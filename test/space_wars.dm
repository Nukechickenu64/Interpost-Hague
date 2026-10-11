// Run after all game subsystems initialize, before Master enables sleep_offline.
SUBSYSTEM_DEF(space_wars_regression)
	name = "Space Wars Regression"
	init_order = -10000
	flags = SS_NO_FIRE

/datum/controller/subsystem/space_wars_regression/Initialize()
	SSticker.round_progressing = FALSE
	Master.SetRunLevel(RUNLEVEL_LOBBY)
	try
		run_space_wars_regression()
	catch(var/exception/error)
		world.log << "SPACE WARS FAIL: [error] at [error.file]:[error.line]"
	del(world)

/proc/space_wars_verify(condition, message)
	if(!condition)
		CRASH(message)

/proc/run_space_wars_regression()
	SSticker.master_mode = "space_wars"
	SSticker.bypass_captain_check = FALSE
	SSticker.setup_tick()
	space_wars_verify(istype(SSticker.mode, /datum/game_mode/space_wars), "Selected mode was replaced with Dynamic.")
	space_wars_verify(GAME_STATE == RUNLEVEL_GAME, "Space Wars could not start without a station Captain.")
	var/datum/game_mode/space_wars/mode = SSticker.mode
	space_wars_verify(mode.unrestricted_respawn && !mode.uses_station_jobs, "Space Wars spawn policy is incorrect.")
	space_wars_verify(!SSdirector.enabled && !config.allow_random_events, "Station events are still enabled.")
	space_wars_verify(mode.arena_z in GLOB.using_map.sealed_levels, "Arena is not sealed against edge travel.")
	var/tile_count = 0
	for(var/turf/tile in mode.arena_area)
		space_wars_verify(tile.type == /turf/space, "Arena contains terrain other than empty space.")
		space_wars_verify(tile.x <= 200 && tile.y <= 200, "Arena extends beyond 200 by 200.")
		for(var/atom/movable/occupant in tile)
			space_wars_verify(!ismob(occupant) && !istype(occupant, /obj/structure), "Arena started occupied.")
		tile_count++
	space_wars_verify(tile_count == 40000, "Arena does not have exactly 40,000 space tiles.")
	var/original_z = world.maxz
	mode.create_arena()
	space_wars_verify(world.maxz == original_z, "Repeated setup allocated another arena.")
	if(world.maxx > 200)
		var/turf/boundary = locate(201, 100, mode.arena_z)
		space_wars_verify(boundary.density, "East arena boundary is passable.")
	if(world.maxy > 200)
		var/turf/boundary = locate(100, 201, mode.arena_z)
		space_wars_verify(boundary.density, "North arena boundary is passable.")
	var/list/ships = list()
	var/list/occupied_tiles = list()
	var/list/registrations = list()
	for(var/i = 1, i <= 24, i++)
		var/obj/structure/vehicleparts/axis/spacecraft/freighter/ship = mode.create_freighter()
		space_wars_verify(ship && ship.components.len == 15, "Freighter did not assemble its full footprint.")
		space_wars_verify(!(ship.reg_number in registrations), "Freighters share a registration.")
		registrations += ship.reg_number
		ships += ship
		var/obj/structure/bed/chair/civ13/driver/spacecraft/pilot_seat
		for(var/obj/structure/vehicleparts/frame/frame in ship.components)
			var/turf/tile = get_turf(frame)
			space_wars_verify(get_area(tile) == mode.arena_area, "Freighter escaped the arena.")
			space_wars_verify(!(tile in occupied_tiles), "Freighters overlap.")
			occupied_tiles += tile
			space_wars_verify(tile.get_spacecraft_life_support(), "Freighter has no working life support.")
			var/obj/structure/bed/chair/civ13/driver/spacecraft/seat = locate() in tile
			if(seat)
				pilot_seat = seat
		space_wars_verify(pilot_seat && pilot_seat.vehicle_axis == ship, "Freighter has no connected pilot seat.")
		var/mob/living/carbon/human/pilot = new(get_turf(pilot_seat))
		space_wars_verify(pilot_seat.buckle_mob(pilot) && ship.driver == pilot, "Pilot cannot take control of the freighter.")
		qdel(pilot)
	var/obj/effect/civ13_vehicle/spacecraft/freighter/preset = new(null, TRUE)
	var/obj/structure/vehicleparts/axis/spacecraft/freighter/first_ship = ships[1]
	var/list/offsets = preset.get_layout_offsets(first_ship.dir)
	var/turf/origin = get_turf(first_ship)
	space_wars_verify(!mode.footprint_available(origin, offsets), "Occupied spawn was accepted.")
	space_wars_verify(!mode.footprint_available(locate(200, 200, mode.arena_z), offsets), "Out-of-bounds spawn was accepted.")
	space_wars_verify(!mode.footprint_available(locate(1, 1, mode.arena_z), offsets), "Map-edge spawn was accepted.")
	var/obj/item/edge_probe = new(locate(1, 100, mode.arena_z))
	edge_probe.touch_map_edge()
	space_wars_verify(edge_probe.z == mode.arena_z, "Arena edge leaked an object into the station map.")
	qdel(edge_probe)
	for(var/obj/structure/vehicleparts/axis/spacecraft/freighter/ship in ships)
		mode.discard_freighter(ship)
	space_wars_verify(mode.footprint_available(origin, offsets), "Failed-spawn cleanup left its footprint occupied.")
	qdel(preset)
	space_wars_verify(!mode.check_finished(), "Space Wars ends when its freighters are gone.")
	world.log << "SPACE WARS PASS: empty 200x200 arena, Captain-free round start, 24 distinct non-overlapping freighters, life support, pilot seats, collision/edge checks, and rollback cleanup."
