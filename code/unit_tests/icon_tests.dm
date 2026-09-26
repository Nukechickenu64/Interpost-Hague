/datum/unit_test/icon_test
	name = "ICON STATE template"

/datum/unit_test/icon_test/los_dither_coverage
	name = "ICON STATE - LOS transition masks use ordered pixel coverage"

/datum/unit_test/icon_test/los_dither_coverage/start_test()
	for(var/coverage in list(4, 8, 12))
		var/icon/pattern = get_los_dither_icon(coverage)
		if(get_los_dither_icon(coverage) != pattern)
			fail("LOS dither icons were not cached.")
			return 1
		var/opaque = 0
		for(var/x in 1 to 4)
			for(var/y in 1 to 4)
				if(!isnull(pattern.GetPixel(x, y)))
					opaque++
		if(opaque != coverage)
			fail("Expected [coverage] opaque pixels, got [opaque] in a 4x4 dither cell.")
			return 1
	pass("LOS transition masks have the expected opaque pixel coverage.")
	return 1

/datum/unit_test/icon_test/depth_layer_crop_shall_preserve_airlock_states
	name = "ICON STATE - Depth layer crop shall preserve airlock states"

/datum/unit_test/icon_test/depth_layer_crop_shall_preserve_airlock_states/start_test()
	var/datum/depth_layer_icons/split_icons = get_depth_layer_icons('icons/obj/doors/Doorint.dmi', 16)
	if(!split_icons)
		fail("The standard airlock icon could not be split.")
		return 1

	var/list/source_states = icon_states('icons/obj/doors/Doorint.dmi')
	var/list/lower_states = icon_states(split_icons.lower)
	var/list/upper_states = icon_states(split_icons.upper)

	if(split_icons.lower.Height() != 16 || split_icons.upper.Height() != 16)
		fail("Depth-layered airlock icons did not have two 16 pixel sections.")
	else if(source_states.len != lower_states.len || source_states.len != upper_states.len)
		fail("Depth-layered airlock icons did not preserve every source icon state.")
	else if(get_depth_layer_icons('icons/obj/doors/Doorint.dmi', 16) != split_icons)
		fail("Depth-layered icons were not reused from the cache.")
	else
		pass("Depth-layered airlock icons preserved dimensions and states.")
	return 1

/datum/unit_test/icon_test/depth_layer_crop_shall_support_multi_tile_airlocks
	name = "ICON STATE - Depth layer crop shall support multi-tile airlocks"

/datum/unit_test/icon_test/depth_layer_crop_shall_support_multi_tile_airlocks/start_test()
	var/list/airlock_icons = list(
		'icons/obj/doors/Door2x1metal.dmi',
		'icons/obj/doors/Door2x1glass.dmi'
	)

	for(var/airlock_icon in airlock_icons)
		var/icon/source_icon = icon(airlock_icon)
		var/datum/depth_layer_icons/split_icons = get_depth_layer_icons(airlock_icon, 16)
		if(!split_icons || split_icons.lower.Width() != source_icon.Width() || split_icons.upper.Width() != source_icon.Width())
			fail("Multi-tile airlock icon '[airlock_icon]' did not preserve its width when split.")
			return 1
		if(split_icons.lower.Height() != 16 || split_icons.upper.Height() != source_icon.Height() - 16)
			fail("Multi-tile airlock icon '[airlock_icon]' was split at the wrong height.")
			return 1

	pass("Multi-tile airlock icons supported the depth split.")
	return 1

/datum/unit_test/icon_test/depth_layer_crop_shall_support_blast_id_doors
	name = "ICON STATE - Depth layer crop shall support blast ID doors"

/datum/unit_test/icon_test/depth_layer_crop_shall_support_blast_id_doors/start_test()
	var/list/blast_id_door_icons = list(
		'icons/obj/doors/door4.dmi'
	)

	for(var/blast_id_door_icon in blast_id_door_icons)
		var/icon/source_icon = icon(blast_id_door_icon)
		var/datum/depth_layer_icons/split_icons = get_depth_layer_icons(blast_id_door_icon, 16)
		if(!split_icons)
			fail("Blast ID door icon '[blast_id_door_icon]' could not be split.")
			return 1
		if(split_icons.lower.Width() != source_icon.Width() || split_icons.upper.Width() != source_icon.Width())
			fail("Blast ID door icon '[blast_id_door_icon]' did not preserve its width when split.")
			return 1
		if(split_icons.lower.Height() != 16 || split_icons.upper.Height() != source_icon.Height() - 16)
			fail("Blast ID door icon '[blast_id_door_icon]' was split at the wrong height.")
			return 1
		if(icon_states(split_icons.lower).len != icon_states(blast_id_door_icon).len || icon_states(split_icons.upper).len != icon_states(blast_id_door_icon).len)
			fail("Blast ID door icon '[blast_id_door_icon]' did not preserve every source icon state.")
			return 1

	pass("Blast ID door icons supported the depth split.")
	return 1

/datum/unit_test/icon_test/depth_layer_visual_shall_attach_and_restore
	name = "ICON STATE - Depth layer visual shall attach and restore"

/datum/unit_test/icon_test/depth_layer_visual_shall_attach_and_restore/start_test()
	var/list/test_icons = list(
		'icons/obj/doors/Doorint.dmi',
		'icons/obj/doors/door4.dmi'
	)

	for(var/test_icon in test_icons)
		var/obj/test_object = new
		test_object.icon = test_icon
		test_object.icon_state = "door_closed"

		if(!test_object.enable_depth_layering(16))
			fail("A valid object using '[test_icon]' could not enable depth layering.")
			qdel(test_object)
			return 1

		var/atom/movable/overlay/depth_layer/upper_visual = test_object.depth_layer_upper
		if(!upper_visual || !(upper_visual in test_object.vis_contents))
			fail("The upper visual was not attached to its owner.")
			qdel(test_object)
			return 1
		if(upper_visual.master != test_object || upper_visual.mouse_opacity != 0)
			fail("The upper visual was not passive and owned by the source object.")
			qdel(test_object)
			return 1
		if(upper_visual.layer != ABOVE_HUMAN_LAYER || upper_visual.pixel_y != 16)
			fail("The upper visual did not use the configured depth layer and offset.")
			qdel(test_object)
			return 1
		if(!test_object.enable_depth_layering(16))
			fail("Enabling depth layering a second time failed.")
			qdel(test_object)
			return 1

		test_object.disable_depth_layering()
		if(test_object.depth_layer_upper || test_object.icon != test_icon)
			fail("Disabling depth layering did not restore the owner.")
			qdel(test_object)
			return 1
		qdel(test_object)

	pass("The depth-layer visuals attached, reused their sources, and restored cleanly.")
	return 1

/datum/unit_test/icon_test/robots_shall_have_eyes_for_each_state
	name = "ICON STATE - Robot shall have eyes for each icon state"
	var/list/excepted_icon_states_ = list(
		"b1","b1+o","b2","b2+o","b3","b3+o","d1","d1+o","d2","d2+o","d3","d3+o",
		"floor1","floor2","floor3","floor4","floor5","floor6","floor7",
		"gib1","gib2","gib3","gib4","gib5","gib6","gib7","gibdown","gibup","gibbl1","gibarm","gibleg",
		"streak1","streak2","streak3","streak4","streak5",
		"droid-combat-roll","droid-combat-shield","emag","remainsrobot", "robot+o+c","robot+o-c","robot+we")

/datum/unit_test/icon_test/robots_shall_have_eyes_for_each_state/start_test()
	var/missing_states = 0
	var/list/valid_states = icon_states('icons/mob/robots.dmi')

	var/list/original_valid_states = valid_states.Copy()
	for(var/icon_state in valid_states)
		if(icon_state in excepted_icon_states_)
			continue
		if(starts_with(icon_state, "eyes-"))
			continue
		if(findtext(icon_state, "openpanel"))
			continue
		var/eye_icon_state = "eyes-[icon_state]"
		if(!(eye_icon_state in valid_states))
			log_unit_test("Eye icon state [eye_icon_state] is missing.")
			missing_states++

	if(missing_states)
		fail("[missing_states] eye icon state\s [missing_states == 1 ? "is" : "are"] missing.")
		var/list/difference = uniquemergelist(original_valid_states, valid_states)
		if(difference.len)
			log_unit_test("[ascii_yellow]---  DEBUG  --- ICON STATES AT START: " + jointext(original_valid_states, ",") + "[ascii_reset]")
			log_unit_test("[ascii_yellow]---  DEBUG  --- ICON STATES AT END: "   + jointext(valid_states, ",") + "[ascii_reset]")
			log_unit_test("[ascii_yellow]---  DEBUG  --- UNIQUE TO EACH LIST: " + jointext(difference, ",") + "[ascii_reset]")
	else
		pass("All related eye icon states exists.")
	return 1

/datum/unit_test/icon_test/sprite_accessories_shall_have_existing_icon_states
	name = "ICON STATE - Sprite accessories shall have existing icon states"

/datum/unit_test/icon_test/sprite_accessories_shall_have_existing_icon_states/start_test()
	var/sprite_accessory_subtypes = list(
		/datum/sprite_accessory/hair,
		/datum/sprite_accessory/facial_hair
	)

	var/list/failed_sprite_accessories = list()
	var/icon_state_cache = list()
	var/duplicates_found = FALSE

	for(var/sprite_accessory_main_type in sprite_accessory_subtypes)
		var/sprite_accessories_by_name = list()
		for(var/sprite_accessory_type in subtypesof(sprite_accessory_main_type))
			var/failed = FALSE
			var/datum/sprite_accessory/sat = sprite_accessory_type

			var/sat_name = initial(sat.name)
			if(sat_name)
				group_by(sprite_accessories_by_name, sat_name, sat)
			else
				failed = TRUE
				log_bad("[sat] - Did not have a name set.")

			var/sat_icon = initial(sat.icon)
			if(sat_icon)
				var/sat_icon_states = icon_state_cache[sat_icon]
				if(!sat_icon_states)
					sat_icon_states = icon_states(sat_icon)
					icon_state_cache[sat_icon] = sat_icon_states

				var/sat_icon_state = initial(sat.icon_state)
				if(sat_icon_state)
					sat_icon_state = "[sat_icon_state]_s"
					if(!(sat_icon_state in sat_icon_states))
						failed = TRUE
						log_bad("[sat] - \"[sat_icon_state]\" did not exist in '[sat_icon]'.")
				else
					failed = TRUE
					log_bad("[sat] - Did not have an icon state set.")
			else
				failed = TRUE
				log_bad("[sat] - Did not have an icon set.")

			if(failed)
				failed_sprite_accessories += sat

		if(number_of_issues(sprite_accessories_by_name, "Sprite Accessory Names"))
			duplicates_found = TRUE

	if(failed_sprite_accessories.len || duplicates_found)
		fail("One or more sprite accessory issues detected.")
	else
		pass("All sprite accessories were valid.")

	return 1
