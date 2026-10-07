#define MINING_SHUTTLE_TAG "Mining"
#define MINING_STATION_LANDMARK "nav_mining_start"
#define MINING_RUINS_LANDMARK "nav_mining_space_ruins"
#define MINING_SATELLITE_LANDMARK "nav_mining_satellite"

var/datum/mining_expedition_controller/mining_expedition
var/list/civ13_mining_expeditions = list()

/proc/get_mining_expedition()
	if(!mining_expedition)
		mining_expedition = new
	return mining_expedition

/proc/get_space_ruins_area()
	if(mining_expedition && mining_expedition.ruins_area)
		return mining_expedition.loading_ruins ? null : mining_expedition.ruins_area
	for(var/area/A in world)
		if(A.type == /area/space/ruins)
			return A
	return null

/proc/get_space_ruins_z()
	var/area/A = get_space_ruins_area()
	if(!A)
		return 0
	for(var/turf/T in A)
		return T.z
	return 0

// Returns list(dx_min, dy_min, dx_max, dy_max) of the shuttle's turfs relative to its current landmark.
/proc/get_shuttle_footprint_extents(var/datum/shuttle/S)
	if(!S || !S.current_location)
		return null
	var/turf/origin = get_turf(S.current_location)
	if(!origin)
		return null
	var/list/ext = list(0, 0, 0, 0)
	for(var/area/A in S.shuttle_area)
		for(var/turf/T in A)
			ext[1] = min(ext[1], T.x - origin.x)
			ext[2] = min(ext[2], T.y - origin.y)
			ext[3] = max(ext[3], T.x - origin.x)
			ext[4] = max(ext[4], T.y - origin.y)
	return ext

// Rectangle list(minx, miny, maxx, maxy, z) that generation must leave empty around the ruins dock.
/proc/get_mining_dock_exclusion(var/margin = 3, var/datum/shuttle/S = null, var/obj/effect/shuttle_landmark/dock = null)
	if(!dock)
		dock = SSshuttle.get_landmark(MINING_RUINS_LANDMARK)
	if(!S)
		S = SSshuttle.shuttles[MINING_SHUTTLE_TAG]
	if(!istype(dock) || !S)
		return null
	var/turf/D = get_turf(dock)
	var/list/ext = get_shuttle_footprint_extents(S)
	if(!D || !ext)
		return null
	return list(D.x + ext[1] - margin, D.y + ext[2] - margin, D.x + ext[3] + margin, D.y + ext[4] + margin, D.z)

/proc/turf_in_exclusion(var/turf/T, var/list/rect)
	if(!T || !rect)
		return FALSE
	return T.z == rect[5] && T.x >= rect[1] && T.x <= rect[3] && T.y >= rect[2] && T.y <= rect[4]

/proc/mining_menu_link(var/atom/holder, var/action, var/label)
	return "<span class='feedback'><a href='?src=\ref[holder];action=[action]'>[label]</a></span>"

/obj/effect/shuttle_landmark/proc/force_clear_footprint(var/datum/shuttle/shuttle)
	if(!shuttle || !shuttle.current_location || shuttle.current_location == src)
		return
	var/profile_clear = config && config.log_debug
	var/clear_start = profile_clear ? world.realtime : 0
	var/clear_usage = profile_clear ? TICK_USAGE_REAL : 0
	var/turf/from_origin = get_turf(shuttle.current_location)
	ensure_base_area(get_turf(src))
	for(var/area/A in shuttle.shuttle_area)
		var/list/translation = get_turf_translation_safe(from_origin, get_turf(src), A.contents)
		for(var/source in translation)
			if(!translation[source])
				try_reposition_to_valid_footprint(from_origin, get_turf(src), A)
				translation = get_turf_translation_safe(from_origin, get_turf(src), A.contents)
				break
		for(var/source in translation)
			var/turf/target = translation[source]
			if(!target)
				continue
			if(target.loc != base_area)
				base_area.contents.Add(target)
			for(var/atom/movable/AM in target)
				if(AM == src || !AM.simulated || ismob(AM))
					continue
				if(AM.anchored || AM.density)
					qdel(AM)
			var/clear_type = base_turf || get_base_turf_by_area(target)
			if(target.density || (clear_type && !istype(target, clear_type)))
				target.ChangeTurf(clear_type)
	if(profile_clear)
		log_debug("Shuttle footprint clear [shuttle.name] at [landmark_tag]: elapsed=[(world.realtime - clear_start) / 10]s cost=[TICK_DELTA_TO_MS(TICK_USAGE_REAL - clear_usage)]ms")

/obj/effect/shuttle_landmark/mining/satellite
	name = "Satellite"
	landmark_tag = MINING_SATELLITE_LANDMARK
	base_turf = /turf/space

/datum/mining_expedition_controller
	var/remote_forbidden = FALSE
	var/has_last_location = FALSE
	var/satellite_z = 0
	var/loading_satellite = FALSE
	var/ruins_z = 0
	var/area/space/ruins/ruins_area
	var/loading_ruins = FALSE
	var/ruins_ready = FALSE
	var/ruins_fresh = FALSE
	var/list/deferred_ruins_atoms
	var/initializing_shuttle = FALSE
	var/datum/shuttle/autodock/mining_shuttle
	var/mission_pending = FALSE
	var/mission_salvage = FALSE
	var/mission_ready = FALSE
	var/mission_error
	var/mission_arrival_time = 0
	var/mission_travel_time = 0
	var/obj/effect/shuttle_landmark/mission_dock
	var/mob/mission_user

/datum/mining_expedition_controller/proc/get_shuttle()
	var/datum/shuttle/autodock/S = SSshuttle.shuttles[MINING_SHUTTLE_TAG]
	if(istype(S) && !QDELETED(S))
		mining_shuttle = S
		return S
	if(mining_shuttle && !QDELETED(mining_shuttle))
		SSshuttle.shuttles[MINING_SHUTTLE_TAG] = mining_shuttle
		return mining_shuttle
	for(var/datum/shuttle/autodock/existing in SSshuttle.process_shuttles)
		if(existing.name == MINING_SHUTTLE_TAG && !QDELETED(existing))
			mining_shuttle = existing
			SSshuttle.shuttles[MINING_SHUTTLE_TAG] = existing
			return existing
	if(!SSshuttle.initialized || initializing_shuttle)
		return null
	var/obj/effect/shuttle_landmark/station = SSshuttle.get_landmark(MINING_STATION_LANDMARK)
	var/area/shuttle/mining/station/shuttle_area = locate(/area/shuttle/mining/station)
	if(!station || !shuttle_area)
		return null
	var/has_shuttle_turfs = FALSE
	for(var/turf/T in shuttle_area)
		if(T.z == station.z)
			has_shuttle_turfs = TRUE
			break
	if(!has_shuttle_turfs)
		return null
	initializing_shuttle = TRUE
	SSshuttle.initialise_shuttle(/datum/shuttle/autodock/multi/mining)
	initializing_shuttle = FALSE
	S = SSshuttle.shuttles[MINING_SHUTTLE_TAG]
	if(istype(S))
		mining_shuttle = S
		return S
	return null

/datum/mining_expedition_controller/proc/ensure_ruins_level(var/mob/user, var/startup_preparation = FALSE)
	if(ruins_ready && ruins_area && ruins_z)
		return TRUE
	if(loading_ruins)
		return fail(user, "DEBRIS FIELD PREPARATION IS IN PROGRESS.")
	var/list/ext = get_shuttle_footprint_extents(get_shuttle())
	if(!ext || ext[3] - ext[1] + 8 >= world.maxx || ext[4] - ext[2] + 8 >= world.maxy)
		return fail(user, "NO SAFE DEBRIS FIELD LANDING SITE AVAILABLE.")
	loading_ruins = TRUE
	var/profile_generation = config && config.log_debug
	try
		if(!ruins_z)
			var/allocation_start = world.realtime
			var/allocation_usage = world.tick_usage
			var/old_init_stage = SSatoms.atom_init_stage
			var/list/old_created_atoms = SSatoms.created_atoms
			deferred_ruins_atoms = list()
			SSatoms.created_atoms = deferred_ruins_atoms
			SSatoms.atom_init_stage = INITIALIZATION_INSSATOMS_LATE
			try
				world.maxz++
				ruins_z = world.maxz
			catch(var/exception/allocation_error)
				SSatoms.atom_init_stage = old_init_stage
				SSatoms.created_atoms = old_created_atoms
				throw allocation_error
			SSatoms.atom_init_stage = old_init_stage
			SSatoms.created_atoms = old_created_atoms
			if(profile_generation)
				log_debug("Mining generation level allocation: elapsed=[(world.realtime - allocation_start) / 10]s tick_usage=[world.tick_usage]% slice_usage=[world.tick_usage - allocation_usage]% size=[world.maxx]x[world.maxy] deferred_atoms=[length(deferred_ruins_atoms)]")
			var/zstack_start = world.realtime
			var/zstack_usage = world.tick_usage
			if(SSzcopy.zstack_maximums.len)
				SSzcopy.calculate_zstack_limits()
			if(profile_generation)
				log_debug("Mining generation zstack setup: elapsed=[(world.realtime - zstack_start) / 10]s tick_usage=[world.tick_usage]% slice_usage=[world.tick_usage - zstack_usage]%")
		if(!ruins_area)
			ruins_area = new /area/space/ruins
		GLOB.using_map.base_turf_by_z[num2text(ruins_z)] = /turf/space
		GLOB.using_map.player_levels |= ruins_z
		var/datum/ruins_generation_budget/budget = new
		var/preparation_start = world.realtime
		budget.begin_phase(world.maxx * world.maxy * 0.125 + length(deferred_ruins_atoms) * 4, 0.2, "level preparation")
		for(var/row = 1, row <= world.maxy, row++)
			for(var/column = 1, column <= world.maxx, column++)
				if(startup_preparation)
					CHECK_TICK
				else
					budget.check()
				var/turf/T = locate(column, row, ruins_z)
				ruins_area.contents.Add(T)
				if(!istype(T, /turf/space))
					T.ChangeTurf(/turf/space)
			CHECK_TICK
		if(profile_generation)
			log_debug("Mining generation turf preparation: elapsed=[(world.realtime - preparation_start) / 10]s (includes pacing)")
		var/initialization_start = world.realtime
		var/list/init_arguments = list(FALSE)
		for(var/atom/created in deferred_ruins_atoms)
			if(startup_preparation)
				CHECK_TICK
			else
				budget.check(4)
			if(!QDELETED(created) && !(created.atom_flags & ATOM_FLAG_INITIALIZED))
				SSatoms.InitAtom(created, init_arguments)
		if(profile_generation)
			log_debug("Mining generation deferred initialization: elapsed=[(world.realtime - initialization_start) / 10]s (includes pacing)")
		deferred_ruins_atoms = null
	catch(var/exception/error)
		loading_ruins = FALSE
		log_error("Mining ruins level preparation failed: [error]")
		return fail(user, "DEBRIS FIELD PREPARATION FAILED. PLEASE RETRY.")
	loading_ruins = FALSE
	ruins_ready = TRUE
	ruins_fresh = TRUE
	log_game("Mining debris field created on z-level [ruins_z].")
	return TRUE

/datum/mining_expedition_controller/proc/shuttle_is_idle(var/datum/shuttle/autodock/S)
	return S && S.current_location && S.moving_status == SHUTTLE_IDLE && S.process_state == IDLE_STATE && !S.in_use

/datum/mining_expedition_controller/proc/is_home_landmark(var/obj/effect/shuttle_landmark/L)
	return L && L.landmark_tag == MINING_STATION_LANDMARK

/datum/mining_expedition_controller/proc/is_home_dock(var/datum/shuttle/autodock/S)
	return S && is_home_landmark(S.current_location)

/datum/mining_expedition_controller/proc/get_home_landmark()
	return SSshuttle.get_landmark(MINING_STATION_LANDMARK)

/datum/mining_expedition_controller/proc/has_transit_navigation(var/datum/shuttle/autodock/S)
	return S && S.landmark_transition && S.landmark_transition.is_valid(S)

/datum/mining_expedition_controller/proc/is_expedition_landmark(var/obj/effect/shuttle_landmark/L)
	return istype(L) && (L.landmark_tag == MINING_RUINS_LANDMARK || L.landmark_tag == MINING_SATELLITE_LANDMARK)

/datum/mining_expedition_controller/proc/location_label(var/obj/effect/shuttle_landmark/L)
	if(!L)
		return "UNKNOWN"
	if(is_home_landmark(L))
		return "STATION"
	switch(L.landmark_tag)
		if(MINING_RUINS_LANDMARK)
			return "DEBRIS FIELD"
		if(MINING_SATELLITE_LANDMARK)
			return "SATELLITE"
	return uppertext(L.name)

/datum/mining_expedition_controller/proc/status_text()
	var/datum/shuttle/autodock/S = get_shuttle()
	if(!S)
		return "NO SHUTTLE SIGNAL"
	if(mission_pending)
		if(S.moving_status == SHUTTLE_IDLE && !mission_ready)
			var/generation_progress = ruins_gen_job ? ruins_gen_job.get_percent() : 0
			return "PREPARING DEBRIS FIELD [generation_progress]% - SHUTTLE HOLDING AT STATION"
		if(S.moving_status != SHUTTLE_INTRANSIT)
			return "DEPARTING FOR DEBRIS FIELD"
		var/eta = max(0, ceil((S.arrive_time - world.time) / 10))
		return "EN ROUTE TO DEBRIS FIELD - SURVEY COMPLETE - ETA [eta] SECONDS"
	if(S.moving_status != SHUTTLE_IDLE || S.process_state != IDLE_STATE)
		return S.next_location ? "EN ROUTE TO [location_label(S.next_location)]" : "BUSY"
	return "STANDING BY AT [location_label(S.current_location)]"

/datum/mining_expedition_controller/proc/is_away()
	var/datum/shuttle/autodock/S = get_shuttle()
	return S && S.current_location && !is_home_landmark(S.current_location)

/datum/mining_expedition_controller/proc/is_at_ruins()
	var/datum/shuttle/autodock/S = get_shuttle()
	return S && S.current_location && S.current_location.landmark_tag == MINING_RUINS_LANDMARK

/datum/mining_expedition_controller/proc/fail(var/mob/user, var/message)
	if(user)
		to_chat(user, "<span class='warning'>[message]</span>")
	return FALSE

/datum/mining_expedition_controller/proc/can_regenerate_ruins(var/mob/user, var/owned_mission = FALSE)
	if(mission_pending && !owned_mission)
		return fail(user, "A DEEP-SPACE SURVEY IS ALREADY IN PROGRESS.")
	var/rz = get_space_ruins_z()
	if(!rz)
		return fail(user, "NO DEBRIS FIELD ON RECORD.")
	if(ruins_gen_job && ruins_gen_job.is_active())
		return fail(user, "A DEEP-SPACE SURVEY IS ALREADY IN PROGRESS.")
	var/datum/shuttle/autodock/S = get_shuttle()
	if(S)
		if(S.current_location && S.current_location.z == rz)
			return fail(user, "MISSION DENIED: THE SHUTTLE IS STILL AT THE DEBRIS FIELD.")
		if(S.next_location && S.next_location.z == rz)
			return fail(user, "MISSION DENIED: THE SHUTTLE IS EN ROUTE TO THE DEBRIS FIELD.")
	// A Prospector uses its own controller, so it must also respect the mapped
	// Mining shuttle before replacing the shared debris field.
	var/datum/mining_expedition_controller/main_expedition = get_mining_expedition()
	if(main_expedition && main_expedition != src)
		var/datum/shuttle/autodock/main_shuttle = main_expedition.get_shuttle()
		if(main_shuttle && ((main_shuttle.current_location && main_shuttle.current_location.z == rz) || (main_shuttle.next_location && main_shuttle.next_location.z == rz)))
			return fail(user, "MISSION DENIED: THE MINING SHUTTLE IS USING THE DEBRIS FIELD.")
	for(var/mob/living/L in world)
		if(!L.ckey)
			continue
		var/turf/T = get_turf(L)
		if(T && T.z == rz)
			return fail(user, "MISSION DENIED: PERSONNEL DETECTED IN THE DEBRIS FIELD.")
	for(var/datum/mining_expedition_controller/civ13/other_expedition in civ13_mining_expeditions)
		if(other_expedition == src)
			continue
		var/datum/shuttle/autodock/other_shuttle = other_expedition.get_shuttle()
		if(other_shuttle && ((other_shuttle.current_location && other_shuttle.current_location.z == rz) || (other_shuttle.next_location && other_shuttle.next_location.z == rz)))
			return fail(user, "MISSION DENIED: ANOTHER PROSPECTOR IS USING THE DEBRIS FIELD.")
	return TRUE

/datum/mining_expedition_controller/proc/dispatch(var/obj/effect/shuttle_landmark/destination, var/mob/user, var/travel_time)
	var/datum/shuttle/autodock/S = get_shuttle()
	if(!S)
		return fail(user, "UNABLE TO ESTABLISH LINK WITH THE SHUTTLE.")
	if(!istype(destination))
		return fail(user, "NAVIGATION DATA UNAVAILABLE.")
	if(S.current_location == destination)
		return fail(user, "THE SHUTTLE IS ALREADY THERE.")
	if(!shuttle_is_idle(S) || mission_pending)
		return fail(user, "THE SHUTTLE IS BUSY.")
	S.move_time = travel_time || initial(S.move_time)
	S.next_location = destination
	if(is_expedition_landmark(destination))
		destination.force_clear_footprint(S)
	S.launch(user)
	if(user)
		to_chat(user, "<span class='notice'>Course plotted. The shuttle is departing for the [lowertext(location_label(destination))].</span>")
	return TRUE

/datum/mining_expedition_controller/proc/get_ruins_dock(var/mob/user)
	if(!ensure_ruins_level(user))
		return null
	var/obj/effect/shuttle_landmark/dock = SSshuttle.get_landmark(MINING_RUINS_LANDMARK)
	if(istype(dock))
		return dock.z == ruins_z ? dock : null
	var/list/ext = get_shuttle_footprint_extents(get_shuttle())
	if(!ext)
		return null
	var/dock_x = clamp(round(world.maxx / 2), 4 - ext[1], world.maxx - 3 - ext[3])
	var/dock_y = clamp(round(world.maxy / 2), 4 - ext[2], world.maxy - 3 - ext[4])
	dock = new /obj/effect/shuttle_landmark/mining/space(locate(dock_x, dock_y, ruins_z))
	dock.base_area = ruins_area
	return dock

/datum/mining_expedition_controller/proc/start_mission(var/mob/user, var/salvage)
	var/datum/shuttle/autodock/S = get_shuttle()
	if(!S)
		return fail(user, "UNABLE TO ESTABLISH LINK WITH THE SHUTTLE.")
	if(!shuttle_is_idle(S) || mission_pending || loading_ruins || (ruins_gen_job && ruins_gen_job.is_active()))
		return fail(user, "THE SHUTTLE IS BUSY.")
	if(get_space_ruins_z() && !can_regenerate_ruins(user))
		return FALSE
	if(!has_transit_navigation(S))
		return fail(user, "TRANSIT NAVIGATION IS NOT READY.")
	var/eta = rand(10, 120)
	mission_pending = TRUE
	mission_salvage = salvage
	mission_ready = FALSE
	mission_error = null
	mission_arrival_time = world.time + eta * 10
	mission_travel_time = eta
	mission_dock = null
	mission_user = user
	if(user)
		to_chat(user, "<span class='notice'>[salvage ? "Salvage" : "Mining"] survey started. The shuttle will remain docked until the debris field is ready.</span>")
	prepare_mission()
	return TRUE

/datum/mining_expedition_controller/proc/prepare_mission()
	set waitfor = FALSE
	try
		var/fresh_level = !ruins_ready || ruins_fresh
		mission_dock = get_ruins_dock()
		if(!mission_pending || mission_error)
			return
		if(!mission_dock)
			mission_error = "DEBRIS FIELD PREPARATION FAILED."
			finish_mission()
			return
		if(!ruins_gen_job)
			ruins_gen_job = new
		if(!ruins_gen_job.start(null, mission_salvage, TRUE, fresh_level, src))
			mission_error = ruins_gen_job.last_error || "DEBRIS FIELD SURVEY COULD NOT START."
			finish_mission()
			return
		has_last_location = FALSE
		while(mission_pending && !mission_error && ruins_gen_job.is_active())
			sleep(5)
		while(ruins_gen_job.is_active())
			sleep(1)
		if(!mission_pending)
			return
		if(mission_error || ruins_gen_job.last_error || ruins_gen_job.done != ruins_gen_job.total)
			if(!mission_error)
				mission_error = ruins_gen_job.last_error || "DEBRIS FIELD SURVEY INCOMPLETE."
			finish_mission()
			return
		var/datum/shuttle/autodock/S = get_shuttle()
		if(!shuttle_is_idle(S) || !is_home_dock(S))
			mission_error = "MINING SHUTTLE LEFT THE STATION BEFORE SURVEY COMPLETED."
			finish_mission()
			return
		if(!mission_dock.is_valid(S))
			mission_error = "DEBRIS FIELD LANDING SITE IS BLOCKED."
			finish_mission()
			return
		mission_ready = TRUE
		S.move_time = mission_travel_time
		S.next_location = mission_dock
		S.launch(mission_user)
		if(S.process_state != WAIT_LAUNCH)
			mission_error = "MINING SHUTTLE COULD NOT LAUNCH AFTER SURVEY."
			finish_mission()
			return
		if(mission_user)
			to_chat(mission_user, "<span class='notice'>The debris field is ready. Mining shuttle departure ETA [mission_travel_time] seconds.</span>")
	catch(var/exception/error)
		mission_error = "DEBRIS FIELD PREPARATION FAILED."
		if(ruins_gen_job && ruins_gen_job.is_active())
			ruins_gen_job.cancel()
		log_error("Mining expedition preparation failed: [error]")
		finish_mission()

/datum/mining_expedition_controller/proc/cancel_mission(var/mob/user)
	if(!mission_pending)
		return fail(user, "NO MINING MISSION IS BEING PREPARED.")
	var/datum/shuttle/autodock/S = get_shuttle()
	if(!mission_ready && S && S.moving_status == SHUTTLE_IDLE)
		mission_error = "DEBRIS FIELD SURVEY CANCELLED."
		if(ruins_gen_job && ruins_gen_job.is_active())
			ruins_gen_job.cancel()
		finish_mission()
		return TRUE
	if(S && S.can_cancel())
		S.cancel_launch(user)
		return TRUE
	return fail(user, "THE SHUTTLE CAN NO LONGER BE CANCELLED.")

/datum/mining_expedition_controller/proc/finish_mission()
	if(mission_error)
		fail(mission_user, "[mission_error] Mission aborted.")
	mission_pending = FALSE
	mission_user = null

/datum/mining_expedition_controller/proc/revisit(var/mob/user)
	if(!has_last_location)
		return fail(user, "NO PREVIOUS MISSION ON RECORD.")
	return dispatch(get_ruins_dock(), user)

/datum/mining_expedition_controller/proc/return_station(var/mob/user)
	return dispatch(get_home_landmark(), user)

/datum/mining_expedition_controller/proc/travel_satellite(var/mob/user)
	var/datum/shuttle/autodock/S = get_shuttle()
	if(!S)
		return fail(user, "UNABLE TO ESTABLISH LINK WITH THE SHUTTLE.")
	if(!shuttle_is_idle(S))
		return fail(user, "THE SHUTTLE IS BUSY.")
	var/obj/effect/shuttle_landmark/L = get_satellite_landmark(user)
	if(!L)
		return FALSE
	return dispatch(L, user)

/datum/mining_expedition_controller/proc/get_satellite_landmark(var/mob/user)
	var/obj/effect/shuttle_landmark/L = SSshuttle.get_landmark(MINING_SATELLITE_LANDMARK)
	if(istype(L))
		return L
	if(satellite_z)
		return fail(user, "SATELLITE BEACON LOST.")
	if(loading_satellite)
		return fail(user, "SATELLITE TELEMETRY STILL RESOLVING.")
	var/path = config.satellite_map
	if(!path || !fexists(path))
		return fail(user, "NO SATELLITE ON RECORD.")
	var/list/ext = get_shuttle_footprint_extents(get_shuttle())
	if(!ext)
		return fail(user, "UNABLE TO ESTABLISH LINK WITH THE SHUTTLE.")

	loading_satellite = TRUE
	var/datum/map_template/template = new(list(path), "Mining Satellite")
	template.base_turf_for_zs = /turf/space
	var/pad = max(ext[3] - ext[1], ext[4] - ext[2]) + 10
	if(!template.width || !template.height || template.width + pad * 2 > world.maxx || template.height + pad * 2 > world.maxy)
		loading_satellite = FALSE
		return fail(user, "SATELLITE TELEMETRY CORRUPTED.")
	var/rx = rand(pad, world.maxx - template.width - pad)
	var/ry = rand(pad, world.maxy - template.height - pad)
	if(!template.load_new_z(rx, ry))
		loading_satellite = FALSE
		return fail(user, "SATELLITE TELEMETRY CORRUPTED.")
	satellite_z = world.maxz
	loading_satellite = FALSE

	L = SSshuttle.get_landmark(MINING_SATELLITE_LANDMARK)
	if(istype(L))
		return L
	// No mapped landmark: park the shuttle just east of the satellite, vertically centred on it.
	var/lx = rx + template.width + 3 - ext[1]
	var/ly = ry + round(template.height / 2) - round((ext[2] + ext[4]) / 2)
	ly = clamp(ly, 2 - ext[2], world.maxy - 1 - ext[4])
	var/turf/T = locate(lx, ly, satellite_z)
	if(!T)
		return fail(user, "SATELLITE TELEMETRY CORRUPTED.")
	L = new /obj/effect/shuttle_landmark/mining/satellite(T)
	return L

/datum/mining_expedition_controller/proc/toggle_remote(var/mob/user)
	remote_forbidden = !remote_forbidden
	if(user)
		to_chat(user, "<span class='notice'>Remote control [remote_forbidden ? "forbidden" : "allowed"].</span>")

/datum/mining_expedition_controller/proc/render_menu(var/atom/holder, var/list/links)
	return "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>CHOOSE YOUR DESTINATION - [status_text()]</span>\n<hr>[jointext(links, "\n")]</div></div>"

/datum/mining_expedition_controller/proc/show_local_menu(mob/user, atom/holder)
	var/list/links = list()
	links += mining_menu_link(holder, "mining", "LOCAL MINING MISSION")
	links += mining_menu_link(holder, "salvage", "SALVAGE MISSION")
	links += mining_menu_link(holder, "remote", remote_forbidden ? "ALLOW REMOTE CONTROL" : "FORBID REMOTE CONTROL")
	links += mining_menu_link(holder, "satellite", "TRAVEL TO THE SATELLITE")
	if(has_last_location && !is_at_ruins())
		links += mining_menu_link(holder, "revisit", "REVISIT LAST LOCATION")
	if(is_away())
		links += mining_menu_link(holder, "station", "RETURN TO STATION")
	links += mining_menu_link(holder, "cancel", "(CANCEL)")
	to_chat(user, render_menu(holder, links))

/datum/mining_expedition_controller/proc/show_remote_menu(mob/user, atom/holder)
	var/list/links = list()
	links += mining_menu_link(holder, "mining", "LOCAL MINING MISSION")
	links += mining_menu_link(holder, "salvage", "SALVAGE MISSION")
	links += mining_menu_link(holder, "satellite", "TRAVEL TO THE SATELLITE")
	links += mining_menu_link(holder, "cancel", "(CANCEL)")
	to_chat(user, render_menu(holder, links))

/datum/mining_expedition_controller/proc/handle_menu_action(mob/user, list/href_list, remote = FALSE)
	var/action = href_list["action"]
	switch(action)
		if("mining")
			start_mission(user, FALSE)
		if("salvage")
			start_mission(user, TRUE)
		if("remote")
			if(remote)
				return FALSE
			toggle_remote(user)
		if("satellite")
			travel_satellite(user)
		if("revisit")
			if(remote)
				return FALSE
			revisit(user)
		if("station")
			if(remote)
				return FALSE
			return_station(user)
		if("cancel")
			cancel_mission(user)
		else
			return FALSE
	return TRUE

/obj/machinery/computer/shuttle_control/mining/expedition
	name = "mining shuttle console"

/obj/machinery/computer/shuttle_control/mining/expedition/attack_hand(mob/user)
	if(inoperable(MAINT) || user.incapacitated())
		return
	if(!allowed(user))
		to_chat(user, "<span class='warning'>Access Denied.</span>")
		return
	add_fingerprint(user)
	show_menu(user)

/obj/machinery/computer/shuttle_control/mining/expedition/proc/show_menu(mob/user)
	var/datum/mining_expedition_controller/C = get_mining_expedition()
	var/list/links = list()
	links += mining_menu_link(src, "mining", "LOCAL MINING MISSION")
	links += mining_menu_link(src, "salvage", "SALVAGE MISSION")
	links += mining_menu_link(src, "remote", C.remote_forbidden ? "ALLOW REMOTE CONTROL" : "FORBID REMOTE CONTROL")
	links += mining_menu_link(src, "satellite", "TRAVEL TO THE SATELLITE")
	if(C.has_last_location && !C.is_at_ruins())
		links += mining_menu_link(src, "revisit", "REVISIT LAST LOCATION")
	if(C.is_away())
		links += mining_menu_link(src, "station", "RETURN TO STATION")
	links += mining_menu_link(src, "cancel", "(CANCEL)")
	to_chat(user, C.render_menu(src, links))

/obj/machinery/computer/shuttle_control/mining/expedition/OnTopic(var/mob/user, var/href_list)
	if(stat & (BROKEN|NOPOWER))
		return TOPIC_HANDLED
	if(!allowed(user))
		to_chat(user, "<span class='warning'>Access Denied.</span>")
		return TOPIC_HANDLED
	var/datum/mining_expedition_controller/C = get_mining_expedition()
	switch(href_list["action"])
		if("mining")
			C.start_mission(user, FALSE)
		if("salvage")
			C.start_mission(user, TRUE)
		if("remote")
			C.toggle_remote(user)
		if("satellite")
			C.travel_satellite(user)
		if("revisit")
			C.revisit(user)
		if("station")
			C.return_station(user)
		if("cancel")
			C.cancel_mission(user)
		else
			return TOPIC_HANDLED
	playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)
	return TOPIC_HANDLED

/obj/machinery/computer/mining_shuttle_comms
	name = "mining shuttle communications console"
	desc = "A long-range uplink used by command to direct the mining shuttle."
	icon_keyboard = "tech_key"
	icon_screen = "comm_monitor"

/obj/machinery/computer/mining_shuttle_comms/attack_hand(mob/user)
	if(..())
		return
	if(!user.GetAccess(ACCESS_REGION_COMMAND))
		to_chat(user, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
		return
	var/datum/mining_expedition_controller/C = get_mining_expedition()
	if(C.remote_forbidden)
		to_chat(user, "<span class='warning'>REMOTE CONTROL LOCKED BY SHUTTLE.</span>")
		return
	var/list/links = list()
	links += mining_menu_link(src, "mining", "LOCAL MINING MISSION")
	links += mining_menu_link(src, "salvage", "SALVAGE MISSION")
	links += mining_menu_link(src, "satellite", "TRAVEL TO THE SATELLITE")
	links += mining_menu_link(src, "cancel", "(CANCEL)")
	to_chat(user, C.render_menu(src, links))

/obj/machinery/computer/mining_shuttle_comms/OnTopic(var/mob/user, var/href_list)
	if(stat & (BROKEN|NOPOWER))
		return TOPIC_HANDLED
	if(!user.GetAccess(ACCESS_REGION_COMMAND))
		to_chat(user, "<span class='warning'>ACCESS DENIED: Command authorization required.</span>")
		return TOPIC_HANDLED
	var/datum/mining_expedition_controller/C = get_mining_expedition()
	if(C.remote_forbidden)
		to_chat(user, "<span class='warning'>REMOTE CONTROL LOCKED BY SHUTTLE.</span>")
		return TOPIC_HANDLED
	switch(href_list["action"])
		if("mining")
			C.start_mission(user, FALSE)
		if("salvage")
			C.start_mission(user, TRUE)
		if("satellite")
			C.travel_satellite(user)
		if("cancel")
			C.cancel_mission(user)
		else
			return TOPIC_HANDLED
	playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)
	return TOPIC_HANDLED

#undef MINING_SHUTTLE_TAG
#undef MINING_STATION_LANDMARK
#undef MINING_RUINS_LANDMARK
#undef MINING_SATELLITE_LANDMARK
