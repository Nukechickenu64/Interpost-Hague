var/global/list/depth_layer_icon_cache = list()

/datum/depth_layer_icons
	var/icon/lower
	var/icon/upper

/proc/get_depth_layer_icons(var/source_icon, var/split_height)
	if(!source_icon || split_height <= 0)
		return

	var/cache_key = "[source_icon]-[split_height]"
	var/datum/depth_layer_icons/cached = depth_layer_icon_cache[cache_key]
	if(cached)
		return cached

	var/icon/source = icon(source_icon)
	var/source_height = source.Height()
	if(split_height >= source_height)
		return

	cached = new
	cached.lower = icon(source_icon)
	cached.lower.Crop(1, 1, source.Width(), split_height)
	cached.upper = icon(source_icon)
	cached.upper.Crop(1, split_height + 1, source.Width(), source_height)
	depth_layer_icon_cache[cache_key] = cached
	return cached

/atom/movable
	var/depth_layer_split_height
	var/depth_layer_source_icon
	var/depth_layer_upper_layer = ABOVE_HUMAN_LAYER
	var/atom/movable/overlay/depth_layer/depth_layer_upper

/atom/movable/proc/enable_depth_layering(var/split_height, var/upper_layer = ABOVE_HUMAN_LAYER)
	var/source_icon = depth_layer_source_icon || icon
	var/datum/depth_layer_icons/split_icons = get_depth_layer_icons(source_icon, split_height)
	if(!split_icons)
		return FALSE

	depth_layer_split_height = split_height
	depth_layer_source_icon = source_icon
	depth_layer_upper_layer = upper_layer
	icon = split_icons.lower

	if(!depth_layer_upper)
		depth_layer_upper = new(null, src)
		vis_contents += depth_layer_upper

	refresh_depth_layer()
	return TRUE

/atom/movable/proc/refresh_depth_layer()
	if(!depth_layer_upper || !depth_layer_source_icon)
		return

	var/datum/depth_layer_icons/split_icons = get_depth_layer_icons(depth_layer_source_icon, depth_layer_split_height)
	if(!split_icons)
		return

	icon = split_icons.lower
	depth_layer_upper.icon = split_icons.upper
	depth_layer_upper.icon_state = icon_state
	depth_layer_upper.dir = dir
	depth_layer_upper.layer = depth_layer_upper_layer
	depth_layer_upper.pixel_x = 0
	depth_layer_upper.pixel_y = depth_layer_split_height
	depth_layer_upper.color = color
	depth_layer_upper.alpha = alpha
	refresh_depth_layer_overlays()

/atom/movable/proc/disable_depth_layering()
	if(depth_layer_source_icon)
		icon = depth_layer_source_icon
	if(depth_layer_upper)
		vis_contents -= depth_layer_upper
		QDEL_NULL(depth_layer_upper)
	depth_layer_source_icon = null
	depth_layer_split_height = null
	depth_layer_upper_layer = ABOVE_HUMAN_LAYER

/atom/movable/proc/refresh_depth_layer_overlays()
	if(!depth_layer_upper)
		return

	var/list/lower_overlays = list()
	var/list/upper_overlays = list()
	for(var/overlay in overlays)
		var/mutable_appearance/lower_overlay = new(overlay)
		var/datum/depth_layer_icons/split_icons = get_depth_layer_icons(lower_overlay.icon, depth_layer_split_height)
		if(!split_icons)
			lower_overlays += lower_overlay
			continue

		var/mutable_appearance/upper_overlay = new(overlay)
		lower_overlay.icon = split_icons.lower
		upper_overlay.icon = split_icons.upper
		lower_overlays += lower_overlay
		upper_overlays += upper_overlay

	overlays = lower_overlays
	depth_layer_upper.overlays = upper_overlays

/atom/movable/proc/clear_depth_layer_overlays()
	if(depth_layer_upper)
		depth_layer_upper.overlays.Cut()

/atom/movable/proc/depth_layer_flick(var/flick_state)
	flick(flick_state, src)
	if(depth_layer_upper)
		flick(flick_state, depth_layer_upper)

/atom/movable/overlay/depth_layer
	density = FALSE
	opacity = FALSE
	mouse_opacity = 0
	layer = ABOVE_HUMAN_LAYER
	appearance_flags = PIXEL_SCALE

/atom/movable/overlay/depth_layer/New(var/newloc, var/atom/movable/owner)
	master = owner
	return ..(newloc)