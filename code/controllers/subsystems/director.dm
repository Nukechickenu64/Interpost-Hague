// Director Engine – The AI Director Subsystem
// Continuously evaluates station state, manages the tension meter,
// triggers catalyst events, and orchestrates the Boiling Point endgame.
// This is the core of the Dynamic State-Machine Framework.

SUBSYSTEM_DEF(director)
	name = "AI Director"
	wait = 5 SECONDS
	priority = SS_PRIORITY_EVENT
	init_order = SS_INIT_MISC
	runlevels = RUNLEVELS_DEFAULT
	var/director_state = DIRECTOR_STATE_DORMANT

	// Tension meter (0-100)
	var/tension = 0
	var/tension_decay_rate = 0.5  // How much tension decays per evaluation cycle
	var/tension_last_change_reason = ""

	// Components
	var/datum/telemetry/telemetry = null
	var/datum/loyalty_tracker/loyalty = null
	var/datum/boiling_point/boiling_point = null

	// Corporate profiles: mind ref -> /datum/corporate_profile
	var/list/profiles = list()

	// Catalyst events
	var/list/datum/catalyst_event/catalysts = list()

	// Timing
	var/last_telemetry_sample = 0
	var/last_evaluation = 0
	var/round_start_time = 0

	// Configuration
	var/enabled = TRUE
	var/debt_probability = 25  // % chance a crewmember starts with a debt
	var/agenda_probability = 60  // % chance a crewmember starts with an agenda

/datum/controller/subsystem/director/Initialize()
	telemetry = new()
	loyalty = new()
	boiling_point = new()

	// Register catalyst events
	catalysts = list(
		new /datum/catalyst_event/tactical_strike(),
		new /datum/catalyst_event/anomaly(),
		new /datum/catalyst_event/mutiny(),
		new /datum/catalyst_event/infiltration(),
	)

	log_debug("AI Director: Initialized with [catalysts.len] catalyst events.")
	return ..()

/datum/controller/subsystem/director/Recover()
	telemetry = SSdirector.telemetry
	loyalty = SSdirector.loyalty
	boiling_point = SSdirector.boiling_point
	profiles = SSdirector.profiles
	catalysts = SSdirector.catalysts
	tension = SSdirector.tension
	director_state = SSdirector.director_state

/datum/controller/subsystem/director/fire(resumed = FALSE)
	if(!enabled)
		return

	if(GAME_STATE != RUNLEVEL_GAME)
		return

	// Sample telemetry at regular intervals
	if(world.time - last_telemetry_sample >= TELEMETRY_SAMPLE_INTERVAL)
		telemetry.sample()
		last_telemetry_sample = world.time

	// Evaluate at regular intervals
	if(world.time - last_evaluation >= DIRECTOR_EVAL_INTERVAL)
		evaluate()
		last_evaluation = world.time

	// Process boiling point if active
	if(boiling_point.active)
		boiling_point.process()

/datum/controller/subsystem/director/stat_entry()
	..("D:[state_name()] T:[round(tension)]")

/datum/controller/subsystem/director/proc/state_name()
	if(director_state == DIRECTOR_STATE_DORMANT)
		return "DORMANT"
	if(director_state == DIRECTOR_STATE_MONITORING)
		return "MONITOR"
	if(director_state == DIRECTOR_STATE_SIMMERING)
		return "SIMMER"
	if(director_state == DIRECTOR_STATE_ESCALATING)
		return "ESCALATE"
	if(director_state == DIRECTOR_STATE_BOILING)
		return "BOIL"
	if(director_state == DIRECTOR_STATE_CONCLUDED)
		return "DONE"
	return "???"

/// Called when the round starts to initialize corporate profiles
/datum/controller/subsystem/director/proc/on_round_start()
	director_state = DIRECTOR_STATE_MONITORING
	tension = 5  // Start with a small baseline
	round_start_time = world.time
	last_telemetry_sample = 0
	last_evaluation = 0

	// Reset components
	telemetry = new()
	loyalty = new()
	boiling_point.reset()
	for(var/datum/catalyst_event/C in catalysts)
		C.reset()
	profiles.Cut()

	// Assign corporate profiles to all crew
	assign_corporate_profiles()

	log_debug("AI Director: Round started. Assigned [profiles.len] corporate profiles.")

/// Assign corporate profiles to all crew at round start
/datum/controller/subsystem/director/proc/assign_corporate_profiles()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.mind || !H.client)
			continue
		if(!is_station_turf(get_turf(H)))
			continue
		if(player_is_antag(H.mind))
			continue  // Already an antag, skip

		var/datum/corporate_profile/CP = new(H.mind)

		// Roll for debt or agenda
		var/roll = rand(1, 100)
		if(roll <= debt_probability)
			CP.generate_debt()
		else if(roll <= debt_probability + agenda_probability)
			CP.generate_agenda()
		// else: clean profile

		profiles[H.mind] = CP

		// Show profile to player after a short delay
		spawn(rand(50, 200))
			if(CP && CP.owner && CP.owner.current)
				CP.show_to_player()

		// Register initial loyalty
		loyalty.set_faction(H.mind, LOYALTY_NANOTRASEN)

/// Main evaluation loop - the heart of the Director Engine
/datum/controller/subsystem/director/proc/evaluate()
	if(director_state == DIRECTOR_STATE_DORMANT || director_state == DIRECTOR_STATE_CONCLUDED)
		return

	// Calculate tension from telemetry
	calculate_tension()

	// Update state machine
	update_state()

	// Check catalyst events
	if(director_state >= DIRECTOR_STATE_SIMMERING)
		check_catalysts()

	// Check corporate profile completion
	check_profiles()

	// Log status
	log_debug("AI Director: State=[state_name()], Tension=[round(tension)], Reason=[tension_last_change_reason]")

/// Calculate the tension meter from telemetry data
/datum/controller/subsystem/director/proc/calculate_tension()
	var/new_tension = 0

	// Base tension from telemetry (inverted: lower safety = higher tension)
	var/power = telemetry.get_value(TELEMETRY_POWER_GRID)
	var	atmos = telemetry.get_value(TELEMETRY_ATMOS_INTEGRITY)
	var	structural = telemetry.get_value(TELEMETRY_STRUCTURAL)
	var	comms = telemetry.get_value(TELEMETRY_COMMS_STATUS)
	var	loyalty_val = telemetry.get_value(TELEMETRY_LOYALTY)
	var	vitality = telemetry.get_value(TELEMETRY_CREW_VITALITY)
	var	death_rate = telemetry.get_value(TELEMETRY_DEATH_RATE)
	var	research = telemetry.get_value(TELEMETRY_RESEARCH_THRESHOLD)

	// Weighted contributions (each contributes to tension)
	new_tension += (100 - power) * 0.10       // Power grid: 10%
	new_tension += (100 - atmos) * 0.10       // Atmos: 10%
	new_tension += (100 - structural) * 0.15  // Structural: 15%
	new_tension += (100 - comms) * 0.05       // Comms: 5%
	new_tension += (100 - loyalty_val) * 0.15 // Loyalty: 15%
	new_tension += (100 - vitality) * 0.10    // Crew vitality: 10%
	new_tension += (100 - death_rate) * 0.10  // Death rate: 10%
	new_tension += (100 - research) * 0.05    // Research threshold: 5%

	// Add tension from corporate profiles
	var/profile_tension = 0
	for(var/datum/mind/M in profiles)
		var/datum/corporate_profile/CP = profiles[M]
		if(CP)
			profile_tension += CP.tension_contribution
	new_tension += min(profile_tension, 20)  // Cap profile contribution at 20

	// Apply natural decay toward the calculated value
	var/difference = new_tension - tension
	if(difference > 0)
		// Tension rises faster than it falls
		tension = clamp(tension + difference * 0.5, 0, TENSION_MAX)
		tension_last_change_reason = "Telemetry-driven rise"
	else
		// Slow decay
		tension = clamp(tension + difference * 0.3, 0, TENSION_MAX)
		tension_last_change_reason = "Telemetry-driven decay"

/// Update the state machine based on tension
/datum/controller/subsystem/director/proc/update_state()
	if(director_state == DIRECTOR_STATE_BOILING)
		return  // Stay in boiling until concluded

	if(tension >= TENSION_CRITICAL && director_state < DIRECTOR_STATE_BOILING)
		// Trigger boiling point
		director_state = DIRECTOR_STATE_BOILING
		boiling_point.start(telemetry)
		return

	if(tension >= TENSION_HIGH && director_state < DIRECTOR_STATE_ESCALATING)
		director_state = DIRECTOR_STATE_ESCALATING
		tension_last_change_reason = "Escalation threshold reached"
		return

	if(tension >= TENSION_ELEVATED && director_state < DIRECTOR_STATE_SIMMERING)
		director_state = DIRECTOR_STATE_SIMMERING
		tension_last_change_reason = "Simmering threshold reached"
		return

	if(tension < TENSION_RISING && director_state > DIRECTOR_STATE_MONITORING)
		director_state = DIRECTOR_STATE_MONITORING
		tension_last_change_reason = "Tension subsided"

/// Check all catalyst events and trigger any that meet conditions
/datum/controller/subsystem/director/proc/check_catalysts()
	for(var/datum/catalyst_event/C in catalysts)
		if(C.can_trigger(telemetry, tension))
			C.trigger(telemetry)

/// Check corporate profiles for completion
/datum/controller/subsystem/director/proc/check_profiles()
	for(var/datum/mind/M in profiles)
		var/datum/corporate_profile/CP = profiles[M]
		if(CP)
			CP.check_completion()

/// Add tension from external sources (catalyst events, admin actions, etc.)
/datum/controller/subsystem/director/proc/add_tension(var/amount, var/reason = "")
	tension = clamp(tension + amount, 0, TENSION_MAX)
	if(reason)
		tension_last_change_reason = reason
	log_debug("AI Director: Tension +[amount] ([reason]). Now at [round(tension)].")

/// Reduce tension from external sources
/datum/controller/subsystem/director/proc/reduce_tension(var/amount, var/reason = "")
	tension = clamp(tension - amount, 0, TENSION_MAX)
	if(reason)
		tension_last_change_reason = reason
	log_debug("AI Director: Tension -[amount] ([reason]). Now at [round(tension)].")

/// Called when a crewmember is arrested (hook from security systems)
/datum/controller/subsystem/director/proc/register_arrest()
	telemetry.register_arrest()

/// Returns a cryptic hint about an impending catalyst or the Boiling Point, for fluff systems like dreaming. Null if nothing looms.
/datum/controller/subsystem/director/proc/get_foreshadowing()
	if(!enabled || director_state == DIRECTOR_STATE_DORMANT || director_state == DIRECTOR_STATE_CONCLUDED)
		return null

	if(director_state == DIRECTOR_STATE_BOILING || tension >= TENSION_CRITICAL)
		return pick("the station screaming as it tears itself apart", "steel doors sealing forever", "the reactor breathing its last")

	var/list/omens = list()
	for(var/datum/catalyst_event/C in catalysts)
		if(C.uses_this_round >= C.max_uses_per_round)
			continue
		if(C.check_conditions(telemetry))
			omens += C.omen_text

	if(!omens.len)
		return null
	return pick(omens)

/// Called when a crewmember dies (hook from death systems)
/datum/controller/subsystem/director/proc/register_death()
	telemetry.register_death()
	add_tension(3, "Crew death")

/// Called when comms blackout starts/ends
/datum/controller/subsystem/director/proc/set_comms_blackout(var/active)
	telemetry.set_comms_blackout(active)
	if(active)
		add_tension(5, "Communications blackout")

/// Called at round end to evaluate all profiles
/datum/controller/subsystem/director/proc/on_round_end()
	director_state = DIRECTOR_STATE_CONCLUDED

	// Evaluate all corporate profiles
	for(var/datum/mind/M in profiles)
		var/datum/corporate_profile/CP = profiles[M]
		if(CP)
			CP.round_end_evaluation()

	// Print profile summaries
	var/list/summaries = list()
	for(var/datum/mind/M in profiles)
		var/datum/corporate_profile/CP = profiles[M]
		if(CP)
			var/summary = CP.get_summary()
			if(summary)
				summaries += "[M.name] ([M.key]): [summary]"

	if(summaries.len)
		to_world("<br><br><b>Corporate Profiles:</b><br>[jointext(summaries, "<br>")]")

	// Print faction summary
	var/faction_summary = loyalty.get_faction_summary()
	log_debug("AI Director: Final faction distribution: [list2params(faction_summary)]")

	// Reset loyalty tracker
	loyalty.reset()

/// Admin verb to get a status report
/datum/controller/subsystem/director/proc/status_report()
	var/html = "<h2>AI Director Status</h2>"
	html += "<b>State:</b> [state_name()]<br>"
	html += "<b>Tension:</b> [round(tension)]/100<br>"
	html += "<b>Last Change:</b> [tension_last_change_reason]<br>"
	html += "<br><b>Telemetry:</b><br>"
	html += "<table border='1'>"
	html += "<tr><td>Power Grid</td><td>[round(telemetry.get_value(TELEMETRY_POWER_GRID))]</td></tr>"
	html += "<tr><td>Atmos Integrity</td><td>[round(telemetry.get_value(TELEMETRY_ATMOS_INTEGRITY))]</td></tr>"
	html += "<tr><td>Structural</td><td>[round(telemetry.get_value(TELEMETRY_STRUCTURAL))]</td></tr>"
	html += "<tr><td>Comms Status</td><td>[round(telemetry.get_value(TELEMETRY_COMMS_STATUS))]</td></tr>"
	html += "<tr><td>Loyalty</td><td>[round(telemetry.get_value(TELEMETRY_LOYALTY))]</td></tr>"
	html += "<tr><td>Crew Vitality</td><td>[round(telemetry.get_value(TELEMETRY_CREW_VITALITY))]</td></tr>"
	html += "<tr><td>Death Rate</td><td>[round(telemetry.get_value(TELEMETRY_DEATH_RATE))]</td></tr>"
	html += "<tr><td>Research Threshold</td><td>[round(telemetry.get_value(TELEMETRY_RESEARCH_THRESHOLD))]</td></tr>"
	html += "</table>"
	html += "<br><b>Corporate Profiles:</b> [profiles.len] active<br>"
	html += "<br><b>Faction Distribution:</b><br>"
	var/faction_summary = loyalty.get_faction_summary()
	for(var/faction in faction_summary)
		html += "[faction]: [faction_summary[faction]]<br>"
	html += "<br><b>Catalyst Events:</b><br>"
	for(var/datum/catalyst_event/C in catalysts)
		html += "[C.name]: [C.uses_this_round]/[C.max_uses_per_round] uses<br>"
	if(boiling_point.active)
		html += "<br><b>BOILING POINT ACTIVE:</b> [boiling_point.scenario]<br>"
		html += "Time remaining: [round(boiling_point.time_remaining / 600)] minutes<br>"
	return html

/// Admin verb to force tension
/datum/controller/subsystem/director/proc/admin_set_tension(var/amount)
	tension = clamp(amount, 0, TENSION_MAX)
	log_and_message_admins("set AI Director tension to [tension].")
	update_state()

/// Admin verb to force a catalyst
/datum/controller/subsystem/director/proc/admin_force_catalyst(var/catalyst_type)
	for(var/datum/catalyst_event/C in catalysts)
		if(C.catalyst_type == catalyst_type)
			C.last_triggered = 0
			C.uses_this_round = 0
			C.trigger(telemetry)
			log_and_message_admins("forced catalyst event '[C.name]'.")
			return

/// Admin verb to force boiling point
/datum/controller/subsystem/director/proc/admin_force_boiling_point()
	if(!boiling_point.active)
		boiling_point.start(telemetry)
		director_state = DIRECTOR_STATE_BOILING
		log_and_message_admins("forced Boiling Point endgame.")