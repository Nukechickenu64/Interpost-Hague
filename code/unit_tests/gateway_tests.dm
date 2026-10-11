/datum/unit_test/movement/gateway_activation
	name = "GATEWAY - Activation and frame controls"

/datum/unit_test/movement/gateway_activation/start_test()
	var/turf/start = get_jetpack_test_turf()
	if(!start)
		fail("No empty region is available for the gateway test.")
		return TRUE
	var/obj/machinery/gateway/centerstation/center = new(start)
	var/list/frame = list()
	for(var/direction in GLOB.alldirs)
		var/obj/machinery/gateway/piece = new(get_step(start, direction))
		piece.set_dir(direction)
		piece.set_density(direction != SOUTH)
		frame += piece
	var/obj/machinery/gateway/entrance = locate() in get_step(start, SOUTH)
	var/mob/user = new(get_step(start, SOUTH))
	// Supply deterministic power without changing the surrounding area's grid.
	var/datum/power_node/supply = center.get_power_node()
	supply.on_bus = TRUE
	supply.bus_powered = TRUE
	center.wait = 0
	var/failure = ""

	if(!center.density || entrance.density)
		failure += "The center must be solid and the entrance must be passable.\n"
	center.attack_hand(user)
	if(!center.active || !center.ready || !center.hell_portal || !center.hell_arrival_turf)
		failure += "The first center click did not activate a complete powered gateway.\n"
	for(var/obj/machinery/gateway/piece in frame)
		if(!piece.active)
			failure += "Activation left a frame piece inactive.\n"

	var/obj/effect/portal/previous_portal = center.hell_portal
	entrance.attack_hand(user)
	if(center.active || center.hell_portal || (previous_portal && !QDELETED(previous_portal)))
		failure += "Clicking the entrance did not deactivate the gateway and remove its portal.\n"
	entrance.attack_hand(user)
	if(!center.active || !center.hell_portal)
		failure += "Clicking the entrance did not reactivate the gateway.\n"

	center.toggleoff()
	center.wait = world.time + 1 MINUTE
	entrance.attack_hand(user)
	if(center.active || center.hell_portal)
		failure += "The gateway activated before triangulation finished.\n"
	center.wait = 0
	supply.bus_powered = FALSE
	entrance.attack_hand(user)
	if(center.active || center.hell_portal)
		failure += "The gateway activated without power.\n"
	supply.bus_powered = TRUE

	var/obj/machinery/gateway/missing_piece = frame[1]
	var/turf/missing_location = get_turf(missing_piece)
	missing_piece.forceMove(null)
	entrance.attack_hand(user)
	if(center.active || center.ready || center.hell_portal)
		failure += "The gateway reused stale frame links after a piece was removed.\n"
	missing_piece.forceMove(missing_location)
	entrance.attack_hand(user)
	if(!center.active || !center.hell_portal)
		failure += "The repaired gateway did not activate on the next click.\n"

	supply.bus_powered = FALSE
	center.power_change()
	center.Process()
	if(center.active || center.hell_portal)
		failure += "Power loss left the gateway active.\n"
	supply.bus_powered = TRUE
	center.power_change()
	entrance.attack_hand(user)
	if(!center.active)
		failure += "The gateway did not recover after power was restored.\n"

	previous_portal = center.hell_portal
	qdel(center)
	if(previous_portal && !QDELETED(previous_portal))
		failure += "Deleting the center left its return portal behind.\n"
	for(var/obj/machinery/gateway/piece in frame)
		if(piece.active)
			failure += "Deleting the center left a frame piece active.\n"
		qdel(piece)
	qdel(user)
	if(failure)
		fail(failure)
	else
		pass("Center and frame clicks activate immediately; incomplete frames, triangulation, and power loss are handled correctly.")
	return TRUE
