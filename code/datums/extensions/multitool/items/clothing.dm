/obj/item/device/medical_bracelet/New()
	set_extension(src, /datum/extension/interactive/multitool/items/clothing)
	..()

/datum/extension/interactive/multitool/items/clothing/interact(obj/item/device/multitool/M, mob/user)
	if(extension_status(user) != STATUS_INTERACTIVE)
		return
	var/obj/item/device/medical_bracelet/u = holder
	if(u.has_sensor == SUIT_NO_SENSORS)
		to_chat(user, SPAN_WARNING("\The [u] doesn't have medical sensors."))
		return
	u.has_sensor = u.has_sensor == SUIT_LOCKED_SENSORS ? SUIT_HAS_SENSORS : SUIT_LOCKED_SENSORS
	user.visible_message(SPAN_NOTICE("\The [user] [u.has_sensor == SUIT_LOCKED_SENSORS ? "" : "un"]locks \the [u]'s medical sensor controls."), range = 2)