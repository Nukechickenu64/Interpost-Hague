/mob/observer/ghost/say(var/message)
	if(pain_possession_object && pain_possession_object.has_possession_mouth())
		if(world.time < next_pain_speech)
			return
		message = sanitize(message)
		if(!message)
			return
		next_pain_speech = world.time + 10
		pain_possession_object.audible_message("<span class='game say'><b>\The [rhtml_encode(pain_possession_object.name)]</b> says, \"[message]\"</span>")
		return
	sanitize_and_communicate(/decl/communication_channel/dsay, client, message)

/obj/var/mob/observer/ghost/pain_possessor

/obj/proc/has_possession_mouth()
	return FALSE

/obj/item/clothing/mask/has_possession_mouth()
	return TRUE

/obj/item/toy/figure/has_possession_mouth()
	return TRUE

/obj/item/toy/plushie/has_possession_mouth()
	return TRUE

/obj/structure/plushie/has_possession_mouth()
	return TRUE
