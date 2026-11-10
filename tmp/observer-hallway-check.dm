/world
	mob = /mob/observer/ghost/hallway_check

var/global/observer_hallway_started = FALSE

/hook/startup/proc/observer_hallway_check()
	world.log = file("tmp/observer-hallway-check.log")
	world.name = "Observer Hallway Motion"
	return TRUE

/mob/observer/ghost/hallway_check/Login()
	while(!shadowcasting_controller.initialized)
		sleep(5)
	forceMove(locate(125, 129, 2))
	. = ..()
	SSticker.can_fire = FALSE
	spawn(40)
		if(client && !observer_hallway_started)
			observer_hallway_started = TRUE
			run_hallway_check()

/mob/observer/ghost/hallway_check/proc/capture(label)
	if(!client)
		return
	world.log << "OBS_HALL [label] [x],[y],[z] time=[world.time] sight=[sight] darkness=[seedarkness]"
	winset(src, null, "command=\".screenshot auto\"")

/mob/observer/ghost/hallway_check/proc/run_hallway_check()
	winset(src, null, "mainwindow.title='Observer Hallway Motion'")
	for(var/obj/machinery/light/L in range(16, src))
		var/area/A = get_area(L)
		A.requires_power = FALSE
		L.stat &= ~NOPOWER
		L.on = TRUE
		if(L.lightbulb) L.lightbulb.status = LIGHT_OK
		L.update_icon(0)
	SSlighting.fire(FALSE, TRUE)
	SSlighting.can_fire = FALSE
	clear_fullscreen("deathscreen", 0)
	client.view = "21x15"
	world.log << "OBS_HALL READY"
	for(var/mode in list("normal", "no-steps", "normal-repeat"))
		if(!client)
			return
		animate_movement = mode == "no-steps" ? NO_STEPS : initial(animate_movement)
		forceMove(locate(125, 130, 2))
		sleep(15)
		capture("[mode]-start")
		for(var/direction in list(SOUTH, NORTH))
			for(var/i in 1 to 4)
				if(!client)
					return
				client.Move(get_step(src, direction), direction)
				sleep(world.tick_lag)
				capture("[mode]-[direction]-[i]-early")
				sleep(1.5)
				capture("[mode]-[direction]-[i]-late")
		sleep(10)
		capture("[mode]-settled")
	world.log << "OBS_HALL DONE"
