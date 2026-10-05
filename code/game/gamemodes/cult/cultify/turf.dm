/turf/var/datum/antagonist/cultist/cult_owner

/turf/proc/cultify_for_cult(datum/antagonist/cultist/cult)
	if(!cult || cult_owner == cult)
		return
	if(istype(src, /turf/simulated/floor))
		var/turf/simulated/floor/F = src
		F.set_flooring(get_flooring_data(/decl/flooring/reinforced/cult))
		F.cult_owner = cult
		cult.add_cultiness(CULTINESS_PER_TURF)
	else if(istype(src, /turf/simulated/wall))
		var/turf/simulated/wall/W = src
		if(W.cult_owner)
			W.cult_owner.remove_cultiness(CULTINESS_PER_TURF)
		var/turf/converted
		if(W.reinf_material)
			converted = W.ChangeTurf(/turf/simulated/wall/cult/reinf)
		else
			converted = W.ChangeTurf(/turf/simulated/wall/cult)
		converted.cult_owner = cult
		cult.add_cultiness(CULTINESS_PER_TURF)
	else
		cultify()

/turf/proc/cultify()
	ChangeTurf(/turf/space)
	return

/turf/simulated/floor/cultify()
	//todo: flooring datum cultify check
	cultify_floor()

/turf/simulated/shuttle/wall/cultify()
	cultify_wall()

/turf/simulated/wall/cultify()
	cultify_wall()

/turf/simulated/wall/cult/cultify()
	return

/turf/unsimulated/wall/cult/cultify()
	return

/turf/unsimulated/beach/cultify()
	return

/turf/unsimulated/wall/cultify()
	cultify_wall()

/turf/simulated/floor/proc/cultify_floor()
	cultify_for_cult(GLOB.cult)


/turf/proc/cultify_wall()
	if(istype(src, /turf/simulated/wall))
		cultify_for_cult(GLOB.cult)
