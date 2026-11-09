/*
Space dust
Commonish random event that causes small clumps of "space dust" to hit the station at high speeds.
The "dust" will damage the hull of the station causin minor hull breaches.
*/

/datum/event/dust
	startWhen	= 10
	endWhen		= 30
	var/min_delay = 30
	var/last_wave
	var/approach_dir

/datum/event/dust/setup()
	var/datum/event_meta/space_hazard/hazard = event_meta
	approach_dir = (istype(hazard) && hazard.approach_dir) ? hazard.approach_dir : pick(GLOB.cardinal)

/datum/event/dust/announce()
	station_alert_radio("The [station_name()] is now passing through a belt of space dust approaching from the [dir2text(approach_dir)].")

/datum/event/dust/tick()
	if(world.time > last_wave + min_delay && prob(10))
		dust_swarm(severity, approach_dir)
		last_wave = world.time

/datum/event/dust/end()
	station_alert_radio("The [station_name()] has now passed through the belt of space dust.")

/proc/dust_swarm(var/strength = EVENT_LEVEL_MUNDANE, var/start_dir = pick(GLOB.cardinal))
	if(!GLOB.using_map || !GLOB.using_map.station_levels || !GLOB.using_map.station_levels.len)
		return
	if(world.maxx <= TRANSITIONEDGE * 4 || world.maxy <= TRANSITIONEDGE * 4)
		return

	var/numbers = rand(strength * 10, strength * 15)

	var/edge = start_dir
	if(!(edge in GLOB.cardinal))
		edge = prob(50) ? (start_dir & (NORTH|SOUTH)) : (start_dir & (EAST|WEST))
	var/turf/startloc
	var/turf/targloc
	var/randomz = pick(GLOB.using_map.station_levels)
	var/randomx = rand(1+TRANSITIONEDGE*2, world.maxx-TRANSITIONEDGE*2)
	var/randomy = rand(1+TRANSITIONEDGE*2, world.maxy-TRANSITIONEDGE*2)
	switch(edge)
		if(NORTH)
			startloc = locate(randomx, world.maxy - TRANSITIONEDGE, randomz)
			targloc = locate(world.maxx - randomx,  1 + TRANSITIONEDGE, randomz)
		if(SOUTH)
			startloc = locate(randomx, 1 + TRANSITIONEDGE, randomz)
			targloc = locate(world.maxx - randomx, world.maxy - TRANSITIONEDGE, randomz)
		if(EAST)
			startloc = locate(world.maxx - TRANSITIONEDGE, randomy, randomz)
			targloc = locate(1 + TRANSITIONEDGE, world.maxy - randomy, randomz)
		if(WEST)
			startloc = locate(1 + TRANSITIONEDGE, randomy, randomz)
			targloc = locate(world.maxx - TRANSITIONEDGE, world.maxy - randomy, randomz)
	if(startloc && edge != start_dir)
		targloc = spaceDebrisFinishLoc(start_dir, randomz, startloc)
	if(!startloc || !targloc)
		return
	var/list/starters = getcircle(startloc, 3)
	starters += startloc
	if(!starters.len)
		return

	var/rocks_per_tile = round(numbers/starters.len)
	for(var/turf/T in starters)
		for(var/i = 1 to rocks_per_tile)
			var/obj/item/projectile/bullet/rock/R = new(T)
			R.launch(targloc, null, startloc.x - T.x, startloc.y - T.y)
