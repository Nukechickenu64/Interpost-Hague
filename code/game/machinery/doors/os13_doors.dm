/obj/machinery/door
	var/os13_door_prefix = ""
	var/os13_door_closed_state
	var/os13_door_frame_state
	var/os13_door_animation
	var/os13_door_animation_serial = 0
	// Opt-in for OS13 door art kept outside the doors folder (turf/replicator sheets).
	var/os13_door_sheet = FALSE

/obj/machinery/door/set_dir(new_dir)
	. = ..()
	if(. && os13_door_states())
		update_icon()

/obj/machinery/door/proc/os13_door_states()
	if(!os13_door_sheet && findtext("[icon]", "icons/os13/objects/objects/doors/") != 1)
		return
	var/static/list/cache = list()
	var/key = "[icon]"
	if(!cache[key])
		cache[key] = icon_states(icon)
	return cache[key]

/obj/machinery/door/proc/os13_door_state(closed)
	var/list/states = os13_door_states()
	if(!states)
		return
	if(closed && os13_door_closed_state)
		return os13_door_closed_state
	if(os13_door_prefix)
		return "[os13_door_prefix][closed ? "1" : "0"]"
	if("door_closed" in states)
		return closed ? "door_closed" : "door_open"
	if("pdoor1" in states)
		return closed ? "pdoor1" : "pdoor0"
	if("mdoor1" in states)
		return closed ? "mdoor1" : "mdoor0"
	if("door1" in states)
		return closed ? "door1" : "door0"

/obj/machinery/door/proc/os13_door_lights_on()
	if(stat & (NOPOWER|BROKEN))
		return FALSE
	if(istype(src, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/A = src
		return A.arePowerSystemsOn()
	return powered()

/obj/machinery/door/proc/os13_door_part(state, part_layer, emissive = FALSE)
	var/image/part = image(icon, state, dir = dir)
	part.layer = part_layer
	// Foreground and light parts must not be flattened into the door leaf.
	part.appearance_flags |= KEEP_APART
	if(emissive)
		part.plane = ABOVE_LIGHTING_PLANE
		part.appearance_flags |= RESET_COLOR
	return part

/obj/machinery/door/proc/os13_update_door_icon()
	var/list/states = os13_door_states()
	if(!states)
		return FALSE
	var/state = os13_door_state(density)
	if(!state)
		return FALSE
	overlays.Cut()
	underlays.Cut()
	icon_state = state
	set_light(0)
	if(density && (stat & BROKEN))
		for(var/broken_state in list("door_broken", "doorb", "pdoor1_broken", "pdoor1b"))
			if(broken_state in states)
				icon_state = broken_state
				break
	if(istype(src, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/A = src
		if(density && A.locked && A.lights && A.arePowerSystemsOn() && ("door_locked" in states))
			icon_state = "door_locked"
			set_light(2, 0.75, COLOR_RED_LIGHT)
		if(A.welded)
			var/weld_state = density ? "welded" : "welded_open"
			if(weld_state in states)
				overlays += os13_door_part(weld_state, layer)
		if(A.p_open && ("panel_open" in states))
			overlays += os13_door_part("panel_open", layer)
	else if(istype(src, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/F = src
		if(density && F.lockdown && !(stat & BROKEN) && ("doorl" in states))
			icon_state = "doorl"
	for(var/lower in list("door_lower", "pdoor_u", "door_down", "door_down2"))
		if(lower in states)
			underlays += os13_door_part(lower, OPEN_DOOR_LAYER)
	if(("OO" in states) && !("pdoor_o" in states) && !("pdoor_u" in states))
		underlays += os13_door_part("OO", OPEN_DOOR_LAYER)
	for(var/foreground in list(os13_door_frame_state ? os13_door_frame_state : "door_overlay", "door_overlay2", "door_closedo", "pdoor_o", "door_up"))
		if(foreground in states)
			overlays += os13_door_part(foreground, ABOVE_HUMAN_LAYER)
	if(os13_door_lights_on())
		var/light_state
		if(os13_door_animation == "opening" && ("light_opening" in states))
			light_state = "light_opening"
		else if(os13_door_animation == "closing" && ("light_closing" in states))
			light_state = "light_closing"
		if(light_state)
			overlays += os13_door_part(light_state, ABOVE_LIGHTING_LAYER, TRUE)
		if("light" in states)
			overlays += os13_door_part("light", ABOVE_LIGHTING_LAYER, TRUE)
		if(os13_door_frame_state)
			var/indicator_state = "[os13_door_frame_state][density ? "1" : "0"]"
			if(indicator_state in states)
				overlays += os13_door_part(indicator_state, ABOVE_LIGHTING_LAYER, TRUE)
	SSradiation.resistance_cache.Remove(get_turf(src))
	return TRUE

/obj/machinery/door/proc/os13_animate_door(animation, duration = 10)
	var/list/states = os13_door_states()
	if(!states || !os13_door_state(density))
		return FALSE
	var/state
	switch(animation)
		if("opening", "closing")
			if(os13_door_prefix)
				state = "[os13_door_prefix]c[animation == "opening" ? "0" : "1"]"
			else if("door_closed" in states)
				state = "door_[animation]"
				if(p_open && ("o_[state]" in states))
					state = "o_[state]"
			else if("pdoor1" in states)
				state = "pdoorc[animation == "opening" ? "0" : "1"]"
			else if("mdoor1" in states)
				state = "mdoorc[animation == "opening" ? "0" : "1"]"
			else
				state = "doorc[animation == "opening" ? "0" : "1"]"
		if("deny")
			if(!density || !os13_door_lights_on())
				return TRUE
			state = "door_deny"
			if(!(state in states))
				state = ("mdoor_deny" in states) ? "mdoor_deny" : "door1_deny"
			var/deny_sound = 'sound/machines/buzz-two.ogg'
			if(istype(src, /obj/machinery/door/airlock))
				var/obj/machinery/door/airlock/A = src
				deny_sound = A.open_failure_access_denied
			playsound(src, deny_sound, 50, FALSE)
		if("spark")
			if(!density)
				return TRUE
			state = ("mdoor_spark" in states) ? "mdoor_spark" : "door_spark"
	if(state in states)
		os13_door_animation = animation
		var/serial = ++os13_door_animation_serial
		update_icon()
		flick(state, src)
		addtimer(CALLBACK(src, .proc/os13_finish_door_animation, serial), (animation in list("opening", "closing")) ? duration : 6)
	return TRUE

/obj/machinery/door/proc/os13_finish_door_animation(serial)
	if(serial != os13_door_animation_serial)
		return
	os13_door_animation = null
	update_icon()

/obj/machinery/door/airlock/os13
	name = "OS13 airlock"
	icon = 'icons/os13/objects/objects/doors/Doormaint.dmi'

/obj/machinery/door/airlock/os13/room
	icon = 'icons/os13/objects/objects/doors/b_room.dmi'

/obj/machinery/door/airlock/os13/electrical_hatch
	icon = 'icons/os13/objects/objects/doors/Doorhatchele2.dmi'

/obj/machinery/door/airlock/os13/maintenance_hatch
	icon = 'icons/os13/objects/objects/doors/Doorhatchmaint.dmi'

/obj/machinery/door/airlock/os13/hatch
	icon = 'icons/os13/objects/objects/doors/DoorHatchV2.dmi'

/obj/machinery/door/airlock/os13/maintenance
	icon = 'icons/os13/objects/objects/doors/Doormaint.dmi'

/obj/machinery/door/airlock/os13/engineering_glass
	icon = 'icons/os13/objects/objects/doors/doorengglass.dmi'
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/airlock/os13/medical_glass
	icon = 'icons/os13/objects/objects/doors/doormedglass.dmi'
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/airlock/os13/medical_glass/alternate
	icon = 'icons/os13/objects/objects/doors/doormedglass2.dmi'

/obj/machinery/door/airlock/os13/security_glass
	icon = 'icons/os13/objects/objects/doors/Doorsecglass2.dmi'
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/airlock/os13/tnc_engineering
	icon = 'icons/os13/objects/objects/doors/doorTNCeng.dmi'

/obj/machinery/door/airlock/os13/tnc_engineering/alternate
	icon = 'icons/os13/objects/objects/doors/doorTNCeng2.dmi'

/obj/machinery/door/airlock/os13/tnc_medical
	icon = 'icons/os13/objects/objects/doors/doorTNCmed.dmi'

/obj/machinery/door/airlock/os13/tnc_medical/alternate
	icon = 'icons/os13/objects/objects/doors/doorTNCmed2.dmi'

/obj/machinery/door/airlock/os13/inquisitor
	icon = 'icons/os13/objects/objects/doors/door_inqtrain.dmi'

/obj/machinery/door/airlock/os13/inquisitor/alternate
	icon = 'icons/os13/objects/objects/doors/door_inqtrain2.dmi'

/obj/machinery/door/airlock/os13/water_glass
	icon = 'icons/os13/objects/objects/doors/door_waterglass.dmi'
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/os13
	name = "OS13 door"
	icon = 'icons/os13/objects/objects/doors/1.dmi'
	autoclose = TRUE

/obj/machinery/door/os13/panel
	icon = 'icons/os13/objects/objects/doors/door2.dmi'

/obj/machinery/door/os13/office
	icon = 'icons/os13/objects/objects/doors/door3.dmi'

/obj/machinery/door/os13/office/alternate
	icon_state = "doora"
	os13_door_closed_state = "doora"
	os13_door_frame_state = "doorao"

/obj/machinery/door/os13/general
	icon = 'icons/os13/objects/objects/doors/doorgeneral.dmi'

/obj/machinery/door/os13/interior
	icon = 'icons/os13/objects/objects/doors/doorint.dmi'
	icon_state = "mdoor1"

/obj/machinery/door/os13/chapel_left
	icon = 'icons/os13/objects/objects/doors/doorchapel_left2.dmi'

/obj/machinery/door/os13/chapel_right
	icon = 'icons/os13/objects/objects/doors/doorchapel_right2.dmi'

/obj/machinery/door/os13/throne_left
	icon = 'icons/os13/objects/objects/doors/door_THRONE_left.dmi'

/obj/machinery/door/os13/throne_right
	icon = 'icons/os13/objects/objects/doors/door_THRONE_right.dmi'

/obj/machinery/door/os13/cave
	icon = 'icons/os13/objects/objects/doors/door_cave.dmi'

/obj/machinery/door/os13/cave/alternate
	os13_door_prefix = "xdoor"
	icon_state = "xdoor1"

/obj/machinery/door/os13/cave/two
	icon = 'icons/os13/objects/objects/doors/door_cave2.dmi'

/obj/machinery/door/os13/cave/two/alternate
	os13_door_prefix = "xdoor"
	icon_state = "xdoor1"

/obj/machinery/door/os13/cave/three
	icon = 'icons/os13/objects/objects/doors/door_cave3.dmi'

/obj/machinery/door/os13/cave/four
	icon = 'icons/os13/objects/objects/doors/door_cave4.dmi'

/obj/machinery/door/os13/cave/four/alternate
	os13_door_prefix = "xdoor"
	icon_state = "xdoor1"

/obj/machinery/door/os13/leviathan
	icon = 'icons/os13/objects/objects/doors/door_leviathan.dmi'

/obj/machinery/door/os13/prison
	icon = 'icons/os13/objects/objects/doors/door_prison.dmi'

/obj/machinery/door/os13/solitary
	icon = 'icons/os13/objects/objects/doors/door_solitary.dmi'
	var/slot_open = FALSE

/obj/machinery/door/os13/solitary/examine(mob/user)
	. = ..()
	to_chat(user, "<span class='notice'>Its viewing slot is [slot_open ? "open" : "shut"]. Alt-click to [slot_open ? "close" : "open"] it.</span>")

/obj/machinery/door/os13/solitary/AltClick(mob/user)
	if(!density || !CanPhysicallyInteract(user))
		return ..()
	slot_open = !slot_open
	os13_door_closed_state = slot_open ? "door1o" : null
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	user.visible_message("<span class='notice'>\The [user] [slot_open ? "slides open" : "shuts"] the viewing slot of \the [src].</span>")
	update_icon()

/obj/machinery/door/os13/gate
	name = "OS13 gate"
	icon = 'icons/os13/objects/objects/doors/gates1.dmi'

/obj/machinery/door/os13/gate/two
	icon = 'icons/os13/objects/objects/doors/gates2.dmi'

/obj/machinery/door/os13/gate/three
	icon = 'icons/os13/objects/objects/doors/gates3.dmi'

/obj/machinery/door/os13/gate/industrial
	icon = 'icons/os13/objects/objects/doors/sgates.dmi'

/obj/machinery/door/os13/gate/industrial/alternate
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/os13/gate/industrial/two
	icon = 'icons/os13/objects/objects/doors/sgates2.dmi'

/obj/machinery/door/os13/gate/industrial/two/alternate
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/os13/gate/industrial/three
	icon = 'icons/os13/objects/objects/doors/sgates3.dmi'

/obj/machinery/door/os13/gate/industrial/three/alternate
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/os13/gate/tech
	icon = 'icons/os13/objects/objects/doors/tgates1.dmi'

/obj/machinery/door/os13/gate/tech/alternate
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/os13/gate/tech/two
	icon = 'icons/os13/objects/objects/doors/tgates2.dmi'

/obj/machinery/door/os13/gate/tech/two/alternate
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/os13/gate/tech/three
	icon = 'icons/os13/objects/objects/doors/tgates3.dmi'

/obj/machinery/door/os13/gate/tech/three/alternate
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/blast/os13
	name = "OS13 shutter"
	icon = 'icons/os13/objects/objects/doors/rapid_pdoor.dmi'
	icon_state = "pdoor1"
	icon_state_closed = "pdoor1"
	icon_state_open = "pdoor0"
	icon_state_opening = "pdoorc0"
	icon_state_closing = "pdoorc1"

/obj/machinery/door/blast/os13/alternate
	icon = 'icons/os13/objects/objects/doors/rapid_pdoor2.dmi'

/obj/machinery/door/blast/os13/automatic
	icon = 'icons/os13/objects/objects/doors/autodoor.dmi'

/obj/machinery/door/blast/os13/brothel
	icon = 'icons/os13/objects/objects/doors/brothel_door.dmi'

/obj/machinery/door/blast/os13/elevator
	icon = 'icons/os13/objects/objects/doors/elevator.dmi'

/obj/machinery/door/blast/os13/warehouse
	icon = 'icons/os13/objects/objects/doors/warehouse_pdoor.dmi'

/obj/machinery/door/blast/os13/tnc
	icon = 'icons/os13/objects/objects/doors/door_tnc.dmi'

/obj/machinery/door/firedoor/os13
	icon = 'icons/os13/objects/objects/doors/door_fire2.dmi'
	icon_state = "door0"

/obj/machinery/door/window/os13
	icon = 'icons/os13/objects/objects/doors/windoor.dmi'

/obj/machinery/door/window/os13/update_icon()
	..()
	// A closed south-edge pane sits in front of anyone standing on the tile.
	if(density && dir == SOUTH)
		layer = ABOVE_HUMAN_LAYER

/obj/machinery/door/window/os13/right
	icon_state = "right"
	base_state = "right"

// ---------------------------------------------------------------------------
// OS13 door art outside the doors folder.
// ---------------------------------------------------------------------------

/obj/machinery/door/os13/shuttle
	name = "shuttle door"
	icon = 'icons/os13/turf/turf/shuttle.dmi'
	os13_door_sheet = TRUE

/obj/machinery/door/os13/replicator
	name = "replicator lab door"
	icon = 'icons/os13/replicator/labyrinth.dmi'
	os13_door_sheet = TRUE

/obj/machinery/door/blast/os13/portcullis
	name = "portcullis"
	desc = "A heavy iron grate that drops to seal the passage."
	icon = 'icons/os13/objects/objects/weapons/objects.dmi'
	icon_state = "portcullis1"
	icon_state_closed = "portcullis1"
	icon_state_open = "portcullis0"
	icon_state_opening = "portcullis10"
	icon_state_closing = "portcullis01"
	opacity = FALSE
	glass = TRUE
	os13_see_through = TRUE
	open_sound = 'sound/machines/shutters_open.ogg'
	close_sound = 'sound/machines/shutters_close.ogg'

/obj/machinery/door/blast/os13/portcullis/update_icon()
	overlays.Cut()
	underlays.Cut()
	icon_state = density ? icon_state_closed : icon_state_open
	if(!density)
		// The raised grate's teeth hang in front of anyone passing under it.
		icon_state = ""
		overlays += os13_door_part(icon_state_open, ABOVE_HUMAN_LAYER)
		underlays += os13_door_part("portculliso", OPEN_DOOR_LAYER)
	SSradiation.resistance_cache.Remove(get_turf(src))

/obj/machinery/door/blast/os13/portcullis/Initialize()
	. = ..()
	update_icon()

/obj/machinery/door/blast/os13/portcullis/open
	begins_closed = FALSE

// ---------------------------------------------------------------------------
// OS13-sprite variants of legacy door types placed on the OS13 maps. They
// keep the legacy behaviour (keypad codes, ID shutters, docking control) and
// only swap the art to the supplied OS13 sheets.
// ---------------------------------------------------------------------------

/obj/machinery/door/airlock/door3/os13
	icon = 'icons/os13/objects/objects/doors/door3.dmi'
	icon_state = "door1"

/obj/machinery/door/airlock/maintenance/os13
	icon = 'icons/os13/objects/objects/doors/Doormaint.dmi'

/obj/machinery/door/airlock/research/os13
	icon = 'icons/os13/objects/objects/doors/doorTNCeng.dmi'

/obj/machinery/door/airlock/hatch/os13
	icon = 'icons/os13/objects/objects/doors/Doorhatchele2.dmi'

/obj/machinery/door/airlock/command/os13
	icon = 'icons/os13/objects/objects/doors/DoorHatchV2.dmi'

/obj/machinery/door/airlock/keypad/os13
	icon = 'icons/os13/objects/objects/doors/b_room.dmi'

/obj/machinery/door/airlock/external/os13
	icon = 'icons/os13/objects/objects/doors/door_waterglass.dmi'
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/airlock/cone/os13
	icon = 'icons/os13/objects/objects/doors/doorgeneral.dmi'
	icon_state = "door1"

/obj/machinery/door/airlock/doorgeneral2/os13
	icon = 'icons/os13/objects/objects/doors/doorgeneral.dmi'
	icon_state = "door1"

/obj/machinery/door/airlock/security/os13
	icon = 'icons/os13/objects/objects/doors/Doorsecglass2.dmi'
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/blast/iddoor/os13
	icon = 'icons/os13/objects/objects/doors/autodoor.dmi'
	icon_state = "pdoor1"
	icon_state_closed = "pdoor1"
	icon_state_open = "pdoor0"
	icon_state_opening = "pdoorc0"
	icon_state_closing = "pdoorc1"

/obj/machinery/door/blast/iddoor/os13/open
	begins_closed = FALSE

/obj/machinery/door/blast/shutters/os13
	icon = 'icons/os13/objects/objects/doors/warehouse_pdoor.dmi'
	icon_state = "pdoor1"
	icon_state_closed = "pdoor1"
	icon_state_open = "pdoor0"
	icon_state_opening = "pdoorc0"
	icon_state_closing = "pdoorc1"

/obj/machinery/door/blast/shutters/os13/open
	begins_closed = FALSE

// ---------------------------------------------------------------------------
// Remote-controlled blast-door versions of every OS13 door above. They share
// the layered/emissive renderer and support buttons, wifi, and airlock controllers.
// ---------------------------------------------------------------------------

/obj/machinery/door/blast/os13
	var/os13_see_through = FALSE

/obj/machinery/door/blast/os13/set_opacity(new_opacity)
	return ..(os13_see_through ? FALSE : new_opacity)

/obj/machinery/door/blast/os13/remote
	name = "OS13 blast door"
	desc = "A reinforced door that only opens on a remote signal."
	icon = 'icons/os13/objects/objects/doors/1.dmi'
	icon_state = "door1"
	icon_state_closed = null
	icon_state_open = null
	icon_state_opening = null
	icon_state_closing = null
	maxhealth = 600
	block_air_zones = 1

/obj/machinery/door/blast/os13/remote/airlock
	icon = 'icons/os13/objects/objects/doors/Doormaint.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/room
	icon = 'icons/os13/objects/objects/doors/b_room.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/electrical_hatch
	icon = 'icons/os13/objects/objects/doors/Doorhatchele2.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/maintenance_hatch
	icon = 'icons/os13/objects/objects/doors/Doorhatchmaint.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/hatch
	icon = 'icons/os13/objects/objects/doors/DoorHatchV2.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/maintenance
	icon = 'icons/os13/objects/objects/doors/Doormaint.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/engineering_glass
	icon = 'icons/os13/objects/objects/doors/doorengglass.dmi'
	icon_state = "door_closed"
	os13_see_through = TRUE
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/blast/os13/remote/airlock/medical_glass
	icon = 'icons/os13/objects/objects/doors/doormedglass.dmi'
	icon_state = "door_closed"
	os13_see_through = TRUE
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/blast/os13/remote/airlock/medical_glass/alternate
	icon = 'icons/os13/objects/objects/doors/doormedglass2.dmi'
	icon_state = "door_closed"
	os13_see_through = TRUE
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/blast/os13/remote/airlock/security_glass
	icon = 'icons/os13/objects/objects/doors/Doorsecglass2.dmi'
	icon_state = "door_closed"
	os13_see_through = TRUE
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/blast/os13/remote/airlock/tnc_engineering
	icon = 'icons/os13/objects/objects/doors/doorTNCeng.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/tnc_engineering/alternate
	icon = 'icons/os13/objects/objects/doors/doorTNCeng2.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/tnc_medical
	icon = 'icons/os13/objects/objects/doors/doorTNCmed.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/tnc_medical/alternate
	icon = 'icons/os13/objects/objects/doors/doorTNCmed2.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/inquisitor
	icon = 'icons/os13/objects/objects/doors/door_inqtrain.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/inquisitor/alternate
	icon = 'icons/os13/objects/objects/doors/door_inqtrain2.dmi'
	icon_state = "door_closed"

/obj/machinery/door/blast/os13/remote/airlock/water_glass
	icon = 'icons/os13/objects/objects/doors/door_waterglass.dmi'
	icon_state = "door_closed"
	os13_see_through = TRUE
	glass = TRUE
	opacity = FALSE

/obj/machinery/door/blast/os13/remote/door
	icon = 'icons/os13/objects/objects/doors/1.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/panel
	icon = 'icons/os13/objects/objects/doors/door2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/office
	icon = 'icons/os13/objects/objects/doors/door3.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/office/alternate
	icon = 'icons/os13/objects/objects/doors/door3.dmi'
	icon_state = "doora"
	os13_door_closed_state = "doora"
	os13_door_frame_state = "doorao"

/obj/machinery/door/blast/os13/remote/door/general
	icon = 'icons/os13/objects/objects/doors/doorgeneral.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/interior
	icon = 'icons/os13/objects/objects/doors/doorint.dmi'
	icon_state = "mdoor1"

/obj/machinery/door/blast/os13/remote/door/chapel_left
	icon = 'icons/os13/objects/objects/doors/doorchapel_left2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/chapel_right
	icon = 'icons/os13/objects/objects/doors/doorchapel_right2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/throne_left
	icon = 'icons/os13/objects/objects/doors/door_THRONE_left.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/throne_right
	icon = 'icons/os13/objects/objects/doors/door_THRONE_right.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/cave
	icon = 'icons/os13/objects/objects/doors/door_cave.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/cave/alternate
	icon = 'icons/os13/objects/objects/doors/door_cave.dmi'
	icon_state = "xdoor1"
	os13_door_prefix = "xdoor"

/obj/machinery/door/blast/os13/remote/door/cave/two
	icon = 'icons/os13/objects/objects/doors/door_cave2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/cave/two/alternate
	icon = 'icons/os13/objects/objects/doors/door_cave2.dmi'
	icon_state = "xdoor1"
	os13_door_prefix = "xdoor"

/obj/machinery/door/blast/os13/remote/door/cave/three
	icon = 'icons/os13/objects/objects/doors/door_cave3.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/cave/four
	icon = 'icons/os13/objects/objects/doors/door_cave4.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/cave/four/alternate
	icon = 'icons/os13/objects/objects/doors/door_cave4.dmi'
	icon_state = "xdoor1"
	os13_door_prefix = "xdoor"

/obj/machinery/door/blast/os13/remote/door/leviathan
	icon = 'icons/os13/objects/objects/doors/door_leviathan.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/prison
	icon = 'icons/os13/objects/objects/doors/door_prison.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/solitary
	icon = 'icons/os13/objects/objects/doors/door_solitary.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate
	icon = 'icons/os13/objects/objects/doors/gates1.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/two
	icon = 'icons/os13/objects/objects/doors/gates2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/three
	icon = 'icons/os13/objects/objects/doors/gates3.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/industrial
	icon = 'icons/os13/objects/objects/doors/sgates.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/industrial/alternate
	icon = 'icons/os13/objects/objects/doors/sgates.dmi'
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/blast/os13/remote/door/gate/industrial/two
	icon = 'icons/os13/objects/objects/doors/sgates2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/industrial/two/alternate
	icon = 'icons/os13/objects/objects/doors/sgates2.dmi'
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/blast/os13/remote/door/gate/industrial/three
	icon = 'icons/os13/objects/objects/doors/sgates3.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/industrial/three/alternate
	icon = 'icons/os13/objects/objects/doors/sgates3.dmi'
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/blast/os13/remote/door/gate/tech
	icon = 'icons/os13/objects/objects/doors/tgates1.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/tech/alternate
	icon = 'icons/os13/objects/objects/doors/tgates1.dmi'
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/blast/os13/remote/door/gate/tech/two
	icon = 'icons/os13/objects/objects/doors/tgates2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/tech/two/alternate
	icon = 'icons/os13/objects/objects/doors/tgates2.dmi'
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/blast/os13/remote/door/gate/tech/three
	icon = 'icons/os13/objects/objects/doors/tgates3.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/gate/tech/three/alternate
	icon = 'icons/os13/objects/objects/doors/tgates3.dmi'
	icon_state = "door2"
	os13_door_closed_state = "door2"

/obj/machinery/door/blast/os13/remote/firedoor
	icon = 'icons/os13/objects/objects/doors/door_fire2.dmi'
	icon_state = "door1"

/obj/machinery/door/blast/os13/remote/door/shuttle
	icon = 'icons/os13/turf/turf/shuttle.dmi'
	icon_state = "door1"
	os13_door_sheet = TRUE

/obj/machinery/door/blast/os13/remote/door/replicator
	icon = 'icons/os13/replicator/labyrinth.dmi'
	icon_state = "door1"
	os13_door_sheet = TRUE
