#define SHADOWCAST_RANGE 7
#define SHADOWCAST_MIN_FADE 0.5
#define SHADOWCAST_MAX_FADE 20
#define SHADOWCAST_DOOR_FADE 2

var/global/list/los_dither_icons = list()

/proc/get_los_dither_icon(coverage)
	var/key = "[coverage]"
	if(los_dither_icons[key])
		return los_dither_icons[key]
	var/icon/pattern = icon(get_solid_white_icon())
	pattern.DrawBox(null, 1, 1, 32, 32)
	var/list/order = list(0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5)
	for(var/y in 1 to 32)
		for(var/x in 1 to 32)
			var/index = ((y - 1) % 4) * 4 + ((x - 1) % 4) + 1
			if(order[index] < coverage)
				pattern.DrawBox("#FFFFFF", x, y, x, y)
	los_dither_icons[key] = pattern
	return pattern

var/global/enhanced_los_enabled = TRUE

/turf
	var/shadowcast_inview
	var/shadowcast_considered
	var/shadowcasting_initialized = FALSE
	var/list/shadowcasting_overlays = list()
	var/list/shadowcasting_occluders = list()

/turf/New()
	. = ..()
	if(shadowcasting_controller.initialized)
		shadowcast_queue_invalidate(src)

/turf/proc/update_shadowcasting_overlays()
	create_shadowcast_overlays(src)
	shadowcasting_initialized = TRUE

var/global/list/shadowcast_dirty_centers = list()

/// Queues cache invalidation for every turf whose shadow geometry could include T.
/proc/shadowcast_queue_invalidate(turf/T)
	if(!enhanced_los_enabled || !shadowcasting_controller.initialized || !istype(T))
		return
	if(!shadowcast_dirty_centers.len)
		spawn(1)
			shadowcast_process_invalidations()
	shadowcast_dirty_centers[T] = TRUE

/proc/shadowcast_process_invalidations()
	set background = 1
	var/list/centers = shadowcast_dirty_centers
	shadowcast_dirty_centers = list()
	var/reach = SHADOWCAST_RANGE + 2
	for(var/turf/C as anything in centers)
		if(QDELETED(C))
			continue
		for(var/turf/T as anything in block(locate(max(C.x - reach, 1), max(C.y - reach, 1), C.z), locate(min(C.x + reach, world.maxx), min(C.y + reach, world.maxy), C.z)))
			T.shadowcasting_initialized = FALSE
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

/proc/create_shadowcast_overlays(turf/locturf)
	var/vrange = SHADOWCAST_RANGE
	var/moveid = ++shadowcast_generation
	var/list/new_triangles = list()
	var/list/new_occluders = list()
	FOR_DVIEW(var/turf/T, vrange, locturf, INVISIBILITY_MAXIMUM)
		T.shadowcast_inview = moveid
		if(T.opaque_counter)
			new_occluders += make_los_occluder(T.x - locturf.x, T.y - locturf.y)
	END_FOR_DVIEW

	var/list/vturfsordered = list()
	for(var/I in 1 to vrange + 1)
		for(var/J in 1 to I)
			vturfsordered += locate(locturf.x + I - J, locturf.y - J, locturf.z)
			vturfsordered += locate(locturf.x - I + J, locturf.y + J, locturf.z)
			vturfsordered += locate(locturf.x + J, locturf.y + I - J, locturf.z)
			vturfsordered += locate(locturf.x - J, locturf.y - I + J, locturf.z)

	var/list/low_triangles = list()
	for(var/turf/T in vturfsordered)
		if(T.shadowcast_inview != moveid || !T.opaque_counter || T.shadowcast_considered == moveid)
			continue
		var/odx = T.x - locturf.x
		var/ody = T.y - locturf.y
		var/dx = odx * world.icon_size
		var/dy = ody * world.icon_size
		var/signx = dx >= 0 ? 1 : -1
		var/signy = dy >= 0 ? 1 : -1
		var/zx = dx == 0
		var/zy = dy == 0
		var/distance = abs(odx) + abs(ody)
		var/udir = dy >= 0 ? NORTH : SOUTH
		var/rdir = dx >= 0 ? EAST : WEST
		var/width = 0
		var/height = 0
		if(zx || zy)
			width = 1
			height = 1
			if(zx)
				var/turf/CT = get_step(T, EAST)
				while(CT && CT.opaque_counter && abs(CT.x - locturf.x) < vrange + 2)
					CT.shadowcast_considered = moveid
					width++
					CT = get_step(CT, EAST)
				CT = get_step(T, WEST)
				while(CT && CT.opaque_counter && abs(CT.x - locturf.x) < vrange + 2)
					CT.shadowcast_considered = moveid
					width++
					dx -= world.icon_size
					CT = get_step(CT, WEST)
				CT = get_step(T, dy > 0 ? SOUTH : NORTH)
				if(CT && CT.opaque_counter)
					continue
				CT = T
				while(CT && abs(CT.y - locturf.y))
					CT.shadowcast_considered = moveid
					CT = get_step(CT, udir)
			if(zy)
				var/turf/CT = get_step(T, NORTH)
				while(CT && CT.opaque_counter && abs(CT.y - locturf.y) < vrange + 2)
					CT.shadowcast_considered = moveid
					height++
					CT = get_step(CT, NORTH)
				CT = get_step(T, SOUTH)
				while(CT && CT.opaque_counter && abs(CT.y - locturf.y) < vrange + 2)
					CT.shadowcast_considered = moveid
					height++
					dy -= world.icon_size
					CT = get_step(CT, SOUTH)
				CT = get_step(T, dx > 0 ? WEST : EAST)
				if(CT && CT.opaque_counter)
					continue
				CT = T
				while(CT && abs(CT.x - locturf.x))
					CT.shadowcast_considered = moveid
					CT = get_step(CT, rdir)
		else
			var/turf/CT = T
			while(CT && CT.opaque_counter && abs(CT.x - locturf.x) < vrange + 2)
				CT.shadowcast_considered = moveid
				width++
				CT = get_step(CT, rdir)
			CT = T
			while(CT && CT.opaque_counter && abs(CT.y - locturf.y) < vrange + 2)
				CT.shadowcast_considered = moveid
				height++
				CT = get_step(CT, udir)

		var/top = dy - signy * 16 + signy * world.icon_size * height
		var/bottom = dy - signy * 16
		var/left = dx - signx * 16
		var/right = dx - signx * 16 + signx * world.icon_size * width
		var/fac = world.icon_size / distance
		if(zy)
			low_triangles += new /datum/triangle(left, top, left, bottom, left * fac, bottom * fac)
			low_triangles += new /datum/triangle(left * fac, top * fac, left, top, left * fac, bottom * fac)
		else if(zx)
			low_triangles += new /datum/triangle(right, bottom, left, bottom, left * fac, bottom * fac)
			low_triangles += new /datum/triangle(left * fac, bottom * fac, right, bottom, right * fac, bottom * fac)
		else
			new_triangles += make_triangle_image(right, top, left, top, left * fac, top * fac)
			new_triangles += make_triangle_image(right, top, right, bottom, right * fac, bottom * fac)
			new_triangles += make_triangle_image(left * fac, top * fac, right, top, right * fac, bottom * fac)

	for(var/datum/triangle/tri as anything in low_triangles)
		new_triangles += make_triangle_image(tri.x1, tri.y1, tri.x2, tri.y2, tri.x3, tri.y3)
		qdel(tri)
	locturf.shadowcasting_overlays = new_triangles
	locturf.shadowcasting_occluders = new_occluders

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

/atom/movable/los_occluder
	name = ""
	plane = SHADOWCASTING_REFLECTOR_PLANE
	mouse_opacity = 0
	opacity = 0

/atom/movable/los_occluder/New(dx, dy)
	icon = get_solid_white_icon()
	pixel_x = dx * world.icon_size
	pixel_y = dy * world.icon_size
	tag = "los-occluder-[dx]-[dy]"

/proc/make_los_occluder(dx, dy)
	var/atom/movable/los_occluder/O = locate("los-occluder-[dx]-[dy]")
	if(!O)
		O = new(dx, dy)
	return O

/client
	var/list/image/los_shadows
	var/list/image/los_masks
	var/list/atom/movable/los_movers
	var/los_current = 1
	var/los_transition_id = 0
	var/turf/last_shadow_turf = null
	var/shadowcast_force = FALSE

/client/proc/shadowcasting_enabled()
	if(!enhanced_los_enabled || !isliving(mob) || isAI(mob))
		return FALSE
	// Remote viewing (cameras etc.) moves the eye away from the body
	if(get_turf(eye) != get_turf(mob))
		return FALSE
	if(mob.sight & (SEE_TURFS|SEE_OBJS|SEE_MOBS))
		return FALSE
	return TRUE

/client/proc/los_set_coverage(index, coverage)
	var/image/shadow = los_shadows[index]
	var/image/mask = los_masks[index]
	if(coverage == 0)
		shadow.alpha = 0
		mask.alpha = 0
		return
	shadow.alpha = 255
	mask.alpha = 255
	if(coverage == 16)
		shadow.filters = null
		mask.filters = null
	else
		var/icon/pattern = get_los_dither_icon(coverage)
		shadow.filters = list(filter(type = "alpha", icon = pattern))
		mask.filters = list(filter(type = "alpha", icon = pattern))

/client/proc/create_opacity_image()
	if(!enhanced_los_enabled)
		return
	if(!los_shadows)
		los_shadows = list()
		los_masks = list()
		los_movers = list()
		for(var/i in 1 to 2)
			var/atom/movable/mover = new
			mover.animate_movement = NO_STEPS
			mover.vis_flags = VIS_INHERIT_PLANE
			mover.mouse_opacity = 0
			los_movers += mover
			var/image/shadow = image(loc = mover)
			shadow.plane = SHADOWCASTING_PLANE
			shadow.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
			los_shadows += shadow
			var/image/mask = image(loc = mover)
			mask.plane = SHADOWCASTING_REFLECTOR_PLANE
			mask.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
			los_masks += mask
	// mob/Login() wipes client.images, so re-add every time
	images |= los_shadows
	images |= los_masks
	++los_transition_id
	for(var/i in 1 to 2)
		los_set_coverage(i, 0)
	last_shadow_turf = null
	update_opacity_image()

/client/proc/clear_opacity_image()
	++los_transition_id
	for(var/i in 1 to 2)
		los_set_coverage(i, 0)
		var/image/shadow = los_shadows[i]
		var/image/mask = los_masks[i]
		shadow.vis_contents.Cut()
		mask.vis_contents.Cut()
	last_shadow_turf = null

/client/proc/advance_los_transition(id, old_index, new_index, step)
	if(id != los_transition_id || !enhanced_los_enabled)
		return
	if(step <= 4)
		los_set_coverage(new_index, step * 4)
	else
		los_set_coverage(old_index, (8 - step) * 4)
	if(step == 8)
		var/image/shadow = los_shadows[old_index]
		var/image/mask = los_masks[old_index]
		shadow.vis_contents.Cut()
		mask.vis_contents.Cut()

/client/proc/update_opacity_image()
	if(!los_shadows)
		return
	var/turf/T = get_turf(mob)
	if(!T || !shadowcasting_enabled())
		if(last_shadow_turf)
			clear_opacity_image()
		return
	if(T == last_shadow_turf && T.shadowcasting_initialized && !shadowcast_force)
		return
	if(!T.shadowcasting_initialized)
		T.update_shadowcasting_overlays()

	var/fade = 0
	var/turf/from = last_shadow_turf
	if(from && from.z == T.z && get_dist(from, T) == 1)
		fade = Clamp((world.icon_size / max(mob.glide_size, 1)) * world.tick_lag, SHADOWCAST_MIN_FADE, SHADOWCAST_MAX_FADE)
	else if(shadowcast_force && from == T)
		fade = SHADOWCAST_DOOR_FADE
	shadowcast_force = FALSE
	++los_transition_id
	var/old_index = los_current
	var/new_index = 3 - old_index
	if(fade && from)
		los_set_coverage(old_index, 16)
	los_set_coverage(new_index, 0)
	var/atom/movable/mover = los_movers[new_index]
	mover.loc = T
	var/image/shadow = los_shadows[new_index]
	var/image/mask = los_masks[new_index]
	shadow.loc = mover
	mask.loc = mover
	shadow.vis_contents = T.shadowcasting_overlays
	mask.vis_contents = T.shadowcasting_occluders
	los_current = new_index
	if(fade && from)
		var/id = los_transition_id
		var/interval = max(1, fade / 8)
		for(var/step in 1 to 8)
			addtimer(CALLBACK(src, .proc/advance_los_transition, id, old_index, new_index, step), interval * step, TIMER_CLIENT_TIME)
	else
		los_set_coverage(new_index, 16)
		los_set_coverage(old_index, 0)
	last_shadow_turf = T

/mob/Login()
	. = ..()
	if(client)
		client.create_opacity_image()

/mob/forceMove()
	. = ..()
	if(client)
		client.update_opacity_image()

/mob/Move()
	. = ..()
	if(client)
		client.update_opacity_image()

// Picks up sight flag changes (mesons, thermals) while standing still.
/mob/living/Life()
	. = ..()
	if(client)
		client.update_opacity_image()

#undef SHADOWCAST_RANGE
#undef SHADOWCAST_MIN_FADE
#undef SHADOWCAST_MAX_FADE
#undef SHADOWCAST_DOOR_FADE
