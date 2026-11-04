/datum/os13_object_regression/proc/check_weapon_objects()
	var/turf/origin = locate(180,40,world.maxz)
	for(var/turf/tile in range(5, origin))
		tile.ChangeTurf(/turf/unsimulated/floor)
	origin = locate(180,40,world.maxz)
	var/mob/living/carbon/human/user = new(origin)
	user.zone_sel = new /obj/screen/zone_sel(null)
	user.zone_sel.selecting = BP_CHEST
	user.skills[SKILL_RANGE] = 120
	var/obj/structure/target = new(locate(184,40,world.maxz))
	target.density = TRUE
	var/obj/item/weapon/gun/projectile/revolver/os13_nt5/nt5 = new(origin)
	var/obj/item/ammo_magazine/a357/loader = new(origin)
	user.put_in_hands(nt5)
	user.put_in_hands(loader)
	var/loader_rounds = loader.stored_ammo.len
	expect(!nt5.load_ammo(loader, user) && loader.stored_ammo.len == loader_rounds && !nt5.loaded.len, "Closed NT5 accepted ammunition or consumed the loader.")
	nt5.attack_self(user)
	expect(nt5.cylinder_open && nt5.load_ammo(loader, user) && nt5.live_rounds() == nt5.max_shells && !loader.stored_ammo.len && loader.loc == user, "Opening and speed-loading did not move the original casings while retaining the loader.")
	var/rounds = nt5.live_rounds()
	expect(!nt5.consume_next_projectile() && nt5.live_rounds() == rounds && !nt5.chambered, "Open NT5 consumed or chambered a projectile.")
	nt5.safety = FALSE
	nt5.Fire(target, user)
	expect(nt5.live_rounds() == rounds, "Normal Fire bypassed the open-cylinder guard.")
	nt5.attack_self(user)
	for(var/shot = 1, shot <= nt5.max_shells, shot++)
		nt5.next_fire_time = 0
		nt5.Fire(target, user)
		expect(nt5.live_rounds() == rounds - shot, "NT5 shot [shot] did not consume exactly one live round.")
	expect(nt5.loaded.len == rounds && !nt5.chambered, "NT5 firing lost spent cases or left an extra chambered casing.")
	var/shots_fired = nt5.shots_fired
	nt5.next_fire_time = 0
	nt5.Fire(target, user)
	expect(nt5.shots_fired == shots_fired && !nt5.live_rounds(), "Empty NT5 generated a shot.")
	nt5.unload_ammo(user)
	expect(nt5.loaded.len == rounds, "Closed NT5 dumped its spent cases.")
	nt5.attack_self(user)
	nt5.unload_ammo(user)
	expect(!nt5.loaded.len && nt5.icon_state == "revolver3_open0", "Open NT5 did not unload to its empty-cylinder state.")
	user.drop_from_inventory(loader)
	var/obj/item/ammo_casing/a9mm/wrong_round = new(origin)
	user.put_in_hands(wrong_round)
	expect(!nt5.load_ammo(wrong_round, user) && wrong_round.loc == user && !nt5.loaded.len, "Wrong-caliber round moved or entered the NT5.")
	user.drop_from_inventory(wrong_round)
	var/obj/item/ammo_casing/a357/stuck_round = new(origin)
	user.put_in_hands(stuck_round)
	stuck_round.canremove = FALSE
	expect(!nt5.load_ammo(stuck_round, user) && stuck_round.loc == user && !nt5.loaded.len, "A refused inventory removal still loaded the NT5.")
	stuck_round.canremove = TRUE
	expect(nt5.load_ammo(stuck_round, user) && stuck_round.loc == nt5 && nt5.live_rounds() == 1, "Single-round loading did not commit the actual held casing.")
	user.drop_from_inventory(nt5)
	nt5.attack_self(user)
	expect(nt5.cylinder_open, "A gun on the floor accepted a held-only cylinder action.")
	qdel(nt5)
	world.log << "OS13_OBJECT_CHECK: NT5 cylinder, actual firing, case conservation and ownership"

	var/obj/item/weapon/gun/energy/laser/os13_tnc/laser = new(origin)
	user.put_in_hands(laser)
	laser.safety = FALSE
	var/initial_charge = laser.power_supply.charge
	var/available_shots = floor(initial_charge / laser.charge_cost)
	for(var/shot = 1, shot <= available_shots, shot++)
		laser.next_fire_time = 0
		laser.Fire(target, user)
		expect(laser.power_supply.charge == initial_charge - shot * laser.charge_cost, "Laser shot [shot] did not consume the actual cell charge.")
	expect(laser.icon_state == "laser0", "Depleted TNC Laser Gun did not display its zero-charge art.")
	shots_fired = laser.shots_fired
	laser.next_fire_time = 0
	laser.Fire(target, user)
	expect(laser.shots_fired == shots_fired, "Depleted laser fired without energy.")
	var/obj/item/cell/old_cell = laser.power_supply
	expect(laser.eject_cell(user) && !laser.power_supply && old_cell.loc == user && laser.icon_state == "laser_empty", "Cell ejection lost the physical cell or did not expose the empty bracket.")
	laser.examine(user)
	expect(!laser.consume_next_projectile(), "Cell-less laser created a projectile.")
	old_cell.charge = old_cell.maxcharge / 2
	laser.attackby(old_cell, user)
	expect(laser.power_supply == old_cell && old_cell.loc == laser && old_cell.charge == old_cell.maxcharge / 2, "Delayed cell installation lost charge or loaded a different cell.")
	var/stored_charge = old_cell.charge
	for(var/i = 1, i <= 10, i++)
		laser.Process()
	expect(old_cell.charge == stored_charge, "Laser self-recharged without an external source.")
	laser.firing = TRUE
	expect(!laser.eject_cell(user) && laser.power_supply == old_cell, "Cell removal bypassed an active firing action.")
	laser.firing = FALSE
	laser.eject_cell(user)
	spawn(1)
		user.drop_from_inventory(old_cell)
	laser.attackby(old_cell, user)
	expect(!laser.power_supply && old_cell.loc == origin, "Interrupted reload installed a dropped cell.")
	qdel(laser)
	world.log << "OS13_OBJECT_CHECK: TNC laser firing, depletion, physical cell replacement and interrupted reload"

	var/datum/research/research = new
	var/datum/design/item/os13_tnc_laser/laser_design = new
	var/datum/design/item/os13_distress_beacon/beacon_design = new
	expect(!research.DesignHasReqs(laser_design) && !research.DesignHasReqs(beacon_design), "OS13 products unlocked before their named technologies were installed.")
	var/datum/tech/os13/laser_gun/laser_technology = new
	var/datum/tech/os13/distress_beacon/beacon_technology = new
	expect(research.AddTech2Known(laser_technology) && research.AddTech2Known(beacon_technology), "Source technology imports did not reach the research holder.")
	research.RefreshResearch()
	expect(research.DesignHasReqs(laser_design) && research.DesignHasReqs(beacon_design), "Installing Laser Gun or Distress Beacon did not unlock its real product.")
	var/obj/machinery/r_n_d/protolathe/replicator = new(origin)
	expect(replicator.supports_design(laser_design) && replicator.supports_design(beacon_design), "OS13 Replicator whitelist excludes the new physical products.")
	var/obj/item/weapon/gun/energy/laser/os13_tnc/fabricated = laser_design.Fabricate(origin, replicator)
	expect(istype(fabricated) && fabricated.power_supply && !fabricated.power_supply.charge && fabricated.icon_state == "laser0", "Fabrication created free power or the wrong laser product.")
	qdel(fabricated)
	qdel(replicator)
	qdel(laser_design)
	qdel(beacon_design)
	qdel(laser_technology)
	qdel(beacon_technology)
	qdel(research)
	qdel(user)
	qdel(target)
	world.log << "OS13_OBJECT_CHECK: named research imports, Replicator eligibility and uncharged laser fabrication"
