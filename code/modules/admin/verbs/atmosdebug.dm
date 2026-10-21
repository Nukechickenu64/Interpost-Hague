/client/var/list/image/atmos_subarea_markers = list()
/client/var/list/atmos_subarea_colors = list()
/client/var/atmos_subarea_visualizer_enabled = FALSE
/client/var/atmos_subarea_visualizer_generation = 0

/client/proc/visualize_atmos_subareas()
	set category = "Debug"
	set name = "Visualize Atmos Subareas"
	if(!check_rights(R_DEBUG))
		return
	atmos_subarea_visualizer_enabled = !atmos_subarea_visualizer_enabled
	atmos_subarea_visualizer_generation++
	images -= atmos_subarea_markers
	atmos_subarea_markers.Cut()
	atmos_subarea_colors.Cut()
	if(!atmos_subarea_visualizer_enabled)
		clear_atmos_subarea_visualizer()
		to_chat(src, "Atmospheric subarea visualization disabled.")
		return
	SSstatistics.add_field_details("admin_verb", "VASUB")
	to_chat(src, "Atmospheric subarea visualization enabled. Colors identify gas subareas; labels show the mapped power area, tile count, pressure, and temperature. U/D mark open vertical air paths; X marks an isolated deck. Toggle this verb again to disable.")
	refresh_atmos_subarea_visualizer(atmos_subarea_visualizer_generation)

/client/proc/clear_atmos_subarea_visualizer()
	atmos_subarea_visualizer_enabled = FALSE
	atmos_subarea_visualizer_generation++
	images -= atmos_subarea_markers
	atmos_subarea_markers.Cut()
	atmos_subarea_colors.Cut()

/client/proc/refresh_atmos_subarea_visualizer(generation)
	set waitfor = FALSE
	var/icon/subarea_fill = icon('icons/misc/debug_group.dmi', "green")
	subarea_fill.Blend("#ffffff", ICON_ADD)
	while(src && atmos_subarea_visualizer_enabled && generation == atmos_subarea_visualizer_generation)
		images -= atmos_subarea_markers
		atmos_subarea_markers.Cut()
		if(!holder || !(holder.rights & R_DEBUG))
			clear_atmos_subarea_visualizer()
			return
		var/turf/center = get_turf(eye) || get_turf(mob)
		if(center && SSair)
			var/list/labeled_subareas = list()
			var/list/current_colors = list()
			var/list/view_dimensions = getviewsize(view)
			var/half_width = min(16, round(view_dimensions[1] / 2))
			var/half_height = min(16, round(view_dimensions[2] / 2))
			var/turf/lower_corner = locate(max(1, center.x - half_width), max(1, center.y - half_height), center.z)
			var/turf/upper_corner = locate(min(world.maxx, center.x + half_width), min(world.maxy, center.y + half_height), center.z)
			for(var/turf/simulated/tile in block(lower_corner, upper_corner))
				if(!TURF_HAS_VALID_ZONE(tile) || SSair.is_space_turf(tile))
					continue
				var/zone/subarea = tile.zone
				var/subarea_color = atmos_subarea_colors[subarea]
				if(!subarea_color)
					subarea_color = rgb(rand(96, 255), rand(96, 255), rand(96, 255))
				current_colors[subarea] = subarea_color
				var/image/marker = image(subarea_fill, tile)
				marker.plane = ABOVE_LIGHTING_PLANE
				marker.layer = HOLOMAP_LAYER
				marker.mouse_opacity = 0
				marker.alpha = 100
				marker.color = subarea_color
				atmos_subarea_markers += marker
				var/vertical_paths = ""
				if(GLOB.using_map && (tile.z in GLOB.using_map.atmos_isolated_z_levels))
					vertical_paths = "X"
				else
					for(var/direction in list(UP, DOWN))
						var/turf/neighbour = get_zstep(tile, direction)
						if(neighbour && !(SSair.air_blocked(tile, neighbour) & AIR_BLOCKED))
							vertical_paths += direction == UP ? "U" : "D"
				if(length(vertical_paths))
					var/image/vertical_marker = image(loc = tile)
					vertical_marker.plane = ABOVE_LIGHTING_PLANE
					vertical_marker.layer = HOLOMAP_LAYER + 0.1
					vertical_marker.mouse_opacity = 0
					vertical_marker.maptext = "<span style='color: white; font-size: 8px; background-color: black;'>[vertical_paths]</span>"
					atmos_subarea_markers += vertical_marker
				if(!(subarea in labeled_subareas))
					labeled_subareas += subarea
					var/image/label = image(loc = tile)
					label.plane = ABOVE_LIGHTING_PLANE
					label.layer = HOLOMAP_LAYER + 0.2
					label.mouse_opacity = 0
					label.maptext_width = 224
					label.maptext_height = 64
					label.maptext_y = 16
					label.maptext = "<span style='color: white; font-size: 8px; background-color: black;'>[subarea.name] ([subarea.contents.len] tiles)<br>[html_encode(subarea.owner ? subarea.owner.name : "No power area")]<br>[round(subarea.air.return_pressure(), 0.1)] kPa / [round(subarea.air.temperature, 0.1)] K</span>"
					atmos_subarea_markers += label
			atmos_subarea_colors = current_colors
			images += atmos_subarea_markers
		sleep(1 SECOND)

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
