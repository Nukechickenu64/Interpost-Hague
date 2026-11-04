/obj/machinery/chemical_dispenser
	name = "chemical dispenser"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dispenser"
	clicksound = "button"
	clickvol = 20

	var/list/spawn_cartridges = null // Set to a list of types to spawn one of each on New()

	var/list/cartridges = list() // Associative, label -> cartridge
	var/obj/item/reagent_containers/container = null

	var/ui_title = "Chemical Dispenser"

	var/accept_drinking = 0
	var/amount = 30

	idle_power_usage = 100
	density = 1
	anchored = 1
	obj_flags = OBJ_FLAG_ANCHORABLE

/obj/machinery/chemical_dispenser/New()
	..()

	if(spawn_cartridges)
		for(var/type in spawn_cartridges)
			add_cartridge(new type(src))

/obj/machinery/chemical_dispenser/examine(mob/user)
	. = ..()
	if(!istype(src, /obj/machinery/chemical_dispenser/os13))
		to_chat(user, "It has [cartridges.len] cartridges installed, and has space for [DISPENSER_MAX_CARTRIDGES - cartridges.len] more.")

/obj/machinery/chemical_dispenser/proc/add_cartridge(obj/item/reagent_containers/chem_disp_cartridge/C, mob/user)
	if(!istype(C))
		if(user)
			to_chat(user, "<span class='warning'>\The [C] will not fit in \the [src]!</span>")
		return

	if(cartridges.len >= DISPENSER_MAX_CARTRIDGES)
		if(user)
			to_chat(user, "<span class='warning'>\The [src] does not have any slots open for \the [C] to fit into!</span>")
		return

	if(!C.label)
		if(user)
			to_chat(user, "<span class='warning'>\The [C] does not have a label!</span>")
		return

	if(cartridges[C.label])
		if(user)
			to_chat(user, "<span class='warning'>\The [src] already contains a cartridge with that label!</span>")
		return

	if(user)
		if(!user.Adjacent(src) || user.incapacitated() || C.loc != user || !user.unEquip(C, target = src))
			return
		to_chat(user, "<span class='notice'>You add \the [C] to \the [src].</span>")
	else
		C.forceMove(src)
	cartridges[C.label] = C
	cartridges = sortAssoc(cartridges)
	SSnano.update_uis(src)

/obj/machinery/chemical_dispenser/proc/remove_cartridge(label)
	. = cartridges[label]
	cartridges -= label
	SSnano.update_uis(src)

/obj/machinery/chemical_dispenser/attackby(obj/item/W, mob/user)
	if(!user || !user.Adjacent(src) || user.incapacitated() || W.loc != user)
		return
	if(istype(W, /obj/item/vending_charge))
		refill_from_charge(W, user)
		return
	if(istype(W, /obj/item/reagent_containers/chem_disp_cartridge))
		add_cartridge(W, user)

	else if(isScrewdriver(W))
		var/list/choices = cartridges.Copy()
		var/label = input(user, "Which cartridge would you like to remove?", "Chemical Dispenser") as null|anything in choices
		if(!label || QDELETED(src) || QDELETED(W) || QDELETED(user) || !user.Adjacent(src) || user.incapacitated() || W.loc != user)
			return
		if(cartridges[label] != choices[label])
			to_chat(user, SPAN_WARNING("That cartridge has changed. Select it again."))
			return
		var/obj/item/reagent_containers/chem_disp_cartridge/C = remove_cartridge(label)
		if(C)
			to_chat(user, "<span class='notice'>You remove \the [C] from \the [src].</span>")
			C.dropInto(loc)

	else if(istype(W, /obj/item/reagent_containers/glass) || istype(W, /obj/item/reagent_containers/food))
		if(container)
			to_chat(user, "<span class='warning'>There is already \a [container] on \the [src]!</span>")
			return

		var/obj/item/reagent_containers/RC = W

		if(!accept_drinking && istype(RC,/obj/item/reagent_containers/food))
			to_chat(user, "<span class='warning'>This machine only accepts beakers!</span>")
			return

		if(!RC.is_open_container())
			to_chat(user, "<span class='warning'>You don't see how \the [src] could dispense reagents into \the [RC].</span>")
			return

		if(!user.unEquip(RC, target = src))
			return
		container = RC
		update_icon()
		to_chat(user, "<span class='notice'>You set \the [RC] on \the [src].</span>")
		SSnano.update_uis(src) // update all UIs attached to src

	else
		..()
	return

/obj/machinery/chemical_dispenser/proc/dispenser_data()
	// this is the data which will be sent to the ui
	var/data[0]
	data["amount"] = amount
	data["isBeakerLoaded"] = container ? 1 : 0
	data["glass"] = accept_drinking
	var beakerD[0]
	if(container && container.reagents && container.reagents.reagent_list.len)
		for(var/datum/reagent/R in container.reagents.reagent_list)
			beakerD[++beakerD.len] = list("name" = R.name, "volume" = R.volume)
	data["beakerContents"] = beakerD

	if(container)
		data["beakerCurrentVolume"] = container.reagents.total_volume
		data["beakerMaxVolume"] = container.reagents.maximum_volume
	else
		data["beakerCurrentVolume"] = null
		data["beakerMaxVolume"] = null

	var chemicals[0]
	for(var/label in cartridges)
		var/obj/item/reagent_containers/chem_disp_cartridge/C = cartridges[label]
		chemicals[++chemicals.len] = list("label" = label, "amount" = C.reagents.total_volume)
	data["chemicals"] = chemicals
	return data

/obj/machinery/chemical_dispenser/ui_interact(mob/user, ui_key = "main",var/datum/nanoui/ui = null, var/force_open = 1)
	var/list/data = dispenser_data()
	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "chem_disp.tmpl", ui_title, 390, 680)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/chemical_dispenser/OnTopic(user, href_list)
	if(href_list["amount"])
		var/requested_amount = text2num(href_list["amount"])
		if(!isnum_safe(requested_amount))
			to_chat(user, SPAN_WARNING("Invalid dispensing amount."))
			return TOPIC_HANDLED
		amount = round(requested_amount, 1) // round to nearest 1
		amount = max(0, min(120, amount)) // Since the user can actually type the commands himself, some sanity checking
		return TOPIC_REFRESH

	if(href_list["dispense"])
		if(dispense_reagent(href_list["dispense"], user))
			return TOPIC_REFRESH
		return TOPIC_HANDLED

	else if(href_list["ejectBeaker"])
		if(container)
			var/obj/item/reagent_containers/B = container
			B.dropInto(loc)
			container = null
			update_icon()
			return TOPIC_REFRESH
		return TOPIC_HANDLED

/obj/machinery/chemical_dispenser/proc/dispense_reagent(label, mob/user)
	var/obj/item/reagent_containers/chem_disp_cartridge/C = cartridges[label]
	if(C && C.loc == src && container && container.loc == src && container.is_open_container())
		C.reagents.trans_to(container, amount)
		return TRUE
	return FALSE

/obj/machinery/chemical_dispenser/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == container)
		container = null
		update_icon()
	for(var/label in cartridges)
		if(cartridges[label] == O)
			remove_cartridge(label)
			break
	SSnano.update_uis(src)

/obj/machinery/chemical_dispenser/attack_ai(mob/user as mob)
	ui_interact(user)

/obj/machinery/chemical_dispenser/attack_hand(mob/user as mob)
	ui_interact(user)

/obj/machinery/chemical_dispenser/update_icon()
	overlays.Cut()
	if(container)
		var/mutable_appearance/beaker_overlay
		beaker_overlay = image('icons/obj/chemical.dmi', src, "lil_beaker")
		beaker_overlay.pixel_x = rand(-10, 5)
		overlays += beaker_overlay

/obj/machinery/chemical_dispenser/os13
	name = "Chemfab"
	desc = "A keycard-locked chemical synthesizer supplied with Chemistry Charges and water. Swipe an authorized ID to unlock its controls."
	icon = 'icons/os13/objects/objects/orbital_decor2.dmi'
	icon_state = "chemfab0"
	ui_title = "Chemfab"
	amount = 5
	req_one_access = list(access_medical, access_chemistry)
	var/locked = TRUE
	var/water_volume = 0
	var/water_capacity = 500
	var/chemical_stock = 0
	var/charge_capacity = 500
	var/charge_refill = 5
	var/list/fabrication_reagents = list()
	var/list/injector_reagents = list("Dylovene" = /datum/reagent/dylovene, "Hyperzine" = /datum/reagent/hyperzine, "Hyperstim" = /datum/reagent/os13_medicine/hyperstim, "Mnemosine" = /datum/reagent/os13_medicine/mnemosine, "Oxivior" = /datum/reagent/os13_medicine/oxivior, "Monogreline" = /datum/reagent/os13_medicine/monogreline, "Polythesine" = /datum/reagent/os13_medicine/polythesine)
	var/list/injector_costs = list("Technetium" = 1, "Theosin" = 1, "Alzhesine" = 2, "Cordrazine" = 2, "Dentrine" = 2, "Dylovene" = 2, "Gelabine" = 2, "Hyperzine" = 2, "Jetamet" = 2, "LAD-5" = 2, "Mnemosine" = 2, "Oxivior" = 2, "Drenex" = 3, "Hyperstim" = 3, "Immirit" = 3, "Monogreline" = 3, "Polythesine" = 3)
	var/list/injector_products = list("Hyperstim" = /obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/hyperstim, "Mnemosine" = /obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/mnemosine, "Oxivior" = /obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/oxivior, "Monogreline" = /obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/monogreline, "Polythesine" = /obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/polythesine)

/obj/machinery/chemical_dispenser/os13/Initialize()
	. = ..()
	power_change()
	update_icon()

/obj/machinery/chemical_dispenser/os13/New()
	..()
	// Retain the local chemistry feedstocks as well as existing medical reagents.
	for(var/cartridge_type in standard_cartridges())
		var/obj/item/reagent_containers/chem_disp_cartridge/prototype = cartridge_type
		var/datum/reagent/reagent_type = initial(prototype.spawn_reagent)
		fabrication_reagents[initial(reagent_type.name)] = reagent_type
	for(var/reagent_type in list(/datum/reagent/dylovene, /datum/reagent/tramadol/oxycodone, /datum/reagent/spaceacillin))
		var/datum/reagent/R = reagent_type
		fabrication_reagents[initial(R.name)] = reagent_type
	fabrication_reagents = sortAssoc(fabrication_reagents)

/obj/machinery/chemical_dispenser/os13/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("The controls are [locked ? "keycard-locked" : "unlocked"]. Swipe a medical or chemistry ID to toggle the lock."))
	to_chat(user, SPAN_NOTICE("Water: [water_volume]/[water_capacity] units. Chemical feedstock: [chemical_stock]/[charge_capacity] units."))
	to_chat(user, SPAN_NOTICE("Insert a Chemistry Charge for feedstock. Load an open beaker of clean water and use Load Water. Select an injector, or use compatibility dispensing for beaker output."))

/obj/machinery/chemical_dispenser/os13/attackby(obj/item/W, mob/user)
	if(!user || user.incapacitated() || !Adjacent(user) || W.loc != user)
		if(user)
			to_chat(user, SPAN_WARNING("You must be able to use a held item beside the Chemfab."))
		return
	var/obj/item/card/id/card = W.GetIdCard()
	if(card)
		if(!operable() || !powered())
			to_chat(user, SPAN_WARNING("The Chemfab is not operational."))
			return
		if(!check_access(card))
			to_chat(user, SPAN_WARNING("Access denied. A medical or chemistry ID is required."))
			return
		locked = !locked
		add_fingerprint(user)
		visible_message(SPAN_NOTICE("[user] [locked ? "locks" : "unlocks"] the Chemfab!"))
		SSnano.update_uis(src)
		return
	// The recording shows charge servicing before the controls are unlocked.
	if(istype(W, /obj/item/vending_charge))
		return ..()
	if(locked)
		to_chat(user, SPAN_WARNING("Not possible. The machine is keycard-locked!"))
		return
	return ..()

/obj/machinery/chemical_dispenser/os13/proc/can_fabricate(mob/user)
	if(!user || !Adjacent(user) || CanUseTopic(user, GLOB.default_state) != STATUS_INTERACTIVE || !operable() || !powered())
		if(user)
			to_chat(user, SPAN_WARNING("The Chemfab controls are not accessible or operational."))
		return FALSE
	if(locked)
		to_chat(user, SPAN_WARNING("Not possible. The machine is keycard-locked!"))
		return FALSE
	return TRUE

/obj/machinery/chemical_dispenser/os13/add_cartridge(obj/item/reagent_containers/chem_disp_cartridge/C, mob/user)
	if(user)
		to_chat(user, SPAN_WARNING("The Chemfabricator uses Chemistry Charges and water, not reagent cartridges."))
	return FALSE

/obj/machinery/chemical_dispenser/os13/refill_from_charge(obj/item/vending_charge/charge, mob/user)
	if(!charge || !user || !user.Adjacent(src) || user.incapacitated() || charge.loc != user)
		return FALSE
	if(!istype(charge, /obj/item/vending_charge/chemistry))
		to_chat(user, SPAN_WARNING("The Chemfabricator only accepts Chemistry Charges."))
		return FALSE
	if(chemical_stock + charge_refill > charge_capacity)
		to_chat(user, SPAN_WARNING("There is not enough room for a full Chemistry Charge. The charge is unchanged."))
		return FALSE
	if(!user.unEquip(charge, target = src))
		to_chat(user, SPAN_WARNING("You must be able to release the held Chemistry Charge."))
		return FALSE
	chemical_stock += charge_refill
	qdel(charge)
	to_chat(user, SPAN_NOTICE("You load the charge into the machine. Charge increases by [charge_refill] to [chemical_stock]. Water is required separately."))
	SSnano.update_uis(src)
	return TRUE

/obj/machinery/chemical_dispenser/os13/dispenser_data()
	var/list/data = ..()
	data["chemfabricator"] = TRUE
	data["waterVolume"] = water_volume
	data["waterCapacity"] = water_capacity
	data["chemicalStock"] = chemical_stock
	data["chargeCapacity"] = charge_capacity
	data["chargeRefill"] = charge_refill
	data["locked"] = locked
	var/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/product_type = /obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab
	data["injectorVolume"] = initial(product_type.volume)
	var/list/injectors = list()
	for(var/label in injector_costs)
		injectors += list(list("label" = label, "cost" = injector_costs[label], "available" = !!injector_reagents[label]))
	data["injectors"] = injectors
	var/list/chemicals = list()
	for(var/label in fabrication_reagents)
		chemicals += list(list("label" = label, "amount" = min(water_volume, chemical_stock)))
	data["chemicals"] = chemicals
	return data

/obj/machinery/chemical_dispenser/os13/OnTopic(user, href_list)
	if(!can_fabricate(user))
		return TOPIC_HANDLED
	if(href_list["makeInjector"])
		fabricate_injector(href_list["makeInjector"], user)
		return TOPIC_REFRESH
	if(href_list["loadWater"])
		load_water(user)
		return TOPIC_REFRESH
	return ..()

/obj/machinery/chemical_dispenser/os13/proc/load_water(mob/user)
	if(!can_fabricate(user))
		return FALSE
	if(!container || container.loc != src || !container.is_open_container() || !container.reagents)
		to_chat(user, SPAN_WARNING("Load an open beaker of clean water first."))
		return FALSE
	if(container.reagents.reagent_list.len != 1 || !container.reagents.has_reagent(/datum/reagent/water))
		to_chat(user, SPAN_WARNING("Only clean water can be loaded. The beaker's contents are unchanged."))
		return FALSE
	var/transferred = min(water_capacity - water_volume, container.reagents.get_reagent_amount(/datum/reagent/water))
	if(transferred <= 0)
		to_chat(user, SPAN_WARNING("The water reservoir is full."))
		return FALSE
	container.reagents.remove_reagent(/datum/reagent/water, transferred)
	water_volume += transferred
	to_chat(user, SPAN_NOTICE("You transfer [transferred] units of water into the reservoir."))
	return TRUE

/obj/machinery/chemical_dispenser/os13/dispense_reagent(label, mob/user)
	if(!can_fabricate(user))
		return FALSE
	var/reagent_type = fabrication_reagents[label]
	if(!reagent_type)
		to_chat(user, SPAN_WARNING("That reagent is not available from this Chemfabricator."))
		return FALSE
	if(!container || container.loc != src || !container.is_open_container() || !container.reagents)
		to_chat(user, SPAN_WARNING("Load an open beaker to receive the product."))
		return FALSE
	if(amount <= 0 || !isnum_safe(amount))
		to_chat(user, SPAN_WARNING("Select a positive dispensing amount."))
		return FALSE
	if(container.reagents.get_free_space() < amount)
		to_chat(user, SPAN_WARNING("The beaker cannot hold the full [amount]-unit batch."))
		return FALSE
	if(water_volume < amount || chemical_stock < amount)
		to_chat(user, SPAN_WARNING("A [amount]-unit batch requires [amount] units each of water and chemical feedstock."))
		return FALSE
	// Commit resources before mixing; the product may react with the beaker.
	water_volume -= amount
	chemical_stock -= amount
	if(!container.reagents.add_reagent(reagent_type, amount))
		water_volume += amount
		chemical_stock += amount
		to_chat(user, SPAN_WARNING("Fabrication failed. Water and feedstock have been restored."))
		return FALSE
	to_chat(user, SPAN_NOTICE("The Chemfabricator dispenses [amount] units of [label]."))
	return TRUE

/obj/machinery/chemical_dispenser/os13/proc/fabricate_injector(label, mob/user)
	if(!can_fabricate(user))
		return FALSE
	var/reagent_type = injector_reagents[label]
	var/cost = injector_costs[label]
	if(!ispath(reagent_type, /datum/reagent) || !isnum_safe(cost) || cost <= 0)
		to_chat(user, SPAN_WARNING("That drug has no implemented Chemfab formulation. No supplies were used."))
		return FALSE
	var/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/product_type = injector_products[label] ? injector_products[label] : /obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab
	var/dose = initial(product_type.volume)
	if(water_volume < dose || chemical_stock < cost)
		to_chat(user, SPAN_WARNING("This injector requires [cost] feedstock units and [dose] units of water."))
		return FALSE
	var/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/product = new(src)
	if(!product.reagents.total_volume)
		product.reagents.add_reagent(reagent_type, dose)
	if(product.reagents.total_volume != dose || product.reagents.get_reagent_amount(reagent_type) != dose || product.reagents.reagent_list.len != 1)
		qdel(product)
		to_chat(user, SPAN_WARNING("Injector fabrication failed. No supplies were used."))
		return FALSE
	water_volume -= dose
	chemical_stock -= cost
	product.SetName("[lowertext(label)] injector")
	product.dropInto(loc)
	if(ishuman(user))
		user.put_in_hands(product)
	add_fingerprint(user)
	to_chat(user, SPAN_NOTICE("The Chemfab produces \a [product]."))
	return TRUE

/obj/machinery/chemical_dispenser/os13/update_icon()
	overlays.Cut()
	if(stat & BROKEN)
		icon_state = "chemfabb"
	else
		icon_state = (stat & NOPOWER) ? "chemfab0" : "chemfab1"
	var/image/top = image(icon, icon_state = "chemfab2", dir = NORTH)
	top.pixel_y = 32
	top.layer = ABOVE_HUMAN_LAYER
	overlays += top
	var/image/top_right = image(icon, icon_state = "chemfab2", dir = EAST)
	top_right.pixel_x = 32
	top_right.pixel_y = 32
	top_right.layer = ABOVE_HUMAN_LAYER
	overlays += top_right
	var/image/tank = image(icon, icon_state = "chemfab2", dir = SOUTH)
	tank.pixel_x = 32
	overlays += tank
	if(!(stat & (NOPOWER|BROKEN)))
		overlays += overlay_image(icon, "chemfabo", plane = ABOVE_LIGHTING_PLANE, layer = ABOVE_LIGHTING_LAYER)
