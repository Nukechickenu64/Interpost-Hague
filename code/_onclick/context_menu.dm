// Shift+Right-Click tile context menu implementation

// Opens a small, borderless browser window listing all atoms on the turf, allowing the user
// to select which atom to target for right-click interactions. It attempts to appear near the mouse.
/mob/proc/open_tile_context_menu(var/turf/T, var/atom/clicked, var/params)
	if(!client || !T)
		return

	// Extract click params to position the menu near the mouse
	var/list/P = istext(params) ? params2list(params) : null
	var/has_pos = FALSE
	var/pos_x = 0
	var/pos_y = 0
	if(P && P["screen-loc"]) // Preferred: derive pixel position from screen-loc
		var/list/screen_loc_params = splittext(P["screen-loc"], ",")
		if(screen_loc_params && screen_loc_params.len >= 2)
			// X base and pixel
			var/list/x_parts = splittext(screen_loc_params[1], ":")
			var/base_x = (x_parts.len >= 1) ? x_parts[1] : "CENTER"
			var/pix_x = text2num((x_parts.len >= 2) ? x_parts[2] : "0")
			// Y base and pixel
			var/list/y_parts = splittext(screen_loc_params[2], ":")
			var/base_y = (y_parts.len >= 1) ? y_parts[1] : "CENTER"
			var/pix_y = text2num((y_parts.len >= 2) ? y_parts[2] : "0")

			var/view = client.view
			var/tile_x = _decode_screen_axis(base_x, view, 1) // EAST/WEST/CENTER
			var/tile_y = _decode_screen_axis(base_y, view, 0) // NORTH/SOUTH/CENTER
			var/pixel_x = (max(1, tile_x) - 1) * world.icon_size + pix_x
			var/pixel_y = (max(1, tile_y) - 1) * world.icon_size + pix_y

			// Get absolute position of the map control and mainwindow, then place popup
			var/map_pos_text = winget(src, "map", "pos")
			var/win_pos_text = winget(src, "mainwindow", "pos")
			if(map_pos_text && win_pos_text)
				var/list/mp = splittext(map_pos_text, ",")
				var/list/wp = splittext(win_pos_text, ",")
				if(mp.len >= 2 && wp.len >= 2)
					var/map_x = text2num(mp[1])
					var/map_y = text2num(mp[2])
					var/win_x = text2num(wp[1])
					var/win_y = text2num(wp[2])
					pos_x = win_x + map_x + pixel_x + 12 // slight offset from cursor
					pos_y = win_y + map_y + pixel_y + 12
					has_pos = TRUE

	// Fallback: try icon-x/y if screen-loc wasn’t present
	if(!has_pos && P)
		var/ix = text2num(P["icon-x"]) - 1
		var/iy = text2num(P["icon-y"]) - 1
		if(ix >= 0 && iy >= 0)
			var/win_pos_text2 = winget(src, "mainwindow", "pos")
			var/map_pos_text2 = winget(src, "map", "pos")
			if(win_pos_text2 && map_pos_text2)
				var/list/wp2 = splittext(win_pos_text2, ",")
				var/list/mp2 = splittext(map_pos_text2, ",")
				if(wp2.len >= 2 && mp2.len >= 2)
					pos_x = text2num(wp2[1]) + text2num(mp2[1]) + ix + 12
					pos_y = text2num(wp2[2]) + text2num(mp2[2]) + iy + 12
					has_pos = TRUE

	// Build a stable list of visible atoms on the tile: include the turf and its contents
	var/list/atoms_on_tile = list()
	// Include the turf itself at the bottom of the list
	atoms_on_tile += T
	// Include all atoms in turf contents (objects, mobs, items)
	for(var/atom/A in T)
		// Skip admin-only/screen/UI objects that shouldn't be in-world selectable
		if(istype(A, /obj/screen))
			continue
		// Basic visibility filter
		if(A.invisibility && A.invisibility > see_invisible)
			continue
		atoms_on_tile += A

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
	var/html = "<html><head><title>Local Context</title>"
	html += "<style>"
	html += "html,body{background:rgba(14,19,27,0.94);color:#d7f6ff;font-family:Verdana,Arial,Helvetica,sans-serif;font-size:9pt;margin:0;padding:0;}"
	html += ".wrap{padding:8px 10px;min-width:220px;max-width:360px;border:1px solid #3ad;border-radius:6px;box-shadow:0 0 14px rgba(58,173,255,0.25) inset, 0 0 12px rgba(8,18,28,0.6);}"
	html += ".hdr{font-size:10pt;color:#8fe3ff;letter-spacing:0.06em;margin-bottom:6px;text-transform:uppercase;}"
	html += ".accent{height:2px;background:linear-gradient(90deg,#3ad,transparent);margin:6px 0 8px 0;}"
	html += ".note{color:#9fd;opacity:0.85;font-size:8pt;} .loc{color:#8fe3ff;} .item{margin:2px 0;}"
	html += "a{color:#b9ecff;text-decoration:none;} a:hover{text-decoration:underline;}"
	html += "</style>"
	// Auto-fit the browser window to the content once it finishes laying out
	html += "<script type='text/javascript'>function __tilectx_fit(){try{var w=Math.ceil(document.body.scrollWidth);var h=Math.ceil(document.body.scrollHeight);window.location='?src=\\ref[src];tilectx_fit=1;w='+w+';h='+h;}catch(e){}};window.onload=function(){setTimeout(__tilectx_fit,10)};</script>"
	html += "</head><body><div class='wrap'>"
	html += "<div class='hdr'>Local Context</div>"
	html += "<div class='accent'></div>"
	html += "<div class='note'>Select an object to interact.</div>"

	if(!atoms_on_tile.len)
		html += "<div class='item note'>(Nothing here)</div>"
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
				html += "<div class='item'>&#8226; [label]"
			else
				html += "<div class='item'>&#8226; <a href=\"?src=\ref[src];tilectx_invoke=\ref[A];proc=pickup\">[label]</a> <span class='note'>(<a href=\"?src=\ref[src];tilectx_obj=\ref[A]\">...</a>)</span>"
			if(A == clicked)
				html += " <span class='note'>(clicked)</span>"
			html += "</div>"

	// Close row and HTML wrapper (always include)
	html += "<div class='accent'></div><div class='note'><a href=\"?src=\ref[src];mach_close=tilectx\">Close</a></div>"
	html += "</div></body></html>"

	// Open the menu window: borderless, non-resizable, placed near mouse if possible
	var/browse_args = "window=tilectx;border=0;titlebar=0;can_resize=0;can_minimize=0;can_close=1;size=260x[dyn_h]"
	if(has_pos)
		browse_args += ";pos=[pos_x],[pos_y]"
	src << browse(html, browse_args)
	if(has_pos)
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
	if(target:verbs)
		for(var/V in target:verbs)
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
	var/base_h = 150
	var/row_h = 18
	var/min_h = 160
	var/max_h = 800
	var/dyn_h = clamp(base_h + (items_count * row_h), min_h, max_h)

	var/html = "<html><head><title>Object Actions</title>"
	html += "<style>"
	html += "html,body{background:rgba(14,19,27,0.94);color:#d7f6ff;font-family:Verdana,Arial,Helvetica,sans-serif;font-size:9pt;margin:0;padding:0;}"
	html += ".wrap{padding:8px 10px;min-width:240px;max-width:400px;border:1px solid #3ad;border-radius:6px;box-shadow:0 0 14px rgba(58,173,255,0.25) inset, 0 0 12px rgba(8,18,28,0.6);}"
	html += ".hdr{font-size:10pt;color:#8fe3ff;letter-spacing:0.06em;margin-bottom:4px;text-transform:uppercase;}"
	html += ".accent{height:2px;background:linear-gradient(90deg,#3ad,transparent);margin:6px 0 8px 0;}"
	html += ".note{color:#9fd;opacity:0.85;font-size:8pt;} .loc{color:#8fe3ff;} .item{margin:2px 0;}"
	html += "a{color:#b9ecff;text-decoration:none;} a:hover{text-decoration:underline;}"
	html += ".iconwrap{display:flex;align-items:center;gap:8px;margin-bottom:6px;} .iconwrap img{image-rendering:pixelated;border-radius:4px;border:1px solid #3ad;background:#091018;}"
	html += "</style>"
	// Auto-fit this object actions window to its content after render (icons may change height)
	html += "<script type='text/javascript'>function __tilectx_fit(){try{var w=Math.ceil(document.body.scrollWidth);var h=Math.ceil(document.body.scrollHeight);window.location='?src=\\ref[src];tilectx_fit=1;w='+w+';h='+h;}catch(e){}};window.onload=function(){setTimeout(__tilectx_fit,10)};</script>"
	html += "</head><body><div class='wrap'>"
	var/title = sanitizeSafe(target.name, 64, 1, 1, 1)
	html += "<div class='hdr'>[title]</div>"
	if(I)
		html += "<div class='iconwrap'><img src='[rsc_name]' width='[icon_w]' height='[icon_h]'></div>"
	html += "<div class='accent'></div>"

	// Standard actions
	// Links below use inline BYOND ref tokens for the target
	html += "<div class='item'>&#8226; <a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=examine'>Examine</a></div>"
	html += "<div class='item'>&#8226; <a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=use'>Use</a></div>"
	html += "<div class='item'>&#8226; <a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=use_right'>Right-use</a></div>"
	html += "<div class='item'>&#8226; <a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=pull'>Pull</a></div>"

	// Custom verbs
	if(verbs_list.len)
		html += "<div class='accent'></div><div class='note'>Verbs</div>"
		for(var/entry in verbs_list)
			var/label = entry["label"]
			var/procname = entry["proc"]
			html += "<div class='item'>&#8226; <a href='?src=\ref[src];tilectx_invoke=\ref[target];proc=[url_encode(procname)]'>[label]</a></div>"

	// Controls
	html += "<div class='accent'></div><div class='note'><a href=\"?src=\ref[src];tilectx_back=1\">Back</a> | <a href=\"?src=\ref[src];mach_close=tilectx\">Close</a></div>"
	html += "</div></body></html>"

	var/browse_args = "window=tilectx;border=0;titlebar=0;can_resize=0;can_minimize=0;can_close=1;size=300x[dyn_h]"
	src.tilectx_last_clicked = target
	src << browse(html, browse_args)
	src.tilectx_open = TRUE

// Handle selection in mob/Topic (implemented there) to dispatch right-click action.

// Helper: decode EAST/WEST/CENTER or NORTH/SOUTH/CENTER to a tile index on the screen grid
/mob/proc/_decode_screen_axis(var/base, var/view, var/is_x)
	if(!istext(base))
		return view+1
	if(findtext(base, is_x ? "EAST-" : "NORTH-"))
		var/num = text2num(copytext(base, 6))
		if(!num) num = 0
		return view*2 + 1 - num
	else if(findtext(base, is_x ? "WEST+" : "SOUTH+"))
		var/num2 = text2num(copytext(base, 6))
		if(!num2) num2 = 0
		return num2 + 1
	else if(findtext(base, "CENTER"))
		return view + 1
	return view + 1
