/* SURGERY STEPS */

/datum/surgery_step
	var/priority = 0	//steps with higher priority would be attempted first

	// type path referencing tools that can be used for this step, and how well are they suited for it
	var/list/allowed_tools = null
	// type paths referencing races that this step applies to.
	var/list/allowed_species = null
	var/list/disallowed_species = null

	// duration of the step
	var/min_duration = 0
	var/max_duration = 0

	// evil infection stuff that will make everyone hate me
	var/can_infect = 0
	//How much blood this step can get on surgeon. 1 - hands, 2 - full body.
	var/blood_level = 0
	var/shock_level = 0	//what shock level will this step put patient on
	var/delicate = 0  //if this step NEEDS stable optable or can be done on any valid surface with no penalty

//returns how well tool is suited for this step
/datum/surgery_step/proc/tool_quality(obj/item/tool)
	for (var/T in allowed_tools)
		if (istype(tool,T))
			return allowed_tools[T]
	return 0

// Checks if this step applies to the user mob at all
/datum/surgery_step/proc/is_valid_target(mob/living/carbon/human/target)
	if(!hasorgans(target))
		return 0

	if(allowed_species)
		for(var/species in allowed_species)
			if(target.species.get_bodytype(target) == species)
				return 1

	if(disallowed_species)
		for(var/species in disallowed_species)
			if(target.species.get_bodytype(target) == species)
				return 0

	return 1


// checks whether this step can be applied with the given user and target
/datum/surgery_step/proc/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return 0

// does stuff to begin the step, usually just printing messages. Moved germs transfering and bloodying here too
/datum/surgery_step/proc/begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if (can_infect && affected)
		spread_germs_to_organ(affected, user)
	if (ishuman(user) && prob(60))
		var/mob/living/carbon/human/H = user
		if (blood_level)
			H.bloody_hands(target,0)
		if (blood_level > 1)
			H.bloody_body(target,0)
	if(shock_level)
		target.shock_stage = max(target.shock_stage, shock_level)
	return

// does stuff to end the step, which is normally print a message + do whatever this step changes
/datum/surgery_step/proc/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(istype(tool, /obj/item/weapon/surgery_tool))
		var/obj/item/weapon/surgery_tool/T = tool
		if(T.operation_sound)
			playsound(user.loc, T.operation_sound, 50, 3)
	return

// stuff that happens when the step fails
/datum/surgery_step/proc/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(istype(tool, /obj/item/weapon/surgery_tool))
		var/obj/item/weapon/surgery_tool/T = tool
		if(T.operation_sound_fail)
			playsound(user.loc, T.operation_sound_fail, 50, 3)
	return null

/datum/surgery_step/proc/success_chance(mob/living/user, mob/living/carbon/human/target, obj/item/tool)
	. = tool_quality(tool)
	if(user == target)
		. -= 10
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		. -= round(H.shock_stage * 0.5)
		if(H.eye_blurry)
			. -= 20
		if(H.eye_blind)
			. -= 60
	if(delicate)
		if(user.slurring)
			. -= 10
		if(!target.lying)
			. -= 30
		var/turf/T = get_turf(target)
		if(locate(/obj/machinery/optable, T))
			. -= 0
		else if(locate(/obj/structure/bed, T))
			. -= 5
		else if(locate(/obj/structure/table, T))
			. -= 10
		else if(locate(/obj/effect/rune/, T))
			. -= 10
	. = max(., 0)

/proc/spread_germs_to_organ(var/obj/item/organ/external/E, var/mob/living/carbon/human/user)
	if(!istype(user) || !istype(E)) return

	var/germ_level = user.germ_level
	if(user.gloves)
		germ_level = user.gloves.germ_level

	E.germ_level = max(germ_level,E.germ_level) //as funny as scrubbing microbes out with clean gloves is - no.

/obj/item/proc/do_surgery(mob/living/carbon/M, mob/living/user, fuckup_prob)
	if(!istype(M))
		return 0
	if(!user || user.incapacitated() || !user.Adjacent(M) || !(src in user.contents))
		to_chat(user, "<span class='warning'>You must hold the tool beside your patient to operate.</span>")
		return 1
	if (user.a_intent == I_HURT)	//check for Hippocratic Oath
		return 0
	var/zone = user.zone_sel.selecting
	if(zone in M.op_stage.in_progress) //Can't operate on someone repeatedly.
		to_chat(user, "<span class='warning'>You can't operate on this area while surgery is already in progress.</span>")
		return 1
	for(var/datum/surgery_step/S in surgery_steps)
		//check if tool is right or close enough and if this step is possible
		if(S.tool_quality(src))
			// Reserve the region before a step can open an organ-selection dialog.
			M.op_stage.in_progress += zone
			var/mob/living/carbon/human/patient = M
			var/obj/item/organ/external/original_region
			if(istype(patient))
				original_region = patient.get_organ(zone)
			var/had_region = !!original_region
			M.op_stage.current_organ = null
			var/step_is_valid = S.can_use(user, M, zone, src)
			if(QDELETED(src) || QDELETED(user) || QDELETED(M) || user.incapacitated() || !user.Adjacent(M) || !(src in user.contents) || user.zone_sel.selecting != zone || (had_region && (QDELETED(original_region) || patient.get_organ(zone) != original_region)))
				if(!QDELETED(M))
					M.op_stage.in_progress -= zone
				to_chat(user, "<span class='warning'>The surgical conditions changed. The operation was cancelled.</span>")
				return 1
			if(step_is_valid && S.is_valid_target(M))
				if(step_is_valid == SURGERY_FAILURE) // This is a failure that already has a message for failing.
					M.op_stage.in_progress -= zone
					return 1
				var/selected_organ = M.op_stage.current_organ
				var/obj/item/organ/selected_object
				if(istype(selected_organ, /obj/item/organ))
					selected_object = selected_organ
				else if(istype(patient) && istext(selected_organ))
					selected_object = patient.internal_organs_by_name[selected_organ]
				var/had_selection = !!selected_object
				var/atom/selected_location = selected_object ? selected_object.loc : null
				var/mob/living/carbon/selected_owner = selected_object ? selected_object.owner : null
				S.begin_step(user, M, zone, src)		//start on it
				var/datum/wound/original_incision = original_region ? original_region.get_incision() : null
				var/had_incision = !!original_incision
				//We had proper tools! (or RNG smiled.) and user did not move or change hands.
				var/tool_success = prob(S.success_chance(user, M, src))
				var/completed = tool_success ? do_mob(user, M, rand(S.min_duration, S.max_duration)) : TRUE
				var/conditions_valid = !QDELETED(src) && !QDELETED(user) && !QDELETED(M)
				if(conditions_valid)
					conditions_valid = !user.incapacitated() && user.Adjacent(M) && (src in user.contents) && user.zone_sel.selecting == zone
				if(conditions_valid && had_region)
					conditions_valid = !QDELETED(original_region) && patient.get_organ(zone) == original_region
				if(conditions_valid && had_incision)
					conditions_valid = !QDELETED(original_incision) && original_region.get_incision() == original_incision
				if(conditions_valid && had_selection)
					conditions_valid = !QDELETED(selected_object) && selected_object.loc == selected_location && selected_object.owner == selected_owner
				if(!completed || !conditions_valid)
					to_chat(user, "<span class='warning'>Surgery interrupted. The step was not completed.</span>")
				else if(tool_success)
					// Different regions may be operated on concurrently.
					M.op_stage.current_organ = selected_organ
					if(user.statcheck(user.stats[STAT_IQ], user.skillcheck(user.skills["medical"], 45, null, "Medical"), "6d6", 20) >= SUCCESS)
						S.end_step(user, M, zone, src)		//finish successfully
					else
						visible_message("<span class='warning'>[user] messes up the surgery step. They must try again.</span>")
						S.fail_step(user, M, zone, src)
						//user.my_skills[SKILL(surgery)].give_xp(25, user)//If they fail it then give them some XP for trying.
				else
					M.op_stage.current_organ = selected_organ
					visible_message("<span class='warning'>[user] messes up the surgery step. They must try again.</span>")
					S.fail_step(user, M, zone, src)		//malpractice~
					//user.my_skills[SKILL(surgery)].give_xp(25, user)//If they fail it then give them some XP for trying.
				if (!QDELETED(M))
					M.op_stage.in_progress -= zone 									// Clear the in-progress flag.
				if (!QDELETED(M) && ishuman(M))
					var/mob/living/carbon/human/H = M
					H.update_surgery()
				return	1	  												//don't want to do weapony things after surgery
			if(!QDELETED(M))
				M.op_stage.in_progress -= zone
	return 0

/proc/sort_surgeries()
	var/gap = surgery_steps.len
	var/swapped = 1
	while (gap > 1 || swapped)
		swapped = 0
		if(gap > 1)
			gap = round(gap / 1.247330950103979)
		if(gap < 1)
			gap = 1
		for(var/i = 1; gap + i <= surgery_steps.len; i++)
			var/datum/surgery_step/l = surgery_steps[i]		//Fucking hate
			var/datum/surgery_step/r = surgery_steps[gap+i]	//how lists work here
			if(l.priority < r.priority)
				surgery_steps.Swap(i, gap + i)
				swapped = 1

/datum/surgery_status/
	var/eyes	=	0
	var/face	=	0
	var/head_reattach = 0
	var/current_organ = "organ"
	var/list/in_progress = list()