// Full production map and shuttle movement; no replacement transport backend.
/hook/startup/proc/os13_object_regression_log()
	fdel("tmp/os13-object-regression.log")
	world.log = file("tmp/os13-object-regression.log")
	return TRUE

SUBSYSTEM_DEF(os13_object_regression)
	name = "OS13 object regression"
	flags = SS_NO_FIRE
	init_order = -INFINITY

/datum/controller/subsystem/os13_object_regression/Initialize(timeofday)
	. = ..()
	spawn(0)
		var/datum/os13_object_regression/check = new
		check.check_objects()

/datum/os13_object_regression
	var/failures = 0
	var/datum/shuttle/autodock/shuttle
	var/datum/mining_expedition_controller/controller

/datum/os13_object_regression/proc/expect(condition, message)
	if(!condition)
		failures++
		world.log << "OS13_OBJECT_FAIL: [message]"
	return condition

/datum/os13_object_regression/proc/fly(obj/effect/shuttle_landmark/destination)
	if(!expect(controller.dispatch(destination, null, 1), "Dispatch to [destination] failed."))
		return FALSE
	shuttle.Process()
	sleep(2)
	expect(shuttle.moving_status == SHUTTLE_INTRANSIT && shuttle.current_location == shuttle.landmark_transition, "Flight skipped its real transit footprint.")
	for(var/i = 1, i <= 50, i++)
		shuttle.Process()
		if(controller.shuttle_is_idle(shuttle))
			break
		sleep(1)
	return expect(shuttle.current_location == destination && controller.shuttle_is_idle(shuttle), "Flight did not arrive and release its navigation lock.")

/datum/os13_object_regression/proc/check_objects()
	// Master.Initialize sets this back to TRUE for ordinary production builds.
	// Override after initialization so headless flights can advance their timers.
	world.sleep_offline = FALSE
	world.log << "OS13_OBJECT_REGRESSION_BEGIN"
	var/baseline_runtimes = GLOB.total_runtimes
	controller = get_mining_expedition()
	shuttle = controller.get_shuttle()
	if(!expect(shuttle && controller.is_home_dock(shuttle), "Stock Classic Scout did not initialize at its berth."))
		finish(baseline_runtimes)
		return
	shuttle.warmup_time = 0
	var/obj/effect/shuttle_landmark/home = shuttle.current_location
	var/obj/effect/shuttle_landmark/open_space = SSshuttle.get_landmark("mining_space")
	expect(GLOB.using_map.station_levels == list(1,2) || (length(GLOB.using_map.station_levels) == 2 && (1 in GLOB.using_map.station_levels) && (2 in GLOB.using_map.station_levels)), "Classic station levels do not match the two mapped decks.")
	var/seats = 0
	var/obj/structure/sofa/os13_scout/seat
	var/obj/machinery/computer/os13_scout_controls/controls
	var/obj/machinery/computer/os13_scout/comms
	var/tiles = 0
	for(var/area/cabin in shuttle.shuttle_area)
		for(var/turf/tile in cabin)
			tiles++
		for(var/obj/structure/sofa/os13_scout/candidate in cabin)
			seat = candidate
			seats++
		controls = locate() in cabin
		comms = locate() in cabin
	expect(tiles == 35 && seats == 4 && controls && comms, "Stock Scout lacks its complete footprint, four passenger seats or distinct controls.")
	if(!seat || !controls || !comms)
		finish(baseline_runtimes)
		return
	var/mob/living/carbon/human/passenger = new(get_turf(seat))
	expect(seat.buckle_mob(passenger), "Passenger could not buckle into the new seat.")
	controls.stat = 0
	controls.update_icon()
	expect(controls.icon_state == "rcomm" && controls.light_range > 0, "Flight controls lost their current powered console state.")
	controls.stat = NOPOWER
	controls.update_icon()
	expect(controls.icon_state == "rcomm0" && !controls.overlays.len && !controls.light_range, "Flight controls glow without power.")
	controls.stat = 0
	controls.update_icon()
	expect(controls.light_range > 0, "Flight-control light did not recover with power.")
	world.log << "OS13_OBJECT_CHECK: stock Scout and console composition"
	fly(open_space)
	expect(get_area(passenger) in shuttle.shuttle_area, "Flight left the passenger behind.")
	expect(passenger.buckled == seat && passenger.loc == seat.loc, "Flight separated the passenger from their seat.")
	expect(os13_scout_is_onboard(controls, controller) && os13_scout_is_onboard(comms, controller), "Consoles lost their craft link after movement.")
	expect(istype(get_turf(home), /turf/space), "Departure left duplicate ship flooring at home.")
	fly(home)
	expect(controls.x == 154 && controls.y == 145 && controls.z == 1, "Return did not restore the exact berth coordinates.")
	world.log << "OS13_OBJECT_CHECK: real departure, transit, passenger transport and return"

	var/turf/signal_origin = locate(60,180,1)
	var/obj/item/device/os13_distress_beacon/beacon = new(signal_origin)
	expect(beacon.signal_available() && (beacon in GLOB.os13_distress_beacons), "Physical beacon did not register a live signal.")
	beacon.active = FALSE
	expect(!beacon.signal_available() && !beacon.rescue_waypoint(controller), "Inactive beacon still supplies rescue navigation.")
	beacon.active = TRUE
	var/obj/effect/shuttle_landmark/os13_rescue/approach = beacon.rescue_waypoint(controller)
	if(expect(approach && approach.is_valid(shuttle), "Active beacon could not find a clear approach."))
		var/turf/blocked = get_turf(approach)
		var/area/original_area = get_area(blocked)
		var/mob/living/carbon/human/bystander = new(blocked)
		expect(!approach.is_valid(shuttle) && !QDELETED(bystander) && bystander.loc == blocked, "Rescue landing accepted or displaced a bystander.")
		qdel(bystander)
		var/obj/structure/closet/crate/obstacle = new(blocked)
		expect(!approach.is_valid(shuttle) && !QDELETED(obstacle), "Rescue landing erased or accepted a dense obstacle.")
		qdel(obstacle)
		var/obj/item/screwdriver/loose_tool = new(blocked)
		expect(!approach.is_valid(shuttle) && !QDELETED(loose_tool), "Rescue landing accepted a loose item that hull transfer could destroy.")
		qdel(loose_tool)
		blocked = blocked.ChangeTurf(/turf/simulated/wall)
		expect(!approach.is_valid(shuttle) && istype(blocked, /turf/simulated/wall) && get_area(blocked) == original_area, "Rescue navigation repaired terrain instead of refusing the site.")
		blocked.ChangeTurf(/turf/space)
		world.log << "OS13_OBJECT_CHECK: live/off signals and non-destructive approach validation"
		fly(approach)
		var/approach_tag = approach.landmark_tag
		qdel(beacon)
		expect(!(beacon in GLOB.os13_distress_beacons), "Destroyed beacon remained discoverable.")
		approach.Process()
		expect(!QDELETED(approach), "Beacon destruction deleted the Scout's occupied waypoint.")
		fly(home)
		approach.Process()
		expect(QDELETED(approach) && !SSshuttle.get_landmark(approach_tag), "Unused rescue waypoint leaked into navigation.")
		world.log << "OS13_OBJECT_CHECK: real rescue flight, beacon destruction and safe waypoint retirement"
	else
		qdel(beacon)
	qdel(passenger)
	var/mob/living/carbon/human/wearer = new(locate(154,142,1))
	var/obj/item/clothing/suit/space/trinet/suit = new(wearer)
	var/obj/item/clothing/head/helmet/space/trinet/intact = new(wearer)
	var/obj/item/clothing/head/helmet/space/trinet/broken/broken = new(wearer)
	wearer.equip_to_slot_if_possible(suit, slot_wear_suit)
	wearer.equip_to_slot_if_possible(intact, slot_head)
	expect(wearer.get_pressure_weakness() == 0, "Intact Tri-Net kit does not seal.")
	wearer.drop_from_inventory(intact)
	wearer.equip_to_slot_if_possible(broken, slot_head)
	expect(wearer.head == broken && wearer.get_pressure_weakness() == 1 && !(broken.item_flags & ITEM_FLAG_AIRTIGHT), "Broken helmet still supplies a pressure seal.")
	broken.on = TRUE
	broken.update_icon()
	expect(!broken.on && !broken.light_range && broken.icon_state == "broken_tspacehelmet", "Broken helmet gained an intact lamp or sprite.")
	world.log << "OS13_OBJECT_CHECK: broken helmet equipment, pressure protection and lamp"
	qdel(wearer)
	check_weapon_objects()
	check_remote_objects()
	check_medicine_objects()
	check_psychocorrection_objects()
	check_rax_objects()
	check_gravpulser_objects()
	check_stun_mine_objects()
	check_energy_arms_objects()
	finish(baseline_runtimes)

/datum/os13_object_regression/proc/finish(baseline_runtimes)
	expect(GLOB.total_runtimes == baseline_runtimes, "Regression actions caused a runtime error.")
	world.log << "OS13_OBJECT_REGRESSION_END: [failures] failures; [GLOB.total_runtimes - baseline_runtimes] new runtimes; [baseline_runtimes] startup runtimes"
	del(world)
