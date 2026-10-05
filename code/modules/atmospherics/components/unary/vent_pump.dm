#define DEFAULT_PRESSURE_DELTA 10000

#define EXTERNAL_PRESSURE_BOUND ONE_ATMOSPHERE
#define INTERNAL_PRESSURE_BOUND 0
#define PRESSURE_CHECKS 1

#define PRESSURE_CHECK_EXTERNAL 1
#define PRESSURE_CHECK_INTERNAL 2

/obj/machinery/atmospherics/unary/vent_pump
	icon = 'icons/atmos/vent_pump.dmi'
	icon_state = "map_vent"
	los_never_cull = TRUE

	name = "Air Vent"
	desc = "Has a valve and pump attached to it."
	use_power = POWER_USE_IDLE
	idle_power_usage = 150		//internal circuitry, friction losses and stuff
	power_rating = 30000			// 30000 W ~ 40 HP

	connect_types = CONNECT_TYPE_REGULAR|CONNECT_TYPE_SUPPLY //connects to regular and supply pipes

	var/area/initial_loc
	level = 1
	var/area_uid
	var/id_tag = null

	var/hibernate = 0 //Do we even process?
	var/pump_direction = 1 //0 = siphoning, 1 = releasing

	var/external_pressure_bound = EXTERNAL_PRESSURE_BOUND
	var/internal_pressure_bound = INTERNAL_PRESSURE_BOUND

	var/pressure_checks = PRESSURE_CHECKS
	//1: Do not pass external_pressure_bound
	//2: Do not pass internal_pressure_bound
	//3: Do not pass either

	// Used when handling incoming radio signals requesting default settings
	var/external_pressure_bound_default = EXTERNAL_PRESSURE_BOUND
	var/internal_pressure_bound_default = INTERNAL_PRESSURE_BOUND
	var/pressure_checks_default = PRESSURE_CHECKS

	var/welded = 0 // Added for aliens -- TLE

	var/frequency = 1439
	var/datum/radio_frequency/radio_connection

	var/radio_filter_out
	var/radio_filter_in

/obj/machinery/atmospherics/unary/vent_pump/on
	use_power = POWER_USE_IDLE
	icon_state = "map_vent_out"

/obj/machinery/atmospherics/unary/vent_pump/siphon
	pump_direction = 0

/obj/machinery/atmospherics/unary/vent_pump/siphon/on
	use_power = POWER_USE_IDLE
	icon_state = "map_vent_in"

/obj/machinery/atmospherics/unary/vent_pump/siphon/on/atmos
	use_power = POWER_USE_IDLE
	icon_state = "map_vent_in"
	external_pressure_bound = 0
	external_pressure_bound_default = 0
	internal_pressure_bound = MAX_PUMP_PRESSURE
	internal_pressure_bound_default = MAX_PUMP_PRESSURE
	pressure_checks = 2
	pressure_checks_default = 2

// Ensure vent pumps can connect to mains pipes by targeting the supply line component when adjacent to a mains pipe.
/obj/machinery/atmospherics/unary/vent_pump/atmos_init()
	update_icon()
	update_underlays()

/obj/machinery/atmospherics/unary/vent_pump/New()
	..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP
	icon = null

/obj/machinery/atmospherics/unary/vent_pump/Destroy()
	unregister_radio(src, frequency)
	if(initial_loc)
		initial_loc.air_vent_info -= id_tag
		initial_loc.air_vent_names -= id_tag
	. = ..()

/obj/machinery/atmospherics/unary/vent_pump/high_volume
	name = "Large Air Vent"
	power_channel = EQUIP
	power_rating = 15000	//15 kW ~ 20 HP

/obj/machinery/atmospherics/unary/vent_pump/high_volume/New()
	..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP + 800

/obj/machinery/atmospherics/unary/vent_pump/engine
	name = "Engine Core Vent"
	power_channel = ENVIRON
	power_rating = 30000	//15 kW ~ 20 HP

/obj/machinery/atmospherics/unary/vent_pump/engine/New()
	..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP + 500 //meant to match air injector

/obj/machinery/atmospherics/unary/vent_pump/update_icon(var/safety = 0)
	if(!check_icon_cache())
		return

	overlays.Cut()

	var/vent_icon = "vent"

	var/turf/T = get_turf(src)
	if(!istype(T))
		return

	if(!T.is_plating() && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
		vent_icon += "h"

	if(welded)
		vent_icon += "weld"
	else if(!powered())
		vent_icon += "off"
	else
		vent_icon += "[use_power ? "[pump_direction ? "out" : "in"]" : "off"]"

	overlays += icon_manager.get_atmos_icon("device", , , vent_icon)

/obj/machinery/atmospherics/unary/vent_pump/update_underlays()
	underlays.Cut()

/obj/machinery/atmospherics/unary/vent_pump/hide()
	update_icon()
	update_underlays()

/obj/machinery/atmospherics/unary/vent_pump/proc/can_pump()
	if(stat & (NOPOWER|BROKEN))
		return 0
	if(!use_power)
		return 0
	if(welded)
		return 0
	return 1

/obj/machinery/atmospherics/unary/vent_pump/proc/get_target_pressure()
	var/obj/machinery/alarm/area_modcon = initial_loc ? initial_loc.master_air_alarm : null
	if(!area_modcon)
		return 0
	var/target_pressure = min(area_modcon.output_pressure, MAX_PUMP_PRESSURE)
	if(pressure_checks & PRESSURE_CHECK_EXTERNAL)
		target_pressure = min(target_pressure, external_pressure_bound)
	return target_pressure

/obj/machinery/atmospherics/unary/vent_pump/proc/get_supply_status(obj/machinery/station_gas_tank/tank)
	if(stat & BROKEN)
		return "vent broken"
	if(stat & NOPOWER)
		return "vent unpowered"
	if(!use_power)
		return "vent switched off"
	if(welded)
		return "vent welded"
	if(hibernate > world.time)
		return "vent sleeping"
	var/obj/machinery/alarm/area_modcon = initial_loc ? initial_loc.master_air_alarm : null
	if(!area_modcon)
		return "no area modcon"
	if(!area_modcon.can_supply_air())
		return "area modcon disabled or offline"
	var/datum/gas_mixture/environment = loc ? loc.return_air() : null
	if(!environment)
		return "no room atmosphere"
	var/target_pressure = get_target_pressure()
	if(environment.get_tile_moles() > PRESSURE_TO_MOLES(target_pressure + 0.5))
		return last_flow_rate > 0 ? "recovering excess gas" : "above target"
	if(environment.get_tile_moles() >= PRESSURE_TO_MOLES(target_pressure))
		return "at target"
	if(!tank)
		tank = get_station_gas_tank(src)
	if(!tank)
		return "no station gas tank"
	return tank.get_supply_status()

/obj/machinery/atmospherics/unary/vent_pump/proc/get_supply_demand(obj/machinery/station_gas_tank/tank)
	if(!pump_direction || get_station_gas_tank(src) != tank || get_supply_status(tank))
		return 0
	var/datum/gas_mixture/environment = loc.return_air()
	var/target_pressure = get_target_pressure()
	var/moles_delta = PRESSURE_TO_MOLES(target_pressure) - environment.get_tile_moles()
	return max(0, moles_delta * environment.volume * environment.group_multiplier / CELL_VOLUME)

/obj/machinery/atmospherics/unary/vent_pump/Process()
	..()

	if (hibernate > world.time)
		return 1

	if(!can_pump())
		return 0

	var/datum/gas_mixture/environment = loc.return_air()
	var/obj/machinery/station_gas_tank/tank = get_station_gas_tank(src)
	last_flow_rate = 0
	last_power_draw = 0
	if(!environment || !tank)
		return 0
	if(pump_direction)
		var/obj/machinery/alarm/area_modcon = initial_loc ? initial_loc.master_air_alarm : null
		var/excess_moles = environment.get_tile_moles() - PRESSURE_TO_MOLES(get_target_pressure())
		if(area_modcon && area_modcon.can_supply_air() && excess_moles > PRESSURE_TO_MOLES(0.5))
			var/recovery_moles = min(tank.max_output_moles, excess_moles * environment.volume * environment.group_multiplier / CELL_VOLUME)
			last_flow_rate = area_modcon.recover_air(tank, environment, recovery_moles)
			if(last_flow_rate)
				last_power_draw = min(power_rating, last_flow_rate * 10)
				use_power_oneoff(last_power_draw)
			return 1
		var/transfer_moles = get_supply_demand(tank)
		if(transfer_moles <= 0)
			return 0
		last_flow_rate = tank.supply(environment, transfer_moles, src)
	else
		var/transfer_moles = get_transfer_moles(environment)
		if(transfer_moles < MINIMUM_MOLES_TO_PUMP)
			return 0
		var/obj/machinery/alarm/area_modcon = initial_loc ? initial_loc.master_air_alarm : null
		if(area_modcon)
			last_flow_rate = area_modcon.recover_air(tank, environment, transfer_moles)
	if(last_flow_rate)
		last_power_draw = min(power_rating, last_flow_rate * 10)
		use_power_oneoff(last_power_draw)
	return 1

/obj/machinery/atmospherics/unary/vent_pump/proc/get_transfer_moles(datum/gas_mixture/environment)
	var/transfer_moles = environment.get_total_moles()
	if(pressure_checks & PRESSURE_CHECK_EXTERNAL)
		var/excess_moles = environment.get_tile_moles() - PRESSURE_TO_MOLES(external_pressure_bound)
		transfer_moles = min(transfer_moles, max(0, excess_moles * environment.volume * environment.group_multiplier / CELL_VOLUME))
	if(pressure_checks & PRESSURE_CHECK_INTERNAL)
		var/pressure_delta = max(0, internal_pressure_bound - air_contents.return_pressure())
		transfer_moles = min(transfer_moles, calculate_transfer_moles(environment, air_contents, pressure_delta))
	return transfer_moles

/obj/machinery/atmospherics/unary/vent_pump/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src

	signal.data = list(
		"area" = src.area_uid,
		"tag" = src.id_tag,
		"device" = "AVP",
		"power" = use_power,
		"direction" = pump_direction?("release"):("siphon"),
		"checks" = pressure_checks,
		"internal" = internal_pressure_bound,
		"external" = external_pressure_bound,
		"timestamp" = world.time,
		"sigtype" = "status",
		"power_draw" = last_power_draw,
		"flow_rate" = last_flow_rate,
	)

	if(!initial_loc.air_vent_names[id_tag])
		var/new_name = "[initial_loc.name] Vent Pump #[initial_loc.air_vent_names.len+1]"
		initial_loc.air_vent_names[id_tag] = new_name
		src.SetName(new_name)
	initial_loc.air_vent_info[id_tag] = signal.data

	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1


/obj/machinery/atmospherics/unary/vent_pump/Initialize()
	. = ..()
	initial_loc = get_area(loc)
	area_uid = initial_loc.uid
	if (!id_tag)
		assign_uid()
		id_tag = num2text(uid)
	//some vents work his own special way
	radio_filter_in = frequency==1439?(RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==1439?(RADIO_TO_AIRALARM):null
	if(frequency)
		radio_connection = register_radio(src, frequency, frequency, radio_filter_in)
		src.broadcast_status()

/obj/machinery/atmospherics/unary/vent_pump/receive_signal(datum/signal/signal)
	if(stat & (NOPOWER|BROKEN))
		return

	hibernate = 0

	//log_admin("DEBUG \[[world.timeofday]\]: /obj/machinery/atmospherics/unary/vent_pump/receive_signal([signal.debug_print()])")
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if(signal.data["purge"] != null)
		pressure_checks &= ~1
		pump_direction = 0

	if(signal.data["stabalize"] != null)
		pressure_checks |= 1
		pump_direction = 1

	if(signal.data["power"] != null)
		update_use_power(sanitize_integer(text2num(signal.data["power"]), POWER_USE_OFF, POWER_USE_ACTIVE, use_power))

	if(signal.data["power_toggle"] != null)
		update_use_power(!use_power)

	if(signal.data["checks"] != null)
		if (signal.data["checks"] == "default")
			pressure_checks = pressure_checks_default
		else
			pressure_checks = text2num(signal.data["checks"])

	if(signal.data["checks_toggle"] != null)
		pressure_checks = (pressure_checks?0:3)

	if(signal.data["direction"] != null)
		pump_direction = text2num(signal.data["direction"])

	if(signal.data["set_internal_pressure"] != null)
		if (signal.data["set_internal_pressure"] == "default")
			internal_pressure_bound = internal_pressure_bound_default
		else
			internal_pressure_bound = between(0,text2num(signal.data["set_internal_pressure"]), MAX_PUMP_PRESSURE)

	if(signal.data["set_external_pressure"] != null)
		if (signal.data["set_external_pressure"] == "default")
			external_pressure_bound = external_pressure_bound_default
		else
			external_pressure_bound = between(0,text2num(signal.data["set_external_pressure"]),MAX_PUMP_PRESSURE)

	if(signal.data["adjust_internal_pressure"] != null)
		internal_pressure_bound = between(0,internal_pressure_bound + text2num(signal.data["adjust_internal_pressure"]),MAX_PUMP_PRESSURE)

	if(signal.data["adjust_external_pressure"] != null)
		external_pressure_bound = between(0,external_pressure_bound + text2num(signal.data["adjust_external_pressure"]),MAX_PUMP_PRESSURE)

	if(signal.data["init"] != null)
		SetName(signal.data["init"])
		return

	if(signal.data["status"] != null)
		spawn(2)
			broadcast_status()
		return //do not update_icon

		//log_admin("DEBUG \[[world.timeofday]\]: vent_pump/receive_signal: unknown command \"[signal.data["command"]]\"\n[signal.debug_print()]")
	spawn(2)
		broadcast_status()
	update_icon()
	return

/obj/machinery/atmospherics/unary/vent_pump/attackby(obj/item/W, mob/user)
	if(isWelder(W))

		var/obj/item/weldingtool/WT = W

		if(!WT.isOn())
			to_chat(user, "<span class='notice'>The welding tool needs to be on to start this task.</span>")
			return 1

		if(!WT.remove_fuel(0,user))
			to_chat(user, "<span class='warning'>You need more welding fuel to complete this task.</span>")
			return 1

		to_chat(user, "<span class='notice'>Now welding \the [src].</span>")
		playsound(src.loc, 'sound/items/Welder2.ogg', 50, 1)

		if(!do_after(user, 20, src))
			to_chat(user, "<span class='notice'>You must remain close to finish this task.</span>")
			return 1

		if(!src)
			return 1

		if(!WT.isOn())
			to_chat(user, "<span class='notice'>The welding tool needs to be on to finish this task.</span>")
			return 1

		welded = !welded
		update_icon()
		user.visible_message("<span class='notice'>\The [user] [welded ? "welds \the [src] shut" : "unwelds \the [src]"].</span>", \
			"<span class='notice'>You [welded ? "weld \the [src] shut" : "unweld \the [src]"].</span>", \
			"You hear welding.")
		return 1

	else
		..()

/obj/machinery/atmospherics/unary/vent_pump/examine(mob/user)
	if(..(user, 1))
		to_chat(user, "A small gauge in the corner reads [round(last_flow_rate, 0.1)] L/s; [round(last_power_draw)] W")
	else
		to_chat(user, "You are too far away to read the gauge.")
	if(welded)
		to_chat(user, "It seems welded shut.")

/obj/machinery/atmospherics/unary/vent_pump/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(!isWrench(W))
		return ..()
	if (!(stat & NOPOWER) && use_power)
		to_chat(user, "<span class='warning'>You cannot unwrench \the [src], turn it off first.</span>")
		return 1
	var/turf/T = src.loc
	if (node && node.level==1 && isturf(T) && !T.is_plating())
		to_chat(user, "<span class='warning'>You must remove the plating first.</span>")
		return 1
	if (air_contents.return_pressure() > 2*ONE_ATMOSPHERE)
		to_chat(user, "<span class='warning'>You cannot unwrench \the [src], it is too exerted due to internal pressure.</span>")
		add_fingerprint(user)
		return 1
	playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
	to_chat(user, "<span class='notice'>You begin to unfasten \the [src]...</span>")
	if (do_after(user, 40, src))
		user.visible_message( \
			"<span class='notice'>\The [user] unfastens \the [src].</span>", \
			"<span class='notice'>You have unfastened \the [src].</span>", \
			"You hear a ratchet.")
		new /obj/item/pipe(loc, make_from=src)
		qdel(src)

#undef DEFAULT_PRESSURE_DELTA

#undef EXTERNAL_PRESSURE_BOUND
#undef INTERNAL_PRESSURE_BOUND
#undef PRESSURE_CHECKS

#undef PRESSURE_CHECK_EXTERNAL
#undef PRESSURE_CHECK_INTERNAL
