/area/space/ruins
	name = "Space Ruins"
	icon_state = "ruins_space"
	// Optional profile type override. If null, a profile will be picked at runtime.
	var/ruins_profile_type
	var/datum/ruins_generation_profile/ruins_profile
	// Radiation baseline for this ruins area (Bq), sampled from a bell curve around COSMIC_RADS_BASE
	var/space_rads_base

/area/space/ruins/Initialize()
	. = ..()
	if(!isnum(space_rads_base))
		space_rads_base = sample_space_rads()

// Approximate Gaussian sampler for per-area radiation, clamped to sane bounds
/area/space/ruins/proc/sample_space_rads()
	// Central Limit Theorem approximation using 6 uniforms in [0,1)
	var/sum = 0.0
	for(var/i = 1, i <= 6, i++)
		sum += rand(0, 1000) / 1000.0
	// sum has mean 3.0; subtract mean to center, scale by desired stddev
	var/norm = sum - 3.0
	var/value = COSMIC_RADS_BASE + (norm * COSMIC_RADS_STDDEV)
	// Clamp within bounds
	if(value < COSMIC_RADS_MIN)
		value = COSMIC_RADS_MIN
	if(value > COSMIC_RADS_MAX)
		value = COSMIC_RADS_MAX
	return value

/area/space/ruins/var/perlin_seed
// Legacy defaults preserved as fallbacks; values are provided by ruins_profile during generation
/area/space/ruins/var/perlin_freq = 0.10		// bigger = more, smaller features
/area/space/ruins/var/perlin_octaves = 3
/area/space/ruins/var/perlin_persistence = 0.5
/area/space/ruins/var/perlin_lacunarity = 2.0
/area/space/ruins/var/mineral_threshold = 0.58 // unused in clump generator, kept for compatibility
/area/space/ruins/var/asteroid_threshold = 0.48 // unused in clump generator, kept for compatibility
// Domain-warp & smoothing controls for clumpy patches
/area/space/ruins/var/warp_amp = 0.08         // how strongly to warp sample coords (0..~0.2)
/area/space/ruins/var/warp_freq = 0.5         // relative frequency for warp noise
/area/space/ruins/var/smooth_passes = 2       // how many majority passes to run (0..3)
/area/space/ruins/var/perlin_scale = 100      // coordinate scale factor for sampling

/area/space/ruins/proc/fade(var/t)
	// Quintic fade curve (Perlin)
	return t*t*t*(t*(t*6 - 15) + 10)

/area/space/ruins/proc/perlin_lerp(var/a, var/b, var/t)
	return a + (b - a) * t

/area/space/ruins/proc/hash2(var/x, var/y, var/seed)
	// Lightweight integer hash for 2D integer grid coords
	var/i = x * 374761393
	i = (i ^ (y * 668265263))
	i = (i ^ (seed * 1274126177))
	i = (i * 1597334677) // mix
	if(i < 0)
		i = -i
	return i

/area/space/ruins/proc/grad2(var/h)
	// 8 gradient directions
	switch(h & 7)
		if(0) return list( 1, 0)
		if(1) return list(-1, 0)
		if(2) return list( 0, 1)
		if(3) return list( 0,-1)
		if(4) return list( 1, 1)
		if(5) return list(-1, 1)
		if(6) return list( 1,-1)
		else return list(-1,-1)

/area/space/ruins/proc/dot2(var/list/g, var/x, var/y)
	return g[1]*x + g[2]*y

/area/space/ruins/proc/gradient_dot2(var/hash, var/x, var/y)
	switch(hash & 7)
		if(0) return x
		if(1) return -x
		if(2) return y
		if(3) return -y
		if(4) return x + y
		if(5) return -x + y
		if(6) return x - y
		else return -x - y

/area/space/ruins/proc/perlin2d_raw(var/x, var/y)
	// Compute single-octave Perlin noise at float x,y using area seed and perlin_freq
	if(!perlin_seed)
		perlin_seed = rand(1, 1<<30)
	// scale world-space
	var/X = x * perlin_freq
	var/Y = y * perlin_freq
	var/x0 = floor(X)
	var/y0 = floor(Y)
	var/x1 = x0 + 1
	var/y1 = y0 + 1
	var/xf = X - x0
	var/yf = Y - y0

	var/n00 = gradient_dot2(hash2(x0, y0, perlin_seed), xf, yf)
	var/n10 = gradient_dot2(hash2(x1, y0, perlin_seed), xf - 1, yf)
	var/n01 = gradient_dot2(hash2(x0, y1, perlin_seed), xf, yf - 1)
	var/n11 = gradient_dot2(hash2(x1, y1, perlin_seed), xf - 1, yf - 1)

	var/u = fade(xf)
	var/v = fade(yf)

	var/xLerp1 = perlin_lerp(n00, n10, u)
	var/xLerp2 = perlin_lerp(n01, n11, u)
	var/nxy = perlin_lerp(xLerp1, xLerp2, v)

	// Normalize rough range ~[-1,1] -> [0,1]
	return (nxy + 1) / 2

/area/space/ruins/proc/perlin2d(var/x, var/y)
	// Fractal Brownian Motion (octaves)
	var/amp = 1.0
	var/freq_backup = perlin_freq
	var/sum = 0.0
	var/max_sum = 0.0
	for(var/i = 1, i <= perlin_octaves, i++)
		// Temporarily set frequency for this octave
		perlin_freq = freq_backup * ((perlin_lacunarity) ** (i-1))
		sum += perlin2d_raw(x, y) * amp
		max_sum += amp
		amp *= perlin_persistence
	// Restore
	perlin_freq = freq_backup
	return sum / max_sum

/datum/ruins_generation_budget
	var/operations = 0
	var/tick_start = 0
	var/phase_duration = 0
	var/phase_work = 0
	var/diagnostic_stage
	var/slice_start = 0
	var/first_slice = FALSE
	var/slow_slice_logged = FALSE

/datum/ruins_generation_budget/New()
	..()
	tick_start = world.tick_usage

/datum/ruins_generation_budget/proc/begin_phase(var/work, var/eta_fraction, var/stage = null)
	phase_work = max(1, work)
	phase_duration = 0
	diagnostic_stage = config && config.log_debug ? stage : null
	slice_start = world.realtime
	first_slice = TRUE
	slow_slice_logged = FALSE
	if(mining_expedition && mining_expedition.mission_pending)
		var/datum/shuttle/autodock/shuttle = mining_expedition.get_shuttle()
		if(shuttle && shuttle.moving_status == SHUTTLE_INTRANSIT)
			phase_duration = max(0, mining_expedition.mission_arrival_time - world.time) * eta_fraction
	operations = 0
	tick_start = world.tick_usage

/datum/ruins_generation_budget/proc/check(var/cost = 0.125)
	if(ruins_gen_job && ruins_gen_job.is_active() && ruins_gen_job.cancelled)
		throw EXCEPTION("Survey cancelled.")
	operations += cost
	var/batch_limit = phase_duration > 0 ? clamp(ceil(phase_work * world.tick_lag / phase_duration), 16, 1024) : 512
	var/tick_usage_slice_limit = phase_duration > 0 ? 2 : 10
	if(operations >= batch_limit || world.tick_usage >= tick_start + tick_usage_slice_limit || world.tick_usage >= 30 || TICK_CHECK)
		if(diagnostic_stage)
			var/slice_usage = world.tick_usage - tick_start
			var/slow_slice = slice_usage >= 10
			if(first_slice || (slow_slice && !slow_slice_logged))
				log_debug("Mining generation [diagnostic_stage]: [first_slice ? "first" : "slow"] slice elapsed=[(world.realtime - slice_start) / 10]s tick_usage=[world.tick_usage]% slice_usage=[slice_usage]% work=[operations]")
			first_slice = FALSE
			if(slow_slice)
				slow_slice_logged = TRUE
		sleep(world.tick_lag)
		operations = 0
		tick_start = world.tick_usage
		slice_start = world.realtime

/area/space/ruins/proc/get_area_bounds()
	if(mining_expedition && mining_expedition.ruins_ready && src == mining_expedition.ruins_area)
		return list(1, 1, world.maxx, world.maxy, mining_expedition.ruins_z)
	// Returns list(minx, miny, maxx, maxy, z)
	var/minx =  1<<30
	var/miny =  1<<30
	var/maxx = -1
	var/maxy = -1
	var/zlev = 0
	var/datum/ruins_generation_budget/budget = new
	for(var/turf/T in src)
		budget.check()
		if(T.x < minx) minx = T.x
		if(T.y < miny) miny = T.y
		if(T.x > maxx) maxx = T.x
		if(T.y > maxy) maxy = T.y
		zlev = T.z
	return list(minx, miny, maxx, maxy, zlev)

/area/space/ruins/proc/safe_mineral_path()
	// Prefer random mineral variants for proper visuals, then base mineral, else fallback
	var/path
	path = text2path("/turf/simulated/mineral/random/high_chance")
	if(path) return path
	path = text2path("/turf/simulated/mineral/random")
	if(path) return path
	path = text2path("/turf/simulated/mineral")
	if(path) return path
	// Generic fallback
	return /turf/simulated/wall/sandstone

/area/space/ruins/proc/generate_ruins_turfs(var/profile_override = null, var/list/exclusion = null)
	set background = 1
	// Generate clumpy terrain by picking high-noise clump centers and making rocks at their cores
	var/list/b = get_area_bounds()
	if(!b || b.len < 5) return
	var/minx = b[1]
	var/miny = b[2]
	var/maxx = b[3]
	var/maxy = b[4]
	var/zlev = b[5]
	// For the ruins z-level, expand generation to the full map bounds (fill entire 128x128)
	if(zlev == get_space_ruins_z())
		minx = 1
		miny = 1
		maxx = min(world.maxx, 128)
		maxy = min(world.maxy, 128)
	if(maxx <= minx || maxy <= miny) return

	var/width = max(1, maxx - minx)
	var/height = max(1, maxy - miny)
	var/mineral_type = safe_mineral_path()

	// Ensure a profile exists (lazy selection if needed) or apply an override
	if(profile_override && ispath(profile_override, /datum/ruins_generation_profile))
		ruins_profile_type = profile_override
		ruins_profile = new ruins_profile_type
	if(!ruins_profile)
		if(ispath(ruins_profile_type))
			ruins_profile = new ruins_profile_type
		else
			ruins_profile = pick_ruins_profile()

	// Adopt profile values for the duration of this generation call
	var/old_perlin_freq = perlin_freq
	var/old_perlin_octaves = perlin_octaves
	var/old_perlin_persistence = perlin_persistence
	var/old_perlin_lacunarity = perlin_lacunarity
	var/old_perlin_scale = perlin_scale
	var/old_warp_amp = warp_amp
	var/old_warp_freq = warp_freq

	if(ruins_profile)
		perlin_freq = ruins_profile.perlin_freq
		perlin_octaves = ruins_profile.perlin_octaves
		perlin_persistence = ruins_profile.perlin_persistence
		perlin_lacunarity = ruins_profile.perlin_lacunarity
		perlin_scale = ruins_profile.perlin_scale
		warp_amp = ruins_profile.warp_amp
		warp_freq = ruins_profile.warp_freq

	// Precompute domain-warped noise for each turf within the generation rectangle
	var/list/noise_of = list() // turf -> noise
	var/datum/ruins_generation_budget/budget = new
	var/tile_count = (maxx - minx + 1) * (maxy - miny + 1)
	budget.begin_phase(tile_count * 4, 0.4, "terrain noise")
	for(var/yy = miny, yy <= maxy, yy++)
		for(var/xx = minx, xx <= maxx, xx++)
			budget.check(4)
			var/turf/T = locate(xx, yy, zlev)
			if(!T) continue
			var/nx = (xx - minx) / width
			var/ny = (yy - miny) / height
			var/warp_x = (perlin2d_raw((nx * perlin_scale) * warp_freq + 123.45, (ny * perlin_scale) * warp_freq + 67.89) - 0.5) * 2
			var/warp_y = (perlin2d_raw((nx * perlin_scale) * warp_freq + 98.76, (ny * perlin_scale) * warp_freq + 54.32) - 0.5) * 2
			var/sx = (nx + warp_amp * warp_x) * perlin_scale
			var/sy = (ny + warp_amp * warp_y) * perlin_scale
			noise_of[T] = perlin2d(sx, sy)
		CHECK_TICK

	// Pick clump centers by greedy selection of highest noise with minimum separation
	var/target_clumps = rand(ruins_profile ? ruins_profile.clumps_min : 6, ruins_profile ? ruins_profile.clumps_max : 12)
	var/min_sep = max(4, round(min(width, height) / 6))
	var/min_sep2 = min_sep * min_sep
	var/list/centers = list() // list of turfs
	// Select each center with a bounded scan. Sorting an associative turf-to-noise
	// list can recurse through large map lists on older BYOND runtimes.
	var/list/candidates = noise_of.Copy()
	while(centers.len < target_clumps && candidates.len)
		var/turf/best = null
		var/bestn = -1.0
		budget.begin_phase(candidates.len * 0.25, 0.3 / max(1, target_clumps - centers.len), "clump scan [centers.len + 1]/[target_clumps]")
		for(var/turf/T in candidates)
			budget.check()
			if(candidates[T] > bestn)
				best = T
				bestn = candidates[T]
		if(!best)
			break
		centers += best
		var/list/remaining = list()
		for(var/turf/T in candidates)
			budget.check()
			var/dx = T.x - best.x
			var/dy = T.y - best.y
			if(dx*dx + dy*dy >= min_sep2)
				remaining[T] = candidates[T]
		candidates = remaining

	// Assign rock radii per center
	var/list/rock_r2 = list() // center turf -> rock radius^2
	for(var/turf/C in centers)
		var/base_divisor = ruins_profile ? ruins_profile.base_divisor : 10
		var/base_r = max(ruins_profile ? ruins_profile.rock_min : 4, round(min(width, height) / base_divisor))
		var/rand_low = ruins_profile ? ruins_profile.rand_low : 80
		var/rand_high = ruins_profile ? ruins_profile.rand_high : 130
		var/rock_min = ruins_profile ? ruins_profile.rock_min : 4
		var/rock_max = max(6, round(min(width,height) * (ruins_profile ? ruins_profile.rock_max_frac : 0.25)))
		var/r_rock = clamp(round(base_r * rand(rand_low, rand_high) / 100), rock_min, rock_max)
		rock_r2[C] = r_rock * r_rock

	// Rock inside a clump's radius, bare space everywhere else (no asteroid floor rings)
	budget.begin_phase(tile_count * 4, 0.8, "terrain placement")
	for(var/yy3 = miny, yy3 <= maxy, yy3++)
		for(var/xx3 = minx, xx3 <= maxx, xx3++)
			budget.check(4)
			var/turf/T = locate(xx3, yy3, zlev)
			if(!T) continue
			var/is_rock = FALSE
			if(!turf_in_exclusion(T, exclusion))
				for(var/turf/C in centers)
					var/dx = T.x - C.x
					var/dy = T.y - C.y
					if(dx*dx + dy*dy <= rock_r2[C])
						is_rock = TRUE
						break
			if(!can_replace_ruins_turf(T))
				continue
			if(is_rock)
				T.ChangeTurf(mineral_type)
			else if(!istype(T, /turf/space))
				T.ChangeTurf(/turf/space)
		CHECK_TICK

	// Restore legacy values so future calls that assume area vars aren't impacted
	perlin_freq = old_perlin_freq
	perlin_octaves = old_perlin_octaves
	perlin_persistence = old_perlin_persistence
	perlin_lacunarity = old_perlin_lacunarity
	perlin_scale = old_perlin_scale
	warp_amp = old_warp_amp
	warp_freq = old_warp_freq
	return

// Only replace safe, generator-owned terrain: space, asteroid floor, mineral, or unsimulated
/area/space/ruins/proc/can_replace_ruins_turf(var/turf/T)
	if(istype(T, /turf/space)) return TRUE
	if(istype(T, /turf/simulated/floor/asteroid)) return TRUE
	if(istype(T, /turf/simulated/mineral)) return TRUE
	if(istype(T, /turf/unsimulated)) return TRUE
	return FALSE

/area/space/ruins/proc/place_random_ruin_object(var/list/exclusion = null, var/eta_fraction = 0)
	var/list/templates = list()
	var/datum/ruins_generation_budget/budget = new
	for(var/template_name in SSmapping.space_ruins_templates)
		templates += SSmapping.space_ruins_templates[template_name]
	if(!templates.len)
		for(var/path in subtypesof(/datum/map_template/ruin/space))
			templates += new path
	if(!templates.len)
		return null

	var/datum/map_template/ruin/space/ruin = pick(templates)
	if(!ruin.width || !ruin.height)
		return null
	var/half_w = round(ruin.width / 2)
	var/half_h = round(ruin.height / 2)
	var/minx = half_w + RUIN_MAP_EDGE_PAD
	var/miny = half_h + RUIN_MAP_EDGE_PAD
	var/maxx = world.maxx - ruin.width + half_w - RUIN_MAP_EDGE_PAD
	var/maxy = world.maxy - ruin.height + half_h - RUIN_MAP_EDGE_PAD
	if(maxx < minx || maxy < miny)
		return null
	var/zlev = get_space_ruins_z()

	for(var/attempt = 1, attempt <= 20, attempt++)
		var/turf/center = locate(rand(minx, maxx), rand(miny, maxy), zlev)
		if(!center)
			continue
		var/list/affected = ruin.get_affected_turfs(center, 1)
		var/ok = TRUE
		for(var/turf/T in affected)
			budget.check()
			// Area check also rejects overlap with earlier ruins, since templates bring their own areas
			if(T.loc != src || (T.turf_flags & TURF_FLAG_NORUINS) || turf_in_exclusion(T, exclusion))
				ok = FALSE
				break
		if(!ok)
			continue
		budget.begin_phase(affected.len * 4, eta_fraction)
		for(var/turf/T in affected)
			budget.check(4)
			for(var/atom/movable/AM in T)
				if(AM.simulated && !AM.anchored && !ismob(AM))
					qdel(AM)
			if(!istype(T, /turf/space))
				T.ChangeTurf(/turf/space)
		if(ruin.load(center, centered = TRUE))
			return center
	return null

/area/space/ruins/proc/place_salvage_ruins(var/count, var/list/exclusion = null)
	for(var/i = 1, i <= count, i++)
		sleep(1)
		place_random_ruin_object(exclusion, 1 / (count - i + 1))
		CHECK_TICK

// Resets the whole ruins z-level to empty space so a new mission can be generated.
/area/space/ruins/proc/wipe_ruins_level()
	var/zlev = get_space_ruins_z()
	if(!zlev)
		return
	var/datum/ruins_generation_budget/budget = new
	budget.begin_phase(world.maxx * world.maxy * 0.125, 0.2, "wipe")
	for(var/row = 1, row <= world.maxy, row++)
		for(var/column = 1, column <= world.maxx, column++)
			budget.check()
			var/turf/T = locate(column, row, zlev)
			for(var/atom/movable/AM in T)
				budget.check(4)
				if(istype(AM, /obj/effect/shuttle_landmark))
					var/obj/effect/shuttle_landmark/L = AM
					if(findtext(L.landmark_tag, "nav_mining_ruin_") == 1)
						SSshuttle.registered_shuttle_landmarks -= L.landmark_tag
						qdel(L)
					continue
				if(!AM.simulated)
					continue
				if(ismob(AM))
					var/mob/M = AM
					if(M.ckey || isobserver(M))
						continue
				qdel(AM)
			if(!istype(T, /turf/space))
				budget.check(4)
				T = T.ChangeTurf(/turf/space)
			if(T.loc != src)
				contents.Add(T)
		CHECK_TICK

// Create a mining shuttle landing landmark within the ruins area
/area/space/ruins/proc/place_mining_lz(var/turf/preferred_center = null)
	var/turf/T = preferred_center
	
	// If no preferred location, use area center
	if(!T)
		var/list/b = get_area_bounds()
		if(!b || b.len < 5) return
		var/minx = b[1]
		var/miny = b[2]
		var/maxx = b[3]
		var/maxy = b[4]
		var/zlev = b[5]
		var/cx = round((minx + maxx) / 2)
		var/cy = round((miny + maxy) / 2)
		T = locate(cx, cy, zlev)
	
	if(!T || get_area(T) != src)
		// Fallback: pick any turf in area
		for(var/turf/TT in src)
			T = TT; break
	if(!T) return

	var/obj/effect/shuttle_landmark/automatic/clearing/LZ = new(T)
	if(LZ)
		LZ.radius = 8 // clearing radius for shuttle landing
		// Give each ruin a unique, readable name so multiple landing options appear distinctly
		LZ.name = "Ruin [T.x],[T.y]"
		LZ.landmark_tag = "nav_mining_ruin_[T.x]_[T.y]_[T.z]"
		LZ.shuttle_restricted = "Mining"
		LZ.SetName("Ruin [T.x],[T.y]")
		// Note: The landmark auto-registers in its Initialize() proc


