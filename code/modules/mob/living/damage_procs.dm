/datum/gurps_bodypart
	var/zone
	var/name
	var/brute = 0
	var/burn = 0
	var/crippled = FALSE
	var/severed = FALSE

/mob/living
	var/list/gurps_bodyparts
	var/gurps_damage_resistance = 0
	var/gurps_damage_applying = FALSE
	var/gurps_legacy_health_scale = 1
	var/gurps_max_hp = null
	var/gurps_anatomy_profile = "limbed"
	var/gurps_death_check_level = 0
	var/gurps_health_check_until = 0
	var/gurps_mechanical = FALSE

/mob/living/proc/has_gurps_anatomy()
	return istype(src, /mob/living/simple_animal) || issilicon(src) || istype(src, /mob/living/bot)

/mob/living/proc/gurps_is_machine()
	return gurps_mechanical || issilicon(src) || istype(src, /mob/living/bot)

/mob/living/proc/initialize_gurps_anatomy()
	if(!has_gurps_anatomy() || gurps_bodyparts)
		return
	if(istype(src, /mob/living/simple_animal/spiderbot) || istype(src, /mob/living/simple_animal/hostile/droid) || istype(src, /mob/living/simple_animal/hostile/hivebot) || istype(src, /mob/living/simple_animal/hostile/retaliate/malf_drone) || istype(src, /mob/living/simple_animal/hostile/viscerator) || istype(src, /mob/living/simple_animal/head))
		gurps_mechanical = TRUE
		if(!gurps_damage_resistance)
			gurps_damage_resistance = 2
	if(istype(src, /mob/living/simple_animal/slime) || istype(src, /mob/living/simple_animal/hostile/mimic))
		gurps_anatomy_profile = "amorphous"
	else if(istype(src, /mob/living/simple_animal/space_worm) || istype(src, /mob/living/simple_animal/head))
		gurps_anatomy_profile = "core"
	else if(istype(src, /mob/living/simple_animal/hostile/carp))
		gurps_anatomy_profile = "finned"
	var/old_max_health = max(1, maxHealth)
	var/health_fraction = health / old_max_health
	if(issilicon(src) && stat != DEAD)
		health_fraction = 1
	maxHealth = isnull(gurps_max_hp) ? max(1, round(old_max_health / 10)) : max(1, gurps_max_hp)
	gurps_legacy_health_scale = old_max_health / maxHealth
	health = maxHealth * health_fraction
	gurps_bodyparts = list()
	var/list/zones = list(BP_CHEST, BP_GROIN, BP_HEAD, BP_EYES, BP_L_ARM, BP_R_ARM, BP_L_HAND, BP_R_HAND, BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT)
	if(gurps_anatomy_profile == "core" || istype(src, /mob/living/silicon/ai))
		zones = list(BP_CHEST, BP_HEAD, BP_EYES)
	else if(gurps_anatomy_profile == "amorphous")
		zones = list(BP_CHEST)
	else if(gurps_anatomy_profile == "finned")
		zones = list(BP_CHEST, BP_HEAD, BP_EYES, BP_L_ARM, BP_R_ARM)
	for(var/zone in zones)
		var/datum/gurps_bodypart/part = new
		part.zone = zone
		part.name = combat_location_name(zone)
		if(gurps_anatomy_profile == "finned" && (zone == BP_L_ARM || zone == BP_R_ARM))
			part.name = zone == BP_L_ARM ? "left fin" : "right fin"
		else if(gurps_is_machine() && zone == BP_HEAD)
			part.name = "processor"
		else if(gurps_is_machine() && zone == BP_EYES)
			part.name = "optical sensors"
		gurps_bodyparts[zone] = part
	if(health_fraction < 1)
		var/datum/gurps_bodypart/torso = gurps_bodyparts[BP_CHEST]
		torso.brute = max(0, maxHealth - health)

/mob/living/proc/gurps_body_damage(var/burning = FALSE)
	var/total = 0
	if(gurps_bodyparts)
		for(var/zone in gurps_bodyparts)
			var/datum/gurps_bodypart/part = gurps_bodyparts[zone]
			total += burning ? part.burn : part.brute
	return total

/mob/living/proc/gurps_updatehealth()
	initialize_gurps_anatomy()
	if(status_flags & GODMODE)
		health = maxHealth
	else
		health = maxHealth - gurps_body_damage() - gurps_body_damage(TRUE)

/mob/living/proc/gurps_adjust_body_damage(var/amount, var/burning = FALSE)
	initialize_gurps_anatomy()
	if(status_flags & GODMODE || !amount)
		return 0
	amount /= gurps_legacy_health_scale
	if(amount > 0)
		return gurps_receive_damage(amount, burning ? BURN : BRUTE, BP_CHEST, ignore_armor = TRUE)
	gurps_heal_bodyparts(-amount, burning)
	gurps_damage_applying = TRUE
	if(burning)
		adjustFireLoss(amount)
	else
		adjustBruteLoss(amount)
	gurps_damage_applying = FALSE
	gurps_updatehealth()
	gurps_death_check_level = min(gurps_death_check_level, max(0, round(-health / maxHealth)))
	return 1

/mob/living/proc/gurps_limb_usable(var/zone)
	if(!gurps_bodyparts || !(zone in gurps_bodyparts))
		return TRUE
	var/datum/gurps_bodypart/part = gurps_bodyparts[zone]
	return !part.crippled && !part.severed

/mob/living/proc/gurps_mobile()
	return (gurps_limb_usable(BP_L_LEG) && gurps_limb_usable(BP_L_FOOT)) || (gurps_limb_usable(BP_R_LEG) && gurps_limb_usable(BP_R_FOOT))

/mob/living/proc/gurps_manipulator_usable()
	return (gurps_limb_usable(BP_L_ARM) && gurps_limb_usable(BP_L_HAND)) || (gurps_limb_usable(BP_R_ARM) && gurps_limb_usable(BP_R_HAND))

/mob/living/proc/gurps_health_status()
	if(status_flags & GODMODE || stat == DEAD)
		return
	if(!gurps_limb_usable(BP_EYES))
		eye_blind = max(eye_blind, 2)
	if(health > 0 && stat == UNCONSCIOUS && !paralysis && !stunned && !weakened && !sleeping)
		set_stat(CONSCIOUS)
	if(health <= -5 * maxHealth)
		death()
		return
	var/death_level = max(0, round(-health / maxHealth))
	while(gurps_death_check_level < death_level)
		gurps_death_check_level++
		var/list/survival = gurps_roll(gurps_stat(STAT_HT))
		if(!survival["success"])
			death()
			return
	if(health <= 0 && world.time >= gurps_health_check_until)
		gurps_health_check_until = world.time + 10
		var/list/consciousness = gurps_roll(gurps_stat(STAT_HT))
		if(!consciousness["success"])
			Paralyse(2)
			set_stat(UNCONSCIOUS)
		else if(!paralysis && !stunned && !weakened && !sleeping)
			set_stat(CONSCIOUS)

/mob/living/proc/gurps_absorb_injury(var/injury)
	return injury

/mob/living/proc/gurps_bodypart_for(var/zone)
	initialize_gurps_anatomy()
	if(!gurps_bodyparts)
		return null
	if(zone in list(BP_FACE, BP_MOUTH, BP_THROAT))
		zone = BP_HEAD
	if(zone == BP_VITALS)
		zone = BP_CHEST
	return gurps_bodyparts[zone] || gurps_bodyparts[BP_CHEST]

/mob/living/proc/gurps_heal_bodyparts(var/amount, var/burning = FALSE)
	if(amount <= 0 || !gurps_bodyparts)
		return
	for(var/zone in gurps_bodyparts)
		var/datum/gurps_bodypart/part = gurps_bodyparts[zone]
		var/healed = min(amount, burning ? part.burn : part.brute)
		if(burning)
			part.burn -= healed
		else
			part.brute -= healed
		amount -= healed
		if(gurps_is_machine() && !part.brute && !part.burn)
			part.severed = FALSE
		var/threshold = maxHealth / ((zone in list(BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT)) ? 3 : (zone == BP_EYES ? 10 : 2))
		if(!part.severed && part.brute + part.burn <= threshold)
			part.crippled = FALSE
		if(amount <= 0)
			break

/mob/living/proc/gurps_receive_damage(var/damage, var/damagetype, var/zone, var/blocked = 0, var/damage_flags = 0, var/used_weapon = null, var/ignore_armor = FALSE)
	if(status_flags & GODMODE || blocked >= 100)
		return 0
	var/datum/gurps_bodypart/part = gurps_bodypart_for(zone)
	if(!part)
		return 0
	var/injury = max(0, damage * blocked_mult(blocked) - (ignore_armor ? 0 : gurps_damage_resistance))
	if(!ignore_armor)
		injury = gurps_absorb_injury(injury)
	if(injury <= 0)
		return 0
	if(!gurps_is_machine() && damagetype == BRUTE)
		if(damage_flags & DAM_EDGE)
			injury *= 1.5
		else if(damage_flags & DAM_SHARP)
			injury *= 2
		if(zone == BP_HEAD)
			injury *= 4
		else if(zone == BP_VITALS && (damage_flags & DAM_SHARP))
			injury *= 1.5
	injury = max(0.1, round(injury, 0.1))
	if(damagetype == BURN)
		part.burn += injury
	else
		part.brute += injury
	var/extremity = part.zone in list(BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT)
	var/limb = extremity || (part.zone in list(BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG))
	if(limb && part.brute + part.burn > maxHealth / (extremity ? 3 : 2))
		if(!part.crippled)
			visible_message(SPAN_DANGER("[src]'s [part.name] is crippled!"))
		part.crippled = TRUE
		if((damage_flags & DAM_EDGE) && injury > maxHealth)
			part.severed = TRUE
		if(part.zone in list(BP_L_ARM, BP_L_HAND))
			if(l_hand) drop_from_inventory(l_hand)
		else if(part.zone in list(BP_R_ARM, BP_R_HAND))
			if(r_hand) drop_from_inventory(r_hand)
	if(part.zone == BP_EYES && part.brute + part.burn > maxHealth / 10)
		part.crippled = TRUE
		eye_blind = max(eye_blind, 2)
	gurps_damage_applying = TRUE
	if(damagetype == BURN)
		adjustFireLoss(injury)
	else
		adjustBruteLoss(injury)
	gurps_damage_applying = FALSE
	if(injury > maxHealth / 2)
		var/list/resist = gurps_roll(gurps_stat(STAT_HT))
		if(!resist["success"])
			Stun(2)
			Weaken(2)
	gurps_updatehealth()
	gurps_health_status()
	return 1

/mob/living/examine(mob/user)
	. = ..()
	if(!has_gurps_anatomy() || !user)
		return
	initialize_gurps_anatomy()
	to_chat(user, SPAN_NOTICE("HP: [round(health, 0.1)] / [maxHealth]; DR: [gurps_damage_resistance]."))
	for(var/zone in gurps_bodyparts)
		var/datum/gurps_bodypart/part = gurps_bodyparts[zone]
		if(part.severed)
			to_chat(user, SPAN_WARNING("[capitalize(part.name)] is missing."))
		else if(part.brute || part.burn)
			to_chat(user, SPAN_WARNING("[capitalize(part.name)]: [round(part.brute + part.burn, 0.1)] injury[part.crippled ? " (crippled)" : ""]."))

/mob/living/silicon/adjustBruteLoss(var/amount)
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount)

/mob/living/silicon/adjustFireLoss(var/amount)
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount, TRUE)

/mob/living/silicon/getBruteLoss()
	return gurps_body_damage()

/mob/living/silicon/getFireLoss()
	return gurps_body_damage(TRUE)

/mob/living/silicon/updatehealth()
	gurps_updatehealth()

/mob/living/bot/adjustBruteLoss(var/amount)
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount)

/mob/living/bot/adjustFireLoss(var/amount)
	if(!gurps_damage_applying)
		return gurps_adjust_body_damage(amount, TRUE)

/mob/living/bot/getBruteLoss()
	return gurps_body_damage()

/mob/living/bot/getFireLoss()
	return gurps_body_damage(TRUE)

/*
	apply_damage() args
	damage - How much damage to take
	damage_type - What type of damage to take, brute, burn
	def_zone - Where to take the damage if its brute or burn

	Returns
	standard 0 if fail
*/
/mob/living/proc/apply_damage(var/damage = 0,var/damagetype = BRUTE, var/def_zone = null, var/blocked = 0, var/damage_flags = 0, var/used_weapon = null)
	if(!damage || (blocked >= 100))	return 0
	if(has_gurps_anatomy() && damage > 0 && (damagetype == BRUTE || damagetype == BURN))
		initialize_gurps_anatomy()
		return gurps_receive_damage(damage / gurps_legacy_health_scale, damagetype, def_zone, blocked, damage_flags, used_weapon)
	switch(damagetype)
		if(BRUTE)
			adjustBruteLoss(damage * blocked_mult(blocked))
		if(BURN)
			if(COLD_RESISTANCE in mutations)	damage = 0
			adjustFireLoss(damage * blocked_mult(blocked))
		if(TOX)
			adjustToxLoss(damage * blocked_mult(blocked))
		if(OXY)
			adjustOxyLoss(damage * blocked_mult(blocked))
		if(CLONE)
			adjustCloneLoss(damage * blocked_mult(blocked))
		if(PAIN)
			adjustHalLoss(damage * blocked_mult(blocked))
		if(ELECTROCUTE)
			electrocute_act(damage, used_weapon, 1.0, def_zone)

	updatehealth()
	return 1


/mob/living/proc/apply_damages(var/brute = 0, var/burn = 0, var/tox = 0, var/oxy = 0, var/clone = 0, var/halloss = 0, var/def_zone = null, var/blocked = 0, var/damage_flags = 0)
	if(blocked >= 100)	return 0
	if(brute)	apply_damage(brute, BRUTE, def_zone, blocked)
	if(burn)	apply_damage(burn, BURN, def_zone, blocked)
	if(tox)		apply_damage(tox, TOX, def_zone, blocked)
	if(oxy)		apply_damage(oxy, OXY, def_zone, blocked)
	if(clone)	apply_damage(clone, CLONE, def_zone, blocked)
	if(halloss) apply_damage(halloss, PAIN, def_zone, blocked)
	return 1


/mob/living/proc/apply_effect(var/effect = 0,var/effecttype = STUN, var/blocked = 0)
	if(!effect || (blocked >= 100))	return 0

	switch(effecttype)
		if(STUN)
			Stun(effect * blocked_mult(blocked))
		if(WEAKEN)
			Weaken(effect * blocked_mult(blocked))
		if(PARALYZE)
			Paralyse(effect * blocked_mult(blocked))
		if(PAIN)
			adjustHalLoss(effect * blocked_mult(blocked))
		if(IRRADIATE)
			radiation += effect * blocked_mult(blocked)
		if(STUTTER)
			if(status_flags & CANSTUN) // stun is usually associated with stutter - TODO CANSTUTTER flag?
				stuttering = max(stuttering, effect * blocked_mult(blocked))
		if(EYE_BLUR)
			eye_blurry = max(eye_blurry, effect * blocked_mult(blocked))
		if(DROWSY)
			drowsyness = max(drowsyness, effect * blocked_mult(blocked))
	updatehealth()
	return 1


/mob/living/proc/apply_effects(var/stun = 0, var/weaken = 0, var/paralyze = 0, var/irradiate = 0, var/stutter = 0, var/eyeblur = 0, var/drowsy = 0, var/agony = 0, var/blocked = 0)
	if(blocked >= 2)	return 0
	if(stun)		apply_effect(stun,      STUN, blocked)
	if(weaken)		apply_effect(weaken,    WEAKEN, blocked)
	if(paralyze)	apply_effect(paralyze,  PARALYZE, blocked)
	if(irradiate)	apply_effect(irradiate, IRRADIATE, blocked)
	if(stutter)		apply_effect(stutter,   STUTTER, blocked)
	if(eyeblur)		apply_effect(eyeblur,   EYE_BLUR, blocked)
	if(drowsy)		apply_effect(drowsy,    DROWSY, blocked)
	if(agony)		apply_effect(agony,     PAIN, blocked)
	return 1
