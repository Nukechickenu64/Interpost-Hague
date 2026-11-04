/obj/item/vending_charge
	name = "Equipment Charge"
	desc = "A sealed fabrication token. Inserting it into any vending machine adds ten creation charges."
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "equipment-charge"
	item_state = "vcharge"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_NORMAL
	var/dispenser_family

/obj/item/vending_charge/coffee
	name = "Coffee Charge"
	icon_state = "coffee-charge"
	dispenser_family = "coffee"

/obj/item/vending_charge/coffee/compatible(obj/machinery/vending/V)
	return istype(V, /obj/machinery/vending/coffee)

/obj/item/vending_charge/soda
	name = "Soda Machine Charge"
	icon_state = "soda-charge"
	dispenser_family = "soda"

/obj/item/vending_charge/soda/compatible(obj/machinery/vending/V)
	return istype(V, /obj/machinery/vending/cola)

/obj/item/vending_charge/cigarette
	name = "Cigarette Charge"
	icon_state = "cigarette-charge"

/obj/item/vending_charge/cigarette/compatible(obj/machinery/vending/V)
	return istype(V, /obj/machinery/vending/cigarette)

/obj/item/vending_charge/bar
	name = "Bar Charge"
	icon_state = "bar-charge"
	dispenser_family = "bar"

/obj/item/vending_charge/bar/compatible(obj/machinery/vending/V)
	return istype(V, /obj/machinery/vending/boozeomat)

/obj/item/vending_charge/chemistry
	name = "Chemistry Charge"
	desc = "A sealed chemical feedstock charge. Adds five charge points to a Chemfab, or refills compatible cartridge dispensers."
	icon_state = "chemistry-charge"
	dispenser_family = "chemistry"

/obj/item/vending_charge/chemistry/compatible(obj/machinery/vending/V)
	return FALSE

/obj/item/vending_charge/hydroponics
	name = "Hydroponics Charge"
	icon_state = "hydro-charge"

/obj/item/vending_charge/hydroponics/compatible(obj/machinery/vending/V)
	return istype(V, /obj/machinery/vending/hydro_cultures)

/obj/item/vending_charge/snack
	name = "Snack Charge"
	icon_state = "snack-charge"

/obj/item/vending_charge/snack/compatible(obj/machinery/vending/V)
	return istype(V, /obj/machinery/vending/snack)

/obj/item/vending_charge/security
	name = "Security Charge"
	icon_state = "security-charge"

/obj/item/vending_charge/security/compatible(obj/machinery/vending/V)
	return istype(V, /obj/machinery/vending/security)

/obj/machinery/vending/engineering/os13
	name = "equipment vendor"
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "equipment"
	icon_vend = "equipment-vend"
	icon_deny = "equipment-deny"

/obj/item/vending_charge/proc/compatible(obj/machinery/vending/V)
	return istype(V)

/obj/item/vending_charge/afterattack(obj/item/target, mob/user, proximity)
	if(type != /obj/item/vending_charge || !proximity || !istype(target) || !target.hidden_uplink?.active)
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
	to_chat(user, SPAN_NOTICE("You insert the charge into the machine. The machine now has [creation_charges] charges."))
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
