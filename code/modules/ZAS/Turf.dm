/turf/simulated/var/zone/zone
/turf/simulated/var/open_directions

/turf/var/needs_air_update = 0
/turf/var/datum/gas_mixture/air

/turf/simulated/proc/update_graphic(list/graphic_add = null, list/graphic_remove = null)
	if(graphic_add && graphic_add.len)
		vis_contents += graphic_add
	if(graphic_remove && graphic_remove.len)
		vis_contents -= graphic_remove

/turf/proc/update_air_properties()
	var/block = c_airblock(src)
	if(block & AIR_BLOCKED)
		//dbg(blocked)
		return 1

	#ifdef MULTIZAS
	for(var/d = 1, d < 64, d *= 2)
	#else
	for(var/d = 1, d < 16, d *= 2)
	#endif

		var/turf/unsim = get_zstep(src, d)

		if(!unsim)
			continue

		block = unsim.c_airblock(src)

		if(block & AIR_BLOCKED)
			//unsim.dbg(air_blocked, turn(180,d))
			continue

		var/r_block = c_airblock(unsim)

		if(r_block & AIR_BLOCKED)
			continue

		if(istype(unsim, /turf/simulated))

			var/turf/simulated/sim = unsim
			if(TURF_HAS_VALID_ZONE(sim))
				SSair.connect(sim, src)

/*
	Simple heuristic for determining if removing the turf from it's zone will not partition the zone (A very bad thing).
	Instead of analyzing the entire zone, we only check the nearest 3x3 turfs surrounding the src turf.
	This implementation may produce false negatives but it (hopefully) will not produce any false postiives.
*/

/turf/simulated/proc/can_safely_remove_from_zone()
	if(!zone) return 1

	var/check_dirs = get_zone_neighbours(src)
	var/unconnected_dirs = check_dirs

	//src is only connected to the zone by a single direction, this is a safe removal.
	if (!(check_dirs & (check_dirs - 1)))
		return TRUE

	#ifdef MULTIZAS
	var/to_check = GLOB.cornerdirsz
	#else
	var/to_check = GLOB.cornerdirs
	#endif

	for(var/dir in to_check)

		//for each pair of "adjacent" cardinals (e.g. NORTH and WEST, but not NORTH and SOUTH)
		if((dir & check_dirs) == dir)
			//check that they are connected by the corner turf
			var/connected_dirs = get_zone_neighbours(get_step(src, dir))
			if(connected_dirs && (dir & GLOB.reverse_dir[connected_dirs]) == dir)
				unconnected_dirs &= ~dir //they are, so unflag the cardinals in question

	//it is safe to remove src from the zone if all cardinals are connected by corner turfs
	return !unconnected_dirs

//helper for can_safely_remove_from_zone()
/turf/simulated/proc/get_zone_neighbours(turf/simulated/T)
	. = 0
	if(istype(T) && T.zone)
		#ifdef MULTIZAS
		var/to_check = GLOB.cardinalz
		#else
		var/to_check = GLOB.cardinal
		#endif
		for(var/dir in to_check)
			var/turf/simulated/other = get_zstep(T, dir)
			if(istype(other) && other.zone == T.zone && !(SSair.air_blocked(T, other) & AIR_BLOCKED) && get_dist(src, other) <= 1)
				. |= dir

/turf/simulated/update_air_properties()
	var/area/current_area = get_area(src)
	if(zone && (zone.invalid || zone.owner != current_area || isspace(current_area)))
		c_copy_air()
		if(!zone.invalid)
			zone.remove(src)
		else
			zone = null

	if(isspace(current_area))
		return ..()

	if(c_airblock(src) & AIR_BLOCKED)
		if(!(blocks_air & AIR_BLOCKED) && (locate(/obj/machinery/door) in src) && (!zone || zone.contents.len == 1))
			if(!zone)
				SSair.build_atmos_subarea(src)
			open_directions = 0
			return TRUE
		if(zone)
			c_copy_air()
			if(can_safely_remove_from_zone())
				zone.remove(src)
			else
				zone.rebuild()
		return TRUE

	if(!zone)
		SSair.build_atmos_subarea(src)

	var/previously_open = open_directions
	open_directions = 0
	#ifdef MULTIZAS
	var/list/directions = GLOB.cardinalz
	#else
	var/list/directions = GLOB.cardinal
	#endif
	for(var/direction in directions)
		var/turf/neighbour = get_zstep(src, direction)
		if(!neighbour)
			continue
		if(SSair.air_blocked(src, neighbour) & AIR_BLOCKED)
			if((previously_open & direction) && istype(neighbour, /turf/simulated))
				var/turf/simulated/blocked_neighbour = neighbour
				if(blocked_neighbour.zone == zone)
					zone.rebuild()
					return
			continue
		open_directions |= direction
		if(SSair.is_space_turf(neighbour))
			SSair.connect(src, neighbour)
		else
			var/turf/simulated/simulated_neighbour = neighbour
			if(TURF_HAS_VALID_ZONE(simulated_neighbour) && simulated_neighbour.zone != zone)
				SSair.connect(src, simulated_neighbour)

/turf/proc/post_update_air_properties()
	if(connections) connections.update_all()

/turf/assume_air(datum/gas_mixture/giver) //use this for machines to adjust air
	return 0

/turf/proc/assume_gas(gasid, moles, temp = 0)
	return 0

/turf/return_air()
	//Create gas mixture to hold data for passing
	return create_initial_air()

/turf/proc/create_initial_air()
	var/datum/gas_mixture/GM = new
	if(isspace(get_area(src)))
		GM.temperature = TCMB
		return GM
	if(initial_gas)
		GM.gas = initial_gas.Copy()
	GM.temperature = temperature
	GM.update_values()

	return GM

/turf/remove_air(amount as num)
	var/datum/gas_mixture/GM = return_air()
	return GM.remove(amount)

/turf/simulated/assume_air(datum/gas_mixture/giver)
	var/datum/gas_mixture/my_air = return_air()
	my_air.merge(giver)

/turf/simulated/assume_gas(gasid, moles, temp = null)
	var/datum/gas_mixture/my_air = return_air()

	if(isnull(temp))
		my_air.adjust_gas(gasid, moles)
	else
		my_air.adjust_gas_temp(gasid, moles, temp)

	return 1

/turf/simulated/return_air()
	var/area/current_area = get_area(src)
	if(isspace(current_area))
		return create_initial_air()
	if(zone)
		if(!zone.invalid)
			SSair.mark_zone_update(zone)
			return zone.air
		else
			if(!air)
				make_air()
			c_copy_air()
			return air
	else
		if(!air)
			make_air()
		return air

/turf/proc/make_air()
	air = create_initial_air()

/turf/simulated/proc/c_copy_air()
	if(!air) air = new/datum/gas_mixture
	air.copy_from(zone.air)
	air.group_multiplier = 1
