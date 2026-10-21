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
	desc = "Scoop goo when a vat's green light flashes, then empty the skimmer into a biomass press. Red vats can also be stirred by hand."
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
	desc = "Fill from the hydroponics console, then add yeast and glig. Stir by hand whenever the red light flashes; after five mixes, scoop the green-lit goo with a skimmer. Stand directly north of the vat to work it."
	icon = 'icons/os13/objects/objects/pipes/vats.dmi'
	icon_state = "vat_empty"
	// The 64px art is centered on its solid base tile; leave space above and beside mapped vats.
	pixel_x = -16
	layer = STRUCTURE_LAYER
	density = TRUE
	anchored = TRUE
	obj_flags = OBJ_FLAG_ANCHORABLE
	idle_power_usage = 50
	active_power_usage = 250
	var/stage = BIOMASS_VAT_EMPTY
	var/has_yeast = FALSE
	var/has_glig = FALSE
	var/stirs = 0
	var/stirs_required = 5
	var/portions = 0
	var/batch_portions = 3
	var/cycle_time = 30 SECONDS
	var/work_left = 0
	var/last_process = 0
	var/obj/machinery/computer/hydroponics/water_supply
	var/obj/effect/vat_access/access_blocker

/obj/machinery/biomass_vat/Initialize()
	. = ..()
	last_process = world.time
	maintain_access_blocker()
	update_icon()

// The vat's 64px body also occupies the tile directly north of it. A blocker
// keeps foot traffic out of that tile except through its northern edge, so the
// only working position is standing directly north of the vat.
/obj/machinery/biomass_vat/proc/maintain_access_blocker()
	var/turf/front = isturf(loc) ? get_step(src, NORTH) : null
	if(!front)
		if(access_blocker)
			QDEL_NULL(access_blocker)
		return
	if(access_blocker && get_turf(access_blocker) != front)
		QDEL_NULL(access_blocker)
	if(!access_blocker)
		access_blocker = new /obj/effect/vat_access(front)

/obj/machinery/biomass_vat/Move(...)
	. = ..()
	if(.)
		maintain_access_blocker()

/obj/machinery/biomass_vat/forceMove(atom/destination)
	. = ..()
	maintain_access_blocker()

/obj/machinery/biomass_vat/Destroy()
	QDEL_NULL(access_blocker)
	return ..()

/obj/machinery/biomass_vat/proc/at_front_tile(mob/user)
	if(!user)
		return FALSE
	var/turf/front = get_step(src, NORTH)
	return front && get_turf(user) == front

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
	flick("vat_filling", src)
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
	if(!at_front_tile(user))
		to_chat(user, "You can only reach the vat from the tile directly north of it.")
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
		return stir()
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

/obj/machinery/biomass_vat/proc/stir()
	if(stage != BIOMASS_VAT_STIR || !operable() || !powered())
		return FALSE
	stirs++
	stage = BIOMASS_VAT_GROWING
	work_left = cycle_time
	last_process = world.time
	update_use_power(POWER_USE_ACTIVE)
	update_icon()
	return TRUE

/obj/machinery/biomass_vat/attack_hand(mob/user)
	if(!user || user.incapacitated() || !Adjacent(user))
		return
	if(!at_front_tile(user))
		to_chat(user, "You can only reach the vat from the tile directly north of it.")
		return
	if(stir())
		user.visible_message("[user] stirs the muck in the vat!", "You stir the muck in the vat.")
	else
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
			to_chat(user, "RED: growth has stopped. Click with an empty hand to stir the muck.")
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
			icon_state = "vat_empty"
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

// Occupies the tile directly north of a vat: passable only straight through
// its northern edge; east/west movement is blocked. Invisible to players.
/obj/effect/vat_access
	name = "hydroponics vat body"
	desc = "The upper half of a hydroponics vat."
	invisibility = INVISIBILITY_MAXIMUM
	anchored = TRUE
	density = TRUE
	mouse_opacity = 0
	unacidable = TRUE
	simulated = FALSE
	icon = null
	icon_state = null

/obj/effect/vat_access/CanPass(atom/movable/mover, turf/target, height = 0, air_group = 0)
	// Air and items sliding at floor height flow over the vat body the same
	// way they flow over a dense machine.
	if(air_group || !height || !target)
		return TRUE
	// Reaching the service tile means walking south off its northern neighbour.
	return get_dir(loc, target) == NORTH

/obj/effect/vat_access/CheckExit(atom/movable/O, turf/target)
	if(!target)
		return TRUE
	if(get_dir(loc, target) & (EAST|WEST))
		return FALSE
	return TRUE

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
	if("bricker_process" in icon_states(icon))
		flick("bricker_process", src)

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
		icon_state = ready ? "bricker_ready" : "bricker"

// Food Processing Units in the water-chip recording are loaded, then activated.
/obj/machinery/biomass_press/food_processor
	name = "food processing unit"
	desc = "Insert a biomass brick, then click with an empty hand to activate. Collect the finished meal with another click. Alt-click to unload an unprocessed brick."
	icon = 'icons/os13/objects/objects/vending.dmi'
	icon_state = "kitchen_base"
	output_type = /obj/item/reagent_containers/food/snacks/ersatz/pizza
	var/list/food_shapes = list("Pizza" = /obj/item/reagent_containers/food/snacks/ersatz/pizza, "Sandwich" = /obj/item/reagent_containers/food/snacks/ersatz/sandwich, "Shawarma" = /obj/item/reagent_containers/food/snacks/ersatz/shawarma, "Burger" = /obj/item/reagent_containers/food/snacks/tofuburger, "Sausage" = /obj/item/reagent_containers/food/snacks/sausage, "Wafers" = /obj/item/reagent_containers/food/snacks/soylenviridians)
	var/fixed_shape
	var/input_type = /obj/item/hydroponics_supply/biomass
	var/input_name = "biomass brick"
	var/obj/item/loaded_input
	var/repairing = FALSE

/obj/machinery/biomass_press/food_processor/pizza
	fixed_shape = "Pizza"

/obj/machinery/biomass_press/food_processor/sandwich
	fixed_shape = "Sandwich"
	output_type = /obj/item/reagent_containers/food/snacks/ersatz/sandwich

/obj/machinery/biomass_press/food_processor/shawarma
	fixed_shape = "Shawarma"
	output_type = /obj/item/reagent_containers/food/snacks/ersatz/shawarma

/obj/machinery/biomass_press/food_processor/shawarma/broken
	stat = BROKEN

/obj/machinery/biomass_press/food_processor/Initialize()
	. = ..()
	update_icon()

/obj/machinery/biomass_press/food_processor/examine(mob/user)
	. = ..()
	if(stat & BROKEN)
		to_chat(user, "Something is wrong with this one. Use an empty hand to repair its jammed mechanism.")
	else
		var/obj/item/food = output_type
		to_chat(user, "This one is configured for making [initial(food.name)]. [loaded_input ? "Ingredient loaded; click to activate." : ""]")

/obj/machinery/biomass_press/food_processor/attack_hand(mob/user)
	if(!user || user.incapacitated() || !Adjacent(user))
		return
	if(stat & BROKEN)
		if(repairing)
			return
		repairing = TRUE
		to_chat(user, "You start clearing and resetting the food unit's jammed mechanism.")
		if(do_after(user, 10 SECONDS, src) && !QDELETED(src) && (stat & BROKEN))
			set_broken(FALSE)
			user.visible_message("[user] fixes the Food Processing Unit.", "You fix the Food Processing Unit.")
		repairing = FALSE
		return
	if(!operable() || !powered())
		return
	if(ready || work_left)
		return ..()
	if(loaded_input)
		activate()
		return
	if(fixed_shape)
		examine(user)
		return
	var/choice = input(user, "Choose a shape for the next biomass brick.", "Food processing unit") as null|anything in food_shapes
	if(!choice || QDELETED(src) || !Adjacent(user) || user.incapacitated() || !operable() || !powered() || loaded_input || work_left || ready)
		return
	output_type = food_shapes[choice]
	to_chat(user, "Selected [choice]. Insert a biomass brick, then click to activate.")
	update_icon()

/obj/machinery/biomass_press/food_processor/proc/activate()
	if(!loaded_input || loaded_input.loc != src || work_left || ready || !operable() || !powered())
		return FALSE
	var/obj/item/B = loaded_input
	loaded_input = null
	consume_input(B)
	begin_processing()
	return TRUE

/obj/machinery/biomass_press/food_processor/proc/consume_input(obj/item/I)
	qdel(I)

// A food unit accepts pressed bricks, never the press's raw-skimmer shortcut.
/obj/machinery/biomass_press/food_processor/start_pressing(obj/item/hydroponics_supply/skimmer/S)
	return FALSE

/obj/machinery/biomass_press/food_processor/attackby(obj/item/O, mob/user)
	if(isWrench(O))
		return ..()
	if(!istype(O, input_type))
		to_chat(user, "This unit accepts a [input_name].")
		return
	if(!user || user.incapacitated() || !Adjacent(user) || O.loc != user || !operable() || !powered())
		return
	if(loaded_input || work_left || ready)
		to_chat(user, "Finish and collect the previous meal first.")
		return
	if(!user.unEquip(O, target = src))
		return
	loaded_input = O
	update_icon()
	to_chat(user, "You load the [input_name]. Click the unit with an empty hand to activate it.")

/obj/machinery/biomass_press/food_processor/AltClick(mob/user)
	if(!user || user.incapacitated() || !Adjacent(user) || !loaded_input)
		return ..()
	var/obj/item/B = loaded_input
	B.forceMove(get_turf(src))
	user.put_in_hands(B)
	return TRUE

/obj/machinery/biomass_press/food_processor/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == loaded_input)
		loaded_input = null
		update_icon()

/obj/machinery/biomass_press/food_processor/Destroy()
	if(loaded_input)
		loaded_input.forceMove(get_turf(src))
	return ..()

/obj/machinery/biomass_press/food_processor/update_icon()
	overlays.Cut()
	icon_state = "kitchen_base"
	overlays += image(icon, "kitchen_inside")
	if(!operable() || !powered())
		overlays += image(icon, "kitchen0")
	else
		var/indicator = "kitchen1"
		if(output_type == /obj/item/reagent_containers/food/snacks/ersatz/pizza)
			indicator = "kitchen1b"
		else if(output_type == /obj/item/reagent_containers/food/snacks/ersatz/sandwich)
			indicator = "kitchen1c"
		overlays += image(icon, indicator)
		if(work_left)
			overlays += image(icon, "kitchen_blink")
	if(loaded_input)
		overlays += image(loaded_input.icon, loaded_input.icon_state)
	else if(ready)
		var/obj/item/food = output_type
		overlays += image(initial(food.icon), initial(food.icon_state))
	if(work_left || (!loaded_input && !ready))
		overlays += image(icon, "kitchen_door")

// The separate Food Processor shown at 56:15 prepares real meat for cooking.
// One slab becomes one raw meatball; all reagents are conserved, including toxins.
/obj/machinery/biomass_press/food_processor/meat_processor
	name = "food processor"
	desc = "Load a slab of meat, then click to mince it into a raw meatball for cooking. This processor does not accept vat biomass. Alt-click to unload before activation."
	icon = 'icons/os13/objects/objects/kitchen.dmi'
	icon_state = "processor"
	fixed_shape = "Meat"
	input_type = /obj/item/reagent_containers/food/snacks/meat
	input_name = "slab of meat"
	output_type = /obj/item/reagent_containers/food/snacks/rawmeatball

/obj/machinery/biomass_press/food_processor/meat_processor/Initialize()
	. = ..()
	create_reagents(1000)

/obj/machinery/biomass_press/food_processor/meat_processor/consume_input(obj/item/I)
	reagents.clear_reagents()
	if(I.reagents)
		I.reagents.trans_to_holder(reagents, I.reagents.total_volume)
	return ..()

/obj/machinery/biomass_press/food_processor/meat_processor/take_product()
	var/obj/item/reagent_containers/food/snacks/product = ..()
	if(product)
		product.reagents.clear_reagents()
		product.reagents.maximum_volume = max(product.reagents.maximum_volume, reagents.total_volume)
		reagents.trans_to_holder(product.reagents, reagents.total_volume)
	return product

/obj/machinery/biomass_press/food_processor/meat_processor/update_icon()
	overlays.Cut()
	icon_state = (operable() && powered() && work_left) ? "processor_on" : "processor"

/obj/item/reagent_containers/food/snacks/ersatz
	name = "ersatz meal"
	desc = "A meal shaped from vat-grown biomass."
	icon = 'icons/os13/objects/objects/cooking.dmi'
	nutriment_amt = 8
	nutriment_desc = list("savory biomass" = 1)
	bitesize = 2

/obj/item/reagent_containers/food/snacks/ersatz/pizza
	name = "ersatz-pizza"
	icon_state = "pizza_pros_s1"

/obj/item/reagent_containers/food/snacks/ersatz/sandwich
	name = "ersatz-sandwich"
	icon_state = "msandwich"

/obj/item/reagent_containers/food/snacks/ersatz/shawarma
	name = "ersatz-shawarma"
	icon_state = "shaurma"

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
