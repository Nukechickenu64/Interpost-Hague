/obj/item/grab/mouth
	type_name = "mouth"
	name = "mouth grab"
	desc = "A bite hold. Left-click to bite down; right-click to release."
	icon = 'icons/mob/screen1.dmi'
	icon_state = "reinforce"
	slot_flags = SLOT_MASK

/obj/item/grab/mouth/pre_check()
	if(!assailant || !affecting)
		return FALSE
	if(!assailant.check_has_mouth() || assailant.check_mouth_coverage())
		return FALSE
	var/obj/item/organ/external/head/head = assailant.get_organ(BP_HEAD)
	if(!head || !head.get_teeth())
		return FALSE
	if(!affecting.get_organ(target_zone))
		return FALSE
	return TRUE

/obj/item/grab/mouth/init()
	if(affecting.w_uniform)
		affecting.w_uniform.add_fingerprint(assailant)
	assailant.equip_to_slot(src, slot_wear_mask)
	affecting.grabbed_by += src
	assailant.do_attack_animation(affecting)
	visible_message("<span class='combat'>[assailant] clamps their teeth around [affecting]'s [get_targeted_organ().name]!</span>")

/obj/item/grab/mouth/Process()
	if(!assailant || !affecting || !assailant.Adjacent(affecting) || !assailant.check_has_mouth() || assailant.check_mouth_coverage())
		qdel(src)

/obj/item/grab/mouth/attack_hand(mob/user)
	if(user == assailant)
		bite_down()

/obj/item/grab/mouth/attack_hand_right(mob/user)
	if(user == assailant)
		visible_message("<span class='notice'>[assailant] releases their bite on [affecting].</span>")
		qdel(src)

/obj/item/grab/mouth/proc/bite_down()
	if(!assailant || !affecting || !assailant.Adjacent(affecting))
		qdel(src)
		return
	if(world.time < last_action + 10)
		to_chat(assailant, "<span class='notice'>You need a moment before biting down again.</span>")
		return
	var/obj/item/organ/external/head/head = assailant.get_organ(BP_HEAD)
	var/obj/item/organ/external/target_organ = get_targeted_organ()
	if(!head || !head.get_teeth() || !target_organ)
		qdel(src)
		return
	if(assailant.mind?.is_leech())
		if(assailant.leech_drain_bite(affecting, target_zone))
			last_action = world.time
		return
	var/datum/unarmed_attack/bite/bite_attack
	for(var/datum/unarmed_attack/attack in assailant.species.unarmed_attacks)
		if(istype(attack, /datum/unarmed_attack/bite) && attack.is_usable(assailant, affecting, target_zone))
			bite_attack = attack
			break
	if(!bite_attack)
		to_chat(assailant, "<span class='warning'>You cannot get a proper bite through your current gear.</span>")
		return
	var/skill_requirement = 45
	if(assailant.c_intent == I_QUICK)
		skill_requirement = 55
	else if(assailant.c_intent == I_STRONG)
		skill_requirement = 65
	var/bite_result = assailant.skillcheck(assailant.skills["melee"], skill_requirement, null, "melee")
	if(!bite_result || bite_result == CRIT_FAILURE)
		visible_message("<span class='warning'>[assailant] fails to get a firm bite on [affecting]!</span>")
		if(bite_result == CRIT_FAILURE)
			to_chat(assailant, "<span class='danger'>Your teeth jar painfully against your target.</span>")
			assailant.apply_effect(5, PAIN)
		qdel(src)
		return
	var/damage = rand(1, 5) + strToDamageModifier(assailant.stats[STAT_ST]) + bite_attack.get_unarmed_damage()
	if(assailant.a_intent == I_HURT)
		damage += 2
	if(assailant.c_intent == I_STRONG)
		damage += max(1, strToDamageModifier(assailant.stats[STAT_ST]))
	else if(assailant.c_intent == I_QUICK)
		damage = max(1, damage - 1)
	if(bite_result == CRIT_SUCCESS)
		damage += 2
	var/armour = affecting.run_armor_check(target_zone, "melee")
	bite_attack.show_attack(assailant, affecting, target_zone, damage)
	bite_attack.apply_effects(assailant, affecting, armour, damage, target_zone)
	affecting.apply_damage(damage, BRUTE, target_zone, armour, bite_attack.damage_flags(), "bite")
	if(target_zone == BP_HEAD && armour <= 0)
		target_organ.sever_artery()
	affecting.receive_damage()
	admin_attack_log(assailant, affecting, "Bit their victim with a mouth grab.", "Was bitten by a mouth grab.", "bit")
	last_action = world.time