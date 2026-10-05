/obj/effect/fluid
	name = ""
	icon = 'icons/effects/liquids.dmi'
	anchored = 1
	simulated = 0
	opacity = 0
	mouse_opacity = 0
	layer = DEEP_FLUID_LAYER
	plane = OBSERVER_PLANE
	alpha = 0
	color = COLOR_OCEAN // ill get to it

	var/temperature = T20C
	var/fluid_amount = 0
	var/turf/start_loc
	var/list/equalizing_fluids = list()
	var/equalize_avg_depth = 0
	var/equalize_avg_temp = 0
	var/flow_amount = 0

/obj/effect/fluid/urine
	color = COLOR_YELLOW

/obj/effect/fluid/ex_act()
	return

/obj/effect/fluid/airlock_crush()
	qdel(src)

/obj/effect/fluid/Initialize()
	. = ..()
	start_loc = get_turf(src)
	if(!istype(start_loc) || start_loc.flooded)
		qdel(src)
		return
	var/turf/simulated/T = start_loc
	if(istype(T))
		T.unwet_floor(FALSE)
	forceMove(start_loc)
	update_icon()

/obj/effect/fluid/Destroy()
	if(start_loc)
		var/turf/simulated/T = start_loc
		if(istype(T))
			T.wet_floor()
		start_loc = null
	if(islist(equalizing_fluids))
		equalizing_fluids.Cut()
	REMOVE_ACTIVE_FLUID(src)
	. = ..()

/obj/effect/fluid/update_icon()

	overlays.Cut()

	if(fluid_amount > FLUID_OVER_MOB_HEAD)
		layer = DEEP_FLUID_LAYER
	else
		layer = SHALLOW_FLUID_LAYER

	if(fluid_amount > FLUID_DEEP)
		alpha = FLUID_MAX_ALPHA
	else
		alpha = min(FLUID_MAX_ALPHA,max(FLUID_MIN_ALPHA,ceil(255*(fluid_amount/FLUID_DEEP))))

	if(fluid_amount > FLUID_DELETING && fluid_amount <= FLUID_EVAPORATION_POINT)
		APPLY_FLUID_OVERLAY("shallow_still")
	else if(fluid_amount > FLUID_EVAPORATION_POINT && fluid_amount < FLUID_SHALLOW)
		APPLY_FLUID_OVERLAY("mid_still")
	else if(fluid_amount >= FLUID_SHALLOW && fluid_amount < (FLUID_DEEP*2))
		APPLY_FLUID_OVERLAY("deep_still")
	else if(fluid_amount >= (FLUID_DEEP*2))
		APPLY_FLUID_OVERLAY("ocean")

// Map helper.
/obj/effect/fluid_mapped
	name = "mapped flooded area"
	alpha = 125
	icon_state = "shallow_still"
	color = COLOR_OCEAN

	var/fluid_amount = FLUID_MAX_DEPTH

/obj/effect/fluid_mapped/Initialize()
	..()
	var/turf/T = get_turf(src)
	if(istype(T))
		var/obj/effect/fluid/F = locate() in T
		if(!F) F = new(T)
		SET_FLUID_DEPTH(F, fluid_amount)
	return INITIALIZE_HINT_QDEL

// Permaflood overlay.
/obj/effect/flood
	name = ""
	mouse_opacity = 0
	layer = DEEP_FLUID_LAYER
	color = COLOR_OCEAN
	icon = 'icons/effects/liquids.dmi'
	icon_state = "ocean"
	alpha = FLUID_MAX_ALPHA
	simulated = 0
	density = 0
	opacity = 0
	anchored = 1

/obj/effect/flood/ex_act()
	return

/obj/effect/flood/New()
	..()
	verbs.Cut()

/obj/effect/floor_liquid
	name = "liquid puddle"
	desc = "A pool of spilled chemicals."
	icon = 'icons/effects/monke_liquid.dmi'
	icon_state = "water-0"
	layer = SHALLOW_FLUID_LAYER
	anchored = TRUE
	mouse_opacity = 0
	alpha = 160
	var/liquid_state = 1
	var/burning = FALSE
	var/last_process = 0
	var/list/contact_times = list()

/obj/effect/floor_liquid/Initialize()
	. = ..()
	var/turf/floor = loc
	if(!istype(floor, /turf/simulated/floor) || floor.density || floor.liquids)
		return INITIALIZE_HINT_QDEL
	floor.liquids = src
	create_reagents(1000)
	last_process = world.time
	START_PROCESSING(SSobj, src)

/obj/effect/floor_liquid/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/turf/floor = loc
	if(isturf(floor) && floor.liquids == src)
		floor.liquids = null
	contact_times = null
	return ..()

/obj/effect/floor_liquid/on_reagent_change()
	update_icon()

/obj/effect/floor_liquid/update_icon()
	if(!reagents)
		return
	var/volume = reagents.total_volume
	liquid_state = 1
	if(volume >= FLOOR_LIQUID_FULL_VOLUME)
		liquid_state = 5
	else if(volume >= FLOOR_LIQUID_SHOULDERS_VOLUME)
		liquid_state = 4
	else if(volume >= FLOOR_LIQUID_WAIST_VOLUME)
		liquid_state = 3
	else if(volume >= FLOOR_LIQUID_ANKLES_VOLUME)
		liquid_state = 2
	color = reagents.get_color()
	var/connections = 0
	var/turf/floor = loc
	if(isturf(floor))
		for(var/direction in GLOB.cardinal)
			var/turf/neighbor = get_step(floor, direction)
			if(neighbor && neighbor.liquids && can_flow(floor, neighbor, direction))
				connections |= direction
	icon_state = liquid_state == 1 ? "water-[connections]" : null
	alpha = min(200, 100 + liquid_state * 20)
	overlays.Cut()
	if(liquid_state > 1)
		var/image/bottom = image('icons/effects/monke_liquid_overlays.dmi', icon_state = "stage[liquid_state - 1]_bottom")
		bottom.layer = DEEP_FLUID_LAYER
		overlays += bottom
		overlays += image('icons/effects/monke_liquid_overlays.dmi', icon_state = "stage[liquid_state - 1]_top")
	if(burning)
		var/image/flames = image('icons/effects/monke_liquid.dmi', icon_state = burn_power() >= 9 ? "fire_big" : "fire_small")
		flames.appearance_flags = RESET_COLOR | RESET_ALPHA
		overlays += flames
		set_light(2, 1, "#ed9200")
	else
		set_light(0)

/obj/effect/floor_liquid/proc/can_flow(turf/source, turf/target, direction)
	if(!istype(target, /turf/simulated/floor) || target.density)
		return FALSE
	UPDATE_FLUID_BLOCKED_DIRS(source)
	UPDATE_FLUID_BLOCKED_DIRS(target)
	if((source.fluid_blocked_dirs & direction) || (target.fluid_blocked_dirs & GLOB.reverse_dir[direction]))
		return FALSE
	return source.CanFluidPass(GLOB.reverse_dir[direction]) && target.CanFluidPass(direction)

/obj/effect/floor_liquid/proc/spread()
	var/turf/floor = loc
	for(var/direction in shuffle(GLOB.cardinal.Copy()))
		if(reagents.total_volume < FLOOR_LIQUID_SPREAD_VOLUME)
			break
		var/turf/neighbor = get_step(floor, direction)
		if(!can_flow(floor, neighbor, direction))
			continue
		var/neighbor_volume = neighbor.liquids ? neighbor.liquids.reagents.total_volume : 0
		var/transfer = (reagents.total_volume - neighbor_volume) / 2
		if(transfer < FLOOR_LIQUID_SPREAD_VOLUME / 2)
			continue
		if(!neighbor.liquids)
			neighbor.liquids = new(neighbor)
		neighbor.liquids.reagents.maximum_volume = max(neighbor.liquids.reagents.maximum_volume, neighbor_volume + transfer)
		reagents.trans_to_holder(neighbor.liquids.reagents, transfer)
		neighbor.liquids.expose_floor()
		if(burning)
			neighbor.liquids.ignite()

/obj/effect/floor_liquid/proc/expose_floor()
	var/datum/reagents/exposure = new(10, GLOB.temp_reagents_holder)
	exposure.floor_liquid_exposure = TRUE
	reagents.trans_to_holder(exposure, min(10, reagents.total_volume))
	exposure.touch_turf(loc)
	exposure.trans_to_holder(reagents, exposure.total_volume)
	qdel(exposure)

/obj/effect/floor_liquid/proc/expose_mob(mob/living/target)
	if(!target || target.loc != loc || target.buckled || target.is_floating || !target.simulated)
		return
	if(contact_times[target] > world.time)
		return
	contact_times[target] = world.time + FLOOR_LIQUID_PROCESS_INTERVAL
	if(liquid_state == 1 && ishuman(target) && !target.lying)
		var/mob/living/carbon/human/human = target
		if(human.shoes)
			return
	var/amount = min(reagents.total_volume, target.lying ? 5 : liquid_state)
	var/datum/reagents/exposure = new(amount, GLOB.temp_reagents_holder)
	reagents.trans_to_holder(exposure, amount)
	exposure.touch_mob(target)
	exposure.splash_mob(target, exposure.total_volume)
	qdel(exposure)

/obj/effect/floor_liquid/Crossed(atom/movable/entering)
	. = ..()
	if(!isliving(entering))
		return
	var/mob/living/target = entering
	expose_mob(target)
	if(!target.lying && !target.buckled && !target.is_floating && target.m_intent == "run")
		for(var/datum/reagent/reagent in reagents.reagent_list)
			if(reagent.liquid_slippery && reagent.volume >= 5)
				target.slip("the liquid puddle", 3)
				break

/obj/effect/floor_liquid/proc/burn_power()
	if(!reagents.total_volume)
		return 0
	var/power = 0
	for(var/datum/reagent/reagent in reagents.reagent_list)
		power += reagent.liquid_fire_power * reagent.volume
	return power / reagents.total_volume

/obj/effect/floor_liquid/proc/ignite()
	if(burn_power() <= 5)
		return
	var/datum/gas_mixture/air = loc.return_air()
	if(!has_oxidizer(air))
		return
	burning = TRUE
	update_icon()
	return TRUE

/obj/effect/floor_liquid/proc/has_oxidizer(datum/gas_mixture/air)
	if(!air)
		return FALSE
	for(var/gas in air.gas)
		if((gas_data.flags[gas] & XGM_GAS_OXIDIZER) && QUANTIZE(air.gas[gas] * vsc.fire_consuption_rate) >= 0.1)
			return TRUE
	return FALSE

/obj/effect/floor_liquid/proc/take_reagents(datum/reagents/receiver, amount)
	if(!receiver || amount <= 0)
		return 0
	. = reagents.trans_to_holder(receiver, amount)
	if(!reagents.total_volume)
		qdel(src)

/obj/effect/floor_liquid/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature >= PHORON_MINIMUM_BURN_TEMPERATURE)
		ignite()

/obj/effect/floor_liquid/Process()
	if(world.time < last_process + FLOOR_LIQUID_PROCESS_INTERVAL)
		return
	var/seconds = min(5, (world.time - last_process) / 10)
	last_process = world.time
	if(!istype(loc, /turf/simulated/floor) || loc.density || !reagents.total_volume)
		qdel(src)
		return
	spread()
	for(var/mob/living/target in loc)
		expose_mob(target)
	for(var/mob/living/target in contact_times)
		if(QDELETED(target) || target.loc != loc)
			contact_times -= target
	if(burning)
		var/datum/gas_mixture/air = loc.return_air()
		if(burn_power() <= 5 || !has_oxidizer(air) || reagents.has_reagent(/datum/reagent/water, 5))
			burning = FALSE
		else
			var/turf/floor = loc
			var/datum/gas_mixture/exhaust = floor.remove_air(seconds * 0.5)
			if(exhaust)
				var/oxidizers = 0
				for(var/gas in exhaust.gas.Copy())
					if(gas_data.flags[gas] & XGM_GAS_OXIDIZER)
						oxidizers += exhaust.gas[gas]
						exhaust.adjust_gas(gas, -exhaust.gas[gas])
				if(oxidizers)
					exhaust.adjust_gas("carbon_dioxide", oxidizers)
					exhaust.temperature = max(exhaust.temperature, T20C + 500)
				floor.assume_air(exhaust)
			for(var/direction in GLOB.cardinal)
				var/turf/neighbor = get_step(floor, direction)
				if(neighbor && neighbor.liquids && !neighbor.liquids.burning && can_flow(floor, neighbor, direction))
					neighbor.liquids.ignite()
			for(var/mob/living/target in loc)
				target.FireBurn(burn_power(), T20C + 500, 125)
			for(var/atom/movable/target in loc)
				if(target != src)
					target.fire_act(air, T20C + 500, 125)
			for(var/datum/reagent/reagent in reagents.reagent_list.Copy())
				if(reagent.liquid_fire_power)
					reagents.remove_reagent(reagent.type, seconds * 0.5)
	for(var/datum/reagent/reagent in reagents.reagent_list.Copy())
		if(reagent.liquid_evaporation_rate && reagents.total_volume < FLOOR_LIQUID_ANKLES_VOLUME)
			reagents.remove_reagent(reagent.type, seconds * reagent.liquid_evaporation_rate)
	update_icon()
	if(!reagents.total_volume)
		qdel(src)