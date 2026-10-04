/client
	var/magic_casting = FALSE
	var/weakref/magic_last_clicked
	var/magic_last_clicked_time = 0

/client/proc/magic_note_click(atom/A)
	if(!magic_interpreter.can_attempt(mob) || istype(A, /obj/screen) || !(istype(A, /atom/movable) || isturf(A)))
		return
	magic_last_clicked = weakref(A)
	magic_last_clicked_time = world.time

/proc/magic_resolve_target(mode, mob/caster, allow_turf = FALSE)
	switch(mode)
		if("self")
			return caster
		if("held")
			return caster.get_active_hand()
		if("visus")
			return magic_resolve_visus(caster, allow_turf)

/proc/magic_resolve_visus(mob/caster, allow_turf = FALSE)
	var/client/C = caster.client
	if(C && C.magic_last_clicked && world.time - C.magic_last_clicked_time <= 10 SECONDS)
		var/atom/clicked = C.magic_last_clicked.resolve()
		if(clicked && !QDELETED(clicked) && (allow_turf || !isturf(clicked)) && (clicked in view(world.view, caster)))
			return clicked

	var/turf/T = get_turf(caster)
	var/turf/last_open
	for(var/i in 1 to world.view)
		T = get_step(T, caster.dir)
		if(!T)
			break
		for(var/mob/living/L in T)
			if(L != caster && !L.invisibility)
				return L
		for(var/obj/O in T)
			if(!O.invisibility && !istype(O, /obj/effect))
				return O
		if(T.density)
			break
		last_open = T
	if(allow_turf)
		return last_open
