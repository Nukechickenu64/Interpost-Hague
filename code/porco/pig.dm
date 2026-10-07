/client/proc/loadDataPig()
	var/datum/asset/stuff = get_asset_datum(/datum/asset/pig)
	stuff.register()
	stuff.send(src)

/client/verb/ready()
	set hidden = 1
	set name = "doneRsc"

	pigReady = 1
	if(mob)
		mob.updatePig()
		mob.startPig()

/client/verb/unready()
	set hidden = 1
	set name = "notdoneRsc"

	pigReady = 0

// Manual fallback for when the pig UI fails to load/render on its own.
/client/verb/ReloadPig()
	set hidden = 1
	set name = "ReloadPig"

	pigReady = 0
	loadDataPig()
	lobbyPig()

/proc/generateVerbHtml(var/verbname = "", var/displayname = "", var/number = 1, var/mob/user)
	var/command_href = user ? "?src=\ref[user];porco_action=[url_encode(verbname)]" : "byond://winset?command=[url_encode(verbname)]"
	if(number % 2)
		return {"<a href='[command_href]' class='verb dim'>[displayname]</a>"}
	else
		return {"<a href='[command_href]' class='verb'>[displayname]</a>"}

/proc/generateVerbList(var/list/verbs = list(), var/count = 1, var/mob/user)
	var/html = ""
	var/counter = count
	for(var/list/L in verbs)
		counter++
		html += generateVerbHtml(L[1], L[2], counter, user) + "$"
	return html

/client/proc/newtext(var/newcontent = "")
	src << output(list2params(list("[newcontent]")), "outputwindow.browser:InputMsg")

/client/proc/changebuttoncontent(var/idcontent = "", var/newcontent = "")
	src << output(list2params(list("[newcontent]", "[idcontent]")), "outputwindow.browser:changel")

/client/proc/addbutton(var/newcontent = "", var/selector = "")
	src << output(list2params(list("[newcontent]", "[selector]")), "outputwindow.browser:addel")

// The System Shock renderer lives in the existing map pane, so neither HUD pane
// has to be moved or rebuilt when a player changes view mode.
/client
	// Kept behind a feature flag while the renderer is being iterated on.
	var/shock3d_feature_enabled = FALSE
	var/shock3d_active = FALSE
	var/shock3d_refresh_active = FALSE
	// Resources are generated lazily and stay in the player's BYOND resource
	// cache. This keeps the recurring scene payload small while allowing the
	// browser to use the actual appearance of turf, object, and mob icons.
	var/list/shock3d_resource_cache = list()

/client/verb/toggle_shock3d()
	set name = "SystemShock3D"
	set category = "OOC"
	set hidden = TRUE

	if(!shock3d_feature_enabled)
		to_chat(src, "<span class='notice'>System Shock 3D is temporarily disabled.</span>")
		return

	shock3d_active = !shock3d_active
	if(shock3d_active)
		// Layer the browser over the ordinary map. Hiding the map control would
		// remove mapwindow from the split pane through its on-hide handler.
		winset(src, "mapwindow.shock3d", "is-visible=true;is-disabled=false;focus=true")
		// The browser has a center-only skin rectangle. Do not set a browse size
		// here: doing so would expand over the native HUD screen objects.
		src << browse('code/porco/html/shock3d.html', "window=mapwindow.shock3d")
		start_shock3d_refresh()
		to_chat(src, "<span class='notice'>System Shock 3D view enabled. It now accepts movement, combat, item, and mouse interaction controls.</span>")
	else
		winset(src, "mapwindow.shock3d", "is-visible=false;is-disabled=true")
		winset(src, "mapwindow.map", "focus=true")
		to_chat(src, "<span class='notice'>System Shock 3D view disabled.</span>")

/client/verb/shock3d_ready()
	set name = "Shock3DReady"
	set hidden = TRUE

	if(shock3d_active)
		update_shock3d()

/client/verb/shock3d_move(move_mode as text)
	set name = "Shock3DMove"
	set hidden = TRUE

	if(!shock3d_active || !mob)
		return

	var/move_direction
	switch(lowertext(move_mode))
		if("forward")
			move_direction = mob.dir
		if("backward")
			move_direction = turn(mob.dir, 180)
		if("left")
			move_direction = turn(mob.dir, -90)
		if("right")
			move_direction = turn(mob.dir, 90)
		else
			return
	Move(get_step(mob, move_direction), move_direction)

/client/verb/shock3d_turn(turn_direction as text)
	set name = "Shock3DTurn"
	set hidden = TRUE

	if(!shock3d_active || !mob)
		return

	var/turn_amount
	switch(lowertext(turn_direction))
		if("left")
			turn_amount = -45
		if("right")
			turn_amount = 45
		else
			return
	mob.facedir(turn(mob.dir, turn_amount))

/client/verb/shock3d_click(delta_x as num, delta_y as num, action as text)
	set name = "Shock3DClick"
	set hidden = TRUE

	if(!shock3d_active || !mob)
		return

	var/scene_radius = 7
	delta_x = round(delta_x)
	delta_y = round(delta_y)
	if(abs(delta_x) > scene_radius || abs(delta_y) > scene_radius)
		return

	var/turf/origin = get_turf(mob)
	var/turf/clicked_turf = origin ? locate(origin.x + delta_x, origin.y + delta_y, origin.z) : null
	if(!clicked_turf || !(clicked_turf in view(scene_radius, mob)))
		return

	// A projected tile has no pixel-accurate sprite position, so choose the
	// top-most clickable visible movable, matching the map's usual behaviour.
	var/atom/clicked = clicked_turf
	var/top_layer = clicked_turf.layer
	for(var/atom/movable/A in clicked_turf)
		if(A == mob || !A.mouse_opacity || A.invisibility > mob.see_invisible)
			continue
		if(A.layer >= top_layer)
			clicked = A
			top_layer = A.layer

	var/click_params = ""
	switch(lowertext(action))
		if("examine")
			click_params = "shift=1"
		if("pull")
			click_params = "ctrl=1"
		if("context")
			click_params = "right=1;shift=1"
		if("alternate")
			click_params = "right=1"
		if("middle")
			click_params = "middle=1"
		if("primary")
			click_params = ""
		else
			return

	mob.ClickOn(clicked, click_params, mob, src)

/client/verb/shock3d_hotkey(hotkey as text)
	set name = "Shock3DHotkey"
	set hidden = TRUE

	if(!shock3d_active || !mob)
		return

	switch(lowertext(hotkey))
		if("use")
			attack_self()
		if("swap")
			swap_hand()
		if("drop")
			drop_item()
		if("throw")
			toggle_throw_mode()
		if("cancel_pull")
			mob.stop_pulling()
		if("wield")
			if(isliving(mob))
				var/mob/living/L = mob
				L.do_wield()
		if("combat")
			if(ishuman(mob))
				var/mob/living/carbon/human/H = mob
				H.toggle_combat_mode()
		if("defense")
			if(ishuman(mob))
				var/mob/living/carbon/human/H = mob
				H.toggle_dodge_parry()
		if("rest")
			mob.mob_rest()
		if("intent_help")
			mob.a_intent_change(I_HELP)
		if("intent_disarm")
			mob.a_intent_change(I_DISARM)
		if("intent_grab")
			mob.a_intent_change(I_GRAB)
		if("intent_harm")
			mob.a_intent_change(I_HURT)

/client/proc/start_shock3d_refresh()
	if(shock3d_refresh_active)
		return

	shock3d_refresh_active = TRUE
	spawn
		while(src && shock3d_active)
			update_shock3d()
			// A live view should feel responsive, but this avoids pushing a browser
			// payload every tick while a player has the normal map open.
			sleep(4)
		shock3d_refresh_active = FALSE

/client/proc/shock3d_icon_resource(var/atom/A)
	if(!A || !A.icon)
		return ""

	// A flattened icon preserves colors, overlays, and the atom's current
	// direction. Include the relevant appearance inputs in the cache key, so
	// wardrobe/state changes receive a new browser resource when necessary.
	var/cache_key = "[A.type]|[A.icon]|[A.icon_state]|[A.dir]|[A.color]|[A.alpha]|[A.pixel_x]|[A.pixel_y]"
	if(A.underlays)
		for(var/underlay in A.underlays)
			cache_key += "|u:[underlay]"
	if(A.overlays)
		for(var/overlay in A.overlays)
			cache_key += "|o:[overlay]"

	var/rsc_name = shock3d_resource_cache[cache_key]
	if(rsc_name)
		return rsc_name

	var/icon/flat_icon = getFlatIcon(A)
	if(!flat_icon)
		return ""

	rsc_name = "shock3d_[copytext(md5(cache_key), 1, 17)].png"
	src << browse_rsc(flat_icon, rsc_name)
	shock3d_resource_cache[cache_key] = rsc_name
	return rsc_name

/client/proc/shock3d_turf_lighting(var/turf/T)
	if(!T)
		return list(0, 0, 0)
	if(!T.dynamic_lighting)
		return list(1, 1, 1)

	// The native lighting system already resolves its light sources into the
	// four corners of each turf. Reuse those final RGB values instead of making
	// a second, mismatched lighting simulation for the 3D pane.
	var/red = 0
	var/green = 0
	var/blue = 0
	var/corner_count = 0
	if(T.corners)
		for(var/datum/lighting_corner/C in T.corners)
			if(!C)
				continue
			if(C.cache_r)
				red += C.cache_r
			if(C.cache_g)
				green += C.cache_g
			if(C.cache_b)
				blue += C.cache_b
			corner_count++
	if(!corner_count)
		return list(0.06, 0.07, 0.08)
	return list(
		min(1, max(0, red / corner_count)),
		min(1, max(0, green / corner_count)),
		min(1, max(0, blue / corner_count))
	)

/client/proc/update_shock3d()
	if(!shock3d_active || !mob)
		return

	var/turf/origin = get_turf(mob)
	if(!origin)
		return

	// view() is deliberately used as the source of the scene. The 3D pane never
	// receives turfs behind opaque walls or beyond the player's visible range.
	var/scene_radius = 7
	var/list/visible_atoms = view(scene_radius, mob)
	var/list/visible_turfs = list()
	for(var/turf/T in visible_atoms)
		visible_turfs[T] = TRUE

	var/list/cells = list()
	var/list/textures = list()
	var/list/lighting = list()
	var/list/holes = list()
	var/list/below_textures = list()
	var/list/below_lighting = list()
	for(var/y = origin.y + scene_radius, y >= origin.y - scene_radius, y--)
		var/row = ""
		var/list/texture_row = list()
		var/list/lighting_row = list()
		var/hole_row = ""
		var/list/below_texture_row = list()
		var/list/below_lighting_row = list()
		for(var/x = origin.x - scene_radius, x <= origin.x + scene_radius, x++)
			var/turf/T = locate(x, y, origin.z)
			var/obj/machinery/door/closed_door = null
			if(T && visible_turfs[T])
				for(var/obj/machinery/door/D in T)
					if(D.density && D.invisibility <= mob.see_invisible)
						closed_door = D
						break
			var/is_wall = !T || !visible_turfs[T] || T.density || closed_door
			var/texture = ""
			row += is_wall ? "1" : "0"
			// Never send an appearance for a turf the normal map has hidden.
			if(closed_door)
				// A closed door is its own view-facing wall surface. This prevents the
				// renderer from treating it as a free-standing voxel with the wrong
				// facing and gives it the same collision silhouette as the game map.
				texture = shock3d_icon_resource(closed_door)
			else if(T && visible_turfs[T])
				texture = shock3d_icon_resource(T)
			texture_row += texture
			var/list/tile_lighting = list(0, 0, 0)
			if(T && visible_turfs[T])
				tile_lighting = shock3d_turf_lighting(T)
			lighting_row += list(tile_lighting)

			// An open turf has no floor on this deck. Render the turf one z-level
			// below through that opening, except when stairs occupy it: stairs are
			// solid traversal geometry rather than a shaft the player can see through.
			var/turf/below_turf = null
			if(T && visible_turfs[T] && T.is_open() && !(locate(/obj/structure/stairs) in T))
				below_turf = GetBelow(T)
			hole_row += below_turf ? "1" : "0"
			var/below_texture = ""
			var/list/below_tile_lighting = list(0, 0, 0)
			if(below_turf)
				below_texture = shock3d_icon_resource(below_turf)
				below_tile_lighting = shock3d_turf_lighting(below_turf)
			below_texture_row += below_texture
			below_lighting_row += list(below_tile_lighting)
		cells += row
		textures += list(texture_row)
		lighting += list(lighting_row)
		holes += hole_row
		below_textures += list(below_texture_row)
		below_lighting += list(below_lighting_row)

	var/list/entities = list()
	for(var/atom/movable/A in visible_atoms)
		if(A == mob || !isturf(A.loc) || A.invisibility > mob.see_invisible)
			continue
		// Every visible game object gets a model. Pure /obj/effect overlays are
		// deliberately excluded: they are particles/decals rather than geometry.
		if(!ismob(A) && (!isobj(A) || istype(A, /obj/effect)))
			continue
		if(istype(A, /obj/machinery/door))
			var/obj/machinery/door/entity_door = A
			if(entity_door.density)
				continue
		entities += list(list(
			"x" = A.x - origin.x + scene_radius + 0.5,
			"y" = scene_radius - (A.y - origin.y) + 0.5,
			"kind" = ismob(A) ? "mob" : "object",
			// The renderer classifies object geometry from these real game fields.
			// This makes an object's semantic model track its name, description and
			// concrete type rather than treating every icon as the same flat sprite.
			"name" = A.name,
			"description" = A.desc,
			"type" = "[A.type]",
			"model" = istype(A, /obj/structure/stairs) ? "stairs" : (istype(A, /obj/machinery/door) ? "door" : ""),
			"dir" = A.dir,
			"sprite" = shock3d_icon_resource(A)
		))

	var/list/scene = list(
		"radius" = scene_radius,
		"cells" = cells,
		"textures" = textures,
		"lighting" = lighting,
		"holes" = holes,
		"belowTextures" = below_textures,
		"belowLighting" = below_lighting,
		"dir" = mob.dir,
		"entities" = entities
	)
	src << output(list2params(list(json_encode(scene))), "mapwindow.shock3d:setScene")

/mob
	var/pig_refresh_active = FALSE

/mob/proc/updatePig()
	set waitfor = 0
	if(!client)
		return
	if(!client.pigReady)
		return

	var/buttonHTML = ""
	var/roleButtonHTML = ""

	// Main heart/menu button
	buttonHTML += {"<a href=\"#\" style=\"display:inline-block;width:32px;height:32px;position:absolute;margin-right:1px;\"><div style=\"background-image: url('Heart.png'); width:32px;height:32px;background-size:cover;display:block;position:relative;top:-132px;\" id=\"Verb\" class=\"button\"></div></a>"}

	// Dead/ghost controls
	if((src.stat == DEAD && GAME_STATE != RUNLEVEL_LOBBY) || isobserver(src) || istype(src, /mob/living/carbon/brain))
		buttonHTML += "<a href=\"#\" style=\"display:inline-block;width:32px;height:32px;position:absolute;margin-left:45px;\"><div style=\"background-image: url('Dead.png'); width:32px;height:32px;background-size:cover;display:block;position:relative;top:-175px;\" id=\"DeadGhost\" class=\"button\"></div></a>"

	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		buttonHTML += "<a href=\"#\" style=\"display:inline-block;width:32px;height:32px;position:absolute;margin-left:45px;\"><div style=\"background-image: url('Emotes.png'); width:32px;height:32px;background-size:cover;display:block;position:relative;top:-132px;\" id=\"Emotes\" class=\"button\"></div></a>"
		buttonHTML += "<a href=\"#\" style=\"display:inline-block;width:32px;height:32px;position:absolute;margin-left:45px;\"><div style=\"background-image: url('Craft.png'); width:32px;height:32px;background-size:cover;display:block;position:relative;top:-87px;\" id=\"Craft\" class=\"button\"></div></a>"

/*
		if(H.isVampire)
			buttonTimes++;
			buttonHTML += "<a href=\"#\"><div style=\"background-image: url(\'Fangs.png\'); margin-top: -50px; margin-left:[pixelDistancing * buttonTimes]px; \" id=\"Vampire\" class=\"button\" /></div></a>"
*/
/*
		if(H.job == "Francisco's Advisor")
			buttonTimes++;
			buttonHTML += "<a href=\"#\"><div style=\"background-image: url(\'Plot.png\'); margin-top: -50px; margin-left:[pixelDistancing * buttonTimes]px; \" id=\"Advisor\" class=\"button\" /></div></a>"
		if(H.job == "Francisco's Bodyguard")
			buttonTimes++;
			buttonHTML += "<a href=\"#\"><div style=\"background-image: url(\'Plot.png\'); margin-top: -50px; margin-left:[pixelDistancing * buttonTimes]px; \" id=\"Bodyguard\" class=\"button\" /></div></a>"
*/
		if(H?.mind)
			var/list/porco_actions_by_tab = get_porco_antagonist_actions_by_tab(H)
			var/tab_index = 0
			for(var/tab_name in porco_actions_by_tab)
				var/list/tab_actions = porco_actions_by_tab[tab_name]
				var/tab_id = tab_name
				var/tab_icon = "Villain.png"
				switch(tab_name)
					if("Integralist")
						tab_icon = "Chrome.png"
					if("Thanati")
						tab_icon = "Thanati.png"
					if("They", "Xenophage")
						tab_icon = "Villain.png"
					else
						tab_id = "PorcoTab[tab_index]"
				tab_index++
				if(!tab_actions.len)
					continue
				roleButtonHTML += "<a href=\"#\" class=\"role-button\" title=\"[tab_name]\"><div style=\"background-image: url('[tab_icon]');\" id=\"[tab_id]\" class=\"button\"></div></a>"
		if(/mob/living/proc/praise_god in H.verbs)
			roleButtonHTML += "<a href=\"#\" class=\"role-button\" title=\"Religion\"><div style=\"background-image: url('Thanati.png');\" id=\"Religion\" class=\"button\"></div></a>"
		if(H.stat == DEAD)
			buttonHTML += "<a href=\"#\" style=\"display:inline-block;width:32px;height:32px;position:absolute;margin-left:46px;\"><div style=\"background-image: url('Dead.png'); width:32px;height:32px;background-size:cover;display:block;position:relative;top:-88px;\" id=\"Dead\" class=\"button\"></div></a>"

	client.addbutton(buttonHTML, "#dynamicpanel")
	client.addbutton(roleButtonHTML, "#dynamicpanel2")
	updateButtons()

/mob/proc/updateButtons()
	set waitfor = 0
	if(!client)
		return
	if(!client.pigReady)
		return

	var/noteHTML = ""
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		noteHTML += "<span style='white-space: nowrap' class='segment1 ST'>ST: <span id='st'>[H.stats[STAT_ST]]</span>$HT: <span id='ht'>[H.stats[STAT_HT]]</span>$IN: <span id='int'>[H.stats[STAT_IQ]]</span>$DX: <span id='dx'>[H.stats[STAT_DX]]</span></span>"
	client.changebuttoncontent("#note", noteHTML)
	client.changebuttoncontent("#Verb", verbUpdate())
	var/list/ooc_options = list(list("OOC", "OOC"), list("Adminhelp", "Admin Help"), list("ShowAchievements", "Show Achievements"))
	if(isliving(src))
		var/mob/living/shop_user = src
		if(shop_user.meta_shop_access())
			ooc_options += list(list("Leverage-Exchange", "Leverage Exchange"))
	client.changebuttoncontent("#options", "<span class='segment1'>" + generateVerbList(ooc_options) + "</span>")
	client.changebuttoncontent("#Emotes", {"<span class='segment1'>[generateVerbList(list(list("slap", "Slap"), list("Nod", "Nod"), list("Hug", "Hug"), list("Bow", "Bow"), list("Scream", "Scream"), list("Whimper", "Whimper"), list("Laugh", "Laugh"), list("Sigh", "Sigh")))]</span>"} + {"<span class='segment2'>[generateVerbList(list(list("Cough", "Cough"), list("Yawn", "Yawn"), list("Wink", "Wink"), list("Grumble", "Grumble"), list("Charge", "Charge"), list("Cry", "Cry"), list("Hem", "Hem"), list("ClearThroat", "Clear Throat"), list("Smile", "Smile")), 2)]</span>"})
	client.changebuttoncontent("#Craft", {"<span class='segment1'>[generateVerbList(list(list("CraftMenu", "Craft Menu")))]</span>"})

	client.changebuttoncontent("#DeadGhost", {"<span class='segment1'>[generateVerbList(list(list("JoinHellDelverSquad", "Fight in Hell"), list("ToggleGhostVision", "Toggle Ghost Vision"), list("ToggleAnonymousChat", "Become Anonymous"), list("ToggleDarkness", "Add Light"), list("BecomeMouse", "Transform into a Mouse"), list("FollowGhost", "Follow"), list("TeleportGhost", "Teleport"), list("ToggleAntagHUD", "Toggle Antag HUD"), list("ToggleMedicHUD", "Toggle Medic HUD"), list("MoveUp", "Move Upwards"), list("MoveDown", "Move Down"), list("ReenterCorpse", "Re-enter Corpse")))]</span>"})
	client.changebuttoncontent("#Dead", {"<span class='segment1'>[generateVerbList(list(list("Succumb", "Succumb")))]</span>"})
	var/list/porco_actions_by_tab = get_porco_antagonist_actions_by_tab(src)
	var/tab_index = 0
	for(var/tab_name in porco_actions_by_tab)
		var/list/tab_actions = porco_actions_by_tab[tab_name]
		var/tab_id = tab_name
		if(!(tab_name in list("They", "Integralist", "Thanati", "Xenophage")))
			tab_id = "PorcoTab[tab_index]"
		tab_index++
		if(!tab_actions.len)
			continue
		client.changebuttoncontent("#[tab_id]", "<span class='segment1'>[generateVerbList(tab_actions, 1, src)]</span>")
	var/list/religion_actions = list()
	if(ishuman(src))
		var/mob/living/carbon/human/religion_user = src
		if(/mob/living/proc/praise_god in religion_user.verbs)
			if(/mob/living/proc/praise_god in religion_user.verbs)
				religion_actions += list(list("PraiseyourGod", "Praise Your God"))
			if(/mob/living/proc/make_shrine in religion_user.verbs)
				religion_actions += list(list("CreateShrine", "Create Shrine"))
	client.changebuttoncontent("#Religion", religion_actions.len ? "<span class='segment1'>[generateVerbList(religion_actions)]</span>" : "")


/mob/proc/verbUpdate()
	var/newHTML = ""
	if(istype(src, /mob/new_player))
		var/lobby = ""
		if(GAME_STATE <= RUNLEVEL_LOBBY)
			lobby += "Time to Start: <span style='color:#0e3b0e' id='timetostart'>[SSticker ? round(SSticker.pregame_timeleft/10) : 0]</span>$"
			for(var/mob/new_player/P in GLOB.player_list)
				if(!P.client || !P.client.prefs)
					continue
				var/gendercheck = (P.client.prefs.gender != MALE) ? "FEMALE" : "MALE"
				var/readycheck = P.ready ? "READY" : "NOT READY"
				lobby += "<b>[P.client.ckey]</b> ([P.client.prefs.age] [gendercheck]) <b>[readycheck]</b>$"
			newHTML += {"<span style='color:#0e3b0e; font-weight:bold;'>[lobby]</span>"}
	if(ishuman(src))
		newHTML += {"<span class='segment1'>[generateVerbList(list(list("DisguiseVoice", "Disguise Voice"), list("Dance", "Dance"), list("Pee", "Pee"), list("LookUp", "Look Up"), list("MoveUp", "Move Upwards"), list("ShowGoals", "Show Goals")))]</span>"} + {"<span class='segment2'>[generateVerbList(list(list("Notes", "Memories"), list("AddNote", "Add Memories"), list("Pray", "Pray"), list("Poo", "Poo"), list("LookDown", "Look Down"), list("MoveDown", "Move Down")), 2)]</span>"}
	return newHTML

/client/proc/lobbyPig()
	src << browse('code/porco/html/pig.html', "window=outputwindow.browser; size=541x315;")

/client/proc/init_pig()
	loadDataPig()
	// Give assets time to arrive before opening the browser, with bounded retries.
	spawn(30)
		var/attempt = 0
		while(src && !pigReady && attempt < 3)
			lobbyPig()
			attempt++
			if(pigReady)
				break
			sleep(50)

	if(!holder)
		return
	winset(src, "outputwindow.csay", "is-visible=true")

/mob/new_player/say(message)
	if(!client)
		return

	client.ooc(message)

/mob/verb/soundbutton()
	set hidden = 1
	set name = "button"

	client << 'sound/uibutton.ogg'

/mob/verb/heartporcao()
	set hidden = 1
	set name = "heartpig"

	soundbutton()

// Quick command to open the wizard spellbook UI if carried
/mob/verb/OpenSpellbook()
	set hidden = 1
	set name = "OpenSpellbook"

	if(!ishuman(src))
		return
	var/mob/living/carbon/human/H = src
	var/obj/item/weapon/spellbook/B = null
	// Prefer held item, otherwise any in contents
	if(istype(H.l_hand, /obj/item/weapon/spellbook))
		B = H.l_hand
	else if(istype(H.r_hand, /obj/item/weapon/spellbook))
		B = H.r_hand
	else
		for(var/obj/item/weapon/spellbook/SB in H.contents)
			B = SB
			break
	if(B)
		B.interact(H)
	else
		to_chat(H, "<span class='warning'>You don't have your spellbook on you.</span>")

/mob/proc/updateStatPig()
	if(!client)
		return
	if(!client.pigReady)
		return

	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		// change() uses getElementById(), which needs the bare id, not a CSS selector
		client << output(list2params(list("st", "[H.stats[STAT_ST]]")), "outputwindow.browser:change")
		client << output(list2params(list("ht", "[H.stats[STAT_HT]]")), "outputwindow.browser:change")
		client << output(list2params(list("int", "[H.stats[STAT_IQ]]")), "outputwindow.browser:change")
		client << output(list2params(list("dx", "[H.stats[STAT_DX]]")), "outputwindow.browser:change")

/*
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		client << output(list2params(list("#pr", "[H.my_stats.pr]")), "outputwindow.browser:change")
		client << output(list2params(list("#timepusher", "[src?:mind?.time_to_pay]")), "outputwindow.browser:change")
		client << output(list2params(list("#im", "[H.my_stats.im]")), "outputwindow.browser:change")
		client << output(list2params(list("#wp", "[H.my_stats.wp]")), "outputwindow.browser:change")
*/

/mob/proc/pigHandler()
	updatePig()
	updateLobbyTimer()
	if(!ishuman(src))
		return

	var/mob/living/carbon/human/H = src
	H.updateStatPig()

// changel() only re-arms the popup's onclick with fresh HTML, it won't refresh an already-open popup, so push the countdown span directly
/mob/proc/updateLobbyTimer()
	if(!client)
		return
	if(!client.pigReady)
		return
	if(GAME_STATE > RUNLEVEL_LOBBY)
		return

	client << output(list2params(list("timetostart", "[SSticker ? round(SSticker.pregame_timeleft/10) : 0]")), "outputwindow.browser:change")

/mob/proc/startPig()
	if(pig_refresh_active)
		return

	pig_refresh_active = TRUE
	spawn
		while(src && client && !QDELETED(src))
			sleep(85)
			if(!client || !client.pigReady || QDELETED(src))
				break
			pigHandler()
		pig_refresh_active = FALSE

/mob/living/carbon/human/Login()
	..()
	heartporcao()
	updatePig()
	startPig()
