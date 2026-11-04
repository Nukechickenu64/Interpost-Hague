/proc/os13_computer_glow(icon_file, state)
	var/static/list/direct_states = list("tncr", "tnccs", "mtnc", "gtnc", "gbtnc", "RCT", "tnc1", "btnc1", "ctnc1", "comm", "econtrol", "econtrol2", "econtrol_mini0", "stnc", "scanner", "nco", "ncou")
	var/glow_state
	if(icon_file == 'icons/os13/objects/objects/computer.dmi')
		if(state in direct_states)
			glow_state = state
		else if(state == "econtrol_active")
			glow_state = "econtrol"
		else if(state == "econtrol2_active")
			glow_state = "econtrol2"
		else if(state == "econtrol_mini1" || state == "econtrol_mini2")
			glow_state = "econtrol_mini0"
	else if(icon_file == 'icons/os13/objects/objects/orbital_decor.dmi' && state == "scanner")
		glow_state = "scanner"
	else if(icon_file == 'icons/obj/computer.dmi' || icon_file == 'icons/obj/modular_console.dmi')
		// These aliases use the families in tools/dmitool/import_os13_computers.py.
		var/static/list/aliases = list(
			"generic" = "tnccs", "menu" = "tnccs", "dummy" = "tnccs",
			"comm" = "comm", "comm_monitor" = "tncr", "comm_logs" = "tncr",
			"crew" = "mtnc", "medcomp" = "mtnc", "medical" = "mtnc", "operating" = "mtnc",
			"dna" = "gtnc", "id" = "tnc1", "upload" = "tnc1", "pass" = "tnc1",
			"security" = "stnc", "explosive" = "stnc", "error" = "stnc",
			"syndie" = "stnc", "syndishuttle" = "stnc", "tcboss" = "stnc",
			"alert-red" = "stnc", "warrant" = "stnc", "hostile" = "stnc", "alarm_monitor" = "stnc",
			"robot" = "btnc1", "mecha" = "btnc1", "ai-fixer" = "btnc1",
			"ai-fixer-empty" = "btnc1", "ai-fixer-full" = "btnc1", "shield" = "btnc1", "bsod" = "btnc1",
			"solar" = "gbtnc", "power" = "gbtnc", "power_screen" = "gbtnc", "solar_screen" = "gbtnc",
			"power_monitor" = "gbtnc", "power_monitor_warn" = "stnc",
			"turbinecomp" = "RCT", "engines" = "RCT", "engine" = "RCT", "fuel_screen" = "RCT", "rust_screen" = "RCT",
			"gyrotron_screen" = "ctnc1", "rdcomp" = "ctnc1", "research" = "ctnc1",
			"entertainment" = "ctnc1", "game" = "ctnc1",
			"alert:0" = "tnc1", "alert:1" = "gbtnc", "alert:2" = "stnc", "alert-green" = "tnc1",
			"smmon_0" = "tnc1", "smmon_1" = "tnc1", "smmon_2" = "tnc1", "smmon_3" = "gbtnc",
			"smmon_4" = "stnc", "smmon_5" = "stnc", "smmon_6" = "stnc")
		if(findtext(state, "os13_") == 1)
			glow_state = aliases[copytext(state, 6)]
		else if(state == "power" || state == "solar")
			glow_state = "gbtnc"
		else if(state == "power_alert")
			glow_state = "stnc"
	if(glow_state)
		return overlay_image('icons/os13/objects/objects/computer_overlay.dmi', glow_state, plane = ABOVE_LIGHTING_PLANE, layer = ABOVE_LIGHTING_LAYER)

/obj/machinery/computer
	name = "computer"
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = 1
	anchored = 1.0
	idle_power_usage = 300
	active_power_usage = 300
	var/circuit = null // The circuit board type used to construct this console.
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
			set_broken(TRUE)
		if(2.0)
			if(prob(25) || prob(50))
				set_broken(TRUE)
		if(3.0)
			if (prob(25))
				set_broken(TRUE)

/obj/machinery/computer/acid_melt()
	set_broken(TRUE)
	return TRUE

/obj/machinery/computer/dismantle()
	visible_message(SPAN_WARNING("\The [src] cannot be dismantled."))
	return FALSE

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
			add_os13_emissive()
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
	add_os13_emissive()

/obj/machinery/computer/proc/add_os13_emissive()
	if(stat & (NOPOWER|BROKEN))
		return
	var/image/glow = os13_computer_glow(icon, icon_state)
	if(glow)
		overlays += glow

/obj/machinery/computer/proc/decode(text)
	// Adds line breaks
	text = replacetext(text, "\n", "<BR>")
	return text

/obj/machinery/computer/attackby(I as obj, user as mob)
	if(isScrewdriver(I))
		to_chat(user, SPAN_WARNING("\The [src] cannot be dismantled. Repair broken glass with a FixBoy-2000 and one zbrite bar."))
	else
		..()

/obj/machinery/computer/attack_ghost(var/mob/ghost)
	attack_hand(ghost)

/obj/machinery/computer/retro //same shit but cooler
	name = "computer"
	icon = 'icons/obj/computer.dmi'
	icon_state = "retrosmall"
