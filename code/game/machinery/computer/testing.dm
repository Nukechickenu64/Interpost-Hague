// Uses global ruins_gen_job declared in code/_helpers/ruins_generation_job.dm

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
	// Next world.time (in deciseconds) when a beacon scan may be initiated again
	var/next_beacon_scan_time = 0

/obj/machinery/computer/bridge/Topic(href, href_list, hsrc)
	..()
	if(get_dist(src, usr) > 1)
		return
	switch(href_list["action"])
		if("printstatus")
			if(!dispensed)
				if(get_dist(src, usr) > 1)
					return
				src.audible_message("The computer makes a few noises as it dispenses a piece of paper.")
				playsound(src, 'sound/machines/dotprinter.ogg', 10, 1)
				var/obj/item/weapon/paper/R = new(src.loc)
				var/log_text = "<b>LOG 22-10-2167</b>\n\nREPORT\n\nTHE MUSSR HAS FALLEN DOT\n\nRETURN TO DAILY ACTIVITY DOT\n\n<b>LOG 12-12-2188</b>\n\nCRYOGENIC STORAGE ACCESS DENIED DOT\n\nACTIVATING CONSERVATION MODE DOT\n\n<b>LOG 18-07-2258</b>\n\nISHIM REPUBLIC IN FULL ALERT STATE DOT\n\nREQUESTING HELP DOT\n\n<b>LOG 19-10-2263</b>\n\nTHE DOT STATION DOT IS DOT UNDER DOT TETRACORP DOT COMMAND DOT\n\nACTIVATE DOT CRYOGENIC DOT AWAKENING DOT"
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
				R.stamped += /obj/item/weapon/stamp
				R.overlays += stampoverlay
				R.stamps += "<HR><i>This paper has been stamped as 'Top Secret'.</i>"
				dispensed = 1
			else
				to_chat(usr, "<span class='warning'>The printer chirps and jams; no paper detected.</span>")
		if("checkstationintegrity")
			playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
			to_chat(usr, "<span class='warning'></b> &@&# ERR### ARRAY OFFLINE, PL333E CONTACT LOCAL ENGINEERING DEPARTMENT HEAD #$$@%) </span></b>")
		if("announce")
			if(usr)
				var/obj/item/weapon/card/id/id_card = usr.GetIdCard()
				crew_announcement.announcer = GetNameAndAssignmentFromId(id_card)
			else
				crew_announcement.announcer = "Unknown"
			if(announcment_cooldown)
				to_chat(usr, "Please allow at least one minute to pass between announcements.")
				return TRUE
			var/input = input(usr, "Please write a message to announce to the [station_name()].", "Priority Announcement") as null|message
			if(!input || get_dist(src, usr) > 1)
				return 1
			if(GLOB.in_character_filter.len)
				if(findtext(input, config.ic_filter_regex))
					to_chat(usr, "<span class='warning'>You rethink your decision and decide that Tetracorp will fire you if you announce that.</span>")
					return 1
			var/decl/security_state/security_state = decls_repository.get_decl(GLOB.using_map.security_state)
			var/decl/security_level/default/df = security_state.current_security_level
			if(df.code == GREEN_CODE)
				crew_announcement.Announce(input, new_sound = 'sound/machines/announce_alarm.ogg')
				announcment_cooldown = 1
			else if(df.code == RED_CODE)
				crew_announcement.Announce(input, new_sound = 'sound/machines/announce_alarm_red.ogg')
				announcment_cooldown = 1
			spawn(6000)//One hour cooldown
				announcment_cooldown = 0
		if("scan_for_beacons")
			if(!usr.GetAccess(ACCESS_REGION_COMMAND))
				to_chat(usr, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
				playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
				return
			// If an async generation job is active, show status and do not start a new one
			if(!ruins_gen_job)
				var/path = text2path("/datum/ruins_generation_job")
				if(path)
					ruins_gen_job = new path
			if(ruins_gen_job && call(ruins_gen_job, "is_active")())
				var/pct = call(ruins_gen_job, "get_percent")()
				to_chat(usr, "<span class='notice'>Deep-space telemetry sweep in progress — [pct]% complete. Stand by.</span>")
				return
			// Enforce a 10-minute cooldown between scans
			var/rem = max(0, next_beacon_scan_time - world.time)
			if(rem > 0)
				var/seconds = round(rem/10)
				var/sec = seconds % 60
				var/min = (seconds - sec) / 60
				to_chat(usr, "<span class='warning'>Deep-space telemetry sweep cooldown: [min]m [sec]s remaining.</span>")
				return
			// Safety guard: don't allow generation if the Mining shuttle is at Station or in the Ruins area
			if(SSshuttle && SSshuttle.shuttles && ("Mining" in SSshuttle.shuttles))
				var/datum/shuttle/S = SSshuttle.shuttles["Mining"]
				if(istype(S))
					var/obj/effect/shuttle_landmark/CL = S.current_location
					if(istype(CL))
						var/blocked_reason = null
						if(CL.landmark_tag == "nav_mining_start")
							blocked_reason = "Mining shuttle is docked at Station. Relocate to open space to initiate sweep"
						else
							var/area/A = get_area(CL)
							if(istype(A, /area/space/ruins))
								blocked_reason = "Mining shuttle is amid debris field. Relocate to a clear sector to initiate sweep"
						if(blocked_reason)
							to_chat(usr, "<span class='warning'>Unable to sweep: [blocked_reason].</span>")
							return

			// Compute minutes since world boot (fallback if a dedicated round_start_time isn't tracked)
			playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)
			// Prompt for Ruins Profile selection
			var/list/profile_options = get_ruins_profile_types()
			var/selected_profile_label = input(usr, "Select sweep parameters:", "Sweep Profile") as null|anything in profile_options
			if(!selected_profile_label || get_dist(src, usr) > 1)
				return
			var/profile_type = profile_options[selected_profile_label]
			// Start async job instead of generating all at once
			if(!ruins_gen_job)
				var/path = text2path("/datum/ruins_generation_job")
				if(path)
					ruins_gen_job = new path
			if(!(ruins_gen_job && call(ruins_gen_job, "start")(profile_type)))
				to_chat(usr, "<span class='warning'>A deep-space sweep is already underway.</span>")
				return
			// Apply 10-minute cooldown (600 seconds => 6000 deciseconds)
			next_beacon_scan_time = world.time + 6000
			var/t = 0
			if(ruins_gen_job)
				var/list/V = ruins_gen_job:vars
				if(V && ("total" in V))
					t = V["total"]
			to_chat(usr, "<span class='notice'>Initiating deep-space telemetry sweep across [t] sector(s). Profile: [selected_profile_label]. Progress will be reported here.</span>")


/obj/machinery/computer/bridge/attack_hand(mob/living/carbon/human/user)
	..()
	if(stat & (BROKEN|NOPOWER))
		return
	if(!user.GetAccess(ACCESS_REGION_COMMAND))
		to_chat(user, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
		playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1, -2)
		return
	var/scan_label = "SWEEP DEEP SPACE"
	if(!ruins_gen_job)
		var/path = text2path("/datum/ruins_generation_job")
		if(path)
			ruins_gen_job = new path
	if(ruins_gen_job && call(ruins_gen_job, "is_active")())
		var/pct = call(ruins_gen_job, "get_percent")()
		scan_label = "[pct]% - SWEEPING DEEP SPACE"
	else
		var/rem = max(0, next_beacon_scan_time - world.time)
		if(rem > 0)
			var/seconds = round(rem/10)
			var/sec = seconds % 60
			var/min = (seconds - sec) / 60
			scan_label = "COOLDOWN [min]m [sec]s"
	to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The console sputters to life, offering the following functions:</span>\n<hr><span class='feedback'><a href='?src=\ref[src];action=printstatus;align='right'>PRINT COMMUNICATION LOGS</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=checkstationintegrity;align='right'>STATION STATUS</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=announce;align='right'>PRIORITY ANNOUNCEMENT</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=scan_for_beacons;align='right'>[scan_label]</a></span></div></div>")

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