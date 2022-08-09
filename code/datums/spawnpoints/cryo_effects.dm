/datum/spawnpoint/cryo/proc/give_effect(mob/living/carbon/human/victim)
	var/message = ""
	if(prob(20)) //starvation
		message += "<span class='warning'>It seems like you forgot to eat before getting 'buried' in the chamber... </span>"
		victim.nutrition = rand(0,200)
		victim.thirst = rand(0,200)
	if(prob(15)) //stutterting and jittering (because of cold?)
		message += "<span class='warning'>This cold is making me jittery... </span>"
		victim.make_jittery(120)
		victim.stuttering = 20
	if(prob(5)) //vomit
		message += "<span class='warning'>I want to vomit... </span>"
		victim.vomit()
	if(!message)
		message += "<span class='notice'>It seems like there weren't any bad effects today...but I couldn't sleep properly anyway. </span>"
	else
		message += "<span class='warning'>Can't even sleep or live properly here... </span>"
	victim.add_event("cryo", /datum/happiness_event/cryo)
	to_chat(victim, message)
	return TRUE