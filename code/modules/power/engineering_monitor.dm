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

/obj/machinery/computer/engineering_power/classic
	desc = "A grid monitor and local solar deployment controller. Its built-in backup supply can spread the array during a blackout."
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/computer/engineering_power/classic/powered()
	return TRUE

/obj/machinery/power/smes/classic
	desc = "A finite startup reserve that supplies the station until the solar arrays are deployed. It recharges from surplus generation."
	should_be_mapped = TRUE
	capacity = 6000
	input_attempt = TRUE
	input_level = 25000
	input_level_max = 25000
	output_level = 35000
	output_level_max = 35000

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
	desc = "A handheld engineering diagnostic. Use it on a machine or wall to inspect damage, or activate it to read the station power report. Use it on a broken console with a glass shard or processed zbrite bar in your other hand."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "fixboy"
	item_state = "multitool"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_SMALL
	slot_flags = SLOT_BELT
	matter = list("steel" = 500, "glass" = 500)

/obj/item/device/fixboy/afterattack(atom/target, mob/user, proximity)
	if(!proximity || QDELETED(target) || !user.Adjacent(target) || user.incapacitated())
		return
	if(user.get_active_hand() != src && user.get_inactive_hand() != src)
		to_chat(user, SPAN_WARNING("Hold the FixBoy-2000 to use it."))
		return
	playsound(src, 'sound/machines/twobeep.ogg', 30, FALSE)
	if(istype(target, /obj/machinery/computer))
		var/obj/machinery/computer/C = target
		if(C.stat & BROKEN)
			var/obj/item/replacement = user.get_active_hand() == src ? user.get_inactive_hand() : user.get_active_hand()
			var/obj/item/stack/material/bar = replacement
			if(istype(replacement, /obj/item/weapon/material/shard) && (replacement.get_material_name() in list("glass", "rglass")))
				qdel(replacement)
			else if(!istype(bar) || bar.get_material_name() != "glass" || !bar.use(1))
				to_chat(user, SPAN_WARNING("Broken glass detected. Hold a glass shard or processed zbrite bar in your other hand to repair \the [C]."))
				return
			C.set_broken(FALSE)
			playsound(C, 'sound/items/Deconstruct.ogg', 50, TRUE)
			to_chat(user, SPAN_NOTICE("You replace \the [C]'s broken glass."))
		else
			to_chat(user, SPAN_NOTICE("[C.name]: no broken glass detected. [C.stat & NOPOWER ? "No external power." : "Power available."]"))
	else if(istype(target, /obj/machinery/power/solar_base))
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
	if(user.incapacitated() || (user.get_active_hand() != src && user.get_inactive_hand() != src))
		to_chat(user, SPAN_WARNING("Hold the FixBoy-2000 while conscious to read its diagnostics."))
		return
	var/list/data = engineering_power_data()
	var/report = "<b>STATION POWER</b><br>"
	for(var/list/entry in data["areas"])
		report += "[entry["name"]]: [entry["load"]] kW[entry["offline"] ? " (power cut)" : ""]<br>"
	report += "<br>TOTAL DEMAND: [data["demand"]] kW<br>GENERATED: [data["generated"]] kW<br>STORED: [data["stored"]] / [data["capacity"]] MJ<br>Solar output: [data["solar_output"]] kW ([data["working"]] / [data["panels"]] mounts generating)<br>Updated [data["age"]] seconds ago."
	to_chat(user, SPAN_NOTICE(report))

/obj/item/device/fixboy/worn_use(mob/user)
	if(!istype(GLOB.using_map, /datum/map/os13classic))
		return ..()
	if(!isturf(user.loc) || user.incapacitated() || loc != user || !user.isEquipped(src))
		return
	var/obj/item/device/os13_foam_container/container = user.get_equipped_item(slot_back)
	if(!istype(container) || container.spent)
		for(var/obj/item/device/os13_foam_container/held in list(user.get_active_hand(), user.get_inactive_hand()))
			if(!held.spent)
				container = held
				break
	if(!istype(container) || container.spent)
		to_chat(user, SPAN_WARNING("Hold a charged foam container or wear one on your back."))
		return
	var/turf/room = get_turf(user)
	var/turf/breach = get_step(room, user.dir)
	if(!istype(room, /turf/simulated) || !istype(breach, /turf/space) || !(user.dir in GLOB.cardinal) || get_area(room) != get_area(breach) || (SSair.air_blocked(room, breach) & AIR_BLOCKED))
		to_chat(user, SPAN_WARNING("Face an open hull breach from inside its compartment."))
		return
	container.spent = TRUE
	container.icon_state = "dispenser_foam_empty"
	new /obj/structure/foamedmetal/os13_hull_patch(breach)
	user.visible_message(SPAN_NOTICE("[user] seals the breach with expanding metal foam."))

/obj/item/device/os13_foam_container
	name = "Foam Container"
	desc = "A one-shot hull sealant canister. Hold it or wear it on your back, face the breach, and right-click your equipped FixBoy to dispense the foam."
	icon = 'icons/os13/turf/turf/neekothing.dmi'
	icon_state = "dispenser_foam"
	w_class = ITEM_SIZE_NORMAL
	slot_flags = SLOT_BACK
	var/spent = FALSE

/obj/structure/foamedmetal/os13_hull_patch
	name = "metal foam hull patch"
	desc = "A temporary pressure seal over a hull breach."
	atmos_canpass = CANPASS_DENSITY

/obj/structure/foamedmetal/os13_hull_patch/New()
	..()
	update_breach_edges(get_turf(src))

/obj/structure/foamedmetal/os13_hull_patch/Destroy()
	var/turf/breach = get_turf(src)
	. = ..()
	update_breach_edges(breach)

/obj/structure/foamedmetal/os13_hull_patch/proc/update_breach_edges(turf/breach)
	if(!breach)
		return
	for(var/direction in GLOB.cardinal)
		var/turf/simulated/neighbor = get_step(breach, direction)
		if(istype(neighbor))
			SSair.mark_for_update(neighbor)

/datum/autolathe/recipe/fixboy
	name = "FixBoy-2000"
	path = /obj/item/device/fixboy
	category = "Devices and Components"

/datum/design/item/os13_fixboy
	name = "FixBoy-2000"
	id = "os13_fixboy"
	req_tech = list(TECH_ENGINEERING = 1, TECH_DATA = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500, "glass" = 500)
	build_path = /obj/item/device/fixboy
	sort_string = "VAACDI"
