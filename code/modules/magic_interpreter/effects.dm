/obj/effect/overlay/temp/magic_cast
	name = "shimmer"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	duration = 10
	randomdir = 0

/proc/magic_cast_effect(atom/A, with_sound = TRUE)
	var/turf/T = get_turf(A)
	if(!T)
		return
	new /obj/effect/overlay/temp/magic_cast(T)
	if(with_sound)
		playsound(T, 'sound/effects/phasein.ogg', 35, 1)
		A.visible_message("<span class='notice'>The air around \the [A] shimmers as spoken words take hold.</span>")
