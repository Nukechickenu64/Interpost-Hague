/world
	mob = /mob/living/carbon/human/artemis_preview

var/global/turf/artemis_preview_origin
var/global/obj/artemis_preview_door
var/global/list/artemis_preview_lamps = list()
var/global/artemis_preview_capture_started = FALSE

/area/artemis_preview
	name = "Artemis lighting reference fixture"
	requires_power = FALSE
	dynamic_lighting = TRUE

/proc/build_artemis_preview()
	if(artemis_preview_origin) return artemis_preview_origin
	if(world.params["los_reference"])
		return build_artemis_reference_scene()
	if(world.params["los_spots_capture"])
		return build_artemis_spot_scene()
	var/cx = world.maxx - 25
	var/cy = world.maxy - 25
	var/zlevel = world.maxz
	var/area/A = new /area/artemis_preview
	var/wall_x = world.params["los_dark_capture"] ? 6 : 10
	var/wall_y = world.params["los_dark_capture"] ? 5 : 9
	for(var/dx in -10 to 10)
		for(var/dy in -9 to 9)
			var/turf/T = locate(cx + dx, cy + dy, zlevel)
			T = T.ChangeTurf(/turf/unsimulated/floor)
			A.contents += T
			T.icon = 'icons/os13/turf/turf/newmaintenance.dmi'
			T.icon_state = dx < 0 ? "hh" : "h3"
			if(abs(dx) == wall_x || abs(dy) == wall_y || (dx == 3 && dy != 0) || (dy == 3 && dx < -1))
				T = T.ChangeTurf(/turf/unsimulated/wall)
			T.lighting_build_overlay()
	artemis_preview_origin = locate(cx, cy, zlevel)
	artemis_preview_door = new /obj(locate(cx + 3, cy, zlevel))
	artemis_preview_door.name = "preview door"
	artemis_preview_door.icon = 'icons/obj/doors/Doorint.dmi'
	artemis_preview_door.icon_state = "door_closed"
	artemis_preview_door.anchored = TRUE
	artemis_preview_door.density = TRUE
	artemis_preview_door.set_opacity(TRUE)
	for(var/list/settings in list(list(-2, 2, "#a5afbe"), list(6, 2, "#208700"), list(-4, -4, "#8060ff")))
		var/obj/machinery/floor_light/os13/lamp = new(locate(cx + settings[1], cy + settings[2], zlevel))
		lamp.default_light_range = 6
		lamp.default_light_power = 4
		lamp.default_light_colour = settings[3]
		lamp.stat &= ~NOPOWER
		lamp.on = TRUE
		lamp.update_brightness()
		artemis_preview_lamps += lamp
	SSlighting.fire(FALSE, TRUE)
	return artemis_preview_origin

/mob/living/carbon/human/artemis_preview/Login()
	// A client can connect while map initialization is still running. Build the
	// fixture only after lighting and opacity invalidation are ready.
	while(!shadowcasting_controller.initialized)
		sleep(5)
	forceMove(build_artemis_preview())
	..()
	SSticker.can_fire = FALSE
	set_sight(SEE_SELF)
	set_see_in_dark(8)
	set_see_invisible(INVISIBILITY_LIGHTING)
	hide_cone()
	client.create_opacity_image()
	client.create_cull_mask()
	if(world.params["lighting_halo_capture"])
		winset(src, "mainwindow", "title=Lighting-Halo-Comparison")
	if(world.params["los_twitch_capture"])
		winset(src, "mainwindow", "title=LOS-Transition-Regression")
		world.log << "ARTEMIS_TWITCH_READY"
	to_chat(src, "Lighting fixture: arrow keys move. Preview Door toggles the opaque doorway; Preview Lights toggles all lamps. Ctrl-right-click tests look-far.")
	// DreamSeeker can reconnect while a second launch logs into the same mob.
	// Schedule one replay per preview world, never two competing input streams.
	if(artemis_preview_capture_started)
		return
	if(world.params["drop_shadow_capture"] || world.params["lighting_halo_capture"] || world.params["los_twitch_capture"] || world.params["los_spots_capture"] || world.params["los_dark_capture"] || world.params["los_edge_calibration"] || world.params["los_input_capture"] || world.params["los_capture"])
		artemis_preview_capture_started = TRUE
	if(world.params["drop_shadow_capture"])
		winset(src, "mainwindow", "title=Drop-Shadow-Comparison")
		spawn(100)
			if(world.params["drop_shadow_wait"])
				world.log << "ARTEMIS_DROP_SHADOW_READY"
				while(client)
					if(fexists("tmp/artemis-lighting/drop-shadow-trigger.txt"))
						fdel("tmp/artemis-lighting/drop-shadow-trigger.txt")
						preview_drop_shadow_sequence()
					sleep(5)
			else
				preview_drop_shadow_sequence()
	else if(world.params["lighting_halo_capture"])
		spawn(100)
			preview_halo_sequence()
	else if(world.params["los_twitch_capture"])
		spawn(100)
			if(world.params["los_twitch_wait"])
				while(client)
					if(fexists("tmp/artemis-lighting/twitch-replay-trigger.txt"))
						fdel("tmp/artemis-lighting/twitch-replay-trigger.txt")
						preview_twitch_sequence()
					sleep(5)
			else
				preview_twitch_sequence()
	else if(world.params["los_spots_capture"])
		spawn(50)
			preview_spot_sequence()
	else if(world.params["los_dark_capture"])
		spawn(50)
			preview_dark_sequence()
	else if(world.params["los_edge_calibration"])
		spawn(50)
			preview_edge_calibration()
	else if(world.params["los_input_capture"])
		spawn(50)
			preview_input_sequence()
	else if(world.params["los_capture"])
		spawn(50)
			preview_capture_sequence()

// Explicit opt-in renderer test, using DreamSeeker's own map export rather than
// an OS screenshot. Files go to the client's BYOND/screenshots directory.
/mob/living/carbon/human/artemis_preview/proc/preview_snapshot(label)
	if(!client) return
	world.log << "ARTEMIS_CAPTURE [label] at [world.time]"
	winset(src, null, "command=\".screenshot auto\"")

/mob/living/carbon/human/artemis_preview/proc/preview_halo_sequence()
	var/obj/screen/lighting_veil_display/veil = locate() in client.screen
	for(var/strength in list(0, 128, 255))
		veil.alpha = strength
		sleep(20)
		preview_snapshot("tile-veil-[strength]")
		sleep(5)
	preview_lights()
	SSlighting.fire(FALSE, TRUE)
	sleep(20)
	preview_snapshot("tile-veil-dark")
	sleep(5)
	preview_lights()
	world.log << "ARTEMIS_HALO complete"

/mob/living/carbon/human/artemis_preview/proc/preview_drop_shadow_sequence()
	var/old_canmove = canmove
	canmove = FALSE
	var/list/grain_alphas = list()
	for(var/obj/screen/G in client.screen)
		if(G.icon == 'icons/effects/static.dmi')
			grain_alphas[G] = G.alpha
			G.alpha = 0
	forceMove(artemis_preview_origin)
	var/obj/structure/closet/crate/crate = new(get_step(artemis_preview_origin, NORTHWEST))
	var/list/casters = list(src, crate)
	for(var/enabled in list(FALSE, TRUE))
		dynamic_shadows_enabled = enabled
		for(var/atom/movable/A in casters)
			A.update_dynamic_shadow()
			world.log << "ARTEMIS_DROP caster=[A.type] enabled=[enabled] eligible=[A.should_cast_dynamic_shadow()] count=[length(A.dynamic_shadows)]"
			for(var/L in A.dynamic_shadows)
				var/atom/movable/dynamic_shadow/S = A.dynamic_shadows[L]
				world.log << "ARTEMIS_DROP silhouette loc=[S.x],[S.y] alpha=[S.alpha] icon=[S.icon] state=[S.icon_state] overlays=[S.overlays.len] plane=[S.plane] layer=[S.layer] transform=[S.transform]"
		sleep(20)
		preview_snapshot("drop-shadow-[enabled]")
		sleep(5)
	preview_lights()
	SSlighting.fire(FALSE, TRUE)
	for(var/atom/movable/A in casters)
		A.update_dynamic_shadow()
	sleep(20)
	preview_snapshot("drop-shadow-dark")
	sleep(5)
	preview_lights()
	canmove = old_canmove
	for(var/obj/screen/G in grain_alphas)
		G.alpha = grain_alphas[G]
	world.log << "ARTEMIS_DROP_SHADOW complete"

/mob/living/carbon/human/artemis_preview/proc/preview_capture_sequence()
	if(!client) return
	preview_snapshot("closed-door")
	sleep(5)
	preview_door()
	sleep(5)
	preview_snapshot("open-door")
	sleep(5)
	set_glide_size(1)
	Move(get_step(src, NORTH), NORTH)
	var/deadline = client.los_motion.ends
	var/datum/los_edge_mesh/mesh = client.los_meshes[client.los_meshes[1]]
	var/revision = mesh.shape_revision
	client.shadowcast_force = TRUE
	client.update_opacity_image()
	world.log << "ARTEMIS_MOTION cardinal duration=[deadline - client.los_motion.started] depth=[client.los_move_depth] refresh_preserved=[deadline == client.los_motion.ends && revision == mesh.shape_revision]"
	for(var/i in 1 to 4)
		sleep(4)
		preview_snapshot("move-[i]")
	sleep(5)
	preview_snapshot("stopped")
	sleep(5)
	Move(get_step(src, SOUTHWEST), SOUTHWEST)
	world.log << "ARTEMIS_MOTION diagonal duration=[client.los_motion.ends - client.los_motion.started] depth=[client.los_move_depth] origin_cleared=[isnull(client.los_move_origin)]"
	sleep(20)
	preview_snapshot("diagonal-stopped")
	sleep(5)
	preview_lights()
	SSlighting.fire(FALSE, TRUE)
	sleep(5)
	preview_snapshot("lights-off")
	sleep(10)
	preview_lights()
	world.log << "ARTEMIS_CAPTURE complete"

/mob/living/carbon/human/artemis_preview/Life()
	if(client)
		client.update_opacity_image()
		client.update_cull_mask(TRUE)
	return TRUE

/mob/living/carbon/human/artemis_preview/verb/preview_door()
	set name = "Preview Door"
	set category = "Preview"
	artemis_preview_door.set_opacity(!artemis_preview_door.opacity)
	artemis_preview_door.density = artemis_preview_door.opacity
	artemis_preview_door.icon_state = artemis_preview_door.opacity ? "door_closed" : "door_open"

/mob/living/carbon/human/artemis_preview/verb/preview_lights()
	set name = "Preview Lights"
	set category = "Preview"
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = !lamp.on
		lamp.update_brightness()

/mob/living/carbon/human/artemis_preview/verb/preview_reset()
	set name = "Preview Reset"
	set category = "Preview"
	forceMove(artemis_preview_origin)

// Exercise the same client.Move -> SelfMove path used by movement input. The
// older slow fixture deliberately called mob.Move directly to inspect geometry.
/mob/living/carbon/human/artemis_preview/proc/preview_input_trace(phase)
	var/list/position = client.los_motion.position()
	world.log << "ARTEMIS_INPUT [json_encode(list("phase" = phase, "time" = world.time, "x" = x, "y" = y, "glide" = glide_size, "move_delay" = client.move_delay, "eye_x" = position[1], "eye_y" = position[2], "target_x" = client.los_motion.target_x, "target_y" = client.los_motion.target_y, "started" = client.los_motion.started, "ends" = client.los_motion.ends, "depth" = client.los_move_depth))]"

/mob/living/carbon/human/artemis_preview/proc/preview_input_sequence()
	if(!client) return
	preview_snapshot("input-initial")
	if(artemis_preview_door.opacity)
		preview_door()
	sleep(5)
	m_intent = world.params["los_move_intent"] == "run" ? "run" : "walk"
	world.log << "ARTEMIS_INPUT_INTENT [m_intent]"
	for(var/step_number in 1 to 3)
		if(client.move_delay > world.time)
			sleep(client.move_delay - world.time)
		var/turf/from = get_turf(src)
		preview_input_trace("before-[step_number]")
		client.Move(get_step(src, SOUTH), SOUTH)
		if(get_turf(src) == from)
			world.log << "ARTEMIS_INPUT_FAILURE step [step_number] did not move"
			return
		preview_input_trace("start-[step_number]")
		if(client.glide_size != glide_size)
			world.log << "ARTEMIS_INPUT_FAILURE camera glide [client.glide_size] differs from body glide [glide_size]"
		var/deadline = client.los_motion.ends
		while(world.time < deadline)
			sleep(world.tick_lag)
			client.shadowcast_force = TRUE
			client.update_opacity_image()
			preview_input_trace("glide-[step_number]")
			if(world.params["los_frame_capture"])
				preview_snapshot("frame-[step_number]-[world.time]")
			if(client.los_motion.ends != deadline)
				world.log << "ARTEMIS_INPUT_FAILURE refresh changed glide deadline"
		preview_snapshot("input-step-[step_number]")
	preview_input_trace("stop")
	var/turf/stopped = get_turf(src)
	var/deadline = client.los_motion.ends
	for(var/tick in 1 to 10)
		sleep(world.tick_lag)
		client.shadowcast_force = TRUE
		client.update_opacity_image()
		preview_input_trace("rest")
		if(world.params["los_frame_capture"])
			preview_snapshot("rest-[tick]")
		if(get_turf(src) != stopped || client.los_motion.ends != deadline)
			world.log << "ARTEMIS_INPUT_FAILURE stopping changed the journey"
	preview_snapshot("input-stopped")
	// A remote look must release the body-camera override; returning restores
	// the body's explicit speed without leaving a stale automatic catch-up.
	var/saved_camera_glide = client.los_saved_camera_glide
	client.eye = get_step(src, NORTH)
	client.update_opacity_image()
	if(client.glide_size != saved_camera_glide || !isnull(client.los_saved_camera_glide))
		world.log << "ARTEMIS_INPUT_FAILURE remote eye retained body camera speed"
	reset_view()
	client.update_opacity_image()
	if(client.glide_size != glide_size)
		world.log << "ARTEMIS_INPUT_FAILURE returning to body did not restore camera speed"
	sleep(10)
	world.log << "ARTEMIS_INPUT complete"

/mob/living/carbon/human/artemis_preview/proc/preview_twitch_sequence()
	if(artemis_preview_door.opacity) preview_door()
	m_intent = "run"
	for(var/mode in list("legacy", "corrected"))
		los_preview_legacy_images = mode == "legacy"
		forceMove(get_step(artemis_preview_origin, EAST))
		sleep(20)
		for(var/repetition in 1 to 4)
			for(var/direction in list(".moveright", ".moveleft"))
				var/turf/from = get_turf(src)
				var/list/previous_images = list()
				for(var/key in client.los_meshes)
					var/datum/los_edge_mesh/mesh = client.los_meshes[key]
					previous_images += mesh.triangles
				world.log << "ARTEMIS_TWITCH [mode] start [repetition] [direction] [world.time]"
				// Dispatch through DreamSeeker's input command and network path,
				// rather than calling client.Move directly on the server.
				var/command = direction
				winset(src, null, "command=\"[command]\"")
				var/timeout = world.time + 20
				while(get_turf(src) == from && world.time < timeout)
					sleep(world.tick_lag)
				if(get_turf(src) == from)
					world.log << "ARTEMIS_TWITCH_FAILURE client command did not move"
					return
				if(mode == "corrected" && (previous_images & client.images).len)
					world.log << "ARTEMIS_TWITCH_FAILURE completed images were retained"
				var/list/active_images = client.images.Copy()
				client.shadowcast_force = TRUE
				client.update_opacity_image()
				if((active_images - client.images).len)
					world.log << "ARTEMIS_TWITCH_FAILURE stationary refresh replaced active images"
				sleep(max(1, client.los_motion.ends - world.time) + 10)
				world.log << "ARTEMIS_TWITCH [mode] stopped [repetition] [direction] [world.time]"
	los_preview_legacy_images = FALSE
	// Back-to-back direction changes exercise the continuous-movement boundary,
	// without the one-second stationary interval used by the comparison above.
	for(var/repetition in 1 to 4)
		for(var/direction in list(".moveright", ".moveleft"))
			var/turf/from = get_turf(src)
			world.log << "ARTEMIS_TWITCH continuous [repetition] [direction] [world.time]"
			var/timeout = world.time + 20
			// Repeat like a held key: an instant command at the exact server
			// cooldown boundary can arrive just before movement becomes legal.
			while(get_turf(src) == from && world.time < timeout)
				winset(src, null, "command=\"[direction]\"")
				sleep(world.tick_lag)
			if(get_turf(src) == from)
				world.log << "ARTEMIS_TWITCH_FAILURE continuous command did not move"
				return
			if(client.images.len < 2 * client.los_meshes.len)
				world.log << "ARTEMIS_TWITCH_FAILURE missing mesh images"
	sleep(20)
	world.log << "ARTEMIS_TWITCH complete"

/mob/living/carbon/human/artemis_preview/proc/preview_edge_calibration()
	var/obj/screen/plane_master/shadowcasting/shadow_plane = locate() in client.screen
	if(!shadow_plane)
		world.log << "ARTEMIS_CALIBRATION_FAILURE missing shadow plane"
		return
	if(artemis_preview_door.opacity)
		preview_door()
	m_intent = "walk"
	for(var/softness in list(1.5, 3, 3.2))
		forceMove(artemis_preview_origin)
		shadow_plane.add_filter("shadow_edge", 1, list("type" = "blur", "size" = softness))
		// Allow the client's previous movement glide to settle after resetting.
		sleep(20)
		preview_snapshot("blur-[softness]-base")
		sleep(5)
		client.Move(get_step(src, SOUTH), SOUTH)
		sleep(max(1, client.los_motion.ends - world.time) + 5)
		preview_snapshot("blur-[softness]-south")
		sleep(5)
	world.log << "ARTEMIS_CALIBRATION complete"

/mob/living/carbon/human/artemis_preview/proc/preview_dark_sequence()
	var/obj/screen/plane_master/lighting/light_plane = locate() in client.screen
	// Compare both compositions in one world, with identical lamp samples.
	for(var/mode in list("before", "after"))
		var/legacy = mode == "before"
		for(var/turf/T in range(20, artemis_preview_origin))
			if(!T.lighting_overlay) continue
			T.lighting_overlay.layer = legacy ? 2 : LIGHTING_LAYER
			T.lighting_overlay.blend_mode = legacy ? BLEND_MULTIPLY : BLEND_OVERLAY
			if(T.lighting_overlay.edge_guard)
				T.lighting_overlay.edge_guard.alpha = legacy ? 0 : 255
		light_plane.add_filter("light_softness", 1, list("type" = "blur", size = 2))
		light_plane.add_filter("bloom", 4, list("type" = "bloom", threshold = LIGHTING_BLOOM_THRESHOLD, size = LIGHTING_BLOOM_SIZE, offset = LIGHTING_BLOOM_OFFSET, alpha = LIGHTING_BLOOM_ALPHA))
		for(var/obj/machinery/floor_light/lamp in artemis_preview_lamps)
			lamp.on = TRUE
			lamp.update_brightness()
		SSlighting.fire(FALSE, TRUE)
		sleep(10)
		preview_snapshot("[mode]-lit")
		sleep(5)
		preview_lights()
		SSlighting.fire(FALSE, TRUE)
		sleep(10)
		preview_snapshot("[mode]-dark-filtered")
		sleep(5)
		light_plane.remove_filter(list("light_softness", "bloom"))
		sleep(5)
		preview_snapshot("[mode]-dark-unfiltered")
		sleep(5)
	world.log << "ARTEMIS_DARK complete"

/proc/build_artemis_spot_scene()
	var/turf/C = locate(world.maxx - 25, world.maxy - 25, world.maxz)
	var/area/A = new /area/artemis_preview
	for(var/dx in -8 to 8)
		for(var/dy in -7 to 7)
			var/turf/T = locate(C.x + dx, C.y + dy, C.z)
			T = T.ChangeTurf(abs(dx) >= 5 || abs(dy) >= 4 ? /turf/unsimulated/wall : /turf/unsimulated/floor)
			A.contents += T
			T.icon = get_solid_white_icon()
			T.icon_state = ""
			T.color = T.opacity ? "#808080" : "#404040"
			T.lighting_build_overlay()
	artemis_preview_origin = locate(C.x, C.y, C.z)
	var/obj/lamp = new(artemis_preview_origin)
	lamp.set_light(12, 4, "#ffffff")
	// A far-side fixture is offset into the visible east wall. It must remain
	// hidden without cutting a black rectangle out of the wall itself.
	var/obj/mount = new(locate(C.x + 6, C.y, C.z))
	mount.name = "far-side offset fixture"
	mount.icon = get_solid_white_icon()
	mount.color = "#ff0000"
	mount.pixel_x = -16
	mount.anchored = TRUE
	SSlighting.fire(FALSE, TRUE)
	return artemis_preview_origin

/mob/living/carbon/human/artemis_preview/proc/preview_spot_sequence()
	preview_snapshot("spots-lit")
	for(var/dx in list(-5, 0, 5))
		for(var/dy in list(-4, 0, 4))
			if(!dx && !dy) continue
			var/turf/T = locate(x + dx, y + dy, z)
			world.log << "ARTEMIS_SPOT sample [dx],[dy] rgb=[T.lighting_overlay?.lum_r]"
	sleep(5)
	var/obj/screen/plane_master/shadowcasting/shadows = locate() in client.screen
	shadows.alpha = 0
	sleep(5)
	preview_snapshot("spots-no-los")
	shadows.alpha = 255
	for(var/obj/O in artemis_preview_origin)
		if(O.light_range) O.set_light(0)
	SSlighting.fire(FALSE, TRUE)
	sleep(10)
	preview_snapshot("spots-dark")
	sleep(5)
	world.log << "ARTEMIS_SPOTS complete"
