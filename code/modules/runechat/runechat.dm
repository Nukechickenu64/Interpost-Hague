#define CHAT_MESSAGE_SPAWN_TIME		(0.2 SECONDS)
#define CHAT_MESSAGE_LIFESPAN		(5 SECONDS)
#define CHAT_MESSAGE_EXTRA_PER_CHAR	0.5
#define CHAT_MESSAGE_MAX_LIFESPAN	(12 SECONDS)
#define CHAT_MESSAGE_EOL_FADE		(1.5 SECONDS)
#define CHAT_MESSAGE_SUPERSEDED_FADE	(0.7 SECONDS)
#define CHAT_MESSAGE_DRIFT			8
#define CHAT_MESSAGE_EOL_DRIFT		4
#define CHAT_MESSAGE_EOL_BLUR		8
#define CHAT_MESSAGE_WIDTH			96
#define CHAT_MESSAGE_FONT_SIZE		6
#define CHAT_MESSAGE_MAX_LENGTH		110
#define CHAT_MESSAGE_APPROX_LHEIGHT	11
#define CHAT_MESSAGE_MAX_STACK		5

/client
	/// "\ref[speaker]" -> list of /datum/chatmessage currently shown to this client, oldest first
	var/list/seen_messages

/datum/chatmessage
	var/image/message
	var/atom/message_loc
	var/client/owned_by
	var/speaker_key
	var/approx_height = CHAT_MESSAGE_APPROX_LHEIGHT
	var/fading = FALSE

/datum/chatmessage/New(text, atom/target, mob/owner, flags = 0, color_override)
	..()
	if(!istype(target) || !owner || !owner.client)
		return
	INVOKE_ASYNC(src, .proc/generate_image, text, target, owner.client, flags, color_override)

/datum/chatmessage/Destroy()
	if(owned_by)
		owned_by.images -= message
		if(owned_by.seen_messages && speaker_key)
			var/list/bucket = owned_by.seen_messages[speaker_key]
			if(bucket)
				bucket -= src
				if(!bucket.len)
					owned_by.seen_messages -= speaker_key
	owned_by = null
	message_loc = null
	message = null
	return ..()

/datum/chatmessage/proc/generate_image(text, atom/target, client/C, flags, color_override)
	owned_by = C
	text = runechat_sanitize(text)
	if(!text)
		qdel(src)
		return

	var/text_color = color_override || runechat_color(target)
	var/body = text
	if(flags & (RUNECHAT_ITALIC|RUNECHAT_EMOTE|RUNECHAT_RADIO))
		body = "<i>[body]</i>"
	var/complete = "<span style=\"font-family:'Press Start 2P';font-size:[CHAT_MESSAGE_FONT_SIZE]px;color:[text_color];text-align:center;\">[body]</span>"

	// MeasureText sleeps until the client answers, so state may have changed afterwards
	var/measured = C.MeasureText(complete, null, CHAT_MESSAGE_WIDTH)
	if(QDELETED(src) || !owned_by || QDELETED(target))
		qdel(src)
		return
	var/x_pos = findtext(measured, "x")
	var/mheight = x_pos ? text2num(copytext(measured, x_pos + 1)) : CHAT_MESSAGE_APPROX_LHEIGHT
	approx_height = max(CHAT_MESSAGE_APPROX_LHEIGHT, mheight)

	message_loc = get_atom_on_turf(target)
	speaker_key = "\ref[message_loc]"

	LAZYINITLIST(owned_by.seen_messages)
	var/list/bucket = owned_by.seen_messages[speaker_key]
	if(!bucket)
		bucket = list()
		owned_by.seen_messages[speaker_key] = bucket
	for(var/datum/chatmessage/old as anything in bucket)
		// fade older bubbles out early; they keep their slow drift and never get shoved upward
		old.end_of_life(TRUE)
	bucket += src
	while(bucket.len > CHAT_MESSAGE_MAX_STACK)
		qdel(bucket[1])

	var/base_height = world.icon_size
	if(ismovable(message_loc))
		var/atom/movable/AM = message_loc
		base_height = AM.bound_height

	message = image(loc = message_loc, layer = RUNECHAT_LAYER)
	message.plane = RUNECHAT_PLANE
	message.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA | KEEP_APART | RESET_COLOR | RESET_TRANSFORM | RESET_ALPHA | PIXEL_SCALE
	message.alpha = 0
	message.pixel_y = base_height * 0.95
	message.maptext_width = CHAT_MESSAGE_WIDTH
	message.maptext_height = approx_height
	message.maptext_x = (world.icon_size - CHAT_MESSAGE_WIDTH) / 2
	message.maptext = complete
	message.filters = list(filter(type = "blur", size = 0), filter(type = "drop_shadow", x = 0, y = 0, size = 0, color = text_color))

	owned_by.images |= message
	var/lifespan = min(CHAT_MESSAGE_MAX_LIFESPAN, CHAT_MESSAGE_LIFESPAN + length(text) * CHAT_MESSAGE_EXTRA_PER_CHAR)
	animate(message, alpha = 255, time = CHAT_MESSAGE_SPAWN_TIME)
	// slow upward drift for the rest of the message's life
	animate(pixel_y = message.pixel_y + CHAT_MESSAGE_DRIFT, time = lifespan - CHAT_MESSAGE_SPAWN_TIME)

	addtimer(CALLBACK(src, .proc/end_of_life), lifespan)

/datum/chatmessage/proc/end_of_life(superseded = FALSE)
	if(QDELETED(src) || fading)
		return
	fading = TRUE
	var/fade_time = superseded ? CHAT_MESSAGE_SUPERSEDED_FADE : CHAT_MESSAGE_EOL_FADE
	if(message)
		// parallel+relative so an early fade never interrupts the ongoing drift animation
		animate(message, alpha = -255, pixel_y = CHAT_MESSAGE_EOL_DRIFT, time = fade_time, easing = QUAD_EASING | EASE_OUT, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE)
		animate(message.filters[1], size = CHAT_MESSAGE_EOL_BLUR, time = fade_time, easing = SINE_EASING | EASE_OUT)
		animate(message.filters[2], color = "#00000000", time = fade_time)
	QDEL_IN(src, fade_time)

/proc/runechat_sanitize(text)
	text = trim(html_decode(strip_html_properly(text)))
	if(!text)
		return
	if(length(text) > CHAT_MESSAGE_MAX_LENGTH)
		text = copytext(text, 1, CHAT_MESSAGE_MAX_LENGTH + 1) + "..."
	return html_encode(text)

/proc/runechat_color(atom/target)
	var/hue = hex2num(copytext(md5("[target.name]"), 1, 4)) % 360
	return rgb(hue, 55, 75, space = COLORSPACE_HSL)

/proc/runechat_to(mob/listener, atom/speaker, text, flags = 0, color_override)
	if(!listener || !listener.client || !speaker || !text)
		return
	if(flags & (RUNECHAT_EMOTE|RUNECHAT_RADIO))
		return
	if(listener.get_preference_value(/datum/client_preference/runechat) != GLOB.PREF_YES)
		return
	new /datum/chatmessage(text, speaker, listener, flags, color_override)

/// Removes the leading actor name from an emote so only the action floats above them.
/proc/runechat_emote_text(atom/user, text)
	text = html_decode(strip_html_properly(text))
	var/list/candidates = list("the [user.name]", "[user.name]")
	for(var/candidate in candidates)
		var/pos = findtext(text, candidate)
		if(pos)
			text = copytext(text, 1, pos) + copytext(text, pos + length(candidate))
			break
	return trim(text)

/atom/proc/runechat_to_hearers(text, flags = 0, visible_only = FALSE, range = world.view)
	if(!text)
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/list/mobs = list()
	var/list/objs = list()
	get_mobs_and_objs_in_view_fast(T, range, mobs, objs)
	for(var/mob/M as anything in mobs)
		if(!M.client || M.sleeping || M.stat == UNCONSCIOUS)
			continue
		if(visible_only)
			if(M.is_blind() || M.see_invisible < invisibility)
				continue
		else if(M.is_deaf())
			continue
		runechat_to(M, src, text, flags)
