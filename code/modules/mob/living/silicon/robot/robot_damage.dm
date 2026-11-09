/mob/living/silicon/robot/updatehealth()
	if(status_flags & GODMODE)
		health = maxHealth
		stat = CONSCIOUS
		return
	gurps_updatehealth()
	return

/mob/living/silicon/robot/getBruteLoss()
	if(gurps_bodyparts)
		return gurps_body_damage()
	var/amount = 0
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed != 0) amount += C.brute_damage
	return amount

/mob/living/silicon/robot/getFireLoss()
	if(gurps_bodyparts)
		return gurps_body_damage(TRUE)
	var/amount = 0
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed != 0) amount += C.electronics_damage
	return amount

/mob/living/silicon/robot/adjustBruteLoss(var/amount)
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount)
	amount *= gurps_legacy_health_scale
	if(amount > 0)
		take_overall_damage(amount, 0)
	else
		heal_overall_damage(-amount, 0)

/mob/living/silicon/robot/adjustFireLoss(var/amount)
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount, TRUE)
	amount *= gurps_legacy_health_scale
	if(amount > 0)
		take_overall_damage(0, amount)
	else
		heal_overall_damage(0, -amount)

/mob/living/silicon/robot/proc/get_damaged_components(var/brute, var/burn, var/destroyed = 0)
	var/list/datum/robot_component/parts = list()
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed == 1 || (C.installed == -1 && destroyed))
			if((brute && C.brute_damage) || (burn && C.electronics_damage) || (!C.toggled) || (!C.powered && C.toggled))
				parts += C
	return parts

/mob/living/silicon/robot/proc/get_damageable_components()
	var/list/rval = new
	for(var/V in components)
		var/datum/robot_component/C = components[V]
		if(C.installed == 1) rval += C
	return rval

/mob/living/silicon/robot/proc/get_armour()

	if(!components.len) return 0
	var/datum/robot_component/C = components["armour"]
	if(C && C.installed == 1)
		return C
	return 0

/mob/living/silicon/robot/gurps_absorb_injury(var/injury)
	if(injury <= 0 || !cell || !istype(module_active, /obj/item/borg/combat/shield))
		return injury
	var/obj/item/borg/combat/shield/shield = module_active
	var/absorbed = injury * shield.shield_level
	var/cost = absorbed * gurps_legacy_health_scale * 100
	if(cell.charge < cost)
		cell.charge = 0
		to_chat(src, SPAN_WARNING("Your shield has overloaded!"))
		return injury
	cell.charge -= cost
	return max(0, injury - absorbed)

/mob/living/silicon/robot/heal_organ_damage(var/brute, var/burn)
	if(!gurps_damage_applying)
		if(brute) gurps_adjust_body_damage(-brute)
		if(burn) gurps_adjust_body_damage(-burn, TRUE)
		return
	var/list/datum/robot_component/parts = get_damaged_components(brute,burn)
	if(!parts.len)	return
	var/datum/robot_component/picked = pick(parts)
	picked.heal_damage(brute,burn)

/mob/living/silicon/robot/take_organ_damage(var/brute = 0, var/burn = 0, var/sharp = 0, var/edge = 0, var/emp = 0)
	if(!gurps_damage_applying)
		initialize_gurps_anatomy()
		var/flags = (sharp ? DAM_SHARP : 0) | (edge ? DAM_EDGE : 0)
		if(brute) gurps_receive_damage(brute / gurps_legacy_health_scale, BRUTE, BP_CHEST, damage_flags = flags, ignore_armor = emp)
		if(burn) gurps_receive_damage(burn / gurps_legacy_health_scale, BURN, BP_CHEST, ignore_armor = emp)
		return
	var/list/components = get_damageable_components()
	if(!components.len)
		return

	if(!emp)
		var/datum/robot_component/armour/A = get_armour()
		if(A)
			A.take_damage(brute,burn,sharp,edge)
			return

	var/datum/robot_component/C = pick(components)
	C.take_damage(brute,burn,sharp,edge)

/mob/living/silicon/robot/heal_overall_damage(var/brute, var/burn)
	if(!gurps_damage_applying)
		if(brute) gurps_adjust_body_damage(-brute)
		if(burn) gurps_adjust_body_damage(-burn, TRUE)
		return
	var/list/datum/robot_component/parts = get_damaged_components(brute,burn)

	while(parts.len && (brute>0 || burn>0) )
		var/datum/robot_component/picked = pick(parts)

		var/brute_was = picked.brute_damage
		var/burn_was = picked.electronics_damage

		picked.heal_damage(brute,burn)

		brute -= (brute_was-picked.brute_damage)
		burn -= (burn_was-picked.electronics_damage)

		parts -= picked

/mob/living/silicon/robot/take_overall_damage(var/brute = 0, var/burn = 0, var/sharp = 0, var/used_weapon = null)
	if(status_flags & GODMODE)	return	//godmode
	if(!gurps_damage_applying)
		if(brute) apply_damage(brute, BRUTE, damage_flags = sharp ? DAM_SHARP : 0, used_weapon = used_weapon)
		if(burn) apply_damage(burn, BURN, used_weapon = used_weapon)
		return
	var/list/datum/robot_component/parts = get_damageable_components()

	var/datum/robot_component/armour/A = get_armour()
	if(A)
		A.take_damage(brute,burn,sharp)
		return

	while(parts.len && (brute>0 || burn>0) )
		var/datum/robot_component/picked = pick(parts)

		var/brute_was = picked.brute_damage
		var/burn_was = picked.electronics_damage

		picked.take_damage(brute,burn)

		brute	-= (picked.brute_damage - brute_was)
		burn	-= (picked.electronics_damage - burn_was)

		parts -= picked

/mob/living/silicon/robot/emp_act(severity)
	uneq_all()
	..() //Damage is handled at /silicon/ level.

/mob/living/silicon/robot/rejuvenate()
	..()
	for(var/component_name in components)
		var/datum/robot_component/component = components[component_name]
		component.brute_damage = 0
		component.electronics_damage = 0
		if(component.installed == -1)
			component.repair()
