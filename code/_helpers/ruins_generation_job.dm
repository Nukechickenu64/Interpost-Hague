// Async, throttled ruins generation across all space-ruins areas, with simple progress reporting.

// Global job handle
var/datum/ruins_generation_job/ruins_gen_job

/datum/ruins_generation_job
	var/active = FALSE
	var/cancelled = FALSE
	var/total = 0
	var/done = 0
	var/list/areas = list()
	var/profile_type = null
	var/last_error = null
	var/sleep_ticks = 2 // deciseconds between areas (~1.2s) to further reduce load

/datum/ruins_generation_job/proc/start(var/profile_path)
	if(active)
		return FALSE
	cancelled = FALSE
	last_error = null
	areas = list()
	// Only target ruins on the 6th z-level
	for(var/area/space/ruins/A in world)
		if(A)
			var/list/b = A.get_area_bounds()
			if(b && b.len >= 5)
				var/zlev = b[5]
				if(zlev == 6)
					areas += A
	total = areas.len
	done = 0
	profile_type = null
	if(profile_path && ispath(profile_path, /datum/ruins_generation_profile))
		profile_type = profile_path
	// Make sure the Mining shuttle has a Space waypoint on z=6
	ensure_mining_space_landmark()
	// Metrics and signal: announce job configured
	metrics_inc("ruins.total", total)
	signal_emit("ruins_generation:started", total)
	active = TRUE
	// Kick off background processing
	spawn(1)
		processing_loop()
	return TRUE

/datum/ruins_generation_job/proc/ensure_mining_space_landmark()
	// Ensure a mining_space waypoint exists on z=6 so the Mining shuttle can travel to open space
	if(SSshuttle && SSshuttle.get_landmark("nav_mining_space_ruins"))
		return
	var/turf/T = null
	var/radius = 10 // 10x10 circle (diameter 10 => radius 5)

	// First try to find an existing circle of space turfs with the required radius on z=6
	for(var/yy = 1 + radius, yy <= world.maxy - radius, yy++)
		for(var/xx = 1 + radius, xx <= world.maxx - radius, xx++)
			var/turf/center = locate(xx, yy, 6)
			if(!center) continue
			var/all_space = TRUE
			var/list/circle = circlerangeturfs(center, radius)
			for(var/turf/CT in circle)
				if(!istype(CT, /turf/space))
					all_space = FALSE
					break
			if(all_space)
				T = center
				break
		if(T) break

	// If none found, carve one by converting a circle of turfs to /turf/space and use that center
	if(!T)
		// Choose a reasonable center: prefer (64,64,6) if in-bounds, else map center
		var/cx = clamp(64, 1 + radius, world.maxx - radius)
		var/cy = clamp(64, 1 + radius, world.maxy - radius)
		if(cx > world.maxx - radius || cy > world.maxy - radius)
			cx = round(world.maxx / 2)
			cy = round(world.maxy / 2)
			cx = clamp(cx, 1 + radius, world.maxx - radius)
			cy = clamp(cy, 1 + radius, world.maxy - radius)
		var/turf/center = locate(cx, cy, 6)
		if(center)
			var/list/circle = circlerangeturfs(center, radius)
			for(var/turf/CT in circle)
				if(!istype(CT, /turf/space))
					CT.ChangeTurf(/turf/space)
			T = center

	if(!T) return
	// Create the space waypoint; it will self-register and clear a landing zone
	new /obj/effect/shuttle_landmark/mining/space(T)

/datum/ruins_generation_job/proc/processing_loop()
	// Process one area per tick to spread cost. If an area throws, store error and continue.
	while(active && !cancelled && done < total)
		var/area/space/ruins/A = areas[done+1]
		if(A)
			try
				A.generate_ruins_turfs(profile_type)
			catch(var/exception/e)
				last_error = "[e] at area #[done+1]"
				// continue despite error
		done++
		metrics_inc("ruins.done", 1)
		signal_emit("ruins_generation:area_done", A)
		// light throttle between areas
		sleep(sleep_ticks)
	active = FALSE
	cancelled = FALSE
	// Finalize
	signal_emit("ruins_generation:complete", list(total = total, done = done, error = last_error))

/datum/ruins_generation_job/proc/get_percent()
	if(total <= 0)
		return 100
	return clamp(round((done * 100.0) / total), 0, 100)

/datum/ruins_generation_job/proc/is_active()
	return active

/datum/ruins_generation_job/proc/cancel()
	if(!active)
		return FALSE
	cancelled = TRUE
	return TRUE
