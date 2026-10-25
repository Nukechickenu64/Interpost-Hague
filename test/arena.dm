// Supply a controlled connected-player count without manufacturing BYOND clients.
/datum/game_mode/arena/regression
	config_tag = "arena_regression"
	votable = FALSE
	var/test_players = 0

/datum/game_mode/arena/regression/living_player_count()
	return test_players

// A client-less target stands in for a connected player for the action test.
/datum/invader_ai/arena/regression/is_valid_target(mob/living/carbon/human/H)
	return H && H != owner && H.stat == CONSCIOUS && H.z == owner.z

/datum/unit_test/arena
	name = "ARENA - Map, loadout, solo spawning and breach survival"

/datum/unit_test/arena/start_test()
	var/failure = ""
	var/list/old_station = GLOB.using_map.station_levels
	var/list/old_players = GLOB.using_map.player_levels
	var/old_events = config.allow_random_events
	var/old_director = SSdirector.enabled
	var/datum/game_mode/arena/regression/mode = new
	mode.pre_setup()
	var/original_z = world.maxz
	mode.pre_setup()
	if(world.maxz != original_z) failure += "Setup loaded the map twice. "
	if(!mode.player_spawns.len || !mode.ai_spawns.len) failure += "Map landmarks were not loaded. "
	for(var/obj/effect/landmark/marker in mode.player_spawns + mode.ai_spawns)
		var/turf/spawn_tile = get_turf(marker)
		if(!spawn_tile || marker.z != mode.arena_z || !istype(get_area(marker), /area/arena) || spawn_tile.density) failure += "Arena spawn landmark is outside a walkable arena tile. "
	if(!(mode.arena_z in GLOB.using_map.station_levels) || !mode.unrestricted_respawn || mode.uses_station_jobs || mode.check_finished()) failure += "Arena mode policy failed. "
	mode.next_opponent = 0
	mode.process()
	if(mode.opponents.len) failure += "Empty arena spawned an AI. "
	mode.test_players = 2
	mode.next_opponent = 0
	mode.process()
	if(mode.opponents.len) failure += "Multiplayer arena spawned an AI. "
	mode.test_players = 1
	mode.next_opponent = world.time + 100
	mode.process()
	if(mode.opponents.len) failure += "Solo grace period was skipped. "
	mode.next_opponent = 0
	mode.process()
	if(mode.opponents.len != 1)
		fail("Solo arena did not spawn exactly one opponent.")
		return TRUE
	var/mob/living/carbon/human/invader/arena/bot = mode.opponents[1]
	STOP_PROCESSING(SSinvaders, bot.brain)
	var/on_marker = FALSE
	for(var/obj/effect/landmark/marker in mode.ai_spawns)
		if(get_turf(marker) == get_turf(bot)) on_marker = TRUE
	if(!on_marker) failure += "AI did not use its landmark. "
	mode.next_opponent = 0
	mode.process()
	if(mode.opponents.len != 1) failure += "Live opponents stacked up. "
	var/turf/T = mode.find_spawn(mode.player_spawns)
	var/mob/living/carbon/human/player = new(T)
	equip_arena_fighter(player)
	if(player.skills["swords"] != 50 || player.gurps_skill_rank("swords") != 5) failure += "Arena player did not start with medium sword skill. "
	if(!player.r_hand || player.r_hand.type != bot.r_hand?.type || player.wear_suit?.type != bot.wear_suit?.type || player.head?.type != bot.head?.type) failure += "Player and AI loadouts differ. "
	if(!istype(bot.brain, /datum/invader_ai/arena) || bot.skills["swords"] != 35) failure += "Practice AI configuration failed. "
	var/datum/invader_ai/arena/regression/test_brain = new(bot, bot.mover)
	bot.forceMove(get_step(T, EAST))
	test_brain.target = player
	bot.combat_mode = TRUE
	bot.guard_chance = 100
	bot.combat_action_until = 0
	bot.next_move = 0
	bot.special_action_ready_until = 0
	bot.hand = FALSE
	bot.combat_steps = 0
	test_brain.melee_attack()
	if(bot.combat_action_until <= world.time || !bot.guard_stance_charges) failure += "AI guard did not use the shared combat action. "
	var/stamina_after_guard = bot.staminaloss
	test_brain.melee_attack()
	if(bot.staminaloss != stamina_after_guard) failure += "AI bypassed its action cooldown. "
	player.stat = UNCONSCIOUS
	if(test_brain.is_valid_target(player) || bot.brain.is_valid_target(player)) failure += "AI targets unconscious players. "
	player.stat = CONSCIOUS
	qdel(test_brain)
	var/area/A = get_area(T)
	if(!A.powered(EQUIP) || !A.powered(LIGHT) || !A.powered(ENVIRON)) failure += "Arena power is not infinite. "
	// Simulated floor pollution and a full floor breach must both return fresh air.
	T = T.ChangeTurf(/turf/simulated/floor)
	var/datum/gas_mixture/air = T.return_air()
	air.gas = list("phoron" = 100)
	air.temperature = 1000
	T.assume_air(air)
	air = T.return_air()
	if(air.gas["phoron"] || air.temperature != T20C || abs(air.return_pressure() - ONE_ATMOSPHERE) > 1) failure += "Pollution changed arena air. "
	T = T.ChangeTurf(/turf/space)
	air = T.return_air()
	if(air.temperature != T20C || abs(air.return_pressure() - ONE_ATMOSPHERE) > 1) failure += "Breach removed arena air. "
	var/datum/gas_mixture/breath = player.get_breath_from_environment()
	if(!breath || !breath.gas["oxygen"]) failure += "Breathing failed on breached arena turf. "
	bot.stat = DEAD
	mode.next_opponent = 0
	mode.process()
	if(mode.opponents.len != 1 || mode.opponents[1] == bot) failure += "Dead opponent was not replaced. "
	for(var/mob/living/opponent in mode.opponents) qdel(opponent)
	qdel(bot)
	qdel(player)
	qdel(mode)
	GLOB.using_map.station_levels = old_station
	GLOB.using_map.player_levels = old_players
	config.allow_random_events = old_events
	SSdirector.enabled = old_director
	if(failure) fail(failure)
	else pass("Map loading, identical equipment, solo grace/cap/replacement, power and breached-turf breathing verified.")
	return TRUE
