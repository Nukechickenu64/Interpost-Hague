// Telemetry data collection for the Director Engine
// Gathers live station state data: power grid, atmos, security, loyalty, etc.

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
	// Count powered vs unpowered APCs on station
	var/powered = 0
	var/total = 0
	for(var/obj/machinery/power/apc/A in SSmachines.machinery)
		if(!is_station_turf(get_turf(A)))
			continue
		total++
		if(A.operating)
			powered++
	if(total == 0)
		samples[TELEMETRY_POWER_GRID] = 100
	else
		samples[TELEMETRY_POWER_GRID] = round((powered / total) * 100)

/datum/telemetry/proc/sample_atmos_integrity()
	// Check for hull breaches / dangerous atmos in station areas
	var/safe_areas = 0
	var/danger_areas = 0
	for(var/area/A in world)
		if(!A || !isStationLevel(A.z))
			continue
		var/dangerous = FALSE
		for(var/turf/simulated/T in A.contents)
			if(!T)
				continue
			var/datum/gas_mixture/air = T.return_air()
			if(!air)
				continue
			if(air.temperature > T0C + 80 || air.temperature < T0C - 10)
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
	// Check for damaged walls/floors on station
	var/intact = 0
	var/damaged = 0
	for(var/turf/simulated/wall/W in world)
		if(!isStationLevel(W.z))
			continue
		if(W.damage < 50)
			intact++
		else
			damaged++
	// Also count space turfs where station should be (rough heuristic)
	for(var/turf/space/S in world)
		if(!isStationLevel(S.z))
			continue
		// Count space turfs adjacent to station areas as potential breaches
		var/adjacent_station = FALSE
		for(var/dir in list(NORTH, SOUTH, EAST, WEST))
			var/turf/T = get_step(S, dir)
			if(istype(T, /turf/simulated))
				var/area/A = T.loc
				if(A && isStationLevel(T.z) && !findtext(A.name, "Space"))
					adjacent_station = TRUE
					break
		if(adjacent_station)
			damaged++
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