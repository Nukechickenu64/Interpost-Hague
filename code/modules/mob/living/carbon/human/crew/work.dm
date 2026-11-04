/datum/crew_ai/proc/supports(var/category)
	switch(category)
		if("Medical")
			return !!(job.department_flag & MED)
		if("Engineering")
			return !!(job.department_flag & ENG)
		if("Gardening", "Logistics")
			return !!(job.department_flag & (SUP|SRV))
		if("Cleaning")
			return TRUE
	return FALSE

/datum/crew_ai/proc/patient_limb(var/mob/living/carbon/human/patient)
	if(patient.stat == DEAD || patient.isSynthetic() || !patient.os13_medical_authorized())
		return null
	for(var/obj/item/organ/external/limb in patient.organs)
		if(limb.robotic >= ORGAN_ROBOT || limb.is_stump())
			continue
		if((limb.organ_tag == BP_HEAD && istype(patient.head, /obj/item/clothing/head/helmet/space)) || (limb.organ_tag != BP_HEAD && istype(patient.wear_suit, /obj/item/clothing/suit/space)))
			continue
		for(var/datum/wound/wound in limb.wounds)
			if(!wound.bandaged && wound.damage_type != BURN)
				return limb
	return null

/datum/crew_ai/proc/work_needed(var/atom/A, var/category)
	if(QDELETED(A))
		return FALSE
	switch(category)
		if("Medical")
			var/mob/living/carbon/human/patient = A
			return istype(patient) && patient_limb(patient)
		if("Engineering")
			var/turf/simulated/wall/wall = A
			return istype(wall) && wall.damage > 0 && wall.construction_stage && !wall.thermite && !(locate(/obj/effect/overlay/wallrot) in wall)
		if("Gardening")
			var/obj/machinery/portable_atmospherics/hydroponics/tray = A
			return istype(tray) && !tray.closed_system && (tray.harvest || tray.dead)
		if("Logistics")
			return !!logistics_action(A)
		if("Cleaning")
			return istype(A, /obj/effect/decal/cleanable) && isturf(A.loc)
		if("Eating")
			var/obj/item/reagent_containers/food/snacks/food = A
			return istype(food) && food.reagents && food.reagents.has_reagent(/datum/reagent/nutriment) && owner.get_fullness() < NUTRITION_LEVEL_FED
		if("Drinking")
			var/obj/item/reagent_containers/food/drinks/drink = A
			return istype(drink) && drink.reagents && drink.reagents.has_reagent(/datum/reagent/water) && owner.thirst < THIRST_LEVEL_MEDIUM
	return FALSE

/datum/crew_ai/proc/consider_work(var/atom/A, var/category, var/list/candidates)
	if(!A || avoided[A] || !supports(category) || !priorities[category] || !work_needed(A, category))
		return
	var/turf/T = get_turf(A)
	if(!T || !(T.z in GLOB.using_map.station_levels))
		return
	var/datum/crew_ai/claimed = roster.claims[A]
	if(claimed && claimed != src && !QDELETED(claimed))
		return
	if(category == "Logistics")
		var/action = logistics_action(A)
		var/supply_type = logistics_supply_type(action)
		if(supply_type && !find_logistics_supply(supply_type, action))
			return
	var/score = priorities[category] * 1000 + (T.z == owner.z ? get_dist(owner, A) : 500)
	candidates[A] = list(category, score)

/datum/crew_ai/proc/find_work()
	if(find_meal())
		return
	var/list/candidates = list()
	if(supports("Medical") && priorities["Medical"])
		for(var/mob/living/carbon/human/patient in GLOB.human_mob_list)
			consider_work(patient, "Medical", candidates)
	if(supports("Gardening") && priorities["Gardening"])
		for(var/obj/machinery/machine in SSmachines.machinery)
			if(istype(machine, /obj/machinery/portable_atmospherics/hydroponics))
				consider_work(machine, "Gardening", candidates)
	if(supports("Logistics") && priorities["Logistics"])
		for(var/obj/machinery/machine in SSmachines.machinery)
			if(istype(machine, /obj/machinery/biomass_vat) || istype(machine, /obj/machinery/biomass_press) || istype(machine, /obj/machinery/computer/hydroponics))
				consider_work(machine, "Logistics", candidates)
	for(var/turf/simulated/wall/wall in view(7, owner))
		consider_work(wall, "Engineering", candidates)
	for(var/obj/effect/decal/cleanable/dirt in view(7, owner))
		consider_work(dirt, "Cleaning", candidates)
	var/atom/best
	var/best_score = INFINITY
	for(var/atom/A in candidates)
		var/list/entry = candidates[A]
		if(entry[2] < best_score)
			best = A
			best_score = entry[2]
	if(best && roster.claim(best, src))
		var/list/entry = candidates[best]
		work_target = best
		work_kind = entry[1]
		task_deadline = world.time + 3 MINUTES
		status = "[work_kind]: [best.name]"

/datum/crew_ai/proc/find_meal()
	if(owner.get_fullness() >= NUTRITION_LEVEL_FED && owner.thirst >= THIRST_LEVEL_MEDIUM)
		return FALSE
	var/list/items = owner.get_contents()
	for(var/obj/item/I in view(7, owner))
		if(isturf(I.loc) && !I.anchored)
			items |= I
	for(var/category in list("Drinking", "Eating"))
		for(var/obj/item/I in items)
			if(!avoided[I] && work_needed(I, category) && roster.claim(I, src))
				work_target = I
				work_kind = category
				task_deadline = world.time + 1 MINUTE
				status = category
				return TRUE
	return FALSE

/datum/crew_ai/proc/work_location()
	if(istype(work_target, /obj/machinery/biomass_vat))
		return get_step(work_target, NORTH)
	return get_turf(work_target)

/datum/crew_ai/proc/work_distance()
	return istype(work_target, /obj/machinery/biomass_vat) ? 0 : 1

/datum/crew_ai/proc/held_tool(var/tool_type)
	for(var/obj/item/I in owner.get_contents())
		if(istype(I, tool_type))
			return I
	return null

/datum/crew_ai/proc/ready_tool(var/tool_type)
	if(task_supply && !istype(task_supply, tool_type))
		if(roster.claims[task_supply] == src)
			roster.claims -= task_supply
		task_supply = null
	var/obj/item/tool = task_supply
	if(!tool)
		tool = held_tool(tool_type)
	if(!tool)
		for(var/obj/item/I in view(7, owner))
			if(istype(I, tool_type) && isturf(I.loc) && !I.anchored && !avoided[I] && (!roster.claims[I] || roster.claims[I] == src))
				tool = I
				break
	if(!tool)
		fail_task("Missing supplies for [work_kind].")
		return null
	task_supply = tool
	return ready_item(tool)

/datum/crew_ai/proc/ready_item(var/obj/item/tool)
	if(QDELETED(tool))
		fail_task("The required supplies are no longer available.")
		return null
	if(!roster.claim(tool, src))
		fail_task("Another worker reserved the required supplies.")
		return null
	if(tool == owner.get_active_hand())
		return tool
	if(!isturf(tool.loc) && !(tool in owner.get_contents()))
		fail_task("The required tool is no longer available.")
		return null
	if(isturf(tool.loc) && tool.anchored)
		fail_task("The required supplies are fixed in place.")
		return null
	if(isturf(tool.loc) && !navigate(get_turf(tool), 1))
		return null
	if(tool == owner.get_inactive_hand())
		owner.swap_hand()
		if(owner.get_active_hand() == tool)
			return tool
		fail_task("Cannot switch hands for work.")
		return null
	if(!free_active_hand())
		fail_task("Cannot free a hand for work.")
		return null
	tool.attack_hand(owner)
	if(owner.get_active_hand() == tool)
		return tool
	fail_task("Cannot pick up the required supplies.")
	return null

/datum/crew_ai/proc/free_active_hand()
	var/obj/item/held = owner.get_active_hand()
	if(!held)
		return TRUE
	if(!owner.canUnEquip(held))
		return FALSE
	for(var/obj/item/storage/container in owner.contents)
		if(container != held && container.can_be_inserted(held, owner, stop_messages = TRUE))
			if(container.handle_item_insertion(held, prevent_warning = TRUE))
				return TRUE
	return owner.unEquip(held)

/datum/crew_ai/proc/perform_work()
	if(!owner.canClick())
		return
	var/obj/item/tool
	switch(work_kind)
		if("Logistics")
			logistics_step = logistics_action(work_target)
			if(!logistics_step)
				finish_task()
				return
			var/supply_type = logistics_supply_type(logistics_step)
			if(supply_type)
				tool = ready_logistics_supply(supply_type, logistics_step)
				if(!tool)
					return
			else if(!free_active_hand())
				fail_task("Cannot free a hand for logistics work.")
				return
		if("Medical")
			tool = ready_tool(/obj/item/stack/medical/bruise_pack)
			if(!tool)
				return
		if("Engineering")
			if(owner.eyecheck() < FLASH_PROTECTION_MAJOR)
				var/obj/item/clothing/glasses/welding/goggles = ready_tool(/obj/item/clothing/glasses/welding)
				if(!goggles)
					return
				if(goggles.up || !owner.equip_to_slot_if_possible(goggles, slot_glasses))
					fail_task("Wall repair requires available, lowered welding goggles.")
					return
			tool = ready_tool(/obj/item/weldingtool)
			if(!tool)
				return
			var/obj/item/weldingtool/welder = tool
			if(welder.get_fuel() <= 0 || owner.eyecheck() < FLASH_PROTECTION_MAJOR)
				fail_task("Wall repair requires fuel and worn welding eye protection.")
				return
		if("Cleaning")
			tool = ready_tool(/obj/item/soap)
			if(!tool)
				return
		if("Eating", "Drinking")
			tool = ready_item(work_target)
			if(!tool)
				return
	// Tool collection can move the worker away from the actual worksite.
	if(!navigate(work_location(), work_distance()))
		return
	acting = TRUE
	status = "Working: [work_kind]"
	INVOKE_ASYNC(src, .proc/execute_work, tool)

/datum/crew_ai/proc/execute_work(var/obj/item/tool)
	var/progress = FALSE
	if(work_target && !QDELETED(work_target) && !owner.incapacitated() && owner.Adjacent(work_target) && work_needed(work_target, work_kind))
		owner.a_intent = I_HELP
		owner.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		switch(work_kind)
			if("Logistics")
				progress = execute_logistics(tool)
			if("Medical")
				var/mob/living/carbon/human/patient = work_target
				var/obj/item/organ/external/limb = patient_limb(patient)
				if(limb)
					var/obj/item/stack/medical/bandages = tool
					var/previous_amount = bandages.amount
					owner.zone_sel.selecting = limb.organ_tag
					tool.attack(patient, owner)
					progress = QDELETED(bandages) || bandages.amount < previous_amount
			if("Engineering")
				var/obj/item/weldingtool/welder = tool
				if(welder.get_fuel() > 0)
					welder.setWelding(TRUE, owner)
					// Recheck immediately before attackby: an undamaged wall is dismantled instead.
					if(work_needed(work_target, "Engineering"))
						work_target.attackby(welder, owner)
					if(!QDELETED(work_target))
						progress = !work_needed(work_target, "Engineering")
					if(!QDELETED(welder))
						welder.setWelding(FALSE, owner)
			if("Gardening")
				work_target.attack_hand(owner)
				progress = !work_needed(work_target, "Gardening")
			if("Cleaning")
				tool.afterattack(work_target, owner, TRUE)
				progress = QDELETED(work_target)
			if("Eating", "Drinking")
				var/obj/item/reagent_containers/meal = tool
				var/previous_volume = meal.reagents.total_volume
				owner.zone_sel.selecting = BP_MOUTH
				if(istype(tool, /obj/item/reagent_containers/food/drinks))
					var/obj/item/reagent_containers/food/drinks/drink = tool
					if(!drink.is_open_container())
						drink.open(owner)
				tool.attack(owner, owner)
				progress = QDELETED(meal) || meal.reagents.total_volume < previous_volume
	if(QDELETED(src))
		return
	acting = FALSE
	if(!progress)
		fail_task("Work was interrupted or could not make progress.")
		return
	status = "Completed [work_kind]"
	finish_task()
