GLOBAL_LIST_EMPTY(banned_ruin_ids)

/proc/seedRuins(list/z_levels = null, budget = 0, whitelist = /area/space, list/potentialRuins, var/maxx = world.maxx, var/maxy = world.maxy)
	if(!z_levels || !z_levels.len)
		world.log << "No Z levels provided - Not generating ruins"
		return

	for(var/zl in z_levels)
		var/turf/T = locate(1, 1, zl)
		if(!T)
			world.log << "Z level [zl] does not exist - Not generating ruins"
			return

	var/list/ruins = potentialRuins.Copy()
	for(var/R in potentialRuins)
		var/datum/map_template/ruin/ruin = R
		if(ruin.id in GLOB.banned_ruin_ids)
			ruins -= ruin //remove all prohibited ids from the candidate list; used to forbit global duplicates.

//Each iteration needs to either place a ruin or strictly decrease either the budget or ruins.len (or break).
	while(budget > 0)
		// Pick a ruin
		var/datum/map_template/ruin/ruin = null
		if(ruins && ruins.len)
			ruin = pick(ruins)
			if(ruin.cost > budget)
				ruins -= ruin
				continue //Too expensive, get rid of it and try again
		else
			log_world("Ruin loader had no ruins to pick from with [budget] left to spend.")
			break
		// Try to place it
		var/sanity = 20
		// And if we can't fit it anywhere, give up, try again

		while(sanity > 0)
			sanity--

			var/width_border = TRANSITIONEDGE + RUIN_MAP_EDGE_PAD + round(ruin.width / 2)
			var/height_border = TRANSITIONEDGE + RUIN_MAP_EDGE_PAD + round(ruin.height / 2)
			var/z_level = pick(z_levels)
			if(width_border > maxx - width_border || height_border > maxx - height_border) // Too big and will never fit.
				ruins -= ruin //So let's not even try anymore with this one.
				break

			var/turf/T = locate(rand(width_border, maxx - width_border), rand(height_border, maxy - height_border), z_level)
			var/valid = TRUE

			for(var/turf/check in ruin.get_affected_turfs(T,1))
				var/area/new_area = get_area(check)
				if(!(istype(new_area, whitelist)) || check.turf_flags & TURF_FLAG_NORUINS)
					if(sanity == 0)
						ruins -= ruin //It didn't fit, and we are out of sanity. Let's make sure not to keep trying the same one.
					valid = FALSE
					break //Let's try again

			if(!valid)
				continue
			log_world("Ruin \"[ruin.name]\" placed at ([T.x], [T.y], [T.z])")

			// Apply Perlin-based terrain within the footprint prior to loading the ruin
			var/list/affected = ruin.get_affected_turfs(T,1)
			if(affected && affected.len)
				apply_ruins_perlin_terrain(affected, null)

			load_ruin(T, ruin)

			// Drop a Mining-restricted landing zone so the mining shuttle can land at this ruin
			var/obj/effect/shuttle_landmark/automatic/clearing/LZ = new(T)
			if(LZ)
				LZ.landmark_tag = "nav_mining_ruin_[T.x]_[T.y]_[T.z]"
				LZ.shuttle_restricted = "Mining"
				LZ.SetName("Ruin LZ ([T.x],[T.y])")
			if(ruin.cost >= 0)
				budget -= ruin.cost
			if(!(ruin.template_flags & TEMPLATE_FLAG_ALLOW_DUPLICATES))
				for(var/other_ruin_datum in ruins)
					var/datum/map_template/ruin/other_ruin = other_ruin_datum
					if(ruin.id == other_ruin.id)
						ruins -= ruin //Remove all ruins with the same id if we don't allow duplicates
				GLOB.banned_ruin_ids += ruin.id //and ban them globally too
			break

proc/load_ruin(turf/central_turf, datum/map_template/template)
	if(!template)
		return FALSE
	for(var/i in template.get_affected_turfs(central_turf, 1))
		var/turf/T = i
		// Clear hostile/simple mobs
		for(var/mob/living/simple_animal/monster in T)
			qdel(monster)
		// Remove non-anchored movables to make room for template
		for(var/atom/movable/AM in T)
			if(!AM.anchored)
				qdel(AM)
	template.load(central_turf,centered = TRUE)
	var/datum/map_template/ruin = template
	if(istype(ruin))
		new /obj/effect/landmark/ruin(central_turf, ruin)

	if(template.template_flags & TEMPLATE_FLAG_NO_RUINS)
		for(var/i in template.get_affected_turfs(central_turf, 1))
			var/turf/T = i
			T.turf_flags |= TURF_FLAG_NORUINS

	return TRUE

// ===== Global helpers to generate ruins on arbitrary turf lists =====

/proc/safe_mineral_turf_path()
	// Prefer random/high_chance variants for proper visual rock walls, then base mineral
	var/path
	path = text2path("/turf/simulated/mineral/random/high_chance")
	if(path)
		return path
	path = text2path("/turf/simulated/mineral/random")
	if(path)
		return path
	path = text2path("/turf/simulated/mineral")
	if(path)
		return path
	return /turf/simulated/wall/sandstone

// Only replace safe, generator-owned terrain: space, asteroid floor, mineral, or unsimulated
/proc/ruins_can_replace_turf(var/turf/T)
	if(istype(T, /turf/space)) return TRUE
	if(istype(T, /turf/simulated/floor/asteroid)) return TRUE
	if(istype(T, /turf/simulated/mineral)) return TRUE
	if(istype(T, /turf/unsimulated)) return TRUE
	return FALSE

/proc/ruins_fade(var/t)
	return t*t*t*(t*(t*6 - 15) + 10)

/proc/ruins_lerp(var/a, var/b, var/t)
	return a + (b - a) * t

/proc/ruins_hash2(var/x, var/y, var/seed)
	var/i = x * 374761393
	i = (i ^ (y * 668265263))
	i = (i ^ (seed * 1274126177))
	i = (i * 1597334677)
	if(i < 0) i = -i
	return i

/proc/ruins_grad2(var/h)
	switch(h & 7)
		if(0) return list( 1, 0)
		if(1) return list(-1, 0)
		if(2) return list( 0, 1)
		if(3) return list( 0,-1)
		if(4) return list( 1, 1)
		if(5) return list(-1, 1)
		if(6) return list( 1,-1)
		else return list(-1,-1)

/proc/ruins_dot2(var/list/g, var/x, var/y)
	return g[1]*x + g[2]*y

/proc/ruins_perlin2d_raw(var/seed, var/freq, var/x, var/y)
	var/X = x * freq
	var/Y = y * freq
	var/x0 = floor(X)
	var/y0 = floor(Y)
	var/x1 = x0 + 1
	var/y1 = y0 + 1
	var/xf = X - x0
	var/yf = Y - y0
	var/list/g00 = ruins_grad2(ruins_hash2(x0, y0, seed))
	var/list/g10 = ruins_grad2(ruins_hash2(x1, y0, seed))
	var/list/g01 = ruins_grad2(ruins_hash2(x0, y1, seed))
	var/list/g11 = ruins_grad2(ruins_hash2(x1, y1, seed))
	var/n00 = ruins_dot2(g00, xf    , yf    )
	var/n10 = ruins_dot2(g10, xf-1  , yf    )
	var/n01 = ruins_dot2(g01, xf    , yf-1  )
	var/n11 = ruins_dot2(g11, xf-1  , yf-1  )
	var/u = ruins_fade(xf)
	var/v = ruins_fade(yf)
	var/xLerp1 = ruins_lerp(n00, n10, u)
	var/xLerp2 = ruins_lerp(n01, n11, u)
	var/nxy = ruins_lerp(xLerp1, xLerp2, v)
	return (nxy + 1) / 2

/proc/ruins_perlin2d(var/seed, var/base_freq, var/octaves, var/persistence, var/lacunarity, var/x, var/y)
	var/amp = 1.0
	var/freq = base_freq
	var/sum = 0.0
	var/max_sum = 0.0
	for(var/i = 1, i <= octaves, i++)
		sum += ruins_perlin2d_raw(seed, freq, x, y) * amp
		max_sum += amp
		amp *= persistence
		freq *= lacunarity
	return sum / (max_sum ? max_sum : 1)

/proc/generate_ruins_on_turfs(var/list/turfs, var/list/config = null, var/list/template_types = null)
	if(!turfs || !turfs.len)
		return null
	// Defaults
	var/perlin_freq = 0.10
	var/perlin_octaves = 3
	var/perlin_persistence = 0.5
	var/perlin_lacunarity = 2.0
	var/mineral_threshold = 0.62
	var/asteroid_threshold = 0.48
	if(config)
		if(!isnull(config["perlin_freq"])) perlin_freq = config["perlin_freq"]
		if(!isnull(config["perlin_octaves"])) perlin_octaves = config["perlin_octaves"]
		if(!isnull(config["perlin_persistence"])) perlin_persistence = config["perlin_persistence"]
		if(!isnull(config["perlin_lacunarity"])) perlin_lacunarity = config["perlin_lacunarity"]
		if(!isnull(config["mineral_threshold"])) mineral_threshold = config["mineral_threshold"]
		if(!isnull(config["asteroid_threshold"])) asteroid_threshold = config["asteroid_threshold"]

	// Bounds
	var/minx =  1<<30
	var/miny =  1<<30
	var/maxx = -1
	var/maxy = -1
	for(var/turf/T in turfs)
		if(T.x < minx) minx = T.x
		if(T.y < miny) miny = T.y
		if(T.x > maxx) maxx = T.x
		if(T.y > maxy) maxy = T.y
	var/width = max(1, maxx - minx)
	var/height = max(1, maxy - miny)
	var/seed = rand(1, 1<<30)
	var/mineral_type = safe_mineral_turf_path()

	for(var/turf/T in turfs)
		var/nx = (T.x - minx) / width
		var/ny = (T.y - miny) / height
		var/noise = ruins_perlin2d(seed, perlin_freq, perlin_octaves, perlin_persistence, perlin_lacunarity, nx * 100, ny * 100)
		if(noise >= mineral_threshold)
			// High noise: spawn mineral rock walls
			if(!istype(T, /turf/simulated/mineral) && ruins_can_replace_turf(T))
				T.ChangeTurf(mineral_type)
		else if(noise >= asteroid_threshold)
			// Mid noise: ensure asteroid floor
			if(!istype(T, /turf/simulated/floor/asteroid) && ruins_can_replace_turf(T))
				T.ChangeTurf(/turf/simulated/floor/asteroid)
		else
			// Low noise: ensure space
			if(!istype(T, /turf/space) && ruins_can_replace_turf(T))
				T.ChangeTurf(/turf/space)

	// Place a ruin template centered on a random candidate turf
	var/list/templates = template_types && template_types.len ? template_types : (typesof(/datum/map_template/ruin/space) - /datum/map_template/ruin/space)
	if(!templates || !templates.len)
		return pick(turfs)
	var/path_choice = pick(templates)
	var/datum/map_template/ruin/space/ruin = new path_choice
	var/turf/center = pick(turfs)
	ruin.load(center, centered = TRUE)
	return center

// Apply Perlin-based terrain classification without loading any templates
/proc/apply_ruins_perlin_terrain(var/list/turfs, var/list/config = null)
	if(!turfs || !turfs.len)
		return
	var/perlin_freq = 0.10
	var/perlin_octaves = 3
	var/perlin_persistence = 0.5
	var/perlin_lacunarity = 2.0
	var/mineral_threshold = 0.62
	var/asteroid_threshold = 0.48
	if(config)
		if(!isnull(config["perlin_freq"])) perlin_freq = config["perlin_freq"]
		if(!isnull(config["perlin_octaves"])) perlin_octaves = config["perlin_octaves"]
		if(!isnull(config["perlin_persistence"])) perlin_persistence = config["perlin_persistence"]
		if(!isnull(config["perlin_lacunarity"])) perlin_lacunarity = config["perlin_lacunarity"]
		if(!isnull(config["mineral_threshold"])) mineral_threshold = config["mineral_threshold"]
		if(!isnull(config["asteroid_threshold"])) asteroid_threshold = config["asteroid_threshold"]

	var/minx =  1<<30
	var/miny =  1<<30
	var/maxx = -1
	var/maxy = -1
	for(var/turf/T in turfs)
		if(T.x < minx) minx = T.x
		if(T.y < miny) miny = T.y
		if(T.x > maxx) maxx = T.x
		if(T.y > maxy) maxy = T.y
	var/width = max(1, maxx - minx)
	var/height = max(1, maxy - miny)
	var/seed = rand(1, 1<<30)
	var/mineral_type = safe_mineral_turf_path()

	for(var/turf/T in turfs)
		var/nx = (T.x - minx) / width
		var/ny = (T.y - miny) / height
		var/noise = ruins_perlin2d(seed, perlin_freq, perlin_octaves, perlin_persistence, perlin_lacunarity, nx * 100, ny * 100)
		if(noise >= mineral_threshold)
			if(!istype(T, /turf/simulated/mineral) && ruins_can_replace_turf(T))
				T.ChangeTurf(mineral_type)
		else if(noise >= asteroid_threshold)
			if(!istype(T, /turf/simulated/floor/asteroid) && ruins_can_replace_turf(T))
				T.ChangeTurf(/turf/simulated/floor/asteroid)
		else
			if(!istype(T, /turf/space) && ruins_can_replace_turf(T))
				T.ChangeTurf(/turf/space)

/proc/find_space_region(var/w = 48, var/h = 48, var/list/z_levels = null, var/tries = 100)
	var/list/candidate_z = list()
	if(z_levels && z_levels.len)
		candidate_z = z_levels.Copy()
	else
		if(GLOB.using_map && GLOB.using_map.map_levels && GLOB.using_map.map_levels.len)
			for(var/z in GLOB.using_map.map_levels)
				candidate_z += z
		else
			for(var/z = 1, z <= world.maxz, z++) candidate_z += z

	while(tries-- > 0)
		var/z = pick(candidate_z)
		var/x1 = rand(2, max(2, world.maxx - w))
		var/y1 = rand(2, max(2, world.maxy - h))
		var/list/region = list()
		var/ok = TRUE
		for(var/x = x1, x < x1 + w, x++)
			for(var/y = y1, y < y1 + h, y++)
				var/turf/T = locate(x,y,z)
				if(!T || !(istype(T, /turf/space)))
					ok = FALSE; break
				if(T.turf_flags & TURF_FLAG_NORUINS)
					ok = FALSE; break
				region += T
			if(!ok) break
		if(ok && region.len)
			return region
	return null

// ===== Distress beacon datums and registry =====

/datum/distress_beacon
	var/name = "Unknown Beacon"
	var/min_minutes = 0
	var/max_minutes = -1
	var/size_w = 48
	var/size_h = 48
	var/list/template_types = null
	var/perlin_freq = null
	var/perlin_octaves = null
	var/perlin_persistence = null
	var/perlin_lacunarity = null
	var/mineral_threshold = null

	proc/can_spawn(var/mins)
		if(mins < min_minutes) return FALSE
		if(max_minutes >= 0 && mins > max_minutes) return FALSE
		return TRUE

	proc/generate()
		var/list/turfs = find_space_region(size_w, size_h)
		if(!turfs) return null
		var/list/config = list(
			"perlin_freq" = isnull(perlin_freq) ? 0.10 : perlin_freq,
			"perlin_octaves" = isnull(perlin_octaves) ? 3 : perlin_octaves,
			"perlin_persistence" = isnull(perlin_persistence) ? 0.5 : perlin_persistence,
			"perlin_lacunarity" = isnull(perlin_lacunarity) ? 2.0 : perlin_lacunarity,
			"mineral_threshold" = isnull(mineral_threshold) ? 0.62 : mineral_threshold
		)
		var/turf/center = generate_ruins_on_turfs(turfs, config, template_types)
		if(!center)
			return null

		// Drop a landing landmark that the Mining shuttle can use, and clear a safe area around it
		var/obj/effect/shuttle_landmark/automatic/clearing/LZ = new(center)
		if(LZ)
			LZ.landmark_tag = "nav_mining_sos"
			LZ.shuttle_restricted = "Mining"
			LZ.SetName("Distress LZ ([center.x],[center.y])")
			// Best-effort: if the Mining shuttle is a ferry, point its offsite waypoint to this new LZ
			var/datum/shuttle/autodock/S = null
			if(SSshuttle && SSshuttle.shuttles)
				S = SSshuttle.shuttles["Mining"]
			if(istype(S, /datum/shuttle/autodock/ferry))
				var/datum/shuttle/autodock/ferry/F = S
				F.waypoint_offsite = LZ
				// If it's currently at station, update its next_location so UI can launch immediately
				if(F.get_location_waypoint() == F.waypoint_station)
					F.next_location = F.get_location_waypoint(1)

		return center

/datum/distress_beacon/derelict
	name = "Derelict Signal"
	min_minutes = 5
	size_w = 64
	size_h = 64
	mineral_threshold = 0.58

/datum/distress_beacon/mining_outpost
	name = "Mining Outpost SOS"
	min_minutes = 15
	size_w = 64
	size_h = 64
	perlin_freq = 0.08
	perlin_octaves = 4
	perlin_persistence = 0.55
	perlin_lacunarity = 2.2
	mineral_threshold = 0.55

// Registry of distress beacons available for scanning
/proc/get_distress_beacons()
	return list(new /datum/distress_beacon/derelict, new /datum/distress_beacon/mining_outpost)
