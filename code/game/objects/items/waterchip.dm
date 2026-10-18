GLOBAL_VAR_INIT (waterchip_installed,0)

/obj/item/device/waterchip
	name = "water chip"
	desc = "This neat thing provides water to the entire station if installed properly."
	icon_state = "chip"
	icon = 'icons/obj/waterchip.dmi'
	force = 1
	w_class = 3
	slot_flags = SLOT_HEAD | SLOT_MASK
	matter = list("steel" = 5000)

/obj/machinery/waterchip_holder
	name = "water chip holder"
	desc = "This is where you hold the water chip. It provides water. Hold it."
	density = 1
	anchored = 1
	icon = 'icons/obj/waterchip.dmi'
	icon_state = "holder1"

	// Power
	idle_power_usage = 10
	active_power_usage = 40 KILOWATTS
	var/obj/item/device/waterchip/installed_chip

/obj/machinery/waterchip_holder/attackby(obj/item/G as obj, mob/user as mob)
	if(!user || user.incapacitated() || !Adjacent(user) || istype(user,/mob/living/silicon))
		return

	if (istype(G, /obj/item/device/waterchip))
		if(installed_chip)
			to_chat(user, "There's already a water chip here.")
			return
		if(!user.unEquip(G, target = src))
			return
		installed_chip = G
		to_chat(user, "You install the chip.")
		refresh_water_supply()
		update_icon()
		playsound(loc, 'sound/items/Ratchet.ogg', 75, 1)
		if(GLOB.bridge_crew_objectives)
			GLOB.bridge_crew_objectives.check_progress()
		return
	return ..()

/obj/machinery/waterchip_holder/attack_hand(mob/user as mob)
	if(!user || user.incapacitated() || !Adjacent(user) || istype(user,/mob/living/silicon))
		return
	remove_chip(user)

/obj/machinery/waterchip_holder/proc/remove_chip(mob/user)
	if(installed_chip)
		var/obj/item/device/waterchip/W = installed_chip
		installed_chip = null
		W.forceMove(get_turf(src))
		user.put_in_hands(W)
		refresh_water_supply()
		update_icon()
		to_chat(user, "You uninstall the chip.")
	else
		to_chat(user, "There is no chip installed.")

/proc/refresh_water_supply()
	GLOB.waterchip_installed = FALSE
	for(var/obj/machinery/waterchip_holder/H in SSmachines.machinery)
		if(!QDELETED(H) && !QDELETED(H.installed_chip) && H.installed_chip.loc == H)
			GLOB.waterchip_installed = TRUE
			return
	for(var/obj/machinery/computer/hydroponics/C in SSmachines.machinery)
		if(!QDELETED(C) && !QDELETED(C.installed_chip) && C.installed_chip.loc == C)
			GLOB.waterchip_installed = TRUE
			return

/obj/machinery/waterchip_holder/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == installed_chip)
		installed_chip = null
		refresh_water_supply()
		update_icon()

/obj/machinery/waterchip_holder/Destroy()
	if(installed_chip)
		installed_chip.forceMove(get_turf(src))
		installed_chip = null
	refresh_water_supply()
	return ..()

/obj/machinery/waterchip_holder/update_icon()
	if(installed_chip)
		icon_state = "holder2"
	else
		icon_state = "holder1"
