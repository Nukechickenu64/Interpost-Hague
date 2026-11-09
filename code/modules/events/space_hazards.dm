// Meteor showers and space dust arrive on a schedule derived from the round's phi value instead of the random event rotation.
#define SPACE_HAZARD_METEOR "meteor"
#define SPACE_HAZARD_DUST "dust"

/datum/event_meta/space_hazard
	var/approach_dir

/datum/space_hazard_forecast
	var/list/next_arrival = list()
	var/list/next_dir = list()
	var/list/next_severity = list()
	var/list/arrival_count = list()
	var/last_world_time = 0

// Deterministic for a given phi, independent of the global RNG state.
/datum/space_hazard_forecast/proc/seeded_roll(kind, index, salt, low, high)
	var/hash = hex2num(copytext(md5("[SSticker.phi]:[kind]:[index]:[salt]"), 1, 7))
	return low + (hash % (high - low + 1))

/datum/space_hazard_forecast/proc/schedule(kind, from_time)
	var/index = arrival_count[kind] + 1
	var/interval
	if(kind == SPACE_HAZARD_METEOR)
		interval = seeded_roll(kind, index, "time", 30 * 60, 60 * 60)
		next_severity[kind] = seeded_roll(kind, index, "severity", 1, 4) == 4 ? EVENT_LEVEL_MAJOR : EVENT_LEVEL_MODERATE
	else
		interval = seeded_roll(kind, index, "time", 10 * 60, 25 * 60)
		next_severity[kind] = EVENT_LEVEL_MUNDANE
	next_arrival[kind] = from_time + interval SECONDS
	next_dir[kind] = GLOB.alldirs[seeded_roll(kind, index, "dir", 1, GLOB.alldirs.len)]

/datum/space_hazard_forecast/proc/process()
	if(!SSticker.phi)
		return
	if(!next_arrival.len)
		for(var/kind in list(SPACE_HAZARD_METEOR, SPACE_HAZARD_DUST))
			arrival_count[kind] = 0
			schedule(kind, world.time)
		last_world_time = world.time
		return
	for(var/kind in next_arrival)
		if(!config.allow_random_events)
			next_arrival[kind] += world.time - last_world_time
		else if(world.time >= next_arrival[kind])
			launch(kind)
	last_world_time = world.time

/datum/space_hazard_forecast/proc/launch(kind)
	var/severity = next_severity[kind]
	var/datum/event_meta/space_hazard/EM
	if(kind == SPACE_HAZARD_METEOR)
		EM = new(severity, severity == EVENT_LEVEL_MAJOR ? "Meteor Storm" : "Meteor Shower", /datum/event/meteor_wave, 0, null, 0, 0, 0, 0)
	else
		EM = new(severity, "Space Dust", /datum/event/dust, 0, null, 0, 0, 0, 0)
	EM.approach_dir = next_dir[kind]
	new EM.event_type(EM)
	log_debug("Space hazard '[EM.name]' arrived from the [dir2text(EM.approach_dir)] (phi [SSticker.phi]).")
	arrival_count[kind]++
	schedule(kind, world.time)

/datum/space_hazard_forecast/proc/hazard_label(kind)
	if(kind == SPACE_HAZARD_METEOR)
		return next_severity[kind] == EVENT_LEVEL_MAJOR ? "Meteor storm" : "Meteor shower"
	return "Space dust belt"

/datum/space_hazard_forecast/proc/radar_report()
	. = list()
	if(!next_arrival.len)
		. += "Long-range sweep calibrating. No contacts plotted."
		return
	if(!config.allow_random_events)
		. += "Long-range tracking suspended. Contacts are holding position."
	for(var/kind in next_arrival)
		var/eta = max(0, next_arrival[kind] - world.time)
		var/minutes = round(eta / (1 MINUTE))
		var/seconds = round((eta - minutes MINUTES) / (1 SECOND))
		. += "[hazard_label(kind)]: bearing [uppertext(dir2text(next_dir[kind]))], arrival [duration2stationtime(eta)] (T-[minutes]m [seconds]s)."

#undef SPACE_HAZARD_METEOR
#undef SPACE_HAZARD_DUST
