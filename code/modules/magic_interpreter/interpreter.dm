var/global/datum/magic_interpreter/magic_interpreter = new

/datum/magic_value
	var/kind
	var/value
	var/word
	var/original

/datum/magic_incantation
	var/message
	var/mob/caster
	// Spells opened with a Latin word give fizzle feedback; alias-opened ones fail silently as normal speech.
	var/strong = FALSE
	var/list/clauses = list()

/datum/magic_spell
	var/message
	var/mob/caster
	var/strong = FALSE
	var/modifier
	var/target_mode
	var/inherits_target = FALSE
	var/member_kind
	var/member
	var/member_word
	var/member_original
	var/operator = "="
	var/list/values = list()
	var/failure

/datum/magic_spell/proc/fail(reason)
	failure = reason
	return null

/datum/magic_spell/proc/value_text()
	var/list/parts = list()
	for(var/datum/magic_value/V in values)
		parts += V.original
	return jointext(parts, " ")

/datum/magic_spell/proc/accepts_turf()
	var/decl/magic_word/W = member
	return istype(W) && W.accepts_turf

/datum/magic_interpreter
	var/list/denied_procs = list("new", "del", "destroy", "login", "logout", "topic")
	var/list/conjunctions = list("et", "atque")

/datum/magic_interpreter/proc/caster_tier(mob/living/M)
	if(!istype(M) || !M.client)
		return
	if(M.client.magic_casting && check_rights(R_FUN|R_DEBUG, FALSE, M.client))
		return "admin"
	if(M.mind && M.mind.spoken_magic_enabled && GLOB.logomancers.is_antagonist(M.mind))
		return "logomancer"

/datum/magic_interpreter/proc/can_attempt(mob/M)
	return !!caster_tier(M)

/datum/magic_interpreter/proc/try_cast(mob/living/caster, message)
	var/tier = caster_tier(caster)
	if(!tier)
		return
	var/datum/magic_incantation/I = parse(message, caster, tier != "admin")
	if(!I)
		return

	var/cost = incantation_cost(I)
	var/excess = 0
	if(cost)
		if(tier == "admin")
			log_admin("[key_name(caster)] spoken magic \"[message]\" would cost [cost] stamina.")
		else
			excess = pay_magic_cost(caster, cost)

	var/list/group = list()
	for(var/datum/magic_spell/S in I.clauses)
		if(S.failure)
			if(!group.len || execute(group))
				report_failure(S)
			group = list()
			break
		if(group.len && !S.inherits_target)
			if(!execute(group))
				group = list()
				break
			group = list()
		group += S
	if(group.len)
		execute(group)

	if(excess > 0)
		magic_overcast(caster, excess)

/datum/magic_interpreter/proc/report_failure(datum/magic_spell/S)
	if(!S.failure || !S.strong)
		return
	if(S.caster)
		to_chat(S.caster, "<span class='warning'>The spell fizzles: [S.failure]</span>")
	log_admin("[key_name(S.caster)] spoken magic fizzled \"[S.message]\": [S.failure]")

/datum/magic_interpreter/proc/tokenize(message)
	message = rhtml_decode(message)
	var/cleaned = ""
	for(var/i in 1 to length(message))
		var/c = copytext(message, i, i + 1)
		cleaned += findtext("abcdefghijklmnopqrstuvwxyz0123456789_#.+=-", c) ? c : " "
	. = list()
	for(var/token in splittext(cleaned, " "))
		while(length(token) > 1 && copytext(token, length(token)) == ".")
			token = copytext(token, 1, length(token))
		if(token && token != ".")
			. += token

/datum/magic_interpreter/proc/parse(message, mob/caster, restricted = FALSE)
	var/list/originals = tokenize(message)
	if(!originals.len)
		return

	var/datum/magic_incantation/I = new
	I.message = message
	I.caster = caster
	var/list/clause_words = list()
	var/list/clause_originals = list()
	var/datum/magic_spell/previous
	for(var/n in 1 to originals.len + 1)
		var/word = n <= originals.len ? lowertext(originals[n]) : null
		if(word && !(word in conjunctions))
			clause_words += word
			clause_originals += originals[n]
			continue
		if(clause_words.len || previous)
			var/datum/magic_spell/S = parse_clause(clause_words, clause_originals, previous, restricted)
			if(!S)
				return
			if(!previous)
				I.strong = S.strong
			S.strong = I.strong
			S.message = message
			S.caster = caster
			I.clauses += S
			previous = S
		clause_words = list()
		clause_originals = list()
	return I.clauses.len ? I : null

/datum/magic_interpreter/proc/parse_clause(list/words, list/originals, datum/magic_spell/previous, restricted = FALSE)
	var/datum/magic_spell/S = new
	if(!words.len)
		S.fail("The words trail off after a conjunction.")
		return S
	var/i = 1
	var/list/entry = magic_lookup(words[i])
	if(entry && entry[1] == "modifier")
		S.modifier = entry[2]
		S.strong = magic_is_latin(words[i])
		i++
		entry = i <= words.len ? magic_lookup(words[i]) : null

	if(entry && entry[1] == "target")
		S.target_mode = entry[2]
		S.strong = S.strong || magic_is_latin(words[i])
		i++
	else if(S.modifier)
		S.target_mode = "visus"
	else if(previous)
		S.modifier = previous.modifier
		S.target_mode = previous.target_mode
		S.inherits_target = TRUE
	else
		return

	if(i > words.len)
		S.fail("The words trail off before anything is named.")
		return S

	entry = magic_lookup(words[i])
	if(entry && (entry[1] == "property" || entry[1] == "action"))
		S.member_kind = entry[1]
		S.member = entry[2]
	else if(entry && magic_is_latin(words[i]))
		S.fail("'[originals[i]]' cannot be shaped that way.")
		return S
	else if(restricted)
		S.fail("'[originals[i]]' holds no power.")
		return S
	else
		S.member_kind = "raw"
	S.member_word = words[i]
	S.member_original = originals[i]
	i++

	if(i <= words.len)
		entry = magic_lookup(words[i])
		if(entry && entry[1] == "operator")
			S.operator = entry[2]
			i++

	while(i <= words.len)
		S.values += parse_value(words[i], originals[i])
		i++
	return S

/datum/magic_interpreter/proc/parse_value(word, original)
	var/static/regex/number = regex("^-?\\d+(\\.\\d+)?$")
	var/static/regex/hex_color = regex("^#(\[0-9a-f\]{3}|\[0-9a-f\]{6})$")
	var/datum/magic_value/V = new
	V.word = word
	V.original = original

	var/list/entry = magic_lookup(word)
	if(entry && entry[1] == "value")
		V.value = entry[2]
		V.kind = isnum(V.value) ? "num" : "color"
	else if(entry && entry[1] == "material")
		V.value = entry[2]
		V.kind = "material"
	else if(entry && entry[1] == "target")
		V.value = entry[2]
		V.kind = "target"
	else if(number.Find(word))
		V.value = text2num(word)
		V.kind = "num"
	else if(word == "true" || word == "false")
		V.value = word == "true"
		V.kind = "num"
	else if(word == "null" || word == "none")
		V.kind = "null"
	else if(hex_color.Find(word) || (word in magic_color_names))
		V.value = word
		V.kind = "color"
	else
		V.value = original
		V.kind = "text"
	return V

// Runs clauses that share one target resolution. Returns FALSE when the chain should stop.
/datum/magic_interpreter/proc/execute(list/group)
	var/datum/magic_spell/first = group[1]
	var/mob/caster = first.caster
	switch(first.modifier)
		if("area")
			var/list/targets = list()
			for(var/mob/living/M in view(world.view, caster))
				if(M != caster)
					targets += M
			for(var/datum/magic_spell/S in group)
				var/succeeded = FALSE
				var/quiet = FALSE
				for(var/mob/living/M in targets)
					if(apply_to(S, M, quiet))
						succeeded = TRUE
						quiet = TRUE
				if(succeeded)
					S.failure = null
					continue
				if(!S.failure)
					S.fail("No one nearby is touched by the words.")
				report_failure(S)
				return FALSE
			return TRUE
		if("project")
			var/atom/aim = magic_resolve_target(first.target_mode, caster, first.accepts_turf())
			if(!aim)
				aim = get_ranged_target_turf(caster, caster.dir, world.view)
			if(get_turf(aim) == get_turf(caster))
				return apply_group(group, aim)
			var/obj/item/projectile/magic_bolt/P = new(get_turf(caster))
			P.spells = group.Copy()
			P.firer = caster
			log_and_message_admins("launched a spoken magic bolt \"[first.message]\" toward [aim]", caster)
			magic_cast_effect(caster)
			P.launch(aim)
			return TRUE
		else
			var/atom/target = magic_resolve_target(first.target_mode, caster, first.accepts_turf())
			if(!target)
				first.fail("There is nothing there to bind the words to.")
				report_failure(first)
				return FALSE
			return apply_group(group, target)

/datum/magic_interpreter/proc/apply_group(list/group, atom/target)
	for(var/datum/magic_spell/S in group)
		S.failure = null
		if(!apply_to(S, target))
			report_failure(S)
			return FALSE
	return TRUE

/datum/magic_interpreter/proc/apply_to(datum/magic_spell/S, atom/target, quiet = FALSE)
	if(!S.caster || QDELETED(S.caster))
		return S.fail("The caster is gone.")
	if(!target || QDELETED(target))
		return S.fail("The words find nothing to hold.")
	if(isturf(target))
		if(!S.accepts_turf())
			return S.fail("The words find nothing to hold.")
	else if(!(ismob(target) || isobj(target)))
		return S.fail("The words find nothing to hold.")
	for(var/forbidden in forbidden_varedit_object_types())
		if(istype(target, forbidden))
			return S.fail("[target] is beyond the reach of words.")

	var/summary
	var/cosmetic = FALSE
	switch(S.member_kind)
		if("property")
			var/decl/magic_word/magic_property/P = S.member
			summary = apply_property(S, P, target)
			cosmetic = P.cosmetic
		if("action")
			var/decl/magic_word/magic_action/A = S.member
			summary = A.invoke(S, target, S.caster)
			cosmetic = A.cosmetic
		if("raw")
			summary = apply_raw(S, target)
	if(!summary)
		return

	if(!QDELETED(target))
		magic_cast_effect(target, !quiet)
	log_and_message_admins("spoke magic \"[S.message]\": [summary]", S.caster)
	if(!cosmetic && ismob(target) && target != S.caster)
		admin_attack_log(S.caster, target, "Spoken magic: [summary]", "Was targeted by spoken magic: [summary]", "used spoken magic ([summary]) on")
	return summary

/datum/magic_interpreter/proc/apply_property(datum/magic_spell/S, decl/magic_word/magic_property/P, atom/target)
	if(!P.accepts(target))
		return S.fail("[target] has no [P.name].")
	if(!S.values.len)
		return S.fail("No value was spoken for [P.name].")
	var/datum/magic_value/V = S.values[1]
	var/new_value
	switch(P.value_kind)
		if("num")
			if(V.kind != "num")
				return S.fail("[P.name] needs a number, not '[V.original]'.")
			var/current = P.get_value(target)
			switch(S.operator)
				if("+")
					new_value = current + V.value
				if("-")
					new_value = current - V.value
				else
					new_value = V.value
			new_value = clamp(new_value, P.min_value, P.max_value)
		if("text")
			if(S.operator != "=")
				return S.fail("[P.name] can only be changed outright.")
			if(V.kind == "num" && S.values.len == 1)
				return S.fail("[P.name] needs words, not a number.")
			new_value = sanitize(copytext(S.value_text(), 1, P.max_length), 0)
			if(!new_value)
				return S.fail("The new [P.name] is empty.")
		if("color")
			if(S.operator != "=")
				return S.fail("[P.name] can only be changed outright.")
			if(V.kind == "color")
				new_value = V.value
			else if(V.kind != "null" && !(V.kind == "num" && V.value == 0))
				return S.fail("'[V.original]' is not a color.")
	P.set_value(target, new_value)
	return "set [P.name] of [target] to [isnull(new_value) ? "null" : new_value]"

/datum/magic_interpreter/proc/apply_raw(datum/magic_spell/S, atom/target)
	var/var_name = find_var(target, S.member_original, S.member_word)
	if(var_name)
		return apply_raw_var(S, target, var_name)
	var/proc_name = find_proc(target, S.member_original, S.member_word)
	if(proc_name)
		return apply_raw_proc(S, target, proc_name)
	return S.fail("Nothing called '[S.member_original]' answers on [target].")

/datum/magic_interpreter/proc/find_var(datum/target, original, word)
	if(original in target.vars)
		return original
	for(var/V in target.vars)
		if(lowertext(V) == word)
			return V

/datum/magic_interpreter/proc/find_proc(datum/target, original, word)
	if(hascall(target, original))
		return original
	if(hascall(target, word))
		return word

/datum/magic_interpreter/proc/apply_raw_var(datum/magic_spell/S, datum/target, var_name)
	if(!target.may_edit_var(S.caster, var_name))
		return S.fail("[var_name] of [target] resists change.")
	if(!S.values.len)
		return S.fail("No value was spoken for [var_name].")
	var/datum/magic_value/V = S.values[1]
	var/current = target.vars[var_name]
	var/new_value

	if(isnum(current) || (isnull(current) && V.kind == "num"))
		if(V.kind == "null" && S.operator == "=")
			new_value = null
		else if(V.kind != "num")
			return S.fail("[var_name] needs a number, not '[V.original]'.")
		else
			switch(S.operator)
				if("+")
					new_value = (current || 0) + V.value
				if("-")
					new_value = (current || 0) - V.value
				else
					new_value = V.value
	else if(istext(current) || isnull(current))
		if(S.operator != "=")
			return S.fail("[var_name] can only be changed outright.")
		if(V.kind != "null")
			new_value = sanitize(copytext(S.value_text(), 1, MAX_MESSAGE_LEN), 0)
	else
		return S.fail("[var_name] is too intricate to shape with words.")

	var/client/C = S.caster.client
	if(!C || !C.special_set_vv_var(target, var_name, new_value, C))
		target.set_variable_value(var_name, new_value)
	if(istype(target, /atom))
		var/atom/A = target
		A.update_icon()
	return "set var [var_name] of [target] from [isnull(current) ? "null" : current] to [isnull(target.vars[var_name]) ? "null" : target.vars[var_name]]"

/datum/magic_interpreter/proc/apply_raw_proc(datum/magic_spell/S, datum/target, proc_name)
	if(!check_rights(R_DEBUG, FALSE, S.caster.client))
		return S.fail("Only those versed in debugging may invoke [proc_name].")
	if(config.debugparanoid && !check_rights(R_ADMIN, FALSE, S.caster.client))
		return S.fail("Only those versed in debugging may invoke [proc_name].")
	if(lowertext(proc_name) in denied_procs)
		return S.fail("[proc_name] is forbidden.")

	var/list/arguments = list()
	for(var/datum/magic_value/V in S.values)
		switch(V.kind)
			if("material")
				arguments += V.word
			if("null")
				arguments.len++
			if("target")
				arguments.len++
				arguments[arguments.len] = magic_resolve_target(V.value, S.caster, TRUE)
			else
				arguments += V.value
	log_admin("[key_name(S.caster)] called [target]'s [proc_name]() via spoken magic with [arguments.len ? "the arguments [list2params(arguments)]" : "no arguments"].")
	var/result = call(target, proc_name)(arglist(arguments))
	return "called [proc_name]([jointext(arguments, ", ")]) on [target], returning [isnull(result) ? "null" : result]"
