/datum/virtue
	var/name = "Default Trait"
	var/description = "A default trait. If you see this someone fucked up."

/datum/virtue/proc/stat_modifier(var/stat)
	switch(name)
		if("chastity")
			if(stat == STAT_HT)
				return 1
		if("temperance")
			if(stat == STAT_HT)
				return 1
		if("charity")
			if(stat == STAT_IQ)
				return 1
		if("diligence")
			if(stat == STAT_DX)
				return 1
		if("patience")
			if(stat == STAT_IQ)
				return 1
		if("kindness")
			if(stat == STAT_IQ)
				return 1
	return 0

/datum/virtue/proc/skill_modifier(var/skill)
	switch(name)
		if("temperance")
			if(skill == "medical" || skill == "cooking")
				return 5
		if("charity")
			if(skill == "medical")
				return 5
		if("diligence")
			return 5
		if("patience")
			if(skill == "engineering" || skill == "surgery")
				return 5
		if("kindness")
			if(skill == "medical" || skill == "cleaning")
				return 5
	return 0

/datum/virtue/chastity
	name = "chastity"
	description = "I keep telling myself I don't want what I can't have."

/datum/virtue/temperance
	name = "temperance"
	description = "I keep saying 'enough' before I enjoy any of it."

/datum/virtue/charity
	name = "charity"
	description = "I give what I can, even when I know it won't fix much."

/datum/virtue/diligence
	name = "diligence"
	description = "I keep working, even when nobody's going to notice."

/datum/virtue/patience
	name = "patience"
	description = "I can wait. No one else seems to care if I do."

/datum/virtue/kindness
	name = "kindness"
	description = "I try to be kind, even when people make me regret it."

/datum/virtue/humility
	name = "humility"
	description = "I tell myself I don't need the credit."

/mob/living/proc/has_virtue(var/datum/virtue/this_virtue)
	return istype(virtue, this_virtue)

/mob/living/proc/set_virtue(var/datum/virtue/set_virtue)
	virtue = set_virtue

/mob/living/proc/remove_virtue()
	virtue = null
