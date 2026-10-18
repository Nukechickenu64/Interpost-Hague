// Vat hydroponics: https://lfwb.at/index.php?title=Logistics_Officer (revision 3443).
// The guide specifies the workflow; batch sizes and timings below are local balance values.
#define BIOMASS_VAT_EMPTY 0
#define BIOMASS_VAT_FILLING 1
#define BIOMASS_VAT_FILLED 2
#define BIOMASS_VAT_GROWING 3
#define BIOMASS_VAT_STIR 4
#define BIOMASS_VAT_READY 5

/obj/item/hydroponics_supply
	w_class = ITEM_SIZE_SMALL

/obj/item/hydroponics_supply/yeast
	name = "yeast packet"
	desc = "A starter culture for a water-filled hydroponics vat. Add one packet and one glig per batch."
	icon = 'icons/os13/objects/objects/cooking.dmi'
	icon_state = "yeastpack"
	item_state = "cigpacket"

/obj/item/hydroponics_supply/glig
	name = "glig"
	desc = "A fibrous culture used to grow biomass. Add it and yeast to a water-filled vat."
	icon = 'icons/os13/objects/objects/food/harvest.dmi'
	icon_state = "glig"
	item_state = "nettle"

/obj/item/hydroponics_supply/biomass
	name = "biomass brick"
	desc = "Pressed vat-grown biomass. A food processor can shape it into a meal; a cloning pod accepts it as 50 units of feedstock."
	icon = 'icons/os13/objects/objects/cooking.dmi'
	icon_state = "soylent"
	item_state = "brick"

/obj/item/hydroponics_supply/skimmer
	name = "skimmer"
	desc = "Stir a vat when its red light flashes. Scoop goo when its green light flashes, then empty the skimmer into a biomass press."
	icon = 'icons/os13/os13hydroitems.dmi'
	icon_state = "spaceshovel0"
	item_state = "shovel"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_NORMAL
	force = 5
	var/loaded = FALSE

/obj/item/hydroponics_supply/skimmer/update_icon()
	icon_state = loaded ? "spaceshovel1" : "spaceshovel0"

/obj/item/hydroponics_supply/skimmer/examine(mob/user)
	. = ..()
	to_chat(user, loaded ? "The skimmer is full of goo. Empty it into a biomass press." : "The skimmer is empty.")

/obj/machinery/computer/hydroponics
	name = "hydroponics console"
	desc = "Monitors biomass vats and controls their water supply. Install a Water Chip from Research, then select Fill empty vats. Alt-click to recover the chip."
	icon_screen = "tank"
	icon_keyboard = "atmos_key"
	light_color = "#66c9b5"
	circuit = /obj/item/circuitboard/hydroponics
	idle_power_usage = 100
	active_power_usage = 1000
	obj_flags = OBJ_FLAG_ANCHORABLE
	var/obj/item/device/waterchip/installed_chip

/obj/item/circuitboard/hydroponics
	name = "circuit board (hydroponics console)"
	build_path = /obj/machinery/computer/hydroponics

/obj/machinery/computer/hydroponics/attack_hand(mob/user)
	if(..() || !user || user.incapacitated() || !Adjacent(user))
		return
	ui_interact(user)

/obj/machinery/computer/hydroponics/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = TRUE)
	var/list/data = get_ui_data()
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "hydroponics_control.tmpl", "Hydroponics Control", 620, 540)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(TRUE)

/obj/machinery/computer/hydroponics/proc/get_connected_vats()
	var/list/vats = list()
	for(var/obj/machinery/biomass_vat/V in SSmachines.machinery)
		if(!QDELETED(V) && V.z == z && get_area(V) == get_area(src))
			vats += V
	return vats

/obj/machinery/computer/hydroponics/proc/get_ui_data()
	var/list/data = list("chip_installed" = !!installed_chip, "can_fill" = FALSE, "vats" = list())
	for(var/obj/machinery/biomass_vat/V in get_connected_vats())
		var/vat_powered = V.operable() && V.powered()
		data["vats"] += list(list("position" = "[V.x], [V.y]", "status" = V.get_status_text(), "powered" = vat_powered, "yeast" = V.has_yeast, "glig" = V.has_glig, "stirs" = V.stirs, "stirs_required" = V.stirs_required, "portions" = V.portions, "needs_stir" = V.stage == BIOMASS_VAT_STIR, "ready" = V.stage == BIOMASS_VAT_READY))
		if(installed_chip && vat_powered && V.stage == BIOMASS_VAT_EMPTY)
			data["can_fill"] = TRUE
	data["can_fill"] = data["can_fill"] && operable() && powered()
	return data

/obj/machinery/computer/hydroponics/OnTopic(mob/user, href_list)
	if(!user || user.incapacitated() || !Adjacent(user) || !operable() || !powered())
		return TOPIC_HANDLED
	if(href_list["fill"])
		var/filled = fill_vats()
		to_chat(user, filled ? "The supply starts filling [filled] vat(s)." : "Install a Water Chip and ensure an empty vat has power.")
		return TOPIC_REFRESH
	if(href_list["eject_chip"])
		remove_chip(user)
		return TOPIC_REFRESH

/obj/machinery/computer/hydroponics/attackby(obj/item/O, mob/user)
	if(!istype(O, /obj/item/device/waterchip))
		return ..()
	if(!user || user.incapacitated() || !Adjacent(user) || issilicon(user))
		return
	if(installed_chip)
		to_chat(user, "The console already has a Water Chip installed.")
		return
	if(!user.unEquip(O, target = src))
		return
	installed_chip = O
	refresh_water_supply()
	to_chat(user, "You insert the Water Chip into the hydroponics console.")
	playsound(loc, 'sound/items/Ratchet.ogg', 75, TRUE)
	if(GLOB.bridge_crew_objectives)
		GLOB.bridge_crew_objectives.check_progress()
	SSnano.update_uis(src)

/obj/machinery/computer/hydroponics/proc/remove_chip(mob/user)
	if(!installed_chip)
		to_chat(user, "There is no Water Chip installed.")
		return
	var/obj/item/device/waterchip/chip = installed_chip
	installed_chip = null
	chip.forceMove(get_turf(src))
	user.put_in_hands(chip)
	refresh_water_supply()
	to_chat(user, "You eject the Water Chip from the console.")
	SSnano.update_uis(src)

/obj/machinery/computer/hydroponics/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == installed_chip)
		installed_chip = null
		refresh_water_supply()
		SSnano.update_uis(src)

/obj/machinery/computer/hydroponics/Destroy()
	if(installed_chip)
		installed_chip.forceMove(get_turf(src))
		installed_chip = null
	refresh_water_supply()
	return ..()

/obj/machinery/computer/hydroponics/proc/fill_vats()
	if(!installed_chip || !operable() || !powered())
		return 0
	var/count = 0
	for(var/obj/machinery/biomass_vat/V in get_connected_vats())
		if(V.begin_filling(src))
			count++
	return count

/obj/machinery/computer/hydroponics/AltClick(mob/user)
	if(user && !user.incapacitated() && Adjacent(user))
		remove_chip(user)
		return TRUE
	return ..()

/obj/machinery/biomass_vat
	name = "hydroponics vat"
	desc = "Fill from the hydroponics console, then add yeast and glig. Stir with a skimmer whenever the red light flashes; scoop the goo when the green light flashes."
	icon = 'icons/os13/objects/objects/pipes/vats.dmi'
	icon_state = "vat_empty"
	// The 64px art is centered on its solid base tile; leave space above and beside mapped vats.
	pixel_x = -16
	density = TRUE
	anchored = TRUE
	obj_flags = OBJ_FLAG_ANCHORABLE
	idle_power_usage = 50
	active_power_usage = 250
	var/stage = BIOMASS_VAT_EMPTY
	var/has_yeast = FALSE
	var/has_glig = FALSE
	var/stirs = 0
	var/stirs_required = 3
	var/portions = 0
	var/batch_portions = 3
	var/cycle_time = 30 SECONDS
	var/work_left = 0
	var/last_process = 0
	var/obj/machinery/computer/hydroponics/water_supply

/obj/machinery/biomass_vat/Initialize()
	. = ..()
	last_process = world.time
	update_icon()

/obj/machinery/biomass_vat/proc/begin_filling(obj/machinery/computer/hydroponics/supply)
	if(stage != BIOMASS_VAT_EMPTY || !supply || !supply.installed_chip || !supply.operable() || !supply.powered())
		return FALSE
	if(!operable() || !powered() || z != supply.z || get_area(src) != get_area(supply))
		return FALSE
	water_supply = supply
	stage = BIOMASS_VAT_FILLING
	work_left = 10 SECONDS
	last_process = world.time
	update_use_power(POWER_USE_ACTIVE)
	update_icon()
	return TRUE

/obj/machinery/biomass_vat/Process()
	var/elapsed = max(0, world.time - last_process)
	last_process = world.time
	advance_cycle(elapsed)

/obj/machinery/biomass_vat/proc/advance_cycle(elapsed)
	if(!operable() || !powered() || elapsed <= 0)
		return
	if(stage == BIOMASS_VAT_FILLING)
		if(QDELETED(water_supply) || !water_supply.installed_chip || !water_supply.operable() || !water_supply.powered())
			return
	else if(stage != BIOMASS_VAT_GROWING)
		return
	work_left = max(0, work_left - elapsed)
	if(work_left)
		return
	if(stage == BIOMASS_VAT_FILLING)
		stage = BIOMASS_VAT_FILLED
		water_supply = null
	else if(stirs < stirs_required)
		stage = BIOMASS_VAT_STIR
		visible_message("The red light on \the [src] flashes. The foam needs stirring.")
	else
		stage = BIOMASS_VAT_READY
		portions = batch_portions
		visible_message("The green light on \the [src] flashes. The goo is ready to skim.")
	update_use_power(POWER_USE_IDLE)
	update_icon()

/obj/machinery/biomass_vat/attackby(obj/item/O, mob/user)
	if(!user || user.incapacitated() || !Adjacent(user))
		return
	if(istype(O, /obj/item/hydroponics_supply/skimmer))
		var/obj/item/hydroponics_supply/skimmer/S = O
		if(S.loaded)
			to_chat(user, "Empty the skimmer into a biomass press first.")
		else if(use_skimmer(S))
			to_chat(user, S.loaded ? "You scoop up a portion of goo." : "You mix the foam. The culture starts growing again.")
		else
			to_chat(user, "Wait for the red light to stir, or the green light to skim.")
		return
	if(istype(O, /obj/item/hydroponics_supply/yeast) || istype(O, /obj/item/hydroponics_supply/glig))
		if(stage != BIOMASS_VAT_FILLED)
			to_chat(user, "The vat must be filled with clean water before adding a culture.")
			return
		var/is_yeast = istype(O, /obj/item/hydroponics_supply/yeast)
		if(is_yeast ? has_yeast : has_glig)
			to_chat(user, "This batch already contains [is_yeast ? "yeast" : "glig"].")
			return
		if(!user.unEquip(O, target = src))
			return
		if(is_yeast)
			has_yeast = TRUE
		else
			has_glig = TRUE
		to_chat(user, "You add \the [O] to the vat.")
		qdel(O)
		if(has_yeast && has_glig)
			stage = BIOMASS_VAT_GROWING
			work_left = cycle_time
			last_process = world.time
			update_use_power(POWER_USE_ACTIVE)
		update_icon()
		return
	return ..()

/obj/machinery/biomass_vat/proc/use_skimmer(obj/item/hydroponics_supply/skimmer/S)
	if(!S || S.loaded || !operable() || !powered())
		return FALSE
	if(stage == BIOMASS_VAT_STIR)
		stirs++
		stage = BIOMASS_VAT_GROWING
		work_left = cycle_time
		last_process = world.time
		update_use_power(POWER_USE_ACTIVE)
	else if(stage == BIOMASS_VAT_READY && portions > 0)
		S.loaded = TRUE
		S.update_icon()
		portions--
		if(!portions)
			stage = BIOMASS_VAT_EMPTY
			has_yeast = FALSE
			has_glig = FALSE
			stirs = 0
	else
		return FALSE
	update_icon()
	return TRUE

/obj/machinery/biomass_vat/attack_hand(mob/user)
	if(user && Adjacent(user))
		examine(user)

/obj/machinery/biomass_vat/proc/get_status_text()
	switch(stage)
		if(BIOMASS_VAT_EMPTY)
			return "Empty"
		if(BIOMASS_VAT_FILLING)
			return "Filling"
		if(BIOMASS_VAT_FILLED)
			return "Water full - add cultures"
		if(BIOMASS_VAT_GROWING)
			return "Growing"
		if(BIOMASS_VAT_STIR)
			return "RED - stir the foam"
		if(BIOMASS_VAT_READY)
			return "GREEN - ready to skim"

/obj/machinery/biomass_vat/examine(mob/user)
	. = ..()
	switch(stage)
		if(BIOMASS_VAT_EMPTY)
			to_chat(user, "Empty. Use the hydroponics console to start a new batch.")
		if(BIOMASS_VAT_FILLING)
			to_chat(user, "Filling. The supply console must retain its chip and power.")
		if(BIOMASS_VAT_FILLED)
			to_chat(user, "Water: full. Yeast: [has_yeast ? "added" : "needed"]. Glig: [has_glig ? "added" : "needed"].")
		if(BIOMASS_VAT_GROWING)
			to_chat(user, "The culture is growing. Mixes completed: [stirs]/[stirs_required].")
		if(BIOMASS_VAT_STIR)
			to_chat(user, "RED: growth has stopped. Mix the foam with an empty skimmer.")
		if(BIOMASS_VAT_READY)
			to_chat(user, "GREEN: [portions] portion(s) of goo ready. Scoop with an empty skimmer.")
	if(!operable() || !powered())
		to_chat(user, "The vat needs power and working machinery to continue.")

/obj/machinery/biomass_vat/update_icon()
	overlays.Cut()
	switch(stage)
		if(BIOMASS_VAT_EMPTY)
			icon_state = "vat_empty"
		if(BIOMASS_VAT_FILLING)
			icon_state = "vat_filling"
		if(BIOMASS_VAT_FILLED)
			icon_state = "vat_filled"
		if(BIOMASS_VAT_GROWING)
			icon_state = "vat_filth[min(stirs + 1, 3)]"
		if(BIOMASS_VAT_STIR)
			icon_state = "vat_filth4"
		if(BIOMASS_VAT_READY)
			icon_state = "vat_filth10"
	if(operable() && powered())
		var/light_state
		if(stage == BIOMASS_VAT_STIR)
			light_state = "over_lowhealth3"
		else if(stage == BIOMASS_VAT_READY)
			light_state = "over_harvest3"
		if(light_state)
			var/image/status_light = image('icons/os13/objects/objects/hydroponics.dmi', light_state)
			status_light.pixel_x = 16
			status_light.pixel_y = 16
			overlays += status_light

/obj/machinery/biomass_press
	name = "biomass press"
	desc = "Empty a goo-filled skimmer into the press, wait for the green indicator, then take the biomass brick with an empty hand."
	icon = 'icons/os13/os13hydroitems.dmi'
	icon_state = "bricker"
	density = TRUE
	anchored = TRUE
	obj_flags = OBJ_FLAG_ANCHORABLE
	idle_power_usage = 50
	active_power_usage = 500
	var/work_left = 0
	var/last_process = 0
	var/ready = FALSE
	var/output_type = /obj/item/hydroponics_supply/biomass

/obj/machinery/biomass_press/proc/start_pressing(obj/item/hydroponics_supply/skimmer/S)
	if(!S || !S.loaded || work_left || ready || !operable() || !powered())
		return FALSE
	S.loaded = FALSE
	S.update_icon()
	begin_processing()
	return TRUE

/obj/machinery/biomass_press/proc/begin_processing()
	work_left = 5 SECONDS
	last_process = world.time
	update_use_power(POWER_USE_ACTIVE)
	update_icon()

/obj/machinery/biomass_press/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/hydroponics_supply/skimmer))
		if(!user || user.incapacitated() || !Adjacent(user))
			return
		if(start_pressing(O))
			to_chat(user, "You pour the goo into the press.")
		else
			to_chat(user, "The press must be powered and empty, and the skimmer must contain goo.")
		return
	return ..()

/obj/machinery/biomass_press/Process()
	var/elapsed = max(0, world.time - last_process)
	last_process = world.time
	advance_cycle(elapsed)

/obj/machinery/biomass_press/proc/advance_cycle(elapsed)
	if(!work_left || !operable() || !powered() || elapsed <= 0)
		return
	work_left = max(0, work_left - elapsed)
	if(!work_left)
		ready = TRUE
		update_use_power(POWER_USE_IDLE)
		update_icon()
		ping()

/obj/machinery/biomass_press/proc/take_product()
	if(!ready || !operable() || !powered())
		return
	ready = FALSE
	var/obj/item/product = new output_type(get_turf(src))
	update_icon()
	return product

/obj/machinery/biomass_press/attack_hand(mob/user)
	if(!user || user.incapacitated() || !Adjacent(user))
		return
	var/obj/item/product = take_product()
	if(product)
		user.put_in_hands(product)
	else
		to_chat(user, work_left ? "Processing. Keep the machine powered until the green indicator lights up." : desc)

/obj/machinery/biomass_press/update_icon()
	if(!operable() || !powered())
		icon_state = "bricker"
	else
		icon_state = work_left ? "bricker_process" : (ready ? "bricker_ready" : "bricker")

/obj/machinery/biomass_press/food_processor
	name = "food processor"
	desc = "Use an empty hand to select a food shape, then insert one biomass brick. Take the meal when the green indicator lights up."
	icon = 'icons/obj/machines/replicator.dmi'
	icon_state = "replicator"
	output_type = /obj/item/reagent_containers/food/snacks/tofuburger
	var/list/food_shapes = list("Burger" = /obj/item/reagent_containers/food/snacks/tofuburger, "Sausage" = /obj/item/reagent_containers/food/snacks/sausage, "Wafers" = /obj/item/reagent_containers/food/snacks/soylenviridians)

/obj/machinery/biomass_press/food_processor/attack_hand(mob/user)
	if(!user || user.incapacitated() || !Adjacent(user))
		return
	if(ready || work_left)
		return ..()
	var/choice = input(user, "Choose a shape for the next biomass brick.", "Food processor") as null|anything in food_shapes
	if(!choice || QDELETED(src) || !Adjacent(user) || user.incapacitated() || work_left || ready)
		return
	output_type = food_shapes[choice]
	to_chat(user, "Selected [choice]. Insert a biomass brick.")

/obj/machinery/biomass_press/food_processor/attackby(obj/item/O, mob/user)
	if(isWrench(O))
		return ..()
	if(!istype(O, /obj/item/hydroponics_supply/biomass))
		to_chat(user, "The food processor accepts pressed biomass bricks.")
		return
	if(!user || user.incapacitated() || !Adjacent(user) || !operable() || !powered())
		return
	if(work_left || ready)
		to_chat(user, "Finish and collect the previous meal first.")
		return
	if(!user.unEquip(O, target = src))
		return
	qdel(O)
	begin_processing()
	to_chat(user, "The processor starts shaping the biomass into food.")

/obj/machinery/biomass_press/food_processor/update_icon()
	overlays.Cut()
	if(!operable() || !powered())
		icon_state = "replicator_d"
	else
		icon_state = work_left ? "replicator_p" : "replicator"
		if(ready)
			overlays += image('icons/os13/objects/objects/hydroponics.dmi', "over_harvest3")

/obj/machinery/vending/hydro_cultures
	name = "vat culture dispenser"
	desc = "Yeast, glig, and skimmers for biomass production."
	icon_state = "nutri"
	icon_deny = "nutri-deny"
	icon_vend = "nutri-vend"
	products = list(/obj/item/hydroponics_supply/yeast = 40, /obj/item/hydroponics_supply/glig = 40, /obj/item/hydroponics_supply/skimmer = 4)

/decl/hierarchy/supply_pack/hydroponics/vat_supplies
	name = "Biomass vat cultures and skimmers"
	contains = list(/obj/item/hydroponics_supply/yeast = 12, /obj/item/hydroponics_supply/glig = 12, /obj/item/hydroponics_supply/skimmer = 2)
	cost = 15
	containername = "biomass culture crate"

/decl/hierarchy/supply_pack/hydroponics/vat_equipment
	name = "Biomass vat equipment"
	contains = list(/obj/machinery/biomass_vat, /obj/machinery/computer/hydroponics, /obj/machinery/biomass_press)
	cost = 60
	containertype = /obj/structure/closet/crate/large/hydroponics
	containername = "biomass equipment crate"

/decl/hierarchy/supply_pack/hydroponics/food_processor
	name = "Biomass food processor"
	contains = list(/obj/machinery/biomass_press/food_processor)
	cost = 30
	containertype = /obj/structure/closet/crate/large/hydroponics
	containername = "food processor crate"
