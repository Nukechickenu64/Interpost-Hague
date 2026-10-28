/var/total_lighting_overlays = 0
/atom/movable/lighting_overlay
	name = ""
	mouse_opacity = 0
	simulated = 0
	anchored = 1
	luminosity = 1
	icon = LIGHTING_ICON
	plane = LIGHTING_PLANE
	layer = LIGHTING_LAYER
	invisibility = INVISIBILITY_LIGHTING
	color = "#000000"
	icon_state = ""
	// Tile samples replace the lightmap backing, including dark edge padding.
	// Multiplication with the world is performed once by the plane master.
	blend_mode = BLEND_OVERLAY

	var/lum_r = 0
	var/lum_g = 0
	var/lum_b = 0

	var/needs_update = FALSE
	var/edge_guard_key
	var/atom/movable/lighting_edge_guard/edge_guard
	var/atom/movable/lighting_veil/tile_glow

/atom/movable/lighting_overlay/Initialize()
	// doesn't need special init
	atom_flags |= ATOM_FLAG_INITIALIZED
	return INITIALIZE_HINT_NORMAL

/atom/movable/lighting_overlay/New(var/atom/loc, var/no_update = FALSE)
	var/turf/T = loc //If this runtimes atleast we'll know what's creating overlays outside of turfs.
	if(TURF_IS_DYNAMICALLY_LIT(T))
		. = ..()
		verbs.Cut()
		total_lighting_overlays++

		icon = get_solid_white_icon()
		T.lighting_overlay = src
		T.luminosity = 0
		update_edge_guard()
		if(no_update)
			return
		update_overlay()
	else
		qdel(src)

/atom/movable/lighting_overlay/proc/update_overlay()
	set waitfor = FALSE
	var/turf/T = loc

	if(!istype(T))
		if(loc)
			log_debug("A lighting overlay realised its loc was NOT a turf (actual loc: [loc][loc ? ", " + loc.type : "null"]) in update_overlay() and got qdel'ed!")
		else
			log_debug("A lighting overlay realised it was in nullspace in update_overlay() and got pooled!")
		qdel(src)
		return
	if(!TURF_IS_DYNAMICALLY_LIT_UNSAFE(T))
		qdel(src)
		return
	update_edge_guard()

	// Sample one light value for the whole tile. The light plane supplies spatial
	// blur and bloom; the tile itself must not bilinearly interpolate four colors.
	var/list/rgb = lighting_tile_rgb(T)
	lum_r = rgb[1]
	lum_g = rgb[2]
	lum_b = rgb[3]
	var/set_luminosity = max(lum_r, lum_g, lum_b) > 1e-6
	var/list/target_color = list(
		lum_r, 0, 0, 0,
		0, lum_g, 0, 0,
		0, 0, lum_b, 0,
		0, 0, 0, 1,
		0, 0, 0, 0)
	// The glow source contains real tile light only, never the lightmap's
	// white fullbright backing. Weak spill fades quadratically toward black.
	var/veil = LIGHTING_VEIL_STRENGTH * max(lum_r, lum_g, lum_b)
	var/list/glow_color = list(lum_r * veil, 0, 0, 0, 0, lum_g * veil, 0, 0,
		0, 0, lum_b * veil, 0, 0, 0, 0, 1, 0, 0, 0, 0)
	if(set_luminosity && !tile_glow)
		tile_glow = new(T)
		tile_glow.color = glow_color
	else if(tile_glow)
		if(!set_luminosity)
			animate(tile_glow)
			tile_glow.color = glow_color
		else
			animate(tile_glow, color = glow_color, time = LIGHTING_TRANSITION_TIME)
	if(!set_luminosity)
		animate(src)
		color = target_color
	else if(islist(color))
		animate(src, color = target_color, time = LIGHTING_TRANSITION_TIME)
	else
		color = target_color

	luminosity = enhanced_los_enabled ? TRUE : set_luminosity
	// Keep black overlays drawable underneath the geometric mask. This does not
	// grant SEE_TURFS or any other through-wall sight flag to the viewer.
	// if (T.above && T.above.shadower)
	// 	T.above.shadower.copy_lighting(src)

/proc/lighting_tile_rgb(turf/T)
	var/red = 0
	var/green = 0
	var/blue = 0
	var/count = 0
	for(var/datum/lighting_corner/C in T.corners)
		if(T.opaque_counter)
			// Opaque tiles never receive light through buried corners. Averaging
			// those zeros made a room corner four times darker than its exposed
			// sample. Normalize by geometry, not by whether a sample is lit.
			var/exposed = FALSE
			for(var/turf/N in C.masters)
				if(!N.opaque_counter)
					exposed = TRUE
					break
			if(!exposed) continue
		count++
		red += C.lum_r
		green += C.lum_g
		blue += C.lum_b
	return lighting_display_rgb(red / max(1, count), green / max(1, count), blue / max(1, count))

// Native visibility omits tiles behind an opaque boundary. Without padding,
// blur/bloom samples the white fullbright backdrop there and lights the wall's
// outer edge even when every actual light sample is zero. Put black padding
// below the real tile samples; visible neighbors replace it with their own RGB.
// Exclude nondynamic neighbors so their intentionally fullbright backing stays.
var/global/list/lighting_edge_guard_cache = list()

/atom/movable/lighting_edge_guard
	name = ""
	mouse_opacity = 0
	anchored = TRUE
	simulated = FALSE
	luminosity = 1
	invisibility = INVISIBILITY_LIGHTING
	plane = LIGHTING_PLANE
	// Both padding and samples use the topdown group, above the screen backing.
	layer = LIGHTING_LAYER - 0.1
	blend_mode = BLEND_OVERLAY

/atom/movable/lighting_edge_guard/Initialize()
	atom_flags |= ATOM_FLAG_INITIALIZED
	return INITIALIZE_HINT_NORMAL

/atom/movable/lighting_overlay/proc/update_edge_guard()
	var/turf/T = loc
	var/mask = 0
	if(istype(T) && T.opaque_counter)
		var/bit = 1
		for(var/dy in -1 to 1)
			for(var/dx in -1 to 1)
				var/turf/N = locate(T.x + dx, T.y + dy, T.z)
				if(!N || TURF_IS_DYNAMICALLY_LIT(N))
					mask |= bit
				bit <<= 1
	var/key = "[mask]"
	if(edge_guard_key == key)
		return
	edge_guard_key = key
	if(!mask)
		QDEL_NULL(edge_guard)
		return
	var/icon/padding = lighting_edge_guard_cache[key]
	if(!padding)
		var/size = world.icon_size
		padding = icon(get_solid_white_icon())
		padding.Scale(size * 3, size * 3)
		padding.DrawBox("#00000000", 1, 1, size * 3, size * 3)
		var/bit = 1
		for(var/dy in 0 to 2)
			for(var/dx in 0 to 2)
				if(mask & bit)
					padding.DrawBox("#000000", dx * size + 1, dy * size + 1, (dx + 1) * size, (dy + 1) * size)
				bit <<= 1
		lighting_edge_guard_cache[key] = padding
	// Keep the padding's lifetime and topdown ordering independent of the tile.
	if(!edge_guard)
		edge_guard = new(T)
		edge_guard.pixel_x = -world.icon_size
		edge_guard.pixel_y = -world.icon_size
	edge_guard.icon = padding

// Variety of overrides so the overlays don't get affected by weird things.
/atom/movable/lighting_overlay/ex_act()
	return

/atom/movable/lighting_overlay/singularity_pull()
	return

/atom/movable/lighting_overlay/Destroy()
	QDEL_NULL(edge_guard)
	QDEL_NULL(tile_glow)
	total_lighting_overlays--

	var/turf/T = loc
	if(istype(T))
		T.lighting_overlay = null

	. = ..()

/atom/movable/lighting_overlay/forceMove()
	if(QDELING(src))
		return ..()
	return 0 //should never move

/atom/movable/lighting_overlay/Move()
	return 0

/atom/movable/lighting_overlay/throw_at()
	return 0

/atom/movable/lighting_veil
	name = ""
	plane = LIGHTING_VEIL_SOURCE_PLANE
	layer = LIGHTING_LAYER
	color = "#000000"
	anchored = TRUE
	simulated = FALSE
	mouse_opacity = 0
	luminosity = 1
	invisibility = INVISIBILITY_LIGHTING

/atom/movable/lighting_veil/New()
	. = ..()
	icon = get_solid_white_icon()

/atom/movable/lighting_veil/Initialize()
	atom_flags |= ATOM_FLAG_INITIALIZED
	return INITIALIZE_HINT_NORMAL

/atom/movable/lighting_veil/ex_act()
	return

/atom/movable/lighting_veil/singularity_pull()
	return
