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
#define INVADER_DARK_LUM       0.05

/datum/invader_ai
	var/mob/living/carbon/human/invader/owner
	var/datum/humanized_mover/mover
	var/speed_multiplier = 1 // Lower is faster for think/reaction timings; below 1 is quicker than a player.
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
	// Areas where crew were actually seen or heard; invaders have no other way of knowing where people are.
	var/list/contact_areas = list()

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
	contact_areas = null
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
		next_scan = world.time + max(1, round(rand(1, 2) * speed_multiplier))
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
		if(!is_valid_target(H) || !can_perceive(H))
			continue
		var/score = get_dist(owner, H) + (H.stat ? 5 : 0) + (H == target ? -2 : 0)
		if(!best || score < best_score)
			best = H
			best_score = score
	if(best)
		note_contact(best)
		if(best != target || (state != INVADER_STATE_ENGAGE && state != INVADER_STATE_HUNT))
			reaction_at = world.time + human_reaction_time()
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

/// What a player could make out on screen: nothing behind their vision cone, nothing in pitch darkness, nothing while blind.
/datum/invader_ai/proc/can_perceive(var/mob/living/carbon/human/H)
	if(get_dist(owner, H) <= 1)
		return TRUE
	if(owner.eye_blind || owner.blinded)
		return FALSE
	if(owner.usefov && !owner.lying && !owner.resting && H.InCone(owner, turn(owner.dir, 180)))
		return FALSE
	var/turf/T = get_turf(H)
	if(!T || T.get_lumcount() <= INVADER_DARK_LUM)
		return FALSE
	return TRUE

/datum/invader_ai/proc/human_reaction_time()
	return max(2, round(gaussian(3, 1) * speed_multiplier))

/datum/invader_ai/proc/note_contact(var/mob/M)
	var/area/A = get_area(M)
	if(!A)
		return
	contact_areas -= A
	contact_areas += A
	if(contact_areas.len > 5)
		contact_areas.Cut(1, 2)

/datum/invader_ai/proc/on_heard(var/mob/speaker)
	if(!is_valid_target(speaker))
		return
	note_contact(speaker)
	if(state == INVADER_STATE_ENGAGE || state == INVADER_STATE_WAIT_DOCK)
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
	reaction_at = world.time + human_reaction_time()
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
			linger_until = world.time + max(1, round(rand(3, 10) * speed_multiplier))
		if(INVADER_STATE_INVESTIGATE, INVADER_STATE_HUNT)
			investigate_turf = null
			state = INVADER_STATE_SEARCH
			linger_until = world.time + max(1, round(rand(3, 10) * speed_multiplier))

/datum/invader_ai/proc/wait_dock()
	if(!release_at)
		var/datum/shuttle/autodock/ferry/supply/S = SSsupply.shuttle
		if(!S || (S.at_station() && S.moving_status == SHUTTLE_IDLE))
			release_at = world.time + max(1, round(rand(2, 10) * speed_multiplier))
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
			linger_until = world.time + max(5, round(20 * speed_multiplier))
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
	// Usually head back to where crew were last seen or heard.
	if(contact_areas.len && prob(60))
		areas = contact_areas
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
	if(G && needs_pump(G))
		if(world.time >= reaction_at)
			pump(G)
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
	var/obj/item/W = get_melee_weapon(5)
	if(!W && world.time >= reaction_at && (!owner.r_hand || !owner.l_hand))
		var/obj/item/stowed = find_stowed_melee()
		if(stowed)
			draw_item(stowed)
			return
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
	reaction_at = world.time + clamp(round(gaussian(1, 0.5) * speed_multiplier), 0, 2)
	owner.ClickOn(aim, "")

/datum/invader_ai/proc/melee_attack()
	set waitfor = FALSE
	owner.zone_sel.selecting = prob(70) ? BP_CHEST : pick(BP_HEAD, BP_GROIN, BP_L_ARM, BP_R_ARM)
	reaction_at = world.time + clamp(round(gaussian(0.5, 0.5) * speed_multiplier), 0, 1)
	owner.ClickOn(target, "")

/datum/invader_ai/proc/get_gun()
	if(istype(owner.r_hand, /obj/item/weapon/gun))
		return owner.r_hand
	if(istype(owner.l_hand, /obj/item/weapon/gun))
		return owner.l_hand

/datum/invader_ai/proc/gun_has_ammo(var/obj/item/weapon/gun/G)
	if(istype(G, /obj/item/weapon/gun/projectile))
		var/obj/item/weapon/gun/projectile/P = G
		if(P.is_jammed)
			return FALSE
		// A spent casing held in the chamber is not a round.
		var/rounds = P.loaded.len + (P.chambered && P.chambered.BB ? 1 : 0)
		if(P.ammo_magazine)
			rounds += P.ammo_magazine.stored_ammo.len
		return rounds > 0
	if(istype(G, /obj/item/weapon/gun/energy))
		var/obj/item/weapon/gun/energy/E = G
		return E.power_supply && E.power_supply.charge >= E.charge_cost
	return TRUE

/datum/invader_ai/proc/needs_pump(var/obj/item/weapon/gun/G)
	var/obj/item/weapon/gun/projectile/shotgun/pump/S = G
	return istype(S) && !S.is_jammed && (!S.chambered || !S.chambered.BB) && S.loaded.len

/// Racking the slide is the player's Z keypress on the held gun.
/datum/invader_ai/proc/pump(var/obj/item/weapon/gun/projectile/shotgun/pump/S)
	set waitfor = FALSE
	select_hand(S)
	reaction_at = world.time + human_reaction_time()
	S.attack_self(owner)

/datum/invader_ai/proc/try_reload(var/obj/item/weapon/gun/G)
	var/obj/item/weapon/gun/projectile/P = G
	if(!istype(P))
		return FALSE
	var/obj/item/ammo = find_spare_ammo(P)
	if(!ammo && !P.is_jammed)
		return FALSE
	reload(P, ammo)
	return TRUE

/datum/invader_ai/proc/find_spare_ammo(var/obj/item/weapon/gun/projectile/P)
	var/list/queue = owner.contents.Copy()
	while(queue.len)
		var/atom/A = queue[queue.len]
		queue.len--
		if(istype(A, /obj/item/ammo_magazine))
			var/obj/item/ammo_magazine/M = A
			if(M.caliber == P.caliber && M.stored_ammo.len && (M.mag_type & P.load_method))
				return M
		else if(istype(A, /obj/item/ammo_casing))
			var/obj/item/ammo_casing/C = A
			// Guns without a magazine type are fed loose rounds.
			if(C.BB && C.caliber == P.caliber && !P.magazine_type)
				return C
		else if(istype(A, /obj/item/storage))
			queue += A.contents

/datum/invader_ai/proc/still_able(var/obj/item/weapon/gun/projectile/P)
	return !QDELETED(owner) && owner.stat == CONSCIOUS && !owner.incapacitated() && !QDELETED(P) && (P == owner.r_hand || P == owner.l_hand)

/// Same steps a player takes: free a hand, pull the old mag, dig out ammo, insert it.
/datum/invader_ai/proc/reload(var/obj/item/weapon/gun/projectile/P, var/obj/item/ammo)
	set waitfor = FALSE
	reloading_until = world.time + 20 SECONDS
	select_hand(P)
	if(P.is_jammed)
		P.unjam(owner)
	if(!ammo || !still_able(P))
		reloading_until = 0
		return
	if(!free_off_hand(P))
		reloading_until = 0
		return
	sleep(human_action_time(4, 8))
	if(istype(ammo, /obj/item/ammo_magazine) && P.ammo_magazine && still_able(P))
		P.unload_ammo(owner, 0)
		var/obj/item/ammo_magazine/old = (owner.r_hand == P) ? owner.l_hand : owner.r_hand
		if(istype(old))
			if(old.stored_ammo.len)
				stow_item(old)
			else
				owner.drop_from_inventory(old)
		sleep(human_action_time(3, 6))
	var/loads = istype(ammo, /obj/item/ammo_casing) ? P.max_shells : 1
	while(loads-- > 0 && ammo && still_able(P))
		sleep(human_action_time(6, 10))
		if(QDELETED(ammo) || !still_able(P) || !take_into_hand(ammo))
			break
		select_hand(P)
		sleep(human_action_time(3, 6))
		if(!still_able(P) || (ammo != owner.r_hand && ammo != owner.l_hand))
			break
		P.load_ammo(ammo, owner)
		if(loads > 0)
			if(P.loaded.len >= P.max_shells)
				break
			ammo = find_spare_ammo(P)
	reloading_until = 0

/datum/invader_ai/proc/human_action_time(var/low, var/high)
	return max(1, round(rand(low, high) * speed_multiplier))

/// Empties the hand not holding keep, stowing the item if it fits or dropping it otherwise.
/datum/invader_ai/proc/free_off_hand(var/obj/item/keep)
	var/obj/item/off = (owner.r_hand == keep) ? owner.l_hand : owner.r_hand
	if(off)
		stow_item(off)
	return !((owner.r_hand == keep) ? owner.l_hand : owner.r_hand)

/datum/invader_ai/proc/stow_item(var/obj/item/I)
	for(var/obj/item/storage/S in owner.contents)
		if(S != I && S.can_be_inserted(I, owner, stop_messages = 1))
			S.handle_item_insertion(I, prevent_warning = TRUE)
			return
	owner.drop_from_inventory(I)

/// Picks an item out of a pocket or bag with an empty hand, as a player clicking it would.
/datum/invader_ai/proc/take_into_hand(var/obj/item/I)
	if(I == owner.r_hand || I == owner.l_hand)
		return TRUE
	var/old_hand = owner.hand
	if(!owner.r_hand)
		owner.hand = 0
	else if(!owner.l_hand)
		owner.hand = 1
	else
		return FALSE
	I.attack_hand(owner)
	if(I != owner.r_hand && I != owner.l_hand)
		owner.hand = old_hand
		return FALSE
	return TRUE

/datum/invader_ai/proc/find_stowed_melee()
	var/list/queue = list()
	for(var/obj/item/storage/S in owner.contents)
		queue += S.contents
	var/obj/item/best
	while(queue.len)
		var/atom/A = queue[queue.len]
		queue.len--
		if(istype(A, /obj/item/storage))
			queue += A.contents
			continue
		var/obj/item/weapon/W = A
		if(!istype(W) || istype(W, /obj/item/weapon/gun) || W.force < 5)
			continue
		if(!best || W.force > best.force)
			best = W
	return best

/datum/invader_ai/proc/draw_item(var/obj/item/I)
	set waitfor = FALSE
	busy = world.time + 10 SECONDS
	sleep(human_action_time(4, 8))
	if(!QDELETED(owner) && owner.stat == CONSCIOUS && !QDELETED(I))
		take_into_hand(I)
	busy = 0

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
	// The crowbar has to come out of the pocket into a free hand first.
	if(C != owner.r_hand && C != owner.l_hand)
		if(owner.r_hand && owner.l_hand)
			stow_item(owner.hand ? owner.r_hand : owner.l_hand)
		sleep(human_action_time(4, 8))
		if(QDELETED(owner) || owner.stat != CONSCIOUS || QDELETED(C) || !take_into_hand(C))
			busy = 0
			return
	select_hand(C)
	if(!QDELETED(A) && owner.Adjacent(A) && owner.canClick())
		owner.ClickOn(A, "")
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
#undef INVADER_DARK_LUM
