// Dynamic State-Machine Gamemode
// Instead of rolling a gamemode at round start, the server uses the AI Director
// to continuously evaluate station state and scale threats dynamically.
// This gamemode is a thin wrapper that delegates to SSdirector.

/datum/game_mode/dynamic
	name = "Dynamic"
	round_description = "An AI Director monitors telemetry and scales threats dynamically. One hidden traitor, leech or logomancer is selected at round start and awakens after five minutes."
	extended_round_description = "A hidden traitor, leech or logomancer is selected from the crew at round start. After five minutes, a traitor receives their assignment, a logomancer awakens to words that bend the world, while a leech suffers a fatal heart attack and may rise again one minute later. The AI Director continues monitoring live station telemetry and triggering Catalyst Events tailored to the environment."
	config_tag = "dynamic"
	votable = 1
	probability = 10
	required_players = 0
	required_enemies = 0
	end_on_antag_death = 0
	round_autoantag = FALSE  // The Director handles antag spawning, not the auto-spawner
	antag_scaling_coeff = 0
	addantag_allowed = ADDANTAG_ADMIN  // Only admins can manually add antags; Director handles the rest

/datum/game_mode/dynamic/New()
	..()
	// No antag templates - the Director spawns antagonists dynamically
	antag_tags = list()
	antag_templates = list()

/datum/game_mode/dynamic/announce()
	to_world("<B>The Director is active. Your actions will shape the round.</B>")
	to_world("<i>Instead of a pre-determined gamemode, the server is continuously evaluating station telemetry and scaling threats based on crew behavior. Tension will rise and fall based on what happens during the shift. Every crewmember has a Corporate Profile - check your notes for details.</i>")

/datum/game_mode/dynamic/pre_setup()
	// No traditional antag pre-setup - the Director handles everything
	// Just ensure the Director is enabled
	if(SSdirector)
		SSdirector.enabled = TRUE
	return 1

/datum/game_mode/dynamic/post_setup()
	. = ..()

	// Activate the AI Director
	if(SSdirector)
		SSdirector.on_round_start()

	// Schedule the shift report
	spawn(rand(waittime_l, waittime_h))
		GLOB.using_map.send_welcome()

/datum/game_mode/dynamic/process()
	// The Director subsystem handles all processing via SSdirector.fire()
	// This is just a passthrough for any gamemode-specific logic
	return

/datum/game_mode/dynamic/check_finished()
	// The round ends once the evacuation shuttle has returned offsite.
	if(SSevac.evacuation_controller && SSevac.evacuation_controller.round_over())
		return 1
	return 0

/datum/game_mode/dynamic/declare_completion()
	// Let the Director print corporate profile summaries
	if(SSdirector)
		SSdirector.on_round_end()

	// Then do the standard completion
	. = ..()

/datum/game_mode/dynamic/cleanup()
	// Reset the Director for the next round
	if(SSdirector)
		SSdirector.reset_starter_antagonist()
		SSdirector.director_state = DIRECTOR_STATE_DORMANT
		SSdirector.tension = 0
		if(SSdirector.boiling_point)
			SSdirector.boiling_point.reset()
	return ..()