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
	check.run_checks()

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

/datum/shield_crawlspace_regression/proc/run_checks()
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

	generator.shutdown_field()
	check_child_crawlspaces()
	expect(GLOB.total_runtimes == baseline_runtimes, "Native runtime errors occurred during the checks.")
	world.log << "SHIELD_CRAWLSPACE_RESULT: [failures ? "FAIL" : "PASS"] failures=[failures] new_runtimes=[GLOB.total_runtimes - baseline_runtimes]"
	del(world)

/datum/shield_crawlspace_regression/proc/check_child_crawlspaces()
	var/turf/start = locate(22,24,1)
	var/turf/passage = locate(23,24,1)
	passage = passage.ChangeTurf(/turf/simulated/open/crawlspace/maintenance)
	var/turf/hatch = locate(24,24,1)
	hatch = hatch.ChangeTurf(/turf/simulated/open/crawlspace/hatch)
	var/turf/panel = locate(25,24,1)
	panel = panel.ChangeTurf(/turf/simulated/open/crawlspace/panel/directional)
	var/turf/exit = locate(26,24,1)
	var/mob/living/carbon/human/cadet = new(start)
	cadet.mind_initialize()
	cadet.age = 56
	job_master.EquipRank(cadet, "Cadet", FALSE, TRUE)
	expect(cadet.is_child() && cadet.mob_size == MOB_SMALL && cadet.age >= 10 && cadet.age <= 14 && cadet.maxHealth == 80, "Round-start Cadet retained an adult body or age.")
	var/mob/living/carbon/human/late_cadet = new(start)
	late_cadet.mind_initialize()
	late_cadet.gender = FEMALE
	late_cadet.age = 45
	job_master.EquipRank(late_cadet, "Cadet", TRUE, TRUE)
	expect(late_cadet.is_child() && late_cadet.age >= 10 && late_cadet.age <= 14 && late_cadet.gender == FEMALE, "Late-join Cadet did not retain their gender in a child body.")
	for(var/mob/living/carbon/human/child in list(cadet, late_cadet))
		var/list/starting_gear = child.get_equipped_items(TRUE)
		expect(child.get_medical_bracelet() && starting_gear.len == 1 && !child.worn_underwear.len && !child.backpack_setup, "[child == cadet ? "Round-start" : "Late-join"] Cadet did not spawn with only a medical bracelet.")
		child.regenerate_icons()
		var/list/body_states = icon_states(child.species.get_icobase(child))
		for(var/obj/item/organ/external/limb in child.organs)
			limb.get_icon()
			expect(limb.icon_state in body_states, "[child.gender] child limb [limb.icon_name] referenced an absent sprite.")
			limb.status |= ORGAN_MUTATED
			limb.get_icon()
			var/deformed_sheet = limb.organ_tag == BP_L_FOOT ? child.species.icobase : child.species.deform
			expect(limb.icon_state in icon_states(deformed_sheet), "[child.gender] mutated child limb [limb.icon_name] referenced an absent sprite.")
			limb.status &= ~ORGAN_MUTATED
		child.mutations |= SKELETON
		for(var/obj/item/organ/external/limb in child.organs)
			limb.get_icon()
			var/skeleton_sheet = limb.organ_tag == BP_GROIN ? 'icons/os13/child/overlays.dmi' : 'icons/os13/mob/mob/flesh/skeleton_child.dmi'
			expect(limb.icon_state in icon_states(skeleton_sheet), "[child.gender] child skeleton [limb.icon_name] referenced an absent sprite.")
		child.mutations -= SKELETON
		child.regenerate_icons()
		var/obj/item/organ/external/head_organ = child.get_organ(BP_HEAD)
		for(var/stage in SURGERY_OPEN to SURGERY_ENCASED)
			var/incision_state = child.species.get_surgery_icon_state(head_organ, stage)
			expect(incision_state in icon_states(child.species.surgery_overlays), "[child.gender] child head incision stage [stage] lacked a fitted sprite.")
		var/obj/item/uniform = new /obj/item/clothing/under/os13_child(start)
		var/obj/item/shoes = new /obj/item/clothing/shoes/os13_child(start)
		expect(uniform && (uniform.get_icon_state(child, slot_w_uniform_str) in icon_states(uniform.item_icons[slot_w_uniform_str])), "The child uniform lacked its worn sprite.")
		expect(shoes && (shoes.get_icon_state(child, slot_shoes_str) in icon_states(shoes.item_icons[slot_shoes_str])), "The child shoes lacked their worn sprite.")
		qdel(uniform)
		qdel(shoes)
	qdel(late_cadet)
	cadet.forceMove(start)
	expect(cadet.Move(passage) && cadet.loc == passage && !cadet.lying, "An upright Cadet could not walk into a crawlspace.")
	var/obj/machinery/door/airlock/maintenance/door = new(hatch)
	door.welded = TRUE
	expect(!cadet.Move(hatch) && cadet.loc == passage, "Child crawlspace access bypassed a welded airlock.")
	qdel(door)
	expect(cadet.Move(hatch) && cadet.Move(panel) && cadet.Move(exit) && cadet.loc == exit && !cadet.lying, "An upright child failed to walk through and out of hatch and panel crawlspaces.")
	var/turf/wardrobe_tile = locate(122, 122, 1)
	var/obj/structure/closet/os13/nt/wardrobe = locate() in wardrobe_tile
	var/obj/item/clothing/under/os13_child/cadet/cadet_uniform = wardrobe ? (locate(/obj/item/clothing/under/os13_child/cadet) in wardrobe) : null
	expect(cadet_uniform, "The NT closet outside cryo lacked the Cadet uniform.")
	if(cadet_uniform)
		expect(wardrobe.open() && cadet_uniform.loc == wardrobe_tile, "Opening the cryo hallway closet did not release the Cadet uniform.")
		expect(cadet.equip_to_slot_if_possible(cadet_uniform, slot_w_uniform) && cadet.w_uniform == cadet_uniform, "A Cadet could not wear the uniform from the closet.")
		var/image/uniform_art = cadet.overlays_standing[UNIFORM_LAYER]
		expect(uniform_art?.icon == 'icons/os13/child/overlays.dmi' && uniform_art.icon_state == "cadet_s", "The Cadet uniform used the wrong worn sprite.")
	qdel(cadet)
	var/mob/living/carbon/human/adult = new(start)
	adult.mob_size = MOB_SMALL
	expect(!adult.Move(passage) && adult.loc == start, "Small adult could walk upright into a crawlspace.")
	var/obj/item/clothing/under/os13_child/uniform = new(start)
	expect(!adult.equip_to_slot_if_possible(uniform, slot_w_uniform), "An adult could wear the fitted child uniform.")
	adult.lying = TRUE
	expect(adult.Move(passage) && adult.loc == passage, "An adult could no longer crawl into a crawlspace.")
	qdel(uniform)
	qdel(adult)
	world.log << "CHILD_CRAWLSPACE_CHECK: Cadet round-start and late-join bodies and bracelet-only spawns, child movement, hatch collision and adult crawling"
