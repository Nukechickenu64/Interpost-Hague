/obj/skybox
	name = "skybox"
	mouse_opacity = 0
	anchored = TRUE
	blend_mode = BLEND_MULTIPLY
	simulated = FALSE
	screen_loc = "CENTER,CENTER"
	plane = SKYBOX_PLANE

/client
	var/obj/skybox/skybox
	var/list/os13_parallax_layers = list()
	var/obj/screen/plane_master/os13_parallax/os13_parallax_master
	var/skybox_z
	var/skybox_uses_os13 = FALSE

// Layers compose normally inside the plane; the finished plane is multiplied
// onto white space turfs so floors, walls and darkness never reveal it.
/obj/screen/plane_master/os13_parallax
	name = "parallax plane master"
	plane = SKYBOX_PLANE
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = 0

/obj/skybox/os13_layer
	appearance_flags = TILE_BOUND | PIXEL_SCALE
	blend_mode = BLEND_OVERLAY
	var/depth = 0
	var/pixels_per_tile = 1
	var/tiled_z
	var/tiled_view

/obj/skybox/os13_layer/proc/update_layer(client/C, turf/T, rebuild)
	if(rebuild || tiled_z != T.z || tiled_view != C.view)
		overlays.Cut()
		tiled_z = T.z
		tiled_view = C.view
		var/list/view_size = getviewsize(C.view)
		// Cover half the viewport plus the largest wrapped shift and one spare tile.
		var/radius_x = Ceiling((view_size[1] * world.icon_size / 2 + 512) / 480)
		var/radius_y = Ceiling((view_size[2] * world.icon_size / 2 + 512) / 480)
		var/image/tile
		if(depth)
			tile = SSskybox.get_os13_stars(T.z, depth)
		else
			tile = image(icon = 'icons/turf/fullscreen4.dmi', icon_state = "space2")
		for(var/x in -radius_x to radius_x)
			for(var/y in -radius_y to radius_y)
				var/image/piece = image(null)
				piece.overlays += tile
				piece.pixel_x = x * 480 - 224
				piece.pixel_y = y * 480 - 224
				overlays += piece
	// Wrap at the authored image width and keep the TILE_BOUND anchor near the
	// screen centre; a far-translated anchor can be culled, exposing the edges.
	var/offset_x = round((T.x * world.icon_size + C.pixel_x) * pixels_per_tile / world.icon_size)
	var/offset_y = round((T.y * world.icon_size + C.pixel_y) * pixels_per_tile / world.icon_size)
	offset_x = ((offset_x % 480) + 480) % 480
	offset_y = ((offset_y % 480) + 480) % 480
	if(offset_x >= 240)
		offset_x -= 480
	if(offset_y >= 240)
		offset_y -= 480
	set_camera_offset(-offset_x, -offset_y)
	C.screen |= src

/obj/skybox/proc/set_camera_offset(offset_x, offset_y)
	// Screen bounds drive zoom and render-target origins; parallax must not expand them.
	var/matrix/position = matrix()
	position.Translate(offset_x, offset_y)
	transform = position

/client/proc/clear_os13_parallax()
	for(var/obj/skybox/os13_layer/L in os13_parallax_layers)
		screen -= L
		qdel(L)
	os13_parallax_layers.Cut()
	if(os13_parallax_master)
		screen -= os13_parallax_master
		QDEL_NULL(os13_parallax_master)

/client/proc/update_skybox(rebuild)
	var/turf/T = get_turf(eye)
	if(!T)
		screen -= skybox
		for(var/obj/skybox/os13_layer/L in os13_parallax_layers)
			screen -= L
		screen -= os13_parallax_master
		skybox_z = null
		return
	var/use_os13 = SSskybox.use_os13_parallax()
	if(skybox_z != T.z || skybox_uses_os13 != use_os13)
		rebuild = TRUE
	skybox_z = T.z
	skybox_uses_os13 = use_os13
	if(use_os13)
		screen -= skybox
		if(!os13_parallax_master)
			os13_parallax_master = new
		// HUD rebuilds can reset the screen; keep the space mask present.
		screen |= os13_parallax_master
		if(!os13_parallax_layers.len)
			for(var/depth in 0 to 3)
				var/obj/skybox/os13_layer/L = new
				L.depth = depth
				L.pixels_per_tile = 2 ** depth
				L.layer = SKYBOX_LAYER + depth
				if(depth)
					L.blend_mode = BLEND_ADD
				os13_parallax_layers += L
		for(var/obj/skybox/os13_layer/L in os13_parallax_layers)
			if(L.depth && !SSskybox.use_stars)
				screen -= L
			else
				L.update_layer(src, T, rebuild)
		return
	if(os13_parallax_layers.len)
		clear_os13_parallax()
	if(!skybox)
		skybox = new()
		screen += skybox
		rebuild = 1

	if(T)
		if(rebuild)
			skybox.overlays.Cut()
			skybox.overlays += SSskybox.get_skybox(T.z)
		screen |= skybox
		skybox.set_camera_offset(-224 - T.x, -224 - T.y)

/mob/Login()
	..()
	client.update_skybox(1)

/mob/Move()
	var/old_z = get_z(src)
	. = ..()
	if(. && client)
		client.update_skybox(old_z != get_z(src))

/mob/forceMove()
	var/old_z = get_z(src)
	. = ..()
	if(. && client)
		client.update_skybox(old_z != get_z(src))