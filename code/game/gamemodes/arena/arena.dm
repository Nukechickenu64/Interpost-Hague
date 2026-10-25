// Arena is loaded on demand, so it can be voted in on an ordinary server build.
/datum/game_mode/arena
	name = "Arena"
	config_tag = "arena"
	round_description = "Sword fights with unlimited respawns. A lone fighter faces practice opponents."
	extended_round_description = "Everyone receives the same sword and armor. Respawn immediately from the ghost menu, without limits."
	uses_station_jobs = FALSE
	unrestricted_respawn = TRUE
	ert_disabled = TRUE
	addantag_allowed = 0
	var/arena_z
	var/next_opponent = 0
	var/list/fighters = list()
	var/list/opponents = list()
	var/list/player_spawns = list()
	var/list/ai_spawns = list()

/obj/effect/landmark/arena_spawn
	name = "Arena player spawn"

/obj/effect/landmark/arena_ai_spawn
	name = "Arena AI spawner"

/area/arena
	name = "Arena"
	requires_power = FALSE
	dynamic_lighting = FALSE
	has_gravity = TRUE

// Fresh mixtures make the area independent of zone pressure, breaches and toxins.
/proc/arena_air()
	var/datum/gas_mixture/air = new
	air.gas = list("oxygen" = MOLES_O2STANDARD, "nitrogen" = MOLES_N2STANDARD)
	air.temperature = T20C
	air.update_values()
	return air

/datum/game_mode/arena/pre_setup()
	if(!arena_z)
		var/datum/map_template/map = new(list("maps/arena.dmm"), "Arena")
		var/turf/loaded = map.load_new_z(1, 1)
		if(!loaded)
			CRASH("Unable to load maps/arena.dmm")
		arena_z = loaded.z
		qdel(map)
		if(SSzcopy.zstack_maximums.len)
			SSzcopy.calculate_zstack_limits()
		for(var/obj/effect/landmark/arena_spawn/marker in world)
			if(marker.z == arena_z)
				player_spawns += marker
		for(var/obj/effect/landmark/arena_ai_spawn/marker in world)
			if(marker.z == arena_z)
				ai_spawns += marker
		if(!player_spawns.len || !ai_spawns.len)
			CRASH("Arena requires player and AI spawn landmarks")
	// The arena becomes the round's main playable level; station infrastructure
	// remains loaded because the server's subsystem initialization uses it.
	GLOB.using_map.station_levels = list(arena_z)
	GLOB.using_map.player_levels = list(arena_z)
	GLOB.using_map.sealed_levels |= arena_z
	config.allow_random_events = FALSE
	SSdirector.enabled = FALSE
	next_opponent = world.time + 15 SECONDS

/datum/game_mode/arena/post_setup()
	return TRUE

/datum/game_mode/arena/check_finished()
	return FALSE

/datum/game_mode/arena/proc/find_spawn(list/landmarks)
	var/list/available = list()
	for(var/obj/effect/landmark/marker in landmarks)
		var/turf/tile = get_turf(marker)
		if(!tile || tile.density)
			continue
		var/blocked = FALSE
		for(var/atom/movable/occupant in tile)
			if(occupant.density)
				blocked = TRUE
		if(!blocked)
			available += tile
	if(available.len)
		return pick(available)
	// Players must never be locked out just because all spawn points are occupied.
	for(var/obj/effect/landmark/marker in landmarks)
		var/turf/tile = get_turf(marker)
		if(tile && !tile.density)
			return tile
	return null

/proc/equip_arena_fighter(mob/living/carbon/human/fighter)
	// The middle skill tier is adept (rank 5, stored as 50).
	fighter.skills["swords"] = 50
	fighter.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(fighter), slot_w_uniform)
	fighter.equip_to_slot_or_del(new /obj/item/clothing/shoes/jackboots(fighter), slot_shoes)
	fighter.equip_to_slot_or_del(new /obj/item/clothing/suit/armor/breastplate(fighter), slot_wear_suit)
	fighter.equip_to_slot_or_del(new /obj/item/clothing/head/helmet(fighter), slot_head)
	fighter.equip_to_slot_or_del(new /obj/item/weapon/material/sword(fighter), slot_r_hand)

/datum/game_mode/arena/spawn_player(mob/new_player/player)
	if(!player?.client || player.spawning || GAME_STATE != RUNLEVEL_GAME)
		return FALSE
	var/turf/tile = find_spawn(player_spawns)
	if(!tile)
		return FALSE
	player.spawning = TRUE
	var/mob/living/carbon/human/fighter = player.create_character(tile)
	if(!fighter)
		player.spawning = FALSE
		return FALSE
	fighter.mind.assigned_role = "Arena Fighter"
	fighter.job = "Arena Fighter"
	SSticker.minds |= fighter.mind
	equip_arena_fighter(fighter)
	fighters |= fighter
	to_chat(fighter, SPAN_NOTICE("Welcome to Arena! Respawn from the ghost menu whenever you like. There are no respawn limits or delays."))
	qdel(player)
	return TRUE

/datum/game_mode/arena/proc/respawn_player(mob/observer/ghost/ghost)
	if(!ghost?.client || GAME_STATE != RUNLEVEL_GAME)
		return FALSE
	var/client/player_client = ghost.client
	var/mob/new_player/player = new
	player.key = ghost.key
	if(!spawn_player(player))
		if(player.client)
			ghost.key = player.key
		qdel(player)
		return FALSE
	ghost.can_reenter_corpse = FALSE
	announce_ghost_joinleave(player_client, 0)
	qdel(ghost)
	return TRUE

/datum/game_mode/arena/proc/living_player_count()
	var/living_players = 0
	for(var/mob/living/carbon/human/fighter in fighters.Copy())
		if(QDELETED(fighter) || fighter.stat == DEAD)
			fighters -= fighter
		else if(fighter.client && fighter.z == arena_z)
			living_players++
	return living_players

/datum/game_mode/arena/process()
	var/living_players = living_player_count()
	for(var/mob/living/carbon/human/invader/arena/opponent in opponents.Copy())
		if(QDELETED(opponent) || opponent.stat == DEAD)
			opponents -= opponent
	if(living_players != 1)
		next_opponent = world.time + 15 SECONDS
		return
	if(opponents.len)
		next_opponent = world.time + 15 SECONDS
		return
	if(world.time < next_opponent)
		return
	var/turf/tile = find_spawn(ai_spawns)
	if(tile)
		var/opponent_type = pick(/mob/living/carbon/human/invader/arena, /mob/living/carbon/human/invader/arena/defender)
		var/mob/living/carbon/human/invader/arena/opponent = new opponent_type(tile)
		opponents += opponent
		to_world(SPAN_NOTICE("A practice opponent enters the arena."))
	next_opponent = world.time + 15 SECONDS
