/datum/surgery_step/os13_neural
	priority = 4
	can_infect = TRUE
	blood_level = 1
	shock_level = 40
	delicate = TRUE

/datum/surgery_step/os13_neural/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!istype(GLOB.using_map, /datum/map/alpha) || !istype(target) || target_zone != BP_HEAD || !target.has_brain())
		return FALSE
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	return head && head.encased && !head.is_stump() && head.robotic < ORGAN_ROBOT && head.get_incision(TRUE)

/datum/surgery_step/os13_neural/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	..()
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	user.visible_message(SPAN_WARNING("[user] makes a mistake while operating on [target]'s head with \the [tool]!"))
	head.take_external_damage(5, 0, DAM_SHARP, used_weapon = tool)

/datum/surgery_step/os13_neural/drill
	allowed_tools = list(/obj/item/weapon/surgery_tool/surgicaldrill = 100)
	min_duration = 50
	max_duration = 70

/datum/surgery_step/os13_neural/drill/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!..())
		return FALSE
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	if(head.cannot_break || !config.bones_can_break)
		to_chat(user, SPAN_WARNING("The skull cannot be opened with this procedure."))
		return SURGERY_FAILURE
	return !(head.status & ORGAN_BROKEN)

/datum/surgery_step/os13_neural/drill/begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	..()
	user.visible_message(SPAN_NOTICE("[user] starts drilling a hole in [target]'s skull with \the [tool]."))

/datum/surgery_step/os13_neural/drill/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(can_use(user, target, target_zone, tool) != TRUE)
		to_chat(user, SPAN_WARNING("The skull is no longer suitable for drilling."))
		return
	..()
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	var/datum/wound/cut/incision = head.get_incision(TRUE)
	incision.open_wound(max(0, head.min_broken_damage * 0.6 - incision.damage))
	head.fracture()
	head.update_damages()
	target.updatehealth()
	user.visible_message(SPAN_NOTICE("[user] drills a hole in [target]'s skull!"))

/datum/surgery_step/os13_neural/insert_port
	allowed_tools = list(/obj/item/organ/internal/os13_neural_port = 100)
	min_duration = 60
	max_duration = 80

/datum/surgery_step/os13_neural/insert_port/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!..())
		return FALSE
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	if(head.open() != SURGERY_ENCASED)
		return FALSE
	var/obj/item/organ/internal/os13_neural_port/port = tool
	if(!istype(port) || port.owner || port.parent_organ != BP_HEAD || (port.status & ORGAN_DEAD) || port.damage > port.max_damage * 0.75)
		to_chat(user, SPAN_WARNING("That neural port cannot be implanted."))
		return SURGERY_FAILURE
	if(target.internal_organs_by_name[port.organ_tag])
		to_chat(user, SPAN_WARNING("There is already a neural port in the patient's head. Remove it first."))
		return SURGERY_FAILURE
	var/space_used = port.get_storage_cost()
	for(var/obj/item/organ/internal/organ in head.internal_organs)
		space_used += organ.get_storage_cost()
	for(var/obj/item/implant_item in head.implants)
		if(istype(implant_item, /obj/item/organ/internal/os13_neural_port))
			to_chat(user, SPAN_WARNING("There is already a loose neural port in the patient's head. Remove it first."))
			return SURGERY_FAILURE
		space_used += implant_item.get_storage_cost()
	head.update_internal_organs_cost()
	if(port.w_class > head.cavity_max_w_class || space_used > base_storage_capacity(head.cavity_max_w_class) + head.internal_organs_size)
		to_chat(user, SPAN_WARNING("There is not enough room in the patient's head for that neural port."))
		return SURGERY_FAILURE
	return TRUE

/datum/surgery_step/os13_neural/insert_port/begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	..()
	user.visible_message(SPAN_NOTICE("[user] starts implanting \the [tool] into [target]'s brain."))

/datum/surgery_step/os13_neural/insert_port/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(can_use(user, target, target_zone, tool) != TRUE)
		to_chat(user, SPAN_WARNING("The neural-port implantation conditions changed."))
		return
	var/obj/item/organ/internal/os13_neural_port/port = tool
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	if(!user.unEquip(port, target = target))
		to_chat(user, SPAN_WARNING("You cannot release the held neural port."))
		return
	port.status &= ~ORGAN_CUT_AWAY
	port.replaced(target, head)
	head.update_internal_organs_cost()
	..()
	user.visible_message(SPAN_NOTICE("[user] implants [target]'s brain!"))

/datum/surgery_step/os13_neural/remove_port
	allowed_tools = list(/obj/item/weapon/surgery_tool/hemostat = 100)
	min_duration = 60
	max_duration = 80

/datum/surgery_step/os13_neural/remove_port/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!..())
		return FALSE
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	var/obj/item/organ/internal/os13_neural_port/port = target.internal_organs_by_name["os13_neural_port"]
	if(head.open() != SURGERY_ENCASED || !istype(port) || port.owner != target || !(port in head.internal_organs))
		return FALSE
	target.op_stage.current_organ = port
	return TRUE

/datum/surgery_step/os13_neural/remove_port/begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	..()
	user.visible_message(SPAN_NOTICE("[user] starts removing an implant from [target]'s brain."))

/datum/surgery_step/os13_neural/remove_port/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!can_use(user, target, target_zone, tool))
		to_chat(user, SPAN_WARNING("The neural implant is no longer accessible."))
		return
	var/obj/item/organ/internal/os13_neural_port/port = target.internal_organs_by_name["os13_neural_port"]
	port.removed(user)
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	head.update_internal_organs_cost()
	..()
	user.visible_message(SPAN_NOTICE("[user] removes an implant from [target]'s brain!"))

/datum/surgery_step/finish_bone/os13_skull
	priority = 4

/datum/surgery_step/finish_bone/os13_skull/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!istype(GLOB.using_map, /datum/map/alpha) || !istype(target) || target_zone != BP_HEAD)
		return FALSE
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	return head && head.get_incision(TRUE) && ..()

/datum/surgery_step/finish_bone/os13_skull/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/head = target.get_organ(BP_HEAD)
	// Bone repair must leave the surgical incision for the laser to close.
	head.mend_fracture()
	head.stage = 0
	user.visible_message(SPAN_NOTICE("[user] finishes mending [target]'s skull with \the [tool]."))

/datum/surgery_step/generic/cauterize/os13_laser
	priority = 5
	allowed_tools = list(/obj/item/weapon/surgery_tool/cautery/os13_laser = 100)

/datum/surgery_step/generic/cauterize/os13_laser/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!istype(GLOB.using_map, /datum/map/alpha) || !istype(target))
		return FALSE
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!affected || affected.is_stump() || affected.cavity || !affected.get_incision(TRUE))
		return FALSE
	if(target_zone == BP_HEAD && affected.encased && (affected.status & ORGAN_BROKEN))
		to_chat(user, SPAN_WARNING("Repair the [affected.encased] before suturing the incision closed."))
		return SURGERY_FAILURE
	return ..()

/datum/surgery_step/generic/cauterize/os13_laser/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	var/datum/wound/cut/incision = affected.get_incision(TRUE)
	incision.close()
	affected.update_damages()
	target.updatehealth()
	user.visible_message(SPAN_NOTICE("[user] sutures [target]'s [affected.name] with the surgical laser!"))
