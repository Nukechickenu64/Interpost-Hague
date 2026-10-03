// Generic damage proc (slimes and monkeys).
/atom/proc/attack_generic(mob/user as mob)
	return 0

/*
	Humans:
	Adds an exception for gloves, to allow special glove types like the ninja ones.

	Otherwise pretty standard.
*/
/mob/living/carbon/human/UnarmedAttack(var/atom/A, var/proximity)

	if(!..())
		return

	// Special glove functions:
	// If the gloves do anything, have them return 1 to stop
	// normal attack_hand() here.
	var/obj/item/clothing/gloves/G = gloves // not typecast specifically enough in defines
	if(istype(G) && G.Touch(A,1))
		return

	A.attack_hand(src)

/atom/proc/attack_hand(mob/user as mob)
	return

// Right-click primary interaction. Default behavior mirrors attack_hand; override on specific types as needed.
/atom/proc/attack_hand_right(mob/user as mob)
	if(!Adjacent(user))
		return
	return attack_hand(user)

/obj/var/preferred_right_click_verb

/obj/proc/get_right_click_verbs()
	var/static/list/supported_verbs = list(
		/obj/machinery/bodyscanner/verb/eject,
		/obj/machinery/dna_scannernew/verb/eject,
		/obj/machinery/dnaforensics/verb/toggle_lid,
		/obj/machinery/recharge_station/verb/move_eject,
		/obj/machinery/iv_drip/verb/toggle_mode,
		/obj/machinery/papershredder/verb/empty_contents,
		/obj/item/device/flashlight/lamp/verb/toggle_light,
		/obj/structure/closet/verb/verb_toggleopen,
		/obj/structure/bed/chair/verb/rotate,
		/obj/structure/ore_box/verb/empty_box,
		/obj/structure/flora/verb/collect_purchase
	)
	return supported_verbs

/obj/proc/select_right_click_verb()
	if(!isturf(loc))
		return
	var/list/supported_verbs = get_right_click_verbs()
	var/best_owner
	var/list/best_verbs = list()
	for(var/verb_path in verbs)
		if(!(verb_path in supported_verbs) || verb_path:invisibility || verb_path:category != "Object")
			continue
		var/path_text = "[verb_path]"
		var/verb_separator = findtext(path_text, "/verb/")
		if(!verb_separator)
			continue
		var/owner_type = text2path(copytext(path_text, 1, verb_separator))
		if(!ispath(type, owner_type))
			continue
		var/verb_name = copytext(path_text, verb_separator + 6)
		if(verb_name in list("examine", "use", "use_right", "pull", "context_give", "context_bite"))
			continue
		if(verb_path == preferred_right_click_verb)
			return verb_path
		if(!best_owner || (owner_type != best_owner && ispath(owner_type, best_owner)))
			best_owner = owner_type
			best_verbs.Cut()
		if(owner_type == best_owner)
			best_verbs[verb_name] = verb_path
	if(best_verbs.len == 1)
		return best_verbs[best_verbs[1]]

/obj/attack_hand_right(mob/user as mob)
	var/verb_path = select_right_click_verb()
	if(!verb_path)
		return ..()
	if(!user || user != usr || QDELETED(src) || QDELETED(user))
		return TRUE
	if(!isliving(user) || !isturf(user.loc) || !user.canClick() || user.incapacitated() || user.restrained() || user.lying)
		return TRUE
	if(!Adjacent(user) || !(src in view(1, user)))
		return TRUE
	if(!(verb_path in verbs))
		return TRUE
	call(src, verb_path)()
	return TRUE

/mob/proc/attack_empty_hand(var/bp_hand)
	return

/mob/living/carbon/human/RestrainedClickOn(var/atom/A)
	return

/mob/living/carbon/human/RangedAttack(var/atom/A)
	//Climbing up open spaces
	if((istype(A, /turf/simulated/floor) || istype(A, /turf/unsimulated/floor) || istype(A, /obj/structure/lattice) || istype(A, /obj/structure/catwalk)) && isturf(loc) && bound_overlay && !is_physically_disabled()) //Climbing through openspace
		return climb_up(A)

	if(gloves)
		var/obj/item/clothing/gloves/G = gloves
		if(istype(G) && G.Touch(A,0)) // for magic gloves
			return TRUE

	. = ..()

/mob/living/RestrainedClickOn(var/atom/A)
	return

/*
	Aliens
*/

/mob/living/carbon/alien/RestrainedClickOn(var/atom/A)
	return

/mob/living/carbon/alien/UnarmedAttack(var/atom/A, var/proximity)

	if(!..())
		return 0

	setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	A.attack_generic(src,rand(5,6),"bitten")

/*
	Slimes
	Nothing happening here
*/

/mob/living/carbon/slime/RestrainedClickOn(var/atom/A)
	return

/mob/living/carbon/slime/UnarmedAttack(var/atom/A, var/proximity)

	if(!..())
		return

	// Eating
	if(Victim)
		if (Victim == A)
			Feedstop()
		return

	//should have already been set if we are attacking a mob, but it doesn't hurt and will cover attacking non-mobs too
	setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	var/mob/living/M = A
	if(!istype(M))
		A.attack_generic(src, (is_adult ? rand(20,40) : rand(5,25)), "glomped") // Basic attack.
	else
		var/power = max(0, min(10, (powerlevel + rand(0, 3))))

		switch(src.a_intent)
			if (I_HELP) // We just poke the other
				M.visible_message("<span class='notice'>[src] gently pokes [M]!</span>", "<span class='notice'>[src] gently pokes you!</span>")
			if (I_DISARM) // We stun the target, with the intention to feed
				var/stunprob = 1

				if (powerlevel > 0 && !istype(A, /mob/living/carbon/slime))
					switch(power * 10)
						if(0) stunprob *= 10
						if(1 to 2) stunprob *= 20
						if(3 to 4) stunprob *= 30
						if(5 to 6) stunprob *= 40
						if(7 to 8) stunprob *= 60
						if(9) 	   stunprob *= 70
						if(10) 	   stunprob *= 95

				if(prob(stunprob))
					var/shock_damage = max(0, powerlevel-3) * rand(6,10)
					M.electrocute_act(shock_damage, src, 1.0, ran_zone())
				else if(prob(40))
					M.visible_message("<span class='danger'>[src] has pounced at [M]!</span>", "<span class='danger'>[src] has pounced at you!</span>")
					M.Weaken(power)
				else
					M.visible_message("<span class='danger'>[src] has tried to pounce at [M]!</span>", "<span class='danger'>[src] has tried to pounce at you!</span>")
				M.updatehealth()
			if (I_GRAB) // We feed
				Wrap(M)
			if (I_HURT) // Attacking
				if(iscarbon(M) && prob(15))
					M.visible_message("<span class='danger'>[src] has pounced at [M]!</span>", "<span class='danger'>[src] has pounced at you!</span>")
					M.Weaken(power)
				else
					A.attack_generic(src, (is_adult ? rand(20,40) : rand(5,25)), "glomped")

/*
	New Players:
	Have no reason to click on anything at all.
*/
/mob/new_player/ClickOn()
	return

/*
	Animals
*/
/mob/living/simple_animal/UnarmedAttack(var/atom/A, var/proximity)

	if(!..())
		return
	if(istype(A,/mob/living))
		if(melee_damage_upper == 0)
			custom_emote(1,"[friendly] [A]!")
			return
		if(ckey)
			admin_attack_log(src, A, "Has [attacktext] its victim.", "Has been [attacktext] by its attacker.", attacktext)
	setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	var/damage = rand(melee_damage_lower, melee_damage_upper)
	if(A.attack_generic(src, damage, attacktext, environment_smash, damtype, defense) && loc && attack_sound)
		playsound(loc, attack_sound, 50, 1, 1)
