// Included only by lighting_los_regression.dme.
/datum/unit_test/lighting_los_drop_shadow
	name = "ARTEMIS - Projected silhouettes follow actual light"

/datum/unit_test/lighting_los_drop_shadow/start_test()
	var/turf/C = lighting_los_fixture()
	var/area/A = get_area(C)
	var/was_dynamic = A.dynamic_lighting
	A.dynamic_lighting = TRUE
	for(var/turf/T in range(9, C))
		T.lighting_build_overlay()
	var/obj/actor = new(C)
	actor.icon = 'icons/obj/storage.dmi'
	actor.icon_state = "crate"
	actor.casts_dynamic_shadow = TRUE
	actor.density = TRUE
	var/obj/east = new(locate(C.x + 3, C.y + 1, C.z))
	var/obj/west = new(locate(C.x - 3, C.y + 1, C.z))
	east.set_light(8, 4, "#ffffff")
	west.set_light(8, 2, "#ffffff")
	SSlighting.fire(FALSE, TRUE)
	actor.update_dynamic_shadow()
	var/atom/movable/dynamic_shadow/E = actor.dynamic_shadows?[east.light]
	var/atom/movable/dynamic_shadow/W = actor.dynamic_shadows?[west.light]
	if(!E || !W)
		fail("Lit raised object did not receive both projected silhouettes.")
	else
		if(E.target_projection.b >= 0 || W.target_projection.b <= 0 || E.target_projection.e >= 0 || W.target_projection.e >= 0)
			fail("Silhouettes did not project away from their lamp, anchored at the feet.")
		if(E.density || E.opacity || E.mouse_opacity)
			fail("A silhouette copied its owner's collision or interaction behavior.")
		if(E.animate_movement != SYNC_STEPS || ((E.appearance_flags & LONG_GLIDE) != (actor.appearance_flags & LONG_GLIDE)))
			fail("Silhouette glide settings diverged from its owner.")
		var/revision = E.projection_revision
		actor.update_dynamic_shadow()
		if(E.projection_revision != revision)
			fail("Stationary refresh restarted an unchanged projection.")
		west.set_light(8, 6)
		east.set_light(8, 2)
		SSlighting.fire(FALSE, TRUE)
		actor.update_dynamic_shadow()
		if(actor.dynamic_shadows[east.light] != E || actor.dynamic_shadows[west.light] != W)
			fail("Light rank change reassigned silhouettes to different emitters.")
		var/icon/asymmetric = icon(get_solid_white_icon())
		asymmetric.Blend("#00000000", ICON_MULTIPLY)
		asymmetric.DrawBox("#ffffff", 21, 9, 28, 16)
		east.icon = asymmetric
		east.pixel_x = 15
		var/list/center = east.light.dynamic_shadow_center()
		if(abs(center[1] - east.x - 23 / 32) > 0.001 || abs(center[2] - east.y + 4 / 32) > 0.001)
			fail("Light origin did not use the opaque sprite centroid and pixel offset.")
		east.pixel_x = 16
		var/list/shifted = east.light.dynamic_shadow_center()
		if(abs(shifted[1] - center[1] - 1 / 32) > 0.001)
			fail("Moving a lamp one pixel across the half-tile boundary snapped its shadow origin.")
		east.transform = matrix(1, 0, 3, 0, 1, -2)
		center = east.light.dynamic_shadow_center()
		if(abs(center[1] - shifted[1] - 3 / 32) > 0.001 || abs(center[2] - shifted[2] + 2 / 32) > 0.001)
			fail("Transformed light fixture did not move its visual shadow origin.")
		actor.maptext = "This must not cast a shadow"
		var/mutable_appearance/glow = mutable_appearance(actor.icon, actor.icon_state)
		glow.plane = EMISSIVE_PLANE
		actor.overlays += glow
		actor.update_dynamic_shadow()
		if(E.maptext || E.overlays.len || E.underlays.len || E.plane != DEFAULT_PLANE || E.layer != MOB_SHADOW_LAYER)
			fail("Projected copy included text or emission, or escaped the floor layer.")
		east.set_light(8, 2, "#000000")
		SSlighting.fire(FALSE, TRUE)
		actor.update_dynamic_shadow()
		if(actor.dynamic_shadows[east.light] || actor.dynamic_shadows[west.light] != W)
			fail("Zero-RGB emitter cast a shadow or removed the other emitter's shadow.")
		actor.forceMove(west)
		if(actor.dynamic_shadows || !QDELETED(W))
			fail("Entering a container left a floor silhouette behind.")
	actor.forceMove(C)
	east.set_light(0)
	west.set_light(0)
	SSlighting.fire(FALSE, TRUE)
	actor.update_dynamic_shadow()
	if(actor.dynamic_shadows)
		fail("Turning off the lights left a projected silhouette.")
	var/obj/machinery/floor_light/os13/flush_lamp = new(C)
	if(flush_lamp.casts_dynamic_shadow)
		fail("Flush floor lamp casts a raised silhouette.")
	var/image/ao = make_ao_image(0, 1)
	if(ao.layer >= DECAL_LAYER || ao.layer >= OBJ_LAYER || ao.layer >= MOB_LAYER || ao.plane != FLOAT_PLANE || !(ao.appearance_flags & KEEP_APART))
		fail("Ambient occlusion can sort above ground objects or join a raised parent's draw group.")
	qdel(flush_lamp)
	qdel(actor)
	qdel(east)
	qdel(west)
	A.dynamic_lighting = was_dynamic
	if(!reported) pass("Lamp direction, stable refresh and source identity, spectrum, exclusions and cleanup verified.")
	return TRUE

/datum/unit_test/proc/lighting_los_fixture()
	var/turf/center = locate(world.maxx - 25, world.maxy - 25, world.maxz)
	for(var/turf/T in range(18, center))
		for(var/obj/O in T)
			if(!istype(O, /atom/movable/lighting_overlay))
				qdel(O)
		T = T.ChangeTurf(/turf/unsimulated/floor)
		T.set_opacity(FALSE)
	return locate(center.x, center.y, center.z)

// Triangle icon vertices are (-16,16), (-16,-16), (16,-16).
/proc/lighting_los_triangle_covers(list/shadows, px, py)
	for(var/atom/movable/triangle/triangle in shadows)
		var/matrix/M = triangle.transform
		var/determinant = M.a * M.e - M.b * M.d
		if(!determinant)
			continue
		var/u = ((px - M.c) * M.e - (py - M.f) * M.b) / determinant
		var/v = ((py - M.f) * M.a - (px - M.c) * M.d) / determinant
		if(u >= -16 && v >= -16 && u + v <= 0)
			return TRUE
	return FALSE

/datum/unit_test/lighting_los_geometry
	name = "ARTEMIS - Cardinal and diagonal shadow projection"

/datum/unit_test/lighting_los_geometry/start_test()
	var/turf/C = lighting_los_fixture()
	for(var/list/offset in list(list(3, 0), list(-3, 0), list(0, 3), list(0, -3), list(9, 9), list(-9, 9), list(9, -9), list(-9, -9)))
		var/turf/W = locate(C.x + offset[1], C.y + offset[2], C.z)
		W.set_opacity(TRUE)
		C.update_shadowcasting_overlays(16)
		var/px = offset[1] * 32 * 1.5
		var/py = offset[2] * 32 * 1.5
		if(!lighting_los_triangle_covers(C.shadowcasting_overlays, px, py))
			fail("Shadow did not extend behind blocker ([offset[1]], [offset[2]]) in an enlarged view.")
		if(lighting_los_triangle_covers(C.shadowcasting_overlays, -px, -py))
			fail("Shadow crossed the viewer into the unobstructed side.")
		W.set_opacity(FALSE)
	C.update_shadowcasting_overlays(7)
	if(C.shadowcasting_range != 7 || C.shadowcasting_occluders.len)
		fail("Viewport shrink retained stale geometry or occluders.")
	if(!reported) pass("All eight directions, distant diagonal corners, and viewport shrink verified.")
	return TRUE

/datum/unit_test/lighting_los_door
	name = "ARTEMIS - Door and moving blocker invalidation"

/datum/unit_test/lighting_los_door/start_test()
	var/turf/C = lighting_los_fixture()
	var/turf/D = locate(C.x + 3, C.y, C.z)
	var/obj/door = new(D)
	door.set_opacity(TRUE)
	C.update_shadowcasting_overlays(10)
	if(!lighting_los_triangle_covers(C.shadowcasting_overlays, 6 * 32, 0))
		fail("Closed opaque door failed to cast a shadow.")
	door.set_opacity(FALSE)
	shadowcast_process_invalidations()
	if(C.shadowcasting_initialized)
		fail("Opening the door did not invalidate the stationary viewer's cache.")
	C.update_shadowcasting_overlays(10)
	if(lighting_los_triangle_covers(C.shadowcasting_overlays, 6 * 32, 0))
		fail("Open door retained its shadow.")
	door.set_opacity(TRUE)
	door.forceMove(locate(C.x, C.y + 3, C.z))
	shadowcast_process_invalidations()
	C.update_shadowcasting_overlays(10)
	if(lighting_los_triangle_covers(C.shadowcasting_overlays, 6 * 32, 0) || !lighting_los_triangle_covers(C.shadowcasting_overlays, 0, 6 * 32))
		fail("Moving an opaque object left stale or missing shadows.")
	qdel(door)
	var/turf/W = get_step(C, EAST)
	var/turf/back = get_step(W, EAST)
	var/obj/mount = new(back)
	mount.pixel_x = -16
	var/list/visible = list()
	visible[C] = TRUE
	visible[W] = TRUE
	var/list/hidden = los_hidden_wall_mounts(visible, list(W))
	if(!hidden[mount])
		fail("An unseen offset fixture was allowed to overlap a visible wall.")
	mount.pixel_x = 0
	hidden = los_hidden_wall_mounts(visible, list(W))
	if(hidden[mount]) fail("Removing the offset left the fixture hidden.")
	mount.pixel_x = 16
	mount.forceMove(C)
	hidden = los_hidden_wall_mounts(visible, list(W))
	if(hidden[mount]) fail("A fixture on the visible side of a wall was hidden.")
	var/atom/movable/los_occluder/mask = make_los_occluder(1, 0)
	var/icon/mask_icon = icon(mask.icon)
	if(mask_icon.GetPixel(1, 16) != "#ffffff" || mask_icon.GetPixel(32, 16) != "#ffffff")
		fail("Visible wall coverage contains a rectangular cutout.")
	qdel(mount)
	if(!reported) pass("Opening, closing, and relocating opacity rebuild the view geometry.")
	return TRUE

/datum/unit_test/lighting_los_light
	name = "ARTEMIS - Colored light falloff and door occlusion"

/datum/unit_test/lighting_los_light/start_test()
	var/turf/C = lighting_los_fixture()
	var/area/A = get_area(C)
	var/old_dynamic = A.dynamic_lighting
	A.dynamic_lighting = TRUE
	for(var/turf/T in range(9, C))
		T.dynamic_lighting = TRUE
		T.lighting_build_overlay()
	for(var/dy in -9 to 9)
		var/turf/W = locate(C.x + 2, C.y + dy, C.z)
		W.set_opacity(TRUE)
	var/obj/lamp = new(C)
	lamp.set_light(8, 4, "#20ff40")
	SSlighting.fire(FALSE, TRUE)
	var/turf/near = locate(C.x - 1, C.y, C.z)
	var/turf/far = locate(C.x - 5, C.y, C.z)
	var/turf/behind = locate(C.x + 4, C.y, C.z)
	if(near.get_lumcount() <= far.get_lumcount() || far.get_lumcount() <= 0)
		fail("Local light did not decrease with distance.")
	if(behind in lamp.light.affecting_turfs)
		fail("Light crossed a sealed opaque wall.")
	var/datum/lighting_corner/corner = near.corners[1]
	if(corner.cache_g <= corner.cache_r || corner.cache_g <= corner.cache_b)
		fail("Green emission lost its dominant color.")
	var/atom/movable/lighting_overlay/tile_light = near.lighting_overlay
	var/icon/tile_icon = icon(tile_light.icon)
	if(tile_icon.GetPixel(1, 1) != "#ffffff" || tile_icon.GetPixel(16, 16) != "#ffffff" || tile_icon.GetPixel(32, 32) != "#ffffff")
		fail("Tile lighting still uses a corner-gradient texture.")
	var/list/tile_rgb = list(0, 0, 0)
	for(var/datum/lighting_corner/sample in near.corners)
		tile_rgb[1] += sample.lum_r / 4
		tile_rgb[2] += sample.lum_g / 4
		tile_rgb[3] += sample.lum_b / 4
	tile_rgb = lighting_display_rgb(tile_rgb[1], tile_rgb[2], tile_rgb[3])
	if(abs(tile_light.lum_r - tile_rgb[1]) > 0.0001 || abs(tile_light.lum_g - tile_rgb[2]) > 0.0001 || abs(tile_light.lum_b - tile_rgb[3]) > 0.0001)
		fail("Tile illumination did not use one exposed RGB sample for the whole tile.")
	var/turf/doorway = locate(C.x + 2, C.y, C.z)
	var/atom/movable/lighting_overlay/wall_light = doorway.lighting_overlay
	if(!wall_light.edge_guard)
		fail("Opaque lighting boundary has no padding against the white backdrop.")
	else
		var/atom/movable/lighting_edge_guard/guard = wall_light.edge_guard
		var/icon/padding = icon(guard.icon)
		if(padding.GetPixel(1, 1) != "#000000" || padding.GetPixel(96, 96) != "#000000")
			fail("Opaque boundary padding does not cover the filter's outside samples.")
	var/turf/fullbright = get_step(doorway, EAST)
	fullbright.dynamic_lighting = FALSE
	fullbright.lighting_clear_overlay()
	if(wall_light.edge_guard)
		var/atom/movable/lighting_edge_guard/guard = wall_light.edge_guard
		var/icon/padding = icon(guard.icon)
		if(padding.GetPixel(80, 48))
			fail("Boundary padding darkened an intentionally fullbright neighbor.")
	fullbright.dynamic_lighting = TRUE
	fullbright.lighting_build_overlay()
	if(tile_light.blend_mode != BLEND_OVERLAY)
		fail("Visible tile samples multiply against boundary padding instead of replacing it.")
	doorway.set_opacity(FALSE)
	if(wall_light.edge_guard)
		fail("Opening an opaque boundary retained its lightmap padding.")
	SSlighting.fire(FALSE, TRUE)
	if(!(behind in lamp.light.affecting_turfs))
		fail("Opening a doorway failed to admit the lamp's light.")
	if(!tile_light.tile_glow || tile_light.tile_glow.plane != LIGHTING_VEIL_SOURCE_PLANE)
		fail("Lit tiles did not supply the isolated optical glow source.")
	lamp.set_light(0)
	SSlighting.fire(FALSE, TRUE)
	if(near.get_lumcount() > 0.001)
		fail("Switching the lamp off left residual illumination.")
	if(tile_light.lum_r || tile_light.lum_g || tile_light.lum_b)
		fail("Unlit floor retained a nonblack tile light.")
	if(tile_light.tile_glow)
		var/icon/glow = icon(tile_light.tile_glow.icon)
		if(islist(tile_light.tile_glow.color))
			glow.MapColors(arglist(tile_light.tile_glow.color))
		else
			glow.Blend(tile_light.tile_glow.color, ICON_MULTIPLY)
		if(glow.GetPixel(16, 16) != "#000000")
			fail("Switching the lamp off retained additive tile glow.")
	var/atom/movable/lighting_veil/retired_glow = tile_light.tile_glow
	near.lighting_clear_overlay()
	if(retired_glow && !QDELETED(retired_glow))
		fail("Removing the tile lightmap left its glow source behind.")
	// A thick room corner has one exposed sample and three buried samples.
	// Buried geometry must not dilute its light; an exposed zero still counts.
	var/turf/corner_wall = locate(C.x - 7, C.y - 7, C.z)
	for(var/turf/T in range(1, corner_wall))
		T.set_opacity(TRUE)
	var/turf/open_corner = get_step(corner_wall, SOUTHWEST)
	open_corner.set_opacity(FALSE)
	var/list/saved = list()
	for(var/datum/lighting_corner/sample in corner_wall.corners)
		saved[sample] = list(sample.lum_r, sample.lum_g, sample.lum_b)
		sample.lum_r = sample.lum_g = sample.lum_b = sample.masters[open_corner] ? 0.4 : 0
	var/list/corner_rgb = lighting_tile_rgb(corner_wall)
	var/list/expected = lighting_display_rgb(0.4, 0.4, 0.4)
	if(abs(corner_rgb[1] - expected[1]) > 0.0001)
		fail("Buried wall samples diluted the exposed corner's illumination.")
	get_step(corner_wall, SOUTHEAST).set_opacity(FALSE)
	corner_rgb = lighting_tile_rgb(corner_wall)
	expected = lighting_display_rgb(0.2, 0.2, 0.2)
	if(abs(corner_rgb[1] - expected[1]) > 0.0001)
		fail("An exposed unlit sample was excluded from wall illumination.")
	for(var/datum/lighting_corner/sample in saved)
		var/list/old = saved[sample]
		sample.lum_r = old[1]
		sample.lum_g = old[2]
		sample.lum_b = old[3]
	qdel(lamp)
	A.dynamic_lighting = old_dynamic
	if(!reported) pass("Falloff, green tint, opaque walls, open doors and complete light removal verified.")
	return TRUE

/datum/unit_test/lighting_los_look_far
	name = "ARTEMIS - Shifted camera retains body line of sight"

/datum/unit_test/lighting_los_look_far/start_test()
	var/turf/C = lighting_los_fixture()
	var/mob/viewer = new(C)
	viewer.see_in_dark = 20
	var/turf/eye_turf = locate(C.x + 4, C.y, C.z)
	var/turf/wall = locate(C.x + 2, C.y + 1, C.z)
	wall.set_opacity(TRUE)
	var/list/visible = view(7, viewer)
	var/list/strips = get_los_cull_strips(eye_turf, 7, viewer, TRUE)
	var/hidden_count = 0
	for(var/dy in -7 to 7)
		for(var/dx in -7 to 7)
			var/turf/T = locate(eye_turf.x + dx, eye_turf.y + dy, eye_turf.z)
			var/hidden = FALSE
			for(var/atom/movable/los_strip/strip in strips)
				var/icon/strip_icon = icon(strip.icon)
				if(strip.pixel_y == dy * 32 && dx * 32 >= strip.pixel_x && dx * 32 < strip.pixel_x + strip_icon.Width())
					hidden = TRUE
			if(hidden) hidden_count++
			if(hidden != !(T in visible) && !T.opacity)
				fail("Camera offset changed body visibility at ([dx], [dy]).")
	if(!hidden_count) fail("Fixture did not exercise a concealed tile.")
	qdel(viewer)
	if(!reported) pass("Every viewport tile was compared with visibility from the character's body.")
	return TRUE

/datum/unit_test/lighting_los_mesh
	name = "ARTEMIS - Continuous mesh motion and viewer isolation"

/datum/unit_test/lighting_los_mesh/start_test()
	if(los_edge_crossing(NORTH, -96, 0, -64, 32) != 0.5 || los_edge_crossing(WEST, 0, -96, -32, -64) != 0.5 || !isnull(los_edge_crossing(SOUTH, -96, -80, -64, -48)))
		fail("Wall-edge crossings were not split at their physical crossing time.")
	// An interpolated vertex must lie on the exact ray for the interpolated eye,
	// rather than fading between two different opaque silhouettes.
	for(var/direction in GLOB.cardinal)
		var/list/start = los_edge_matrices(direction, -96, -80, 36)
		var/list/finish = los_edge_matrices(direction, -64, -48, 36)
		for(var/fraction in list(0.125, 0.25, 0.5, 0.75, 0.875))
			var/list/between = los_edge_matrices(direction, -96 + 32 * fraction, -80 + 32 * fraction, 36)
			for(var/i in 1 to 2)
				var/matrix/A = start[i]
				var/matrix/B = finish[i]
				var/matrix/M = between[i]
				if(abs(M.a - (A.a + (B.a - A.a) * fraction)) > 0.001 || abs(M.b - (A.b + (B.b - A.b) * fraction)) > 0.001 || abs(M.c - (A.c + (B.c - A.c) * fraction)) > 0.001 || abs(M.d - (A.d + (B.d - A.d) * fraction)) > 0.001 || abs(M.e - (A.e + (B.e - A.e) * fraction)) > 0.001 || abs(M.f - (A.f + (B.f - A.f) * fraction)) > 0.001)
					fail("Interpolated edge vertices left the viewer's rays.")
	var/turf/C = lighting_los_fixture()
	var/datum/los_edge_mesh/first_viewer = new(C, WEST)
	var/datum/los_edge_mesh/second_viewer = new(C, WEST)
	first_viewer.reshape(C.x - 3, C.y, 36)
	second_viewer.reshape(C.x - 3, C.y, 36)
	var/image/first = first_viewer.triangles[1]
	var/image/second = second_viewer.triangles[1]
	var/matrix/original = second.transform
	first_viewer.reshape(C.x - 2, C.y + 1, 36, 2)
	var/revision = first_viewer.shape_revision
	if(first_viewer.reshape(C.x - 2, C.y + 1, 36) || first_viewer.shape_revision != revision)
		fail("A stationary refresh restarted or snapped an in-flight mesh.")
	var/matrix/untouched = second.transform
	if(first == second || untouched.c != original.c || untouched.f != original.f || first.alpha != 255)
		fail("Animating a viewer changed another viewer's mesh or faded the shadow.")
	qdel(first_viewer)
	qdel(second_viewer)
	var/datum/los_motion/motion = new
	motion.reset(10, 10, 0)
	motion.begin(10, 10, 11, 11, 8, 0.5, TRUE, 0)
	var/list/halfway = motion.position(1)
	if(motion.ends != 2 || halfway[1] != 10.5 || halfway[2] != 10.5)
		fail("Diagonal LONG_GLIDE did not share the character's pixel speed.")
	// A second movement starts at the interpolated eye; stationary rebuilds
	// sample the existing journey and must not extend its deadline.
	motion.begin(11, 11, 12, 11, 8, 0.5, TRUE, 1)
	var/list/restarted = motion.position(1)
	if(restarted[1] != halfway[1] || restarted[2] != halfway[2] || motion.ends != 4)
		fail("Starting another step snapped the eye to the previous target tile.")
	var/deadline = motion.ends
	motion.position(2)
	var/list/stopped = motion.position(20)
	if(motion.ends != deadline || stopped[1] != 12 || stopped[2] != 11)
		fail("Stopping or refreshing the journey moved its endpoint or deadline.")
	motion.reset(30, 30, 21)
	var/list/teleported = motion.position(21)
	if(teleported[1] != 30 || teleported[2] != 30 || motion.ends != 21)
		fail("Teleport retained an old LOS journey.")
	qdel(motion)
	if(!reported) pass("Intermediate rays match linear matrix interpolation; viewers have independent opaque meshes.")
	return TRUE

/datum/unit_test/lighting_los_response
	name = "ARTEMIS - Exposure spectrum and smooth light boundary"

/datum/unit_test/lighting_los_response/start_test()
	var/list/black = lighting_display_rgb(0, 0, 0)
	var/list/negative = lighting_display_rgb(-1, -0.01, -10)
	var/list/white = lighting_display_rgb(1.5, 1.5, 1.5)
	var/list/weak = lighting_display_rgb(0.001, 0.001, 0.001)
	if(black[1] || black[2] || black[3] || negative[1] || negative[2] || negative[3])
		fail("The exposure curve added an ambient glow to zero or negative light.")
	if(white[1] < 0.85 || white[1] > 1 || white[1] != white[2] || white[2] != white[3])
		fail("A strong white lamp failed to produce a bright neutral highlight.")
	if(weak[1] >= 0.01)
		fail("Very weak spill was lifted into gray haze.")
	var/previous = 0
	for(var/intensity in list(0.01, 0.05, 0.1, 0.5, 1, 2, 4, 8))
		var/list/green = lighting_display_rgb(intensity * 0.125, intensity, intensity * 0.25)
		if(green[2] < previous || green[2] > 1 || green[1] / green[2] > 0.25 || green[3] / green[2] > 0.4)
			fail("Colored illumination washed out, clipped, or fell as intensity increased.")
		previous = green[2]
	if(lighting_radial_falloff(8, 0, 8) || lighting_radial_falloff(20, 0, 8))
		fail("A finite-radius lamp leaked past its range.")
	if(abs(lighting_radial_falloff(3, 4, 8) - lighting_radial_falloff(0, 5, 8)) > 0.0001)
		fail("Circular falloff changed with direction.")
	if(lighting_radial_falloff(7.9, 0, 8) >= 0.001)
		fail("The lamp edge has a visible discontinuity.")
	if(!reported) pass("Bright neutral highlights, saturated colors, black unlit space and a smooth finite boundary verified.")
	return TRUE

/datum/unit_test/lighting_los_emission
	name = "ARTEMIS - Floor lamp bloom follows power and damage"

/datum/unit_test/lighting_los_emission/start_test()
	var/turf/C = lighting_los_fixture()
	var/obj/machinery/floor_light/os13/lamp = new(C)
	lamp.stat &= ~(BROKEN|NOPOWER)
	lamp.on = TRUE
	lamp.update_brightness()
	if(!lamp.emissive_overlay || lamp.emissive_overlay.plane != EMISSIVE_PLANE || lamp.emissive_overlay.icon_state != "floorlight2" || lamp.emissive_overlay.blend_mode != BLEND_ADD || !lamp.light_range)
		fail("The lit recessed lamp did not emit its lens-only bloom texture.")
	// Render actual authored lens pixels through the tint, not just the stored
	// color value: the old amber texture multiplied by blue was nearly black.
	for(var/lamp_color in list("#ffffff", "#0000ff"))
		lamp.default_light_colour = lamp_color
		lamp.update_brightness()
		var/icon/lens = icon(lamp.emissive_overlay.icon, lamp.emissive_overlay.icon_state)
		lens.MapColors(arglist(lamp.emissive_overlay.color))
		var/brightest = 0
		for(var/x in 1 to lens.Width())
			for(var/y in 1 to lens.Height())
				var/pixel = lens.GetPixel(x, y)
				if(!pixel) continue
				var/list/rgb = ReadRGB(pixel)
				brightest = max(brightest, rgb[3])
				if(lamp_color == "#ffffff" && (rgb[1] != rgb[2] || rgb[2] != rgb[3]))
					fail("A white lamp retained the authored amber lens tint.")
				if(lamp_color == "#0000ff" && (rgb[1] || rgb[2]))
					fail("A blue lamp's emission included unrelated color channels.")
		if(brightest < 100)
			fail("Neutralizing the lens removed its usable brightness.")
	lamp.on = FALSE
	lamp.update_brightness()
	if(lamp.emissive_overlay || lamp.light_range)
		fail("Switching the floor lamp off retained illumination or bloom.")
	lamp.on = TRUE
	lamp.stat |= NOPOWER
	lamp.update_brightness()
	if(lamp.emissive_overlay || lamp.light_range)
		fail("An unpowered floor lamp retained illumination or bloom.")
	lamp.stat &= ~NOPOWER
	lamp.damaged = 1
	lamp.update_brightness()
	if(lamp.emissive_overlay || lamp.icon_state != "floorlight01")
		fail("A damaged recessed lens rendered an intact lamp glow.")
	lamp.stat |= BROKEN
	lamp.update_brightness()
	if(lamp.emissive_overlay || lamp.light_range)
		fail("A broken floor lamp retained illumination or bloom.")
	qdel(lamp)
	var/obj/machinery/floor_light/panel = new(C)
	panel.stat &= ~(BROKEN|NOPOWER)
	panel.anchored = TRUE
	panel.on = TRUE
	panel.use_power = POWER_USE_ACTIVE
	panel.update_brightness()
	if(!panel.emissive_overlay || panel.emissive_overlay.icon_state != "on")
		fail("A lit square panel did not reach the emissive plane.")
	panel.damaged = 2
	panel.update_icon()
	if(panel.emissive_overlay?.icon_state != "flicker2")
		fail("The panel bloom did not follow its flickering lens state.")
	panel.on = FALSE
	panel.update_brightness()
	if(panel.emissive_overlay)
		fail("Switching the square panel off retained bloom.")
	qdel(panel)
	if(!reported) pass("Recessed and square floor lamps emit only while powered, with matching lens states.")
	return TRUE
