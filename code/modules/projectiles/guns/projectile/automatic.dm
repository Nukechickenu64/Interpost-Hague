/obj/item/weapon/gun/projectile/automatic //Hopefully someone will find a way to make these fire in bursts or something. --Superxpdude
	name = "\improper Lawson Arms L-9 Prototype Submachine Gun"
	desc = "A lightweight development-stage submachine gun configured for rapid fire. Uses 9mm rounds."
	icon_state = "saber"	//ugly
	w_class = ITEM_SIZE_NORMAL
	load_method = SPEEDLOADER //yup. until someone sprites a magazine for it.
	max_shells = 22
	caliber = "9mm"
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 2)
	slot_flags = SLOT_BELT
	ammo_type = /obj/item/ammo_casing/c9mm
	multi_aim = 1
	burst_delay = 2
	fire_sound = 'sound/weapons/guns/fire/smg_fire.ogg'
	mag_insert_sound = 'sound/weapons/guns/interaction/smg_magin.ogg'
	mag_remove_sound = 'sound/weapons/guns/interaction/smg_magout.ogg'

	//machine pistol, easier to one-hand with
	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=0, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=4,    one_hand_penalty=1, burst_accuracy=list(0,-1,-1),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=1, fire_delay=null, move_delay=4,    one_hand_penalty=2, burst_accuracy=list(0,-1,-1,-1,-2), dispersion=list(0.6, 0.6, 1.0, 1.0, 1.2), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/c20r/oldsmg
	name = "\improper Scarborough Arms Harbinger Submachine Gun"
	desc = "An older Scarborough Arms submachine gun used by prison guards and military units. It accepts the C-20r platform's standard magazines."
	icon_state = "smg"
	item_state = "wt550"
	wielded_item_state = "smg-wielded"
	one_hand_penalty = 1
	auto_eject = 0
	unload_sound = 'sound/weapons/guns/interact/smg_magout.ogg'
	reload_sound = 'sound/weapons/guns/interact/smg_magin.ogg'
	jam_chance = 3

/obj/item/weapon/gun/projectile/automatic/c20r/oldsmg/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "smg"
	else
		icon_state = "smg-e"


/obj/item/weapon/gun/projectile/automatic/machine_pistol
	name = "\improper Lumoco Arms MP6 Vesper Machine Pistol"
	desc = "The Lumoco Arms MP6 Vesper is a common .45-caliber machine pistol, sometimes informally called an Uzi on frontier stations."
	icon_state = "mac"
	item_state = "mac"
	wielded_item_state = "mac-wielded"
	//wielded_item_state = "mac-wielded"
	w_class = ITEM_SIZE_NORMAL
	load_method = MAGAZINE
	caliber = ".45"
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 2, TECH_ILLEGAL = 3)
	slot_flags = SLOT_BELT
	ammo_type = /obj/item/ammo_casing/c45
	magazine_type = /obj/item/ammo_magazine/c45uzi
	automatic = 0
	allowed_magazines = /obj/item/ammo_magazine/c45uzi //more damage compared to the wt550, smaller mag size
	one_hand_penalty = 1
	jam_chance = 5

	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=0, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=4,    one_hand_penalty=1, burst_accuracy=list(0,-1,-1),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",      burst=1, fire_delay=0, one_hand_penalty=2, burst_accuracy=null, dispersion=list(0.0, 0.8, 1.5), burst_delay = 0, automatic = 1)
		)

/obj/item/weapon/gun/projectile/automatic/machine_pistol/update_icon()
	..()
	icon_state = (ammo_magazine)? "mac" : "mac-empty"
	wielded_item_state = (ammo_magazine)? "mac-wielded" : "mac-wielded-empty"

/obj/item/weapon/gun/projectile/automatic/mini_uzi/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "mpistolen"
	else
		icon_state = "mpistolen-empty"

/obj/item/weapon/gun/projectile/automatic/mini_uzi
	name = "\improper Lumoco Arms MP9 Compact Submachine Gun"
	desc = "An ultra-compact submachine gun designed for close protection and confined-space use."

/obj/item/weapon/gun/projectile/automatic/c20r
	name = "\improper Scarborough Arms C-20r Submachine Gun"
	desc = "A lightweight, select-fire 10mm submachine gun manufactured by Scarborough Arms. The receiver bears the company's 'Per falcis, per pravitas' motto."
	icon_state = "c20r"
	item_state = "c20r"
	w_class = ITEM_SIZE_LARGE
	force = 10
	caliber = "10mm"
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 2, TECH_ILLEGAL = 8)
	slot_flags = SLOT_BELT|SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/a10mm
	allowed_magazines = /obj/item/ammo_magazine/a10mm
	auto_eject = 1
	auto_eject_sound = 'sound/weapons/smg_empty_alarm.ogg'
	one_hand_penalty = 1
	unload_sound 	= 'sound/weapons/guns/interact/sfrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/sfrifle_magin.ogg'

	//SMG
	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=2, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=4,    one_hand_penalty=3, burst_accuracy=list(0,-1,-1),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=1, fire_delay=null, move_delay=4,    one_hand_penalty=4, burst_accuracy=list(0,-1,-1,-1,-2), dispersion=list(0.6, 0.6, 1.0, 1.0, 1.2), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/c20r/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "c20r-[round(ammo_magazine.stored_ammo.len,4)]"
	else
		icon_state = "c20r"
	return

/obj/item/weapon/gun/projectile/automatic/sts35
	name = "\improper Frontier Arms STS-35 Assault Rifle"
	desc = "A rugged 5.56mm select-fire rifle common on frontier worlds. Its manufacturer and serial number have been removed."
	icon_state = "arifle"
	item_state = null
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a556"
	origin_tech = list(TECH_COMBAT = 6, TECH_MATERIAL = 1, TECH_ILLEGAL = 5)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/c556
	allowed_magazines = /obj/item/ammo_magazine/c556
	one_hand_penalty = 3
	wielded_item_state = "arifle-wielded"
	unload_sound 	= 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/ltrifle_magin.ogg'


	//Assault rifle, burst fire degrades quicker than SMG, worse one-handing penalty, slightly increased move delay
	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=4, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=6,    one_hand_penalty=5, burst_accuracy=list(0,-1,-1),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=1, fire_delay=null, move_delay=6,    one_hand_penalty=6, burst_accuracy=list(0,-1,-2,-3,-3), dispersion=list(0.6, 1.0, 1.2, 1.2, 1.5), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/sts35/update_icon()
	icon_state = (ammo_magazine)? "arifle" : "arifle-empty"
	wielded_item_state = (ammo_magazine)? "arifle-wielded" : "arifle-wielded-empty"
	..()

/obj/item/weapon/gun/projectile/automatic/ak47
	name = "\improper Mars Military Industries MA-47 Frontier Rifle"
	desc = "An older 7.62x39mm rifle design with imitation-wood furniture, widely copied and refurbished across the frontier."
	icon_state = "ak47"
	item_state = null
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a762x39"
	origin_tech = list(TECH_COMBAT = 6, TECH_MATERIAL = 1, TECH_ILLEGAL = 5)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/ak47
	allowed_magazines = /obj/item/ammo_magazine/ak47
	one_hand_penalty = 3
	wielded_item_state = "ak47"
	unload_sound 	= 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/ltrifle_magin.ogg'


	//Assault rifle, burst fire degrades quicker than SMG, worse one-handing penalty, slightly increased move delay
	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=4, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="automatic",   burst=1, fire_delay=null, move_delay=6,    one_hand_penalty=6, burst_accuracy=list(0,-1,-2,-3,-3), dispersion=list(0.6, 1.0, 1.2, 1.2, 1.5), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/ak47/update_icon()
	icon_state = (ammo_magazine)? "ak47" : "ak47"
	wielded_item_state = (ammo_magazine)? "ak47" : "ak47"
	..()

/obj/item/weapon/gun/projectile/automatic/lr
	name = "\improper Aussec Armoury LR-204 Civilian Rifle"
	desc = "A semi-automatic 5.56mm rifle sold for civilian use. Its simple construction is easy to maintain and modify."
	icon_state = "lr204"
	item_state = null
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a556"
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 1, TECH_ILLEGAL = 1)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/lr
	allowed_magazines = /obj/item/ammo_magazine/lr
	one_hand_penalty = 3
	wielded_item_state = "arifle-wielded"
	unload_sound 	= 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/ltrifle_magin.ogg'


	//Assault rifle, burst fire degrades quicker than SMG, worse one-handing penalty, slightly increased move delay
	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=1,    move_delay=null, one_hand_penalty=3, burst_accuracy=null, dispersion=null, automatic = 0),
		)

/obj/item/weapon/gun/projectile/automatic/lr/update_icon()
	icon_state = (ammo_magazine)? "arifle" : "arifle-empty"
	wielded_item_state = (ammo_magazine)? "arifle-wielded" : "arifle-wielded-empty"
	..()

/obj/item/weapon/gun/projectile/automatic/tacticalgun
	name = "\improper Hephaestus Industries CTAC B-2 Tactical Rifle"
	desc = "A durable select-fire rifle configured for accurate fire and issued to specialist units by the CTAC program."
	icon_state = "tacticalgun"
	item_state = null
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a762x39"
	origin_tech = list(TECH_COMBAT = 9, TECH_MATERIAL = 4, TECH_ILLEGAL = 6)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/c556
	allowed_magazines = /obj/item/ammo_magazine/c556
	one_hand_penalty = 0
	wielded_item_state = "arifle-wielded"
	unload_sound 	= 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/ltrifle_magin.ogg'


	//Assault rifle, burst fire degrades quicker than SMG, worse one-handing penalty, slightly increased move delay
	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=0, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=null,    one_hand_penalty=0, burst_accuracy=list(0,0,0),       dispersion=list(0.0, 0.0, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=1, fire_delay=null, move_delay=null,    one_hand_penalty=0, burst_accuracy=list(0,0,0,0,0), dispersion=list(0.0, 0.0, 0.0, 0.0, 0.0), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/tacticalgun/update_icon()
	icon_state = (ammo_magazine)? "arifle" : "arifle-empty"
	wielded_item_state = (ammo_magazine)? "arifle-wielded" : "arifle-wielded-empty"
	..()

/obj/item/weapon/gun/projectile/automatic/tbr21
	name = "\improper Scarborough Arms TBR-21 Battle Rifle"
	desc = "An expensive 7.62x51mm, gas-operated battle rifle with an open-bolt action, intended for use against armored targets."
	icon_state = "ctacassault"
	item_state = "rifle1"
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a762x51"
	origin_tech = list(TECH_COMBAT = 6, TECH_MATERIAL = 1, TECH_ILLEGAL = 5)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/ctac
	allowed_magazines = /obj/item/ammo_magazine/ctac
	one_hand_penalty = 2
	wielded_item_state = "arifle-wielded"
	unload_sound 	= 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/ltrifle_magin.ogg'


	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=2, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=null,    one_hand_penalty=3, burst_accuracy=list(0,0,0),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=5, fire_delay=null, move_delay=null,    one_hand_penalty=3, burst_accuracy=list(0,-1,-1,-1,-2), dispersion=list(0.6, 0.6, 1.0, 1.0, 1.2), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/colonyak
	name = "\improper Frontier Arms FA-47 Colony Rifle"
	desc = "A rugged 7.62x39mm rifle produced for frontier colonies, where reliability and ease of maintenance are priorities."
	icon_state = "colonyrifle"
	item_state = "rifle1"
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a762x39"
	origin_tech = list(TECH_COMBAT = 6, TECH_MATERIAL = 1, TECH_ILLEGAL = 5)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/ak
	allowed_magazines = /obj/item/ammo_magazine/ak
	one_hand_penalty = 2
	wielded_item_state = "arifle-wielded"
	unload_sound 	= 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/ltrifle_magin.ogg'


	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=2, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=null,    one_hand_penalty=3, burst_accuracy=list(0,0,0),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=5, fire_delay=null, move_delay=null,    one_hand_penalty=3, burst_accuracy=list(0,-1,-1,-1,-2), dispersion=list(0.6, 0.6, 1.0, 1.0, 1.2), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/colonyak/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "colonyrifle"
	else
		icon_state = "colonyrifle-empty"
	return

/obj/item/weapon/gun/projectile/automatic/tbr16
	name = "\improper Scarborough Arms TBR-16 Battle Submachine Gun"
	desc = "A compact, gas-operated 7.62x51mm submachine gun with an open-bolt action, built for military close-quarters use."
	icon_state = "ctacsmg"
	item_state = "rifle1"
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a762x51"
	origin_tech = list(TECH_COMBAT = 6, TECH_MATERIAL = 1, TECH_ILLEGAL = 5)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/ctac
	allowed_magazines = /obj/item/ammo_magazine/ctac
	one_hand_penalty = 2
	wielded_item_state = "arifle-wielded"
	unload_sound 	= 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/ltrifle_magin.ogg'


	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=2, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=null,    one_hand_penalty=2, burst_accuracy=list(0,0,0),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="6-round bursts", burst=6, fire_delay=null, move_delay=null,    one_hand_penalty=3, burst_accuracy=list(0,0,0),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=1, fire_delay=null, move_delay=null,    one_hand_penalty=2, burst_accuracy=list(0,0,0,0,0), dispersion=list(0.0, 0.0, 0.0, 1.1, 1.0), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/tbr12/update_icon()
	icon_state = (ammo_magazine)? "arifle" : "arifle-empty"
	wielded_item_state = (ammo_magazine)? "arifle-wielded" : "arifle-wielded-empty"
	..()

/obj/item/weapon/gun/projectile/automatic/tbr12
	name = "\improper Scarborough Arms TBR-12 Experimental Rifle"
	desc = "An experimental rifle from Scarborough Arms' TBR development program."

/obj/item/weapon/gun/projectile/automatic/wt550
	name = "\improper Ward-Takahashi WT-550 Saber Submachine Gun"
	desc = "The WT-550 Saber is an affordable 9mm submachine gun manufactured by Ward-Takahashi for private security and paramilitary use."
	icon_state = "wt550"
	item_state = "wt550"
	w_class = ITEM_SIZE_NORMAL
	caliber = "9mm"
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 2)
	slot_flags = SLOT_BELT
	ammo_type = /obj/item/ammo_casing/c9mm/rubber
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/mc9mmt/rubber
	allowed_magazines = /obj/item/ammo_magazine/mc9mmt

	//machine pistol, like SMG but easier to one-hand with
	firemodes = list(
		list(mode_name="semiauto",       burst=1, fire_delay=0,    move_delay=null, one_hand_penalty=0, burst_accuracy=null, dispersion=null, automatic = 0),
		list(mode_name="3-round bursts", burst=3, fire_delay=null, move_delay=4,    one_hand_penalty=1, burst_accuracy=list(0,-1,-1),       dispersion=list(0.0, 0.6, 1.0), automatic = 0),
		list(mode_name="automatic",   burst=5, fire_delay=null, move_delay=4,    one_hand_penalty=2, burst_accuracy=list(0,-1,-1,-1,-2), dispersion=list(0.6, 0.6, 1.0, 1.0, 1.2), automatic = 1),
		)

/obj/item/weapon/gun/projectile/automatic/wt550/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "wt550-[round(ammo_magazine.stored_ammo.len,4)]"
	else
		icon_state = "wt550"
	return

/obj/item/weapon/gun/projectile/automatic/z8
	name = "\improper Zendai Foundries Z8 Bulldog Bullpup Carbine"
	desc = "A bullpup 7.62mm carbine from the now-defunct Zendai Foundries. It uses armor-piercing ammunition and has an underslung grenade launcher; this model does not support automatic fire."
	icon_state = "carbine"
	item_state = "z8carbine"
	w_class = ITEM_SIZE_HUGE
	force = 10
	caliber = "a762"
	origin_tech = list(TECH_COMBAT = 8, TECH_MATERIAL = 3)
	ammo_type = /obj/item/ammo_casing/a762
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/a762
	allowed_magazines = /obj/item/ammo_magazine/a762
	auto_eject = 1
	auto_eject_sound = 'sound/weapons/smg_empty_alarm.ogg'
	one_hand_penalty = 5
	burst_delay = 4
	wielded_item_state = "z8carbine-wielded"
	unload_sound 	= 'sound/weapons/guns/interact/batrifle_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/batrifle_magin.ogg'

	//would have one_hand_penalty=4,5 but the added weight of a grenade launcher makes one-handing even harder
	firemodes = list(
		list(mode_name="semiauto",       burst=1,    fire_delay=0,    move_delay=null, use_launcher=null, one_hand_penalty=5, burst_accuracy=null, dispersion=null),
		list(mode_name="3-round bursts", burst=3,    fire_delay=null, move_delay=6,    use_launcher=null, one_hand_penalty=6, burst_accuracy=list(0,-1,-1), dispersion=list(0.0, 0.6, 1.0)),
		list(mode_name="fire grenades",  burst=null, fire_delay=null, move_delay=null, use_launcher=1,    one_hand_penalty=5, burst_accuracy=null, dispersion=null)
		)

	var/use_launcher = 0
	var/obj/item/weapon/gun/launcher/grenade/underslung/launcher

/obj/item/weapon/gun/projectile/automatic/z8/New()
	..()
	launcher = new(src)

/obj/item/weapon/gun/projectile/automatic/z8/attackby(obj/item/I, mob/user)
	if((istype(I, /obj/item/weapon/grenade)))
		launcher.load(I, user)
	else
		..()

/obj/item/weapon/gun/projectile/automatic/z8/attack_hand(mob/user)
	if(user.get_inactive_hand() == src && use_launcher)
		launcher.unload(user)
	else
		..()

/obj/item/weapon/gun/projectile/automatic/z8/Fire(atom/target, mob/living/user, params, pointblank=0, reflex=0)
	if(use_launcher)
		launcher.Fire(target, user, params, pointblank, reflex)
		if(!launcher.chambered)
			switch_firemodes() //switch back automatically
	else
		..()

/obj/item/weapon/gun/projectile/automatic/z8/update_icon()
	..()
	if(ammo_magazine)
		if(ammo_magazine.stored_ammo.len)
			icon_state = "carbine-loaded"
		else
			icon_state = "carbine-empty"
	else
		icon_state = "carbine"
	return

/obj/item/weapon/gun/projectile/automatic/z8/examine(mob/user)
	. = ..()
	if(launcher.chambered)
		to_chat(user, "\The [launcher] has \a [launcher.chambered] loaded.")
	else
		to_chat(user, "\The [launcher] is empty.")

/obj/item/weapon/gun/projectile/automatic/l6_saw
	name = "\improper Aussec Armoury L6 Squad Automatic Weapon"
	desc = "The Aussec Armoury L6 is a 5.56mm squad automatic weapon with a 50-round box magazine and a lacquered wooden pistol grip."
	icon_state = "l6closed100"
	item_state = "l6closedmag"
	w_class = ITEM_SIZE_HUGE
	force = 10
	slot_flags = 0
	max_shells = 50
	caliber = "a556"
	origin_tech = list(TECH_COMBAT = 6, TECH_MATERIAL = 1, TECH_ILLEGAL = 2)
	slot_flags = 0 //need sprites for SLOT_BACK
	ammo_type = /obj/item/ammo_casing/a556
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/box/a556
	allowed_magazines = list(/obj/item/ammo_magazine/box/a556, /obj/item/ammo_magazine/c556)
	one_hand_penalty = 6
	wielded_item_state = "gun_wielded"
	mag_insert_sound = 'sound/weapons/guns/interaction/lmg_magin.ogg'
	mag_remove_sound = 'sound/weapons/guns/interaction/lmg_magout.ogg'

	//LMG, better sustained fire accuracy than assault rifles (comparable to SMG), higer move delay and one-handing penalty
	//No single-shot or 3-round-burst modes since using this weapon should come at a cost to flexibility.
	firemodes = list(
		list(mode_name="short bursts",	burst=5, move_delay=12, one_hand_penalty=8, burst_accuracy = list(0,-1,-1,-2,-2),          dispersion = list(0.6, 1.0, 1.0, 1.0, 1.2)),
		list(mode_name="long bursts",	burst=8, move_delay=15, one_hand_penalty=9, burst_accuracy = list(0,-1,-1,-2,-2,-2,-3,-3), dispersion = list(1.0, 1.0, 1.0, 1.0, 1.2)),
		)

	var/cover_open = 0

/obj/item/weapon/gun/projectile/automatic/l6_saw/mag
	magazine_type = /obj/item/ammo_magazine/c556

/obj/item/weapon/gun/projectile/automatic/l6_saw/special_check(mob/user)
	if(cover_open)
		to_chat(user, "<span class='warning'>[src]'s cover is open! Close it before firing!</span>")
		return 0
	return ..()

/obj/item/weapon/gun/projectile/automatic/l6_saw/proc/toggle_cover(mob/user)
	cover_open = !cover_open
	to_chat(user, "<span class='notice'>You [cover_open ? "open" : "close"] [src]'s cover.</span>")
	update_icon()

/obj/item/weapon/gun/projectile/automatic/l6_saw/attack_self(mob/user as mob)
	if(cover_open)
		toggle_cover(user) //close the cover
		playsound(src.loc, 'sound/weapons/guns/interact/lmg_close.ogg', 100, 1)
	else
		return ..() //once closed, behave like normal

/obj/item/weapon/gun/projectile/automatic/l6_saw/attack_hand(mob/user as mob)
	if(!cover_open && user.get_inactive_hand() == src)
		toggle_cover(user) //open the cover
		playsound(src.loc, 'sound/weapons/guns/interact/lmg_open.ogg', 100, 1)
	else
		return ..() //once open, behave like normal

/obj/item/weapon/gun/projectile/automatic/l6_saw/update_icon()
	if(istype(ammo_magazine, /obj/item/ammo_magazine/box))
		icon_state = "l6[cover_open ? "open" : "closed"][round(ammo_magazine.stored_ammo.len, 25)]"
		item_state = "l6[cover_open ? "open" : "closed"]"
	else if(ammo_magazine)
		icon_state = "l6[cover_open ? "open" : "closed"]mag"
		item_state = "l6[cover_open ? "open" : "closed"]mag"
	else
		icon_state = "l6[cover_open ? "open" : "closed"]-empty"
		item_state = "l6[cover_open ? "open" : "closed"]-empty"
	..()

/obj/item/weapon/gun/projectile/automatic/l6_saw/load_ammo(var/obj/item/A, mob/user)
	if(!cover_open)
		to_chat(user, "<span class='warning'>You need to open the cover to load that into [src].</span>")
		return
	..()

/obj/item/weapon/gun/projectile/automatic/l6_saw/unload_ammo(mob/user, var/allow_dump=1)
	if(!cover_open)
		to_chat(user, "<span class='warning'>You need to open the cover to unload [src].</span>")
		return
	..()
