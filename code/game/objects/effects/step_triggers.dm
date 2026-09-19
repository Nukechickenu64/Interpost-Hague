/* Simple object type, calls a proc when "stepped" on by something */

/obj/effect/step_trigger
	var/affect_ghosts = 0
	var/stopper = 1 // stops throwers
	invisibility = 101 // nope cant see this shit
	anchored = 1

/obj/effect/step_trigger/proc/Trigger(var/atom/movable/A)
	return 0

/obj/effect/step_trigger/Crossed(atom/movable/H)
	..()
	if(!H)
		return
	if(isobserver(H) && !(isghost(H) && affect_ghosts))
		return
	Trigger(H)



/* Tosses things in a certain direction */

/obj/effect/step_trigger/thrower
	var/direction = SOUTH // the direction of throw
	var/tiles = 3	// if 0: forever until atom hits a stopper
	var/immobilize = 1 // if nonzero: prevents mobs from moving while they're being flung
	var/speed = 1	// delay of movement
	var/facedir = 0 // if 1: atom faces the direction of movement
	var/nostop = 0 // if 1: will only be stopped by teleporters
	var/list/affecting = list()

/obj/effect/step_trigger/thrower/Trigger(var/atom/movable/AM)
	if(!AM || !istype(AM) || !AM.simulated)
		return
	var/curtiles = 0
	var/stopthrow = 0
	var/mob/M
	var/previous_canmove
	for(var/obj/effect/step_trigger/thrower/T in orange(2, src))
		if(AM in T.affecting)
			return

	if(ismob(AM))
		M = AM
		if(immobilize)
			previous_canmove = M.canmove
			M.canmove = 0

	affecting.Add(AM)
	while(AM && !stopthrow)
		if(tiles)
			if(curtiles >= tiles)
				break
		if(AM.z != src.z)
			break

		curtiles++

		sleep(speed)
		if(QDELETED(AM) || !AM.loc || AM.z != src.z)
			break

		// Calculate if we should stop the process
		if(!nostop)
			for(var/obj/effect/step_trigger/T in get_step(AM, direction))
				if(T.stopper && T != src)
					stopthrow = 1
		else
			for(var/obj/effect/step_trigger/teleporter/T in get_step(AM, direction))
				if(T.stopper)
					stopthrow = 1

		if(AM)
			var/predir = AM.dir
			if(!step(AM, direction))
				break
			if(facedir)
				AM.set_dir(direction)
			else
				AM.set_dir(predir)



	affecting.Remove(AM)

	if(M && !QDELETED(M) && immobilize)
		M.canmove = previous_canmove

/* Stops things thrown by a thrower, doesn't do anything */

/obj/effect/step_trigger/stopper

/* Instant teleporter */

/obj/effect/step_trigger/teleporter
	var/teleport_x = 0	// teleportation coordinates (if one is null, then no teleport!)
	var/teleport_y = 0
	var/teleport_z = 0

/obj/effect/step_trigger/teleporter/Trigger(var/atom/movable/A)
	if(!A || isnull(teleport_x) || isnull(teleport_y) || isnull(teleport_z))
		return 0

	var/new_x = clamp(teleport_x, 1, world.maxx)
	var/new_y = clamp(teleport_y, 1, world.maxy)
	var/new_z = clamp(teleport_z, 1, world.maxz)
	var/turf/T = locate(new_x, new_y, new_z)
	if(!T)
		return 0

	return A.forceMove(T)

/* Random teleporter, teleports atoms to locations ranging from teleport_x - teleport_x_offset, etc */

/obj/effect/step_trigger/teleporter/random
	opacity = 1
	var/teleport_x_offset = 0
	var/teleport_y_offset = 0
	var/teleport_z_offset = 0

/obj/effect/step_trigger/teleporter/random/Trigger(var/atom/movable/A)
	if(!A || isnull(teleport_x) || isnull(teleport_x_offset) || isnull(teleport_y) || isnull(teleport_y_offset) || isnull(teleport_z) || isnull(teleport_z_offset))
		return 0

	// offset is treated as a radius around the configured center coordinate.
	var/min_x = max(1, teleport_x - teleport_x_offset)
	var/max_x = min(world.maxx, teleport_x + teleport_x_offset)
	var/min_y = max(1, teleport_y - teleport_y_offset)
	var/max_y = min(world.maxy, teleport_y + teleport_y_offset)
	var/min_z = max(1, teleport_z - teleport_z_offset)
	var/max_z = min(world.maxz, teleport_z + teleport_z_offset)

	// Preserve the existing "choose a random coordinate between these two values" behavior,
	// but clamp the result to valid world bounds so invalid map config entries cannot
	// generate impossible or null targets.
	var/new_x = clamp(rand(min_x, max_x), 1, world.maxx)
	var/new_y = clamp(rand(min_y, max_y), 1, world.maxy)
	var/new_z = clamp(rand(min_z, max_z), 1, world.maxz)
	var/turf/T = locate(new_x, new_y, new_z)
	if(!T)
		return 0

	return A.forceMove(T)
