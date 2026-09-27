#define JOLT_MAX_STRENGTH 10
#define JOLT_COOLDOWN 1 SECOND

/mob/living
	var/last_jolt = 0
	var/jolt_impact = 0 //strength of the jolt currently flinging us, used for wall slam damage

// Jolts the floor around epicenter; strength (1-10) falls off with distance. Direction defaults to away from the epicenter.
/proc/floor_jolt(turf/epicenter, radius, strength, dir_override)
	epicenter = get_turf(epicenter)
	if(!epicenter || radius <= 0 || strength <= 0)
		return
	strength = min(strength, JOLT_MAX_STRENGTH)
	for(var/mob/living/L in GLOB.living_mob_list_)
		if(L.z != epicenter.z)
			continue
		var/dist = get_dist(L, epicenter)
		if(dist > radius)
			continue
		var/local_strength = round(strength * (1 - dist / (radius + 1)), 1)
		if(local_strength < 1)
			continue
		L.floor_jolt_act(dir_override ? dir_override : get_dir(epicenter, L), local_strength)

/mob/living/proc/floor_jolt_act(direction, strength)
	if(stat == DEAD || buckled || anchored || issilicon(src))
		return FALSE
	if(world.time < last_jolt + JOLT_COOLDOWN)
		return FALSE
	var/turf/T = get_turf(src)
	if(!istype(T) || loc != T || !T.is_floor() || !has_gravity(src, T))
		return FALSE
	if(Check_Shoegrip())
		to_chat(src, "<span class='warning'>The floor lurches, but your boots hold you in place!</span>")
		shake_camera(src, 3, 1)
		return FALSE

	last_jolt = world.time
	strength = clamp(strength, 1, JOLT_MAX_STRENGTH)
	if(!direction)
		direction = pick(GLOB.cardinal)

	shake_camera(src, 5 + strength, max(1, round(strength / 3)))
	visible_message("<span class='danger'>\The [src] is thrown off balance!</span>", "<span class='danger'>The floor lurches violently beneath you, throwing you off your feet!</span>")
	Weaken(round(strength / 2) + 1)

	var/range = clamp(round(strength / 2), 1, 5)
	var/speed = clamp(round(strength / 2), 1, 5)
	spawn(0)
		jolt_impact = strength
		throw_at(get_edge_target_turf(src, direction), range, speed)
		jolt_impact = 0
	return TRUE

/mob/living/proc/jolt_collision(atom/A)
	var/damage = clamp(jolt_impact * 3, 3, 30)
	adjustBruteLoss(damage)
	Weaken(round(jolt_impact / 2) + 1)
	shake_camera(src, 5, max(1, round(jolt_impact / 3)))

/mob/living/carbon/human/jolt_collision(atom/A)
	var/damage = clamp(jolt_impact * 3, 3, 30)
	var/obj/item/organ/external/E = get_organ(pick(BP_HEAD, BP_CHEST, BP_GROIN, BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG))
	if(!E)
		E = get_organ(BP_CHEST)
	apply_damage(damage, BRUTE, E ? E.organ_tag : BP_CHEST)
	if(E && jolt_impact >= 6 && prob(jolt_impact * 5))
		E.fracture()
	Weaken(round(jolt_impact / 2) + 1)
	shake_camera(src, 5, max(1, round(jolt_impact / 3)))

#undef JOLT_MAX_STRENGTH
#undef JOLT_COOLDOWN
