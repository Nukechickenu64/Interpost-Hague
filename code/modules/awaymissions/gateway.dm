/obj/machinery/gateway
	name = "gateway"
	desc = "A mysterious gateway built by unknown hands. Its active portal leads to Hell."
	icon = 'icons/obj/machines/gateway.dmi'
	icon_state = "off"
	density = 1
	anchored = 1
	var/active = 0


/obj/machinery/gateway/Initialize()
	update_icon()
	if(dir == SOUTH)
		set_density(0)
	. = ..()

/obj/machinery/gateway/update_icon()
	if(active)
		icon_state = "on"
		return
	icon_state = "off"


// The station gateway is assembled from this centre and the eight surrounding frame pieces.
/obj/machinery/gateway/centerstation
	density = 1
	icon_state = "offcenter"

	var/list/linked = list()
	var/ready = 0
	var/wait = 0
	var/obj/effect/portal/hell_portal = null
	var/turf/hell_arrival_turf = null

/obj/machinery/gateway/centerstation/Initialize()
	update_icon()
	wait = world.time + config.gateway_delay
	. = ..()

/obj/machinery/gateway/centerstation/Destroy()
	clear_hell_portal()
	return ..()

/obj/machinery/gateway/centerstation/update_icon()
	if(active)
		icon_state = "oncenter"
		return
	icon_state = "offcenter"


obj/machinery/gateway/centerstation/Process()
	if(stat & NOPOWER)
		if(active)
			toggleoff()
		return

	if(active)
		use_power_oneoff(5000)


/obj/machinery/gateway/centerstation/proc/detect()
	linked = list()
	var/turf/T = loc

	for(var/i in GLOB.alldirs)
		T = get_step(loc, i)
		var/obj/machinery/gateway/G = locate(/obj/machinery/gateway) in T
		if(G)
			linked.Add(G)
			continue

		ready = 0
		toggleoff()
		break

	if(linked.len == 8)
		ready = 1


/obj/machinery/gateway/centerstation/proc/toggleon(mob/user as mob)
	if(!ready)			return
	if(linked.len != 8)	return
	if(!powered())		return
	if(world.time < wait)
		to_chat(user, "<span class='notice'>Error: Warpspace triangulation in progress. Estimated time to completion: [round(((wait - world.time) / 10) / 60)] minutes.</span>")
		return
	if(!create_hell_portal())
		to_chat(user, "<span class='notice'>Error: No safe Hell destination found.</span>")
		return

	for(var/obj/machinery/gateway/G in linked)
		G.active = 1
		G.update_icon()
	active = 1
	update_icon()


/obj/machinery/gateway/centerstation/proc/toggleoff()
	clear_hell_portal()
	for(var/obj/machinery/gateway/G in linked)
		G.active = 0
		G.update_icon()
	active = 0
	update_icon()


/obj/machinery/gateway/centerstation/proc/create_hell_portal()
	clear_hell_portal()

	var/list/destinations = list()
	find_hell_portal_destinations(destinations)
	if(!destinations.len)
		return FALSE

	var/turf/portal_turf = pick(destinations)
	hell_arrival_turf = destinations[portal_turf]
	hell_portal = new /obj/effect/portal(portal_turf, get_step(loc, SOUTH), 0)
	hell_portal.creator = src
	return TRUE



/obj/machinery/gateway/centerstation/proc/find_hell_portal_destinations(list/destinations)
	var/turf/arrival_turf
	for(var/turf/simulated/floor/helldirt/T in world)
		if(!is_open_hell_turf(T))
			continue
		arrival_turf = get_open_hell_adjacent_turf(T)
		if(arrival_turf)
			destinations[T] = arrival_turf

	for(var/turf/simulated/floor/hellslate/T in world)
		if(!is_open_hell_turf(T))
			continue
		arrival_turf = get_open_hell_adjacent_turf(T)
		if(arrival_turf)
			destinations[T] = arrival_turf


/obj/machinery/gateway/centerstation/proc/is_open_hell_turf(turf/T)
	if(!T || T.density || turf_contains_dense_objects(T))
		return FALSE
	return istype(T, /turf/simulated/floor/helldirt) || istype(T, /turf/simulated/floor/hellslate)


/obj/machinery/gateway/centerstation/proc/get_open_hell_adjacent_turf(turf/T)
	var/list/open_turfs = list()
	for(var/direction in GLOB.cardinal)
		var/turf/candidate = get_step(T, direction)
		if(is_open_hell_turf(candidate))
			open_turfs += candidate
	if(open_turfs.len)
		return pick(open_turfs)


/obj/machinery/gateway/centerstation/proc/clear_hell_portal()
	if(hell_portal)
		qdel(hell_portal)
	hell_portal = null
	hell_arrival_turf = null


/obj/machinery/gateway/centerstation/attack_hand(mob/user as mob)
	if(!ready)
		detect()
		return
	if(!active)
		toggleon(user)
		return
	toggleoff()


// Travellers arrive beside the return portal so they do not immediately step through it.
/obj/machinery/gateway/centerstation/Bumped(atom/movable/M as mob|obj)
	if(!ready || !active || !hell_portal || !hell_arrival_turf)
		return
	M.loc = hell_arrival_turf
	M.set_dir(SOUTH)
	use_power_oneoff(5000)


/obj/machinery/gateway/centerstation/attackby(obj/item/device/W as obj, mob/user as mob)
	if(isMultitool(W))
		to_chat(user, "The gate is already calibrated, there is no work for you to do here.")
		return
