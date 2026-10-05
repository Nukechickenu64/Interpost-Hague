/obj/machinery/meter
	name = "meter"
	desc = "A gas flow meter."
	icon = 'icons/obj/meter.dmi'
	icon_state = "meterX"
	var/obj/machinery/atmospherics/pipe/target = null
	anchored = 1.0
	power_channel = ENVIRON
	var/frequency = 0
	var/id
	idle_power_usage = 15

/obj/machinery/meter/Initialize()
	. = ..()
	if (!target)
		src.target = locate(/obj/machinery/atmospherics/pipe) in loc

/obj/machinery/meter/Process()
	if(!target)
		icon_state = "meterX"
		return 0

	if(stat & (BROKEN|NOPOWER))
		icon_state = "meter0"
		return 0

	var/datum/gas_mixture/environment = target.return_air()
	if(!environment)
		icon_state = "meterX"
		return 0

	var/gas_level = isturf(target) ? environment.get_tile_moles() / MOLES_CELLSTANDARD : environment.return_pressure() / ONE_ATMOSPHERE
	if(gas_level <= 0.15)
		icon_state = "meter0"
	else if(gas_level <= 1.8)
		var/val = round(gas_level/0.3 + 0.5)
		icon_state = "meter1_[val]"
	else if(gas_level <= 30)
		var/val = round(gas_level/5 - 0.35) + 1
		icon_state = "meter2_[val]"
	else if(gas_level <= 59)
		var/val = round(gas_level/5 - 6) + 1
		icon_state = "meter3_[val]"
	else
		icon_state = "meter4"

	if(frequency)
		var/datum/radio_frequency/radio_connection = radio_controller.return_frequency(frequency)

		if(!radio_connection) return

		var/datum/signal/signal = new
		signal.source = src
		signal.transmission_method = 1
		signal.data = list(
			"tag" = id,
			"device" = "AM",
			"sigtype" = "status"
		)
		if(isturf(target))
			signal.data["tile_moles"] = round(environment.get_tile_moles(), 0.1)
		else
			signal.data["pressure"] = round(environment.return_pressure())
		radio_connection.post_signal(src, signal)

/obj/machinery/meter/examine(mob/user)
	. = ..()

	if(get_dist(user, src) > 3 && !(istype(user, /mob/living/silicon/ai) || isghost(user)))
		to_chat(user, "<span class='warning'>You are too far away to read it.</span>")

	else if(stat & (NOPOWER|BROKEN))
		to_chat(user, "<span class='warning'>The display is off.</span>")

	else if(src.target)
		var/datum/gas_mixture/environment = target.return_air()
		if(environment)
			var/reading = isturf(target) ? "[round(environment.get_tile_moles(), 0.01)] mol/tile" : "[round(environment.return_pressure(), 0.01)] kPa"
			to_chat(user, "The gas gauge reads [reading]; [round(environment.temperature,0.01)]K ([round(environment.temperature-T0C,0.01)]&deg;C)")
		else
			to_chat(user, "The sensor error light is blinking.")
	else
		to_chat(user, "The connect error light is blinking.")


/obj/machinery/meter/Click()

	if(istype(usr, /mob/living/silicon/ai)) // ghosts can call ..() for examine
		usr.examinate(src)
		return 1

	return ..()

/obj/machinery/meter/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(!isWrench(W))
		return ..()
	playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
	to_chat(user, "<span class='notice'>You begin to unfasten \the [src]...</span>")
	if (do_after(user, 40, src))
		user.visible_message( \
			"<span class='notice'>\The [user] unfastens \the [src].</span>", \
			"<span class='notice'>You have unfastened \the [src].</span>", \
			"You hear ratchet.")
		new /obj/item/pipe_meter(src.loc)
		qdel(src)

// TURF METER - REPORTS A TILE'S AIR CONTENTS

/obj/machinery/meter/turf/New()
	..()
	src.target = loc
	return 1


/obj/machinery/meter/turf/Initialize()
	. = ..()
	if (!target)
		src.target = loc

/obj/machinery/meter/turf/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	return
