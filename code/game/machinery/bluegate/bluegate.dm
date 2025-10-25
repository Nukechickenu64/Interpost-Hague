/obj/machinery/bluegate
	name = "Bluespace gateway chamber"
	desc = "Nobody on the station would know how exactly this works, better not break it."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "sleeper_0"
	density = 1
	anchored = 1
	clicksound = 'sound/machines/buttonbeep.ogg'
	clickvol = 30
	var/mob/living/carbon/human/occupant = null
	var/obj/item/weapon/reagent_containers/glass/beaker = null

	idle_power_usage = 15
	active_power_usage = 1000 //builtin health analyzer, dialysis machine, injectors.

/obj/machinery/bluegate/Initialize()
	. = ..()
	update_icon()

/obj/machinery/bluegate/Process()
	if(stat & (NOPOWER|BROKEN))
		return

/obj/machinery/bluegate/update_icon()
	icon_state = "sleeper_[occupant ? "1" : "0"]"

/obj/machinery/bluegate/attack_hand(var/mob/user)
	if(stat & (NOPOWER|BROKEN))
		return
	if(user == occupant)
		if(occupant.isblue)
			to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The interior computer's nearly burned out screen shows you the following commands:</span>\n<span class='feedback'><a href='?src=\ref[src];action=fuel;align='right'>CHECK FUEL</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=activate;align='right'>DEACTIVATE TRANSFORMATION</a></span></div></div>")
		else
			to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The interior computer's nearly burned out screen shows you the following commands:</span>\n<span class='feedback'><a href='?src=\ref[src];action=fuel;align='right'>CHECK FUEL</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=activate;align='right'>ACTIVATE TRANSFORMATION</a></span></div></div>")
	else
		to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The computer's nearly burned out screen shows you the following commands:</span>\n<hr><span class='feedback'><a href='?src=\ref[src];action=eject;align='right'>EJECT SUBJECT</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=beaker;align='right'>EJECT BEAKER</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=fuel;align='right'>CHECK FUEL</a></span></div></div>")

/obj/machinery/bluegate/Topic(href, href_list, hsrc)
	if(get_dist(src, usr) > 1)
		return
	switch(href_list["action"])
		if("eject")
			go_out()

		if("beaker")
			remove_beaker()

		if("fuel")
			if(!beaker)
				to_chat(usr, "<span class='warning'>There is no beaker in the sleeper.</span>")
				return TOPIC_REFRESH
			else
				visible_message("there's [beaker.reagents.total_volume] units of fuel left.")

		if("activate")
			if(!occupant)
				to_chat(usr, "<span class='warning'>There is no occupant in the sleeper.</span>")

			if(stat & (NOPOWER|BROKEN))
				to_chat(usr, "<span class='warning'>The [src] is not powered.</span>")
			else

				if(!beaker || !beaker.reagents.get_reagent_amount(/datum/reagent/toxin/phoron) || beaker.reagents.get_reagent_amount(/datum/reagent/toxin/phoron) < 100)
					to_chat(usr, "<span class='warning'>There is not enough phoron fuel in the beaker.</span>")
					return TOPIC_REFRESH
				else
					for(var/obj/item/bad in occupant.contents)
						if(!istype(bad,/obj/item/organ))
							to_chat(occupant, "<span class='warning'>There must be no items on subject.</span>")
							return
					beaker.reagents.remove_reagent(/datum/reagent/toxin/phoron, 100)
					if(!occupant.isblue)
						occupant.phantomize_blue()
						use_power_oneoff(active_power_usage,POWER_CHAN, TRUE)
						visible_message("\The [occupant] slowly materializes out of the phantom state.")
					else
						occupant.phantomize_blue()
						use_power_oneoff(active_power_usage, POWER_CHAN, TRUE)
						visible_message("\The [occupant] slowly fades into a phantom state.")

/obj/item/weapon/reagent_containers/glass/beaker/phoron
	name = "phoron beaker"
	desc = "A beaker filled with highly concentrated phoron fuel."

obj/item/weapon/reagent_containers/glass/beaker/phoron/New()
	reagents = new()
	reagents.add_reagent(/datum/reagent/toxin/phoron, 500)

/obj/machinery/bluegate/attack_ai(var/mob/user)
	return attack_hand(user)

/obj/machinery/bluegate/attackby(var/obj/item/I, var/mob/user)
	if(istype(I, /obj/item/weapon/reagent_containers/glass))
		add_fingerprint(user)
		if(!beaker)
			beaker = I
			user.drop_item()
			I.forceMove(src)
			user.visible_message("<span class='notice'>\The [user] adds \a [I] to \the [src].</span>", "<span class='notice'>You add \a [I] to \the [src].</span>")
		else
			to_chat(user, "<span class='warning'>\The [src] has a beaker already.</span>")
		return
	else
		..()

/obj/machinery/bluegate/MouseDrop_T(var/mob/target, var/mob/user)
	if(!CanMouseDrop(target, user))
		return
	if(!istype(target))
		return
	if(target.buckled)
		to_chat(user, "<span class='warning'>Unbuckle the subject before attempting to move them.</span>")
		return
	go_in(target, user)

/obj/machinery/bluegate/relaymove(var/mob/user)
	..()
	go_out()


/obj/machinery/bluegate/proc/go_in(var/mob/M, var/mob/user)
	if(!M)
		return
	if(stat & (BROKEN|NOPOWER))
		return
	if(occupant)
		to_chat(user, "<span class='warning'>\The [src] is already occupied.</span>")
		return

	if(M == user)
		visible_message("\The [user] starts climbing into \the [src].")
	else
		visible_message("\The [user] starts putting [M] into \the [src].")

	if(do_after(user, 20, src))
		if(occupant)
			to_chat(user, "<span class='warning'>\The [src] is already occupied.</span>")
			return
		M.stop_pulling()
		if(M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.forceMove(src)
		occupant = M
		update_icon()

/obj/machinery/bluegate/proc/go_out()
	if(!occupant)
		return
	if(occupant.client)
		occupant.client.eye = occupant.client.mob
		occupant.client.perspective = MOB_PERSPECTIVE
	occupant.dropInto(loc)
	occupant = null
	for(var/atom/movable/A in src) // In case an object was dropped inside or something
		if(A == beaker)
			continue
		A.dropInto(loc)
	update_use_power(POWER_USE_IDLE)
	update_icon()

/obj/machinery/bluegate/proc/remove_beaker()
	if(beaker)
		beaker.dropInto(loc)
		beaker = null

/mob/living/carbon/human
	var/isblue = FALSE

/mob/living/carbon/human/attack_hand(mob/living/carbon/M)
	. = ..()


/mob/living/carbon/human/equip_to_slot(obj/item/W, slot, redraw_mob)

/mob/living/carbon/human/proc/phantomize_blue()
	if(isblue)
		isblue = FALSE
		density = 1
		alpha = 255
		plane = DEFAULT_PLANE
		invisibility = 0
		see_invisible = 0
		sight = SEE_TURFS|SEE_SELF|SEE_BLACKNESS
		simulated = TRUE
	isblue = TRUE
	density = 0
	alpha = 127
	plane = OBSERVER_PLANE
	invisibility = INVISIBILITY_OBSERVER
	see_invisible = SEE_INVISIBLE_OBSERVER
	sight = SEE_TURFS|SEE_SELF|SEE_BLACKNESS
	simulated = FALSE

/obj/machinery/bluegate/Destroy()
	if(occupant)
		go_out()
	. = ..()

	/obj/concept
		name = "thought wave"
		desc = "A wave of pure thought energy."

	/obj/concept/grief
		name = "Grief"
		desc = "A wave of pure thought energy filled with sorrow and despair."

	/obj/concept/fullfillment
		name = "Fulfillment"
		desc = "A wave of pure thought energy filled with joy and satisfaction."


	/obj/item/weapon/bluescanner
		name = "bluespace scanner"
		desc = "A handheld device used to detect and store bluespace anomaly data within a disk. powered by bluespace itself, handy."

/obj/machinery/phaser
	name = "Bluespace phaser"
	desc = "Nobody on the station would know how exactly this works, better not break it."
	icon = 'icons/obj/modular_console.dmi'
	icon_state = "cs_db"
	density = 1
	anchored = 1
	clicksound = 'sound/machines/buttonbeep.ogg'
	clickvol = 30

	idle_power_usage = 15
	active_power_usage = 1000


/obj/machinery/phaser/attackby(obj/item/O, mob/user)
	if(O.invisibility == INVISIBILITY_OBSERVER)
		use_power_oneoff(active_power_usage)
		O.invisibility = 0
		visible_message("\the [O] Reappears into ordinary existance!")
		user.drop_item(O)
	else
		O.invisibility == INVISIBILITY_OBSERVER
		visible_message("\the [O] Disappears")
		use_power_oneoff(active_power_usage)
		user.drop_item(O)