// Exercise the production Classic map after normal atom and shuttle initialization.
/hook/startup/proc/os13_multiz_regression_log()
	fdel("tmp/os13-multiz-regression.log")
	world.log = file("tmp/os13-multiz-regression.log")
	return TRUE

SUBSYSTEM_DEF(os13_multiz_regression)
	name = "OS13 multiz regression"
	flags = SS_NO_FIRE
	init_order = -INFINITY

/datum/controller/subsystem/os13_multiz_regression/Initialize(timeofday)
	. = ..()
	world.sleep_offline = FALSE
	SSticker.can_fire = FALSE
	var/datum/os13_multiz_regression/check = new
	check.check_map()

/datum/os13_multiz_regression
	var/failures = 0

/datum/os13_multiz_regression/proc/expect(condition, message)
	if(!condition)
		failures++
		if(failures <= 20)
			world.log << "OS13_MULTIZ_FAIL: [message]"
	return condition

/datum/os13_multiz_regression/proc/check_map()
	if(!expect(istype(GLOB.using_map, /datum/map/os13classic), "Requires the production Classic map."))
		finish()
		return
	expect(HasAbove(1) && HasBelow(2), "Decks 1 and 2 are disconnected.")
	expect(HasAbove(2) && HasBelow(3), "The mapped roof is disconnected from deck 2.")
	expect(!HasBelow(1) && !HasAbove(3) && !HasBelow(4), "The station stack connects to an unrelated level.")
	for(var/z in 1 to 3)
		expect(SSzcopy.zstack_maximums[z] == 3, "Incorrect rendering stack maximum for Z[z].")

	var/ladder_pairs = 0
	for(var/list/position in list(list(104, 117), list(104, 121), list(104, 123), list(104, 127), list(143, 150)))
		var/turf/lower_turf = locate(position[1], position[2], 1)
		var/turf/upper_turf = locate(position[1], position[2], 2)
		var/obj/structure/ladder/lower = locate() in lower_turf
		var/obj/structure/ladder/upper = locate() in upper_turf
		if(!expect(lower && upper && lower.target_up == upper && upper.target_down == lower, "Unpaired exterior ladder at [position.Join(",")]."))
			continue
		expect(!upper.target_up && (upper.allowed_directions & DOWN), "Upper endpoint does not terminate the ladder route.")
		var/mob/living/carbon/human/climber = new(lower_turf)
		expect(lower.getTargetLadder(climber) == upper, "Lower ladder interaction selects the wrong destination.")
		expect(lower.climbLadder(climber, upper) && climber.loc == upper_turf, "Climber could not ascend at [position.Join(",")].")
		expect(upper.getTargetLadder(climber) == lower, "Upper ladder interaction selects the wrong destination.")
		expect(upper.climbLadder(climber, lower) && climber.loc == lower_turf, "Climber could not descend at [position.Join(",")].")
		qdel(climber)
		ladder_pairs++
	world.log << "OS13_MULTIZ: exercised [ladder_pairs] exterior ladder pairs in both directions."

	var/open_tiles = 0
	var/visible_lower_tiles = 0
	for(var/turf/simulated/open/tile in world)
		if(tile.z != 2 && tile.z != 3)
			continue
		var/turf/under = locate(tile.x, tile.y, tile.z - 1)
		expect(GetBelow(tile) == under && tile.below == under && under.above == tile, "Open-floor rendering link missing at [tile.x],[tile.y],[tile.z].")
		if(tile.z_flags & ZM_ALLOW_ATMOS)
			expect(CanAtmosZConnect(tile, under), "Open-floor atmosphere link missing at [tile.x],[tile.y],[tile.z].")
		// Check actual Z1 artwork copied into Z2 openings, beyond linked refs.
		if(tile.z == 2 && (tile.z_flags & ZM_MIMIC_OVERWRITE) && !istype(under, /turf/space) && !(under.z_flags & ZM_MIMIC_BELOW))
			expect(tile.icon == under.icon && tile.icon_state == under.icon_state && tile.dir == under.dir, "Lower-deck artwork missing at [tile.x],[tile.y],2.")
			expect(tile.plane == OPENTURF_MAX_PLANE - 1 && tile.z_depth == 1 && !tile.opacity && tile.alpha > 0, "Lower-deck appearance has incorrect visibility/depth at [tile.x],[tile.y],2.")
			visible_lower_tiles++
		open_tiles++
		CHECK_TICK
	expect(open_tiles > 0, "No production open-floor fixtures were exercised.")
	expect(visible_lower_tiles > 0, "No Z2 openings onto solid Z1 turfs were exercised.")
	world.log << "OS13_MULTIZ: checked [open_tiles] open-floor links on decks 2 and 3."
	world.log << "OS13_MULTIZ: checked copied lower-deck artwork and visibility on [visible_lower_tiles] Z2 openings."
	finish()

/datum/os13_multiz_regression/proc/finish()
	expect(GLOB.total_runtimes == 0, "Native runtime errors occurred.")
	world.log << "OS13_MULTIZ_RESULT: [failures ? "FAIL" : "PASS"] failures=[failures] runtimes=[GLOB.total_runtimes]"
	del(world)
