/obj/item/civ13_shell
	name = "vehicle cannon shell"
	icon = 'icons/obj/vehicles.dmi'
	w_class = ITEM_SIZE_LARGE
	var/caliber = 75
	var/atype = "AP"
	var/damage = 100
	var/heavy_armor_penetration = 80
	var/reagent_payload
	var/rounds = 1

/obj/item/civ13_shell/New()
	..()
	if(!istype(src, /obj/item/civ13_shell/magazine))
		name = "[caliber]mm [atype] shell"
	update_icon()

/obj/item/civ13_shell/magazine/update_icon()
	var/base_state = initial(icon_state)
	var/list/states = icon_states(icon)
	var/closest_count
	var/selected_state
	var/prefix = "[base_state]-"
	for(var/state in states)
		if(copytext(state, 1, length(prefix) + 1) != prefix)
			continue
		var/count = text2num(copytext(state, length(prefix) + 1))
		if(!isnull(count) && count >= rounds && (isnull(closest_count) || count < closest_count))
			closest_count = count
			selected_state = state
	if(selected_state)
		icon_state = selected_state
	else if(base_state in states)
		icon_state = base_state
	else if("[base_state]-0" in states)
		icon_state = "[base_state]-0"

/obj/item/projectile/civ13_shell
	name = "vehicle shell"
	damage = 100
	var/caliber = 75
	var/atype = "AP"
	var/heavy_armor_penetration = 80
	var/obj/structure/vehicleparts/axis/firing_axis

/obj/item/projectile/civ13_shell/on_impact(atom/target)
	. = ..()
	if(atype == "HE" || atype == "APHE" || atype == "HEAT")
		explosion(get_turf(target), -1, -1, 1, 2)
	else if(atype == "INCENDIARY")
		var/turf/impact = get_turf(target)
		if(impact)
			impact.hotspot_expose(1200, 100)

/obj/structure/vehicleparts/weapon
	name = "vehicle cannon"
	anchored = TRUE
	density = FALSE
	var/caliber = 75
	var/maxrange = 25
	var/minrange = 0
	var/firedelay = 1
	var/autoloader = FALSE
	var/rotation_speed = 0.5
	var/turret_icon
	var/turret_x = 0
	var/turret_y = 0
	var/turret_color
	var/obj/item/civ13_shell/loaded
	var/obj/structure/vehicleparts/weapon/cannon
	var/cannon_type
	var/list/weapon_types = list()
	var/list/guns = list()
	var/selected_weapon = 1
	var/list/crew = list()
	var/turf/aim_target
	var/next_fire = 0
	var/loading = FALSE
	var/health = 100
	var/machinegun = FALSE
	var/list/ui_users = list()
	var/image/exterior_image
	var/turret_sprite_icon
	var/list/crew_roles = list("gunner", "loader", "commander")
	var/gunner_x = 10
	var/gunner_y = -6
	var/loader_x = -10
	var/loader_y = -6
	var/commander_x = 0
	var/commander_y = 10
	var/list/accepted_ammo = list()
	var/fixed_mount = FALSE
	var/next_rotation = 0
	var/image/aim_marker
	var/obj/structure/bed/chair/civ13/control_seat

/obj/structure/vehicleparts/weapon/proc/get_crew_seat(role)
	for(var/obj/structure/bed/chair/civ13/seat in crew)
		if(role == "gunner" && istype(seat, /obj/structure/bed/chair/civ13/passenger/gunner))
			return seat
		if(role == "loader" && istype(seat, /obj/structure/bed/chair/civ13/passenger/loader))
			return seat
		if(role == "commander" && istype(seat, /obj/structure/bed/chair/civ13/passenger/commander))
			return seat
	return null

/obj/structure/vehicleparts/weapon/proc/accepts_shell(obj/item/civ13_shell/shell)
	if(!shell || shell.rounds <= 0 || shell.caliber != caliber)
		return FALSE
	if(accepted_ammo.len)
		for(var/ammo_type in accepted_ammo)
			if(istype(shell, ammo_type))
				return TRUE
		return FALSE
	return TRUE

/obj/structure/vehicleparts/weapon/proc/try_autoload()
	var/obj/structure/vehicleparts/weapon/gun = cannon ? cannon : src
	if(!axis || !gun.autoloader || gun.loaded || gun.loading || health <= 0 || gun.health <= 0)
		return
	gun.loading = TRUE
	spawn(20)
		if(src && axis && gun && !gun.loaded && health > 0 && gun.health > 0)
			for(var/obj/structure/vehicleparts/shellrack/rack in axis.modules)
				for(var/obj/item/civ13_shell/shell in rack.contents)
					if(gun.accepts_shell(shell))
						shell.forceMove(gun)
						gun.loaded = shell
						break
				if(gun.loaded)
					break
		if(gun)
			gun.loading = FALSE

/obj/structure/vehicleparts/weapon/proc/clear_aim_marker()
	if(aim_marker)
		for(var/mob/user in ui_users)
			if(user.client)
				user.client.images -= aim_marker
		aim_marker = null

/obj/structure/vehicleparts/weapon/proc/setup_crew()
	if((!turret_icon && !weapon_types.len && !cannon_type) || crew.len)
		return
	for(var/role in crew_roles)
		var/seat_type = role == "gunner" ? /obj/structure/bed/chair/civ13/passenger/gunner : (role == "loader" ? /obj/structure/bed/chair/civ13/passenger/loader : /obj/structure/bed/chair/civ13/passenger/commander)
		var/obj/structure/bed/chair/civ13/seat = new seat_type(get_turf(src))
		seat.vehicle_axis = axis
		seat.station_control = src
		seat.set_dir(dir)
		seat.pixel_x = role == "gunner" ? gunner_x : (role == "loader" ? loader_x : commander_x)
		seat.pixel_y = role == "gunner" ? gunner_y : (role == "loader" ? loader_y : commander_y)
		seat.anchored = TRUE
		crew += seat
	if(cannon_type && !cannon && !guns.len)
		cannon = new cannon_type(src)
		cannon.axis = axis
		caliber = cannon.caliber
		autoloader = cannon.autoloader
		maxrange = cannon.maxrange
		minrange = cannon.minrange
	try_autoload()
	if(!guns.len)
		for(var/weapon_type in weapon_types)
			var/obj/structure/vehicleparts/weapon/gun = new weapon_type(src)
			guns += gun
	for(var/obj/structure/vehicleparts/weapon/gun in guns)
		gun.axis = axis
	if(guns.len)
		cannon = guns[1]
		caliber = cannon.caliber
		autoloader = cannon.autoloader
		maxrange = cannon.maxrange
		minrange = cannon.minrange

/obj/structure/vehicleparts/weapon/proc/can_operate(mob/user)
	if(!user || user.incapacitated() || !axis || health <= 0)
		return FALSE
	var/onboard = FALSE
	for(var/obj/structure/vehicleparts/frame/frame in axis.components)
		if(get_turf(frame) == get_turf(user))
			onboard = TRUE
			break
	if(!onboard)
		return FALSE
	if(control_seat)
		return control_seat.vehicle_axis == axis && control_seat.buckled_mob == user
	if(!Adjacent(user))
		return FALSE
	if(crew.len)
		var/obj/structure/bed/chair/civ13/gunner_seat = get_crew_seat("gunner")
		return gunner_seat && gunner_seat.buckled_mob == user
	return user.buckled && istype(user.buckled, /obj/structure/bed/chair/civ13) && user.buckled:vehicle_axis == axis && (istype(user.buckled, /obj/structure/bed/chair/civ13/passenger/gunner) || get_turf(user) == get_turf(src))

/obj/structure/vehicleparts/weapon/attack_hand(mob/user)
	if(!can_operate(user))
		to_chat(user, SPAN_WARNING("Operate the weapon from its crew station."))
		return
	show_controls(user)

/obj/structure/vehicleparts/weapon/proc/show_controls(mob/user)
	if(!can_operate(user))
		return
	ui_users |= user
	var/obj/structure/vehicleparts/weapon/gun = cannon ? cannon : src
	try_autoload()
	var/html = "<html><body><h3>[html_encode(name)]</h3><p>[gun.caliber]mm | [gun.loaded ? html_encode(gun.loaded.name) : "Unloaded"]</p>"
	for(var/index = 1, index <= guns.len, index++)
		var/obj/structure/vehicleparts/weapon/option = guns[index]
		html += "<a href='?src=\ref[src];weapon=[index]'>[html_encode(option.name)]</a><br>"
	html += "<p>Target: [aim_target ? "[aim_target.x], [aim_target.y]" : "None"]</p>"
	html += "<p>[gun.loading ? "Reloading" : (world.time < next_rotation ? "Rotating" : "Ready")] | [gun.loaded ? gun.loaded.rounds : 0] rounds</p>"
	html += "<a href='?src=\ref[src];aim=1'>Aim</a> | <a href='?src=\ref[src];left=1'>Rotate Left</a> | <a href='?src=\ref[src];right=1'>Rotate Right</a> | <a href='?src=\ref[src];fire=1'>Fire</a></body></html>"
	user << browse(html, "window=civ13_weapon;size=360x200")

/obj/structure/vehicleparts/weapon/Topic(href, href_list)
	if(!can_operate(usr))
		return
	if(href_list["weapon"])
		var/index = text2num(href_list["weapon"])
		if(index == round(index) && index >= 1 && index <= guns.len)
			selected_weapon = index
			cannon = guns[index]
			caliber = cannon.caliber
			maxrange = cannon.maxrange
			minrange = cannon.minrange
			autoloader = cannon.autoloader
			try_autoload()
	else if(href_list["aim"])
		var/turf/target = input(usr, "Select a target", name) as null|turf in view(maxrange, usr)
		if(can_operate(usr) && target && target.z == z && get_dist(src, target) <= maxrange && get_dist(src, target) >= minrange && get_dist(src, target) > 0 && world.time >= next_rotation)
			if(fixed_mount && axis && get_dir(src, target) != axis.dir)
				to_chat(usr, SPAN_WARNING("Turn the vehicle to aim this fixed mount."))
				return
			clear_aim_marker()
			aim_target = target
			var/target_direction = get_dir(src, target)
			if(target_direction != dir)
				next_rotation = world.time + max(1, rotation_speed * 10)
			set_dir(target_direction)
			aim_marker = image('icons/turf/overlays.dmi', target, "greenOverlay")
			aim_marker.alpha = 120
			aim_marker.mouse_opacity = 0
			usr.client.images += aim_marker
			update_icon()
	else if(href_list["left"] || href_list["right"])
		if(fixed_mount || world.time < next_rotation)
			return
		next_rotation = world.time + max(1, rotation_speed * 10)
		set_dir(turn(dir, href_list["left"] ? 90 : -90))
		aim_target = null
		clear_aim_marker()
		update_icon()
	else if(href_list["fire"])
		fire(usr)
	show_controls(usr)

/obj/structure/vehicleparts/weapon/proc/fire(mob/user)
	var/obj/structure/vehicleparts/weapon/gun = cannon ? cannon : src
	if(!can_operate(user) || gun.health <= 0 || !aim_target || aim_target.z != z || get_dist(src, aim_target) > maxrange || get_dist(src, aim_target) < gun.minrange || world.time < next_rotation || world.time < gun.next_fire || !gun.loaded || gun.loading)
		return FALSE
	var/obj/item/projectile/civ13_shell/projectile = new(get_turf(src))
	projectile.damage = gun.loaded.damage
	projectile.caliber = gun.loaded.caliber
	projectile.atype = gun.loaded.atype
	projectile.heavy_armor_penetration = gun.loaded.heavy_armor_penetration
	projectile.firing_axis = axis
	projectile.firer = user
	projectile.shot_from = name
	projectile.launch(aim_target, BP_CHEST)
	gun.next_fire = world.time + max(0.1, gun.firedelay) * 10
	gun.loaded.rounds--
	gun.loaded.update_icon()
	if(gun.loaded.rounds <= 0)
		qdel(gun.loaded)
		gun.loaded = null
		try_autoload()
	playsound(src, 'sound/weapons/gunshot/gunshot.ogg', 80, TRUE)
	return TRUE

/obj/structure/vehicleparts/weapon/attackby(obj/item/ammunition, mob/user)
	var/obj/structure/vehicleparts/weapon/gun = cannon ? cannon : src
	if(istype(ammunition, /obj/item/civ13_shell))
		var/obj/item/civ13_shell/shell = ammunition
		for(var/obj/structure/vehicleparts/weapon/option in guns)
			if(option.accepts_shell(shell) && !option.loaded && !option.loading)
				gun = option
				break
		var/obj/structure/bed/chair/civ13/loader_seat = get_crew_seat("loader")
		if(loader_seat && !gun.autoloader && !gun.machinegun && loader_seat.buckled_mob != user)
			to_chat(user, SPAN_WARNING("Use the loader's station to reload this turret."))
			return
		if(gun.loaded || gun.loading || !gun.accepts_shell(shell) || !Adjacent(user) || user.incapacitated() || shell.loc != user || health <= 0 || gun.health <= 0)
			return
		gun.loading = TRUE
		if(do_after(user, gun.autoloader ? 10 : 30, src) && !gun.loaded && ammunition.loc == user && Adjacent(user) && !user.incapacitated() && health > 0 && gun.health > 0 && (!loader_seat || gun.autoloader || gun.machinegun || loader_seat.buckled_mob == user))
			user.drop_from_inventory(shell, gun)
			if(shell.loc == gun)
				gun.loaded = shell
		gun.loading = FALSE
		return
	if(isWelder(ammunition) && health < initial(health))
		var/obj/item/weldingtool/welder = ammunition
		if(welder.isOn() && welder.remove_fuel(1, user) && do_after(user, 40, src))
			health = initial(health)
		return
	return ..()

/obj/structure/vehicleparts/weapon/update_icon()
	if(!turret_icon)
		return
	overlays.Cut()
	if(!turret_sprite_icon)
		turret_sprite_icon = icon
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "tank_cannon"
	if(!exterior_image)
		exterior_image = image(turret_sprite_icon, src)
	exterior_image.icon = turret_sprite_icon
	var/list/turret_states = icon_states(turret_sprite_icon)
	var/body_state = "[turret_icon][health <= 0]"
	if(!(body_state in turret_states))
		body_state = "[turret_icon]0"
	exterior_image.icon_state = body_state
	exterior_image.dir = dir
	var/icon/turret_dimensions = icon(turret_sprite_icon)
	exterior_image.pixel_x = (world.icon_size - turret_dimensions.Width()) / 2
	exterior_image.pixel_y = (world.icon_size - turret_dimensions.Height()) / 2
	if(axis)
		switch(axis.dir)
			if(NORTH)
				exterior_image.pixel_x -= turret_x
				exterior_image.pixel_y -= turret_y
			if(SOUTH)
				exterior_image.pixel_x += turret_x
				exterior_image.pixel_y += turret_y
			if(EAST)
				exterior_image.pixel_x -= turret_y
				exterior_image.pixel_y += turret_x
			if(WEST)
				exterior_image.pixel_x += turret_y
				exterior_image.pixel_y -= turret_x
	exterior_image.color = axis ? axis.color : turret_color
	exterior_image.layer = ABOVE_HUMAN_LAYER + 0.3
	exterior_image.mouse_opacity = 0
	exterior_image.overlays.Cut()
	var/roof_state = "[turret_icon]_roof[health <= 0]"
	if(!(roof_state in turret_states))
		roof_state = "[turret_icon]_roof0"
	if(roof_state in turret_states)
		var/image/turret_roof = image(icon = turret_sprite_icon, icon_state = roof_state, dir = dir, layer = ABOVE_HUMAN_LAYER + 0.4)
		turret_roof.mouse_opacity = 0
		exterior_image.overlays += turret_roof
	for(var/obj/structure/bed/chair/civ13/seat in crew)
		var/offset_x = istype(seat, /obj/structure/bed/chair/civ13/passenger/gunner) ? gunner_x : (istype(seat, /obj/structure/bed/chair/civ13/passenger/loader) ? loader_x : commander_x)
		var/offset_y = istype(seat, /obj/structure/bed/chair/civ13/passenger/gunner) ? gunner_y : (istype(seat, /obj/structure/bed/chair/civ13/passenger/loader) ? loader_y : commander_y)
		switch(dir)
			if(NORTH)
				seat.pixel_x = offset_x
				seat.pixel_y = offset_y
			if(SOUTH)
				seat.pixel_x = -offset_x
				seat.pixel_y = -offset_y
			if(EAST)
				seat.pixel_x = offset_y
				seat.pixel_y = -offset_x
			if(WEST)
				seat.pixel_x = -offset_y
				seat.pixel_y = offset_x

/obj/structure/vehicleparts/weapon/Destroy()
	clear_aim_marker()
	if(axis && exterior_image)
		for(var/client/viewer in axis.roof_viewers)
			viewer.images -= exterior_image
	for(var/mob/user in ui_users)
		user << browse(null, "window=civ13_weapon")
	ui_users.Cut()
	for(var/obj/structure/bed/chair/civ13/seat in crew)
		qdel(seat)
	crew.Cut()
	if(!guns.len)
		QDEL_NULL(cannon)
	else
		for(var/obj/structure/vehicleparts/weapon/gun in guns)
			qdel(gun)
		guns.Cut()
		cannon = null
	QDEL_NULL(loaded)
	return ..()

/obj/structure/vehicleparts/weapon/bullet_act(obj/item/projectile/projectile)
	if(axis && istype(projectile, /obj/item/projectile/civ13_shell) && projectile:firing_axis == axis)
		return PROJECTILE_CONTINUE
	health = max(0, health - projectile.get_structure_damage())
	update_icon()
	return 0

/obj/structure/vehicleparts/weapon/ex_act(severity)
	health = max(0, health - (severity == 1 ? 100 : 30))
	update_icon()

/obj/structure/bed/chair/civ13/passenger
	name = "passenger seat"

/obj/structure/bed/chair/civ13/passenger/gunner
	name = "gunner's seat"

/obj/structure/bed/chair/civ13/passenger/loader
	name = "loader's seat"

/obj/structure/bed/chair/civ13/passenger/commander
	name = "commander's seat"

/obj/structure/vehicleparts/weapon/spacecraft
	name = "spacecraft mass driver"
	desc = "A frame-mounted 75mm mass driver. Load vehicle shells and operate it from an onboard crew station."
	icon_state = "tank_cannon"
	caliber = 75
	maxrange = 30
	firedelay = 2
	autoloader = TRUE

/obj/structure/vehicleparts/shellrack
	name = "vehicle ammunition rack"
	var/caliber = 75
	var/start_shell_type = /obj/item/civ13_shell
	var/start_shells = 0
	var/capacity = 12

/obj/structure/vehicleparts/shellrack/New()
	..()
	for(var/count = 1, count <= start_shells, count++)
		new start_shell_type(src)

/obj/structure/vehicleparts/shellrack/attackby(obj/item/ammunition, mob/user)
	if(istype(ammunition, /obj/item/civ13_shell) && contents.len < capacity && Adjacent(user) && !user.incapacitated() && ammunition.loc == user)
		user.drop_from_inventory(ammunition, src)
		if(axis && ammunition.loc == src)
			for(var/obj/structure/vehicleparts/weapon/weapon in axis.modules)
				weapon.try_autoload()
		return
	return ..()

/obj/structure/vehicleparts/shellrack/attack_hand(mob/user)
	if(!Adjacent(user) || user.incapacitated() || !contents.len)
		return
	var/obj/item/civ13_shell/shell = input(user, "Select ammunition", name) as null|anything in contents
	if(shell && shell.loc == src && Adjacent(user) && !user.incapacitated())
		shell.forceMove(get_turf(src))
		user.put_in_hands(shell)

/obj/structure/vehicleparts/frame/bullet_act(obj/item/projectile/projectile)
	if(axis && istype(projectile, /obj/item/projectile/civ13_shell) && projectile:firing_axis == axis)
		return PROJECTILE_CONTINUE
	var/direction = get_dir(src, projectile.starting)
	if(!direction)
		direction = turn(projectile.dir, 180)
	var/list/wall
	for(var/cardinal in GLOB.cardinal)
		if(!(direction & cardinal))
			continue
		var/list/candidate = get_wall(cardinal)
		if(candidate && candidate[3] && !candidate[7] && candidate[5] > 0 && (!wall || candidate[4] > wall[4]))
			wall = candidate
	if(!wall)
		return PROJECTILE_CONTINUE
	var/penetration = istype(projectile, /obj/item/projectile/civ13_shell) ? projectile:heavy_armor_penetration : projectile.damage / 2
	if(penetration < wall[4])
		return 0
	wall[5] = max(0, wall[5] - projectile.get_structure_damage())
	if(wall[5] <= 0)
		broken = TRUE
		if(axis)
			axis.stopmovementloop()
	update_icon()
	if(istype(projectile, /obj/item/projectile/civ13_shell))
		var/obj/item/projectile/civ13_shell/shell = projectile
		if(shell.atype in list("AP", "APCR", "APDS", "APFSDS", "APHE", "HEAT"))
			shell.heavy_armor_penetration = max(0, shell.heavy_armor_penetration - wall[4])
			shell.damage = max(0, shell.damage - wall[4])
			if(shell.damage > 0 && shell.heavy_armor_penetration > 0)
				return PROJECTILE_CONTINUE
	return 0

/obj/structure/vehicleparts/frame/ex_act(severity)
	var/damage = severity == 1 ? 150 : (severity == 2 ? 50 : 15)
	for(var/direction in GLOB.cardinal)
		var/list/wall = get_wall(direction)
		wall[5] = max(0, wall[5] - damage)
	broken = TRUE
	if(axis)
		axis.stopmovementloop()
	update_icon()
