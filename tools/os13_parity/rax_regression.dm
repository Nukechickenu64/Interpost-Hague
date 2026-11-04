/obj/structure/os13_rax_regression_target
	name = "shotgun regression target"
	density = TRUE
	var/impacts = 0
	var/last_projectile
	var/delivered_damage = 0

/obj/structure/os13_rax_regression_target/bullet_act(obj/item/projectile/projectile, def_zone)
	impacts++
	last_projectile = projectile.type
	delivered_damage += projectile.get_structure_damage()
	return 0

/datum/os13_object_regression/proc/check_rax_objects()
	var/turf/origin = locate(180,50,world.maxz)
	for(var/turf/tile in range(4, origin))
		tile.ChangeTurf(/turf/unsimulated/floor)
	origin = locate(180,50,world.maxz)
	var/mob/living/carbon/human/user = new(origin)
	user.zone_sel = new /obj/screen/zone_sel(null)
	user.zone_sel.selecting = BP_CHEST
	user.skills[SKILL_RANGE] = 120
	var/obj/structure/os13_rax_regression_target/target = new(locate(182,50,world.maxz))
	var/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/rax = new(origin)
	user.put_in_hands(rax)
	rax.safety = FALSE
	expect(!rax.loaded.len && !rax.chambered, "RAX starts with unsupplied ammunition.")
	var/obj/item/ammo_casing/a357/wrong = new(origin)
	user.put_in_hands(wrong)
	expect(!rax.load_ammo(wrong, user) && wrong.loc == user && !rax.loaded.len, "RAX accepted or consumed wrong-calibre ammunition.")
	qdel(wrong)
	var/list/casings = list()
	var/obj/item/ammo_casing/shotgun/pellet/os13/shell = new(origin)
	casings += shell
	user.put_in_hands(shell)
	shell.canremove = FALSE
	expect(!rax.load_ammo(shell, user) && shell.loc == user && shell.BB, "Refused inventory removal still loaded or consumed a RAX shell.")
	shell.canremove = TRUE
	expect(rax.load_ammo(shell, user) && shell.loc == rax && shell.BB, "RAX did not load the original held casing and pellet payload.")
	rax.Fire(target, user)
	expect(!rax.shots_fired && !rax.chambered && rax.loaded.len == 1 && shell.BB, "RAX fired directly from the tube without pumping.")
	for(var/i = 2, i <= rax.max_shells, i++)
		shell = new(origin)
		casings += shell
		user.put_in_hands(shell)
		expect(rax.load_ammo(shell, user), "RAX refused a compatible shell before its tube was full.")
	var/obj/item/ammo_casing/shotgun/pellet/os13/overflow = new(origin)
	user.put_in_hands(overflow)
	expect(!rax.load_ammo(overflow, user) && overflow.loc == user && rax.loaded.len == rax.max_shells, "Full RAX consumed an excess shell or exceeded its tube capacity.")
	qdel(overflow)
	var/obj/item/ammo_casing/unloaded = rax.loaded[rax.loaded.len]
	expect(rax.unload_ammo(user) && unloaded.loc == user && rax.loaded.len == rax.max_shells - 1 && unloaded.BB, "RAX tube unloading did not recover its actual live shell.")
	expect(rax.load_ammo(unloaded, user), "Recovered RAX shell could not be reloaded.")
	user.drop_from_inventory(rax)
	expect(!rax.pump(user) && !rax.unload_ammo(user) && !rax.chambered, "Dropped RAX could still be cycled or unloaded by its former holder.")
	user.put_in_hands(rax)
	world.log << "OS13_OBJECT_CHECK: RAX physical single-shell loading, wrong/full/refused ownership checks and tube unloading"

	var/obj/item/ammo_casing/first = rax.loaded[1]
	expect(rax.pump(user) && rax.chambered == first && rax.loaded.len == rax.max_shells - 1, "RAX pumping did not move the original tube casing into its chamber.")
	expect(!rax.pump(user) && rax.chambered == first, "RAX pump cooldown allowed a second immediate cycle.")
	for(var/shot = 1, shot <= rax.max_shells, shot++)
		var/obj/item/ammo_casing/current = rax.chambered
		expect(istype(current?.BB, /obj/item/projectile/bullet/pellet/shotgun/os13), "RAX source-style buckshot is not an actual pellet projectile.")
		rax.next_fire_time = 0
		rax.Fire(target, user)
		expect(rax.shots_fired == shot && rax.chambered == current && !current.BB && current.loc == rax, "RAX shot [shot] failed to spend exactly one shell while retaining its spent case.")
		expect(rax.getAmmo() == rax.max_shells - shot, "RAX counted its retained spent case as a live round.")
		rax.next_fire_time = 0
		rax.Fire(target, user)
		expect(rax.shots_fired == shot && rax.chambered == current, "RAX fired again from a spent chamber without pumping.")
		rax.recentpump = 0
		expect(rax.pump(user) && current.loc == origin, "RAX pump failed to eject its actual spent case.")
	for(var/i = 1, i <= 20 && !target.impacts, i++)
		sleep(1)
	expect(target.impacts && target.delivered_damage > 0 && target.last_projectile == /obj/item/projectile/bullet/pellet/shotgun/os13, "Real RAX firing did not deliver its damaging pellet projectile to a physical target.")
	expect(!rax.loaded.len && !rax.chambered && !rax.getAmmo(), "Exhausted RAX retained a duplicate live round or reported spent cases as ammunition.")
	for(var/obj/item/ammo_casing/casing in casings)
		expect(casing.loc == origin && !casing.BB, "RAX lost a casing or restored an expended projectile.")
	world.log << "OS13_OBJECT_CHECK: actual RAX projectile delivery, manual chamber cycling, spent-case retention and ammunition conservation"

	for(var/i = 1, i <= 2, i++)
		shell = new(origin)
		casings += shell
		user.put_in_hands(shell)
		rax.load_ammo(shell, user)
	rax.recentpump = 0
	rax.pump(user)
	var/obj/item/ammo_casing/live = rax.chambered
	var/obj/item/projectile/payload = live.BB
	rax.recentpump = 0
	rax.pump(user)
	expect(live.loc == origin && live.BB == payload && rax.chambered && rax.chambered != live, "Cycling a live RAX shell consumed or duplicated its original projectile.")
	var/obj/item/ammo_casing/before_jam = rax.chambered
	rax.is_jammed = TRUE
	rax.recentpump = 0
	spawn(1)
		user.drop_from_inventory(rax)
	expect(!rax.pump(user) && rax.is_jammed && !rax.pumping && rax.chambered == before_jam && before_jam.BB, "Interrupted RAX jam clearing altered its chamber, cleared the jam or retained an action lock.")
	user.put_in_hands(rax)
	rax.recentpump = 0
	var/old_shots = rax.shots_fired
	spawn(1)
		rax.next_fire_time = 0
		rax.Fire(target, user)
		expect(rax.shots_fired == old_shots && before_jam.BB && !rax.unload_ammo(user), "RAX fired or unloaded during jam clearing.")
	expect(rax.pump(user) && !rax.is_jammed && !rax.pumping && rax.chambered == before_jam && before_jam.BB, "Completed RAX jam clearing cycled or consumed ammunition.")
	rax.firing = TRUE
	rax.recentpump = 0
	expect(!rax.pump(user), "RAX action was cycled during firing.")
	rax.firing = FALSE
	qdel(rax)
	for(var/obj/item/ammo_casing/casing in casings)
		qdel(casing)
	qdel(user)
	qdel(target)
	world.log << "OS13_OBJECT_CHECK: live RAX shell recovery, interrupted/completed jam clearing and firing-action exclusion"
