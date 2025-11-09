/mob/living/deity
	name = "shapeless creature"
	desc = "A shape of otherworldly matter, not yet ready to be unleashed into this world."
	icon = 'icons/mob/deity_big.dmi'
	icon_state = "egg"
	var/power_min = 10 //Below this amount you regenerate uplink TCs
	pixel_x = -128
	pixel_y = -128
	health = 100
	maxHealth = 100 //I dunno what to do with health at this point.
	universal_understand = 1
	var/eye_type = /mob/observer/eye/cult
	var/list/minions = list() //Minds of those who follow him
	var/list/structures = list() //The objs that this dude controls.
	var/list/feats = list() //These are the deities 'skills' that they unlocked. Which can unlock abilities, new categories, etc. What this list actually IS is the names of the feats and whatever data they need,
	var/obj/item/device/uplink/contained/mob_uplink
	var/datum/god_form/form
	var/datum/current_boon
	var/mob/living/following

/mob/living/deity/New()
	..()
	if(eye_type)
		eyeobj = new eye_type(src)
		eyeobj.possess(src)
		eyeobj.visualnet.add_source(src)
	mob_uplink = new(src, telecrystals = 0)

/mob/living/deity/Life()
	. = ..()
	if(. && mob_uplink.uses < power_min)
		mob_uplink.uses += 1 + (!feats[DEITY_POWER_BONUS] ? 0 : feats[DEITY_POWER_BONUS])
		SSnano.update_uis(mob_uplink)

/mob/living/deity/death()
	. = ..()
	if(.)
		for(var/m in minions)
			var/datum/mind/M = m
			remove_follower_spells(M)
			to_chat(M.current, "<font size='3'><span class='danger'>Your connection has been severed! \The [src] is no more!</span></font>")
			sound_to(M.current, 'sound/hallucinations/far_noise.ogg')
			M.current.Weaken(10)
		for(var/s in structures)
			var/obj/structure/deity/S = s
			S.linked_god = null

/mob/living/deity/Destroy()
	death(0)
	minions.Cut()
	eyeobj.release()
	structures.Cut()
	QDEL_NULL(eyeobj)
	QDEL_NULL(form)
	return ..()

/mob/living/deity/verb/return_to_plane()
	set category = "Godhood"

	eyeobj.forceMove(get_turf(src))

/mob/living/deity/verb/open_menu()
	set name = "Open Menu"
	set category = "Godhood"

	if(!form)
		to_chat(src, "<span class='warning'>Choose a form first!</span>")
		return
	if(!src.mob_uplink.uplink_owner)
		src.mob_uplink.uplink_owner = src.mind
	mob_uplink.update_nano_data()
	src.mob_uplink.trigger(src)

/mob/living/deity/verb/choose_form()
	set name = "Choose Form"
	set category = "Godhood"
	// Build a styled HTML window that looks like a divine tablet
	var/list/html = list()
	var/header = ""
	header += "<html><head>"
	header += "<meta http-equiv='X-UA-Compatible' content='IE=edge' />"
	header += "<meta charset='utf-8' />"
	header += "<style>"
	header += "body { margin:0; padding:0; background:#0b0a0f; color:#e6e0d0; font-family: Segoe UI, Tahoma, Arial, sans-serif; }"
	header += ".tablet { max-width: 760px; margin: 12px auto; padding: 16px 18px; background: radial-gradient(ellipse at top, #1b171f 0%, #0c0a0e 70%) no-repeat; border: 2px solid #3a2b40; border-radius: 14px; box-shadow: 0 0 16px rgba(170, 120, 255, 0.35), inset 0 0 12px rgba(170, 120, 255, 0.15); }"
	header += ".tablet h1 { font-size: 22px; margin: 0 0 4px 0; text-align:center; letter-spacing: 1px; }"
	header += ".tablet .subtitle { display:block; text-align:center; color:#cbbfd9; margin-bottom: 10px; font-size: 12px; }"
	header += "table { width:100%; border-collapse: collapse; }"
	header += "th, td { padding: 8px 10px; vertical-align: middle; }"
	header += "th { background: #251f29; color:#e6e0d0; border-bottom: 1px solid #3a2b40; text-align:left; }"
	header += "tr:nth-child(even) { background: rgba(255,255,255,0.03); }"
	header += "tr:hover { background: rgba(170,120,255,0.10); }"
	header += ".name a { color:#d7b6ff; text-decoration:none; font-weight:600; }"
	header += ".name a:hover { text-decoration:underline; }"
	header += ".icon { text-align:center; }"
	header += ".desc { color:#d9d3c6; }"
	header += ".footer { text-align:center; color:#b7a9c7; margin-top:10px; font-size:11px; }"
	header += "img { image-rendering: pixelated; }"
	header += "</style>"
	header += "</head><body><div class='tablet'>"
	header += "<h1>Choose a Form</h1>"
	header += "<span class='subtitle'>This choice is permanent. Choose carefully, but quickly.</span>"
	header += "<table>"
	header += "<tr><th style='width:30%'>Name</th><th style='width:20%'>Theme</th><th style='width:50%'>Description</th></tr>"

	html += header

	var/list/forms = subtypesof(/datum/god_form)
	for(var/T in forms)
		var/datum/god_form/G = T
		var/god_name_raw = initial(G.name)
		var/god_name = escape_html(god_name_raw)
		var/god_info = escape_html(initial(G.info))

		// Prepare icon resource with name-based handle
		var/icon/god_icon = icon('icons/mob/mob.dmi', initial(G.pylon_icon_state))
		send_rsc(src, god_icon, "[god_name_raw].png")

		html += "<tr><td class='name'><a href='?src=\ref[src];form=[G]'>[god_name]</a></td><td class='icon'><img src='[god_name_raw].png'></td><td class='desc'>[god_info]</td></tr>"

	html += "</table><div class='footer'>Tap a name to embody its essence.</div></div></body></html>"

	var/dat = jointext(html, "")
	show_browser(src, dat, "window=godform;title=Divine Tablet;size=780x560;can_close=0;noresize=1")

/mob/living/deity/proc/escape_html(var/text)
	if(isnull(text))
		return ""
	var/t = "[text]"
	// Replace ampersand first to avoid double-encoding
	t = replacetext(t, "&", "&amp;")
	t = replacetext(t, "<", "&lt;")
	t = replacetext(t, ">", "&gt;")
	t = replacetext(t, "\"", "&quot;")
	t = replacetext(t, "'", "&#39;")
	return t

/mob/living/deity/proc/set_form(var/type)
	form = new type(src)
	to_chat(src, "<span class='notice'>You undergo a transformation into your new form!</span>")
	spawn(1)
		SetName(form.name)
		var/newname = sanitize(input(src, "Choose a name for your new form.", "Name change", form.name) as text, MAX_NAME_LEN)
		if(newname)
			fully_replace_character_name(newname)
	src.verbs -= /mob/living/deity/verb/choose_form
	show_browser(src, null, "window=godform")
	for(var/m in minions)
		var/datum/mind/mind = m
		var/mob/living/L = mind.current
		L.faction = form.faction

//Gets the name based on form, or if there is no form name, type.
/mob/living/deity/proc/get_type_name(var/type)
	if(form && form.buildables[type])
		var/list/vars = form.buildables[type]
		if(vars["name"])
			return vars["name"]
	var/atom/movable/M = type
	return initial(M.name)