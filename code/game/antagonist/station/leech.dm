/datum/antagonist/afflicted
	id = "leech"
	role_text = "Leech"
	role_text_plural = "Leeches"
	feedback_tag = "leech_objective"
	protected_jobs = list(/datum/job/captain, /datum/job/hos, /datum/job/cmo)
	blacklisted_jobs = list(/datum/job/ai)
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE
	hard_cap = 2
	hard_cap_round = 2
	initial_spawn_req = 1
	initial_spawn_target = 1
	antaghud_indicator = "hudtraitor"
	welcome_text = "Your marrow has failed. Fresh human blood is all that keeps your organs alive. You have no supernatural gifts, only an increasingly desperate hunger."

/datum/antagonist/afflicted/create_objectives(var/datum/mind/leech_mind)
	if(!..())
		return

	var/datum/objective/leech/blood_volume/blood_volume_objective = new
	blood_volume_objective.owner = leech_mind
	leech_mind.objectives += blood_volume_objective

	var/datum/objective/leech/blood_stockpile/blood_stockpile_objective = new
	blood_stockpile_objective.owner = leech_mind
	leech_mind.objectives += blood_stockpile_objective

	var/datum/objective/leech/undiagnosed/undiagnosed_objective = new
	undiagnosed_objective.owner = leech_mind
	leech_mind.objectives += undiagnosed_objective

	var/datum/objective/escape/escape_objective = new
	escape_objective.owner = leech_mind
	leech_mind.objectives += escape_objective

/datum/mind
	var/leech_diagnosed = FALSE
	var/leech_conversion_pending = FALSE

/datum/mind/proc/is_leech()
	return special_role == "Leech"

/mob/living/carbon/human/proc/handle_leech_decay()
	if(!mind?.is_leech() || stat == DEAD || !vessel)
		return
	remove_blood(1)
	var/blood_volume = get_blood_volume()
	if(blood_volume <= 0)
		to_chat(src, "<span class='danger'>Your empty heart gives one final, useless beat.</span>")
		death()
		return
	if(blood_volume <= 25)
		pale = 1
		adjustStaminaLoss(5)
		adjustToxLoss(3)
		if(internal_organs.len)
			var/obj/item/organ/internal/organ = pick(internal_organs)
			organ.take_internal_damage(1)
		if(prob(15))
			if(l_hand)
				drop_l_hand()
			else if(r_hand)
				drop_r_hand()
		to_chat(src, "<span class='danger'>Your limbs are failing. You need blood immediately.</span>")
	else if(blood_volume <= 50)
		pale = 1
		adjustStaminaLoss(3)
		eye_blurry = max(eye_blurry, 3)
		apply_effect(2, STUTTER)
		if(prob(10))
			emote(pick("groan", "cough"))
	else if(blood_volume <= 75)
		pale = 1
		adjustStaminaLoss(2)
		make_jittery(3)
	else
		pale = 0

/mob/living/carbon/human/proc/leech_drain_bite(mob/living/carbon/human/victim, target_zone)
	if(!mind?.is_leech() || !victim || victim.stat == DEAD || !victim.lying)
		return FALSE
	if(victim.run_armor_check(target_zone, "melee") > 0)
		to_chat(src, "<span class='warning'>You cannot reach blood through [victim]'s armor.</span>")
		return FALSE
	visible_message("<span class='warning'>[src] presses their mouth against [victim]'s [victim.get_organ(target_zone).name].</span>")
	if(!do_after(src, 10, victim, progress = 0))
		return FALSE
	if(!Adjacent(victim) || victim.stat == DEAD || !victim.lying)
		return FALSE
	var/amount = min(20, victim.vessel.get_reagent_amount(/datum/reagent/blood), species.blood_volume - vessel.total_volume)
	if(amount <= 0)
		to_chat(src, "<span class='warning'>There is no fresh blood left to draw.</span>")
		return FALSE
	victim.vessel.trans_to_holder(vessel, amount)
	victim.apply_damage(1, BRUTE, target_zone, victim.run_armor_check(target_zone, "melee"), 0, "bite")
	if(target_zone == BP_HEAD)
		var/obj/item/organ/external/target_organ = victim.get_organ(target_zone)
		if(target_organ)
			target_organ.sever_artery()
	victim.receive_damage()
	adjustHalLoss(-10)
	visible_message("<span class='danger'>[src] buries their teeth in [victim] and begins to drink!</span>")
	playsound(get_turf(src), 'sound/weapons/bite.ogg', 50, 1, -1)
	admin_attack_log(src, victim, "Drained blood from their victim.", "Had their blood drained.", "drained blood from")
	if(victim.vessel.get_reagent_amount(/datum/reagent/blood) <= 0)
		victim.death()
		leech_schedule_conversion(victim)
	return TRUE

/mob/living/carbon/human/proc/leech_schedule_conversion(mob/living/carbon/human/victim)
	if(!victim?.mind || victim.mind.leech_conversion_pending)
		return
	victim.mind.leech_conversion_pending = TRUE
	spawn(600)
		if(!victim || victim.stat != DEAD || !victim.mind)
			return
		victim.revive()
		GLOB.leech_antagonist.add_antagonist(victim.mind, 1, 0, 0, 1)
		to_chat(victim, "<span class='danger'><font size=3>Your pulse returns, but your marrow is dead. You are a Leech.</font></span>")

/datum/objective/leech/blood_volume
	explanation_text = "Maintain a blood volume above 80% when the escape shuttle arrives."

/datum/objective/leech/blood_volume/check_completion()
	return owner?.current && ishuman(owner.current) && owner.current:get_blood_volume() > 80

/datum/objective/leech/blood_stockpile
	explanation_text = "Secure at least 500 units of fresh human blood in IV bags or cryogenic containers to bring off-station."

/datum/objective/leech/blood_stockpile/check_completion()
	if(!owner?.current)
		return FALSE
	var/blood_total = 0
	for(var/obj/item/weapon/reagent_containers/ivbag/bag in owner.current.get_contents())
		blood_total += bag.reagents.get_reagent_amount(/datum/reagent/blood)
	return blood_total >= 500

/datum/objective/leech/undiagnosed
	explanation_text = "Survive the shift without Medbay diagnosing your hematopoietic failure."

/datum/objective/leech/undiagnosed/check_completion()
	return owner && !owner.leech_diagnosed

GLOBAL_DATUM_INIT(leech_antagonist, /datum/antagonist/afflicted, new)