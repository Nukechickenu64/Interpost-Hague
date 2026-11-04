// Opt-in native renderer comparison. Never included by the production DME.
var/global/turf/openspace_preview_lower

/proc/build_openspace_preview()
	var/cx = world.maxx - 25
	var/cy = world.maxy - 25
	var/lower_z = world.maxz - 1
	if(z_levels.len < lower_z) z_levels.len = lower_z
	z_levels[lower_z] = TRUE
	SSzcopy.calculate_zstack_limits()
	var/area/artemis_preview/A = new
	for(var/deck in lower_z to world.maxz)
		for(var/turf/T in block(locate(cx - 9, cy - 9, deck), locate(cx + 9, cy + 9, deck)))
			for(var/obj/O in T) qdel(O)
			T = T.ChangeTurf(/turf/unsimulated/floor)
			A.contents += T
			T.dynamic_lighting = TRUE
			T.lighting_build_overlay()
	openspace_preview_lower = locate(cx, cy, lower_z)
	for(var/dy in -3 to 3)
		for(var/dx in -3 to 3)
			var/turf/T = locate(cx + dx, cy + dy, world.maxz)
			T.ChangeTurf(/turf/simulated/open)
	for(var/dx in -3 to 3)
		var/turf/T = locate(cx + dx, cy + 2, lower_z)
		T.ChangeTurf(/turf/unsimulated/wall)
	var/obj/lamp = new(locate(cx - 2, cy - 2, lower_z))
	lamp.set_light(10, 3, "#ffffff")
	var/obj/probe = new(openspace_preview_lower)
	probe.icon = get_solid_white_icon()
	probe.color = "#40b0ff"
	probe.anchored = TRUE
	probe.casts_dynamic_shadow = FALSE
	SSlighting.fire(FALSE, TRUE)
	for(var/i in 1 to 3) SSzcopy.fire(FALSE, TRUE)
	artemis_preview_origin = locate(cx, cy - 4, world.maxz)
	return artemis_preview_origin

/mob/living/carbon/human/artemis_preview/proc/preview_openspace_sequence()
	canmove = FALSE
	GLOB.cryo_startup_effect.stop()
	preview_suppress_grain()
	winset(src, "mainwindow", "title=Openspace-Render-Comparison")
	SSlighting.fire(FALSE, TRUE)
	SSlighting.can_fire = FALSE
	// Reproduce the old helper-copy behavior, then remove only those copies.
	for(var/turf/T in range(8, openspace_preview_lower))
		for(var/atom/movable/helper in T)
			if(istype(helper, /atom/movable/lighting_edge_guard) || istype(helper, /atom/movable/lighting_veil))
				helper.z_flags &= ~ZMM_IGNORE
		T.above?.update_mimic()
	for(var/i in 1 to 3) SSzcopy.fire(FALSE, TRUE)
	sleep(20)
	preview_snapshot("openspace-before-helper-exclusion")
	sleep(10)
	var/removed = 0
	for(var/turf/T in range(8, openspace_preview_lower))
		for(var/atom/movable/helper in T)
			if(istype(helper, /atom/movable/lighting_edge_guard) || istype(helper, /atom/movable/lighting_veil))
				helper.z_flags |= ZMM_IGNORE
				if(helper.bound_overlay) removed++
				QDEL_NULL(helper.bound_overlay)
		T.above?.update_mimic()
	for(var/i in 1 to 3) SSzcopy.fire(FALSE, TRUE)
	sleep(20)
	preview_snapshot("openspace-after-helper-exclusion")
	world.log << "OPENSPACE_RENDER complete removed_helpers=[removed]"
