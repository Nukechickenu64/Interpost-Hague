/mob/living/carbon/human/proc/give_cryo_effect()
	var/message = ""
	if(prob(20)) //starvation
		message += "<span class='info'>It seems like you forgot to eat before getting 'buried' in the chamber...\n</span>"
		set_nutrition(rand(100,200))
		set_thirst(rand(100,200))
	if(prob(15)) //stutterting and jittering (because of cold?)
		message += "<span class='info'>This cold is making me jittery... </span>\n"
		make_jittery(120)
		stuttering = 20
	if(prob(15)) //vomit
		message += "<span class='info'>I want to vomit... </span>\n"
		vomit()
	if(!message)
		message += "<span class='notice'>It seems like there weren't any bad effects today...but I couldn't sleep properly anyway. </span>\n"
	else
		message += "<span class='info'>Can't even sleep or live properly here... </span>\n"
	to_chat(src, "[message]")
	return TRUE

/mob/living/carbon/human/proc/give_cryo_captain_effect()
	var/message = ""
	if(prob(20)) //starvation
		message += "<span class='info'>It seems like I forgot to eat before getting 'buried' in the chamber...[rand(20,60)] years of working as a Captain and still no brain. </span>"
		set_nutrition(rand(100,200))
		set_thirst(rand(100,200))
	if(prob(15)) //stutterting and jittering (because of cold?)
		message += "<span class='info'>This cold is making me jittery... </span>"
		make_jittery(120)
		stuttering = 20
	if(prob(15)) //vomit
		message += "<span class='info'>I want to vomit... </span>"
		vomit()
	if(!message)
		message += "<span class='notice'>It seems like there weren't any bad effects today...but I couldn't sleep properly anyway. </span>"
	else
		message += "<span class='info'>Can't even sleep or live properly here... </span>"
	to_chat(src, "[message]")
	return TRUE

GLOBAL_VAR_INIT(os13_cryo_sound_channel, GLOB.sound_channels.RequestChannel("OS13_CRYO_INTRO"))
var/global/const/OS13_CRYO_RELEASE_TIME = 9.6 SECONDS

/client
	var/datum/os13_cryo_intro/os13_cryo_intro

/obj/screen/plane_master/os13_cryo_hud
	plane = HUD_PLANE
	alpha = 0
	mouse_opacity = 0

/obj/screen/os13_cryo_intro
	plane = FULLSCREEN_PLANE
	mouse_opacity = 0

/obj/screen/os13_cryo_intro/darkness
	icon = 'icons/mob/screen1.dmi'
	icon_state = "black"
	screen_loc = ui_entire_screen
	layer = CRIT_LAYER + 1
	alpha = 247

/obj/screen/os13_cryo_intro/darkness/sidebar
	alpha = 255

/obj/screen/os13_cryo_intro/darkness/sidebar/left
	screen_loc = "WEST-3,SOUTH to WEST-1,NORTH"

/obj/screen/os13_cryo_intro/darkness/sidebar/right
	screen_loc = "EAST+1,SOUTH to EAST+1,NORTH"

/obj/screen/os13_cryo_intro/static_field
	// Tile the existing play area. An oversized icon expands the SIDE_MAP bounds
	// even when a transform scales its visible pixels down.
	icon_state = "noise"
	screen_loc = ui_entire_screen
	layer = CRIT_LAYER + 2
	color = "#294574"
	alpha = 118
	blend_mode = BLEND_ADD

/obj/screen/os13_cryo_intro/static_field/band
	screen_loc = "WEST,CENTER to EAST,CENTER"
	layer = CRIT_LAYER + 3
	color = "#416bb0"
	alpha = 130

/obj/screen/os13_cryo_intro/subtitle
	icon = null
	screen_loc = "CENTER,CENTER"
	layer = CRIT_LAYER + 4
	maptext_height = 48

/datum/os13_cryo_intro
	var/client/viewer
	var/mob/living/carbon/human/joiner
	var/obj/machinery/cryopod/pod
	var/obj/screen/os13_cryo_intro/darkness/darkness
	var/list/sidebars
	var/obj/screen/plane_master/os13_cryo_hud/hud_mask
	var/obj/screen/os13_cryo_intro/static_field/noise
	var/obj/screen/os13_cryo_intro/static_field/band/band
	var/obj/screen/os13_cryo_intro/subtitle/subtitle
	var/list/displayed_captions
	var/list/identity_labels

/datum/os13_cryo_intro/New(mob/living/carbon/human/crew, obj/machinery/cryopod/chamber)
	..()
	joiner = crew
	viewer = crew.client
	pod = chamber
	QDEL_NULL(viewer.os13_cryo_intro)
	viewer.os13_cryo_intro = src

/datum/os13_cryo_intro/proc/can_start()
	return !QDELETED(src) && !QDELETED(pod) && !QDELETED(joiner) && viewer?.os13_cryo_intro == src && viewer.mob == joiner && joiner.loc == pod && pod.occupant == joiner && !pod.releasing

/datum/os13_cryo_intro/proc/wait_for_viewport()
	// Wait for the visible map to hold its size for a full second.
	var/last_visible_size
	while(can_start())
		var/list/viewport = params2list(winget(viewer, "mapwindow.map", "is-visible;size"))
		if(!can_start())
			break
		var/viewport_size = viewport["size"]
		var/list/dimensions = splittext(viewport_size, "x")
		var/visible = viewport["is-visible"] == "true" && length(dimensions) == 2 && text2num(dimensions[1]) > 0 && text2num(dimensions[2]) > 0
		if(visible)
			var/list/window_state = params2list(winget(viewer, "mainwindow", "is-visible;is-minimized"))
			if(!can_start())
				break
			visible = window_state["is-visible"] == "true" && window_state["is-minimized"] == "false"
		if(visible && viewport_size == last_visible_size)
			pod.start_joiner_intro(src)
			return
		last_visible_size = visible ? viewport_size : null
		sleep(1 SECOND)
	if(!QDELETED(src))
		qdel(src)

/datum/os13_cryo_intro/proc/play()
	darkness = new
	hud_mask = new
	sidebars = list(new /obj/screen/os13_cryo_intro/darkness/sidebar/left, new /obj/screen/os13_cryo_intro/darkness/sidebar/right)
	noise = new
	band = new
	subtitle = new
	displayed_captions = list()
	subtitle.filters = filter(type = "drop_shadow", x = 0, y = 0, size = 3, color = "#90baff")
	viewer.screen += list(darkness, hud_mask)
	viewer.screen += sidebars

	// The first two transmissions come through in darkness. The cryobay resolves under the third.
	animate(darkness, alpha = 247, time = 2.7 SECONDS)
	animate(alpha = 75, time = 0.9 SECONDS, easing = SINE_EASING)
	animate(alpha = 32, time = 1.1 SECONDS, easing = SINE_EASING)
	sound_to(viewer, sound(null, channel = GLOB.cryo_startup_effect.alarm_channel))
	if(!joiner.ear_deaf && !(joiner.sdisabilities & DEAF))
		sound_to(viewer, sound('sound/ambience/os13_cryo_intro.ogg', wait = FALSE, channel = GLOB.os13_cryo_sound_channel))

	if(viewer.get_preference_value(/datum/client_preference/os13_cryo_flashes) == GLOB.PREF_NO)
		return

	var/static/icon/static_tile
	if(!static_tile)
		static_tile = icon('icons/os13/effects/effects/camera_noise.dmi')
		static_tile.Crop(1, 1, world.icon_size, world.icon_size)
	noise.icon = static_tile
	band.icon = static_tile

	// Reveal fragments in audio order and retain them so there's time to read. The final fragment repeats as reception drops.
	var/static/list/default_transmission = list(
		list(1.1 SECONDS, 2.1 SECONDS, "... wish there was some other way ..."),
		list(2.1 SECONDS, 3.1 SECONDS, "... the traitor under whose control I ..."),
		list(3.1 SECONDS, 4.5 SECONDS, "... I was implanted with a microchip, I was like a zombie ..."),
		list(4.5 SECONDS, 5.6 SECONDS, "... protected our databanks to ..."),
		list(5.6 SECONDS, 6.8 SECONDS, "... to take the Charon and land near Base-7 ..."),
		list(6.8 SECONDS, 8.2 SECONDS, "... I admit the sabotage that is my fault, but the real enemy is still onboard ..."),
		list(8.2 SECONDS, OS13_CRYO_RELEASE_TIME, "... I'll be waiting for you ...")
	)
	var/list/transmission = config.os13_cryo_captions || default_transmission
	for(var/list/cue as anything in transmission)
		addtimer(CALLBACK(src, .proc/show_signal, cue[3]), cue[1], TIMER_CLIENT_TIME)
		addtimer(CALLBACK(src, .proc/hide_static_signal), cue[2], TIMER_CLIENT_TIME)

/datum/os13_cryo_intro/proc/show_signal(line)
	if(viewer?.mob != joiner || joiner.loc != pod || pod?.occupant != joiner)
		// Deleting this datum cancels its remaining client timers. Defer that
		// until after the timer subsystem has finished walking their queue.
		QDEL_IN(src, 0)
		return
	var/list/dimensions = getviewsize(viewer.view)
	var/width = dimensions[1] * world.icon_size
	var/font_size = clamp(round(width / 34), 8, 17)
	var/speaker = config.os13_cryo_speaker
	var/two_lines = length(speaker) + length(line) > 76
	displayed_captions += line
	band.screen_loc = length(displayed_captions) > 1 ? "WEST,CENTER-3 to EAST,CENTER+3" : (two_lines ? "WEST,CENTER-1:16 to EAST,CENTER:16" : initial(band.screen_loc))
	subtitle.maptext_width = min(width - 16, 580)
	subtitle.maptext_x = round((world.icon_size - subtitle.maptext_width) / 2)
	subtitle.maptext_height = min(240, max(48, 32 * length(displayed_captions)))
	subtitle.maptext_y = -round(subtitle.maptext_height / 2)
	var/list/caption_markup = list()
	for(var/caption as anything in displayed_captions)
		caption_markup += "<span style='font-family:Arial;font-size:[font_size]px;color:#f0efff'><b>[html_encode(speaker)]:</b> <i>&quot;[html_encode(caption)]&quot;</i></span>"
	var/caption_text = jointext(caption_markup, "<br>")
	subtitle.maptext = "<center>[caption_text]</center>"
	viewer.screen |= list(noise, band, subtitle)
	animate(noise, alpha = 145, time = 1, loop = -1)
	animate(alpha = 104, time = 1)
	animate(alpha = 123, time = 1)

/datum/os13_cryo_intro/proc/hide_static_signal()
	viewer.screen -= list(noise, band)

/datum/os13_cryo_intro/proc/hide_signal()
	viewer.screen -= list(noise, band, subtitle)

/datum/os13_cryo_intro/proc/wake()
	pod = null
	hide_signal()
	animate(darkness, alpha = 0, time = 0.6 SECONDS)
	animate(hud_mask, alpha = 255, time = 0.6 SECONDS)
	for(var/obj/screen/sidebar as anything in sidebars)
		animate(sidebar, alpha = 0, time = 0.6 SECONDS)
	addtimer(CALLBACK(src, .proc/show_identity), 1.2 SECONDS, TIMER_CLIENT_TIME)
	QDEL_IN(src, 3.8 SECONDS)

/datum/os13_cryo_intro/proc/show_identity()
	if(viewer.mob != joiner)
		QDEL_IN(src, 0)
		return
	var/occupation = joiner.job || joiner.mind?.assigned_role
	identity_labels = list(
		identity_label("<b>[html_encode(joiner.real_name)]</b>", 30),
		identity_label(html_encode(occupation), -18)
	)
	viewer.images += identity_labels
	for(var/image/label as anything in identity_labels)
		animate(label, alpha = 255, time = 0.15 SECONDS)
		animate(alpha = 255, time = 1.25 SECONDS)
		animate(alpha = 0, time = 0.9 SECONDS)

/datum/os13_cryo_intro/proc/identity_label(text, offset)
	var/image/label = image(loc = joiner, layer = RUNECHAT_LAYER)
	label.plane = RUNECHAT_PLANE
	label.appearance_flags = KEEP_APART | RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM
	label.mouse_opacity = 0
	label.alpha = 0
	label.maptext_width = 240
	label.maptext_height = 20
	label.maptext_x = (world.icon_size - label.maptext_width) / 2
	label.maptext_y = offset
	label.maptext = "<center><span style='font-family:Arial;font-size:12px;color:#f0efff'>[text]</span></center>"
	label.filters = filter(type = "drop_shadow", x = 0, y = 0, size = 2, color = "#7385af")
	return label

/datum/os13_cryo_intro/Destroy()
	if(viewer)
		if(viewer.os13_cryo_intro == src)
			viewer.os13_cryo_intro = null
		if(pod && viewer.mob == joiner && viewer.eye == pod && (joiner.loc != pod || QDELETED(pod)))
			viewer.eye = joiner
			viewer.perspective = MOB_PERSPECTIVE
		viewer.screen -= list(darkness, hud_mask, noise, band, subtitle)
		viewer.screen -= sidebars
		if(identity_labels)
			viewer.images -= identity_labels
		sound_to(viewer, sound(null, channel = GLOB.os13_cryo_sound_channel))
	QDEL_NULL(darkness)
	QDEL_NULL(hud_mask)
	QDEL_NULL(noise)
	QDEL_NULL(band)
	QDEL_NULL(subtitle)
	displayed_captions = null
	for(var/obj/screen/sidebar as anything in sidebars)
		qdel(sidebar)
	sidebars = null
	identity_labels = null
	viewer = null
	joiner = null
	pod = null
	return ..()
