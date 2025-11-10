/datum/game_mode/cult_only
	name = "Cult Uprising"
	round_description = "Only the cult stirs in the shadows."
	extended_round_description = "A cult-only round. Spawns cultists as the sole antagonist template. Ideal for testing and themed rounds."
	config_tag = "cult_only"
	votable = 1
	probability = 0
	required_players = 0
	required_enemies = 0
	end_on_antag_death = 1
	round_autoantag = TRUE
	require_all_templates = 0
	antag_scaling_coeff = 1

/datum/game_mode/cult_only/New()
	..()
	antag_templates = list()
	// Ensure only the cultist antagonist is used
	if(GLOB.all_antag_types_)
		var/datum/antagonist/cultist/C = GLOB.all_antag_types_[/datum/antagonist/cultist]
		if(istype(C))
			antag_templates |= C
		else
			// Fallback: instantiate a cultist template if not present in global list
			antag_templates |= new /datum/antagonist/cultist

/datum/game_mode/cult_only/pre_setup()
	return ..()

/datum/game_mode/cult_only/post_setup()
	. = ..()
	// Ensure we have at least one cultist; let template handle scaling
	for(var/datum/antagonist/A in antag_templates)
		A.attempt_random_spawn()
	return .
