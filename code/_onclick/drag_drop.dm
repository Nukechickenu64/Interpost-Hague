/*
	MouseDrop:

	Called on the atom you're dragging.  In a lot of circumstances we want to use the
	recieving object instead, so that's the default action.  This allows you to drag
	almost anything into a trash can.
*/

/atom/proc/CanMouseDrop(atom/over, var/mob/user = usr, var/incapacitation_flags)
	if(!user || !over)
		return FALSE
	if(!ghost_can_affect_world(user))
		return FALSE
	if(user.incapacitated(incapacitation_flags))
		return FALSE
	if(!src.Adjacent(user) || !over.Adjacent(user))
		return FALSE // should stop you from dragging through windows
	return check_mousedrop_interactivity(user)

/atom/proc/check_mousedrop_interactivity(var/mob/user)
	return CanPhysicallyInteract(user)

/atom/MouseDrop(atom/over)
	if(!usr || !over) return
	if(!ghost_can_affect_world(usr, TRUE))
		return
	if(!Adjacent(usr) || !over.Adjacent(usr)) return // should stop you from dragging through windows

	var/mob/user = usr
	spawn(0)
		if(!QDELETED(user) && !QDELETED(over) && ghost_can_affect_world(user))
			over.MouseDrop_T(src, user)
	return

// Receive a mouse drop
/atom/proc/MouseDrop_T(atom/dropping, mob/user)
	return
