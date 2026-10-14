// Physical media is the only output of a dive. R&D must import it normally.
#define CYBERDECK_LINK_RANGE 3
#define CYBERDECK_MAX_LEVEL 20
#define CYBERDECK_IDLE 0
#define CYBERDECK_BOOTING 1
#define CYBERDECK_RUNNING 2

/obj/item/clothing/head/cyberdeck/headset
	name = "cyberdeck helmet"
	desc = "A neural interface helmet. Buckle into a nearby cyberdeck chair and have the console operator boot your avatar into cyberspace."
	tint = TINT_NONE

/obj/structure/bed/chair/cyberdeck
	name = "cyberdeck chair"
	desc = "A neural interface chair. A cyberdeck console within three tiles can connect to its helmet-wearing occupant."
	base_icon = "officechair_dark"
	icon_state = "officechair_dark_preview"
	var/obj/machinery/computer/cyberdeck/linked_console

/obj/structure/bed/chair/cyberdeck/post_buckle_mob()
	. = ..()
	if(linked_console && buckled_mob != linked_console.operator_body)
		linked_console.end_dive("The chair connection was broken.")

/obj/structure/bed/chair/cyberdeck/Destroy()
	if(linked_console)
		linked_console.end_dive("The cyberdeck chair was destroyed.")
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
	var/dive_id = 0
	var/monitor_timer
	var/dive_deadline
	var/status_message = "Insert a blank technology disk to begin."

/obj/machinery/computer/cyberdeck/Destroy()
	end_dive("The research console was destroyed.")
	if(disk)
		disk.dropInto(loc)
		disk = null
	return ..()

/obj/machinery/computer/cyberdeck/power_change()
	. = ..()
	if(stat & (BROKEN|NOPOWER))
		end_dive("The research console lost power or failed.")

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
	if(D.stored)
		to_chat(user, SPAN_WARNING("This disk contains research. Import or erase it at an R&D console first."))
		return
	if(user.unEquip(D, FALSE, src))
		disk = D
		status_message = "Blank disk loaded. Select an occupied chair and a research field."
		attack_hand(user)

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
	if(state != CYBERDECK_IDLE)
		data["operator"] = operator_body ? operator_body.real_name : "Unknown operator"
		data["research"] = pending_tech ? pending_tech.name : "Research archive"
		data["level"] = pending_tech ? pending_tech.level : 0
		data["size"] = instance ? instance.size : 0
		data["decrypted"] = instance ? instance.decrypted : 0
		data["required"] = instance ? instance.required_keys : 0
		data["seconds"] = state == CYBERDECK_RUNNING ? max(0, round((dive_deadline - world.time) / 10)) : 0
		return data
	var/list/chairs = list()
	var/selected_valid = FALSE
	for(var/obj/structure/bed/chair/cyberdeck/C in range(CYBERDECK_LINK_RANGE, src))
		var/mob/living/carbon/human/H = C.buckled_mob
		if(!eligible_operator(H, C))
			continue
		if(C == linked_chair)
			selected_valid = TRUE
		chairs += list(list("name" = H.real_name, "ref" = "\ref[C]", "selected" = C == linked_chair))
	data["chairs"] = chairs
	// begin_dive automatically selects a free chair only when none is selected.
	data["can_boot"] = disk && !QDELETED(disk) && disk.loc == src && !disk.stored && (linked_chair ? selected_valid : chairs.len > 0)
	data["link_hint"] = selected_valid ? "Neural link selected." : linked_chair ? "Previous link unavailable. Select a chair." : chairs.len ? "Boot will link the first available chair." : "Wear a cyberdeck helmet and buckle into a free chair within three tiles."
	var/list/archives = list()
	for(var/tech_type in subtypesof(/datum/tech))
		var/datum/tech/T = tech_type
		if(initial(T.level) <= 0)
			continue // Secret disciplines still require their special sources.
		var/known_level = network_level(tech_type)
		archives += list(list("name" = initial(T.name), "id" = initial(T.id), "known" = known_level, "level" = known_level + 1, "complete" = known_level >= CYBERDECK_MAX_LEVEL, "size" = cyberdeck_map_size(known_level + 1)))
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
		end_dive("Emergency recall requested at the console.")
	else if(state == CYBERDECK_IDLE)
		switch(href_list["action"])
			if("eject")
				if(disk)
					disk.dropInto(loc)
					disk = null
					status_message = "Disk ejected. Insert a blank technology disk to begin."
			if("chair")
				var/obj/structure/bed/chair/cyberdeck/C = locate(href_list["chair"])
				if(istype(C) && eligible_operator(C.buckled_mob, C))
					linked_chair = C
			if("boot")
				for(var/tech_type in subtypesof(/datum/tech))
					var/datum/tech/T = tech_type
					if(initial(T.level) > 0 && initial(T.id) == href_list["tech"])
						begin_dive(user, tech_type)
						break
	// browse() interfaces must refresh themselves; TOPIC_REFRESH only describes
	// the result to the caller. The seated user may now control their avatar.
	if(user.client)
		attack_hand(user)
	return TOPIC_REFRESH

/obj/machinery/computer/cyberdeck/proc/eligible_operator(mob/living/carbon/human/H, obj/structure/bed/chair/cyberdeck/C)
	return istype(H) && !QDELETED(H) && istype(C) && !QDELETED(C) && C.z == z && get_dist(C, src) <= CYBERDECK_LINK_RANGE && (!C.linked_console || C.linked_console == src) && H.buckled == C && C.buckled_mob == H && H.loc == C.loc && H.stat == CONSCIOUS && istype(H.head, /obj/item/clothing/head/cyberdeck) && H.mind && H.mind.current == H

/obj/machinery/computer/cyberdeck/proc/network_level(tech_type)
	var/datum/tech/base = tech_type
	. = initial(base.level)
	for(var/obj/machinery/computer/rdconsole/C in SSmachines.machinery)
		if(C.files)
			for(var/datum/tech/T in C.files.known_tech)
				if(T.id == initial(base.id))
					. = max(., T.level)
	for(var/obj/machinery/r_n_d/server/S in SSmachines.machinery)
		if(istype(S, /obj/machinery/r_n_d/server/centcom) || !S.files)
			continue
		for(var/datum/tech/T in S.files.known_tech)
			if(T.id == initial(base.id))
				. = max(., T.level)

/obj/machinery/computer/cyberdeck/proc/begin_dive(mob/user, tech_type)
	if(state != CYBERDECK_IDLE)
		return reject_boot(user, "A dive is already being prepared or running.")
	if((stat & (BROKEN|NOPOWER)) || !powered())
		return reject_boot(user, "The cyberdeck console needs working equipment power.")
	if(!ispath(tech_type, /datum/tech))
		return reject_boot(user, "Select a valid research archive.")
	var/datum/tech/base = tech_type
	if(initial(base.level) <= 0 || network_level(tech_type) >= CYBERDECK_MAX_LEVEL)
		return reject_boot(user, "No further archive is available in that research field.")
	if(!disk || QDELETED(disk) || disk.loc != src || disk.stored)
		return reject_boot(user, "Insert a blank technology disk first.")
	if(!linked_chair)
		for(var/obj/structure/bed/chair/cyberdeck/C in range(CYBERDECK_LINK_RANGE, src))
			if(eligible_operator(C.buckled_mob, C))
				linked_chair = C
				break
	if(!linked_chair || !eligible_operator(linked_chair.buckled_mob, linked_chair))
		return reject_boot(user, "Select a conscious, helmet-wearing technician buckled into a free cyberdeck chair within three tiles.")
	instance = acquire_cyberdeck_instance()
	if(!instance)
		return reject_boot(user, "No cyberspace archive is available. Wait for an active dive to finish and try again.")
	state = CYBERDECK_BOOTING // Reserve the chair and disk before map generation yields.
	linked_chair.linked_console = src
	operator_body = linked_chair.buckled_mob
	operator_mind = operator_body.mind
	linked_helmet = operator_body.head
	pending_tech = new tech_type
	pending_tech.level = network_level(tech_type) + 1
	var/this_dive = ++dive_id
	status_message = "Building the research archive. The disk drive and neural link are reserved."
	attack_hand(user)
	var/datum/cyberdeck_instance/building = instance
	if(!building.generate(pending_tech.level, src) || QDELETED(src) || state != CYBERDECK_BOOTING || this_dive != dive_id)
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
	dive_deadline = world.time + (10 + pending_tech.level) MINUTES
	status_message = "Dive active. Decrypt the relays and download the data core."
	operator_body.unset_machine()
	dive_body << browse(null, "window=cyberdeck")
	to_chat(dive_body, SPAN_NOTICE("You enter [pending_tech.name], level [pending_tech.level]. Decrypt [building.required_keys] relays, then download the data core. Use Recall or the entry portal to return without data."))
	playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 20, 1)
	schedule_monitor()
	return TRUE

/obj/machinery/computer/cyberdeck/proc/reject_boot(mob/user, message)
	status_message = message
	to_chat(user, SPAN_WARNING(message))
	return FALSE

/obj/machinery/computer/cyberdeck/proc/physical_link_valid()
	return !(stat & (BROKEN|NOPOWER)) && powered() && !QDELETED(disk) && disk.loc == src && !disk.stored && !QDELETED(operator_body) && operator_body.stat != DEAD && !QDELETED(linked_chair) && linked_chair.linked_console == src && linked_chair.buckled_mob == operator_body && operator_body.buckled == linked_chair && operator_body.loc == linked_chair.loc && linked_chair.z == z && get_dist(linked_chair, src) <= CYBERDECK_LINK_RANGE && !QDELETED(linked_helmet) && operator_body.head == linked_helmet

/obj/machinery/computer/cyberdeck/proc/dive_valid(mob/living/simple_animal/cyber_avatar/V)
	return state == CYBERDECK_RUNNING && V == dive_body && !QDELETED(V) && V.stat == CONSCIOUS && V.health > 0 && operator_mind && operator_mind.current == V && V.mind == operator_mind && instance && V.z == instance.z_level && world.time < dive_deadline && physical_link_valid()

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
		end_dive("Neural link lost, avatar integrity failed, or archive time expired. No data was written.")
		return
	schedule_monitor()

/obj/machinery/computer/cyberdeck/proc/complete_dive(mob/living/simple_animal/cyber_avatar/V)
	if(!dive_valid(V) || instance.decrypted < instance.required_keys)
		return FALSE
	// Transfer ownership of this independent datum, never a live station database entry.
	disk.stored = pending_tech
	disk.name = "[pending_tech.name] technology disk (level [pending_tech.level])"
	disk.desc = "Decrypted cyberspace research. Import this disk at an R&D console to unlock level [pending_tech.level] [pending_tech.name]."
	pending_tech = null
	end_dive("Download complete. Eject the technology disk and import it at R&D.")
	playsound(src, 'sound/machines/ping.ogg', 30, 1)
	return TRUE

// Every exit uses one idempotent cleanup path, including destruction during boot.
/obj/machinery/computer/cyberdeck/proc/end_dive(message)
	if(state == CYBERDECK_IDLE)
		return
	state = CYBERDECK_IDLE
	dive_id++
	if(monitor_timer)
		deltimer(monitor_timer)
		monitor_timer = null
	var/mob/living/simple_animal/cyber_avatar/V = dive_body
	dive_body = null
	if(V)
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
	if(instance)
		instance.release()
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
