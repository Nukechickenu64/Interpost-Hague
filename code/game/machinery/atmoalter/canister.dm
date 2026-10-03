/obj/machinery/portable_atmospherics/canister
	name = "\improper Canister: \[CAUTION\]"
	icon = 'icons/obj/atmos.dmi'
	icon_state = "yellow"
	density = 1
	anchored = TRUE
	var/station_fed = FALSE
	var/health = 100.0
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	w_class = ITEM_SIZE_GARGANTUAN

	var/valve_open = 0
	var/release_pressure = ONE_ATMOSPHERE
	var/release_flow_rate = ATMOS_DEFAULT_VOLUME_PUMP //in L/s

	var/canister_color = "yellow"
	var/can_label = 1
	start_pressure = 45 * ONE_ATMOSPHERE
	max_fill_pressure = 45 * ONE_ATMOSPHERE
	var/temperature_resistance = 1000 + T0C
	volume = 1000
	interact_offline = 1 // Allows this to be used when not in powered area.
	var/release_log = ""
	var/update_flag = 0

/obj/machinery/portable_atmospherics/canister/drain_power()
	return -1

/obj/machinery/portable_atmospherics/canister/Initialize()
	. = ..()
	anchored = TRUE

/obj/machinery/portable_atmospherics/canister/connect(obj/machinery/atmospherics/portables_connector/new_port)
	anchored = TRUE
	return FALSE

/obj/machinery/portable_atmospherics/canister/disconnect()
	. = ..()
	anchored = TRUE

/obj/machinery/portable_atmospherics/canister/proc/get_refill_source()
	if(station_fed)
		var/obj/machinery/station_gas_tank/reserve = get_station_gas_tank(src)
		return reserve ? reserve.air_contents : null
	return air_contents

/obj/machinery/portable_atmospherics/canister/proc/refill_tank(obj/item/tank/tank)
	if(destroyed || (stat & BROKEN) || !tank || !tank.air_contents)
		return 0
	var/datum/gas_mixture/source = get_refill_source()
	var/datum/gas_mixture/destination = tank.air_contents
	if(!source || source.total_moles <= 0 || source.temperature <= 0 || destination.return_pressure() >= 10 * ONE_ATMOSPHERE)
		return 0
	var/max_temperature = max(source.temperature, destination.temperature)
	var/max_moles = 10 * ONE_ATMOSPHERE * destination.volume * destination.group_multiplier / (R_IDEAL_GAS_EQUATION * max_temperature)
	var/transfer_moles = min(max(0, max_moles - destination.total_moles), source.total_moles * release_flow_rate / source.volume)
	if(station_fed)
		var/obj/machinery/station_gas_tank/reserve = get_station_gas_tank(src)
		return reserve ? reserve.refill_tank(destination, transfer_moles) : 0
	if(transfer_moles < MINIMUM_MOLES_TO_PUMP)
		return 0
	var/datum/gas_mixture/removed = source.remove(transfer_moles)
	var/transferred = removed.total_moles
	destination.merge(removed)
	qdel(removed)
	return transferred

/obj/machinery/portable_atmospherics/canister/sleeping_agent
	name = "\improper Canister: \[N2O\]"
	icon_state = "redws"
	canister_color = "redws"
	can_label = 0

/obj/machinery/portable_atmospherics/canister/nitrogen
	name = "\improper Canister: \[N2\]"
	icon_state = "red"
	canister_color = "red"
	can_label = 0

/obj/machinery/portable_atmospherics/canister/nitrogen/prechilled
	name = "\improper Canister: \[N2 (Cooling)\]"

/obj/machinery/portable_atmospherics/canister/oxygen
	name = "\improper Canister: \[O2\]"
	icon_state = "blue"
	canister_color = "blue"
	can_label = 0

/obj/machinery/portable_atmospherics/canister/oxygen/prechilled
	name = "\improper Canister: \[O2 (Cryo)\]"
	start_pressure = 20 * ONE_ATMOSPHERE
	max_fill_pressure = 20 * ONE_ATMOSPHERE

/obj/machinery/portable_atmospherics/canister/hydrogen
	name = "\improper Canister: \[Hydrogen\]"
	icon_state = "purple"
	canister_color = "purple"
	can_label = 0

/obj/machinery/portable_atmospherics/canister/phoron
	name = "\improper Canister \[Phoron\]"
	icon_state = "orange"
	canister_color = "orange"
	can_label = 0

/obj/machinery/portable_atmospherics/canister/carbon_dioxide
	name = "\improper Canister \[CO2\]"
	icon_state = "black"
	canister_color = "black"
	can_label = 0

/obj/machinery/portable_atmospherics/canister/air
	name = "\improper Canister \[Air\]"
	station_fed = TRUE
	icon_state = "grey"
	canister_color = "grey"
	can_label = 0

/obj/machinery/portable_atmospherics/canister/air/airlock
	start_pressure = 3 * ONE_ATMOSPHERE
	max_fill_pressure = 3 * ONE_ATMOSPHERE

/obj/machinery/portable_atmospherics/canister/empty
	start_pressure = 0
	can_label = 1
	var/obj/machinery/portable_atmospherics/canister/canister_type = /obj/machinery/portable_atmospherics/canister

/obj/machinery/portable_atmospherics/canister/empty/New()
	..()
	name = 	initial(canister_type.name)
	icon_state = 	initial(canister_type.icon_state)
	canister_color = 	initial(canister_type.canister_color)

/obj/machinery/portable_atmospherics/canister/empty/air
	icon_state = "grey"
	station_fed = TRUE
	canister_type = /obj/machinery/portable_atmospherics/canister/air
/obj/machinery/portable_atmospherics/canister/empty/oxygen
	icon_state = "blue"
	canister_type = /obj/machinery/portable_atmospherics/canister/oxygen
/obj/machinery/portable_atmospherics/canister/empty/phoron
	icon_state = "orange"
	canister_type = /obj/machinery/portable_atmospherics/canister/phoron
/obj/machinery/portable_atmospherics/canister/empty/nitrogen
	icon_state = "red"
	canister_type = /obj/machinery/portable_atmospherics/canister/nitrogen
/obj/machinery/portable_atmospherics/canister/empty/carbon_dioxide
	icon_state = "black"
	canister_type = /obj/machinery/portable_atmospherics/canister/carbon_dioxide
/obj/machinery/portable_atmospherics/canister/empty/sleeping_agent
	icon_state = "redws"
	canister_type = /obj/machinery/portable_atmospherics/canister/sleeping_agent
/obj/machinery/portable_atmospherics/canister/empty/hydrogen
	icon_state = "purple"
	canister_type = /obj/machinery/portable_atmospherics/canister/hydrogen




/obj/machinery/portable_atmospherics/canister/proc/check_change()
	var/old_flag = update_flag
	update_flag = 0
	if(holding)
		update_flag |= 1
	if(connected_port)
		update_flag |= 2

	var/datum/gas_mixture/source = get_refill_source()
	var/tank_pressure = source ? source.return_pressure() : 0
	if(tank_pressure < 10)
		update_flag |= 4
	else if(tank_pressure < ONE_ATMOSPHERE)
		update_flag |= 8
	else if(tank_pressure < 15*ONE_ATMOSPHERE)
		update_flag |= 16
	else
		update_flag |= 32

	if(update_flag == old_flag)
		return 1
	else
		return 0

/obj/machinery/portable_atmospherics/canister/update_icon()
/*
update_flag
1 = holding
2 = connected_port
4 = tank_pressure < 10
8 = tank_pressure < ONE_ATMOS
16 = tank_pressure < 15*ONE_ATMOS
32 = tank_pressure go boom.
*/

	if (src.destroyed)
		src.overlays = 0
		src.icon_state = text("[]-1", src.canister_color)
		return

	if(icon_state != "[canister_color]")
		icon_state = "[canister_color]"

	if(check_change()) //Returns 1 if no change needed to icons.
		return

	src.overlays = 0

	if(update_flag & 1)
		overlays += "can-open"
	if(update_flag & 2)
		overlays += "can-connector"
	if(update_flag & 4)
		overlays += overlay_image(icon, "can-o0", plane = ABOVE_LIGHTING_PLANE, layer = ABOVE_LIGHTING_LAYER)
	if(update_flag & 8)
		overlays += overlay_image(icon, "can-o1", plane = ABOVE_LIGHTING_PLANE, layer = ABOVE_LIGHTING_LAYER)
	else if(update_flag & 16)
		overlays += overlay_image(icon, "can-o2", plane = ABOVE_LIGHTING_PLANE, layer = ABOVE_LIGHTING_LAYER)
	else if(update_flag & 32)
		overlays += overlay_image(icon, "can-o3", plane = ABOVE_LIGHTING_PLANE, layer = ABOVE_LIGHTING_LAYER)
	return

/obj/machinery/portable_atmospherics/canister/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > temperature_resistance)
		health -= 5
		healthcheck()

/obj/machinery/portable_atmospherics/canister/proc/healthcheck()
	if(destroyed)
		return 1

	if (src.health <= 10)
		var/atom/location = src.loc
		location.assume_air(air_contents)

		src.destroyed = 1
		playsound(src.loc, 'sound/effects/spray.ogg', 10, 1, -3)
		src.set_density(0)
		update_icon()

		if (src.holding)
			src.holding.dropInto(loc)
			src.holding = null

		return 1
	else
		return 1

/obj/machinery/portable_atmospherics/canister/Process()
	if (destroyed)
		return

	..()
	valve_open = FALSE
	if(holding)
		refill_tank(holding)
	update_icon()

/obj/machinery/portable_atmospherics/canister/proc/return_temperature()
	var/datum/gas_mixture/GM = src.return_air()
	if(GM && GM.volume>0)
		return GM.temperature
	return 0

/obj/machinery/portable_atmospherics/canister/proc/return_pressure()
	var/datum/gas_mixture/GM = src.return_air()
	if(GM && GM.volume>0)
		return GM.return_pressure()
	return 0

/obj/machinery/portable_atmospherics/canister/bullet_act(var/obj/item/projectile/Proj)
	if(!(Proj.damage_type == BRUTE || Proj.damage_type == BURN))
		return

	if(Proj.damage)
		src.health -= round(Proj.damage / 2)
		healthcheck()
	..()

/obj/machinery/portable_atmospherics/canister/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if(destroyed)
		return
	if(isWrench(W))
		anchored = TRUE
		to_chat(user, "<span class='notice'>\The [src] is permanently secured.</span>")
		return
	if(istype(W, /obj/item/tank))
		if(holding)
			to_chat(user, "<span class='warning'>\A [holding] is already filling here.</span>")
			return
		if(istype(user, /mob/living/silicon/robot) && istype(W, /obj/item/tank/jetpack))
			if(refill_tank(W))
				to_chat(user, "<span class='notice'>You refill your jetpack from \the [src].</span>")
			return
		if(istype(user, /mob/living/silicon))
			return
		if(user.unEquip(W))
			W.forceMove(src)
			holding = W
			update_icon()
		return
	if(!isWrench(W) && !istype(W, /obj/item/tank) && !istype(W, /obj/item/device/analyzer) && !istype(W, /obj/item/device/pda))
		visible_message("<span class='warning'>\The [user] hits \the [src] with \a [W]!</span>")
		src.health -= W.force
		healthcheck()

/obj/machinery/portable_atmospherics/canister/attack_ai(var/mob/user as mob)
	return

/obj/machinery/portable_atmospherics/canister/attack_hand(var/mob/user as mob)
	if(destroyed || istype(user, /mob/living/silicon) || !user.Adjacent(src) || user.incapacitated())
		return
	if(holding)
		var/obj/item/tank/tank = holding
		holding = null
		tank.manipulated_by = user.real_name
		tank.update_icon()
		user.put_in_hands(tank)
		update_icon()

/obj/machinery/portable_atmospherics/canister/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	return

/obj/machinery/portable_atmospherics/canister/OnTopic(var/mob/user, href_list, state)
	return TOPIC_HANDLED

/obj/machinery/portable_atmospherics/canister/CanUseTopic()
	if(destroyed)
		return STATUS_CLOSE
	return ..()

/obj/machinery/portable_atmospherics/canister/phoron/New()
	..()

	src.air_contents.adjust_gas("phoron", MolesForPressure())
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/oxygen/New()
	..()

	src.air_contents.adjust_gas("oxygen", MolesForPressure())
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/hydrogen/New()
	..()
	src.air_contents.adjust_gas("hydrogen", MolesForPressure())
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/oxygen/prechilled/New()
	..()
	src.air_contents.temperature = 80
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/sleeping_agent/New()
	..()

	air_contents.adjust_gas("sleeping_agent", MolesForPressure())
	src.update_icon()
	return 1

//Dirty way to fill room with gas. However it is a bit easier to do than creating some floor/engine/n2o -rastaf0
/obj/machinery/portable_atmospherics/canister/sleeping_agent/roomfiller/New()
	..()
	air_contents.gas["sleeping_agent"] = 9*4000
	spawn(10)
		var/turf/simulated/location = src.loc
		if (istype(src.loc))
			while (!location.air)
				sleep(10)
			location.assume_air(air_contents)
			air_contents = new
	return 1

/obj/machinery/portable_atmospherics/canister/nitrogen/New()
	..()
	src.air_contents.adjust_gas("nitrogen", MolesForPressure())
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/nitrogen/prechilled/New()
	..()
	src.air_contents.temperature = 80
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/carbon_dioxide/New()
	..()
	src.air_contents.adjust_gas("carbon_dioxide", MolesForPressure())
	src.update_icon()
	return 1


/obj/machinery/portable_atmospherics/canister/air/New()
	..()
	src.update_icon()
	return 1



// Special types used for engine setup admin verb, they contain double amount of that of normal canister.
/obj/machinery/portable_atmospherics/canister/nitrogen/engine_setup/New()
	..()
	src.air_contents.adjust_gas("nitrogen", MolesForPressure())
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/carbon_dioxide/engine_setup/New()
	..()
	src.air_contents.adjust_gas("carbon_dioxide", MolesForPressure())
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/phoron/engine_setup/New()
	..()
	src.air_contents.adjust_gas("phoron", MolesForPressure())
	src.update_icon()
	return 1

/obj/machinery/portable_atmospherics/canister/hydrogen/engine_setup/New()
	..()
	src.air_contents.adjust_gas("hydrogen", MolesForPressure())
	src.update_icon()
