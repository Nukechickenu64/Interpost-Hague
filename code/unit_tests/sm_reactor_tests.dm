/datum/unit_test/sm_reactor_field_decay_bounds
	name = "SUPERMATTER REACTOR: Field decay time spans 60 minutes at minimum output to 5 minutes at maximum"

/datum/unit_test/sm_reactor_field_decay_bounds/start_test()
	var/obj/machinery/power/sm_reactor/R = new(get_safe_turf())
	R.set_output_level(1)
	var/slowest = R.field_decay_time()
	R.set_output_level(R.max_output_level)
	var/fastest = R.field_decay_time()
	qdel(R)
	if(slowest != 60 MINUTES || fastest != 5 MINUTES)
		fail("Expected decay times of [60 MINUTES] and [5 MINUTES], got [slowest] and [fastest].")
	else
		pass("Field decay time scales between 60 and 5 minutes.")
	return 1

/datum/unit_test/sm_reactor_scram_refused_when_critical
	name = "SUPERMATTER REACTOR: SCRAM is refused below 15% integrity"

/datum/unit_test/sm_reactor_scram_refused_when_critical/start_test()
	var/obj/machinery/power/sm_reactor/R = new(get_safe_turf())
	R.fuel_sheets = 10
	R.start_reactor()
	R.integrity = 10
	var/critical_result = R.scram()
	R.integrity = 50
	var/healthy_result = R.scram()
	R.state = SMR_STATE_OFF
	qdel(R)
	if(critical_result || !healthy_result)
		fail("SCRAM results were [critical_result] at 10% and [healthy_result] at 50% integrity.")
	else
		pass("SCRAM is refused at critical integrity and accepted otherwise.")
	return 1
