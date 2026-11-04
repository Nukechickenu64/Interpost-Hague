/area/os13_stun_mine_regression
	name = "Stun Mine regression room"
	requires_power = FALSE
	dynamic_lighting = FALSE
	has_gravity = TRUE

/obj/item/clothing/shoes/os13_stun_mine_regression
	siemens_coefficient = 0
	body_parts_covered = FEET

/datum/os13_object_regression/proc/check_stun_mine_objects()
	var/area/room = new /area/os13_stun_mine_regression
	for(var/x = 90, x <= 97, x++)
		for(var/y = 30, y <= 34, y++)
			var/turf/tile = locate(x,y,1)
			tile = tile.ChangeTurf(/turf/unsimulated/floor)
			room.contents.Add(tile)
	var/turf/site = locate(94,32,1)
	var/turf/approach = locate(95,32,1)
	var/turf/operator_tile = locate(93,32,1)
	var/mob/living/carbon/human/user = new(site)
	var/datum/research/research = new
	var/datum/design/item/os13_stun_mine/design = new
	var/datum/tech/os13/stun_mine/technology = new
	var/obj/machinery/r_n_d/protolathe/replicator = new(operator_tile)
	expect(!research.DesignHasReqs(design), "Stun Mine fabrication was available without its named technology.")
	research.AddTech2Known(technology)
	research.RefreshResearch()
	expect(research.DesignHasReqs(design) && replicator.supports_design(design), "Stun Mine research failed to admit the physical Replicator product.")
	var/obj/item/device/os13_stun_mine/mine = design.Fabricate(site, replicator)
	expect(istype(mine) && !mine.armed && !mine.spent && !mine.anchored && mine.icon_state == "mine", "Replicator failed to produce an inactive, unused physical Stun Mine.")
	qdel(replicator)
	qdel(research)
	qdel(design)
	qdel(technology)
	world.log << "OS13_OBJECT_CHECK: named Stun Mine research gate and inactive physical Replicator output"

	user.put_in_hands(mine)
	mine.canremove = FALSE
	mine.attack_self(user)
	expect(mine.loc == user && !mine.busy && !mine.armed, "Stun Mine deployment bypassed refused inventory release.")
	mine.canremove = TRUE
	spawn(1)
		user.forceMove(operator_tile)
	expect(!mine.attack_self(user) && mine.loc == site && !mine.armed && !mine.busy && !mine.anchored, "Interrupted Stun Mine deployment armed, consumed or locked the device.")
	expect(mine.arm(user) && mine.armed && mine.anchored && mine.icon_state == "mine1", "Completed Stun Mine arming did not produce its anchored ready state.")
	var/obj/item/screwdriver/tool = new(approach)
	tool.Move(site)
	expect(mine.armed && !mine.spent, "A loose tool consumed a contact Stun Mine.")
	var/mob/living/carbon/human/victim = new(approach)
	// Use real area gravity rather than a floating animation flag turf entry resets.
	room.has_gravity = FALSE
	victim.update_floating()
	victim.Move(site)
	expect(mine.armed && !mine.spent && !victim.stunned, "A zero-gravity crossing triggered the pressure-contact Stun Mine.")
	victim.forceMove(approach)
	room.has_gravity = TRUE
	victim.update_floating()
	victim.stat = DEAD
	victim.Move(site)
	expect(mine.armed && !mine.spent, "A dead body triggered the Stun Mine.")
	victim.forceMove(approach)
	victim.stat = CONSCIOUS
	expect(victim.Move(site), "Contact victim could not actually move onto the Stun Mine tile.")
	expect(mine.spent && !mine.armed && !mine.anchored && !mine.busy && mine.icon_state == "mine" && victim.stunned > 0 && victim.weakened > 0, "Actual contact did not spend the original mine and apply native stun/weakness.")
	var/mob/living/carbon/human/second = new(approach)
	second.Move(site)
	expect(!second.stunned && !mine.arm(user) && mine.spent, "A spent Stun Mine discharged again or could be rearmed.")
	qdel(victim)
	qdel(second)
	qdel(tool)
	qdel(mine)
	world.log << "OS13_OBJECT_CHECK: physical deployment, refused release, interrupted arming, real contact stun and exactly one discharge"

	mine = new(site)
	expect(mine.arm(user), "Disarm fixture did not arm.")
	spawn(1)
		user.forceMove(locate(91,32,1))
	expect(!mine.disarm(user) && mine.armed && mine.anchored && !mine.busy && !mine.spent, "Interrupted disarming cleared, spent or unlocked the armed mine.")
	user.forceMove(operator_tile)
	expect(mine.disarm(user) && !mine.armed && !mine.spent && !mine.anchored && !mine.busy, "Completed disarming did not preserve an unused recoverable mine.")
	mine.attack_hand(user)
	expect(mine.loc == user, "Disarmed mine could not be physically recovered.")
	expect(mine.attack_self(user) && mine.armed && mine.loc == operator_tile, "A safely disarmed unused mine could not be deployed again.")
	mine.forceMove(site)
	expect(!mine.armed && !mine.busy && !mine.anchored && !mine.spent && !mine.armed_turf, "Forced relocation left a portable active mine.")
	expect(mine.arm(user), "Relocated inactive mine could not be deliberately armed again.")
	victim = new(approach)
	spawn(1)
		expect(!mine.arm(user) && !mine.disarm(user), "Concurrent operation bypassed the Stun Mine action lock.")
		victim.Move(site)
	expect(!mine.disarm(user) && mine.spent && !mine.armed && !mine.busy && victim.stunned > 0, "A pending disarm restored a mine discharged during the procedure.")
	qdel(victim)
	qdel(mine)
	world.log << "OS13_OBJECT_CHECK: interrupted/successful disarming, recovery, relocation safety and trigger-during-disarm invalidation"

	mine = new(site)
	spawn(1)
		mine.forceMove(approach)
	expect(!mine.arm(user) && !mine.armed && !mine.busy && !mine.anchored && mine.loc == approach, "A relocated arming action armed the mine at its new location.")
	user.forceMove(site)
	expect(mine.arm(user), "Container safety fixture could not arm.")
	var/obj/item/storage/backpack/bag = new(site)
	mine.forceMove(bag)
	victim = new(locate(96,32,1))
	victim.Move(approach)
	expect(!mine.armed && !mine.busy && !mine.spent && !victim.stunned, "A mine relocated into storage remained active or triggered through its container.")
	expect(!mine.arm(user), "A contained Stun Mine could be armed.")
	var/turf/open_space = locate(90,29,1)
	open_space = open_space.ChangeTurf(/turf/space)
	var/obj/item/device/os13_stun_mine/space_mine = new(open_space)
	user.forceMove(get_turf(space_mine))
	expect(!space_mine.arm(user) && !space_mine.busy && !space_mine.armed, "A Stun Mine armed directly on open space.")
	qdel(space_mine)
	qdel(victim)
	qdel(bag)
	user.forceMove(operator_tile)
	mine = new(site)
	expect(mine.arm(user), "Electrical protection fixture could not arm.")
	victim = new(approach)
	var/obj/item/clothing/shoes/os13_stun_mine_regression/boots = new(approach)
	expect(victim.equip_to_slot_if_possible(boots, slot_shoes), "Electrical protection fixture could not equip its insulating boots.")
	victim.Move(site)
	expect(mine.spent && !victim.stunned && !victim.weakened, "The Stun Mine bypassed the actual foot's electrical protection.")
	qdel(mine)
	qdel(victim)
	qdel(user)
	world.log << "OS13_OBJECT_CHECK: moved arming operation, storage containment, invalid-floor refusal and actual electrical protection"
