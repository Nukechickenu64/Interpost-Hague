// This type of flooring cannot be altered short of being destroyed and rebuilt.
// Use this to bypass the flooring system entirely ie. event areas, holodeck, etc.

/turf/simulated/floor/fixed
	name = "floor"
	icon = 'icons/turf/flooring/tiles.dmi'
	icon_state = "steel"
	initial_flooring = null

/turf/simulated/floor/fixed/attackby(var/obj/item/C, var/mob/user)
	if(istype(C, /obj/item/stack) && !isCoil(C))
		return
	return ..()

/turf/simulated/floor/fixed/update_icon()
	update_flood_overlay()

/turf/simulated/floor/fixed/is_plating()
	return 0

/turf/simulated/floor/fixed/set_flooring()
	return

/turf/simulated/floor/fixed/os13
	name = "OS13 floor"
	icon = 'icons/os13/turf/turf/floors.dmi'
	icon_state = "floor"

/turf/simulated/floor/fixed/os13/perforated_cover
	name = "perforated floor cover"
	icon = 'icons/os13/turf/turf/newmaintenance.dmi'
	icon_state = "hh"

/turf/simulated/floor/fixed/os13/plain_cover
	name = "floor cover"
	icon = 'icons/os13/turf/turf/newmaintenance.dmi'
	icon_state = "h3"

/turf/simulated/floor/fixed/os13/paired_cover
	name = "paired floor cover"
	icon = 'icons/os13/turf/turf/newmaintenance.dmi'
	icon_state = "ccc"

/turf/simulated/floor/fixed/os13/panel_floor
	icon = 'icons/os13/turf/turf/newmaintenance.dmi'
	icon_state = "hhh"

/turf/simulated/floor/fixed/alium
	name = "alien plating"
	desc = "This obviously wasn't made for your feet."
	icon = 'icons/turf/flooring/alium.dmi'
	icon_state = "jaggy"

/turf/simulated/floor/fixed/alium/attackby(var/obj/item/C, var/mob/user)
	if(isCrowbar(C))
		to_chat(user, "<span class='notice'>There aren't any openings big enough to pry it away...</span>")
		return
	return ..()

/turf/simulated/floor/fixed/alium/New()
	..()
	var/material/A = get_material_by_name("alien alloy")
	if(!A)
		return
	color = A.icon_colour
	icon_state = "[A.icon_base][(x*y) % 7]"

/turf/simulated/floor/fixed/alium/airless
	initial_gas = null
	temperature = TCMB

/turf/simulated/floor/fixed/alium/ex_act(severity)
	var/material/A = get_material_by_name("alien alloy")
	if(prob(A.explosion_resistance))
		return
	if(severity == 1)
		ChangeTurf(get_base_turf_by_area(src))

/turf/simulated/floor/fixed/os13/bridge
	icon = 'icons/os13/turf/turf/bridge.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/bridge/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/bridge/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/bridge/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/bridge/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/bridge/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/bridge/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/bridge/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/bridge/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/bridge/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/bridge/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/bridge/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/bridge/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/bridge/state_0_4
	icon_state = "0,4"

/turf/simulated/floor/fixed/os13/bridge/state_1_4
	icon_state = "1,4"

/turf/simulated/floor/fixed/os13/bridge/state_2_4
	icon_state = "2,4"

/turf/simulated/floor/fixed/os13/bridge/state_0_5
	icon_state = "0,5"

/turf/simulated/floor/fixed/os13/bridge/state_1_5
	icon_state = "1,5"

/turf/simulated/floor/fixed/os13/bridge/state_2_5
	icon_state = "2,5"

/turf/simulated/floor/fixed/os13/catwalk2
	icon = 'icons/os13/turf/turf/catwalk2.dmi'
	icon_state = "a"

/turf/simulated/floor/fixed/os13/catwalk2/state_a
	icon_state = "a"

/turf/simulated/floor/fixed/os13/cs
	icon = 'icons/os13/turf/turf/cs.dmi'
	icon_state = "cybspace"

/turf/simulated/floor/fixed/os13/cs/state_cybspace
	icon_state = "cybspace"

/turf/simulated/floor/fixed/os13/cs/state_cybspaceenter
	icon_state = "cybspaceenter"

/turf/simulated/floor/fixed/os13/dirt
	icon = 'icons/os13/turf/turf/dirt.dmi'
	icon_state = "1"

/turf/simulated/floor/fixed/os13/dirt/state_1
	icon_state = "1"

/turf/simulated/floor/fixed/os13/dirt/state_2
	icon_state = "2"

/turf/simulated/floor/fixed/os13/dirt/state_3
	icon_state = "3"

/turf/simulated/floor/fixed/os13/dirt/state_4
	icon_state = "4"

/turf/simulated/floor/fixed/os13/dirt/state_5
	icon_state = "5"

/turf/simulated/floor/fixed/os13/dirt/state_6
	icon_state = "6"

/turf/simulated/floor/fixed/os13/dirt/state_7
	icon_state = "7"

/turf/simulated/floor/fixed/os13/dirt/state_8
	icon_state = "8"

/turf/simulated/floor/fixed/os13/dirt/state_9
	icon_state = "9"

/turf/simulated/floor/fixed/os13/dirt/state_10
	icon_state = "10"

/turf/simulated/floor/fixed/os13/dirt/state_11
	icon_state = "11"

/turf/simulated/floor/fixed/os13/dirt/state_12
	icon_state = "12"

/turf/simulated/floor/fixed/os13/dirt/state_13
	icon_state = "13"

/turf/simulated/floor/fixed/os13/dirt/state_14
	icon_state = "14"

/turf/simulated/floor/fixed/os13/dirt/state_15
	icon_state = "15"

/turf/simulated/floor/fixed/os13/dirt/state_16
	icon_state = "16"

/turf/simulated/floor/fixed/os13/dirt/state_over_water1
	icon_state = "over_water1"

/turf/simulated/floor/fixed/os13/dirt/state_over_water2
	icon_state = "over_water2"

/turf/simulated/floor/fixed/os13/dirt/state_asteroid_dug3
	icon_state = "asteroid_dug3"

/turf/simulated/floor/fixed/os13/dirt/state_asteroid_dug2
	icon_state = "asteroid_dug2"

/turf/simulated/floor/fixed/os13/dirt/state_asteroid_dug1
	icon_state = "asteroid_dug1"

/turf/simulated/floor/fixed/os13/dirt/state_way
	icon_state = "way"

/turf/simulated/floor/fixed/os13/dirt2
	icon = 'icons/os13/turf/turf/dirt2.dmi'
	icon_state = "1"

/turf/simulated/floor/fixed/os13/dirt2/state_1
	icon_state = "1"

/turf/simulated/floor/fixed/os13/dirt2/state_2
	icon_state = "2"

/turf/simulated/floor/fixed/os13/dirt2/state_3
	icon_state = "3"

/turf/simulated/floor/fixed/os13/dirt2/state_4
	icon_state = "4"

/turf/simulated/floor/fixed/os13/dirt2/state_5
	icon_state = "5"

/turf/simulated/floor/fixed/os13/dirt2/state_6
	icon_state = "6"

/turf/simulated/floor/fixed/os13/dirt2/state_7
	icon_state = "7"

/turf/simulated/floor/fixed/os13/dirt2/state_8
	icon_state = "8"

/turf/simulated/floor/fixed/os13/dirt2/state_9
	icon_state = "9"

/turf/simulated/floor/fixed/os13/dirt2/state_10
	icon_state = "10"

/turf/simulated/floor/fixed/os13/dirt2/state_11
	icon_state = "11"

/turf/simulated/floor/fixed/os13/dirt2/state_12
	icon_state = "12"

/turf/simulated/floor/fixed/os13/dirt2/state_13
	icon_state = "13"

/turf/simulated/floor/fixed/os13/dirt2/state_14
	icon_state = "14"

/turf/simulated/floor/fixed/os13/dirt2/state_15
	icon_state = "15"

/turf/simulated/floor/fixed/os13/dirt2/state_16
	icon_state = "16"

/turf/simulated/floor/fixed/os13/dirt2/state_over_water1
	icon_state = "over_water1"

/turf/simulated/floor/fixed/os13/dirt2/state_over_water2
	icon_state = "over_water2"

/turf/simulated/floor/fixed/os13/dirt2/state_asteroid_dug3
	icon_state = "asteroid_dug3"

/turf/simulated/floor/fixed/os13/dirt2/state_asteroid_dug2
	icon_state = "asteroid_dug2"

/turf/simulated/floor/fixed/os13/dirt2/state_asteroid_dug1
	icon_state = "asteroid_dug1"

/turf/simulated/floor/fixed/os13/dirt2/state_way
	icon_state = "way"

/turf/simulated/floor/fixed/os13/floor_flesh
	icon = 'icons/os13/turf/turf/floor_flesh.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floor_flesh/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floor_flesh/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floor_flesh/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floor_flesh/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floor_parquet2
	icon = 'icons/os13/turf/turf/floor_parquet2.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floor_parquet2/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floor_parquet3
	icon = 'icons/os13/turf/turf/floor_parquet3.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floor_parquet3/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floor_parquet3/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floor_parquet3/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floor_parquet3/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors
	icon = 'icons/os13/turf/turf/floors.dmi'
	icon_state = "newstone3"

/turf/simulated/floor/fixed/os13/floors/state_newstone3
	icon_state = "newstone3"

/turf/simulated/floor/fixed/os13/floors/state_os4
	icon_state = "os4"

/turf/simulated/floor/fixed/os13/floors/state_floor
	icon_state = "floor"

/turf/simulated/floor/fixed/os13/floors/state_newstone4
	icon_state = "newstone4"

/turf/simulated/floor/fixed/os13/floors/state_bfloorz
	icon_state = "bfloorz"

/turf/simulated/floor/fixed/os13/floors/state_legadam
	icon_state = "legadam"

/turf/simulated/floor/fixed/os13/floors/state_sewerhatch1
	icon_state = "sewerhatch1"

/turf/simulated/floor/fixed/os13/floors/state_sewerhatch0
	icon_state = "sewerhatch0"

/turf/simulated/floor/fixed/os13/floors/state_sewerhatcha
	icon_state = "sewerhatcha"

/turf/simulated/floor/fixed/os13/floors/state_soft
	icon_state = "soft"

/turf/simulated/floor/fixed/os13/floors/state_n00
	icon_state = "n00"

/turf/simulated/floor/fixed/os13/floors/state_newcyber
	icon_state = "newcyber"

/turf/simulated/floor/fixed/os13/floors/state_n01
	icon_state = "n01"

/turf/simulated/floor/fixed/os13/floors/state_newbar
	icon_state = "newbar"

/turf/simulated/floor/fixed/os13/floors/state_solarpanel2
	icon_state = "solarpanel2"

/turf/simulated/floor/fixed/os13/floors/state_mhole
	icon_state = "mhole"

/turf/simulated/floor/fixed/os13/floors/state_polarwarn
	icon_state = "polarwarn"

/turf/simulated/floor/fixed/os13/floors/state_polarwarn2
	icon_state = "polarwarn2"

/turf/simulated/floor/fixed/os13/floors/state_bleeky
	icon_state = "bleeky"

/turf/simulated/floor/fixed/os13/floors/state_bleeky2
	icon_state = "bleeky2"

/turf/simulated/floor/fixed/os13/floors/state_npolar
	icon_state = "npolar"

/turf/simulated/floor/fixed/os13/floors/state_polar
	icon_state = "polar"

/turf/simulated/floor/fixed/os13/floors/state_lev
	icon_state = "lev"

/turf/simulated/floor/fixed/os13/floors/state_osb1
	icon_state = "osb1"

/turf/simulated/floor/fixed/os13/floors/state_os2
	icon_state = "os2"

/turf/simulated/floor/fixed/os13/floors/state_os3
	icon_state = "os3"

/turf/simulated/floor/fixed/os13/floors/state_os5
	icon_state = "os5"

/turf/simulated/floor/fixed/os13/floors/state_os7
	icon_state = "os7"

/turf/simulated/floor/fixed/os13/floors/state_os8
	icon_state = "os8"

/turf/simulated/floor/fixed/os13/floors/state_os13
	icon_state = "os13"

/turf/simulated/floor/fixed/os13/floors/state_os13b
	icon_state = "os13b"

/turf/simulated/floor/fixed/os13/floors/state_os4warn
	icon_state = "os4warn"

/turf/simulated/floor/fixed/os13/floors/state_thronelad
	icon_state = "thronelad"

/turf/simulated/floor/fixed/os13/floors/state_os4warn2
	icon_state = "os4warn2"

/turf/simulated/floor/fixed/os13/floors/state_os6
	icon_state = "os6"

/turf/simulated/floor/fixed/os13/floors/state_os9
	icon_state = "os9"

/turf/simulated/floor/fixed/os13/floors/state_os10
	icon_state = "os10"

/turf/simulated/floor/fixed/os13/floors/state_os11
	icon_state = "os11"

/turf/simulated/floor/fixed/os13/floors/state_os12
	icon_state = "os12"

/turf/simulated/floor/fixed/os13/floors/state_npolar2
	icon_state = "npolar2"

/turf/simulated/floor/fixed/os13/floors/state_exotic
	icon_state = "exotic"

/turf/simulated/floor/fixed/os13/floors/state_bluestone
	icon_state = "bluestone"

/turf/simulated/floor/fixed/os13/floors/state_greystone
	icon_state = "greystone"

/turf/simulated/floor/fixed/os13/floors/state_bluestone2
	icon_state = "bluestone2"

/turf/simulated/floor/fixed/os13/floors/state_bluestone3
	icon_state = "bluestone3"

/turf/simulated/floor/fixed/os13/floors/state_darkstone
	icon_state = "darkstone"

/turf/simulated/floor/fixed/os13/floors/state_bet
	icon_state = "bet"

/turf/simulated/floor/fixed/os13/floors/state_newstone2
	icon_state = "newstone2"

/turf/simulated/floor/fixed/os13/floors/state_k1
	icon_state = "k1"

/turf/simulated/floor/fixed/os13/floors/state_k3
	icon_state = "k3"

/turf/simulated/floor/fixed/os13/floors/state_mrav
	icon_state = "mrav"

/turf/simulated/floor/fixed/os13/floors/state_mrav2
	icon_state = "mrav2"

/turf/simulated/floor/fixed/os13/floors/state_k2
	icon_state = "k2"

/turf/simulated/floor/fixed/os13/floors/state_k4
	icon_state = "k4"

/turf/simulated/floor/fixed/os13/floors/state_2115
	icon_state = "2115"

/turf/simulated/floor/fixed/os13/floors/state_surgery
	icon_state = "surgery"

/turf/simulated/floor/fixed/os13/floors/state_surgery2
	icon_state = "surgery2"

/turf/simulated/floor/fixed/os13/floors/state_brothel
	icon_state = "brothel"

/turf/simulated/floor/fixed/os13/floors/state_cluster
	icon_state = "cluster"

/turf/simulated/floor/fixed/os13/floors/state_h
	icon_state = "H"

/turf/simulated/floor/fixed/os13/floors/state_grimy
	icon_state = "grimy"

/turf/simulated/floor/fixed/os13/floors/state_grim2
	icon_state = "grim2"

/turf/simulated/floor/fixed/os13/floors/state_sealab
	icon_state = "sealab"

/turf/simulated/floor/fixed/os13/floors/state_ss_ladder
	icon_state = "ss_ladder"

/turf/simulated/floor/fixed/os13/floors/state_snf2
	icon_state = "snf2"

/turf/simulated/floor/fixed/os13/floors/state_snf24
	icon_state = "snf24"

/turf/simulated/floor/fixed/os13/floors/state_snf23
	icon_state = "snf23"

/turf/simulated/floor/fixed/os13/floors/state_snf22
	icon_state = "snf22"

/turf/simulated/floor/fixed/os13/floors/state_nf2
	icon_state = "nf2"

/turf/simulated/floor/fixed/os13/floors/state_newstone
	icon_state = "newstone"

/turf/simulated/floor/fixed/os13/floors/state_temple1
	icon_state = "temple1"

/turf/simulated/floor/fixed/os13/floors/state_temple2
	icon_state = "temple2"

/turf/simulated/floor/fixed/os13/floors/state_temple3
	icon_state = "temple3"

/turf/simulated/floor/fixed/os13/floors/state_temple4
	icon_state = "temple4"

/turf/simulated/floor/fixed/os13/floors/state_stonecrafted
	icon_state = "stonecrafted"

/turf/simulated/floor/fixed/os13/floors/state_stonedamaged
	icon_state = "stonedamaged"

/turf/simulated/floor/fixed/os13/floors/state_nf24
	icon_state = "nf24"

/turf/simulated/floor/fixed/os13/floors/state_nf23
	icon_state = "nf23"

/turf/simulated/floor/fixed/os13/floors/state_nf22
	icon_state = "nf22"

/turf/simulated/floor/fixed/os13/floors/state_alien
	icon_state = "alien"

/turf/simulated/floor/fixed/os13/floors/state_newbar4
	icon_state = "newbar4"

/turf/simulated/floor/fixed/os13/floors/state_black
	icon_state = "black"

/turf/simulated/floor/fixed/os13/floors/state_newbar5
	icon_state = "newbar5"

/turf/simulated/floor/fixed/os13/floors/state_asteroid_anim
	icon_state = "asteroid_anim"

/turf/simulated/floor/fixed/os13/floors/state_w
	icon_state = "w"

/turf/simulated/floor/fixed/os13/floors/state_wb
	icon_state = "wb"

/turf/simulated/floor/fixed/os13/floors/state_wb2
	icon_state = "wb2"

/turf/simulated/floor/fixed/os13/floors/state_23
	icon_state = "23"

/turf/simulated/floor/fixed/os13/floors/state_23b
	icon_state = "23b"

/turf/simulated/floor/fixed/os13/floors/state_23s
	icon_state = "23s"

/turf/simulated/floor/fixed/os13/floors/state_24
	icon_state = "24"

/turf/simulated/floor/fixed/os13/floors/state_23323
	icon_state = "23323"

/turf/simulated/floor/fixed/os13/floors/state_snowbase
	icon_state = "snowbase"

/turf/simulated/floor/fixed/os13/floors/state_above
	icon_state = "above"

/turf/simulated/floor/fixed/os13/floors/state_a
	icon_state = "a"

/turf/simulated/floor/fixed/os13/floors/state_ns
	icon_state = "ns"

/turf/simulated/floor/fixed/os13/floors/state_asteroid2
	icon_state = "asteroid2"

/turf/simulated/floor/fixed/os13/floors/state_asteroid3
	icon_state = "asteroid3"

/turf/simulated/floor/fixed/os13/floors/state_asteroid4
	icon_state = "asteroid4"

/turf/simulated/floor/fixed/os13/floors/state_asteroid6
	icon_state = "asteroid6"

/turf/simulated/floor/fixed/os13/floors/state_asteroid7
	icon_state = "asteroid7"

/turf/simulated/floor/fixed/os13/floors/state_asteroid8
	icon_state = "asteroid8"

/turf/simulated/floor/fixed/os13/floors/state_asteroid
	icon_state = "asteroid"

/turf/simulated/floor/fixed/os13/floors/state_asteroid5
	icon_state = "asteroid5"

/turf/simulated/floor/fixed/os13/floors/state_asteroid0
	icon_state = "asteroid0"

/turf/simulated/floor/fixed/os13/floors/state_asteroid1
	icon_state = "asteroid1"

/turf/simulated/floor/fixed/os13/floors/state_asteroid9
	icon_state = "asteroid9"

/turf/simulated/floor/fixed/os13/floors/state_asteroid10
	icon_state = "asteroid10"

/turf/simulated/floor/fixed/os13/floors/state_s_ladder
	icon_state = "s_ladder"

/turf/simulated/floor/fixed/os13/floors/state_ladder
	icon_state = "ladder"

/turf/simulated/floor/fixed/os13/floors/state_ladder2
	icon_state = "ladder2"

/turf/simulated/floor/fixed/os13/floors/state_ladder4
	icon_state = "ladder4"

/turf/simulated/floor/fixed/os13/floors/state_ladder3
	icon_state = "ladder3"

/turf/simulated/floor/fixed/os13/floors/state_asteroid11
	icon_state = "asteroid11"

/turf/simulated/floor/fixed/os13/floors/state_asteroid12
	icon_state = "asteroid12"

/turf/simulated/floor/fixed/os13/floors/state_asteroid13
	icon_state = "asteroid13"

/turf/simulated/floor/fixed/os13/floors/state_plazar
	icon_state = "plazar"

/turf/simulated/floor/fixed/os13/floors/state_trainstation
	icon_state = "trainstation"

/turf/simulated/floor/fixed/os13/floors/state_cyberspace
	icon_state = "cyberspace"

/turf/simulated/floor/fixed/os13/floors/state_plating
	icon_state = "plating"

/turf/simulated/floor/fixed/os13/floors/state_bar2
	icon_state = "bar2"

/turf/simulated/floor/fixed/os13/floors/state_bar2r
	icon_state = "bar2r"

/turf/simulated/floor/fixed/os13/floors/state_bbb
	icon_state = "bbb"

/turf/simulated/floor/fixed/os13/floors/state_rct2
	icon_state = "rct2"

/turf/simulated/floor/fixed/os13/floors/state_bloodbar
	icon_state = "bloodbar"

/turf/simulated/floor/fixed/os13/floors/state_bbar2
	icon_state = "bbar2"

/turf/simulated/floor/fixed/os13/floors/state_firewall
	icon_state = "firewall"

/turf/simulated/floor/fixed/os13/floors/state_nfloorz
	icon_state = "nfloorz"

/turf/simulated/floor/fixed/os13/floors/state_n2floors
	icon_state = "n2floors"

/turf/simulated/floor/fixed/os13/floors/state_open
	icon_state = "open"

/turf/simulated/floor/fixed/os13/floors/state_empty
	icon_state = "empty"

/turf/simulated/floor/fixed/os13/floors/state_open2
	icon_state = "open2"

/turf/simulated/floor/fixed/os13/floors/state_mayo
	icon_state = "mayo"

/turf/simulated/floor/fixed/os13/floors/state_circuitoff
	icon_state = "circuitoff"

/turf/simulated/floor/fixed/os13/floors/state_circuitoff2
	icon_state = "circuitoff2"

/turf/simulated/floor/fixed/os13/floors/state_ldamaged1
	icon_state = "ldamaged1"

/turf/simulated/floor/fixed/os13/floors/state_ldamaged2
	icon_state = "ldamaged2"

/turf/simulated/floor/fixed/os13/floors/state_ldamaged3
	icon_state = "ldamaged3"

/turf/simulated/floor/fixed/os13/floors/state_ldamaged4
	icon_state = "ldamaged4"

/turf/simulated/floor/fixed/os13/floors/state_wf
	icon_state = "wf"

/turf/simulated/floor/fixed/os13/floors/state_wf2
	icon_state = "wf2"

/turf/simulated/floor/fixed/os13/floors/state_ldamaged5
	icon_state = "ldamaged5"

/turf/simulated/floor/fixed/os13/floors/state_lpanelscorched
	icon_state = "lpanelscorched"

/turf/simulated/floor/fixed/os13/floors/state_lfloorscorched1
	icon_state = "lfloorscorched1"

/turf/simulated/floor/fixed/os13/floors/state_lfloorscorched3
	icon_state = "lfloorscorched3"

/turf/simulated/floor/fixed/os13/floors/state_lfloorscorched2
	icon_state = "lfloorscorched2"

/turf/simulated/floor/fixed/os13/floors/state_lplatingdmg1
	icon_state = "lplatingdmg1"

/turf/simulated/floor/fixed/os13/floors/state_lplatingdmg2
	icon_state = "lplatingdmg2"

/turf/simulated/floor/fixed/os13/floors/state_lplatingdmg3
	icon_state = "lplatingdmg3"

/turf/simulated/floor/fixed/os13/floors/state_damaged1
	icon_state = "damaged1"

/turf/simulated/floor/fixed/os13/floors/state_damaged2
	icon_state = "damaged2"

/turf/simulated/floor/fixed/os13/floors/state_damaged3
	icon_state = "damaged3"

/turf/simulated/floor/fixed/os13/floors/state_panelscorched
	icon_state = "panelscorched"

/turf/simulated/floor/fixed/os13/floors/state_parket
	icon_state = "parket"

/turf/simulated/floor/fixed/os13/floors/state_parket_bright
	icon_state = "parket_bright"

/turf/simulated/floor/fixed/os13/floors/state_floorscorched1
	icon_state = "floorscorched1"

/turf/simulated/floor/fixed/os13/floors/state_floorscorched2
	icon_state = "floorscorched2"

/turf/simulated/floor/fixed/os13/floors/state_damaged4
	icon_state = "damaged4"

/turf/simulated/floor/fixed/os13/floors/state_damaged5
	icon_state = "damaged5"

/turf/simulated/floor/fixed/os13/floors/state_platingdmg1
	icon_state = "platingdmg1"

/turf/simulated/floor/fixed/os13/floors/state_platingdmg2
	icon_state = "platingdmg2"

/turf/simulated/floor/fixed/os13/floors/state_platingdmg3
	icon_state = "platingdmg3"

/turf/simulated/floor/fixed/os13/floors/state_bar3
	icon_state = "bar3"

/turf/simulated/floor/fixed/os13/floors/state_chapelnew
	icon_state = "chapelnew"

/turf/simulated/floor/fixed/os13/floors/state_blackice
	icon_state = "blackice"

/turf/simulated/floor/fixed/os13/floors/state_hull
	icon_state = "hull"

/turf/simulated/floor/fixed/os13/floors/state_newhull
	icon_state = "newhull"

/turf/simulated/floor/fixed/os13/floors/state_plazaf
	icon_state = "plazaf"

/turf/simulated/floor/fixed/os13/floors/state_plazaf2
	icon_state = "plazaf2"

/turf/simulated/floor/fixed/os13/floors/state_plaza
	icon_state = "plaza"

/turf/simulated/floor/fixed/os13/floors/state_pol3
	icon_state = "pol3"

/turf/simulated/floor/fixed/os13/floors/state_plazabox
	icon_state = "plazabox"

/turf/simulated/floor/fixed/os13/floors/state_6
	icon_state = "6"

/turf/simulated/floor/fixed/os13/floors/state_zzz
	icon_state = "zzz"

/turf/simulated/floor/fixed/os13/floors/state_seabed
	icon_state = "seabed"

/turf/simulated/floor/fixed/os13/floors/state_asteroid_dug3
	icon_state = "asteroid_dug3"

/turf/simulated/floor/fixed/os13/floors/state_asteroid_dug2
	icon_state = "asteroid_dug2"

/turf/simulated/floor/fixed/os13/floors/state_asteroid_dug1
	icon_state = "asteroid_dug1"

/turf/simulated/floor/fixed/os13/floors/state_platingk
	icon_state = "platingk"

/turf/simulated/floor/fixed/os13/floors/state_floor02
	icon_state = "floor02"

/turf/simulated/floor/fixed/os13/floors/state_34242
	icon_state = "34242"

/turf/simulated/floor/fixed/os13/floors/state_pol
	icon_state = "pol"

/turf/simulated/floor/fixed/os13/floors/state_pol2
	icon_state = "pol2"

/turf/simulated/floor/fixed/os13/floors/state_pol22
	icon_state = "pol22"

/turf/simulated/floor/fixed/os13/floors/state_pol23
	icon_state = "pol23"

/turf/simulated/floor/fixed/os13/floors/state_blackcorner
	icon_state = "blackcorner"

/turf/simulated/floor/fixed/os13/floors/state_n
	icon_state = "n"

/turf/simulated/floor/fixed/os13/floors/state_carpbet2side
	icon_state = "carpbet2side"

/turf/simulated/floor/fixed/os13/floors/state_carpbet2
	icon_state = "carpbet2"

/turf/simulated/floor/fixed/os13/floors/state_carpet2side
	icon_state = "carpet2side"

/turf/simulated/floor/fixed/os13/floors/state_carpet2
	icon_state = "carpet2"

/turf/simulated/floor/fixed/os13/floors/state_21
	icon_state = "21"

/turf/simulated/floor/fixed/os13/floors/state_22
	icon_state = "22"

/turf/simulated/floor/fixed/os13/floors/state_surface
	icon_state = "surface"

/turf/simulated/floor/fixed/os13/floors/state_fx
	icon_state = "FX"

/turf/simulated/floor/fixed/os13/floors/state_fx2
	icon_state = "FX2"

/turf/simulated/floor/fixed/os13/floors/state_k
	icon_state = "K"

/turf/simulated/floor/fixed/os13/floors/state_zero
	icon_state = "zero"

/turf/simulated/floor/fixed/os13/floors/state_f7
	icon_state = "F7"

/turf/simulated/floor/fixed/os13/floors/state_rct
	icon_state = "rct"

/turf/simulated/floor/fixed/os13/floors/state_rct3
	icon_state = "rct3"

/turf/simulated/floor/fixed/os13/floors/state_rct4
	icon_state = "rct4"

/turf/simulated/floor/fixed/os13/floors/state_steel
	icon_state = "steel"

/turf/simulated/floor/fixed/os13/floors/state_wallo6
	icon_state = "wallo6"

/turf/simulated/floor/fixed/os13/floors/state_wallo5
	icon_state = "wallo5"

/turf/simulated/floor/fixed/os13/floors/state_wallo7
	icon_state = "wallo7"

/turf/simulated/floor/fixed/os13/floors/state_wallo8
	icon_state = "wallo8"

/turf/simulated/floor/fixed/os13/floors/state_f2
	icon_state = "F2"

/turf/simulated/floor/fixed/os13/floors/state_f3
	icon_state = "F3"

/turf/simulated/floor/fixed/os13/floors/state_f4
	icon_state = "F4"

/turf/simulated/floor/fixed/os13/floors/state_f55
	icon_state = "F55"

/turf/simulated/floor/fixed/os13/floors/state_f5
	icon_state = "F5"

/turf/simulated/floor/fixed/os13/floors/state_f
	icon_state = "F"

/turf/simulated/floor/fixed/os13/floors/state_f6
	icon_state = "F6"

/turf/simulated/floor/fixed/os13/floors/state_ff
	icon_state = "FF"

/turf/simulated/floor/fixed/os13/floors/state_f74
	icon_state = "F74"

/turf/simulated/floor/fixed/os13/floors/state_h2
	icon_state = "H2"

/turf/simulated/floor/fixed/os13/floors/state_surface2
	icon_state = "surface2"

/turf/simulated/floor/fixed/os13/floors/state_surface3
	icon_state = "surface3"

/turf/simulated/floor/fixed/os13/floors/state_newbar2
	icon_state = "newbar2"

/turf/simulated/floor/fixed/os13/floors/state_evil
	icon_state = "evil"

/turf/simulated/floor/fixed/os13/floors/state_bloodf2
	icon_state = "bloodf2"

/turf/simulated/floor/fixed/os13/floors/state_3323
	icon_state = "3323"

/turf/simulated/floor/fixed/os13/floors/state_carpbet23side
	icon_state = "carpbet23side"

/turf/simulated/floor/fixed/os13/floors/state_carpbet23
	icon_state = "carpbet23"

/turf/simulated/floor/fixed/os13/floors/state_tladder
	icon_state = "tladder"

/turf/simulated/floor/fixed/os13/floors/state_bf2
	icon_state = "bf2"

/turf/simulated/floor/fixed/os13/floors/state_bf22
	icon_state = "bf22"

/turf/simulated/floor/fixed/os13/floors/state_bf25
	icon_state = "bf25"

/turf/simulated/floor/fixed/os13/floors/state_troom1
	icon_state = "troom1"

/turf/simulated/floor/fixed/os13/floors/state_troom2
	icon_state = "troom2"

/turf/simulated/floor/fixed/os13/floors/state_troom3
	icon_state = "troom3"

/turf/simulated/floor/fixed/os13/floors/state_grimy3
	icon_state = "grimy3"

/turf/simulated/floor/fixed/os13/floors/state_nfloorz2
	icon_state = "nfloorz2"

/turf/simulated/floor/fixed/os13/floors/state_nfloorz3
	icon_state = "nfloorz3"

/turf/simulated/floor/fixed/os13/floors/state_nfloorz4
	icon_state = "nfloorz4"

/turf/simulated/floor/fixed/os13/floors/state_betb
	icon_state = "betb"

/turf/simulated/floor/fixed/os13/floors/state_sladder
	icon_state = "sladder"

/turf/simulated/floor/fixed/os13/floors_cave_new
	icon = 'icons/os13/turf/turf/floors_cave_new.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_dug3
	icon_state = "dug3"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_dug2
	icon_state = "dug2"

/turf/simulated/floor/fixed/os13/floors_cave_new/state_dug1
	icon_state = "dug1"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new
	icon = 'icons/os13/turf/turf/floors_cave_stone_new.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/floors_cave_stone_new/state_ov
	icon_state = "ov"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles
	icon = 'icons/os13/turf/turf/floors_concrete_new_tiles.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/floors_concrete_new_tiles/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/floors_glow
	icon = 'icons/os13/turf/turf/floors_glow.dmi'
	icon_state = "os13"

/turf/simulated/floor/fixed/os13/floors_glow/state_os13
	icon_state = "os13"

/turf/simulated/floor/fixed/os13/floors_glow/state_n01
	icon_state = "n01"

/turf/simulated/floor/fixed/os13/floors_interior_face
	icon = 'icons/os13/turf/turf/floors_interior_face.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/floors_interior_face/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/floors_interior_stone_new_tiles
	icon = 'icons/os13/turf/turf/floors_interior_stone_new_tiles.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_interior_stone_new_tiles/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_interior_stone_new_tiles/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_interior_stone_new_tiles/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_interior_stone_new_tiles/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_interior_stone_new_tiles/state_border
	icon_state = "border"

/turf/simulated/floor/fixed/os13/floors_parquet
	icon = 'icons/os13/turf/turf/floors_parquet.dmi'
	icon_state = "parket_bright"

/turf/simulated/floor/fixed/os13/floors_parquet/state_parket_bright
	icon_state = "parket_bright"

/turf/simulated/floor/fixed/os13/floors_parquet/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_parquet/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_parquet/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_parquet/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_parquet/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_parquet/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_parquet/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_parquet/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_parquet/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floors_stone_new2
	icon = 'icons/os13/turf/turf/floors_stone_new2.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_stone_new2/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles
	icon = 'icons/os13/turf/turf/floors_stone_new_tiles.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2
	icon = 'icons/os13/turf/turf/floors_stone_new_tiles2.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/floors_stone_new_tiles2/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/hell
	icon = 'icons/os13/turf/turf/hell.dmi'
	icon_state = "floor"

/turf/simulated/floor/fixed/os13/hell/state_floor
	icon_state = "floor"

/turf/simulated/floor/fixed/os13/ice
	icon = 'icons/os13/turf/turf/ice.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/ice/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/ice/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/ice/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/ice/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/ice/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/ice/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/ice/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/ice/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/ice/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/ice/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/ice/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/ice/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/ice/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/ice/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/ice/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/ice/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/ice/state_crack1
	icon_state = "crack1"

/turf/simulated/floor/fixed/os13/ice/state_crack2
	icon_state = "crack2"

/turf/simulated/floor/fixed/os13/ice/state_crack3
	icon_state = "crack3"

/turf/simulated/floor/fixed/os13/ice/state_crack4
	icon_state = "crack4"

/turf/simulated/floor/fixed/os13/ice/state_crack5
	icon_state = "crack5"

/turf/simulated/floor/fixed/os13/ice/state_crack6
	icon_state = "crack6"

/turf/simulated/floor/fixed/os13/ice/state_crack7
	icon_state = "crack7"

/turf/simulated/floor/fixed/os13/ice/state_crack8
	icon_state = "crack8"

/turf/simulated/floor/fixed/os13/ice/state_crack9
	icon_state = "crack9"

/turf/simulated/floor/fixed/os13/ice/state_crack10
	icon_state = "crack10"

/turf/simulated/floor/fixed/os13/newmaintenance
	icon = 'icons/os13/turf/turf/newmaintenance.dmi'
	icon_state = "nse"

/turf/simulated/floor/fixed/os13/newmaintenance/state_nse
	icon_state = "nse"

/turf/simulated/floor/fixed/os13/newmaintenance/state_swe
	icon_state = "swe"

/turf/simulated/floor/fixed/os13/newmaintenance/state_nsw
	icon_state = "nsw"

/turf/simulated/floor/fixed/os13/newmaintenance/state_nwe
	icon_state = "nwe"

/turf/simulated/floor/fixed/os13/newmaintenance/state_hub
	icon_state = "hub"

/turf/simulated/floor/fixed/os13/newmaintenance/state_se
	icon_state = "se"

/turf/simulated/floor/fixed/os13/newmaintenance/state_sw
	icon_state = "sw"

/turf/simulated/floor/fixed/os13/newmaintenance/state_nw
	icon_state = "nw"

/turf/simulated/floor/fixed/os13/newmaintenance/state_ne
	icon_state = "ne"

/turf/simulated/floor/fixed/os13/newmaintenance/state_vertical
	icon_state = "vertical"

/turf/simulated/floor/fixed/os13/newmaintenance/state_horizontal
	icon_state = "horizontal"

/turf/simulated/floor/fixed/os13/newmaintenance/state_empty
	icon_state = ""

/turf/simulated/floor/fixed/os13/newmaintenance/state_hh
	icon_state = "hh"

/turf/simulated/floor/fixed/os13/newmaintenance/state_hhh
	icon_state = "hhh"

/turf/simulated/floor/fixed/os13/newmaintenance/state_h2
	icon_state = "h2"

/turf/simulated/floor/fixed/os13/newmaintenance/state_h3
	icon_state = "h3"

/turf/simulated/floor/fixed/os13/newmaintenance/state_h
	icon_state = "h"

/turf/simulated/floor/fixed/os13/newmaintenance/state_ccc
	icon_state = "ccc"

/turf/simulated/floor/fixed/os13/newrails
	icon = 'icons/os13/turf/turf/newrails.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/newrails/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/newrails/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/newrails/state_4_0
	icon_state = "4,0"

/turf/simulated/floor/fixed/os13/newrails/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/newrails/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/newrails/state_4_1
	icon_state = "4,1"

/turf/simulated/floor/fixed/os13/newrails/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/newrails/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/newrails/state_4_2
	icon_state = "4,2"

/turf/simulated/floor/fixed/os13/newrails/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/newrails/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/newrails/state_4_3
	icon_state = "4,3"

/turf/simulated/floor/fixed/os13/newrails/state_0_4
	icon_state = "0,4"

/turf/simulated/floor/fixed/os13/newrails/state_2_4
	icon_state = "2,4"

/turf/simulated/floor/fixed/os13/newrails/state_4_4
	icon_state = "4,4"

/turf/simulated/floor/fixed/os13/newrails/state_0_5
	icon_state = "0,5"

/turf/simulated/floor/fixed/os13/newrails/state_2_5
	icon_state = "2,5"

/turf/simulated/floor/fixed/os13/newrails/state_4_5
	icon_state = "4,5"

/turf/simulated/floor/fixed/os13/newrails/state_0_6
	icon_state = "0,6"

/turf/simulated/floor/fixed/os13/newrails/state_2_6
	icon_state = "2,6"

/turf/simulated/floor/fixed/os13/newrails/state_4_6
	icon_state = "4,6"

/turf/simulated/floor/fixed/os13/newrails/state_0_7
	icon_state = "0,7"

/turf/simulated/floor/fixed/os13/newrails/state_2_7
	icon_state = "2,7"

/turf/simulated/floor/fixed/os13/newrails/state_4_7
	icon_state = "4,7"

/turf/simulated/floor/fixed/os13/newrails/state_0_8
	icon_state = "0,8"

/turf/simulated/floor/fixed/os13/newrails/state_2_8
	icon_state = "2,8"

/turf/simulated/floor/fixed/os13/newrails/state_4_8
	icon_state = "4,8"

/turf/simulated/floor/fixed/os13/newrails/state_0_9
	icon_state = "0,9"

/turf/simulated/floor/fixed/os13/newrails/state_2_9
	icon_state = "2,9"

/turf/simulated/floor/fixed/os13/newrails/state_4_9
	icon_state = "4,9"

/turf/simulated/floor/fixed/os13/newrails/state_newrailsanim_0_0
	icon_state = "NewRailsAnim 0,0"

/turf/simulated/floor/fixed/os13/newrails/state_newrailsanim_1_0
	icon_state = "NewRailsAnim 1,0"

/turf/simulated/floor/fixed/os13/newrails/state_newrailsanim_2_0
	icon_state = "NewRailsAnim 2,0"

/turf/simulated/floor/fixed/os13/newrails/state_static_0_0
	icon_state = "Static 0,0"

/turf/simulated/floor/fixed/os13/newrails/state_static_1_0
	icon_state = "Static 1,0"

/turf/simulated/floor/fixed/os13/newrails/state_static_2_0
	icon_state = "Static 2,0"

/turf/simulated/floor/fixed/os13/newrails2
	icon = 'icons/os13/turf/turf/newrails2.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/newrails2/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/newrails2/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/newrails2/state_0_4
	icon_state = "0,4"

/turf/simulated/floor/fixed/os13/newrails2/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/newrails2/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/newrails2/state_1_4
	icon_state = "1,4"

/turf/simulated/floor/fixed/os13/newrails2/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/newrails2/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/newrails2/state_2_4
	icon_state = "2,4"

/turf/simulated/floor/fixed/os13/newrails2/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/newrails2/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/newrails2/state_3_4
	icon_state = "3,4"

/turf/simulated/floor/fixed/os13/newrails2/state_4_0
	icon_state = "4,0"

/turf/simulated/floor/fixed/os13/newrails2/state_4_2
	icon_state = "4,2"

/turf/simulated/floor/fixed/os13/newrails2/state_4_4
	icon_state = "4,4"

/turf/simulated/floor/fixed/os13/newrails2/state_5_0
	icon_state = "5,0"

/turf/simulated/floor/fixed/os13/newrails2/state_5_2
	icon_state = "5,2"

/turf/simulated/floor/fixed/os13/newrails2/state_5_4
	icon_state = "5,4"

/turf/simulated/floor/fixed/os13/newrails2/state_6_0
	icon_state = "6,0"

/turf/simulated/floor/fixed/os13/newrails2/state_6_2
	icon_state = "6,2"

/turf/simulated/floor/fixed/os13/newrails2/state_6_4
	icon_state = "6,4"

/turf/simulated/floor/fixed/os13/newrails2/state_7_0
	icon_state = "7,0"

/turf/simulated/floor/fixed/os13/newrails2/state_7_2
	icon_state = "7,2"

/turf/simulated/floor/fixed/os13/newrails2/state_7_4
	icon_state = "7,4"

/turf/simulated/floor/fixed/os13/newrails2/state_8_0
	icon_state = "8,0"

/turf/simulated/floor/fixed/os13/newrails2/state_8_2
	icon_state = "8,2"

/turf/simulated/floor/fixed/os13/newrails2/state_8_4
	icon_state = "8,4"

/turf/simulated/floor/fixed/os13/newrails2/state_9_0
	icon_state = "9,0"

/turf/simulated/floor/fixed/os13/newrails2/state_9_2
	icon_state = "9,2"

/turf/simulated/floor/fixed/os13/newrails2/state_9_4
	icon_state = "9,4"

/turf/simulated/floor/fixed/os13/platform
	icon = 'icons/os13/turf/turf/platform.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/platform/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/platform/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/platform/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/platform/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/platform/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/platform/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/platform/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/platform/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/platform/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/platform/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/platform/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/platform/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/platform/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/platform/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/platform/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/platform/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/platform/state_empty
	icon_state = ""

/turf/simulated/floor/fixed/os13/platform2
	icon = 'icons/os13/turf/turf/platform2.dmi'
	icon_state = "H2 0,0"

/turf/simulated/floor/fixed/os13/platform2/state_h2_0_0
	icon_state = "H2 0,0"

/turf/simulated/floor/fixed/os13/platform2/state_h2_1_0
	icon_state = "H2 1,0"

/turf/simulated/floor/fixed/os13/platform2/state_h2_2_0
	icon_state = "H2 2,0"

/turf/simulated/floor/fixed/os13/platform2/state_h2_0_1
	icon_state = "H2 0,1"

/turf/simulated/floor/fixed/os13/platform2/state_h2_1_1
	icon_state = "H2 1,1"

/turf/simulated/floor/fixed/os13/platform2/state_h2_2_1
	icon_state = "H2 2,1"

/turf/simulated/floor/fixed/os13/platform2/state_h2_0_2
	icon_state = "H2 0,2"

/turf/simulated/floor/fixed/os13/platform2/state_h2_1_2
	icon_state = "H2 1,2"

/turf/simulated/floor/fixed/os13/platform2/state_h2_2_2
	icon_state = "H2 2,2"

/turf/simulated/floor/fixed/os13/rails
	icon = 'icons/os13/turf/turf/rails.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/rails/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/rails/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/rails/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/rails/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/rails/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/rails/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/rails/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/rails/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/rails/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/rails/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/rails/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/rails/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/rails/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/rails/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/rails/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/rails/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/rails/state_asteroid_anim
	icon_state = "asteroid_anim"

/turf/simulated/floor/fixed/os13/rails/state_asteroid_anim2
	icon_state = "asteroid_anim2"

/turf/simulated/floor/fixed/os13/snow
	icon = 'icons/os13/turf/turf/snow.dmi'
	icon_state = "thisisfuckingstupid"

/turf/simulated/floor/fixed/os13/snow/state_thisisfuckingstupid
	icon_state = "thisisfuckingstupid"

/turf/simulated/floor/fixed/os13/snow/state_ironsand1
	icon_state = "ironsand1"

/turf/simulated/floor/fixed/os13/snow/state_ironsand2
	icon_state = "ironsand2"

/turf/simulated/floor/fixed/os13/snow/state_ironsand3
	icon_state = "ironsand3"

/turf/simulated/floor/fixed/os13/snow/state_ironsand4
	icon_state = "ironsand4"

/turf/simulated/floor/fixed/os13/snow/state_ironsand5
	icon_state = "ironsand5"

/turf/simulated/floor/fixed/os13/snow/state_ironsand6
	icon_state = "ironsand6"

/turf/simulated/floor/fixed/os13/snow/state_ironsand7
	icon_state = "ironsand7"

/turf/simulated/floor/fixed/os13/snow/state_ironsand8
	icon_state = "ironsand8"

/turf/simulated/floor/fixed/os13/snow/state_ironsand9
	icon_state = "ironsand9"

/turf/simulated/floor/fixed/os13/snow/state_ironsand10
	icon_state = "ironsand10"

/turf/simulated/floor/fixed/os13/snow/state_ironsand11
	icon_state = "ironsand11"

/turf/simulated/floor/fixed/os13/snow/state_ironsand12
	icon_state = "ironsand12"

/turf/simulated/floor/fixed/os13/snow/state_ironsand13
	icon_state = "ironsand13"

/turf/simulated/floor/fixed/os13/snow/state_ironsand14
	icon_state = "ironsand14"

/turf/simulated/floor/fixed/os13/snow/state_ironsand16
	icon_state = "ironsand16"

/turf/simulated/floor/fixed/os13/snow/state_ironsand15
	icon_state = "ironsand15"

/turf/simulated/floor/fixed/os13/snow/state_ironsand0
	icon_state = "ironsand0"

/turf/simulated/floor/fixed/os13/snow/state_asteroid_dug3
	icon_state = "asteroid_dug3"

/turf/simulated/floor/fixed/os13/snow/state_asteroid_dug2
	icon_state = "asteroid_dug2"

/turf/simulated/floor/fixed/os13/snow/state_asteroid_dug1
	icon_state = "asteroid_dug1"

/turf/simulated/floor/fixed/os13/snow/state_worm1
	icon_state = "worm1"

/turf/simulated/floor/fixed/os13/snow/state_worm2
	icon_state = "worm2"

/turf/simulated/floor/fixed/os13/snow/state_worm3
	icon_state = "worm3"

/turf/simulated/floor/fixed/os13/snow/state_worm4
	icon_state = "worm4"

/turf/simulated/floor/fixed/os13/snow/state_worms
	icon_state = "worms"

/turf/simulated/floor/fixed/os13/snow/state_worms2
	icon_state = "worms2"

/turf/simulated/floor/fixed/os13/snow/state_over_water1
	icon_state = "over_water1"

/turf/simulated/floor/fixed/os13/snow/state_over_water2
	icon_state = "over_water2"

/turf/simulated/floor/fixed/os13/snow/state_grave0
	icon_state = "grave0"

/turf/simulated/floor/fixed/os13/snow/state_grave_t1
	icon_state = "grave_t1"

/turf/simulated/floor/fixed/os13/snow/state_grave_t2
	icon_state = "grave_t2"

/turf/simulated/floor/fixed/os13/snow/state_grave_t3
	icon_state = "grave_t3"

/turf/simulated/floor/fixed/os13/snow/state_grave1
	icon_state = "grave1"

/turf/simulated/floor/fixed/os13/snow/state_graved
	icon_state = "graved"

/turf/simulated/floor/fixed/os13/snow/state_snowmask
	icon_state = "snowmask"

/turf/simulated/floor/fixed/os13/snow/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/snow/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/snow/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/snow/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/snow/state_4_0
	icon_state = "4,0"

/turf/simulated/floor/fixed/os13/snow/state_5_0
	icon_state = "5,0"

/turf/simulated/floor/fixed/os13/snow/state_6_0
	icon_state = "6,0"

/turf/simulated/floor/fixed/os13/snow/state_7_0
	icon_state = "7,0"

/turf/simulated/floor/fixed/os13/snow/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/snow/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/snow/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/snow/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/snow/state_4_1
	icon_state = "4,1"

/turf/simulated/floor/fixed/os13/snow/state_5_1
	icon_state = "5,1"

/turf/simulated/floor/fixed/os13/snow/state_6_1
	icon_state = "6,1"

/turf/simulated/floor/fixed/os13/snow/state_7_1
	icon_state = "7,1"

/turf/simulated/floor/fixed/os13/snow/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/snow/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/snow/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/snow/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/snow/state_4_2
	icon_state = "4,2"

/turf/simulated/floor/fixed/os13/snow/state_5_2
	icon_state = "5,2"

/turf/simulated/floor/fixed/os13/snow/state_6_2
	icon_state = "6,2"

/turf/simulated/floor/fixed/os13/snow/state_7_2
	icon_state = "7,2"

/turf/simulated/floor/fixed/os13/snow/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/snow/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/snow/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/snow/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/snow/state_4_3
	icon_state = "4,3"

/turf/simulated/floor/fixed/os13/snow/state_5_3
	icon_state = "5,3"

/turf/simulated/floor/fixed/os13/snow/state_6_3
	icon_state = "6,3"

/turf/simulated/floor/fixed/os13/snow/state_7_3
	icon_state = "7,3"

/turf/simulated/floor/fixed/os13/snow/state_0_4
	icon_state = "0,4"

/turf/simulated/floor/fixed/os13/snow/state_1_4
	icon_state = "1,4"

/turf/simulated/floor/fixed/os13/snow/state_2_4
	icon_state = "2,4"

/turf/simulated/floor/fixed/os13/snow/state_3_4
	icon_state = "3,4"

/turf/simulated/floor/fixed/os13/snow/state_4_4
	icon_state = "4,4"

/turf/simulated/floor/fixed/os13/snow/state_5_4
	icon_state = "5,4"

/turf/simulated/floor/fixed/os13/snow/state_6_4
	icon_state = "6,4"

/turf/simulated/floor/fixed/os13/snow/state_7_4
	icon_state = "7,4"

/turf/simulated/floor/fixed/os13/snow/state_0_5
	icon_state = "0,5"

/turf/simulated/floor/fixed/os13/snow/state_1_5
	icon_state = "1,5"

/turf/simulated/floor/fixed/os13/snow/state_2_5
	icon_state = "2,5"

/turf/simulated/floor/fixed/os13/snow/state_3_5
	icon_state = "3,5"

/turf/simulated/floor/fixed/os13/snow/state_4_5
	icon_state = "4,5"

/turf/simulated/floor/fixed/os13/snow/state_5_5
	icon_state = "5,5"

/turf/simulated/floor/fixed/os13/snow/state_6_5
	icon_state = "6,5"

/turf/simulated/floor/fixed/os13/snow/state_7_5
	icon_state = "7,5"

/turf/simulated/floor/fixed/os13/snow/state_0_6
	icon_state = "0,6"

/turf/simulated/floor/fixed/os13/snow/state_1_6
	icon_state = "1,6"

/turf/simulated/floor/fixed/os13/snow/state_2_6
	icon_state = "2,6"

/turf/simulated/floor/fixed/os13/snow/state_3_6
	icon_state = "3,6"

/turf/simulated/floor/fixed/os13/snow/state_4_6
	icon_state = "4,6"

/turf/simulated/floor/fixed/os13/snow/state_5_6
	icon_state = "5,6"

/turf/simulated/floor/fixed/os13/snow/state_6_6
	icon_state = "6,6"

/turf/simulated/floor/fixed/os13/snow/state_7_6
	icon_state = "7,6"

/turf/simulated/floor/fixed/os13/snow/state_0_7
	icon_state = "0,7"

/turf/simulated/floor/fixed/os13/snow/state_1_7
	icon_state = "1,7"

/turf/simulated/floor/fixed/os13/snow/state_2_7
	icon_state = "2,7"

/turf/simulated/floor/fixed/os13/snow/state_3_7
	icon_state = "3,7"

/turf/simulated/floor/fixed/os13/snow/state_4_7
	icon_state = "4,7"

/turf/simulated/floor/fixed/os13/snow/state_5_7
	icon_state = "5,7"

/turf/simulated/floor/fixed/os13/snow/state_6_7
	icon_state = "6,7"

/turf/simulated/floor/fixed/os13/snow/state_7_7
	icon_state = "7,7"

/turf/simulated/floor/fixed/os13/soulwall2
	icon = 'icons/os13/turf/turf/soulwall2.dmi'
	icon_state = "SoulFloor"

/turf/simulated/floor/fixed/os13/soulwall2/state_soulfloor
	icon_state = "SoulFloor"

/turf/simulated/floor/fixed/os13/soulwall2/state_soulfloors
	icon_state = "SoulFloorS"

/turf/simulated/floor/fixed/os13/soulwall2/state_darkfloor
	icon_state = "darkfloor"

/turf/simulated/floor/fixed/os13/stonefloor
	icon = 'icons/os13/turf/turf/stonefloor.dmi'
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/stonefloor/state_0_0
	icon_state = "0,0"

/turf/simulated/floor/fixed/os13/stonefloor/state_1_0
	icon_state = "1,0"

/turf/simulated/floor/fixed/os13/stonefloor/state_2_0
	icon_state = "2,0"

/turf/simulated/floor/fixed/os13/stonefloor/state_3_0
	icon_state = "3,0"

/turf/simulated/floor/fixed/os13/stonefloor/state_4_0
	icon_state = "4,0"

/turf/simulated/floor/fixed/os13/stonefloor/state_5_0
	icon_state = "5,0"

/turf/simulated/floor/fixed/os13/stonefloor/state_25
	icon_state = "25"

/turf/simulated/floor/fixed/os13/stonefloor/state_0_1
	icon_state = "0,1"

/turf/simulated/floor/fixed/os13/stonefloor/state_1_1
	icon_state = "1,1"

/turf/simulated/floor/fixed/os13/stonefloor/state_2_1
	icon_state = "2,1"

/turf/simulated/floor/fixed/os13/stonefloor/state_3_1
	icon_state = "3,1"

/turf/simulated/floor/fixed/os13/stonefloor/state_4_1
	icon_state = "4,1"

/turf/simulated/floor/fixed/os13/stonefloor/state_5_1
	icon_state = "5,1"

/turf/simulated/floor/fixed/os13/stonefloor/state_0_2
	icon_state = "0,2"

/turf/simulated/floor/fixed/os13/stonefloor/state_1_2
	icon_state = "1,2"

/turf/simulated/floor/fixed/os13/stonefloor/state_2_2
	icon_state = "2,2"

/turf/simulated/floor/fixed/os13/stonefloor/state_3_2
	icon_state = "3,2"

/turf/simulated/floor/fixed/os13/stonefloor/state_4_2
	icon_state = "4,2"

/turf/simulated/floor/fixed/os13/stonefloor/state_5_2
	icon_state = "5,2"

/turf/simulated/floor/fixed/os13/stonefloor/state_0_3
	icon_state = "0,3"

/turf/simulated/floor/fixed/os13/stonefloor/state_1_3
	icon_state = "1,3"

/turf/simulated/floor/fixed/os13/stonefloor/state_2_3
	icon_state = "2,3"

/turf/simulated/floor/fixed/os13/stonefloor/state_3_3
	icon_state = "3,3"

/turf/simulated/floor/fixed/os13/stonefloor/state_4_3
	icon_state = "4,3"

/turf/simulated/floor/fixed/os13/stonefloor/state_5_3
	icon_state = "5,3"

/turf/simulated/floor/fixed/os13/stonefloor/state_66
	icon_state = "66"

/turf/simulated/floor/fixed/os13/stonefloor/state_255
	icon_state = "255"

/turf/simulated/floor/fixed/os13/stonefloor/state_aborder1
	icon_state = "aborder1"

/turf/simulated/floor/fixed/os13/stonefloor/state_aborder2
	icon_state = "aborder2"

/turf/simulated/floor/fixed/os13/stonefloor/state_4_31
	icon_state = "4,31"

/turf/simulated/floor/fixed/os13/stonefloor/state_52
	icon_state = "52"

/turf/simulated/floor/fixed/os13/stonefloor/state_s
	icon_state = "s"

/turf/simulated/floor/fixed/os13/stonefloor/state_stonedamaged
	icon_state = "stonedamaged"

/turf/simulated/floor/fixed/os13/stonenew
	icon = 'icons/os13/turf/turf/stonenew.dmi'
	icon_state = "smallstone"

/turf/simulated/floor/fixed/os13/stonenew/state_smallstone
	icon_state = "smallstone"

/turf/simulated/floor/fixed/os13/stonewall
	icon = 'icons/os13/turf/turf/stonewall.dmi'
	icon_state = "stonefloor"

/turf/simulated/floor/fixed/os13/stonewall/state_stonefloor
	icon_state = "stonefloor"

/turf/simulated/floor/fixed/os13/stonewall/state_stonefloor3
	icon_state = "stonefloor3"

/turf/simulated/floor/fixed/os13/stonewall/state_stonefloor2
	icon_state = "stonefloor2"

/turf/simulated/floor/fixed/os13/stonewall/state_stonedamaged
	icon_state = "stonedamaged"

/turf/simulated/floor/fixed/os13/stonewall2
	icon = 'icons/os13/turf/turf/stonewall2.dmi'
	icon_state = "stonefloor"

/turf/simulated/floor/fixed/os13/stonewall2/state_stonefloor
	icon_state = "stonefloor"

/turf/simulated/floor/fixed/os13/stonewall2/state_stonefloor2
	icon_state = "stonefloor2"

/turf/simulated/floor/fixed/os13/stonewall2/state_stonedamaged
	icon_state = "stonedamaged"

/turf/simulated/floor/fixed/os13/thermal
	icon = 'icons/os13/turf/turf/thermal.dmi'
	icon_state = "thermal"

/turf/simulated/floor/fixed/os13/thermal/state_thermal
	icon_state = "thermal"

/turf/simulated/floor/fixed/os13/thermal/state_thermal2
	icon_state = "thermal2"

/turf/simulated/floor/fixed/os13/train
	icon = 'icons/os13/turf/turf/train.dmi'
	icon_state = "floor"

/turf/simulated/floor/fixed/os13/train/state_floor
	icon_state = "floor"
