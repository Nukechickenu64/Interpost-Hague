// Physical item: ALIEN 00:02:40, FLT-01 in the operations audit.
// Navigation/range/activation choices are documented in os13_missing_objects.md.
GLOBAL_LIST_EMPTY(os13_distress_beacons)

/obj/item/device/os13_distress_beacon
	name = "Distress Beacon"
	desc = "It gives a chance to survive for those who've lost themselves in space."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "beacon"
	item_state = "beacon"
	item_icons = list(
		slot_l_hand_str = 'icons/os13/objects/objects/device.dmi',
		slot_r_hand_str = 'icons/os13/objects/objects/device.dmi',
		slot_wear_amulet_str = 'icons/os13/objects/objects/device.dmi'
	)
	w_class = ITEM_SIZE_SMALL
	slot_flags = SLOT_AMULET|SLOT_BELT
	var/active = TRUE

/obj/item/device/os13_distress_beacon/Initialize()
	. = ..()
	GLOB.os13_distress_beacons += src

/obj/item/device/os13_distress_beacon/Destroy()
	GLOB.os13_distress_beacons -= src
	return ..()

/obj/item/device/os13_distress_beacon/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("The distress transmitter is [active ? "on" : "off"]. Hold it to switch it [active ? "off" : "on"]."))

/obj/item/device/os13_distress_beacon/attack_self(mob/user)
	if(user.incapacitated() || (user.get_active_hand() != src && user.get_inactive_hand() != src))
		return
	active = !active
	add_fingerprint(user)
	to_chat(user, SPAN_NOTICE("You switch [active ? "on" : "off"] the Distress Beacon."))

/obj/item/device/os13_distress_beacon/proc/signal_available()
	return !QDELETED(src) && active && get_turf(src)

// This does not call the generic landmark's destructive landing-site repair.
// A distress signal supplies coordinates, not permission to bulldoze a room.
/proc/os13_rescue_footprint_clear(datum/shuttle/shuttle, turf/origin, area/landing_area)
	if(!shuttle?.current_location || !origin || !landing_area)
		return FALSE
	var/tiles = 0
	for(var/area/cabin in shuttle.shuttle_area)
		var/list/translation = shuttle.current_location.get_turf_translation_safe(get_turf(shuttle.current_location), origin, cabin.contents)
		for(var/source in translation)
			var/turf/target = translation[source]
			if(!istype(target, /turf/space) || get_area(target) != landing_area)
				return FALSE
			for(var/atom/movable/obstacle in target)
				if(ismob(obstacle) || obstacle.simulated)
					return FALSE
			tiles++
	return tiles > 0

/obj/item/device/os13_distress_beacon/proc/rescue_waypoint(datum/mining_expedition_controller/controller)
	if(!signal_available())
		return null
	var/datum/shuttle/autodock/shuttle = controller?.get_shuttle()
	var/turf/signal_origin = get_turf(src)
	if(!shuttle || (get_area(src) in shuttle.shuttle_area))
		return null
	// Nearest clear approach within twelve tiles. Do not overlap the beacon:
	// an unattended device can be on the floor beside the stranded person.
	for(var/radius = 1, radius <= 12, radius++)
		for(var/turf/candidate in orange(radius, signal_origin))
			if(get_dist(candidate, signal_origin) != radius || !istype(get_area(candidate), /area/space))
				continue
			if(!os13_rescue_footprint_clear(shuttle, candidate, get_area(candidate)))
				continue
			var/list/extents = get_shuttle_footprint_extents(shuttle)
			if(signal_origin.x >= candidate.x + extents[1] && signal_origin.x <= candidate.x + extents[3] && signal_origin.y >= candidate.y + extents[2] && signal_origin.y <= candidate.y + extents[4])
				continue
			var/obj/effect/shuttle_landmark/os13_rescue/approach = new(candidate)
			approach.rescue_shuttle = shuttle
			return approach
	return null

/obj/effect/shuttle_landmark/os13_rescue
	name = "Distress Beacon approach"
	base_turf = /turf/space
	var/datum/shuttle/autodock/rescue_shuttle

/obj/effect/shuttle_landmark/os13_rescue/Initialize()
	var/area/approach_area = get_area(src)
	base_area = approach_area.type
	landmark_tag = "os13_rescue_\ref[src]"
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/effect/shuttle_landmark/os13_rescue/is_valid(datum/shuttle/shuttle)
	return shuttle?.current_location != src && os13_rescue_footprint_clear(shuttle, get_turf(src), base_area)

/obj/effect/shuttle_landmark/os13_rescue/proc/in_use()
	// long_jump retains its departure waypoint as an emergency return site.
	// Keep it until the owning flight has finished, including its return leg.
	if(!QDELETED(rescue_shuttle) && (rescue_shuttle.moving_status != SHUTTLE_IDLE || rescue_shuttle.process_state != IDLE_STATE))
		return TRUE
	for(var/key in SSshuttle.shuttles)
		var/datum/shuttle/autodock/shuttle = SSshuttle.shuttles[key]
		if(shuttle.current_location == src || (istype(shuttle) && (shuttle.next_location == src || shuttle.landmark_transition == src)))
			return TRUE
	return FALSE

/obj/effect/shuttle_landmark/os13_rescue/Process()
	// Retain fixed plotted coordinates throughout transit and while docked,
	// even if the physical beacon is switched off or destroyed after launch.
	if(!in_use())
		qdel(src)

/obj/effect/shuttle_landmark/os13_rescue/Destroy()
	STOP_PROCESSING(SSobj, src)
	rescue_shuttle = null
	if(SSshuttle.registered_shuttle_landmarks[landmark_tag] == src)
		SSshuttle.registered_shuttle_landmarks -= landmark_tag
	return ..()

/datum/design/item/os13_distress_beacon
	name = "Distress Beacon"
	id = "os13_distress_beacon"
	req_tech = list(TECH_MAGNET = 1, TECH_ENGINEERING = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500, "glass" = 500)
	build_path = /obj/item/device/os13_distress_beacon
	sort_string = "VAACQ"
