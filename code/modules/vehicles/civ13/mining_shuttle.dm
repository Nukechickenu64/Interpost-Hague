// A freely spawnable vehicle that participates in the shuttle system rather than
// approximating long-range travel with the modular vehicle movement loop.

var/civ13_mining_shuttle_serial = 0

/area/shuttle/civ13_mining
	name = "Prospector Mining Shuttle"
	icon_state = "shuttle"

/obj/effect/shuttle_landmark/civ13_mining
	name = "Prospector home berth"
	// The chassis records this landmark's base area before converting its
	// footprint into a shuttle area.  Do not let deferred atom initialization
	// overwrite that saved berth with the dynamic area.
	autoset = FALSE

/obj/effect/shuttle_landmark/civ13_mining/New(var/newloc, var/tag)
	landmark_tag = tag
	..(newloc)

/obj/effect/shuttle_landmark/civ13_mining/Destroy()
	if(SSshuttle && SSshuttle.registered_shuttle_landmarks[landmark_tag] == src)
		SSshuttle.registered_shuttle_landmarks -= landmark_tag
	return ..()

/datum/shuttle/autodock/multi/civ13_mining
	defer_initialisation = TRUE
	warmup_time = 10
	move_time = 120
	var/datum/mining_expedition_controller/civ13/controller

/datum/shuttle/autodock/multi/civ13_mining/New(var/shuttle_name, var/obj/effect/shuttle_landmark/start, var/area/dynamic_area, var/datum/mining_expedition_controller/civ13/new_controller)
	shuttle_area = list(dynamic_area)
	controller = new_controller
	..(shuttle_name, start)

/datum/shuttle/autodock/multi/civ13_mining/proc/civ13_long_jump(var/obj/effect/shuttle_landmark/destination, var/travel_time)
	if(moving_status != SHUTTLE_IDLE)
		return
	moving_status = SHUTTLE_WARMUP
	if(sound_takeoff)
		playsound(current_location, sound_takeoff, 100, 20, 0.2)
	spawn(warmup_time * 10)
		if(QDELETED(src) || moving_status == SHUTTLE_IDLE)
			return
		if(!fuel_check())
			cancel_launch(null)
			return
		arrive_time = world.time + travel_time * 10
		moving_status = SHUTTLE_INTRANSIT
		sleep(max(0, travel_time) * 10)
		if(QDELETED(src) || moving_status != SHUTTLE_INTRANSIT)
			return
		if(!attempt_move(destination))
			var/mob/alert_user = ismob(in_use) ? in_use : null
			// Unlike a normal long jump, this shuttle deliberately remains at its
			// origin until its simulated transit completes.  Do not let a failed
			// arrival fall through to process_arrived(), which would otherwise
			// release the lock as if it had reached the destination.
			moving_status = SHUTTLE_IDLE
			next_location = null
			in_use = null
			process_state = IDLE_STATE
			var/datum/mining_expedition_controller/civ13/C = controller
			if(C && C.mission_pending)
				C.mission_error = "MINING SHUTTLE COULD NOT REACH THE DESTINATION."
				C.finish_mission()
			else if(alert_user)
				to_chat(alert_user, SPAN_WARNING("Prospector shuttle could not reach its destination."))
			log_game("Prospector shuttle [name] failed to reach [destination].")
			return
		moving_status = SHUTTLE_IDLE

/datum/shuttle/autodock/multi/civ13_mining/process_launch()
	if(!next_location || !next_location.is_valid(src))
		process_state = IDLE_STATE
		in_use = null
		return
	civ13_long_jump(next_location, move_time)
	process_state = WAIT_ARRIVE

/datum/shuttle/autodock/multi/civ13_mining/process_arrived()
	// Use the actual final waypoint for the parent docking cleanup, matching the
	// mapped mining shuttle's arrival behavior.
	next_location = current_location
	var/datum/mining_expedition_controller/civ13/C = controller
	if(C && C.mission_pending && current_location == C.mission_dock)
		C.has_last_location = TRUE
		C.finish_mission()
	return ..()

/datum/shuttle/autodock/multi/civ13_mining/cancel_launch(var/user)
	if(can_cancel() && controller && controller.mission_pending)
		controller.finish_mission()
	return ..()

/datum/mining_expedition_controller/civ13
	var/datum/shuttle/autodock/multi/civ13_mining/mining_vehicle
	var/obj/effect/shuttle_landmark/civ13_mining/home_landmark

/datum/mining_expedition_controller/civ13/get_shuttle()
	return mining_vehicle && !QDELETED(mining_vehicle) ? mining_vehicle : null

/datum/mining_expedition_controller/civ13/is_home_landmark(var/obj/effect/shuttle_landmark/L)
	return L && L == home_landmark

/datum/mining_expedition_controller/civ13/get_home_landmark()
	return home_landmark

/datum/mining_expedition_controller/civ13/has_transit_navigation(var/datum/shuttle/autodock/S)
	return S && S == mining_vehicle

/datum/mining_expedition_controller/civ13/ensure_ruins_level(var/mob/user, var/startup_preparation = FALSE)
	var/area/space/ruins/existing_area = get_space_ruins_area()
	var/existing_z = get_space_ruins_z()
	if(existing_area && existing_z)
		ruins_area = existing_area
		ruins_z = existing_z
		ruins_ready = TRUE
		return TRUE
	return ..()

/datum/mining_expedition_controller/civ13/get_satellite_landmark(var/mob/user)
	var/datum/mining_expedition_controller/main_controller = get_mining_expedition()
	if(main_controller && main_controller != src)
		return main_controller.get_satellite_landmark(user)
	return ..()

/obj/structure/vehicleparts/axis/spacecraft/mining
	name = "Prospector mining shuttle chassis"
	desc = "A shuttle-integrated spacecraft chassis. Its pilot couch controls mining missions rather than local thrust."
	var/area/shuttle/civ13_mining/shuttle_area
	var/datum/shuttle/autodock/multi/civ13_mining/shuttle
	var/datum/mining_expedition_controller/civ13/mining_controller
	var/obj/effect/shuttle_landmark/civ13_mining/home_landmark
	var/obj/machinery/computer/civ13_mining_shuttle_comms/comms_console

/obj/structure/vehicleparts/axis/spacecraft/mining/can_drive(mob/user)
	return FALSE

/obj/structure/vehicleparts/axis/spacecraft/mining/proc/find_comms_turf()
	for(var/obj/structure/vehicleparts/frame/frame in components)
		for(var/direction in GLOB.cardinal)
			var/turf/candidate = get_step(frame, direction)
			if(!candidate || candidate.density || has_frame(candidate))
				continue
			var/blocked = FALSE
			for(var/atom/movable/obstacle in candidate)
				if(obstacle.density)
					blocked = TRUE
					break
			if(!blocked)
				return candidate
	return null

/obj/structure/vehicleparts/axis/spacecraft/mining/on_preset_assembled(list/locations)
	if(!SSshuttle || !SSshuttle.initialized)
		initialization_error = "The shuttle control subsystem is not ready."
		return FALSE
	var/turf/origin = get_turf(src)
	if(!origin)
		initialization_error = "The Prospector has no valid home berth."
		return FALSE
	var/serial = ++civ13_mining_shuttle_serial
	home_landmark = new /obj/effect/shuttle_landmark/civ13_mining(origin, "civ13_mining_home_[serial]")
	if(!home_landmark)
		initialization_error = "Unable to register a Prospector home berth."
		return FALSE
	// Preserve the berth before its turf becomes part of the dynamic shuttle
	// area.  This also keeps construction rollback safe if initialization is
	// deferred by the atom subsystem.
	home_landmark.base_area = get_area(origin)
	home_landmark.base_turf = origin.type
	shuttle_area = new /area/shuttle/civ13_mining
	for(var/coordinate in locations)
		var/turf/tile = locations[coordinate]
		if(tile)
			shuttle_area.contents.Add(tile)
	if(origin.loc != shuttle_area)
		shuttle_area.contents.Add(origin)
	mining_controller = new
	civ13_mining_expeditions += mining_controller
	mining_controller.home_landmark = home_landmark
	shuttle = new /datum/shuttle/autodock/multi/civ13_mining("Prospector Mining [serial]", home_landmark, shuttle_area, mining_controller)
	if(!shuttle)
		qdel(home_landmark)
		home_landmark = null
		civ13_mining_expeditions -= mining_controller
		QDEL_NULL(mining_controller)
		initialization_error = "Unable to register the Prospector with shuttle control."
		return FALSE
	mining_controller.mining_vehicle = shuttle
	var/turf/comms_turf = find_comms_turf()
	if(!comms_turf)
		initialization_error = "The Prospector needs one clear adjacent turf for its communications console."
		return FALSE
	comms_console = new(comms_turf)
	comms_console.mining_controller = mining_controller
	comms_console.linked_shuttle = src
	comms_console.name = "Prospector Mining [serial] communications console"
	visible_message(SPAN_NOTICE("[src] registers as [shuttle.name]. Its communications console is at ([comms_turf.x], [comms_turf.y], [comms_turf.z])."))
	return TRUE

/obj/structure/vehicleparts/axis/spacecraft/mining/Destroy()
	var/area/return_area = shuttle && shuttle.current_location ? shuttle.current_location.base_area : (home_landmark ? home_landmark.base_area : null)
	if(return_area && shuttle_area)
		for(var/turf/tile in shuttle_area)
			return_area.contents.Add(tile)
	QDEL_NULL(comms_console)
	if(mining_controller)
		mining_controller.mission_pending = FALSE
		if(ruins_gen_job && ruins_gen_job.mission_controller == mining_controller && ruins_gen_job.is_active())
			ruins_gen_job.cancel()
		civ13_mining_expeditions -= mining_controller
		mining_controller.mining_vehicle = null
		QDEL_NULL(mining_controller)
	QDEL_NULL(shuttle)
	QDEL_NULL(home_landmark)
	QDEL_NULL(shuttle_area)
	shuttle_area = null
	return ..()

/obj/structure/bed/chair/civ13/driver/spacecraft/mining
	name = "Prospector pilot couch"
	desc = "A mining shuttle flight station. It controls expeditions, salvage, satellite travel and remote-command permission."

/obj/structure/bed/chair/civ13/driver/spacecraft/mining/attack_hand(mob/living/user)
	if(buckled_mob != user)
		return ..()
	var/obj/structure/vehicleparts/axis/spacecraft/mining/chassis = vehicle_axis
	if(!istype(chassis) || user.incapacitated())
		return
	var/list/actions = list("Mining Shuttle Controls", "Leave Seat")
	var/action = input(user, "Select an action", "Prospector Controls") as null|anything in actions
	if(!action || buckled_mob != user || vehicle_axis != chassis || user.incapacitated())
		return
	if(action == "Leave Seat")
		return user_unbuckle_mob(user)
	if(!user.GetAccess(access_mining))
		to_chat(user, SPAN_WARNING("ACCESS DENIED: Mining authorization required."))
		return
	if(!chassis.mining_controller || !chassis.mining_controller.get_shuttle())
		to_chat(user, SPAN_WARNING("Unable to establish a link with this shuttle."))
		return
	chassis.mining_controller.show_local_menu(user, src)

/obj/structure/bed/chair/civ13/driver/spacecraft/mining/OnTopic(var/mob/user, var/list/href_list)
	var/obj/structure/vehicleparts/axis/spacecraft/mining/chassis = vehicle_axis
	if(buckled_mob != user || !istype(chassis) || user.incapacitated() || !user.GetAccess(access_mining))
		return TOPIC_HANDLED
	if(chassis.mining_controller && chassis.mining_controller.handle_menu_action(user, href_list))
		playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)
	return TOPIC_HANDLED

/obj/machinery/computer/civ13_mining_shuttle_comms
	desc = "A paired command uplink for a Prospector mining shuttle."
	icon_keyboard = "tech_key"
	icon_screen = "comm_monitor"
	var/datum/mining_expedition_controller/civ13/mining_controller
	var/obj/structure/vehicleparts/axis/spacecraft/mining/linked_shuttle

/obj/machinery/computer/civ13_mining_shuttle_comms/attack_hand(mob/user)
	if(..())
		return
	if(!user.GetAccess(ACCESS_REGION_COMMAND))
		to_chat(user, SPAN_WARNING("ACCESS DENIED: Command authorization required."))
		return
	if(!mining_controller || !mining_controller.get_shuttle())
		to_chat(user, SPAN_WARNING("SHUTTLE SIGNAL LOST."))
		return
	if(mining_controller.remote_forbidden)
		to_chat(user, SPAN_WARNING("REMOTE CONTROL LOCKED BY SHUTTLE."))
		return
	mining_controller.show_remote_menu(user, src)

/obj/machinery/computer/civ13_mining_shuttle_comms/OnTopic(var/mob/user, var/list/href_list)
	if(stat & (BROKEN|NOPOWER) || !user.GetAccess(ACCESS_REGION_COMMAND))
		return TOPIC_HANDLED
	if(!mining_controller || !mining_controller.get_shuttle() || mining_controller.remote_forbidden)
		return TOPIC_HANDLED
	if(mining_controller.handle_menu_action(user, href_list, TRUE))
		playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)
	return TOPIC_HANDLED
