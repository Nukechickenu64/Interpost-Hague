/decl/magic_word/magic_action/proc/spoken_amount(datum/magic_spell/S, default_amount, max_amount)
	if(S.values.len)
		var/datum/magic_value/V = S.values[1]
		if(V.kind == "num")
			return clamp(round(V.value), 1, max_amount)
	return default_amount

/decl/magic_word/magic_action/status
	base_cost = 20
	cost_per_unit = 2
	var/status_kind
	var/default_amount = 5
	var/max_amount = 30
	var/carbon_only = FALSE

/decl/magic_word/magic_action/status/magic_cost(datum/magic_spell/S)
	return base_cost + spoken_amount(S, default_amount, max_amount) * cost_per_unit

/decl/magic_word/magic_action/status/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!isliving(target))
		return S.fail("[target] has no body for the words to seize.")
	if(carbon_only && !iscarbon(target))
		return S.fail("[target] is not made of flesh the words understand.")
	var/mob/living/L = target
	var/amount = spoken_amount(S, default_amount, max_amount)
	switch(status_kind)
		if("stun")
			L.Stun(amount)
		if("weaken")
			L.Weaken(amount)
		if("paralyse")
			L.Paralyse(amount)
		if("sleep")
			L.Sleeping(amount)
		if("blind")
			L.eye_blind = max(L.eye_blind, amount)
		if("blur")
			L.eye_blurry = max(L.eye_blurry, amount)
		if("deaf")
			L.ear_deaf = max(L.ear_deaf, amount)
		if("silence")
			L.silent = max(L.silent, amount)
		if("confuse")
			L.confused = max(L.confused, amount)
		if("jitter")
			L.make_jittery(amount * 10)
		if("dizzy")
			L.make_dizzy(amount * 10)
		if("stutter")
			L.stuttering = max(L.stuttering, amount)
		if("slur")
			L.slurring = max(L.slurring, amount)
		if("drowsy")
			L.drowsyness = max(L.drowsyness, amount)
		if("hallucinate")
			var/mob/living/carbon/C = L
			C.hallucination(amount * 10, 50)
		if("shock")
			var/mob/living/carbon/C = L
			C.electrocute_act(amount * 2, null)
		if("radiate")
			L.apply_effect(amount * 5, IRRADIATE)
		if("flash")
			L.flash_eyes()
	return "[name] [L] ([amount])"

/decl/magic_word/magic_action/status/stupere
	name = "to stun"
	words = list("stupere")
	status_kind = "stun"
	base_cost = 30
	cost_per_unit = 4
	max_amount = 15

/decl/magic_word/magic_action/status/cadere
	name = "to fell"
	words = list("cadere")
	status_kind = "weaken"
	base_cost = 30
	cost_per_unit = 4
	max_amount = 15

/decl/magic_word/magic_action/status/torpere
	name = "to paralyse"
	words = list("torpere")
	status_kind = "paralyse"
	base_cost = 50
	cost_per_unit = 6
	max_amount = 15

/decl/magic_word/magic_action/status/dormire
	name = "to sleep"
	words = list("dormire")
	status_kind = "sleep"
	base_cost = 50
	cost_per_unit = 5
	max_amount = 20

/decl/magic_word/magic_action/status/caecare
	name = "to blind"
	words = list("caecare")
	status_kind = "blind"
	cost_per_unit = 3

/decl/magic_word/magic_action/status/obscurare
	name = "to blur sight"
	words = list("obscurare")
	status_kind = "blur"
	base_cost = 10
	cost_per_unit = 1

/decl/magic_word/magic_action/status/surdare
	name = "to deafen"
	words = list("surdare")
	status_kind = "deaf"
	base_cost = 15
	cost_per_unit = 1

/decl/magic_word/magic_action/status/tacere
	name = "to silence"
	words = list("tacere")
	status_kind = "silence"
	base_cost = 25
	cost_per_unit = 3

/decl/magic_word/magic_action/status/confundere
	name = "to confuse"
	words = list("confundere")
	status_kind = "confuse"

/decl/magic_word/magic_action/status/tremere
	name = "to make tremble"
	words = list("tremere")
	status_kind = "jitter"
	base_cost = 10
	cost_per_unit = 1

/decl/magic_word/magic_action/status/vertigo
	name = "to make dizzy"
	words = list("vertigo")
	status_kind = "dizzy"
	base_cost = 15
	cost_per_unit = 1

/decl/magic_word/magic_action/status/balbutire
	name = "to make stutter"
	words = list("balbutire")
	status_kind = "stutter"
	base_cost = 10
	cost_per_unit = 1

/decl/magic_word/magic_action/status/titubare
	name = "to make speech slur"
	words = list("titubare")
	status_kind = "slur"
	base_cost = 10
	cost_per_unit = 1

/decl/magic_word/magic_action/status/languere
	name = "to make drowsy"
	words = list("languere")
	status_kind = "drowsy"
	base_cost = 15
	cost_per_unit = 1

/decl/magic_word/magic_action/status/somniare
	name = "to make see visions"
	words = list("somniare")
	status_kind = "hallucinate"
	carbon_only = TRUE
	base_cost = 25
	cost_per_unit = 2

/decl/magic_word/magic_action/status/fulgur
	name = "to strike with lightning"
	words = list("fulgur")
	status_kind = "shock"
	carbon_only = TRUE
	base_cost = 35
	cost_per_unit = 4

/decl/magic_word/magic_action/status/radiare
	name = "to irradiate"
	words = list("radiare")
	status_kind = "radiate"
	base_cost = 30
	cost_per_unit = 3

/decl/magic_word/magic_action/status/fulgere
	name = "to dazzle"
	words = list("fulgere")
	status_kind = "flash"
	base_cost = 25
	cost_per_unit = 0

/decl/magic_word/magic_action/body
	base_cost = 20
	var/body_kind

/decl/magic_word/magic_action/body/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!iscarbon(target))
		return S.fail("[target] has no body for the words to seize.")
	var/mob/living/carbon/C = target
	var/amount = spoken_amount(S, 5, 30)
	switch(body_kind)
		if("starve")
			C.nutrition = max(C.nutrition - amount * 20, 0)
		if("feed")
			C.nutrition = max(C.nutrition, 400)
		if("purge")
			if(!C.reagents)
				return S.fail("[C] holds nothing to purge.")
			C.reagents.clear_reagents()
		if("cure")
			var/cured = 0
			for(var/ID in C.virus2)
				var/datum/disease2/disease/D = C.virus2[ID]
				if(D)
					D.cure(C)
					cured++
			if(!cured)
				return S.fail("[C] carries no sickness.")
		if("drunk")
			if(!C.reagents)
				return S.fail("[C] cannot be made drunk.")
			C.reagents.add_reagent(/datum/reagent/ethanol/vodka, amount * 2)
		if("sedate")
			if(!C.reagents)
				return S.fail("[C] cannot be sedated.")
			C.reagents.add_reagent(/datum/reagent/soporific, amount)
		if("cuff")
			if(!ishuman(C))
				return S.fail("[C] has no wrists to bind.")
			if(C.handcuffed)
				return S.fail("[C] is already bound.")
			var/obj/item/weapon/handcuffs/wizard/cuffs = new(C)
			C.handcuffed = cuffs
			C.update_inv_handcuffed()
		if("uncuff")
			if(!C.handcuffed)
				return S.fail("[C] is not bound.")
			C.drop_from_inventory(C.handcuffed)
	return "[name] [C]"

/decl/magic_word/magic_action/body/esurire
	name = "to starve"
	words = list("esurire")
	body_kind = "starve"
	cost_per_unit = 2

/decl/magic_word/magic_action/body/esurire/magic_cost(datum/magic_spell/S)
	return base_cost + spoken_amount(S, 5, 30) * cost_per_unit

/decl/magic_word/magic_action/body/satiare
	name = "to sate"
	words = list("satiare")
	body_kind = "feed"
	cosmetic = TRUE

/decl/magic_word/magic_action/body/purgare
	name = "to purge"
	words = list("purgare")
	body_kind = "purge"
	base_cost = 40

/decl/magic_word/magic_action/body/immunire
	name = "to cure sickness"
	words = list("immunire")
	body_kind = "cure"
	base_cost = 50
	cosmetic = TRUE

/decl/magic_word/magic_action/body/inebriare
	name = "to intoxicate"
	words = list("inebriare")
	body_kind = "drunk"
	cost_per_unit = 2

/decl/magic_word/magic_action/body/inebriare/magic_cost(datum/magic_spell/S)
	return base_cost + spoken_amount(S, 5, 30) * cost_per_unit

/decl/magic_word/magic_action/body/sopire
	name = "to sedate"
	words = list("sopire")
	body_kind = "sedate"
	base_cost = 40
	cost_per_unit = 4

/decl/magic_word/magic_action/body/sopire/magic_cost(datum/magic_spell/S)
	return base_cost + spoken_amount(S, 5, 30) * cost_per_unit

/decl/magic_word/magic_action/body/vincire
	name = "to bind"
	words = list("vincire")
	body_kind = "cuff"
	base_cost = 70

/decl/magic_word/magic_action/body/solvere
	name = "to unbind"
	words = list("solvere")
	body_kind = "uncuff"
	base_cost = 30
	cosmetic = TRUE
