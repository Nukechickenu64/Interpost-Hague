// Original supplied art, with real floor/wall/door behavior beneath it.
/turf/simulated/wall/os13
	icon = 'icons/os13/turf/turf/wwalls.dmi'
	icon_state = "rwall0"

/turf/simulated/wall/os13/update_icon()
	. = ..()
	if(!density)
		return
	overlays.Cut()
	var/connections = 0
	for(var/direction in list(NORTH, SOUTH, EAST, WEST))
		if(istype(get_step(src, direction), /turf/simulated/wall))
			connections |= direction
	icon = initial(icon)
	icon_state = "rwall[connections]"
	color = null
	if(damage && material)
		var/stage = clamp(round(damage / material.integrity * 6) + 1, 1, 7)
		overlays += image('icons/os13/turf/turf/walls.dmi', "damage[stage]")

/obj/structure/sign/os13_deck
	name = "deck number"
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "odeck1"

/obj/structure/sign/os13_label
	name = "department sign"
	icon = 'icons/os13/objects/objects/orbital_decor2.dmi'
	icon_state = "whiteboard"
	maptext_width = 96
	maptext_x = -32
	maptext_y = 8

/obj/structure/sign/os13_label/Initialize()
	. = ..()
	maptext = "<div style='text-align:center;font-size:7px;color:#bba3ed;background:#292336'>[html_encode(name)]</div>"

/obj/machinery/computer/hydroponics/os13

/obj/machinery/computer/hydroponics/os13/Initialize()
	. = ..()
	installed_chip = new /obj/item/device/waterchip(src)
	update_icon()

/area/os13
	name = "OS13"
	icon_state = "crew_quarters"
	base_turf = /turf/space
	has_gravity = 1

/area/os13/engineering
	name = "Deck 1 - Engineering"
/area/os13/medical
	name = "Deck 2 - Medical"
/area/os13/cargo
	name = "Deck 3 - Cargo"
/area/os13/hydroponics
	name = "Deck 3 - Hydroponics"
/area/os13/civilian
	name = "Deck 4 - Civilian"
/area/os13/kitchen
	name = "Deck 4 - Kitchen and Bar"
/area/os13/chapel
	name = "Deck 4 - Chapel"
/area/os13/security
	name = "Deck 5 - Security"
/area/os13/armory
	name = "Deck 5 - Armory"
/area/os13/research
	name = "Deck 6 - Research"
/area/os13/mezzanine
	name = "Research Mezzanine"
/area/os13/command
	name = "Deck 7 - Command"
/area/os13/solar
	name = "Solar Array"
	has_gravity = 0

/area/turbolift/os13
	lift_floor_label = "1"
	lift_floor_name = "Engineering"
/area/turbolift/os13/medical
	lift_floor_label = "2"
	lift_floor_name = "Medical"
/area/turbolift/os13/cargo
	lift_floor_label = "3"
	lift_floor_name = "Cargo and Hydroponics"
/area/turbolift/os13/civilian
	lift_floor_label = "4"
	lift_floor_name = "Civilian"
/area/turbolift/os13/security
	lift_floor_label = "5"
	lift_floor_name = "Security"
/area/turbolift/os13/research
	lift_floor_label = "6"
	lift_floor_name = "Research"
/area/turbolift/os13/mezzanine
	lift_floor_label = "6M"
	lift_floor_name = "Research Mezzanine"
/area/turbolift/os13/command
	lift_floor_label = "7"
	lift_floor_name = "Command"

/obj/turbolift_map_holder/os13
	name = "OS13 main lift"
	depth = 8
	lift_size_x = 4
	lift_size_y = 4
	floor_type = /turf/simulated/floor/tiled/no0
	wall_type = /turf/simulated/wall/os13
	areas_to_use = list(/area/turbolift/os13, /area/turbolift/os13/medical, /area/turbolift/os13/cargo, /area/turbolift/os13/civilian, /area/turbolift/os13/security, /area/turbolift/os13/research, /area/turbolift/os13/mezzanine, /area/turbolift/os13/command)
