/client/var/inquisitive_ghost = 1
/mob/observer/ghost/verb/toggle_inquisition() // warning: unexpected inquisition
	set name = "Toggle Inquisitiveness"
	set desc = "Sets whether your ghost examines everything on click by default"
	set category = "Ghost"
	if(!client) return
	client.inquisitive_ghost = !client.inquisitive_ghost
	if(client.inquisitive_ghost)
		to_chat(src, "<span class='notice'>You will now examine everything you click on.</span>")
	else
		to_chat(src, "<span class='notice'>You will no longer examine things you click on.</span>")

/mob/observer/ghost/DblClickOn(var/atom/A, var/params)
	if(pain_possession_object)
		return
	if(istype(A, /mob/living/carbon/human))
		var/mob/living/carbon/human/clone = A
		if(clone.clone_claimable)
			if(!MayRespawn(1))
				return
			if(clone.stat == DEAD || clone.key || clone.mind)
				to_chat(src, "<span class='warning'>That clone is already inhabited or unavailable.</span>")
				return
			clone.clone_claimable = FALSE
			announce_ghost_joinleave(src, 0, "They have inhabited a freshly grown clone.")
			clone.ckey = ckey
			to_chat(clone, "<span class='notice'>You awaken in a newly grown body. Your genetic origins are unfamiliar.</span>")
			return
	if(can_reenter_corpse && mind && mind.current)
		if(A == mind.current || (mind.current in A)) // double click your corpse or whatever holds it
			reenter_corpse()						// (cloning scanner, body bag, closet, mech, etc)
			return
	if(!client || !client.holder)
		return

	// Things you might plausibly want to follow
	if(istype(A,/atom/movable))
		ManualFollow(A)
	// Otherwise jump
	else
		stop_following()
		forceMove(get_turf(A))

/mob/observer/ghost/ClickOn(var/atom/A, var/params)
	if(!canClick()) return
	setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	if(pain_possession_object)
		examinate(A)
		return

	// You are responsible for checking config.ghost_interaction when you override this function
	// Not all of them require checking, see below
	var/list/modifiers = params2list(params)
	if(modifiers["alt"])
		var/target_turf = get_turf(A)
		if(target_turf)
			AltClickOn(target_turf)
	else
		A.attack_ghost(src)

// Oh by the way this didn't work with old click code which is why clicking shit didn't spam you
/atom/proc/attack_ghost(mob/observer/ghost/user as mob)
	if(!istype(user))
		return
	if(user.client && user.client.inquisitive_ghost)
		user.examinate(src)
	return

// ---------------------------------------
// And here are some good things for free:
// Now you can click through portals, wormholes, gateways, and teleporters while observing. -Sayu

/obj/machinery/teleport/hub/attack_ghost(mob/user as mob)
	if(get_dist(user, src) > 1)
		return
	var/atom/l = loc
	var/obj/machinery/computer/teleporter/com = locate(/obj/machinery/computer/teleporter, locate(l.x - 2, l.y, l.z))
	if(com && com.locked)
		user.forceMove(get_turf(com.locked))

/obj/effect/portal/attack_ghost(mob/user as mob)
	if(get_dist(user, src) > 1)
		return
	if(target)
		user.forceMove(get_turf(target))

/obj/machinery/gateway/centerstation/attack_ghost(mob/user as mob)
	if(get_dist(user, src) > 1)
		return
	if(active && hell_arrival_turf)
		user.forceMove(hell_arrival_turf)
	else
		to_chat(user, "[src] has no destination.")

// -------------------------------------------
// This was supposed to be used by adminghosts
// I think it is a *terrible* idea
// but I'm leaving it here anyway
// commented out, of course.
/*
/atom/proc/attack_admin(mob/user as mob)
	if(!user || !user.client || !user.client.holder)
		return
	attack_hand(user)

*/
