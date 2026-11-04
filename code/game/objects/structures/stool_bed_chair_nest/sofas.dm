/obj/structure/sofa
	name = "comfy sofa"
	desc = "So lovely, uh."
	icon = 'icons/obj/furniture.dmi'
	icon_state = "sofa_right"
	anchored = TRUE
	can_buckle = TRUE

/obj/structure/sofa/left
	icon_state = "sofa_left"

/obj/structure/sofa/os13
	name = "station couch"
	desc = "An upholstered seat."
	icon = 'icons/os13/objects/objects/couch.dmi'
	icon_state = "couch2c"
	buckle_lying = FALSE

/obj/structure/sofa/os13/Initialize()
	. = ..()
	update_icon()

/obj/structure/sofa/os13/section_a
	icon_state = "couch2a"

/obj/structure/sofa/os13/section_b
	icon_state = "couch2b"

/obj/structure/sofa/os13/section_d
	name = "couch section"
	desc = "An extension of a sectional couch, without a separate seat."
	icon_state = "couch2d"
	can_buckle = FALSE

/obj/structure/sofa/os13/section_e
	name = "couch section"
	desc = "An extension of a sectional couch, without a separate seat."
	icon_state = "couch2e"
	can_buckle = FALSE

/obj/structure/sofa/os13/padded_left
	icon_state = "couch1a"

/obj/structure/sofa/os13/padded_right
	icon_state = "couch1b"

/obj/structure/sofa/os13/fancy
	name = "fancy couch"
	icon_state = "fancycouch"

/obj/structure/sofa/os13/armchair
	name = "upholstered armchair"
	icon_state = "couchie"

/obj/structure/sofa/os13/royal
	name = "ornate couch"
	icon_state = "royal"

/obj/structure/sofa/os13/old
	name = "old couch"
	icon_state = "old"

/obj/structure/sofa/os13/old/alternate
	icon_state = "old2"

/obj/structure/sofa/os13/rounded
	name = "rounded couch"
	icon_state = "orph"

/obj/structure/sofa/os13/rounded/alternate
	icon_state = "orph2"

/obj/structure/sofa/update_icon()
	..()
	if(src.dir == NORTH)
		src.layer = 5
	else
		src.layer = OBJ_LAYER

/obj/structure/sofa/black
	icon_state = "couchblack_middle"

/obj/structure/sofa/black/left
	icon_state = "couchblack_left"

/obj/structure/sofa/black/right
	icon_state = "couchblack_right"


/obj/structure/sofa/beige
	icon_state = "couchbeige_middle"

/obj/structure/sofa/beige/left
	icon_state = "couchbeige_left"

/obj/structure/sofa/beige/right
	icon_state = "couchbeige_right"

/obj/structure/sofa/brown
	icon_state = "couchbrown_middle"

/obj/structure/sofa/brown/left
	icon_state = "couchbrown_left"

/obj/structure/sofa/brown/right
	icon_state = "couchbrown_right"

/obj/structure/sofa/bench/church_right
	name = "bench"
	desc = "It's a bench."
	icon = 'icons/obj/objects.dmi'
	icon_state = "church_right"
	dir = 1
	layer = 3

/obj/structure/sofa/bench/church_center
	name = "bench"
	desc = "It's a bench."
	icon = 'icons/obj/objects.dmi'
	icon_state = "church_center"
	dir = 1
	layer = 3

/obj/structure/sofa/bench/church_left
	name = "bench"
	desc = "It's a bench."
	icon = 'icons/obj/objects.dmi'
	icon_state = "church_left"
	dir = 1
	layer = 3

/obj/structure/sofa/bench/os13
	name = "station bench"
	desc = "A metal-framed bench section."
	icon = 'icons/obj/bench.dmi'
	icon_state = "12"
	dir = EAST
	layer = OBJ_LAYER
	buckle_lying = 0
	buckle_dir = SOUTH

/obj/structure/sofa/bench/os13/update_icon()
	// These sections have no backrest to draw over a seated occupant.
	layer = OBJ_LAYER

/obj/structure/sofa/bench/os13/vertical
	icon_state = "3"
	dir = SOUTH
	buckle_dir = WEST

/obj/structure/sofa/bench/os13/single
	icon_state = "0"

/obj/structure/sofa/bench/os13/end
	icon_state = "4"

/obj/structure/sofa/bench/os13/end/right
	icon_state = "8"
	dir = WEST

/obj/structure/sofa/bench/os13/end/top
	icon_state = "2"
	dir = SOUTH
	buckle_dir = WEST

/obj/structure/sofa/bench/os13/end/bottom
	icon_state = "1"
	dir = NORTH
	buckle_dir = WEST

/obj/structure/sofa/bench/os13/corner
	icon_state = "10"
	dir = SOUTHWEST

/obj/structure/sofa/bench/os13/corner/top_left
	icon_state = "6"
	dir = SOUTHEAST

/obj/structure/sofa/bench/os13/corner/bottom_left
	icon_state = "5"
	dir = NORTHEAST

/obj/structure/sofa/bench/os13/corner/bottom_right
	icon_state = "9"
	dir = NORTHWEST

/obj/structure/sofa/bench/os13/junction
	icon_state = "15"

/obj/structure/sofa/bench/os13/junction/north
	icon_state = "13"

/obj/structure/sofa/bench/os13/junction/south
	icon_state = "14"

/obj/structure/sofa/bench/os13/junction/east
	icon_state = "7"
	buckle_dir = WEST

/obj/structure/sofa/bench/os13/junction/west
	icon_state = "11"
	buckle_dir = EAST
