//Shitty variant of the normal bolt action rifle.
/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/shitty
	name = "\improper Frontier Arms FA-01 Stormrider Bolt-Action Rifle"
	desc = "An early Stormrider-pattern rifle, older and less reliable than the FA-02. This example shows heavy wear."
	icon_state = "mosin2"
	item_state = "mosin2"
	wielded_item_state = "mosin2-wielded"
	jam_chance = 3
	//pumpsound = 'sound/weapons/newrifle_reload.ogg'
	fire_sound = "brifle"
	caliber = "763"
	ammo_type = /obj/item/ammo_casing/brifle

/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/shitty/bayonet
	name = "\improper Frontier Arms FA-01 Stormrider Rifle with Bayonet"
	desc = "An early, worn Stormrider-pattern rifle fitted with a fixed bayonet."
	icon_state = "mosin2-bayonet"
	force = 15
	sharp = 1
	attack_verb = list ("stabbed", "sliced")
	hitsound = "stab_sound"


/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/shitty/pump(mob/M as mob)
	..()
	M.visible_message("[M] pushes the bolt of \the [src.name]")//For deaf people.


//Paryying.
/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/handle_shield(mob/living/user, var/damage, atom/damage_source = null, mob/attacker = null, var/def_zone = null, var/attack_text = "the attack")
	if(default_sword_parry(user, damage, damage_source, attacker, def_zone, attack_text))
		return 1
	return 0

/*
//This is OP at the moment.
/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/verb/scope()
	set category = "Object"
	set name = "Use Iron Sights"
	set popup_menu = 1

	toggle_scope(usr, 2.0)
*/
/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/madsen
	name = "\improper Aussec Armoury M-4 Bolt-Action Rifle"
	desc = "A well-maintained bolt-action rifle with a clean stock and refinished metalwork."
	icon_state = "madsen"
	item_state = "mosin2"
	wielded_item_state = "mosin2-wielded"
	jam_chance = 1
	//pumpsound = 'sound/weapons/newrifle_reload.ogg'
	fire_sound = "brifle"
	caliber = "763"
	ammo_type = /obj/item/ammo_casing/brifle

/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/remedymk1
	name = "\improper Remedy Arms RM-1 Bolt-Action Rifle"
	desc = "An older bolt-action rifle with a wooden stock, kept in unusually good condition."
	icon_state = "remedymk1"
	item_state = "remedymk1"
	wielded_item_state = "mosin2-wielded"
	jam_chance = 1
	//pumpsound = 'sound/weapons/newrifle_reload.ogg'
	fire_sound = "brifle"
	caliber = "763"
	ammo_type = /obj/item/ammo_casing/brifle


//AMMO
/obj/item/ammo_casing/brifle
	desc = "An old worn out looking bullet casing."
	caliber = "763"
	projectile_type = /obj/item/projectile/bullet/rifle/a762/brifle
	icon_state = "rifle-casing"
	spent_icon = "rifle-casing-spent"

/obj/item/projectile/bullet/rifle/a762/brifle
	fire_sound = "brifle"
	penetration_modifier = 1.5



//Shitty shotgun
/obj/item/weapon/gun/projectile/shotgun/pump/shitty
	name = "\improper Ward-Takahashi WTX Frontier Shotgun"
	desc = "A low-cost 12-gauge pump shotgun sold for frontier use. Its loose tolerances make it prone to jamming."
	jam_chance = 15

/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/persuasion
	name = "\improper Hephaestus HPR-2 Precision Rifle"
	desc = "A modern bolt-action precision rifle chambered for 7.62x54mm ammunition, with a 20-round capacity."
	icon_state = "Persuasion_mk2"
	item_state = "madsen"
	jam_chance = 1
	//pumpsound = 'sound/weapons/newrifle_reload.ogg'
	fire_sound = "brifle"
	caliber = "a762x54"
	ammo_type = /obj/item/ammo_casing/a762x54
	handle_casings = HOLD_CASINGS //please work please work.
	load_method = SINGLE_CASING
	max_shells = 20 //Maybe needs a nerf.

/obj/item/weapon/gun/projectile/shotgun/pump/boltaction/persuasion/verb/scope()
	set category = "Object"
	set name = "Use Iron Sights"
	set popup_menu = 1

	toggle_scope(usr, 2.0)
