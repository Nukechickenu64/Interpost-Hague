// Shared human melee resolution. See docs/combat-parity-implementation.md for
// verified 3e rules, Lifeweb extensions, and the legacy anatomy conversion.
#define COMBAT_TURN 10

/mob/living/carbon/human
	var/combat_action_until = 0
	var/combat_defenseless_until = 0
	var/combat_defense_window = -1
	var/combat_blocks_used = 0
	var/combat_left_parries = 0
	var/combat_right_parries = 0
	var/combat_shock = 0
	var/combat_shock_until = 0
	var/combat_injury_applying = FALSE
	var/combat_defending_until = 0
	var/combat_motion_window = -1
	var/combat_steps = 0
	var/combat_action_kind = ""
	var/combat_action_steps = 0
	var/combat_last_step = -COMBAT_TURN
	// Physical handedness is independent of which HUD hand is selected.
	var/combat_left_handed = FALSE
	var/list/last_combat_event

/obj/item
	// Null means this item's legacy force is converted at the boundary, not a
	// certified tabletop weapon profile. Explicit modes are dice-table modifiers.
	var/combat_swing_add = null
	var/combat_thrust_add = null
	var/combat_damage_cap = 0
	var/combat_min_st = 0
	var/combat_unbalanced = FALSE
	var/combat_parry_fraction = 0.5
	var/combat_parry_modifier = 0

/obj/item/clothing
	var/combat_dr = null
	var/combat_pd = null

/obj/item/weapon/shield
	var/combat_shield_pd = 3

/obj/item/weapon/shield/buckler
	combat_shield_pd = 1

/obj/item/weapon/shield/proc/combat_shield_available()
	return TRUE

/obj/item/weapon/shield/energy/combat_shield_available()
	return active

/obj/item/weapon/material/knife
	combat_swing_add = -2
	combat_thrust_add = 0
	combat_damage_cap = 8
	combat_parry_modifier = -1

/obj/item/weapon/material/sword
	combat_swing_add = 1
	combat_thrust_add = 1
	combat_min_st = 10

/obj/item/weapon/material/sword/combat_knife
	combat_swing_add = -2
	combat_thrust_add = 0
	combat_damage_cap = 8
	combat_min_st = 0
	combat_parry_modifier = -1

/obj/item/weapon/material/sword/mace
	combat_swing_add = 3
	combat_min_st = 12
	combat_unbalanced = TRUE

/obj/item/weapon/material/sword/club
	combat_swing_add = 1

/obj/item/weapon/material/knife/dagger
	name = "dagger"
	sharp = TRUE
	edge = FALSE
	combat_swing_add = null
	combat_thrust_add = -1
	combat_damage_cap = 6

/obj/item/weapon/material/sword/makeshiftspear
	combat_swing_add = null
	combat_thrust_add = 2
	combat_min_st = 9

/obj/item/weapon/staff
	combat_swing_add = 2
	combat_thrust_add = 2
	combat_parry_fraction = 0.666667

/obj/item/weapon/material/hatchet
	combat_swing_add = 2
	combat_min_st = 12
	combat_unbalanced = TRUE

/obj/item/clothing/suit/armor/breastplate
	combat_dr = 6
	combat_pd = 4

/obj/item/clothing/suit/armor/fullbreastplate
	combat_dr = 6
	combat_pd = 4

/mob/living/carbon/human/proc/combat_hand_usable(var/left)
	var/obj/item/organ/external/O = get_organ(left ? BP_L_HAND : BP_R_HAND)
	var/obj/item/organ/external/arm = get_organ(left ? BP_L_ARM : BP_R_ARM)
	return O && arm && O.is_usable() && arm.is_usable()

/mob/living/carbon/human/proc/combat_can_act(var/left, var/special = FALSE)
	combat_refresh_motion()
	if(stat || paralysis || stunned || weakened || sleeping || restrained())
		return FALSE
	if(world.time < combat_action_until || staminaloss >= 120 || combat_steps > 1)
		return FALSE
	if(special)
		return world.time >= special_action_ready_until
	return combat_hand_usable(left) && world.time >= (left ? left_hand_ready_until : right_hand_ready_until)

/mob/living/carbon/human/proc/combat_commit(var/duration = COMBAT_TURN, var/left, var/special = FALSE)
	combat_action_until = world.time + max(COMBAT_TURN, duration)
	combat_action_kind = "attack"
	combat_action_steps = combat_steps
	combat_defending_until = 0
	guard_stance_charges = 0
	setClickCooldown(combat_action_until - world.time)
	if(special)
		set_special_action_cooldown(combat_action_until)
	else
		set_hand_ready_cooldown(left, combat_action_until)
	update_hand_ready_hud()

/mob/living/carbon/human/proc/combat_refresh_motion()
	if(combat_motion_window < 0 || world.time >= combat_motion_window + COMBAT_TURN)
		combat_motion_window = world.time
		combat_steps = 0

/mob/living/carbon/human/Move(NewLoc, direct)
	var/count_step = isturf(loc) && isturf(NewLoc) && loc != NewLoc && !throwing && !buckled
	if(count_step)
		combat_refresh_motion()
		if(world.time < combat_action_until && combat_action_kind != "move" && combat_action_steps >= 1)
			return FALSE
		if(combat_mode && combat_steps >= combat_dodge_target())
			return FALSE
	. = ..()
	if(. && count_step)
		combat_last_step = world.time
		combat_steps++
		if(world.time < combat_action_until && combat_action_kind != "move")
			combat_action_steps++
		if(combat_steps > 1)
			combat_action_kind = "move"
			combat_action_until = max(combat_action_until, combat_motion_window + COMBAT_TURN)
			combat_defending_until = 0
			guard_stance_charges = 0

/mob/living/carbon/human/proc/combat_attempt_grab(mob/living/carbon/human/target, var/zone)
	if(!target || target == src || !Adjacent(target) || get_z(src) != get_z(target) || !combat_can_act(hand) || get_active_hand() || c_intent == I_DEFEND)
		return FALSE
	combat_commit(COMBAT_TURN, hand)
	combat_defending_until = 0
	guard_stance_charges = 0
	if(c_intent == I_STRONG || c_intent == I_QUICK)
		combat_defenseless_until = combat_action_until
	adjustStaminaLoss(3)
	do_attack_animation(target)
	var/list/roll = gurps_roll(combat_attack_target(null, zone, hand != combat_left_handed))
	var/feint = consume_feint_bonus(target)
	last_combat_event = list("target" = target, "zone" = zone, "roll" = roll, "outcome" = "miss", "injury" = 0)
	if(!roll["success"])
		visible_message(SPAN_WARNING("[src] fails to grab [target]'s [combat_location_name(zone)]!"))
		return FALSE
	var/defense = roll["critical_success"] ? null : target.combat_defend(src, null, zone, "cr", feint)
	if(defense)
		last_combat_event["outcome"] = defense
		return FALSE
	last_combat_event["outcome"] = "grab"
	return TRUE

/mob/living/carbon/human/proc/combat_skill(obj/item/weapon = null)
	// Existing job ranks remain a compatibility input; no random mood/readiness
	// bonus is injected into an otherwise identical attack or defense.
	if(!weapon)
		return max(gurps_stat(STAT_DX), gurps_skill_target("unarmed"))
	return gurps_skill_target(weapon.deathweb_weapon_skill ? weapon.deathweb_weapon_skill : SKILL_MELEE)

/proc/combat_location_penalty(var/zone)
	// Advanced-location values are an explicit provisional content profile.
	// Keep them separate from the verified roll/defense machinery.
	switch(zone)
		if(BP_EYES) return -9
		if(BP_HEAD) return -7
		if(BP_FACE, BP_MOUTH, BP_THROAT) return -5
		if(BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT) return -4
		if(BP_VITALS, BP_GROIN) return -3
		if(BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG) return -2
	return 0

/proc/combat_location_name(var/zone)
	switch(zone)
		if(BP_EYES) return "eye"
		if(BP_THROAT) return "throat"
		if(BP_FACE) return "face"
		if(BP_MOUTH) return "mouth"
		if(BP_VITALS) return "vitals"
		if(BP_BELLY) return "belly"
	return zone

/proc/combat_style_description(var/style)
	switch(style)
		if(I_WEAK) return "Light attack: use one less ST for damage."
		if(I_AIM) return "Aimed attack: +2 to hit, with one extra second of recovery."
		if(I_STRONG) return "Strong attack: +2 damage; no active defense until ready again."
		if(I_QUICK) return "Fury: +4 to hit; no active defense until ready again."
		if(I_DEFEND) return "Defense: right-click to commit to two different defense attempts. Select another style to attack."
		if(I_GUARD) return "Guard: right-click to brace for two different defense attempts. Attacking ends the guard."
		if(I_DUAL) return "Dual: right-click your opponent to attack with the other hand. The weaker hand is at -4; both hands share recovery."
		if(I_FEINT) return "Feint: right-click your opponent, then attack after recovery to exploit the opening."
	return ""

/mob/living/carbon/human/proc/combat_attack_target(obj/item/weapon, var/zone, var/offhand = FALSE)
	var/target = combat_skill(weapon) + combat_location_penalty(zone)
	if(weapon)
		target -= max(0, weapon.combat_min_st - combat_strength())
		target -= round(weapon.deathweb_accuracy / 10)
	if(offhand)
		target -= 4
	if(lying)
		target -= 4
	if(length(grabbed_by))
		target -= 4
	if(world.time < combat_shock_until)
		target -= combat_shock
	// Lifeweb aimed melee is a declared extension, not ranged Aim.
	if(c_intent == I_AIM)
		target += 2
	if(c_intent == I_QUICK)
		target += 4
	return target

/mob/living/carbon/human/proc/combat_attack_duration(obj/item/weapon)
	var/duration = weapon && weapon.combat_unbalanced ? 2 * COMBAT_TURN : COMBAT_TURN
	if(weapon && isnull(weapon.combat_swing_add) && isnull(weapon.combat_thrust_add))
		duration = max(duration, weapon.weapon_speed_delay)
	if(c_intent == I_AIM)
		duration += COMBAT_TURN
	return duration

/mob/living/carbon/human/proc/combat_refresh_defenses()
	if(combat_defense_window < 0 || world.time >= combat_defense_window + COMBAT_TURN)
		combat_defense_window = world.time
		combat_blocks_used = 0
		combat_left_parries = 0
		combat_right_parries = 0

/mob/living/carbon/human/proc/combat_faces(atom/attacker)
	if(!attacker || get_z(src) != get_z(attacker))
		return FALSE
	var/attack_direction = get_dir(src, attacker)
	return !attack_direction || !(attack_direction & reverse_direction(dir))

/mob/living/carbon/human/proc/combat_dodge_target()
	var/move = round((gurps_stat(STAT_DX) + gurps_stat(STAT_HT)) / 4)
	// Inventory has no weights in pounds. Existing slowdown is the explicit
	// encumbrance adapter until all equipment has a tabletop weight profile.
	var/load_penalty = 0
	for(var/slot = slot_first to slot_last)
		var/obj/item/I = get_equipped_item(slot)
		if(I)
			load_penalty += max(0, I.slowdown_general + I.slowdown_per_slot[slot] + I.slowdown_accessory)
	move = max(1, move - round(load_penalty))
	if(health <= maxHealth * 3 / max(1, gurps_stat(STAT_HT)))
		move = round(move / 2)
	return move

/mob/living/carbon/human/proc/combat_parry_target(obj/item/weapon)
	if(!weapon)
		return max(round(gurps_stat(STAT_DX) / 2), round(gurps_skill_target("unarmed") * 2 / 3))
	return round(combat_skill(weapon) * weapon.combat_parry_fraction) + weapon.combat_parry_modifier

/mob/living/carbon/human/proc/combat_protection(var/zone, var/damage_type = "cr")
	var/list/result = list("dr" = 0, "pd" = 0, "layers" = list())
	var/obj/item/organ/external/O = get_organ(zone == BP_VITALS ? BP_CHEST : zone)
	if(!O)
		return result
	var/coverage = O.body_part
	if(zone in list(BP_FACE, BP_MOUTH))
		coverage = FACE
	else if(zone == BP_EYES)
		coverage = EYES
	for(var/obj/item/clothing/C in list(head, wear_mask, wear_suit, w_uniform, gloves, shoes, glasses))
		if(!(C.body_parts_covered & coverage))
			continue
		var/dr = C.combat_dr
		var/pd = C.combat_pd
		if(isnull(dr))
			dr = round(max(0, C.armor["melee"]) / 10)
		if(isnull(pd))
			pd = min(4, round(dr / 2))
		if(C.deathweb_armor_type == DEATHWEB_ARMOR_MAIL && damage_type == "imp")
			dr = min(dr, 2)
			pd = min(pd, 1)
		if(!isnull(C.combat_dr))
			dr = round(dr * C.deathweb_durability / 100)
		result["dr"] += dr
		result["pd"] = max(result["pd"], pd)
		var/list/layers = result["layers"]
		layers += C
	return result

/mob/living/carbon/human/proc/combat_defend(mob/living/carbon/human/attacker, obj/item/incoming, var/zone, var/damage_type, var/feint = 0, var/attack_kind = "strike")
	combat_refresh_defenses()
	var/list/protection = combat_protection(zone, damage_type)
	var/pd = protection["pd"]
	var/front = combat_faces(attacker)
	var/obj/item/weapon/shield/shield
	var/shield_left = FALSE
	for(var/obj/item/weapon/shield/S in list(l_hand, r_hand))
		if(!S.combat_shield_available() || !combat_hand_usable(S == l_hand))
			continue
		if(!shield || S.combat_shield_pd > shield.combat_shield_pd)
			shield = S
			shield_left = S == l_hand
	if(shield && front)
		pd += shield.combat_shield_pd
	var/list/options = list()
	var/active = combat_mode && front && !stat && !paralysis && !sleeping && !restrained() && world.time >= combat_defenseless_until
	var/penalty = feint + (stunned ? 4 : 0) + (lying ? 3 : 0) + (length(grabbed_by) ? 4 : 0)
	var/defend = world.time < combat_defending_until
	var/limit = defend ? 2 : 1
	if(active)
		if(canmove && !buckled)
			options["dodge"] = combat_dodge_target() + pd - penalty
		if(shield && combat_hand_usable(shield_left) && world.time >= (shield_left ? left_hand_ready_until : right_hand_ready_until) && combat_blocks_used < limit)
			options["block"] = round(max(gurps_stat(STAT_DX) - 4, gurps_skill_target("shield")) / 2) + pd - penalty
		// Each held weapon has its own parry allowance. HUD selection must not
		// conceal the second weapon or reset the first weapon's spent defense.
		for(var/left in list(FALSE, TRUE))
			var/obj/item/P = left ? l_hand : r_hand
			var/used = left ? combat_left_parries : combat_right_parries
			if(!combat_hand_usable(left) || used >= limit)
				continue
			if(istype(P, /obj/item/weapon/shield))
				continue
			if(P && (!P.force || (P.item_flags & ITEM_FLAG_NO_BLUDGEON) || (P.combat_unbalanced && world.time < P.next_attack_time)))
				continue
			var/bare_penalty = !P && incoming && (incoming.edge || !incoming.sharp) ? 3 : 0
			options[left ? "parry left" : "parry right"] = combat_parry_target(P) + pd - penalty - bare_penalty
	if(!length(options))
		if(pd <= 0)
			return null
		options["passive protection"] = pd
	var/list/attempted = list()
	for(var/attempt = 1; attempt <= (defend ? 2 : 1); attempt++)
		var/chosen
		var/best = -INFINITY
		for(var/option in options)
			var/kind = findtext(option, "parry") == 1 ? "parry" : option
			if(kind in attempted)
				continue
			var/value = options[option]
			if(value > best || (value == best && kind == (defense_intent == I_PARRY ? "parry" : "dodge")))
				chosen = option
				best = value
		if(!chosen)
			break
		var/parry_left = chosen == "parry left"
		var/obj/item/parrying_weapon
		if(findtext(chosen, "parry") == 1)
			chosen = "parry"
			parrying_weapon = parry_left ? l_hand : r_hand
		attempted += chosen
		if(chosen == "block")
			combat_blocks_used++
			deathweb_learn_skill("shield", -2)
		if(chosen == "parry")
			if(parry_left)
				combat_left_parries++
			else
				combat_right_parries++
			if(parrying_weapon && parrying_weapon.combat_unbalanced)
				parrying_weapon.next_attack_time = world.time + COMBAT_TURN
				set_hand_ready_cooldown(parry_left, parrying_weapon.next_attack_time)
		var/list/roll = gurps_roll(best)
		if(roll["success"])
			if(chosen == "dodge")
				visible_message(SPAN_NOTICE("[src] dodges [attacker]'s attack!"))
			else if(chosen == "block")
				visible_message(SPAN_NOTICE("[src] blocks [attacker]'s attack with [shield]!"))
			else if(chosen == "parry")
				visible_message(SPAN_NOTICE("[src] parries [attacker]'s attack with [parrying_weapon ? parrying_weapon : "bare hands"]!"))
				if(parrying_weapon && !incoming)
					combat_parry_unarmed(attacker, parrying_weapon, attack_kind)
			else
				visible_message(SPAN_NOTICE("[src]'s protection turns aside [attacker]'s attack!"))
			playsound(src, 'sound/weapons/thudswoosh.ogg', 50, 1)
			return chosen
	return null

/mob/living/carbon/human/proc/combat_parry_unarmed(mob/living/carbon/human/attacker, obj/item/weapon, var/attack_kind)
	// A successful weapon parry can injure the attacking limb (Lite p.26).
	var/list/counter = gurps_roll(combat_skill(weapon))
	if(!counter["success"])
		return
	var/zone = attack_kind == "kick" ? BP_R_LEG : (attacker.hand ? BP_L_ARM : BP_R_ARM)
	if(attack_kind == "kick")
		var/obj/item/organ/external/leg = attacker.get_organ(BP_R_LEG)
		if(!leg || !leg.is_usable())
			zone = BP_L_LEG
	var/damage_type = weapon.edge ? "cut" : (weapon.sharp ? "imp" : "cr")
	var/list/protection = attacker.combat_protection(zone, damage_type)
	var/dr = weapon.deathweb_ignore_armor ? 0 : protection["dr"]
	var/injury = max(0, combat_roll_damage(weapon, damage_type, counter["dice"] == 3) - dr)
	if(injury)
		attacker.combat_apply_injury(injury, zone, damage_type, weapon)
		visible_message(SPAN_DANGER("[src]'s parry wounds [attacker]'s [combat_location_name(zone)]!"))
		admin_attack_log(src, attacker, "Wounded their attacking limb with a weapon parry.", "Was injured by an armed parry.", "parried")

/proc/combat_strength_dice(var/strength, var/swing = FALSE)
	// GURPS 3e Lite p.18, ST 5..20. Higher ST is a declared extrapolation.
	var/static/list/thrust_adds = list(-5,-4,-3,-3,-2,-2,-1,-1,0,0,1,1,2,2,-1,-1)
	var/static/list/swing_adds = list(-5,-4,-3,-2,-1,0,1,2,-1,0,1,2,-1,0,1,2)
	if(strength < 5)
		return list(0, 0)
	var/st = clamp(round(strength), 5, 20)
	var/dice = swing ? (st >= 17 ? 3 : (st >= 13 ? 2 : 1)) : (st >= 19 ? 2 : 1)
	var/adds = swing ? swing_adds[st - 4] : thrust_adds[st - 4]
	return list(dice, adds + max(0, round((strength - 20) / 2)))

/mob/living/carbon/human/proc/combat_roll_damage(obj/item/weapon, var/damage_type, var/maximize = FALSE, var/attack_kind = "strike")
	var/swing = weapon && (weapon.edge || !weapon.sharp)
	var/adds = weapon ? (swing ? weapon.combat_swing_add : weapon.combat_thrust_add) : (attack_kind == "kick" ? 0 : -2)
	if(weapon && isnull(adds))
		return max(damage_type == "cr" ? 0 : 1, round(weapon.force / 10))
	var/list/damage = combat_strength_dice(combat_strength(), swing)
	var/total = damage[2] + adds
	if(!weapon && gurps_skill_rank("unarmed") > 0)
		total += round(gurps_skill_target("unarmed") / 10)
	for(var/die = 1; die <= damage[1]; die++)
		total += maximize ? 6 : rand(1, 6)
	if(c_intent == I_STRONG)
		total += 2
	if(weapon && weapon.combat_damage_cap)
		total = min(total, weapon.combat_damage_cap)
	return max(damage_type == "cr" ? 0 : 1, total)

/mob/living/carbon/human/proc/combat_apply_injury(var/injury, var/zone, var/damage_type, obj/item/weapon)
	if(injury <= 0)
		return
	// Named, single conversion boundary for the existing medical/wound scale.
	// This does not certify legacy consciousness/healing as tabletop rules.
	var/scale = maxHealth / max(1, gurps_stat(STAT_HT))
	var/flags = damage_type == "cut" ? DAM_SHARP|DAM_EDGE : (damage_type == "imp" ? DAM_SHARP : 0)
	combat_injury_applying = TRUE
	var/obj/item/organ/external/O = get_organ(zone == BP_VITALS ? BP_CHEST : zone)
	apply_damage(injury * scale, BRUTE, zone, 0, flags, weapon, O)
	combat_injury_applying = FALSE
	combat_shock = (combat_shock_until > world.time ? combat_shock : 0) + injury
	combat_shock_until = world.time + COMBAT_TURN
	if(O && (zone in list(BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG, BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT)))
		var/threshold = gurps_stat(STAT_HT) / ((zone in list(BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT)) ? 3 : 2)
		if(injury > threshold)
			if(O.sever_tendon())
				visible_message(SPAN_DANGER("[src]'s [O.name] is crippled!"))
			if(zone in list(BP_L_ARM, BP_L_HAND))
				if(l_hand) drop_from_inventory(l_hand)
			else if(zone in list(BP_R_ARM, BP_R_HAND))
				if(r_hand) drop_from_inventory(r_hand)
	if(zone == BP_EYES && injury > gurps_stat(STAT_HT) / 10)
		var/obj/item/organ/internal/eyes/E = internal_organs_by_name[BP_EYES]
		if(E)
			E.take_internal_damage(E.max_damage)
			visible_message(SPAN_DANGER("[src]'s eye is ruined!"))
	if(injury > gurps_stat(STAT_HT) / 2)
		var/list/resist = gurps_roll(gurps_stat(STAT_HT))
		Stun(2)
		if(!resist["success"])
			Weaken(2)
			visible_message(SPAN_DANGER("[src] is stunned and falls down!"))
		else
			visible_message(SPAN_DANGER("[src] is stunned by the blow, but keeps their footing!"))
	updatehealth()
	UpdateDamageIcon()

/mob/living/carbon/human/proc/perform_combat_strike(mob/living/carbon/human/target, obj/item/weapon = null, var/zone = BP_CHEST, var/attack_kind = "strike")
	if(!zone)
		zone = BP_CHEST
	var/left = weapon ? weapon == l_hand : hand
	var/kicking = attack_kind == "kick"
	var/offhand = !kicking && left != combat_left_handed
	var/datum/unarmed_attack/natural_attack
	if(!weapon && !kicking)
		if(get_active_hand())
			return FALSE
		natural_attack = get_unarmed_attack(target, zone)
		if(!natural_attack)
			return FALSE
	if(!target || !Adjacent(target) || get_z(src) != get_z(target) || !combat_can_act(left, kicking))
		return FALSE
	if(kicking)
		var/obj/item/organ/external/leg = get_organ(BP_L_LEG)
		var/obj/item/organ/external/other_leg = get_organ(BP_R_LEG)
		if(target == src || lying || legcuffed() || ((!leg || !leg.is_usable()) && (!other_leg || !other_leg.is_usable())))
			return FALSE
	if(weapon && (!(weapon in list(l_hand, r_hand)) || world.time < weapon.next_attack_time || !weapon.force || (weapon.item_flags & ITEM_FLAG_NO_BLUDGEON)))
		return FALSE
	var/obj/item/organ/external/O = target.get_organ(zone == BP_VITALS ? BP_CHEST : zone)
	if(!O || O.is_stump())
		to_chat(src, SPAN_WARNING("They are missing that body part!"))
		return FALSE
	if(lying && !target.lying && (zone in list(BP_CHEST, BP_HEAD, BP_FACE, BP_EYES, BP_MOUTH, BP_THROAT)))
		to_chat(src, SPAN_WARNING("I can't reach their [combat_location_name(zone)]!"))
		return FALSE
	if(weapon && !aura_check(AURA_TYPE_WEAPON, weapon, src))
		return FALSE
	if(c_intent == I_DEFEND)
		to_chat(src, SPAN_WARNING("Right-click to prepare all-out defense, or select an attack style."))
		return FALSE
	var/duration = combat_attack_duration(weapon)
	if(natural_attack)
		duration = max(duration, natural_attack.delay)
	combat_commit(duration, left, kicking)
	combat_defending_until = 0
	guard_stance_charges = 0
	if(weapon)
		weapon.next_attack_time = combat_action_until
	if(c_intent == I_STRONG || c_intent == I_QUICK)
		combat_defenseless_until = combat_action_until
	adjustStaminaLoss((weapon ? weapon.w_class + 3 : 3) + (c_intent == I_STRONG ? 7 : 0))
	do_attack_animation(target)
	if(weapon && weapon.swing_sound)
		playsound(target, weapon.swing_sound, 50, 1, -1)
	var/feint = consume_feint_bonus(target)
	var/list/roll = gurps_roll(combat_attack_target(weapon, zone, offhand) - (kicking ? 2 : 0))
	var/list/event = list("target" = target, "weapon" = weapon, "zone" = zone, "roll" = roll, "outcome" = "miss", "injury" = 0, "ready_at" = combat_action_until)
	last_combat_event = event
	attack_quality = attack_quality_from_margin(roll["margin"], roll["success"])
	admin_attack_log(src, target, "Attacked [zone] using [weapon ? weapon : "an unarmed strike"].", "Was attacked.", "attacked")
	deathweb_learn_skill(weapon && weapon.deathweb_weapon_skill ? weapon.deathweb_weapon_skill : "unarmed", -2)
	if(!roll["success"])
		visible_message(SPAN_DANGER("[src] [attack_quality] misses [target] with [weapon ? weapon : "an unarmed strike"]!"))
		if(roll["critical_failure"])
			// Conservative mishap until the full advanced critical table is sourced.
			combat_commit(duration + COMBAT_TURN, left, kicking)
			event["ready_at"] = combat_action_until
			if(weapon)
				weapon.next_attack_time = combat_action_until
			if(c_intent == I_STRONG || c_intent == I_QUICK)
				combat_defenseless_until = combat_action_until
			visible_message(SPAN_WARNING("Critical failure! [src] loses the rhythm of the attack!"))
		if(kicking)
			var/list/balance = gurps_roll(max(gurps_stat(STAT_DX), combat_skill()))
			if(!balance["success"])
				Weaken(2)
				visible_message(SPAN_WARNING("[src] loses balance after the missed kick!"))
		attack_quality = null
		return TRUE
	var/damage_type = weapon ? (weapon.edge ? "cut" : (weapon.sharp ? "imp" : "cr")) : "cr"
	if(natural_attack)
		damage_type = natural_attack.edge ? "cut" : (natural_attack.sharp ? "imp" : "cr")
	var/defense = roll["critical_success"] ? null : target.combat_defend(src, weapon, zone, damage_type, feint, attack_kind)
	if(defense)
		event["outcome"] = defense
		attack_quality = null
		return TRUE
	var/basic_damage = combat_roll_damage(weapon, damage_type, roll["dice"] == 3, attack_kind)
	if(natural_attack)
		// Nonhuman natural weapons retain their content bonus through the same
		// explicit force conversion used for unprofiled equipment.
		basic_damage += round(natural_attack.get_unarmed_damage(src) / 10)
	var/list/protection = target.combat_protection(zone, damage_type)
	var/dr = weapon && weapon.deathweb_ignore_armor ? 0 : protection["dr"]
	var/penetrating = max(0, basic_damage - dr)
	var/multiplier = damage_type == "imp" ? 2 : (damage_type == "cut" ? 1.5 : 1)
	// Named advanced-location profile; see provenance/remaining verification.
	if(zone in list(BP_HEAD, BP_EYES))
		multiplier = 4
	else if(zone == BP_VITALS && damage_type == "imp")
		multiplier = 3
	else if(zone == BP_THROAT && damage_type == "cut")
		multiplier = 2
	else if(zone in list(BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG, BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT))
		multiplier = 1
	var/injury = round(penetrating * multiplier)
	event["basic_damage"] = basic_damage
	event["dr"] = dr
	event["injury"] = injury
	event["outcome"] = injury ? "injury" : (dr ? "armor" : "glancing blow")
	if(!penetrating)
		if(dr)
			target.visible_message(SPAN_NOTICE("[target]'s armor stops [src]'s strike with [weapon ? weapon : "bare hands"]!"))
		else
			target.visible_message(SPAN_NOTICE("[src]'s glancing blow fails to injure [target]."))
	else
		var/location_name = combat_location_name(zone)
		if(location_name == zone)
			location_name = O.name
		if(natural_attack)
			natural_attack.show_attack(src, target, zone, injury)
		else
			target.visible_message("<span class='combat'>[src] [attack_quality] [weapon ? weapon.get_attack_name() : "kicks"] [target]'s [location_name] with [weapon ? weapon : "a foot"]!</span>")
		if(natural_attack && natural_attack.deal_halloss)
			target.apply_damage(injury * target.maxHealth / max(1, target.gurps_stat(STAT_HT)), PAIN, zone, 0)
		else
			target.combat_apply_injury(injury, zone, damage_type, weapon)
		if(target != src)
			complete_sanity_crisis(SANITY_CRISIS_HARM_OTHER)
		if(weapon)
			target.attack_bloody(weapon, src, injury * 10, zone)
		if(weapon && weapon.hitsound)
			playsound(target, weapon.hitsound, 50, 1, -1)
		else
			playsound(target, 'sound/weapons/punch1.ogg', 50, 1)
	if(weapon)
		weapon.deathweb_wear_weapon(!penetrating)
	if(dr && basic_damage)
		for(var/obj/item/clothing/C in protection["layers"])
			C.deathweb_wear_armor()
	attack_quality = null
	return TRUE
