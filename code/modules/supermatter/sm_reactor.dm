#define SMR_STATE_OFF 0
#define SMR_STATE_RUNNING 1
#define SMR_STATE_SCRAMMED 2
#define SMR_STATE_DELAMINATING 3

#define SMR_ANOMALY_SURGE "surge"
#define SMR_ANOMALY_CASCADE "cascade"
#define SMR_ANOMALY_FRACTURE "fracture"
#define SMR_ANOMALY_RUNAWAY "runaway"

#define SMR_FIELD_DANGER 25

/obj/machinery/power/sm_reactor
	name = "supermatter reactor"
	desc = "A towering containment vessel wrapped around a phoron-fed supermatter lattice. The field emitters hum with barely restrained power."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "emfield_s3"
	density = 1
	anchored = 1
	layer = ABOVE_OBJ_LAYER
	bound_width = 96
	bound_height = 96
	appearance_flags = TILE_BOUND

	var/reactor_id = "sm_reactor"
	var/state = SMR_STATE_OFF

	var/output_level = 1
	var/max_output_level = 10
	var/min_power = 200000
	var/max_power = 1000000

	var/fuel_sheets = 0
	var/max_fuel_sheets = 100

	var/field = 100
	var/integrity = 100

	var/pulse_window_until = 0
	var/next_window_at = 0

	// Anomaly id -> world.time deadline (0 = no deadline).
	var/list/anomalies = list()
	var/next_anomaly_at = 0

	var/coolant_charges = 3
	var/max_coolant_charges = 3
	var/next_coolant_regen_at = 0

	var/scram_until = 0
	var/last_process = 0
	var/no_bus_logged = FALSE

/obj/machinery/power/sm_reactor/Initialize()
	. = ..()
	last_process = world.time
	update_icon()

/obj/machinery/power/sm_reactor/proc/level_fraction()
	return (output_level - 1) / max(1, max_output_level - 1)

/obj/machinery/power/sm_reactor/proc/current_output()
	. = Interpolate(min_power, max_power, level_fraction())
	if(anomalies[SMR_ANOMALY_SURGE])
		. *= 1.5

// Time for the field to fall from full to the danger threshold with no anomalies.
/obj/machinery/power/sm_reactor/proc/field_decay_time()
	return Interpolate(60 MINUTES, 5 MINUTES, level_fraction())

/obj/machinery/power/sm_reactor/proc/field_decay_rate()
	. = (100 - SMR_FIELD_DANGER) / field_decay_time()
	if(anomalies[SMR_ANOMALY_CASCADE])
		. *= 3
	else if(anomalies[SMR_ANOMALY_SURGE])
		. *= 2

/obj/machinery/power/sm_reactor/proc/sheet_burn_time()
	return Interpolate(5 MINUTES, 30 SECONDS, level_fraction())

/obj/machinery/power/sm_reactor/proc/schedule_window()
	var/gap = Interpolate(10 MINUTES, 90 SECONDS, level_fraction())
	next_window_at = world.time + rand(gap, gap * 2)

/obj/machinery/power/sm_reactor/proc/schedule_anomaly()
	var/mean = Interpolate(45 MINUTES, 4 MINUTES, level_fraction())
	next_anomaly_at = world.time + rand(mean * 0.5, mean * 1.5)

/obj/machinery/power/sm_reactor/proc/window_open()
	return state == SMR_STATE_RUNNING && world.time < pulse_window_until

/obj/machinery/power/sm_reactor/proc/center_turf()
	return locate(x + 1, y + 1, z) || get_turf(src)

/obj/machinery/power/sm_reactor/Process()
	var/dt = clamp(world.time - last_process, 0, 10 SECONDS)
	last_process = world.time

	if(state == SMR_STATE_DELAMINATING)
		return
	if(state != SMR_STATE_RUNNING)
		update_icon()
		return

	if(fuel_sheets <= 0)
		fuel_sheets = 0
		state = SMR_STATE_OFF
		anomalies.Cut()
		visible_message("<span class='notice'>\The [src] winds down as its phoron supply runs dry.</span>")
		update_icon()
		return

	var/burn_mult = anomalies[SMR_ANOMALY_SURGE] ? 1.5 : 1
	fuel_sheets = max(0, fuel_sheets - (dt / sheet_burn_time()) * burn_mult)
	if(!powernet)
		var/datum/power_node/N = get_power_node()
		if(N && N.out_net)
			powernet = N.out_net
		else if(!no_bus_logged)
			no_bus_logged = TRUE
			log_error("SM reactor at [x],[y],[z] has no power bus (CCID [ccid]); check its power link.")
	add_avail(current_output())

	field = max(0, field - field_decay_rate() * dt)
	if(field < SMR_FIELD_DANGER)
		// At zero field the core goes from intact to delamination in about two minutes.
		adjust_integrity(-((SMR_FIELD_DANGER - field) / SMR_FIELD_DANGER) * (100 / (2 MINUTES)) * dt)
	if(anomalies[SMR_ANOMALY_FRACTURE])
		adjust_integrity(-(100 / (30 MINUTES)) * dt)

	process_window()
	process_anomalies()

	if(coolant_charges < max_coolant_charges && world.time >= next_coolant_regen_at)
		coolant_charges++
		next_coolant_regen_at = world.time + 20 MINUTES

	SSradiation.radiate(center_turf(), output_level * 2)

	if(integrity <= 0)
		delaminate()
	update_icon()

/obj/machinery/power/sm_reactor/proc/process_window()
	if(pulse_window_until && world.time >= pulse_window_until)
		pulse_window_until = 0
		schedule_window()
	if(!pulse_window_until && world.time >= next_window_at)
		pulse_window_until = world.time + 30 SECONDS

/obj/machinery/power/sm_reactor/proc/process_anomalies()
	for(var/id in anomalies.Copy())
		var/deadline = anomalies[id]
		if(!deadline || world.time < deadline)
			continue
		anomalies -= id
		switch(id)
			if(SMR_ANOMALY_SURGE)
				adjust_integrity(-10)
				visible_message("<span class='danger'>\The [src] shudders as an unchecked phoron surge scours the core!</span>")
			if(SMR_ANOMALY_RUNAWAY)
				adjust_integrity(-15)
				visible_message("<span class='danger'>\The [src] glows white-hot as a thermal runaway burns through the lattice!</span>")
			if(SMR_ANOMALY_CASCADE)
				visible_message("<span class='notice'>The harmonic whine from \the [src] fades on its own.</span>")

	if(world.time < next_anomaly_at)
		return
	schedule_anomaly()
	var/list/possible = list(SMR_ANOMALY_SURGE, SMR_ANOMALY_CASCADE, SMR_ANOMALY_FRACTURE, SMR_ANOMALY_RUNAWAY) - anomalies
	if(!length(possible))
		return
	var/id = pick(possible)
	switch(id)
		if(SMR_ANOMALY_SURGE)
			anomalies[id] = world.time + 60 SECONDS
			visible_message("<span class='warning'>\The [src] roars as a phoron surge floods the core!</span>")
		if(SMR_ANOMALY_CASCADE)
			anomalies[id] = world.time + 3 MINUTES
			visible_message("<span class='warning'>A rising harmonic whine builds inside \the [src].</span>")
		if(SMR_ANOMALY_FRACTURE)
			anomalies[id] = 0
			visible_message("<span class='warning'>Something cracks loudly inside \the [src]'s housing.</span>")
		if(SMR_ANOMALY_RUNAWAY)
			anomalies[id] = world.time + 90 SECONDS
			visible_message("<span class='warning'>Heat ripples off \the [src] as its core temperature spikes.</span>")

/obj/machinery/power/sm_reactor/proc/adjust_integrity(amount)
	integrity = clamp(integrity + amount, 0, 100)

/obj/machinery/power/sm_reactor/proc/start_reactor()
	if(state == SMR_STATE_RUNNING || state == SMR_STATE_DELAMINATING)
		return FALSE
	if(world.time < scram_until || fuel_sheets <= 0 || integrity <= 0)
		return FALSE
	state = SMR_STATE_RUNNING
	last_process = world.time
	pulse_window_until = 0
	schedule_window()
	schedule_anomaly()
	update_icon()
	return TRUE

/obj/machinery/power/sm_reactor/proc/set_output_level(level)
	output_level = clamp(round(level), 1, max_output_level)

/obj/machinery/power/sm_reactor/proc/pulse_field()
	if(state != SMR_STATE_RUNNING)
		return FALSE
	if(window_open())
		field = 100
		pulse_window_until = 0
		schedule_window()
		return TRUE
	field = max(0, field - 5)
	adjust_integrity(-3)
	visible_message("<span class='warning'>\The [src]'s containment field flickers violently from a mistimed pulse!</span>")
	return FALSE

/obj/machinery/power/sm_reactor/proc/resolve_anomaly(id)
	if(state != SMR_STATE_RUNNING || !(id in anomalies) || id == SMR_ANOMALY_FRACTURE)
		return FALSE
	if(id == SMR_ANOMALY_RUNAWAY)
		if(coolant_charges <= 0)
			return FALSE
		if(coolant_charges == max_coolant_charges)
			next_coolant_regen_at = world.time + 20 MINUTES
		coolant_charges--
	anomalies -= id
	return TRUE

/obj/machinery/power/sm_reactor/proc/scram()
	if(state != SMR_STATE_RUNNING)
		return FALSE
	if(integrity < 15)
		visible_message("<span class='danger'>\The [src]'s control rods jam against the warped lattice!</span>")
		return FALSE
	state = SMR_STATE_SCRAMMED
	scram_until = world.time + 5 MINUTES
	pulse_window_until = 0
	anomalies -= list(SMR_ANOMALY_SURGE, SMR_ANOMALY_CASCADE, SMR_ANOMALY_RUNAWAY)
	visible_message("<span class='notice'>\The [src] slams its control rods home and falls silent.</span>")
	update_icon()
	return TRUE

/obj/machinery/power/sm_reactor/update_icon()
	switch(state)
		if(SMR_STATE_DELAMINATING)
			color = "#ff2222"
			set_light(8, 4, "#ff2222")
		if(SMR_STATE_RUNNING)
			if(field < SMR_FIELD_DANGER || integrity < 50)
				color = "#ff8844"
				set_light(6, 3, "#ff8844")
			else if(window_open())
				color = "#ccffff"
				set_light(6, 3, "#ccffff")
			else
				color = "#88aaff"
				set_light(5, 2, "#88aaff")
		else
			color = "#666666"
			set_light(0)

/obj/machinery/power/sm_reactor/examine(mob/user)
	. = ..()
	switch(state)
		if(SMR_STATE_RUNNING)
			to_chat(user, "It is running, producing roughly [round(current_output() / 1000)] kW.")
		if(SMR_STATE_SCRAMMED)
			to_chat(user, "It has been SCRAMmed and is locked out.")
		if(SMR_STATE_DELAMINATING)
			to_chat(user, "<span class='danger'>Its lattice is tearing itself apart!</span>")
		else
			to_chat(user, "It is offline.")
	to_chat(user, "The fuel gauge reads [round(fuel_sheets, 0.1)] sheet\s of phoron.")
	if(integrity < 50)
		to_chat(user, "<span class='warning'>The housing is badly warped.</span>")
	else if(integrity < 100)
		to_chat(user, "The housing shows signs of stress.")
	if(anomalies[SMR_ANOMALY_FRACTURE])
		to_chat(user, "<span class='warning'>A glowing fracture runs across the lattice housing. It could be welded shut.</span>")

/obj/machinery/power/sm_reactor/proc/load_phoron(obj/item/stack/material/phoron/sheets)
	if(!istype(sheets) || QDELETED(sheets) || state == SMR_STATE_DELAMINATING)
		return 0
	var/amount = min(max(0, Floor(max_fuel_sheets - fuel_sheets)), sheets.amount)
	if(amount < 1 || !sheets.use(amount))
		return 0
	fuel_sheets += amount
	return amount

/obj/machinery/power/sm_reactor/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/stack/material/phoron))
		if(state == SMR_STATE_DELAMINATING)
			return
		var/amount = load_phoron(O)
		if(amount < 1)
			to_chat(user, "<span class='notice'>\The [src]'s fuel hopper is full.</span>")
			return
		to_chat(user, "<span class='notice'>You load [amount] sheet\s of phoron into \the [src].</span>")
		return

	if(isWelder(O))
		var/obj/item/weldingtool/WT = O
		var/repairing_fracture = (SMR_ANOMALY_FRACTURE in anomalies)
		if(!repairing_fracture && (state == SMR_STATE_RUNNING || integrity >= 100))
			to_chat(user, "<span class='notice'>There is nothing on \the [src] you can weld right now.</span>")
			return
		if(!WT.remove_fuel(0, user))
			return
		playsound(src, 'sound/items/Welder.ogg', 100, 1)
		user.visible_message("<span class='notice'>\The [user] starts welding \the [src]'s housing.</span>")
		if(!do_after(user, 5 SECONDS, src) || !WT.isOn())
			return
		if(repairing_fracture)
			anomalies -= SMR_ANOMALY_FRACTURE
			to_chat(user, "<span class='notice'>You seal the fracture in \the [src]'s lattice housing.</span>")
		else if(state != SMR_STATE_RUNNING && state != SMR_STATE_DELAMINATING)
			adjust_integrity(10)
			to_chat(user, "<span class='notice'>You patch some of the stress damage on \the [src].</span>")
		return
	return ..()

/obj/machinery/power/sm_reactor/ex_act(severity)
	adjust_integrity(-30 / severity)

/obj/machinery/power/sm_reactor/emp_act(severity)
	if(state == SMR_STATE_RUNNING)
		field = max(0, field - 30 / severity)

/obj/machinery/power/sm_reactor/proc/delaminate()
	set waitfor = 0

	if(state == SMR_STATE_DELAMINATING)
		return
	state = SMR_STATE_DELAMINATING
	update_icon()
	log_and_message_admins("Supermatter reactor delaminating at [x] [y] [z]")
	visible_message("<span class='danger'>\The [src]'s containment collapses and the core begins to delaminate!</span>")
	var/explosion_power = Interpolate(8, 16, level_fraction())
	sleep(30 SECONDS)

	var/turf/TS = center_turf()
	if(!istype(TS))
		return
	var/list/affected_z = GetConnectedZlevels(TS.z)

	for(var/affected in affected_z)
		SSradiation.z_radiate(locate(1, 1, affected), 20, 1)

	for(var/mob/living/mob in GLOB.living_mob_list_)
		var/turf/TM = get_turf(mob)
		if(!TM || !(TM.z in affected_z))
			continue
		mob.Weaken(4)
		to_chat(mob, "<span class='danger'>An invisible force slams you against the ground!</span>")
		if(iscarbon(mob))
			var/mob/living/carbon/C = mob
			var/area/A = get_area(TM)
			if(A && !(A.area_flags & AREA_FLAG_RAD_SHIELDED))
				var/dist = 200 - get_dist(TS, C)
				if(dist >= 1)
					C.hallucination(round(dist * 1.5), dist)

	for(var/obj/machinery/power/area_smes/A in SSmachines.machinery)
		if(!(A.z in affected_z))
			continue
		if(prob(10))
			A.overload_lighting()
		var/random_change = rand(80, 120) / 100
		A.energy_fail(round((A.is_critical ? 10 : 120) * random_change))

	for(var/obj/machinery/power/smes/buildable/S in SSmachines.machinery)
		if(!(S.z in affected_z))
			continue
		S.energy_fail(round(60 * rand(80, 120) / 100))
		if(prob(100 - get_dist(TS, S) * 0.5))
			S.grounding = 0

	for(var/obj/machinery/power/solar/S in SSmachines.machinery)
		if((S.z in affected_z) && prob(60))
			S.set_broken(TRUE)

	explosion(TS, explosion_power * 0.5, explosion_power, explosion_power * 2, explosion_power * 4, 1)
	qdel(src)

/obj/machinery/disposal/deliveryChute/phoron_feeder
	name = "supermatter phoron inlet"
	desc = "A fuel delivery chute that accepts only phoron sheets and feeds a linked supermatter reactor. Excess fuel remains in the chute until the reactor has room."
	use_power = POWER_USE_OFF
	var/reactor_id = "sm_reactor"

/obj/machinery/disposal/deliveryChute/phoron_feeder/can_load(atom/movable/thing)
	return istype(thing, /obj/item/stack/material/phoron)

/obj/machinery/disposal/deliveryChute/phoron_feeder/attackby(obj/item/item, mob/user)
	if(!item || !user || (stat & BROKEN))
		return
	if(!can_load(item))
		to_chat(user, "<span class='warning'>\The [src] only accepts phoron sheets.</span>")
		return
	if(isrobot(user) || !user.drop_from_inventory(item, src))
		return
	add_fingerprint(user, 0, item)
	to_chat(user, "<span class='notice'>You place \the [item] into \the [src].</span>")
	flush()

/obj/machinery/disposal/deliveryChute/phoron_feeder/CanPass(atom/movable/mover, turf/target, height = 0, air_group = 0)
	if(!can_load(mover))
		return FALSE
	return ..()

/obj/machinery/disposal/deliveryChute/phoron_feeder/Process()
	flush()

/obj/machinery/disposal/deliveryChute/phoron_feeder/flush()
	flush = 0
	if(stat & BROKEN)
		return
	var/turf/source_turf = get_turf(src)
	if(!source_turf)
		return
	var/list/valid_z = GetConnectedZlevels(source_turf.z)
	for(var/obj/machinery/power/sm_reactor/reactor in SSmachines.machinery)
		if(reactor.reactor_id != reactor_id || !(reactor.z in valid_z))
			continue
		for(var/obj/item/stack/material/phoron/sheets in contents.Copy())
			if(!reactor.load_phoron(sheets))
				break
		return

#undef SMR_FIELD_DANGER
