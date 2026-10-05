/var/total_lighting_sources = 0
// This is where the fun begins.
// These are the main datums that emit light.

/datum/light_source
	var/atom/top_atom        // The atom we're emitting light from(for example a mob if we're from a flashlight that's being held).
	var/atom/source_atom     // The atom that we belong to.

	var/turf/source_turf     // The turf under the above.
	var/turf/pixel_turf      // The turf the top_atom appears to over.
	var/light_power    // Intensity of the emitter light.
	var/light_range      // The range of the emitted light.
	var/light_color    // The colour of the light, string, decomposed by parse_light_color()
	var/light_cone_angle
	var/light_cone_dir
	var/light_glow_range
	var/light_cone_target_x
	var/light_cone_target_y
	var/cone_target_x
	var/cone_target_y
	var/cone_target_dist
	var/cone_unit_x
	var/cone_unit_y
	var/cone_update = FALSE

	// Variables for keeping track of the colour.
	var/lum_r
	var/lum_g
	var/lum_b

	// The lumcount values used to apply the light.
	var/applied_lum_r
	var/applied_lum_g
	var/applied_lum_b

	var/list/datum/lighting_corner/effect_str     // List used to store how much we're affecting corners.
	var/list/turf/affecting_turfs

	var/applied = FALSE // Whether we have applied our light yet or not.

	var/vis_update      // Whether we should smartly recalculate visibility. and then only update tiles that became(in)visible to us.
	var/needs_update    // Whether we are queued for an update.
	var/destroyed       // Whether we are destroyed and need to stop emitting light.
	var/force_update

// This macro will only offset up to 1 tile, but anything with a greater offset is an outlier and probably should handle its own lighting offsets.
// Anything pixelshifted 16px or more will be considered on the next tile.
#define GET_APPROXIMATE_PIXEL_DIR(PX, PY) ((!(PX) ? 0 : ((PX >= 16 ? EAST : (PX <= -16 ? WEST : 0)))) | (!PY ? 0 : (PY >= 16 ? NORTH : (PY <= -16 ? SOUTH : 0))))
#define UPDATE_APPROXIMATE_PIXEL_TURF var/_mask = GET_APPROXIMATE_PIXEL_DIR(top_atom.pixel_x, top_atom.pixel_y); pixel_turf = _mask ? (get_step(source_turf, _mask) || source_turf) : source_turf

/datum/light_source/New(var/atom/owner, var/atom/top)
	total_lighting_sources++
	source_atom = owner // Set our new owner.
	if(!source_atom.light_sources)
		source_atom.light_sources = list()

	source_atom.light_sources += src // Add us to the lights of our owner.
	top_atom = top
	if(top_atom != source_atom)
		if(!top.light_sources)
			top.light_sources     = list()

		top_atom.light_sources += src

	source_turf = top_atom
	UPDATE_APPROXIMATE_PIXEL_TURF
	light_power = source_atom.light_power
	light_range = source_atom.light_range
	light_color = source_atom.light_color
	light_cone_angle = source_atom.light_cone_angle
	light_cone_dir = source_atom.light_cone_dir
	light_glow_range = source_atom.light_glow_range
	light_cone_target_x = source_atom.light_cone_target_x
	light_cone_target_y = source_atom.light_cone_target_y

	parse_light_color()

	effect_str      = list()
	affecting_turfs = list()

	update()


	return ..()

// Kill ourselves.
/datum/light_source/proc/destroy()
	total_lighting_sources--
	destroyed = TRUE
	force_update()
	if(source_atom && source_atom.light_sources)
		source_atom.light_sources -= src

	if(top_atom && top_atom.light_sources)
		top_atom.light_sources    -= src

// Call it dirty, I don't care.
// This is here so there's no performance loss on non-instant updates from the fact that the engine can also do instant updates.
// If you're wondering what's with the "BYOND" argument: BYOND won't let me have a() macro that has no arguments :|.
#define effect_update(BYOND)            \
	if(!needs_update)                  \
	{                                   \
		SSlighting.light_queue += src;  \
		needs_update            = TRUE; \
	}

// This proc will cause the light source to update the top atom, and add itself to the update queue.
/datum/light_source/proc/update(var/atom/new_top_atom)
	// This top atom is different.
	if(new_top_atom && new_top_atom != top_atom)
		if(top_atom != source_atom) // Remove ourselves from the light sources of that top atom.
			top_atom.light_sources -= src

		top_atom = new_top_atom

		if(top_atom != source_atom)
			if(!top_atom.light_sources)
				top_atom.light_sources = list()

			top_atom.light_sources += src // Add ourselves to the light sources of our new top atom.

	effect_update(null)

// Will force an update without checking if it's actually needed.
/datum/light_source/proc/force_update()
	force_update = 1

	effect_update(null)

// Will cause the light source to recalculate turfs that were removed or added to visibility only.
/datum/light_source/proc/vis_update()
	vis_update = 1

	effect_update(null)

// Will check if we actually need to update, and update any variables that may need to be updated.
/datum/light_source/proc/check()
	if(!source_atom || !light_range || !light_power)
		destroy()
		return 1

	if(!top_atom)
		top_atom = source_atom
		. = 1

	if(isturf(top_atom))
		if(source_turf != top_atom)
			source_turf = top_atom
			UPDATE_APPROXIMATE_PIXEL_TURF
			. = 1
	else if(top_atom.loc != source_turf)
		source_turf = top_atom.loc
		. = 1

	if(source_atom.light_power != light_power)
		light_power = source_atom.light_power
		. = 1

	if(source_atom.light_range != light_range)
		light_range = source_atom.light_range
		. = 1

	if(light_range && light_power && !applied)
		. = 1

	if(source_atom.light_cone_angle != light_cone_angle || source_atom.light_cone_dir != light_cone_dir || source_atom.light_glow_range != light_glow_range || source_atom.light_cone_target_x != light_cone_target_x || source_atom.light_cone_target_y != light_cone_target_y)
		light_cone_angle = source_atom.light_cone_angle
		light_cone_dir = source_atom.light_cone_dir
		light_glow_range = source_atom.light_glow_range
		light_cone_target_x = source_atom.light_cone_target_x
		light_cone_target_y = source_atom.light_cone_target_y
		cone_update = TRUE
		prepare_cone()

	if(source_atom.light_color != light_color)
		light_color = source_atom.light_color
		parse_light_color()
		. = 1

// Decompile the hexadecimal colour into lumcounts of each perspective.
/datum/light_source/proc/parse_light_color()
	if(light_color)
		lum_r = GetRedPart  (light_color) / 255
		lum_g = GetGreenPart(light_color) / 255
		lum_b = GetBluePart (light_color) / 255
	else
		lum_r = 1
		lum_g = 1
		lum_b = 1

// Macro that applies light to a new corner.
// It is a macro in the interest of speed, yet not having to copy paste it.
// If you're wondering what's with the backslashes, the backslashes cause BYOND to not automatically end the line.
// As such this all gets counted as a single line.
// The braces and semicolons are there to be able to do this on a single line.

#define APPLY_CORNER(C)              \
	. = light_cone_angle ? cone_falloff(C) : LUM_FALLOFF(C, source_turf); \
	. *= light_power/2;              \
	effect_str[C] = .;               \
	C.update_lumcount                \
	(                                \
		. * applied_lum_r,           \
		. * applied_lum_g,           \
		. * applied_lum_b            \
	);

// I don't need to explain what this does, do I?
#define REMOVE_CORNER(C)             \
	. = -effect_str[C];              \
	C.update_lumcount                \
	(                                \
		. * applied_lum_r,           \
		. * applied_lum_g,           \
		. * applied_lum_b            \
	);

//Original/Euclidean (circular) lighting falloff. This looks the best and gives a circular light shape.
// Uses LIGHTING_HEIGHT to simulate pseudo-z falloff.
#if LIGHTING_FALLOFF == 1
#define LUM_FALLOFF(C, T) (1 - CLAMP01(sqrt((C.x - T.x) ** 2 + (C.y - T.y) ** 2 + LIGHTING_HEIGHT) / max(1, light_range)))

//Manhattan (diamond) falloff. Kept for compatibility if toggled via LIGHTING_FALLOFF define.
#elif LIGHTING_FALLOFF == 2
#define LUM_FALLOFF(C, T) (1 - CLAMP01(((abs(C.x - T.x) + abs(C.y - T.y))) / max(1, light_range+1)))

//Chebyshev/Octagonal approximation (square-ish). Alternative option if desired.
#else
#define GET_LUM_DIST(DISTX, DISTY) (DISTX + DISTY + abs(DISTX - DISTY)*0.4)
#define LUM_FALLOFF(C, T) (1 - CLAMP01((GET_LUM_DIST(abs(C.x - T.x), abs(C.y - T.y))) / max(1, light_range+1)))
#endif

/datum/light_source/proc/prepare_cone()
	cone_target_dist = 0
	if(!light_cone_angle || !source_turf)
		return
	cone_target_x = light_cone_target_x
	cone_target_y = light_cone_target_y
	if(isnull(cone_target_x) || isnull(cone_target_y))
		cone_target_x = source_turf.x + sin(light_cone_dir) * light_range
		cone_target_y = source_turf.y + cos(light_cone_dir) * light_range
	var/target_dx = cone_target_x - source_turf.x
	var/target_dy = cone_target_y - source_turf.y
	cone_target_dist = sqrt(target_dx * target_dx + target_dy * target_dy)
	if(!cone_target_dist)
		return
	if(cone_target_dist > light_range)
		target_dx = target_dx / cone_target_dist * light_range
		target_dy = target_dy / cone_target_dist * light_range
		cone_target_x = source_turf.x + target_dx
		cone_target_y = source_turf.y + target_dy
		cone_target_dist = light_range
	cone_unit_x = target_dx / cone_target_dist
	cone_unit_y = target_dy / cone_target_dist

/datum/light_source/proc/cone_falloff(datum/lighting_corner/C)
	var/dx = C.x - source_turf.x
	var/dy = C.y - source_turf.y
	. = 0
	var/glow_dist_squared = dx * dx + dy * dy
	if(light_glow_range && (light_glow_range < 0 || glow_dist_squared < light_glow_range * light_glow_range))
		. = 1 - CLAMP01(sqrt(glow_dist_squared) / light_glow_range)
	if(!cone_target_dist)
		return
	var/along = dx * cone_unit_x + dy * cone_unit_y
	var/across = abs(dx * cone_unit_y - dy * cone_unit_x)
	var/beam_width = 0.35 + 0.75 * CLAMP01(along / cone_target_dist)
	var/beam = 0
	if(along >= 0 && along <= cone_target_dist && across < beam_width)
		beam = 0.75 * (1 - across / beam_width)
	var/spot_dist_x = C.x - cone_target_x
	var/spot_dist_y = C.y - cone_target_y
	var/spot_dist_squared = spot_dist_x * spot_dist_x + spot_dist_y * spot_dist_y
	var/spot = 0
	if(spot_dist_squared < 1.4 * 1.4)
		spot = 1 - CLAMP01(sqrt(spot_dist_squared) / 1.4)
	. = max(., beam, spot)

/datum/light_source/proc/update_cone_lum()
	// Aiming changes intensity, not visibility or corner membership.
	for(var/datum/lighting_corner/C in effect_str)
		var/strength = 0
		if(C.active)
			strength = light_cone_angle ? cone_falloff(C) : LUM_FALLOFF(C, source_turf)
			strength *= light_power / 2
		var/delta = strength - effect_str[C]
		if(!delta)
			continue
		effect_str[C] = strength
		C.update_lumcount(delta * applied_lum_r, delta * applied_lum_g, delta * applied_lum_b)

/datum/light_source/proc/apply_lum()
	var/static/update_gen = 1
	applied = 1
	prepare_cone()

	// Keep track of the last applied lum values so that the lighting can be reversed
	applied_lum_r = lum_r
	applied_lum_g = lum_g
	applied_lum_b = lum_b

	FOR_DVIEW(var/turf/T, light_range, source_turf, INVISIBILITY_LIGHTING)
		check_t:
		if(!T.lighting_corners_initialised)
			T.generate_missing_corners()

		for(var/datum/lighting_corner/C in T.get_corners())
			if(C.update_gen == update_gen)
				continue

			C.update_gen = update_gen
			C.affecting += src

			if(!C.active)
				effect_str[C] = 0
				continue

			APPLY_CORNER(C)



		if(!T.affecting_lights)
			T.affecting_lights = list()

		T.affecting_lights += src
		affecting_turfs    += T

		if ((T.z_flags & ZM_ALLOW_LIGHTING) && T.below)
			T = T.below
			goto check_t

	END_FOR_DVIEW

	update_gen++

/datum/light_source/proc/process_the_turf(var/turf/T, update_gen)

	if(!T.lighting_corners_initialised)
		T.generate_missing_corners()

	for(var/datum/lighting_corner/C in T.get_corners())
		if(C.update_gen == update_gen)
			continue

		C.update_gen = update_gen
		C.affecting += src

		if(!C.active)
			effect_str[C] = 0
			continue

		APPLY_CORNER(C)



	if(!T.affecting_lights)
		T.affecting_lights = list()

	T.affecting_lights += src
	affecting_turfs    += T

	var/turf/simulated/open/O = T
	if(istype(O) && O.below)
		return O.below
	return null

/datum/light_source/proc/remove_lum()
	applied = FALSE

	for(var/turf/T in affecting_turfs)
		if(!T.affecting_lights)
			T.affecting_lights = list()
		else
			T.affecting_lights -= src

	affecting_turfs.Cut()

	for(var/datum/lighting_corner/C in effect_str)
		REMOVE_CORNER(C)

		C.affecting -= src

	effect_str.Cut()

/datum/light_source/proc/recalc_corner(var/datum/lighting_corner/C)
	if(effect_str.Find(C)) // Already have one.
		REMOVE_CORNER(C)

	APPLY_CORNER(C)

/datum/light_source/proc/smart_vis_update()
	var/list/datum/lighting_corner/corners = list()
	var/list/turf/turfs                    = list()
	FOR_DVIEW(var/turf/T, light_range, source_turf, 0)
		if(!T.lighting_corners_initialised)
			T.generate_missing_corners()
		corners |= T.get_corners()
		turfs   += T

		var/turf/simulated/open/O = T
		if(istype(O) && O.below)
			// Consider the turf below us as well. (Z-lights)
			for(T = O.below; !isnull(T); T = update_the_turf(T,corners, turfs));

	var/list/L = turfs - affecting_turfs // New turfs, add us to the affecting lights of them.
	affecting_turfs += L
	for(var/turf/T in L)
		if(!T.affecting_lights)
			T.affecting_lights = list(src)
		else
			T.affecting_lights += src

	L = affecting_turfs - turfs // Now-gone turfs, remove us from the affecting lights.
	affecting_turfs -= L
	for(var/turf/T in L)
		T.affecting_lights -= src

	for(var/datum/lighting_corner/C in corners - effect_str) // New corners
		C.affecting += src
		if(!C.active)
			effect_str[C] = 0
			continue

		APPLY_CORNER(C)

	for(var/datum/lighting_corner/C in effect_str - corners) // Old, now gone, corners.
		REMOVE_CORNER(C)
		C.affecting -= src
		effect_str -= C


/datum/light_source/proc/update_the_turf(var/turf/T, var/list/datum/lighting_corner/corners, var/list/turf/turfs)
	if(!T.lighting_corners_initialised)
		T.generate_missing_corners()
	corners |= T.get_corners()
	turfs   += T

	var/turf/simulated/open/O = T
	if(istype(O) && O.below)
		return O.below
	return null

#undef effect_update
#undef LUM_FALLOFF
#undef REMOVE_CORNER
#undef APPLY_CORNER
