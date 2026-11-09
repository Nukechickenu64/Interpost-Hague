/datum/event/meteor_wave
	startWhen		= 30	// About one minute early warning
	endWhen 		= 60	// Adjusted automatically in tick()
	var/alarmWhen   = 30
	var/next_meteor = 40
	var/waves = 1
	var/start_side
	var/next_meteor_lower = 10
	var/next_meteor_upper = 20


/datum/event/meteor_wave/setup()
	waves = 0
	for(var/n in 1 to severity)
		waves += rand(20,35)

	var/datum/event_meta/space_hazard/hazard = event_meta
	start_side = (istype(hazard) && hazard.approach_dir) ? hazard.approach_dir : pick(GLOB.cardinal)
	endWhen = worst_case_end()

/datum/event/meteor_wave/announce()
	// OS13 parity: proximity countdown to first impact (marshal video 32:45).
	var/seconds_to_impact = max(0, round((next_meteor - activeFor) * 2))
	if(severity == EVENT_LEVEL_MAJOR)
		station_alert_radio("DANGER! Proximity alert! [replacetext(GLOB.using_map.meteor_detected_message, "%STATION_NAME%", station_name())] Impact from the [dir2text(start_side)] in [seconds_to_impact]s!", GLOB.using_map.meteor_detected_sound)
	else
		station_alert_radio("DANGER! Proximity alert! The [station_name()] is entering a meteor shower. Impact from the [dir2text(start_side)] in [seconds_to_impact]s!")

/datum/event/meteor_wave/tick()
	// Begin sending the alarm signals to shield diffusers so the field is already regenerated (if it exists) by the time actual meteors start flying around.
	if(alarmWhen < activeFor)
		for(var/obj/machinery/shield_diffuser/SD in SSmachines.machinery)
			if(isStationLevel(SD.z))
				SD.meteor_alarm(10)

	if(waves && activeFor >= next_meteor)
		send_wave()

/datum/event/meteor_wave/proc/worst_case_end()
	return activeFor + ((30 / severity) * waves) + 30

/datum/event/meteor_wave/proc/send_wave()
	spawn() spawn_meteors(get_wave_size(), get_meteors(), start_side)
	next_meteor += rand(next_meteor_lower, next_meteor_upper) / severity
	waves--
	endWhen = worst_case_end()

/datum/event/meteor_wave/proc/get_wave_size()
	return severity * rand(2,4)

/datum/event/meteor_wave/end()
	station_alert_radio("The [station_name()] has cleared the meteor [severity == EVENT_LEVEL_MAJOR ? "storm" : "shower"].")

/datum/event/meteor_wave/proc/get_meteors()
	switch(severity)
		if(EVENT_LEVEL_MAJOR)
			return meteors_major
		if(EVENT_LEVEL_MODERATE)
			return meteors_moderate
		else
			return meteors_minor

/var/list/meteors_minor = list(
	/obj/effect/meteor/medium     = 120,
	/obj/effect/meteor/dust       = 30,
	/obj/effect/meteor/irradiated = 30,
	/obj/effect/meteor/big        = 80,
	/obj/effect/meteor/flaming    = 10,
	/obj/effect/meteor/golden     = 10,
	/obj/effect/meteor/silver     = 10,
)

/var/list/meteors_moderate = list(
	/obj/effect/meteor/medium     = 120,
	/obj/effect/meteor/big        = 80,
	/obj/effect/meteor/dust       = 30,
	/obj/effect/meteor/irradiated = 30,
	/obj/effect/meteor/flaming    = 10,
	/obj/effect/meteor/golden     = 10,
	/obj/effect/meteor/silver     = 10,
	/obj/effect/meteor/emp        = 10,
)

/var/list/meteors_major = list(
	/obj/effect/meteor/medium     = 120,
	/obj/effect/meteor/big        = 80,
	/obj/effect/meteor/dust       = 30,
	/obj/effect/meteor/irradiated = 30,
	/obj/effect/meteor/emp        = 30,
	/obj/effect/meteor/flaming    = 10,
	/obj/effect/meteor/golden     = 10,
	/obj/effect/meteor/silver     = 10,
	/obj/effect/meteor/tunguska   = 1,
)

/datum/event/meteor_wave/overmap
	next_meteor_lower = 5
	next_meteor_upper = 10
	next_meteor = 0
	var/obj/effect/overmap/ship/victim

/datum/event/meteor_wave/overmap/Destroy()
	victim = null
	. = ..()

/datum/event/meteor_wave/overmap/tick()
	if(victim && !victim.is_still()) //Meteors mostly fly in your face
		start_side = prob(90) ? victim.fore_dir : pick(GLOB.cardinal)
	else //Unless you're standing
		start_side = pick(GLOB.cardinal)
	..()

/datum/event/meteor_wave/overmap/get_wave_size()
	. = ..()
	if(!victim)
		return
	if(victim.is_still()) //Standing still means less shit flies your way
		. = round(. * 0.25)
	if(victim.get_speed() < 0.3) //Slow and steady
		. = round(. * 0.6)
	if(victim.get_speed() > 3) //Sanic stahp
		. *= 2