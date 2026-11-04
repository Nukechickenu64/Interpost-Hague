/area/os13_remote_regression
	name = "Remote device regression room"
	requires_power = FALSE
	dynamic_lighting = FALSE

/datum/engineering_atmos_menu/os13_fixboy/regression
	var/choices = 0

/datum/engineering_atmos_menu/os13_fixboy/regression/choose(prompt, title, list/options)
	choices++
	if(choices == 1)
		return "ALL VENTS"
	// Simulate the target being locked while the second native dialog is open.
	controller.locked = TRUE
	return "REFILL"

/datum/os13_object_regression/proc/check_remote_objects()
	var/area/first = new /area/os13_remote_regression
	var/area/second = new /area/os13_remote_regression
	for(var/x = 14, x <= 20, x++)
		for(var/y = 24, y <= 27, y++)
			var/turf/tile = locate(x,y,1)
			tile = tile.ChangeTurf(/turf/unsimulated/floor)
			first.contents.Add(tile)
	for(var/x = 24, x <= 28, x++)
		for(var/y = 24, y <= 27, y++)
			var/turf/tile = locate(x,y,1)
			tile = tile.ChangeTurf(/turf/unsimulated/floor)
			second.contents.Add(tile)
	var/turf/operator_turf = locate(15,25,1)
	var/mob/living/carbon/human/user = new(operator_turf)
	var/obj/machinery/alarm/alarm = new(locate(19,25,1))
	var/obj/machinery/alarm/other_alarm = new(locate(25,25,1))
	first.master_air_alarm = alarm
	second.master_air_alarm = other_alarm
	alarm.alarm_area = first
	other_alarm.alarm_area = second
	alarm.stat = other_alarm.stat = 0
	alarm.locked = other_alarm.locked = FALSE
	alarm.rcon_setting = other_alarm.rcon_setting = 3 // RCON_YES is local to alarm.dm.
	alarm.req_access = other_alarm.req_access = list()
	alarm.req_one_access = other_alarm.req_one_access = list(access_atmospherics)
	var/obj/machinery/atmospherics/unary/vent_pump/vent = new(locate(19,26,1))
	var/obj/machinery/atmospherics/unary/vent_pump/other_vent = new(locate(25,26,1))
	vent.stat = other_vent.stat = 0
	vent.set_engineering_mode("FILTER")
	other_vent.set_engineering_mode("FILTER")
	var/obj/item/device/fixboy/advanced/fixboy = new(operator_turf)
	user.put_in_hands(fixboy)
	expect(!fixboy.can_control(user, alarm), "Advanced FixBoy granted control without an engineering keycard.")
	var/obj/item/card/id/card = new(operator_turf)
	card.access = list(access_atmospherics, access_engine)
	user.put_in_hands(card)
	expect(!user.Adjacent(alarm) && fixboy.can_control(user, alarm), "Advanced FixBoy did not establish actual authorized remote control.")
	expect(fixboy.send_command(user, alarm, list("modcon" = "vent", "vent" = "all", "mode" = "STOP")) && !vent.use_power && other_vent.use_power, "Remote stop failed or changed another area's vent.")
	expect(!fixboy.send_command(user, alarm, list("modcon" = "vent", "vent" = "\ref[other_vent]", "mode" = "STOP")) && other_vent.use_power, "A foreign-area vent reference crossed remote area boundaries.")
	fixboy.send_command(user, alarm, list("modcon" = "vent", "vent" = "all", "mode" = "FILTER"))
	var/datum/engineering_atmos_menu/os13_fixboy/regression/menu = new(fixboy, user, alarm)
	expect(!menu.interact() && vent.engineering_mode_name() == "FILTER", "A target locked during the menu still committed a remote vent command.")
	qdel(menu)
	alarm.locked = FALSE
	alarm.rcon_setting = 1 // RCON_NO.
	expect(!fixboy.send_command(user, alarm, list("modcon" = "automatic")), "Remote-disabled Modcon accepted a device command.")
	alarm.rcon_setting = 3
	alarm.stat = NOPOWER
	expect(!fixboy.can_control(user, alarm), "Unpowered Modcon remained remotely controllable.")
	alarm.stat = 0
	card.access = list()
	expect(!fixboy.can_control(user, alarm), "Removing the engineering authorization did not revoke the remote link.")
	card.access = list(access_atmospherics, access_engine)
	user.drop_from_inventory(fixboy)
	expect(!fixboy.can_control(user, alarm), "Dropped Advanced FixBoy retained its remote link.")
	expect(!alarm.apply_modcon_action(user, list("modcon" = "vent", "vent" = "all", "mode" = "STOP")) && vent.use_power, "Adding a remote device weakened the ordinary local Modcon proximity check.")
	qdel(fixboy)
	world.log << "OS13_OBJECT_CHECK: Advanced FixBoy remote commands, area isolation, access, power and dialog revalidation"

	var/obj/machinery/computer/bridge/bridge = new(locate(19,25,1))
	bridge.stat = 0
	var/obj/item/device/os13_remcom/remcom = new(operator_turf)
	user.put_in_hands(remcom)
	expect(!remcom.can_connect(user, bridge), "RemCom allowed an engineering-only card to issue bridge commands.")
	card.access = list(access_heads, access_captain, access_atmospherics, access_engine)
	expect(remcom.can_connect(user, bridge) && bridge.os13_command_available(user, remcom), "RemCom could not establish a real distant bridge link.")
	expect(!bridge.os13_command_available(user), "Adding RemCom bypassed ordinary local bridge proximity.")
	var/initial_salvage = GLOB.os13_salvage_authorized
	expect(remcom.perform(user, bridge, "Toggle Salvage Permission") && GLOB.os13_salvage_authorized != initial_salvage, "RemCom did not operate the actual shared bridge salvage policy.")
	bridge.stat = NOPOWER
	var/last_salvage = GLOB.os13_salvage_authorized
	expect(!remcom.perform(user, bridge, "Toggle Salvage Permission") && GLOB.os13_salvage_authorized == last_salvage, "Power loss did not revoke pending RemCom commands.")
	bridge.stat = 0
	user.drop_from_inventory(remcom)
	expect(!remcom.perform(user, bridge, "Toggle Salvage Permission") && GLOB.os13_salvage_authorized == last_salvage, "Dropped RemCom retained command authority.")
	user.put_in_hands(remcom)
	card.access = list()
	expect(!remcom.can_connect(user, bridge), "Lost command credentials did not revoke the RemCom connection.")
	GLOB.os13_salvage_authorized = initial_salvage
	qdel(remcom)
	qdel(bridge)
	world.log << "OS13_OBJECT_CHECK: RemCom real bridge policy, command authorization, proximity isolation and stale links"
	var/obj/machinery/computer/os13_scout_controls/scout_controls = locate() in locate(154,145,1)
	user.forceMove(locate(154,144,1))
	var/obj/structure/bed/chair/pilot_chair = locate() in get_turf(user)
	expect(pilot_chair.buckle_mob(user), "Pilot could not sit in the stock Scout chair for the control check.")
	// The stock berth can lose power while the full-map simulation runs.
	// Isolate credential behavior; power loss is checked separately above.
	scout_controls.stat = 0
	card.access = list(access_engine)
	expect(!os13_scout_can_use(scout_controls, user, controller, TRUE), "Scout Controls treated a non-pilot access list as pilot authorization.")
	card.access = list(access_mining)
	expect(os13_scout_can_use(scout_controls, user, controller, TRUE), "Scout Controls refused the actual pilot credential.")
	pilot_chair.unbuckle_mob()
	expect(os13_scout_can_use(scout_controls, user, controller, TRUE), "Scout Controls required buckling instead of allowing a nearby authorized pilot.")

	var/datum/research/research = new
	var/datum/design/item/os13_advanced_fixboy/fixboy_design = new
	var/datum/design/item/os13_remcom/remcom_design = new
	var/datum/tech/os13/advanced_fixboy/fixboy_technology = new
	var/datum/tech/os13/remcom/remcom_technology = new
	expect(!research.DesignHasReqs(fixboy_design) && !research.DesignHasReqs(remcom_design), "Remote devices were unlocked without their own source technologies.")
	research.AddTech2Known(fixboy_technology)
	research.AddTech2Known(remcom_technology)
	research.RefreshResearch()
	expect(research.DesignHasReqs(fixboy_design) && research.DesignHasReqs(remcom_design), "Named remote-device imports did not unlock their physical products.")
	var/obj/item/device/fixboy/advanced/new_fixboy = fixboy_design.Fabricate(operator_turf, null)
	var/obj/item/device/os13_remcom/new_remcom = remcom_design.Fabricate(operator_turf, null)
	expect(istype(new_fixboy) && istype(new_remcom), "Remote-device designs fabricated placeholder or incorrect objects.")
	qdel(new_fixboy)
	qdel(new_remcom)
	qdel(fixboy_design)
	qdel(remcom_design)
	qdel(fixboy_technology)
	qdel(remcom_technology)
	qdel(research)
	qdel(user)
	qdel(alarm)
	qdel(other_alarm)
	qdel(vent)
	qdel(other_vent)
	world.log << "OS13_OBJECT_CHECK: Advanced FixBoy and RemCom technology-gated physical fabrication"
