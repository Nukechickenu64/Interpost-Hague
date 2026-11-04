/area/os13_gravpulser_regression
	name = "Gravpulser regression room"
	requires_power = FALSE
	dynamic_lighting = FALSE

/obj/item/clothing/suit/armor/os13_gravpulser_regression
	armor = list(melee = 100, bullet = 100, laser = 100, energy = 100, bomb = 100, bio = 100, rad = 100)

/datum/os13_object_regression/proc/check_gravpulser_objects()
	var/area/room = new /area/os13_gravpulser_regression
	for(var/x = 80, x <= 87, x++)
		for(var/y = 30, y <= 34, y++)
			var/turf/tile = locate(x,y,1)
			tile = tile.ChangeTurf(/turf/unsimulated/floor)
			room.contents.Add(tile)
	var/turf/origin = locate(82,32,1)
	var/mob/living/carbon/human/user = new(origin)
	user.zone_sel = new /obj/screen/zone_sel(null)
	user.zone_sel.selecting = BP_CHEST
	user.skills[SKILL_RANGE] = 120
	var/obj/structure/os13_rax_regression_target/target = new(locate(84,32,1))
	var/obj/item/weapon/gun/energy/os13_heavy_gravpulser/gun = new(origin)
	user.put_in_hands(gun)
	gun.safety = FALSE
	expect(gun.power_supply && gun.power_supply.maxcharge == gun.charge_cost * 5 && gun.icon_state == "gravrifle", "Heavy Gravpulser did not initialize its real five-shot battery.")
	for(var/shot = 1, shot <= 5, shot++)
		gun.next_fire_time = 0
		gun.Fire(target, user)
		expect(gun.power_supply.charge == (5 - shot) * gun.charge_cost && gun.shots_fired == shot, "Gravpulser shot [shot] did not consume exactly one fifth of the full battery.")
	gun.next_fire_time = 0
	gun.Fire(target, user)
	expect(!gun.power_supply.charge && gun.shots_fired == 5 && gun.icon_state == "gravrifle_empty", "A depleted Gravpulser produced a sixth shot or retained ready art.")
	for(var/i = 1, i <= 20 && !target.impacts, i++)
		sleep(1)
	expect(target.impacts && target.delivered_damage > 0 && target.last_projectile == /obj/item/projectile/energy/os13_gravsphere, "Heavy Gravpulser did not deliver an actual damaging gravsphere to a physical target.")
	gun.power_supply.charge = gun.charge_cost - 1
	gun.next_fire_time = 0
	gun.Fire(target, user)
	expect(gun.power_supply.charge == gun.charge_cost - 1, "An incomplete Gravpulser charge was partially spent on a failed shot.")
	gun.power_supply.charge = 0
	for(var/i = 1, i <= 10, i++)
		gun.Process()
	expect(!gun.power_supply.charge, "Heavy Gravpulser recharged itself without an energy source.")
	world.log << "OS13_OBJECT_CHECK: real Heavy Gravpulser delivery, exactly five battery shots, depletion and no self-recharge"

	var/obj/machinery/recharger/charger = new(locate(83,32,1))
	charger.stat = 0
	gun.canremove = FALSE
	charger.attackby(gun, user)
	expect(!charger.charging && gun.loc == user, "A refused inventory release still inserted the Gravpulser into a charger.")
	gun.canremove = TRUE
	charger.attackby(gun, user)
	expect(charger.charging == gun && gun.loc == charger, "The standard station recharger refused the actual Gravpulser.")
	charger.stat = NOPOWER
	charger.Process()
	expect(!gun.power_supply.charge, "An unpowered station recharger supplied Gravpulser energy.")
	charger.stat = 0
	for(var/i = 1, i <= 200 && !gun.power_supply.fully_charged(), i++)
		charger.Process()
	expect(gun.power_supply.charge == gun.charge_cost * 5 && charger.use_power == POWER_USE_ACTIVE, "Powered standard recharge failed to restore the bounded five-shot battery.")
	charger.attack_hand(user)
	expect(!charger.charging && gun.loc == user && gun.icon_state == "gravrifle", "Recharger retrieval did not return the real weapon with its restored ready state.")
	var/obj/item/cell/high/foreign_cell = new(origin)
	user.put_in_hands(foreign_cell)
	var/obj/item/cell/battery = gun.power_supply
	gun.attackby(foreign_cell, user)
	expect(foreign_cell.loc == user && gun.power_supply == battery && gun.power_supply.maxcharge == gun.charge_cost * 5, "An unsupported high-capacity cell bypassed the fixed five-shot configuration.")
	qdel(foreign_cell)
	gun.power_supply = null
	gun.update_icon()
	gun.next_fire_time = 0
	gun.Fire(target, user)
	gun.examine(user)
	expect(gun.icon_state == "gravrifle_empty", "A missing Gravpulser battery retained a usable/ready appearance.")
	gun.power_supply = battery
	gun.update_icon()
	world.log << "OS13_OBJECT_CHECK: actual station recharge, powerless/refused insertion, physical retrieval and bounded battery compatibility"

	var/mob/living/carbon/human/armored = new(locate(82,33,1))
	var/mob/living/carbon/human/unarmored = new(locate(83,33,1))
	var/obj/item/clothing/suit/armor/os13_gravpulser_regression/armor = new(get_turf(armored))
	expect(armored.equip_to_slot_if_possible(armor, slot_wear_suit), "Armor-bypass fixture could not equip its protective vest.")
	var/obj/item/projectile/bullet/control = new(origin)
	control.damage = 25
	control.armor_penetration = 0
	var/normal_block = armored.bullet_act(control, BP_CHEST)
	expect(normal_block == 100 && !armored.getBruteLoss(), "The comparison armor did not block the ordinary control projectile.")
	var/obj/item/projectile/energy/os13_gravsphere/sphere = new(origin)
	var/grav_block = armored.bullet_act(sphere, BP_CHEST)
	var/obj/item/projectile/energy/os13_gravsphere/other_sphere = new(origin)
	unarmored.bullet_act(other_sphere, BP_CHEST)
	expect(!grav_block && armored.getBruteLoss() > 0 && armored.getBruteLoss() == unarmored.getBruteLoss(), "Actual gravsphere body damage was reduced by conventional armor.")
	qdel(control)
	qdel(sphere)
	qdel(other_sphere)
	qdel(armored)
	qdel(unarmored)
	// Armor bypass must not imply passage through dense station walls.
	target.forceMove(locate(86,32,1))
	target.impacts = 0
	var/turf/barrier = locate(85,32,1)
	barrier.ChangeTurf(/turf/simulated/wall)
	gun.next_fire_time = 0
	gun.Fire(target, user)
	sleep(20)
	expect(gun.power_supply.charge == gun.charge_cost * 4 && !target.impacts, "A gravsphere either bypassed a dense wall or never consumed its shot.")
	world.log << "OS13_OBJECT_CHECK: native armored/unarmored human impacts, conventional armor bypass and dense-wall collision"

	var/datum/research/research = new
	var/datum/design/item/os13_heavy_gravpulser/design = new
	var/datum/tech/os13/gravcutter/precursor = new
	var/datum/tech/os13/heavy_gravpulser/technology = new
	expect(!research.DesignHasReqs(design), "Heavy Gravpulser fabrication was available without its own technology.")
	research.AddTech2Known(precursor)
	research.RefreshResearch()
	expect(!research.DesignHasReqs(design), "Gravcutter discovery alone unlocked the unrecovered Heavy Gravpulser product.")
	research.AddTech2Known(technology)
	research.RefreshResearch()
	var/obj/machinery/r_n_d/protolathe/replicator = new(origin)
	expect(research.DesignHasReqs(design) && replicator.supports_design(design), "Heavy Gravpulser research did not admit its physical Replicator design.")
	var/obj/item/weapon/gun/energy/os13_heavy_gravpulser/fabricated = design.Fabricate(origin, replicator)
	expect(istype(fabricated) && fabricated.power_supply.maxcharge == fabricated.charge_cost * 5 && !fabricated.power_supply.charge && fabricated.icon_state == "gravrifle_empty", "Fabrication created the wrong product, free electrical charge or an unbounded battery.")
	qdel(fabricated)
	qdel(replicator)
	qdel(research)
	qdel(design)
	qdel(precursor)
	qdel(technology)
	qdel(gun)
	qdel(charger)
	qdel(user)
	qdel(target)
	world.log << "OS13_OBJECT_CHECK: named Heavy Gravpulser research gating and physically uncharged Replicator output"
