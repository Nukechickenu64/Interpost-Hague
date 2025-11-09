/datum/game_mode/all_antags
	name = "All Antags"
	round_description = "Every known antagonist type is in play. Expect chaos."
	extended_round_description = "This mode attempts to include and spawn every antagonist template supported by the server."
	config_tag = "allantags"
	votable = 1
	probability = 0
	required_players = 0
	required_enemies = 0
	end_on_antag_death = 0
	round_autoantag = TRUE
	require_all_templates = 0
	antag_scaling_coeff = 3

/datum/game_mode/all_antags/New()
	..()
	// Populate antag_templates with all available antagonist datums, excluding explicitly excepted ones
	antag_templates = list()
	for(var/antag_type in GLOB.all_antag_types_)
		var/datum/antagonist/A = GLOB.all_antag_types_[antag_type]
		if(!A)
			continue
		if(A.flags & ANTAG_RANDOM_EXCEPTED)
			continue
		antag_templates |= A

/datum/game_mode/all_antags/announce()
	// Use the base announcement but ensure we show a short summary
	..()
	if(antag_templates && antag_templates.len)
		var/names = list()
		for(var/datum/antagonist/A in antag_templates)
			names += A.role_text_plural
		to_world("<b>Active antagonist types:</b> [english_list(names, ", ", ", and ")].")

/datum/game_mode/all_antags/pre_setup()
	// Let the base logic preselect any job-overriding antags before jobs are handed out
	return ..()

/datum/game_mode/all_antags/post_setup()
	// After jobs have been assigned, try to spawn a roundstart set of each antagonist type
	. = ..()
	if(!(antag_templates && antag_templates.len))
		return
	for(var/datum/antagonist/A in antag_templates)
		A.attempt_random_spawn()
	return .
