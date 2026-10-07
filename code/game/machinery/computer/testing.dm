GLOBAL_DATUM_INIT(station_wake_sequence, /datum/station_wake_sequence, new)
GLOBAL_DATUM_INIT(bridge_crew_objectives, /datum/bridge_crew_objectives, new)

// Shared recovery objectives issued by the bridge report. Each objective is
// tied to a station state that the game can verify rather than a paper-only task.
/datum/bridge_crew_objectives
	var/issued = FALSE
	var/list/completed = list()
	var/power_stable_since = 0

/datum/bridge_crew_objectives/proc/reset()
	issued = FALSE
	completed.Cut()
	power_stable_since = 0

/datum/bridge_crew_objectives/proc/issue()
	issued = TRUE
	check_progress()

/datum/bridge_crew_objectives/proc/check_progress()
	if(!issued)
		return
	if(!completed["wake_station"] && GLOB.station_wake_sequence.started && !GLOB.station_wake_sequence.active)
		complete_objective("wake_station", "Station wake-up", 5)
	if(!completed["water_service"] && GLOB.waterchip_installed)
		complete_objective("water_service", "Water service restoration", 5)
	if(!completed["power_grid"])
		check_power_grid()

/datum/bridge_crew_objectives/proc/check_power_grid()
	var/powered = 0
	var/total = 0
	for(var/obj/machinery/power/area_smes/controller in SSmachines.machinery)
		if(!is_station_turf(get_turf(controller)))
			continue
		total++
		if(controller.operating)
			powered++
	if(!total || powered * 100 < total * 90)
		power_stable_since = 0
		return
	if(!power_stable_since)
		power_stable_since = world.time
		return
	if(world.time - power_stable_since >= 30 SECONDS)
		complete_objective("power_grid", "Power-grid stabilization", 10)

/datum/bridge_crew_objectives/proc/complete_objective(var/id, var/objective_name, var/reward)
	if(completed[id])
		return
	completed[id] = TRUE
	var/recipients = 0
	for(var/mob/living/carbon/human/crew_member in GLOB.player_list)
		if(!crew_member.client || !crew_member.mind || crew_member.stat == DEAD || !is_station_turf(get_turf(crew_member)) || player_is_antag(crew_member.mind))
			continue
		var/datum/preferences/prefs = crew_member.client.prefs
		if(!prefs)
			continue
		prefs.meta_currency += reward
		prefs.save_preferences()
		recipients++
		to_chat(crew_member, "<span class='notice'><b>Bridge recovery objective complete:</b> [objective_name]. +[reward] Leverage (total: [prefs.meta_currency]).</span>")
	command_announcement.Announce("[objective_name] is complete. [recipients] eligible crew member[recipients == 1 ? "" : "s"] received [reward] Leverage.", "Bridge Operations")

/datum/bridge_crew_objectives/proc/get_status_report()
	if(!issued)
		return "<p><b>Bridge recovery contract:</b> no report has been printed this shift.</p>"
	var/wake_status = completed["wake_station"] ? "Complete" : "Pending"
	var/water_status = completed["water_service"] ? "Complete" : "Pending"
	var/power_status = completed["power_grid"] ? "Complete" : "Pending"
	return "<h3>Bridge Recovery Contract</h3><table border='1' cellpadding='5'><tr><th>Objective</th><th>Status</th><th>Crew reward</th></tr><tr><td>Complete the WAKE STATION sequence</td><td>[wake_status]</td><td>5 Leverage</td></tr><tr><td>Install the water control chip</td><td>[water_status]</td><td>5 Leverage</td></tr><tr><td>Keep at least 90% of station power controllers online for 30 seconds</td><td>[power_status]</td><td>10 Leverage</td></tr></table><p>Rewards go to living, non-antagonist crew aboard when each objective clears.</p>"

/datum/station_wake_sequence
	var/active = FALSE
	var/started = FALSE
	var/list/targets = list()
	var/list/enabled_rooms = list()
	var/next_target = 1
	var/lights_started = 0
	var/thermostats_reset = 0
	var/mob/operator

/datum/station_wake_sequence/proc/start(mob/user)
	if(started)
		to_chat(user, "<span class='warning'>[active ? "A station wake sequence is already in progress." : "The station has already been awakened. Adjust lights and thermostats locally."]</span>")
		return FALSE
	started = TRUE
	active = TRUE
	operator = user
	next_target = 1
	lights_started = 0
	thermostats_reset = 0
	for(var/obj/machinery/light/fixture in world)
		if(fixture.z in GLOB.using_map.station_levels)
			fixture.bridge_startup_pending = !fixture.powered()
			targets += fixture
	for(var/obj/machinery/light_switch/light_switch in world)
		if(light_switch.z in GLOB.using_map.station_levels)
			targets += light_switch
	for(var/obj/machinery/alarm/alarm in world)
		if(alarm.z in GLOB.using_map.station_levels)
			targets += alarm
	to_chat(user, "<span class='notice'>Station wake sequence initiated: starting lights individually, then setting air alarm thermostats to 20°C, one device every half second.</span>")
	advance()
	return TRUE

/datum/station_wake_sequence/proc/enable_room(area/room)
	if(room && !(room in enabled_rooms))
		enabled_rooms += room
		room.set_lightswitch(TRUE, bridge_startup = TRUE)

/datum/station_wake_sequence/proc/advance()
	while(next_target <= length(targets))
		var/obj/machinery/target = targets[next_target++]
		if(QDELETED(target))
			continue
		if(istype(target, /obj/machinery/light))
			var/obj/machinery/light/fixture = target
			var/pending = fixture.bridge_startup_pending
			enable_room(get_area(fixture))
			if(pending)
				fixture.bridge_startup_pending = FALSE
				fixture.seton(fixture.powered())
				if(fixture.on)
					fixture.flicker(6, bridge_startup = TRUE)
					lights_started++
		else if(istype(target, /obj/machinery/light_switch))
			var/obj/machinery/light_switch/light_switch = target
			enable_room(light_switch.connected_area)
		else if(istype(target, /obj/machinery/alarm))
			var/obj/machinery/alarm/alarm = target
			alarm.target_temperature = T20C
			thermostats_reset++
		addtimer(CALLBACK(src, /datum/station_wake_sequence/proc/advance), 0.5 SECONDS)
		return
	active = FALSE
	targets.Cut()
	enabled_rooms.Cut()
	if(!QDELETED(operator))
		to_chat(operator, "<span class='notice'>Wake station command complete: [lights_started] lights started and [thermostats_reset] air alarms set to 20°C.</span>")
	operator = null
	GLOB.bridge_crew_objectives.check_progress()

/obj/machinery/computer/bridge
	name = "bridge computer"
	desc = "A battered command console wired into station comms and navigation. The CRT hums faintly."
	var/dispensed = 0 //why yes, I am stealing this from the nano code, how could you t-ACK!
	var/centcomm_message_cooldown = 0
	var/announcment_cooldown = 0
	var/datum/announcement/priority/crew_announcement = new
	var/current_viewing_message_id = 0
	var/current_viewing_message = null
	var/new_sound = 'sound/machines/announce_alarm.ogg'
	var/new_sound_red = 'sound/machines/announce_alarm_red.ogg'

/obj/machinery/computer/bridge/proc/topic_requires_command_access(var/list/href_list)
	if(!href_list || !href_list["action"])
		return FALSE
	var/action = href_list["action"]
	return (action in list("wake_station", "printstatus", "checkstationintegrity", "announce", "call_shuttle", "cancel_shuttle"))

/obj/machinery/computer/bridge/Topic(href, href_list, hsrc)
	if(..())
		return
	if(src.CanUseTopic(usr, GLOB.default_state, href_list) != STATUS_INTERACTIVE)
		return
	if(get_dist(src, usr) > 1)
		return
	switch(href_list["action"])
		if("cancel_shuttle")
			if(!usr.GetAccess(ACCESS_REGION_COMMAND))
				to_chat(usr, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
				playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
				return
			if(!SSevac.evacuation_controller || !SSevac.evacuation_controller.can_cancel())
				to_chat(usr, "<span class='warning'>The escape shuttle is not inbound and cannot be cancelled.</span>")
				return
			if(alert(usr, "Are you sure you want to cancel the escape shuttle?", name, "No", "Yes") != "Yes")
				return
			if(src.CanUseTopic(usr, GLOB.default_state, href_list) != STATUS_INTERACTIVE || get_dist(src, usr) > 1 || !usr.GetAccess(ACCESS_REGION_COMMAND))
				return
			cancel_call_proc(usr)
			show_menu(usr)
		if("call_shuttle")
			if(!usr.GetAccess(ACCESS_REGION_COMMAND))
				to_chat(usr, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
				playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
				return
			if(round_duration_in_ticks < 30 MINUTES)
				to_chat(usr, "<span class='warning'>Escape shuttle requests unlock 30 minutes after shift start.</span>")
				return
			if(alert(usr, "Are you sure you want to call the escape shuttle?", name, "No", "Yes") != "Yes")
				return
			if(src.CanUseTopic(usr, GLOB.default_state, href_list) != STATUS_INTERACTIVE || get_dist(src, usr) > 1 || !usr.GetAccess(ACCESS_REGION_COMMAND))
				return
			call_shuttle_proc(usr)
			show_menu(usr)
		if("wake_station")
			if(topic_requires_command_access(href_list) && !usr.GetAccess(ACCESS_REGION_COMMAND))
				to_chat(usr, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
				playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
				return
			wake_station()
			show_menu(usr)
		if("printstatus")
			if(topic_requires_command_access(href_list) && !usr.GetAccess(ACCESS_REGION_COMMAND))
				to_chat(usr, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
				playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
				return
			if(!dispensed)
				if(get_dist(src, usr) > 1)
					return
				src.audible_message("The computer makes a few noises as it dispenses a piece of paper.")
				playsound(src, 'sound/machines/dotprinter.ogg', 10, 1)
				var/obj/item/paper/R = new(src.loc)
				var/sname = station_name()
				var/full_text = "<b>BRIDGE COMMUNICATIONS REPORT</b>\n\n<b>From:</b> Emergency Operations Relay\n<b>To:</b> [sname] Bridge Operations\n<b>Subject:</b> Reserve-mode service restoration\n\nThe station is running on reserve-mode protocols. External traffic is intermittent; no off-station assignment or rescue operation has been authorized. Restore the services below so local operations can resume.\n\n<b>CREW RECOVERY CONTRACT</b>\n\n<ol><li><b>Wake the station.</b> Use WAKE STATION at this console. The sequence restores bridge-controlled lighting and resets station air-alarm thermostats to 20°C. <b>Reward: 5 Leverage for each eligible crew member.</b></li><li><b>Restore water service.</b> Install the portable water control chip in its holder. <b>Reward: 5 Leverage for each eligible crew member.</b></li><li><b>Stabilize the power grid.</b> Keep at least 90% of station power controllers online for 30 seconds. <b>Reward: 10 Leverage for each eligible crew member.</b></li></ol>\n\nCompletion is verified automatically. Rewards are deposited immediately to living, non-antagonist crew aboard the station when each objective clears. Review STATION STATUS at this console for live contract progress."
				GLOB.bridge_crew_objectives.issue()
				R.set_content(full_text)
				R.name = "Bridge Recovery Report"
				var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
				stampoverlay.icon_state = "paper_stamp-hos"
				R.stamped += /obj/item/stamp
				R.overlays += stampoverlay
				R.stamps += "<HR><i>This paper has been stamped as 'Top Secret'.</i>"
				dispensed = 1
				show_menu(usr)
			else
				to_chat(usr, "<span class='warning'>Communication logs have already been printed. The printer is unavailable.</span>")
		if("checkstationintegrity")
			if(topic_requires_command_access(href_list) && !usr.GetAccess(ACCESS_REGION_COMMAND))
				to_chat(usr, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
				playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
				return
			playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
			if(!SSdirector)
				to_chat(usr, "<span class='warning'>Station telemetry unavailable: AI Director is not initialized.</span>")
				return
			var/datum/browser/popup = new(usr, "bridge_station_status", "Station Status", 650, 500)
			popup.set_content("[GLOB.bridge_crew_objectives.get_status_report()]<hr>[SSdirector.station_status_report()]")
			popup.open()
		if("announce")
			if(topic_requires_command_access(href_list) && !usr.GetAccess(ACCESS_REGION_COMMAND))
				to_chat(usr, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
				playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
				return
			if(usr)
				var/obj/item/card/id/id_card = usr.GetIdCard()
				crew_announcement.announcer = GetNameAndAssignmentFromId(id_card)
			else
				crew_announcement.announcer = "Unknown"
			if(announcment_cooldown)
				to_chat(usr, "Please allow at least ten minutes to pass between announcements.")
				return TRUE
			var/input = input(usr, "Please write a message to announce to the [station_name()].", "Priority Announcement") as null|message
			if(!input || get_dist(src, usr) > 1)
				return 1
			if(GLOB.in_character_filter.len)
				if(findtext(input, config.ic_filter_regex))
					to_chat(usr, "<span class='warning'>You rethink your decision and decide that Nanotrasen will fire you if you announce that.</span>")
					return 1
			var/decl/security_state/security_state = decls_repository.get_decl(GLOB.using_map.security_state)
			var/decl/security_level/default/df = security_state.current_security_level
			if(df.code == GREEN_CODE)
				crew_announcement.Announce(input, new_sound = 'sound/machines/announce_alarm.ogg')
				announcment_cooldown = 1
			else if(df.code == RED_CODE)
				crew_announcement.Announce(input, new_sound = 'sound/machines/announce_alarm_red.ogg')
				announcment_cooldown = 1
			spawn(6000)//Ten-minute cooldown
				announcment_cooldown = 0
/obj/machinery/computer/bridge/proc/wake_station()
	if(GLOB.station_wake_sequence.start(usr))
		playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)


/obj/machinery/computer/bridge/attack_hand(mob/living/carbon/human/user)
	..()
	if(stat & (BROKEN|NOPOWER))
		return
	if(!user.GetAccess(ACCESS_REGION_COMMAND))
		to_chat(user, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
		playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
		return
	show_menu(user)

/obj/machinery/computer/bridge/proc/show_menu(mob/user)
	var/menu = "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The console sputters to life, offering the following functions:</span>\n<hr>"
	if(!dispensed)
		menu += "<span class='feedback'><a href='?src=\ref[src];action=printstatus'>PRINT COMMUNICATION LOGS</a></span>\n"
	menu += "<span class='feedback'><a href='?src=\ref[src];action=checkstationintegrity'>STATION STATUS</a></span>\n"
	if(!GLOB.station_wake_sequence.started)
		menu += "<span class='feedback'><a href='?src=\ref[src];action=wake_station'>WAKE STATION</a></span>\n"
	var/datum/evacuation_controller/evacuation = SSevac.evacuation_controller
	if(!evacuation)
		menu += "<span class='graytext'>ESCAPE SHUTTLE UNAVAILABLE</span>\n"
	else if(evacuation.is_on_cooldown())
		menu += "<span class='graytext'>ESCAPE SHUTTLE [evacuation.get_status_panel_eta()] - CALL LOCKED</span>\n"
	else if(evacuation.can_cancel())
		menu += "<span class='graytext'>ESCAPE SHUTTLE [evacuation.get_status_panel_eta()]</span>\n"
		menu += "<span class='feedback'><a href='?src=\ref[src];action=cancel_shuttle'>CANCEL ESCAPE SHUTTLE</a></span>\n"
	else if(!evacuation.is_idle())
		menu += "<span class='graytext'>ESCAPE SHUTTLE [evacuation.get_status_panel_eta()]</span>\n"
	else if(round_duration_in_ticks >= 30 MINUTES)
		menu += "<span class='feedback'><a href='?src=\ref[src];action=call_shuttle'>CALL ESCAPE SHUTTLE</a></span>\n"
	else
		menu += "<span class='graytext'>ESCAPE SHUTTLE LOCKED UNTIL 30 MINUTES AFTER ROUND START</span>\n"
	menu += "<span class='feedback'><a href='?src=\ref[src];action=announce'>PRIORITY ANNOUNCEMENT</a></span></div></div>"
	to_chat(user, menu)

// Generate a random mission briefing text for the crew
/obj/machinery/computer/bridge/proc/generate_random_mission()
	var/sname = station_name()
	var/list/targets = list(
		"Sector [rand(3,12)]G",
		"Deep Field [rand(100,999)]",
		"Perimeter Array [rand(1,9)]",
		"Relay Spire [rand(21,89)]",
		"Drift Belt [rand(5,25)]"
	)
	var/where = pick(targets)

	var/list/missions = list(
		list(
			title = "Emergency Evacuation",
			body = "A faint SOS has been received from [where]. Dispatch a rescue team, locate survivors, and evacuate them safely to [sname]."),
		list(
			title = "Salvage Operation",
			body = "Telemetry flagged derelict signatures near [where]. Secure and recover valuable components or data cores. Avoid unnecessary damage."),
		list(
			title = "Survey and Cartography",
			body = "Unmapped anomalies detected around [where]. Conduct a detailed scan, chart navigational hazards, and return an updated sector map."),
		list(
			title = "Secure Anomalous Object",
			body = "Anomalous readings have spiked near [where]. Identify the source, secure the site, and transfer dangerous items to containment."),
		list(
			title = "Comms Array Repair",
			body = "Outbound traffic shows packet loss through [where]. Inspect the relay, repair damaged modules, and restore full bandwidth."),
		list(
			title = "Black Box Retrieval",
			body = "A destroyed craft’s transponder ping was triangulated to [where]. Locate the flight recorder and return it intact."),
		list(
			title = "Quarantine Sweep",
			body = "Biohazard alerts at [where]. Establish perimeter, neutralize threats, and certify the zone before lifting quarantine."),
		list(
			title = "Escort and Protection",
			body = "A civilian tug will cross [where]. Provide escort coverage and deter hostile interference until transit completes."),
		list(
			title = "Debris Clearance",
			body = "High-velocity debris threatens lanes near [where]. Clear navigational hazards and mark remaining clusters."),
		list(
			title = "Power Reinstatement",
			body = "A grid fragment in [where] is dark. Diagnose failures, restore minimal power, and stabilize the microgrid."
		)
	)

	var/choice = pick(missions)
	var/title = choice["title"]
	var/body = choice["body"]
	var/text = "<b>[uppertext(title)]</b>\n\n[body]\n\n<b>Orders:</b> Coordinate via Bridge Ops, file after-action within 30 minutes of completion."
	return text
