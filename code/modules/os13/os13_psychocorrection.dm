// MED 00:15:50-00:18:40; GEN 01:05:00. See docs/os13_psychocorrection_parity.md.
// Hardware/recording and Sleep are observed; other trigger effects and numeric
// timings/skill checks are local reconstruction, not recovered source values.
/proc/os13_mnemonic_word(message)
	if(!istext(message))
		return null
	message = lowertext(trim(message))
	while(length(message) && (copytext(message, -1) in list("!", ".", "?")))
		message = copytext(message, 1, -1)
	var/static/regex/word = regex("^\[a-z]\[a-z'-]{0,23}$")
	return word.Find(message) ? message : null

/obj/item/organ/internal/brain
	var/list/os13_conditioned_triggers
	var/os13_conditioning_revision = 0
	var/os13_next_conditioned_trigger = 0

/datum/happiness_event/os13_conditioned_panic
	description = "<span class='danger'>That word fills me with fear!</span>\n"
	happiness = -10
	timeout = 1 MINUTE

/mob/living/carbon/human/proc/os13_conditioning_brain()
	var/obj/item/organ/internal/brain/brain = internal_organs_by_name[BP_BRAIN]
	if(!istype(brain) || brain.owner != src || !brain.is_usable() || isSynthetic())
		return null
	return brain

/mob/living/carbon/human/hear_say(message, verb = "says", datum/language/language = null, alt_name = "", italics = 0, mob/speaker = null, sound/speech_sound, sound_vol)
	os13_receive_mnemonic(message, speaker, language)
	return ..()

/mob/living/carbon/human/proc/os13_receive_mnemonic(message, mob/speaker, datum/language/language)
	var/obj/item/organ/internal/brain/brain = os13_conditioning_brain()
	if(!brain?.os13_conditioned_triggers?.len || stat != CONSCIOUS || sleeping || is_deaf() || !isliving(speaker) || speaker.stat == DEAD || speaker.z != z || !(speaker in hearers(7, src)) || !say_understands(speaker, language))
		return FALSE
	if(language && (language.flags & (NONVERBAL|SIGNLANG|INNATE)))
		return FALSE
	// Match the normal hear_say listener-side vacuum/contact-hearing rule.
	var/turf/tile = get_turf(src)
	var/datum/gas_mixture/air = tile?.return_air()
	if((!air || air.get_tile_moles() < PRESSURE_TO_MOLES(SOUND_MINIMUM_PRESSURE)) && get_dist(speaker, src) > 1)
		return FALSE
	var/word = os13_mnemonic_word(message)
	if(!word || world.time < brain.os13_next_conditioned_trigger)
		return FALSE
	for(var/mode in brain.os13_conditioned_triggers)
		if(brain.os13_conditioned_triggers[mode] != word)
			continue
		brain.os13_next_conditioned_trigger = world.time + 3 SECONDS
		switch(mode)
			if("SLEEP")
				Sleeping(10)
			if("PANIC")
				add_event("os13_conditioned_panic", /datum/happiness_event/os13_conditioned_panic)
				make_jittery(10)
				to_chat(src, SPAN_DANGER("A wave of panic overwhelms you!"))
			if("COMBAT")
				combat_mode = TRUE
				if(combat_icon)
					combat_icon.icon_state = "cmbt1"
				to_chat(src, SPAN_WARNING("Your conditioned combat reflexes engage!"))
		log_game("[key_name(src)] responded to conditioned [mode] trigger spoken by [key_name(speaker)].")
		return TRUE
	return FALSE

/obj/machinery/os13_correctional_apparatus
	name = "Correctional Apparatus"
	desc = "A seated neural-conditioning apparatus operated from a linked Psychocorrectional Console."
	icon = 'icons/os13/objects/objects/weapons/surgery.dmi'
	icon_state = "torturechair"
	anchored = TRUE
	density = FALSE
	obj_flags = OBJ_FLAG_ANCHORABLE
	can_buckle = TRUE
	buckle_lying = FALSE
	idle_power_usage = 50
	active_power_usage = 2500
	var/obj/machinery/computer/os13_psychocorrection/console

/obj/machinery/os13_correctional_apparatus/post_buckle_mob(mob/living/subject)
	..()
	if(console?.session && console.session.subject != buckled_mob)
		console.cancel_procedure("The subject left the apparatus.")

/obj/machinery/os13_correctional_apparatus/attack_hand(mob/user)
	// Mechanical seat release must remain usable during an electrical outage.
	if(buckled_mob && user && !user.incapacitated() && Adjacent(user))
		return user_unbuckle_mob(user)
	return ..()

/obj/machinery/os13_correctional_apparatus/power_change()
	. = ..()
	if(inoperable() && console?.session)
		console.cancel_procedure("The apparatus lost power.")

/obj/machinery/os13_correctional_apparatus/Destroy()
	if(console)
		console.unlink_apparatus()
	return ..()

/obj/machinery/computer/os13_psychocorrection
	name = "Psychocorrectional Console"
	desc = "A keycard-locked console for a nearby Correctional Apparatus. Swipe a medical ID to unlock it."
	icon = 'icons/os13/objects/objects/computer.dmi'
	icon_state = "mtnc"
	icon_keyboard = null
	icon_screen = null
	obj_flags = OBJ_FLAG_ANCHORABLE
	req_one_access = list(access_medical)
	var/locked = TRUE
	var/obj/machinery/os13_correctional_apparatus/apparatus
	var/datum/os13_psychocorrection_session/session
	var/procedure_time = 5 SECONDS

/obj/machinery/computer/os13_psychocorrection/proc/can_operate(mob/user)
	return !QDELETED(src) && user && !user.incapacitated() && Adjacent(user) && anchored && operable() && powered() && !locked && allowed(user)

/obj/machinery/computer/os13_psychocorrection/proc/compatible_apparatus(obj/machinery/os13_correctional_apparatus/target)
	return !QDELETED(target) && isturf(loc) && isturf(target.loc) && target.z == z && get_area(target) == get_area(src) && get_dist(target, src) <= 4 && target.anchored && (!target.console || target.console == src)

/obj/machinery/computer/os13_psychocorrection/proc/link_apparatus(obj/machinery/os13_correctional_apparatus/target)
	if(session || !compatible_apparatus(target))
		return FALSE
	unlink_apparatus()
	apparatus = target
	target.console = src
	return TRUE

/obj/machinery/computer/os13_psychocorrection/proc/unlink_apparatus()
	cancel_procedure("The apparatus connection was removed.")
	if(apparatus?.console == src)
		apparatus.console = null
	apparatus = null

/obj/machinery/computer/os13_psychocorrection/proc/select_apparatus(mob/user)
	if(!can_operate(user) || session)
		return FALSE
	var/list/choices = list()
	for(var/obj/machinery/os13_correctional_apparatus/target in range(4, src))
		if(compatible_apparatus(target))
			choices["[target.name] ([target.x],[target.y])"] = target
	if(!choices.len)
		to_chat(user, SPAN_WARNING("No available apparatus is connected in this room."))
		return FALSE
	var/choice
	if(choices.len == 1)
		choice = choices[1]
	else
		choice = input(user, "Select an apparatus.", name) as null|anything in choices
	if(!choice || !can_operate(user))
		return FALSE
	return link_apparatus(choices[choice])

/obj/machinery/computer/os13_psychocorrection/proc/begin_procedure(mob/user, mode)
	if(!can_operate(user) || session || !(mode in list("SLEEP", "PANIC", "COMBAT", "CLEAR")) || !compatible_apparatus(apparatus) || apparatus.console != src)
		return FALSE
	var/mob/living/carbon/human/subject = apparatus.buckled_mob
	var/obj/item/organ/internal/brain/brain = istype(subject) ? subject.os13_conditioning_brain() : null
	if(!brain || subject.stat == DEAD || apparatus.inoperable() || !apparatus.powered())
		to_chat(user, SPAN_WARNING("A living organic subject must be seated in an operational apparatus."))
		return FALSE
	session = new(src, user, subject, brain, mode)
	apparatus.update_use_power(POWER_USE_ACTIVE)
	if(mode == "CLEAR")
		var/datum/os13_psychocorrection_session/job = session
		spawn(0)
			if(!QDELETED(job))
				job.perform()
	else
		to_chat(user, SPAN_NOTICE("Recording started. Exclaim the trigger-word."))
		addtimer(CALLBACK(session, /datum/os13_psychocorrection_session/proc/recording_expired), 30 SECONDS)
	return TRUE

/obj/machinery/computer/os13_psychocorrection/proc/cancel_procedure(reason)
	if(!session)
		return
	to_chat(session.operator, SPAN_WARNING(reason))
	QDEL_NULL(session)
	if(apparatus)
		apparatus.update_use_power(POWER_USE_IDLE)

/obj/machinery/computer/os13_psychocorrection/hear_talk(mob/speaker, message, verb, datum/language/language)
	..()
	if(!session || session.working || speaker != session.operator || !session.valid() || (language && (language.flags & (NONVERBAL|SIGNLANG|INNATE))))
		return
	var/word = os13_mnemonic_word(message)
	if(!word)
		return
	if(session.brain.os13_conditioned_triggers)
		for(var/mode in session.brain.os13_conditioned_triggers)
			if(mode != session.mode && session.brain.os13_conditioned_triggers[mode] == word)
				to_chat(speaker, SPAN_WARNING("That mnemonic already activates a different response. Record another word."))
				return
	session.word = word
	session.working = TRUE
	to_chat(speaker, SPAN_NOTICE("Mnemonic audiosignal recorded successfully."))
	var/datum/os13_psychocorrection_session/job = session
	spawn(0)
		if(!QDELETED(job))
			job.perform()

/obj/machinery/computer/os13_psychocorrection/attack_hand(mob/user)
	if(!can_operate(user))
		to_chat(user, SPAN_WARNING("Not possible. The controls require an operational console, an unlocked keycard lock and medical access."))
		return
	if(!apparatus && !select_apparatus(user))
		return
	var/list/actions = list("Trigger (SLEEP)" = "SLEEP", "Trigger (PANIC)" = "PANIC", "Trigger (COMBAT)" = "COMBAT", "Clear conditioned triggers" = "CLEAR", "Select apparatus" = "LINK", "Cancel procedure" = "CANCEL")
	var/choice = input(user, "Select a procedure.", name) as null|anything in actions
	if(!choice || !can_operate(user))
		return
	switch(actions[choice])
		if("LINK")
			select_apparatus(user)
		if("CANCEL")
			cancel_procedure("The operator cancelled the procedure.")
		else
			begin_procedure(user, actions[choice])

/obj/machinery/computer/os13_psychocorrection/attackby(obj/item/item, mob/user)
	var/obj/item/card/id/card = item.GetIdCard()
	if(!card)
		return ..()
	if(!user || user.incapacitated() || !Adjacent(user) || item.loc != user || (user.get_active_hand() != item && user.get_inactive_hand() != item) || !operable() || !powered() || !check_access(card))
		return
	locked = !locked
	if(locked)
		cancel_procedure("The controls were locked.")
	visible_message(SPAN_NOTICE("[user] [locked ? "locks" : "unlocks"] the Psychocorrectional Console!"))
	add_fingerprint(user)

/obj/machinery/computer/os13_psychocorrection/Process()
	if(session && !session.valid())
		cancel_procedure("The procedure was interrupted.")

/obj/machinery/computer/os13_psychocorrection/power_change()
	. = ..()
	if(inoperable())
		cancel_procedure("The console lost power.")
	update_icon()

/obj/machinery/computer/os13_psychocorrection/update_icon()
	overlays.Cut()
	icon_state = (stat & BROKEN) ? "mtncb" : ((stat & NOPOWER) ? "mtnc0" : "mtnc")
	set_light(operable() ? 1 : 0, 0.4, "#c060d0")

/obj/machinery/computer/os13_psychocorrection/Destroy()
	unlink_apparatus()
	return ..()

/datum/os13_psychocorrection_session
	var/obj/machinery/computer/os13_psychocorrection/console
	var/obj/machinery/os13_correctional_apparatus/apparatus
	var/mob/operator
	var/mob/living/carbon/human/subject
	var/obj/item/organ/internal/brain/brain
	var/turf/seat_turf
	var/revision
	var/mode
	var/word
	var/working = FALSE

/datum/os13_psychocorrection_session/New(obj/machinery/computer/os13_psychocorrection/new_console, mob/new_operator, mob/living/carbon/human/new_subject, obj/item/organ/internal/brain/new_brain, new_mode)
	console = new_console
	apparatus = console.apparatus
	operator = new_operator
	subject = new_subject
	brain = new_brain
	revision = brain.os13_conditioning_revision
	seat_turf = get_turf(apparatus)
	mode = new_mode
	..()

/datum/os13_psychocorrection_session/proc/valid()
	return !QDELETED(src) && !QDELETED(console) && console.session == src && console.can_operate(operator) && !QDELETED(apparatus) && console.apparatus == apparatus && console.compatible_apparatus(apparatus) && apparatus.console == console && apparatus.operable() && apparatus.powered() && get_turf(apparatus) == seat_turf && !QDELETED(subject) && subject.loc == seat_turf && apparatus.buckled_mob == subject && subject.buckled == apparatus && subject.stat != DEAD && subject.os13_conditioning_brain() == brain && brain.os13_conditioning_revision == revision

/datum/os13_psychocorrection_session/proc/recording_expired()
	if(!working && console?.session == src)
		console.cancel_procedure("Recording timed out.")

/obj/machinery/computer/os13_psychocorrection/proc/procedure_succeeds(mob/user)
	var/list/result = user.gurps_skill_roll("medical")
	return result["success"]

/datum/os13_psychocorrection_session/proc/perform()
	working = TRUE
	if(!valid() || (mode != "CLEAR" && !word))
		if(console?.session == src)
			console.cancel_procedure("The procedure was interrupted.")
		return
	var/completed = do_after(operator, console.procedure_time, subject)
	if(QDELETED(src))
		return
	if(!completed || !valid())
		console.cancel_procedure("The procedure was interrupted.")
		return
	if(!console.procedure_succeeds(operator))
		to_chat(operator, SPAN_DANGER("The procedure was FAILED."))
	else
		if(mode == "CLEAR")
			brain.os13_conditioned_triggers = null
			subject.clear_event("os13_conditioned_panic")
		else
			if(!brain.os13_conditioned_triggers)
				brain.os13_conditioned_triggers = list()
			brain.os13_conditioned_triggers[mode] = word
		brain.os13_conditioning_revision++
		to_chat(operator, SPAN_NOTICE("The procedure was performed successfully."))
		log_game("[key_name(operator)] completed [mode] conditioning on [key_name(subject)] at [get_area(console)].")
	console.session = null
	apparatus.update_use_power(POWER_USE_IDLE)
	qdel(src)

/datum/os13_psychocorrection_session/Destroy()
	if(console?.session == src)
		console.session = null
	console = null
	apparatus = null
	operator = null
	subject = null
	brain = null
	seat_turf = null
	return ..()
