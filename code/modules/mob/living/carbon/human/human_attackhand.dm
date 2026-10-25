/mob/living/carbon/human/proc/get_unarmed_attack(var/mob/living/carbon/human/target, var/hit_zone)
	for(var/datum/unarmed_attack/u_attack in species.unarmed_attacks)
		if(is_leech() && istype(u_attack, /datum/unarmed_attack/bite) && !can_use_leech_fangs())
			continue
		if(u_attack.is_usable(src, target, hit_zone))
			if(pulling_punches)
				var/datum/unarmed_attack/soft_variant = u_attack.get_sparring_variant()
				if(soft_variant)
					return soft_variant
			return u_attack
	return null

/mob/living/carbon/human/attack_hand(mob/living/carbon/M as mob)
	if(M == src && zone_sel.selecting == BP_MOUTH && mouth_item)
		var/obj/item/item_to_remove = mouth_item
		mouth_item = null
		update_inv_wear_mask()
		visible_message("<span class='notice'>[src] takes [item_to_remove] out of [src]'s mouth.</span>")
		if(!put_in_hands(item_to_remove))
			item_to_remove.forceMove(loc)
			update_icons()
		return 1

	var/mob/living/carbon/human/H = M
	if(istype(H))
		var/obj/item/organ/external/temp = H.organs_by_name[BP_R_HAND]
		if(H.hand)
			temp = H.organs_by_name[BP_L_HAND]
		if(!temp || (!temp.is_usable() && !M.nabbing))
			to_chat(H, "<span class='warning'>You can't use your hand.</span>")
			return

	..()

	// Should this all be in Touch()?
	if(istype(H))
		if(H.a_intent != I_HURT && H.a_intent != I_GRAB && H != src && check_shields(0, null, H, H.zone_sel.selecting, H.name))
			H.do_attack_animation(src)
			return 0

		if(istype(H.gloves, /obj/item/clothing/gloves/boxing/hologlove))
			H.do_attack_animation(src)
			var/damage = rand(0, 9)
			if(!damage)
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
				visible_message("<span class='danger'>\The [H] has attempted to punch \the [src]!</span>")
				return 0
			var/obj/item/organ/external/affecting = get_organ(ran_zone(H.zone_sel.selecting))
			var/armor_block = run_armor_check(affecting, "melee")

			if(HULK in H.mutations)
				damage += 5

			playsound(loc, "punch", 25, 1, -1)

			update_personal_goal(/datum/goal/achievement/fistfight, TRUE)
			H.update_personal_goal(/datum/goal/achievement/fistfight, TRUE)

			visible_message("<span class='danger'>[H] has punched \the [src]!</span>")

			var/hologlove_harm_before = getBruteLoss() + getFireLoss() + getHalLoss()
			apply_damage(damage, PAIN, affecting, armor_block)
			if(H != src && getBruteLoss() + getFireLoss() + getHalLoss() > hologlove_harm_before)
				H.complete_sanity_crisis(SANITY_CRISIS_HARM_OTHER)
			if(damage >= 9)
				visible_message("<span class='danger'>[H] has weakened \the [src]!</span>")
				apply_effect(4, WEAKEN, armor_block)

			return

	if(istype(M,/mob/living/carbon))
		M.spread_disease_to(src, "Contact")

	if(istype(H))
		for (var/obj/item/grab/G in H)
			if (G.assailant == H && G.affecting == src)
				if(G.resolve_openhand_attack())
					return 1


	switch(M.a_intent)
		if(I_HELP)
			if(istype(H) && (is_asystole() || (status_flags & FAKEDEATH)))
				if (!cpr_time)
					return 0

				cpr_time = 0
				spawn(30)
					cpr_time = 1

				H.visible_message("<span class='notice'>\The [H] is trying to perform CPR on \the [src].</span>")

				if(!do_after(H, 30, src))
					return

				H.visible_message("<span class='notice'>\The [H] performs CPR on \the [src]!</span>")
				if(prob(20 - usr.stats[STAT_IQ]))
					var/obj/item/organ/external/chest = get_organ(BP_CHEST)
					if(chest)
						chest.fracture()
				if(stat != DEAD)
					if(prob(H.skills[SKILL_MED]))
						resuscitate()

					if(!H.check_has_mouth())
						to_chat(H, "<span class='warning'>You don't have a mouth, you cannot do mouth-to-mouth resustication!</span>")
						return
					if(!check_has_mouth())
						to_chat(H, "<span class='warning'>They don't have a mouth, you cannot do mouth-to-mouth resustication!</span>")
						return
					if((H.head && (H.head.body_parts_covered & FACE)) || (H.wear_mask && (H.wear_mask.body_parts_covered & FACE)))
						to_chat(H, "<span class='warning'>You need to remove your mouth covering for mouth-to-mouth resustication!</span>")
						return 0
					if((head && (head.body_parts_covered & FACE)) || (wear_mask && (wear_mask.body_parts_covered & FACE)))
						to_chat(H, "<span class='warning'>You need to remove \the [src]'s mouth covering for mouth-to-mouth resustication!</span>")
						return 0
					if (!H.internal_organs_by_name[H.species.breathing_organ])
						to_chat(H, "<span class='danger'>You need lungs for mouth-to-mouth resustication!</span>")
						return
					if(!need_breathe())
						return
					var/obj/item/organ/internal/lungs/L = internal_organs_by_name[species.breathing_organ]
					if(L)
						var/datum/gas_mixture/breath = H.get_breath_from_environment()
						var/fail = L.handle_breath(breath, 1)
						if(!fail)
							to_chat(src, "<span class='notice'>You feel a breath of fresh air enter your lungs. It feels good.</span>")

			else if(!(M == src && apply_pressure(M, M.zone_sel.selecting)))
				help_shake_act(M)
			return 1

		if(I_GRAB)
			visible_message("<span class='danger'>[M] attempted to grab \the [src]!</span>")
			if(istype(H))

				var/obj/item/organ/external/affecting = get_organ(H.zone_sel.selecting)
				if(!affecting || affecting.is_stump())
					to_chat(H, "There is nothing to grab!")
					return
				if(M != src)
					if(!H.combat_attempt_grab(src, H.zone_sel.selecting))
						return

				switch(H.zone_sel.selecting)
					//Strangling
					if(BP_THROAT)
						return H.make_grab(H, src, GRAB_STRANGLE)

					//Covering the mouth
					if(BP_MOUTH)
						return H.make_grab(H, src, GRAB_MOUTH_COVER)

					//Wrenching
					if(BP_FACE)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_L_LEG)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_R_LEG)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_L_HAND)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_R_HAND)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_HEAD)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_R_FOOT)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_L_FOOT)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_L_ARM)
						return H.make_grab(H, src, GRAB_WRENCH)
					if(BP_R_ARM)
						return H.make_grab(H, src, GRAB_WRENCH)

					//Tackling?
					if(BP_CHEST)
						return H.make_grab(H, src, GRAB_TAKEDOWN)
					if(BP_GROIN)
						return H.make_grab(H, src, GRAB_TAKEDOWN)

			return H.make_grab(H, src)


		if(I_HURT)
			if(!istype(H))
				attack_generic(M, rand(1,3), "punched")
				return
			return H.perform_combat_strike(src, null, H.zone_sel.selecting)

		if(I_DISARM)
			if(H.species)
				admin_attack_log(M, src, "Disarmed their victim.", "Was disarmed.", "disarmed")
				H.species.disarm_attackhand(H, src)

			if(M != src)
				if(try_guard_block(H) || attempt_dodge(H))//Trying to dodge or block before they even have the chance to miss us.
					return

	return

/mob/living/carbon/human/proc/afterattack(atom/target as mob|obj|turf|area, mob/living/user as mob|obj, inrange, params)
	return

/mob/living/carbon/human/attack_generic(var/mob/user, var/damage, var/attack_message, var/environment_smash, var/damtype = BRUTE, var/armorcheck = "melee")

	if(!damage || !istype(user))
		return
	if(istype(user, /mob/living/simple_animal))
		var/mob/living/simple_animal/animal_attacker = user
		if(!animal_attacker.gurps_melee_attack_check(src))
			return 0
	admin_attack_log(user, src, "Attacked their victim", "Was attacked", "has [attack_message]")
	src.visible_message("<span class='danger'>[user] has [attack_message] [src]!</span>")
	user.do_attack_animation(src)

	var/dam_zone = pick(organs_by_name)
	var/obj/item/organ/external/affecting = get_organ(ran_zone(dam_zone))
	var/armor_block = run_armor_check(affecting, armorcheck)
	var/harm_before = getBruteLoss() + getFireLoss() + getHalLoss()
	apply_damage(damage, damtype, affecting, armor_block)
	if(istype(user, /mob/living/carbon/human) && getBruteLoss() + getFireLoss() + getHalLoss() > harm_before)
		var/mob/living/carbon/human/attacker = user
		if(attacker != src)
			attacker.complete_sanity_crisis(SANITY_CRISIS_HARM_OTHER)
	updatehealth()
	return 1

//Breaks all grips and pulls that the mob currently has.
/mob/living/carbon/human/proc/break_all_grabs(mob/living/carbon/user)
	var/success = 0
	if(pulling)
		visible_message("<span class='danger'>[user] has broken [src]'s grip on [pulling]!</span>")
		success = 1
		stop_pulling()

	if(istype(l_hand, /obj/item/grab))
		var/obj/item/grab/lgrab = l_hand
		if(lgrab.affecting)
			visible_message("<span class='danger'>[user] has broken [src]'s grip on [lgrab.affecting]!</span>")
			success = 1
		spawn(1)
			qdel(lgrab)
	if(istype(r_hand, /obj/item/grab))
		var/obj/item/grab/rgrab = r_hand
		if(rgrab.affecting)
			visible_message("<span class='danger'>[user] has broken [src]'s grip on [rgrab.affecting]!</span>")
			success = 1
		spawn(1)
			qdel(rgrab)
	return success
/*
	We want to ensure that a mob may only apply pressure to one organ of one mob at any given time. Currently this is done mostly implicitly through
	the behaviour of do_after() and the fact that applying pressure to someone else requires a grab:
	If you are applying pressure to yourself and attempt to grab someone else, you'll change what you are holding in your active hand which will stop do_mob()
	If you are applying pressure to another and attempt to apply pressure to yourself, you'll have to switch to an empty hand which will also stop do_mob()
	Changing targeted zones should also stop do_mob(), preventing you from applying pressure to more than one body part at once.
*/
/mob/living/carbon/human/proc/apply_pressure(mob/living/user, var/target_zone)
	var/obj/item/organ/external/organ = get_organ(target_zone)
	if(!organ || !(organ.status & ORGAN_BLEEDING) || (organ.robotic >= ORGAN_ROBOT))
		return 0

	if(organ.applied_pressure)
		var/message = "<span class='warning'>[ismob(organ.applied_pressure)? "Someone" : "\A [organ.applied_pressure]"] is already applying pressure to [user == src? "your [organ.name]" : "[src]'s [organ.name]"].</span>"
		to_chat(user, message)
		return 0

	if(user == src)
		user.visible_message("\The [user] starts applying pressure to \his [organ.name]!", "You start applying pressure to your [organ.name]!")
	else
		user.visible_message("\The [user] starts applying pressure to [src]'s [organ.name]!", "You start applying pressure to [src]'s [organ.name]!")
	spawn(0)
		organ.applied_pressure = user

		// Movement does not interrupt self-treatment; hand and target-zone changes still end the hold.
		do_mob(user, src, INFINITY, target_zone, progress = 0, movement_interrupt = (user != src))

		organ.applied_pressure = null

		if(user == src)
			user.visible_message("\The [user] stops applying pressure to \his [organ.name]!", "You stop applying pressure to your [organ.name]!")
		else
			user.visible_message("\The [user] stops applying pressure to [src]'s [organ.name]!", "You stop applying pressure to [src]'s [organ.name]!")

	return 1
