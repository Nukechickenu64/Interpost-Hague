/area/shuttle/os13_charon
	name = "TNC Charon"
	requires_power = FALSE

/obj/effect/shuttle_landmark/charon_origin
	name = "Charon holding point"
	landmark_tag = "os13_charon_origin"
	base_area = /area/space
	base_turf = /turf/space

/obj/effect/shuttle_landmark/charon_berth
	name = "Primary Docking Port"
	landmark_tag = "os13_charon_dock"
	autoset = TRUE

/obj/effect/shuttle_landmark/charon_berth/is_valid(datum/shuttle/shuttle)
	if(shuttle.current_location == src)
		return FALSE
	for(var/area/cabin in shuttle.shuttle_area)
		var/list/translation = get_turf_translation_safe(get_turf(shuttle.current_location), get_turf(src), cabin.contents)
		if(!length(translation) || check_collision(translation))
			return FALSE
		for(var/turf/source as anything in translation)
			var/turf/destination = translation[source]
			for(var/atom/movable/obstacle in destination)
				if(obstacle.simulated)
					return FALSE
	return TRUE

/obj/machinery/door/airlock/os13/charon_dock
	name = "Charon docking hatch"
	locked = TRUE
	autoclose = FALSE

/datum/shuttle/charon
	name = "TNC Charon"
	category = /datum/shuttle/charon
	defer_initialisation = TRUE
	shuttle_area = /area/shuttle/os13_charon
	knockdown = FALSE
	var/arrived_at_station = FALSE
	var/list/invaders = list()
	var/boarding_deadline = 0

/datum/shuttle/charon/New(obj/effect/shuttle_landmark/charon_origin/origin)
	..(null, origin)

/datum/shuttle/charon/proc/dock_at(obj/effect/shuttle_landmark/charon_berth/berth)
	if(arrived_at_station || !berth || !attempt_move(berth))
		return FALSE
	arrived_at_station = TRUE
	for(var/obj/machinery/door/airlock/os13/charon_dock/hatch in range(2, berth))
		hatch.locked = FALSE
		hatch.open(TRUE)
	command_announcement.Announce("TNC Charon has docked at the primary gateway. Authorization code expired. Prepare to repel boarders.", "Arriving Vessel", do_newscast = FALSE)
	deploy_invaders()
	return TRUE

/proc/os13_charon_active_ghost(mob/observer/ghost/ghost)
	return istype(ghost) && ghost.client && !ghost.client.is_afk() && !(ghost.can_reenter_corpse && isliving(ghost.mind?.current) && ghost.mind.current.stat != DEAD)

/datum/shuttle/charon/proc/deploy_invaders()
	var/list/ghosts = list()
	for(var/mob/observer/ghost/ghost in GLOB.player_list)
		if(os13_charon_active_ghost(ghost))
			ghosts += ghost
	var/list/spawn_turfs = list()
	for(var/area/cabin in shuttle_area)
		for(var/turf/simulated/floor/floor in cabin)
			if(!(locate(/obj/machinery/door) in floor))
				spawn_turfs += floor
	if(!length(spawn_turfs))
		return
	var/forced_crew = length(ghosts) > 4
	var/party_size = forced_crew ? length(ghosts) : 8
	var/list/free_turfs = spawn_turfs.Copy()
	for(var/index in 1 to party_size)
		if(!length(free_turfs))
			free_turfs = spawn_turfs.Copy()
		var/turf/site = pick_n_take(free_turfs)
		var/mob/living/carbon/human/invader/charon/boarder = new(site)
		var/datum/invader_ai/charon/brain = boarder.brain
		brain.charon = src
		invaders += boarder
		if(forced_crew)
			var/mob/observer/ghost/ghost = ghosts[index]
			if(os13_charon_active_ghost(ghost))
				boarder.key = ghost.key
				if(boarder.mind)
					boarder.mind.assigned_role = "Charon Invader"
				to_chat(boarder, SPAN_WARNING("You are a Charon invader. Board the station with your squad and eliminate the crew. The mining lift leads to the upper deck."))

/mob/living/carbon/human/invader/charon/Initialize()
	. = ..()
	QDEL_NULL(wear_mask)
	equip_to_slot_or_del(new /obj/item/clothing/mask/breath(src), slot_wear_mask)
	var/obj/item/tank/emergency/oxygen/engi/supply = new(src)
	equip_to_slot_or_del(supply, slot_belt)
	if(!QDELETED(supply))
		internal = supply
	STOP_PROCESSING(SSinvaders, brain)
	qdel(brain)
	brain = new /datum/invader_ai/charon(src, mover)
	START_PROCESSING(SSinvaders, brain)

/datum/shuttle/autodock/ferry/lift2/proc/classic_bay_contains(turf/tile)
	var/turf/landing = get_turf(tile?.z == waypoint_station?.z ? waypoint_station : waypoint_offsite)
	return tile && landing && tile.z == landing.z && abs(tile.x - landing.x) <= 1 && abs(tile.y - landing.y) <= 1

/obj/machinery/computer/shuttle_control/lift2/classic
	desc = "A mining lift control panel fed by the lift's independent drive power."
	use_power = POWER_USE_OFF

/obj/machinery/computer/shuttle_control/lift2/classic/powered(chan, area/check_area)
	return TRUE

/datum/invader_ai/charon
	var/datum/shuttle/charon/charon
	var/finished_boarding = FALSE

/datum/invader_ai/charon/Process()
	if(QDELETED(owner) || owner.stat == DEAD || !mover || finished_boarding || !charon || owner.client)
		return ..()
	if(owner.stat != CONSCIOUS || owner.incapacitated() || !owner.canmove || breach_door)
		return ..()
	var/datum/shuttle/autodock/ferry/lift2/lift = SSshuttle.shuttles["Mining Lift"]
	var/turf/lower = get_turf(lift?.waypoint_offsite)
	var/turf/upper = get_turf(lift?.waypoint_station)
	if(!lower || !upper)
		return ..()
	if(owner.z == upper.z)
		if(!lift.classic_bay_contains(get_turf(owner)))
			finished_boarding = TRUE
			mover.clear()
			return ..()
		move_to(locate(upper.x + 2, upper.y, upper.z))
		return
	if(owner.z != lower.z)
		return ..()

	var/list/squad = list()
	var/aboard = 0
	for(var/mob/living/carbon/human/invader/charon/ally in charon.invaders)
		if(!QDELETED(ally) && ally.z == lower.z && ally.stat == CONSCIOUS && !ally.client && !ally.incapacitated())
			squad += ally
			if(get_area(ally) in lift.shuttle_area)
				aboard++
			if(length(squad) >= 8)
				break
	var/index = squad.Find(owner)
	if(!index)
		return
	if(lift.current_location != lift.waypoint_offsite)
		charon.boarding_deadline = 0
		var/turf/waiting = index == 1 ? locate(lower.x, lower.y + 2, lower.z) : locate(lower.x - 2 + ((index - 2) % 5), lower.y + 3 + round((index - 2) / 5), lower.z)
		move_to(waiting)
		if(!upper_lift_occupied(lift) && !lower_bay_occupied(lift, lower))
			operate_lift(lift, lower)
		return
	if(lift.is_launching())
		return
	if(get_area(owner) in lift.shuttle_area)
		if(!charon.boarding_deadline)
			charon.boarding_deadline = world.time + 40 SECONDS
		if(aboard == length(squad) || (aboard >= 2 && world.time >= charon.boarding_deadline))
			operate_lift(lift, lower)
	if(lift.process_state == IDLE_STATE)
		// Keep a caller beside the console and fill the far rows to leave the approach clear.
		var/seat = index == 1 ? 7 : (index == 8 ? 8 : index - 2)
		var/turf/boarding = locate(lower.x - 1 + (seat % 3), lower.y - 1 + round(seat / 3), lower.z)
		move_to(boarding)

/datum/invader_ai/charon/proc/move_to(turf/goal)
	if(!goal || get_turf(owner) == goal)
		return
	if(mover.goal != goal)
		mover.clear()
		mover.set_goal(goal)
	if(mover.tick() == MOVER_BLOCKED_DOOR)
		begin_breach(mover.blocking_door)

/datum/invader_ai/charon/proc/upper_lift_occupied(datum/shuttle/autodock/ferry/lift2/lift)
	for(var/mob/living/carbon/human/invader/charon/ally in charon.invaders)
		if(!QDELETED(ally) && !ally.client && ally.stat == CONSCIOUS && (get_area(ally) in lift.shuttle_area))
			return TRUE
	return FALSE

/datum/invader_ai/charon/proc/lower_bay_occupied(datum/shuttle/autodock/ferry/lift2/lift, turf/landing)
	for(var/mob/living/carbon/human/invader/charon/ally in charon.invaders)
		if(!QDELETED(ally) && ally.stat != DEAD && ally.z == landing.z && lift.classic_bay_contains(get_turf(ally)))
			return TRUE
	return FALSE

/datum/invader_ai/charon/proc/operate_lift(datum/shuttle/autodock/ferry/lift2/lift, turf/landing)
	if(lift.process_state != IDLE_STATE || !lift.can_launch())
		return
	var/obj/machinery/computer/shuttle_control/lift2/controls = locate() in locate(landing.x - 1, landing.y + 2, landing.z)
	if(controls && owner.Adjacent(controls) && controls.operable() && controls.allowed(owner))
		controls.attack_hand(owner)
