/datum/unit_test/research_designs_shall_be_unique
	name = "UNIQUENESS: Research Designs Shall Be Unique"

/datum/unit_test/research_designs_shall_be_unique/start_test()
	var/list/ids = list()
	var/list/build_paths = list()

	for(var/design_type in subtypesof(/datum/design))
		var/datum/design/design = design_type
		if(initial(design.id) == "id")
			continue

		group_by(ids, initial(design.id), design)
		group_by(build_paths, initial(design.build_path), design)

	var/number_of_issues = number_of_issues(ids, "IDs")
	number_of_issues += number_of_issues(build_paths, "Build Paths")

	if(number_of_issues)
		fail("[number_of_issues] issues with research designs found.")
	else
		pass("All research designs are unique.")

	return 1

/datum/unit_test/research_processor_only_offers_buildable_designs
	name = "RESEARCH: Ideation Condenser Only Offers Buildable Designs"

/datum/unit_test/research_processor_only_offers_buildable_designs/start_test()
	var/obj/machinery/research_processor/processor = new
	var/list/choices = processor.get_design_choices("grief")
	var/valid = choices && choices.len
	for(var/design_type in choices)
		var/datum/design/design = design_type
		if(!initial(design.build_path) || !(initial(design.build_type) & (PROTOLATHE|IMPRINTER)))
			valid = FALSE
	var/selected_type = processor.pick_weighted_design("grief")
	if(selected_type && !(selected_type in choices))
		valid = FALSE
	qdel(processor)
	if(valid)
		pass("The condenser selects only designs that a fabricator can build.")
	else
		fail("The condenser candidate pool includes invalid designs or is empty.")
	return 1

/datum/unit_test/bluegate_activation_is_occupant_only
	name = "BLUEGATE: Only Occupant Can Activate Transformation"

/datum/unit_test/bluegate_activation_is_occupant_only/start_test()
	var/obj/machinery/bluegate/gate = new
	var/mob/living/carbon/human/occupant = new(null)
	var/mob/living/carbon/human/bystander = new(null)
	gate.occupant = occupant
	var/valid = gate.can_activate(occupant) && !gate.can_activate(bystander)
	qdel(gate)
	qdel(occupant)
	qdel(bystander)
	if(valid)
		pass("Only the current Bluegate occupant can activate transformation.")
	else
		fail("Bluegate activation authorization does not match the occupant.")
	return 1

/datum/unit_test/research_console_restricts_sensitive_topic_actions
	name = "RESEARCH: Sensitive Console Actions Require Access"

/datum/unit_test/research_console_restricts_sensitive_topic_actions/start_test()
	var/obj/machinery/computer/rdconsole/console = new
	var/list/disk_action = list("copy_tech" = "1")
	var/list/mixed_action = list("menu" = "1.1", "reset" = "1")
	var/list/public_action = list("build" = "design_id")
	var/valid = console.topic_requires_research_access(disk_action)
	valid = valid && console.topic_requires_research_access(mixed_action)
	valid = valid && !console.topic_requires_research_access(public_action)
	valid = valid && console.topic_menu_is_public(5.0) && !console.topic_menu_is_public(1.6)
	qdel(console)
	if(valid)
		pass("Sensitive href actions are classified independently of the visible menu.")
	else
		fail("R&D console href action authorization classification is incorrect.")
	return 1

/datum/unit_test/mining_sell_order_accepts_ten_sheet_stack
	name = "MINING: Sell Orders Accept Ten-Sheet Material Stacks"

/datum/unit_test/mining_sell_order_accepts_ten_sheet_stack/start_test()
	var/datum/sell_order/mining/osmium/v10/order = new
	var/obj/item/stack/material/osmium/ten/stack = new
	var/accepted = order.add_item(stack)
	var/valid = accepted && order.progress == order.max_progress
	qdel(stack)
	qdel(order)
	if(valid)
		pass("Mining sell orders accept matching material stack subtypes.")
	else
		fail("An Osmium ten-sheet stack did not satisfy its mining sell order.")
	return 1

/datum/unit_test/sell_order_clamps_reagent_oversupply
	name = "CARGO: Sell Orders Clamp Reagent Oversupply"

/datum/unit_test/sell_order_clamps_reagent_oversupply/start_test()
	var/datum/sell_order/order = new
	order.wanted = list(/datum/reagent/water = 10)
	order.max_progress = 10
	var/obj/item/weapon/reagent_containers/glass/beaker/beaker = new
	beaker.reagents.add_reagent(/datum/reagent/water, 20)
	var/accepted = order.add_item(beaker)
	var/valid = accepted && order.wanted[/datum/reagent/water] == 0 && order.progress == order.max_progress
	qdel(beaker)
	qdel(order)
	if(valid)
		pass("Reagent oversupply is clamped to the order's remaining amount.")
	else
		fail("Reagent oversupply left invalid sell-order progress.")
	return 1

/datum/unit_test/player_preferences_shall_have_unique_key
	name = "UNIQUENESS: Player Preferences Shall Be Unique"

/datum/unit_test/player_preferences_shall_have_unique_key/start_test()
	var/list/preference_keys = list()

	for(var/cp in get_client_preferences())
		var/datum/client_preference/client_pref = cp
		group_by(preference_keys, client_pref.key, client_pref)

	var/number_of_issues = number_of_issues(preference_keys, "Keys")
	if(number_of_issues)
		fail("[number_of_issues] issues with player preferences found.")
	else
		pass("All player preferences have unique keys.")
	return 1

/datum/unit_test/access_datums_shall_be_unique
	name = "UNIQUENESS: Access Datums Shall Be Unique"

/datum/unit_test/access_datums_shall_be_unique/start_test()
	var/list/access_ids = list()
	var/list/access_descs = list()

	for(var/a in get_all_access_datums())
		var/datum/access/access = a
		group_by(access_ids, num2text(access.id), access)
		group_by(access_descs, access.desc, access)

	var/number_of_issues = number_of_issues(access_ids, "Ids")
	number_of_issues += number_of_issues(access_descs, "Descriptions")
	if(number_of_issues)
		fail("[number_of_issues] issue\s with access datums found.")
	else
		pass("All access datums are unique.")
	return 1

/datum/unit_test/outfit_datums_shall_have_unique_names
	name = "UNIQUENESS: Outfit Datums Shall Have Unique Names"

/datum/unit_test/outfit_datums_shall_have_unique_names/start_test()
	var/list/outfits_by_name = list()

	for(var/a in outfits())
		var/decl/hierarchy/outfit/outfit = a
		group_by(outfits_by_name, outfit.name, outfit.type)

	var/number_of_issues = number_of_issues(outfits_by_name, "Names")
	if(number_of_issues)
		fail("[number_of_issues] issue\s with outfit datums found.")
	else
		pass("All outfit datums have unique names.")
	return 1

/datum/unit_test/languages_shall_have_unique_names
	name = "UNIQUENESS: Languages Shall Have Unique Names"

/datum/unit_test/languages_shall_have_unique_names/start_test()
	var/list/languages_by_name = list()

	for(var/lt in subtypesof(/datum/language))
		var/datum/language/l = lt
		group_by(languages_by_name, initial(l.name), lt)

	var/number_of_issues = number_of_issues(languages_by_name, "Language Names")
	if(number_of_issues)
		fail("[number_of_issues] issue\s with language datums found.")
	else
		pass("All languages datums have unique names.")
	return 1

/datum/unit_test/languages_shall_have_no_or_unique_keys
	name = "UNIQUENESS: Languages Shall Have No or Unique Keys"

/datum/unit_test/languages_shall_have_no_or_unique_keys/start_test()
	var/list/languages_by_key = list()

	for(var/lt in subtypesof(/datum/language))
		var/datum/language/l = lt
		var/language_key = initial(l.key)
		if(!language_key)
			continue

		group_by(languages_by_key, language_key, lt)

	var/number_of_issues = number_of_issues(languages_by_key, "Language Keys")
	if(number_of_issues)
		fail("[number_of_issues] issue\s with language datums found.")
	else
		pass("All languages datums have unique keys.")
	return 1

/datum/unit_test/outfit_backpacks_shall_have_unique_names
	name = "UNIQUENESS: Outfit Backpacks Shall Have Unique Names"

/datum/unit_test/outfit_backpacks_shall_have_unique_names/start_test()
	var/list/backpacks_by_name = list()

	var/bos = decls_repository.get_decls_of_subtype(/decl/backpack_outfit)
	for(var/bo in bos)
		var/decl/backpack_outfit/backpack_outfit = bos[bo]
		group_by(backpacks_by_name, backpack_outfit.name, backpack_outfit)

	var/number_of_issues = number_of_issues(backpacks_by_name, "Outfit Backpack Names")
	if(number_of_issues)
		fail("[number_of_issues] outfit backpacks\s found.")
	else
		pass("All outfit backpacks have unique names.")
	return 1


/datum/unit_test/proc/number_of_issues(var/list/entries, var/type, var/feedback = /decl/noi_feedback)
	var/issues = 0
	for(var/key in entries)
		var/list/values = entries[key]
		if(values.len > 1)
			var/decl/noi_feedback/noif = decls_repository.get_decl(feedback)
			noif.print(src, type, key, values)
			issues++

	return issues

/decl/noi_feedback/proc/priv_print(var/datum/unit_test/ut, var/type, var/key, var/output_text)
	ut.log_bad("[type] - [key] - The following entries have the same value: [output_text]")

/decl/noi_feedback/proc/print(var/datum/unit_test/ut, var/type, var/key, var/list/entries)
	priv_print(ut, type, key, english_list(entries))

/decl/noi_feedback/detailed/print(var/datum/unit_test/ut, var/type, var/key, var/list/entries)
	var/list/pretty_print = list()
	pretty_print += ""
	for(var/entry in entries)
		pretty_print += log_info_line(entry)
	priv_print(ut, type, key, jointext(pretty_print, "\n"))
