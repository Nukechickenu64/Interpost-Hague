/datum/unit_test/spacecraft
	name = "SPACECRAFT template"
	var/obj/structure/vehicleparts/axis/spacecraft/ship
	var/obj/structure/bed/chair/civ13/driver/seat
	var/mob/living/carbon/human/pilot

/datum/unit_test/spacecraft/proc/setup_ship()
	var/turf/origin
	for(var/turf/space/candidate in world)
		if(candidate.x <= TRANSITIONEDGE + 12 || candidate.y <= TRANSITIONEDGE + 12 || candidate.x >= world.maxx - TRANSITIONEDGE - 12 || candidate.y >= world.maxy - TRANSITIONEDGE - 12)
			continue
		var/clear = TRUE
		for(var/turf/tile in trange(12, candidate))
			if(!istype(tile, /turf/space))
				clear = FALSE
				break
			for(var/atom/movable/occupant in tile)
				if(!istype(occupant, /atom/movable/lighting_overlay))
					clear = FALSE
					break
			if(!clear)
				break
		if(clear)
			origin = candidate
			break
	if(!origin)
		fail("No clear space region is available for spacecraft tests.")
		return FALSE
	var/obj/effect/civ13_vehicle/spacecraft/scout/preset = new(origin, TRUE)
	if(!preset.assemble(SOUTH))
		fail("Scout assembly failed: [preset.assembly_error]")
		qdel(preset)
		return FALSE
	ship = locate() in origin
	for(var/obj/structure/bed/chair/civ13/driver/candidate in ship.get_transporting())
		seat = candidate
		break
	pilot = new(get_turf(seat))
	seat.buckle_mob(pilot)
	return TRUE

/datum/unit_test/spacecraft/proc/cleanup_ship()
	if(ship)
		var/list/parts = ship.get_transporting() | ship.components
		qdel(ship)
		for(var/atom/movable/part in parts)
			qdel(part)
	QDEL_NULL(pilot)
	ship = null
	seat = null

/datum/unit_test/spacecraft/proc/control(direction)
	ship.next_control_input = 0
	ship.last_turn = -100
	return seat.relaymove(pilot, direction)

/datum/unit_test/spacecraft/cabin
	name = "SPACECRAFT - Cabin Protection and Life Support Failure"

/datum/unit_test/spacecraft/cabin/start_test()
	if(!setup_ship())
		return TRUE
	var/obj/structure/vehicleparts/life_support/unit = pilot.get_spacecraft_life_support()
	if(!unit || ship.engine.on)
		fail("The preset did not provide functioning life support with its engine off.")
		cleanup_ship()
		return TRUE
	var/turf/cabin_tile = get_turf(pilot)
	for(var/i = 1 to 10)
		pilot.breathe()
		pilot.handle_environment(pilot.get_environment_air())
	if(pilot.failed_last_breath || pilot.getOxyLoss() || pilot.getBruteLoss() || pilot.getFireLoss() || pilot.pressure_alert)
		fail("An unsuited occupant suffered breathing, pressure or temperature effects inside the cabin.")
	if(SSradiation.get_rads_at_turf(cabin_tile))
		fail("Cabin shielding did not block cosmic radiation.")
	seat.unbuckle_mob()
	if(pilot.get_spacecraft_life_support() != unit)
		fail("Leaving the seat removed cabin protection.")
	var/turf/outside = locate(ship.x - 4, ship.y, ship.z)
	pilot.forceMove(outside)
	if(pilot.get_spacecraft_life_support() || !SSradiation.get_rads_at_turf(outside))
		fail("Cabin protection extended outside the ship.")
	pilot.forceMove(cabin_tile)
	unit.enabled = FALSE
	var/datum/gas_mixture/environment = pilot.get_environment_air()
	var/datum/gas_mixture/breath = pilot.get_breath_from_environment()
	if(pilot.get_spacecraft_life_support() || (breath && breath.total_moles) || environment.get_tile_moles() || !SSradiation.get_rads_at_turf(cabin_tile))
		fail("Disabling life support did not restore vacuum and radiation exposure.")
	qdel(breath)
	unit.enabled = TRUE
	unit.health = 0
	if(pilot.get_spacecraft_life_support())
		fail("A destroyed life support unit still protected occupants.")
	unit.health = initial(unit.health)
	if(pilot.get_spacecraft_life_support() != unit)
		fail("Repairing the unit did not restore cabin protection.")
	unit.mount.broken = TRUE
	if(pilot.get_spacecraft_life_support())
		fail("Life support operated on a broken mount.")
	unit.mount.broken = FALSE
	ship.remove_component(unit)
	if(pilot.get_spacecraft_life_support())
		fail("An uninstalled unit still provided cabin protection.")
	qdel(unit)
	if(!reported)
		pass("Unsuited seated and standing occupants are protected only by installed, enabled, intact life support.")
	cleanup_ship()
	return TRUE

/datum/unit_test/spacecraft/controls
	name = "SPACECRAFT - Signed Throttle, Automatic Gears and Heading"

/datum/unit_test/spacecraft/controls/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	for(var/i = 1 to 10)
		control(NORTH)
	if(ship.throttle != 100 || ship.reverse || ship.currentspeed != ship.speeds || ship.get_heading() != 180)
		fail("W did not select full forward throttle and the highest automatic gear facing south.")
	control(NORTH)
	if(ship.throttle != 100)
		fail("Forward throttle exceeded its limit.")
	for(var/i = 1 to 10)
		control(SOUTH)
	if(ship.throttle || ship.cruise || ship.currentspeed)
		fail("Reducing throttle to zero did not select neutral and stop.")
	control(SOUTH)
	if(ship.throttle != -10 || !ship.reverse || ship.currentspeed != 1)
		fail("S below zero did not automatically select reverse.")
	control(NORTH)
	control(NORTH)
	if(ship.throttle != 10 || ship.reverse)
		fail("W did not pass from reverse through neutral into forward.")
	for(var/i = 1 to 3)
		control(EAST)
	if(ship.heading != 225 || ship.dir != WEST || ship.throttle != 10)
		fail("D did not increase heading in 15-degree increments while preserving throttle.")
	control(WEST)
	if(ship.heading != 210 || ship.dir != SOUTH)
		fail("A did not reduce heading and rotate the hull back.")
	ship.heading = 0
	ship.set_dir(NORTH)
	control(WEST)
	if(ship.heading != 345)
		fail("Heading did not wrap below zero.")
	control(EAST)
	if(ship.heading != 0)
		fail("Heading did not wrap past 360 degrees.")
	seat.unbuckle_mob()
	if(control(SOUTH) || ship.throttle != 10)
		fail("An unbuckled pilot could change flight controls.")
	if(!reported)
		pass("Throttle crosses zero in both directions, gears are automatic, and A/D adjust a wrapped heading.")
	cleanup_ship()
	return TRUE

/datum/unit_test/spacecraft/unattended
	name = "SPACECRAFT - Unattended Flight Carries Occupants and Cabin Protection"

/datum/unit_test/spacecraft/unattended/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	control(NORTH)
	seat.unbuckle_mob()
	var/turf/origin = get_turf(ship)
	var/turf/old_pilot_tile = get_turf(pilot)
	var/fuel_before = ship.engine.fueltank.get_fuel_amount()
	var/deadline = world.time + 4 SECONDS
	while(get_turf(ship) == origin && world.time < deadline)
		sleep(1)
	if(get_turf(ship) == origin || ship.driver || ship.throttle != 10 || !ship.cruise)
		fail("The spacecraft stopped or lost throttle after the pilot left the seat.")
	if(get_turf(pilot) == old_pilot_tile || !ship.has_frame(get_turf(pilot)) || !pilot.get_spacecraft_life_support())
		fail("An unbuckled occupant or cabin protection did not move with the ship.")
	if(ship.engine.fueltank.get_fuel_amount() >= fuel_before)
		fail("Unattended propulsion did not consume fuel.")
	ship.stopmovementloop()
	var/turf/stopped_at = get_turf(ship)
	sleep(ship.vehicle_m_delay + 1)
	if(get_turf(ship) != stopped_at || ship.throttle || ship.moving || ship.cruise)
		fail("The brake did not stop unattended flight.")
	if(!reported)
		pass("Flight persists without a driver, carries standing occupants, uses fuel, and stops on braking.")
	cleanup_ship()
	return TRUE

/datum/unit_test/spacecraft/flight_safety
	name = "SPACECRAFT - Angled Travel, Reverse and Propulsion Safety"

/datum/unit_test/spacecraft/flight_safety/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	ship.set_throttle(100)
	ship.heading = 15
	var/start_x = ship.x
	var/start_y = ship.y
	for(var/i = 1 to 8)
		ship.last_vehicle_move = -100
		ship.flight_step()
	if(ship.x != start_x + 2 || ship.y != start_y + 8)
		fail("A 15-degree course did not accumulate fractional tile movement correctly.")
	var/turf/forward_end = get_turf(ship)
	ship.stopmovementloop()
	ship.heading = 0
	ship.set_throttle(-100)
	ship.last_vehicle_move = -100
	ship.flight_step()
	if(ship.y != forward_end.y - 1 || ship.x != forward_end.x)
		fail("Reverse throttle did not travel opposite the heading.")
	ship.stopmovementloop()
	ship.set_throttle(100)
	ship.heading = 315
	// Block only the west intermediate footprint of a northwest step.
	var/obj/structure/vehicleparts/frame/front = ship.components[1]
	for(var/obj/structure/vehicleparts/frame/frame in ship.components)
		if(frame.x < front.x || (frame.x == front.x && frame.y < front.y))
			front = frame
	var/obj/test/blocker = new(get_step(front, WEST), 1)
	blocker.density = TRUE
	blocker.anchored = TRUE
	var/turf/before_collision = get_turf(ship)
	ship.last_vehicle_move = -100
	ship.flight_step()
	if(get_turf(ship) != before_collision || ship.throttle || ship.cruise)
		fail("An angled step clipped an obstacle or failed to brake on collision.")
	qdel(blocker)
	ship.engine.fueltank.reagents.clear_reagents()
	ship.set_throttle(100)
	ship.last_vehicle_move = -100
	ship.flight_step()
	if(ship.engine.on || ship.throttle || ship.cruise || get_turf(ship) != before_collision)
		fail("Running out of fuel did not shut down propulsion and stop the ship.")
	ship.engine.fueltank.reagents.add_reagent(/datum/reagent/fuel, 10)
	ship.engine.on = TRUE
	var/obj/structure/vehicleparts/movement/thruster/thruster = ship.wheels[1]
	thruster.broken = TRUE
	ship.set_throttle(100)
	if(ship.throttle || ship.can_move_vehicle())
		fail("A spacecraft without enough working thrusters could keep moving.")
	if(!reported)
		pass("Angled and reverse travel honor collisions, fuel exhaustion and thruster failure.")
	cleanup_ship()
	return TRUE
