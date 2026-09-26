#define ASSIGNMENT_ANY "Any"
#define ASSIGNMENT_AI "AI"
#define ASSIGNMENT_CYBORG "Cyborg"
#define ASSIGNMENT_ENGINEER "Engineer"
#define ASSIGNMENT_GARDENER "Gardener"
#define ASSIGNMENT_JANITOR "Janitor"
#define ASSIGNMENT_MEDICAL "Medical"
#define ASSIGNMENT_SCIENTIST "Scientist"
#define ASSIGNMENT_SECURITY "Security"

// Positional mapping by severity (1=Mundane,2=Moderate,3=Major)
var/global/list/severity_to_string = list("Mundane", "Moderate", "Major")

/datum/event_container
	var/severity = -1
	var/delayed = 0
	var/delay_modifier = 1
	var/next_event_time = 0
	var/list/available_events
	var/list/last_event_time = list()
	var/datum/event_meta/next_event = null

	var/last_world_time = 0

/datum/event_container/proc/process()
	if(!next_event_time)
		set_event_delay()

	if(delayed || !config.allow_random_events)
		next_event_time += (world.time - last_world_time)
	else if(world.time > next_event_time)
		start_event()

	last_world_time = world.time

/datum/event_container/proc/start_event()
	if(!next_event)	// If non-one has explicitly set an event, randomly pick one
		next_event = acquire_event()

	// Has an event been acquired?
	if(next_event)
		// Set when the event of this type was last fired, and prepare the next event start
		last_event_time[next_event] = world.time
		set_event_delay()
		next_event.enabled = !next_event.one_shot	// This event will no longer be available in the random rotation if one shot

		new next_event.event_type(next_event)	// Events are added and removed from the processing queue in their New/kill procs

		log_debug("Starting event '[next_event.name]' of severity [severity_to_string[severity]].")
		next_event = null						// When set to null, a random event will be selected next time
	else
		// If not, wait for one minute, instead of one tick, before checking again.
		next_event_time += (60 * 10)


/datum/event_container/proc/acquire_event()
	if(available_events.len == 0)
		return
	var/active_with_role = number_active_with_role()

	var/list/possible_events = list()
	for(var/datum/event_meta/EM in available_events)
		var/event_weight = get_weight(EM, active_with_role)
		if(event_weight)
			possible_events[EM] = event_weight

	if(possible_events.len == 0)
		return null

	// Select an event and remove it from the pool of available events
	var/picked_event = pickweight(possible_events)
	available_events -= picked_event
	return picked_event

/datum/event_container/proc/get_weight(var/datum/event_meta/EM, var/list/active_with_role)
	if(!EM.enabled)
		return 0

	var/weight = EM.get_weight(active_with_role)
	var/last_time = last_event_time[EM]
	if(last_time)
		var/time_passed = world.time - last_time
		var/weight_modifier = max(0, round((config.expected_round_length - time_passed) / 300))
		weight = weight - weight_modifier

	return weight

/datum/event_container/proc/set_event_delay()
	// If the next event time has not yet been set and we have a custom first time start
	if(next_event_time == 0 && config.event_first_run[severity])
		var/lower = config.event_first_run[severity]["lower"]
		var/upper = config.event_first_run[severity]["upper"]
		var/event_delay = rand(lower, upper)
		next_event_time = world.time + event_delay
	// Otherwise, follow the standard setup process
	else
		var/playercount_modifier = 1
		switch(GLOB.player_list.len)
			if(0 to 10)
				playercount_modifier = 1.2
			if(11 to 15)
				playercount_modifier = 1.1
			if(16 to 25)
				playercount_modifier = 1
			if(26 to 35)
				playercount_modifier = 0.9
			if(36 to 100000)
				playercount_modifier = 0.8
		playercount_modifier = playercount_modifier * delay_modifier

		var/event_delay = rand(config.event_delay_lower[severity], config.event_delay_upper[severity]) * playercount_modifier
		next_event_time = world.time + event_delay

	log_debug("Next event of severity [severity_to_string[severity]] in [(next_event_time - world.time)/600] minutes.")

/datum/event_container/proc/SelectEvent()
	var/datum/event_meta/EM = input("Select an event to queue up.", "Event Selection", null) as null|anything in available_events
	if(!EM)
		return
	if(next_event)
		available_events += next_event
	available_events -= EM
	next_event = EM
	return EM

/datum/event_container/mundane
	severity = EVENT_LEVEL_MUNDANE
	available_events = list(
		// Severity level, event name, even type, base weight, role weights, one shot, min weight, max weight. Last two only used if set and non-zero
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Nothing",			/datum/event/nothing,			100),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "APC Damage",		/datum/event/apc_damage,		20, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Computer Damage",		/datum/event/computer_damage,		20, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Computer Update",		/datum/event/computer_update,		40),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Brand Intelligence",/datum/event/brand_intelligence,10, 	list(ASSIGNMENT_JANITOR = 10),	1),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Camera Damage",		/datum/event/camera_damage,		20, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Economic News",		/datum/event/economic_event,	300),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Lost Carp",			/datum/event/carp_migration, 	20, 	list(ASSIGNMENT_SECURITY = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Money Hacker",		/datum/event/money_hacker, 		0, 		list(ASSIGNMENT_ANY = 4), 1, 10, 25),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Money Lotto",		/datum/event/money_lotto, 		0, 		list(ASSIGNMENT_ANY = 1), 1, 5, 15),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Mundane News", 		/datum/event/mundane_news, 		300),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Shipping Error",	/datum/event/shipping_error	, 	30, 	list(ASSIGNMENT_ANY = 2), 0),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Space Dust",		/datum/event/dust	, 			30, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Sensor Suit Jamming",/datum/event/sensor_suit_jamming,50,	list(ASSIGNMENT_MEDICAL = 20, ASSIGNMENT_AI = 20), 1),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Trivial News",		/datum/event/trivial_news, 		400),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Vermin Infestation",/datum/event/infestation, 		100,	list(ASSIGNMENT_JANITOR = 100)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Toilet Clog",		/datum/event/toilet_clog,		50, 	list(ASSIGNMENT_JANITOR = 20)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Wallrot",			/datum/event/wallrot, 			0,		list(ASSIGNMENT_ENGINEER = 30, ASSIGNMENT_GARDENER = 50)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Electrical Storm",	/datum/event/electrical_storm, 	20,		list(ASSIGNMENT_ENGINEER = 20, ASSIGNMENT_JANITOR = 100)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Space Cold Outbreak",/datum/event/space_cold,		100,	list(ASSIGNMENT_MEDICAL = 20)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Coffee Shortage", /datum/event/catalogue/mundane/coffee_shortage, 35, list(ASSIGNMENT_ANY = 2)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Maintenance Lull", /datum/event/catalogue/mundane/maintenance_lull, 30, list(ASSIGNMENT_ENGINEER = 5)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Repairs Audit", /datum/event/catalogue/mundane/repairs_audit, 25, list(ASSIGNMENT_ENGINEER = 5)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Cargo Relabel", /datum/event/catalogue/mundane/cargo_relabel, 30, list(ASSIGNMENT_ANY = 2)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Plant Growth", /datum/event/catalogue/mundane/plant_growth, 30, list(ASSIGNMENT_GARDENER = 15)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Waste Review", /datum/event/catalogue/mundane/waste_review, 30, list(ASSIGNMENT_JANITOR = 15)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Quiet Hours", /datum/event/catalogue/mundane/quiet_hours, 25, list(ASSIGNMENT_AI = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Visitor Poll", /datum/event/catalogue/mundane/visitor_poll, 35),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Lighting Calibration", /datum/event/catalogue/mundane/lighting_calibration, 25, list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Temperature Survey", /datum/event/catalogue/mundane/temperature_survey, 30, list(ASSIGNMENT_ENGINEER = 5, ASSIGNMENT_MEDICAL = 5)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Meal Rotation", /datum/event/catalogue/mundane/meal_rotation, 35),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Parcel Mixup", /datum/event/catalogue/mundane/parcel_mixup, 30),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Air Sample", /datum/event/catalogue/mundane/air_sample, 25, list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Film Night", /datum/event/catalogue/mundane/film_night, 20),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Clock Drift", /datum/event/catalogue/mundane/clock_drift, 25, list(ASSIGNMENT_AI = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Market Update", /datum/event/catalogue/mundane/market_update, 35),
	)

/datum/event_container/moderate
	severity = EVENT_LEVEL_MODERATE
	available_events = list(
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Nothing",					/datum/event/nothing,					1230),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Appendicitis", 			/datum/event/spontaneous_appendicitis, 	0,		list(ASSIGNMENT_MEDICAL = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Carp School",				/datum/event/carp_migration,			100, 	list(ASSIGNMENT_ENGINEER = 10, ASSIGNMENT_SECURITY = 20), 1),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Communication Blackout",	/datum/event/communications_blackout,	100,	list(ASSIGNMENT_AI = 100, ASSIGNMENT_ENGINEER = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Electrical Storm",			/datum/event/electrical_storm, 			10,		list(ASSIGNMENT_ENGINEER = 15, ASSIGNMENT_JANITOR = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Gravity Failure",			/datum/event/gravity,	 				75,		list(ASSIGNMENT_ENGINEER = 25)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Grid Check",				/datum/event/grid_check, 				200,	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Ion Storm",				/datum/event/ionstorm, 					0,		list(ASSIGNMENT_AI = 50, ASSIGNMENT_CYBORG = 50, ASSIGNMENT_ENGINEER = 15, ASSIGNMENT_SCIENTIST = 5)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Meteor Shower",			/datum/event/meteor_wave,				0,		list(ASSIGNMENT_ENGINEER = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Prison Break",				/datum/event/prison_break,				0,		list(ASSIGNMENT_SECURITY = 100)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Radiation Storm",			/datum/event/radiation_storm, 			0,		list(ASSIGNMENT_MEDICAL = 50), 1),
		new /datum/event_meta/extended_penalty(EVENT_LEVEL_MODERATE, "Random Antagonist",/datum/event/random_antag,		2.5,	list(ASSIGNMENT_SECURITY = 1), 1, 0, 5),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Rogue Drones",				/datum/event/rogue_drone, 				20,		list(ASSIGNMENT_SECURITY = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Sensor Suit Jamming",		/datum/event/sensor_suit_jamming,		10,		list(ASSIGNMENT_MEDICAL = 20, ASSIGNMENT_AI = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Solar Storm",				/datum/event/solar_storm, 				10,		list(ASSIGNMENT_ENGINEER = 20, ASSIGNMENT_SECURITY = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Space Dust",				/datum/event/dust	, 					30, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Toilet Flooding",			/datum/event/toilet_clog/flood,			50, 	list(ASSIGNMENT_JANITOR = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Spider Infestation",		/datum/event/spider_infestation, 		25,		list(ASSIGNMENT_SECURITY = 30), 1),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Virology Breach",			/datum/event/prison_break/virology,		0,		list(ASSIGNMENT_MEDICAL = 100)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Xenobiology Breach",		/datum/event/prison_break/xenobiology,	0,		list(ASSIGNMENT_SCIENCE = 100)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Power Conservation", /datum/event/catalogue/moderate/power_conservation, 20, list(ASSIGNMENT_ENGINEER = 15)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Communications Echo", /datum/event/catalogue/moderate/comms_echo, 20, list(ASSIGNMENT_AI = 20, ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Cargo Inspection", /datum/event/catalogue/moderate/cargo_inspection, 25),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Medical Inventory", /datum/event/catalogue/moderate/medical_inventory, 20, list(ASSIGNMENT_MEDICAL = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Atmospheric Survey", /datum/event/catalogue/moderate/atmospheric_survey, 20, list(ASSIGNMENT_ENGINEER = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Security Drill", /datum/event/catalogue/moderate/security_drill, 25, list(ASSIGNMENT_SECURITY = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Robotics Fault", /datum/event/catalogue/moderate/robotics_fault, 20, list(ASSIGNMENT_ENGINEER = 10, ASSIGNMENT_CYBORG = 15)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Research Anomaly", /datum/event/catalogue/moderate/research_anomaly, 20, list(ASSIGNMENT_SCIENTIST = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Structural Stress", /datum/event/catalogue/moderate/structural_stress, 20, list(ASSIGNMENT_ENGINEER = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Emergency Broadcast", /datum/event/catalogue/moderate/emergency_broadcast, 25, list(ASSIGNMENT_AI = 15)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Food Contamination", /datum/event/catalogue/moderate/food_contamination, 20, list(ASSIGNMENT_MEDICAL = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Contract Dispute", /datum/event/catalogue/moderate/contract_dispute, 30),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Medical Triage", /datum/event/catalogue/moderate/medical_triage, 20, list(ASSIGNMENT_MEDICAL = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Navigation Drift", /datum/event/catalogue/moderate/navigation_drift, 20, list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Thermal Spike", /datum/event/catalogue/moderate/thermal_spike, 20, list(ASSIGNMENT_ENGINEER = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Data Corruption", /datum/event/catalogue/moderate/data_corruption, 20, list(ASSIGNMENT_AI = 20, ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Evacuation Review", /datum/event/catalogue/moderate/evacuation_review, 25, list(ASSIGNMENT_SECURITY = 10)),
	)

/datum/event_container/major
	severity = EVENT_LEVEL_MAJOR
	available_events = list(
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Nothing",				/datum/event/nothing,			1320),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Blob",				/datum/event/blob, 				0,	list(ASSIGNMENT_ENGINEER = 40), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Carp Migration",		/datum/event/carp_migration,	0,	list(ASSIGNMENT_SECURITY =  5), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Containment Breach",	/datum/event/prison_break/station,0,list(ASSIGNMENT_ANY = 5)),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Meteor Wave",			/datum/event/meteor_wave,		0,	list(ASSIGNMENT_ENGINEER = 10),	1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Space Vines",			/datum/event/spacevine, 		0,	list(ASSIGNMENT_ENGINEER = 15), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Electrical Storm",	/datum/event/electrical_storm, 	0,	list(ASSIGNMENT_ENGINEER = 10, ASSIGNMENT_JANITOR = 5)),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Unknown Transmission", /datum/event/catalogue/major/unknown_transmission, 0, list(ASSIGNMENT_AI = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Containment Protocol", /datum/event/catalogue/major/containment_protocol, 0, list(ASSIGNMENT_SECURITY = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Critical Power Review", /datum/event/catalogue/major/critical_power_review, 0, list(ASSIGNMENT_ENGINEER = 15), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Hostile Weather", /datum/event/catalogue/major/hostile_weather, 0, list(ASSIGNMENT_ENGINEER = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "False Evacuation", /datum/event/catalogue/major/false_evacuation, 0, list(ASSIGNMENT_SECURITY = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Black Box", /datum/event/catalogue/major/black_box, 0, list(ASSIGNMENT_SCIENTIST = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Automated Lockdown", /datum/event/catalogue/major/automated_lockdown, 0, list(ASSIGNMENT_SECURITY = 15), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Deep Space Signal", /datum/event/catalogue/major/deep_space_signal, 0, list(ASSIGNMENT_AI = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Structural Emergency", /datum/event/catalogue/major/structural_emergency, 0, list(ASSIGNMENT_ENGINEER = 15), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Unknown Cargo", /datum/event/catalogue/major/unknown_cargo, 0, list(ASSIGNMENT_ANY = 5), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Command Failure", /datum/event/catalogue/major/command_failure, 0, list(ASSIGNMENT_AI = 15), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Atmospheric Emergency", /datum/event/catalogue/major/atmospheric_emergency, 0, list(ASSIGNMENT_ENGINEER = 15), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Crew Manifest", /datum/event/catalogue/major/crew_manifest, 0, list(ASSIGNMENT_SECURITY = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Last Warning", /datum/event/catalogue/major/last_warning, 0, list(ASSIGNMENT_ANY = 5), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Operations Halt", /datum/event/catalogue/major/operations_halt, 0, list(ASSIGNMENT_ANY = 5), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Blackout Forecast", /datum/event/catalogue/major/blackout_forecast, 0, list(ASSIGNMENT_ENGINEER = 10, ASSIGNMENT_AI = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Arrival Window", /datum/event/catalogue/major/arrival_window, 0, list(ASSIGNMENT_ENGINEER = 10), 1),
	)


#undef ASSIGNMENT_ANY
#undef ASSIGNMENT_AI
#undef ASSIGNMENT_CYBORG
#undef ASSIGNMENT_ENGINEER
#undef ASSIGNMENT_GARDENER
#undef ASSIGNMENT_JANITOR
#undef ASSIGNMENT_MEDICAL
#undef ASSIGNMENT_SCIENTIST
#undef ASSIGNMENT_SECURITY
