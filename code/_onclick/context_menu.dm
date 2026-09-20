// Shift+Right-Click tile context menu implementation

// Opens a small, borderless browser window listing all atoms on the turf, allowing the user
// to select which atom to target for right-click interactions. It appears at the mouse cursor.
/mob/proc/open_tile_context_menu(var/turf/T, var/atom/clicked, var/params)
	if(!client || !clicked)
		return

	// Position the menu at the mouse cursor, like a native right-click dropdown.
	// BYOND's screen-loc uses a bottom-left origin with 1-based indices; window pos uses
	// a top-left origin in screen pixels. We must convert between the two.
	var/list/P = istext(params) ? params2list(params) : null
	var/has_pos = FALSE
	var/pos_x = 0
	var/pos_y = 0

	if(P && P["screen-loc"])
		var/list/sl = splittext(P["screen-loc"], ",")
		if(sl.len >= 2)
			var/list/xp = splittext(sl[1], ":")
			var/list/yp = splittext(sl[2], ":")
			if(xp.len >= 2 && yp.len >= 2)
				// Determine view dimensions (client.view may be a number or "WxH" string)
				var/view_x = 7
				var/view_y = 7
				if(istext(client.view))
					var/list/vp = splittext("[client.view]", "x")
					view_x = text2num(vp[1]) || 7
					if(vp.len >= 2)
						view_y = text2num(vp[2]) || view_x
					else
						view_y = view_x
				else
					view_x = client.view
					view_y = client.view

				var/col = _screen_loc_to_index(xp[1], view_x, TRUE)
				var/row = _screen_loc_to_index(yp[1], view_y, FALSE)
				var/pix_x = text2num(xp[2]) || 0
				var/pix_y = text2num(yp[2]) || 0

				// The map control's "pos" from winget returns an absolute screen position
				// when the window is docked as a pane. We do NOT add mainwindow's position
				// on top of it — that would double-count and skew the menu right/down.
				var/map_pos = winget(src, "mapwindow.map", "pos")
				var/map_size = winget(src, "mapwindow.map", "size")
				var/map_icon_size = winget(src, "mapwindow.map", "icon-size")

				if(map_pos)
					var/list/mp = splittext(map_pos, ",")
					if(mp.len >= 2)
						var/map_x = text2num(mp[1])
						var/map_y = text2num(mp[2])

						var/map_w_px = 0
						var/map_h_px = 0
						if(map_size)
							var/list/ms = splittext(map_size, "x")
							if(ms.len >= 2)
								map_w_px = text2num(ms[1]) || 0
								map_h_px = text2num(ms[2]) || 0

						// Number of tiles visible in each dimension
						var/tiles_x = view_x * 2 + 1
						var/tiles_y = view_y * 2 + 1

						// Determine the actual on-screen tile size.
						// icon-size=0 means "stretch to fit" — tiles are scaled to fill the control.
						// icon-size=N means fixed N-pixel tiles, possibly centered in the control.
						var/tile_px = world.icon_size
						var/is_stretch = TRUE
						if(map_icon_size)
							var/icon_sz = text2num(map_icon_size)
							if(icon_sz && icon_sz > 0)
								tile_px = icon_sz
								is_stretch = FALSE

						var/grid_off_x = 0
						var/grid_off_y = 0
						var/eff_tile_w = tile_px
						var/eff_tile_h = tile_px

						if(is_stretch && map_w_px > 0 && map_h_px > 0)
							// Stretch mode: tiles fill the entire control
							eff_tile_w = map_w_px / tiles_x
							eff_tile_h = map_h_px / tiles_y
						else
							// Fixed tile mode: grid may be centered in the control
							var/grid_w = tiles_x * tile_px
							var/grid_h = tiles_y * tile_px
							grid_off_x = max(0, round((map_w_px - grid_w) / 2))
							grid_off_y = max(0, round((map_h_px - grid_h) / 2))

						// Convert screen-loc (bottom-left origin, 1-based) to screen pixels
						// (top-left origin). In stretch mode, pixel offsets scale proportionally.
						var/scale_x = eff_tile_w / world.icon_size
						var/scale_y = eff_tile_h / world.icon_size

						pos_x = map_x + grid_off_x + (col - 1) * eff_tile_w + (pix_x - 1) * scale_x
						pos_y = map_y + map_h_px - grid_off_y - (row - 1) * eff_tile_h - pix_y * scale_y
						has_pos = TRUE

	// Fallback to last known position if we couldn't determine the cursor position
	if(!has_pos && !isnull(tilectx_last_pos_x) && !isnull(tilectx_last_pos_y))
		pos_x = tilectx_last_pos_x
		pos_y = tilectx_last_pos_y
		has_pos = TRUE

	// Build a stable list of visible atoms for the menu. For HUD elements we include the clicked screen
	// control itself and its underlying object so the menu still opens when there is no turf.
	var/list/atoms_on_tile = list()
	if(T)
		atoms_on_tile += T
		for(var/atom/A in T)
			if(istype(A, /obj/screen))
				continue
			if(A.invisibility && A.invisibility > see_invisible)
				continue
			atoms_on_tile += A
	else if(clicked)
		atoms_on_tile += clicked
		if(istype(clicked, /obj/screen))
			var/obj/screen/S = clicked
			if(S.master && S.master != clicked)
				atoms_on_tile += S.master

	if(!atoms_on_tile.len && clicked)
		atoms_on_tile += clicked

	// Optional: cap the number to avoid huge menus
	var/max_items = 100
	if(atoms_on_tile.len > max_items)
		atoms_on_tile.len = max_items

	// Precompute dynamic window height based on number of entries
	var/items_count = max(1, atoms_on_tile.len)
	var/base_h = 90
	var/row_h = 18
	var/min_h = 140
	var/max_h = 720
	var/dyn_h = clamp(base_h + (items_count * row_h), min_h, max_h)

	// Compose HTML menu with a diegetic style
	// DOCTYPE is required: without it the embedded browser renders in quirks mode, where
	// document.body.scrollHeight reports the viewport height instead of the actual content
	// height, so the auto-fit below silently fails and the background never shrinks to the border.
	var/html = "<!DOCTYPE html><html><head><title>Local Context</title>"
	html += "<style>"
	html += "html,body{background:#050b09;color:#6fe8c0;font-family:'Consolas','Courier New',monospace;font-size:9pt;margin:0;padding:0;}"
	html += ".wrap{display:inline-block;position:relative;padding:10px 12px;min-width:220px;max-width:360px;border:1px solid #4fe0ab;background:rgba(10,30,24,0.92);box-shadow:0 0 10px rgba(79,224,171,0.2) inset;}"
	html += ".corner{position:absolute;width:7px;height:7px;border-color:#8ffcd2;}"
	html += ".corner.tl{top:-1px;left:-1px;border-top:2px solid;border-left:2px solid;}"
	html += ".corner.tr{top:-1px;right:-1px;border-top:2px solid;border-right:2px solid;}"
	html += ".corner.bl{bottom:-1px;left:-1px;border-bottom:2px solid;border-left:2px solid;}"
	html += ".corner.br{bottom:-1px;right:-1px;border-bottom:2px solid;border-right:2px solid;}"
	html += ".hdr{font-size:10pt;color:#8ffcd2;letter-spacing:0.1em;text-transform:uppercase;text-align:center;margin-bottom:6px;padding-bottom:4px;border-bottom:1px solid rgba(111,232,192,0.4);}"
	html += ".accent{height:1px;background:linear-gradient(90deg,transparent,#4fe0ab,transparent);margin:6px 0 8px 0;}"
	html += ".note{color:#4fa88a;opacity:0.9;font-size:8pt;text-transform:uppercase;letter-spacing:0.05em;} .loc{color:#8ffcd2;}"
	html += ".item{margin:3px 0;padding:0;border:1px solid rgba(111,232,192,0.35);background:rgba(111,232,192,0.04);text-transform:uppercase;letter-spacing:0.05em;white-space:nowrap;}"
	html += ".item:hover{background:rgba(111,232,192,0.15);border-color:#8ffcd2;}"
	html += ".item.plain{padding:3px 6px;text-align:center;color:#4fa88a;}"
	html += ".item.two{display:table;width:100%;table-layout:fixed;}"
	html += ".item a{color:#8ffcd2;text-decoration:none;display:block;padding:3px 6px;text-align:center;}"
	html += ".item a:hover{color:#c8fff0;}"
	html += ".item.two a.main{display:table-cell;vertical-align:middle;width:100%;}"
	html += ".item.two a.expand{display:table-cell;vertical-align:middle;width:26px;border-left:1px solid rgba(111,232,192,0.35);}"
	html += "</style>"
	// Auto-fit the browser window to the bordered .wrap element itself, not the viewport
	html += "<script type='text/javascript'>function __tilectx_fit(){try{var el=document.getElementById('wrap');var w=Math.ceil(el.offsetWidth);var h=Math.ceil(el.offsetHeight);window.location='?src=\ref[src];tilectx_fit=1;w='+w+';h='+h;}catch(e){}};window.onload=function(){setTimeout(__tilectx_fit,10)};</script>"
	html += "</head><body><div id='wrap' class='wrap'>"
	html += "<span class='corner tl'></span><span class='corner tr'></span><span class='corner bl'></span><span class='corner br'></span>"
	html += "<div class='hdr'>Local Context</div>"
	html += "<div class='note' style='text-align:center;margin-bottom:6px;'>Select an object to interact.</div>"

	if(!atoms_on_tile.len)
		html += "<div class='item plain'>(Nothing here)</div>"
	else
		// Show top-most last added first (simple: reverse iterate so contents appear above turf)
		for(var/i = atoms_on_tile.len, i >= 1, i--)
			var/atom/A = atoms_on_tile[i]
			var/label = sanitizeSafe(A.name, 64, 1, 1, 1)
			// Skip nameless entries to avoid blank rows
			if(!label || !length(label))
				continue
			// Build links using inline BYOND ref tokens so the engine encodes them properly at compile-time.
			if(isturf(A))
				// Don't make the turf itself clickable for pickup
				html += "<div class='item plain'>[label]</div>"
			else
				// Split into two cells (label + expand) so each is independently clickable across its full area
				var/clicked_suffix = (A == clicked) ? " (CLICKED)" : ""
				html += "<div class='item two'><a class='main' href=\"?src=\ref[src];tilectx_invoke=\ref[A];proc=pickup\">[label][clicked_suffix]</a><a class='expand' href=\"?src=\ref[src];tilectx_obj=\ref[A]\">...</a></div>"

	// Close row and HTML wrapper (always include)
	html += "<div class='accent'></div><div class='item'><a href=\"?src=\ref[src];mach_close=tilectx\">Close</a></div>"
	html += "</div></body></html>"

	// Open the menu window: borderless, non-resizable, placed at mouse cursor if possible
	var/browse_args = "window=tilectx;border=0;titlebar=0;can_resize=0;can_minimize=0;can_close=1;size=260x[dyn_h]"
	if(has_pos)
		browse_args += ";pos=[pos_x],[pos_y]"
	src << browse(html, browse_args)
	if(has_pos)
		tilectx_last_pos_x = pos_x
		tilectx_last_pos_y = pos_y
		// Ensure position sticks if the engine ignores the initial pos argument sometimes
		winset(src, "tilectx", "pos=[pos_x],[pos_y]")

	// Mark as open for click-away close
	src.tilectx_open = TRUE
	// Remember last context for back navigation
	src.tilectx_last_turf = T
	src.tilectx_last_clicked = clicked

// Open a verb/action menu for a specific object, with an image preview and a list of available verbs.
/mob/proc/open_object_context_menu(var/atom/target)
	if(!client || !target)
		return

	// Determine if the viewer has admin privileges
	var/is_admin = (client && client.holder)
	// Precompute jump target turf for admin jump link
	var/turf/admin_jump_turf = null
	if(is_admin)
		admin_jump_turf = get_turf(target)

	// Attempt to capture a flat icon of the target
	var/icon/I = null
	var/icon_w = 32
	var/icon_h = 32
	if(istype(target, /atom))
		I = getFlatIcon(target)
		if(istype(I, /icon))
			icon_w = I.Width()
			icon_h = I.Height()

	var/rsc_name = "tilectx_obj_[rand(1,1000000)].png"
	if(I)
		src << browse_rsc(I, rsc_name)

	// Build verbs list from the object's verbs
	var/list/verbs_list = list()
	var/list/target_verbs = target.verbs
	if(target_verbs)
		for(var/V in target_verbs)
			var/pathtext = "[V]" // e.g., /obj/item/verb/toggle
			var/list/parts = splittext(pathtext, "/")
			if(!parts || !parts.len) continue
			var/procname = parts[parts.len]
			if(!procname || findtext(procname, "..")) continue
			// Labelize: underscores to spaces, capitalize first letter
			var/label = capitalize(replacetext(procname, "_", " "))
			verbs_list += list(list("proc"=procname, "label"=label))

	// Precompute dynamic height
	var/items_count = verbs_list.len + 4 // include standard actions
	if(is_admin)
		// Admin section: VV + Jump are always present; PP + Follow only for mobs
		items_count += 2
		if(ismob(target))
			items_count += 2
	var/base_h = 150
	var/row_h = 18
	var/min_h = 160
	var/max_h = 800
	var/dyn_h = clamp(base_h + (items_count * row_h), min_h, max_h)

	// DOCTYPE is required: without it the embedded browser renders in quirks mode, where
	// document.body.scrollHeight reports the viewport height instead of the actual content
	// height, so the auto-fit below silently fails and the background never shrinks to the border.
	var/html = "<!DOCTYPE html><html><head><title>Object Actions</title>"
	html += "<style>"
	html += "html,body{background:#050b09;color:#6fe8c0;font-family:'Consolas','Courier New',monospace;font-size:9pt;margin:0;padding:0;}"
	html += ".wrap{display:inline-block;position:relative;padding:10px 12px;min-width:240px;max-width:400px;border:1px solid #4fe0ab;background:rgba(10,30,24,0.92);box-shadow:0 0 10px rgba(79,224,171,0.2) inset;}"
	html += ".corner{position:absolute;width:7px;height:7px;border-color:#8ffcd2;}"
	html += ".corner.tl{top:-1px;left:-1px;border-top:2px solid;border-left:2px solid;}"
	html += ".corner.tr{top:-1px;right:-1px;border-top:2px solid;border-right:2px solid;}"
	html += ".corner.bl{bottom:-1px;left:-1px;border-bottom:2px solid;border-left:2px solid;}"
	html += ".corner.br{bottom:-1px;right:-1px;border-bottom:2px solid;border-right:2px solid;}"
	html += ".hdr{font-size:10pt;color:#8ffcd2;letter-spacing:0.1em;text-transform:uppercase;text-align:center;margin-bottom:4px;padding-bottom:4px;border-bottom:1px solid rgba(111,232,192,0.4);}"
	html += ".accent{height:1px;background:linear-gradient(90deg,transparent,#4fe0ab,transparent);margin:6px 0 8px 0;}"
	html += ".note{color:#4fa88a;opacity:0.9;font-size:8pt;text-transform:uppercase;letter-spacing:0.05em;text-align:center;} .loc{color:#8ffcd2;}"
	html += ".item{margin:3px 0;padding:0;border:1px solid rgba(111,232,192,0.35);background:rgba(111,232,192,0.04);text-transform:uppercase;letter-spacing:0.05em;white-space:nowrap;}"
	html += ".item:hover{background:rgba(111,232,192,0.15);border-color:#8ffcd2;}"
	html += ".item a{color:#8ffcd2;text-decoration:none;display:block;padding:3px 6px;text-align:center;}"
	html += ".item a:hover{color:#c8fff0;}"
	html += ".iconwrap{display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:6px;} .iconwrap img{image-rendering:pixelated;border:1px solid #4fe0ab;background:#091018;}"
	html += "</style>"
	// Auto-fit this object actions window to the bordered .wrap element itself, not the viewport
	html += "<script type='text/javascript'>function __tilectx_fit(){try{var el=document.getElementById('wrap');var w=Math.ceil(el.offsetWidth);var h=Math.ceil(el.offsetHeight);window.location='?src=\ref[src];tilectx_fit=1;w='+w+';h='+h;}catch(e){}};window.onload=function(){setTimeout(__tilectx_fit,10)};</script>"
	html += "</head><body><div id='wrap' class='wrap'>"
	html += "<span class='corner tl'></span><span class='corner tr'></span><span class='corner bl'></span><span class='corner br'></span>"
	var/title = sanitizeSafe(target.name, 64, 1, 1, 1)
	html += "<div class='hdr'>[title]</div>"
	if(I)
		html += "<div class='iconwrap'><img src='[rsc_name]' width='[icon_w]' height='[icon_h]'></div>"
	html += "<div class='accent'></div>"

	// Standard actions
	// Links below use inline BYOND ref tokens for the target
	html += "<div class='item'><a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=examine'>Examine</a></div>"
	html += "<div class='item'><a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=use'>Use</a></div>"
	html += "<div class='item'><a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=use_right'>Right-use</a></div>"
	html += "<div class='item'><a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=pull'>Pull</a></div>"

	// Custom verbs
	if(verbs_list.len)
		html += "<div class='accent'></div><div class='note'>Verbs</div>"
		for(var/entry in verbs_list)
			var/label = entry["label"]
			var/procname = entry["proc"]
			html += "<div class='item'><a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=[url_encode(procname)]'>[label]</a></div>"

	// Admin-only actions
	if(is_admin)
		html += "<div class='accent'></div><div class='note'>Admin</div>"
		// View Variables (VV)
		html += "<div class='item'><a href='?_src_=vars;Vars=\ref[target]'>VV (View Variables)</a></div>"
		// Player Panel (PP) and Follow, only meaningful for mobs
		if(ismob(target))
			html += "<div class='item'><a href='?_src_=holder;adminplayeropts=\ref[target]'>PP (Player Panel)</a></div>"
			html += "<div class='item'><a href='?_src_=holder;adminplayerobservefollow=\ref[target]'>Follow</a></div>"
		// Coordinate Jump (JMP) to the target's turf, if available
		if(admin_jump_turf)
			html += "<div class='item'><a href='?_src_=holder;adminplayerobservecoodjump=1;X=[admin_jump_turf.x];Y=[admin_jump_turf.y];Z=[admin_jump_turf.z]'>Jump</a></div>"

	// Controls
	html += "<div class='accent'></div><div class='item'><a href=\"?src=\ref[src];tilectx_back=1\">Back</a></div><div class='item'><a href=\"?src=\ref[src];mach_close=tilectx\">Close</a></div>"
	html += "</div></body></html>"

	var/browse_args = "window=tilectx;border=0;titlebar=0;can_resize=0;can_minimize=0;can_close=1;size=300x[dyn_h]"
	if(!isnull(tilectx_last_pos_x) && !isnull(tilectx_last_pos_y))
		browse_args += ";pos=[tilectx_last_pos_x],[tilectx_last_pos_y]"
	src.tilectx_last_clicked = target
	src << browse(html, browse_args)
	if(!isnull(tilectx_last_pos_x) && !isnull(tilectx_last_pos_y))
		winset(src, "tilectx", "pos=[tilectx_last_pos_x],[tilectx_last_pos_y]")
	src.tilectx_open = TRUE

/mob/proc/close_tile_context_menu()
	src << browse(null, "window=tilectx")
	tilectx_open = FALSE

/mob/proc/handle_tilectx_topic(var/list/href_list)
	if(!href_list)
		return FALSE

	if(href_list["tilectx_fit"]) {
		var/w = text2num(href_list["w"])
		var/h = text2num(href_list["h"])
		if(w && h)
			// Clamp to sane bounds to prevent absurd window sizes from malformed JS values
			w = clamp(round(w), 100, 800)
			h = clamp(round(h), 100, 900)
			var/fit_args = "size=[w]x[h]"
			if(!isnull(tilectx_last_pos_x) && !isnull(tilectx_last_pos_y))
				fit_args += ";pos=[tilectx_last_pos_x],[tilectx_last_pos_y]"
			winset(src, "tilectx", fit_args)
		return TRUE
	}

	if(href_list["mach_close"] == "tilectx") {
		close_tile_context_menu()
		return TRUE
	}

	if(href_list["tilectx_back"]) {
		if(tilectx_last_turf)
			open_tile_context_menu(tilectx_last_turf, tilectx_last_clicked, null)
		return TRUE
	}

	if(href_list["tilectx_obj"]) {
		var/atom/target_obj = locate(href_list["tilectx_obj"])
		if(target_obj) {
			tilectx_last_clicked = target_obj
			open_object_context_menu(target_obj)
		}
		return TRUE
	}

	if(href_list["tilectx_invoke"]) {
		var/atom/target = locate(href_list["tilectx_invoke"])
		var/procname = href_list["proc"]
		if(target && procname) {
			if(procname == "pickup") {
				if(!target.Adjacent(src)) {
					to_chat(src, "<span class='warning'>You're too far away to pick that up.</span>")
					return TRUE
				}
				target.attack_hand(src)
				close_tile_context_menu()
				return TRUE
			} else if(procname == "examine") {
				target.examine(src)
			} else if(procname == "use") {
				target.attack_hand(src)
			} else if(procname == "use_right") {
				target.attack_hand_right(src)
			} else if(procname == "pull") {
				if(ismovable(target)) {
					var/atom/movable/M = target
					start_pulling(M)
				}
			} else {
				// Validate that the requested proc is an actual verb on the target before calling it
				var/allowed = FALSE
				var/list/target_verbs = target.verbs
				if(target_verbs)
					for(var/V in target_verbs)
						var/list/parts = splittext("[V]", "/")
						if(parts && parts.len && parts[parts.len] == procname)
							allowed = TRUE
							break
				if(allowed)
					call(target, procname)()
			}
			close_tile_context_menu()
			return TRUE
		}
		return FALSE
	}

	return FALSE

// Helper: convert a screen-loc tile reference to a 1-based numeric index.
// Handles "CENTER", "WEST+n"/"EAST-n" (X axis), "SOUTH+n"/"NORTH-n" (Y axis), and plain numbers.
/mob/proc/_screen_loc_to_index(var/base, var/view, var/is_x)
	if(!istext(base))
		return view + 1
	// Try parsing as a plain number first (BYOND may return numeric indices directly)
	var/num = text2num(base)
	if(!isnull(num))
		return num
	if(findtext(base, "CENTER"))
		return view + 1
	if(is_x)
		if(findtext(base, "EAST-"))
			return view * 2 + 1 - (text2num(copytext(base, 6)) || 0)
		if(findtext(base, "WEST+"))
			return (text2num(copytext(base, 6)) || 0) + 1
	else
		if(findtext(base, "NORTH-"))
			return view * 2 + 1 - (text2num(copytext(base, 7)) || 0)
		if(findtext(base, "SOUTH+"))
			return (text2num(copytext(base, 7)) || 0) + 1
	return view + 1