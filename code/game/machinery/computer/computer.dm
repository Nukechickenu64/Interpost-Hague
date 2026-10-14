/obj/machinery/computer
	name = "computer"
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = 1
	anchored = 1.0
	idle_power_usage = 300
	active_power_usage = 300
	var/circuit = null //The path to the circuit board type. If circuit==null, the computer can't be disassembled.
	var/processing = 0

	var/icon_keyboard = "generic_key"
	var/icon_screen = "generic"
	var/light_range_on = 2
	var/light_power_on = 1
	var/overlay_layer
	var/base_icon_state
	atom_flags = ATOM_FLAG_CLIMBABLE
	clicksound = "truekeyboard"

/obj/machinery/computer/New()
	overlay_layer = layer
	base_icon_state = icon_state
	..()

/obj/machinery/computer/Initialize()
	. = ..()
	power_change()
	update_icon()

/obj/machinery/computer/emp_act(severity)
	if(prob(20/severity)) set_broken(TRUE)
	..()

/obj/machinery/computer/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(25))
				qdel(src)
				return
			if (prob(50))
				for(var/x in verbs)
					verbs -= x
				set_broken(TRUE)
		if(3.0)
			if (prob(25))
				for(var/x in verbs)
					verbs -= x
				set_broken(TRUE)

/obj/machinery/computer/bullet_act(var/obj/item/projectile/Proj)
	if(prob(Proj.get_structure_damage()))
		set_broken(TRUE)
	..()

/obj/machinery/computer/update_icon()
	overlays.Cut()
	icon_state = base_icon_state
	// OS13 states include the casing and keyboard, so do not add legacy overlays.
	if(icon == 'icons/obj/computer.dmi')
		var/full_state
		switch(base_icon_state)
			if("computer", "retrosmall")
				full_state = "os13_[icon_screen]"
			if("oldcomp")
				full_state = "os13_retro"
			if("laptop")
				full_state = "os13_laptop"
			if("guest")
				full_state = "os13_pass"
			if("tcstation")
				full_state = "os13_syndie"
		if(full_state && (full_state in icon_states(icon)))
			if(stat & NOPOWER)
				icon_state = "[full_state]_off"
				set_light(0)
			else
				icon_state = (stat & BROKEN) ? "[full_state]_broken" : full_state
				set_light(light_range_on, light_power_on)
			return

	if(stat & NOPOWER)
		set_light(0)
		if("[base_icon_state]_off" in icon_states(icon))
			icon_state = "[base_icon_state]_off"
		if(icon_keyboard)
			overlays += image(icon,"[icon_keyboard]_off", overlay_layer)
		return
	else
		set_light(light_range_on, light_power_on)

	if(stat & BROKEN)
		overlays += image(icon,"[icon_state]_broken", overlay_layer)
	else
		overlays += image(icon,icon_screen, overlay_layer)

	if(icon_keyboard)
		overlays += image(icon, icon_keyboard, overlay_layer)

/obj/machinery/computer/proc/decode(text)
	// Adds line breaks
	text = replacetext(text, "\n", "<BR>")
	return text

/obj/machinery/computer/attackby(I as obj, user as mob)
	if(isScrewdriver(I) && circuit)
		playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
		if(do_after(user, 20, src))
			var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
			var/obj/item/circuitboard/M = new circuit( A )
			A.circuit = M
			A.anchored = 1
			for (var/obj/C in src)
				C.dropInto(loc)
			if (src.stat & BROKEN)
				to_chat(user, "<span class='notice'>The broken glass falls out.</span>")
				new /obj/item/weapon/material/shard( src.loc )
				A.state = 3
				A.icon_state = "3"
			else
				to_chat(user, "<span class='notice'>You disconnect the monitor.</span>")
				A.state = 4
				A.icon_state = "4"
			M.deconstruct(src)
			qdel(src)
	else
		..()

/obj/machinery/computer/attack_ghost(var/mob/ghost)
	attack_hand(ghost)

/obj/machinery/computer/retro //same shit but cooler
	name = "computer"
	icon = 'icons/obj/computer.dmi'
	icon_state = "retrosmall"
