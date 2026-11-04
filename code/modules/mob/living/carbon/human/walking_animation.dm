// Procedural, integer-pixel gait for the standard 32x32 human layout.
// All cutout sprites and pose instructions are prepared before atom initialization.
// During play we only assemble appearances using those immutable masks; no icon
// rasterization, cropping, shifting or frame generation occurs during movement.
/mob/living/carbon/human
	var/walking_phase = 0
	var/walking_next_foot = 1
	var/walking_generation = 0
	var/walking_move_depth = 0
	var/image/walking_body_source
	var/list/walking_overlay_cache

/mob/living/carbon/human/proc/walking_animation_enabled()
	return client && get_preference_value(/datum/client_preference/walking_animation) == GLOB.PREF_YES

/mob/living/carbon/human/proc/can_animate_walking()
	if(!SSwalking.initialized || !walking_animation_enabled() || !icon_update || !stand_icon || !species || species.name != SPECIES_HUMAN)
		return FALSE
	if(stat != CONSCIOUS || !canmove || lying || resting || buckled || hanging || throwing || is_floating || transforming || is_cloaked() || !isturf(loc))
		return FALSE
	if(!has_gravity(src, loc))
		return FALSE
	// A side-view silhouette cannot supply a second leg after an amputation.
	for(var/part in list(BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT))
		var/obj/item/organ/external/limb = get_organ(part)
		if(!limb || limb.is_stump())
			return FALSE
	return TRUE

/mob/living/carbon/human/Move()
	var/atom/origin = loc
	walking_move_depth++
	. = ..()
	walking_move_depth--
	// Diagonal Move calls recurse into cardinal steps. Animate the final move
	// once, and only for player locomotion, not conveyor belts or being pushed.
	if(!walking_move_depth && loc != origin)
		if(client && client.moving && isturf(origin) && origin.z == z && get_dist(origin, src) == 1)
			begin_walking_step()
		else
			stop_walking_animation()

/mob/living/carbon/human/forceMove(atom/destination)
	stop_walking_animation()
	return ..()

/mob/living/carbon/human/proc/begin_walking_step()
	if(!can_animate_walking())
		stop_walking_animation()
		return
	walking_phase = walking_next_foot
	walking_next_foot *= -1
	var/generation = ++walking_generation
	update_icons(TRUE)
	// Match the visible tile glide without calling movement_delay() again (it
	// has gameplay side effects). Return to the contact pose between steps.
	var/stride_time = max(world.tick_lag, min(6, 32 / max(1, glide_size) * world.tick_lag))
	spawn(max(world.tick_lag, stride_time * 0.65))
		if(!QDELETED(src) && generation == walking_generation)
			stop_walking_animation()

/mob/living/carbon/human/proc/stop_walking_animation()
	walking_generation++
	if(!walking_phase)
		return
	walking_phase = 0
	if(!QDELETED(src) && stand_icon)
		update_icons(TRUE)

/mob/living/carbon/human/proc/clear_walking_cache()
	walking_body_source = null
	walking_overlay_cache = null

// No fire(): once initialized, the mask library is read-only for the round.
SUBSYSTEM_DEF(walking)
	name = "Walking Poses"
	init_order = SS_INIT_ATOMS + 0.5
	flags = SS_NO_FIRE
	var/list/masks = list()
	var/list/poses = list()
	var/generated_masks = 0

/datum/controller/subsystem/walking/Initialize(timeofday)
	if(!poses.len)
		for(var/facing in list(SOUTH, NORTH, EAST, WEST))
			for(var/phase in list(-1, 1))
				for(var/garment in list(FALSE, TRUE))
					var/list/slices = list()
					if(garment)
						slices += list(list(prepare_mask(1, 7, 32, 10), 0, 0, FALSE))
						slices += list(list(prepare_mask(1, 1, 32, 6), phase, 0, FALSE))
					else if(facing == SOUTH || facing == NORTH)
						var/left_lift = (phase == 1) == (facing == SOUTH)
						slices += list(list(prepare_mask(1, 1, 16, 10), 0, left_lift ? 1 : 0, FALSE))
						slices += list(list(prepare_mask(17, 1, 32, 10), 0, left_lift ? 0 : 1, FALSE))
					else
						var/stride = phase * (facing == EAST ? 1 : -1)
						for(var/leg in list(-1, 1))
							for(var/band = 0, band < 3, band++)
								var/dx = stride * leg * (2 - band)
								slices += list(list(prepare_mask(1, 1 + band * 3, 32, band == 2 ? 10 : 3 + band * 3), dx, leg == -1 ? 1 : 0, leg == -1))
					// Hands reach down to y=11 in r_human.dmi. Keep that row
					// and everything above it stationary, drawn over the thighs.
					slices += list(list(prepare_mask(1, 11, 32, 32), 0, 0, FALSE))
					poses["[facing]|[phase]|[garment]"] = slices
	return ..()

// The only sprite generator in this feature. Guard against any lazy generation
// after startup, including a late join, a new outfit or a preference toggle.
/datum/controller/subsystem/walking/proc/prepare_mask(x1, y1, x2, y2)
	var/key = "[x1],[y1],[x2],[y2]"
	if(masks[key])
		return masks[key]
	if(initialized)
		CRASH("Walking mask requested after initialization: [key]")
	var/icon/mask = new('icons/effects/effects.dmi', "nothing")
	mask.DrawBox("#ffffff", x1, y1, x2, y2)
	masks[key] = mask
	generated_masks++
	return mask

/datum/controller/subsystem/walking/proc/get_pose(facing, phase, garment = FALSE)
	// Four-direction sprites use a cardinal facing even when movement was diagonal.
	if(!(facing in list(SOUTH, NORTH, EAST, WEST)))
		facing = facing & NORTH ? NORTH : SOUTH
	return poses["[facing]|[phase]|[garment]"]

/mob/living/carbon/human/set_dir(new_dir)
	. = ..()
	if(walking_phase)
		update_icons(TRUE)

/mob/living/carbon/human/proc/walking_body_overlay()
	if(!walking_body_source)
		walking_body_source = image(stand_icon)
	return walking_overlay(walking_body_source)

// The outer wrapper retains the source's position, colors, alpha and layer.
// Each inner slice clips the existing sprite AND its nested accessories with a
// prebuilt mask. Keeping source icons intact also preserves animated equipment,
// one-direction states, blood and dynamically colored body parts.
/mob/living/carbon/human/proc/walking_overlay(source, garment = FALSE)
	if(!walking_overlay_cache)
		walking_overlay_cache = list()
	var/cache_key = "\ref[source]|[dir]|[walking_phase]|[garment]"
	if(walking_overlay_cache[cache_key])
		return walking_overlay_cache[cache_key]
	var/list/slices = SSwalking.get_pose(dir, walking_phase, garment)
	if(!slices)
		return source
	var/mutable_appearance/pose = new(source)
	pose.icon = null
	pose.icon_state = ""
	pose.overlays = null
	pose.underlays = null
	// Effects already present on the source run inside each slice before clipping.
	pose.filters = null
	for(var/list/slice in slices)
		var/mutable_appearance/part = new(source)
		part.pixel_x = slice[2]
		part.pixel_y = slice[3]
		part.transform = null
		part.color = null
		part.alpha = 255
		part.layer = FLOAT_LAYER
		part.plane = FLOAT_PLANE
		part.appearance_flags &= ~(RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART)
		part.appearance_flags |= KEEP_TOGETHER
		part.filters += filter(type = "alpha", icon = slice[1])
		if(slice[4])
			part.filters += filter(type = "color", color = rgb(210, 210, 210))
		pose.overlays += part
	walking_overlay_cache[cache_key] = pose
	return pose

