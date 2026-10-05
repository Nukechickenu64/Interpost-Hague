/*
	Screen objects
	Todo: improve/re-implement

	Screen objects are only used for the hud and should not appear anywhere "in-game".
	They are used with the client/screen list and the screen_loc var.
	For more information, see the byond documentation on the screen_loc and screen vars.
*/
/obj/screen
	name = ""
	icon = 'icons/mob/screen1.dmi'
	plane = HUD_PLANE
	layer = HUD_BASE_LAYER
	appearance_flags = NO_CLIENT_COLOR
	unacidable = 1
	var/obj/master = null    //A reference to the object in the slot. Grabs or items, generally.
	var/datum/hud/hud = null // A reference to the owner HUD, if any.
	var/globalscreen = FALSE //Global screens are not qdeled when the holding mob is destroyed.

/obj/screen/Destroy()
	master = null
	return ..()

/obj/screen/text
	icon = null
	icon_state = null
	mouse_opacity = 0
	screen_loc = "CENTER-7,CENTER-7"
	maptext_height = 480
	maptext_width = 480

/obj/screen/inventory
	var/slot_id	//The indentifier for the slot. It has nothing to do with ID cards.
	var/list/object_overlays = list() // Required for inventory/screen overlays.
	var/occupied = FALSE
	var/unoccupied_color

/obj/screen/inventory/proc/update_occupancy(obj/item/item)
	var/new_occupied = !!item
	if(occupied == new_occupied)
		return
	occupied = new_occupied
	if(occupied)
		unoccupied_color = color
		animate(src, color = "#444444", time = 1, loop = -1)
		animate(color = unoccupied_color, time = 1, loop = -1)
	else
		animate(src)
		color = unoccupied_color

/obj/screen/close
	name = "close"
	icon = 'icons/mob/screen1_small.dmi'
	icon_state = "x"

/obj/screen/close/Click()
	if(master)
		if(istype(master, /obj/item/storage))
			var/obj/item/storage/S = master
			playsound(loc, S.close_sound, 75, 1)
			S.close(usr)
	return 1


/obj/screen/item_action
	var/obj/item/owner

/obj/screen/item_action/Destroy()
	..()
	owner = null

/obj/screen/item_action/Click()
	if(!usr || !owner)
		return 1
	if(!usr.canClick())
		return

	if(usr.stat || usr.restrained() || usr.stunned || usr.lying)
		return 1

	if(!(owner in usr))
		return 1

	owner.ui_action_click()
	return 1

/obj/screen/storage
	name = "storage"

/obj/screen/storage/Click()
	if(!usr.canClick())
		return 1
	if(usr.stat || usr.paralysis || usr.stunned || usr.weakened)
		return 1
	if (istype(usr.loc,/obj/mecha)) // stops inventory actions in a mech
		return 1
	if(master)
		var/obj/item/I = usr.get_active_hand()
		if(I)
			usr.ClickOn(master)
	return 1

/obj/screen/happiness_icon/Click()
	var/mob/living/carbon/C = usr
	C.print_happiness(C)

// Ported from OpenSourceWeb: one 32x64 selector, so icon-y spans the whole doll (1-64).
/obj/screen/zone_sel
	name = "damage zone"
	icon_state = "zone_sel"
	screen_loc = ui_zonesel
	var/selecting = BP_CHEST

/obj/screen/zone_sel/Click(location, control, params)
	var/list/PL = params2list(params)
	var/icon_x = text2num(PL["icon-x"])
	var/icon_y = text2num(PL["icon-y"])
	var/old_selecting = selecting //We're only going to update_icon() if there's been a change

	if(PL["right"])
		selecting = pick(BP_R_FOOT, BP_L_FOOT, BP_R_LEG, BP_L_LEG, BP_GROIN, BP_R_HAND, BP_L_HAND, BP_VITALS, BP_THROAT, BP_CHEST, BP_R_ARM, BP_L_ARM, BP_MOUTH, BP_FACE, BP_EYES, BP_HEAD)
	else
		switch(icon_y)
			if(1 to 7) //Feet
				switch(icon_x)
					if(1 to 16)
						selecting = BP_R_FOOT
					if(17 to 32)
						selecting = BP_L_FOOT
					else
						return TRUE
			if(8 to 18) //Legs
				switch(icon_x)
					if(1 to 16)
						selecting = BP_R_LEG
					if(17 to 32)
						selecting = BP_L_LEG
					else
						return TRUE
			if(19 to 22) //Legs and groin
				switch(icon_x)
					if(1 to 11)
						selecting = BP_R_LEG
					if(12 to 22)
						selecting = BP_GROIN
					if(23 to 32)
						selecting = BP_L_LEG
					else
						return TRUE
			if(23 to 25) //Hands and groin/vitals
				switch(icon_x)
					if(2 to 11)
						selecting = BP_R_HAND
					if(12 to 22)
						selecting = (icon_y == 23) ? BP_GROIN : BP_VITALS
					if(23 to 31)
						selecting = BP_L_HAND
					else
						return TRUE
			if(26 to 32) //Hands and vitals
				switch(icon_x)
					if(2 to 11)
						selecting = BP_R_HAND
					if(12 to 22)
						selecting = BP_VITALS
					if(23 to 31)
						selecting = BP_L_HAND
					else
						return TRUE
			if(33 to 44) //Chest and arms to shoulders
				switch(icon_x)
					if(4 to 10)
						selecting = BP_R_ARM
					if(11 to 22)
						selecting = BP_CHEST
					if(23 to 29)
						selecting = BP_L_ARM
					else
						return TRUE
			if(45 to 64) //Throat, face, mouth, eyes, head
				switch(icon_x)
					if(11 to 22)
						selecting = BP_FACE
						switch(icon_y)
							if(45 to 48)
								if(icon_x >= 13 && icon_x <= 20)
									selecting = BP_THROAT
							if(49 to 51)
								if(icon_x >= 13 && icon_x <= 20)
									selecting = BP_MOUTH
							if(53 to 55)
								if((icon_x >= 14 && icon_x <= 15) || (icon_x >= 18 && icon_x <= 19))
									selecting = BP_EYES
							if(56 to 61)
								selecting = BP_HEAD
					else
						return TRUE

	if(old_selecting != selecting)
		update_icon()
		playsound(usr, pick('sound/misc/UISwitch1.ogg', 'sound/misc/UISwitch2.ogg', 'sound/misc/PopupMenu.ogg'), 30, 0)
	return TRUE

/obj/screen/zone_sel/proc/set_selected_zone(bodypart)
	var/old_selecting = selecting
	selecting = bodypart
	if(old_selecting != selecting)
		update_icon()

/obj/screen/zone_sel/update_icon()
	overlays.Cut()
	if(icon != 'icons/mob/screen/zone_sel_osw.dmi')
		overlays += image('icons/mob/zone_sel.dmi', "[selecting]")
		return
	switch(selecting)
		if(BP_EYES)
			overlays += image(icon, "right eye")
			overlays += image(icon, "left eye")
		if(BP_BELLY)
			overlays += image(icon, "vitals")
		else
			overlays += image(icon, "[selecting]")
/obj/screen/intent
	name = "intent"
	//icon = 'icons/mob/screen/dark.dmi'
	icon_state = "intent1"
	screen_loc = ui_drop_throw//ui_acti
	var/intent = I_HELP

/obj/screen/intent/Click(var/location, var/control, var/params)
	var/clicksound = list('sound/misc/UISwitch1.ogg', 'sound/misc/UISwitch2.ogg', 'sound/misc/PopupMenu.ogg')
	var/list/P = params2list(params)
	var/icon_x = text2num(P["icon-x"])
	var/icon_y = text2num(P["icon-y"])
	playsound(usr, pick(clicksound), 30, 0)
	intent = I_DISARM
	if(icon_x <= world.icon_size/2)
		if(icon_y <= world.icon_size/2)
			intent = I_HELP
		else
			intent = I_HURT
	else if(icon_y <= world.icon_size/2)
		intent = I_GRAB
	update_icon()
	usr.a_intent = intent

/obj/screen/intent/update_icon()
	if(icon == 'icons/mob/screen/os13.dmi')
		switch(intent)
			if(I_HELP)
				icon_state = "intent1"
			if(I_DISARM)
				icon_state = "intent3"
			if(I_GRAB)
				icon_state = "intent2"
			if(I_HURT)
				icon_state = "intent4"
	else
		icon_state = "intent_[intent]"

/obj/screen/combat
	name = "Combat Intent"
	icon = 'icons/mob/screen/os13.dmi'
	icon_state = "aim"
	screen_loc = ui_atk_intents
	var/intent = I_STRONG

/obj/screen/combat/Click(var/location, var/control, var/params)
	if(!usr || !usr.hud_used || !usr.hud_used.combat_intent_popup)
		return 1
	var/clicksound = list('sound/misc/UISwitch1.ogg', 'sound/misc/UISwitch2.ogg', 'sound/misc/PopupMenu.ogg')
	playsound(usr, pick(clicksound), 30, 0)
	var/obj/screen/combat_popup/popup = usr.hud_used.combat_intent_popup
	popup.screen_loc = popup.screen_loc ? null : ui_os13_combat_popup
	return 1


/obj/screen/combat/update_icon()
	if(icon == 'icons/mob/screen/os13.dmi')
		switch(intent)
			if(I_AIM)
				icon_state = "aimed"
			if(I_STRONG)
				icon_state = "max_st"
			if(I_DEFEND)
				icon_state = "defend"
			if(I_QUICK)
				icon_state = "fury"
			if(I_WEAK)
				icon_state = "min_st"
			if(I_GUARD)
				icon_state = "guard"
			if(I_DUAL)
				icon_state = "dual"
			if(I_FEINT)
				icon_state = "feint"
	else
		icon_state = "[intent]"

/obj/screen/combat_popup
	name = "combat popup"
	icon = 'icons/mob/screen/screen2.dmi'
	icon_state = "cstyle2"
	screen_loc = null
	layer = HUD_ABOVE_HUD_LAYER

/obj/screen/combat_popup/Click(var/location, var/control, var/params)
	if(!ishuman(usr) || !usr.hud_used || !usr.hud_used.combat_intent_button)
		return 1
	var/clicksound = list('sound/misc/UISwitch1.ogg', 'sound/misc/UISwitch2.ogg', 'sound/misc/PopupMenu.ogg')
	var/list/P = params2list(params)
	var/icon_x = text2num(P["icon-x"])
	var/icon_y = text2num(P["icon-y"])
	if(icon_x < 33 || icon_x > 62)
		return 1
	var/selected_intent
	switch(icon_y)
		if(55 to 64)
			selected_intent = I_WEAK
		if(48 to 54)
			selected_intent = I_AIM
		if(40 to 47)
			selected_intent = I_QUICK
		if(33 to 39)
			selected_intent = I_STRONG
		if(25 to 32)
			selected_intent = I_DEFEND
		if(18 to 24)
			selected_intent = I_GUARD
		if(9 to 17)
			selected_intent = I_DUAL
		if(1 to 8)
			selected_intent = I_FEINT
	if(!selected_intent)
		return 1
	playsound(usr, pick(clicksound), 30, 0)
	var/mob/living/carbon/human/H = usr
	H.c_intent = selected_intent
	var/obj/screen/combat/button = H.hud_used.combat_intent_button
	button.intent = selected_intent
	button.update_icon()
	screen_loc = null
	return 1

/obj/screen/skills_family
	name = "cutebuttons"
	icon = 'icons/mob/screen/os13.dmi'
	icon_state = "cutebuttons"
	screen_loc = ui_skills_family//ui_acti
	layer = HUD_ABOVE_HUD_LAYER

/obj/screen/skills_family/Click(var/location, var/control, var/params)
	var/clicksound = list('sound/misc/UISwitch1.ogg', 'sound/misc/UISwitch2.ogg', 'sound/misc/PopupMenu.ogg')
	var/list/P = params2list(params)
	var/icon_x = text2num(P["icon-x"])
	var/icon_y = text2num(P["icon-y"])
	playsound(usr, pick(clicksound), 30, 0)
	if(!ishuman(usr))
		return 1
	var/mob/living/carbon/human/H = usr
	if(icon_y > world.icon_size/2)
		if(icon_x <= world.icon_size/2)
			H.open_craft_menu()
		else
			chat_crew_manifest()
	else if(icon_x > world.icon_size/2)
		usr << browse('html/help.html', "window=help")
	else
		H.check_skills()
	return 1

/obj/screen/Click(location, control, params)
	if(!usr)	return 1
	var/list/modifiers = params2list(params)
	if(modifiers["right"] && modifiers["shift"]) {
		usr.ClickOn(src, params, usr, usr.client)
		return 1
	}
	var/clicksound = list('sound/misc/UISwitch1.ogg', 'sound/misc/UISwitch2.ogg', 'sound/misc/PopupMenu.ogg')
	switch(name)
		if("toggle")
			if(usr.hud_used.inventory_shown)
				usr.hud_used.inventory_shown = 0
				usr.client.screen -= usr.hud_used.other
			else
				usr.hud_used.inventory_shown = 1
				usr.client.screen += usr.hud_used.other

			playsound(usr, pick(clicksound), 30, 0)
			usr.hud_used.hidden_inventory_update()

		if("equip")
			if (istype(usr.loc,/obj/mecha)) // stops inventory actions in a mech
				return 1
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				H.quick_equip()
			playsound(usr, pick(clicksound), 30, 0)

		if("moreactions")
			if(!ishuman(usr))
				return 1
			var/mob/living/carbon/human/H = usr
			var/icon_y = text2num(modifiers["icon-y"])
			if(icon_y >= 23)
				H.do_wield()
			else if(icon_y >= 16)
				H.lookup()
			else if(icon_y >= 9)
				H.hide()
			else
				var/turf/front = get_step(H, H.dir)
				if(front)
					H.ClickOn(front, "", H, H.client)
			playsound(usr, pick(clicksound), 30, 0)

		if("resist")
			if(modifiers["right"])
				if(ishuman(usr))
					var/mob/living/carbon/human/H = usr
					H.toggle_resisting = !H.toggle_resisting
					src.icon_state = H.toggle_resisting ? "act_resist2" : "act_resist"
			else if(isliving(usr))
				var/mob/living/L = usr
				L.resist()
			playsound(usr, pick(clicksound), 30, 0)


		if("move_mode")
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				H.m_intent = H.m_intent == "walk" ? "run" : "walk"
				H.update_movement_hud()
			playsound(usr, pick(clicksound), 30, 0)

		if("sprint")
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				if(H.sprinting)
					H.sprinting = FALSE
				else if(H.m_intent == "run" && H.canmove && !H.resting)
					H.sprinting = TRUE
				else
					to_chat(H, SPAN_NOTICE("You need to be able to move and set your intent to Run to sprint."))
				H.update_movement_hud()
			playsound(usr, pick(clicksound), 30, 0)

		if("Reset Machine")
			usr.unset_machine()

		if("health")
			if(ishuman(usr))
				var/mob/living/carbon/human/X = usr
				X.exam_self()
				playsound(usr, pick(clicksound), 30, 0)


		if("surrender")
			if(ishuman(usr))
				var/mob/living/carbon/human/S = usr
				S.surrender()
				playsound(usr, pick(clicksound), 30, 0)


		if("internal")
			if(iscarbon(usr))
				var/mob/living/carbon/C = usr
				if(!C.stat && !C.stunned && !C.paralysis && !C.restrained())
					if(C.internal)
						C.internal = null
						to_chat(C, "<span class='notice'>No longer running on internals.</span>")
						if(C.internals)
							C.internals.icon_state = "internal0"
					else

						var/no_mask
						if(!(C.wear_mask && C.wear_mask.item_flags & ITEM_FLAG_AIRTIGHT))
							var/mob/living/carbon/human/H = C
							if(!(H.head && H.head.item_flags & ITEM_FLAG_AIRTIGHT))
								no_mask = 1

						if(no_mask)
							to_chat(C, "<span class='notice'>You are not wearing a suitable mask or helmet.</span>")
							return 1
						else
							var/list/nicename = null
							var/list/tankcheck = null
							var/breathes = "oxygen"    //default, we'll check later
							var/list/contents = list()
							var/from = "on"

							if(ishuman(C))
								var/mob/living/carbon/human/H = C
								breathes = H.species.breath_type
								nicename = list ("suit", "back", "belt", "right hand", "left hand", "left pocket", "right pocket")
								tankcheck = list (H.s_store, C.back, H.belt, C.r_hand, C.l_hand) + H.get_pocket_items(slot_l_store) + H.get_pocket_items(slot_r_store)
							else
								nicename = list("right hand", "left hand", "back")
								tankcheck = list(C.r_hand, C.l_hand, C.back)

							for(var/i=1, i<tankcheck.len+1, ++i)
								if(istype(tankcheck[i], /obj/item/tank))
									var/obj/item/tank/t = tankcheck[i]
									if (!isnull(t.manipulated_by) && t.manipulated_by != C.real_name && findtext(t.desc,breathes))
										contents.Add(t.air_contents.total_moles)	//Someone messed with the tank and put unknown gasses
										continue					//in it, so we're going to believe the tank is what it says it is
									switch(breathes)
																		//These tanks we're sure of their contents
										if("nitrogen") 							//So we're a bit more picky about them.

											if(t.air_contents.gas["nitrogen"] && !t.air_contents.gas["oxygen"])
												contents.Add(t.air_contents.gas["nitrogen"])
											else
												contents.Add(0)

										if ("oxygen")
											if(t.air_contents.gas["oxygen"] && !t.air_contents.gas["phoron"])
												contents.Add(t.air_contents.gas["oxygen"])
											else
												contents.Add(0)

										// No races breath this, but never know about downstream servers.
										if ("carbon dioxide")
											if(t.air_contents.gas["carbon_dioxide"] && !t.air_contents.gas["phoron"])
												contents.Add(t.air_contents.gas["carbon_dioxide"])
											else
												contents.Add(0)


								else
									//no tank so we set contents to 0
									contents.Add(0)

							//Alright now we know the contents of the tanks so we have to pick the best one.

							var/best = 0
							var/bestcontents = 0
							for(var/i=1, i <  contents.len + 1 , ++i)
								if(!contents[i])
									continue
								if(contents[i] > bestcontents)
									best = i
									bestcontents = contents[i]


							//We've determined the best container now we set it as our internals

							if(best)
								to_chat(C, "<span class='notice'>You are now running on internals from [tankcheck[best]] [from] your [nicename[best]].</span>")
								playsound(C, 'sound/effects/internals.ogg', 50, 0)
								C.internal = tankcheck[best]


							if(C.internal)
								if(C.internals)
									C.internals.icon_state = "internal1"
							else
								to_chat(C, "<span class='notice'>You don't have a[breathes=="oxygen" ? "n oxygen" : addtext(" ",breathes)] tank.</span>")
		if("act_intent")
			usr.a_intent_change("right")
			playsound(usr, pick(clicksound), 30, 0)

		if("pull")
			usr.stop_pulling()
			playsound(usr, pick(clicksound), 30, 0)


		if("rest")
			usr.mob_rest()
			playsound(usr, pick(clicksound), 30, 0)


		if("throw")
			if(!usr.stat && isturf(usr.loc) && !usr.restrained())
				var/icon_y = text2num(modifiers["icon-y"])
				if(usr.throw_icon && usr.throw_icon.icon == 'icons/mob/screen/os13.dmi' && icon_y && icon_y <= world.icon_size/2)
					if(usr.client)
						usr.client.drop_item()
				else
					usr:toggle_throw_mode()
				playsound(usr, pick(clicksound), 30, 0)
		if("drop")
			if(usr.client)
				usr.client.drop_item()
				playsound(usr, pick(clicksound), 30, 0)
		if("wield")
			if(!ishuman(usr)) return
			var/mob/living/carbon/human/HH = usr
			var/obj/item/I = HH.get_active_hand()
			if(!I)
				return
			I.attempt_wield(HH)
			playsound(usr, pick(clicksound), 30, 0)
		if("actions1")
			if(!ishuman(usr))
				return 1
			var/mob/living/carbon/human/H = usr
			var/icon_y = text2num(modifiers["icon-y"])
			var/new_intent
			if(icon_y >= 23)
				new_intent = "kick"
			else if(icon_y >= 16 && icon_y <= 22)
				new_intent = "steal"
			else if(icon_y >= 9 && icon_y <= 15)
				new_intent = "jump"
			else if(icon_y >= 1 && icon_y <= 8)
				new_intent = "bite"
			else
				return 1
			if(H.middle_click_intent == new_intent)
				H.middle_click_intent = null
				H.kick_icon.icon_state = "actions"
			else
				H.middle_click_intent = new_intent
				H.kick_icon.icon_state = "actions[new_intent]"
			playsound(usr, pick(clicksound), 30, 0)
		if("combat mode")
			if(!ishuman(usr))	return
			usr << 'sound/effects/ui_toggle.ogg'
			var/mob/living/carbon/human/C = usr
			if(C.combat_mode)
				C.combat_mode = 0
				C.combat_icon.icon_state = "cmbt0"
			else
				C.combat_mode = 1
				C.combat_icon.icon_state = "cmbt1"

		if("dodge intent")
			if(ishuman(usr))
				playsound(usr, pick(clicksound), 30, 0)
				var/mob/living/carbon/human/E = usr
				if(E.defense_intent == I_PARRY)
					E.defense_intent = I_DODGE
					E.dodge_intent_icon.icon_state = "dodge1"
				else
					E.defense_intent = I_PARRY
					E.dodge_intent_icon.icon_state = "dodge0"
		if("fixeye")
			usr.face_direction()
			playsound(usr, pick(clicksound), 30, 0)
			if(usr.facing_dir)
				usr.fixeye.icon_state = "fixed_e1"
			else
				usr.fixeye.icon_state = "fixed_e0"
		if("awake")
			if(!ishuman(usr))
				return 1
			var/mob/living/carbon/human/H = usr
			var/icon_y = text2num(modifiers["icon-y"])
			if(icon_y in 12 to 21)
				H.toggle_eye()
			else if(icon_y in 22 to 32)
				H.mob_sleep()
			else
				return 1
			H.update_awake_hud()
			playsound(usr, pick(clicksound), 30, 0)

		if("mood")
			playsound(usr, pick(clicksound), 30, 0)
			var/mob/living/carbon/C = usr
			C.print_happiness(C)

		if("stamina")
			playsound(usr, pick(clicksound), 30, 0)
			var/mob/living/M = usr
			M.report_stamina()

		if("module")
			if(isrobot(usr))
				var/mob/living/silicon/robot/R = usr
//				if(R.module)
//					R.hud_used.toggle_show_robot_modules()
//					return 1
				R.pick_module()

		if("inventory")
			if(isrobot(usr))
				var/mob/living/silicon/robot/R = usr
				if(R.module)
					R.hud_used.toggle_show_robot_modules()
					return 1
				else
					to_chat(R, "You haven't selected a module yet.")

		if("radio")
			if(issilicon(usr))
				usr:radio_menu()
		if("panel")
			if(issilicon(usr))
				usr:installed_modules()

		if("store")
			if(isrobot(usr))
				var/mob/living/silicon/robot/R = usr
				if(R.module)
					R.uneq_active()
					R.hud_used.update_robot_modules_display()
				else
					to_chat(R, "You haven't selected a module yet.")

		if("module1")
			if(istype(usr, /mob/living/silicon/robot))
				usr:toggle_module(1)

		if("module2")
			if(istype(usr, /mob/living/silicon/robot))
				usr:toggle_module(2)

		if("module3")
			if(istype(usr, /mob/living/silicon/robot))
				usr:toggle_module(3)
		else
			return 0
	return 1

/obj/screen/inventory/Click(location, control, params)
	// At this point in client Click() code we have passed the 1/10 sec check and little else
	// We don't even know if it's a middle click
	if(!usr.canClick())
		return 1
	if(usr.stat || usr.paralysis || usr.stunned)//|| usr.weakened Don't need none of that shit no more.
		return 1
	if (istype(usr.loc,/obj/mecha)) // stops inventory actions in a mech
		return 1
	var/obj/item/grab/mouth/bite_grab = usr.get_equipped_item(slot_id)
	if(istype(bite_grab))
		if(bite_grab.handle_hud_click(usr, params))
			return 1
	switch(name)
		if("r_hand")
			if(iscarbon(usr))
				var/mob/living/carbon/C = usr
				C.activate_hand("r")
				if(C.hand)
					C.activate_hand("r")
				else
					C.attack_empty_hand(BP_R_HAND)
		if("l_hand")
			if(iscarbon(usr))
				var/mob/living/carbon/C = usr
				C.activate_hand("l")
				if(!C.hand)
					C.activate_hand("l")
				else
					C.attack_empty_hand(BP_L_HAND)
		if("swap")
			usr:swap_hand()
		if("hand")
			usr:swap_hand()

		else
			if(usr.attack_ui(slot_id))
				usr.update_inv_l_hand(0)
				usr.update_inv_r_hand(0)
	return 1
