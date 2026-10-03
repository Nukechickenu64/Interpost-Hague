#define DSHADOW_MAX_ALPHA		150
#define DSHADOW_MIN_WEIGHT		0.08
#define DSHADOW_MAX_SHADOWS		3
#define DSHADOW_FLATTEN			0.55
#define DSHADOW_ANIMATE_TIME	3

var/global/dynamic_shadows_enabled = FALSE
var/global/list/dynamic_shadow_icon_heights = list()

/atom/movable
	var/casts_dynamic_shadow = FALSE
	var/list/dynamic_shadows

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
	if(!dynamic_shadows_enabled || !casts_dynamic_shadow || !isturf(loc) || !icon)
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
	// Strongest lights first; each entry is list(weight, dx, dy, dist)
	var/list/casts = list()
	for(var/datum/light_source/L as anything in T.affecting_lights)
		if(L.destroyed || !L.applied || L.top_atom == src)
			continue
		var/turf/LT = L.pixel_turf || L.source_turf
		if(!LT || LT.z != T.z)
			continue
		var/dx = ox - LT.x
		var/dy = oy - LT.y
		var/dist = sqrt(dx * dx + dy * dy)
		if(dist < 0.3)
			continue
		var/weight = L.light_power * max(0, 1 - dist / max(L.light_range, 1))
		if(weight < DSHADOW_MIN_WEIGHT)
			continue
		var/insert_at = casts.len + 1
		for(var/i in 1 to casts.len)
			var/list/other = casts[i]
			if(weight > other[1])
				insert_at = i
				break
		casts.Insert(insert_at, null)
		casts[insert_at] = list(weight, dx, dy, dist)

	var/count = min(casts.len, DSHADOW_MAX_SHADOWS)
	if(!count)
		clear_dynamic_shadows()
		return
	LAZYINITLIST(dynamic_shadows)
	while(dynamic_shadows.len > count)
		var/atom/movable/dynamic_shadow/extra = dynamic_shadows[dynamic_shadows.len]
		dynamic_shadows.len--
		qdel(extra)
	while(dynamic_shadows.len < count)
		dynamic_shadows += new /atom/movable/dynamic_shadow(null, src)

	var/half_height = get_dynamic_shadow_icon_height() / 2
	// While moving, finish the reshape exactly when the glide finishes so shadow and owner stay in step
	var/anim_time = moving ? (world.icon_size / max(glide_size, 1)) * world.tick_lag : DSHADOW_ANIMATE_TIME
	for(var/i in 1 to count)
		var/list/cast = casts[i]
		var/atom/movable/dynamic_shadow/S = dynamic_shadows[i]
		S.sync_position()
		S.copy_owner_appearance()
		var/dist = cast[4]
		var/shadow_length = Clamp(0.3 + dist * 0.25, 0.4, 1.4)
		var/shear = cast[2] / dist * shadow_length
		var/height = cast[3] / dist * shadow_length * DSHADOW_FLATTEN
		if(abs(height) < 0.2)
			height = height < 0 ? -0.2 : 0.2
		// Pivot at the feet: x' = 0.9x + shear*(y+h), y' = height*(y+h) - h
		var/matrix/M = matrix(transform) * matrix(0.9, shear, shear * half_height, 0, height, height * half_height - half_height)
		animate(S, transform = M, alpha = round(DSHADOW_MAX_ALPHA * min(cast[1], 1)), time = anim_time)

/atom/movable/proc/clear_dynamic_shadows()
	for(var/S in dynamic_shadows)
		qdel(S)
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
	. = ..()
	if(casts_dynamic_shadow && dynamic_shadows_enabled)
		update_dynamic_shadow(TRUE)

/atom/movable/forceMove()
	. = ..()
	if(casts_dynamic_shadow && dynamic_shadows_enabled)
		update_dynamic_shadow(TRUE)

/atom/movable/set_dir()
	. = ..()
	if(. && dynamic_shadows)
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
	plane = DEFAULT_PLANE
	layer = MOB_SHADOW_LAYER
	appearance_flags = PIXEL_SCALE | KEEP_APART | KEEP_TOGETHER
	alpha = 0
	var/atom/movable/owner
	var/last_source_appearance

/atom/movable/dynamic_shadow/New(loc, atom/movable/new_owner)
	..()
	owner = new_owner

/atom/movable/dynamic_shadow/proc/copy_owner_appearance()
	if(!owner || owner.appearance == last_source_appearance)
		return
	last_source_appearance = owner.appearance
	var/mutable_appearance/MA = new(owner)
	MA.name = ""
	MA.plane = DEFAULT_PLANE
	MA.layer = MOB_SHADOW_LAYER
	MA.mouse_opacity = 0
	MA.invisibility = 0
	MA.render_target = null
	MA.appearance_flags = PIXEL_SCALE | KEEP_APART | KEEP_TOGETHER
	MA.color = null
	MA.opacity = 0
	MA.luminosity = 0
	MA.alpha = alpha
	MA.transform = transform
	MA.pixel_x = pixel_x
	MA.pixel_y = pixel_y
	// Overlays on their own planes (glows, emissives) render outside KEEP_TOGETHER and would escape the black filter
	var/list/kept_overlays = list()
	for(var/overlay in MA.overlays)
		var/mutable_appearance/O = overlay
		if(O.plane == FLOAT_PLANE || O.plane == DEFAULT_PLANE)
			kept_overlays += overlay
	MA.overlays = kept_overlays
	appearance = MA
	// Filters apply to the whole KEEP_TOGETHER composite, so RESET_COLOR overlays turn black too
	filters = list(filter(type = "color", color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 0,0,0,0)), filter(type = "blur", size = 1))

/atom/movable/dynamic_shadow/Destroy()
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

#undef DSHADOW_MAX_ALPHA
#undef DSHADOW_MIN_WEIGHT
#undef DSHADOW_MAX_SHADOWS
#undef DSHADOW_FLATTEN
#undef DSHADOW_ANIMATE_TIME
