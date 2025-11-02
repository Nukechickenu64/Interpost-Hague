/area/space/ruins
	name = "Ruins Space"
	icon_state = "ruins_space"


/area/space/ruins/Initialize()
	. = ..()
	// Defer generation one tick to ensure the map is fully initialized
	spawn(1)
		generate_ruins_turfs()
		place_random_ruin_object()

/area/space/ruins/var/perlin_seed
/area/space/ruins/var/perlin_freq = 0.10		// bigger = more, smaller features
/area/space/ruins/var/perlin_octaves = 3
/area/space/ruins/var/perlin_persistence = 0.5
/area/space/ruins/var/perlin_lacunarity = 2.0
/area/space/ruins/var/mineral_threshold = 0.62 // tiles above this become mineral

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
	// Prefer requested path if it exists; otherwise fallback to something rocky
	var/path = text2path("/turf/simulated/mineral")
	if(path)
		return path
	// Try a generic sandstone wall if mineral doesn't exist in this codebase
	return /turf/simulated/wall/sandstone

/area/space/ruins/proc/generate_ruins_turfs()
	// Generate mineral patches using Perlin noise over the area's bounds
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

	for(var/turf/T in src)
		// Normalize coordinates to avoid giant world-coord steps
		var/nx = (T.x - minx) / width
		var/ny = (T.y - miny) / height
		var/noise = perlin2d(nx * 100, ny * 100) // expand to get nice features regardless of area size
		if(noise >= mineral_threshold)
			if(istype(T, /turf/space) || istype(T, /turf/simulated/floor) || istype(T, /turf/unsimulated))
				new mineral_type(T)
	return

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
	// Attempt to load centered; the loader will handle overlaps
	ruin.load(center, centered = TRUE)
	return

