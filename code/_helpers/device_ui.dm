// Physical screens share one shell across NanoUI, TGUI and legacy browsers.
// UI datums resolve their physical host explicitly; unrelated menus never opt in.
/atom/proc/has_device_screen()
	return FALSE

/obj/machinery/has_device_screen()
	return TRUE

/obj/item/device/has_device_screen()
	return TRUE

/obj/item/modular_computer/has_device_screen()
	return TRUE

/obj/item/assembly/has_device_screen()
	return TRUE

/obj/mecha/has_device_screen()
	return TRUE

/obj/item/integrated_circuit/has_device_screen()
	return TRUE

/obj/item/anodevice/has_device_screen()
	return TRUE

/obj/item/weapon/gun/energy/temperature/has_device_screen()
	return TRUE

/obj/item/storage/secure/has_device_screen()
	return TRUE

/obj/item/weapon/gun/projectile/dartgun/has_device_screen()
	return TRUE

/obj/item/locator/has_device_screen()
	return TRUE

/obj/item/pinpointer/has_device_screen()
	return TRUE

/obj/item/implant/has_device_screen()
	return TRUE

/obj/item/mecha_parts/mecha_equipment/has_device_screen()
	return TRUE

/obj/structure/lift/panel/has_device_screen()
	return TRUE

/obj/structure/vehicleparts/weapon/has_device_screen()
	return TRUE

/mob/living/bot/has_device_screen()
	return TRUE

// Instruments use composition menus rather than a physical display.
/obj/item/device/violin/has_device_screen()
	return FALSE

/proc/device_ui_host(var/datum/source)
	if(!source)
		return
	var/atom/host = source.nano_host()
	if(istype(host) && host.has_device_screen())
		return host
	return null

// Cached per appearance, not per window or update. Screen overlays on older
// computers are sampled separately; complete sprites use their powered/off pair.
/proc/device_ui_profile(var/atom/host)
	var/static/list/profiles = list()
	var/screen_state
	if(istype(host, /obj/machinery/computer) && !findtext(host.icon_state, "os13_"))
		var/obj/machinery/computer/computer = host
		screen_state = computer.icon_screen
	if(istype(host, /obj/item/modular_computer) && !findtext(host.icon_state, "os13_"))
		var/obj/item/modular_computer/computer = host
		screen_state = computer.active_program ? computer.active_program.program_icon_state : computer.icon_state_menu
	var/key = "[host.icon]|[host.icon_state]|[host.dir]|[screen_state]"
	if(profiles[key])
		return profiles[key]
	var/icon/sprite = icon(host.icon, host.icon_state, host.dir, 1)
	var/icon/display = screen_state ? icon(host.icon, screen_state, host.dir, 1) : sprite
	var/icon/unpowered
	if(host.icon && ("[host.icon_state]_off" in icon_states(host.icon)))
		unpowered = icon(host.icon, "[host.icon_state]_off", host.dir, 1)
	// These sprites illuminate their keyboard/casing too. Isolate the actual LCD.
	var/list/screen_rect
	if(host.icon == 'icons/obj/modular_laptop.dmi' && findtext(host.icon_state, "os13_"))
		screen_rect = list(10, 17, 23, 24)
	if(host.icon == 'icons/obj/monitorsos13.dmi' && findtext(host.icon_state, "ealarm") && host.dir == SOUTH)
		screen_rect = list(11, 21, 16, 26)
	var/list/casing_colors = list()
	var/list/screen_colors = list()
	var/min_x = 1000
	var/min_y = 1000
	var/max_x = 0
	var/max_y = 0
	for(var/x = 1, x <= min(sprite.Width(), 96), x++)
		for(var/y = 1, y <= min(sprite.Height(), 96), y++)
			var/pixel = sprite.GetPixel(x, y)
			var/list/channels = ReadRGB(pixel)
			if(!channels || (channels.len >= 4 && channels[4] < 128))
				continue
			var/bright = max(channels[1], channels[2], channels[3])
			var/chroma = bright - min(channels[1], channels[2], channels[3])
			var/casing_candidate = bright > 35 && bright < 225 && chroma < 65
			var/casing_pixel = rgb(channels[1], channels[2], channels[3])
			var/screen_pixel = display.GetPixel(x, y)
			channels = ReadRGB(screen_pixel)
			if(!channels || (channels.len >= 4 && channels[4] < 128))
				if(casing_candidate)
					casing_colors[casing_pixel] += 1
				continue
			bright = max(channels[1], channels[2], channels[3])
			chroma = bright - min(channels[1], channels[2], channels[3])
			var/is_screen = screen_state || (unpowered && screen_pixel != unpowered.GetPixel(x, y))
			if(!screen_state && !unpowered)
				is_screen = chroma > 20 && bright > 65 && y > sprite.Height() / 3
			if(screen_rect)
				is_screen = x >= screen_rect[1] && x <= screen_rect[3] && y >= screen_rect[2] && y <= screen_rect[4]
			if(casing_candidate && !is_screen)
				casing_colors[casing_pixel] += 1
			if(is_screen && bright > 30)
				screen_colors[rgb(channels[1], channels[2], channels[3])] += 1
				min_x = min(min_x, x)
				max_x = max(max_x, x)
				min_y = min(min_y, y)
				max_y = max(max_y, y)
	var/casing = "#575950"
	var/screen = "#497b79"
	var/highest = 0
	for(var/pixel in casing_colors)
		if(casing_colors[pixel] > highest)
			highest = casing_colors[pixel]
			casing = pixel
	highest = 0
	for(var/pixel in screen_colors)
		var/list/channels = ReadRGB(pixel)
		var/chroma = max(channels[1], channels[2], channels[3]) - min(channels[1], channels[2], channels[3])
		var/weight = screen_colors[pixel] * max(1, chroma)
		if(weight > highest)
			highest = weight
			screen = pixel
	var/handheld = istype(host, /obj/item) && !istype(host, /obj/item/modular_computer/console) && !istype(host, /obj/item/modular_computer/telescreen) && !istype(host, /obj/item/modular_computer/laptop)
	var/ratio = handheld ? 0.85 : 1.4
	if(max_x - min_x >= 3 && max_y - min_y >= 3)
		ratio = clamp((max_x - min_x + 1) / (max_y - min_y + 1), 0.65, 2)
	var/list/profile = list("casing" = casing, "rim" = BlendRGB(casing, "#ffffff", 0.28), "shadow" = BlendRGB(casing, "#000000", 0.65), "screen" = BlendRGB(screen, "#05080c", 0.78), "ink" = BlendRGB(screen, "#ffffff", 0.75), "accent" = BlendRGB(screen, "#ffffff", 0.4), "ratio" = ratio, "kind" = handheld ? "handheld" : "console")
	profiles[key] = profile
	return profile

/datum/asset/simple/device_ui
	assets = list("device-ui.css" = 'html/device-ui.css', "device-ui.js" = 'html/device-ui.js')

// Wrap the existing document without changing its links, forms or framework root.
// The metadata uses HTML attribute encoding; sprite names never become script.
/proc/device_ui_html(var/mob/user, var/html, var/window_id, var/datum/source, var/close_command = null, var/close_href = null)
	var/atom/host = device_ui_host(source)
	if(!host || !istext(html) || !length(html))
		return html
	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/device_ui)
	assets.send(user)
	var/list/profile = device_ui_profile(host)
	var/list/config = list("window" = window_id, "name" = strip_improper(host.name), "kind" = profile["kind"], "closeCommand" = close_command, "closeHref" = close_href)
	if(!close_command && !close_href)
		config["closeCommand"] = device_ui_close_command(window_id, "\ref[host]")
	var/head = "<meta name='device-screen' content='[html_encode(json_encode(config))]'><link rel='stylesheet' href='device-ui.css'><style>"
	head += "body.device-ui{color:[profile["ink"]] !important;background:[profile["shadow"]] !important;}#device-frame{background-color:[profile["casing"]];border-color:[profile["rim"]] [profile["shadow"]] [profile["shadow"]] [profile["rim"]];}#device-glass{background-color:[profile["screen"]];border-color:[profile["shadow"]];color:[profile["ink"]];}#device-frame .device-hardware{color:[profile["ink"]];}body.device-ui a,body.device-ui #uiTitleText,body.device-ui .uiTitle,body.device-ui h1,body.device-ui h2,body.device-ui h3{color:[profile["accent"]] !important;}#device-indicator{background:[profile["accent"]];box-shadow:0 0 5px [profile["accent"]];}"
	head += "</style><script src='device-ui.js'></script>"
	// Mount before deferred UI bundles navigate to their BYOND initialization URL.
	var/mount_script = "<script>if(window.DeviceUI){window.DeviceUI.mount();}</script>"
	var/head_end = findtext(html, "</head>")
	if(head_end)
		html = "[copytext(html, 1, head_end)][head][copytext(html, head_end)]"
		var/body_end = findlasttext(html, "</body>")
		if(body_end)
			return "[copytext(html, 1, body_end)][mount_script][copytext(html, body_end)]"
		return "[html][mount_script]"
	return "<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'>[head]</head><body>[html][mount_script]</body></html>"

/proc/device_ui_options(var/options, var/datum/source)
	var/atom/host = device_ui_host(source)
	if(!host)
		return options
	var/list/params = params2list(options)
	params["border"] = 0
	params["titlebar"] = 0
	params["can_close"] = 1
	// Native resizing adds the Windows frame even with titlebar=0. The bezel's
	// resize handle changes the size through winset instead.
	params["can_resize"] = 0
	params["can_minimize"] = 0
	params["can_maximize"] = 0
	// Preserve the content area, but start with the physical display's orientation.
	var/list/size = splittext(params["size"] ? params["size"] : "500x400", "x")
	var/area = max(280, text2num(size[1])) * max(180, text2num(size[size.len]))
	var/list/profile = device_ui_profile(host)
	var/ratio = profile["ratio"]
	var/w = clamp(round(sqrt(area * ratio)), 320, 1100)
	var/h = clamp(round(w / ratio), 240, 850)
	params["size"] = "[w + 48]x[h + 76]"
	return list2params(params)

/proc/device_ui_configure(var/mob/user, var/window_id, var/datum/source)
	if(!user || !user.client || !window_id || !device_ui_host(source))
		return
	// browse options only apply when a popup is first created. Also repair an
	// existing window, and remove the embedded browser control's sunken border.
	winset(user, window_id, "titlebar=false;can-resize=false;can-minimize=false;can-maximize=false")
	winset(user, "[window_id].browser", "border=none")

/proc/device_ui_close_command(var/window_id, var/atomref = "null")
	// A single encoded argument avoids BYOND prompting for a second text input.
	return ".deviceclose [url_encode(list2params(list("window" = window_id, "ref" = atomref)))]"

/proc/device_ui_browse(var/mob/user, var/html, var/options, var/datum/source)
	if(!html || !device_ui_host(source))
		user << browse(html, options)
		return
	var/list/params = params2list(options)
	user << browse(device_ui_html(user, html, params["window"], source), device_ui_options(options, source))
	device_ui_configure(user, params["window"], source)

/client/verb/deviceclose(var/payload as text)
	set hidden = TRUE
	set name = ".deviceclose"
	var/list/params = params2list(url_decode(payload))
	var/window_id = params["window"]
	if(!istext(window_id) || !length(window_id))
		return
	var/atomref = params["ref"] ? params["ref"] : "null"
	var/atom/host = locate(atomref)
	if(mob && mob.machine == host)
		mob.unset_machine()
	windowclose(atomref)
	// Some legacy close callbacks render once more. Close after cleanup and
	// unsubscribe again so processing ticks cannot reopen the screen.
	if(mob && mob.machine == host)
		mob.unset_machine()
	src << browse(null, "window=[window_id]")
