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
	var/obj/machinery/atmospherics/unary/outlet_injector/linked_injector
	var/obj/machinery/atmospherics/unary/vent_pump/linked_outpump
	var/list/linked_feed_pumps = list()
	var/list/linked_feed_filters = list()
	var/obj/machinery/power/generator/linked_generator
	var/link_refresh_at = 0

	var/target_generation = 250000
	var/target_temperature = 3000
	var/target_epr = 1
	var/max_excitation = 600
	var/generation_demand = TRUE
	var/temperature_demand = TRUE
	var/emitters_enabled = FALSE
	var/safety_shutdown = FALSE
	var/safe_streak = 0


/obj/machinery/computer/general_air_control/supermatter_core/return_text()
	var/list/core_data = get_core_sensor_data()
	var/temperature = istype(linked_supermatter) ? linked_supermatter.get_ambient_temperature() : core_data["temperature"]
	var/pressure = core_data["pressure"]
	var/pressure_label = "Sensor Pressure"
	if(istype(linked_supermatter))
		var/turf/chamber = get_turf(linked_supermatter)
		var/datum/gas_mixture/chamber_air = chamber?.return_air()
		if(chamber_air)
			pressure = chamber_air.return_pressure()
			pressure_label = "Core Pressure"
	var/automation_status = automatic_management ? "<span class='sm-good'>AUTOMATIC</span>" : "<span class='sm-muted'>MANUAL</span>"
	var/automation_button = automatic_management ? "Disable Automatic Management" : "Enable Automatic Management"
	var/output = {"
<style>
.sm-subtitle{color:#9fd;font-size:10px}.sm-grid{width:100%;border-collapse:separate;border-spacing:5px}.sm-panel{background:#111d29;border:1px solid #246;padding:7px;vertical-align:top}.sm-panel h3{color:#b9ecff;font-size:10px;margin:0 0 5px}.sm-stat{color:#d7f6ff;font-size:16px;font-weight:bold}.sm-label{color:#9eb6c8;font-size:9px;text-transform:uppercase}.sm-good{color:#9fff9f;font-weight:bold}.sm-warn{color:#ffd866;font-weight:bold}.sm-bad{color:#ff7a7a;font-weight:bold}.sm-muted{color:#b7c2d0;font-weight:bold}.sm-action{display:inline-block;background:#17364b;border:1px solid #3ad;color:#d7f6ff;padding:3px 6px;margin:2px 2px 0 0;text-decoration:none}.sm-action:hover{background:#24536e;text-decoration:none}.sm-control{margin-top:5px;padding-top:5px;border-top:1px solid #246}.sm-value{color:#d7f6ff}
</style>
<div class='sm-subtitle'>COOLANT AND CHAMBER PRESSURE MANAGEMENT</div>
<table class='sm-grid'><tr>
<td class='sm-panel'><h3>CHAMBER TELEMETRY</h3>
<div class='sm-label'>Temperature</div><div class='sm-stat [temperature >= 4250 ? "sm-bad" : temperature >= 3500 ? "sm-warn" : "sm-good"]'>[temperature ? "[round(temperature)] K" : "NO SIGNAL"]</div>
<div class='sm-label'>[pressure_label]</div><div class='sm-stat [pressure >= 500 ? "sm-warn" : "sm-good"]'>[pressure ? "[round(pressure, 0.1)] kPa" : "NO SIGNAL"]</div>
</td>
<td class='sm-panel'><h3>POWER MANAGEMENT</h3>
<div class='sm-label'>Control Mode</div><div class='sm-stat'>[automation_status]</div>
<div class='sm-subtitle'>[automatic_management ? "Adaptive coolant flow and pressure retention are active." : "Manual setpoints are active."]</div>
<a class='sm-action' href='?src=\ref[src];toggle_automatic_management=1'>[automation_button]</a>
<div class='sm-control'><span class='sm-label'>Automatic Core Target</span> <span class='sm-value'>[target_temperature] K</span><br>[automatic_management ? "<a class='sm-action' href='?src=\ref[src];set_target_temperature=1'>Set Target</a>" : ""]</div>
</td>
</tr><tr><td class='sm-panel'>"}

	if(input_info)
		var/power = (input_info["power"])
		var/volume_rate = round(input_info["volume_rate"], 0.1)
		output += "<h3>COOLANT INJECTOR</h3><span class='sm-label'>State</span> <span class='[power ? "sm-good" : "sm-bad"]'>[power ? "INJECTING" : "ON HOLD"]</span><br><span class='sm-label'>Flow Limit</span> <span class='sm-value'>[volume_rate] L/s</span>"

	else
		output += "<h3>COOLANT INJECTOR</h3><span class='sm-bad'>NO DEVICE STATUS</span>"
	if(istype(linked_injector))
		output += "<br><span class='sm-label'>Feed Reservoir</span> <span class='sm-value'>[round(linked_injector.air_contents.total_moles, 0.1)] mol / [round(linked_injector.air_contents.return_pressure(), 0.1)] kPa</span> <span class='sm-label'>Actual Flow</span> <span class='sm-value'>[round(linked_injector.last_flow_rate, 0.1)] L/cycle</span>"
		output += "<br><span class='sm-label'>Feed Pumps / Filters</span> <span class='sm-value'>[linked_feed_pumps.len] / [linked_feed_filters.len]</span>"

	output += "<div class='sm-control'><span class='sm-label'>Manual Flow Setpoint</span> <span class='sm-value'>[round(input_flow_setting, 0.1)] L/s</span><br><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=-100'>-100</a><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=-10'>-10</a><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=10'>+10</a><a class='sm-action' href='?src=\ref[src];adj_input_flow_rate=100'>+100</a><a class='sm-action' href='?src=\ref[src];in_set_flowrate=1'>Apply</a><a class='sm-action' href='?src=\ref[src];in_toggle_injector=1'>Toggle</a><a class='sm-action' href='?src=\ref[src];in_refresh_status=1'>Refresh</a></div></td><td class='sm-panel'>"

	if(output_info)
		var/power = (output_info["power"])
		var/pressure_limit = output_info["external"]
		output += "<h3>CORE OUTPUMP</h3><span class='sm-label'>State</span> <span class='[power ? "sm-good" : "sm-bad"]'>[power ? "REGULATING" : "ON HOLD"]</span><br><span class='sm-label'>Minimum Core Pressure</span> <span class='sm-value'>[pressure_limit] kPa</span>"

	else
		output += "<h3>CORE OUTPUMP</h3><span class='sm-bad'>NO DEVICE STATUS</span>"
	if(istype(linked_outpump))
		output += "<br><span class='sm-label'>Actual Flow</span> <span class='sm-value'>[round(linked_outpump.last_flow_rate, 0.1)] L/cycle</span>"

	output += "<div class='sm-control'><span class='sm-label'>Manual Pressure Setpoint</span> <span class='sm-value'>[pressure_setting] kPa</span><br><a class='sm-action' href='?src=\ref[src];adj_pressure=-100'>-100</a><a class='sm-action' href='?src=\ref[src];adj_pressure=-10'>-10</a><a class='sm-action' href='?src=\ref[src];adj_pressure=10'>+10</a><a class='sm-action' href='?src=\ref[src];adj_pressure=100'>+100</a><a class='sm-action' href='?src=\ref[src];out_set_pressure=1'>Apply</a><a class='sm-action' href='?src=\ref[src];out_toggle_power=1'>Toggle</a><a class='sm-action' href='?src=\ref[src];out_refresh_status=1'>Refresh</a></div></td></tr>"

	output += "<tr><td class='sm-panel' colspan=2><h3>CRYSTAL &amp; EMITTER LINK</h3>"
	if(istype(linked_supermatter))
		var/status = linked_supermatter.get_status()
		var/integrity = linked_supermatter.get_integrity()
		var/status_class = (status >= SUPERMATTER_DANGER) ? "sm-bad" : (status >= SUPERMATTER_WARNING) ? "sm-warn" : "sm-good"
		output += "<span class='sm-label'>Crystal Integrity</span> <span class='sm-stat [status_class]'>[integrity]%</span> "
		output += "<span class='sm-label'>Status</span> <span class='sm-stat [status_class]'>[status_name(status)]</span> <span class='sm-label'>EPR</span> <span class='sm-value'>[linked_supermatter.get_epr()]</span><br>"
	else
		output += "<span class='sm-bad'>NO CRYSTAL LINKED</span><br>"

	output += "<span class='sm-label'>Linked Emitters</span> <span class='sm-value'>[linked_emitters.len]</span> "
	output += "<span class='sm-label'>Emitters On</span> <span class='[emitters_enabled ? "sm-good" : "sm-muted"]'>[emitters_enabled ? "YES" : "NO"]</span> "
	if(istype(linked_generator))
		output += "<span class='sm-label'>Generator</span> <span class='sm-value'>[round(linked_generator.effective_gen / 1000, 0.1)] / [round(target_generation / 1000)] kW</span> "
		if(linked_generator.circ1 && linked_generator.circ2)
			output += "<br><span class='sm-label'>Circulators 1 / 2</span> <span class='sm-value'>[round(linked_generator.circ1.recent_moles_transferred, 0.1)] / [round(linked_generator.circ2.recent_moles_transferred, 0.1)] mol/cycle</span> "
	else
		output += "<span class='sm-bad'>NO GENERATOR LINKED</span> "
	if(automatic_management)
		var/cooling_fault = get_cooling_fault()
		if(cooling_fault)
			output += "<span class='sm-bad'>[cooling_fault]</span> "
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
	linked_injector = null
	linked_outpump = null
	linked_feed_pumps = list()
	linked_feed_filters = list()
	linked_generator = null

	var/turf/T = get_turf(src)
	if(!T)
		return

	var/list/valid_z = GetConnectedZlevels(T.z)

	for(var/obj/machinery/power/supermatter/S in SSmachines.machinery)
		if(S.grav_pulling || S.exploded || !(S.z in valid_z) || !istype(S.loc, /turf/))
			continue
		linked_supermatter = S
		break

	if(istype(linked_supermatter))
		var/nearest_generator_distance = 60
		for(var/obj/machinery/power/generator/G in SSmachines.machinery)
			if(G.z != linked_supermatter.z)
				continue
			var/distance = get_dist(G, linked_supermatter)
			if(distance < nearest_generator_distance)
				nearest_generator_distance = distance
				linked_generator = G
		for(var/obj/machinery/atmospherics/unary/outlet_injector/I in SSmachines.machinery)
			if(I.z == linked_supermatter.z && I.frequency == frequency && I.id == input_tag)
				linked_injector = I
				break
		for(var/obj/machinery/atmospherics/unary/vent_pump/V in SSmachines.machinery)
			if(V.z == linked_supermatter.z && V.frequency == frequency && V.id_tag == output_tag)
				linked_outpump = V
				break
		if(linked_injector?.network)
			var/list/feed_networks = list(linked_injector.network)
			for(var/obj/machinery/atmospherics/omni/filter/F in SSmachines.machinery)
				if(F.z != linked_injector.z || get_dist(F, linked_injector) > 30 || F.error_check() || !F.input?.network)
					continue
				var/feeds_injector = (F.output?.network == linked_injector.network)
				for(var/datum/omni_port/port in F.gas_filters)
					if(port.network == linked_injector.network)
						feeds_injector = TRUE
				if(feeds_injector)
					linked_feed_filters += F
					feed_networks |= F.input.network
			for(var/obj/machinery/atmospherics/binary/pump/P in SSmachines.machinery)
				if(P.z == linked_injector.z && get_dist(P, linked_injector) <= 30 && P.node1 && P.node2 && P.network1 && (P.network2 in feed_networks))
					linked_feed_pumps += P

	for(var/obj/machinery/power/emitter/E in SSmachines.machinery)
		if(!istype(linked_supermatter) || E.z != linked_supermatter.z || E.id != "EngineEmitter" || get_dist(E, linked_supermatter) > 30)
			continue
		linked_emitters += E

// Silently turns all linked emitters on or off. Used instead of touching them directly so we never fire an
// emitter that isn't actually wired up and ready.
/obj/machinery/computer/general_air_control/supermatter_core/proc/set_emitters(var/should_fire)
	emitters_enabled = FALSE
	for(var/obj/machinery/power/emitter/E in linked_emitters)
		if(QDELETED(E))
			continue
		E.remote_set_active(should_fire)
		if(E.active)
			emitters_enabled = TRUE

/obj/machinery/computer/general_air_control/supermatter_core/proc/get_cooling_fault()
	if(!istype(linked_injector) || !istype(linked_outpump))
		return "COOLANT DEVICE NOT LINKED"
	if(linked_injector.stat & (NOPOWER|BROKEN) || !linked_injector.use_power)
		return "INJECTOR UNPOWERED"
	if(!linked_injector.node || !linked_injector.network)
		return "INJECTOR FEED DISCONNECTED"
	if(linked_outpump.stat & (NOPOWER|BROKEN) || !linked_outpump.can_pump())
		return "OUTPUMP UNAVAILABLE"
	if(!linked_outpump.node || !linked_outpump.network || linked_outpump.pump_direction)
		return "OUTPUMP DISCONNECTED OR REVERSED"
	if(linked_injector.air_contents.total_moles > 0.5)
		return null
	for(var/datum/gas_mixture/air in linked_injector.network.gases)
		if(air.total_moles > 0.5)
			return null
	return "COOLANT FEED EMPTY"

/obj/machinery/computer/general_air_control/supermatter_core/proc/cooling_available()
	return !get_cooling_fault()

/obj/machinery/computer/general_air_control/supermatter_core/proc/start_feed_pumps()
	for(var/obj/machinery/atmospherics/omni/filter/F in linked_feed_filters)
		if(!QDELETED(F) && !(F.stat & (NOPOWER|BROKEN)) && !F.error_check() && !F.use_power)
			F.update_use_power(POWER_USE_IDLE)
			F.update_icon()
	for(var/obj/machinery/atmospherics/binary/pump/P in linked_feed_pumps)
		if(QDELETED(P) || (P.stat & (NOPOWER|BROKEN)) || !P.node1 || !P.node2 || !P.network1 || !P.network2)
			continue
		var/feeds_injector = (P.network2 == linked_injector?.network)
		for(var/obj/machinery/atmospherics/omni/filter/F in linked_feed_filters)
			if(!QDELETED(F) && !F.error_check() && F.input?.network == P.network2 && (F.output?.network == linked_injector?.network))
				feeds_injector = TRUE
			if(!QDELETED(F) && !F.error_check() && F.input?.network == P.network2)
				for(var/datum/omni_port/port in F.gas_filters)
					if(port.network == linked_injector?.network)
						feeds_injector = TRUE
		if(!feeds_injector)
			continue
		P.target_pressure = max(P.target_pressure, min(1000, P.max_pressure_setting))
		if(!P.use_power)
			P.update_use_power(POWER_USE_IDLE)
			P.update_icon()

/obj/machinery/computer/general_air_control/supermatter_core/proc/needs_excitation(var/generation, var/crystal_power, var/temperature, var/epr = 1)
	if(epr < target_epr || generation < target_generation)
		generation_demand = TRUE
	else if(generation >= target_generation + 25000)
		generation_demand = FALSE
	else
		generation_demand = FALSE
	if(temperature >= target_temperature)
		temperature_demand = FALSE
	else if(temperature <= target_temperature - 100)
		temperature_demand = TRUE
	return generation_demand && temperature_demand && crystal_power < max_excitation

/obj/machinery/computer/general_air_control/supermatter_core/proc/set_target_temperature(var/value)
	if(!isnum_safe(value) || value < 300 || value > 3500)
		return FALSE
	target_temperature = value
	return TRUE

/obj/machinery/computer/general_air_control/supermatter_core/proc/automatic_danger(var/status, var/integrity, var/temperature, var/critical_temp, var/epr, var/cooling_ready, var/generator_ready)
	return !cooling_ready || !generator_ready || epr < 1 || status > SUPERMATTER_NORMAL || integrity < 100 || (critical_temp && temperature >= critical_temp * 0.76)

/obj/machinery/computer/general_air_control/supermatter_core/proc/update_automatic_setpoints(var/temperature, var/critical_temp, var/status, var/epr, var/cooling_ready, var/chamber_pressure)
	automatic_flow_setting = 700
	automatic_pressure_setting = 300
	if(temperature >= target_temperature + 200)
		automatic_flow_setting = 1200
		automatic_pressure_setting = 25
	else if(temperature >= target_temperature)
		automatic_flow_setting = 1100
		automatic_pressure_setting = 150
	else if(temperature >= target_temperature - 200)
		automatic_flow_setting = 900
		automatic_pressure_setting = 250
	if(critical_temp)
		if(temperature >= critical_temp * 0.9 || status >= SUPERMATTER_DANGER)
			automatic_flow_setting = max(automatic_flow_setting, 1200)
			automatic_pressure_setting = min(automatic_pressure_setting, 25)
		else if(temperature >= critical_temp * 0.7 || status >= SUPERMATTER_WARNING)
			automatic_flow_setting = max(automatic_flow_setting, 1100)
			automatic_pressure_setting = min(automatic_pressure_setting, 50)
	if(critical_temp && temperature >= critical_temp * 0.7)
		automatic_flow_setting = 1200
		if(epr >= 1)
			automatic_pressure_setting = max(25, min(chamber_pressure - 25, chamber_pressure / epr))
		else
			automatic_pressure_setting = 25
	else if(!cooling_ready || epr < 1)
		automatic_pressure_setting = max(100, chamber_pressure + 1)

/obj/machinery/computer/general_air_control/supermatter_core/proc/run_automatic_management()
	if(world.time >= link_refresh_at || !istype(linked_supermatter) || !istype(linked_injector) || !istype(linked_outpump) || !istype(linked_generator))
		refresh_links()

	if(!istype(linked_supermatter))
		// No crystal to babysit - don't blindly keep emitters firing into the void.
		set_emitters(FALSE)
		return

	var/status = linked_supermatter.get_status()
	var/integrity = linked_supermatter.get_integrity()
	var/temperature = linked_supermatter.get_ambient_temperature()
	var/critical_temp = linked_supermatter.get_critical_temperature()
	var/epr = linked_supermatter.get_epr()
	start_feed_pumps()
	var/cooling_ready = cooling_available()
	var/turf/chamber = get_turf(linked_supermatter)
	var/datum/gas_mixture/chamber_air = chamber?.return_air()
	var/chamber_pressure = chamber_air?.return_pressure()

	update_automatic_setpoints(temperature, critical_temp, status, epr, cooling_ready, chamber_pressure)

	send_core_command(input_tag, list("power" = 1, "set_volume_rate" = "[automatic_flow_setting]"))
	send_core_command(output_tag, list("power" = 1, "set_external_pressure" = automatic_pressure_setting, "checks" = 1))

	// Safety interlock: back off well before actual danger. Waiting for a WARNING/damage reading is already too
	// late, since the reaction is self-sustaining and keeps heating the chamber long after emitters stop firing.
	var/danger = automatic_danger(status, integrity, temperature, critical_temp, epr, cooling_ready, istype(linked_generator))
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

	set_emitters(needs_excitation(linked_generator.effective_gen, linked_supermatter.power, temperature, epr))

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
	..()
	return 1

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
	if(href_list["set_target_temperature"])
		if(!automatic_management)
			return 1
		var/new_target = input(usr, "Core temperature target in Kelvin (300-3500 K)", "Automatic Core Target", target_temperature) as num|null
		if(automatic_management && usr && usr.machine == src && CanUseTopic(usr, GLOB.default_state) == STATUS_INTERACTIVE)
			set_target_temperature(new_target)
			src.updateUsrDialog()
		return 1
	if(href_list["toggle_automatic_management"])
		automatic_management = !automatic_management
		if(automatic_management)
			refresh_links()
		else
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




