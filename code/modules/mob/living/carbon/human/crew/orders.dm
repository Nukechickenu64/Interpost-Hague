/proc/can_order_ai_crew(var/mob/user)
	if(!user || !user.client || GAME_STATE != RUNLEVEL_GAME || !SSticker.ai_crew)
		return FALSE
	if(check_rights(R_ADMIN, FALSE, user))
		return TRUE
	if(!ishuman(user) || user.incapacitated() || !user.mind)
		return FALSE
	var/datum/job/job = user.mind.assigned_job
	return job && !job.opposition && (job in job_master.occupations)

/mob/living/carbon/human/verb/ai_crew_orders()
	set name = "AI Crew Orders"
	set category = "IC"
	set desc = "Assign work priorities, movement and delivery orders to the AI crew."
	if(!can_order_ai_crew(src))
		to_chat(src, SPAN_WARNING("Only active crew or administrators can direct AI crew during a round."))
		return
	var/list/choices = list()
	for(var/mob/living/carbon/human/crew/H in SSticker.ai_crew.members)
		if(H.brain && H.stat != DEAD && !H.client)
			choices["[H.real_name] ([H.job]) - [H.brain.status]"] = H
	if(!choices.len)
		to_chat(src, SPAN_NOTICE("No AI crew are available."))
		return
	var/selection = input(src, "Choose an AI crew member. Job-specific automation is incomplete; all crew support movement and delivery orders.", "AI Crew") as null|anything in choices
	if(!selection)
		return
	var/mob/living/carbon/human/crew/H = choices[selection]
	if(!can_order_ai_crew(src) || QDELETED(H) || !H.brain)
		return
	var/action = input(src, "[H.real_name]: [H.brain.status]", "Crew Order") as null|anything in list("Work", "Follow me", "Move here", "Hold position", "Deliver item here", "Work priorities")
	if(!action)
		return
	if(!can_order_ai_crew(src) || QDELETED(H) || !H.brain)
		return
	var/datum/crew_ai/brain = H.brain
	if(action == "Work priorities")
		var/list/categories = list()
		for(var/category in brain.priorities)
			if(brain.supports(category))
				categories += category
		var/category = input(src, "Choose a work category.", "Work Priorities") as null|anything in categories
		if(!category)
			return
		var/priority = input(src, "0 disables this work. 1 is highest; 4 is lowest.", category, brain.priorities[category]) as null|num
		if(isnull(priority))
			return
		if(!can_order_ai_crew(src) || QDELETED(brain) || QDELETED(H))
			return
		if(priority != round(priority) || priority < 0 || priority > 4)
			to_chat(src, SPAN_WARNING("Choose a whole number from 0 to 4."))
			return
		brain.priorities[category] = priority
		to_chat(src, SPAN_NOTICE("[H.real_name]'s [category] priority is now [priority]."))
		return
	var/obj/item/item
	if(action == "Deliver item here")
		var/list/items = list()
		for(var/obj/item/I in view(7, src))
			if(isturf(I.loc) && !I.anchored)
				items += I
		item = input(src, "Choose a loose item to bring to your current location.", "Delivery") as null|anything in items
		if(!item)
			return
	if(!can_order_ai_crew(src) || QDELETED(H) || QDELETED(brain) || H.client || H.stat == DEAD)
		to_chat(src, SPAN_WARNING("This crew member is no longer available."))
		return
	if(brain.acting)
		to_chat(src, SPAN_WARNING("[H.real_name] is performing an interaction. Wait until it finishes."))
		return
	if(item && (QDELETED(item) || !isturf(item.loc) || item.anchored || !(item in view(7, src))))
		to_chat(src, SPAN_WARNING("That item is no longer available."))
		return
	brain.cancel_order()
	brain.order_user = src
	brain.order = action
	brain.order_target = (action == "Follow me") ? src : get_turf(src)
	brain.task_deadline = world.time + 3 MINUTES
	if(action == "Deliver item here")
		if(!brain.roster.claim(item, brain))
			brain.cancel_order()
			to_chat(src, SPAN_WARNING("Another AI crew member is already collecting that item."))
			return
		brain.order_target = item
		brain.delivery = get_turf(src)
	brain.status = action
	to_chat(src, SPAN_NOTICE("[H.real_name] received your order: [action]."))

/datum/crew_ai/proc/cancel_order()
	finish_task()
	if(cargo && cargo.loc == owner)
		owner.drop_from_inventory(cargo)
	cargo = null
	delivery = null
	order = "Work"
	order_target = null
	order_user = null

/datum/crew_ai/proc/process_order()
	if(order == "Hold position")
		status = "Holding position"
		return
	if(!order_target || QDELETED(order_target))
		fail_task("The order target is no longer available.")
		return
	if(order == "Follow me")
		if(!can_order_ai_crew(order_user))
			cancel_order()
			return
		if(navigate(get_turf(order_target), 2))
			task_deadline = world.time + 3 MINUTES
		else if(world.time > task_deadline)
			fail_task("Unable to follow you.")
		return
	if(world.time > task_deadline)
		fail_task("The order timed out.")
		return
	if(order == "Move here")
		if(navigate(get_turf(order_target), 0))
			order = "Hold position"
			status = "Holding position"
		return
	if(order == "Deliver item here")
		if(!cargo)
			var/obj/item/item = order_target
			if(!istype(item) || !isturf(item.loc) || item.anchored)
				fail_task("The delivery item is no longer available.")
				return
			if(!navigate(get_turf(item), 1))
				return
			if(!free_active_hand())
				fail_task("Cannot free a hand for the delivery.")
				return
			item.attack_hand(owner)
			if(item.loc != owner)
				fail_task("Cannot pick up the delivery item.")
				return
			cargo = item
			reset_navigation()
		if(cargo.loc != owner)
			fail_task("The delivery item was lost.")
			return
		if(navigate(delivery, 0))
			if(!owner.unEquip(cargo))
				fail_task("Cannot put down the delivery item.")
				return
			if(order_user)
				to_chat(order_user, SPAN_NOTICE("[owner] completed your delivery."))
			cargo = null
			cancel_order()
