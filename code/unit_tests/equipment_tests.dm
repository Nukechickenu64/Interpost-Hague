#ifndef SUCCESS
#define SUCCESS 1
#endif
#ifndef FAILURE
#define FAILURE 0
#endif


datum/unit_test/vision_glasses/
	name = "EQUIPMENT: Vision Template"
	var/mob/living/carbon/human/H = null
	var/expectation = SEE_INVISIBLE_NOLIGHTING
	var/glasses_type = null
	async = 1

datum/unit_test/vision_glasses/start_test()
	spawn(0)
		var/list/test = create_test_mob_with_mind(null, /mob/living/carbon/human)
		if(isnull(test))
			fail("Check Runtimed in Mob creation")

		if(test["result"] == FAILURE)
			fail(test["msg"])
			async = 0

		H = locate(test["mobref"])

		var/obj/item/clothing/glasses/G = new glasses_type()
		H.glasses = G

	return 1


datum/unit_test/vision_glasses/check_result()

	if(isnull(H) || H.life_tick < 2)
		return 0

	if(isnull(H.glasses))
		fail("Mob doesn't have glasses on")

	H.handle_vision()	// Because Life has a client check that bypasses updating vision

	if(H.see_invisible == expectation)
		pass("Mob See invisible is [H.see_invisible]")
	else
		fail("Mob See invisible is [H.see_invisible] / expected [expectation]")

	return 1

datum/unit_test/vision_glasses/NVG
	name = "EQUIPMENT: NVG see_invis"
	glasses_type = /obj/item/clothing/glasses/night

datum/unit_test/vision_glasses/mesons
	name = "EQUIPMENT: Mesons see_invis"
	glasses_type = /obj/item/clothing/glasses/meson

datum/unit_test/vision_glasses/plain
	name = "EQUIPMENT: Plain glasses. see_invis"
	glasses_type = /obj/item/clothing/glasses/regular
	expectation = SEE_INVISIBLE_LIVING

datum/unit_test/preference_starting_gear
	name = "EQUIPMENT: Naked crew spawns clear preference gear"

/datum/unit_test/preference_starting_gear/start_test()
	var/list/test = create_test_mob_with_mind(null, /mob/living/carbon/human)
	if(isnull(test) || test["result"] == FAILURE)
		fail(isnull(test) ? "Human test mob creation returned null." : test["msg"])
		return TRUE

	var/mob/living/carbon/human/H = locate(test["mobref"])
	if(!H)
		fail("Human test mob could not be located.")
		return TRUE

	var/original_gender = H.gender
	var/original_hair_style = H.h_style
	var/obj/item/underwear/U = new(H)
	U.ForceEquipUnderwear(H, FALSE)
	H.backpack_setup = new /datum/backpack_setup(null, null)
	H.clear_preference_starting_gear()

	if(H.worn_underwear.len || H.backpack_setup)
		fail("Preference underwear or backpack setup remained on the human.")
	else if(H.gender != original_gender || H.h_style != original_hair_style)
		fail("Clearing preference gear changed character appearance.")
	else
		pass("Preference gear was cleared without changing character appearance.")

	qdel(H)
	return TRUE

// ============================================================================

datum/unit_test/storage_capacity_test
datum/unit_test/item_weapon_classification
	name = "EQUIPMENT: Only combat items should be classified as weapons"

/datum/unit_test/item_weapon_classification/start_test()
	var/list/non_weapon_types = list(
		/obj/item/paper,
		/obj/item/card/id,
		/obj/item/reagent_containers/food/snacks,
		/obj/item/storage,
		/obj/item/wrench,
		/obj/item/tank
	)
	for(var/item_type in non_weapon_types)
		if(ispath(item_type, /obj/item/weapon))
			fail("[item_type] is still classified as a weapon.")
			return TRUE

	if(!ispath(/obj/item/weapon/gun, /obj/item/weapon) || !ispath(/obj/item/weapon/melee, /obj/item/weapon))
		fail("Gun or melee weapon types are no longer classified as weapons.")
		return TRUE

	pass("Noncombat item families and combat weapon families have distinct type ancestry.")
	return TRUE

datum/unit_test/storage_capacity_test
	name = "EQUIPMENT: Storage items should be able to actually hold their initial contents"

datum/unit_test/storage_capacity_test/start_test()
	var/bad_tests = 0

	// obj/item/storage/internal cannot be tested sadly, as they expect their host object to create them
	for(var/storage_type in subtypesof(/obj/item/storage) - typesof(/obj/item/storage/internal))
		var/obj/item/storage/S = new storage_type(null) //should be fine to put it in nullspace...
		var/bad_msg = "[ascii_red]--------------- [S.name] \[[S.type]\]"
		bad_tests += test_storage_capacity(S, bad_msg)

	if(bad_tests)
		fail("\[[bad_tests]\] Some storage item types were not able to hold their default initial contents.")
	else
		pass("All storage item types were able to hold their default initial contents.")

	return 1

/proc/test_storage_capacity(obj/item/storage/S, var/bad_msg)
	var/bad_tests = 0

	// TODO: re-implement
	return bad_tests

/obj/item/device/pda/registration_test
	var/registration_response = "Field Engineer"
	var/last_suggested_name
	var/obj/item/drop_during_prompt

/obj/item/device/pda/registration_test/prompt_registration_name(mob/user, suggested_name)
	last_suggested_name = suggested_name
	if(drop_during_prompt)
		user.drop_from_inventory(drop_during_prompt)
		drop_during_prompt = null
	return registration_response

/datum/unit_test/pda_id_cards
	name = "EQUIPMENT: PDAs accept unnamed IDs and transfer the presented card safely"

/datum/unit_test/pda_id_cards/start_test()
	var/mob/living/carbon/human/actor = new(get_safe_turf())
	var/obj/item/device/pda/registration_test/device = new(actor)
	var/obj/item/pen/held_tool = new(actor)
	actor.put_in_active_hand(held_tool)
	var/obj/item/card/id/spare = new(actor)
	spare.registered_name = null
	spare.rank = "Engineer"
	spare.assignment = "Atmospheric Technician"
	actor.put_in_inactive_hand(spare)

	// The presented card may be in the other hand. First use should register AND insert it.
	device.attackby(spare, actor)
	if(device.id != spare || spare.loc != device || actor.get_inactive_hand())
		fail("The unnamed spare ID was rejected, left in hand, or not inserted on first use.")
	if(device.owner != "Field Engineer" || spare.registered_name || device.ownrank != "Engineer" || device.ownjob != "Atmospheric Technician")
		fail("Registration lost the chosen PDA name, changed the ID itself, or confused rank with alternate assignment.")

	var/obj/item/card/id/named = new(actor)
	named.registered_name = "Roche Hendson"
	named.rank = "Engineer"
	named.assignment = "Atmospheric Technician"
	actor.put_in_inactive_hand(named)
	for(var/invalid_name in list(null, "   ", "<b>Bad Name</b>", "This name is longer than twenty six characters"))
		device.registration_response = invalid_name
		if(device.id_check(actor, 2, named) || device.id != spare || spare.loc != device || named.loc != actor || device.owner != "Field Engineer")
			fail("Cancelling or entering an invalid name changed the ID slot, inventory, or PDA owner.")
	device.registration_response = "Cargo Runner"
	device.attackby(named, actor)
	if(device.id != named || named.loc != device || spare.loc != actor || actor.get_inactive_hand() != spare || actor.get_active_hand() != held_tool)
		fail("Swapping IDs moved the wrong item or failed to return the previous card.")
	if(device.owner != "Cargo Runner" || named.registered_name != "Roche Hendson" || device.last_suggested_name != "Field Engineer")
		fail("A card swap did not offer the existing name or failed to apply the chosen name only to the PDA.")

	actor.drop_from_inventory(spare)
	var/obj/item/card/id/locked = new(actor)
	actor.put_in_inactive_hand(locked)
	locked.canremove = FALSE
	if(device.id_check(actor, 2, locked) || device.id != named || named.loc != device || locked.loc != actor)
		fail("A failed unequip changed the ID slot or bypassed the card's removal restriction.")
	locked.canremove = TRUE
	if(device.id_check(actor, 2, spare) || spare.loc != get_safe_turf() || device.id != named)
		fail("The PDA accepted a card that the user was not carrying.")
	device.drop_during_prompt = locked
	if(device.id_check(actor, 2, locked) || device.id != named || locked.loc != get_safe_turf() || device.owner != "Cargo Runner")
		fail("Registration moved a card that was dropped while the name prompt was open.")
	actor.put_in_inactive_hand(locked)

	if(!device.id_check(actor, 1) || device.id || named.loc == device)
		fail("The UI could not eject the inserted ID with both hands full.")
	actor.drop_from_inventory(locked)
	if(device.id_check(actor, 1) || device.id)
		fail("The empty ID slot reported success when neither hand held a card.")

	var/obj/item/device/pda/registration_test/fresh_device = new(actor)
	fresh_device.registration_response = "Roche Custom"
	actor.put_in_inactive_hand(named)
	if(!fresh_device.id_check(actor, 1) || fresh_device.id != named || named.loc != fresh_device)
		fail("The screen's Insert ID action did not find the card in the inactive hand.")
	if(fresh_device.owner != "Roche Custom" || fresh_device.last_suggested_name != "Roche Hendson" || named.registered_name != "Roche Hendson" || fresh_device.ownrank != "Engineer" || fresh_device.ownjob != "Atmospheric Technician")
		fail("Named-card registration lost the chosen name, card-name suggestion, rank, or alternate assignment, or changed the ID itself.")

	qdel(spare)
	qdel(named)
	qdel(locked)
	qdel(held_tool)
	qdel(device)
	qdel(fresh_device)
	qdel(actor)
	if(!reported)
		pass("Custom-name registration, cancellation, invalid input, card swaps, and interrupted prompts preserve inventory and ID identity.")
	return TRUE

#undef SUCCESS
#undef FAILURE
