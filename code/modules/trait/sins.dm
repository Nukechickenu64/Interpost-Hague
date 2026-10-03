/datum/sin
	var/name = "Default Sin"
	var/description = "A default sin."

/datum/sin/proc/stat_modifier(var/stat)
	switch(name)
		if("lust")
			if(stat == STAT_IQ)
				return 1
		if("gluttony")
			if(stat == STAT_HT)
				return 1
		if("greed")
			if(stat == STAT_IQ)
				return 1
		if("sloth")
			if(stat == STAT_HT)
				return 1
		if("wrath")
			if(stat == STAT_ST)
				return 2
		if("envy")
			if(stat == STAT_DX)
				return 1
		if("pride")
			if(stat == STAT_IQ)
				return 1
	return 0

/datum/sin/proc/skill_modifier(var/skill)
	switch(name)
		if("gluttony")
			if(skill == "cooking")
				return 5
		if("greed")
			if(skill == "crafting" || skill == "mining")
				return 5
		if("sloth")
			return -5
		if("wrath")
			if(skill == "melee")
				return 5
		if("envy")
			if(skill == "ranged")
				return 5
	return 0

/datum/sin/lust
	name = "lust"
	description = "Even the dirty apples I find delicious."

/datum/sin/gluttony
	name = "gluttony"
	description = "Every empty plate is just a promise of another."

/datum/sin/greed
	name = "greed"
	description = "My will is justice."

/datum/sin/sloth
	name = "sloth"
	description = "The dust has had more time with this room than I have."

/datum/sin/wrath
	name = "wrath"
	description = "One spark, and the whole room learns my name."

/datum/sin/envy
	name = "envy"
	description = "Funny how the sun always finds their window first."

/datum/sin/pride
	name = "pride"
	description = "Even my shadow seems to stand a little taller."

/mob/living/proc/has_sin(var/datum/sin/this_sin)
	return istype(sin, this_sin)

/mob/living/proc/set_sin(var/datum/sin/set_sin)
	sin = set_sin

/mob/living/proc/remove_sin()
	sin = null
