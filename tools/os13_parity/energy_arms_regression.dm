/area/os13_energy_arms_regression
	name = "Energy arms regression room"
	requires_power = FALSE
	dynamic_lighting = FALSE

/datum/os13_object_regression/proc/check_energy_arms_objects()
	var/area/room = new /area/os13_energy_arms_regression
	for(var/x = 100, x <= 108, x++)
		for(var/y = 30, y <= 34, y++)
			var/turf/tile = locate(x,y,1)
			tile = tile.ChangeTurf(/turf/unsimulated/floor)
			room.contents.Add(tile)
	var/turf/origin = locate(102,32,1)
	var/mob/living/carbon/human/user = new(origin)
	user.zone_sel = new /obj/screen/zone_sel(null)
	user.zone_sel.selecting = BP_CHEST
	user.skills[SKILL_RANGE] = 120
	var/datum/research/research = new
	var/datum/design/item/os13_energy_gun/gun_design = new
	var/datum/design/item/os13_energy_sword/sword_design = new
	var/datum/tech/os13/laser_gun/laser_tech = new
	var/datum/tech/os13/energy_gun/gun_tech = new
	var/datum/tech/os13/energy_sword/sword_tech = new
	var/obj/machinery/r_n_d/protolathe/replicator = new(locate(102,33,1))
	expect(!research.DesignHasReqs(gun_design) && !research.DesignHasReqs(sword_design), "Energy arms were fabricatable without their own technologies.")
	research.AddTech2Known(laser_tech)
	research.RefreshResearch()
	expect(!research.DesignHasReqs(gun_design) && !research.DesignHasReqs(sword_design), "Laser Gun discovery alone unlocked Energy Gun or Energy Sword products.")
	research.AddTech2Known(gun_tech)
	research.RefreshResearch()
	expect(research.DesignHasReqs(gun_design) && !research.DesignHasReqs(sword_design), "Energy Gun research failed to unlock its product separately from Energy Sword.")
	research.AddTech2Known(sword_tech)
	research.RefreshResearch()
	expect(research.DesignHasReqs(sword_design) && replicator.supports_design(gun_design) && replicator.supports_design(sword_design), "Energy arms research did not admit both physical Replicator designs.")
	var/obj/item/weapon/gun/energy/gun/os13/gun = gun_design.Fabricate(origin, replicator)
	var/obj/item/weapon/melee/energy/sword/os13/sword = sword_design.Fabricate(origin, replicator)
	expect(istype(gun) && gun.power_supply && !gun.power_supply.charge && gun.icon_state == "energy0" && gun.projectile_type == /obj/item/projectile/beam/stun, "Energy Gun fabrication created the wrong product, free charge or an unsafe initial mode.")
	expect(istype(sword) && !sword.active && sword.icon_state == "sword0" && !sword.sharp && !sword.edge && !sword.light_range, "Energy Sword fabrication created an active blade or incorrect inactive state.")
	qdel(replicator)
	qdel(research)
	qdel(gun_design)
	qdel(sword_design)
	qdel(laser_tech)
	qdel(gun_tech)
	qdel(sword_tech)
	world.log << "OS13_OBJECT_CHECK: separate Energy Gun/Sword named research gates and actual safe Replicator products"

	user.put_in_hands(gun)
	gun.safety = FALSE
	gun.power_supply.charge = gun.power_supply.maxcharge
	gun.update_icon()
	expect(gun.firemodes.len == 2 && gun.icon_state == "energy100" && gun.overlays.len, "Energy Gun lacks two real firing modes or composed charge/mode art.")
	var/mob/living/carbon/human/patient = new(locate(104,32,1))
	gun.Fire(patient, user)
	for(var/i = 1, i <= 10 && !patient.getHalLoss(), i++)
		sleep(1)
	expect(gun.shots_fired == 1 && gun.power_supply.charge == gun.power_supply.maxcharge - gun.charge_cost && patient.getHalLoss() > 0 && !patient.getFireLoss() && !patient.getBruteLoss(), "Actual stun-mode firing did not consume battery and cause native agony without physical wounds.")
	var/charge_before_selector = gun.power_supply.charge
	gun.attack_self(user)
	expect(gun.sel_mode == 2 && gun.projectile_type == /obj/item/projectile/beam && gun.power_supply.charge == charge_before_selector && gun.fire_sound == 'sound/weapons/Laser.ogg', "Energy Gun selector failed to change its real projectile/sound or consumed ammunition.")
	gun.next_fire_time = 0
	gun.Fire(patient, user)
	for(var/i = 1, i <= 10 && !patient.getFireLoss(), i++)
		sleep(1)
	expect(gun.shots_fired == 2 && patient.getFireLoss() > 0 && gun.power_supply.charge == gun.power_supply.maxcharge - 2 * gun.charge_cost, "Actual lethal-mode firing did not deliver a damaging laser and consume one shared battery shot.")
	qdel(patient)
	world.log << "OS13_OBJECT_CHECK: actual Energy Gun stun/laser body impacts, shared battery and real mode/sound selection"

	var/obj/structure/os13_rax_regression_target/target = new(locate(106,32,1))
	for(var/i = 3, i <= gun.max_shots, i++)
		gun.next_fire_time = 0
		gun.Fire(target, user)
	gun.next_fire_time = 0
	gun.Fire(target, user)
	expect(gun.shots_fired == gun.max_shots && !gun.power_supply.charge && gun.icon_state == "energy0", "Energy Gun exceeded its battery, failed to spend it or retained charged artwork.")
	gun.power_supply.charge = gun.charge_cost - 1
	gun.next_fire_time = 0
	gun.Fire(target, user)
	expect(gun.shots_fired == gun.max_shots && gun.power_supply.charge == gun.charge_cost - 1, "An incomplete Energy Gun charge produced or partially paid for a shot.")
	gun.power_supply.charge = 0
	for(var/i = 1, i <= 10, i++)
		gun.Process()
	expect(!gun.power_supply.charge, "Energy Gun self-recharged without a power source.")
	var/obj/machinery/recharger/charger = new(origin)
	charger.stat = 0
	gun.canremove = FALSE
	charger.attackby(gun, user)
	expect(gun.loc == user && !charger.charging, "Energy Gun recharge insertion bypassed refused inventory release.")
	gun.canremove = TRUE
	charger.attackby(gun, user)
	expect(charger.charging == gun && gun.loc == charger, "Standard station recharger did not accept the actual Energy Gun.")
	gun.attack_self(user)
	expect(gun.sel_mode == 2, "A remotely operated Energy Gun changed mode inside a charger.")
	charger.stat = NOPOWER
	charger.Process()
	expect(!gun.power_supply.charge, "An unpowered recharger supplied Energy Gun charge.")
	charger.stat = 0
	for(var/i = 1, i <= 200 && !gun.power_supply.fully_charged(), i++)
		charger.Process()
	charger.attack_hand(user)
	expect(gun.loc == user && gun.power_supply.fully_charged() && gun.sel_mode == 2 && gun.projectile_type == /obj/item/projectile/beam && gun.icon_state == "energy100", "Recharge/retrieval replaced the Energy Gun, lost its mode or failed to restore actual power.")
	gun.firing = TRUE
	gun.attack_self(user)
	expect(gun.sel_mode == 2, "Energy Gun changed mode while firing.")
	gun.firing = FALSE
	gun.attack_self(user)
	expect(gun.sel_mode == 1 && gun.projectile_type == /obj/item/projectile/beam/stun, "Energy Gun selector failed to cycle back to stun.")
	user.drop_from_inventory(gun)
	gun.next_fire_time = 0
	var/remaining = gun.power_supply.charge
	gun.Fire(target, user)
	gun.attack_self(user)
	expect(gun.power_supply.charge == remaining && gun.sel_mode == 1, "A dropped Energy Gun could fire or change mode remotely.")
	var/obj/item/cell/battery = gun.power_supply
	gun.power_supply = null
	gun.update_icon()
	gun.examine(user)
	expect(gun.icon_state == "energy_empty" && !gun.overlays.len, "A missing Energy Gun battery retained charged/mode artwork.")
	gun.power_supply = battery
	qdel(gun)
	qdel(charger)
	qdel(target)
	world.log << "OS13_OBJECT_CHECK: Energy Gun depletion, bounded station recharge, ownership, mode retention and missing battery"

	sword.attack_self(user)
	expect(!sword.active && !sword.light_range, "An unheld Energy Sword activated remotely.")
	user.put_in_hands(sword)
	sword.attack_self(user)
	expect(sword.active && sword.force == sword.active_force && sword.sharp && sword.edge && sword.icon_state == "sword1" && sword.item_state == "sword1" && sword.light_range > 0 && sword.get_storage_cost() == ITEM_SIZE_NO_CONTAINER, "Energy Sword activation failed to extend a real lit, damaging, non-storable blade.")
	var/mob/living/simple_animal/melee_target = new(locate(103,32,1))
	melee_target.maxHealth = 1000
	melee_target.health = 1000
	melee_target.stop_automated_movement = TRUE
	var/before_health = melee_target.health
	sword.next_attack_time = 0
	sword.attack(melee_target, user, BP_CHEST)
	expect(melee_target.health < before_health, "The active Energy Sword failed to deal actual melee damage through the ordinary attack pipeline.")
	sword.attack_self(user)
	expect(!sword.active && sword.force == initial(sword.force) && !sword.sharp && !sword.edge && sword.item_state == "sword0" && !sword.light_range && sword.get_storage_cost() != ITEM_SIZE_NO_CONTAINER, "Energy Sword deactivation retained blade damage, sharpness, light or storage restriction.")
	world.log << "OS13_OBJECT_CHECK: real Energy Sword activation, supplied world/hand states, light, storage restrictions and melee damage"

	sword.attack_self(user)
	user.drop_from_inventory(sword)
	expect(!sword.active && sword.icon_state == "sword0" && !sword.light_range, "Dropping an Energy Sword left a live blade on the floor.")
	before_health = melee_target.health
	sword.next_attack_time = 0
	sword.attack(melee_target, user, BP_CHEST)
	expect(melee_target.health == before_health, "A floor Energy Sword dealt a remote melee hit.")
	user.put_in_hands(sword)
	sword.attack_self(user)
	melee_target.forceMove(locate(107,32,1))
	sword.next_attack_time = 0
	sword.attack(melee_target, user, BP_CHEST)
	expect(melee_target.health == before_health, "A held Energy Sword struck outside physical melee reach.")
	user.Stun(5)
	sword.attack_self(user)
	expect(sword.active, "An incapacitated user could operate the Energy Sword selector.")
	sword.deactivate(user)
	qdel(melee_target)
	qdel(sword)
	qdel(user)
	world.log << "OS13_OBJECT_CHECK: Energy Sword drop safety, physical ownership/reach and incapacitated control refusal"
