/atom
	var/light_power = 1 // intensity of the light
	var/light_range = 0 // range in tiles of the light
	var/light_color		// Hexadecimal RGB string representing the colour of the light
	var/light_cone_angle = 0 // half-width in degrees; 0 = omnidirectional
	var/light_cone_dir = 0   // degrees, 0 = north, clockwise
	var/light_glow_range = 0 // omnidirectional glow radius around a cone light
	var/light_cone_target_x
	var/light_cone_target_y

	var/datum/light_source/light
	var/list/light_sources

// Nonsensical value for l_color default, so we can detect if it gets set to null.
#define NONSENSICAL_VALUE -99999
/atom/proc/set_light(l_range, l_power, l_color = NONSENSICAL_VALUE)
	. = 0 //make it less costly if nothing's changed

	if(l_power != null && l_power != light_power)
		light_power = l_power
		. = 1
	if(l_range != null && l_range != light_range)
		light_range = l_range
		. = 1
	if(l_color != NONSENSICAL_VALUE && l_color != light_color)
		light_color = l_color
		. = 1

	if(.) update_light()

#undef NONSENSICAL_VALUE

/atom/proc/set_light_cone(angle, cone_dir, glow_range, target_x, target_y)
	cone_dir = round(cone_dir, 5)
	if(cone_dir >= 360 || cone_dir < 0)
		cone_dir = (cone_dir % 360 + 360) % 360
	if(angle == light_cone_angle && cone_dir == light_cone_dir && glow_range == light_glow_range && target_x == light_cone_target_x && target_y == light_cone_target_y)
		return FALSE
	light_cone_angle = angle
	light_cone_dir = cone_dir
	light_glow_range = glow_range
	light_cone_target_x = target_x
	light_cone_target_y = target_y
	update_light()
	return TRUE

/atom/proc/update_light()
	set waitfor = FALSE

	if(!light_power || !light_range)
		if(light)
			light.destroy()
			light = null
	else
		if(!istype(loc, /atom/movable))
			. = src
		else
			. = loc

		if(light)
			light.update(.)
		else
			light = new /datum/light_source(src, .)

/atom/Destroy()
	if(light)
		light.destroy()
		light = null
	return ..()

// Multi-tile movables count toward every turf they cover, not just loc.
/atom/movable/set_opacity()
	. = ..()
	if(.)
		for(var/turf/T in locs)
			T.RecalculateOpacity()

#define LIGHT_MOVE_UPDATE \
var/turf/old_loc = loc;\
. = ..();\
if(loc != old_loc) {\
	for(var/datum/light_source/L in light_sources) {\
		L.source_atom.update_light();\
	}\
}

/atom/movable/Move()
	LIGHT_MOVE_UPDATE

/atom/movable/forceMove()
	LIGHT_MOVE_UPDATE

#undef LIGHT_MOVE_UPDATE

/obj/item/equipped()
	. = ..()
	update_light()

/obj/item/pickup(mob/user)
	. = ..()
	update_light()
	if(istype(src, /obj/item/weapon) && user)
		user.perceived_visible_message("<span class='danger'>[user] reaches for a weapon!</span>")
	if(drawsound)
		playsound(user, drawsound, 50, 1)

/obj/item/dropped()
	. = ..()
	update_light()


/proc/lighting_tile_distance(atom/A, atom/B)
	if(!A || !B) return 0
	var/dx = A.x - B.x
	var/dy = A.y - B.y
	var/falloff_mode = LIGHTING_FALLOFF
	if(falloff_mode == 1)
		// Euclidean: circular falloff
		return sqrt(dx*dx + dy*dy)
	else if(falloff_mode == 2)
		// Manhattan: diamond falloff
		return abs(dx) + abs(dy)
	else
		// Chebyshev: square falloff
		return max(abs(dx), abs(dy))

/proc/lighting_falloff_weight(dist, range)
    if(range <= 0) return 0
    var/w = 1 - (dist / range)
    if(w < 0) return 0
    if(w > 1) return 1
    return w