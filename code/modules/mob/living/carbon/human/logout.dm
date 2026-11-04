/mob/living/carbon/human/Logout()
	stop_walking_animation()
	clear_walking_cache()
	clear_blind_tiles()
	..()
	if(species) species.handle_logout_special(src)
	return
