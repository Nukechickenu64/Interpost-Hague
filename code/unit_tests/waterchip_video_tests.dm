#ifdef UNIT_TEST

/obj/machinery/chargemaster/waterchip_test
	var/test_power = TRUE

/obj/machinery/chargemaster/waterchip_test/powered(chan = -1, area/check_area = null)
	return test_power

/obj/machinery/biomass_press/food_processor/waterchip_test
	var/test_power = TRUE

/obj/machinery/biomass_press/food_processor/waterchip_test/powered(chan = -1, area/check_area = null)
	return test_power

/obj/machinery/biomass_press/food_processor/meat_processor/waterchip_test/powered(chan = -1, area/check_area = null)
	return TRUE

/datum/unit_test/waterchip_chargemaster
	name = "WATER CHIP VIDEO - ChargeMaster conversion and physical conservation"

/datum/unit_test/waterchip_chargemaster/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/chargemaster/waterchip_test/M = new(T)
	M.stat = 0
	M.attack_hand(U)
	if(M.selected != "Soda")
		failure += "The selector did not cycle to Soda. "
	for(var/choice in M.charge_types)
		M.selected = choice
		var/obj/item/precursor_charge/C = new(T)
		if(M.load_charge(C, U))
			failure += "A precursor could be loaded from the floor. "
		U.put_in_hands(C)
		M.test_power = FALSE
		if(M.load_charge(C, U) || C.loc != U)
			failure += "An unpowered machine accepted a charge. "
		M.test_power = TRUE
		if(!M.load_charge(C, U) || M.load_charge(C, U))
			failure += "Load/repeated-load protection failed for [choice]. "
		M.attack_hand(U)
		if(M.selected != choice)
			failure += "Selection changed during conversion. "
		M.test_power = FALSE
		M.advance_cycle(1 MINUTE)
		if(M.work_left != 5 SECONDS || QDELETED(C))
			failure += "Conversion advanced without power. "
		M.test_power = TRUE
		M.advance_cycle(5 SECONDS)
		var/obj/item/vending_charge/output = locate(M.charge_types[choice]) in T
		if(!output || output.type != M.charge_types[choice] || !QDELETED(C) || M.precursor || M.work_left)
			failure += "[choice] did not consume one precursor and produce its refill. "
		qdel(output)
		M.advance_cycle(1 MINUTE)
		if(locate(/obj/item/vending_charge) in T)
			failure += "An empty ChargeMaster duplicated output. "
	var/obj/item/precursor_charge/recovered = new(T)
	U.put_in_hands(recovered)
	M.load_charge(recovered, U)
	M.test_power = FALSE
	M.AltClick(U)
	if(recovered.loc != U || M.work_left || M.precursor || QDELETED(recovered))
		failure += "Cancellation failed to recover the original precursor during an outage. "
	M.test_power = TRUE
	M.load_charge(recovered, U)
	qdel(M)
	if(recovered.loc != T || QDELETED(recovered))
		failure += "Destroying the machine lost its unfinished precursor. "
	qdel(recovered)
	qdel(U)
	if(failure)
		fail(failure)
	else
		pass("All nine refill outputs, outage pauses, selector locking, cancellation and destruction preserve one-for-one conversion.")
	return TRUE

/datum/unit_test/waterchip_refills
	name = "WATER CHIP VIDEO - Chemistry, bar, coffee and soda refills"

/datum/unit_test/waterchip_refills/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/list/families = list(/obj/machinery/chemical_dispenser = /obj/item/vending_charge/chemistry, /obj/machinery/chemical_dispenser/bar_alc = /obj/item/vending_charge/bar, /obj/machinery/chemical_dispenser/bar_soft = /obj/item/vending_charge/soda, /obj/machinery/chemical_dispenser/bar_coffee = /obj/item/vending_charge/coffee)
	for(var/dispenser_type in families)
		var/obj/machinery/chemical_dispenser/D = new dispenser_type(T)
		var/charge_type = families[dispenser_type]
		var/obj/item/vending_charge/C = new charge_type(T)
		U.put_in_hands(C)
		D.attackby(C, U)
		if(!QDELETED(C) || !length(D.cartridges))
			failure += "[D.name] did not initialize its standard stock from a charge. "
		if(!length(D.cartridges))
			failure += "Family [C.dispenser_family], preset count [length(D.charge_stock(C.dispenser_family))], held [C.loc == U], adjacent [U.Adjacent(D)], incapacitated [U.incapacitated()]. "
			qdel(C)
			qdel(D)
			continue
		C = new charge_type(T)
		U.put_in_hands(C)
		if(D.refill_from_charge(C, U) || QDELETED(C) || C.loc != U)
			failure += "A full [D.name] consumed a charge. "
		var/label = D.cartridges[1]
		var/obj/item/reagent_containers/chem_disp_cartridge/R = D.cartridges[label]
		R.reagents.remove_any(30)
		R.reagents.add_reagent(/datum/reagent/toxin, 5)
		var/before = R.reagents.total_volume
		if(D.refill_from_charge(C, U) || R.reagents.total_volume != before || !R.reagents.has_reagent(/datum/reagent/toxin))
			failure += "A custom mixture was modified. "
		R.reagents.clear_reagents()
		if(!D.refill_from_charge(C, U) || R.reagents.total_volume != R.volume || !QDELETED(C))
			failure += "An emptied standard cartridge was not replenished. "
		D.remove_cartridge(label)
		qdel(R)
		C = new charge_type(T)
		U.put_in_hands(C)
		D.refill_from_charge(C, U)
		if(!D.cartridges[label] || !QDELETED(C))
			failure += "A missing standard cartridge was not replaced. "
		var/obj/item/vending_charge/wrong = new /obj/item/vending_charge/security(T)
		U.put_in_hands(wrong)
		if(D.refill_from_charge(wrong, U) || QDELETED(wrong))
			failure += "An incompatible charge was consumed. "
		qdel(wrong)
		qdel(D)
	var/obj/machinery/chemical_dispenser/ert/restricted = new(T)
	var/obj/item/vending_charge/chemistry/C = new(T)
	U.put_in_hands(C)
	if(restricted.refill_from_charge(C, U) || QDELETED(C))
		failure += "A standard charge restocked restricted medicine. "
	qdel(C)
	qdel(restricted)
	var/list/vendors = list(/obj/machinery/vending/cigarette = /obj/item/vending_charge/cigarette, /obj/machinery/vending/boozeomat = /obj/item/vending_charge/bar, /obj/machinery/vending/medical = /obj/item/vending_charge, /obj/machinery/vending/hydro_cultures = /obj/item/vending_charge/hydroponics)
	for(var/vendor_type in vendors)
		var/obj/machinery/vending/V = new vendor_type(T)
		sleep(5)
		var/old_charges = V.creation_charges
		var/charge_type = vendors[vendor_type]
		var/obj/item/vending_charge/refill = new charge_type(T)
		U.put_in_hands(refill)
		if(!V.refill_from_charge(refill, U) || !QDELETED(refill) || V.creation_charges != old_charges + 10)
			failure += "[V.name] did not accept its refill family. "
		qdel(V)
	qdel(U)
	if(failure)
		fail(failure)
	else
		pass("All dispenser families refill; full/wrong machines preserve charges, missing cartridges return, and custom mixtures/restricted presets remain untouched.")
	return TRUE

/datum/unit_test/waterchip_meat
	name = "WATER CHIP VIDEO - Separate real-meat processing and reagent conservation"

/datum/unit_test/waterchip_meat/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/biomass_press/food_processor/meat_processor/waterchip_test/P = new(T)
	var/obj/item/reagent_containers/food/snacks/meat/M = new(T)
	var/obj/item/hydroponics_supply/biomass/B = new(T)
	P.stat = 0
	U.put_in_hands(B)
	P.attackby(B, U)
	if(P.loaded_input || QDELETED(B))
		failure += "The meat processor accepted vat biomass. "
	U.drop_from_inventory(B)
	M.reagents.add_reagent(/datum/reagent/toxin, 5)
	var/before = M.reagents.total_volume
	U.put_in_hands(M)
	P.attackby(M, U)
	P.attack_hand(U)
	P.advance_cycle(5 SECONDS)
	var/obj/item/reagent_containers/food/snacks/meal = P.take_product()
	if(!istype(meal, /obj/item/reagent_containers/food/snacks/rawmeatball) || !QDELETED(M) || meal.reagents.total_volume != before || !meal.reagents.has_reagent(/datum/reagent/toxin, 5) || P.take_product())
		failure += "Mincing lost/duplicated food or removed its contaminants. "
	for(var/atom/A in list(P, meal, B, U))
		qdel(A)
	if(failure)
		fail(failure)
	else
		pass("A slab becomes a cooking ingredient with its original nutrition and contaminants; biomass is rejected.")
	return TRUE

/datum/unit_test/waterchip_supply
	name = "WATER CHIP VIDEO - Water chip removal stops sinks and showers"

/datum/unit_test/waterchip_supply/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/computer/hydroponics/biomass_test/C = new(T)
	var/obj/machinery/waterchip_holder/H = new(T)
	var/obj/item/device/waterchip/first = new(T)
	var/obj/item/device/waterchip/second = new(T)
	var/obj/structure/hygiene/sink/S = new(T)
	var/obj/structure/hygiene/shower/shower = new(T)
	var/obj/item/reagent_containers/glass/beaker/B = new(T)
	var/obj/item/mop/mop = new(T)
	C.stat = 0
	U.put_in_hands(B)
	S.attackby(B, U)
	if(B.reagents.total_volume)
		failure += "A sink supplied water without a chip. "
	U.drop_from_inventory(B)
	U.put_in_hands(first)
	C.attackby(first, U)
	U.put_in_hands(second)
	H.attackby(second, U)
	U.put_in_hands(B)
	S.attackby(B, U)
	if(!B.reagents.has_reagent(/datum/reagent/water))
		failure += "A sink stayed dry after installation. "
	C.remove_chip(U)
	if(!GLOB.waterchip_installed)
		failure += "Removing one of two chips cut off the remaining supply. "
	U.drop_from_inventory(first)
	shower.attack_hand(U)
	shower.Process()
	if(!shower.on)
		failure += "A supplied shower would not turn on. "
	second.forceMove(T)
	if(H.installed_chip || GLOB.waterchip_installed)
		failure += "Forced chip removal left a stale supply. "
	shower.Process()
	if(shower.on)
		failure += "A shower kept running after chip removal. "
	B.reagents.clear_reagents()
	S.attackby(B, U)
	if(B.reagents.total_volume)
		failure += "A container filled after chip removal. "
	U.drop_from_inventory(B)
	U.put_in_hands(mop)
	S.attackby(mop, U)
	if(mop.reagents.total_volume)
		failure += "A mop became wet without water. "
	shower.on = TRUE
	shower.attack_hand(U)
	if(shower.on)
		failure += "A dry shower could not be turned off. "
	var/datum/design/item/waterchip/design = new
	for(var/material in first.matter)
		if(first.matter[material] > design.materials[material])
			failure += "A recycled water chip yields more material than fabrication costs. "
	qdel(design)
	for(var/atom/A in list(C, H, first, second, S, shower, B, mop, U))
		qdel(A)
	refresh_water_supply()
	if(failure)
		fail(failure)
	else
		pass("Multiple physical chips, forced removal, container filling, mop wetting, shower shutoff and fabrication/recycling conservation verified.")
	return TRUE

/datum/unit_test/waterchip_food
	name = "WATER CHIP VIDEO - Hand stirring, food activation, repairs and recovery"

/datum/unit_test/waterchip_food/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/biomass_vat/biomass_test/V = new(T)
	V.stat = 0
	V.stage = BIOMASS_VAT_STIR
	U.forceMove(get_step(V, NORTH))
	V.attack_hand(U)
	if(V.stirs_required != 5 || V.stirs != 1 || V.stage != BIOMASS_VAT_GROWING)
		failure += "Empty-hand stirring or five-mix recipe failed. "
	V.attack_hand(U)
	if(V.stirs != 1)
		failure += "Repeated clicks skipped the growth interval. "
	var/obj/machinery/biomass_press/food_processor/waterchip_test/F = new(T)
	var/obj/item/hydroponics_supply/biomass/B = new(T)
	F.stat = BROKEN
	U.put_in_hands(B)
	F.attackby(B, U)
	if(F.loaded_input || QDELETED(B))
		failure += "A broken food unit consumed biomass. "
	U.drop_from_inventory(B)
	F.attack_hand(U)
	if(F.stat & BROKEN)
		failure += "The timed repair did not restore the food unit. "
	U.put_in_hands(B)
	F.attackby(B, U)
	F.test_power = FALSE
	if(F.activate() || QDELETED(B))
		failure += "The food unit activated without power. "
	F.AltClick(U)
	if(B.loc != U || F.loaded_input)
		failure += "The loaded brick could not be recovered during an outage. "
	F.test_power = TRUE
	F.attackby(B, U)
	F.attack_hand(U)
	F.attack_hand(U)
	if(!QDELETED(B) || !F.work_left)
		failure += "Explicit activation failed. "
	F.test_power = FALSE
	F.advance_cycle(1 MINUTE)
	if(F.ready || F.work_left != 5 SECONDS)
		failure += "Food processing continued through an outage. "
	F.test_power = TRUE
	F.advance_cycle(5 SECONDS)
	var/obj/item/reagent_containers/food/snacks/meal = F.take_product()
	if(!istype(meal, /obj/item/reagent_containers/food/snacks/ersatz/pizza) || !meal.reagents.total_volume || F.take_product())
		failure += "Food output was missing, inedible or duplicated. "
	B = new(T)
	U.put_in_hands(B)
	F.attackby(B, U)
	qdel(F)
	if(B.loc != T || QDELETED(B))
		failure += "Destruction lost an unprocessed brick. "
	for(var/atom/A in list(B, V, meal, U))
		qdel(A)
	if(failure)
		fail(failure)
	else
		pass("Hand stirring, growth locks, timed repair, explicit activation, edible output, outage pause and physical brick recovery verified.")
	return TRUE

/datum/unit_test/waterchip_dispatch
	name = "WATER CHIP VIDEO - Real processing and mapped logistics route"

/datum/unit_test/waterchip_dispatch/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/chargemaster/waterchip_test/M = new(T)
	var/obj/item/precursor_charge/C = new(T)
	M.stat = 0
	U.put_in_hands(C)
	M.load_charge(C, U)
	sleep(7 SECONDS)
	var/obj/item/vending_charge/output = locate() in T
	if(!output || !QDELETED(C) || M.work_left || !M.is_processing)
		failure += "Machinery dispatch did not finish a real conversion. "
	qdel(output)
	qdel(M)
	qdel(U)
	if(GLOB.using_map.name == "Alpha")
		if(!locate(/obj/machinery/chargemaster) in locate(130, 117, 3))
			failure += "The cargo ChargeMaster is missing. "
		if(!locate(/obj/structure/closet/crate/precursor_charges) in locate(132, 115, 3))
			failure += "The starting precursor crate is missing. "
		for(var/path in list(/obj/machinery/biomass_press/food_processor/pizza, /obj/machinery/biomass_press/food_processor/sandwich, /obj/machinery/biomass_press/food_processor/shawarma/broken))
			if(!(locate(path) in SSmachines.machinery))
				failure += "A mapped food unit ([path]) is missing. "
	if(failure)
		fail(failure)
	else
		pass("The machinery subsystem finishes real conversions; Alpha has ChargeMasters, precursors and all three food units.")
	return TRUE

#endif
