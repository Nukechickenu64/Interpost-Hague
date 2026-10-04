/decl/magic_word
	var/base_cost = 10
	var/cost_per_unit = 0

/decl/magic_word/proc/magic_cost(datum/magic_spell/S)
	. = base_cost
	for(var/datum/magic_value/V in S.values)
		if(V.kind == "num")
			. += abs(V.value) * cost_per_unit

/datum/magic_interpreter/proc/clause_cost(datum/magic_spell/S)
	var/decl/magic_word/W = S.member
	if(!istype(W))
		return 0
	. = W.magic_cost(S)
	if(S.target_mode == "visus")
		. *= 1.5
	if(S.member_kind == "property" && S.operator == "=")
		. *= 1.5
	switch(S.modifier)
		if("project")
			. *= 1.25
		if("area")
			. *= 3

// Only clauses before the first parse failure are spoken in full and paid for.
/datum/magic_interpreter/proc/incantation_cost(datum/magic_incantation/I)
	var/total = 0
	var/clauses = 0
	for(var/datum/magic_spell/S in I.clauses)
		if(S.failure)
			break
		total += clause_cost(S)
		clauses++
	if(clauses > 1)
		total += 5 * (clauses - 1)
	return round(total)

// Returns how far the cost overran the caster's remaining stamina.
/datum/magic_interpreter/proc/pay_magic_cost(mob/living/caster, cost)
	var/budget = max(STAMINA_EXHAUST - caster.getStaminaLoss(), 0)
	caster.adjustStaminaLoss(cost)
	if(cost > budget)
		return cost - budget
	var/strain = caster.getStaminaLoss() / STAMINA_EXHAUST
	if(strain >= 0.8)
		to_chat(caster, "<span class='warning'>The words drag the breath out of you. You are close to your limit.</span>")
	else if(strain >= 0.5)
		to_chat(caster, "<span class='notice'>Speaking the words leaves you winded.</span>")
	return 0

/datum/magic_interpreter/proc/magic_overcast(mob/living/caster, excess)
	if(QDELETED(caster))
		return
	caster.Exhaust()
	caster.adjustBrainLoss(excess * 0.1)
	caster.adjustBruteLoss(excess * 0.25)
	caster.updatehealth()
	if(excess >= 100)
		to_chat(caster, "<span class='danger'>The words tear through you. Blood pours from your nose and your thoughts scatter.</span>")
	else
		to_chat(caster, "<span class='danger'>You spoke beyond your strength. Something inside you gives way.</span>")
	log_and_message_admins("overcast spoken magic by [excess] stamina.", caster)
