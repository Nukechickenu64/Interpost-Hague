#ifdef UNIT_TEST

// Alpha does not map the generic safe_turf landmark. Use a real, isolated
// platform on the test z-level so fixtures actually initialize and interact.
/datum/unit_test/proc/engineer_test_turf()
	var/turf/origin = locate(world.maxx - 20, world.maxy - 20, world.maxz)
	for(var/turf/T in range(6, origin))
		if(!istype(T, /turf/unsimulated/floor))
			T.ChangeTurf(/turf/unsimulated/floor)
	return locate(world.maxx - 20, world.maxy - 20, world.maxz)

/datum/unit_test/engineer_solar_service
	name = "ENGINEER VIDEO - Solar maintenance, deployment and material conservation"

/datum/unit_test/engineer_solar_service/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/power/solar_base/installed/damaged/B = new(T)
	var/obj/item/solar_panel/original = B.panel
	var/obj/item/screwdriver/D = new(T)
	U.put_in_hands(D)
	if(B.power_output() || B.remove_panel(U) || B.repair_base())
		failure += "A defective/secured mount bypassed the service sequence. "
	B.attackby(D, U)
	if(B.secured || !B.remove_panel(U) || original.loc != U || !B.repair_base())
		failure += "Unsecuring, physical removal or exposed-base repair failed. "
	if(!B.install_panel(original, U) || B.power_output())
		failure += "Refitting lost the original panel or generated before securing. "
	B.attackby(D, U)
	if(B.power_output() != 7200)
		failure += "A repaired secured standard panel did not generate 7.2 kW. "
	B.deployed = FALSE
	B.ex_act(3)
	if(B.power_output() || B.defective || original.broken)
		failure += "Retraction did not stop output/protect against a glancing impact. "
	B.deployed = TRUE
	B.ex_act(2)
	if(!B.defective || !original.broken || B.power_output())
		failure += "An exposed impact did not disable both mount and panel. "
	B.attackby(D, U)
	B.remove_panel(U)
	var/obj/item/weapon/material/shard/mirror/shard = locate() in U
	if(!QDELETED(original) || !shard || shard.matter["steel"] != 2000 || shard.matter["glass"] != 4000)
		failure += "Shattered panel salvage lost or duplicated its material value. "
	if(shard)
		U.drop_from_inventory(shard)
	B.repair_base()
	var/obj/item/solar_panel/advanced/P = new(T)
	if(B.install_panel(P, U))
		failure += "A panel on the floor could be installed without holding it. "
	U.put_in_hands(P)
	B.install_panel(P, U)
	B.attackby(D, U)
	if(B.power_output() != 14400)
		failure += "Advanced replacement output was incorrect. "
	B.disconnect_from_network()
	if(B.power_output())
		failure += "A disconnected mount generated power. "
	B.connect_to_network()
	var/obj/machinery/computer/engineering_power/C = new(T)
	B.array_id = C.array_id = "engineer-video-test"
	C.set_array_deployed(FALSE)
	if(B.deployed || B.power_output())
		failure += "The console did not retract its array. "
	C.set_array_deployed(TRUE)
	if(!B.deployed || B.power_output() != 14400)
		failure += "The console did not restore output. "
	C.stat = 0
	C.update_icon()
	if(C.icon_state != "os13_power")
		failure += "The power console did not use its OS13 computer sprite. "
	C.stat = NOPOWER
	C.update_icon()
	if(C.icon_state != "os13_power_off")
		failure += "The power console did not display its unpowered state. "
	for(var/atom/A in list(C, B, D, shard, U))
		qdel(A)
	if(failure)
		fail(failure)
	else
		pass("Physical panels, service ordering, faults, salvage, upgraded output, grid connection and deployment verified.")
	return TRUE

/datum/unit_test/engineer_salvage
	name = "ENGINEER VIDEO - Cart, harvester and research replacement panels"

/datum/unit_test/engineer_salvage/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/structure/solar_panel_cart/loaded/C = new(T)
	var/obj/structure/harvester/H = new(T)
	var/obj/item/screwdriver/tool = new(T)
	var/obj/item/weapon/material/shard/mirror/S = new(T)
	var/obj/item/ore/os13/iron/O = new(T)
	if(C.panels.len != 6)
		failure += "The replacement cart was not loaded with six panels. "
	var/obj/item/solar_panel/P = C.panels[C.panels.len]
	C.attack_hand(U)
	if(P.loc != U || C.panels.len != 5)
		failure += "Unloading did not return the original panel. "
	C.attackby(P, U)
	if(P.loc != C || C.panels.len != 6)
		failure += "Loading duplicated or lost a panel. "
	C.attack_hand(U)
	U.drop_from_inventory(P)
	H.attack_hand(U)
	if(P.loc != H || S.loc != H || O.loc != H || tool.loc != T)
		failure += "The harvester did not collect panels/shards/ore selectively on activation. "
	H.release_contents()
	if(P.loc != T || S.loc != T || O.loc != T || H.scooped.len)
		failure += "Release lost or retained salvage. "
	H.scoop_turf()
	qdel(H)
	if(P.loc != T || S.loc != T || O.loc != T)
		failure += "Destroying the harvester destroyed its salvage. "
	var/list/remaining = C.panels.Copy()
	qdel(C)
	for(var/obj/item/solar_panel/remaining_panel in remaining)
		if(remaining_panel.loc != T)
			failure += "Destroying the cart lost a replacement panel. "
		qdel(remaining_panel)
	var/datum/design/item/solar_panel/design = new
	var/datum/design/item/solar_panel/advanced/advanced = new
	if(design.build_path != /obj/item/solar_panel || advanced.build_path != /obj/item/solar_panel/advanced || advanced.req_tech[TECH_POWER] <= design.req_tech[TECH_POWER])
		failure += "Research did not expose the standard and advanced progression. "
	for(var/material_id in P.matter)
		if(design.materials[material_id] < P.matter[material_id])
			failure += "Fabricating/reclaiming a panel could create free material. "
	for(var/datum/A in list(design, advanced, P, S, O, tool, U))
		qdel(A)
	if(failure)
		fail(failure)
	else
		pass("Six real replacements, cart recovery, selective salvage, release/destruction recovery and research costs verified.")
	return TRUE

/obj/machinery/vending/engineering/video_test
	products = list(/obj/item/screwdriver = 4, /obj/item/wrench = 3)
	premium = list(/obj/item/crowbar = 2)
	contraband = list()

/datum/unit_test/engineer_vending
	name = "ENGINEER VIDEO - Compatible refill charges and stock preservation"

/datum/unit_test/engineer_vending/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/vending/engineering/video_test/V = new(T)
	sleep(5) // Vending Initialize builds its inventory after four ticks.
	var/obj/item/vending_charge/C = new(T)
	var/obj/item/vending_charge/coffee/wrong = new(T)
	U.put_in_hands(C)
	if(V.refill_from_charge(C, U) || QDELETED(C))
		failure += "A full vendor consumed a charge. "
	var/datum/stored_items/vending_products/R = V.product_records[1]
	var/datum/stored_items/vending_products/uninstantiated = V.product_records[2]
	var/datum/stored_items/vending_products/premium = V.product_records[3]
	var/obj/item/vended = R.get_product(T)
	var/obj/item/returned = R.instances[1]
	returned.name = "returned screwdriver"
	uninstantiated.amount = 0
	premium.amount = 0
	U.put_in_hands(wrong)
	if(V.refill_from_charge(wrong, U) || QDELETED(wrong) || R.get_amount() != 3)
		failure += "An incompatible refill was consumed or changed stock. "
	if(!V.refill_from_charge(C, U) || !QDELETED(C) || R.get_amount() != 4 || uninstantiated.get_amount() != 3 || premium.get_amount())
		failure += "Refilling failed to restore ordinary capacities or created premium stock. "
	if(!(returned in R.instances) || returned.name != "returned screwdriver" || vended.loc != T)
		failure += "Refilling replaced returned items or recalled a vended tool. "
	for(var/atom/A in list(vended, V, wrong, U))
		qdel(A)
	if(failure)
		fail(failure)
	else
		pass("Wrong/full refills rejected; both stock representations replenished; returned and premium items preserved.")
	return TRUE

/datum/unit_test/engineer_power_sample
	name = "ENGINEER VIDEO - Completed grid samples and storage energy conservation"

/datum/unit_test/engineer_power_sample/start_test()
	var/failure = ""
	var/datum/powernet/original_net = power_net
	var/original_start = round_start_time
	var/original_infinite = GLOB.infinite_station_power
	var/original_infinite_smes = GLOB.infinite_smes_power
	round_start_time = 0
	GLOB.infinite_station_power = FALSE
	GLOB.infinite_smes_power = FALSE
	var/datum/powernet/N = new
	power_net = N
	var/area/A = new
	A.requires_power = TRUE
	A.always_unpowered = FALSE
	N.cached_station_areas = list(A)
	A.used_equip = 2000
	A.oneoff_light = 1000
	N.avail = N.newavail = 20000
	N.draw_power(5000)
	N.reset()
	if(N.viewload != 8000 || N.area_loads[A] != 3000 || A.oneoff_light || N.generated != 20000 || N.load)
		failure += "Direct draw or completed area demand was discarded. "
	A.oneoff_light = 1000
	N.record_serviced_area(A)
	A.clear_usage()
	N.draw_power(3000)
	A.oneoff_equip = 500
	N.newavail = 20000
	N.reset()
	if(N.viewload != 3500 || N.area_loads[A] != 3500)
		failure += "Controller-serviced demand was double billed or its sample was lost ([N.viewload]/[N.area_loads[A]]). "
	A.used_equip = 0
	var/obj/machinery/power/smes/S = new(engineer_test_turf())
	S.stat = 0
	S.input_attempt = S.output_attempt = TRUE
	S.input_level = S.output_level = 50000
	var/initial_charge = S.charge
	S.Process()
	N.reset()
	if(S.charge != initial_charge || S.input_available || N.generated || N.stored_energy != initial_charge)
		failure += "Idle storage charged itself or failed to refund unused output. "
	N.newavail = 20000
	N.avail = 70000
	N.draw_power(30000)
	S.Process()
	N.reset()
	if(abs(S.charge - (initial_charge - 10000 * CELLRATE)) > 0.1 || S.input_available || N.generated != 20000 || N.viewload != 30000)
		failure += "Storage deficit mismatch: charge=[S.charge], expected=[initial_charge - 10000 * CELLRATE], input=[S.input_available], generated=[N.generated], demand=[N.viewload]. "
	var/list/report = engineering_power_data()
	if(report["demand"] != 30 || report["generated"] != 20 || report["age"] != 0)
		failure += "The console report did not use the completed grid sample. "
	qdel(S)
	qdel(N)
	qdel(A)
	power_net = original_net
	round_start_time = original_start
	GLOB.infinite_station_power = original_infinite
	GLOB.infinite_smes_power = original_infinite_smes
	if(failure)
		fail(failure)
	else
		pass("Direct and area loads counted once, snapshots retained, generation excludes storage, refunds conserve energy.")
	return TRUE

/datum/unit_test/engineer_shield_and_bracelet
	name = "ENGINEER VIDEO - Directional shields and bracelet readings"

/datum/unit_test/engineer_shield_and_bracelet/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/obj/machinery/power/shield_generator/G = new(T)
	G.field_radius = 3
	G.running = SHIELD_RUNNING
	G.regenerate_field()
	var/full_segments = G.field_segments.len
	G.OnTopic(null, list("direction" = "[NORTH]"))
	if(!G.field_segments.len || G.field_segments.len >= full_segments || !G.covers_direction(get_step(T, NORTH)) || G.covers_direction(get_step(T, SOUTH)) || G.covers_direction(get_step(T, EAST)))
		failure += "The north sector failed to restrict actual shield coverage. "
	for(var/obj/effect/shield/S in G.field_segments)
		if(!G.covers_direction(get_turf(S)))
			failure += "A shield segment survived outside the selected sector. "
	G.mode_changes_locked = TRUE
	G.OnTopic(null, list("direction" = "[SOUTH]"))
	if(G.field_direction != NORTH)
		failure += "A cut control wire did not prevent coverage changes. "
	G.mode_changes_locked = FALSE
	G.OnTopic(null, list("direction" = "0"))
	if(G.field_segments.len != full_segments)
		failure += "Full coverage did not restore the original perimeter. "
	var/mob/living/carbon/human/U = new(T)
	var/obj/item/device/medical_bracelet/B = new(T)
	if(B.local_reading())
		failure += "An unworn bracelet reported someone else's readings. "
	U.equip_to_slot_if_possible(B, slot_wrist_l)
	U.radiation = 42
	var/list/reading = B.local_reading()
	var/area/A = get_area(U)
	if(!reading || reading["area"] != A.name || reading["radiation"] != 42 || isnull(reading["pulse"]))
		failure += "A worn bracelet omitted location, pulse or radiation. "
	qdel(G)
	qdel(B)
	qdel(U)
	if(failure)
		fail(failure)
	else
		pass("Cardinal sector geometry, full perimeter restoration, control-wire lock and worn-only local telemetry verified.")
	return TRUE

/datum/unit_test/engineer_crew_signals
	name = "ENGINEER VIDEO - Missing crew signals and sensor-level restrictions"

/datum/unit_test/engineer_crew_signals/start_test()
	var/failure = ""
	var/datum/computer_file/crew_record/online = new
	var/datum/computer_file/crew_record/offline = new
	online.set_name("Online Engineer")
	offline.set_name("Missing Engineer")
	var/list/live = list(list("name" = "Online Engineer", "sensor_type" = SUIT_SENSOR_VITAL, "pulse" = 80, "area" = "Hidden location", "radiation" = 42))
	var/list/rows = crew_monitor_rows(live, list(online, offline))
	var/report = crew_signal_report(rows)
	if(rows.len != 2 || !findtext(report, "Missing Engineer - NOT RESPONDING") || !findtext(report, "RAD: 42") || findtext(report, "Hidden location"))
		failure += "Missing signal, radiation display or vital-only location restriction failed. "
	for(var/list/entry in rows)
		if(entry["missing"] && (entry["sensor_type"] || entry["area"] || entry["z"] != -1))
			failure += "A missing signal retained live tracking data. "
	live[1]["sensor_type"] = SUIT_SENSOR_BINARY
	rows = crew_monitor_rows(live, list(online, offline))
	report = crew_signal_report(rows)
	if(findtext(report, "RAD:") || findtext(report, "PLS:") || findtext(report, "Hidden location"))
		failure += "Binary-only reporting leaked detailed vitals. "
	qdel(online)
	qdel(offline)
	if(failure)
		fail(failure)
	else
		pass("Manifest members without signals remain visible; detailed vitals and positions obey sensor levels.")
	return TRUE

/turf/unsimulated/floor/engineer_atmos_test
	var/datum/gas_mixture/test_air

/turf/unsimulated/floor/engineer_atmos_test/return_air()
	return test_air

/datum/unit_test/engineer_atmos_controls
	name = "ENGINEER VIDEO - Area vent controls, access and persistent lockdown"

/datum/unit_test/engineer_atmos_controls/start_test()
	var/failure = ""
	var/turf/unsimulated/floor/engineer_atmos_test/T = engineer_test_turf().ChangeTurf(/turf/unsimulated/floor/engineer_atmos_test)
	T.test_air = new(CELL_VOLUME, T20C)
	T.test_air.adjust_gas(GAS_OXYGEN, PRESSURE_TO_MOLES(100))
	var/area/A = get_area(T)
	var/obj/machinery/alarm/old_master = A.master_air_alarm
	var/old_manual = A.atmos_manual_lockdown
	var/old_auto = A.atmos_auto_lockdown
	var/old_pressure = A.atmos_pressure_lockdown
	var/old_doors = A.air_doors_activated
	var/list/old_tanks = station_gas_tanks.Copy()
	var/obj/machinery/station_gas_tank/tank = new(T)
	station_gas_tanks = list(tank)
	tank.stat = 0
	var/obj/machinery/alarm/controller = new(T)
	A.master_air_alarm = controller
	controller.stat = 0
	var/obj/machinery/computer/station_gas_control/C = new(T)
	C.stat = 0
	C.selected_area = A
	var/obj/machinery/atmospherics/unary/vent_pump/one = new(T)
	var/obj/machinery/atmospherics/unary/vent_pump/two = new(T)
	one.stat = two.stat = 0
	var/mob/living/carbon/human/U = new(T)
	C.OnTopic(U, list("area" = "\ref[A]", "vent" = "all", "vent_mode" = "STOP"))
	if(!one.use_power || !two.use_power)
		failure += "A user without access changed vents. "
	C.req_one_access = list()
	C.OnTopic(U, list("area" = "\ref[A]", "vent" = "\ref[one]", "vent_mode" = "STOP"))
	if(one.use_power || !two.use_power)
		failure += "Individual control changed the wrong vents. "
	C.OnTopic(U, list("area" = "\ref[A]", "vent" = "bad-ref", "vent_mode" = "STOP"))
	if(!two.use_power)
		failure += "A stale vent reference became an all-vent command. "
	C.OnTopic(U, list("area" = "\ref[A]", "vent" = "all", "vent_mode" = "FILTER"))
	if(one.engineering_mode_name() != "FILTER" || two.engineering_mode_name() != "FILTER")
		failure += "All-vent filtering failed. "
	controller.stat = NOPOWER
	if(C.set_vent_mode(A, null, "REFILL"))
		failure += "An offline controller accepted a command. "
	controller.stat = 0
	C.stat = NOPOWER
	C.OnTopic(U, list("area" = "\ref[A]", "vent" = "all", "vent_mode" = "STOP"))
	if(!one.use_power)
		failure += "An unpowered console changed vents. "
	C.stat = 0
	var/list/data = C.atmos_data(U)
	if(!data["tank"] || data["vents"].len != 2 || data["supply_status"] != "online" || data["vents"][1]["mode"] != "FILTER")
		failure += "Console data did not report the live reserve and vent states. "
	controller.locked = FALSE
	if(controller.apply_modcon_action(U, list("modcon" = "vent", "vent" = "all", "mode" = "STOP")) || findtext(controller.modcon_report(U), "modcon=vent"))
		failure += "The local modcon accepted or offered commands without access. "
	controller.req_one_access = list()
	if(!controller.apply_modcon_action(U, list("modcon" = "vent", "vent" = "\ref[one]", "mode" = "STOP")) || one.use_power || !two.use_power)
		failure += "The local modcon failed individual vent control. "
	if(controller.apply_modcon_action(U, list("modcon" = "vent", "vent" = "bad-ref", "mode" = "STOP")) || !two.use_power)
		failure += "The local modcon treated a stale reference as all vents. "
	controller.locked = TRUE
	if(controller.apply_modcon_action(U, list("modcon" = "vent", "vent" = "all", "mode" = "REFILL")))
		failure += "A locked modcon accepted a stale command. "
	controller.locked = FALSE
	controller.shorted = TRUE
	if(controller.apply_modcon_action(U, list("modcon" = "automatic")))
		failure += "A shorted modcon changed lockdown settings. "
	controller.shorted = FALSE
	U.forceMove(get_step(get_step(T, NORTH), NORTH))
	if(controller.apply_modcon_action(U, list("modcon" = "vent", "vent" = "all", "mode" = "REFILL")))
		failure += "A distant user could use old modcon links. "
	U.forceMove(T)
	if(!controller.apply_modcon_action(U, list("modcon" = "vent", "vent" = "all", "mode" = "FILTER")) || one.engineering_mode_name() != "FILTER" || two.engineering_mode_name() != "FILTER")
		failure += "The local modcon failed all-vent control. "
	var/local_report = controller.modcon_report(U)
	if(!findtext(local_report, "modcon=lockdown") || !findtext(local_report, "modcon=automatic") || !findtext(local_report, "vent=all") || !findtext(local_report, "FILTER"))
		failure += "The local report omitted controls or selected mode. "
	fdel("tmp/engineer-video-check/modcon-fragment.html")
	text2file(local_report, "tmp/engineer-video-check/modcon-fragment.html")
	A.atmos_auto_lockdown = TRUE
	A.atmos_manual_lockdown = FALSE
	A.atmos_pressure_lockdown = FALSE
	T.test_air.adjust_gas(GAS_OXYGEN, -PRESSURE_TO_MOLES(50))
	A.update_atmos_lockdown(0)
	if(!A.air_doors_activated)
		failure += "Low gas quantity did not trigger automatic lockdown. "
	T.test_air.adjust_gas(GAS_OXYGEN, PRESSURE_TO_MOLES(11))
	A.update_atmos_lockdown(0)
	if(!A.air_doors_activated)
		failure += "Lockdown recovery margin was ignored. "
	T.test_air.adjust_gas(GAS_OXYGEN, PRESSURE_TO_MOLES(39))
	A.atmos_manual_lockdown = TRUE
	A.update_atmos_lockdown(0)
	if(!A.air_doors_activated)
		failure += "Recovery cleared a manual lockdown. "
	A.atmos_manual_lockdown = FALSE
	A.update_atmos_lockdown(0)
	if(A.air_doors_activated)
		failure += "Recovered air did not clear automatic lockdown. "
	T.test_air.temperature = 100
	A.update_atmos_lockdown(0)
	if(A.air_doors_activated)
		failure += "Pressure lockdown used temperature instead of the existing gas-quantity model. "
	T.test_air.temperature = T20C
	T.test_air.adjust_gas(GAS_OXYGEN, -PRESSURE_TO_MOLES(90))
	A.atmos_auto_lockdown = FALSE
	A.update_atmos_lockdown(0)
	if(A.air_doors_activated)
		failure += "Disabled automatic lockdown closed doors. "
	A.atmos_manual_lockdown = TRUE
	A.update_atmos_lockdown(0)
	if(!A.air_doors_activated)
		failure += "Disabling automatic control also disabled manual lockdown. "
	controller.locked = FALSE
	controller.OnTopic(U, list("atmos_reset" = "1"), GLOB.default_state)
	if(A.atmos_manual_lockdown || A.air_doors_activated)
		failure += "The existing air-alarm reset did not release manual lockdown. "
	controller.OnTopic(U, list("atmos_alarm" = "1"), GLOB.default_state)
	A.update_atmos_lockdown(0)
	if(!A.atmos_manual_lockdown || !A.air_doors_activated)
		failure += "The existing air-alarm activation was not persistent. "
	for(var/atom/fixture in list(C, one, two, controller, tank, U))
		qdel(fixture)
	station_gas_tanks = old_tanks
	A.master_air_alarm = old_master
	A.atmos_manual_lockdown = old_manual
	A.atmos_auto_lockdown = old_auto
	A.atmos_pressure_lockdown = old_pressure
	A.air_doors_activated = old_doors
	qdel(T.test_air)
	T.ChangeTurf(/turf/unsimulated/floor)
	if(failure)
		fail(failure)
	else
		pass("Individual/all vent commands, access, offline/stale targets, live readings and manual/automatic lockdown verified.")
	return TRUE

/datum/unit_test/engineer_atmos_flow
	name = "ENGINEER VIDEO - Filtering, refill conservation and stopped/welded vents"

/datum/unit_test/engineer_atmos_flow/start_test()
	var/failure = ""
	var/turf/unsimulated/floor/engineer_atmos_test/T = engineer_test_turf().ChangeTurf(/turf/unsimulated/floor/engineer_atmos_test)
	T.test_air = new(CELL_VOLUME, T20C)
	T.test_air.adjust_multi(GAS_OXYGEN, 10, GAS_NITROGEN, 30, GAS_CO2, 5)
	var/area/A = get_area(T)
	var/obj/machinery/alarm/old_master = A.master_air_alarm
	var/list/old_tanks = station_gas_tanks.Copy()
	var/obj/machinery/station_gas_tank/tank = new(T)
	station_gas_tanks = list(tank)
	tank.stat = 0
	var/obj/machinery/alarm/controller = new(T)
	controller.stat = 0
	A.master_air_alarm = controller
	var/obj/machinery/atmospherics/unary/vent_pump/vent = new(T)
	vent.stat = 0
	vent.set_engineering_mode("FILTER")
	vent.Process()
	if(T.test_air.get_gas(GAS_CO2) >= 5 || abs(T.test_air.get_gas(GAS_OXYGEN) - 10) > 0.001 || abs(T.test_air.get_gas(GAS_NITROGEN) - 30) > 0.001 || controller.cartridge.integrity != controller.cartridge.max_integrity)
		failure += "Filtering did not remove contaminants while preserving breathable gas and the modcon cartridge. "
	var/remaining = T.test_air.total_moles
	controller.cartridge.integrity = 0
	vent.Process()
	if(abs(T.test_air.total_moles - remaining) > 0.001)
		failure += "An exhausted cartridge still filtered. "
	controller.cartridge.integrity = controller.cartridge.max_integrity
	vent.welded = TRUE
	vent.Process()
	if(abs(T.test_air.total_moles - remaining) > 0.001)
		failure += "A welded vent still filtered. "
	vent.welded = FALSE
	vent.set_engineering_mode("STOP")
	vent.Process()
	if(abs(T.test_air.total_moles - remaining) > 0.001)
		failure += "A stopped vent moved gas. "
	vent.set_engineering_mode("REFILL")
	tank.supply_allocations[vent] = 10
	var/total_before = T.test_air.total_moles + tank.air_contents.total_moles
	vent.Process()
	if(T.test_air.total_moles <= remaining || abs(T.test_air.total_moles + tank.air_contents.total_moles - total_before) > 0.1)
		failure += "Refill failed or created gas instead of drawing from the reserve. "
	remaining = T.test_air.total_moles
	tank.enabled = FALSE
	vent.Process()
	if(abs(T.test_air.total_moles - remaining) > 0.001)
		failure += "Refill bypassed disabled supply. "
	// A standalone scrubber must initialize during play and process only once.
	// With ample power, one 750 L cycle samples 42 of these 140 moles in 2500 L.
	qdel(T.test_air)
	T.test_air = new(2500, T20C)
	T.test_air.adjust_multi(GAS_OXYGEN, 10, GAS_NITROGEN, 30, GAS_CO2, 100)
	var/obj/machinery/atmospherics/unary/vent_scrubber/scrubber = new(T)
	if(!scrubber.air_contents || scrubber.air_contents.volume != ATMOS_DEFAULT_VOLUME_FILTER || scrubber.icon || !(GAS_CO2 in scrubber.scrubbing_gas))
		failure += "A newly built scrubber did not finish initialization. "
	scrubber.stat = 0
	scrubber.use_power = POWER_USE_IDLE
	scrubber.power_rating = 1000000000
	controller.cartridge.integrity = controller.cartridge.max_integrity
	scrubber.Process()
	if(abs(T.test_air.get_gas(GAS_CO2) - 58) > 0.001 || abs(scrubber.last_flow_rate - 42) > 0.001 || controller.cartridge.integrity != controller.cartridge.max_integrity || T.test_air.get_gas(GAS_OXYGEN) != 10 || T.test_air.get_gas(GAS_NITROGEN) != 30)
		failure += "A scrubber filtered more than one cycle or misreported flow; the modcon cartridge wore unexpectedly. "
	for(var/atom/fixture in list(scrubber, vent, controller, tank))
		qdel(fixture)
	station_gas_tanks = old_tanks
	A.master_air_alarm = old_master
	qdel(T.test_air)
	T.ChangeTurf(/turf/unsimulated/floor)
	if(failure)
		fail(failure)
	else
		pass("Real gas filtering without modcon cartridge wear, welding, stop mode, finite-reserve refill and single-cycle scrubber flow verified.")
	return TRUE

/datum/unit_test/engineer_timed_maintenance
	name = "ENGINEER VIDEO - Timed vent welding and solar repair interruptions"

/datum/unit_test/engineer_timed_maintenance/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	STOP_PROCESSING(SSmobs, U)
	var/obj/item/weldingtool/W = new(T)
	U.put_in_hands(W)
	W.setWelding(TRUE)
	// Isolate task fuel from the welder's independent idle consumption.
	STOP_PROCESSING(SSobj, W)
	for(var/vent_type in list(/obj/machinery/atmospherics/unary/vent_pump, /obj/machinery/atmospherics/unary/vent_scrubber))
		var/obj/machinery/atmospherics/unary/V = new vent_type(T)
		var/before = W.get_fuel()
		var/start = world.time
		// A second use while work is in progress must not toggle it back.
		spawn(5)
			V.attackby(W, U)
		V.attackby(W, U)
		if(!V.welded || V.vent_servicing || world.time - start < 2 SECONDS || abs(W.get_fuel() - (before - 1)) > 0.001)
			failure += "[vent_type]: timed welding, fuel cost or concurrent-use guard failed. "
		V.attackby(W, U)
		if(V.welded || V.vent_servicing)
			failure += "[vent_type]: unwelding failed through normal tool dispatch. "
		before = W.get_fuel()
		spawn(5)
			U.forceMove(get_step(T, NORTH))
		V.attackby(W, U)
		if(V.welded || V.vent_servicing || W.get_fuel() != before)
			failure += "[vent_type]: movement did not cancel welding without charging fuel. "
		U.forceMove(T)
		spawn(5)
			W.setWelding(FALSE)
		V.attackby(W, U)
		if(V.welded || V.vent_servicing || W.get_fuel() != before)
			failure += "[vent_type]: switching off the welder did not cancel completion. "
		W.setWelding(TRUE)
		STOP_PROCESSING(SSobj, W)
		spawn(5)
			U.drop_from_inventory(W)
		V.attackby(W, U)
		if(V.welded || V.vent_servicing || W.get_fuel() != before)
			failure += "[vent_type]: dropping the welder did not cancel completion. "
		U.put_in_hands(W)
		W.tank.reagents.remove_reagent(/datum/reagent/fuel, W.get_fuel())
		start = world.time
		V.attackby(W, U)
		if(V.welded || V.vent_servicing || world.time != start)
			failure += "[vent_type]: an empty lit welder started work. "
		W.tank.reagents.add_reagent(/datum/reagent/fuel, 20)
		qdel(V)
	var/obj/machinery/power/solar_base/B = new(T)
	B.defective = TRUE
	var/before = W.get_fuel()
	spawn(5)
		U.forceMove(get_step(T, NORTH))
	B.attackby(W, U)
	if(!B.defective || B.servicing || W.get_fuel() != before)
		failure += "Interrupted solar repair completed or charged fuel. "
	U.forceMove(T)
	var/start = world.time
	B.attackby(W, U)
	if(B.defective || B.servicing || world.time - start < 3 SECONDS || abs(W.get_fuel() - (before - 1)) > 0.001)
		failure += "An uninterrupted three-second solar weld did not repair the base. "
	for(var/atom/fixture in list(B, W, U))
		qdel(fixture)
	if(failure)
		fail(failure)
	else
		pass("Pump/scrubber welding and unwelding, held lit tools, fuel, concurrent use, movement/drop/shutdown interruptions and timed solar repair verified.")
	return TRUE

#endif
