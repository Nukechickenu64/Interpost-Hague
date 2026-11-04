// Reference implementations below are frozen from the pre-optimization code.
// Keep them independent: these tests check equivalence, including live changes.
/datum/unit_test/simulation_optimization_atmos
	name = "OPTIMIZATION - Atmos equivalence and vent lifecycle"

/datum/unit_test/simulation_optimization_atmos/start_test()
	var/list/registered = list()
	for(var/obj/machinery/atmospherics/unary/vent_pump/V in SSmachines.machinery)
		registered += V
	if(registered.len != station_supply_vents.len)
		fail("Vent registry differs from machinery membership.")
	else
		for(var/i in 1 to registered.len)
			if(registered[i] != station_supply_vents[i])
				fail("Vent registry changed allocation order at [i].")
	var/obj/machinery/atmospherics/unary/vent_pump/temporary = new(get_safe_turf())
	if(!(temporary in station_supply_vents))
		fail("Constructed vent was not registered.")
	var/area/vent_area = get_area(temporary)
	var/obj/container = new(get_safe_turf())
	for(var/inside_container in list(FALSE, TRUE))
		if(inside_container)
			temporary.forceMove(container)
		var/list/area_vents = list()
		for(var/obj/machinery/atmospherics/unary/vent_pump/V in vent_area)
			area_vents += V
		var/list/registry_vents = list()
		for(var/obj/machinery/atmospherics/unary/vent_pump/V as anything in station_supply_vents)
			if(isturf(V.loc) && get_area(V) == vent_area)
				registry_vents += V
		if((area_vents - registry_vents).len || (registry_vents - area_vents).len)
			fail("Lockdown vent membership changed for contained=[inside_container].")
	qdel(temporary)
	qdel(container)
	if(temporary in station_supply_vents)
		fail("Deleted vent remained registered.")
	for(var/case_id in 1 to 60)
		var/datum/gas_mixture/A = new(CELL_VOLUME, case_id % 3 ? T20C : 0, case_id)
		var/datum/gas_mixture/B = new(CELL_VOLUME, case_id % 4 ? 500 : 0, 61 - case_id)
		if(case_id % 5)
			A.adjust_multi(GAS_OXYGEN, case_id, GAS_NITROGEN, 20)
		if(case_id % 7)
			B.adjust_multi(GAS_CO2, 5, GAS_NITROGEN, case_id * 2)
		var/datum/gas_mixture/RA = new(A.volume, A.temperature, A.group_multiplier)
		var/datum/gas_mixture/RB = new(B.volume, B.temperature, B.group_multiplier)
		RA.copy_from(A)
		RB.copy_from(B)
		var/ratio = case_id % 3 ? 1 : 0.4
		var/one_way = case_id % 4 == 0
		var/result = A.share_ratio(B, 1, one_way = one_way, transfer_ratio = ratio)
		var/expected = RA.optimization_reference_share(RB, 1, one_way = one_way, transfer_ratio = ratio)
		if(result != expected || A.temperature != RA.temperature || B.temperature != RB.temperature || A.total_moles != RA.total_moles || B.total_moles != RB.total_moles)
			fail("Gas totals, temperature or sleep decision changed in case [case_id].")
		for(var/g in gas_data.gases)
			if(A.gas[g] != RA.gas[g] || B.gas[g] != RB.gas[g])
				fail("Gas [g] changed in case [case_id].")
		qdel(A)
		qdel(B)
		qdel(RA)
		qdel(RB)
	log_debug("Reserve scan candidates: [SSmachines.machinery.len] machines -> [station_supply_vents.len] vents.")
	var/datum/gas_mixture/bench_a = new(CELL_VOLUME, T20C, 10)
	var/datum/gas_mixture/bench_b = new(CELL_VOLUME, T20C, 30)
	bench_a.adjust_multi(GAS_OXYGEN, 50, GAS_NITROGEN, 100, GAS_CO2, 3)
	bench_b.copy_from(bench_a)
	var/start = REALTIMEOFDAY
	for(var/i in 1 to 20000)
		bench_a.optimization_reference_share(bench_b, 1, transfer_ratio = 1)
	var/reference_time = REALTIMEOFDAY - start
	start = REALTIMEOFDAY
	for(var/i in 1 to 20000)
		bench_a.share_ratio(bench_b, 1, transfer_ratio = 1)
	log_debug("20000 equalizations: original [reference_time] ds, optimized [REALTIMEOFDAY - start] ds.")
	qdel(bench_a)
	qdel(bench_b)
	if(!reported) pass("60 mixed/vacuum/grouped/one-way cases match the original, and vent membership/order/lifecycle are intact.")
	return TRUE

/datum/unit_test/simulation_optimization_shadows
	name = "OPTIMIZATION - Cached shadow masks match original sampling"

/datum/unit_test/simulation_optimization_shadows/start_test()
	var/turf/C = lighting_los_fixture()
	var/area/A = get_area(C)
	var/old_dynamic = A.dynamic_lighting
	A.dynamic_lighting = TRUE
	for(var/turf/T in range(9, C))
		T.lighting_build_overlay()
	var/obj/actor = new(C)
	actor.icon = 'icons/obj/storage.dmi'
	actor.icon_state = "crate"
	actor.casts_dynamic_shadow = TRUE
	var/obj/lamp = new(locate(C.x + 3, C.y + 1, C.z))
	var/obj/fill = new(locate(C.x - 3, C.y, C.z))
	lamp.set_light(8, 4, "#ffffff")
	var/atom/movable/dynamic_shadow/optimized = new(null, actor)
	var/atom/movable/dynamic_shadow/reference = new(null, actor)
	optimized.copy_owner_appearance()
	reference.copy_owner_appearance()
	var/list/old_scan = list()
	var/list/new_scan = list()
	var/list/scanned = list()
	for(var/turf/center in list(C, get_step(C, EAST), C))
		for(var/atom/movable/AM in range(5, center))
			if(AM.casts_dynamic_shadow)
				old_scan[AM] = TRUE
		SSdynamic_shadows.collect_view(center, 5, new_scan, scanned)
	if((old_scan - new_scan).len || (new_scan - old_scan).len)
		fail("Overlapping view scan changed caster membership.")
	for(var/case_id in 1 to 32)
		actor.pixel_x = case_id % 8
		actor.pixel_y = -(case_id % 5)
		fill.set_light(8, case_id % 4, case_id % 2 ? "#00ff00" : "#ffffff")
		SSlighting.fire(FALSE, TRUE)
		var/dx = sin(case_id * 360 / 32) * 3
		var/dy = cos(case_id * 360 / 32) * 3
		var/matrix/M = dynamic_shadow_projection(dx, dy, 3, 1.05, 16)
		optimized.update_light_mask(lamp.light, M, dx, dy, 3)
		reference.optimization_reference_mask(lamp.light, M, dx, dy, 3)
		if(optimized.light_mask_signature != reference.light_mask_signature)
			fail("Mask differs from original in projection [case_id].")
		var/list/receivers = optimized.mask_receivers
		optimized.update_light_mask(lamp.light, M, dx, dy, 3)
		if(optimized.mask_receivers != receivers)
			fail("Stationary refresh rebuilt projected geometry.")
		// Lighting may change without moving the caster or its projected samples.
		fill.set_light(8, (case_id + 2) % 4)
		SSlighting.fire(FALSE, TRUE)
		optimized.update_light_mask(lamp.light, M, dx, dy, 3)
		reference.optimization_reference_mask(lamp.light, M, dx, dy, 3)
		if(optimized.light_mask_signature != reference.light_mask_signature || optimized.mask_receivers != receivers)
			fail("Stationary lighting change was missed or rebuilt geometry.")
	// Use the same final scene for a conservative native timing comparison.
	var/matrix/M = dynamic_shadow_projection(3, 1, sqrt(10), 1, 16)
	optimized.update_light_mask(lamp.light, M, 3, 1, sqrt(10))
	var/icon/unchanged_mask = optimized.light_mask
	actor.icon_state = ""
	optimized.copy_owner_appearance()
	optimized.update_light_mask(lamp.light, M, 3, 1, sqrt(10))
	if(optimized.light_mask != unchanged_mask)
		fail("An appearance-only change rebuilt an unchanged light mask.")
	// Moving the caster and changing even a very small matrix component must
	// invalidate geometry, without relying on rounded text signatures.
	var/list/old_receivers = optimized.mask_receivers
	actor.loc = get_step(C, NORTH)
	optimized.update_light_mask(lamp.light, M, 3, 1, sqrt(10))
	reference.optimization_reference_mask(lamp.light, M, 3, 1, sqrt(10))
	if(optimized.mask_receivers == old_receivers || optimized.light_mask_signature != reference.light_mask_signature)
		fail("Caster movement failed to refresh projected receivers.")
	old_receivers = optimized.mask_receivers
	M.c += 0.000001
	optimized.update_light_mask(lamp.light, M, 3, 1, sqrt(10))
	reference.optimization_reference_mask(lamp.light, M, 3, 1, sqrt(10))
	if(optimized.mask_receivers == old_receivers || optimized.light_mask_signature != reference.light_mask_signature)
		fail("Fractional matrix change failed to refresh projected receivers.")
	// Replacing a receiving turf must not leave a stale cached reference.
	var/turf/replaced = optimized.mask_tile_alpha[1]
	replaced.ChangeTurf(/turf/unsimulated/floor)
	SSlighting.fire(FALSE, TRUE)
	optimized.update_light_mask(lamp.light, M, 3, 1, sqrt(10))
	reference.optimization_reference_mask(lamp.light, M, 3, 1, sqrt(10))
	if(optimized.light_mask_signature != reference.light_mask_signature)
		fail("Receiving turf replacement changed cached mask output.")
	var/start = REALTIMEOFDAY
	for(var/i in 1 to 1000)
		reference.optimization_reference_mask(lamp.light, M, 3, 1, sqrt(10))
	var/reference_time = REALTIMEOFDAY - start
	start = REALTIMEOFDAY
	for(var/i in 1 to 1000)
		optimized.update_light_mask(lamp.light, M, 3, 1, sqrt(10))
	log_debug("1000 stationary masks: original [reference_time] ds, cached [REALTIMEOFDAY - start] ds; [optimized.mask_receivers.len] samples, [optimized.mask_tile_alpha.len] receiving tiles.")
	// Larger sprites and map-edge samples include null receivers.
	actor.loc = locate(1, 1, C.z)
	optimized.source_width = reference.source_width = 64
	optimized.source_height = reference.source_height = 64
	optimized.update_light_mask(lamp.light, M, 3, 1, sqrt(10))
	reference.optimization_reference_mask(lamp.light, M, 3, 1, sqrt(10))
	if(optimized.light_mask_signature != reference.light_mask_signature)
		fail("Resized/map-edge mask differs from original.")
	for(var/atom/O in list(optimized, reference, actor, lamp, fill))
		qdel(O)
	SSlighting.fire(FALSE, TRUE)
	A.dynamic_lighting = old_dynamic
	if(!reported) pass("64 projection/live-light cases match original alpha samples; stationary geometry is reused.")
	return TRUE

// Frozen reference: original spatial mask sampling.
/atom/movable/dynamic_shadow/proc/optimization_reference_mask(datum/light_source/casting_light, matrix/M, dx, dy, distance)
	var/width = source_width + world.icon_size
	var/height = source_height + world.icon_size
	var/ox = owner.x + (owner.pixel_x + (source_width - world.icon_size) / 2) / world.icon_size
	var/oy = owner.y + (owner.pixel_y + (source_height - world.icon_size) / 2) / world.icon_size
	var/list/tile_alpha = list()
	var/list/samples = list()
	var/needs_mask = FALSE
	for(var/py in 1 to height step 4)
		for(var/px in 1 to width step 4)
			var/u = px + (4 - 1) / 2 - (width + 1) / 2
			var/v = py + (4 - 1) / 2 - (height + 1) / 2
			var/turf/receiver = locate(round(ox + (M.a * u + M.b * v + M.c) / world.icon_size + 0.5), round(oy + (M.d * u + M.e * v + M.f) / world.icon_size + 0.5), owner.z)
			var/strength = 0
			if(receiver)
				if(isnull(tile_alpha[receiver]))
					tile_alpha[receiver] = round(255 * owner.dynamic_shadow_retention(casting_light, receiver, dx, dy, distance))
				strength = tile_alpha[receiver]
			samples += strength
			if(strength != 255) needs_mask = TRUE
	var/signature = "[width],[height]:[jointext(samples, ",")]"
	if(signature == light_mask_signature)
		return
	light_mask_signature = signature
	light_mask = null
	if(needs_mask)
		light_mask = icon(get_solid_white_icon())
		light_mask.Scale(width, height)
		light_mask.Blend("#00000000", ICON_MULTIPLY)
		var/i = 0
		for(var/py in 1 to height step 4)
			for(var/px in 1 to width step 4)
				light_mask.DrawBox(rgb(255, 255, 255, samples[++i]), px, py, min(px + 4 - 1, width), min(py + 4 - 1, height))
	set_shadow_filters()


// Frozen reference: original gas sharing and equilibrium check.
/datum/gas_mixture/proc/optimization_reference_share(datum/gas_mixture/other, connecting_tiles, share_size = null, one_way = 0, transfer_ratio = null)
	var/static/list/sharing_lookup_table = list(0.30, 0.40, 0.48, 0.54, 0.60, 0.66)
	//Shares a specific ratio of gas between mixtures using simple weighted averages.
	var/ratio = sharing_lookup_table[6]

	var/size = max(1, group_multiplier)
	if(isnull(share_size)) share_size = max(1, other.group_multiplier)
	var/combined_size = size + share_size

	var/full_heat_capacity = heat_capacity()
	var/s_full_heat_capacity = other.heat_capacity()
	var/combined_heat_capacity = full_heat_capacity + s_full_heat_capacity

	var/temp_avg = 0
	if(combined_heat_capacity)
		temp_avg = (temperature * full_heat_capacity + other.temperature * s_full_heat_capacity) / combined_heat_capacity

	if(sharing_lookup_table.len >= connecting_tiles) //6 or more interconnecting tiles will max at 42% of air moved per tick.
		ratio = sharing_lookup_table[connecting_tiles]
	if(!isnull(transfer_ratio))
		ratio = clamp(transfer_ratio, 0, 1)

	var/remaining_ratio = 1 - ratio
	var/list/our_gases = gas
	var/list/other_gases = other.gas
	var/list/gas_ids = our_gases | other_gases
	for(var/gas_id in gas_ids)
		var/our_moles = our_gases[gas_id]
		var/average_moles = our_moles * size
		average_moles += other_gases[gas_id] * share_size
		average_moles /= combined_size
		our_gases[gas_id] = max(0, (our_moles - average_moles) * remaining_ratio + average_moles)
		if(!one_way)
			other_gases[gas_id] = max(0, (other_gases[gas_id] - average_moles) * remaining_ratio + average_moles)

	temperature = max(0, (temperature - temp_avg) * remaining_ratio + temp_avg)
	if(!one_way)
		other.temperature = max(0, (other.temperature - temp_avg) * remaining_ratio + temp_avg)

	update_values()
	other.update_values()

	return compare(other, compare_pressure = FALSE)


