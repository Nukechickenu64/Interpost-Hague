/obj/structure/vehicleparts/frame/wood
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 90

/obj/structure/vehicleparts/frame/defaultarmored/lwall
	w_left = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/rwall
	w_right = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/fwall
	w_front = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/bwall
	w_back = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/ldoor
	w_left = list("c_door",TRUE,TRUE,20,45,TRUE,TRUE)

/obj/structure/vehicleparts/frame/defaultarmored/rdoor
	w_right = list("c_door",TRUE,TRUE,20,45,TRUE,TRUE)

/obj/structure/vehicleparts/frame/defaultarmored/fdoor
	w_front = list("c_door",TRUE,TRUE,20,45,TRUE,TRUE)

/obj/structure/vehicleparts/frame/defaultarmored/bdoor
	w_back = list("c_door",TRUE,TRUE,20,45,TRUE,TRUE)

/obj/structure/vehicleparts/frame/defaultarmored/lwall/armored
	w_left = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/rwall/armored
	w_right = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/fwall/armored
	w_front = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/bwall/armored
	w_back = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/rb
	w_right = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/lb
	w_left = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/rf
	w_right = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)
	w_front = list("c_armoredfront",FALSE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/lf
	w_left = list("c_wall",TRUE,TRUE,20,50,FALSE,FALSE)
	w_front = list("c_armoredfront",FALSE,TRUE,20,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/rb/armored
	w_right = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)
	w_back = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/lb/armored
	w_left = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)
	w_back = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/rf/armored
	w_right = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/defaultarmored/lf/armored
	w_left = list("c_armoredwall",TRUE,TRUE,55,90,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,55,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car

/obj/structure/vehicleparts/frame/car/lf/truck
	w_left = list("c_windoweddoor",TRUE,TRUE,0,4,TRUE,TRUE)
	w_front = list("c_windshield",FALSE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/rf/truck
	w_right = list("c_windoweddoor",TRUE,TRUE,0,4,TRUE,TRUE)
	w_front = list("c_windshield",FALSE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/lf/truck/armored
	w_left = list("c_windoweddoor",TRUE,TRUE,10,25,TRUE,TRUE)
	w_front = list("c_armoredfront",FALSE,TRUE,15,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/rf/truck/armored
	w_right = list("c_windoweddoor",TRUE,TRUE,10,25,TRUE,TRUE)
	w_front = list("c_armoredfront",FALSE,TRUE,15,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/mercedes/lf
	w_left = list("c_windoweddoor",TRUE,TRUE,10,25,TRUE,TRUE)
	w_front = list("c_windshield",FALSE,TRUE,5,20,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/mercedes/rf
	w_right = list("c_windoweddoor",TRUE,TRUE,10,25,TRUE,TRUE)
	w_front = list("c_windshield",FALSE,TRUE,5,20,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/tigr/lf
	w_left = list("c_windoweddoor",TRUE,TRUE,10,30,TRUE,TRUE)
	w_front = list("c_windshield2",FALSE,TRUE,10,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/tigr/rf
	w_right = list("c_windoweddoor",TRUE,TRUE,10,30,TRUE,TRUE)
	w_front = list("c_windshield2",FALSE,TRUE,10,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/tigr/rb
	w_right = list("c_windoweddoor",TRUE,TRUE,10,25,TRUE,TRUE)
	w_back = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/tigr/lb
	w_left = list("c_windoweddoor",TRUE,TRUE,10,25,TRUE,TRUE)
	w_back = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/l3
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'

/obj/structure/vehicleparts/frame/l3/lf
	w_front = list("c_wall",FALSE,TRUE,14,14,FALSE,FALSE,TRUE)
	w_left = list("c_wall",TRUE,TRUE,14,14,FALSE,FALSE,TRUE)
	override_roof_icon = "l3_barrel"

/obj/structure/vehicleparts/frame/l3/lf/cc
	w_front = list("c_wall",FALSE,TRUE,14,14,FALSE,FALSE,TRUE)
	w_left = list("c_wall",TRUE,TRUE,14,14,FALSE,FALSE,TRUE)
	override_roof_icon = "l3cc_barrel"

/obj/structure/vehicleparts/frame/l3/rf
	w_front = list("c_wall",FALSE,TRUE,14,14,FALSE,FALSE,TRUE)
	w_right = list("c_wall",FALSE,TRUE,14,14,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/l3/lc
	w_front = list("l3_turret",TRUE,TRUE,14,14,FALSE,FALSE,TRUE)
	w_left = list("c_wall",TRUE,TRUE,14,14,FALSE,FALSE)
	override_frame_icon = "l3_turret"

/obj/structure/vehicleparts/frame/l3/rc
	w_front = list("l3_driver_port",TRUE,TRUE,14,14,FALSE,FALSE)
	w_right = list("c_door",FALSE,TRUE,14,14,TRUE,TRUE)
	override_frame_icon = "l3_driver_port"

/obj/structure/vehicleparts/frame/l3/lb
	w_left = list("c_wall",TRUE,TRUE,14,14,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,8,8,FALSE,FALSE)

/obj/structure/vehicleparts/frame/l3/rb
	w_right = list("c_wall",TRUE,TRUE,14,14,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,8,8,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/front
	w_right = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_armoredfront",FALSE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/bonnetcenter
	w_front = list("c_armoredfront",FALSE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/back
	w_right = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/bootleft
	w_left = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_back = list("c_door",TRUE,TRUE,0,0.1,TRUE,TRUE)

/obj/structure/vehicleparts/frame/car/bootright
	w_right = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_back = list("c_door",TRUE,TRUE,0,0.1,TRUE,TRUE)

/obj/structure/vehicleparts/frame/car/bootleft/closed
	w_left = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/bootright/closed
	w_right = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/bootcenter
	w_back = list("c_door",TRUE,TRUE,0,0.1,TRUE,TRUE)

/obj/structure/vehicleparts/frame/car/left
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 90
	noroof = TRUE
	w_left = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/right
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 90
	noroof = TRUE
	w_right = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/left/armored
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 90
	noroof = TRUE
	w_left = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/right/armored
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 90
	noroof = TRUE
	w_right = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/left/metal
	name = "steel frame"
	desc = "A steel vehicle frame."
	icon_state = "frame_steel"
	resistance = 150
	noroof = FALSE
	w_left = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/left/metalreinforced
	name = "steel frame"
	desc = "A steel vehicle frame."
	icon_state = "frame_steel"
	resistance = 150
	noroof = FALSE
	w_left = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/right/metal
	name = "steel frame"
	desc = "A steel vehicle frame."
	icon_state = "frame_steel"
	resistance = 150
	noroof = FALSE
	w_right = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/rb
	w_right = list("c_windoweddoor",TRUE,TRUE,5,0.1,TRUE,TRUE)
	w_back = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/lb
	w_left = list("c_windoweddoor",TRUE,TRUE,5,0.1,TRUE,TRUE)
	w_back = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/rf
	w_right = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/lf
	w_left = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_wall",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/rb/armored
	w_right = list("c_windoweddoor",TRUE,TRUE,5,30,TRUE,TRUE)
	w_back = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/lb/armored
	w_left = list("c_windoweddoor",TRUE,TRUE,5,30,TRUE,TRUE)
	w_back = list("c_wall",TRUE,TRUE,10,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/rf/armored
	w_right = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)
	w_front = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/lf/armored
	w_left = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)
	w_front = list("c_wall",TRUE,TRUE,10,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/van/lf
	w_front = list("vanfront_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanfront_left"
	icon_state = "frame_steel_corner_lf"

/obj/structure/vehicleparts/frame/car/van/cf
	w_front = list("vanfront_centerU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanfront_center"
	icon_state = "frame_steel_corner_cf"

/obj/structure/vehicleparts/frame/car/van/rf
	w_front = list("vanfront_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanfront_right"
	icon_state = "frame_steel_corner_rf"

/obj/structure/vehicleparts/frame/car/van/lfc
	w_front = list("vanwindshield2door_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "vanwindshield2door_left"

/obj/structure/vehicleparts/frame/car/van/rfc
	w_front = list("vanwindshield2door_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "vanwindshield2door_right"

/obj/structure/vehicleparts/frame/car/van/cfc
	w_front = list("truckwindshield_center",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/van/lb
	w_back = list("vanback_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanback_left"
	icon_state = "frame_steel_corner_lb"

/obj/structure/vehicleparts/frame/car/van/cb
	w_back = list("vanback_centerU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "vanback_center"
	icon_state = "frame_steel_corner_cb"

/obj/structure/vehicleparts/frame/car/van/rb
	w_back = list("vanback_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanback_right"
	icon_state = "frame_steel_corner_rb"

/obj/structure/vehicleparts/frame/car/piccolino/lf
	w_front = list("as_piccolino_front_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "as_piccolino_front_left"
	removesroof = TRUE
	icon_state = "frame_steel_corner_lf"

/obj/structure/vehicleparts/frame/car/piccolino/rf
	w_front = list("as_piccolino_front_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "as_piccolino_front_right"
	removesroof = TRUE
	icon_state = "frame_steel_corner_rf"

/obj/structure/vehicleparts/frame/car/piccolino/lb
	w_back = list("as_piccolino_back_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_thin",FALSE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "as_piccolino_back_left"
	icon_state = "frame_steel_corner_lb"

/obj/structure/vehicleparts/frame/car/piccolino/rb
	w_back = list("as_piccolino_back_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_thin",FALSE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "as_piccolino_back_right"
	icon_state = "frame_steel_corner_rb"

/obj/structure/vehicleparts/frame/car/piccolino/lc
	w_front = list("vanwindshield2door_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "vanwindshield2door_left"

/obj/structure/vehicleparts/frame/car/piccolino/rc
	w_front = list("vanwindshield2door_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "vanwindshield2door_right"

/obj/structure/vehicleparts/frame/car/quattroporte/lf
	w_front = list("as_quattroporte_front_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "as_quattroporte_front_left"
	removesroof = TRUE
	icon_state = "frame_steel_corner_lf"

/obj/structure/vehicleparts/frame/car/quattroporte/rf
	w_front = list("as_quattroporte_front_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "as_quattroporte_front_right"
	removesroof = TRUE
	icon_state = "frame_steel_corner_rf"

/obj/structure/vehicleparts/frame/car/quattroporte/lb
	w_back = list("as_quattroporte_back_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "as_quattroporte_back_left"
	icon_state = "frame_steel_corner_lb"

/obj/structure/vehicleparts/frame/car/quattroporte/rb
	w_back = list("as_quattroporte_back_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "as_quattroporte_back_right"
	icon_state = "frame_steel_corner_rb"

/obj/structure/vehicleparts/frame/car/quattroporte/lc
	w_front = list("carwindshield2door_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_left"

/obj/structure/vehicleparts/frame/car/quattroporte/rc
	w_front = list("carwindshield2door_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_right"

/obj/structure/vehicleparts/frame/car/umek/lf
	w_front = list("um_erstenklasse_front_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	removesroof = TRUE
	hasoverlay = "um_erstenklasse_front_left"
	icon_state = "frame_steel_corner_lf"

/obj/structure/vehicleparts/frame/car/umek/rf
	w_front = list("um_erstenklasse_front_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	removesroof = TRUE
	icon_state = "frame_steel_corner_rf"
	hasoverlay = "um_erstenklasse_front_right"

/obj/structure/vehicleparts/frame/car/umek/lfc
	w_front = list("carwindshield2door_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_left"

/obj/structure/vehicleparts/frame/car/umek/rfc
	w_front = list("carwindshield2door_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_right"

/obj/structure/vehicleparts/frame/car/umek/rbc
	w_right = list("c_windoweddoor",TRUE,TRUE,5,0.1,TRUE,FALSE)
	w_back = list("c_thin",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/umek/lbc
	w_left = list("c_windoweddoor",TRUE,TRUE,5,0.1,TRUE,FALSE)
	w_back = list("c_thin",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/umek/lb
	icon_state = "frame_steel_corner_lb"
	w_back = list("um_erstenklasse_back_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "um_erstenklasse_back_left"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/umek/rb
	icon_state = "frame_steel_corner_rb"
	w_back = list("um_erstenklasse_back_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "um_erstenklasse_back_right"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/falcon/lf
	icon_state = "frame_steel_corner_lf"
	w_front = list("smc_falcon_front_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE,TRUE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "smc_falcon_front_left"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/falcon/rf
	icon_state = "frame_steel_corner_rf"
	w_front = list("smc_falcon_front_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "smc_falcon_front_right"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/falcon/lfc
	w_front = list("carwindshield2door_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_left"

/obj/structure/vehicleparts/frame/car/falcon/rfc
	w_front = list("carwindshield2door_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_right"

/obj/structure/vehicleparts/frame/car/falcon/rbc
	w_right = list("c_windoweddoor",TRUE,TRUE,5,0.1,TRUE,FALSE)
	w_back = list("c_thin",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/falcon/lbc
	w_left = list("c_windoweddoor",TRUE,TRUE,5,0.1,TRUE,FALSE)
	w_back = list("c_thin",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/falcon/lb
	icon_state = "frame_steel_corner_lb"
	w_back = list("smc_falcon_back_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "smc_falcon_back_left"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/falcon/rb
	icon_state = "frame_steel_corner_rb"
	w_back = list("smc_falcon_back_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "smc_falcon_back_right"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/wyoming/lf
	icon_state = "frame_steel_corner_lf"
	w_front = list("truckfront2_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "truckfront2_left"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/wyoming/rf
	icon_state = "frame_steel_corner_rf"
	w_front = list("truckfront2_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "truckfront2_right"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/wyoming/lfc
	w_left = list("none",TRUE,TRUE,0,4,TRUE,FALSE)
	w_front = list("vanwindshield2door_leftU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanwindshield2door_left"

/obj/structure/vehicleparts/frame/car/wyoming/rfc
	w_right = list("none",TRUE,TRUE,0,4,TRUE,FALSE)
	w_front = list("vanwindshield2door_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanwindshield2door_right"

/obj/structure/vehicleparts/frame/car/wyoming/rbc
	w_right = list("c_wall",TRUE,TRUE,5,0.1,FALSE,FALSE)
	w_front = list("c_thin",TRUE,TRUE,1,0.1,FALSE,FALSE)
	noroof = TRUE

/obj/structure/vehicleparts/frame/car/wyoming/lbc
	w_left = list("c_wall",TRUE,TRUE,5,0.1,FALSE,FALSE)
	w_front = list("c_thin",TRUE,TRUE,1,0.1,FALSE,FALSE)
	noroof = TRUE

/obj/structure/vehicleparts/frame/car/wyoming/lb
	icon_state = "frame_steel_corner_lb"
	w_back = list("truckback_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "carback2_left"
	removesroof = TRUE
	override_roof_icon = "truckback_left_closed"

/obj/structure/vehicleparts/frame/car/wyoming/rb
	icon_state = "frame_steel_corner_rb"
	w_back = list("truckback_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "carback2_right"
	removesroof = TRUE
	override_roof_icon = "truckback_right_closed"

/obj/structure/vehicleparts/frame/car/toyota/lf
	icon_state = "frame_steel_corner_lf"
	w_front = list("truckfront2_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "toyota2_left"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/toyota/rf
	icon_state = "frame_steel_corner_rf"
	w_front = list("truckfront2_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "toyota2_right"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/toyota/lfc
	w_left = list("c_windoweddoor",TRUE,TRUE,0,4,TRUE,FALSE)
	w_front = list("vanwindshield2door_leftU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanwindshield2door_left"

/obj/structure/vehicleparts/frame/car/toyota/rfc
	w_right = list("c_windoweddoor",TRUE,TRUE,0,4,TRUE,FALSE)
	w_front = list("vanwindshield2door_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "vanwindshield2door_right"

/obj/structure/vehicleparts/frame/car/toyota/lfcc
	w_left = list("c_windoweddoor",TRUE,TRUE,0,4,TRUE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota/rfcc
	w_right = list("c_windoweddoor",TRUE,TRUE,0,4,TRUE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota/lb
	icon_state = "frame_steel_corner_lb"
	w_back = list("truckback_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_thin",TRUE,TRUE,1,0.1,FALSE,FALSE)
	hasoverlay = "carback2_left"
	removesroof = TRUE
	override_roof_icon = "truckback_left_closed"

/obj/structure/vehicleparts/frame/car/toyota/rb
	icon_state = "frame_steel_corner_rb"
	w_back = list("truckback_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_thin",TRUE,TRUE,1,0.1,FALSE,FALSE)
	hasoverlay = "carback2_right"
	removesroof = TRUE
	override_roof_icon = "truckback_right_closed"

/obj/structure/vehicleparts/frame/car/toyota_armored/lf
	icon_state = "frame_steel_corner_lf"
	w_front = list("c_armoredwall",TRUE,TRUE,25,30,FALSE,FALSE)
	w_left = list("c_wall",TRUE,TRUE,25,30,TRUE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota_armored/rf
	icon_state = "frame_steel_corner_rf"
	w_front = list("c_armoredwall",TRUE,TRUE,25,30,FALSE,FALSE)
	w_right = list("c_wall",TRUE,TRUE,25,30,TRUE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota_armored/lfc
	w_left = list("c_door",TRUE,TRUE,25,30,TRUE,FALSE)
	w_front = list("c_window2",FALSE,TRUE,25,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota_armored/rfc
	w_right = list("c_door",TRUE,TRUE,25,30,TRUE,FALSE)
	w_front = list("c_window2",FALSE,TRUE,25,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota_armored/lfcc
	w_left = list("c_windoweddoor",TRUE,TRUE,25,30,TRUE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota_armored/rfcc
	w_right = list("c_windoweddoor",TRUE,TRUE,25,30,TRUE,FALSE)

/obj/structure/vehicleparts/frame/car/toyota_armored/lb
	icon_state = "frame_steel_corner_lb"
	w_back = list("truckback_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_thin",TRUE,TRUE,1,0.1,FALSE,FALSE)
	hasoverlay = "carback2_left"
	override_roof_icon = "truckback_left_closed"

/obj/structure/vehicleparts/frame/car/toyota_armored/rb
	icon_state = "frame_steel_corner_rb"
	w_back = list("truckback_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_front = list("c_thin",TRUE,TRUE,1,0.1,FALSE,FALSE)
	hasoverlay = "carback2_right"
	override_roof_icon = "truckback_right_closed"

/obj/structure/vehicleparts/frame/car/shinobu/lf
	w_front = list("carfront5_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	icon_state = "frame_steel_corner_lf"
	hasoverlay = "carfront5_left"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/shinobu/rf
	w_front = list("carfront5_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	icon_state = "frame_steel_corner_rf"
	hasoverlay = "carfront5_right"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/shinobu/lb
	w_back = list("carback1_leftU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	icon_state = "frame_steel_corner_lb"
	hasoverlay = "carback1_left"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/shinobu/rb
	w_back = list("carback1_rightU",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	icon_state = "frame_steel_corner_rb"
	hasoverlay = "carback1_right"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/shinobu/lcf
	w_front = list("carwindshield2door_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_left"

/obj/structure/vehicleparts/frame/car/shinobu/rcf
	w_front = list("carwindshield2door_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_right"

/obj/structure/vehicleparts/frame/car/shinobu/rbc
	w_right = list("c_windoweddoor",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_back = list("c_thin",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/shinobu/lbc
	w_left = list("c_windoweddoor",TRUE,TRUE,0,0.1,TRUE,FALSE)
	w_back = list("c_thin",TRUE,TRUE,0,0.1,FALSE,FALSE)

/obj/structure/vehicleparts/frame/car/kazoku/lf
	w_front = list("carfront3_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "carfront3_left"
	icon_state = "frame_steel_corner_lf"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/kazoku/rf
	w_front = list("carfront3_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "carfront3_right"
	icon_state = "frame_steel_corner_rf"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/kazoku/lb
	w_back = list("ys_back_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "ys_back_left"
	icon_state = "frame_steel_corner_lb"

/obj/structure/vehicleparts/frame/car/kazoku/rb
	w_back = list("ys_back_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "ys_back_right"
	icon_state = "frame_steel_corner_rb"

/obj/structure/vehicleparts/frame/car/kazoku/lc
	w_front = list("carwindshield2door_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_left"

/obj/structure/vehicleparts/frame/car/kazoku/rc
	w_front = list("carwindshield2door_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "carwindshield2door_right"

/obj/structure/vehicleparts/frame/car/type95/lf
	w_front = list("type95front_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "type95front_left"
	icon_state = "frame_steel_corner_lf_type95"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/type95/rf
	w_front = list("type95front_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "type95front_right"
	icon_state = "frame_steel_corner_rf_type95"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/type95/lb
	w_back = list("type95_back_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "type95_back_left"
	icon_state = "frame_steel_corner_lb_type95"

/obj/structure/vehicleparts/frame/car/type95/rb
	w_back = list("type95_back_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "type95_back_right"
	icon_state = "frame_steel_corner_rb_type95"

/obj/structure/vehicleparts/frame/car/type95/lc
	w_front = list("type95windshielddoor_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "type95windshielddoor_left"
	icon_state = "frame_steel_corner_clf_type95"

/obj/structure/vehicleparts/frame/car/type95/rc
	w_front = list("type95windshielddoor_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "type95windshielddoor_right"
	icon_state = "frame_steel_corner_crf_type95"

/obj/structure/vehicleparts/frame/car/type94/lf
	w_front = list("type94front_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "type94front_left"
	icon_state = "frame_steel_corner_lf_type95"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/type94/rf
	w_front = list("type94front_rightU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,FALSE,FALSE)
	hasoverlay = "type94front_right"
	icon_state = "frame_steel_corner_rf_type95"
	removesroof = TRUE

/obj/structure/vehicleparts/frame/car/type94/lc
	w_front = list("type94windshielddoor_leftU",TRUE,TRUE,0,0.1,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "type94windshielddoor_left"
	icon_state = "frame_steel_corner_clf_type95"

/obj/structure/vehicleparts/frame/car/type94/rc
	w_front = list("type94windshielddoor_rightU",FALSE,TRUE,0,0.1,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,0,0.1,TRUE,FALSE)
	hasoverlay = "type94windshielddoor_right"
	icon_state = "frame_steel_corner_crf_type95"

/obj/structure/vehicleparts/frame/panzervi

/obj/structure/vehicleparts/frame/panzervi/front
	w_front = list("c_armoredwall",FALSE,TRUE,102,130,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzervi/back
	w_back = list("c_wall",TRUE,TRUE,50,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzervi/left
	w_left = list("c_wall",TRUE,TRUE,70,80,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzervi/right
	w_right = list("c_wall",TRUE,TRUE,70,80,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzervi/back/door
	w_back = list("c_door",TRUE,TRUE,45,50,TRUE,TRUE)
	doorcode = 11940

/obj/structure/vehicleparts/frame/panzervi/rb
	w_right = list("c_wall",TRUE,TRUE,70,80,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,50,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzervi/lb
	w_left = list("c_wall",TRUE,TRUE,70,80,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,50,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzervi/rf
	w_right = list("c_wall",TRUE,TRUE,70,80,FALSE,FALSE)
	w_front = list("c_armoredfront2",FALSE,TRUE,102,130,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/panzervi/lf
	w_left = list("c_wall",TRUE,TRUE,70,80,FALSE,FALSE)
	w_front = list("c_armoredfront2",FALSE,TRUE,102,130,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzeriv

/obj/structure/vehicleparts/frame/panzeriv/front
	w_front = list("c_wall",TRUE,TRUE,45,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzeriv/back
	w_back = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzeriv/left
	w_left = list("c_wall",TRUE,TRUE,30,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzeriv/right
	w_right = list("c_wall",TRUE,TRUE,30,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzeriv/left/door
	w_left = list("c_door",TRUE,TRUE,26,28,TRUE,TRUE)
	doorcode = 11940

/obj/structure/vehicleparts/frame/panzeriv/right/door
	w_right = list("c_door",TRUE,TRUE,26,28,TRUE,TRUE)
	doorcode = 11940

/obj/structure/vehicleparts/frame/panzeriv/rb
	w_right = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzeriv/lb
	w_left = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/panzeriv/rf
	w_right = list("c_wall",TRUE,TRUE,35,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,45,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/panzeriv/lf
	w_left = list("c_wall",TRUE,TRUE,35,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,45,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t34
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/t34/front
	icon_state = "t34_frame_steel_front_middle"
	w_front = list("t34_front_middle_frame",TRUE,TRUE,80,80,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t34/back
	icon_state = "t34_frame_steel_back"
	w_back = list("t34_back_middle_frame",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t34/left
	icon_state = "t34_frame_steel_middle_front_left"
	w_left = list("t34_middle_front_left_frame",TRUE,TRUE,50,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/t34/fc
	icon_state = "t34_frame_steel_middle_front"

/obj/structure/vehicleparts/frame/t34/right
	icon_state = "t34_frame_steel_middle_front_right"
	w_right = list("t34_middle_front_right_frame",TRUE,TRUE,50,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/t34/left/door
	icon_state = "t34_frame_steel_middle_back_left"
	w_left = list("t34_middle_back_left_frame",TRUE,TRUE,50,50,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/t34/bc
	icon_state = "t34_frame_steel_middle_back"

/obj/structure/vehicleparts/frame/t34/right/door
	icon_state = "t34_frame_steel_middle_back_right"
	w_right = list("t34_middle_back_right_frame",TRUE,TRUE,50,50,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/t34/rb
	icon_state = "t34_frame_steel_back_right"
	w_back = list("t34_back_right_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t34/lb
	icon_state = "t34_frame_steel_back_left"
	w_back = list("t34_back_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t34/rf
	icon_state = "t34_frame_steel_front_right"
	w_front = list("t34_front_right_frame",TRUE,TRUE,80,80,FALSE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t34/lf
	icon_state = "t34_frame_steel_front_left"
	w_front = list("t34_front_left_frame",TRUE,TRUE,80,80,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su85

/obj/structure/vehicleparts/frame/su85/front
	w_front = list("c_wall",TRUE,TRUE,70,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su85/back
	w_back = list("c_wall",TRUE,TRUE,70,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su85/left
	w_left = list("c_wall",TRUE,TRUE,45,45,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su85/right
	w_right = list("c_wall",TRUE,TRUE,45,45,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su85/right/door
	w_right = list("c_door",TRUE,TRUE,50,30,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/su85/rb
	w_right = list("c_wall",TRUE,TRUE,50,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,60,60,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su85/lb
	w_left = list("c_wall",TRUE,TRUE,50,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,60,60,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su85/rf
	w_right = list("c_wall",TRUE,TRUE,45,45,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,70,70,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/su85/lf
	w_left = list("c_wall",TRUE,TRUE,45,45,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,70,70,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/sdfkzfront

/obj/structure/vehicleparts/frame/sdfkzfront/lf
	w_left = list("c_wall",TRUE,TRUE,15,15,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,15,15,FALSE,FALSE)

/obj/structure/vehicleparts/frame/sdfkzfront/rf
	w_right = list("c_wall",TRUE,TRUE,15,15,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,15,15,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/sdfkzfront/right
	w_right = list("c_wall",TRUE,TRUE,15,15,FALSE,FALSE)

/obj/structure/vehicleparts/frame/sdfkzfront/right/door
	w_right = list("c_door",TRUE,TRUE,15,15,TRUE,TRUE)
	doorcode = 11940

/obj/structure/vehicleparts/frame/t20

/obj/structure/vehicleparts/frame/t20/lf
	w_left = list("c_wall",TRUE,TRUE,20,20,FALSE,FALSE,TRUE)
	w_front = list("c_armoredfront",TRUE,TRUE,30,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t20/rf
	w_right = list("c_wall",TRUE,TRUE,20,20,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,20,20,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t20/leftm
	name = "steel frame"
	desc = "A steel vehicle frame."
	icon_state = "frame_steel"
	resistance = 150
	noroof = FALSE
	w_left = list("c_wall",TRUE,TRUE,15,15,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t20/rightm
	name = "steel frame"
	desc = "A steel vehicle frame."
	icon_state = "frame_steel"
	resistance = 150
	noroof = FALSE
	w_right = list("c_door",TRUE,TRUE,30,30,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/t20/frontlback
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 120
	noroof = TRUE
	w_front = list("c_wall",TRUE,TRUE,20,20,FALSE,FALSE)
	w_right = list("c_door",TRUE,TRUE,15,15,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/t20/frontrback
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 120
	noroof = TRUE
	w_front = list("c_wall",TRUE,TRUE,20,20,FALSE,FALSE)
	w_left = list("c_door",TRUE,TRUE,15,15,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/t20/backl
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 120
	noroof = TRUE
	w_back = list("c_wall",TRUE,TRUE,15,15,FALSE,FALSE)
	w_right = list("c_door",TRUE,TRUE,15,15,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/t20/backr
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 120
	noroof = TRUE
	w_back = list("c_wall",TRUE,TRUE,15,15,FALSE,FALSE)
	w_left = list("c_door",TRUE,TRUE,15,15,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/bt7

/obj/structure/vehicleparts/frame/bt7/lf
	w_front = list("c_armoredfront",TRUE,TRUE,38,50,FALSE,FALSE)
	w_left = list("c_wall",TRUE,TRUE,34,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bt7/rf
	w_front = list("c_armoredfront",TRUE,TRUE,38,50,FALSE,FALSE,TRUE)
	w_right = list("c_wall",TRUE,TRUE,34,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bt7/lfc
	w_left = list("c_wall",TRUE,TRUE,15,15,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bt7/rfc
	w_right = list("c_door",TRUE,TRUE,15,15,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/bt7/lbc
	w_left = list("c_wall",TRUE,TRUE,34,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bt7/rbc
	w_right = list("c_wall",TRUE,TRUE,34,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bt7/lb
	w_back = list("c_wall",TRUE,TRUE,25,50,FALSE,FALSE)
	w_left = list("c_wall",TRUE,TRUE,34,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bt7/rb
	w_back = list("c_wall",TRUE,TRUE,25,50,FALSE,FALSE)
	w_right = list("c_wall",TRUE,TRUE,34,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m13

/obj/structure/vehicleparts/frame/m13/front
	w_front = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/m13/front/thin
	w_front = list("c_wall",TRUE,TRUE,3,3,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m13/back
	w_back = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m13/left
	w_left = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m13/right
	w_right = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m13/left/door
	w_left = list("c_door",TRUE,TRUE,25,25,TRUE,TRUE)

/obj/structure/vehicleparts/frame/m13/right/door
	w_right = list("c_door",TRUE,TRUE,25,25,TRUE,TRUE)

/obj/structure/vehicleparts/frame/m13/rb
	w_right = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m13/lb
	w_left = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m13/rf
	w_right = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE,TRUE)
	w_front = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/m13/rf/thin
	w_right = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,3,3,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/m13/lf
	w_left = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE,TRUE)
	w_front = list("c_wall",TRUE,TRUE,30,30,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/m13/lf/thin
	w_left = list("c_wall",TRUE,TRUE,25,25,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,3,3,FALSE,FALSE)

/obj/structure/vehicleparts/frame/unattr

/obj/structure/vehicleparts/frame/unattr/lf
	w_left = list("c_wall",TRUE,TRUE,40,40,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,40,40,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/unattr/rf
	w_right = list("c_wall",TRUE,TRUE,40,40,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,40,40,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/unattr/leftm
	name = "steel frame"
	desc = "A steel vehicle frame."
	icon_state = "frame_steel"
	resistance = 150
	noroof = FALSE
	w_left = list("c_wall",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/unattr/rightm
	name = "steel frame"
	desc = "A steel vehicle frame."
	icon_state = "frame_steel"
	resistance = 150
	noroof = FALSE
	w_right = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/unattr/frontlback
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 140
	noroof = TRUE
	w_front = list("c_wall",TRUE,TRUE,40,40,FALSE,FALSE)
	w_right = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	w_left = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/unattr/frontrback
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 140
	noroof = TRUE
	w_front = list("c_wall",TRUE,TRUE,40,40,FALSE,FALSE)
	w_left = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	w_right = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/unattr/backl
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 140
	noroof = TRUE
	w_back = list("c_wall",TRUE,TRUE,40,40,FALSE,FALSE)
	w_right = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	w_left = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/unattr/backr
	name = "wood frame"
	desc = "A wood vehicle frame."
	icon_state = "frame_wood"
	resistance = 140
	noroof = TRUE
	w_back = list("c_wall",TRUE,TRUE,40,40,FALSE,FALSE)
	w_right = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	w_left = list("c_door",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/kv1

/obj/structure/vehicleparts/frame/kv1/front
	w_front = list("c_wall",TRUE,TRUE,85,85,FALSE,FALSE)

/obj/structure/vehicleparts/frame/kv1/back
	w_back = list("c_wall",TRUE,TRUE,70,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/kv1/left
	w_left = list("c_wall",TRUE,TRUE,75,75,FALSE,FALSE)

/obj/structure/vehicleparts/frame/kv1/right
	w_right = list("c_wall",TRUE,TRUE,75,75,FALSE,FALSE)

/obj/structure/vehicleparts/frame/kv1/left/door
	w_left = list("c_door",TRUE,TRUE,75,30,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/kv1/right/door
	w_right = list("c_door",TRUE,TRUE,75,30,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/kv1/rb
	w_right = list("c_wall",TRUE,TRUE,75,75,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,70,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/kv1/lb
	w_left = list("c_wall",TRUE,TRUE,75,75,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,70,70,FALSE,FALSE)

/obj/structure/vehicleparts/frame/kv1/rf
	w_right = list("c_wall",TRUE,TRUE,75,75,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,85,85,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/kv1/lf
	w_left = list("c_wall",TRUE,TRUE,70,70,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,75,75,FALSE,FALSE)

/obj/structure/vehicleparts/frame/i_go

/obj/structure/vehicleparts/frame/i_go/front
	w_front = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/i_go/back
	w_back = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/i_go/left
	w_left = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/i_go/right
	w_right = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/i_go/left/door
	w_left = list("c_door",TRUE,TRUE,17,50,TRUE,FALSE)
	doorcode = 5970

/obj/structure/vehicleparts/frame/i_go/right/door
	w_right = list("c_door",TRUE,TRUE,17,50,TRUE,FALSE)
	doorcode = 5970

/obj/structure/vehicleparts/frame/i_go/rb
	w_right = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/i_go/lb
	w_left = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/i_go/rf
	w_right = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,17,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/i_go/lf
	w_left = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/chi_ha

/obj/structure/vehicleparts/frame/chi_ha/front
	w_front = list("c_wall",TRUE,TRUE,25,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/chi_ha/back
	w_back = list("c_wall",TRUE,TRUE,10,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/chi_ha/left
	w_left = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/chi_ha/right
	w_right = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/chi_ha/left/door
	w_left = list("c_door",TRUE,TRUE,17,50,TRUE,FALSE)
	doorcode = 5970

/obj/structure/vehicleparts/frame/chi_ha/right/door
	w_right = list("c_door",TRUE,TRUE,17,50,TRUE,FALSE)
	doorcode = 5970

/obj/structure/vehicleparts/frame/chi_ha/rb
	w_right = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,10,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/chi_ha/lb
	w_left = list("c_wall",TRUE,TRUE,17,50,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,10,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/chi_ha/rf
	w_right = list("c_wall",TRUE,TRUE,25,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,25,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/chi_ha/lf
	w_left = list("c_wall",TRUE,TRUE,25,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,25,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/hago
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'
	broken_icon = 'icons/obj/civ13/vehicleparts_damaged.dmi'

/obj/structure/vehicleparts/frame/hago/lf
	icon_state = "hago_frame_lf"
	w_front = list("hago_fl_frame",FALSE,FALSE,12,50,FALSE,FALSE,TRUE)
	w_left = list("none",TRUE,TRUE,12,50,FALSE,FALSE)
	override_roof_icon = "hago_fl_roof"
	override_frame_icon = "hago_fl_frame"

/obj/structure/vehicleparts/frame/hago/rf
	icon_state = "hago_frame_rf"
	w_front = list("hago_fr_frame",TRUE,TRUE,12,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,12,50,FALSE,FALSE)
	override_roof_icon = "hago_fr_roof"
	override_frame_icon = "hago_fr_frame"

/obj/structure/vehicleparts/frame/hago/lc
	icon_state = "hago_frame_cl"
	w_left = list("hago_cl_frame",TRUE,TRUE,10,50,TRUE,TRUE)
	override_roof_icon = "hago_cl_roof"
	override_frame_icon = "hago_cl_frame"

/obj/structure/vehicleparts/frame/hago/rc
	icon_state = "hago_frame_cr"
	w_right = list("hago_cr_frame",TRUE,TRUE,10,50,FALSE,FALSE)
	override_roof_icon = "hago_cr_roof"
	override_frame_icon = "hago_cr_frame"

/obj/structure/vehicleparts/frame/hago/lb
	icon_state = "hago_frame_bl"
	w_back = list("hago_bl_frame",TRUE,TRUE,6,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,10,50,FALSE,FALSE)
	override_roof_icon = "hago_bl_roof"
	override_frame_icon = "hago_bl_frame"

/obj/structure/vehicleparts/frame/hago/rb
	icon_state = "hago_frame_br"
	w_back = list("hago_br_frame",TRUE,TRUE,6,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,10,50,FALSE,FALSE)
	override_roof_icon = "hago_br_roof"
	override_frame_icon = "hago_br_frame"

/obj/structure/vehicleparts/frame/m4

/obj/structure/vehicleparts/frame/m4/front
	w_front = list("c_wall",TRUE,TRUE,30,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m4/back
	w_back = list("c_wall",TRUE,TRUE,15,35,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m4/left
	w_left = list("c_wall",TRUE,TRUE,20,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m4/right
	w_right = list("c_wall",TRUE,TRUE,20,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m4/left/door
	w_left = list("c_door",TRUE,TRUE,26,28,TRUE,TRUE)
	doorcode = 9950

/obj/structure/vehicleparts/frame/m4/right/door
	w_right = list("c_door",TRUE,TRUE,26,28,TRUE,TRUE)
	doorcode = 9950

/obj/structure/vehicleparts/frame/m4/rb
	w_right = list("c_wall",TRUE,TRUE,20,40,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,15,35,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m4/lb
	w_left = list("c_wall",TRUE,TRUE,20,40,FALSE,FALSE)
	w_back = list("c_wall",TRUE,TRUE,15,35,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m4/rf
	w_right = list("c_wall",TRUE,TRUE,30,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,30,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/m4/lf
	w_left = list("c_wall",TRUE,TRUE,30,50,FALSE,FALSE)
	w_front = list("c_armoredfront",TRUE,TRUE,30,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/t90a
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'

/obj/structure/vehicleparts/frame/t90a/front
	w_front = list("mt_front_frame",TRUE,TRUE,600,600,FALSE,FALSE)
	override_roof_icon = "mt_front_roof"
	override_frame_icon = "mt_front_frame"

/obj/structure/vehicleparts/frame/t90a/back
	w_back = list("mt_back_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_roof"
	override_frame_icon = "mt_back_frame"

/obj/structure/vehicleparts/frame/t90a/left
	w_left = list("mt_left_frame",TRUE,TRUE,90,90,FALSE,FALSE)
	override_roof_icon = "mt_left_roof"
	override_frame_icon = "mt_left_frame"

/obj/structure/vehicleparts/frame/t90a/left/door
	w_left = list("mt_left_door_frame",TRUE,TRUE,90,30,TRUE,TRUE)
	override_roof_icon = "mt_left_door_roof"
	override_frame_icon = "mt_left_door_frame"

/obj/structure/vehicleparts/frame/t90a/right
	w_right = list("mt_right_frame",TRUE,TRUE,90,80,FALSE,FALSE)
	override_roof_icon = "mt_right_roof"
	override_frame_icon = "mt_right_frame"

/obj/structure/vehicleparts/frame/t90a/right/door
	w_right = list("mt_right_door_frame",TRUE,TRUE,90,30,TRUE,TRUE)
	override_roof_icon = "mt_right_door_roof"
	override_frame_icon = "mt_right_door_frame"

/obj/structure/vehicleparts/frame/t90a/right/door/coded
	doorcode = 4975

/obj/structure/vehicleparts/frame/t90a/rb
	w_right = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_back = list("mt_right_back_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_right_roof"
	override_frame_icon = "mt_back_right_frame"

/obj/structure/vehicleparts/frame/t90a/lb
	w_left = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_back = list("mt_back_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_left_roof"
	override_frame_icon = "mt_back_left_frame"

/obj/structure/vehicleparts/frame/t90a/rf
	w_right = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_front = list("mt_front_right_frame",TRUE,TRUE,600,600,FALSE,FALSE,TRUE)
	override_roof_icon = "mt_front_right_roof"
	override_frame_icon = "mt_front_right_frame"

/obj/structure/vehicleparts/frame/t90a/lf
	w_left = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_front = list("mt_front_left_frame",TRUE,TRUE,600,600,FALSE,FALSE)
	override_roof_icon = "mt_front_left_roof"
	override_frame_icon = "mt_front_left_frame"

/obj/structure/vehicleparts/frame/t72
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'

/obj/structure/vehicleparts/frame/t72/front
	w_front = list("mt_front_frame",TRUE,TRUE,450,450,FALSE,FALSE)
	override_roof_icon = "mt_front_roof"
	override_frame_icon = "mt_front_frame"

/obj/structure/vehicleparts/frame/t72/back
	w_back = list("mt_back_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_roof"
	override_frame_icon = "mt_back_frame"

/obj/structure/vehicleparts/frame/t72/left
	w_left = list("mt_left_frame",TRUE,TRUE,90,90,FALSE,FALSE)
	override_roof_icon = "mt_left_roof"
	override_frame_icon = "mt_left_frame"

/obj/structure/vehicleparts/frame/t72/left/door
	w_left = list("mt_left_door_frame",TRUE,TRUE,90,30,TRUE,TRUE)
	override_roof_icon = "mt_left_door_roof"
	override_frame_icon = "mt_left_door_frame"

/obj/structure/vehicleparts/frame/t72/right
	w_right = list("mt_right_frame",TRUE,TRUE,90,90,FALSE,FALSE)
	override_roof_icon = "mt_right_roof"
	override_frame_icon = "mt_right_frame"

/obj/structure/vehicleparts/frame/t72/right/door
	w_right = list("mt_right_door_frame",TRUE,TRUE,90,30,TRUE,TRUE)
	override_roof_icon = "mt_right_door_roof"
	override_frame_icon = "mt_right_door_frame"

/obj/structure/vehicleparts/frame/t72/right/door/coded
	doorcode = 4975

/obj/structure/vehicleparts/frame/t72/rb
	w_right = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_back = list("mt_right_back_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_right_roof"
	override_frame_icon = "mt_back_right_frame"

/obj/structure/vehicleparts/frame/t72/lb
	w_left = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_back = list("mt_back_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_left_roof"
	override_frame_icon = "mt_back_left_frame"

/obj/structure/vehicleparts/frame/t72/rf
	w_right = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_front = list("mt_front_right_frame",TRUE,TRUE,450,450,FALSE,FALSE,TRUE)
	override_roof_icon = "mt_front_right_roof"
	override_frame_icon = "mt_front_right_frame"

/obj/structure/vehicleparts/frame/t72/lf
	w_left = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_front = list("mt_front_left_frame",TRUE,TRUE,450,450,FALSE,FALSE)
	override_roof_icon = "mt_front_left_roof"
	override_frame_icon = "mt_front_left_frame"

/obj/structure/vehicleparts/frame/t55
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'

/obj/structure/vehicleparts/frame/t55/front
	w_front = list("mt_front_frame",TRUE,TRUE,200,200,FALSE,FALSE)
	override_roof_icon = "mt_front_roof"
	override_frame_icon = "mt_front_frame"

/obj/structure/vehicleparts/frame/t55/back
	w_back = list("mt_back_frame",TRUE,TRUE,45,45,FALSE,FALSE)
	override_roof_icon = "mt_back_roof"
	override_frame_icon = "mt_back_frame"

/obj/structure/vehicleparts/frame/t55/left
	w_left = list("mt_left_frame",TRUE,TRUE,80,80,FALSE,FALSE)
	override_roof_icon = "mt_left_roof"
	override_frame_icon = "mt_left_frame"

/obj/structure/vehicleparts/frame/t55/left/door
	w_left = list("mt_left_door_frame",TRUE,TRUE,80,30,TRUE,TRUE)
	override_roof_icon = "mt_left_door_roof"
	override_frame_icon = "mt_left_door_frame"

/obj/structure/vehicleparts/frame/t55/right
	w_right = list("mt_right_frame",TRUE,TRUE,80,80,FALSE,FALSE)
	override_roof_icon = "mt_right_roof"
	override_frame_icon = "mt_right_frame"

/obj/structure/vehicleparts/frame/t55/right/door
	w_right = list("mt_right_door_frame",TRUE,TRUE,80,30,TRUE,TRUE)
	override_roof_icon = "mt_right_door_roof"
	override_frame_icon = "mt_right_door_frame"

/obj/structure/vehicleparts/frame/t55/rb
	w_right = list("c_wall",TRUE,TRUE,80,80,FALSE,FALSE)
	w_back = list("mt_right_back_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_right_roof"
	override_frame_icon = "mt_back_right_frame"

/obj/structure/vehicleparts/frame/t55/lb
	w_left = list("c_wall",TRUE,TRUE,80,80,FALSE,FALSE)
	w_back = list("mt_back_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "mt_back_left_roof"
	override_frame_icon = "mt_back_left_frame"

/obj/structure/vehicleparts/frame/t55/rf
	w_right = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_front = list("mt_front_right_frame",TRUE,TRUE,450,450,FALSE,FALSE)
	override_roof_icon = "mt_front_right_roof"
	override_frame_icon = "mt_front_right_frame"

/obj/structure/vehicleparts/frame/t55/lf
	w_left = list("c_wall",TRUE,TRUE,90,90,FALSE,FALSE)
	w_front = list("mt_front_left_frame",TRUE,TRUE,450,450,FALSE,FALSE)
	override_roof_icon = "mt_front_left_roof"
	override_frame_icon = "mt_front_left_frame"

/obj/structure/vehicleparts/frame/leopard
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'

/obj/structure/vehicleparts/frame/leopard/front
	w_front = list("mt_front_frame",TRUE,TRUE,450,450,FALSE,FALSE)
	override_roof_icon = "mt_front_roof"
	override_frame_icon = "mt_front_frame"

/obj/structure/vehicleparts/frame/leopard/back
	w_back = list("mt_back_frame",TRUE,TRUE,20,20,FALSE,FALSE)
	override_roof_icon = "mt_back_roof"
	override_frame_icon = "mt_back_frame"

/obj/structure/vehicleparts/frame/leopard/left
	w_left = list("mt_left_frame",TRUE,TRUE,60,60,FALSE,FALSE)
	override_roof_icon = "mt_left_roof"
	override_frame_icon = "mt_left_frame"

/obj/structure/vehicleparts/frame/leopard/left/door
	w_left = list("mt_left_door_frame",TRUE,TRUE,60,30,TRUE,TRUE)
	override_roof_icon = "mt_left_door_roof"
	override_frame_icon = "mt_left_door_frame"

/obj/structure/vehicleparts/frame/leopard/right/door/coded
	doorcode = 5970

/obj/structure/vehicleparts/frame/leopard/right
	w_right = list("mt_right_frame",TRUE,TRUE,60,35,FALSE,FALSE)
	override_roof_icon = "mt_right_roof"
	override_frame_icon = "mt_right_frame"

/obj/structure/vehicleparts/frame/leopard/right/door
	w_right = list("mt_right_door_frame",TRUE,TRUE,60,30,TRUE,TRUE)
	override_roof_icon = "mt_right_door_roof"
	override_frame_icon = "mt_right_door_frame"

/obj/structure/vehicleparts/frame/leopard/rb
	w_right = list("c_wall",TRUE,TRUE,60,60,FALSE,FALSE)
	w_back = list("mt_right_back_frame",TRUE,TRUE,20,20,FALSE,FALSE)
	override_roof_icon = "mt_back_right_roof"
	override_frame_icon = "mt_back_right_frame"

/obj/structure/vehicleparts/frame/leopard/lb
	w_left = list("c_wall",TRUE,TRUE,60,60,FALSE,FALSE)
	w_back = list("mt_back_left_frame",TRUE,TRUE,20,20,FALSE,FALSE)
	override_roof_icon = "mt_back_left_roof"
	override_frame_icon = "mt_back_left_frame"

/obj/structure/vehicleparts/frame/leopard/rf
	w_right = list("c_wall",TRUE,TRUE,75,75,FALSE,FALSE)
	w_front = list("mt_front_right_frame",TRUE,TRUE,450,450,FALSE,FALSE,TRUE)
	override_roof_icon = "mt_front_right_roof"
	override_frame_icon = "mt_front_right_frame"

/obj/structure/vehicleparts/frame/leopard/lf
	w_left = list("c_wall",TRUE,TRUE,75,75,FALSE,FALSE)
	w_front = list("mt_front_left_frame",TRUE,TRUE,450,450,FALSE,FALSE)
	override_roof_icon = "mt_front_left_roof"
	override_frame_icon = "mt_front_left_frame"

/obj/structure/vehicleparts/frame/omw22_2
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'

/obj/structure/vehicleparts/frame/omw22_2/front
	w_front = list("mt_front_frame",TRUE,TRUE,90,90,FALSE,FALSE)
	override_roof_icon = "mt_front_roof"
	override_frame_icon = "mt_front_frame"

/obj/structure/vehicleparts/frame/omw22_2/back
	w_back = list("mt_back_frame",TRUE,TRUE,50,40,FALSE,FALSE)
	override_roof_icon = "mt_back_roof"
	override_frame_icon = "mt_back_frame"

/obj/structure/vehicleparts/frame/omw22_2/left
	w_left = list("mt_left_frame",TRUE,TRUE,50,40,FALSE,FALSE)
	override_roof_icon = "mt_left_roof"
	override_frame_icon = "mt_left_frame"

/obj/structure/vehicleparts/frame/omw22_2/right
	w_right = list("mt_right_frame",TRUE,TRUE,50,40,FALSE,FALSE)
	override_roof_icon = "mt_right_roof"
	override_frame_icon = "mt_right_frame"

/obj/structure/vehicleparts/frame/omw22_2/left/door
	w_left = list("mt_left_door_frame",TRUE,TRUE,50,28,TRUE,TRUE)
	doorcode = 668643
	override_roof_icon = "mt_left_door_roof"
	override_frame_icon = "mt_left_door_frame"

/obj/structure/vehicleparts/frame/omw22_2/right/door
	w_right = list("mt_right_door_frame",TRUE,TRUE,50,28,TRUE,TRUE)
	doorcode = 668643
	override_roof_icon = "mt_right_door_roof"
	override_frame_icon = "mt_right_door_frame"

/obj/structure/vehicleparts/frame/omw22_2/right/door/coded
	doorcode = 5970

/obj/structure/vehicleparts/frame/omw22_2/rb
	w_right = list("c_wall",TRUE,TRUE,50,40,FALSE,FALSE)
	w_back = list("mt_right_back_frame",TRUE,TRUE,50,40,FALSE,FALSE)
	override_roof_icon = "mt_back_right_roof"
	override_frame_icon = "mt_back_right_frame"

/obj/structure/vehicleparts/frame/omw22_2/lb
	w_left = list("c_wall",TRUE,TRUE,50,40,FALSE,FALSE)
	w_back = list("mt_back_left_frame",TRUE,TRUE,50,40,FALSE,FALSE)
	override_roof_icon = "mt_back_left_roof"
	override_frame_icon = "mt_back_left_frame"

/obj/structure/vehicleparts/frame/omw22_2/rf
	w_right = list("c_wall",TRUE,TRUE,50,40,FALSE,FALSE)
	w_front = list("mt_front_right_frame",TRUE,TRUE,90,90,FALSE,FALSE,TRUE)
	override_roof_icon = "mt_front_right_roof"
	override_frame_icon = "mt_front_right_frame"

/obj/structure/vehicleparts/frame/omw22_2/lf
	w_left = list("c_wall",TRUE,TRUE,50,40,FALSE,FALSE)
	w_front = list("mt_front_left_frame",TRUE,TRUE,90,90,FALSE,FALSE)
	override_roof_icon = "mt_front_left_roof"
	override_frame_icon = "mt_front_left_frame"

/obj/structure/vehicleparts/frame/baf1_a
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'
	override_roof_icon = "baf1_fc"

/obj/structure/vehicleparts/frame/baf1_a/center_back
	override_roof_icon = "baf1_bc"

/obj/structure/vehicleparts/frame/baf1_a/front
	w_front = list("mt_front_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "baf1_f"
	override_frame_icon = "mt_front_frame"

/obj/structure/vehicleparts/frame/baf1_a/back
	w_back = list("mt_back_frame",TRUE,TRUE,40,35,FALSE,FALSE)
	override_roof_icon = "baf1_b"
	override_frame_icon = "mt_back_frame"

/obj/structure/vehicleparts/frame/baf1_a/left
	w_left = list("mt_left_frame",TRUE,TRUE,40,35,FALSE,FALSE)
	override_roof_icon = "baf1_fcl"
	override_frame_icon = "mt_left_frame"

/obj/structure/vehicleparts/frame/baf1_a/left/back
	override_roof_icon = "baf1_bcl"

/obj/structure/vehicleparts/frame/baf1_a/right
	w_right = list("mt_right_frame",TRUE,TRUE,40,35,FALSE,FALSE)
	override_roof_icon = "baf1_fcr"
	override_frame_icon = "mt_right_frame"

/obj/structure/vehicleparts/frame/baf1_a/right/back
	override_roof_icon = "baf1_bcr"

/obj/structure/vehicleparts/frame/baf1_a/left/door
	w_left = list("mt_right_door_frame",TRUE,TRUE,40,24,TRUE,TRUE)
	doorcode = 932145
	override_roof_icon = "baf1_bcl"
	override_frame_icon = "mt_left_door_frame"

/obj/structure/vehicleparts/frame/baf1_a/right/door
	w_right = list("mt_right_door_frame",TRUE,TRUE,40,24,TRUE,TRUE)
	doorcode = 932145
	override_roof_icon = "baf1_bcr"
	override_frame_icon = "mt_right_door_frame"

/obj/structure/vehicleparts/frame/baf1_a/right/door/coded
	doorcode = 9950

/obj/structure/vehicleparts/frame/baf1_a/rb
	w_right = list("c_wall",TRUE,TRUE,40,35,FALSE,FALSE)
	w_back = list("mt_right_back_frame",TRUE,TRUE,40,35,FALSE,FALSE)
	override_roof_icon = "baf1_br"
	override_frame_icon = "mt_back_right_frame"

/obj/structure/vehicleparts/frame/baf1_a/rb/door
	w_right = list("c_door",TRUE,TRUE,40,24,TRUE,TRUE)
	w_back = list("c_wall",TRUE,TRUE,40,35,FALSE,FALSE)

/obj/structure/vehicleparts/frame/baf1_a/lb
	w_left = list("c_wall",TRUE,TRUE,40,35,FALSE,FALSE)
	w_back = list("mt_back_left_frame",TRUE,TRUE,40,35,FALSE,FALSE)
	override_roof_icon = "baf1_bl"
	override_frame_icon = "mt_back_left_frame"

/obj/structure/vehicleparts/frame/baf1_a/rf
	w_right = list("c_wall",TRUE,TRUE,40,35,FALSE,FALSE)
	w_front = list("mt_front_right_frame",TRUE,TRUE,50,50,FALSE,FALSE,TRUE)
	override_roof_icon = "baf1_fr"
	override_frame_icon = "mt_front_right_frame"

/obj/structure/vehicleparts/frame/baf1_a/lf
	w_left = list("c_wall",TRUE,TRUE,40,35,FALSE,FALSE)
	w_front = list("mt_front_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	override_roof_icon = "baf1_fl"
	override_frame_icon = "mt_front_left_frame"

/obj/structure/vehicleparts/frame/is3
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/is3/lf
	icon_state = "is3_frame_steel_front_left"
	w_front = list("is3_front_left_frame",TRUE,TRUE,300,300,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,300,300,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/front
	icon_state = "is3_frame_steel_front_middle"
	w_front = list("is3_front_middle_frame",TRUE,TRUE,300,300,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/rf
	icon_state = "is3_frame_steel_front_right"
	w_front = list("is3_front_right_frame",TRUE,TRUE,300,300,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,300,300,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/lfc
	icon_state = "is3_frame_steel_middle_front_left"
	w_left = list("is3_middle_front_left_frame",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/fc
	icon_state = "is3_frame_steel_middle_front"

/obj/structure/vehicleparts/frame/is3/rfc
	icon_state = "is3_frame_steel_middle_front_right"
	w_right = list("is3_middle_front_right_frame",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/lc
	icon_state = "is3_frame_steel_middle_left"
	w_left = list("is3_middle_left_frame",TRUE,TRUE,90,90,TRUE,TRUE)

/obj/structure/vehicleparts/frame/is3/c
	icon_state = "is3_frame_steel_middle"

/obj/structure/vehicleparts/frame/is3/rc
	icon_state = "is3_frame_steel_middle_right"
	w_right = list("is3_middle_right_frame",TRUE,TRUE,90,90,TRUE,TRUE)

/obj/structure/vehicleparts/frame/is3/lbc
	icon_state = "is3_frame_steel_middle_back_left"
	w_left = list("is3_middle_back_left_frame",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/bc
	icon_state = "is3_frame_steel_middle_back"

/obj/structure/vehicleparts/frame/is3/rbc
	icon_state = "is3_frame_steel_middle_back_right"
	w_right = list("is3_middle_back_right_frame",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/lb
	icon_state = "is3_frame_steel_back_left"
	w_back = list("is3_back_left_frame",TRUE,TRUE,90,90,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/back
	icon_state = "is3_frame_steel_back"
	w_back = list("is3_back_middle_frame",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is3/rb
	icon_state = "is3_frame_steel_back_right"
	w_back = list("is3_back_right_frame",TRUE,TRUE,90,90,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/is2/lf
	icon_state = "is2_frame_steel_front_left"
	w_front = list("is2_front_left_frame",TRUE,TRUE,300,300,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,200,200,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2/front
	icon_state = "is2_frame_steel_front_middle"
	w_front = list("is2_front_middle_frame",TRUE,TRUE,260,260,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2/rf
	icon_state = "is2_frame_steel_front_right"
	w_front = list("is2_front_right_frame",TRUE,TRUE,300,300,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,200,200,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2/lfc
	icon_state = "is2_frame_steel_middle_front_left"
	w_left = list("is2_middle_front_left_frame",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2/fc
	icon_state = "is2_frame_steel_middle_front"

/obj/structure/vehicleparts/frame/is2/rfc
	icon_state = "is2_frame_steel_middle_front_right"
	w_right = list("is2_middle_front_right_frame",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2/lbc
	icon_state = "is2_frame_steel_middle_back_left"
	w_left = list("is2_middle_back_left_frame",TRUE,TRUE,90,90,TRUE,TRUE)

/obj/structure/vehicleparts/frame/is2/bc
	icon_state = "is2_frame_steel_middle_back"

/obj/structure/vehicleparts/frame/is2/rbc
	icon_state = "is2_frame_steel_middle_back_right"
	w_right = list("is2_middle_back_right_frame",TRUE,TRUE,90,90,TRUE,TRUE)

/obj/structure/vehicleparts/frame/is2/lb
	icon_state = "is2_frame_steel_back_left"
	w_back = list("is2_back_left_frame",TRUE,TRUE,100,100,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2/back
	icon_state = "is2_frame_steel_back"
	w_back = list("is2_back_middle_frame",TRUE,TRUE,100,100,FALSE,FALSE)

/obj/structure/vehicleparts/frame/is2/rb
	icon_state = "is2_frame_steel_back_right"
	w_back = list("is2_back_right_frame",TRUE,TRUE,100,100,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,90,90,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/su100/lf
	icon_state = "su100_frame_steel_front_left"
	w_front = list("su100_front_left_frame",TRUE,TRUE,160,160,TRUE,TRUE,TRUE)
	w_left = list("none",TRUE,TRUE,45,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/front
	icon_state = "su100_frame_steel_front_middle"
	w_front = list("su100_front_middle_frame",TRUE,TRUE,160,160,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/rf
	icon_state = "su100_frame_steel_front_right"
	w_front = list("su100_front_right_frame",TRUE,TRUE,160,160,FALSE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,45,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/lfc
	icon_state = "su100_frame_steel_middle_front_left"
	w_left = list("su100_middle_front_left_frame",TRUE,TRUE,45,45,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/fc
	icon_state = "su100_frame_steel_middle_front"

/obj/structure/vehicleparts/frame/su100/rfc
	icon_state = "su100_frame_steel_middle_front_right"
	w_right = list("su100_middle_front_right_frame",TRUE,TRUE,45,45,TRUE,TRUE)

/obj/structure/vehicleparts/frame/su100/lbc
	icon_state = "su100_frame_steel_middle_back_left"
	w_left = list("su100_middle_back_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/bc
	icon_state = "su100_frame_steel_middle_back"

/obj/structure/vehicleparts/frame/su100/rbc
	icon_state = "su100_frame_steel_middle_back_right"
	w_right = list("su100_middle_back_right_frame",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/lb
	icon_state = "su100_frame_steel_back_left"
	w_back = list("su100_back_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/back
	icon_state = "su100_frame_steel_back"
	w_back = list("su100_back_middle_frame",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/su100/rb
	icon_state = "su100_frame_steel_back_right"
	w_back = list("su100_back_right_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m41
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/m41/lf
	icon_state = "m41_frame_steel_front_left"
	w_front = list("m41_front_left_frame",TRUE,TRUE,45,45,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,25,25,TRUE,TRUE)

/obj/structure/vehicleparts/frame/m41/rf
	icon_state = "m41_frame_steel_front_right"
	w_front = list("m41_front_right_frame",TRUE,TRUE,45,45,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m41/lc
	icon_state = "m41_frame_steel_middle_left"
	w_left = list("m41_middle_left_frame",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m41/rc
	icon_state = "m41_frame_steel_middle_right"
	w_right = list("m41_middle_right_frame",TRUE,TRUE,25,25,TRUE,TRUE)

/obj/structure/vehicleparts/frame/m41/lb
	icon_state = "m41_frame_steel_back_left"
	w_back = list("m41_back_left_frame",TRUE,TRUE,25,25,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m41/rb
	icon_state = "m41_frame_steel_back_right"
	w_back = list("m41_back_right_frame",TRUE,TRUE,25,25,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,25,25,FALSE,FALSE)

/obj/structure/vehicleparts/frame/char1
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/char1/front
	icon_state = "char1_frame_steel_front_middle"
	w_front = list("char1_front_middle_frame",TRUE,TRUE,80,80,FALSE,FALSE)

/obj/structure/vehicleparts/frame/char1/center
	icon_state = "char1_frame_steel_middle"

/obj/structure/vehicleparts/frame/char1/back
	icon_state = "char1_frame_steel_back_middle"
	w_back = list("char1_back_middle_frame",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/char1/left
	icon_state = "char1_frame_steel_middle_left"
	w_left = list("char1_middle_left_frame",TRUE,TRUE,50,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/char1/left/door
	icon_state = "char1_frame_steel_middle_left"
	w_left = list("char1_middle_left_frame",TRUE,TRUE,50,50,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/char1/right
	icon_state = "char1_frame_steel_middle_right"
	w_right = list("char1_middle_right_frame",TRUE,TRUE,50,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/char1/right/door
	icon_state = "char1_frame_steel_middle_right"
	w_right = list("char1_middle_right_frame",TRUE,TRUE,50,50,TRUE,TRUE)
	doorcode = 4975

/obj/structure/vehicleparts/frame/char1/rb
	icon_state = "char1_frame_steel_back_right"
	w_back = list("char1_back_right_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/char1/lb
	icon_state = "char1_frame_steel_back_left"
	w_back = list("char1_back_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/char1/rf
	icon_state = "char1_frame_steel_front_right"
	w_front = list("char1_front_right_frame",TRUE,TRUE,80,80,FALSE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/char1/lf
	icon_state = "char1_frame_steel_front_left"
	w_front = list("char1_front_left_frame",TRUE,TRUE,80,80,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmv1
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/bmv1/front
	icon_state = "char1_frame_steel_front_middle"
	w_front = list("char1_front_middle_frame",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmv1/center
	icon_state = "char1_frame_steel_middle"

/obj/structure/vehicleparts/frame/bmv1/back
	icon_state = "char1_frame_steel_back_middle"
	w_back = list("char1_back_middle_frame",TRUE,TRUE,30,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmv1/left
	icon_state = "char1_frame_steel_middle_left"
	w_left = list("char1_middle_left_frame",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmv1/left/door
	icon_state = "char1_frame_steel_middle_left"
	w_left = list("char1_middle_left_frame",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 668643

/obj/structure/vehicleparts/frame/bmv1/right
	icon_state = "char1_frame_steel_middle_right"
	w_right = list("char1_middle_right_frame",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmv1/right/door
	icon_state = "char1_frame_steel_middle_right"
	w_right = list("char1_middle_right_frame",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 668643

/obj/structure/vehicleparts/frame/bmv1/rb
	icon_state = "char1_frame_steel_back_right"
	w_back = list("char1_back_right_frame",TRUE,TRUE,30,30,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmv1/lb
	icon_state = "char1_frame_steel_back_left"
	w_back = list("char1_back_left_frame",TRUE,TRUE,30,30,TRUE,TRUE)
	w_front = list("c_door",TRUE,TRUE,5,5,TRUE, TRUE)
	w_left = list("none",TRUE,TRUE,40,40,FALSE,FALSE)
	w_right = list("c_wall",TRUE,TRUE,5,5,FALSE,FALSE)
	doorcode = 668643

/obj/structure/vehicleparts/frame/bmv1/rf
	icon_state = "char1_frame_steel_front_right"
	w_front = list("char1_front_right_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmv1/lf
	icon_state = "char1_frame_steel_front_left"
	w_front = list("char1_front_left_frame",TRUE,TRUE,50,50,FALSE,FALSE,TRUE)
	w_left = list("none",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/tankparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/tankparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/smf1/front
	icon_state = "t34_frame_steel_front_middle"
	w_front = list("t34_front_middle_frame",TRUE,TRUE,50,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1/back
	icon_state = "t34_frame_steel_back"
	w_back = list("t34_back_middle_frame",TRUE,TRUE,30,30,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1/left
	icon_state = "t34_frame_steel_middle_front_left"
	w_left = list("t34_middle_front_left_frame",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1/left/door
	icon_state = "t34_frame_steel_middle_back_left"
	w_left = list("t34_middle_back_left_frame",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 932145

/obj/structure/vehicleparts/frame/smf1/right
	icon_state = "t34_frame_steel_middle_front_right"
	w_right = list("t34_middle_front_right_frame",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1/right/door
	icon_state = "t34_frame_steel_middle_back_right"
	w_right = list("t34_middle_back_right_frame",TRUE,TRUE,40,40,TRUE,TRUE)
	doorcode = 932145

/obj/structure/vehicleparts/frame/smf1/rb
	icon_state = "t34_frame_steel_back_right"
	w_back = list("t34_back_right_frame",TRUE,TRUE,30,30,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1/bc
	icon_state = "t34_frame_steel_middle_back"

/obj/structure/vehicleparts/frame/smf1/lb
	icon_state = "t34_frame_steel_back_left"
	w_back = list("t34_back_left_frame",TRUE,TRUE,30,30,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1/rf
	icon_state = "t34_frame_steel_front_right"
	w_front = list("t34_front_right_frame",TRUE,TRUE,50,50,FALSE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/smf1/fc
	icon_state = "t34_frame_steel_middle_front"

/obj/structure/vehicleparts/frame/smf1/lf
	icon_state = "t34_frame_steel_front_left"
	w_front = list("t34_front_left_frame",TRUE,TRUE,50,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,40,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/apcparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/apcparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/mtlb/lf
	icon_state = "mtlb_frame_steel_front_left"
	w_front = list("mtlb_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb/rf
	icon_state = "mtlb_frame_steel_front_right"
	w_front = list("mtlb_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb/lfc
	icon_state = "mtlb_frame_steel_middle_front_left"
	w_left = list("mtlb_middle_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb/rfc
	icon_state = "mtlb_frame_steel_middle_front_right"
	w_right = list("mtlb_middle_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb/lbc
	icon_state = "mtlb_frame_steel_middle_back_left"
	w_left = list("mtlb_middle_back_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb/rbc
	icon_state = "mtlb_frame_steel_middle_back_right"
	w_right = list("mtlb_middle_back_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb/lb
	icon_state = "mtlb_frame_steel_back_left"
	w_back = list("mtlb_back_left_frame",TRUE,TRUE,35,50,TRUE,TRUE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/mtlb/rb
	icon_state = "mtlb_frame_steel_back_right"
	w_back = list("mtlb_back_right_frame",TRUE,TRUE,35,50,TRUE,TRUE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113
	icon = 'icons/obj/civ13/apcparts.dmi'
	normal_icon = 'icons/obj/civ13/apcparts.dmi'

/obj/structure/vehicleparts/frame/m113/lf
	icon_state = "m113_frame_steel_front_left"
	w_front = list("m113_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/rf
	icon_state = "m113_frame_steel_front_right"
	w_front = list("m113_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/lfc
	icon_state = "m113_frame_steel_middle_front_left"
	w_left = list("m113_middle_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/rfc
	icon_state = "m113_frame_steel_middle_front_right"
	w_right = list("m113_middle_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/lbc
	icon_state = "m113_frame_steel_middle_back_left"
	w_left = list("m113_middle_back_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/rbc
	icon_state = "m113_frame_steel_middle_back_right"
	w_right = list("m113_middle_back_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/lb
	icon_state = "m113_frame_steel_back_left"
	w_back = list("m113_back_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/rb
	icon_state = "m113_frame_steel_back_right"
	w_back = list("m113_back_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/front
	icon_state = "m113_frame_steel_front_middle"
	w_front = list("m113_front_middle_frame",TRUE,TRUE,40,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/m113/fc
	icon_state = "m113_frame_steel_middle_front"

/obj/structure/vehicleparts/frame/m113/bc
	icon_state = "m113_frame_steel_middle_back"

/obj/structure/vehicleparts/frame/m113/back
	icon_state = "m113_frame_steel_back"
	w_back = list("m113_front_middle_frame",TRUE,TRUE,40,50,TRUE,TRUE)

/obj/structure/vehicleparts/frame/bmd2
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/apcparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/apcparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/bmd2/lf
	icon_state = "bmd2new_frame_steel_front_left"
	w_front = list("bmd2new_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmd2/rf
	icon_state = "bmd2new_frame_steel_front_right"
	w_front = list("bmd2new_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmd2/lc
	icon_state = "bmd2new_frame_steel_middle_left"
	w_left = list("bmd2new_middle_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmd2/rc
	icon_state = "bmd2new_frame_steel_middle_right"
	w_right = list("bmd2new_middle_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmd2/lb
	icon_state = "bmd2new_frame_steel_back_left"
	w_back = list("bmd2new_back_left_frame",TRUE,TRUE,35,50,TRUE,TRUE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bmd2/rb
	icon_state = "bmd2new_frame_steel_back_right"
	w_back = list("bmd2new_back_right_frame",TRUE,TRUE,35,50,TRUE,TRUE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/adrian
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/apcparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/apcparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/adrian/lf
	icon_state = "bmd2new_frame_steel_front_left"
	w_front = list("bmd2new_front_left_frame",TRUE,TRUE,40,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/adrian/rf
	icon_state = "bmd2new_frame_steel_front_right"
	w_front = list("bmd2new_front_right_frame",TRUE,TRUE,40,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/adrian/lc
	icon_state = "bmd2new_frame_steel_middle_left"
	w_left = list("bmd2new_middle_left_frame",TRUE,TRUE,30,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/adrian/rc
	icon_state = "bmd2new_frame_steel_middle_right"
	w_right = list("bmd2new_middle_right_frame",TRUE,TRUE,30,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/adrian/lb
	icon_state = "bmd2new_frame_steel_back_left"
	w_back = list("bmd2new_back_left_frame",TRUE,TRUE,25,30,TRUE,TRUE)
	w_left = list("none",TRUE,TRUE,30,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/adrian/rb
	icon_state = "bmd2new_frame_steel_back_right"
	w_back = list("bmd2new_back_right_frame",TRUE,TRUE,25,30,TRUE,TRUE)
	w_right = list("none",TRUE,TRUE,30,40,FALSE,FALSE)

/obj/structure/vehicleparts/frame/btr80
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/apcparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/apcparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/btr80/lf
	icon_state = "btr80_frame_steel_front_left"
	w_front = list("btr80_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/btr80/rf
	icon_state = "btr80_frame_steel_front_right"
	w_front = list("btr80_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/btr80/lfc
	icon_state = "btr80_frame_steel_middle_front_left"
	w_left = list("btr80_middle_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/btr80/rfc
	icon_state = "btr80_frame_steel_middle_front_right"
	w_right = list("btr80_middle_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/frame/btr80/lbc
	icon_state = "btr80_frame_steel_middle_back_left"
	w_left = list("btr80_middle_back_left_frame",TRUE,TRUE,35,50,TRUE,TRUE)

/obj/structure/vehicleparts/frame/btr80/rbc
	icon_state = "btr80_frame_steel_middle_back_right"
	w_right = list("btr80_middle_back_right_frame",TRUE,TRUE,35,50,TRUE,TRUE)

/obj/structure/vehicleparts/frame/btr80/lb
	icon_state = "btr80_frame_steel_back_left"
	w_back = list("btr80_back_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/btr80/rb
	icon_state = "btr80_frame_steel_back_right"
	w_back = list("btr80_back_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/cv90
	icon = 'icons/obj/civ13/tankparts.dmi'
	normal_icon = 'icons/obj/civ13/tankparts.dmi'

/obj/structure/vehicleparts/frame/cv90/lf
	w_front = list("mt_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_left = list("c_wall",TRUE,TRUE,35,50,FALSE,FALSE)
	override_roof_icon = "mt_front_left_roof"
	override_frame_icon = "mt_front_left_frame"

/obj/structure/vehicleparts/frame/cv90/front
	w_front = list("mt_front_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	override_roof_icon = "mt_front_roof"
	override_frame_icon = "mt_front_frame"

/obj/structure/vehicleparts/frame/cv90/rf
	w_front = list("mt_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_right = list("c_wall",TRUE,TRUE,35,50,FALSE,FALSE)
	override_roof_icon = "mt_front_right_roof"
	override_frame_icon = "mt_front_right_frame"

/obj/structure/vehicleparts/frame/cv90/left
	w_left = list("mt_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	override_roof_icon = "mt_left_roof"
	override_frame_icon = "mt_left_frame"

/obj/structure/vehicleparts/frame/cv90/right
	w_right = list("mt_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	override_roof_icon = "mt_right_roof"
	override_frame_icon = "mt_right_frame"

/obj/structure/vehicleparts/frame/cv90/lb
	w_back = list("mt_back_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_left = list("c_wall",TRUE,TRUE,35,50,FALSE,FALSE)
	override_roof_icon = "mt_back_left_roof"
	override_frame_icon = "mt_back_left_frame"

/obj/structure/vehicleparts/frame/cv90/back
	w_back = list("mt_back_door_frame",TRUE,TRUE,35,50,TRUE,TRUE)
	override_roof_icon = "mt_back_door_roof"
	override_frame_icon = "mt_back_door_frame"

/obj/structure/vehicleparts/frame/cv90/rb
	w_back = list("mt_right_back_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_right = list("c_wall",TRUE,TRUE,35,50,FALSE,FALSE)
	override_roof_icon = "mt_back_right_roof"
	override_frame_icon = "mt_back_right_frame"

/obj/structure/vehicleparts/frame/bradley
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	normal_icon = 'icons/obj/civ13/apcparts96x96.dmi'
	broken_icon = 'icons/obj/civ13/apcparts96x96_damaged.dmi'
	pixel_x = -32
	pixel_y = -32

/obj/structure/vehicleparts/frame/bradley/lf
	icon_state = "bradley_frame_steel_front_left"
	w_front = list("bradley_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bradley/rf
	icon_state = "bradley_frame_steel_front_right"
	w_front = list("bradley_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bradley/lfc
	icon_state = "bradley_frame_steel_middle_front_left"
	w_left = list("bradley_middle_front_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bradley/rfc
	icon_state = "bradley_frame_steel_middle_front_right"
	w_right = list("bradley_middle_front_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bradley/lbc
	icon_state = "bradley_frame_steel_middle_back_left"
	w_left = list("bradley_middle_back_left_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bradley/rbc
	icon_state = "bradley_frame_steel_middle_back_right"
	w_right = list("bradley_middle_back_right_frame",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bradley/lb
	icon_state = "bradley_frame_steel_back_left"
	w_back = list("bradley_back_left_frame",TRUE,TRUE,35,50,TRUE,TRUE)
	w_left = list("none",TRUE,TRUE,35,50,FALSE,FALSE)

/obj/structure/vehicleparts/frame/bradley/rb
	icon_state = "bradley_frame_steel_back_right"
	w_back = list("bradley_back_right_frame",TRUE,TRUE,35,50,TRUE,TRUE)
	w_right = list("none",TRUE,TRUE,35,50,FALSE,FALSE,TRUE)

/obj/structure/vehicleparts/axis/car/piccolino
	name = "ASNO Piccolino"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 4
	maxpower = 700
	speedlist = list(8,6,4.5,3)
	turntimer = 5

/obj/structure/vehicleparts/axis/car/quattroporte
	name = "ASNO Quattroporte"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 4
	maxpower = 800
	speedlist = list(7,5,3.5,2.5)
	turntimer = 7

/obj/structure/vehicleparts/axis/car/erstenklasse
	name = "Ubermacht Erstenklasse"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 1100
	speedlist = list(7,6,5,4,3)
	turntimer = 6

/obj/structure/vehicleparts/axis/car/cv
	name = "CV 33"
	desc = "A powered axis from a tankette."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 1900
	speedlist = list(7,6,5,4,3)
	turntimer = 6

/obj/structure/vehicleparts/axis/car/falcon
	name = "SMC Falcon"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 4
	maxpower = 1000
	speedlist = list(7,6,5,2)
	turntimer = 5

/obj/structure/vehicleparts/axis/car/falcon/police
	speeds = 5
	maxpower = 1000
	speedlist = list(7,6,5,3,2.5)
	turntimer = 4
	name = "SMC Falcon Police Interceptor"
	color = "#383838"

/obj/structure/vehicleparts/axis/car/shinobu
	name = "Yamasaki Shinobu"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 800
	speedlist = list(5,4,3,2,1.2)
	turntimer = 4

/obj/structure/vehicleparts/axis/car/shinobu/police
	name = "Yamasaki Shinobu Police Interceptor"
	color = "#383838"

/obj/structure/vehicleparts/axis/car/kazoku
	name = "Yamasaki Kazoku"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 4
	maxpower = 800
	speedlist = list(6,5,4,2.5)
	turntimer = 5

/obj/structure/vehicleparts/axis/car/type95
	name = "Kurogane Type 95"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 800
	speedlist = list(5,4,2.5,1.5,1)
	turntimer = 4

/obj/structure/vehicleparts/axis/car/type94
	name = "Isuzu Type 94"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 800
	speedlist = list(5,4,2.5,1.5,1)
	turntimer = 5

/obj/structure/vehicleparts/axis/car/volle
	name = "Ubermacht Volle"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 4
	maxpower = 1200
	speedlist = list(8,6.5,4.5,2.5)
	turntimer = 9

/obj/structure/vehicleparts/axis/car/wyoming
	name = "SMC Wyoming"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 4
	maxpower = 1300
	speedlist = list(7,5.5,4.5,3)
	turntimer = 9

/obj/structure/vehicleparts/axis/car/toyota
	name = "Toyota"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	color = "#BDB76B"
	speeds = 5
	maxpower = 1580
	speedlist = list(10,6.5,4.5,3,2)
	turntimer = 7

/obj/structure/vehicleparts/axis/car/daf
	name = "DAF YA-4442 Truck"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 1800
	speedlist = list(8,5,4,3,2)
	turntimer = 8

/obj/structure/vehicleparts/axis/car/mercedes
	name = "Mercedes-Benz G280"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 1000
	speedlist = list(7,4,3,2,1)
	turntimer = 8

/obj/structure/vehicleparts/axis/car/tigr
	name = "AMN-233114 Tigr-M"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 1000
	speedlist = list(7,4,3,2,1)
	turntimer = 8

/obj/structure/vehicleparts/axis/car/ba64
	name = "Ba-64 armored car"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 800
	speedlist = list(10,6,4,3)
	turntimer = 7
	reg_number = ""
	color = "#3d5931"

/obj/structure/vehicleparts/axis/car/t20komsomoletstractor
	name = "T-20 Komsomolets tractor"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 800
	speedlist = list(10,6,4,3,2)
	turntimer = 6
	reg_number = ""
	color = "#3d5931"

/obj/structure/vehicleparts/axis/car/unattr
	name = "UN Attack Vehicle"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 4
	maxpower = 1000
	speedlist = list(10,6,4,3)
	turntimer = 6
	reg_number = ""
	color = "#ffffff"

/obj/structure/vehicleparts/axis/car/kamaz
	name = "KamAZ-4350 Truck"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 1800
	speedlist = list(8,5,4,3,2)
	turntimer = 8

/obj/structure/vehicleparts/axis/car/volle/ambulance
	name = "Ubermacht Volle KW Ambulance"
	color = "#FFFFFF"

/obj/structure/vehicleparts/axis/bike
	name = "motorcycle axis"
	speeds = 3
	maxpower = 10
	speedlist = list(3,2,1)
	reg_number = ""
	turntimer = 5
	vehicle_type = "bike"

/obj/structure/vehicleparts/axis/heavy
	name = "heavy vehicle axis"
	desc = "A heavy and slow vehicle axis."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 3
	maxpower = 2500
	speedlist = list(12,8,6)
	vehicle_type = "tank"

/obj/structure/vehicleparts/axis/heavy/is1
	name = "IS-1"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#4a5243"

/obj/structure/vehicleparts/axis/heavy/is2
	name = "IS-2"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#4a5243"

/obj/structure/vehicleparts/axis/heavy/is3
	name = "IS-3"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#4a5243"

/obj/structure/vehicleparts/axis/heavy/t34
	name = "T-34"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#3d5931"

/obj/structure/vehicleparts/axis/heavy/t34/t3485
	name = "T-34-85"
	color = "#4a5243"

/obj/structure/vehicleparts/axis/heavy/su100
	name = "SU-100"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#4a5243"

/obj/structure/vehicleparts/axis/heavy/su100/su85m
	name = "SU-85M"

/obj/structure/vehicleparts/axis/heavy/bt7
	name = "BT-7"
	speeds = 7
	speedlist = list(12,8,6,5,4,3,2)
	reg_number = ""
	color = "#5c784f"

/obj/structure/vehicleparts/axis/heavy/su85
	name = "SU-85"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#506945"

/obj/structure/vehicleparts/axis/heavy/kv1a
	name = "KV-1A"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#3d5931"

/obj/structure/vehicleparts/axis/heavy/mtlb
	name = "MT-LB"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#4a5243"
	vehicle_type = "apc"

/obj/structure/vehicleparts/axis/heavy/m113
	name = "M113 APC"
	speeds = 4
	speedlist = list(14,10,8)
	reg_number = ""
	color = "#939276"
	vehicle_type = "apc"

/obj/structure/vehicleparts/axis/heavy/m41
	name = "M41"
	speeds = 4
	speedlist = list(14,10,8)
	reg_number = ""
	color = "#494224"

/obj/structure/vehicleparts/axis/heavy/bmd1
	name = "BMD-1"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#787859"
	vehicle_type = "apc"

/obj/structure/vehicleparts/axis/heavy/bmd2
	name = "BMD-2"
	speeds = 4
	speedlist = list(9,6,4,3)
	reg_number = ""
	color = "#787859"
	vehicle_type = "apc"

/obj/structure/vehicleparts/axis/heavy/btr80
	name = "BTR-80"
	speeds = 5
	speedlist = list(10,6,5,4,3)
	reg_number = ""
	color = "#4a5243"
	vehicle_type = "apc"

/obj/structure/vehicleparts/axis/heavy/btr80/atgm

/obj/structure/vehicleparts/axis/heavy/bradley
	name = "M2 Bradley"
	speeds = 5
	speedlist = list(10,6,5,4,3)
	reg_number = ""
	color = "#787859"
	vehicle_type = "apc"

/obj/structure/vehicleparts/axis/heavy/cv90
	name = "CV-90"
	speeds = 5
	speedlist = list(10,6,5,4,3)
	reg_number = ""
	color = "#5C5C4C"
	vehicle_type = "apc"

/obj/structure/vehicleparts/axis/heavy/t80u
	name = "T-80U"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t80uk
	name = "T-80UK"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t72
	name = "T-72"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t72m1
	name = "T-72M1"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t72b3
	name = "T-72B3"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t64bm
	name = "T-64BM"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t64bv
	name = "T-64BV"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t62a
	name = "T-62A"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t62m
	name = "T-62M"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t62mv
	name = "T-62MV"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/t55
	name = "T-55"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/panzeriv
	name = "Panzer IV"
	speeds = 3
	speedlist = list(12,8,6)
	reg_number = ""
	color = "#585A5C"

/obj/structure/vehicleparts/axis/heavy/panzervi
	name = "Panzer VI Tiger"
	speeds = 4
	speedlist = list(14,11,9,7)
	reg_number = ""
	color = "#3B3F41"

/obj/structure/vehicleparts/axis/heavy/l3
	name = "L3/33"
	speeds = 4
	speedlist = list(10,6,4,3)
	reg_number = ""
	color = "#D79E57"

/obj/structure/vehicleparts/axis/heavy/l3cc
	name = "L3/33 CC"
	speeds = 4
	speedlist = list(9,5,3,2)
	reg_number = ""
	color = "#c4a567"

/obj/structure/vehicleparts/axis/heavy/m13
	name = "M13/40"
	speeds = 4
	speedlist = list(12,8,6,5)
	reg_number = ""
	color = "#778687"

/obj/structure/vehicleparts/axis/heavy/omw22_2
	name = "OMW-22 mk. II"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#774D4C"

/obj/structure/vehicleparts/axis/heavy/baf1_a
	name = "BAF I mod. A"
	speeds = 4
	speedlist = list(9,6,4,3)
	reg_number = ""
	color = "#8383C2"

/obj/structure/vehicleparts/axis/heavy/t90a
	name = "T-90A"
	speeds = 4
	speedlist = list(10,7,5,4)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/leopard
	name = "Leopard 2A6"
	speeds = 4
	speedlist = list(9,6,4,3)
	reg_number = ""
	color = "#5C5C4C"

/obj/structure/vehicleparts/axis/heavy/challenger2
	name = "FV4034 Challenger 2"
	speeds = 4
	speedlist = list(9,6,4,3)
	reg_number = ""
	color = "#CCC0A6"

/obj/structure/vehicleparts/axis/heavy/m1a1_abrams
	name = "M1A1 Abrams"
	speeds = 4
	speedlist = list(9,6,4,3)
	reg_number = ""
	color = "#58564a"

/obj/structure/vehicleparts/axis/heavy/i_go
	name = "Type 89 I-Go"
	speeds = 4
	speedlist = list(10,7,5,4)
	color = "#6a5a3d"
	reg_number = ""

/obj/structure/vehicleparts/axis/heavy/chi_ha
	name = "Type 97 Chi-Ha"
	speeds = 4
	speedlist = list(10,7,5,4)
	color = "#6a5a3d"
	reg_number = ""

/obj/structure/vehicleparts/axis/heavy/hago
	name = "Type 95 Ha-Go"
	speeds = 4
	speedlist = list(8,5,3,2)
	color = "#6a5a3d"
	reg_number = ""

/obj/structure/vehicleparts/axis/heavy/m4
	name = "M-4 Sherman"
	speeds = 4
	speedlist = list(12,8,6,5)
	color = "#494224"
	reg_number = ""

/obj/structure/vehicleparts/axis/heavy/m48a1
	name = "M-48A1 Patton"
	speeds = 4
	speedlist = list(12,8,6,5)
	color = "#494224"
	reg_number = ""

/obj/structure/vehicleparts/axis/heavy/m60a3
	name = "M60A3 Patton"
	speeds = 4
	speedlist = list(12,8,6,5)
	color = "#4B4D40"
	reg_number = ""

/obj/structure/vehicleparts/axis/heavy/bmv1_1
	name = "BMV-1 mk. I"
	speeds = 4
	speedlist = list(10,7,6,4)
	reg_number = ""
	color = "#4D5D53"

/obj/structure/vehicleparts/axis/heavy/smf1_a
	name = "SMF I mod. A"
	speeds = 4
	speedlist = list(10,7,6,4)
	reg_number = ""
	color = "#555346"

/obj/structure/vehicleparts/axis/car
	name = "car axis"
	desc = "A powered axis from a car."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	speeds = 5
	maxpower = 800
	speedlist = list(8,6,4,3,2)
	turntimer = 8
	vehicle_type = "car"

/obj/structure/vehicleparts/movement
	name = "Standard Wheel"
	ntype = "wheel"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "wheel_t_dark"
	base_icon = "wheel_t_dark"
	movement_icon = "wheel_t_dark_m"
	reversed = FALSE

/obj/structure/vehicleparts/movement/reversed
	name = "Standard Wheel (Reversed)"
	ntype = "wheel"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "wheel_t_dark"
	base_icon = "wheel_t_dark"
	movement_icon = "wheel_t_dark_m"
	reversed = TRUE

/obj/structure/vehicleparts/movement/armored
	name = "Armored Wheels"
	ntype = "wheel"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "wheel_t_dark"
	base_icon = "wheel_t_dark"
	movement_icon = "wheel_t_dark_m"
	reversed = FALSE

/obj/structure/vehicleparts/movement/armored/reversed
	name = "Armored Wheels (Reversed)"
	ntype = "wheel"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "wheel_t_dark"
	base_icon = "wheel_t_dark"
	movement_icon = "wheel_t_dark_m"
	reversed = TRUE

/obj/structure/vehicleparts/movement/armored/btr/left
	name = "BTR-80 Wheel (Front Left)"
	ntype = "wheel"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "btr80_wheels_front_left"
	base_icon = "btr80_wheels_front_left"
	movement_icon = "btr80_wheels_front_left_m"
	reversed = FALSE
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/armored/btr/right
	name = "BTR-80 Wheel (Front Right)"
	ntype = "wheel"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "btr80_wheels_front_right"
	base_icon = "btr80_wheels_front_right"
	movement_icon = "btr80_wheels_front_right_m"
	reversed = FALSE
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/armored/btr/left/reversed
	name = "BTR-80 Wheel (Back Left)"
	ntype = "wheel"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "btr80_wheels_back_left"
	base_icon = "btr80_wheels_back_left"
	movement_icon = "btr80_wheels_back_left_m"
	reversed = TRUE
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/armored/btr/right/reversed
	name = "BTR-80 Wheel (Back Right)"
	ntype = "wheel"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "btr80_wheels_back_right"
	base_icon = "btr80_wheels_back_right"
	movement_icon = "btr80_wheels_back_right_m"
	reversed = TRUE
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks
	name = "Armored Tracks"
	ntype = "track"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tracks_end"
	base_icon = "tracks_end"
	movement_icon = "tracks_end_m"
	reversed = FALSE

/obj/structure/vehicleparts/movement/tracks/reversed
	name = "Armored Tracks"
	ntype = "track"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tracks_end"
	base_icon = "tracks_end"
	movement_icon = "tracks_end_m"
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/left
	name = "Armored Tracks (Left)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts.dmi'
	icon_state = "tracks_end_left"
	base_icon = "tracks_end_left"
	movement_icon = "tracks_end_left_m"
	reversed = FALSE
	side = "left"

/obj/structure/vehicleparts/movement/tracks/right
	name = "Armored Tracks (Right)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts.dmi'
	icon_state = "tracks_end_right"
	base_icon = "tracks_end_right"
	movement_icon = "tracks_end_right_m"
	reversed = FALSE
	side = "right"

/obj/structure/vehicleparts/movement/tracks/mtlb/left_front
	name = "MT-LB Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "mtlb_tracks_left_front"
	base_icon = "mtlb_tracks_left_front"
	movement_icon = "mtlb_tracks_left_front_m"
	reversed = FALSE
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/mtlb/right_front
	name = "MT-LB Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "mtlb_tracks_right_front"
	base_icon = "mtlb_tracks_right_front"
	movement_icon = "mtlb_tracks_right_front_m"
	reversed = FALSE
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/mtlb/left_back
	name = "MT-LB Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "mtlb_tracks_left_back"
	base_icon = "mtlb_tracks_left_back"
	movement_icon = "mtlb_tracks_left_back_m"
	reversed = TRUE
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/mtlb/right_back
	name = "MT-LB Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "mtlb_tracks_right_back"
	base_icon = "mtlb_tracks_right_back"
	movement_icon = "mtlb_tracks_right_back_m"
	reversed = TRUE
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/bmd2new/left_front
	name = "BMD-2 Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_left_front"
	base_icon = "bmd2new_tracks_left_front"
	movement_icon = "bmd2new_tracks_left_front_m"
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/bmd2new/right_front
	name = "BMD-2 Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_right_front"
	base_icon = "bmd2new_tracks_right_front"
	movement_icon = "bmd2new_tracks_right_front_m"
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/bmd2new/left_back
	name = "BMD-2 Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_left_back"
	base_icon = "bmd2new_tracks_left_back"
	movement_icon = "bmd2new_tracks_left_back_m"
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/bmd2new/right_back
	name = "BMD-2 Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_right_back"
	base_icon = "bmd2new_tracks_right_back"
	movement_icon = "bmd2new_tracks_right_back_m"
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/bradley/left_front
	name = "Bradley Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_left_front"
	base_icon = "bradley_tracks_left_front"
	movement_icon = "bradley_tracks_left_front_m"
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/bradley/right_front
	name = "Bradley Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_right_front"
	base_icon = "bradley_tracks_right_front"
	movement_icon = "bradley_tracks_right_front_m"
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/bradley/left_back
	name = "Bradley Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_left_back"
	base_icon = "bradley_tracks_left_back"
	movement_icon = "bradley_tracks_left_back_m"
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/bradley/right_back
	name = "Bradley Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_right_back"
	base_icon = "bradley_tracks_right_back"
	movement_icon = "bradley_tracks_right_back_m"
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/is3/left_front
	name = "IS-3 Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_left_front"
	base_icon = "is3_tracks_left_front"
	movement_icon = "is3_tracks_left_front_m"
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/is3/right_front
	name = "IS-3 Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_right_front"
	base_icon = "is3_tracks_right_front"
	movement_icon = "is3_tracks_right_front_m"
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/is3/left_back
	name = "IS-3 Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_left_back"
	base_icon = "is3_tracks_left_back"
	movement_icon = "is3_tracks_left_back_m"
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/is3/right_back
	name = "IS-3 Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_right_back"
	base_icon = "is3_tracks_right_back"
	movement_icon = "is3_tracks_right_back_m"
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/is2/left_front
	name = "IS-2 Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_left_front"
	base_icon = "is2_tracks_left_front"
	movement_icon = "is2_tracks_left_front_m"
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/is2/right_front
	name = "IS-2 Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_right_front"
	base_icon = "is2_tracks_right_front"
	movement_icon = "is2_tracks_right_front_m"
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/is2/left_back
	name = "IS-2 Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_left_back"
	base_icon = "is2_tracks_left_back"
	movement_icon = "is2_tracks_left_back_m"
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/is2/right_back
	name = "IS-2 Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_right_back"
	base_icon = "is2_tracks_right_back"
	movement_icon = "is2_tracks_right_back_m"
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/t34/left_front
	name = "T-34 Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_left_front"
	base_icon = "t34_tracks_left_front"
	movement_icon = "t34_tracks_left_front_m"
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/t34/right_front
	name = "T-34 Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_right_front"
	base_icon = "t34_tracks_right_front"
	movement_icon = "t34_tracks_right_front_m"
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/t34/left_back
	name = "T-34 Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_left_back"
	base_icon = "t34_tracks_left_back"
	movement_icon = "t34_tracks_left_back_m"
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/t34/right_back
	name = "T-34 Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_right_back"
	base_icon = "t34_tracks_right_back"
	movement_icon = "t34_tracks_right_back_m"
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/char1/left_front
	name = "Char-B1 Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_left_front"
	base_icon = "char1_tracks_left_front"
	movement_icon = "char1_tracks_left_front_m"
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/char1/right_front
	name = "Char-B1 Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_right_front"
	base_icon = "char1_tracks_right_front"
	movement_icon = "char1_tracks_right_front_m"
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/char1/left_back
	name = "Char-B1 Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_left_back"
	base_icon = "char1_tracks_left_back"
	movement_icon = "char1_tracks_left_back_m"
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/char1/right_back
	name = "Char-B1 Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_right_back"
	base_icon = "char1_tracks_right_back"
	movement_icon = "char1_tracks_right_back_m"
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/m41/left_front
	name = "M41 Track (Left Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_left_front"
	base_icon = "m41_tracks_left_front"
	movement_icon = "m41_tracks_left_front_m"
	position = "front"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/m41/right_front
	name = "M41 Track (Right Front)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_right_front"
	base_icon = "m41_tracks_right_front"
	movement_icon = "m41_tracks_right_front_m"
	position = "front"
	side = "right"

/obj/structure/vehicleparts/movement/tracks/m41/left_back
	name = "M41 Track (Left Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_left_back"
	base_icon = "m41_tracks_left_back"
	movement_icon = "m41_tracks_left_back_m"
	position = "back"
	side = "left"

/obj/structure/vehicleparts/movement/tracks/m41/right_back
	name = "M41 Track (Right Back)"
	ntype = "track"
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_right_back"
	base_icon = "m41_tracks_right_back"
	movement_icon = "m41_tracks_right_back_m"
	position = "back"
	side = "right"

/obj/structure/vehicleparts/movement/tracks
	name = "armored tracks"
	icon_state = "tracks_end"
	base_icon = "tracks_end"
	movement_icon = "tracks_end_m"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	ntype = "track"

/obj/structure/vehicleparts/movement/tracks/middle
	icon_state = "tracks_cover"
	base_icon = "tracks_cover"
	movement_icon = "tracks_m_cover"

/obj/structure/vehicleparts/movement/tracks/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/left
	icon = 'icons/obj/civ13/tankparts.dmi'
	icon_state = "tracks_end_left"
	base_icon = "tracks_end_left"
	movement_icon = "tracks_end_left_m"

/obj/structure/vehicleparts/movement/tracks/right
	icon = 'icons/obj/civ13/tankparts.dmi'
	icon_state = "tracks_end_right"
	base_icon = "tracks_end_right"
	movement_icon = "tracks_end_right_m"

/obj/structure/vehicleparts/movement/tracks/left/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/right/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/mtlb/left
	icon = 'icons/obj/civ13/apcparts.dmi'
	icon_state = "mtlb_tracks_end_left"
	base_icon = "mtlb_tracks_end_left"
	movement_icon = "mtlb_tracks_end_left_m"

/obj/structure/vehicleparts/movement/tracks/mtlb/right
	icon = 'icons/obj/civ13/apcparts.dmi'
	icon_state = "mtlb_tracks_end_right"
	base_icon = "mtlb_tracks_end_right"
	movement_icon = "mtlb_tracks_end_right_m"

/obj/structure/vehicleparts/movement/tracks/mtlb/left/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/mtlb/right/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/bmd2/left
	icon = 'icons/obj/civ13/apcparts.dmi'
	icon_state = "bmd2_tracks_end_left"
	base_icon = "bmd2_tracks_end_left"
	movement_icon = "bmd2_tracks_end_left_m"

/obj/structure/vehicleparts/movement/tracks/bmd2/right
	icon = 'icons/obj/civ13/apcparts.dmi'
	icon_state = "bmd2_tracks_end_right"
	base_icon = "bmd2_tracks_end_right"
	movement_icon = "bmd2_tracks_end_right_m"

/obj/structure/vehicleparts/movement/tracks/bmd2new/left_front
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_left_front"
	base_icon = "bmd2new_tracks_left_front"
	movement_icon = "bmd2new_tracks_left_front_m"

/obj/structure/vehicleparts/movement/tracks/bmd2new/right_front
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_right_front"
	base_icon = "bmd2new_tracks_right_front"
	movement_icon = "bmd2new_tracks_right_front_m"

/obj/structure/vehicleparts/movement/tracks/bmd2new/left_back
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_left_back"
	base_icon = "bmd2new_tracks_left_back"
	movement_icon = "bmd2new_tracks_left_back_m"

/obj/structure/vehicleparts/movement/tracks/bmd2new/right_back
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bmd2new_tracks_right_back"
	base_icon = "bmd2new_tracks_right_back"
	movement_icon = "bmd2new_tracks_right_back_m"

/obj/structure/vehicleparts/movement/tracks/bradley/left_front
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_left_front"
	base_icon = "bradley_tracks_left_front"
	movement_icon = "bradley_tracks_left_front_m"

/obj/structure/vehicleparts/movement/tracks/bradley/right_front
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_right_front"
	base_icon = "bradley_tracks_right_front"
	movement_icon = "bradley_tracks_right_front_m"

/obj/structure/vehicleparts/movement/tracks/bradley/left_back
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_left_back"
	base_icon = "bradley_tracks_left_back"
	movement_icon = "bradley_tracks_left_back_m"

/obj/structure/vehicleparts/movement/tracks/bradley/right_back
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "bradley_tracks_right_back"
	base_icon = "bradley_tracks_right_back"
	movement_icon = "bradley_tracks_right_back_m"

/obj/structure/vehicleparts/movement/tracks/is3/left_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_left_front"
	base_icon = "is3_tracks_left_front"
	movement_icon = "is3_tracks_left_front_m"

/obj/structure/vehicleparts/movement/tracks/is3/right_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_right_front"
	base_icon = "is3_tracks_right_front"
	movement_icon = "is3_tracks_right_front_m"

/obj/structure/vehicleparts/movement/tracks/is3/left_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_left_back"
	base_icon = "is3_tracks_left_back"
	movement_icon = "is3_tracks_left_back_m"

/obj/structure/vehicleparts/movement/tracks/is3/right_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is3_tracks_right_back"
	base_icon = "is3_tracks_right_back"
	movement_icon = "is3_tracks_right_back_m"

/obj/structure/vehicleparts/movement/tracks/is2/left_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_left_front"
	base_icon = "is2_tracks_left_front"
	movement_icon = "is2_tracks_left_front_m"

/obj/structure/vehicleparts/movement/tracks/is2/right_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_right_front"
	base_icon = "is2_tracks_right_front"
	movement_icon = "is2_tracks_right_front_m"

/obj/structure/vehicleparts/movement/tracks/is2/left_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_left_back"
	base_icon = "is2_tracks_left_back"
	movement_icon = "is2_tracks_left_back_m"

/obj/structure/vehicleparts/movement/tracks/is2/right_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "is2_tracks_right_back"
	base_icon = "is2_tracks_right_back"
	movement_icon = "is2_tracks_right_back_m"

/obj/structure/vehicleparts/movement/tracks/t34/left_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_left_front"
	base_icon = "t34_tracks_left_front"
	movement_icon = "t34_tracks_left_front_m"

/obj/structure/vehicleparts/movement/tracks/t34/right_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_right_front"
	base_icon = "t34_tracks_right_front"
	movement_icon = "t34_tracks_right_front_m"

/obj/structure/vehicleparts/movement/tracks/t34/left_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_left_back"
	base_icon = "t34_tracks_left_back"
	movement_icon = "t34_tracks_left_back_m"

/obj/structure/vehicleparts/movement/tracks/t34/right_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "t34_tracks_right_back"
	base_icon = "t34_tracks_right_back"
	movement_icon = "t34_tracks_right_back_m"

/obj/structure/vehicleparts/movement/tracks/char1/left_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_left_front"
	base_icon = "char1_tracks_left_front"
	movement_icon = "char1_tracks_left_front_m"

/obj/structure/vehicleparts/movement/tracks/char1/right_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_right_front"
	base_icon = "char1_tracks_right_front"
	movement_icon = "char1_tracks_right_front_m"

/obj/structure/vehicleparts/movement/tracks/char1/left_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_left_back"
	base_icon = "char1_tracks_left_back"
	movement_icon = "char1_tracks_left_back_m"

/obj/structure/vehicleparts/movement/tracks/char1/right_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "char1_tracks_right_back"
	base_icon = "char1_tracks_right_back"
	movement_icon = "char1_tracks_right_back_m"

/obj/structure/vehicleparts/movement/tracks/m41/left_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_left_front"
	base_icon = "m41_tracks_left_front"
	movement_icon = "m41_tracks_left_front_m"

/obj/structure/vehicleparts/movement/tracks/m41/right_front
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_right_front"
	base_icon = "m41_tracks_right_front"
	movement_icon = "m41_tracks_right_front_m"

/obj/structure/vehicleparts/movement/tracks/m41/left_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_left_back"
	base_icon = "m41_tracks_left_back"
	movement_icon = "m41_tracks_left_back_m"

/obj/structure/vehicleparts/movement/tracks/m41/right_back
	icon = 'icons/obj/civ13/tankparts96x96.dmi'
	icon_state = "m41_tracks_right_back"
	base_icon = "m41_tracks_right_back"
	movement_icon = "m41_tracks_right_back_m"

/obj/structure/vehicleparts/movement/tracks/hago/left
	icon = 'icons/obj/civ13/tankparts.dmi'
	icon_state = "hago_tracks_l"
	base_icon = "hago_tracks_l"
	movement_icon = "hago_tracks_l_m"

/obj/structure/vehicleparts/movement/tracks/hago/right
	icon = 'icons/obj/civ13/tankparts.dmi'
	icon_state = "hago_tracks_r"
	base_icon = "hago_tracks_r"
	movement_icon = "hago_tracks_r_m"

/obj/structure/vehicleparts/movement/tracks/hago/left/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/hago/right/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/apc/left
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "tracks_end_left"
	base_icon = "tracks_end_left"
	movement_icon = "tracks_end_left_m"

/obj/structure/vehicleparts/movement/tracks/apc/right
	icon = 'icons/obj/civ13/apcparts96x96.dmi'
	icon_state = "tracks_end_right"
	base_icon = "tracks_end_right"
	movement_icon = "tracks_end_right_m"

/obj/structure/vehicleparts/movement/tracks/apc/left/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/apc/right/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/m113/left
	icon = 'icons/obj/civ13/apcparts.dmi'
	icon_state = "m113_tracks_end_left"
	base_icon = "m113_tracks_end_left"
	movement_icon = "m113_tracks_end_left_m"

/obj/structure/vehicleparts/movement/tracks/m113/right
	icon = 'icons/obj/civ13/apcparts.dmi'
	icon_state = "m113_tracks_end_right"
	base_icon = "m113_tracks_end_right"
	movement_icon = "m113_tracks_end_right_m"

/obj/structure/vehicleparts/movement/tracks/m113/left/reversed
	reversed = TRUE

/obj/structure/vehicleparts/movement/tracks/m113/right/reversed
	reversed = TRUE

/obj/effect/civ13_vehicle/asno/piccolino
	name = "ASNO Piccolino"
	custom_color = "#494949"
	axis_type = /obj/structure/vehicleparts/axis/car/piccolino
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/piccolino/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/piccolino/lf, /obj/structure/vehicleparts/engine/internal/gasoline/ethanol/premade/piccolino, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/eu/centered/front),
		"1,2" = list(/obj/structure/bed/chair/civ13/passenger/carseat/right, /obj/structure/vehicleparts/frame/car/piccolino/rc),
		"2,2" = list(/obj/structure/bed/chair/civ13/driver/car, /obj/structure/vehicleparts/frame/car/piccolino/lc),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/piccolino/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/piccolino/lb, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/eu/centered),
	)

/obj/effect/civ13_vehicle/asno/quattroporte
	name = "ASNO Quattroporte"
	custom_color = "#076007"
	axis_type = /obj/structure/vehicleparts/axis/car/quattroporte
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/quattroporte/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/quattroporte/lf, /obj/structure/vehicleparts/engine/internal/gasoline/premade/quattroporte, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/eu/centered/front),
		"1,2" = list(/obj/structure/bed/chair/civ13/passenger/carseat/right, /obj/structure/vehicleparts/frame/car/quattroporte/rc),
		"2,2" = list(/obj/structure/bed/chair/civ13/driver/car, /obj/structure/vehicleparts/frame/car/quattroporte/lc),
		"1,3" = list(/obj/structure/bed/chair/civ13/passenger/carseat/right, /obj/structure/vehicleparts/frame/car/quattroporte/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,3" = list(/obj/structure/bed/chair/civ13/passenger/carseat/left, /obj/structure/vehicleparts/frame/car/quattroporte/lb, /obj/structure/vehicleparts/license_plate/eu/centered, /obj/structure/vehicleparts/movement/reversed),
	)

/obj/effect/civ13_vehicle/ubermacht/erstenklasse
	name = "Ubermacht Erstenklasse"
	custom_color = "#1b1f1b"
	axis_type = /obj/structure/vehicleparts/axis/car/erstenklasse
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/tank/fueleddiesel, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/umek/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/umek/lf, /obj/structure/vehicleparts/engine/internal/diesel/premade/erstenklasse, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/eu/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/umek/rfc, /obj/structure/bed/chair/civ13/passenger/carseat/right/lion),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/umek/lfc, /obj/structure/bed/chair/civ13/driver/car/lion),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/umek/rbc, /obj/structure/bed/chair/civ13/passenger/carseat/right/lion),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/umek/lbc, /obj/structure/bed/chair/civ13/passenger/carseat/left/lion),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/umek/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/umek/lb, /obj/structure/vehicleparts/movement/reversed),
	)

/obj/effect/civ13_vehicle/smc/falcon
	name = "SMC Falcon"
	custom_color = "#1b1f1b"
	axis_type = /obj/structure/vehicleparts/axis/car/falcon
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/tank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/falcon/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/falcon/lf, /obj/structure/vehicleparts/engine/internal/gasoline/premade/falcon, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/us/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/falcon/rfc, /obj/structure/bed/chair/civ13/passenger/carseat/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/falcon/lfc, /obj/structure/bed/chair/civ13/driver/car),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/falcon/rbc, /obj/structure/bed/chair/civ13/passenger/carseat/right),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/falcon/lbc, /obj/structure/bed/chair/civ13/passenger/carseat/left),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/falcon/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/falcon/lb, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/us/centered),
	)

/obj/effect/civ13_vehicle/smc/falcon/unmarked
	name = "SMC Falcon"
	custom_color = "#13161c"
	axis_type = /obj/structure/vehicleparts/axis/car/falcon/police
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/tank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/falcon/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/falcon/lf, /obj/structure/vehicleparts/engine/internal/gasoline/premade/falcon, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/us/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/falcon/rfc, /obj/structure/bed/chair/civ13/passenger/carseat/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/falcon/lfc, /obj/structure/bed/chair/civ13/driver/car),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/falcon/rbc, /obj/structure/bed/chair/civ13/passenger/carseat/right),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/falcon/lbc, /obj/structure/bed/chair/civ13/passenger/carseat/left),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/falcon/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/falcon/lb, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/us/centered),
	)

/obj/effect/civ13_vehicle/smc/wyoming
	name = "SMC Wyoming"
	custom_color = "#392f92"
	axis_type = /obj/structure/vehicleparts/axis/car/wyoming
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/tank/fueleddiesel, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/wyoming/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/wyoming/lf, /obj/structure/vehicleparts/engine/internal/diesel/premade/wyoming, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/us/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/wyoming/rfc, /obj/structure/bed/chair/civ13/passenger/carseat/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/wyoming/lfc, /obj/structure/bed/chair/civ13/driver/car),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/wyoming/rbc),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/wyoming/lbc),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/wyoming/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/wyoming/lb, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/us/centered),
	)

/obj/effect/civ13_vehicle/yamasaki/shinobu
	name = "Yamasaki Shinobu 5000"
	custom_color = "#7F0000"
	axis_type = /obj/structure/vehicleparts/axis/car/shinobu
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/tank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/shinobu/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/shinobu/lf, /obj/structure/vehicleparts/engine/internal/gasoline/wankel/premade/shinobu, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/eu/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/shinobu/rcf, /obj/structure/bed/chair/civ13/passenger/carseat/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/shinobu/lcf, /obj/structure/bed/chair/civ13/driver/car),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/shinobu/rbc, /obj/structure/bed/chair/civ13/passenger/carseat/right),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/shinobu/lbc, /obj/structure/bed/chair/civ13/passenger/carseat/left),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/shinobu/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/shinobu/lb, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/eu/centered),
	)

/obj/effect/civ13_vehicle/yamasaki/shinobu/police
	name = "Yamasaki Police Interceptor Shinobu"
	custom_color = "#383838"
	axis_type = /obj/structure/vehicleparts/axis/car/shinobu/police
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/tank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/shinobu/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/shinobu/lf, /obj/structure/vehicleparts/engine/internal/gasoline/wankel/premade/shinobu, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/us/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/shinobu/rcf, /obj/structure/bed/chair/civ13/passenger/carseat/right/dark),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/shinobu/lcf, /obj/structure/bed/chair/civ13/driver/car/dark),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/shinobu/rbc, /obj/structure/bed/chair/civ13/passenger/carseat/right/dark),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/shinobu/lbc, /obj/structure/bed/chair/civ13/passenger/carseat/left/dark),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/shinobu/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/shinobu/lb, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/us/centered),
	)

/obj/effect/civ13_vehicle/yamasaki/kazoku
	name = "Yamasaki Kazoku"
	custom_color = "#3b3a3a"
	axis_type = /obj/structure/vehicleparts/axis/car/kazoku
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/kazoku/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/kazoku/lf, /obj/structure/vehicleparts/engine/internal/gasoline/premade/kazoku, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/eu/centered/front),
		"1,2" = list(/obj/structure/bed/chair/civ13/passenger/carseat/right, /obj/structure/vehicleparts/frame/car/kazoku/rc),
		"2,2" = list(/obj/structure/bed/chair/civ13/driver/car, /obj/structure/vehicleparts/frame/car/kazoku/lc),
		"1,3" = list(/obj/structure/bed/chair/civ13/passenger/carseat/right, /obj/structure/vehicleparts/frame/car/kazoku/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,3" = list(/obj/structure/bed/chair/civ13/passenger/carseat/left, /obj/structure/vehicleparts/frame/car/kazoku/lb, /obj/structure/vehicleparts/license_plate/eu/centered, /obj/structure/vehicleparts/movement/reversed),
	)

/obj/effect/civ13_vehicle/kurogane/type95
	name = "Kurogane type 95"
	custom_color = "#736953"
	axis_type = /obj/structure/vehicleparts/axis/car/type95
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/type95/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/type95/lf, /obj/structure/vehicleparts/engine/internal/gasoline/premade/type95, /obj/structure/vehicleparts/movement),
		"1,2" = list(/obj/structure/bed/chair/civ13/driver/car/type95, /obj/structure/vehicleparts/frame/car/type95/rc),
		"2,2" = list(/obj/structure/bed/chair/civ13/passenger/carseat/left/type95, /obj/structure/vehicleparts/frame/car/type95/lc),
		"1,3" = list(/obj/structure/bed/chair/civ13/passenger/carseat/right/type95, /obj/structure/vehicleparts/frame/car/type95/rb, /obj/structure/vehicleparts/movement/reversed),
		"2,3" = list(/obj/structure/bed/chair/civ13/passenger/carseat/left/type95, /obj/structure/vehicleparts/frame/car/type95/lb, /obj/structure/vehicleparts/movement/reversed),
	)

/obj/effect/civ13_vehicle/isuzu/type94
	name = "Isuzu Type 94"
	custom_color = "#736953"
	axis_type = /obj/structure/vehicleparts/axis/car/type94
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/frame/car/type94/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/type94/lf, /obj/structure/vehicleparts/engine/internal/gasoline/premade/type94, /obj/structure/vehicleparts/movement),
		"1,2" = list(/obj/structure/bed/chair/civ13/driver/car/type94, /obj/structure/vehicleparts/frame/car/type94/rc),
		"2,2" = list(/obj/structure/bed/chair/civ13/passenger/carseat/left/type94, /obj/structure/vehicleparts/frame/car/type94/lc),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/right),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/left),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/right),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/left),
		"1,5" = list(/obj/structure/vehicleparts/frame/car/right, /obj/structure/vehicleparts/movement/reversed),
		"2,5" = list(/obj/structure/vehicleparts/frame/car/left, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/eu),
	)

/obj/effect/civ13_vehicle/car

/obj/effect/civ13_vehicle/car/mercedes
	name = "Mercedes-Benz G280"
	custom_color = "#45453b"
	axis_type = /obj/structure/vehicleparts/axis/car/mercedes
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/rf/armored, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel, /obj/structure/vehicleparts/movement/armored),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/lf/armored, /obj/structure/vehicleparts/engine/internal/diesel/premade/v6, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/nl/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/mercedes/rf, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/mercedes/lf, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/rb/armored, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/lb/armored, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/nl/centered),
	)

/obj/effect/civ13_vehicle/car/mercedes/mg
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/rf/armored, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel, /obj/structure/vehicleparts/movement/armored),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/lf/armored, /obj/structure/vehicleparts/engine/internal/diesel/premade/v6, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/nl/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/mercedes/rf, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/weapon/mg/stationary/m2browning),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/mercedes/lf, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/rb/armored, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed, /obj/item/civ13_shell/magazine/a50cal_can, /obj/item/civ13_shell/magazine/a50cal_can, /obj/item/civ13_shell/magazine/a50cal_can),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/lb/armored, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/nl/centered),
	)

/obj/effect/civ13_vehicle/car/tigr
	name = "AMN-233114 Tigr-M"
	custom_color = "#45453b"
	axis_type = /obj/structure/vehicleparts/axis/car/tigr
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/rf/armored, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel, /obj/structure/vehicleparts/movement/armored),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/lf/armored, /obj/structure/vehicleparts/engine/internal/diesel/premade/v6, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/ru_mil/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/tigr/rf, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/tigr/lf, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/tigr/rb, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/tigr/lb, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/ru_mil/centered),
	)

/obj/effect/civ13_vehicle/car/tigr/mg
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/rf/armored, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel, /obj/structure/vehicleparts/movement/armored),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/lf/armored, /obj/structure/vehicleparts/engine/internal/diesel/premade/v6, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/ru_mil/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/tigr/rf, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/weapon/mg/stationary/pkm),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/tigr/lf, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/tigr/rb, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed, /obj/item/civ13_shell/magazine/pkm/c100, /obj/item/civ13_shell/magazine/pkm/c100, /obj/item/civ13_shell/magazine/pkm/c100),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/tigr/lb, /obj/structure/bed/chair/civ13/passenger/office/dark, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/license_plate/ru_mil/centered),
	)

/obj/effect/civ13_vehicle/car/toyota
	name = "Toyota Hilux"
	custom_color = "#BDB76B"
	axis_type = /obj/structure/vehicleparts/axis/car/toyota
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/toyota/rf, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/fueltank/smalltank/fueleddiesel),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/toyota/lf, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/toyota/rfc, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/toyota/lfc, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/toyota/rfcc, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/toyota/lfcc, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/toyota/rb, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/weapon/turret/technical_dshk),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/toyota/lb, /obj/structure/vehicleparts/movement/reversed, /obj/item/civ13_shell/magazine/ammo127, /obj/item/civ13_shell/magazine/ammo127, /obj/item/civ13_shell/magazine/ammo127, /obj/item/civ13_shell/magazine/ammo127),
	)

/obj/effect/civ13_vehicle/car/toyota/armored
	name = "Toyota Modificated"
	custom_color = "#BDB76B"
	axis_type = /obj/structure/vehicleparts/axis/car/toyota
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/rf, /obj/structure/vehicleparts/movement/armored, /obj/structure/vehicleparts/fueltank/smalltank/fueleddiesel),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/lf, /obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/rfc, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/lfc, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/rfcc, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/lfcc, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/rb, /obj/structure/vehicleparts/movement/armored),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/toyota_armored/lb, /obj/structure/vehicleparts/movement/armored/reversed),
	)

/obj/effect/civ13_vehicle/truck

/obj/effect/civ13_vehicle/truck/daf
	name = "DAF YA-4442 Truck"
	custom_color = "#45453b"
	axis_type = /obj/structure/vehicleparts/axis/car/daf
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/rf/armored, /obj/structure/vehicleparts/fueltank/tank/fueledgasoline, /obj/structure/vehicleparts/movement),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/lf/armored, /obj/structure/vehicleparts/engine/internal/gasoline/premade/v6, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/nl/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/rf/truck/armored, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/lf/truck/armored, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/right/armored),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/left/armored),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/right/armored, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/left/armored, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/nl/centered),
	)

/obj/effect/civ13_vehicle/truck/kamaz
	name = "KamAZ-4350 Truck"
	custom_color = "#45453b"
	axis_type = /obj/structure/vehicleparts/axis/car/kamaz
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/car/rf/armored, /obj/structure/vehicleparts/fueltank/tank/fueledgasoline, /obj/structure/vehicleparts/movement),
		"2,1" = list(/obj/structure/vehicleparts/frame/car/lf/armored, /obj/structure/vehicleparts/engine/internal/gasoline/premade/v6, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/license_plate/ru_mil/centered/front),
		"1,2" = list(/obj/structure/vehicleparts/frame/car/rf/truck/armored, /obj/structure/bed/chair/civ13/passenger/office/dark),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/lf/truck/armored, /obj/structure/bed/chair/civ13/driver),
		"1,3" = list(/obj/structure/vehicleparts/frame/car/right/armored),
		"2,3" = list(/obj/structure/vehicleparts/frame/car/left/armored),
		"1,4" = list(/obj/structure/vehicleparts/frame/car/right/armored, /obj/structure/vehicleparts/movement/reversed),
		"2,4" = list(/obj/structure/vehicleparts/frame/car/left/armored, /obj/structure/vehicleparts/movement/reversed, /obj/structure/vehicleparts/license_plate/ru_mil/centered),
	)

/obj/effect/civ13_vehicle/tank

/obj/effect/civ13_vehicle/tank/panzeriv
	name = "Panzer IV"
	custom_color = "#585A5C"
	axis_type = /obj/structure/vehicleparts/axis/heavy/panzeriv
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/panzeriv/rf, /obj/item/civ13_shell/magazine/mg34belt, /obj/item/civ13_shell/magazine/mg34belt, /obj/item/civ13_shell/magazine/mg34belt, /obj/item/civ13_shell/magazine/mg34belt, /obj/structure/vehicleparts/weapon/mg/stationary/mg34),
		"2,1" = list(/obj/structure/vehicleparts/frame/panzeriv/front),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/panzeriv/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/panzeriv/right, /obj/structure/vehicleparts/shellrack/full75),
		"2,2" = list(/obj/structure/vehicleparts/frame/panzeriv, /obj/structure/vehicleparts/weapon/turret/pziv),
		"3,2" = list(/obj/structure/vehicleparts/frame/panzeriv/left, /obj/structure/vehicleparts/shellrack/full75),
		"1,3" = list(/obj/structure/vehicleparts/frame/panzeriv/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/panzeriv),
		"3,3" = list(/obj/structure/vehicleparts/frame/panzeriv/left/door),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/panzeriv/rb, /obj/structure/vehicleparts/engine/internal/gasoline/premade/panzeriv),
		"2,4" = list(/obj/structure/vehicleparts/frame/panzeriv/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/panzeriv/lb, /obj/structure/vehicleparts/fueltank/tank/fueledgasoline),
	)

/obj/effect/civ13_vehicle/tank/panzervi
	name = "Panzer VI Tiger"
	custom_color = "#585A5C"
	axis_type = /obj/structure/vehicleparts/axis/heavy/panzervi
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/panzervi/rf, /obj/item/civ13_shell/magazine/mg34belt, /obj/item/civ13_shell/magazine/mg34belt, /obj/item/civ13_shell/magazine/mg34belt, /obj/item/civ13_shell/magazine/mg34belt, /obj/structure/bed/chair/civ13/passenger/mgunner/mg34),
		"2,1" = list(/obj/structure/vehicleparts/frame/panzervi/front),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/panzervi/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/panzervi/right, /obj/structure/vehicleparts/shellrack/full88),
		"2,2" = list(/obj/structure/vehicleparts/frame/panzervi, /obj/structure/vehicleparts/weapon/turret/pzvi),
		"3,2" = list(/obj/structure/vehicleparts/frame/panzervi/left, /obj/structure/vehicleparts/shellrack/full88),
		"1,3" = list(/obj/structure/vehicleparts/frame/panzervi/right),
		"2,3" = list(/obj/structure/vehicleparts/frame/panzervi),
		"3,3" = list(/obj/structure/vehicleparts/frame/panzervi/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/panzeriv/rb, /obj/structure/vehicleparts/engine/internal/gasoline/premade/panzeriv),
		"2,4" = list(/obj/structure/vehicleparts/frame/panzervi/back/door),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/panzeriv/lb, /obj/structure/vehicleparts/fueltank/tank/fueledgasoline),
	)

/obj/effect/civ13_vehicle/tank/omw22_2
	name = "OMW-22 mk. II"
	custom_color = "#774D4C"
	axis_type = /obj/structure/vehicleparts/axis/heavy/omw22_2
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/omw22_2/rf, /obj/structure/vehicleparts/headlamp),
		"2,1" = list(/obj/structure/vehicleparts/frame/omw22_2/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/omw22_2/lf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/structure/vehicleparts/weapon/mg/stationary/pkm, /obj/structure/vehicleparts/headlamp),
		"1,2" = list(/obj/structure/vehicleparts/frame/omw22_2/right, /obj/structure/bed/chair/civ13/passenger/commander),
		"2,2" = list(/obj/structure/vehicleparts/frame/omw22_2, /obj/structure/vehicleparts/weapon/cannon/omwtc10),
		"3,2" = list(/obj/structure/vehicleparts/frame/omw22_2/left, /obj/structure/bed/chair/civ13/passenger/loader),
		"1,3" = list(/obj/structure/vehicleparts/frame/omw22_2/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/omw22_2, /obj/structure/bed/chair/civ13/passenger/gunner),
		"3,3" = list(/obj/structure/vehicleparts/frame/omw22_2/left, /obj/structure/vehicleparts/shellrack/full100modern),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/omw22_2/rb),
		"2,4" = list(/obj/structure/vehicleparts/frame/omw22_2/back, /obj/structure/vehicleparts/engine/internal/diesel/premade/omw22_2, /obj/structure/vehicleparts/headlamp),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/omw22_2/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/baf1_a
	name = "BAF I mod. A"
	custom_color = "#8383C2"
	axis_type = /obj/structure/vehicleparts/axis/heavy/baf1_a
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/baf1_a/rf, /obj/structure/vehicleparts/headlamp, /obj/structure/bed/chair/civ13/driver/tank),
		"2,1" = list(/obj/structure/vehicleparts/frame/baf1_a/front, /obj/structure/bed/chair/civ13/passenger/commander),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/baf1_a/lf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/structure/vehicleparts/weapon/mg/stationary/pkm, /obj/structure/vehicleparts/headlamp),
		"1,2" = list(/obj/structure/vehicleparts/frame/baf1_a/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/baf1_a, /obj/structure/vehicleparts/weapon/cannon/baftkn75),
		"3,2" = list(/obj/structure/vehicleparts/frame/baf1_a/left, /obj/structure/bed/chair/civ13/passenger/loader),
		"1,3" = list(/obj/structure/vehicleparts/frame/baf1_a/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/baf1_a/center_back, /obj/structure/bed/chair/civ13/passenger/gunner),
		"3,3" = list(/obj/structure/vehicleparts/frame/baf1_a/left/door),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/baf1_a/rb, /obj/structure/vehicleparts/engine/internal/gasoline/premade/baf1_a),
		"2,4" = list(/obj/structure/vehicleparts/frame/baf1_a/back, /obj/structure/vehicleparts/headlamp, /obj/structure/vehicleparts/shellrack/full75),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/baf1_a/lb, /obj/structure/vehicleparts/fueltank/tank/fueledgasoline),
	)

/obj/effect/civ13_vehicle/tank/m4
	name = "M4-Sherman"
	custom_color = "#293822"
	axis_type = /obj/structure/vehicleparts/axis/heavy/m4
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/m4/rf, /obj/item/civ13_shell/magazine/browning, /obj/item/civ13_shell/magazine/browning, /obj/item/civ13_shell/magazine/browning, /obj/item/civ13_shell/magazine/browning, /obj/structure/bed/chair/civ13/passenger/mgunner/browning_lmg),
		"2,1" = list(/obj/structure/vehicleparts/frame/m4/front),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/m4/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/m4/right, /obj/structure/vehicleparts/shellrack/full75),
		"2,2" = list(/obj/structure/vehicleparts/frame/m4, /obj/structure/vehicleparts/weapon/turret/sherman),
		"3,2" = list(/obj/structure/vehicleparts/frame/m4/left, /obj/structure/vehicleparts/shellrack/full75),
		"1,3" = list(/obj/structure/vehicleparts/frame/m4/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/m4, /obj/structure/vehicleparts/shellrack/full75),
		"3,3" = list(/obj/structure/vehicleparts/frame/m4/left/door),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/m4/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"2,4" = list(/obj/structure/vehicleparts/frame/m4/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/m4/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/chiha
	name = "Type 97 Chi-Ha"
	custom_color = "#6a5a3d"
	axis_type = /obj/structure/vehicleparts/axis/heavy/chi_ha
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/chi_ha/rf, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/structure/vehicleparts/weapon/mg/stationary/type98),
		"2,1" = list(/obj/structure/vehicleparts/frame/chi_ha/front),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/chi_ha/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/chi_ha/right, /obj/structure/bed/chair/civ13/passenger/commander),
		"2,2" = list(/obj/structure/vehicleparts/frame/chi_ha, /obj/structure/vehicleparts/weapon/cannon/japanese57),
		"3,2" = list(/obj/structure/vehicleparts/frame/chi_ha/left, /obj/structure/bed/chair/civ13/passenger/gunner),
		"1,3" = list(/obj/structure/vehicleparts/frame/chi_ha/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/chi_ha, /obj/structure/bed/chair/civ13/passenger/loader),
		"3,3" = list(/obj/structure/vehicleparts/frame/chi_ha/left/door),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/chi_ha/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/item/civ13_shell/magazine/type92, /obj/structure/vehicleparts/weapon/mg/stationary/type98),
		"2,4" = list(/obj/structure/vehicleparts/frame/chi_ha/back, /obj/structure/vehicleparts/shellrack/full57),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/chi_ha/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/hago
	name = "Type 95 Ha-Go"
	custom_color = "#6a5a3d"
	axis_type = /obj/structure/vehicleparts/axis/heavy/hago
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/hago/right, /obj/structure/vehicleparts/frame/hago/rf, /obj/structure/bed/chair/civ13/driver/tank),
		"2,1" = list(/obj/structure/vehicleparts/movement/tracks/hago/left, /obj/structure/vehicleparts/frame/hago/lf, /obj/structure/bed/chair/civ13/passenger/mgunner/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97),
		"1,2" = list(/obj/structure/vehicleparts/frame/hago/rc),
		"2,2" = list(/obj/structure/vehicleparts/frame/hago/lc, /obj/structure/vehicleparts/weapon/turret/hago),
		"1,3" = list(/obj/structure/vehicleparts/frame/hago/rb, /obj/structure/vehicleparts/movement/tracks/hago/left/reversed, /obj/structure/vehicleparts/engine/internal/diesel/premade/hago, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,3" = list(/obj/structure/vehicleparts/frame/hago/lb, /obj/structure/vehicleparts/movement/tracks/hago/right/reversed, /obj/structure/vehicleparts/shellrack/full37, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97, /obj/item/civ13_shell/magazine/type99/type97),
	)

/obj/effect/civ13_vehicle/tank/l3
	name = "L3/33"
	custom_color = "#D79E57"
	axis_type = /obj/structure/vehicleparts/axis/heavy/l3
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/l3/rf, /obj/structure/vehicleparts/movement/tracks/right),
		"2,1" = list(/obj/structure/vehicleparts/frame/l3/lf, /obj/structure/vehicleparts/movement/tracks/left),
		"1,2" = list(/obj/structure/vehicleparts/frame/l3/rc, /obj/structure/bed/chair/civ13/driver/tank/anchored),
		"2,2" = list(/obj/structure/vehicleparts/frame/l3/lc, /obj/structure/bed/chair/civ13/passenger/office/dark/anchored, /obj/structure/vehicleparts/weapon/mg/stationary/breda30/hull, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30),
		"1,3" = list(/obj/structure/vehicleparts/frame/l3/rb, /obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/engine/internal/gasoline/premade/l3),
		"2,3" = list(/obj/structure/vehicleparts/frame/l3/lb, /obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline),
	)

/obj/effect/civ13_vehicle/tank/l3/antitank
	name = "L3/33 CC"
	custom_color = "#D79E57"
	axis_type = /obj/structure/vehicleparts/axis/heavy/l3cc
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/l3/rf, /obj/structure/vehicleparts/movement/tracks/right),
		"2,1" = list(/obj/structure/vehicleparts/frame/l3/lf/cc, /obj/structure/vehicleparts/movement/tracks/left),
		"1,2" = list(/obj/structure/vehicleparts/frame/l3/rc, /obj/structure/bed/chair/civ13/driver/tank/anchored),
		"2,2" = list(/obj/structure/vehicleparts/frame/l3/lc, /obj/structure/bed/chair/civ13/passenger/office/dark/anchored, /obj/structure/vehicleparts/weapon/mg/stationary/solothurn/italian/stationary, /obj/item/civ13_shell/magazine/a20mm_aphe, /obj/item/civ13_shell/magazine/a20mm_aphe, /obj/item/civ13_shell/magazine/a20mm_aphe, /obj/item/civ13_shell/magazine/a20mm_aphe, /obj/item/civ13_shell/magazine/a20mm_aphe),
		"1,3" = list(/obj/structure/vehicleparts/frame/l3/rb, /obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/engine/internal/gasoline/premade/l3),
		"2,3" = list(/obj/structure/vehicleparts/frame/l3/lb, /obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline),
	)

/obj/effect/civ13_vehicle/tank/m13
	name = "M13/40"
	custom_color = "#778687"
	axis_type = /obj/structure/vehicleparts/axis/heavy/m13
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/m13/rf, /obj/structure/vehicleparts/movement/tracks/right),
		"2,1" = list(/obj/structure/vehicleparts/frame/m13/front),
		"3,1" = list(/obj/structure/vehicleparts/frame/m13/lf, /obj/structure/vehicleparts/movement/tracks/left),
		"1,2" = list(/obj/structure/vehicleparts/frame/m13/rf/thin, /obj/structure/vehicleparts/weapon/mg/stationary/breda30/hull, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30, /obj/item/civ13_shell/magazine/breda30),
		"2,2" = list(/obj/structure/vehicleparts/frame/m13/front/thin),
		"3,2" = list(/obj/structure/vehicleparts/frame/m13/lf/thin, /obj/structure/bed/chair/civ13/driver/tank),
		"1,3" = list(/obj/structure/vehicleparts/frame/m13/right/door, /obj/structure/bed/chair/civ13/passenger/commander),
		"2,3" = list(/obj/structure/vehicleparts/frame/m13, /obj/structure/vehicleparts/weapon/cannon/italian47),
		"3,3" = list(/obj/structure/vehicleparts/frame/m13/left/door, /obj/structure/bed/chair/civ13/passenger/gunner),
		"1,4" = list(/obj/structure/vehicleparts/frame/m13/rb, /obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/shellrack/full47),
		"2,4" = list(/obj/structure/vehicleparts/frame/m13/back, /obj/structure/bed/chair/civ13/passenger/loader),
		"3,4" = list(/obj/structure/vehicleparts/frame/m13/lb, /obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/engine/internal/diesel/premade/m13, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t34
	name = "T34"
	custom_color = "#3d5931"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t34
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_front, /obj/structure/vehicleparts/frame/t34/rf, /obj/structure/bed/chair/civ13/passenger/mgunner/dt28),
		"2,1" = list(/obj/structure/vehicleparts/frame/t34/front, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_front, /obj/structure/vehicleparts/frame/t34/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/t34/right, /obj/structure/vehicleparts/shellrack/full76),
		"2,2" = list(/obj/structure/vehicleparts/frame/t34/fc, /obj/structure/vehicleparts/weapon/turret/t34),
		"3,2" = list(/obj/structure/vehicleparts/frame/t34/left, /obj/structure/vehicleparts/shellrack/full76),
		"1,3" = list(/obj/structure/vehicleparts/frame/t34/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/t34/bc, /obj/structure/vehicleparts/shellrack/full76),
		"3,3" = list(/obj/structure/vehicleparts/frame/t34/left/door),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_back, /obj/structure/vehicleparts/frame/t34/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"2,4" = list(/obj/structure/vehicleparts/frame/t34/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_back, /obj/structure/vehicleparts/frame/t34/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/bt7
	name = "BT-7"
	custom_color = "#5c784f"
	axis_type = /obj/structure/vehicleparts/axis/heavy/bt7
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/bt7/rf, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt),
		"2,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/bt7/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/bt7/rfc, /obj/structure/vehicleparts/shellrack/full45),
		"2,2" = list(/obj/structure/vehicleparts/frame/bt7/lfc, /obj/structure/vehicleparts/weapon/turret/bt7),
		"1,3" = list(/obj/structure/vehicleparts/frame/bt7/rbc),
		"2,3" = list(/obj/structure/vehicleparts/frame/bt7/lbc),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/bt7/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"2,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/bt7/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t3485
	name = "T-34-85"
	custom_color = "#4a5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t34/t3485
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_front, /obj/structure/vehicleparts/frame/t34/rf, /obj/structure/bed/chair/civ13/passenger/mgunner/dtm28),
		"2,1" = list(/obj/structure/vehicleparts/frame/t34/front, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_front, /obj/structure/vehicleparts/frame/t34/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/t34/right, /obj/structure/vehicleparts/shellrack/full85),
		"2,2" = list(/obj/structure/vehicleparts/frame/t34/fc, /obj/structure/vehicleparts/weapon/turret/t3485),
		"3,2" = list(/obj/structure/vehicleparts/frame/t34/left, /obj/structure/vehicleparts/shellrack/full85),
		"1,3" = list(/obj/structure/vehicleparts/frame/t34/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/t34/bc),
		"3,3" = list(/obj/structure/vehicleparts/frame/t34/left/door),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_back, /obj/structure/vehicleparts/frame/t34/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"2,4" = list(/obj/structure/vehicleparts/frame/t34/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_back, /obj/structure/vehicleparts/frame/t34/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/kv1
	name = "KV-1A"
	custom_color = "#3d5931"
	axis_type = /obj/structure/vehicleparts/axis/heavy/kv1a
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/kv1/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/kv1/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks, /obj/structure/vehicleparts/frame/kv1/lf, /obj/structure/bed/chair/civ13/passenger/mgunner/dt28, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt),
		"1,2" = list(/obj/structure/vehicleparts/frame/kv1/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/kv1, /obj/structure/vehicleparts/weapon/turret/kv1),
		"3,2" = list(/obj/structure/vehicleparts/frame/kv1/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/kv1/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/kv1, /obj/structure/bed/chair/civ13/passenger/loader),
		"3,3" = list(/obj/structure/vehicleparts/frame/kv1/left/door),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/kv1/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"2,4" = list(/obj/structure/vehicleparts/frame/kv1/back, /obj/structure/vehicleparts/shellrack/full85),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/reversed, /obj/structure/vehicleparts/frame/kv1/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/su100
	name = "SU-100"
	custom_color = "#4a5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/su100
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_front, /obj/structure/vehicleparts/frame/su100/rf, /obj/structure/vehicleparts/shellrack/full100ww2),
		"2,1" = list(/obj/structure/vehicleparts/frame/su100/front, /obj/structure/vehicleparts/weapon/turret/course/su100),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_front, /obj/structure/vehicleparts/frame/su100/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/su100/rfc, /obj/structure/bed/chair/civ13/passenger/commander),
		"2,2" = list(/obj/structure/vehicleparts/frame/su100/fc, /obj/structure/vehicleparts/shellrack/full100ww2),
		"3,2" = list(/obj/structure/vehicleparts/frame/su100/lfc),
		"1,3" = list(/obj/structure/vehicleparts/frame/su100/rbc),
		"2,3" = list(/obj/structure/vehicleparts/frame/su100/bc),
		"3,3" = list(/obj/structure/vehicleparts/frame/su100/lbc),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_back, /obj/structure/vehicleparts/frame/su100/rb),
		"2,4" = list(/obj/structure/vehicleparts/frame/su100/back, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_back, /obj/structure/vehicleparts/frame/su100/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/su85m
	name = "SU-85M"
	custom_color = "#4a5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/su100/su85m
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_front, /obj/structure/vehicleparts/frame/su100/rf, /obj/structure/vehicleparts/shellrack/full85),
		"2,1" = list(/obj/structure/vehicleparts/frame/su100/front, /obj/structure/vehicleparts/weapon/turret/course/su85m),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_front, /obj/structure/vehicleparts/frame/su100/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/su100/rfc, /obj/structure/bed/chair/civ13/passenger/commander),
		"2,2" = list(/obj/structure/vehicleparts/frame/su100/fc, /obj/structure/vehicleparts/shellrack/full85),
		"3,2" = list(/obj/structure/vehicleparts/frame/su100/lfc),
		"1,3" = list(/obj/structure/vehicleparts/frame/su100/rbc),
		"2,3" = list(/obj/structure/vehicleparts/frame/su100/bc),
		"3,3" = list(/obj/structure/vehicleparts/frame/su100/lbc),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/right_back, /obj/structure/vehicleparts/frame/su100/rb),
		"2,4" = list(/obj/structure/vehicleparts/frame/su100/back, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/t34/left_back, /obj/structure/vehicleparts/frame/su100/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t55
	name = "T-55"
	custom_color = "#4a5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t55
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/t55/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/t55/front),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/t55/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/t55/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/t55, /obj/structure/vehicleparts/weapon/turret/t55, /obj/structure/vehicleparts/shellrack/full100ww2),
		"3,2" = list(/obj/structure/vehicleparts/frame/t55/left, /obj/item/civ13_shell/magazine/ammo127, /obj/item/civ13_shell/magazine/ammo127, /obj/item/civ13_shell/magazine/ammo127, /obj/item/civ13_shell/magazine/ammo127),
		"1,3" = list(/obj/structure/vehicleparts/frame/t55/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/t55),
		"3,3" = list(/obj/structure/vehicleparts/frame/t55/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/t55/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/t55/back, /obj/structure/vehicleparts/shellrack/full100ww2),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/t55/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t64bm
	name = "T-64BM"
	custom_color = "#5c5c4c"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t64bm
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/t72/rf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"2,1" = list(/obj/structure/vehicleparts/frame/t72/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/t72/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/t72/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/t72, /obj/structure/vehicleparts/shellrack/autoloader/full125, /obj/structure/vehicleparts/weapon/turret/t64bm),
		"3,2" = list(/obj/structure/vehicleparts/frame/t72/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/t72/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/t72),
		"3,3" = list(/obj/structure/vehicleparts/frame/t72/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/t72/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/t72/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/t72/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t72
	name = "T-72"
	custom_color = "#5c5c4c"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t72
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/t72/rf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"2,1" = list(/obj/structure/vehicleparts/frame/t72/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/t72/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/t72/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/t72, /obj/structure/vehicleparts/shellrack/autoloader/full125, /obj/structure/vehicleparts/weapon/turret/t72),
		"3,2" = list(/obj/structure/vehicleparts/frame/t72/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/t72/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/t72),
		"3,3" = list(/obj/structure/vehicleparts/frame/t72/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/t72/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/t72/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/t72/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t72b3
	name = "T-72B3"
	custom_color = "#5c5c4c"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t72b3
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/t90a/rf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"2,1" = list(/obj/structure/vehicleparts/frame/t90a/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/t90a/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/t90a/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/t90a, /obj/structure/vehicleparts/shellrack/autoloader/full125, /obj/structure/vehicleparts/weapon/turret/t72/t72b3),
		"3,2" = list(/obj/structure/vehicleparts/frame/t90a/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/t90a/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/t90a),
		"3,3" = list(/obj/structure/vehicleparts/frame/t90a/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/t90a/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/t90a/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/t90a/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t72m1
	name = "T-72M1"
	custom_color = "#5c5c4c"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t72m1
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/t72/rf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"2,1" = list(/obj/structure/vehicleparts/frame/t72/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/t72/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/t72/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/t72, /obj/structure/vehicleparts/shellrack/autoloader/full125, /obj/structure/vehicleparts/weapon/turret/t72/t72m1),
		"3,2" = list(/obj/structure/vehicleparts/frame/t72/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/t72/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/t72),
		"3,3" = list(/obj/structure/vehicleparts/frame/t72/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/t72/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/t72/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/t72/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t80uk
	name = "T-80UK"
	custom_color = "#5c5c4c"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t80uk
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/t90a/rf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"2,1" = list(/obj/structure/vehicleparts/frame/t90a/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/t90a/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/t90a/right, /obj/structure/bed/chair/civ13/passenger/commander),
		"2,2" = list(/obj/structure/vehicleparts/frame/t90a, /obj/structure/vehicleparts/weapon/turret/t80u/t80uk, /obj/structure/vehicleparts/shellrack/autoloader/full125),
		"3,2" = list(/obj/structure/vehicleparts/frame/t90a/left, /obj/structure/bed/chair/civ13/passenger/gunner),
		"1,3" = list(/obj/structure/vehicleparts/frame/t90a/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/t90a),
		"3,3" = list(/obj/structure/vehicleparts/frame/t90a/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/t90a/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/t90a/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/t90a/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/t90a
	name = "T-90A"
	custom_color = "#4a5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/t90a
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/t90a/rf, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"2,1" = list(/obj/structure/vehicleparts/frame/t90a/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/t90a/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/t90a/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/t90a, /obj/structure/vehicleparts/shellrack/autoloader/full125, /obj/structure/vehicleparts/weapon/turret/t90a),
		"3,2" = list(/obj/structure/vehicleparts/frame/t90a/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/t90a/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/t90a),
		"3,3" = list(/obj/structure/vehicleparts/frame/t90a/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/t90a/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/t90a/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/t90a/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/m1a1_abrams
	name = "M1A1 Abrams"
	custom_color = "#58564a"
	axis_type = /obj/structure/vehicleparts/axis/heavy/m1a1_abrams
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/baf1_a/rf, /obj/item/civ13_shell/magazine/a50cal_can, /obj/item/civ13_shell/magazine/a50cal_can, /obj/item/civ13_shell/magazine/a50cal_can, /obj/structure/vehicleparts/weapon/mg/stationary/m2browning),
		"2,1" = list(/obj/structure/vehicleparts/frame/baf1_a/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/baf1_a/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/baf1_a/right, /obj/structure/vehicleparts/shellrack/full120),
		"2,2" = list(/obj/structure/vehicleparts/frame/baf1_a, /obj/structure/vehicleparts/weapon/turret/m1abrams),
		"3,2" = list(/obj/structure/vehicleparts/frame/baf1_a/left, /obj/structure/vehicleparts/shellrack/full120),
		"1,3" = list(/obj/structure/vehicleparts/frame/baf1_a/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/baf1_a),
		"3,3" = list(/obj/structure/vehicleparts/frame/baf1_a/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/baf1_a/rb, /obj/structure/vehicleparts/engine/internal/turbine/abrams),
		"2,4" = list(/obj/structure/vehicleparts/frame/baf1_a/back, /obj/structure/vehicleparts/shellrack/full120),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/baf1_a/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/challenger2
	name = "FV4034 Challenger 2"
	custom_color = "#CCC0A6"
	axis_type = /obj/structure/vehicleparts/axis/heavy/challenger2
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/omw22_2/rf, /obj/item/civ13_shell/magazine/mg3belt, /obj/item/civ13_shell/magazine/mg3belt, /obj/item/civ13_shell/magazine/mg3belt),
		"2,1" = list(/obj/structure/vehicleparts/frame/omw22_2/front, /obj/structure/bed/chair/civ13/driver/tank),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/omw22_2/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/omw22_2/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/omw22_2, /obj/structure/vehicleparts/weapon/turret/challenger2),
		"3,2" = list(/obj/structure/vehicleparts/frame/omw22_2/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/omw22_2/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/omw22_2),
		"3,3" = list(/obj/structure/vehicleparts/frame/omw22_2/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/omw22_2/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/omw22_2/back, /obj/structure/vehicleparts/shellrack/full100modern),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/omw22_2/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/tank/leopard2a6
	name = "Leopard 2A6"
	custom_color = "#4a5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/leopard
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/leopard/rf, /obj/item/civ13_shell/magazine/mg3belt, /obj/item/civ13_shell/magazine/mg3belt, /obj/item/civ13_shell/magazine/mg3belt),
		"2,1" = list(/obj/structure/vehicleparts/frame/leopard/front),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/leopard/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/leopard/right),
		"2,2" = list(/obj/structure/vehicleparts/frame/leopard, /obj/structure/vehicleparts/weapon/turret/leo2a6),
		"3,2" = list(/obj/structure/vehicleparts/frame/leopard/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/leopard/right/door/coded),
		"2,3" = list(/obj/structure/vehicleparts/frame/leopard),
		"3,3" = list(/obj/structure/vehicleparts/frame/leopard/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/leopard/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/v12),
		"2,4" = list(/obj/structure/vehicleparts/frame/leopard/back, /obj/structure/vehicleparts/shellrack/full120),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/leopard/lb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
	)

/obj/effect/civ13_vehicle/apc

/obj/effect/civ13_vehicle/apc/mtlb
	name = "MT-LB"
	custom_color = "#4A5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/mtlb
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/mtlb/right_front, /obj/structure/vehicleparts/frame/mtlb/rf, /obj/structure/vehicleparts/weapon/turret/mtlb, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"2,1" = list(/obj/structure/vehicleparts/movement/tracks/mtlb/left_front, /obj/structure/vehicleparts/frame/mtlb/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/mtlb/rfc, /obj/structure/vehicleparts/engine/internal/diesel/premade/mtlb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,2" = list(/obj/structure/vehicleparts/frame/mtlb/lfc),
		"1,3" = list(/obj/structure/vehicleparts/frame/mtlb/rbc),
		"2,3" = list(/obj/structure/vehicleparts/frame/mtlb/lbc),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/mtlb/right_back, /obj/structure/vehicleparts/frame/mtlb/rb),
		"2,4" = list(/obj/structure/vehicleparts/movement/tracks/mtlb/left_back, /obj/structure/vehicleparts/frame/mtlb/lb),
	)

/obj/effect/civ13_vehicle/apc/m113
	name = "M113"
	axis_type = /obj/structure/vehicleparts/axis/heavy/m113
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/m113/right, /obj/structure/vehicleparts/frame/m113/rf, /obj/structure/vehicleparts/engine/internal/diesel/premade/m113, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,1" = list(/obj/structure/vehicleparts/frame/m113/front, /obj/item/civ13_shell/magazine/browning, /obj/item/civ13_shell/magazine/browning, /obj/item/civ13_shell/magazine/browning, /obj/item/civ13_shell/magazine/browning, /obj/structure/vehicleparts/weapon/mg/stationary/browning),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/m113/left, /obj/structure/bed/chair/civ13/driver/tank, /obj/structure/vehicleparts/frame/m113/lf),
		"1,2" = list(/obj/structure/vehicleparts/frame/m113/rfc),
		"2,2" = list(/obj/structure/vehicleparts/frame/m113/fc),
		"3,2" = list(/obj/structure/vehicleparts/frame/m113/lfc),
		"1,3" = list(/obj/structure/vehicleparts/frame/m113/rbc),
		"2,3" = list(/obj/structure/vehicleparts/frame/m113/bc),
		"3,3" = list(/obj/structure/vehicleparts/frame/m113/lfc),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/m113/left/reversed, /obj/structure/vehicleparts/frame/m113/rb),
		"2,4" = list(/obj/structure/vehicleparts/frame/m113/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/m113/right/reversed, /obj/structure/vehicleparts/frame/m113/lb),
	)

/obj/effect/civ13_vehicle/apc/bmd2
	name = "BMD-2"
	custom_color = "#4A5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/bmd2
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/bmd2new/right_front, /obj/structure/vehicleparts/frame/bmd2/rf, /obj/structure/bed/chair/civ13/driver/tank),
		"2,1" = list(/obj/structure/vehicleparts/movement/tracks/bmd2new/left_front, /obj/structure/vehicleparts/frame/bmd2/lf, /obj/structure/bed/chair/civ13/passenger/mgunner/pkm, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"1,2" = list(/obj/structure/vehicleparts/frame/bmd2/rc, /obj/structure/vehicleparts/weapon/turret/bmd2, /obj/item/civ13_shell/magazine/a30mm_ap, /obj/item/civ13_shell/magazine/a30mm_ap, /obj/item/civ13_shell/magazine/a30mm_he, /obj/item/civ13_shell/magazine/a30mm_he, /obj/structure/vehicleparts/headlamp),
		"2,2" = list(/obj/structure/vehicleparts/frame/bmd2/lc),
		"1,3" = list(/obj/structure/vehicleparts/movement/tracks/bmd2new/right_back, /obj/structure/vehicleparts/frame/bmd2/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/bmd2, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,3" = list(/obj/structure/vehicleparts/movement/tracks/bmd2new/left_back, /obj/structure/vehicleparts/frame/bmd2/lb),
	)

/obj/effect/civ13_vehicle/apc/ba64
	name = "Ba-64"
	custom_color = "#3d5931"
	axis_type = /obj/structure/vehicleparts/axis/car/ba64
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/armored, /obj/structure/vehicleparts/frame/su85/rf, /obj/item/civ13_shell/magazine/maxim, /obj/item/civ13_shell/magazine/maxim, /obj/item/civ13_shell/magazine/maxim, /obj/item/civ13_shell/magazine/maxim, /obj/structure/vehicleparts/weapon/mg/stationary/maxim/ww2),
		"2,1" = list(/obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/frame/su85/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/su85/right/door),
		"2,2" = list(/obj/structure/vehicleparts/frame/car/left/metalreinforced),
		"1,3" = list(/obj/structure/vehicleparts/movement/armored, /obj/structure/vehicleparts/frame/defaultarmored/rb, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,3" = list(/obj/structure/vehicleparts/movement/armored/reversed, /obj/structure/vehicleparts/frame/defaultarmored/lb, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
	)

/obj/effect/civ13_vehicle/apc/btr80
	name = "BTR-80"
	custom_color = "#4A5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/btr80
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/armored/btr/right, /obj/structure/vehicleparts/frame/btr80/rf),
		"2,1" = list(/obj/structure/vehicleparts/movement/armored/btr/left, /obj/structure/vehicleparts/frame/btr80/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/btr80/rfc, /obj/structure/vehicleparts/weapon/turret/btr80),
		"2,2" = list(/obj/structure/vehicleparts/frame/btr80/lfc, /obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm),
		"1,3" = list(/obj/structure/vehicleparts/frame/btr80/rbc, /obj/structure/vehicleparts/headlamp),
		"2,3" = list(/obj/structure/vehicleparts/frame/btr80/lbc, /obj/item/civ13_shell/magazine/a30mm_ap/btr80, /obj/item/civ13_shell/magazine/a30mm_ap/btr80, /obj/item/civ13_shell/magazine/a30mm_he/btr80),
		"1,4" = list(/obj/structure/vehicleparts/movement/armored/btr/right/reversed, /obj/structure/vehicleparts/frame/btr80/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/btr80, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,4" = list(/obj/structure/vehicleparts/movement/armored/btr/left/reversed, /obj/structure/vehicleparts/frame/btr80/lb),
	)

/obj/effect/civ13_vehicle/apc/cv90
	name = "CV90"
	custom_color = "#4A5243"
	axis_type = /obj/structure/vehicleparts/axis/heavy/cv90
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/right, /obj/structure/vehicleparts/frame/cv90/rf),
		"2,1" = list(/obj/structure/vehicleparts/frame/cv90/front),
		"3,1" = list(/obj/structure/vehicleparts/movement/tracks/left, /obj/structure/vehicleparts/frame/cv90/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/cv90/right, /obj/structure/vehicleparts/headlamp, /obj/item/civ13_shell/magazine/a35mm_fap, /obj/item/civ13_shell/magazine/a35mm_fap, /obj/item/civ13_shell/magazine/a35mm_hei, /obj/item/civ13_shell/magazine/a35mm_hei),
		"2,2" = list(/obj/structure/vehicleparts/frame/cv90, /obj/structure/vehicleparts/weapon/turret/cv90),
		"3,2" = list(/obj/structure/vehicleparts/frame/cv90/left, /obj/item/civ13_shell/magazine/m249, /obj/item/civ13_shell/magazine/m249, /obj/item/civ13_shell/magazine/m249),
		"1,3" = list(/obj/structure/vehicleparts/frame/cv90/right),
		"2,3" = list(/obj/structure/vehicleparts/frame/cv90),
		"3,3" = list(/obj/structure/vehicleparts/frame/cv90/left),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/left/reversed, /obj/structure/vehicleparts/frame/cv90/rb, /obj/structure/vehicleparts/engine/internal/diesel/premade/btr80, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,4" = list(/obj/structure/vehicleparts/frame/cv90/back),
		"3,4" = list(/obj/structure/vehicleparts/movement/tracks/right/reversed, /obj/structure/vehicleparts/frame/cv90/lb),
	)

/obj/effect/civ13_vehicle/apc/bradley
	name = "M2 Bradley"
	custom_color = "#CCC0A6"
	axis_type = /obj/structure/vehicleparts/axis/heavy/bradley
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/movement/tracks/bradley/right_front, /obj/structure/vehicleparts/frame/bradley/rf, /obj/structure/vehicleparts/engine/internal/diesel/premade/m113, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,1" = list(/obj/structure/vehicleparts/movement/tracks/bradley/left_front, /obj/structure/vehicleparts/frame/bradley/lf, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/bradley/rfc),
		"2,2" = list(/obj/structure/vehicleparts/frame/bradley/lfc),
		"1,3" = list(/obj/structure/vehicleparts/frame/bradley/rbc, /obj/item/civ13_shell/magazine/a25mm_ap/bradley, /obj/item/civ13_shell/magazine/a25mm_ap/bradley, /obj/item/civ13_shell/magazine/a25mm_he/bradley, /obj/item/civ13_shell/magazine/a25mm_he/bradley, /obj/structure/vehicleparts/weapon/turret/bradley),
		"2,3" = list(/obj/structure/vehicleparts/frame/bradley/lbc, /obj/item/civ13_shell/magazine/m249, /obj/item/civ13_shell/magazine/m249, /obj/item/civ13_shell/magazine/m249),
		"1,4" = list(/obj/structure/vehicleparts/movement/tracks/bradley/right_back, /obj/structure/vehicleparts/frame/bradley/rb),
		"2,4" = list(/obj/structure/vehicleparts/movement/tracks/bradley/left_back, /obj/structure/vehicleparts/frame/bradley/lb),
	)

/obj/effect/civ13_vehicle/apc/bradley/green
	custom_color = "#313831"

/obj/effect/civ13_vehicle/tank/bmv1
	name = "BMV-1 mk. I"
	custom_color = "#3d5931"
	axis_type = /obj/structure/vehicleparts/axis/heavy/bmv1_1
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/bmv1/rf, /obj/structure/vehicleparts/movement/tracks/char1/right_front, /obj/structure/bed/chair/civ13/driver/tank),
		"2,1" = list(/obj/structure/vehicleparts/frame/bmv1/front),
		"3,1" = list(/obj/structure/vehicleparts/frame/bmv1/lf, /obj/structure/vehicleparts/movement/tracks/char1/left_front, /obj/structure/bed/chair/civ13/passenger/mgunner/dt28, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt),
		"1,2" = list(/obj/structure/vehicleparts/frame/bmv1/right/door),
		"2,2" = list(/obj/structure/vehicleparts/frame/bmv1/center, /obj/structure/vehicleparts/weapon/turret/bmv1),
		"3,2" = list(/obj/structure/vehicleparts/frame/bmv1/left, /obj/structure/vehicleparts/shellrack/full75),
		"1,3" = list(/obj/structure/vehicleparts/frame/bmv1/rb, /obj/structure/vehicleparts/movement/tracks/char1/right_back, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha),
		"2,3" = list(/obj/structure/vehicleparts/frame/bmv1/back, /obj/structure/vehicleparts/shellrack/full75),
		"3,3" = list(/obj/structure/vehicleparts/frame/bmv1/lb, /obj/structure/vehicleparts/movement/tracks/char1/left_back),
	)

/obj/effect/civ13_vehicle/tank/smf1
	name = "SMF I mod. A"
	custom_color = "#555346"
	axis_type = /obj/structure/vehicleparts/axis/heavy/smf1_a
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/smf1/rf, /obj/structure/vehicleparts/movement/tracks/t34/right_front, /obj/structure/bed/chair/civ13/passenger/mgunner/dt28),
		"2,1" = list(/obj/structure/vehicleparts/frame/smf1/front, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt, /obj/item/civ13_shell/magazine/dp/dt),
		"3,1" = list(/obj/structure/vehicleparts/frame/smf1/lf, /obj/structure/vehicleparts/movement/tracks/t34/left_front, /obj/structure/bed/chair/civ13/driver/tank),
		"1,2" = list(/obj/structure/vehicleparts/frame/smf1/right, /obj/structure/vehicleparts/shellrack/full75),
		"2,2" = list(/obj/structure/vehicleparts/frame/smf1/fc, /obj/structure/vehicleparts/weapon/turret/smf1, /obj/structure/vehicleparts/shellrack/full75),
		"3,2" = list(/obj/structure/vehicleparts/frame/smf1/left),
		"1,3" = list(/obj/structure/vehicleparts/frame/smf1/right/door),
		"2,3" = list(/obj/structure/vehicleparts/frame/smf1/bc),
		"3,3" = list(/obj/structure/vehicleparts/frame/smf1/left/door),
		"1,4" = list(/obj/structure/vehicleparts/frame/smf1/rb, /obj/structure/vehicleparts/movement/tracks/t34/right_back, /obj/structure/vehicleparts/engine/internal/diesel/premade/chiha, /obj/structure/vehicleparts/fueltank/tank/fueleddiesel),
		"2,4" = list(/obj/structure/vehicleparts/frame/smf1/back),
		"3,4" = list(/obj/structure/vehicleparts/frame/smf1/lb, /obj/structure/vehicleparts/movement/tracks/t34/left_back, /obj/structure/vehicleparts/shellrack/full75),
	)

/obj/structure/vehicleparts/fueltank/smalltank/fueledgasoline
	start_fuel = 200

/obj/structure/vehicleparts/engine/internal/gasoline/ethanol/premade/piccolino
	name = "four-stroke gasoline-ethanol engine"
	desc = "A relatively cheap four-stroke gasoline engine, converted to use ethanol too. Can run on both fuels, but its around 15% less efficient."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 240.8
	fuel_use = 0.9799999999999999

/obj/structure/vehicleparts/license_plate/eu/centered/front
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_eur"

/obj/structure/bed/chair/civ13/passenger/carseat/right
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_right"

/obj/structure/bed/chair/civ13/driver/car
	name = "driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_driver_left"

/obj/structure/vehicleparts/license_plate/eu/centered
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_eur"

/obj/structure/vehicleparts/engine/internal/gasoline/premade/quattroporte
	name = "four-stroke gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 300
	fuel_use = 0.9

/obj/structure/bed/chair/civ13/passenger/carseat/left
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_left"

/obj/structure/vehicleparts/fueltank/tank/fueleddiesel
	start_fuel = 200

/obj/structure/vehicleparts/engine/internal/diesel/premade/erstenklasse
	name = "diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 440
	fuel_use = 1.21

/obj/structure/bed/chair/civ13/passenger/carseat/right/lion
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_right"

/obj/structure/bed/chair/civ13/driver/car/lion
	name = "driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_driver_left"

/obj/structure/bed/chair/civ13/passenger/carseat/left/lion
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_left"

/obj/structure/vehicleparts/fueltank/tank/fueledgasoline
	start_fuel = 200

/obj/structure/vehicleparts/engine/internal/gasoline/premade/falcon
	name = "four-stroke gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 650
	fuel_use = 1.95

/obj/structure/vehicleparts/license_plate/us/centered/front
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_us"

/obj/structure/vehicleparts/license_plate/us/centered
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_us"

/obj/structure/vehicleparts/engine/internal/diesel/premade/wyoming
	name = "diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 640
	fuel_use = 1.76

/obj/structure/vehicleparts/engine/internal/gasoline/wankel/premade/shinobu
	name = "Wankel rotary gasoline engine"
	desc = "A somewhat complex rotary engine. Very high Power-To-Weight ratio, but bad fuel economy."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "wankel_static"
	power = 1050
	fuel_use = 2.59

/obj/structure/bed/chair/civ13/passenger/carseat/right/dark
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_right"

/obj/structure/bed/chair/civ13/driver/car/dark
	name = "driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_driver_left"

/obj/structure/bed/chair/civ13/passenger/carseat/left/dark
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_left"

/obj/structure/vehicleparts/engine/internal/gasoline/premade/kazoku
	name = "four-stroke gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 380
	fuel_use = 1.14

/obj/structure/vehicleparts/engine/internal/gasoline/premade/type95
	name = "four-stroke gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 380
	fuel_use = 1.14

/obj/structure/bed/chair/civ13/driver/car/type95
	name = "driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_driver_right_type95"

/obj/structure/bed/chair/civ13/passenger/carseat/left/type95
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_left_type95"

/obj/structure/bed/chair/civ13/passenger/carseat/right/type95
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_right_type95"

/obj/structure/vehicleparts/engine/internal/gasoline/premade/type94
	name = "four-stroke gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 440
	fuel_use = 0.44

/obj/structure/bed/chair/civ13/driver/car/type94
	name = "driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_driver_right_type94"

/obj/structure/bed/chair/civ13/passenger/carseat/left/type94
	name = "car seat"
	desc = "A leather car seat."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_left_type94"

/obj/structure/vehicleparts/license_plate/eu
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_eur"

/obj/structure/vehicleparts/engine/internal/diesel/premade/v6
	name = "V6 diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 640
	fuel_use = 1.76

/obj/structure/vehicleparts/license_plate/nl/centered/front
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_nl"

/obj/structure/bed/chair/civ13/passenger/office/dark

/obj/structure/bed/chair/civ13/driver
	name = "driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "driver_car"

/obj/structure/vehicleparts/license_plate/nl/centered
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_nl"

/obj/structure/vehicleparts/weapon/mg/stationary/m2browning
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "M2HB browning machine gun"
	desc = "An american heavy machinegun. Chambered in .50 cal rounds."
	icon_state = "m2"
	caliber = 12.7
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/a50cal_can)

/obj/item/civ13_shell/magazine/a50cal_can
	name = ".50 BMG ammo can"
	desc = "A magazine for some kind of gun."
	icon_state = "b762x51"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 12.7
	rounds = 150
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/license_plate/ru_mil/centered/front
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_ru_mil"

/obj/structure/vehicleparts/license_plate/ru_mil/centered
	name = "license plate"
	desc = "A vehicle registration plate."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "license_plate_ru_mil"

/obj/structure/vehicleparts/weapon/mg/stationary/pkm
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "PKM machine gun"
	desc = "Soviet Heavy PKM machinegun. Uses 7.62x54mm rounds."
	icon_state = "pkm"
	caliber = 7.62
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/pkm, /obj/item/civ13_shell/magazine/pkm/c100, /obj/item/civ13_shell/magazine/maxim)

/obj/item/civ13_shell/magazine/pkm/c100
	name = "PKM ammo belt (7.62x54mmR)"
	desc = "A magazine for some kind of gun."
	icon_state = "b762x54"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.62
	rounds = 100
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/fueltank/smalltank/fueleddiesel
	start_fuel = 200

/obj/structure/vehicleparts/engine/internal/diesel/premade/v12
	name = "V12 diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 1200
	fuel_use = 3.3

/obj/structure/vehicleparts/weapon/turret/technical_dshk
	icon = 'icons/obj/civ13/mgs.dmi'
	icon_state = "dshk"
	name = "DSHK"
	turret_icon = ""
	turret_x = 16
	turret_y = 7
	turret_color = "#4a5243"
	rotation_speed = 0.2
	gunner_x = 0
	gunner_y = 4
	loader_x = -16
	loader_y = 0
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/mg/stationary/dshk)
	crew_roles = list("gunner")

/obj/item/civ13_shell/magazine/ammo127
	name = "Ammo can (12.7x108mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "b127"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 12.7
	rounds = 50
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/engine/internal/gasoline/premade/v6
	name = "V6 gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 700
	fuel_use = 2.1

/obj/item/civ13_shell/magazine/mg34belt
	name = "MG 34 ammo belt"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.92
	rounds = 250
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/mg/stationary/mg34
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "MG 34 machine gun"
	desc = "A german heavy machinegun. Chambered in 7.92x57 Mauser."
	icon_state = "mg34hmg"
	caliber = 7.92
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/mg34belt, /obj/item/civ13_shell/magazine/mg34)

/obj/structure/bed/chair/civ13/driver/tank
	name = "tank driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "driver_tank"

/obj/structure/vehicleparts/shellrack/full75
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 75
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP75

/obj/structure/vehicleparts/weapon/turret/pziv
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "PZ-IV"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "pziv_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#585A5C"
	rotation_speed = 1.1
	gunner_x = 11
	gunner_y = -2
	loader_x = -11
	loader_y = -2
	commander_x = 0
	commander_y = 11
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/german75, /obj/structure/vehicleparts/weapon/mg/stationary/mg34)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/engine/internal/gasoline/premade/panzeriv
	name = "four-stroke gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 1200
	fuel_use = 3.6

/obj/structure/bed/chair/civ13/passenger/mgunner/mg34
	name = "machinegunner's seat"
	desc = "A seat with a course machinegun."
	icon_state = "officechair_white"
	station_weapon = /obj/structure/vehicleparts/weapon/mg/manual/mg34

/obj/structure/vehicleparts/shellrack/full88
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 88
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP88

/obj/structure/vehicleparts/weapon/turret/pzvi
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "PZ-VI"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "tiger_tank"
	turret_x = 0
	turret_y = 16
	turret_color = "#585A5C"
	rotation_speed = 1.3
	gunner_x = 11
	gunner_y = -2
	loader_x = -11
	loader_y = -2
	commander_x = 0
	commander_y = 11
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/german88, /obj/structure/vehicleparts/weapon/mg/stationary/mg34)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/headlamp

/obj/item/civ13_shell/magazine/pkm
	name = "PKM ammo belt (7.62x54mmR)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.62
	rounds = 250
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/bed/chair/civ13/passenger/commander
	name = "commander's seat"
	desc = "The vehicle commander's seat, with a perisope."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "commanders_seat"

/obj/structure/vehicleparts/weapon/cannon/omwtc10
	name = "OMW-TC 100mm"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 100mm Redmenian tank-based cannon."
	caliber = 100
	maxrange = 35
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/bed/chair/civ13/passenger/loader
	name = "loader's seat"
	desc = "A seat at the gun loader's position."
	icon_state = "officechair_white"

/obj/structure/bed/chair/civ13/passenger/gunner
	name = "gunner's seat"
	desc = "A seat next to the gun trigger."
	icon_state = "officechair_white"

/obj/structure/vehicleparts/shellrack/full100modern
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 100
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP100

/obj/structure/vehicleparts/engine/internal/diesel/premade/omw22_2
	name = "OMW 15 liter diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 1200
	fuel_use = 3.3

/obj/structure/vehicleparts/headlamp

/obj/structure/vehicleparts/weapon/cannon/baftkn75
	name = "BAF TKN 75mm"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 75mm Blugoslavian tank-based cannon."
	caliber = 75
	maxrange = 30
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/engine/internal/gasoline/premade/baf1_a
	name = "BAF 12 gasoline engine"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 1200
	fuel_use = 3.6

/obj/item/civ13_shell/magazine/browning
	name = "browning ammo belt"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.62
	rounds = 250
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/bed/chair/civ13/passenger/mgunner/browning_lmg
	name = "machinegunner's seat"
	desc = "A seat with a course machinegun."
	icon_state = "officechair_white"
	station_weapon = /obj/structure/vehicleparts/weapon/mg/browning_lmg

/obj/structure/vehicleparts/weapon/turret/sherman
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "M-4 Sherman"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "m4_turret"
	turret_x = 0
	turret_y = 8
	turret_color = "#635931"
	rotation_speed = 0.8
	gunner_x = 9
	gunner_y = -8
	loader_x = 9
	loader_y = 8
	commander_x = -13
	commander_y = 6
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/american75, /obj/structure/vehicleparts/weapon/mg/browning_lmg)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/engine/internal/diesel/premade/chiha
	name = "diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 2000
	fuel_use = 5.5

/obj/item/civ13_shell/magazine/type92
	name = "Type 92 ammo belt"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.7
	rounds = 30
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/mg/stationary/type98
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "Type 92 machine gun"
	desc = "A japanese heavy machinegun. Chambered in 7.7x58mm Arisaka."
	icon_state = "type92hmg"
	caliber = 7.7
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/type92)

/obj/structure/vehicleparts/weapon/cannon/japanese57
	name = "Type 97 Cannon"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 57mm Japanese tank-based cannon."
	caliber = 57
	maxrange = 25
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/shellrack/full57
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 57
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP57

/obj/structure/bed/chair/civ13/passenger/mgunner/type97
	name = "machinegunner's seat"
	desc = "A seat with a course machinegun."
	icon_state = "officechair_white"
	station_weapon = /obj/structure/vehicleparts/weapon/mg/type99/type97tank

/obj/item/civ13_shell/magazine/type99/type97
	name = "Type-97 Magazine"
	desc = "A magazine for some kind of gun."
	icon_state = "type97"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.7
	rounds = 20
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/turret/hago
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "Type 95 Ha-Go"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "type95_turret"
	turret_x = -12
	turret_y = 0
	turret_color = "#6a5a3d"
	rotation_speed = 2
	gunner_x = 0
	gunner_y = 0
	loader_x = -16
	loader_y = 0
	commander_x = 0
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/japanese37, /obj/structure/vehicleparts/weapon/mg/type99/type97tank)
	crew_roles = list("gunner")

/obj/structure/vehicleparts/engine/internal/diesel/premade/hago
	name = "diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 800
	fuel_use = 2.2

/obj/structure/vehicleparts/shellrack/full37
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 37
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP37

/obj/structure/bed/chair/civ13/driver/tank/anchored
	name = "tank driver's seat"
	desc = "Where you drive the vehicle."
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "driver_tank"

/obj/structure/bed/chair/civ13/passenger/office/dark/anchored

/obj/structure/vehicleparts/weapon/mg/stationary/breda30/hull
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "vehicle mounted Breda 30 machine gun"
	desc = "The Fucile Mitragliatore Breda modello 30 is a Italian light machinegun that entered service in 1930. The design of the gun is rather impractical and often makes for long reload times. Chambered in 6.5x52mm Carcano."
	icon_state = "type92hmg"
	caliber = 6.5
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/breda30)

/obj/item/civ13_shell/magazine/breda30
	name = "Breda 30 clip (6.5x52mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "breda30"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 6.5
	rounds = 20
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/engine/internal/gasoline/premade/l3
	name = "FIAT-SPA CV3"
	desc = "A relatively cheap four-stroke gasoline engine."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "gasoline_static"
	power = 430
	fuel_use = 1.29

/obj/structure/vehicleparts/weapon/mg/stationary/solothurn/italian/stationary
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "vehicle mounted Fucile Controcarri S Mod.39"
	desc = "An Italian variant of the Swiss Solothurn S18/1000 20mm anti-tank rifle. It is a later variant of the S-18/100 with modifications for a higher muzzle velocity, as well as a larger cartridge size. The more powerful ammunition resulted in significant recoil, which was problematic for the gunner, and its size made portability difficult."
	icon_state = "type92hmg"
	caliber = 20
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/a20mm_aphe)

/obj/item/civ13_shell/magazine/a20mm_aphe
	name = "APHE clip (20mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "breda30"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 20
	rounds = 10
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/cannon/italian47
	name = "47mm 47/32 mod.35"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "An 45mm Italian tank-based cannon."
	caliber = 47
	maxrange = 25
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/shellrack/full47
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 47
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP47

/obj/structure/vehicleparts/engine/internal/diesel/premade/m13
	name = "SPA 8 T M40 11"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 1000
	fuel_use = 2.75

/obj/structure/bed/chair/civ13/passenger/mgunner/dt28
	name = "machinegunner's seat"
	desc = "A seat with a course machinegun."
	icon_state = "officechair_white"
	station_weapon = /obj/structure/vehicleparts/weapon/mg/dp28/dt28

/obj/item/civ13_shell/magazine/dp/dt
	name = "DT magazine (7.62x54mmR)"
	desc = "A magazine for some kind of gun."
	icon_state = "dt_drum"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.62
	rounds = 60
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/shellrack/full76
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 76
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP76

/obj/structure/vehicleparts/weapon/turret/t34
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-34"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t34_turret"
	turret_x = 0
	turret_y = 0
	turret_color = "#3d5931"
	rotation_speed = 0.5 // seconds for 1 degree
	gunner_x = 9
	gunner_y = -2
	loader_x = -9
	loader_y = -2
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/russian76, /obj/structure/vehicleparts/weapon/mg/dp28/dt28)
	crew_roles = list("gunner", "loader")

/obj/structure/vehicleparts/shellrack/full45
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 45
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP45

/obj/structure/vehicleparts/weapon/turret/bt7
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "BT-7"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "bt7_turret"
	turret_x = -16
	turret_y = 0
	turret_color = "#5c784f"
	rotation_speed = 0.5 // seconds for 1 degree
	gunner_x = 9
	gunner_y = -2
	loader_x = -9
	loader_y = -2
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/russian76, /obj/structure/vehicleparts/weapon/mg/dp28/dt28)
	crew_roles = list("gunner", "loader")

/obj/structure/bed/chair/civ13/passenger/mgunner/dtm28
	name = "machinegunner's seat"
	desc = "A seat with a course machinegun."
	icon_state = "officechair_white"
	station_weapon = /obj/structure/vehicleparts/weapon/mg/dp28/dt28/dtm28

/obj/structure/vehicleparts/shellrack/full85
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 85
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP85

/obj/structure/vehicleparts/weapon/turret/t3485
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-34-85"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t3485_turret"
	turret_x = 0
	turret_y = 0
	turret_color = "#4a5243"
	rotation_speed = 0.5 // seconds for 1 degree
	gunner_x = 11
	gunner_y = -12
	loader_x = -11
	loader_y = -2
	commander_x = 11
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/russian85, /obj/structure/vehicleparts/weapon/mg/dp28/dt28)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/weapon/turret/kv1
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "KV-1"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "kv1_turret"
	turret_x = 0
	turret_y = 0
	turret_color = "#3d5931"
	rotation_speed = 1
	gunner_x = 9
	gunner_y = -2
	loader_x = -9
	loader_y = -2
	commander_x = 0
	commander_y = 11
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/russian76, /obj/structure/vehicleparts/weapon/mg/dp28/dt28)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/shellrack/full100ww2
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 100
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP100

/obj/structure/vehicleparts/weapon/turret/course/su100
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "SU-100"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "su100_turret"
	turret_x = 0
	turret_y = 0
	turret_color = "#4a5243"
	rotation_speed = 0.5 // seconds for 1 degree
	gunner_x = 12
	gunner_y = 8
	loader_x = -6
	loader_y = 18
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/russian100)
	crew_roles = list("gunner", "loader")
	fixed_mount = TRUE

/obj/structure/vehicleparts/weapon/turret/course/su85m
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "SU-85M"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "su100_turret"
	turret_x = 0
	turret_y = 0
	turret_color = "#4a5243"
	rotation_speed = 0.5 // seconds for 1 degree
	gunner_x = 12
	gunner_y = 8
	loader_x = -6
	loader_y = 18
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/russian85)
	crew_roles = list("gunner", "loader")
	fixed_mount = TRUE

/obj/structure/vehicleparts/weapon/turret/t55
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-55"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t55_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#5c5c4c"
	rotation_speed = 1.1
	gunner_x = 11
	gunner_y = -17
	loader_x = -13
	loader_y = 3
	commander_x = 16
	commander_y = 2
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/russian100, /obj/structure/vehicleparts/weapon/mg/stationary/dshk)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/shellrack/autoloader/full125
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods. This one designed to feed into an autoloader, neat!"
	icon_state = "shellrack0"
	caliber = 125
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP125

/obj/structure/vehicleparts/weapon/turret/t64bm
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-64BM"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t64bm_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#5c5c4c"
	rotation_speed = 0.7
	gunner_x = 16
	gunner_y = 5
	loader_x = -16
	loader_y = 0
	commander_x = -16
	commander_y = 6
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/autoloader/t90a, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner", "commander")

/obj/structure/vehicleparts/weapon/turret/t72
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-72"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t72_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#5c5c4c"
	rotation_speed = 0.8
	gunner_x = 14
	gunner_y = 3
	loader_x = -16
	loader_y = 0
	commander_x = -14
	commander_y = 7
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/autoloader/t90a, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner", "commander")

/obj/structure/vehicleparts/weapon/turret/t72/t72b3
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-72B3"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t72b3_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#5c5c4c"
	rotation_speed = 0.3
	gunner_x = 14
	gunner_y = 3
	loader_x = -16
	loader_y = 0
	commander_x = -14
	commander_y = 7
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/autoloader/t90a, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner", "commander")

/obj/structure/vehicleparts/weapon/turret/t72/t72m1
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-72M1"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t72m1_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#5c5c4c"
	rotation_speed = 0.6
	gunner_x = 14
	gunner_y = 3
	loader_x = -16
	loader_y = 0
	commander_x = -14
	commander_y = 7
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/autoloader/t90a, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner", "commander")

/obj/structure/vehicleparts/weapon/turret/t80u/t80uk
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-80UK"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t80uk_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#5c5c4c"
	rotation_speed = 0.6
	gunner_x = 16
	gunner_y = 5
	loader_x = -16
	loader_y = 0
	commander_x = -14
	commander_y = 5
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/autoloader/t90a, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner", "commander")

/obj/structure/vehicleparts/weapon/turret/t90a
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "T-90A"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t90a_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#4a5243"
	rotation_speed = 0.6
	gunner_x = 16
	gunner_y = 8
	loader_x = -16
	loader_y = 0
	commander_x = -14
	commander_y = 6
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/autoloader/t90a, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner", "commander")

/obj/structure/vehicleparts/shellrack/full120
	icon = 'icons/obj/civ13/structures.dmi'
	name = "shell rack"
	desc = "A rack for storage your explosive goods."
	icon_state = "shellrack0"
	caliber = 120
	start_shells = 6
	start_shell_type = /obj/item/civ13_shell/AP120

/obj/structure/vehicleparts/weapon/turret/m1abrams
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "M1A1_turret"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "m1a1_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#4a5243"
	rotation_speed = 0.4
	gunner_x = 16
	gunner_y = -16
	loader_x = 16
	loader_y = 10
	commander_x = -10
	commander_y = 16
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/m1a1_abrams, /obj/structure/vehicleparts/weapon/mg/manual/m249)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/engine/internal/turbine/abrams
	name = "Honeywell AGT1500 turbine engine"
	desc = "A turbine engine using an air compressor. High Power-To-Weight ratio and can run on a lot of fuels, but has bad fuel economy."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "turbine_static"
	power = 2040
	fuel_use = 6

/obj/item/civ13_shell/magazine/mg3belt
	name = "belt (7.62x51mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.92
	rounds = 100
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/turret/challenger2
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "Challenger-2"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "challenger2_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#4a5243"
	rotation_speed = 0.4
	gunner_x = -16
	gunner_y = -16
	loader_x = 16
	loader_y = 16
	commander_x = -16
	commander_y = 16
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/leopard, /obj/structure/vehicleparts/weapon/mg/stationary/mg3)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/weapon/turret/leo2a6
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "2A6"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "2a6_turret"
	turret_x = 0
	turret_y = 16
	turret_color = "#4a5243"
	rotation_speed = 0.3
	gunner_x = 16
	gunner_y = -16
	loader_x = 16
	loader_y = 16
	commander_x = -16
	commander_y = 16
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/leopard, /obj/structure/vehicleparts/weapon/mg/stationary/mg3)
	crew_roles = list("gunner", "loader", "commander")

/obj/structure/vehicleparts/weapon/turret/mtlb
	icon = 'icons/obj/civ13/mgs.dmi'
	icon_state = "pkm"
	name = "MTLB"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "mtlb_turret"
	turret_x = 3
	turret_y = 12
	turret_color = "#4a5243"
	rotation_speed = 0.9
	gunner_x = 0
	gunner_y = 0
	loader_x = -16
	loader_y = 0
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner")

/obj/structure/vehicleparts/engine/internal/diesel/premade/mtlb
	name = "YaMZ 238 diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 1200
	fuel_use = 3.3

/obj/structure/vehicleparts/engine/internal/diesel/premade/m113
	name = "Detroit 6V53T diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 1200
	fuel_use = 3.3

/obj/structure/vehicleparts/weapon/mg/stationary/browning
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "M1919A1 browning machine gun"
	desc = "An american heavy machinegun. Chambered in 30-06. rounds."
	icon_state = "browning"
	caliber = 7.62
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/browning)

/obj/structure/bed/chair/civ13/passenger/mgunner/pkm
	name = "machinegunner's seat"
	desc = "A seat with a course machinegun."
	icon_state = "officechair_white"
	station_weapon = /obj/structure/vehicleparts/weapon/mg/pkm

/obj/structure/vehicleparts/weapon/turret/bmd2
	icon = 'icons/obj/civ13/mgs.dmi'
	icon_state = "autocannon"
	name = "BMD-2"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "bmd2_turret"
	turret_x = 16
	turret_y = -16
	turret_color = "#787859"
	rotation_speed = 0.3
	gunner_x = 4
	gunner_y = 0
	loader_x = -16
	loader_y = 0
	commander_x = -4
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/shipunov2a42, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner", "commander")

/obj/item/civ13_shell/magazine/a30mm_ap
	name = "AP-T ammo belt (30mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 30
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/item/civ13_shell/magazine/a30mm_he
	name = "HE-T ammo belt (30mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 30
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "HE"

/obj/structure/vehicleparts/engine/internal/diesel/premade/bmd2
	name = "5D-20 15 diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 1200
	fuel_use = 3.3

/obj/item/civ13_shell/magazine/maxim
	name = "Maxim ammo belt"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.62
	rounds = 250
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/mg/stationary/maxim/ww2
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "Maxim"
	desc = "Russian version of the original Maxim machinegun, on cart mount. Uses Russian 7.62x54mm rounds."
	icon_state = "maxim_ww2"
	caliber = 7.62
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/maxim)

/obj/structure/vehicleparts/weapon/turret/btr80
	icon = 'icons/obj/civ13/mgs.dmi'
	icon_state = "autocannon"
	name = "BTR-80"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "btr80_turret"
	turret_x = 16
	turret_y = 0
	turret_color = "#4a5243"
	rotation_speed = 0.4
	gunner_x = 0
	gunner_y = 4
	loader_x = -16
	loader_y = 0
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/shipunov2a72, /obj/structure/vehicleparts/weapon/mg/pkm)
	crew_roles = list("gunner")

/obj/item/civ13_shell/magazine/a30mm_ap/btr80
	name = "AP-T ammo belt (30mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 30
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/item/civ13_shell/magazine/a30mm_he/btr80
	name = "HE-T ammo belt (30mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 30
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/engine/internal/diesel/premade/btr80
	name = "KamAZ-7403 diesel engine"
	desc = "A heavy diesel engine, using compression instead of spark plugs. High torque and fuel efficiency."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 1200
	fuel_use = 3.3

/obj/item/civ13_shell/magazine/a35mm_fap
	name = "FAP ammo belt (35mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 35
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/item/civ13_shell/magazine/a35mm_hei
	name = "HEI-T ammo belt (35mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 35
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/turret/cv90
	icon = 'icons/obj/civ13/mgs.dmi'
	icon_state = "autocannon"
	name = "CV90"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "cv90_turret"
	turret_x = 0
	turret_y = 12
	turret_color = "#4a5243"
	rotation_speed = 0.3
	gunner_x = -8
	gunner_y = 0
	loader_x = -16
	loader_y = 0
	commander_x = 8
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/bushmaster, /obj/structure/vehicleparts/weapon/mg/manual/m249)
	crew_roles = list("gunner", "commander")

/obj/item/civ13_shell/magazine/m249
	name = "belt (5.56x45mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "b762"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 5.56
	rounds = 100
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/item/civ13_shell/magazine/a25mm_ap/bradley
	name = "AP-T ammo belt (25 mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 25
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/item/civ13_shell/magazine/a25mm_he/bradley
	name = "HE-T ammo belt (25 mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "maximbelt"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 25
	rounds = 150
	damage = 80
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/turret/bradley
	icon = 'icons/obj/civ13/mgs.dmi'
	icon_state = "autocannon"
	name = "Bradley"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "bradley_turret"
	turret_x = 9
	turret_y = -1
	turret_color = "#4a5243"
	rotation_speed = 0.3
	gunner_x = -8
	gunner_y = 0
	loader_x = -16
	loader_y = 0
	commander_x = 8
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/bushmaster/bradley, /obj/structure/vehicleparts/weapon/mg/manual/m249)
	crew_roles = list("gunner", "commander")

/obj/structure/vehicleparts/weapon/turret/bmv1
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "BMV-1 mk. I"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "char1_turret"
	turret_x = 0
	turret_y = 0
	turret_color = "#3d5931"
	rotation_speed = 0.5 // seconds for 1 degree
	gunner_x = 9
	gunner_y = -2
	loader_x = -9
	loader_y = -2
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/bmv75, /obj/structure/vehicleparts/weapon/mg/dp28/dt28)
	crew_roles = list("gunner", "loader")

/obj/structure/vehicleparts/weapon/turret/smf1
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	name = "SMF I mod. A"
	icon = 'icons/obj/civ13/vehicles256x256.dmi'
	icon_state = ""
	turret_icon = "t34_turret"
	turret_x = 0
	turret_y = 0
	turret_color = "#555346"
	rotation_speed = 0.5 // seconds for 1 degree
	gunner_x = 9
	gunner_y = -2
	loader_x = -9
	loader_y = -2
	commander_x = 10
	commander_y = 0
	weapon_types = list(/obj/structure/vehicleparts/weapon/cannon/smf75, /obj/structure/vehicleparts/weapon/mg/dp28/dt28)
	crew_roles = list("gunner", "loader")

/obj/item/civ13_shell/HE37
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 37
	atype = "HE"
	damage = 225
	heavy_armor_penetration = 5

/obj/item/civ13_shell/AP37
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 37
	atype = "AP"
	damage = 95
	heavy_armor_penetration = 65

/obj/item/civ13_shell/APCR37
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 37
	atype = "APCR"
	damage = 115
	heavy_armor_penetration = 85

/obj/item/civ13_shell/HE45
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 45
	atype = "HE"
	damage = 290
	heavy_armor_penetration = 5

/obj/item/civ13_shell/AP45
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 45
	atype = "AP"
	damage = 75
	heavy_armor_penetration = 70

/obj/item/civ13_shell/APCR45
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 45
	atype = "APCR"
	damage = 90
	heavy_armor_penetration = 94

/obj/item/civ13_shell/HE47
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 47
	atype = "HE"
	damage = 290
	heavy_armor_penetration = 8

/obj/item/civ13_shell/AP47
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 47
	atype = "AP"
	damage = 75
	heavy_armor_penetration = 40

/obj/item/civ13_shell/APCR47
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 47
	atype = "APCR"
	damage = 90
	heavy_armor_penetration = 60

/obj/item/civ13_shell/HE57
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 57
	atype = "HE"
	damage = 225
	heavy_armor_penetration = 15

/obj/item/civ13_shell/AP57
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 57
	atype = "AP"
	damage = 95
	heavy_armor_penetration = 52

/obj/item/civ13_shell/APCR57
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 57
	atype = "APCR"
	damage = 115
	heavy_armor_penetration = 75

/obj/item/civ13_shell/HE75
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 75
	atype = "HE"
	damage = 250
	heavy_armor_penetration = 15

/obj/item/civ13_shell/AP75
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 75
	atype = "AP"
	damage = 100
	heavy_armor_penetration = 52

/obj/item/civ13_shell/APCR75
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 75
	atype = "APCR"
	damage = 125
	heavy_armor_penetration = 75

/obj/item/civ13_shell/HE100
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 100
	atype = "HE"
	damage = 333
	heavy_armor_penetration = 27

/obj/item/civ13_shell/AP100
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 100
	atype = "AP"
	damage = 133
	heavy_armor_penetration = 180

/obj/item/civ13_shell/APCR100
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 100
	atype = "APCR"
	damage = 100
	heavy_armor_penetration = 220

/obj/item/civ13_shell/HEAT100
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 100
	atype = "HEAT"
	damage = 100
	heavy_armor_penetration = 0

/obj/item/civ13_shell/HE115
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 115
	atype = "HE"
	damage = 333
	heavy_armor_penetration = 27

/obj/item/civ13_shell/AP115
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 115
	atype = "AP"
	damage = 133
	heavy_armor_penetration = 220

/obj/item/civ13_shell/APCR115
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 115
	atype = "APCR"
	damage = 100
	heavy_armor_penetration = 400

/obj/item/civ13_shell/HEAT115
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 115
	atype = "HEAT"
	damage = 100
	heavy_armor_penetration = 350

/obj/item/civ13_shell/HE120
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 120
	atype = "HE"
	damage = 333
	heavy_armor_penetration = 40

/obj/item/civ13_shell/AP120
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 120
	atype = "AP"
	damage = 140
	heavy_armor_penetration = 200

/obj/item/civ13_shell/APCR120
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 120
	atype = "APCR"
	damage = 100
	heavy_armor_penetration = 450

/obj/item/civ13_shell/HEAT120
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 120
	atype = "HEAT"
	damage = 100
	heavy_armor_penetration = 450

/obj/item/civ13_shell/HE122
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 122
	atype = "HE"
	damage = 333
	heavy_armor_penetration = 35

/obj/item/civ13_shell/AP122
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 122
	atype = "AP"
	damage = 140
	heavy_armor_penetration = 215

/obj/item/civ13_shell/HE125
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 125
	atype = "HE"
	damage = 333
	heavy_armor_penetration = 45

/obj/item/civ13_shell/AP125
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 125
	atype = "AP"
	damage = 140
	heavy_armor_penetration = 450

/obj/item/civ13_shell/APCR125
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 125
	atype = "APCR"
	damage = 100
	heavy_armor_penetration = 450

/obj/item/civ13_shell/HEAT125
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 125
	atype = "HEAT"
	damage = 100
	heavy_armor_penetration = 450

/obj/item/civ13_shell/HE90
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 90
	atype = "HE"
	damage = 350
	heavy_armor_penetration = 20

/obj/item/civ13_shell/AP90
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 90
	atype = "AP"
	damage = 145
	heavy_armor_penetration = 180

/obj/item/civ13_shell/APCR90
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 90
	atype = "APCR"
	damage = 175
	heavy_armor_penetration = 300

/obj/item/civ13_shell/HE88
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 88
	atype = "HE"
	damage = 350
	heavy_armor_penetration = 20

/obj/item/civ13_shell/AP88
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 88
	atype = "AP"
	damage = 145
	heavy_armor_penetration = 150

/obj/item/civ13_shell/APCR88
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 88
	atype = "APCR"
	damage = 175
	heavy_armor_penetration = 270

/obj/item/civ13_shell/HE85
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 85
	atype = "HE"
	damage = 330
	heavy_armor_penetration = 20

/obj/item/civ13_shell/AP85
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 85
	atype = "AP"
	damage = 140
	heavy_armor_penetration = 140

/obj/item/civ13_shell/APCR85
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 85
	atype = "APCR"
	damage = 170
	heavy_armor_penetration = 195

/obj/item/civ13_shell/HE76
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 76.2
	atype = "HE"
	damage = 250
	heavy_armor_penetration = 10

/obj/item/civ13_shell/AP76
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 76.2
	atype = "AP"
	damage = 100
	heavy_armor_penetration = 100

/obj/item/civ13_shell/APCR76
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 76.2
	atype = "APCR"
	damage = 125
	heavy_armor_penetration = 125

/obj/item/civ13_shell/HE204
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 204
	atype = "HE"
	damage = 500
	heavy_armor_penetration = 100

/obj/item/civ13_shell/AP204
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 204
	atype = "AP"
	damage = 400
	heavy_armor_penetration = 350

/obj/item/civ13_shell/APCR204
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 204
	atype = "APCR"
	damage = 450
	heavy_armor_penetration = 350

/obj/item/civ13_shell/nuclear
	icon = 'icons/obj/civ13/cannon_ball.dmi'
	name = "cannon shell"
	icon_state = "shellHE"
	caliber = 75
	atype = "NUCLEAR"
	damage = 100
	heavy_armor_penetration = 15

/obj/structure/vehicleparts/weapon/mg/stationary/dshk
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "DShK machine gun"
	desc = "Soviet Heavy DShK machinegun, can also be as anti vehicle gun against some lightly armored vehicles. Uses 12.7x108mm rounds."
	icon_state = "dshk"
	caliber = 12.7
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/ammo127)

/obj/item/civ13_shell/magazine/mg34
	name = "MG34 magazine (7.92x57mm)"
	desc = "A magazine for some kind of gun."
	icon_state = "mg34"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.92
	rounds = 50
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"

/obj/structure/vehicleparts/weapon/cannon/german75
	name = "7.5cm KwK 40"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 75mm German tank-based cannon."
	caliber = 75
	maxrange = 25
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/mg/manual/mg34
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "MG34"
	desc = "German light machinegun chambered in 7.92x57mm Mauser. An utterly devastating support weapon."
	icon_state = "mg34"
	caliber = 7.92
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/mg34, /obj/item/civ13_shell/magazine/mg34belt)

/obj/structure/vehicleparts/weapon/cannon/german88
	name = "8.8 cm KwK 36"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 88mm German tank-based cannon."
	caliber = 88
	maxrange = 35
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/mg/browning_lmg
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "M1919A6 Browning LMG"
	desc = "An American squad support machinegun. Uses 30-06 rounds. Very heavy to carry around."
	icon_state = "browlmg"
	caliber = 7.62
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/browning)

/obj/structure/vehicleparts/weapon/cannon/american75
	name = "75mm M3 gun"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 75mm american tank-based cannon."
	caliber = 75
	maxrange = 25
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/mg/type99/type97tank
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "Type 97 tank machinegun"
	desc = "The Type 97 tank machine Gun, is a Japanese machine gun based on the ZB26 designed specifically for tank use."
	icon_state = "type97lmg"
	caliber = 7.7
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/type99/type97)

/obj/structure/vehicleparts/weapon/cannon/japanese37
	name = "Type 94 Cannon"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 37mm Japanese tank-based cannon."
	caliber = 37
	maxrange = 25
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/mg/dp28/dt28
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "DT-28"
	desc = "The DT-28 light machinegun. Designed to be places in vehicles. This one is in 7.62x54mmR."
	icon_state = "dt"
	caliber = 7.62
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/dp, /obj/item/civ13_shell/magazine/dp/dt)

/obj/structure/vehicleparts/weapon/cannon/russian76
	name = "76mm M1940 F-34"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 76.2 mm Russian tank-based cannon."
	caliber = 76.2
	maxrange = 27
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/mg/dp28/dt28/dtm28
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "DTM-28"
	desc = "The DTM-28 light machinegun. Designed to be places in vehicles. This one is in 7.62x54mmR."
	icon_state = "dtm"
	caliber = 7.62
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/dp, /obj/item/civ13_shell/magazine/dp/dt)

/obj/structure/vehicleparts/weapon/cannon/russian85
	name = "85mm S-53"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 85mm Russian tank-based cannon."
	caliber = 85
	maxrange = 33
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/cannon/russian100
	name = "100mm D10S"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 100mm Russian tank-based cannon."
	caliber = 100
	maxrange = 33
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/cannon/autoloader/t90a
	name = "2A46 125mm"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 125mm Russian tank-based cannon."
	caliber = 125
	maxrange = 35
	minrange = 5
	firedelay = 1
	autoloader = TRUE

/obj/structure/vehicleparts/weapon/mg/pkm
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "PKM machine gun"
	desc = "A soviet machinegun chambered in 7.62x54mmR rounds."
	icon_state = "pkmp"
	caliber = 7.62
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/pkm/c100, /obj/item/civ13_shell/magazine/maxim, /obj/item/civ13_shell/magazine/pkm)

/obj/structure/vehicleparts/weapon/cannon/m1a1_abrams
	name = "M256 120mm"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "The M256 is an American 120 mm smoothbore tank gun. It uses a German-designed Rh-120 L44 gun tube and combustible cartridges with an American-designed mount, cradle and recoil mechanism."
	caliber = 120
	maxrange = 35
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/mg/manual/m249
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "M249 SAW"
	desc = "An American variant of the Belgian FN Minimi machinegun chambered in 5.56x45mm NATO rounds. Sucessor of the M60."
	icon_state = "m249"
	caliber = 5.56
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/m249)

/obj/structure/vehicleparts/weapon/cannon/leopard
	name = "Rheinmetall 120 mm L/55"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 120 mm German tank-based cannon."
	caliber = 120
	maxrange = 35
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/mg/stationary/mg3
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "MG 3 machine gun"
	desc = "A german heavy machinegun. Chambered in 7.62x51mm rounds."
	icon_state = "mg3"
	caliber = 7.92
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/mg3belt)

/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/shipunov2a42
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "Shipunov 2A42 30mm autocannon"
	desc = "The 30mm 2A42 autocannon was developed as a replacement for the 2A28 Grom. It fires 30mm rounds."
	icon_state = "autocannon"
	caliber = 30
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/a30mm_ap, /obj/item/civ13_shell/magazine/a30mm_he)

/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/shipunov2a72
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "Shipunov 2A72 30mm autocannon"
	desc = "A lighter simplified variant of the 2A42 with a lower number of parts, a longer barrel, and higher muzzle velocity, but also a lower rate of fire. It fires 30mm rounds."
	icon_state = "autocannon"
	caliber = 30
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/a30mm_ap/btr80, /obj/item/civ13_shell/magazine/a30mm_he/btr80)

/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/bushmaster
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "Bushmaster III 35mm autocannon"
	desc = "The Bushmaster III is a chain gun, like the other members of the Bushmaster family, which grants it great dependability and safety from ammunition cook-off even though it does result in lower rates of fire."
	icon_state = "autocannon"
	caliber = 35
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/a35mm_fap, /obj/item/civ13_shell/magazine/a35mm_hei)

/obj/structure/vehicleparts/weapon/mg/stationary/autocannon/bushmaster/bradley
	icon = 'icons/obj/civ13/mgs.dmi'
	name = "M242 'Bushmaster' 25mm autocannon"
	desc = "An electrically driven, chain-fed gun used for engaging various targets."
	icon_state = "autocannon"
	caliber = 25
	machinegun = TRUE
	firedelay = 0.2
	accepted_ammo = list(/obj/item/civ13_shell/magazine/a25mm_ap/bradley, /obj/item/civ13_shell/magazine/a25mm_he/bradley)

/obj/structure/vehicleparts/weapon/cannon/bmv75
	name = "BMV-TC 75mm"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 75mm Redmenian tank-based cannon."
	caliber = 75
	maxrange = 30
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/structure/vehicleparts/weapon/cannon/smf75
	name = "SMF TKN 75mm"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	desc = "A 75mm Blugoslavian tank-based cannon."
	caliber = 75
	maxrange = 30
	minrange = 5
	firedelay = 1
	autoloader = FALSE

/obj/item/civ13_shell/magazine/dp
	name = "DP pan (7.62x54mmR)"
	desc = "A magazine for some kind of gun."
	icon_state = "dp_disk"
	icon = 'icons/obj/civ13/ammo.dmi'
	caliber = 7.62
	rounds = 47
	damage = 35
	heavy_armor_penetration = 15
	atype = "AP"
