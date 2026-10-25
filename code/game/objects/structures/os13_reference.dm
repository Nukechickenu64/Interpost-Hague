// Types identified directly in the water-chip recording. Keep the supplied
// icon states on real objects, so map placements survive runtime updates.
/obj/machinery/door/os13_office
	name = "office door"
	icon = 'icons/os13/objects/objects/doors/door3.dmi'
	icon_state = "door1"
	autoclose = 1

/obj/machinery/door/airlock/os13_corridor
	name = "corridor airlock"
	icon = 'icons/os13/objects/objects/doors/doormedglass2.dmi'

/obj/machinery/door/airlock/os13_maintenance
	name = "maintenance hatch"
	icon = 'icons/os13/objects/objects/doors/Doorhatchmaint.dmi'

/obj/machinery/light/small/os13_green_strip
	name = "green wall strip"
	desc = "A narrow green lamp marking the corridor."
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "tube1"
	base_state = "tube"
	color = "#64ff64"
	light_type = /obj/item/light/bulb/green

/obj/machinery/light/small/os13_wall
	name = "round wall lamp"
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "wall1"
	base_state = "wall"

/obj/machinery/light/small/os13_wall/green
	light_type = /obj/item/light/bulb/green

/obj/structure/sign/os13_reference_deck
	name = "deck number"
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "odeck3"

/obj/structure/sign/os13_station_emblem
	name = "station emblem"
	icon = 'icons/os13/objects/objects/decals.dmi'
	icon_state = "ntlogo"
	dir = NORTH

/obj/structure/sign/nt_answers/os13_reference
	icon = 'icons/os13/objects/objects/decals.dmi'

/obj/machinery/atmospherics/unary/vent_pump/os13_reference
	name = "square floor vent"
	icon = 'icons/obj/atmospherics/vent_pump.dmi'
	icon_state = "hoff7"
	use_power = POWER_USE_OFF

/obj/machinery/atmospherics/unary/vent_pump/os13_reference/update_icon(var/safety = 0)
	icon = initial(icon)
	overlays.Cut()
	if(welded)
		icon_state = "hweld4"
	else if((stat & (NOPOWER|BROKEN)) || !use_power)
		icon_state = "hoff7"
	else
		icon_state = pump_direction ? "hout6" : "hin5"

/obj/machinery/computer/os13_scanner
	name = "scanner console"
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "scanner"
	density = 1
	icon_keyboard = null
	icon_screen = null

/obj/machinery/computer/os13_scanner/update_icon()
	overlays.Cut()
	if(stat & NOPOWER)
		icon_state = "scanner0"
		set_light(0)
	else
		icon_state = (stat & BROKEN) ? "scannerb" : "scanner"
		set_light(light_range_on, light_power_on)

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

// The cross-bracing is visible through the walkway; it does not block walking.
/obj/structure/os13_walkway_bracing
	name = "walkway bracing"
	icon = 'icons/os13/objects/objects/structures.dmi'
	icon_state = "lattice"
	anchored = 1
	density = 0
	layer = ABOVE_TILE_LAYER

/obj/machinery/vending/coffee/os13_reference
	name = "coffee dispenser"
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "coffee"
	icon_vend = null
	icon_deny = null

/obj/machinery/vending/coffee/os13_reference/update_icon()
	// Supplied art uses coffee0, not the stock vending '-off' suffix.
	icon_state = (stat & (BROKEN|NOPOWER)) ? "coffee0" : "coffee"
