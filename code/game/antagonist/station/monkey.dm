// Notes towards a monkey mode to reduce snowflakes for downstream.

/datum/antagonist/monkey
	role_text = "Rabid Monkey"
	role_text_plural = "Rabid Monkeys"
	mob_type = /mob/living/carbon/monkey
	id = MODE_MONKEY
	flags = ANTAG_OVERRIDE_JOB | ANTAG_OVERRIDE_MOB

/datum/antagonist/monkey/apply(var/datum/mind/player)
	if(!player || !player.current)
		return 0

	var/mob/living/carbon/monkey/M = player.current
	for(var/datum/disease/D in M.viruses)
		if(istype(D, /datum/disease/jungle_fever))
			if(ticker && ticker.mode && ticker.mode.config_tag == "monkey")
				return 2
			return 1
	return 0