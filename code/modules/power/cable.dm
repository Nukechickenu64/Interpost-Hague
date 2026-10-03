// Cable coil: crafting/construction material only. Power is routed through CCID links, not floor cables.

var/list/possible_cable_coil_colours


///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

#define MAXCOIL 30

/obj/item/stack/cable_coil
	name = "multipurpose cable coil"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	randpixel = 2
	amount = MAXCOIL
	max_amount = MAXCOIL
	color = COLOR_RED
	desc = "A coil of wiring, for delicate electronics use aswell as the more basic cable laying."
	throwforce = 0
	w_class = ITEM_SIZE_NORMAL
	throw_speed = 2
	throw_range = 5
	matter = list(DEFAULT_WALL_MATERIAL = 50, "glass" = 20)
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BELT
	item_state = "coil"
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = /obj/item/stack/cable_coil

/obj/item/stack/cable_coil/single
	amount = 1

/obj/item/stack/cable_coil/single/New(var/loc, var/length = 1, var/param_color = null)
	..(loc, length, param_color)

/obj/item/stack/cable_coil/cyborg
	name = "cable coil synthesizer"
	desc = "A device that makes cable."
	gender = NEUTER
	matter = null
	uses_charge = 1
	charge_costs = list(1)

/obj/item/stack/cable_coil/New(loc, length = MAXCOIL, var/param_color = null)
	..()
	src.amount = length
	if (param_color) // It should be red by default, so only recolor it if parameter was specified.
		color = param_color
	update_icon()
	update_wclass()

///////////////////////////////////
// General procedures
///////////////////////////////////

//you can use wires to heal robotics
/obj/item/stack/cable_coil/attack(var/atom/A, var/mob/living/user, var/def_zone)
	if(ishuman(A) && user.a_intent == I_HELP)
		var/mob/living/carbon/human/H = A
		var/obj/item/organ/external/S = H.organs_by_name[user.zone_sel.selecting]

		if (!S) return
		if(S.robotic < ORGAN_ROBOT || user.a_intent != I_HELP)
			return ..()

		var/use_amt = min(src.amount, ceil(S.burn_dam/3), 5)
		if(can_use(use_amt))
			if(S.robo_repair(3*use_amt, BURN, "some damaged wiring", src, user))
				src.use(use_amt)
		return
	return ..()


/obj/item/stack/cable_coil/update_icon()
	if (!color)
		color = possible_cable_coil_colours[pick(possible_cable_coil_colours)]
	if(amount == 1)
		icon_state = "coil1"
		SetName("cable piece")
	else if(amount == 2)
		icon_state = "coil2"
		SetName("cable piece")
	else
		icon_state = initial(icon_state)
		SetName(initial(name))

/obj/item/stack/cable_coil/proc/set_cable_color(var/selected_color, var/user)
	if(!selected_color)
		return

	var/final_color = possible_cable_coil_colours[selected_color]
	if(!final_color)
		selected_color = "Red"
		final_color = possible_cable_coil_colours[selected_color]
	color = final_color
	to_chat(user, "<span class='notice'>You change \the [src]'s color to [lowertext(selected_color)].</span>")

/obj/item/stack/cable_coil/proc/update_wclass()
	if(amount == 1)
		w_class = ITEM_SIZE_TINY
	else
		w_class = ITEM_SIZE_SMALL

/obj/item/stack/cable_coil/examine(mob/user)
	. = ..()
	if(get_dist(src, user) > 1)
		return

	if(get_amount() == 1)
		to_chat(user, "A short piece of power cable.")
	else if(get_amount() == 2)
		to_chat(user, "A piece of power cable.")
	else
		to_chat(user, "A coil of power cable. There are [get_amount()] lengths of cable in the coil.")


/obj/item/stack/cable_coil/verb/make_restraint()
	set name = "Make Cable Restraints"
	set category = "Object"
	var/mob/M = usr

	if(ishuman(M) && !M.incapacitated())
		if(!istype(usr.loc,/turf)) return
		if(src.amount <= 14)
			to_chat(usr, "<span class='warning'>You need at least 15 lengths to make restraints!</span>")
			return
		var/obj/item/weapon/handcuffs/cable/B = new /obj/item/weapon/handcuffs/cable(usr.loc)
		B.color = color
		to_chat(usr, "<span class='notice'>You wind some cable together to make some restraints.</span>")
		src.use(15)
	else
		to_chat(usr, "<span class='notice'>You cannot do that.</span>")

/obj/item/stack/cable_coil/cyborg/verb/set_colour()
	set name = "Change Colour"
	set category = "Object"

	var/selected_type = input("Pick new colour.", "Cable Colour", null, null) as null|anything in possible_cable_coil_colours
	set_cable_color(selected_type, usr)

// Items usable on a cable coil :
//   - Wirecutters : cut them duh !
//   - Cable coil : merge cables
/obj/item/stack/cable_coil/proc/can_merge(var/obj/item/stack/cable_coil/C)
	return color == C.color

/obj/item/stack/cable_coil/cyborg/can_merge()
	return 1

/obj/item/stack/cable_coil/transfer_to(obj/item/stack/cable_coil/S)
	if(!istype(S))
		return
	if(!can_merge(S))
		return

	..()

/obj/item/stack/cable_coil/use()
	. = ..()
	update_icon()
	return

/obj/item/stack/cable_coil/add()
	. = ..()
	update_icon()
	return

//////////////////////////////
// Misc.
/////////////////////////////

/obj/item/stack/cable_coil/cut
	item_state = "coil2"

/obj/item/stack/cable_coil/cut/New(loc)
	..()
	src.amount = rand(1,2)
	update_icon()
	update_wclass()

/obj/item/stack/cable_coil/yellow
	color = COLOR_YELLOW

/obj/item/stack/cable_coil/blue
	color = COLOR_BLUE

/obj/item/stack/cable_coil/green
	color = COLOR_LIME

/obj/item/stack/cable_coil/pink
	color = COLOR_PINK

/obj/item/stack/cable_coil/orange
	color = COLOR_ORANGE

/obj/item/stack/cable_coil/cyan
	color = COLOR_CYAN

/obj/item/stack/cable_coil/white
	color = COLOR_WHITE

/obj/item/stack/cable_coil/random/New()
	color = possible_cable_coil_colours[pick(possible_cable_coil_colours)]
	..()

GLOBAL_LIST_INIT(standing_objects, list(/obj/item/stool, /obj/structure/hygiene/toilet, /obj/structure/table, /obj/structure/bed))

/proc/is_standing_on_object(x)
	if(!x) return FALSE

	for(var/obj/O in get_turf(x))
		if(is_type_in_list(O, GLOB.standing_objects))
			return TRUE
	return FALSE

/obj/item/stack/cable_coil/verb/make_noose()
	set name = "Make Noose"
	set category = "Object"

	var/mob/living/carbon/human/H = usr
	var/turf/current_turf = get_turf(H)

	if(!ishuman(H) || !istype(current_turf, /turf))
		return

	var/turf/above = GetAbove(H)

	// Forbid to create a noose in the air
	// Also sanity check for turf in loc
	if(istype(above, /turf/simulated/open))
		to_chat(usr, "<span class='warning'>There is no ceiling above you.</span>")
		return

	if(H.restrained() || H.stat || H.paralysis || H.stunned)
		to_chat(usr, "<span class='warning'>You can't do it right now.</span>")
		return

	if(!is_standing_on_object(H))
		to_chat(usr, "<span class='warning'>You have to be standing on top of a chair, table or bed to make a noose!</span>")
		return

	if(amount <= 24)
		to_chat(H, "<span class='warning'>You need at least 25 lengths to make a noose!</span>")
		return

	if(!do_mob(H, current_turf, 3 SECONDS))
		return

	if(!H.unEquip(src))
		return

	var/obj/structure/noose/N = new /obj/structure/noose(current_turf)
	to_chat(usr, "<span class='notice'>You wind some cable together to make a noose, tying it to the ceiling.</span>")
	forceMove(N)
	N.coil = src
	N.color = color

/obj/structure/noose
	name = "noose"
	desc = "A morbid apparatus."
	icon_state = "noose"
	icon = 'icons/obj/noose.dmi'
	anchored = TRUE
	can_buckle = TRUE
	buckle_lying = FALSE
	layer = 5
	var/ticks = 0

	var/manual_triggered
	var/image/over = null
	var/obj/item/stack/cable_coil/coil
	var/area/current_area

/obj/structure/noose/attackby(obj/item/W, mob/user, params)
	if(W.edge)
		user.visible_message(\
			"<span class='notice'>[user] cuts the noose.</span>",\
			"<span class='notice'>You cut the noose.</span>")
		untie()
		return
	return ..()

/obj/structure/noose/bullet_act(obj/item/projectile/P)
	if(prob(40))
		visible_message("<span class='notice'>\The [src] gets split by \the [P]!</span>")
		untie()

/obj/structure/noose/proc/untie()
	if(buckled_mob)
		buckled_mob.visible_message(\
			"<span class='danger'>[buckled_mob] falls over and hits the ground!</span>",\
			"<span class='danger'>You fall over and hit the ground!</span>")
		buckled_mob.adjustBruteLoss(10)
	playsound(src, 'sound/items/Wirecutter.ogg', 60, 1)
	if(coil)
		coil.dropInto(loc)
		coil = null
	qdel(src)

/obj/structure/noose/Initialize()
	. = ..()
	pixel_y += 16 //Noose looks like it's "hanging" in the air
	over = image(icon, "noose_overlay")
	over.layer = BASE_HUMAN_LAYER + 0.1
	current_area = get_area(src)

/obj/structure/noose/Destroy()
	STOP_PROCESSING(SSmiscproc, src)
	QDEL_NULL(over)
	QDEL_NULL(coil)
	current_area = null
	return ..()

/obj/structure/noose/post_buckle_mob(mob/living/M)
	if(M == buckled_mob)
		layer = 3
		overlays.Add(over)
		M.pixel_y = initial(M.pixel_y) + 8
		M.dir = SOUTH
		START_PROCESSING(SSmiscproc, src)
	else
		STOP_PROCESSING(SSmiscproc, src)
		layer = initial(layer)
		overlays.Cut()
		pixel_x = initial(pixel_x)
		M.pixel_x = initial(M.pixel_x)
		M.pixel_y = initial(M.pixel_y)
		manual_triggered = FALSE

/obj/structure/noose/user_unbuckle_mob(mob/living/user)
	if(!user.IsAdvancedToolUser())
		return

	if(buckled_mob?.buckled == src)
		var/mob/living/M = buckled_mob
		if(M != user)
			user.visible_message(\
				"<span class='notice'>[user] begins to untie the noose over [M]'s neck...</span>",\
				"<span class='notice'>You begin to untie the noose over [M]'s neck...</span>")
			if(do_mob(user, M, 10 SECONDS))
				user.visible_message(\
				"<span class='notice'>[user] unties the noose over [M]'s neck!</span>",\
				"<span class='notice'>You untie the noose over [M]'s neck!</span>")
			else
				return
		else
			M.visible_message(\
				"<span class='warning'>[M] struggles to untie the noose over their neck!</span>",\
				"<span class='notice'>You struggle to untie the noose over your neck.</span>")
			if(!do_after(M, 15 SECONDS))
				if(M?.buckled)
					to_chat(M, "<span class='warning'>You fail to untie yourself!</span>")
				return
			if(!M.buckled)
				return
			M.visible_message(\
				"<span class='warning'>[M] unties the noose over their neck!</span>",\
				"<span class='notice'>You untie the noose over your neck!</span>")
			M.Weaken(3)
		unbuckle_mob()
		add_fingerprint(user)

/obj/structure/noose/proc/check_head(mob/living/carbon/human/H, mob/user)
	if(!H || !ishuman(H))
		return FALSE

	var/obj/item/organ/external/affecting = H.get_organ(BP_HEAD)
	if(!affecting || affecting.is_stump())
		if(user)
			to_chat(user, "<span class='danger'>They don't have a head.</span>")
		return FALSE
	else
		return TRUE

/obj/structure/noose/user_buckle_mob(mob/living/carbon/human/M, mob/user)
	if(!in_range(user, src) || user.stat || user.restrained() || !istype(M))
		return FALSE

	if(!user.IsAdvancedToolUser())
		return

	if(M.loc != loc)
		return FALSE //Can only noose someone if they're on the same tile as noose

	if(!check_head(M, user))
		return

	add_fingerprint(user)

	if(M == user && buckle_mob(M))
		M.visible_message(\
			"<span class='warning'>[M] ties \the [src] over their neck!</span>",\
			"<span class='warning'>You tie \the [src] over your neck!</span>")
		playsound(user.loc, 'sound/effects/noosed.ogg', 50, 1, -1)
		return 1
	else
		M.visible_message(\
			"<span class='danger'>[user] attempts to tie \the [src] over [M]'s neck!</span>",\
			"<span class='danger'>[user] ties \the [src] over your neck!</span>")
		to_chat(user, "<span class='notice'>It will take 20 seconds and you have to stand still.</span>")
		if(do_after(user, 200))
			if(buckle_mob(M))
				M.visible_message(\
					"<span class='danger'>[user] ties \the [src] over [M]'s neck!</span>",\
					"<span class='danger'>[user] ties \the [src] over your neck!</span>")
				playsound(user.loc, 'sound/effects/noosed.ogg', 50, 1, -1)
				return 1
			else
				user.visible_message(\
					"<span class='warning'>[user] fails to tie \the [src] over [M]'s neck!</span>",\
					"<span class='warning'>You fail to tie \the [src] over [M]'s neck!</span>")
				return 0
		else
			user.visible_message(\
				"<span class='warning'>[user] fails to tie \the [src] over [M]'s neck!</span>",\
				"<span class='warning'>You fail to tie \the [src] over [M]'s neck!</span>")
			return 0

/obj/structure/noose/Process()
	if(!buckled_mob || !ishuman(buckled_mob) || !check_head(buckled_mob))
		if(buckled_mob)
			unbuckle_mob()
		return PROCESS_KILL

	if((is_standing_on_object(buckled_mob) && !buckled_mob.resting) || !current_area.has_gravity)
		if(pixel_x != initial(pixel_x) || buckled_mob.pixel_x != initial(buckled_mob.pixel_x))
			pixel_x = initial(pixel_x)
			buckled_mob.pixel_x = initial(buckled_mob.pixel_x)
			manual_triggered = FALSE
		return

	if(!manual_triggered && buckled_mob.resting)
		noosed_effect(buckled_mob)

	ticks++

	switch(ticks)
		if(1)
			pixel_x -= 1
			buckled_mob.pixel_x -= 1
		if(2)
			pixel_x = initial(pixel_x)
			buckled_mob.pixel_x = initial(buckled_mob.pixel_x)
		if(3)
			pixel_x += 1
			buckled_mob.pixel_x += 1

			if(buckled_mob)
				playsound(buckled_mob, 'sound/effects/noose_idle.ogg', 50, 1, -3)
				if(ishuman(buckled_mob))
					var/mob/living/carbon/human/H = buckled_mob
					if(!H.need_breathe())
						return

				if(prob(15))
					var/flavor_text = list("<span class='warning'>[buckled_mob]'s legs flail for anything to stand on.</span>",\
											"<span class='warning'>[buckled_mob]'s hands are desperately clutching the noose.</span>",\
											"<span class='warning'>[buckled_mob]'s limbs sway back and forth with diminishing strength.</span>")
					if(buckled_mob.stat == DEAD)
						flavor_text = list("<span class='warning'>[buckled_mob]'s limbs lifelessly sway back and forth.</span>",\
											"<span class='warning'>[buckled_mob]'s eyes stare straight ahead.</span>")
					buckled_mob.visible_message(pick(flavor_text))
		if(4)
			pixel_x = initial(pixel_x)
			buckled_mob.pixel_x = initial(buckled_mob.pixel_x)
			ticks = 0

	if(ishuman(buckled_mob))
		var/mob/living/carbon/human/H = buckled_mob
		if(!H.need_breathe())
			return

		buckled_mob.adjustOxyLoss(3)
		buckled_mob.silent = max(buckled_mob.silent, 10)
		if(!(H.silent && H.stat) && prob(10))
			buckled_mob.emote("gasp")

/obj/structure/noose/proc/noosed_effect(mob/user)
	if(manual_triggered)
		return

	if(buckled_mob?.buckled == user)
		manual_triggered = TRUE

/*
	// Here's come some special actions
	for(var/obj/O in user.loc)
		// For example chairs will fold
		if(istype(O, /obj/structure/bed/chair))
			var/obj/structure/bed/chair/C = O
			C.fold()
			return
*/