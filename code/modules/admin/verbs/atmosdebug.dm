/client/proc/atmosscan()
	set category = "Mapping"
	set name = "Check Piping"
	set background = 1
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return
	SSstatistics.add_field_details("admin_verb","CP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

	if(alert("WARNING: This command should not be run on a live server. Do you want to continue?", "Check Piping", "No", "Yes") == "No")
		return

	to_chat(usr, "Checking for disconnected pipes...")
	//all plumbing - yes, some things might get stated twice, doesn't matter.
	for (var/obj/machinery/atmospherics/plumbing in world)
		if (plumbing.nodealert)
			to_chat(usr, "Unconnected [plumbing.name] located at [plumbing.x],[plumbing.y],[plumbing.z] ([get_area(plumbing.loc)])")

	//Manifolds
	for (var/obj/machinery/atmospherics/pipe/manifold/pipe in world)
		if (!pipe.node1 || !pipe.node2 || !pipe.node3)
			to_chat(usr, "Unconnected [pipe.name] located at [pipe.x],[pipe.y],[pipe.z] ([get_area(pipe.loc)])")

	//Pipes
	for (var/obj/machinery/atmospherics/pipe/simple/pipe in world)
		if (!pipe.node1 || !pipe.node2)
			to_chat(usr, "Unconnected [pipe.name] located at [pipe.x],[pipe.y],[pipe.z] ([get_area(pipe.loc)])")

	to_chat(usr, "Checking for overlapping pipes...")
	next_turf:
		for(var/turf/T)
			for(var/dir in GLOB.cardinal)
				var/list/connect_types = alist(1 = 0, 2 = 0, 3 = 0)
				for(var/obj/machinery/atmospherics/pipe in T)
					if(dir & pipe.initialize_directions)
						for(var/connect_type in pipe.connect_types)
							connect_types[connect_type] += 1
						if(connect_types[1] > 1 || connect_types[2] > 1 || connect_types[3] > 1)
							to_chat(usr, "Overlapping pipe ([pipe.name]) located at [T.x],[T.y],[T.z] ([get_area(T)])")
							continue next_turf
	to_chat(usr, "Done")

/client/proc/powerdebug()
	set category = "Mapping"
	set name = "Check Power"
	if(!src.holder)
		to_chat(src, "Only administrators may use this command.")
		return
	SSstatistics.add_field_details("admin_verb","CPOW") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

	for(var/obj/machinery/power/P in SSmachines.machinery)
		if(istype(P, /obj/machinery/power/area_smes))
			continue
		var/datum/power_node/N = P.power_node
		if(!N || !N.has_links())
			to_chat(usr, "Unlinked power machine: [P] ([P.type]) at [P.x], [P.y], [P.z] in [get_area(P)]")

	for(var/obj/effect/area_power_marker/M in GLOB.area_power_markers)
		if(!GLOB.area_smes_by_id[M.area_id])
			to_chat(usr, "Area power marker with no matching area SMES (area_id=[M.area_id]) at [M.x], [M.y], [M.z] in [get_area(M)]")

	for(var/obj/machinery/power/area_smes/S in SSmachines.machinery)
		if(!S.served_areas.len)
			to_chat(usr, "Area SMES powering nothing: [S] at [S.x], [S.y], [S.z]")
		if(!S.power_node || !S.power_node.has_links())
			to_chat(usr, "Area SMES with no input links: [S] at [S.x], [S.y], [S.z]")

	var/list/checked = list()
	for(var/obj/machinery/M in SSmachines.machinery)
		var/area/A = get_area(M)
		if(!A || checked[A] || !A.requires_power || A.always_unpowered || !(M.z in GLOB.using_map.station_levels))
			continue
		checked[A] = TRUE
		if(!A.area_smes)
			to_chat(usr, "Station area without an area SMES: [A] ([A.type])")
