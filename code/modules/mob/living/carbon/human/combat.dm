/mob/living/carbon/human/proc/toggle_combat_mode()
	if(!ishuman(usr))
		return

	playsound_local(src, 'sound/effects/ui_toggle.ogg', 50, 0, 1)
	var/mob/living/carbon/human/C = usr
	if(!C.combat_mode)
		C.combat_mode = 1
		C.combat_icon.icon_state = "cmbt1"
		to_chat(src, "<span class='warning'>You toggle on combat mode.</span>")
	else
		combat_mode = 0
		C.combat_icon.icon_state = "cmbt0"
		to_chat(src, "<span class='danger'>You toggle off combat mode.</span>")

/mob/living/carbon/human/proc/toggle_dodge_parry()
	if(ishuman(usr))
		var/mob/living/carbon/human/E = usr
		if(E.defense_intent == I_DODGE)
			E.defense_intent = I_PARRY
			E.dodge_intent_icon.icon_state = "dodge0"
			to_chat(src, "<span class='danger'>You will now parry.</span>")
		else
			E.defense_intent = I_DODGE
			E.dodge_intent_icon.icon_state = "dodge1"
			to_chat(src, "<span class='warning'>You will now dodge.</span>")

/mob/living/carbon/human/verb/dodgeparry_hotkey()
	set name = ".defense_intent"
	set hidden = 1

	toggle_dodge_parry()

/mob/living/carbon/human/verb/combatmode_hotkey()
	set name = ".combat_mode"
	set hidden = 1

	toggle_combat_mode()

//Going here till I find a better place for it.
/mob/living/proc/handle_combat_mode()//Makes it so that you can't regain stamina in combat mode.
	if(combat_mode)
		if(staminaloss < 90)
			adjustStaminaLoss(1)

/mob/living/proc/attempt_dodge(mob/living/carbon/human/attacker = null) // Handle parry is an object proc, it's, its own thing.
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(H.toggle_resisting)
			return 0
	var/dodge_modifier = c_intent == I_DEFEND ? 4 : 0
	if(defense_intent != I_DODGE || buckled || resting || lying || zoomed)
		return 0
	var/feint_penalty = ishuman(attacker) ? attacker.consume_feint_bonus(src) : 0
	if(combat_mode)
		var/dodge_difficulty = 10 + min(round(staminaloss / 10), 8) - dodge_modifier + feint_penalty
		if(staminaloss < 50 && statcheck(stats[STAT_DX], dodge_difficulty, "We couldn't dodge in time!", "dex"))
			do_dodge()
			return 1
		else if(staminaloss >= 50 && statcheck(stats[STAT_DX], dodge_difficulty + 2, "I'm getting too exhausted to dodge!", "dex"))
			do_dodge()
			return 1
	else if(prob(5) && statcheck(stats[STAT_DX], 12 + feint_penalty, "I can't dodge something I'm not ready for!", "dex"))
		do_dodge()
		return 1
	return 0

/mob/living/proc/do_dodge()
	var/lol = pick(GLOB.cardinal)//get a direction.
	adjustStaminaLoss(15)//add some stamina loss
	playsound(loc, 'sound/weapons/punchmiss.ogg', 80, 1)//play a sound
	step(src,lol)//move them
	visible_message("<b><big>[src.name] dodges out of the way!</big></b>")//send a message
	//be on our way

/mob/proc/surrender()//Surrending. I need to put this in a different file.
	if(!incapacitated())
		//Stun(5)  // THIS WAS NOT FUNNY AND I DID NOT LAUGH
		Weaken(10) // This is enabled however to give people an incentive not to fake surrender
		visible_message("<b>[src] surrenders!</b>")
		playsound(src, 'sound/effects/surrender.ogg', 50, 1)
		var/atom/movable/overlay/animation = new /atom/movable/overlay(loc)
		animation.icon_state = "blank"
		animation.icon = 'icons/mob/screen1.dmi'
		animation.master = src
		flick("attention", animation)

/mob/proc/mob_rest()
	var/getupchance = (!stunned && !weakened) || (rand(1,50) < stats[STAT_DX]/1.5)
	if(resting && getupchance)//The incapacitated proc includes resting for whatever fucking stupid reason I hate SS13 code so fucking much.
		visible_message("<span class='notice'>[usr] is trying to get up.</span>")
		if(do_after(src, 20 -  stat_to_modifier(stats[STAT_DX])* 3))
			resting = FALSE
			rest?.icon_state = "rest0"
			update_canmove()
		return

	else
		resting = TRUE
		playsound(get_turf(src), "bodyfall", 50, 1)
		update_canmove()
		//For stopping runtimes with NPCs
		rest?.icon_state = "rest1"
		fixeye?.icon_state = "fixed_e0"
		walk_to(src,0)

/mob/living/carbon/human/proc/toggle_eye()
	if(stat != CONSCIOUS || sleeping || voluntary_sleeping || waking_up)
		eye_closed = TRUE
		to_chat(src, "<span class='warning'>You can't open your eyes while asleep.</span>")
		update_awake_hud()
		return
	eye_closed = !eye_closed
	if(eye_closed)
		to_chat(src, "<span class='notice'>You close your eyes.</span>")
	else
		to_chat(src, "<span class='notice'>You open your eyes.</span>")
	update_body()
	species.handle_vision(src)
	update_awake_hud()

/mob/living/carbon/human/proc/update_awake_hud()
	if(!awake)
		return
	if(waking_up)
		awake.icon_state = "sleep2"
	else if(stat != CONSCIOUS || sleeping || voluntary_sleeping)
		awake.icon_state = "sleep1"
	else
		awake.icon_state = "sleep0"
	awake.overlays.Cut()
	if(eye_closed)
		awake.overlays += image(awake.icon, "eyeso")

/mob/living/carbon/human/proc/update_hand_ready_hud()
	if(!readycd)
		return
	readycd.icon_state = "ready000"
	readycd.overlays.Cut()
	if(world.time < right_hand_ready_until)
		readycd.overlays += image(readycd.icon, "ready100")
	if(world.time < special_action_ready_until)
		readycd.overlays += image(readycd.icon, "ready010")
	if(world.time < left_hand_ready_until)
		readycd.overlays += image(readycd.icon, "ready001")

/mob/living/carbon/human/proc/set_hand_ready_cooldown(var/left_hand, var/cooldown_until)
	if(left_hand)
		left_hand_ready_until = max(left_hand_ready_until, cooldown_until)
	else
		right_hand_ready_until = max(right_hand_ready_until, cooldown_until)

/mob/living/carbon/human/proc/set_special_action_cooldown(var/cooldown_until)
	special_action_ready_until = max(special_action_ready_until, cooldown_until)

/mob/verb/mob_rest_hotkey()
	set name = ".mob_rest"
	set hidden = 1

	mob_rest()