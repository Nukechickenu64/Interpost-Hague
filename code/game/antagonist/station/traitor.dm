GLOBAL_DATUM_INIT(traitors, /datum/antagonist/traitor, new)

/datum/mind
	var/traitor_plant_uplink_pending = FALSE
	var/traitor_plant_uplink_claimed = FALSE

// Inherits most of its vars from the base datum.
/datum/antagonist/traitor
	id = MODE_TRAITOR
	protected_jobs = list(/datum/job/officer, /datum/job/warden, /datum/job/detective, /datum/job/captain, /datum/job/lawyer, /datum/job/hos)
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE
	hard_cap = 7
	hard_cap_round = 7
	initial_spawn_req = 2
	initial_spawn_target = 5
	show_objectives_on_creation = 0 //we are not antagonists, we do not need the antagonist shpiel/objectives
	porco_tab = "Traitor"

/datum/antagonist/traitor/attempt_spawn(spawn_target)
	var/datum/game_mode/traitor/mode = os13_fixed_traitor_mode()
	if(!mode)
		return ..()
	if(mode.os13_orders || !length(candidates))
		return FALSE
	while(length(candidates))
		var/datum/mind/candidate = pick(candidates)
		candidates -= candidate
		var/mob/living/carbon/human/H = candidate.current
		if(!istype(H) || H.stat == DEAD || !H.client || H.mind != candidate || candidate.special_role || player_is_antag(candidate) || !can_become_antag(candidate))
			continue
		if(!istype(candidate.assigned_job, /datum/job/os13))
			continue
		var/datum/os13_traitor_orders/orders = new(candidate)
		if(orders.setup())
			mode.os13_orders = orders
			addtimer(CALLBACK(orders, /datum/os13_traitor_orders/proc/restore_memory), 3 MINUTES)
			return TRUE
		qdel(orders)
		message_admins("OS13 Traitor could not find a mapped maintenance cache or lifeboat berth.")
		return FALSE
	message_admins("No eligible OS13 crew member remained in the Traitor lottery after job assignment.")
	return FALSE

/datum/antagonist/traitor/update_current_antag_max(datum/game_mode/mode)
	if(istype(mode, /datum/game_mode/traitor) && istype(GLOB.using_map, /datum/map/os13classic))
		cur_max = 1
		return
	return ..()

/datum/antagonist/traitor/greet(datum/mind/player)
	var/datum/os13_traitor_orders/orders = os13_fixed_traitor_mode()?.os13_orders
	if(orders?.owner == player)
		orders.brief(player.current)
		return TRUE
	return ..()

/datum/antagonist/traitor/get_porco_actions(mob/living/carbon/human/user)
	var/datum/os13_traitor_orders/orders = os13_fixed_traitor_mode()?.os13_orders
	if(!orders?.can_act(user))
		return ..()
	return list(list("os13_open_cache", "Open Cache"), list("os13_traitor_thoughts", "Thoughts"))

/datum/antagonist/traitor/print_player_summary()
	var/datum/game_mode/traitor/mode = os13_fixed_traitor_mode()
	if(!mode)
		return ..()
	if(mode.os13_orders)
		to_world(mode.os13_orders.debrief())

/datum/antagonist/traitor/get_extra_panel_options(var/datum/mind/player)
	return "<a href='?src=\ref[player];common=crystals'>\[set creation charges\]</a><a href='?src=\ref[src];spawn_uplink=\ref[player.current]'>\[spawn uplink\]</a>"

/datum/antagonist/traitor/Topic(href, href_list)
	if (..())
		return 1
	if(href_list["spawn_uplink"])
		spawn_uplink(locate(href_list["spawn_uplink"]))
		return 1

/datum/antagonist/traitor/create_objectives(var/datum/mind/traitor)
	var/datum/os13_traitor_orders/orders = os13_fixed_traitor_mode()?.os13_orders
	if(orders?.owner == traitor)
		var/datum/objective/os13_traitor/objective = new
		objective.owner = traitor
		objective.orders = orders
		traitor.objectives += objective
		return
	if(!..())
		return

	if(istype(traitor.current, /mob/living/silicon))
		var/datum/objective/assassinate/kill_objective = new
		kill_objective.owner = traitor
		kill_objective.find_target()
		traitor.objectives += kill_objective

		var/datum/objective/survive/survive_objective = new
		survive_objective.owner = traitor
		traitor.objectives += survive_objective

		if(prob(10))
			var/datum/objective/block/block_objective = new
			block_objective.owner = traitor
			traitor.objectives += block_objective
	else
		switch(rand(1,100))
			if(1 to 33)
				var/datum/objective/assassinate/kill_objective = new
				kill_objective.owner = traitor
				kill_objective.find_target()
				traitor.objectives += kill_objective
			if(34 to 50)
				var/datum/objective/brig/brig_objective = new
				brig_objective.owner = traitor
				brig_objective.find_target()
				traitor.objectives += brig_objective
			if(51 to 66)
				var/datum/objective/harm/harm_objective = new
				harm_objective.owner = traitor
				harm_objective.find_target()
				traitor.objectives += harm_objective
			else
				var/datum/objective/steal/steal_objective = new
				steal_objective.owner = traitor
				steal_objective.find_target()
				traitor.objectives += steal_objective
		switch(rand(1,100))
			if(1 to 80)
				if (!(locate(/datum/objective/escape) in traitor.objectives))
					var/datum/objective/escape/escape_objective = new
					escape_objective.owner = traitor
					traitor.objectives += escape_objective
			else
				if (!(locate(/datum/objective/hijack) in traitor.objectives))
					var/datum/objective/hijack/hijack_objective = new
					hijack_objective.owner = traitor
					traitor.objectives += hijack_objective
	return

/datum/antagonist/traitor/equip(var/mob/living/carbon/human/traitor_mob)
	var/datum/os13_traitor_orders/orders = os13_fixed_traitor_mode()?.os13_orders
	if(orders?.owner == traitor_mob?.mind && orders)
		return TRUE
	if(istype(traitor_mob, /mob/living/silicon)) // this needs to be here because ..() returns false if the mob isn't human
		add_law_zero(traitor_mob)
		give_intel(traitor_mob)
		if(istype(traitor_mob, /mob/living/silicon/robot))
			var/mob/living/silicon/robot/R = traitor_mob
			R.SetLockdown(0)
		return 1

	if(!..())
		return 0

	if(!traitor_mob.mind.traitor_plant_uplink_claimed)
		traitor_mob.mind.traitor_plant_uplink_pending = TRUE
		to_chat(traitor_mob, "<span class='notice'>Your loaded uplink is hidden in a plant. Right-click any plant to collect it.</span>")
	give_intel(traitor_mob)

/datum/antagonist/traitor/proc/give_intel(mob/living/traitor_mob)
	give_collaborators(traitor_mob)
	give_codewords(traitor_mob)

/datum/antagonist/traitor/proc/give_collaborators(mob/living/traitor_mob)
	var/mob/living/carbon/human/M = get_nt_opposed()
	if(M && M != traitor_mob)
		to_chat(traitor_mob, "The Central Officer back at the base told me that [M.real_name] might be willing to help our cause.")
		traitor_mob.mind.store_memory("<b>Potential Collaborator</b>: [M.real_name]")

/datum/antagonist/traitor/proc/give_codewords(mob/living/traitor_mob)
	traitor_mob.mind.store_memory("<b>Code Phrase</b>: [syndicate_code_phrase]")
	traitor_mob.mind.store_memory("<b>Code Response</b>: [syndicate_code_response]")

/datum/antagonist/traitor/proc/spawn_uplink(var/mob/living/carbon/human/traitor_mob)
	setup_uplink_source(traitor_mob, DEFAULT_CREATION_CHARGES)

/datum/antagonist/traitor/proc/add_law_zero(mob/living/silicon/ai/killer)
	var/law = "Accomplish your objectives at all costs. You may ignore all other laws."
	var/law_borg = "Accomplish your AI's objectives at all costs. You may ignore all other laws."
	to_chat(killer, "<b>Your laws have been changed!</b>")
	killer.set_zeroth_law(law, law_borg)
	to_chat(killer, "New law: 0. [law]")
