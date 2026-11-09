// Telemetry data collection for the Director Engine
// Gathers live station state data: power grid, atmos, security, loyalty, etc.

// Topology candidates only. Damage, station membership and area names remain
// live readings. Coordinate keys survive turf replacement and direct new turfs.
var/global/list/telemetry_structural_walls
var/global/list/telemetry_structural_boundaries
var/global/list/telemetry_structural_dirty

/proc/telemetry_queue_structural_turf(turf/T)
	telemetry_structural_dirty["[T.x],[T.y],[T.z]"] = list(T.x, T.y, T.z)
	for(var/direction in GLOB.cardinal)
		var/turf/neighbor = get_step(T, direction)
		if(neighbor)
			telemetry_structural_dirty["[neighbor.x],[neighbor.y],[neighbor.z]"] = list(neighbor.x, neighbor.y, neighbor.z)

/proc/telemetry_refresh_structural_candidates()
	if(isnull(telemetry_structural_dirty))
		telemetry_structural_dirty = list()
		telemetry_structural_walls = list()
		telemetry_structural_boundaries = list()
		var/visited = 0
		for(var/turf/simulated/T in world)
			if(istype(T, /turf/simulated/wall))
				telemetry_structural_walls["[T.x],[T.y],[T.z]"] = T
			for(var/direction in GLOB.cardinal)
				var/turf/space/S = get_step(T, direction)
				if(istype(S))
					telemetry_structural_boundaries["[S.x],[S.y],[S.z]"] = S
			if(++visited % 256 == 0)
				CHECK_TICK
	// Only topology edits and their immediate neighbors need reclassification.
	// Swapping the queue also preserves edits made while this pass yields.
	var/list/dirty = telemetry_structural_dirty
	telemetry_structural_dirty = list()
	var/visited = 0
	for(var/key in dirty)
		var/list/coords = dirty[key]
		var/turf/T = locate(coords[1], coords[2], coords[3])
		telemetry_structural_walls -= key
		telemetry_structural_boundaries -= key
		if(istype(T, /turf/simulated/wall))
			telemetry_structural_walls[key] = T
		if(istype(T, /turf/space))
			for(var/direction in GLOB.cardinal)
				if(istype(get_step(T, direction), /turf/simulated))
					telemetry_structural_boundaries[key] = T
					break
		if(++visited % 256 == 0)
			CHECK_TICK

/datum/telemetry
	var/name = "telemetry"

	// Raw sampled values (0-100 normalized where applicable)
	var/list/samples = list()

	// Rolling history for trend analysis (last N samples)
	var/list/history = list()
	var/history_depth = 10

	// Accumulators for events since last sample
	var/arrests_since_sample = 0
	var/deaths_since_sample = 0
	var/comms_blackout_active = FALSE
	var/power_controllers_total = 0

/datum/telemetry/New()
	for(var/key in list(
		TELEMETRY_POWER_GRID,
		TELEMETRY_ATMOS_INTEGRITY,
		TELEMETRY_SECURITY_ARRESTS,
		TELEMETRY_LOYALTY,
		TELEMETRY_STRUCTURAL,
		TELEMETRY_COMMS_STATUS,
		TELEMETRY_RESEARCH_THRESHOLD,
		TELEMETRY_CREW_VITALITY,
		TELEMETRY_DEATH_RATE
	))
		samples[key] = 100  // Start at nominal
		history[key] = list()

/// Collect a full telemetry sample from the station
/datum/telemetry/proc/sample()
	sample_power_grid()
	sample_atmos_integrity()
	sample_security_arrests()
	sample_loyalty()
	sample_structural_integrity()
	sample_comms_status()
	sample_research_threshold()
	sample_crew_vitality()
	sample_death_rate()

	// Push to history
	for(var/key in samples)
		var/list/h = history[key]
		h += samples[key]
		if(h.len > history_depth)
			h.Cut(1, h.len - history_depth + 1)

	// Reset accumulators
	arrests_since_sample = 0
	deaths_since_sample = 0

/// Get a telemetry value
/datum/telemetry/proc/get_value(var/key)
	return samples[key] || 0

/// Get the trend (positive = improving, negative = degrading) for a key
/datum/telemetry/proc/get_trend(var/key)
	var/list/h = history[key]
	if(!h || h.len < 2)
		return 0
	return h[h.len] - h[h.len - 1]

/// Get the average over history
/datum/telemetry/proc/get_average(var/key)
	var/list/h = history[key]
	if(!h || !h.len)
		return samples[key] || 0
	var/sum = 0
	for(var/val in h)
		sum += val
	return sum / h.len

// === Individual samplers ===

/datum/telemetry/proc/sample_power_grid()
	if(istype(GLOB.using_map, /datum/map/os13classic))
		var/coverage = power_net.os13_generation_coverage()
		samples[TELEMETRY_POWER_GRID] = isnull(coverage) ? 0 : round(coverage)
		return
	var/powered = 0
	var/total = 0
	for(var/obj/machinery/power/area_smes/A in SSmachines.machinery)
		if(!is_station_turf(get_turf(A)))
			continue
		total++
		if(A.is_supplying_power())
			powered++
	power_controllers_total = total
	if(total == 0)
		samples[TELEMETRY_POWER_GRID] = 0
	else
		samples[TELEMETRY_POWER_GRID] = round((powered / total) * 100)

/datum/telemetry/proc/sample_atmos_integrity()
	// Check for hull breaches / dangerous atmos in station areas
	var/safe_areas = 0
	var/danger_areas = 0
	for(var/area/A in world)
		if(!A || !isStationLevel(A.z) || istype(A, /area/space))
			continue
		var/dangerous = FALSE
		// A zone shares one mixture across all its turfs. Check each mixture
		// once per area, while still including unzoned turf air.
		var/list/checked_air = list()
		for(var/turf/simulated/T in A.contents)
			if(T.blocks_air)
				continue
			// Read air directly; return_air() would queue zone updates as a side effect.
			var/datum/gas_mixture/air = T.zone ? T.zone.air : T.air
			if(!air || checked_air[air])
				continue
			checked_air[air] = TRUE
			// Station baseline is cold (turf default 253.5K); match air alarm danger thresholds.
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
	if(total == 0)
		samples[TELEMETRY_ATMOS_INTEGRITY] = 100
	else
		samples[TELEMETRY_ATMOS_INTEGRITY] = round((safe_areas / total) * 100)

/datum/telemetry/proc/sample_security_arrests()
	// Based on accumulated arrests since last sample + current brig population
	var/brig_count = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!is_station_turf(get_turf(H)))
			continue
		var/area/A = get_area(H)
		if(A && (findtext(A.name, "Brig") || findtext(A.name, "Prison") || findtext(A.name, "Cell")))
			brig_count++
	// Combine recent arrests with brig population, normalize
	var/raw = arrests_since_sample * 10 + brig_count * 5
	samples[TELEMETRY_SECURITY_ARRESTS] = clamp(100 - raw, 0, 100)

/datum/telemetry/proc/sample_loyalty()
	// Average crew loyalty based on Nanotrasen relation preferences and active antags
	var/total_loyalty = 0
	var/count = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.client || !H.mind)
			continue
		if(!is_station_turf(get_turf(H)))
			continue
		var/loyalty = 50  // Neutral baseline
		if(H.client.prefs)
			switch(H.client.prefs.nanotrasen_relation)
				if(COMPANY_LOYAL)
					loyalty = 90
				if(COMPANY_SUPPORTATIVE)
					loyalty = 75
				if(COMPANY_NEUTRAL)
					loyalty = 50
				if(COMPANY_SKEPTICAL)
					loyalty = 30
				if(COMPANY_OPPOSED)
					loyalty = 10
		// Active antags are disloyal
		if(player_is_antag(H.mind))
			loyalty = max(0, loyalty - 40)
		total_loyalty += loyalty
		count++
	if(count == 0)
		samples[TELEMETRY_LOYALTY] = 50
	else
		samples[TELEMETRY_LOYALTY] = round(total_loyalty / count)

/datum/telemetry/proc/sample_structural_integrity()
	set background = TRUE
	telemetry_refresh_structural_candidates()
	// Sample only walls and possible breaches. Turf lifecycle hooks keep the
	// candidate sets current without another world scan on every sample.
	var/intact = 0
	var/damaged = 0
	var/visited = 0
	for(var/key in telemetry_structural_walls)
		var/turf/simulated/wall/W = telemetry_structural_walls[key]
		if(!istype(W) || !isStationLevel(W.z))
			continue
		if(W.damage < 50)
			intact++
		else
			damaged++
		if(++visited % 256 == 0)
			CHECK_TICK
	for(var/key in telemetry_structural_boundaries)
		var/turf/space/S = telemetry_structural_boundaries[key]
		if(!istype(S) || !isStationLevel(S.z))
			continue
		for(var/direction in GLOB.cardinal)
			var/turf/simulated/T = get_step(S, direction)
			if(!istype(T))
				continue
			var/area/A = T.loc
			if(A && !findtext(A.name, "Space"))
				damaged++
				break
		if(++visited % 256 == 0)
			CHECK_TICK
	var/total = intact + damaged
	if(total == 0)
		samples[TELEMETRY_STRUCTURAL] = 100
	else
		samples[TELEMETRY_STRUCTURAL] = round((intact / total) * 100)

/datum/telemetry/proc/sample_comms_status()
	// Check telecomms functionality
	var/functional_relays = 0
	var/total_relays = 0
	for(var/obj/machinery/telecomms/relay/R in SSmachines.machinery)
		if(!is_station_turf(get_turf(R)))
			continue
		total_relays++
		if(R.on)
			functional_relays++
	if(total_relays == 0)
		samples[TELEMETRY_COMMS_STATUS] = comms_blackout_active ? 0 : 100
	else
		samples[TELEMETRY_COMMS_STATUS] = round((functional_relays / total_relays) * 100)

/datum/telemetry/proc/sample_research_threshold()
	// Track how close science is to "dimensional thresholds" via R&D levels
	var/max_tech = 0
	for(var/obj/machinery/computer/rdconsole/RD in SSmachines.machinery)
		if(!is_station_turf(get_turf(RD)))
			continue
		if(RD.files)
			for(var/datum/tech/T in RD.files.known_tech)
				if(T.level > max_tech)
					max_tech = T.level
	// Higher tech = closer to threshold = lower "safety" score
	samples[TELEMETRY_RESEARCH_THRESHOLD] = clamp(100 - (max_tech * 10), 0, 100)

/datum/telemetry/proc/sample_crew_vitality()
	// Percentage of crew alive and conscious
	var/alive = 0
	var/total = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!is_station_turf(get_turf(H)))
			continue
		total++
		if(H.stat < DEAD)
			alive++
	if(total == 0)
		samples[TELEMETRY_CREW_VITALITY] = 100
	else
		samples[TELEMETRY_CREW_VITALITY] = round((alive / total) * 100)

/datum/telemetry/proc/sample_death_rate()
	// Based on accumulated deaths, normalized
	var/raw = deaths_since_sample * 15
	samples[TELEMETRY_DEATH_RATE] = clamp(100 - raw, 0, 100)

/// Called by external systems to register an arrest
/datum/telemetry/proc/register_arrest()
	arrests_since_sample++

/// Called by external systems to register a death
/datum/telemetry/proc/register_death()
	deaths_since_sample++

/// Called when comms blackout starts/ends
/datum/telemetry/proc/set_comms_blackout(var/active)
	comms_blackout_active = active
