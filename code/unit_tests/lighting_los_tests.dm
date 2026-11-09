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
	actor.blend_mode = BLEND_ADD
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
		if(E.blend_mode != BLEND_OVERLAY)
			fail("An additive source made its black floor silhouette additive too.")
		if(E.animate_movement != SYNC_STEPS || ((E.appearance_flags & LONG_GLIDE) != (actor.appearance_flags & LONG_GLIDE)))
			fail("Silhouette glide settings diverged from its owner.")
		var/revision = E.projection_revision
		actor.update_dynamic_shadow()
		if(E.projection_revision != revision)
			fail("Stationary refresh restarted an unchanged projection.")
		// Turning and moving must start one reshape, using the actual glide.
		actor.set_glide_size(4)
		actor.dir = WEST
		var/turf/next = get_step(C, NORTH)
		actor.Move(next, NORTH)
		if(E.projection_revision != revision + 1 || E.projection_duration != world.icon_size / actor.glide_size * world.tick_lag)
			fail("A moving turn was reshaped twice or used a stationary duration.")
		var/matrix/moving_projection = E.transform
		var/moving_alpha = E.alpha
		var/moving_revision = E.projection_revision
		actor.icon_state = "crateopen"
		E.copy_owner_appearance()
		if(!(E.transform ~= moving_projection) || E.alpha != moving_alpha || E.projection_revision != moving_revision)
			fail("Refreshing sprite content replaced the shadow's animated state.")
		actor.icon_state = "crate"
		actor.Move(C, SOUTH)
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
		var/mutable_appearance/physical_part = mutable_appearance(actor.icon, actor.icon_state)
		physical_part.plane = DEFAULT_PLANE
		actor.overlays += physical_part
		actor.update_dynamic_shadow()
		var/mutable_appearance/shadow_part = E.overlays[1]
		if(!shadow_part || shadow_part.plane != FLOAT_PLANE || (shadow_part.appearance_flags & KEEP_APART))
			fail("A physical sprite part escaped the dedicated floor-shadow pass.")
		actor.overlays.Cut()
		var/mutable_appearance/glow = mutable_appearance(actor.icon, actor.icon_state)
		glow.plane = EMISSIVE_PLANE
		actor.overlays += glow
		actor.update_dynamic_shadow()
		if(E.maptext || E.overlays.len || E.underlays.len || E.plane != WORLD_SHADOW_SOURCE_PLANE || E.layer != MOB_SHADOW_LAYER)
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
	var/obj/underfloor = new(C)
	underfloor.layer = PIPE_LAYER
	underfloor.sync_world_render_plane()
	var/obj/screen/world_terrain_display/terrain_display = new
	var/obj/screen/world_shadow_display/shadow_display = new
	if(C.plane != WORLD_TERRAIN_SOURCE_PLANE || underfloor.plane != C.plane)
		fail("Terrain composition exposed an underfloor object above the floor.")
	if(terrain_display.plane != WORLD_TERRAIN_DISPLAY_PLANE || shadow_display.plane != WORLD_SHADOW_DISPLAY_PLANE || terrain_display.plane >= shadow_display.plane || shadow_display.plane >= DEFAULT_PLANE || terrain_display.layer < BACKGROUND_LAYER || shadow_display.layer < BACKGROUND_LAYER)
		fail("Floor shadows are not composed after terrain and before SIDE_MAP objects.")
	if(!(terrain_display.appearance_flags & PASS_MOUSE) || shadow_display.mouse_opacity)
		fail("World composition lost terrain mouse routing or made shadows interactive.")
	qdel(underfloor)
	qdel(terrain_display)
	qdel(shadow_display)
	qdel(flush_lamp)
	// The receiver can be lit by a beam that misses the caster entirely.
	var/turf/receiver = get_step(C, SOUTH)
	var/obj/key_light = new(locate(C.x, C.y + 3, C.z))
	var/obj/fill_light = new(locate(C.x, C.y - 4, C.z))
	key_light.set_light(8, 4, "#ffffff")
	SSlighting.fire(FALSE, TRUE)
	var/unfilled = actor.dynamic_shadow_retention(key_light.light, receiver, 0, -3, 3)
	if(unfilled != 1)
		fail("A single source cancelled its own shadow.")
	fill_light.set_light(8, 0.5, "#ffffff")
	SSlighting.fire(FALSE, TRUE)
	var/weak_fill = actor.dynamic_shadow_retention(key_light.light, receiver, 0, -3, 3)
	if(weak_fill <= 0 || weak_fill >= unfilled)
		fail("Weak opposing light did not partially fill the receiving floor's shadow.")
	fill_light.set_light(8, 8, "#ffffff")
	SSlighting.fire(FALSE, TRUE)
	if(actor.dynamic_shadow_retention(key_light.light, receiver, 0, -3, 3) != 0)
		fail("Strong opposing light did not cancel a shadow it illuminates.")
	fill_light.forceMove(key_light.loc)
	SSlighting.fire(FALSE, TRUE)
	if(actor.dynamic_shadow_retention(key_light.light, receiver, 0, -3, 3) != 1)
		fail("A second lamp behind the caster erased their shared shadow.")
	fill_light.forceMove(locate(C.x, C.y - 4, C.z))
	fill_light.light_cone_angle = 60
	fill_light.light_cone_target_x = C.x
	fill_light.light_cone_target_y = C.y - 8
	fill_light.update_light()
	SSlighting.fire(FALSE, TRUE)
	if(actor.dynamic_shadow_retention(key_light.light, receiver, 0, -3, 3) != 1)
		fail("A beam aimed away from the receiving floor erased its shadow.")
	fill_light.light_cone_target_y = receiver.y
	fill_light.update_light()
	SSlighting.fire(FALSE, TRUE)
	if(actor.dynamic_shadow_retention(key_light.light, receiver, 0, -3, 3) != 0)
		fail("A beam aimed at the receiving floor failed to cancel the shadow.")
	actor.update_dynamic_shadow()
	var/atom/movable/dynamic_shadow/key_shadow = actor.dynamic_shadows?[key_light.light]
	if(!key_shadow?.light_mask || key_shadow.filters.len != 3)
		fail("Receiver illumination did not reach the silhouette's alpha filter.")
	var/mask_signature = key_shadow?.light_mask_signature
	actor.update_dynamic_shadow()
	if(key_shadow?.light_mask_signature != mask_signature)
		fail("Stationary light-mask sampling changed without a lighting change.")
	for(var/dx in -9 to 9)
		var/turf/wall = locate(C.x + dx, C.y - 2, C.z)
		wall.set_opacity(TRUE)
	SSlighting.fire(FALSE, TRUE)
	if(actor.dynamic_shadow_retention(key_light.light, receiver, 0, -3, 3) != 1)
		fail("A beam behind an opaque wall cancelled a visible floor shadow.")
	qdel(key_light)
	qdel(fill_light)
	// At a fixed range, rotating a lamp must rotate both projection axes:
	// the old east/west matrix collapsed the sprite into a thin horizontal line.
	var/projected_area
	for(var/list/offset in list(list(3, 0), list(3, 3), list(0, 3), list(-3, 3), list(-3, 0), list(-3, -3), list(0, -3), list(3, -3)))
		var/dx = offset[1]
		var/dy = offset[2]
		var/distance = sqrt(dx * dx + dy * dy)
		var/matrix/projection = dynamic_shadow_projection(dx, dy, distance, 1, 16)
		var/area_scale = abs(projection.a * projection.e - projection.b * projection.d)
		if(isnull(projected_area)) projected_area = area_scale
		if(area_scale < 0.4 || abs(area_scale - projected_area) > 0.001)
			fail("Rotating the light collapsed the projected sprite's width.")
		if(abs(projection.b * -16 + projection.c) > 0.001 || abs(projection.e * -16 + projection.f + 16) > 0.001)
			fail("Rotating the projection moved its foot anchor.")
	var/mob/living/carbon/human/figure = new(C)
	figure.icon = actor.icon
	figure.icon_state = actor.icon_state
	figure.overlays.Cut()
	var/mob/living/nonhuman = new(C)
	nonhuman.icon = actor.icon
	nonhuman.icon_state = actor.icon_state
	for(var/facing in list(NORTH, SOUTH, EAST, WEST))
		actor.dir = facing
		nonhuman.dir = facing
		figure.dir = facing
		for(var/list/offset in list(list(3, 0), list(-3, 0), list(0, 3), list(0, -3), list(3, 3)))
			var/dx = offset[1]
			var/dy = offset[2]
			var/distance = sqrt(dx * dx + dy * dy)
			var/matrix/flat = actor.get_dynamic_shadow_projection(dx, dy, distance, 1, 16)
			var/matrix/nonhuman_flat = nonhuman.get_dynamic_shadow_projection(dx, dy, distance, 1, 16)
			var/matrix/human_projection = figure.get_dynamic_shadow_projection(dx, dy, distance, 1, 16)
			var/matrix/directional = dynamic_shadow_projection(dx, dy, distance, 1, 16)
			if(flat.a != 0.9 || flat.d || abs(flat.e) < 0.2 || !(flat ~= nonhuman_flat))
				fail("An object or nonhuman mob lost the original flat shadow projection.")
			if(!(human_projection ~= directional))
				fail("A human lost the directional shadow projection.")
			if(actor.dynamic_shadow_sprite_dir(dx, dy) != facing || nonhuman.dynamic_shadow_sprite_dir(dx, dy) != facing)
				fail("A nonhuman caster selected a light-facing sprite instead of its own facing.")
			figure.lying = TRUE
			var/matrix/prone = figure.get_dynamic_shadow_projection(dx, dy, distance, 1, 16)
			if(!(prone ~= flat) || figure.dynamic_shadow_sprite_dir(dx, dy) != actor.dynamic_shadow_sprite_dir(dx, dy))
				fail("A prone human did not use the same flat projection and sprite facing as an object.")
			figure.lying = FALSE
			var/matrix/standing = figure.get_dynamic_shadow_projection(dx, dy, distance, 1, 16)
			if(!(standing ~= directional))
				fail("Standing up did not restore the human's directional shadow.")
	qdel(nonhuman)
	// Expected sprite facings for a character facing N/S/E/W, respectively.
	// Check handedness, not just that either side sprite was selected.
	var/list/facings = list(NORTH, SOUTH, EAST, WEST)
	for(var/list/lighting_case in list(
		list(0, -3, list(NORTH, SOUTH, EAST, WEST)),
		list(0, 3, list(SOUTH, NORTH, WEST, EAST)),
		list(-3, 0, list(WEST, EAST, NORTH, SOUTH)),
		list(3, 0, list(EAST, WEST, SOUTH, NORTH))))
		var/list/expected = lighting_case[3]
		for(var/i in 1 to facings.len)
			figure.dir = facings[i]
			if(figure.dynamic_shadow_sprite_dir(lighting_case[1], lighting_case[2]) != expected[i])
				fail("Human shadow profile is reversed: facing=[figure.dir], light offset=[lighting_case[1]],[lighting_case[2]].")
	// With a lamp north/south, the projected side profile must still point in
	// the character's world-facing horizontal direction, even when width flips.
	for(var/facing in list(EAST, WEST))
		figure.dir = facing
		for(var/dy in list(-3, 3))
			var/matrix/projected = figure.get_dynamic_shadow_projection(0, dy, 3, 1, 16)
			var/profile = figure.dynamic_shadow_sprite_dir(0, dy)
			var/nose_x = projected.a * (profile == EAST ? 1 : -1)
			if(nose_x * (facing == EAST ? 1 : -1) <= 0)
				fail("Projected human profile points opposite the character's facing.")
	figure.dir = EAST
	var/atom/movable/dynamic_shadow/figure_shadow = new(null, figure)
	var/mutable_appearance/accessory = mutable_appearance(actor.icon, actor.icon_state)
	var/mutable_appearance/nested_part = mutable_appearance(actor.icon, actor.icon_state)
	accessory.overlays += nested_part
	figure.overlays += accessory
	figure_shadow.copy_owner_appearance(SOUTH)
	var/old_appearance = figure_shadow.appearance
	figure_shadow.copy_owner_appearance(WEST)
	var/mutable_appearance/shadow_accessory = figure_shadow.overlays[1]
	var/mutable_appearance/shadow_nested = shadow_accessory.overlays[1]
	// BYOND can normalize a top-level overlay to dir=0 when it inherits the
	// atom's facing. Resolve that inheritance before checking nested equipment.
	var/accessory_dir = shadow_accessory.dir || figure_shadow.dir
	var/nested_dir = shadow_nested.dir || accessory_dir
	if(figure_shadow.dir != WEST || accessory_dir != WEST || nested_dir != WEST || figure_shadow.appearance == old_appearance || figure.dir != EAST)
		fail("Light-view selection did not reach nested equipment or changed the real character's facing: shadow=[figure_shadow.dir], accessory=[accessory_dir], nested=[nested_dir], changed=[figure_shadow.appearance != old_appearance], owner=[figure.dir].")
	// Procedural walking bodies live entirely in overlays while icon is null.
	figure.icon = null
	if(!figure.should_cast_dynamic_shadow())
		fail("An overlay-only walking character lost its shadow.")
	figure_shadow.copy_owner_appearance(WEST)
	if(!figure_shadow.overlays.len || figure_shadow.source_width != world.icon_size)
		fail("An overlay-only body lost its silhouette or mask dimensions.")
	qdel(figure_shadow)
	qdel(figure)
	qdel(actor)
	qdel(east)
	qdel(west)
	A.dynamic_lighting = was_dynamic
	if(!reported) pass("Source identity, floor composition, spatial fill, beam direction, occlusion and cleanup verified.")
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

/datum/unit_test/lighting_los_ao
	name = "ARTEMIS - Ambient occlusion disabled"

/datum/unit_test/lighting_los_ao/start_test()
	var/turf/C = lighting_los_fixture()
	var/turf/W = get_step(C, NORTH)
	W = W.ChangeTurf(/turf/unsimulated/wall)
	if(C.permit_ao || C.ao_receiver || W.ao_receiver)
		fail("A newly created turf enables ambient occlusion.")
	C.permit_ao = TRUE // Map overrides must not reactivate globally disabled AO.
	C.queue_ao()
	C.calculate_ao_neighbors()
	C.update_ao()
	C.regenerate_ao()
	if(C.ao_receiver || C.ao_queued || LAZYLEN(C.ao_overlays) || LAZYLEN(C.ao_overlays_mimic) || LAZYLEN(SSao.queue) || !(SSao.flags & SS_NO_FIRE))
		fail("An AO hook creates render data or enables AO processing.")
	var/obj/screen/plane_master/world_ao/PM = new
	var/obj/screen/plane_master/world_ao_receivers/receivers = new
	var/obj/screen/world_ao_display/display = new
	if(PM.filters.len || PM.render_target || receivers.filters.len || receivers.render_target || display.filters.len || display.render_source || display.alpha)
		fail("An obsolete AO screen type still has active rendering effects.")
	C.set_opacity(TRUE)
	C.set_opacity(FALSE)
	C.queue_ao(FALSE)
	C = C.ChangeTurf(/turf/unsimulated/floor)
	if(C.ao_receiver || C.ao_overlays || C.ao_overlays_mimic)
		fail("An opacity change or floor replacement reactivated AO.")
	qdel(PM)
	qdel(receivers)
	qdel(display)
	if(!reported) pass("No AO masks, overlays, filters, render sources or processing; map overrides cannot reactivate AO.")
	return TRUE

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
	// Compare real machinery doors with the same geometry occupied by a wall.
	D = D.ChangeTurf(/turf/unsimulated/wall)
	C.update_shadowcasting_overlays(10)
	var/list/wall_shadows = C.shadowcasting_overlays.Copy()
	var/list/wall_occluders = C.shadowcasting_occluders.Copy()
	D = D.ChangeTurf(/turf/unsimulated/floor)
	var/obj/machinery/door/real_door = new(D)
	C.update_shadowcasting_overlays(10)
	if(real_door.los_never_cull || (real_door in D.vis_contents))
		fail("A door bypasses normal wall LOS through a turf visual-content exemption.")
	if(length(wall_shadows - C.shadowcasting_overlays) || length(C.shadowcasting_overlays - wall_shadows) || length(wall_occluders - C.shadowcasting_occluders) || length(C.shadowcasting_occluders - wall_occluders))
		fail("A closed opaque door does not have the same LOS geometry and visible boundary mask as a wall.")
	var/list/front_visible = list()
	front_visible[get_step(D, WEST)] = TRUE
	if(D.lighting_overlay) D.lighting_overlay.luminosity = 1
	if(D.opacity || !los_boundary_face_visible(D, C, front_visible))
		fail("An opaque door on a floor did not expose its viewer-facing boundary like a wall.")
	var/list/back_visible = list()
	back_visible[get_step(D, EAST)] = TRUE
	if(los_boundary_face_visible(D, C, back_visible))
		fail("A door exposed its far boundary through its closed face.")
	real_door.open()
	shadowcast_process_invalidations()
	C.update_shadowcasting_overlays(10)
	if(C.shadowcasting_overlays.len || C.shadowcasting_occluders.len || los_boundary_face_visible(D, C, front_visible))
		fail("Opening a real door retained wall LOS geometry or a boundary mask.")
	real_door.close()
	shadowcast_process_invalidations()
	C.update_shadowcasting_overlays(10)
	if(!lighting_los_triangle_covers(C.shadowcasting_overlays, 6 * 32, 0) || (real_door in D.vis_contents))
		fail("Closing a real door failed to restore normal wall LOS without bypassing culling.")
	qdel(real_door)
	var/obj/machinery/door/airlock/glass/glass_door = new(D)
	C.update_shadowcasting_overlays(10)
	if(D.opaque_counter || C.shadowcasting_overlays.len || glass_door.los_never_cull || (glass_door in D.vis_contents))
		fail("A transparent door became opaque or bypassed normal LOS culling.")
	qdel(glass_door)
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
	var/atom/movable/los_occluder/rear_mask = make_los_occluder(4, 0)
	var/near_shadow_depth = los_wall_mask_depth(1, 0)
	if(mask.layer <= near_shadow_depth || near_shadow_depth <= rear_mask.layer)
		fail("Wall depth does not preserve the casting wall while hiding a farther wall.")
	var/obj/screen/plane_master/los_occluders/depth_master = new
	var/icon/depth_sample = icon(get_solid_white_icon())
	depth_sample.DrawBox("#000000", 17, 1, 32, 32)
	depth_sample.MapColors(0,0,0,1, 0,0,0,0, 0,0,0,0, 0,0,0,0, 1,1,1,0)
	if(depth_sample.GetPixel(1, 16) != "#ffffff" || depth_sample.GetPixel(32, 16))
		fail("A nearer black shadow does not remove rear-wall mask alpha.")
	qdel(depth_master)
	for(var/normal in list(NORTH, EAST))
		var/list/face = list()
		for(var/offset in -2 to 2)
			var/turf/segment = locate(C.x + (normal == NORTH ? offset : 3), C.y + (normal == NORTH ? 3 : offset), C.z)
			segment.set_opacity(TRUE)
			face += segment
		var/facing = turn(normal, 180)
		var/front_depth = los_wall_face_depth(face[1], facing, C.x, C.y)
		if(front_depth != los_wall_face_depth(face[5], facing, C.x, C.y))
			fail("Adjacent tiles of a straight wall can cut sawtooth holes in one another.")
		var/turf/rear = locate(C.x + (normal == EAST ? 6 : 0), C.y + (normal == NORTH ? 6 : 0), C.z)
		rear.set_opacity(TRUE)
		if(front_depth <= los_wall_face_depth(rear, facing, C.x, C.y) + 0.001)
			fail("A farther wall surface can exempt itself from the nearer wall's shadow.")
		for(var/turf/segment in face) segment.set_opacity(FALSE)
		rear.set_opacity(FALSE)
	var/turf/off_axis = locate(C.x + 6, C.y + 6, C.z)
	off_axis.set_opacity(TRUE)
	if(los_wall_face_depth(off_axis, SOUTH, C.x, C.y) != los_wall_mask_depth(6, 6) || los_wall_face_depth(off_axis, WEST, C.x, C.y) != los_wall_mask_depth(6, 6))
		fail("An off-axis wall face ignored the distance to its nearest endpoint.")
	off_axis.set_opacity(FALSE)
	// An exposed diagonal cap must stay whole, although another wall touches
	// the sightline at a grid corner. A genuinely screened rear wall must not.
	for(var/sx in list(-1, 1))
		for(var/sy in list(-1, 1))
			var/turf/blocker = locate(C.x + 2 * sx, C.y + 3 * sy, C.z)
			var/turf/cap = locate(C.x + 3 * sx, C.y + 4 * sy, C.z)
			blocker.set_opacity(TRUE)
			cap.set_opacity(TRUE)
			if(los_wall_protection_depth(cap, C) < 2)
				fail("An exposed diagonal corner is clipped instead of preserving its complete wall tile.")
			blocker.set_opacity(FALSE)
			cap.set_opacity(FALSE)
			var/turf/joint = locate(C.x + 3 * sx, C.y + 3 * sy, C.z)
			var/turf/side_x = locate(C.x + 2 * sx, C.y + 3 * sy, C.z)
			var/turf/side_y = locate(C.x + 3 * sx, C.y + 2 * sy, C.z)
			joint.set_opacity(TRUE)
			side_x.set_opacity(TRUE)
			side_y.set_opacity(TRUE)
			if(los_wall_protection_depth(joint, C) < 2)
				fail("The inside corner of an L-shaped wall is hidden despite its visible diagonal floor.")
			joint.set_opacity(FALSE)
			side_x.set_opacity(FALSE)
			side_y.set_opacity(FALSE)
			var/turf/long_cap = locate(C.x + 4 * sx, C.y + 3 * sy, C.z)
			var/turf/run_near = locate(C.x + 3 * sx, C.y + 3 * sy, C.z)
			var/turf/run_far = locate(C.x + 2 * sx, C.y + 3 * sy, C.z)
			var/turf/run_side = locate(C.x + 4 * sx, C.y + 2 * sy, C.z)
			for(var/turf/part in list(long_cap, run_near, run_far, run_side)) part.set_opacity(TRUE)
			if(los_wall_protection_depth(long_cap, C) < 2)
				fail("A corner was clipped by its own connected straight wall run.")
			for(var/turf/part in list(long_cap, run_near, run_far, run_side)) part.set_opacity(FALSE)
	for(var/dx in -4 to 2)
		var/turf/near_wall = locate(C.x + dx, C.y - 3, C.z)
		near_wall.set_opacity(TRUE)
	var/turf/screened_wall = locate(C.x + 3, C.y - 5, C.z)
	screened_wall.set_opacity(TRUE)
	if(los_wall_protection_depth(screened_wall, C) >= 2)
		fail("Protecting exposed corners revealed a rear wall whose front floor is blocked.")
	var/turf/remote_cap = locate(C.x + 4, C.y - 5, C.z)
	remote_cap.set_opacity(TRUE)
	if(los_wall_protection_depth(remote_cap, C) >= 2)
		fail("A distant wall was revealed by grazing a nearer wall's corner.")
	remote_cap.set_opacity(FALSE)
	screened_wall.set_opacity(FALSE)
	for(var/dx in -4 to 2)
		var/turf/near_wall = locate(C.x + dx, C.y - 3, C.z)
		near_wall.set_opacity(FALSE)
	// A visible front-floor center does not imply that the entire wall behind
	// it is exposed. Both a straight tile and an L-joint can cross a remote ray.
	var/turf/remote_blocker = locate(C.x + 2, C.y - 3, C.z)
	remote_blocker.set_opacity(TRUE)
	var/turf/partial_wall = locate(C.x + 5, C.y - 5, C.z)
	partial_wall.set_opacity(TRUE)
	var/turf/front_floor = get_step(partial_wall, NORTH)
	if(!los_floor_ray_visible(C, front_floor, partial_wall))
		fail("Partial-wall fixture did not expose the front floor used by the old exemption.")
	if(los_wall_tile_exposed(partial_wall, C) || los_wall_protection_depth(partial_wall, C) >= 2)
		fail("A partly shadowed rear wall was exempted because its front floor was visible.")
	var/turf/partial_joint = locate(C.x + 6, C.y - 5, C.z)
	var/turf/joint_north = get_step(partial_joint, NORTH)
	partial_joint.set_opacity(TRUE)
	joint_north.set_opacity(TRUE)
	if(los_wall_tile_exposed(partial_joint, C) || los_wall_protection_depth(partial_joint, C) >= 2)
		fail("A rear L-joint extended corner protection into a separate wall's shadow.")
	remote_blocker.set_opacity(FALSE)
	partial_wall.set_opacity(FALSE)
	partial_joint.set_opacity(FALSE)
	joint_north.set_opacity(FALSE)
	var/turf/fractional_blocker = locate(C.x + 2, C.y + 1, C.z)
	var/turf/fractional_target = locate(C.x + 6, C.y, C.z)
	fractional_blocker.set_opacity(TRUE)
	if(!los_floor_ray_visible(C, fractional_target, null, C.x, C.y + 0.25) || los_floor_ray_visible(C, fractional_target, null, C.x, C.y + 0.75))
		fail("Wall visibility used the destination tile instead of the fractional gliding eye.")
	fractional_blocker.set_opacity(FALSE)
	var/turf/first_boundary = locate(C.x + 2, C.y, C.z)
	var/turf/second_boundary = locate(C.x + 5, C.y, C.z)
	first_boundary.set_opacity(TRUE)
	second_boundary.set_opacity(TRUE)
	C.update_shadowcasting_overlays(10)
	if(!(first_boundary in C.shadowcasting_mask_walls) || !(second_boundary in C.shadowcasting_mask_walls) || C.shadowcasting_occluders.len != C.shadowcasting_mask_walls.len)
		fail("Native visibility removed opaque candidates from the continuously clipped wall mask.")
	first_boundary.set_opacity(FALSE)
	second_boundary.set_opacity(FALSE)
	var/obj/physical_source = new(C)
	physical_source.icon = get_solid_white_icon()
	physical_source.opacity = TRUE
	physical_source.maptext = "not physical wall art"
	var/mutable_appearance/physical_part = mutable_appearance(physical_source.icon)
	physical_source.overlays += physical_part
	var/mutable_appearance/glow_part = mutable_appearance(physical_source.icon)
	glow_part.plane = EMISSIVE_PLANE
	physical_source.overlays += glow_part
	var/source_appearance = physical_source.appearance
	var/mutable_appearance/retained = los_retained_wall_appearance(physical_source)
	if(retained.overlays.len != 1 || retained.maptext || retained.mouse_opacity || physical_source.appearance != source_appearance)
		fail("Retained wall art duplicated emission or changed its real source.")
	var/area/retained_area = get_area(C)
	var/was_dynamic = retained_area.dynamic_lighting
	retained_area.dynamic_lighting = TRUE
	C.lighting_build_overlay()
	C.set_opacity(TRUE)
	C.lighting_overlay.update_overlay()
	var/list/render_sources = los_wall_render_sources(C, list())
	if(!(C in render_sources) || !(physical_source in render_sources) || !(C.lighting_overlay in render_sources) || !(C.lighting_overlay.edge_guard in render_sources))
		fail("Retaining a wall omitted its light sample or dark edge padding.")
	var/mutable_appearance/retained_light = los_retained_wall_appearance(C.lighting_overlay)
	if(retained_light.plane != LIGHTING_SAMPLE_PLANE || !retained_light.color)
		fail("Retained lighting escaped the multiply lightmap.")
	C.set_opacity(FALSE)
	retained_area.dynamic_lighting = was_dynamic
	qdel(physical_source)
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
	for(var/dx in 1 to 11)
		var/turf/wall = locate(C.x + dx, C.y + 2, C.z)
		wall.set_opacity(TRUE)
	var/list/visible = view(11, viewer)
	var/turf/clear_far_tile = locate(C.x + 11, C.y, C.z)
	var/turf/blocked_far_tile = locate(C.x + 8, C.y + 4, C.z)
	if(!(clear_far_tile in visible) || (blocked_far_tile in visible))
		fail("Fixture must have both a visible tile and a blocked tile beyond the normal viewport.")
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
	if(!reported) pass("The shifted viewport shows clear distant tiles and still hides tiles blocked from the body.")
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
	var/turf/anchor = locate(C.x - 3, C.y, C.z)
	first_viewer.anchor(anchor)
	for(var/image/ray in first_viewer.triangles)
		if(ray.loc != anchor || ray.pixel_w != 3 * world.icon_size || ray.pixel_z)
			fail("LOS passes can be culled separately or shifted away from their wall.")
	// Reanchoring must preserve all six projected world positions, including
	// when native view drops the original wall while the viewer glides past it.
	anchor = get_step(anchor, NORTH)
	first_viewer.anchor(anchor)
	for(var/image/ray in first_viewer.triangles)
		if(ray.loc != anchor || ray.pixel_w + anchor.x * world.icon_size != C.x * world.icon_size || ray.pixel_z + anchor.y * world.icon_size != C.y * world.icon_size)
			fail("Moving the shared LOS anchor moved a projected wall edge.")
	// Both passes must use identical geometry: a sharp foreground hole and a
	// feathered floor edge cannot disagree about which side of a wall is hidden.
	if(first_viewer.triangles.len != 6)
		fail("The foreground has no independent geometric LOS mask.")
	else
		for(var/i in 1 to 2)
			var/image/soft = first_viewer.triangles[i]
			var/image/sharp = first_viewer.triangles[i + 2]
			var/matrix/A = soft.transform
			var/matrix/B = sharp.transform
			if(sharp.plane != SHADOWCASTING_GEOMETRY_PLANE || sharp == soft || A.a != B.a || A.b != B.b || A.c != B.c || A.d != B.d || A.e != B.e || A.f != B.f)
				fail("Foreground visibility diverged from the floor's wall rays.")
			var/image/mask_shadow = first_viewer.triangles[i + 4]
			var/matrix/depth_projection = mask_shadow.transform
			if(mask_shadow.plane != SHADOWCASTING_REFLECTOR_PLANE || !(depth_projection ~= A))
				fail("Wall-depth masking diverged from the animated LOS rays.")
	var/image/first = first_viewer.triangles[1]
	var/image/second = second_viewer.triangles[1]
	var/matrix/original = second.transform
	first_viewer.reshape(C.x - 2, C.y + 1, 36, 2)
	for(var/i in 5 to 6)
		var/image/depth_ray = first_viewer.triangles[i]
		if(abs(depth_ray.layer - los_wall_face_depth(C, WEST, C.x - 2, C.y + 1)) > 0.000001)
			fail("An animated wall ray retained depth from a different viewpoint than its transform.")
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
