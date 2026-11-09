//Redefining some robot procs, since drones can't be repaired and really shouldn't take component damage.
/mob/living/silicon/robot/drone
	gurps_damage_resistance = 2
	var/fireloss = 0
	var/bruteloss = 0

/mob/living/silicon/robot/drone/take_overall_damage(var/brute = 0, var/burn = 0, var/sharp = 0, var/used_weapon = null)
	if(!gurps_damage_applying)
		if(brute) apply_damage(brute, BRUTE, damage_flags = sharp ? DAM_SHARP : 0, used_weapon = used_weapon)
		if(burn) apply_damage(burn, BURN, used_weapon = used_weapon)
		return
	bruteloss += brute
	fireloss += burn

/mob/living/silicon/robot/drone/heal_overall_damage(var/brute, var/burn)
	if(!gurps_damage_applying)
		if(brute) gurps_adjust_body_damage(-brute)
		if(burn) gurps_adjust_body_damage(-burn, TRUE)
		return

	bruteloss -= brute
	fireloss -= burn

	if(bruteloss<0) bruteloss = 0
	if(fireloss<0) fireloss = 0

/mob/living/silicon/robot/drone/take_organ_damage(var/brute = 0, var/burn = 0, var/sharp = 0, var/emp = 0)
	take_overall_damage(brute,burn)

/mob/living/silicon/robot/drone/heal_organ_damage(var/brute, var/burn)
	heal_overall_damage(brute,burn)

/mob/living/silicon/robot/drone/getFireLoss()
	return gurps_body_damage(TRUE)

/mob/living/silicon/robot/drone/getBruteLoss()
	return gurps_body_damage()