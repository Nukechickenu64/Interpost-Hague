#define INVADER_STATE_WAIT_DOCK   1
#define INVADER_STATE_SEARCH      2
#define INVADER_STATE_INVESTIGATE 3
#define INVADER_STATE_HUNT        4
#define INVADER_STATE_ENGAGE      5
#define INVADER_STATE_BREACH      6

#define INVADER_SIGHT          7
#define INVADER_SEARCH_RADIUS  60
#define INVADER_HUNT_TIMEOUT   (30 SECONDS)
#define INVADER_BREACH_TIMEOUT (60 SECONDS)

/datum/invader_ai
	var/mob/living/carbon/human/invader/owner
	var/datum/humanized_mover/mover
	var/state = INVADER_STATE_SEARCH
	// world.time until which an async action owns the mob; expires on its own if that action runtimes.
	var/busy = 0
	var/reloading_until = 0
	var/shuttle_protected = FALSE
	var/mob/living/carbon/human/target
	var/turf/last_seen_turf
	var/last_seen_time = 0
	var/reaction_at = 0
	var/next_scan = 0
	var/turf/investigate_turf
	var/release_at = 0
	var/linger_until = 0
	var/obj/machinery/door/breach_door
	var/breach_started = 0
	var/resume_state = INVADER_STATE_SEARCH
	var/list/recent_areas = list()

/datum/invader_ai/New(var/mob/living/carbon/human/invader/new_owner, var/datum/humanized_mover/new_mover)
	..()
	owner = new_owner
	mover = new_mover

/datum/invader_ai/Destroy()
	owner = null
	mover = null
	target = null
	last_seen_turf = null
	investigate_turf = null
	breach_door = null
	recent_areas = null
	return ..()

/// Hold position (with idle fidgeting) until the supply shuttle has docked at the station.
/datum/invader_ai/proc/wait_for_dock()
	state = INVADER_STATE_WAIT_DOCK
	shuttle_protected = TRUE
	owner.status_flags |= GODMODE

/// Protection lasts until the invader leaves the shuttle or starts fighting.
/datum/invader_ai/proc/check_shuttle_protection()
	if(state == INVADER_STATE_WAIT_DOCK)
		return
	if(state != INVADER_STATE_ENGAGE)
		var/datum/shuttle/autodock/ferry/supply/S = SSsupply.shuttle
		if(S && (get_area(owner) in S.shuttle_area))
			return
	shuttle_protected = FALSE
	owner.status_flags &= ~GODMODE

/datum/invader_ai/Process()
	if(QDELETED(owner) || owner.stat == DEAD || !mover)
		return PROCESS_KILL
	if(shuttle_protected)
		check_shuttle_protection()
	if(world.time < busy || owner.client || owner.stat != CONSCIOUS)
		return
	if(owner.resting && !mover.crawling)
		get_up()
		return
	if(!mover.crawling && (owner.incapacitated() || !owner.canmove))
		return
	if(owner.grabbed_by.len && prob(5))
		struggle()
		return
	if(world.time >= next_scan)
		next_scan = world.time + rand(1, 2)
		scan()
	mover.in_combat = (state == INVADER_STATE_ENGAGE || state == INVADER_STATE_HUNT)
	// Combat mode blocks stamina regen, so only hold it while actually fighting.
	owner.combat_mode = (state == INVADER_STATE_ENGAGE)
	switch(state)
		if(INVADER_STATE_WAIT_DOCK)
			wait_dock()
		if(INVADER_STATE_SEARCH)
			search()
		if(INVADER_STATE_INVESTIGATE)
			investigate()
		if(INVADER_STATE_HUNT)
			hunt()
		if(INVADER_STATE_ENGAGE)
			engage()
		if(INVADER_STATE_BREACH)
			breach()

/datum/invader_ai/proc/is_valid_target(var/mob/living/carbon/human/H)
	return istype(H) && H != owner && H.stat != DEAD && H.z == owner.z && !is_invader_ally(H)

/datum/invader_ai/proc/scan()
	var/mob/living/carbon/human/best
	var/best_score
	for(var/mob/living/carbon/human/H in view(INVADER_SIGHT, owner))
		if(!is_valid_target(H))
			continue
		var/score = get_dist(owner, H) + (H.stat ? 5 : 0) + (H == target ? -2 : 0)
		if(!best || score < best_score)
			best = H
			best_score = score
	if(best)
		if(best != target || (state != INVADER_STATE_ENGAGE && state != INVADER_STATE_HUNT))
			reaction_at = world.time
			mover.clear()
			mover.pause_until = 0
		target = best
		last_seen_turf = get_turf(best)
		last_seen_time = world.time
		breach_door = null
		release_at = 0
		state = INVADER_STATE_ENGAGE
	else if(state == INVADER_STATE_ENGAGE)
		state = INVADER_STATE_HUNT
		mover.set_goal(last_seen_turf)

/datum/invader_ai/proc/on_heard(var/mob/speaker)
	if(!is_valid_target(speaker) || state == INVADER_STATE_ENGAGE || state == INVADER_STATE_WAIT_DOCK)
		return
	mover.look_target = speaker
	if(state == INVADER_STATE_SEARCH || state == INVADER_STATE_INVESTIGATE)
		investigate_turf = get_turf(speaker)
		state = INVADER_STATE_INVESTIGATE

/datum/invader_ai/proc/on_attacked(var/mob/attacker)
	if(!is_valid_target(attacker) || state == INVADER_STATE_ENGAGE)
		return
	target = attacker
	last_seen_turf = get_turf(attacker)
	last_seen_time = world.time
	reaction_at = world.time
	breach_door = null
	state = INVADER_STATE_HUNT
	mover.set_goal(last_seen_turf)

/datum/invader_ai/proc/handle_move_result(var/result)
	switch(result)
		if(MOVER_ARRIVED, MOVER_FAILED)
			on_arrived()
		if(MOVER_BLOCKED_DOOR)
			begin_breach(mover.blocking_door)

/datum/invader_ai/proc/on_arrived()
	mover.clear()
	switch(state)
		if(INVADER_STATE_SEARCH)
			linger_until = world.time + rand(3, 10)
		if(INVADER_STATE_INVESTIGATE, INVADER_STATE_HUNT)
			investigate_turf = null
			state = INVADER_STATE_SEARCH
			linger_until = world.time + rand(3, 10)

/datum/invader_ai/proc/wait_dock()
	if(!release_at)
		var/datum/shuttle/autodock/ferry/supply/S = SSsupply.shuttle
		if(!S || (S.at_station() && S.moving_status == SHUTTLE_IDLE))
			release_at = world.time + rand(2, 10)
	if(release_at && world.time >= release_at)
		release_at = 0
		state = INVADER_STATE_SEARCH
		return
	mover.idle_tick()

/datum/invader_ai/proc/search()
	if(world.time < linger_until)
		mover.idle_tick()
		return
	if(!mover.goal)
		var/turf/T = pick_search_goal()
		if(!T)
			linger_until = world.time + 20
			return
		mover.set_goal(T)
	handle_move_result(mover.tick())

/datum/invader_ai/proc/investigate()
	if(!investigate_turf)
		state = INVADER_STATE_SEARCH
		return
	if(mover.goal != investigate_turf)
		mover.set_goal(investigate_turf, 1)
	handle_move_result(mover.tick())

/datum/invader_ai/proc/hunt()
	if(!last_seen_turf || world.time - last_seen_time > INVADER_HUNT_TIMEOUT)
		target = null
		mover.clear()
		state = INVADER_STATE_SEARCH
		return
	if(mover.goal != last_seen_turf)
		mover.set_goal(last_seen_turf)
	handle_move_result(mover.tick())

/datum/invader_ai/proc/pick_search_goal()
	var/list/areas = SSinvaders.get_station_areas()
	var/turf/here = get_turf(owner)
	if(!length(areas) || !here)
		return
	// Usually head for where people are, like following the noise of an occupied room.
	if(prob(60))
		var/list/occupied = list()
		for(var/mob/living/carbon/human/H in GLOB.human_mob_list)
			if(is_valid_target(H) && get_dist(H, here) <= INVADER_SEARCH_RADIUS)
				occupied |= get_area(H)
		if(occupied.len)
			areas = occupied
	for(var/attempt in 1 to 6)
		var/area/A = pick(areas)
		if(A in recent_areas)
			continue
		var/list/candidates = list()
		for(var/turf/simulated/floor/T in A)
			if(T.z == here.z && get_dist(T, here) <= INVADER_SEARCH_RADIUS && !T.contains_dense_objects())
				candidates += T
		if(!candidates.len)
			continue
		recent_areas += A
		if(recent_areas.len > 5)
			recent_areas.Cut(1, 2)
		return pick(candidates)

// === Combat ===

/datum/invader_ai/proc/engage()
	if(!is_valid_target(target))
		target = null
		mover.clear()
		state = INVADER_STATE_SEARCH
		return
	var/dist = get_dist(owner, target)
	var/obj/item/weapon/gun/G = get_gun()
	if(G && world.time < reloading_until)
		combat_move(dist, 3, 5)
		return
	if(G && !gun_has_ammo(G))
		if(try_reload(G))
			combat_move(dist, 3, 5)
			return
		owner.drop_from_inventory(G)
		G = null
	if(G)
		ranged_engage(G, dist)
	else
		melee_engage(dist)

/// Keeps the invader moving during a fight: close in past max_range, back off inside min_range, strafe otherwise.
/datum/invader_ai/proc/combat_move(var/dist, var/min_range, var/max_range)
	if(dist > max_range)
		var/turf/T = get_turf(target)
		if(mover.goal != T)
			mover.set_goal(T, max(1, max_range - 1))
		handle_move_result(mover.tick())
		return
	if(mover.goal)
		mover.clear()
	if(dist < min_range)
		mover.step_relative(target, TRUE)
	else if(prob(50))
		mover.step_relative(target, FALSE)

/datum/invader_ai/proc/ranged_engage(var/obj/item/weapon/gun/G, var/dist)
	select_hand(G)
	if(dist <= INVADER_SIGHT && world.time >= reaction_at && owner.canClick())
		var/atom/aim = target
		if(prob(12))
			var/turf/T = get_step(get_turf(target), pick(GLOB.alldirs))
			if(T)
				aim = T
		if(!ally_in_line_of_fire(aim))
			fire_at(aim)
	combat_move(dist, 3, 5)

/datum/invader_ai/proc/ally_in_line_of_fire(var/atom/aim)
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(aim)
	if(!here || !there)
		return FALSE
	for(var/turf/T in getline(here, there))
		if(T == here)
			continue
		for(var/mob/living/L in T)
			if(L != target && is_invader_ally(L))
				return TRUE
	// Allies standing right next to the impact point catch misses and pellets.
	for(var/mob/living/L in orange(1, there))
		if(L != owner && is_invader_ally(L))
			return TRUE
	return FALSE

/datum/invader_ai/proc/melee_engage(var/dist)
	var/obj/item/W = get_melee_weapon()
	if(W)
		select_hand(W)
	else if(!owner.r_hand)
		owner.hand = 0
	else if(!owner.l_hand)
		owner.hand = 1
	if(owner.Adjacent(target) && world.time >= reaction_at && owner.canClick() && (!W || world.time > W.next_attack_time))
		melee_attack()
	if(dist <= 1 && !owner.Adjacent(target))
		mover.step_relative(target, FALSE)
	else
		combat_move(dist, 0, 1)

/datum/invader_ai/proc/fire_at(var/atom/aim)
	set waitfor = FALSE
	owner.zone_sel.selecting = prob(80) ? BP_CHEST : pick(BP_HEAD, BP_GROIN, BP_L_LEG, BP_R_LEG)
	reaction_at = world.time + clamp(gaussian(1, 0.5), 0, 3)
	owner.ClickOn(aim, "")

/datum/invader_ai/proc/melee_attack()
	set waitfor = FALSE
	owner.zone_sel.selecting = prob(70) ? BP_CHEST : pick(BP_HEAD, BP_GROIN, BP_L_ARM, BP_R_ARM)
	reaction_at = world.time + clamp(gaussian(0.5, 0.5), 0, 2)
	owner.ClickOn(target, "")

/datum/invader_ai/proc/get_gun()
	if(istype(owner.r_hand, /obj/item/weapon/gun))
		return owner.r_hand
	if(istype(owner.l_hand, /obj/item/weapon/gun))
		return owner.l_hand

/datum/invader_ai/proc/gun_has_ammo(var/obj/item/weapon/gun/G)
	if(istype(G, /obj/item/weapon/gun/projectile))
		var/obj/item/weapon/gun/projectile/P = G
		return P.getAmmo() > 0 && !P.is_jammed
	if(istype(G, /obj/item/weapon/gun/energy))
		var/obj/item/weapon/gun/energy/E = G
		return E.power_supply && E.power_supply.charge >= E.charge_cost
	return TRUE

/datum/invader_ai/proc/try_reload(var/obj/item/weapon/gun/G)
	var/obj/item/weapon/gun/projectile/P = G
	if(!istype(P))
		return FALSE
	var/obj/item/ammo_magazine/M = find_spare_magazine(P)
	if(!M && !P.is_jammed)
		return FALSE
	reload(P, M)
	return TRUE

/datum/invader_ai/proc/find_spare_magazine(var/obj/item/weapon/gun/projectile/P)
	var/list/queue = owner.contents.Copy()
	while(queue.len)
		var/atom/A = queue[queue.len]
		queue.len--
		if(istype(A, /obj/item/ammo_magazine))
			var/obj/item/ammo_magazine/M = A
			if(M.caliber == P.caliber && M.stored_ammo.len && (M.mag_type & P.load_method))
				return M
		else if(istype(A, /obj/item/storage))
			queue += A.contents

/datum/invader_ai/proc/reload(var/obj/item/weapon/gun/projectile/P, var/obj/item/ammo_magazine/M)
	set waitfor = FALSE
	reloading_until = world.time + 3 SECONDS
	select_hand(P)
	if(P.is_jammed)
		P.unjam(owner)
	if(M && P.ammo_magazine)
		P.unload_ammo(owner, 0)
	sleep(rand(8, 15))
	if(M && !QDELETED(owner) && owner.stat == CONSCIOUS && !QDELETED(M) && !QDELETED(P) && P.loc == owner)
		if(istype(M.loc, /obj/item/storage))
			var/obj/item/storage/S = M.loc
			S.remove_from_storage(M, owner)
		P.load_ammo(M, owner)
	sleep(rand(3, 8))
	reloading_until = 0

/datum/invader_ai/proc/get_melee_weapon(var/min_force = 10)
	var/obj/item/best
	for(var/obj/item/I in list(owner.r_hand, owner.l_hand))
		if(istype(I, /obj/item/weapon/gun) || I.force < min_force)
			continue
		if(!best || I.force > best.force)
			best = I
	return best

/datum/invader_ai/proc/select_hand(var/obj/item/I)
	if(!I)
		return
	if(owner.r_hand == I)
		owner.hand = 0
	else if(owner.l_hand == I)
		owner.hand = 1

// === Door breaching ===

/datum/invader_ai/proc/begin_breach(var/obj/machinery/door/D)
	if(!D)
		return
	if(state != INVADER_STATE_BREACH)
		resume_state = state
	breach_door = D
	breach_started = world.time
	state = INVADER_STATE_BREACH
	mover.hesitate()

/datum/invader_ai/proc/end_breach()
	breach_door = null
	mover.blocking_door = null
	mover.door_attempts = 0
	state = resume_state

/datum/invader_ai/proc/give_up_breach()
	mover.exclude_door(breach_door)
	breach_door = null
	state = resume_state

/datum/invader_ai/proc/breach()
	var/obj/machinery/door/D = breach_door
	if(QDELETED(D) || !D.density)
		end_breach()
		return
	if(world.time - breach_started > INVADER_BREACH_TIMEOUT || get_dist(owner, D) > 1)
		give_up_breach()
		return
	if(!owner.canClick() || world.time < mover.pause_until)
		return
	var/obj/machinery/door/airlock/A = D
	if(istype(A))
		if(A.welded || A.brace || (A.locked && (A.stat & BROKEN)))
			give_up_breach()
			return
		if(!A.arePowerSystemsOn() && !A.locked)
			var/obj/item/crowbar/C = locate() in owner
			if(C)
				pry(A, C)
			else
				give_up_breach()
			return
	var/obj/item/W = get_melee_weapon(D.min_force)
	if(!istype(W, /obj/item/weapon))
		give_up_breach()
		return
	select_hand(W)
	bash(D)

/datum/invader_ai/proc/bash(var/obj/machinery/door/D)
	set waitfor = FALSE
	busy = world.time + 10 SECONDS
	owner.ClickOn(D, "")
	busy = 0

/datum/invader_ai/proc/pry(var/obj/machinery/door/airlock/A, var/obj/item/crowbar/C)
	set waitfor = FALSE
	busy = world.time + 10 SECONDS
	owner.face_atom(A)
	A.attackby(C, owner)
	busy = 0

// === Misc ===

/datum/invader_ai/proc/get_up()
	set waitfor = FALSE
	busy = world.time + 10 SECONDS
	owner.mob_rest()
	busy = 0

/datum/invader_ai/proc/struggle()
	set waitfor = FALSE
	busy = world.time + 10 SECONDS
	owner.resist()
	busy = 0

#undef INVADER_STATE_WAIT_DOCK
#undef INVADER_STATE_SEARCH
#undef INVADER_STATE_INVESTIGATE
#undef INVADER_STATE_HUNT
#undef INVADER_STATE_ENGAGE
#undef INVADER_STATE_BREACH
#undef INVADER_SIGHT
#undef INVADER_SEARCH_RADIUS
#undef INVADER_HUNT_TIMEOUT
#undef INVADER_BREACH_TIMEOUT
