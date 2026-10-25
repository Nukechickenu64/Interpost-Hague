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
	name = "ENGINEER VIDEO - Universal creation tokens and vending costs"

/datum/unit_test/engineer_vending/start_test()
	var/failure = ""
	var/turf/T = engineer_test_turf()
	var/mob/living/carbon/human/U = new(T)
	var/obj/machinery/vending/engineering/video_test/V = new(T)
	sleep(5)
	V.stat = 0
	V.scan_id = FALSE
	var/datum/stored_items/vending_products/R = V.product_records[1]
	var/before = V.creation_charges
	var/list/original_items = T.contents.Copy()
	V.vend(R, U)
	if(V.creation_charges != before - R.charge_cost)
		failure += "Vending did not deduct its creation cost. "
	for(var/token_type in list(/obj/item/vending_charge, /obj/item/vending_charge/coffee, /obj/item/vending_charge/security))
		var/obj/item/vending_charge/C = new token_type(T)
		U.put_in_hands(C)
		before = V.creation_charges
		if(!V.refill_from_charge(C, U) || !QDELETED(C) || V.creation_charges != before + 10)
			failure += "A universal token did not add exactly ten charges. "
	var/obj/item/vending_charge/distant = new(T)
	U.put_in_hands(distant)
	before = V.creation_charges
	U.forceMove(get_step(get_step(T, NORTH), NORTH))
	if(V.refill_from_charge(distant, U) || QDELETED(distant) || V.creation_charges != before)
		failure += "A distant user inserted a token. "
	U.forceMove(T)
	U.drop_from_inventory(distant)
	if(V.refill_from_charge(distant, U) || QDELETED(distant) || V.creation_charges != before)
		failure += "An unheld token was accepted. "
	for(var/obj/item/I in T)
		if(!(I in original_items))
			qdel(I)
	qdel(V)
	qdel(U)
	if(failure)
		fail(failure)
	else
		pass("Universal token variants add ten charges; real vending spends its cost; distant/unheld tokens are rejected.")
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
	vent.malfunction_chance = 0
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
	// The current game uses filtering vents; the standalone scrubber was removed.
	// With ample power, one 750 L cycle samples 42 of these 140 moles in 2500 L.
	qdel(T.test_air)
	T.test_air = new(2500, T20C)
	T.test_air.adjust_multi(GAS_OXYGEN, 10, GAS_NITROGEN, 30, GAS_CO2, 100)
	var/obj/machinery/atmospherics/unary/vent_pump/scrubber = new(T)
	if(!scrubber.air_contents || scrubber.air_contents.volume != ATMOS_DEFAULT_VOLUME_PUMP || scrubber.icon)
		failure += "A newly built filtering vent did not finish initialization. "
	scrubber.stat = 0
	scrubber.set_engineering_mode("FILTER")
	scrubber.malfunction_chance = 0
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
		pass("Real gas filtering without modcon cartridge wear, welding, stop mode, finite-reserve refill and single-cycle filtering vent flow verified.")
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
	for(var/vent_type in list(/obj/machinery/atmospherics/unary/vent_pump))
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
		pass("Vent welding and unwelding, held lit tools, fuel, concurrent use, movement/drop/shutdown interruptions and timed solar repair verified.")
	return TRUE


// Supply dialog answers while running the same session and authorization logic
// used by real native inputs. Each answer can race a world-state change.
/datum/engineering_atmos_menu/engineer_test
	var/list/answers = list()
	var/list/prompts = list()
	var/list/reports = list()
	var/change_at = 0
	var/change_kind
	var/atom/change_target
	var/result

/datum/engineering_atmos_menu/engineer_test/proc/change_state()
	if(prompts.len != change_at)
		return
	switch(change_kind)
		if("move")
			user.forceMove(get_step(get_step(get_turf(source), NORTH), NORTH))
		if("power")
			source.stat |= NOPOWER
		if("access")
			source.req_one_access = list(access_engine_equip)
		if("delete")
			qdel(change_target)
		if("lock")
			controller.locked = TRUE
		if("automatic")
			controller.alarm_area.atmos_auto_lockdown = FALSE
		if("selection")
			console.selected_area = null

/datum/engineering_atmos_menu/engineer_test/choose(prompt, title, list/choices)
	prompts += list(list("prompt" = prompt, "title" = title, "choices" = choices.Copy()))
	change_state()
	return answers.len >= prompts.len ? answers[prompts.len] : null

/datum/engineering_atmos_menu/engineer_test/choose_pressure(current)
	prompts += list(list("prompt" = "pressure", "current" = current))
	change_state()
	return answers.len >= prompts.len ? answers[prompts.len] : null

/datum/engineering_atmos_menu/engineer_test/report(message)
	reports += message

/datum/unit_test/engineer_native_atmos
	name = "ENGINEER VIDEO - Native atmosphere menus, reports and stale dialogs"

/datum/unit_test/engineer_native_atmos/proc/run_menu(obj/machinery/source, mob/user, list/answers, change_at = 0, change_kind = null, atom/change_target = null)
	var/datum/engineering_atmos_menu/engineer_test/menu = new(source, user)
	menu.answers = answers
	menu.change_at = change_at
	menu.change_kind = change_kind
	menu.change_target = change_target
	menu.result = menu.interact()
	return menu

/datum/unit_test/engineer_native_atmos/start_test()
	var/failure = ""
	var/turf/unsimulated/floor/engineer_atmos_test/T = engineer_test_turf().ChangeTurf(/turf/unsimulated/floor/engineer_atmos_test)
	T.test_air = new(CELL_VOLUME, T20C)
	T.test_air.adjust_gas(GAS_OXYGEN, PRESSURE_TO_MOLES(100))
	var/area/A = get_area(T)
	var/obj/machinery/alarm/old_master = A.master_air_alarm
	var/list/old_tanks = station_gas_tanks.Copy()
	var/old_name = A.name
	var/old_manual = A.atmos_manual_lockdown
	var/old_auto = A.atmos_auto_lockdown
	var/old_pressure = A.atmos_pressure_lockdown
	var/old_doors = A.air_doors_activated
	A.name = "Engineering <Deck>"
	A.atmos_auto_lockdown = TRUE
	A.atmos_manual_lockdown = FALSE
	var/obj/machinery/station_gas_tank/tank = new(T)
	station_gas_tanks = list(tank)
	tank.stat = 0
	var/obj/machinery/alarm/controller = new(T)
	A.master_air_alarm = controller
	controller.stat = 0
	controller.locked = FALSE
	controller.req_one_access = list()
	var/obj/machinery/computer/station_gas_control/C = new(T)
	C.stat = 0
	C.req_one_access = list()
	var/list/vents = list()
	for(var/i = 1 to 6)
		var/obj/machinery/atmospherics/unary/vent_pump/vent = new(T)
		vent.stat = 0
		vent.malfunction_chance = 0
		vent.set_engineering_mode("FILTER")
		vents += vent
	var/obj/machinery/atmospherics/unary/vent_pump/one = vents[1]
	var/obj/machinery/atmospherics/unary/vent_pump/two = vents[2]
	var/mob/living/carbon/human/U = new(T)
	var/datum/engineering_atmos_menu/engineer_test/menu = run_menu(C, U, list(A.name, "Air Vent 2", "STOP"), 3, "selection")
	if(!menu.result || one.engineering_mode_name() != "FILTER" || two.engineering_mode_name() != "STOP" || menu.prompts.len != 3)
		failure += "Remote native vent selection was redirected or changed the wrong vent. "
	if(menu.prompts.len == 3)
		var/list/areas = menu.prompts[1]["choices"]
		if(menu.prompts[1]["title"] != "Atmospherics Control Console" || menu.prompts[1]["prompt"] != "CHOOSE AREA" || areas[1] != "(SET LOCKDOWN PRESSURE)" || areas[areas.len] != "(CANCEL)")
			failure += "Area dialog labels/order differ from the recording. "
		if(menu.prompts[2]["title"] != "Modcon Unit" || menu.prompts[2]["prompt"] != "CHOOSE AN ACTION" || jointext(menu.prompts[2]["choices"], "|") != "Toggle Lockdown|Disable Auto-Lockdown|Air Vent 1|Air Vent 2|Air Vent 3|Air Vent 4|Air Vent 5|Air Vent 6|ALL VENTS|(Cancel)")
			failure += "Modcon action labels/order differ from the recording. "
		if(jointext(menu.prompts[3]["choices"], "|") != "REFILL|STOP|FILTER|(Cancel)")
			failure += "Vent mode labels/order differ from the recording. "
	if(menu.reports.len != 2 || !findtext(menu.reports[1], "*LOCKDOWN PRESSURE: 60 kPA") || !findtext(menu.reports[2], "Engineering &lt;Deck&gt;") || !findtext(menu.reports[2], "Vent-6") || !findtext(menu.reports[2], "&gt; Pressure: 100 kPa") || findtext(menu.reports[2], "href="))
		failure += "Native report omitted real readings/numbering, failed escaping or included extra command links. "
	fdel("tmp/engineer-video-check/native-atmos-fragment.html")
	text2file(jointext(menu.reports, ""), "tmp/engineer-video-check/native-atmos-fragment.html")
	qdel(menu)
	menu = run_menu(controller, U, list("ALL VENTS", "FILTER"))
	if(!menu.result || menu.prompts.len != 2 || two.engineering_mode_name() != "FILTER")
		failure += "Local all-vent flow did not use the same mode dialog. "
	qdel(menu)
	for(var/list/cancel_answers in list(list("(CANCEL)"), list(A.name, "(Cancel)"), list(A.name, "ALL VENTS", "(Cancel)"), list(A.name, "ALL VENTS", null)))
		menu = run_menu(C, U, cancel_answers)
		if(menu.result || one.engineering_mode_name() != "FILTER")
			failure += "A canceled dialog changed vents. "
		qdel(menu)
	for(var/change in list("move", "power", "access"))
		menu = run_menu(C, U, list(A.name, "ALL VENTS", "STOP"), 3, change)
		if(menu.result || one.engineering_mode_name() != "FILTER")
			failure += "Native commands survived [change] during a dialog. "
		qdel(menu)
		U.forceMove(T)
		C.stat = 0
		C.req_one_access = list()
	menu = run_menu(controller, U, list("ALL VENTS", "STOP"), 2, "lock")
	if(menu.result || one.engineering_mode_name() != "FILTER")
		failure += "A local dialog bypassed a relocked modcon. "
	qdel(menu)
	controller.locked = FALSE
	menu = run_menu(C, U, list(A.name, "Air Vent 6", "STOP"), 3, "delete", vents[6])
	if(menu.result || one.engineering_mode_name() != "FILTER")
		failure += "A removed selected vent became an all-vent command. "
	qdel(menu)
	menu = run_menu(controller, U, list("Disable Auto-Lockdown"), 1, "automatic")
	if(!menu.result || A.atmos_auto_lockdown)
		failure += "A stale Disable action toggled automatic lockdown back on. "
	qdel(menu)
	menu = run_menu(controller, U, list("Enable Auto-Lockdown"))
	if(!menu.result || !A.atmos_auto_lockdown)
		failure += "Enable Auto-Lockdown did not restore automatic control. "
	qdel(menu)
	menu = run_menu(controller, U, list("Toggle Lockdown"))
	if(!menu.result || !A.atmos_manual_lockdown)
		failure += "Native manual lockdown failed. "
	qdel(menu)
	menu = run_menu(C, U, list("(SET LOCKDOWN PRESSURE)", 50))
	if(!menu.result || tank.lockdown_pressure != 50)
		failure += "Native pressure setting failed. "
	qdel(menu)
	menu = run_menu(C, U, list("(SET LOCKDOWN PRESSURE)", 70), 2, "power")
	if(menu.result || tank.lockdown_pressure != 50)
		failure += "An offline pressure dialog still committed. "
	qdel(menu)
	C.stat = 0
	menu = run_menu(C, U, list("(SET LOCKDOWN PRESSURE)", null))
	if(menu.result || tank.lockdown_pressure != 50)
		failure += "Canceling pressure input overwrote the threshold. "
	qdel(menu)
	C.req_one_access = list(access_engine_equip)
	menu = run_menu(C, U, list(A.name, "ALL VENTS", "STOP"))
	if(menu.result || menu.prompts.len != 1 || menu.reports.len != 2 || one.engineering_mode_name() != "FILTER")
		failure += "Read-only viewing offered native control actions. "
	qdel(menu)
	for(var/atom/fixture in vents + list(C, controller, tank, U))
		if(!QDELETED(fixture))
			qdel(fixture)
	station_gas_tanks = old_tanks
	A.master_air_alarm = old_master
	A.name = old_name
	A.atmos_manual_lockdown = old_manual
	A.atmos_auto_lockdown = old_auto
	A.atmos_pressure_lockdown = old_pressure
	A.air_doors_activated = old_doors
	qdel(T.test_air)
	T.ChangeTurf(/turf/unsimulated/floor)
	if(failure)
		fail(failure)
	else
		pass("Native area/action/mode sequence, report numbering, exact menu labels, cancellation, stale-dialog checks and read-only viewing verified.")
	return TRUE

#endif
