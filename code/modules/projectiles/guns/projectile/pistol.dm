/obj/item/weapon/gun/projectile/colt
	name = "\improper Lumoco Arms LA-1911 Pistol"
	desc = "A low-cost .45-caliber service pistol by Lumoco Arms, patterned after an older military design. Uses .45 rounds."
	magazine_type = /obj/item/ammo_magazine/c45m
	allowed_magazines = /obj/item/ammo_magazine/c45m
	icon_state = "colt"
	caliber = ".45"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	load_method = MAGAZINE

/obj/item/weapon/gun/projectile/colt/officer
	name = "\improper Ward-Takahashi WT45 Duty Pistol"
	icon_state = "secgundark"
	desc = "The Ward-Takahashi WT45 is a mass-produced .45-caliber service pistol, widely recognized from films and other entertainment media. Uses .45 rounds."
	icon_state = "secgundark"
	accuracy = 0.35
	fire_delay = 6.5

/obj/item/weapon/gun/projectile/colt/officer/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "secgundark"
	else
		icon_state = "secgundark-e"

/obj/item/weapon/gun/projectile/sec
	name = "\improper NanoTrasen Mk58 .45 Service Pistol"
	desc = "The NanoTrasen Mk58 is a low-cost, widely issued .45-caliber service pistol found across human space. Uses .45 rounds."
	icon_state = "secguncomp"
	magazine_type = /obj/item/ammo_magazine/c45m/flash
	allowed_magazines = /obj/item/ammo_magazine/c45m
	caliber = ".45"
	accuracy = -0.35
	fire_delay = 5.5
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	load_method = MAGAZINE

/obj/item/weapon/gun/projectile/sec/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "secguncomp"
	else
		icon_state = "secguncomp-e"

/obj/item/weapon/gun/projectile/sec/flash
	name = "\improper NanoTrasen Mk58 Signal Pistol"
	desc = "A Mk58-pattern pistol modified to fire .45-caliber signal cartridges."

/obj/item/weapon/gun/projectile/sec/wood
	desc = "A customized NanoTrasen Mk58 with a fitted wooden grip and other owner-installed modifications. Uses .45 rounds."
	name = "\improper NanoTrasen Mk58 Custom Pistol"
	icon_state = "secgundark"
	accuracy = 0

/obj/item/weapon/gun/projectile/sec/wood/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "secgundark"
	else
		icon_state = "secgundark-e"

/obj/item/weapon/gun/projectile/silenced
	name = "\improper Lumoco Arms LA-45S Suppressed Pistol"
	desc = "A .45-caliber semi-automatic pistol fitted with a sound suppressor. Uses .45 rounds."
	icon_state = "silenced_pistol"
	w_class = ITEM_SIZE_NORMAL
	caliber = ".45"
	silenced = 1
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 8)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/c45m
	allowed_magazines = /obj/item/ammo_magazine/c45m

/obj/item/weapon/gun/projectile/sig250
	name = "\improper Tarvos T-250 Compact Pistol"
	desc = "A compact, heavily modified Tarvos sidearm chambered for .45 ACP."
	icon_state = "sig250"
	item_state = "sig250"
	w_class = ITEM_SIZE_SMALL
	caliber = "a45acp"
	silenced = 0
	fire_delay = 1
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 2)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/sig250
	allowed_magazines = /obj/item/ammo_magazine/sig250
	jam_chance = 1

/obj/item/weapon/gun/projectile/sig250/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "sig250"
	else
		icon_state = "sig250_empty"

/obj/item/weapon/gun/projectile/glock17
	name = "\improper NanoTrasen NT-17 Service Pistol"
	desc = "A striker-fired 9mm service pistol manufactured by NanoTrasen for general issue."
	icon_state = "glock17"
	item_state = "pistol1"
	w_class = ITEM_SIZE_SMALL
	caliber = "a9mm"
	silenced = 0
	fire_delay = 1
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 2)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/glock17
	allowed_magazines = /obj/item/ammo_magazine/glock17
	jam_chance = 0

/obj/item/weapon/gun/projectile/glock17/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "glock17"
	else
		icon_state = "glock17_empty"

/obj/item/weapon/gun/projectile/betta
	name = "\improper Aussec Armoury AS-9 Duty Pistol"
	desc = "A standard-issue 9mm duty pistol used by military and security units across human space."
	icon_state = "m9"
	item_state = "pistol1"
	w_class = ITEM_SIZE_SMALL
	caliber = "a9mm"
	silenced = 0
	fire_delay = 1
	origin_tech = list(TECH_COMBAT = 3, TECH_MATERIAL = 2, TECH_ILLEGAL = 3)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/betta
	allowed_magazines = /obj/item/ammo_magazine/betta
	jam_chance = 0

/obj/item/weapon/gun/projectile/betta/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "m9"
	else
		icon_state = "m9_empty"

/obj/item/weapon/gun/projectile/c6
	name = "\improper Zendai Foundries C-6 Heritage Pistol"
	desc = "An obsolete 9mm service pistol kept in circulation through extensive refurbishment and modification."
	icon_state = "raider_gun"
	item_state = "pistol1"
	w_class = ITEM_SIZE_SMALL
	caliber = "a9mm"
	silenced = 0
	fire_delay = 3
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 1, TECH_ILLEGAL = 4)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/c6
	allowed_magazines = /obj/item/ammo_magazine/c6
	jam_chance = 2

/obj/item/weapon/gun/projectile/c6/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "raider_gun"
	else
		icon_state = "raider_gun_empty"

/obj/item/weapon/gun/projectile/maers14
	name = "\improper Shellguard MA-14 Service Pistol"
	desc = "The Shellguard MA-14 is a standard 9mm sidearm issued to expeditionary and marine units."
	icon_state = "maers14"
	item_state = "pistol1"
	w_class = ITEM_SIZE_SMALL
	caliber = "a9mm"
	silenced = 0
	fire_delay = 0
	origin_tech = list(TECH_COMBAT = 3, TECH_MATERIAL = 2, TECH_ILLEGAL = 3)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/maers14
	allowed_magazines = /obj/item/ammo_magazine/maers14
	jam_chance = 0

/obj/item/weapon/gun/projectile/maers14/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "maers14"
	else
		icon_state = "maers14_empty"

/obj/item/weapon/gun/projectile/herculus
	name = "\improper Lawson Arms LA-24 Suppressed Pistol"
	desc = "A compact 9mm semi-automatic pistol equipped with a sound suppressor."
	icon_state = "herculusxv26"
	item_state = "pistol1"
	w_class = ITEM_SIZE_SMALL
	caliber = "a9mm"
	silenced = 1
	fire_delay = 0
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 2)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/glock17
	allowed_magazines = /obj/item/ammo_magazine/glock17
	jam_chance = 0

/obj/item/weapon/gun/projectile/glock17/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "glock17"
	else
		icon_state = "glock17_empty"

/obj/item/weapon/gun/projectile/maka
	name = "\improper Zendai Foundries ZP-9 Officer's Pistol"
	desc = "A compact 9mm pistol commonly carried by security officers and plainclothes personnel."
	icon_state = "maka_special"
	item_state = "pistol"
	w_class = ITEM_SIZE_SMALL
	caliber = "9mm"
	silenced = 0
	fire_delay = 1
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 2)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/makaspecial
	allowed_magazines = /obj/item/ammo_magazine/makaspecial
	jam_chance = 2

/obj/item/weapon/gun/projectile/magnum_pistol
	name = "\improper HelTek Magnus .50 AE Pistol"
	desc = "The HelTek Magnus is a heavy-frame handgun chambered for .50 AE ammunition."
	icon_state = "magnum"
	item_state = "revolver"
	force = 14.0
	caliber = ".50"
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/a50
	allowed_magazines = /obj/item/ammo_magazine/a50
	mag_insert_sound = 'sound/weapons/guns/interaction/hpistol_magin.ogg'
	mag_remove_sound = 'sound/weapons/guns/interaction/hpistol_magout.ogg'

/obj/item/weapon/gun/projectile/magnum_pistol/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "magnum"
	else
		icon_state = "magnum-e"

/obj/item/weapon/gun/projectile/gyropistol
	name = "\improper Hephaestus HG-75 Gyrojet Pistol"
	desc = "A bulky pistol built around a launcher system for self-propelled rounds."
	icon_state = "gyropistol"
	max_shells = 8
	caliber = "75"
	origin_tech = list(TECH_COMBAT = 3)
	ammo_type = /obj/item/ammo_casing/a75
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/a75
	fire_delay = 25
	auto_eject = 1
	auto_eject_sound = 'sound/weapons/smg_empty_alarm.ogg'
	mag_insert_sound = 'sound/weapons/guns/interaction/hpistol_magin.ogg'
	mag_remove_sound = 'sound/weapons/guns/interaction/hpistol_magout.ogg'

/obj/item/weapon/gun/projectile/gyropistol/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "gyropistolloaded"
	else
		icon_state = "gyropistol"

/obj/item/weapon/gun/projectile/pistol
	name = "\improper Glukco Arms G22 Holdout Pistol"
	desc = "A compact, easily concealed 9mm pistol manufactured by Glukco Arms. It accepts a screw-on suppressor."
	icon_state = "pistol"
	item_state = null
	w_class = ITEM_SIZE_SMALL
	caliber = "9mm"
	silenced = 0
	fire_delay = 1
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 2)
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/mc9mm
	allowed_magazines = /obj/item/ammo_magazine/mc9mm
	jam_chance = 15

/obj/item/weapon/gun/projectile/pistol/flash
	name = "\improper Glukco Arms G22 Signal Pistol"
	desc = "A G22-pattern pistol converted to fire 9mm signal cartridges."
	magazine_type = /obj/item/ammo_magazine/mc9mm/flash

/obj/item/weapon/gun/projectile/pistol/attack_hand(mob/user as mob)
	if(user.get_inactive_hand() == src)
		if(silenced)
			if(user.l_hand != src && user.r_hand != src)
				..()
				return
			to_chat(user, "<span class='notice'>You unscrew [silenced] from [src].</span>")
			user.put_in_hands(silenced)
			silenced = initial(silenced)
			w_class = initial(w_class)
			update_icon()
			return
	..()

/obj/item/weapon/gun/projectile/pistol/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I, /obj/item/weapon/silencer))
		if(user.l_hand != src && user.r_hand != src)	//if we're not in his hands
			to_chat(user, "<span class='notice'>You'll need [src] in your hands to do that.</span>")
			return
		user.drop_item()
		to_chat(user, "<span class='notice'>You screw [I] onto [src].</span>")
		silenced = I	//dodgy?
		w_class = ITEM_SIZE_NORMAL
		I.forceMove(src)		//put the silencer into the gun
		update_icon()
		return
	..()

/obj/item/weapon/gun/projectile/pistol/update_icon()
	..()
	if(silenced)
		icon_state = "pistol-silencer"
	else
		icon_state = "pistol"
	if(!(ammo_magazine && ammo_magazine.stored_ammo.len))
		icon_state = "[icon_state]-e"

/obj/item/weapon/silencer
	name = "silencer"
	desc = "A silencer."
	icon = 'icons/obj/gun.dmi'
	icon_state = "silencer"
	w_class = ITEM_SIZE_SMALL

/obj/item/weapon/gun/projectile/pirate
	name = "frontier-built Model 1 Improvised Pistol"
	desc = "A crude, locally assembled single-shot firearm with a simple barrel, grip, and improvised firing mechanism."
	icon_state = "zipgun"
	item_state = "sawnshotgun"
	handle_casings = CYCLE_CASINGS //player has to take the old casing out manually before reloading
	load_method = SINGLE_CASING
	max_shells = 1 //literally just a barrel

	var/global/list/ammo_types = list(
		/obj/item/ammo_casing/a357              = ".357",
		/obj/item/ammo_casing/shotgun           = "12 gauge",
		/obj/item/ammo_casing/shotgun           = "12 gauge",
		/obj/item/ammo_casing/shotgun/pellet    = "12 gauge",
		/obj/item/ammo_casing/shotgun/pellet    = "12 gauge",
		/obj/item/ammo_casing/shotgun/pellet    = "12 gauge",
		/obj/item/ammo_casing/shotgun/beanbag   = "12 gauge",
		/obj/item/ammo_casing/shotgun/stunshell = "12 gauge",
		/obj/item/ammo_casing/shotgun/flash     = "12 gauge",
		/obj/item/ammo_casing/a762              = "7.62mm",
		/obj/item/ammo_casing/a556              = "5.56mm"
		)

/obj/item/weapon/gun/projectile/pirate/New()
	ammo_type = pick(ammo_types)
	desc += " Uses [ammo_types[ammo_type]] rounds."

	var/obj/item/ammo_casing/ammo = ammo_type
	caliber = initial(ammo.caliber)
	..()

// Zip gun construction.
/obj/item/weapon/zipgunframe
	name = "zip gun frame"
	desc = "A half-finished zip gun."
	icon_state = "zipgun0"
	item_state = "zipgun-solid"
	var/buildstate = 0

/obj/item/weapon/zipgunframe/update_icon()
	icon_state = "zipgun[buildstate]"

/obj/item/weapon/zipgunframe/examine(mob/user)
	. = ..()
	..(user)
	switch(buildstate)
		if(1) to_chat(user, "It has a barrel loosely fitted to the stock.")
		if(2) to_chat(user, "It has a barrel that has been secured to the stock with tape.")
		if(3) to_chat(user, "It has a trigger and firing pin assembly loosely fitted into place.")

/obj/item/weapon/zipgunframe/attackby(var/obj/item/thing, var/mob/user)
	if(istype(thing,/obj/item/pipe) && buildstate == 0)
		user.drop_from_inventory(thing)
		qdel(thing)
		user.visible_message("<span class='notice'>\The [user] fits \the [thing] to \the [src] as a crude barrel.</span>")
		add_fingerprint(user)
		buildstate++
		update_icon()
		return
	else if(istype(thing,/obj/item/tape_roll) && buildstate == 1)
		user.visible_message("<span class='notice'>\The [user] secures the assembly with \the [thing].</span>")
		add_fingerprint(user)
		buildstate++
		update_icon()
		return
	else if(istype(thing,/obj/item/device/assembly/mousetrap) && buildstate == 2)
		user.drop_from_inventory(thing)
		qdel(thing)
		user.visible_message("<span class='notice'>\The [user] takes apart \the [thing] and uses the parts to construct a crude trigger and firing mechanism inside the assembly.</span>")
		add_fingerprint(user)
		buildstate++
		update_icon()
		return
	else if(isScrewdriver(thing) && buildstate == 3)
		user.visible_message("<span class='notice'>\The [user] secures the trigger assembly with \the [thing].</span>")
		playsound(loc, 'sound/items/Screwdriver.ogg', 50, 1)
		var/obj/item/weapon/gun/projectile/pirate/zipgun
		zipgun = new/obj/item/weapon/gun/projectile/pirate { starts_loaded = 0 } (loc)
		if(ismob(loc))
			var/mob/M = loc
			M.drop_from_inventory(src)
			M.put_in_hands(zipgun)
		transfer_fingerprints_to(zipgun)
		qdel(src)
		return
	else
		..()
