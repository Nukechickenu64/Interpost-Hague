// Controlled reconstruction of the visible junction at 03:00. Tile centers in
// the reference are approximately 84 display pixels apart; the player is (0,0),
// with the two upper shadow-casting corners at (2,2) and (4,2). Unseen topology
// and lamp parameters are provisional, so this fixture is not a recovered map.
/proc/build_artemis_reference_scene()
	var/cx = world.maxx - 25
	var/cy = world.maxy - 25
	var/zlevel = world.maxz
	var/area/A = new /area/artemis_preview
	for(var/dx in -10 to 10)
		for(var/dy in -9 to 9)
			var/open = ((dy == 0 || dy == 1) && dx >= -1 && dx <= 7)
			open ||= (dy == 2 && (dx == -1 || dx == 0 || dx == 3 || (dx >= 5 && dx <= 7)))
			open ||= (dy == 3 && dx >= -1 && dx <= 1)
			open ||= ((dy == -2 || dy == -3) && dx >= -1 && dx <= 2)
			open ||= (dx == 0 && (dy == -1 || (dy >= -7 && dy <= -4)))
			var/turf/T = locate(cx + dx, cy + dy, zlevel)
			T = T.ChangeTurf(open ? /turf/unsimulated/floor : /turf/unsimulated/wall)
			A.contents += T
			// The panes immediately east of the player do not originate the
			// reference's shadows; the next solid tile does. Keep them dense but
			// transparent, as observed from both sides during the southward step.
			if(dx == 1 && (dy == -1 || dy == 2))
				T.set_opacity(FALSE)
				T.color = "#8dabb7"
			if(open)
				T.icon = 'icons/os13/turf/turf/floors.dmi'
				T.icon_state = dx <= 1 && dy >= 0 ? "steel" : "os3"
			T.lighting_build_overlay()
	artemis_preview_origin = locate(cx, cy, zlevel)
	artemis_preview_door = new /obj(locate(cx, cy - 1, zlevel))
	artemis_preview_door.name = "reference doorway"
	artemis_preview_door.icon = 'icons/obj/doors/Doorint.dmi'
	artemis_preview_door.icon_state = "door_closed"
	artemis_preview_door.anchored = TRUE
	artemis_preview_door.density = TRUE
	artemis_preview_door.set_opacity(TRUE)
	for(var/list/settings in list(list(2, 1, 6, 4, "#ced6e2"), list(6, 1, 5, 3, "#20bf30"), list(0, -2, 3, 1.5, "#f9a34b"), list(0, -6, 4, 2, "#f9c763")))
		var/obj/machinery/floor_light/os13/lamp = new(locate(cx + settings[1], cy + settings[2], zlevel))
		lamp.default_light_range = settings[3]
		lamp.default_light_power = settings[4]
		lamp.default_light_colour = settings[5]
		lamp.stat &= ~NOPOWER
		lamp.on = TRUE
		lamp.update_brightness()
		artemis_preview_lamps += lamp
	SSlighting.fire(FALSE, TRUE)
	world.log << "ARTEMIS_REFERENCE visible junction fixture; provisional unseen topology and light parameters"
	return artemis_preview_origin
