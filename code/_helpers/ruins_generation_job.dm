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
	var/salvage = FALSE
	var/skip_wipe = FALSE
	var/datum/mining_expedition_controller/mission_controller
	var/datum/shuttle/mission_shuttle
	var/obj/effect/shuttle_landmark/mission_dock

/datum/ruins_generation_job/proc/start(var/profile_path, var/salvage_mission = FALSE, var/owned_mission = FALSE, var/fresh_level = FALSE, var/datum/mining_expedition_controller/controller = null)
	if(active)
		return FALSE
	var/datum/mining_expedition_controller/expedition = controller || get_mining_expedition()
	if(expedition.mission_pending && !owned_mission)
		return FALSE
	cancelled = FALSE
	last_error = null
	salvage = salvage_mission
	areas = list()
	var/area/space/ruins/ruins_area = get_space_ruins_area()
	if(!ruins_area || !get_space_ruins_z())
		last_error = "No debris field is ready for generation."
		return FALSE
	var/datum/shuttle/autodock/shuttle = owned_mission ? expedition.get_shuttle() : null
	if(owned_mission)
		if(!expedition.mission_pending || !shuttle || shuttle.moving_status != SHUTTLE_IDLE || !expedition.is_home_dock(shuttle))
			last_error = "The expedition shuttle is not holding at the station for preflight."
			return FALSE
	if(!expedition.can_regenerate_ruins(null, owned_mission))
		last_error = "The debris field is occupied or the shuttle is en route."
		return FALSE
	areas += ruins_area
	skip_wipe = owned_mission && fresh_level
	total = areas.len
	done = 0
	profile_type = null
	if(profile_path && ispath(profile_path, /datum/ruins_generation_profile))
		profile_type = profile_path
	ensure_mining_space_landmark()
	// Metrics and signal: announce job configured
	metrics_inc("ruins.total", total)
	signal_emit("ruins_generation:started", total)
	active = TRUE
	expedition.ruins_fresh = FALSE
	mission_controller = expedition
	mission_shuttle = shuttle
	mission_dock = expedition.mission_dock
	// Kick off background processing
	spawn(1)
		processing_loop()
	return TRUE

/datum/ruins_generation_job/proc/ensure_mining_space_landmark()
	// Ensure a mining space waypoint exists in /area/space/ruins so the Mining shuttle can travel to open space.
	// Accept both the legacy tag and the canonical "nav_mining_*" tag for compatibility.
	if(SSshuttle && SSshuttle.get_landmark("nav_mining_space_ruins"))
		return
	
	var/turf/T = null
	var/radius = 10
	
	// Find the /area/space/ruins area
	var/area/space/ruins/ruins_area = get_space_ruins_area()
	
	if(!ruins_area)
		log_debug("ensure_mining_space_landmark: No /area/space/ruins found in world")
		return
	
	// First try to find an existing circle of space turfs with the required radius in the ruins area
	var/list/bounds = ruins_area.get_area_bounds()
	if(bounds && bounds.len >= 5)
		var/minx = bounds[1]
		var/miny = bounds[2]
		var/maxx = bounds[3]
		var/maxy = bounds[4]
		var/zlev = bounds[5]
		
		for(var/yy = max(miny, 1 + radius), yy <= min(maxy, world.maxy - radius), yy++)
			for(var/xx = max(minx, 1 + radius), xx <= min(maxx, world.maxx - radius), xx++)
				var/turf/center = locate(xx, yy, zlev)
				if(!center || get_area(center) != ruins_area) continue
				var/all_space = TRUE
				var/all_in_ruins = TRUE
				var/list/circle = circlerangeturfs(center, radius)
				for(var/turf/CT in circle)
					if(!istype(CT, /turf/space))
						all_space = FALSE
						break
					if(get_area(CT) != ruins_area)
						all_in_ruins = FALSE
						break
				if(all_space && all_in_ruins)
					T = center
					break
			if(T) break
		
		// If none found, pick center of ruins area and ensure it's clear
		if(!T)
			var/cx = round((minx + maxx) / 2)
			var/cy = round((miny + maxy) / 2)
			T = locate(cx, cy, zlev)
			if(T && get_area(T) == ruins_area)
				var/list/circle = circlerangeturfs(T, radius)
				for(var/turf/CT in circle)
					if(get_area(CT) == ruins_area && !istype(CT, /turf/space))
						CT.ChangeTurf(/turf/space)
	
	if(!T) 
		log_debug("ensure_mining_space_landmark: Could not find suitable location in ruins area")
		return
	
	// Create the space waypoint; it will self-register and clear a landing zone
	new /obj/effect/shuttle_landmark/mining/space(T)

/datum/ruins_generation_job/proc/processing_loop()
	// Process one area per tick to spread cost. If an area throws, store error and continue.
	var/list/exclusion = get_mining_dock_exclusion(3, mission_shuttle, mission_dock)
	while(active && !cancelled && done < total)
		var/area/space/ruins/A = areas[done+1]
		if(A)
			var/list/profile_values = list(
				"perlin_freq" = A.perlin_freq,
				"perlin_octaves" = A.perlin_octaves,
				"perlin_persistence" = A.perlin_persistence,
				"perlin_lacunarity" = A.perlin_lacunarity,
				"perlin_scale" = A.perlin_scale,
				"warp_amp" = A.warp_amp,
				"warp_freq" = A.warp_freq
			)
			try
				if(!skip_wipe)
					A.wipe_ruins_level()
				A.generate_ruins_turfs(profile_type, exclusion)
				if(salvage)
					A.place_salvage_ruins(rand(2, 4), exclusion)
			catch(var/exception/e)
				last_error = "[e] at area #[done+1]"
				// continue despite error
			for(var/setting in profile_values)
				A.vars[setting] = profile_values[setting]
		done++
		metrics_inc("ruins.done", 1)
		signal_emit("ruins_generation:area_done", A)
		// light throttle between areas
		sleep(sleep_ticks)
	if(cancelled)
		last_error = "Survey cancelled."
	active = FALSE
	cancelled = FALSE
	mission_controller = null
	mission_shuttle = null
	mission_dock = null
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
