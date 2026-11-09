// Deathweb's observer powers, adapted to the local ghost, lighting and organ systems.
// Every effect that reaches the physical realm checks the current round Phi.
/proc/wraith_effects_allowed()
	return SSticker && isnum(SSticker.phi) && SSticker.phi > 90

/mob/observer/ghost/proc/can_affect_world(notify = FALSE)
	if(!QDELETED(src) && wraith_effects_allowed())
		return TRUE
	if(notify)
		to_chat(src, SPAN_WARNING("The shroud holds. Physical effects require Phi above 90."))
	return FALSE

/proc/ghost_can_affect_world(mob/user, notify = FALSE)
	var/mob/observer/ghost/ghost = user
	return !istype(ghost) || ghost.can_affect_world(notify)

/mob/observer/ghost
	var/wraith_pain = 0
	var/next_wraith_dream

/obj/screen/fullscreen/wraith_vignette
	icon = 'icons/os13/wraith/vignette.dmi'
	icon_state = "ghost"
	allstate = TRUE
	layer = FULLSCREEN_LAYER

/obj/effect/wraith_echo
	name = "echo of pain"
	desc = "A trace of someone's last pain. Wraiths can collect it."
	icon = 'icons/os13/wraith/spectres.dmi'
	icon_state = "pain"
	anchored = TRUE
	invisibility = INVISIBILITY_OBSERVER
	appearance_flags = NO_CLIENT_COLOR
	simulated = FALSE

/obj/effect/wraith_echo/Crossed(atom/movable/mover)
	. = ..()
	var/mob/observer/ghost/ghost = mover
	if(QDELETED(src) || !istype(ghost) || ghost.loc != loc)
		return
	ghost.wraith_pain += 5
	to_chat(ghost, SPAN_NOTICE("You collect 5 Pain."))
	sound_to(ghost, sound('sound/os13/wraith/pain_sound.ogg', volume = 70))
	qdel(src)

/mob/observer/ghost/verb/wraith_jaunt()
	set name = "Jaunt (5 Pain)"
	set category = "Wraith"
	if(!client || pain_possession_object)
		return
	if(wraith_pain < 5)
		to_chat(src, SPAN_WARNING("Jaunt requires 5 Pain."))
		return
	var/list/choices = list()
	for(var/mob/living/carbon/human/target in GLOB.player_list)
		if(target.stat != DEAD && get_turf(target))
			choices += target
	if(!choices.len)
		return
	var/mob/living/carbon/human/target = input(src, "Whose presence do you seek?", "Jaunt") as null|anything in choices
	if(!client || QDELETED(target) || target.stat == DEAD || !(target in choices) || pain_possession_object || wraith_pain < 5)
		return
	var/turf/destination = get_turf(target)
	if(!destination || destination == loc || check_is_holy_turf(destination))
		return
	ghost_to_turf(destination)
	if(loc == destination)
		wraith_pain -= 5

/mob/observer/ghost/verb/wraith_ascend()
	set name = "Ascend (30 Pain)"
	set category = "Wraith"
	if(!client || pain_possession_object || wraith_pain < 30)
		to_chat(src, SPAN_WARNING("Ascension requires 30 Pain and a free spirit."))
		return
	if(!config.abandon_allowed || !SSticker.mode || SSticker.mode.deny_respawn || !MayRespawn(1, config.respawn_delay))
		to_chat(src, SPAN_WARNING("You cannot return to the lobby yet."))
		return
	wraith_pain -= 30
	announce_ghost_joinleave(client, 0)
	var/mob/new_player/lobby = new
	lobby.key = key

/mob/observer/ghost/proc/wraith_flicker(obj/machinery/light/fixture, spend_pain = TRUE)
	if(!can_affect_world(TRUE) || QDELETED(fixture) || !fixture.Adjacent(src) || !fixture.on || pain_possession_object)
		return FALSE
	var/turf/origin = get_turf(src)
	var/turf/fixture_turf = get_turf(fixture)
	if(!origin || origin.holy || !fixture_turf || fixture_turf.holy)
		return FALSE
	if(spend_pain && wraith_pain < 1)
		to_chat(src, SPAN_WARNING("Flickering this light requires 1 Pain."))
		return FALSE
	if(!spend_pain && bootime > world.time)
		return FALSE
	if(!fixture.flicker(spectral_source = src))
		return FALSE
	if(spend_pain)
		wraith_pain--
	else
		bootime = world.time + 1 MINUTE
	return TRUE

/mob/observer/ghost/verb/wraith_boo()
	set name = "Flick the Lights"
	set category = "Wraith"
	if(!can_affect_world(TRUE))
		return
	for(var/obj/machinery/light/fixture in range(1, src))
		if(wraith_flicker(fixture, FALSE))
			return

/mob/observer/ghost/verb/wraith_dream(message as text)
	set name = "Intervene in Dreams"
	set category = "Wraith"
	if(!can_affect_world(TRUE) || !client)
		return
	message = sanitize(copytext(message, 1, MAX_MESSAGE_LEN))
	if(!message || next_wraith_dream > world.time || pain_possession_object)
		return
	var/decl/communication_channel/dsay/deadchat = decls_repository.get_decl(/decl/communication_channel/dsay)
	if(!deadchat.can_communicate(client, message, /decl/dsay_communication/say))
		return
	var/delivered = FALSE
	for(var/mob/living/carbon/human/target in hearers(7, src))
		if(wraith_deliver_dream(target, message))
			delivered = TRUE
	if(delivered)
		next_wraith_dream = world.time + 30 SECONDS
		log_say("Wraith dream/[key_name(src)]: [message]")

/mob/observer/ghost/proc/wraith_deliver_dream(mob/living/carbon/human/target, message)
	if(!can_affect_world() || QDELETED(target) || target.stat == DEAD || !(target.sleeping || target.stat == UNCONSCIOUS) || !message)
		return FALSE
	var/turf/origin = get_turf(src)
	var/turf/destination = get_turf(target)
	if(!origin || origin.holy || !destination || destination.holy || destination.z != origin.z || get_dist(origin, destination) > 7)
		return FALSE
	to_chat(target, "<span class='notice'><i>... [message] ...</i></span>")
	if(prob(12))
		sound_to(target, sound('sound/os13/wraith/ghost_effect.ogg', volume = 25))
	return TRUE

/proc/is_grue_dark_turf(turf/site)
	return site && !site.density && !isopenspace(site) && !istype(site, /turf/space) && !site.holy && !site.luminosity && site.get_lumcount() <= LIGHTING_ROUND_VALUE

/mob/observer/ghost/verb/wraith_summon_grue()
	set name = "Summon Grue (15 Pain)"
	set category = "Wraith"
	wraith_create_grue()

/mob/observer/ghost/proc/wraith_create_grue()
	if(!can_affect_world(TRUE) || pain_possession_object || wraith_pain < 15)
		return null
	var/turf/site = get_turf(src)
	if(!is_grue_dark_turf(site))
		to_chat(src, SPAN_WARNING("A grue needs solid ground in darkness."))
		return null
	var/mob/living/simple_animal/os13_grue/grue = new(site)
	wraith_pain -= 15
	log_game("[key_name(src)] summoned a grue at [site.x],[site.y],[site.z].")
	return grue

/mob/living/simple_animal/os13_grue
	name = "grue"
	desc = "A shadow that shuns the light."
	icon = 'icons/os13/wraith/spectres.dmi'
	icon_state = "grue"
	icon_living = "grue"
	icon_dead = "grue"
	invisibility = INVISIBILITY_OBSERVER
	appearance_flags = NO_CLIENT_COLOR
	density = FALSE
	anchored = TRUE
	wander = FALSE
	supernatural = TRUE
	possession_candidate = FALSE

/mob/living/simple_animal/os13_grue/Life()
	if(!wraith_effects_allowed() || !is_grue_dark_turf(get_turf(src)))
		qdel(src)
		return
	. = ..()
	if(stat == DEAD || QDELETED(src))
		qdel(src)
		return
	var/turf/next = get_step(src, pick(GLOB.cardinal))
	if(is_grue_dark_turf(next))
		step_towards(src, next)

/mob/living/simple_animal/os13_grue/Crossed(atom/movable/mover)
	. = ..()
	if(!wraith_effects_allowed() || stat == DEAD || !is_grue_dark_turf(get_turf(src)))
		return
	var/mob/living/carbon/human/victim = mover
	if(!istype(victim) || victim.loc != loc || victim.stat != CONSCIOUS || (victim.status_flags & GODMODE) || victim.is_leech())
		return
	var/obj/item/organ/internal/heart/heart = victim.internal_organs_by_name[BP_HEART]
	if(!istype(heart) || heart.robotic >= ORGAN_ROBOT || heart.pulse == PULSE_NONE)
		return
	heart.pulse = PULSE_NONE
	heart.heartbeat = 0
	to_chat(victim, SPAN_DANGER("Something in the darkness stops your heart!"))
	sound_to(victim, sound('sound/os13/wraith/ghost_effect.ogg', volume = 70))
