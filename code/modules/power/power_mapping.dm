// Mapping tools for the CCID power grid. All helpers resolve after every atom has initialised, then delete themselves.

GLOBAL_LIST_EMPTY(power_link_tag_members)

/obj/effect/power_link_helper
	name = "power link helper"
	desc = "Mapping helper: links the power object on this tile into the bus named by net_tag."
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x"
	anchored = 1
	simulated = 0
	invisibility = 101
	var/net_tag				// every helper with the same tag joins one bus
	var/port = "both"		// "in" = draws from the bus, "out" = feeds the bus, "both" = plain bus member
	var/target_type			// optional: pick this type when several linkable objects share the tile

/obj/effect/power_link_helper/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/power_link_helper/LateInitialize()
	var/obj/target = find_power_target(loc, target_type)
	if(!target)
		log_error("[type] at [x],[y],[z] found nothing linkable (target_type=[target_type]).")
	else
		apply_link(target.get_power_node())
	qdel(src)

/obj/effect/power_link_helper/proc/apply_link(datum/power_node/N)
	if(!N || !net_tag)
		return
	var/list/members = GLOB.power_link_tag_members[net_tag]
	if(!members)
		members = list()
		GLOB.power_link_tag_members[net_tag] = members
	var/new_out = (port == "out" || port == "both")
	var/new_in = (port == "in" || port == "both")
	var/datum/power_node/first_both
	for(var/datum/power_node/M in members)
		var/m_port = members[M]
		var/m_out = (m_port == "out" || m_port == "both")
		var/m_in = (m_port == "in" || m_port == "both")
		if(m_port == "both" && !first_both)
			first_both = M
		if(port == "both" && m_port == "both")
			continue
		if(new_out && m_in)
			link_power_nodes(N, M)
		else if(new_in && m_out)
			link_power_nodes(M, N)
	if(port == "both" && first_both)
		link_power_nodes(first_both, N)
	members[N] = port

/proc/find_power_target(turf/T, wanted_type)
	if(!T)
		return null
	var/obj/fallback
	for(var/obj/O in T)
		if(istype(O, /obj/effect) || !O.is_power_linkable())
			continue
		if(wanted_type)
			if(istype(O, wanted_type))
				return O
			continue
		if(istype(O, /obj/machinery/power))
			return O
		if(!fallback)
			fallback = O
	return fallback

// Links the object on this tile directly to a CCID; the target may be created later.
/obj/effect/power_link_helper/direct
	name = "direct power link helper"
	desc = "Mapping helper: links the power object on this tile to target_ccid. direction = \"out\" feeds the target, \"in\" draws from it."
	var/target_ccid
	var/direction = "out"

/obj/effect/power_link_helper/direct/apply_link(datum/power_node/N)
	if(!N || !target_ccid)
		return
	if(direction == "in")
		N.inputs |= target_ccid
	else
		N.outputs |= target_ccid
	power_grid_dirty = TRUE

// Gives the object on this tile a fixed CCID so other links can reference it.
/obj/effect/power_link_helper/set_ccid
	name = "set CCID helper"
	desc = "Mapping helper: assigns new_ccid to the power object on this tile."
	var/new_ccid

/obj/effect/power_link_helper/set_ccid/apply_link(datum/power_node/N)
	if(N && new_ccid)
		N.rename(new_ccid)
