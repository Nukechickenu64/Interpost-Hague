// Spawn this explicitly for testing; it has no circuit board or fabrication design.
/obj/machinery/computer/cyberdeck/debug
	name = "cyberdeck debug console"
	desc = "A self-powered cyberdeck test console. Use Debug tools to prepare a seated operator, create disks and set up a research importer."
	circuit = null
	use_power = POWER_USE_OFF
	var/safe_debug_dive = FALSE
	var/atom/debug_return_location
	var/obj/debug_return_seat
	var/obj/structure/bed/chair/cyberdeck/debug_previous_chair
	var/debug_return_direction
	var/debug_body_processing = FALSE
	var/debug_body_godmode = FALSE
	var/debug_body_transforming = FALSE

/obj/machinery/computer/cyberdeck/debug/powered(chan = -1, area/check_area = null)
	return TRUE

/obj/machinery/computer/cyberdeck/debug/screen_data()
	. = ..()
	.["debug_tools"] = TRUE
	.["safe_debug_dive"] = safe_debug_dive

/obj/machinery/computer/cyberdeck/debug/OnTopic(mob/user, list/href_list)
	if(href_list["action"] == "debug_solo")
		choose_safe_debug_dive(user)
		return TOPIC_HANDLED
	if(href_list["action"] == "debug")
		debug_tools(user)
		return TOPIC_HANDLED
	return ..()

/obj/machinery/computer/cyberdeck/debug/proc/can_debug(mob/user)
	return !QDELETED(src) && istype(user, /mob/living/carbon/human) && !QDELETED(user) && user.stat == CONSCIOUS && user.Adjacent(src) && CanPhysicallyInteract(user)

/obj/machinery/computer/cyberdeck/debug/proc/debug_tools(mob/user)
	if(!can_debug(user))
		return
	var/list/actions = list("Enter safe debug cyberspace", "Prepare me for a dive", "Create blank technology disk", "Create recorded technology disk", "Create blank design disk", "Create software disk kit", "Create standard neural port", "Create advanced neural port", "Create research import console", "Reset avatar ability cooldowns", "Complete test dive", "Recall test dive")
	var/action = input(user, "Debug equipment and data. Importing a recorded disk installs real research visible to the station's cyberdecks.", name) as null|anything in actions
	if(!action || !can_debug(user))
		return
	switch(action)
		if("Enter safe debug cyberspace")
			choose_safe_debug_dive(user)
		if("Prepare me for a dive")
			prepare_operator(user)
		if("Create blank technology disk")
			create_disk(get_turf(user))
		if("Create recorded technology disk")
			var/list/technologies = list()
			for(var/tech_type in research_technology_types())
				var/datum/tech/T = tech_type
				technologies["[initial(T.name)] ([initial(T.id)])"] = tech_type
			var/choice = input(user, "Choose the research to record. This does not install it.", name) as null|anything in technologies
			if(!choice || !can_debug(user))
				return
			var/tech_type = technologies[choice]
			var/level = 1
			if(!ispath(tech_type, /datum/tech/os13))
				level = input(user, "Research level (1-20).", name, 1) as null|num
				if(isnull(level) || !can_debug(user))
					return
			create_disk(get_turf(user), tech_type, level)
		if("Create blank design disk")
			new /obj/item/disk/design_disk(get_turf(user))
		if("Create software disk kit")
			if(!istype(GLOB.using_map, /datum/map/alpha))
				to_chat(user, SPAN_WARNING("The Scan and ICE-Pick software catalogue is used on Alpha."))
				return
			for(var/tech_type in list(/datum/tech/os13/scan_mk1, /datum/tech/os13/scan_mk2, /datum/tech/os13/icepick_mk2))
				create_disk(get_turf(user), tech_type)
			to_chat(user, SPAN_NOTICE("Software disks created. Import only Mk.I first to test its recharge, then Mk.II to test the upgrade."))
		if("Create standard neural port")
			new /obj/item/organ/internal/os13_neural_port(get_turf(user))
		if("Create advanced neural port")
			new /obj/item/organ/internal/os13_neural_port/advanced(get_turf(user))
		if("Create research import console")
			var/turf/T = importer_turf()
			if(!T)
				to_chat(user, SPAN_WARNING("Clear a neighboring floor tile for the importer."))
				return
			new /obj/machinery/computer/rdconsole/cyberdeck_debug(T)
			to_chat(user, SPAN_NOTICE("Self-powered research importer created. Use its normal disk menus to import, export and erase data. Its installed research is visible to cyberdecks."))
		if("Reset avatar ability cooldowns")
			if(!QDELETED(dive_body))
				dive_body.scan_ready_at = 0
				dive_body.icepick_ready_at = 0
		if("Complete test dive")
			if(state == CYBERDECK_RUNNING && instance && dive_valid(dive_body))
				instance.destroyed_data = 0
				instance.decrypted = instance.required_keys
				complete_dive(dive_body)
		if("Recall test dive")
			end_dive("Debug recall requested. No data was written.")
	if(can_debug(user))
		attack_hand(user)

/obj/machinery/computer/cyberdeck/debug/proc/choose_safe_debug_dive(mob/user)
	if(!can_debug(user))
		return
	var/level = input(user, "Archive size/tier (1-20). Your body is protected and paused. No equipment or disk is required, and no research is saved. Use Exit Debug Cyberspace at any time.", "Safe debug cyberspace", 1) as null|num
	if(isnull(level) || !can_debug(user))
		return
	begin_safe_debug_dive(user, level)

/obj/machinery/computer/cyberdeck/debug/proc/begin_safe_debug_dive(mob/living/carbon/human/H, level = 1)
	if(!can_debug(H) || !H.mind || H.mind.current != H || H.transforming || !isnum(level))
		return FALSE
	if(state != CYBERDECK_IDLE || (stat & BROKEN))
		return reject_boot(H, "Finish the current dive and repair the debug console first.")
	if(istype(H.buckled, /obj/structure/bed/chair/cyberdeck))
		var/obj/structure/bed/chair/cyberdeck/chair = H.buckled
		if(chair.linked_console)
			return reject_boot(H, "That chair is reserved by another dive.")
	instance = acquire_cyberdeck_instance()
	if(!instance)
		return reject_boot(H, "No test archive is free. Finish another dive and try again.")
	safe_debug_dive = TRUE
	state = CYBERDECK_BOOTING
	var/this_dive = ++dive_id
	operator_body = H
	operator_mind = H.mind
	debug_return_location = H.loc
	debug_return_seat = H.buckled
	debug_return_direction = H.dir
	debug_previous_chair = linked_chair
	linked_chair = null
	debug_body_processing = H.is_processing == "SSmobs"
	debug_body_godmode = !!(H.status_flags & GODMODE)
	debug_body_transforming = H.transforming
	// Pause biology, including any Life call already queued by the mob subsystem.
	H.transforming = TRUE
	H.status_flags |= GODMODE
	if(debug_body_processing)
		STOP_PROCESSING(SSmobs, H)
	try
		if(H.buckled)
			H.buckled.unbuckle_mob()
		H.forceMove(src)
		H.unset_machine()
		H << browse(null, "window=cyberdeck")
		status_message = "Building a safe debug simulation. Your body is paused and protected."
		var/datum/cyberdeck_instance/building = instance
		if(!building.generate(clamp(round(level), 1, CYBERDECK_MAX_LEVEL), src) || QDELETED(src) || state != CYBERDECK_BOOTING || dive_id != this_dive)
			if(!QDELETED(src) && dive_id == this_dive)
				end_dive("Debug archive generation failed. You have been safely returned.")
			return FALSE
		if(!physical_link_valid() || operator_mind.current != H)
			end_dive("Debug startup was interrupted. You have been safely returned.")
			return FALSE
		dive_body = new /mob/living/simple_animal/cyber_avatar/debug(building.entry_turf)
		dive_body.master_console = src
		dive_body.copy_body_appearance(H)
		operator_mind.transfer_to(dive_body)
		if(operator_mind.current != dive_body || dive_body.mind != operator_mind)
			end_dive("Debug avatar transfer failed. You have been safely returned.")
			return FALSE
	catch(var/exception/error)
		log_debug("Safe cyberdeck debug startup failed: [error]")
		end_dive("Debug startup failed. You have been safely returned.")
		return FALSE
	state = CYBERDECK_RUNNING
	dive_deadline = INFINITY
	protection_active_at = 0
	status_message = "Safe debug simulation active. Exit Debug Cyberspace, EJECT or Recall returns you immediately. Nothing is written to disk."
	to_chat(dive_body, SPAN_NOTICE(status_message))
	schedule_monitor()
	return TRUE

/obj/machinery/computer/cyberdeck/debug/physical_link_valid()
	if(safe_debug_dive)
		return !QDELETED(operator_body) && operator_body.loc == src && operator_body.stat != DEAD
	return ..()

/obj/machinery/computer/cyberdeck/debug/complete_dive(mob/living/simple_animal/cyber_avatar/V)
	if(!safe_debug_dive)
		return ..()
	if(!dive_valid(V) || instance.decrypted < instance.required_keys)
		return FALSE
	end_dive("Debug simulation complete. No research or disk contents were changed.")
	return TRUE

/obj/machinery/computer/cyberdeck/debug/end_dive(message)
	if(!safe_debug_dive)
		return ..()
	var/mob/living/carbon/human/H = operator_body
	var/atom/return_location = debug_return_location
	var/obj/return_seat = debug_return_seat
	var/obj/structure/bed/chair/cyberdeck/previous_chair = debug_previous_chair
	// Parent cleanup owns mind transfer, avatar deletion, timers and archive release.
	. = ..("Safe debug dive ended. Your body is restored; no research or disk contents were changed.")
	if(!QDELETED(H))
		H.forceMove(!QDELETED(return_location) ? return_location : get_turf(src))
		if(!QDELETED(return_seat) && return_seat.loc == H.loc && !return_seat.buckled_mob)
			return_seat.buckle_mob(H)
		H.set_dir(debug_return_direction)
		if(!debug_body_godmode)
			H.status_flags &= ~GODMODE
		H.transforming = debug_body_transforming
		if(debug_body_processing && !H.is_processing)
			START_PROCESSING(SSmobs, H)
	linked_chair = QDELETED(previous_chair) ? null : previous_chair
	safe_debug_dive = FALSE
	debug_return_location = null
	debug_return_seat = null
	debug_previous_chair = null
	debug_body_processing = FALSE
	debug_body_godmode = FALSE
	debug_body_transforming = FALSE

// Separate avatar subtype keeps protection exclusive to the disposable simulation.
/mob/living/simple_animal/cyber_avatar/debug
	status_flags = GODMODE

/mob/living/simple_animal/cyber_avatar/debug/verb/exit_debug_cyberspace()
	set name = "Exit Debug Cyberspace"
	set category = "Abilities"
	recall()

/mob/living/simple_animal/cyber_avatar/debug/Stat()
	if(statpanel("Status"))
		stat("Mode", "Safe debug simulation / no disk writes")
		stat("Exit", "Use Exit Debug Cyberspace, EJECT or Recall at any time")
		if(!QDELETED(master_console) && master_console.instance)
			stat("Data collected", "[master_console.instance.decrypted]/[master_console.instance.required_keys]")

/mob/living/simple_animal/cyber_avatar/debug/Logout()
	. = ..()
	if(!QDELETED(master_console) && master_console.dive_body == src)
		master_console.end_dive("Debug player disconnected.")

/obj/machinery/computer/cyberdeck/debug/proc/importer_turf()
	for(var/direction in GLOB.cardinal)
		var/turf/T = get_step(src, direction)
		if(!T || T.density || istype(T, /turf/space))
			continue
		var/blocked = FALSE
		for(var/atom/movable/A in T)
			if(A.density)
				blocked = TRUE
				break
		if(!blocked)
			return T
	return null

/obj/machinery/computer/cyberdeck/debug/proc/create_disk(turf/T, tech_type = null, level = 1)
	if(!T || (tech_type && !(tech_type in research_technology_types())))
		return null
	var/disk_type = istype(GLOB.using_map, /datum/map/alpha) ? /obj/item/disk/tech_disk/os13 : /obj/item/disk/tech_disk
	var/obj/item/disk/tech_disk/D = new disk_type(T)
	if(tech_type)
		var/datum/tech/research = new tech_type
		research.level = ispath(tech_type, /datum/tech/os13) ? 1 : clamp(round(level), 1, CYBERDECK_MAX_LEVEL)
		D.set_research(research)
	return D

/obj/machinery/computer/cyberdeck/debug/proc/prepare_operator(mob/living/carbon/human/H)
	if(state != CYBERDECK_IDLE || !istype(H) || get_area(H) != get_area(src) || H.z != z)
		to_chat(H, SPAN_WARNING("Stand in this console's area and finish any active dive first."))
		return FALSE
	if(H.buckled && !istype(H.buckled, /obj/structure/bed/chair/cyberdeck))
		to_chat(H, SPAN_WARNING("Unbuckle from your current seat first."))
		return FALSE
	if(H.head && !istype(H.head, /obj/item/clothing/head/cyberdeck))
		to_chat(H, SPAN_WARNING("Remove your headgear first so the test helmet can be equipped."))
		return FALSE
	if(!H.head)
		H.equip_to_slot_or_del(new /obj/item/clothing/head/cyberdeck/headset(H), slot_head)
	if(!istype(H.head, /obj/item/clothing/head/cyberdeck))
		return FALSE
	if(istype(GLOB.using_map, /datum/map/alpha) && !H.has_os13_neural_port())
		if(H.internal_organs_by_name["os13_neural_port"] || !H.get_organ(BP_HEAD))
			to_chat(H, SPAN_WARNING("Repair the existing neural port or head before preparing this operator."))
			return FALSE
		var/obj/item/organ/internal/os13_neural_port/port = new(H)
		port.replaced(H, H.get_organ(BP_HEAD))
	if(!H.buckled)
		var/obj/structure/bed/chair/cyberdeck/chair = locate() in get_turf(H)
		if(!chair)
			chair = new(get_turf(H))
		chair.buckle_mob(H)
	var/obj/structure/bed/chair/cyberdeck/chair = H.buckled
	if(!eligible_operator(H, chair))
		to_chat(H, SPAN_WARNING("The operator could not be linked. Check the chair, mind and neural port."))
		return FALSE
	linked_chair = chair
	if(!disk)
		disk = create_disk(get_turf(src))
		disk.forceMove(src)
	to_chat(H, SPAN_NOTICE("Test chair linked and helmet equipped. A standard neural port is installed on Alpha if needed. Select an archive at the console to dive; completed research is written to the inserted disk."))
	return TRUE

// Uses real R&D disk handling; never claims a live station's fabrication devices.
/obj/machinery/computer/rdconsole/cyberdeck_debug
	name = "cyberdeck debug research importer"
	desc = "A self-powered test console for importing, backing up and erasing research disks. Imported technology is visible to the station's cyberdecks."
	circuit = null
	use_power = POWER_USE_OFF
	req_access = list()

/obj/machinery/computer/rdconsole/cyberdeck_debug/powered(chan = -1, area/check_area = null)
	return TRUE

/obj/machinery/computer/rdconsole/cyberdeck_debug/SyncRDevices()
	return
