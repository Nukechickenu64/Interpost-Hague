/datum/unit_test/lighting_multiz
	name = "ARTEMIS - Bidirectional light through open decks"

/datum/unit_test/lighting_multiz/start_test()
	var/cx = world.maxx - 25
	var/cy = world.maxy - 25
	var/lower_z = world.maxz - 2
	var/list/original_z_levels = z_levels.Copy()
	if(z_levels.len < world.maxz)
		z_levels.len = world.maxz
	z_levels[lower_z] = TRUE
	z_levels[lower_z + 1] = TRUE
	if(lower_z > 1) z_levels[lower_z - 1] = FALSE
	var/list/areas = list()
	for(var/deck in lower_z to world.maxz)
		for(var/turf/T in block(locate(cx - 9, cy - 9, deck), locate(cx + 9, cy + 9, deck)))
			for(var/obj/O in T)
				qdel(O)
			T = T.ChangeTurf(/turf/unsimulated/floor)
			var/area/A = get_area(T)
			if(!(A in areas)) areas[A] = A.dynamic_lighting
			A.dynamic_lighting = TRUE
			T.dynamic_lighting = TRUE
			T.set_opacity(FALSE)
			T.lighting_build_overlay()
	var/turf/lower = locate(cx, cy, lower_z)
	var/turf/middle = locate(cx, cy, lower_z + 1)
	var/turf/upper = locate(cx, cy, lower_z + 2)
	var/obj/lamp = new(lower)
	lamp.set_light(8, 4, "#20ff40")
	SSlighting.fire(FALSE, TRUE)
	if(middle in lamp.light.affecting_turfs)
		fail("A solid floor admitted light from below.")
	// Opening the FIRST aperture has no pre-existing cross-deck ray to watch it.
	for(var/turf/T in range(1, middle))
		T.ChangeTurf(/turf/simulated/open)
	middle = locate(cx, cy, lower_z + 1)
	SSlighting.fire(FALSE, TRUE)
	var/turf/middle_spill = locate(cx + 2, cy, middle.z)
	if(!(middle in lamp.light.affecting_turfs) || !(middle_spill in lamp.light.affecting_turfs) || middle_spill.get_lumcount() <= 0)
		fail("Opening a hole failed to spill light upward onto surrounding floor.")
	var/datum/lighting_corner/colored = middle_spill.corners[1]
	if(colored.lum_g <= colored.lum_r || colored.lum_g <= colored.lum_b)
		fail("Cross-deck light lost its source color.")
	for(var/turf/T in range(1, upper))
		T.ChangeTurf(/turf/simulated/open)
	upper = locate(cx, cy, lower_z + 2)
	SSlighting.fire(FALSE, TRUE)
	if(!(upper in lamp.light.affecting_turfs))
		fail("Light did not travel through two consecutive open decks.")
	var/datum/lighting_corner/near_corner = middle.corners[1]
	var/datum/lighting_corner/far_corner = upper.corners[1]
	if(near_corner.lum_g <= far_corner.lum_g || far_corner.lum_g <= 0)
		fail("Light did not fade with vertical distance.")
	// The hole displays the lighting of the visible floor, including its lamp.
	var/list/lower_rgb = lighting_tile_rgb(lower)
	var/list/upper_rgb = lighting_tile_rgb(upper)
	if(abs(lower_rgb[2] - upper_rgb[2]) > 0.0001 || abs(upper.lighting_overlay.lum_g - lower_rgb[2]) > 0.0001)
		fail("An open shaft did not display the visible bottom floor's lightmap.")
	// A blocker in the shaft must update both closing AND reopening visibility.
	var/obj/blocker = new(middle)
	blocker.set_opacity(TRUE)
	SSlighting.fire(FALSE, TRUE)
	if(upper in lamp.light.affecting_turfs)
		fail("An opaque shaft blocker leaked light upward.")
	blocker.set_opacity(FALSE)
	SSlighting.fire(FALSE, TRUE)
	if(!(upper in lamp.light.affecting_turfs))
		fail("Removing a shaft blocker did not restore upward light.")
	qdel(blocker)
	// Close a transparent hole: opacity does not change, but light passage does.
	middle = middle.ChangeTurf(/turf/unsimulated/floor)
	SSlighting.fire(FALSE, TRUE)
	if((middle in lamp.light.affecting_turfs) || (upper in lamp.light.affecting_turfs))
		fail("Closing a hole retained light through its solid floor.")
	middle = middle.ChangeTurf(/turf/simulated/open)
	SSlighting.fire(FALSE, TRUE)
	// Reverse the source. Light must spread below the aperture, not just copy its column.
	lamp.forceMove(get_step(upper, WEST))
	SSlighting.fire(FALSE, TRUE)
	var/turf/lower_spill = locate(cx + 2, cy, lower_z)
	if(!(lower_spill in lamp.light.affecting_turfs) || lower_spill.get_lumcount() <= 0)
		fail("Upper-deck light did not spread across the lower floor.")
	// A receiving-deck wall blocks that spill and remains watched when closed.
	var/turf/doorway = locate(cx + 1, cy, lower_z)
	doorway.set_opacity(TRUE)
	SSlighting.fire(FALSE, TRUE)
	if(lower_spill in lamp.light.affecting_turfs)
		fail("Downward spill passed through a wall on the receiving deck.")
	doorway.set_opacity(FALSE)
	SSlighting.fire(FALSE, TRUE)
	if(!(lower_spill in lamp.light.affecting_turfs))
		fail("Opening a receiving-deck door did not restore light.")
	// Aiming-only updates must retain the vertical attenuation.
	lamp.set_light_cone(60, 90, 0, cx + 3, cy)
	SSlighting.fire(FALSE, TRUE)
	var/datum/lighting_corner/sample = lower_spill.corners[1]
	var/aimed_strength = lamp.light.effect_str[sample]
	lamp.light.force_update()
	SSlighting.fire(FALSE, TRUE)
	if(abs(aimed_strength - lamp.light.effect_str[sample]) > 0.0001)
		fail("A full rebuild and an aiming update disagree on cross-deck falloff.")
	// Every ray must respect deck connectivity, even with open tiles in both maps.
	z_levels[lower_z] = FALSE
	lamp.light.force_update()
	SSlighting.fire(FALSE, TRUE)
	if(lower_spill in lamp.light.affecting_turfs)
		fail("Light crossed disconnected map decks.")
	z_levels[lower_z] = TRUE
	lamp.set_light_cone(0, 0, 0)
	lamp.light.force_update()
	SSlighting.fire(FALSE, TRUE)
	var/list/watched = lamp.light.visibility_turfs.Copy()
	var/datum/light_source/source = lamp.light
	lamp.set_light(0)
	SSlighting.fire(FALSE, TRUE)
	if(lower_spill.get_lumcount() > 0.001 || upper.lighting_overlay.lum_g > 0.001)
		fail("Switching off a cross-deck light left residual illumination.")
	for(var/turf/T in watched)
		if(source in T.lighting_visibility_sources)
			fail("A removed cross-deck source retained visibility subscriptions.")
	// Exercise the actual Z-copy queue, not just the lightmap's RGB function.
	// A lower wall's 3x3 black padding used to be copied above the visible floor.
	var/turf/render_lower = locate(cx + 5, cy + 5, lower_z)
	var/turf/render_upper = locate(cx + 5, cy + 5, lower_z + 1)
	for(var/turf/T in range(1, render_upper))
		T.ChangeTurf(/turf/simulated/open)
	render_upper = locate(cx + 5, cy + 5, lower_z + 1)
	var/turf/render_wall = get_step(render_lower, NORTH)
	render_wall.set_opacity(TRUE)
	var/obj/render_lamp = new(render_lower)
	render_lamp.set_light(6, 2)
	var/obj/scenery = new(render_lower)
	scenery.icon = 'icons/obj/storage.dmi'
	scenery.icon_state = "crate"
	scenery.anchored = TRUE
	SSlighting.fire(FALSE, TRUE)
	render_upper.update_mimic()
	for(var/i in 1 to 3) SSzcopy.fire(FALSE, TRUE)
	var/atom/movable/lighting_edge_guard/padding = render_wall.lighting_overlay.edge_guard
	var/atom/movable/lighting_veil/glow = render_lower.lighting_overlay.tile_glow
	if(!padding || !glow)
		fail("The openspace rendering fixture did not create its padding and glow sources.")
	if(padding?.bound_overlay || glow?.bound_overlay || render_lower.lighting_overlay.bound_overlay)
		fail("Openspace copied a lower-deck lightmap, black boundary mask or glow buffer into scenery.")
	if(!scenery.bound_overlay || scenery.bound_overlay.loc != render_upper || scenery.bound_overlay.icon != scenery.icon)
		fail("Excluding renderer helpers also removed a visible lower-deck object.")
	qdel(scenery)
	var/turf/render_top = GetAbove(render_upper)
	render_top = render_top.ChangeTurf(/turf/simulated/open)
	var/turf/upper_wall = get_step(render_upper, NORTH)
	upper_wall.set_opacity(TRUE)
	SSlighting.fire(FALSE, TRUE)
	if(!render_upper.lighting_overlay?.tile_glow || !render_top.lighting_overlay?.tile_glow)
		fail("The test shaft must start above a floor that produces glow.")
	render_lower = render_lower.ChangeTurf(/turf/space)
	if(!istype(render_lower, /turf/space) || render_lower.above != render_upper || render_upper.below != render_lower)
		fail("Replacing the lower floor with space broke the shaft's Z-mimic link.")
	SSlighting.fire(FALSE, TRUE)
	for(var/turf/opening in list(render_upper, render_top))
		var/atom/movable/lighting_overlay/lightmap = opening.lighting_overlay
		if(!lightmap || !lightmap.luminosity || lightmap.alpha || lightmap.tile_glow)
			fail("An opening over space lost visibility or added a sample to bloom or veil.")
	// The upper wall's southern edge padding would otherwise darken the uncovered opening.
	if(text2num(upper_wall.lighting_overlay.edge_guard_key) & (1 << 1))
		fail("Wall padding covered a fullbright opening over space.")
	render_lower.ChangeTurf(/turf/simulated/floor/airless)
	render_lamp.light.force_update()
	SSlighting.fire(FALSE, TRUE)
	for(var/turf/opening in list(render_upper, render_top))
		if(!opening.lighting_overlay?.alpha || !opening.lighting_overlay?.tile_glow)
			fail("Replacing space with a lit floor did not restore the shaft's lighting passes.")
	qdel(render_lamp)
	SSlighting.fire(FALSE, TRUE)
	qdel(lamp)
	// Restore connectivity and area settings; the fixture is outside the playable map.
	z_levels = original_z_levels
	for(var/area/A in areas)
		A.dynamic_lighting = areas[A]
	if(!reported) pass("Cross-deck lighting, Z-copy scenery, and fullbright openings without bloom or veil verified.")
	return TRUE
