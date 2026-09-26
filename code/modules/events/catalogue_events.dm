/datum/event/catalogue
	startWhen = 0
	announceWhen = 0
	endWhen = 5
	var/announcement = ""
	var/announcement_title = "Station Bulletin"
	var/mechanic_mode = ""
	var/maintenance_access_changed = FALSE
	var/gravity_changed = FALSE
	var/list/affected_apcs = list()
	var/list/affected_airlocks = list()
	var/list/spawned_drones = list()

/datum/event/catalogue/start()
	switch(mechanic_mode)
		if("computer")
			commence_updates(severity)
		if("power")
			for(var/obj/machinery/power/apc/A in SSmachines.machinery)
				if(affected_apcs.len >= max(1, severity * 2))
					break
				var/turf/T = get_turf(A)
				if(!T || !(T.z in GLOB.using_map.player_levels) || A.is_critical || A.emagged)
					continue
				A.overload_lighting(30 + (severity * 20))
				A.energy_fail()
				affected_apcs += A
		if("comms")
			communications_blackout(1)
		if("access")
			make_maint_all_access()
			maintenance_access_changed = TRUE
		if("radiation")
			make_maint_all_access()
			maintenance_access_changed = TRUE
		if("gravity")
			gravity_is_on = 0
			gravity_changed = TRUE
			for(var/area/A in world)
				if(A.z in GLOB.using_map.station_levels)
					A.gravitychange(gravity_is_on)
		if("doors")
			for(var/obj/machinery/door/airlock/A in SSmachines.machinery)
				if(affected_airlocks.len >= max(2, severity * 3))
					break
				var/turf/T = get_turf(A)
				if(!T || !(T.z in GLOB.using_map.player_levels))
					continue
				A.prison_open()
				affected_airlocks += A
		if("drones")
			var/list/possible_spawns = list()
			for(var/obj/effect/landmark/L in landmarks_list)
				if(L.name == "carpspawn")
					possible_spawns += L
			if(possible_spawns.len)
				for(var/i = 1 to max(1, severity * 2))
					var/mob/living/simple_animal/hostile/retaliate/malf_drone/D = new(get_turf(pick(possible_spawns)))
					spawned_drones += D

/datum/event/catalogue/tick()
	if(mechanic_mode == "radiation" && !(activeFor % 5))
		for(var/z in GLOB.using_map.station_levels)
			SSradiation.z_radiate(locate(1, 1, z), rand(15, 35), 1)

/datum/event/catalogue/announce()
	if(announcement)
		command_announcement.Announce(announcement, announcement_title)

/datum/event/catalogue/end()
	if(maintenance_access_changed)
		revoke_maint_all_access()
		maintenance_access_changed = FALSE
	if(gravity_changed)
		gravity_is_on = 1
		for(var/area/A in world)
			if((A.z in GLOB.using_map.station_levels) && initial(A.has_gravity))
				A.gravitychange(gravity_is_on)
		gravity_changed = FALSE
	for(var/mob/living/simple_animal/hostile/retaliate/malf_drone/D in spawned_drones)
		if(D)
			D.z = GLOB.using_map.admin_levels[1]
			D.has_loot = 0
			qdel(D)
	spawned_drones.Cut()

/datum/event/catalogue/mundane
	mechanic_mode = "computer"

/datum/event/catalogue/moderate
	mechanic_mode = "power"

/datum/event/catalogue/major
	mechanic_mode = "comms"

/datum/event/catalogue/mundane/coffee_shortage
	mechanic_mode = "computer"
	announcement = "Supply control reports an unexpected shortage of coffee products. Rationing is not currently required."
	announcement_title = "Supply Advisory"

/datum/event/catalogue/mundane/maintenance_lull
	announcement = "Maintenance telemetry is unusually quiet. Engineering is advised to enjoy the silence while it lasts."
	announcement_title = "Maintenance Report"

/datum/event/catalogue/mundane/repairs_audit
	announcement = "A routine corporate audit of station repairs has begun. Please retain damaged parts for inspection."
	announcement_title = "Corporate Audit"

/datum/event/catalogue/mundane/cargo_relabel
	announcement = "Several cargo containers have received revised shipping labels. Verify manifests before opening sealed freight."
	announcement_title = "Cargo Notice"

/datum/event/catalogue/mundane/plant_growth
	announcement = "Hydroponics sensors report a brief period of accelerated plant growth. Gardeners should inspect their trays."
	announcement_title = "Botanical Notice"

/datum/event/catalogue/mundane/waste_review
	announcement = "Waste processing has entered a quality review cycle. Unusual disposal requests may require additional paperwork."
	announcement_title = "Sanitation Notice"

/datum/event/catalogue/mundane/quiet_hours
	announcement = "The station has been selected for a communications quiet-hours trial. Non-critical chatter may be delayed."
	announcement_title = "Communications Advisory"

/datum/event/catalogue/mundane/visitor_poll
	announcement = "An anonymous visitor satisfaction poll is now circulating through station terminals. Participation is voluntary."
	announcement_title = "Public Relations"

/datum/event/catalogue/mundane/lighting_calibration
	mechanic_mode = "power"
	announcement = "Lighting control has begun a calibration sweep. Minor changes in brightness may occur across the station."
	announcement_title = "Lighting Report"

/datum/event/catalogue/mundane/temperature_survey
	announcement = "Environmental control is conducting a temperature survey. Report any unusually warm or cold workspace."
	announcement_title = "Environmental Advisory"

/datum/event/catalogue/mundane/meal_rotation
	announcement = "The galley has changed the meal rotation ahead of schedule. Dietary substitutions may be available on request."
	announcement_title = "Galley Notice"

/datum/event/catalogue/mundane/parcel_mixup
	announcement = "A small number of personal parcels may have been routed to the wrong department. Check labels before claiming deliveries."
	announcement_title = "Logistics Notice"

/datum/event/catalogue/mundane/air_sample
	announcement = "Atmospherics has requested additional air samples from occupied areas. No hazard has been detected."
	announcement_title = "Atmospherics Report"

/datum/event/catalogue/mundane/film_night
	announcement = "The recreation committee has scheduled an impromptu film night. Seating is first come, first served."
	announcement_title = "Recreation Notice"

/datum/event/catalogue/mundane/clock_drift
	mechanic_mode = "computer"
	announcement = "Station clocks have developed a minor synchronization drift. Official time remains available through command terminals."
	announcement_title = "Timekeeping Advisory"

/datum/event/catalogue/mundane/market_update
	announcement = "The interstellar commodities market has shifted in favor of locally produced goods. Procurement may see revised prices."
	announcement_title = "Market Bulletin"

/datum/event/catalogue/moderate/power_conservation
	mechanic_mode = "power"
	announcement = "Power management has activated a conservation advisory. Non-essential equipment may be subject to temporary limits."
	announcement_title = "Power Advisory"

/datum/event/catalogue/moderate/comms_echo
	mechanic_mode = "comms"
	announcement = "Communications reports a repeating echo on several channels. Operators should confirm important orders by a second method."
	announcement_title = "Communications Warning"

/datum/event/catalogue/moderate/cargo_inspection
	announcement = "Cargo has been selected for an unscheduled inspection. Sealed freight must remain available to customs officers."
	announcement_title = "Cargo Warning"

/datum/event/catalogue/moderate/medical_inventory
	announcement = "Medical inventory software has flagged discrepancies in emergency supplies. Medical staff should verify stock manually."
	announcement_title = "Medical Warning"

/datum/event/catalogue/moderate/atmospheric_survey
	announcement = "Atmospherics has detected unstable readings in a remote section of the station. Engineering teams should investigate."
	announcement_title = "Atmospherics Warning"

/datum/event/catalogue/moderate/security_drill
	announcement = "Security has initiated a station-wide readiness drill. Personnel should follow departmental emergency procedures."
	announcement_title = "Security Bulletin"

/datum/event/catalogue/moderate/robotics_fault
	mechanic_mode = "drones"
	announcement = "Robotics telemetry has reported intermittent control faults. Cyborgs and maintenance units should use caution."
	announcement_title = "Robotics Warning"

/datum/event/catalogue/moderate/research_anomaly
	announcement = "Research instruments have recorded a result outside the expected confidence range. Science is advised to secure sensitive samples."
	announcement_title = "Research Warning"

/datum/event/catalogue/moderate/structural_stress
	mechanic_mode = "doors"
	announcement = "Structural monitors report increased stress along several maintenance corridors. Avoid unnecessary construction until reviewed."
	announcement_title = "Structural Warning"

/datum/event/catalogue/moderate/emergency_broadcast
	announcement = "An automated emergency broadcast has been detected on an unregistered frequency. Its source is currently unknown."
	announcement_title = "Signal Warning"

/datum/event/catalogue/moderate/food_contamination
	announcement = "Food safety systems have identified a possible contamination event. The galley is suspending service pending testing."
	announcement_title = "Food Safety Warning"

/datum/event/catalogue/moderate/contract_dispute
	announcement = "A contract dispute has placed several station services under temporary review. Department heads should confirm their current authority."
	announcement_title = "Administrative Warning"

/datum/event/catalogue/moderate/medical_triage
	announcement = "Medical triage protocols have been elevated due to an incoming advisory. Prepare treatment space and emergency supplies."
	announcement_title = "Medical Advisory"

/datum/event/catalogue/moderate/navigation_drift
	announcement = "Navigation has detected a minor drift in the station's projected route. Pilots and engineering should review guidance data."
	announcement_title = "Navigation Warning"

/datum/event/catalogue/moderate/thermal_spike
	announcement = "Thermal sensors have recorded a transient spike near station machinery. Engineering should inspect cooling and insulation."
	announcement_title = "Thermal Warning"

/datum/event/catalogue/moderate/data_corruption
	mechanic_mode = "computer"
	announcement = "A portion of station records has failed an integrity check. Backups remain available, but affected terminals should be isolated."
	announcement_title = "Data Integrity Warning"

/datum/event/catalogue/moderate/evacuation_review
	announcement = "Emergency management has begun a review of evacuation readiness. Keep access routes clear until the review concludes."
	announcement_title = "Emergency Management"

/datum/event/catalogue/major/unknown_transmission
	announcement = "Command has confirmed a sustained transmission from beyond the station perimeter. The sender has not identified itself."
	announcement_title = "Priority Alert"

/datum/event/catalogue/major/containment_protocol
	mechanic_mode = "access"
	announcement = "A station-wide containment protocol has been placed on standby after multiple systems reported correlated anomalies."
	announcement_title = "Priority Alert"

/datum/event/catalogue/major/critical_power_review
	announcement = "Power infrastructure has entered a critical review state. All departments must prepare for possible interruptions."
	announcement_title = "Critical Power Alert"

/datum/event/catalogue/major/hostile_weather
	mechanic_mode = "radiation"
	endWhen = 80
	announcement = "External sensors report a dangerous environmental front approaching the station. Secure exposed equipment and personnel."
	announcement_title = "External Hazard Alert"

/datum/event/catalogue/major/false_evacuation
	announcement = "An evacuation order has been issued through an unverified command channel. Await confirmation while emergency systems investigate."
	announcement_title = "Evacuation Alert"

/datum/event/catalogue/major/black_box
	announcement = "A sealed black-box recording has been recovered from outside the station. Its contents indicate a developing threat."
	announcement_title = "Intelligence Alert"

/datum/event/catalogue/major/automated_lockdown
	mechanic_mode = "doors"
	announcement = "Automated security systems have entered a contested lockdown state. Command and security must establish control immediately."
	announcement_title = "Security Alert"

/datum/event/catalogue/major/deep_space_signal
	announcement = "A deep-space signal has synchronized with station systems. Its repeating pattern is affecting long-range sensors."
	announcement_title = "Priority Signal Alert"

/datum/event/catalogue/major/structural_emergency
	mechanic_mode = "gravity"
	endWhen = 60
	announcement = "Station structural integrity has fallen below the preferred operating margin. All departments should prepare emergency procedures."
	announcement_title = "Structural Emergency"

/datum/event/catalogue/major/unknown_cargo
	mechanic_mode = "drones"
	announcement = "A large unregistered mass has appeared on cargo tracking. Its composition and point of origin are unknown."
	announcement_title = "Cargo Emergency"

/datum/event/catalogue/major/command_failure
	mechanic_mode = "access"
	announcement = "Command authentication services are reporting a cascading failure. Department heads should verify orders in person."
	announcement_title = "Command Emergency"

/datum/event/catalogue/major/atmospheric_emergency
	mechanic_mode = "power"
	announcement = "Atmospheric control has declared an emergency readiness state after detecting multiple unresolved pressure anomalies."
	announcement_title = "Atmospheric Emergency"

/datum/event/catalogue/major/crew_manifest
	announcement = "The station manifest has reported an impossible discrepancy: more active identities are present than were assigned at departure."
	announcement_title = "Identity Emergency"

/datum/event/catalogue/major/last_warning
	announcement = "A final warning has been received from an unknown authority. It provides no explanation and a rapidly approaching deadline."
	announcement_title = "Priority Warning"

/datum/event/catalogue/major/operations_halt
	mechanic_mode = "comms"
	announcement = "Central operations has ordered all non-essential work suspended until a station-wide threat assessment is complete."
	announcement_title = "Operations Emergency"

/datum/event/catalogue/major/blackout_forecast
	mechanic_mode = "comms"
	announcement = "Station systems forecast a major communications and power disruption. Emergency teams should move to readiness positions."
	announcement_title = "Systems Emergency"

/datum/event/catalogue/major/arrival_window
	announcement = "Long-range tracking has identified a fast-moving object on a trajectory intersecting the station's operational envelope."
	announcement_title = "Approach Alert"
