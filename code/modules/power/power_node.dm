// Wireless power grid. Every power-capable object owns a /datum/power_node identified by a CCID.
// Links are directed (source output -> target input); linked endpoints are merged into shared /datum/powernet buses.

GLOBAL_LIST_EMPTY(power_nodes_by_ccid)
var/global/power_grid_dirty = TRUE
var/global/power_ccid_counter = 0

/proc/generate_ccid(prefix = "CC")
	var/candidate
	do
		candidate = "[prefix]-[++power_ccid_counter]"
	while(GLOB.power_nodes_by_ccid[candidate])
	return candidate

/proc/power_node_by_ccid(ccid)
	if(!ccid)
		return null
	return GLOB.power_nodes_by_ccid[ccid]

/datum/power_node
	var/ccid
	var/obj/holder
	var/split = FALSE		// IN and OUT are separate buses (SMES-like)
	var/bridged = FALSE		// split node that currently joins its IN and OUT buses (breaker box)
	var/enabled = TRUE		// disabled nodes keep their links but don't join any bus (e.g. unwrenched)
	var/list/inputs = list()
	var/list/outputs = list()
	var/datum/powernet/in_net
	var/datum/powernet/out_net

	// Ordinary machinery drawing from a bus instead of its area.
	var/on_bus = FALSE
	var/bus_powered = FALSE
	var/bus_oneoff = 0

/datum/power_node/New(obj/new_holder, wanted_ccid, is_split)
	..()
	holder = new_holder
	split = is_split
	if(!wanted_ccid || GLOB.power_nodes_by_ccid[wanted_ccid])
		wanted_ccid = generate_ccid()
	ccid = wanted_ccid
	GLOB.power_nodes_by_ccid[ccid] = src
	power_grid_dirty = TRUE

/datum/power_node/Destroy()
	for(var/other_ccid in inputs)
		var/datum/power_node/N = power_node_by_ccid(other_ccid)
		if(N)
			N.outputs -= ccid
	for(var/other_ccid in outputs)
		var/datum/power_node/N = power_node_by_ccid(other_ccid)
		if(N)
			N.inputs -= ccid
	inputs.Cut()
	outputs.Cut()
	if(GLOB.power_nodes_by_ccid[ccid] == src)
		GLOB.power_nodes_by_ccid -= ccid
	if(on_bus && holder)
		holder.leave_power_bus(src)
	in_net = null
	out_net = null
	if(holder && holder.power_node == src)
		holder.power_node = null
	holder = null
	power_grid_dirty = TRUE
	return ..()

/datum/power_node/proc/set_enabled(new_state)
	if(enabled == new_state)
		return
	enabled = new_state
	power_grid_dirty = TRUE

/datum/power_node/proc/rename(new_ccid)
	if(!new_ccid || new_ccid == ccid || GLOB.power_nodes_by_ccid[new_ccid])
		return FALSE
	var/old_ccid = ccid
	for(var/other_ccid in inputs)
		var/datum/power_node/N = power_node_by_ccid(other_ccid)
		if(N)
			N.outputs -= old_ccid
			N.outputs |= new_ccid
	for(var/other_ccid in outputs)
		var/datum/power_node/N = power_node_by_ccid(other_ccid)
		if(N)
			N.inputs -= old_ccid
			N.inputs |= new_ccid
	GLOB.power_nodes_by_ccid -= old_ccid
	GLOB.power_nodes_by_ccid[new_ccid] = src
	ccid = new_ccid
	if(holder)
		holder.ccid = new_ccid
	power_grid_dirty = TRUE
	return TRUE

/datum/power_node/proc/has_links()
	return length(inputs) || length(outputs)

/datum/power_node/proc/get_name()
	return holder ? "[holder.name]" : "unknown"

// Links source's output to target's input. Returns TRUE on success.
/proc/link_power_nodes(datum/power_node/source, datum/power_node/target)
	if(!source || !target || source == target)
		return FALSE
	if(target.ccid in source.outputs)
		return FALSE
	source.outputs |= target.ccid
	target.inputs |= source.ccid
	power_grid_dirty = TRUE
	return TRUE

/proc/unlink_power_nodes(datum/power_node/source, datum/power_node/target)
	if(!source || !target)
		return FALSE
	if(!(target.ccid in source.outputs) && !(source.ccid in target.inputs))
		return FALSE
	source.outputs -= target.ccid
	target.inputs -= source.ccid
	power_grid_dirty = TRUE
	return TRUE

/proc/link_power_ccids(source_ccid, target_ccid)
	return link_power_nodes(power_node_by_ccid(source_ccid), power_node_by_ccid(target_ccid))

// Link lists may reference nodes that are created later (map loading). Keep both sides symmetric.
/proc/sync_power_link_lists()
	for(var/ccid in GLOB.power_nodes_by_ccid)
		var/datum/power_node/N = GLOB.power_nodes_by_ccid[ccid]
		for(var/in_ccid in N.inputs)
			var/datum/power_node/S = power_node_by_ccid(in_ccid)
			if(S)
				S.outputs |= N.ccid
		for(var/out_ccid in N.outputs)
			var/datum/power_node/T = power_node_by_ccid(out_ccid)
			if(T)
				T.inputs |= N.ccid

/proc/power_endpoint_find(list/parents, key)
	var/root = key
	while(parents[root] != root)
		root = parents[root]
	while(parents[key] != root)
		var/next = parents[key]
		parents[key] = root
		key = next
	return root

/proc/power_endpoint_union(list/parents, a, b)
	var/ra = power_endpoint_find(parents, a)
	var/rb = power_endpoint_find(parents, b)
	if(ra != rb)
		parents[ra] = rb

/datum/power_node/proc/in_key()
	return "[ccid]|i"

/datum/power_node/proc/out_key()
	return split ? "[ccid]|o" : "[ccid]|i"

// Recomputes every bus from the link graph. Old net state is carried over so a relink doesn't black out the grid for a tick.
/proc/rebuild_power_grid()
	power_grid_dirty = FALSE
	sync_power_link_lists()

	var/list/parents = list()
	var/list/active = list()
	for(var/ccid in GLOB.power_nodes_by_ccid)
		var/datum/power_node/N = GLOB.power_nodes_by_ccid[ccid]
		if(!N.enabled || !N.holder || QDELETED(N.holder))
			continue
		if(!istype(N.holder, /obj/machinery/power) && !N.has_links())
			continue
		active[N] = TRUE

	for(var/datum/power_node/N in active)
		var/in_endpoint = N.in_key()
		if(!parents[in_endpoint])
			parents[in_endpoint] = in_endpoint
		if(N.split)
			var/out_endpoint = N.out_key()
			if(!parents[out_endpoint])
				parents[out_endpoint] = out_endpoint
		for(var/out_ccid in N.outputs)
			var/datum/power_node/T = power_node_by_ccid(out_ccid)
			if(!T || !active[T])
				continue
			var/a = N.out_key()
			var/b = T.in_key()
			if(!parents[a])
				parents[a] = a
			if(!parents[b])
				parents[b] = b
			power_endpoint_union(parents, a, b)
		if(N.split && N.bridged)
			var/a = N.in_key()
			var/b = N.out_key()
			if(!parents[a])
				parents[a] = a
			if(!parents[b])
				parents[b] = b
			power_endpoint_union(parents, a, b)

	var/list/old_net_by_key = list()
	for(var/ccid in GLOB.power_nodes_by_ccid)
		var/datum/power_node/N = GLOB.power_nodes_by_ccid[ccid]
		if(N.in_net)
			old_net_by_key[N.in_key()] = N.in_net
		if(N.out_net)
			old_net_by_key[N.out_key()] = N.out_net

	var/list/new_nets = list()
	var/list/sources_per_new = list()
	for(var/key in parents)
		var/root = power_endpoint_find(parents, key)
		var/datum/powernet/PN = new_nets[root]
		if(!PN)
			PN = new /datum/powernet()
			new_nets[root] = PN
			sources_per_new[PN] = list()
		var/datum/powernet/old = old_net_by_key[key]
		if(old)
			sources_per_new[PN] |= old

	var/list/split_count = list()
	for(var/datum/powernet/PN in sources_per_new)
		for(var/datum/powernet/old in sources_per_new[PN])
			split_count[old] = (split_count[old] || 0) + 1
	for(var/datum/powernet/PN in sources_per_new)
		for(var/datum/powernet/old in sources_per_new[PN])
			var/share = split_count[old]
			PN.avail += old.avail / share
			PN.newavail += old.newavail / share
			PN.load += old.load / share
			PN.smes_avail += old.smes_avail / share
			PN.smes_newavail += old.smes_newavail / share
			PN.viewload = max(PN.viewload, old.viewload)
			PN.problem = max(PN.problem, old.problem)

	for(var/ccid in GLOB.power_nodes_by_ccid)
		var/datum/power_node/N = GLOB.power_nodes_by_ccid[ccid]
		var/active_node = active[N]
		var/datum/powernet/new_in = active_node ? new_nets[parents[N.in_key()] ? power_endpoint_find(parents, N.in_key()) : null] : null
		var/datum/powernet/new_out = active_node ? new_nets[parents[N.out_key()] ? power_endpoint_find(parents, N.out_key()) : null] : null
		N.in_net = new_in
		N.out_net = new_out
		if(new_out)
			new_out.nodes[N.holder] = N.holder
		if(N.split && new_in && new_in != new_out)
			new_in.input_nodes[N.holder] = N.holder
		if(N.holder)
			N.holder.power_nets_changed(N)

	for(var/datum/powernet/old in split_count)
		if(!QDELETED(old))
			qdel(old)
	for(var/datum/powernet/PN in SSmachines.powernets.Copy())
		if(!(PN in sources_per_new) && !QDELETED(PN))
			qdel(PN)

/////////////////////////////////////////
// Holder side: any /obj can own a node.
/////////////////////////////////////////

/obj
	var/datum/power_node/power_node
	var/ccid					// mapper-settable CCID; generated if blank
	var/list/ccid_inputs		// mapper-settable CCIDs this object draws from
	var/list/ccid_outputs		// mapper-settable CCIDs this object feeds

/obj/proc/is_power_linkable()
	return FALSE

/obj/proc/power_node_is_split()
	return FALSE

/obj/proc/get_power_node(create = TRUE)
	if(power_node || !create || !is_power_linkable())
		return power_node
	power_node = new /datum/power_node(src, ccid, power_node_is_split())
	ccid = power_node.ccid
	if(length(ccid_inputs))
		power_node.inputs |= ccid_inputs
	if(length(ccid_outputs))
		power_node.outputs |= ccid_outputs
	return power_node

/obj/proc/remove_power_node()
	if(power_node)
		QDEL_NULL(power_node)

/obj/proc/power_nets_changed(datum/power_node/N)
	return

/obj/proc/leave_power_bus(datum/power_node/N)
	return

/obj/proc/get_input_powernet()
	return power_node && power_node.in_net

// Description of non-link supplies (area SMES) shown in the energy boy menu.
/obj/proc/get_implicit_power_inputs()
	return list()

/obj/proc/get_implicit_power_outputs()
	return list()

/obj/Destroy()
	remove_power_node()
	return ..()
