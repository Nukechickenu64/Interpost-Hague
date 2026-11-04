#define DSHADOW_MAX_ALPHA		150
#define DSHADOW_MIN_WEIGHT		0.08
#define DSHADOW_MAX_SHADOWS		3
#define DSHADOW_FLATTEN			0.55
#define DSHADOW_ANIMATE_TIME	3
#define DSHADOW_MASK_STEP		4

var/global/dynamic_shadows_enabled = TRUE
var/global/list/dynamic_shadow_icon_heights = list()
#ifdef ARTEMIS_LOS_PREVIEW
var/global/shadow_preview_legacy_rotation = FALSE
#endif

/atom/movable
	var/casts_dynamic_shadow = FALSE
	var/list/dynamic_shadows
	var/dynamic_shadow_move_depth = 0

/mob/living
	casts_dynamic_shadow = TRUE

/obj/machinery
	casts_dynamic_shadow = TRUE

/obj/structure
	casts_dynamic_shadow = TRUE

// Doors, flat/underfloor and wall-mounted fixtures never cast.
/obj/machinery/door
	casts_dynamic_shadow = FALSE
/obj/machinery/light
	casts_dynamic_shadow = FALSE
/obj/machinery/floor_light
	casts_dynamic_shadow = FALSE
/obj/machinery/camera
	casts_dynamic_shadow = FALSE
/obj/machinery/atmospherics
	casts_dynamic_shadow = FALSE
/obj/machinery/power/area_smes
	casts_dynamic_shadow = FALSE
/obj/machinery/alarm
	casts_dynamic_shadow = FALSE
/obj/machinery/firealarm
	casts_dynamic_shadow = FALSE
/obj/machinery/light_switch
	casts_dynamic_shadow = FALSE
/obj/machinery/button
	casts_dynamic_shadow = FALSE
/obj/machinery/status_display
	casts_dynamic_shadow = FALSE
/obj/machinery/newscaster
	casts_dynamic_shadow = FALSE
/obj/machinery/requests_console
	casts_dynamic_shadow = FALSE
/obj/machinery/hologram
	casts_dynamic_shadow = FALSE
/obj/machinery/navbeacon
	casts_dynamic_shadow = FALSE
/obj/structure/door_assembly
	casts_dynamic_shadow = FALSE
/obj/structure/inflatable/door
	casts_dynamic_shadow = FALSE
/obj/structure/droppod_door
	casts_dynamic_shadow = FALSE
/obj/structure/window
	casts_dynamic_shadow = FALSE
/obj/structure/sign
	casts_dynamic_shadow = FALSE
/obj/structure/extinguisher_cabinet
	casts_dynamic_shadow = FALSE
/obj/structure/disposalpipe
	casts_dynamic_shadow = FALSE
/obj/structure/lattice
	casts_dynamic_shadow = FALSE
/obj/structure/catwalk
	casts_dynamic_shadow = FALSE

/atom/movable/proc/should_cast_dynamic_shadow()
	if(!dynamic_shadows_enabled || !casts_dynamic_shadow || !isturf(loc) || (!icon && !overlays.len))
		return FALSE
	if(invisibility || alpha < 50 || layer < TABLE_LAYER)
		return FALSE
	// Wall-mounted things are pixel-shifted onto the neighbouring wall
	if(abs(pixel_x) >= 16 || abs(pixel_y) >= 16)
		return FALSE
	return TRUE

/atom/movable/proc/update_dynamic_shadow(moving = FALSE)
	if(!should_cast_dynamic_shadow())
		clear_dynamic_shadows()
		return

	var/turf/T = loc
	var/ox = T.x + pixel_x / world.icon_size
	var/oy = T.y + pixel_y / world.icon_size
	// Rank the light actually reaching this tile, including cones, color and
	// occlusion. Range alone used to cast shadows from lamps aimed elsewhere.
	// Each entry is list(weight, dx, dy, dist, source).
	var/list/casts = list()
	for(var/datum/light_source/L as anything in T.affecting_lights)
		if(L.destroyed || !L.applied || L.top_atom == src)
			continue
		var/turf/LT = L.source_turf
		if(!LT || LT.z != T.z)
			continue
		var/list/light_center = L.dynamic_shadow_center()
		var/dx = ox - light_center[1]
		var/dy = oy - light_center[2]
		var/dist = sqrt(dx * dx + dy * dy)
		if(dist < 0.3)
			continue
		var/weight = L.dynamic_shadow_tile_weight(T)
		if(weight < DSHADOW_MIN_WEIGHT)
			continue
		var/insert_at = casts.len + 1
		for(var/i in 1 to casts.len)
			var/list/other = casts[i]
			if(weight > other[1])
				insert_at = i
				break
		if(insert_at > DSHADOW_MAX_SHADOWS)
			continue
		casts.Insert(insert_at, null)
		casts[insert_at] = list(weight, dx, dy, dist, L)
		if(casts.len > DSHADOW_MAX_SHADOWS)
			casts.len = DSHADOW_MAX_SHADOWS

	var/count = min(casts.len, DSHADOW_MAX_SHADOWS)
	if(!count)
		clear_dynamic_shadows()
		return
	LAZYINITLIST(dynamic_shadows)
	// Keep each silhouette attached to its light when two lights trade rank.
	// Reusing by rank made shadows sweep across the actor at that boundary.
	var/list/retired = dynamic_shadows.Copy()

	var/half_height = get_dynamic_shadow_icon_height() / 2
	// While moving, finish the reshape exactly when the glide finishes so shadow and owner stay in step
	var/anim_time = moving ? (world.icon_size / max(glide_size, 1)) * world.tick_lag : DSHADOW_ANIMATE_TIME
	for(var/i in 1 to count)
		var/list/cast = casts[i]
		var/datum/light_source/L = cast[5]
		var/atom/movable/dynamic_shadow/S = dynamic_shadows[L]
		if(!S)
			S = new /atom/movable/dynamic_shadow(null, src)
			dynamic_shadows[L] = S
		retired -= L
		S.sync_position()
		S.copy_owner_appearance(dynamic_shadow_sprite_dir(cast[2], cast[3]))
		var/dist = cast[4]
		var/shadow_length = Clamp(0.3 + dist * 0.25, 0.4, 1.4)
		var/matrix/M = matrix(transform) * get_dynamic_shadow_projection(cast[2], cast[3], dist, shadow_length, half_height)
		S.update_light_mask(L, M, cast[2], cast[3], dist)
		S.set_projection(M, round(DSHADOW_MAX_ALPHA * min(cast[1], 1)), anim_time)
	for(var/L in retired)
		qdel(dynamic_shadows[L])
		dynamic_shadows -= L

// The width axis must rotate with the projected height axis. Keeping width
// horizontal made the two axes almost parallel under an east/west light.
/proc/dynamic_shadow_projection(dx, dy, distance, shadow_length, half_height)
	var/along_x = dx / distance * shadow_length
	var/along_y = dy / distance * shadow_length * DSHADOW_FLATTEN
	var/across_x = -dy / distance * 0.9
	var/across_y = dx / distance * 0.9 * DSHADOW_FLATTEN
	return matrix(across_x, along_x, along_x * half_height, across_y, along_y, along_y * half_height - half_height)

// Objects, nonhuman casters and prone humans use the original flatter shear.
/atom/movable/proc/get_dynamic_shadow_projection(dx, dy, distance, shadow_length, half_height)
	var/shear = dx / distance * shadow_length
	var/height = dy / distance * shadow_length * DSHADOW_FLATTEN
	if(abs(height) < 0.2)
		height = height < 0 ? -0.2 : 0.2
	return matrix(0.9, shear, shear * half_height, 0, height, height * half_height - half_height)

/mob/living/carbon/human/get_dynamic_shadow_projection(dx, dy, distance, shadow_length, half_height)
	if(lying)
		return ..()
	return dynamic_shadow_projection(dx, dy, distance, shadow_length, half_height)

/atom/movable/proc/dynamic_shadow_sprite_dir(dx, dy)
	return dir

// A north-side lamp is the unrotated reference for the authored sprite facings.
// Rotate into the lamp's frame using its continuous visual center.
/mob/living/carbon/human/dynamic_shadow_sprite_dir(dx, dy)
	if(lying)
		return ..()
	var/source_angle = Atan2(-dy, -dx)
	// The previous half-turn reversed both side profiles and front/back views.
	var/relative_angle = (dir2angle(dir) - source_angle + 720) % 360
	return angle2dir((round(relative_angle / 90 + 0.5) * 90) % 360)

/atom/movable/proc/clear_dynamic_shadows()
	for(var/L in dynamic_shadows)
		qdel(dynamic_shadows[L])
	dynamic_shadows = null

/atom/movable/proc/get_dynamic_shadow_icon_height()
	// Generated /icon objects change constantly; only cache real icon files
	if(!isfile(icon))
		return world.icon_size
	. = dynamic_shadow_icon_heights[icon]
	if(!.)
		var/icon/I = icon(icon)
		. = I.Height() || world.icon_size
		dynamic_shadow_icon_heights[icon] = .

/atom/movable/Move()
	var/atom/origin = loc
	dynamic_shadow_move_depth++
	. = ..()
	dynamic_shadow_move_depth--
	if(!dynamic_shadow_move_depth && loc != origin && casts_dynamic_shadow && dynamic_shadows_enabled)
		update_dynamic_shadow(TRUE)

/atom/movable/forceMove()
	. = ..()
	if(casts_dynamic_shadow && dynamic_shadows_enabled)
		clear_dynamic_shadows()
		update_dynamic_shadow()

/atom/movable/set_dir()
	. = ..()
	// Move also changes direction. Submit its final position/facing together,
	// with the movement duration, instead of starting a stationary turn first.
	if(. && dynamic_shadows && !dynamic_shadow_move_depth)
		update_dynamic_shadow()

/atom/movable/Destroy()
	clear_dynamic_shadows()
	return ..()

/// Black silhouette copy of its owner, projected along the floor away from one nearby light.
/atom/movable/dynamic_shadow
	name = ""
	mouse_opacity = 0
	anchored = TRUE
	simulated = FALSE
	plane = WORLD_SHADOW_SOURCE_PLANE
	layer = MOB_SHADOW_LAYER
	blend_mode = BLEND_OVERLAY
	appearance_flags = TILE_BOUND | PIXEL_SCALE | KEEP_APART | KEEP_TOGETHER
	alpha = 0
	var/atom/movable/owner
	var/last_source_appearance
	var/last_sprite_dir
	var/matrix/target_projection
	var/target_alpha
	var/projection_revision = 0
	var/projection_duration = 0
	var/icon/light_mask
	var/light_mask_signature
	var/list/mask_geometry
	/// Sample -> distinct tile index (zero for out-of-map samples).
	var/list/mask_receivers
	/// Coordinates, rather than turf refs, survive ChangeTurf on receivers.
	var/list/mask_tiles
	var/list/mask_tile_alpha
	var/source_width = 32
	var/source_height = 32
	animate_movement = SYNC_STEPS

/atom/movable/dynamic_shadow/New(loc, atom/movable/new_owner)
	..()
	owner = new_owner

/atom/movable/dynamic_shadow/proc/copy_owner_appearance(sprite_dir)
	if(!owner)
		return
	if(isnull(sprite_dir))
		sprite_dir = owner.dir
	if(owner.appearance == last_source_appearance && sprite_dir == last_sprite_dir)
		return
	last_source_appearance = owner.appearance
	last_sprite_dir = sprite_dir
	var/icon/source_icon = owner.icon ? icon(owner.icon) : null
	source_width = source_icon ? source_icon.Width() : world.icon_size
	source_height = source_icon ? source_icon.Height() : world.icon_size
	var/mutable_appearance/MA = new(owner)
	MA.name = ""
	MA.dir = sprite_dir
	MA.plane = WORLD_SHADOW_SOURCE_PLANE
	MA.layer = MOB_SHADOW_LAYER
	MA.blend_mode = BLEND_OVERLAY
	MA.mouse_opacity = 0
	MA.invisibility = 0
	MA.render_target = null
	MA.render_source = null
	MA.maptext = null
	MA.appearance_flags = TILE_BOUND | PIXEL_SCALE | KEEP_APART | KEEP_TOGETHER | (owner.appearance_flags & LONG_GLIDE)
	MA.animate_movement = SYNC_STEPS
	MA.color = null
	MA.opacity = 0
	MA.density = FALSE
	MA.screen_loc = null
	// Like the lightmap, this visual must be sent even on an engine-dark turf.
	// Its black pixels cannot illuminate the scene's multiply lightmap.
	MA.luminosity = 1
	// Overlays on their own planes (glows, emissives) render outside KEEP_TOGETHER and would escape the black filter
	var/list/kept_overlays = list()
	for(var/overlay in MA.overlays)
		var/mutable_appearance/O = dynamic_shadow_overlay(overlay, ismob(owner) ? sprite_dir : null)
		if(O)
			kept_overlays += O
	MA.overlays = kept_overlays
	MA.underlays = null
	// Do not assign the complete appearance: it contains the server's target
	// transform/alpha, which can snap a still-gliding client to the endpoint
	// when a walking pose or equipment changes. Only replace sprite content.
	icon = MA.icon
	icon_state = MA.icon_state
	dir = MA.dir
	overlays = MA.overlays
	underlays = null
	appearance_flags = MA.appearance_flags
	luminosity = 1
	// Filters apply to the whole KEEP_TOGETHER composite, so RESET_COLOR overlays turn black too
	set_shadow_filters()

/atom/movable/dynamic_shadow/proc/set_shadow_filters()
	filters = list(filter(type = "color", color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 0,0,0,0)))
	if(light_mask)
		filters += filter(type = "alpha", icon = light_mask)
	filters += filter(type = "blur", size = 1)

// Sample the receiving floor, not just the caster's tile. A flashlight can
// illuminate the end of a shadow without ever illuminating the caster.
/atom/movable/dynamic_shadow/proc/update_light_mask(datum/light_source/casting_light, matrix/M, dx, dy, distance)
	var/width = source_width + world.icon_size
	var/height = source_height + world.icon_size
	var/ox = owner.x + (owner.pixel_x + (source_width - world.icon_size) / 2) / world.icon_size
	var/oy = owner.y + (owner.pixel_y + (source_height - world.icon_size) / 2) / world.icon_size
	var/list/geometry = list(width, height, ox, oy, owner.z, M.a, M.b, M.c, M.d, M.e, M.f, world.maxx, world.maxy, world.maxz)
	var/geometry_changed = !mask_geometry
	if(mask_geometry)
		for(var/i in 1 to geometry.len)
			if(geometry[i] != mask_geometry[i])
				geometry_changed = TRUE
				break
	if(geometry_changed)
		mask_geometry = geometry
		mask_receivers = list()
		mask_tiles = list()
		var/list/tile_indices = list()
		for(var/py in 1 to height step DSHADOW_MASK_STEP)
			for(var/px in 1 to width step DSHADOW_MASK_STEP)
				var/u = px + (DSHADOW_MASK_STEP - 1) / 2 - (width + 1) / 2
				var/v = py + (DSHADOW_MASK_STEP - 1) / 2 - (height + 1) / 2
				var/tx = round(ox + (M.a * u + M.b * v + M.c) / world.icon_size + 0.5)
				var/ty = round(oy + (M.d * u + M.e * v + M.f) / world.icon_size + 0.5)
				var/turf/receiver = locate(tx, ty, owner.z)
				var/index = 0
				if(receiver)
					index = tile_indices[receiver]
					if(!index)
						mask_tiles += list(list(tx, ty, owner.z))
						index = mask_tiles.len
						tile_indices[receiver] = index
				mask_receivers += index
	// Re-read every receiving tile's lighting, even when geometry is unchanged.
	// Facing/centers depend on the light and caster, not on the receiving tile.
	var/list/light_facing = list()
	var/list/tile_strengths = list()
	mask_tile_alpha = list()
	for(var/list/coords as anything in mask_tiles)
		var/turf/receiver = locate(coords[1], coords[2], coords[3])
		var/strength = receiver ? round(255 * owner.dynamic_shadow_retention(casting_light, receiver, dx, dy, distance, light_facing)) : 0
		tile_strengths += strength
		if(receiver)
			mask_tile_alpha[receiver] = strength
	var/list/samples = list()
	var/needs_mask = FALSE
	for(var/index in mask_receivers)
		var/strength = index ? tile_strengths[index] : 0
		samples += strength
		if(strength != 255) needs_mask = TRUE
	var/signature = "[width],[height]:[jointext(samples, ",")]"
	if(signature == light_mask_signature)
		return
	light_mask_signature = signature
	light_mask = null
	if(needs_mask)
		light_mask = icon(get_solid_white_icon())
		light_mask.Scale(width, height)
		light_mask.Blend("#00000000", ICON_MULTIPLY)
		var/i = 0
		for(var/py in 1 to height step DSHADOW_MASK_STEP)
			for(var/px in 1 to width step DSHADOW_MASK_STEP)
				light_mask.DrawBox(rgb(255, 255, 255, samples[++i]), px, py, min(px + DSHADOW_MASK_STEP - 1, width), min(py + DSHADOW_MASK_STEP - 1, height))
	set_shadow_filters()

/datum/light_source/proc/dynamic_shadow_tile_weight(turf/T)
	if(destroyed || !applied || !(src in T.affecting_lights))
		return 0
	. = 0
	for(var/datum/lighting_corner/C in T.corners)
		. += max(0, effect_str[C]) / 4
	. *= max(applied_lum_r, applied_lum_g, applied_lum_b)

/atom/movable/proc/dynamic_shadow_retention(datum/light_source/casting_light, turf/receiver, dx, dy, distance, list/light_facing = null)
	var/cast_weight = casting_light.dynamic_shadow_tile_weight(receiver)
	if(cast_weight <= 0)
		return 0
	var/fill = 0
	var/ox = x + pixel_x / world.icon_size
	var/oy = y + pixel_y / world.icon_size
	for(var/datum/light_source/L as anything in receiver.affecting_lights)
		if(L == casting_light)
			continue
		var/weight = L.dynamic_shadow_tile_weight(receiver)
		if(weight <= 0)
			continue
		// Lights on the receiving side fill the silhouette. Co-located lamps
		// behind the caster must not erase the shadow they both project.
		var/facing = light_facing ? light_facing[L] : null
		if(isnull(facing))
			var/list/center = L.dynamic_shadow_center()
			var/lx = center[1] - ox
			var/ly = center[2] - oy
			var/light_distance = sqrt(lx * lx + ly * ly)
			facing = light_distance > 0.1 ? CLAMP01((dx * lx + dy * ly) / (distance * light_distance)) : 1
			if(light_facing)
				light_facing[L] = facing
		fill += weight * facing
	return CLAMP01(1 - fill / cast_weight)

/atom/movable/dynamic_shadow/proc/set_projection(matrix/M, strength, duration)
	if(target_projection && target_projection ~= M && target_alpha == strength)
		return
	projection_revision++
	projection_duration = duration
	if(!target_projection)
		// The first frame must already be at the feet, never an upright black
		// duplicate that slowly collapses onto the floor.
		transform = M
		alpha = strength
	else
		// These are projected floor bases, including reflection/shear. BYOND's
		// rotation-preserving decomposition can choose the opposite turn when
		// the caster crosses a lamp's horizontal axis. Interpolate the basis.
		var/animation_flags = ANIMATION_LINEAR_TRANSFORM
#ifdef ARTEMIS_LOS_PREVIEW
		if(shadow_preview_legacy_rotation)
			animation_flags = 0
#endif
		animate(src, transform = M, alpha = strength, time = duration, flags = animation_flags)
	target_projection = M
	target_alpha = strength
	// Rebind after the projection changes. A filtered KEEP_TOGETHER group
	// prepared with the previous transform can retain stale sideways bounds.
	set_shadow_filters()

/atom/movable/dynamic_shadow/Destroy()
	mask_receivers = null
	mask_tiles = null
	mask_tile_alpha = null
	mask_geometry = null
	owner = null
	loc = null
	return ..()

/atom/movable/dynamic_shadow/proc/sync_position()
	if(!owner || !isturf(owner.loc))
		loc = null
		return
	glide_size = owner.glide_size
	// Direct loc assignment so shadows never trigger Crossed()/Entered() on traps and the like
	loc = owner.loc
	pixel_x = owner.pixel_x
	pixel_y = owner.pixel_y

// Shadows are pure visuals; keep them out of every interaction path.
/atom/movable/dynamic_shadow/Move()
	return FALSE

/atom/movable/dynamic_shadow/forceMove()
	return FALSE

/atom/movable/dynamic_shadow/ex_act()
	return

/atom/movable/dynamic_shadow/update_dynamic_shadow(moving = FALSE)
	return

// Rehome physical sprite parts into the shadow pass. Their old world plane
// would otherwise break out of KEEP_TOGETHER and escape the black silhouette.
/proc/dynamic_shadow_overlay(source, sprite_dir)
	var/mutable_appearance/O = new(source)
	if(O.plane != FLOAT_PLANE && O.plane != DEFAULT_PLANE)
		return null
	O.plane = FLOAT_PLANE
	if(!isnull(sprite_dir))
		O.dir = sprite_dir
	O.appearance_flags &= ~(KEEP_APART|PLANE_MASTER)
	O.render_source = null
	O.render_target = null
	O.maptext = null
	var/list/parts = list()
	for(var/part in O.overlays)
		var/mutable_appearance/physical = dynamic_shadow_overlay(part, sprite_dir)
		if(physical) parts += physical
	O.overlays = parts
	O.underlays = null
	return O

/atom/proc/sync_world_render_plane()
	// Pipes and cables must remain underneath the terrain, rather than being
	// promoted above the completed floor when normal objects are composited.
	if(isobj(src) && plane == DEFAULT_PLANE && layer < TURF_LAYER)
		plane = WORLD_TERRAIN_SOURCE_PLANE
	// Explicitly overhead turfs retain their foreground behaviour.
	else if(isturf(src) && plane == WORLD_TERRAIN_SOURCE_PLANE && layer >= OBJ_LAYER)
		plane = DEFAULT_PLANE

/obj/screen/plane_master/world_terrain
	name = "world terrain source"
	plane = WORLD_TERRAIN_SOURCE_PLANE
	render_target = "*world_terrain"
	mouse_opacity = 1

/obj/screen/plane_master/world_shadows
	name = "world floor shadow source"
	plane = WORLD_SHADOW_SOURCE_PLANE
	render_target = "*world_floor_shadows"
	mouse_opacity = 0

/obj/screen/world_terrain_display
	name = ""
	screen_loc = "SCREEN_SOUTHWEST"
	plane = WORLD_TERRAIN_DISPLAY_PLANE
	layer = WORLD_TERRAIN_DISPLAY_LAYER
	render_source = "*world_terrain"
	appearance_flags = PASS_MOUSE
	mouse_opacity = 1

/obj/screen/world_shadow_display
	name = ""
	screen_loc = "SCREEN_SOUTHWEST"
	plane = WORLD_SHADOW_DISPLAY_PLANE
	layer = WORLD_SHADOW_DISPLAY_LAYER
	render_source = "*world_floor_shadows"
	mouse_opacity = 0

/datum/light_source
	var/shadow_center_icon
	var/shadow_center_state
	var/shadow_center_dir
	var/list/shadow_center_sample

// Alpha-weighted spatial center of the fixture, in continuous world coordinates.
// Cache just its sprite sample; offsets and transforms are evaluated every time.
/datum/light_source/proc/dynamic_shadow_center()
	var/atom/A = top_atom
	if(!A || !source_turf)
		return list(0, 0)
	if(!shadow_center_sample || A.icon != shadow_center_icon || A.icon_state != shadow_center_state || A.dir != shadow_center_dir)
		shadow_center_icon = A.icon
		shadow_center_state = A.icon_state
		shadow_center_dir = A.dir
		var/icon/I = A.icon ? icon(A.icon, A.icon_state, A.dir, 1) : null
		var/w = I ? I.Width() : world.icon_size
		var/h = I ? I.Height() : world.icon_size
		var/sum_x = 0
		var/sum_y = 0
		var/weight = 0
		if(I)
			for(var/x in 1 to w)
				for(var/y in 1 to h)
					var/pixel = I.GetPixel(x, y)
					if(!pixel) continue
					var/alpha_weight = length(pixel) == 9 ? text2num(copytext(pixel, 8, 10), 16) : 255
					sum_x += x * alpha_weight
					sum_y += y * alpha_weight
					weight += alpha_weight
		shadow_center_sample = list(weight ? sum_x / weight - (w + 1) / 2 : 0, weight ? sum_y / weight - (h + 1) / 2 : 0, (w - world.icon_size) / 2, (h - world.icon_size) / 2)
	var/cx = shadow_center_sample[1]
	var/cy = shadow_center_sample[2]
	var/matrix/M = A.transform
	var/tx = M ? M.a * cx + M.b * cy + M.c : cx
	var/ty = M ? M.d * cx + M.e * cy + M.f : cy
	return list(source_turf.x + (tx + shadow_center_sample[3] + A.pixel_x + A.pixel_w) / world.icon_size, source_turf.y + (ty + shadow_center_sample[4] + A.pixel_y + A.pixel_z) / world.icon_size)

#undef DSHADOW_MAX_ALPHA
#undef DSHADOW_MIN_WEIGHT
#undef DSHADOW_MAX_SHADOWS
#undef DSHADOW_FLATTEN
#undef DSHADOW_ANIMATE_TIME
#undef DSHADOW_MASK_STEP
