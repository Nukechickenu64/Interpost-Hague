/*

Overview:
	These are what handle gas transfers between zones and into space.
	They are found in a zone's edges list and in SSair.edges.
	Each edge updates every air tick due to their role in gas transfer.
	They come in two flavors, /connection_edge/zone and /connection_edge/unsimulated.
	As the type names might suggest, they handle inter-zone and spacelike connections respectively.

Class Vars:

	A - This always holds a zone. In unsimulated edges, it holds the only zone.

	connecting_turfs - This holds a list of connected turfs.

	coefficent - This is a marker for how many connections are on this edge. Used to determine the ratio of flow.

	connection_edge/zone

		B - This holds the second zone with which the first zone equalizes.

		direct - This counts the number of direct (i.e. with no doors) connections on this edge.
		         Any value of this is sufficient to make the zones mergeable.

	connection_edge/unsimulated

		B - This holds an unsimulated turf which has the gas values this edge is mimicing.

		air - Retrieved from B on creation and used as an argument for the legacy ShareSpace() proc.

Class Procs:

	add_connection(connection/c)
		Adds a connection to this edge. Usually increments the coefficient and adds a turf to connecting_turfs.

	remove_connection(connection/c)
		Removes a connection from this edge. This works even if c is not in the edge, so be careful.
		If the coefficient reaches zero as a result, the edge is erased.

	contains_zone(zone/Z)
		Returns true if either A or B is equal to Z. Unsimulated connections return true only on A.

	erase()
		Removes this connection from processing and zone edge lists.

	tick()
		Called every air tick on edges in the processing list. Equalizes gas.

	get_connected_zone(zone/from)
		Helper proc that allows getting the other zone of an edge given one of them.
		Only on /connection_edge/zone, otherwise use A.

*/


/connection_edge/var/zone/A

/connection_edge/var/list/connecting_turfs = list()
/connection_edge/var/direct = 0
/connection_edge/var/sleeping = 1

/connection_edge/var/coefficient = 0
/connection_edge/var/list/airflow_connections = list()

/connection_edge/New()
	CRASH("Cannot make connection edge without specifications.")

/connection_edge/proc/add_connection(connection/c)
	airflow_connections += c
	coefficient++
	if(c.direct()) direct++
//	log_debug("Connection added: [type] Coefficient: [coefficient]")


/connection_edge/proc/remove_connection(connection/c)
//	log_debug("Connection removed: [type] Coefficient: [coefficient-1]")

	airflow_connections -= c
	coefficient--
	if(coefficient <= 0)
		erase()
	if(c.direct()) direct--

/connection_edge/proc/contains_zone(zone/Z)

/connection_edge/proc/erase()
	SSair.remove_edge(src)
//	log_debug("[type] Erased.")


/connection_edge/proc/tick()

/connection_edge/proc/recheck()

/connection_edge/proc/flow(datum/gas_mixture/other, zone/other_zone)
	if(!SSair.times_fired)
		return
	var/mole_delta = A.air.get_tile_moles() - other.get_tile_moles()
	var/strength = abs(mole_delta) * R_IDEAL_GAS_EQUATION * T20C / CELL_VOLUME / ONE_ATMOSPHERE * 100
	if(strength < min(vsc.airflow_lightest_pressure, vsc.airflow_stun_pressure))
		return
	var/list/affected = list()
	var/list/our_openings = list()
	var/list/other_openings = list()
	for(var/connection/opening in airflow_connections)
		if(!opening.valid())
			continue
		var/turf/simulated/our_turf = opening.A
		var/turf/other_turf = opening.B
		if(our_turf.zone != A)
			our_turf = opening.B
			other_turf = opening.A
		our_openings[our_turf] = other_turf
		if(other_zone)
			other_openings[other_turf] = our_turf
	A.airflow(our_openings, strength, mole_delta > 0, affected)
	if(other_zone)
		other_zone.airflow(other_openings, strength, mole_delta < 0, affected)

/connection_edge/zone/var/zone/B

/connection_edge/zone/New(zone/A, zone/B)

	src.A = A
	src.B = B
	A.edges.Add(src)
	B.edges.Add(src)
	if(!A.zone_edges)
		A.zone_edges = list()
	if(!B.zone_edges)
		B.zone_edges = list()
	A.zone_edges[B] = src
	B.zone_edges[A] = src
	//id = edge_id(A,B)
//	log_debug("New edge between [A] and [B]")


/connection_edge/zone/add_connection(connection/c)
	. = ..()
	connecting_turfs.Add(c.A)

/connection_edge/zone/remove_connection(connection/c)
	connecting_turfs.Remove(c.A)
	. = ..()

/connection_edge/zone/contains_zone(zone/Z)
	return A == Z || B == Z

/connection_edge/zone/erase()
	if(A.zone_edges && A.zone_edges[B] == src)
		A.zone_edges -= B
	if(B.zone_edges && B.zone_edges[A] == src)
		B.zone_edges -= A
	A.edges.Remove(src)
	B.edges.Remove(src)
	. = ..()

/connection_edge/zone/tick()
	if(A.invalid || B.invalid)
		erase()
		return

	flow(B.air, B)
	var/equiv = A.air.share_ratio(B.air, coefficient, transfer_ratio = 1)

	if(equiv)
		if(direct)
			erase()
			SSair.merge(A, B)
			return
		else
			SSair.mark_edge_sleeping(src)

	SSair.mark_zone_update(A)
	SSair.mark_zone_update(B)

/connection_edge/zone/recheck()
	if(!A.air.compare(B.air, vacuum_exception = 1, compare_pressure = FALSE))
	// Edges with only one side being vacuum need processing no matter how close.
		SSair.mark_edge_active(src)

//Helper proc to get connections for a zone.
/connection_edge/zone/proc/get_connected_zone(zone/from)
	if(A == from) return B
	else return A

/connection_edge/unsimulated/var/turf/B
/connection_edge/unsimulated/var/datum/gas_mixture/air

/connection_edge/unsimulated/New(zone/A, turf/B)
	src.A = A
	src.B = B
	A.edges.Add(src)
	air = B.return_air()
	//id = 52*A.id
//	log_debug("New edge from [A] to [B].")


/connection_edge/unsimulated/add_connection(connection/c)
	. = ..()
	connecting_turfs.Add(c.B)
	air.group_multiplier = coefficient

/connection_edge/unsimulated/remove_connection(connection/c)
	connecting_turfs.Remove(c.B)
	air.group_multiplier = coefficient
	. = ..()

/connection_edge/unsimulated/erase()
	A.edges.Remove(src)
	. = ..()

/connection_edge/unsimulated/contains_zone(zone/Z)
	return A == Z

/connection_edge/unsimulated/tick()
	if(A.invalid)
		erase()
		return

	flow(air)
	A.air.copy_from(air)
	SSair.mark_edge_sleeping(src)

	SSair.mark_zone_update(A)

/connection_edge/unsimulated/recheck()
	// Edges with only one side being vacuum need processing no matter how close.
	// Note: This prevents a room retaining gas while exposed to space, but
	// does not specially handle the less common case of a simulated room exposed to an unsimulated pressurized turf.
	if(!A.air.compare(air, vacuum_exception = 1, compare_pressure = FALSE))
		SSair.mark_edge_active(src)

proc/ShareHeat(datum/gas_mixture/A, datum/gas_mixture/B, connecting_tiles)
	//This implements a simplistic version of the Stefan-Boltzmann law.
	var/energy_delta = ((A.temperature - B.temperature) ** 4) * STEFAN_BOLTZMANN_CONSTANT * connecting_tiles * 2.5
	var/maximum_energy_delta = max(0, min(A.temperature * A.heat_capacity() * A.group_multiplier, B.temperature * B.heat_capacity() * B.group_multiplier))
	if(maximum_energy_delta > abs(energy_delta))
		if(energy_delta < 0)
			maximum_energy_delta *= -1
		energy_delta = maximum_energy_delta

	A.temperature -= energy_delta / (A.heat_capacity() * A.group_multiplier)
	B.temperature += energy_delta / (B.heat_capacity() * B.group_multiplier)
