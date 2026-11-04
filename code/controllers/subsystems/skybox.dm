// Shared skybox appearances and camera updates for the OS13 parallax layers.

#define RANDOM_RGB rgb(rand(0,255), rand(0,255), rand(0,255))

SUBSYSTEM_DEF(skybox)
	name = "Space skybox"
	init_order = SS_INIT_SKYBOX
	flags = SS_BACKGROUND
	wait = 1
	var/background_color
	var/skybox_icon = 'icons/turf/skybox.dmi' //Path to our background. Lets us use anything we damn well please. Skyboxes need to be 736x736
	var/background_icon = "space"
	var/use_stars = TRUE
	var/star_path = 'icons/turf/skybox.dmi'
	var/star_state = "stars"
	var/list/skybox_cache = list()
	var/list/space_appearance_cache
	var/list/os13_star_cache = list()
	var/list/currentrun = list()
	var/os13_space_appearance

/datum/controller/subsystem/skybox/PreInit()
	build_space_appearances()

/datum/controller/subsystem/skybox/proc/build_space_appearances()
	var/mutable_appearance/os13_space = new /mutable_appearance(/turf/space)
	os13_space.icon_state = "white"
	os13_space_appearance = os13_space.appearance
	space_appearance_cache = new(26)
	for (var/i in 0 to 25)
		var/mutable_appearance/dust = mutable_appearance('icons/turf/space_dust.dmi', "[i]")
		dust.plane = DUST_PLANE
		dust.alpha = 30
		dust.blend_mode = BLEND_ADD

		var/mutable_appearance/space = new /mutable_appearance(/turf/space)
		space.icon_state = "white"
		space.overlays += dust
		space_appearance_cache[i + 1] = space.appearance

/datum/controller/subsystem/skybox/Initialize(start_uptime)
	//background_color = RANDOM_RGB

/datum/controller/subsystem/skybox/Recover()
	background_color = SSskybox.background_color
	skybox_icon = SSskybox.skybox_icon
	background_icon = SSskybox.background_icon
	use_stars = SSskybox.use_stars
	star_path = SSskybox.star_path
	star_state = SSskybox.star_state
	skybox_cache = SSskybox.skybox_cache
	os13_star_cache = SSskybox.os13_star_cache

/datum/controller/subsystem/skybox/fire(resumed = FALSE)
	if(!istype(GLOB.using_map, /datum/map/alpha))
		return
	if(!resumed)
		currentrun = GLOB.clients.Copy()
	while(currentrun.len)
		var/client/C = currentrun[currentrun.len]
		currentrun.len--
		if(C)
			C.update_skybox()
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/skybox/proc/use_os13_parallax()
	return istype(GLOB.using_map, /datum/map/alpha) && background_icon == initial(background_icon) && skybox_icon == initial(skybox_icon)

/datum/controller/subsystem/skybox/proc/get_os13_stars(z, depth)
	var/cache_key = "[z]:[depth]"
	if(os13_star_cache[cache_key])
		return os13_star_cache[cache_key]
	var/list/star_icons = list('icons/os13/mob/mob/HUD/stars1.dmi', 'icons/os13/mob/mob/HUD/stars2.dmi', 'icons/os13/mob/mob/HUD/stars3.dmi')
	var/list/star_counts = list(11, 15, 20)
	var/image/field = image(null)
	for(var/i in 1 to star_counts[depth])
		var/hash = md5("os13-stars:[z]:[depth]:[i]")
		var/image/star = image(icon = star_icons[depth], icon_state = "[i]")
		star.pixel_x = hex2num(copytext(hash, 1, 5)) % 449
		star.pixel_y = hex2num(copytext(hash, 5, 9)) % 449
		field.overlays += star
	os13_star_cache[cache_key] = field
	return field

/datum/controller/subsystem/skybox/proc/get_skybox(z)
	if(!skybox_cache["[z]"])
		skybox_cache["[z]"] = generate_skybox(z)
	return skybox_cache["[z]"]

/datum/controller/subsystem/skybox/proc/generate_skybox(z)
	var/image/res = image(skybox_icon)

	var/image/base = overlay_image(skybox_icon, background_icon)

	if(use_stars)
		var/image/stars = overlay_image(skybox_icon, star_state, plane = STAR_PLANE, flags = RESET_COLOR)
		base.overlays += stars

	res.overlays += base

	return res
/datum/controller/subsystem/skybox/proc/rebuild_skyboxes(var/list/zlevels)
	for(var/z in zlevels)
		skybox_cache["[z]"] = generate_skybox(z)

	for(var/client/C)
		C.update_skybox(1)

//Update skyboxes. Called by universes, for now.
/datum/controller/subsystem/skybox/proc/change_skybox(new_state, new_color, new_use_stars, new_use_overmap_details)
	var/need_rebuild = FALSE
	if(new_state != background_icon)
		background_icon = new_state
		need_rebuild = TRUE

	if(new_color != background_color)
		background_color = new_color
		need_rebuild = TRUE

	if(new_use_stars != use_stars)
		use_stars = new_use_stars
		need_rebuild = TRUE

	if(need_rebuild)
		skybox_cache.Cut()

		for(var/client/C)
			C.update_skybox(1)