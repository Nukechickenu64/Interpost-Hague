/mob/living/silicon/ai
	gurps_damage_resistance = 6
	var/fireloss = 0
	var/bruteloss = 0
	var/oxyloss = 0

/mob/living/silicon/ai/getFireLoss()
	return gurps_body_damage(TRUE)

/mob/living/silicon/ai/getBruteLoss()
	return gurps_body_damage()

/mob/living/silicon/ai/getOxyLoss()
	return oxyloss

/mob/living/silicon/ai/adjustFireLoss(var/amount)
	if(status_flags & GODMODE) return
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount, TRUE)
	fireloss = gurps_body_damage(TRUE)

/mob/living/silicon/ai/adjustBruteLoss(var/amount)
	if(status_flags & GODMODE) return
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount)
	bruteloss = gurps_body_damage()

/mob/living/silicon/ai/adjustOxyLoss(var/amount)
	if(status_flags & GODMODE) return
	oxyloss = max(0, oxyloss + min(amount / gurps_legacy_health_scale, maxHealth - oxyloss))

/mob/living/silicon/ai/setFireLoss(var/amount)
	if(status_flags & GODMODE)
		fireloss = 0
		return
	initialize_gurps_anatomy()
	adjustFireLoss(amount - getFireLoss() * gurps_legacy_health_scale)

/mob/living/silicon/ai/setOxyLoss(var/amount)
	if(status_flags & GODMODE)
		oxyloss = 0
		return
	oxyloss = max(0, amount / gurps_legacy_health_scale)

/mob/living/silicon/ai/updatehealth()
	if(status_flags & GODMODE)
		health = maxHealth
		set_stat(CONSCIOUS)
		setOxyLoss(0)
	else
		gurps_updatehealth()

/mob/living/silicon/ai/rejuvenate()
	..()
	add_ai_verbs(src)

// Returns percentage of AI's remaining backup capacitor charge (maxhealth - oxyloss).
/mob/living/silicon/ai/proc/backup_capacitor()
	return ((getOxyLoss() - maxHealth) / maxHealth) * (-100)

// Returns percentage of AI's remaining hardware integrity (maxhealth - (bruteloss + fireloss))
/mob/living/silicon/ai/proc/hardware_integrity()
	return (health / maxHealth) * 100