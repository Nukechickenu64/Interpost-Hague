/*
	Unit tests for ATMOSPHERICS primitives
*/
#define ALL_GASIDS gas_data.gases

/datum/unit_test/atmos_machinery
	var/list/test_cases = list()

/datum/unit_test/atmos_machinery/proc/create_gas_mixes(gas_mix_data)
	var/list/gas_mixes = list()
	for(var/mix_name in gas_mix_data)
		var/list/mix_data = gas_mix_data[mix_name]

		var/datum/gas_mixture/gas_mix = new (CELL_VOLUME, mix_data["temperature"])

		var/list/initial_gas = mix_data["initial_gas"]
		if(initial_gas.len)
			var/list/gas_args = list()
			for(var/gasid in initial_gas)
				gas_args += gasid
				gas_args += initial_gas[gasid]
			gas_mix.adjust_multi(arglist(gas_args))

		gas_mixes[mix_name] = gas_mix
	return gas_mixes

/datum/unit_test/atmos_machinery/proc/gas_amount_changes(var/list/before_gas_mixes, var/list/after_gas_mixes)
	var/list/result = list()
	for(var/mix_name in before_gas_mixes & after_gas_mixes)
		var/change = list()

		var/datum/gas_mixture/before = before_gas_mixes[mix_name]
		var/datum/gas_mixture/after = after_gas_mixes[mix_name]

		var/list/all_gases = before.gas | after.gas
		for(var/gasid in all_gases)
			change[gasid] = after.get_gas(gasid) - before.get_gas(gasid)

		result[mix_name] = change

	return result

/datum/unit_test/atmos_machinery/proc/check_moles_conserved(var/case_name, var/list/before_gas_mixes, var/list/after_gas_mixes)
	var/failed = FALSE
	for(var/gasid in gas_data.gases)
		var/before = 0
		for(var/gasmix in before_gas_mixes)
			var/datum/gas_mixture/G = before_gas_mixes[gasmix]
			before += G.get_gas(gasid)

		var/after = 0
		for(var/gasmix in after_gas_mixes)
			var/datum/gas_mixture/G = after_gas_mixes[gasmix]
			after += G.get_gas(gasid)

		if(abs(before - after) > ATMOS_PRECISION)
			fail("[case_name]: expected [before] moles of [gasid], found [after] moles.")
			failed |= TRUE

	if(!failed)
		pass("[case_name]: conserved moles of each gas ID.")

/datum/unit_test/atmos_machinery/conserve_moles
	test_cases = list(
		uphill = list(
			source = list(
				initial_gas = list(
					"oxygen"         = 5,
					"nitrogen"       = 10,
					"carbon_dioxide" = 5,
					"phoron"         = 10,
					"sleeping_agent" = 5,
				),
				temperature = T20C - 5,
			),
			sink = list(
				initial_gas = list(
					"oxygen"         = 10,
					"nitrogen"       = 20,
					"carbon_dioxide" = 10,
					"phoron"         = 20,
					"sleeping_agent" = 10,
				),
				temperature = T20C + 5,
			)
		),
		downhill = list(
			source = list(
				initial_gas = list(
					"oxygen"         = 10,
					"nitrogen"       = 20,
					"carbon_dioxide" = 10,
					"phoron"         = 20,
					"sleeping_agent" = 10,
				),
				temperature = T20C + 5,
			),
			sink = list(
				initial_gas = list(
					"oxygen"         = 5,
					"nitrogen"       = 10,
					"carbon_dioxide" = 5,
					"phoron"         = 10,
					"sleeping_agent" = 5,
				),
				temperature = T20C - 5,
			),
		),
		flat = list(
			source = list(
				initial_gas = list(
					"oxygen"         = 10,
					"nitrogen"       = 20,
					"carbon_dioxide" = 10,
					"phoron"         = 20,
					"sleeping_agent" = 10,
				),
				temperature = T20C,
			),
			sink = list(
				initial_gas = list(
					"oxygen"         = 10,
					"nitrogen"       = 20,
					"carbon_dioxide" = 10,
					"phoron"         = 20,
					"sleeping_agent" = 10,
				),
				temperature = T20C,
			),
		),
		vacuum_sink = list(
			source = list(
				initial_gas = list(
					"oxygen"         = 10,
					"nitrogen"       = 20,
					"carbon_dioxide" = 10,
					"phoron"         = 20,
					"sleeping_agent" = 10,
				),
				temperature = T20C,
			),
			sink = list(
				initial_gas = list(),
				temperature = 0,
			),
		),
		vacuum_source = list(
			source = list(
				initial_gas = list(),
				temperature = 0,
			),
			sink = list(
				initial_gas = list(
					"oxygen"         = 10,
					"nitrogen"       = 20,
					"carbon_dioxide" = 10,
					"phoron"         = 20,
					"sleeping_agent" = 10,
				),
				temperature = T20C,
			),
		),
	)


/datum/unit_test/atmos_machinery/conserve_moles/pump_gas
	name = "ATMOS MACHINERY: pump_gas() Conserves Moles"

/datum/unit_test/atmos_machinery/conserve_moles/pump_gas/start_test()
	for(var/case_name in test_cases)
		var/gas_mix_data = test_cases[case_name]
		var/list/before_gas_mixes = create_gas_mixes(gas_mix_data)
		var/list/after_gas_mixes = create_gas_mixes(gas_mix_data)

		pump_gas(null, after_gas_mixes["source"], after_gas_mixes["sink"], null, INFINITY)

		check_moles_conserved(case_name, before_gas_mixes, after_gas_mixes)

	return 1

/datum/unit_test/atmos_machinery/conserve_moles/pump_gas_passive
	name = "ATMOS MACHINERY: pump_gas_passive() Conserves Moles"

/datum/unit_test/atmos_machinery/conserve_moles/pump_gas_passive/start_test()
	for(var/case_name in test_cases)
		var/gas_mix_data = test_cases[case_name]
		var/list/before_gas_mixes = create_gas_mixes(gas_mix_data)
		var/list/after_gas_mixes = create_gas_mixes(gas_mix_data)

		pump_gas_passive(null, after_gas_mixes["source"], after_gas_mixes["sink"], null)

		check_moles_conserved(case_name, before_gas_mixes, after_gas_mixes)

	return 1

/datum/unit_test/atmos_machinery/conserve_moles/scrub_gas
	name = "ATMOS MACHINERY: scrub_gas() Conserves Moles"

/datum/unit_test/atmos_machinery/conserve_moles/scrub_gas/start_test()
	var/list/filtering = gas_data.gases

	for(var/case_name in test_cases)
		var/gas_mix_data = test_cases[case_name]
		var/list/before_gas_mixes = create_gas_mixes(gas_mix_data)
		var/list/after_gas_mixes = create_gas_mixes(gas_mix_data)

		scrub_gas(null, filtering, after_gas_mixes["source"], after_gas_mixes["sink"], null, INFINITY)

		check_moles_conserved(case_name, before_gas_mixes, after_gas_mixes)

	return 1

/datum/unit_test/atmos_machinery/conserve_moles/filter_gas
	name = "ATMOS MACHINERY: filter_gas() Conserves Moles"

/datum/unit_test/atmos_machinery/conserve_moles/filter_gas/start_test()
	var/list/filtering = gas_data.gases

	for(var/case_name in test_cases)
		var/gas_mix_data = test_cases[case_name]
		var/list/before_gas_mixes = create_gas_mixes(gas_mix_data)
		var/list/after_gas_mixes = create_gas_mixes(gas_mix_data)

		filter_gas(null, filtering, after_gas_mixes["source"], after_gas_mixes["sink"], after_gas_mixes["source"], null, INFINITY)

		check_moles_conserved(case_name, before_gas_mixes, after_gas_mixes)

	return 1

/datum/unit_test/atmos_machinery/conserve_moles/filter_gas_multi
	name = "ATMOS MACHINERY: filter_gas_multi() Conserves Moles"

/datum/unit_test/atmos_machinery/conserve_moles/filter_gas_multi/start_test()
	for(var/case_name in test_cases)
		var/gas_mix_data = test_cases[case_name]
		var/list/before_gas_mixes = create_gas_mixes(gas_mix_data)
		var/list/after_gas_mixes = create_gas_mixes(gas_mix_data)

		var/list/filtering = list()
		for(var/gasid in gas_data.gases)
			filtering[gasid] = after_gas_mixes["sink"] //just filter everything to sink

		filter_gas_multi(null, filtering, after_gas_mixes["source"], after_gas_mixes["sink"], null, INFINITY)

		check_moles_conserved(case_name, before_gas_mixes, after_gas_mixes)

	return 1

/datum/unit_test/atmos_machinery/conserve_moles/mix_gas
	name = "ATMOS MACHINERY: mix_gas() Conserves Moles"

/datum/unit_test/atmos_machinery/conserve_moles/mix_gas/start_test()
	for(var/case_name in test_cases)
		var/gas_mix_data = test_cases[case_name]
		var/list/before_gas_mixes = create_gas_mixes(gas_mix_data)
		var/list/after_gas_mixes = create_gas_mixes(gas_mix_data)

		var/list/mix_sources = list()
		for(var/gasid in ALL_GASIDS)
			var/datum/gas_mixture/mix_source = after_gas_mixes["sink"]
			mix_sources[mix_source] = 1.0/gas_data.gases.len //doesn't work as a macro for some reason

		mix_gas(null, mix_sources, after_gas_mixes["sink"], null, INFINITY)

		check_moles_conserved(case_name, before_gas_mixes, after_gas_mixes)

	return 1

/obj/machinery/atmospherics/unary/vent_pump/supply_test
	var/obj/machinery/station_gas_tank/test_tank
	var/datum/gas_mixture/test_environment
	var/test_demand = 100

/obj/machinery/atmospherics/unary/vent_pump/supply_test/get_supply_demand(obj/machinery/station_gas_tank/tank)
	return tank == test_tank ? test_demand : 0

/datum/unit_test/atmos_machinery/station_supply
	name = "ATMOS MACHINERY: Shared tank supplies competing vents"

/datum/unit_test/atmos_machinery/station_supply/start_test()
	var/turf/test_turf = get_safe_turf()
	if(!test_turf)
		fail("No safe test turf is available.")
		return 1
	var/obj/machinery/station_gas_tank/tank = new(test_turf)
	var/obj/machinery/atmospherics/unary/vent_pump/supply_test/first = new(test_turf)
	var/obj/machinery/atmospherics/unary/vent_pump/supply_test/second = new(test_turf)
	tank.stat = 0
	first.test_tank = tank
	second.test_tank = tank
	first.test_environment = new(CELL_VOLUME, T20C)
	second.test_environment = new(CELL_VOLUME, T20C)
	var/initial_moles = tank.air_contents.total_moles
	var/failed = FALSE
	for(var/cycle in 1 to 3)
		tank.Process()
		var/first_flow
		var/second_flow
		if(cycle % 2)
			first_flow = tank.supply(first.test_environment, 100, first)
			second_flow = tank.supply(second.test_environment, 100, second)
		else
			second_flow = tank.supply(second.test_environment, 100, second)
			first_flow = tank.supply(first.test_environment, 100, first)
		if(first_flow <= 0 || second_flow <= 0)
			fail("Cycle [cycle]: competing vents received [first_flow] and [second_flow] moles.")
			failed = TRUE
		if(first_flow + second_flow > tank.max_output_moles + ATMOS_PRECISION)
			fail("Cycle [cycle]: exceeded the shared tank output limit.")
			failed = TRUE
		if(tank.supply(first.test_environment, 100, first) || tank.supply(second.test_environment, 100, second))
			fail("Cycle [cycle]: a consumer drew more than its allowance.")
			failed = TRUE
	first.test_demand = 10
	tank.Process()
	var/small_flow = tank.supply(first.test_environment, 100, first)
	var/large_flow = tank.supply(second.test_environment, 100, second)
	if(abs(small_flow - 10) > ATMOS_PRECISION || abs(large_flow - 90) > ATMOS_PRECISION)
		fail("Unequal demand received [small_flow] and [large_flow] moles instead of 10 and 90.")
		failed = TRUE
	tank.max_output_moles = MINIMUM_MOLES_TO_PUMP
	var/first_low_flow = 0
	var/second_low_flow = 0
	for(var/cycle in 1 to 2)
		tank.Process()
		var/first_flow = tank.supply(first.test_environment, 100, first)
		var/second_flow = tank.supply(second.test_environment, 100, second)
		first_low_flow += first_flow
		second_low_flow += second_flow
		if(first_flow + second_flow > tank.max_output_moles + ATMOS_PRECISION)
			fail("Low output limit was exceeded.")
			failed = TRUE
	if(first_low_flow <= 0 || second_low_flow <= 0)
		fail("A minimum-sized output limit starved a competing vent.")
		failed = TRUE
	var/transferred = first.test_environment.total_moles + second.test_environment.total_moles
	if(abs(initial_moles - tank.air_contents.total_moles - transferred) > ATMOS_PRECISION)
		fail("Tank supply did not conserve moles.")
		failed = TRUE
	qdel(first.test_environment)
	qdel(second.test_environment)
	qdel(first)
	qdel(second)
	qdel(tank)
	if(!failed)
		pass("Both competing vents received gas without exceeding the shared limit or losing moles.")
	return 1

/obj/modcon_supply_test_room
	var/datum/gas_mixture/test_air

/obj/modcon_supply_test_room/return_air()
	return test_air

/obj/modcon_supply_test_room/Destroy()
	QDEL_NULL(test_air)
	return ..()

/datum/unit_test/atmos_machinery/modcon_refill
	name = "ATMOS MACHINERY: Modcon refill respects pressure and shutdown gates"
	var/supply_failed = FALSE

/datum/unit_test/atmos_machinery/modcon_refill/proc/check_flow(obj/machinery/station_gas_tank/tank, obj/machinery/atmospherics/unary/vent_pump/vent, obj/modcon_supply_test_room/room, expected_flow, case_name)
	var/tank_before = tank.air_contents.total_moles
	var/room_before = room.test_air.total_moles
	tank.Process()
	vent.Process()
	var/room_change = room.test_air.total_moles - room_before
	var/tank_change = tank.air_contents.total_moles - tank_before
	if((expected_flow && abs(room_change) < MINIMUM_MOLES_TO_PUMP) || (!expected_flow && abs(room_change) > ATMOS_PRECISION))
		fail("[case_name]: unexpected transfer of [room_change] moles ([vent.get_supply_status()]).")
		supply_failed = TRUE
	if(abs(room_change + tank_change) > ATMOS_PRECISION)
		fail("[case_name]: transferred gas was not conserved.")
		supply_failed = TRUE
	var/obj/machinery/alarm/controller = vent.initial_loc.master_air_alarm
	if(vent.pump_direction && room.test_air.return_pressure() > min(controller.output_pressure, vent.external_pressure_bound) + ATMOS_PRECISION)
		fail("[case_name]: room pressure exceeded the modcon target.")
		supply_failed = TRUE

/datum/unit_test/atmos_machinery/modcon_refill/start_test()
	var/turf/test_turf = get_safe_turf()
	if(!test_turf)
		fail("No safe test turf is available.")
		return 1
	var/area/test_area = get_area(test_turf)
	var/obj/machinery/alarm/original_master = test_area.master_air_alarm
	var/list/original_tanks = station_gas_tanks
	station_gas_tanks = list()
	var/obj/machinery/station_gas_tank/tank = new(test_turf)
	var/obj/machinery/alarm/modcon = new(test_turf)
	var/obj/modcon_supply_test_room/room = new(test_turf)
	var/obj/machinery/atmospherics/unary/vent_pump/vent = new(room)
	test_area.master_air_alarm = modcon
	tank.stat = 0
	modcon.stat = 0
	vent.stat = 0
	for(var/pressure_fraction in list(0.85, 0.70, 0))
		QDEL_NULL(room.test_air)
		room.test_air = new(CELL_VOLUME, T20C)
		var/moles = pressure_fraction * ONE_ATMOSPHERE * CELL_VOLUME / (R_IDEAL_GAS_EQUATION * T20C)
		room.test_air.adjust_multi(GAS_OXYGEN, moles * 0.21, GAS_NITROGEN, moles * 0.79)
		modcon.overall_danger_level(room.test_air)
		check_flow(tank, vent, room, TRUE, "Refill at [pressure_fraction] atmospheres")
		if(room.test_air.return_pressure() < modcon.output_pressure - ATMOS_PRECISION)
			check_flow(tank, vent, room, TRUE, "Complete rate-limited refill")
		check_flow(tank, vent, room, FALSE, "Stop at target")
	QDEL_NULL(room.test_air)
	room.test_air = new(CELL_VOLUME, T20C)
	for(var/shutdown_mode in list(AALARM_MODE_OFF, AALARM_MODE_PANIC, AALARM_MODE_CYCLE))
		modcon.mode = shutdown_mode
		check_flow(tank, vent, room, FALSE, "Modcon shutdown mode [shutdown_mode]")
	modcon.mode = AALARM_MODE_SCRUBBING
	for(var/power_fault in list(NOPOWER, BROKEN))
		modcon.stat = power_fault
		check_flow(tank, vent, room, FALSE, "Modcon fault [power_fault]")
		modcon.stat = 0
		tank.stat = power_fault
		check_flow(tank, vent, room, FALSE, "Tank fault [power_fault]")
		tank.stat = 0
		vent.stat = power_fault
		check_flow(tank, vent, room, FALSE, "Vent fault [power_fault]")
		vent.stat = 0
	modcon.shorted = TRUE
	check_flow(tank, vent, room, FALSE, "Shorted modcon")
	modcon.shorted = FALSE
	modcon.buildstage = 0
	check_flow(tank, vent, room, FALSE, "Incomplete modcon")
	modcon.buildstage = 2
	tank.enabled = FALSE
	check_flow(tank, vent, room, FALSE, "Disabled tank")
	tank.enabled = TRUE
	tank.max_output_moles = 0
	check_flow(tank, vent, room, FALSE, "Zero output limit")
	tank.max_output_moles = 100
	vent.welded = TRUE
	check_flow(tank, vent, room, FALSE, "Welded vent")
	vent.welded = FALSE
	vent.use_power = POWER_USE_OFF
	check_flow(tank, vent, room, FALSE, "Switched-off vent")
	vent.use_power = POWER_USE_IDLE
	QDEL_NULL(room.test_air)
	room.test_air = new(CELL_VOLUME, T20C)
	var/room_moles = ONE_ATMOSPHERE * 0.85 * CELL_VOLUME / (R_IDEAL_GAS_EQUATION * T20C)
	room.test_air.adjust_multi(GAS_OXYGEN, room_moles * 0.20, GAS_NITROGEN, room_moles * 0.79, GAS_CO2, room_moles * 0.01)
	vent.pump_direction = 0
	var/datum/signal/siphon_command = new
	siphon_command.data = list("tag" = vent.id_tag, "sigtype" = "command", "power" = 1, "direction" = 0, "set_external_pressure" = ONE_ATMOSPHERE * 0.5)
	vent.receive_signal(siphon_command)
	var/room_before_siphon = room.test_air.total_moles
	var/tank_before_siphon = tank.air_contents.total_moles
	var/contaminants_before_siphon = room.test_air.get_gas(GAS_CO2)
	var/cartridge_before_siphon = modcon.cartridge.integrity
	for(var/cycle in 1 to 10)
		if(room.test_air.return_pressure() <= vent.external_pressure_bound + ATMOS_PRECISION)
			break
		tank.Process()
		vent.Process()
	if(room.test_air.return_pressure() >= ONE_ATMOSPHERE * 0.85 || room.test_air.return_pressure() > vent.external_pressure_bound + ATMOS_PRECISION)
		fail("Siphoning did not lower room pressure to the commanded target.")
		supply_failed = TRUE
	var/discarded_contaminants = contaminants_before_siphon - room.test_air.get_gas(GAS_CO2)
	if(abs((room_before_siphon - room.test_air.total_moles) - (tank.air_contents.total_moles - tank_before_siphon) - discarded_contaminants) > ATMOS_PRECISION)
		fail("Filtered siphoning did not conserve clean gas and account for discarded contaminants.")
		supply_failed = TRUE
	if(tank.air_contents.get_gas(GAS_CO2) > 0 || discarded_contaminants <= 0 || modcon.cartridge.integrity >= cartridge_before_siphon)
		fail("Siphoning did not filter contaminants before reserve storage and wear the cartridge.")
		supply_failed = TRUE
	qdel(siphon_command)
	vent.pump_direction = 1
	var/datum/signal/pressurize_command = new
	pressurize_command.data = list("tag" = vent.id_tag, "sigtype" = "command", "power" = 1, "direction" = 1, "set_external_pressure" = ONE_ATMOSPHERE * 0.75)
	vent.receive_signal(pressurize_command)
	for(var/cycle in 1 to 10)
		if(room.test_air.return_pressure() >= vent.external_pressure_bound - ATMOS_PRECISION)
			break
		tank.Process()
		vent.Process()
	if(abs(room.test_air.return_pressure() - vent.external_pressure_bound) > ATMOS_PRECISION)
		fail("Pressurizing did not stop at the commanded pressure bound.")
		supply_failed = TRUE
	qdel(pressurize_command)
	vent.external_pressure_bound = ONE_ATMOSPHERE
	var/datum/gas_mixture/reserve = tank.air_contents
	tank.air_contents = new(CELL_VOLUME, T20C)
	check_flow(tank, vent, room, FALSE, "Empty reserve")
	qdel(tank.air_contents)
	tank.air_contents = reserve
	station_gas_tanks = original_tanks
	test_area.master_air_alarm = original_master
	qdel(vent)
	qdel(room)
	qdel(modcon)
	qdel(tank)
	if(!supply_failed)
		pass("Refill and filtered recovery respect pressure bounds, conserve clean gas, and respect shutdown gates.")
	return 1

/mob/living/carbon/human/canister_refill_test
	var/refuse_unequip = FALSE

/mob/living/carbon/human/canister_refill_test/unEquip(obj/item/item, force = 0, atom/target = null)
	if(refuse_unequip)
		return FALSE
	return ..()

/datum/unit_test/atmos_machinery/canister_refill
	name = "ATMOS MACHINERY: Fixed gas stations refill tanks safely"
	var/refill_failed = FALSE

/datum/unit_test/atmos_machinery/canister_refill/proc/verify(condition, message)
	if(!condition)
		fail(message)
		refill_failed = TRUE

/datum/unit_test/atmos_machinery/canister_refill/start_test()
	var/turf/test_turf = get_safe_turf()
	if(!test_turf)
		fail("No safe test turf is available.")
		return 1
	var/list/original_tanks = station_gas_tanks
	station_gas_tanks = list()
	var/obj/machinery/portable_atmospherics/canister/air/air_station = new(test_turf)
	var/obj/machinery/portable_atmospherics/canister/empty/air/empty_air_station = new(test_turf)
	var/obj/machinery/portable_atmospherics/canister/oxygen/oxygen_station = new(test_turf)
	var/obj/item/tank/air/portable_tank = new(test_turf)
	verify(!air_station.refill_tank(portable_tank), "Air station filled a tank without a station reserve.")
	verify(!air_station.air_contents.total_moles, "Station-fed air dispenser created a duplicate reserve.")
	var/obj/machinery/station_gas_tank/reserve = new(test_turf)
	reserve.stat = NOPOWER
	air_station.stat = NOPOWER
	var/reserve_before = reserve.air_contents.total_moles
	var/tank_before = portable_tank.air_contents.total_moles
	for(var/cycle in 1 to 10)
		reserve.Process()
		air_station.refill_tank(portable_tank)
	verify(abs(portable_tank.air_contents.return_pressure() - 10 * ONE_ATMOSPHERE) < 0.1, "Unpowered air station did not fill to 10 atmospheres.")
	verify(abs(reserve_before - reserve.air_contents.total_moles - portable_tank.air_contents.total_moles + tank_before) < 0.01, "Station-fed refill did not conserve gas.")
	verify(!air_station.refill_tank(portable_tank), "Full tank continued consuming reserve gas.")
	verify(empty_air_station.get_refill_source() == reserve.air_contents, "Empty air subtype did not resolve the shared reserve.")
	verify(oxygen_station.get_refill_source() == oxygen_station.air_contents, "Oxygen station incorrectly used the shared reserve.")
	QDEL_NULL(portable_tank.air_contents)
	portable_tank.air_contents = new(portable_tank.volume, T20C)
	reserve.Process()
	reserve.supply_allocations[oxygen_station] = reserve.max_output_moles
	verify(!air_station.refill_tank(portable_tank), "Tank refill stole gas allocated to vents.")
	reserve.supply_allocations.Cut()
	reserve.enabled = FALSE
	verify(!air_station.refill_tank(portable_tank), "Disabled reserve supplied a refill.")
	reserve.enabled = TRUE
	reserve.stat = BROKEN
	verify(!air_station.refill_tank(portable_tank), "Broken reserve supplied a refill.")
	reserve.stat = NOPOWER
	reserve.max_output_moles = 1
	reserve.Process()
	verify(air_station.refill_tank(portable_tank) <= 1 + ATMOS_PRECISION, "Refill exceeded the reserve output limit.")
	verify(!air_station.refill_tank(portable_tank), "Repeated refill exceeded the same cycle's output limit.")
	for(var/source_temperature in list(80, T20C, 600))
		QDEL_NULL(oxygen_station.air_contents)
		oxygen_station.air_contents = new(oxygen_station.volume, source_temperature)
		oxygen_station.air_contents.adjust_gas(GAS_OXYGEN, oxygen_station.MolesForPressure())
		QDEL_NULL(portable_tank.air_contents)
		portable_tank.air_contents = new(portable_tank.volume, T20C)
		portable_tank.air_contents.adjust_gas(GAS_OXYGEN, ONE_ATMOSPHERE * portable_tank.volume / (R_IDEAL_GAS_EQUATION * T20C))
		var/initial_total = oxygen_station.air_contents.total_moles + portable_tank.air_contents.total_moles
		for(var/cycle in 1 to 100)
			oxygen_station.refill_tank(portable_tank)
			verify(portable_tank.air_contents.return_pressure() <= 10 * ONE_ATMOSPHERE + 0.1, "Refill exceeded safe pressure at [source_temperature] K.")
		verify(abs(portable_tank.air_contents.return_pressure() - 10 * ONE_ATMOSPHERE) < 0.1, "Refill did not reach target at [source_temperature] K.")
		verify(abs(initial_total - oxygen_station.air_contents.total_moles - portable_tank.air_contents.total_moles) < 0.01, "Specialty refill did not conserve gas at [source_temperature] K.")
	QDEL_NULL(oxygen_station.air_contents)
	oxygen_station.air_contents = new(oxygen_station.volume, T20C)
	oxygen_station.air_contents.adjust_gas(GAS_OXYGEN, 0.05)
	QDEL_NULL(portable_tank.air_contents)
	portable_tank.air_contents = new(portable_tank.volume, T20C)
	for(var/cycle in 1 to 20)
		oxygen_station.refill_tank(portable_tank)
	verify(portable_tank.air_contents.total_moles <= 0.05 + ATMOS_PRECISION, "Finite oxygen source generated gas.")
	verify(!oxygen_station.refill_tank(portable_tank), "Depleted oxygen source continued filling.")
	var/obj/modcon_supply_test_room/room = new(test_turf)
	room.test_air = new(CELL_VOLUME, T20C)
	oxygen_station.forceMove(room)
	oxygen_station.valve_open = TRUE
	oxygen_station.Process()
	verify(!room.test_air.total_moles && !oxygen_station.valve_open, "Legacy valve state released gas into the room.")
	oxygen_station.forceMove(test_turf)
	var/obj/item/wrench/wrench = new(test_turf)
	var/mob/living/carbon/human/canister_refill_test/user = new(test_turf)
	oxygen_station.attackby(wrench, user)
	oxygen_station.disconnect()
	var/obj/machinery/atmospherics/portables_connector/connector = new(test_turf)
	verify(!oxygen_station.connect(connector) && oxygen_station.anchored, "Connector lifecycle made the station movable.")
	user.put_in_hands(portable_tank)
	user.refuse_unequip = TRUE
	oxygen_station.attackby(portable_tank, user)
	verify(!oxygen_station.holding && portable_tank.loc == user, "Station inserted a tank after failed unequip.")
	user.refuse_unequip = FALSE
	oxygen_station.attackby(portable_tank, user)
	verify(oxygen_station.holding == portable_tank && portable_tank.loc == oxygen_station, "Tank insertion failed.")
	var/obj/item/tank/air/second_tank = new(test_turf)
	user.put_in_hands(second_tank)
	oxygen_station.attackby(second_tank, user)
	verify(oxygen_station.holding == portable_tank && second_tank.loc == user, "Occupied station accepted a second tank.")
	oxygen_station.attack_hand(user)
	verify(!oxygen_station.holding && portable_tank.loc == user, "Click did not retrieve the tank into a free hand.")
	var/obj/item/tank/jetpack/oxygen/jetpack = new(test_turf)
	var/mob/living/silicon/robot/robot = new(test_turf)
	reserve.max_output_moles = 100
	reserve.Process()
	var/jetpack_before = jetpack.air_contents.total_moles
	air_station.attackby(jetpack, robot)
	verify(jetpack.air_contents.total_moles > jetpack_before && !air_station.holding, "Robot jetpack did not refill without occupying the slot.")
	qdel(jetpack)
	qdel(robot)
	qdel(user)
	qdel(portable_tank)
	qdel(second_tank)
	qdel(wrench)
	qdel(connector)
	qdel(room)
	qdel(oxygen_station)
	qdel(air_station)
	qdel(empty_air_station)
	qdel(reserve)
	station_gas_tanks = original_tanks
	if(!refill_failed)
		pass("Fixed stations refill safely without power, preserve finite gas and vent allocations, and handle tank inventory.")
	return 1

/datum/unit_test/atmos_machinery/modcon_recovery
	name = "ATMOS MACHINERY: Modcon filters recovered gas before reserve storage"

/datum/unit_test/atmos_machinery/modcon_recovery/start_test()
	var/turf/test_turf = get_safe_turf()
	if(!test_turf)
		fail("No safe test turf is available.")
		return 1
	var/obj/machinery/station_gas_tank/reserve = new(test_turf)
	var/obj/machinery/alarm/modcon = new(test_turf)
	var/datum/gas_mixture/room = new(CELL_VOLUME, T20C)
	room.adjust_multi(GAS_OXYGEN, 20, GAS_NITROGEN, 70, GAS_CO2, 5, GAS_PHORON, 5)
	modcon.stat = 0
	reserve.stat = 0
	var/failed = FALSE
	var/reserve_before = reserve.air_contents.total_moles
	var/integrity_before = modcon.cartridge.integrity
	var/flow = modcon.recover_air(reserve, room, 50)
	if(abs(flow - 50) > 0.01 || abs(reserve.air_contents.total_moles - reserve_before - 45) > 0.01 || reserve.air_contents.get_gas(GAS_CO2) || reserve.air_contents.get_gas(GAS_PHORON) || modcon.cartridge.integrity >= integrity_before)
		fail("Recovered gas was not filtered, conserved, or charged to the cartridge.")
		failed = TRUE
	for(var/fault in list(NOPOWER, BROKEN))
		modcon.stat = fault
		if(modcon.recover_air(reserve, room, 10))
			fail("Faulted modcon recovered gas.")
			failed = TRUE
	modcon.stat = 0
	modcon.cartridge.integrity = 0
	if(modcon.recover_air(reserve, room, 10))
		fail("Exhausted cartridge recovered gas.")
		failed = TRUE
	modcon.cartridge.integrity = modcon.cartridge.max_integrity
	var/obj/item/weapon/chemical_scrubber/filter = modcon.cartridge
	modcon.cartridge = null
	if(modcon.recover_air(reserve, room, 10))
		fail("Missing cartridge recovered gas.")
		failed = TRUE
	modcon.cartridge = filter
	modcon.mode = AALARM_MODE_OFF
	if(modcon.recover_air(reserve, room, 10))
		fail("Switched-off modcon recovered gas.")
		failed = TRUE
	modcon.mode = AALARM_MODE_SCRUBBING
	reserve.max_pressure = reserve.air_contents.return_pressure()
	var/room_before = room.total_moles
	if(modcon.recover_air(reserve, room, 10) || abs(room.total_moles - room_before) > ATMOS_PRECISION)
		fail("Full reserve allowed room gas removal.")
		failed = TRUE
	qdel(room)
	qdel(modcon)
	qdel(filter)
	qdel(reserve)
	if(!failed)
		pass("Recovery filters contaminants, wears cartridges, and respects filter faults and reserve capacity.")
	return 1

/datum/unit_test/atmos_machinery/modcon_cold_start
	name = "ATMOS MACHINERY: Cold starting air is safe without suppressing modcon hazards"

/datum/unit_test/atmos_machinery/modcon_cold_start/start_test()
	var/turf/source_turf = get_space_turf()
	var/turf/simulated/test_turf = get_safe_turf()
	if(!source_turf || !istype(test_turf))
		fail("No space and simulated safe turfs are available.")
		return 1
	var/original_temperature = source_turf.temperature
	var/list/original_gas = source_turf.initial_gas
	var/datum/gas_mixture/original_source_air = source_turf.air
	var/area/test_area = get_area(test_turf)
	var/obj/machinery/alarm/original_master = test_area.master_air_alarm
	var/obj/machinery/alarm/modcon = new(test_turf)
	var/obj/machinery/alarm/server/server = new(test_turf)
	var/failed = FALSE
	var/turf/default_turf = /turf
	var/default_temperature = initial(default_turf.temperature)
	source_turf.temperature = default_temperature
	source_turf.initial_gas = list(GAS_OXYGEN = MOLES_O2STANDARD, GAS_NITROGEN = MOLES_N2STANDARD)
	var/datum/gas_mixture/room = source_turf.return_air()
	source_turf.make_air()
	var/datum/gas_mixture/created_air = source_turf.air
	if(abs(room.return_pressure() - ONE_ATMOSPHERE) > 0.01 || abs(created_air.return_pressure() - ONE_ATMOSPHERE) > 0.01 || room.temperature != source_turf.temperature)
		fail("Default cold air pressure is [room.return_pressure()] kPa (make_air: [created_air.return_pressure()]), temperature [room.temperature] K.")
		failed = TRUE
	if(modcon.overall_danger_level(room) || server.overall_danger_level(room))
		fail("Cold startup sensors: pressure [modcon.pressure_dangerlevel], oxygen [modcon.oxygen_dangerlevel], temperature [modcon.temperature_dangerlevel]; server temperature [server.temperature_dangerlevel].")
		failed = TRUE
	if(server.TLV["temperature"][3] != T0C+30 || server.TLV["temperature"][4] != T0C+40)
		fail("Server modcon lost its specialized upper temperature limits.")
		failed = TRUE
	var/zone/original_zone = test_turf.zone
	var/datum/gas_mixture/original_air = test_turf.air
	test_turf.zone = null
	test_turf.air = room
	modcon.stat = 0
	modcon.report_danger_level = FALSE
	modcon.Process()
	if(modcon.danger_level || !modcon.regulating_temperature)
		fail("First cold-start process raised danger [modcon.danger_level] or refused its existing heating target.")
		failed = TRUE
	room.temperature = modcon.target_temperature
	modcon.handle_heating_cooling(room)
	if(modcon.regulating_temperature || modcon.overall_danger_level(room))
		fail("Temperature regulation did not stop safely at the existing target.")
		failed = TRUE
	test_turf.air = original_air
	test_turf.zone = original_zone
	for(var/hazard in list("vacuum", "oxygen", "pressure", "carbon dioxide", "phoron", "cold", "hot"))
		var/datum/gas_mixture/unsafe_air = new(CELL_VOLUME, default_temperature)
		unsafe_air.adjust_multi(GAS_OXYGEN, MOLES_O2STANDARD * T20C / unsafe_air.temperature, GAS_NITROGEN, MOLES_N2STANDARD * T20C / unsafe_air.temperature)
		switch(hazard)
			if("vacuum")
				unsafe_air.remove(unsafe_air.total_moles)
			if("oxygen")
				var/oxygen_moles = unsafe_air.get_gas(GAS_OXYGEN)
				unsafe_air.adjust_multi(GAS_OXYGEN, -oxygen_moles, GAS_NITROGEN, oxygen_moles)
			if("pressure")
				unsafe_air.adjust_gas(GAS_NITROGEN, unsafe_air.total_moles)
			if("carbon dioxide")
				unsafe_air.adjust_gas(GAS_CO2, 20)
			if("phoron")
				unsafe_air.adjust_gas(GAS_PHORON, 2)
			if("cold")
				unsafe_air.temperature = T0C-27
			if("hot")
				unsafe_air.temperature = T0C+67
		if(modcon.overall_danger_level(unsafe_air) != 2)
			fail("Modcon failed to detect the [hazard] hazard immediately.")
			failed = TRUE
		qdel(unsafe_air)
	for(var/preset in list("vacuum", "nitrogen", "tank", "custom", "warm"))
		source_turf.temperature = default_temperature
		source_turf.initial_gas = list(GAS_OXYGEN = MOLES_O2STANDARD, GAS_NITROGEN = MOLES_N2STANDARD)
		switch(preset)
			if("vacuum")
				source_turf.initial_gas = null
			if("nitrogen")
				source_turf.initial_gas = list(GAS_NITROGEN = MOLES_N2STANDARD)
			if("tank")
				source_turf.initial_gas = list(GAS_OXYGEN = MOLES_O2ATMOS, GAS_NITROGEN = MOLES_N2ATMOS)
			if("custom")
				source_turf.initial_gas[GAS_CO2] = 5
			if("warm")
				source_turf.temperature = T20C
		var/datum/gas_mixture/preset_air = source_turf.return_air()
		for(var/gasid in preset_air.gas)
			if(preset_air.gas[gasid] != source_turf.initial_gas[gasid])
				fail("Initialization changed the deliberate [preset] preset.")
				failed = TRUE
		qdel(preset_air)
	source_turf.temperature = original_temperature
	source_turf.initial_gas = original_gas
	source_turf.air = original_source_air
	test_area.master_air_alarm = original_master
	var/obj/item/weapon/chemical_scrubber/filter = modcon.cartridge
	var/obj/item/weapon/chemical_scrubber/server_filter = server.cartridge
	qdel(modcon)
	qdel(server)
	qdel(filter)
	qdel(server_filter)
	qdel(room)
	qdel(created_air)
	if(!failed)
		pass("Cold default air, first processing, regulation, server limits, custom presets and genuine hazards behave correctly.")
	return 1

#undef ALL_GASIDS