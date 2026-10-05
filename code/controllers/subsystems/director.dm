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
	var/list/profiles = list()

	// Catalyst events
	var/list/datum/catalyst_event/catalysts = list()
	var/datum/director_arc/current_arc
	var/list/datum/director_arc/arc_history = list()

	// Timing
	var/last_telemetry_sample = 0
	var/last_evaluation = 0
	var/last_director_beat = 0
	var/round_start_time = 0
	var/starter_required = FALSE
	var/list/starter_role_weights = list(MODE_TRAITOR = 40, "leech" = 40, MODE_LOGOMANCER = 20)
	var/starter_role
	var/datum/mind/starter_mind
	var/mob/living/carbon/human/starter_body
	var/starter_ckey
	var/starter_deadline = 0
	var/starter_resurrection_at = 0
	var/starter_notified = FALSE
	var/starter_busy = FALSE
	var/client/starter_action_client

	// Configuration
	var/enabled = TRUE
	var/debt_probability = 25
	var/agenda_probability = 60
	// Minimum antagonist presence maintenance
	var/list/antag_last_activity = list()  // mind -> world.time of last recorded hostile action
	var/last_antag_maintenance = 0

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
		new /datum/catalyst_event/pony_incursion(),
		new /datum/catalyst_event/leech(),
		new /datum/catalyst_event/epicurean(),
		new /datum/catalyst_event/cargo_incursion(),
	)

	log_debug("AI Director: Initialized with [catalysts.len] catalyst events.")
	return ..()

/datum/controller/subsystem/director/Recover()
	telemetry = SSdirector.telemetry
	loyalty = SSdirector.loyalty
	boiling_point = SSdirector.boiling_point
	profiles = SSdirector.profiles
	catalysts = SSdirector.catalysts
	current_arc = SSdirector.current_arc
	arc_history = SSdirector.arc_history
	tension = SSdirector.tension
	director_state = SSdirector.director_state
	round_start_time = SSdirector.round_start_time
	starter_required = SSdirector.starter_required
	starter_role = SSdirector.starter_role
	starter_mind = SSdirector.starter_mind
	starter_body = SSdirector.starter_body
	starter_ckey = SSdirector.starter_ckey
	starter_deadline = SSdirector.starter_deadline
	starter_resurrection_at = SSdirector.starter_resurrection_at
	starter_notified = SSdirector.starter_notified
	starter_action_client = SSdirector.starter_action_client

/datum/controller/subsystem/director/fire(resumed = FALSE)
	if(!enabled)
		return

	if(GAME_STATE != RUNLEVEL_GAME)
		return

	process_starter_antagonist()

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

/// Called when the round starts to reset Director state for a new narrative.
/datum/controller/subsystem/director/proc/on_round_start()
	reset_starter_antagonist()
	director_state = DIRECTOR_STATE_MONITORING
	tension = 5  // Start with a small baseline
	round_start_time = world.time
	last_telemetry_sample = 0
	last_evaluation = 0
	last_director_beat = 0
	if(current_arc)
		qdel(current_arc)
	current_arc = null
	for(var/datum/director_arc/old_arc in arc_history)
		qdel(old_arc)
	arc_history.Cut()

	// Reset components
	telemetry = new()
	loyalty = new()
	boiling_point.reset()
	for(var/datum/catalyst_event/C in catalysts)
		C.reset()
	profiles.Cut()
	assign_corporate_profiles()
	if(istype(SSticker.mode, /datum/game_mode/dynamic))
		starter_required = TRUE
		starter_role = pickweight(starter_role_weights.Copy())
		starter_deadline = round_start_time + DIRECTOR_STARTER_DELAY
		select_starter_antagonist()
	log_debug("AI Director: Round started. Assigned [profiles.len] corporate profiles.")

/datum/controller/subsystem/director/proc/clear_starter_candidate()
	if(starter_action_client)
		starter_action_client.verbs -= /client/proc/rise_as_leech
	starter_action_client = null
	starter_mind = null
	starter_body = null
	starter_ckey = null
	starter_resurrection_at = 0

/datum/controller/subsystem/director/proc/reset_starter_antagonist()
	clear_starter_candidate()
	starter_required = FALSE
	starter_role = null
	starter_deadline = 0
	starter_notified = FALSE
	starter_busy = FALSE

/datum/controller/subsystem/director/proc/starter_candidate_eligible(mob/living/carbon/human/candidate, antag_id)
	if(!is_antagonist_enabled(antag_id))
		return FALSE
	if(!candidate || QDELETED(candidate) || !candidate.client || !candidate.mind || candidate.stat == DEAD || !is_station_turf(get_turf(candidate)))
		return FALSE
	if(player_is_antag(candidate.mind) || candidate.mind.leech_conversion_pending)
		return FALSE
	var/datum/antagonist/antag = GLOB.all_antag_types_[antag_id]
	if(!antag || antag.get_antag_count() >= antag.hard_cap || !antag.can_become_antag(candidate.mind, FALSE))
		return FALSE
	if(antag_id == "leech")
		var/obj/item/organ/internal/heart/heart = candidate.get_organ(BP_HEART)
		if(!heart || heart.robotic >= ORGAN_ROBOT || heart.pulse == PULSE_NONE || (heart.status & ORGAN_DEAD) || !candidate.vessel || candidate.species.blood_volume <= 0)
			return FALSE
	return TRUE

/datum/controller/subsystem/director/proc/select_starter_antagonist()
	clear_starter_candidate()
	var/list/roles = list(starter_role)
	var/list/remaining = starter_role_weights.Copy()
	remaining -= starter_role
	while(remaining.len)
		var/next_role = pickweight(remaining)
		roles += next_role
		remaining -= next_role
	for(var/antag_id in roles)
		var/list/candidates = list()
		for(var/mob/living/carbon/human/candidate in GLOB.player_list)
			if(starter_candidate_eligible(candidate, antag_id))
				candidates += candidate
		if(!candidates.len)
			continue
		starter_role = antag_id
		starter_body = pick(candidates)
		starter_mind = starter_body.mind
		starter_ckey = starter_body.ckey
		starter_notified = FALSE
		log_debug("AI Director: Selected [starter_ckey] as delayed round-start [starter_role].")
		return TRUE
	if(!starter_notified)
		message_admins("AI Director: No eligible crew for the Dynamic starter antagonist. Selection will retry without bypassing antagonist restrictions.")
		starter_notified = TRUE
	return FALSE

/datum/controller/subsystem/director/proc/get_starter_client()
	if(starter_body?.client && starter_body.ckey == starter_ckey)
		return starter_body.client
	for(var/mob/observer/ghost/observer in GLOB.player_list)
		if(observer.client && observer.ckey == starter_ckey && observer.mind == starter_mind && observer.can_reenter_corpse && !observer.pain_possession_object)
			return observer.client
	return null

/datum/controller/subsystem/director/proc/starter_awakening_valid()
	if(!starter_required || !starter_resurrection_at || !starter_mind || QDELETED(starter_mind) || !starter_body || QDELETED(starter_body))
		return FALSE
	if(starter_body.mind != starter_mind || starter_mind.current != starter_body || player_is_antag(starter_mind))
		return FALSE
	var/client/owner = get_starter_client()
	if(!owner || (starter_body.client && starter_body.client != owner))
		return FALSE
	if(starter_body.key && copytext(starter_body.key, 1, 2) != "@" && starter_body.ckey != starter_ckey)
		return FALSE
	var/datum/antagonist/antag = GLOB.all_antag_types_["leech"]
	if(!antag || antag.get_antag_count() >= antag.hard_cap || !antag.can_become_antag(starter_mind, FALSE) || jobban_isbanned(owner.mob, antag.id))
		return FALSE
	if(config.use_age_restriction_for_jobs && isnum_safe(owner.player_age) && isnum_safe(antag.min_player_age) && owner.player_age < antag.min_player_age)
		return FALSE
	return TRUE

/datum/controller/subsystem/director/proc/process_starter_antagonist()
	if(!starter_required || starter_busy || director_state == DIRECTOR_STATE_DORMANT || director_state == DIRECTOR_STATE_CONCLUDED)
		return
	if(starter_resurrection_at)
		if(!starter_awakening_valid())
			log_debug("AI Director: Replacing unavailable cardiac starter [starter_ckey].")
			clear_starter_candidate()
		else
			var/client/owner = get_starter_client()
			if(starter_action_client != owner)
				if(starter_action_client)
					starter_action_client.verbs -= /client/proc/rise_as_leech
				starter_action_client = owner
				owner.verbs |= /client/proc/rise_as_leech
			if(starter_body.stat != DEAD)
				complete_starter_leech()
			return
	if(starter_mind && (starter_mind.current != starter_body || starter_body?.mind != starter_mind || starter_body?.ckey != starter_ckey || !starter_candidate_eligible(starter_body, starter_role)))
		log_debug("AI Director: Replacing unavailable starter [starter_ckey].")
		clear_starter_candidate()
	if(!starter_mind && !select_starter_antagonist())
		return
	if(world.time < starter_deadline)
		return
	starter_busy = TRUE
	if(starter_role == "leech")
		starter_body.begin_starter_leech_death()
	else
		var/datum/antagonist/antag = GLOB.all_antag_types_[starter_role]
		if(antag.add_antagonist(starter_mind, FALSE, FALSE, FALSE, FALSE, TRUE))
			loyalty.set_faction(starter_mind, starter_role == MODE_TRAITOR ? LOYALTY_SYNDICATE : LOYALTY_NEUTRAL)
			log_debug("AI Director: Activated round-start [starter_role] [starter_ckey].")
			starter_required = FALSE
			clear_starter_candidate()
		else
			clear_starter_candidate()
	starter_busy = FALSE

/datum/controller/subsystem/director/proc/can_recruit_antagonist(antag_id)
	if(starter_deadline && world.time < starter_deadline)
		return FALSE
	var/reserved = starter_required ? 1 : 0
	var/datum/antagonist/antag = GLOB.all_antag_types_[antag_id]
	if(!is_antagonist_enabled(antag_id) || !antag || antag.get_antag_count() + (starter_role == antag_id ? reserved : 0) >= antag.hard_cap)
		return FALSE
	return get_total_antag_count() + reserved < max(1, round(count_living_crew() / 2))

/datum/controller/subsystem/director/proc/assign_corporate_profiles()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.mind || !H.client || !is_station_turf(get_turf(H)) || player_is_antag(H.mind))
			continue
		var/datum/corporate_profile/CP = new(H.mind)
		var/roll = rand(1, 100)
		if(roll <= debt_probability)
			CP.generate_debt()
		else if(roll <= debt_probability + agenda_probability)
			CP.generate_agenda()
		profiles[H.mind] = CP
		spawn(rand(50, 200))
			if(CP && CP.owner && CP.owner.current)
				CP.show_to_player()
		loyalty.set_faction(H.mind, LOYALTY_NANOTRASEN)

/// Main evaluation loop - the heart of the Director Engine
/datum/controller/subsystem/director/proc/evaluate()
	if(director_state == DIRECTOR_STATE_DORMANT || director_state == DIRECTOR_STATE_CONCLUDED)
		return

	// Calculate tension from telemetry
	calculate_tension()
	apply_time_pressure()

	// Update state machine
	update_state()

	// Check catalyst events
	if(director_state >= DIRECTOR_STATE_SIMMERING && director_state < DIRECTOR_STATE_BOILING)
		check_catalysts()
	check_profiles()

	// Ensure the round always has at least one live antagonist to react to
	maintain_antagonist_presence()

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
	var/security_arrests = telemetry.get_value(TELEMETRY_SECURITY_ARRESTS)
	var	loyalty_val = telemetry.get_value(TELEMETRY_LOYALTY)
	var	vitality = telemetry.get_value(TELEMETRY_CREW_VITALITY)
	var	death_rate = telemetry.get_value(TELEMETRY_DEATH_RATE)
	var	research = telemetry.get_value(TELEMETRY_RESEARCH_THRESHOLD)

	// Weighted contributions (each contributes to tension)
	new_tension += (100 - power) * 0.10           // Power grid: 10%
	new_tension += (100 - atmos) * 0.10           // Atmos: 10%
	new_tension += (100 - structural) * 0.15      // Structural: 15%
	new_tension += (100 - comms) * 0.05           // Comms: 5%
	new_tension += (100 - security_arrests) * 0.10 // Security arrests: 10%
	new_tension += (100 - loyalty_val) * 0.15     // Loyalty: 15%
	new_tension += (100 - vitality) * 0.10        // Crew vitality: 10%
	new_tension += (100 - death_rate) * 0.10      // Death rate: 10%
	new_tension += (100 - research) * 0.05        // Research threshold: 5%
	var/profile_tension = 0
	for(var/datum/mind/M in profiles)
		var/datum/corporate_profile/CP = profiles[M]
		if(CP)
			profile_tension += CP.tension_contribution
	new_tension += min(profile_tension, 20)

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

/// Apply a growing minimum tension as the Director loses patience with a long shift.
/datum/controller/subsystem/director/proc/apply_time_pressure()
	if(!round_start_time)
		return

	var/elapsed = world.time - round_start_time
	if(elapsed <= DIRECTOR_IMPATIENCE_START)
		return

	var/impatience_window = DIRECTOR_MAX_ROUND_DURATION - boiling_point.total_duration - DIRECTOR_IMPATIENCE_START
	var/time_pressure = min(DIRECTOR_MAX_TIME_PRESSURE, ((elapsed - DIRECTOR_IMPATIENCE_START) / impatience_window) * DIRECTOR_MAX_TIME_PRESSURE)
	if(tension < time_pressure)
		tension = time_pressure
		tension_last_change_reason = "Director impatience"

/// Update the state machine based on tension
/datum/controller/subsystem/director/proc/update_state()
	if(director_state == DIRECTOR_STATE_BOILING)
		return  // Stay in boiling until concluded

	if(tension >= TENSION_CRITICAL && director_state < DIRECTOR_STATE_BOILING && finale_is_earned())
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
	if(world.time - last_director_beat < DIRECTOR_BEAT_COOLDOWN)
		return FALSE

	var/best_score = -1
	var/list/best_candidates = list()
	for(var/datum/catalyst_event/C in catalysts)
		if(!C.is_eligible(telemetry, tension))
			if(C.warning_active)
				C.clear_warning()
			continue
		var/score = C.director_priority
		if(current_arc && current_arc.theme == C.arc_theme)
			score += DIRECTOR_ARC_CONTINUITY_BONUS
		if(score > best_score)
			best_score = score
			best_candidates.Cut()
			best_candidates += C
		else if(score == best_score)
			best_candidates += C

	while(best_candidates.len)
		var/datum/catalyst_event/selected = pick(best_candidates)
		best_candidates -= selected
		if(selected.warning_duration && !selected.can_trigger(telemetry, tension))
			return FALSE
		if(!selected.trigger(telemetry))
			if(selected.warning_active)
				return FALSE
			continue
		last_director_beat = world.time
		if(!current_arc || current_arc.theme != selected.arc_theme)
			start_arc(selected)
		else
			current_arc.record_beat(selected, "Follow-up selected to preserve [current_arc.title] continuity")
		log_debug("AI Director: Arc '[current_arc.title]' advanced to beat [current_arc.beat_count] with [selected.name].")
		return TRUE
	return FALSE

/datum/controller/subsystem/director/proc/start_arc(var/datum/catalyst_event/first_beat)
	if(current_arc)
		arc_history += current_arc
		while(arc_history.len > DIRECTOR_ARC_HISTORY_LIMIT)
			var/datum/director_arc/oldest_arc = arc_history[1]
			arc_history.Cut(1, 2)
			qdel(oldest_arc)
	current_arc = new(first_beat.arc_theme, first_beat)

/datum/controller/subsystem/director/proc/finale_is_earned()
	return current_arc && current_arc.beat_count >= DIRECTOR_ARC_MIN_BEATS

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

/datum/controller/subsystem/director/proc/register_arrest(var/datum/mind/security_officer, var/record_uid)
	telemetry.register_arrest()
	var/datum/corporate_profile/CP = profiles[security_officer]
	if(CP)
		CP.credit_arrest(record_uid)

/// Records that an antagonist mind took a hostile/evil action (hooked from admin_attack_log and antagonist creation)
/datum/controller/subsystem/director/proc/record_antagonist_activity(var/datum/mind/M)
	if(!M)
		return
	antag_last_activity[M] = world.time

/// Total antagonists (any type) currently in the round
/datum/controller/subsystem/director/proc/get_total_antag_count()
	var/count = 0
	for(var/id in GLOB.all_antag_types_)
		var/datum/antagonist/AT = GLOB.all_antag_types_[id]
		count += AT.get_antag_count()
	return count

/// Total antagonists (any type) that are alive and connected
/datum/controller/subsystem/director/proc/get_total_active_antag_count()
	var/count = 0
	for(var/id in GLOB.all_antag_types_)
		var/datum/antagonist/AT = GLOB.all_antag_types_[id]
		count += AT.get_active_antag_count()
	return count

/// Number of living, connected crew on the station - used as the antagonist population cap basis
/datum/controller/subsystem/director/proc/count_living_crew()
	var/count = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.client || H.stat == DEAD)
			continue
		if(!is_station_turf(get_turf(H)))
			continue
		count++
	return count

/// TRUE if there are no active antagonists, or every active antagonist has gone quiet for too long
/datum/controller/subsystem/director/proc/all_active_antagonists_stale()
	for(var/id in GLOB.all_antag_types_)
		var/datum/antagonist/AT = GLOB.all_antag_types_[id]
		for(var/datum/mind/M in AT.current_antagonists)
			var/mob/living/L = M.current
			if(!L || L.stat == DEAD)
				continue //dead
			if(!L.client && !L.teleop)
				continue //SSD
			var/last_activity = antag_last_activity[M]
			if(last_activity && world.time - last_activity < ANTAG_STALE_THRESHOLD)
				return FALSE
	return TRUE //either nobody active, or everybody active has gone quiet

/// Keeps the round populated with at least one engaged antagonist, capped at half the living crew
/datum/controller/subsystem/director/proc/maintain_antagonist_presence()
	if(director_state == DIRECTOR_STATE_DORMANT || director_state == DIRECTOR_STATE_CONCLUDED)
		return
	if(starter_required || !can_recruit_antagonist("traitor"))
		return
	if(world.time - last_antag_maintenance < ANTAG_MAINTENANCE_COOLDOWN)
		return
	if(!all_active_antagonists_stale())
		return
	last_antag_maintenance = world.time

	var/max_allowed = max(1, round(count_living_crew() / 2))
	if(get_total_antag_count() >= max_allowed)
		return

	if(!try_spawn_replacement_antagonist())
		log_debug("AI Director: No eligible antagonist recruitment; continuing the active narrative arc without a replacement.")

/// Attempts to stand up a fresh traitor from a ghost candidate, or a living opted-in crewmember
/datum/controller/subsystem/director/proc/try_spawn_replacement_antagonist()
	if(!can_director_recruit_ghosts() && !can_director_convert_crew())
		return FALSE
	var/datum/antagonist/traitor_antag = GLOB.all_antag_types_["traitor"]
	if(!traitor_antag)
		return FALSE

	if(can_director_convert_crew() && convert_station_antagonist("traitor"))
		add_tension(10, "Director recruited an existing crewmember as an antagonist")
		return TRUE

	var/list/ghost_candidates = list()
	for(var/mob/observer/ghost/G in GLOB.player_list)
		if(G.client && G.client.prefs && G.client.prefs.be_special_role && ("traitor" in G.client.prefs.be_special_role))
			ghost_candidates += G

	if(ghost_candidates.len)
		var/mob/observer/ghost/chosen = pick(ghost_candidates)
		var/mob/living/carbon/human/replacement = director_spawn_ghost_body(chosen, "Agent [rand(100,999)]")
		if(replacement && replacement.mind && traitor_antag.add_antagonist(replacement.mind, 0, 0, 1))
			replacement.mind.assigned_role = "Syndicate Agent"
			loyalty.set_faction(replacement.mind, LOYALTY_SYNDICATE)
			to_chat(replacement, "<span class='danger'>You are a Syndicate agent, quietly inserted to keep the station on its toes. Complete your objectives with subtlety.</span>")
			add_tension(10, "Director restored a lapsed antagonist")
			return TRUE
		if(replacement)
			qdel(replacement)

	return FALSE

/datum/controller/subsystem/director/proc/can_director_recruit_ghosts()
	return config && config.director_antag_policy == DIRECTOR_ANTAG_POLICY_GHOSTS

/datum/controller/subsystem/director/proc/can_director_convert_crew()
	return config && config.director_antag_policy == DIRECTOR_ANTAG_POLICY_CREW

/// Returns a cryptic hint about an impending catalyst or the Boiling Point, for fluff systems like dreaming. Null if nothing looms.
/datum/controller/subsystem/director/proc/get_foreshadowing()
	if(!enabled || director_state == DIRECTOR_STATE_DORMANT || director_state == DIRECTOR_STATE_CONCLUDED)
		return null

	if(boiling_point.active || (tension >= TENSION_CRITICAL && finale_is_earned()))
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
	reset_starter_antagonist()
	director_state = DIRECTOR_STATE_CONCLUDED
	for(var/datum/mind/M in profiles)
		var/datum/corporate_profile/CP = profiles[M]
		if(CP)
			CP.round_end_evaluation()
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

/datum/controller/subsystem/director/proc/station_status_report()
	var/html = "<h2>Station Operational Status</h2><p>Source: AI Director station telemetry.</p>"
	if(!telemetry || !last_telemetry_sample)
		return html + "<p><b>Telemetry unavailable:</b> No station sample has been collected yet. Check local power controllers and air alarms.</p>"
	var/sample_age = max(0, round((world.time - last_telemetry_sample) / 10))
	html += "<p>Last sample: [sample_age] seconds ago. Reopen STATION STATUS to refresh this report.</p>"
	if(!enabled)
		html += "<p><b>Monitoring offline:</b> AI Director updates are disabled; these are the last recorded readings.</p>"
	else if(world.time - last_telemetry_sample > 2 * TELEMETRY_SAMPLE_INTERVAL)
		html += "<p><b>Warning:</b> Telemetry is stale. Verify conditions locally.</p>"
	var/list/metrics = list(
		list("key" = TELEMETRY_POWER_GRID, "name" = "Power supply", "meaning" = "Station area power controllers operating.", "advice" = "Check engine output, cabling and area power controllers."),
		list("key" = TELEMETRY_ATMOS_INTEGRITY, "name" = "Atmosphere", "meaning" = "Station areas passing temperature, oxygen and phoron checks.", "advice" = "Inspect air alarms, isolate unsafe compartments and restore breathable air."),
		list("key" = TELEMETRY_STRUCTURAL, "name" = "Hull integrity", "meaning" = "Estimated intact structure; exposed station edges count as possible breaches.", "advice" = "Inspect damaged walls and exposed compartments; seal confirmed hull breaches."),
		list("key" = TELEMETRY_COMMS_STATUS, "name" = "Communications", "meaning" = "Station telecomms relays enabled.", "advice" = "Inspect relay power and telecomms equipment; establish local communications."),
		list("key" = TELEMETRY_CREW_VITALITY, "name" = "Crew survival", "meaning" = "Living share of human crew currently on station, including unconscious crew.", "advice" = "Coordinate medical triage and search for missing or injured personnel.")
	)
	var/list/recommendations = list()
	html += "<table border='1' cellpadding='5'><tr><th>System</th><th>Reading</th><th>Trend</th><th>Interpretation</th></tr>"
	for(var/list/metric in metrics)
		var/key = metric["key"]
		var/value = round(telemetry.get_value(key))
		var/trend = telemetry.get_trend(key)
		var/trend_text = trend > 0 ? "Improving" : (trend < 0 ? "Declining" : "Stable")
		html += "<tr><td>[metric["name"]]</td><td>[value]%</td><td>[trend_text]</td><td>[metric["meaning"]]</td></tr>"
		if(value < 100)
			recommendations += metric["advice"]
	html += "</table><h3>Recommended Actions</h3>"
	if(length(recommendations))
		html += "<ul>"
		for(var/advice in recommendations)
			html += "<li>[advice]</li>"
		html += "</ul>"
	else
		html += "<p>No issues flagged by these sampled indicators. Continue local inspections and routine maintenance.</p>"
	html += "<p>These are station-wide estimates, not a guarantee that every room or device is safe.</p>"
	return html

/// Admin verb to get a status report
/datum/controller/subsystem/director/proc/status_report()
	var/html = "<h2>AI Director Status</h2>"
	html += "<b>State:</b> [state_name()]<br>"
	html += "<b>Tension:</b> [round(tension)]/100<br>"
	html += "<b>Last Change:</b> [tension_last_change_reason]<br>"
	if(starter_required)
		html += "<b>Starter:</b> [starter_role] / [starter_ckey ? starter_ckey : "awaiting eligible crew"]<br>"
		if(starter_resurrection_at)
			html += "Awaiting resurrection; self-revival ready in [max(0, round((starter_resurrection_at - world.time) / 10))] seconds<br>"
		else
			html += "Activation in [max(0, round((starter_deadline - world.time) / 10))] seconds<br>"
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
	var/antag_policy = config ? config.director_antag_policy : DIRECTOR_ANTAG_POLICY_CREW
	html += "<br><b>Antagonist Policy:</b> [antag_policy]<br>"
	if(current_arc)
		html += "<br><b>Active Arc:</b> [current_arc.title] ([current_arc.beat_count] beats)<br>"
		html += "Last beat rationale: [current_arc.last_selection_reason]<br>"
		html += "Finale readiness: [finale_is_earned() ? "earned" : "developing"]<br>"
	else
		html += "<br><b>Active Arc:</b> None<br>"
	if(last_director_beat)
		var/beat_wait = max(0, DIRECTOR_BEAT_COOLDOWN - (world.time - last_director_beat))
		html += "Next beat eligible in: [round(beat_wait / 10)] seconds<br>"
	else
		html += "Next beat eligible: Ready<br>"
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
			C.clear_warning()
			// Forcing skips tension, condition and warning gating, which trigger() would enforce.
			if(!C.execute(telemetry))
				log_and_message_admins("tried to force catalyst event '[C.name]', but it could not execute right now.")
				return
			C.last_triggered = world.time
			C.uses_this_round++
			log_and_message_admins("forced catalyst event '[C.name]'.")
			return

/// Admin verb to force boiling point
/datum/controller/subsystem/director/proc/admin_force_boiling_point()
	if(!boiling_point.active)
		boiling_point.start(telemetry)
		director_state = DIRECTOR_STATE_BOILING
		log_and_message_admins("forced Boiling Point endgame.")