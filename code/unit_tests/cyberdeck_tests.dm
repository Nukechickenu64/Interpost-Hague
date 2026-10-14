#ifdef UNIT_TEST

// Keep the fixture independent of the live station's changing power network.
/obj/machinery/computer/cyberdeck/unit_test
	var/test_power = TRUE

/obj/machinery/computer/cyberdeck/unit_test/powered(chan = -1, area/check_area = null)
	return test_power

// Headless tests have no BYOND client. Keep the real Topic distance, visibility,
// incapacitation and machinery checks; substitute only the connection check.
/mob/living/carbon/human/cyberdeck_test_operator
	see_in_dark = 8

/mob/living/carbon/human/cyberdeck_test_operator/shared_nano_interaction()
	if(stat)
		return STATUS_CLOSE
	return incapacitated() ? STATUS_UPDATE : STATUS_INTERACTIVE

/datum/unit_test/cyberdeck_preallocation
	name = "CYBERDECK - Archives are prepared at startup without runtime world expansion"

/datum/unit_test/cyberdeck_preallocation/start_test()
	var/failure = ""
	var/initial_maxz = world.maxz
	var/list/zstack = SSzcopy.zstack_maximums
	var/list/reserved = list()
	var/max_size = cyberdeck_map_size(CYBERDECK_MAX_LEVEL)
	if(GLOB.cyberdeck_instances.len < CYBERDECK_MIN_INSTANCES)
		fail("Startup did not prepare the minimum archive pool.")
		return TRUE
	for(var/datum/cyberdeck_instance/I in GLOB.cyberdeck_instances)
		var/turf/T = locate(I.origin_x + max_size - 1, I.origin_y + max_size - 1, I.z_level)
		if(!I.prepared || !I.z_level || I.z_level > initial_maxz || !istype(T, /turf/unsimulated/wall/cyberdeck) || get_area(T) != I.archive_area || !(T.atom_flags & ATOM_FLAG_INITIALIZED))
			failure += "A startup slot lacks its initialized maximum-size firewall. "
		if(!(I.z_level in GLOB.using_map.player_levels) || zstack.len < I.z_level || zstack[I.z_level] != I.z_level)
			failure += "Startup z-level metadata is missing or connected to another level. "
		var/datum/cyberdeck_instance/claimed = acquire_cyberdeck_instance()
		if(!claimed || (claimed in reserved))
			failure += "A prepared slot could not be claimed exclusively. "
		else
			reserved += claimed
	if(acquire_cyberdeck_instance())
		failure += "Exhaustion created an additional archive. "
	for(var/datum/cyberdeck_instance/I in reserved)
		I.release()
	var/datum/cyberdeck_instance/I = acquire_cyberdeck_instance()
	var/obj/machinery/computer/cyberdeck/unit_test/C = new(locate(1, 1, 1))
	if(!I || !I.generate(CYBERDECK_MAX_LEVEL, C))
		failure += "The largest maze could not use a startup slot. "
	else
		var/archive_z = I.z_level
		I.release()
		var/datum/cyberdeck_instance/reused = acquire_cyberdeck_instance()
		if(reused != I || reused.z_level != archive_z || !reused.generate(1, C))
			failure += "A smaller maze could not reuse the same startup slot. "
		for(var/x = 1, x <= max_size, x++)
			for(var/y = 1, y <= max_size, y++)
				var/turf/T = locate(I.origin_x + x - 1, I.origin_y + y - 1, archive_z)
				if((x > I.size || y > I.size) && !istype(T, /turf/unsimulated/wall/cyberdeck))
					failure += "Reusing the archive left old pathways outside the smaller maze. "
		if(reused)
			reused.release()
	if(I)
		I.release()
	qdel(C)
	if(world.maxz != initial_maxz || SSzcopy.zstack_maximums != zstack)
		failure += "Claiming, exhausting or regenerating archives expanded/reindexed the world. "
	if(length(failure))
		fail(failure)
	else
		pass("Startup slots, exclusive claims, pool exhaustion and level 20-to-1 reuse passed without world expansion or Z-copy recalculation.")
	return TRUE

/datum/unit_test/cyberdeck_layout
	name = "CYBERDECK - Connected procedural archives scale with research level"

/datum/unit_test/cyberdeck_layout/start_test()
	var/datum/cyberdeck_instance/I = new
	var/failure = ""
	var/previous_size = 0
	for(var/level = 1, level <= CYBERDECK_MAX_LEVEL, level++)
		I.build_layout(level)
		if(I.size <= previous_size || !(I.size % 2))
			failure += "Level [level] did not increase the odd map dimensions. "
		previous_size = I.size
		var/list/visited = new/list(I.cells.len)
		var/list/frontier = list(I.cell_index(2, 2))
		visited[frontier[1]] = TRUE
		var/head = 1
		while(head <= frontier.len)
			var/index = frontier[head++]
			var/x = ((index - 1) % I.size) + 1
			var/y = round((index - 1) / I.size) + 1
			for(var/direction in GLOB.cardinal)
				var/nx = x + (direction == EAST ? 1 : direction == WEST ? -1 : 0)
				var/ny = y + (direction == NORTH ? 1 : direction == SOUTH ? -1 : 0)
				if(nx < 1 || nx > I.size || ny < 1 || ny > I.size)
					continue
				var/neighbor = I.cell_index(nx, ny)
				if(I.cells[neighbor] && !visited[neighbor])
					visited[neighbor] = TRUE
					frontier += neighbor
		for(var/x = 1, x <= I.size, x++)
			for(var/y = 1, y <= I.size, y++)
				var/index = I.cell_index(x, y)
				if(I.cells[index] && !visited[index])
					failure += "Unreachable cell at level [level]: [x],[y]. "
				if((x == 1 || y == 1 || x == I.size || y == I.size) && I.cells[index])
					failure += "Level [level] opened its outer firewall. "
		var/layout = I.cells.Join(",")
		I.build_layout(level)
		if(layout == I.cells.Join(","))
			failure += "Level [level] repeated the same generated layout. "
	qdel(I)
	if(length(failure))
		fail(failure)
	else
		pass("All 20 levels have increasing bounds, sealed edges, randomized layouts and reachable cells.")
	return TRUE

/datum/unit_test/cyberdeck_session
	name = "CYBERDECK - Disk download, progression, isolation and safe recall"

/datum/unit_test/cyberdeck_session/start_test()
	var/turf/T = get_safe_turf()
	if(!T)
		// Alpha has no safe_turf landmark; the fixture does not process biology.
		for(var/turf/space/candidate in world)
			if(candidate.x > TRANSITIONEDGE + 2 && candidate.y > TRANSITIONEDGE + 2)
				T = candidate
				break
	if(!T)
		fail("No safe test turf.")
		return TRUE
	var/obj/machinery/computer/cyberdeck/unit_test/C = new(T)
	C.power_change()
	var/mob/living/carbon/human/H = new /mob/living/carbon/human/cyberdeck_test_operator(T)
	STOP_PROCESSING(SSmobs, H)
	var/datum/mind/M = new
	M.transfer_to(H)
	var/obj/structure/bed/chair/cyberdeck/chair = new(T)
	var/obj/item/clothing/head/cyberdeck/headset/helmet = new(H)
	H.head = helmet
	H.buckled = chair
	chair.buckled_mob = H
	C.linked_chair = chair
	var/failure = ""
	var/original_level = C.network_level(/datum/tech/engineering)
	var/list/screen = C.screen_data()
	if(screen["can_boot"] || findtext(cyberdeck_ui_html(screen, "byond://?src=\ref[C]"), "action=boot"))
		failure += "The screen offered Boot without a disk. "
	H.set_machine(C)
	if(C.OnTopic(H, list("close" = "1")) != TOPIC_NOACTION || H.machine)
		failure += "Closing the screen retained its dialog subscription. "
	if(C.begin_dive(H, /datum/tech/engineering))
		failure += "Booted without a disk. "
	var/obj/item/disk/tech_disk/D = new(C)
	C.disk = D
	D.stored = new /datum/tech/engineering
	screen = C.screen_data()
	if(screen["can_boot"] || screen["media"] != "recorded")
		failure += "The screen treated a recorded disk as writable. "
	if(C.begin_dive(H, /datum/tech/engineering))
		failure += "Booted onto an occupied disk. "
	QDEL_NULL(D.stored)
	C.linked_chair = null
	screen = C.screen_data()
	if(!screen["can_boot"] || C.linked_chair)
		failure += "Displaying an available auto-link hid Boot or reserved a chair. "
	for(var/list/archive in screen["archives"])
		if(archive["id"] == TECH_ILLEGAL || archive["id"] == TECH_ARCANE)
			failure += "The screen exposed a secret research discipline. "
	C.linked_chair = chair
	H.head = null
	screen = C.screen_data()
	if(screen["can_boot"])
		failure += "The screen offered Boot with a stale chair selection. "
	if(C.begin_dive(H, /datum/tech/engineering))
		failure += "Booted without a helmet. "
	H.head = helmet
	if(C.begin_dive(H, /datum/tech/syndicate))
		failure += "Allowed a forged request for a secret discipline. "
	var/initial_maxz = world.maxz
	var/list/reserved = list()
	for(var/datum/cyberdeck_instance/I in GLOB.cyberdeck_instances)
		var/datum/cyberdeck_instance/claimed = acquire_cyberdeck_instance()
		if(claimed)
			reserved += claimed
	if(C.begin_dive(H, /datum/tech/engineering) || C.state != CYBERDECK_IDLE || C.instance || C.pending_tech || chair.linked_console || M.current != H || D.loc != C || D.stored)
		failure += "An exhausted archive pool reserved the chair/disk or transferred the operator. "
	for(var/datum/cyberdeck_instance/I in reserved)
		I.release()
	usr = H
	var/boot_href = "?src=\ref[C];action=boot;tech=[TECH_ENGINEERING]"
	C.Topic(boot_href, params2list(boot_href))
	usr = null
	if(C.state != CYBERDECK_RUNNING)
		failure += "Boot Level hyperlink did not launch (Topic access [C.CanUseTopic(H)], status [C.status_message]). "
	else
		// The fixture has no client. Keep the first dive alive while a second
		// archive is generated (and yields); disconnection is tested explicitly.
		deltimer(C.monitor_timer)
		C.monitor_timer = null
		var/mob/living/simple_animal/cyber_avatar/V = C.dive_body
		var/datum/cyberdeck_instance/I = C.instance
		if(ishuman(V) || V.mind != M || M.current != V || H.mind || V.overlays.len || V.name != H.real_name)
			failure += "Avatar is not a flat nonhuman projection of the linked mind. "
		for(var/direction in GLOB.cardinal)
			var/icon/avatar_frame = icon(V.icon, V.icon_state, direction)
			fcopy(avatar_frame, "data/cyberdeck-avatar-[direction].png")
		var/hp = V.health
		V.handle_atmos()
		if(V.health != hp)
			failure += "Virtual avatar took atmosphere damage. "
		if(C.complete_dive(V) || D.stored)
			failure += "Downloaded before decryption. "
		var/first_id = C.dive_id
		if(C.begin_dive(H, /datum/tech/materials) || C.dive_id != first_id)
			failure += "Second boot replaced an active dive. "
		var/datum/cyberdeck_instance/other = acquire_cyberdeck_instance()
		if(other == I || !other.generate(1, C) || other.z_level == I.z_level)
			failure += "Concurrent archives shared a z-level. "
		other.release()
		var/mob/living/simple_animal/cyber_avatar/stranger = new(I.entry_turf)
		for(var/obj/effect/cyberdeck_node/relay/R in I.nodes)
			V.forceMove(get_turf(R))
			stranger.forceMove(get_turf(R))
			var/answer = copytext("0123456789ABCDEF", R.key_value + 1, R.key_value + 2)
			if(R.accept_key(answer, stranger))
				failure += "Foreign avatar unlocked a relay. "
			if(R.accept_key("invalid", V) || V.health != hp - 10)
				failure += "Wrong key did not reject and damage the avatar. "
			hp = V.health
			if(!R.accept_key(answer, V) || R.accept_key(answer, V))
				failure += "Relay failed to unlock exactly once. "
		qdel(stranger)
		if(I.decrypted != I.required_keys || !C.complete_dive(V))
			failure += "Decrypted archive did not download. "
		if(!D.stored || D.stored.id != TECH_ENGINEERING || D.stored.level != original_level + 1)
			failure += "Disk payload has the wrong technology or level. "
		if(C.network_level(/datum/tech/engineering) != original_level)
			failure += "Download directly changed station research. "
		if(M.current != H || H.mind != M || C.state != CYBERDECK_IDLE || C.instance || I.busy || I.nodes.len || I.floors.len || chair.linked_console || !QDELETED(V))
			failure += "Successful download did not return the mind and release the archive. "
		var/datum/research/RD = new
		if(D.stored)
			RD.AddTech2Known(D.stored)
		RD.RefreshResearch()
		var/waterchip_unlocked = FALSE
		for(var/datum/design/design in RD.known_designs)
			if(design.build_path == /obj/item/device/waterchip)
				waterchip_unlocked = TRUE
		if(!waterchip_unlocked)
			failure += "Imported engineering disk did not unlock the water chip. "
		qdel(RD)
		QDEL_NULL(D.stored)
		var/old_z = I.z_level
		if(C.begin_dive(H, /datum/tech/engineering))
			if(C.instance != I || C.instance.z_level != old_z)
				failure += "Sequential dives did not reuse the released z-level. "
			C.check_dive(first_id)
			if(C.state != CYBERDECK_RUNNING)
				failure += "A stale monitoring callback ended a newer dive. "
			C.end_dive("Test recall")
		else
			failure += "Could not start a second dive. "
	// Each failure must leave a blank disk and return the same mind.
	for(var/scenario in list("recall", "helmet", "chair", "disk", "power", "death", "avatar deletion", "disconnect", "timeout", "console deletion"))
		if(!C.begin_dive(H, /datum/tech/materials))
			failure += "Could not boot the [scenario] scenario (state [C.state], power [C.powered()], stat [C.stat], body [H.stat], mind [M.current == H]). "
			break
		var/datum/cyberdeck_instance/I = C.instance
		switch(scenario)
			if("recall")
				C.dive_body.recall()
			if("helmet")
				H.head = null
				if(C.physical_link_valid())
					failure += "Missing helmet left the link valid. "
				C.check_dive()
				H.head = helmet
			if("chair")
				chair.unbuckle_mob()
				chair.buckle_mob(H)
			if("disk")
				D.forceMove(T)
				if(C.complete_dive(C.dive_body) || C.physical_link_valid())
					failure += "Removed disk remained writable. "
				C.check_dive()
				D.forceMove(C)
			if("power")
				C.test_power = FALSE
				C.power_change()
				C.test_power = TRUE
				C.power_change()
			if("death")
				C.dive_body.death()
			if("avatar deletion")
				qdel(C.dive_body)
			if("disconnect")
				C.check_dive() // Fixture deliberately has no client.
			if("timeout")
				C.dive_deadline = world.time
				if(C.dive_valid(C.dive_body))
					failure += "Expired archive remained valid. "
				C.check_dive()
			if("console deletion")
				qdel(C)
		if(M.current != H || H.mind != M || D.stored || I.busy || chair.linked_console)
			failure += "Unsafe or rewarding cleanup after [scenario]. "
		if(scenario != "console deletion" && (C.monitor_timer || C.dive_body || C.instance || C.pending_tech))
			failure += "[scenario] left session resources attached. "
	if(D.loc != T)
		failure += "Console destruction did not eject its disk. "
	if(!QDELETED(C))
		qdel(C)
	H.buckled = null
	chair.buckled_mob = null
	qdel(chair)
	qdel(H)
	qdel(M)
	qdel(D)
	if(world.maxz != initial_maxz)
		failure += "Booting or recalling a dive expanded the world. "
	if(length(failure))
		fail(failure)
	else
		pass("Disk prerequisites, relay validation, disk-only rewards, archive isolation/reuse and ten recall paths passed.")
	return TRUE

// Opt-in integration test: run cyberdeck_test.dmb with
// -params "cyberdeck_client=1" and connect a Dream Seeker to that test server.
// Never queued by the general headless suite.
/datum/unit_test/cyberdeck_client
	name = "template - CYBERDECK connected client self-boot and recall"

/datum/unit_test/cyberdeck_client/start_test()
	var/connect_deadline = world.time + 20 SECONDS
	while(!GLOB.clients.len && world.time < connect_deadline)
		sleep(1 SECOND)
	if(!GLOB.clients.len)
		fail("No Dream Seeker connected to the isolated test server.")
		return TRUE
	var/client/player = GLOB.clients[1]
	// clients is populated before client.New/Login finish. Wait for the normal
	// browser-ready handshake before moving the client out of its lobby mob.
	var/login_deadline = world.time + 30 SECONDS
	while(player && !player.pigReady && world.time < login_deadline)
		sleep(1 SECOND)
	if(!player || !player.pigReady)
		fail("The connected Dream Seeker did not finish logging in.")
		return TRUE
	var/mob/original_mob = player.mob
	var/turf/T
	for(var/turf/space/candidate in world)
		if(candidate.x > TRANSITIONEDGE + 2 && candidate.y > TRANSITIONEDGE + 2)
			T = candidate
			break
	var/obj/machinery/computer/cyberdeck/unit_test/C = new(get_step(T, EAST))
	C.power_change()
	var/mob/living/carbon/human/H = new(T)
	STOP_PROCESSING(SSmobs, H)
	H.see_in_dark = 8
	usr = H
	H.key = player.key
	var/datum/mind/M = H.mind
	var/obj/structure/bed/chair/cyberdeck/chair = new(T)
	chair.buckle_mob(H)
	H.equip_to_slot_or_del(new /obj/item/clothing/head/cyberdeck/headset(H), slot_head)
	var/obj/item/disk/tech_disk/D = new(H)
	H.put_in_hands(D)
	C.attackby(D, H)
	var/failure = ""
	if(C.disk != D || D.loc != C)
		failure += "Inserting a held disk did not load the drive. "
	var/href = "?src=\ref[C];action=boot;tech=[TECH_ENGINEERING]"
	C.Topic(href, params2list(href))
	if(C.state != CYBERDECK_RUNNING || !C.dive_body || player.mob != C.dive_body || player.eye != C.dive_body || M.current != C.dive_body || !C.instance || C.dive_body.z != C.instance.z_level)
		failure += "Self-boot did not transfer the connected player and camera (access [C.CanUseTopic(H)], status [C.status_message]). "
	else
		sleep(2 SECONDS)
		if(C.state != CYBERDECK_RUNNING)
			failure += "The connected dive was immediately recalled. "
		else
			usr = C.dive_body
			C.dive_body.recall()
		if(player.mob != H || player.eye != H || H.mind != M || M.current != H || D.stored)
			failure += "Recall did not restore the connected player and camera to the seated body. "
	usr = original_mob
	player.mob = original_mob
	usr = null
	qdel(C)
	qdel(chair)
	qdel(H)
	qdel(M)
	qdel(D)
	if(length(failure))
		fail(failure)
	else
		pass("A connected player inserted a disk, self-booted through Topic, stayed in cyberspace and recalled to their body.")
	return TRUE

#endif
