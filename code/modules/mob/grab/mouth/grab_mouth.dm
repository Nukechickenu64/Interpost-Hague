/obj/item/grab/mouth
	type_name = GRAB_MOUTH
	start_grab_name = GRAB_MOUTH
	name = "mouth grab"
	desc = "A bite hold. Click the top to bite down; with fangs embedded, either half feeds as a leech. Right-click to drop the hold."
	slot_flags = SLOT_MASK
	var/leech_bite_in_progress = FALSE
	var/leech_fangs_inserted = FALSE
	var/obj/item/grab/mouth_cover/linked_grab // Set when this bite hold was granted by someone's hand covering our mouth.

/obj/item/grab/mouth/pre_check()
	if(!assailant || !affecting)
		return FALSE
	if(assailant.wear_mask)
		to_chat(assailant, "<span class='warning'>You need to remove your mask before biting.</span>")
		return FALSE
	if(!mob_can_equip(assailant, slot_wear_mask, TRUE))
		to_chat(assailant, "<span class='warning'>You cannot wear a bite hold right now.</span>")
		return FALSE
	if(!assailant.check_has_mouth() || assailant.check_mouth_coverage())
		return FALSE
	var/obj/item/organ/external/head/head = assailant.get_organ(BP_HEAD)
	if(!head || !head.get_teeth())
		return FALSE
	var/obj/item/organ/external/target_organ = affecting.get_organ(target_zone)
	if(!target_organ || target_organ.is_stump())
		return FALSE
	return TRUE

/obj/item/grab/mouth/init()
	if(!assailant.equip_to_slot_if_possible(src, slot_wear_mask, 0, 1))
		to_chat(assailant, "<span class='warning'>You cannot wear a bite hold right now.</span>")
		qdel(src)
		return
	..()
	if(QDELETED(src))
		return
	if(affecting.w_uniform)
		affecting.w_uniform.add_fingerprint(assailant)
	affecting.grabbed_by += src
	var/obj/item/organ/external/target_organ = get_targeted_organ()
	if(linked_grab)
		to_chat(assailant, "<span class='notice'>[affecting]'s [target_organ.name] is right against your teeth!.</span>")
		return
	assailant.do_attack_animation(affecting)
	visible_message("<span class='combat'>[assailant] keeps their teeth clamped around [affecting]'s [target_organ.name]!</span>")

/obj/item/grab/mouth/Destroy()
	if(linked_grab)
		if(linked_grab.counter_bite == src)
			linked_grab.counter_bite = null
		linked_grab = null
	return ..()

// A counter-bite sits on the hand covering our mouth, so it must not drag either mob around.
/obj/item/grab/mouth/adjust_position(var/force = 0)
	if(!linked_grab)
		return ..()
	if(!assailant || !affecting || !assailant.Adjacent(affecting))
		qdel(src)
		return 0
	return 1

/obj/item/grab/mouth/reset_position()
	if(!linked_grab)
		return ..()

/obj/item/grab/mouth/update_icons()
	..()
	if(!assailant?.can_use_leech_fangs())
		leech_fangs_inserted = FALSE
	icon_state = leech_fangs_inserted ? "feed" : "bite"

/obj/item/grab/mouth/proc/handle_hud_click(mob/user, params)
	if(user != assailant || !user.canClick() || user.incapacitated())
		return FALSE
	var/list/modifiers = params2list(params)
	if(modifiers["middle"] || modifiers["shift"] || modifiers["ctrl"] || modifiers["alt"])
		return FALSE
	if(modifiers["right"])
		release_bite(user)
		return TRUE
	var/icon/control_icon = icon(src.icon, src.icon_state, src.dir)
	var/icon_y = text2num(modifiers["icon-y"])
	if(icon_y && icon_y <= control_icon.Height() / 2)
		feed(user)
	else
		bite_down()
	return TRUE

/obj/item/grab/mouth/proc/release_bite(mob/user)
	if(user == assailant)
		visible_message("<span class='notice'>[assailant] releases their bite on [affecting].</span>")
		assailant.drop_from_inventory(src)

/obj/item/grab/mouth/worn_use(mob/user)
	release_bite(user)

/obj/item/grab/mouth/attack_hand_right(mob/user)
	release_bite(user)

/datum/grab/mouth
	type_name = GRAB_MOUTH
	state_name = GRAB_MOUTH
	fancy_desc = "holding"
	icon = 'icons/mob/screen/os13.dmi'
	icon_state = "bite"
	shift = 8
	stop_move = 0
	same_tile = 0
	can_absorb = 0
	shield_assailant = 0
	point_blank_mult = 1
	break_chance_table = list(15, 60, 100)
	action_cooldown = 10

/datum/grab/mouth/attack_self_act(var/obj/item/grab/mouth/G)
	G.bite_down()

/datum/grab/mouth/process_effect(var/obj/item/grab/mouth/G)
	var/mob/living/carbon/human/assailant = G.assailant
	var/mob/living/carbon/human/affecting = G.affecting
	if(!assailant || !affecting || !assailant.Adjacent(affecting) || !assailant.check_has_mouth() || assailant.check_mouth_coverage())
		qdel(G)
		return
	if(G.linked_grab && (QDELETED(G.linked_grab) || G.linked_grab.assailant != affecting || G.linked_grab.affecting != assailant))
		qdel(G)
		return
	G.update_icons()

/obj/item/grab/mouth/proc/bite_down(var/initial_attempt = FALSE)
	if(!assailant || !affecting || !assailant.Adjacent(affecting))
		qdel(src)
		return
	if(!initial_attempt && world.time < last_action + 10)
		to_chat(assailant, "<span class='notice'>You need a moment before biting down again.</span>")
		return
	var/obj/item/organ/external/head/head = assailant.get_organ(BP_HEAD)
	var/obj/item/organ/external/target_organ = get_targeted_organ()
	if(!head || !head.get_teeth() || !target_organ || target_organ.is_stump())
		qdel(src)
		return
	if(assailant.mind?.is_leech())
		if(!assailant.can_use_leech_fangs())
			leech_fangs_inserted = FALSE
			to_chat(assailant, "<span class='warning'>You need to extend your fangs before biting down.</span>")
			return FALSE
		if(leech_fangs_inserted)
			return feed(assailant)
		if(assailant.incapacitated() || affecting == assailant)
			return FALSE
	var/datum/unarmed_attack/bite/bite_attack
	for(var/datum/unarmed_attack/attack in assailant.species.unarmed_attacks)
		if(istype(attack, /datum/unarmed_attack/bite) && attack.is_usable(assailant, affecting, target_zone))
			bite_attack = attack
			break
	if(!bite_attack)
		to_chat(assailant, "<span class='warning'>You cannot get a proper bite through your current gear.</span>")
		return
	var/bite_delay = assailant.is_leech() ? 10 : bite_attack.delay
	if(initial_attempt && world.time < assailant.last_attack + bite_delay)
		to_chat(assailant, "<span class='notice'>You can't bite again so soon.</span>")
		return
	if(initial_attempt)
		assailant.last_attack = world.time + 2
		assailant.set_special_action_cooldown(assailant.last_attack + bite_delay)
	assailant.adjustStaminaLoss(rand(2, 4))
	var/skill_requirement = 45
	if(assailant.c_intent == I_QUICK)
		skill_requirement = 55
	else if(assailant.c_intent == I_STRONG)
		skill_requirement = 65
	var/bite_result = assailant.skillcheck(assailant.skills["melee"], skill_requirement, null, "melee")
	if(!bite_result || bite_result == CRIT_FAILURE)
		visible_message("<span class='warning'>[assailant] tries to bite [affecting], but misses.</span>")
		playsound(affecting.loc, 'sound/weapons/punchmiss.ogg', 50, 1)
		if(bite_result == CRIT_FAILURE)
			to_chat(assailant, "<span class='danger'>Your teeth jar painfully against your target.</span>")
			assailant.apply_effect(5, PAIN)
		return
	if(affecting.try_guard_block(assailant) || affecting.attempt_dodge(assailant))
		return
	var/damage = rand(0, 2) + strToDamageModifier(assailant.combat_strength()) + bite_attack.get_unarmed_damage()
	if(assailant.a_intent == I_HURT)
		damage += 2
	if(assailant.c_intent == I_STRONG)
		damage += max(1, strToDamageModifier(assailant.combat_strength()))
	else if(assailant.c_intent == I_QUICK)
		damage = max(1, damage - 1)
	if(bite_result == CRIT_SUCCESS)
		damage += 2
	damage = bite_attack.ensure_nonzero_damage(damage)
	var/bite_zone = assailant.is_leech() && target_zone == BP_THROAT ? BP_CHEST : target_zone
	var/armour = affecting.run_armor_check(bite_zone, "melee")
	var/bite_damage_flags = bite_attack.damage_flags()
	if(assailant.is_leech())
		if(armour >= 100)
			to_chat(assailant, "<span class='warning'>You cannot reach blood through [affecting]'s armor.</span>")
			return FALSE
		damage += 5
		bite_damage_flags |= DAM_SHARP
		leech_fangs_inserted = TRUE
		icon_state = "feed"
	bite_attack.show_attack(assailant, affecting, target_zone, damage)
	bite_attack.apply_effects(assailant, affecting, armour, damage, target_zone)
	affecting.apply_damage(damage, BRUTE, bite_zone, armour, damage_flags = bite_damage_flags, used_weapon = "bite")
	affecting.receive_damage()
	admin_attack_log(assailant, affecting, "Bit their victim.", "Was bitten by [assailant].", "bit")
	last_action = world.time
	return TRUE

/obj/item/grab/mouth/proc/feed(mob/user)
	if(user != assailant || !assailant || !affecting)
		return FALSE
	if(!assailant.is_leech())
		to_chat(user, "<span class='warning'>You cannot feed through a bite without fangs.</span>")
		return FALSE
	if(!leech_fangs_inserted || !assailant.can_use_leech_fangs())
		to_chat(user, "<span class='warning'>Bite down with your extended fangs before feeding.</span>")
		return FALSE
	if(leech_bite_in_progress)
		return FALSE
	if(world.time < last_action + 10)
		to_chat(user, "<span class='notice'>You need a moment before feeding again.</span>")
		return FALSE
	leech_bite_in_progress = TRUE
	var/feed_succeeded = assailant.leech_drain_bite(affecting, target_zone)
	if(QDELETED(src))
		return FALSE
	leech_bite_in_progress = FALSE
	if(feed_succeeded)
		last_action = world.time
	return feed_succeeded