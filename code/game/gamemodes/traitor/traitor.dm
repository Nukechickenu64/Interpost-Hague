/datum/game_mode/traitor
	name = "traitor"
	round_description = "There is a foreign agent or traitor onboard. Do not let the traitor succeed!"
	extended_round_description = "The Company's monopolistic control over the phoron supplies of Nyx has marked the \
		station to be a highly valuable target for many competing organizations and individuals. The varied pasts \
		and experiences of your coworkers have left them susceptible to the vices and temptations of humanity. \
		Are you in the safe self-contained workplace you once thought it was, or has it become a playground \
		for the evils of the galaxy? Who can you trust? Watch your front. Watch your sides. Watch your back. \
		The familiar faces that you've passed hundreds of times down the hallways before can be hiding terrible \
		secrets and deceptions. Every corner is a mystery. Every conversation is a lie. You will be facing your \
		friends and family as they try to use your emotions and trust to their advantage, leaving you with nothing \
		but the painful reminder that space is cruel and unforgiving."
	config_tag = "traitor"
	required_players = 0
	required_enemies = 1
	antag_tags = list(MODE_TRAITOR)
	antag_scaling_coeff = 5
	end_on_antag_death = 0
	latejoin_antag_tags = list(MODE_TRAITOR)
	var/datum/os13_traitor_orders/os13_orders

/datum/game_mode/traitor/pre_setup()
	if(istype(GLOB.using_map, /datum/map/os13classic))
		round_description = "Orbital Station 13 has awakened to evidence of sabotage. Find the traitor and secure the station."
		extended_round_description = "After six centuries in cryosleep, the crew of Orbital Station 13 wakes to a damaged station. The Marshal must investigate the sabotage and bring the traitor to the Brig while the rest of the crew repairs the station and defends it against outside threats."
		latejoin_antag_tags = list()
		round_autoantag = FALSE
		addantag_allowed = ADDANTAG_ADMIN
		antag_scaling_coeff = 0
	return ..()

/datum/game_mode/traitor/check_finished()
	return os13_orders?.bomb_detonated || ..()
