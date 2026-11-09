GLOBAL_DATUM_INIT(os13_classic_round, /datum/os13_classic_round, new)

/proc/os13_classic_crew(mob/living/crew)
	if(!isliving(crew) || QDELETED(crew) || crew.stat == DEAD)
		return FALSE
	var/mob/living/carbon/human/person = crew
	if(istype(person) && person.os13_psi_control?.victim == person)
		return istype(person.os13_psi_control.victim_mind?.assigned_job, /datum/job/os13)
	return istype(crew.mind?.assigned_job, /datum/job/os13) && crew.mind.current == crew

/datum/os13_classic_round
	var/destruct_at = 0
	var/turf/destruct_origin
	var/datum/shuttle/charon/charon
	var/next_dock_attempt = 0

/datum/os13_classic_round/proc/emergency_available()
	if(GAME_STATE != RUNLEVEL_GAME || !istype(GLOB.using_map, /datum/map/os13classic) || SSticker.mode?.explosion_in_progress || SSticker.mode?.station_was_nuked || os13_fixed_traitor_mode()?.os13_orders?.bomb_detonated)
		return FALSE
	var/survivors = living_crew()
	return survivors > 0 && survivors <= 2

/datum/os13_classic_round/proc/living_crew()
	var/survivors = 0
	for(var/datum/mind/mind in SSticker.minds)
		if(!istype(mind.assigned_job, /datum/job/os13))
			continue
		var/mob/body = mind.current
		var/mob/observer/os13_psi_displaced/witness = body
		var/mob/living/carbon/human/borrowed = body
		if(istype(witness))
			body = witness.control?.victim
		else if(istype(borrowed) && borrowed.os13_psi_control?.caster_mind == mind)
			body = borrowed.os13_psi_control.caster
		if(isliving(body) && !QDELETED(body) && body.stat != DEAD && ++survivors > 2)
			break
	return survivors

/datum/os13_classic_round/proc/arm(turf/bridge)
	if(destruct_at || !is_station_turf(bridge) || !emergency_available())
		return FALSE
	destruct_origin = bridge
	destruct_at = world.time + 2 MINUTES
	command_announcement.Announce("Emergency self-destruct in two minutes. Proceed to the EVA lifeboats.", "Station Emergency", do_newscast = FALSE)
	return TRUE

/datum/os13_classic_round/proc/abort()
	if(!destruct_at)
		return FALSE
	destruct_at = 0
	destruct_origin = null
	command_announcement.Announce("Emergency self-destruct cancelled.", "Station Emergency", do_newscast = FALSE)
	return TRUE

/datum/os13_classic_round/proc/tick(elapsed)
	if(SSticker.mode?.explosion_in_progress)
		return
	if(destruct_at)
		if(living_crew() > 2)
			abort()
		else if(world.time >= destruct_at)
			var/turf/site = destruct_origin
			destruct_origin = null
			destruct_at = 0
			SSticker.mode.explosion_in_progress = TRUE
			INVOKE_ASYNC(src, .proc/detonate, site)
			return
	if(elapsed < 2 HOURS || world.time < next_dock_attempt || charon?.arrived_at_station)
		return
	next_dock_attempt = world.time + 10 SECONDS
	var/obj/effect/shuttle_landmark/charon_berth/berth = SSshuttle.get_landmark("os13_charon_dock")
	if(!charon)
		var/obj/effect/shuttle_landmark/charon_origin/origin = SSshuttle.get_landmark("os13_charon_origin")
		if(!origin || !berth)
			return
		charon = new(origin)
	charon.dock_at(berth)

/datum/os13_classic_round/proc/detonate(turf/site)
	SetUniversalState(/datum/universal_state/nuclear_explosion, arguments = list(site))

/obj/machinery/cryopod/lifepod/os13_lifeboat/crew
	name = "crew lifeboat"
	desc = "A one-person evacuation capsule. It unlocks when at most two members of the crew remain alive."

/obj/machinery/cryopod/lifepod/os13_lifeboat/crew/check_occupant_allowed(mob/crew)
	return ..() && os13_classic_crew(crew) && GLOB.os13_classic_round.emergency_available()

/obj/machinery/cryopod/lifepod/os13_lifeboat/crew/launch()
	if(!check_occupant_allowed(occupant))
		return FALSE
	return ..()

/obj/machinery/cryopod/lifepod/os13_lifeboat/crew/Process()
	. = ..()
	if(!launched && occupant && check_occupant_allowed(occupant))
		launch()

/obj/machinery/computer/bridge/proc/os13_emergency_controls_available(mob/user)
	if(!istype(GLOB.using_map, /datum/map/os13classic) || !os13_classic_crew(user) || QDELETED(src) || !operable() || !powered() || !user.Adjacent(src) || user.incapacitated())
		return FALSE
	var/datum/os13_classic_round/incident = GLOB.os13_classic_round
	return (incident.destruct_at || incident.emergency_available()) && CanUseTopic(user, GLOB.default_state) == STATUS_INTERACTIVE

/obj/machinery/computer/bridge/proc/os13_emergency_controls()
	var/datum/os13_classic_round/incident = GLOB.os13_classic_round
	if(incident.destruct_at)
		return "<span class='graytext'>SELF-DESTRUCT IN [max(0, round((incident.destruct_at - world.time) / (1 SECOND)))] SECONDS</span>\n<span class='feedback'><a href='?src=\ref[src];action=os13_abort_destruct'>ABORT SELF-DESTRUCT</a></span>\n"
	return "<span class='graytext'>CREW LIFEBOATS UNLOCKED IN EVA</span>\n<span class='feedback'><a href='?src=\ref[src];action=os13_arm_destruct'>ARM SELF-DESTRUCT</a></span>\n"

/obj/machinery/computer/bridge/proc/os13_emergency_destruct(mob/user, cancel = FALSE)
	if(!os13_emergency_controls_available(user))
		return
	if(cancel)
		GLOB.os13_classic_round.abort()
		return
	if(!GLOB.os13_classic_round.emergency_available() || GLOB.os13_classic_round.destruct_at)
		return
	if(alert(user, "Arm station self-destruct? The crew will have two minutes to evacuate.", "Emergency Self-Destruct", "Cancel", "Arm") != "Arm")
		return
	if(os13_emergency_controls_available(user))
		GLOB.os13_classic_round.arm(get_turf(src))
