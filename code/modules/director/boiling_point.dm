// Boiling Point Endgame
// When the tension meter hits maximum, the station enters a critical state.
// The focus shifts to extraction, securing high-value assets, and surviving
// multi-faction crossfire as the station tears itself apart.

/datum/boiling_point
	var/active = FALSE
	var/scenario = ""
	var/time_remaining = 0
	var/total_duration = 10 MINUTES
	var/started_at = 0
	var/list/active_hazards = list()

/// Start the Boiling Point endgame
/datum/boiling_point/proc/start(var/datum/telemetry/T)
	if(active)
		return FALSE

	active = TRUE
	started_at = world.time
	time_remaining = total_duration

	// Choose scenario based on telemetry
	scenario = choose_scenario(T)

	log_debug("Boiling Point endgame started: [scenario]")
	message_admins("Boiling Point endgame triggered: [scenario]")

	// Make the announcement
	announce_boiling_point()

	// Execute the scenario
	switch(scenario)
		if(BOILING_REACTOR_MELTDOWN)
			start_reactor_meltdown()
		if(BOILING_HULL_FAILURE)
			start_hull_failure()
		if(BOILING_CORPORATE_LOCKDOWN)
			start_corporate_lockdown()

	// Enable the shuttle for evacuation
	if(SSevac.evacuation_controller)
		SSevac.evacuation_controller.call_evacuation()

	return TRUE

/// Choose the appropriate boiling point scenario based on telemetry
/datum/boiling_point/proc/choose_scenario(var/datum/telemetry/T)
	var/power = T.get_value(TELEMETRY_POWER_GRID)
	var	structural = T.get_value(TELEMETRY_STRUCTURAL)
	var	atmos = T.get_value(TELEMETRY_ATMOS_INTEGRITY)

	// If power grid is critical, reactor meltdown
	if(power < 30)
		return BOILING_REACTOR_MELTDOWN

	// If structural integrity is critical, hull failure
	if(structural < 30 || atmos < 30)
		return BOILING_HULL_FAILURE

	// Default: corporate lockdown
	return BOILING_CORPORATE_LOCKDOWN

/// Announce the boiling point to the station
/datum/boiling_point/proc/announce_boiling_point()
	var/announcement_text = ""
	switch(scenario)
		if(BOILING_REACTOR_MELTDOWN)
			announcement_text = "CRITICAL ALERT: Reactor meltdown imminent. All personnel must evacuate immediately. The station's power grid has failed beyond recovery. You have approximately [round(total_duration / 600)] minutes before total core breach."
		if(BOILING_HULL_FAILURE)
			announcement_text = "CRITICAL ALERT: Catastrophic hull failure detected. The station is tearing itself apart. Structural integrity is below safe thresholds. Evacuate immediately. Estimated time to total collapse: [round(total_duration / 600)] minutes."
		if(BOILING_CORPORATE_LOCKDOWN)
			announcement_text = "CRITICAL ALERT: Nanotrasen has initiated corporate lockdown protocol. The station is being sealed. All personnel must secure high-value assets and evacuate. Lockdown will be fully enforced in [round(total_duration / 600)] minutes."

	command_announcement.Announce(announcement_text, "BOILING POINT - STATION CRITICAL")
	sound_to(world, sound('sound/effects/alert.ogg'))

/// Process the boiling point each tick
/datum/boiling_point/proc/process()
	if(!active)
		return

	time_remaining = total_duration - (world.time - started_at)

	// Apply ongoing hazards based on scenario
	switch(scenario)
		if(BOILING_REACTOR_MELTDOWN)
			process_reactor_meltdown()
		if(BOILING_HULL_FAILURE)
			process_hull_failure()
		if(BOILING_CORPORATE_LOCKDOWN)
			process_corporate_lockdown()
	for(var/obj/effect/radiation_hazard/R in active_hazards)
		if(R)
			R.apply_radiation()

	// Check if time is up
	if(time_remaining <= 0)
		final_catastrophe()

/// Reactor meltdown: escalating radiation, power failures, explosions
/datum/boiling_point/proc/start_reactor_meltdown()
	// Start cutting power to non-critical areas
	for(var/obj/machinery/power/apc/A in SSmachines.machinery)
		if(!is_station_turf(get_turf(A)))
			continue
		var/area/AR = get_area(A)
		if(AR && (findtext(AR.name, "Maintenance") || findtext(AR.name, "Storage")))
			A.operating = 0
			A.update_icon()
	// Spawn radiation hazards near engineering
	spawn_radiation_hazards()

/datum/boiling_point/proc/process_reactor_meltdown()
	// Every 30 seconds, cause random power failures and radiation pulses
	if(prob(10))
		var/obj/machinery/power/apc/target = null
		var/list/apcs = list()
		for(var/obj/machinery/power/apc/A in SSmachines.machinery)
			if(is_station_turf(get_turf(A)))
				apcs += A
		if(apcs.len)
			target = pick(apcs)
			target.operating = 0
			target.update_icon()
			var/area/AR = get_area(target)
			if(AR)
				AR.power_light = 0
				AR.power_equip = 0
				AR.power_environ = 0

	// Radiation pulses
	if(prob(5))
		for(var/mob/living/carbon/human/H in GLOB.player_list)
			if(!is_station_turf(get_turf(H)))
				continue
			H.apply_effect(rand(5, 15), IRRADIATE)

/// Hull failure: random hull breaches, decompression
/datum/boiling_point/proc/start_hull_failure()
	// Create initial breaches
	for(var/i = 1 to 5)
		create_random_breach()

/datum/boiling_point/proc/process_hull_failure()
	// Every tick, chance of new breaches
	if(prob(8))
		create_random_breach()

	// Random window shattering
	if(prob(15))
		for(var/obj/structure/window/W in world)
			if(!isStationLevel(W.z))
				continue
			if(prob(5))
				W.shatter()

/datum/boiling_point/proc/create_random_breach()
	var/turf/target = director_pick_station_turf()
	if(!target)
		return
	// Destroy the turf
	if(istype(target, /turf/simulated/wall))
		var/turf/simulated/wall/W = target
		W.dismantle_wall()
	else if(istype(target, /turf/simulated/floor))
		// Create a hole
		var/turf/simulated/floor/F = target
		F.break_tile()
		// Replace with space if on exterior
		if(prob(50))
			target.ChangeTurf(/turf/space)

/// Corporate lockdown: blast doors close, access restricted
/datum/boiling_point/proc/start_corporate_lockdown()
	// Close all blast doors
	for(var/obj/machinery/door/blast/B in SSmachines.machinery)
		if(!is_station_turf(get_turf(B)))
			continue
		B.close()

	// Lock down key areas
	for(var/obj/machinery/door/airlock/A in SSmachines.machinery)
		if(!is_station_turf(get_turf(A)))
			continue
		var/area/AR = get_area(A)
		if(AR && (findtext(AR.name, "Bridge") || findtext(AR.name, "Vault") || findtext(AR.name, "Armory")))
			A.lock()

/datum/boiling_point/proc/process_corporate_lockdown()
	// Periodically lock additional doors
	if(prob(5))
		for(var/obj/machinery/door/airlock/A in SSmachines.machinery)
			if(!is_station_turf(get_turf(A)))
				continue
			if(prob(3))
				A.lock()

/// Final catastrophe when time runs out
/datum/boiling_point/proc/final_catastrophe()
	if(!active)
		return

	active = FALSE
	for(var/obj/effect/radiation_hazard/R in active_hazards)
		if(R)
			qdel(R)
	active_hazards.Cut()

	switch(scenario)
		if(BOILING_REACTOR_MELTDOWN)
			// Massive explosion centered on engineering
			var/turf/epicenter = null
			for(var/area/A in world)
				if(!isStationLevel(A.z))
					continue
				if(findtext(A.name, "Engine") || findtext(A.name, "Engineering"))
					for(var/turf/simulated/floor/F in A.contents)
						epicenter = F
						break
					break
			if(epicenter)
				explosion(epicenter, 6, 10, 15, 20)
			command_announcement.Announce("REACTOR CORE BREACH. The station's engine has detonated. All hands lost.", "CATASTROPHE")

		if(BOILING_HULL_FAILURE)
			// Multiple massive breaches
			for(var/i = 1 to 10)
				create_random_breach()
			command_announcement.Announce("TOTAL STRUCTURAL COLLAPSE. The station has broken apart.", "CATASTROPHE")

		if(BOILING_CORPORATE_LOCKDOWN)
			// Complete lockdown - all doors seal permanently
			for(var/obj/machinery/door/airlock/A in SSmachines.machinery)
				if(is_station_turf(get_turf(A)))
					A.lock()
			for(var/obj/machinery/door/blast/B in SSmachines.machinery)
				if(is_station_turf(get_turf(B)))
					B.close()
			command_announcement.Announce("LOCKDOWN COMPLETE. Nanotrasen has permanently sealed the station. All remaining personnel are considered expendable.", "CATASTROPHE")

	// Force shuttle call if not already called
	if(SSevac.evacuation_controller && !SSevac.evacuation_controller.round_over())
		SSevac.evacuation_controller.call_evacuation()

/// Spawn radiation hazard effects
/datum/boiling_point/proc/spawn_radiation_hazards()
	for(var/i = 1 to 3)
		var/turf/target = director_pick_station_turf()
		if(target)
			active_hazards += new /obj/effect/radiation_hazard(target)

/obj/effect/radiation_hazard
	name = "radiation field"
	desc = "A dangerous field of ionizing radiation."
	icon = 'icons/effects/effects.dmi'
	icon_state = "radiation"
	invisibility = 0
	anchored = TRUE
	var/radiation_strength = 10

/obj/effect/radiation_hazard/New()
	..()

/obj/effect/radiation_hazard/Destroy()
	return ..()

/obj/effect/radiation_hazard/proc/apply_radiation()
	for(var/mob/living/L in view(2, src))
		L.apply_effect(radiation_strength, IRRADIATE)

/proc/director_pick_station_turf()
	var/list/station_turfs = list()
	for(var/turf/T in world)
		if(is_station_turf(T))
			station_turfs += T
	if(station_turfs.len)
		return pick(station_turfs)

/// Reset for a new round
/datum/boiling_point/proc/reset()
	active = FALSE
	scenario = ""
	time_remaining = 0
	started_at = 0
	for(var/obj/effect/radiation_hazard/R in active_hazards)
		if(R)
			qdel(R)
	active_hazards.Cut()