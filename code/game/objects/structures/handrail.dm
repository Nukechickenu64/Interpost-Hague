/obj/structure/handrail
	name = "handrail"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "handrail"
	desc = "A safety railing with buckles to secure yourself to when floor isn't stable enough."
	buckle_action = "hold onto"
	buckle_action_third_person = "holds onto"
	unbuckle_action = "let go of"
	unbuckle_action_third_person = "lets go of"
	density = 0
	anchored = 1
	can_buckle = 1

/obj/structure/handrail/attack_hand(mob/living/user)
	if(buckled_mob)
		user_unbuckle_mob(user)
	else if(isliving(user))
		user_buckle_mob(user, user)

/obj/structure/handrail/buckle_mob(mob/living/M)
	. = ..()
	if(.)
		playsound(src, 'sound/effects/buckle.ogg', 20)

/obj/structure/handrai
	parent_type = /obj/structure/handrail