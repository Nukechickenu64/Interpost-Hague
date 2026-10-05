/datum/grab/normal/aggressive
	state_name = NORM_AGGRESSIVE

	upgrab_name = NORM_NECK
	downgrab_name = NORM_PASSIVE

	shift = 12


	stop_move = 1
	reverse_facing = 0
	can_absorb = 0
	shield_assailant = 0
	point_blank_mult = 1
	same_tile = 0
	can_throw = 1
	force_danger = 1
	breakability = 3

	icon_state = "grabbed1"

	break_chance_table = list(5, 20, 40, 80, 100)
/datum/grab/normal/aggressive/process_effect(var/obj/item/grab/G)
	var/mob/living/carbon/human/affecting = G.affecting

	// Keeps those who are on the ground down
	if(affecting.lying)
		affecting.Weaken(4)

/datum/grab/normal/aggressive/downgrade_effect(var/obj/item/grab/G)
	if(G.force_down)
		to_chat(G.assailant, "<span class='warning'>You are no longer pinning [G.affecting] to the ground.</span>")
		G.force_down = FALSE

/datum/grab/normal/aggressive/can_upgrade(var/obj/item/grab/G)
	if(!G.allow_upgrade)
		return FALSE
	if(isslime(G.affecting))
		to_chat(G.assailant, "<span class='notice'>You squeeze [G.affecting], but nothing interesting happens.</span>")
		return FALSE
	return TRUE