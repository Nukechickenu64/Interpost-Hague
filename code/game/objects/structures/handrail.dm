/obj/structure/handrai
	name = "handrail"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "handrail"
	desc = "A safety railing with buckles to secure yourself to when floor isn't stable enough."
	density = 0
	anchored = 1
	can_buckle = 1

/obj/structure/handrai/attack_hand(mob/living/user)
	if(buckled_mob)
		user_unbuckle_mob(user)
	else if(isliving(user))
		user_buckle_mob(user, user)

/obj/structure/handrai/buckle_mob(mob/living/M)
	. = ..()
	if(.)
		playsound(src, 'sound/effects/buckle.ogg', 20)