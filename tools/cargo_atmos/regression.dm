// Uses the production map, then exits without starting a round.
/hook/startup/proc/cargo_atmos_regression_log()
	fdel("tmp/cargo-atmos/regression.log")
	world.log = file("tmp/cargo-atmos/regression.log")
	return TRUE

SUBSYSTEM_DEF(cargo_atmos_regression)
	name = "Cargo atmosphere regression"
	init_order = -INFINITY
	flags = SS_NO_FIRE

/datum/controller/subsystem/cargo_atmos_regression/Initialize(timeofday)
	SSticker.can_fire = FALSE
	. = ..()
	var/datum/unit_test/human_environment_breath/breath_test = new
	breath_test.start_test()
	var/failed = failed_unit_tests || !breath_test.reported
	if(istype(GLOB.using_map, /datum/map/os13classic))
		failed |= check_elevator()
	else
		world.log << "CARGO_ATMOS: production map must be OS13 Classic."
		failed = TRUE
	world.log << "CARGO_ATMOS_RESULT: [failed ? "FAIL" : "PASS"] runtimes=[GLOB.total_runtimes]"
	del(world)

/datum/controller/subsystem/cargo_atmos_regression/proc/check_elevator()
	var/area/cargo_bay/cargo = locate()
	var/list/people = list()
	for(var/list/position in list(list(135, 125, 1), list(137, 125, 1), list(135, 128, 1)))
		var/turf/simulated/T = locate(position[1], position[2], position[3])
		if(!istype(T) || get_area(T) != cargo || !T.zone)
			world.log << "CARGO_ATMOS: missing cargo elevator fixture at [position.Join(",")]."
			return TRUE
		people += new /mob/living/carbon/human(T, SPECIES_HUMAN)
	// Random grille failures are independent of this breathing regression.
	for(var/obj/machinery/atmospherics/unary/vent_pump/vent in cargo)
		vent.malfunction_chance = 0
	var/minimum_air = INFINITY
	var/maximum_oxygen_loss = 0
	for(var/cycle in 1 to 200)
		for(var/mob/living/carbon/human/H in people)
			H.breathe()
			var/datum/gas_mixture/environment = H.loc.return_air()
			minimum_air = min(minimum_air, environment.get_tile_moles())
			maximum_oxygen_loss = max(maximum_oxygen_loss, H.getOxyLoss())
		for(var/obj/machinery/alarm/controller in cargo)
			controller.Process()
		for(var/obj/machinery/station_gas_tank/tank in station_gas_tanks)
			tank.Process()
		for(var/obj/machinery/atmospherics/unary/vent_pump/vent in cargo)
			vent.Process()
		SSair.fire(FALSE, TRUE)
		CHECK_TICK
	world.log << "CARGO_ATMOS: 3 elevator occupants, 200 breathing/atmosphere cycles, minimum [minimum_air] mol/tile, maximum [maximum_oxygen_loss] oxygen loss."
	return minimum_air < HUMAN_SAFE_AIR_MOLES_MIN || maximum_oxygen_loss != 0
