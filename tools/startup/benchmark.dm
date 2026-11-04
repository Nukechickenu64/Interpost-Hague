/hook/startup/proc/startup_benchmark()
	fdel("tmp/startup-benchmark.log")
	world.log = file("tmp/startup-benchmark.log")
	if(world.params["profile"])
		world.Profile(PROFILE_RESTART)
	return TRUE

SUBSYSTEM_DEF(startup_benchmark)
	name = "Startup benchmark"
	init_order = -INFINITY
	flags = SS_NO_FIRE

/datum/controller/subsystem/startup_benchmark/Initialize(timeofday)
	var/list/timings = list()
	var/first_start = timeofday
	for(var/datum/controller/subsystem/SS in Master.subsystems)
		if(SS.init_state == SS_INITSTATE_DONE)
			var/seconds = (SS.init_finish - SS.init_start) / 10
			timings[SS.name] = seconds
			first_start = min(first_start, SS.init_start)
	var/total = (timeofday - first_start) / 10
	fdel("tmp/startup-timings.json")
	text2file(json_encode(list("total_seconds" = total, "subsystems" = timings)), "tmp/startup-timings.json")
	if(world.params["profile"])
		fdel("tmp/startup-profile.json")
		text2file(json_encode(world.Profile(PROFILE_STOP)), "tmp/startup-profile.json")
	// Check the initial state before any normal lighting tick can repair it.
	var/overlays = 0
	var/failures = 0
	var/starlight_failures = 0
	for(var/turf/T in world)
		if(config.starlight && istype(T, /turf/space))
			var/borders_simulated = FALSE
			for(var/direction in GLOB.alldirs)
				if(istype(get_step(T, direction), /turf/simulated))
					borders_simulated = TRUE
					break
			if(T.light_range != (borders_simulated ? config.starlight : 0))
				starlight_failures++
			CHECK_TICK
		if(!TURF_IS_DYNAMICALLY_LIT_UNSAFE(T))
			continue
		overlays++
		var/atom/movable/lighting_overlay/O = T.lighting_overlay
		var/list/rgb = lighting_tile_rgb(T)
		if(!O || !O.has_light_sample || O.needs_update || O.lum_r != rgb[1] || O.lum_g != rgb[2] || O.lum_b != rgb[3])
			failures++
		CHECK_TICK
	if(SSlighting.light_queue.len || SSlighting.corner_queue.len || SSlighting.overlay_queue.len)
		failures++
	world.log << "STARTUP_LIGHTING_CHECK: [overlays] tiles, [failures] failures"
	world.log << "STARTUP_STARLIGHT_CHECK: [starlight_failures] failures"
	world.log << "STARTUP_BENCHMARK_READY: [total] seconds"
	del(world)
