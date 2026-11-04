/proc/crew_safe_turf(var/turf/T)
	return T && !T.density && !istype(T, /turf/space) && !istype(T, /turf/simulated/open) && !IsTurfAtmosUnsafe(T) && !(locate(/obj/fire) in T)

/proc/crew_edge_allowed(var/turf/from, var/turf/destination, var/mob/living/carbon/human/crew/H)
	if(!crew_safe_turf(destination))
		return FALSE
	for(var/obj/machinery/door/D in destination)
		if(D.density && (!D.allowed(H) || (H.brain && D in H.brain.mover.excluded_doors)))
			return FALSE
	for(var/obj/machinery/door/window/D in from)
		if(D.density && D.dir == get_dir(from, destination) && !D.allowed(H))
			return FALSE
	for(var/obj/effect/vat_access/blocker in destination)
		if(!blocker.CanPass(H, from, 1))
			return FALSE
	for(var/obj/effect/vat_access/blocker in from)
		if(!blocker.CheckExit(H, destination))
			return FALSE
	return TRUE

/turf/proc/CrewAdjacentTurfs(var/mob/living/carbon/human/crew/H)
	var/list/neighbors = InvaderAdjacentTurfs(H)
	. = list()
	for(var/turf/T in neighbors)
		var/direction = get_dir(src, T)
		if(!crew_edge_allowed(src, T, H))
			continue
		if(direction in GLOB.cornerdirs)
			var/turf/A = get_step(src, direction & (NORTH|SOUTH))
			var/turf/B = get_step(src, direction & (EAST|WEST))
			if(!crew_edge_allowed(src, A, H) || !crew_edge_allowed(A, T, H) || !crew_edge_allowed(src, B, H) || !crew_edge_allowed(B, T, H))
				continue
		. += T

/datum/humanized_mover/crew
	adjacency_proc = /turf/proc/CrewAdjacentTurfs
	distance_proc = /turf/proc/CrewDistance

/turf/proc/CrewDistance(var/turf/T)
	// Being one tile away through a window is not a usable work position.
	if(T && get_dist(src, T) == 1 && !T.Adjacent(src))
		return 2
	return InvaderDistance(T)

/datum/humanized_mover/crew/arrived()
	return ..() && (goal_dist != 1 || owner.Adjacent(goal))

/datum/humanized_mover/crew/do_step(var/turf/T, var/direction)
	var/mob/living/carbon/human/crew/H = owner
	if(!crew_edge_allowed(get_turf(owner), T, H))
		return FALSE
	return ..()

/datum/humanized_mover/crew/try_overshoot()
	return FALSE

/datum/humanized_mover/crew/crawl_step(var/turf/here, var/turf/next)
	var/mob/living/carbon/human/crew/H = owner
	if(!crew_edge_allowed(here, next, H))
		return on_step_failed()
	return ..()

/datum/crew_ai/proc/reset_navigation()
	mover.clear()
	mover.excluded_doors.Cut()
	ride = null
	boarding_floor = null
	exit_floor = null
	next_lift_call = 0
	boarding = FALSE

/datum/crew_ai/proc/walk_toward_target(var/turf/T, var/distance = 1)
	var/turf/here = get_turf(owner)
	if(!T || !here)
		return FALSE
	if(here.z == T.z && get_dist(here, T) <= distance && (distance != 1 || owner.Adjacent(T)))
		mover.clear()
		return TRUE
	if(mover.goal != T || mover.goal_dist != distance)
		mover.set_goal(T, distance)
	mover.tick()
	if(mover.blocking_door)
		mover.exclude_door(mover.blocking_door)
	return FALSE

// Floors form a small graph over z-levels; take one elevator leg at a time.
/datum/crew_ai/proc/find_lift(var/turf/destination)
	var/list/open = list(owner.z)
	var/list/visited = list("[owner.z]" = TRUE)
	var/list/first_lift = list()
	var/list/first_floor = list()
	while(open.len)
		var/level = open[1]
		open.Cut(1, 2)
		for(var/obj/structure/lift/button/button in world)
			if(button.z != level || !button.lift || !button.floor || !button.lift.is_functional())
				continue
			if(level == owner.z)
				var/list/path = AStar(get_turf(owner), get_turf(button), /turf/proc/CrewAdjacentTurfs, /turf/proc/CrewDistance, 0, 250, 1, null, owner)
				if(!LAZYLEN(path))
					continue
			for(var/datum/turbolift_floor/floor in button.lift.floors)
				var/obj/structure/lift/button/exit_button = floor.ext_panel
				if(!exit_button || visited["[exit_button.z]"])
					continue
				var/key = "[exit_button.z]"
				visited[key] = TRUE
				first_lift[key] = first_lift["[level]"] ? first_lift["[level]"] : button
				first_floor[key] = first_floor["[level]"] ? first_floor["[level]"] : floor
				if(exit_button.z == destination.z)
					var/obj/structure/lift/button/entry = first_lift[key]
					ride = entry.lift
					boarding_floor = entry.floor
					exit_floor = first_floor[key]
					return TRUE
				open += exit_button.z
	return FALSE

/datum/crew_ai/proc/navigate(var/turf/destination, var/distance = 1)
	var/turf/here = get_turf(owner)
	if(!here || !destination)
		return FALSE
	// Remain aboard through intermediate stops rather than walking into an empty shaft.
	if(ride && get_area(owner) == locate(ride.current_floor.area_ref))
		if(ride.current_floor != exit_floor)
			if(!(exit_floor in ride.queued_floors) && ride.target_floor != exit_floor)
				ride.queue_move_to(exit_floor)
			status = "Riding elevator"
			return FALSE
		if(!ride.doors_are_open())
			ride.open_doors()
		ride = null
		boarding_floor = null
		exit_floor = null
		boarding = FALSE
		mover.clear()
	if(here.z == destination.z)
		return walk_toward_target(destination, distance)
	if(!ride && !find_lift(destination))
		fail_task("No reachable elevator route to that deck.")
		return FALSE
	var/obj/structure/lift/button/button = boarding_floor.ext_panel
	if(!button || !ride.control_panel_interior)
		fail_task("The elevator controls are unavailable.")
		return FALSE
	status = "Travelling by elevator"
	if(!boarding && !walk_toward_target(get_turf(button), 1))
		return FALSE
	if(world.time >= next_lift_call && ride.current_floor != boarding_floor && !(boarding_floor in ride.queued_floors) && ride.target_floor != boarding_floor)
		button.attack_hand(owner)
		next_lift_call = world.time + 5 SECONDS
	if(ride.current_floor != boarding_floor)
		boarding = FALSE
		return FALSE
	ride.open_doors()
	boarding = TRUE
	// The panel moves with the cabin, so it only names a safe boarding tile when docked here.
	walk_toward_target(get_turf(ride.control_panel_interior), 0)
	return FALSE
