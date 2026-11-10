/world
	mob = /mob/living/carbon/human/terrain_flash_probe

/mob/living/carbon/human/terrain_flash_probe/Login()
	while(!shadowcasting_controller.initialized)
		sleep(5)
	var/x0 = text2num(world.params["x"]) || 125
	var/y0 = text2num(world.params["y"]) || 129
	var/z0 = text2num(world.params["z"]) || 2
	forceMove(locate(x0, y0, z0))
	. = ..()
	SSticker.can_fire = FALSE
	spawn(20)
		run_terrain_flash_probe()

/mob/living/carbon/human/terrain_flash_probe/proc/run_terrain_flash_probe()
	if(!client) return
	winset(src, "mainwindow", "title=Terrain-glide-probe")
	for(var/obj/screen/S in client.screen)
		if(istype(S, /obj/screen/fullscreen) || S == film_grain || (S.icon_state in list("7 moderate", "1 light", "scanlines")))
			client.screen -= S
	for(var/obj/machinery/light/L in range(16, src))
		var/area/A = get_area(L)
		A.requires_power = FALSE
		L.stat &= ~NOPOWER
		L.on = TRUE
		if(L.lightbulb)
			L.lightbulb.status = LIGHT_OK
		L.update_icon(0)
	SSlighting.fire(FALSE, TRUE)
	var/turf/start = get_turf(src)
	var/obj/screen/plane_master/world_terrain/M = locate() in client.screen
	var/obj/screen/world_terrain_display/D = locate() in client.screen
	set_glide_size(2)
	client.glide_size = glide_size
	set_see_in_dark(8)
	set_see_invisible(INVISIBILITY_LIGHTING)
	world.log << "TERRAIN_PROBE ready [start.x],[start.y],[start.z] sight=[sight] glide=[glide_size]"
	for(var/phase in list("relay", "direct", "relay-repeat"))
		if(!client) return
		if(phase == "direct")
			M.render_target = null
			client.screen -= D
		else
			M.render_target = "*world_terrain"
			client.screen |= D
		forceMove(start)
		sleep(18)
		var/direction = text2num(world.params["dir"]) || SOUTH
		for(var/i in 1 to 4)
			terrain_probe_shot(phase, "rest", i)
			var/turf/from = get_turf(src)
			var/turf/target = get_step(from, direction)
			Move(target, direction)
			world.log << "TERRAIN_PROBE move [from.x],[from.y],[from.z] -> [x],[y],[z]"
			for(var/j in 1 to 5)
				sleep(2)
				terrain_probe_shot(phase, "glide-[j]", i)
			sleep(16)
			direction = turn(direction, 180)
	world.log << "TERRAIN_PROBE complete"

/mob/living/carbon/human/terrain_flash_probe/proc/terrain_probe_shot(phase, label, i)
	world.log << "TERRAIN_PROBE shot [phase] [i] [label] [time2text(world.realtime, "hh:mm:ss")]"
	winset(src, null, "command=\".screenshot auto\"")

/hook/startup/proc/terrain_flash_probe_log()
	world.log = file("tmp/terrain-flash-probe.log")
	return TRUE
