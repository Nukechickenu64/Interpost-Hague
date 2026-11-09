GLOBAL_LIST_EMPTY(cyberdeck_instances)

#define CYBERDECK_MIN_INSTANCES 4

// Called by mapping before atom, lighting and Z-copy initialization. World
// expansion must never happen on the Boot Level interaction path.
/proc/initialize_cyberdeck_instances()
	if(GLOB.cyberdeck_instances.len)
		return TRUE
	if(SSmapping.initialized)
		return FALSE
	var/max_size = cyberdeck_map_size(CYBERDECK_MAX_LEVEL)
	if(max_size + 4 > world.maxx || max_size + 4 > world.maxy)
		report_progress("Cyberspace archives unavailable: the map is too small.")
		return FALSE
	var/console_count = 0
	for(var/obj/machinery/computer/cyberdeck/C in world)
		console_count++
	var/slot_count = max(CYBERDECK_MIN_INSTANCES, console_count)
	var/first_z = world.maxz + 1
	report_progress("Preparing [slot_count] reusable cyberspace z-levels...")
	world.maxz += slot_count
	for(var/slot = 0, slot < slot_count, slot++)
		var/datum/cyberdeck_instance/I = new
		I.z_level = first_z + slot
		I.archive_area = new
		I.origin_x = max(2, round((world.maxx - max_size) / 2))
		I.origin_y = max(2, round((world.maxy - max_size) / 2))
		GLOB.using_map.player_levels |= I.z_level
		GLOB.using_map.base_turf_by_z[num2text(I.z_level)] = /turf/unsimulated/wall/cyberdeck
		for(var/x = 0, x < max_size, x++)
			for(var/y = 0, y < max_size, y++)
				var/turf/T = locate(I.origin_x + x, I.origin_y + y, I.z_level)
				I.archive_area.contents.Add(T)
				// These empty startup turfs will receive their normal initialization
				// with the rest of the map; no live ChangeTurf side effects are needed.
				new /turf/unsimulated/wall/cyberdeck(T)
				CHECK_TICK
		I.prepared = TRUE
		GLOB.cyberdeck_instances += I
	report_progress("Prepared [slot_count] cyberspace z-levels for research dives.")
	return TRUE

/proc/cyberdeck_map_size(level)
	return 13 + 2 * clamp(round(level), 1, CYBERDECK_MAX_LEVEL)

/proc/acquire_cyberdeck_instance()
	for(var/datum/cyberdeck_instance/I in GLOB.cyberdeck_instances)
		if(I.prepared && !I.busy)
			I.busy = TRUE
			return I
	return null

/area/cyberdeck_archive
	name = "Cyberspace research archive"
	requires_power = FALSE
	dynamic_lighting = FALSE
	luminosity = 1
	has_gravity = TRUE
	base_turf = /turf/unsimulated/wall/cyberdeck

/turf/unsimulated/wall/cyberdeck
	name = "firewall"
	desc = "The sealed boundary of a virtual research archive."
	icon = 'icons/misc/newcyber.dmi'
	icon_state = "beam0"

/turf/unsimulated/wall/cyberdeck/Initialize(mapload)
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		name = "ICE barrier"
		desc = "A solid block of virtual ICE."
		icon = 'icons/os13/objects/objects/newcyber.dmi'
		icon_state = "ice"

/turf/unsimulated/wall/cyberdeck/CanPass(atom/movable/mover, turf/target, height = 1.5, air_group = 0)
	if(istype(mover, /mob/living/simple_animal/cyber_avatar))
		var/mob/living/simple_animal/cyber_avatar/V = mover
		var/obj/machinery/computer/cyberdeck/C = V.master_console
		if(!QDELETED(C) && C.instance && C.instance.can_traverse_ice(src, V))
			return TRUE
	return ..()

/turf/unsimulated/floor/cyberdeck
	name = "data pathway"
	desc = "A flat expanse of virtual memory."
	icon = 'icons/misc/newcyber.dmi'
	icon_state = "black_ice"

/turf/unsimulated/floor/cyberdeck/Initialize(mapload)
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		icon = 'icons/os13/mob/mob/HUD/grid.dmi'
		icon_state = "1"

// A slot owns one isolated z-level. Slots are reused, never shared by active dives.
/datum/cyberdeck_instance
	var/prepared = FALSE
	var/busy = FALSE
	var/generating = FALSE
	var/cancelled = FALSE
	var/z_level
	var/size
	var/origin_x
	var/origin_y
	var/area/cyberdeck_archive/archive_area
	var/turf/entry_turf
	var/list/floors = list()
	var/list/nodes = list()
	var/list/guardian_trail = list()
	var/list/cells = list()
	var/required_keys
	var/decrypted = 0
	var/destroyed_data = 0
	var/collection_mode = FALSE
	var/obj/machinery/computer/cyberdeck/owner
	var/generation = 0

/datum/cyberdeck_instance/proc/cell_index(x, y)
	return (y - 1) * size + x

// OS13 uses open data fields; other maps retain a connected depth-first maze.
/datum/cyberdeck_instance/proc/build_layout(level)
	destroyed_data = 0
	size = cyberdeck_map_size(level)
	cells = new/list(size * size)
	if(collection_mode)
		// Separated ICE islands leave connected lanes between every cluster.
		for(var/x = 2, x < size, x++)
			for(var/y = 2, y < size, y++)
				cells[cell_index(x, y)] = TRUE
		for(var/x = 4, x < size - 2, x += 4)
			for(var/y = 4, y < size - 2, y += 4)
				if(!prob(65))
					continue
				var/width = rand(1, 2)
				var/height = rand(1, 2)
				for(var/dx = 0, dx < width, dx++)
					for(var/dy = 0, dy < height, dy++)
						cells[cell_index(x + dx, y + dy)] = FALSE
		required_keys = 10
		decrypted = 0
		return
	var/list/stack = list(list(2, 2))
	cells[cell_index(2, 2)] = TRUE
	while(stack.len)
		var/list/current = stack[stack.len]
		var/list/choices = list()
		for(var/direction in GLOB.cardinal)
			var/nx = current[1] + (direction == EAST ? 2 : direction == WEST ? -2 : 0)
			var/ny = current[2] + (direction == NORTH ? 2 : direction == SOUTH ? -2 : 0)
			if(nx > 1 && nx < size && ny > 1 && ny < size && !cells[cell_index(nx, ny)])
				choices += list(list(nx, ny))
		if(!choices.len)
			stack.len--
			continue
		var/list/next = pick(choices)
		cells[cell_index((current[1] + next[1]) / 2, (current[2] + next[2]) / 2)] = TRUE
		cells[cell_index(next[1], next[2])] = TRUE
		stack += list(next)
	// Occasional loops offer shortcuts without disconnecting any research nodes.
	for(var/x = 2, x < size, x++)
		for(var/y = 2, y < size, y++)
			if(!cells[cell_index(x, y)] && prob(8) && ((cells[cell_index(x - 1, y)] && cells[cell_index(x + 1, y)]) || (cells[cell_index(x, y - 1)] && cells[cell_index(x, y + 1)])))
				cells[cell_index(x, y)] = TRUE
	required_keys = 1 + ceil(level / 4)
	decrypted = 0

/datum/cyberdeck_instance/proc/generate(level, obj/machinery/computer/cyberdeck/console)
	if(!prepared || !busy || generating || owner || !z_level || !archive_area || QDELETED(console))
		return FALSE
	generating = TRUE
	cancelled = FALSE
	owner = console
	generation++
	collection_mode = istype(GLOB.using_map, /datum/map/alpha)
	build_layout(level)
	if(size + 4 > world.maxx || size + 4 > world.maxy)
		generating = FALSE
		release()
		return FALSE
	try
		for(var/x = 1, x <= size, x++)
			for(var/y = 1, y <= size, y++)
				var/turf/T = locate(origin_x + x - 1, origin_y + y - 1, z_level)
				if(cells[cell_index(x, y)])
					T = T.ChangeTurf(/turf/unsimulated/floor/cyberdeck)
					floors += T
				else if(!istype(T, /turf/unsimulated/wall/cyberdeck))
					T.ChangeTurf(/turf/unsimulated/wall/cyberdeck)
				CHECK_TICK
				if(cancelled || QDELETED(owner))
					generating = FALSE
					release()
					return FALSE
		entry_turf = locate(origin_x + 1, origin_y + 1, z_level)
		add_node(/obj/effect/cyberdeck_node/exit, entry_turf)
		var/list/available = floors.Copy()
		// Do not place objectives next to the entry portal.
		for(var/turf/T in floors)
			if(get_dist(T, entry_turf) < 5)
				available -= T
		if(collection_mode)
			for(var/i = 1, i <= required_keys, i++)
				add_node(/obj/effect/cyberdeck_node/data_fragment, pick_n_take(available))
			for(var/i = 1, i <= min(level * 2, available.len), i++)
				add_node(/obj/effect/cyberdeck_node/ice, pick_n_take(available))
			if(istype(GLOB.using_map, /datum/map/os13classic))
				add_node(/obj/effect/cyberdeck_node/guardian/scanner, pick_n_take(available))
				add_node(/obj/effect/cyberdeck_node/guardian/spore, pick_n_take(available))
				if(level >= 3)
					add_node(/obj/effect/cyberdeck_node/guardian/carp, pick_n_take(available))
			generating = FALSE
			return TRUE
		var/turf/core_turf
		var/farthest = -1
		for(var/turf/T in available)
			if(get_dist(T, entry_turf) > farthest)
				core_turf = T
				farthest = get_dist(T, entry_turf)
		add_node(/obj/effect/cyberdeck_node/core, core_turf)
		available -= core_turf
		for(var/i = 1, i <= required_keys, i++)
			var/turf/T = pick_n_take(available)
			add_node(/obj/effect/cyberdeck_node/relay, T)
		// ICE is optional: it occupies extra dead ends, never blocks a required node.
		var/ice_count = 0
		for(var/turf/T in shuffle(available))
			var/exits = 0
			for(var/direction in GLOB.cardinal)
				if(istype(get_step(T, direction), /turf/unsimulated/floor/cyberdeck))
					exits++
			if(exits == 1)
				add_node(/obj/effect/cyberdeck_node/ice, T)
				if(++ice_count >= level)
					break
	catch(var/exception/error)
		log_debug("Cyberdeck archive generation failed: [error]")
		generating = FALSE
		release()
		return FALSE
	generating = FALSE
	return TRUE

/datum/cyberdeck_instance/proc/add_node(node_type, turf/T)
	var/obj/effect/cyberdeck_node/N = new node_type(T)
	N.instance = src
	N.generation = generation
	nodes += N
	return N

/datum/cyberdeck_instance/proc/advance_guardians(mob/living/simple_animal/cyber_avatar/avatar)
	if(!collection_mode || !istype(GLOB.using_map, /datum/map/os13classic) || world.time < owner.protection_active_at)
		return
	var/turf/current_tile = get_turf(avatar)
	guardian_trail -= current_tile
	guardian_trail.Insert(1, current_tile)
	if(length(guardian_trail) > 12)
		guardian_trail.Cut(13)
	for(var/obj/effect/cyberdeck_node/guardian/guardian in nodes)
		guardian.patrol(avatar)
		if(cancelled)
			return

/datum/cyberdeck_instance/proc/can_traverse_ice(turf/unsimulated/wall/cyberdeck/T, mob/living/simple_animal/cyber_avatar/V)
	if(!collection_mode || cancelled || generating || QDELETED(owner) || owner.instance != src || !owner.dive_valid(V) || !owner.advanced_port_active() || !istype(T) || T.z != z_level)
		return FALSE
	var/local_x = T.x - origin_x + 1
	var/local_y = T.y - origin_y + 1
	return local_x > 1 && local_x < size && local_y > 1 && local_y < size

/datum/cyberdeck_instance/proc/deactivate_ice(turf/unsimulated/wall/cyberdeck/T, mob/living/simple_animal/cyber_avatar/V)
	if(!collection_mode || cancelled || generating || QDELETED(owner) || !owner.dive_valid(V) || owner.instance != src || !istype(T) || T.z != z_level || !T.Adjacent(V))
		return FALSE
	var/local_x = T.x - origin_x + 1
	var/local_y = T.y - origin_y + 1
	if(local_x <= 1 || local_x >= size || local_y <= 1 || local_y >= size)
		to_chat(V, SPAN_WARNING("The archive boundary cannot be deactivated. Use EJECT or the entry portal to leave."))
		return FALSE
	var/index = cell_index(local_x, local_y)
	if(cells[index])
		to_chat(V, SPAN_WARNING("This tile is not an active ICE barrier."))
		return FALSE
	V.clear_scan()
	var/turf/opened = T.ChangeTurf(/turf/unsimulated/floor/cyberdeck)
	cells[index] = TRUE
	floors |= opened
	playsound(opened, 'sound/misc/ipick.ogg', 50, TRUE)
	to_chat(V, SPAN_NOTICE("Blue ICE deactivated."))
	return TRUE

/datum/cyberdeck_instance/proc/erase_information(atom/target, mob/living/simple_animal/cyber_avatar/V)
	if(!collection_mode || cancelled || generating || QDELETED(owner) || owner.instance != src || !owner.dive_valid(V) || QDELETED(target) || !(target in view(1, V)) || target.alpha <= 0 || target.invisibility > V.see_invisible)
		return FALSE
	if(istype(target, /turf/unsimulated/wall/cyberdeck))
		return deactivate_ice(target, V)
	if(!istype(target, /obj/effect/cyberdeck_node))
		return FALSE
	var/obj/effect/cyberdeck_node/N = target
	if(N.instance != src || N.generation != generation || !(N in nodes) || !N.can_interact(V))
		return FALSE
	V.clear_scan()
	playsound(get_turf(N), 'sound/misc/ipick.ogg', 50, TRUE)
	to_chat(V, SPAN_NOTICE("ICE-Pick removed [N.name]."))
	if(istype(N, /obj/effect/cyberdeck_node/data_fragment))
		destroyed_data++
		owner.status_message = "Download unavailable: [destroyed_data] required data point(s) destroyed. EJECT and start a fresh dive. Existing disk contents are unchanged."
		to_chat(V, SPAN_WARNING(owner.status_message))
	nodes -= N
	qdel(N)
	owner.updateUsrDialog()
	return TRUE

/datum/cyberdeck_instance/proc/release()
	cancelled = TRUE
	if(generating)
		return // The generation loop owns this slot until it has stopped yielding.
	for(var/obj/effect/cyberdeck_node/N in nodes)
		qdel(N)
	nodes.Cut()
	guardian_trail.Cut()
	for(var/turf/T in floors)
		T.ChangeTurf(/turf/unsimulated/wall/cyberdeck)
	floors.Cut()
	cells.Cut()
	entry_turf = null
	owner = null
	decrypted = 0
	destroyed_data = 0
	busy = FALSE

/obj/effect/cyberdeck_node
	name = "archive node"
	icon = 'icons/misc/newcyber.dmi'
	anchored = TRUE
	var/datum/cyberdeck_instance/instance
	var/generation
	var/working = FALSE

/obj/effect/cyberdeck_node/Initialize(mapload)
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		icon = 'icons/os13/objects/objects/newcyber.dmi'

/obj/effect/cyberdeck_node/proc/can_interact(mob/living/simple_animal/cyber_avatar/V)
	return istype(V) && !QDELETED(src) && instance && !instance.cancelled && generation == instance.generation && instance.owner && instance.owner.dive_valid(V) && Adjacent(V)

/obj/effect/cyberdeck_node/interact(mob/living/simple_animal/cyber_avatar/V)
	return

/obj/effect/cyberdeck_node/data_fragment
	name = "research data"
	desc = "Collect this data by clicking it nearby or moving onto it."
	icon_state = "data"
	var/collected = FALSE

/obj/effect/cyberdeck_node/data_fragment/interact(mob/living/simple_animal/cyber_avatar/V)
	if(collected || !can_interact(V) || !instance.collection_mode)
		return
	V.clear_scan()
	collected = TRUE
	alpha = 0
	mouse_opacity = 0
	instance.decrypted++
	if(instance.decrypted >= instance.required_keys)
		instance.owner.complete_dive(V)
	else
		to_chat(V, SPAN_NOTICE("DATA LEFT: [instance.required_keys - instance.decrypted]."))
		if(instance.destroyed_data)
			to_chat(V, SPAN_WARNING("[instance.destroyed_data] required data point(s) were destroyed. This download cannot be completed; use EJECT and start a fresh dive."))
		instance.owner.updateUsrDialog()

/obj/effect/cyberdeck_node/data_fragment/Crossed(atom/movable/AM)
	. = ..()
	if(istype(AM, /mob/living/simple_animal/cyber_avatar))
		interact(AM)

/obj/effect/cyberdeck_node/relay
	name = "encrypted relay"
	desc = "Click to decode a hexadecimal encryption key."
	icon_state = "access"
	var/key_value
	var/shift
	var/solved = FALSE

/obj/effect/cyberdeck_node/relay/New()
	..()
	key_value = rand(0, 15)
	shift = rand(1, 15)

/obj/effect/cyberdeck_node/relay/proc/encoded_key()
	return copytext("0123456789ABCDEF", ((key_value + shift) % 16) + 1, ((key_value + shift) % 16) + 2)

/obj/effect/cyberdeck_node/relay/proc/accept_key(answer, mob/living/simple_animal/cyber_avatar/V)
	if(!can_interact(V) || solved || isnull(answer))
		return FALSE
	var/decoded = copytext("0123456789ABCDEF", key_value + 1, key_value + 2)
	if(uppertext(trim(answer)) != decoded)
		V.adjustBruteLoss(10)
		to_chat(V, SPAN_WARNING("Key rejected. ICE removes 10 avatar integrity. Subtract the decimal shift from the hexadecimal header, wrapping below zero to F."))
		if(V.health <= 0)
			V.death()
		return FALSE
	solved = TRUE
	instance.decrypted++
	icon_state = "data"
	name = "decrypted relay"
	to_chat(V, SPAN_NOTICE("Relay decrypted: [instance.decrypted]/[instance.required_keys]. [instance.decrypted == instance.required_keys ? "The data core is ready to download." : "Find the remaining relays."]"))
	return TRUE

/obj/effect/cyberdeck_node/relay/interact(mob/living/simple_animal/cyber_avatar/V)
	if(!can_interact(V) || solved || working)
		return
	working = TRUE
	var/answer = input(V, "Encrypted header: [encoded_key()]. Shift: +[shift] (decimal), wrapping at 16. Enter the original hexadecimal digit (0-9 or A-F). Subtract the shift to decrypt.", "Decrypt relay") as null|text
	if(QDELETED(src))
		return
	working = FALSE
	accept_key(answer, V)

/obj/effect/cyberdeck_node/core
	name = "research data core"
	desc = "Decrypt every relay, then click here to download the technology onto the physical disk."
	icon_state = "data"

/obj/effect/cyberdeck_node/core/interact(mob/living/simple_animal/cyber_avatar/V)
	if(!can_interact(V) || working)
		return
	if(instance.decrypted < instance.required_keys)
		to_chat(V, SPAN_WARNING("Archive locked: decrypt all [instance.required_keys] relays first."))
		return
	working = TRUE
	to_chat(V, SPAN_NOTICE("Downloading to the physical disk. Hold your position."))
	var/completed = do_after(V, 3 SECONDS, src)
	if(QDELETED(src))
		return
	working = FALSE
	if(completed && can_interact(V))
		instance.owner.complete_dive(V)

/obj/effect/cyberdeck_node/exit
	name = "recall portal"
	desc = "Click to return to your body without completing the download."
	icon_state = "tnc_exit"

/obj/effect/cyberdeck_node/exit/Initialize(mapload)
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		desc = "Click nearby or step onto this portal to return to your body without completing the download."

/obj/effect/cyberdeck_node/exit/interact(mob/living/simple_animal/cyber_avatar/V)
	if(can_interact(V))
		instance.owner.end_dive("You left the archive. No data was written.")

/obj/effect/cyberdeck_node/exit/Crossed(atom/movable/AM)
	. = ..()
	if(instance && instance.collection_mode && istype(AM, /mob/living/simple_animal/cyber_avatar))
		interact(AM)

/obj/effect/cyberdeck_node/ice
	name = "red ICE"
	desc = "A hostile packet. Avoid stepping on it: it damages avatar integrity."
	icon_state = "red_ice"

/obj/effect/cyberdeck_node/ice/Crossed(atom/movable/AM)
	. = ..()
	var/mob/living/simple_animal/cyber_avatar/V = AM
	if(can_interact(V))
		if(instance.collection_mode && world.time < instance.owner.protection_active_at)
			to_chat(V, SPAN_NOTICE("The Red ICE protection is still asleep."))
			return
		V.adjustBruteLoss(20)
		to_chat(V, SPAN_WARNING("Red ICE strips 20 avatar integrity!"))
		if(V.health <= 0)
			V.death()

/obj/effect/cyberdeck_node/guardian
	icon = 'icons/os13/objects/objects/newcyber.dmi'
	var/detection_range = 0
	var/next_hit = 0

/obj/effect/cyberdeck_node/guardian/Crossed(atom/movable/AM)
	. = ..()
	var/mob/living/simple_animal/cyber_avatar/avatar = AM
	contact(avatar)

/obj/effect/cyberdeck_node/guardian/proc/track(mob/living/simple_animal/cyber_avatar/avatar)
	return null

/obj/effect/cyberdeck_node/guardian/proc/patrol(mob/living/simple_animal/cyber_avatar/avatar)
	if(QDELETED(src))
		return
	if(contact(avatar))
		return
	var/turf/target = track(avatar)
	var/list/steps = list()
	var/best_distance = INFINITY
	for(var/direction in GLOB.cardinal)
		var/turf/next = get_step(src, direction)
		if(!istype(next, /turf/unsimulated/floor/cyberdeck) || next == instance.entry_turf)
			continue
		var/distance = target ? get_dist(next, target) : 0
		if(distance < best_distance)
			best_distance = distance
			steps.Cut()
		if(distance == best_distance)
			steps += next
	if(length(steps))
		forceMove(pick(steps))
		contact(avatar)

/obj/effect/cyberdeck_node/guardian/proc/contact(mob/living/simple_animal/cyber_avatar/avatar)
	if(!can_interact(avatar) || loc != avatar.loc || world.time < instance.owner.protection_active_at || world.time < next_hit)
		return FALSE
	next_hit = world.time + 2 SECONDS
	strike(avatar)
	return TRUE

/obj/effect/cyberdeck_node/guardian/proc/strike(mob/living/simple_animal/cyber_avatar/avatar)
	instance.owner.forced_eject("[name] detected you and terminated the connection. No data was written.")

/obj/effect/cyberdeck_node/guardian/scanner
	name = "archive scanner"
	icon_state = "access"

/obj/effect/cyberdeck_node/guardian/spore
	name = "mysterious spore"
	icon_state = "spore"
	detection_range = 6

/obj/effect/cyberdeck_node/guardian/spore/track(mob/living/simple_animal/cyber_avatar/avatar)
	for(var/turf/trace in instance.guardian_trail)
		if(trace != loc && get_dist(src, trace) <= detection_range)
			return trace

/obj/effect/cyberdeck_node/guardian/carp
	name = "cyberspace carp"
	icon_state = "spesscarp"
	detection_range = 12

/obj/effect/cyberdeck_node/guardian/carp/track(mob/living/simple_animal/cyber_avatar/avatar)
	if(get_dist(src, avatar) <= detection_range)
		return get_turf(avatar)

/obj/effect/cyberdeck_node/guardian/carp/strike(mob/living/simple_animal/cyber_avatar/avatar)
	if(++avatar.guardian_fatigue >= 3)
		instance.owner.forced_eject("The cyberspace carp exhausted your avatar and forced an ejection. No data was written.")
	else
		to_chat(avatar, SPAN_WARNING("The cyberspace carp saps your strength. Your avatar slows down."))
