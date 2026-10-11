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

/obj/structure/vehicleparts/axis/spacecraft
	// Throttle is signed: crossing zero automatically switches forward/reverse.
	var/throttle = 0
	var/heading = null // Degrees clockwise from north; initialized from the assembled direction.
	var/travel_offset_x = 0
	var/travel_offset_y = 0
	var/next_control_input = 0

/obj/structure/vehicleparts/axis/spacecraft/proc/get_heading()
	if(isnull(heading))
		heading = dir2angle(dir)
	return heading

/obj/structure/vehicleparts/axis/spacecraft/proc/flight_status()
	var/propulsion_error = get_propulsion_error()
	return "Throttle: [throttle]%. Automatic gear: [throttle ? (reverse ? "R" : "F") : "N"][currentspeed ? currentspeed : ""]. Heading: [get_heading()] degrees (0=N, 90=E). Propulsion: [propulsion_error ? propulsion_error : "Ready."]"

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
	// The movement step consumes fuel and shuts the engine down on exhaustion.
	return !get_propulsion_error(FALSE)

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
	get_heading()
	switch(direction)
		if(NORTH) // W / up
			set_throttle(throttle + 10)
		if(SOUTH) // S / down
			set_throttle(throttle - 10)
		if(EAST, WEST) // D / A steer independently of the current facing.
			var/new_heading = (heading + (direction == EAST ? 15 : -15) + 360) % 360
			// Sprites and modular borders use cardinal facings; travel uses the exact heading.
			var/new_direction = angle2dir((round((new_heading + 45) / 90) * 90) % 360)
			if(new_direction != dir && !turn_vehicle(new_direction))
				return FALSE
			heading = new_heading
	next_control_input = world.time + 2
	to_chat(user, SPAN_NOTICE(flight_status()))
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/startmovementloop()
	if(!can_move_vehicle())
		stopmovementloop()
		return
	if(!throttle)
		set_throttle(10)
		return
	cruise = TRUE
	if(movement_loop_running)
		return
	movement_loop_running = TRUE
	spawn()
		while(cruise && throttle && can_move_vehicle())
			flight_step()
			sleep(max(1, vehicle_m_delay))
		movement_loop_running = FALSE
		stopmovementloop()

/obj/structure/vehicleparts/axis/spacecraft/proc/flight_step()
	if(!throttle || !can_move_vehicle())
		stopmovementloop()
		return FALSE
	if(world.time < last_vehicle_move + vehicle_m_delay)
		return FALSE
	// Accumulate fractional tile travel so 15-degree courses remain distinct and
	// diagonals do not gain speed compared to cardinal courses.
	var/travel_heading = get_heading() + (reverse ? 180 : 0)
	travel_offset_x += sin(travel_heading)
	travel_offset_y += cos(travel_heading)
	var/step_x = round(travel_offset_x + 0.5)
	var/step_y = round(travel_offset_y + 0.5)
	travel_offset_x -= step_x
	travel_offset_y -= step_y
	if(!step_x && !step_y)
		return TRUE
	var/direction = (step_x > 0 ? EAST : (step_x < 0 ? WEST : 0)) | (step_y > 0 ? NORTH : (step_y < 0 ? SOUTH : 0))
	return move_vehicle(direction)

/obj/structure/vehicleparts/axis/spacecraft/stopmovementloop()
	throttle = 0
	reverse = FALSE
	travel_offset_x = 0
	travel_offset_y = 0
	return ..()
