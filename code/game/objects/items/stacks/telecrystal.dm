/obj/item/stack/telecrystal
	name = "telecrystal"
	desc = "It seems to be pulsing with suspiciously enticing energies."
	description_antag = "Crush a crystal to make a short-range teleportation jump."
	singular_name = "telecrystal"
	icon = 'icons/obj/telescience.dmi'
	icon_state = "telecrystal"
	w_class = ITEM_SIZE_TINY
	max_amount = 50
	item_flags = ITEM_FLAG_NO_BLUDGEON
	origin_tech = list(TECH_MATERIAL = 6, TECH_BLUESPACE = 4)

/obj/item/stack/telecrystal/attack_self(var/mob/user)
	if(use(5))
		user.visible_message("<span class='warning'>\The [user] crushes a crystal!</span>", "<span class='warning'>You crush \a [src]!</span>", "You hear the sound of a crystal breaking just before a sudden crack of electricity.")
		var/turf/T = get_random_turf_in_range(user, 7, 3)
		if(T)
			user.phase_out(T, get_turf(user))
			user.forceMove(T)
			user.phase_in(T, get_turf(user))
