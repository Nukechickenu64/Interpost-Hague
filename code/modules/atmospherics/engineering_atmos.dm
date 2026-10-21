// Area controls observed in the engineer recording. The simulation still uses
// gas quantity; lockdown kPa settings are converted at the standard temperature.
/area
	var/atmos_manual_lockdown = FALSE
	var/atmos_auto_lockdown = TRUE
	var/atmos_pressure_lockdown = FALSE

/area/proc/update_atmos_lockdown(new_danger = null)
	var/obj/machinery/alarm/controller = master_air_alarm
	var/obj/machinery/station_gas_tank/tank = controller ? get_station_gas_tank(controller) : null
	if(isnull(new_danger))
		new_danger = atmosalm
	if(tank && controller && controller.buildstage == 2 && !(controller.stat & (NOPOWER|BROKEN)) && !controller.shorted)
		var/minimum_air = null
		for(var/obj/machinery/atmospherics/unary/vent_pump/vent in src)
			var/turf/T = get_turf(vent)
			var/datum/gas_mixture/air = T ? T.return_air() : null
			if(air)
				minimum_air = isnull(minimum_air) ? air.get_tile_moles() : min(minimum_air, air.get_tile_moles())
		if(!isnull(minimum_air))
			// A small recovery margin keeps doors from chattering at the boundary.
			atmos_pressure_lockdown = tank.lockdown_pressure > 0 && minimum_air < PRESSURE_TO_MOLES(tank.lockdown_pressure + (atmos_pressure_lockdown ? 2 : 0))
			// Other hazards still use existing alarm thresholds. Areas without
			// vent readings retain the complete legacy alarm, including low air.
			new_danger = 0
			for(var/obj/machinery/alarm/sensor in src)
				if(sensor.buildstage == 2 && !(sensor.stat & (NOPOWER|BROKEN)) && !sensor.shorted && sensor.report_danger_level)
					new_danger = max(new_danger, sensor.oxygen_dangerlevel, sensor.co2_dangerlevel, sensor.phoron_dangerlevel, sensor.temperature_dangerlevel, sensor.other_dangerlevel)
	var/should_close = atmos_manual_lockdown || (atmos_auto_lockdown && (atmos_pressure_lockdown || new_danger >= 2))
	if(should_close)
		air_doors_close()
	else if(!atmos_auto_lockdown || new_danger < 1)
		air_doors_open()

/obj/machinery/station_gas_tank
	var/lockdown_pressure = 60

/obj/machinery/computer/station_gas_control
	icon_screen = "area_atmos"
	circuit = /obj/item/circuitboard/station_gas_control
	var/area/selected_area

/obj/machinery/computer/station_gas_control/proc/controlled_areas()
	var/list/result = list()
	var/obj/machinery/station_gas_tank/tank = get_station_gas_tank(src)
	if(!tank)
		return result
	for(var/obj/machinery/alarm/controller in SSmachines.machinery)
		if(!QDELETED(controller) && controller.alarm_area && controller == controller.alarm_area.master_air_alarm && is_on_same_plane_or_station(z, controller.z) && get_station_gas_tank(controller) == tank)
			result |= controller.alarm_area
	return result

/obj/machinery/computer/station_gas_control/proc/atmos_data(mob/user)
	var/list/data = list("can_control" = allowed(user), "areas" = list(), "vents" = list())
	var/obj/machinery/station_gas_tank/tank = get_station_gas_tank(src)
	data["tank"] = !!tank
	if(tank)
		data["reserve"] = round(tank.air_contents.return_pressure(), 0.1)
		var/supply_status = tank.get_supply_status()
		data["supply_status"] = supply_status ? supply_status : "online"
		data["enabled"] = tank.enabled
		data["limit"] = tank.max_output_moles
		data["lockdown_pressure"] = tank.lockdown_pressure
	var/list/areas = controlled_areas()
	for(var/area/A in areas)
		data["areas"] += list(list("name" = html_encode(A.name), "ref" = "\ref[A]", "locked" = A.air_doors_activated))
	data["areas"] = sortByKey(data["areas"], "name")
	if(!(selected_area in areas))
		selected_area = null
	if(!selected_area)
		return data
	data["selected"] = "\ref[selected_area]"
	data["area_name"] = html_encode(selected_area.name)
	data["locked"] = selected_area.air_doors_activated
	data["manual"] = selected_area.atmos_manual_lockdown
	data["automatic"] = selected_area.atmos_auto_lockdown
	var/obj/machinery/alarm/controller = selected_area.master_air_alarm
	data["controller_online"] = controller && controller.buildstage == 2 && !(controller.stat & (NOPOWER|BROKEN)) && !controller.shorted
	for(var/obj/machinery/atmospherics/unary/vent_pump/vent in selected_area)
		var/turf/T = get_turf(vent)
		var/datum/gas_mixture/air = T ? T.return_air() : null
		var/vent_status = vent.get_supply_status(tank)
		data["vents"] += list(list("name" = html_encode(vent.name), "ref" = "\ref[vent]", "pressure" = air ? round(air.return_pressure(), 0.1) : "Unknown", "mode" = vent.engineering_mode_name(), "status" = vent_status ? vent_status : "online"))
	return data

/obj/machinery/computer/station_gas_control/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = TRUE)
	var/list/data = atmos_data(user)
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "engineering_atmos.tmpl", "Atmospherics Control Console", 650, 700)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(TRUE)

/obj/machinery/computer/station_gas_control/proc/set_vent_mode(area/A, obj/machinery/atmospherics/unary/vent_pump/target, mode)
	if(!(A in controlled_areas()))
		return FALSE
	var/obj/machinery/alarm/controller = A.master_air_alarm
	return controller ? controller.set_engineering_vent_mode(target, mode) : FALSE

// Both the station console and the local modcon use the same area-scoped command.
/obj/machinery/alarm/proc/set_engineering_vent_mode(obj/machinery/atmospherics/unary/vent_pump/target, new_mode)
	if(!alarm_area || alarm_area.master_air_alarm != src || buildstage != 2 || (stat & (NOPOWER|BROKEN)) || shorted || !(new_mode in list("REFILL", "STOP", "FILTER")))
		return FALSE
	if(target && (QDELETED(target) || get_area(target) != alarm_area))
		return FALSE
	var/changed = 0
	for(var/obj/machinery/atmospherics/unary/vent_pump/vent in alarm_area)
		if(!QDELETED(vent) && (!target || vent == target) && vent.set_engineering_mode(new_mode))
			changed++
	if(changed && new_mode != "STOP")
		// Resume the controller after breach shutdown, without changing other vents.
		mode = AALARM_MODE_SCRUBBING
	return changed

/obj/machinery/alarm/proc/can_use_modcon(mob/user)
	return user && !user.incapacitated() && user.Adjacent(src) && allowed(user) && !locked && buildstage == 2 && !(stat & (NOPOWER|BROKEN)) && !shorted

/obj/machinery/alarm/proc/apply_modcon_action(mob/user, list/command)
	if(!can_use_modcon(user) || !alarm_area)
		return FALSE
	switch(command["modcon"])
		if("lockdown")
			alarm_area.atmos_manual_lockdown = !alarm_area.atmos_manual_lockdown
			alarm_area.update_atmos_lockdown()
			return TRUE
		if("automatic")
			alarm_area.atmos_auto_lockdown = !alarm_area.atmos_auto_lockdown
			alarm_area.update_atmos_lockdown()
			return TRUE
		if("vent")
			var/obj/machinery/atmospherics/unary/vent_pump/target
			if(command["vent"] != "all")
				target = locate(command["vent"]) in alarm_area
				if(!istype(target))
					return FALSE
			var/obj/machinery/alarm/controller = alarm_area.master_air_alarm
			return controller ? controller.set_engineering_vent_mode(target, command["mode"]) : FALSE
	return FALSE

/obj/machinery/alarm/proc/vent_control_links(target_ref)
	var/text = ""
	for(var/action in list("REFILL", "STOP", "FILTER"))
		text += "<a href='?src=\ref[src];modcon=vent;vent=[target_ref];mode=[action]'>[action]</a> "
	return text

/obj/machinery/computer/station_gas_control/OnTopic(mob/user, href_list)
	if(stat & (NOPOWER|BROKEN))
		return TOPIC_HANDLED
	var/area/A = locate(href_list["area"]) in controlled_areas()
	if(href_list["choose_area"] && A)
		selected_area = A
		return TOPIC_REFRESH
	if(!allowed(user))
		return TOPIC_HANDLED
	if(href_list["lockdown_pressure"])
		var/obj/machinery/station_gas_tank/tank = get_station_gas_tank(src)
		if(!tank)
			return TOPIC_HANDLED
		var/value = input(user, "Automatic lockdown threshold (kPa at 20 C)", "Lockdown pressure", tank.lockdown_pressure) as null|num
		if(isnum_safe(value) && CanUseTopic(user) == STATUS_INTERACTIVE && allowed(user) && !(stat & (NOPOWER|BROKEN)) && tank == get_station_gas_tank(src))
			tank.lockdown_pressure = between(0, value, ONE_ATMOSPHERE)
			for(var/area/controlled in controlled_areas())
				controlled.update_atmos_lockdown()
		return TOPIC_REFRESH
	if(!A)
		return TOPIC_HANDLED
	if(href_list["lockdown"])
		A.atmos_manual_lockdown = !A.atmos_manual_lockdown
		A.update_atmos_lockdown()
	if(href_list["automatic"])
		A.atmos_auto_lockdown = !A.atmos_auto_lockdown
		A.update_atmos_lockdown()
	if(href_list["vent_mode"])
		var/obj/machinery/atmospherics/unary/vent_pump/vent
		if(href_list["vent"] != "all")
			vent = locate(href_list["vent"]) in A
			if(!istype(vent))
				return TOPIC_HANDLED
		set_vent_mode(A, vent, href_list["vent_mode"])
	return TOPIC_REFRESH

/obj/item/circuitboard/station_gas_control
	name = "circuit board (station atmospherics control)"
	build_path = /obj/machinery/computer/station_gas_control
	origin_tech = list(TECH_ENGINEERING = 2, TECH_DATA = 1)

/datum/design/circuit/station_gas_control
	name = "station atmospherics control"
	id = "station_gas_control"
	build_path = /obj/item/circuitboard/station_gas_control
	req_tech = list(TECH_ENGINEERING = 2, TECH_DATA = 1)

// The central filter hub scrubs contaminants recovered by the area modcons
// before they reach the station reserve. Cartridge wear happens here instead
// of on the modcon units.
/obj/machinery/filter_hub
	name = "filter hub"
	desc = "Centralized contaminant filtration feeding the station atmosphere reserve."
	icon = 'icons/os13/objects/objects/machines/atmos2.dmi'
	icon_state = "4"
	anchored = TRUE
	density = FALSE
	bound_width = 64
	bound_height = 64
	power_channel = ENVIRON
	idle_power_usage = 100
	req_one_access = list(access_atmospherics, access_engine_equip)
	var/list/cartridges = list()
	var/max_cartridges = 4
	var/obj/machinery/station_gas_tank/output_tank

/obj/machinery/filter_hub/Initialize()
	. = ..()
	station_filter_hubs |= src
	output_tank = get_station_gas_tank(src)
	for(var/slot in 1 to max_cartridges)
		cartridges += new /obj/item/weapon/chemical_scrubber(src)
	update_tile_appearance()

/obj/machinery/filter_hub/Destroy()
	station_filter_hubs -= src
	for(var/obj/item/weapon/chemical_scrubber/cartridge in cartridges)
		if(cartridge)
			cartridge.forceMove(get_turf(src))
	cartridges = null
	return ..()

// The hub renders as a 2x2 arrangement of per-tile sprites. State 4 is the
// southwest anchor; 3 is southeast, 2 is northwest, 1 is northeast.
/obj/machinery/filter_hub/proc/update_tile_appearance()
	overlays.Cut()
	icon_state = "4"
	var/list/tile_offsets = list(
		list("3", 32, 0),
		list("2", 0, 32),
		list("1", 32, 32)
	)
	for(var/list/tile in tile_offsets)
		var/image/piece = image(icon, tile[1])
		piece.pixel_x = tile[2]
		piece.pixel_y = tile[3]
		overlays += piece

/obj/machinery/filter_hub/proc/can_process()
	return !(stat & (NOPOWER|BROKEN)) && first_available_cartridge() != null

/obj/machinery/filter_hub/proc/first_available_cartridge()
	for(var/obj/item/weapon/chemical_scrubber/cartridge in cartridges)
		if(cartridge && cartridge.integrity > 0)
			return cartridge
	return null

// Consumes contaminant moles into the filter media, wearing cartridges like
// the old modcon cartridges. Returns the moles that could not be captured.
/obj/machinery/filter_hub/proc/consume_contaminants(moles)
	if(moles <= 0)
		return 0
	if(stat & (NOPOWER|BROKEN))
		return moles
	var/cost = moles / 1000
	for(var/obj/item/weapon/chemical_scrubber/cartridge in cartridges)
		if(!cartridge || cartridge.integrity <= 0)
			continue
		var/take = min(cartridge.integrity, cost)
		cartridge.integrity -= take
		cost -= take
		if(cost <= 0)
			break
	return cost * 1000

/obj/machinery/filter_hub/proc/status_report(mob/user)
	var/text = "<div class='firstdivmood'><div class='compbox'><b>[name]</b><hr>"
	text += "Reserve link: [output_tank && !QDELETED(output_tank) ? "online" : "offline"]<br>"
	text += "Filter media:<br>"
	for(var/index in 1 to cartridges.len)
		var/obj/item/weapon/chemical_scrubber/cartridge = cartridges[index]
		if(cartridge)
			text += "Cartridge [index]: [round(cartridge.integrity / cartridge.max_integrity * 100, 0.1)]%<br>"
	return "[text]</div></div>"

/obj/machinery/filter_hub/attack_hand(mob/user)
	if(..())
		return
	to_chat(user, status_report(user))

/obj/machinery/filter_hub/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/chemical_scrubber))
		if(cartridges.len >= max_cartridges)
			to_chat(user, SPAN_WARNING("All cartridge slots are occupied."))
			return
		if(!allowed(user))
			to_chat(user, SPAN_WARNING("Access denied."))
			return
		user.drop_item()
		W.forceMove(src)
		cartridges += W
		to_chat(user, SPAN_NOTICE("You slot the chemical scrubber into \the [src]."))
		return
	if(isCrowbar(W))
		if(!cartridges.len)
			to_chat(user, SPAN_WARNING("There are no cartridges to remove."))
			return
		if(!allowed(user))
			to_chat(user, SPAN_WARNING("Access denied."))
			return
		// Eject the most spent cartridge first.
		var/obj/item/weapon/chemical_scrubber/spent
		for(var/obj/item/weapon/chemical_scrubber/cartridge in cartridges)
			if(!spent || cartridge.integrity < spent.integrity)
				spent = cartridge
		cartridges -= spent
		spent.forceMove(get_turf(src))
		to_chat(user, SPAN_NOTICE("You pry \the [spent] out of \the [src]."))
		return
	return ..()

/obj/machinery/filter_hub/examine(mob/user)
	. = ..(user)
	var/obj/item/weapon/chemical_scrubber/first = first_available_cartridge()
	to_chat(user, "It has [cartridges.len]/[max_cartridges] filter cartridges installed; [first ? "media is available" : "its filter media is exhausted or missing"].")
	to_chat(user, "Use a crowbar to eject a spent cartridge, and a replacement chemical scrubber to install a new one.")

/obj/machinery/atmospherics/unary/vent_pump
	var/engineering_mode = "STOP" // Null keeps legacy/local alarm control unchanged.

/obj/machinery/atmospherics/unary/vent_pump/proc/engineering_mode_name()
	if(!use_power)
		return "STOP"
	return engineering_mode ? engineering_mode : (pump_direction ? "FILTER" : "SIPHON")

/obj/machinery/atmospherics/unary/vent_pump/proc/set_engineering_mode(mode)
	if(malfunction || (stat & (NOPOWER|BROKEN)) || !(mode in list("REFILL", "STOP", "FILTER")))
		return FALSE
	engineering_mode = mode
	hibernate = 0
	last_flow_rate = 0
	last_power_draw = 0
	pump_direction = 1
	pressure_checks = 1 // External bound; the legacy vent constants are file-local.
	external_pressure_bound = external_pressure_bound_default
	update_use_power(mode == "STOP" ? POWER_USE_OFF : POWER_USE_IDLE)
	update_icon()
	broadcast_status()
	return TRUE

// Filter mode works exactly like a filtering scrubber: one limited flow rate,
// a contaminant-only gas list. The modcon no longer wears its own cartridge;
// when a central filter hub exists, its media absorbs the contaminants (and
// wears) instead, and exhausted hub media stops filtering. Without a hub the
// contaminants are simply destroyed. A hibernate nap skips cycles that filter
// nothing.
/obj/machinery/atmospherics/unary/vent_pump/proc/filter_room(datum/gas_mixture/environment)
	var/obj/machinery/alarm/controller = initial_loc ? initial_loc.master_air_alarm : null
	var/efficiency = controller ? controller.scrub_efficiency() : 0
	if(!efficiency || !environment || !environment.volume)
		return 0
	var/obj/machinery/filter_hub/hub = get_station_filter_hub(src)
	if(hub && !hub.can_process())
		last_flow_rate = 0
		hibernate = world.time + rand(100, 200)
		return 0
	var/list/contaminants = gas_data.gases.Copy()
	contaminants -= GAS_OXYGEN
	contaminants -= GAS_NITROGEN
	var/amount = min(environment.total_moles, environment.total_moles * MAX_SCRUBBER_FLOWRATE / environment.volume) * efficiency
	var/datum/gas_mixture/removed = new(environment.volume, environment.temperature)
	var/before = environment.total_moles
	var/draw = scrub_gas(src, contaminants, environment, removed, amount, power_rating)
	last_flow_rate = max(0, before - environment.total_moles)
	qdel(removed)
	if(last_flow_rate)
		if(hub)
			hub.consume_contaminants(last_flow_rate)
	else
		hibernate = world.time + rand(100, 200)
	if(draw >= 0)
		last_power_draw = draw
		use_power_oneoff(draw)
	return last_flow_rate

// One service operation for both pump and scrubber grilles. Wrench handling
// remains in each device's attackby so it cannot replace welding dispatch.
/obj/machinery/atmospherics/unary
	var/welded = FALSE
	var/vent_servicing = FALSE

/obj/machinery/atmospherics/unary/proc/weld_vent(obj/item/weldingtool/tool, mob/user)
	if(vent_servicing || !istype(tool) || !user || user.incapacitated() || !user.Adjacent(src) || user.get_active_hand() != tool || tool.loc != user)
		return FALSE
	if(!tool.isOn() || tool.get_fuel() < 1)
		to_chat(user, SPAN_WARNING("A lit welding tool with fuel is required."))
		return FALSE
	var/was_welded = welded
	vent_servicing = TRUE
	to_chat(user, SPAN_NOTICE("You begin [was_welded ? "unwelding" : "welding shut"] \the [src]."))
	playsound(src, 'sound/items/Welder2.ogg', 50, TRUE)
	var/completed = do_after(user, 2 SECONDS, src)
	if(QDELETED(src))
		return FALSE
	vent_servicing = FALSE
	if(!completed || QDELETED(tool) || tool.loc != user || user.get_active_hand() != tool || welded != was_welded || !tool.remove_fuel(1, user))
		return FALSE
	welded = !was_welded
	last_flow_rate = 0
	last_power_draw = 0
	update_icon()
	user.visible_message(SPAN_NOTICE("\The [user] [welded ? "welds shut" : "unwelds"] \the [src]."), SPAN_NOTICE("You [welded ? "weld shut" : "unweld"] \the [src]."))
	return TRUE
