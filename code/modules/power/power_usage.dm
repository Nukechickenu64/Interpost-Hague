/*
This is /obj/machinery level code to properly manage power usage from the area.
*/

// Note that we update the area even if the area is unpowered. Machines drawing from a linked bus skip area accounting.
#define REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power)\
	if(old_power != new_power && !(power_node && power_node.on_bus)){\
		var/area/A = get_area(src);\
		if(A) A.power_use_change(old_power, new_power, power_channel)}

/obj/machinery/is_power_linkable()
	return TRUE

/obj/machinery/get_description_info()
	var/base_description = ..()
	if(use_power == POWER_USE_OFF && !istype(src, /obj/machinery/power) && !power_node)
		return base_description
	var/datum/power_node/N = get_power_node()
	if(!N)
		return base_description
	var/list/power_details = list("Power CCID: [N.ccid]")
	if(N.inputs.len)
		power_details += "Inputs: [english_list(N.inputs)]"
	if(N.outputs.len)
		power_details += "Outputs: [english_list(N.outputs)]"
	var/power_description = jointext(power_details, "<br>")
	return base_description ? "[base_description]<br>[power_description]" : power_description

/obj/machinery/power_nets_changed(datum/power_node/N)
	if(N.in_net && !N.on_bus)
		var/area/A = get_area(src)
		if(A)
			A.power_use_change(get_power_usage(), 0, power_channel)
		N.on_bus = TRUE
		N.bus_powered = N.in_net.avail > 0
		SSmachines.bus_consumers |= src
		power_change()
	else if(!N.in_net && N.on_bus)
		leave_power_bus(N)

/obj/machinery/leave_power_bus(datum/power_node/N)
	N.on_bus = FALSE
	N.bus_powered = FALSE
	SSmachines.bus_consumers -= src
	if(QDELETED(src))
		return
	var/area/A = get_area(src)
	if(A)
		A.power_use_change(0, get_power_usage(), power_channel)
	power_change()

/obj/machinery/get_implicit_power_inputs()
	if(power_node && power_node.on_bus)
		return list()
	var/area/A = get_area(src)
	var/obj/machinery/power/area_smes/S = A && A.get_area_smes()
	if(S)
		var/datum/power_node/supply_node = S.get_power_node()
		return list("Area supply: [S.name] ([supply_node.ccid])")
	return list("Area supply: none")

// returns true if the area has power on given channel (or doesn't require power), defaults to power_channel.
// May also optionally specify an area, otherwise defaults to src.loc.loc
/obj/machinery/proc/powered(var/chan = -1, var/area/check_area = null)

	if(!src.loc)
		return 0

	if(power_node && power_node.on_bus)
		return power_node.bus_powered

	//Don't do this. It allows machines that set use_power to 0 when off (many machines) to
	//be turned on again and used after a power failure because they never gain the NOPOWER flag.
	//if(!use_power)
	//	return 1

	if(!check_area)
		check_area = src.loc.loc		// make sure it's in an area
	if(!check_area || !isarea(check_area))
		return 0					// if not, then not powered
	if(chan == -1)
		chan = power_channel
	return check_area.powered(chan)			// return power status of the area

// called whenever the power settings of the containing area change
// by default, check equipment channel & set flag can override if needed
// This is NOT for when the machine's own status changes; update_use_power for that.
/obj/machinery/proc/power_change()
	var/oldstat = stat

	if(powered(power_channel))
		stat &= ~NOPOWER
	else
		stat |= NOPOWER

	. = (stat != oldstat)
	if(.)
		update_icon()

/obj/machinery/proc/get_power_usage()
	switch(use_power)
		if(POWER_USE_IDLE)
			return idle_power_usage
		if(POWER_USE_ACTIVE)
			return active_power_usage
		else
			return 0

// This will have this machine have its area eat this much power next tick, and not afterwards. Do not use for continued power draw.
/obj/machinery/proc/use_power_oneoff(var/amount, var/chan = POWER_CHAN, var/return_false = FALSE)
	if(power_node && power_node.on_bus)
		power_node.bus_oneoff += amount
		return
	var/area/A = get_area(src)		// make sure it's in an area
	if(!A)
		return
	if(chan == POWER_CHAN)
		chan = power_channel
	A.use_power_oneoff(amount, chan)

// Do not do power stuff in New/Initialize until after ..()
/obj/machinery/Initialize()
	REPORT_POWER_CONSUMPTION_CHANGE(0, get_power_usage())
	GLOB.moved_event.register(src, src, .proc/update_power_on_move)
	. = ..()
	if(ccid || length(ccid_inputs) || length(ccid_outputs))
		get_power_node()

// Or in Destroy at all, but especially after the ..().
/obj/machinery/Destroy()
	GLOB.moved_event.unregister(src, src, .proc/update_power_on_move)
	REPORT_POWER_CONSUMPTION_CHANGE(get_power_usage(), 0)
	. = ..()

/obj/machinery/proc/update_power_on_move(atom/movable/mover, atom/old_loc, atom/new_loc)
	var/power = get_power_usage()
	if(!power || (power_node && power_node.on_bus))
		return // This is the most likely case anyway.
	var/area/old_area = get_area(old_loc)
	var/area/new_area = get_area(new_loc)
	if(old_area != new_area)
		if(old_area)
			old_area.power_use_change(power, 0, power_channel)
		if(new_area)
			new_area.power_use_change(0, power, power_channel)

// The three procs below are the only allowed ways of modifying the corresponding variables.
/obj/machinery/proc/update_use_power(new_use_power)
	if(use_power == new_use_power)
		return
	var/old_power = get_power_usage()
	use_power = new_use_power
	var/new_power = get_power_usage()
	REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power)

/obj/machinery/proc/update_power_channel(new_channel)
	var/old_channel = power_channel
	if(old_channel == new_channel)
		return
	var/power = get_power_usage()
	REPORT_POWER_CONSUMPTION_CHANGE(power, 0)
	power_channel = new_channel
	REPORT_POWER_CONSUMPTION_CHANGE(0, power)

/obj/machinery/proc/change_power_consumption(new_power_consumption, use_power_mode = POWER_USE_IDLE)
	var/old_power
	switch(use_power_mode)
		if(POWER_USE_IDLE)
			old_power = idle_power_usage
			idle_power_usage = new_power_consumption
		if(POWER_USE_ACTIVE)
			old_power = active_power_usage
			active_power_usage = new_power_consumption
		else
			return
	if(use_power_mode == use_power)
		REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power_consumption)

#undef REPORT_POWER_CONSUMPTION_CHANGE