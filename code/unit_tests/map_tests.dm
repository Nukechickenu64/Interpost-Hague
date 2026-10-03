/*
 *
 *  Map Unit Tests.
 *  Zone checks / APC / Scrubber / Vent / Cryopod Computers.
 *
 *
 */

#ifndef FAILURE
#define FAILURE 0
#endif
#ifndef SUCCESS
#define SUCCESS 1
#endif


/datum/unit_test/apc_area_test
	name = "MAP: Area Test APC / Scrubbers / Vents"


/datum/unit_test/apc_area_test/start_test()
	var/list/bad_areas = list()
	var/area_test_count = 0

	for(var/area/A in world)
		if(!A.z)
			continue
		if(!isPlayerLevel(A.z))
			continue
		area_test_count++
		var/area_good = 1
		var/bad_msg = "--------------- [A.name]([A.type])"

		var/exemptions = get_exemptions(A)
		if(!A.area_smes && !(exemptions & GLOB.using_map.NO_APC))
			log_bad("[bad_msg] lacks an area SMES marker.")
			area_good = 0
		else if(A.area_smes && (exemptions & GLOB.using_map.NO_APC))
			log_bad("[bad_msg] is not supposed to have an area power marker.")
			area_good = 0

		if(!A.air_scrub_info.len && !(exemptions & GLOB.using_map.NO_SCRUBBER))
			log_bad("[bad_msg] lacks an air scrubber.")
			area_good = 0
		else if(A.air_scrub_info.len && (exemptions & GLOB.using_map.NO_SCRUBBER))
			log_bad("[bad_msg] is not supposed to have an air scrubber.")
			area_good = 0

		if(!A.air_vent_info.len && !(exemptions & GLOB.using_map.NO_VENT))
			log_bad("[bad_msg] lacks an air vent.[ascii_reset]")
			area_good = 0
		else if(A.air_vent_info.len && (exemptions & GLOB.using_map.NO_VENT))
			log_bad("[bad_msg] is not supposed to have an air vent.")
			area_good = 0

		if(!area_good)
			bad_areas.Add(A)

	if(bad_areas.len)
		fail("\[[bad_areas.len]/[area_test_count]\]Some areas did not have the expected APC/vent/scrubber setup.")
	else
		pass("All \[[area_test_count]\] areas contained APCs, air scrubbers, and air vents.")

	return 1

/datum/unit_test/apc_area_test/proc/get_exemptions(var/area)
	// We assume deeper types come last
	for(var/i = GLOB.using_map.apc_test_exempt_areas.len; i>0; i--)
		var/exempt_type = GLOB.using_map.apc_test_exempt_areas[i]
		if(istype(area, exempt_type))
			return GLOB.using_map.apc_test_exempt_areas[exempt_type]

//=======================================================================================

/datum/unit_test/closet_test
	name = "MAP: Closet Capacity Test Player Z levels"

/datum/unit_test/closet_test/start_test()
	var/bad_tests = 0

	for(var/obj/structure/closet/C in world)
		if(!C.opened && isPlayerLevel(C.z))
			var/total_content_size = 0
			for(var/atom/movable/AM in C.contents)
				total_content_size += C.content_size(AM)
			if(total_content_size > C.storage_capacity)
				log_bad("[log_info_line(C)] contains more objects than able to hold ([total_content_size] / [C.storage_capacity]).")
				bad_tests++

	if(bad_tests)
		fail("\[[bad_tests]\] Some closets contained more objects than they were able to hold.")
	else
		pass("No overflowing closets found.")

	return 1

//=======================================================================================

/datum/unit_test/closet_containment_test
	name = "MAP: Closet Containment Test Player Z levels"

/datum/unit_test/closet_containment_test/start_test()
	var/bad_tests = 0

	for(var/obj/structure/closet/C in world)
		if(!C.opened && isPlayerLevel(C.z))
			var/contents_pre_open = C.contents.Copy()
			C.dump_contents()
			C.store_contents()
			var/list/no_longer_contained_atoms = contents_pre_open - C.contents
			var/list/previously_not_contained_atoms = C.contents - contents_pre_open

			if(no_longer_contained_atoms.len)
				bad_tests++
				log_bad("[log_info_line(C)] no longer contains the following atoms: [log_info_line(no_longer_contained_atoms)]")
			if(previously_not_contained_atoms.len)
				log_debug("[log_info_line(C)] now contains the following atoms: [log_info_line(previously_not_contained_atoms)]")

	if(bad_tests)
		fail("[bad_tests] closet\s with inconsistent pre/post-open contents found.")
	else
		pass("No closets with inconsistent pre/post-open contents found.")

	return 1

//=======================================================================================

/datum/unit_test/storage_map_test
	name = "MAP: On Map Storage Item Capacity Test Player Z levels"

/datum/unit_test/storage_map_test/start_test()
	var/bad_tests = 0

	for(var/obj/item/storage/S in world)
		if(isPlayerLevel(S.z))
			var/bad_msg = "[ascii_red]--------------- [S.name] \[[S.type]\] \[[S.x] / [S.y] / [S.z]\]"
			bad_tests += test_storage_capacity(S, bad_msg)

	if(bad_tests)
		fail("\[[bad_tests]\] Some on-map storage items were not able to hold their initial contents.")
	else
		pass("All on-map storage items were able to hold their initial contents.")

	return 1

/datum/unit_test/map_image_map_test
	name = "MAP: All map levels shall have a corresponding map image."

/datum/unit_test/map_image_map_test/start_test()
	var/failed = FALSE

	for(var/z in GLOB.using_map.map_levels)
		var/file_name = map_image_file_name(z)
		var/file_path = MAP_IMAGE_PATH + file_name
		if(!fexists(file_path))
			failed = TRUE
			log_unit_test("[GLOB.using_map.path]-[z] is missing its map image [file_name].")

	if(failed)
		fail("One or more map levels were missing a corresponding map image.")
	else
		pass("All map levels had a corresponding image.")

	return 1

//=======================================================================================

datum/unit_test/correct_allowed_spawn_test
	name = "MAP: All allowed_spawns entries should have spawnpoints on map."

datum/unit_test/correct_allowed_spawn_test/start_test()
	var/failed = FALSE

	for(var/spawn_name in GLOB.using_map.allowed_spawns)
		var/datum/spawnpoint/spawnpoint = spawntypes()[spawn_name]
		if(!spawnpoint)
			log_unit_test("Map allows spawning in [spawn_name], but [spawn_name] is null!")
			failed = TRUE
		else if(!spawnpoint.turfs.len)
			log_unit_test("Map allows spawning in [spawn_name], but [spawn_name] has no associated spawn turfs.")
			failed = TRUE

	if(failed)
		log_unit_test("Following spawn points exist:")
		for(var/spawnpoint in spawntypes())
			log_unit_test("\t[spawnpoint] ([any2ref(spawnpoint)])")
		log_unit_test("Following spawn points are allowed:")
		for(var/spawnpoint in GLOB.using_map.allowed_spawns)
			log_unit_test("\t[spawnpoint] ([any2ref(spawnpoint)])")
		fail("Some of the entries in allowed_spawns have no spawnpoint turfs.")
	else
		pass("All entries in allowed_spawns have spawnpoints.")

	return 1

//=======================================================================================

datum/unit_test/map_check
	name = "MAP: Map Check"

datum/unit_test/map_check/start_test()
	if(world.maxx < 1 || world.maxy < 1 || world.maxz < 1)
		fail("Unexpected map size. Was a map properly included?")
	else
		pass("Map size met minimum requirements.")
	return 1
//=======================================================================================

datum/unit_test/ladder_check
	name = "MAP: Ladder Check"

datum/unit_test/ladder_check/start_test()
	var/succeeded = TRUE
	for(var/obj/structure/ladder/L)
		if(L.allowed_directions & UP)
			succeeded = check_direction(L, GetAbove(L), UP, DOWN) && succeeded
		if(L.allowed_directions & DOWN)
			succeeded = check_direction(L, GetBelow(L), DOWN, UP) && succeeded
	if(succeeded)
		pass("All ladders are correctly setup.")
	else
		fail("One or more ladders are incorrectly setup.")

	return 1

/datum/unit_test/ladder_check/proc/check_direction(var/obj/structure/ladder/L, var/turf/destination_turf, var/check_direction, var/other_ladder_direction)
	if(!destination_turf)
		log_bad("Unable to acquire turf in the [dir2text(check_direction)] for [log_info_line(L)]")
		return FALSE
	var/obj/structure/ladder/other_ladder = (locate(/obj/structure/ladder) in destination_turf)
	if(!other_ladder)
		log_bad("Unable to acquire ladder in the direction [dir2text(check_direction)] for [log_info_line(L)]")
		return FALSE
	if(!(other_ladder.allowed_directions & other_ladder_direction))
		log_bad("The ladder in the direction [dir2text(check_direction)] is not allowed to connect to [log_info_line(L)]")
		return FALSE
	return TRUE

//=======================================================================================

/datum/unit_test/landmark_check
	name = "MAP: Landmark Check"

/datum/unit_test/landmark_check/start_test()
	var/safe_landmarks = 0
	var/space_landmarks = 0

	for(var/lm in landmarks_list)
		var/obj/effect/landmark/landmark = lm
		if(istype(landmark, /obj/effect/landmark/test/safe_turf))
			log_debug("Safe landmark found: [log_info_line(landmark)]")
			safe_landmarks++
		else if(istype(landmark, /obj/effect/landmark/test/space_turf))
			log_debug("Space landmark found: [log_info_line(landmark)]")
			space_landmarks++
		else if(istype(landmark, /obj/effect/landmark/test))
			log_debug("Test landmark with unknown tag found: [log_info_line(landmark)]")

	if(safe_landmarks != 1 || space_landmarks != 1)
		if(safe_landmarks != 1)
			log_bad("Found [safe_landmarks] safe landmarks. Expected 1.")
		if(space_landmarks != 1)
			log_bad("Found [space_landmarks] space landmarks. Expected 1.")
		fail("Expected exactly one safe landmark, and one space landmark.")
	else
		pass("Exactly one safe landmark, and exactly one space landmark found.")

	return 1

//=======================================================================================

/datum/unit_test/cryopod_comp_check
	name = "MAP: Cryopod Validity Check"

/datum/unit_test/cryopod_comp_check/start_test()
	var/pass = TRUE

	for(var/obj/machinery/cryopod/C in SSmachines.machinery)
		if(!C.control_computer)
			log_bad("[get_area(C)] lacks a cryopod control computer while holding a cryopod.")
			pass = FALSE

	for(var/obj/machinery/computer/cryopod/C in SSmachines.machinery)
		if(!(locate(/obj/machinery/cryopod) in get_area(C)))
			log_bad("[get_area(C)] lacks a cryopod while holding a control computer.")
			pass = FALSE

	if(pass)
		pass("All cryopods have their respective control computers.")
	else
		fail("Cryopods were not set up correctly.")

	return 1

//=======================================================================================

/datum/unit_test/camera_nil_c_tag_check
	name = "MAP: Camera nil c_tag check"

/datum/unit_test/camera_nil_c_tag_check/start_test()
	var/pass = TRUE

	for(var/obj/machinery/camera/C in world)
		if(!C.c_tag)
			log_bad("Following camera does not have a c_tag set: [log_info_line(C)]")
			pass = FALSE

	if(pass)
		pass("Have cameras have the c_tag set.")
	else
		fail("One or more cameras do not have the c_tag set.")

	return 1

//=======================================================================================

/datum/unit_test/camera_unique_c_tag_check
	name = "MAP: Camera unique c_tag check"

/datum/unit_test/camera_unique_c_tag_check/start_test()
	var/cameras_by_ctag = list()
	var/checked_cameras = 0

	for(var/obj/machinery/camera/C in world)
		if(!C.c_tag)
			continue
		checked_cameras++
		group_by(cameras_by_ctag, C.c_tag, C)

	var/number_of_issues = number_of_issues(cameras_by_ctag, "Camera c_tags", /decl/noi_feedback/detailed)
	if(number_of_issues)
		fail("[number_of_issues] issue\s with camera c_tags found.")
	else
		pass("[checked_cameras] camera\s have a unique c_tag.")

	return 1

//=======================================================================================

/datum/unit_test/legacy_atmospherics_shall_be_retired
	name = "MAP: Legacy atmospherics and disposal piping shall be retired"

/datum/unit_test/disposal_loading_size/start_test()
	var/obj/machinery/disposal/bin = new(null)
	var/mob/living/carbon/human/human = new(null)
	var/mob/living/simple_animal/mouse/mouse = new(null)
	var/obj/structure/closet/container = new(null)
	if(bin.can_load(human))
		fail("Disposal accepts a human directly.")
	else if(!bin.can_load(mouse))
		fail("Disposal rejects a mouse.")
	else
		human.forceMove(container)
		if(bin.can_load(container))
			fail("Disposal accepts a container holding a human.")
		else
			pass("Disposal restricts direct and nested living passengers.")
	qdel(bin)
	qdel(container)
	qdel(human)
	qdel(mouse)
	return 1

/datum/unit_test/legacy_atmospherics_shall_be_retired/start_test()
	var/failures = 0
	for(var/obj/machinery/atmospherics/machine in world)
		if(istype(machine, /obj/machinery/atmospherics/unary/vent_pump) || istype(machine, /obj/machinery/atmospherics/unary/vent_scrubber))
			continue
		log_bad("Legacy atmospheric machinery remains: [log_info_line(machine)]")
		failures++

	for(var/obj/structure/disposalpipe/pipe in world)
		log_bad("Legacy disposal pipe remains: [log_info_line(pipe)]")
		failures++
	for(var/obj/structure/disposaloutlet/outlet in world)
		log_bad("Legacy disposal outlet remains: [log_info_line(outlet)]")
		failures++
	for(var/obj/structure/disposalconstruct/construction in world)
		if(construction.ptype == 6 || construction.ptype == 8)
			continue
		log_bad("Unfinished disposal construction remains: [log_info_line(construction)]")
		failures++

	if(failures)
		fail("[failures] legacy atmospheric or disposal plumbing objects remain.")
	else
		pass("Legacy atmospheric and disposal piping is retired.")
	return 1

//=======================================================================================

/datum/unit_test/simple_pipes_shall_not_face_north_or_west // The init code is worthless and cannot handle it
	name = "MAP: Simple pipes shall not face north or west"

/datum/unit_test/simple_pipes_shall_not_face_north_or_west/start_test()
	var/failures = 0
	for(var/obj/machinery/atmospherics/pipe/simple/pipe in SSmachines.machinery)
		if(!istype(pipe, /obj/machinery/atmospherics/pipe/simple/hidden) && !istype(pipe, /obj/machinery/atmospherics/pipe/simple/visible))
			continue
		if(pipe.dir == NORTH || pipe.dir == WEST)
			log_bad("Following pipe had an invalid direction: [log_info_line(pipe)]")
			failures++

	if(failures)
		fail("[failures] simple pipe\s faced the wrong direction.")
	else
		pass("All simple pipes faced an appropriate direction.")
	return 1

//=======================================================================================

/datum/unit_test/shutoff_valves_shall_connect_to_two_different_pipe_networks
	name = "MAP: Shutoff valves shall connect to two different pipe networks"

/datum/unit_test/shutoff_valves_shall_connect_to_two_different_pipe_networks/start_test()
	var/failures = 0
	for(var/obj/machinery/atmospherics/valve/shutoff/SV in SSmachines.machinery)
		SV.close()
	for(var/obj/machinery/atmospherics/valve/shutoff/SV in SSmachines.machinery)
		if(SV.network_node1 == SV.network_node2)
			log_bad("Following shutoff valve does not connect to two different pipe networks: [log_info_line(SV)]")
			failures++

	if(failures)
		fail("[failures] shutoff valves did not connect to two different pipe networks.")
	else
		pass("All shutoff valves connect to two different pipe networks.")
	return 1

//=======================================================================================

/datum/unit_test/station_pipes_shall_not_leak
	name = "MAP: Station pipes shall not leak"

/datum/unit_test/station_pipes_shall_not_leak/start_test()
	var/failures = 0
	for(var/obj/machinery/atmospherics/pipe/P in SSmachines.machinery)
		if(P.leaking && isStationLevel(P.z))
			failures++
			log_bad("Following pipe is leaking: [log_info_line(P)]")

	if(failures)
		fail("[failures] station pipe\s leak.")
	else
		pass("No station pipes are leaking")
	return 1

#undef SUCCESS
#undef FAILURE
