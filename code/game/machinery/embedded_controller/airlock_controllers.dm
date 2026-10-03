//base type for controllers of two-door systems
/obj/machinery/embedded_controller/radio/airlock
	// Setup parameters only
	radio_filter = RADIO_AIRLOCK
	var/tag_exterior_door
	var/tag_interior_door
	var/tag_airpump
	var/tag_chamber_sensor
	var/tag_exterior_sensor
	var/tag_interior_sensor
	var/tag_airlock_mech_sensor
	var/tag_shuttle_mech_sensor
	var/tag_secure = 0
	var/list/dummy_terminals = list()
	var/cycle_to_external_air = 0

/obj/machinery/embedded_controller/radio/airlock/New()
	..()
	program = new/datum/computer/file/embedded_program/airlock(src)

/obj/machinery/embedded_controller/radio/airlock/Destroy()
	for(var/thing in dummy_terminals)
		var/obj/machinery/dummy_airlock_controller/dummy = thing
		dummy.master_controller = null
	dummy_terminals.Cut()
	return ..()

/obj/machinery/embedded_controller/radio/airlock/CanUseTopic(var/mob/user)
	if(!allowed(user))
		return min(STATUS_UPDATE, ..())
	else
		return ..()

//Advanced airlock controller for when you want a more versatile airlock controller - useful for turning simple access control rooms into airlocks
/obj/machinery/embedded_controller/radio/airlock/advanced_airlock_controller
	name = "Advanced Airlock Controller"

//Airlock controller for airlock control - most airlocks on the station use this
/obj/machinery/embedded_controller/radio/airlock/airlock_controller
	name = "Airlock Controller"
	tag_secure = 1

/obj/machinery/embedded_controller/radio/airlock/ui_interact()
	return

/obj/machinery/embedded_controller/radio/airlock/proc/get_airlock_program()
	return program

/obj/machinery/embedded_controller/radio/airlock/proc/manual_cycle_enabled()
	return TRUE

/obj/machinery/embedded_controller/radio/airlock/proc/start_manual_cycle(datum/computer/file/embedded_program/airlock/chamber_program, cycle_out)
	if(cycle_out)
		chamber_program.begin_cycle_out()
	else
		chamber_program.begin_cycle_in()
	chamber_program.memory["processing"] = TRUE

/obj/machinery/embedded_controller/radio/airlock/proc/cycle_on_click(mob/user)
	if(!user || !allowed(user))
		if(user)
			to_chat(user, "<span class='warning'>Access denied.</span>")
		return FALSE
	if(!on || !operable() || user.stat || user.lying || !user.IsAdvancedToolUser())
		return FALSE
	var/datum/computer/file/embedded_program/airlock/chamber_program = get_airlock_program()
	if(!chamber_program || !manual_cycle_enabled())
		to_chat(user, "<span class='warning'>The airlock is under docking control.</span>")
		return FALSE
	if(!chamber_program.done_cycling())
		to_chat(user, "<span class='warning'>The airlock is already cycling.</span>")
		return FALSE
	start_manual_cycle(chamber_program, chamber_program.memory["interior_status"]["state"] == "open")
	update_icon()
	return TRUE

/obj/machinery/embedded_controller/radio/airlock/attack_hand(mob/user)
	if(CanUseTopic(user, GLOB.default_state) != STATUS_INTERACTIVE)
		return FALSE
	return cycle_on_click(user)

/obj/machinery/embedded_controller/radio/airlock/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/embedded_controller/radio/airlock/Topic(href, href_list)
	return STATUS_CLOSE

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/LateInitialize()
	. = ..()
	for(var/obj/effect/landmark/airlock_link/link_marker in range(4, src))
		if(get_area(link_marker) == get_area(src))
			return
	var/obj/effect/landmark/airlock_link/generated_marker = new(get_turf(src))
	generated_marker.dir = dir
	generated_marker.link_airlock_components()

/obj/effect/landmark/airlock_link
	name = "airlock link marker"
	desc = "Automatically links a nearby full-room airlock. Face this marker toward the exterior door."
	var/search_radius = 4

/obj/effect/landmark/airlock_link/Initialize()
	. = ..()
	icon_state = "x2"
	invisibility = 101

/obj/effect/landmark/airlock_link/LateInitialize()
	. = ..()
	link_airlock_components()

/obj/effect/landmark/airlock_link/proc/link_airlock_components()
	var/obj/machinery/embedded_controller/radio/airlock/airlock_controller/controller
	var/obj/machinery/airlock_sensor/chamber_sensor
	var/obj/machinery/atmospherics/air_pump
	var/obj/machinery/door/airlock/exterior_door
	var/obj/machinery/door/airlock/interior_door
	var/list/nearby_doors = list()
	for(var/obj/machinery/embedded_controller/radio/airlock/airlock_controller/C in range(search_radius, src))
		if(C.z == z && get_area(C) == get_area(src))
			if(controller)
				log_error("Airlock link marker at [x],[y],[z] found multiple full-room controllers.")
				return
			controller = C
	if(!controller)
		log_error("Airlock link marker at [x],[y],[z] has no full-room controller nearby.")
		return
	for(var/obj/machinery/airlock_sensor/S in range(search_radius, src))
		if(S.z == z && get_area(S) == get_area(src))
			if(chamber_sensor)
				log_error("Airlock link marker at [x],[y],[z] found multiple chamber sensors.")
				return
			chamber_sensor = S
	for(var/obj/machinery/atmospherics/P in range(search_radius, src))
		if((istype(P, /obj/machinery/atmospherics/binary/pump) || istype(P, /obj/machinery/atmospherics/unary/vent_pump)) && P.z == z && get_area(P) == get_area(src))
			var/pump_matches_legacy_tag = (istype(P, /obj/machinery/atmospherics/binary/pump) && P:id == controller.tag_airpump) || (istype(P, /obj/machinery/atmospherics/unary/vent_pump) && P:id_tag == controller.tag_airpump)
			if(controller && controller.tag_airpump && !pump_matches_legacy_tag)
				continue
			if(air_pump)
				log_error("Airlock link marker at [x],[y],[z] found multiple air pumps.")
				return
			air_pump = P
	for(var/obj/machinery/door/airlock/D in range(search_radius, src))
		if(D.z == z && get_area(D) == get_area(src))
			nearby_doors += D
	if(!chamber_sensor || !air_pump || nearby_doors.len != 2)
		log_error("Airlock link marker at [x],[y],[z] requires one controller, one chamber sensor, one air pump, and exactly two airlocks.")
		return

	for(var/obj/machinery/door/airlock/D in nearby_doors)
		if(controller.tag_exterior_door)
			if(D.id_tag == controller.tag_exterior_door)
				exterior_door = D
			else
				interior_door = D
		else if(get_dir(src, D) & dir)
			exterior_door = D
		else
			interior_door = D
	if(!exterior_door || !interior_door)
		log_error("Airlock link marker at [x],[y],[z] must face one of its two airlock doors.")
		return

	var/link_id = "AIRLOCK_[sequential_id(/obj/effect/landmark/airlock_link)]"
	var/airlock_frequency = controller.frequency
	controller.id_tag = link_id
	controller.tag_exterior_door = "[link_id]_outer"
	controller.tag_interior_door = "[link_id]_inner"
	controller.tag_airpump = "[link_id]_pump"
	controller.tag_chamber_sensor = "[link_id]_sensor"
	controller.tag_exterior_sensor = null
	controller.tag_interior_sensor = null
	var/datum/computer/file/embedded_program/airlock/airlock_program = controller.program
	if(!airlock_program)
		log_error("Airlock link marker at [x],[y],[z] found a controller without an airlock program.")
		return
	airlock_program.id_tag = link_id
	airlock_program.tag_exterior_door = controller.tag_exterior_door
	airlock_program.tag_interior_door = controller.tag_interior_door
	airlock_program.tag_airpump = controller.tag_airpump
	airlock_program.tag_chamber_sensor = controller.tag_chamber_sensor
	airlock_program.tag_exterior_sensor = null
	airlock_program.tag_interior_sensor = null
	if(controller.frequency != airlock_frequency)
		controller.set_frequency(airlock_frequency)

	exterior_door.id_tag = controller.tag_exterior_door
	exterior_door.set_frequency(airlock_frequency)
	interior_door.id_tag = controller.tag_interior_door
	interior_door.set_frequency(airlock_frequency)
	chamber_sensor.id_tag = controller.tag_chamber_sensor
	chamber_sensor.set_frequency(airlock_frequency, RADIO_AIRLOCK)
	if(istype(air_pump, /obj/machinery/atmospherics/binary/pump))
		var/obj/machinery/atmospherics/binary/pump/binary_pump = air_pump
		binary_pump.id = controller.tag_airpump
		binary_pump.set_frequency(airlock_frequency, RADIO_AIRLOCK)
		binary_pump.broadcast_status()
	else
		var/obj/machinery/atmospherics/unary/vent_pump/vent = air_pump
		unregister_radio(vent, vent.frequency)
		vent.id_tag = controller.tag_airpump
		vent.frequency = airlock_frequency
		vent.radio_filter_in = null
		vent.radio_filter_out = null
		vent.radio_connection = register_radio(vent, airlock_frequency, airlock_frequency)
		vent.broadcast_status()
	exterior_door.send_status()
	interior_door.send_status()
	controller.update_icon()


//Access controller for door control - used in virology and the like
/obj/machinery/embedded_controller/radio/airlock/access_controller
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "access_control_standby"

	name = "Access Controller"
	tag_secure = 1

/obj/machinery/embedded_controller/radio/airlock/access_controller/start_manual_cycle(datum/computer/file/embedded_program/airlock/chamber_program, cycle_out)
	chamber_program.receive_user_command(cycle_out ? "cycle_ext_door" : "cycle_int_door")

/obj/machinery/embedded_controller/radio/airlock/access_controller/update_icon()
	if(on && program)
		if(program.memory["processing"])
			icon_state = "access_control_process"
		else
			icon_state = "access_control_standby"
	else
		icon_state = "access_control_off"

