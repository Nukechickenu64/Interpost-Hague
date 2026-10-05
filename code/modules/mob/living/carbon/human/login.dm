/mob/living/carbon/human/Login()
	..()
	if(leech_starving && !QDELETED(leech_witness))
		leech_witness.key = key
		return
	update_hud()
	if(species) species.handle_login_special(src)
	updatePig()
	return