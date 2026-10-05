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
	antaghud_indicator = "huddead"
	porco_actions = list(
		list("ToggleLeechFangs", "Extend / Retract Fangs"),
		list("LeechMesmerize", "Mesmerizing Gaze"),
		list("leech_blood_strength", "Blood Strength (50 blood)"),
		list("leech_fortitude", "Fortitude (50 blood)"),
		list("leech_celerity", "Celerity (250 blood)"),
		list("leech_heal", "Heal (150 blood)"),
		list("leech_dead_eyes", "Dead Eyes")
	)
	welcome_text = "You died, but the blood in your veins drags you onward. Your heart is silent, your lungs still, and pain is a distant memory. Fresh human blood sustains you and fuels your disciplines: Blood Strength, Fortitude, Celerity, and healing. Dead Eyes reveals spirits and pierces darkness. Fire, silver, and intense light are your enemies."

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
		leech.clear_leech_powers()
		leech.stats[STAT_IQ] += 5
		leech.leech_stat_bonuses[STAT_IQ] = 5
		leech.leech_fangs_extended = FALSE
		leech.leech_last_meal = world.time
		leech.leech_last_hunger_update = world.time
		leech.leech_meal_blood = 0
		leech.verbs += /mob/living/carbon/human/proc/toggle_leech_fangs
		leech.verbs += /mob/living/carbon/human/proc/leech_mesmerize
		leech.verbs += /mob/living/carbon/human/proc/leech_blood_strength
		leech.verbs += /mob/living/carbon/human/proc/leech_fortitude
		leech.verbs += /mob/living/carbon/human/proc/leech_celerity
		leech.verbs += /mob/living/carbon/human/proc/leech_heal
		leech.verbs += /mob/living/carbon/human/proc/leech_dead_eyes
		leech.handle_happiness()
		leech.update_stamina_hud()

/datum/antagonist/afflicted/remove_antagonist(var/datum/mind/player, var/show_message, var/implanted)
	. = ..()
	if(. && istype(player.current, /mob/living/carbon/human))
		var/mob/living/carbon/human/leech = player.current
		leech.verbs -= /mob/living/carbon/human/proc/toggle_leech_fangs
		leech.verbs -= /mob/living/carbon/human/proc/leech_mesmerize
		leech.verbs -= /mob/living/carbon/human/proc/leech_blood_strength
		leech.verbs -= /mob/living/carbon/human/proc/leech_fortitude
		leech.verbs -= /mob/living/carbon/human/proc/leech_celerity
		leech.verbs -= /mob/living/carbon/human/proc/leech_heal
		leech.verbs -= /mob/living/carbon/human/proc/leech_dead_eyes
		leech.clear_leech_powers()
		leech.leech_fangs_extended = FALSE
		leech.update_happiness()
		leech.handle_happiness()
		leech.update_stamina_hud()

/datum/mind
	var/leech_diagnosed = FALSE
	var/leech_conversion_pending = FALSE

/datum/mind/proc/is_leech()
	return special_role == GLOB.leech_antagonist.role_text

/mob/living/carbon/human/proc/is_leech()
	return mind?.is_leech()

/mob/living/carbon/human/ssd_check()
	if(leech_starving)
		return FALSE
	return ..()

/mob/living/carbon/human/get_client()
	if(leech_starving && leech_witness)
		return leech_witness.client
	return ..()

/mob/living/carbon/human/show_message(msg, type, alt, alt_type)
	if(leech_starving && leech_witness?.client)
		return leech_witness.show_message(msg, type, alt, alt_type)
	return ..()

/mob/living/carbon/human/adjustStaminaLoss(var/amount, var/passive = FALSE)
	if(is_leech())
		staminaloss = 0
		return
	..()

/mob/living/carbon/human/setStaminaLoss(var/amount)
	if(is_leech())
		staminaloss = 0
		return
	..()

/mob/living/carbon/human/update_stamina_hud()
	if(nutrition_icon)
		nutrition_icon.name = is_leech() ? "blood hunger and thirst" : "nutrition"
		if(is_leech())
			nutrition_icon.icon_state = leech_is_hungry() ? "hunger2" : "hunger0"
	if(is_leech())
		update_happiness()
	if(!stamina_icon)
		return
	if(!is_leech())
		stamina_icon.name = "stamina"
		stamina_icon.color = null
		return ..()
	var/blood_percentage = get_blood_volume()
	stamina_icon.name = "blood ([blood_percentage]%)"
	stamina_icon.cut_overlays()
	stamina_icon.icon_state = "v[Clamp(round(blood_percentage * 12 / 100), 0, 12)]"
	stamina_icon.color = null

/mob/living/carbon/human
	var/leech_fangs_extended = FALSE
	var/leech_last_light_damage = 0
	var/leech_lure_cooldown = 0
	var/list/leech_stat_bonuses = list()
	var/list/leech_power_expiry = list()
	var/leech_power_generation = 0
	var/leech_dead_eyes_active = FALSE
	var/leech_fire_fear_cooldown = 0
	var/leech_last_meal = 0
	var/leech_last_hunger_update = 0
	var/leech_meal_blood = 0
	var/leech_starving = FALSE
	var/leech_starvation_deadline = 0
	var/datum/leech_starvation_ai/leech_starvation_ai
	var/mob/observer/virtual/mob/leech_starvation/leech_witness
	// TODO: Add a fang sprite or overlay to the human appearance update when art is available.

/mob/living/carbon/human/proc/clear_leech_powers()
	stop_leech_starvation()
	leech_power_generation++
	for(var/stat_name in leech_stat_bonuses)
		stats[stat_name] -= leech_stat_bonuses[stat_name]
	leech_stat_bonuses.Cut()
	leech_power_expiry.Cut()
	leech_dead_eyes_active = FALSE
	handle_vision()

/mob/living/carbon/human/proc/leech_spend_blood(amount)
	if(!is_leech() || incapacitated() || !vessel)
		return FALSE
	if(vessel.get_reagent_amount(/datum/reagent/blood) <= amount)
		to_chat(src, "<span class='warning'>You need more than [amount] units of blood.</span>")
		return FALSE
	vessel.remove_reagent(/datum/reagent/blood, amount)
	update_stamina_hud()
	return TRUE

/mob/living/carbon/human/proc/leech_stat_power(stat_name, bonus, cost, duration, maximum = 0, refresh = TRUE)
	if(!is_leech() || incapacitated())
		return FALSE
	if(!refresh && leech_stat_bonuses[stat_name])
		to_chat(src, "<span class='warning'>That discipline is already active.</span>")
		return FALSE
	var/old_bonus = leech_stat_bonuses[stat_name]
	if(!isnum(old_bonus))
		old_bonus = 0
	var/base_stat = stats[stat_name] - old_bonus
	if(maximum)
		bonus = min(bonus, maximum - base_stat)
	if(bonus <= 0)
		to_chat(src, "<span class='warning'>Your [uppertext(stat_name)] cannot be increased further.</span>")
		return FALSE
	if(!leech_spend_blood(cost))
		return FALSE
	stats[stat_name] += bonus - old_bonus
	leech_stat_bonuses[stat_name] = bonus
	var/expires_at = world.time + duration
	var/generation = leech_power_generation
	leech_power_expiry[stat_name] = expires_at
	spawn(duration)
		if(!QDELETED(src) && generation == leech_power_generation && leech_power_expiry[stat_name] == expires_at)
			stats[stat_name] -= leech_stat_bonuses[stat_name]
			leech_stat_bonuses -= stat_name
			leech_power_expiry -= stat_name
	return TRUE

/mob/living/carbon/human/proc/leech_blood_strength()
	set name = "Blood Strength"
	set desc = "Spend 50 blood for +5 ST for two minutes, up to 30 ST. Reuse refreshes the duration."
	set category = "IC"
	if(leech_stat_power(STAT_ST, 5, 50, 1200, 30))
		to_chat(src, "<span class='notice'>Blood floods your muscles with unnatural strength.</span>")

/mob/living/carbon/human/proc/leech_fortitude()
	set name = "Fortitude"
	set desc = "Spend 50 blood for +4 HT for two minutes, up to 30 HT. Reuse refreshes the duration."
	set category = "IC"
	if(leech_stat_power(STAT_HT, 4, 50, 1200, 30))
		to_chat(src, "<span class='notice'>Your dead flesh hardens with stolen vitality.</span>")

/mob/living/carbon/human/proc/leech_celerity()
	set name = "Celerity"
	set desc = "Spend 250 blood for +6 DX and supernatural speed for ninety seconds."
	set category = "IC"
	if(leech_stat_power(STAT_DX, 6, 250, 900, refresh = FALSE))
		to_chat(src, "<span class='notice'>The world seems to slow around you.</span>")

/mob/living/carbon/human/proc/leech_heal()
	set name = "Heal"
	set desc = "Spend 150 blood to restore your dead flesh without replenishing your blood."
	set category = "IC"
	if(!leech_spend_blood(150))
		return
	dizziness = 0
	rejuvenate(preserve_blood = TRUE)
	to_chat(src, "<span class='notice'>Your wounds close as stolen blood repairs your body.</span>")

/mob/living/carbon/human/proc/leech_dead_eyes()
	set name = "Dead Eyes"
	set desc = "Toggle the ability to see spirits and see in the dark."
	set category = "IC"
	if(!is_leech() || incapacitated())
		return
	leech_dead_eyes_active = !leech_dead_eyes_active
	handle_vision()
	to_chat(src, "<span class='notice'>Your sight [leech_dead_eyes_active ? "opens to the world of the dead" : "returns to normal"].</span>")

/mob/living/carbon/human/proc/toggle_leech_fangs()
	set name = "Extend / Retract Fangs"
	set desc = "Extend or conceal your fangs. Retracted fangs cannot inflict a feeding bite."
	set category = "IC"

	if(!is_leech() || incapacitated())
		return
	leech_fangs_extended = !leech_fangs_extended
	to_chat(src, "<span class='notice'>You [leech_fangs_extended ? "bare" : "retract"] your fangs.</span>")

/client/verb/toggle_leech_fangs_ui()
	set name = "ToggleLeechFangs"
	set hidden = 1

	if(ishuman(mob))
		var/mob/living/carbon/human/leech = mob
		leech.toggle_leech_fangs()

/client/verb/leech_mesmerize_ui()
	set name = "LeechMesmerize"
	set hidden = 1

	if(ishuman(mob))
		var/mob/living/carbon/human/leech = mob
		var/mob/living/carbon/human/target = input(leech, "Choose a target", "Mesmerizing Gaze") as null|mob in oview(3)
		if(target)
			leech.leech_mesmerize(target)

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
	staminaloss = 0
	fatigue = 0
	set_nutrition(450)
	set_thirst(THIRST_LEVEL_FILLED)
	leech_touch_silver(l_hand)
	leech_touch_silver(r_hand)
	handle_leech_fire_fear()
	var/obj/structure/closet/coffin/refuge = loc
	var/hunger_elapsed = max(0, world.time - leech_last_hunger_update)
	leech_last_hunger_update = world.time
	if(istype(refuge) && (resting || lying) && !leech_starving)
		leech_last_meal += hunger_elapsed
	update_stamina_hud()
	var/blood_volume = get_blood_volume()
	if(blood_volume <= 0)
		to_chat(src, "<span class='danger'>The last blood leaves your veins. Your dead body finally goes still.</span>")
		death()
		return
	pale = leech_is_hungry()
	if(!leech_starving && world.time >= leech_last_meal + 30 MINUTES)
		start_leech_starvation()

/mob/living/carbon/human/proc/leech_is_hungry()
	return is_leech() && (leech_starving || world.time >= leech_last_meal + 15 MINUTES)

/mob/living/carbon/human/proc/leech_digest_blood(amount)
	leech_meal_blood += amount
	if(leech_meal_blood >= 200)
		leech_meal_blood = 0
		leech_last_meal = world.time
		if(leech_starving)
			stop_leech_starvation()
			to_chat(src, "<span class='notice'>Your hunger recedes. Your body is yours again.</span>")
	update_stamina_hud()

/mob/living/carbon/human/proc/start_leech_starvation()
	if(leech_starving || !is_leech() || stat == DEAD)
		return
	leech_starving = TRUE
	leech_starvation_deadline = world.time + 1 MINUTE
	leech_meal_blood = 0
	leech_starvation_ai = new(src)
	visible_message("<span class='danger'>[src]'s expression twists into a feral hunger!</span>")
	to_chat(leech_witness ? leech_witness : src, "<span class='danger'>Starvation takes your body. You can only watch through its eyes. It must drink 200 blood within one minute, or you will die.</span>")
	update_stamina_hud()

/mob/living/carbon/human/proc/stop_leech_starvation()
	leech_starving = FALSE
	leech_starvation_deadline = 0
	QDEL_NULL(leech_starvation_ai)
	QDEL_NULL(leech_witness)

/mob/observer/virtual/mob/leech_starvation
	name = "captive consciousness"
	alpha = 0
	ghost_image_flag = GHOST_IMAGE_NONE
	anchored = TRUE
	var/allow_departure = FALSE

/mob/observer/virtual/mob/leech_starvation/uses_side_ui()
	return TRUE

/mob/observer/virtual/mob/leech_starvation/get_client()
	return client

/mob/observer/virtual/mob/leech_starvation/is_blind()
	var/mob/living/carbon/human/body = host
	return !body || body.is_blind()

/mob/observer/virtual/mob/leech_starvation/is_deaf()
	var/mob/living/carbon/human/body = host
	return !body || body.is_deaf()

/mob/observer/virtual/mob/leech_starvation/Login()
	..()
	if(host)
		sync_sight(host)
		client.eye = host
		client.perspective = EYE_PERSPECTIVE
		var/mob/living/carbon/human/body = host
		for(var/obj/screen/meter in list(body.stamina_icon, body.nutrition_icon, body.happiness_icon, body.healths))
			client.screen |= meter

/mob/observer/virtual/mob/leech_starvation/Move()
	return FALSE

/mob/observer/virtual/mob/leech_starvation/ClickOn(atom/target, params, mob/user, client/player_client)
	return

/mob/observer/virtual/mob/leech_starvation/ghostize(can_reenter_corpse = CORPSE_CAN_REENTER)
	if(allow_departure)
		return ..()

/mob/observer/virtual/mob/leech_starvation/Destroy()
	var/mob/living/carbon/human/body = host
	if(key)
		if(!QDELETED(host))
			body.key = key
		else if(client)
			mind = body?.mind
			allow_departure = TRUE
			ghostize(FALSE)
	return ..()

/datum/leech_starvation_ai
	var/mob/living/carbon/human/owner
	var/datum/humanized_mover/mover
	var/mob/living/carbon/human/target
	var/list/unreachable_targets = list()
	var/next_bite = 0
	var/saved_attack_intent
	var/saved_combat_intent
	var/saved_combat_mode
	var/saved_fangs
	var/saved_resting
	var/saved_eye_closed

/datum/leech_starvation_ai/New(mob/living/carbon/human/body)
	..()
	owner = body
	saved_attack_intent = owner.a_intent
	saved_combat_intent = owner.c_intent
	saved_combat_mode = owner.combat_mode
	saved_fangs = owner.leech_fangs_extended
	saved_resting = owner.resting
	saved_eye_closed = owner.eye_closed
	owner.a_intent = I_HURT
	owner.c_intent = I_QUICK
	owner.combat_mode = TRUE
	owner.leech_fangs_extended = TRUE
	owner.leech_witness = new(get_turf(owner), owner)
	owner.leech_witness.real_name = owner.real_name
	if(owner.key)
		owner.leech_witness.key = owner.key
	mover = new(owner)
	mover.in_combat = TRUE
	START_PROCESSING(SSobj, src)

/datum/leech_starvation_ai/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(mover)
	if(!QDELETED(owner))
		var/obj/item/grab/mouth/hold = owner.wear_mask
		if(istype(hold))
			qdel(hold)
		owner.a_intent = saved_attack_intent
		owner.c_intent = saved_combat_intent
		owner.combat_mode = saved_combat_mode
		owner.leech_fangs_extended = saved_fangs
		owner.SetResting(saved_resting)
		owner.eye_closed = saved_eye_closed
		QDEL_NULL(owner.leech_witness)
	owner = null
	target = null
	unreachable_targets = null
	return ..()

/datum/leech_starvation_ai/proc/feeding_zone(mob/living/carbon/human/victim)
	for(var/zone in list(BP_CHEST, BP_HEAD, BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG))
		var/obj/item/organ/external/organ = victim.get_organ(zone)
		if(organ && !organ.is_stump() && organ.robotic < ORGAN_ROBOT && victim.run_armor_check(zone, "melee") < 100)
			return zone
	return null

/datum/leech_starvation_ai/proc/valid_target(mob/living/carbon/human/victim)
	return !QDELETED(victim) && victim != owner && !victim.is_leech() && victim.z == owner.z && victim.vessel?.get_reagent_amount(/datum/reagent/blood) > 0 && feeding_zone(victim)

/datum/leech_starvation_ai/Process()
	if(QDELETED(owner) || owner.stat == DEAD || !owner.is_leech() || !owner.leech_starving)
		if(!QDELETED(owner))
			owner.stop_leech_starvation()
		return PROCESS_KILL
	if(world.time >= owner.leech_starvation_deadline)
		var/mob/living/carbon/human/body = owner
		body.stop_leech_starvation()
		to_chat(body, "<span class='danger'>Your body fails to satisfy its hunger and goes still.</span>")
		body.death()
		return PROCESS_KILL
	owner.handle_vision()
	if(owner.client && owner.leech_witness)
		owner.leech_witness.key = owner.key
	if(owner.leech_witness?.client)
		owner.leech_witness.client.eye = owner
		owner.leech_witness.client.update_cull_mask(TRUE)
		owner.leech_witness.set_fullscreen(owner.eye_closed || owner.eye_blind, "blind", /obj/screen/fullscreen/blind)
		owner.leech_witness.set_fullscreen(owner.stat == UNCONSCIOUS, "blackout", /obj/screen/fullscreen/blackout)
	if(owner.incapacitated())
		return
	if(owner.resting && !mover.crawling)
		owner.SetResting(FALSE)
	owner.eye_closed = FALSE
	if(!valid_target(target) || get_dist(owner, target) > 15)
		var/obj/item/grab/mouth/old_hold = owner.wear_mask
		if(istype(old_hold))
			qdel(old_hold)
		target = null
		for(var/mob/living/carbon/human/candidate in view(7, owner))
			if(unreachable_targets[candidate] > world.time)
				continue
			if(valid_target(candidate) && (!target || get_dist(owner, candidate) < get_dist(owner, target)))
				target = candidate
	if(!target)
		if(!mover.goal)
			var/list/destinations = list()
			for(var/turf/simulated/floor/destination in view(7, owner))
				if(!destination.density)
					destinations += destination
			if(destinations.len)
				mover.set_goal(pick(destinations))
		mover.tick()
		return
	if(!owner.Adjacent(target))
		mover.set_goal(get_turf(target), 1)
		if(!mover.try_tick())
			unreachable_targets[target] = world.time + 100
			target = null
		return
	mover.clear()
	if(world.time < next_bite)
		return
	next_bite = world.time + 10
	var/obj/item/grab/mouth/hold = owner.wear_mask
	if(istype(hold) && hold.affecting == target)
		hold.bite_down()
		return
	if(owner.wear_mask)
		owner.drop_from_inventory(owner.wear_mask)
	for(var/obj/item/clothing/cover in list(owner.head, owner.wear_suit))
		if((cover.body_parts_covered & FACE) && (cover.item_flags & ITEM_FLAG_THICKMATERIAL))
			owner.drop_from_inventory(cover)
	var/zone = feeding_zone(target)
	if(!zone)
		return
	hold = new(owner, target, zone)
	if(!hold.pre_check() || !hold.can_grab() || !hold.bite_down(TRUE))
		qdel(hold)
		return
	hold.init()

/mob/living/carbon/human/proc/leech_touch_silver(obj/item/item)
	if(!is_leech() || gloves || !item || (l_hand != item && r_hand != item))
		return FALSE
	var/material/item_material = item.get_material()
	if(item_material?.name != "silver" && !(item.matter && item.matter["silver"]) && !istype(item, /obj/item/coin/silver))
		return FALSE
	var/hand_zone = l_hand == item ? BP_L_HAND : BP_R_HAND
	drop_from_inventory(item)
	apply_damage(rand(5, 10), BRUTE, hand_zone, 0, 0, "silver contact")
	visible_message("<span class='danger'>[src] recoils from [item], their hand blistering!</span>")
	to_chat(src, "<span class='danger'>The silver sears your dead flesh!</span>")
	return TRUE

/mob/living/carbon/human/proc/handle_leech_fire_fear()
	if(world.time < leech_fire_fear_cooldown)
		return
	var/near_fire = on_fire
	for(var/obj/fire/fire in view(1, src))
		if(fire.firelevel > 0)
			near_fire = TRUE
			break
	if(!near_fire)
		return
	leech_fire_fear_cooldown = world.time + 100
	make_jittery(10)
	dizziness = max(dizziness, 10)
	to_chat(src, "<span class='danger'>The flames fill you with an instinctive terror!</span>")

/mob/living/carbon/human/proc/handle_leech_light_exposure(var/damage = 1)
	if(!is_leech() || stat == DEAD || world.time < leech_last_light_damage + 20)
		return
	leech_last_light_damage = world.time
	apply_damage(damage, BURN, BP_CHEST, 0, 0, "intense light")
	visible_message("<span class='danger'>[src]'s skin blisters under the harsh light!</span>")

/mob/living/carbon/human/proc/leech_drain_bite(mob/living/carbon/human/victim, target_zone)
	if(!can_use_leech_fangs())
		to_chat(src, "<span class='warning'>Your fangs must be extended to bite and draw blood.</span>")
		return FALSE
	if(incapacitated() || !victim || victim == src || !Adjacent(victim) || !check_has_mouth() || check_mouth_coverage())
		return FALSE
	var/bite_zone = target_zone == BP_THROAT ? BP_CHEST : target_zone
	if(victim.run_armor_check(bite_zone, "melee") >= 100)
		to_chat(src, "<span class='warning'>You cannot reach blood through [victim]'s armor.</span>")
		return FALSE
	var/obj/item/organ/external/target_organ = victim.get_organ(bite_zone)
	if(!target_organ || target_organ.is_stump())
		return FALSE
	var/amount = leech_siphon_blood(victim, 40)
	if(amount <= 0)
		to_chat(src, "<span class='warning'>There is no blood left to draw.</span>")
		return FALSE
	if(victim.stat != DEAD)
		victim.druggy += 200
		victim.add_event("leech_feeding", /datum/happiness_event/leech_feeding)
		victim.Stun(10)
	adjustHalLoss(-10)
	visible_message("<span class='danger'>[src] drinks [victim]'s blood through their embedded fangs!</span>")
	playsound(get_turf(src), 'sound/weapons/bite.ogg', 50, 1, -1)
	admin_attack_log(src, victim, "Drained [amount] units of blood from their victim.", "Had [amount] units of blood drained.", "drained blood from")
	return TRUE

/mob/living/carbon/human/proc/leech_siphon_blood(mob/living/carbon/human/victim, amount)
	if(!is_leech() || !victim?.vessel || victim == src || !vessel || amount <= 0)
		return 0
	var/blood_available = victim.vessel.get_reagent_amount(/datum/reagent/blood)
	var/blood_consumed = min(amount, blood_available)
	if(blood_consumed <= 0)
		return 0
	var/blood_to_store = max(0, min(blood_consumed, species.blood_volume - vessel.total_volume, vessel.get_free_space()))
	if(blood_to_store > 0)
		vessel.add_reagent(/datum/reagent/blood, blood_to_store, victim.vessel.get_data(/datum/reagent/blood), safety = TRUE)
	victim.vessel.remove_reagent(/datum/reagent/blood, blood_consumed)
	leech_digest_blood(blood_consumed)
	update_stamina_hud()
	victim.update_stamina_hud()
	if(victim.vessel.get_reagent_amount(/datum/reagent/blood) <= 0 && victim.stat != DEAD)
		victim.death()
		leech_schedule_conversion(victim)
	return blood_consumed

/mob/living/carbon/human/proc/leech_schedule_conversion(mob/living/carbon/human/victim)
	if(!victim?.mind || victim.mind.leech_conversion_pending)
		return
	var/datum/mind/pending_mind = victim.mind
	pending_mind.leech_conversion_pending = TRUE
	spawn(600)
		if(!victim || victim.mind != pending_mind || victim.stat != DEAD || pending_mind.is_leech())
			pending_mind.leech_conversion_pending = FALSE
			return
		victim.revive()
		if(victim.stat == DEAD || victim.mind != pending_mind || pending_mind.current != victim || !GLOB.leech_antagonist.add_antagonist(pending_mind, 1, 0, 0, 1))
			pending_mind.leech_conversion_pending = FALSE
			return
		pending_mind.leech_conversion_pending = FALSE
		to_chat(victim, "<span class='danger'><font size=3>Your dead body stirs. The hunger for blood is yours now. You are a Leech.</font></span>")

/mob/living/carbon/human/proc/begin_starter_leech_death()
	if(!SSdirector.starter_required || SSdirector.starter_body != src || mind != SSdirector.starter_mind || stat == DEAD)
		return
	var/obj/item/organ/internal/heart/heart = get_organ(BP_HEART)
	if(!heart)
		SSdirector.clear_starter_candidate()
		return
	heart.pulse = PULSE_NONE
	heart.heartbeat = 0
	to_chat(src, "<span class='danger'>A crushing pain grips your chest. Your heart stops.</span>")
	death(FALSE, "clutches their chest and collapses, lifeless...")
	if(stat != DEAD || mind != SSdirector.starter_mind)
		SSdirector.clear_starter_candidate()
		return
	SSdirector.starter_resurrection_at = world.time + DIRECTOR_LEECH_REVIVAL_DELAY
	var/client/owner = SSdirector.get_starter_client()
	if(owner)
		owner.verbs |= /client/proc/rise_as_leech
		SSdirector.starter_action_client = owner
		to_chat(owner, "<span class='danger'>Death has not released you. In one minute, you may choose Rise Again to return to your body. Only then will your hunger awaken.</span>")
	log_debug("AI Director: Round-start leech [SSdirector.starter_ckey] suffered fatal cardiac arrest.")

/client/proc/rise_as_leech()
	set name = "Rise Again"
	set category = "IC"
	if(!SSdirector || SSdirector.starter_busy || GAME_STATE != RUNLEVEL_GAME || SSdirector.director_state == DIRECTOR_STATE_DORMANT || SSdirector.director_state == DIRECTOR_STATE_CONCLUDED)
		return
	if(!SSdirector.starter_awakening_valid() || SSdirector.get_starter_client() != src)
		verbs -= /client/proc/rise_as_leech
		return
	if(world.time < SSdirector.starter_resurrection_at)
		to_chat(src, "<span class='notice'>Your body is not ready. You must wait [ceil((SSdirector.starter_resurrection_at - world.time) / 10)] seconds.</span>")
		return
	SSdirector.complete_starter_leech(TRUE)

/datum/controller/subsystem/director/proc/complete_starter_leech(self_resurrection = FALSE)
	if(starter_busy || !starter_awakening_valid())
		return FALSE
	if(starter_body.stat == DEAD && (!self_resurrection || world.time < starter_resurrection_at))
		return FALSE
	starter_busy = TRUE
	var/client/owner = get_starter_client()
	if(starter_body.stat == DEAD)
		starter_body.revive()
	if(starter_body.stat == DEAD || starter_body.mind != starter_mind || starter_mind.current != starter_body)
		starter_busy = FALSE
		return FALSE
	if(istype(owner.mob, /mob/observer/ghost))
		var/mob/observer/ghost/observer = owner.mob
		if(!observer.reenter_corpse())
			starter_busy = FALSE
			return FALSE
	var/datum/antagonist/antag = GLOB.all_antag_types_["leech"]
	if(!antag.add_antagonist(starter_mind, FALSE, FALSE, FALSE, FALSE, TRUE))
		clear_starter_candidate()
		starter_busy = FALSE
		return FALSE
	loyalty.set_faction(starter_mind, LOYALTY_NEUTRAL)
	starter_body.visible_message("<span class='danger'>[starter_body] stirs, their eyes opening with an unnatural hunger.</span>")
	log_debug("AI Director: Round-start leech [starter_ckey] resurrected and converted.")
	starter_required = FALSE
	clear_starter_candidate()
	starter_busy = FALSE
	return TRUE

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
	for(var/obj/item/reagent_containers/ivbag/bag in owner.current.get_contents())
		blood_total += bag.reagents.get_reagent_amount(/datum/reagent/blood)
	return blood_total >= 500

/datum/objective/leech/undiagnosed
	explanation_text = "Survive the shift without Medbay diagnosing your hematopoietic failure."

/datum/objective/leech/undiagnosed/check_completion()
	return owner && !owner.leech_diagnosed

GLOBAL_DATUM_INIT(leech_antagonist, /datum/antagonist/afflicted, new)