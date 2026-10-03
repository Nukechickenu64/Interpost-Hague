PROCESSING_SUBSYSTEM_DEF(invaders)
	name = "Invaders"
	wait = 1
	// Not SS_BACKGROUND: reactions and step timing need to fire on schedule.
	flags = SS_POST_FIRE_TIMING|SS_NO_INIT
	var/list/station_areas

/datum/controller/subsystem/processing/invaders/proc/get_station_areas()
	if(!station_areas)
		station_areas = get_filtered_areas(GLOB.is_station_but_not_space_or_shuttle_area)
	return station_areas
