/obj/item/mop
	desc = "The world of janitalia wouldn't be complete without a mop."
	name = "mop"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mop"
	force = 5
	throwforce = 10.0
	throw_speed = 5
	throw_range = 10
	w_class = ITEM_SIZE_NORMAL
	obj_flags = OBJ_FLAG_NO_EMBED // no
	attack_verb = list("mopped", "bashed", "bludgeoned", "whacked")
	var/mopping = 0
	var/mopcount = 0

/obj/item/mop/New()
	create_reagents(30)

/obj/item/mop/afterattack(atom/A, mob/user, proximity)
	if(!proximity)
		return

	var/moppable
	if(istype(A, /turf))
		var/turf/T = A
		if(T.liquids)
			if(T.liquids.liquid_state > 1)
				to_chat(user, SPAN_WARNING("There is too much liquid here to mop up."))
				return
			if(reagents.get_free_space() < 1)
				to_chat(user, SPAN_WARNING("Your mop is saturated. Wring it into a bucket on harm intent first."))
				return
			user.visible_message(SPAN_NOTICE("\The [user] begins to mop up \the [T]."))
			if(do_after(user, max(10, 100 - user.skills["cleaning"]), T) && T.liquids)
				if(T.liquids.liquid_state > 1)
					to_chat(user, SPAN_WARNING("There is too much liquid here to mop up."))
					return
				var/collected = T.liquids.take_reagents(reagents, reagents.get_free_space())
				if(collected && (reagents.has_reagent(/datum/reagent/water, 1) || reagents.has_reagent(/datum/reagent/space_cleaner, 1)))
					T.clean_blood()
					T.remove_cleanables()
				to_chat(user, SPAN_NOTICE("You mop up [round(collected, 0.1)] units of liquid."))
			return
		var/obj/effect/fluid/F = locate() in T
		if(F && F.fluid_amount > 0)
			if(F.fluid_amount > FLUID_SHALLOW)
				to_chat(user, SPAN_WARNING("There is too much water here to be mopped up."))
			else
				user.visible_message("<span class='notice'>\The [user] begins to mop up \the [T].</span>")
				if(do_after(user, 40, T) && F && !QDELETED(F))
					if(F.fluid_amount > FLUID_SHALLOW)
						to_chat(user, SPAN_WARNING("There is too much water here to be mopped up."))
					else
						qdel(F)
						to_chat(user, "<span class='notice'>You have finished mopping!</span>")
			return
		moppable = TRUE

	if(moppable)
		if(reagents.total_volume < 1)
			to_chat(user, "<span class='notice'>Your mop is dry!</span>")
			return
		var/turf/T = get_turf(A)
		if(!T)
			return

		user.visible_message("<span class='warning'>\The [user] begins to clean \the [T].</span>")

		var/delay = 100 - user.skills["cleaning"] //Better at cleaning, you mop faster
		if(do_after(user, delay, T))
			if(T)
				T.clean(src, user)
			to_chat(user, "<span class='notice'>You have finished mopping!</span>")

/obj/effect/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/mop) || istype(I, /obj/item/soap))
		return
	..()
