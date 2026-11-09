/mob/living/carbon/human/Logout()
	var/datum/os13_cryo_intro/intro = my_client?.os13_cryo_intro
	if(intro?.joiner == src)
		qdel(intro)
	stop_walking_animation()
	clear_walking_cache()
	clear_blind_tiles()
	..()
	if(species) species.handle_logout_special(src)
	return
