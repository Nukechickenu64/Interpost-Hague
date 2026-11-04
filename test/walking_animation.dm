// Only replace the connected player's preference; exercise real eligibility,
// body/equipment composition, pose caching, and delayed reset behavior.
/mob/living/carbon/human/walking_test
	var/test_walking_enabled = TRUE

/mob/living/carbon/human/walking_test/walking_animation_enabled()
	return test_walking_enabled

/area/walking_regression
	has_gravity = TRUE
	requires_power = FALSE

/datum/unit_test/proc/walking_fixture()
	var/turf/T = combat_test_turf()
	var/area/walking_regression/A = new
	for(var/turf/floor in range(1, T))
		A.contents += floor
	var/mob/living/carbon/human/walking_test/H = new(T)
	STOP_PROCESSING(SSmobs, H)
	H.regenerate_icons()
	H.update_canmove()
	return H

/proc/walking_matches_standing(mob/living/carbon/human/H)
	var/icon/rendered = icon(H.icon)
	for(var/facing in list(SOUTH, NORTH, EAST, WEST))
		for(var/x = 1, x <= 32, x++)
			for(var/y = 1, y <= 32, y++)
				if(rendered.GetPixel(x, y, dir = facing) != H.stand_icon.GetPixel(x, y, dir = facing))
					return FALSE
	return TRUE

// Test/preview only: CPU rendering of the startup masks, never included in the
// production renderer. Gameplay uses alpha filters on existing appearances.
/proc/walking_test_icon(icon/source, phase, garment = FALSE)
	var/icon/result = icon('icons/effects/effects.dmi', "nothing")
	for(var/facing in list(SOUTH, NORTH, EAST, WEST))
		var/icon/frame = icon(source, null, facing)
		if(!length(icon_states(frame)))
			frame = icon(source, null, SOUTH)
		var/icon/pose = icon('icons/effects/effects.dmi', "nothing")
		for(var/list/slice in SSwalking.get_pose(facing, phase, garment))
			var/icon/piece = new(frame)
			piece.Blend(slice[1], ICON_MULTIPLY)
			if(slice[2]) piece.Shift(slice[2] > 0 ? EAST : WEST, abs(slice[2]))
			if(slice[3]) piece.Shift(NORTH, slice[3])
			if(slice[4]) piece.Blend(rgb(210, 210, 210), ICON_MULTIPLY)
			pose.Blend(piece, ICON_OVERLAY)
		result.Insert(pose, icon_state = "", dir = facing)
	return result

/datum/unit_test/walking_pixels
	name = "WALKING - Pixel masks and directional poses"

/datum/unit_test/walking_pixels/start_test()
	var/icon/source = icon('icons/effects/effects.dmi', "nothing")
	source.DrawBox("#ff0000", 12, 3, 12, 3)
	source.DrawBox("#00ff00", 20, 3, 20, 3)
	source.DrawBox("#0000ff", 16, 20, 16, 20)
	source.DrawBox("#ffff00", 13, 11, 13, 11)
	var/icon/single_direction = walking_test_icon(source, 1)
	var/icon/directional = icon('icons/effects/effects.dmi', "nothing")
	for(var/facing in list(SOUTH, NORTH, EAST, WEST))
		directional.Insert(source, icon_state = "", dir = facing)
	source = directional
	var/icon/left = walking_test_icon(source, 1)
	var/icon/right = walking_test_icon(source, -1)
	var/failure = ""
	if(left.GetPixel(12, 4, "", SOUTH) != "#ff0000" || left.GetPixel(20, 3, "", SOUTH) != "#00ff00")
		failure += "South-facing planted and raised feet are incorrect. "
	if(right.GetPixel(12, 3, "", SOUTH) != "#ff0000" || right.GetPixel(20, 4, "", SOUTH) != "#00ff00")
		failure += "The other foot does not alternate. "
	if(left.GetPixel(12, 3, "", NORTH) != "#ff0000" || left.GetPixel(20, 4, "", NORTH) != "#00ff00")
		failure += "North-facing gait does not mirror the feet. "
	for(var/facing in list(SOUTH, NORTH, EAST, WEST))
		if(single_direction.GetPixel(16, 20, "", facing) != "#0000ff")
			failure += "One-direction equipment vanished facing [facing]. "
		if(left.GetPixel(16, 20, "", facing) != "#0000ff" || right.GetPixel(16, 20, "", facing) != "#0000ff")
			failure += "Upper body moved in direction [facing]. "
		if(left.GetPixel(13, 11, "", facing) != "#ffff00" || right.GetPixel(13, 11, "", facing) != "#ffff00")
			failure += "Hand pixels moved away from gloves/held items in direction [facing]. "
	if(source.GetPixel(12, 3) != "#ff0000" || source.GetPixel(12, 4))
		failure += "Pose generation mutated the source. "
	var/icon/robe = walking_test_icon(source, 1, TRUE)
	if(robe.GetPixel(13, 3, "", SOUTH) != "#ff0000" || robe.GetPixel(21, 3, "", SOUTH) != "#00ff00")
		failure += "Long garment hem was split rather than shifted together. "
	if(failure) fail(failure)
	else pass("Feet alternate, north mirrors south, torso stays fixed, garment hems stay together, sources are unchanged.")
	return TRUE

/datum/unit_test/walking_equipment
	name = "WALKING - Equipment, nested overlays, cache and exported poses"

/datum/unit_test/walking_equipment/start_test()
	var/mob/living/carbon/human/walking_test/H = walking_fixture()
	var/failure = ""
	H.equip_to_slot_if_possible(new /obj/item/clothing/under/color/grey(H), slot_w_uniform)
	H.equip_to_slot_if_possible(new /obj/item/clothing/shoes/black(H), slot_shoes)
	H.update_inv_w_uniform()
	H.update_inv_shoes()
	var/original = H.icon
	var/image/uniform = H.overlays_standing[UNIFORM_LAYER]
	var/image/boots = H.overlays_standing[SHOES_LAYER]
	var/boots_icon = boots.icon
	H.begin_walking_step()
	if(!H.walking_phase || H.icon == original || !H.walking_overlay_cache.len)
		failure += "A clothed human did not receive a procedural pose. "
	var/mutable_appearance/posed_boots = H.walking_overlay(boots)
	if(posed_boots.icon == boots_icon || posed_boots.color != boots.color || posed_boots.layer != boots.layer)
		failure += "Boots were not animated with their original appearance attributes. "
	if(H.walking_overlay(boots) != posed_boots)
		failure += "Repeated pose requests bypassed the cache. "
	var/image/nested = image('icons/mob/human_races/r_human.dmi', "l_foot_m")
	nested.color = "#ff8080"
	var/image/container = new
	container.overlays += nested
	var/mutable_appearance/posed_container = H.walking_overlay(container)
	var/mutable_appearance/posed_slice = posed_container.overlays[1]
	var/mutable_appearance/posed_child = posed_slice.overlays[1]
	if(!posed_container.overlays.len || posed_child.color != nested.color || posed_child.icon != nested.icon)
		failure += "Nested markings/accessories lost their source or color. "
	if(boots.icon != boots_icon || H.overlays_standing[UNIFORM_LAYER] != uniform)
		failure += "Standing equipment was mutated. "
	// Export a software preview of the precomputed masks on the game's actual
	// standing appearance. Native filter rendering is checked separately.
	for(var/body_gender in list(MALE, FEMALE))
		H.gender = body_gender
		H.regenerate_icons()
		H.stop_walking_animation()
		for(var/facing in list(SOUTH, NORTH, EAST, WEST))
			H.dir = facing
			var/icon/flat = getFlatIcon(H)
			for(var/phase in list(0, 1, -1))
				var/icon/preview = phase ? walking_test_icon(flat, phase) : flat
				fcopy(preview, "tmp/walking-animation/[body_gender]_[phase]_[facing].png")
	H.stop_walking_animation()
	if(!walking_matches_standing(H) || H.walking_phase)
		failure += "Stopping did not restore the current standing body. "
	H.begin_walking_step()
	var/list/old_cache = H.walking_overlay_cache
	H.update_icons()
	if(H.walking_overlay_cache == old_cache)
		failure += "Appearance changes did not invalidate cached poses. "
	qdel(H)
	if(failure) fail(failure)
	else pass("Body and boots animate, nested colors survive, cache is reused/invalidated, original overlays survive, male/female poses exported.")
	return TRUE

/datum/unit_test/walking_lifecycle
	name = "WALKING - Toggle, posture, relocation and idle reset"

/datum/unit_test/walking_lifecycle/start_test()
	var/mob/living/carbon/human/walking_test/H = walking_fixture()
	var/failure = ""
	var/startup_masks = SSwalking.generated_masks
	if(!SSwalking.initialized || startup_masks != 8 || SSwalking.poses.len != 16)
		failure += "Walking mask library was not fully prepared during initialization. "
	var/datum/client_preference/preference = get_client_preference(/datum/client_preference/walking_animation)
	if(!preference || preference.key != "HUMAN_WALKING_ANIMATION" || preference.default_value != GLOB.PREF_YES)
		failure += "Saved preference registration/default failed. "
	H.begin_walking_step()
	if(!H.walking_phase) failure += "Eligible human did not start. "
	H.test_walking_enabled = FALSE
	preference.changed(H, GLOB.PREF_NO)
	if(H.walking_phase || !walking_matches_standing(H)) failure += "Disabling did not immediately restore standing. "
	H.begin_walking_step()
	if(H.walking_phase) failure += "Disabled human animated. "
	H.test_walking_enabled = TRUE
	H.begin_walking_step()
	H.lying = TRUE
	H.update_icons()
	if(H.walking_phase) failure += "Prone human retained walking pose. "
	H.lying = FALSE
	H.resting = TRUE
	H.begin_walking_step()
	if(H.walking_phase) failure += "Resting human animated. "
	H.resting = FALSE
	H.is_floating = TRUE
	H.begin_walking_step()
	if(H.walking_phase) failure += "Floating human animated. "
	H.is_floating = FALSE
	H.stat = DEAD
	H.begin_walking_step()
	if(H.walking_phase) failure += "Dead human animated. "
	H.stat = CONSCIOUS
	H.begin_walking_step()
	H.forceMove(get_step(H, NORTH))
	if(H.walking_phase) failure += "Teleport retained walking pose. "
	H.begin_walking_step()
	var/first_phase = H.walking_phase
	H.begin_walking_step()
	if(H.walking_phase != -first_phase) failure += "Successive steps did not alternate. "
	sleep(8)
	if(H.walking_phase || !walking_matches_standing(H)) failure += "Idle timer failed to restore standing. "
	if(SSwalking.generated_masks != startup_masks) failure += "Sprites were generated after initialization. "
	qdel(H)
	if(failure) fail(failure)
	else pass("Startup library is complete and no sprites were generated at runtime. Saved toggle defaults on; off, prone, resting, floating, death, teleport and idle reset work; feet alternate.")
	return TRUE
