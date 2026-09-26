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
	welcome_text = "You died, but the blood in your veins drags you onward. Your heart is silent, your lungs still, and pain is a distant memory. Fresh human blood is the only thing that keeps your dead flesh moving."

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

/datum/antagonist/afflicted/create_antagonist(var/datum/mind/target, var/move, var/gag_announcement, var/preserve_appearance)
	. = ..()
	if(. && istype(target.current, /mob/living/carbon/human))
		var/mob/living/carbon/human/leech = target.current
		leech.leech_fangs_extended = FALSE
		leech.verbs += /mob/living/carbon/human/proc/toggle_leech_fangs
		leech.verbs += /mob/living/carbon/human/proc/leech_mesmerize

/datum/antagonist/afflicted/remove_antagonist(var/datum/mind/player, var/show_message, var/implanted)
	. = ..()
	if(. && istype(player.current, /mob/living/carbon/human))
		var/mob/living/carbon/human/leech = player.current
		leech.verbs -= /mob/living/carbon/human/proc/toggle_leech_fangs
		leech.verbs -= /mob/living/carbon/human/proc/leech_mesmerize
		leech.leech_fangs_extended = FALSE

/datum/mind
	var/leech_diagnosed = FALSE
	var/leech_conversion_pending = FALSE

/datum/mind/proc/is_leech()
	return special_role == "Leech"

/mob/living/carbon/human/proc/is_leech()
	return mind?.is_leech()

/mob/living/carbon/human
	var/leech_fangs_extended = FALSE
	var/leech_last_light_damage = 0
	var/leech_lure_cooldown = 0
	// TODO: Add a fang sprite or overlay to the human appearance update when art is available.

/mob/living/carbon/human/proc/toggle_leech_fangs()
	set name = "Extend / Retract Fangs"
	set desc = "Extend or conceal your fangs. Retracted fangs cannot inflict a feeding bite."
	set category = "IC"

	if(!is_leech() || incapacitated())
		return
	leech_fangs_extended = !leech_fangs_extended
	to_chat(src, "<span class='notice'>You [leech_fangs_extended ? "bare" : "retract"] your fangs.</span>")

/mob/living/carbon/human/proc/can_use_leech_fangs()
	return is_leech() && leech_fangs_extended

/mob/living/carbon/human/proc/leech_mesmerize(mob/living/carbon/human/target in oview(3))
	set name = "Mesmerizing Gaze"
	set desc = "Try to draw someone's attention and compel them to take one step closer."
	set category = "IC"

	if(!is_leech() || incapacitated() || world.time < leech_lure_cooldown)
		return
	if(!target || target == src || target.stat != CONSCIOUS || target.incapacitated())
		to_chat(src, "<span class='warning'>They are not in a state to meet your gaze.</span>")
		return
	leech_lure_cooldown = world.time + 300
	visible_message("<span class='warning'>[src] fixes [target] with an unnervingly steady gaze.</span>")
	if(prob(35))
		to_chat(target, "<span class='notice'>You shake off [src]'s unsettling gaze.</span>")
		return
	step_towards(target, src)
	to_chat(target, "<span class='warning'>For a moment, you feel compelled to move closer to [src].</span>")

/mob/living/carbon/human/proc/handle_leech_decay()
	if(!mind?.is_leech() || stat == DEAD || !vessel)
		return
	var/obj/structure/closet/coffin/refuge = loc
	if(!(istype(refuge) && (resting || lying)))
		remove_blood(1)
	var/blood_volume = get_blood_volume()
	if(blood_volume <= 0)
		to_chat(src, "<span class='danger'>The last blood leaves your veins. Your dead body finally goes still.</span>")
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

/mob/living/carbon/human/proc/handle_leech_light_exposure(var/damage = 1)
	if(!is_leech() || stat == DEAD || world.time < leech_last_light_damage + 20)
		return
	leech_last_light_damage = world.time
	apply_damage(damage, BURN, BP_CHEST, 0, 0, "intense light")
	visible_message("<span class='danger'>[src]'s skin blisters under the harsh light!</span>")

/mob/living/carbon/human/proc/leech_drain_bite(mob/living/carbon/human/victim, target_zone)
	if(!is_leech() || !leech_fangs_extended)
		to_chat(src, "<span class='warning'>Your fangs must be extended to bite and draw blood.</span>")
		return FALSE
	if(!victim || victim.stat == DEAD || !victim.lying)
		return FALSE
	if(victim.run_armor_check(target_zone, "melee") > 0)
		to_chat(src, "<span class='warning'>You cannot reach blood through [victim]'s armor.</span>")
		return FALSE
	var/obj/item/organ/external/target_organ = victim.get_organ(target_zone)
	visible_message("<span class='warning'>[src] presses their mouth against [victim]'s [target_organ.name].</span>")
	if(!do_after(src, 10, victim, progress = 0))
		return FALSE
	if(!Adjacent(victim) || victim.stat == DEAD || !victim.lying)
		return FALSE
	var/amount = min(20, victim.vessel.get_reagent_amount(/datum/reagent/blood), species.blood_volume - vessel.total_volume)
	if(amount <= 0)
		to_chat(src, "<span class='warning'>There is no fresh blood left to draw.</span>")
		return FALSE
	victim.vessel.trans_to_holder(vessel, amount)
	victim.apply_damage(3, BRUTE, target_zone, victim.run_armor_check(target_zone, "melee"), 0, "fangs")
	if(target_zone == BP_HEAD)
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
	var/datum/mind/pending_mind = victim.mind
	pending_mind.leech_conversion_pending = TRUE
	spawn(600)
		if(!victim || victim.mind != pending_mind || victim.stat != DEAD || pending_mind.is_leech())
			pending_mind.leech_conversion_pending = FALSE
			return
		if(!victim.revive() || !GLOB.leech_antagonist.add_antagonist(pending_mind, 1, 0, 0, 1))
			pending_mind.leech_conversion_pending = FALSE
			return
		pending_mind.leech_conversion_pending = FALSE
		to_chat(victim, "<span class='danger'><font size=3>Your dead body stirs. The hunger for blood is yours now. You are a Leech.</font></span>")

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