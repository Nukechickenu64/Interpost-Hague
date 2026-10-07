/obj/structure/vehicleparts
	name = "vehicle component"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "part"
	anchored = FALSE
	var/obj/structure/vehicleparts/axis/axis
	var/normal_icon = 'icons/obj/civ13/vehicleparts.dmi'
	var/broken_icon = 'icons/obj/civ13/vehicleparts_damaged.dmi'
	var/obj/structure/vehicleparts/frame/mount

/obj/structure/vehicleparts/MouseDrop(obj/structure/vehicleparts/frame/target, src_location, over_location)
	if(!istype(target) || !target.axis || axis || !usr || usr.incapacitated() || !Adjacent(usr) || !target.Adjacent(usr))
		return
	target.axis.install_component(src, target, usr)

/obj/structure/vehicleparts/attackby(obj/item/tool, mob/user)
	if(axis && (istype(tool, /obj/item/stack/material/phoron) || istype(tool, /obj/item/reagent_containers)))
		return axis.refuel(tool, user, src)
	if(isWrench(tool) && axis && !axis.moving && (!axis.engine || !axis.engine.on))
		var/obj/structure/vehicleparts/axis/chassis = axis
		if(do_after(user, 20, src) && axis == chassis && !chassis.moving && (!chassis.engine || !chassis.engine.on))
			chassis.remove_component(src)
		return
	return ..()

/obj/structure/vehicleparts/Destroy()
	if(axis && axis != src)
		axis.remove_component(src)
	mount = null
	return ..()

/obj/structure/vehicleparts/frame
	name = "steel vehicle frame"
	icon_state = "frame_steel"
	layer = OBJ_LAYER - 0.02
	density = TRUE
	var/list/w_front = list("", FALSE, FALSE, 0, 40, FALSE, FALSE, FALSE)
	var/list/w_back = list("", FALSE, FALSE, 0, 40, FALSE, FALSE, FALSE)
	var/list/w_left = list("", FALSE, FALSE, 0, 40, FALSE, FALSE, FALSE)
	var/list/w_right = list("", FALSE, FALSE, 0, 40, FALSE, FALSE, FALSE)
	var/obj/structure/vehicleparts/movement/mwheel
	var/broken = FALSE
	var/doorcode = 0
	var/override_roof_icon
	var/override_frame_icon
	var/override_color
	var/hasoverlay
	var/noroof = FALSE
	var/removesroof = FALSE
	var/resistance = 150
	var/image/roof
	var/list/wall_health_limits
	var/base_floor_state
	var/base_pixel_x = 0
	var/base_pixel_y = 0
	atom_flags = ATOM_FLAG_CHECKS_BORDER

/obj/structure/vehicleparts/frame/New()
	base_floor_state = icon_state
	base_pixel_x = pixel_x
	base_pixel_y = pixel_y
	..()
	w_front = w_front.Copy()
	w_back = w_back.Copy()
	w_left = w_left.Copy()
	w_right = w_right.Copy()
	wall_health_limits = list(w_front[5], w_back[5], w_left[5], w_right[5])
	update_icon()

/obj/structure/vehicleparts/frame/proc/get_wall(direction)
	if(direction == dir)
		return w_front
	if(direction == turn(dir, 180))
		return w_back
	if(direction == turn(dir, 90))
		return w_left
	if(direction == turn(dir, -90))
		return w_right
	return null

/obj/structure/vehicleparts/frame/proc/wall_blocks(direction)
	for(var/cardinal in GLOB.cardinal)
		if(!(direction & cardinal))
			continue
		var/list/wall = get_wall(cardinal)
		if(wall && wall[3] && wall[5] > 0 && !wall[7])
			return TRUE
	return FALSE

/obj/structure/vehicleparts/frame/CanPass(atom/movable/mover, turf/target, height = 0, air_group = 0)
	if(axis && istype(mover, /obj/item/projectile/civ13_shell) && mover:firing_axis == axis)
		return TRUE
	return !wall_blocks(get_dir(get_turf(src), get_turf(mover)))

/obj/structure/vehicleparts/frame/CheckExit(atom/movable/mover, turf/target)
	if(axis && istype(mover, /obj/item/projectile/civ13_shell) && mover:firing_axis == axis)
		return TRUE
	return !wall_blocks(get_dir(get_turf(src), target))

/obj/structure/vehicleparts/frame/attack_hand(mob/user)
	if(!Adjacent(user) || user.incapacitated())
		return
	var/list/doors = list()
	for(var/direction in GLOB.cardinal)
		var/list/wall = get_wall(direction)
		if(wall && wall[6] && wall[5] > 0)
			doors[dir2text(direction)] = direction
	if(!doors.len)
		return
	var/choice = input(user, "Select a vehicle door", name) as null|anything in doors
	if(!choice || !Adjacent(user) || user.incapacitated())
		return
	var/list/wall = get_wall(doors[choice])
	if(!wall || !wall[6] || wall[5] <= 0)
		return
	wall[7] = !wall[7]
	update_icon()
	playsound(src, 'sound/effects/metal_close.ogg', 35, TRUE)

/obj/structure/vehicleparts/frame/update_icon()
	var/icon/native_dimensions = icon(normal_icon)
	var/floor_icon_file = broken && (base_floor_state in icon_states(broken_icon)) ? broken_icon : normal_icon
	var/floor_state = base_floor_state
	if(!(floor_state in icon_states(floor_icon_file)))
		floor_icon_file = 'icons/obj/civ13/vehicleparts.dmi'
		floor_state = "frame_steel"
	var/icon/floor_dimensions = icon(floor_icon_file)
	icon = floor_icon_file
	icon_state = floor_state
	pixel_x = base_pixel_x + (native_dimensions.Width() - floor_dimensions.Width()) / 2
	pixel_y = base_pixel_y + (native_dimensions.Height() - floor_dimensions.Height()) / 2
	overlays.Cut()
	for(var/direction in GLOB.cardinal)
		var/list/wall = get_wall(direction)
		if(!wall || !length(wall[1]) || wall[1] == "none")
			continue
		var/state = wall[1]
		if(override_frame_icon && direction == dir)
			state = override_frame_icon
		var/wall_icon_file = wall[5] > 0 ? normal_icon : broken_icon
		var/has_open_sprite = FALSE
		if(wall[6] && wall[7] && ("[state]_open" in icon_states(wall_icon_file)))
			state = "[state]_open"
			has_open_sprite = TRUE
		else if(wall[6] && wall[7] && ("[state]open" in icon_states(wall_icon_file)))
			state = "[state]open"
			has_open_sprite = TRUE
		if(!(state in icon_states(wall_icon_file)))
			if(state in icon_states(normal_icon))
				wall_icon_file = normal_icon
			else
				wall_icon_file = 'icons/obj/civ13/vehicleparts.dmi'
				state = wall[6] ? "c_door" : (wall[2] ? "c_wall" : "c_window")
				has_open_sprite = FALSE
		var/icon/wall_sprite = icon(wall_icon_file, state, direction)
		if(wall[6] && wall[7] && !has_open_sprite)
			var/sprite_width = wall_sprite.Width()
			var/sprite_height = wall_sprite.Height()
			if(direction == NORTH || direction == SOUTH)
				wall_sprite.DrawBox(null, round(sprite_width / 8) + 1, 1, sprite_width - round(sprite_width / 8), sprite_height)
			else
				wall_sprite.DrawBox(null, 1, round(sprite_height / 8) + 1, sprite_width, sprite_height - round(sprite_height / 8))
		var/image/border = image(icon = wall_sprite, layer = ABOVE_HUMAN_LAYER)
		border.pixel_x = base_pixel_x - pixel_x + (native_dimensions.Width() - wall_sprite.Width()) / 2
		border.pixel_y = base_pixel_y - pixel_y + (native_dimensions.Height() - wall_sprite.Height()) / 2
		if(wall.len < 8 || !wall[8])
			border.color = override_color ? override_color : (axis ? axis.color : null)
		border.mouse_opacity = 0
		overlays += border
	if(mwheel)
		mwheel.update_icon()
		var/wheel_direction = mwheel.reversed ? turn(dir, 180) : dir
		var/icon/wheel_sprite = icon(mwheel.icon, mwheel.icon_state, wheel_direction)
		var/image/wheel_overlay = image(icon = wheel_sprite, layer = OBJ_LAYER - 0.01)
		wheel_overlay.mouse_opacity = 0
		wheel_overlay.color = mwheel.color
		wheel_overlay.pixel_x = base_pixel_x - pixel_x + (native_dimensions.Width() - wheel_sprite.Width()) / 2
		wheel_overlay.pixel_y = base_pixel_y - pixel_y + (native_dimensions.Height() - wheel_sprite.Height()) / 2
		if(axis)
			var/front = !axis.has_frame(get_step(src, dir))
			var/back = !axis.has_frame(get_step(src, turn(dir, 180)))
			var/right = !axis.has_frame(get_step(src, turn(dir, -90)))
			if(mwheel.ntype == "track")
				var/track_offset = istype(mwheel, /obj/structure/vehicleparts/movement/tracks/m113) || istype(mwheel, /obj/structure/vehicleparts/movement/tracks/mtlb) ? 28 : (istype(mwheel, /obj/structure/vehicleparts/movement/tracks/bmd2) ? 20 : 32)
				var/offset_direction = front ? dir : (back ? turn(dir, 180) : 0)
				wheel_overlay.pixel_x += offset_direction == EAST ? track_offset : (offset_direction == WEST ? -track_offset : 0)
				wheel_overlay.pixel_y += offset_direction == NORTH ? track_offset : (offset_direction == SOUTH ? -track_offset : 0)
				wheel_overlay.color = axis.color
			else if(mwheel.ntype == "wheel")
				var/outward = turn(dir, right ? -90 : 90)
				wheel_overlay.pixel_x += outward == EAST ? 16 : (outward == WEST ? -16 : 0)
				wheel_overlay.pixel_y += outward == SOUTH ? -22 : 0
		overlays += wheel_overlay
	if(!roof)
		roof = image(icon, src)
	var/roof_icon_file = broken ? broken_icon : normal_icon
	var/roof_state = override_roof_icon ? override_roof_icon : replacetext(base_floor_state, "frame", "roof")
	if(!(roof_state in icon_states(roof_icon_file)))
		if(roof_state in icon_states(normal_icon))
			roof_icon_file = normal_icon
		else if("roof_steel" in icon_states(normal_icon))
			roof_icon_file = normal_icon
			roof_state = "roof_steel"
		else
			roof_icon_file = 'icons/obj/civ13/vehicleparts.dmi'
			roof_state = "roof_steel1"
	roof.icon = roof_icon_file
	roof.icon_state = roof_state
	var/icon/roof_dimensions = icon(roof_icon_file)
	roof.pixel_x = base_pixel_x - pixel_x + (native_dimensions.Width() - roof_dimensions.Width()) / 2
	roof.pixel_y = base_pixel_y - pixel_y + (native_dimensions.Height() - roof_dimensions.Height()) / 2
	if(noroof || removesroof)
		roof.icon_state = ""
	roof.dir = dir
	roof.layer = ABOVE_HUMAN_LAYER + 0.2
	roof.mouse_opacity = 0
	roof.color = override_color ? override_color : (axis ? axis.color : null)
	roof.overlays.Cut()
	if(hasoverlay)
		var/body_icon_file = (hasoverlay in icon_states(normal_icon)) ? normal_icon : 'icons/obj/civ13/vehicleparts.dmi'
		var/body_state = (hasoverlay in icon_states(body_icon_file)) ? hasoverlay : "roof_steel1"
		var/image/body_overlay = image(icon = body_icon_file, icon_state = body_state)
		var/icon/body_dimensions = icon(body_icon_file)
		body_overlay.pixel_x = (roof_dimensions.Width() - body_dimensions.Width()) / 2
		body_overlay.pixel_y = (roof_dimensions.Height() - body_dimensions.Height()) / 2
		body_overlay.dir = turn(dir, 180)
		body_overlay.layer = ABOVE_HUMAN_LAYER
		body_overlay.mouse_opacity = 0
		roof.overlays += body_overlay

/obj/structure/vehicleparts/frame/Crossed(atom/movable/mover)
	. = ..()
	if(axis && ismob(mover))
		axis.refresh_roof_visibility()

/obj/structure/vehicleparts/frame/Uncrossed(atom/movable/mover)
	. = ..()
	if(axis && ismob(mover))
		var/obj/structure/vehicleparts/axis/chassis = axis
		spawn(0)
			if(chassis)
				chassis.refresh_roof_visibility()

/obj/structure/vehicleparts/frame/attackby(obj/item/tool, mob/user)
	if(axis && (istype(tool, /obj/item/stack/material/phoron) || istype(tool, /obj/item/reagent_containers)))
		return axis.refuel(tool, user, src)
	if(istype(tool, /obj/item/stack/material/steel))
		if(axis && (axis.moving || (axis.engine && axis.engine.on)))
			return
		var/list/sides = list("Front" = w_front, "Back" = w_back, "Left" = w_left, "Right" = w_right)
		var/side = input(user, "Frame border", name) as null|anything in sides
		if(!side || !Adjacent(user) || user.incapacitated() || tool.loc != user)
			return
		var/list/borders = list(
			"Steel wall" = list("c_wall", TRUE, TRUE, 20, 50, FALSE, FALSE, FALSE),
			"Armored wall" = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE),
			"Door" = list("c_door", TRUE, TRUE, 20, 45, TRUE, TRUE, FALSE),
			"Window" = list("c_window", FALSE, TRUE, 10, 40, FALSE, FALSE, FALSE),
		)
		var/choice = input(user, "Border (3 steel sheets)", name) as null|anything in borders
		if(!choice || !Adjacent(user) || user.incapacitated() || tool.loc != user || (axis && (axis.moving || (axis.engine && axis.engine.on))))
			return
		var/obj/item/stack/material/steel/steel = tool
		if(steel.amount >= 3 && do_after(user, 30, src) && tool.loc == user && Adjacent(user) && (!axis || (!axis.moving && (!axis.engine || !axis.engine.on))) && steel.use(3))
			var/list/wall = sides[side]
			wall.Cut()
			wall.Add(borders[choice])
			wall_health_limits[side == "Front" ? 1 : (side == "Back" ? 2 : (side == "Left" ? 3 : 4))] = wall[5]
			update_icon()
		return
	if(isWelder(tool) && broken)
		var/obj/item/weldingtool/welder = tool
		if((!axis || (!axis.moving && (!axis.engine || !axis.engine.on))) && welder.isOn() && welder.remove_fuel(1, user) && do_after(user, 40, src) && (!axis || (!axis.moving && (!axis.engine || !axis.engine.on))))
			broken = FALSE
			w_front[5] = wall_health_limits[1]
			w_back[5] = wall_health_limits[2]
			w_left[5] = wall_health_limits[3]
			w_right[5] = wall_health_limits[4]
			update_icon()
		return
	if(isWrench(tool) && axis)
		if(axis.moving || (axis.engine && axis.engine.on))
			return
		for(var/obj/structure/vehicleparts/part in axis.modules)
			if(part.mount == src)
				to_chat(user, SPAN_WARNING("Remove the mounted components before dismantling the frame."))
				return
		for(var/mob/living/occupant in get_turf(src))
			to_chat(user, SPAN_WARNING("The frame is occupied."))
			return
		for(var/obj/structure/bed/chair/civ13/seat in get_turf(src))
			if(seat.vehicle_axis == axis)
				to_chat(user, SPAN_WARNING("Remove the connected seats before dismantling the frame."))
				return
		var/obj/structure/vehicleparts/axis/chassis = axis
		if(do_after(user, 30, src) && axis == chassis && !chassis.moving && (!chassis.engine || !chassis.engine.on))
			for(var/client/viewer in chassis.roof_viewers)
				viewer.images -= roof
			chassis.components -= src
			axis = null
			anchored = FALSE
			update_icon()
		return
	return ..()

/obj/structure/vehicleparts/frame/MouseDrop(obj/structure/vehicleparts/frame/target, src_location, over_location)
	if(!istype(target) || !target.axis || axis || !isturf(loc) || target.axis.moving || (target.axis.engine && target.axis.engine.on) || !usr || usr.incapacitated() || !Adjacent(usr) || !target.Adjacent(usr))
		return
	var/direction = get_dir(get_turf(target), get_turf(src))
	if(target.axis.components.len >= 25 || !(direction in GLOB.cardinal))
		to_chat(usr, SPAN_WARNING("The vehicle cannot accommodate another frame here."))
		return
	axis = target.axis
	axis.components += src
	anchored = TRUE
	set_dir(axis.dir)
	axis.refresh_component_icons()

/obj/structure/vehicleparts/frame/Destroy()
	if(axis)
		for(var/obj/structure/bed/chair/civ13/seat in get_turf(src))
			if(seat.vehicle_axis == axis)
				seat.unbind_from_vehicle()
		for(var/client/viewer in axis.roof_viewers)
			viewer.images -= roof
		for(var/obj/structure/vehicleparts/part in axis.modules.Copy())
			if(part.mount == src)
				axis.remove_component(part)
		axis.stopmovementloop()
		axis.components -= src
		axis.refresh_component_icons()
		axis = null
	return ..()

/obj/structure/vehicleparts/movement
	name = "vehicle wheel"
	var/broken = FALSE
	var/reversed = FALSE
	var/ntype = "wheel"
	var/obj/structure/vehicleparts/frame/connected
	var/base_icon = "wheel_t_dark"
	var/movement_icon = "wheel_t_dark_m"
	var/side = "left"
	var/position = "front"

/obj/structure/vehicleparts/movement/update_icon()
	icon_state = axis && axis.moving ? movement_icon : base_icon
	if(broken && ("[base_icon]_broken" in icon_states(icon)))
		icon_state = "[base_icon]_broken"

/obj/structure/vehicleparts/movement/attackby(obj/item/tool, mob/user)
	if(broken && isWelder(tool))
		var/obj/item/weldingtool/welder = tool
		if(welder.isOn() && welder.remove_fuel(1, user) && do_after(user, 40, src))
			broken = FALSE
			if(mount)
				mount.update_icon()
		return
	return ..()

/obj/structure/vehicleparts/movement/tracks
	name = "vehicle track"
	ntype = "track"

/obj/structure/vehicleparts/axis
	name = "vehicle chassis"
	density = FALSE
	anchored = TRUE
	var/list/components = list()
	var/list/wheels = list()
	var/mob/living/driver
	var/obj/structure/vehicleparts/engine/engine
	var/currentspeed = 0
	var/reverse = FALSE
	var/moving = FALSE
	var/vehicle_m_delay = 4
	var/last_vehicle_move = 0
	var/list/modules = list()
	var/vehicle_type = "car"
	var/speeds = 5
	var/maxpower = 50
	var/list/speedlist = list(6, 5, 4, 3, 2)
	var/reg_number = ""
	var/turntimer = 5
	var/last_turn = 0
	var/list/roof_viewers = list()
	var/cruise = FALSE
	var/movement_loop_running = FALSE
	var/space_capable = FALSE
	var/required_thrusters = 2
	var/initialization_error

/obj/structure/vehicleparts/axis/proc/startmovementloop()
	if(movement_loop_running || !can_drive(driver))
		return
	currentspeed = max(1, currentspeed)
	vehicle_m_delay = speedlist.len ? speedlist[min(currentspeed, speedlist.len)] : 4
	cruise = TRUE
	movement_loop_running = TRUE
	spawn()
		while(cruise && can_drive(driver))
			relaymove(driver, reverse ? turn(dir, 180) : dir)
			sleep(max(1, vehicle_m_delay))
		movement_loop_running = FALSE
		stopmovementloop()

/obj/structure/vehicleparts/axis/New()
	..()
	START_PROCESSING(SSobj, src)

/obj/structure/vehicleparts/axis/proc/refuel(obj/item/container, mob/user, atom/refueling_point)
	var/obj/structure/vehicleparts/fueltank/tank = engine ? engine.fueltank : null
	if(!tank)
		for(var/obj/structure/vehicleparts/fueltank/candidate in modules)
			tank = candidate
			break
	if(!tank)
		to_chat(user, SPAN_WARNING("This vehicle has no connected fuel tank."))
		return TRUE
	return tank.refuel(container, user, refueling_point)

/obj/structure/vehicleparts/axis/proc/has_frame(turf/tile)
	if(!tile)
		return FALSE
	for(var/obj/structure/vehicleparts/frame/frame in components)
		if(get_turf(frame) == tile)
			return TRUE
	return FALSE

/obj/structure/vehicleparts/axis/proc/get_exterior_images()
	var/list/exterior_images = list()
	for(var/obj/structure/vehicleparts/frame/frame in components)
		if(frame.roof && (frame.hasoverlay || (!frame.noroof && !frame.removesroof)))
			exterior_images += frame.roof
	for(var/obj/structure/vehicleparts/weapon/weapon in modules)
		if(weapon.exterior_image)
			exterior_images += weapon.exterior_image
	return exterior_images

/obj/structure/vehicleparts/axis/proc/refresh_roof_visibility()
	var/list/current_viewers = list()
	var/list/exterior_images = get_exterior_images()
	for(var/mob/player in GLOB.player_list)
		if(!player.client || get_dist(src, player) > 20 || player.z != z)
			continue
		var/inside = FALSE
		for(var/obj/structure/vehicleparts/frame/frame in components)
			if(get_turf(player) == get_turf(frame))
				inside = TRUE
				break
		if(inside)
			player.client.images -= exterior_images
		else
			current_viewers |= player.client
	for(var/client/viewer in roof_viewers - current_viewers)
		viewer.images -= exterior_images
	for(var/client/viewer in current_viewers)
		viewer.images |= exterior_images
	roof_viewers = current_viewers

/obj/structure/vehicleparts/axis/proc/process()
	refresh_roof_visibility()
	if(moving && !cruise && world.time > last_vehicle_move + vehicle_m_delay * 2)
		stopmovementloop()

/obj/structure/vehicleparts/axis/proc/on_preset_assembled(list/locations)
	return TRUE

/obj/structure/vehicleparts/axis/proc/install_component(obj/structure/vehicleparts/part, obj/structure/vehicleparts/frame/frame, mob/user)
	if(part.axis || frame.axis != src || moving || (engine && engine.on))
		return FALSE
	if(istype(part, /obj/structure/vehicleparts/movement) && space_capable != istype(part, /obj/structure/vehicleparts/movement/thruster))
		if(user)
			to_chat(user, SPAN_WARNING("This chassis requires [space_capable ? "thrusters" : "wheels or tracks"]."))
		return FALSE
	if(istype(part, /obj/structure/vehicleparts/engine))
		if(engine)
			return FALSE
		engine = part
	if(istype(part, /obj/structure/vehicleparts/movement))
		if(frame.mwheel)
			return FALSE
		var/obj/structure/vehicleparts/movement/wheel = part
		wheels += wheel
		frame.mwheel = wheel
		wheel.connected = frame
	part.axis = src
	part.mount = frame
	part.anchored = TRUE
	part.forceMove(get_turf(frame))
	part.set_dir(dir)
	modules |= part
	refresh_fuel_tank()
	if(istype(part, /obj/structure/vehicleparts/weapon))
		var/obj/structure/vehicleparts/weapon/weapon = part
		weapon.setup_crew()
		weapon.update_icon()
	if(istype(part, /obj/structure/vehicleparts/shellrack))
		for(var/obj/structure/vehicleparts/weapon/weapon in modules)
			weapon.try_autoload()
	assign_weapon_controls()
	frame.update_icon()
	return TRUE

/obj/structure/vehicleparts/axis/proc/refresh_component_icons()
	for(var/obj/structure/vehicleparts/frame/frame in components)
		frame.update_icon()

/obj/structure/vehicleparts/axis/proc/refresh_fuel_tank()
	if(!engine)
		return
	if(engine.fueltank && engine.fueltank.axis == src && (engine.fueltank in modules))
		return
	engine.fueltank = null
	for(var/obj/structure/vehicleparts/fueltank/tank in modules)
		engine.fueltank = tank
		break
	if(!engine.fueltank)
		engine.on = FALSE

/obj/structure/vehicleparts/axis/proc/assign_weapon_controls()
	for(var/obj/structure/vehicleparts/weapon/weapon in modules)
		if(weapon.crew.len || (weapon.control_seat && weapon.control_seat.mounted_weapon == weapon))
			continue
		weapon.control_seat = null
		var/obj/structure/bed/chair/civ13/driver/driver_seat
		var/obj/structure/bed/chair/civ13/passenger/gunner/gunner_seat
		for(var/obj/structure/bed/chair/civ13/seat in get_transporting())
			if(seat.vehicle_axis != src || seat.station_control || seat.mounted_weapon)
				continue
			if(istype(seat, /obj/structure/bed/chair/civ13/passenger/gunner))
				gunner_seat = seat
				break
			if(!driver_seat && istype(seat, /obj/structure/bed/chair/civ13/driver))
				driver_seat = seat
		weapon.control_seat = gunner_seat ? gunner_seat : driver_seat

/obj/structure/vehicleparts/axis/proc/get_controlled_weapons(obj/structure/bed/chair/civ13/seat)
	var/list/controlled_weapons = list()
	if(!seat)
		return controlled_weapons
	for(var/obj/structure/vehicleparts/weapon/weapon in modules)
		if(weapon.control_seat == seat)
			controlled_weapons += weapon
	return controlled_weapons

/obj/structure/vehicleparts/axis/proc/remove_component(obj/structure/vehicleparts/part)
	stopmovementloop()
	if(istype(part, /obj/structure/vehicleparts/weapon))
		var/obj/structure/vehicleparts/weapon/weapon = part
		for(var/client/viewer in roof_viewers)
			viewer.images -= weapon.exterior_image
		weapon.clear_aim_marker()
		for(var/mob/user in weapon.ui_users)
			user << browse(null, "window=civ13_weapon")
		weapon.ui_users.Cut()
		weapon.control_seat = null
		for(var/obj/structure/bed/chair/civ13/seat in weapon.crew)
			qdel(seat)
		weapon.crew.Cut()
		for(var/obj/structure/vehicleparts/weapon/gun in weapon.guns)
			gun.axis = null
	modules -= part
	wheels -= part
	if(part == engine)
		engine.on = FALSE
		engine = null
	else if(istype(part, /obj/structure/vehicleparts/fueltank))
		refresh_fuel_tank()
	if(part.mount && part.mount.mwheel == part)
		part.mount.mwheel = null
	if(part.mount)
		part.mount.update_icon()
	if(istype(part, /obj/structure/vehicleparts/movement))
		var/obj/structure/vehicleparts/movement/wheel = part
		wheel.connected = null
	part.mount = null
	part.axis = null
	part.anchored = FALSE
	assign_weapon_controls()
	refresh_component_icons()
	refresh_roof_visibility()
	if(istype(part, /obj/structure/vehicleparts/movement/thruster))
		part.update_icon()

/obj/structure/vehicleparts/axis/MouseDrop(obj/structure/vehicleparts/frame/target, src_location, over_location)
	if(!istype(target) || target.axis || components.len || !usr || usr.incapacitated() || !Adjacent(usr) || !target.Adjacent(usr))
		return
	target.axis = src
	target.anchored = TRUE
	components += target
	forceMove(get_turf(target))
	target.set_dir(dir)
	refresh_component_icons()

/obj/structure/vehicleparts/axis/proc/stopmovementloop()
	cruise = FALSE
	moving = FALSE
	currentspeed = 0
	for(var/obj/structure/vehicleparts/frame/frame in components)
		frame.update_icon()

/obj/structure/vehicleparts/axis/proc/can_drive(mob/user)
	if(user != driver || !user || user.incapacitated() || !components.len || !engine || !engine.on)
		return FALSE
	if(!istype(user.buckled, /obj/structure/bed/chair/civ13/driver) || user.buckled:vehicle_axis != src || user.buckled:buckled_mob != user || !has_frame(get_turf(user)) || engine.health <= 0)
		return FALSE
	if(space_capable)
		var/thruster_count = 0
		for(var/obj/structure/vehicleparts/movement/thruster/thruster in wheels)
			if(!thruster.broken)
				thruster_count++
		return thruster_count >= required_thrusters
	if(wheels.len < (vehicle_type == "bike" ? 2 : 4))
		return FALSE
	for(var/obj/structure/vehicleparts/movement/wheel in wheels)
		if(wheel.broken)
			return FALSE
	return TRUE

/obj/structure/vehicleparts/axis/proc/get_transporting()
	var/list/transporting = list()
	for(var/obj/structure/vehicleparts/frame/frame in components)
		for(var/atom/movable/passenger in get_turf(frame))
			if(passenger == src || (passenger in components))
				continue
			if(ismob(passenger) || istype(passenger, /obj/item) || (passenger in modules) || (istype(passenger, /obj/structure/bed/chair/civ13) && passenger:vehicle_axis == src))
				transporting |= passenger
	return transporting

/obj/structure/vehicleparts/axis/proc/footprint_clear(list/destinations, list/transporting)
	if(!transporting)
		transporting = get_transporting()
	for(var/turf/destination in destinations)
		if(!destination || destination.density || (!space_capable && istype(destination, /turf/space)))
			return FALSE
		if(space_capable && istype(destination, /turf/space) && (destination.x <= TRANSITIONEDGE || destination.x >= world.maxx - TRANSITIONEDGE + 1 || destination.y <= TRANSITIONEDGE || destination.y >= world.maxy - TRANSITIONEDGE + 1))
			return FALSE
		for(var/atom/movable/obstacle in destination)
			if(obstacle in transporting)
				continue
			if(obstacle.density && !(obstacle in components) && !(istype(obstacle, /obj/structure/vehicleparts) && obstacle:axis == src))
				return FALSE
	return TRUE

/obj/structure/vehicleparts/axis/relaymove(mob/user, direction)
	if(!can_drive(user) || !(direction in GLOB.cardinal) || world.time < last_vehicle_move + vehicle_m_delay)
		return FALSE
	if(direction != dir && direction != turn(dir, 180))
		return turn_vehicle(direction)
	reverse = direction != dir
	var/list/destinations = list()
	var/list/transporting = get_transporting()
	vehicle_m_delay = speedlist.len ? speedlist[min(max(1, currentspeed), speedlist.len)] : 4
	for(var/obj/structure/vehicleparts/frame/frame in components)
		var/turf/destination = get_step(frame, direction)
		if(!destination)
			return FALSE
		destinations += destination
	if(!footprint_clear(destinations, transporting))
		stopmovementloop()
		return FALSE
	if(!engine.consume_fuel())
		stopmovementloop()
		return FALSE
	var/list/cargo = list()
	for(var/atom/movable/passenger in transporting)
		cargo[passenger] = get_step(passenger, direction)
	for(var/obj/structure/vehicleparts/frame/frame in components)
		frame.forceMove(get_step(frame, direction))
	forceMove(get_step(src, direction))
	for(var/atom/movable/passenger in cargo)
		passenger.forceMove(cargo[passenger])
	last_vehicle_move = world.time
	moving = TRUE
	currentspeed = max(1, currentspeed)
	for(var/obj/structure/vehicleparts/frame/frame in components)
		frame.update_icon()
	refresh_roof_visibility()
	return TRUE

/obj/structure/vehicleparts/axis/proc/turn_vehicle(direction)
	if(!(direction in GLOB.cardinal) || direction == dir || direction == turn(dir, 180) || world.time < last_turn + turntimer)
		return FALSE
	var/left_turn = direction == turn(dir, 90)
	var/min_x = world.maxx
	var/min_y = world.maxy
	var/max_x = 1
	var/max_y = 1
	for(var/obj/structure/vehicleparts/frame/frame in components)
		min_x = min(min_x, frame.x)
		min_y = min(min_y, frame.y)
		max_x = max(max_x, frame.x)
		max_y = max(max_y, frame.y)
	var/list/destinations = list()
	var/list/moves = list()
	var/list/transporting = get_transporting()
	for(var/obj/structure/vehicleparts/frame/frame in components)
		var/offset_x = frame.x - min_x
		var/offset_y = frame.y - min_y
		var/turf/destination = locate(min_x + (left_turn ? max_y - min_y - offset_y : offset_y), min_y + (left_turn ? offset_x : max_x - min_x - offset_x), z)
		if(!destination)
			return FALSE
		moves[frame] = destination
		destinations += destination
		for(var/atom/movable/passenger in get_turf(frame))
			if(passenger in transporting)
				moves[passenger] = destination
	if(!footprint_clear(destinations, transporting))
		return FALSE
	if(!engine || !engine.consume_fuel())
		stopmovementloop()
		return FALSE
	var/turn_angle = left_turn ? 90 : -90
	for(var/atom/movable/passenger in moves)
		passenger.forceMove(moves[passenger])
		passenger.set_dir(turn(passenger.dir, turn_angle))
		if(istype(passenger, /obj/structure/vehicleparts/weapon))
			var/obj/structure/vehicleparts/weapon/weapon = passenger
			weapon.aim_target = null
			weapon.clear_aim_marker()
			weapon.update_icon()
	forceMove(locate(min_x, min_y, z))
	set_dir(direction)
	last_turn = world.time
	for(var/obj/structure/vehicleparts/frame/frame in components)
		frame.update_icon()
	refresh_roof_visibility()
	return TRUE

/obj/structure/vehicleparts/axis/Destroy()
	STOP_PROCESSING(SSobj, src)
	stopmovementloop()
	for(var/client/viewer in roof_viewers)
		viewer.images -= get_exterior_images()
	roof_viewers.Cut()
	for(var/obj/structure/vehicleparts/part in modules.Copy())
		remove_component(part)
	for(var/obj/structure/vehicleparts/frame/frame in components)
		for(var/obj/structure/bed/chair/civ13/seat in get_turf(frame))
			if(seat.vehicle_axis == src)
				seat.unbind_from_vehicle()
		frame.axis = null
		frame.anchored = FALSE
	for(var/obj/structure/vehicleparts/movement/wheel in wheels)
		wheel.axis = null
	driver = null
	return ..()

/obj/structure/vehicleparts/movement/bullet_act(obj/item/projectile/projectile)
	if(projectile.get_structure_damage() >= 20)
		broken = TRUE
		if(axis)
			axis.stopmovementloop()
		if(mount)
			mount.update_icon()
	return 0

/obj/structure/vehicleparts/movement/ex_act(severity)
	broken = TRUE
	if(axis)
		axis.stopmovementloop()
	if(mount)
		mount.update_icon()

/obj/structure/vehicleparts/axis/spacecraft
	name = "spacecraft chassis"
	desc = "A modular spacecraft chassis with powered attitude control. Requires two working thrusters."
	icon_state = "axis_powered"
	vehicle_type = "spacecraft"
	space_capable = TRUE
	speedlist = list(6, 4, 3, 2)
	speeds = 4

/obj/structure/vehicleparts/movement/thruster
	name = "maneuvering thruster"
	desc = "A vacuum-rated propulsion and attitude-control assembly for a spacecraft chassis."
	icon = 'icons/obj/ship_engine.dmi'
	icon_state = "nozzle"
	ntype = "thruster"
	base_icon = "nozzle"
	movement_icon = "nozzle"

/obj/structure/vehicleparts/movement/thruster/update_icon()
	. = ..()
	color = broken ? "#555555" : null
	set_light(axis && axis.moving && !broken ? 2 : 0, 1, "#71D8FF")

/obj/structure/vehicleparts/movement/thruster/ion
	name = "ion maneuvering thruster"
	desc = "A compact ion nozzle. Its propellant is supplied by the vehicle's fuel system."

/obj/structure/vehicleparts/movement/thruster/heavy
	name = "heavy maneuvering thruster"
	desc = "A reinforced vacuum nozzle for cargo ships and patrol craft."

/obj/structure/vehicleparts/axis/spacecraft/scout
	name = "scout spacecraft chassis"
	speedlist = list(5, 3, 2, 1)
	turntimer = 3

/obj/structure/vehicleparts/axis/spacecraft/freighter
	name = "freighter spacecraft chassis"
	speedlist = list(8, 6, 5)
	speeds = 3
	turntimer = 8

/obj/structure/vehicleparts/frame/spacecraft
	name = "spacecraft deck section"
	desc = "A spacecraft hull section. It provides structural protection, but is not an airtight compartment; use a spacesuit and internals in vacuum."
	icon_state = "frame_steel"
	override_roof_icon = "roof_steel1"
	resistance = 200

/obj/structure/vehicleparts/frame/spacecraft/left
	name = "port hull section"
	w_right = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/right
	name = "starboard hull section"
	w_left = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/nose
	name = "cockpit viewport section"
	w_front = list("c_windshield", FALSE, TRUE, 20, 60, FALSE, FALSE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/nose/left
	name = "port cockpit section"
	w_right = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/nose/right
	name = "starboard cockpit section"
	w_left = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/stern
	name = "aft hull section"
	w_back = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE)
	override_roof_icon = "roof_steel_exhaust"

/obj/structure/vehicleparts/frame/spacecraft/stern/left
	name = "port engine nacelle"
	w_right = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/stern/right
	name = "starboard engine nacelle"
	w_left = list("c_armoredwall", TRUE, TRUE, 55, 90, FALSE, FALSE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/hatch
	name = "spacecraft boarding hatch"
	w_right = list("c_door", TRUE, TRUE, 20, 60, TRUE, TRUE, FALSE)
	override_roof_icon = "roof_steel_hatch"

/obj/structure/vehicleparts/frame/spacecraft/hatch/right
	name = "starboard boarding hatch"
	w_right = list("", FALSE, FALSE, 0, 40, FALSE, FALSE, FALSE)
	w_left = list("c_door", TRUE, TRUE, 20, 60, TRUE, TRUE, FALSE)

/obj/structure/vehicleparts/frame/spacecraft/armored
	name = "reinforced spacecraft deck"
	resistance = 300
	override_roof_icon = "roof_steel2"
