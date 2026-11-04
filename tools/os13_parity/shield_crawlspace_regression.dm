/hook/startup/proc/shield_crawlspace_regression_log()
	fdel("tmp/shield-crawlspace-regression.log")
	world.log = file("tmp/shield-crawlspace-regression.log")
	return TRUE

SUBSYSTEM_DEF(shield_crawlspace_regression)
	name = "Shield crawlspace regression"
	flags = SS_NO_FIRE
	init_order = -INFINITY

/datum/controller/subsystem/shield_crawlspace_regression/Initialize(timeofday)
	. = ..()
	world.sleep_offline = FALSE
	SSticker.can_fire = FALSE
	SSmachines.can_fire = FALSE
	var/datum/shield_crawlspace_regression/check = new
	check.run()

/area/maintenance/shield_crawlspace_regression
	name = "Shield maintenance regression"
	requires_power = FALSE
	dynamic_lighting = FALSE

/area/shield_crawlspace_regression
	name = "Shield ordinary room regression"
	requires_power = FALSE
	dynamic_lighting = FALSE

/datum/shield_crawlspace_regression
	var/failures = 0

/datum/shield_crawlspace_regression/proc/expect(condition, message)
	if(!condition)
		failures++
		world.log << "SHIELD_CRAWLSPACE_FAIL: [message]"

/datum/shield_crawlspace_regression/proc/run()
	var/baseline_runtimes = GLOB.total_runtimes
	var/area/maintenance/room = new /area/maintenance/shield_crawlspace_regression
	var/area/ordinary = new /area/shield_crawlspace_regression
	for(var/z in list(1, world.maxz))
		for(var/x = 20, x <= 28, x++)
			for(var/y = 20, y <= 24, y++)
				var/turf/tile = locate(x, y, z)
				for(var/obj/object in tile)
					qdel(object)
				tile = tile.ChangeTurf(/turf/unsimulated/floor)
				room.contents.Add(tile)
	var/obj/machinery/power/shield_generator/generator = new(locate(20,20,1))
	var/list/occupants = list()
	var/list/variants = list(/turf/simulated/open/crawlspace, /turf/simulated/open/crawlspace/maintenance, /turf/simulated/open/crawlspace/hatch, /turf/simulated/open/crawlspace/panel/plain)
	var/x = 21
	for(var/variant in variants)
		var/turf/tile = locate(x++,22,1)
		tile = tile.ChangeTurf(variant)
		var/mob/living/carbon/human/occupant = new(tile)
		occupant.lying = TRUE
		occupants += occupant
		expect(!occupant.getFireLoss(), "Disabled shields shocked a crawlspace occupant.")

	var/turf/ordinary_tile = locate(25,22,1)
	ordinary_tile = ordinary_tile.ChangeTurf(/turf/simulated/open/crawlspace/maintenance)
	ordinary.contents.Add(ordinary_tile)
	var/mob/living/carbon/human/outside_maintenance = new(ordinary_tile)
	var/mob/living/carbon/human/on_floor = new(locate(26,22,1))
	var/turf/offstation_tile = locate(24,22,world.maxz)
	offstation_tile = offstation_tile.ChangeTurf(/turf/simulated/open/crawlspace)
	var/mob/living/carbon/human/offstation = new(offstation_tile)
	expect(!is_station_turf(offstation_tile), "Offstation fixture is on a station level.")

	generator.OnTopic(null, list("start_generator" = "1"))
	for(var/mob/living/carbon/human/occupant in occupants)
		expect(occupant.getFireLoss() > 0, "Shield startup did not shock an existing [occupant.loc.type] occupant.")
	expect(!outside_maintenance.getFireLoss() && !on_floor.getFireLoss() && !offstation.getFireLoss(), "Shields shocked a non-maintenance, ordinary-floor or offstation occupant.")

	var/mob/living/carbon/human/subject = occupants[1]
	var/damage = subject.getFireLoss()
	subject.forceMove(locate(21,21,1))
	subject.next_crawlspace_shock = 0
	subject.lying = TRUE
	expect(subject.Move(locate(21,22,1)), "Crawling entry failed.")
	expect(subject.getFireLoss() > damage, "Entering an electrified crawlspace did not shock the crawler.")
	damage = subject.getFireLoss()
	generator.shock_maintenance_crawlspaces()
	expect(subject.getFireLoss() == damage, "Repeated contact bypassed the shock cooldown.")

	subject.next_crawlspace_shock = 0
	generator.current_energy = generator.max_energy
	generator.Process()
	expect(subject.getFireLoss() > damage, "A stationary occupant was not shocked by generator processing.")
	damage = subject.getFireLoss()
	subject.next_crawlspace_shock = 0
	var/obj/machinery/power/shield_generator/second = new(locate(20,23,1))
	second.OnTopic(null, list("start_generator" = "1"))
	expect(subject.getFireLoss() > damage, "A second station generator did not power the hazard.")
	damage = subject.getFireLoss()
	generator.shock_maintenance_crawlspaces()
	expect(subject.getFireLoss() == damage, "Multiple generators bypassed the shared cooldown.")
	second.shutdown_field()

	generator.OnTopic(null, list("begin_shutdown" = "1"))
	subject.next_crawlspace_shock = 0
	expect(generator.shock_crawlspace_occupant(subject), "Discharging shields lost electrification before shutdown.")
	generator.shutdown_field()
	subject.next_crawlspace_shock = 0
	damage = subject.getFireLoss()
	generator.shock_maintenance_crawlspaces()
	expect(subject.getFireLoss() == damage && !generator.shock_crawlspace_occupant(subject), "Shutdown left crawlspaces electrified.")

	generator.running = SHIELD_RUNNING
	generator.overloaded = TRUE
	expect(!generator.shock_crawlspace_occupant(subject), "An overloaded generator electrified crawlspaces.")
	generator.overloaded = FALSE
	generator.forceMove(locate(20,20,world.maxz))
	expect(!generator.shock_crawlspace_occupant(subject), "An offstation generator electrified station crawlspaces.")
	generator.forceMove(locate(20,20,1))
	subject.status_flags |= GODMODE
	expect(!generator.shock_crawlspace_occupant(subject) && subject.getFireLoss() == damage, "Electrification bypassed normal electrocution immunity.")

	expect(GLOB.total_runtimes == baseline_runtimes, "Native runtime errors occurred during the checks.")
	world.log << "SHIELD_CRAWLSPACE_RESULT: [failures ? "FAIL" : "PASS"] failures=[failures] new_runtimes=[GLOB.total_runtimes - baseline_runtimes]"
	del(world)
