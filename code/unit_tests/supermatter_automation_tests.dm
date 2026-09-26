/datum/unit_test/supermatter_controller_processing
	name = "SUPERMATTER: Automatic controller remains scheduled"

/datum/unit_test/supermatter_controller_processing/start_test()
	var/obj/machinery/computer/general_air_control/supermatter_core/control = new
	if(control.Process() == PROCESS_KILL)
		fail("The controller stopped processing before automatic mode could be enabled.")
	else
		pass("The controller remains in the machinery processing queue.")
	qdel(control)
	return 1

/datum/unit_test/supermatter_automatic_setpoints
	name = "SUPERMATTER: Automatic cooling increases exhaust as temperature rises"

/datum/unit_test/supermatter_automatic_setpoints/start_test()
	var/obj/machinery/computer/general_air_control/supermatter_core/control = new
	var/failed = FALSE
	var/list/temperatures = list(1000, 2500, 3500, 4500)
	var/list/flows = list(700, 900, 1100, 1200)
	var/list/pressures = list(100, 75, 50, 25)
	for(var/index = 1 to temperatures.len)
		control.update_automatic_setpoints(temperatures[index], 5000, SUPERMATTER_NORMAL, 2, TRUE, 200)
		if(control.automatic_flow_setting != flows[index] || control.automatic_pressure_setting != pressures[index])
			failed = TRUE
			log_bad("At [temperatures[index]] K, expected [flows[index]] L/s and [pressures[index]] kPa, got [control.automatic_flow_setting] L/s and [control.automatic_pressure_setting] kPa.")

	control.update_automatic_setpoints(4000, 5000, SUPERMATTER_DANGER, 2, TRUE, 200)
	if(control.automatic_pressure_setting != 25)
		failed = TRUE
		log_bad("Damaged crystal did not get maximum exhaust.")

	control.update_automatic_setpoints(4500, 5000, SUPERMATTER_NORMAL, 0.4, TRUE, 200)
	if(control.automatic_pressure_setting != 201)
		failed = TRUE
		log_bad("Low coolant did not stop the outpump from draining the chamber.")

	control.update_automatic_setpoints(4500, 5000, SUPERMATTER_NORMAL, 2, FALSE, 200)
	if(control.automatic_pressure_setting != 201)
		failed = TRUE
		log_bad("Unavailable cooling did not stop the outpump from draining the chamber.")

	qdel(control)
	if(!failed)
		pass("Automatic cooling increases exhaust while protecting a starved chamber.")
	return 1

/datum/unit_test/supermatter_emitter_interlock
	name = "SUPERMATTER: Remote shutdown overrides emitter control lock"

/datum/unit_test/supermatter_emitter_interlock/start_test()
	var/obj/machinery/power/emitter/emitter = new
	emitter.active = TRUE
	emitter.locked = TRUE
	emitter.remote_set_active(FALSE)
	if(emitter.active)
		fail("Locked emitter ignored the automatic safety shutdown.")
	else
		pass("Locked emitter accepts the automatic safety shutdown.")
	qdel(emitter)
	return 1

/datum/unit_test/supermatter_generation_target
	name = "SUPERMATTER: Automatic excitation targets generator watts"

/datum/unit_test/supermatter_generation_target/start_test()
	var/obj/machinery/computer/general_air_control/supermatter_core/control = new
	var/failed = FALSE
	if(!control.needs_excitation(0, 0) || !control.needs_excitation(249999, 250))
		failed = TRUE
		log_bad("Cold or underproducing reactor failed to request emitter startup.")
	if(!control.needs_excitation(250000, 250))
		failed = TRUE
		log_bad("Emitters stopped immediately at 250 kW without a power buffer.")
	if(control.needs_excitation(275000, 250) || control.needs_excitation(260000, 0))
		failed = TRUE
		log_bad("Emitters continued firing after reaching the 275 kW shutoff threshold.")
	if(!control.needs_excitation(249999, 250))
		failed = TRUE
		log_bad("Emitters failed to restart below 250 kW.")
	if(control.needs_excitation(0, control.max_excitation))
		failed = TRUE
		log_bad("Excitation did not stop at its safe crystal power cap.")
	qdel(control)
	if(!failed)
		pass("Generator watts control emitter startup and the 250 kW target.")
	return 1