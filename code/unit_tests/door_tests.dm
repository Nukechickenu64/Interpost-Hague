/datum/unit_test/door_occupancy
	name = "DOORS - Physical occupants block non-crushing closes"

/datum/unit_test/door_occupancy/start_test()
	var/turf/test_turf = get_safe_turf()
	var/mob/living/carbon/human/occupant = new(test_turf)
	var/list/door_types = list(/obj/machinery/door/unpowered/simple, /obj/machinery/door/firedoor, /obj/machinery/door/window, /obj/machinery/door/blast)
	for(var/door_type in door_types)
		var/obj/machinery/door/door = new door_type(test_turf)
		door.set_density(FALSE)
		if(istype(door, /obj/machinery/door/blast))
			var/obj/machinery/door/blast/blast = door
			blast.force_close()
		else
			door.close()
		if(door.density)
			fail("[door_type] closed over a living mob.")
		qdel(door)
	qdel(occupant)
	if(!reported)
		pass("All non-crushing door types stayed open over a physical mob.")
	return TRUE

/datum/unit_test/door_ghost
	name = "DOORS - Observers do not block closing"

/datum/unit_test/door_ghost/start_test()
	var/turf/test_turf = get_safe_turf()
	var/obj/machinery/door/door = new(test_turf)
	door.set_density(FALSE)
	var/mob/observer/ghost/observer = new(test_turf)
	door.close()
	if(!door.density)
		fail("An observer blocked a door from closing.")
	else
		pass("An observer did not block closing.")
	qdel(observer)
	qdel(door)
	return TRUE

/datum/unit_test/door_late_arrival
	name = "DOORS - Late occupants block closing"

/datum/unit_test/door_late_arrival/start_test()
	var/turf/test_turf = get_safe_turf()
	var/obj/machinery/door/door = new(test_turf)
	door.set_density(FALSE)
	spawn(1)
		var/mob/living/carbon/human/occupant = new(test_turf)
		spawn(4)
			qdel(occupant)
	door.close()
	if(door.density)
		fail("A door enclosed a mob that arrived during its closing animation.")
	else
		pass("A late arrival prevented closure.")
	qdel(door)
	return TRUE

/datum/unit_test/door_airlock
	name = "DOORS - Safe airlocks wait for occupants"

/datum/unit_test/door_airlock/start_test()
	var/turf/test_turf = get_safe_turf()
	var/obj/machinery/door/airlock/door = new(test_turf)
	door.set_density(FALSE)
	door.autoclose = FALSE
	var/mob/living/carbon/human/occupant = new(test_turf)
	door.close(TRUE)
	if(door.density)
		fail("A safe airlock closed over a living mob.")
	qdel(occupant)
	door.close(TRUE)
	if(!door.density)
		fail("A safe airlock could not close after the mob left.")
	if(!reported)
		pass("A safe airlock waited for the occupant to leave.")
	qdel(door)
	return TRUE