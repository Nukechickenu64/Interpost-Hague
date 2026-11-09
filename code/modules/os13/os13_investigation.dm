var/global/os13_file_serial = 1000

/proc/os13_case_categories()
	var/static/list/categories = list(
		"JUNIOR STAFF" = list("Pilot", "Engineer", "Cadet", "Logistics Officer"),
		"COMMAND STAFF" = list("Captain", "Chief Engineer", "Scientific Overseer"),
		"ENGINEERING WATCH" = list("Chief Engineer", "Engineer"),
		"FLIGHT AND EVA CREW" = list("Pilot", "Chief Engineer", "Engineer", "Marshal"),
		"MEDICAL STAFF" = list("Geneticist", "Medical Officer", "Psionic-Counselor"),
		"RESEARCH PERSONNEL" = list("Scientific Overseer", "Cybertechnician", "Geneticist"),
		"INTENSECURE PERSONNEL" = list("Marshal", "Pilot"),
		"LIFE SUPPORT DETAIL" = list("Chief Engineer", "Engineer", "Medical Officer", "Logistics Officer"),
		"GENETICS SUPPORT" = list("Geneticist", "Medical Officer", "Psionic-Counselor", "Scientific Overseer"),
		"STATION WATCH" = list("Captain", "Marshal", "Chief Engineer", "Medical Officer"),
		"STORES AND SALVAGE CREW" = list("Logistics Officer", "Pilot", "Cadet", "Chief Engineer"),
		"SENIOR SPECIALISTS" = list("Chief Engineer", "Medical Officer", "Scientific Overseer", "Marshal", "Psionic-Counselor"),
		"TECHNICAL SYSTEMS STAFF" = list("Chief Engineer", "Engineer", "Scientific Overseer", "Cybertechnician")
	)
	return categories

/proc/os13_junior_suspect(datum/mind/crew)
	var/list/categories = os13_case_categories()
	return crew.assigned_role in categories["JUNIOR STAFF"]

/obj/item/os13_investigation_file
	name = "Numbered File"
	desc = "A numbered archive file. Investigate its documents to recover a lead."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "report"
	item_state = "paper"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_SMALL
	var/file_number
	var/pages_left = -1
	var/lead_text
	var/followup_file_number
	var/investigating = FALSE
	var/evidence_bound = FALSE

/obj/item/os13_investigation_file/Initialize()
	. = ..()
	file_number = ++os13_file_serial
	SetName("File #[file_number]")
	update_icon()
	var/area/archive_area = get_area(src)
	if(istype(GLOB.using_map, /datum/map/alpha) && archive_area && is_station_turf(get_turf(src)))
		GLOB.os13_approved_documents["[file_number]"] = list("name" = name, "location" = archive_area.name)

/obj/item/os13_investigation_file/update_icon()
	icon_state = pages_left == 0 ? "emptyreport" : "report"

/obj/item/os13_investigation_file/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("File [file_number]: [pages_left < 0 ? "not yet investigated" : "[pages_left] pages remaining"]."))

/obj/item/os13_investigation_file/attack_self(mob/user)
	investigate(user, src)

/obj/item/os13_investigation_file/attackby(obj/item/tool, mob/user)
	var/obj/item/weapon/flame/flame = tool
	if(!istype(flame) || !flame.lit)
		return ..()
	user.visible_message(SPAN_WARNING("[user] holds [flame] up to [src]."))
	if(do_after(user, 2 SECONDS, src) && !QDELETED(src) && !QDELETED(flame) && flame.lit && user.get_active_hand() == flame && Adjacent(user))
		new /obj/effect/decal/cleanable/ash(get_turf(src))
		GLOB.os13_approved_documents -= "[file_number]"
		user.visible_message(SPAN_WARNING("[user] burns [src] to ash."))
		qdel(src)

/obj/item/os13_investigation_file/verb/investigate_file()
	set name = "Investigate File"
	set category = "Object"
	set src in usr
	investigate(usr, src)

/obj/item/os13_investigation_file/proc/reference_case_file(obj/item/os13_investigation_file/target)
	followup_file_number = target.file_number
	// A numbered lead should require a search. Ordinary archive locations stay listed.
	GLOB.os13_approved_documents -= "[target.file_number]"

/obj/item/os13_investigation_file/proc/bind_evidence()
	if(evidence_bound)
		return
	evidence_bound = TRUE
	if(lead_text || !istype(GLOB.using_map, /datum/map/alpha))
		return
	// Fixed 3022 cases are filed when the traitor is selected.
	if(os13_fixed_traitor_mode())
		return
	for(var/datum/mind/traitor in get_antags(MODE_TRAITOR))
		if(os13_junior_suspect(traitor))
			lead_text = "The evidence implicates at least one member of JUNIOR STAFF: Pilot, Engineer, Cadet or Logistics Officer."
			break

/obj/item/os13_investigation_file/proc/can_investigate(mob/living/carbon/human/user, atom/holder)
	return GAME_STATE == RUNLEVEL_GAME && !QDELETED(user) && !user.incapacitated() && !is_blind(user) && !QDELETED(holder) && user.Adjacent(holder) && (holder == src ? loc == user && (user.get_active_hand() == src || user.get_inactive_hand() == src) : loc == holder)

/obj/item/os13_investigation_file/proc/investigate(mob/user, atom/holder)
	var/mob/living/carbon/human/reader = user
	if(GAME_STATE != RUNLEVEL_GAME)
		to_chat(user, SPAN_WARNING("Archive investigation is only available during the round."))
		return
	if(!istype(reader) || !can_investigate(reader, holder))
		to_chat(user, SPAN_WARNING("You must be able to read and remain beside the filed documents or hold the file."))
		return
	if(investigating)
		to_chat(user, SPAN_WARNING("Someone is already going through this file."))
		return
	if(pages_left == 0)
		to_chat(user, SPAN_NOTICE("<b>NO LEADS HERE.</b> This file has already been investigated."))
		return
	if(pages_left < 0)
		pages_left = rand(8, 160)
	bind_evidence()
	var/atom/original_location = loc
	if(!reader.buckled)
		to_chat(reader, SPAN_NOTICE("It's much easier to learn the documents while sitting."))
	reader.visible_message(SPAN_NOTICE("[reader] begins to investigate the files!"))
	investigating = TRUE
	while(pages_left > 0)
		var/obj/structure/seat = reader.buckled
		var/per_step = seat ? 3 SECONDS : 6 SECONDS
		if(!do_after(reader, per_step, holder) || QDELETED(src))
			if(!QDELETED(src))
				investigating = FALSE
			to_chat(reader, SPAN_WARNING("File investigation interrupted. Remaining pages are retained."))
			return
		if(!can_investigate(reader, holder) || loc != original_location || reader.buckled != seat)
			investigating = FALSE
			to_chat(reader, SPAN_WARNING("The file or reading conditions changed. Investigation interrupted."))
			return
		pages_left = max(0, pages_left - rand(4, 9))
		to_chat(reader, SPAN_NOTICE("<b>[pages_left] PAGES LEFT!</b>"))
	investigating = FALSE
	update_icon()
	var/list/findings = list()
	if(lead_text)
		findings += lead_text
		to_chat(reader, SPAN_DANGER("You cannot believe your eyes. [lead_text]"))
		lead_text = null
	if(followup_file_number)
		var/reference = "I have to check File #[followup_file_number] for a clue."
		findings += reference
		to_chat(reader, SPAN_NOTICE(reference))
		followup_file_number = null
	if(!length(findings))
		to_chat(reader, SPAN_NOTICE("<b>NO LEADS HERE.</b>"))
		return
	if(os13_fixed_traitor_mode())
		reader.mind?.store_memory("<b>[name]</b><br>[jointext(findings, "<br>")]")

/obj/structure/filingcabinet/proc/os13_prepare_archive()
	if(!istype(GLOB.using_map, /datum/map/alpha) || GAME_STATE != RUNLEVEL_GAME || istype(src, /obj/structure/filingcabinet/id_records) || os13_archive_created)
		return
	for(var/obj/item/os13_investigation_file/candidate in contents)
		os13_archive_created = TRUE
		return
	os13_archive_created = TRUE
	var/obj/item/os13_investigation_file/file = new(src)
	file.pages_left = investigation_pages
	file.lead_text = investigation_lead_text
	file.update_icon()
	investigation_lead_text = null

/obj/structure/filingcabinet/proc/os13_investigate_archive(mob/living/carbon/human/user, obj/item/os13_investigation_file/selected_file)
	if(istype(src, /obj/structure/filingcabinet/id_records))
		to_chat(user, SPAN_NOTICE("These drawers contain identification cards, not investigation files."))
		return
	if(GAME_STATE != RUNLEVEL_GAME || !user.Adjacent(src) || !CanPhysicallyInteract(user) || is_blind(user))
		to_chat(user, SPAN_WARNING("You must be able to read beside the cabinet during the round."))
		return
	os13_prepare_archive()
	var/obj/item/os13_investigation_file/file = selected_file
	if(file)
		if(QDELETED(file) || file.loc != src)
			to_chat(user, SPAN_WARNING("That file is no longer in this cabinet."))
			return
	else
		var/list/files = list()
		for(var/obj/item/os13_investigation_file/candidate in contents)
			if(candidate.pages_left != 0)
				files += candidate
		if(files.len == 1)
			file = files[1]
		else if(files.len > 1)
			file = input(user, "Select the file to investigate.", "Archive") as null|anything in files
			if(!file)
				return
	if(!file)
		to_chat(user, SPAN_NOTICE("<b>NO LEADS HERE.</b> No unread investigation file is present."))
		return
	if(QDELETED(src) || QDELETED(user) || QDELETED(file) || file.loc != src || !user.Adjacent(src) || !CanPhysicallyInteract(user))
		to_chat(user, SPAN_WARNING("The cabinet, file or reading conditions changed."))
		return
	file.investigate(user, src)
	if(!QDELETED(src) && !QDELETED(file) && file.loc == src)
		investigation_pages = file.pages_left
