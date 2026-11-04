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
	apply_directional_offset = FALSE

/obj/machinery/light/small/os13_wall/green
	light_type = /obj/item/light/bulb/green

/obj/structure/sign/os13_deck
	name = "deck marker"
	desc = "A wall-mounted marker displaying a deck number."
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "odeck1"

/obj/structure/sign/os13_deck/one
	name = "deck 1 marker"
	icon_state = "odeck1"

/obj/structure/sign/os13_deck/two
	name = "deck 2 marker"
	icon_state = "odeck2"

/obj/structure/sign/os13_deck/three
	name = "deck 3 marker"
	icon_state = "odeck3"

/obj/structure/sign/os13_deck/four
	name = "deck 4 marker"
	icon_state = "odeck4"

/obj/structure/sign/os13_deck/five
	name = "deck 5 marker"
	icon_state = "odeck5"

/obj/structure/sign/os13_deck/six
	name = "deck 6 marker"
	icon_state = "odeck6"

/obj/structure/sign/os13_deck/seven
	name = "deck 7 marker"
	icon_state = "odeck7"

/obj/structure/os13_wall_bar
	name = "wall bar"
	desc = "A wall-mounted bar fixture."
	icon = 'icons/os13/objects/objects/orbital_decor.dmi'
	icon_state = "nbar"
	anchored = TRUE
	density = FALSE

/obj/structure/closet/os13
	name = "storage closet"
	icon = 'icons/os13/objects/objects/closet.dmi'
	var/open_animation

/obj/structure/closet/os13/Initialize()
	. = ..()
	update_icon()

/obj/structure/closet/os13/update_icon()
	..()
	if(wall_mounted)
		density = FALSE
	overlays.Cut()
	if(welded && !opened)
		overlays += image('icons/obj/closet.dmi', "welded")

/obj/structure/closet/os13/open()
	. = ..()
	if(. && open_animation)
		flick(open_animation, src)

/obj/structure/closet/os13/nt
	name = "NT closet"
	icon_state = "nt"
	icon_closed = "nt"
	icon_opened = "ntopen"

/obj/structure/closet/os13/tnc
	name = "blue equipment closet"
	icon_state = "tnc"
	icon_closed = "tnc"
	icon_opened = "tncopen"

/obj/structure/closet/os13/tnc2
	name = "dark equipment closet"
	icon_state = "tnc2"
	icon_closed = "tnc2"
	icon_opened = "tnc2open"

/obj/structure/closet/os13/tnc2/damaged
	icon_state = "tnc2b"
	icon_closed = "tnc2b"
	icon_opened = "tnc2bopen"

/obj/structure/closet/os13/black
	name = "black equipment cabinet"
	icon_state = "black"
	icon_closed = "black"
	icon_opened = "blackopen"
	open_animation = "blackopening"

/obj/structure/closet/os13/suit
	name = "suit cabinet"
	icon_state = "ssuit"
	icon_closed = "ssuit"
	icon_opened = "ssuitopen"
	open_animation = "ssuitopening"

/obj/structure/closet/os13/bio
	name = "biohazard closet"
	icon_state = "bio"
	icon_closed = "bio"
	icon_opened = "bioopen"

/obj/structure/closet/os13/syndicate
	name = "red equipment closet"
	icon_state = "syndicate"
	icon_closed = "syndicate"

/obj/structure/closet/os13/emergency
	name = "emergency closet"
	icon_state = "emergency"
	icon_closed = "emergency"
	icon_opened = "emergencyopen"

/obj/structure/closet/os13/emergency/transparent
	icon_state = "temergency"
	icon_closed = "temergency"
	icon_opened = "temergency_open"

/obj/structure/closet/os13/medical
	name = "medical closet"
	icon_state = "medical"
	icon_closed = "medical"
	icon_opened = "medicalopen"

/obj/structure/closet/os13/medical/alternate
	icon_state = "medical1"
	icon_closed = "medical1"

/obj/structure/closet/os13/fridge
	name = "double-door refrigerator"
	icon_state = "fridge0"
	icon_closed = "fridge0"
	icon_opened = "fridge1open"

/obj/structure/closet/os13/fridge/update_icon()
	..()
	if(opened && icon_closed == "fridge0")
		overlays += "fridge2open"

/obj/structure/closet/os13/fridge/left
	name = "left refrigerator cabinet"
	icon_state = "fridge1"
	icon_closed = "fridge1"

/obj/structure/closet/os13/fridge/right
	name = "right refrigerator cabinet"
	icon_state = "fridge2"
	icon_closed = "fridge2"
	icon_opened = "fridge2open"

/obj/structure/closet/os13/wood
	name = "wooden wardrobe"
	icon_state = "nwood"
	icon_closed = "nwood"
	icon_opened = "nwoodopen"

/obj/structure/closet/os13/portal
	name = "ornate closet"
	icon_state = "portal"
	icon_closed = "portal"
	icon_opened = "portalopen"

/obj/structure/closet/os13/mining
	name = "mining closet"
	icon_state = "mining"
	icon_closed = "mining"
	icon_opened = "miningopen"

/obj/structure/closet/os13/witch
	name = "ornate wardrobe"
	icon_state = "witchcloset"
	icon_closed = "witchcloset"
	icon_opened = "witchcloset_open"

/obj/structure/closet/os13/fire
	name = "fire closet"
	icon_state = "firecloset"
	icon_closed = "firecloset"
	icon_opened = "fireclosetopen"

/obj/structure/closet/os13/emergency/compact
	name = "compact emergency cabinet"
	icon_state = "emerg"
	icon_closed = "emerg"
	icon_opened = "emerg1"
	wall_mounted = TRUE
	anchored = TRUE
	density = FALSE
	storage_types = CLOSET_STORAGE_ITEMS

/obj/structure/closet/os13/security
	name = "security closet"
	icon_state = "inqsec"
	icon_closed = "inqsec"
	icon_opened = "inqsecopen"

/obj/structure/closet/os13/security/alternate
	icon_state = "inqsec1"
	icon_closed = "inqsec1"

/obj/structure/closet/os13/security/offline
	icon_state = "inqsecoff"
	icon_closed = "inqsecoff"

/obj/structure/closet/os13/cabinet
	name = "storage cabinet"
	icon_state = "cabinet_closed"
	icon_closed = "cabinet_closed"
	icon_opened = "cabinet_open"

/obj/structure/closet/os13/dim
	name = "green closet"
	icon_state = "dim"
	icon_closed = "dim"
	icon_opened = "dimopen"

/obj/structure/closet/os13/cerberus
	name = "red storage cabinet"
	icon_state = "cerb"
	icon_closed = "cerb"
	icon_opened = "cerbo"

/obj/structure/closet/os13/cerberus/alternate
	icon_state = "cerb1"
	icon_closed = "cerb1"

/obj/structure/closet/os13/cerberus/offline
	icon_state = "cerboff"
	icon_closed = "cerboff"

/obj/structure/closet/os13/sarcophagus
	name = "ancient sarcophagus"
	icon_state = "ancient_sarcofagus"
	icon_closed = "ancient_sarcofagus"
	icon_opened = "portalopen"

/obj/structure/closet/os13/coffin
	name = "coffin"
	icon_state = "coffin"
	icon_closed = "coffin"
	icon_opened = "coffin_open"

/obj/structure/closet/os13/coffin/wood
	name = "wooden coffin"
	icon_state = "woodencoffin"
	icon_closed = "woodencoffin"
	icon_opened = "woodencoffin_open"

/obj/structure/closet/os13/cabinet/arched
	name = "arched cabinet"
	icon_state = "cabinet2_closed"
	icon_closed = "cabinet2_closed"
	icon_opened = "cabinet2_open"

/obj/structure/closet/os13/wood/rough
	name = "rough wooden closet"
	icon_state = "wooden"
	icon_closed = "wooden"
	icon_opened = "woodenopen"

/obj/structure/closet/os13/cabinet/plain
	name = "plain wooden cabinet"
	icon_state = "cabinet0_closed"
	icon_closed = "cabinet0_closed"
	icon_opened = "cabinet0_open"

/obj/structure/closet/os13/cabinet/paneled
	name = "paneled cabinet"
	icon_state = "cabinet1_closed"
	icon_closed = "cabinet1_closed"
	icon_opened = "cabinet1_open"

/obj/structure/closet/os13/emergency/compact/gray
	icon_state = "lemerg"
	icon_closed = "lemerg"
	icon_opened = "lemerg1"

/obj/structure/closet/os13/emergency/compact/dark
	icon_state = "lemerg2"
	icon_closed = "lemerg2"
	icon_opened = "lemerg3"

/obj/structure/closet/os13/mailbox
	name = "mailbox"
	icon_state = "mailbox0"
	icon_closed = "mailbox0"
	icon_opened = "mailbox1"
	storage_types = CLOSET_STORAGE_ITEMS

/obj/structure/closet/os13/organic
	name = "organic storage pod"
	icon_state = "fat"
	icon_closed = "fat"
	icon_opened = "fatopen"

/obj/structure/closet/os13/bloody
	name = "bloodstained closet"

/obj/structure/closet/os13/bloody/update_icon()
	..()
	overlays += "closetblood"

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
	add_os13_emissive()

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


// Decorative, non-functional replicator pads. They reuse the working
// Replicator platform's animated art for set dressing on maps.
/obj/structure/os13_replicator_pad
	name = "replicator platform"
	desc = "A matter replication platform. This one is decommissioned and doesn't respond."
	icon = 'icons/os13/replicator/labyrinth.dmi'
	icon_state = "chair"
	anchored = 1
	density = 0
	layer = ABOVE_TILE_LAYER

/obj/structure/os13_replicator_pad/inert
	desc = "A matter replication platform. This one is powered down and doesn't respond."
	icon_state = "chair2"

/obj/structure/os13_replicator_prop
	name = "replicator"
	desc = "A non-functional matter replication device."
	icon = 'icons/os13/objects/objects/miscobjs.dmi'
	icon_state = "TheSingGen2"
	anchored = 1
	density = 1
	layer = ABOVE_TILE_LAYER

// Decorative ribbon wiring bolted to the deck. Automatically connects to
// adjacent wiring: straight runs, corners, junction-box ends, and tees.
/obj/structure/os13_floor_wires
	name = "floor wiring"
	desc = "A thick ribbon of insulated cables bolted to the deck, terminating in junction boxes."
	icon = 'icons/os13/objects/objects/machines/engine.dmi'
	icon_state = "4-8"
	anchored = 1
	density = 0
	layer = EXPOSED_WIRE_LAYER

/obj/structure/os13_floor_wires/Initialize()
	. = ..()
	update_wire_connections(TRUE)

/obj/structure/os13_floor_wires/Destroy()
	var/turf/T = loc
	. = ..()
	if(istype(T))
		for(var/direction in GLOB.cardinal)
			var/obj/structure/os13_floor_wires/W = locate() in get_step(T, direction)
			if(W && !QDELETED(W))
				W.update_wire_connections()

/obj/structure/os13_floor_wires/proc/update_wire_connections(var/propagate = FALSE)
	var/wire_dirs = 0
	for(var/direction in GLOB.cardinal)
		var/obj/structure/os13_floor_wires/W = locate() in get_step(src, direction)
		if(W && !QDELETED(W))
			wire_dirs |= direction
			if(propagate)
				W.update_wire_connections()
	overlays.Cut()
	switch(wire_dirs)
		if(0)
			icon_state = "4-8"
		if(NORTH)
			icon_state = "0-1"
		if(SOUTH)
			icon_state = "0-2"
		if(EAST)
			icon_state = "0-4"
		if(WEST)
			icon_state = "0-8"
		if(NORTH|SOUTH)
			icon_state = "1-2"
		if(EAST|WEST)
			icon_state = "4-8"
		if(NORTH|EAST)
			icon_state = "0,0"
		if(NORTH|WEST)
			icon_state = "1,0"
		if(SOUTH|EAST)
			icon_state = "0,1"
		if(SOUTH|WEST)
			icon_state = "1,1"
		// No dedicated tee/cross states exist, so layer a corner or a
		// crossing straight over the base run instead.
		if(NORTH|SOUTH|EAST)
			icon_state = "1-2"
			overlays += image(icon, "0,0")
		if(NORTH|SOUTH|WEST)
			icon_state = "1-2"
			overlays += image(icon, "1,0")
		if(NORTH|EAST|WEST)
			icon_state = "4-8"
			overlays += image(icon, "0,0")
		if(SOUTH|EAST|WEST)
			icon_state = "4-8"
			overlays += image(icon, "0,1")
		if(NORTH|SOUTH|EAST|WEST)
			icon_state = "4-8"
			overlays += image(icon, "1-2")

/obj/structure/os13_floor_door
	name = "floor door"
	desc = "A floor-mounted door that can be opened to allow passage downward."
	icon = 'icons/os13/objects/objects/doors/rapid_pdoor.dmi'
	icon_state = "pdoor1"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_TILE_LAYER
	obj_flags = OBJ_FLAG_NOFALL

	var/hatch_open = FALSE

/obj/structure/os13_floor_door/attack_hand(mob/user)
	. = ..()
	if(. || user.incapacitated())
		return

	hatch_open = !hatch_open
	if(hatch_open)
		obj_flags &= ~OBJ_FLAG_NOFALL
		icon_state = "pdoor0"
		flick("pdoorc0", src)
		user.visible_message("<span class='notice'>[user] opens [src].</span>", "<span class='notice'>You open [src].</span>")
		if(user.loc == loc)
			user.fall()
	else
		obj_flags |= OBJ_FLAG_NOFALL
		icon_state = "pdoor1"
		flick("pdoorc1", src)
		user.visible_message("<span class='notice'>[user] closes [src].</span>", "<span class='notice'>You close [src].</span>")
	add_fingerprint(user)
	return TRUE

/obj/structure/os13_floor_door/alternate
	name = "alternate floor door"
	icon = 'icons/os13/objects/objects/doors/rapid_pdoor2.dmi'
