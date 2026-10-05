// Catalyst Events – Telemetry-Driven Escalation
// The Director Engine triggers these events based on live station telemetry.
// Each catalyst is tailored to the current environmental conditions.

/datum/director_arc
	var/theme = ""
	var/title = ""
	var/started_at = 0
	var/last_advanced = 0
	var/beat_count = 0
	var/last_selection_reason = ""
	var/list/beat_history = list()

/datum/director_arc/New(var/new_theme, var/datum/catalyst_event/first_beat)
	..()
	theme = new_theme
	started_at = world.time
	last_advanced = world.time
	beat_history = list()
	if(first_beat)
		switch(theme)
			if("syndicate_incursion")
				title = "Syndicate Incursion"
			if("dimensional_breach")
				title = "Dimensional Breach"
			if("crew_unrest")
				title = "Crew Unrest"
			if("biological_predation")
				title = "Biological Predation"
			else
				title = "Station Crisis"
		record_beat(first_beat, "Opening beat selected from current station conditions")

/datum/director_arc/proc/record_beat(var/datum/catalyst_event/beat, var/selection_reason)
	if(!beat)
		return
	beat_count++
	last_advanced = world.time
	last_selection_reason = selection_reason
	beat_history += "[world.time]: [beat.name] - [selection_reason]"
	if(beat_history.len > DIRECTOR_ARC_HISTORY_LIMIT)
		beat_history.Cut(1, 2)

/datum/catalyst_event
	var/name = "Catalyst"
	var/catalyst_type = ""
	var/arc_theme = "station_crisis"
	var/director_priority = 50
	var/description = ""
	var/tension_threshold = TENSION_RISING
	var/cooldown = CATALYST_COOLDOWN
	var/last_triggered = 0
	var/max_uses_per_round = 1
	var/uses_this_round = 0
	var/omen_text = "something waiting for its moment" // Cryptic hint shown by fluff systems (e.g. dreaming) when close to triggering
	var/warning_duration = 0
	var/warning_text = null
	var/warning_clear_text = null
	var/warning_active = FALSE
	var/warning_started = 0

/// Check if this catalyst can trigger based on telemetry and cooldowns
/datum/catalyst_event/proc/can_trigger(var/datum/telemetry/T, var/tension)
	if(!is_eligible(T, tension))
		clear_warning()
		return FALSE
	if(!warning_duration)
		return TRUE
	if(!warning_active)
		warning_active = TRUE
		warning_started = world.time
		if(warning_text)
			command_announcement.Announce(warning_text, "Director Advisory")
		return FALSE
	return world.time - warning_started >= warning_duration

/datum/catalyst_event/proc/is_eligible(var/datum/telemetry/T, var/tension)
	if(uses_this_round >= max_uses_per_round)
		return FALSE
	if(world.time - last_triggered < cooldown)
		return FALSE
	if(tension < tension_threshold)
		return FALSE
	if(!check_conditions(T))
		return FALSE
	return TRUE

/// Clear an active warning when the crew resolves the conditions that prompted it.
/datum/catalyst_event/proc/clear_warning()
	if(!warning_active)
		return
	warning_active = FALSE
	warning_started = 0
	if(warning_clear_text)
		command_announcement.Announce(warning_clear_text, "Director Advisory")

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
	warning_active = FALSE
	warning_started = 0

// === The Tactical Strike ===
// If external communications go down and structural integrity drops,
// spawn a heavily armed Syndicate strike force in a stealth insertion.

/datum/catalyst_event/tactical_strike
	name = "Tactical Strike"
	catalyst_type = CATALYST_TACTICAL_STRIKE
	arc_theme = "syndicate_incursion"
	director_priority = 70
	description = "A Syndicate strike force has detected the station's vulnerability and is launching a stealth insertion."
	tension_threshold = TENSION_ELEVATED
	max_uses_per_round = 1
	omen_text = "boots on the hull, faceless and silent"
	warning_duration = 2 MINUTES
	warning_text = "Long-range sensors detect a possible hostile insertion window. Restoring external communications and repairing hull damage may avert escalation, but severe station-wide instability can still authorize a strike."
	warning_clear_text = "The hostile insertion warning has been withdrawn. Station vulnerabilities have stabilized."

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
	if(!SSdirector.can_recruit_antagonist("traitor"))
		return FALSE
	if(!SSdirector.can_director_recruit_ghosts() && !SSdirector.can_director_convert_crew())
		return FALSE
	// Crew mode keeps selected players in their existing human bodies.
	var/list/candidates = list()
	if(SSdirector.can_director_convert_crew())
		for(var/mob/living/carbon/human/H in GLOB.player_list)
			if(!H.client || !H.mind || H.stat == DEAD || !is_station_turf(get_turf(H)) || player_is_antag(H.mind) || H.mind == SSdirector.starter_mind)
				continue
			candidates += H.mind
	else
		for(var/mob/observer/ghost/G in GLOB.player_list)
			if(SSdirector.starter_mind && G.mind == SSdirector.starter_mind)
				continue
			if(G.client && G.client.prefs && G.client.prefs.be_special_role && ("traitor" in G.client.prefs.be_special_role))
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
	var/datum/antagonist/traitor/traitor_antag = GLOB.all_antag_types_["traitor"]
	if(!traitor_antag)
		return FALSE
	var/antag_slots = traitor_antag.hard_cap - traitor_antag.get_antag_count()
	var/round_antag_slots = max(1, round(crew_count / 2)) - SSdirector.get_total_antag_count()
	team_size = min(team_size, antag_slots, round_antag_slots)
	if(team_size <= 0)
		return FALSE

	var/list/team_minds = list()
	for(var/i = 1 to team_size)
		if(!candidates.len || !SSdirector.can_recruit_antagonist("traitor"))
			break
		var/mob/observer/ghost/chosen = null
		var/mob/living/carbon/human/operative = null
		var/move_to_spawn = FALSE
		if(SSdirector.can_director_convert_crew())
			var/datum/mind/chosen_mind = pick(candidates)
			candidates -= chosen_mind
			operative = chosen_mind.current
		else
			chosen = pick(candidates)
			candidates -= chosen
			operative = director_spawn_ghost_body(chosen, "Syndicate Operative [rand(100,999)]")
			move_to_spawn = TRUE

		if(!operative || !operative.mind || !traitor_antag.add_antagonist(operative.mind, 0, 0, move_to_spawn))
			if(operative && chosen)
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
	arc_theme = "dimensional_breach"
	director_priority = 65
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
		if(!H.mind || !H.client || H.stat == DEAD || player_is_antag(H.mind) || H.mind == SSdirector.starter_mind)
			continue
		if(!SSdirector.can_director_convert_crew())
			continue
		var/turf/H_turf = get_turf(H)
		if(!H_turf || !isStationLevel(H_turf.z))
			continue
		if(get_dist(H_turf, center) <= 15)
			nearby_crew += H.mind

	// Convert a few nearby crew to cultists without moving them from their current bodies.
	var/datum/antagonist/cultist = GLOB.all_antag_types_["cultist"]
	var/crew_slots = cultist ? cultist.hard_cap - cultist.get_antag_count() : 0
	var/round_slots = max(1, round(SSdirector.count_living_crew() / 2)) - SSdirector.get_total_antag_count()
	var/cultists_to_make = min(3, nearby_crew.len, crew_slots, round_slots)
	for(var/i = 1 to cultists_to_make)
		if(!nearby_crew.len || !SSdirector.can_recruit_antagonist("cultist"))
			break
		var/datum/mind/M = pick(nearby_crew)
		nearby_crew -= M
		if(cultist.add_antagonist(M, 0, 0, 0))
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
	arc_theme = "crew_unrest"
	director_priority = 60
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
	if(!SSdirector.can_director_convert_crew())
		return FALSE
	// Find disgruntled crew (low NT loyalty, not already antags)
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.mind || !H.client)
			continue
		if(H.stat == DEAD || !is_station_turf(get_turf(H)))
			continue
		if(player_is_antag(H.mind) || H.mind == SSdirector.starter_mind)
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
	if(!rev_antag)
		return FALSE
	revs_to_make = min(revs_to_make, rev_antag.hard_cap - rev_antag.get_antag_count())
	revs_to_make = min(revs_to_make, max(1, round(SSdirector.count_living_crew() / 2)) - SSdirector.get_total_antag_count())
	if(revs_to_make <= 0)
		return FALSE

	for(var/i = 1 to revs_to_make)
		if(!candidates.len || !SSdirector.can_recruit_antagonist(rev_antag.id))
			break
		var/datum/mind/M = pick(candidates)
		candidates -= M
		if(!rev_antag.add_antagonist(M, 0, 0, 0))
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
	arc_theme = "syndicate_incursion"
	director_priority = 40
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
	if(!SSdirector.can_recruit_antagonist("traitor"))
		return FALSE
	if(SSdirector.can_director_convert_crew())
		if(!convert_station_antagonist("traitor"))
			log_debug("Infiltration: No eligible crewmember to recruit.")
			return FALSE
		SSdirector.add_tension(10, "Existing crewmember recruited as an infiltrator")
		return TRUE
	if(!SSdirector.can_director_recruit_ghosts())
		return FALSE
	var/datum/antagonist/traitor/traitor_antag = GLOB.all_antag_types_["traitor"]
	if(!traitor_antag || traitor_antag.get_antag_count() >= traitor_antag.hard_cap)
		return FALSE
	// Find a ghost candidate
	var/list/candidates = list()
	for(var/mob/observer/ghost/G in GLOB.player_list)
		if(SSdirector.starter_mind && G.mind == SSdirector.starter_mind)
			continue
		if(G.client && G.client.prefs && G.client.prefs.be_special_role && ("traitor" in G.client.prefs.be_special_role))
			candidates += G

	if(!candidates.len)
		log_debug("Infiltration: No ghost candidates, aborting.")
		return

	var/mob/observer/ghost/chosen = pick(candidates)
	var/mob/living/carbon/human/infiltrator = director_spawn_ghost_body(chosen, "Agent [rand(100,999)]")
	if(!infiltrator || !infiltrator.mind)
		return FALSE

	// Give basic traitor gear
	if(!traitor_antag.add_antagonist(infiltrator.mind, 0, 0, 1))
		qdel(infiltrator)
		return FALSE
	infiltrator.mind.assigned_role = "Syndicate Agent"
	SSdirector.loyalty.set_faction(infiltrator.mind, LOYALTY_SYNDICATE)

	to_chat(infiltrator, "<span class='danger'>You are a Syndicate infiltrator. You have been inserted onto the station. Complete your objectives with subtlety.</span>")

	SSdirector.add_tension(10, "Infiltrator deployed")
	return TRUE

// === Hidden Appetites ===
// Covert station antagonists selected from living crew who opted into the role.

/proc/convert_station_antagonist(var/antag_id)
	if(!SSdirector || !SSdirector.can_director_convert_crew())
		return FALSE
	if(!SSdirector.can_recruit_antagonist(antag_id))
		return FALSE
	var/datum/antagonist/antag = GLOB.all_antag_types_[antag_id]
	if(!antag || antag.get_antag_count() >= antag.hard_cap)
		return FALSE
	if(SSdirector.get_total_antag_count() >= max(1, round(SSdirector.count_living_crew() / 2)))
		return FALSE
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.client || !H.mind || H.stat == DEAD || !is_station_turf(get_turf(H)))
			continue
		if(player_is_antag(H.mind) || H.mind == SSdirector.starter_mind)
			continue
		if(!SSdirector.can_director_convert_crew() && (!H.client.prefs || !H.client.prefs.be_special_role || !(antag_id in H.client.prefs.be_special_role)))
			continue
		candidates += H.mind
	while(candidates.len)
		var/datum/mind/candidate = pick(candidates)
		candidates -= candidate
		if(antag.add_antagonist(candidate, 0, 0, 0, 1, 1))
			SSdirector.loyalty.set_faction(candidate, LOYALTY_NEUTRAL)
			return TRUE
	return FALSE

/datum/catalyst_event/leech
	name = "Hematopoietic Failure"
	catalyst_type = CATALYST_LEECH
	arc_theme = "biological_predation"
	director_priority = 50
	description = "A crewmember's failing marrow has developed an appetite for fresh blood."
	tension_threshold = TENSION_ELEVATED
	max_uses_per_round = 1
	cooldown = 10 MINUTES
	omen_text = "a hollow pulse and a thirst no drink can touch"

/datum/catalyst_event/leech/check_conditions(var/datum/telemetry/T)
	return T.get_value(TELEMETRY_CREW_VITALITY) < 75

/datum/catalyst_event/leech/execute(var/datum/telemetry/T)
	if(!convert_station_antagonist("leech"))
		log_debug("Hematopoietic Failure: No eligible Leech candidate, aborting.")
		return FALSE
	SSdirector.add_tension(8, "A Leech emerged among the crew")
	return TRUE

/datum/catalyst_event/epicurean
	name = "Forbidden Appetite"
	catalyst_type = CATALYST_EPICUREAN
	arc_theme = "biological_predation"
	director_priority = 55
	description = "Mounting pressure has pushed a crewmember toward a carefully concealed appetite."
	tension_threshold = TENSION_HIGH
	max_uses_per_round = 1
	cooldown = 10 MINUTES
	omen_text = "a spotless knife laid beside an empty plate"

/datum/catalyst_event/epicurean/check_conditions(var/datum/telemetry/T)
	return T.get_value(TELEMETRY_CREW_VITALITY) >= 60

/datum/catalyst_event/epicurean/execute(var/datum/telemetry/T)
	if(!convert_station_antagonist("epicurean"))
		log_debug("Forbidden Appetite: No eligible Epicurean candidate, aborting.")
		return FALSE
	SSdirector.add_tension(8, "An Epicurean emerged among the crew")
	return TRUE

// === Cargo Incursion ===
// Armed boarders stow away on the supply shuttle while it is off-station, then hunt the crew once it docks.

/datum/catalyst_event/cargo_incursion
	name = "Cargo Incursion"
	catalyst_type = CATALYST_CARGO_INCURSION
	arc_theme = "syndicate_incursion"
	director_priority = 60
	description = "Armed boarders have stowed away aboard the inbound supply shuttle."
	tension_threshold = TENSION_HIGH
	max_uses_per_round = 1
	omen_text = "crates that breathe in the dark"
	warning_duration = 2 MINUTES
	warning_text = "Supply manifests show unexplained mass discrepancies on the next cargo run. Cargo personnel should treat the inbound shuttle with caution."
	warning_clear_text = "The supply manifest discrepancy has been reconciled."

/datum/catalyst_event/cargo_incursion/check_conditions(var/datum/telemetry/T)
	return !!SSsupply.shuttle

/datum/catalyst_event/cargo_incursion/execute(var/datum/telemetry/T)
	var/datum/shuttle/autodock/ferry/supply/S = SSsupply.shuttle
	if(!S || S.at_station() || S.moving_status != SHUTTLE_IDLE)
		log_debug("Cargo Incursion: Supply shuttle is not idle off-station, deferring.")
		return FALSE

	var/list/spawn_turfs = list()
	for(var/area/A in S.shuttle_area)
		for(var/turf/simulated/floor/F in A)
			if(!F.contains_dense_objects())
				spawn_turfs += F
	if(!spawn_turfs.len)
		return FALSE

	var/crew_count = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat != DEAD && is_station_turf(get_turf(H)))
			crew_count++
	var/squad_size = clamp(round(crew_count / 6), 2, 6)
	for(var/i in 1 to squad_size)
		var/mob/living/carbon/human/invader/I = new(pick(spawn_turfs))
		I.brain.wait_for_dock()

	S.launch()
	announce_on_dock(S)
	SSdirector.add_tension(15, "Cargo Incursion launched")
	return TRUE

/datum/catalyst_event/cargo_incursion/proc/announce_on_dock(var/datum/shuttle/autodock/ferry/supply/S)
	set waitfor = FALSE
	var/give_up_at = world.time + 10 MINUTES
	sleep(10 SECONDS)
	while(S && !(S.at_station() && S.moving_status == SHUTTLE_IDLE))
		if(world.time > give_up_at)
			return
		sleep(5 SECONDS)
	command_announcement.Announce( \
		"Unregistered life signs detected aboard the docked supply shuttle. Armed hostiles are disembarking into Cargo. All hands, prepare for hostile contact.", \
		"Emergency Alert", \
		)

/datum/catalyst_event/pony_incursion
	name = "Pony Incursion"
	catalyst_type = "pony_incursion"
	arc_theme = "dimensional_breach"
	director_priority = 55
	description = "Hostile ponies emerge to exterminate the station's humanoids."
	tension_threshold = TENSION_ELEVATED
	max_uses_per_round = 1
	omen_text = "hooves beyond the veil and a hatred of hands"

/datum/catalyst_event/pony_incursion/check_conditions(var/datum/telemetry/T)
	return istype(SSticker.mode, /datum/game_mode/dynamic) && config && config.director_antag_policy != DIRECTOR_ANTAG_POLICY_DISABLED && SSdirector.can_recruit_antagonist("pony")

/datum/catalyst_event/pony_incursion/execute(var/datum/telemetry/T)
	if(!check_conditions(T))
		return FALSE
	var/datum/antagonist/pony/antag = GLOB.all_antag_types_["pony"]
	var/list/candidates = list()
	for(var/mob/observer/ghost/ghost in GLOB.player_list)
		if(!ghost.client?.prefs || !ghost.key || ghost.pony_creation || (SSdirector.starter_mind && ghost.mind == SSdirector.starter_mind))
			continue
		if(!("pony" in ghost.client.prefs.be_special_role) || jobban_isbanned(ghost, "pony"))
			continue
		if(config.use_age_restriction_for_antags && ghost.client.player_age < antag.minimum_player_age)
			continue
		candidates += ghost
	if(!candidates.len)
		return FALSE
	var/list/spawn_turfs = list()
	for(var/turf/simulated/floor/floor in world)
		if(is_station_turf(floor) && !floor.contains_dense_objects() && !floor.density)
			var/datum/gas_mixture/air = floor.return_air()
			if(air && air.return_pressure() >= 80 && air.temperature >= 270 && air.temperature <= 320)
				spawn_turfs += floor
	if(!spawn_turfs.len)
		return FALSE
	var/team_size = min(candidates.len, clamp(round(SSdirector.count_living_crew() / 10), 1, 3))
	var/invited = 0
	for(var/member_index = 1 to team_size)
		if(!candidates.len || !SSdirector.can_recruit_antagonist("pony"))
			break
		var/mob/observer/ghost/chosen = pick(candidates)
		candidates -= chosen
		new /datum/nano_module/appearance_changer/pony_creation(chosen, pick(spawn_turfs))
		invited++
	return invited > 0

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