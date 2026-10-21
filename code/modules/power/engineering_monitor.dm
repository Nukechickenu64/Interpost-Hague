// Use one completed grid sample, not area counters which clear between ticks.
/proc/engineering_power_data()
	var/list/areas = list()
	for(var/area/A in power_net.area_loads)
		areas += list(list("name" = html_encode(A.name), "load" = round(power_net.area_loads[A] / 1000, 0.01), "offline" = (!A.powered(EQUIP) && !A.powered(LIGHT) && !A.powered(ENVIRON))))
	areas = sortByKey(areas, "name")
	var/panels = 0
	var/working = 0
	var/retracted = 0
	var/solar_output = 0
	for(var/obj/machinery/power/solar_base/B in GLOB.solar_bases)
		panels++
		if(!B.deployed)
			retracted++
		var/output = B.power_output()
		if(output)
			working++
		solar_output += output
	return list("areas" = areas, "demand" = round(power_net.viewload / 1000, 0.01), "generated" = round(power_net.generated / 1000, 0.01), "stored" = round(power_net.stored_energy * 3600 / 1000000, 0.01), "capacity" = round(power_net.storage_capacity * 3600 / 1000000, 0.01), "age" = round((world.time - power_net.sampled_at) / 10, 0.1), "panels" = panels, "working" = working, "retracted" = retracted, "solar_output" = round(solar_output / 1000, 0.01))

/obj/machinery/computer/engineering_power
	name = "station power control"
	desc = "A station-wide demand monitor and solar array deployment console."
	icon_screen = "power"
	req_access = list(access_engine_equip)
	circuit = /obj/item/circuitboard/engineering_power
	var/array_id = "station"

/obj/machinery/computer/engineering_power/attack_hand(mob/user)
	if(..())
		return
	ui_interact(user)

/obj/machinery/computer/engineering_power/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = TRUE)
	var/list/data = engineering_power_data()
	data["can_control"] = allowed(user)
	data["array_id"] = array_id
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "engineering_power.tmpl", name, 580, 620)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(TRUE)

/obj/machinery/computer/engineering_power/proc/set_array_deployed(new_state)
	var/changed = 0
	for(var/obj/machinery/power/solar_base/B in GLOB.solar_bases)
		if(B.array_id != array_id || !AreConnectedZLevels(z, B.z))
			continue
		B.deployed = !!new_state
		B.last_output = 0
		B.update_icon()
		changed++
	return changed

/obj/machinery/computer/engineering_power/OnTopic(mob/user, href_list)
	if(!allowed(user) || (stat & (NOPOWER|BROKEN)))
		return TOPIC_HANDLED
	if(href_list["deploy"] == "1" || href_list["deploy"] == "0")
		var/deploy = href_list["deploy"] == "1"
		var/changed = set_array_deployed(deploy)
		to_chat(user, SPAN_NOTICE("[changed] solar mounts are now [deploy ? "spread" : "retracted"]."))
		return TOPIC_REFRESH

/obj/item/circuitboard/engineering_power
	name = "circuit board (station power control)"
	build_path = /obj/machinery/computer/engineering_power
	origin_tech = list(TECH_POWER = 2, TECH_DATA = 1)

/datum/design/circuit/engineering_power
	name = "station power control"
	id = "engineering_power"
	build_path = /obj/item/circuitboard/engineering_power
	req_tech = list(TECH_POWER = 2, TECH_DATA = 1)

/obj/item/device/fixboy
	name = "FixBoy-2000"
	desc = "A handheld engineering diagnostic. Use it on a machine or wall to inspect damage, or activate it to read the station power report."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "fixboy"
	w_class = ITEM_SIZE_SMALL
	slot_flags = SLOT_BELT
	matter = list("steel" = 500, "glass" = 500)

/obj/item/device/fixboy/afterattack(atom/target, mob/user, proximity)
	if(!proximity || user.incapacitated())
		return
	playsound(src, 'sound/machines/twobeep.ogg', 30, FALSE)
	if(istype(target, /obj/machinery/power/solar_base))
		var/obj/machinery/power/solar_base/B = target
		B.examine(user)
	else if(istype(target, /turf/simulated/wall))
		var/turf/simulated/wall/W = target
		to_chat(user, SPAN_NOTICE("[W.name]: [W.damage ? "structural damage detected; repair with a welder" : "no structural defects detected"]."))
	else if(istype(target, /obj/machinery))
		var/obj/machinery/M = target
		to_chat(user, SPAN_NOTICE("[M.name]: [M.stat & BROKEN ? "mechanical fault detected" : "no mechanical fault detected"]. [M.stat & NOPOWER ? "No external power." : "Power available."]"))
	else
		to_chat(user, SPAN_NOTICE("No serviceable machinery detected."))

/obj/item/device/fixboy/attack_self(mob/user)
	var/list/data = engineering_power_data()
	var/report = "<b>STATION POWER</b><br>"
	for(var/list/entry in data["areas"])
		report += "[entry["name"]]: [entry["load"]] kW[entry["offline"] ? " (power cut)" : ""]<br>"
	report += "<br>TOTAL DEMAND: [data["demand"]] kW<br>GENERATED: [data["generated"]] kW<br>STORED: [data["stored"]] / [data["capacity"]] MJ<br>Solar output: [data["solar_output"]] kW ([data["working"]] / [data["panels"]] mounts generating)<br>Updated [data["age"]] seconds ago."
	to_chat(user, SPAN_NOTICE(report))

/datum/autolathe/recipe/fixboy
	name = "FixBoy-2000"
	path = /obj/item/device/fixboy
	category = "Devices and Components"
