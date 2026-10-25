/client/proc/edit_own_skills()
	set name = "Edit Own Skills"
	set category = "Admin"
	set desc = "Open a menu to edit your current character's skills."
	admin_edit_own_gurps(TRUE)

/client/proc/edit_own_stats()
	set name = "Edit Own Stats"
	set category = "Admin"
	set desc = "Open a menu to edit your current character's GURPS stats."
	admin_edit_own_gurps(FALSE)

/client/proc/admin_edit_own_gurps(var/edit_skills)
	if(!holder || !(holder.rights & R_ADMIN))
		return
	if(!ishuman(mob))
		to_chat(src, SPAN_WARNING("You must be controlling a human character to edit your skills or stats."))
		return
	var/mob/living/carbon/human/target = mob
	var/title = edit_skills ? "Edit Own Skills" : "Edit Own Stats"
	var/list/stat_names = list("Strength" = STAT_ST, "Dexterity" = STAT_DX, "Intelligence" = STAT_IQ, "Health" = STAT_HT, "Perception" = STAT_PER, "Willpower" = STAT_WP, "Immunity" = STAT_IM, "Speed" = STAT_SPD)
	while(holder && (holder.rights & R_ADMIN) && mob == target && !QDELETED(target))
		var/list/choices = list()
		if(edit_skills)
			var/list/skill_keys = list()
			for(var/skill in deathweb_skill_defaults)
				skill_keys |= skill
			for(var/skill in target.skills)
				skill_keys |= skill
			for(var/skill in skill_keys)
				var/value = target.skills[skill] || 0
				choices["[capitalize(skill)]: [value]/100 ([target.skillnumtodesc(value)])"] = skill
		else
			for(var/label in stat_names)
				var/stat_key = stat_names[label]
				choices["[label]: [target.gurps_stat(stat_key)]"] = stat_key
		var/selection = input(src, "Choose a value to edit. Cancel closes this menu.", title) as null|anything in choices
		// Inputs yield: do not edit an old body after ghosting or losing admin rights.
		if(isnull(selection) || !holder || !(holder.rights & R_ADMIN) || mob != target || QDELETED(target))
			return
		var/entry = choices[selection]
		if(isnull(entry))
			return
		var/old_value = edit_skills ? (target.skills[entry] || 0) : target.gurps_stat(entry)
		var/prompt = edit_skills ? "Set [entry] from 0 to 100. 50 is adept; 100 is legendary." : "Set the current effective [entry] stat from 0 to 100. Temporary effects still expire normally; changing IQ or HT also affects derived stats."
		var/new_value = input(src, prompt, title, old_value) as null|num
		if(!holder || !(holder.rights & R_ADMIN) || mob != target || QDELETED(target))
			return
		if(isnull(new_value))
			continue
		if(new_value < 0 || new_value > 100)
			to_chat(src, SPAN_WARNING("Enter a number from 0 to 100."))
			continue
		new_value = round(new_value)
		if(edit_skills)
			target.skills[entry] = new_value
		else
			// Translate effective Perception/Immunity back into their stored offsets.
			var/stored_value = new_value
			if(entry == STAT_PER)
				stored_value = new_value - target.stats[STAT_IQ] + 10
			else if(entry == STAT_IM)
				stored_value = new_value - target.stats[STAT_HT]
			target.stats[entry] = stored_value
		log_admin("[key_name(src)] changed their own [edit_skills ? "skill" : "stat"] [entry] from [old_value] to [new_value].")
		to_chat(src, SPAN_NOTICE("[capitalize(entry)] is now [new_value]."))
