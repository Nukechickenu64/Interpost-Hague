// A flat sprite controlled by a mind: no human organs, equipment or atmosphere.
/mob/living/simple_animal/cyber_avatar
	name = "cyberspace avatar"
	desc = "A flat projection of a technician's neural pattern."
	icon_state = ""
	icon_living = ""
	icon_dead = ""
	maxHealth = 100
	health = 100
	wander = FALSE
	stop_automated_movement = TRUE
	universal_speak = TRUE
	min_gas = null
	max_gas = null
	mob_swap_flags = 0
	mob_push_flags = 0
	var/obj/machinery/computer/cyberdeck/master_console
	var/list/scan_images = list()
	var/client/scan_client
	var/scan_timer
	var/scan_ready_at = 0
	var/icepick_ready_at = 0
	var/guardian_fatigue = 0

/mob/living/simple_animal/cyber_avatar/Initialize(mapload)
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		verbs += /mob/living/simple_animal/cyber_avatar/proc/eject
		verbs += /mob/living/simple_animal/cyber_avatar/proc/scan
		verbs += /mob/living/simple_animal/cyber_avatar/proc/icepick

/mob/living/simple_animal/cyber_avatar/proc/icepick()
	set name = "ICE-Pick"
	set category = "Abilities"
	if(QDELETED(master_console) || !master_console.dive_valid(src) || !master_console.instance.collection_mode || !client)
		to_chat(src, SPAN_WARNING("ICE-Pick requires an active cyberspace connection."))
		return
	var/advanced_icepick = research_network_level(/datum/tech/os13/icepick_mk2) > 0
	if(istype(GLOB.using_map, /datum/map/os13classic) && !advanced_icepick && research_network_level(/datum/tech/os13/icepick_mk1) <= 0)
		to_chat(src, SPAN_WARNING("Install ICE-Pick software at the Replicator before using it."))
		return
	if(world.time < icepick_ready_at)
		to_chat(src, SPAN_WARNING("ICE-Pick is recharging: [ceil((icepick_ready_at - world.time) / 10)] seconds remaining."))
		return
	var/obj/machinery/computer/cyberdeck/C = master_console
	var/session = C.dive_id
	var/list/targets = list()
	for(var/atom/A in view(1, src))
		if((istype(A, /obj/effect/cyberdeck_node) || istype(A, /turf/unsimulated/wall/cyberdeck)) && A.alpha > 0 && A.invisibility <= see_invisible)
			targets += A
	if(!length(targets))
		to_chat(src, SPAN_NOTICE("No nearby archive information can be removed."))
		return
	var/atom/target = input(src, "Choose nearby information to remove. Removing useful data prevents completing this download; removing the exit leaves EJECT as your way out.", "ICE-Pick") as null|anything in targets
	if(QDELETED(src))
		return
	if(!target)
		to_chat(src, SPAN_NOTICE("ICE-Pick cancelled."))
		return
	if(QDELETED(target))
		to_chat(src, SPAN_WARNING("That information is no longer available."))
		return
	if(istype(target, /obj/effect/cyberdeck_node/data_fragment) || istype(target, /obj/effect/cyberdeck_node/exit))
		if(alert(src, "Permanently remove [target.name] from this dive? Removing research data prevents completion. Removing the exit leaves EJECT available.", "Destructive ICE-Pick operation", "Remove", "Cancel") != "Remove")
			if(!QDELETED(src))
				to_chat(src, SPAN_NOTICE("ICE-Pick cancelled."))
			return
	if(QDELETED(src))
		return
	if(QDELETED(C) || master_console != C || C.dive_id != session || !C.dive_valid(src) || !client || world.time < icepick_ready_at)
		to_chat(src, SPAN_WARNING("The session or ICE-Pick recharge changed. Nothing was removed."))
		return
	if(!C.instance.erase_information(target, src))
		to_chat(src, SPAN_WARNING("That information is no longer available for ICE-Pick. Nothing was removed."))
		return
	icepick_ready_at = world.time + (advanced_icepick ? 3 SECONDS : 30 SECONDS)

/mob/living/simple_animal/cyber_avatar/proc/clear_scan()
	if(scan_timer)
		deltimer(scan_timer)
		scan_timer = null
	if(scan_client)
		scan_client.images -= scan_images
	scan_images.Cut()
	scan_client = null

/mob/living/simple_animal/cyber_avatar/proc/scan()
	set name = "Scan"
	set category = "Abilities"
	if(QDELETED(master_console) || !master_console.dive_valid(src) || !master_console.instance.collection_mode || !client)
		to_chat(src, SPAN_WARNING("Scan requires an active cyberspace connection."))
		return
	var/advanced_scan = research_network_level(/datum/tech/os13/scan_mk2) > 0
	if(!advanced_scan && research_network_level(/datum/tech/os13/scan_mk1) <= 0)
		to_chat(src, SPAN_WARNING("Install Scan software at a Replicator console before using it."))
		return
	if(world.time < scan_ready_at)
		to_chat(src, SPAN_WARNING("Scan is recharging: [ceil((scan_ready_at - world.time) / 10)] seconds remaining."))
		return
	clear_scan()
	scan_ready_at = world.time + (advanced_scan ? 3 SECONDS : 30 SECONDS)
	scan_client = client
	for(var/atom/A in view(client.view, src))
		if(!istype(A, /obj/effect/cyberdeck_node) && !istype(A, /turf/unsimulated/wall/cyberdeck) && !istype(A, /turf/unsimulated/floor/cyberdeck) && !istype(A, /mob/living/simple_animal/cyber_avatar))
			continue
		if(A.invisibility > see_invisible || A.alpha <= 0)
			continue
		var/image/marker = image(loc = A)
		marker.appearance = A.appearance
		marker.color = "#66ffff"
		marker.alpha = 180
		marker.layer = A.layer + 0.1
		scan_images += marker
	scan_client.images += scan_images
	scan_timer = addtimer(CALLBACK(src, .proc/clear_scan), 3 SECONDS, TIMER_STOPPABLE)
	to_chat(src, SPAN_NOTICE("Scan highlights the visible archive grid, avatars, ICE and data."))

/mob/living/simple_animal/cyber_avatar/proc/copy_body_appearance(mob/living/carbon/human/H)
	name = H.real_name
	real_name = H.real_name
	gender = H.gender
	if(!H.stand_icon)
		H.update_body(FALSE)
	var/image/naked = image(H.stand_icon)
	// Use the unmasked hair, even if the physical helmet hides it.
	var/obj/item/organ/external/head/head_organ = H.get_organ(BP_HEAD)
	if(head_organ)
		var/image/hair = head_organ.get_hair_icon()
		if(hair)
			naked.overlays += hair
	for(var/overlay_index in list(SKIN_LAYER, BODYHAIR_LAYER))
		if(H.overlays_standing[overlay_index])
			naked.overlays += H.overlays_standing[overlay_index]
	var/species_tail = H.species.get_tail(H)
	if(species_tail)
		naked.overlays += image(H.get_tail_icon(), icon_state = "[species_tail]_s")
	var/icon/flat = icon('icons/effects/effects.dmi', "nothing")
	for(var/direction in GLOB.cardinal)
		flat.Insert(getFlatIcon(naked, direction, always_use_defdir = TRUE), dir = direction)
	icon = flat
	icon_state = ""
	overlays.Cut()
	set_dir(H.dir)

/mob/living/simple_animal/cyber_avatar/handle_atmos()
	return // This avatar has no biological needs.

/mob/living/simple_animal/cyber_avatar/get_move_intent_delay()
	. = ..()
	if(!QDELETED(master_console) && master_console.dive_valid(src) && master_console.instance.collection_mode && master_console.advanced_port_active())
		. = max(0.5, . / 2)
	. += guardian_fatigue

/mob/living/simple_animal/cyber_avatar/UnarmedAttack(atom/A, proximity)
	if(stat != CONSCIOUS || !proximity || !Adjacent(A))
		return
	if(istype(A, /obj/effect/cyberdeck_node))
		var/obj/effect/cyberdeck_node/N = A
		N.interact(src)
	else if(istype(A, /turf/unsimulated/wall/cyberdeck) && !QDELETED(master_console) && master_console.dive_body == src && master_console.instance)
		master_console.instance.deactivate_ice(A, src)

/mob/living/simple_animal/cyber_avatar/verb/recall()
	set name = "Recall"
	set category = "Abilities"
	if(!QDELETED(master_console) && master_console.dive_body == src)
		master_console.end_dive("You recalled your avatar. No data was written.")

/mob/living/simple_animal/cyber_avatar/proc/eject()
	set name = "EJECT"
	set category = "Abilities"
	recall()

/mob/living/simple_animal/cyber_avatar/Stat()
	..()
	if(!QDELETED(master_console) && master_console.dive_body == src && master_console.instance && statpanel("Status"))
		var/datum/cyberdeck_instance/I = master_console.instance
		if(I.collection_mode)
			stat("DATA LEFT", max(0, I.required_keys - I.decrypted))
			stat("Scan recharge", "[max(0, ceil((scan_ready_at - world.time) / 10))] seconds")
			stat("ICE-Pick recharge", "[max(0, ceil((icepick_ready_at - world.time) / 10))] seconds")
		else
			stat("Relays decrypted", "[I.decrypted]/[I.required_keys]")
		stat("Archive connection", "[max(0, round((master_console.dive_deadline - world.time) / 10))] seconds")

/mob/living/simple_animal/cyber_avatar/death(gibbed, deathmessage, show_dead_message)
	if(!QDELETED(master_console) && master_console.dive_body == src)
		master_console.forced_eject("Avatar integrity lost. Your body has been recalled; no data was written.")
		return TRUE
	return ..()

/mob/living/simple_animal/cyber_avatar/Destroy()
	clear_scan()
	if(!QDELETED(master_console) && master_console.dive_body == src)
		master_console.forced_eject("Your cyberspace avatar was disconnected.")
	return ..()

/mob/living/simple_animal/cyber_avatar/Logout()
	clear_scan()
	return ..()
