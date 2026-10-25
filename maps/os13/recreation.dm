// Video reconstruction built from the root os13.dmm shell.
#include "recreation_assets.dm"
#include "recreated.dmm"

/datum/map/os13
	parent_type = /datum/map/alpha
	name = "OS13"
	full_name = "Orbital Station 13"
	path = "os13"
	station_name = "Orbital Station 13"
	station_short = "OS13"
	station_levels = list(2,3,4,5,6,7,8,9)
	contact_levels = list(2,3,4,5,6,7,8,9)
	player_levels = list(2,3,4,5,6,7,8,9)
	map_levels = list(2,3,4,5,6,7,8,9)
	admin_levels = list(10)
	atmos_isolated_z_levels = list(1,10)
	accessible_z_levels = list("2"=1,"3"=1,"4"=1,"5"=1,"6"=1,"7"=1,"8"=1,"9"=1)

/datum/map/os13/setup_map()
	. = ..()
	station_name = "Orbital Station 13"
	station_short = "OS13"

// The shell's first level is space, not Alpha's generated asteroid.
/datum/map/os13/perform_map_generation()
	return TRUE
