// Powersink - used to drain station power

/obj/item/device/powersink
	name = "power sink"
	desc = "A nulling power sink which drains energy from electrical systems."
	icon_state = "powersink0"
	item_state = "electronic"
	w_class = ITEM_SIZE_LARGE
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	throwforce = 5
	throw_speed = 1
	throw_range = 2

	matter = list(DEFAULT_WALL_MATERIAL = 750,"waste" = 750)

	origin_tech = list(TECH_POWER = 3, TECH_ILLEGAL = 5)
	var/drain_rate = 1500000		// amount of power to drain per tick
	var/apc_drain_rate = 5000 		// Max. amount drained from single APC. In Watts.
	var/dissipation_rate = 20000	// Passive dissipation of drained power. In Watts.
	var/power_drained = 0 			// Amount of power drained.
	var/max_power = 5e9				// Detonation point.
	var/mode = 0					// 0 = off, 1=clamped (off), 2=operating
	var/drained_this_tick = 0		// This is unfortunately necessary to ensure we process powersinks BEFORE other machinery such as APCs.

	var/datum/powernet/PN			// Our input bus

/obj/item/device/powersink/is_power_linkable()
	return FALSE

/obj/item/device/powersink/Destroy()
	if(mode == 2)
		STOP_PROCESSING_POWER_OBJECT(src)
	. = ..()

/obj/item/device/powersink/attackby(var/obj/item/I, var/mob/user)
	if(isScrewdriver(I))
		if(mode == 0)
			if(!isturf(loc))
				return
			if(!isStationLevel(z))
				to_chat(user, "There is no station power feed here to clamp onto.")
				return
			anchored = 1
			mode = 1
			PN = power_net
			src.visible_message("<span class='notice'>[user] clamps [src] onto the station power grid!</span>")
			return
		else
			if (mode == 2)
				STOP_PROCESSING_POWER_OBJECT(src)
			anchored = 0
			mode = 0
			src.visible_message("<span class='notice'>[user] detaches [src] from the power feed!</span>")
			set_light(0)
			icon_state = "powersink0"

			return
	else
		..()

/obj/item/device/powersink/attack_ai()
	return

/obj/item/device/powersink/attack_hand(var/mob/user)
	switch(mode)
		if(0)
			..()
		if(1)
			src.visible_message("<span class='notice'>[user] activates [src]!</span>")
			mode = 2
			icon_state = "powersink1"
			START_PROCESSING_POWER_OBJECT(src)
		if(2)  //This switch option wasn't originally included. It exists now. --NeoFite
			src.visible_message("<span class='notice'>[user] deactivates [src]!</span>")
			mode = 1
			set_light(0)
			icon_state = "powersink0"
			STOP_PROCESSING_POWER_OBJECT(src)

/obj/item/device/powersink/pwr_drain()
	if(!anchored)
		return 0

	if(drained_this_tick)
		return 1
	drained_this_tick = 1

	var/drained = 0

	if(!PN)
		return 1

	set_light(12)
	PN.trigger_warning()
	// found the grid, so drain up to max power from it
	drained = PN.draw_power(drain_rate)
	// if tried to drain more than the grid could give, drain the station SMES storage pool instead
	if(drained < drain_rate)
		for(var/obj/machinery/power/smes/S in PN.storage)
			// Enough power drained this tick, no need to torture more units
			if(drained >= drain_rate)
				break
			var/cur_charge = S.charge / CELLRATE
			var/drain_val = min(apc_drain_rate, cur_charge)
			S.remove_charge(drain_val)
			drained += drain_val
	power_drained += drained
	return 1


/obj/item/device/powersink/Process()
	drained_this_tick = 0
	power_drained -= min(dissipation_rate, power_drained)
	if(power_drained > max_power * 0.95)
		playsound(src, 'sound/effects/screech.ogg', 100, 1, 1)
	if(power_drained >= max_power)
		explosion(src.loc, 3,6,9,12)
		qdel(src)
		return
	if(anchored && isStationLevel(z))
		PN = power_net
	else
		PN = null
