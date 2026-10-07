/obj/structure/vehicleparts/engine
	name = "internal combustion engine"
	layer = OBJ_LAYER + 0.05
	var/on = FALSE
	var/fuel_type = /datum/reagent/fuel
	var/fuel_use = 0.1
	var/power = 100
	var/health = 100
	var/obj/structure/vehicleparts/fueltank/fueltank

/obj/structure/vehicleparts/engine/proc/consume_fuel()
	if(!on || health <= 0 || !fueltank || !fueltank.consume_fuel(fuel_use, fuel_type))
		on = FALSE
		return FALSE
	return TRUE

/obj/structure/vehicleparts/engine/attack_hand(mob/user)
	return toggle_engine(user)

/obj/structure/vehicleparts/engine/proc/toggle_engine(mob/user, obj/structure/bed/chair/civ13/driver/control_seat)
	if(!user || user.incapacitated())
		return
	if(control_seat)
		if(control_seat.buckled_mob != user || !axis || control_seat.vehicle_axis != axis || axis.engine != src)
			return
	else if(!Adjacent(user))
		return
	if(!on && (!fueltank || fueltank.get_fuel_amount(fuel_type) < fuel_use || health <= 0))
		to_chat(user, SPAN_WARNING("The engine needs fuel and must be in working order."))
		return
	on = !on
	if(!on && axis)
		axis.stopmovementloop()
	to_chat(user, SPAN_NOTICE("You turn the engine [on ? "on" : "off"]."))
	update_icon()

/obj/structure/vehicleparts/engine/attackby(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/stack/material/phoron) || istype(tool, /obj/item/reagent_containers))
		if(!fueltank)
			to_chat(user, SPAN_WARNING("This engine has no connected fuel tank."))
			return TRUE
		return fueltank.refuel(tool, user, src)
	if(isWrench(tool))
		return ..()
	if(isWelder(tool))
		var/obj/item/weldingtool/welder = tool
		if(!on && health < initial(health) && welder.isOn() && welder.remove_fuel(1, user) && do_after(user, 30, src))
			health = min(initial(health), health + 20)
		return
	if(tool.force)
		health = max(0, health - tool.force)
		if(!health)
			on = FALSE
			if(axis)
				axis.stopmovementloop()

/obj/structure/vehicleparts/engine/Destroy()
	if(axis && axis.engine == src)
		axis.stopmovementloop()
		axis.engine = null
	fueltank = null
	return ..()

/obj/structure/vehicleparts/engine/bullet_act(obj/item/projectile/projectile)
	health = max(0, health - projectile.get_structure_damage())
	if(!health)
		on = FALSE
		if(axis)
			axis.stopmovementloop()
	return 0

/obj/structure/vehicleparts/engine/ex_act(severity)
	health = max(0, health - (severity == 1 ? 100 : 30))
	if(!health)
		on = FALSE
		if(axis)
			axis.stopmovementloop()

/obj/structure/vehicleparts/fueltank
	name = "vehicle fuel tank"
	layer = OBJ_LAYER + 0.05
	var/capacity = 200
	var/start_fuel = 0

/obj/structure/vehicleparts/fueltank/New()
	..()
	create_reagents(capacity)
	if(start_fuel)
		reagents.add_reagent(/datum/reagent/fuel, start_fuel)

/obj/structure/vehicleparts/fueltank/proc/get_fuel_amount(primary_fuel = /datum/reagent/fuel)
	if(!reagents)
		return 0
	var/amount = reagents.get_reagent_amount(primary_fuel)
	if(primary_fuel != /datum/reagent/toxin/phoron)
		amount += reagents.get_reagent_amount(/datum/reagent/toxin/phoron)
	return amount

/obj/structure/vehicleparts/fueltank/proc/consume_fuel(amount, primary_fuel = /datum/reagent/fuel)
	if(amount <= 0 || get_fuel_amount(primary_fuel) < amount)
		return FALSE
	var/primary_amount = min(amount, reagents.get_reagent_amount(primary_fuel))
	if(primary_amount > 0)
		reagents.remove_reagent(primary_fuel, primary_amount)
	var/remaining = max(0, amount - primary_amount)
	if(remaining > 0)
		reagents.remove_reagent(/datum/reagent/toxin/phoron, remaining)
	return TRUE

/obj/structure/vehicleparts/fueltank/attackby(obj/item/container, mob/user)
	if(istype(container, /obj/item/stack/material/phoron) || istype(container, /obj/item/reagent_containers))
		return refuel(container, user, src)
	return ..()

/obj/structure/vehicleparts/fueltank/proc/refuel(obj/item/container, mob/user, atom/refueling_point)
	if(!refueling_point)
		refueling_point = src
	if(!user || !container || !refueling_point.Adjacent(user) || user.incapacitated() || container.loc != user)
		return TRUE
	if(refueling_point != src)
		var/obj/structure/vehicleparts/part = refueling_point
		if(!istype(part) || !axis || (part != axis && part.axis != axis))
			return TRUE
	if(!reagents)
		create_reagents(capacity)
	if(istype(container, /obj/item/stack/material/phoron))
		if(reagents.get_free_space() < 20)
			to_chat(user, SPAN_WARNING("The tank needs room for 20 fuel units to accept a phoron sheet."))
			return TRUE
		var/obj/item/stack/material/phoron/sheets = container
		if(sheets.amount >= 1 && reagents.add_reagent(/datum/reagent/fuel, 20))
			sheets.use(1)
			to_chat(user, SPAN_NOTICE("You fuel [src] with a phoron sheet, adding 20 units of fuel."))
		return TRUE
	if(!container.is_open_container())
		to_chat(user, SPAN_WARNING("Open [container] before pouring fuel."))
		return TRUE
	if(!container.reagents || (container.reagents.get_reagent_amount(/datum/reagent/fuel) + container.reagents.get_reagent_amount(/datum/reagent/toxin/phoron)) <= 0)
		to_chat(user, SPAN_WARNING("[container] contains no liquid fuel or liquid phoron."))
		return TRUE
	if(reagents.get_free_space() <= 0)
		to_chat(user, SPAN_WARNING("[src] is full."))
		return TRUE
	var/transferred = 0
	for(var/reagent_type in list(/datum/reagent/fuel, /datum/reagent/toxin/phoron))
		var/amount = min(20 - transferred, container.reagents.get_reagent_amount(reagent_type), reagents.get_free_space())
		if(amount > 0 && reagents.add_reagent(reagent_type, amount, container.reagents.get_data(reagent_type)))
			container.reagents.remove_reagent(reagent_type, amount)
			transferred += amount
	if(transferred > 0)
		to_chat(user, SPAN_NOTICE("You add [round(transferred, 0.1)] units of fuel to [src]."))
	return TRUE

/obj/structure/vehicleparts/fueltank/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("Fuel: [round(get_fuel_amount(), 0.1)]/[capacity]."))
	to_chat(user, SPAN_NOTICE("Accepts liquid fuel, liquid phoron, or phoron sheets (20 fuel units per sheet)."))

/obj/structure/bed/chair/civ13
	name = "vehicle seat"
	layer = OBJ_LAYER
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "carseat_middle"
	density = FALSE
	buckle_movable = TRUE
	var/obj/structure/vehicleparts/axis/vehicle_axis
	var/station_weapon
	var/obj/structure/vehicleparts/weapon/mounted_weapon
	var/obj/structure/vehicleparts/weapon/station_control

/obj/structure/bed/chair/civ13/attack_hand(mob/living/user)
	if(!Adjacent(user) || user.incapacitated())
		return
	if(!buckled_mob)
		return user_buckle_mob(user, user)
	if(buckled_mob == user && mounted_weapon)
		return mounted_weapon.attack_hand(user)
	if(buckled_mob == user && station_control && istype(src, /obj/structure/bed/chair/civ13/passenger/gunner))
		return station_control.attack_hand(user)
	if(buckled_mob == user && vehicle_axis)
		var/list/controlled_weapons = vehicle_axis.get_controlled_weapons(src)
		if(controlled_weapons.len == 1)
			var/obj/structure/vehicleparts/weapon/single_weapon = controlled_weapons[1]
			return single_weapon.show_controls(user)
		if(controlled_weapons.len > 1)
			var/list/weapon_choices = list()
			for(var/obj/structure/vehicleparts/weapon/option in controlled_weapons)
				weapon_choices["[option.name] ([option.x], [option.y])"] = option
			var/weapon_choice = input(user, "Select a mounted weapon", "Vehicle Controls") as null|anything in weapon_choices
			var/obj/structure/vehicleparts/weapon/selected_weapon = weapon_choices[weapon_choice]
			if(selected_weapon && buckled_mob == user && vehicle_axis)
				return selected_weapon.show_controls(user)
	return ..()

/obj/structure/bed/chair/civ13/proc/bind_to(obj/structure/vehicleparts/axis/chassis)
	if(!chassis || !chassis.has_frame(get_turf(src)))
		return FALSE
	vehicle_axis = chassis
	anchored = TRUE
	if(station_weapon && !mounted_weapon)
		mounted_weapon = new station_weapon(get_turf(src))
		for(var/obj/structure/vehicleparts/frame/frame in chassis.components)
			if(get_turf(frame) == get_turf(src))
				if(!chassis.install_component(mounted_weapon, frame))
					qdel(mounted_weapon)
					mounted_weapon = null
					vehicle_axis = null
					anchored = FALSE
					return FALSE
				break
	if(mounted_weapon)
		mounted_weapon.control_seat = src
	chassis.assign_weapon_controls()
	return TRUE

/obj/structure/bed/chair/civ13/proc/unbind_from_vehicle()
	var/obj/structure/vehicleparts/axis/chassis = vehicle_axis
	var/mob/living/occupant = buckled_mob
	if(buckled_mob)
		unbuckle_mob()
	if(chassis && chassis.driver == occupant)
		chassis.driver = null
	QDEL_NULL(mounted_weapon)
	station_control = null
	vehicle_axis = null
	anchored = FALSE
	if(chassis)
		for(var/obj/structure/vehicleparts/weapon/weapon in chassis.modules)
			if(weapon.control_seat == src)
				weapon.control_seat = null
		chassis.assign_weapon_controls()

/obj/structure/bed/chair/civ13/MouseDrop(obj/structure/vehicleparts/frame/target, src_location, over_location)
	if(!istype(target) || !target.axis || vehicle_axis || !usr || usr.incapacitated() || !Adjacent(usr) || !target.Adjacent(usr) || target.axis.moving || (target.axis.engine && target.axis.engine.on))
		return
	forceMove(get_turf(target))
	set_dir(target.axis.dir)
	bind_to(target.axis)

/obj/structure/bed/chair/civ13/update_icon()
	overlays.Cut()
	icon_state = initial(icon_state)
	if(!(icon_state in icon_states(icon)))
		icon = 'icons/obj/civ13/vehicleparts.dmi'
		icon_state = "carseat_middle"

/obj/structure/bed/chair/civ13/post_buckle_mob(mob/living/occupant)
	. = ..()
	if(!buckled_mob)
		var/obj/structure/vehicleparts/weapon/weapon = station_control ? station_control : mounted_weapon
		if(weapon && occupant)
			if(weapon.aim_marker && occupant.client)
				occupant.client.images -= weapon.aim_marker
			weapon.ui_users -= occupant
			occupant << browse(null, "window=civ13_weapon")

/obj/structure/bed/chair/civ13/attackby(obj/item/tool, mob/user)
	if(isWrench(tool) && vehicle_axis && !buckled_mob && !vehicle_axis.moving && (!vehicle_axis.engine || !vehicle_axis.engine.on))
		if(station_control)
			to_chat(user, SPAN_WARNING("Remove the turret to detach its integrated crew stations."))
			return
		var/obj/structure/vehicleparts/axis/chassis = vehicle_axis
		if(do_after(user, 20, src) && !buckled_mob && vehicle_axis == chassis && !chassis.moving && (!chassis.engine || !chassis.engine.on))
			unbind_from_vehicle()
		return
	return ..()

/obj/structure/bed/chair/civ13/Destroy()
	unbind_from_vehicle()
	return ..()

/obj/structure/bed/chair/civ13/driver
	name = "driver's seat"

/obj/structure/bed/chair/civ13/driver/attack_hand(mob/living/user)
	if(buckled_mob != user)
		return ..()
	if(!vehicle_axis || user.incapacitated())
		return
	var/obj/structure/vehicleparts/axis/chassis = vehicle_axis
	var/fuel_amount = chassis.engine && chassis.engine.fueltank ? round(chassis.engine.fueltank.get_fuel_amount(chassis.engine.fuel_type), 0.1) : 0
	var/list/actions = list("Toggle Engine", "Shift Gear", "Toggle Throttle", "Brake", "Leave Seat")
	if(chassis.get_controlled_weapons(src).len)
		actions += "Weapon Controls"
	var/action = input(user, "Engine: [chassis.engine && chassis.engine.on ? "On" : "Off"]. Fuel: [fuel_amount]. Gear: [chassis.currentspeed].", "Vehicle Controls") as null|anything in actions
	if(!action || buckled_mob != user || vehicle_axis != chassis || user.incapacitated())
		return
	switch(action)
		if("Toggle Engine")
			if(chassis.engine)
				chassis.engine.toggle_engine(user, src)
		if("Shift Gear")
			shift_gear()
		if("Toggle Throttle")
			toggle_throttle()
		if("Brake")
			chassis.stopmovementloop()
		if("Leave Seat")
			user_unbuckle_mob(user)
		if("Weapon Controls")
			var/list/weapon_choices = list()
			for(var/obj/structure/vehicleparts/weapon/option in chassis.get_controlled_weapons(src))
				weapon_choices["[option.name] ([option.x], [option.y])"] = option
			var/weapon_choice = input(user, "Select a mounted weapon", "Vehicle Controls") as null|anything in weapon_choices
			var/obj/structure/vehicleparts/weapon/selected_weapon = weapon_choices[weapon_choice]
			if(selected_weapon && buckled_mob == user && vehicle_axis == chassis)
				selected_weapon.show_controls(user)

/obj/structure/bed/chair/civ13/driver/post_buckle_mob()
	. = ..()
	if(vehicle_axis)
		vehicle_axis.driver = buckled_mob
		if(!buckled_mob)
			vehicle_axis.stopmovementloop()

/obj/structure/bed/chair/civ13/driver/relaymove(mob/user, direction)
	if(vehicle_axis && buckled_mob == user)
		return vehicle_axis.relaymove(user, direction)
	return FALSE

/obj/structure/bed/chair/civ13/driver/verb/shift_gear()
	set name = "Shift Vehicle Gear"
	set category = "Object"
	set src in view(1)
	if(usr != buckled_mob || !vehicle_axis || !vehicle_axis.can_drive(usr))
		return
	var/gear = input(usr, "Gear", name, max(1, vehicle_axis.currentspeed)) as null|num
	if(isnull(gear) || usr != buckled_mob || !vehicle_axis || !vehicle_axis.can_drive(usr))
		return
	vehicle_axis.currentspeed = clamp(round(gear), 1, min(vehicle_axis.speeds, vehicle_axis.speedlist.len))
	vehicle_axis.vehicle_m_delay = vehicle_axis.speedlist[vehicle_axis.currentspeed]

/obj/structure/bed/chair/civ13/driver/verb/toggle_throttle()
	set name = "Toggle Vehicle Throttle"
	set category = "Object"
	set src in view(1)
	if(usr != buckled_mob || !vehicle_axis || !vehicle_axis.can_drive(usr))
		return
	if(vehicle_axis.cruise)
		vehicle_axis.stopmovementloop()
	else
		vehicle_axis.startmovementloop()

/obj/structure/bed/chair/civ13/driver/verb/toggle_engine()
	set name = "Toggle Vehicle Engine"
	set category = "Object"
	set src in view(1)
	if(usr == buckled_mob && vehicle_axis && vehicle_axis.engine)
		vehicle_axis.engine.toggle_engine(usr, src)

/obj/structure/bed/chair/civ13/driver/Destroy()
	if(vehicle_axis && vehicle_axis.driver == buckled_mob)
		vehicle_axis.driver = null
		vehicle_axis.stopmovementloop()
	return ..()

/obj/structure/vehicleparts/engine/motorcycle
	name = "125cc motorcycle engine"
	power = 8
	fuel_use = 0.05

/obj/structure/vehicleparts/fueltank/motorcycle
	name = "motorcycle fuel tank"
	icon_state = "fueltank_bike"
	capacity = 50
	start_fuel = 50

/obj/structure/bed/chair/civ13/driver/motorcycle
	name = "motorcycle handlebars"
	icon = 'icons/obj/civ13/vehicleparts.dmi'
	icon_state = "bike_handles"

/obj/structure/vehicleparts/engine/spacecraft
	name = "closed-cycle rocket engine"
	desc = "A vacuum-rated propulsion plant with onboard oxidizer. Accepts standard vehicle fuel."
	icon = 'icons/obj/civ13/engines32.dmi'
	icon_state = "diesel_static"
	power = 300
	health = 150
	fuel_use = 0.3

/obj/structure/vehicleparts/engine/spacecraft/ion
	name = "ion propulsion plant"
	desc = "An efficient electric propulsion assembly using standard vehicle fuel as propellant."
	power = 200
	fuel_use = 0.1

/obj/structure/vehicleparts/engine/spacecraft/heavy
	name = "heavy closed-cycle rocket engine"
	desc = "A reinforced vacuum propulsion plant for larger spacecraft. Accepts standard vehicle fuel."
	power = 600
	health = 250
	fuel_use = 0.6

/obj/structure/vehicleparts/fueltank/spacecraft
	name = "spacecraft propellant tank"
	icon_state = "fueltank_small_tank"
	capacity = 300

/obj/structure/vehicleparts/fueltank/spacecraft/full
	start_fuel = 300

/obj/structure/vehicleparts/fueltank/spacecraft/large
	name = "large spacecraft propellant tank"
	icon_state = "fueltank_large_tank"
	capacity = 600

/obj/structure/vehicleparts/fueltank/spacecraft/large/full
	start_fuel = 600

/obj/structure/bed/chair/civ13/driver/spacecraft
	name = "pilot's control couch"
	desc = "Spacecraft flight controls: engine, thrust settings, powered cruise and braking."
	icon_state = "driver_tank"

/obj/structure/bed/chair/civ13/passenger/spacecraft
	name = "spacecraft acceleration couch"
	icon_state = "carseat_middle"

/obj/structure/bed/chair/civ13/passenger/gunner/spacecraft
	name = "spacecraft weapons station"
	icon_state = "commanders_seat"

/obj/structure/vehicleparts/cargo_hold
	name = "spacecraft cargo locker"
	desc = "A frame-mounted locker for loose equipment and supplies."
	icon_state = "lid_fueltank"
	var/capacity = 12

/obj/structure/vehicleparts/cargo_hold/attackby(obj/item/equipment, mob/user)
	if(isWrench(equipment) || isWelder(equipment))
		return ..()
	if(!Adjacent(user) || user.incapacitated() || equipment.loc != user || contents.len >= capacity)
		return
	user.drop_from_inventory(equipment, src)

/obj/structure/vehicleparts/cargo_hold/attack_hand(mob/user)
	if(!Adjacent(user) || user.incapacitated() || !contents.len)
		return
	var/obj/item/equipment = input(user, "Retrieve cargo", name) as null|anything in contents
	if(equipment && equipment.loc == src && Adjacent(user) && !user.incapacitated())
		equipment.forceMove(get_turf(src))
		user.put_in_hands(equipment)

/obj/structure/vehicleparts/cargo_hold/Destroy()
	for(var/obj/item/equipment in contents)
		equipment.forceMove(get_turf(src))
	return ..()
