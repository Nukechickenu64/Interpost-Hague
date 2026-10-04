GLOBAL_DATUM_INIT(logomancers, /datum/antagonist/logomancer, new)

/datum/mind
	var/spoken_magic_enabled = FALSE

/datum/antagonist/logomancer
	id = MODE_LOGOMANCER
	role_text = "Logomancer"
	role_text_plural = "Logomancers"
	welcome_text = "Words you never learned surface in your mind, and the world bends when you speak them. Every word costs you breath and strength; speak beyond your endurance and it will cost you far more."
	antaghud_indicator = "hudwizard"
	protected_jobs = list(/datum/job/officer, /datum/job/warden, /datum/job/detective, /datum/job/captain, /datum/job/lawyer, /datum/job/hos)
	flags = ANTAG_SUSPICIOUS
	hard_cap = 2
	hard_cap_round = 2
	initial_spawn_req = 1
	initial_spawn_target = 1
	faction = "logomancer"

/datum/antagonist/logomancer/create_objectives(datum/mind/player)
	if(!..())
		return
	var/kill = FALSE
	var/steal = FALSE
	switch(rand(1, 3))
		if(1)
			kill = TRUE
		if(2)
			steal = TRUE
		else
			kill = TRUE
			steal = TRUE
	if(kill)
		var/datum/objective/assassinate/kill_objective = new
		kill_objective.owner = player
		kill_objective.find_target()
		player.objectives |= kill_objective
	if(steal)
		var/datum/objective/steal/steal_objective = new
		steal_objective.owner = player
		steal_objective.find_target()
		player.objectives |= steal_objective
	var/datum/objective/survive/survive_objective = new
	survive_objective.owner = player
	player.objectives |= survive_objective

/datum/antagonist/logomancer/equip(mob/living/carbon/human/player)
	return istype(player)

/datum/antagonist/logomancer/greet(datum/mind/player)
	if(!..())
		return
	player.spoken_magic_enabled = TRUE
	player.current.verbs |= /mob/living/proc/toggle_spoken_magic_ic
	player.store_memory(logomancer_word_memory())
	to_chat(player.current, "<span class='notice'>The words are written in your notes.</span>")
	return 1

/datum/antagonist/logomancer/remove_antagonist(datum/mind/player, show_message, implanted)
	. = ..()
	if(. && player)
		player.spoken_magic_enabled = FALSE
		if(player.current)
			player.current.verbs -= /mob/living/proc/toggle_spoken_magic_ic

/proc/logomancer_word_memory()
	if(!magic_dictionary)
		build_magic_dictionary()
	var/list/lines = list("<b>The words:</b>")
	for(var/word in magic_dictionary)
		lines += "[word] - [magic_word_gloss(magic_dictionary[word])]"
	lines += "et, atque - and"
	return jointext(lines, "<br>")

/proc/magic_word_gloss(list/entry)
	var/payload = entry[2]
	switch(entry[1])
		if("target")
			switch(payload)
				if("self")
					return "oneself"
				if("held")
					return "what is in hand"
				if("visus")
					return "what is seen"
		if("modifier")
			return payload == "project" ? "to cast outward" : "all around"
		if("operator")
			switch(payload)
				if("+")
					return "more"
				if("-")
					return "less"
			return "to become"
		if("value")
			return isnum(payload) ? "[payload]" : "a color"
		if("material")
			return payload
	if(istype(payload, /decl/magic_word))
		var/decl/magic_word/D = payload
		return D.name
	return "?"

/mob/living/proc/toggle_spoken_magic_ic()
	set name = "Toggle Spoken Words"
	set category = "IC"

	if(!mind || !GLOB.logomancers.is_antagonist(mind))
		verbs -= /mob/living/proc/toggle_spoken_magic_ic
		return
	mind.spoken_magic_enabled = !mind.spoken_magic_enabled
	to_chat(src, "<span class='notice'>You [mind.spoken_magic_enabled ? "let the words flow into your speech" : "hold the words back"].</span>")
