// power_node.dm - removed. The global power grid no longer uses CCID link graphs;
// every power machine connects directly to /datum/powernet/power_net. The stubs below
// keep legacy callers compiling; they all no-op or return safe defaults.

GLOBAL_LIST_EMPTY(power_nodes_by_ccid)
var/global/power_grid_dirty = FALSE
var/global/power_ccid_counter = 0

/proc/generate_ccid(prefix = "CC")
	var/candidate
	do
		candidate = "[prefix]-[++power_ccid_counter]"
	while(GLOB.power_nodes_by_ccid[candidate])
	return candidate

/proc/power_node_by_ccid(ccid)
	return GLOB.power_nodes_by_ccid[ccid]

/datum/power_node
	var/ccid
	var/obj/holder
	var/split = FALSE
	var/bridged = FALSE
	var/enabled = TRUE
	var/list/inputs = list()
	var/list/outputs = list()
	var/datum/powernet/in_net
	var/datum/powernet/out_net

	// Legacy bus-consumer fields; inert with the global grid.
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

/datum/power_node/Destroy()
	inputs.Cut()
	outputs.Cut()
	if(GLOB.power_nodes_by_ccid[ccid] == src)
		GLOB.power_nodes_by_ccid -= ccid
	holder = null
	return ..()

/datum/power_node/proc/rename(new_ccid)
	if(!new_ccid || new_ccid == ccid)
		return FALSE
	if(GLOB.power_nodes_by_ccid[new_ccid])
		return FALSE
	GLOB.power_nodes_by_ccid -= ccid
	GLOB.power_nodes_by_ccid[new_ccid] = src
	ccid = new_ccid
	return TRUE

/datum/power_node/proc/set_enabled(new_state)
	enabled = !!new_state

/datum/power_node/proc/has_links()
	return FALSE

/datum/power_node/proc/get_name()
	return holder ? "[holder.name]" : "unknown"

// Legacy linking API; no grid topology to update any more.
/proc/link_power_nodes(datum/power_node/source, datum/power_node/target)
	return FALSE

/proc/unlink_power_nodes(datum/power_node/source, datum/power_node/target)
	return FALSE

/proc/link_power_ccids(source_ccid, target_ccid)
	return FALSE

/proc/sync_power_link_lists()
	return

/proc/rebuild_power_grid()
	power_grid_dirty = FALSE
	return

/////////////////////////////////////////
// Holder side: any /obj can still declare
// the vars; node creation is a no-op.
/////////////////////////////////////////

/obj
	var/datum/power_node/power_node
	var/ccid
	var/list/ccid_inputs
	var/list/ccid_outputs

/obj/proc/is_power_linkable()
	return FALSE

/obj/proc/power_node_is_split()
	return FALSE

/obj/proc/get_power_node(create = TRUE)
	return null

/obj/proc/remove_power_node()
	return

/obj/proc/power_nets_changed(datum/power_node/N)
	return

/obj/proc/leave_power_bus(datum/power_node/N)
	return

/obj/proc/get_input_powernet()
	return power_net

/obj/proc/get_implicit_power_inputs()
	return list()

/obj/proc/get_implicit_power_outputs()
	return list()

/obj/Destroy()
	remove_power_node()
	return ..()