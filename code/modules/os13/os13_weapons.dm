// Recorded weapon identities and operations. See docs/os13_weapon_parity.md
// for source evidence and the inherited, uncertified balance parameters.
/proc/os13_weapon_held(obj/item/weapon, mob/user)
	return !QDELETED(weapon) && user && !user.incapacitated() && weapon.loc == user && (user.get_active_hand() == weapon || user.get_inactive_hand() == weapon)

// CAP 00:00:20-00:00:40: open/close cylinder, examination and empty click.
/obj/item/weapon/gun/projectile/revolver/os13_nt5
	name = "\improper NT5"
	desc = "The final solution to all discipline-related problems."
	icon = 'icons/os13/objects/objects/weapons/gun.dmi'
	icon_state = "revolver3"
	item_state = "revolver3"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	starts_loaded = FALSE
	var/cylinder_open = FALSE

/obj/item/weapon/gun/projectile/revolver/os13_nt5/proc/live_rounds()
	var/rounds = 0
	for(var/obj/item/ammo_casing/casing in loaded)
		if(casing.BB)
			rounds++
	return rounds

/obj/item/weapon/gun/projectile/revolver/os13_nt5/update_icon()
	. = ..()
	// The supplied open-cylinder family has empty/partial/full artwork.
	icon_state = cylinder_open ? "revolver3_open[min(2, ceil(2 * live_rounds() / max_shells))]" : "revolver3"
	update_held_icon()

/obj/item/weapon/gun/projectile/revolver/os13_nt5/attack_self(mob/user)
	if(!os13_weapon_held(src, user) || firing)
		return
	cylinder_open = !cylinder_open
	add_fingerprint(user)
	to_chat(user, SPAN_NOTICE("You [cylinder_open ? "open" : "close"] the cylinder."))
	playsound(src, 'sound/weapons/guns/interact/selector.ogg', 40, TRUE)
	update_icon()

/obj/item/weapon/gun/projectile/revolver/os13_nt5/consume_next_projectile()
	// Also guard the consumption boundary: an open cylinder must not cycle,
	// chamber or spend a round even if firing is invoked without the UI.
	if(cylinder_open)
		return null
	return ..()

/obj/item/weapon/gun/projectile/revolver/os13_nt5/special_check(mob/user, obj/item/item)
	if(cylinder_open)
		to_chat(user, SPAN_WARNING("Close the cylinder first."))
		return FALSE
	return ..()

/obj/item/weapon/gun/projectile/revolver/os13_nt5/load_ammo(obj/item/ammunition, mob/user)
	if(!os13_weapon_held(src, user) || !os13_weapon_held(ammunition, user) || firing)
		return FALSE
	if(!cylinder_open)
		to_chat(user, SPAN_WARNING("Open the cylinder first."))
		return FALSE
	if(loaded.len >= max_shells)
		to_chat(user, SPAN_WARNING("The cylinder is full. Unload spent cases before reloading."))
		return FALSE
	var/inserted = 0
	if(istype(ammunition, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/casing = ammunition
		if(casing.caliber != caliber || !user.unEquip(casing, target = src))
			return FALSE
		loaded.Insert(1, casing)
		inserted = 1
	else if(istype(ammunition, /obj/item/ammo_magazine))
		var/obj/item/ammo_magazine/loader = ammunition
		if(loader.mag_type != SPEEDLOADER || loader.caliber != caliber)
			return FALSE
		// The loader stays in the user's hand; only its real casings move.
		for(var/obj/item/ammo_casing/casing in loader.stored_ammo.Copy())
			if(loaded.len >= max_shells)
				break
			if(casing.loc != loader || casing.caliber != caliber)
				continue
			casing.forceMove(src)
			loader.stored_ammo -= casing
			loaded += casing
			inserted++
		loader.update_icon()
	if(!inserted)
		return FALSE
	chamber_offset = 0
	add_fingerprint(user)
	playsound(src, reload_sound, 50, TRUE)
	to_chat(user, SPAN_NOTICE("You load [inserted] round\s into the NT5."))
	update_icon()
	return TRUE

/obj/item/weapon/gun/projectile/revolver/os13_nt5/unload_ammo(mob/user, allow_dump = TRUE)
	if(!os13_weapon_held(src, user) || !cylinder_open || firing)
		return FALSE
	. = ..()
	update_icon()

/obj/item/weapon/gun/projectile/revolver/os13_nt5/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("The cylinder is [cylinder_open ? "open" : "closed"]."))
	to_chat(user, SPAN_NOTICE(live_rounds() ? "There are [live_rounds()] live rounds in the cylinder." : "It's empty."))

// ALIEN 01:18:30-01:19:40: actual laser shots followed by depletion/clicks.
/obj/item/weapon/gun/energy/laser/os13_tnc
	name = "\improper TNC Laser Gun"
	desc = "A cell-powered TNC laser weapon."
	icon = 'icons/os13/objects/objects/weapons/gun.dmi'
	icon_state = "laser100"
	item_state = "laser"
	wielded_item_state = null
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	accepts_cell_type = /obj/item/cell
	self_recharge = FALSE

/obj/item/weapon/gun/energy/laser/os13_tnc/update_icon()
	// These are full authored sprites, not the generic charge-bar overlays.
	overlays.Cut()
	if(!power_supply)
		icon_state = "laser_empty"
	else if(power_supply.charge < charge_cost)
		icon_state = "laser0"
	else
		icon_state = "laser[max(25, round(power_supply.percent(), 25))]"
	update_held_icon()

/obj/item/weapon/gun/energy/laser/os13_tnc/proc/eject_cell(mob/user)
	if(!os13_weapon_held(src, user) || !power_supply || firing)
		return FALSE
	var/obj/item/cell/cell = power_supply
	power_supply = null
	cell.forceMove(get_turf(user))
	user.put_in_hands(cell)
	to_chat(user, SPAN_NOTICE("You eject the TNC Laser Gun's power cell."))
	update_icon()
	return TRUE

/obj/item/weapon/gun/energy/laser/os13_tnc/verb/eject_power_cell()
	set name = "Eject Power Cell"
	set category = "Object"
	set src in usr
	eject_cell(usr)

/obj/item/weapon/gun/energy/laser/os13_tnc/MouseDrop(atom/over_object)
	// Retain hand-drag unloading, with the same ownership/firing guards.
	if(istype(over_object, /obj/screen) && (over_object.name == "l_hand" || over_object.name == "r_hand"))
		eject_cell(usr)

/obj/item/weapon/gun/energy/laser/os13_tnc/attackby(obj/item/item, mob/user)
	if(!istype(item, /obj/item/cell))
		return ..()
	if(!os13_weapon_held(src, user) || !os13_weapon_held(item, user) || power_supply || firing || !istype(item, accepts_cell_type))
		return TRUE
	if(!do_after(user, 5, src))
		return TRUE
	// The gun, cell and free bracket must still be the ones selected before
	// the delay. No cell is moved or spent on an interrupted replacement.
	if(!os13_weapon_held(src, user) || !os13_weapon_held(item, user) || power_supply || firing)
		return TRUE
	if(user.unEquip(item, target = src))
		power_supply = item
		to_chat(user, SPAN_NOTICE("You load the power cell into the TNC Laser Gun."))
		update_icon()
	return TRUE

/datum/design/item/os13_tnc_laser
	name = "TNC Laser Gun"
	id = "os13_tnc_laser"
	req_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 3000, "glass" = 1000)
	build_path = /obj/item/weapon/gun/energy/laser/os13_tnc
	sort_string = "VAAWS"

/datum/design/item/os13_tnc_laser/Fabricate(newloc, fabricator)
	var/obj/item/weapon/gun/energy/laser/os13_tnc/weapon = ..()
	// Fabrication supplies hardware, not free stored electrical energy.
	weapon.power_supply.charge = 0
	weapon.update_icon()
	return weapon
