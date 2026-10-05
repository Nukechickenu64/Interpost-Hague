// Adapted from tiiktaaaliik/Ponystation13, cbebc7b1488d22983678d5de5c5c6f489c72348b (AGPL-3.0).
GLOBAL_LIST_INIT(pony_names, world.file2list("config/names/pony.txt"))

/datum/species/pony
	name = "Earth Pony"
	name_plural = "Earth Ponies"
	blurb = "Equestrians are colorful, long-lived psychic quadrupeds. Earth ponies channel their talents into strength, endurance, and powerful hind-leg kicks."
	icobase = 'icons/mob/human_races/pony/bodyparts.dmi'
	deform = 'icons/mob/human_races/pony/bodyparts.dmi'
	damage_overlays = null
	damage_mask = null
	blood_mask = null
	eye_icon = null
	base_color = "#ffffff"
	limb_blend = ICON_MULTIPLY
	appearance_flags = HAS_SKIN_COLOR | HAS_HAIR_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED | SPECIES_NO_FBP_CHARGEN | SPECIES_NO_FBP_CONSTRUCTION
	species_flags = SPECIES_FLAG_NO_MINOR_CUT
	hud_type = /datum/hud_data/pony
	language = "Ponish"
	name_language = "Ponish"
	pathogen_bodytype = SPECIES_HUMAN
	min_age = 18
	max_age = 150
	default_h_style = "Soldier (Equestrian)"
	default_f_style = "Shaved"
	taste_sensitivity = TASTE_SENSITIVE
	darksight = 4
	stance_limbs = list(BP_L_ARM, BP_R_ARM, BP_L_HAND, BP_R_HAND, BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT)
	stance_damage_multiplier = 0.5
	stat_modifiers = list(STAT_ST = 2, STAT_HT = 2)
	unarmed_types = list(/datum/unarmed_attack/hoof, /datum/unarmed_attack/bite)
	inherent_verbs = list(/mob/living/carbon/human/proc/pony_telepathy, /mob/living/carbon/human/proc/pony_hind_kick)
	has_limbs = list(
		BP_CHEST = list("path" = /obj/item/organ/external/chest/pony),
		BP_GROIN = list("path" = /obj/item/organ/external/groin/pony),
		BP_HEAD = list("path" = /obj/item/organ/external/head/pony),
		BP_L_ARM = list("path" = /obj/item/organ/external/arm/pony),
		BP_R_ARM = list("path" = /obj/item/organ/external/arm/right/pony),
		BP_L_LEG = list("path" = /obj/item/organ/external/leg/pony),
		BP_R_LEG = list("path" = /obj/item/organ/external/leg/right/pony),
		BP_L_HAND = list("path" = /obj/item/organ/external/hand/pony),
		BP_R_HAND = list("path" = /obj/item/organ/external/hand/right/pony),
		BP_L_FOOT = list("path" = /obj/item/organ/external/foot/pony),
		BP_R_FOOT = list("path" = /obj/item/organ/external/foot/right/pony)
	)
	var/archetype_organ = /obj/item/organ/internal/pony_core
	var/archetype_tag = "pony core"
	var/wing_state
	var/open_wing_state
	var/ear_state = "m_pony_ears_pony_FRONT"
	var/flight_cooldown = 7 SECONDS

/datum/species/pony/New()
	has_organ = has_organ.Copy()
	has_organ[BP_BRAIN] = /obj/item/organ/internal/brain/pony
	has_organ[BP_EYES] = /obj/item/organ/internal/eyes/pony
	has_organ[archetype_tag] = archetype_organ
	..()
	equip_adjust = list(
		slot_head_str = list("NORTH" = list("x" = 0, "y" = -7), "SOUTH" = list("x" = 0, "y" = -7), "EAST" = list("x" = 6, "y" = -7), "WEST" = list("x" = -6, "y" = -7)),
		slot_glasses_str = list("NORTH" = list("x" = 0, "y" = -7), "SOUTH" = list("x" = 0, "y" = -7), "EAST" = list("x" = 6, "y" = -7), "WEST" = list("x" = -6, "y" = -7)),
		slot_wear_mask_str = list("NORTH" = list("x" = 0, "y" = -6), "SOUTH" = list("x" = 0, "y" = -6), "EAST" = list("x" = 8, "y" = -6), "WEST" = list("x" = -8, "y" = -6))
	)

/datum/species/pony/unicorn
	name = "Unicorn"
	name_plural = "Unicorns"
	blurb = "Unicorns focus their psychic talents through a horn, manipulating distant objects and floating their carried items. Their horns are vulnerable to EMP interference."
	stat_modifiers = list(STAT_IQ = 2, STAT_HT = -1)
	infection_modifier = 1.5
	archetype_organ = /obj/item/organ/internal/pony_horn
	archetype_tag = "pony horn"
	inherent_verbs = list(/mob/living/carbon/human/proc/pony_telepathy, /mob/living/carbon/human/proc/pony_float_items)

/datum/species/pony/pegasus
	name = "Pegasus"
	name_plural = "Pegasi"
	blurb = "Pegasi have psionically enhanced feathered wings. They can fly briefly over obstacles and maneuver in weightlessness, but require air and tire with exertion."
	stat_modifiers = list(STAT_DX = 2, STAT_HT = -1)
	infection_modifier = 1.5
	archetype_organ = /obj/item/organ/internal/pony_wings
	archetype_tag = "pony wings"
	wing_state = "m_pony_wings_pony_folded_FRONT"
	open_wing_state = "m_pony_wings_pony_FRONT"
	inherent_verbs = list(/mob/living/carbon/human/proc/pony_telepathy, /mob/living/carbon/human/proc/pony_flight)

/datum/species/pony/pegasus/thestral
	name = "Thestral"
	name_plural = "Thestrals"
	blurb = "Thestrals are nocturnal Equestrians with leathery wings, sharp fangs, and keen senses. Their eyes are sensitive to bright light."
	stat_modifiers = list(STAT_DX = 1, STAT_PER = 2, STAT_HT = -1)
	archetype_organ = /obj/item/organ/internal/pony_wings/thestral
	wing_state = "batpony_wings_folded"
	open_wing_state = "batpony_wings_open"
	ear_state = "m_pony_ears_thestral_FRONT"
	flight_cooldown = 15 SECONDS
	darksight = 8
	flash_mod = 1.5
	light_sensitive = TRUE
	unarmed_types = list(/datum/unarmed_attack/bite/pony_fangs, /datum/unarmed_attack/hoof)

/datum/species/pony/handle_post_spawn(var/mob/living/carbon/human/H)
	..()
	if(!H.pony_appearance_saved)
		H.pony_previous_h_style = H.h_style
		H.pony_previous_f_style = H.f_style
		H.pony_appearance_saved = TRUE
	var/datum/sprite_accessory/hair/style = GLOB.hair_styles_list[H.h_style]
	if(!istype(style, /datum/sprite_accessory/hair/pony))
		H.h_style = default_h_style
	H.f_style = default_f_style

/datum/species/pony/remove_inherent_verbs(var/mob/living/carbon/human/H)
	H.pony_stop_flight()
	H.pony_floating_items = FALSE
	H.pony_release_grips()
	var/datum/species/next_species = H.dna ? all_species[H.dna.species] : null
	if(!istype(next_species, /datum/species/pony))
		H.h_style = H.pony_previous_h_style
		H.f_style = H.pony_previous_f_style
		H.pony_previous_h_style = null
		H.pony_previous_f_style = null
		H.pony_appearance_saved = FALSE
	..()

/datum/species/pony/handle_death(var/mob/living/carbon/human/H)
	H.pony_stop_flight()
	H.pony_floating_items = FALSE
	H.pony_release_grips()

/datum/species/pony/get_race_key(var/mob/living/carbon/human/H)
	if(!H)
		return ..()
	return "[race_key]_[H.r_hair]_[H.g_hair]_[H.b_hair]_[H.pony_can_fly()]_[H.eye_closed]_[!!H.internal_organs_by_name[archetype_tag]]"

/datum/species/pony/get_limb_icon(var/obj/item/organ/external/limb, var/selected_icon)
	if(limb.robotic >= ORGAN_ROBOT && selected_icon == 'icons/mob/human.dmi')
		return 'icons/mob/human_races/robotic.dmi'
	if(limb.robotic < ORGAN_ROBOT && limb.owner && (SKELETON in limb.owner.mutations))
		return 'icons/mob/human_races/r_skeleton.dmi'
	if(limb.robotic < ORGAN_ROBOT && selected_icon == 'icons/mob/human.dmi' && (limb.organ_tag in list(BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT)))
		return icobase
	return ..()

/datum/species/pony/get_limb_icon_state(var/obj/item/organ/external/limb, var/selected_state)
	if(limb.robotic < ORGAN_ROBOT && !(limb.owner && (SKELETON in limb.owner.mutations)))
		switch(limb.organ_tag)
			if(BP_L_HAND)
				return "pony_l_arm"
			if(BP_R_HAND)
				return "pony_r_arm"
			if(BP_L_FOOT)
				return "pony_l_leg"
			if(BP_R_FOOT)
				return "pony_r_leg"
		return ..()
	var/state = limb.organ_tag
	if(state == BP_CHEST)
		state = "torso"
	var/female = limb.dna ? limb.dna.GetUIState(DNA_UI_GENDER) : (limb.owner && limb.owner.gender == FEMALE)
	var/gendered_state = "[state]_[female ? "f" : "m"]"
	var/list/states = icon_states(limb.icon)
	if(gendered_state in states)
		return gendered_state
	return state

/datum/species/pony/process_limb_icon(var/obj/item/organ/external/limb, var/icon/limb_icon)
	if(limb.robotic >= ORGAN_ROBOT || (limb.owner && (SKELETON in limb.owner.mutations)))
		return ..()
	// Split the source legs at the hoof so amputation and the medical HUD have real distal pixels.
	if(limb.organ_tag in list(BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT))
		limb_icon.DrawBox(null, 1, 4, 32, 32)
		limb.icon_cache_key += "_[limb.organ_tag]"
	else if(limb.organ_tag in list(BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG))
		limb_icon.DrawBox(null, 1, 1, 32, 3)
		limb.icon_cache_key += "_[limb.organ_tag]"
	return limb_icon

/datum/species/pony/handle_movement_delay_special(var/mob/living/carbon/human/H)
	var/holding = H.pony_occupied_forehooves()
	for(var/tag in list(BP_L_ARM, BP_R_ARM, BP_L_HAND, BP_R_HAND))
		if(!H.pony_limb_usable(tag))
			return 2 + holding
	if(H.buckled || H.pony_can_fly())
		return 0
	return holding ? holding : -0.5

/datum/species/pony/can_overcome_gravity(var/mob/living/carbon/human/H)
	return H.pony_can_fly()

/datum/species/pony/can_fall(var/mob/living/carbon/human/H)
	return !H.pony_can_fly()

/datum/species/pony/handle_environment_special(var/mob/living/carbon/human/H)
	if(H.pony_flight_until)
		if(!H.pony_can_fly())
			H.pony_stop_flight()
		else
			H.adjustStaminaLoss(max(1, 3 - stat_to_modifier(H.stats[STAT_HT])))
			if(!H.pony_can_fly())
				H.pony_stop_flight()
	if(H.pony_floating_items && !H.pony_horn_usable())
		H.pony_floating_items = FALSE
		to_chat(H, "<span class='warning'>Your horn can no longer support your carried items.</span>")
	if(H.pony_floating_items && (H.l_hand || H.r_hand))
		H.adjustStaminaLoss(1)
		if(!H.pony_horn_usable())
			H.pony_floating_items = FALSE
			to_chat(H, "<span class='warning'>You are too exhausted to keep your carried items floating.</span>")
	if(!H.can_use_telekinesis())
		H.pony_release_grips()

/datum/hud_data/pony/New()
	gear = gear.Copy()
	gear -= "gloves"
	..()

/datum/unarmed_attack/hoof
	attack_verb = list("hoof-struck")
	attack_noun = list("hoof")
	damage = 1

/datum/unarmed_attack/bite/pony_fangs
	attack_verb = list("bit")
	attack_noun = list("fangs")
	damage = 2
	sharp = TRUE

/datum/species/pony/proc/handle_nutriment(var/mob/living/carbon/human/H, var/datum/reagent/nutriment/food, var/removed)
	if(istype(food, /datum/reagent/nutriment/protein))
		H.adjustToxLoss(2 * removed)
		return FALSE
	if(H.pony_organ_usable("pony core") && H.stat != DEAD && H.statcheck(H.stats[STAT_HT], 10, null, STAT_HT))
		H.heal_organ_damage(removed, 0)
		H.adjustStaminaLoss(-removed)
	return TRUE

/datum/sprite_accessory/hair/pony
	name = "Soldier (Equestrian)"
	icon = 'icons/mob/human_races/pony/face.dmi'
	icon_state = "hair_eq_wintersshield"
	blend = ICON_MULTIPLY
	species_allowed = list("Earth Pony", "Unicorn", "Pegasus", "Thestral")

/datum/sprite_accessory/hair/pony/dork
	name = "Dork (Equestrian)"
	icon_state = "hair_eq_dork"

/datum/sprite_accessory/hair/pony/punk
	name = "Punk Rocker (Equestrian)"
	icon_state = "hair_eq_punkrocker"

/datum/sprite_accessory/hair/pony/timid
	name = "Timid (Equestrian)"
	icon_state = "hair_eq_timid"

/datum/sprite_accessory/hair/pony/bookworm
	name = "Bookworm (Equestrian)"
	icon_state = "hair_eq_bookworm"

/datum/sprite_accessory/hair/pony/fatale
	name = "Fatale (Equestrian)"
	icon_state = "hair_eq_fatale"

/datum/language/ponish
	name = "Ponish"
	desc = "A flowing tonal language spoken by Equestrians, known for its metaphors and vibrant vocabulary."
	key = "-"
	flags = RESTRICTED
	space_chance = 75
	syllables = list("rivaa", "llanseri", "intsnu", "ta", "awupen", "bunzhabee", "tsubki", "waalluku", "zi", "aah", "irrit", "lovinmu", "urhka", "entsulla", "tsa", "wabewa", "falozha", "suntsuphoa", "sorra", "olrisa", "sinrron", "konsu", "surr", "vusan", "ipuxi")

/datum/language/ponish/get_random_name(var/gender)
	return pick(GLOB.pony_names)
