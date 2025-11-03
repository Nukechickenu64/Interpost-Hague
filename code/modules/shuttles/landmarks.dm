//making this separate from /obj/effect/landmark until that mess can be dealt with
/obj/effect/shuttle_landmark
	name = "Nav Point"
	icon = 'icons/effects/effects.dmi'
	icon_state = "energynet"
	anchored = 1
	unacidable = 1
	simulated = 0
	invisibility = 101

	var/landmark_tag
	//ID of the controller on the dock side
	var/datum/computer/file/embedded_program/docking/docking_controller
	//ID of controller used for this landmark for shuttles with multiple ones.
	var/list/special_dock_targets

	//when the shuttle leaves this landmark, it will leave behind the base area
	//also used to determine if the shuttle can arrive here without obstruction
	var/area/base_area
	//Will also leave this type of turf behind if set.
	var/turf/base_turf
	//If set, will set base area and turf type to same as where it was spawned at
	var/autoset
	//Will be moved by the shuttle when it moves
	var/mobile
	//Name of the shuttle, null for generic waypoint
	var/shuttle_restricted

/obj/effect/shuttle_landmark/Initialize()
	. = ..()
	if(autoset)
		base_area = get_area(src)
		var/turf/T = get_turf(src)
		if(T)
			base_turf = T.type
	else
		base_area = locate(base_area || world.area)

	SetName(name + " ([x],[y])")

	if(docking_controller)
		var/docking_tag = docking_controller
		docking_controller = locate(docking_tag)
		if(!istype(docking_controller))
			log_error("Could not find docking controller for shuttle waypoint '[name]', docking tag was '[docking_tag]'.")
		if(GLOB.using_map.use_overmap)
			var/obj/effect/overmap/location = map_sectors["[z]"]
			if(location && location.docking_codes)
				docking_controller.docking_codes = location.docking_codes

	SSshuttle.register_landmark(landmark_tag, src)

/obj/effect/shuttle_landmark/forceMove()
	var/obj/effect/overmap/map_origin = map_sectors["[z]"]
	. = ..()
	var/obj/effect/overmap/map_destination = map_sectors["[z]"]
	if(map_origin != map_destination)
		if(map_origin)
			map_origin.remove_landmark(src, shuttle_restricted)
		if(map_destination)
			map_destination.add_landmark(src, shuttle_restricted)

//Called when the landmark is added to an overmap sector.
/obj/effect/shuttle_landmark/proc/sector_set(var/obj/effect/overmap/O)

/obj/effect/shuttle_landmark/proc/is_valid(var/datum/shuttle/shuttle)
	if(shuttle.current_location == src)
		// Already docked here; invalid as a destination
		log_debug("[type] '[name]' at ([x],[y],[z]) invalid for shuttle [shuttle ? shuttle.name : null]: already at this landmark")
		return FALSE
	for(var/area/A in shuttle.shuttle_area)
		var/list/translation = get_turf_translation(get_turf(shuttle.current_location), get_turf(src), A.contents)
		if(check_collision(translation))
			// Explain why and try to self-heal if possible
			if(analyze_and_attempt_fix(shuttle, A, translation))
				// Still invalid after attempting fix
				return FALSE
	return TRUE

/obj/effect/shuttle_landmark/proc/check_collision(var/list/turf_translation)
	for(var/source in turf_translation)
		var/turf/target = turf_translation[source]
		if(!target)
			return TRUE //collides with edge of map
		if(target.loc != base_area)
			return TRUE //collides with another area
		if(target.density)
			return TRUE //dense turf
	return FALSE

// Analyze a collision and try to repair the destination so the shuttle can land.
// Returns TRUE if the site is still invalid after repairs, FALSE if fixed.
/obj/effect/shuttle_landmark/proc/analyze_and_attempt_fix(var/datum/shuttle/shuttle, var/area/A, var/list/turf_translation)
	var/turf/from_origin = get_turf(shuttle.current_location)
	var/turf/dest_origin = get_turf(src)

	var/has_oob = FALSE
	var/has_wrong_area = FALSE
	var/has_dense = FALSE
	var/list/dense_targets = list()
	var/list/area_mismatch_targets = list()

	for(var/source in turf_translation)
		var/turf/target = turf_translation[source]
		if(!target)
			if(!has_oob)
				var/source_coords = "?"
				if(istype(source, /turf))
					var/turf/S = source
					source_coords = "[S.x],[S.y],[S.z]"
				log_debug("[type] '[name]' at ([x],[y],[z]): invalid for shuttle [shuttle ? shuttle.name : null]: target would be off map (source=[source_coords]) relative to dest=([dest_origin.x],[dest_origin.y],[dest_origin.z])")
			has_oob = TRUE
			continue
		if(target.loc != base_area)
			has_wrong_area = TRUE
			area_mismatch_targets += target
		if(target.density)
			has_dense = TRUE
			dense_targets += target

	if(has_wrong_area)
		var/turf/example_t = (area_mismatch_targets.len ? area_mismatch_targets[1] : null)
		if(example_t)
			log_debug("[type] '[name]' at ([x],[y],[z]): area mismatch: target ([example_t.x],[example_t.y],[example_t.z]) in area='[example_t.loc ? example_t.loc.name : null]' != base_area='[base_area ? base_area.name : null]'")
		else
			log_debug("[type] '[name]' at ([x],[y],[z]): area mismatch detected on one or more tiles (base_area='[base_area ? base_area.name : null]')")

	if(has_dense)
		log_debug("[type] '[name]' at ([x],[y],[z]): dense turf collision on [dense_targets.len] tile(s); attempting to clear to base turf")

	// 1) If off-map or area mismatch, try nudging the landmark around to a valid spot (ignoring density at first)
	if(has_oob || has_wrong_area)
		if(try_reposition_to_valid_footprint(from_origin, dest_origin, A))
			// recompute translation with new destination and recheck density separately
			dest_origin = get_turf(src)
			turf_translation = get_turf_translation(from_origin, dest_origin, A.contents)
			// refresh flags except density (we'll handle next)
			has_oob = FALSE
			has_wrong_area = FALSE
			for(var/source2 in turf_translation)
				var/turf/target2 = turf_translation[source2]
				if(!target2)
					has_oob = TRUE
					break
				if(target2.loc != base_area)
					has_wrong_area = TRUE
					break
		if(has_oob)
			log_debug("[type] '[name]': reposition failed: still off map after search")
		if(has_wrong_area)
			log_debug("[type] '[name]': reposition failed: still not fully within base_area '[base_area ? base_area.name : null]'")

	// 2) If dense turfs remain, try clearing them to a passable base turf
	if(!has_oob && !has_wrong_area && dense_targets.len)
		var/cleared = 0
		for(var/turf/T in dense_targets)
			if(T && T.density)
				var/new_type = get_base_turf_by_area(T)
				if(new_type)
					T.ChangeTurf(new_type)
					cleared++
		log_debug("[type] '[name]': cleared [cleared] dense turfs under footprint to base turf")

		// Re-evaluate collision
		dest_origin = get_turf(src)
		var/list/new_translation = get_turf_translation(from_origin, dest_origin, A.contents)
		if(check_collision(new_translation))
			log_debug("[type] '[name]': still colliding after dense turf clear; giving up for now")
			return TRUE
		return FALSE

	// If any remaining non-dense issues persist, still invalid
	if(has_oob || has_wrong_area)
		return TRUE

	// No remaining issues (or none detected beyond density which was absent)
	return FALSE

// Try to find a nearby landmark position so the shuttle footprint fits fully on-map and within base_area (ignoring density).
/obj/effect/shuttle_landmark/proc/try_reposition_to_valid_footprint(var/turf/from_origin, var/turf/dest_origin, var/area/A)
	if(!from_origin || !dest_origin)
		return FALSE

	// Search a small radius around current destination center for a spot fully within base_area and map bounds
	var/radius = 12
	for(var/dy = -radius, dy <= radius, dy++)
		for(var/dx = -radius, dx <= radius, dx++)
			var/nx = dest_origin.x + dx
			var/ny = dest_origin.y + dy
			if(nx < 1 || ny < 1 || nx > world.maxx || ny > world.maxy)
				continue
			var/turf/candidate = locate(nx, ny, dest_origin.z)
			if(!_footprint_within_area_and_bounds(from_origin, candidate, A))
				continue
			// Found a candidate; move the landmark here
			log_debug("[type] '[name]': repositioning landmark from ([dest_origin.x],[dest_origin.y]) to ([nx],[ny]) to satisfy area/bounds")
			forceMove(candidate)
			return TRUE

	return FALSE

// Check whether the shuttle footprint would be fully on-map and within base_area when centered on 'dest_center'. Ignores density.
/obj/effect/shuttle_landmark/proc/_footprint_within_area_and_bounds(var/turf/from_origin, var/turf/dest_center, var/area/A)
	if(!from_origin || !dest_center)
		return FALSE
	var/list/translation = get_turf_translation(from_origin, dest_center, A.contents)
	for(var/source in translation)
		var/turf/target = translation[source]
		if(!target)
			return FALSE
		if(target.loc != base_area)
			return FALSE
	return TRUE

//Self-naming/numbering ones.
/obj/effect/shuttle_landmark/automatic
	name = "Navpoint"
	landmark_tag = "navpoint"
	autoset = 1

/obj/effect/shuttle_landmark/automatic/Initialize()
	landmark_tag += "-[x]-[y]-[z]-[random_id("landmarks",1,9999)]"
	return ..()

/obj/effect/shuttle_landmark/automatic/sector_set(var/obj/effect/overmap/O)
	..()
	SetName("[O.name] - [initial(name)] ([x],[y])")

//Subtype that calls explosion on init to clear space for shuttles
/obj/effect/shuttle_landmark/automatic/clearing
	var/radius = 10

/obj/effect/shuttle_landmark/automatic/clearing/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/shuttle_landmark/automatic/clearing/LateInitialize()
	var/list/victims = circlerangeturfs(get_turf(src),radius)
	for(var/turf/T in victims)
		if(T.density)
			T.ChangeTurf(get_base_turf_by_area(T))

/obj/item/device/spaceflare
	name = "bluespace flare"
	desc = "Burst transmitter used to broadcast all needed information for shuttle navigation systems. Has a flare attached for marking the spot where you probably shouldn't be standing."
	icon_state = "bluflare"
	light_color = "#3728ff"
	var/active

/obj/item/device/spaceflare/attack_self(var/mob/user)
	if(!active)
		visible_message("<span class='notice'>[user] pulls the cord, activating the [src].</span>")
		activate()

/obj/item/device/spaceflare/proc/activate()
	if(active)
		return
	active = 1
	var/turf/T = get_turf(src)
	var/obj/effect/shuttle_landmark/automatic/mark = new(T)
	mark.SetName("Beacon signal ([T.x],[T.y])")
	if(ismob(loc))
		var/mob/M = loc
		M.drop_from_inventory(src,T)
	anchored = 1
	T.hotspot_expose(1500, 5)
	update_icon()

/obj/item/device/spaceflare/update_icon()
	if(active)
		icon_state = "bluflare_on"
		set_light(l_range = 6, l_power = 3)