#define SHADOWCAST_RANGE 7
#define LOS_CULL_MAX_RANGE 20

// Temporarily disabled: use native tile visibility until smooth LOS is revisited.
var/global/enhanced_los_enabled = FALSE
#ifdef ARTEMIS_LOS_PREVIEW
var/global/los_preview_legacy_images = FALSE
var/global/los_preview_legacy_corner_promotion = FALSE
var/global/los_preview_legacy_wall_motion = FALSE
#endif

/turf
	var/shadowcast_inview
	var/shadowcast_lit
	var/shadowcast_considered
	var/shadowcasting_initialized = FALSE
	var/shadowcasting_range = 0
	// create_shadowcast_overlays() fills these on first use. Most map turfs
	// never become a viewer's center, so do not allocate six empty lists each.
	var/list/shadowcasting_edges
	var/list/shadowcasting_overlays
	var/list/shadowcasting_occluders
	var/list/shadowcasting_visible_turfs
	var/list/shadowcasting_visible_walls
	var/list/shadowcasting_mask_walls

/turf/New()
	. = ..()
	if(!isnull(telemetry_structural_dirty))
		telemetry_queue_structural_turf(src)
	if(shadowcasting_controller.initialized)
		shadowcast_queue_invalidate(src)

/turf/proc/update_shadowcasting_overlays(view_range = SHADOWCAST_RANGE)
	create_shadowcast_overlays(src, view_range)
	shadowcasting_range = view_range
	shadowcasting_initialized = TRUE

var/global/list/shadowcast_dirty_centers = list()
var/global/list/los_wall_face_bounds = list()

/// Queues cache invalidation for every turf whose shadow geometry could include T.
/proc/shadowcast_queue_invalidate(turf/T)
	if(!shadowcasting_controller.initialized || !istype(T))
		return
	los_wall_face_bounds.Cut()
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
				if((dx && O.pixel_x * dx >= 16) || (dy && O.pixel_y * dy >= 16))
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
	var/list/mask_walls = list()
	FOR_DVIEW(var/turf/T, vrange, locturf, INVISIBILITY_MAXIMUM)
		T.shadowcast_inview = moveid
		visible_turfs[T] = TRUE
	END_FOR_DVIEW
	for(var/turf/T as anything in block(locate(max(locturf.x - vrange, 1), max(locturf.y - vrange, 1), locturf.z), locate(min(locturf.x + vrange, world.maxx), min(locturf.y + vrange, world.maxy), locturf.z)))
		if(!T.opaque_counter || T == locturf)
			continue
		if(T.shadowcast_inview == moveid)
			visible_walls += T
		var/include_mask = TRUE
#ifdef ARTEMIS_LOS_PREVIEW
		if(los_preview_legacy_wall_motion) include_mask = T.shadowcast_inview == moveid
#endif
		if(include_mask)
			mask_walls += T
			occluders += make_los_occluder(T.x - locturf.x, T.y - locturf.y, los_wall_protection_depth(T, locturf))
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
	locturf.shadowcasting_mask_walls = mask_walls

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

/atom/movable/los_occluder/New(dx, dy, new_tag, depth)
	icon = get_solid_white_icon()
	pixel_x = dx * world.icon_size
	pixel_y = dy * world.icon_size
	layer = (depth || los_wall_mask_depth(dx, dy)) + 0.001
	tag = new_tag

// Along a ray through grid cells, Manhattan distance increases at every cell
// boundary. Draw each wall above its own shadow, and below nearer wall shadows.
/proc/los_wall_mask_depth(dx, dy)
	return 1 + (2 * LOS_CULL_MAX_RANGE + 4 - abs(dx) - abs(dy)) * 0.01

// Trace open cell interiors. At an exact grid corner, advance both axes so a
// wall touching only that point cannot hide an exposed neighbouring wall cap.
/proc/los_floor_ray_visible(turf/viewer, turf/target, turf/protected_wall, view_x, view_y)
	if(!target || target.z != viewer.z || target.opaque_counter) return FALSE
	return los_wall_point_visible(viewer, target.x, target.y, protected_wall, FALSE, view_x, view_y)

/proc/los_same_wall_run(turf/first, turf/second)
	if(first.z != second.z || (first.x != second.x && first.y != second.y)) return FALSE
	var/direction = get_dir(first, second)
	var/turf/cell = first
	for(var/i in 1 to 2 * LOS_CULL_MAX_RANGE + 4)
		if(!cell?.opaque_counter) return FALSE
		if(cell == second) return TRUE
		cell = get_step(cell, direction)
	return FALSE

/proc/los_wall_cap_neighbor(turf/blocker, turf/wall, include_run)
	return wall && (get_dist(blocker, wall) <= 1 || (include_run && los_same_wall_run(blocker, wall)))

/proc/los_wall_point_visible(turf/viewer, target_x, target_y, turf/protected_wall, ignore_adjacent = FALSE, view_x, view_y)
	if(isnull(view_x)) view_x = viewer.x
	if(isnull(view_y)) view_y = viewer.y
	var/dx = target_x - view_x
	var/dy = target_y - view_y
	var/step_x = dx > 0 ? 1 : (dx < 0 ? -1 : 0)
	var/step_y = dy > 0 ? 1 : (dy < 0 ? -1 : 0)
	var/delta_x = dx ? 1 / abs(dx) : 1e9
	var/delta_y = dy ? 1 / abs(dy) : 1e9
	var/cell_x = round(view_x + 0.5)
	var/cell_y = round(view_y + 0.5)
	var/next_x = dx ? (cell_x + step_x * 0.5 - view_x) / dx : 1e9
	var/next_y = dy ? (cell_y + step_y * 0.5 - view_y) / dy : 1e9
	for(var/i in 1 to 2 * LOS_CULL_MAX_RANGE + 4)
		// A surface endpoint belongs to the wall being tested; only the open
		// segment before that endpoint can be blocked by another wall.
		if(min(next_x, next_y) >= 1 - 0.000001) return TRUE
		if(abs(next_x - next_y) < 0.000001)
			var/turf/side_x = locate(cell_x + step_x, cell_y, viewer.z)
			var/turf/side_y = locate(cell_x, cell_y + step_y, viewer.z)
			// Only a cap touching its own neighbouring wall may use this corner.
			// A remote wall cannot peek through a nearer blocker's silhouette tip.
			if(side_x?.opaque_counter && !los_wall_cap_neighbor(side_x, protected_wall, ignore_adjacent)) return FALSE
			if(side_y?.opaque_counter && !los_wall_cap_neighbor(side_y, protected_wall, ignore_adjacent)) return FALSE
			cell_x += step_x
			cell_y += step_y
			next_x += delta_x
			next_y += delta_y
		else if(next_x < next_y)
			cell_x += step_x
			next_x += delta_x
		else
			cell_y += step_y
			next_y += delta_y
		var/turf/cell = locate(cell_x, cell_y, viewer.z)
		if(!cell) return FALSE
		if(cell.opaque_counter && (!ignore_adjacent || !los_wall_cap_neighbor(cell, protected_wall, TRUE))) return FALSE
	return FALSE

// Preserve an adjoining cap as a complete tile, but do not extend that
// exemption across a shadow from a separate wall further along the sightline.
/proc/los_wall_tile_exposed(turf/wall, turf/viewer, view_x, view_y)
	for(var/offset_x in list(-0.5, 0.5))
		for(var/offset_y in list(-0.5, 0.5))
			if(!los_wall_point_visible(viewer, wall.x + offset_x, wall.y + offset_y, wall, TRUE, view_x, view_y)) return FALSE
	return TRUE

/proc/los_wall_protection_depth(turf/wall, turf/viewer, protect_exposed = TRUE, view_x, view_y)
	if(isnull(view_x)) view_x = viewer.x
	if(isnull(view_y)) view_y = viewer.y
	var/depth = 0
	var/check_full_tile = TRUE
#ifdef ARTEMIS_LOS_PREVIEW
	check_full_tile = !los_preview_legacy_corner_promotion
#endif
	if(protect_exposed && check_full_tile && !los_wall_tile_exposed(wall, viewer, view_x, view_y)) protect_exposed = FALSE
	if(protect_exposed && view_x != wall.x && view_y != wall.y)
		var/front_x = wall.x + (view_x > wall.x ? 1 : -1)
		var/front_y = wall.y + (view_y > wall.y ? 1 : -1)
		var/turf/side_x = locate(front_x, wall.y, wall.z)
		var/turf/side_y = locate(wall.x, front_y, wall.z)
		// Inside an L-shaped wall, the corner tile borders the visible room only
		// diagonally. Its two connected wall neighbours must not erase that cap.
		if(side_x?.opaque_counter && side_y?.opaque_counter && los_floor_ray_visible(viewer, locate(front_x, front_y, wall.z), wall, view_x, view_y)) return 2
	for(var/direction in GLOB.cardinal)
		if((direction == NORTH && view_y <= wall.y) || (direction == SOUTH && view_y >= wall.y) || (direction == EAST && view_x <= wall.x) || (direction == WEST && view_x >= wall.x)) continue
		var/turf/front = get_step(wall, direction)
		if(!front || front.opaque_counter) continue
		// This is the first wall bordering a visible floor, including a diagonal
		// cap. Preserve its entire authored tile, not a triangle cut by its peers.
		if(protect_exposed && los_floor_ray_visible(viewer, front, wall, view_x, view_y)) return 2
		depth = max(depth, los_wall_face_depth(wall, direction, view_x, view_y))
	return depth || los_wall_mask_depth(wall.x - view_x, wall.y - view_y)

// A straight, exposed face is one surface. Adjacent tiles on that surface must
// not carve diagonal notches into one another's wall mask.
/proc/los_wall_face_depth(turf/wall, direction, eye_x, eye_y)
	var/horizontal = direction & (NORTH|SOUTH)
	var/key = "\ref[wall]:[direction]"
	var/list/bounds = los_wall_face_bounds[key]
	if(!bounds)
		var/low = horizontal ? wall.x : wall.y
		var/high = low
		for(var/side in (horizontal ? list(WEST, EAST) : list(SOUTH, NORTH)))
			var/turf/end = wall
			for(var/i in 1 to LOS_CULL_MAX_RANGE * 2)
				var/turf/next = get_step(end, side)
				if(!next?.opaque_counter || get_step(next, direction)?.opaque_counter) break
				end = next
			var/coordinate = horizontal ? end.x : end.y
			low = min(low, coordinate)
			high = max(high, coordinate)
		bounds = list(low, high)
		los_wall_face_bounds[key] = bounds
	var/eye_along_face = horizontal ? eye_x : eye_y
	var/closest = Clamp(eye_along_face, bounds[1], bounds[2])
	return horizontal ? los_wall_mask_depth(closest - eye_x, wall.y - eye_y) : los_wall_mask_depth(wall.x - eye_x, closest - eye_y)

/proc/make_los_occluder(dx, dy, depth)
	var/tag = "los-occluder-solid-[dx]-[dy]-[depth]"
	var/atom/movable/los_occluder/O = locate(tag)
	if(!O)
		O = new(dx, dy, tag, depth)
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
	for(var/i in 1 to 6)
		var/image/I = image('icons/effects/triangle.dmi', wall, "triangle")
		I.plane = i <= 2 ? SHADOWCASTING_PLANE : (i <= 4 ? SHADOWCASTING_GEOMETRY_PLANE : SHADOWCASTING_REFLECTOR_PLANE)
		I.color = "#000000"
		I.mouse_opacity = 0
		I.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
		triangles += I

/datum/los_edge_mesh/proc/anchor(turf/viewer)
	// Every pass must survive the same native visibility decision. Leaving the
	// floor/object rays on their wall while moving only the depth rays to the
	// viewer lets native culling remove one half of the composite mid-step.
	for(var/image/I in triangles)
		I.loc = viewer
		I.pixel_w = (wall.x - viewer.x) * world.icon_size
		I.pixel_z = (wall.y - viewer.y) * world.icon_size

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
	for(var/i in 1 to triangles.len)
		var/image/I = triangles[i]
		var/vertex = (i - 1) % 2 + 1
		var/depth = i >= 5 ? los_wall_face_depth(wall, direction, eye_x, eye_y) : I.layer
		if(intermediate)
			var/mid_depth = i >= 5 ? los_wall_face_depth(wall, direction, start_eye_x + (eye_x - start_eye_x) * crossing, start_eye_y + (eye_y - start_eye_y) * crossing) : I.layer
			animate(I, transform = intermediate[vertex], layer = mid_depth, time = duration * crossing, flags = ANIMATION_LINEAR_TRANSFORM)
			animate(I, transform = matrices[vertex], layer = depth, time = duration * (1 - crossing), flags = ANIMATION_LINEAR_TRANSFORM | ANIMATION_CONTINUE)
		else if(duration)
			// Interruptions continue from the client's interpolated transform.
			animate(I, transform = matrices[vertex], layer = depth, time = duration, flags = ANIMATION_LINEAR_TRANSFORM)
		else
			animate(I)
			I.transform = matrices[vertex]
			I.layer = depth
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
	var/list/los_wall_images = list()
	var/list/los_retained_walls = list()
	var/list/los_retained_appearances = list()
	var/los_wall_motion_generation = 0
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
	los_wall_motion_generation++
	for(var/atom/A in los_retained_walls)
		var/image/I = los_retained_walls[A]
		images -= I
		qdel(I)
	los_retained_walls.Cut()
	los_retained_appearances.Cut()
	for(var/turf/W in los_wall_images)
		var/image/I = los_wall_images[W]
		images -= I
		qdel(I)
	los_wall_images.Cut()
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

/client/proc/update_wall_depth_masks(turf/T, view_x, view_y)
	for(var/turf/W in los_wall_images - T.shadowcasting_mask_walls)
		var/image/I = los_wall_images[W]
		images -= I
		los_wall_images -= W
		qdel(I)
	for(var/i in 1 to T.shadowcasting_mask_walls.len)
		var/turf/W = T.shadowcasting_mask_walls[i]
		var/atom/movable/los_occluder/mask = T.shadowcasting_occluders[i]
		var/image/I = los_wall_images[W]
		if(!I)
			I = image(icon = get_solid_white_icon(), loc = T)
			I.plane = SHADOWCASTING_REFLECTOR_PLANE
			I.mouse_opacity = 0
			I.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
			los_wall_images[W] = I
			images += I
		var/depth = isnull(view_x) ? mask.layer : los_wall_protection_depth(W, T, TRUE, view_x, view_y) + 0.001
		if(abs(I.layer - depth) > 0.000001)
			I.layer = depth
		I.loc = T
		// Ground offsets would reintroduce SIDE_MAP's positional sorting.
		I.pixel_w = mask.pixel_x
		I.pixel_z = mask.pixel_y

// Native tile culling can remove a wall before a pixel glide has reached it.
// Keep only its physical appearance in the world passes; the same geometric
// LOS still hides rear faces. No mobs or nonopaque contents are copied.
/client/proc/update_retained_los_walls(turf/T)
	var/list/wanted = list()
	var/retain = TRUE
#ifdef ARTEMIS_LOS_PREVIEW
	retain = !los_preview_legacy_wall_motion
#endif
	if(retain)
		var/list/current = los_motion.position()
		for(var/turf/W in T.shadowcasting_mask_walls)
			if(T.shadowcasting_visible_turfs[W]) continue
			// Retain connecting exposed caps only; remote rooms need no copies.
			if(los_wall_protection_depth(W, T) < 2 && los_wall_protection_depth(W, T, TRUE, current[1], current[2]) < 2) continue
			for(var/atom/A in los_wall_render_sources(W, los_hidden_mount_images)) wanted[A] = TRUE
	for(var/atom/A in los_retained_walls - wanted)
		var/image/I = los_retained_walls[A]
		images -= I
		los_retained_walls -= A
		los_retained_appearances -= A
		qdel(I)
	for(var/atom/A in wanted)
		var/image/I = los_retained_walls[A]
		if(!I)
			I = image(loc = T)
			los_retained_walls[A] = I
			images += I
		if(los_retained_appearances[A] != A.appearance)
			I.appearance = los_retained_wall_appearance(A)
			los_retained_appearances[A] = A.appearance
		I.loc = T
		I.pixel_x = I.pixel_y = 0
		I.pixel_w = (A.x - T.x) * world.icon_size + A.pixel_x + A.pixel_w
		I.pixel_z = (A.y - T.y) * world.icon_size + A.pixel_y + A.pixel_z

/proc/los_wall_render_sources(turf/W, list/hidden_mounts)
	var/list/sources = list()
	if(W.opacity && (W.icon || W.overlays.len)) sources += W
	for(var/obj/O in W)
		if(O.opacity && (O.icon || O.overlays.len) && !hidden_mounts?[O]) sources += O
	// Native culling removes the light sample with the wall art. Retain its
	// lighting alongside the art so the retained cap still gets shaded.
	var/atom/movable/lighting_overlay/light = W.lighting_overlay
	if(light)
		sources += light
		if(light.edge_guard) sources += light.edge_guard
		if(light.tile_glow) sources += light.tile_glow
	return sources

/proc/los_retained_wall_appearance(source, physical_plane)
	var/mutable_appearance/MA = new(source)
	if(isnull(physical_plane)) physical_plane = MA.plane
	MA.mouse_opacity = 0
	MA.maptext = null
	MA.render_source = null
	MA.render_target = null
	var/list/physical_overlays = list()
	for(var/part in MA.overlays)
		var/mutable_appearance/O = new(part)
		if(!(O.plane in list(FLOAT_PLANE, DEFAULT_PLANE, physical_plane, WORLD_TERRAIN_SOURCE_PLANE))) continue
		O = los_retained_wall_appearance(O, physical_plane)
		O.plane = FLOAT_PLANE
		physical_overlays += O
	MA.overlays = physical_overlays
	var/list/physical_underlays = list()
	for(var/part in MA.underlays)
		var/mutable_appearance/O = new(part)
		if(!(O.plane in list(FLOAT_PLANE, DEFAULT_PLANE, physical_plane, WORLD_TERRAIN_SOURCE_PLANE))) continue
		O = los_retained_wall_appearance(O, physical_plane)
		O.plane = FLOAT_PLANE
		physical_underlays += O
	MA.underlays = physical_underlays
	return MA

/client/proc/refresh_los_wall_depths(turf/T, view_x, view_y)
	update_wall_depth_masks(T, view_x, view_y)

/client/proc/start_los_wall_glide(turf/T)
	var/generation = ++los_wall_motion_generation
	spawn(0)
		while(generation == los_wall_motion_generation && last_shadow_turf == T && mob)
			var/now = world.time
			var/list/current = los_motion.position(now)
			refresh_los_wall_depths(T, current[1], current[2])
			if(now >= los_motion.ends) break
			sleep(min(los_motion.ends - now, world.tick_lag))

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
		update_retained_los_walls(T)
		return
	if(!T.shadowcasting_initialized || T.shadowcasting_range != view_range)
		T.update_shadowcasting_overlays(view_range)
	update_wall_mount_visibility(T)
	var/turf/from = los_move_origin || last_shadow_turf
	// Clear a completed animation before starting the next one. Replacing every
	// image at this boundary drops whole render passes for a frame on the client.
	// Interrupted glides keep their sequence and interpolated starting point.
	var/finish_animation = allow_glide && world.time >= los_motion.ends
#ifdef ARTEMIS_LOS_PREVIEW
	if(los_preview_legacy_images) finish_animation = FALSE
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
		if(mesh && finish_animation && duration)
			for(var/image/I in mesh.triangles)
				animate(I)
		if(!mesh)
			var/list/edge = T.shadowcasting_edges[key]
			mesh = new(edge[1], edge[2])
			los_meshes[key] = mesh
			mesh.reshape(current_eye[1], current_eye[2], projection)
			images |= mesh.triangles
		// SIDE_MAP sorts different map rows before fractional layers. Keep all
		// depth-mask draws at one anchor, using visual-only w/z offsets, so nearer
		// shadows can cover rear walls without changing their ground sort position.
		mesh.anchor(T)
		// Ray transform and depth share one sequence; per-tick parallel depth
		// changes can replay the transform's base appearance on DreamSeeker.
		mesh.reshape(T.x, T.y, projection, duration, current_eye[1], current_eye[2])
	los_wall_anchor.loc = T
	update_retained_los_walls(T)
	var/continuous_walls = TRUE
#ifdef ARTEMIS_LOS_PREVIEW
	continuous_walls = !los_preview_legacy_wall_motion
#endif
	if(continuous_walls)
		refresh_los_wall_depths(T, current_eye[1], current_eye[2])
	else
		refresh_los_wall_depths(T, T.x, T.y)
	last_shadow_turf = T
	last_shadow_range = view_range
	shadowcast_force = FALSE
	if(continuous_walls)
		start_los_wall_glide(T)

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

// A boundary may be an opaque turf or an opaque object (such as a closed door)
// on a floor. Both expose the same viewer-facing edge to the culling pass.
/proc/los_boundary_face_visible(turf/boundary, turf/viewer, list/visible)
	if(!boundary.opaque_counter || visible[boundary] || (boundary.lighting_overlay && !boundary.lighting_overlay.luminosity))
		return FALSE
	for(var/direction in GLOB.cardinal)
		var/turf/face = get_step(boundary, direction)
		if(!face || face.opaque_counter || !visible[face])
			continue
		if((face.x - boundary.x) * (viewer.x - boundary.x) > 0 || (face.y - boundary.y) * (viewer.y - boundary.y) > 0)
			return TRUE
	return FALSE

/// Black strips over every tile within range that BYOND culls for opacity/darkness, so pixel-offset sprites from visible tiles can't draw over them.
/proc/get_los_cull_strips(turf/center, range, mob/viewer, use_viewer = FALSE)
	var/list/visible = list()
	var/turf/visibility_center = center
	var/visibility_range = range
	if(viewer && isturf(viewer.loc) && (use_viewer || viewer.loc == center))
		visibility_center = get_turf(viewer)
		if(visibility_center != center)
			// Cover the shifted viewport without widening the query on the other axis.
			var/width = 2 * (range + abs(center.x - visibility_center.x)) + 1
			var/height = 2 * (range + abs(center.y - visibility_center.y)) + 1
			visibility_range = "[width]x[height]"
		for(var/turf/T in view(visibility_range, viewer))
			visible[T] = TRUE
	else
		// Remote eyes (cameras etc.) fall back to pure opacity culling
		FOR_DVIEW(var/turf/T, range, center, INVISIBILITY_MAXIMUM)
			visible[T] = TRUE
		END_FOR_DVIEW
	var/list/visible_faces = list()
	FOR_DVIEW(var/turf/wall, visibility_range, visibility_center, INVISIBILITY_MAXIMUM)
		if(los_boundary_face_visible(wall, visibility_center, visible))
			visible_faces[wall] = TRUE
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
