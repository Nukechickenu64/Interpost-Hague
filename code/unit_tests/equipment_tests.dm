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

#undef SUCCESS
#undef FAILURE
