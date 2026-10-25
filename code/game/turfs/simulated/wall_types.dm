/turf/simulated/wall/r_wall
	icon_state = "rgeneric"

/turf/simulated/wall/r_wall/New(var/newloc)
	..(newloc, "plasteel","plasteel") //3strong

/turf/simulated/wall/ocp_wall
	name = "thermoprotected wall"

/turf/simulated/wall/ocp_wall/New(var/newloc)
	..(newloc, "osmium-carbide plasteel", "osmium-carbide plasteel")


/turf/simulated/wall/cult
	icon_state = "cult"

/turf/simulated/wall/cult/New(var/newloc, var/reinforce = 0)
	..(newloc,"cult",reinforce ? "cult2" : null)

/turf/simulated/wall/cult/reinf/New(var/newloc)
	..(newloc, 1)

/turf/simulated/wall/cult/dismantle_wall()
	if(cult_owner)
		cult_owner.remove_cultiness(CULTINESS_PER_TURF)
		cult_owner = null
	..()

/turf/unsimulated/wall/cult
	name = "cult wall"
	desc = "Hideous images dance beneath the surface."
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "cult"

/turf/simulated/wall/iron/New(var/newloc)
	..(newloc,"iron")
/turf/simulated/wall/uranium/New(var/newloc)
	..(newloc,"uranium")
/turf/simulated/wall/diamond/New(var/newloc)
	..(newloc,"diamond")
/turf/simulated/wall/gold/New(var/newloc)
	..(newloc,"gold")
/turf/simulated/wall/silver/New(var/newloc)
	..(newloc,"silver")
/turf/simulated/wall/phoron/New(var/newloc)
	..(newloc,"phoron")
/turf/simulated/wall/sandstone/New(var/newloc)
	..(newloc,"sandstone")
/turf/simulated/wall/wood/New(var/newloc)
	..(newloc,"wood")
/turf/simulated/wall/ironphoron/New(var/newloc)
	..(newloc,"iron","phoron")
/turf/simulated/wall/golddiamond/New(var/newloc)
	..(newloc,"gold","diamond")
/turf/simulated/wall/silvergold/New(var/newloc)
	..(newloc,"silver","gold")
/turf/simulated/wall/sandstonediamond/New(var/newloc)
	..(newloc,"sandstone","diamond")

// Kind of wondering if this is going to bite me in the butt.
/turf/simulated/wall/voxshuttle/New(var/newloc)
	..(newloc,"voxalloy")
/turf/simulated/wall/voxshuttle/attackby()
	return
/turf/simulated/wall/titanium/New(var/newloc)
	..(newloc,"titanium")

/turf/simulated/wall/alium
	icon_state = "jaggy"
	floor_type = /turf/simulated/floor/fixed/alium

/turf/simulated/wall/alium/New(var/newloc)
	..(newloc,"alium")

/turf/simulated/wall/alium/ex_act(severity)
	if(prob(explosion_resistance))
		return
	..()

/turf/simulated/wall/rusty
	name = "rusty wall"
	icon_state = "rusty"

/turf/simulated/wall/rusty/New(var/newloc)
	..(newloc,"rusty steel")

/turf/simulated/wall/os13
	name = "OS13 wall"
	icon = 'icons/os13/turf/turf/walls.dmi'
	icon_state = "wall0"

/turf/simulated/wall/os13/update_icon()
	. = ..()
	icon = initial(icon)
	icon_state = initial(icon_state)
	color = initial(color)
	overlays.Cut()
	if(damage && material)
		var/integrity = material.integrity
		if(reinf_material)
			integrity += reinf_material.integrity
		var/damage_index = min(round(damage / integrity * damage_overlays.len) + 1, damage_overlays.len)
		overlays += damage_overlays[damage_index]

/turf/simulated/wall/os13/caves_new
	icon = 'icons/os13/turf/turf/caves_new.dmi'
	icon_state = "wall2"

/turf/simulated/wall/os13/caves_new/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/caves_new/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/caves_new/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/caves_new/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/caves_new/state_w
	icon_state = "W"

/turf/simulated/wall/os13/caves_new/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_new/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/caves_new/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/caves_new/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/caves_new/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/caves_new/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/caves_new/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/caves_new/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/caves_new/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/caves_new/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/caves_new/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/caves_new/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_new/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/caves_new/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/caves_new/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/caves_new/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/caves_new/state_w0
	icon_state = "W0"

/turf/simulated/wall/os13/caves_new/state_wn
	icon_state = "WN"

/turf/simulated/wall/os13/caves_new/state_a
	icon_state = "A"

/turf/simulated/wall/os13/caves_new0
	icon = 'icons/os13/turf/turf/caves_new0.dmi'
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_new0/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_new0/state_wall_side1
	icon_state = "wall_side1"

/turf/simulated/wall/os13/caves_new0/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/caves_new0/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/caves_new0/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_new0/state_xwall
	icon_state = "xwall"

/turf/simulated/wall/os13/caves_new0/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/caves_new0/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/caves_new0/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/caves_new0/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/caves_new0/state_wall_side1_0_0
	icon_state = "wall_side1 0,0"

/turf/simulated/wall/os13/caves_new0/state_w
	icon_state = "W"

/turf/simulated/wall/os13/caves_new0/state_wall_side1_1_0
	icon_state = "wall_side1 1,0"

/turf/simulated/wall/os13/caves_new0/state_wall_side1_2_0
	icon_state = "wall_side1 2,0"

/turf/simulated/wall/os13/caves_new0/state_wall_side1_3_0
	icon_state = "wall_side1 3,0"

/turf/simulated/wall/os13/caves_new0/state_vertical_0_0
	icon_state = "vertical 0,0"

/turf/simulated/wall/os13/caves_new0/state_vertical_0_1
	icon_state = "vertical 0,1"

/turf/simulated/wall/os13/caves_new0/state_vertical_0_2
	icon_state = "vertical 0,2"

/turf/simulated/wall/os13/caves_new0/state_vertical_0_3
	icon_state = "vertical 0,3"

/turf/simulated/wall/os13/caves_new0b
	icon = 'icons/os13/turf/turf/caves_new0b.dmi'
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_new0b/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_new0b/state_wall_side1
	icon_state = "wall_side1"

/turf/simulated/wall/os13/caves_new0b/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/caves_new0b/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/caves_new0b/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_new0b/state_xwall
	icon_state = "xwall"

/turf/simulated/wall/os13/caves_new0b/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/caves_new0b/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/caves_new0b/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/caves_new0b/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/caves_new0b/state_wall_side1_0_0
	icon_state = "wall_side1 0,0"

/turf/simulated/wall/os13/caves_new0b/state_w
	icon_state = "W"

/turf/simulated/wall/os13/caves_new0b/state_wall_side1_1_0
	icon_state = "wall_side1 1,0"

/turf/simulated/wall/os13/caves_new0b/state_wall_side1_2_0
	icon_state = "wall_side1 2,0"

/turf/simulated/wall/os13/caves_new0b/state_wall_side1_3_0
	icon_state = "wall_side1 3,0"

/turf/simulated/wall/os13/caves_new0b/state_vertical_0_0
	icon_state = "vertical 0,0"

/turf/simulated/wall/os13/caves_new0b/state_vertical_0_1
	icon_state = "vertical 0,1"

/turf/simulated/wall/os13/caves_new0b/state_vertical_0_2
	icon_state = "vertical 0,2"

/turf/simulated/wall/os13/caves_new0b/state_vertical_0_3
	icon_state = "vertical 0,3"

/turf/simulated/wall/os13/caves_new4
	icon = 'icons/os13/turf/turf/caves_new4.dmi'
	icon_state = "wall_side1"

/turf/simulated/wall/os13/caves_new4/state_wall_side1
	icon_state = "wall_side1"

/turf/simulated/wall/os13/caves_new4/state_wall_side2
	icon_state = "wall_side2"

/turf/simulated/wall/os13/caves_new4/state_wall_side3
	icon_state = "wall_side3"

/turf/simulated/wall/os13/caves_new4/state_wall_side4
	icon_state = "wall_side4"

/turf/simulated/wall/os13/caves_new4/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/caves_new4/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/caves_new4/state_w
	icon_state = "W"

/turf/simulated/wall/os13/caves_new4/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_new4/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_new4/state_w0
	icon_state = "W0"

/turf/simulated/wall/os13/caves_new4/state_wn
	icon_state = "WN"

/turf/simulated/wall/os13/caves_new4/state_a
	icon_state = "A"

/turf/simulated/wall/os13/caves_new5
	icon = 'icons/os13/turf/turf/caves_new5.dmi'
	icon_state = "W0"

/turf/simulated/wall/os13/caves_new5/state_w0
	icon_state = "W0"

/turf/simulated/wall/os13/caves_new5/state_wn
	icon_state = "WN"

/turf/simulated/wall/os13/caves_new5/state_a
	icon_state = "A"

/turf/simulated/wall/os13/caves_new5/state_w
	icon_state = "W"

/turf/simulated/wall/os13/caves_new5/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_new5/state_wall_side1
	icon_state = "wall_side1"

/turf/simulated/wall/os13/caves_new5/state_wall_side2
	icon_state = "wall_side2"

/turf/simulated/wall/os13/caves_new5/state_wall_side3
	icon_state = "wall_side3"

/turf/simulated/wall/os13/caves_new5/state_wall_side4
	icon_state = "wall_side4"

/turf/simulated/wall/os13/caves_new5/state_wall_side5
	icon_state = "wall_side5"

/turf/simulated/wall/os13/caves_new5/state_wall_side6
	icon_state = "wall_side6"

/turf/simulated/wall/os13/caves_new5/state_wall_side7
	icon_state = "wall_side7"

/turf/simulated/wall/os13/caves_new5/state_wall_side8
	icon_state = "wall_side8"

/turf/simulated/wall/os13/caves_new5/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/caves_new5/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/caves_new5/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_new5/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/caves_new5/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/caves_new5/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/caves_new5/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/caves_new5/state_empty
	icon_state = ""

/turf/simulated/wall/os13/caves_smooth
	icon = 'icons/os13/turf/turf/caves_smooth.dmi'
	icon_state = "stonewall"

/turf/simulated/wall/os13/caves_smooth/state_stonewall
	icon_state = "stonewall"

/turf/simulated/wall/os13/caves_smooth/state_stonewall_end
	icon_state = "stonewall_end"

/turf/simulated/wall/os13/caves_smooth/state_stonewall_straight
	icon_state = "stonewall_straight"

/turf/simulated/wall/os13/caves_smooth/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_smooth/state_xwall
	icon_state = "xwall"

/turf/simulated/wall/os13/caves_smyak
	icon = 'icons/os13/turf/turf/caves_smyak.dmi'
	icon_state = "wall_side1"

/turf/simulated/wall/os13/caves_smyak/state_wall_side1
	icon_state = "wall_side1"

/turf/simulated/wall/os13/caves_smyak/state_wall_side2
	icon_state = "wall_side2"

/turf/simulated/wall/os13/caves_smyak/state_wall_side3
	icon_state = "wall_side3"

/turf/simulated/wall/os13/caves_smyak/state_wall_side4
	icon_state = "wall_side4"

/turf/simulated/wall/os13/caves_smyak/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/caves_smyak/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/caves_smyak/state_w
	icon_state = "W"

/turf/simulated/wall/os13/caves_smyak/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_smyak/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_smyak/state_w0
	icon_state = "W0"

/turf/simulated/wall/os13/caves_smyak/state_wn
	icon_state = "WN"

/turf/simulated/wall/os13/caves_smyak/state_a
	icon_state = "A"

/turf/simulated/wall/os13/caves_snow
	icon = 'icons/os13/turf/turf/caves_snow.dmi'
	icon_state = "W0"

/turf/simulated/wall/os13/caves_snow/state_w0
	icon_state = "W0"

/turf/simulated/wall/os13/caves_snow/state_wn
	icon_state = "WN"

/turf/simulated/wall/os13/caves_snow/state_a
	icon_state = "A"

/turf/simulated/wall/os13/caves_snow/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/caves_snow/state_w
	icon_state = "W"

/turf/simulated/wall/os13/caves_snow/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/caves_snow/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/caves_snow/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/caves_snow/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/caves_snow/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/caves_snow/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/caves_snow/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/caves_snow/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/caves_snow/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/caves_snow/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/caves_snow/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/caves_snow/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/caves_snow/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/caves_snow/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/caves_snow/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/caves_snow/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/caves_snow/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/caves_snow/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/caves_snow/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/flesh
	icon = 'icons/os13/turf/turf/flesh.dmi'
	icon_state = "flesh_"

/turf/simulated/wall/os13/flesh/state_flesh
	icon_state = "flesh_"

/turf/simulated/wall/os13/flesh/state_flesh_nswe
	icon_state = "flesh_NSWE"

/turf/simulated/wall/os13/flesh/state_flesh_e
	icon_state = "flesh_E"

/turf/simulated/wall/os13/flesh/state_flesh_we
	icon_state = "flesh_WE"

/turf/simulated/wall/os13/flesh/state_flesh_nws
	icon_state = "flesh_NWS"

/turf/simulated/wall/os13/flesh/state_flesh_n
	icon_state = "flesh_N"

/turf/simulated/wall/os13/flesh/state_flesh_ns
	icon_state = "flesh_NS"

/turf/simulated/wall/os13/flesh/state_flesh_nwe
	icon_state = "flesh_NWE"

/turf/simulated/wall/os13/flesh/state_flesh_ne
	icon_state = "flesh_NE"

/turf/simulated/wall/os13/flesh/state_flesh_nw
	icon_state = "flesh_NW"

/turf/simulated/wall/os13/flesh/state_flesh_s
	icon_state = "flesh_S"

/turf/simulated/wall/os13/flesh/state_flesh_swe
	icon_state = "flesh_SWE"

/turf/simulated/wall/os13/flesh/state_flesh_sw
	icon_state = "flesh_SW"

/turf/simulated/wall/os13/flesh/state_flesh_se
	icon_state = "flesh_SE"

/turf/simulated/wall/os13/flesh/state_flesh_w
	icon_state = "flesh_W"

/turf/simulated/wall/os13/flesh/state_flesh_nse
	icon_state = "flesh_NSE"

/turf/simulated/wall/os13/flesh/state_flesh_nsw
	icon_state = "flesh_NSW"

/turf/simulated/wall/os13/gwalls
	icon = 'icons/os13/turf/turf/gwalls.dmi'
	icon_state = "r_wall"

/turf/simulated/wall/os13/gwalls/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/gwalls/state_frwall_open
	icon_state = "frwall_open"

/turf/simulated/wall/os13/gwalls/state_frwall_opening
	icon_state = "frwall_opening"

/turf/simulated/wall/os13/gwalls/state_frwall_closing
	icon_state = "frwall_closing"

/turf/simulated/wall/os13/gwalls/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/gwalls/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/gwalls/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/gwalls/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/gwalls/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/gwalls/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/gwalls/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/gwalls/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/gwalls/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/gwalls/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/gwalls/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/gwalls/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/gwalls/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/gwalls/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/gwalls/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/gwalls/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/hell
	icon = 'icons/os13/turf/turf/hell.dmi'
	icon_state = "wall"

/turf/simulated/wall/os13/hell/state_wall
	icon_state = "wall"

/turf/simulated/wall/os13/hell/state_w
	icon_state = "W"

/turf/simulated/wall/os13/hell/state_straight
	icon_state = "straight"

/turf/simulated/wall/os13/hell/state_end
	icon_state = "end"

/turf/simulated/wall/os13/hell/state_xwall
	icon_state = "xwall"

/turf/simulated/wall/os13/lev
	icon = 'icons/os13/turf/turf/lev.dmi'
	icon_state = "r_wall"

/turf/simulated/wall/os13/lev/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/lev/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/lev/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/lev/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/lev/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/lev/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/lev/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/lev/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/lev/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/lev/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/lev/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/lev/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/lev/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/lev/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/lev/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/lev/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/lev/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/lev/state_dec0
	icon_state = "dec0"

/turf/simulated/wall/os13/lev/state_dec1
	icon_state = "dec1"

/turf/simulated/wall/os13/lev/state_pdec
	icon_state = "pdec"

/turf/simulated/wall/os13/lev/state_pdec2
	icon_state = "pdec2"

/turf/simulated/wall/os13/lev/state_pdec3
	icon_state = "pdec3"

/turf/simulated/wall/os13/lev/state_loud
	icon_state = "loud"

/turf/simulated/wall/os13/lev/state_loud2
	icon_state = "loud2"

/turf/simulated/wall/os13/lev_mask
	icon = 'icons/os13/turf/turf/lev_mask.dmi'
	icon_state = "r_wall"

/turf/simulated/wall/os13/lev_mask/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/lev_mask/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/lev_mask/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/lev_mask/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/lev_mask/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/lev_mask/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/lev_mask/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/lev_mask/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/lev_mask/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/lev_mask/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/lev_mask/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/lev_mask/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/lev_mask/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/lev_mask/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/lev_mask/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/lev_mask/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/lev_mask/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/meat
	icon = 'icons/os13/turf/turf/meat.dmi'
	icon_state = "wall_side1"

/turf/simulated/wall/os13/meat/state_wall_side1
	icon_state = "wall_side1"

/turf/simulated/wall/os13/meat/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/meat/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/meat/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/meat/state_w0
	icon_state = "W0"

/turf/simulated/wall/os13/meat/state_wn
	icon_state = "WN"

/turf/simulated/wall/os13/meat/state_a
	icon_state = "A"

/turf/simulated/wall/os13/meat/state_w
	icon_state = "W"

/turf/simulated/wall/os13/meat/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/meat/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/meat/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/meat/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/meat/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/prisonwalls
	icon = 'icons/os13/turf/turf/prisonwalls.dmi'
	icon_state = "r_wall"

/turf/simulated/wall/os13/prisonwalls/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/prisonwalls/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/prisonwalls/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/prisonwalls/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/prisonwalls/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/prisonwalls/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/prisonwalls/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/prisonwalls/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/prisonwalls/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/prisonwalls/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/prisonwalls/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/prisonwalls/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/prisonwalls/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/prisonwalls/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/prisonwalls/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/prisonwalls/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/prisonwalls/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/prisonwalls2
	icon = 'icons/os13/turf/turf/prisonwalls2.dmi'
	icon_state = "r_wall"

/turf/simulated/wall/os13/prisonwalls2/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/prisonwalls2/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/prisonwalls2/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/prisonwalls2/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/prisonwalls2/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/prisonwalls2/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/prisonwalls2/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/prisonwalls2/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/prisonwalls2/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/prisonwalls2/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/prisonwalls2/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/prisonwalls2/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/prisonwalls2/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/prisonwalls2/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/prisonwalls2/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/prisonwalls2/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/prisonwalls2/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/shuttle
	icon = 'icons/os13/turf/turf/shuttle.dmi'
	icon_state = "wall3"

/turf/simulated/wall/os13/shuttle/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/shuttle/state_diagonalwall3
	icon_state = "diagonalWall3"

/turf/simulated/wall/os13/shuttle/state_wall3_space
	icon_state = "wall3_space"

/turf/simulated/wall/os13/soulwall1
	icon = 'icons/os13/turf/turf/soulwall1.dmi'
	icon_state = "window1"

/turf/simulated/wall/os13/soulwall1/state_window1
	icon_state = "window1"

/turf/simulated/wall/os13/soulwall1/state_window2
	icon_state = "window2"

/turf/simulated/wall/os13/soulwall1/state_window3
	icon_state = "window3"

/turf/simulated/wall/os13/soulwall1/state_window4
	icon_state = "window4"

/turf/simulated/wall/os13/soulwall1/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/soulwall1/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/soulwall1/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/soulwall1/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/soulwall1/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/soulwall1/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/soulwall1/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/soulwall1/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/soulwall1/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/soulwall1/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/soulwall1/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/soulwall1/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/soulwall1/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/soulwall1/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/soulwall1/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/soulwall1/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/soulwall2
	icon = 'icons/os13/turf/turf/soulwall2.dmi'
	icon_state = ""

/turf/simulated/wall/os13/soulwall2/state_empty
	icon_state = ""

/turf/simulated/wall/os13/soulwall2/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/soulwall2/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/soulwall2/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/soulwall2/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/soulwall2/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/soulwall2/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/soulwall2/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/soulwall2/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/soulwall2/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/soulwall2/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/soulwall2/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/soulwall2/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/soulwall2/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/soulwall2/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/soulwall2/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/soulwall2/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/soulwall2/state_corner
	icon_state = "corner"

/turf/simulated/wall/os13/soulwall2/state_cornermask
	icon_state = "cornermask"

/turf/simulated/wall/os13/stonecave
	icon = 'icons/os13/turf/turf/stonecave.dmi'
	icon_state = "wall"

/turf/simulated/wall/os13/stonecave/state_wall
	icon_state = "wall"

/turf/simulated/wall/os13/stonecave/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/stonecave/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/stonecave/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/stonecave/state_w
	icon_state = "W"

/turf/simulated/wall/os13/stonecave/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/stonecave/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/stonecave/state_bwall
	icon_state = "Bwall"

/turf/simulated/wall/os13/stonecave/state_bwall_straight
	icon_state = "Bwall_straight"

/turf/simulated/wall/os13/stonecave/state_bwall_end
	icon_state = "Bwall_end"

/turf/simulated/wall/os13/stonecave/state_bwall15
	icon_state = "Bwall15"

/turf/simulated/wall/os13/stonecave/state_bwall0
	icon_state = "Bwall0"

/turf/simulated/wall/os13/stonewall
	icon = 'icons/os13/turf/turf/stonewall.dmi'
	icon_state = "xwall10"

/turf/simulated/wall/os13/stonewall/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/stonewall/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/stonewall/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/stonewall/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/stonewall/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/stonewall/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/stonewall/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/stonewall/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/stonewall/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/stonewall/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/stonewall/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/stonewall/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/stonewall/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/stonewall/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/stonewall/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/stonewall/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/stonewall/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/stonewall/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/stonewall/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/stonewall/state_fort1
	icon_state = "fort1"

/turf/simulated/wall/os13/stonewall/state_fort2
	icon_state = "fort2"

/turf/simulated/wall/os13/stonewall/state_empty
	icon_state = ""

/turf/simulated/wall/os13/stonewall/state_fwall
	icon_state = "fwall"

/turf/simulated/wall/os13/stonewall/state_fwall2
	icon_state = "fwall2"

/turf/simulated/wall/os13/stonewall/state_fort3
	icon_state = "fort3"

/turf/simulated/wall/os13/stonewall/state_fortclosed
	icon_state = "fortclosed"

/turf/simulated/wall/os13/stonewall/state_21
	icon_state = "21"

/turf/simulated/wall/os13/stonewall/state_sfff
	icon_state = "sfff"

/turf/simulated/wall/os13/stonewall2
	icon = 'icons/os13/turf/turf/stonewall2.dmi'
	icon_state = "stonewall"

/turf/simulated/wall/os13/stonewall2/state_stonewall
	icon_state = "stonewall"

/turf/simulated/wall/os13/stonewall2/state_xwall
	icon_state = "xwall"

/turf/simulated/wall/os13/stonewall2/state_stonewall_end
	icon_state = "stonewall_end"

/turf/simulated/wall/os13/stonewall2/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/stonewall2/state_stonewall_straight
	icon_state = "stonewall_straight"

/turf/simulated/wall/os13/stonewall2/state_sfff
	icon_state = "sfff"

/turf/simulated/wall/os13/stonewall2/state_empty
	icon_state = ""

/turf/simulated/wall/os13/stonewall2/state_fwall
	icon_state = "fwall"

/turf/simulated/wall/os13/stonewall2/state_fort1
	icon_state = "fort1"

/turf/simulated/wall/os13/stonewall2/state_fort2
	icon_state = "fort2"

/turf/simulated/wall/os13/stonewall2/state_fort3
	icon_state = "fort3"

/turf/simulated/wall/os13/stonewall2/state_fortclosed
	icon_state = "fortclosed"

/turf/simulated/wall/os13/stonewall3
	icon = 'icons/os13/turf/turf/stonewall3.dmi'
	icon_state = "stonewall"

/turf/simulated/wall/os13/stonewall3/state_stonewall
	icon_state = "stonewall"

/turf/simulated/wall/os13/stonewall3/state_stonewall_straight
	icon_state = "stonewall_straight"

/turf/simulated/wall/os13/stonewall3/state_stonewall_end
	icon_state = "stonewall_end"

/turf/simulated/wall/os13/stonewall3/state_xwall
	icon_state = "xwall"

/turf/simulated/wall/os13/stonewall3/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/stonewall3/state_empty
	icon_state = ""

/turf/simulated/wall/os13/stonewall3/state_b
	icon_state = "B"

/turf/simulated/wall/os13/stonewall3/state_fwall
	icon_state = "fwall"

/turf/simulated/wall/os13/stonewall3/state_fwall2
	icon_state = "fwall2"

/turf/simulated/wall/os13/stonewall3/state_fort1
	icon_state = "fort1"

/turf/simulated/wall/os13/stonewall3/state_fort2
	icon_state = "fort2"

/turf/simulated/wall/os13/stonewall3/state_fort3
	icon_state = "fort3"

/turf/simulated/wall/os13/stonewall3/state_fortclosed
	icon_state = "fortclosed"

/turf/simulated/wall/os13/stonewall3/state_corners
	icon_state = "corners"

/turf/simulated/wall/os13/stonewall3_mask
	icon = 'icons/os13/turf/turf/stonewall3_mask.dmi'
	icon_state = "stonewall"

/turf/simulated/wall/os13/stonewall3_mask/state_stonewall
	icon_state = "stonewall"

/turf/simulated/wall/os13/stonewall3_mask/state_stonewall_straight
	icon_state = "stonewall_straight"

/turf/simulated/wall/os13/stonewall3_mask/state_stonewall_end
	icon_state = "stonewall_end"

/turf/simulated/wall/os13/stonewall3_mask/state_corners
	icon_state = "corners"

/turf/simulated/wall/os13/stonewall3_mask/state_fort1
	icon_state = "fort1"

/turf/simulated/wall/os13/subwalls
	icon = 'icons/os13/turf/turf/subwalls.dmi'
	icon_state = "wall0"

/turf/simulated/wall/os13/subwalls/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/subwalls/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/subwalls/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/subwalls/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/subwalls/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/subwalls/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/subwalls/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/subwalls/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/subwalls/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/subwalls/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/subwalls/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/subwalls/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/subwalls/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/subwalls/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/subwalls/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/subwalls/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/wr
	icon = 'icons/os13/turf/turf/wR.dmi'
	icon_state = ""

/turf/simulated/wall/os13/wr/state_empty
	icon_state = ""

/turf/simulated/wall/os13/wr/state_w
	icon_state = "w"

/turf/simulated/wall/os13/wr/state_k
	icon_state = "k"

/turf/simulated/wall/os13/wr/state_k2
	icon_state = "k2"

/turf/simulated/wall/os13/wr/state_k3
	icon_state = "k3"

/turf/simulated/wall/os13/wr/state_k5
	icon_state = "k5"

/turf/simulated/wall/os13/wall
	icon = 'icons/os13/turf/turf/wall.dmi'
	icon_state = "W"

/turf/simulated/wall/os13/wall/state_w
	icon_state = "W"

/turf/simulated/wall/os13/wall/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/wall/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/wall/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/wall/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/wall/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/wall/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/wall/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/wall/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/wall/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/wall/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/wall/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/wall/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/wall/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/wall/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/wall/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/wall/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/wall/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/wall/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/wall/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/wall/state_w2
	icon_state = "W2"

/turf/simulated/wall/os13/wall/state_wallo
	icon_state = "wallo"

/turf/simulated/wall/os13/wall/state_wallo2
	icon_state = "wallo2"

/turf/simulated/wall/os13/wallb
	icon = 'icons/os13/turf/turf/wallb.dmi'
	icon_state = "W"

/turf/simulated/wall/os13/wallb/state_w
	icon_state = "W"

/turf/simulated/wall/os13/wallb/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/wallb/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/wallb/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/wallb/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/wallb/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/wallb/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/wallb/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/wallb/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/wallb/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/wallb/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/wallb/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/wallb/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/wallb/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/wallb/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/wallb/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/wallb/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/wallb/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/wallb/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/wallb/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/walls
	icon = 'icons/os13/turf/turf/walls.dmi'
	icon_state = "hull0"

/turf/simulated/wall/os13/walls/state_hull0
	icon_state = "hull0"

/turf/simulated/wall/os13/walls/state_rock_side
	icon_state = "rock_side"

/turf/simulated/wall/os13/walls/state_rock_side2
	icon_state = "rock_side2"

/turf/simulated/wall/os13/walls/state_soft
	icon_state = "soft"

/turf/simulated/wall/os13/walls/state_obs
	icon_state = "obs"

/turf/simulated/wall/os13/walls/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/walls/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/walls/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/walls/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/walls/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/walls/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/walls/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/walls/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/walls/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/walls/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/walls/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/walls/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/walls/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/walls/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/walls/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/walls/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/walls/state_cyberspace
	icon_state = "cyberspace"

/turf/simulated/wall/os13/walls/state_riveted
	icon_state = "riveted"

/turf/simulated/wall/os13/walls/state_rock
	icon_state = "rock"

/turf/simulated/wall/os13/walls/state_r1
	icon_state = "r1"

/turf/simulated/wall/os13/walls/state_r2
	icon_state = "r2"

/turf/simulated/wall/os13/walls/state_r3
	icon_state = "r3"

/turf/simulated/wall/os13/walls/state_fwall_open
	icon_state = "fwall_open"

/turf/simulated/wall/os13/walls/state_fwall_opening
	icon_state = "fwall_opening"

/turf/simulated/wall/os13/walls/state_fwall_closing
	icon_state = "fwall_closing"

/turf/simulated/wall/os13/walls/state_caves
	icon_state = "caves"

/turf/simulated/wall/os13/walls/state_2_0
	icon_state = "2,0"

/turf/simulated/wall/os13/walls/state_3
	icon_state = "3"

/turf/simulated/wall/os13/walls/state_caves_anim
	icon_state = "caves_anim"

/turf/simulated/wall/os13/walls/state_black
	icon_state = "black"

/turf/simulated/wall/os13/walls/state_rock_corner_nw
	icon_state = "rock_corner_nw"

/turf/simulated/wall/os13/walls/state_rock_corner_ne
	icon_state = "rock_corner_ne"

/turf/simulated/wall/os13/walls/state_rock_corner_sw
	icon_state = "rock_corner_sw"

/turf/simulated/wall/os13/walls/state_rock_corner_se
	icon_state = "rock_corner_se"

/turf/simulated/wall/os13/walls/state_vau2
	icon_state = "vau2"

/turf/simulated/wall/os13/walls/state_vau4
	icon_state = "vau4"

/turf/simulated/wall/os13/walls/state_vau3
	icon_state = "vau3"

/turf/simulated/wall/os13/walls/state_tgr
	icon_state = "tgr"

/turf/simulated/wall/os13/walls/state_tgr2
	icon_state = "tgr2"

/turf/simulated/wall/os13/walls/state_tgr3
	icon_state = "tgr3"

/turf/simulated/wall/os13/walls/state_tgr4
	icon_state = "tgr4"

/turf/simulated/wall/os13/walls/state_tgr5
	icon_state = "tgr5"

/turf/simulated/wall/os13/walls/state_dark_side
	icon_state = "dark_side"

/turf/simulated/wall/os13/walls/state_r_wall_3
	icon_state = "r_wall-3"

/turf/simulated/wall/os13/walls/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/walls/state_r_wall_1
	icon_state = "r_wall-1"

/turf/simulated/wall/os13/walls/state_r_wall_2
	icon_state = "r_wall-2"

/turf/simulated/wall/os13/walls/state_r_wall_4
	icon_state = "r_wall-4"

/turf/simulated/wall/os13/walls/state_r_wall_5
	icon_state = "r_wall-5"

/turf/simulated/wall/os13/walls/state_r_wall_6
	icon_state = "r_wall-6"

/turf/simulated/wall/os13/walls/state_frwall_open
	icon_state = "frwall_open"

/turf/simulated/wall/os13/walls/state_frwall_opening
	icon_state = "frwall_opening"

/turf/simulated/wall/os13/walls/state_frwall_closing
	icon_state = "frwall_closing"

/turf/simulated/wall/os13/walls/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/walls/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/walls/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/walls/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/walls/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/walls/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/walls/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/walls/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/walls/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/walls/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/walls/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/walls/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/walls/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/walls/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/walls/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/walls/state_frwallx
	icon_state = "frwallx"

/turf/simulated/wall/os13/walls/state_empty
	icon_state = ""

/turf/simulated/wall/os13/walls/state_2
	icon_state = "2"

/turf/simulated/wall/os13/walls/state_4
	icon_state = "4"

/turf/simulated/wall/os13/walls/state_5
	icon_state = "5"

/turf/simulated/wall/os13/walls/state_bg
	icon_state = "bg"

/turf/simulated/wall/os13/walls/state_rock_side3
	icon_state = "rock_side3"

/turf/simulated/wall/os13/walls/state_dark_over
	icon_state = "dark_over"

/turf/simulated/wall/os13/walls/state_ch2
	icon_state = "ch2"

/turf/simulated/wall/os13/walls/state_ch22
	icon_state = "ch22"

/turf/simulated/wall/os13/walls/state_ch223
	icon_state = "ch223"

/turf/simulated/wall/os13/walls/state_02
	icon_state = "02"

/turf/simulated/wall/os13/walls/state_04
	icon_state = "04"

/turf/simulated/wall/os13/walls/state_05
	icon_state = "05"

/turf/simulated/wall/os13/walls/state_scratch1
	icon_state = "scratch1"

/turf/simulated/wall/os13/walls/state_scratch2
	icon_state = "scratch2"

/turf/simulated/wall/os13/walls/state_scratch3
	icon_state = "scratch3"

/turf/simulated/wall/os13/walls/state_scratch4
	icon_state = "scratch4"

/turf/simulated/wall/os13/walls/state_wound1
	icon_state = "wound1"

/turf/simulated/wall/os13/walls/state_wound2
	icon_state = "wound2"

/turf/simulated/wall/os13/walls/state_wound3
	icon_state = "wound3"

/turf/simulated/wall/os13/walls/state_wound4
	icon_state = "wound4"

/turf/simulated/wall/os13/walls/state_damage1
	icon_state = "damage1"

/turf/simulated/wall/os13/walls/state_damage2
	icon_state = "damage2"

/turf/simulated/wall/os13/walls/state_damage3
	icon_state = "damage3"

/turf/simulated/wall/os13/walls/state_damage4
	icon_state = "damage4"

/turf/simulated/wall/os13/walls/state_damage5
	icon_state = "damage5"

/turf/simulated/wall/os13/walls/state_damage6
	icon_state = "damage6"

/turf/simulated/wall/os13/walls/state_paint
	icon_state = "paint"

/turf/simulated/wall/os13/walls/state_damage7
	icon_state = "damage7"

/turf/simulated/wall/os13/walls/state_dirt1
	icon_state = "dirt1"

/turf/simulated/wall/os13/walls/state_dirt2
	icon_state = "dirt2"

/turf/simulated/wall/os13/walls/state_dirt3
	icon_state = "dirt3"

/turf/simulated/wall/os13/walls/state_dirt4
	icon_state = "dirt4"

/turf/simulated/wall/os13/walls/state_detail3
	icon_state = "detail3"

/turf/simulated/wall/os13/walls/state_detail1
	icon_state = "detail1"

/turf/simulated/wall/os13/walls/state_detail2
	icon_state = "detail2"

/turf/simulated/wall/os13/walls/state_detail2o
	icon_state = "detail2o"

/turf/simulated/wall/os13/walls/state_detail2u
	icon_state = "detail2u"

/turf/simulated/wall/os13/walls/state_cdetail2
	icon_state = "cdetail2"

/turf/simulated/wall/os13/walls/state_cdetail2o
	icon_state = "cdetail2o"

/turf/simulated/wall/os13/walls/state_bdetail2
	icon_state = "bdetail2"

/turf/simulated/wall/os13/walls/state_bdetail2o
	icon_state = "bdetail2o"

/turf/simulated/wall/os13/walls/state_och2
	icon_state = "och2"

/turf/simulated/wall/os13/walls/state_och22
	icon_state = "och22"

/turf/simulated/wall/os13/walls/state_och223
	icon_state = "och223"

/turf/simulated/wall/os13/walls2
	icon = 'icons/os13/turf/turf/walls2.dmi'
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls2/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls2/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/walls2/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/walls2/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/walls2/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/walls2/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/walls2/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/walls2/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/walls2/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/walls2/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/walls2/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/walls2/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/walls2/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/walls2/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/walls2/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/walls2/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/walls2/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/walls2_mask
	icon = 'icons/os13/turf/turf/walls2_mask.dmi'
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls2_mask/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls2_mask/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/walls2_mask/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/walls2_mask/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/walls2_mask/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/walls2_mask/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/walls2_mask/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/walls2_mask/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/walls2_mask/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/walls2_mask/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/walls2_mask/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/walls2_mask/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/walls2_mask/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/walls2_mask/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/walls2_mask/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/walls2_mask/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/walls2_mask/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/walls3
	icon = 'icons/os13/turf/turf/walls3.dmi'
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls3/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls3/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/walls3/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/walls3/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/walls3/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/walls3/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/walls3/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/walls3/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/walls3/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/walls3/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/walls3/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/walls3/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/walls3/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/walls3/state_empty
	icon_state = ""

/turf/simulated/wall/os13/walls3/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/walls3/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/walls3/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/walls3/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/walls3b
	icon = 'icons/os13/turf/turf/walls3b.dmi'
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls3b/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls3b/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/walls3b/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/walls3b/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/walls3b/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/walls3b/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/walls3b/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/walls3b/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/walls3b/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/walls3b/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/walls3b/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/walls3b/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/walls3b/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/walls3b/state_empty
	icon_state = ""

/turf/simulated/wall/os13/walls3b/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/walls3b/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/walls3b/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/walls3b/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/walls_details
	icon = 'icons/os13/turf/turf/walls_details.dmi'
	icon_state = "wall0"

/turf/simulated/wall/os13/walls_details/state_wall0
	icon_state = "wall0"

/turf/simulated/wall/os13/walls_details/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/walls_details/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/walls_details/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/walls_details/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/walls_details/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/walls_details/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/walls_details/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/walls_details/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/walls_details/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/walls_details/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/walls_details/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/walls_details/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/walls_details/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/walls_details/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/walls_details/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/walls_details/state_r_wall_3
	icon_state = "r_wall-3"

/turf/simulated/wall/os13/walls_details/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/walls_details/state_r_wall_1
	icon_state = "r_wall-1"

/turf/simulated/wall/os13/walls_details/state_r_wall_2
	icon_state = "r_wall-2"

/turf/simulated/wall/os13/walls_details/state_r_wall_4
	icon_state = "r_wall-4"

/turf/simulated/wall/os13/walls_details/state_r_wall_5
	icon_state = "r_wall-5"

/turf/simulated/wall/os13/walls_details/state_r_wall_6
	icon_state = "r_wall-6"

/turf/simulated/wall/os13/walls_details/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/walls_details/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/walls_details/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/walls_details/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/walls_details/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/walls_details/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/walls_details/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/walls_details/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/walls_details/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/walls_details/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/walls_details/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/walls_details/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/walls_details/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/walls_details/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/walls_details/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/walls_details/state_rwall15
	icon_state = "rwall15"

/turf/simulated/wall/os13/walls_details/state_2
	icon_state = "2"

/turf/simulated/wall/os13/walls_details/state_4
	icon_state = "4"

/turf/simulated/wall/os13/walls_details/state_5
	icon_state = "5"

/turf/simulated/wall/os13/walls_details/state_bg
	icon_state = "bg"

/turf/simulated/wall/os13/walls_details/state_02
	icon_state = "02"

/turf/simulated/wall/os13/walls_details/state_04
	icon_state = "04"

/turf/simulated/wall/os13/walls_details/state_05
	icon_state = "05"

/turf/simulated/wall/os13/wallw
	icon = 'icons/os13/turf/turf/wallw.dmi'
	icon_state = "W"

/turf/simulated/wall/os13/wallw/state_w
	icon_state = "W"

/turf/simulated/wall/os13/wallw/state_wall2
	icon_state = "wall2"

/turf/simulated/wall/os13/wallw/state_wall1
	icon_state = "wall1"

/turf/simulated/wall/os13/wallw/state_wall4
	icon_state = "wall4"

/turf/simulated/wall/os13/wallw/state_wall8
	icon_state = "wall8"

/turf/simulated/wall/os13/wallw/state_xwall10
	icon_state = "xwall10"

/turf/simulated/wall/os13/wallw/state_xwall5
	icon_state = "xwall5"

/turf/simulated/wall/os13/wallw/state_xwall9
	icon_state = "xwall9"

/turf/simulated/wall/os13/wallw/state_xwall6
	icon_state = "xwall6"

/turf/simulated/wall/os13/wallw/state_wall12
	icon_state = "wall12"

/turf/simulated/wall/os13/wallw/state_wall10
	icon_state = "wall10"

/turf/simulated/wall/os13/wallw/state_wall6
	icon_state = "wall6"

/turf/simulated/wall/os13/wallw/state_wall5
	icon_state = "wall5"

/turf/simulated/wall/os13/wallw/state_wall9
	icon_state = "wall9"

/turf/simulated/wall/os13/wallw/state_wall3
	icon_state = "wall3"

/turf/simulated/wall/os13/wallw/state_wall7
	icon_state = "wall7"

/turf/simulated/wall/os13/wallw/state_wall11
	icon_state = "wall11"

/turf/simulated/wall/os13/wallw/state_wall13
	icon_state = "wall13"

/turf/simulated/wall/os13/wallw/state_wall14
	icon_state = "wall14"

/turf/simulated/wall/os13/wooden3
	icon = 'icons/os13/turf/turf/wooden3.dmi'
	icon_state = "wall"

/turf/simulated/wall/os13/wooden3/state_wall
	icon_state = "wall"

/turf/simulated/wall/os13/wooden3/state_wall_straight
	icon_state = "wall_straight"

/turf/simulated/wall/os13/wooden3/state_wall_end
	icon_state = "wall_end"

/turf/simulated/wall/os13/wooden3/state_xwall
	icon_state = "xwall"

/turf/simulated/wall/os13/wooden3/state_wall15
	icon_state = "wall15"

/turf/simulated/wall/os13/wooden3/state_w
	icon_state = "W"

/turf/simulated/wall/os13/wooden3/state_w2
	icon_state = "W2"

/turf/simulated/wall/os13/wooden3/state_w3
	icon_state = "W3"

/turf/simulated/wall/os13/wooden3/state_fort1
	icon_state = "fort1"

/turf/simulated/wall/os13/wooden3/state_fort2
	icon_state = "fort2"

/turf/simulated/wall/os13/wooden3/state_fortclosed
	icon_state = "fortclosed"

/turf/simulated/wall/os13/wooden3/state_fw
	icon_state = "FW"

/turf/simulated/wall/os13/wwalls
	icon = 'icons/os13/turf/turf/wwalls.dmi'
	icon_state = "r_wall"

/turf/simulated/wall/os13/wwalls/state_r_wall
	icon_state = "r_wall"

/turf/simulated/wall/os13/wwalls/state_frwall_open
	icon_state = "frwall_open"

/turf/simulated/wall/os13/wwalls/state_frwall_opening
	icon_state = "frwall_opening"

/turf/simulated/wall/os13/wwalls/state_frwall_closing
	icon_state = "frwall_closing"

/turf/simulated/wall/os13/wwalls/state_rwall0
	icon_state = "rwall0"

/turf/simulated/wall/os13/wwalls/state_rwall1
	icon_state = "rwall1"

/turf/simulated/wall/os13/wwalls/state_rwall2
	icon_state = "rwall2"

/turf/simulated/wall/os13/wwalls/state_rwall3
	icon_state = "rwall3"

/turf/simulated/wall/os13/wwalls/state_rwall4
	icon_state = "rwall4"

/turf/simulated/wall/os13/wwalls/state_rwall5
	icon_state = "rwall5"

/turf/simulated/wall/os13/wwalls/state_rwall6
	icon_state = "rwall6"

/turf/simulated/wall/os13/wwalls/state_rwall7
	icon_state = "rwall7"

/turf/simulated/wall/os13/wwalls/state_rwall8
	icon_state = "rwall8"

/turf/simulated/wall/os13/wwalls/state_rwall9
	icon_state = "rwall9"

/turf/simulated/wall/os13/wwalls/state_rwall10
	icon_state = "rwall10"

/turf/simulated/wall/os13/wwalls/state_rwall11
	icon_state = "rwall11"

/turf/simulated/wall/os13/wwalls/state_rwall12
	icon_state = "rwall12"

/turf/simulated/wall/os13/wwalls/state_rwall13
	icon_state = "rwall13"

/turf/simulated/wall/os13/wwalls/state_rwall14
	icon_state = "rwall14"

/turf/simulated/wall/os13/wwalls/state_rwall15
	icon_state = "rwall15"
