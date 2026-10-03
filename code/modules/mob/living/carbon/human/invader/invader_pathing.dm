// Turf adjacency and cost procs for AStar, used by invader NPCs.
// AStar passes its `id` argument to the adjacency proc, so the moving mob arrives here as M.

/turf/proc/InvaderAdjacentTurfs(var/mob/living/M)
	. = list()
	for(var/d in GLOB.cardinal)
		var/turf/T = get_step(src, d)
		if(invader_can_step(src, T, M))
			. += T
	for(var/d in GLOB.cornerdirs)
		var/turf/T = get_step(src, d)
		if(!T)
			continue
		var/turf/A = get_step(src, d & (NORTH|SOUTH))
		var/turf/B = get_step(src, d & (EAST|WEST))
		if(invader_can_step(src, A, M, FALSE) && invader_can_step(A, T, M, FALSE) && invader_can_step(src, B, M, FALSE) && invader_can_step(B, T, M, FALSE))
			. += T

/turf/proc/InvaderDistance(var/turf/T)
	if(get_dist(src, T) != 1)
		return get_dist(src, T)
	. = (x != T.x && y != T.y) ? 1.4 : 1
	if(locate(/obj/structure/plasticflaps) in T)
		. += 3
	for(var/obj/machinery/door/D in T)
		if(D.density)
			. += 6
			break

/proc/invader_can_step(var/turf/from, var/turf/T, var/mob/living/M, var/allow_doors = TRUE)
	if(!from || !T || T.density || T.z != from.z || istype(T, /turf/space) || istype(T, /turf/simulated/open))
		return FALSE
	var/d = get_dir(from, T)
	for(var/obj/structure/window/W in from)
		if(W.density && W.dir == d)
			return FALSE
	for(var/obj/machinery/door/window/WD in from)
		if(WD.density && WD.dir == d && (!allow_doors || !invader_door_passable(WD, M)))
			return FALSE
	var/rd = GLOB.reverse_dir[d]
	for(var/obj/O in T)
		if(istype(O, /obj/machinery/door))
			var/obj/machinery/door/D = O
			if(!D.density)
				continue
			if(istype(D, /obj/machinery/door/window) && D.dir != rd)
				continue
			if(!allow_doors || !invader_door_passable(D, M))
				return FALSE
			continue
		// Players get through flaps by lying down and crawling; the mover does the same.
		if(istype(O, /obj/structure/plasticflaps))
			if(!allow_doors)
				return FALSE
			continue
		if(!O.CanPass(M, from))
			return FALSE
	return TRUE

/proc/invader_door_passable(var/obj/machinery/door/D, var/mob/living/M)
	if(istype(D, /obj/machinery/door/blast) || istype(D, /obj/machinery/door/firedoor))
		return FALSE
	var/mob/living/carbon/human/invader/I = M
	if(istype(I) && I.mover && (D in I.mover.excluded_doors))
		return FALSE
	return TRUE
