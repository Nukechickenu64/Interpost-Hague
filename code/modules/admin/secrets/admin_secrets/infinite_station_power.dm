/datum/admin_secret_item/admin_secret/infinite_station_power
	name = "Toggle Infinite Station Power"

/datum/admin_secret_item/admin_secret/infinite_station_power/execute(var/mob/user)
	. = ..()
	if(!.)
		return

	GLOB.infinite_station_power = !GLOB.infinite_station_power
	log_and_message_admins("toggled infinite station power [GLOB.infinite_station_power ? "on" : "off"].")
	to_chat(user, SPAN_NOTICE("Infinite station power is now [GLOB.infinite_station_power ? "ENABLED" : "disabled"]."))
