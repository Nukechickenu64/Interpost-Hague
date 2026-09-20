/obj/machinery/air_sensor
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "gsensor1"
	name = "Gas Sensor"

	anchored = 1
	var/state = 0

	var/id_tag
	var/frequency = 1439

	var/on = 1
	var/output = 3
	//Flags:
	// 1 for pressure
	// 2 for temperature
	// Output >= 4 includes gas composition
	// 4 for oxygen concentration
	// 8 for phoron concentration
	// 16 for nitrogen concentration
	// 32 for carbon dioxide concentration
	// 64 for hydrogen concentration

	var/datum/radio_frequency/radio_connection

/obj/machinery/air_sensor/update_icon()
	icon_state = "gsensor[on]"

/obj/machinery/air_sensor/Process()
	if(on)
		var/datum/signal/signal = new
		signal.transmission_method = 1 //radio signal
		signal.data["tag"] = id_tag
		signal.data["timestamp"] = world.time

		var/datum/gas_mixture/air_sample = return_air()

		if(output&1)
			signal.data["pressure"] = num2text(round(air_sample.return_pressure(),0.1),)
		if(output&2)
			signal.data["temperature"] = round(air_sample.temperature,0.1)

		if(output>4)
			var/total_moles = air_sample.total_moles
			if(total_moles > 0)
				if(output&4)
					signal.data["oxygen"] = round(100*air_sample.gas["oxygen"]/total_moles,0.1)
				if(output&8)
					signal.data["phoron"] = round(100*air_sample.gas["phoron"]/total_moles,0.1)
				if(output&16)
					signal.data["nitrogen"] = round(100*air_sample.gas["nitrogen"]/total_moles,0.1)
				if(output&32)
					signal.data["carbon_dioxide"] = round(100*air_sample.gas["carbon_dioxide"]/total_moles,0.1)
				if(output&64)
					signal.data["hydrogen"] = round(100*air_sample.gas["hydrogen"]/total_moles,0.1)
			else
				signal.data["oxygen"] = 0
				signal.data["phoron"] = 0
				signal.data["nitrogen"] = 0
				signal.data["carbon_dioxide"] = 0
				signal.data["hydrogen"] = 0
		signal.data["sigtype"]="status"
		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)


/obj/machinery/air_sensor/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = radio_controller.add_object(src, frequency, RADIO_ATMOSIA)

/obj/machinery/air_sensor/Initialize()
	set_frequency(frequency)
	. = ..()

/obj/machinery/air_sensor/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src,frequency)
	. = ..()

/obj/machinery/computer/general_air_control
	icon = 'icons/obj/computer.dmi'
	icon_keyboard = "atmos_key"
	icon_screen = "tank"

	name = "Computer"

	var/frequency = 1439
	var/list/sensors = list()

	var/list/sensor_information = list()
	var/datum/radio_frequency/radio_connection
	circuit = /obj/item/weapon/circuitboard/air_management

obj/machinery/computer/general_air_control/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src, frequency)
	..()

/obj/machinery/computer/general_air_control/attack_hand(mob/user)
	if(..(user))
		return
	user << browse(return_text(),"window=computer")
	user.set_machine(src)
	onclose(user, "computer")

/obj/machinery/computer/general_air_control/Process()
	..()
	src.updateUsrDialog()

/obj/machinery/computer/general_air_control/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption) return

	var/id_tag = signal.data["tag"]
	if(!id_tag || !sensors.Find(id_tag)) return

	sensor_information[id_tag] = signal.data

/obj/machinery/computer/general_air_control/proc/return_text()
	var/sensor_data
	if(sensors.len)
		for(var/id_tag in sensors)
			var/long_name = sensors[id_tag]
			var/list/data = sensor_information[id_tag]
			var/sensor_part = "<B>[long_name]</B>:<BR>"

			if(data)
				if(data["pressure"])
					sensor_part += "   <B>Pressure:</B> [data["pressure"]] kPa<BR>"
				if(data["temperature"])
					sensor_part += "   <B>Temperature:</B> [data["temperature"]] K<BR>"
				if(data["oxygen"]||data["phoron"]||data["nitrogen"]||data["carbon_dioxide"]||data["hydrogen"])
					sensor_part += "   <B>Gas Composition :</B>"
					if(data["oxygen"])
						sensor_part += "[data["oxygen"]]% O2; "
					if(data["nitrogen"])
						sensor_part += "[data["nitrogen"]]% N; "
					if(data["carbon_dioxide"])
						sensor_part += "[data["carbon_dioxide"]]% CO2; "
					if(data["hydrogen"])
						sensor_part += "[data["hydrogen"]]% H2; "
					if(data["phoron"])
						sensor_part += "[data["phoron"]]% PH; "
				sensor_part += "<HR>"

			else
				sensor_part = "<FONT color='red'>[long_name] can not be found!</FONT><BR>"

			sensor_data += sensor_part

	else
		sensor_data = "No sensors connected."

	var/output = {"<B>[name]</B><HR>
<B>Sensor Data:</B><HR><HR>[sensor_data]"}

	return output

/obj/machinery/computer/general_air_control/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = radio_controller.add_object(src, frequency, RADIO_ATMOSIA)

/obj/machinery/computer/general_air_control/Initialize()
	set_frequency(frequency)
	. = ..()

/obj/machinery/computer/general_air_control/large_tank_control
	icon = 'icons/obj/computer.dmi'

	frequency = 1441
	var/input_tag
	var/output_tag

	var/list/input_info
	var/list/output_info

	var/input_flow_setting = 200
	var/pressure_setting = ONE_ATMOSPHERE * 45
	circuit = /obj/item/weapon/circuitboard/air_management/tank_control


/obj/machinery/computer/general_air_control/large_tank_control/return_text()
	var/output = ..()
	//if(signal.data)
	//	input_info = signal.data // Attempting to fix intake control -- TLE

	output += "<B>Tank Control System</B><BR><BR>"
	if(input_info)
		var/power = (input_info["power"])
		var/volume_rate = round(input_info["volume_rate"], 0.1)
		output += "<B>Input</B>: [power?("Injecting"):("On Hold")] <A href='?src=\ref[src];in_refresh_status=1'>Refresh</A><BR>Flow Rate Limit: [volume_rate] L/s<BR>"
		output += "Command: <A href='?src=\ref[src];in_toggle_injector=1'>Toggle Power</A> <A href='?src=\ref[src];in_set_flowrate=1'>Set Flow Rate</A><BR>"

	else
		output += "<FONT color='red'>ERROR: Can not find input port</FONT> <A href='?src=\ref[src];in_refresh_status=1'>Search</A><BR>"

	output += "Flow Rate Limit: <A href='?src=\ref[src];adj_input_flow_rate=-100'>-</A> <A href='?src=\ref[src];adj_input_flow_rate=-10'>-</A> <A href='?src=\ref[src];adj_input_flow_rate=-1'>-</A> <A href='?src=\ref[src];adj_input_flow_rate=-0.1'>-</A> [round(input_flow_setting, 0.1)] L/s <A href='?src=\ref[src];adj_input_flow_rate=0.1'>+</A> <A href='?src=\ref[src];adj_input_flow_rate=1'>+</A> <A href='?src=\ref[src];adj_input_flow_rate=10'>+</A> <A href='?src=\ref[src];adj_input_flow_rate=100'>+</A><BR>"

	output += "<BR>"

	if(output_info)
		var/power = (output_info["power"])
		var/output_pressure = output_info["internal"]
		output += {"<B>Output</B>: [power?("Open"):("On Hold")] <A href='?src=\ref[src];out_refresh_status=1'>Refresh</A><BR>
Max Output Pressure: [output_pressure] kPa<BR>"}
		output += "Command: <A href='?src=\ref[src];out_toggle_power=1'>Toggle Power</A> <A href='?src=\ref[src];out_set_pressure=1'>Set Pressure</A><BR>"

	else
		output += "<FONT color='red'>ERROR: Can not find output port</FONT> <A href='?src=\ref[src];out_refresh_status=1'>Search</A><BR>"

	output += "Max Output Pressure Set: <A href='?src=\ref[src];adj_pressure=-1000'>-</A> <A href='?src=\ref[src];adj_pressure=-100'>-</A> <A href='?src=\ref[src];adj_pressure=-10'>-</A> <A href='?src=\ref[src];adj_pressure=-1'>-</A> [pressure_setting] kPa <A href='?src=\ref[src];adj_pressure=1'>+</A> <A href='?src=\ref[src];adj_pressure=10'>+</A> <A href='?src=\ref[src];adj_pressure=100'>+</A> <A href='?src=\ref[src];adj_pressure=1000'>+</A><BR>"

	return output

/obj/machinery/computer/general_air_control/large_tank_control/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption) return

	var/id_tag = signal.data["tag"]

	if(input_tag == id_tag)
		input_info = signal.data
	else if(output_tag == id_tag)
		output_info = signal.data
	else
		..(signal)

/obj/machinery/computer/general_air_control/large_tank_control/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["adj_pressure"])
		var/change = text2num(href_list["adj_pressure"])
		pressure_setting = between(0, pressure_setting + change, MAX_PUMP_PRESSURE)
		spawn(1)
			src.updateUsrDialog()
		return 1

	if(href_list["adj_input_flow_rate"])
		var/change = text2num(href_list["adj_input_flow_rate"])
		input_flow_setting = between(0, input_flow_setting + change, ATMOS_DEFAULT_VOLUME_PUMP + 500) //default flow rate limit for air injectors
		spawn(1)
			src.updateUsrDialog()
		return 1

	if(!radio_connection)
		return 0
	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src
	if(href_list["in_refresh_status"])
		input_info = null
		signal.data = list ("tag" = input_tag, "status" = 1)
		. = 1

	if(href_list["in_toggle_injector"])
		input_info = null
		signal.data = list ("tag" = input_tag, "power_toggle" = 1)
		. = 1

	if(href_list["in_set_flowrate"])
		input_info = null
		signal.data = list ("tag" = input_tag, "set_volume_rate" = "[input_flow_setting]")
		. = 1

	if(href_list["out_refresh_status"])
		output_info = null
		signal.data = list ("tag" = output_tag, "status" = 1)
		. = 1

	if(href_list["out_toggle_power"])
		output_info = null
		signal.data = list ("tag" = output_tag, "power_toggle" = 1)
		. = 1

	if(href_list["out_set_pressure"])
		output_info = null
		signal.data = list ("tag" = output_tag, "set_internal_pressure" = pressure_setting)
		. = 1

	signal.data["sigtype"]="command"
	radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

	spawn(5)
		src.updateUsrDialog()

/obj/machinery/computer/general_air_control/supermatter_core
	icon = 'icons/obj/computer.dmi'

	frequency = 1438
	var/input_tag
	var/output_tag

	var/list/input_info
	var/list/output_info

	var/input_flow_setting = 700
	var/pressure_setting = 100
	var/automatic_management = FALSE
	var/automatic_flow_setting = 0
	var/automatic_pressure_setting = 0
	circuit = /obj/item/weapon/circuitboard/air_management/supermatter_core

	// Direct link to the actual crystal and any emitters feeding it, used by automatic management.
	var/obj/machinery/power/supermatter/linked_supermatter
	var/list/linked_emitters = list()
	var/link_refresh_at = 0

	// Automatic management will only fire emitters below this power level, and will latch off entirely once the crystal takes any damage.
	var/target_power = 250
	var/emitters_enabled = FALSE
	var/safety_shutdown = FALSE
	var/safe_streak = 0


/obj/machinery/computer/general_air_control/supermatter_core/return_text()
	var/list/core_data = get_core_sensor_data()
	var/temperature = core_data["temperature"]
	var/pressure = core_data["pressure"]
	var/automation_status = automatic_management ? "<span class='sm-good'>AUTOMATIC</span>" : "<span class='sm-muted'>MANUAL</span>"
	var/automation_button = automatic_management ? "Disable Automatic Management" : "Enable Automatic Management"
	var/output = {"
<style>
.sm-title{color:#8fe3ff;font-size:15px;font-weight:bold;letter-spacing:1px}.sm-subtitle{color:#9fd;font-size:10px}.sm-grid{width:100%;border-collapse:separate;border-spacing:5px}.sm-panel{background:#111d29;border:1px solid #246;padding:7px;vertical-align:top}.sm-panel h3{color:#b9ecff;font-size:10px;margin:0 0 5px}.sm-stat{color:#d7f6ff;font-size:16px;font-weight:bold}.sm-label{color:#9eb6c8;font-size:9px;text-transform:uppercase}.sm-good{color:#9fff9f;font-weight:bold}.sm-warn{color:#ffd866;font-weight:bold}.sm-bad{color:#ff7a7a;font-weight:bold}.sm-muted{color:#b7c2d0;font-weight:bold}.sm-action{display:inline-block;background:#17364b;border:1px solid #3ad;color:#d7f6ff;padding:3px 6px;margin:2px 2px 0 0;text-decoration:none}.sm-action:hover{background:#24536e;text-decoration:none}.sm-control{margin-top:5px;padding-top:5px;border-top:1px solid #246}.sm-value{color:#d7f6ff}
</style>
<div class='sm-title'>SUPERMATTER CORE CONTROL</div>
<div class='sm-subtitle'>COOLANT AND CHAMBER PRESSURE MANAGEMENT</div>
<table class='sm-grid'><tr>
<td class='sm-panel'><h3>CHAMBER TELEMETRY</h3>
<div class='sm-label'>Temperature</div><div class='sm-stat [temperature >= 4250 ? "sm-bad" : temperature >= 3500 ? "sm-warn" : "sm-good"]'>[temperature ? "[round(temperature)] K" : "NO SIGNAL"]</div>
<div class='sm-label'>Pressure</div><div class='sm-stat [pressure >= 500 ? "sm-warn" : "sm-good"]'>[pressure ? "[round(pressure, 0.1)] kPa" : "NO SIGNAL"]</div>
</td>
<td class='sm-panel'><h3>POWER MANAGEMENT</h3>
<div class='sm-label'>Control Mode</div><div class='sm-stat'>[automation_status]</div>
<div class='sm-subtitle'>[automatic_management ? "Adaptive coolant flow and pressure retention are active." : "Manual setpoints are active."]</div>
<a class='sm-action' href='?src=\ref[src];toggle_automatic_management=1'>[automation_button]</a>
</td>
</tr><tr><td class='sm-panel'>"}

	if(input_info)
		var/power = (input_info["power"])
		var/volume_rate = round(input_info["volume_rate"], 0.1)
		output += "<h3>COOLANT INJECTOR</h3><span class='sm-label'>State</span> <span class='[power ? "sm-good" : "sm-bad"]'>[power ? "INJECTING" : "ON HOLD"]</span><br><span class='sm-label'>Flow Limit</span> <span class='sm-value'>[volume_rate] L/s</span>"

	else
		output += "<h3>COOLANT INJECTOR</h3><span class='sm-bad'>NO DEVICE STATUS</span>"

	output += "<div class='sm-control'><span class='sm-label'>Manual Flow Setpoint</span> <span class='sm-value'>[round(input_flow_setting, 0.1)] L/s</span><br><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=-100'>-100</a><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=-10'>-10</a><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=10'>+10</a><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=100'>+100</a><a class='sm-action' href='?src=\ref[src];in_set_flowrate=1'>Apply</a><a class='sm-action' href='?src=\ref[src];in_toggle_injector=1'>Toggle</a><a class='sm-action' href='?src=\ref[src];in_refresh_status=1'>Refresh</a></div></td><td class='sm-panel'>"

	if(output_info)
		var/power = (output_info["power"])
		var/pressure_limit = output_info["external"]
		output += "<h3>CORE OUTPUMP</h3><span class='sm-label'>State</span> <span class='[power ? "sm-good" : "sm-bad"]'>[power ? "REGULATING" : "ON HOLD"]</span><br><span class='sm-label'>Minimum Core Pressure</span> <span class='sm-value'>[pressure_limit] kPa</span>"

	else
		output += "<h3>CORE OUTPUMP</h3><span class='sm-bad'>NO DEVICE STATUS</span>"

	output += "<div class='sm-control'><span class='sm-label'>Manual Pressure Setpoint</span> <span class='sm-value'>[pressure_setting] kPa</span><br><a class='sm-action' href='?src=\ref[src];adj_pressure=-100'>-100</a><a class='sm-action' href='?src=\ref[src];adj_pressure=-10'>-10</a><a class='sm-action' href='?src=\ref[src];adj_pressure=10'>+10</a><a class='sm-action' href='?src=\ref[src];adj_pressure=100'>+100</a><a class='sm-action' href='?src=\ref[src];out_set_pressure=1'>Apply</a><a class='sm-action' href='?src=\ref[src];out_toggle_power=1'>Toggle</a><a class='sm-action' href='?src=\ref[src];out_refresh_status=1'>Refresh</a></div></td></tr>"

	output += "<tr><td class='sm-panel' colspan=2><h3>CRYSTAL &amp; EMITTER LINK</h3>"
	if(istype(linked_supermatter))
		var/status = linked_supermatter.get_status()
		var/integrity = linked_supermatter.get_integrity()
		var/status_class = (status >= SUPERMATTER_DANGER) ? "sm-bad" : (status >= SUPERMATTER_WARNING) ? "sm-warn" : "sm-good"
		output += "<span class='sm-label'>Crystal Integrity</span> <span class='sm-stat [status_class]'>[integrity]%</span> "
		output += "<span class='sm-label'>Status</span> <span class='sm-stat [status_class]'>[status_name(status)]</span><br>"
	else
		output += "<span class='sm-bad'>NO CRYSTAL LINKED</span><br>"

	output += "<span class='sm-label'>Linked Emitters</span> <span class='sm-value'>[linked_emitters.len]</span> "
	output += "<span class='sm-label'>Firing</span> <span class='[emitters_enabled ? "sm-good" : "sm-muted"]'>[emitters_enabled ? "YES" : "NO"]</span> "
	if(safety_shutdown)
		output += "<span class='sm-bad'>SAFETY INTERLOCK ENGAGED</span>"
	output += "<div class='sm-control'><a class='sm-action' href='?src=\ref[src];refresh_links=1'>Rescan Engine Room</a></div>"
	output += "</td></tr></table>"

	return ui_build_styled_html("Supermatter Core Control", output)

/obj/machinery/computer/general_air_control/supermatter_core/proc/status_name(var/status)
	switch(status)
		if(SUPERMATTER_INACTIVE)
			return "INACTIVE"
		if(SUPERMATTER_NORMAL)
			return "NORMAL"
		if(SUPERMATTER_NOTIFY)
			return "ELEVATED"
		if(SUPERMATTER_WARNING)
			return "WARNING"
		if(SUPERMATTER_DANGER)
			return "DANGER"
		if(SUPERMATTER_EMERGENCY)
			return "EMERGENCY"
		if(SUPERMATTER_DELAMINATING)
			return "DELAMINATING"
	return "UNKNOWN"

/obj/machinery/computer/general_air_control/supermatter_core/proc/get_core_sensor_data()
	var/list/core_data = list("temperature" = 0, "pressure" = 0)
	for(var/id_tag in sensor_information)
		var/list/data = sensor_information[id_tag]
		if(!data)
			continue
		if(data["temperature"])
			core_data["temperature"] = max(core_data["temperature"], text2num(data["temperature"]))
		if(data["pressure"])
			core_data["pressure"] = max(core_data["pressure"], text2num(data["pressure"]))
	return core_data

/obj/machinery/computer/general_air_control/supermatter_core/proc/send_core_command(var/device_tag, var/list/command)
	if(!radio_connection || !device_tag)
		return
	command["tag"] = device_tag
	command["sigtype"] = "command"
	var/datum/signal/signal = new
	signal.transmission_method = 1
	signal.source = src
	signal.data = command
	radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

// Locates the actual supermatter crystal and any emitters sharing its z-levels, so automatic management can act on
// real crystal state instead of trusting a single (possibly stale/missing) remote temperature sensor.
/obj/machinery/computer/general_air_control/supermatter_core/proc/refresh_links()
	link_refresh_at = world.time + 100
	linked_supermatter = null
	linked_emitters = list()

	var/turf/T = get_turf(src)
	if(!T)
		return

	var/list/valid_z = GetConnectedZlevels(T.z)

	for(var/obj/machinery/power/supermatter/S in SSmachines.machinery)
		if(S.grav_pulling || S.exploded || !(S.z in valid_z) || !istype(S.loc, /turf/))
			continue
		linked_supermatter = S
		break

	for(var/obj/machinery/power/emitter/E in SSmachines.machinery)
		if(!(E.z in valid_z))
			continue
		linked_emitters += E

// Silently turns all linked emitters on or off. Used instead of touching them directly so we never fire an
// emitter that isn't actually wired up and ready.
/obj/machinery/computer/general_air_control/supermatter_core/proc/set_emitters(var/should_fire)
	emitters_enabled = should_fire
	for(var/obj/machinery/power/emitter/E in linked_emitters)
		if(QDELETED(E))
			continue
		E.remote_set_active(should_fire)

/obj/machinery/computer/general_air_control/supermatter_core/proc/run_automatic_management()
	if(world.time >= link_refresh_at || !istype(linked_supermatter))
		refresh_links()

	if(!istype(linked_supermatter))
		// No crystal to babysit - don't blindly keep emitters firing into the void.
		set_emitters(FALSE)
		return

	var/status = linked_supermatter.get_status()
	var/integrity = linked_supermatter.get_integrity()
	var/temperature = linked_supermatter.get_ambient_temperature()
	var/critical_temp = linked_supermatter.get_critical_temperature()

	// Coolant/pressure response now ramps up well ahead of actual danger, off the crystal's real temperature
	// and status, rather than waiting for a single sensor reading or for damage to already be happening.
	automatic_flow_setting = 700
	automatic_pressure_setting = 100
	if(critical_temp)
		if(temperature >= critical_temp * 0.9 || status >= SUPERMATTER_DANGER)
			automatic_flow_setting = 1200
			automatic_pressure_setting = 500
		else if(temperature >= critical_temp * 0.7 || status >= SUPERMATTER_WARNING)
			automatic_flow_setting = 1100
			automatic_pressure_setting = 300
		else if(temperature >= critical_temp * 0.5 || status >= SUPERMATTER_NOTIFY)
			automatic_flow_setting = 900
			automatic_pressure_setting = 200

	send_core_command(input_tag, list("power" = 1, "set_volume_rate" = "[automatic_flow_setting]"))
	send_core_command(output_tag, list("power" = 1, "set_external_pressure" = automatic_pressure_setting, "checks" = 1))

	// Safety interlock: back off well before actual danger. Waiting for a WARNING/damage reading is already too
	// late, since the reaction is self-sustaining and keeps heating the chamber long after emitters stop firing.
	var/danger = (status > SUPERMATTER_NORMAL) || (integrity < 100) || (critical_temp && temperature >= critical_temp * 0.5)
	if(danger)
		safety_shutdown = TRUE
		safe_streak = 0
	else if(safety_shutdown)
		// Require several consecutive safe readings before trusting it enough to re-arm, so it can't flip-flop
		// straight back into danger off a single good tick.
		safe_streak++
		if(safe_streak >= 5)
			safety_shutdown = FALSE
			safe_streak = 0

	if(safety_shutdown || status == SUPERMATTER_ERROR || status == SUPERMATTER_DELAMINATING)
		set_emitters(FALSE)
		return

	// Safe to keep the crystal fed - only fire while comfortably cool and below the power target.
	set_emitters(linked_supermatter.power < target_power)

/obj/machinery/computer/general_air_control/supermatter_core/Initialize()
	. = ..()
	refresh_links()

/obj/machinery/computer/general_air_control/supermatter_core/Process()
	if(automatic_management)
		run_automatic_management()
	else if(emitters_enabled || safety_shutdown)
		// Manual mode - don't leave emitters latched on/off from a previous automatic run.
		safety_shutdown = FALSE
		set_emitters(FALSE)
	return ..()

/obj/machinery/computer/general_air_control/supermatter_core/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption) return

	var/id_tag = signal.data["tag"]

	if(input_tag == id_tag)
		input_info = signal.data
	else if(output_tag == id_tag)
		output_info = signal.data
	else
		..(signal)

/obj/machinery/computer/general_air_control/supermatter_core/Topic(href, href_list)
	if(..())
		return 1
	if(href_list["toggle_automatic_management"])
		automatic_management = !automatic_management
		if(!automatic_management)
			safety_shutdown = FALSE
			safe_streak = 0
			set_emitters(FALSE)
		spawn(1)
			src.updateUsrDialog()
		return 1

	if(href_list["refresh_links"])
		refresh_links()
		spawn(1)
			src.updateUsrDialog()
		return 1

	if(href_list["adj_pressure"] || href_list["adj_input_flow_rate"] || href_list["in_toggle_injector"] || href_list["in_set_flowrate"] || href_list["out_toggle_power"] || href_list["out_set_pressure"])
		automatic_management = FALSE

	if(href_list["adj_pressure"])
		var/change = text2num(href_list["adj_pressure"])
		pressure_setting = between(0, pressure_setting + change, MAX_PUMP_PRESSURE)
		spawn(1)
			src.updateUsrDialog()
		return 1

	if(href_list["adj_input_flow_rate"])
		var/change = text2num(href_list["adj_input_flow_rate"])
		input_flow_setting = between(0, input_flow_setting + change, ATMOS_DEFAULT_VOLUME_PUMP + 500) //default flow rate limit for air injectors
		spawn(1)
			src.updateUsrDialog()
		return 1

	if(!radio_connection)
		return 0
	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src
	if(href_list["in_refresh_status"])
		input_info = null
		signal.data = list ("tag" = input_tag, "status" = 1)
		. = 1

	if(href_list["in_toggle_injector"])
		input_info = null
		signal.data = list ("tag" = input_tag, "power_toggle" = 1)
		. = 1

	if(href_list["in_set_flowrate"])
		input_info = null
		signal.data = list ("tag" = input_tag, "set_volume_rate" = "[input_flow_setting]")
		. = 1

	if(href_list["out_refresh_status"])
		output_info = null
		signal.data = list ("tag" = output_tag, "status" = 1)
		. = 1

	if(href_list["out_toggle_power"])
		output_info = null
		signal.data = list ("tag" = output_tag, "power_toggle" = 1)
		. = 1

	if(href_list["out_set_pressure"])
		output_info = null
		signal.data = list ("tag" = output_tag, "set_external_pressure" = pressure_setting, "checks" = 1)
		. = 1

	signal.data["sigtype"]="command"
	radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

	spawn(5)
		src.updateUsrDialog()

/obj/machinery/computer/general_air_control/fuel_injection
	icon = 'icons/obj/computer.dmi'
	icon_screen = "alert:0"

	var/device_tag
	var/list/device_info

	var/automation = 0

	var/cutoff_temperature = 2000
	var/on_temperature = 1200
	circuit = /obj/item/weapon/circuitboard/air_management/injector_control

/obj/machinery/computer/general_air_control/fuel_injection/Process()
	if(automation)
		if(!radio_connection)
			return 0

		var/injecting = 0
		for(var/id_tag in sensor_information)
			var/list/data = sensor_information[id_tag]
			if(data["temperature"])
				if(data["temperature"] >= cutoff_temperature)
					injecting = 0
					break
				if(data["temperature"] <= on_temperature)
					injecting = 1

		var/datum/signal/signal = new
		signal.transmission_method = 1 //radio signal
		signal.source = src

		signal.data = list(
			"tag" = device_tag,
			"power" = injecting,
			"sigtype"="command"
		)

		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

	..()

/obj/machinery/computer/general_air_control/fuel_injection/return_text()
	var/output = ..()

	output += "<B>Fuel Injection System</B><BR>"
	if(device_info)
		var/power = device_info["power"]
		var/volume_rate = device_info["volume_rate"]
		output += {"Status: [power?("Injecting"):("On Hold")] <A href='?src=\ref[src];refresh_status=1'>Refresh</A><BR>
Rate: [volume_rate] L/sec<BR>"}

		if(automation)
			output += "Automated Fuel Injection: <A href='?src=\ref[src];toggle_automation=1'>Engaged</A><BR>"
			output += "Injector Controls Locked Out<BR>"
		else
			output += "Automated Fuel Injection: <A href='?src=\ref[src];toggle_automation=1'>Disengaged</A><BR>"
			output += "Injector: <A href='?src=\ref[src];toggle_injector=1'>Toggle Power</A> <A href='?src=\ref[src];injection=1'>Inject (1 Cycle)</A><BR>"

	else
		output += "<FONT color='red'>ERROR: Can not find device</FONT> <A href='?src=\ref[src];refresh_status=1'>Search</A><BR>"

	return output

/obj/machinery/computer/general_air_control/fuel_injection/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption) return

	var/id_tag = signal.data["tag"]

	if(device_tag == id_tag)
		device_info = signal.data
	else
		..(signal)

/obj/machinery/computer/general_air_control/fuel_injection/Topic(href, href_list)
	if((. = ..()))
		return

	if(href_list["refresh_status"])
		device_info = null
		if(!radio_connection)
			return 0

		var/datum/signal/signal = new
		signal.transmission_method = 1 //radio signal
		signal.source = src
		signal.data = list(
			"tag" = device_tag,
			"status" = 1,
			"sigtype"="command"
		)
		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

	if(href_list["toggle_automation"])
		automation = !automation

	if(href_list["toggle_injector"])
		device_info = null
		if(!radio_connection)
			return 0

		var/datum/signal/signal = new
		signal.transmission_method = 1 //radio signal
		signal.source = src
		signal.data = list(
			"tag" = device_tag,
			"power_toggle" = 1,
			"sigtype"="command"
		)

		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

	if(href_list["injection"])
		if(!radio_connection)
			return 0

		var/datum/signal/signal = new
		signal.transmission_method = 1 //radio signal
		signal.source = src
		signal.data = list(
			"tag" = device_tag,
			"inject" = 1,
			"sigtype"="command"
		)

		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)




