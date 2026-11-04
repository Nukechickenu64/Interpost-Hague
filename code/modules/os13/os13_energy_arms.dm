// Named products seen as retrieved technology in SCI 01:15:40 / 01:22:20.
// Physical balance, servicing and sprite assignments are reconstruction choices.
// See docs/os13_energy_arms_parity.md for the evidence boundary.
/obj/item/weapon/gun/energy/gun/os13
	name = "\improper Energy Gun"
	desc = "An energy sidearm with stun and lethal settings and an internal rechargeable battery."
	icon = 'icons/os13/objects/objects/weapons/gun.dmi'
	icon_state = "energy100"
	item_state = "gun"
	wielded_item_state = null
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	charge_meter = FALSE
	self_recharge = FALSE
	accepts_cell_type = null
	power_supply = null
	max_shots = 10
	charge_cost = 20
	projectile_type = /obj/item/projectile/beam/stun
	firemodes = list(
		list(mode_name = "stun", projectile_type = /obj/item/projectile/beam/stun, fire_sound = 'sound/weapons/Taser.ogg'),
		list(mode_name = "lethal", projectile_type = /obj/item/projectile/beam, fire_sound = 'sound/weapons/Laser.ogg')
	)

/obj/item/weapon/gun/energy/gun/os13/update_icon()
	overlays.Cut()
	if(!power_supply)
		icon_state = "energy_empty"
	else
		icon_state = power_supply.charge < charge_cost ? "energy0" : "energy[max(25, round(power_supply.percent(), 25))]"
		// The supplied energystun/energykill states are indicator overlays,
		// not full weapon sprites. Keep the authored battery sprite underneath.
		overlays += overlay_image(icon, projectile_type == /obj/item/projectile/beam/stun ? "energystun" : "energykill")
	update_held_icon()

/obj/item/weapon/gun/energy/gun/os13/attack_self(mob/user)
	if(os13_weapon_held(src, user))
		return ..()

/obj/item/weapon/gun/energy/gun/os13/special_check(mob/user, obj/item/item)
	if(!os13_weapon_held(src, user))
		return FALSE
	return ..()

/obj/item/weapon/gun/energy/gun/os13/MouseDrop(atom/over_object)
	// Fixed battery, serviced by the standard station recharger.
	return

/obj/item/weapon/melee/energy/sword/os13
	name = "\improper Energy Sword"
	desc = "A compact energy blade. Activate it while held to extend the blade."
	icon = 'icons/os13/objects/objects/weapons/weapons.dmi'
	icon_state = "sword0"
	item_state = "sword0"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	sharp = FALSE
	edge = FALSE
	sword_light_color = COLOR_BLUE

/obj/item/weapon/melee/energy/sword/os13/update_icon()
	icon_state = active ? "sword1" : "sword0"
	item_state = icon_state
	update_held_icon()

/obj/item/weapon/melee/energy/sword/os13/attack_self(mob/living/user)
	if(os13_weapon_held(src, user))
		return ..()

/obj/item/weapon/melee/energy/sword/os13/activate(mob/living/user)
	if(active || !os13_weapon_held(src, user))
		return FALSE
	..()
	update_icon()
	return TRUE

/obj/item/weapon/melee/energy/sword/os13/deactivate(mob/living/user)
	..()
	update_icon()

/obj/item/weapon/melee/energy/sword/os13/attack(mob/living/target, mob/living/user, target_zone)
	if(!os13_weapon_held(src, user) || !target || !target.Adjacent(user))
		return FALSE
	return ..()

/datum/design/item/os13_energy_gun
	name = "Energy Gun"
	id = "os13_energy_gun"
	req_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 3)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 3000, "glass" = 1000)
	build_path = /obj/item/weapon/gun/energy/gun/os13
	sort_string = "VAAWV"

/datum/design/item/os13_energy_gun/Fabricate(newloc, fabricator)
	var/obj/item/weapon/gun/energy/gun/os13/weapon = ..()
	weapon.power_supply.charge = 0
	weapon.update_icon()
	return weapon

/datum/design/item/os13_energy_sword
	name = "Energy Sword"
	id = "os13_energy_sword"
	req_tech = list(TECH_COMBAT = 4, TECH_MAGNET = 4)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 1000)
	build_path = /obj/item/weapon/melee/energy/sword/os13
	sort_string = "VAAWW"
