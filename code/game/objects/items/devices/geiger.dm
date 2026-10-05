//Geiger counter
//Rewritten version of TG's geiger counter
//I opted to show exact radiation levels

/obj/item/device/medical_bracelet
	name = "medical bracelet"
	desc = "A wrist-worn medical monitor that transmits the wearer's vital signs and location to crew monitoring systems."
	icon = 'icons/obj/bracelets.dmi'
	icon_state = "pulsemeter"
	item_state = "multitool"
	w_class = ITEM_SIZE_SMALL
	slot_flags = SLOT_WRIST_L|SLOT_WRIST_R
	var/has_sensor = SUIT_HAS_SENSORS
	var/sensor_mode = SUIT_SENSOR_TRACKING

/obj/item/device/medical_bracelet/equipped(mob/user, slot)
	. = ..()
	transform = initial(transform)
	if(slot == slot_wrist_r)
		var/matrix/wrist_transform = matrix(transform)
		wrist_transform.Scale(-1, 1)
		transform = wrist_transform

/obj/item/device/medical_bracelet/dropped(mob/user)
	. = ..()
	transform = initial(transform)

/obj/item/device/medical_bracelet/examine(mob/user)
	. = ..()
	var/list/modes = list("off", "life signs", "vital signs", "vital signs and location")
	to_chat(user, SPAN_NOTICE("Its reporting mode is [modes[sensor_mode + 1]]."))
	if(ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		if(wearer.wrist_l == src || wearer.wrist_r == src)
			to_chat(user, SPAN_NOTICE("Pulse: [wearer.get_pulse(1)]. Body temperature: [round(wearer.bodytemperature - T0C, 0.1)] C."))

/obj/item/device/medical_bracelet/attack_self(mob/user)
	set_sensors(user)

/obj/item/device/medical_bracelet/proc/set_sensors(mob/user)
	if(isobserver(user) || user.incapacitated())
		return
	if(has_sensor >= SUIT_LOCKED_SENSORS)
		to_chat(user, SPAN_WARNING("The bracelet's sensor controls are locked."))
		return
	var/list/modes = list("Off", "Life signs", "Vital signs", "Vital signs and location")
	var/selected_mode = input(user, "Select a reporting mode:", "Medical Bracelet", modes[sensor_mode + 1]) as null|anything in modes
	if(!selected_mode || QDELETED(src) || user.incapacitated() || get_dist(user, src) > 1)
		return
	sensor_mode = modes.Find(selected_mode) - 1
	user.visible_message(SPAN_NOTICE("[user] adjusts \the [src]."), SPAN_NOTICE("You set \the [src] to [lowertext(selected_mode)]."))

/obj/item/device/medical_bracelet/verb/toggle_sensors()
	set name = "Set Medical Bracelet Sensors"
	set category = "Object"
	set src in usr
	set_sensors(usr)

/obj/item/device/medical_bracelet/emp_act(severity)
	..()
	sensor_mode = pick(SUIT_SENSOR_OFF, SUIT_SENSOR_BINARY, SUIT_SENSOR_VITAL)

/obj/item/device/geiger
	name = "geiger counter"
	desc = "A handheld device used for detecting and measuring radiation in an area."
	description_info = "By using this item, you may toggle its scanning mode on and off. Examine it while it's on to check for ambient radiation."
	description_fluff = "For centuries geiger counters have been saving the lives of unsuspecting laborers and technicians. You can never be too careful around radiation."
	icon_state = "geiger_off"
	item_state = "multitool"
	w_class = ITEM_SIZE_SMALL
	var/scanning = 0
	var/radiation_count = 0

/obj/item/device/geiger/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/device/geiger/Process()
	if(!scanning)
		return
	radiation_count = SSradiation.get_rads_at_turf(get_turf(src))
	update_icon()

/obj/item/device/geiger/attack_self(var/mob/user)
	scanning = !scanning
	if(scanning)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)
	update_icon()
	playsound(usr, 'sound/effects/mechanic_enable.ogg', 50, 0)
	to_chat(user, "<span class='notice'>\icon[src] You switch [scanning ? "on" : "off"] [src].</span>")

/obj/item/device/geiger/resolve_attackby(var/atom/A)
	var/turf/T = A
	if(!scanning)
		return
	if(!istype(T))
		to_chat(usr, "<span class='warning'>\The [src] only scans the surrounding area.</span>")
		playsound(usr, 'sound/misc/denied.ogg', 50, 0)
		return
	. = ..(usr)
	var/msg = "[scanning ? "Ambient" : "Stored"] radiation level: [radiation_count ? radiation_count : "0"] Bq."
	playsound(usr, 'sound/misc/accepted.ogg', 50, 0)
	to_chat(usr, "<span class='notice'>[msg]</span>")

/obj/item/device/geiger/update_icon()
	if(!scanning)
		icon_state = "geiger_off"
		return 1

	switch(radiation_count)
		if(null) icon_state = "geiger_on_1"
		if(-INFINITY to RAD_LEVEL_LOW) icon_state = "geiger_on_1"
		if(RAD_LEVEL_LOW + 0.01 to RAD_LEVEL_MODERATE) icon_state = "geiger_on_2"
		if(RAD_LEVEL_MODERATE + 0.1 to RAD_LEVEL_HIGH) icon_state = "geiger_on_3"
		if(RAD_LEVEL_HIGH + 1 to RAD_LEVEL_VERY_HIGH) icon_state = "geiger_on_4"
		if(RAD_LEVEL_VERY_HIGH + 1 to INFINITY) icon_state = "geiger_on_5"

/obj/item/device/geiger/bracelet
	name = "geiger bracelet"
	desc = "A wrist-worn radiation monitor that measures ambient radiation."
	icon = 'icons/obj/bracelets.dmi'
	icon_state = "dosimeter"
	slot_flags = SLOT_WRIST_L|SLOT_WRIST_R

/obj/item/device/geiger/bracelet/equipped(mob/user, slot)
	. = ..()
	transform = initial(transform)
	if(slot == slot_wrist_r)
		var/matrix/wrist_transform = matrix(transform)
		wrist_transform.Scale(-1, 1)
		transform = wrist_transform

/obj/item/device/geiger/bracelet/dropped(mob/user)
	. = ..()
	transform = initial(transform)

/obj/item/device/geiger/bracelet/Initialize()
	. = ..()
	scanning = TRUE
	START_PROCESSING(SSobj, src)

/obj/item/device/geiger/bracelet/update_icon()
	icon_state = "dosimeter"

/obj/item/device/geiger/bracelet/examine(mob/user)
	. = ..()
	if(scanning)
		radiation_count = SSradiation.get_rads_at_turf(get_turf(src))
		to_chat(user, SPAN_NOTICE("Ambient radiation level: [radiation_count ? radiation_count : 0] Bq."))
	else
		to_chat(user, SPAN_NOTICE("Its radiation scanner is switched off."))

