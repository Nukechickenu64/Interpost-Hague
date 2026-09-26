GLOBAL_DATUM_INIT(epicureans, /datum/antagonist/epicurean, new)

/datum/antagonist/epicurean
	id = "epicurean"
	role_text = "Epicurean"
	role_text_plural = "Epicureans"
	feedback_tag = "epicurean_objective"
	protected_jobs = list(/datum/job/captain, /datum/job/hos, /datum/job/rd)
	blacklisted_jobs = list(/datum/job/ai)
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE
	hard_cap = 2
	hard_cap_round = 2
	initial_spawn_req = 1
	initial_spawn_target = 1
	antaghud_indicator = "hudtraitor"
	welcome_text = "The crew are your pantry. Harvest only from fresh cadavers, prepare a convincing feast, and leave no trace of your appetite."

/datum/antagonist/epicurean/create_objectives(var/datum/mind/epicurean)
	if(!..())
		return

	var/datum/objective/epicurean/feast/feast_objective = new
	feast_objective.owner = epicurean
	epicurean.objectives += feast_objective

	var/datum/objective/epicurean/trophies/trophy_objective = new
	trophy_objective.owner = epicurean
	epicurean.objectives += trophy_objective

	var/datum/objective/escape/escape_objective = new
	escape_objective.owner = epicurean
	epicurean.objectives += escape_objective

/datum/antagonist/epicurean/equip(var/mob/living/carbon/human/player)
	if(!..())
		return 0
	player.put_in_hands(new /obj/item/weapon/epicurean/harvesting_scalpel(player))
	player.put_in_hands(new /obj/item/weapon/epicurean/prion_starter(player))
	player.put_in_hands(new /obj/item/weapon/epicurean/catalyst_starter(player))
	return 1

/datum/mind
	var/list/epicurean_trophies

/datum/mind/proc/has_epicurean_trophy(trophy_type)
	return epicurean_trophies && (trophy_type in epicurean_trophies)

/var/global/list/epicurean_infected = list()

/datum/objective/epicurean
	var/progress = 0

/datum/objective/epicurean/feast
	explanation_text = "Serve a multi-course human feast to at least three unsuspecting crew members."

/datum/objective/epicurean/feast/check_completion()
	return progress >= 3

/datum/objective/epicurean/trophies
	explanation_text = "Harvest and consume three distinct department-head trophy glands."

/datum/objective/epicurean/trophies/check_completion()
	return progress >= 3

/obj/item/weapon/epicurean
	name = "Epicurean implement"
	desc = "A discreet tool for an exceptionally discerning cook."
	icon = 'icons/obj/kitchen.dmi'
	w_class = ITEM_SIZE_SMALL

/obj/item/weapon/epicurean/harvesting_scalpel
	name = "gourmet scalpel"
	desc = "A surgical scalpel with measurements for precise, clean trophy harvesting."
	icon_state = "knife"

/obj/item/weapon/epicurean/harvesting_scalpel/attack(mob/living/carbon/human/target, mob/living/carbon/human/user)
	if(!user?.mind || user.mind.special_role != "Epicurean")
		return ..()
	if(target.stat != DEAD || !target.timeofdeath || world.time - target.timeofdeath > 5 MINUTES)
		to_chat(user, "<span class='warning'>Only a fresh cadaver will yield a suitable trophy.</span>")
		return
	var/trophy_type
	var/organ_name
	if(target.mind && (target.mind.assigned_role in list("Captain", "Head of Personnel", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer")))
		trophy_type = "command_brain"
		organ_name = "Command Brain"
	else if(target.mind && (target.mind.assigned_role in list("Head of Security", "Warden", "Detective", "Security Officer")))
		trophy_type = "security_heart"
		organ_name = "Security Heart"
	else if((target.mind && target.mind.assigned_role == "Geneticist") || target.species?.name == "Plasmaman")
		trophy_type = "resilience_liver"
		organ_name = "Geneticist/Plasmaman Liver"
	if(!trophy_type)
		to_chat(user, "<span class='warning'>This cadaver has no trophy gland you can use.</span>")
		return
	if(user.mind.has_epicurean_trophy(trophy_type))
		to_chat(user, "<span class='notice'>You have already perfected this course.</span>")
		return
	var/obj/item/weapon/epicurean/trophy/trophy = new(user, trophy_type, organ_name)
	user.put_in_hands(trophy)
	user.visible_message("<span class='warning'>[user] makes a precise incision in [target].</span>", "<span class='notice'>You extract a [organ_name] from [target].</span>")

/obj/item/weapon/epicurean/trophy
	name = "trophy gland"
	var/trophy_type
	var/organ_name

/obj/item/weapon/epicurean/trophy/New(loc, new_trophy_type, new_organ_name)
	..(loc)
	trophy_type = new_trophy_type
	organ_name = new_organ_name
	name = "[organ_name] trophy"

/obj/item/weapon/epicurean/trophy/attack_self(mob/user)
	if(!ishuman(user) || !user.mind || user.mind.special_role != "Epicurean")
		to_chat(user, "<span class='warning'>The gland is inedible to an unrefined palate.</span>")
		return
	var/mob/living/carbon/human/epicurean = user
	if(epicurean.mind.has_epicurean_trophy(trophy_type))
		to_chat(user, "<span class='notice'>You have already consumed this kind of trophy.</span>")
		return
	if(!epicurean.mind.epicurean_trophies)
		epicurean.mind.epicurean_trophies = list()
	epicurean.mind.epicurean_trophies += trophy_type
	to_chat(user, "<span class='notice'>You consume the [organ_name]. Its acquired instincts settle into your flesh.</span>")
	if(trophy_type == "command_brain")
		epicurean.put_in_hands(new /obj/item/device/encryptionkey/heads/ai_integrated(epicurean))
		to_chat(user, "<span class='notice'>A stolen chorus fills your mind. An all-department encryption key takes physical form in your hand.</span>")
	else if(trophy_type == "security_heart")
		epicurean.adjustStaminaLoss(-50)
		to_chat(user, "<span class='notice'>Your pulse steadies. Exhaustion and pain now feed an adrenal reserve.</span>")
	else if(trophy_type == "resilience_liver")
		epicurean.setToxLoss(0)
		epicurean.radiation = 0
		to_chat(user, "<span class='notice'>Your blood runs clean and hostile atmospheres lose their bite.</span>")
	for(var/datum/objective/epicurean/trophies/trophy_objective in epicurean.mind.objectives)
		trophy_objective.progress = epicurean.mind.epicurean_trophies.len
	qdel(src)

/obj/item/weapon/epicurean/prion_starter
	name = "prion starter"
	desc = "A flavorless culture that turns prepared food into a latent infectious course."

/obj/item/weapon/epicurean/prion_starter/afterattack(obj/item/weapon/reagent_containers/food/snacks/target, mob/user, proximity)
	if(!proximity)
		return
	target.reagents.add_reagent(/datum/reagent/epicurean_prion, 5)
	to_chat(user, "<span class='notice'>You fold the latent prion into [target].</span>")
	qdel(src)

/obj/item/weapon/epicurean/catalyst_starter
	name = "catalyst starter"
	desc = "A bitter concentrate that awakens the latent prion in every infected diner."

/obj/item/weapon/epicurean/catalyst_starter/afterattack(obj/item/weapon/reagent_containers/food/snacks/target, mob/user, proximity)
	if(!proximity)
		return
	target.reagents.add_reagent(/datum/reagent/epicurean_catalyst, 5)
	to_chat(user, "<span class='notice'>You fold the catalyst into [target].</span>")
	qdel(src)

/datum/reagent/epicurean_prion
	name = "Latent Prion"
	description = "A dormant human-protein prion. A mass spectrometer can distinguish it from ordinary food additives."
	taste_description = "richness"
	color = "#7c1b1b"
	metabolism = REM * 0.1
	scannable = 1

/datum/reagent/epicurean_prion/affect_ingest(var/mob/living/carbon/human/target, var/alien, var/removed)
	if(target in epicurean_infected)
		return
	epicurean_infected += target
	to_chat(target, "<span class='notice'>That was surprisingly rich.</span>")
	for(var/datum/mind/epicurean in SSticker.minds)
		if(epicurean.special_role != "Epicurean")
			continue
		for(var/datum/objective/epicurean/feast/feast_objective in epicurean.objectives)
			feast_objective.progress = epicurean_infected.len

/datum/reagent/epicurean_catalyst
	name = "Prion Catalyst"
	description = "An activator that causes latent prions to produce violent flesh cravings."
	taste_description = "metallic bitterness"
	color = "#4d0010"
	metabolism = REM * 0.5
	scannable = 1

/datum/reagent/epicurean_catalyst/affect_ingest(var/mob/living/carbon/human/target, var/alien, var/removed)
	for(var/mob/living/carbon/human/infected in epicurean_infected.Copy())
		if(QDELETED(infected) || infected.stat == DEAD)
			epicurean_infected -= infected
			continue
		infected.hallucination(35, 20)
		infected.adjustStaminaLoss(25)
		infected.make_jittery(10)
		to_chat(infected, "<span class='danger'>You need to bite someone. Now.</span>")