/decl/magic_word/magic_action/motion
	base_cost = 30
	var/motion_kind

/decl/magic_word/magic_action/motion/invoke(datum/magic_spell/S, atom/target, mob/caster)
	if(!istype(target, /atom/movable))
		return S.fail("[target] cannot be moved by words.")
	var/atom/movable/AM = target
	switch(motion_kind)
		if("disarm")
			if(!isliving(AM))
				return S.fail("[AM] holds nothing.")
			var/mob/living/L = AM
			var/dropped = 0
			for(var/obj/item/I in list(L.l_hand, L.r_hand))
				if(L.drop_from_inventory(I))
					dropped++
			if(!dropped)
				return S.fail("[L] holds nothing.")
		if("summon")
			if(!isitem(AM) || AM.anchored)
				return S.fail("[AM] will not come.")
			if(ismob(AM.loc))
				var/mob/holder = AM.loc
				if(holder == caster)
					return S.fail("[AM] is already yours.")
				holder.drop_from_inventory(AM)
			else if(!isturf(AM.loc))
				return S.fail("[AM] is shut away.")
			AM.forceMove(get_turf(caster))
			caster.put_in_hands(AM)
		if("repel")
			if(AM == caster || AM.anchored || !isturf(AM.loc))
				return S.fail("[AM] cannot be pushed away.")
			var/range = spoken_amount(S, 4, 10)
			var/turf/destination = get_ranged_target_turf(AM, get_dir(caster, AM), range)
			spawn(0)
				AM.throw_at(destination, range, 2, caster)
		if("attract")
			if(AM == caster || AM.anchored || !isturf(AM.loc))
				return S.fail("[AM] cannot be drawn in.")
			var/range = max(get_dist(AM, caster) - 1, 1)
			spawn(0)
				AM.throw_at(get_turf(caster), range, 2, caster)
		if("swap")
			if(AM == caster || AM.anchored || !isturf(AM.loc) || !isturf(caster.loc))
				return S.fail("[AM] cannot trade places with you.")
			var/turf/here = get_turf(caster)
			var/turf/there = get_turf(AM)
			magic_cast_effect(here, FALSE)
			caster.forceMove(there)
			AM.forceMove(here)
		if("duplicate")
			if(!isitem(AM) || istype(AM, /obj/item/holder) || (locate(/mob) in AM))
				return S.fail("[AM] cannot be copied.")
			new AM.type(get_turf(AM))
		if("glow")
			AM.set_light(spoken_amount(S, 4, 8), 1, "#ffffcc")
		if("darken")
			AM.set_light(0)
		if("fade")
			var/seconds = spoken_amount(S, 10, 30)
			var/old_alpha = AM.alpha
			animate(AM, alpha = 30, time = 5)
			spawn(seconds * 10)
				if(!QDELETED(AM))
					animate(AM, alpha = old_alpha, time = 5)
		if("spin")
			AM.SpinAnimation(10, spoken_amount(S, 3, 10))
		if("shake")
			AM.shake_animation(spoken_amount(S, 8, 20))
	return "[name] [AM]"

/decl/magic_word/magic_action/motion/exarmare
	name = "to disarm"
	words = list("exarmare")
	motion_kind = "disarm"
	base_cost = 35

/decl/magic_word/magic_action/motion/arcessere
	name = "to summon"
	words = list("arcessere")
	motion_kind = "summon"
	base_cost = 40

/decl/magic_word/magic_action/motion/repellere
	name = "to repel"
	words = list("repellere")
	motion_kind = "repel"
	cost_per_unit = 4

/decl/magic_word/magic_action/motion/attrahere
	name = "to draw near"
	words = list("attrahere")
	motion_kind = "attract"

/decl/magic_word/magic_action/motion/permutare
	name = "to trade places"
	words = list("permutare")
	motion_kind = "swap"
	base_cost = 60

/decl/magic_word/magic_action/motion/duplicare
	name = "to duplicate"
	words = list("duplicare")
	motion_kind = "duplicate"
	base_cost = 80

/decl/magic_word/magic_action/motion/duplicare/magic_cost(datum/magic_spell/S)
	return base_cost

/decl/magic_word/magic_action/motion/illuminare
	name = "to illuminate"
	words = list("illuminare")
	motion_kind = "glow"
	base_cost = 10
	cost_per_unit = 1
	cosmetic = TRUE

/decl/magic_word/magic_action/motion/obtenebrare
	name = "to darken"
	words = list("obtenebrare")
	motion_kind = "darken"
	base_cost = 10
	cosmetic = TRUE

/decl/magic_word/magic_action/motion/evanescere
	name = "to fade from sight"
	words = list("evanescere")
	motion_kind = "fade"
	base_cost = 30
	cost_per_unit = 2
	cosmetic = TRUE

/decl/magic_word/magic_action/motion/rotare
	name = "to spin"
	words = list("rotare")
	motion_kind = "spin"
	base_cost = 5
	cosmetic = TRUE

/decl/magic_word/magic_action/motion/quatere
	name = "to shake"
	words = list("quatere")
	motion_kind = "shake"
	base_cost = 5
	cosmetic = TRUE
