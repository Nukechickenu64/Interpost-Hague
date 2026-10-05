// A hand clamped over someone's mouth. The victim cannot speak, and gets a bite hold on the covering hand.
/obj/item/grab/mouth_cover
	type_name = GRAB_MOUTH_COVER
	start_grab_name = GRAB_MOUTH_COVER
	name = "mouth grab"
	var/hand_zone
	var/obj/item/grab/mouth/counter_bite
	var/counter_bite_given = FALSE

/obj/item/grab/mouth_cover/pre_check()
	if(!..())
		return FALSE
	if(!affecting.check_has_mouth())
		to_chat(assailant, "<span class='combat'>I cannot locate a mouth on [affecting]!</span>")
		return FALSE
	return TRUE

/obj/item/grab/mouth_cover/init()
	hand_zone = assailant.hand ? BP_L_HAND : BP_R_HAND
	..()
	if(QDELETED(src))
		return
	if(affecting.w_uniform)
		affecting.w_uniform.add_fingerprint(assailant)
	assailant.put_in_active_hand(src)
	assailant.do_attack_animation(affecting)
	playsound(affecting.loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
	visible_message("<span class='combatbold'>[assailant] clamps \his hand over [affecting]'s mouth!</span>")
	affecting.grabbed_by += src
	silence_victim()
	give_counter_bite()

/obj/item/grab/mouth_cover/Destroy()
	var/obj/item/grab/mouth/bite = counter_bite
	counter_bite = null
	if(bite && !QDELETED(bite))
		bite.linked_grab = null
		if(bite.assailant)
			bite.assailant.drop_from_inventory(bite)
		if(!QDELETED(bite))
			qdel(bite)
	return ..()

/obj/item/grab/mouth_cover/proc/silence_victim()
	if(affecting && affecting.silent < 3)
		affecting.silent = 3

/obj/item/grab/mouth_cover/proc/give_counter_bite()
	if(counter_bite_given || !assailant || !affecting)
		return
	if(affecting.stat || affecting.wear_mask || !affecting.check_has_mouth() || affecting.check_mouth_coverage())
		return
	var/obj/item/organ/external/hand = assailant.get_organ(hand_zone)
	if(!hand || hand.is_stump())
		return
	var/obj/item/organ/external/head/head = affecting.get_organ(BP_HEAD)
	if(!head || !head.get_teeth())
		return
	var/obj/item/grab/mouth/bite = new(affecting, assailant, hand_zone)
	bite.linked_grab = src
	if(!bite.pre_check() || !bite.can_grab())
		bite.linked_grab = null
		qdel(bite)
		return
	counter_bite_given = TRUE
	counter_bite = bite
	bite.init()
	if(QDELETED(bite))
		counter_bite = null

/datum/grab/special/mouth_cover
	type_name = GRAB_MOUTH_COVER
	state_name = GRAB_MOUTH_COVER
	fancy_desc = "covering the mouth of"
	icon_state = "grabbed"
	can_absorb = 0
	force_danger = 0
	break_chance_table = list(5, 20, 40, 80, 100)

/datum/grab/special/mouth_cover/attack_self_act(var/obj/item/grab/mouth_cover/G)
	if(!G || !G.assailant || !G.affecting)
		return
	G.assailant.visible_message("<span class='notice'>[G.assailant] takes \his hand off [G.affecting]'s mouth.</span>")
	let_go(G)

/datum/grab/special/mouth_cover/process_effect(var/obj/item/grab/mouth_cover/G)
	G.silence_victim()
	G.give_counter_bite()

/mob/living/carbon/human/proc/get_mouth_cover_grab()
	for(var/obj/item/grab/mouth_cover/G in grabbed_by)
		if(!QDELETED(G) && G.assailant && G.affecting == src)
			return G
	return null
