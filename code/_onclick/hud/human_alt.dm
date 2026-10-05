/mob/living/carbon/human
	hud_type = /datum/hud/human

/datum/hud/human/FinalizeInstantiation(var/ui_style='icons/mob/screen/os13.dmi', var/ui_color = "#ffffff", var/ui_alpha = 255)
	var/mob/living/carbon/human/target = mymob
	if(mymob.client)
		mymob.client.screen -= list(mymob.oxygen, mymob.toxin, mymob.fire, mymob.pressure)
	if(mymob.oxygen)
		qdel(mymob.oxygen)
		mymob.oxygen = null
	if(mymob.toxin)
		qdel(mymob.toxin)
		mymob.toxin = null
	if(mymob.fire)
		qdel(mymob.fire)
		mymob.fire = null
	if(mymob.pressure)
		qdel(mymob.pressure)
		mymob.pressure = null
	var/datum/hud_data/hud_data
	if(!istype(target))
		hud_data = new()
	else
		hud_data = target.species.hud

	if(hud_data.icon)
		ui_style = 'icons/mob/screen/os13.dmi'
	else
		ui_style = 'icons/mob/screen/os13.dmi'

	src.adding = list()
	src.other = list()
	src.hotkeybuttons = list() //These can be disabled for hotkey usersx
	mymob.using_alt_hud = 1

	var/list/hud_elements = list()
	var/obj/screen/using
	var/obj/screen/inventory/inv_box

	// The side panel is only drawn for mobs whose UI actually uses it (inventory slots).
	if(length(hud_data.gear))
		using = new /obj/screen() //Upper bar
		using.dir = NORTH
		using.icon = 'icons/mob/screen/backgrounds.dmi'
		using.icon_state = "1"
		using.screen_loc = "WEST-3:12,SOUTH"
		using.layer = UNDER_HUD_LAYER
		adding += using

	// Draw the various inventory equipment slots.
	var/has_hidden_gear
	for(var/gear_slot in hud_data.gear)

		inv_box = new /obj/screen/inventory()
		inv_box.icon = ui_style
		inv_box.color = ui_color
		inv_box.alpha = ui_alpha

		var/list/slot_data =  hud_data.gear[gear_slot]
		inv_box.name =        gear_slot
		inv_box.screen_loc =  slot_data["loc"]
		inv_box.slot_id =     slot_data["slot"]
		inv_box.icon_state =  slot_data["state"]

		if(slot_data["dir"])
			inv_box.set_dir(slot_data["dir"])

		if(slot_data["toggle"])
			//src.other += inv_box
			has_hidden_gear = 0
			src.adding += inv_box
		else
			src.adding += inv_box

	if(has_hidden_gear)
		using = new /obj/screen()
		using.name = "toggle"
		using.icon = ui_style
		using.icon_state = "other"
		using.screen_loc = ui_inventory
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using

	// Draw the attack intent dialogue.
	if(hud_data.has_a_intent)

		using = new /obj/screen/intent()
		using.icon = ui_style
		var/obj/screen/intent/intent_button = using
		intent_button.update_icon()
		src.adding += using
		action_intent = using

		hud_elements |= using

	using = new /obj/screen()
	using.name = "moreactions"
	using.icon = 'icons/mob/screen/os13.dmi'
	using.icon_state = "moreactions"
	using.screen_loc = ui_os13_moreactions
	using.color = ui_color
	using.alpha = ui_alpha
	src.adding += using
	hud_elements |= using

	// Draw the combat intent dialogue.
	if(hud_data.has_c_intent)

		using = new /obj/screen/combat()
		using.icon = ui_style
		using.color = ui_color
		using.alpha = ui_alpha
		var/obj/screen/combat/combat_button = using
		combat_button.intent = mymob.c_intent
		using.update_icon()
		src.adding += using
		combat_intent_button = combat_button

		hud_elements |= using

		var/obj/screen/combat_popup/combat_popup = new
		combat_popup.icon = 'icons/mob/screen/screen2.dmi'
		combat_popup.icon_state = "cstyle2"
		combat_popup.screen_loc = null
		combat_popup.layer = HUD_ABOVE_HUD_LAYER
		combat_popup.color = ui_color
		combat_popup.alpha = ui_alpha
		combat_intent_popup = combat_popup
		src.adding += combat_popup
		hud_elements |= combat_popup

	// Draw the skill/family dialogue.
	if(hud_data.has_skills_family)

		using = new /obj/screen/skills_family()
		using.icon = ui_style
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using

		hud_elements |= using

	if(hud_data.has_m_intent)
		using = new /obj/screen()
		using.name = "move_mode"
		using.icon = ui_style
		using.icon_state = mymob.m_intent == "walk" ? "walking" : "running"
		using.screen_loc = ui_os13_move
		using.desc = "Click to toggle Walk and Run (Jog). Use Sprint while running to move faster."
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using
		move_intent = using

	using = new /obj/screen()
	using.name = "sprint"
	using.desc = "Click while running to toggle Sprint for extra speed at the cost of stamina."
	using.icon = ui_style
	using.icon_state = target.sprinting ? "sprint1" : "sprint0"
	using.screen_loc = ui_os13_sprint
	using.color = ui_color
	using.alpha = ui_alpha
	target.sprint_icon = using
	hud_elements |= using

	if(hud_data.has_drop && !hud_data.has_throw)
		using = new /obj/screen()
		using.name = "drop"
		using.icon = ui_style
		using.icon_state = "act_throw_off"
		using.screen_loc = ui_dropbutton
		using.color = ui_color
		using.alpha = ui_alpha
		src.hotkeybuttons += using

	if(hud_data.has_hands)
		/*
		using = new /obj/screen()
		using.name = "equip"
		using.icon = ui_style
		using.icon_state = "act_equip"
		using.screen_loc = ui_tg_equip
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using
		*/

		inv_box = new /obj/screen/inventory()
		inv_box.name = "r_hand"
		inv_box.icon = ui_style
		inv_box.icon_state = "r_hand"
		inv_box.screen_loc = ui_os13_rhand
		inv_box.slot_id = slot_r_hand
		inv_box.color = ui_color
		inv_box.alpha = ui_alpha

		src.r_hand_hud_object = inv_box
		src.adding += inv_box

		inv_box = new /obj/screen/inventory()
		inv_box.name = "l_hand"
		inv_box.icon = ui_style
		inv_box.icon_state = "l_hand"
		inv_box.screen_loc = ui_os13_lhand
		inv_box.slot_id = slot_l_hand
		inv_box.color = ui_color
		inv_box.alpha = ui_alpha
		src.l_hand_hud_object = inv_box
		src.adding += inv_box
	/*
		using = new /obj/screen/inventory()
		using.name = "hand"
		using.icon = ui_style
		using.icon_state = "hand"
		using.screen_loc = ui_os13_swaphand
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using

		using = new /obj/screen/inventory()
		using.name = "hand"
		using.icon = ui_style
		using.icon_state = "hand2"
		using.screen_loc = ui_swaphand2
		using.color = ui_color
		using.alpha = ui_alpha
		src.adding += using
		*/

		using = new /obj/screen/inventory()
		using.name = "hand"
		using.dir = NORTH
		using.icon = ui_style
		using.icon_state = mymob.hand ? "hand_l" : "hand_r"
		using.screen_loc = ui_os13_swaphand
		src.swaphands_hud_object = using
		src.adding += using
		update_selected_hand_overlay()

	if(hud_data.has_resist)
		using = new /obj/screen()
		using.name = "resist"
		using.icon = ui_style
		using.icon_state = target.toggle_resisting ? "act_resist2" : "act_resist"
		using.screen_loc = ui_resist
		using.color = ui_color
		using.alpha = ui_alpha
		src.hotkeybuttons += using

	if(hud_data.has_throw)
		mymob.throw_icon = new /obj/screen()
		mymob.throw_icon.icon = ui_style
		mymob.throw_icon.icon_state = "act_throw_off"
		mymob.throw_icon.name = "throw"
		mymob.throw_icon.screen_loc = ui_dropbutton
		mymob.throw_icon.color = ui_color
		mymob.throw_icon.alpha = ui_alpha
		src.hotkeybuttons += mymob.throw_icon
		hud_elements |= mymob.throw_icon

		mymob.pullin = new /obj/screen()
		mymob.pullin.icon = ui_style
		mymob.pullin.icon_state = "pull0"
		mymob.pullin.name = "pull"
		mymob.pullin.screen_loc = ui_pull
		src.hotkeybuttons += mymob.pullin
		hud_elements |= mymob.pullin

	if(hud_data.has_internals)
		mymob.internals = new /obj/screen()
		mymob.internals.icon = ui_style
		mymob.internals.icon_state = "internal0"
		mymob.internals.name = "internal"
		mymob.internals.screen_loc = ui_os13_internal
		hud_elements |= mymob.internals

		mymob.healths = new /obj/screen()
		mymob.healths.icon = ui_style
		mymob.healths.icon_state = "health0"
		mymob.healths.name = "health"
		mymob.healths.screen_loc = ui_os13_health
		hud_elements |= mymob.healths

	if(hud_data.has_bodytemp)
		mymob.bodytemp = new /obj/screen()
		mymob.bodytemp.icon = ui_style
		mymob.bodytemp.icon_state = "temp1"
		mymob.bodytemp.name = "body temperature"
		mymob.bodytemp.screen_loc = ui_os13_temp
		hud_elements |= mymob.bodytemp

	if(target.isSynthetic())
		target.cells = new /obj/screen()
		target.cells.icon = 'icons/mob/screen1_robot.dmi'
		target.cells.icon_state = "charge-empty"
		target.cells.name = "cell"
		target.cells.screen_loc = ui_os13_nutrition
		hud_elements |= target.cells

	else if(hud_data.has_nutrition)
		mymob.nutrition_icon = new /obj/screen/food()
		mymob.nutrition_icon.icon = ui_style
		mymob.nutrition_icon.icon_state = "hunger0"
		mymob.nutrition_icon.name = "nutrition"
		mymob.nutrition_icon.screen_loc = ui_os13_nutrition
		hud_elements |= mymob.nutrition_icon

	mymob.readycd = new /obj/screen()
	mymob.readycd.icon = ui_style
	mymob.readycd.icon_state = "ready000"
	mymob.readycd.name = "hand ready"
	mymob.readycd.screen_loc = ui_os13_readycd
	hud_elements |= mymob.readycd
	target.update_hand_ready_hud()

	mymob.stamina_icon = new /obj/screen()//STAMINA
	mymob.stamina_icon.icon = ui_style
	mymob.stamina_icon.icon_state = "fatigue10"
	mymob.stamina_icon.name = "stamina"
	mymob.stamina_icon.screen_loc = ui_os13_stamina
	hud_elements |= mymob.stamina_icon
	target.update_stamina_hud()

	mymob.film_grain = new()
	mymob.film_grain.icon = 'icons/effects/static.dmi'
	mymob.film_grain.icon_state = "7 moderate"
	mymob.film_grain.screen_loc = ui_entire_screen
	mymob.film_grain.alpha = 140
	mymob.film_grain.layer = FULLSCREEN_LAYER
	mymob.film_grain.mouse_opacity = 0
	hud_elements |= mymob.film_grain

	mymob.rest = new /obj/screen()
	mymob.rest.name = "rest"
	mymob.rest.icon = 'icons/mob/screen/os13.dmi'
	mymob.rest.icon_state = "rest[mymob.resting]"
	mymob.rest.screen_loc = ui_os13_rest
	hud_elements |= mymob.rest
	if (mymob.resting)
		mymob.rest.icon_state = "rest1"
	else
		mymob.rest.icon_state = "rest0"

	using = new /obj/screen()
	using.icon = ui_style
	using.icon_state = "actions"
	using.name = "actions1"
	using.screen_loc = ui_atk
	using.color = ui_color
	using.alpha = ui_alpha
	mymob.kick_icon = using
	mymob.jump_icon = using
	hud_elements |= using

	mymob.fixeye = new /obj/screen()
	mymob.fixeye.icon = ui_style
	mymob.fixeye.icon_state = "fixed_e0"
	mymob.fixeye.name = "fixeye"
	mymob.fixeye.screen_loc = ui_os13_fixeye
	hud_elements |= mymob.fixeye

	target.awake = new /obj/screen()
	target.awake.icon = ui_style
	target.awake.icon_state = target.sleeping ? "sleep1" : "sleep0"
	target.awake.name = "awake"
	target.awake.screen_loc = ui_os13_awake
	hud_elements |= target.awake
	target.update_awake_hud()

	mymob.pain = new /obj/screen( null )
	mymob.pain.icon = ui_style
	mymob.pain.icon_state = "blank"
	mymob.pain.name = "pain"
	mymob.pain.screen_loc = "WEST,SOUTH to EAST,NORTH"
	mymob.pain.layer = UNDER_HUD_LAYER
	mymob.pain.mouse_opacity = 0
	hud_elements |= mymob.pain

	mymob.noise = new /obj/screen()
	mymob.noise.icon = 'icons/misc/fullscreen.dmi'
	mymob.noise.icon_state = "grain"
	mymob.noise.name = " "
	mymob.noise.screen_loc = "1,1"
	mymob.noise.alpha = 120
	mymob.noise.mouse_opacity = 0
	hud_elements |= mymob.noise

	// Fatigue vignette overlay (starts invisible, becomes darker with fatigue stages)
	mymob.fatigue_vignette = new /obj/screen()
	mymob.fatigue_vignette.icon = 'icons/misc/fullscreen.dmi'
	mymob.fatigue_vignette.icon_state = "vignette_dark" // Provide multiple states e.g., vignette_dark1..4 in the icon file.
	mymob.fatigue_vignette.name = "fatigue"
	mymob.fatigue_vignette.screen_loc = "1,1"
	mymob.fatigue_vignette.alpha = 0 // Hidden initially
	mymob.fatigue_vignette.layer = FULLSCREEN_LAYER
	mymob.fatigue_vignette.mouse_opacity = 0
	hud_elements |= mymob.fatigue_vignette

	mymob.combat_icon = new /obj/screen()//combat mode
	mymob.combat_icon.name = "combat mode"
	mymob.combat_icon.icon = ui_style//'icons/mob/screen/dark.dmi'
	mymob.combat_icon.icon_state = "cmbt0"
	mymob.combat_icon.screen_loc = ui_os13_combat
	hud_elements |= mymob.combat_icon

	mymob.dodge_intent_icon = new /obj/screen()//dodge or parry
	mymob.dodge_intent_icon.name = "dodge intent"
	mymob.dodge_intent_icon.icon = ui_style//'icons/mob/screen/dark.dmi'
	mymob.dodge_intent_icon.icon_state = mymob.defense_intent == I_DODGE ? "dodge1" : "dodge0"
	mymob.dodge_intent_icon.screen_loc = ui_os13_defense
	hud_elements |= mymob.dodge_intent_icon

	mymob.surrender = new /obj/screen()
	mymob.surrender.name = "surrender"
	mymob.surrender.icon = ui_style//'icons/mob/screen/dark.dmi'
	mymob.surrender.icon_state = "surrender"
	mymob.surrender.screen_loc = ui_os13_surrender
	hud_elements |= mymob.surrender

	mymob.wield_icon = new /obj/screen()
	mymob.wield_icon.name = "wield"
	mymob.wield_icon.icon = ui_style
	mymob.wield_icon.icon_state = "guardsword"
	mymob.wield_icon.screen_loc = ui_wield
	hud_elements |= mymob.wield_icon

	mymob.happiness_icon = new /obj/screen()
	mymob.happiness_icon.name = "mood"
	mymob.happiness_icon.icon = ui_style
	mymob.happiness_icon.icon_state = "pressure6"
	mymob.happiness_icon.screen_loc = ui_os13_happiness
	hud_elements |= mymob.happiness_icon
	if(target.is_leech())
		target.update_happiness()


	mymob.zone_sel = new /obj/screen/zone_sel( null )
	mymob.zone_sel.screen_loc = ui_os13_zonesel
	mymob.zone_sel.icon = 'icons/mob/screen/zone_sel_osw.dmi'
	mymob.zone_sel.icon_state = "zone_sel"
	mymob.zone_sel.update_icon()
	hud_elements |= mymob.zone_sel

	//Handle the gun settings buttons
	mymob.gun_setting_icon = new /obj/screen/gun/mode(null)
	mymob.gun_setting_icon.icon = ui_style
	mymob.gun_setting_icon.color = ui_color
	mymob.gun_setting_icon.alpha = ui_alpha
	//hud_elements |= mymob.gun_setting_icon

	mymob.item_use_icon = new /obj/screen/gun/item(null)
	mymob.item_use_icon.icon = ui_style
	mymob.item_use_icon.color = ui_color
	mymob.item_use_icon.alpha = ui_alpha

	mymob.gun_move_icon = new /obj/screen/gun/move(null)
	mymob.gun_move_icon.icon = ui_style
	mymob.gun_move_icon.color = ui_color
	mymob.gun_move_icon.alpha = ui_alpha

	mymob.radio_use_icon = new /obj/screen/gun/radio(null)
	mymob.radio_use_icon.icon = ui_style
	mymob.radio_use_icon.color = ui_color
	mymob.radio_use_icon.alpha = ui_alpha

	if(ishuman(mymob))
		var/mob/living/carbon/human/H = mymob
		H.fov = new /obj/screen()
		H.fov.icon = 'icons/mob/hide.dmi'
		H.fov.icon_state = "combat"
		H.fov.name = " "
		H.fov.screen_loc = "1,1"
		H.fov.mouse_opacity = 0
		H.fov.layer = UNDER_HUD_LAYER
		hud_elements |= H.fov

	if(ishuman(mymob))
		var/mob/living/carbon/human/H = mymob
		H.hovertext = new /obj/screen/text/atm
		H.hovertext.maptext = ""
		H.hovertext.maptext_height = 100
		H.hovertext.maptext_width = 480
		H.hovertext.screen_loc = "CENTER-7, CENTER+7"
		hud_elements |= H.hovertext

	mymob.client.screen = list()

	mymob.client.screen += hud_elements
	mymob.client.screen += src.adding + src.hotkeybuttons
	inventory_shown = 1
	mymob.client.screen |= mymob.contents
	persistant_inventory_update()
	hidden_inventory_update()

/mob/living/carbon/human/verb/toggle_hotkey_verbs()
	set category = "OOC"
	set name = "Toggle hotkey buttons"
	set desc = "This disables or enables the user interface buttons which can be used with hotkeys."

	if(hud_used.hotkey_ui_hidden)
		client.screen += hud_used.hotkeybuttons
		hud_used.hotkey_ui_hidden = 0
	else
		client.screen -= hud_used.hotkeybuttons
		hud_used.hotkey_ui_hidden = 1

/obj/screen/food/Click(var/location, var/control, var/params)
	if(ishuman(usr) && usr.nutrition_icon == src)
		var/mob/living/carbon/human/H = usr
		var/hunger_status = "not hungry"
		var/thirst_status = "not thirsty"
		switch(H.nutrition)
			if(450 to INFINITY)
				hunger_status = "not hungry"
			if(350 to 450)
				hunger_status = "not hungry"
			if(250 to 350)
				hunger_status = "a bit peckish"
			if(150 to 250)
				hunger_status = "quite hungry"
			else
				hunger_status = "starving"
		switch(H.thirst)
			if(450 to INFINITY)
				thirst_status = "overhydrated"
			if(350 to 450)
				thirst_status = "not thirsty"
			if(250 to 350)
				thirst_status = "a bit thirsty"
			if(150 to 250)
				thirst_status = "quite thirsty"
			else
				thirst_status = "dying of thirst"
		to_chat(H, SPAN_NOTICE("Hunger: [hunger_status]. Thirst: [thirst_status]."))

/obj/screen/drink/Click(var/location, var/control, var/params)
	if(istype(usr) && usr.hydration_icon == src)
		switch(icon_state)
			if("hydration0")
				to_chat(usr, SPAN_WARNING("You are overhydrated."))
			if("hydration1")
				to_chat(usr, SPAN_NOTICE("You are not thirsty."))
			if("hydration2")
				to_chat(usr, SPAN_NOTICE("You are a bit thirsty."))
			if("hydration3")
				to_chat(usr, SPAN_WARNING("You are quite thirsty."))
			if("hydration4")
				to_chat(usr, SPAN_DANGER("You are dying of thirst!"))