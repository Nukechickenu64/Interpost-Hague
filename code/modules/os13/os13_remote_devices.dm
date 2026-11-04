// The archived research catalogue defines Advanced FixBoy as remote access to
// atmospherics machinery. Reuse the real Modcon commands and dialog sequence.
/obj/item/device/fixboy/advanced
	name = "Advanced FixBoy"
	desc = "A FixBoy with remote Modcon access. Hold it to select an unlocked station controller with remote control enabled. Engineering diagnostics and console repairs remain available by using it on nearby machinery."
	icon_state = "fixboy2"
	matter = list("steel" = 1000, "glass" = 1000)

/obj/item/device/fixboy/advanced/proc/can_operate(mob/user)
	return !QDELETED(src) && user && !user.incapacitated() && loc == user && (user.get_active_hand() == src || user.get_inactive_hand() == src) && is_station_turf(get_turf(user))

/obj/item/device/fixboy/advanced/proc/can_control(mob/user, obj/machinery/alarm/controller)
	return can_operate(user) && !QDELETED(controller) && is_station_turf(get_turf(controller)) && controller.alarm_area && controller.alarm_area.master_air_alarm == controller && controller.buildstage == 2 && !controller.shorted && !controller.locked && controller.rcon_setting != RCON_NO && !(controller.stat & (NOPOWER|BROKEN)) && controller.powered() && controller.allowed(user)

/obj/item/device/fixboy/advanced/proc/controllers(mob/user)
	var/list/result = list()
	if(!can_operate(user))
		return result
	for(var/obj/machinery/alarm/controller in SSmachines.machinery)
		if(can_control(user, controller))
			var/label = "[controller.alarm_area.name] ([controller.x],[controller.y], deck [controller.z])"
			result[label] = controller
	return result

/obj/item/device/fixboy/advanced/proc/send_command(mob/user, obj/machinery/alarm/controller, list/command)
	if(!can_control(user, controller))
		to_chat(user, SPAN_WARNING("The remote Modcon connection is no longer available."))
		return FALSE
	return controller.apply_modcon_action(user, command, remote = src)

/obj/item/device/fixboy/advanced/attack_self(mob/user)
	if(!can_operate(user))
		to_chat(user, SPAN_WARNING("Hold the Advanced FixBoy aboard the station to use it."))
		return
	var/selection = input(user, "Select a function.", "Advanced FixBoy") as null|anything in list("Remote Atmospherics", "Station Power Report")
	if(!(selection in list("Remote Atmospherics", "Station Power Report")) || !can_operate(user))
		return
	if(selection == "Station Power Report")
		return ..()
	var/list/available = controllers(user)
	if(!available.len)
		to_chat(user, SPAN_WARNING("No authorized, unlocked station Modcon is available for remote control."))
		return
	var/choice = input(user, "Select a Modcon.", "Advanced FixBoy") as null|anything in available
	if(!choice)
		return
	var/obj/machinery/alarm/controller = available[choice]
	if(!can_control(user, controller))
		to_chat(user, SPAN_WARNING("The selected Modcon is no longer available."))
		return
	var/datum/engineering_atmos_menu/os13_fixboy/menu = new(src, user, controller)
	menu.interact()
	qdel(menu)

/datum/engineering_atmos_menu/os13_fixboy
	var/obj/item/device/fixboy/advanced/device

/datum/engineering_atmos_menu/os13_fixboy/New(obj/item/device/fixboy/advanced/new_device, mob/new_user, obj/machinery/alarm/new_controller)
	..(new_controller, new_user)
	device = new_device

/datum/engineering_atmos_menu/os13_fixboy/Destroy()
	device = null
	return ..()

/datum/engineering_atmos_menu/os13_fixboy/available(require_access = FALSE)
	return !QDELETED(device) && device.can_control(user, controller)

/datum/engineering_atmos_menu/os13_fixboy/apply_command(list/command)
	return !QDELETED(device) && device.send_command(user, controller, command)

/datum/design/item/os13_advanced_fixboy
	name = "Advanced FixBoy"
	id = "os13_advanced_fixboy"
	req_tech = list(TECH_ENGINEERING = 2, TECH_DATA = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 1000)
	build_path = /obj/item/device/fixboy/advanced
	sort_string = "VAACDR"

// RemCom Device: the source catalogue describes remote Bridge access.
/obj/item/device/os13_remcom
	name = "RemCom Device"
	desc = "A handheld station command terminal. Hold it to connect to an operational bridge computer using your command keycard."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "Pipboy"
	item_state = "multitool"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_SMALL
	slot_flags = SLOT_BELT
	matter = list("steel" = 1000, "glass" = 1000)

/obj/item/device/os13_remcom/proc/can_connect(mob/user, obj/machinery/computer/bridge/bridge)
	return !QDELETED(src) && istype(GLOB.using_map, /datum/map/alpha) && user && !user.incapacitated() && loc == user && (user.get_active_hand() == src || user.get_inactive_hand() == src) && is_station_turf(get_turf(user)) && !QDELETED(bridge) && (bridge in SSmachines.machinery) && is_station_turf(get_turf(bridge)) && bridge.operable() && bridge.powered() && bridge.os13_command_authorized(user)

/obj/item/device/os13_remcom/proc/commands()
	return list("General Report", "Today Reports", "Approved Documents", "Erase Approved Documents", "Toggle Salvage Permission", "Shield Coverage", "Toggle Shields")

/obj/item/device/os13_remcom/proc/perform(mob/user, obj/machinery/computer/bridge/bridge, action)
	if(!can_connect(user, bridge) || !(action in commands()))
		to_chat(user, SPAN_WARNING("Bridge connection unavailable. Hold the RemCom Device with command authorization and reconnect."))
		return FALSE
	switch(action)
		if("General Report")
			bridge.os13_show_general_report(user, src)
		if("Today Reports")
			bridge.os13_show_reports(user, src)
		if("Approved Documents")
			bridge.os13_show_documents(user, src)
		if("Erase Approved Documents")
			bridge.os13_erase_documents(user, src)
		if("Toggle Salvage Permission")
			bridge.os13_toggle_salvage(user, src)
		if("Shield Coverage")
			bridge.os13_control_shields(user, "os13_shield_direction", src)
		if("Toggle Shields")
			bridge.os13_control_shields(user, "os13_shield_toggle", src)
	return TRUE

/obj/item/device/os13_remcom/attack_self(mob/user)
	var/list/bridges = list()
	for(var/obj/machinery/computer/bridge/bridge in SSmachines.machinery)
		if(can_connect(user, bridge))
			bridges["[bridge.name] ([bridge.x],[bridge.y], deck [bridge.z])"] = bridge
	if(!bridges.len)
		to_chat(user, SPAN_WARNING("No authorized bridge connection is available. Hold the RemCom Device aboard the station with a command keycard."))
		return
	var/selection = input(user, "Select a bridge computer.", "RemCom Device") as null|anything in bridges
	if(!selection)
		return
	var/obj/machinery/computer/bridge/bridge = bridges[selection]
	if(!can_connect(user, bridge))
		return
	var/action = input(user, "Select a bridge command.", "RemCom Device") as null|anything in commands()
	if(action)
		perform(user, bridge, action)

/datum/design/item/os13_remcom
	name = "RemCom Device"
	id = "os13_remcom"
	req_tech = list(TECH_ENGINEERING = 3, TECH_DATA = 3)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 1000)
	build_path = /obj/item/device/os13_remcom
	sort_string = "VAACDS"
