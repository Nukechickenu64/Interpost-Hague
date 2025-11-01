// Base life processing for mobs

/mob
	var/life_tick = 0

// Default Life proc invoked by SSmobs processing subsystem.
// Subtypes may override this to implement per-tick behavior.
/mob/proc/Life(var/wait, var/times_fired, var/datum/controller/subsystem/processing/subsystem)
	life_tick++
	return
