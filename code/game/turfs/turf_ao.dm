// Ambient occlusion is globally disabled. Keep compatibility hooks for turf
// replacement and multiz callers; they only remove obsolete AO appearances.
/turf
	var/permit_ao = FALSE
	var/image/ao_receiver
	var/list/ao_overlays
	var/ao_neighbors = AO_ALL_NEIGHBORS
	var/list/ao_overlays_mimic
	var/ao_neighbors_mimic = AO_ALL_NEIGHBORS
	var/ao_queued = AO_UPDATE_NONE

/turf/proc/queue_ao(rebuild = TRUE)
	update_ao()

/turf/proc/regenerate_ao()
	update_ao()

/turf/proc/calculate_ao_neighbors()
	ao_neighbors = AO_ALL_NEIGHBORS
	ao_neighbors_mimic = AO_ALL_NEIGHBORS

/turf/proc/update_ao()
	if(ao_overlays)
		overlays -= ao_overlays
		ao_overlays = null
	if(ao_overlays_mimic)
		if(shadower)
			shadower.overlays -= ao_overlays_mimic
		ao_overlays_mimic = null
	sync_ao_receiver()

/turf/proc/sync_ao_receiver()
	if(ao_receiver)
		overlays -= ao_receiver.appearance
		QDEL_NULL(ao_receiver)

// A floor viewed through an upper shaft must not become a receiver on that
// upper level; otherwise its absolute mask plane can shade lower-level sprites.
/turf/proc/ao_mimic_appearance()
	if(!ao_receiver)
		return appearance
	var/mutable_appearance/copy = new(src)
	copy.overlays -= ao_receiver.appearance
	return copy

// Inert compatibility types: no targets, sources, filters or visible AO output.
/obj/screen/plane_master/world_ao
	name = "disabled ambient occlusion"
	plane = DEFAULT_PLANE
	mouse_opacity = 1

/obj/screen/plane_master/world_ao_receivers
	name = "disabled ambient occlusion receivers"
	plane = WORLD_AO_RECEIVER_SOURCE_PLANE
	mouse_opacity = 0

/obj/screen/world_ao_display
	name = ""
	screen_loc = "SCREEN_SOUTHWEST"
	plane = WORLD_SHADOW_DISPLAY_PLANE
	layer = WORLD_AO_DISPLAY_LAYER
	alpha = 0
	mouse_opacity = 0
