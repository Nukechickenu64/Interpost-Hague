GLOBAL_DATUM_INIT(station_wake_sequence, /datum/station_wake_sequence, new)

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
	return (action in list("wake_station", "printstatus", "checkstationintegrity", "announce"))

/obj/machinery/computer/bridge/Topic(href, href_list, hsrc)
	if(..())
		return
	if(src.CanUseTopic(usr, GLOB.default_state, href_list) != STATUS_INTERACTIVE)
		return
	if(get_dist(src, usr) > 1)
		return
	switch(href_list["action"])
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
				var/log_text = "<b>LOG 22-10-2167</b>\n\nREPORT\n\nTHE MUSSR HAS FALLEN DOT\n\nRETURN TO DAILY ACTIVITY DOT\n\n<b>LOG 12-12-2188</b>\n\nCRYOGENIC STORAGE ACCESS DENIED DOT\n\nACTIVATING CONSERVATION MODE DOT\n\n<b>LOG 18-07-2258</b>\n\nISHIM REPUBLIC IN FULL ALERT STATE DOT\n\nREQUESTING HELP DOT\n\n<b>LOG 19-10-2263</b>\n\nTHE DOT STATION DOT IS DOT UNDER DOT NANOTRASEN DOT COMMAND DOT\n\nACTIVATE DOT CRYOGENIC DOT AWAKENING DOT"
				// Primary objective: exit reserve mode and restore nominal operations
				var/sname = station_name()
				var/primary_text = "<b>PRIMARY OBJECTIVE: EXIT RESERVE MODE</b>\n\n[sname] is operating under Reserve Mode protocols. Restore nominal station function in the following sequence:" \
					+ "\n<ol>" \
					+ "<li>Bring the engine online and stabilize output.</li>" \
					+ "<li>Set all air alarm thermostats to 20°C across habitable zones.</li>" \
					+ "<li>Install the portable water control chip and verify flow.</li>" \
					+ "<li>Initiate food production (hydroponics or galley autosupply).</li>" \
					+ "<li>Conduct compartment sweep: examine and certify all sections.</li>" \
					+ "</ol>" \
					+ "Report completion to Bridge Ops to lift Reserve Mode locks."
				// Secondary tasking: dynamically assigned mission
				var/mission_text = generate_random_mission()
				var/full_text = "[log_text]\n\n<hr>\n[primary_text]\n\n<hr>\n<b>FOLLOW-ON TASKING</b>\n\n[mission_text]"
				R.set_content(full_text)
				R.name = "Mission Briefing"
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
			popup.set_content(SSdirector.station_status_report())
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