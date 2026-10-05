/obj/item/device/flashlight
	name = "flashlight"
	desc = "A hand-held emergency light."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "flashlight"
	item_state = "flashlight"
	w_class = ITEM_SIZE_SMALL
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT

	matter = list(DEFAULT_WALL_MATERIAL = 50,"glass" = 20)

	action_button_name = "Toggle Flashlight"
	var/on = 0
	var/brightness_on = 4 //range of light when on
	var/activation_sound = 'sound/effects/flashlight.ogg'
	var/flashlight_power //luminosity of light when on, can be negative
	var/cone_angle = 30 // half-width in degrees; 0 keeps an all-around glow and disables aiming
	var/cone_range = 6
	var/glow_range = 2
	var/aim_angle
	var/aim_target_x
	var/aim_target_y
	var/mob/cone_holder

/obj/item/device/flashlight/Initialize()
	. = ..()
	update_icon()

/obj/item/device/flashlight/Destroy()
	set_cone_holder(null)
	return ..()

/obj/item/device/flashlight/update_icon()
	if(on)
		icon_state = "[initial(icon_state)]-on"
		item_state = "[initial(icon_state)]-on"
		var/range = cone_angle ? cone_range : brightness_on
		update_cone()
		if(flashlight_power)
			set_light(l_range = range, l_power = flashlight_power)
		else
			set_light(range)
	else
		icon_state = "[initial(icon_state)]"
		item_state = "[initial(icon_state)]"
		set_light(0)
		update_cone()

/obj/item/device/flashlight/proc/update_cone()
	if(!on || !cone_angle)
		set_light_cone(0, 0, 0, null, null)
		return
	var/mob/M = loc
	if(!istype(M) || M.get_active_hand() != src || isnull(aim_angle))
		set_light_cone(cone_angle, get_cone_dir(), glow_range, null, null)
	else
		set_light_cone(cone_angle, get_cone_dir(), glow_range, aim_target_x, aim_target_y)

/obj/item/device/flashlight/proc/get_cone_dir()
	var/mob/M = loc
	if(istype(M))
		if(!isnull(aim_angle) && M.get_active_hand() == src)
			return aim_angle
		. = dir2angle(M.dir)
	else
		. = dir2angle(dir)
	if(isnull(.))
		. = 180

/obj/item/device/flashlight/proc/set_cone_holder(mob/M)
	if(cone_holder == M)
		return
	if(cone_holder)
		GLOB.dir_set_event.unregister(cone_holder, src, /obj/item/device/flashlight/proc/holder_dir_set)
	cone_holder = M
	if(cone_holder && cone_angle)
		GLOB.dir_set_event.register(cone_holder, src, /obj/item/device/flashlight/proc/holder_dir_set)

/obj/item/device/flashlight/proc/holder_dir_set(atom/holder, old_dir, new_dir)
	if(loc != holder)
		set_cone_holder(null)
		return
	if(on && old_dir != new_dir)
		update_cone()

/obj/item/device/flashlight/proc/hands_swapped(mob/user)
	if(user.get_active_hand() != src)
		aim_angle = null
	update_cone()

/obj/item/device/flashlight/equipped(mob/user, slot)
	. = ..()
	set_cone_holder(user)
	if(user.get_active_hand() != src)
		aim_angle = null
	update_cone()

/obj/item/device/flashlight/dropped(mob/user)
	. = ..()
	if(loc != user)
		set_cone_holder(null)
		aim_angle = null
		if(user)
			set_dir(user.dir)
	update_cone()

/obj/item/device/flashlight/proc/can_aim(atom/A, mob/user)
	if(!on || !cone_angle || !A || !user || user.get_active_hand() != src)
		return FALSE
	if(user.a_intent == I_HURT)
		return FALSE
	if(istype(A, /obj/screen/click_catcher))
		return TRUE
	if(!(isturf(A) || isturf(A.loc)))
		return FALSE
	if(ismob(A) && user.a_intent == I_HELP && user.zone_sel && user.zone_sel.selecting == BP_EYES && A.Adjacent(user))
		return FALSE
	return TRUE

/obj/item/device/flashlight/proc/aim_at(atom/A, mob/user, params)
	var/turf/U = get_turf(user)
	if(!U || !A)
		return
	var/px
	var/py
	var/list/P = params2list(params)
	if(istype(A, /obj/screen/click_catcher))
		var/obj/screen/click_catcher/CC = A
		px = (U.x + CC.x_offset - 1) * world.icon_size
		py = (U.y + CC.y_offset - 1) * world.icon_size
	else
		var/turf/T = get_turf(A)
		if(!T || T.z != U.z)
			return
		px = (T.x - 1) * world.icon_size + A.pixel_x
		py = (T.y - 1) * world.icon_size + A.pixel_y
	if(P["icon-x"] && P["icon-y"])
		px += text2num(P["icon-x"])
		py += text2num(P["icon-y"])
	else
		px += world.icon_size / 2
		py += world.icon_size / 2

	var/dx = px - ((U.x - 1) * world.icon_size + world.icon_size / 2)
	var/dy = py - ((U.y - 1) * world.icon_size + world.icon_size / 2)
	if(!dx && !dy)
		return
	if(!dy)
		aim_angle = dx > 0 ? 90 : 270
	else
		aim_angle = arctan(dx / dy)
		if(dy < 0)
			aim_angle += 180
		else if(dx < 0)
			aim_angle += 360

	var/face = abs(dx) > abs(dy) ? (dx > 0 ? EAST : WEST) : (dy > 0 ? NORTH : SOUTH)
	if(user.dir != face && user.canface())
		if(user.facing_dir)
			user.facing_dir = face
		user.set_dir(face)
	var/turf/target_turf = get_turf(A)
	if(target_turf && target_turf.z == U.z)
		aim_target_x = target_turf.x + (px - (target_turf.x - 1) * world.icon_size) / world.icon_size - 0.5
		aim_target_y = target_turf.y + (py - (target_turf.y - 1) * world.icon_size) / world.icon_size - 0.5
	update_cone()

/client
	var/atom/flashlight_aim_target
	var/flashlight_aim_params
	var/flashlight_aiming = FALSE

/client/proc/flashlight_mouse_down(atom/object, params)
	var/list/P = params2list(params)
	if(!P["left"] || P["shift"] || P["ctrl"] || P["alt"] || !mob)
		return FALSE
	var/obj/item/device/flashlight/F = mob.get_active_hand()
	if(!istype(F) || !F.can_aim(object, mob))
		return FALSE
	flashlight_aim_target = object
	flashlight_aim_params = params
	if(!flashlight_aiming)
		flashlight_aim_loop(F)
	return TRUE

/client/proc/flashlight_aim_loop(obj/item/device/flashlight/F)
	set waitfor = FALSE
	flashlight_aiming = TRUE
	var/atom/last_target
	var/last_params
	var/turf/last_user_turf
	var/turf/last_target_turf
	var/last_target_pixel_x
	var/last_target_pixel_y
	var/last_user_dir
	var/last_canface
	while(flashlight_aim_target && mob && !QDELETED(F) && F.on && mob.get_active_hand() == F && !mob.incapacitated() && mob.a_intent != I_HURT)
		if(QDELETED(flashlight_aim_target))
			break
		var/turf/user_turf = get_turf(mob)
		var/turf/target_turf = get_turf(flashlight_aim_target)
		var/canface = mob.canface()
		if(isnull(F.aim_angle) || last_target != flashlight_aim_target || last_params != flashlight_aim_params || last_user_turf != user_turf || last_target_turf != target_turf || last_target_pixel_x != flashlight_aim_target.pixel_x || last_target_pixel_y != flashlight_aim_target.pixel_y || last_user_dir != mob.dir || last_canface != canface)
			F.aim_at(flashlight_aim_target, mob, flashlight_aim_params)
			last_target = flashlight_aim_target
			last_params = flashlight_aim_params
			last_user_turf = user_turf
			last_target_turf = target_turf
			last_target_pixel_x = flashlight_aim_target.pixel_x
			last_target_pixel_y = flashlight_aim_target.pixel_y
			last_user_dir = mob.dir
			last_canface = canface
		sleep(world.tick_lag)
	flashlight_aim_target = null
	flashlight_aiming = FALSE

/obj/item/device/flashlight/attack_self(mob/user)
	if(!isturf(user.loc))
		to_chat(user, "You cannot turn the light on while in this [user.loc].")//To prevent some lighting anomalities.

		return 0
	on = !on
	if(on && activation_sound)
		playsound(src.loc, activation_sound, 75, 1)
		item_state = "[initial(icon_state)]-on"
	else
		playsound(src.loc, activation_sound, 75, 1)
		item_state = "[initial(icon_state)]"
	update_icon()
	user.update_action_buttons()
	return 1

/obj/item/device/flashlight/attack(mob/living/M as mob, mob/living/user as mob)
	add_fingerprint(user)
	if(on && user.zone_sel.selecting == BP_EYES)

		if((CLUMSY in user.mutations) && prob(50))	//too dumb to use flashlight properly
			return ..()	//just hit them in the head

		var/mob/living/carbon/human/H = M	//mob has protective eyewear
		if(istype(H))
			if(H.is_leech() && flashlight_power >= 3)
				H.handle_leech_light_exposure(2)
			for(var/obj/item/clothing/C in list(H.head,H.wear_mask,H.glasses))
				if(istype(C) && (C.body_parts_covered & EYES))
					to_chat(user, "<span class='warning'>You're going to need to remove [C] first.</span>")
					return

			var/obj/item/organ/vision
			if(!H.species.vision_organ || !H.should_have_organ(H.species.vision_organ))
				to_chat(user, "<span class='warning'>You can't find anything on [H] to direct [src] into!</span>")
				return

			vision = H.internal_organs_by_name[H.species.vision_organ]
			if(!vision)
				vision = H.species.has_organ[H.species.vision_organ]
				to_chat(user, "<span class='warning'>\The [H] is missing \his [initial(vision.name)]!</span>")
				return

			user.visible_message("<span class='notice'>\The [user] directs [src] into [M]'s [vision.name].</span>", \
								 "<span class='notice'>You direct [src] into [M]'s [vision.name].</span>")

			inspect_vision(vision, user)

			user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN) //can be used offensively
			M.flash_eyes()
	else
		return ..()

/obj/item/device/flashlight/proc/inspect_vision(obj/item/organ/vision, mob/living/user)
	var/mob/living/carbon/human/H = vision.owner

	if(H == user)	//can't look into your own eyes buster
		return

	if(vision.robotic < ORGAN_ROBOT )

		if(vision.owner.stat == DEAD || H.blinded)	//mob is dead or fully blind
			to_chat(user, "<span class='warning'>\The [H]'s pupils do not react to the light!</span>")
			return
		if(XRAY in H.mutations)
			to_chat(user, "<span class='notice'>\The [H]'s pupils give an eerie glow!</span>")
		if(vision.damage)
			to_chat(user, "<span class='warning'>There's visible damage to [H]'s [vision.name]!</span>")
		else if(H.eye_blurry)
			to_chat(user, "<span class='notice'>\The [H]'s pupils react slower than normally.</span>")
		if(H.getBrainLoss() > 15)
			to_chat(user, "<span class='notice'>There's visible lag between left and right pupils' reactions.</span>")

		var/list/pinpoint = list(/datum/reagent/tramadol/oxycodone=1,/datum/reagent/tramadol=5)
		var/list/dilating = list(/datum/reagent/space_drugs=5,/datum/reagent/mindbreaker=1,/datum/reagent/adrenaline=1)
		var/datum/reagents/ingested = H.get_ingested_reagents()
		if(H.reagents.has_any_reagent(pinpoint) || ingested.has_any_reagent(pinpoint))
			to_chat(user, "<span class='notice'>\The [H]'s pupils are already pinpoint and cannot narrow any more.</span>")
		else if(H.shock_stage >= 30 || H.reagents.has_any_reagent(dilating) || ingested.has_any_reagent(dilating))
			to_chat(user, "<span class='notice'>\The [H]'s pupils narrow slightly, but are still very dilated.</span>")
		else
			to_chat(user, "<span class='notice'>\The [H]'s pupils narrow.</span>")

	//if someone wants to implement inspecting robot eyes here would be the place to do it.

/obj/item/device/flashlight/upgraded
	name = "\improper LED flashlight"
	desc = "An energy efficient flashlight."
	icon_state = "biglight"
	item_state = "biglight"
	brightness_on = 6
	flashlight_power = 3
	cone_range = 8

/obj/item/device/flashlight/flashdark
	name = "flashdark"
	desc = "A strange device manufactured with mysterious elements that somehow emits darkness. Or maybe it just sucks in light? Nobody knows for sure."
	icon_state = "flashdark"
	item_state = "flashdark"
	w_class = ITEM_SIZE_NORMAL
	brightness_on = 8
	flashlight_power = -6
	cone_range = 8
	cone_angle = 35

/obj/item/device/flashlight/pen
	name = "penlight"
	desc = "A pen-sized light, used by medical staff."
	icon_state = "penlight"
	item_state = ""
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_EARS
	brightness_on = 2
	w_class = ITEM_SIZE_TINY
	cone_range = 3
	cone_angle = 20
	glow_range = 1

/obj/item/device/flashlight/maglight
	name = "maglight"
	desc = "A very, very heavy duty flashlight."
	icon_state = "maglight"
	item_state = "maglight"
	force = 10
	attack_verb = list ("smacked", "thwacked", "thunked")
	matter = list(DEFAULT_WALL_MATERIAL = 200,"glass" = 50)
	hitsound = "swing_hit"
	cone_range = 7
	cone_angle = 25

/obj/item/device/flashlight/drone
	name = "low-power flashlight"
	desc = "A miniature lamp, that might be used by small robots."
	icon_state = "penlight"
	item_state = ""
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	brightness_on = 2
	w_class = ITEM_SIZE_TINY
	cone_angle = 0


// the desk lamps are a bit special
/obj/item/device/flashlight/lamp
	name = "desk lamp"
	desc = "A desk lamp with an adjustable mount."
	icon_state = "lamp"
	item_state = "lamp"
	brightness_on = 5
	w_class = ITEM_SIZE_LARGE
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	cone_angle = 0

	on = 1


// green-shaded desk lamp
/obj/item/device/flashlight/lamp/green
	desc = "A classic green-shaded desk lamp."
	icon_state = "lampgreen"
	item_state = "lampgreen"
	brightness_on = 4
	light_color = "#ffc58f"

/obj/item/device/flashlight/lamp/verb/toggle_light()
	set name = "Toggle light"
	set category = "Object"
	set src in oview(1)

	if(!usr.stat)
		attack_self(usr)

// FLARES

/obj/item/device/flashlight/flare
	name = "flare"
	desc = "A red standard-issue flare. There are instructions on the side reading 'pull cord, make light'."
	w_class = ITEM_SIZE_TINY
	brightness_on = 8 // Pretty bright.
	light_power = 3
	light_color = "#e58775"
	icon_state = "flare"
	item_state = "flare"
	action_button_name = null //just pull it manually, neckbeard.
	cone_angle = 0
	var/fuel = 0
	var/on_damage = 7
	var/produce_heat = 1500
	activation_sound = 'sound/effects/flare.ogg'

/obj/item/device/flashlight/flare/Initialize()
	fuel = rand(800, 1000) // Sorry for changing this so much but I keep under-estimating how long X number of ticks last in seconds.
	. = ..()

/obj/item/device/flashlight/flare/Process()
	var/turf/pos = get_turf(src)
	if(pos)
		pos.hotspot_expose(produce_heat, 5)
	fuel = max(fuel - 1, 0)
	if(!fuel || !on)
		turn_off()
		if(!fuel)
			src.icon_state = "[initial(icon_state)]-empty"
		STOP_PROCESSING(SSobj, src)

/obj/item/device/flashlight/flare/proc/turn_off()
	on = 0
	src.force = initial(src.force)
	src.damtype = initial(src.damtype)
	update_icon()

/obj/item/device/flashlight/flare/attack_self(mob/user)
	if(turn_on(user))
		user.visible_message("<span class='notice'>\The [user] activates \the [src].</span>", "<span class='notice'>You pull the cord on the flare, activating it!</span>")

/obj/item/device/flashlight/flare/proc/turn_on(var/mob/user)
	if(on)
		return FALSE
	if(!fuel)
		if(user)
			to_chat(user, "<span class='notice'>It's out of fuel.</span>")
		return FALSE
	on = TRUE
	force = on_damage
	damtype = "fire"
	START_PROCESSING(SSobj, src)
	update_icon()
	return 1

//Glowsticks
/obj/item/device/flashlight/glowstick
	name = "green glowstick"
	desc = "A military-grade glowstick."
	w_class = 2.0
	brightness_on = 4
	light_power = 2
	color = "#49f37c"
	icon_state = "glowstick"
	item_state = "glowstick"
	randpixel = 12
	var/fuel = 0
	activation_sound = null
	cone_angle = 0

/obj/item/device/flashlight/glowstick/Initialize()
	fuel = rand(1600, 2000)
	light_color = color
	. = ..()

/obj/item/device/flashlight/glowstick/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/device/flashlight/glowstick/Process()
	fuel = max(fuel - 1, 0)
	if(!fuel)
		turn_off()
		STOP_PROCESSING(SSobj, src)
		update_icon()

/obj/item/device/flashlight/glowstick/proc/turn_off()
	on = 0
	update_icon()

/obj/item/device/flashlight/glowstick/update_icon()
	item_state = "glowstick"
	overlays.Cut()
	if(!fuel)
		icon_state = "glowstick-empty"
		set_light(0)
	else if (on)
		var/image/I = overlay_image(icon,"glowstick-on",color)
		I.blend_mode = BLEND_ADD
		overlays += I
		item_state = "glowstick-on"
		set_light(brightness_on)
	else
		icon_state = "glowstick"
	var/mob/M = loc
	if(istype(M))
		if(M.l_hand == src)
			M.update_inv_l_hand()
		if(M.r_hand == src)
			M.update_inv_r_hand()

/obj/item/device/flashlight/glowstick/attack_self(mob/user)

	if(!fuel)
		to_chat(user,"<span class='notice'>\The [src] is spent.</span>")
		return
	if(on)
		to_chat(user,"<span class='notice'>\The [src] is already lit.</span>")
		return

	. = ..()
	if(.)
		user.visible_message("<span class='notice'>[user] cracks and shakes the glowstick.</span>", "<span class='notice'>You crack and shake the glowstick, turning it on!</span>")
		START_PROCESSING(SSobj, src)

/obj/item/device/flashlight/glowstick/red
	name = "red glowstick"
	color = "#fc0f29"

/obj/item/device/flashlight/glowstick/blue
	name = "blue glowstick"
	color = "#599dff"

/obj/item/device/flashlight/glowstick/orange
	name = "orange glowstick"
	color = "#fa7c0b"

/obj/item/device/flashlight/glowstick/yellow
	name = "yellow glowstick"
	color = "#fef923"

/obj/item/device/flashlight/glowstick/random
	name = "glowstick"
	desc = "A party-grade glowstick."
	color = "#ff00ff"

/obj/item/device/flashlight/glowstick/random/New()
	color = rgb(rand(50,255),rand(50,255),rand(50,255))
	..()

/obj/item/device/flashlight/slime
	gender = PLURAL
	name = "glowing slime extract"
	desc = "A glowing ball of what appears to be amber."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "floor1" //not a slime extract sprite but... something close enough!
	item_state = "slime"
	w_class = ITEM_SIZE_TINY
	brightness_on = 6
	on = 1 //Bio-luminesence has one setting, on.
	cone_angle = 0

/obj/item/device/flashlight/slime/New()
	..()
	set_light(brightness_on)

/obj/item/device/flashlight/slime/update_icon()
	return

/obj/item/device/flashlight/slime/attack_self(mob/user)
	return //Bio-luminescence does not toggle.

// torch

/obj/item/device/flashlight/torch
	name = "torch"
	desc = "A simple torch."
	w_class = ITEM_SIZE_LARGE // It's a torch.
	brightness_on = 8 // Pretty bright.
	light_power = 3
	light_color = "#e58775"
	icon_state = "torch0"
	item_state = "torch"
	action_button_name = null //just pull it manually, neckbeard.
	cone_angle = 0
	var/fuel = 0
	var/on_damage = 7
	var/produce_heat = 1500
	//activation_sound = ''

/obj/item/device/flashlight/torch/Initialize()
	fuel = rand(800, 1000)
	. = ..()

/obj/item/device/flashlight/torch/Process()
	var/turf/pos = get_turf(src)
	if(pos)
		pos.hotspot_expose(produce_heat, 5)
	fuel = max(fuel - 1, 0)
	if(!fuel || !on)
		turn_off()
		if(!fuel)
			src.icon_state = "[initial(icon_state)]-empty"
		STOP_PROCESSING(SSobj, src)

/obj/item/device/flashlight/torch/proc/turn_off()
	on = 0
	src.force = initial(src.force)
	src.damtype = initial(src.damtype)
	update_icon()

/obj/item/device/flashlight/torch/attackby(obj/item/C, mob/user)
	if(istype(C, /obj/item/weapon/flame/lighter))
		turn_on(C, user)
		to_chat(user, "<span class='notice'>You turn on the torch.</span>")
	else
		return FALSE

/obj/item/device/flashlight/torch/proc/turn_on(var/mob/user)
	if(on)
		return FALSE
	if(!fuel)
		if(user)
			to_chat(user, "<span class='notice'>It's burned out.</span>")
		return FALSE
	on = TRUE
	force = on_damage
	damtype = "fire"
	START_PROCESSING(SSobj, src)
	update_icon()
	return 1
