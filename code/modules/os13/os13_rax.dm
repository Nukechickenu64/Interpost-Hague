// ALIEN 01:18:40-01:19:30: pellet hits, manual pumping, empty clicks and drops.
// See docs/os13_rax_parity.md for the unrecovered source balance/asset details.
/obj/item/projectile/bullet/pellet/shotgun/os13
	name = "pellet"

/obj/item/ammo_casing/shotgun/pellet/os13
	projectile_type = /obj/item/projectile/bullet/pellet/shotgun/os13

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax
	name = "\improper RAX Shotgun"
	desc = "A pump-action shotgun with a tubular magazine. Cycle the action to chamber a shell or eject a spent case."
	icon = 'icons/os13/objects/objects/weapons/gun.dmi'
	icon_state = "shotgun"
	item_state = "shotgun"
	wielded_item_state = null
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	starts_loaded = FALSE
	ammo_type = /obj/item/ammo_casing/shotgun/pellet/os13
	var/pumping = FALSE

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/update_icon()
	icon_state = "shotgun"
	update_held_icon()

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/attack_self(mob/user)
	return pump(user)

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/pump(mob/user)
	if(!os13_weapon_held(src, user) || firing || pumping || world.time < recentpump + 10)
		return FALSE
	if(chambered && chambered.loc != src)
		return FALSE
	if(loaded.len)
		var/obj/item/ammo_casing/next_shell = loaded[1]
		if(QDELETED(next_shell) || next_shell.loc != src || next_shell.caliber != caliber)
			return FALSE
	recentpump = world.time
	if(is_jammed)
		pumping = TRUE
		var/obj/item/ammo_casing/old_chamber = chambered
		to_chat(user, SPAN_NOTICE("You begin clearing the RAX Shotgun's jam."))
		var/completed = do_after(user, 40, src)
		if(QDELETED(src))
			return FALSE
		pumping = FALSE
		if(!completed || !os13_weapon_held(src, user) || firing || chambered != old_chamber || !is_jammed)
			return FALSE
		is_jammed = FALSE
		playsound(src, 'sound/effects/unjam.ogg', 50, TRUE)
		return TRUE
	if(chambered)
		chambered.forceMove(get_turf(src))
		playsound(src, casingsound, 50, TRUE)
		chambered = null
	if(loaded.len)
		chambered = loaded[1]
		loaded.Cut(1, 2)
	playsound(src, pumpsound, 60, TRUE)
	user.visible_message(SPAN_NOTICE("[user] pumps the RAX Shotgun!"))
	add_fingerprint(user)
	update_icon()
	return TRUE

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/consume_next_projectile()
	if(is_jammed || pumping)
		return null
	return ..()

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/getAmmo()
	var/rounds = chambered?.BB ? 1 : 0
	for(var/obj/item/ammo_casing/shell in loaded)
		if(shell.BB)
			rounds++
	return rounds

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/special_check(mob/user, obj/item/item)
	if(pumping)
		return FALSE
	return ..()

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/load_ammo(obj/item/ammunition, mob/user)
	if(!os13_weapon_held(src, user) || !os13_weapon_held(ammunition, user) || firing || pumping || !istype(ammunition, /obj/item/ammo_casing) || loaded.len >= max_shells)
		return FALSE
	var/obj/item/ammo_casing/shell = ammunition
	if(shell.caliber != caliber || !user.unEquip(shell, target = src))
		return FALSE
	// Match the existing pump-shotgun tube's insertion order, retaining the
	// original casing/projectile instead of manufacturing another round.
	loaded.Insert(1, shell)
	add_fingerprint(user)
	playsound(src, bulletinsert_sound, 50, TRUE)
	to_chat(user, SPAN_NOTICE("You insert \a [shell] into the RAX Shotgun."))
	update_icon()
	return TRUE

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/unload_ammo(mob/user, allow_dump = TRUE)
	if(!os13_weapon_held(src, user) || firing || pumping || !loaded.len)
		return FALSE
	var/obj/item/ammo_casing/shell = loaded[loaded.len]
	if(QDELETED(shell) || shell.loc != src)
		return FALSE
	loaded.len--
	shell.forceMove(get_turf(user))
	user.put_in_hands(shell)
	to_chat(user, SPAN_NOTICE("You remove \a [shell] from the RAX Shotgun's tube."))
	update_icon()
	return TRUE

/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("The tube contains [loaded.len] shell\s."))
	to_chat(user, SPAN_NOTICE(chambered ? (chambered.BB ? "A live shell is chambered." : "A spent case remains in the chamber.") : "The chamber is empty."))
