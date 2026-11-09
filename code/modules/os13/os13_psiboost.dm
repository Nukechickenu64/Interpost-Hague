// Classic uses the listed permanent Intelligence costs, with Willpower as a fallback.
/proc/os13_psi_power_costs()
	var/static/list/costs = list(
		"Psi-Armor" = 2,
		"Pain Radiation" = 2,
		"Fear Radiation" = 1,
		"Telepathic Control" = 5,
		"Psychogenic Agility" = 1,
		"Psychogenic Strength" = 1,
		"Hypnogenesis" = 1,
		"Meta-Barrier" = 1,
		"Cryptokinetic Attack" = 2,
		"Pyrokinetic Attack" = 5
	)
	return costs

/proc/os13_psi_round_powers(phi)
	var/list/choices = os13_psi_power_costs().Copy()
	var/list/selected = list()
	for(var/draw in 1 to 3)
		var/hash = hex2num(copytext(md5("[phi]:os13-psiboost:[draw]"), 1, 7))
		var/index = 1 + hash % length(choices)
		selected += choices[index]
		choices.Cut(index, index + 1)
	return selected

/obj/item/organ/internal/os13_psiboost/proc/available_powers()
	return os13_psi_round_powers(SSticker.phi)

/obj/item/organ/internal/os13_psiboost/advanced
	name = "PsiBoost Implant+"
	desc = "An advanced neural amplifier with all ten PsiBoost powers."

/obj/item/organ/internal/os13_psiboost/advanced/available_powers()
	return os13_psi_power_costs().Copy()

/datum/design/item/os13_psiboost/advanced
	name = "PsiBoost Implant+"
	id = "os13_psiboost_implant_plus"
	materials = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 1000)
	build_path = /obj/item/organ/internal/os13_psiboost/advanced
	sort_string = "VAACFA"

/mob/living/carbon/human
	var/os13_psi_armor_until = 0
	var/os13_psi_armor_fraction = 0
	var/os13_hypnogenesis_until = 0
	var/datum/os13_psi_control/os13_psi_control

/mob/living/carbon/human/proc/os13_psionic_talent()
	return clamp(max(os13_counselor ? 3 : 1, psi ? psi.rating : 0), 1, 5)

/mob/living/carbon/human/proc/os13_psi_pay(cost)
	if(stats[STAT_IQ] >= cost + 1)
		stats[STAT_IQ] -= cost
		to_chat(src, SPAN_WARNING("The power permanently costs you [cost] Intelligence."))
		return TRUE
	if(stats[STAT_WP] >= cost)
		stats[STAT_WP] -= cost
		to_chat(src, SPAN_WARNING("The power permanently costs you [cost] Willpower."))
		return TRUE
	to_chat(src, SPAN_WARNING("You lack the Intelligence or Willpower to use that power."))
	return FALSE

/mob/living/carbon/human/proc/os13_use_psiboost()
	set name = "PsiBoost Powers"
	set category = "Psionics"
	var/obj/item/organ/internal/os13_psiboost/implant = os13_psiboost()
	if(!implant || !client || os13_psi_control || !istype(GLOB.using_map, /datum/map/os13classic))
		return
	var/list/costs = os13_psi_power_costs()
	var/list/choices = list()
	for(var/power in implant.available_powers())
		choices["[power] ([costs[power]] INT/WP)"] = power
	var/choice = input(src, "Choose a power. Its cost is permanent.", "PsiBoost") as null|anything in choices
	var/power = choices[choice]
	if(!power || implant != os13_psiboost() || !client || os13_psi_control)
		return
	var/atom/target
	var/list/candidates = list()
	switch(power)
		if("Telepathic Control", "Hypnogenesis", "Cryptokinetic Attack", "Pyrokinetic Attack")
			for(var/mob/living/carbon/human/candidate in oview(5, src))
				if(os13_psi_target(candidate, power))
					candidates += candidate
			if(length(candidates))
				target = input(src, "Choose a target.", power) as null|anything in candidates
			if(!os13_psi_target(target, power))
				return
		if("Meta-Barrier")
			for(var/turf/tile in orange(1, src))
				if(os13_psi_barrier_site(tile))
					candidates += tile
			if(length(candidates))
				target = input(src, "Choose an adjacent empty tile.", power) as null|anything in candidates
			if(!os13_psi_barrier_site(target))
				return
	if(implant != os13_psiboost() || !client || os13_psi_control || disrupts_psionics())
		return
	os13_cast_psiboost(power, target)

/mob/living/carbon/human/proc/os13_psi_target(mob/living/carbon/human/target, power)
	if(!istype(target) || QDELETED(target) || target == src || target.stat == DEAD || target.isSynthetic() || !target.has_brain() || !(target in oview(5, src)) || target.disrupts_psionics())
		return FALSE
	if(power == "Telepathic Control")
		return !machine && !buckled && client?.eye == src && mind?.current == src && target.client?.eye == target && target.mind?.current == target && !target.machine && !target.buckled && !target.os13_psi_control && target.stat == CONSCIOUS && isturf(loc) && isturf(target.loc)
	return TRUE

/mob/living/carbon/human/proc/os13_psi_barrier_site(turf/tile)
	return istype(tile, /turf/simulated/floor) && !tile.density && Adjacent(tile) && !(locate(/mob/living) in tile) && !(locate(/obj/effect/os13_meta_barrier) in tile)

/mob/living/carbon/human/proc/os13_cast_psiboost(power, atom/target)
	var/obj/item/organ/internal/os13_psiboost/implant = os13_psiboost()
	if(!implant || !(power in implant.available_powers()) || os13_psi_control || disrupts_psionics() || !istype(GLOB.using_map, /datum/map/os13classic))
		return FALSE
	var/increased_stat
	if(power == "Psychogenic Agility")
		increased_stat = STAT_DX
	else if(power == "Psychogenic Strength")
		increased_stat = STAT_ST
	if(increased_stat && stats[increased_stat] >= 20)
		to_chat(src, SPAN_WARNING("You have already reached the limit of that enhancement."))
		return FALSE
	if(power == "Psi-Armor" && os13_psi_armor_until > world.time)
		return FALSE
	var/mob/living/carbon/human/victim = target
	if((power in list("Telepathic Control", "Hypnogenesis", "Cryptokinetic Attack", "Pyrokinetic Attack")) && !os13_psi_target(victim, power))
		return FALSE
	if(power == "Meta-Barrier" && !os13_psi_barrier_site(target))
		return FALSE
	var/talent = os13_psionic_talent()
	var/list/costs = os13_psi_power_costs()
	if(!os13_psi_pay(costs[power]))
		return FALSE
	switch(power)
		if("Psi-Armor")
			os13_psi_armor_fraction = 0.35 + 0.07 * talent
			os13_psi_armor_until = world.time + (8 + 4 * talent) SECONDS
			to_chat(src, SPAN_NOTICE("A layer of imagined armor settles around you."))
		if("Pain Radiation", "Fear Radiation")
			for(var/mob/living/carbon/human/other in oview(5, src))
				if(!os13_psi_target(other, power))
					continue
				if(power == "Pain Radiation")
					other.adjustHalLoss(8 + 4 * talent)
					other.Weaken(1 + talent + (other.happiness < MOOD_LEVEL_SAD1 ? 2 : 0))
					to_chat(other, SPAN_DANGER("A wave of psionic pain makes your muscles seize."))
				else
					other.confused = max(other.confused, 2 + talent)
					if(other.canmove && !other.buckled)
						step_away(other, src, 6)
					to_chat(other, SPAN_DANGER("Panic overwhelms you."))
		if("Telepathic Control")
			new /datum/os13_psi_control(src, victim, implant, (4 + 2 * talent) SECONDS)
		if("Psychogenic Agility", "Psychogenic Strength")
			stats[increased_stat]++
			to_chat(src, SPAN_NOTICE("You permanently enhance your [increased_stat == STAT_DX ? "agility" : "strength"]."))
		if("Hypnogenesis")
			victim.os13_hypnogenesis_until = max(victim.os13_hypnogenesis_until, world.time + (4 + 2 * talent) SECONDS)
			to_chat(victim, SPAN_DANGER("Your limbs grow heavy. You cannot jump or crawl."))
		if("Meta-Barrier")
			var/obj/effect/os13_meta_barrier/barrier = new(target)
			barrier.talent = talent
			QDEL_IN(barrier, (8 + 4 * talent) SECONDS)
		if("Cryptokinetic Attack")
			if(victim.bodytemperature > 170)
				victim.bodytemperature = max(170, victim.bodytemperature - 20 - 10 * talent)
			victim.Stun(1 + talent)
			to_chat(victim, SPAN_DANGER("An intense cold locks up your muscles."))
		if("Pyrokinetic Attack")
			victim.adjust_fire_stacks(2 + talent)
			victim.IgniteMob()
	return TRUE

/obj/effect/os13_meta_barrier
	name = "psionic barrier"
	desc = "A translucent wall held together by a psionic impulse."
	icon = 'icons/os13/objects/objects/newcyber.dmi'
	icon_state = "nwall"
	alpha = 170
	density = TRUE
	anchored = TRUE
	var/talent = 1

/obj/effect/os13_meta_barrier/CanPass(atom/movable/mover, turf/target, height, air_group)
	var/mob/living/carbon/human/person = mover
	if(istype(person) && person.os13_psionic_talent() >= talent)
		return TRUE
	return ..()

/mob/observer/os13_psi_displaced
	name = "displaced mind"
	ghost_image_flag = GHOST_IMAGE_NONE
	canmove = FALSE
	see_invisible = 0
	sight = SEE_SELF
	var/datum/os13_psi_control/control

/mob/observer/os13_psi_displaced/Move()
	return FALSE

/datum/os13_psi_control
	var/mob/living/carbon/human/caster
	var/mob/living/carbon/human/victim
	var/datum/mind/caster_mind
	var/datum/mind/victim_mind
	var/mob/observer/os13_psi_displaced/displaced
	var/obj/item/organ/internal/os13_psiboost/implant
	var/ends_at
	var/ending = FALSE

/datum/os13_psi_control/New(mob/living/carbon/human/source, mob/living/carbon/human/target, obj/item/organ/internal/os13_psiboost/device, duration)
	..()
	caster = source
	victim = target
	caster_mind = caster.mind
	victim_mind = victim.mind
	implant = device
	ends_at = world.time + duration
	caster.os13_psi_control = src
	victim.os13_psi_control = src
	displaced = new(get_turf(victim))
	displaced.control = src
	displaced.mind = victim_mind
	displaced.key = victim.key
	displaced.reset_view(victim)
	to_chat(displaced, SPAN_DANGER("A foreign mind takes control of your body."))
	caster_mind.transfer_to(victim)
	victim_mind.current = displaced
	to_chat(victim, SPAN_NOTICE("You control [victim.real_name] for a short time."))
	START_PROCESSING(SSobj, src)

/datum/os13_psi_control/Process()
	if(world.time >= ends_at || QDELETED(caster) || QDELETED(victim) || QDELETED(implant) || QDELETED(displaced) || caster.stat == DEAD || victim.stat == DEAD || implant.owner != caster || !implant.is_usable() || caster_mind.current != victim || victim_mind.current != displaced || !victim.client || !displaced.client)
		finish()

/datum/os13_psi_control/proc/finish()
	if(ending)
		return
	ending = TRUE
	STOP_PROCESSING(SSobj, src)
	if(!QDELETED(caster))
		caster.os13_psi_control = null
	if(!QDELETED(victim))
		victim.os13_psi_control = null
	if(!caster_mind.current || caster_mind.current == victim)
		return_mind(caster_mind, caster)
	if(!victim_mind.current || victim_mind.current == displaced)
		return_mind(victim_mind, victim)
	QDEL_NULL(displaced)
	qdel(src)

/datum/os13_psi_control/proc/return_mind(datum/mind/person, mob/living/carbon/human/body)
	if(!QDELETED(body) && (!body.mind || body.mind == person))
		person.active = TRUE
		person.transfer_to(body)
		to_chat(body, SPAN_NOTICE("Your mind returns to your body."))
		return
	if(person.current == victim && !QDELETED(victim) && victim.mind == person)
		victim.mind = null
	var/mob/observer/ghost/ghost = new(displaced)
	ghost.mind = person
	ghost.can_reenter_corpse = FALSE
	person.current = ghost
	ghost.key = person.key
