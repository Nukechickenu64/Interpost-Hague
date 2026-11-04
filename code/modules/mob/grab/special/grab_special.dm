/datum/grab/special
	icon = 'icons/mob/screen/os13.dmi'
	stop_move = 1
	can_absorb = 1
	shield_assailant = 0
	point_blank_mult = 1
	force_danger = 1

/obj/item/grab/special/init()
	..()

	if(affecting.w_uniform)
		affecting.w_uniform.add_fingerprint(assailant)

	assailant.put_in_active_hand(src)
	assailant.do_attack_animation(affecting)
	playsound(affecting.loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
	var/obj/O = get_targeted_organ()
	var/grab_string = O.name
	if(assailant.zone_sel.selecting == BP_THROAT)
		grab_string = "throat"
	// OS13 parity: chest grab with a blade in the off hand reads as a hostage take.
	var/obj/item/offhand = assailant.get_inactive_hand()
	if(assailant.zone_sel.selecting == BP_THROAT && istype(offhand) && offhand.sharp)
		visible_message("<span class='danger'>[assailant] grabs [affecting]'s chest, putting \the [offhand] to [affecting]'s throat!</span>")
	else
		visible_message("<span class='warning'>[assailant] grabs [affecting]'s [grab_string]!</span>")
	affecting.grabbed_by += src

/obj/item/grab/special/strangle
	type_name = GRAB_STRANGLE
	start_grab_name = GRAB_STRANGLE

/datum/grab/special/strangle
	type_name = GRAB_STRANGLE
	icon_state = "strangle"
	activate_effect = FALSE
	state_name = GRAB_STRANGLE

/datum/grab/special/strangle/attack_self_act(var/obj/item/grab/G)
	do_strangle(G)

/datum/grab/special/strangle/process_effect(var/obj/item/grab/G)
	var/mob/living/carbon/human/affecting = G.affecting

	affecting.drop_l_hand()
	affecting.drop_r_hand()

	if(affecting.lying)
		affecting.Weaken(4)

	affecting.adjustOxyLoss(1)

	affecting.apply_effect(STUTTER, 5) //It will hamper your voice, being choked and all.
	affecting.Weaken(5)	//Should keep you down unless you get help.
	affecting.losebreath = max(affecting.losebreath + 2, 3)

/datum/grab/special/strangle/proc/do_strangle(var/obj/item/grab/G)
	activate_effect = !activate_effect
	G.assailant.visible_message("<span class='warning'>[G.assailant] [activate_effect ? "starts" : "stops"] strangling [G.affecting]</span>")

/obj/item/grab/special/wrench
	type_name = GRAB_WRENCH
	start_grab_name = GRAB_WRENCH

/datum/grab/special/wrench
	type_name = GRAB_WRENCH
	icon_state = "wrench"
	state_name = GRAB_WRENCH

/datum/grab/special/wrench/attack_self_act(var/obj/item/grab/G)
	var/mob/living/carbon/human/assailant = G.assailant
	do_wrench(G)
	if(!QDELETED(assailant))
		assailant.setClickCooldown(DEFAULT_SLOW_COOLDOWN)

/datum/grab/special/wrench/proc/do_wrench(var/obj/item/grab/G)
	var/obj/item/organ/external/O = G.get_targeted_organ()
	var/mob/living/carbon/human/assailant = G.assailant
	var/mob/living/carbon/human/affecting = G.affecting

	if(assailant.doing_something)
		return

	if(!O)
		to_chat(assailant, "<span class='warning'>[affecting] is missing that body part!</span>")
		return

	var/relocating = O.dislocated > 0
	if(relocating && O.is_parent_dislocated())
		to_chat(assailant, "<span class='warning'>You need to relocate the joint above [O.name] first!</span>")
		return

	assailant.doing_something = TRUE
	if(relocating)
		assailant.visible_message("<span class='warning'>[assailant] tries to relocate [affecting]'s [O.joint]!</span>")
	else
		assailant.visible_message("<span class='danger'>[assailant] tries to break [affecting]'s [O.name]!</span>")

	if(!do_after(assailant, relocating ? 30 : 15, affecting))
		assailant.doing_something = FALSE
		return

	if(QDELETED(G) || QDELETED(O) || O.owner != affecting || G.get_targeted_organ() != O)
		assailant.doing_something = FALSE
		return

	if(relocating)
		if(O.dislocated > 0 && !O.is_parent_dislocated())
			O.undislocate()
			assailant.visible_message("<span class='notice'>[assailant] pops [affecting]'s [O.joint] back into place!</span>")
		assailant.doing_something = FALSE
		return

	if(!O.is_broken())
		var/break_chance
		if(O == affecting.get_organ(BP_HEAD))
			break_chance = (assailant.stats[STAT_ST]*10) - affecting.stats[STAT_HT]*8
		else if(O == affecting.get_organ(BP_L_ARM) || O == affecting.get_organ(BP_R_ARM) || O == affecting.get_organ(BP_R_LEG)|| O == affecting.get_organ(BP_R_LEG))
			break_chance = (assailant.stats[STAT_ST]*10) - affecting.stats[STAT_HT]*6
		else
			break_chance = (assailant.stats[STAT_ST]*10) - affecting.stats[STAT_HT]*5
		if (break_chance <= 0)
			break_chance = 5 //for good luck :)
		if(prob(break_chance))
			O.fracture()
			if(O == affecting.get_organ(BP_HEAD))
				affecting.adjustBrainLoss(150) //if you're getting your head wrenched you're gonna die lol

	assailant.doing_something = FALSE


/obj/item/grab/special/takedown
	type_name = GRAB_TAKEDOWN
	start_grab_name = GRAB_TAKEDOWN

/datum/grab/special/takedown
	type_name = GRAB_TAKEDOWN
	state_name = GRAB_TAKEDOWN
	icon_state = "takedown"

/datum/grab/special/takedown/attack_self_act(var/obj/item/grab/G)
	do_takedown(G)
	G.assailant.setClickCooldown(DEFAULT_SLOW_COOLDOWN)

/datum/grab/special/takedown/process_effect(var/obj/item/grab/G)
	// Keeps those who are on the ground down
	if(G.affecting.lying)
		G.affecting.Weaken(4)

/datum/grab/special/takedown/proc/do_takedown(var/obj/item/grab/G)
	var/mob/living/carbon/human/affecting = G.affecting
	var/mob/living/carbon/human/assailant = G.assailant

	if(assailant.doing_something)
		return

	assailant.doing_something = TRUE
	affecting.visible_message("<span class='notice'>[assailant] is trying to pin [affecting] to the ground!</span>")

	if(!do_after(assailant, 30, affecting))
		assailant.doing_something = FALSE
		return

	if(!G.attacking && !affecting.lying)
		G.attacking = 1

		if(!assailant.statcheck(assailant.stats[STAT_ST] / 2 + 3) >= SUCCESS && do_mob(assailant, affecting, 30))

			G.attacking = 0
			G.action_used()
			affecting.Weaken(2)
			affecting.visible_message("<span class='notice'>[assailant] pins [affecting] to the ground!</span>")
			assailant.doing_something = FALSE
			return 1
		else
			affecting.visible_message("<span class='notice'>[assailant] fails to pin [affecting] to the ground.</span>")
			G.attacking = 0
			assailant.doing_something = FALSE
			return 0
	else
		assailant.doing_something = FALSE
		return 0

/datum/grab/special/self
	icon_state = "grabbed"