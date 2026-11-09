// Adapted from Near-Web/Deathweb at d264167e. See icons/os13/child/ATTRIBUTION.md.
/datum/species/human/child
	name = SPECIES_CHILD
	name_plural = "Children"
	race_key = "child"
	spawn_flags = 0
	total_health = 80
	min_age = 10
	max_age = 14
	mob_size = MOB_SMALL
	pixel_offset_y = -4
	icobase = 'icons/os13/child/body.dmi'
	deform = 'icons/os13/child/deformed.dmi'
	damage_overlays = 'icons/os13/child/damage.dmi'
	damage_mask = 'icons/os13/child/damage_mask.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_TONE_NORMAL | HAS_EYE_COLOR
	genitals = FALSE
	sexybits_location = null

/datum/species/human/child/get_bodytype(mob/living/carbon/human/H)
	return SPECIES_CHILD

/datum/species/human/child/handle_post_spawn(mob/living/carbon/human/H)
	if(H.age < min_age || H.age > max_age)
		H.age = rand(min_age, max_age)
	H.f_style = "Shaved"
	return ..()

/datum/species/human/child/get_limb_icon_state(obj/item/organ/external/limb, selected_state)
	// Preserve the native art for prosthetics, skeletons, and explicit overrides.
	if(!limb.dna || limb.force_icon || limb.robotic >= ORGAN_ROBOT || (limb.owner && (SKELETON in limb.owner.mutations)))
		return selected_state
	switch(limb.icon_name)
		if("head")
			return "[selected_state]_s"
		if("torso")
			return "chest_c_s"
		if("groin")
			return selected_state == "groin_f" ? "groin_f_s" : "groin_c_s"
	return "[limb.icon_name]_c_s"

/datum/species/human/child/get_limb_damage_icon(mob/living/carbon/human/H, obj/item/organ/external/limb)
	// Deathweb stores bruises and burns separately for each limb group.
	var/region = limb.icon_name
	switch(region)
		if("torso", "groin")
			region = "chest"
		if("l_hand")
			region = "l_arm"
		if("r_hand")
			region = "r_arm"
		if("l_foot")
			region = "l_leg"
		if("r_foot")
			region = "r_leg"
	var/brute = copytext(limb.damage_state, 1, 2)
	var/burn = copytext(limb.damage_state, 2, 3)
	var/icon/result = new(damage_overlays, "00")
	if(brute != "0")
		result.Blend(icon(damage_overlays, "[region]_[brute]0"), ICON_OVERLAY)
	if(burn != "0")
		result.Blend(icon(damage_overlays, "[region]_0[burn]"), ICON_OVERLAY)
	return result

/mob/living/carbon/human/proc/is_child()
	return istype(species, /datum/species/human/child)

/mob/living/carbon/human/child
	name = "Child"

/mob/living/carbon/human/child/New(new_loc)
	return ..(new_loc, SPECIES_CHILD)

/obj/item/clothing/under/os13_child
	name = "scullion's uniform"
	desc = "A work uniform fitted for a child."
	icon = 'icons/os13/child/uniforms.dmi'
	icon_state = "grey"
	worn_state = "child_grey"
	item_icons = list(slot_w_uniform_str = 'icons/os13/child/uniforms_worn.dmi')
	species_restricted = list(SPECIES_CHILD)
	body_parts_covered = UPPER_TORSO | ARMS

/obj/item/clothing/under/os13_child/urchin
	name = "urchin's uniform"
	icon_state = "urchin"
	worn_state = "urchin"

/obj/item/clothing/under/os13_child/noble
	name = "child's noble garments"
	desc = "Formal garments fitted for a child."
	icon_state = "child_heir"
	worn_state = "child_heir"
	body_parts_covered = UPPER_TORSO | LOWER_TORSO | LEGS | ARMS

/obj/item/clothing/suit/os13_child
	name = "children's coat"
	desc = "A coat fitted for a child."
	icon = 'icons/os13/child/suits.dmi'
	icon_state = "kidcoat"
	item_state = null
	item_icons = list(slot_wear_suit_str = 'icons/os13/child/suits_worn.dmi')
	species_restricted = list(SPECIES_CHILD)
	body_parts_covered = UPPER_TORSO | ARMS

/obj/item/clothing/suit/os13_child/scuff
	name = "scuff's coat"
	icon_state = "rugged"

/obj/item/clothing/suit/os13_child/worker
	name = "child worker's coat"
	icon_state = "rugged"

/obj/item/clothing/suit/os13_child/apron
	name = "child apron"
	desc = "An apron sized for an apprentice."
	icon_state = "yapron"

/obj/item/clothing/suit/os13_child/disciple
	name = "meister's disciple garments"
	icon_state = "disciple"

/obj/item/clothing/suit/os13_child/successor
	name = "child successor dress"
	desc = "A black formal dress sized for a child."
	icon_state = "heirdress"
	body_parts_covered = UPPER_TORSO | LOWER_TORSO | LEGS | ARMS

/obj/item/clothing/suit/os13_child/cold
	name = "child cold suit"
	icon_state = "yminer"
	body_parts_covered = UPPER_TORSO | LOWER_TORSO

/obj/item/clothing/suit/armor/vest/os13_child
	name = "squire's armor"
	desc = "Armor fitted for a child."
	icon = 'icons/os13/child/suits.dmi'
	icon_state = "squire"
	item_state = "squire"
	item_icons = list(slot_wear_suit_str = 'icons/os13/child/suits_worn.dmi')
	species_restricted = list(SPECIES_CHILD)
	body_parts_covered = UPPER_TORSO | LOWER_TORSO | ARMS | LEGS
	armor = list(melee = 35, bullet = 15, laser = 50, energy = 10, bomb = 25, bio = 0, rad = 0)

/obj/item/clothing/suit/armor/vest/os13_child/triton
	name = "child triton armor"
	icon_state = "triton"
	item_state = "triton"
	armor = list(melee = 40, bullet = 0, laser = 0, energy = 10, bomb = 10, bio = 0, rad = 0)

/obj/item/clothing/suit/armor/vest/os13_child/kraken
	name = "child kraken armor"
	icon_state = "ycensor"
	item_state = "ycensor"
	armor = list(melee = 70, bullet = 45, laser = 50, energy = 10, bomb = 25, bio = 0, rad = 0)

/obj/item/clothing/shoes/os13_child
	name = "black children's shoes"
	desc = "Shoes fitted for a child."
	icon = 'icons/os13/child/shoes.dmi'
	icon_state = "yblack"
	item_state = null
	item_icons = list(slot_shoes_str = 'icons/os13/child/shoes_worn.dmi')
	species_restricted = list(SPECIES_CHILD)

/obj/item/clothing/shoes/os13_child/work
	name = "children's work shoes"
	icon_state = "yminer"

/obj/item/clothing/shoes/os13_child/squire
	name = "squire's shoes"
	icon_state = "squire"
