// Handheld tool for viewing and editing CCID power links.
/obj/item/device/energy_boy
	name = "energy boy"
	desc = "A handheld grid configurator. Use it on any powered device to see and edit which CCIDs it draws power from and feeds."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	color = "#ffd24a"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 3
	w_class = ITEM_SIZE_SMALL
	throwforce = 3
	throw_range = 10
	throw_speed = 3
	matter = list(DEFAULT_WALL_MATERIAL = 60, "glass" = 30)
	origin_tech = list(TECH_POWER = 2, TECH_ENGINEERING = 2)
	req_access = list(access_engine_equip)
	var/weakref/target_ref
	var/buffer_ccid

/obj/item/device/energy_boy/resolve_attackby(atom/A, mob/user)
	if(!isobj(A))
		return ..()
	var/obj/O = A
	if(!O.is_power_linkable())
		return ..()
	if(!O.get_power_node())
		return ..()
	target_ref = weakref(O)
	playsound(user, 'sound/machines/twobeep.ogg', 30, 0)
	ui_interact(user)
	return 1

/obj/item/device/energy_boy/attack_self(mob/user)
	if(get_target())
		ui_interact(user)
	else
		to_chat(user, "<span class='notice'>Use \the [src] on a powered device first.</span>")

/obj/item/device/energy_boy/proc/get_target()
	var/obj/O = target_ref && target_ref.resolve()
	if(!O || QDELETED(O))
		target_ref = null
		return null
	return O

/obj/item/device/energy_boy/proc/can_reach_target(mob/user, obj/O)
	return O && user && (loc == user) && user.Adjacent(O) && !user.incapacitated()

/obj/item/device/energy_boy/proc/can_edit(mob/user, obj/O)
	var/needs_access = length(O.req_access) || length(O.req_one_access)
	if(hasvar(O, "locked") && O:locked)
		needs_access = TRUE
	if(!needs_access)
		return TRUE
	return O.allowed(user) || allowed(user)

/obj/item/device/energy_boy/proc/node_entry(ccid, mob/user, obj/from)
	var/datum/power_node/N = power_node_by_ccid(ccid)
	var/list/entry = list("ccid" = ccid, "name" = "<i>missing</i>", "where" = "")
	if(N && N.holder)
		entry["name"] = N.get_name()
		var/area/A = get_area(N.holder)
		entry["where"] = A ? A.name : ""
		if(!AreConnectedZLevels(from.z, N.holder.z))
			entry["where"] += " (unreachable)"
	return entry

/obj/item/device/energy_boy/proc/describe_net(datum/powernet/PN)
	if(!PN)
		return "No bus"
	return "[round(PN.avail)] W available, [round(PN.viewload)] W load"

/obj/item/device/energy_boy/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/obj/O = get_target()
	if(!O)
		return
	var/datum/power_node/N = O.get_power_node()
	if(!N)
		return

	var/list/inputs = list()
	for(var/c in N.inputs)
		inputs += list(node_entry(c, user, O))
	var/list/outputs = list()
	for(var/c in N.outputs)
		outputs += list(node_entry(c, user, O))

	var/data[0]
	data["targetName"] = O.name
	data["ccid"] = N.ccid
	data["split"] = N.split
	data["enabled"] = N.enabled
	data["canEdit"] = can_edit(user, O)
	data["inputs"] = inputs
	data["outputs"] = outputs
	data["implicitInputs"] = O.get_implicit_power_inputs()
	data["implicitOutputs"] = O.get_implicit_power_outputs()
	data["inBus"] = describe_net(N.in_net)
	data["outBus"] = describe_net(N.out_net)
	data["buffer"] = buffer_ccid
	var/datum/power_node/B = power_node_by_ccid(buffer_ccid)
	data["bufferName"] = B ? B.get_name() : null

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "energy_boy.tmpl", "Energy Boy - [O.name]", 520, 520)
		ui.set_initial_data(data)
		ui.open()

/obj/item/device/energy_boy/OnTopic(mob/user, href_list, datum/topic_state/state)
	var/obj/O = get_target()
	if(!can_reach_target(user, O))
		to_chat(user, "<span class='warning'>You need to stay next to the device.</span>")
		return TOPIC_HANDLED
	var/datum/power_node/N = O.get_power_node()
	if(!N)
		return TOPIC_HANDLED

	if(href_list["buffer"])
		buffer_ccid = N.ccid
		to_chat(user, "<span class='notice'>Stored [N.ccid] in the buffer.</span>")
		return TOPIC_REFRESH

	if(!can_edit(user, O))
		to_chat(user, "<span class='warning'>Access denied.</span>")
		return TOPIC_HANDLED

	if(href_list["remove_in"])
		var/datum/power_node/S = power_node_by_ccid(href_list["remove_in"])
		if(S)
			unlink_power_nodes(S, N)
		else
			N.inputs -= href_list["remove_in"]
			power_grid_dirty = TRUE
		log_and_message_admins("removed power link [href_list["remove_in"]] -> [N.ccid] ([O]) with an energy boy.", user, get_turf(O))
	else if(href_list["remove_out"])
		var/datum/power_node/T = power_node_by_ccid(href_list["remove_out"])
		if(T)
			unlink_power_nodes(N, T)
		else
			N.outputs -= href_list["remove_out"]
			power_grid_dirty = TRUE
		log_and_message_admins("removed power link [N.ccid] ([O]) -> [href_list["remove_out"]] with an energy boy.", user, get_turf(O))
	else if(href_list["add_in"] || href_list["add_out"] || href_list["add_in_ccid"] || href_list["add_out_ccid"] || href_list["link_buffer_in"] || href_list["link_buffer_out"])
		var/as_input = href_list["add_in"] || href_list["add_in_ccid"] || href_list["link_buffer_in"]
		var/other_ccid = buffer_ccid
		if(href_list["add_in_ccid"] || href_list["add_out_ccid"])
			other_ccid = href_list["add_in_ccid"] || href_list["add_out_ccid"]
		else if(href_list["add_in"] || href_list["add_out"])
			var/list/choices = list()
			var/list/choice_labels = list()
			for(var/obj/machinery/M in SSmachines.machinery)
				if(AreConnectedZLevels(O.z, M.z))
					M.get_power_node()
			for(var/candidate_ccid in GLOB.power_nodes_by_ccid)
				var/datum/power_node/candidate = power_node_by_ccid(candidate_ccid)
				if(!candidate || QDELETED(candidate) || !candidate.holder || QDELETED(candidate.holder) || candidate == N)
					continue
				var/candidate_id = candidate.ccid
				if(!AreConnectedZLevels(O.z, candidate.holder.z) || !can_edit(user, candidate.holder))
					continue
				if(N.inputs.Find(candidate_id) || N.outputs.Find(candidate_id))
					continue
				var/area/candidate_area = get_area(candidate.holder)
				choices[candidate_id] = TRUE
				choice_labels += "[candidate_id] | [candidate.get_name()] ([candidate_area ? candidate_area.name : "No area"]);"
			if(!choices.len)
				to_chat(user, "<span class='notice'>No other reachable power nodes are available.</span>")
				return TOPIC_HANDLED
			var/selected_ccid = sanitize(input(user, "Available CCIDs:\n[jointext(choice_labels, "\n")]\nEnter a CCID to [as_input ? "draw power from" : "feed power to"].", "Energy Boy") as text|null, 64)
			if(selected_ccid && choices[selected_ccid])
				other_ccid = selected_ccid
			if(!other_ccid || !can_reach_target(user, O))
				return TOPIC_HANDLED
		var/datum/power_node/other = power_node_by_ccid(other_ccid)
		if(!other || !other.holder)
			to_chat(user, "<span class='warning'>No device with CCID [other_ccid] responds.</span>")
			return TOPIC_HANDLED
		if(other == N)
			to_chat(user, "<span class='warning'>A device can't be linked to itself.</span>")
			return TOPIC_HANDLED
		if(!AreConnectedZLevels(O.z, other.holder.z))
			to_chat(user, "<span class='warning'>[other_ccid] is out of range.</span>")
			return TOPIC_HANDLED
		if(!can_edit(user, other.holder))
			to_chat(user, "<span class='warning'>Access denied for [other.get_name()].</span>")
			return TOPIC_HANDLED
		var/linked = as_input ? link_power_nodes(other, N) : link_power_nodes(N, other)
		if(linked)
			to_chat(user, "<span class='notice'>Linked [as_input ? "[other.ccid] -> [N.ccid]" : "[N.ccid] -> [other.ccid]"].</span>")
			log_and_message_admins("linked power [as_input ? "[other.ccid] -> [N.ccid]" : "[N.ccid] -> [other.ccid]"] ([O]) with an energy boy.", user, get_turf(O))
		else
			to_chat(user, "<span class='warning'>That link already exists.</span>")
	return TOPIC_REFRESH
