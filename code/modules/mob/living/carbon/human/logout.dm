/mob/living/carbon/human/Logout()
	clear_blind_tiles()
	..()
	if(species) species.handle_logout_special(src)
	return