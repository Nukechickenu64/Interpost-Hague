/obj/effect/shuttle_landmark/lifeboat
	name = "Lifeboat waypoint"
	autoset = TRUE

/obj/effect/shuttle_landmark/lifeboat/Destroy()
	if(SSshuttle.registered_shuttle_landmarks[landmark_tag] == src)
		SSshuttle.registered_shuttle_landmarks -= landmark_tag
	return ..()

/datum/shuttle/lifeboat
	category = /datum/shuttle/lifeboat
	sound_takeoff = 'sound/effects/rocket.ogg'
	var/obj/machinery/cryopod/lifepod/lifeboat/capsule
	var/obj/effect/shuttle_landmark/lifeboat/berth
	var/obj/effect/shuttle_landmark/lifeboat/escape_point

/datum/shuttle/lifeboat/New(obj/machinery/cryopod/lifepod/lifeboat/hull)
	capsule = hull
	berth = new(get_turf(hull))
	// The capsule is the entire hull. No station turfs or loose objects travel with it.
	shuttle_area = list()
	..("Lifeboat [random_id("lifeboats", 1, 9999)]", berth)

/datum/shuttle/lifeboat/Destroy()
	capsule = null
	QDEL_NULL(berth)
	QDEL_NULL(escape_point)
	return ..()

/datum/shuttle/lifeboat/proc/can_depart()
	return !QDELETED(capsule) && !capsule.launched && capsule.operable() && !QDELETED(berth) && capsule.loc == get_turf(berth)

/datum/shuttle/lifeboat/proc/secured_passenger()
	var/mob/living/passenger = capsule?.occupant
	if(istype(passenger) && passenger.stat != DEAD && passenger.loc == capsule && !capsule.releasing)
		return passenger

/datum/shuttle/lifeboat/proc/is_safe_landing(turf/destination)
	if(!istype(destination, /turf/space) || is_station_turf(destination))
		return FALSE
	for(var/atom/movable/obstacle in destination)
		if(obstacle.simulated)
			return FALSE
	return TRUE

/datum/shuttle/lifeboat/proc/launch()
	if(moving_status != SHUTTLE_IDLE || !can_depart() || !secured_passenger())
		return FALSE
	var/escape_z = GLOB.using_map.get_empty_zlevel()
	for(var/attempt in 1 to 10)
		var/turf/destination = locate(rand(TRANSITIONEDGE, world.maxx - TRANSITIONEDGE), rand(TRANSITIONEDGE, world.maxy - TRANSITIONEDGE), escape_z)
		if(!is_safe_landing(destination))
			continue
		escape_point = new(destination)
		if(attempt_move(escape_point))
			return TRUE
		QDEL_NULL(escape_point)
	return FALSE

/datum/shuttle/lifeboat/attempt_move(obj/effect/shuttle_landmark/destination)
	if(!can_depart() || !secured_passenger() || !is_safe_landing(get_turf(destination)))
		return FALSE
	return ..()

/datum/shuttle/lifeboat/shuttle_moved(obj/effect/shuttle_landmark/destination, list/turf_translation)
	if(moving_status == SHUTTLE_IDLE && sound_takeoff)
		playsound(capsule, sound_takeoff, 100)
	capsule.launched = TRUE
	capsule.forceMove(get_turf(destination))
	current_location = destination

/obj/machinery/cryopod/lifepod/lifeboat
	name = "lifeboat"
	desc = "A single-passenger evacuation shuttle with a sealed life-support capsule."
	var/datum/shuttle/lifeboat/shuttle

/obj/machinery/cryopod/lifepod/lifeboat/Initialize()
	. = ..()
	shuttle = new(src)

/obj/machinery/cryopod/lifepod/lifeboat/Destroy()
	QDEL_NULL(shuttle)
	return ..()

/obj/machinery/cryopod/lifepod/lifeboat/launch()
	return shuttle?.launch()
