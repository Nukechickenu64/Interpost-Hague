/mob/living/carbon/human
	var/pony_flight_until = 0
	var/pony_next_flight = 0
	var/pony_flight_pass_flags = 0
	var/pony_flight_timer
	var/pony_floating_items = FALSE
	var/pony_next_kinesis = 0
	var/pony_next_kick = 0
	var/pony_next_thought = 0
	var/pony_previous_h_style
	var/pony_previous_f_style
	var/pony_appearance_saved = FALSE

/mob/living/carbon/human/proc/pony_organ_usable(var/tag)
	if(!istype(species, /datum/species/pony))
		return FALSE
	var/obj/item/organ/internal/organ = internal_organs_by_name[tag]
	var/organ_type = species.has_organ[tag]
	return organ_type && istype(organ, organ_type) && !QDELETED(organ) && organ.owner == src && organ.loc == src && organ.is_usable()

/mob/living/carbon/human/proc/pony_limb_usable(var/tag)
	var/obj/item/organ/external/limb = get_organ(tag)
	return limb && !limb.is_stump() && !(limb.status & (ORGAN_BROKEN | ORGAN_DEAD | ORGAN_CUT_AWAY | ORGAN_TENDON_CUT)) && !limb.is_dislocated() && limb.is_usable()

/mob/living/carbon/human/proc/pony_occupied_forehooves()
	if(pony_floating_items && pony_horn_usable())
		return 0
	return (l_hand && !istype(l_hand, /obj/item/tk_grab) ? 1 : 0) + (r_hand && !istype(r_hand, /obj/item/tk_grab) ? 1 : 0)

/mob/living/carbon/human/proc/pony_horn_usable()
	return istype(species, /datum/species/pony/unicorn) && pony_organ_usable("pony horn") && pony_organ_usable(BP_BRAIN) && pony_limb_usable(BP_HEAD) && !incapacitated() && !lying && isturf(loc) && staminaloss < 75 && fatigue < 90

/mob/living/carbon/human/can_use_telekinesis()
	return ..() || pony_horn_usable()

/mob/living/carbon/human/telekinesis_range()
	return (TK in mutations) ? ..() : 7

/mob/living/carbon/human/telekinetic_grab_type()
	return (TK in mutations) ? ..() : /obj/item/tk_grab/pony

/mob/living/carbon/human/proc/pony_kinesis_target_valid(var/atom/target)
	if(!target || QDELETED(target) || !(target in view(telekinesis_range(), src)) || (!isturf(target) && !isturf(target.loc)))
		return FALSE
	var/obj/object = target
	if(istype(object) && !object.anchored && !(TK in mutations))
		return object.w_class <= max(ITEM_SIZE_NORMAL, ITEM_SIZE_NORMAL + stat_to_modifier(stats[STAT_ST]))
	return TRUE

/mob/living/carbon/human/prepare_telekinesis(var/atom/target)
	if(TK in mutations)
		return ..()
	if(!pony_power_ready())
		return FALSE
	if(!pony_horn_usable())
		to_chat(src, "<span class='warning'>You need a healthy brain, head, and functioning unicorn horn.</span>")
		return FALSE
	if(!pony_kinesis_target_valid(target))
		to_chat(src, "<span class='warning'>Your horn cannot reach or lift that target.</span>")
		return FALSE
	if(world.time < pony_next_kinesis)
		to_chat(src, "<span class='warning'>Your horn needs a moment to refocus.</span>")
		return FALSE
	pony_next_kinesis = world.time + 1 SECOND
	adjustStaminaLoss(5)
	return statcheck(stats[STAT_IQ], 10 + round(get_dist(src, target) / 3), "Your telekinetic focus slips.", STAT_IQ)

/mob/living/carbon/human/proc/pony_release_grips()
	for(var/obj/item/tk_grab/grip in list(l_hand, r_hand))
		drop_from_inventory(grip)

/mob/living/carbon/human/proc/pony_power_ready()
	if(!istype(species, /datum/species/pony) || incapacitated() || lying || !isturf(loc) || !pony_organ_usable(BP_BRAIN) || !pony_limb_usable(BP_HEAD))
		to_chat(src, "<span class='warning'>You cannot use your Equestrian abilities in this condition.</span>")
		return FALSE
	if(staminaloss >= 75 || fatigue >= 90)
		to_chat(src, "<span class='warning'>You are too exhausted to focus your Equestrian abilities.</span>")
		return FALSE
	if(!canClick())
		to_chat(src, "<span class='warning'>You need a moment before acting again.</span>")
		return FALSE
	return TRUE

/mob/living/carbon/human/proc/pony_float_items()
	set name = "Float Carried Items"
	set category = "Abilities"
	if(pony_floating_items)
		pony_floating_items = FALSE
		to_chat(src, "<span class='notice'>You lower your carried items to your forehooves.</span>")
		return
	if(!pony_power_ready())
		return
	if(!pony_horn_usable())
		to_chat(src, "<span class='warning'>You need a functioning unicorn horn.</span>")
		return
	adjustStaminaLoss(5)
	if(!statcheck(stats[STAT_IQ], 10, "You cannot focus on your carried items.", STAT_IQ))
		return
	pony_floating_items = TRUE
	to_chat(src, "<span class='notice'>Your horn supports your carried items, freeing your forehooves for movement.</span>")

/mob/living/carbon/human/proc/pony_can_fly()
	if(!istype(species, /datum/species/pony/pegasus) || world.time >= pony_flight_until || incapacitated() || buckled || pinned.len || lying || staminaloss >= 75 || fatigue >= 90 || !pony_organ_usable("pony wings") || !pony_organ_usable(BP_BRAIN) || !pony_limb_usable(BP_HEAD) || !isturf(loc))
		return FALSE
	var/turf/T = loc
	var/datum/gas_mixture/air = T.return_air()
	return air && air.get_tile_moles() >= PRESSURE_TO_MOLES(85)

/mob/living/carbon/human/proc/pony_flight()
	set name = "Equestrian Flight"
	set category = "Abilities"
	if(pony_flight_until)
		pony_stop_flight()
		return
	if(!pony_power_ready())
		return
	if(!istype(species, /datum/species/pony/pegasus) || !pony_organ_usable("pony wings"))
		to_chat(src, "<span class='warning'>You need functioning wings to fly.</span>")
		return
	if(buckled || pinned.len)
		to_chat(src, "<span class='warning'>You cannot take flight while buckled or pinned.</span>")
		return
	var/turf/T = loc
	var/datum/gas_mixture/air = T.return_air()
	if(!air || air.get_tile_moles() < PRESSURE_TO_MOLES(85))
		to_chat(src, "<span class='warning'>There is not enough air for your wings to generate lift.</span>")
		return
	if(world.time < pony_next_flight)
		to_chat(src, "<span class='warning'>Your wings have not recovered from their last flight.</span>")
		return
	var/datum/species/pony/pony_species = species
	pony_next_flight = world.time + pony_species.flight_cooldown
	adjustStaminaLoss(10)
	if(!statcheck(stats[STAT_DX], 10, "You fail to coordinate your takeoff.", STAT_DX))
		return
	pony_flight_until = world.time + 3 SECONDS
	if(!pony_can_fly())
		pony_flight_until = 0
		to_chat(src, "<span class='warning'>You are too exhausted to take flight.</span>")
		return
	pony_flight_pass_flags = PASS_FLAG_TABLE & ~pass_flags
	pass_flags |= PASS_FLAG_TABLE
	visible_message("<span class='notice'>[src] takes flight!</span>")
	update_body()
	pony_flight_timer = addtimer(CALLBACK(src, /mob/living/carbon/human/proc/pony_stop_flight), 3 SECONDS, TIMER_STOPPABLE)

/mob/living/carbon/human/proc/pony_stop_flight()
	if(pony_flight_timer)
		deltimer(pony_flight_timer)
		pony_flight_timer = null
	if(!pony_flight_until)
		return
	pony_flight_until = 0
	pass_flags &= ~pony_flight_pass_flags
	pony_flight_pass_flags = 0
	update_body()
	fall()

/mob/living/carbon/human/proc/pony_hind_kick(var/mob/living/target as mob in view(1))
	set name = "Hind-leg Kick"
	set category = "Abilities"
	if(!pony_power_ready())
		return
	if(buckled || pinned.len)
		to_chat(src, "<span class='warning'>You cannot kick while buckled or pinned.</span>")
		return
	if(!istype(species, /datum/species/pony) || istype(species, /datum/species/pony/unicorn) || istype(species, /datum/species/pony/pegasus) || !pony_organ_usable("pony core"))
		to_chat(src, "<span class='warning'>You need a functioning Earth pony core.</span>")
		return
	for(var/tag in list(BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT))
		if(!pony_limb_usable(tag))
			to_chat(src, "<span class='warning'>You need both healthy hind legs to kick.</span>")
			return
	if(!target || QDELETED(target) || target == src || !isturf(target.loc) || !(target in view(1, src)) || !Adjacent(target))
		to_chat(src, "<span class='warning'>Your target must be beside you.</span>")
		return
	if(world.time < pony_next_kick)
		to_chat(src, "<span class='warning'>Your hind legs need time to recover.</span>")
		return
	pony_next_kick = world.time + 20 SECONDS
	setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	adjustStaminaLoss(15)
	if(!statcheck(stats[STAT_DX], 12, "Your hind-leg kick misses.", STAT_DX))
		return
	var/damage = max(1, rand(1, 6) + rand(1, 6) + stat_to_modifier(combat_strength()))
	var/armor = target.run_armor_check(BP_CHEST, "melee")
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.check_shields(damage, null, src, BP_CHEST, "hind-leg kick") || H.try_guard_block(src) || H.attempt_dodge(src))
			return
	set_dir(turn(get_dir(src, target), 180))
	do_attack_animation(target)
	visible_message("<span class='danger'>[src] kicks [target] with both hind legs!</span>")
	playsound(loc, "punch", 50, TRUE)
	target.apply_damage(damage, pulling_punches ? PAIN : BRUTE, BP_CHEST, armor)
	if(armor < 100 && statcheck(stats[STAT_ST], 12, null, STAT_ST))
		target.apply_effect(2, WEAKEN, armor)
		step(target, get_dir(src, target))
	log_attack("[key_name(src)] hind-leg kicked [key_name(target)] for [damage] damage.")

/mob/living/carbon/human/proc/pony_telepathy(var/mob/living/target as mob in view(7))
	set name = "Telepathic Communication"
	set category = "Abilities"
	if(!pony_power_ready())
		return
	var/obj/item/organ/internal/brain/pony/brain = internal_organs_by_name[BP_BRAIN]
	if(!istype(brain) || !brain.is_usable())
		to_chat(src, "<span class='warning'>You need a functioning Equestrian brain.</span>")
		return
	if(!target || target == src || target.stat == DEAD || !(target in view(7, src)))
		to_chat(src, "<span class='warning'>You need a living recipient within sight.</span>")
		return
	var/message = sanitize(input(src, "Project a thought to [target].", "Telepathy") as null|text)
	if(!message)
		return
	if(!pony_power_ready() || QDELETED(target) || target.stat == DEAD || !(target in view(7, src)) || QDELETED(brain) || !brain.is_usable() || internal_organs_by_name[BP_BRAIN] != brain)
		to_chat(src, "<span class='warning'>You have lost your connection to the recipient.</span>")
		return
	if(world.time < pony_next_thought)
		to_chat(src, "<span class='warning'>Your mind needs a moment to refocus.</span>")
		return
	pony_next_thought = world.time + 1 SECOND
	adjustStaminaLoss(3)
	if(!statcheck(stats[STAT_IQ], 10, "Your thought fails to reach the recipient.", STAT_IQ))
		return
	if(target.do_psionics_check(3, src))
		to_chat(src, "<span class='warning'>Something blocks your thought.</span>")
		return
	to_chat(target, "<span class='notice'><b>A voice echoes in your head:</b> \"[message]\"</span>")
	to_chat(src, "<span class='notice'>You project to [target]: \"[message]\"</span>")
	log_say("[key_name(src)] telepathically to [key_name(target)]: [message]")

/obj/item/tk_grab/pony/proc/valid_focus()
	var/mob/living/carbon/human/H = host
	return istype(H) && !QDELETED(H) && loc == H && (H.l_hand == src || H.r_hand == src) && H.can_use_telekinesis() && focus && !QDELETED(focus) && !focus.anchored && H.pony_kinesis_target_valid(focus)

/obj/item/tk_grab/pony/proc/release_focus()
	if(host && !QDELETED(host))
		to_chat(host, "<span class='warning'>You lose your telekinetic grip.</span>")
		host.drop_from_inventory(src)
	qdel(src)

/obj/item/tk_grab/pony/focus_object(var/obj/target, var/mob/living/user)
	..()
	if(!QDELETED(src) && focus)
		START_PROCESSING(SSobj, src)

/obj/item/tk_grab/pony/Process()
	if(!valid_focus())
		release_focus()
		return PROCESS_KILL
	var/mob/living/carbon/human/H = host
	if(!(TK in H.mutations))
		H.adjustStaminaLoss(1)
		if(!valid_focus())
			release_focus()
			return PROCESS_KILL

/obj/item/tk_grab/pony/attack_self(var/mob/user)
	if(user != host || !valid_focus())
		release_focus()
		return
	if(!user.prepare_telekinesis(focus))
		return
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	..()

/obj/item/tk_grab/pony/afterattack(var/atom/target, var/mob/living/user, var/proximity)
	if(user != host || !valid_focus())
		release_focus()
		return
	..()

/obj/item/tk_grab/pony/dropped(var/mob/user)
	STOP_PROCESSING(SSobj, src)
	..()

/obj/item/tk_grab/pony/Destroy()
	STOP_PROCESSING(SSobj, src)
	focus = null
	host = null
	return ..()
