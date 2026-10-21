/obj/item/vending_charge
	name = "universal creation token"
	desc = "A sealed fabrication token. Inserting it into any vending machine adds ten creation charges."
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "equipment-charge"
	item_state = "vcharge"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_NORMAL
	var/dispenser_family

/obj/item/vending_charge/coffee
	icon_state = "coffee-charge"
	dispenser_family = "coffee"

/obj/item/vending_charge/soda
	icon_state = "soda-charge"
	dispenser_family = "soda"

/obj/item/vending_charge/cigarette
	icon_state = "cigarette-charge"

/obj/item/vending_charge/bar
	icon_state = "bar-charge"
	dispenser_family = "bar"

/obj/item/vending_charge/chemistry
	icon_state = "chemistry-charge"
	dispenser_family = "chemistry"

/obj/item/vending_charge/hydroponics
	icon_state = "hydro-charge"

/obj/item/vending_charge/snack
	icon_state = "snack-charge"

/obj/item/vending_charge/security
	icon_state = "security-charge"

/obj/machinery/vending/engineering/os13
	name = "equipment vendor"
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "equipment"
	icon_vend = "equipment-vend"
	icon_deny = "equipment-deny"

/obj/item/vending_charge/proc/compatible(obj/machinery/vending/V)
	return istype(V)

/obj/item/vending_charge/afterattack(obj/item/target, mob/user, proximity)
	if(!proximity || !istype(target) || !target.hidden_uplink?.active)
		return ..()
	if(loc != user || user.incapacitated() || !user.unEquip(src, target = target))
		return
	target.hidden_uplink.uses += 10
	target.hidden_uplink.update_nano_data()
	SSnano.update_uis(target.hidden_uplink)
	to_chat(user, SPAN_NOTICE("The uplink now has [target.hidden_uplink.uses] creation charges."))
	qdel(src)

/obj/machinery/vending/proc/refill_from_charge(obj/item/vending_charge/C, mob/user)
	if(!user || !user.Adjacent(src) || user.incapacitated() || C.loc != user || !C.compatible(src))
		to_chat(user, SPAN_WARNING("That charge does not fit this vendor."))
		return FALSE
	if(!user.unEquip(C, target = src))
		return FALSE
	creation_charges += 10
	qdel(C)
	to_chat(user, SPAN_NOTICE("You insert the creation token. The machine now has [creation_charges] charges."))
	SSnano.update_uis(src)
	return TRUE

/decl/hierarchy/supply_pack/supply/vending_charges
	name = "Vending refill charges"
	contains = list(/obj/item/vending_charge = 2, /obj/item/vending_charge/coffee, /obj/item/vending_charge/soda, /obj/item/vending_charge/snack)
	containername = "vending refill crate"

/decl/hierarchy/supply_pack/security/vending_charges
	name = "Security vending refills"
	contains = list(/obj/item/vending_charge/security = 2)
	containername = "security vending refill crate"


/obj/machinery/vending/cigarette/os13
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "cigs"
	icon_vend = null
	icon_deny = null
