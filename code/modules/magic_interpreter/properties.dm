/decl/magic_word/magic_property
	var/value_kind = "num"
	var/min_value = 0
	var/max_value = 100
	var/max_length = MAX_NAME_LEN

/decl/magic_word/magic_property/proc/accepts(atom/target)
	return TRUE

/decl/magic_word/magic_property/magic_cost(datum/magic_spell/S)
	if(value_kind == "text")
		return base_cost + length(S.value_text()) / 4
	return ..()

/decl/magic_word/magic_property/proc/get_value(atom/target)
	return null

/decl/magic_word/magic_property/proc/set_value(atom/target, value)
	return

/decl/magic_word/magic_property/sanguis
	name = "blood volume"
	words = list("sanguis", "cruor")
	aliases = list("blood", "blood_volume", "bloodloss")
	base_cost = 15
	cost_per_unit = 0.5

/decl/magic_word/magic_property/sanguis/accepts(atom/target)
	var/mob/living/carbon/human/H = target
	return istype(H) && H.vessel && H.species && H.species.blood_volume

/decl/magic_word/magic_property/sanguis/get_value(mob/living/carbon/human/H)
	return H.get_blood_volume()

/decl/magic_word/magic_property/sanguis/set_value(mob/living/carbon/human/H, value)
	var/wanted = H.species.blood_volume * value / 100
	var/current = H.vessel.get_reagent_amount(/datum/reagent/blood)
	if(wanted < current)
		H.vessel.remove_reagent(/datum/reagent/blood, current - wanted)
	else if(wanted > current)
		H.vessel.add_reagent(/datum/reagent/blood, wanted - current)
		H.fixblood()

/decl/magic_word/magic_property/damage
	max_value = 200
	base_cost = 15
	cost_per_unit = 0.5
	var/damage_kind

/decl/magic_word/magic_property/damage/accepts(atom/target)
	return isliving(target)

/decl/magic_word/magic_property/damage/get_value(mob/living/L)
	switch(damage_kind)
		if("brute")
			return L.getBruteLoss()
		if("burn")
			return L.getFireLoss()
		if("tox")
			return L.getToxLoss()
		if("oxy")
			return L.getOxyLoss()

/decl/magic_word/magic_property/damage/set_value(mob/living/L, value)
	var/delta = value - get_value(L)
	switch(damage_kind)
		if("brute")
			L.adjustBruteLoss(delta)
		if("burn")
			L.adjustFireLoss(delta)
		if("tox")
			L.adjustToxLoss(delta)
		if("oxy")
			L.adjustOxyLoss(delta)
	L.updatehealth()

/decl/magic_word/magic_property/damage/aeris
	name = "toxin damage"
	words = list("aeris", "venenum")
	aliases = list("toxloss", "tox", "toxin")
	damage_kind = "tox"

/decl/magic_word/magic_property/damage/brute
	name = "brute damage"
	words = list("vulnus")
	aliases = list("bruteloss", "brute")
	damage_kind = "brute"

/decl/magic_word/magic_property/damage/burn
	name = "burn damage"
	words = list("adustio")
	aliases = list("fireloss", "burnloss", "burn")
	damage_kind = "burn"

/decl/magic_word/magic_property/damage/oxy
	name = "oxygen damage"
	words = list("suffocatio")
	aliases = list("oxyloss", "oxy", "suffocation")
	damage_kind = "oxy"

/decl/magic_word/magic_property/calor
	name = "body temperature"
	words = list("calor", "temperies")
	aliases = list("bodytemperature", "temperature", "temp")
	max_value = 1000
	cost_per_unit = 0.1

/decl/magic_word/magic_property/calor/accepts(atom/target)
	return isliving(target)

/decl/magic_word/magic_property/calor/get_value(mob/living/L)
	return L.bodytemperature

/decl/magic_word/magic_property/calor/set_value(mob/living/L, value)
	L.bodytemperature = value

/decl/magic_word/magic_property/color
	name = "color"
	words = list("color", "tinctura")
	aliases = list("colour", "tint")
	value_kind = "color"
	cosmetic = TRUE
	base_cost = 5

/decl/magic_word/magic_property/color/set_value(atom/target, value)
	target.color = value

/decl/magic_word/magic_property/alpha
	name = "opacity"
	words = list("alpha", "perspicuitas")
	aliases = list("opacity", "transparency")
	max_value = 255
	cosmetic = TRUE
	base_cost = 5
	cost_per_unit = 0.05

/decl/magic_word/magic_property/alpha/get_value(atom/target)
	return target.alpha

/decl/magic_word/magic_property/alpha/set_value(atom/target, value)
	target.alpha = round(value)

/decl/magic_word/magic_property/nomen
	name = "name"
	words = list("nomen", "titulus")
	aliases = list("name")
	value_kind = "text"
	cosmetic = TRUE

/decl/magic_word/magic_property/nomen/set_value(atom/target, value)
	if(!ismob(target))
		target.SetName(value)
		return
	var/mob/M = target
	var/old_name = M.real_name
	M.fully_replace_character_name(value)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/card/id/I = H.wear_id && H.wear_id.GetIdCard()
		if(I && I.registered_name == old_name)
			I.registered_name = value
			I.update_name()
		H.SetName(H.get_visible_name())

/decl/magic_word/magic_property/aer
	name = "air amount (mol/tile)"
	words = list("aer", "aura")
	aliases = list("moles", "air")
	max_value = PRESSURE_TO_MOLES(1000)
	accepts_turf = TRUE
	base_cost = 30
	cost_per_unit = 0.1 * ONE_ATMOSPHERE / MOLES_CELLSTANDARD

/decl/magic_word/magic_property/aer/accepts(atom/target)
	return istype(get_turf(target), /turf/simulated)

/decl/magic_word/magic_property/aer/get_value(atom/target)
	var/turf/T = get_turf(target)
	var/datum/gas_mixture/air = T.return_air()
	return air ? air.get_tile_moles() : 0

/decl/magic_word/magic_property/aer/set_value(atom/target, value)
	var/turf/T = get_turf(target)
	var/datum/gas_mixture/air = T.return_air()
	if(!air)
		return
	if(air.total_moles <= 0)
		if(!value)
			return
		if(air.temperature < TCMB)
			air.temperature = T20C
		air.adjust_multi(GAS_OXYGEN, MOLES_O2STANDARD * air.group_multiplier, GAS_NITROGEN, MOLES_N2STANDARD * air.group_multiplier)
	var/current = air.get_tile_moles()
	if(current > 0)
		air.multiply(value / current)

/decl/magic_word/magic_property/descriptio
	name = "description"
	words = list("descriptio", "narratio")
	aliases = list("desc", "description")
	value_kind = "text"
	max_length = MAX_MESSAGE_LEN
	cosmetic = TRUE

/decl/magic_word/magic_property/descriptio/set_value(atom/target, value)
	target.desc = value
