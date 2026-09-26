#define CHAT_MESSAGE_SPAWN_TIME		(0.2 SECONDS)
#define CHAT_MESSAGE_LIFESPAN		(5 SECONDS)
#define CHAT_MESSAGE_EXTRA_PER_CHAR	0.5
#define CHAT_MESSAGE_MAX_LIFESPAN	(12 SECONDS)
#define CHAT_MESSAGE_EOL_FADE		(0.7 SECONDS)
#define CHAT_MESSAGE_WIDTH			96
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

	var/font_size = (flags & RUNECHAT_SMALL) ? 6 : 7
	var/text_color = color_override || runechat_color(target)
	var/body = text
	if(flags & (RUNECHAT_ITALIC|RUNECHAT_EMOTE|RUNECHAT_RADIO))
		body = "<i>[body]</i>"
	var/complete = "<span style=\"font-family:'Small Fonts';font-size:[font_size]px;-dm-text-outline:1px #000000;color:[text_color];text-align:center;\">[body]</span>"

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
		if(old.message)
			animate(old.message, pixel_y = old.message.pixel_y + approx_height, time = CHAT_MESSAGE_SPAWN_TIME)
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

	owned_by.images |= message
	animate(message, alpha = 255, time = CHAT_MESSAGE_SPAWN_TIME)

	var/lifespan = min(CHAT_MESSAGE_MAX_LIFESPAN, CHAT_MESSAGE_LIFESPAN + length(text) * CHAT_MESSAGE_EXTRA_PER_CHAR)
	addtimer(CALLBACK(src, .proc/end_of_life), lifespan)

/datum/chatmessage/proc/end_of_life()
	if(QDELETED(src))
		return
	if(message)
		animate(message, alpha = 0, time = CHAT_MESSAGE_EOL_FADE)
	QDEL_IN(src, CHAT_MESSAGE_EOL_FADE)

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
