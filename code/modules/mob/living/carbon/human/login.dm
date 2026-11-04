/mob/living/carbon/human/Login()
	..()
	if(leech_starving && !QDELETED(leech_witness))
		leech_witness.key = key
		return
	update_hud()
	if(species) species.handle_login_special(src)
	updatePig()
	if(GAME_STATE == RUNLEVEL_GAME && SSticker.mode && SSticker.mode.os13_loyal_sheets_ready)
		os13_send_loyal_crew_sheet(src)
	return