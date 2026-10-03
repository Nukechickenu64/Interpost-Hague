datum/unit_test/power_link_integrity
	name = "POWER: CCID links have matching endpoints and shared buses"

/datum/unit_test/power_link_integrity/start_test()
	rebuild_power_grid()
	var/failure = ""
	for(var/ccid in GLOB.power_nodes_by_ccid)
		var/datum/power_node/N = GLOB.power_nodes_by_ccid[ccid]
		for(var/in_ccid in N.inputs)
			var/datum/power_node/S = power_node_by_ccid(in_ccid)
			if(!S)
				failure += "[ccid] references missing input [in_ccid].\n"
			else if(!(ccid in S.outputs))
				failure += "[in_ccid] -> [ccid] is missing its reciprocal output.\n"
		for(var/out_ccid in N.outputs)
			var/datum/power_node/T = power_node_by_ccid(out_ccid)
			if(!T)
				failure += "[ccid] references missing output [out_ccid].\n"
			else if(!(ccid in T.inputs))
				failure += "[ccid] -> [out_ccid] is missing its reciprocal input.\n"
			else if(N.enabled && T.enabled && N.out_net != T.in_net)
				failure += "[ccid] -> [out_ccid] does not share a power bus.\n"
	if(failure)
		fail(failure)
	else
		pass("All CCID links have matching endpoints and bus assignments.")
	return 1

/datum/unit_test/power_startup_grace
	name = "POWER: Station buses receive temporary round-start supply"

/datum/unit_test/power_startup_grace/start_test()
	var/turf/test_turf = get_safe_turf() || get_space_turf() || locate(1, 1, 1)
	if(!test_turf)
		fail("No test turf is available.")
		return 1
	var/was_station_level = (test_turf.z in GLOB.using_map.station_levels)
	var/original_round_start_time = round_start_time
	var/original_infinite_station_power = GLOB.infinite_station_power
	var/datum/powernet/test_net = new
	var/obj/test_node = new(test_turf)
	test_net.nodes[test_node] = test_node
	var/failure = ""
	GLOB.infinite_station_power = FALSE
	GLOB.using_map.station_levels |= test_turf.z
	round_start_time = world.time
	test_net.reset()
	if(test_net.avail <= 0)
		failure += "Station bus received no temporary supply during the startup window.\n"
	test_net.avail = 0
	test_net.newavail = 0
	round_start_time = world.time - (10 MINUTES)
	test_net.reset()
	if(test_net.avail)
		failure += "Station bus retained temporary supply after the startup window.\n"
	test_net.avail = 0
	test_net.newavail = 0
	round_start_time = world.time
	GLOB.using_map.station_levels -= test_turf.z
	test_net.reset()
	if(test_net.avail)
		failure += "Non-station bus received temporary startup supply.\n"
	round_start_time = original_round_start_time
	GLOB.infinite_station_power = original_infinite_station_power
	if(was_station_level)
		GLOB.using_map.station_levels |= test_turf.z
	else
		GLOB.using_map.station_levels -= test_turf.z
	qdel(test_net)
	qdel(test_node)
	if(failure)
		fail(failure)
	else
		pass("Temporary startup supply is limited to station buses and expires after ten minutes.")
	return 1

/datum/unit_test/areas_power_marker_uniqueness
	name = "POWER: Each area has at most one area power marker."

/datum/unit_test/solar_wireless_lifecycle
	name = "POWER: Solar controllers register and discover devices after wireless rebuilds"

/datum/unit_test/solar_wireless_lifecycle/start_test()
	var/turf/test_turf = get_space_turf() || locate(1, 1, 1)
	var/obj/machinery/power/solar_control/manual = new(test_turf)
	var/obj/machinery/power/solar_control/autostart/automatic = new(test_turf)
	var/obj/machinery/power/solar/panel = new(test_turf)
	var/obj/machinery/power/tracker/tracker = new(test_turf)
	var/failure = ""
	link_power_nodes(panel.get_power_node(), manual.get_power_node())
	link_power_nodes(tracker.get_power_node(), manual.get_power_node())
	rebuild_power_grid()
	manual.Process()
	if(!(manual in solars_list) || panel.control || tracker.control)
		failure += "Manual controller failed registration or discovered devices without a search.\n"
	manual.search_for_connected()
	if(panel.control != manual || tracker.control != manual)
		failure += "Manual search did not find devices on its wireless bus.\n"
	rebuild_power_grid()
	manual.Process()
	if(panel.control != manual || tracker.control != manual)
		failure += "An unchanged bus rebuild lost valid device associations.\n"
	unlink_power_nodes(panel.power_node, manual.power_node)
	unlink_power_nodes(tracker.power_node, manual.power_node)
	link_power_nodes(panel.power_node, automatic.get_power_node())
	link_power_nodes(tracker.power_node, automatic.power_node)
	rebuild_power_grid()
	manual.Process()
	automatic.Process()
	if(!(automatic in solars_list) || panel.control != automatic || tracker.control != automatic)
		failure += "Autostart failed to discover relinked devices after rebuild completion.\n"
	automatic.disconnect_from_network()
	rebuild_power_grid()
	automatic.Process()
	if((automatic in solars_list) || panel.control || tracker.control)
		failure += "Disconnect left a registered controller or stale device associations.\n"
	automatic.connect_to_network()
	rebuild_power_grid()
	automatic.Process()
	if(!(automatic in solars_list) || panel.control != automatic || tracker.control != automatic)
		failure += "Autostart failed to recover after reconnecting.\n"
	qdel(automatic)
	if((automatic in solars_list) || panel.control || tracker.control)
		failure += "Controller deletion left solar registrations or device associations.\n"
	qdel(manual)
	qdel(panel)
	qdel(tracker)
	rebuild_power_grid()
	if(failure)
		fail(failure)
	else
		pass("Manual discovery, deferred autostart, relinking, and cleanup work on wireless buses.")
	return 1

/datum/unit_test/wireless_generator_storage
	name = "POWER: Solar and supermatter output charge a wireless SMES input without bypassing storage"

/datum/unit_test/wireless_generator_storage/start_test()
	if(!GLOB.sun)
		skip("Solar generation requires a sun datum.")
		return 1
	var/turf/test_turf = get_space_turf() || locate(1, 1, 1)
	var/obj/machinery/power/solar_control/control = new(test_turf)
	var/obj/machinery/power/solar/panel = new(test_turf)
	var/obj/machinery/power/sm_reactor/reactor = new(test_turf)
	var/obj/machinery/power/smes/buildable/storage = new(test_turf)
	var/failure = ""
	link_power_nodes(panel.get_power_node(), control.get_power_node())
	link_power_nodes(panel.power_node, storage.get_power_node())
	link_power_nodes(reactor.get_power_node(), storage.power_node)
	rebuild_power_grid()
	control.search_for_connected()
	var/datum/powernet/input_bus = storage.input_powernet
	if(panel.powernet != input_bus || reactor.powernet != input_bus || storage.powernet == input_bus)
		failure += "Generators do not share the SMES input, or its split buses are bridged.\n"
	panel.sunfrac = 1
	panel.obscured = FALSE
	input_bus.newavail = 0
	panel.Process()
	var/solar_output = solar_gen_rate * panel.efficiency
	if(input_bus.newavail != solar_output || control.gen != solar_output)
		failure += "Illuminated solar output was not injected into the wireless input bus.\n"
	reactor.fuel_sheets = 10
	reactor.start_reactor()
	reactor.next_window_at = world.time + 1 HOURS
	reactor.next_anomaly_at = world.time + 1 HOURS
	reactor.Process()
	var/expected_output = solar_output + reactor.current_output()
	if(input_bus.newavail != expected_output)
		failure += "Solar and reactor outputs were not accumulated exactly once.\n"
	input_bus.reset()
	storage.charge = 0
	storage.input_attempt = TRUE
	storage.input_level = expected_output
	storage.output_attempt = FALSE
	storage.Process()
	input_bus.reset()
	if(storage.charge != expected_output * CELLRATE)
		failure += "SMES did not charge from the combined generator output.\n"
	reactor.scram()
	input_bus.newavail = 0
	reactor.Process()
	if(input_bus.newavail)
		failure += "SCRAMmed reactor continued producing power.\n"
	reactor.state = SMR_STATE_RUNNING
	reactor.fuel_sheets = 0
	reactor.Process()
	if(input_bus.newavail || reactor.state != SMR_STATE_OFF)
		failure += "Fuel-empty reactor continued producing power.\n"
	panel.obscured = TRUE
	panel.Process()
	panel.obscured = FALSE
	panel.stat |= BROKEN
	panel.Process()
	panel.stat &= ~BROKEN
	panel.unset_control()
	panel.Process()
	if(input_bus.newavail)
		failure += "Obscured, broken, or uncontrolled panel generated power.\n"
	storage.output_attempt = TRUE
	storage.output_level = solar_output
	storage.Process()
	if(storage.powernet.newavail != solar_output || input_bus.newavail)
		failure += "SMES output did not remain on its separate wireless bus.\n"
	qdel(control)
	qdel(panel)
	qdel(reactor)
	qdel(storage)
	rebuild_power_grid()
	if(failure)
		fail(failure)
	else
		pass("Both generators feed SMES input; shutdown gates and split-bus storage work.")
	return 1

/datum/unit_test/areas_power_marker_uniqueness/start_test()
	var/failure = ""
	for(var/obj/effect/area_power_marker/M in GLOB.area_power_markers)
		if(!GLOB.area_smes_by_id[M.area_id])
			failure += "Marker [log_info_line(M)] references missing area SMES ID '[M.area_id]'.\n"
	for(var/area/A in world)
		var/obj/effect/area_power_marker/found_marker = null
		for(var/obj/effect/area_power_marker/M in A)
			if(!found_marker)
				found_marker = M
				continue
			if(failure)
				failure = "[failure]\n"
			failure = "[failure]Duplicated area power markers in [A.name]. #1: [log_info_line(found_marker)]  #2: [log_info_line(M)]"

	if(failure)
		fail(failure)
	else
		pass("No areas with duplicated power markers have been found.")
	return 1

/datum/unit_test/area_power_tally_accuracy
	name = "POWER: All areas must have accurate power use values."

/datum/unit_test/area_power_tally_accuracy/start_test()
	var/failed = FALSE
	var/list/channel_names = list("equip", "light", "environ")
	for(var/area/A in world)
		var/list/old_values = list(A.used_equip, A.used_light, A.used_environ)
		A.retally_power()
		var/list/new_values = list(A.used_equip, A.used_light, A.used_environ)
		for(var/i in 1 to length(old_values))
			if(old_values[i] != new_values[i])
				failed = TRUE
				log_bad("The area [A.name] had improper power use values on the [channel_names[i]] channel: was [old_values[i]] but should be [new_values[i]].")

	if(failed)
		fail("At least one area had improper power use values")
	else
		pass("All areas had accurate power use values.")
	return 1