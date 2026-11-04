// MED 00:54:20 help panel and 01:04:40 injection. Source roles and Chemfab
// costs are recorded; effect strengths/metabolism are local reconstruction.
// See docs/os13_medicine_parity.md before treating them as source constants.

/mob/proc/chemical_stat_modifier(stat_type)
	return 0

/mob/living/carbon/chemical_stat_modifier(stat_type)
	if(stat == DEAD)
		return 0
	if(ishuman(src))
		var/mob/living/carbon/human/human = src
		if(human.isSynthetic())
			return 0
	var/modifier = chem_effects["os13_stat_[stat_type]"]
	return isnum(modifier) ? modifier : 0

// Preserve permanent stats, training, species changes and admin edits.
// The contribution disappears when the normal chemistry cycle clears effects.
/mob/proc/effective_stat(stat_type)
	return stats[stat_type] + chemical_stat_modifier(stat_type)

/datum/reagent/os13_medicine
	name = "OS13 medicine"
	reagent_state = LIQUID
	taste_description = "bitterness"
	metabolism = REM * 0.5
	scannable = TRUE
	var/announced = FALSE

/datum/reagent/os13_medicine/hyperstim
	name = "Hyperstim"
	description = "A combat stimulant that temporarily enhances strength, coordination and endurance."
	color = "#d64e66"

/datum/reagent/os13_medicine/hyperstim/affect_blood(mob/living/carbon/patient, alien, removed)
	patient.add_up_to_chemical_effect("os13_stat_[STAT_ST]", 5)
	patient.add_up_to_chemical_effect("os13_stat_[STAT_DX]", 2)
	patient.add_up_to_chemical_effect("os13_stat_[STAT_HT]", 2)
	if(!announced)
		announced = TRUE
		to_chat(patient, SPAN_NOTICE("... I'M FEELING SO GOOD! ..."))

/datum/reagent/os13_medicine/mnemosine
	name = "Mnemosine"
	description = "A cognitive stimulant that temporarily improves intellectual performance."
	color = "#ac8cdb"

/datum/reagent/os13_medicine/mnemosine/affect_blood(mob/living/carbon/patient, alien, removed)
	patient.add_up_to_chemical_effect("os13_stat_[STAT_IQ]", 2)

/datum/reagent/os13_medicine/oxivior
	name = "Oxivior"
	description = "An oxygenic liquid that supports oxygen delivery through circulating blood."
	color = "#87ddec"

/datum/reagent/os13_medicine/oxivior/affect_blood(mob/living/carbon/patient, alien, removed)
	patient.add_up_to_chemical_effect(CE_OXYGENATED, 1)

/datum/reagent/os13_medicine/monogreline
	name = "Monogreline"
	description = "A sedative that causes drowsiness and, with continued exposure, sleep."
	color = "#5981b9"

/datum/reagent/os13_medicine/monogreline/affect_blood(mob/living/carbon/patient, alien, removed)
	patient.drowsyness = max(patient.drowsyness, min(60, patient.drowsyness + 4))
	if(patient.chem_doses[type] >= 1)
		patient.Sleeping(5)

/datum/reagent/os13_medicine/polythesine
	name = "Polythesine"
	description = "A neuroleptic that suppresses hallucinations."
	color = "#8cb69e"

/datum/reagent/os13_medicine/polythesine/affect_blood(mob/living/carbon/patient, alien, removed)
	patient.add_up_to_chemical_effect(CE_MIND, 2)

// Stable physical product types also work when placed by a mapper.
/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/hyperstim
	name = "hyperstim injector"
	starts_with = list(/datum/reagent/os13_medicine/hyperstim = 5)

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/mnemosine
	name = "mnemosine injector"
	starts_with = list(/datum/reagent/os13_medicine/mnemosine = 5)

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/oxivior
	name = "oxivior injector"
	starts_with = list(/datum/reagent/os13_medicine/oxivior = 5)

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/monogreline
	name = "monogreline injector"
	starts_with = list(/datum/reagent/os13_medicine/monogreline = 5)

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/polythesine
	name = "polythesine injector"
	starts_with = list(/datum/reagent/os13_medicine/polythesine = 5)
