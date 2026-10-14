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

/mob/living/simple_animal/cyber_avatar/UnarmedAttack(atom/A, proximity)
	if(stat != CONSCIOUS || !proximity || !Adjacent(A))
		return
	if(istype(A, /obj/effect/cyberdeck_node))
		var/obj/effect/cyberdeck_node/N = A
		N.interact(src)

/mob/living/simple_animal/cyber_avatar/verb/recall()
	set name = "Recall"
	set category = "Abilities"
	if(master_console)
		master_console.end_dive("You recalled your avatar. No data was written.")

/mob/living/simple_animal/cyber_avatar/Stat()
	..()
	if(master_console && master_console.instance && statpanel("Status"))
		var/datum/cyberdeck_instance/I = master_console.instance
		stat("Relays decrypted", "[I.decrypted]/[I.required_keys]")
		stat("Archive connection", "[max(0, round((master_console.dive_deadline - world.time) / 10))] seconds")

/mob/living/simple_animal/cyber_avatar/death(gibbed, deathmessage, show_dead_message)
	if(master_console)
		master_console.end_dive("Avatar integrity lost. Your body has been recalled; no data was written.")
		return TRUE
	return ..()

/mob/living/simple_animal/cyber_avatar/Destroy()
	if(master_console)
		master_console.end_dive("Your cyberspace avatar was disconnected.")
	return ..()
