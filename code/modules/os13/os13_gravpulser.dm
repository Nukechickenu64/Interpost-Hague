// Physical product for the archived Heavy Gravpulser technology. The local
// catalogue specifies five shots and armor bypass. Damage/art/recharge details
// remain reconstruction choices: see docs/os13_gravpulser_parity.md.
/obj/item/projectile/energy/os13_gravsphere
	name = "gravsphere"
	icon = 'icons/os13/objects/objects/projectiles.dmi'
	icon_state = "pulse"
	damage = 25
	damage_type = BRUTE
	check_armour = null
	armor_penetration = 100
	mob_hit_sound = list('sound/effects/gore/bullethit2.ogg')

/obj/item/weapon/gun/energy/os13_heavy_gravpulser
	name = "\improper Heavy Gravpulser"
	desc = "A heavy gravitic weapon with a five-shot internal battery and a station-recharger connection."
	icon = 'icons/os13/objects/objects/weapons/gun.dmi'
	icon_state = "gravrifle"
	item_state = "gravrifle"
	wielded_item_state = null
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	projectile_type = /obj/item/projectile/energy/os13_gravsphere
	max_shots = 5
	charge_cost = 100
	self_recharge = FALSE
	accepts_cell_type = null
	power_supply = null
	charge_meter = FALSE
	w_class = ITEM_SIZE_HUGE
	slot_flags = SLOT_BACK
	force = 10
	one_hand_penalty = 3
	fire_sound = 'sound/weapons/pulse3.ogg'
	fire_sound_text = "gravitic pulse"

/obj/item/weapon/gun/energy/os13_heavy_gravpulser/update_icon()
	overlays.Cut()
	icon_state = power_supply && power_supply.charge >= charge_cost ? "gravrifle" : "gravrifle_empty"
	update_held_icon()

/obj/item/weapon/gun/energy/os13_heavy_gravpulser/special_check(mob/user, obj/item/item)
	if(!os13_weapon_held(src, user))
		return FALSE
	return ..()

/obj/item/weapon/gun/energy/os13_heavy_gravpulser/MouseDrop(atom/over_object)
	// This reconstruction uses a fixed battery. The source does not establish
	// interchangeable cell compatibility or an ejection/replacement procedure.
	return

/datum/design/item/os13_heavy_gravpulser
	name = "Heavy Gravpulser"
	id = "os13_heavy_gravpulser"
	req_tech = list(TECH_COMBAT = 4, TECH_MAGNET = 4)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 3000, "glass" = 1000)
	build_path = /obj/item/weapon/gun/energy/os13_heavy_gravpulser
	sort_string = "VAAWT"

/datum/design/item/os13_heavy_gravpulser/Fabricate(newloc, fabricator)
	var/obj/item/weapon/gun/energy/os13_heavy_gravpulser/weapon = ..()
	weapon.power_supply.charge = 0
	weapon.power_supply.update_icon()
	weapon.update_icon()
	return weapon
