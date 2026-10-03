var/global/list/station_gas_tanks = list()

/proc/retire_legacy_piping(list/machines)
	var/list/atmos_machinery_to_remove = list()
	for(var/obj/machinery/atmospherics/machine in machines)
		if(istype(machine, /obj/machinery/atmospherics/unary/vent_pump) || istype(machine, /obj/machinery/atmospherics/unary/vent_scrubber))
			continue
		atmos_machinery_to_remove += machine
	for(var/obj/machinery/atmospherics/machine in atmos_machinery_to_remove)
		machines -= machine
		qdel(machine)

	var/list/disposal_piping_to_remove = list()
	for(var/obj/structure/disposalpipe/pipe in world)
		disposal_piping_to_remove += pipe
	for(var/obj/structure/disposaloutlet/outlet in world)
		disposal_piping_to_remove += outlet
	for(var/obj/structure/disposalpipe/pipe in disposal_piping_to_remove)
		qdel(pipe)
	for(var/obj/structure/disposaloutlet/outlet in disposal_piping_to_remove)
		qdel(outlet)
	for(var/obj/structure/disposalconstruct/construction in world)
		if(construction.ptype != 6 && construction.ptype != 8)
			qdel(construction)

/proc/get_station_gas_tank(atom/source)
	var/turf/source_turf = get_turf(source)
	if(!source_turf)
		return null
	for(var/obj/machinery/station_gas_tank/tank in station_gas_tanks)
		if(QDELETED(tank))
			continue
		var/obj/effect/overmap/source_sector = map_sectors["[source_turf.z]"]
		var/obj/effect/overmap/tank_sector = map_sectors["[tank.z]"]
		if(source_sector && tank_sector && source_sector != tank_sector)
			continue
		if(is_on_same_plane_or_station(source_turf.z, tank.z))
			return tank
	return null

/proc/ensure_station_gas_tank(list/machines)
	for(var/obj/machinery/atmospherics/unary/vent_pump/vent in machines)
		if(get_station_gas_tank(vent))
			continue
		var/turf/placement = get_turf(vent)
		for(var/obj/machinery/atmospherics/unary/vent_pump/candidate in machines)
			if(candidate.z == vent.z && istype(get_area(candidate), /area/engineering/atmos))
				placement = get_turf(candidate)
				break
		if(!placement)
			continue
		var/obj/machinery/station_gas_tank/tank = new(placement)
		for(var/turf/simulated/floor/floor in orange(2, tank))
			if(get_dist(floor, tank) > 1 && get_area(floor) == get_area(tank) && !locate(/obj/machinery) in floor)
				new /obj/machinery/computer/station_gas_control(floor)
				break

/obj/machinery/station_gas_tank
	name = "station gas tank"
	desc = "A large reserve of breathable gas for the station's atmosphere controls."
	icon = 'icons/obj/station_gas_tank.dmi'
	icon_state = "tank"
	anchored = TRUE
	density = FALSE
	bound_width = 96
	bound_height = 96
	bound_x = -32
	bound_y = -32
	power_channel = ENVIRON
	idle_power_usage = 150
	var/datum/gas_mixture/air_contents
	var/enabled = TRUE
	var/max_output_moles = 1000
	var/max_pressure = MAX_PUMP_PRESSURE
	var/last_supply_tick = -1
	var/supplied_this_tick = 0
	var/list/supply_allocations = list()
	var/supply_cursor = 1

/obj/machinery/station_gas_tank/Initialize()
	. = ..()
	air_contents = new /datum/gas_mixture(1000000, T20C)
	var/initial_moles = 20 * ONE_ATMOSPHERE * air_contents.volume / (R_IDEAL_GAS_EQUATION * T20C)
	air_contents.adjust_multi(GAS_OXYGEN, initial_moles * 0.21, GAS_NITROGEN, initial_moles * 0.79)
	station_gas_tanks |= src

/obj/machinery/station_gas_tank/Destroy()
	station_gas_tanks -= src
	QDEL_NULL(air_contents)
	return ..()

/obj/machinery/station_gas_tank/Process()
	last_supply_tick = world.time
	supplied_this_tick = 0
	supply_allocations.Cut()
	if(get_supply_status())
		return 1
	var/list/demands = list()
	for(var/obj/machinery/atmospherics/unary/vent_pump/vent in SSmachines.machinery)
		if(QDELETED(vent))
			continue
		var/demand = vent.get_supply_demand(src)
		if(demand >= MINIMUM_MOLES_TO_PUMP)
			demands[vent] = demand
	var/remaining = min(max_output_moles, air_contents.total_moles)
	var/max_consumers = round(remaining / MINIMUM_MOLES_TO_PUMP)
	if(demands.len > max_consumers)
		var/list/pending = demands
		demands = list()
		for(var/offset in 0 to max_consumers - 1)
			var/obj/machinery/atmospherics/unary/vent_pump/vent = pending[((supply_cursor - 1 + offset) % pending.len) + 1]
			demands[vent] = pending[vent]
		supply_cursor = ((supply_cursor - 1 + max_consumers) % pending.len) + 1
	while(demands.len && remaining >= MINIMUM_MOLES_TO_PUMP)
		var/share = remaining / demands.len
		for(var/obj/machinery/atmospherics/unary/vent_pump/vent in demands.Copy())
			var/allocation = min(demands[vent], share)
			supply_allocations[vent] += allocation
			remaining -= allocation
			demands[vent] -= allocation
			if(demands[vent] < MINIMUM_MOLES_TO_PUMP)
				demands -= vent
	return 1

/obj/machinery/station_gas_tank/proc/get_supply_status()
	if(stat & BROKEN)
		return "tank broken"
	if(stat & NOPOWER)
		return "tank unpowered"
	if(!enabled)
		return "tank output disabled"
	if(!air_contents || air_contents.total_moles < MINIMUM_MOLES_TO_PUMP || air_contents.temperature <= 0)
		return "tank empty"
	if(max_output_moles < MINIMUM_MOLES_TO_PUMP)
		return "tank output limit too low"
	return null

/obj/machinery/station_gas_tank/proc/supply(datum/gas_mixture/environment, requested_moles, obj/machinery/atmospherics/unary/vent_pump/consumer)
	if(get_supply_status() || !environment || requested_moles <= 0)
		return 0
	var/moles = min(requested_moles, max_output_moles - supplied_this_tick, air_contents.total_moles)
	if(consumer)
		moles = min(moles, isnum(supply_allocations[consumer]) ? supply_allocations[consumer] : 0)
	if(moles < MINIMUM_MOLES_TO_PUMP)
		return 0
	var/datum/gas_mixture/removed = air_contents.remove(moles)
	if(!removed)
		return 0
	environment.merge(removed)
	qdel(removed)
	supplied_this_tick += moles
	if(consumer)
		supply_allocations[consumer] -= moles
	return moles

/obj/machinery/station_gas_tank/proc/refill_tank(datum/gas_mixture/environment, requested_moles)
	if((stat & BROKEN) || !enabled || !air_contents || !environment || air_contents.temperature <= 0)
		return 0
	var/available = max_output_moles - supplied_this_tick
	for(var/consumer in supply_allocations)
		available -= supply_allocations[consumer]
	var/moles = min(requested_moles, available, air_contents.total_moles)
	if(moles < MINIMUM_MOLES_TO_PUMP)
		return 0
	var/datum/gas_mixture/removed = air_contents.remove(moles)
	var/transferred = removed.total_moles
	environment.merge(removed)
	qdel(removed)
	supplied_this_tick += transferred
	return transferred

/obj/machinery/station_gas_tank/proc/receive_gas(datum/gas_mixture/environment, requested_moles)
	if(stat & (NOPOWER|BROKEN) || !enabled || !air_contents || !environment || requested_moles <= 0 || environment.temperature <= 0)
		return 0
	var/max_temperature = max(air_contents.temperature, environment.temperature)
	var/max_total_moles = max_pressure * air_contents.volume * air_contents.group_multiplier / (R_IDEAL_GAS_EQUATION * max_temperature)
	var/remaining_capacity = max(0, max_total_moles - air_contents.total_moles)
	var/moles = min(requested_moles, remaining_capacity, environment.total_moles)
	if(moles < MINIMUM_MOLES_TO_PUMP)
		return 0
	var/datum/gas_mixture/removed = environment.remove(moles)
	if(!removed)
		return 0
	air_contents.merge(removed)
	qdel(removed)
	return moles

/obj/machinery/station_gas_tank/attack_hand(mob/user)
	if(..())
		return
	to_chat(user, "<span class='notice'>Reserve: [round(air_contents.return_pressure(), 0.1)] kPa; output: [enabled ? "enabled" : "disabled"] ([max_output_moles] mol/cycle).</span>")

/obj/machinery/computer/station_gas_control
	name = "station gas control computer"
	desc = "Controls the station's shared breathable gas reserve."
	req_one_access = list(access_atmospherics, access_engine_equip)

/obj/machinery/computer/station_gas_control/attack_hand(mob/user)
	if(..())
		return
	var/obj/machinery/station_gas_tank/tank = get_station_gas_tank(src)
	if(!tank)
		to_chat(user, "<span class='warning'>No station gas tank is online.</span>")
		return
	var/text = "<div class='firstdivmood'><div class='compbox'><b>STATION GAS CONTROL</b><hr>Reserve: [round(tank.air_contents.return_pressure(), 0.1)] kPa<br>Output: [tank.enabled ? "ON" : "OFF"]<br>Limit: [tank.max_output_moles] mol/cycle<br>"
	if(allowed(user))
		text += "<a href='?src=\ref[src];gas_action=toggle'>TOGGLE OUTPUT</a><br><a href='?src=\ref[src];gas_action=limit'>SET LIMIT</a><br><a href='?src=\ref[src];gas_action=refill'>TRANSFER FROM CANISTER</a>"
	to_chat(user, "[text]</div></div>")

/obj/machinery/computer/station_gas_control/Topic(href, href_list)
	if(!href_list["gas_action"])
		return ..()
	if((stat & (NOPOWER|BROKEN)) || !usr || get_dist(src, usr) > 1 || !allowed(usr))
		return
	var/obj/machinery/station_gas_tank/tank = get_station_gas_tank(src)
	if(!tank)
		return
	switch(href_list["gas_action"])
		if("toggle")
			tank.enabled = !tank.enabled
		if("limit")
			var/new_limit = input(usr, "Maximum gas output in moles per cycle", "Station gas", tank.max_output_moles) as null|num
			if(isnum_safe(new_limit) && get_dist(src, usr) <= 1 && allowed(usr))
				tank.max_output_moles = between(0, new_limit, 1000)
		if("refill")
			var/list/candidates = list()
			for(var/obj/machinery/portable_atmospherics/canister/canister in range(1, tank))
				if(!canister.station_fed && canister.air_contents && canister.air_contents.total_moles && canister.air_contents.gas.len <= 2 && canister.air_contents.get_gas(GAS_OXYGEN) + canister.air_contents.get_gas(GAS_NITROGEN) >= canister.air_contents.total_moles)
					candidates += canister
			var/obj/machinery/portable_atmospherics/canister/selected = input(usr, "Transfer breathable gas from which canister?", "Station gas") as null|anything in candidates
			if(selected && get_dist(src, usr) <= 1 && allowed(usr) && get_dist(selected, tank) <= 1)
				var/capacity = max(0, (tank.max_pressure - tank.air_contents.return_pressure()) * tank.air_contents.volume / (R_IDEAL_GAS_EQUATION * T20C))
				var/datum/gas_mixture/transferred = selected.air_contents.remove(min(capacity, selected.air_contents.total_moles))
				if(transferred)
					tank.air_contents.merge(transferred)
					qdel(transferred)
	attack_hand(usr)
