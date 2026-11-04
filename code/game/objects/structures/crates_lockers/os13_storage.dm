/obj/structure/closet/crate/os13
	name = "equipment chest"
	icon = 'icons/os13/objects/objects/storage.dmi'
	icon_state = "box3"
	icon_closed = "box3"
	icon_opened = "box3open"
	var/open_animation = "box3_opening"
	var/close_animation = "box3_closing"

/obj/structure/closet/crate/os13/Initialize()
	. = ..()
	update_icon()

/obj/structure/closet/crate/os13/open()
	. = ..()
	if(. && open_animation)
		flick(open_animation, src)

/obj/structure/closet/crate/os13/close()
	. = ..()
	if(. && close_animation)
		flick(close_animation, src)

/obj/structure/closet/crate/os13/ancient
	name = "ancient storage chest"
	icon_state = "ancientclosed"
	icon_closed = "ancientclosed"
	icon_opened = "ancientopen"
	open_animation = null
	close_animation = null

/obj/structure/closet/crate/os13/wood
	name = "wooden storage chest"
	icon_state = "gold"
	icon_closed = "gold"
	icon_opened = "goldopen"
	open_animation = null
	close_animation = null

/obj/structure/closet/crate/os13/wood/small
	name = "small wooden chest"
	icon_state = "cgold"
	icon_closed = "cgold"
	icon_opened = "cgoldopen"

/obj/structure/closet/crate/os13/wood/banded
	name = "banded wooden chest"
	icon_state = "bgold"
	icon_closed = "bgold"
	icon_opened = "bgoldopen"

/obj/structure/closet/crate/os13/wood/large
	name = "large wooden chest"
	icon_state = "dgold"
	icon_closed = "dgold"
	icon_opened = "dgoldopen"

/obj/structure/closet/crate/os13/equipment
	name = "metal equipment case"
	icon_state = "ecrate"
	icon_closed = "ecrate"
	icon_opened = "ecrateopen"
	open_animation = null
	close_animation = null

/obj/structure/closet/crate/os13/red
	name = "red storage case"
	icon_state = "redbox"
	icon_closed = "redbox"
	icon_opened = "redbox_open"
	open_animation = null
	close_animation = null

/obj/structure/closet/crate/os13/technical
	name = "technical equipment chest"
	icon_state = "tech"
	icon_closed = "tech"
	icon_opened = "techopen"
	open_animation = null
	close_animation = null

/obj/structure/closet/crate/os13/technical/alternate
	icon_state = "tech2"
	icon_closed = "tech2"
	icon_opened = "tech2open"

/obj/structure/closet/crate/os13/ornate
	name = "ornate storage chest"
	icon_state = "hchest"
	icon_closed = "hchest"
	icon_opened = "hchest_open"
	open_animation = null
	close_animation = null

/obj/structure/closet/crate/os13/cargo
	name = "cargo container"
	icon_state = "cargo1"
	icon_closed = "cargo1"
	icon_opened = "cargo0"
	open_animation = null
	close_animation = null

/obj/structure/closet/crate/os13/cargo/update_icon()
	..()
	if(opened)
		overlays += overlay_image(icon, "cargo0_ov", layer = ABOVE_HUMAN_LAYER)

/obj/structure/closet/crate/freezer/os13
	icon = 'icons/os13/objects/objects/storage.dmi'

/obj/structure/closet/crate/freezer/os13/Initialize()
	. = ..()
	update_icon()
