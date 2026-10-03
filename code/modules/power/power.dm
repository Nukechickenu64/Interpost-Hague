//////////////////////////////
// POWER MACHINERY BASE CLASS
//////////////////////////////

/////////////////////////////
// Definitions
/////////////////////////////

/obj/machinery/power
	name = null
	icon = 'icons/obj/power.dmi'
	anchored = 1.0
	var/datum/powernet/powernet = null
	var/datum/powernet/input_powernet = null	// only for split nodes (SMES-like)
	use_power = POWER_USE_OFF
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/power/Initialize()
	. = ..()
	connect_to_network()

/obj/machinery/power/Destroy()
	disconnect_from_network()
	. = ..()

/obj/machinery/power/is_power_linkable()
	return TRUE

/obj/machinery/power/power_nets_changed(datum/power_node/N)
	powernet = N.out_net
	input_powernet = N.split ? N.in_net : null

///////////////////////////////
// General procedures
//////////////////////////////


/obj/machinery/power/powered()
	if(use_power)
		return ..()
	return 1 //doesn't require an external power source

// common helper procs for all power machines
/obj/machinery/power/drain_power(var/drain_check, var/surge, var/amount = 0)
	if(drain_check)
		return 1

	if(powernet && powernet.avail)
		powernet.trigger_warning()
		return powernet.draw_power(amount)

/obj/machinery/power/proc/add_avail(var/amount)
	if(powernet)
		powernet.newavail += amount
		return 1
	return 0

/obj/machinery/power/proc/draw_power(var/amount)
	if(powernet)
		return powernet.draw_power(amount)
	return 0

/obj/machinery/power/proc/surplus()
	if(powernet)
		return powernet.avail-powernet.load
	else
		return 0

/obj/machinery/power/proc/avail()
	if(powernet)
		return powernet.avail
	else
		return 0

// Enable this machine's node so it joins whatever buses it is linked into.
/obj/machinery/power/proc/connect_to_network()
	var/datum/power_node/N = get_power_node()
	if(!N)
		return 0
	N.set_enabled(TRUE)
	return 1

// Keep links but leave every bus until reconnected.
/obj/machinery/power/proc/disconnect_from_network()
	if(!power_node)
		return 0
	power_node.set_enabled(FALSE)
	if(powernet)
		powernet.nodes -= src
		powernet = null
	if(input_powernet)
		input_powernet.input_nodes -= src
		input_powernet = null
	return 1

/proc/request_power_grid_rebuild()
	power_grid_dirty = TRUE

//Determines how strong could be shock, deals damage to mob, uses power.
//M is a mob who touched wire/whatever
//power_source is a source of electricity, can be powercell, area, area SMES, powernet or null
//source is an object caused electrocuting (airlock, grille, etc)
//No animations will be performed by this proc.
/proc/electrocute_mob(mob/living/carbon/M as mob, var/power_source, var/obj/source, var/siemens_coeff = 1.0)
	if(istype(M.loc,/obj/mecha))	return 0	//feckin mechs are dumb
	var/area/source_area
	if(istype(power_source,/area))
		source_area = power_source
		power_source = source_area.get_area_smes()

	var/datum/powernet/PN
	var/obj/item/cell/cell

	if(istype(power_source,/datum/powernet))
		PN = power_source
	else if(istype(power_source,/obj/item/cell))
		cell = power_source
	else if(istype(power_source,/obj/machinery/power/area_smes))
		var/obj/machinery/power/area_smes/smes = power_source
		cell = smes.cell
		PN = smes.powernet
	else if (!power_source)
		return 0
	else
		log_admin("ERROR: /proc/electrocute_mob([M], [power_source], [source]): wrong power_source")
		return 0
	//Triggers powernet warning, but only for 5 ticks (if applicable)
	//If following checks determine user is protected we won't alarm for long.
	if(PN)
		PN.trigger_warning(5)
	if(istype(M,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		if(H.species.siemens_coefficient <= 0)
			return
		if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves
			if(G.siemens_coefficient == 0)	return 0		//to avoid spamming with insulated glvoes on

	//Checks again. If we are still here subject will be shocked, trigger standard 20 tick warning
	//Since this one is longer it will override the original one.
	if(PN)
		PN.trigger_warning()

	if (!cell && !PN)
		return 0
	var/PN_damage = 0
	var/cell_damage = 0
	if (PN)
		PN_damage = PN.get_electrocute_damage()
	if (cell)
		cell_damage = cell.get_electrocute_damage()
	var/shock_damage = 0
	if (PN_damage>=cell_damage)
		power_source = PN
		shock_damage = PN_damage
	else
		power_source = cell
		shock_damage = cell_damage
	var/drained_hp = M.electrocute_act(shock_damage, source, siemens_coeff) //zzzzzzap!
	var/drained_energy = drained_hp*20

	if (source_area)
		source_area.use_power_oneoff(drained_energy/CELLRATE)
	else if (istype(power_source,/datum/powernet))
		var/drained_power = drained_energy/CELLRATE
		drained_power = PN.draw_power(drained_power)
	else if (istype(power_source, /obj/item/cell))
		cell.use(drained_energy)
	return drained_energy
