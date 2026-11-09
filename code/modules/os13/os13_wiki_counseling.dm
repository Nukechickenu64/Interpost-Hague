/mob/living/carbon/human
	var/os13_counselor = FALSE
	var/list/os13_borrowed_skills = list()
	var/os13_next_clone_offer = 0

/mob/living
	var/os13_recent_phrase
	var/os13_recent_phrase_time = 0

/mob/living/carbon/human/proc/os13_training_link(mob/living/carbon/human/other)
	return os13_counselor && !incapacitated() && !QDELETED(other) && other != src && !other.incapacitated() && !isSynthetic() && !other.isSynthetic() && has_brain() && other.has_brain() && (other in view(1, src))

/mob/living/carbon/human/proc/telepathic_training()
	set name = "Telepathic Training"
	set category = "Psionics"

	if(!os13_counselor || incapacitated())
		to_chat(src, SPAN_WARNING("You cannot establish a telepathic link."))
		return
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(1, src))
		if(os13_training_link(H))
			candidates += H
	if(!candidates.len)
		to_chat(src, SPAN_WARNING("There is nobody close enough to train with."))
		return
	var/mob/living/carbon/human/other = input(src, "Whose mind do you want to link with?", "Telepathic Training") as null|anything in candidates
	if(!other)
		return
	var/direction = input(src, "Learn from this person or teach them?", "Telepathic Training") as null|anything in list("Learn", "Teach")
	if(!direction)
		return
	if(!os13_training_link(other))
		to_chat(src, SPAN_WARNING("The telepathic link was broken."))
		return
	var/mob/living/carbon/human/teacher = direction == "Learn" ? other : src
	var/mob/living/carbon/human/student = direction == "Learn" ? src : other
	var/list/available = list()
	for(var/skill in teacher.skills)
		if(teacher.skills[skill] > student.skills[skill] || (student.os13_borrowed_skills[skill] && teacher.skills[skill] == student.skills[skill]))
			available += skill
	if(!available.len)
		to_chat(src, SPAN_NOTICE("There is no new skill to transfer."))
		return
	var/skill = input(src, "Which skill do you want to transfer?", "Telepathic Training") as null|anything in available
	if(!skill)
		return
	if(!os13_training_link(other))
		to_chat(src, SPAN_WARNING("The telepathic link was broken."))
		return
	if(!(skill in teacher.skills) || !(skill in student.skills))
		to_chat(src, SPAN_WARNING("That knowledge is no longer available to transfer."))
		return
	if(teacher.skills[skill] < student.skills[skill] || (teacher.skills[skill] == student.skills[skill] && !student.os13_borrowed_skills[skill]))
		to_chat(src, SPAN_NOTICE("That knowledge is already familiar."))
		return
	student.borrow_os13_skill(skill, teacher.skills[skill])
	to_chat(teacher, SPAN_NOTICE("Your knowledge of [skill] passes into [student]'s mind."))
	to_chat(student, SPAN_NOTICE("You instantly learn [skill] from [teacher]. This borrowed knowledge will fade in three hours."))

/mob/living/carbon/human/proc/borrow_os13_skill(skill, level)
	var/list/previous = os13_borrowed_skills[skill]
	var/permanent_level = skills[skill] - (previous ? previous["amount"] : 0)
	var/amount = max(skills[skill], level) - permanent_level
	if(amount <= 0)
		return
	var/expires = world.time + 3 HOURS
	skills[skill] = permanent_level + amount
	os13_borrowed_skills[skill] = list("amount" = amount, "expires" = expires)
	addtimer(CALLBACK(src, /mob/living/carbon/human/proc/forget_os13_skill, skill, expires), 3 HOURS)

/mob/living/carbon/human/proc/forget_os13_skill(skill, expires)
	var/list/loan = os13_borrowed_skills[skill]
	if(!loan || loan["expires"] != expires)
		return
	// Remove only the borrowed contribution, retaining subsequent learning.
	skills[skill] = max(0, skills[skill] - loan["amount"])
	os13_borrowed_skills -= skill
	to_chat(src, SPAN_NOTICE("The borrowed knowledge of [skill] fades from your memory."))

/mob/living/carbon/human/proc/os13_psychometry(obj/object)
	if(!os13_counselor || incapacitated() || !combat_mode || is_blind(src) || QDELETED(object) || !(object in view(1, src)))
		return
	if(object.psychometric_touch_name)
		to_chat(src, SPAN_NOTICE("You sense the lingering touch of [html_encode(object.psychometric_touch_name)] on [object]."))
	else
		to_chat(src, SPAN_NOTICE("You cannot sense a recent touch on [object]."))

/mob/living/carbon/human/proc/os13_read_emotions(mob/living/carbon/human/other)
	if(!os13_counselor || incapacitated() || is_blind(src) || QDELETED(other) || other == src || other.stat == DEAD || other.isSynthetic() || !(other in view(5, src)))
		return
	var/emotion = other.happiness > MOOD_LEVEL_HAPPY1 ? "contentment" : other.happiness < MOOD_LEVEL_SAD1 ? "distress" : "a calm mind"
	to_chat(src, SPAN_NOTICE("You feel [emotion] from [other]."))
	if(other.os13_recent_phrase && world.time < other.os13_recent_phrase_time + 10 MINUTES)
		to_chat(src, SPAN_NOTICE("An echo of [other]'s recent words reaches you: \"[html_encode(rhtml_decode(other.os13_recent_phrase))]\""))

/obj/item/clothing/ears/earmuffs/os13_healing
	name = "Healing Headphones"
	desc = "Therapeutic headphones for posthibernational psychosis. Wear them continuously for one minute to complete treatment."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "headphones"
	item_state = "earmuffs"
	item_icons = list(
		slot_l_ear_str = 'icons/os13/mob/mob/clothing/secondary/ears.dmi',
		slot_r_ear_str = 'icons/os13/mob/mob/clothing/secondary/ears.dmi'
	)
	var/treatment_started = 0

/obj/item/clothing/ears/earmuffs/os13_healing/equipped(mob/user, slot)
	. = ..()
	treatment_started = 0
	if(slot == slot_l_ear || slot == slot_r_ear)
		START_PROCESSING(SSobj, src)
	return .

/obj/item/clothing/ears/earmuffs/os13_healing/dropped(mob/user)
	STOP_PROCESSING(SSobj, src)
	treatment_started = 0
	return ..()

/obj/item/clothing/ears/earmuffs/os13_healing/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/clothing/ears/earmuffs/os13_healing/Process()
	var/mob/living/carbon/human/H = loc
	if(!istype(H) || H.stat == DEAD || !(H.l_ear == src || H.r_ear == src))
		treatment_started = 0
		STOP_PROCESSING(SSobj, src)
		return
	if(!H.posthib_psychosis)
		treatment_started = 0
		return
	if(!treatment_started)
		treatment_started = world.time
		to_chat(H, SPAN_NOTICE("The headphones begin a calming therapeutic sequence."))
	if(world.time >= treatment_started + 1 MINUTE)
		H.cure_posthib_psychosis(treatment = TRUE)
		treatment_started = 0

/datum/design/item/os13_healing_headphones
	name = "Healing Headphones"
	id = "os13_healing_headphones"
	req_tech = list(TECH_BIO = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500)
	build_path = /obj/item/clothing/ears/earmuffs/os13_healing
	sort_string = "VAACC"

/mob/living/carbon/human/proc/os13_offer_clone()
	if(!wraith_effects_allowed())
		return
	if(!istype(GLOB.using_map, /datum/map/alpha) || !clone_claimable || key || mind || stat == DEAD || !isturf(loc) || world.time < os13_next_clone_offer)
		return
	os13_clone_awakened = TRUE
	os13_next_clone_offer = world.time + 1 MINUTE
	var/offers = 0
	for(var/mob/observer/ghost/G in GLOB.player_list)
		if(!G.client || !G.MayRespawn(1))
			continue
		to_chat(G, SPAN_NOTICE("A neural shock calls you to a fresh clone. [ghost_follow_link(src, G)] Double-click the clone to inhabit it."))
		offers++
	visible_message(SPAN_NOTICE("[src]'s body twitches as it is offered to the wraiths."))
	if(!offers)
		visible_message(SPAN_NOTICE("No wraith answers the call. Try again later."))

/obj/item/organ/internal/os13_neural_port
	name = "Schriebmann Port"
	desc = "A surgical neural interface for operating a cyberdeck."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "neuroimplant"
	parent_organ = BP_HEAD
	organ_tag = "os13_neural_port"
	robotic = ORGAN_ROBOT
	relative_size = 10

/mob/living/carbon/human/proc/has_os13_neural_port()
	var/obj/item/organ/internal/os13_neural_port/port = internal_organs_by_name["os13_neural_port"]
	return istype(port) && port.owner == src && port.is_usable()

/datum/design/item/os13_neural_port
	name = "Schriebmann Port"
	id = "os13_neural_port"
	req_tech = list(TECH_DATA = 1, TECH_BIO = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500)
	build_path = /obj/item/organ/internal/os13_neural_port
	sort_string = "VAACD"

/obj/item/organ/internal/os13_neural_port/advanced
	name = "Advanced Schriebmann's Port"
	desc = "An advanced surgical neural interface for operating a cyberdeck."
	item_state = "implantcase"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/datum/design/item/os13_advanced_neural_port
	name = "Advanced Schriebmann's Port"
	id = "os13_advanced_neural_port"
	req_tech = list(TECH_DATA = 3, TECH_BIO = 3)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 1000)
	build_path = /obj/item/organ/internal/os13_neural_port/advanced
	sort_string = "VAACDA"

/obj/item/organ/internal/os13_psiboost
	name = "PsiBoost Implant"
	desc = "An implanted neural amplifier providing remote vision, thought transmission, and three psionic powers."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "neuroimplant"
	parent_organ = BP_HEAD
	organ_tag = "os13_psiboost"
	robotic = ORGAN_ROBOT
	relative_size = 10
	var/mob/living/carbon/human/view_target
	var/client/view_client
	var/view_until = 0
	var/next_transmission = 0

/obj/item/organ/internal/os13_psiboost/New(mob/living/carbon/holder)
	..()
	if(owner)
		grant_controls()

/obj/item/organ/internal/os13_psiboost/proc/grant_controls()
	owner.verbs |= /mob/living/carbon/human/proc/os13_remote_vision
	owner.verbs |= /mob/living/carbon/human/proc/os13_transmit_thought
	if(istype(GLOB.using_map, /datum/map/os13classic))
		owner.verbs |= /mob/living/carbon/human/proc/os13_use_psiboost

/obj/item/organ/internal/os13_psiboost/replaced(mob/living/carbon/human/target, obj/item/organ/external/affected)
	. = ..()
	if(.)
		grant_controls()

/obj/item/organ/internal/os13_psiboost/removed(mob/living/user, drop_organ = 1, detach = 1)
	remove_controls()
	return ..()

/obj/item/organ/internal/os13_psiboost/Destroy()
	remove_controls()
	return ..()

/obj/item/organ/internal/os13_psiboost/die()
	stop_viewing()
	if(owner)
		owner.os13_psi_armor_until = 0
	return ..()

/obj/item/organ/internal/os13_psiboost/proc/remove_controls()
	stop_viewing()
	if(owner)
		owner.verbs -= /mob/living/carbon/human/proc/os13_remote_vision
		owner.verbs -= /mob/living/carbon/human/proc/os13_transmit_thought
		owner.verbs -= /mob/living/carbon/human/proc/os13_use_psiboost
		owner.os13_psi_armor_until = 0
		if(owner.os13_psi_control?.caster == owner)
			owner.os13_psi_control.finish()

/obj/item/organ/internal/os13_psiboost/proc/can_operate()
	return owner && !owner.os13_psi_control && owner.internal_organs_by_name[organ_tag] == src && is_usable() && !owner.incapacitated() && owner.has_brain() && !owner.isSynthetic()

/obj/item/organ/internal/os13_psiboost/proc/valid_target(mob/living/carbon/human/target)
	if(!can_operate() || QDELETED(target) || !target.client || target == owner || target.stat != CONSCIOUS || !target.has_brain() || target.isSynthetic())
		return FALSE
	var/turf/source_turf = get_turf(owner)
	var/turf/target_turf = get_turf(target)
	return source_turf && target_turf && source_turf.z == target_turf.z

/obj/item/organ/internal/os13_psiboost/proc/targets()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/target in GLOB.player_list)
		if(target.client && valid_target(target))
			candidates += target
	return candidates

/obj/item/organ/internal/os13_psiboost/proc/viewing()
	return view_target && view_client && owner && view_client == owner.client && view_client.mob == owner && view_client.eye == view_target && !owner.machine && !owner.eyeobj && !owner.z_eye && !is_blind(owner) && world.time < view_until && valid_target(view_target)

/obj/item/organ/internal/os13_psiboost/proc/stop_viewing()
	STOP_PROCESSING(SSobj, src)
	if(view_client && owner && view_client.mob == owner && view_client.eye == view_target)
		owner.reset_view(null)
	view_target = null
	view_client = null
	view_until = 0

/obj/item/organ/internal/os13_psiboost/Process()
	. = ..()
	if(!viewing())
		if(owner && view_target)
			to_chat(owner, SPAN_NOTICE("Your remote vision ends."))
		stop_viewing()

/mob/living/carbon/human/proc/os13_psiboost()
	var/obj/item/organ/internal/os13_psiboost/implant = internal_organs_by_name["os13_psiboost"]
	if(istype(implant) && implant.owner == src && implant.can_operate())
		return implant

/mob/living/carbon/human/proc/os13_remote_vision()
	set name = "Remote Vision"
	set category = "Psionics"
	var/obj/item/organ/internal/os13_psiboost/implant = os13_psiboost()
	var/client/operator_client = client
	if(!implant || !client)
		to_chat(src, SPAN_WARNING("Your psionic amplifier is unavailable."))
		return
	if(implant.view_target)
		implant.stop_viewing()
		to_chat(src, SPAN_NOTICE("You return your sight to your own body."))
		return
	if(machine || eyeobj || z_eye || client.eye != src || is_blind(src))
		to_chat(src, SPAN_WARNING("Return to your own unobstructed view before projecting your sight."))
		return
	var/list/candidates = implant.targets()
	if(!candidates.len)
		to_chat(src, SPAN_WARNING("There are no conscious minds you can reach on this deck."))
		return
	var/mob/living/carbon/human/target = input(src, "Whose location do you want to observe?", "Remote Vision") as null|anything in candidates
	if(!target)
		return
	if(QDELETED(implant) || implant != os13_psiboost() || !implant.valid_target(target) || !client || client != operator_client || machine || eyeobj || z_eye || client.eye != src || is_blind(src))
		to_chat(src, SPAN_WARNING("The remote vision link could not be established."))
		return
	implant.view_target = target
	implant.view_client = client
	implant.view_until = world.time + 30 SECONDS
	reset_view(target)
	START_PROCESSING(SSobj, implant)
	to_chat(src, SPAN_NOTICE("You project your sight to [target]. Use Remote Vision again to return. Your body remains where you left it."))

/mob/living/carbon/human/proc/os13_transmit_thought()
	set name = "Thought Transmission"
	set category = "Psionics"
	var/obj/item/organ/internal/os13_psiboost/implant = os13_psiboost()
	var/client/operator_client = client
	if(!implant || !client)
		to_chat(src, SPAN_WARNING("Your psionic amplifier is unavailable."))
		return
	if(world.time < implant.next_transmission)
		to_chat(src, SPAN_WARNING("Wait for your last thought to settle."))
		return
	var/list/candidates = implant.targets()
	if(!candidates.len)
		to_chat(src, SPAN_WARNING("There are no conscious minds you can reach on this deck."))
		return
	var/mob/living/carbon/human/target = input(src, "Whose mind do you want to reach?", "Thought Transmission") as null|anything in candidates
	if(!target)
		return
	var/message = sanitize(input(src, "What thought do you want to transmit?", "Thought Transmission") as null|text, MAX_MESSAGE_LEN)
	if(!message)
		return
	if(QDELETED(implant) || implant != os13_psiboost() || !implant.valid_target(target) || !client || client != operator_client || world.time < implant.next_transmission)
		to_chat(src, SPAN_WARNING("The thought transmission link was interrupted."))
		return
	implant.next_transmission = world.time + 2 SECONDS
	to_chat(target, SPAN_NOTICE("A thought from [html_encode(real_name)] reaches your mind: \"[message]\""))
	to_chat(src, SPAN_NOTICE("You transmit to [html_encode(target.real_name)]: \"[message]\""))
	log_say("[key_name(src)] sent an OS13 telepathic message to [key_name(target)]: [message]")

/datum/design/item/os13_psiboost
	name = "PsiBoost Implant"
	id = "os13_psiboost_implant"
	req_tech = list(TECH_DATA = 3, TECH_BIO = 3)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500)
	build_path = /obj/item/organ/internal/os13_psiboost
	sort_string = "VAACF"
