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
	if(world.params["openspace_capture"])
		return build_openspace_preview()
	if(world.params["video_motion_capture"])
		artemis_preview_origin = locate(130, 128, 2)
		return artemis_preview_origin
	if(world.params["edge_debug_capture"])
		if(world.params["wall_depth_capture"])
			artemis_preview_origin = locate(131, 128, 2)
			return artemis_preview_origin
		var/list/signature = list("/turf/simulated/floor/fixed", "/turf/simulated/floor/fixed", "/turf/simulated/floor/fixed", "/turf/simulated/floor/fixed", "/turf/simulated/floor/fixed", "/turf/simulated/floor/fixed", "/turf/simulated/floor/tiled/verybright", "/turf/simulated/wall/iron", "/turf/simulated/wall/iron")
		for(var/z in 1 to world.maxz)
			var/matches = 0
			var/i = 0
			for(var/dy in -1 to 1)
				for(var/dx in -1 to 1)
					var/turf/T = locate(136 + dx, 134 + dy, z)
					if("[T?.type]" == signature[++i]) matches++
			if(matches >= 7)
				artemis_preview_origin = locate(136, 134, z)
				world.log << "ARTEMIS_EDGE matched StrongerDMM scene at 136,134,[z]"
				return artemis_preview_origin
		artemis_preview_origin = locate(136, 134, 2)
		world.log << "ARTEMIS_EDGE scene signature did not match; using requested z=2"
		return artemis_preview_origin
	if(world.params["ao_elevator_capture"])
		artemis_preview_origin = locate(135, 125, 1)
		return artemis_preview_origin
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
	if(world.params["wall_corner_capture"])
		winset(src, "mainwindow", "title=Wall-Corner-LOS-Check")
	if(world.params["wall_footprint_capture"])
		winset(src, "mainwindow", "title=Wall-Footprint-LOS-Check")
	if(world.params["video_motion_capture"])
		winset(src, "mainwindow", "title=Video-LOS-Motion-Check")
	if(world.params["los_twitch_capture"])
		winset(src, "mainwindow", "title=LOS-Transition-Regression")
		world.log << "ARTEMIS_TWITCH_READY"
	to_chat(src, "Lighting fixture: arrow keys move. Preview Door toggles the opaque doorway; Preview Lights toggles all lamps. Ctrl-right-click tests look-far.")
	// DreamSeeker can reconnect while a second launch logs into the same mob.
	// Schedule one replay per preview world, never two competing input streams.
	if(artemis_preview_capture_started)
		return
	if(world.params["openspace_capture"])
		artemis_preview_capture_started = TRUE
		spawn(100)
			preview_openspace_sequence()
		return
	if(world.params["video_motion_capture"])
		artemis_preview_capture_started = TRUE
		spawn(100)
			world.log << "ARTEMIS_VIDEO_READY"
			while(client)
				if(fexists("tmp/review-20261031-video/replay-trigger.txt"))
					fdel("tmp/review-20261031-video/replay-trigger.txt")
					preview_recorded_video_motion()
					return
				sleep(5)
		return
	if(world.params["edge_debug_capture"])
		artemis_preview_capture_started = TRUE
		spawn(150)
			preview_edge_pass_sequence()
		return
	if(world.params["ao_elevator_capture"])
		artemis_preview_capture_started = TRUE
		spawn(100)
			preview_ao_elevator_sequence()
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
						if(world.params["drop_shadow_facing_capture"])
							preview_shadow_facing_sequence()
						else if(world.params["drop_shadow_rotation_capture"])
							preview_shadow_rotation_sequence()
						else if(world.params["drop_shadow_direction_capture"])
							preview_shadow_direction_sequence()
						else if(world.params["drop_shadow_fill_capture"])
							preview_shadow_fill_sequence()
						else
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
	if(world.params["ao_elevator_capture"] || world.params["edge_debug_capture"] || world.params["los_dark_capture"])
		preview_suppress_grain()
		sleep(2)
	world.log << "ARTEMIS_CAPTURE [label] at [world.time]"
	winset(src, null, "command=\".screenshot auto\"")

/mob/living/carbon/human/artemis_preview/proc/preview_suppress_grain()
	for(var/obj/screen/S in client.screen)
		if(istype(S, /obj/screen/fullscreen) || S == film_grain || findtext("[S.icon]", "static.dmi") || (S.icon_state in list("7 moderate", "1 light", "scanlines")))
			S.icon = null
			client.screen -= S

// Recovered tile positions from the supplied 60 fps recording. Missing board
// observations are marked as inferred in route.json; no claim of exact inputs.
/mob/living/carbon/human/artemis_preview/proc/preview_recorded_video_motion()
	var/list/route = json_decode(file2text("tools/lighting_los/video_motion_route.json"))
	var/live = !!world.params["video_motion_live"]
	canmove = live
	m_intent = "run"
	GLOB.cryo_startup_effect.stop()
	preview_suppress_grain()
	for(var/obj/machinery/light/L in range(16, src))
		var/area/A = get_area(L)
		A.requires_power = FALSE
		L.stat &= ~NOPOWER
		L.on = TRUE
		if(L.lightbulb) L.lightbulb.status = LIGHT_OK
		L.update_icon(0)
	SSlighting.fire(FALSE, TRUE)
	SSlighting.can_fire = live
	SSdynamic_shadows.can_fire = live
	set_glide_size(8)
	var/list/modes = world.params["video_motion_corrected_only"] ? list("corrected") : list("previous", "corrected")
	for(var/mode in modes)
		los_preview_legacy_wall_motion = mode == "previous"
		for(var/turf/T in block(locate(108, 104, 2), locate(159, 152, 2))) T.shadowcasting_initialized = FALSE
		client.clear_opacity_image()
		forceMove(locate(130, 128, 2))
		client.los_motion.reset(x, y)
		client.shadowcast_force = TRUE
		client.update_opacity_image()
		sleep(20)
		world.log << "ARTEMIS_VIDEO begin [mode] time=[world.time] live=[live] lighting=[SSlighting.can_fire] shadows=[SSdynamic_shadows.can_fire]"
		var/list/first = route[1]
		var/start_time = world.time
		for(var/i in 2 to route.len)
			var/list/step = route[i]
			var/due = start_time + (step["time"] - first["time"]) * 10
			if(world.time < due) sleep(due - world.time)
			var/turf/target = locate(step["x"], step["y"], 2)
			var/moved = FALSE
			if(get_dist(src, target) == 1)
				if(live)
					// Exercise cooldowns, SelfMove/glide setup and the walking pose.
					// Direct mob.Move bypasses all three and hid input-only defects.
					if(world.time < client.move_delay) sleep(client.move_delay - world.time)
					if(world.params["video_motion_native"])
						var/list/commands = list("[NORTH]" = ".moveup", "[SOUTH]" = ".movedown", "[EAST]" = ".moveright", "[WEST]" = ".moveleft")
						var/command = commands["[get_dir(src, target)]"]
						var/turf/from = loc
						var/deadline = world.time + 20
						while(loc == from && world.time < deadline)
							winset(src, null, "command=\"[command]\"")
							sleep(world.tick_lag)
						moved = loc == target
					else
						moved = client.Move(target, get_dir(src, target))
				else
					moved = Move(target, get_dir(src, target))
			if(!moved || loc != target)
				world.log << "ARTEMIS_VIDEO_FAILURE [mode] step=[i] from=[x],[y] target=[target.x],[target.y]"
				return
			world.log << "ARTEMIS_VIDEO step [mode] index=[i] pos=[x],[y] time=[world.time] end=[client.los_motion.ends] glide=[glide_size] retained=[client.los_retained_walls.len] shadows=[length(dynamic_shadows)] walking=[walking_phase]"
			sleep(0)
		sleep(20)
		world.log << "ARTEMIS_VIDEO end [mode] time=[world.time]"
	los_preview_legacy_wall_motion = FALSE
	SSlighting.can_fire = TRUE
	SSdynamic_shadows.can_fire = TRUE
	canmove = TRUE
	world.log << "ARTEMIS_VIDEO complete"

// Independent native render-pass switches, leaving the production renderer
// untouched. Reuse the user's StrongerDMM tile signature and mapped geometry.
/mob/living/carbon/human/artemis_preview/proc/preview_edge_pass_sequence()
	canmove = FALSE
	GLOB.cryo_startup_effect.stop()
	for(var/obj/machinery/light/L in range(12, src))
		var/area/A = get_area(L)
		A.requires_power = FALSE
		L.stat &= ~NOPOWER
		L.on = TRUE
		if(L.lightbulb) L.lightbulb.status = LIGHT_OK
		L.update_icon(0)
	SSlighting.fire(FALSE, TRUE)
	SSlighting.can_fire = FALSE
	var/obj/screen/plane_master/lighting/light_plane = locate() in client.screen
	var/obj/screen/plane_master/shadowcasting/los_plane = locate() in client.screen
	var/obj/screen/plane_master/los_visible_objects/foreground = locate() in client.screen
	var/obj/screen/plane_master/emissive/emission = locate() in client.screen
	var/obj/screen/lighting_veil_display/veil = locate() in client.screen
	sleep(30)
	if(world.params["wall_depth_capture"])
		SSdynamic_shadows.can_fire = FALSE
		if(world.params["wall_corner_capture"])
			var/footprint_compare = world.params["wall_footprint_capture"]
			var/phase_hold = footprint_compare ? 100 : 200
			preview_snapshot(footprint_compare ? "wall-footprint-corrected" : "wall-corners-whole")
			sleep(phase_hold)
			los_preview_legacy_corner_promotion = !!footprint_compare
			for(var/turf/W in client.los_wall_images)
				var/image/I = client.los_wall_images[W]
				I.layer = los_wall_protection_depth(W, get_turf(src), !!footprint_compare) + 0.001
			sleep(20)
			preview_snapshot(footprint_compare ? "wall-footprint-before" : "wall-corners-before")
			sleep(phase_hold)
			los_preview_legacy_corner_promotion = FALSE
			client.update_wall_depth_masks(get_turf(src))
			sleep(20)
			preview_snapshot(footprint_compare ? "wall-footprint-corrected-repeat" : "wall-corners-whole-repeat")
			sleep(100)
			SSlighting.can_fire = TRUE
			SSdynamic_shadows.can_fire = TRUE
			canmove = TRUE
			world.log << "[footprint_compare ? "ARTEMIS_WALL_FOOTPRINT" : "ARTEMIS_WALL_CORNERS"] complete at [x],[y],[z]"
			return
		for(var/turf/W in block(locate(x + 1, y - 7, z), locate(x + 6, y - 1, z)))
			if(!W.opaque_counter) continue
			var/detail = "WALL_DEPTH [W.x],[W.y] native=[W in loc:shadowcasting_visible_walls]"
			for(var/direction in GLOB.cardinal)
				if(!get_step(W, direction)?.opaque_counter)
					detail += " face[direction]=[los_wall_face_depth(W, direction, x, y)]"
			world.log << detail
		preview_snapshot("wall-depth-corrected")
		for(var/key in client.los_meshes)
			var/datum/los_edge_mesh/mesh = client.los_meshes[key]
			for(var/i in 5 to 6)
				var/image/I = mesh.triangles[i]
				I.alpha = 0
		sleep(10)
		preview_snapshot("wall-depth-old-exemption")
		for(var/key in client.los_meshes)
			var/datum/los_edge_mesh/mesh = client.los_meshes[key]
			for(var/i in 5 to 6)
				var/image/I = mesh.triangles[i]
				I.alpha = 255
		sleep(10)
		preview_snapshot("wall-depth-corrected-repeat")
		sleep(10)
		SSlighting.can_fire = TRUE
		SSdynamic_shadows.can_fire = TRUE
		canmove = TRUE
		world.log << "ARTEMIS_WALL_DEPTH complete at [x],[y],[z]"
		return
	if(world.params["object_occlusion_compare"])
		SSdynamic_shadows.can_fire = FALSE
		// Pixel-offset sprites can remain native-visible while their rendered
		// pixels sit behind a wall. The former blanket exemption revealed this.
		var/obj/hidden_probe = new(loc)
		hidden_probe.icon = get_solid_white_icon()
		hidden_probe.color = "#ffffff"
		hidden_probe.pixel_x = 96
		hidden_probe.pixel_y = 64
		var/obj/visible_probe = new(loc)
		visible_probe.icon = get_solid_white_icon()
		visible_probe.color = "#00ffff"
		visible_probe.pixel_x = -32
		sleep(10)
		preview_snapshot("objects-geometric-los")
		foreground.remove_filter("object_los")
		sleep(10)
		preview_snapshot("objects-broken-blanket-exemption")
		foreground.add_filter("object_los", 1, list("type" = "alpha", "render_source" = "*los_geometry", "flags" = MASK_INVERSE))
		sleep(10)
		preview_snapshot("objects-geometric-los-repeat")
		sleep(10)
		qdel(hidden_probe)
		qdel(visible_probe)
		SSlighting.can_fire = TRUE
		SSdynamic_shadows.can_fire = TRUE
		canmove = TRUE
		world.log << "ARTEMIS_OBJECT_OCCLUSION complete at [x],[y],[z]"
		return
	if(world.params["edge_mask_compare"])
		SSdynamic_shadows.can_fire = FALSE
		preview_snapshot("edge-visible-objects-protected")
		sleep(10)
		los_plane.remove_filter("visible_objects")
		sleep(10)
		preview_snapshot("edge-legacy-object-overdraw")
		sleep(10)
		los_plane.add_filter("visible_objects", 6, list("type" = "alpha", "render_source" = "los_visible_objects", "flags" = MASK_INVERSE))
		sleep(10)
		preview_snapshot("edge-visible-objects-protected-repeat")
		sleep(10)
		SSlighting.can_fire = TRUE
		SSdynamic_shadows.can_fire = TRUE
		canmove = TRUE
		world.log << "ARTEMIS_EDGE_OBJECT_MASK complete at [x],[y],[z]"
		return
	preview_snapshot("edge-all-passes")
	sleep(10)
	dynamic_shadows_enabled = FALSE
	SSdynamic_shadows.can_fire = FALSE
	for(var/atom/movable/A in range(16, src))
		A.clear_dynamic_shadows()
	sleep(10)
	preview_snapshot("edge-no-projected-shadows")
	sleep(10)
	for(var/atom/movable/lighting_edge_guard/G in range(16, src))
		G.alpha = 0
	sleep(10)
	preview_snapshot("edge-no-light-padding")
	sleep(10)
	for(var/atom/movable/lighting_edge_guard/G in range(16, src))
		G.alpha = 255
	light_plane.remove_filter("light_softness")
	sleep(10)
	preview_snapshot("edge-no-light-blur")
	sleep(10)
	light_plane.add_filter("light_softness", 1, list("type" = "blur", "size" = 2))
	los_plane.alpha = 0
	sleep(10)
	preview_snapshot("edge-no-los")
	sleep(10)
	light_plane.alpha = 0
	emission.alpha = 0
	veil.alpha = 0
	sleep(10)
	preview_snapshot("edge-raw-art")
	sleep(10)
	light_plane.alpha = 255
	emission.alpha = 255
	veil.alpha = 255
	los_plane.alpha = 255
	SSlighting.can_fire = TRUE
	dynamic_shadows_enabled = TRUE
	SSdynamic_shadows.can_fire = TRUE
	canmove = TRUE
	world.log << "ARTEMIS_EDGE complete at [x],[y],[z]"

// Actual OS13 classic lower elevator, not a synthetic lighting fixture.
/mob/living/carbon/human/artemis_preview/proc/preview_ao_elevator_sequence()
	canmove = FALSE
	forceMove(locate(133, 127, 1))
	client.shadowcast_force = TRUE
	client.update_opacity_image()
	// Capture after the startup cryo pulse, with existing fixtures powered.
	// Placement, wall/window geometry, sprite offsets and LOS stay mapped.
	GLOB.cryo_startup_effect.stop()
	for(var/obj/machinery/light/L in range(10, src))
		var/area/A = get_area(L)
		A.requires_power = FALSE
		L.stat &= ~NOPOWER
		L.on = TRUE
		if(L.lightbulb)
			L.lightbulb.status = LIGHT_OK
		L.update_icon(0)
	SSlighting.fire(FALSE, TRUE)
	var/obj/screen/world_ao_display/PM = locate() in client.screen
	if(!PM)
		sleep(20)
		preview_snapshot("elevator-ao-disabled")
		canmove = TRUE
		world.log << "ARTEMIS_ELEVATOR AO disabled at [x],[y],[z]"
		return
	var/old_lighting_fire = SSlighting.can_fire
	// Mapped lamps can flicker or change hue during a pair. Hold their applied
	// lightmap constant so the only scene-wide change is the AO display.
	SSlighting.can_fire = FALSE
	for(var/obj/screen/S in client.screen)
		if(S == film_grain || findtext("[S.icon]", "static.dmi"))
			S.alpha = 0
	sleep(20)
	preview_snapshot("elevator-ao-on")
	PM.alpha = 0
	sleep(10)
	preview_snapshot("elevator-ao-off")
	if(world.params["ao_object_probe"])
		sleep(10)
		preview_snapshot("elevator-ao-off-control")
	PM.alpha = 255
	if(world.params["ao_object_probe"])
		// A lower-plane opaque object was beneath the old foreground AO pass.
		var/obj/probe = new(loc)
		probe.name = "AO foreground protection probe"
		probe.icon = get_solid_white_icon()
		probe.color = "#20a0ff"
		probe.plane = BLACKNESS_PLANE
		probe.layer = OBJ_LAYER
		sleep(20)
		preview_snapshot("elevator-ao-probe-on")
		sleep(5)
		PM.alpha = 0
		sleep(10)
		preview_snapshot("elevator-ao-probe-off")
		sleep(10)
		preview_snapshot("elevator-ao-probe-off-control")
		sleep(5)
		PM.alpha = 255
		qdel(probe)
	SSlighting.can_fire = old_lighting_fire
	world.log << "ARTEMIS_ELEVATOR complete at [x],[y],[z]"

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
		if(G == film_grain || findtext("[G.icon]", "static.dmi"))
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
				var/matrix/M = S.transform
				world.log << "ARTEMIS_DROP geometry z=[S.z] matrix=[M.a],[M.b],[M.c],[M.d],[M.e],[M.f] height=[A.get_dynamic_shadow_icon_height()] floor_plane=[A.loc.plane] floor_layer=[A.loc.layer] visible=[S in view(20, src)]"
		sleep(20)
		preview_snapshot("drop-shadow-[enabled]")
		sleep(5)
	if(world.params["drop_shadow_debug"])
		SSdynamic_shadows.can_fire = FALSE
		for(var/atom/movable/A in casters)
			for(var/L in A.dynamic_shadows)
				var/atom/movable/dynamic_shadow/S = A.dynamic_shadows[L]
				S.filters = null
				S.color = "#ff00ff"
				S.alpha = 255
				S.transform = null
				S.layer = ABOVE_HUMAN_LAYER
		sleep(20)
		preview_snapshot("drop-shadow-debug-visible")
		sleep(5)
		for(var/atom/movable/A in casters)
			for(var/L in A.dynamic_shadows)
				var/atom/movable/dynamic_shadow/S = A.dynamic_shadows[L]
					S.color = "#ff00ff"
				S.transform = S.target_projection
		sleep(20)
		preview_snapshot("drop-shadow-debug-projected")
		sleep(5)
		for(var/atom/movable/A in casters)
			for(var/L in A.dynamic_shadows)
				var/atom/movable/dynamic_shadow/S = A.dynamic_shadows[L]
				S.appearance_flags &= ~(KEEP_TOGETHER|KEEP_APART)
		sleep(20)
		preview_snapshot("drop-shadow-debug-ungrouped")
		sleep(5)
		for(var/atom/movable/A in casters)
			for(var/L in A.dynamic_shadows)
				var/atom/movable/dynamic_shadow/S = A.dynamic_shadows[L]
				S.color = "#000000"
		sleep(20)
		preview_snapshot("drop-shadow-debug-black")
		sleep(5)
		for(var/atom/movable/A in casters)
			A.clear_dynamic_shadows()
		SSdynamic_shadows.can_fire = TRUE
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

// Paired native exports retain identical illumination; only the shadow mask
// changes. This distinguishes a filled shadow from a brighter floor texture.
/mob/living/carbon/human/artemis_preview/proc/preview_shadow_fill_sequence()
	var/old_canmove = canmove
	canmove = FALSE
	forceMove(artemis_preview_origin)
	var/list/grain_alphas = list()
	for(var/obj/screen/G in client.screen)
		if(G == film_grain || findtext("[G.icon]", "static.dmi"))
			grain_alphas[G] = G.alpha
			G.alpha = 0
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = FALSE
		lamp.update_brightness()
	var/obj/key_light = new(locate(x, y + 2, z))
	var/obj/fill_light = new(locate(x, y - 3, z))
	key_light.set_light(8, 4, "#ffffff")
	fill_light.set_light(8, 8, "#ffffff")
	SSdynamic_shadows.can_fire = FALSE
	for(var/aimed in list(FALSE, TRUE))
		fill_light.set_light_cone(60, aimed ? 0 : 180, 0, x, aimed ? y - 1 : y - 7)
		SSlighting.fire(FALSE, TRUE)
		update_dynamic_shadow()
		var/atom/movable/dynamic_shadow/S = dynamic_shadows[key_light.light]
		var/icon/actual_mask = S.light_mask
		S.light_mask = null
		S.set_shadow_filters()
		sleep(20)
		preview_snapshot("shadow-fill-[aimed]-unmasked")
		sleep(5)
		S.light_mask = actual_mask
		S.set_shadow_filters()
		sleep(20)
		preview_snapshot("shadow-fill-[aimed]-masked")
		sleep(5)
		world.log << "ARTEMIS_SHADOW_FILL aimed=[aimed] receiver_retention=[dynamic_shadow_retention(key_light.light, get_step(loc, SOUTH), 0, -2, 2)] mask=[!isnull(actual_mask)]"
	qdel(key_light)
	qdel(fill_light)
	SSlighting.fire(FALSE, TRUE)
	update_dynamic_shadow()
	sleep(20)
	preview_snapshot("shadow-fill-dark")
	sleep(5)
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = TRUE
		lamp.update_brightness()
	SSdynamic_shadows.can_fire = TRUE
	canmove = old_canmove
	for(var/obj/screen/G in grain_alphas)
		G.alpha = grain_alphas[G]
	world.log << "ARTEMIS_SHADOW_FILL complete"

/mob/living/carbon/human/artemis_preview/proc/preview_shadow_direction_sequence()
	var/old_canmove = canmove
	var/old_dir = dir
	canmove = FALSE
	forceMove(artemis_preview_origin)
	var/list/grain_alphas = list()
	for(var/obj/screen/G in client.screen)
		if(G == film_grain || findtext("[G.icon]", "static.dmi"))
			grain_alphas[G] = G.alpha
			G.alpha = 0
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = FALSE
		lamp.update_brightness()
	var/obj/key_light = new
	key_light.set_light(8, 4, "#ffffff")
	SSdynamic_shadows.can_fire = FALSE
	for(var/lamp_side in list(WEST, EAST, NORTH, SOUTH))
		key_light.forceMove(get_step(get_step(get_step(loc, lamp_side), lamp_side), lamp_side))
		SSlighting.fire(FALSE, TRUE)
		for(var/facing in list(SOUTH, EAST))
			set_dir(facing)
			update_dynamic_shadow()
			var/atom/movable/dynamic_shadow/S = dynamic_shadows[key_light.light]
			var/list/center = key_light.light.dynamic_shadow_center()
			var/dx = x - center[1]
			var/dy = y - center[2]
			var/distance = sqrt(dx * dx + dy * dy)
			var/shadow_length = Clamp(0.3 + distance * 0.25, 0.4, 1.4)
			// Historical geometry is confined to this opt-in diagnostic fixture.
			var/shear = dx / distance * shadow_length
			var/height = dy / distance * shadow_length * 0.55
			if(abs(height) < 0.2) height = height < 0 ? -0.2 : 0.2
			var/half_height = get_dynamic_shadow_icon_height() / 2
			S.copy_owner_appearance(dir)
			S.transform = matrix(transform) * matrix(0.9, shear, shear * half_height, 0, height, height * half_height - half_height)
			S.light_mask = null
			S.light_mask_signature = null
			S.set_shadow_filters()
			sleep(20)
			preview_snapshot("shadow-direction-[lamp_side]-[facing]-legacy")
			sleep(5)
			// Recreate through the production path after overriding the old
			// transform. Reusing its completed filtered draw group leaves stale
			// bounds at exactly sideways angles in the comparison client.
			clear_dynamic_shadows()
			sleep(20)
			preview_snapshot("shadow-direction-[lamp_side]-[facing]-clear")
			sleep(5)
			update_dynamic_shadow()
			S = dynamic_shadows[key_light.light]
			sleep(20)
			preview_snapshot("shadow-direction-[lamp_side]-[facing]-corrected")
			sleep(5)
			var/matrix/M = S.target_projection
			world.log << "ARTEMIS_SHADOW_DIRECTION lamp=[lamp_side] facing=[facing] sprite=[S.dir] determinant=[M.a * M.e - M.b * M.d]"
			if(world.params["drop_shadow_direction_debug"] && lamp_side == WEST && facing == SOUTH)
				world.log << "ARTEMIS_DIRECTION_DEBUG alpha=[S.alpha] icon=[S.icon] state=[S.icon_state] overlays=[S.overlays.len] mask=[!isnull(S.light_mask)] matrix=[M.a],[M.b],[M.c],[M.d],[M.e],[M.f]"
				fcopy(S.icon, "tmp/artemis-shadow-20261029/direction-sprite.dmi")
				S.light_mask = null
				S.set_shadow_filters()
				sleep(20)
				preview_snapshot("direction-debug-no-mask")
				sleep(5)
				S.copy_owner_appearance(dir)
				S.light_mask = null
				S.set_shadow_filters()
				S.transform = M
				sleep(20)
				preview_snapshot("direction-debug-owner-sprite")
				sleep(5)
				var/matrix/epsilon = matrix(M)
				epsilon.a = 0.0001
				epsilon.e = 0.0001
				S.transform = epsilon
				sleep(20)
				preview_snapshot("direction-debug-epsilon")
				sleep(5)
				S.transform = null
				sleep(20)
				preview_snapshot("direction-debug-upright")
				sleep(5)
	qdel(key_light)
	SSlighting.fire(FALSE, TRUE)
	update_dynamic_shadow()
	sleep(20)
	preview_snapshot("shadow-direction-dark")
	sleep(5)
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = TRUE
		lamp.update_brightness()
	set_dir(old_dir)
	SSdynamic_shadows.can_fire = TRUE
	canmove = old_canmove
	for(var/obj/screen/G in grain_alphas)
		G.alpha = grain_alphas[G]
	world.log << "ARTEMIS_SHADOW_DIRECTION complete"

// Native facing check: actual composed humans, all four facings at each lamp.
/mob/living/carbon/human/artemis_preview/proc/preview_shadow_facing_sequence()
	var/old_canmove = canmove
	var/old_dir = dir
	var/shadows_running = SSdynamic_shadows.can_fire
	canmove = FALSE
	GLOB.cryo_startup_effect.stop()
	preview_suppress_grain()
	forceMove(artemis_preview_origin)
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = FALSE
		lamp.update_brightness()
	SSdynamic_shadows.can_fire = FALSE
	var/obj/key_light = new
	key_light.icon = get_solid_white_icon()
	key_light.color = "#fff0a0"
	key_light.transform = matrix(0.2, 0, 0, 0, 0.2, 0)
	key_light.set_light(8, 4, "#ffffff")
	for(var/lamp_side in list(NORTH, SOUTH, WEST, EAST))
		key_light.forceMove(get_step(get_step(loc, lamp_side), lamp_side))
		SSlighting.fire(FALSE, TRUE)
		for(var/facing in list(NORTH, SOUTH, EAST, WEST))
			set_dir(facing)
			update_dynamic_shadow()
			var/atom/movable/dynamic_shadow/S = dynamic_shadows[key_light.light]
			if(!S)
				world.log << "ARTEMIS_SHADOW_FACING_FAILURE missing shadow lamp=[lamp_side] facing=[facing]"
				continue
			sleep(5)
			world.log << "ARTEMIS_SHADOW_FACING lamp=[lamp_side] facing=[facing] sprite=[S.dir] time=[world.time]"
			sleep(10)
	qdel(key_light)
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = TRUE
		lamp.update_brightness()
	set_dir(old_dir)
	canmove = old_canmove
	SSdynamic_shadows.can_fire = shadows_running
	world.log << "ARTEMIS_SHADOW_FACING complete"

// Slow native glides isolate the matrix animation from input cooldowns. Both
// modes use production Move/update_dynamic_shadow; only interpolation differs.
/mob/living/carbon/human/artemis_preview/proc/preview_shadow_rotation_sequence()
	var/old_canmove = canmove
	var/old_glide = glide_size
	var/list/grain_alphas = list()
	for(var/obj/screen/G in client.screen)
		if(G == film_grain || findtext("[G.icon]", "static.dmi"))
			grain_alphas[G] = G.alpha
			G.alpha = 0
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = FALSE
		lamp.update_brightness()
	SSdynamic_shadows.can_fire = FALSE
	var/obj/key_light = new
	key_light.set_light(8, 4, "#ffffff")
	for(var/mode in list("legacy", "corrected"))
		shadow_preview_legacy_rotation = mode == "legacy"
		for(var/side in list(WEST, EAST))
			forceMove(artemis_preview_origin)
			key_light.forceMove(locate(x + (side == WEST ? -2 : 2), y + 1, z))
			SSlighting.fire(FALSE, TRUE)
			set_dir(NORTH)
			set_glide_size(2)
			client.glide_size = glide_size
			clear_dynamic_shadows()
			update_dynamic_shadow()
			sleep(20)
			world.log << "ARTEMIS_SHADOW_ROTATION begin mode=[mode] side=[side] time=[world.time]"
			for(var/direction in list(NORTH, NORTH, SOUTH, SOUTH))
				if(!Move(get_step(src, direction), direction))
					world.log << "ARTEMIS_SHADOW_ROTATION_FAILURE blocked step"
					return
				var/atom/movable/dynamic_shadow/S = dynamic_shadows[key_light.light]
				var/matrix/M = S.target_projection
				world.log << "ARTEMIS_SHADOW_ROTATION step mode=[mode] side=[side] direction=[direction] dx=[x-key_light.x] dy=[y-key_light.y] matrix=[M.a],[M.b],[M.c],[M.d],[M.e],[M.f] time=[world.time]"
				sleep(world.icon_size / glide_size * world.tick_lag + 8)
			world.log << "ARTEMIS_SHADOW_ROTATION end mode=[mode] side=[side] time=[world.time]"
	shadow_preview_legacy_rotation = FALSE
	qdel(key_light)
	forceMove(artemis_preview_origin)
	set_glide_size(old_glide)
	for(var/obj/machinery/floor_light/os13/lamp in artemis_preview_lamps)
		lamp.on = TRUE
		lamp.update_brightness()
	SSdynamic_shadows.can_fire = TRUE
	canmove = old_canmove
	for(var/obj/screen/G in grain_alphas)
		G.alpha = grain_alphas[G]
	world.log << "ARTEMIS_SHADOW_ROTATION complete"

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
		if(world.params["ao_elevator_capture"])
			preview_suppress_grain()
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
				if(mode == "corrected" && (previous_images - client.images).len)
					world.log << "ARTEMIS_TWITCH_FAILURE starting a new step discarded persistent rays"
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
	var/obj/screen/lighting_backdrop/backdrop = locate() in client.screen
	// Exercise an unpadded cull boundary in both compositions.
	var/list/guard_alphas = list()
	for(var/turf/T in range(20, artemis_preview_origin))
		var/atom/movable/lighting_edge_guard/guard = T.lighting_overlay?.edge_guard
		if(guard)
			guard_alphas[guard] = guard.alpha
			guard.alpha = 0
	// Compare both compositions in one world, with identical lamp samples.
	for(var/mode in list("before", "after"))
		var/legacy = mode == "before"
		backdrop.color = legacy ? "#ffffff" : "#000000"
		if(legacy)
			light_plane.remove_filter("light_coverage")
		else
			light_plane.add_filter("light_coverage", 5, list("type" = "alpha", render_source = "*light_samples"))
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
	for(var/atom/movable/lighting_edge_guard/guard in guard_alphas)
		guard.alpha = guard_alphas[guard]
	light_plane.add_filter("light_softness", 1, list("type" = "blur", size = 2))
	light_plane.add_filter("bloom", 4, list("type" = "bloom", threshold = LIGHTING_BLOOM_THRESHOLD, size = LIGHTING_BLOOM_SIZE, offset = LIGHTING_BLOOM_OFFSET, alpha = LIGHTING_BLOOM_ALPHA))
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
