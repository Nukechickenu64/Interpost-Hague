GLOBAL_DATUM_INIT(heretics, /datum/antagonist/heretic, new)

/proc/get_heretic(mob/player)
	if(!player?.mind || !GLOB.heretics || !(player.mind in GLOB.heretics.current_antagonists))
		return null
	return GLOB.heretics.devotees[player.mind]

/datum/antagonist/heretic
	id = MODE_HERETIC
	role_text = "Heretic"
	role_text_plural = "Heretics"
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDOM_EXCEPTED
	faction = "heretic"
	feedback_tag = "heretic_objective"
	antaghud_indicator = "hudcultist"
	porco_tab = "Mansus"
	porco_actions = list(
		list("heretic_knowledge", "Forbidden Knowledge", /mob/living/proc/heretic_knowledge),
		list("heretic_offer", "Offer a Sacrifice", /mob/living/proc/heretic_offer),
		list("heretic_path_power", "Invoke a Path", /mob/living/proc/heretic_path_power),
		list("heretic_summon_hound", "Summon Spectral Hound", /mob/living/proc/heretic_summon_hound)
	)
	welcome_text = "The Mansus has opened your eyes. Your pursuit of Forbidden Knowledge is solitary: other heretics are not obliged to serve you."
	blacklisted_jobs = list(/datum/job/ai)
	var/list/devotees = list()

/datum/antagonist/heretic/can_become_antag(datum/mind/player, ignore_role)
	if(!player || !ishuman(player.current) || get_cult(player.current))
		return FALSE
	return ..()

/datum/antagonist/heretic/get_porco_actions(mob/living/carbon/human/user)
	if(!user || !user.mind || !user.mind.has_active_antagonist(src))
		return list()
	var/list/available_actions = list()
	for(var/list/action in porco_actions)
		if(action[3] in user.verbs)
			available_actions += list(action)
	return available_actions

/datum/antagonist/heretic/equip(mob/living/carbon/human/player)
	if(!..())
		return FALSE
	var/obj/item/weapon/material/knife/ritual/blade = new(get_turf(player))
	blade.name = "eldritch ritual knife"
	blade.desc = "A narrow blade scored with symbols that seem to shift when you look away."
	var/list/slots = list(slot_in_backpack, slot_l_store, slot_r_store, slot_l_hand, slot_r_hand)
	for(var/slot in slots)
		player.equip_to_slot(blade, slot)
		if(blade.loc == player)
			return TRUE
	qdel(blade)
	return TRUE

/datum/antagonist/heretic/add_antagonist(datum/mind/player, ignore_role, do_not_equip, move_to_spawn, do_not_announce, preserve_appearance)
	if(!player || devotees[player] || !can_become_antag(player, ignore_role))
		return FALSE
	var/datum/heretic_devotee/devotee = new(player)
	devotees[player] = devotee
	. = ..()
	if(!.)
		devotees -= player
		qdel(devotee)
		return
	var/datum/religion/previous_faith = GLOB.all_religions[devotee.previous_religion]
	if(previous_faith)
		previous_faith.followers -= player.name
	player.religion = HERETIC_RELIGION
	player.current.religion = HERETIC_RELIGION
	var/datum/religion/faith = GLOB.all_religions[HERETIC_RELIGION]
	if(faith)
		faith.followers |= player.name
	player.current.update_religion_magic()
	devotee.bind_body(player.current)

/datum/antagonist/heretic/remove_antagonist(datum/mind/player, show_message, implanted)
	var/datum/heretic_devotee/devotee = devotees[player]
	. = ..()
	if(!. || !devotee)
		return
	devotee.unbind_body(player.current)
	for(var/mob/living/simple_animal/summoned in devotee.summons)
		qdel(summoned)
	player.religion = devotee.previous_religion
	var/datum/religion/faith = GLOB.all_religions[HERETIC_RELIGION]
	if(faith)
		faith.followers -= player.name
	var/datum/religion/restored_faith = GLOB.all_religions[player.religion]
	if(restored_faith)
		restored_faith.followers |= player.name
	if(player.current)
		player.current.religion = player.religion
		player.current.faction = devotee.previous_faction
		player.current.update_religion_magic()
	devotees -= player
	qdel(devotee)

/datum/heretic_devotee
	var/datum/mind/owner
	var/previous_religion
	var/previous_faction
	var/knowledge_points = 1
	var/knowledge_gained = 1
	var/list/researched_knowledge = list()
	var/list/sacrifice_targets = list()
	var/list/sacrificed = list()
	var/list/summons = list()
	var/total_sacrifices = 0
	var/high_value_sacrifices = 0
	var/ascended = FALSE
	var/next_influence = 0
	var/next_power_use = 0

/datum/heretic_devotee/New(datum/mind/player)
	..()
	owner = player
	previous_religion = player.current.religion ? player.current.religion : LEGAL_RELIGION
	previous_faction = player.current.faction
	next_influence = world.time + 20 MINUTES

/datum/heretic_devotee/proc/bind_body(mob/living/body)
	if(body)
		body.verbs |= /mob/living/proc/heretic_knowledge
		body.verbs |= /mob/living/proc/heretic_offer
		if(researched_knowledge.len)
			body.verbs |= /mob/living/proc/heretic_path_power
		if("Flesh" in researched_knowledge)
			body.verbs |= /mob/living/proc/heretic_summon_hound
		body.religion = HERETIC_RELIGION
		body.faction = "heretic"

/datum/heretic_devotee/proc/unbind_body(mob/living/body)
	if(body)
		body.verbs -= /mob/living/proc/heretic_knowledge
		body.verbs -= /mob/living/proc/heretic_offer
		body.verbs -= /mob/living/proc/heretic_path_power
		body.verbs -= /mob/living/proc/heretic_summon_hound

/datum/heretic_devotee/Destroy()
	owner = null
	sacrifice_targets.Cut()
	researched_knowledge.Cut()
	summons.Cut()
	return ..()

/mob/living/proc/heretic_knowledge()
	set name = "Forbidden Knowledge"
	set category = "Heretic"
	var/datum/heretic_devotee/devotee = get_heretic(src)
	if(!devotee || stat)
		return
	var/list/path_costs = list("Ash" = 1, "Blade" = 1, "Cosmos" = 2, "Flesh" = 2, "Lock" = 2, "Moon" = 2, "Rust" = 2, "Void" = 2)
	var/list/choices = list()
	for(var/path_name in path_costs)
		if(path_name in devotee.researched_knowledge)
			continue
		var/cost = path_costs[path_name]
		choices["Research the [path_name] path ([cost] point[cost == 1 ? "" : "s"])"] = path_name
	choices["Review your progress"] = "review"
	var/choice = input(src, "You have [devotee.knowledge_points] knowledge point(s). Choose a study.", "Forbidden Knowledge") as null|anything in choices
	if(!choice)
		return
	var/selected = choices[choice]
	if(selected == "review")
		var/list/researched = devotee.researched_knowledge.len ? devotee.researched_knowledge : list("None")
		to_chat(src, "<span class='notice'>You have offered [devotee.total_sacrifices] sacrifice(s). Researched paths: [english_list(researched)].</span>")
		return
	var/research_cost = path_costs[selected]
	var/already_researched = (selected in devotee.researched_knowledge)
	if(!research_cost || devotee.knowledge_points < research_cost || already_researched)
		to_chat(src, "<span class='warning'>You lack the knowledge required for that path.</span>")
		return
	devotee.knowledge_points -= research_cost
	devotee.researched_knowledge |= selected
	devotee.knowledge_gained += research_cost
	devotee.bind_body(devotee.owner.current)
	updateButtons()
	to_chat(src, "<span class='cult'>Forbidden Knowledge takes root. You have learned the [selected] path.</span>")

/mob/living/proc/heretic_offer()
	set name = "Offer a Sacrifice"
	set category = "Heretic"
	var/datum/heretic_devotee/devotee = get_heretic(src)
	if(!devotee || stat)
		return
	var/list/corpses = list()
	for(var/mob/living/carbon/human/target in view(1, src))
		if(target.stat != DEAD || target == src)
			continue
		var/target_key = target.mind ? target.mind : target
		if(target_key in devotee.sacrificed)
			continue
		corpses += target
	if(!corpses.len)
		to_chat(src, "<span class='warning'>There is no unoffered corpse within reach.</span>")
		return
	var/mob/living/carbon/human/target = input(src, "Choose a corpse to offer to the Mansus.", "Offer a Sacrifice") as null|anything in corpses
	if(!target || !(target in view(1, src)) || target.stat != DEAD)
		return
	if(!do_after(src, 50))
		return
	if(!get_heretic(src) || !(target in view(1, src)) || target.stat != DEAD)
		to_chat(src, "<span class='warning'>The offering is interrupted.</span>")
		return
	var/sacrifice_key = target.mind ? target.mind : target
	if(sacrifice_key in devotee.sacrificed)
		return
	devotee.sacrificed |= sacrifice_key
	devotee.total_sacrifices++
	var/points_awarded = 1
	if(target.mind && player_is_antag(target.mind))
		points_awarded++
		devotee.high_value_sacrifices++
	devotee.knowledge_points += points_awarded
	devotee.knowledge_gained += points_awarded
	visible_message("<span class='warning'>[src] whispers over [target]'s body as strange symbols briefly burn across the air.</span>", "<span class='cult'>The Mansus accepts the offering. You gain [points_awarded] knowledge point(s).</span>")

/mob/living/proc/heretic_path_power()
	set name = "Invoke a Path"
	set category = "Heretic"
	var/datum/heretic_devotee/devotee = get_heretic(src)
	if(!devotee || stat || world.time < devotee.next_power_use)
		return
	var/list/path_names = list("Ash", "Blade", "Cosmos", "Flesh", "Lock", "Moon", "Rust", "Void")
	var/list/available_paths = list()
	for(var/path_name in path_names)
		if(path_name in devotee.researched_knowledge)
			available_paths += path_name
	if(!available_paths.len)
		return
	var/path_choice = input(src, "Choose a researched path to invoke.", "Heretic Path") as null|anything in available_paths
	if(!path_choice || !(path_choice in devotee.researched_knowledge) || world.time < devotee.next_power_use)
		return
	var/list/nearby_targets = list()
	for(var/mob/living/carbon/human/target in view(5, src))
		if(target != src && target.stat != DEAD)
			nearby_targets += target
	switch(path_choice)
		if("Ash")
			var/list/destinations = list()
			for(var/turf/T in orange(3, src))
				if(!T.density && !T.holy)
					destinations += T
			if(!destinations.len)
				to_chat(src, "<span class='warning'>The ash has nowhere to carry you.</span>")
				return
			forceMove(pick(destinations))
			to_chat(src, "<span class='cult'>You dissolve into grey ash and reform nearby.</span>")
		if("Blade")
			var/mob/living/carbon/human/target = input(src, "Choose a nearby target.", "Heretic Blade") as null|anything in nearby_targets
			if(!target || !(target in view(1, src)) || target.stat == DEAD)
				return
			target.adjustBruteLoss(20)
			target.Weaken(10)
			visible_message("<span class='danger'>An invisible blade tears through [target]!</span>")
		if("Cosmos")
			var/list/readings = list()
			for(var/mob/living/carbon/human/target in view(7, src))
				if(target != src && target.stat != DEAD)
					readings += target.name
			to_chat(src, "<span class='cult'>The stars disclose nearby living minds: [english_list(readings)].</span>")
		if("Flesh")
			adjustBruteLoss(-20)
			adjustFireLoss(-20)
			to_chat(src, "<span class='cult'>Your wounds knit as the Mansus reshapes your flesh.</span>")
		if("Lock")
			var/mob/living/carbon/human/target = input(src, "Choose a nearby target.", "Heretic Lock") as null|anything in nearby_targets
			if(!target || !(target in view(2, src)) || target.stat == DEAD)
				return
			target.Stun(20)
			visible_message("<span class='warning'>[target] freezes as unseen doors slam shut around them.</span>")
		if("Moon")
			var/mob/living/carbon/human/target = input(src, "Choose a nearby target.", "Heretic Moon") as null|anything in nearby_targets
			if(!target || !(target in view(5, src)) || target.stat == DEAD)
				return
			target.confused += 20
			target.eye_blind += 5
			to_chat(target, "<span class='warning'>The room turns unfamiliar, and the moon seems much too close.</span>")
		if("Rust")
			var/mob/living/carbon/human/target = input(src, "Choose a nearby target.", "Heretic Rust") as null|anything in nearby_targets
			if(!target || !(target in view(1, src)) || target.stat == DEAD)
				return
			target.adjustBruteLoss(15)
			to_chat(target, "<span class='danger'>Corrosion crawls beneath your skin.</span>")
		if("Void")
			var/mob/living/carbon/human/target = input(src, "Choose a nearby target.", "Heretic Void") as null|anything in nearby_targets
			if(!target || !(target in view(5, src)) || target.stat == DEAD)
				return
			target.adjustOxyLoss(20)
			target.eye_blind += 10
			to_chat(target, "<span class='warning'>The air vanishes into a silent, lightless void.</span>")
	if(!get_heretic(src))
		return
	devotee.next_power_use = world.time + 2 MINUTES

/mob/living/proc/heretic_summon_hound()
	set name = "Summon Spectral Hound"
	set category = "Heretic"
	var/datum/heretic_devotee/devotee = get_heretic(src)
	if(!devotee || stat || !("Flesh" in devotee.researched_knowledge) || devotee.knowledge_points < 3)
		to_chat(src, "<span class='warning'>The Flesh path needs three knowledge points to shape a hound.</span>")
		return
	for(var/mob/living/simple_animal/summoned in devotee.summons)
		if(summoned && !summoned.stat)
			to_chat(src, "<span class='warning'>Your spectral hound still answers the call.</span>")
			return
	var/turf/T = get_turf(src)
	if(!T || T.density)
		return
	devotee.knowledge_points -= 3
	var/mob/living/simple_animal/faithful_hound/hound = new(T)
	hound.faction = "heretic"
	hound.allowed_mobs |= src
	devotee.summons |= hound
	visible_message("<span class='warning'>A spectral hound crawls from the shadows beside [src].</span>")