// Cabin protection follows the modular deck instead of changing the underlying turfs.
// This keeps moving ships from pressurizing space or leaving protection behind.
/turf/proc/get_spacecraft_life_support()
	for(var/obj/structure/vehicleparts/frame/frame in src)
		if(!frame.axis || !frame.axis.space_capable || frame.broken || !(frame in frame.axis.components))
			continue
		for(var/obj/structure/vehicleparts/life_support/unit in frame.axis.modules)
			if(unit.is_functional())
				return unit
	return null

/mob/living/proc/get_spacecraft_life_support()
	var/turf/tile = get_turf(src)
	return tile ? tile.get_spacecraft_life_support() : null

/mob/living/proc/get_environment_air()
	var/obj/structure/vehicleparts/life_support/unit = get_spacecraft_life_support()
	return unit ? unit.cabin_air : (loc ? loc.return_air() : null)

// A registered component must still be physically on its intact deck mount.
/obj/structure/vehicleparts/proc/has_operational_mount()
	if(QDELETED(src) || QDELETED(axis) || QDELETED(mount))
		return FALSE
	return (src in axis.modules) && mount.axis == axis && (mount in axis.components) && !mount.broken && isturf(loc) && loc == mount.loc

/obj/structure/vehicleparts/life_support
	name = "life support unit"
	desc = "A self-powered spacecraft cabin system providing clean air, comfortable pressure and temperature, and radiation shielding. Works with the propulsion engine off. Click to toggle; weld to repair."
	icon_state = "lid_fueltank"
	layer = OBJ_LAYER + 0.05
	var/enabled = TRUE
	var/health = 100
	var/datum/gas_mixture/cabin_air

/obj/structure/vehicleparts/life_support/New()
	..()
	cabin_air = make_air(CELL_VOLUME)

/obj/structure/vehicleparts/life_support/Destroy()
	QDEL_NULL(cabin_air)
	return ..()

/obj/structure/vehicleparts/life_support/proc/is_functional()
	return enabled && health > 0 && has_operational_mount() && axis.space_capable

/obj/structure/vehicleparts/life_support/proc/make_air(volume_needed)
	var/datum/gas_mixture/air = new(volume_needed, T20C)
	air.adjust_multi("oxygen", MOLES_O2STANDARD * volume_needed / CELL_VOLUME, "nitrogen", MOLES_N2STANDARD * volume_needed / CELL_VOLUME)
	return air

/obj/structure/vehicleparts/life_support/attack_hand(mob/user)
	if(!Adjacent(user) || user.incapacitated())
		return
	enabled = !enabled
	to_chat(user, SPAN_NOTICE("You switch [src] [enabled ? "on" : "off"]."))

/obj/structure/vehicleparts/life_support/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("Life support: [is_functional() ? "operational" : "offline"]. Integrity: [health]/[initial(health)]."))

/obj/structure/vehicleparts/life_support/attackby(obj/item/tool, mob/user)
	if(isWrench(tool) || istype(tool, /obj/item/stack/material/phoron) || istype(tool, /obj/item/reagent_containers))
		return ..()
	if(isWelder(tool))
		var/obj/item/weldingtool/welder = tool
		if(health < initial(health) && welder.isOn() && welder.remove_fuel(1, user) && do_after(user, 30, src))
			health = min(initial(health), health + 20)
		return
	if(tool.force)
		health = max(0, health - tool.force)

/obj/structure/vehicleparts/life_support/bullet_act(obj/item/projectile/projectile)
	health = max(0, health - projectile.get_structure_damage())
	return 0

/obj/structure/vehicleparts/life_support/ex_act(severity)
	health = max(0, health - (severity == 1 ? 100 : 30))

// A ship owns a continuous center and a rigid local coordinate system. Turfs
// are only spatial/interaction proxies: each part is placed on its nearest turf
// and the remainder is rendered without quantizing the ship's position or angle.
/atom/movable
	var/obj/structure/vehicleparts/axis/spacecraft/spacecraft_carrier

/datum/spacecraft_attachment
	var/local_x
	var/local_y
	var/rotates = FALSE
	var/rotation_origin = 0
	var/original_animate_movement
	var/matrix/base_transform
	var/matrix/applied_transform
	var/icon_width = 32
	var/icon_height = 32
	var/local_facing = 0
	var/rendered_dir
	var/walk_from_x = 0
	var/walk_from_y = 0
	var/walk_started = 0
	var/walk_duration = 0

// Collision and boarding use local_x/y (the accepted destination). Drawing
// moves between cells in the hull's coordinate system, including during turns.
/datum/spacecraft_attachment/proc/visual_local(at_time = world.time)
	if(walk_duration <= 0 || at_time >= walk_started + walk_duration)
		return list(local_x, local_y)
	var/fraction = clamp((at_time - walk_started) / walk_duration, 0, 1)
	return list(walk_from_x + (local_x - walk_from_x) * fraction, walk_from_y + (local_y - walk_from_y) * fraction)

/datum/spacecraft_attachment/proc/begin_deck_step(target_x, target_y, duration)
	var/list/from = visual_local()
	walk_from_x = from[1]
	walk_from_y = from[2]
	local_x = target_x
	local_y = target_y
	walk_started = world.time
	walk_duration = max(0, duration)

// Keep the normal eye and visibility origin. The unused screen-axis camera
// offsets can track the rendered position without fighting zoom/dizziness x/y.
/client
	var/spacecraft_camera_x = 0
	var/spacecraft_camera_y = 0

/client/proc/clear_spacecraft_camera()
	pixel_w -= spacecraft_camera_x
	pixel_z -= spacecraft_camera_y
	spacecraft_camera_x = 0
	spacecraft_camera_y = 0

/client/proc/update_spacecraft_camera()
	clear_spacecraft_camera()
	if(!mob || eye != mob || !mob.spacecraft_carrier)
		return
	var/obj/structure/vehicleparts/axis/spacecraft/ship = mob.spacecraft_carrier
	var/datum/spacecraft_attachment/attachment = ship.flight_attachments[mob]
	if(!attachment)
		return
	var/list/point = ship.flight_point(attachment, TRUE)
	spacecraft_camera_x = round((point[1] - mob.x) * world.icon_size, 1)
	spacecraft_camera_y = round((point[2] - mob.y) * world.icon_size, 1)
	pixel_w += spacecraft_camera_x
	pixel_z += spacecraft_camera_y

/mob/proc/has_spacecraft_deck()
	return spacecraft_carrier && spacecraft_carrier.passenger_frame(src)

/obj/structure/vehicleparts/axis/spacecraft
	var/throttle = 0
	var/heading = null // Degrees clockwise from north.
	var/flight_x = null // Hull center, in world tiles; never rounded for physics.
	var/flight_y = null
	var/assembly_heading = null // The local coordinate system and sprite facing.
	var/next_control_input = 0
	var/free_flight = TRUE
	var/applying_pose = FALSE
	var/list/flight_attachments = list()
	var/list/deck_walkers = list()
	var/deck_animation_loop_running = FALSE

/obj/structure/vehicleparts/axis/spacecraft/proc/get_heading()
	if(isnull(heading))
		heading = dir2angle(dir)
	return heading

// The legacy % operator truncates fractions before calculating the remainder.
/proc/spacecraft_normalize_heading(value)
	return value - 360 * round(value / 360)

/obj/structure/vehicleparts/axis/spacecraft/proc/flight_status()
	var/propulsion_error = get_propulsion_error()
	return "Throttle: [throttle]%. Automatic gear: [throttle ? (reverse ? "R" : "F") : "N"][currentspeed ? currentspeed : ""]. Heading: [round(get_heading(), 0.1)] degrees (0=N, 90=E). Position: [round(flight_x, 0.01)], [round(flight_y, 0.01)]. Propulsion: [propulsion_error ? propulsion_error : "Ready."]"

/obj/structure/vehicleparts/axis/spacecraft/proc/get_propulsion_error(check_fuel = TRUE)
	if(QDELETED(src) || !components.len)
		return "No attached hull."
	if(!engine || engine.axis != src || !engine.has_operational_mount())
		return "Engine missing, displaced, or mounted on a damaged deck."
	if(engine.health <= 0)
		return "Engine needs repairs."
	if(!engine.fueltank || engine.fueltank.axis != src || !engine.fueltank.has_operational_mount())
		return "Propellant tank missing, displaced, or mounted on a damaged deck."
	if(check_fuel && engine.fueltank.get_fuel_amount(engine.fuel_type) < engine.fuel_use)
		return "Insufficient propellant."
	var/thruster_count = 0
	for(var/obj/structure/vehicleparts/movement/thruster/thruster in wheels)
		if(thruster.axis == src && !thruster.broken && thruster.has_operational_mount() && thruster.mount.mwheel == thruster)
			thruster_count++
	if(thruster_count < required_thrusters)
		return "Working thrusters: [thruster_count]/[required_thrusters]. Check thrusters and their deck mounts."
	if(!engine.on)
		return "Engine is off."
	return null

/obj/structure/vehicleparts/axis/spacecraft/can_move_vehicle()
	return !get_propulsion_error(FALSE)

/obj/structure/vehicleparts/axis/spacecraft/get_transporting()
	var/list/transporting = ..()
	// Different off-grid decks can share a backing turf without overlapping.
	// Never collect occupants or loose cargo already carried by another ship.
	for(var/atom/movable/part in transporting.Copy())
		if(part.spacecraft_carrier && part.spacecraft_carrier != src)
			transporting -= part
		else if(ismob(part))
			var/mob/passenger = part
			if(istype(passenger.buckled, /obj/structure/bed/chair/civ13) && passenger.buckled:vehicle_axis != src)
				transporting -= part
	return transporting

/obj/structure/vehicleparts/axis/spacecraft/proc/initialize_flight()
	if(!free_flight || !components.len)
		return FALSE
	if(!isnull(flight_x))
		return TRUE
	var/min_x = world.maxx
	var/min_y = world.maxy
	var/max_x = 1
	var/max_y = 1
	for(var/obj/structure/vehicleparts/frame/frame in components)
		min_x = min(min_x, frame.x)
		min_y = min(min_y, frame.y)
		max_x = max(max_x, frame.x)
		max_y = max(max_y, frame.y)
	flight_x = (min_x + max_x) / 2
	flight_y = (min_y + max_y) / 2
	assembly_heading = get_heading()
	sync_attachments()
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/on_preset_assembled(list/locations)
	initialize_flight()
	return ..()

/obj/structure/vehicleparts/axis/spacecraft/proc/set_throttle(value)
	throttle = clamp(value, -100, 100)
	if(!throttle)
		stopmovementloop()
		return
	reverse = throttle < 0
	currentspeed = clamp(CEILING(abs(throttle) * min(speeds, speedlist.len) / 100, 1), 1, speedlist.len)
	vehicle_m_delay = speedlist[currentspeed]
	startmovementloop()

/obj/structure/vehicleparts/axis/spacecraft/relaymove(mob/user, direction)
	if(!can_drive(user) || !(direction in GLOB.cardinal) || world.time < next_control_input)
		return FALSE
	switch(direction)
		if(NORTH)
			set_throttle(throttle + 10)
		if(SOUTH)
			set_throttle(throttle - 10)
		if(EAST, WEST)
			if(!set_heading(get_heading() + (direction == EAST ? 5 : -5)))
				return FALSE
	next_control_input = world.time + 2
	to_chat(user, SPAN_NOTICE(flight_status()))
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/startmovementloop()
	if(!can_move_vehicle() || !initialize_flight())
		stopmovementloop()
		return
	if(!throttle)
		set_throttle(10)
		return
	cruise = TRUE
	if(movement_loop_running)
		return
	movement_loop_running = TRUE
	last_vehicle_move = world.time
	spawn()
		while(cruise && throttle && can_move_vehicle())
			sleep(world.tick_lag)
			if(cruise && throttle)
				flight_step()
		movement_loop_running = FALSE
		stopmovementloop()

// Integrate elapsed time, not whole-tile impulses. A cardinal course can stop
// between tiles just like any other course. Fuel is charged per tile traveled.
/obj/structure/vehicleparts/axis/spacecraft/proc/flight_step()
	if(!throttle || !can_move_vehicle() || !initialize_flight())
		stopmovementloop()
		return FALSE
	var/elapsed = min(world.time - last_vehicle_move, world.tick_lag)
	if(elapsed <= 0)
		return FALSE
	last_vehicle_move = world.time
	var/distance = elapsed / max(1, vehicle_m_delay)
	var/course = get_heading() + (reverse ? 180 : 0)
	if(!try_flight_pose(flight_x + sin(course) * distance, flight_y + cos(course) * distance, heading, distance))
		stopmovementloop()
		return FALSE
	if(!moving)
		moving = TRUE
		refresh_component_icons()
	refresh_pose()
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/proc/set_heading(value)
	if(!can_move_vehicle() || !initialize_flight())
		return FALSE
	value = spacecraft_normalize_heading(value)
	var/angle = spacecraft_normalize_heading(value - get_heading() + 180) - 180
	if(!angle)
		return TRUE
	// Every attitude adjustment uses fuel and the same collision checks, even
	// when it does not cross a cardinal facing or change any backing turf.
	if(!try_flight_pose(flight_x, flight_y, value, abs(angle) / 90))
		return FALSE
	last_turn = world.time
	for(var/obj/structure/vehicleparts/weapon/weapon in modules)
		weapon.aim_target = null
		weapon.clear_aim_marker()
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/proc/rotate_to(direction)
	return (direction in GLOB.cardinal) && set_heading(dir2angle(direction))

/obj/structure/vehicleparts/axis/spacecraft/turn_vehicle(direction)
	return rotate_to(direction)

// Preflight the whole swept path before moving any atom or spending propellant.
// Each interval bounds the swept translation and rotation, including between
// samples. Limit corner travel to 1/8 tile to keep angular padding small.
/obj/structure/vehicleparts/axis/spacecraft/proc/try_flight_pose(new_x, new_y, new_heading, fuel_distance)
	sync_attachments()
	var/dx = new_x - flight_x
	var/dy = new_y - flight_y
	var/angle = spacecraft_normalize_heading(new_heading - get_heading() + 180) - 180
	var/radius = 0
	for(var/obj/structure/vehicleparts/frame/frame in components)
		var/datum/spacecraft_attachment/attachment = flight_attachments[frame]
		radius = max(radius, sqrt(attachment.local_x ** 2 + attachment.local_y ** 2) + 0.707107)
	var/samples = max(1, CEILING((sqrt(dx * dx + dy * dy) + radius * abs(angle) * 0.017453293) / 0.125, 1))
	var/list/transporting = get_transporting()
	var/padding = 2 * radius * sin(abs(angle) / samples / 4)
	for(var/i = 1 to samples)
		var/fraction = (i - 0.5) / samples
		if(!flight_pose_clear(flight_x + dx * fraction, flight_y + dy * fraction, heading + angle * fraction, transporting, padding, dx / samples / 2, dy / samples / 2))
			return FALSE
	// The chassis may outlive the deck section underneath it. Validate every
	// backing location too, so a surviving attachment cannot enter nullspace or
	// trigger a space-edge transition independently of the rest of the ship.
	var/c = cos(new_heading - assembly_heading)
	var/s = sin(new_heading - assembly_heading)
	for(var/atom/movable/part in flight_attachments)
		var/datum/spacecraft_attachment/attachment = flight_attachments[part]
		var/turf/destination = locate(round(new_x + attachment.local_x * c + attachment.local_y * s + 0.5), round(new_y - attachment.local_x * s + attachment.local_y * c + 0.5), z)
		if(!destination || (istype(destination, /turf/space) && (destination.x <= TRANSITIONEDGE || destination.y <= TRANSITIONEDGE || destination.x >= world.maxx - TRANSITIONEDGE + 1 || destination.y >= world.maxy - TRANSITIONEDGE + 1)))
			return FALSE
	if(!engine.fueltank.consume_fuel(engine.fuel_use * fuel_distance, engine.fuel_type))
		engine.on = FALSE
		stopmovementloop()
		return FALSE
	flight_x = new_x
	flight_y = new_y
	heading = new_heading
	// dir remains useful to callers, but never controls layout or sprite facing.
	set_dir(angle2dir((round((heading + 45) / 90) * 90) % 360))
	apply_flight_pose()
	return TRUE

// Separating-axis test for two unit deck squares with arbitrary orientations.
// Touching edges are allowed. This also handles another freely rotated ship.
/proc/spacecraft_squares_overlap(dx, dy, angle_a, angle_b, padding = 0, sweep_x = 0, sweep_y = 0)
	var/relative = angle_b - angle_a
	var/reach = 0.5 + 0.5 * (abs(cos(relative)) + abs(sin(relative))) - 0.00001
	for(var/angle in list(angle_a, angle_b))
		var/c = cos(angle)
		var/s = sin(angle)
		if(abs(dx * c - dy * s) >= reach + padding + abs(sweep_x * c - sweep_y * s) || abs(dx * s + dy * c) >= reach + padding + abs(sweep_x * s + sweep_y * c))
			return FALSE
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/proc/flight_pose_clear(cx, cy, course, list/transporting, padding = 0, sweep_x = 0, sweep_y = 0)
	var/angle = course - assembly_heading
	var/c = cos(angle)
	var/s = sin(angle)
	var/extent = (abs(c) + abs(s)) / 2
	var/extent_x = extent + padding + abs(sweep_x)
	var/extent_y = extent + padding + abs(sweep_y)
	for(var/obj/structure/vehicleparts/frame/frame in components)
		var/datum/spacecraft_attachment/attachment = flight_attachments[frame]
		var/fx = cx + attachment.local_x * c + attachment.local_y * s
		var/fy = cy - attachment.local_x * s + attachment.local_y * c
		if(fx - extent_x < 0.5 || fy - extent_y < 0.5 || fx + extent_x > world.maxx + 0.5 || fy + extent_y > world.maxy + 0.5)
			return FALSE
		// Include nearby turf proxies of off-grid frames, whose centers may lie
		// up to half a tile away from their loc.
		for(var/tx = max(1, round(fx - extent_x - 1)) to min(world.maxx, CEILING(fx + extent_x + 1, 1)))
			for(var/ty = max(1, round(fy - extent_y - 1)) to min(world.maxy, CEILING(fy + extent_y + 1, 1)))
				var/turf/tile = locate(tx, ty, z)
				var/touches_tile = spacecraft_squares_overlap(tx - fx, ty - fy, angle, 0, padding, sweep_x, sweep_y)
				if(touches_tile && (tile.density || (istype(tile, /turf/space) && (tx <= TRANSITIONEDGE || ty <= TRANSITIONEDGE || tx >= world.maxx - TRANSITIONEDGE + 1 || ty >= world.maxy - TRANSITIONEDGE + 1))))
					return FALSE
				for(var/atom/movable/obstacle in tile)
					if(!obstacle.density || obstacle == src || (obstacle in components) || (obstacle in transporting) || (istype(obstacle, /obj/structure/vehicleparts) && obstacle:axis == src))
						continue
					if(istype(obstacle, /obj/structure/vehicleparts/frame))
						var/obj/structure/vehicleparts/frame/other_frame = obstacle
						if(istype(other_frame.axis, /obj/structure/vehicleparts/axis/spacecraft))
							var/obj/structure/vehicleparts/axis/spacecraft/other = other_frame.axis
							var/datum/spacecraft_attachment/other_attachment = other.flight_attachments[other_frame]
							if(other_attachment)
								var/list/point = other.flight_point(other_attachment)
								if(spacecraft_squares_overlap(point[1] - fx, point[2] - fy, angle, other.heading - other.assembly_heading, padding, sweep_x, sweep_y))
									return FALSE
								continue
					// Other carried atoms are covered by their ship's deck geometry.
					if(obstacle.spacecraft_carrier && obstacle.spacecraft_carrier != src && obstacle.spacecraft_carrier.flight_attachments[obstacle])
						continue
					if(touches_tile)
						return FALSE
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/proc/flight_point(datum/spacecraft_attachment/attachment, visual = FALSE, at_time = world.time)
	var/angle = get_heading() - assembly_heading
	var/list/point = visual ? attachment.visual_local(at_time) : list(attachment.local_x, attachment.local_y)
	return list(flight_x + point[1] * cos(angle) + point[2] * sin(angle), flight_y - point[1] * sin(angle) + point[2] * cos(angle))

/obj/structure/vehicleparts/axis/spacecraft/proc/stop_deck_animation(atom/movable/passenger)
	deck_walkers -= passenger
	var/datum/spacecraft_attachment/attachment = flight_attachments[passenger]
	if(attachment)
		attachment.walk_duration = 0

// A parked ship needs animation updates too. One short-lived loop per ship
// updates only walking passengers/cargo, never enabling independent hull glide.
/obj/structure/vehicleparts/axis/spacecraft/proc/start_deck_animation(atom/movable/passenger)
	deck_walkers |= passenger
	if(deck_animation_loop_running)
		return
	deck_animation_loop_running = TRUE
	spawn()
		while(!QDELETED(src) && deck_walkers.len)
			sleep(world.tick_lag)
			if(QDELETED(src))
				return
			update_deck_animations()
		deck_animation_loop_running = FALSE

/obj/structure/vehicleparts/axis/spacecraft/proc/update_deck_animations()
	for(var/atom/movable/passenger in deck_walkers.Copy())
		var/datum/spacecraft_attachment/attachment = flight_attachments[passenger]
		if(QDELETED(passenger) || !attachment || passenger.spacecraft_carrier != src)
			deck_walkers -= passenger
			continue
		render_flight_atom(passenger, attachment)
		if(world.time >= attachment.walk_started + attachment.walk_duration)
			stop_deck_animation(passenger)

/obj/structure/vehicleparts/axis/spacecraft/proc/frame_at_local(local_x, local_y)
	for(var/obj/structure/vehicleparts/frame/frame in components)
		var/datum/spacecraft_attachment/attachment = flight_attachments[frame]
		if(attachment && !frame.broken && abs(attachment.local_x - local_x) < 0.01 && abs(attachment.local_y - local_y) < 0.01)
			return frame
	return null

/obj/structure/vehicleparts/axis/spacecraft/proc/passenger_frame(atom/movable/passenger)
	var/datum/spacecraft_attachment/attachment = flight_attachments[passenger]
	if(!attachment || !isturf(passenger.loc))
		return null
	var/obj/structure/vehicleparts/frame/frame = frame_at_local(attachment.local_x, attachment.local_y)
	return frame && frame.loc == passenger.loc ? frame : null

// Use the closest visible deck axis for each movement key. All four keys use
// the same rotation, including at 45 degrees, so opposite keys remain opposites.
/obj/structure/vehicleparts/axis/spacecraft/proc/deck_direction(direction)
	return turn(direction, round((get_heading() - assembly_heading + 45) / 90) * 90)

/obj/structure/vehicleparts/axis/spacecraft/proc/deck_wall_blocks(obj/structure/vehicleparts/frame/frame, direction)
	if(!frame)
		return FALSE
	var/datum/spacecraft_attachment/attachment = flight_attachments[frame]
	direction = turn(direction, assembly_heading - attachment.rotation_origin)
	var/list/wall = frame.get_wall(direction)
	return wall && wall[3] && wall[5] > 0 && !wall[7]

// Turfs can coincide or be diagonal for adjacent deck cells. Validate the
// actual shared edge, then move the spatial proxy without native tile stepping.
/obj/structure/vehicleparts/axis/spacecraft/proc/step_on_deck(atom/movable/passenger, direction, allow_exit = TRUE, animation_duration = 0)
	var/datum/spacecraft_attachment/attachment = flight_attachments[passenger]
	var/obj/structure/vehicleparts/frame/from = passenger_frame(passenger)
	if(!from || !(direction in GLOB.cardinal) || passenger.anchored)
		return FALSE
	var/dx = (direction == EAST) - (direction == WEST)
	var/dy = (direction == NORTH) - (direction == SOUTH)
	var/target_x = attachment.local_x + dx
	var/target_y = attachment.local_y + dy
	var/obj/structure/vehicleparts/frame/target_frame = frame_at_local(target_x, target_y)
	if((!target_frame && !allow_exit) || deck_wall_blocks(from, direction) || deck_wall_blocks(target_frame, turn(direction, 180)))
		return FALSE
	var/angle = get_heading() - assembly_heading
	var/world_x = flight_x + target_x * cos(angle) + target_y * sin(angle)
	var/world_y = flight_y - target_x * sin(angle) + target_y * cos(angle)
	var/turf/destination = locate(round(world_x + 0.5), round(world_y + 0.5), z)
	// An open edge can round back onto the departing deck. Take the next
	// outside turf in that direction so disembarking cannot reattach in place.
	if(!target_frame && destination && has_frame(destination))
		destination = get_step(destination, angle2dir(spacecraft_normalize_heading(dir2angle(direction) + angle)))
		if(destination && has_frame(destination))
			return FALSE
	if(!destination || destination.density)
		return FALSE
	if(!target_frame && istype(destination, /turf/space) && (destination.x <= TRANSITIONEDGE || destination.y <= TRANSITIONEDGE || destination.x >= world.maxx - TRANSITIONEDGE + 1 || destination.y >= world.maxy - TRANSITIONEDGE + 1))
		return FALSE
	// Carried obstacles are addressed by their deck cell, never their turf.
	// Unattached world obstacles still use the normal passage checks.
	for(var/atom/movable/obstacle in (flight_attachments | destination.contents | passenger.loc.contents))
		if(obstacle == passenger || (obstacle in components) || obstacle == src)
			continue
		var/datum/spacecraft_attachment/obstacle_pose = flight_attachments[obstacle]
		if(obstacle_pose)
			if(abs(obstacle_pose.local_x - attachment.local_x) < 0.01 && abs(obstacle_pose.local_y - attachment.local_y) < 0.01 && !obstacle.CheckExit(passenger, destination))
				return FALSE
			if(abs(obstacle_pose.local_x - target_x) > 0.01 || abs(obstacle_pose.local_y - target_y) > 0.01)
				continue
		else if(obstacle.loc == passenger.loc && obstacle.loc != destination)
			if(!obstacle.CheckExit(passenger, destination))
				return FALSE
			continue
		if(!obstacle.CanPass(passenger, passenger.loc, 1))
			passenger.Bump(obstacle)
			return FALSE
	var/turf/old_loc = get_turf(passenger)
	if(!target_frame)
		detach_from_flight(passenger)
		passenger.set_dir(angle2dir(spacecraft_normalize_heading(dir2angle(direction) + angle)))
		passenger.forceMove(destination)
	else
		attachment.begin_deck_step(target_x, target_y, animation_duration)
		attachment.local_facing = dir2angle(direction)
		applying_pose = TRUE
		passenger.forceMove(destination)
		applying_pose = FALSE
		render_flight_atom(passenger, attachment)
		if(animation_duration > 0)
			start_deck_animation(passenger)
		else
			stop_deck_animation(passenger)
	passenger.move_speed = world.time - passenger.l_move_time
	passenger.l_move_time = world.time
	passenger.m_flag = 1
	passenger.last_move = angle2dir(spacecraft_normalize_heading(dir2angle(direction) + angle))
	passenger.Moved(old_loc)
	refresh_roof_visibility()
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/proc/walk_on_deck(mob/passenger, direction)
	if(passenger.buckled || !passenger.canmove || passenger.anchored || !passenger_frame(passenger))
		return FALSE
	if(passenger.restrained())
		passenger.stop_pulling()
	var/local_direction = deck_direction(direction)
	// Preserve diagonal inputs without ever cutting a closed corner.
	if(!(local_direction in GLOB.cardinal))
		var/moved = FALSE
		for(var/cardinal in GLOB.cardinal)
			if((local_direction & cardinal) && passenger_frame(passenger))
				moved = walk_on_deck(passenger, turn(cardinal, -round((get_heading() - assembly_heading + 45) / 90) * 90)) || moved
		return moved
	var/datum/spacecraft_attachment/attachment = flight_attachments[passenger]
	var/old_x = attachment.local_x
	var/old_y = attachment.local_y
	var/list/followers = list()
	if(passenger.pulling)
		followers |= passenger.pulling
	for(var/obj/item/grab/grab in passenger)
		if(grab.affecting)
			followers |= grab.affecting
		if(passenger.client)
			passenger.client.move_delay = max(passenger.client.move_delay, world.time + grab.grab_slowdown())
	var/animation_duration = passenger.client ? passenger.client.move_delay - world.time : passenger.get_move_intent_delay()
	animation_duration = max(world.tick_lag * 2, animation_duration)
	if(!step_on_deck(passenger, local_direction, TRUE, animation_duration))
		return FALSE
	// Pull cargo/crew into the cell just vacated, using the same edge checks.
	for(var/atom/movable/follower in followers)
		var/datum/spacecraft_attachment/follower_pose = flight_attachments[follower]
		if(!follower_pose || follower.anchored || (ismob(follower) && follower:buckled))
			continue
		var/fdx = old_x - follower_pose.local_x
		var/fdy = old_y - follower_pose.local_y
		if(abs(fdx) + abs(fdy) != 1)
			continue
		step_on_deck(follower, fdx ? (fdx > 0 ? EAST : WEST) : (fdy > 0 ? NORTH : SOUTH), FALSE, animation_duration)
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/proc/attach_to_flight(atom/movable/part)
	if(flight_attachments[part])
		return
	var/datum/spacecraft_attachment/attachment = new
	var/angle = get_heading() - assembly_heading
	var/dx = part.x - flight_x
	var/dy = part.y - flight_y
	attachment.local_x = dx * cos(angle) - dy * sin(angle)
	attachment.local_y = dx * sin(angle) + dy * cos(angle)
	attachment.rotates = part == src || (part in components) || (part in modules) || (istype(part, /obj/structure/bed/chair/civ13) && part:vehicle_axis == src)
	attachment.rotation_origin = dir2angle(dir)
	attachment.local_facing = dir2angle(deck_direction(part.dir))
	attachment.rendered_dir = part.dir
	attachment.original_animate_movement = part.animate_movement
	// Turf changes are bookkeeping, not independent movements. Native gliding
	// lags those changes behind our matrix offsets, pulling the hull apart at
	// speed. All carried atoms must display the authoritative pose together.
	part.animate_movement = NO_STEPS
	attachment.base_transform = matrix(part.transform)
	if(part.icon)
		var/icon/dimensions = icon(part.icon)
		attachment.icon_width = dimensions.Width()
		attachment.icon_height = dimensions.Height()
	// Mounted components and seated crew must share the exact deck coordinate,
	// including when two rotated deck centers have the same nearest turf.
	var/atom/movable/mounting
	if(istype(part, /obj/structure/vehicleparts) && part:mount)
		mounting = part:mount
	else if(ismob(part) && part:buckled && flight_attachments[part:buckled])
		mounting = part:buckled
	else if(!(part in components) && part != src)
		for(var/obj/structure/vehicleparts/frame/frame in components)
			if(frame.loc == part.loc)
				mounting = frame
				break
	var/datum/spacecraft_attachment/mount_pose = flight_attachments[mounting]
	if(mount_pose)
		attachment.local_x = mount_pose.local_x
		attachment.local_y = mount_pose.local_y
	flight_attachments[part] = attachment
	part.spacecraft_carrier = src
	if(ismob(part))
		var/mob/passenger = part
		passenger.inertia_dir = 0
		passenger.update_floating()
	GLOB.moved_event.register(part, src, /obj/structure/vehicleparts/axis/spacecraft/proc/flight_atom_moved)

/obj/structure/vehicleparts/axis/spacecraft/proc/detach_from_flight(atom/movable/part)
	var/datum/spacecraft_attachment/attachment = flight_attachments[part]
	if(!attachment)
		return
	stop_deck_animation(part)
	GLOB.moved_event.unregister(part, src, /obj/structure/vehicleparts/axis/spacecraft/proc/flight_atom_moved)
	if(part.spacecraft_carrier == src)
		part.spacecraft_carrier = null
	if(ismob(part) && part:client)
		var/mob/passenger = part
		passenger.client.clear_spacecraft_camera()
	if(!QDELETED(part))
		part.animate_movement = attachment.original_animate_movement
		if(!attachment.applied_transform || spacecraft_same_transform(part.transform, attachment.applied_transform))
			part.transform = attachment.base_transform
		if(istype(part, /obj/structure/vehicleparts/frame))
			var/obj/structure/vehicleparts/frame/frame = part
			if(frame.roof)
				frame.roof.transform = null
		if(istype(part, /obj/structure/vehicleparts/weapon))
			var/obj/structure/vehicleparts/weapon/weapon = part
			if(weapon.exterior_image)
				weapon.exterior_image.transform = null
	flight_attachments -= part
	qdel(attachment)

// Independent movement (walking, picking up cargo, displacing a module) drops
// the old pose immediately, even while parked. Deck entry adds the new pose.
/obj/structure/vehicleparts/axis/spacecraft/proc/flight_atom_moved(atom/movable/part, atom/old_loc, atom/new_loc)
	if(applying_pose)
		return
	detach_from_flight(part)
	refresh_pose()

/obj/structure/vehicleparts/axis/spacecraft/proc/sync_attachments()
	var/list/aboard = components | get_transporting()
	aboard |= src
	for(var/atom/movable/part in flight_attachments.Copy())
		if(QDELETED(part) || !(part in aboard))
			detach_from_flight(part)
	// Attach frames before mounted hardware, seats before their occupants.
	for(var/obj/structure/vehicleparts/frame/frame in components)
		attach_to_flight(frame)
	for(var/atom/movable/part in aboard)
		if(!ismob(part))
			attach_to_flight(part)
	for(var/mob/passenger in aboard)
		attach_to_flight(passenger)

/proc/spacecraft_same_transform(matrix/a, matrix/b)
	return a && b && a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d && a.e == b.e && a.f == b.f

/obj/structure/vehicleparts/axis/spacecraft/proc/render_flight_atom(atom/movable/part, datum/spacecraft_attachment/attachment)
	var/list/point = flight_point(attachment, TRUE)
	var/angle = attachment.rotates ? get_heading() - (part == src ? dir2angle(dir) : attachment.rotation_origin) : 0
	if(ismob(part))
		var/mob/passenger = part
		var/hull_angle = get_heading() - assembly_heading
		if(passenger.dir != attachment.rendered_dir)
			attachment.local_facing = dir2angle(deck_direction(passenger.dir))
		var/datum/spacecraft_attachment/seat_pose = flight_attachments[passenger.buckled]
		if(seat_pose)
			attachment.local_facing = dir2angle(passenger.buckled.dir) + assembly_heading - seat_pose.rotation_origin
		var/world_facing = attachment.local_facing + hull_angle
		var/world_dir = angle2dir(spacecraft_normalize_heading(round((world_facing + 45) / 90) * 90))
		if(passenger.dir != world_dir)
			passenger.dir = world_dir
			passenger.update_vision_cone()
		attachment.rendered_dir = passenger.dir
		angle = world_facing - dir2angle(passenger.dir)
	// Preserve transformations made by other systems (e.g. lying down).
	if(attachment.applied_transform && !spacecraft_same_transform(part.transform, attachment.applied_transform))
		attachment.base_transform = matrix(part.transform)
	var/matrix/pose = matrix(attachment.base_transform)
	pose.Turn(angle)
	var/offset_x = part.pixel_x + (attachment.icon_width - world.icon_size) / 2
	var/offset_y = part.pixel_y + (attachment.icon_height - world.icon_size) / 2
	pose.Translate((point[1] - part.x) * world.icon_size + offset_x * cos(angle) + offset_y * sin(angle) - offset_x, (point[2] - part.y) * world.icon_size - offset_x * sin(angle) + offset_y * cos(angle) - offset_y)
	part.transform = pose
	attachment.applied_transform = matrix(pose)
	if(ismob(part) && part:client)
		var/mob/passenger = part
		passenger.client.update_spacecraft_camera()
	if(istype(part, /obj/structure/vehicleparts/frame))
		var/obj/structure/vehicleparts/frame/frame = part
		if(frame.roof)
			// Images attached to the frame already inherit its complete pose.
			// Applying it again rotates/translates the roof away from the deck.
			frame.roof.transform = null
	if(istype(part, /obj/structure/vehicleparts/weapon))
		var/obj/structure/vehicleparts/weapon/weapon = part
		if(weapon.exterior_image)
			weapon.exterior_image.transform = null

/obj/structure/vehicleparts/axis/spacecraft/proc/apply_flight_pose()
	applying_pose = TRUE
	for(var/atom/movable/part in flight_attachments)
		var/datum/spacecraft_attachment/attachment = flight_attachments[part]
		var/list/point = flight_point(attachment)
		part.animate_movement = NO_STEPS
		// DM round() floors; adding 0.5 selects the nearest turf symmetrically.
		part.forceMove(locate(round(point[1] + 0.5), round(point[2] + 0.5), z))
	for(var/atom/movable/part in flight_attachments)
		render_flight_atom(part, flight_attachments[part])
	applying_pose = FALSE
	refresh_roof_visibility()

/obj/structure/vehicleparts/axis/spacecraft/refresh_pose()
	if(!free_flight || isnull(flight_x) || applying_pose || QDELETED(src))
		return
	sync_attachments()
	for(var/atom/movable/part in flight_attachments)
		render_flight_atom(part, flight_attachments[part])

/obj/structure/vehicleparts/axis/spacecraft/process()
	. = ..()
	refresh_pose()

/obj/structure/vehicleparts/axis/spacecraft/stopmovementloop()
	throttle = 0
	reverse = FALSE
	. = ..()
	refresh_pose()

/obj/structure/vehicleparts/axis/spacecraft/remove_component(obj/structure/vehicleparts/part)
	detach_from_flight(part)
	. = ..()
	refresh_pose()

/obj/structure/vehicleparts/axis/spacecraft/Destroy()
	applying_pose = TRUE
	for(var/atom/movable/part in flight_attachments.Copy())
		detach_from_flight(part)
	return ..()
