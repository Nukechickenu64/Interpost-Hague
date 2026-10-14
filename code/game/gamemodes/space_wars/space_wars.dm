#define SPACE_WARS_MAP_SIZE 200

/datum/game_mode/space_wars
	name = "Space Wars"
	config_tag = "space_wars"
	round_description = "Every pilot has their own freighter. Fight, explore, and respawn without limits."
	extended_round_description = "An empty 200 by 200 space arena. Every arrival and respawn receives a fresh freighter at a random clear location. Use Respawn in the pig menu's ghost tab to return immediately."
	uses_station_jobs = FALSE
	unrestricted_respawn = TRUE
	ert_disabled = TRUE
	votable = 1
	probability = 1
	addantag_allowed = 0
	var/arena_z
	var/freighter_serial = 0
	var/area/space/space_wars/arena_area

/area/space/space_wars
	name = "Space Wars"

// On maps wider than 200 tiles, an impassable outer row/column bounds the arena.
// The 200 by 200 playable rectangle itself consists entirely of ordinary space.
/turf/space/space_wars_boundary
	name = "edge of the Space Wars arena"
	density = TRUE

/datum/game_mode/space_wars/pre_setup()
	create_arena()
	config.allow_random_events = FALSE
	SSdirector.enabled = FALSE

/datum/game_mode/space_wars/announce()
	to_world("<B>Space Wars!</B> [extended_round_description]")

/datum/game_mode/space_wars/post_setup()
	return TRUE

/datum/game_mode/space_wars/check_finished()
	// Deaths and destroyed freighters never end this sandbox round.
	return FALSE

/datum/game_mode/space_wars/proc/create_arena()
	if(arena_z)
		return
	world.maxx = max(world.maxx, SPACE_WARS_MAP_SIZE)
	world.maxy = max(world.maxy, SPACE_WARS_MAP_SIZE)
	world.maxz++
	arena_z = world.maxz
	if(SSzcopy.zstack_maximums.len)
		SSzcopy.calculate_zstack_limits()
	arena_area = new
	GLOB.using_map.sealed_levels |= arena_z
	GLOB.using_map.player_levels |= arena_z
	for(var/turf/tile in block(locate(1, 1, arena_z), locate(SPACE_WARS_MAP_SIZE, SPACE_WARS_MAP_SIZE, arena_z)))
		arena_area.contents += tile
		CHECK_TICK
	if(world.maxx > SPACE_WARS_MAP_SIZE)
		for(var/y = 1, y <= SPACE_WARS_MAP_SIZE + (world.maxy > SPACE_WARS_MAP_SIZE), y++)
			var/turf/tile = locate(SPACE_WARS_MAP_SIZE + 1, y, arena_z)
			tile.ChangeTurf(/turf/space/space_wars_boundary)
	if(world.maxy > SPACE_WARS_MAP_SIZE)
		for(var/x = 1, x <= SPACE_WARS_MAP_SIZE, x++)
			var/turf/tile = locate(x, SPACE_WARS_MAP_SIZE + 1, arena_z)
			tile.ChangeTurf(/turf/space/space_wars_boundary)

/datum/game_mode/space_wars/proc/footprint_available(turf/origin, list/offsets)
	if(!origin || origin.z != arena_z)
		return FALSE
	for(var/coordinate in offsets)
		var/list/offset = offsets[coordinate]
		var/turf/tile = locate(origin.x + offset[1], origin.y + offset[2], arena_z)
		if(!istype(tile, /turf/space) || tile.density || get_area(tile) != arena_area)
			return FALSE
		if(tile.x <= TRANSITIONEDGE || tile.y <= TRANSITIONEDGE || tile.x > SPACE_WARS_MAP_SIZE - TRANSITIONEDGE || tile.y > SPACE_WARS_MAP_SIZE - TRANSITIONEDGE)
			return FALSE
		for(var/atom/movable/obstacle in tile)
			if(obstacle.density || ismob(obstacle) || istype(obstacle, /obj/structure/vehicleparts) || istype(obstacle, /obj/structure/bed/chair/civ13))
				return FALSE
	return TRUE

/datum/game_mode/space_wars/proc/find_spawn_turf(list/offsets)
	// Randomize the entire search, so occupied tiles cannot cause unlucky failures.
	var/list/candidates = list()
	for(var/x = TRANSITIONEDGE + 1, x <= SPACE_WARS_MAP_SIZE - TRANSITIONEDGE, x++)
		for(var/y = TRANSITIONEDGE + 1, y <= SPACE_WARS_MAP_SIZE - TRANSITIONEDGE, y++)
			candidates += (x - 1) * SPACE_WARS_MAP_SIZE + y
	while(candidates.len)
		var/index = rand(1, candidates.len)
		var/coordinate = candidates[index] - 1
		candidates[index] = candidates[candidates.len]
		candidates.len--
		var/turf/origin = locate(round(coordinate / SPACE_WARS_MAP_SIZE) + 1, (coordinate % SPACE_WARS_MAP_SIZE) + 1, arena_z)
		if(footprint_available(origin, offsets))
			return origin
		CHECK_TICK
	return null

/datum/game_mode/space_wars/proc/create_freighter()
	var/obj/effect/civ13_vehicle/spacecraft/freighter/preset = new(null, TRUE)
	var/facing = pick(GLOB.cardinal)
	var/list/offsets = preset.get_layout_offsets(facing)
	var/turf/origin = find_spawn_turf(offsets)
	if(!origin)
		qdel(preset)
		return null
	preset.forceMove(origin)
	preset.reg_number = "SW-[++freighter_serial]"
	if(!preset.assemble(facing))
		log_game("Space Wars freighter assembly failed: [preset.assembly_error]")
		qdel(preset)
		return null
	var/obj/structure/vehicleparts/axis/spacecraft/freighter/ship = locate() in origin
	return ship

// Only used to roll back an unsuccessful spawn, before the ship has a player.
/datum/game_mode/space_wars/proc/discard_freighter(obj/structure/vehicleparts/axis/spacecraft/freighter/ship)
	var/list/parts = ship.components.Copy() | ship.modules.Copy()
	for(var/obj/structure/vehicleparts/frame/frame in ship.components)
		for(var/obj/structure/bed/chair/civ13/seat in get_turf(frame))
			if(seat.vehicle_axis == ship)
				parts |= seat
	qdel(ship)
	for(var/obj/part in parts)
		qdel(part)

/datum/game_mode/space_wars/spawn_player(mob/new_player/player)
	if(!player?.client || player.spawning || GAME_STATE != RUNLEVEL_GAME)
		return FALSE
	if(!config.enter_allowed)
		to_chat(player, SPAN_WARNING("There is an administrative lock on entering the game!"))
		return FALSE
	if(!player.check_species_allowed(all_species[player.client.prefs.species]))
		return FALSE
	player.spawning = TRUE
	var/obj/structure/vehicleparts/axis/spacecraft/freighter/ship = create_freighter()
	if(!ship)
		player.spawning = FALSE
		to_chat(player, SPAN_WARNING("There is no clear space for a new freighter. Please try again shortly."))
		return FALSE
	var/obj/structure/bed/chair/civ13/driver/spacecraft/pilot_seat
	for(var/obj/structure/vehicleparts/frame/frame in ship.components)
		pilot_seat = locate() in get_turf(frame)
		if(pilot_seat && pilot_seat.vehicle_axis == ship)
			break
	if(!pilot_seat || !player.client)
		discard_freighter(ship)
		player.spawning = FALSE
		return FALSE
	var/mob/living/carbon/human/pilot = player.create_character(get_turf(pilot_seat))
	if(!pilot)
		discard_freighter(ship)
		player.spawning = FALSE
		return FALSE
	pilot.mind.assigned_role = "Freighter Captain"
	pilot.job = "Freighter Captain"
	if(!(pilot.mind in SSticker.minds))
		SSticker.minds += pilot.mind
	var/decl/hierarchy/outfit/standard_space_gear/outfit = decls_repository.get_decl(/decl/hierarchy/outfit/standard_space_gear)
	outfit.equip(pilot)
	pilot_seat.buckle_mob(pilot)
	to_chat(pilot, SPAN_NOTICE("Welcome to Space Wars! This is your freighter, [ship.reg_number]. Use the pilot seat to start its engine. W/S adjust throttle and A/D adjust heading. Use Respawn in the pig menu's ghost tab for a fresh freighter at any time after ghosting."))
	log_and_message_admins("has spawned in Space Wars aboard [ship.reg_number].", pilot)
	qdel(player)
	return TRUE

/datum/game_mode/space_wars/proc/respawn_player(mob/observer/ghost/ghost)
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

#undef SPACE_WARS_MAP_SIZE
