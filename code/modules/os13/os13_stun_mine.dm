// The named catalogue establishes a single-use stunning mine. Contact range,
// timings, strength and artwork are local reconstruction choices documented in
// docs/os13_stun_mine_parity.md, not measured original constants.
/obj/item/device/os13_stun_mine
	name = "\improper Stun Mine"
	desc = "A single-use contact stun mine. Deploy it from your hand, or arm it on the floor. An empty-hand interaction disarms an active mine."
	icon = 'icons/os13/objects/objects/weapons/grenade.dmi'
	icon_state = "mine"
	item_state = "mine"
	item_icons = list(slot_l_hand_str = 'icons/os13/objects/objects/weapons/grenade.dmi', slot_r_hand_str = 'icons/os13/objects/objects/weapons/grenade.dmi')
	w_class = ITEM_SIZE_SMALL
	randpixel = FALSE
	matter = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500)
	var/armed = FALSE
	var/spent = FALSE
	var/busy = FALSE
	var/operation_id = 0
	var/turf/armed_turf
	var/armed_by
	var/operation_time = 3 SECONDS

/obj/item/device/os13_stun_mine/update_icon()
	icon_state = armed ? "mine1" : "mine"
	update_held_icon()

/obj/item/device/os13_stun_mine/proc/can_operate(mob/user)
	if(QDELETED(src) || !isliving(user) || user.incapacitated() || user.restrained() || !user.IsAdvancedToolUser() || !user.can_use_hands() || issilicon(user) || !Adjacent(user))
		return FALSE
	if(ishuman(user))
		var/mob/living/carbon/human/human = user
		var/obj/item/organ/external/left = human.get_organ(BP_L_HAND)
		var/obj/item/organ/external/right = human.get_organ(BP_R_HAND)
		return (!human.l_hand && left && left.is_usable()) || (!human.r_hand && right && right.is_usable())
	return !user.get_active_hand() || !user.get_inactive_hand()

/obj/item/device/os13_stun_mine/proc/valid_floor()
	return isturf(loc) && !istype(loc, /turf/space) && !istype(loc, /turf/simulated/open) && !loc.density

/obj/item/device/os13_stun_mine/attack_self(mob/user)
	if(spent || armed || busy || !can_operate(user) || loc != user || (user.get_active_hand() != src && user.get_inactive_hand() != src))
		return FALSE
	var/turf/site = get_turf(user)
	if(!site || istype(site, /turf/space) || istype(site, /turf/simulated/open) || site.density || !user.unEquip(src, target = site))
		return FALSE
	return arm(user)

/obj/item/device/os13_stun_mine/verb/arm_on_floor()
	set name = "Arm Stun Mine"
	set category = "Object"
	set src in oview(1)
	arm(usr)

/obj/item/device/os13_stun_mine/proc/arm(mob/user)
	if(spent || armed || busy || !can_operate(user) || !valid_floor())
		return FALSE
	// Do not arm underneath another person already occupying the contact tile.
	for(var/mob/living/occupant in loc)
		if(occupant != user && occupant.stat != DEAD)
			return FALSE
	busy = TRUE
	anchored = TRUE
	armed_turf = loc
	var/token = ++operation_id
	to_chat(user, "<span class='notice'>You begin arming \the [src].</span>")
	var/completed = do_after(user, operation_time, src)
	if(QDELETED(src) || token != operation_id)
		return FALSE
	busy = FALSE
	anchored = FALSE
	if(!completed || !can_operate(user) || loc != armed_turf || !valid_floor())
		armed_turf = null
		return FALSE
	for(var/mob/living/occupant in loc)
		if(occupant != user && occupant.stat != DEAD)
			armed_turf = null
			return FALSE
	armed = TRUE
	anchored = TRUE
	armed_by = key_name(user)
	update_icon()
	to_chat(user, "<span class='warning'>\The [src] is armed. Stepping on it will discharge it.</span>")
	return TRUE

/obj/item/device/os13_stun_mine/attack_hand(mob/user)
	if(busy)
		return
	if(armed)
		return disarm(user)
	return ..()

/obj/item/device/os13_stun_mine/proc/disarm(mob/user)
	if(!armed || spent || busy || !can_operate(user) || loc != armed_turf || !valid_floor())
		return FALSE
	busy = TRUE
	var/token = ++operation_id
	to_chat(user, "<span class='notice'>You begin disarming \the [src].</span>")
	var/completed = do_after(user, operation_time, src)
	if(QDELETED(src) || token != operation_id)
		return FALSE
	busy = FALSE
	if(!completed || !can_operate(user) || !armed || spent || loc != armed_turf || !valid_floor())
		return FALSE
	armed = FALSE
	anchored = FALSE
	armed_turf = null
	armed_by = null
	update_icon()
	to_chat(user, "<span class='notice'>You disarm \the [src].</span>")
	return TRUE

/obj/item/device/os13_stun_mine/Crossed(atom/movable/mover)
	. = ..()
	if(!armed || spent || loc != armed_turf || !valid_floor() || !isliving(mover))
		return
	var/mob/living/victim = mover
	if(victim.loc != loc || victim.stat == DEAD || !has_gravity(victim) || victim.is_floating || victim.buckled || victim.throwing)
		return
	// Commit the one discharge before effects. A pending disarm cannot restore it.
	armed = FALSE
	spent = TRUE
	busy = FALSE
	operation_id++
	anchored = FALSE
	armed_turf = null
	name = "spent Stun Mine"
	desc = "The discharged casing of a single-use stun mine. It cannot be rearmed."
	update_icon()
	visible_message("<span class='danger'>\The [victim] triggers \the [src]!</span>")
	log_attack("[key_name(victim)] triggered a Stun Mine armed by [armed_by] at [x],[y],[z].")
	playsound(src, 'sound/weapons/Taser.ogg', 50, TRUE)
	victim.stun_effect_act(3, 40, BP_L_FOOT, src)

/obj/item/device/os13_stun_mine/proc/check_relocation()
	if((armed || busy) && loc != armed_turf)
		operation_id++
		armed = FALSE
		busy = FALSE
		anchored = FALSE
		armed_turf = null
		armed_by = null
		update_icon()

/obj/item/device/os13_stun_mine/forceMove(atom/destination)
	. = ..()
	check_relocation()

/obj/item/device/os13_stun_mine/Move(...)
	. = ..()
	check_relocation()

/datum/design/item/os13_stun_mine
	name = "Stun Mine"
	id = "os13_stun_mine"
	req_tech = list(TECH_COMBAT = 2, TECH_MAGNET = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500)
	build_path = /obj/item/device/os13_stun_mine
	sort_string = "VAAWU"
