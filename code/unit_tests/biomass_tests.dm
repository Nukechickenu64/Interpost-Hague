#ifdef UNIT_TEST

/obj/machinery/computer/hydroponics/biomass_test
	var/test_power = TRUE

/obj/machinery/computer/hydroponics/biomass_test/powered(chan = -1, area/check_area = null)
	return test_power

/obj/machinery/biomass_vat/biomass_test
	var/test_power = TRUE

/obj/machinery/biomass_vat/biomass_test/powered(chan = -1, area/check_area = null)
	return test_power

/obj/machinery/biomass_press/biomass_test
	var/test_power = TRUE

/obj/machinery/biomass_press/biomass_test/powered(chan = -1, area/check_area = null)
	return test_power

/obj/machinery/biomass_press/food_processor/biomass_test/powered(chan = -1, area/check_area = null)
	return TRUE

/datum/unit_test/biomass_workflow
	name = "HYDROPONICS - Chip, water, cultures, stirring, skimming and pressing"

/datum/unit_test/biomass_workflow/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/computer/hydroponics/biomass_test/C = new(T)
	var/obj/machinery/biomass_vat/biomass_test/V = new(T)
	var/obj/machinery/biomass_press/biomass_test/P = new(T)
	var/obj/item/hydroponics_supply/skimmer/S = new(T)
	var/obj/item/device/waterchip/chip = new(T)
	var/obj/item/device/waterchip/spare = new(T)
	var/turf/vat_front = get_step(V, NORTH)
	C.stat = V.stat = P.stat = 0
	U.forceMove(vat_front)
	C.update_icon()
	if(!istype(C, /obj/machinery/computer) || C.icon_state != "os13_tank")
		failure += "Hydroponics is not using the powered OS13 computer. "
	C.stat = NOPOWER
	C.update_icon()
	if(C.icon_state != "os13_tank_off")
		failure += "The hydroponics computer did not switch off visually. "
	C.stat = BROKEN
	C.update_icon()
	if(C.icon_state != "os13_tank_broken")
		failure += "The hydroponics computer has no broken state. "
	C.stat = 0
	C.update_icon()
	var/list/console_data = C.get_ui_data()
	if(console_data["chip_installed"] || console_data["can_fill"] || length(console_data["vats"]) != 1)
		failure += "The console did not report its empty supply and local vat. "
	if(C.fill_vats() || V.stage != BIOMASS_VAT_EMPTY)
		failure += "The water supply worked without a chip. "
	U.put_in_hands(chip)
	C.attackby(chip, U)
	if(C.installed_chip != chip || chip.loc != C || !GLOB.waterchip_installed || QDELETED(chip))
		failure += "Installing the physical water chip failed. "
	console_data = C.get_ui_data()
	if(!console_data["chip_installed"] || !console_data["can_fill"])
		failure += "Installing the chip did not enable the console fill control. "
	U.put_in_hands(spare)
	C.attackby(spare, U)
	if(C.installed_chip != chip || spare.loc != U || QDELETED(spare))
		failure += "Duplicate installation consumed or replaced a chip. "
	U.drop_from_inventory(spare)
	C.test_power = FALSE
	if(C.fill_vats())
		failure += "An unpowered console filled vats. "
	C.test_power = TRUE
	C.OnTopic(U, list("fill" = "1"))
	if(V.stage != BIOMASS_VAT_FILLING)
		failure += "The console did not fill its local empty vat. "
	C.OnTopic(U, list("eject_chip" = "1"))
	V.advance_cycle(10 SECONDS)
	if(V.stage != BIOMASS_VAT_FILLING || chip.loc != U || C.installed_chip)
		failure += "Removing a chip did not pause filling or return the original chip. "
	C.attackby(chip, U)
	V.advance_cycle(10 SECONDS)
	if(V.stage != BIOMASS_VAT_FILLED)
		failure += "Filling did not resume. "
	var/obj/item/hydroponics_supply/yeast/Y = new(T)
	U.put_in_hands(Y)
	V.attackby(Y, U)
	if(!V.has_yeast || V.stage != BIOMASS_VAT_FILLED || !QDELETED(Y))
		failure += "Yeast alone started the culture or was not consumed. "
	var/obj/item/hydroponics_supply/yeast/duplicate = new(T)
	U.put_in_hands(duplicate)
	V.attackby(duplicate, U)
	if(QDELETED(duplicate) || duplicate.loc != U)
		failure += "The vat wasted a duplicate culture. "
	U.drop_from_inventory(duplicate)
	var/obj/item/hydroponics_supply/glig/G = new(T)
	U.put_in_hands(G)
	V.attackby(G, U)
	if(V.stage != BIOMASS_VAT_GROWING || !QDELETED(G) || V.use_skimmer(S))
		failure += "The culture recipe or early-harvest protection failed. "
	V.test_power = FALSE
	var/remaining = V.work_left
	V.advance_cycle(V.cycle_time)
	if(V.work_left != remaining)
		failure += "Growth continued without power. "
	V.test_power = TRUE
	for(var/i = 1 to V.stirs_required)
		V.advance_cycle(V.cycle_time)
		if(V.stage != BIOMASS_VAT_STIR || !V.overlays.len)
			failure += "Mix [i] did not stop with a red indicator. "
		V.advance_cycle(V.cycle_time * 10)
		if(V.stage != BIOMASS_VAT_STIR || V.portions)
			failure += "Unattended foam advanced without stirring. "
		if(!V.use_skimmer(S) || S.loaded || V.stirs != i)
			failure += "Stirring did not resume growth. "
	V.advance_cycle(V.cycle_time)
	if(V.stage != BIOMASS_VAT_READY || V.portions != 3 || !V.overlays.len)
		failure += "The finished batch did not show its green harvest indicator. "
	var/list/bricks = list()
	for(var/i = 1 to 3)
		if(!V.use_skimmer(S) || !S.loaded || S.icon_state != "spaceshovel1")
			failure += "Scoop [i] failed. "
		var/previous_portions = V.portions
		if(V.use_skimmer(S) || V.portions != previous_portions)
			failure += "A full skimmer removed more goo. "
		if(!P.start_pressing(S) || S.loaded || P.start_pressing(S))
			failure += "Press transfer was duplicated or failed. "
		P.test_power = FALSE
		P.advance_cycle(10 SECONDS)
		if(P.ready || P.work_left != 5 SECONDS)
			failure += "Pressing continued without power. "
		P.test_power = TRUE
		P.advance_cycle(5 SECONDS)
		var/obj/item/product = P.take_product()
		if(!istype(product, /obj/item/hydroponics_supply/biomass) || P.take_product())
			failure += "Press output was missing or could be duplicated. "
		if(product)
			bricks += product
	if(V.stage != BIOMASS_VAT_EMPTY || V.has_yeast || V.has_glig || V.portions || V.stirs || V.use_skimmer(S))
		failure += "An exhausted vat retained ingredients, goo or progress. "
	if(C.fill_vats() != 1)
		failure += "The exhausted vat could not start another batch. "
	C.remove_chip(U)
	for(var/atom/A in bricks + list(C, V, P, S, chip, spare, duplicate, U))
		qdel(A)
	if(failure)
		fail(failure)
	else
		pass("Physical chip recovery, power pauses, exact recipe, five mandatory mixes, three scoops, pressing and batch reset verified.")
	return TRUE

/datum/unit_test/vat_access
	name = "HYDROPONICS - North-only vat service and blocked upper tile"

/datum/unit_test/vat_access/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(engineer_test_turf())
	var/obj/machinery/biomass_vat/biomass_test/V = new(T)
	V.stat = 0
	var/turf/front = get_step(V, NORTH)
	var/obj/effect/vat_access/B = V.access_blocker
	if(V.layer != STRUCTURE_LAYER)
		failure += "The vat does not render below standing humans. "
	if(!B || B.loc != front || B.invisibility != INVISIBILITY_MAXIMUM)
		failure += "The vat did not maintain an invisible access blocker on its north tile. "
	if(B.CheckExit(U, get_step(front, EAST)) || B.CheckExit(U, get_step(front, WEST)))
		failure += "The vat's upper tile allows sideways exits. "
	U.forceMove(get_step(front, NORTH))
	if(!B.CheckExit(U, front))
		failure += "The vat's upper tile blocks its only working approach. "
	if(!B.CanPass(U, U.loc, 1, 0))
		failure += "The vat's upper tile blocks entry from the north. "
	U.forceMove(get_step(front, EAST))
	if(B.CanPass(U, U.loc, 1, 0))
		failure += "The vat's upper tile permits entry from the side. "
	V.stage = BIOMASS_VAT_FILLED
	var/obj/item/hydroponics_supply/yeast/Y = new(front)
	U.forceMove(front)
	U.put_in_hands(Y)
	V.attackby(Y, U)
	if(!V.has_yeast || !QDELETED(Y))
		failure += "A worker standing directly north of the vat could not add a culture. "
	var/obj/item/hydroponics_supply/glig/G = new(T)
	U.forceMove(get_step(V, SOUTH))
	U.put_in_hands(G)
	V.attackby(G, U)
	if(V.has_glig || QDELETED(G))
		failure += "A worker outside the north tile added a culture. "
	var/turf/T2 = get_step(V, NORTH)
	var/obj/effect/vat_access/old_blocker = B
	V.forceMove(T2)
	if(!V.access_blocker || V.access_blocker == old_blocker || !QDELETED(old_blocker) || V.access_blocker.loc != get_step(V, NORTH))
		failure += "The access blocker did not follow a relocated vat. "
	var/obj/effect/vat_access/new_blocker = V.access_blocker
	qdel(V)
	if(!QDELETED(new_blocker) && new_blocker.loc == get_step(T2, NORTH))
		failure += "Destroying the vat left its access blocker behind. "
	for(var/atom/A in list(U, Y, G))
		if(A && !QDELETED(A))
			qdel(A)
	if(failure)
		fail(failure)
	else
		pass("The vat renders under walkers, its upper tile only opens north or south, and only the tile directly north can work it.")
	return TRUE

/datum/unit_test/biomass_consumers
	name = "HYDROPONICS - Food shapes and cloning feedstock"

/datum/unit_test/biomass_consumers/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/biomass_press/food_processor/biomass_test/F = new(T)
	var/obj/machinery/clonepod/C = new(T)
	F.stat = 0
	for(var/shape in F.food_shapes)
		var/obj/item/hydroponics_supply/biomass/B = new(T)
		U.put_in_hands(B)
		F.output_type = F.food_shapes[shape]
		F.attackby(B, U)
		if(F.loaded_input != B || QDELETED(B) || F.work_left)
			failure += "The food processor did not hold a brick for [shape]. "
		F.attack_hand(U)
		if(!QDELETED(B) || !F.work_left)
			failure += "The food processor did not activate for [shape]. "
		F.advance_cycle(5 SECONDS)
		var/obj/item/reagent_containers/food/snacks/meal = F.take_product()
		if(!istype(meal) || meal.type != F.food_shapes[shape] || !meal.reagents.total_volume || F.take_product())
			failure += "The [shape] meal was missing, inedible or duplicated. "
		qdel(meal)
	var/before = C.biomass
	for(var/i = 1 to 3)
		var/obj/item/hydroponics_supply/biomass/B = new(T)
		U.put_in_hands(B)
		C.attackby(B, U)
		if(!QDELETED(B))
			failure += "The cloning pod did not consume brick [i]. "
	if(C.biomass != before + CLONE_BIOMASS)
		failure += "Three bricks did not provide one clone's 150 biomass. "
	qdel(F)
	qdel(C)
	qdel(U)
	if(failure)
		fail(failure)
	else
		pass("All food shapes produce edible meals; a batch of three bricks supplies 150 cloning biomass.")
	return TRUE

/datum/unit_test/biomass_processing
	name = "HYDROPONICS - Machinery processing and mapped supply chain"

/datum/unit_test/biomass_processing/start_test()
	var/failure = ""
	var/obj/machinery/biomass_press/biomass_test/P = new(engineer_test_turf())
	P.stat = 0
	var/obj/item/hydroponics_supply/skimmer/S = new(engineer_test_turf())
	S.loaded = TRUE
	P.start_pressing(S)
	// Exercise actual subsystem dispatch, not just manual time advancement.
	sleep(7 SECONDS)
	if(!P.ready || P.work_left || !P.is_processing)
		failure += "The machinery subsystem did not complete a real five-second press cycle. "
	qdel(P)
	qdel(S)
	var/vats = 0
	var/consoles = 0
	var/presses = 0
	var/food_processors = 0
	var/cultures = 0
	for(var/obj/machinery/M in SSmachines.machinery)
		if(!isStationLevel(M.z))
			continue
		if(istype(M, /obj/machinery/biomass_vat))
			vats++
		if(istype(M, /obj/machinery/computer/hydroponics))
			consoles++
		if(M.type == /obj/machinery/biomass_press)
			presses++
		if(istype(M, /obj/machinery/biomass_press/food_processor))
			food_processors++
		if(istype(M, /obj/machinery/vending/hydro_cultures))
			cultures++
	if(GLOB.using_map.name == "Alpha" && (vats != 4 || !consoles || !presses || !food_processors || !cultures))
		failure += "Alpha biomass fixtures: [vats] vats, [consoles] consoles, [presses] presses, [food_processors] food processors, [cultures] culture dispensers. "
	if(failure)
		fail(failure)
	else
		pass("Real machinery dispatch completed the press cycle. Station fixtures: [vats] vats, [consoles] consoles, [presses] presses, [food_processors] food processors, [cultures] culture dispensers.")
	return TRUE

#endif
