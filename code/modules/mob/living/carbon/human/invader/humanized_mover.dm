// Player-like movement driver for client-less human mobs.
// Walks short re-planned segments of a coarse route with human step timing, hesitation,
// door clicking, collision stutter and idle fidgeting.

#define MOVER_IDLE         0
#define MOVER_WAITING      1
#define MOVER_MOVING       2
#define MOVER_ARRIVED      3
#define MOVER_FAILED       4
#define MOVER_BLOCKED_DOOR 5

#define MOVER_ROUTE_DEPTH  250
#define MOVER_LOCAL_DEPTH  16

/datum/humanized_mover
	var/mob/living/carbon/human/owner
	var/turf/goal
	var/goal_dist = 0
	var/list/route
	var/route_index = 1
	var/turf/waypoint
	var/list/segment
	var/next_step_time = 0
	var/pause_until = 0
	var/failed_steps = 0
	var/repaths = 0
	var/door_attempts = 0
	var/next_door_click = 0
	var/obj/machinery/door/blocking_door
	var/list/excluded_doors = list()
	var/last_move_dir = 0
	var/area/last_area
	var/pending_sidestep = FALSE
	var/atom/look_target
	var/turf/shuffle_home
	var/in_combat = FALSE
	var/crawling = FALSE

/datum/humanized_mover/New(var/mob/living/carbon/human/new_owner)
	..()
	owner = new_owner
	last_area = get_area(owner)

/datum/humanized_mover/Destroy()
	owner = null
	clear()
	look_target = null
	shuffle_home = null
	excluded_doors = null
	return ..()

/datum/humanized_mover/proc/set_goal(var/turf/T, var/dist = 0)
	if(!T)
		clear()
		return
	goal_dist = dist
	// Keep the existing route while the destination only drifts a little (chasing a moving target).
	if(goal && route && T.z == goal.z && get_dist(goal, T) <= 2)
		goal = T
		return
	goal = T
	route = null
	segment = null
	repaths = 0
	failed_steps = 0

/datum/humanized_mover/proc/clear()
	goal = null
	route = null
	segment = null
	waypoint = null
	blocking_door = null
	door_attempts = 0
	failed_steps = 0
	repaths = 0
	pending_sidestep = FALSE
	crawling = FALSE

/datum/humanized_mover/proc/exclude_door(var/obj/machinery/door/D)
	if(D)
		excluded_doors |= D
	blocking_door = null
	door_attempts = 0
	route = null
	segment = null

/datum/humanized_mover/proc/pause(var/ds)
	pause_until = max(pause_until, world.time + ds)

/datum/humanized_mover/proc/hesitate()
	pause(clamp(round(gaussian(4, 1)), 2, 6))

/datum/humanized_mover/proc/ready()
	return world.time >= pause_until && world.time >= next_step_time

/datum/humanized_mover/proc/arrived()
	var/turf/here = get_turf(owner)
	if(!goal || !here)
		return FALSE
	if(goal_dist)
		return here.z == goal.z && get_dist(here, goal) <= goal_dist
	return here == goal

/datum/humanized_mover/proc/step_delay()
	var/delay = owner.m_intent == "walk" ? 7 + config.walk_speed : 1 + config.run_speed
	if(owner.m_intent == "run" && owner.drowsyness > 0)
		delay += 6
	delay += owner.movement_delay()
	delay += gaussian(0.2, 0.5)
	if(prob(3))
		delay += rand(1, 3)
	return max(1, delay)

/datum/humanized_mover/proc/tick()
	if(!goal)
		return MOVER_IDLE
	if(arrived())
		clear()
		return MOVER_ARRIVED
	if(!ready())
		glance()
		return MOVER_WAITING
	if(pending_sidestep)
		pending_sidestep = FALSE
		sidestep()
		segment = null
		return MOVER_MOVING
	if(!route && !build_route())
		return MOVER_FAILED
	if(!length(segment) && !build_segment())
		route = null
		if(++repaths > 4)
			clear()
			return MOVER_FAILED
		return MOVER_WAITING

	var/turf/here = get_turf(owner)
	var/turf/next = segment[1]
	if(!here || next.z != here.z || get_dist(here, next) != 1)
		segment = null
		return MOVER_WAITING

	if((locate(/obj/structure/plasticflaps) in next) || (locate(/obj/structure/plasticflaps) in here))
		return crawl_step(here, next)
	crawling = FALSE
	if(owner.resting)
		return MOVER_WAITING

	var/obj/machinery/door/D = dense_door(next, here)
	if(D)
		return handle_door(D)

	update_move_intent()
	var/dir = get_dir(here, next)
	if(try_overshoot(here, dir))
		return MOVER_MOVING
	if(!do_step(next, dir))
		return on_step_failed()
	if(get_turf(owner) == next)
		segment.Cut(1, 2)
	else
		segment = null
	on_step_success(here)
	return MOVER_MOVING

/datum/humanized_mover/proc/crawl_step(var/turf/here, var/turf/next)
	crawling = TRUE
	if(!owner.lying)
		owner.resting = TRUE
		owner.update_canmove()
		pause(rand(2, 4))
		return MOVER_WAITING
	owner.scramble(next)
	if(get_turf(owner) == here)
		return on_step_failed()
	if(get_turf(owner) == next)
		segment.Cut(1, 2)
	else
		segment = null
	last_move_dir = get_dir(here, get_turf(owner))
	next_step_time = world.time + step_delay() + rand(3, 6)
	return MOVER_MOVING

/datum/humanized_mover/proc/build_route()
	var/turf/here = get_turf(owner)
	if(!here || !goal || here.z != goal.z)
		clear()
		return FALSE
	route = AStar(here, goal, /turf/proc/InvaderAdjacentTurfs, /turf/proc/InvaderDistance, 0, MOVER_ROUTE_DEPTH, goal_dist, null, owner)
	if(!islist(route) || !route.len)
		clear()
		return FALSE
	route_index = 1
	segment = null
	return TRUE

/datum/humanized_mover/proc/build_segment()
	var/turf/here = get_turf(owner)
	for(var/attempt in 1 to 3)
		if(route_index >= route.len)
			// The goal drifted past the end of the old route.
			if(attempt > 1 || !build_route())
				return FALSE
		var/idx = min(route_index + rand(3, 5), route.len)
		route_index = idx
		waypoint = route[idx]
		var/turf/aim = waypoint
		// Aim slightly off the exact route, like clicking roughly across the screen.
		if(idx < route.len && prob(40))
			var/list/near = waypoint.InvaderAdjacentTurfs(owner)
			if(near.len)
				aim = pick(near)
		var/list/local = AStar(here, aim, /turf/proc/InvaderAdjacentTurfs, /turf/proc/InvaderDistance, 0, MOVER_LOCAL_DEPTH, 0, null, owner)
		if((!islist(local) || !local.len) && aim != waypoint)
			local = AStar(here, waypoint, /turf/proc/InvaderAdjacentTurfs, /turf/proc/InvaderDistance, 0, MOVER_LOCAL_DEPTH, 0, null, owner)
		if(!islist(local) || !local.len)
			return FALSE
		if(local.len >= 2)
			segment = local.Copy(2)
			return TRUE
	return FALSE

/datum/humanized_mover/proc/do_step(var/turf/T, var/dir)
	var/turf/start = get_turf(owner)
	owner.SelfMove(T, dir)
	return get_turf(owner) != start

/datum/humanized_mover/proc/on_step_success(var/turf/prev)
	var/turf/here = get_turf(owner)
	last_move_dir = get_dir(prev, here)
	failed_steps = 0
	door_attempts = 0
	next_step_time = world.time + step_delay()
	if(length(segment))
		var/turf/N = segment[1]
		var/obj/machinery/door/D = dense_door(N, here)
		// Click the door a step early so we keep walking instead of bumping into it.
		if(D && !D.operating && world.time >= next_door_click)
			door_attempts++
			next_door_click = world.time + rand(3, 6)
			click_door(D)
	if(in_combat)
		return
	var/area/A = get_area(here)
	if(A != last_area)
		last_area = A
		if(prob(20))
			hesitate()
	else if(prob(4) && is_junction(here))
		hesitate()
	notice_surroundings()

/datum/humanized_mover/proc/on_step_failed()
	failed_steps++
	pause(rand(2, 4))
	if(prob(50))
		pending_sidestep = TRUE
	else
		segment = null
	if(failed_steps > 3)
		failed_steps = 0
		route = null
		segment = null
		if(++repaths > 4)
			clear()
			return MOVER_FAILED
	return MOVER_WAITING

/datum/humanized_mover/proc/try_overshoot(var/turf/here, var/dir)
	if(in_combat || !last_move_dir || !(dir in GLOB.cardinal) || !(last_move_dir in GLOB.cardinal))
		return FALSE
	if(dir == last_move_dir || dir == GLOB.reverse_dir[last_move_dir] || !prob(8))
		return FALSE
	var/turf/T = get_step(here, last_move_dir)
	if(!invader_can_step(here, T, owner, FALSE) || (locate(/mob/living) in T))
		return FALSE
	if(!do_step(T, last_move_dir))
		return FALSE
	segment = null
	on_step_success(here)
	return TRUE

/datum/humanized_mover/proc/sidestep()
	var/turf/here = get_turf(owner)
	var/list/options = list()
	for(var/d in GLOB.cardinal)
		if(d == last_move_dir)
			continue
		var/turf/T = get_step(here, d)
		if(invader_can_step(here, T, owner, FALSE) && !(locate(/mob/living) in T))
			options += T
	if(!options.len)
		return
	var/turf/T = pick(options)
	var/d = get_dir(here, T)
	if(do_step(T, d))
		last_move_dir = d
		next_step_time = world.time + step_delay()

/// Steps one tile away from (away = TRUE) or around (away = FALSE) an atom. Used for combat spacing.
/datum/humanized_mover/proc/step_relative(var/atom/A, var/away)
	if(!ready())
		return FALSE
	var/turf/here = get_turf(owner)
	var/cur = get_dist(here, A)
	var/list/options = list()
	for(var/d in GLOB.cardinal)
		var/turf/T = get_step(here, d)
		if(!invader_can_step(here, T, owner, FALSE) || (locate(/mob/living) in T))
			continue
		var/nd = get_dist(T, A)
		if(away ? nd > cur : nd == cur)
			options += T
	if(!options.len)
		return FALSE
	var/turf/T = pick(options)
	var/d = get_dir(here, T)
	if(!do_step(T, d))
		return FALSE
	last_move_dir = d
	next_step_time = world.time + step_delay()
	segment = null
	return TRUE

/datum/humanized_mover/proc/dense_door(var/turf/T, var/turf/from)
	var/d = get_dir(from, T)
	for(var/obj/machinery/door/window/WD in from)
		if(WD.density && WD.dir == d)
			return WD
	for(var/obj/machinery/door/D in T)
		if(!D.density)
			continue
		if(istype(D, /obj/machinery/door/window) && D.dir != GLOB.reverse_dir[d])
			continue
		return D

/datum/humanized_mover/proc/handle_door(var/obj/machinery/door/D)
	if(world.time < next_door_click || D.operating)
		return MOVER_WAITING
	if(door_attempts >= 2)
		blocking_door = D
		door_attempts = 0
		return MOVER_BLOCKED_DOOR
	door_attempts++
	next_door_click = world.time + rand(3, 6)
	owner.face_atom(D)
	click_door(D)
	pause(rand(1, 3))
	return MOVER_WAITING

/datum/humanized_mover/proc/click_door(var/obj/machinery/door/D)
	set waitfor = FALSE
	if(owner && D && owner.Adjacent(D))
		D.attack_hand(owner)

/datum/humanized_mover/proc/is_junction(var/turf/T)
	var/open = 0
	for(var/d in GLOB.cardinal)
		if(invader_can_step(T, get_step(T, d), owner, FALSE))
			open++
	return open >= 3

/datum/humanized_mover/proc/notice_surroundings()
	for(var/mob/living/carbon/human/H in orange(2, owner))
		if(H.stat == DEAD || is_invader_ally(H))
			continue
		if(prob(25))
			look_target = H
		if(prob(30))
			hesitate()
		return
	if(prob(5))
		var/obj/machinery/computer/C = locate() in orange(2, owner)
		if(C)
			look_target = C

/datum/humanized_mover/proc/glance()
	if(!look_target || in_combat)
		return
	if(get_dist(owner, look_target) <= 3)
		owner.face_atom(look_target)
	look_target = null

/datum/humanized_mover/proc/update_move_intent()
	var/want = (!in_combat && hazard_nearby()) ? "walk" : "run"
	if(owner.m_intent != want)
		owner.m_intent = want

/datum/humanized_mover/proc/hazard_nearby()
	var/area/A = get_area(owner)
	if(A)
		var/area_name = lowertext(A.name)
		if(findtext(area_name, "kitchen") || findtext(area_name, "hydroponic"))
			return TRUE
	for(var/turf/simulated/T in range(2, owner))
		if(T.wet)
			return TRUE
	return FALSE

/// Fidgeting while standing around: occasional turns or a step out and back.
/datum/humanized_mover/proc/idle_tick()
	if(!ready())
		return
	glance()
	var/turf/here = get_turf(owner)
	if(shuffle_home)
		if(here != shuffle_home && get_dist(here, shuffle_home) == 1)
			do_step(shuffle_home, get_dir(here, shuffle_home))
		shuffle_home = null
		next_step_time = world.time + step_delay()
		return
	if(!prob(2))
		return
	if(prob(60))
		owner.set_dir(turn(owner.dir, pick(90, -90)))
		return
	var/d = pick(GLOB.cardinal)
	var/turf/T = get_step(here, d)
	if(invader_can_step(here, T, owner, FALSE) && !(locate(/mob/living) in T) && do_step(T, d))
		shuffle_home = here
		next_step_time = world.time + rand(3, 6)
