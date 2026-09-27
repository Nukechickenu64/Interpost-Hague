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

/datum/virtue/temperance
	name = "temperance"

/datum/virtue/charity
	name = "charity"

/datum/virtue/diligence
	name = "diligence"

/datum/virtue/patience
	name = "patience"

/datum/virtue/kindness
	name = "kindness"

/datum/virtue/humility
	name = "humility"

/mob/living/proc/has_virtue(var/datum/virtue/this_virtue)
	return istype(virtue, this_virtue)

/mob/living/proc/set_virtue(var/datum/virtue/set_virtue)
	virtue = set_virtue

/mob/living/proc/remove_virtue()
	virtue = null
