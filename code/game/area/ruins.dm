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
	// Defer generation one tick to ensure the map is fully initialized
	spawn(1)
		// Sample this area's background space radiation once (Gaussian around COSMIC_RADS_BASE)
		if(!isnum(space_rads_base))
			space_rads_base = sample_space_rads()
		// Select or create a generation profile (datum-driven)
		if(!ruins_profile)
			if(ispath(ruins_profile_type))
				ruins_profile = new ruins_profile_type
			else
				ruins_profile = pick_ruins_profile()
		generate_ruins_turfs()
		place_random_ruin_object()
		place_mining_lz()

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

	var/list/g00 = grad2(hash2(x0, y0, perlin_seed))
	var/list/g10 = grad2(hash2(x1, y0, perlin_seed))
	var/list/g01 = grad2(hash2(x0, y1, perlin_seed))
	var/list/g11 = grad2(hash2(x1, y1, perlin_seed))

	var/n00 = dot2(g00, xf    , yf    )
	var/n10 = dot2(g10, xf-1  , yf    )
	var/n01 = dot2(g01, xf    , yf-1  )
	var/n11 = dot2(g11, xf-1  , yf-1  )

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

/area/space/ruins/proc/get_area_bounds()
	// Returns list(minx, miny, maxx, maxy, z)
	var/minx =  1<<30
	var/miny =  1<<30
	var/maxx = -1
	var/maxy = -1
	var/zlev = 0
	for(var/turf/T in src)
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

/area/space/ruins/proc/generate_ruins_turfs(var/profile_override = null)
	// Generate clumpy terrain by picking 6-8 high-noise clump centers, making rocks at cores and floor around
	var/list/b = get_area_bounds()
	if(!b || b.len < 5) return
	var/minx = b[1]
	var/miny = b[2]
	var/maxx = b[3]
	var/maxy = b[4]
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

	// Precompute domain-warped noise for each turf
	var/list/noise_of = list() // turf -> noise
	for(var/turf/T in src)
		var/nx = (T.x - minx) / width
		var/ny = (T.y - miny) / height
		var/warp_x = (perlin2d((nx * perlin_scale) * warp_freq + 123.45, (ny * perlin_scale) * warp_freq + 67.89) - 0.5) * 2
		var/warp_y = (perlin2d((nx * perlin_scale) * warp_freq + 98.76, (ny * perlin_scale) * warp_freq + 54.32) - 0.5) * 2
		var/sx = (nx + warp_amp * warp_x) * perlin_scale
		var/sy = (ny + warp_amp * warp_y) * perlin_scale
		noise_of[T] = perlin2d(sx, sy)

	// Pick clump centers by greedy selection of highest noise with minimum separation
	var/target_clumps = rand(ruins_profile ? ruins_profile.clumps_min : 6, ruins_profile ? ruins_profile.clumps_max : 12)
	var/min_sep = max(4, round(min(width, height) / 6))
	var/min_sep2 = min_sep * min_sep
	var/list/centers = list() // list of turfs
	while(centers.len < target_clumps)
		var/turf/best = null
		var/bestn = -1.0
		for(var/turf/T in src)
			var/n = noise_of[T]
			if(n <= bestn)
				continue
			// Enforce separation from existing centers
			var/ok = TRUE
			for(var/turf/C in centers)
				var/dx = T.x - C.x
				var/dy = T.y - C.y
				if(dx*dx + dy*dy < min_sep2)
					ok = FALSE; break
			if(!ok) continue
			best = T
			bestn = n
		if(best)
			centers += best
		else
			break // couldn't find more with separation

	// Assign radii per center and classify tiles
	var/list/rock_r2 = list() // center turf -> rock radius^2
	var/list/floor_r2 = list() // center turf -> floor radius^2
	for(var/turf/C in centers)
		var/base_divisor = ruins_profile ? ruins_profile.base_divisor : 10
		var/base_r = max(ruins_profile ? ruins_profile.rock_min : 4, round(min(width, height) / base_divisor))
		var/rand_low = ruins_profile ? ruins_profile.rand_low : 80
		var/rand_high = ruins_profile ? ruins_profile.rand_high : 130
		var/rock_min = ruins_profile ? ruins_profile.rock_min : 4
		var/rock_max = max(6, round(min(width,height) * (ruins_profile ? ruins_profile.rock_max_frac : 0.25)))
		var/r_rock = clamp(round(base_r * rand(rand_low, rand_high) / 100), rock_min, rock_max)
		var/floor_extra_div = ruins_profile ? ruins_profile.floor_extra_div : 2
		var/r_floor = r_rock + max(2, round(base_r / floor_extra_div))
		rock_r2[C] = r_rock * r_rock
		floor_r2[C] = r_floor * r_floor

	// Apply classes: 2=mineral inside rock radius; 1=floor inside floor radius; else space
	for(var/turf/T in src)
		var/class = 0
		for(var/turf/C in centers)
			var/dx = T.x - C.x
			var/dy = T.y - C.y
			var/d2 = dx*dx + dy*dy
			if(d2 <= rock_r2[C])
				class = 2; break
			else if(d2 <= floor_r2[C])
				if(class < 1) class = 1
		if(class == 2)
			if(!istype(T, /turf/simulated/mineral) && can_replace_ruins_turf(T))
				T.ChangeTurf(mineral_type)
		else if(class == 1)
			if(!istype(T, /turf/simulated/floor/asteroid) && can_replace_ruins_turf(T))
				T.ChangeTurf(/turf/simulated/floor/asteroid)
		else
			if(!istype(T, /turf/space) && can_replace_ruins_turf(T))
				T.ChangeTurf(/turf/space)

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

/area/space/ruins/proc/place_random_ruin_object()
	// Choose a random space ruin map template and load it somewhere within this area
	var/list/templates = typesof(/datum/map_template/ruin/space) - /datum/map_template/ruin/space
	if(!templates || !templates.len)
		// Fallback: specific known DMM if template list isn't available
		// If the map_template system isn't present, safely do nothing
		return

	var/path_choice = pick(templates)
	var/datum/map_template/ruin/space/ruin = new path_choice
	// Gather candidate turfs (prefer simulated for stability)
	var/list/candidates = list()
	for(var/turf/T in src)
		if(!(T.turf_flags & TURF_FLAG_NORUINS))
			candidates += T
	if(!candidates.len) return
	var/turf/center = pick(candidates)
	// Attempt to load centered; clear non-anchored movables within footprint first
	var/list/affected = ruin.get_affected_turfs(center, 1)
	if(affected && affected.len)
		for(var/turf/T in affected)
			for(var/atom/movable/AM in T)
				if(!AM.anchored)
					qdel(AM)
	ruin.load(center, centered = TRUE)
	return

// Create a mining shuttle landing landmark within the ruins area
/area/space/ruins/proc/place_mining_lz()
	var/list/b = get_area_bounds()
	if(!b || b.len < 5) return
	var/minx = b[1]
	var/miny = b[2]
	var/maxx = b[3]
	var/maxy = b[4]
	var/zlev = b[5]
	var/cx = round((minx + maxx) / 2)
	var/cy = round((miny + maxy) / 2)
	var/turf/T = locate(cx, cy, zlev)
	if(!T || get_area(T) != src)
		// Fallback: pick any turf in area
		for(var/turf/TT in src)
			T = TT; break
	if(!T) return

	var/obj/effect/shuttle_landmark/automatic/clearing/LZ = new(T)
	if(LZ)
		LZ.radius = 6 // smaller clearing so we don't wipe large portions of the ruin
		// Give each ruin a unique, readable name so multiple landing options appear distinctly
		LZ.name = "Ruin [T.x],[T.y]"
		LZ.landmark_tag = "nav_mining_ruin_[T.x]_[T.y]_[T.z]"
		LZ.shuttle_restricted = "Mining"
		LZ.SetName("Ruin [T.x],[T.y]")
		SSshuttle.register_landmark(LZ)


