// Reference: Fliche's water-chip video, 18:30-20:00 and 1:03:45-1:06:15.
// One precursor makes one refill. Duration and cargo prices are local balance.
/obj/item/precursor_charge
	name = "precursor charge"
	desc = "An unconfigured refill pack. Select a product on a ChargeMaster, then insert this charge."
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "generic-charge"
	item_state = "vcharge"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_NORMAL

/obj/machinery/chargemaster
	name = "ChargeMaster"
	desc = "Click the selector to cycle refill types, then insert a precursor charge. Conversion takes five seconds. Alt-click to recover an unfinished precursor."
	icon = 'icons/os13/objects/objects/chargemaster.dmi'
	icon_state = "cmaster"
	density = TRUE
	anchored = TRUE
	obj_flags = OBJ_FLAG_ANCHORABLE
	idle_power_usage = 50
	active_power_usage = 2000
	var/list/charge_types = list("Equipment" = /obj/item/vending_charge, "Soda" = /obj/item/vending_charge/soda, "Security" = /obj/item/vending_charge/security, "Cigarette" = /obj/item/vending_charge/cigarette, "Bar" = /obj/item/vending_charge/bar, "Chemistry" = /obj/item/vending_charge/chemistry, "Coffee" = /obj/item/vending_charge/coffee, "Hydroponics" = /obj/item/vending_charge/hydroponics, "Snack" = /obj/item/vending_charge/snack)
	var/selected = "Equipment"
	var/output_type
	var/obj/item/precursor_charge/precursor
	var/work_left = 0
	var/last_process = 0

/obj/machinery/chargemaster/examine(mob/user)
	. = ..()
	to_chat(user, "Selected: [selected]. [precursor ? "A precursor is being converted." : "Insert a precursor charge."]")

/obj/machinery/chargemaster/attack_hand(mob/user)
	if(!user || user.incapacitated() || !Adjacent(user) || !operable() || !powered())
		return
	if(precursor)
		to_chat(user, "The ChargeMaster is busy. Alt-click to cancel and recover the precursor.")
		return
	var/index = charge_types.Find(selected) + 1
	selected = charge_types[index > length(charge_types) ? 1 : index]
	to_chat(user, "Selected: [selected]")
	update_icon()

/obj/machinery/chargemaster/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/precursor_charge))
		if(!load_charge(O, user))
			to_chat(user, "The ChargeMaster must be powered, working and empty. Hold a precursor charge to load it.")
		return
	return ..()

/obj/machinery/chargemaster/proc/load_charge(obj/item/precursor_charge/C, mob/user)
	if(!C || !user || user.incapacitated() || !Adjacent(user) || C.loc != user || precursor || !operable() || !powered() || !charge_types[selected])
		return FALSE
	if(!user.unEquip(C, target = src))
		return FALSE
	precursor = C
	output_type = charge_types[selected]
	work_left = 5 SECONDS
	last_process = world.time
	update_use_power(POWER_USE_ACTIVE)
	update_icon()
	flick("cmaster_process", src)
	return TRUE

/obj/machinery/chargemaster/Process()
	var/elapsed = max(0, world.time - last_process)
	last_process = world.time
	advance_cycle(elapsed)

/obj/machinery/chargemaster/proc/advance_cycle(elapsed)
	if(!precursor || !work_left || !operable() || !powered() || elapsed <= 0)
		return
	work_left = max(0, work_left - elapsed)
	if(work_left)
		return
	var/obj/item/precursor_charge/consumed = precursor
	precursor = null
	new output_type(get_turf(src))
	output_type = null
	qdel(consumed)
	update_use_power(POWER_USE_IDLE)
	update_icon()
	visible_message(SPAN_NOTICE("[name]: Happy charging."))
	ping()

/obj/machinery/chargemaster/AltClick(mob/user)
	if(!user || user.incapacitated() || !Adjacent(user) || !precursor)
		return ..()
	var/obj/item/precursor_charge/C = precursor
	C.forceMove(get_turf(src))
	user.put_in_hands(C)
	return TRUE

/obj/machinery/chargemaster/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == precursor)
		precursor = null
		output_type = null
		work_left = 0
		update_use_power(POWER_USE_IDLE)
		update_icon()

/obj/machinery/chargemaster/Destroy()
	if(precursor)
		precursor.forceMove(get_turf(src))
	return ..()

/obj/machinery/chargemaster/update_icon()
	overlays.Cut()
	icon_state = "cmaster"
	if(!operable() || !powered())
		return
	if(work_left)
		return
	var/obj/item/vending_charge/C = charge_types[selected]
	if(C)
		var/preview = initial(C.icon_state)
		if(!(preview in icon_states(icon)))
			preview = "generic-charge"
		overlays += image(icon, preview)

/obj/structure/closet/crate/precursor_charges
	name = "precursor charge crate"

/obj/structure/closet/crate/precursor_charges/WillContain()
	return list(/obj/item/precursor_charge = 12)

/decl/hierarchy/supply_pack/supply/precursor_charges
	name = "Precursor charges (12)"
	contains = list(/obj/item/precursor_charge = 12)
	cost = 60
	containername = "precursor charge crate"

/decl/hierarchy/supply_pack/supply/chargemaster
	name = "ChargeMaster"
	contains = list(/obj/machinery/chargemaster)
	cost = 40
	containertype = /obj/structure/closet/crate/large
	containername = "ChargeMaster crate"

// Replenish only the family's standard cartridges. Never overwrite a custom
// mixture, relabel a player's cartridge, or add restricted medicine presets.
/obj/machinery/chemical_dispenser/proc/charge_stock(family)
	var/obj/machinery/chemical_dispenser/preset
	if(istype(src, /obj/machinery/chemical_dispenser/bar_soft))
		if(family == "soda")
			preset = /obj/machinery/chemical_dispenser/bar_soft/full
	else if(istype(src, /obj/machinery/chemical_dispenser/bar_alc))
		if(family == "bar")
			preset = /obj/machinery/chemical_dispenser/bar_alc/full
	else if(istype(src, /obj/machinery/chemical_dispenser/bar_coffee))
		if(family == "coffee")
			preset = /obj/machinery/chemical_dispenser/bar_coffee/full
	else if(family == "chemistry" && (type == /obj/machinery/chemical_dispenser || istype(src, /obj/machinery/chemical_dispenser/full) || istype(src, /obj/machinery/chemical_dispenser/lower_budget)))
		preset = /obj/machinery/chemical_dispenser/full
	if(preset)
		return spawn_cartridges ? spawn_cartridges : standard_cartridges()

/obj/machinery/chemical_dispenser/proc/refill_from_charge(obj/item/vending_charge/charge, mob/user)
	if(!charge || !user || user.incapacitated() || !Adjacent(user) || charge.loc != user)
		return FALSE
	var/list/stock = charge_stock(charge.dispenser_family)
	if(!length(stock))
		to_chat(user, "That charge does not fit this dispenser.")
		return FALSE
	var/list/top_up = list()
	var/list/missing = list()
	for(var/cartridge_type in stock)
		var/obj/item/reagent_containers/chem_disp_cartridge/prototype = cartridge_type
		var/datum/reagent/reagent_type = initial(prototype.spawn_reagent)
		var/label = initial(reagent_type.name)
		var/obj/item/reagent_containers/chem_disp_cartridge/C = cartridges[label]
		if(!C)
			if(length(cartridges) + length(missing) < DISPENSER_MAX_CARTRIDGES)
				missing += prototype
			continue
		if(C.type != prototype || C.loc != src || !C.reagents || C.reagents.get_free_space() <= 0)
			continue
		var/pure = TRUE
		for(var/datum/reagent/R in C.reagents.reagent_list)
			if(R.type != reagent_type)
				pure = FALSE
		if(pure)
			top_up += C
	if(!length(top_up) && !length(missing))
		to_chat(user, "No standard cartridges need replenishing. Custom mixtures are left untouched.")
		return FALSE
	if(!user.unEquip(charge, target = src))
		return FALSE
	for(var/obj/item/reagent_containers/chem_disp_cartridge/C in top_up)
		C.reagents.add_reagent(C.spawn_reagent, C.reagents.get_free_space())
	for(var/cartridge_type in missing)
		add_cartridge(new cartridge_type(src))
	qdel(charge)
	to_chat(user, "You insert the charge into the machine. Its standard reagents are replenished.")
	SSnano.update_uis(src)
	return TRUE
