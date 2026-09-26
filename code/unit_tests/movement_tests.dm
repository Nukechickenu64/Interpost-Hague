/datum/unit_test/movement
	name = "MOVEMENT template"
	async = 0

/datum/unit_test/movement/buckled_captain_chair_reaches_console
	name = "MOVEMENT - Buckled Captain Chair Reaches Console"

/datum/unit_test/movement/buckled_captain_chair_reaches_console/start_test()
	var/turf/seat_turf = get_safe_turf()
	var/turf/console_turf = get_step(seat_turf, NORTH)
	var/obj/structure/bed/chair/comfy/captain/seat = new(seat_turf)
	seat.set_dir(NORTH)
	var/mob/living/carbon/human/operator = new(seat_turf)
	var/obj/machinery/computer/shuttle_control/multi/console = new(console_turf)
	var/obj/structure/bed/chair/ordinary = new(get_step(seat_turf, SOUTH))

	if(!seat.buckle_mob(operator))
		fail("The captain chair could not buckle its occupant.")
	else if(!console.Adjacent(operator) || !operator.Adjacent(console))
		fail("The buckled occupant cannot reach the console directly in front of the chair.")
	else if(!(ordinary.atom_flags & ATOM_FLAG_CHECKS_BORDER))
		fail("The ordinary chair lost its border behavior.")
	else
		pass("A buckled captain can reach the console without changing ordinary chairs.")

	qdel(ordinary)
	qdel(console)
	qdel(operator)
	qdel(seat)
	return TRUE

/datum/unit_test/movement/force_move_shall_trigger_crossed_when_entering_turf
	name = "MOVEMENT - Force Move Shall Trigger Crossed When Entering Turf"

/datum/unit_test/movement/force_move_shall_trigger_crossed_when_entering_turf/start_test()
	var/turf/start = get_safe_turf()
	var/turf/target = get_step(start, NORTH)

	var/obj/mover = new /obj/test(start, 1)
	var/obj/test/crossed_obj/crossed = new(target, 1)

	mover.forceMove(target)

	if(!crossed.crossers)
		fail("The target object was never crossed.")
	else if(crossed.crossers.len != 1)
		fail("The target object was crossed [crossed.crossers.len] times, expected 1.")
	else
		pass("The target was crossed 1 time.")

	qdel(target)
	qdel(crossed)
	return TRUE

/datum/unit_test/movement/force_move_shall_trigger_entered
	name = "MOVEMENT - Force Move Shall Trigger Entered"

/datum/unit_test/movement/force_move_shall_trigger_entered/start_test()
	var/turf/start = get_safe_turf()
	var/obj/mover = new /obj/test(start, 1)
	var/obj/test/entered_obj/target = new(start, 1)

	mover.forceMove(target)

	if(!target.enterers)
		fail("The target object was never entered.")
	else if(target.enterers.len != 1)
		fail("The target object was entered [target.enterers.len] times, expected 1.")
	else
		pass("The target was entered 1 time.")

	qdel(mover)
	qdel(target)
	return TRUE

/datum/unit_test/movement/ghost_walks_through_objects_not_walls
	name = "MOVEMENT - Ghost Walks Through Objects, Not Walls"

/datum/unit_test/movement/ghost_walks_through_objects_not_walls/start_test()
	var/turf/start = get_safe_turf()
	var/turf/target = get_step(start, NORTH)
	var/old_density = target.density
	var/mob/observer/ghost/observer = new(start)
	var/obj/test/blocker = new(target, 1)
	blocker.density = TRUE
	blocker.anchored = TRUE
	if(!observer.can_walk_into(target))
		fail("A dense object on an open turf blocked the ghost.")
	target.density = TRUE
	if(observer.can_walk_into(target))
		fail("A solid turf did not block the ghost.")
	if(!reported)
		pass("Open turfs remain passable through dense objects; solid turfs block ghosts.")
	target.density = old_density
	qdel(blocker)
	qdel(observer)
	return TRUE

/datum/unit_test/movement/pain_possession_target_rules
	name = "MOVEMENT - Pain Possession Target Rules"

/datum/unit_test/movement/pain_possession_target_rules/start_test()
	var/turf/start = get_safe_turf()
	var/mob/observer/ghost/observer = new(start)
	observer.pain_possession_turf = start
	var/obj/item/toy/figure/figure = new(start)
	var/obj/item/clothing/mask/mask = new(start)
	var/obj/test/fixture = new(start, 1)
	fixture.anchored = TRUE
	var/obj/effect/nonphysical = new(start)
	if(!observer.valid_pain_possession_target(figure) || observer.valid_pain_possession_target(fixture) || observer.valid_pain_possession_target(nonphysical))
		fail("Loose physical objects should be eligible; anchored fixtures and effects should not.")
	if(!figure.has_possession_mouth() || !mask.has_possession_mouth() || fixture.has_possession_mouth())
		fail("Only the allowed mask and doll types should have possession speech.")
	figure.pain_possessor = observer
	if(observer.valid_pain_possession_target(figure))
		fail("An object already controlled by a ghost is still eligible.")
	figure.pain_possessor = null
	if(!reported)
		pass("Only unclaimed loose physical objects are eligible; masks and dolls can speak.")
	qdel(nonphysical)
	qdel(fixture)
	qdel(mask)
	qdel(figure)
	qdel(observer)
	return TRUE

/obj/test/crossed_obj
	var/list/crossers

/obj/test/crossed_obj/Crossed(var/crosser)
	if(!crossers)
		crossers = list()
	crossers += crosser

/obj/test/entered_obj
	var/list/enterers

/obj/test/entered_obj/Entered(var/enterer)
	if(!enterers)
		enterers = list()
	enterers += enterer
