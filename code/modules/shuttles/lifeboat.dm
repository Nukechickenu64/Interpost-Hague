/area/shuttle/lifeboat
	name = "Lifeboat"
	icon_state = "shuttle"
	var/datum/shuttle/autodock/multi/lifeboat/shuttle

/area/shuttle/lifeboat/second
	name = "Lifeboat 2"

/obj/effect/shuttle_landmark/lifeboat
	name = "Lifeboat landing point"
	base_turf = /turf/space
	shuttle_restricted = "Lifeboat"

/obj/effect/shuttle_landmark/lifeboat/is_valid(datum/shuttle/shuttle)
	return shuttle?.name == shuttle_restricted && shuttle.current_location != src && os13_rescue_footprint_clear(shuttle, get_turf(src), base_area)

/obj/effect/shuttle_landmark/lifeboat/berth
	name = "Lifeboat berth"
	landmark_tag = "nav_lifeboat_start"

/obj/effect/shuttle_landmark/lifeboat/berth/second
	name = "Lifeboat 2 berth"
	landmark_tag = "nav_lifeboat_2_start"
	shuttle_restricted = "Lifeboat 2"

/obj/effect/shuttle_landmark/lifeboat/transit
	name = "Lifeboat in transit"
	landmark_tag = "nav_lifeboat_transit"
	autoset = TRUE

/obj/effect/shuttle_landmark/lifeboat/destination
	name = "Lifeboat destination"
	autoset = TRUE

/obj/effect/shuttle_landmark/lifeboat/destination/open_space
	name = "Open Space"
	landmark_tag = "nav_lifeboat_open_space"

/obj/effect/shuttle_landmark/lifeboat/destination/open_space/New(turf/landing, datum/shuttle/autodock/multi/lifeboat/boat)
	if(boat)
		shuttle_restricted = boat.name
		landmark_tag = boat.open_space_tag
	return ..(landing)

/obj/effect/shuttle_landmark/lifeboat/destination/open_space/Destroy()
	if(SSshuttle.get_landmark(landmark_tag) == src)
		SSshuttle.registered_shuttle_landmarks -= landmark_tag
	return ..()

/datum/shuttle/autodock/multi/lifeboat
	name = "Lifeboat"
	warmup_time = 10
	shuttle_area = /area/shuttle/lifeboat
	current_location = "nav_lifeboat_start"
	var/open_space_tag = "nav_lifeboat_open_space"
	var/area/shuttle/lifeboat/cabin
	var/obj/effect/shuttle_landmark/lifeboat/berth/home_berth
	var/obj/effect/shuttle_landmark/lifeboat/destination/open_space/open_space
	var/datum/mining_expedition_controller/lifeboat/controller

/datum/shuttle/autodock/multi/lifeboat/second
	name = "Lifeboat 2"
	shuttle_area = /area/shuttle/lifeboat/second
	current_location = "nav_lifeboat_2_start"
	open_space_tag = "nav_lifeboat_2_open_space"

/datum/shuttle/autodock/multi/lifeboat/New()
	home_berth = SSshuttle.get_landmark(current_location)
	var/area/home_area = get_area(home_berth)
	if(!istype(home_berth) || home_area?.type != shuttle_area)
		return
	cabin = home_area
	shuttle_area = cabin
	..(name, home_berth)
	controller = new(src)
	cabin.shuttle = src

/datum/shuttle/autodock/multi/lifeboat/Destroy()
	if(cabin?.shuttle == src)
		cabin.shuttle = null
	cabin = null
	QDEL_NULL(controller)
	QDEL_NULL(open_space)
	home_berth = null
	return ..()

/datum/shuttle/autodock/multi/lifeboat/proc/get_landing_extents()
	for(var/turf/tile in cabin)
		if(tile.z != home_berth.z)
			log_error("[name] must occupy a single z-level.")
			return null
	return get_shuttle_footprint_extents(src)

/datum/shuttle/autodock/multi/lifeboat/proc/prepare_open_space(space_z, list/extents, list/bounds)
	// Center the entire hull in its assigned region, even with an off-center berth.
	var/landing_x = round((bounds[1] + bounds[3] - extents[1] - extents[3]) / 2)
	var/landing_y = round((bounds[2] + bounds[4] - extents[2] - extents[4]) / 2)
	open_space = new(locate(landing_x, landing_y, space_z), src)
	if(!open_space.is_valid(src))
		QDEL_NULL(open_space)
		log_error("[name] open-space preparation failed during shuttle initialization.")
		return FALSE
	GLOB.using_map.player_levels |= space_z
	return TRUE

/datum/shuttle/autodock/multi/lifeboat/proc/hatches_closed()
	for(var/area/cabin in shuttle_area)
		for(var/obj/machinery/door/airlock/hatch in cabin)
			if(!hatch.density || hatch.operating)
				return FALSE
	return TRUE

/datum/shuttle/autodock/multi/lifeboat/get_destinations()
	destinations_cache.Cut()
	if(controller.can_visit(open_space))
		destinations_cache[open_space.landmark_tag] = open_space
	return destinations_cache

/datum/shuttle/autodock/multi/lifeboat/can_launch()
	return process_state == IDLE_STATE && controller.can_visit(next_location) && ..() && hatches_closed()

/datum/shuttle/autodock/multi/lifeboat/can_force()
	return controller.can_visit(next_location) && ..()

/datum/shuttle/autodock/multi/lifeboat/process_launch()
	if(!controller.can_visit(next_location))
		cancel_launch(null)
		return
	return ..()

/datum/shuttle/autodock/multi/lifeboat/attempt_move(obj/effect/shuttle_landmark/destination)
	if(!controller.can_visit(destination) || !hatches_closed())
		return FALSE
	return ..()

/datum/shuttle/autodock/multi/lifeboat/process_arrived()
	next_location = current_location
	return ..()

/datum/mining_expedition_controller/lifeboat
	var/datum/shuttle/autodock/multi/lifeboat/shuttle

/datum/mining_expedition_controller/lifeboat/New(datum/shuttle/autodock/multi/lifeboat/boat)
	shuttle = boat
	return ..()

/datum/mining_expedition_controller/lifeboat/get_shuttle()
	return shuttle

/datum/mining_expedition_controller/lifeboat/is_home_landmark(obj/effect/shuttle_landmark/point)
	return point == shuttle.home_berth

/datum/mining_expedition_controller/lifeboat/is_expedition_landmark(obj/effect/shuttle_landmark/point)
	return FALSE

/datum/mining_expedition_controller/lifeboat/can_visit(obj/effect/shuttle_landmark/point)
	return GLOB.os13_classic_round.self_destruct_active() && !QDELETED(point) && point == shuttle.open_space && shuttle.current_location == shuttle.home_berth

/datum/mining_expedition_controller/lifeboat/show_local_menu(mob/user, atom/holder)
	var/list/links = list()
	if(can_visit(shuttle.open_space))
		links += mining_menu_link(holder, "open_space", "LAUNCH TO OPEN SPACE")
	else if(shuttle.current_location == shuttle.home_berth && !GLOB.os13_classic_round.self_destruct_active())
		links += "<span class='graytext'>LAUNCH LOCKED UNTIL STATION SELF-DESTRUCT IS INITIATED</span>"
	else if(shuttle.current_location != shuttle.open_space)
		links += "<span class='graytext'>NO LIFEBOAT DESTINATIONS AVAILABLE</span>"
	if(shuttle.can_cancel())
		links += mining_menu_link(holder, "cancel", "CANCEL DEPARTURE")
	to_chat(user, render_menu(holder, links))

/datum/mining_expedition_controller/lifeboat/handle_menu_action(mob/user, list/href_list, remote = FALSE)
	if(remote)
		return FALSE
	var/action = href_list["action"]
	if(action == "cancel")
		shuttle.cancel_launch(user)
		return TRUE
	if(action == "open_space")
		if(GLOB.os13_classic_round.self_destruct_active())
			dispatch(shuttle.open_space, user, shuttle.warmup_time)
		else
			fail(user, "LAUNCH LOCKED UNTIL STATION SELF-DESTRUCT IS INITIATED.")
		return TRUE
	return FALSE

/obj/machinery/computer/os13_scout_controls/lifeboat
	name = "Lifeboat Controls"
	desc = "The lifeboat's Scout-style flight controls."

/datum/controller/subsystem/shuttle/proc/prepare_lifeboat_landings()
	var/datum/shuttle/autodock/multi/lifeboat/first = shuttles["Lifeboat"]
	var/datum/shuttle/autodock/multi/lifeboat/second = shuttles["Lifeboat 2"]
	var/list/first_extents = first?.get_landing_extents()
	var/list/second_extents = second?.get_landing_extents()
	if(!first_extents && !second_extents)
		return

	var/space_z = ++world.maxz
	var/second_z = space_z
	var/list/first_bounds = list(1, 1, world.maxx, world.maxy)
	var/list/second_bounds = first_bounds.Copy()
	if(first_extents && second_extents)
		var/first_width = first_extents[3] - first_extents[1] + 1
		var/second_width = second_extents[3] - second_extents[1] + 1
		var/first_height = first_extents[4] - first_extents[2] + 1
		var/second_height = second_extents[4] - second_extents[2] + 1
		// Use disjoint regions so both landing footprints are clear even if they launch together.
		if(first_width + second_width <= world.maxx)
			var/split_x = clamp(round(world.maxx / 2), first_width, world.maxx - second_width)
			first_bounds[3] = split_x
			second_bounds[1] = split_x + 1
		else if(first_height + second_height <= world.maxy)
			var/split_y = clamp(round(world.maxy / 2), first_height, world.maxy - second_height)
			first_bounds[4] = split_y
			second_bounds[2] = split_y + 1
		else
			second_z = ++world.maxz

	if(first_extents)
		first.prepare_open_space(space_z, first_extents, first_bounds)
	if(second_extents)
		second.prepare_open_space(second_z, second_extents, second_bounds)
