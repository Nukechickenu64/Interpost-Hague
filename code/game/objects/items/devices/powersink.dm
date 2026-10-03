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
	return TRUE

/obj/item/device/powersink/Destroy()
	if(mode == 2)
		STOP_PROCESSING_POWER_OBJECT(src)
	. = ..()

/obj/item/device/powersink/attackby(var/obj/item/I, var/mob/user)
	if(isScrewdriver(I))
		if(mode == 0)
			if(!isturf(loc))
				return
			var/datum/power_node/N = get_power_node()
			if(!length(N.inputs))
				var/area/A = get_area(src)
				var/obj/machinery/power/area_smes/S = A && A.get_area_smes()
				if(S)
					link_power_nodes(S.get_power_node(), N)
			if(!length(N.inputs))
				to_chat(user, "There is no power feed here to clamp onto.")
				return
			anchored = 1
			mode = 1
			src.visible_message("<span class='notice'>[user] clamps [src] onto the local power feed!</span>")
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
	// found a powernet, so drain up to max power from it
	drained = PN.draw_power(drain_rate)
	// if tried to drain more than available on powernet
	// now look for area SMES units on the bus and drain their cells
	if(drained < drain_rate)
		for(var/obj/machinery/power/area_smes/A in PN.nodes)
			// Enough power drained this tick, no need to torture more units
			if(drained >= drain_rate)
				break
			if(A.operating && A.cell)
				var/cur_charge = A.cell.charge / CELLRATE
				var/drain_val = min(apc_drain_rate, cur_charge)
				A.cell.use(drain_val * CELLRATE)
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
	if(anchored && power_node)
		PN = power_node.in_net
	else
		PN = null
