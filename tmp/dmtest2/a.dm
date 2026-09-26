/datum/thing
/datum/thing/proc/Go()
	return "BASE"

/datum/thing/Go()
	. = "FIRST(" + ..() + ")"
