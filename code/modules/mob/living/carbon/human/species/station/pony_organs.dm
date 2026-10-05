// Hooves use the distal pixels of the source leg sprites through the species rendering hooks.
/obj/item/organ/external/groin/pony
	name = "hindquarters"
	gendered_icon = FALSE
	icon_name = "blank"
	force_icon = 'icons/mob/human.dmi'

/obj/item/organ/external/arm/pony
	name = "left foreleg"
	icon_name = "pony_l_arm"
	gendered_icon = FALSE
	can_stand = TRUE

/obj/item/organ/external/arm/right/pony
	name = "right foreleg"
	icon_name = "pony_r_arm"
	gendered_icon = FALSE
	can_stand = TRUE

/obj/item/organ/external/leg/pony
	name = "left hind leg"
	icon_name = "pony_l_leg"
	gendered_icon = FALSE
	icon_position = 0

/obj/item/organ/external/leg/right/pony
	name = "right hind leg"
	icon_name = "pony_r_leg"
	gendered_icon = FALSE
	icon_position = 0

/obj/item/organ/external/hand/pony
	name = "left forehoof"
	icon_name = "blank"
	force_icon = 'icons/mob/human.dmi'
	gendered_icon = FALSE
	can_stand = TRUE
	has_finger = FALSE
	digit_check = list()

/obj/item/organ/external/hand/right/pony
	name = "right forehoof"
	icon_name = "blank"
	force_icon = 'icons/mob/human.dmi'
	gendered_icon = FALSE
	can_stand = TRUE
	has_finger = FALSE
	digit_check = list()

/obj/item/organ/external/foot/pony
	name = "left hind hoof"
	icon_name = "blank"
	force_icon = 'icons/mob/human.dmi'
	gendered_icon = FALSE
	has_finger = FALSE
	digit_check = list()

/obj/item/organ/external/foot/right/pony
	name = "right hind hoof"
	icon_name = "blank"
	force_icon = 'icons/mob/human.dmi'
	gendered_icon = FALSE
	has_finger = FALSE
	digit_check = list()

/obj/item/organ/external/proc/blend_pony_feature(var/state, var/hair = FALSE)
	var/icon/feature = new('icons/mob/human_races/pony/bodyparts.dmi', state)
	if(hair)
		if(islist(h_col) && h_col.len >= 3)
			feature.Blend(rgb(h_col[1], h_col[2], h_col[3]), ICON_MULTIPLY)
	else
		feature = apply_colouration(feature)
	mob_icon.Blend(feature, ICON_OVERLAY)
	overlays += feature

/obj/item/organ/external/chest/pony
	name = "pony body"
	icon_name = "pony_chest"
	gendered_icon = FALSE

/obj/item/organ/external/chest/pony/update_icon()
	overlays.Cut()
	..()
	if(!istype(species, /datum/species/pony) || robotic >= ORGAN_ROBOT || (owner && (SKELETON in owner.mutations)))
		return
	blend_pony_feature("m_pony_tail_pony_FRONT", TRUE)
	var/datum/species/pony/pony_species = species
	if(owner && pony_species.wing_state && owner.internal_organs_by_name["pony wings"])
		blend_pony_feature(owner.pony_can_fly() ? pony_species.open_wing_state : pony_species.wing_state)

/obj/item/organ/external/head/pony
	name = "pony head"
	icon_name = "pony_head"
	gendered_icon = FALSE
	eye_icon = null
	max_teeth = 24
	var/pony_mane_style

/obj/item/organ/external/head/pony/update_icon()
	overlays.Cut()
	..()
	if(!istype(species, /datum/species/pony) || robotic >= ORGAN_ROBOT || (owner && (SKELETON in owner.mutations)))
		return
	var/datum/species/pony/pony_species = species
	blend_pony_feature(pony_species.ear_state)
	if(owner && owner.internal_organs_by_name["pony horn"])
		blend_pony_feature("m_pony_horn_pony_FRONT")
	if(owner && !owner.eye_closed)
		var/icon/eyes = new('icons/mob/human_races/pony/face.dmi', "pony_eye_l")
		eyes.Blend(new/icon('icons/mob/human_races/pony/face.dmi', "pony_eye_r"), ICON_OVERLAY)
		var/obj/item/organ/internal/eyes/eye_organ = owner.internal_organs_by_name[BP_EYES]
		eyes.Blend(eye_organ ? rgb(eye_organ.eye_colour[1], eye_organ.eye_colour[2], eye_organ.eye_colour[3]) : "#800000", ICON_MULTIPLY)
		mob_icon.Blend(eyes, ICON_OVERLAY)
	var/icon/lids = new('icons/mob/human_races/pony/face.dmi', "pony_eyelids")
	lids = apply_colouration(lids)
	mob_icon.Blend(lids, ICON_OVERLAY)
	return mob_icon

/obj/item/organ/external/head/pony/get_hair_icon()
	var/image/result = image('icons/mob/human.dmi', "blank")
	if(robotic >= ORGAN_ROBOT || (owner && (SKELETON in owner.mutations)))
		return result
	if(owner)
		pony_mane_style = owner.h_style
		if(owner.head && (owner.head.flags_inv & BLOCKHEADHAIR))
			return result
	var/datum/sprite_accessory/hair/style = GLOB.hair_styles_list[pony_mane_style]
	if(!istype(style, /datum/sprite_accessory/hair/pony))
		return result
	var/icon/mane = new(style.icon, style.icon_state)
	if(islist(h_col) && h_col.len >= 3)
		mane.Blend(rgb(h_col[1], h_col[2], h_col[3]), style.blend)
	result.overlays += mane
	return result

/obj/item/organ/internal/brain/pony
	name = "pony brain"
	desc = "An Equestrian brain with an enlarged, psionically active pineal gland."

/obj/item/organ/internal/eyes/pony
	name = "pony eyes"

/obj/item/organ/internal/pony_core
	name = "beating core of earth"
	desc = "A psychic organ that channels an Earth pony's strength and endurance."
	organ_tag = "pony core"
	parent_organ = BP_CHEST
	icon = 'icons/mob/human_races/pony/bodyparts.dmi'
	icon_state = "earth_pony_core"

/obj/item/organ/internal/pony_horn
	name = "unicorn horn"
	desc = "An Equestrian's telekinetic focus, sensitive to electromagnetic interference."
	organ_tag = "pony horn"
	parent_organ = BP_HEAD
	surface_accessible = TRUE
	icon = 'icons/mob/human_races/pony/bodyparts.dmi'
	icon_state = "m_pony_horn_pony_FRONT"
	var/disrupted_until = 0

/obj/item/organ/internal/pony_horn/is_usable()
	return ..() && world.time >= disrupted_until

/obj/item/organ/internal/pony_horn/emp_act(var/severity)
	..()
	disrupted_until = max(disrupted_until, world.time + (severity == 1 ? 20 SECONDS : 10 SECONDS))
	if(owner)
		owner.pony_floating_items = FALSE
		owner.pony_release_grips()
		owner.adjustStaminaLoss(10)
		to_chat(owner, "<span class='warning'>Electromagnetic interference disrupts your horn!</span>")

/obj/item/organ/internal/pony_horn/removed(var/mob/living/user, var/drop_organ = TRUE, var/detach = TRUE)
	var/mob/living/carbon/human/H = owner
	if(H)
		H.pony_floating_items = FALSE
		H.pony_release_grips()
	..()
	if(H && !QDELETED(H))
		H.update_body()

/obj/item/organ/internal/pony_horn/Destroy()
	var/mob/living/carbon/human/H = owner
	if(H && !QDELETED(H))
		H.pony_floating_items = FALSE
		H.pony_release_grips()
	. = ..()
	if(H && !QDELETED(H) && H.get_organ(BP_CHEST) && !QDELETED(H.get_organ(BP_CHEST)))
		H.update_body()

/obj/item/organ/internal/pony_horn/replaced(var/mob/living/carbon/human/target, var/obj/item/organ/external/affected)
	. = ..()
	if(.)
		target.update_body()

/obj/item/organ/internal/pony_wings
	name = "pegasus wings"
	desc = "Psionically enhanced wings. They need a substantial atmosphere to generate lift."
	organ_tag = "pony wings"
	parent_organ = BP_CHEST
	surface_accessible = TRUE
	icon = 'icons/mob/human_races/pony/bodyparts.dmi'
	icon_state = "m_pony_wings_pony_FRONT"

/obj/item/organ/internal/pony_wings/thestral
	name = "thestral wings"
	icon_state = "batpony_wings_open"

/obj/item/organ/internal/pony_wings/removed(var/mob/living/user, var/drop_organ = TRUE, var/detach = TRUE)
	var/mob/living/carbon/human/H = owner
	if(H)
		H.pony_stop_flight()
	..()
	if(H && !QDELETED(H))
		H.update_body()

/obj/item/organ/internal/pony_wings/Destroy()
	var/mob/living/carbon/human/H = owner
	if(H && !QDELETED(H))
		H.pony_stop_flight()
	. = ..()
	if(H && !QDELETED(H) && H.get_organ(BP_CHEST) && !QDELETED(H.get_organ(BP_CHEST)))
		H.update_body()

/obj/item/organ/internal/pony_wings/replaced(var/mob/living/carbon/human/target, var/obj/item/organ/external/affected)
	. = ..()
	if(.)
		target.update_body()
