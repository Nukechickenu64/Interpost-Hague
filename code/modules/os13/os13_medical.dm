/proc/os13_medical_scan_results(mob/living/carbon/human/patient, target_zone)
	var/list/report = list()
	var/no_vitals = patient.isSynthetic() || patient.stat == DEAD || (patient.status_flags & FAKEDEATH)
	report += "<b>[html_encode(patient.name)]'s Diagnosis:</b> Overall status: [no_vitals ? "DEAD" : "HEALTHY"]"
	if(!patient.isSynthetic() && patient.vessel && patient.species.blood_volume)
		var/volume = patient.vessel.get_reagent_amount(/datum/reagent/blood)
		var/percentage = 100 * volume / patient.species.blood_volume
		var/blood_status = percentage >= BLOOD_VOLUME_SAFE ? "Normal" : "Low"
		report += "Blood type: [patient.dna ? html_encode(patient.dna.b_type) : "Unknown"]"
		report += "Blood Level [blood_status]: [round(percentage, 0.0001)]% [round(volume, 0.001)]cl"
	else
		report += "Blood type: N/A<br>Blood Level: N/A"
	report += "Pulse: [no_vitals ? 0 : patient.get_pulse(1)]"

	var/obj/item/organ/external/affected = patient.get_organ(target_zone)
	if(!affected || affected.is_stump())
		report += SPAN_WARNING("Selected body part is missing.")
		return jointext(report, "<br>")
	var/list/region_names = list(BP_HEAD = "Head", BP_CHEST = "Chest", BP_GROIN = "Groin", BP_L_ARM = "Left arm", BP_R_ARM = "Right arm", BP_L_HAND = "Left hand", BP_R_HAND = "Right hand", BP_L_LEG = "Left leg", BP_R_LEG = "Right leg", BP_L_FOOT = "Left foot", BP_R_FOOT = "Right foot")
	var/region_name = region_names[affected.organ_tag]
	report += "<b>Deep analysis for ([html_encode(region_name ? region_name : affected.name)])</b>"
	var/list/findings = affected.get_scan_results()
	if(affected.has_infected_wound())
		findings |= "Infected wound"
	if(!findings.len)
		report += "No abnormalities detected in this region."
	else
		for(var/i = 1 to findings.len)
			report += "[i]. [html_encode(uppertext(findings[i]))]"
	for(var/obj/item/organ/internal/organ in affected.internal_organs)
		if(istype(organ, /obj/item/organ/internal/brain))
			var/obj/item/organ/internal/brain/brain = organ
			if(brain.is_bruised())
				report += SPAN_WARNING("Significant brain damage detected!")
		else if(organ.is_damaged())
			report += SPAN_WARNING("Damage detected in [html_encode(organ.name)].")
	return jointext(report, "<br>")

/obj/item/organ/internal/os13_medvisor
	name = "Medvisor"
	desc = "An implanted medical diagnostic interface. Diagnose an adjacent patient or toggle body-search telemetry."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "neuroimplant"
	parent_organ = BP_HEAD
	organ_tag = "os13_medvisor"
	robotic = ORGAN_ROBOT
	relative_size = 10
	var/searching = FALSE
	var/list/search_images = list()
	var/client/search_client
	var/datum/browser/search_window
	var/next_search_update = 0

/obj/item/organ/internal/os13_medvisor/New(mob/living/carbon/holder)
	..()
	if(owner)
		grant_controls()

/obj/item/organ/internal/os13_medvisor/proc/grant_controls()
	owner.verbs |= /mob/living/carbon/human/proc/os13_medical_diagnosis
	owner.verbs |= /mob/living/carbon/human/proc/os13_medical_body_search
	owner.verbs |= /mob/living/carbon/human/proc/os13_remove_dressing

/obj/item/organ/internal/os13_medvisor/replaced(mob/living/carbon/human/target, obj/item/organ/external/affected)
	. = ..()
	if(.)
		grant_controls()

/obj/item/organ/internal/os13_medvisor/removed(mob/living/user, drop_organ = 1, detach = 1)
	remove_controls()
	return ..()

/obj/item/organ/internal/os13_medvisor/die()
	stop_search()
	return ..()

/obj/item/organ/internal/os13_medvisor/Destroy()
	remove_controls()
	return ..()

/obj/item/organ/internal/os13_medvisor/proc/remove_controls()
	stop_search()
	if(owner)
		owner.verbs -= /mob/living/carbon/human/proc/os13_medical_diagnosis
		owner.verbs -= /mob/living/carbon/human/proc/os13_medical_body_search
		owner.verbs -= /mob/living/carbon/human/proc/os13_remove_dressing

/obj/item/organ/internal/os13_medvisor/proc/can_operate()
	return owner && owner.internal_organs_by_name[organ_tag] == src && is_usable() && !owner.incapacitated() && !is_blind(owner)

/mob/living/carbon/human/proc/os13_medical_diagnosis()
	set name = "Medical Diagnosis"
	set category = "Medical"
	var/obj/item/organ/internal/os13_medvisor/visor = internal_organs_by_name["os13_medvisor"]
	if(!istype(visor) || !visor.can_operate())
		to_chat(src, SPAN_WARNING("Your medical interface is unavailable."))
		return
	var/list/patients = list(src)
	for(var/mob/living/carbon/human/patient in view(1, src))
		patients |= patient
	var/mob/living/carbon/human/patient = input(src, "Select a patient. Analysis uses your selected body region.", "Medical Diagnosis") as null|anything in patients
	if(!patient)
		return
	if(QDELETED(visor) || QDELETED(patient) || !visor.can_operate() || !Adjacent(patient))
		to_chat(src, SPAN_WARNING("The diagnostic link was interrupted."))
		return
	setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	visible_message(SPAN_NOTICE("[src] analyzes [patient]."))
	to_chat(src, os13_medical_scan_results(patient, zone_sel.selecting))

/mob/living/carbon/human/proc/os13_medical_body_search()
	set name = "Body Search"
	set category = "Medical"
	var/obj/item/organ/internal/os13_medvisor/visor = internal_organs_by_name["os13_medvisor"]
	if(!istype(visor) || !visor.can_operate())
		to_chat(src, SPAN_WARNING("Your medical interface is unavailable."))
		return
	if(visor.searching)
		visor.stop_search()
		to_chat(src, SPAN_NOTICE("Body search disabled."))
		return
	visor.searching = TRUE
	visor.next_search_update = 0
	START_PROCESSING(SSobj, visor)
	to_chat(src, SPAN_NOTICE("Body search enabled. Blue: living authorized crew with medical bracelets. Red: corpses, unauthorized people and people without bracelets. Remote readings respect bracelet sensor modes."))
	visor.update_search()

/obj/item/organ/internal/os13_medvisor/proc/clear_search_images()
	if(search_client)
		search_client.images -= search_images
	search_images.Cut()
	search_client = null

/obj/item/organ/internal/os13_medvisor/proc/stop_search()
	searching = FALSE
	STOP_PROCESSING(SSobj, src)
	clear_search_images()
	if(search_window)
		search_window.close()
		QDEL_NULL(search_window)

/obj/item/organ/internal/os13_medvisor/Process()
	. = ..()
	if(!searching)
		return
	if(!can_operate() || !owner.client)
		if(owner)
			to_chat(owner, SPAN_WARNING("Body search stopped: the diagnostic link is unavailable."))
		stop_search()
		return
	if(world.time >= next_search_update)
		update_search()

/mob/living/carbon/human/proc/os13_medical_authorized()
	var/obj/item/card/id/id = GetIdCard()
	if(!id)
		return FALSE
	return (access_medical in id.access || access_maint_tunnels in id.access || access_heads in id.access || access_security in id.access || access_research in id.access || access_cargo in id.access || access_engine in id.access || access_mining in id.access)

/obj/item/organ/internal/os13_medvisor/Topic(href, href_list)
	if(usr == owner && href_list["close"])
		stop_search()
		return
	return ..()

/obj/item/organ/internal/os13_medvisor/proc/update_search()
	clear_search_images()
	if(!owner.client)
		return
	search_client = owner.client
	next_search_update = world.time + 1 SECOND
	for(var/mob/living/carbon/human/patient in view(owner))
		var/living_crew = patient.stat != DEAD && !(patient.status_flags & FAKEDEATH) && patient.os13_medical_authorized() && patient.get_medical_bracelet()
		var/image/marker = image(loc = patient)
		marker.appearance = patient.appearance
		marker.color = living_crew ? "#4488ff" : "#ff4444"
		marker.alpha = 100
		marker.layer = patient.layer + 0.1
		search_images += marker
	search_client.images += search_images

	var/list/report = list("Remote bracelet telemetry<br><table><tr><th>Crew</th><th>Deck / Room</th><th>PLS</th><th>RAD</th></tr>")
	var/turf/position = get_turf(owner)
	var/list/readings = crew_repository.health_data(position?.z)
	var/entries = 0
	for(var/list/reading in readings)
		var/sensor_mode = reading["sensor_type"]
		if(sensor_mode < SUIT_SENSOR_BINARY)
			continue
		var/location = sensor_mode >= SUIT_SENSOR_TRACKING ? "Deck [reading["z"]] / [html_encode(reading["area"])]" : "Location withheld"
		var/pulse = sensor_mode >= SUIT_SENSOR_VITAL ? reading["pulse"] : "Withheld"
		var/radiation = sensor_mode >= SUIT_SENSOR_VITAL ? reading["radiation"] : null
		var/mob/living/carbon/human/patient = locate(reading["ref"])
		var/status_color = reading["stat"] == DEAD || !istype(patient) || !patient.os13_medical_authorized() ? "#ff4444" : "#4488ff"
		report += "<tr style='color:[status_color]'><td>[html_encode(reading["name"])]</td><td>[location]</td><td>[pulse]</td><td>[isnull(radiation) ? "Withheld" : (radiation > 0 ? "RAD" : "-")]</td></tr>"
		entries++
	if(!entries)
		report += "<tr><td colspan='4'>No bracelet telemetry received.</td></tr>"
	report += "</table>"
	if(!search_window)
		search_window = new(owner, "os13_body_search", "Body Search", 550, 350, src)
		search_window.set_content(jointext(report, ""))
		search_window.open()
	else
		search_window.set_content(jointext(report, ""))
		search_window.update()

/obj/item/device/os13_medikit
	name = "Medi-Kit"
	desc = "A charged medical tool with artery repair, antibiotic, painkiller and hemostatic modes. The selected body region must be uncovered."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "medkit"
	item_state = "medicalpack"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_NORMAL
	slot_flags = SLOT_BELT
	var/list/mode_charges = list("Artery sewer" = 3, "Antibiotic" = 3, "Painkillers" = 3, "Hemostatic" = 3)
	var/selected_mode = "Artery sewer"
	var/treating = FALSE

/obj/item/device/os13_medikit/update_icon()
	icon_state = "medkit0"
	for(var/mode in mode_charges)
		if(mode_charges[mode] > 0)
			icon_state = "medkit"
			break

/obj/item/device/os13_medikit/examine(mob/user)
	. = ..()
	for(var/mode in mode_charges)
		to_chat(user, SPAN_NOTICE("[mode]: [mode_charges[mode]] charges[mode == selected_mode ? " (selected)" : ""]."))

/obj/item/device/os13_medikit/attack_self(mob/user)
	if(treating)
		to_chat(user, SPAN_WARNING("Treatment is already in progress."))
		return
	if(user.incapacitated())
		to_chat(user, SPAN_WARNING("You cannot operate the Medi-Kit."))
		return
	var/next_mode = mode_charges.Find(selected_mode) + 1
	selected_mode = mode_charges[next_mode > mode_charges.len ? 1 : next_mode]
	to_chat(user, SPAN_NOTICE("Mode: [selected_mode] (Charge: [mode_charges[selected_mode]])"))

/obj/item/device/os13_medikit/do_surgery(mob/living/carbon/target, mob/living/user)
	if(user.a_intent != I_HELP)
		return ..()
	attack(target, user)
	return TRUE

/obj/item/device/os13_medikit/proc/treatment_valid(mob/living/carbon/human/patient, mob/living/user, obj/item/organ/external/affected, mode)
	if(user.a_intent != I_HELP || !user.IsAdvancedToolUser())
		to_chat(user, SPAN_WARNING("Use HELP intent; you must be able to operate medical tools."))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(patient) || (user.get_active_hand() != src && user.get_inactive_hand() != src))
		to_chat(user, SPAN_WARNING("You must hold the Medi-Kit and remain beside the patient."))
		return FALSE
	if(!affected || affected.owner != patient || affected.is_stump() || affected.robotic >= ORGAN_ROBOT)
		to_chat(user, SPAN_WARNING("The selected body region cannot be treated by the Medi-Kit."))
		return FALSE
	for(var/obj/item/clothing/clothing in patient.get_equipped_items())
		if(clothing.body_parts_covered & affected.body_part)
			to_chat(user, SPAN_WARNING("Not possible. Clothes prevent me from doing this."))
			return FALSE
	if(mode_charges[mode] <= 0)
		to_chat(user, SPAN_WARNING("[mode] has no charges remaining."))
		return FALSE
	if(mode == "Artery sewer" && !(affected.status & ORGAN_ARTERY_CUT))
		to_chat(user, SPAN_NOTICE("There is no ruptured artery in this region."))
		return FALSE
	if(mode == "Hemostatic")
		var/bleeding = FALSE
		for(var/datum/wound/wound in affected.wounds)
			if(wound.bleeding())
				bleeding = TRUE
				break
		if(!bleeding)
			to_chat(user, SPAN_NOTICE("There are no bleeding wounds in this region. Use Artery sewer for a ruptured artery."))
			return FALSE
	if(mode == "Antibiotic" || mode == "Painkillers")
		if(!patient.reagents || patient.reagents.get_free_space() < 10)
			to_chat(user, SPAN_WARNING("The patient cannot receive a full dose."))
			return FALSE
	return TRUE

/obj/item/device/os13_medikit/attack(mob/living/target, mob/living/user)
	var/mob/living/carbon/human/patient = target
	if(!istype(patient) || patient.isSynthetic())
		to_chat(user, SPAN_WARNING("The Medi-Kit can only treat organic humanoids."))
		return
	if(treating)
		to_chat(user, SPAN_WARNING("Treatment is already in progress."))
		return
	var/zone = user.zone_sel.selecting
	var/obj/item/organ/external/affected = patient.get_organ(zone)
	var/mode = selected_mode
	if(!treatment_valid(patient, user, affected, mode))
		return
	if(zone in patient.op_stage.in_progress)
		to_chat(user, SPAN_WARNING("This body region is already being operated on."))
		return
	treating = TRUE
	patient.op_stage.in_progress += zone
	user.visible_message(SPAN_NOTICE("[user] begins treating [patient]'s [affected.name] with the Medi-Kit ([mode])."))
	var/completed = do_mob(user, patient, 3 SECONDS)
	if(!QDELETED(patient))
		patient.op_stage.in_progress -= zone
	if(QDELETED(src))
		return
	treating = FALSE
	if(!completed || QDELETED(patient) || QDELETED(affected) || QDELETED(user))
		to_chat(user, SPAN_WARNING("Medi-Kit treatment interrupted. No charge was used."))
		return
	if(patient.get_organ(zone) != affected || !treatment_valid(patient, user, affected, mode))
		to_chat(user, SPAN_WARNING("The treatment conditions changed. No charge was used."))
		return
	switch(mode)
		if("Artery sewer")
			affected.status &= ~ORGAN_ARTERY_CUT
		if("Hemostatic")
			for(var/datum/wound/wound in affected.wounds)
				if(wound.bleeding())
					wound.clamped = TRUE
		if("Antibiotic", "Painkillers")
			var/reagent_type = mode == "Antibiotic" ? /datum/reagent/spaceacillin : /datum/reagent/tramadol
			if(!patient.reagents.add_reagent(reagent_type, 10))
				to_chat(user, SPAN_WARNING("The dose could not be administered. No charge was used."))
				return
			admin_inject_log(user, patient, src, "[mode] ([reagent_type])", 10)
	mode_charges[mode]--
	affected.update_damages()
	patient.updatehealth()
	update_icon()
	user.visible_message(SPAN_NOTICE("[user] completes [mode] treatment on [patient]'s [affected.name]."))
	to_chat(user, SPAN_NOTICE("Mode: [mode] (Charge: [mode_charges[mode]])"))

/datum/design/item/os13_medvisor
	name = "Medvisor"
	id = "os13_medvisor"
	req_tech = list(TECH_BIO = 2, TECH_DATA = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500)
	build_path = /obj/item/organ/internal/os13_medvisor
	sort_string = "VAACE"

/datum/design/item/os13_medikit
	name = "Medi-Kit"
	id = "os13_medikit"
	req_tech = list(TECH_BIO = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 500)
	build_path = /obj/item/device/os13_medikit
	sort_string = "VAACF"

/obj/item/weapon/surgery_tool/cautery/os13_laser
	name = "surgical laser"
	desc = "A focused surgical laser for closing incisions and suturing individual wounds."
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "laser2"
	item_state = "laser"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/datum/design/item/os13_surgical_laser
	name = "Surgical laser"
	id = "os13_surgical_laser"
	req_tech = list(TECH_BIO = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 1000)
	build_path = /obj/item/weapon/surgery_tool/cautery/os13_laser
	sort_string = "VAACG"

/mob/living/carbon/human/proc/os13_remove_dressing()
	set name = "Remove Dressing"
	set category = "Medical"
	var/obj/item/organ/internal/os13_medvisor/visor = internal_organs_by_name["os13_medvisor"]
	if(!istype(visor) || !visor.can_operate())
		to_chat(src, SPAN_WARNING("Your medical interface is unavailable."))
		return
	var/list/patients = list(src)
	for(var/mob/living/carbon/human/patient in view(1, src))
		patients |= patient
	var/mob/living/carbon/human/patient = input(src, "Select a patient. Your selected body region will be unbandaged.", "Remove Dressing") as null|anything in patients
	if(!patient)
		return
	if(QDELETED(visor) || QDELETED(patient) || !visor.can_operate() || !Adjacent(patient))
		to_chat(src, SPAN_WARNING("The patient or medical interface is no longer available."))
		return
	var/zone = zone_sel.selecting
	var/obj/item/organ/external/affected = patient.get_organ(zone)
	if(!affected || affected.is_stump())
		to_chat(src, SPAN_WARNING("The selected body part is missing."))
		return
	var/list/dressings = list()
	for(var/datum/wound/wound in affected.wounds)
		if(wound.bandaged)
			dressings += wound
	if(!dressings.len)
		to_chat(src, SPAN_NOTICE("There are no dressings on this region."))
		return
	if(patient.get_covering_equipped_item(affected.body_part))
		to_chat(src, SPAN_WARNING("Uncover the selected body region before removing its dressings."))
		return
	if(zone in patient.op_stage.in_progress)
		to_chat(src, SPAN_WARNING("This region is already being treated."))
		return
	patient.op_stage.in_progress += zone
	visible_message(SPAN_NOTICE("[src] starts unbandaging [patient]'s [affected.name]."))
	var/completed = do_mob(src, patient, 3 SECONDS)
	if(!QDELETED(patient))
		patient.op_stage.in_progress -= zone
	if(!completed || QDELETED(patient) || QDELETED(affected) || QDELETED(visor) || !visor.can_operate() || !Adjacent(patient))
		to_chat(src, SPAN_WARNING("Dressing removal interrupted."))
		return
	if(patient.get_organ(zone) != affected || patient.get_covering_equipped_item(affected.body_part))
		to_chat(src, SPAN_WARNING("The selected region changed or is no longer exposed."))
		return
	var/removed = 0
	for(var/datum/wound/wound in dressings)
		if(!QDELETED(wound) && (wound in affected.wounds) && wound.bandaged)
			wound.bandaged = FALSE
			removed++
	if(!removed)
		to_chat(src, SPAN_NOTICE("The dressings are no longer present."))
		return
	affected.update_damages()
	patient.update_bandaging()
	patient.update_bleeding()
	visible_message(SPAN_NOTICE("[src] unbandages [patient]'s [affected.name]."))

/obj/machinery/optable/os13
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "table2-idle"
	var/has_monitor = TRUE

/obj/machinery/optable/os13/Initialize()
	. = ..()
	power_change()
	update_icon()

/obj/machinery/optable/os13/update_icon()
	if(!has_monitor)
		icon_state = "table3"
	else if(inoperable())
		icon_state = "table1"
	else if(!QDELETED(victim) && victim.loc == loc && victim.lying)
		icon_state = victim.pulse() ? "table2-active" : "table2-active-dead"
	else
		icon_state = "table2-idle"

/obj/machinery/optable/os13/check_victim()
	. = ..()
	update_icon()

/obj/machinery/optable/os13/take_victim(mob/living/carbon/patient, mob/living/carbon/user)
	. = ..()
	update_icon()

/obj/machinery/optable/os13/unmonitored
	name = "surgery table"
	desc = "An operating table without an integrated patient monitor."
	icon_state = "table3"
	has_monitor = FALSE
	use_power = POWER_USE_OFF

/obj/machinery/os13_neuroinhibitor
	name = "Stationary Neuroinhibitor"
	desc = "A stationary neuroinhibitor with a switchable status indicator."
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "inhib0"
	density = TRUE
	anchored = TRUE
	obj_flags = OBJ_FLAG_ANCHORABLE
	idle_power_usage = 1
	active_power_usage = 5
	var/switched_on = FALSE

/obj/machinery/os13_neuroinhibitor/Initialize()
	. = ..()
	power_change()
	update_icon()

/obj/machinery/os13_neuroinhibitor/update_icon()
	icon_state = "inhib0"
	overlays.Cut()
	if(switched_on && operable())
		overlays += overlay_image(icon, "inhib1", plane = ABOVE_LIGHTING_PLANE, layer = ABOVE_LIGHTING_LAYER)

/obj/machinery/os13_neuroinhibitor/attack_hand(mob/user)
	if(!user || user.incapacitated() || !user.Adjacent(src))
		to_chat(user, SPAN_WARNING("You must be able to reach the neuroinhibitor's controls."))
		return
	if(!operable() || !powered())
		to_chat(user, SPAN_WARNING("The neuroinhibitor is not operational."))
		return
	if(..())
		return
	switched_on = !switched_on
	update_use_power(switched_on ? POWER_USE_ACTIVE : POWER_USE_IDLE)
	update_icon()
	add_fingerprint(user)
	visible_message(SPAN_NOTICE("[user] turns the [name] [switched_on ? "on" : "off"]."))

/obj/machinery/os13_neuroinhibitor/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("The indicator is [switched_on && operable() ? "on" : "off"]."))
	to_chat(user, SPAN_WARNING("Neural suppression is not connected; the indicator alone does not provide anesthesia."))

/obj/item/weapon/surgery_tool/scalpel/os13
	name = "surgical scalpel"
	matter = list(DEFAULT_WALL_MATERIAL = 1000)
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "scalpel"
	item_state = "scalpel"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/weapon/surgery_tool/bonegel/os13
	name = "Bone-gel"
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "bonegel"
	item_state = "c_tube"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/weapon/surgery_tool/retractor/os13
	name = "surgical retractor"
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "retractor"
	item_state = "retractor"
	item_icons = list(slot_l_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi', slot_r_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi')

/obj/item/weapon/surgery_tool/hemostat/os13
	name = "surgical forceps"
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "forceps"
	item_state = "forceps"
	item_icons = list(slot_l_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi', slot_r_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi')

/obj/item/weapon/surgery_tool/surgicaldrill/os13
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "drill"
	item_state = "drill"
	item_icons = list(slot_l_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi', slot_r_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi')

/obj/item/weapon/surgery_tool/circular_saw/os13
	name = "surgical saw"
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "saw1"
	item_state = "saw1"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/weapon/surgery_tool/bonesetter/os13
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "bonesetter"
	item_state = "bonesetter"
	item_icons = list(slot_l_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi', slot_r_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi')

/obj/item/weapon/surgery_tool/FixOVein/suture/os13
	name = "surgical needle"
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "needle"
	item_state = "needle"
	item_icons = list(slot_l_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi', slot_r_hand_str = 'icons/os13/objects/objects/weapons/surgery.dmi')

/obj/item/storage/firstaid/surgery/os13
	name = "OS13 surgery kit"
	startswith = list(
		/obj/item/weapon/surgery_tool/scalpel/os13,
		/obj/item/weapon/surgery_tool/retractor/os13,
		/obj/item/weapon/surgery_tool/hemostat/os13,
		/obj/item/weapon/surgery_tool/surgicaldrill/os13,
		/obj/item/weapon/surgery_tool/circular_saw/os13,
		/obj/item/weapon/surgery_tool/bonesetter/os13,
		/obj/item/weapon/surgery_tool/bonegel/os13,
		/obj/item/weapon/surgery_tool/FixOVein/suture/os13,
		/obj/item/weapon/surgery_tool/cautery/os13_laser
	)

/obj/item/reagent_containers/hypospray/autoinjector/os13_blood_substitute
	name = "Blood Substitute Injector"
	desc = "A sealed five-dose cartridge of nanoblood substitute. Repeated injections can be toxic."
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "nanoblood"
	item_state = "dnainjector"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	atom_flags = 0
	volume = 25
	starts_with = list(/datum/reagent/nanoblood = 25)
	var/injecting = FALSE

/obj/item/reagent_containers/hypospray/autoinjector/os13_blood_substitute/update_icon()
	icon_state = reagents?.total_volume > 0 ? "nanoblood" : "dnanoblood"

/obj/item/reagent_containers/hypospray/autoinjector/os13_blood_substitute/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("Cartridge life: [Floor(reagents.total_volume / amount_per_transfer_from_this)] uses."))

/obj/item/reagent_containers/hypospray/autoinjector/os13_blood_substitute/attack(mob/living/target, mob/user)
	var/mob/living/carbon/human/patient = target
	if(!istype(patient) || patient.isSynthetic())
		to_chat(user, SPAN_WARNING("The blood substitute injector is for organic humanoids only."))
		return
	if(injecting)
		to_chat(user, SPAN_WARNING("This injector is already in use."))
		return
	if(!reagents.total_volume)
		to_chat(user, SPAN_WARNING("The injector is spent."))
		return
	var/zone = user.zone_sel.selecting
	var/obj/item/organ/external/affected = patient.get_organ(zone)
	if(!affected || affected.is_stump())
		to_chat(user, SPAN_WARNING("The selected injection site is missing."))
		return
	if(user.incapacitated() || !user.Adjacent(patient) || (user.get_active_hand() != src && user.get_inactive_hand() != src) || !patient.can_inject(user, zone))
		to_chat(user, SPAN_WARNING("Hold the injector beside an accessible injection site."))
		return
	if(!patient.reagents || patient.reagents.get_free_space() < amount_per_transfer_from_this)
		to_chat(user, SPAN_WARNING("The patient cannot receive the full dose."))
		return
	injecting = TRUE
	user.visible_message(SPAN_NOTICE("[user] attempts to inject [patient] with [src]."))
	var/completed = do_mob(user, patient, 3 SECONDS)
	if(QDELETED(src))
		return
	injecting = FALSE
	if(!completed || QDELETED(patient) || QDELETED(user) || QDELETED(affected))
		to_chat(user, SPAN_WARNING("Injection interrupted. No dose was used."))
		return
	if(user.incapacitated() || !user.Adjacent(patient) || patient.get_organ(zone) != affected || affected.is_stump() || (user.get_active_hand() != src && user.get_inactive_hand() != src) || !patient.can_inject(user, zone))
		to_chat(user, SPAN_WARNING("The injection conditions changed. No dose was used."))
		return
	if(reagents.total_volume < amount_per_transfer_from_this || !patient.reagents || patient.reagents.get_free_space() < amount_per_transfer_from_this)
		to_chat(user, SPAN_WARNING("The full dose cannot be administered."))
		return
	// The inherited injector uses the current selected zone; keep the captured site.
	if(user.zone_sel.selecting != zone)
		to_chat(user, SPAN_WARNING("The selected injection site changed. No dose was used."))
		return
	return ..()

/datum/design/item/os13_surgical_scalpel
	name = "Surgical scalpel"
	id = "os13_surgical_scalpel"
	req_tech = list(TECH_BIO = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000)
	build_path = /obj/item/weapon/surgery_tool/scalpel/os13
	sort_string = "VAACH"

/datum/design/item/os13_bonegel
	name = "Bone-gel"
	id = "os13_bonegel"
	req_tech = list(TECH_BIO = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500, "glass" = 500)
	build_path = /obj/item/weapon/surgery_tool/bonegel/os13
	sort_string = "VAACI"

/datum/design/item/os13_blood_substitute
	name = "Blood Substitute Injector"
	id = "os13_blood_substitute"
	req_tech = list(TECH_BIO = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500, "glass" = 500)
	build_path = /obj/item/reagent_containers/hypospray/autoinjector/os13_blood_substitute
	sort_string = "VAACJ"

/datum/design/item/os13_hemostatic_bandages
	name = "Hemostatic Bandages"
	id = "os13_hemostatic_bandages"
	req_tech = list(TECH_BIO = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/stack/medical/bruise_pack/os13_hemostatic
	sort_string = "VAACK"

/datum/design/item/os13_bacteriophage_bandages
	name = "Bacteriophages Containing Bandages"
	id = "os13_bacteriophage_bandages"
	req_tech = list(TECH_BIO = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500, "glass" = 500)
	build_path = /obj/item/stack/medical/bruise_pack/os13_bacteriophage
	sort_string = "VAACL"

/obj/item/organ/internal/liver/os13_artificial
	name = "Artificial Liver"
	desc = "A cybernetic replacement for an ordinary liver."
	icon = 'icons/os13/mob/mob/flesh/cyber_organs.dmi'
	icon_state = "liver"
	item_state = "implantcase"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/organ/internal/liver/os13_artificial/New(mob/living/carbon/holder)
	..()
	robotize()

/obj/item/organ/internal/liver/os13_artificial/robotize()
	. = ..()
	icon_state = "liver"

/datum/design/item/os13_artificial_liver
	name = "Artificial Liver"
	id = "os13_artificial_liver"
	req_tech = list(TECH_BIO = 3, TECH_MATERIAL = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 1000)
	build_path = /obj/item/organ/internal/liver/os13_artificial
	sort_string = "VAACM"

/obj/item/organ/internal/eyes/os13_artificial
	name = "Artificial Eyeball"
	desc = "A cybernetic replacement for the eyes, installed through ordinary organ surgery."
	gender = NEUTER
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "eyeball"
	item_state = "implantcase"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/organ/internal/eyes/os13_artificial/New(mob/living/carbon/holder)
	..()
	robotize()

/obj/item/organ/internal/eyes/os13_artificial/robotize()
	. = ..()
	name = initial(name)
	icon = initial(icon)
	icon_state = initial(icon_state)
	dead_icon = null

/datum/design/item/os13_artificial_eyeball
	name = "Artificial Eyeball"
	id = "os13_artificial_eyeball"
	req_tech = list(TECH_BIO = 3, TECH_MATERIAL = 2, TECH_MAGNET = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 1000)
	build_path = /obj/item/organ/internal/eyes/os13_artificial
	sort_string = "VAACN"

/obj/item/device/os13_dosimeter
	name = "Dosimeter"
	desc = "A passive radiation exposure recorder. Its reading stays with the device when transferred; it does not measure the body's current radiation burden."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "dosimeter"
	item_state = "multitool"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_SMALL
	slot_flags = SLOT_BELT
	var/recorded_exposure = 0

/obj/item/device/os13_dosimeter/rad_act(severity)
	. = ..()
	recorded_exposure += max(0, severity)

/obj/item/device/os13_dosimeter/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("[round(recorded_exposure / 100, 0.01)] Gy"))

/obj/item/device/os13_dosimeter/attack_self(mob/user)
	if(user.incapacitated() || (user.get_active_hand() != src && user.get_inactive_hand() != src))
		to_chat(user, SPAN_WARNING("Hold the Dosimeter to read it."))
		return
	to_chat(user, SPAN_NOTICE("[round(recorded_exposure / 100, 0.01)] Gy"))

/datum/design/item/os13_dosimeter
	name = "Dosimeter"
	id = "os13_dosimeter"
	req_tech = list(TECH_MAGNET = 1, TECH_ENGINEERING = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500, "glass" = 500)
	build_path = /obj/item/device/os13_dosimeter
	sort_string = "VAACO"
