/mob/living/silicon/decoy/Life()
	if (src.stat == 2)
		return
	else
		gurps_health_status()


/mob/living/silicon/decoy/updatehealth()
	gurps_updatehealth()
