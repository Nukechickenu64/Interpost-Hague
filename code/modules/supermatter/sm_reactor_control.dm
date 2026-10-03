/obj/machinery/computer/sm_reactor_control
	name = "supermatter reactor control console"
	desc = "Monitors and stabilises a phoron-fed supermatter reactor."
	icon_keyboard = "tech_key"
	icon_screen = "power"
	light_color = "#88aaff"
	circuit = /obj/item/circuitboard/sm_reactor_control
	var/reactor_id = "sm_reactor"
	var/obj/machinery/power/sm_reactor/reactor

/obj/machinery/computer/sm_reactor_control/proc/get_reactor()
	if(istype(reactor) && !QDELETED(reactor))
		return reactor
	reactor = null
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/list/valid_z = GetConnectedZlevels(T.z)
	for(var/obj/machinery/power/sm_reactor/R in SSmachines.machinery)
		if(R.reactor_id == reactor_id && (R.z in valid_z))
			reactor = R
			break
	return reactor

/obj/machinery/computer/sm_reactor_control/attack_hand(mob/user)
	if(..())
		return
	ui_interact(user)

/obj/machinery/computer/sm_reactor_control/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/data[0]
	var/obj/machinery/power/sm_reactor/R = get_reactor()
	data["linked"] = !!R
	if(R)
		var/list/anomaly_data = list()
		for(var/id in R.anomalies)
			var/deadline = R.anomalies[id]
			anomaly_data[++anomaly_data.len] = list(
				"id" = id,
				"time_left" = deadline ? max(0, round((deadline - world.time) / 10)) : -1
			)
		data["state"] = R.state
		data["output_level"] = R.output_level
		data["max_output_level"] = R.max_output_level
		data["output_kw"] = R.state == SMR_STATE_RUNNING ? round(R.current_output() / 1000) : 0
		data["fuel"] = round(R.fuel_sheets, 0.1)
		data["max_fuel"] = R.max_fuel_sheets
		data["field"] = round(R.field)
		data["integrity"] = round(R.integrity)
		data["window_open"] = R.window_open()
		data["window_left"] = R.window_open() ? round((R.pulse_window_until - world.time) / 10) : 0
		data["anomalies"] = anomaly_data
		data["coolant_charges"] = R.coolant_charges
		data["max_coolant_charges"] = R.max_coolant_charges
		data["scram_left"] = max(0, round((R.scram_until - world.time) / 10))

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "sm_reactor.tmpl", name, 520, 620)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/computer/sm_reactor_control/OnTopic(mob/user, href_list)
	var/obj/machinery/power/sm_reactor/R = get_reactor()
	if(!R)
		return TOPIC_REFRESH
	switch(href_list["action"])
		if("start")
			R.start_reactor()
		if("level")
			R.set_output_level(R.output_level + text2num(href_list["change"]))
		if("pulse")
			R.pulse_field()
		if("throttle")
			R.resolve_anomaly(SMR_ANOMALY_SURGE)
		if("damp")
			R.resolve_anomaly(SMR_ANOMALY_CASCADE)
		if("flush")
			R.resolve_anomaly(SMR_ANOMALY_RUNAWAY)
		if("scram")
			R.scram()
		else
			return TOPIC_NOACTION
	R.update_icon()
	return TOPIC_REFRESH
