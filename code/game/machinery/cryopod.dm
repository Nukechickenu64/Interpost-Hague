/*
 * Cryogenic refrigeration unit. Basically a despawner.
 * Stealing a lot of concepts/code from sleepers due to massive laziness.
 * The despawn tick will only fire if it's been more than time_till_despawned ticks
 * since time_entered, which is world.time when the occupant moves in.
 * ~ Zuhayr
 */


GLOBAL_DATUM_INIT(cryo_startup_effect, /datum/cryo_startup_effect, new)

/datum/cryo_startup_effect
	var/active = FALSE
	var/started = FALSE
	var/end_time = 0
	var/intensity = 0.15
	var/alarm_channel = 7
	var/pulse_timer
	var/stop_timer
	var/next_sound_update = 0
	var/list/rooms = list()
	var/list/fixtures = list()
	var/list/listeners = list()

/datum/cryo_startup_effect/proc/start()
	if(started)
		return
	started = TRUE
	end_time = round_start_time + 5 MINUTES
	if(world.time >= end_time)
		return
	for(var/obj/machinery/cryopod/pod in world)
		var/area/room = get_area(pod)
		if(!room || istype(room, /area/crew_quarters/captain) || istype(room, /area/crew_quarters/heads/hop))
			continue
		rooms |= room
	if(!length(rooms))
		return
	active = TRUE
	for(var/area/room in rooms)
		room.set_lightswitch(TRUE)
		for(var/obj/machinery/light/fixture in room)
			fixtures |= fixture
	stop_timer = addtimer(CALLBACK(src, /datum/cryo_startup_effect/proc/stop), end_time - world.time, TIMER_STOPPABLE)
	pulse()

/datum/cryo_startup_effect/proc/affects(var/obj/machinery/light/fixture)
	return active && world.time < end_time && (get_area(fixture) in rooms)

/datum/cryo_startup_effect/proc/register_light(var/obj/machinery/light/fixture)
	if(affects(fixture))
		fixtures |= fixture

/datum/cryo_startup_effect/proc/unregister_light(var/obj/machinery/light/fixture)
	fixtures -= fixture

/datum/cryo_startup_effect/proc/pulse()
	pulse_timer = null
	if(!active)
		return
	if(world.time >= end_time)
		stop()
		return
	var/phase = ((world.time - round_start_time) % (10 SECONDS)) / (10 SECONDS)
	intensity = 0.15 + 0.85 * (1 - cos(phase * 360)) / 2
	for(var/obj/machinery/light/fixture in fixtures.Copy())
		if(QDELETED(fixture))
			fixtures -= fixture
		else
			fixture.refresh_light_emission()
	if(world.time >= next_sound_update)
		update_alarm()
		next_sound_update = world.time + 1 SECOND
	pulse_timer = addtimer(CALLBACK(src, /datum/cryo_startup_effect/proc/pulse), 0.2 SECONDS, TIMER_STOPPABLE)

/datum/cryo_startup_effect/proc/update_alarm()
	var/list/current_listeners = list()
	for(var/client/listener in GLOB.clients)
		var/turf/location = get_turf(listener.mob)
		if(!location || !isStationLevel(location.z) || istype(listener.mob, /mob/new_player))
			continue
		var/mob/living/living_listener = listener.mob
		if(istype(living_listener) && ((living_listener.sdisabilities & DEAF) || living_listener.ear_deaf))
			continue
		current_listeners += listener
	for(var/client/listener in listeners - current_listeners)
		if(listener in GLOB.clients)
			sound_to(listener, sound(null, channel = alarm_channel))
	for(var/client/listener in current_listeners)
		var/alarm_playing = FALSE
		for(var/sound/playing_sound in listener.SoundQuery())
			if(playing_sound.channel == alarm_channel)
				alarm_playing = TRUE
				break
		if(!alarm_playing)
			sound_to(listener, sound('sound/ambience/CRYOLARM.ogg', repeat = TRUE, wait = FALSE, volume = 100, channel = alarm_channel))
	listeners = current_listeners

/datum/cryo_startup_effect/proc/stop()
	active = FALSE
	if(pulse_timer)
		deltimer(pulse_timer)
		pulse_timer = null
	if(stop_timer)
		deltimer(stop_timer)
		stop_timer = null
	for(var/client/listener in listeners)
		if(listener in GLOB.clients)
			sound_to(listener, sound(null, channel = alarm_channel))
	listeners.Cut()
	for(var/obj/machinery/light/fixture in fixtures)
		if(!QDELETED(fixture))
			fixture.refresh_light_emission()
	fixtures.Cut()
	rooms.Cut()

/datum/cryo_startup_effect/Destroy()
	stop()
	return ..()

//Main cryopod console.

/obj/machinery/computer/cryopod
	name = "cryogenic oversight console"
	desc = "An interface between crew and the cryogenic storage oversight systems."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "cellconsole"
	circuit = /obj/item/circuitboard/cryopodcontrol
	density = 0
	interact_offline = 1
	var/mode = null

	//Used for logging people entering cryosleep and important items they are carrying.
	var/list/frozen_crew = list()
	var/list/frozen_items = list()
	var/list/_admin_logs = list() // _ so it shows first in VV

	var/storage_type = "crewmembers"
	var/storage_name = "Cryogenic Oversight Control"
	var/allow_items = 1
	var/obj/machinery/cryopod/cryopod = null
	var/list/cryopods = list() //Linked cloning pods.

/obj/machinery/computer/cryopod/Initialize()
	..()
	update_module()

/obj/machinery/computer/cryopod/robot
	name = "robotic storage console"
	desc = "An interface between crew and the robotic storage systems."
	icon = 'icons/obj/robot_storage.dmi'
	icon_state = "console"
	circuit = /obj/item/circuitboard/robotstoragecontrol

	storage_type = "cyborgs"
	storage_name = "Robotic Storage Control"
	allow_items = 0

/obj/machinery/computer/cryopod/proc/update_module()
	src.cryopod = findcryo()
	releasecryo()
	findcryo()

/obj/machinery/computer/cryopod/proc/findcryo()
	var/obj/machinery/cryopod/cryopodf = null

	//Try to find scanner on adjacent tiles first
	for(dir in list(NORTH,EAST,SOUTH,WEST))
		cryopodf = locate(/obj/machinery/cryopod, get_step(src, dir))
		if (cryopodf)
			return cryopodf

	//Then look for a free one in the area
	if(!cryopodf)
		var/area/A = get_area(src)
		for(var/obj/machinery/cryopod/C in A.get_contents())
			return C

	return

/obj/machinery/computer/cryopod/proc/releasecryo()
	for(var/obj/machinery/cryopod/C in cryopods)
		C.connected = null
		C.name = initial(C.name)
	cryopods.Cut()

/obj/machinery/computer/cryopod/proc/connect_cryopod(var/obj/machinery/cryopod/C)
	if(C in cryopods)
		return 0

	if(C.connected)
		C.connected.release_cryopod(C)
	C.connected = src
	cryopods += C
	rename_cryopods()

	return 1

/obj/machinery/computer/cryopod/proc/release_cryopod(var/obj/machinery/cryopod/C)
	if(!(C in cryopods))
		return

	C.connected = null
	C.name = initial(C.name)
	cryopods -= C
	rename_cryopods()
	return 1

/obj/machinery/computer/cryopod/proc/rename_cryopods()
	for(var/i = 1 to cryopods.len)
		var/atom/C = cryopods[i]
		C.name = "[initial(C.name)] #[i]"

/obj/machinery/computer/cryopod/proc/findcryopod()
	var/num = 1
	var/area/A = get_area(src)
	for(var/obj/machinery/cryopod/C in A.get_contents())
		if(!C.connected)
			cryopods += C
			C.connected = src
			C.name = "[initial(C.name)] #[num++]"

/obj/machinery/computer/cryopod/attack_ai()
	src.attack_hand()

/obj/machinery/computer/cryopod/attack_hand(mob/user = usr)
	if(stat & (NOPOWER|BROKEN))
		return
	..()

	user.set_machine(src)

	var/dat

	dat += "<hr/><br/><b>[storage_name]</b><br/>"
	dat += "<i>Welcome, [user.real_name].</i><br/><br/><hr/>"
	dat += "<a href='?src=\ref[src];log=1'>View storage log</a>.<br>"
	dat += "<a href='?src=\ref[src];exit=1'>Eject the occupants</a>.<br>"
	if(allow_items)
		dat += "<a href='?src=\ref[src];view=1'>View objects</a>.<br>"
		dat += "<a href='?src=\ref[src];item=1'>Recover object</a>.<br>"
		dat += "<a href='?src=\ref[src];allitems=1'>Recover all objects</a>.<br>"

	var/page = ui_build_styled_html(storage_name, dat)
	user << browse(page, "window=cryopod_console")
	onclose(user, "cryopod_console")

/obj/machinery/computer/cryopod/OnTopic(user, href_list, state)
	if(href_list["log"])
		var/dat = "<b>Recently stored [storage_type]</b><br/><hr/><br/>"
		for(var/person in frozen_crew)
			dat += "[person]<br/>"
		dat += "<hr/>"
		show_browser(user, dat, "window=cryolog")
		. = TOPIC_REFRESH

	else if(href_list["view"])
		if(!allow_items) return

		var/dat = "<b>Recently stored objects</b><br/><hr/><br/>"
		for(var/obj/item/I in frozen_items)
			dat += "[I.name]<br/>"
		dat += "<hr/>"

	else if(href_list["exit"])

		var/area/A = get_area(cryopod)

		for(cryopod in A)
			if(!cryopod.occupant)
				to_chat(user, "<span class='notice'>There is nothing to exit the storage.</span>")
				return
			else
				cryopod.eject()

		. = TOPIC_REFRESH

	else if(href_list["item"])
		if(!allow_items) return

		if(frozen_items.len == 0)
			to_chat(user, "<span class='notice'>There is nothing to recover from storage.</span>")
			return TOPIC_HANDLED

		var/obj/item/I = input(user, "Please choose which object to retrieve.","Object recovery",null) as null|anything in frozen_items
		if(!I || !CanUseTopic(user, state))
			return TOPIC_HANDLED

		if(!(I in frozen_items))
			to_chat(user, "<span class='notice'>\The [I] is no longer in storage.</span>")
			return TOPIC_HANDLED

		visible_message("<span class='notice'>The console beeps happily as it disgorges \the [I].</span>", 3)

		I.dropInto(loc)
		frozen_items -= I
		. = TOPIC_REFRESH

	else if(href_list["allitems"])
		if(!allow_items) return TOPIC_HANDLED

		if(frozen_items.len == 0)
			to_chat(user, "<span class='notice'>There is nothing to recover from storage.</span>")
			return TOPIC_HANDLED

		visible_message("<span class='notice'>The console beeps happily as it disgorges the desired objects.</span>", 3)

		for(var/obj/item/I in frozen_items)
			I.dropInto(loc)
			frozen_items -= I
		. = TOPIC_REFRESH

	attack_hand(user)

/obj/item/circuitboard/cryopodcontrol
	name = "Circuit board (Cryogenic Oversight Console)"
	build_path = /obj/machinery/computer/cryopod
	origin_tech = list(TECH_DATA = 3)

/obj/item/circuitboard/robotstoragecontrol
	name = "Circuit board (Robotic Storage Console)"
	build_path = /obj/machinery/computer/cryopod/robot
	origin_tech = list(TECH_DATA = 3)

//Decorative structures to go alongside cryopods.
/obj/structure/cryofeed
	name = "cryogenic feed"
	desc = "A bewildering tangle of machinery and pipes."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "cryo_rear"
	anchored = 1
	dir = WEST
	layer = BELOW_OBJ_LAYER

//Cryopods themselves.
/obj/machinery/cryopod
	name = "cryogenic freezer"
	desc = "A man-sized pod for entering suspended animation."
	icon = 'icons/obj/machines/os13.dmi'
	icon_state = "cryochamber1" // Map editor preview; replaced by the layered visuals at runtime.
	density = 1
	anchored = 1
	dir = WEST

	var/base_icon_state = "cryochamber0"
	var/occupied_icon_state = "cryochamber1"
	// Builds the pod from layered parts with the occupant visible through the lid windows.
	var/layered_visuals = TRUE
	var/atom/movable/cryopod_visual/occupant_visual
	var/atom/movable/cryopod_visual/lid_visual
	var/lid_closed = FALSE
	var/releasing = FALSE // Lid is opening; the occupant is let out once the animation ends.
	var/last_occupant_appearance
	var/last_visual_dir
	var/on_store_message = "has entered long-term storage."
	var/on_store_name = "Cryogenic Oversight"
	var/on_enter_occupant_message = "You feel cool air surround you. You go numb as your senses turn inward."
	var/allow_occupant_types = list(/mob/living/carbon/human)
	var/disallow_occupant_types = list()

	var/mob/occupant = null       // Person waiting to be despawned.
	var/issue_joiner_access_card = FALSE
	var/time_till_despawn = 9000  // Down to 15 minutes //30 minutes-ish is too long
	var/time_entered = 0          // Used to keep track of the safe period.
	var/obj/item/device/radio/intercom/announce //

	var/obj/machinery/computer/cryopod/control_computer
	var/obj/machinery/computer/cryopod/connected = null //So we remember the connected cryopod.
	var/last_no_computer_message = 0
	var/applies_stasis = 1

	// These items are preserved when the process() despawn proc occurs.
	var/list/preserve_items = list(
		/obj/item/integrated_circuit/manipulation/bluespace_rift,
		/obj/item/integrated_circuit/input/teleporter_locator,
		/obj/item/card/id/captains_spare,
		/obj/item/aicard,
		/obj/item/device/mmi,
		/obj/item/device/paicard,
		/obj/item/weapon/gun,
		/obj/item/pinpointer,
		/obj/item/clothing/suit,
		/obj/item/clothing/shoes/magboots,
		/obj/item/blueprints,
		/obj/item/clothing/head/helmet/space,
		/obj/item/storage/internal
	)

/obj/machinery/cryopod/robot
	name = "robotic storage unit"
	desc = "A storage unit for robots."
	icon = 'icons/obj/robot_storage.dmi'
	icon_state = "pod_0"
	base_icon_state = "pod_0"
	occupied_icon_state = "pod_1"
	layered_visuals = FALSE
	on_store_message = "has entered robotic storage."
	on_store_name = "Robotic Storage Oversight"
	on_enter_occupant_message = "The storage unit broadcasts a sleep signal to you. Your systems start to shut down, and you enter low-power mode."
	allow_occupant_types = list(/mob/living/silicon/robot)
	disallow_occupant_types = list(/mob/living/silicon/robot/drone)
	applies_stasis = 0

/obj/machinery/cryopod/lifepod
	name = "life pod"
	desc = "A man-sized pod for entering suspended animation. Dubbed 'cryocoffin' by more cynical spacers, it is pretty barebone, counting on stasis system to keep the victim alive rather than packing extended supply of food or air. Can be ordered with symbols of common religious denominations to be used in space funerals too."
	on_store_name = "Life Pod Oversight"
	time_till_despawn = 20 MINUTES
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "redpod0"
	base_icon_state = "redpod0"
	occupied_icon_state = "redpod1"
	layered_visuals = FALSE
	var/launched = 0
	var/datum/gas_mixture/airtank

/obj/machinery/cryopod/lifepod/Initialize()
	. = ..()
	airtank = new()
	airtank.temperature = T0C
	airtank.adjust_gas("oxygen", MOLES_O2STANDARD, 0)
	airtank.adjust_gas("nitrogen", MOLES_N2STANDARD)

/obj/machinery/cryopod/lifepod/return_air()
	return airtank

/obj/machinery/cryopod/lifepod/proc/launch()
	launched = 1
	for(var/d in GLOB.cardinal)
		var/turf/T = get_step(src,d)
		var/obj/machinery/door/blast/B = locate() in T
		if(B && B.density)
			B.force_open()
			break

	var/list/possible_locations = list()
	if(GLOB.using_map.use_overmap)
		var/obj/effect/overmap/O = map_sectors["[z]"]
		for(var/obj/effect/overmap/OO in range(O,2))
			if(OO.in_space || istype(OO,/obj/effect/overmap/sector/exoplanet))
				possible_locations |= text2num(level)

	var/newz = GLOB.using_map.get_empty_zlevel()
	if(possible_locations.len && prob(10))
		newz = pick(possible_locations)
	var/turf/nloc = locate(rand(TRANSITIONEDGE, world.maxx-TRANSITIONEDGE), rand(TRANSITIONEDGE, world.maxy-TRANSITIONEDGE),newz)
	if(!istype(nloc, /turf/space))
		explosion(nloc, 1, 2, 3)
	playsound(loc,'sound/effects/rocket.ogg',100)
	forceMove(nloc)

//Don't use these for in-round leaving
/obj/machinery/cryopod/lifepod/Process()
	if(SSevac.evacuation_controller && SSevac.evacuation_controller.state >= EVAC_LAUNCHING)
		if(occupant && !launched)
			launch()
		..()

/obj/machinery/cryopod/New()
	announce = new /obj/item/device/radio/intercom(src)
	..()

/obj/machinery/cryopod/Destroy()
	if(occupant)
		occupant.forceMove(loc)
	remove_layered_visuals()
	return ..()

/obj/machinery/cryopod/Initialize()
	. = ..()
	find_control_computer()
	if(layered_visuals)
		setup_layered_visuals()
	update_icon()

/atom/movable/cryopod_visual
	name = ""
	mouse_opacity = 0
	anchored = TRUE
	simulated = FALSE
	appearance_flags = PIXEL_SCALE | KEEP_TOGETHER

GLOBAL_LIST_EMPTY(cryopod_occupant_masks)

/obj/machinery/cryopod/proc/setup_layered_visuals()
	icon = initial(icon)
	icon_state = base_icon_state
	appearance_flags |= KEEP_TOGETHER

	occupant_visual = new
	occupant_visual.vis_flags = VIS_INHERIT_PLANE
	occupant_visual.layer = layer + 0.001
	occupant_visual.dir = SOUTH

	lid_visual = new
	lid_visual.vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_DIR
	lid_visual.layer = layer + 0.002
	lid_visual.icon = icon
	lid_visual.icon_state = "cryopod_open"
	lid_visual.underlays += image(icon, "cryochamber0c")

	vis_contents += occupant_visual
	vis_contents += lid_visual
	lid_closed = FALSE

/obj/machinery/cryopod/proc/remove_layered_visuals()
	if(occupant_visual)
		vis_contents -= occupant_visual
		QDEL_NULL(occupant_visual)
	if(lid_visual)
		vis_contents -= lid_visual
		QDEL_NULL(lid_visual)
	last_occupant_appearance = null

/obj/machinery/cryopod/update_icon(var/instant = FALSE)
	if(!layered_visuals || !lid_visual)
		icon_state = occupant ? occupied_icon_state : base_icon_state
		return

	icon_state = base_icon_state
	refresh_occupant_visual()

	var/should_close = (occupant && !releasing) ? TRUE : FALSE
	if(should_close == lid_closed)
		return
	lid_closed = should_close
	lid_visual.icon_state = lid_closed ? "cryochamber1" : "cryopod_open"
	if(!instant)
		flick(lid_closed ? "cryopod_closing" : "cryopod_opening", lid_visual)

// Shows a copy of the occupant lying at 45 degrees inside the pod, clipped to the pod's silhouette.
/obj/machinery/cryopod/proc/refresh_occupant_visual(var/force = FALSE)
	if(!occupant_visual)
		return
	if(!occupant || occupant.invisibility)
		if(last_occupant_appearance)
			occupant_visual.overlays.Cut()
			last_occupant_appearance = null
		return
	if(!force && occupant.appearance == last_occupant_appearance && dir == last_visual_dir)
		return
	last_occupant_appearance = occupant.appearance
	last_visual_dir = dir

	// The SOUTH/WEST sprites put the headrest at the upper left; NORTH/EAST mirror it.
	var/mirrored = (dir == NORTH || dir == EAST)
	var/matrix/M = matrix()
	M.Scale(0.8)
	M.Turn(mirrored ? 45 : -45)
	M.Translate(mirrored ? -2 : 2, 0)

	var/mutable_appearance/MA = new(occupant)
	MA.name = ""
	MA.plane = FLOAT_PLANE
	MA.layer = FLOAT_LAYER
	MA.dir = SOUTH
	MA.mouse_opacity = 0
	MA.invisibility = 0
	MA.render_target = null
	MA.filters = null
	MA.appearance_flags = PIXEL_SCALE | KEEP_TOGETHER
	MA.pixel_x = 0
	MA.pixel_y = 0
	MA.transform = M
	// Overlays on their own planes (glows, emissives) would escape the mask and render above the lid.
	var/list/kept_overlays = list()
	for(var/overlay in MA.overlays)
		var/mutable_appearance/O = overlay
		if(O.plane == FLOAT_PLANE || O.plane == DEFAULT_PLANE)
			kept_overlays += overlay
	MA.overlays = kept_overlays

	occupant_visual.overlays.Cut()
	occupant_visual.overlays += MA
	occupant_visual.filters = filter(type = "alpha", icon = get_cryopod_occupant_mask(icon, dir))

/proc/get_cryopod_occupant_mask(var/mask_icon, var/mask_dir)
	var/key = "[mask_icon]-[mask_dir]"
	var/icon/mask = GLOB.cryopod_occupant_masks[key]
	if(!mask)
		mask = icon(mask_icon, "cryochamber0", mask_dir)
		GLOB.cryopod_occupant_masks[key] = mask
	return mask

/obj/machinery/cryopod/proc/find_control_computer(urgent=0)
	// Workaround for http://www.byond.com/forum/?post=2007448
	for(var/obj/machinery/computer/cryopod/C in src.loc.loc)
		control_computer = C
		break
	// control_computer = locate(/obj/machinery/computer/cryopod) in src.loc.loc

	// Don't send messages unless we *need* the computer, and less than five minutes have passed since last time we messaged
	if(!control_computer && urgent && last_no_computer_message + 5*60*10 < world.time)
		log_admin("Cryopod in [src.loc.loc] could not find control computer!")
		message_admins("Cryopod in [src.loc.loc] could not find control computer!")
		last_no_computer_message = world.time

	return control_computer != null

/obj/machinery/cryopod/proc/check_occupant_allowed(mob/M)
	var/correct_type = 0
	for(var/type in allow_occupant_types)
		if(istype(M, type))
			correct_type = 1
			break

	if(!correct_type) return 0

	for(var/type in disallow_occupant_types)
		if(istype(M, type))
			return 0

	return 1

//Lifted from Unity stasis.dm and refactored. ~Zuhayr
/obj/machinery/cryopod/Process()
	if(occupant)
		// Keep the visible occupant in sync with clothing/damage changes (e.g. latejoiners still being equipped).
		refresh_occupant_visual()

		if(releasing)
			return

		//Allow a ten minute gap between entering the pod and actually despawning.
		if(world.time - time_entered < time_till_despawn)
			return

		if(!occupant.client && occupant.stat<2) //Occupant is living and has no client.
			if(!control_computer)
				if(!find_control_computer(urgent=1))
					return

			despawn_occupant()

// This function can not be undone; do not call this unless you are sure
// Also make sure there is a valid control computer
/obj/machinery/cryopod/robot/despawn_occupant()
	var/mob/living/silicon/robot/R = occupant
	if(!istype(R)) return ..()

	qdel(R.mmi)
	for(var/obj/item/I in R.module) // the tools the borg has; metal, glass, guns etc
		for(var/obj/item/O in I) // the things inside the tools, if anything; mainly for janiborg trash bags
			O.forceMove(R)
		qdel(I)
	qdel(R.module)

	return ..()

// This function can not be undone; do not call this unless you are sure
// Also make sure there is a valid control computer
/obj/machinery/cryopod/proc/despawn_occupant()
	//Drop all items into the pod.
	for(var/obj/item/W in occupant)
		occupant.drop_from_inventory(W)
		W.forceMove(src)

		if(W.contents.len) //Make sure we catch anything not handled by qdel() on the items.
			for(var/obj/item/O in W.contents)
				if(istype(O,/obj/item/storage/internal)) //Stop eating pockets, you fuck!
					continue
				O.forceMove(src)

	//Delete all items not on the preservation list.
	var/list/items = src.contents.Copy()
	items -= occupant // Don't delete the occupant
	items -= announce // or the autosay radio.

	for(var/obj/item/W in items)

		var/preserve = null
		// Snowflaaaake.
		if(istype(W, /obj/item/device/mmi))
			var/obj/item/device/mmi/brain = W
			if(brain.brainmob && brain.brainmob.client && brain.brainmob.key)
				preserve = 1
			else
				continue
		else
			for(var/T in preserve_items)
				if(istype(W,T))
					preserve = 1
					break

		if(!preserve)
			qdel(W)
		else
			if(control_computer && control_computer.allow_items)
				control_computer.frozen_items += W
				W.loc = null
			else
				W.forceMove(src.loc)

	//Update any existing objectives involving this mob.
	for(var/datum/objective/O in all_objectives)
		// We don't want revs to get objectives that aren't for heads of staff. Letting
		// them win or lose based on cryo is silly so we remove the objective.
		if(O.target == occupant.mind)
			if(O.owner && O.owner.current)
				to_chat(O.owner.current, "<span class='warning'>You get the feeling your target is no longer within your reach...</span>")
			qdel(O)

	//Handle job slot/tater cleanup.
	if(occupant.mind)
		var/job = occupant.mind.assigned_role
		job_master.FreeRole(job)

		if(occupant.mind.objectives.len)
			occupant.mind.objectives = null
			occupant.mind.special_role = null

	// Delete them from datacore.
	var/datum/computer_file/crew_record/R = get_crewmember_record(occupant.real_name)
	if(R)
		qdel(R)

	//TODO: Check objectives/mode, update new targets if this mob is the target, spawn new antags?


	//Make an announcement and log the person entering storage.

	// Titles should really be fetched from data records
	//  and records should not be fetched by name as there is no guarantee names are unique
	var/role_alt_title = occupant.mind ? occupant.mind.role_alt_title : "Unknown"

	if(control_computer)
		control_computer.frozen_crew += "[occupant.real_name], [role_alt_title] - [stationtime2text()]"
		control_computer._admin_logs += "[key_name(occupant)] ([role_alt_title]) at [stationtime2text()]"
	log_and_message_admins("[key_name(occupant)] ([role_alt_title]) entered cryostorage.")

	announce.autosay("[occupant.real_name], [role_alt_title], [on_store_message]", "[on_store_name]")
	visible_message("<span class='notice'>\The [initial(name)] hums and hisses as it moves [occupant.real_name] into storage.</span>", 3)

	//This should guarantee that ghosts don't spawn.
	occupant.ckey = null

	// Delete the mob.
	qdel(occupant)
	set_occupant(null)


/obj/machinery/cryopod/attackby(var/obj/item/weapon/G as obj, var/mob/user as mob)

	if(istype(G, /obj/item/grab))
		var/obj/item/grab/grab = G
		if(occupant)
			to_chat(user, "<span class='notice'>\The [src] is in use.</span>")
			return

		if(!ismob(grab.affecting))
			return

		if(!check_occupant_allowed(grab.affecting))
			return

		var/willing = null //We don't want to allow people to be forced into despawning.
		var/mob/M = grab.affecting

		if(M.client)
			if(alert(M,"Would you like to enter long-term storage?",,"Yes","No") == "Yes")
				if(!M || !grab || !grab.affecting) return
				willing = 1
		else
			willing = 1

		if(willing)

			visible_message("[user] starts putting [grab.affecting:name] into \the [src].", 3)

			if(do_after(user, 20, src))
				if(!M || !grab || !grab.affecting) return

			qdel(grab)
			set_occupant(M)

			// Book keeping!
			var/turf/location = get_turf(src)
			log_admin("[key_name_admin(M)] has entered a stasis pod. (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[location.x];Y=[location.y];Z=[location.z]'>JMP</a>)")
			message_admins("<span class='notice'>[key_name_admin(M)] has entered a stasis pod.</span>")

			//Despawning occurs when process() is called with an occupant without a client.
			src.add_fingerprint(M)

/obj/machinery/cryopod/verb/eject()
	set name = "Eject Pod"
	set category = "Object"
	set hidden = 1
	set src in oview(1)
	if(usr.stat != 0)
		return

	//Eject any items that aren't meant to be in the pod.
	var/list/items = src.contents
	if(occupant) items -= occupant
	if(announce) items -= announce

	for(var/obj/item/W in items)
		W.forceMove(get_turf(src))
	src.go_out()
	update_icon()
	add_fingerprint(usr)

	SetName("[name]")
	return

/obj/machinery/cryopod/proc/manual_eject()
	//Eject any items that aren't meant to be in the pod.
	var/list/items = src.contents
	if(occupant) items -= occupant
	if(announce) items -= announce

	for(var/obj/item/W in items)
		W.forceMove(get_turf(src))
	src.go_out()
	update_icon()
	add_fingerprint(usr)

	SetName("[name]")
	return

/obj/machinery/cryopod/verb/move_inside()
	set name = "Enter Pod"
	set category = "Object"
	set src in oview(1)
	set hidden = 1

	if(usr.stat != 0 || !check_occupant_allowed(usr))
		return

	if(src.occupant)
		to_chat(usr, "<span class='notice'><B>\The [src] is in use.</B></span>")
		return

	for(var/mob/living/carbon/slime/M in range(1,usr))
		if(M.Victim == usr)
			to_chat(usr, "You're too busy getting your life sucked out of you.")
			return

	visible_message("[usr] starts climbing into \the [src].", 3)

	if(do_after(usr, 20, src))

		if(!usr || !usr.client)
			return

		if(src.occupant)
			to_chat(usr, "<span class='notice'><B>\The [src] is in use.</B></span>")
			return

		set_occupant(usr)

		src.add_fingerprint(usr)
		playsound(src, 'sound/machines/cryoenter.ogg', 40)

	return

/obj/machinery/cryopod/proc/go_out()

	if(!occupant)
		playsound(src, 'sound/machines/button11.ogg', 40)
		return

	if(do_after(usr, 30, src) && occupant)
		start_release()

	return

/obj/machinery/cryopod/proc/go_out_forced()

	if(!occupant)
		playsound(src, 'sound/machines/button11.ogg', 40)
		return

	start_release()

	return

#define CRYOPOD_LID_OPEN_TIME 5 // Total frame delay of the "cryopod_opening" state.

// Opens the lid and only lets the occupant out once the opening animation has finished.
/obj/machinery/cryopod/proc/start_release()
	if(releasing || !occupant)
		return
	playsound(src, 'sound/machines/cryoexit.ogg', 40)
	if(!layered_visuals || !lid_visual || !lid_closed)
		release_occupant()
		return
	releasing = TRUE
	lid_closed = FALSE
	lid_visual.icon_state = "cryopod_open"
	flick("cryopod_opening", lid_visual)
	addtimer(CALLBACK(src, /obj/machinery/cryopod/proc/release_occupant), CRYOPOD_LID_OPEN_TIME)

#undef CRYOPOD_LID_OPEN_TIME

/obj/machinery/cryopod/proc/release_occupant()
	releasing = FALSE
	if(QDELETED(src))
		return
	if(!occupant)
		update_icon()
		return

	if(occupant.client)
		occupant.client.eye = src.occupant.client.mob
		occupant.client.perspective = MOB_PERSPECTIVE

	occupant.forceMove(get_turf(src))
	occupant.resting = TRUE
	occupant.update_canmove()
	occupant.fatigue = occupant.max_fatigue
	if(isliving(occupant))
		var/mob/living/released_occupant = occupant
		released_occupant.update_stamina_hud()
		released_occupant.fade_cryo_filter_effect()
	if(issue_joiner_access_card && ishuman(occupant))
		dispense_joiner_access_card(occupant)
	set_occupant(null)

/obj/machinery/cryopod/proc/dispense_joiner_access_card(var/mob/living/carbon/human/joiner)
	var/datum/job/job = job_master.GetJob(joiner.job)
	if(!job)
		WARNING("Cryopod could not issue an access card for [joiner.real_name], job [joiner.job].")
		to_chat(joiner, "<span class='warning'>The cryopod could not determine your role and failed to dispense a temporary access card. Please contact an administrator.</span>")
		return

	var/obj/item/card/id/cryo_temporary/card = new(get_turf(src))
	card.rank = job.title
	card.assignment = (joiner.mind && joiner.mind.role_alt_title) ? joiner.mind.role_alt_title : job.title
	card.access = job.get_access()
	joiner.set_id_info(card)
	card.add_fingerprint(joiner)
	if(!joiner.equip_to_slot_if_possible(card, slot_wear_id, disable_warning = TRUE))
		if(!joiner.put_in_hands(card))
			card.forceMove(get_turf(src))
			to_chat(joiner, "<span class='notice'>Your temporary access card falls onto the floor beside the cryopod.</span>")
	to_chat(joiner, "<span class='notice'>The cryopod dispenses a temporary access card for your role: [card.assignment]. It is dissolving in the air and will disappear in three minutes.</span>")

// instant: show the pod already closed instead of animating the lid (e.g. latejoiners spawning inside).
/obj/machinery/cryopod/proc/set_occupant(var/mob/living/carbon/occupant, var/instant = FALSE, var/joining = FALSE)
	src.occupant = occupant
	issue_joiner_access_card = occupant && joining
	if(!occupant)
		SetName(initial(name))
		update_icon()
		return

	occupant.stop_pulling()
	if(occupant.client)
		occupant.client.perspective = EYE_PERSPECTIVE
		occupant.client.eye = src
	occupant.forceMove(src)
	time_entered = world.time

	if(occupant)
		SetName("[name] ([occupant])")
	else
		SetName("[name]")
	update_icon(instant)
