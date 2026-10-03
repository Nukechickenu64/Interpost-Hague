/datum/unit_test/movement
	name = "MOVEMENT template"
	async = 0

/datum/unit_test/movement/proc/get_jetpack_test_turf()
	for(var/turf/space/candidate in world)
		if(candidate.x < 4 || candidate.y < 4 || candidate.x > world.maxx - 3 || candidate.y > world.maxy - 3 || candidate.z >= world.maxz)
			continue
		var/turf/above = locate(candidate.x, candidate.y, candidate.z + 1)
		if(!istype(above, /turf/space))
			continue
		var/list/test_turfs = trange(1, candidate)
		test_turfs += above
		var/clear = TRUE
		for(var/turf/nearby in test_turfs)
			if(!istype(nearby, /turf/space))
				clear = FALSE
				break
			for(var/atom/movable/occupant in nearby)
				if(!istype(occupant, /atom/movable/lighting_overlay))
					clear = FALSE
					break
			if(!clear)
				break
		if(clear)
			return candidate
	return null

/datum/unit_test/movement/jetpack_horizontal_thrust
	name = "MOVEMENT - Jetpack Horizontal Thrust"

/datum/unit_test/movement/jetpack_horizontal_thrust/start_test()
	var/turf/start = get_jetpack_test_turf()
	if(!start)
		skip("No empty space region is available for jetpack movement tests.")
		return TRUE
	var/turf/target = get_step(start, NORTH)
	var/mob/living/carbon/human/pilot = new(start)
	var/obj/item/tank/jetpack/oxygen/pack = new(pilot)
	if(!pilot.equip_to_slot_if_possible(pack, slot_back))
		fail("A jetpack could not be equipped in the back slot.")
	else
		pack.ui_action_click()
		var/fuel_before = pack.air_contents.total_moles
		if(!pilot.Process_Spacemove(0))
			fail("A fueled, enabled back-slot jetpack did not permit thrust.")
		else if(abs(fuel_before - pack.air_contents.total_moles - 0.01) > ATMOS_PRECISION)
			fail("Horizontal thrust did not consume the expected fuel.")
		else if(!pilot.SelfMove(target, NORTH) || pilot.loc != target)
			fail("A pilot with working thrust could not move to adjacent space.")
		pack.stabilization_on = TRUE
		pilot.inertia_dir = NORTH
		if(!pilot.Process_Spacemove(1) || pilot.inertia_dir)
			fail("An enabled stabilizer did not stop drift.")
		pack.stabilization_on = FALSE
		fuel_before = pack.air_contents.total_moles
		if(pilot.Process_Spacemove(1) || pack.air_contents.total_moles != fuel_before)
			fail("A disabled stabilizer used fuel or stopped drift in open space.")
		pack.on = FALSE
		if(pack.allow_thrust(0.01, pilot))
			fail("A disabled jetpack supplied thrust.")
		pack.on = TRUE
		var/datum/gas_mixture/exhaust = pack.air_contents.remove(pack.air_contents.total_moles)
		qdel(exhaust)
		if(pack.allow_thrust(0.01, pilot))
			fail("An empty jetpack supplied thrust.")
		else
			pack.air_contents.adjust_gas("oxygen", 0.004)
			var/last_pulse_percent = pack.remaining_gas_percent()
			if(last_pulse_percent <= 0)
				fail("A jetpack with residual gas displayed 0% remaining.")
			else if(!pack.allow_thrust(0.01, pilot))
				fail("A jetpack refused its final partial thrust pulse.")
			else if(pack.air_contents.total_moles > 0)
				fail("The final partial thrust pulse did not consume the remaining gas.")
	if(!reported)
		pass("Fueled jetpacks permit horizontal movement and honor stabilization and activation.")
	qdel(pilot)
	qdel(pack)
	return TRUE

/datum/unit_test/movement/tank_remaining_gas_percentage
	name = "MOVEMENT - Tank Remaining Gas Percentage"

/datum/unit_test/movement/tank_remaining_gas_percentage/start_test()
	var/obj/item/tank/emergency/oxygen/tank = new(null)
	if(tank.remaining_gas_percent() != 100)
		fail("A full emergency oxygen tank did not display 100% gas remaining.")
	else
		var/datum/gas_mixture/used_gas = tank.air_contents.remove(tank.air_contents.total_moles / 2)
		qdel(used_gas)
		if(abs(tank.remaining_gas_percent() - 50) > 1)
			fail("A half-empty oxygen tank did not display approximately 50% gas remaining.")
		else
			var/datum/gas_mixture/remaining_gas = tank.air_contents.remove(tank.air_contents.total_moles)
			qdel(remaining_gas)
			if(tank.remaining_gas_percent() != 0)
				fail("An empty oxygen tank did not display 0% gas remaining.")
			else
				pass("Tank percentage reflects remaining gas rather than tank pressure.")
	qdel(tank)
	return TRUE

/datum/unit_test/movement/oxygen_tank_breaths_until_empty
	name = "MOVEMENT - Oxygen Tank Breathes Until Empty"

/datum/unit_test/movement/oxygen_tank_breaths_until_empty/start_test()
	var/obj/item/tank/oxygen/tank = new(null)
	var/breath_moles = tank.distribute_pressure * BREATH_VOLUME / (R_IDEAL_GAS_EQUATION * T20C)
	var/datum/gas_mixture/unused_gas = tank.air_contents.remove(tank.air_contents.total_moles - 2 * breath_moles)
	qdel(unused_gas)
	if(tank.air_contents.return_pressure() >= tank.distribute_pressure)
		fail("The low-pressure breathing test did not leave the tank below regulator pressure.")
	else
		for(var/breath_index = 1 to 2)
			var/datum/gas_mixture/breath = tank.remove_air_volume(BREATH_VOLUME)
			if(!breath || abs(breath.total_moles - breath_moles) > ATMOS_PRECISION)
				fail("The oxygen tank did not provide a full breath with gas remaining.")
				qdel(breath)
				break
			qdel(breath)
		if(tank.air_contents.total_moles > ATMOS_PRECISION)
			fail("The low-pressure oxygen tank did not reach empty after its remaining breaths.")
		else
			pass("The oxygen tank supplies normal breaths until no gas remains.")
	qdel(tank)
	return TRUE

/datum/unit_test/movement/jetpack_vertical_thrust
	name = "MOVEMENT - Jetpack Vertical Thrust"

/datum/unit_test/movement/jetpack_vertical_thrust/start_test()
	var/turf/space_turf = get_jetpack_test_turf()
	if(!space_turf)
		skip("No empty pair of space turfs is available for vertical jetpack tests.")
		return TRUE
	var/lower_z = space_turf.z
	var/turf/lower = locate(space_turf.x, space_turf.y, lower_z)
	var/turf/upper = locate(space_turf.x, space_turf.y, lower_z + 1)
	var/lower_type = lower.type
	var/upper_type = upper.type
	var/list/original_z_levels = z_levels.Copy()
	if(z_levels.len < lower_z)
		z_levels.len = lower_z
	z_levels[lower_z] = TRUE
	lower = lower.ChangeTurf(/turf/space)
	upper = upper.ChangeTurf(/turf/space)
	var/mob/living/carbon/human/pilot = new(lower)
	var/obj/item/tank/jetpack/oxygen/pack = new(pilot)
	var/obj/test/blocker = new(upper, 1)
	blocker.density = TRUE
	blocker.anchored = TRUE
	if(!pilot.equip_to_slot_if_possible(pack, slot_back))
		fail("A jetpack could not be equipped for vertical flight.")
	else
		pack.on = TRUE
		var/fuel_before = pack.air_contents.total_moles
		if(pilot.zMove(UP) || pilot.loc != lower || pack.air_contents.total_moles != fuel_before)
			fail("A blocked upward request moved the pilot or consumed fuel.")
		qdel(blocker)
		blocker = null
		pack.on = FALSE
		if(pilot.zMove(UP) || pilot.loc != lower || pack.air_contents.total_moles != fuel_before)
			fail("A disabled jetpack allowed vertical flight or consumed fuel.")
		pack.on = TRUE
		pilot.anchored = TRUE
		if(pilot.zMove(UP) || pack.air_contents.total_moles != fuel_before)
			fail("An anchored pilot flew or consumed fuel.")
		pilot.anchored = FALSE
		pilot.stat = UNCONSCIOUS
		if(pilot.zMove(UP) || pack.air_contents.total_moles != fuel_before)
			fail("An unconscious pilot flew or consumed fuel.")
		pilot.stat = CONSCIOUS
		pack.stabilization_on = TRUE
		pilot.last_move = NORTH
		if(!pilot.zMove(UP) || pilot.loc != upper)
			fail("A fueled jetpack did not fly upwards through open space.")
		else if(abs(fuel_before - pack.air_contents.total_moles - 0.01) > ATMOS_PRECISION)
			fail("Upward flight did not consume exactly one thrust pulse.")
		else if(pilot.last_move || pilot.inertia_dir)
			fail("Vertical flight retained stale horizontal momentum.")
		fuel_before = pack.air_contents.total_moles
		if(!pilot.zMove(DOWN) || pilot.loc != lower)
			fail("A fueled jetpack did not fly downwards through open space.")
		else if(abs(fuel_before - pack.air_contents.total_moles - 0.01) > ATMOS_PRECISION)
			fail("Downward flight did not consume exactly one thrust pulse.")
		var/obj/structure/catwalk/catwalk = new(upper)
		fuel_before = pack.air_contents.total_moles
		if(pilot.zMove(UP) || pilot.loc != lower || pack.air_contents.total_moles != fuel_before)
			fail("A catwalk allowed upward flight through its floor or consumed fuel.")
		qdel(catwalk)
		upper = upper.ChangeTurf(/turf/simulated/floor/airless)
		if(pilot.zMove(UP) || pilot.loc != lower || pack.air_contents.total_moles != fuel_before)
			fail("A solid floor allowed upward flight or consumed fuel.")
		upper = upper.ChangeTurf(/turf/space)
		z_levels[lower_z] = FALSE
		if(pilot.zMove(UP) || pilot.loc != lower || pack.air_contents.total_moles != fuel_before)
			fail("Flight across disconnected levels succeeded or consumed fuel.")
		z_levels[lower_z] = TRUE
		var/datum/gas_mixture/exhaust = pack.air_contents.remove(pack.air_contents.total_moles)
		qdel(exhaust)
		if(pilot.zMove(UP) || pilot.loc != lower)
			fail("An empty jetpack allowed vertical flight.")
	if(!reported)
		pass("Vertical flight respects fuel, activation, movement restrictions and passage checks.")
	qdel(blocker)
	qdel(pilot)
	qdel(pack)
	lower.ChangeTurf(lower_type)
	upper.ChangeTurf(upper_type)
	z_levels = original_z_levels
	return TRUE

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
