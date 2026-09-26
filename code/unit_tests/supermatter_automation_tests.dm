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
	var/list/temperatures = list(1000, 2500, 2850, 3000, 3200, 4500)
	var/list/flows = list(700, 700, 900, 1100, 1200, 1200)
	var/list/pressures = list(300, 300, 250, 150, 25, 100)
	for(var/index = 1 to temperatures.len)
		control.update_automatic_setpoints(temperatures[index], 5000, SUPERMATTER_NORMAL, 2, TRUE, 200)
		if(control.automatic_flow_setting != flows[index] || control.automatic_pressure_setting != pressures[index])
			failed = TRUE
			log_bad("At [temperatures[index]] K, expected [flows[index]] L/s and [pressures[index]] kPa, got [control.automatic_flow_setting] L/s and [control.automatic_pressure_setting] kPa.")
	control.update_automatic_setpoints(1000, 5000, SUPERMATTER_NORMAL, 2, TRUE, 90)
	if(control.automatic_pressure_setting != 300)
		failed = TRUE
		log_bad("Healthy cold core did not retain incoming gas during warm-up.")

	control.update_automatic_setpoints(4000, 5000, SUPERMATTER_DANGER, 2, TRUE, 200)
	if(control.automatic_pressure_setting != 100)
		failed = TRUE
		log_bad("Hot crystal did not exhaust while retaining one EPR of coolant.")

	control.update_automatic_setpoints(4500, 5000, SUPERMATTER_NORMAL, 0.4, TRUE, 200)
	if(control.automatic_pressure_setting != 25)
		failed = TRUE
		log_bad("Low coolant blocked emergency exhaust.")

	control.update_automatic_setpoints(4500, 5000, SUPERMATTER_NORMAL, 2, FALSE, 200)
	if(control.automatic_pressure_setting != 100)
		failed = TRUE
		log_bad("Missing feed blocked emergency exhaust.")

	control.update_automatic_setpoints(5568, 5000, SUPERMATTER_WARNING, 0.4, FALSE, 4344.7)
	if(control.automatic_pressure_setting != 25 || control.automatic_flow_setting != 1200 || control.automatic_pressure_setting >= 4344.7)
		failed = TRUE
		log_bad("Overheated, damaged core did not allow hot gas to escape.")
	control.update_automatic_setpoints(5568, 5000, SUPERMATTER_WARNING, 10, FALSE, 4344.7)
	if(abs(control.automatic_pressure_setting - 434.47) > 0.1)
		failed = TRUE
		log_bad("Emergency exhaust did not preserve a bounded coolant reserve.")
	var/datum/gas_mixture/chamber_air = new(CELL_VOLUME, 5568)
	chamber_air.adjust_gas("nitrogen", 4344.7 * CELL_VOLUME / (R_IDEAL_GAS_EQUATION * 5568))
	var/obj/machinery/atmospherics/unary/vent_pump/outpump = new
	outpump.pump_direction = 0
	outpump.pressure_checks = 1
	outpump.external_pressure_bound = 4345.7
	if(outpump.get_pressure_delta(chamber_air) > 0.5)
		failed = TRUE
		log_bad("The screenshot's blocked siphon unexpectedly moved gas.")
	outpump.external_pressure_bound = control.automatic_pressure_setting
	if(outpump.get_pressure_delta(chamber_air) <= 0.5)
		failed = TRUE
		log_bad("Emergency siphon setpoint did not permit gas flow.")
	qdel(outpump)
	qdel(chamber_air)

	control.update_automatic_setpoints(1000, 5000, SUPERMATTER_NORMAL, 0.4, FALSE, 200)
	if(control.automatic_pressure_setting != 201)
		failed = TRUE
		log_bad("Cool core with unavailable feed did not retain chamber gas.")
	control.set_target_temperature(300)
	control.update_automatic_setpoints(500, 5000, SUPERMATTER_NORMAL, 0.4, FALSE, 200)
	if(control.automatic_pressure_setting != 201)
		failed = TRUE
		log_bad("Low player target overrode cool-core gas retention.")
	control.update_automatic_setpoints(3500, 5000, SUPERMATTER_NORMAL, 0.4, FALSE, 200)
	if(control.automatic_pressure_setting != 25)
		failed = TRUE
		log_bad("Fixed pre-danger temperature did not override gas retention.")
	control.update_automatic_setpoints(1000, 5000, SUPERMATTER_WARNING, 0.4, FALSE, 200)
	if(control.automatic_pressure_setting != 201)
		failed = TRUE
		log_bad("Cool but previously damaged core lost its coolant reserve.")

	qdel(control)
	if(!failed)
		pass("Automatic cooling increases exhaust while protecting a starved chamber.")
	return 1

/datum/unit_test/supermatter_temperature_target
	name = "SUPERMATTER: Automatic target controls heating without bypassing safety"

/datum/unit_test/supermatter_temperature_target/start_test()
	var/obj/machinery/computer/general_air_control/supermatter_core/control = new
	var/failed = FALSE
	control.automatic_management = TRUE
	if(control.set_target_temperature(null) || control.set_target_temperature(299) || control.set_target_temperature(3501) || control.target_temperature != 3000)
		failed = TRUE
		log_bad("Invalid input changed the core target.")
	if(!control.set_target_temperature(3500) || control.target_temperature != 3500)
		failed = TRUE
		log_bad("The highest safe target was rejected.")
	if(!control.needs_excitation(0, 500, 3400) || control.needs_excitation(0, 500, 3500))
		failed = TRUE
		log_bad("The higher target did not stop excitation at its setpoint.")
	if(!control.set_target_temperature(1600) || control.target_temperature != 1600 || !control.automatic_management)
		failed = TRUE
		log_bad("Valid target was rejected or disabled automatic mode.")
	if(!control.needs_excitation(0, 0, 1400) || control.needs_excitation(0, 0, 1600) || control.needs_excitation(0, 0, 1550) || !control.needs_excitation(0, 0, 1500))
		failed = TRUE
		log_bad("Emitter temperature deadband ignored the requested target.")
	control.update_automatic_setpoints(1600, 5000, SUPERMATTER_NORMAL, 2, TRUE, 200)
	if(control.automatic_flow_setting != 1100 || control.automatic_pressure_setting != 150)
		failed = TRUE
		log_bad("Coolant did not respond at the selected temperature.")
	qdel(control)
	if(!failed)
		pass("Temperature target bounds, cooling and emitter deadband are respected.")
	return 1

/datum/unit_test/supermatter_automatic_safety
	name = "SUPERMATTER: Automatic shutdown keeps a margin below damage"

/datum/unit_test/supermatter_automatic_safety/start_test()
	var/obj/machinery/computer/general_air_control/supermatter_core/control = new
	var/failed = FALSE
	if(control.automatic_danger(SUPERMATTER_NORMAL, 100, 3799, 5000, 2, TRUE, TRUE))
		failed = TRUE
		log_bad("Healthy core shut down below the automatic cutoff.")
	if(!control.automatic_danger(SUPERMATTER_NORMAL, 100, 3800, 5000, 2, TRUE, TRUE) || !control.automatic_danger(SUPERMATTER_NOTIFY, 100, 4001, 5000, 2, TRUE, TRUE) || !control.automatic_danger(SUPERMATTER_WARNING, 99, 5000, 5000, 2, TRUE, TRUE))
		failed = TRUE
		log_bad("Hot or elevated-status core bypassed shutdown.")
	if(!control.automatic_danger(SUPERMATTER_NORMAL, 99, 3000, 5000, 2, TRUE, TRUE) || !control.automatic_danger(SUPERMATTER_NORMAL, 100, 3000, 5000, 0.5, TRUE, TRUE) || !control.automatic_danger(SUPERMATTER_NORMAL, 100, 3000, 5000, 2, FALSE, TRUE))
		failed = TRUE
		log_bad("Damage or coolant shortage bypassed shutdown.")
	qdel(control)
	if(!failed)
		pass("Thermal, damage, status and coolant interlocks remain active.")
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
	if(!control.needs_excitation(0, 0, 1000) || !control.needs_excitation(249999, 250, 1000))
		failed = TRUE
		log_bad("Cold or underproducing reactor failed to request emitter startup.")
	if(!control.needs_excitation(250000, 250, 1000))
		failed = TRUE
		log_bad("Emitters stopped immediately at 250 kW without a power buffer.")
	if(control.needs_excitation(275000, 250, 1000) || control.needs_excitation(260000, 0, 1000))
		failed = TRUE
		log_bad("Emitters continued firing after reaching the 275 kW shutoff threshold.")
	if(!control.needs_excitation(249999, 250, 1000))
		failed = TRUE
		log_bad("Emitters failed to restart below 250 kW.")
	if(!control.needs_excitation(0, 500, 1000))
		failed = TRUE
		log_bad("Emitter cap blocked higher safe excitation.")
	if(control.needs_excitation(0, control.max_excitation, 1000))
		failed = TRUE
		log_bad("Excitation did not stop at its safe crystal power cap.")
	qdel(control)
	if(!failed)
		pass("Generator watts control emitter startup and the 250 kW target.")
	return 1