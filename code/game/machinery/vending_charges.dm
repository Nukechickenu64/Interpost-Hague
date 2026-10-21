// Physical restocking cartridges, as used by logistics in the reference video.
// Refill normal products to their configured capacity; premium/hidden stock and
// individually returned products remain untouched.
/obj/item/vending_charge
	name = "equipment charge"
	desc = "A sealed equipment-vendor refill. Insert it into a compatible machine to replenish its ordinary stock."
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "equipment-charge"
	item_state = "vcharge"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_NORMAL
	var/list/vendor_types = list(/obj/machinery/vending/engineering, /obj/machinery/vending/engivend, /obj/machinery/vending/tool, /obj/machinery/vending/medical, /obj/machinery/vending/wallmed1, /obj/machinery/vending/wallmed2)
	var/dispenser_family

/obj/item/vending_charge/coffee
	name = "coffee charge"
	desc = "A sealed refill for a coffee vendor."
	icon_state = "coffee-charge"
	vendor_types = list(/obj/machinery/vending/coffee)
	dispenser_family = "coffee"

/obj/item/vending_charge/soda
	name = "soda machine charge"
	desc = "A sealed refill for a soda vendor."
	icon_state = "soda-charge"
	vendor_types = list(/obj/machinery/vending/cola)
	dispenser_family = "soda"

/obj/item/vending_charge/cigarette
	name = "cigarette charge"
	desc = "A sealed refill for a cigarette vendor."
	icon_state = "cigarette-charge"
	vendor_types = list(/obj/machinery/vending/cigarette)

/obj/item/vending_charge/bar
	name = "bar charge"
	desc = "A sealed refill for bar vendors and alcohol dispensers."
	icon_state = "bar-charge"
	vendor_types = list(/obj/machinery/vending/boozeomat)
	dispenser_family = "bar"

/obj/item/vending_charge/chemistry
	name = "chemistry charge"
	desc = "A sealed refill for a standard chemical dispenser's basic reagent cartridges."
	icon_state = "chemistry-charge"
	vendor_types = list()
	dispenser_family = "chemistry"

/obj/item/vending_charge/hydroponics
	name = "hydroponics charge"
	desc = "A sealed refill of vat cultures, seeds and hydroponics supplies."
	icon_state = "hydro-charge"
	vendor_types = list(/obj/machinery/vending/hydro_cultures, /obj/machinery/vending/hydronutrients, /obj/machinery/vending/hydroseeds)

/obj/item/vending_charge/snack
	name = "snack charge"
	desc = "A sealed refill for a snack vendor."
	icon_state = "snack-charge"
	vendor_types = list(/obj/machinery/vending/snack)

/obj/item/vending_charge/security
	name = "security charge"
	desc = "A sealed refill for ordinary security equipment. It does not replenish restricted stock."
	icon_state = "security-charge"
	vendor_types = list(/obj/machinery/vending/security)

/obj/machinery/vending/engineering/os13
	name = "equipment vendor"
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "equipment"
	icon_vend = "equipment-vend"
	icon_deny = "equipment-deny"

/obj/item/vending_charge/proc/compatible(obj/machinery/vending/V)
	for(var/vendor_type in vendor_types)
		if(istype(V, vendor_type))
			return TRUE
	return FALSE

/obj/machinery/vending/proc/refill_from_charge(obj/item/vending_charge/C, mob/user)
	if(!user || !user.Adjacent(src) || user.incapacitated() || C.loc != user || !C.compatible(src))
		to_chat(user, SPAN_WARNING("That charge does not fit this vendor."))
		return FALSE
	var/needed = 0
	for(var/datum/stored_items/vending_products/R in product_records)
		if(R.category != CAT_NORMAL || !(R.item_path in products))
			continue
		needed += max(0, (products[R.item_path] ? products[R.item_path] : 1) - R.get_amount())
	if(!needed)
		to_chat(user, SPAN_NOTICE("The vendor does not need replenishing."))
		return FALSE
	if(!user.unEquip(C, target = src))
		return FALSE
	for(var/datum/stored_items/vending_products/R in product_records)
		if(R.category != CAT_NORMAL || !(R.item_path in products))
			continue
		var/add_count = max(0, (products[R.item_path] ? products[R.item_path] : 1) - R.get_amount())
		if(R.instances)
			for(var/i = 1 to add_count)
				R.add_product(new R.item_path(src))
		else
			R.amount += add_count
	qdel(C)
	to_chat(user, SPAN_NOTICE("You insert the charge into the machine. Its supplies are replenished."))
	SSnano.update_uis(src)
	return TRUE

/decl/hierarchy/supply_pack/supply/vending_charges
	name = "Vending refill charges"
	contains = list(/obj/item/vending_charge = 2, /obj/item/vending_charge/coffee, /obj/item/vending_charge/soda, /obj/item/vending_charge/snack)
	cost = 20
	containername = "vending refill crate"

/decl/hierarchy/supply_pack/security/vending_charges
	name = "Security vending refills"
	contains = list(/obj/item/vending_charge/security = 2)
	cost = 20
	containername = "security vending refill crate"


/obj/machinery/vending/cigarette/os13
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "cigs"
	icon_vend = null
	icon_deny = null
