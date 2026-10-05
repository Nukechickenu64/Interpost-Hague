/mob/living/carbon/human
	var/list/blind_tile_images = list()

/mob/living/carbon/human/ClickOn(atom/A, params, mob/user, client/client)
	var/turf/interacted_tile
	if(A && src.client && can_sense_blind_tiles() && world.time > next_click && canClick() && !restrained() && !in_throw_mode && isturf(loc))
		var/list/modifiers = params2list(params)
		if(!modifiers["shift"] && !modifiers["ctrl"] && !modifiers["alt"] && !modifiers["middle"] && !(modifiers["right"] && c_intent == I_GUARD))
			if((isturf(A) || isturf(A.loc)) && A.Adjacent(src))
				interacted_tile = get_turf(A)
	. = ..()
	if(interacted_tile && !QDELETED(interacted_tile))
		reveal_blind_tile(interacted_tile)

/mob/living/carbon/human/Bump(atom/movable/A, yes)
	var/turf/interacted_tile = get_turf(A)
	. = ..()
	if(yes && interacted_tile && !QDELETED(interacted_tile))
		reveal_blind_tile(interacted_tile)

/mob/living/carbon/human/proc/can_sense_blind_tiles()
	return eye_closed && stat == CONSCIOUS && !sleeping && !voluntary_sleeping && !waking_up && !paralysis && !stunned && !weakened

/mob/living/carbon/human/proc/reveal_blind_tile(turf/T)
	if(!client || !can_sense_blind_tiles() || !isturf(loc) || !Adjacent(T))
		return
	var/state = T.get_blind_sense_state()
	var/best_priority = -1
	for(var/atom/movable/A in T)
		if(A == src || A.invisibility || QDELETED(A))
			continue
		var/candidate_state = A.get_blind_sense_state()
		if(!candidate_state)
			continue
		var/priority = (candidate_state != "?" ? 100 : 0) + (A.density ? 20 : 0) + (A.anchored ? 10 : 0) + A.layer
		if(priority > best_priority)
			best_priority = priority
			state = candidate_state

	var/image/marker = blind_tile_images[T]
	if(!marker)
		marker = image('icons/mob/screen/blind.dmi', T)
		// The normal emissive plane is hidden by the closed-eye fullscreen overlay.
		marker.plane = BLIND_SENSE_PLANE
		marker.layer = BLIND_SENSE_LAYER
		marker.mouse_opacity = 0
		marker.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | NO_CLIENT_COLOR
		marker.filters = filter(type = "bloom", threshold = EMISSIVE_BLOOM_THRESHOLD, size = EMISSIVE_BLOOM_SIZE, offset = EMISSIVE_BLOOM_OFFSET, alpha = EMISSIVE_BLOOM_ALPHA)
		blind_tile_images[T] = marker
		add_client_image(marker)
	marker.icon_state = state
	addtimer(CALLBACK(src, /mob/living/carbon/human/proc/remove_blind_tile, T), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/carbon/human/proc/remove_blind_tile(turf/T)
	var/image/marker = blind_tile_images[T]
	if(!marker)
		return
	remove_client_image(marker)
	blind_tile_images -= T

/mob/living/carbon/human/proc/clear_blind_tiles()
	for(var/turf/T as anything in blind_tile_images)
		remove_client_image(blind_tile_images[T])
	blind_tile_images.Cut()

/atom/proc/get_blind_sense_state()
	return null

/turf/get_blind_sense_state()
	return density ? "wall" : "floor"

/turf/simulated/open/get_blind_sense_state()
	return "open"

/obj/get_blind_sense_state()
	return "?"

/obj/effect/get_blind_sense_state()
	return null

/obj/screen/get_blind_sense_state()
	return null

/obj/machinery/door/get_blind_sense_state()
	return density ? "door" : "open"

/obj/structure/table/get_blind_sense_state()
	return "table"

/obj/structure/closet/get_blind_sense_state()
	return "closet"

/obj/structure/closet/crate/get_blind_sense_state()
	return "chest"

/obj/structure/closet/statue/get_blind_sense_state()
	return "statue"

/obj/structure/bed/get_blind_sense_state()
	return "bed"

/obj/structure/bed/chair/get_blind_sense_state()
	return "chair"

/mob/living/get_blind_sense_state()
	return stat == DEAD ? "corpse" : "?"

/mob/living/simple_animal/mushroom/get_blind_sense_state()
	return stat == DEAD ? "corpse" : "mushroom"

/obj/item/reagent_containers/food/snacks/grown/mushroom/get_blind_sense_state()
	return "mushroom"
