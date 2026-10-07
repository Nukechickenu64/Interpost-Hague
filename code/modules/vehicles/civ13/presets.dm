/obj/effect/civ13_vehicle
	name = "Civ13 ground vehicle"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "axis_powered"
	var/axis_type = /obj/structure/vehicleparts/axis/car
	var/custom_color
	var/doorcode = 0
	var/reg_number = ""
	var/list/tocreate = list()
	var/assembly_error

/obj/effect/civ13_vehicle/Initialize(mapload, manual_assembly = FALSE)
	. = ..()
	if(tocreate.len && !manual_assembly)
		spawn(1)
			assemble()

/obj/effect/civ13_vehicle/proc/get_layout_offsets(spawn_direction = SOUTH)
	var/list/offsets = list()
	var/max_x = 0
	var/max_y = 0
	for(var/coordinate in tocreate)
		var/list/position = splittext(coordinate, ",")
		var/offset_x = text2num(position[1]) - 1
		var/offset_y = text2num(position[2]) - 1
		offsets[coordinate] = list(offset_x, offset_y)
		max_x = max(max_x, offset_x)
		max_y = max(max_y, offset_y)
	for(var/coordinate in offsets)
		var/list/position = offsets[coordinate]
		var/offset_x = position[1]
		var/offset_y = position[2]
		switch(spawn_direction)
			if(NORTH)
				offsets[coordinate] = list(max_x - offset_x, max_y - offset_y)
			if(EAST)
				offsets[coordinate] = list(max_y - offset_y, offset_x)
			if(WEST)
				offsets[coordinate] = list(offset_y, max_x - offset_x)
	return offsets

/obj/effect/civ13_vehicle/proc/assemble(spawn_direction = SOUTH)
	assembly_error = null
	if(!tocreate.len)
		assembly_error = "This vehicle has no assembly layout."
		return FALSE
	var/list/locations = list()
	var/list/offsets = get_layout_offsets(spawn_direction)
	var/obj/structure/vehicleparts/axis/chassis_type = axis_type
	for(var/coordinate in tocreate)
		var/list/offset = offsets[coordinate]
		var/turf/tile = locate(x + offset[1], y + offset[2], z)
		if(!tile || tile.density || (!initial(chassis_type.space_capable) && istype(tile, /turf/space)))
			assembly_error = "The footprint extends into unsupported terrain or beyond the map at layout tile [coordinate]."
			visible_message(SPAN_WARNING("There is not enough space to assemble [name]."))
			return FALSE
		if(initial(chassis_type.space_capable) && istype(tile, /turf/space) && (tile.x <= TRANSITIONEDGE || tile.x >= world.maxx - TRANSITIONEDGE + 1 || tile.y <= TRANSITIONEDGE || tile.y >= world.maxy - TRANSITIONEDGE + 1))
			assembly_error = "Spacecraft cannot be assembled in the map-edge transition zone at layout tile [coordinate]."
			return FALSE
		for(var/atom/movable/obstacle in tile)
			if(obstacle.density || ismob(obstacle) || istype(obstacle, /obj/structure/vehicleparts) || istype(obstacle, /obj/structure/bed/chair/civ13))
				assembly_error = "[obstacle] blocks the footprint at ([tile.x],[tile.y],[tile.z])."
				visible_message(SPAN_WARNING("[name] cannot be assembled on an occupied tile."))
				return FALSE
		locations[coordinate] = tile
	var/obj/structure/vehicleparts/axis/chassis = new axis_type(get_turf(src))
	chassis.set_dir(spawn_direction)
	if(custom_color)
		chassis.color = custom_color
	chassis.reg_number = reg_number
	var/list/created_parts = list()
	var/list/seats = list()
	var/list/created_atoms = list(chassis)
	for(var/coordinate in tocreate)
		var/list/component_types = tocreate[coordinate]
		var/turf/tile = locations[coordinate]
		for(var/component_type in component_types)
			var/atom/movable/component = new component_type(tile)
			if(!component)
				assembly_error = "Unable to create component [component_type]."
				for(var/atom/movable/created in created_atoms)
					qdel(created)
				return FALSE
			created_atoms += component
			component.set_dir(spawn_direction)
			if(istype(component, /obj/structure/vehicleparts/frame))
				var/obj/structure/vehicleparts/frame/frame = component
				frame.axis = chassis
				frame.anchored = TRUE
				if(doorcode)
					frame.doorcode = doorcode
				chassis.components += frame
			else if(istype(component, /obj/structure/vehicleparts))
				created_parts += component
			else if(istype(component, /obj/structure/bed/chair/civ13))
				seats += component
	for(var/obj/structure/vehicleparts/part in created_parts)
		var/installed = FALSE
		for(var/obj/structure/vehicleparts/frame/frame in chassis.components)
			if(get_turf(frame) == get_turf(part))
				installed = chassis.install_component(part, frame)
				break
		if(!installed)
			assembly_error = "Unable to install [part.name] into the preset layout."
			for(var/atom/movable/created in created_atoms)
				qdel(created)
			return FALSE
	for(var/obj/structure/bed/chair/civ13/seat in seats)
		if(!seat.bind_to(chassis))
			assembly_error = "Unable to connect [seat.name] to the preset layout."
			for(var/atom/movable/created in created_atoms)
				qdel(created)
			return FALSE
	if(!chassis.on_preset_assembled(locations))
		assembly_error = chassis.initialization_error || "Unable to initialize this vehicle's special systems."
		for(var/atom/movable/created in created_atoms)
			qdel(created)
		return FALSE
	chassis.refresh_component_icons()
	if(chassis.speedlist.len)
		chassis.vehicle_m_delay = chassis.speedlist[1]
	chassis.process()
	qdel(src)
	return TRUE

/client/proc/vehicle_menu()
	set name = "Vehicle Menu"
	set category = "Admin"
	set desc = "Select a ground vehicle or spacecraft and choose where to spawn it."

	if(!check_rights(R_SPAWN) || !mob)
		return
	if(holder.callproc && holder.callproc.waiting_for_click)
		to_chat(src, SPAN_WARNING("Finish or cancel the current atom selection first."))
		return
	clear_vehicle_placement()
	var/list/vehicles = list()
	for(var/vehicle_type in subtypesof(/obj/effect/civ13_vehicle))
		var/obj/effect/civ13_vehicle/preset = new vehicle_type(null, TRUE)
		var/list/layout = preset.tocreate
		if(!layout || !layout.len)
			qdel(preset)
			continue
		var/model_path = replacetext("[vehicle_type]", "/obj/effect/civ13_vehicle/", "")
		vehicles["[preset.name] ([model_path])"] = vehicle_type
		qdel(preset)
	if(!vehicles.len)
		to_chat(src, SPAN_WARNING("No spawnable vehicle presets are available."))
		return
	var/choice = input(src, "Select a vehicle to spawn", "Vehicle Menu") as null|anything in sortList(vehicles)
	if(!choice || !check_rights(R_SPAWN) || !mob)
		return
	var/list/placement_modes = list("North" = NORTH, "South" = SOUTH, "East" = EAST, "West" = WEST, "Mouse" = 0)
	var/mode = input(src, "Placement direction", "Vehicle Menu") as null|anything in placement_modes
	if(!mode || !check_rights(R_SPAWN) || !mob)
		return
	var/facing = placement_modes[mode]
	if(mode == "Mouse")
		var/list/facings = list("North" = NORTH, "South" = SOUTH, "East" = EAST, "West" = WEST)
		var/direction = input(src, "Vehicle facing", "Vehicle Menu", capitalize(dir2text(mob.dir))) as null|anything in facings
		if(!direction || !check_rights(R_SPAWN) || !mob)
			return
		facing = facings[direction]
	var/vehicle_type = vehicles[choice]
	clear_vehicle_placement()
	vehicle_placement_helper = new vehicle_type(null, TRUE)
	vehicle_placement_direction = facing
	vehicle_placement_mouse = mode == "Mouse"
	vehicle_placement_offsets = vehicle_placement_helper.get_layout_offsets(facing)
	vehicle_placement_width = 1
	vehicle_placement_height = 1
	for(var/coordinate in vehicle_placement_offsets)
		var/list/offset = vehicle_placement_offsets[coordinate]
		vehicle_placement_width = max(vehicle_placement_width, offset[1] + 1)
		vehicle_placement_height = max(vehicle_placement_height, offset[2] + 1)
	verbs |= /client/proc/cancel_vehicle_placement
	var/turf/player_tile = get_turf(mob)
	if(!player_tile)
		clear_vehicle_placement()
		return
	var/origin_x = player_tile.x
	var/origin_y = player_tile.y
	if(vehicle_placement_mouse)
		vehicle_placement_old_popup = show_popup_menus
		show_popup_menus = FALSE
		update_vehicle_placement_preview(player_tile)
		to_chat(src, SPAN_NOTICE("Mouse placement: [vehicle_placement_helper.name], facing [dir2text(facing)], [vehicle_placement_width] x [vehicle_placement_height] tiles. Left-click to spawn; right-click or Cancel Vehicle Placement to cancel."))
		return
	switch(facing)
		if(NORTH)
			origin_x -= round((vehicle_placement_width - 1) / 2)
			origin_y++
		if(SOUTH)
			origin_x -= round((vehicle_placement_width - 1) / 2)
			origin_y -= vehicle_placement_height
		if(EAST)
			origin_x++
			origin_y -= round((vehicle_placement_height - 1) / 2)
		if(WEST)
			origin_x -= vehicle_placement_width
			origin_y -= round((vehicle_placement_height - 1) / 2)
	var/turf/origin = locate(origin_x, origin_y, player_tile.z)
	if(!origin)
		to_chat(src, SPAN_WARNING("That placement extends beyond the map."))
		clear_vehicle_placement()
		return
	update_vehicle_placement_preview(origin)
	var/obj/effect/civ13_vehicle/preview_helper = vehicle_placement_helper
	var/confirmation = alert(src, "Spawn [preview_helper.name], facing [dir2text(facing)], in the green [vehicle_placement_width] x [vehicle_placement_height] footprint?", "Vehicle Menu", "Spawn", "Cancel")
	if(vehicle_placement_helper != preview_helper)
		return
	if(confirmation == "Spawn")
		confirm_vehicle_placement()
	else
		clear_vehicle_placement()

/client
	var/obj/effect/civ13_vehicle/vehicle_placement_helper
	var/turf/vehicle_placement_origin
	var/vehicle_placement_direction = SOUTH
	var/vehicle_placement_width = 1
	var/vehicle_placement_height = 1
	var/vehicle_placement_mouse = FALSE
	var/vehicle_placement_old_popup
	var/list/vehicle_placement_offsets = list()
	var/list/vehicle_placement_images = list()
	var/icon/vehicle_placement_bounds_icon
	var/icon/vehicle_placement_arrow_icon

/client/proc/clear_vehicle_placement()
	images -= vehicle_placement_images
	vehicle_placement_images.Cut()
	QDEL_NULL(vehicle_placement_helper)
	vehicle_placement_origin = null
	vehicle_placement_offsets.Cut()
	vehicle_placement_bounds_icon = null
	vehicle_placement_arrow_icon = null
	if(!isnull(vehicle_placement_old_popup))
		show_popup_menus = vehicle_placement_old_popup
		vehicle_placement_old_popup = null
	vehicle_placement_mouse = FALSE
	verbs -= /client/proc/cancel_vehicle_placement

/client/proc/cancel_vehicle_placement()
	set name = "Cancel Vehicle Placement"
	set category = "Admin"
	clear_vehicle_placement()
	to_chat(src, SPAN_NOTICE("Vehicle placement cancelled."))

/client/proc/update_vehicle_placement_preview(turf/origin)
	if(!vehicle_placement_helper || !origin || origin == vehicle_placement_origin)
		return
	images -= vehicle_placement_images
	vehicle_placement_images.Cut()
	vehicle_placement_origin = origin
	var/pixel_width = vehicle_placement_width * world.icon_size
	var/pixel_height = vehicle_placement_height * world.icon_size
	if(!vehicle_placement_bounds_icon)
		vehicle_placement_bounds_icon = icon('icons/turf/overlays.dmi', "greenOverlay")
		vehicle_placement_bounds_icon.Scale(pixel_width, pixel_height)
		vehicle_placement_bounds_icon.DrawBox(null, 1, 1, pixel_width, pixel_height)
		vehicle_placement_bounds_icon.DrawBox("#4DFF70", 1, 1, pixel_width, 2)
		vehicle_placement_bounds_icon.DrawBox("#4DFF70", 1, pixel_height - 1, pixel_width, pixel_height)
		vehicle_placement_bounds_icon.DrawBox("#4DFF70", 1, 1, 2, pixel_height)
		vehicle_placement_bounds_icon.DrawBox("#4DFF70", pixel_width - 1, 1, pixel_width, pixel_height)
		var/icon/arrow = icon('icons/turf/overlays.dmi', "greenOverlay")
		arrow.DrawBox(null, 1, 1, 32, 32)
		arrow.DrawBox("#4DFF70", 14, 5, 18, 20)
		for(var/row = 0, row <= 8, row++)
			arrow.DrawBox("#4DFF70", 16 - row, 27 - row, 16 + row, 27 - row)
		var/angle = vehicle_placement_direction == NORTH ? 0 : (vehicle_placement_direction == SOUTH ? 180 : (vehicle_placement_direction == EAST ? -90 : 90))
		vehicle_placement_arrow_icon = turn(arrow, angle)
	for(var/coordinate in vehicle_placement_offsets)
		var/list/offset = vehicle_placement_offsets[coordinate]
		var/turf/tile = locate(origin.x + offset[1], origin.y + offset[2], origin.z)
		if(!tile)
			continue
		var/image/highlight = image('icons/turf/overlays.dmi', tile, "greenOverlay")
		highlight.alpha = 70
		highlight.plane = HUD_PLANE
		highlight.layer = HUD_ABOVE_HUD_LAYER
		highlight.mouse_opacity = 0
		vehicle_placement_images += highlight
	var/image/bounds = image(vehicle_placement_bounds_icon, origin)
	bounds.plane = HUD_PLANE
	bounds.layer = HUD_ABOVE_HUD_LAYER + 0.1
	bounds.mouse_opacity = 0
	bounds.maptext = "<span style='color:#4DFF70;background-color:#000000;font-weight:bold'>[uppertext(dir2text(vehicle_placement_direction))] [vehicle_placement_width]x[vehicle_placement_height]</span>"
	bounds.maptext_y = pixel_height + 2
	bounds.maptext_width = max(pixel_width, 128)
	bounds.maptext_height = 20
	vehicle_placement_images += bounds
	var/image/facing_arrow = image(vehicle_placement_arrow_icon, origin)
	facing_arrow.plane = HUD_PLANE
	facing_arrow.layer = HUD_ABOVE_HUD_LAYER + 0.2
	facing_arrow.mouse_opacity = 0
	facing_arrow.pixel_x = (pixel_width - world.icon_size) / 2
	facing_arrow.pixel_y = (pixel_height - world.icon_size) / 2
	vehicle_placement_images += facing_arrow
	images += vehicle_placement_images

/client/proc/confirm_vehicle_placement()
	if(!vehicle_placement_helper || !vehicle_placement_origin)
		return
	if(!holder || !(holder.rights & R_SPAWN) || !mob)
		clear_vehicle_placement()
		return
	var/obj/effect/civ13_vehicle/helper = vehicle_placement_helper
	var/turf/origin = vehicle_placement_origin
	var/vehicle_type = helper.type
	var/vehicle_name = helper.name
	var/facing = vehicle_placement_direction
	helper.forceMove(origin)
	if(!helper.assemble(facing))
		to_chat(src, SPAN_WARNING("Vehicle spawn failed: [helper.assembly_error]"))
		helper.forceMove(null)
		if(!vehicle_placement_mouse)
			clear_vehicle_placement()
		return
	vehicle_placement_helper = null
	clear_vehicle_placement()
	log_and_message_admins("spawned vehicle [vehicle_type], facing [dir2text(facing)], at ([origin.x],[origin.y],[origin.z]).")
	SSstatistics.add_field_details("admin_verb", "VEHICLEMENU")
	to_chat(src, SPAN_NOTICE("Spawned [vehicle_name], facing [dir2text(facing)], at ([origin.x],[origin.y],[origin.z])."))

/client/proc/vehicle_placement_turf(atom/target, params)
	if(istype(target, /obj/screen))
		return null
	var/list/modifiers = params2list(params)
	if(modifiers["screen-loc"])
		var/list/position = splittext(modifiers["screen-loc"], ",")
		if(position.len >= 2)
			var/list/screen_x = splittext(position[1], ":")
			var/list/screen_y = splittext(position[2], ":")
			var/cursor_x = text2num(screen_x[1])
			var/cursor_y = text2num(screen_y[1])
			var/view_width
			var/view_height
			if(isnum(view))
				view_width = view * 2 + 1
				view_height = view_width
			else
				var/list/view_dimensions = splittext("[view]", "x")
				if(view_dimensions.len >= 2)
					view_width = text2num(view_dimensions[1])
					view_height = text2num(view_dimensions[2])
			var/turf/center = get_turf(perspective == MOB_PERSPECTIVE ? mob : eye)
			if(!center)
				center = get_turf(mob)
			if(center && view_width && view_height && cursor_x >= 1 && cursor_y >= 1 && cursor_x <= view_width && cursor_y <= view_height)
				return locate(center.x + cursor_x - round(view_width / 2) - 1, center.y + cursor_y - round(view_height / 2) - 1, center.z)
	return get_turf(target)

/client/proc/vehicle_placement_hover(atom/target, control, params)
	if(!vehicle_placement_mouse || !vehicle_placement_helper || (control != "mapwindow.map" && control != "map"))
		return FALSE
	if(!holder || !(holder.rights & R_SPAWN) || !mob)
		clear_vehicle_placement()
		return FALSE
	var/turf/tile = vehicle_placement_turf(target, params)
	if(tile && tile.z == mob.z)
		update_vehicle_placement_preview(tile)
		return TRUE
	return FALSE

/client/proc/vehicle_placement_click(atom/target, control, params)
	if(!vehicle_placement_mouse || !vehicle_placement_helper)
		return FALSE
	var/list/modifiers = params2list(params)
	if(modifiers["right"])
		clear_vehicle_placement()
		to_chat(src, SPAN_NOTICE("Vehicle placement cancelled."))
		return TRUE
	if(control != "mapwindow.map" && control != "map")
		return FALSE
	if(modifiers["left"] && vehicle_placement_hover(target, control, params))
		confirm_vehicle_placement()
	return TRUE

/atom/MouseEntered(location, control, params)
	if(usr && usr.client)
		usr.client.vehicle_placement_hover(src, control, params)
	return ..()

/obj/structure/vehicleparts/headlamp
	name = "vehicle headlamp"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "part"
	light_range = 4
	light_power = 1

/obj/structure/vehicleparts/headlamp/attack_hand(mob/user)
	if(Adjacent(user) && !user.incapacitated())
		set_light(light_range ? 0 : 4)

/obj/structure/vehicleparts/headlamp/spacecraft
	name = "spacecraft searchlight"
	icon_state = "c_lim"

/obj/structure/vehicleparts/frame/motorcycle
	name = "motorcycle frame"
	icon_state = "motorcycle_frame0"
	noroof = TRUE

/obj/structure/vehicleparts/frame/motorcycle/middle
	icon_state = "motorcycle_frame1"

/obj/structure/vehicleparts/frame/motorcycle/rear
	icon_state = "motorcycle_frame2"

/obj/effect/civ13_vehicle/yamasaki/m125
	name = "Yamasaki M125"
	axis_type = /obj/structure/vehicleparts/axis/bike
	custom_color = "#B62C31"
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/motorcycle, /obj/structure/vehicleparts/movement, /obj/structure/vehicleparts/engine/motorcycle),
		"1,2" = list(/obj/structure/vehicleparts/frame/motorcycle/middle, /obj/structure/bed/chair/civ13/driver/motorcycle, /obj/structure/vehicleparts/fueltank/motorcycle),
		"1,3" = list(/obj/structure/vehicleparts/frame/motorcycle/rear, /obj/structure/vehicleparts/movement/reversed),
	)

/obj/structure/vehicleparts/workbench
	name = "vehicle assembly workbench"
	anchored = TRUE
	density = TRUE
	var/list/recipes = list(
		"Steel frame" = /obj/structure/vehicleparts/frame,
		"Chassis" = /obj/structure/vehicleparts/axis/car,
		"Tank chassis" = /obj/structure/vehicleparts/axis/heavy,
		"Engine" = /obj/structure/vehicleparts/engine,
		"Fuel tank" = /obj/structure/vehicleparts/fueltank,
		"Wheel" = /obj/structure/vehicleparts/movement,
		"Tracks" = /obj/structure/vehicleparts/movement/tracks,
		"Driver's seat" = /obj/structure/bed/chair/civ13/driver,
		"Passenger seat" = /obj/structure/bed/chair/civ13/passenger,
		"Cannon" = /obj/structure/vehicleparts/weapon,
		"Ammunition rack" = /obj/structure/vehicleparts/shellrack,
		"Spacecraft chassis" = /obj/structure/vehicleparts/axis/spacecraft,
		"Scout spacecraft chassis" = /obj/structure/vehicleparts/axis/spacecraft/scout,
		"Freighter spacecraft chassis" = /obj/structure/vehicleparts/axis/spacecraft/freighter,
		"Spacecraft deck" = /obj/structure/vehicleparts/frame/spacecraft,
		"Reinforced spacecraft deck" = /obj/structure/vehicleparts/frame/spacecraft/armored,
		"Port hull" = /obj/structure/vehicleparts/frame/spacecraft/left,
		"Starboard hull" = /obj/structure/vehicleparts/frame/spacecraft/right,
		"Cockpit viewport" = /obj/structure/vehicleparts/frame/spacecraft/nose,
		"Port cockpit" = /obj/structure/vehicleparts/frame/spacecraft/nose/left,
		"Starboard cockpit" = /obj/structure/vehicleparts/frame/spacecraft/nose/right,
		"Aft hull" = /obj/structure/vehicleparts/frame/spacecraft/stern,
		"Port engine nacelle" = /obj/structure/vehicleparts/frame/spacecraft/stern/left,
		"Starboard engine nacelle" = /obj/structure/vehicleparts/frame/spacecraft/stern/right,
		"Port boarding hatch" = /obj/structure/vehicleparts/frame/spacecraft/hatch,
		"Starboard boarding hatch" = /obj/structure/vehicleparts/frame/spacecraft/hatch/right,
		"Rocket engine" = /obj/structure/vehicleparts/engine/spacecraft,
		"Ion propulsion plant" = /obj/structure/vehicleparts/engine/spacecraft/ion,
		"Heavy rocket engine" = /obj/structure/vehicleparts/engine/spacecraft/heavy,
		"Maneuvering thruster" = /obj/structure/vehicleparts/movement/thruster,
		"Ion thruster" = /obj/structure/vehicleparts/movement/thruster/ion,
		"Heavy thruster" = /obj/structure/vehicleparts/movement/thruster/heavy,
		"Propellant tank" = /obj/structure/vehicleparts/fueltank/spacecraft,
		"Large propellant tank" = /obj/structure/vehicleparts/fueltank/spacecraft/large,
		"Pilot couch" = /obj/structure/bed/chair/civ13/driver/spacecraft,
		"Acceleration couch" = /obj/structure/bed/chair/civ13/passenger/spacecraft,
		"Spacecraft weapons station" = /obj/structure/bed/chair/civ13/passenger/gunner/spacecraft,
		"Spacecraft mass driver" = /obj/structure/vehicleparts/weapon/spacecraft,
		"Spacecraft cargo locker" = /obj/structure/vehicleparts/cargo_hold,
		"Spacecraft searchlight" = /obj/structure/vehicleparts/headlamp/spacecraft,
	)

/obj/structure/vehicleparts/workbench/attackby(obj/item/materials, mob/user)
	if(!istype(materials, /obj/item/stack/material/steel) || !Adjacent(user) || user.incapacitated())
		return ..()
	var/choice = input(user, "Build vehicle component (5 steel sheets)", name) as null|anything in recipes
	if(!choice || !Adjacent(user) || user.incapacitated() || materials.loc != user)
		return
	var/obj/item/stack/material/steel/steel = materials
	if(steel.amount < 5 || !do_after(user, 40, src) || !Adjacent(user) || materials.loc != user || steel.amount < 5)
		return
	var/component_type = recipes[choice]
	if(steel.use(5))
		new component_type(get_turf(user))

/obj/effect/civ13_vehicle/spacecraft
	name = "spacecraft"
	axis_type = /obj/structure/vehicleparts/axis/spacecraft
	custom_color = "#B9CDD4"

/obj/effect/civ13_vehicle/spacecraft/scout
	name = "Kestrel scout spacecraft"
	axis_type = /obj/structure/vehicleparts/axis/spacecraft/scout
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/left, /obj/structure/bed/chair/civ13/driver/spacecraft, /obj/structure/vehicleparts/headlamp/spacecraft),
		"2,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/right, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"1,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch, /obj/structure/vehicleparts/fueltank/spacecraft/full),
		"2,2" = list(/obj/structure/vehicleparts/frame/spacecraft/right, /obj/structure/vehicleparts/cargo_hold),
		"1,3" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/left, /obj/structure/vehicleparts/movement/thruster/ion, /obj/structure/vehicleparts/engine/spacecraft/ion),
		"2,3" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/right, /obj/structure/vehicleparts/movement/thruster/ion),
	)

/obj/effect/civ13_vehicle/spacecraft/shuttle
	name = "Wayfarer passenger shuttle"
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/left, /obj/structure/vehicleparts/headlamp/spacecraft),
		"2,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose, /obj/structure/bed/chair/civ13/driver/spacecraft),
		"3,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/right, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"1,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"2,2" = list(/obj/structure/vehicleparts/frame/spacecraft, /obj/structure/bed/chair/civ13/passenger/spacecraft, /obj/structure/vehicleparts/fueltank/spacecraft/full),
		"3,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch/right, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"1,3" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/left, /obj/structure/vehicleparts/movement/thruster),
		"2,3" = list(/obj/structure/vehicleparts/frame/spacecraft/stern, /obj/structure/vehicleparts/engine/spacecraft, /obj/structure/vehicleparts/cargo_hold),
		"3,3" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/right, /obj/structure/vehicleparts/movement/thruster),
	)

/obj/effect/civ13_vehicle/spacecraft/freighter
	name = "Mule cargo spacecraft"
	axis_type = /obj/structure/vehicleparts/axis/spacecraft/freighter
	custom_color = "#87AF99"
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/left, /obj/structure/vehicleparts/headlamp/spacecraft),
		"2,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose, /obj/structure/bed/chair/civ13/driver/spacecraft),
		"3,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/right, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"1,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch),
		"2,2" = list(/obj/structure/vehicleparts/frame/spacecraft, /obj/structure/vehicleparts/cargo_hold),
		"3,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch/right),
		"1,3" = list(/obj/structure/vehicleparts/frame/spacecraft/left, /obj/structure/vehicleparts/cargo_hold),
		"2,3" = list(/obj/structure/vehicleparts/frame/spacecraft, /obj/structure/vehicleparts/cargo_hold),
		"3,3" = list(/obj/structure/vehicleparts/frame/spacecraft/right, /obj/structure/vehicleparts/cargo_hold),
		"1,4" = list(/obj/structure/vehicleparts/frame/spacecraft/left),
		"2,4" = list(/obj/structure/vehicleparts/frame/spacecraft, /obj/structure/vehicleparts/fueltank/spacecraft/large/full),
		"3,4" = list(/obj/structure/vehicleparts/frame/spacecraft/right),
		"1,5" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/left, /obj/structure/vehicleparts/movement/thruster/heavy),
		"2,5" = list(/obj/structure/vehicleparts/frame/spacecraft/stern, /obj/structure/vehicleparts/engine/spacecraft/heavy),
		"3,5" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/right, /obj/structure/vehicleparts/movement/thruster/heavy),
	)

/obj/effect/civ13_vehicle/spacecraft/patrol
	name = "Lancer patrol spacecraft"
	custom_color = "#B6BEC5"
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/left, /obj/structure/vehicleparts/headlamp/spacecraft),
		"2,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose, /obj/structure/bed/chair/civ13/driver/spacecraft),
		"3,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/right, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"1,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch),
		"2,2" = list(/obj/structure/vehicleparts/frame/spacecraft/armored, /obj/structure/vehicleparts/weapon/spacecraft, /obj/structure/bed/chair/civ13/passenger/gunner/spacecraft),
		"3,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch/right, /obj/structure/vehicleparts/shellrack/full75),
		"1,3" = list(/obj/structure/vehicleparts/frame/spacecraft/left),
		"2,3" = list(/obj/structure/vehicleparts/frame/spacecraft/armored, /obj/structure/vehicleparts/fueltank/spacecraft/large/full),
		"3,3" = list(/obj/structure/vehicleparts/frame/spacecraft/right, /obj/structure/vehicleparts/cargo_hold),
		"1,4" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/left, /obj/structure/vehicleparts/movement/thruster/heavy),
		"2,4" = list(/obj/structure/vehicleparts/frame/spacecraft/stern, /obj/structure/vehicleparts/engine/spacecraft/heavy),
		"3,4" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/right, /obj/structure/vehicleparts/movement/thruster/heavy),
	)

/obj/effect/civ13_vehicle/spacecraft/mining
	name = "Prospector mining shuttle"
	axis_type = /obj/structure/vehicleparts/axis/spacecraft/mining
	custom_color = "#BD9B55"
	tocreate = list(
		"1,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/left, /obj/structure/vehicleparts/headlamp/spacecraft),
		"2,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose, /obj/structure/bed/chair/civ13/driver/spacecraft/mining),
		"3,1" = list(/obj/structure/vehicleparts/frame/spacecraft/nose/right, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"1,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch, /obj/structure/bed/chair/civ13/passenger/spacecraft),
		"2,2" = list(/obj/structure/vehicleparts/frame/spacecraft/armored, /obj/structure/vehicleparts/cargo_hold),
		"3,2" = list(/obj/structure/vehicleparts/frame/spacecraft/hatch/right, /obj/structure/vehicleparts/cargo_hold),
		"1,3" = list(/obj/structure/vehicleparts/frame/spacecraft/left, /obj/structure/vehicleparts/cargo_hold),
		"2,3" = list(/obj/structure/vehicleparts/frame/spacecraft, /obj/structure/vehicleparts/cargo_hold),
		"3,3" = list(/obj/structure/vehicleparts/frame/spacecraft/right, /obj/structure/vehicleparts/cargo_hold),
		"1,4" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/left),
		"2,4" = list(/obj/structure/vehicleparts/frame/spacecraft/stern),
		"3,4" = list(/obj/structure/vehicleparts/frame/spacecraft/stern/right),
	)
