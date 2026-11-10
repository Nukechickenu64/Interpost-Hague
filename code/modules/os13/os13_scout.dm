/proc/os13_scout_is_onboard(atom/terminal, datum/mining_expedition_controller/controller)
	var/datum/shuttle/autodock/shuttle = controller?.get_shuttle()
	return shuttle && (get_area(terminal) in shuttle.shuttle_area)

// PIL 00:05:40: two inward-facing rows of passenger seats beside the aisle.
// Keep the supplied seat and restraint sprites separate so the harness is
// drawn over the passenger, without drawing the seat itself over their body.
/obj/structure/sofa/os13_scout
	name = "Scout passenger seat"
	desc = "A restrained passenger seat aboard the Scout."
	icon = 'icons/os13/objects/objects/weapons/objects.dmi'
	icon_state = "shuttle"
	dir = EAST
	buckle_lying = FALSE

/obj/structure/sofa/os13_scout/Initialize()
	. = ..()
	update_icon()

/obj/structure/sofa/os13_scout/update_icon()
	layer = OBJ_LAYER
	overlays.Cut()
	if(buckled_mob)
		var/image/restraint = overlay_image(icon, "shuttle_overlay", layer = ABOVE_HUMAN_LAYER)
		restraint.dir = dir
		overlays += restraint

/obj/structure/sofa/os13_scout/post_buckle_mob(mob/living/occupant)
	..()
	update_icon()

/obj/structure/sofa/os13_scout/set_dir()
	. = ..()
	if(buckled_mob)
		buckled_mob.set_dir(dir)
	update_icon()

/proc/os13_scout_controller(atom/terminal)
	if(istype(terminal, /obj/machinery/computer/os13_scout_controls/lifeboat))
		var/area/shuttle/lifeboat/cabin = get_area(terminal)
		return istype(cabin) ? cabin.shuttle?.controller : null
	for(var/datum/mining_expedition_controller/civ13/controller in civ13_mining_expeditions)
		if(!QDELETED(controller) && os13_scout_is_onboard(terminal, controller))
			return controller
	return get_mining_expedition()

/proc/os13_scout_can_use(obj/machinery/computer/terminal, mob/user, datum/mining_expedition_controller/controller, local_only = FALSE)
	if(QDELETED(terminal) || QDELETED(controller) || !controller?.get_shuttle())
		to_chat(user, SPAN_WARNING("UNABLE TO ESTABLISH LINK WITH THE SHUTTLE."))
		return FALSE
	// Adjacency expects the operator as neighbor so their chair is ignored.
	if(terminal.inoperable() || user.incapacitated() || !terminal.Adjacent(user))
		to_chat(user, SPAN_WARNING("Scout connection interrupted. Remain beside an operational console."))
		return FALSE
	if(os13_scout_controller(terminal) != controller)
		to_chat(user, SPAN_WARNING("Scout connection changed. Open the console again."))
		return FALSE
	var/onboard = os13_scout_is_onboard(terminal, controller)
	if(local_only && !onboard)
		to_chat(user, SPAN_WARNING("Scout Controls must be installed aboard the linked shuttle."))
		return FALSE
	if(onboard)
		if(!terminal.check_mapper_access(user.GetAccess(), access_mining in user.GetAccess()))
			to_chat(user, SPAN_WARNING("ACCESS DENIED: Pilot authorization required."))
			return FALSE
	else
		if(!terminal.check_mapper_access(user.GetAccess(), access_heads in user.GetAccess()))
			to_chat(user, SPAN_WARNING("ACCESS DENIED: Command authorization required."))
			return FALSE
		if(controller.remote_forbidden)
			to_chat(user, SPAN_WARNING("REMOTE CONTROL LOCKED BY SHUTTLE."))
			return FALSE
	return TRUE

/obj/machinery/computer/os13_scout_controls/examine(mob/user)
	. = ..()
	var/datum/mining_expedition_controller/controller = os13_scout_controller(src)
	if(!os13_scout_is_onboard(src, controller))
		to_chat(user, SPAN_WARNING("These controls are not installed aboard a linked Scout."))
		return
	var/datum/shuttle/autodock/shuttle = controller.get_shuttle()
	if(shuttle.moving_status == SHUTTLE_INTRANSIT)
		to_chat(user, SPAN_NOTICE("We're flying!"))
	to_chat(user, SPAN_NOTICE(html_encode(controller.status_text())))

/proc/os13_scout_distress_sites(datum/mining_expedition_controller/controller)
	var/list/sites = list()
	var/datum/shuttle/autodock/shuttle = controller.get_shuttle()
	if(!shuttle)
		return sites
	for(var/tag in SSshuttle.registered_shuttle_landmarks)
		var/obj/effect/shuttle_landmark/site = SSshuttle.registered_shuttle_landmarks[tag]
		if(QDELETED(site) || !istype(site))
			continue
		if(tag != "nav_mining_sos" && findtext(tag, "nav_mining_ruin_") != 1)
			continue
		if(site.shuttle_restricted && site.shuttle_restricted != shuttle.name)
			continue
		if(!controller.can_visit(site))
			continue
		sites["[site.name] ([tag])"] = site
	return sites

/obj/machinery/computer/os13_scout_controls/OnTopic(mob/user, list/href_list)
	var/datum/mining_expedition_controller/controller = os13_scout_controller(src)
	if(!os13_scout_can_use(src, user, controller, TRUE))
		return TOPIC_HANDLED
	if(href_list["scout_controller"] != "\ref[controller]")
		to_chat(user, SPAN_WARNING("Scout navigation link is stale. Open the controls again."))
		return TOPIC_HANDLED
	if(controller.handle_menu_action(user, href_list))
		playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)
		controller.show_local_menu(user, src)
	else
		to_chat(user, SPAN_WARNING("Unknown Scout navigation request."))
	return TOPIC_HANDLED

/obj/machinery/computer/os13_scout/proc/search_distress(mob/user, datum/mining_expedition_controller/controller)
	var/list/sites = os13_scout_distress_sites(controller)
	var/signal_number = 0
	for(var/obj/item/device/os13_distress_beacon/beacon in GLOB.os13_distress_beacons)
		if(beacon.signal_available() && !os13_scout_is_onboard(beacon, controller))
			signal_number++
			sites["Distress Beacon signal [signal_number]"] = beacon
	if(!sites.len)
		last_message = "NO DISTRESS SIGNALS FOUND."
		to_chat(user, SPAN_NOTICE(last_message))
		return
	to_chat(user, SPAN_NOTICE("Registered distress/ruin landing signals: [sites.len]."))
	var/selection = input(user, "Select a registered signal to plot a course.", "Scout Distress Signals") as null|anything in sites
	if(!selection)
		return
	if(!os13_scout_can_use(src, user, controller))
		return
	var/atom/selected_signal = sites[selection]
	if(istype(selected_signal, /obj/item/device/os13_distress_beacon))
		var/obj/item/device/os13_distress_beacon/beacon = selected_signal
		if(QDELETED(beacon) || !beacon.signal_available())
			to_chat(user, SPAN_WARNING("DISTRESS SIGNAL LOST."))
			return
		var/datum/shuttle/autodock/shuttle = controller.get_shuttle()
		if(!controller.shuttle_is_idle(shuttle) || controller.mission_pending)
			to_chat(user, SPAN_WARNING("THE SHUTTLE IS BUSY."))
			return
		var/obj/effect/shuttle_landmark/os13_rescue/approach = beacon.rescue_waypoint(controller)
		if(!approach)
			to_chat(user, SPAN_WARNING("DISTRESS SIGNAL RECEIVED, BUT NO CLEAR SCOUT APPROACH IS AVAILABLE."))
			return
		if(controller.dispatch(approach, user))
			last_message = "RESCUE COURSE PLOTTED: DISTRESS BEACON"
		else
			qdel(approach)
		return
	var/obj/effect/shuttle_landmark/site = selected_signal
	var/list/current_sites = os13_scout_distress_sites(controller)
	if(QDELETED(site) || current_sites[selection] != site)
		to_chat(user, SPAN_WARNING("DISTRESS SIGNAL LOST."))
		return
	var/datum/shuttle/autodock/shuttle = controller.get_shuttle()
	if(!controller.shuttle_is_idle(shuttle) || controller.mission_pending)
		to_chat(user, SPAN_WARNING("THE SHUTTLE IS BUSY."))
		return
	if(!site.is_valid(shuttle))
		to_chat(user, SPAN_WARNING("DISTRESS LANDING SITE IS OBSTRUCTED OR UNAVAILABLE."))
		return
	if(controller.dispatch(site, user))
		last_message = "COURSE PLOTTED: [site.name]"
