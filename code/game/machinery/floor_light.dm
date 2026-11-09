var/list/floor_light_cache = list()

/obj/machinery/floor_light
	name = "floor light"
	icon = 'icons/obj/machines/floor_light.dmi'
	icon_state = "base"
	desc = "A backlit floor panel."
	layer = ABOVE_TILE_LAYER
	anchored = 0
	use_power = POWER_USE_OFF
	idle_power_usage = 0
	active_power_usage = 0
	power_channel = LIGHT
	matter = list(DEFAULT_WALL_MATERIAL = 250, "glass" = 250)

	var/on
	var/on_until = 0
	var/emergency_power = FALSE
	var/damaged
	var/default_light_range = 4
	var/default_light_power = 2
	var/default_light_colour = "#F9C763"
	var/image/emissive_overlay

/obj/machinery/floor_light/prebuilt
	anchored = 1

/obj/machinery/floor_light/Initialize()
	. = ..()
	if(on)
		on_until = world.time + 1 MINUTE
	power_change()

/obj/machinery/floor_light/power_change()
	. = ..()
	update_light_state()
	update_brightness()

/obj/machinery/floor_light/attackby(var/obj/item/W, var/mob/user)
	if(isScrewdriver(W))
		anchored = !anchored
		visible_message("<span class='notice'>\The [user] has [anchored ? "attached" : "detached"] \the [src].</span>")
		update_light_state()
		update_brightness()
	else if(isWelder(W) && (damaged || (stat & BROKEN)))
		var/obj/item/weldingtool/WT = W
		if(!WT.remove_fuel(0, user))
			to_chat(user, "<span class='warning'>\The [src] must be on to complete this task.</span>")
			return
		playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
		if(!do_after(user, 20, src))
			return
		if(!src || !WT.isOn())
			return
		visible_message("<span class='notice'>\The [user] has repaired \the [src].</span>")
		set_broken(FALSE)
		damaged = null
		update_brightness()
	else if(W.force && user.a_intent == "hurt")
		attack_hand(user)
	return

/obj/machinery/floor_light/attack_hand(var/mob/user)

	if(user.a_intent == I_HURT && !issmall(user))
		if(!isnull(damaged) && !(stat & BROKEN))
			visible_message("<span class='danger'>\The [user] smashes \the [src]!</span>")
			playsound(src, "shatter", 70, 1)
			set_broken(TRUE)
		else
			visible_message("<span class='danger'>\The [user] attacks \the [src]!</span>")
			playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
			if(isnull(damaged)) damaged = 0
		update_brightness()
		return
	else

		if(!anchored)
			to_chat(user, "<span class='warning'>\The [src] must be screwed down first.</span>")
			return

		if(stat & BROKEN)
			to_chat(user, "<span class='warning'>\The [src] is too damaged to be functional.</span>")
			return

		power_change()
		if(emergency_power)
			to_chat(user, "<span class='warning'>\The [src] is providing emergency lighting.</span>")
			return

		on = !on
		on_until = on ? world.time + 1 MINUTE : 0
		visible_message("<span class='notice'>\The [user] turns \the [src] [on ? "on" : "off"].</span>")
		update_brightness()
		return

/obj/machinery/floor_light/Process()
	..()
	if(update_light_state())
		update_brightness()

/obj/machinery/floor_light/proc/update_light_state()
	var/was_on = on
	var/was_emergency = emergency_power
	var/area/light_area = get_area(src)
	emergency_power = light_area && !light_area.powered(LIGHT)
	if(emergency_power)
		on = TRUE
		on_until = 0
	else if(was_emergency || (on && world.time >= on_until))
		on = FALSE
		on_until = 0
	if(!anchored || broken())
		on = FALSE
		on_until = 0
	return on != was_on || emergency_power != was_emergency

/obj/machinery/floor_light/proc/update_brightness()
	update_use_power(POWER_USE_OFF)
	if(on && anchored && !broken())
		if(light_range != default_light_range || light_power != default_light_power || light_color != default_light_colour)
			set_light(default_light_range, default_light_power, default_light_colour)
	else
		if(light_range || light_power)
			set_light(0)

	update_icon()

/obj/machinery/floor_light/update_icon()
	overlays.Cut()
	emissive_overlay = null
	if(on && anchored && !broken())
		if(isnull(damaged))
			var/cache_key = "floorlight-[default_light_colour]"
			if(!floor_light_cache[cache_key])
				var/image/I = image("on")
				I.color = default_light_colour
				I.plane = plane
				I.layer = layer+0.001
				floor_light_cache[cache_key] = I
			overlays |= floor_light_cache[cache_key]
			emissive_overlay = overlay_image(icon, "on", default_light_colour, RESET_COLOR, EMISSIVE_PLANE, EMISSIVE_LAYER)
		else
			if(damaged == 0) //Needs init.
				damaged = rand(1,4)
			var/cache_key = "floorlight-broken[damaged]-[default_light_colour]"
			if(!floor_light_cache[cache_key])
				var/image/I = image("flicker[damaged]")
				I.color = default_light_colour
				I.plane = plane
				I.layer = layer+0.001
				floor_light_cache[cache_key] = I
			overlays |= floor_light_cache[cache_key]
			emissive_overlay = overlay_image(icon, "flicker[damaged]", default_light_colour, RESET_COLOR, EMISSIVE_PLANE, EMISSIVE_LAYER)
	if(emissive_overlay)
		emissive_overlay.blend_mode = BLEND_ADD
		overlays += emissive_overlay

/obj/machinery/floor_light/proc/broken()
	return (stat & BROKEN)

/obj/machinery/floor_light/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
		if(2)
			if (prob(50))
				qdel(src)
			else if(prob(20))
				set_broken(TRUE)
			else
				if(isnull(damaged))
					damaged = 0
		if(3)
			if (prob(5))
				qdel(src)
			else if(isnull(damaged))
				damaged = 0
	return

/obj/machinery/floor_light/Destroy()
	var/area/A = get_area(src)
	if(A)
		on = 0
	. = ..()

// Recessed, round grated fixture seen in the OS13 cryogenic/locker rooms.
// This is a light, not a sewer hatch or a decorative floor overlay.
/obj/machinery/floor_light/os13
	name = "recessed floor light"
	desc = "A floor lamp protected by a round metal grate."
	icon = 'icons/os13/objects/objects/miscobjs.dmi'
	icon_state = "floorlight0"
	anchored = 1
	density = 0
	on = 0
	use_power = POWER_USE_OFF

/obj/machinery/floor_light/os13/update_icon()
	// Do not inherit the square panel's cached "on"/"flicker" overlays.
	overlays.Cut()
	emissive_overlay = null
	icon_state = "floorlight0"
	if(on && anchored && !broken())
		icon_state = "floorlight1"
		if(!isnull(damaged))
			icon_state = "floorlight01"
		else
			// The authored lens is amber. Its red channel contains its brightness
			// mask; multiplying the amber RGB by a white/blue lamp color retained
			// that baked tint. Use the mask for both the visible lens and emission.
			icon_state = "floorlight0"
			var/list/lens_color = floor_light_lens_color(default_light_colour)
			overlays += overlay_image(icon, "floorlight2", lens_color, RESET_COLOR, plane, layer + 0.001)
			emissive_overlay = overlay_image(icon, "floorlight2", lens_color, RESET_COLOR, EMISSIVE_PLANE, EMISSIVE_LAYER)
			emissive_overlay.blend_mode = BLEND_ADD
			overlays += emissive_overlay

// Preserve the lens alpha and shade; tint a neutral emission mask rather than
// multiplying two independent spectra (the atlas amber and the lamp color).
/proc/floor_light_lens_color(light_colour)
	var/list/channels = ReadRGB(light_colour)
	return list(channels[1] / 255, channels[2] / 255, channels[3] / 255, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0)
