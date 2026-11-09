/hook/startup/proc/wraith_regression_log()
	fdel("tmp/wraith-regression.log")
	world.log = file("tmp/wraith-regression.log")
	return TRUE

SUBSYSTEM_DEF(wraith_regression)
	name = "Wraith regression"
	flags = SS_NO_FIRE
	init_order = -INFINITY

/datum/controller/subsystem/wraith_regression/Initialize(timeofday)
	. = ..()
	spawn(0)
		world.sleep_offline = FALSE
		var/datum/wraith_regression/check = new
		check.run_checks()

/area/wraith_regression
	requires_power = FALSE
	dynamic_lighting = FALSE

/obj/structure/wraith_regression_control
	var/used = FALSE

/obj/structure/wraith_regression_control/attack_hand(mob/user)
	used = TRUE

/datum/wraith_regression
	var/failures = 0

/datum/wraith_regression/proc/expect(condition, message)
	if(!condition)
		failures++
		world.log << "WRAITH_FAIL: [message]"

/datum/wraith_regression/proc/run_checks()
	var/baseline_runtimes = GLOB.total_runtimes
	var/area/room = new /area/wraith_regression
	for(var/x = 20, x <= 26, x++)
		for(var/y = 20, y <= 24, y++)
			var/turf/tile = locate(x, y, 1)
			tile = tile.ChangeTurf(/turf/unsimulated/floor)
			room.contents.Add(tile)
	var/turf/origin = locate(22,22,1)
	var/turf/adjacent = locate(23,22,1)
	var/mob/observer/ghost/ghost = new
	ghost.forceMove(origin)
	var/mob/living/carbon/human/patient = new(adjacent)
	patient.sleeping = 5
	var/obj/machinery/light/fixture = new(origin)
	fixture.on = TRUE
	var/obj/item/screwdriver/tool = new(origin)
	var/obj/structure/wraith_regression_control/control = new(origin)
	ghost.pain_possession_turf = origin
	ghost.wraith_pain = 20
	for(var/phi in list(null, 89, 90))
		SSticker.phi = phi
		expect(!ghost.can_affect_world() && !ghost.ghost_ability_check(), "The strict Phi threshold opened at [phi].")
		expect(!ghost.wraith_flicker(fixture) && !fixture.flicker(spectral_source = ghost) && !fixture.flickering && fixture.on, "A lamp was altered by a locked wraith at [phi].")
		expect(!ghost.wraith_deliver_dream(patient, "A dream") && !ghost.wraith_create_grue(), "A dream or grue bypassed Phi at [phi].")
		expect(!ghost.possess_pain_object(tool) && !tool.pain_possessor && !ghost.try_possession(patient), "Possession was allowed at [phi].")
		ghost.toggle_visiblity()
		expect(ghost.invisibility == INVISIBILITY_OBSERVER && ghost.wraith_pain == 20, "A refused effect manifested the ghost or spent its Pain at [phi].")
		var/datum/ghosttrap/trap = get_ghost_trap("positronic brain")
		expect(!trap.assess_candidate(ghost, patient, FALSE), "A physical recruitment offer ignored Phi at [phi].")
		ghost.handle_tilectx_topic(list("tilectx_invoke" = "\ref[control]", "proc" = "use"))
		expect(!control.used, "A stale context-menu request performed a physical action at [phi].")
	world.log << "WRAITH_CHECK: closed at unset, 89 and 90 across supernatural and legacy routes"

	var/obj/effect/wraith_echo/echo = new(adjacent)
	ghost.ghost_to_turf(adjacent)
	expect(ghost.loc == adjacent && QDELETED(echo) && ghost.wraith_pain == 25, "Passive movement or collecting Pain stopped at Phi 90.")
	ghost.ghost_to_turf(origin)
	ghost.ghost_to_turf(adjacent)
	expect(ghost.wraith_pain == 25, "A single echo could be collected repeatedly.")
	ghost.ghost_to_turf(origin)
	world.log << "WRAITH_CHECK: passive travel and single-use Pain collection at Phi 90"

	SSticker.phi = 91
	expect(ghost.can_affect_world() && ghost.ghost_ability_check(), "Phi 91 did not enable the wraith powers.")
	patient.sleeping = 5
	expect(ghost.wraith_deliver_dream(patient, "A dream"), "A wraith could not reach a nearby sleeping human at Phi 91.")
	patient.sleeping = 0
	expect(!ghost.wraith_deliver_dream(patient, "A dream"), "A dream reached an awake human.")
	expect(ghost.wraith_flicker(fixture) && fixture.flickering && ghost.wraith_pain == 24, "A paid haunt did not start a real light flicker or spent the wrong amount.")
	for(var/i = 1, i <= 10 && fixture.on, i++)
		sleep(1)
	expect(!fixture.on, "An authorized haunt never changed the lamp's physical state.")
	SSticker.phi = 90
	for(var/i = 1, i <= 10 && fixture.flickering, i++)
		sleep(1)
	expect(!fixture.flickering && fixture.on, "Flicker continued after Phi fell or left the lamp unpowered.")
	qdel(fixture)
	world.log << "WRAITH_CHECK: Phi 91 dreams and physical flicker, with cleanup at Phi 90"

	SSticker.phi = 91
	var/mob/living/simple_animal/os13_grue/grue = ghost.wraith_create_grue()
	expect(grue && grue.loc == origin && ghost.wraith_pain == 9, "Summoning did not create a dark-ground grue for 15 Pain.")
	var/obj/item/organ/internal/heart/heart = patient.internal_organs_by_name[BP_HEART]
	patient.stat = CONSCIOUS
	patient.sleeping = 0
	patient.Move(origin)
	expect(heart.pulse == PULSE_NONE && patient.is_asystole(), "An authorized grue crossing failed to cause native cardiac arrest.")
	patient.forceMove(adjacent)
	heart.pulse = PULSE_NORM
	SSticker.phi = 90
	patient.Move(origin)
	expect(heart.pulse == PULSE_NORM, "A previously summoned grue could still stop a heart after Phi fell.")
	if(grue && !QDELETED(grue))
		grue.Life()
		expect(QDELETED(grue), "A locked grue persisted in the world.")
	world.log << "WRAITH_CHECK: physical grue and native cardiac arrest only above Phi 90"

	qdel(patient)
	qdel(tool)
	qdel(control)
	qdel(ghost)
	expect(GLOB.total_runtimes == baseline_runtimes, "The wraith checks caused a native runtime.")
	world.log << "WRAITH_RESULT: [failures ? "FAIL" : "PASS"] failures=[failures] new_runtimes=[GLOB.total_runtimes - baseline_runtimes] startup_runtimes=[baseline_runtimes]"
	del(world)
