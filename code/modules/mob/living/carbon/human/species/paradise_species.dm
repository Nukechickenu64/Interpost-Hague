// Species datums adapted from Paradise to the legacy Interpost species API.

/datum/species/abductor
	name = "Abductor"
	name_plural = "Abductors"
	blurb = "Abductors are secretive alien raiders who rely on strange technology and telepathic coordination."
	icobase = 'icons/mob/human_races/r_abductor.dmi'
	appearance_flags = HAS_EYE_COLOR | HAS_SKIN_COLOR
	species_flags = SPECIES_FLAG_NO_SCAN | SPECIES_FLAG_NO_POISON
	spawn_flags = SPECIES_IS_RESTRICTED
	blood_color = "#00ff00"
	flesh_color = "#b5b5b5"

/datum/species/diona
	name = "Diona"
	name_plural = "Dionae"
	blurb = "Dionae are plant-like gestalt beings that thrive in light and struggle when starved."
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
	has_limbs = list(
		BP_CHEST = list("path" = /obj/item/organ/external/chest, "descriptor" = "core trunk"),
		BP_GROIN = list("path" = /obj/item/organ/external/groin, "descriptor" = "fork"),
		BP_HEAD = list("path" = /obj/item/organ/external/head, "descriptor" = "head"),
		BP_L_ARM = list("path" = /obj/item/organ/external/arm, "descriptor" = "left upper tendril"),
		BP_R_ARM = list("path" = /obj/item/organ/external/arm/right, "descriptor" = "right upper tendril"),
		BP_L_LEG = list("path" = /obj/item/organ/external/leg, "descriptor" = "left lower tendril"),
		BP_R_LEG = list("path" = /obj/item/organ/external/leg/right, "descriptor" = "right lower tendril"),
		BP_L_HAND = list("path" = /obj/item/organ/external/hand, "descriptor" = "left grasper"),
		BP_R_HAND = list("path" = /obj/item/organ/external/hand/right, "descriptor" = "right grasper"),
		BP_L_FOOT = list("path" = /obj/item/organ/external/foot, "descriptor" = "left foot"),
		BP_R_FOOT = list("path" = /obj/item/organ/external/foot/right, "descriptor" = "right foot")
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
	blurb = "Diomorphs are pod-grown dionae that keep the same light-fed resilience while retaining diona physiology."

/datum/species/golem/random
	name = "Random Golem"
	name_plural = "Random Golems"
	blurb = "A random golem shell that resolves into one of many material variants."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/adamantine
	name = "Adamantine Golem"
	name_plural = "Adamantine Golems"
	blurb = "A dense mineral construct with stable, durable golem physiology."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plasma
	name = "Plasma Golem"
	name_plural = "Plasma Golems"
	blurb = "A volatile phoron-bodied golem that is fragile around heat and open flame."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/diamond
	name = "Diamond Golem"
	name_plural = "Diamond Golems"
	blurb = "A hardened crystal golem known for exceptional toughness."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/gold
	name = "Gold Golem"
	name_plural = "Gold Golems"
	blurb = "A lighter golem body that trades durability for speed."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/silver
	name = "Silver Golem"
	name_plural = "Silver Golems"
	blurb = "A dense silver shell suited to forceful melee strikes."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plasteel
	name = "Plasteel Golem"
	name_plural = "Plasteel Golems"
	blurb = "An exceptionally heavy combat golem built for impact over mobility."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/titanium
	name = "Titanium Golem"
	name_plural = "Titanium Golems"
	blurb = "A heat-tolerant golem shell adapted to hazardous high-temperature environments."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plastitanium
	name = "Plastitanium Golem"
	name_plural = "Plastitanium Golems"
	blurb = "A reinforced titanium composite body with excellent burn resilience."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/alloy
	name = "Alien Alloy Golem"
	name_plural = "Alien Alloy Golems"
	blurb = "An advanced alloy frame that emphasizes self-repair and alien construction methods."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/wood
	name = "Wood Golem"
	name_plural = "Wood Golems"
	blurb = "A living timber construct that echoes some plant-like vulnerabilities and recovery."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/uranium
	name = "Uranium Golem"
	name_plural = "Uranium Golems"
	blurb = "A radioactive mineral golem whose body is saturated with unstable ore."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/plastic
	name = "Plastic Golem"
	name_plural = "Plastic Golems"
	blurb = "A synthetic golem chassis that favors flexibility over hardness."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/sand
	name = "Sand Golem"
	name_plural = "Sand Golems"
	blurb = "A brittle aggregate body that shrugs off some force but suffers from heat and energy."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/glass
	name = "Glass Golem"
	name_plural = "Glass Golems"
	blurb = "A fragile glass construct that can turn incoming energy to its advantage."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/bluespace
	name = "Bluespace Golem"
	name_plural = "Bluespace Golems"
	blurb = "A spatially unstable golem variant tied to volatile bluespace mineralization."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/bananium
	name = "Bananium Golem"
	name_plural = "Bananium Golems"
	blurb = "A prank-oriented clown-metal shell with intentionally harmless combat profile."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/tranquillite
	name = "Tranquillite Golem"
	name_plural = "Tranquillite Golems"
	blurb = "A mime-themed mineral frame associated with quiet, defensive utility."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/golem/cloth
	name = "Cloth Golem"
	name_plural = "Cloth Golems"
	blurb = "A wrapped, enchanted construct that sacrifices resilience for unusual persistence."
	icobase = 'icons/mob/human_races/r_cloth_golem.dmi'
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/tajaran
	name = "Farwa"
	name_plural = "Farwa"
	blurb = "A tajaran monkey-form adapted as the lesser biological form of Tajaran."
	icobase = 'icons/mob/human_races/monkeys/r_farwa.dmi'
	greater_form = /datum/species/tajaran
	tail = "farwatail"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/vulpkanin
	name = "Wolpin"
	name_plural = "Wolpin"
	blurb = "A vulpkanin monkey-form with reduced dexterity and an uplifted greater form."
	icobase = 'icons/mob/human_races/monkeys/r_wolpin.dmi'
	greater_form = /datum/species/vulpkanin
	tail = "wolpintail"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/skrell
	name = "Neara"
	name_plural = "Neara"
	blurb = "A skrell monkey-form representing a devolved lesser biology."
	icobase = 'icons/mob/human_races/monkeys/r_neara.dmi'
	greater_form = /datum/species/skrell
	tail = null
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/unathi
	name = "Stok"
	name_plural = "Stok"
	blurb = "An unathi monkey-form that matures into full unathi physiology."
	icobase = 'icons/mob/human_races/monkeys/r_stok.dmi'
	greater_form = /datum/species/unathi
	tail = "stoktail"
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/monkey/nian_worme
	name = "Nian Worme"
	name_plural = "Nian Wormes"
	blurb = "A nian moth monkey-form with fragile biology and a clear greater form progression."
	icobase = 'icons/mob/human_races/monkeys/r_worme.dmi'
	greater_form = /datum/species/moth
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/drask
	name = "Drask"
	name_plural = "Drask"
	blurb = "Cold-adapted drask handle low temperatures comfortably but suffer in warm climates."
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
	blurb = "Greys are frail, enigmatic aliens with prominent darkvision and unusual appearance."
	icobase = 'icons/mob/human_races/grey/r_grey.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	darksight = 10
	blood_color = "#a200ff"
	flesh_color = "#a598ad"

/datum/species/kidan
	name = "Kidan"
	name_plural = "Kidan"
	blurb = "Kidan are insectoid humanoids with tough exoskeletal traits and altered toxin response."
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
	blurb = "Machine bodies are synthetic humanoid shells with heavily reduced biological needs."
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
	blurb = "Nian are moth-like humanoids with delicate physiology and distinct cultural identity."
	icobase = 'icons/mob/human_races/nian/r_moth.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	toxins_mod = 1.5
	blood_color = "#b9ae9c"

/datum/species/plasmaman
	name = "Plasmaman"
	name_plural = "Plasmamen"
	blurb = "Plasmamen breathe phoron and are poisoned by oxygen, demanding specialized life support."
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
	blurb = "Animated skeletal remains with minimal organic systems and unusual durability profile."
	icobase = 'icons/mob/human_races/r_skeleton.dmi'
	species_flags = SPECIES_FLAG_NO_MINOR_CUT | SPECIES_FLAG_NO_POISON
	spawn_flags = SPECIES_IS_RESTRICTED
	blood_color = "#eeeeee"
	flesh_color = "#d6d1c5"
	has_organ = list(
		BP_BRAIN = /obj/item/organ/internal/brain/golem
		)

/datum/species/skeleton/lich
	name = "Lich"
	name_plural = "Liches"
	blurb = "A magically sustained skeletal form traditionally associated with necromancy."

/datum/species/skeleton/brittle
	name = "Brittle Skeleton"
	name_plural = "Brittle Skeletons"
	blurb = "A weaker skeletal form that shatters under force more readily than ancient variants."
	brute_mod = 1.5

/datum/species/skrell
	name = "Skrell"
	name_plural = "Skrell"
	blurb = "Skrell are amphibious psionically-inclined humanoids known for adaptable scholarly cultures."
	max_age = 220
	icobase = 'icons/mob/human_races/r_skrell.dmi'
	appearance_flags = HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	blood_color = "#1d2cbf"
	flesh_color = "#8cd7a3"

/datum/species/skulk
	name = "Skkulakin"
	name_plural = "Skkulakin"
	blurb = "Skkulakin are furtive humanoids marked by dark palettes and uncommon physiology."
	max_age = 70
	icobase = 'icons/mob/human_races/skulk/r_skulkbrown.dmi'
	appearance_flags = HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	flesh_color = "#e3e2dd"

/datum/species/slime
	name = "Slime People"
	name_plural = "Slime People"
	blurb = "Slime people are gelatinous humanoids with resilient unbreakable limb morphology."
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
	blurb = "Tajaran are feline humanoids adapted to cold climates with strong claws and tail balance."
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
	blurb = "Unathi are reptilian desert-born humanoids with high heat tolerance and predatory traits."
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
	blurb = "Ash walkers are primitive unathi-adjacent wasteland survivors adapted to extreme terrain."
	spawn_flags = SPECIES_IS_RESTRICTED

/datum/species/vulpkanin
	name = "Vulpkanin"
	name_plural = "Vulpkanin"
	blurb = "Vulpkanin are canid humanoids with keen senses, expressive tails, and clawed natural attacks."
	icobase = 'icons/mob/human_races/r_vulpkanin.dmi'
	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	spawn_flags = SPECIES_IS_RESTRICTED
	unarmed_types = list(/datum/unarmed_attack/claws)
	tail = "vulptail"
	flesh_color = "#966464"
