/datum/powernet
	var/list/nodes = list()			// holders whose output (or only) port is on this bus
	var/list/input_nodes = list()	// split holders (SMES) whose input port is on this bus

	var/load = 0				// the current load on the powernet, increased by each machine at processing
	var/newavail = 0			// what available power was gathered last tick, then becomes...
	var/avail = 0				//...the current available power in the powernet
	var/viewload = 0			// the load as it appears on the power console (gradually updated)

	var/smes_demand = 0			// Amount of power demanded by all SMESs from this network. Needed for load balancing.
	var/list/inputting = list()	// List of SMESs that are demanding power from this network. Needed for load balancing.

	var/smes_avail = 0			// Amount of power (avail) from SMESes. Used by SMES load balancing
	var/smes_newavail = 0		// As above, just for newavail

	var/netexcess = 0			// excess power on the powernet (typically avail-load)

	var/problem = 0				// If this is not 0 there is some sort of issue in the powernet. Monitors will display warnings.

/datum/powernet/New()
	START_PROCESSING_POWERNET(src)
	..()

/datum/powernet/Destroy()
	for(var/obj/machinery/power/M in nodes)
		if(M.powernet == src)
			M.powernet = null
	for(var/obj/machinery/power/M in input_nodes)
		if(M.input_powernet == src)
			M.input_powernet = null
	nodes.Cut()
	input_nodes.Cut()
	inputting.Cut()
	STOP_PROCESSING_POWERNET(src)
	return ..()

//Returns the amount of excess power (before refunding to SMESs) from last tick.
//This is for machines that might adjust their power consumption using this data.
/datum/powernet/proc/last_surplus()
	return max(avail - load, 0)

/datum/powernet/proc/draw_power(var/amount)
	var/draw = between(0, amount, avail - load)
	load += draw
	return draw

/datum/powernet/proc/is_empty()
	return !nodes.len && !input_nodes.len

// Triggers warning for certain amount of ticks
/datum/powernet/proc/trigger_warning(var/duration_ticks = 20)
	problem = max(duration_ticks, problem)

// Amount of power granted to a station powernet when the infinite power admin secret is enabled.
#define INFINITE_STATION_POWER_AMOUNT 999999999
#define POWER_STARTUP_GRACE_PERIOD (10 MINUTES)

/datum/powernet/proc/is_on_station_level()
	for(var/atom/M in nodes)
		if(M.z in GLOB.using_map.station_levels)
			return TRUE
	for(var/atom/M in input_nodes)
		if(M.z in GLOB.using_map.station_levels)
			return TRUE
	return FALSE

/datum/powernet/proc/get_area_smes_units()
	. = list()
	for(var/obj/machinery/power/area_smes/A in nodes)
		. += A

//handles the power changes in the powernet
//called every ticks by the powernet controller
/datum/powernet/proc/reset()
	if(is_on_station_level() && (GLOB.infinite_station_power || (round_start_time && world.time >= round_start_time && world.time - round_start_time < POWER_STARTUP_GRACE_PERIOD)))
		newavail = max(newavail, INFINITE_STATION_POWER_AMOUNT)

	if(problem > 0)
		problem = max(problem - 1, 0)

	netexcess = avail - load

	// At this point, all other machines have finished using power. Anything left over may be used up to charge SMESs.
	if(inputting.len && smes_demand)
		var/smes_input_percentage = between(0, (netexcess / smes_demand) * 100, 100)
		for(var/obj/machinery/power/smes/S in inputting)
			S.input_power(smes_input_percentage)

	netexcess = avail - load

	if(netexcess)
		var/perc = get_percent_load(1)
		for(var/obj/machinery/power/smes/S in nodes)
			S.restore(perc)

	//updates the viewed load (as seen on power computers)
	viewload = round(load)

	//reset the powernet
	load = 0
	avail = newavail
	smes_avail = smes_newavail
	inputting.Cut()
	smes_demand = 0
	newavail = 0
	smes_newavail = 0

#undef INFINITE_STATION_POWER_AMOUNT

/datum/powernet/proc/get_percent_load(var/smes_only = 0)
	if(smes_only)
		var/smes_used = load - (avail - smes_avail) 			// SMESs are always last to provide power
		if(!smes_used || smes_used < 0 || !smes_avail)			// SMES power isn't available or being used at all, SMES load is therefore 0%
			return 0
		return between(0, (smes_used / smes_avail) * 100, 100)	// Otherwise return percentage load of SMESs.
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
