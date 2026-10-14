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

/datum/unit_test/spacecraft/continuous_pose
	name = "SPACECRAFT - Continuous Position, Fractional Heading and Stable Pivot"

/datum/unit_test/spacecraft/continuous_pose/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	var/start_x = ship.flight_x
	var/start_y = ship.flight_y
	var/fuel_before = ship.engine.fueltank.get_fuel_amount()
	if(!ship.set_heading(397.5) || ship.get_heading() != 37.5)
		fail("An arbitrary heading was snapped or fractional wraparound was lost.")
	for(var/i = 1 to 72)
		if(!ship.set_heading(ship.get_heading() + 5))
			fail("An unobstructed full-circle turn was rejected.")
	if(ship.get_heading() != 37.5 || ship.flight_x != start_x || ship.flight_y != start_y)
		fail("A full turn shifted the center of the even-width hull or snapped its angle.")
	if(ship.engine.fueltank.get_fuel_amount() >= fuel_before)
		fail("Continuous attitude changes did not use propellant.")
	for(var/obj/structure/vehicleparts/part in ship.modules)
		if(!part.has_operational_mount())
			fail("An arbitrary rotation displaced a component from its deck mount.")
	var/datum/spacecraft_attachment/seat_pose = ship.flight_attachments[seat]
	var/datum/spacecraft_attachment/pilot_pose = ship.flight_attachments[pilot]
	if(!pilot_pose || pilot.loc != seat.loc || pilot_pose.local_x != seat_pose.local_x || pilot_pose.local_y != seat_pose.local_y)
		fail("Rotation separated the pilot from the couch.")
	ship.set_heading(0)
	ship.set_throttle(10)
	ship.vehicle_m_delay = world.tick_lag * 4
	ship.last_vehicle_move = world.time - world.tick_lag
	ship.flight_step()
	ship.stopmovementloop()
	if(abs(ship.flight_x - start_x) > 0.001 || abs(ship.flight_y - start_y - 0.25) > 0.001)
		fail("Braking on a cardinal course snapped a quarter-tile position.")
	ship.refresh_pose()
	if(abs(ship.flight_y - start_y - 0.25) > 0.001)
		fail("Refreshing a parked hull changed its continuous position.")
	seat.unbuckle_mob()
	pilot.forceMove(locate(ship.x - 6, ship.y, ship.z))
	if(ship.flight_attachments[pilot] || !spacecraft_same_transform(pilot.transform, matrix()))
		fail("Leaving a parked off-grid hull retained the ship's transform.")
	if(!reported)
		pass("Fractional headings, stable full-circle turns, sub-tile braking and immediate disembark cleanup work.")
	cleanup_ship()
	return TRUE

/datum/unit_test/spacecraft/rotation_collision
	name = "SPACECRAFT - Swept Rotation and Unchanged Pose on Collision"

/datum/unit_test/spacecraft/rotation_collision/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	var/obj/structure/vehicleparts/frame/corner = ship.components[1]
	for(var/obj/structure/vehicleparts/frame/frame in ship.components)
		if(frame.y > corner.y || (frame.y == corner.y && frame.x > corner.x))
			corner = frame
	var/obj/test/blocker = new(get_step(corner, EAST), 1)
	blocker.density = TRUE
	blocker.anchored = TRUE
	var/old_heading = ship.get_heading()
	var/old_x = ship.flight_x
	var/old_y = ship.flight_y
	var/fuel_before = ship.engine.fueltank.get_fuel_amount()
	var/turf/old_corner_turf = get_turf(corner)
	// The northeast corner immediately sweeps east, even though its nearest
	// turf is unchanged and no cardinal-facing threshold has been crossed.
	if(ship.set_heading(old_heading + 5))
		fail("A small attitude adjustment passed its hull through a neighboring obstacle.")
	if(ship.get_heading() != old_heading || ship.flight_x != old_x || ship.flight_y != old_y || get_turf(corner) != old_corner_turf || ship.engine.fueltank.get_fuel_amount() != fuel_before)
		fail("A blocked turn changed position, heading, backing turfs or fuel.")
	qdel(blocker)
	if(!ship.set_heading(old_heading + 5))
		fail("Removing the obstacle did not restore free rotation.")
	if(!reported)
		pass("Small turns check the swept hull and blocked rotations leave the entire ship unchanged.")
	cleanup_ship()
	return TRUE

/datum/unit_test/spacecraft/synchronized_movement
	name = "SPACECRAFT - Hull Alignment at Every Gear and Glide Restoration"

/datum/unit_test/spacecraft/synchronized_movement/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	ship.set_heading(37.5)
	var/obj/item/stack/material/steel/cargo = new(get_turf(seat))
	ship.refresh_pose()
	var/datum/spacecraft_attachment/pilot_attachment = ship.flight_attachments[pilot]
	var/datum/spacecraft_attachment/cargo_attachment = ship.flight_attachments[cargo]
	var/pilot_glide = pilot_attachment.original_animate_movement
	var/cargo_glide = cargo_attachment.original_animate_movement
	// Exercise enough fractional movement to cross different turf boundaries
	// on different ticks, including at the highest forward and reverse speeds.
	for(var/gear = 1 to ship.speedlist.len)
		for(var/travel_sign in list(1, -1))
			ship.set_throttle(travel_sign * 100)
			ship.vehicle_m_delay = ship.speedlist[gear]
			for(var/i = 1 to 6)
				ship.last_vehicle_move = world.time - world.tick_lag
				if(!ship.flight_step())
					fail("Unobstructed flight failed at gear [gear].")
				for(var/atom/movable/part in ship.flight_attachments)
					if(part.animate_movement != NO_STEPS)
						fail("[part] can glide independently of the hull at gear [gear].")
					var/datum/spacecraft_attachment/attachment = ship.flight_attachments[part]
					var/list/point = ship.flight_point(attachment)
					if(part.x != round(point[1] + 0.5) || part.y != round(point[2] + 0.5))
						fail("[part] lost its world-position proxy at gear [gear].")
	ship.stopmovementloop()
	seat.unbuckle_mob()
	var/turf/outside = locate(ship.x - 6, ship.y, ship.z)
	pilot.forceMove(outside)
	cargo.forceMove(outside)
	if(pilot.animate_movement != pilot_glide || cargo.animate_movement != cargo_glide || pilot.spacecraft_carrier || cargo.spacecraft_carrier)
		fail("Disembarking did not restore ordinary crew/cargo movement settings.")
	qdel(cargo)
	if(!reported)
		pass("Hull, crew and cargo share one pose at every gear; independent gliding resumes after leaving.")
	cleanup_ship()
	return TRUE

/datum/unit_test/spacecraft/deck_walking
	name = "SPACECRAFT - Local Deck Walking, Walls and Crew Facing"

/datum/unit_test/spacecraft/deck_walking/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	ship.set_heading(37.5)
	if(pilot.SelfMove(get_step(pilot, NORTH), NORTH))
		fail("A buckled occupant could walk away from the couch.")
	seat.unbuckle_mob()
	pilot.canmove = TRUE
	var/datum/spacecraft_attachment/pose = ship.flight_attachments[pilot]
	var/obj/structure/vehicleparts/frame/from = ship.passenger_frame(pilot)
	var/start_x = pose.local_x
	var/start_y = pose.local_y
	var/local_direction
	var/obj/structure/vehicleparts/frame/target_frame
	for(var/direction in GLOB.cardinal)
		target_frame = ship.frame_at_local(start_x + (direction == EAST) - (direction == WEST), start_y + (direction == NORTH) - (direction == SOUTH))
		if(target_frame && !ship.deck_wall_blocks(from, direction) && !ship.deck_wall_blocks(target_frame, turn(direction, 180)))
			local_direction = direction
			break
	if(!local_direction)
		fail("No open adjacent scout deck cell was available.")
		cleanup_ship()
		return TRUE
	var/key_direction = turn(local_direction, -round((ship.get_heading() - ship.assembly_heading + 45) / 90) * 90)
	// Block the receiving side only: movement must check both shared borders.
	var/list/wall = target_frame.get_wall(turn(local_direction, 180))
	var/list/original_wall = wall.Copy()
	wall[3] = TRUE
	wall[5] = 100
	wall[7] = FALSE
	if(pilot.SelfMove(get_step(pilot, key_direction), key_direction) || pose.local_x != start_x || pose.local_y != start_y)
		fail("Walking passed through the closed receiving border.")
	wall[7] = TRUE
	if(!pilot.SelfMove(get_step(pilot, key_direction), key_direction) || ship.passenger_frame(pilot) != target_frame)
		fail("Opening the border did not allow a single adjacent deck step.")
	for(var/i = 1 to original_wall.len)
		wall[i] = original_wall[i]
	if(!pilot.check_solid_ground() || !pilot.Process_Spacemove(1) || pilot.inertia_dir)
		fail("An intact deck did not provide stable footing.")
	var/destination_x = pose.local_x
	var/destination_y = pose.local_y
	var/relative_facing = pose.local_facing
	// At 45 degrees, center this shared edge on a turf center so both deck
	// cells round to one turf. Walking must still change the local cell.
	ship.set_heading(45)
	var/list/from_point = ship.flight_point(ship.flight_attachments[from])
	var/list/to_point = ship.flight_point(ship.flight_attachments[target_frame])
	var/mid_x = (from_point[1] + to_point[1]) / 2
	var/mid_y = (from_point[2] + to_point[2]) / 2
	ship.try_flight_pose(ship.flight_x + round(mid_x + 0.5) - mid_x, ship.flight_y + round(mid_y + 0.5) - mid_y, 45, 0)
	var/turf/shared_turf = pilot.loc
	if(from.loc != target_frame.loc || !ship.step_on_deck(pilot, turn(local_direction, 180), FALSE) || pilot.loc != shared_turf || ship.passenger_frame(pilot) != from)
		fail("Two deck cells sharing a backing turf could not be walked between.")
	ship.step_on_deck(pilot, local_direction, FALSE)
	for(var/course in list(45, 90, 225, 359.5))
		ship.set_heading(course)
		if(pose.local_x != destination_x || pose.local_y != destination_y || pose.local_facing != relative_facing)
			fail("Turning the hull changed the passenger's local position or facing.")
		if(ship.deck_direction(SOUTH) != turn(ship.deck_direction(NORTH), 180) || ship.deck_direction(WEST) != turn(ship.deck_direction(EAST), 180))
			fail("Walking controls were not opposite at heading [course].")
	var/obj/item/stack/material/steel/cargo = new(get_turf(pilot))
	ship.refresh_pose()
	var/datum/spacecraft_attachment/cargo_pose = ship.flight_attachments[cargo]
	// Explicit local positions make the test independent of shared turf proxies.
	cargo_pose.local_x = start_x
	cargo_pose.local_y = start_y
	ship.apply_flight_pose()
	if(!ship.step_on_deck(cargo, local_direction, FALSE) || cargo_pose.local_x != destination_x || cargo_pose.local_y != destination_y)
		fail("Cargo could not follow the same local deck edge as a passenger.")
	qdel(cargo)
	pilot.forceMove(locate(ship.x - 6, ship.y, ship.z))
	if(pilot.has_spacecraft_deck() || pilot.spacecraft_carrier || !spacecraft_same_transform(pilot.transform, matrix()))
		fail("Disembarking retained deck footing or the crew transform.")
	if(!reported)
		pass("Deck walking respects shared walls, hull turns, stable footing, cargo movement and disembark cleanup.")
	cleanup_ship()
	return TRUE

/datum/unit_test/spacecraft/deck_animation
	name = "SPACECRAFT - Roof Alignment and Walking Interpolation"

/datum/unit_test/spacecraft/deck_animation/start_test()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	ship.set_heading(37.5)
	seat.unbuckle_mob()
	var/datum/spacecraft_attachment/attachment = ship.flight_attachments[pilot]
	var/obj/structure/vehicleparts/frame/from = ship.passenger_frame(pilot)
	var/step_direction
	for(var/direction in GLOB.cardinal)
		var/obj/structure/vehicleparts/frame/neighbor = ship.frame_at_local(attachment.local_x + (direction == EAST) - (direction == WEST), attachment.local_y + (direction == NORTH) - (direction == SOUTH))
		if(neighbor && !ship.deck_wall_blocks(from, direction) && !ship.deck_wall_blocks(neighbor, turn(direction, 180)))
			step_direction = direction
			break
	if(!step_direction)
		fail("No open edge was available for the walking animation test.")
		cleanup_ship()
		return TRUE
	var/list/start = ship.flight_point(attachment, TRUE)
	var/duration = 6 * world.tick_lag
	if(!ship.step_on_deck(pilot, step_direction, FALSE, duration))
		fail("An open deck step could not start its animation.")
		cleanup_ship()
		return TRUE
	var/list/first = ship.flight_point(attachment, TRUE)
	if(abs(first[1] - start[1]) > 0.001 || abs(first[2] - start[2]) > 0.001 || !(pilot in ship.deck_walkers))
		fail("Walking snapped to its destination instead of starting at the previous displayed position.")
	// Translation and rotation during a step must carry its intermediate point.
	ship.try_flight_pose(ship.flight_x + 0.25, ship.flight_y - 0.25, 112.5, 0.5)
	var/list/begin = ship.flight_point(attachment, TRUE, attachment.walk_started)
	var/list/middle = ship.flight_point(attachment, TRUE, attachment.walk_started + duration / 2)
	var/list/finish = ship.flight_point(attachment)
	if(abs(middle[1] - (begin[1] + finish[1]) / 2) > 0.001 || abs(middle[2] - (begin[2] + finish[2]) / 2) > 0.001)
		fail("A walking passenger's intermediate pose did not follow the moving, rotating hull.")
	// The timer must advance even with the engine off and no flight loop.
	ship.engine.on = FALSE
	sleep(2 * world.tick_lag)
	var/list/intermediate = attachment.visual_local()
	if((intermediate[1] == attachment.walk_from_x && intermediate[2] == attachment.walk_from_y) || (intermediate[1] == attachment.local_x && intermediate[2] == attachment.local_y))
		fail("Walking on a parked ship did not produce an intermediate frame.")
	sleep(duration)
	if((pilot in ship.deck_walkers) || attachment.walk_duration)
		fail("A completed walking animation retained its update loop entry.")
	// Roofs use their frame's transform exactly once, including after rebuilds.
	for(var/obj/structure/vehicleparts/frame/frame in ship.components)
		frame.update_icon()
	ship.refresh_pose()
	for(var/obj/structure/vehicleparts/frame/frame in ship.components)
		var/image/roof = frame.roof
		var/datum/spacecraft_attachment/frame_pose = ship.flight_attachments[frame]
		var/icon/roof_icon = icon(roof.icon)
		if(roof.loc != frame || (roof.transform && !spacecraft_same_transform(roof.transform, matrix())) || (roof.appearance_flags & RESET_TRANSFORM))
			fail("The roof did not inherit its deck's transform exactly once.")
		if(abs(roof.pixel_x + (roof_icon.Width() - frame_pose.icon_width) / 2) > 0.001 || abs(roof.pixel_y + (roof_icon.Height() - frame_pose.icon_height) / 2) > 0.001)
			fail("The roof and floor sprite centers were not aligned.")
	ship.step_on_deck(pilot, turn(step_direction, 180), FALSE, duration)
	pilot.forceMove(locate(ship.x - 6, ship.y, ship.z))
	if(pilot in ship.deck_walkers)
		fail("Leaving the ship retained a walking animation.")
	if(!reported)
		pass("Roofs inherit one aligned pose; walking interpolates on moving and parked ships and cleans up on exit.")
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
	for(var/i = 1 to 9)
		control(EAST)
	if(ship.heading != 225 || ship.dir != WEST || ship.throttle != 10)
		fail("D did not increase heading in 5-degree increments while preserving throttle.")
	for(var/i = 1 to 3)
		control(WEST)
	if(ship.heading != 210 || ship.dir != SOUTH)
		fail("A did not reduce heading and rotate the hull back.")
	ship.set_heading(0)
	control(WEST)
	if(ship.heading != 355)
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
	ship.set_heading(15)
	ship.vehicle_m_delay = world.tick_lag * 4
	var/start_x = ship.flight_x
	var/start_y = ship.flight_y
	for(var/i = 1 to 8)
		ship.last_vehicle_move = world.time - world.tick_lag
		ship.flight_step()
	if(abs(ship.flight_x - start_x - 0.517638) > 0.001 || abs(ship.flight_y - start_y - 1.931852) > 0.001)
		fail("Eight quarter-tile impulses did not follow the exact 15-degree course.")
	var/forward_x = ship.flight_x
	var/forward_y = ship.flight_y
	ship.stopmovementloop()
	ship.set_heading(0)
	ship.set_throttle(-100)
	ship.vehicle_m_delay = world.tick_lag * 4
	ship.last_vehicle_move = world.time - world.tick_lag
	ship.flight_step()
	if(abs(ship.flight_y - forward_y + 0.25) > 0.001 || abs(ship.flight_x - forward_x) > 0.001)
		fail("Reverse throttle did not travel opposite the heading.")
	cleanup_ship()
	if(!setup_ship())
		return TRUE
	ship.engine.on = TRUE
	ship.set_heading(0)
	ship.set_throttle(100)
	ship.vehicle_m_delay = world.tick_lag * 4
	// A fractional move must collide before the nearest turf changes.
	var/obj/structure/vehicleparts/frame/front = ship.components[1]
	for(var/obj/structure/vehicleparts/frame/frame in ship.components)
		if(frame.y > front.y)
			front = frame
	var/obj/test/blocker = new(get_step(front, NORTH), 1)
	blocker.density = TRUE
	blocker.anchored = TRUE
	var/turf/before_collision = get_turf(ship)
	var/before_y = ship.flight_y
	ship.last_vehicle_move = world.time - world.tick_lag
	ship.flight_step()
	if(get_turf(ship) != before_collision || ship.flight_y != before_y || ship.throttle || ship.cruise)
		fail("A sub-tile step clipped an obstacle or failed to brake on collision.")
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
