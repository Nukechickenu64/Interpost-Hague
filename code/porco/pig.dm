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
			if(porco_actions_by_tab["They"])
				roleButtonHTML += "<a href=\"#\" class=\"role-button\"><div style=\"background-image: url('Villain.png');\" id=\"They\" class=\"button\"></div></a>"
			if(porco_actions_by_tab["Integralist"])
				roleButtonHTML += "<a href=\"#\" class=\"role-button\"><div style=\"background-image: url('Chrome.png');\" id=\"Integralist\" class=\"button\"></div></a>"
			if(porco_actions_by_tab["Thanati"])
				roleButtonHTML += "<a href=\"#\" class=\"role-button\"><div style=\"background-image: url('Thanati.png');\" id=\"Thanati\" class=\"button\"></div></a>"
		if(H?.religion != LEGAL_RELIGION)
			roleButtonHTML += "<a href=\"#\" class=\"role-button\"><div style=\"background-image: url('Thanati.png');\" id=\"Thanati\" class=\"button\"></div></a>"
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
	client.changebuttoncontent("#options", "<span class='segment1'>" + generateVerbList(list(list("OOC", "OOC"), list("Adminhelp", "Admin Help"), list("ShowAchievements", "Show Achievements"))) + "</span>")
	client.changebuttoncontent("#Emotes", {"<span class='segment1'>[generateVerbList(list(list("slap", "Slap"), list("Nod", "Nod"), list("Hug", "Hug"), list("Bow", "Bow"), list("Scream", "Scream"), list("Whimper", "Whimper"), list("Laugh", "Laugh"), list("Sigh", "Sigh")))]</span>"} + {"<span class='segment2'>[generateVerbList(list(list("Cough", "Cough"), list("Yawn", "Yawn"), list("Wink", "Wink"), list("Grumble", "Grumble"), list("Charge", "Charge"), list("Cry", "Cry"), list("Hem", "Hem"), list("ClearThroat", "Clear Throat"), list("Smile", "Smile")), 2)]</span>"})
	client.changebuttoncontent("#Craft", {"<span class='segment1'>[generateVerbList(list(list("CraftMenu", "Craft Menu")))]</span>"})

	client.changebuttoncontent("#DeadGhost", {"<span class='segment1'>[generateVerbList(list(list("JoinHellDelverSquad", "Fight in Hell"), list("ToggleGhostVision", "Toggle Ghost Vision"), list("ToggleAnonymousChat", "Become Anonymous"), list("ToggleDarkness", "Add Light"), list("BecomeMouse", "Transform into a Mouse"), list("FollowGhost", "Follow"), list("TeleportGhost", "Teleport"), list("ToggleAntagHUD", "Toggle Antag HUD"), list("ToggleMedicHUD", "Toggle Medic HUD"), list("MoveUp", "Move Upwards"), list("MoveDown", "Move Down"), list("ReenterCorpse", "Re-enter Corpse")))]</span>"})
	client.changebuttoncontent("#Dead", {"<span class='segment1'>[generateVerbList(list(list("Succumb", "Succumb")))]</span>"})
	var/list/porco_actions_by_tab = get_porco_antagonist_actions_by_tab(src)
	client.changebuttoncontent("#They", porco_actions_by_tab["They"] ? "<span class='segment1'>[generateVerbList(porco_actions_by_tab["They"], 1, src)]</span>" : "")
	client.changebuttoncontent("#Integralist", porco_actions_by_tab["Integralist"] ? "<span class='segment1'>[generateVerbList(porco_actions_by_tab["Integralist"], 1, src)]</span>" : "")
	client.changebuttoncontent("#Thanati", porco_actions_by_tab["Thanati"] ? "<span class='segment1'>[generateVerbList(porco_actions_by_tab["Thanati"], 1, src)]</span>" : "")


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