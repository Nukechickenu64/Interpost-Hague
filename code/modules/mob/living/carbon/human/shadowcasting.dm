#define SHADOWCAST_RANGE 7
#define LOS_CULL_MAX_RANGE 20

// Artemis reference: continuous wall/door silhouettes, not just native tile culling.
var/global/enhanced_los_enabled = TRUE
#ifdef ARTEMIS_LOS_PREVIEW
var/global/los_preview_legacy_images = FALSE
#endif

/turf
	var/shadowcast_inview
	var/shadowcast_lit
	var/shadowcast_considered
	var/shadowcasting_initialized = FALSE
	var/shadowcasting_range = 0
	var/list/shadowcasting_edges = list()
	var/list/shadowcasting_overlays = list()
	var/list/shadowcasting_occluders = list()
	var/list/shadowcasting_visible_turfs = list()
	var/list/shadowcasting_visible_walls = list()

/turf/New()
	. = ..()
	if(shadowcasting_controller.initialized)
		shadowcast_queue_invalidate(src)

/turf/proc/update_shadowcasting_overlays(view_range = SHADOWCAST_RANGE)
	create_shadowcast_overlays(src, view_range)
	shadowcasting_range = view_range
	shadowcasting_initialized = TRUE

var/global/list/shadowcast_dirty_centers = list()

/// Queues cache invalidation for every turf whose shadow geometry could include T.
/proc/shadowcast_queue_invalidate(turf/T)
	if(!shadowcasting_controller.initialized || !istype(T))
		return
	if(!shadowcast_dirty_centers.len)
		spawn(1)
			shadowcast_process_invalidations()
	shadowcast_dirty_centers[T] = TRUE

/proc/shadowcast_process_invalidations()
	set background = 1
	var/list/centers = shadowcast_dirty_centers
	shadowcast_dirty_centers = list()
	var/reach = LOS_CULL_MAX_RANGE + 2
	var/cull_reach = LOS_CULL_MAX_RANGE + 1
	for(var/turf/C as anything in centers)
		if(QDELETED(C))
			continue
		for(var/turf/T as anything in block(locate(max(C.x - cull_reach, 1), max(C.y - cull_reach, 1), C.z), locate(min(C.x + cull_reach, world.maxx), min(C.y + cull_reach, world.maxy), C.z)))
			T.shadowcasting_initialized = FALSE
	for(var/client/CL as anything in GLOB.clients)
		var/turf/cull_turf = CL.los_cull_turf
		if(!cull_turf)
			continue
		for(var/turf/C as anything in centers)
			if(!QDELETED(C) && C.z == cull_turf.z && get_dist(C, cull_turf) <= cull_reach)
				CL.update_cull_mask(TRUE)
				break
	if(!enhanced_los_enabled)
		return
	for(var/client/CL as anything in GLOB.clients)
		var/turf/last = CL.last_shadow_turf
		if(!last)
			continue
		for(var/turf/C as anything in centers)
			if(!QDELETED(C) && C.z == last.z && get_dist(C, last) <= reach)
				CL.shadowcast_force = TRUE
				CL.update_opacity_image()
				break

/// Affine matrix mapping the triangle icon onto (x1,y1)-(x2,y2)-(x3,y3), in pixels relative to the image's loc centre.
/proc/los_triangle_matrix(x1, y1, x2, y2, x3, y3)
	return matrix((x3 - x2) / 32, (x1 - x2) / 32, (x3 + x1) / 2, (y3 - y2) / 32, (y1 - y2) / 32, (y1 + y3) / 2)

/datum/triangle
	var/x1
	var/y1
	var/x2
	var/y2
	var/x3
	var/y3

/datum/triangle/New(x1, y1, x2, y2, x3, y3)
	src.x1 = x1
	src.y1 = y1
	src.x2 = x2
	src.y2 = y2
	src.x3 = x3
	src.y3 = y3

var/global/shadowcast_generation = 0

/proc/los_hidden_wall_mounts(list/visible_turfs, list/visible_walls)
	var/list/hidden = list()
	for(var/turf/wall in visible_walls)
		for(var/direction in GLOB.cardinal)
			var/turf/object_turf = get_step(wall, direction)
			if(!object_turf || visible_turfs[object_turf]) continue
			var/dx = wall.x - object_turf.x
			var/dy = wall.y - object_turf.y
			for(var/obj/O in object_turf)
				if((dx && O.pixel_x * dx > 0) || (dy && O.pixel_y * dy > 0))
					hidden[O] = TRUE
	return hidden

// Two triangles extruded from a fixed world-space wall edge. Coordinates are
// relative to the wall centre; only the far vertices depend on the eye position.
// A constant projection factor makes every matrix coefficient affine in eye x/y,
// so LINEAR_TRANSFORM reproduces the same geometry between server movement ticks.
/proc/los_edge_matrices(direction, eye_x, eye_y, projection)
	var/ax = -16
	var/ay = -16
	var/bx = 16
	var/by = -16
	switch(direction)
		if(NORTH)
			ay = by = 16
			eye_y = max(eye_y, 16)
		if(SOUTH)
			eye_y = min(eye_y, -16)
		if(EAST)
			ax = bx = 16
			by = 16
			eye_x = max(eye_x, 16)
		if(WEST)
			bx = -16
			by = 16
			eye_x = min(eye_x, -16)
	var/fax = ax + (ax - eye_x) * projection
	var/fay = ay + (ay - eye_y) * projection
	var/fbx = bx + (bx - eye_x) * projection
	var/fby = by + (by - eye_y) * projection
	return list(los_triangle_matrix(ax, ay, bx, by, fax, fay), los_triangle_matrix(bx, by, fbx, fby, fax, fay))

/proc/create_shadowcast_overlays(turf/locturf, view_range = SHADOWCAST_RANGE)
	var/vrange = Clamp(view_range, SHADOWCAST_RANGE, LOS_CULL_MAX_RANGE)
	var/moveid = ++shadowcast_generation
	var/list/edges = list()
	var/list/shadows = list()
	var/list/occluders = list()
	var/list/visible_turfs = list()
	var/list/visible_walls = list()
	FOR_DVIEW(var/turf/T, vrange, locturf, INVISIBILITY_MAXIMUM)
		T.shadowcast_inview = moveid
		visible_turfs[T] = TRUE
	END_FOR_DVIEW
	for(var/turf/T as anything in block(locate(max(locturf.x - vrange, 1), max(locturf.y - vrange, 1), locturf.z), locate(min(locturf.x + vrange, world.maxx), min(locturf.y + vrange, world.maxy), locturf.z)))
		if(!T.opaque_counter || T == locturf)
			continue
		if(T.shadowcast_inview == moveid)
			visible_walls += T
			occluders += make_los_occluder(T.x - locturf.x, T.y - locturf.y)
		for(var/direction in GLOB.cardinal)
			var/turf/neighbor = get_step(T, direction)
			if(neighbor?.opaque_counter)
				continue
			var/key = "\ref[T]:[direction]"
			edges[key] = list(T, direction)
#ifdef UNIT_TEST
			// Static output supports geometry diagnostics. The client uses private,
			// persistent images below; never animate these shared cached appearances.
			var/list/matrices = los_edge_matrices(direction, (locturf.x - T.x) * 32, (locturf.y - T.y) * 32, 2 * vrange + 4)
			for(var/matrix/M in matrices)
				M.c += (T.x - locturf.x) * 32
				M.f += (T.y - locturf.y) * 32
				var/tag = "los-edge-static-[direction]-[M.a]-[M.b]-[M.c]-[M.d]-[M.e]-[M.f]"
				var/atom/movable/triangle/shadow = locate(tag)
				if(!shadow)
					shadow = new(0, 0, 0, 0, 0, 0)
					shadow.transform = M
					shadow.tag = tag
				shadows += shadow
#endif
	locturf.shadowcasting_edges = edges
	locturf.shadowcasting_overlays = shadows
	locturf.shadowcasting_occluders = occluders
	locturf.shadowcasting_visible_turfs = visible_turfs
	locturf.shadowcasting_visible_walls = visible_walls

/atom/movable/triangle
	name = ""
	icon = 'icons/effects/triangle.dmi'
	icon_state = "triangle"
	plane = SHADOWCASTING_PLANE
	mouse_opacity = 0
	opacity = 0
	color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,32, 0,0,0,0)

/atom/movable/triangle/New(x1, y1, x2, y2, x3, y3)
	transform = los_triangle_matrix(x1, y1, x2, y2, x3, y3)
	tag = "los-triangle-[x1]-[y1]-[x2]-[y2]-[x3]-[y3]"

/proc/make_triangle_image(x1, y1, x2, y2, x3, y3)
	var/atom/movable/triangle/T = locate("los-triangle-[x1]-[y1]-[x2]-[y2]-[x3]-[y3]")
	if(!T)
		T = new(x1, y1, x2, y2, x3, y3)
	return T

/atom/movable/los_square
	name = ""
	plane = SHADOWCASTING_PLANE
	mouse_opacity = 0
	opacity = 0
	color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,32, 0,0,0,0)

/atom/movable/los_square/New(dx, dy, new_tag)
	icon = get_solid_white_icon()
	pixel_x = dx * world.icon_size
	pixel_y = dy * world.icon_size
	tag = new_tag

/proc/make_los_square(dx, dy)
	var/tag = "los-square-[dx]-[dy]"
	var/atom/movable/los_square/S = locate(tag)
	if(!S)
		S = new(dx, dy, tag)
	return S

/atom/movable/los_occluder
	name = ""
	plane = SHADOWCASTING_REFLECTOR_PLANE
	mouse_opacity = 0
	opacity = 0

/atom/movable/los_occluder/New(dx, dy, new_tag)
	icon = get_solid_white_icon()
	pixel_x = dx * world.icon_size
	pixel_y = dy * world.icon_size
	tag = new_tag

/proc/make_los_occluder(dx, dy)
	var/tag = "los-occluder-solid-[dx]-[dy]"
	var/atom/movable/los_occluder/O = locate(tag)
	if(!O)
		O = new(dx, dy, tag)
	return O

/datum/los_edge_mesh
	var/turf/wall
	var/direction
	var/list/image/triangles = list()
	var/last_eye_x
	var/last_eye_y
	var/last_projection
	var/shape_revision = 0

// Crossing the plane of an edge changes which side can cast. Split there so a
// degenerate back-facing edge does not begin growing half a step too early.
/proc/los_edge_crossing(direction, start_x, start_y, end_x, end_y)
	var/start = direction & (NORTH|SOUTH) ? start_y : start_x
	var/finish = direction & (NORTH|SOUTH) ? end_y : end_x
	var/boundary = direction & (NORTH|EAST) ? 16 : -16
	if(start == finish)
		return null
	var/fraction = (boundary - start) / (finish - start)
	return fraction > 0 && fraction < 1 ? fraction : null

/datum/los_edge_mesh/New(turf/new_wall, new_direction)
	wall = new_wall
	direction = new_direction
	for(var/i in 1 to 2)
		var/image/I = image('icons/effects/triangle.dmi', wall, "triangle")
		I.plane = SHADOWCASTING_PLANE
		I.color = "#000000"
		I.mouse_opacity = 0
		I.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
		triangles += I

/datum/los_edge_mesh/proc/reshape(eye_x, eye_y, projection, duration = 0, start_eye_x, start_eye_y)
	// Life/opacity refreshes must not cancel a glide just because they default to
	// duration=0. A repeated endpoint is already being displayed or approached.
	if(eye_x == last_eye_x && eye_y == last_eye_y && projection == last_projection)
		return FALSE
	shape_revision++
	if(isnull(start_eye_x))
		start_eye_x = last_eye_x
		start_eye_y = last_eye_y
	var/list/matrices = los_edge_matrices(direction, (eye_x - wall.x) * 32, (eye_y - wall.y) * 32, projection)
	var/crossing
	var/list/intermediate
	if(duration && !isnull(start_eye_x))
		crossing = los_edge_crossing(direction, (start_eye_x - wall.x) * 32, (start_eye_y - wall.y) * 32, (eye_x - wall.x) * 32, (eye_y - wall.y) * 32)
		if(!isnull(crossing))
			intermediate = los_edge_matrices(direction, (start_eye_x + (eye_x - start_eye_x) * crossing - wall.x) * 32, (start_eye_y + (eye_y - start_eye_y) * crossing - wall.y) * 32, projection)
	for(var/i in 1 to 2)
		var/image/I = triangles[i]
		if(intermediate)
			animate(I, transform = intermediate[i], time = duration * crossing, flags = ANIMATION_LINEAR_TRANSFORM)
			animate(I, transform = matrices[i], time = duration * (1 - crossing), flags = ANIMATION_LINEAR_TRANSFORM | ANIMATION_CONTINUE)
		else if(duration)
			// Interruptions continue from the client's interpolated transform.
			animate(I, transform = matrices[i], time = duration, flags = ANIMATION_LINEAR_TRANSFORM)
		else
			animate(I)
			I.transform = matrices[i]
	last_eye_x = eye_x
	last_eye_y = eye_y
	last_projection = projection
	return TRUE

/datum/los_edge_mesh/Destroy()
	for(var/image/I in triangles)
		qdel(I)
	triangles.Cut()
	wall = null
	return ..()

// Tracks the same pixel journey as the mob. Opacity/Life refreshes can add new
// edges during a glide without starting the journey again from a tile center.
/datum/los_motion
	var/start_x
	var/start_y
	var/target_x
	var/target_y
	var/started = 0
	var/ends = 0

/datum/los_motion/proc/position(now = world.time)
	var/fraction = ends > started ? Clamp((now - started) / (ends - started), 0, 1) : 1
	return list(start_x + (target_x - start_x) * fraction, start_y + (target_y - start_y) * fraction)

/datum/los_motion/proc/reset(x, y, now = world.time)
	start_x = target_x = x
	start_y = target_y = y
	started = ends = now

/datum/los_motion/proc/begin(from_x, from_y, to_x, to_y, glide, tick_lag, long_glide, now = world.time)
	var/list/current = position(now)
	if(isnull(target_x) || target_x != from_x || target_y != from_y)
		current = list(from_x, from_y)
	start_x = current[1]
	start_y = current[2]
	target_x = to_x
	target_y = to_y
	started = now
	var/dx = abs(target_x - start_x)
	var/dy = abs(target_y - start_y)
	var/distance = long_glide ? max(dx, dy) : sqrt(dx * dx + dy * dy)
	ends = now + distance * world.icon_size / max(glide, 1) * tick_lag

/client
	var/list/los_meshes = list()
	var/list/los_hidden_mount_images = list()
	var/image/los_wall_mask
	var/atom/movable/los_wall_anchor
	var/turf/last_shadow_turf
	var/last_shadow_range = 0
	var/shadowcast_force = FALSE
	var/datum/los_motion/los_motion = new
	var/los_move_depth = 0
	var/turf/los_move_origin
	var/los_saved_camera_glide

// Automatic camera gliding has its own catch-up speed. Keep body-following
// scrolling on the same explicit speed as the body and projected LOS, including
// the first and last step. Remote eyes retain their own camera behavior.
/client/proc/sync_los_camera_glide()
	if(eye == mob && shadowcasting_enabled())
		if(isnull(los_saved_camera_glide))
			los_saved_camera_glide = glide_size
		glide_size = mob.glide_size
	else
		restore_los_camera_glide()

/client/proc/restore_los_camera_glide()
	if(!isnull(los_saved_camera_glide))
		glide_size = los_saved_camera_glide
		los_saved_camera_glide = null

/client/proc/shadowcasting_enabled()
	if(!enhanced_los_enabled || !isliving(mob) || isAI(mob))
		return FALSE
	if(get_turf(eye) != get_turf(mob) && !look_far_active())
		return FALSE
	if(mob.sight & (SEE_TURFS|SEE_OBJS|SEE_MOBS))
		return FALSE
	return TRUE

/client/proc/create_opacity_image()
	if(!enhanced_los_enabled)
		return
	if(!los_wall_mask)
		los_wall_anchor = new
		los_wall_anchor.animate_movement = NO_STEPS
		los_wall_anchor.mouse_opacity = 0
		los_wall_mask = image(loc = los_wall_anchor)
		los_wall_mask.plane = SHADOWCASTING_REFLECTOR_PLANE
		los_wall_mask.mouse_opacity = 0
		los_wall_mask.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
	clear_opacity_image()
	images |= los_wall_mask
	update_opacity_image()

/client/proc/clear_opacity_image()
	restore_los_camera_glide()
	for(var/obj/O in los_hidden_mount_images)
		var/image/I = los_hidden_mount_images[O]
		images -= I
		qdel(I)
	los_hidden_mount_images.Cut()
	for(var/key in los_meshes)
		var/datum/los_edge_mesh/mesh = los_meshes[key]
		images -= mesh.triangles
		qdel(mesh)
	los_meshes.Cut()
	if(los_wall_mask)
		los_wall_mask.vis_contents.Cut()
	last_shadow_turf = null

/client/proc/update_wall_mount_visibility(turf/T)
	var/list/hidden = los_hidden_wall_mounts(T.shadowcasting_visible_turfs, T.shadowcasting_visible_walls)
	for(var/obj/O in los_hidden_mount_images - hidden)
		var/image/I = los_hidden_mount_images[O]
		images -= I
		los_hidden_mount_images -= O
		qdel(I)
	for(var/obj/O in hidden)
		if(los_hidden_mount_images[O]) continue
		// Hide the unseen object for this viewer, never punch a rectangular hole
		// in the visible wall to hide an overlapping fixture.
		var/image/I = image(loc = O)
		I.override = TRUE
		I.alpha = 0
		I.appearance_flags = RESET_ALPHA
		los_hidden_mount_images[O] = I
		images += I

/client/proc/shadowcast_view_range()
	var/range = ceil(max(last_view_x_dim, last_view_y_dim) / 2)
	if(look_far_active())
		range += get_dist(get_turf(mob), get_turf(eye))
	return Clamp(range, SHADOWCAST_RANGE, LOS_CULL_MAX_RANGE)

/client/proc/update_opacity_image(allow_glide = FALSE)
	if(!los_wall_mask || los_move_depth)
		return
	sync_los_camera_glide()
	var/turf/T = get_turf(mob)
	if(!T || !shadowcasting_enabled())
		if(last_shadow_turf)
			clear_opacity_image()
		return
	var/view_range = shadowcast_view_range()
	if(T == last_shadow_turf && last_shadow_range == view_range && T.shadowcasting_initialized && T.shadowcasting_range == view_range && !shadowcast_force)
		// Offset objects can move without changing opacity or the viewer's turf.
		update_wall_mount_visibility(T)
		return
	if(!T.shadowcasting_initialized || T.shadowcasting_range != view_range)
		T.update_shadowcasting_overlays(view_range)
	update_wall_mount_visibility(T)
	var/turf/from = los_move_origin || last_shadow_turf
	// DreamSeeker can briefly replay a completed image transform when a new
	// sequence supersedes it. Retire that image before starting another glide.
	// Keep in-flight images so interrupted movement continues from the actual
	// client interpolation instead of snapping to a server-estimated position.
	var/renew_meshes = allow_glide && world.time >= los_motion.ends
#ifdef ARTEMIS_LOS_PREVIEW
	if(los_preview_legacy_images) renew_meshes = FALSE
#endif
	if(allow_glide && mob.animate_movement != NO_STEPS && from && from.z == T.z && get_dist(from, T) == 1)
		los_motion.begin(from.x, from.y, T.x, T.y, mob.glide_size, world.tick_lag, mob.appearance_flags & LONG_GLIDE)
	else if(T != last_shadow_turf)
		los_motion.reset(T.x, T.y)
	var/list/current_eye = los_motion.position()
	var/duration = max(0, los_motion.ends - world.time)
	var/projection = 2 * view_range + 4
	for(var/key in los_meshes - T.shadowcasting_edges)
		var/datum/los_edge_mesh/mesh = los_meshes[key]
		images -= mesh.triangles
		qdel(mesh)
		los_meshes -= key
	for(var/key in T.shadowcasting_edges)
		var/datum/los_edge_mesh/mesh = los_meshes[key]
		if(mesh && renew_meshes && duration)
			images -= mesh.triangles
			qdel(mesh)
			mesh = null
		if(!mesh)
			var/list/edge = T.shadowcasting_edges[key]
			mesh = new(edge[1], edge[2])
			los_meshes[key] = mesh
			mesh.reshape(current_eye[1], current_eye[2], projection)
			images |= mesh.triangles
		mesh.reshape(T.x, T.y, projection, duration, current_eye[1], current_eye[2])
	los_wall_anchor.loc = T
	los_wall_mask.vis_contents = T.shadowcasting_occluders
	last_shadow_turf = T
	last_shadow_range = view_range
	shadowcast_force = FALSE

/client/Del()
	clear_opacity_image()
	QDEL_NULL(los_wall_mask)
	QDEL_NULL(los_wall_anchor)
	QDEL_NULL(los_motion)
	return ..()

/atom/movable/los_strip
	name = ""
	plane = SHADOWCASTING_PLANE
	mouse_opacity = 0
	opacity = 0
	appearance_flags = PIXEL_SCALE
	color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,32, 0,0,0,0)

/atom/movable/los_strip/New(dx, dy, len, new_tag)
	var/icon/strip_icon = icon(get_solid_white_icon())
	strip_icon.Scale(len * world.icon_size, world.icon_size)
	icon = strip_icon
	pixel_x = dx * world.icon_size
	pixel_y = dy * world.icon_size
	tag = new_tag

/proc/make_los_strip(dx, dy, len)
	var/tag = "los-strip-[dx]-[dy]-[len]"
	var/atom/movable/los_strip/S = locate(tag)
	if(!S)
		S = new(dx, dy, len, tag)
	return S

/proc/los_pixel_offset_toward_viewer(atom/movable/object, turf/viewer)
	if(!object || !viewer || !object.anchored || istype(object, /obj/item))
		return FALSE
	var/turf/source = get_turf(object)
	if(!source || source.z != viewer.z)
		return FALSE
	return (object.pixel_x && (viewer.x - source.x) * object.pixel_x > 0) || (object.pixel_y && (viewer.y - source.y) * object.pixel_y > 0)

/// Black strips over every tile within range that BYOND culls for opacity/darkness, so pixel-offset sprites from visible tiles can't draw over them.
/proc/get_los_cull_strips(turf/center, range, mob/viewer, use_viewer = FALSE)
	var/list/visible = list()
	var/turf/visibility_center = center
	if(viewer && isturf(viewer.loc) && (use_viewer || viewer.loc == center))
		visibility_center = get_turf(viewer)
		// view() from the mob matches the client's native culling exactly (opacity AND darkness/see_in_dark)
		for(var/turf/T in view(range, viewer))
			visible[T] = TRUE
	else
		// Remote eyes (cameras etc.) fall back to pure opacity culling
		FOR_DVIEW(var/turf/T, range, center, INVISIBILITY_MAXIMUM)
			visible[T] = TRUE
		END_FOR_DVIEW
	var/list/visible_faces = list()
	FOR_DVIEW(var/turf/wall, range, visibility_center, INVISIBILITY_MAXIMUM)
		if(!wall.opacity || visible[wall] || (wall.lighting_overlay && !wall.lighting_overlay.luminosity))
			continue
		for(var/direction in GLOB.cardinal)
			var/turf/face = get_step(wall, direction)
			if(!face || face.opaque_counter || !visible[face])
				continue
			if((face.x - wall.x) * (visibility_center.x - wall.x) > 0 || (face.y - wall.y) * (visibility_center.y - wall.y) > 0)
				visible_faces[wall] = TRUE
				break
	END_FOR_DVIEW
	visible |= visible_faces
	var/list/strips = list()
	for(var/dy in -range to range)
		var/run_start = null
		for(var/dx in -range to range + 1)
			var/hidden = FALSE
			if(dx <= range)
				var/turf/T = locate(center.x + dx, center.y + dy, center.z)
				hidden = T && !visible[T]
			if(hidden)
				if(isnull(run_start))
					run_start = dx
			else if(!isnull(run_start))
				strips += make_los_strip(run_start, dy, dx - run_start)
				run_start = null
	return strips

/client
	var/atom/movable/los_cull_mover
	var/image/los_cull_image
	var/turf/los_cull_turf
	var/los_cull_range = 0
	var/turf/look_far_target
	var/turf/look_far_origin
	var/mob/look_far_owner

/client/proc/look_far_active()
	if(!look_far_target)
		return FALSE
	if(mob != look_far_owner || get_turf(mob) != look_far_origin || !isliving(mob) || mob.incapacitated() || eye != look_far_target)
		if(mob)
			mob.reset_view()
		else
			look_far_target = null
			look_far_origin = null
			look_far_owner = null
		return FALSE
	return TRUE

/mob/proc/LookFarClickOn(atom/target)
	if(!client || !isliving(src) || isAI(src) || incapacitated() || !isturf(loc) || machine || eyeobj || client.adminobs)
		return FALSE
	var/mob/living/viewer = src
	if(viewer.z_eye)
		return FALSE
	var/turf/destination = get_turf(target)
	var/turf/origin = get_turf(src)
	if(!destination || destination.z != origin.z)
		return FALSE
	if(destination == origin || destination == client.look_far_target)
		reset_view()
		return TRUE
	if(client.eye != src && !client.look_far_active())
		return FALSE
	var/range = Clamp(ceil(max(client.last_view_x_dim, client.last_view_y_dim) / 2), 7, LOS_CULL_MAX_RANGE)
	if(!(destination in view(range, src)))
		return FALSE
	client.look_far_target = destination
	client.look_far_origin = origin
	client.look_far_owner = src
	client.perspective = EYE_PERSPECTIVE
	client.eye = destination
	client.update_opacity_image()
	client.update_cull_mask(TRUE)
	return TRUE

/client/proc/create_cull_mask()
	if(!los_cull_image)
		los_cull_mover = new
		los_cull_mover.animate_movement = NO_STEPS
		los_cull_mover.mouse_opacity = 0
		los_cull_image = image(loc = los_cull_mover)
		los_cull_image.plane = SHADOWCASTING_PLANE
		los_cull_image.mouse_opacity = 0
		los_cull_image.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
	// mob/Login() wipes client.images, so re-add every time
	images |= los_cull_image
	update_cull_mask(TRUE)

/client/proc/update_cull_mask(force = FALSE)
	update_spacecraft_camera()
	if(!los_cull_image)
		return
	var/looking_far = look_far_active()
	var/turf/center = get_turf(eye)
	if(!center || !mob || shadowcasting_enabled() || isAI(mob) || (mob.sight & (SEE_TURFS|SEE_OBJS|SEE_MOBS)))
		if(los_cull_turf)
			los_cull_image.vis_contents.Cut()
			los_cull_turf = null
		return
	var/range = Clamp(ceil(max(last_view_x_dim, last_view_y_dim) / 2), 7, LOS_CULL_MAX_RANGE)
	if(!force && center == los_cull_turf && range == los_cull_range)
		return
	los_cull_turf = center
	los_cull_range = range
	los_cull_mover.loc = center
	los_cull_image.vis_contents = get_los_cull_strips(center, range, mob, looking_far)

/mob/Login()
	. = ..()
	if(client)
		client.create_opacity_image()
		client.create_cull_mask()

/mob/forceMove()
	. = ..()
	if(client)
		client.update_opacity_image()
		client.update_cull_mask()

/mob/Move()
	var/client/viewer = client
	if(viewer)
		if(!viewer.los_move_depth)
			viewer.los_move_origin = get_turf(src)
			viewer.sync_los_camera_glide()
		viewer.los_move_depth++
	. = ..()
	if(viewer)
		viewer.los_move_depth--
		// Diagonal movement calls Move recursively for its cardinal legs. Only
		// submit the final journey, even when one leg was blocked.
		if(!viewer.los_move_depth)
			if(viewer == client && get_turf(src) != viewer.los_move_origin)
				viewer.update_opacity_image(TRUE)
				viewer.update_cull_mask()
			viewer.los_move_origin = null

// Picks up sight flag and lighting changes (mesons, thermals, lights toggling) while standing still.
/mob/living/Life()
	. = ..()
	if(client)
		client.update_opacity_image()
		client.update_cull_mask(TRUE)

#undef SHADOWCAST_RANGE
#undef LOS_CULL_MAX_RANGE
