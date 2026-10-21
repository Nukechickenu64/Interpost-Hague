var/global/list/obj/machinery/bluespacerelay/bluespace_relays = list()

/obj/machinery/bluespacerelay
	name = "Emergency Bluespace Relay"
	desc = "This sends messages through bluespace! Wow!"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "bspacerelay"
	anchored = 1
	density = 1
	idle_power_usage = 15000

/obj/machinery/bluespacerelay/update_icon()
	if(stat & (BROKEN|NOPOWER))
		icon_state = "[initial(icon_state)]_off"
	else
		icon_state = initial(icon_state)

/obj/machinery/bluespacerelay/New()
	..()
	bluespace_relays += src
	component_parts = list()
	component_parts += new /obj/item/circuitboard/bluespacerelay(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/subspace/filter(src)
	component_parts += new /obj/item/stock_parts/subspace/crystal(src)
	component_parts += new /obj/item/stack/cable_coil(src, 30)

/obj/machinery/bluespacerelay/Destroy()
	bluespace_relays -= src
	return ..()

// A single bluespace relay is all the telecomms infrastructure that radio
// traffic needs. It receives subspace transmissions and re-broadcasts them to
// every radio device, no receivers/buses/processors/servers required.
/obj/machinery/bluespacerelay/receive_signal(datum/signal/signal)
	if(stat & (BROKEN|NOPOWER)) // has to be on to receive messages
		return

	if(signal.data["message"])

		// Prevents massive radio spam
		signal.data["done"] = 1 // mark the signal as being broadcasted
		// Search for the original signal and mark it as done as well
		var/datum/signal/original = signal.data["original"]
		if(original)
			original.data["done"] = 1
			original.data["compression"] = signal.data["compression"]
			original.data["level"] = signal.data["level"]

		var/signal_message = "[signal.frequency]:[signal.data["message"]]:[signal.data["realname"]]"
		if(signal_message in recentmessages)
			return
		recentmessages.Add(signal_message)

		if(!message_delay)
			message_delay = 1
			spawn(10)
				message_delay = 0
				recentmessages = list()

		if(signal.data["slow"] > 0)
			sleep(signal.data["slow"]) // simulate the network lag if necessary

		// Bluespace reaches every connected level with a single machine.
		var/turf/position = get_turf(src)
		if(!position)
			return
		if(!islist(signal.data["level"]))
			signal.data["level"] = list(signal.data["level"])
		signal.data["level"] |= GetConnectedZlevels(position.z)

		/** #### - Normal / Artificial Broadcast - #### **/

		if(signal.data["type"] == 0 || signal.data["type"] == 2)
			var/datum/radio_frequency/connection = signal.data["connection"]
			if(istype(connection))
				var/vdata = (signal.data["type"] == 2) ? 4 : null
				Broadcast_Message(signal.data["connection"], signal.data["mob"],
								  signal.data["vmask"], signal.data["vmessage"],
								  signal.data["radio"], signal.data["message"],
								  signal.data["name"], signal.data["job"],
								  signal.data["realname"], signal.data["vname"], vdata, signal.data["compression"], signal.data["level"], connection.frequency,
								  signal.data["verb"], signal.data["language"])

/obj/machinery/bluespacerelay/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(default_deconstruction_screwdriver(user, O))
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return

	..()