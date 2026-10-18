#ifdef UNIT_TEST

/mob/living/replicator_radiation_probe
	var/pulses = 0
	var/radiation_armor = 0
	var/acute_damage = 0

/mob/living/replicator_radiation_probe/rad_act(severity)
	pulses++
	return ..()

/mob/living/replicator_radiation_probe/getarmor(def_zone, type)
	return type == "rad" ? radiation_armor : 0

/mob/living/replicator_radiation_probe/adjustToxLoss(amount)
	acute_damage = max(0, acute_damage + amount)

/mob/living/replicator_radiation_probe/getToxLoss()
	return acute_damage

/obj/machinery/r_n_d/protolathe/replicator_test
	var/pulses = 0
	var/test_power = TRUE
	var/last_flash_duration

/obj/machinery/r_n_d/protolathe/replicator_test/powered(chan = -1, area/check_area = null)
	return test_power

/obj/machinery/r_n_d/protolathe/replicator_test/conversion_pulse(flash_duration = 4)
	pulses++
	last_flash_duration = flash_duration

/obj/item/replicator_test_scrap
	name = "replicator test scrap"
	matter = list("steel" = 1000)

/datum/unit_test/replicator_radiation
	name = "REPLICATOR - Lingering radiation, lethal core, weaker tail, shielding and floor layering"

/datum/unit_test/replicator_radiation/start_test()
	var/failure = ""
	// A clear corner of the unit-test level, away from the station and other fixtures.
	var/test_z = world.maxz
	var/origin_x = world.maxx - 40
	var/origin_y = world.maxy - 40
	var/turf/origin = locate(origin_x, origin_y, test_z)
	var/list/turf_types = list()
	for(var/turf/T in range(6, origin))
		var/old_type = T.type
		var/turf/replacement = T.ChangeTurf(/turf/unsimulated/floor)
		turf_types[replacement] = old_type
	origin = locate(origin_x, origin_y, test_z)
	var/obj/machinery/r_n_d/protolathe/R = new(origin)
	var/obj/item/floor_item = new(origin)
	floor_item.layer = MOUSETRAP_LAYER
	if(R.plane != floor_item.plane || R.layer >= floor_item.layer)
		failure += "The platform renders over low floor items. "
	var/mob/living/replicator_radiation_probe/core = new(locate(origin.x + 3, origin.y + 3, test_z))
	var/mob/living/replicator_radiation_probe/tail = new(locate(origin.x + 4, origin.y, test_z))
	var/mob/living/replicator_radiation_probe/far = new(locate(origin.x + 5, origin.y, test_z))
	var/mob/living/carbon/human/core_human = new(get_turf(core))
	var/mob/living/carbon/human/tail_human = new(get_turf(tail))
	var/mob/living/replicator_radiation_probe/armored = new(get_turf(core))
	armored.radiation_armor = 100
	var/mob/living/replicator_radiation_probe/shielded = new(locate(origin.x - 3, origin.y, test_z))
	var/obj/shield = new(locate(origin.x - 1, origin.y, test_z))
	shield.rad_resistance = 100
	SSradiation.resistance_cache.Remove(get_turf(shield))
	var/mob/living/replicator_radiation_probe/walker = new(get_step(origin, SOUTH))
	if(!step(walker, NORTH) || get_turf(walker) != origin)
		failure += "The platform blocked movement. "
	// The field must coexist with an ordinary radiation source on the same tile.
	var/datum/radiation_source/ambient = new(origin)
	ambient.update_rad_power(10)
	SSradiation.add_source(ambient)
	var/source_count = SSradiation.sources.len
	R.conversion_pulse(3 SECONDS)
	var/datum/radiation_source/replicator/field = R.radiation_field
	if(core.radiation != 500 || core.pulses != 1)
		failure += "Core/corner dose was [core.radiation] in [core.pulses] hits. "
	if(tail.radiation != 25 || far.radiation != 16 || tail.pulses != 1)
		failure += "Tail doses were [tail.radiation] and [far.radiation]. "
	if(armored.radiation || armored.getToxLoss() || shielded.radiation >= core.radiation || shielded.getToxLoss() >= core.getToxLoss())
		failure += "Armor or environmental shielding failed. "
	if(SSradiation.sources.len != source_count + 1 || SSradiation.sources_assoc[origin] != ambient || !(field in SSradiation.sources))
		failure += "Field was not registered independently of ambient radiation. "
	if(core_human.getToxLoss() < 49 || tail_human.getToxLoss() > 3 || tail_human.handle_death_check())
		failure += "Immediate core injury was ineffective or the outer burst was lethal. "
	var/obj/effect/replicator_flash/flash = locate() in origin
	if(!flash || flash.pixel_x != -32 || flash.pixel_y != -32 || flash.light_range < 6 || flash.light_color != COLOR_DEEP_SKY_BLUE)
		failure += "Centered blue flash was missing. "
	sleep(25)
	if(QDELETED(flash) || !flash.light_range || QDELETED(field) || core.pulses <= 1 || core.getToxLoss() <= 50 || field.rad_power >= field.peak_power)
		failure += "Production exposure at 2.5 seconds: flash_deleted=[QDELETED(flash)], light=[flash.light_range], field_deleted=[QDELETED(field)], pulses=[core.pulses], acute_damage=[core.getToxLoss()], power=[field.rad_power]/[field.peak_power]. "
	sleep(10)
	if(!QDELETED(flash) || QDELETED(field))
		failure += "The production flash did not end after three seconds, or radiation ended with it. "
	field.started_at = world.time - field.duration / 2
	field.process_radiation()
	if(SSradiation.get_rads_at_turf(get_turf(core), field) != 250 || SSradiation.get_rads_at_turf(get_turf(tail), field) != 12.5)
		failure += "Radiation did not fade to half strength at half its lifetime. "
	R.conversion_pulse()
	if(R.radiation_field != field || field.rad_power != field.peak_power || SSradiation.sources.len != source_count + 1)
		failure += "Repeated conversion failed to refresh one field. "
	// Advance the real exposure code through its lifetime without a minute-long test.
	for(var/age = 2 SECONDS, age < field.duration, age += 2 SECONDS)
		field.started_at = world.time - age
		field.process_radiation()
		for(var/obj/item/organ/internal/I in core_human.internal_organs)
			if(I.vital)
				I.Process()
	if(core_human.stat != DEAD && !core_human.handle_death_check())
		failure += "Sustained core exposure did not fatally injure a human. "
	if(tail_human.handle_death_check() || tail_human.getToxLoss() >= 100)
		failure += "A single fading field was too lethal beyond the core. "
	field.started_at = world.time - field.duration
	field.process_radiation()
	if(!QDELETED(field) || (field in SSradiation.sources) || SSradiation.sources_assoc[origin] != ambient)
		failure += "The field failed to expire cleanly. "
	qdel(ambient)
	for(var/obj/effect/replicator_flash/F in origin)
		qdel(F)
	for(var/atom/movable/A in list(R, floor_item, core, tail, far, core_human, tail_human, armored, shielded, shield, walker, flash))
		qdel(A)
	for(var/turf/T in turf_types)
		T.ChangeTurf(turf_types[T])
	if(length(failure))
		fail(failure)
	else
		pass("Floor layering, real ongoing exposure, fatal human core injury, weaker tail, shielding, gradual decay and expiration verified.")
	return TRUE

/datum/unit_test/replicator_operations
	name = "REPLICATOR - Three-second production, instant reclamation and storage/power checks"

/datum/unit_test/replicator_operations/start_test()
	var/failure = ""
	// Keep the fixture off the space-map edge, which relocates newly created objects.
	var/turf/T = locate(world.maxx - 60, world.maxy - 60, world.maxz)
	var/old_turf_type = T.type
	T = T.ChangeTurf(/turf/unsimulated/floor)
	var/obj/machinery/r_n_d/protolathe/replicator_test/R = new(T)
	var/list/original_storages = GLOB.replicator_storages
	GLOB.replicator_storages = list()
	var/obj/machinery/replicator_storage/storage = new(locate(T.x + 4, T.y, T.z))
	var/obj/machinery/replicator_storage_compartment/steel = storage.compartments["steel"]
	steel.locked = FALSE
	var/obj/machinery/computer/rdconsole/C = new(T)
	R.linked_console = C
	C.linked_lathe = R
	R.stat = 0
	var/datum/design/D = new
	D.build_path = /obj/item/replicator_test_scrap
	D.materials = list("steel" = 1000)
	D.time = 6000
	steel.stored_material = 1000
	var/start_time = world.time
	R.addToQueue(D)
	var/obj/item/replicator_test_scrap/item = locate() in T
	if(item || !R.busy || R.producing_design != D || R.pulses != 1 || R.last_flash_duration != 3 SECONDS || steel.stored_material != 1000)
		failure += "Production did not start its three-second effects before creating the item. "
	sleep(15)
	if((locate(/obj/item/replicator_test_scrap) in T) || !R.busy)
		failure += "Production completed before three seconds. "
	sleep(16)
	item = locate() in T
	if(!item || R.busy || R.pulses != 1 || steel.stored_material != 0 || length(R.queue) || world.time - start_time < 3 SECONDS)
		failure += "Printing: item=[item], pulses=[R.pulses], steel=[steel.stored_material], queue=[length(R.queue)], status=[R.stat]. "
	R.Process()
	if(R.pulses != 1)
		failure += "Idle processing repeated the pulse. "
	if(item)
		start_time = world.time
		if(!R.reclaim(item) || R.reclaim(item) || !QDELETED(item) || world.time != start_time)
			failure += "Platform reclamation was delayed or accepted the same item twice. "
		if(R.pulses != 2 || steel.stored_material != 300 || R.converting || R.busy)
			failure += "Instant reclamation failed to recover material and pulse once. "
	item = new(T)
	R.test_power = FALSE
	R.stat = NOPOWER
	R.addToQueue(D)
	if(R.reclaim(item) || QDELETED(item) || item.loc != T || R.pulses != 2 || R.converting || R.busy || length(R.queue) != 1)
		failure += "Unpowered conversion consumed an item, emitted a pulse, or lost its pending request. "
	R.removeFromQueue(1)
	R.test_power = TRUE
	R.stat = 0
	item.forceMove(R)
	if(R.reclaim(item) || QDELETED(item) || R.pulses != 2)
		failure += "An inserted item was reclaimed. "
	item.forceMove(T)
	steel.stored_material = steel.capacity - 10
	R.reclaim(item)
	if(steel.stored_material != steel.capacity || R.pulses != 3)
		failure += "Reclamation exceeded storage capacity or failed to flash. "
	var/obj/item/replicator_test_scrap/container = new(T)
	var/obj/item/contents = new(container)
	if(R.can_reclaim(container))
		failure += "A filled container could be reclaimed. "
	qdel(contents)
	if(R.reclaim(container) || container.loc != T)
		failure += "Full storage accepted reclamation or moved an item. "
	if(!C.topic_requires_research_access(list("reclaim" = 1)))
		failure += "Reclamation bypassed research access. "
	var/mob/living/replicator_radiation_probe/holder = new(T)
	container.forceMove(holder)
	if(R.can_reclaim(container))
		failure += "An item held by someone standing on the platform was accepted. "
	container.forceMove(get_step(T, NORTH))
	if(R.can_reclaim(container))
		failure += "An adjacent item was accepted. "
	var/obj/item/stack/material/steel/sheets = new(T, 3)
	steel.stored_material = steel.capacity - sheets.perunit * 2
	if(!R.reclaim(sheets))
		failure += "Could not reclaim sheets directly from the platform. "
	if(steel.stored_material != steel.capacity || QDELETED(sheets) || sheets.get_amount() != 1 || R.pulses != 4)
		failure += "Sheet conversion failed to respect stack amount/storage capacity. "
	qdel(sheets)
	steel.stored_material = 0
	R.addToQueue(D)
	R.addToQueue(D)
	if(length(R.queue) != 2 || R.pulses != 4)
		failure += "Requests without materials were not held in the queue. "
	sheets = new(T, 3)
	var/expected_material = sheets.perunit * 3 - 2000
	start_time = world.time
	R.reclaim(sheets)
	if(!QDELETED(sheets) || !R.busy || length(R.queue) != 1 || R.pulses != 6 || world.time != start_time)
		failure += "Instant reclamation did not immediately start the next production cycle. "
	sleep(61)
	if(R.busy || length(R.queue) || R.pulses != 7 || steel.stored_material != expected_material)
		failure += "Queued items did not finish in consecutive three-second cycles. "
	R.addToQueue(D)
	steel.locked = TRUE
	sleep(31)
	if(R.busy || length(R.queue) != 1 || steel.stored_material != expected_material)
		failure += "A compartment locked during production was consumed. "
	steel.locked = FALSE
	R.Process()
	sleep(31)
	if(R.busy || length(R.queue) || steel.stored_material != expected_material - 1000)
		failure += "An interrupted request did not resume after unlocking. "
	for(var/obj/item/replicator_test_scrap/output in T)
		qdel(output)
	qdel(holder)
	qdel(container)
	qdel(R)
	qdel(C)
	qdel(D)
	qdel(storage)
	GLOB.replicator_storages = original_storages
	T.ChangeTurf(old_turf_type)
	if(length(failure))
		fail(failure)
	else
		pass("Three-second production starts effects immediately; instant reclamation, queued work, lock rechecks, power, tile-only targets and capacity verified.")
	return TRUE

/datum/unit_test/replicator_connections
	name = "REPLICATOR - Map-wide nearest device selection and connection lifecycle"

/datum/unit_test/replicator_connections/start_test()
	var/failure = ""
	var/origin_x = world.maxx - 90
	var/origin_y = world.maxy - 90
	var/test_z = world.maxz
	var/list/turf_types = list()
	var/list/fixture_turfs = list(
		locate(origin_x, origin_y, test_z),
		locate(origin_x + 20, origin_y, test_z),
		locate(origin_x + 10, origin_y, test_z),
		locate(origin_x + 1, origin_y, test_z),
		locate(origin_x + 2, origin_y, test_z),
		locate(origin_x + 5, origin_y, test_z - 1)
	)
	for(var/turf/T in fixture_turfs)
		var/old_type = T.type
		var/turf/replacement = T.ChangeTurf(/turf/unsimulated/floor)
		turf_types[replacement] = old_type
	var/turf/origin = locate(origin_x, origin_y, test_z)
	var/obj/machinery/r_n_d/protolathe/far = new(locate(origin_x + 20, origin_y, test_z))
	var/obj/machinery/r_n_d/protolathe/near = new(locate(origin_x + 10, origin_y, test_z))
	var/obj/machinery/r_n_d/protolathe/open_panel = new(locate(origin_x + 1, origin_y, test_z))
	var/obj/machinery/r_n_d/protolathe/claimed = new(locate(origin_x + 2, origin_y, test_z))
	var/obj/machinery/r_n_d/protolathe/other_level = new(locate(origin_x + 5, origin_y, test_z - 1))
	var/obj/machinery/computer/rdconsole/owner = new(null)
	open_panel.panel_open = TRUE
	claimed.linked_console = owner
	owner.linked_lathe = claimed

	// Isolate synchronous discovery from real station machines; restore before yielding.
	var/list/original_machinery = SSmachines.machinery
	original_machinery -= list(far, near, open_panel, claimed, other_level, owner)
	SSmachines.machinery = list(far, near, open_panel, claimed)
	var/obj/machinery/computer/rdconsole/C = new(origin)
	if(C.linked_lathe != near || near.linked_console != C || far.linked_console)
		failure += "Initialization did not choose the nearest available replicator beyond four tiles. "
	if(claimed.linked_console != owner || open_panel.linked_console)
		failure += "Discovery stole a claimed device or connected through an open panel. "
	open_panel.panel_open = FALSE
	C.SyncRDevices()
	if(C.linked_lathe != open_panel || open_panel.linked_console != C || near.linked_console)
		failure += "Re-sync did not switch to a closer device and release the previous one. "
	open_panel.panel_open = TRUE
	C.SyncRDevices()
	if(C.linked_lathe != near || open_panel.linked_console)
		failure += "Re-sync retained an unavailable device. "
	SSmachines.machinery += other_level
	C.SyncRDevices()
	if(C.linked_lathe != other_level || near.linked_console)
		failure += "Discovery could not select the closest device on another map level. "
	// Equal-distance candidates should not cause the current connection to oscillate.
	far.forceMove(get_turf(other_level))
	C.SyncRDevices()
	if(C.linked_lathe != other_level || far.linked_console)
		failure += "Re-sync switched away from an equally close current device. "
	qdel(C)
	if(other_level.linked_console)
		failure += "Deleting the console did not release its replicator. "
	C = new(origin)
	var/obj/machinery/r_n_d/protolathe/selected = C.linked_lathe
	qdel(selected)
	if(C.linked_lathe)
		failure += "Deleting a replicator left a stale console connection. "
	C.SyncRDevices()
	if(!C.linked_lathe || QDELETED(C.linked_lathe))
		failure += "Re-sync failed to replace a deleted device. "
	selected = C.linked_lathe
	SSmachines.machinery = list(C)
	C.SyncRDevices()
	if(C.linked_lathe || selected.linked_console)
		failure += "No available replicators left stale links behind. "
	SSmachines.machinery = original_machinery

	for(var/obj/O in list(C, owner, far, near, open_panel, claimed, other_level))
		qdel(O)
	for(var/turf/T in turf_types)
		T.ChangeTurf(turf_types[T])
	if(length(failure))
		fail(failure)
	else
		pass("Remote/nearest selection, map levels, re-sync, ownership, panels and deletion verified.")
	return TRUE

/datum/unit_test/replicator_storage
	name = "REPLICATOR - Multi-object storage, shared capacity, access locks and placeholders"

/datum/unit_test/replicator_storage/start_test()
	var/failure = ""
	var/turf/origin = locate(world.maxx - 120, world.maxy - 120, world.maxz)
	var/list/original_storages = GLOB.replicator_storages
	GLOB.replicator_storages = list()
	var/obj/machinery/replicator_storage/A = new(origin)
	var/obj/machinery/replicator_storage/B = new(locate(origin.x + 6, origin.y, origin.z))
	var/obj/machinery/replicator_storage_compartment/steel_a = A.compartments["steel"]
	var/obj/machinery/replicator_storage_compartment/steel_b = B.compartments["steel"]
	var/obj/machinery/replicator_storage_compartment/elerium = A.compartments["plasteel"]
	var/obj/machinery/replicator_storage_compartment/zbrite = A.compartments["glass"]
	if(A.compartments.len != 3 || B.compartments.len != 3 || GLOB.replicator_storages.len != 2)
		failure += "Two independent complete structures were not created. "
	for(var/obj/machinery/replicator_storage/storage in list(A, B))
		for(var/material_id in storage.compartments)
			var/obj/machinery/replicator_storage_compartment/C = storage.compartments[material_id]
			if(!C.connected() || !C.locked || C.stored_material || C.capacity != 15 * SHEET_MATERIAL_AMOUNT)
				failure += "A compartment did not start empty, connected, locked and limited to 15 sheets. "
	if(get_turf(steel_a) != get_step(A, WEST) || get_turf(elerium) != get_step(A, EAST) || get_turf(zbrite) != get_step(A, SOUTH))
		failure += "The compartment arrangement does not match the reference. "
	var/mob/living/carbon/human/user = new(get_step(steel_a, WEST))
	var/obj/item/card/id/id = new(user)
	id.access = list()
	user.wear_id = id
	var/obj/machinery/r_n_d/protolathe/replicator_test/R = new(get_step(origin, NORTH))
	R.stat = 0
	var/obj/item/stack/material/steel/sheets = new(get_turf(user), 20)
	steel_a.attackby(sheets, user)
	if(steel_a.stored_material != steel_a.capacity || sheets.get_amount() != 5)
		failure += "Sheet loading exceeded the 15-sheet capacity or lost the excess. "
	steel_b.attackby(sheets, user)
	if(!QDELETED(sheets) || R.material_amount("steel") != 20 * SHEET_MATERIAL_AMOUNT || R.material_amount("steel", TRUE))
		failure += "Two structures did not retain separate locked supplies. "
	var/obj/item/stack/material/glass/glass = new(get_turf(user), 2)
	steel_a.attackby(glass, user)
	if(glass.get_amount() != 2)
		failure += "A compartment accepted the wrong material. "
	zbrite.attackby(glass, user)
	var/obj/item/stack/material/plasteel/plasteel = new(get_turf(user), 2)
	elerium.attackby(plasteel, user)
	if(!QDELETED(glass) || !QDELETED(plasteel) || zbrite.stored_material != 2 * SHEET_MATERIAL_AMOUNT || elerium.stored_material != 2 * SHEET_MATERIAL_AMOUNT)
		failure += "Glass/zbrite or plasteel/elerium mapping failed. "
	if(steel_a.toggle_lock(user) || !steel_a.locked)
		failure += "A user without science access changed a lock. "
	var/datum/design/D = new
	D.build_path = /obj/item/replicator_test_scrap
	D.materials = list("steel" = 20 * SHEET_MATERIAL_AMOUNT)
	R.addToQueue(D)
	if(R.canBuild(D) || R.pulses || length(R.queue) != 1)
		failure += "Locked supplies were consumed for production. "
	id.access = list(access_research)
	var/start_time = world.time
	if(!steel_a.toggle_lock(user) || steel_a.locked || world.time - start_time < 2 SECONDS || R.canBuild(D))
		failure += "The authorized two-second unlock or locked-stock exclusion failed. "
	user.forceMove(get_step(steel_b, WEST))
	if(!steel_b.toggle_lock(user) || R.pulses != 1 || !R.busy)
		failure += "Unlocking both structures did not start production. "
	sleep(31)
	if(R.busy || length(R.queue) || R.material_amount("steel"))
		failure += "Production did not consume unlocked stock from both structures. "
	if(!steel_b.toggle_lock(user) || !steel_b.locked)
		failure += "The unlocked compartment could not be locked again. "
	spawn(5)
		user.forceMove(get_step(user, NORTH))
	if(steel_b.toggle_lock(user) || !steel_b.locked || steel_b.changing_lock)
		failure += "Movement did not cancel the lock operation. "
	var/stored_before = zbrite.stored_material
	R.eject("glass", 1)
	if(zbrite.stored_material != stored_before || (locate(/obj/item/stack/material/glass) in get_turf(R)))
		failure += "A legacy withdrawal request extracted stored material. "
	R.store_material("glass", 100 * SHEET_MATERIAL_AMOUNT)
	if(R.material_amount("glass") != 30 * SHEET_MATERIAL_AMOUNT)
		failure += "Reclamation did not respect both compartments' capacities. "
	qdel(A)
	if(!QDELETED(steel_a) || !QDELETED(zbrite) || !QDELETED(elerium) || R.material_amount("glass") != 15 * SHEET_MATERIAL_AMOUNT)
		failure += "Deleting one structure left orphaned storage or removed the other structure's stock. "
	for(var/obj/item/replicator_test_scrap/output in get_turf(R))
		qdel(output)
	qdel(R)
	qdel(B)
	qdel(user)
	qdel(D)
	GLOB.replicator_storages = original_storages
	if(length(failure))
		fail(failure)
	else
		pass("Two complete structures, 15-sheet compartments, placeholders, shared production, science access, timed/interrupted locks and withdrawal protection verified.")
	return TRUE

#endif
