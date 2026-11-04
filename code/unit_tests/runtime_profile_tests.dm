// Profile-driven optimizations must preserve the Director's sampled values.
/datum/unit_test/runtime_profile_telemetry
	name = "OPTIMIZATION - Director telemetry equivalence"

/datum/unit_test/runtime_profile_telemetry/start_test()
	var/datum/telemetry/metrics = new
	var/cold_start = REALTIMEOFDAY
	metrics.sample_structural_integrity()
	log_debug("Initial topology discovery: [REALTIMEOFDAY - cold_start] ds; [telemetry_structural_walls.len] walls, [telemetry_structural_boundaries.len] boundary candidates.")
	world.Profile(PROFILE_RESTART)
	var/start = REALTIMEOFDAY
	metrics.optimization_reference_structural()
	var/reference_time = REALTIMEOFDAY - start
	var/expected = metrics.samples[TELEMETRY_STRUCTURAL]
	start = REALTIMEOFDAY
	metrics.sample_structural_integrity()
	log_debug("Full map structural sample after discovery: original [reference_time] ds, optimized [REALTIMEOFDAY - start] ds.")
	var/list/profile = world.Profile(PROFILE_STOP)
	for(var/i = 7, i + 5 <= profile.len, i += 6)
		if(profile[i] in list("/datum/telemetry/proc/sample_structural_integrity", "/datum/telemetry/proc/optimization_reference_structural"))
			log_debug("[profile[i]]: self [profile[i + 1] * 1000] ms, total [profile[i + 2] * 1000] ms, overtime [profile[i + 4] * 1000] ms, calls [profile[i + 5]].")
	if(metrics.samples[TELEMETRY_STRUCTURAL] != expected)
		fail("Full-map structural reading changed.")
	metrics.optimization_reference_atmos()
	expected = metrics.samples[TELEMETRY_ATMOS_INTEGRITY]
	metrics.sample_atmos_integrity()
	if(metrics.samples[TELEMETRY_ATMOS_INTEGRITY] != expected)
		fail("Full-map atmosphere reading changed.")
	// Include the fixture level, then alter walls, shared breach boundaries,
	// and area names. No persistent topology cache may hide these changes.
	var/list/old_levels = GLOB.using_map.station_levels
	GLOB.using_map.station_levels = list(world.maxz)
	var/area/fixture = new
	fixture.name = "Telemetry fixture"
	var/turf/center = locate(30, 30, world.maxz)
	for(var/turf/T in range(2, center))
		fixture.contents += T
		T.ChangeTurf(/turf/space)
	var/turf/simulated/wall/W = center.ChangeTurf(/turf/simulated/wall)
	var/turf/simulated/F = get_step(W, EAST).ChangeTurf(/turf/simulated/floor)
	for(var/case_id in 1 to 4)
		W.damage = case_id == 1 ? 49 : 50
		fixture.name = case_id == 3 ? "Space fixture" : "Telemetry fixture"
		if(case_id == 4)
			F = F.ChangeTurf(/turf/space)
		metrics.optimization_reference_structural()
		expected = metrics.samples[TELEMETRY_STRUCTURAL]
		metrics.sample_structural_integrity()
		if(metrics.samples[TELEMETRY_STRUCTURAL] != expected)
			fail("Structural reading changed in live fixture [case_id].")
	new /turf/space(W)
	metrics.optimization_reference_structural()
	expected = metrics.samples[TELEMETRY_STRUCTURAL]
	metrics.sample_structural_integrity()
	if(metrics.samples[TELEMETRY_STRUCTURAL] != expected)
		fail("Direct turf construction left a stale structural candidate.")
	GLOB.using_map.station_levels = old_levels
	qdel(metrics)
	if(!reported)
		pass("Full-map atmosphere and structure match; wall damage, shared boundaries, Space names and turf replacement remain live.")
	return TRUE

// Frozen pre-optimization structural sampler.
/datum/telemetry/proc/optimization_reference_structural()
	set background = TRUE
	var/intact = 0
	var/damaged = 0
	for(var/turf/simulated/wall/W in world)
		if(!isStationLevel(W.z))
			continue
		if(W.damage < 50)
			intact++
		else
			damaged++
	for(var/turf/space/S in world)
		if(!isStationLevel(S.z))
			continue
		var/adjacent_station = FALSE
		for(var/direction in list(NORTH, SOUTH, EAST, WEST))
			var/turf/T = get_step(S, direction)
			if(istype(T, /turf/simulated))
				var/area/A = T.loc
				if(A && isStationLevel(T.z) && !findtext(A.name, "Space"))
					adjacent_station = TRUE
					break
		if(adjacent_station)
			damaged++
	var/total = intact + damaged
	samples[TELEMETRY_STRUCTURAL] = total ? round((intact / total) * 100) : 100

// Frozen pre-optimization atmosphere sampler (direct gas reads have no effects).
/datum/telemetry/proc/optimization_reference_atmos()
	var/safe_areas = 0
	var/danger_areas = 0
	for(var/area/A in world)
		if(!A || !isStationLevel(A.z) || istype(A, /area/space))
			continue
		var/dangerous = FALSE
		for(var/turf/simulated/T in A.contents)
			if(T.blocks_air)
				continue
			var/datum/gas_mixture/air = T.zone ? T.zone.air : T.air
			if(!air)
				continue
			if(air.temperature > T0C + 66 || air.temperature < T0C - 26)
				dangerous = TRUE
				break
			var/oxygen = air.total_moles ? (air.gas["oxygen"] / air.total_moles) * 100 : 0
			if(oxygen < 16 || oxygen > 30)
				dangerous = TRUE
				break
			var/toxins = air.total_moles ? (air.gas["phoron"] / air.total_moles) * 100 : 0
			if(toxins > 1)
				dangerous = TRUE
				break
		if(dangerous)
			danger_areas++
		else
			safe_areas++
	var/total = safe_areas + danger_areas
	samples[TELEMETRY_ATMOS_INTEGRITY] = total ? round((safe_areas / total) * 100) : 100
