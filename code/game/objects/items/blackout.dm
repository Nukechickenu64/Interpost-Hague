// Blackout tool, used to trigger massive electricity outttage on ship or station, including connected levels.
// It may have additional shots to use, but currently balanced to one shot.

/datum/uplink_item/item/tools/blackout
	name = "High Pulse Electricity Outage Tool"
	item_cost = 24
	path = /obj/item/weapon/blackout
	desc = "A device wich can create power virus in terminal, spread it in power network and temporally creating blackout."

/obj/item/weapon/blackout
	name = "high pulse electricity outage tool"
	desc = "A unknown device, probably only experienced electrics know what this can do."
	icon = 'icons/obj/blackout.dmi'
	icon_state = "device_blackout-off"

	var/severity = 2
	var/shots = 1
	var/lastUse = 0
	var/cooldown = (20 MINUTES)

/obj/item/weapon/blackout/afterattack(obj/target, mob/user, proximity)
	if(!proximity)
		return

	if(!istype(target))
		return

	add_fingerprint(user)

	if(istype(target, /obj/machinery/power))
		var/obj/machinery/power/power_machine = target

		if(!power_machine.powernet && !power_machine.input_powernet)
			to_chat(user, "<span class='warning'>This power station isn't connected to power net.</span>")
			return

		if(check_to_use())
			to_chat(user, "<span class='warning'>Device does not respond. Perhaps you need to try later.</span>")
			return

		if(!shots)
			to_chat(user, "<span class='warning>Device does not respond.</span>")
			return

		hacktheenergy(power_machine, user)

/obj/item/weapon/blackout/proc/hacktheenergy(obj/machinery/power/power_machine, mob/user)
	if(!istype(power_machine) || !user) return

	src.audible_message("<font color=Maroon><b>HackTheEnergy.exe Assistant</b></font> says, \
	\"-- Starting. Connecting to the therminal. --\"")
	if(!do_after(user, 30, power_machine)) return

	src.audible_message("<font color=Maroon><b>HackTheEnergy.exe Assistant</b></font> says, \
	\"-- Successful Ñonnection to the terminal. Getting information about the powergrid ... --\"")
	if(!do_after(user, 80, power_machine)) return

	src.audible_message("<font color=Maroon><b>HackTheEnergy.exe Assistant</b></font> says, \
	\"-- Powernet scan succeeded. Starting the pulsation procedure. --\"")

	icon_state = "device_blackout-on"
	playsound(src, 'sound/items/goggles_charge.ogg', 50, 1)

	if(!do_after(user, 40, power_machine)) return
	src.audible_message("<font color=Maroon><b>HackTheEnergy.exe Assistant</b></font> says, \
	\"-- Done. Pulsing is complete. We wish you a successful and productive mission. --\"")

	shots--
	cooldown = world.time

	var/datum/powernet/powernet = power_machine.input_powernet || power_machine.powernet
	if(!powernet)
		return
	for(var/obj/machinery/power/area_smes/A in powernet.nodes)
		A.energy_fail(rand(30 * severity, 60 * severity))
	for(var/obj/machinery/power/smes/buildable/S in powernet.nodes | powernet.input_nodes)
		S.energy_fail(rand(15 * severity, 30 * severity))

	log_and_message_admins("used \the [src] on \the [power_machine] to shutdown powernet.", user)
	icon_state = "device_blackout-off"

/obj/item/weapon/blackout/proc/check_to_use()
	return lastUse <= (world.time - cooldown)