/datum/crew_ai/proc/logistics_action(var/atom/target)
	if(istype(target, /obj/machinery/computer/hydroponics))
		var/obj/machinery/computer/hydroponics/console = target
		if(!console.operable() || !console.powered())
			return null
		if(!console.installed_chip)
			return "Install water chip"
		for(var/obj/machinery/biomass_vat/vat in console.get_connected_vats())
			if(vat.stage == BIOMASS_VAT_EMPTY && vat.operable() && vat.powered())
				return "Fill vats"
		return null
	if(istype(target, /obj/machinery/biomass_vat))
		var/obj/machinery/biomass_vat/vat = target
		if(!vat.operable() || !vat.powered())
			return null
		switch(vat.stage)
			if(BIOMASS_VAT_FILLED)
				if(!vat.has_yeast)
					return "Add yeast"
				if(!vat.has_glig)
					return "Add glig"
			if(BIOMASS_VAT_STIR)
				return "Stir vat"
			if(BIOMASS_VAT_READY)
				if(vat.portions > 0)
					return "Skim vat"
		return null
	if(istype(target, /obj/machinery/biomass_press/food_processor))
		var/obj/machinery/biomass_press/food_processor/unit = target
		// Meat processors have a separate input/output workflow.
		if(unit.input_type != /obj/item/hydroponics_supply/biomass)
			return null
		if(unit.stat & BROKEN)
			return unit.repairing ? null : "Repair food unit"
		if(!unit.operable() || !unit.powered() || unit.work_left)
			return null
		if(unit.ready)
			return "Collect meal"
		if(unit.loaded_input)
			return "Activate food unit"
		return "Load food unit"
	if(istype(target, /obj/machinery/biomass_press))
		var/obj/machinery/biomass_press/press = target
		if(!press.operable() || !press.powered() || press.work_left || press.output_type != /obj/item/hydroponics_supply/biomass)
			return null
		return press.ready ? "Collect biomass" : "Press goo"
	return null

/datum/crew_ai/proc/logistics_supply_type(var/action)
	switch(action)
		if("Install water chip")
			return /obj/item/device/waterchip
		if("Add yeast")
			return /obj/item/hydroponics_supply/yeast
		if("Add glig")
			return /obj/item/hydroponics_supply/glig
		if("Skim vat", "Press goo")
			return /obj/item/hydroponics_supply/skimmer
		if("Load food unit")
			return /obj/item/hydroponics_supply/biomass
	return null

/datum/crew_ai/proc/logistics_supply_matches(var/obj/item/item, var/supply_type, var/action)
	if(QDELETED(item) || !istype(item, supply_type) || item.anchored || avoided[item])
		return FALSE
	var/datum/crew_ai/claimant = roster.claims[item]
	if(claimant && claimant != src && !QDELETED(claimant))
		return FALSE
	if(istype(item, /obj/item/hydroponics_supply/skimmer))
		var/obj/item/hydroponics_supply/skimmer/skimmer = item
		if(skimmer.loaded != (action == "Press goo"))
			return FALSE
	return TRUE

/datum/crew_ai/proc/find_logistics_supply(var/supply_type, var/action)
	var/list/inventory = owner.get_contents()
	for(var/obj/item/item in inventory)
		if(logistics_supply_matches(item, supply_type, action))
			return item
	var/list/loose = list()
	if(supply_type == /obj/item/device/waterchip)
		for(var/obj/item/device/waterchip/chip in world)
			if(isturf(chip.loc))
				loose += chip
	else
		for(var/obj/item/hydroponics_supply/supply in world)
			if(isturf(supply.loc))
				loose += supply
	var/obj/item/best
	var/best_score = INFINITY
	for(var/obj/item/item in loose)
		if(!(item.z in GLOB.using_map.station_levels) || !logistics_supply_matches(item, supply_type, action))
			continue
		var/score = item.z == owner.z ? get_dist(owner, item) : 500
		if(score < best_score)
			best = item
			best_score = score
	return best

/datum/crew_ai/proc/ready_logistics_supply(var/supply_type, var/action)
	if(task_supply && !logistics_supply_matches(task_supply, supply_type, action))
		// The player or another machine may have consumed or changed the reserved item.
		fail_task("The reserved logistics supplies changed or became unavailable.")
		return null
	if(!task_supply)
		task_supply = find_logistics_supply(supply_type, action)
		if(!task_supply || !roster.claim(task_supply, src))
			fail_task("Missing available supplies for [action].")
			return null
	status = "[action]: collecting [task_supply.name]"
	return ready_item(task_supply)

/datum/crew_ai/proc/execute_logistics(var/obj/item/tool)
	if(logistics_action(work_target) != logistics_step)
		return FALSE
	if(logistics_supply_type(logistics_step) && (QDELETED(tool) || owner.get_active_hand() != tool))
		return FALSE
	switch(logistics_step)
		if("Install water chip")
			var/obj/machinery/computer/hydroponics/console = work_target
			console.attackby(tool, owner)
			return console.installed_chip == tool
		if("Fill vats")
			var/obj/machinery/computer/hydroponics/console = work_target
			return console.fill_vats() > 0
		if("Add yeast", "Add glig")
			var/obj/machinery/biomass_vat/vat = work_target
			if(!vat.at_front_tile(owner))
				return FALSE
			vat.attackby(tool, owner)
			return logistics_step == "Add yeast" ? vat.has_yeast : vat.has_glig
		if("Stir vat")
			var/obj/machinery/biomass_vat/vat = work_target
			if(!vat.at_front_tile(owner))
				return FALSE
			var/previous_stirs = vat.stirs
			vat.attack_hand(owner)
			return vat.stirs > previous_stirs
		if("Skim vat")
			var/obj/machinery/biomass_vat/vat = work_target
			if(!vat.at_front_tile(owner))
				return FALSE
			var/obj/item/hydroponics_supply/skimmer/skimmer = tool
			vat.attackby(skimmer, owner)
			return skimmer.loaded
		if("Press goo")
			var/obj/machinery/biomass_press/press = work_target
			var/obj/item/hydroponics_supply/skimmer/skimmer = tool
			press.attackby(skimmer, owner)
			return !skimmer.loaded && press.work_left > 0
		if("Load food unit")
			var/obj/machinery/biomass_press/food_processor/unit = work_target
			unit.attackby(tool, owner)
			return unit.loaded_input == tool
		if("Activate food unit")
			var/obj/machinery/biomass_press/food_processor/unit = work_target
			unit.attack_hand(owner)
			return unit.work_left > 0
		if("Repair food unit")
			var/obj/machinery/biomass_press/food_processor/unit = work_target
			unit.attack_hand(owner)
			return !QDELETED(unit) && !(unit.stat & BROKEN)
		if("Collect biomass", "Collect meal")
			var/obj/machinery/biomass_press/press = work_target
			press.attack_hand(owner)
			if(press.ready)
				return FALSE
			// Leave output available to the next worker or hungry crew, not hidden in inventory.
			var/obj/item/product = owner.get_active_hand()
			return product && owner.unEquip(product)
	return FALSE
