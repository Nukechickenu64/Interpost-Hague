/datum/spawnpoint/cryo/proc/give_effect(mob/living/carbon/human/victim)
	var/message = ""
	if(prob(40)) //starvation
		message += "<span class='warning'>It seems like you forgot to eat before getting 'buried' in the chamber... </span>"
		victim.set_nutrition(rand(0,200))
		victim.set_thirst(rand(0,200))
	if(prob(25)) //stutterting and jittering (because of cold?)
		message += "<span class='warning'>This cold is making me jittery... </span>"
		victim.make_jittery(120)
		victim.stuttering = 20
	if(prob(15)) //vomit
		message += "<span class='warning'>I want to vomit... </span>"
		victim.vomit()
	if(!message)
		message += "<span class='notice'>It seems like there weren't any bad effects today...but I couldn't sleep properly anyway. </span>"
	else
		message += "<span class='warning'>Can't even sleep or live properly here... </span>"
	to_chat(victim, "[message]")
	return TRUE

/datum/spawnpoint/cryocaptain/proc/give_effect(mob/living/carbon/human/victim)
	var/message = ""
	if(prob(40)) //starvation
		message += "<span class='warning'>It seems like I forgot to eat before getting 'buried' in the chamber...[rand(20,60)] years of working Captain and still no brain. </span>"
		victim.set_nutrition(rand(0,200))
		victim.set_thirst(rand(0,200))
	if(prob(25)) //stutterting and jittering (because of cold?)
		message += "<span class='warning'>This cold is making me jittery... </span>"
		victim.make_jittery(120)
		victim.stuttering = 20
	if(prob(15)) //vomit
		message += "<span class='warning'>I want to vomit... </span>"
		victim.vomit()
	if(!message)
		message += "<span class='notice'>It seems like there weren't any bad effects today...but I couldn't sleep properly anyway. </span>"
	else
		message += "<span class='warning'>Can't even sleep or live properly here... </span>"
	to_chat(victim, "[message]")
	return TRUE