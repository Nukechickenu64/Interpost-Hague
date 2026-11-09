// Physical media is the only output of a dive. R&D must import it normally.
#define CYBERDECK_MAX_LEVEL 20
#define CYBERDECK_IDLE 0
#define CYBERDECK_BOOTING 1
#define CYBERDECK_RUNNING 2

/obj/item/clothing/head/cyberdeck/headset
	name = "cyberdeck helmet"
	desc = "A neural interface helmet. Buckle into a cyberdeck chair in the console's area and have the console operator boot your avatar into cyberspace."
	tint = TINT_NONE

/obj/structure/bed/chair/cyberdeck
	name = "cyberdeck chair"
	desc = "A neural interface chair. A cyberdeck console in the same area and on the same level can connect to its helmet-wearing occupant."
	icon = 'icons/obj/objects.dmi'
	base_icon = "cyberdeck"
	icon_state = "cyberdeck"
	var/obj/machinery/computer/cyberdeck/linked_console

/obj/structure/bed/chair/cyberdeck/update_icon()
	// The OS13 sprite is complete and has no separate foreground overlay.
	overlays.Cut()

/obj/structure/bed/chair/cyberdeck/post_buckle_mob()
	. = ..()
	if(linked_console && buckled_mob != linked_console.operator_body)
		linked_console.forced_eject("The chair connection was broken.")

/obj/structure/bed/chair/cyberdeck/Destroy()
	if(linked_console)
		linked_console.forced_eject("The cyberdeck chair was destroyed.")
	return ..()

/obj/machinery/computer/cyberdeck
	name = "cyberdeck research console"
	desc = "Boots a seated, helmet-wearing technician into a generated research archive. Insert a blank technology disk, select a research field, then decrypt its relays and download the archive."
	icon_keyboard = "rd_key"
	icon_screen = "rdcomp"
	circuit = /obj/item/circuitboard/cyberdeck
	var/state = CYBERDECK_IDLE
	var/obj/item/disk/tech_disk/disk
	var/obj/structure/bed/chair/cyberdeck/linked_chair
	var/obj/item/clothing/head/cyberdeck/linked_helmet
	var/mob/living/carbon/human/operator_body
	var/datum/mind/operator_mind
	var/mob/living/simple_animal/cyber_avatar/dive_body
	var/datum/cyberdeck_instance/instance
	var/datum/tech/pending_tech
	var/datum/tech/original_disk_research
	var/obj/item/disk/tech_disk/session_disk
	var/dive_id = 0
	var/monitor_timer
	var/dive_deadline
	var/protection_active_at = 0
	var/status_message = "Insert a blank technology disk to begin."

/obj/machinery/computer/cyberdeck/Initialize(mapload)
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		desc = "Connects a seated, helmet-wearing technician to a research data field. Insert a technology disk and select a research field. Collect all data to record the technology and return to your body."

/obj/machinery/computer/cyberdeck/Destroy()
	forced_eject("The research console was destroyed.")
	if(disk)
		disk.dropInto(loc)
		disk = null
	return ..()

/obj/machinery/computer/cyberdeck/power_change()
	. = ..()
	if(stat & (BROKEN|NOPOWER))
		forced_eject("The research console lost power or failed.")

/obj/machinery/computer/cyberdeck/attackby(obj/item/I, mob/user)
	if(!istype(I, /obj/item/disk))
		return ..()
	if(!istype(I, /obj/item/disk/tech_disk))
		to_chat(user, SPAN_WARNING("Insert a technology disk, not a component design disk."))
		return
	if(disk || state != CYBERDECK_IDLE)
		to_chat(user, SPAN_WARNING("The disk drive is occupied."))
		return
	var/obj/item/disk/tech_disk/D = I
	if(D.stored && !istype(GLOB.using_map, /datum/map/alpha))
		to_chat(user, SPAN_WARNING("This disk contains research. Import or erase it at an R&D console first."))
		return
	if(user.unEquip(D, FALSE, src))
		disk = D
		status_message = D.stored ? "Warning: the installed diskette already contains data. A successful download may overwrite it; boot requires confirmation." : "Blank disk loaded. Select an occupied chair and a research field."
		if(D.stored)
			to_chat(user, SPAN_WARNING(status_message))
		attack_hand(user)
	else
		to_chat(user, SPAN_WARNING("You cannot insert \the [D] while it cannot be removed from your inventory."))

/obj/machinery/computer/cyberdeck/attack_hand(mob/user)
	if(..())
		return
	user.set_machine(src)
	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/cyberdeck_ui)
	assets.send(user)
	device_ui_browse(user, cyberdeck_ui_html(screen_data(), "byond://?src=\ref[src]"), "window=cyberdeck;size=600x620", src)
	onclose(user, "cyberdeck")

// A read-only snapshot: displaying a link must never reserve a chair or disk.
/obj/machinery/computer/cyberdeck/proc/screen_data()
	var/list/data = list("phase" = state, "message" = status_message, "disk_name" = disk ? disk.name : "No disk inserted", "media" = disk ? (disk.stored ? "recorded" : "blank") : "missing")
	data["allow_overwrite"] = istype(GLOB.using_map, /datum/map/alpha)
	data["collection_mode"] = istype(GLOB.using_map, /datum/map/alpha)
	if(data["collection_mode"])
		data["scan_status"] = network_level(/datum/tech/os13/scan_mk2) > 0 ? "Mk.II installed (10x recharge)" : network_level(/datum/tech/os13/scan_mk1) > 0 ? "Mk.I installed" : "unavailable (install Scan research)"
		if(network_level(/datum/tech/os13/icepick_mk2) > 0)
			data["icepick_status"] = "MK2 installed (10x recharge)"
		else if(istype(GLOB.using_map, /datum/map/os13classic))
			data["icepick_status"] = network_level(/datum/tech/os13/icepick_mk1) > 0 ? "Mk.I installed" : "unavailable (install ICE-Pick research)"
		else
			data["icepick_status"] = "base ability available (MK2 not installed)"
	data["dive_id"] = dive_id
	data["disk_ref"] = disk ? "\ref[disk]" : null
	data["recording_ref"] = disk && disk.stored ? "\ref[disk.stored]" : "blank"
	if(disk && disk.stored)
		data["stored_research"] = disk.stored.name
		data["stored_level"] = disk.stored.display_level()
		data["stored_level_label"] = istype(disk.stored, /datum/tech/os13) ? "tier" : "level"
		var/list/recordings = list()
		for(var/datum/tech/recording in disk.research_recordings())
			recordings += "[recording.name] ([istype(recording, /datum/tech/os13) ? "tier" : "level"] [recording.display_level()])"
		data["recordings"] = recordings
	if(state != CYBERDECK_IDLE)
		data["operator"] = operator_body ? operator_body.real_name : "Unknown operator"
		data["research"] = pending_tech ? pending_tech.name : "Research archive"
		data["level"] = pending_tech ? pending_tech.display_level() : 0
		data["size"] = instance ? instance.size : 0
		data["decrypted"] = instance ? instance.decrypted : 0
		data["required"] = instance ? instance.required_keys : 0
		data["destroyed_data"] = instance ? instance.destroyed_data : 0
		data["advanced_port"] = advanced_port_active()
		data["protection_seconds"] = state == CYBERDECK_RUNNING ? max(0, ceil((protection_active_at - world.time) / 10)) : 0
		data["collection_mode"] = instance && instance.collection_mode
		data["seconds"] = state == CYBERDECK_RUNNING ? max(0, round((dive_deadline - world.time) / 10)) : 0
		return data
	var/list/chairs = list()
	var/selected_valid = FALSE
	for(var/obj/structure/bed/chair/cyberdeck/C in get_area(src))
		var/mob/living/carbon/human/H = C.buckled_mob
		if(!eligible_operator(H, C))
			continue
		if(C == linked_chair)
			selected_valid = TRUE
		chairs += list(list("name" = H.real_name, "ref" = "\ref[C]", "selected" = C == linked_chair))
	data["chairs"] = chairs
	// begin_dive automatically selects a free chair only when none is selected.
	data["can_boot"] = disk && !QDELETED(disk) && disk.loc == src && (!disk.stored || data["allow_overwrite"]) && (linked_chair ? selected_valid : chairs.len > 0)
	data["link_hint"] = selected_valid ? "Neural link selected." : linked_chair ? "Previous link unavailable. Select a chair." : chairs.len ? "Boot will link the first available chair in this area." : "Wear a cyberdeck helmet and buckle into a free chair in this area on the same level."
	if(istype(GLOB.using_map, /datum/map/alpha))
		data["link_hint"] += " A working Schriebmann Port must be implanted in the technician."
	var/list/archives = list()
	for(var/tech_type in research_technology_types())
		var/datum/tech/T = tech_type
		if(initial(T.level) <= 0)
			continue // Secret disciplines still require their special sources.
		var/known_level = network_level(tech_type)
		if(!archive_available(tech_type))
			continue
		var/selected_level = archive_level(tech_type)
		archives += list(list("name" = initial(T.name), "id" = initial(T.id), "known" = known_level, "level" = selected_level, "complete" = archive_complete(tech_type), "size" = cyberdeck_map_size(selected_level)))
	data["archives"] = archives
	return data


/obj/machinery/computer/cyberdeck/OnTopic(mob/user, list/href_list)
	if(href_list["close"])
		if(user && user.machine == src)
			user.unset_machine()
		return TOPIC_NOACTION
	if(!user || (stat & (BROKEN|NOPOWER)))
		return TOPIC_NOACTION
	if(href_list["action"] == "abort")
		if(state == CYBERDECK_IDLE || !href_list["dive_id"] || text2num(href_list["dive_id"]) != dive_id)
			to_chat(user, SPAN_WARNING("That dive has ended. Review the current session before requesting recall."))
		else
			end_dive("Emergency recall requested at the console.")
	else if(state == CYBERDECK_IDLE)
		switch(href_list["action"])
			if("eject")
				if(!disk || QDELETED(disk) || disk.loc != src || href_list["disk"] != "\ref[disk]" || !href_list["dive_id"] || text2num(href_list["dive_id"]) != dive_id)
					to_chat(user, SPAN_WARNING("The disk or session changed. Review the current media before ejecting it."))
				else
					disk.dropInto(loc)
					disk = null
					status_message = "Disk ejected. Insert a blank technology disk to begin."
			if("chair")
				var/obj/structure/bed/chair/cyberdeck/C = locate(href_list["chair"])
				if(istype(C) && eligible_operator(C.buckled_mob, C))
					linked_chair = C
			if("boot")
				if(!disk || QDELETED(disk) || disk.loc != src || href_list["disk"] != "\ref[disk]" || href_list["recording"] != (disk.stored ? "\ref[disk.stored]" : "blank") || !href_list["dive_id"] || text2num(href_list["dive_id"]) != dive_id)
					reject_boot(user, "The disk, recording or session changed. Review the current archive before booting.")
				else if(!href_list["level"])
					reject_boot(user, "Refresh the archive list before booting.")
				else
					var/found_archive = FALSE
					for(var/tech_type in research_technology_types())
						var/datum/tech/T = tech_type
						if(initial(T.level) > 0 && initial(T.id) == href_list["tech"])
							found_archive = TRUE
							begin_dive(user, tech_type, text2num(href_list["level"]))
							break
					if(!found_archive)
						reject_boot(user, "That technology is outside the available research catalogue.")
	// browse() interfaces must refresh themselves; TOPIC_REFRESH only describes
	// the result to the caller. The seated user may now control their avatar.
	if(user.client)
		attack_hand(user)
	return TOPIC_REFRESH

/obj/machinery/computer/cyberdeck/proc/chair_in_link_area(obj/structure/bed/chair/cyberdeck/C)
	return istype(C) && !QDELETED(C) && get_turf(src) && C.z == z && get_area(C) == get_area(src)

/obj/machinery/computer/cyberdeck/proc/eligible_operator(mob/living/carbon/human/H, obj/structure/bed/chair/cyberdeck/C)
	if(istype(GLOB.using_map, /datum/map/alpha) && (!istype(H) || !H.has_os13_neural_port()))
		return FALSE
	return istype(H) && !QDELETED(H) && !H.os13_psi_control && chair_in_link_area(C) && (!C.linked_console || C.linked_console == src) && H.buckled == C && C.buckled_mob == H && H.loc == C.loc && H.stat == CONSCIOUS && istype(H.head, /obj/item/clothing/head/cyberdeck) && H.mind && H.mind.current == H

/obj/machinery/computer/cyberdeck/proc/network_level(tech_type)
	return research_network_level(tech_type)

/obj/machinery/computer/cyberdeck/proc/advanced_port_active()
	if(!istype(GLOB.using_map, /datum/map/alpha) || QDELETED(operator_body))
		return FALSE
	var/obj/item/organ/internal/os13_neural_port/advanced/port = operator_body.internal_organs_by_name["os13_neural_port"]
	return istype(port) && port.owner == operator_body && port.is_usable()

/obj/machinery/computer/cyberdeck/proc/archive_level(tech_type)
	if(ispath(tech_type, /datum/tech/os13))
		var/datum/tech/os13/T = tech_type
		return initial(T.archive_tier)
	return network_level(tech_type) + 1

/obj/machinery/computer/cyberdeck/proc/archive_complete(tech_type)
	return network_level(tech_type) >= (ispath(tech_type, /datum/tech/os13) ? 1 : CYBERDECK_MAX_LEVEL)

/obj/machinery/computer/cyberdeck/proc/archive_available(tech_type)
	return research_archive_available(tech_type)

/obj/machinery/computer/cyberdeck/proc/begin_dive(mob/user, tech_type, expected_level = null)
	if(state != CYBERDECK_IDLE)
		return reject_boot(user, "A dive is already being prepared or running.")
	if((stat & (BROKEN|NOPOWER)) || !powered())
		return reject_boot(user, "The cyberdeck console needs working equipment power.")
	if(!(tech_type in research_technology_types()))
		return reject_boot(user, "Select a valid research archive.")
	var/datum/tech/base = tech_type
	if(initial(base.level) <= 0 || !archive_available(tech_type) || archive_complete(tech_type))
		return reject_boot(user, "No further archive is available in that research field.")
	var/selected_level = archive_level(tech_type)
	if(!isnull(expected_level) && expected_level != selected_level)
		return reject_boot(user, "The archive level changed. Review the current research before booting.")
	if(!disk || QDELETED(disk) || disk.loc != src)
		return reject_boot(user, "Insert a blank technology disk first.")
	if(disk.stored)
		if(!istype(GLOB.using_map, /datum/map/alpha))
			return reject_boot(user, "Insert a blank technology disk first.")
		var/obj/item/disk/tech_disk/confirmed_disk = disk
		var/datum/tech/confirmed_research = disk.stored
		var/confirmed_dive_id = dive_id
		if(alert(user, "This diskette already contains research. A successful download will replace it. Cancelled or failed dives retain the old data. Continue?", "Overwrite disk research", "Continue", "Cancel") != "Continue")
			to_chat(user, SPAN_NOTICE("Overwrite request cancelled. No dive was started by this request."))
			return FALSE
		if(QDELETED(src) || QDELETED(user))
			return FALSE
		if(state != CYBERDECK_IDLE || dive_id != confirmed_dive_id || disk != confirmed_disk || QDELETED(disk) || disk.loc != src || disk.stored != confirmed_research)
			return reject_boot(user, "The disk or session changed during confirmation. Nothing was overwritten.")
		if(!user.Adjacent(src) || !CanPhysicallyInteract(user) || (stat & (BROKEN|NOPOWER)) || !powered())
			return reject_boot(user, "The console connection was lost during confirmation. Nothing was overwritten.")
		if(!archive_available(tech_type) || archive_complete(tech_type) || archive_level(tech_type) != selected_level)
			return reject_boot(user, "This archive changed during confirmation. Nothing was overwritten.")
	if(!linked_chair)
		for(var/obj/structure/bed/chair/cyberdeck/C in get_area(src))
			if(eligible_operator(C.buckled_mob, C))
				linked_chair = C
				break
	if(!linked_chair || !eligible_operator(linked_chair.buckled_mob, linked_chair))
		return reject_boot(user, "Select a conscious, helmet-wearing technician buckled into a free cyberdeck chair in this area on the same level.")
	instance = acquire_cyberdeck_instance()
	if(!instance)
		return reject_boot(user, "No cyberspace archive is available. Wait for an active dive to finish and try again.")
	state = CYBERDECK_BOOTING // Reserve the chair and disk before map generation yields.
	original_disk_research = disk.stored
	session_disk = disk
	linked_chair.linked_console = src
	operator_body = linked_chair.buckled_mob
	operator_mind = operator_body.mind
	linked_helmet = operator_body.head
	pending_tech = new tech_type
	pending_tech.level = ispath(tech_type, /datum/tech/os13) ? 1 : selected_level
	var/this_dive = ++dive_id
	status_message = "Building the research archive. The disk drive and neural link are reserved."
	attack_hand(user)
	var/datum/cyberdeck_instance/building = instance
	if(!building.generate(selected_level, src) || QDELETED(src) || state != CYBERDECK_BOOTING || this_dive != dive_id)
		if(!QDELETED(src) && this_dive == dive_id)
			end_dive("Archive generation failed; no data was written.")
		return FALSE
	if(!physical_link_valid() || operator_mind.current != operator_body)
		end_dive("The neural link broke during boot.")
		return FALSE
	try
		dive_body = new(building.entry_turf)
		dive_body.master_console = src
		dive_body.copy_body_appearance(operator_body)
		operator_mind.transfer_to(dive_body)
	catch(var/exception/error)
		log_debug("Cyberdeck avatar startup failed: [error]")
		end_dive("Avatar startup failed; your body was recalled and the disk is safe.")
		return FALSE
	if(!dive_body || operator_mind.current != dive_body || dive_body.mind != operator_mind)
		end_dive("Avatar control transfer failed; your body was recalled and the disk is safe.")
		return FALSE
	state = CYBERDECK_RUNNING
	if(istype(GLOB.using_map, /datum/map/os13classic) && operator_body.cyberdeck_needs_sleep)
		operator_body.adjustBrainLoss(10)
		to_chat(dive_body, SPAN_DANGER("Your unrested brain takes damage as the neural link starts. Sleep before diving again."))
	protection_active_at = building.collection_mode ? world.time + rand(10, 30) SECONDS : 0
	dive_deadline = world.time + (10 + selected_level) MINUTES
	status_message = building.collection_mode ? "Dive active. Collect all research data; the final collection completes the download." : "Dive active. Decrypt the relays and download the data core."
	operator_body.unset_machine()
	dive_body << browse(null, "window=cyberdeck")
	if(building.collection_mode)
		to_chat(dive_body, SPAN_NOTICE("You enter [pending_tech.name], tier [selected_level]. Collect every research data point to retrieve the technology. EJECT or the entry portal returns without completing the download."))
		to_chat(dive_body, SPAN_NOTICE("DATA LEFT: [building.required_keys]."))
		to_chat(dive_body, SPAN_NOTICE("Active protection is asleep for [round((protection_active_at - world.time) / 10)] seconds. Use this time to orient yourself."))
		to_chat(dive_body, SPAN_NOTICE("Left-click nearby Blue ICE to deactivate an interior barrier. The outer archive boundary remains sealed."))
		to_chat(dive_body, SPAN_NOTICE("Use Scan in Abilities to highlight the visible archive grid, avatars, ICE and data after installing Scan software at a Replicator console. Scan Mk.II recharges ten times faster."))
		to_chat(dive_body, SPAN_NOTICE("ICE-Pick in Abilities removes nearby archive information. Do not remove useful data or the exit. Installed ICE-Pick MK2 recharges ten times faster."))
		if(advanced_port_active())
			to_chat(dive_body, SPAN_NOTICE("Advanced Schriebmann's Port connected: movement-intent delay is reduced, and you can move through interior Blue ICE without deactivating it."))
	else
		to_chat(dive_body, SPAN_NOTICE("You enter [pending_tech.name], level [pending_tech.level]. Decrypt [building.required_keys] relays, then download the data core. Use Recall or the entry portal to return without data."))
	playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 20, 1)
	schedule_monitor()
	return TRUE

/obj/machinery/computer/cyberdeck/proc/reject_boot(mob/user, message)
	status_message = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/obj/machinery/computer/cyberdeck/proc/physical_link_valid()
	if(disk != session_disk)
		return FALSE
	if(istype(GLOB.using_map, /datum/map/alpha) && (QDELETED(operator_body) || !operator_body.has_os13_neural_port()))
		return FALSE
	return !(stat & (BROKEN|NOPOWER)) && powered() && !QDELETED(disk) && disk.loc == src && disk.stored == original_disk_research && !QDELETED(operator_body) && operator_body.stat != DEAD && chair_in_link_area(linked_chair) && linked_chair.linked_console == src && linked_chair.buckled_mob == operator_body && operator_body.buckled == linked_chair && operator_body.loc == linked_chair.loc && !QDELETED(linked_helmet) && operator_body.head == linked_helmet

/obj/machinery/computer/cyberdeck/proc/dive_valid(mob/living/simple_animal/cyber_avatar/V)
	return state == CYBERDECK_RUNNING && V == dive_body && !QDELETED(V) && V.master_console == src && V.stat == CONSCIOUS && V.health > 0 && operator_mind && operator_mind.current == V && V.mind == operator_mind && !QDELETED(instance) && instance.owner == src && instance.busy && !instance.cancelled && !instance.generating && V.z == instance.z_level && world.time < dive_deadline && physical_link_valid()

/obj/machinery/computer/cyberdeck/proc/schedule_monitor()
	monitor_timer = addtimer(CALLBACK(src, .proc/check_dive, dive_id), 1 SECOND, TIMER_STOPPABLE)

/obj/machinery/computer/cyberdeck/proc/check_dive(expected_dive)
	if(!isnull(expected_dive) && expected_dive != dive_id)
		return
	if(monitor_timer)
		deltimer(monitor_timer)
	monitor_timer = null
	if(state != CYBERDECK_RUNNING)
		return
	if(!dive_valid(dive_body) || !dive_body.client)
		forced_eject("Neural link lost, avatar integrity failed, or archive time expired. No data was written.")
		return
	instance.advance_guardians(dive_body)
	if(state == CYBERDECK_RUNNING)
		schedule_monitor()

/obj/machinery/computer/cyberdeck/proc/forced_eject(message)
	if(state == CYBERDECK_RUNNING && istype(GLOB.using_map, /datum/map/os13classic) && !QDELETED(operator_body))
		operator_body.cyberdeck_needs_sleep = TRUE
		operator_body.cyberdeck_sleep_started = 0
		message += " The forced ejection leaves you exhausted. Sleep before diving again or risk brain damage."
	end_dive(message)

/mob/living/carbon/human
	var/cyberdeck_needs_sleep = FALSE
	var/cyberdeck_sleep_started = 0

/mob/living/carbon/human/proc/recover_from_cyberdeck_ejection()
	if(!voluntary_sleeping || !sleeping || stat == DEAD || InStasis())
		cyberdeck_sleep_started = 0
		return
	if(!cyberdeck_sleep_started)
		cyberdeck_sleep_started = world.time
	else if(world.time >= cyberdeck_sleep_started + 30 SECONDS)
		cyberdeck_needs_sleep = FALSE
		cyberdeck_sleep_started = 0
		to_chat(src, SPAN_NOTICE("Your mind has recovered from the forced ejection."))

/obj/machinery/computer/cyberdeck/proc/complete_dive(mob/living/simple_animal/cyber_avatar/V)
	if(!dive_valid(V) || instance.decrypted < instance.required_keys)
		return FALSE
	if(instance.collection_mode && instance.destroyed_data > 0)
		to_chat(V, SPAN_WARNING("Download unavailable: required data was destroyed. Use EJECT and start a fresh dive. Existing disk contents are unchanged."))
		return FALSE
	if(QDELETED(pending_tech) || !(pending_tech.type in research_technology_types()) || !isnum(pending_tech.level) || pending_tech.level <= 0 || (instance.collection_mode && pending_tech.level != 1))
		log_debug("Cyberdeck [src] at [x],[y],[z] cancelled a download because the pending research was unavailable or invalid.")
		end_dive("Download cancelled: the research recording is invalid. No data was written; existing disk contents are unchanged.")
		return FALSE
	if(instance.collection_mode)
		to_chat(V, SPAN_NOTICE("ALL THE DATA HAS BEEN COLLECTED."))
	// Transfer ownership of this independent datum, never a live station database entry.
	disk.set_research(pending_tech)
	var/completion_message = instance.collection_mode ? "[pending_tech.name] technology retrieved. Eject the diskette and install it at the Replicator console." : "Download complete. Eject the technology disk and import it at R&D."
	pending_tech = null
	end_dive(completion_message)
	playsound(src, 'sound/machines/ping.ogg', 30, 1)
	return TRUE

// Every exit uses one idempotent cleanup path, including destruction during boot.
/obj/machinery/computer/cyberdeck/proc/end_dive(message)
	if(state == CYBERDECK_IDLE)
		return
	state = CYBERDECK_IDLE
	protection_active_at = 0
	dive_id++
	if(monitor_timer)
		deltimer(monitor_timer)
		monitor_timer = null
	var/mob/living/simple_animal/cyber_avatar/V = dive_body
	dive_body = null
	if(V)
		V.clear_scan()
		V.master_console = null
	if(operator_mind && (operator_mind.current == V || operator_mind.current == operator_body))
		if(!QDELETED(operator_body) && (!operator_body.mind || operator_body.mind == operator_mind))
			operator_mind.transfer_to(operator_body)
			to_chat(operator_body, SPAN_NOTICE(message))
		else if(V)
			V.ghostize()
	if(!QDELETED(V))
		qdel(V)
	if(linked_chair && linked_chair.linked_console == src)
		linked_chair.linked_console = null
	linked_chair = null
	linked_helmet = null
	operator_body = null
	operator_mind = null
	QDEL_NULL(pending_tech)
	original_disk_research = null
	session_disk = null
	if(!QDELETED(instance))
		if(instance.owner == src || !instance.owner)
			instance.release()
		else
			log_debug("Cyberdeck [src] at [x],[y],[z] skipped cleanup of an archive owned by another console.")
	instance = null
	status_message = message
	if(!QDELETED(src))
		updateUsrDialog()

/obj/item/circuitboard/cyberdeck
	name = "circuit board (cyberdeck research console)"
	build_path = /obj/machinery/computer/cyberdeck

/datum/design/circuit/cyberdeck
	name = "cyberdeck research console"
	id = "cyberdeck"
	req_tech = list(TECH_DATA = 1)
	build_path = /obj/item/circuitboard/cyberdeck
	sort_string = "HAAAG"

/datum/design/item/cyberdeck_helmet
	name = "cyberdeck helmet"
	id = "cyberdeck_helmet"
	req_tech = list(TECH_DATA = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 1000)
	build_path = /obj/item/clothing/head/cyberdeck/headset
	sort_string = "VAACA"

// The former dive reward is fabricated after importing engineering research.
/datum/design/item/waterchip
	name = "water filtration chip"
	id = "water_filtration_chip"
	req_tech = list(TECH_ENGINEERING = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500)
	build_path = /obj/item/device/waterchip
	sort_string = "VAACB"
