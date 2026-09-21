// Catalyst Events – Telemetry-Driven Escalation
// The Director Engine triggers these events based on live station telemetry.
// Each catalyst is tailored to the current environmental conditions.

/datum/catalyst_event
	var/name = "Catalyst"
	var/catalyst_type = ""
	var/description = ""
	var/tension_threshold = TENSION_RISING
	var/cooldown = CATALYST_COOLDOWN
	var/last_triggered = 0
	var/max_uses_per_round = 1
	var/uses_this_round = 0
	var/omen_text = "something waiting for its moment" // Cryptic hint shown by fluff systems (e.g. dreaming) when close to triggering

/// Check if this catalyst can trigger based on telemetry and cooldowns
/datum/catalyst_event/proc/can_trigger(var/datum/telemetry/T, var/tension)
	if(uses_this_round >= max_uses_per_round)
		return FALSE
	if(world.time - last_triggered < cooldown)
		return FALSE
	if(tension < tension_threshold)
		return FALSE
	return check_conditions(T)

/// Override in subclasses for specific telemetry conditions
/datum/catalyst_event/proc/check_conditions(var/datum/telemetry/T)
	return TRUE

/// Trigger the catalyst event
/datum/catalyst_event/proc/trigger(var/datum/telemetry/T)
	if(!can_trigger(T, SSdirector.tension))
		return FALSE
	log_debug("Catalyst event '[name]' triggered at tension [SSdirector.tension].")
	if(!execute(T))
		return FALSE
	last_triggered = world.time
	uses_this_round++
	return TRUE

/// Actually perform the catalyst action - override in subclasses
/datum/catalyst_event/proc/execute(var/datum/telemetry/T)
	return TRUE

/// Reset for a new round
/datum/catalyst_event/proc/reset()
	last_triggered = 0
	uses_this_round = 0

// === The Tactical Strike ===
// If external communications go down and structural integrity drops,
// spawn a heavily armed Syndicate strike force in a stealth insertion.

/datum/catalyst_event/tactical_strike
	name = "Tactical Strike"
	catalyst_type = CATALYST_TACTICAL_STRIKE
	description = "A Syndicate strike force has detected the station's vulnerability and is launching a stealth insertion."
	tension_threshold = TENSION_ELEVATED
	max_uses_per_round = 1
	omen_text = "boots on the hull, faceless and silent"

/datum/catalyst_event/tactical_strike/check_conditions(var/datum/telemetry/T)
	// Comms down + structural damage = opportunity
	var/comms = T.get_value(TELEMETRY_COMMS_STATUS)
	var	structural = T.get_value(TELEMETRY_STRUCTURAL)
	if(comms < 40 && structural < 60)
		return TRUE
	// Also trigger if tension is very high regardless
	if(SSdirector.tension >= TENSION_HIGH)
		return TRUE
	return FALSE

/datum/catalyst_event/tactical_strike/execute(var/datum/telemetry/T)
	// Gather ghost candidates for the strike team
	var/list/candidates = list()
	for(var/mob/observer/ghost/G in GLOB.player_list)
		if(!G.client)
			continue
		if(G.client.prefs && (G.client.prefs.be_special_role && "traitor" in G.client.prefs.be_special_role))
			candidates += G

	if(candidates.len < 1)
		log_debug("Tactical Strike: Not enough ghost candidates, aborting.")
		return

	// Determine team size based on crew count
	var/crew_count = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(is_station_turf(get_turf(H)))
			crew_count++
	var/team_size = clamp(round(crew_count / 10), 2, 5)

	var/list/team_minds = list()
	for(var/i = 1 to team_size)
		if(!candidates.len)
			break
		var/mob/observer/ghost/chosen = pick(candidates)
		candidates -= chosen

		// Create a new human for the operative and register it through the antag datum.
		var/mob/living/carbon/human/operative = director_spawn_ghost_body(chosen, "Syndicate Operative [rand(100,999)]")
		var/datum/antagonist/traitor/traitor_antag = GLOB.all_antag_types_["traitor"]
		if(!operative || !operative.mind || !traitor_antag || !traitor_antag.add_antagonist(operative.mind, 0, 0, 1))
			if(operative)
				qdel(operative)
			continue
		operative.mind.assigned_role = "Syndicate Operative"
		SSdirector.loyalty.set_faction(operative.mind, LOYALTY_SYNDICATE)
		team_minds += operative.mind

	if(team_minds.len < 1)
		log_debug("Tactical Strike: Failed to create any operatives, aborting.")
		return

	// Assign squad doctrine
	var/datum/squad_doctrine/syndicate_strike/doctrine = new
	doctrine.assign_roles(team_minds)
	for(var/datum/mind/M in team_minds)
		doctrine.equip_member(M)
	doctrine.announce_squad()

	// Announce to the station
	command_announcement.Announce( \
		"Unidentified vessel detected on long-range scanners. Stealth insertion in progress. All hands, prepare for hostile contact.", \
		"Emergency Alert", \
		)

	// Add tension
	SSdirector.add_tension(20, "Tactical Strike deployed")
	return TRUE

// === The Anomaly ===
// If Science pushes experimental research too far, trigger a Cult or Eldritch invasion
// centered in the research sector.

/datum/catalyst_event/anomaly
	name = "Dimensional Anomaly"
	catalyst_type = CATALYST_ANOMALY
	description = "Science has breached dimensional thresholds. An eldritch invasion is manifesting in the research sector."
	tension_threshold = TENSION_RISING
	max_uses_per_round = 1
	omen_text = "a door that shouldn't open, and something on the other side"

/datum/catalyst_event/anomaly/check_conditions(var/datum/telemetry/T)
	var	research = T.get_value(TELEMETRY_RESEARCH_THRESHOLD)
	if(research < 30)  // High tech levels = low safety score
		return TRUE
	if(SSdirector.tension >= TENSION_HIGH)
		return TRUE
	return FALSE

/datum/catalyst_event/anomaly/execute(var/datum/telemetry/T)
	// Find the research sector
	var/area/research_area = null
	for(var/area/A in world)
		if(!isStationLevel(A.z))
			continue
		if(findtext(A.name, "Research") || findtext(A.name, "Science") || findtext(A.name, "R&D"))
			research_area = A
			break

	var/turf/center = null
	if(research_area)
		for(var/turf/simulated/floor/F in research_area.contents)
			center = F
			break

	if(!center)
		center = director_pick_station_turf()

	// Spawn eldritch effects - portals and cult structures
	if(center)
		for(var/i = 1 to 3)
			var/turf/target = get_step(center, pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
			if(target)
				new /obj/effect/portal(target)

	// Flag nearby crew as cultists
	var/list/nearby_crew = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.mind || !H.client)
			continue
		var/turf/H_turf = get_turf(H)
		if(!H_turf || !isStationLevel(H_turf.z))
			continue
		if(get_dist(H_turf, center) <= 15)
			nearby_crew += H.mind

	// Convert a few nearby crew to cultists
	var/cultists_to_make = min(3, nearby_crew.len)
	for(var/i = 1 to cultists_to_make)
		if(!nearby_crew.len)
			break
		var/datum/mind/M = pick(nearby_crew)
		nearby_crew -= M
		var/datum/antagonist/cultist = GLOB.all_antag_types_["cultist"]
		if(cultist && cultist.add_antagonist(M, 0, 0, 1))
			SSdirector.loyalty.set_faction(M, LOYALTY_CULT)

	command_announcement.Announce( \
		"Dimensional breach detected in the research sector. Anomalous entities are manifesting. All personnel evacuate the area immediately.", \
		"Anomaly Alert", \
		)

	SSdirector.add_tension(25, "Dimensional Anomaly manifested")
	return TRUE

// === The Mutiny ===
// If Security begins mass-arresting crew and loyalty telemetry drops into the red,
// silently flag disgruntled crewmembers as Revolutionaries with hidden encrypted comms.

/datum/catalyst_event/mutiny
	name = "Mutiny"
	catalyst_type = CATALYST_MUTINY
	description = "Security crackdown has pushed crew loyalty into the red. Revolutionary sentiment is spreading."
	tension_threshold = TENSION_ELEVATED
	max_uses_per_round = 2
	omen_text = "clenched fists behind a smile, a knife you cannot see"

/datum/catalyst_event/mutiny/check_conditions(var/datum/telemetry/T)
	var	loyalty = T.get_value(TELEMETRY_LOYALTY)
	var	arrests = T.get_value(TELEMETRY_SECURITY_ARRESTS)
	// Low loyalty + high arrest rate = mutiny conditions
	if(loyalty < 35 && arrests < 50)
		return TRUE
	if(SSdirector.tension >= TENSION_HIGH && loyalty < 50)
		return TRUE
	return FALSE

/datum/catalyst_event/mutiny/execute(var/datum/telemetry/T)
	// Find disgruntled crew (low NT loyalty, not already antags)
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.mind || !H.client)
			continue
		if(!is_station_turf(get_turf(H)))
			continue
		if(player_is_antag(H.mind))
			continue
		if(H.client.prefs)
			var/loyalty = H.client.prefs.nanotrasen_relation
			if(loyalty == COMPANY_OPPOSED || loyalty == COMPANY_SKEPTICAL)
				candidates += H.mind
			else if(loyalty == COMPANY_NEUTRAL && prob(30))
				candidates += H.mind

	if(!candidates.len)
		log_debug("Mutiny: No suitable candidates found, aborting.")
		return

	// Convert candidates to revolutionaries
	var/revs_to_make = min(clamp(round(candidates.len / 3), 1, 5), candidates.len)
	var/datum/antagonist/rev_antag = GLOB.all_antag_types_["revolutionary"]
	if(!rev_antag)
		// Fallback: use renegade
		rev_antag = GLOB.all_antag_types_["renegade"]

	for(var/i = 1 to revs_to_make)
		if(!candidates.len)
			break
		var/datum/mind/M = pick(candidates)
		candidates -= M
		if(!rev_antag || !rev_antag.add_antagonist(M, 0, 0, 1))
			continue
		SSdirector.loyalty.set_faction(M, LOYALTY_REVOLUTIONARY)
		if(M.current)
			to_chat(M.current, "<span class='danger'>The crackdown has gone too far. You receive an encrypted message on a hidden frequency: 'The revolution begins now. You are not alone. Use :t to communicate on the revolutionary channel.'</span>")

	command_announcement.Announce( \
		"Loyalty telemetry indicates significant unrest among the crew. Security is advised to exercise restraint.", \
		"Internal Affairs Advisory", \
		)

	SSdirector.add_tension(15, "Mutiny fomented")
	return TRUE

// === The Infiltration ===
// A lighter catalyst: spawns a single syndicate infiltrator when tension is moderate

/datum/catalyst_event/infiltration
	name = "Syndicate Infiltration"
	catalyst_type = CATALYST_INFILTRATION
	description = "A lone Syndicate infiltrator has boarded the station."
	tension_threshold = TENSION_RISING
	max_uses_per_round = 2
	cooldown = 8 MINUTES
	omen_text = "a stranger wearing a familiar face"

/datum/catalyst_event/infiltration/check_conditions(var/datum/telemetry/T)
	if(SSdirector.tension >= TENSION_RISING)
		return TRUE
	return FALSE

/datum/catalyst_event/infiltration/execute(var/datum/telemetry/T)
	// Find a ghost candidate
	var/list/candidates = list()
	for(var/mob/observer/ghost/G in GLOB.player_list)
		if(G.client && G.client.prefs && (G.client.prefs.be_special_role && "traitor" in G.client.prefs.be_special_role))
			candidates += G

	if(!candidates.len)
		log_debug("Infiltration: No ghost candidates, aborting.")
		return

	var/mob/observer/ghost/chosen = pick(candidates)
	var/mob/living/carbon/human/infiltrator = director_spawn_ghost_body(chosen, "Agent [rand(100,999)]")
	if(!infiltrator || !infiltrator.mind)
		return FALSE

	// Give basic traitor gear
	var/datum/antagonist/traitor_antag = GLOB.all_antag_types_["traitor"]
	if(!traitor_antag || !traitor_antag.add_antagonist(infiltrator.mind, 0, 0, 1))
		qdel(infiltrator)
		return FALSE
	infiltrator.mind.assigned_role = "Syndicate Agent"
	SSdirector.loyalty.set_faction(infiltrator.mind, LOYALTY_SYNDICATE)

	to_chat(infiltrator, "<span class='danger'>You are a Syndicate infiltrator. You have been inserted onto the station. Complete your objectives with subtlety.</span>")

	SSdirector.add_tension(10, "Infiltrator deployed")
	return TRUE

/proc/director_spawn_ghost_body(var/mob/observer/ghost/ghost, var/name)
	if(!ghost || !ghost.client || !ghost.key)
		return null
	var/mob/living/carbon/human/body = new(get_turf(ghost))
	body.key = ghost.key
	if(!body.mind)
		body.mind = new /datum/mind(ghost.key)
		body.mind.current = body
		body.mind.original = body
	body.real_name = name
	body.SetName(name)
	return body