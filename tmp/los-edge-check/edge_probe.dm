#define LIGHTING_PLANE 15
/world
	name = "LOS Edge Final Check"
	view = "15x13"
	maxx = 15
	maxy = 13
	maxz = 1
	fps = 20
/turf
	icon = 'triangle.dmi'
	icon_state = "triangle"
/obj/screen
	mouse_opacity = 0
/obj/screen/light_master
	appearance_flags = PLANE_MASTER
	plane = LIGHTING_PLANE
	blend_mode = BLEND_MULTIPLY
	screen_loc = "CENTER,CENTER"
	render_target = "light"
/obj/screen/light_back
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER + 1
	screen_loc = "CENTER"
/obj/screen/output
	screen_loc = "CENTER"
	plane = 3
	blend_mode = BLEND_OVERLAY
	layer = BACKGROUND_LAYER + 1
/obj/screen/display_master
	screen_loc = "CENTER,CENTER"
	plane = 3
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_MULTIPLY
/obj/screen/guard
	plane = LIGHTING_PLANE
	screen_loc = "CENTER"
	alpha = 0
/obj/sample
	plane = LIGHTING_PLANE
	layer = TOPDOWN_LAYER + 2
	mouse_opacity = 0
/mob
	invisibility = 101
/mob/Login()
	..()
	var/icon/tile = icon('triangle.dmi', "triangle")
	tile.Scale(32,32)
	tile.DrawBox("#ffffff",1,1,32,32)
	for(var/turf/T in world)
		T.icon = tile
		T.color = "#808080"
		if(T.x >= 4 && T.x <= 10 && T.y >= 4 && T.y <= 10)
			var/obj/sample/S = new(T)
			S.icon = tile
			S.color = T.y >= 9 ? "#60b0ff" : "#000000"
	var/obj/screen/light_master/M = new
	var/obj/screen/output/D = new
	M.render_target = "*light"
	M.blend_mode = BLEND_OVERLAY
	var/obj/screen/display_master/P = new
	D.icon = tile
	D.color = "#000000"
	D.transform = matrix(64,0,0,0,64,0)
	client.screen.Add(M,D,P)
	var/bloom = filter(type = "bloom", threshold = "#808080", size = 4, offset = 0, alpha = 110)
	var/softness = filter(type = "blur", size = 2)
	var/input = filter(type = "layer", render_source = "*light")
	var/coverage = filter(type = "alpha", render_source = "*light")
	var/obj/screen/guard/G = new
	G.icon = tile
	client.screen += G
	for(var/phase in list("legacy-bloom", "legacy-blur", "fixed", "empty"))
		D.color = findtext(phase, "legacy") ? "#ffffff" : "#000000"
		switch(phase)
			if("legacy-bloom")
				P.filters = list(input, softness, bloom)
			if("legacy-blur")
				P.filters = list(input, softness)
			else
				P.filters = list(input, softness, bloom, coverage)
		if(phase == "empty")
			for(var/obj/sample/S in world)
				del(S)
		sleep(35)
		world.log << "CAPTURE [phase]"
		winset(src, null, "command=\".screenshot auto\"")
	sleep(15)
	world.log << "LOS_EDGE_PROBE_COMPLETE"
	shutdown()




