var/global/datum/antagonist/pony_changeling/mlp_hive = new

/datum/antagonist/pony_changeling
	id = "mlp_changeling"
	role_text = "Changeling"
	role_text_plural = "Changelings"
	feedback_tag = "mlp_changeling_objective"
	protected_jobs = list(/datum/job/captain, /datum/job/hos, /datum/job/cmo)
	blacklisted_jobs = list(/datum/job/ai)
	flags = 0x320
	hard_cap = 2
	hard_cap_round = 2
	initial_spawn_req = 1
	initial_spawn_target = 1
	antaghud_indicator = "hudchangeling"
	faction = "changeling"
	welcome_text = "You are a changeling from a hidden hive. Wear the faces you steal, feed on the crew's love, and keep your true nature hidden. Use the Changeling abilities to absorb DNA and transform. Love is your strength; without it, your disguise and body will fail."

/datum/antagonist/pony_changeling/create_objectives(var/datum/mind/changeling_mind)
	if(!..())
		return

	var/datum/objective/absorb/absorb_objective = new
	absorb_objective.owner = changeling_mind
	absorb_objective.gen_amount_goal(2, 3)
	changeling_mind.objectives += absorb_objective

	var/datum/objective/mlp_changeling/love/love_objective = new
	love_objective.owner = changeling_mind
	changeling_mind.objectives += love_objective

	var/datum/objective/escape/escape_objective = new
	escape_objective.owner = changeling_mind
	changeling_mind.objectives += escape_objective

/datum/antagonist/pony_changeling/create_antagonist(var/datum/mind/target, var/move, var/gag_announcement, var/preserve_appearance)
	. = ..()
	if(. && istype(target.current, /mob/living/carbon/human))
		var/mob/living/carbon/human/changeling = target.current
		var/datum/absorbed_dna/starting_disguise = new(changeling.real_name, changeling.dna.Clone(), changeling.species?.name, changeling.languages.Copy())
		target.mlp_changeling = new
		target.mlp_changeling.original_species = changeling.species?.name
		changeling.set_species("Shadow", 1)
		changeling.make_changeling()
		changeling.absorbDNA(starting_disguise)
		changeling.handle_changeling_transform(starting_disguise)
		changeling.verbs += /mob/living/carbon/human/proc/mlp_feed_on_love
		to_chat(changeling, "<span class='notice'>Your love reserves begin at [target.mlp_changeling.love]. Feed carefully: hunger makes disguise difficult.</span>")

/datum/antagonist/pony_changeling/remove_antagonist(var/datum/mind/player, var/show_message, var/implanted)
	. = ..()
	if(. && istype(player.current, /mob/living/carbon/human))
		var/mob/living/carbon/human/changeling = player.current
		changeling.remove_changeling_powers()
		changeling.verbs -= /mob/living/carbon/human/proc/mlp_feed_on_love
		if(player.mlp_changeling?.original_species)
			changeling.set_species(player.mlp_changeling.original_species, 1)
	player.mlp_changeling = null

/datum/antagonist/pony_changeling/tick()
	for(var/datum/mind/changeling_mind in current_antagonists)
		if(!changeling_mind?.current || !changeling_mind.mlp_changeling)
			continue
		changeling_mind.mlp_changeling.process(changeling_mind.current)
	return 1

/datum/mind
	var/datum/pony_changeling/mlp_changeling

/datum/pony_changeling
	var/original_species
	var/love = 50
	var/max_love = 100
	var/love_decay = 0.05
	var/last_low_love_warning = 0

/datum/pony_changeling/proc/process(var/mob/living/carbon/human/changeling)
	if(!changeling || changeling.stat > 0)
		return
	love = max(0, love - love_decay)
	if(love <= 0)
		changeling.adjustToxLoss(1)
		if(world.time >= last_low_love_warning)
			to_chat(changeling, "<span class='danger'>Your borrowed shape feels hollow. You need love.</span>")
			last_low_love_warning = world.time + 600
	else if(love <= 15 && world.time >= last_low_love_warning)
		to_chat(changeling, "<span class='warning'>Your love reserves are nearly empty.</span>")
		last_low_love_warning = world.time + 600

/datum/pony_changeling/proc/add_love(var/amount, var/mob/living/carbon/human/changeling)
	love = min(max_love, love + amount)
	if(changeling && amount > 0)
		to_chat(changeling, "<span class='notice'>Warmth gathers beneath your borrowed skin. Love: [round(love)]/[max_love].</span>")

/mob/living/carbon/human/proc/mlp_feed_on_love()
	set category = "Changeling"
	set name = "Feed on Love"
	set desc = "Drain emotional warmth from a nearby living human without killing them."

	if(!mind?.mlp_changeling || incapacitated())
		return
	var/mob/living/carbon/human/target = input(src, "Choose someone to feed from.", "Feed on Love") as null|anything in view(1, src)
	if(!istype(target) || target == src || target.stat > 0 || !Adjacent(target))
		return
	if(!do_after(src, 30, target, progress = 0))
		return
	if(!Adjacent(target) || target.stat > 0 || !target.mind)
		return
	mind.mlp_changeling.add_love(20, src)
	target.adjustStaminaLoss(10)
	visible_message("<span class='warning'>[src] draws a shimmering warmth from [target].</span>")
	to_chat(target, "<span class='notice'>A sudden emptiness settles over you, as if a joyful memory has gone cold.</span>")

/datum/objective/mlp_changeling

/datum/objective/mlp_changeling/love
	explanation_text = "Keep at least 60 units of love in your reserves when the escape shuttle arrives."

/datum/objective/mlp_changeling/love/check_completion()
	return owner?.current && owner.mlp_changeling && owner.mlp_changeling.love >= 60
