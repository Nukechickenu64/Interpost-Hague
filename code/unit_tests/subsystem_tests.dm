/datum/unit_test/subsystem_atom_shall_have_no_bad_init_calls
	name = "SUBSYSTEM - ATOMS: Shall have no bad init calls"

/datum/unit_test/subsystem_atom_shall_have_no_bad_init_calls/start_test()
	if(SSatoms.BadInitializeCalls.len)
		log_bad(jointext(SSatoms.InitLog(), null))
		fail("[SSatoms] had bad initialization calls.")
	else
		pass("[SSatoms] had no bad initialization calls.")
	return 1

/datum/catalyst_event/unit_test_warning
	cooldown = 0
	warning_duration = 20
	var/conditions_active = TRUE

/datum/catalyst_event/unit_test_warning/check_conditions(var/datum/telemetry/T)
	return conditions_active

/datum/unit_test/director_catalyst_warning
	name = "DIRECTOR: Catalyst warnings allow response and clear when resolved"

/datum/unit_test/director_catalyst_warning/start_test()
	var/datum/telemetry/T = new
	var/datum/catalyst_event/unit_test_warning/C = new
	var/failed = FALSE

	if(C.can_trigger(T, TENSION_RISING) || !C.warning_active)
		failed = TRUE
		log_bad("Eligible catalyst did not start its warning delay.")

	C.conditions_active = FALSE
	if(C.can_trigger(T, TENSION_RISING) || C.warning_active)
		failed = TRUE
		log_bad("Resolved catalyst conditions did not cancel the warning.")

	C.conditions_active = TRUE
	if(C.can_trigger(T, TENSION_RISING) || !C.warning_active)
		failed = TRUE
		log_bad("Restored catalyst conditions did not begin a fresh warning.")

	C.warning_started = world.time - C.warning_duration
	if(!C.can_trigger(T, TENSION_RISING))
		failed = TRUE
		log_bad("Catalyst did not become eligible after the warning delay.")

	C.reset()
	if(C.warning_active || C.warning_started)
		failed = TRUE
		log_bad("Round reset did not clear the catalyst warning.")

	qdel(C)
	qdel(T)
	if(failed)
		fail("Catalyst warning state transitions were incorrect.")
	else
		pass("Catalyst warning starts, cancels on recovery, delays execution, and resets cleanly.")
	return 1
