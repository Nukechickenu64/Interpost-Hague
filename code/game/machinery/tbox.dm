// The T-box home game console, its CRT television, controller and cartridges.
//
// Examining a powered CRT television opens a PICO-8 emulator window driven by
// whatever cartridge sits in a T-box console within one tile of the set.
// The first viewer holding a T-box controller in their hands becomes the
// active player: their client runs the emulator (nano/js/pico8.js) and streams
// framebuffer updates plus full savestates back to the console. Everyone else
// who examines the television gets a spectator window that mirrors the
// player's screen exactly. The last uploaded savestate persists on the console
// even with nobody watching, so play resumes exactly where it stopped; it is
// only wiped when the cartridge is removed or the console is reset via its
// right-click verb.

#define TBOX_MAX_VIEW_RANGE 7
#define TBOX_MAX_UPLOAD_LENGTH 131072

// ---- cartridge ------------------------------------------------------------

/obj/item/tbox_cartridge
	name = "\improper T-box game cartridge"
	desc = "A chunky plastic game cartridge for the T-box home console."
	icon = 'icons/obj/tbox.dmi'
	icon_state = "tbox_cart"
	item_state = "electronic"
	w_class = ITEM_SIZE_SMALL
	var/cart_id  // key into the global pico8_cart_library (local emulator carts)
	var/bbs_pid  // key into tbox_bbs_cart_library (Lexaloffle BBS widget carts)

/obj/item/tbox_cartridge/Initialize()
	. = ..()
	if(cart_id && pico8_cart_library[cart_id])
		var/list/meta = pico8_cart_library[cart_id]
		name = "\improper T-box game cartridge ([meta["title"]])"
		desc += " The label reads \"[meta["title"]]\"."
	else if(bbs_pid && tbox_bbs_cart_library[bbs_pid])
		name = "\improper T-box netlink cartridge ([tbox_bbs_cart_library[bbs_pid]])"
		desc += " A holographic sticker reads \"[tbox_bbs_cart_library[bbs_pid]]\" above a tiny antenna; it streams its game over the extranet."

/obj/item/tbox_cartridge/proc/is_valid()
	return (cart_id && pico8_cart_library[cart_id]) || (bbs_pid && tbox_bbs_cart_library[bbs_pid])

/obj/item/tbox_cartridge/breakout
	cart_id = "breakout"

/obj/item/tbox_cartridge/spessman
	cart_id = "spessman"

// Unlabeled flea-market cartridge: becomes a random game from the library.
/obj/item/tbox_cartridge/random/Initialize()
	cart_id = pick(pico8_cart_library)
	. = ..()

// Netlink cartridge: spawns as a random featured cart from the Lexaloffle BBS
// (tbox_bbs_carts.dm), streamed through the official widget player.
/obj/item/tbox_cartridge/bbs/Initialize()
	bbs_pid = pick(tbox_bbs_cart_library)
	. = ..()

// ---- controller -----------------------------------------------------------

/obj/item/tbox_controller
	name = "\improper T-box controller"
	desc = "A two-button game pad for the T-box home console. Hold it in your hands to take control of whatever the console is hooked up to."
	icon = 'icons/obj/tbox.dmi'
	icon_state = "tbox_pad"
	item_state = "electronic"
	w_class = ITEM_SIZE_SMALL

/obj/item/tbox_controller/attack_self(mob/user)
	to_chat(user, "<span class='notice'>You mash the buttons of \the [src]. Nothing happens; it needs a running T-box in sight.</span>")

// ---- console ---------------------------------------------------------------

/obj/machinery/tbox
	name = "\improper T-box game console"
	desc = "A Tanotrusen T-box home entertainment console. Feed it a game cartridge and park it next to a television."
	icon = 'icons/obj/tbox.dmi'
	icon_state = "tbox"
	density = FALSE
	anchored = TRUE
	use_power = POWER_USE_OFF
	interact_offline = TRUE

	var/obj/item/tbox_cartridge/cart

	// Persistent game state, exactly as last reported by the player's emulator.
	var/saved_state           // raw savestate JSON uploaded by the player's window
	var/saved_fb              // RLE framebuffer of the last savestate, for fresh spectator windows
	var/saved_fb_seq = 0

	var/mob/active_player
	var/obj/machinery/crt_tv/player_tv
	var/player_is_bbs = FALSE    // active session streams a BBS cart through the official widget
	var/list/spectators = list() // mob -> television they are watching through

	// Reassembly buffer for chunked uploads from the player's window.
	var/up_kind
	var/up_seq = 0
	var/up_total = 0
	var/up_recv = 0
	var/list/up_chunks

/obj/machinery/tbox/Destroy()
	end_all_sessions("SIGNAL LOST")
	if(cart)
		cart.dropInto(loc)
		cart = null
	return ..()

/obj/machinery/tbox/examine(mob/user)
	. = ..(user, 1)
	if(.)
		if(cart)
			to_chat(user, "<span class='notice'>\The [cart] is slotted into it. Click it to pop the cartridge out, or use the right-click verb to reset the game.</span>")
		else
			to_chat(user, "<span class='notice'>Its cartridge slot is empty.</span>")

/obj/machinery/tbox/update_icon()
	icon_state = cart ? "tbox_on" : "tbox"

/obj/machinery/tbox/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/tbox_cartridge))
		var/obj/item/tbox_cartridge/C = W
		if(!C.is_valid())
			to_chat(user, "<span class='warning'>\The [src] refuses \the [C]; the cartridge seems to be a dud.</span>")
			return TRUE
		if(cart)
			to_chat(user, "<span class='warning'>There is already \a [cart] in \the [src]. Remove it first.</span>")
			return TRUE
		if(!user.unEquip(C, FALSE, src))
			return TRUE
		cart = C
		wipe_state()
		update_icon()
		update_tvs()
		user.visible_message("<span class='notice'>\The [user] slots \the [C] into \the [src].</span>", "<span class='notice'>You slot \the [C] into \the [src].</span>")
		return TRUE
	return ..()

/obj/machinery/tbox/attack_hand(mob/user)
	if(..())
		return 1
	if(!cart)
		to_chat(user, "<span class='notice'>The cartridge slot of \the [src] is empty.</span>")
		return 1
	var/obj/item/tbox_cartridge/C = cart
	cart = null
	wipe_state()
	update_icon()
	update_tvs()
	end_all_sessions(null, eject = TRUE)
	C.dropInto(loc)
	user.put_in_hands(C)
	user.visible_message("<span class='notice'>\The [user] pops \the [C] out of \the [src].</span>", "<span class='notice'>You pop \the [C] out of \the [src]. The game state is lost.</span>")
	return 1

// Appears in the console's right-click menu.
/obj/machinery/tbox/verb/reset_game()
	set name = "Reset Game"
	set category = "Object"
	set src in view(1)

	if(!usr || usr.incapacitated() || !Adjacent(usr))
		return
	if(!cart)
		to_chat(usr, "<span class='notice'>\The [src] has no cartridge to reset.</span>")
		return
	wipe_state()
	usr.visible_message("<span class='notice'>\The [usr] jabs the reset button on \the [src].</span>", "<span class='notice'>You jab the reset button on \the [src]. The game starts over.</span>")
	if(player_is_bbs)
		// The widget player can't be rebooted remotely; close the session so
		// the next examine starts the stream over.
		drop_player(null)
		return
	if(active_player)
		push_js(active_player, player_tv, "tboxReset")
	for(var/mob/M in spectators)
		push_js(M, spectators[M], "tboxReset")

/obj/machinery/tbox/Process()
	if(!active_player && !length(spectators))
		return
	validate_sessions()

// ---- session management -----------------------------------------------------

/obj/machinery/tbox/proc/wipe_state()
	saved_state = null
	saved_fb = null
	saved_fb_seq = 0
	up_chunks = null
	up_total = 0
	up_recv = 0

// Televisions find consoles dynamically; poke any nearby set so its screen
// state matches the console.
/obj/machinery/tbox/proc/update_tvs()
	for(var/obj/machinery/crt_tv/tv in range(1, src))
		tv.update_icon()

/obj/machinery/tbox/proc/holding_controller(mob/user)
	return istype(user.get_active_hand(), /obj/item/tbox_controller) || istype(user.get_inactive_hand(), /obj/item/tbox_controller)

/obj/machinery/tbox/proc/window_id(obj/machinery/crt_tv/tv)
	return "tbox\ref[tv]"

/obj/machinery/tbox/proc/push_js(mob/M, obj/machinery/crt_tv/tv, function, list/arguments)
	if(!M || !M.client || !tv)
		return
	if(!islist(arguments))
		arguments = list("")
	send_output(M, list2params(arguments), "[window_id(tv)].browser:[function]")

/obj/machinery/tbox/proc/session_valid(mob/M, obj/machinery/crt_tv/tv)
	if(!M || !M.client || !tv || tv.inoperable())
		return FALSE
	if(M.z != tv.z || get_dist(M, tv) > TBOX_MAX_VIEW_RANGE)
		return FALSE
	return TRUE

/obj/machinery/tbox/proc/validate_sessions()
	if(active_player)
		if(!cart || !session_valid(active_player, player_tv) || !holding_controller(active_player))
			drop_player("SIGNAL LOST")
	for(var/mob/M in spectators.Copy())
		if(!session_valid(M, spectators[M]))
			push_js(M, spectators[M], "tboxKick", list("SIGNAL LOST"))
			spectators -= M

// The player stopped (walked off, dropped the controller, closed the window).
// Their last uploaded savestate stays on the console, so the game freezes
// exactly where it was until somebody picks it back up.
/obj/machinery/tbox/proc/drop_player(reason)
	if(!active_player)
		return
	release_player_controls(active_player)
	if(player_is_bbs)
		// The widget window has none of our JS hooks; just close it.
		if(active_player.client && player_tv)
			show_browser(active_player, null, "window=[window_id(player_tv)]")
	else if(reason)
		push_js(active_player, player_tv, "tboxKick", list(reason))
	active_player = null
	player_tv = null
	player_is_bbs = FALSE
	up_chunks = null
	up_total = 0
	up_recv = 0
	for(var/mob/M in spectators)
		push_js(M, spectators[M], "tboxPause")

/obj/machinery/tbox/proc/end_all_sessions(reason, eject = FALSE)
	var/function = eject ? "tboxEject" : "tboxKick"
	if(active_player)
		release_player_controls(active_player)
		if(player_is_bbs)
			if(active_player.client && player_tv)
				show_browser(active_player, null, "window=[window_id(player_tv)]")
		else
			push_js(active_player, player_tv, function, eject ? null : list(reason))
		active_player = null
		player_tv = null
		player_is_bbs = FALSE
	for(var/mob/M in spectators)
		push_js(M, spectators[M], function, eject ? null : list(reason))
	spectators.Cut()
	up_chunks = null
	up_total = 0
	up_recv = 0

/obj/machinery/tbox/proc/viewer_closed(mob/M)
	if(M == active_player)
		drop_player(null)
	else
		spectators -= M

// ---- keyboard input via BYOND macros --------------------------------------
// Keyboard events inside browse windows are unreliable, so while somebody is
// playing, their client's windows are switched to the "tbox" macro set
// (interface/skin.dmf): the BYOND client captures the keys itself and routes
// them through the .tboxkey verb to the player's emulator window. The
// previous macro set is restored the moment the session ends; Escape also
// hands the controls back.

/client/var/obj/machinery/tbox/tbox_console
/client/var/tbox_prev_macro

/client/verb/tbox_key(btn as num, down as num)
	set name = ".tboxkey"
	set hidden = 1
	set instant = 1
	if(tbox_console)
		tbox_console.player_key(mob, btn, down)

/client/verb/tbox_quit()
	set name = ".tboxquit"
	set hidden = 1
	set instant = 1
	if(tbox_console)
		tbox_console.player_quit(mob)

/obj/machinery/tbox/proc/grab_player_controls(mob/user, obj/machinery/crt_tv/tv)
	var/client/C = user.client
	if(!C)
		return
	C.tbox_console = src
	if(isnull(C.tbox_prev_macro))
		var/current = winget(C, "mainwindow", "macro")
		C.tbox_prev_macro = length(current) ? current : "macro"
	winset(C, window_id(tv), "macro=tbox")
	winset(C, "mainwindow", "macro=tbox")
	winset(C, "mapwindow.map", "focus=true")

/obj/machinery/tbox/proc/release_player_controls(mob/M)
	var/client/C = M && M.client
	if(!C || C.tbox_console != src)
		return
	C.tbox_console = null
	var/previous = C.tbox_prev_macro
	C.tbox_prev_macro = null
	if(!length(previous))
		previous = "macro"
	winset(C, "mainwindow", "macro=[previous]")
	winset(C, "mapwindow.map", "focus=true")

/obj/machinery/tbox/proc/player_key(mob/user, btn, down)
	if(!user || user != active_player || !cart)
		return
	if(!holding_controller(user))
		return
	btn = text2num("[btn]")
	if(isnull(btn))
		return
	btn = round(btn)
	if(btn < 0 || btn > 9)
		return
	push_js(active_player, player_tv, "tboxKey", list("[btn]", down ? "1" : "0"))

/obj/machinery/tbox/proc/player_quit(mob/user)
	if(user != active_player)
		return
	drop_player("STANDBY")
	to_chat(user, "<span class='notice'>You stop playing; the game is frozen where you left it.</span>")

// Opens (or refreshes) a viewing session on the given television for a user.
/obj/machinery/tbox/proc/open_session(mob/user, obj/machinery/crt_tv/tv)
	if(!user.client || !cart)
		return

	if(cart.bbs_pid)
		open_bbs_session(user, tv)
		return

	var/role = "spectator"
	if(user == active_player)
		role = "player"
		player_tv = tv
	else if(!active_player && holding_controller(user))
		role = "player"
		active_player = user
		player_tv = tv
		spectators -= user
	else
		spectators[user] = tv

	send_asset(user.client, "pico8_fengari.js")
	send_asset(user.client, "pico8.js")
	send_asset(user.client, "pico8_tbox.js")

	var/cart_source = file2text("nano/pico8/carts/[cart.cart_id].p8")
	var/list/meta = pico8_cart_library[cart.cart_id]
	var/state_js = (role == "player" && saved_state) ? saved_state : "null"
	var/fb_js = saved_fb ? json_encode(saved_fb) : "null"
	var/hint
	var/pad_html = ""
	if(role == "player")
		hint = "PLAYING - arrows move, Z/X act, Enter/P for menu, Esc hands the controller back. Your character stands still while you play."
		pad_html = {"<div id="pad">
<span class="pbtn" data-btn="0">&#9664;</span><span class="pbtn" data-btn="2">&#9650;</span><span class="pbtn" data-btn="3">&#9660;</span><span class="pbtn" data-btn="1">&#9654;</span>
<span class="pgap"></span>
<span class="pbtn pact" data-btn="4">Z</span><span class="pbtn pact" data-btn="5">X</span>
<span class="pgap"></span>
<span class="pbtn psm" data-btn="8">ENT</span><span class="pbtn psm" data-btn="9">P</span>
</div>"}
	else if(active_player)
		hint = "WATCHING [sanitize(active_player.name)] - grab a controller and look again once they stop to play"
	else
		hint = "WATCHING - hold a T-box controller in your hands and look at the television again to play"

	var/html = {"<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<style>
	body { background: #14100e; color: #c2c3c7; font-family: monospace; margin: 0; text-align: center; }
	#bezel { display: inline-block; margin-top: 12px; padding: 18px; background: #3b2f26; border-radius: 12px; border: 2px solid #241c16; }
	#holder { position: relative; width: 512px; height: 512px; background: #000; }
	#p8screen { width: 512px; height: 512px; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor; }
	#p8overlay { display: none; position: absolute; left: 0; top: 44%; width: 100%; color: #fff1e8; background: rgba(0,0,0,0.75); padding: 8px 0; font-size: 18px; letter-spacing: 2px; }
	#pad { margin-top: 10px; }
	.pbtn { display: inline-block; min-width: 34px; padding: 10px 8px; margin: 0 3px; background: #3b2f26; color: #fff1e8; border: 2px solid #241c16; border-radius: 8px; font-size: 16px; cursor: pointer; -webkit-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; }
	.pbtn:active { background: #5a4636; }
	.pact { background: #7e2553; }
	.pact:active { background: #a53371; }
	.psm { font-size: 11px; padding: 12px 6px; }
	.pgap { display: inline-block; width: 16px; }
	#hint { margin: 10px; font-size: 12px; color: #83769c; }
	#title { margin-top: 8px; font-size: 14px; color: #ffa300; }
</style>
<script type="text/javascript" src="pico8_fengari.js"></script>
<script type="text/javascript" src="pico8.js"></script>
<script type="text/javascript">
	window.TBOX_CFG = {
		role: "[role]",
		src: "\ref[src]",
		cart: [json_encode(cart_source)],
		state: [state_js],
		fb: [fb_js],
		fbSeq: [saved_fb_seq]
	};
</script>
<script type="text/javascript" src="pico8_tbox.js"></script>
</head>
<body>
<div id="bezel"><div id="holder"><canvas id="p8screen" width="128" height="128"></canvas><div id="p8overlay"></div></div></div>
[pad_html]
<div id="title">[sanitize(meta["title"])]</div>
<div id="hint">[hint]</div>
</body>
</html>"}

	show_browser(user, html, "window=[window_id(tv)];size=570x[role == "player" ? 710 : 650];title=[tv.name]")
	onclose(user, window_id(tv), src)
	// Keyboard input goes through the "tbox" macro set rather than the
	// browser window; grab the client's macros for the duration of play.
	if(role == "player")
		grab_player_controls(user, tv)

	// Get spectators onto the live delta stream as soon as possible.
	if(role == "spectator" && active_player)
		push_js(active_player, player_tv, "tboxKeyframe")

// BBS netlink carts play through Lexaloffle's official embeddable widget
// player, streamed straight from the extranet into the television. The real
// player is a sealed cross-origin app, so there is no savestate persistence
// and no spectator mirroring: one controller holder plays at a time, keys go
// directly into the embedded player, and reset/eject simply end the stream.
/obj/machinery/tbox/proc/open_bbs_session(mob/user, obj/machinery/crt_tv/tv)
	var/title = tbox_bbs_cart_library[cart.bbs_pid]
	if(user == active_player)
		player_tv = tv
	else if(active_player)
		to_chat(user, "<span class='notice'>The screen shows <b>[title]</b>; [active_player] is wired into it right now.</span>")
		return
	else if(!holding_controller(user))
		to_chat(user, "<span class='notice'>The screen shows the title card of <b>[title]</b>. You need a T-box controller in your hands to tune in.</span>")
		return
	else
		active_player = user
		player_tv = tv
		player_is_bbs = TRUE
		spectators -= user

	var/html = {"<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<style>
	body { background: #14100e; color: #c2c3c7; font-family: monospace; margin: 0; text-align: center; }
	#bezel { display: inline-block; margin-top: 12px; padding: 12px; background: #3b2f26; border-radius: 12px; border: 2px solid #241c16; }
	iframe { border: 0; background: #000; }
	#title { margin-top: 8px; font-size: 14px; color: #ffa300; }
	#hint { margin: 10px; font-size: 12px; color: #83769c; }
</style>
</head>
<body>
<div id="bezel"><iframe src="https://www.lexaloffle.com/bbs/widget.php?pid=[cart.bbs_pid]" width="520" height="580" allowfullscreen></iframe></div>
<div id="title">[sanitize(title)]</div>
<div id="hint">STREAMING FROM THE EXTRANET - click the player to start, arrows move, Z/X act. No save states on netlink carts; closing the window ends the stream.</div>
</body>
</html>"}

	show_browser(user, html, "window=[window_id(tv)];size=600x720;title=[tv.name]")
	onclose(user, window_id(tv), src)


// ---- uploads from the player's window ----------------------------------------

/obj/machinery/tbox/Topic(href, href_list)
	if(href_list["close"])
		if(usr)
			viewer_closed(usr)
		return 1
	if(href_list["tbup"])
		if(!usr || usr != active_player)
			return 1
		handle_upload(href_list)
		return 1
	return 0

/obj/machinery/tbox/proc/handle_upload(list/href_list)
	var/kind = href_list["k"]
	if(kind != "ss" && kind != "fr")
		return
	var/seq = text2num(href_list["q"])
	var/index = text2num(href_list["i"])
	var/total = text2num(href_list["n"])
	var/data = href_list["d"]
	if(!seq || !index || !total || isnull(data) || index > total || total > 128)
		return
	if(seq != up_seq || kind != up_kind || total != up_total || !up_chunks)
		up_seq = seq
		up_kind = kind
		up_total = total
		up_recv = 0
		up_chunks = new/list(total)
	if(up_chunks[index])
		return
	up_chunks[index] = data
	up_recv++
	if(up_recv < up_total)
		return
	var/payload = jointext(up_chunks, null)
	up_chunks = null
	up_total = 0
	up_recv = 0
	process_upload(kind, payload)

/obj/machinery/tbox/proc/process_upload(kind, payload)
	if(!cart || length(payload) > TBOX_MAX_UPLOAD_LENGTH)
		return
	// The payload is re-broadcast into other viewers' browser windows; never
	// allow anything that could smuggle markup in.
	if(findtext(payload, "<") || findtext(payload, ">"))
		return
	switch(kind)
		if("ss")
			var/list/state
			try
				state = json_decode(payload)
			catch(var/exception/error)
				if(error)
					return
			if(!islist(state))
				return
			saved_state = payload
			saved_fb = state["fb"]
			saved_fb_seq = text2num("[state["seq"]]") || 0
		if("fr")
			for(var/mob/M in spectators)
				push_js(M, spectators[M], "tboxFrame", list(payload))

// ---- television ---------------------------------------------------------------

/obj/machinery/crt_tv
	name = "\improper CRT television"
	desc = "A hefty cathode-ray tube television in a fake wood cabinet. Examine it to watch whatever is plugged in."
	icon = 'icons/obj/tbox.dmi'
	icon_state = "tv_off"
	density = TRUE
	anchored = TRUE
	idle_power_usage = 120
	use_power = POWER_USE_IDLE

/obj/machinery/crt_tv/Initialize()
	. = ..()
	update_icon()

/obj/machinery/crt_tv/examine(mob/user)
	. = ..(user, 3)
	if(!user.client)
		return
	if(user.z != z || get_dist(user, src) > TBOX_MAX_VIEW_RANGE)
		return
	if(user.stat && !isobserver(user))
		return
	try_watch(user)

/obj/machinery/crt_tv/update_icon()
	if(inoperable())
		icon_state = "tv_off"
	else
		var/obj/machinery/tbox/console = find_console()
		icon_state = (console && console.cart) ? "tv_on" : "tv_static"

/obj/machinery/crt_tv/power_change()
	. = ..()
	update_icon()

/obj/machinery/crt_tv/proc/find_console()
	for(var/obj/machinery/tbox/console in range(1, src))
		return console
	return null

/obj/machinery/crt_tv/proc/try_watch(mob/user)
	if(inoperable())
		to_chat(user, "<span class='notice'>The screen is dark.</span>")
		return
	var/obj/machinery/tbox/console = find_console()
	update_icon()
	if(!console)
		to_chat(user, "<span class='notice'>The screen hisses with static; nothing is plugged into \the [src].</span>")
		return
	if(!console.cart)
		to_chat(user, "<span class='notice'>The screen shows a bouncing logo: <b>INSERT CARTRIDGE</b>.</span>")
		return
	console.open_session(user, src)

#undef TBOX_MAX_VIEW_RANGE
#undef TBOX_MAX_UPLOAD_LENGTH
