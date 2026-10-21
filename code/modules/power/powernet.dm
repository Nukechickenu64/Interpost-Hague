// Global power net. There is exactly one grid: it spans every station z-level.
// Generators add their output to global production, SMES units form the global storage
// pool (they charge from surplus production and output their stored charge into the pool),
// and areas draw from the pool. While draw exceeds production + storage output, power is
// cut to a random area each balance pass until the grid is stable again.

var/global/datum/powernet/power_net = new

/datum/powernet
	var/list/nodes = list()			// every registered /obj/machinery/power on the grid
	var/list/input_nodes = list()	// SMES-style storage units (API compatibility)
	var/list/producers = list()		// generators feeding the pool
	var/list/storage = list()		// SMES units forming the storage pool

	var/load = 0				// the load drawn this tick, increased as machines/areas draw
	var/newavail = 0			// production gathered last tick, becomes...
	var/avail = 0				//...the currently available power (production + storage output)
	var/viewload = 0			// the load as it appears on power consoles

	var/smes_demand = 0			// amount of power demanded by all SMESs this tick (charging)
	var/list/inputting = list()	// SMESs currently demanding charge
	var/smes_avail = 0			// power provided by SMES output
	var/smes_newavail = 0

	var/netexcess = 0			// excess power (avail - load)
	var/problem = 0				// grid warning ticker; monitors show warnings while non-zero

	var/storage_capacity = 0	// summed SMES capacity (charge units)
	var/stored_energy = 0		// summed SMES charge last tick (display only)
	var/generated = 0			// production generated last tick (display only)
	var/list/area_loads = list() // Completed per-area sample, retained after clear_usage().
	var/list/serviced_area_loads = list() // Area controllers already paid for this usage via draw_power().
	var/sampled_at = 0

	var/list/depowered_areas = list()	// areas currently force-cut by the shortage balancer
	var/list/cached_station_areas		// lazily-built station area cache
	var/problems_ticks_left = 0			// problem value carried over across reset (display)

/datum/powernet/New()
	..()

/datum/powernet/Destroy()
	nodes.Cut()
	input_nodes.Cut()
	producers.Cut()
	storage.Cut()
	inputting.Cut()
	depowered_areas.Cut()
	return ..()

// --- Registration ---------------------------------------------------------

/datum/powernet/proc/register_machine(obj/machinery/power/M)
	nodes[M] = M

/datum/powernet/proc/unregister_machine(obj/machinery/power/M)
	nodes -= M
	producers -= M
	storage -= M
	input_nodes -= M

/datum/powernet/proc/register_producer(obj/machinery/power/M)
	register_machine(M)
	producers[M] = M

/datum/powernet/proc/register_storage(obj/machinery/power/smes/S)
	register_machine(S)
	storage[S] = S
	input_nodes[S] = S
	recalc_capacity()

/datum/powernet/proc/unregister_storage(obj/machinery/power/smes/S)
	storage -= S
	input_nodes -= S
	recalc_capacity()

/datum/powernet/proc/recalc_capacity()
	storage_capacity = 0
	for(var/obj/machinery/power/smes/S in storage)
		if(!QDELETED(S))
			storage_capacity += S.capacity

/datum/powernet/proc/station_areas()
	if(!length(cached_station_areas))
		cached_station_areas = get_filtered_areas(GLOB.is_station_but_not_space_or_shuttle_area)
		for(var/area/external/external_area)
			if(isStationLevel(external_area.z))
				cached_station_areas |= external_area
	return cached_station_areas

// --- Consumption / state ---------------------------------------------------

//Returns the amount of excess power (before charging SMESs) from last tick.
/datum/powernet/proc/last_surplus()
	return max(avail - load, 0)

/datum/powernet/proc/draw_power(var/amount)
	var/draw = between(0, amount, avail - load)
	load += draw
	return draw

/datum/powernet/proc/is_empty()
	return !nodes.len

/datum/powernet/proc/trigger_warning(var/duration_ticks = 20)
	problem = max(duration_ticks, problem)

/datum/powernet/proc/record_serviced_area(area/A)
	serviced_area_loads[A] += A.usage(TOTAL)

// Amount of power granted when the infinite power admin secret is enabled.
#define INFINITE_STATION_POWER_AMOUNT 999999999
#define POWER_STARTUP_GRACE_PERIOD (10 MINUTES)

// Area channel values (match code/game/area definitions)
#define GP_EQUIP 1
#define GP_LIGHT 2
#define GP_ENVIRON 3

// Called every machines tick after all machinery processed (SSmachines).
// Gathers production, balances area draw against it, charges SMESs and cuts
// power to random areas while the grid cannot cover the load.
/datum/powernet/proc/reset()
	problems_ticks_left = max(problems_ticks_left, 0)
	if(problem > 0)
		problem = max(problem - 1, 0)

	// Admin infinite power secret and round-start grace period.
	if(GLOB.infinite_station_power || (round_start_time && world.time >= round_start_time && world.time - round_start_time < POWER_STARTUP_GRACE_PERIOD))
		newavail = max(newavail, INFINITE_STATION_POWER_AMOUNT)

	generated = max(0, newavail - smes_newavail)
	avail = newavail
	smes_avail = smes_newavail

	// Sum area load and clear the tick-local usage counters.
	// Keep direct machinery draw (notably shields) already charged this tick.
	area_loads.Cut()
	sampled_at = world.time
	var/list/areas = station_areas()
	for(var/area/A in areas)
		if(!A.requires_power || A.always_unpowered)
			continue
		if(A in serviced_area_loads)
			// The area controller already drew the standing load from the grid
			// (or its cell). Only later one-off requests still need billing.
			var/remaining = A.oneoff_equip + A.oneoff_light + A.oneoff_environ
			area_loads[A] = serviced_area_loads[A] + remaining
			load += remaining
		else
			area_loads[A] = A.usage(TOTAL)
			load += area_loads[A]
	for(var/area/A in areas)
		A.clear_usage()
	serviced_area_loads.Cut()
	viewload = round(load)

	// Storage unit charging: grant each demanding SMES its share of the surplus.
	netexcess = avail - load
	if(inputting.len && smes_demand)
		// Storage output is not newly generated energy and cannot charge itself.
		var/smes_input_percentage = between(0, (max(0, generated - load) / smes_demand) * 100, 100)
		for(var/obj/machinery/power/smes/S in inputting)
			S.input_power(smes_input_percentage)
	netexcess = avail - load

	// Refund unused SMES output back into their charge.
	if(netexcess)
		var/perc = get_percent_load(1)
		for(var/obj/machinery/power/smes/S in storage)
			S.restore(perc)
	stored_energy = 0
	for(var/obj/machinery/power/smes/S in storage)
		if(!QDELETED(S))
			stored_energy += S.charge

	// Shortage balancing: while demand exceeds supply, cut a random powered area.
	balance_areas(max(load - avail, 0))

	// Reset for the next tick.
	problems_ticks_left = problem
	load = 0
	avail = newavail
	smes_avail = smes_newavail
	inputting.Cut()
	smes_demand = 0
	newavail = 0
	smes_newavail = 0

// Cut power from random non-critical areas while the grid is short, restore everything
// once production covers the load again.
/datum/powernet/proc/balance_areas(var/deficit)
	var/list/areas = station_areas()
	if(deficit > 0)
		var/list/candidates = list()
		for(var/area/A in areas)
			if(A.requires_power && !A.always_unpowered && !(A in depowered_areas) && A.any_power_channel_on())
				candidates += A
		while(deficit > 0 && candidates.len)
			var/area/A = pick(candidates)	// depower a random area
			candidates -= A
			var/cut = area_loads[A]
			if(A.x || prob(1)) // wired-in areas always register usage; guard only vs. zero-use spots
				depowered_areas += A
				A.area_power_cut()
			deficit -= max(cut, 1)
	else
		for(var/area/A in depowered_areas.Copy())
			depowered_areas -= A
			A.area_power_restore()

/datum/powernet/proc/get_percent_load(var/smes_only = 0)
	if(smes_only)
		var/smes_used = load - (avail - smes_avail)	// SMESs are always last to provide power
		if(!smes_used || smes_used < 0 || !smes_avail)
			return 0
		return between(0, (smes_used / smes_avail) * 100, 100)
	else
		if(!load)
			return 0
		return between(0, (avail / load) * 100, 100)

/datum/powernet/proc/get_electrocute_damage()
	switch(avail)
		if (1000000 to INFINITY)
			return min(rand(50,160),rand(50,160))
		if (200000 to 1000000)
			return min(rand(25,80),rand(25,80))
		if (100000 to 200000)//Ave powernet
			return min(rand(20,60),rand(20,60))
		if (50000 to 100000)
			return min(rand(15,40),rand(15,40))
		if (1000 to 50000)
			return min(rand(10,20),rand(10,20))
		else
			return 0

#undef INFINITE_STATION_POWER_AMOUNT
#undef POWER_STARTUP_GRACE_PERIOD
#undef GP_EQUIP
#undef GP_LIGHT
#undef GP_ENVIRON
