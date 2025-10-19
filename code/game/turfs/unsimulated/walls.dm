/turf/unsimulated/wall
	name = "wall"
	icon = 'icons/turf/walls.dmi'
	icon_state = "riveted"
	opacity = 1
	density = 1

/turf/unsimulated/wall/fakeglass
	name = "window"
	icon_state = "fakewindows"
	opacity = 0

/turf/unsimulated/wall/other
	icon_state = "r_wall"

/turf/unsimulated/hellwall
	name = "fleshy wall"
	desc = "It's almost moving.."
	icon = 'icons/turf/walls.dmi'
	icon_state = "hell_wall"
	opacity = 1
	density = 1

/turf/MouseDrop_T(mob/living/M, mob/living/user)
	if(density > 0)
		// user leaning effect: nudge the user's sprite a few pixels toward the wall, then restore
		if(istype(user, /mob/living))
			user._lean_prev_pixel_x = user.pixel_x
			user._lean_prev_pixel_y = user.pixel_y
				// compute cardinal direction from user to this turf
			var/dx = 0
			var/dy = 0
			if(src.x > user.x) dx = 1
			else if(src.x < user.x) dx = -1
			if(src.y > user.y) dy = 1
			else if(src.y < user.y) dy = -1

			// small nudge amount (pixels). Tweak as desired.
			var/lean_pixels = 8

			visible_message("<span class='notice'>[user] leans against the [src.name].</span>","<span class='notice'>You lean against the [src.name].</span>")

			// apply nudge
			user.pixel_x += dx * lean_pixels
			user.pixel_y += dy * lean_pixels
			user.density = 0 // to avoid collision issues while leaning

			user.leaning = TRUE

/mob/living
	var/leaning = FALSE

/mob/living/Move(NewLoc, direct)
	. = ..()
	if(leaning)
		pixel_x = _lean_prev_pixel_x
		pixel_y = _lean_prev_pixel_y
		density = 1
		leaning = FALSE
		update_icons()

/mob/living/move_to_turf(atom/movable/am, old_loc, new_loc)
	. = ..()
	if(leaning)
		pixel_x = _lean_prev_pixel_x
		pixel_y = _lean_prev_pixel_y
		density = 1
		leaning = FALSE
		update_icons()

/mob/living/human/Moved(atom/oldloc)
	. = ..()
	if(leaning)
		pixel_x = _lean_prev_pixel_x
		pixel_y = _lean_prev_pixel_y
		density = 1
		leaning = FALSE
		update_icons()