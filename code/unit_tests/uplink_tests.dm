/datum/unit_test/uplink_setup_test
	name = "UPLINK: All uplink items shall be valid."

/datum/unit_test/uplink_setup_test/start_test()
	var/success = TRUE

	for(var/item in uplink.items)
		var/datum/uplink_item/ui = item
		success = is_valid_uplink_item(ui, "Uplink items") && success

	for(var/item in uplink.items_assoc)
		var/datum/uplink_item/ui = uplink.items_assoc[item]
		success = is_valid_uplink_item(ui, "Uplink assoc items") && success

	var/datum/uplink_random_selection/uplink_selection = get_uplink_random_selection_by_type(/datum/uplink_random_selection/blacklist)
	for(var/item in uplink_selection.items)
		var/datum/uplink_random_item/uri = item // Basically ensuring random uplink items is a subset of the full range of items
		success = is_valid_uplink_item(uplink.items_assoc[uri.uplink_item], "Random uplink items", uri.uplink_item) && success

	if(success)
		pass("All uplink items were valid.")
	else
		fail("One or more uplink items were invalid.")

	return TRUE

/datum/unit_test/antagonist_preferences_enabled_by_default
	name = "PREFERENCES: All antagonist roles are enabled by default."

/datum/unit_test/antagonist_preferences_enabled_by_default/start_test()
	var/datum/preferences/preferences = new
	preferences.be_special_role = list()
	preferences.never_be_special_role = list("legacy_non_antagonist_role")

	var/first_antag_id
	for(var/antag_type in GLOB.all_antag_types_)
		var/datum/antagonist/antag = GLOB.all_antag_types_[antag_type]
		first_antag_id = antag.id
		preferences.never_be_special_role |= antag.id
		break

	preferences.normalize_antagonist_role_preferences()
	var/success = first_antag_id ? TRUE : FALSE
	for(var/antag_type in GLOB.all_antag_types_)
		var/datum/antagonist/antag = GLOB.all_antag_types_[antag_type]
		if(!(antag.id in preferences.be_special_role) || (antag.id in preferences.never_be_special_role))
			success = FALSE
	preferences.normalize_antagonist_role_preferences()
	if(!(first_antag_id in preferences.be_special_role) || (first_antag_id in preferences.never_be_special_role))
		success = FALSE
	if(!("legacy_non_antagonist_role" in preferences.never_be_special_role))
		success = FALSE

	var/datum/category_group/player_setup_category/general_preferences/general_category = preferences.player_setup.categories_by_name["General"]
	if(!general_category || !general_category.items_by_name["Antag Setup"] || preferences.player_setup.categories_by_name["Roles"])
		success = FALSE

	qdel(preferences)
	if(success)
		pass("All registered antagonist roles default to High; the Roles category is removed and uplink setup remains under General.")
	else
		fail("Antagonist role defaults or preference category registration were incorrect.")
	return TRUE

/datum/unit_test/uplink_setup_test/proc/is_valid_uplink_item(var/datum/uplink_item/ui, var/type, var/optional_uplink_item_type)
	if(!istype(ui))
		log_bad("[type]: [ui] was of an unexpected type: [ui ? ui.type : (optional_uplink_item_type ? optional_uplink_item_type : "NULL")]")
		return FALSE
	if(!ui.category)
		log_bad("[type]: [ui] has no category.")
		return FALSE
	var/cost = 	ui.cost(0)
	if(cost <= 0)
		log_bad("[type]: [ui] has an invalid cost of [cost].")
		return FALSE
	return TRUE
