// Species datums adapted from Paradise to the legacy Interpost species API.

/datum/species/abductor
	name = "Abductor"
	name_plural = "Abductors"
	icobase = 'icons/mob/human_races/r_abductor.dmi'
	appearance_flags = HAS_EYE_COLOR | HAS_SKIN_COLOR
	species_flags = SPECIES_FLAG_NO_SCAN | SPECIES_FLAG_NO_POISON
	spawn_flags = SPECIES_IS_RESTRICTED
	blood_color = "#00ff00"
	flesh_color = "#b5b5b5"

/datum/species/diona
	name = "Diona"
	name_plural = "Dionae"
	icobase = 'icons/mob/human_races/r_diona.dmi'
	appearance_flags = HAS_EYE_COLOR
	species_flags = SPECIES_FLAG_IS_PLANT
	spawn_flags = SPECIES_IS_RESTRICTED
	blood_color = "#004400"
	flesh_color = "#907e4a"
	breath_type = null
	poison_type = null
	brute_mod = 0.8
	var/pod = FALSE
	has_organ = list(
		BP_HEART = /obj/item/organ/internal/heart,
		BP_STOMACH = /obj/item/organ/internal/stomach,
		BP_LIVER = /obj/item/organ/internal/liver,
		BP_KIDNEYS = /obj/item/organ/internal/kidneys,
		BP_BRAIN = /obj/item/organ/internal/brain,
		BP_APPENDIX = /obj/item/organ/internal/appendix,
		BP_GUTS = /obj/item/organ/internal/guts,
		BP_EYES = /obj/item/organ/internal/eyes
		)

/datum/species/diona/handle_environment_special(var/mob/living/carbon/human/H)
	if(H.InStasis() || H.stat == DEAD)
		return
	var/light_amount = 0
	if(isturf(H.loc))
		var/turf/T = H.loc
		light_amount = min(1, T.get_lumcount()) - 0.5
	if(light_amount > 0)
		H.adjust_nutrition(light_amount * 10)
		if(light_amount > 0.2 && (pod || H.health > 0))
			H.heal_overall_damage(1, 1)
			H.adjustOxyLoss(-1)
			H.adjustToxLoss(-1)
	if(H.nutrition < NUTRITION_LEVEL_STARVING + 50)
		H.take_overall_damage(2, 0)

/datum/species/diona/pod
	name = "Diomorph"
	name_plural = "Diomorphs"

/datum/species/golem/random
	name = "Random Golem"
	name_plural = "Random Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/adamantine
	name = "Adamantine Golem"
	name_plural = "Adamantine Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plasma
	name = "Plasma Golem"
	name_plural = "Plasma Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/diamond
	name = "Diamond Golem"
	name_plural = "Diamond Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/gold
	name = "Gold Golem"
	name_plural = "Gold Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/silver
	name = "Silver Golem"
	name_plural = "Silver Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plasteel
	name = "Plasteel Golem"
	name_plural = "Plasteel Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/titanium
	name = "Titanium Golem"
	name_plural = "Titanium Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plastitanium
	name = "Plastitanium Golem"
	name_plural = "Plastitanium Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/alloy
	name = "Alien Alloy Golem"
	name_plural = "Alien Alloy Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/wood
	name = "Wood Golem"
	name_plural = "Wood Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/uranium
	name = "Uranium Golem"
	name_plural = "Uranium Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plastic
	name = "Plastic Golem"
	name_plural = "Plastic Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/sand
	name = "Sand Golem"
	name_plural = "Sand Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/glass
	name = "Glass Golem"
	name_plural = "Glass Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/bluespace
	name = "Bluespace Golem"
	name_plural = "Bluespace Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/bananium
	name = "Bananium Golem"
	name_plural = "Bananium Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/tranquillite
	name = "Tranquillite Golem"
	name_plural = "Tranquillite Golems"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/cloth
	name = "Cloth Golem"
	name_plural = "Cloth Golems"
	icobase = 'icons/mob/human_races/r_cloth_golem.dmi'
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/tajaran
	name = "Farwa"
	name_plural = "Farwa"
	icobase = 'icons/mob/human_races/monkeys/r_farwa.dmi'
	greater_form = /datum/species/tajaran
	tail = "farwatail"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/vulpkanin
	name = "Wolpin"
	name_plural = "Wolpin"
	icobase = 'icons/mob/human_races/monkeys/r_wolpin.dmi'
	greater_form = /datum/species/vulpkanin
	tail = "wolpintail"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/skrell
	name = "Neara"
	name_plural = "Neara"
	icobase = 'icons/mob/human_races/monkeys/r_neara.dmi'
	greater_form = /datum/species/skrell
	tail = null
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/unathi
	name = "Stok"
	name_plural = "Stok"
	icobase = 'icons/mob/human_races/monkeys/r_stok.dmi'
	greater_form = /datum/species/unathi
	tail = "stoktail"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/nian_worme
	name = "Nian Worme"
	name_plural = "Nian Wormes"
	icobase = 'icons/mob/human_races/monkeys/r_worme.dmi'
	greater_form = /datum/species/moth
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/drask
	name = "Drask"
	name_plural = "Drask"
	max_age = 500
	icobase = 'icons/mob/human_races/r_drask.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	cold_level_1 = -1
	cold_level_2 = -1
	cold_level_3 = -1
	heat_level_1 = 310
	heat_level_2 = 340
	heat_level_3 = 400
	blood_color = "#a3d4eb"
	flesh_color = "#a3d4eb"

/datum/species/grey
	name = "Grey"
	name_plural = "Greys"
	icobase = 'icons/mob/human_races/grey/r_grey.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	darksight = 10
	blood_color = "#a200ff"
	flesh_color = "#a598ad"

/datum/species/kidan
	name = "Kidan"
	name_plural = "Kidan"
	icobase = 'icons/mob/human_races/r_kidan.dmi'
	appearance_flags = HAS_SKIN_COLOR | HAS_EYE_COLOR
	species_flags = SPECIES_FLAG_NO_MINOR_CUT
	spawn_flags = SPECIES_IS_RESTRICTED
	brute_mod = 0.8
	toxins_mod = 1.7
	blood_color = "#fb9800"
	flesh_color = "#ba7814"

/datum/species/machine
	name = "Machine"
	name_plural = "Machines"
	max_age = 60
	icobase = 'icons/mob/human_races/r_machine.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	species_flags = SPECIES_FLAG_NO_POISON
	spawn_flags = SPECIES_IS_RESTRICTED
	toxins_mod = 0
	breath_type = null
	poison_type = null
	blood_color = "#d12d2d"
	flesh_color = "#aaaaaa"
	has_organ = list(
		BP_HEART = /obj/item/organ/internal/heart,
		BP_BRAIN = /obj/item/organ/internal/brain
		)

/datum/species/moth
	name = "Nian"
	name_plural = "Nianae"
	icobase = 'icons/mob/human_races/nian/r_moth.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	toxins_mod = 1.5
	blood_color = "#b9ae9c"

/datum/species/plasmaman
	name = "Plasmaman"
	name_plural = "Plasmamen"
	max_age = 150
	icobase = 'icons/mob/human_races/r_plasmaman_sb.dmi'
	appearance_flags = HAS_EYE_COLOR
	species_flags = SPECIES_FLAG_NO_POISON
	spawn_flags = SPECIES_IS_RESTRICTED
	burn_mod = 1.5
	breath_type = "phoron"
	poison_type = "oxygen"
	flesh_color = "#8b3fba"

/datum/species/skeleton
	name = "Ancient Skeleton"
	name_plural = "Ancient Skeletons"
	icobase = 'icons/mob/human_races/r_skeleton.dmi'
	species_flags = SPECIES_FLAG_NO_MINOR_CUT | SPECIES_FLAG_NO_POISON
	spawn_flags = SPECIES_IS_RESTRICTED
	blood_color = "#eeeeee"
	flesh_color = "#d6d1c5"

/datum/species/skeleton/lich
	name = "Lich"
	name_plural = "Liches"

/datum/species/skeleton/brittle
	name = "Brittle Skeleton"
	name_plural = "Brittle Skeletons"
	brute_mod = 1.5

/datum/species/skrell
	name = "Skrell"
	name_plural = "Skrell"
	max_age = 220
	icobase = 'icons/mob/human_races/r_skrell.dmi'
	appearance_flags = HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	blood_color = "#1d2cbf"
	flesh_color = "#8cd7a3"

/datum/species/skulk
	name = "Skkulakin"
	name_plural = "Skkulakin"
	max_age = 70
	icobase = 'icons/mob/human_races/skulk/r_skulkbrown.dmi'
	appearance_flags = HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	flesh_color = "#e3e2dd"

/datum/species/slime
	name = "Slime People"
	name_plural = "Slime People"
	max_age = 130
	icobase = 'icons/mob/human_races/r_slime.dmi'
	appearance_flags = HAS_SKIN_COLOR | HAS_EYE_COLOR
	species_flags = SPECIES_FLAG_NO_MINOR_CUT
	spawn_flags = SPECIES_IS_RESTRICTED
	cold_level_1 = 280
	cold_level_2 = 240
	cold_level_3 = 200
	blood_color = "#0064c8"
	flesh_color = "#5fe8b1"
	brute_mod = 0.8
	has_organ = list(
		BP_HEART = /obj/item/organ/internal/heart,
		BP_STOMACH = /obj/item/organ/internal/stomach,
		BP_LIVER = /obj/item/organ/internal/liver,
		BP_KIDNEYS = /obj/item/organ/internal/kidneys,
		BP_BRAIN = /obj/item/organ/internal/brain/slime,
		BP_APPENDIX = /obj/item/organ/internal/appendix,
		BP_GUTS = /obj/item/organ/internal/guts,
		BP_EYES = /obj/item/organ/internal/eyes
		)
	has_limbs = list(
		BP_CHEST = list("path" = /obj/item/organ/external/chest/unbreakable/slime),
		BP_GROIN = list("path" = /obj/item/organ/external/groin/unbreakable/slime),
		BP_HEAD = list("path" = /obj/item/organ/external/head/unbreakable/slime),
		BP_L_ARM = list("path" = /obj/item/organ/external/arm/unbreakable/slime),
		BP_R_ARM = list("path" = /obj/item/organ/external/arm/right/unbreakable/slime),
		BP_L_LEG = list("path" = /obj/item/organ/external/leg/unbreakable/slime),
		BP_R_LEG = list("path" = /obj/item/organ/external/leg/right/unbreakable/slime),
		BP_L_HAND = list("path" = /obj/item/organ/external/hand/unbreakable/slime),
		BP_R_HAND = list("path" = /obj/item/organ/external/hand/right/unbreakable/slime),
		BP_L_FOOT = list("path" = /obj/item/organ/external/foot/unbreakable/slime),
		BP_R_FOOT = list("path" = /obj/item/organ/external/foot/right/unbreakable/slime)
		)

/datum/species/tajaran
	name = "Tajaran"
	name_plural = "Tajaran"
	icobase = 'icons/mob/human_races/r_tajaran.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	unarmed_types = list(/datum/unarmed_attack/claws)
	tail = "tajtail"
	cold_level_1 = 240
	cold_level_2 = 180
	cold_level_3 = 100
	flesh_color = "#b5a69b"

/datum/species/unathi
	name = "Unathi"
	name_plural = "Unathi"
	icobase = 'icons/mob/human_races/r_lizard.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	unarmed_types = list(/datum/unarmed_attack/claws)
	tail = "sogtail"
	cold_level_1 = 280
	cold_level_2 = 220
	cold_level_3 = 140
	heat_level_1 = 505
	heat_level_2 = 540
	heat_level_3 = 600
	flesh_color = "#34af10"

/datum/species/unathi/ashwalker
	name = "Ash Walker"
	name_plural = "Ash Walkers"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/vulpkanin
	name = "Vulpkanin"
	name_plural = "Vulpkanin"
	icobase = 'icons/mob/human_races/r_vulpkanin.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	unarmed_types = list(/datum/unarmed_attack/claws)
	tail = "vulptail"
	flesh_color = "#966464"
