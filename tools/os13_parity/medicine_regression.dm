/area/os13_medicine_regression
	name = "Medicine regression room"
	requires_power = FALSE
	dynamic_lighting = FALSE

// Supply only the UI-client presence check for a headless operator. Physical
// distance, capability, machine power and lock checks remain production code.
/mob/living/carbon/human/os13_medicine_regression/shared_nano_interaction()
	if(stat)
		return STATUS_CLOSE
	return incapacitated() ? STATUS_UPDATE : STATUS_INTERACTIVE

/datum/os13_object_regression/proc/check_medicine_objects()
	var/area/room = new /area/os13_medicine_regression
	for(var/x = 30, x <= 35, x++)
		for(var/y = 30, y <= 34, y++)
			var/turf/tile = locate(x,y,1)
			tile = tile.ChangeTurf(/turf/unsimulated/floor)
			room.contents.Add(tile)
	var/turf/origin = locate(31,31,1)
	var/mob/living/carbon/human/user = new /mob/living/carbon/human/os13_medicine_regression(origin)
	user.stats = user.stats.Copy()
	user.zone_sel = new /obj/screen/zone_sel(null)
	user.zone_sel.selecting = BP_CHEST
	var/mob/living/carbon/human/patient = new(locate(31,32,1))
	patient.stats = patient.stats.Copy()
	var/obj/machinery/chemical_dispenser/os13/fab = new(locate(32,31,1))
	fab.stat = 0
	var/obj/item/vending_charge/chemistry/charge = new(origin)
	user.put_in_hands(charge)
	charge.canremove = FALSE
	fab.attackby(charge, user)
	expect(!fab.chemical_stock && charge.loc == user, "Chemfab consumed an unreleasable Chemistry Charge.")
	charge.canremove = TRUE
	fab.attackby(charge, user)
	expect(fab.chemical_stock == 5 && QDELETED(charge) && fab.locked, "Locked Chemfab charge servicing did not add exactly five points.")
	var/obj/item/card/id/card = new(origin)
	card.access = list(access_medical)
	user.put_in_hands(card)
	fab.attackby(card, user)
	expect(!fab.locked, "Medical keycard did not unlock the Chemfab.")
	user.drop_from_inventory(card)
	var/obj/item/reagent_containers/glass/beaker/beaker = new(origin)
	beaker.reagents.add_reagent(/datum/reagent/water, 10)
	beaker.reagents.add_reagent(/datum/reagent/ethanol, 1)
	user.put_in_hands(beaker)
	fab.attackby(beaker, user)
	expect(fab.container == beaker && !fab.load_water(user) && !fab.water_volume && beaker.reagents.total_volume == 11, "Chemfab purified or consumed a mixed water supply.")
	beaker.reagents.remove_reagent(/datum/reagent/ethanol, 1)
	expect(fab.load_water(user) && fab.water_volume == 10 && !beaker.reagents.total_volume, "Chemfab water loading did not transfer actual clean water.")
	expect(fab.fabricate_injector("Hyperstim", user) && fab.chemical_stock == 2 && fab.water_volume == 5, "Hyperstim did not consume its recorded three-point cost and full water dose.")
	var/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/hyperstim = locate() in user
	expect(hyperstim && hyperstim.reagents.get_reagent_amount(/datum/reagent/os13_medicine/hyperstim) == 5 && hyperstim.reagents.reagent_list.len == 1, "Hyperstim output is missing, substituted or contaminated with inherited medication.")
	if(!hyperstim)
		return
	var/base_strength = user.gurps_stat(STAT_ST)
	var/base_dexterity = user.gurps_stat(STAT_DX)
	var/base_health = user.gurps_stat(STAT_HT)
	expect(hyperstim.attack(user, user) && !hyperstim.reagents.total_volume && hyperstim.icon_state == "injector1" && isturf(hyperstim.loc), "Successful self-injection did not spend and drop the original injector.")
	user.handle_chemicals_in_body()
	expect(user.gurps_stat(STAT_ST) == base_strength + 5 && user.gurps_stat(STAT_DX) == base_dexterity + 2 && user.gurps_stat(STAT_HT) == base_health + 2 && user.stats[STAT_ST] == base_strength, "Hyperstim did not affect real GURPS stats without rewriting permanent strength.")
	user.stats[STAT_ST] += 0.25
	user.bloodstr.add_reagent(/datum/reagent/os13_medicine/hyperstim, 5)
	user.handle_chemicals_in_body()
	expect(user.effective_stat(STAT_ST) == base_strength + 5.25, "Repeated Hyperstim stacked its bonus or destroyed subsequent permanent learning.")
	user.bloodstr.clear_reagents()
	user.handle_chemicals_in_body()
	expect(user.effective_stat(STAT_ST) == base_strength + 0.25 && user.gurps_stat(STAT_DX) == base_dexterity && user.gurps_stat(STAT_HT) == base_health, "Hyperstim removal left a permanent stat contribution.")
	expect(!hyperstim.attack(user, user), "A spent floor injector was reused.")
	qdel(hyperstim)
	// Exercise natural metabolism as well as explicit chemical removal.
	user.bloodstr.add_reagent(/datum/reagent/os13_medicine/hyperstim, 5)
	for(var/i = 1, i <= 250 && user.bloodstr.total_volume, i++)
		user.handle_chemicals_in_body()
	user.handle_chemicals_in_body()
	expect(!user.bloodstr.total_volume && !user.chemical_stat_modifier(STAT_ST) && user.effective_stat(STAT_ST) == base_strength + 0.25, "Natural Hyperstim depletion left an active contribution or damaged permanent learning.")
	world.log << "OS13_OBJECT_CHECK: real Chemfab charge/water loop, Hyperstim delivery, combat stats and reversible nonstacking effects"

	expect(fab.fabricate_injector("Mnemosine", user) && !fab.chemical_stock && !fab.water_volume, "Mnemosine did not consume its recorded two-point cost and remaining water.")
	var/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/mnemosine = locate() in user
	var/base_iq = user.gurps_stat(STAT_IQ)
	var/base_perception = user.gurps_stat(STAT_PER)
	var/base_medical = user.gurps_skill_target("medical")
	expect(mnemosine.attack(user, user), "Mnemosine injector could not administer its distinct formulation.")
	user.handle_chemicals_in_body()
	expect(user.gurps_stat(STAT_IQ) == base_iq + 2 && user.gurps_stat(STAT_PER) == base_perception + 2 && user.gurps_skill_target("medical") == base_medical + 2, "Mnemosine did not reach derived perception and actual cognitive skill checks.")
	user.stats[STAT_IQ] += 1
	user.bloodstr.clear_reagents()
	user.handle_chemicals_in_body()
	expect(user.gurps_stat(STAT_IQ) == base_iq + 1, "Clearing Mnemosine removed permanent intelligence gained during exposure.")
	qdel(mnemosine)
	world.log << "OS13_OBJECT_CHECK: Mnemosine cognitive skills, derived perception and preserved permanent progression"

	// Supply the other three products through the actual machine, not free props.
	for(var/i = 1, i <= 2, i++)
		charge = new(origin)
		user.put_in_hands(charge)
		fab.attackby(charge, user)
	beaker.reagents.add_reagent(/datum/reagent/water, 15)
	fab.load_water(user)
	var/list/formulations = list("Oxivior" = /datum/reagent/os13_medicine/oxivior, "Monogreline" = /datum/reagent/os13_medicine/monogreline, "Polythesine" = /datum/reagent/os13_medicine/polythesine)
	for(var/label in formulations)
		expect(fab.fabricate_injector(label, user), "[label] could not be fabricated from real supplies.")
		var/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/product = locate() in user
		expect(product && product.reagents.get_reagent_amount(formulations[label]) == 5, "[label] contained a substituted reagent.")
		patient.bloodstr.clear_reagents()
		patient.handle_chemicals_in_body()
		patient.sleeping = 0
		if(label == "Oxivior")
			patient.adjustOxyLoss(30)
		if(label == "Polythesine")
			patient.hallucination(100, 40)
		var/blood_before = patient.get_blood_volume()
		var/oxygen_before = patient.get_blood_oxygenation()
		expect(product.attack(patient, user), "[label] could not be administered to another person.")
		patient.handle_chemicals_in_body()
		if(label == "Oxivior")
			expect(patient.get_blood_oxygenation() > oxygen_before && patient.get_blood_volume() == blood_before, "Oxivior did not improve actual circulating oxygenation, or created free blood.")
		if(label == "Monogreline")
			for(var/i = 1, i <= 12, i++)
				patient.handle_chemicals_in_body()
			expect(patient.drowsyness && patient.sleeping, "Monogreline did not produce actual sedation and sleep after exposure.")
		if(label == "Polythesine")
			patient.handle_hallucinations()
			expect(patient.chem_effects[CE_MIND] == 2 && patient.hallucination_power < 40, "Polythesine did not suppress the real hallucination system.")
		qdel(product)
	expect(fab.chemical_stock == 2 && !fab.water_volume, "The three formulations did not consume exactly eight stock and fifteen water.")
	patient.bloodstr.clear_reagents()
	patient.handle_chemicals_in_body()
	expect(!patient.chem_effects[CE_OXYGENATED] && !patient.chem_effects[CE_MIND], "Removed formulations left persistent oxygen or neuroleptic effects.")
	world.log << "OS13_OBJECT_CHECK: physical Oxivior, Monogreline and Polythesine metabolism and actual downstream medical effects"

	beaker.reagents.add_reagent(/datum/reagent/water, 10)
	fab.load_water(user)
	fab.locked = TRUE
	expect(!fab.fabricate_injector("Mnemosine", user) && fab.chemical_stock == 2 && fab.water_volume == 10, "A locked Chemfab spent supplies on an injector.")
	fab.locked = FALSE
	fab.stat = NOPOWER
	expect(!fab.fabricate_injector("Mnemosine", user) && fab.chemical_stock == 2 && fab.water_volume == 10, "An unpowered Chemfab produced medicine or spent supplies.")
	fab.stat = 0
	expect(!fab.fabricate_injector("Cordrazine", user) && fab.chemical_stock == 2 && fab.water_volume == 10, "An unsupported formulation consumed supplies or created a substitute.")
	expect(fab.fabricate_injector("Mnemosine", user), "Chemfab did not recover after lock and power refusals.")
	var/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/interrupted = locate() in user
	spawn(1)
		user.drop_from_inventory(interrupted)
	expect(!interrupted.attack(patient, user) && interrupted.reagents.total_volume == 5 && !interrupted.injecting, "Dropping an injector during its attempt still consumed the dose or retained an action lock.")
	user.put_in_hands(interrupted)
	patient.bloodstr.clear_reagents()
	patient.bloodstr.add_reagent(/datum/reagent/water, patient.bloodstr.maximum_volume)
	expect(!interrupted.attack(patient, user) && interrupted.reagents.total_volume == 5, "A full patient received a partial dose or spent the injector.")
	patient.bloodstr.clear_reagents()
	// Ordinary armor blocks this site; a pressure suit has an injection port.
	var/obj/item/clothing/suit/armor/suit = new(get_turf(patient))
	spawn(1)
		expect(patient.equip_to_slot_if_possible(suit, slot_wear_suit), "The injection-interruption fixture could not equip its blocking armor.")
	expect(!interrupted.attack(patient, user) && interrupted.reagents.total_volume == 5 && !patient.bloodstr.total_volume, "Covering the selected site during injection still committed the dose.")
	qdel(interrupted)
	qdel(fab)
	qdel(user)
	qdel(patient)
	qdel(card)
	world.log << "OS13_OBJECT_CHECK: locked/unpowered/unsupported fabrication and interrupted, full-recipient and covered-site injection conservation"
