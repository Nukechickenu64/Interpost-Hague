/*
Contains helper procs for airflow, handled in /connection_group.
*/

mob/var/last_airflow_stun = 0

/zone/proc/airflow(list/openings, strength, pulling, list/affected)
	var/list/frontier = list()
	var/list/routes = list()
	for(var/turf/simulated/origin in openings)
		var/turf/destination = openings[origin]
		if(!destination || origin.zone != src || (SSair.air_blocked(origin, destination) & AIR_BLOCKED))
			continue
		frontier += origin
		routes[origin] = destination
	for(var/distance = 0, distance < 7 && frontier.len, distance++)
		var/list/next_frontier = list()
		var/local_strength = strength * (7 - distance) / 7
		for(var/turf/simulated/current in frontier)
			var/list/path
			for(var/atom/movable/movable in current)
				if(movable in affected)
					continue
				if(movable.anchored || !movable.AirflowCanMove(local_strength))
					continue
				if(movable.airflow_speed || (movable.last_airflow && movable.last_airflow > world.time - vsc.airflow_delay))
					continue
				var/can_move = movable.check_airflow_movable(local_strength)
				if(!can_move && (!ismob(movable) || local_strength < vsc.airflow_stun_pressure))
					continue
				affected += movable
				if(ismob(movable) && local_strength >= vsc.airflow_stun_pressure)
					var/mob/victim = movable
					victim.airflow_stun()
				if(!can_move)
					continue
				if(pulling && !path)
					path = list()
					var/turf/waypoint = current
					while(routes[waypoint])
						waypoint = routes[waypoint]
						path += waypoint
				movable.airflow_dest = routes[current]
				movable.airflow_path = path ? path.Copy() : null
				movable.airborne_acceleration = local_strength / 10
				if(pulling)
					movable.GotoAirflowDest(local_strength / 10)
				else
					movable.RepelAirflowDest(local_strength / 10)
			for(var/direction in GLOB.cardinal)
				var/turf/simulated/neighbor = get_step(current, direction)
				if(!istype(neighbor) || neighbor.zone != src || routes[neighbor])
					continue
				if(SSair.air_blocked(current, neighbor) & AIR_BLOCKED)
					continue
				routes[neighbor] = current
				next_frontier += neighbor
		frontier = next_frontier

mob/proc/airflow_stun()
	if(stat == 2)
		return 0
	if(last_airflow_stun && last_airflow_stun > world.time - vsc.airflow_stun_cooldown)	return 0

	if(!(status_flags & CANSTUN) && !(status_flags & CANWEAKEN))
		to_chat(src, "<span class='notice'>You stay upright as the air rushes past you.</span>")
		return 0
	if(buckled)
		to_chat(src, "<span class='notice'>Air suddenly rushes past you!</span>")
		return 0
	if(!lying)
		to_chat(src, "<span class='warning'>The sudden rush of air knocks you over!</span>")
	Weaken(5)
	last_airflow_stun = world.time

mob/living/silicon/airflow_stun()
	return

mob/living/carbon/slime/airflow_stun()
	return

mob/living/carbon/human/airflow_stun()
	if(!Process_Spaceslipping())
		to_chat(src, "<span class='notice'>Air suddenly rushes past you!</span>")
		return 0
	..()

atom/movable/proc/check_airflow_movable(n)

	if(anchored && !ismob(src)) return 0

	if(!isobj(src) && n < vsc.airflow_dense_pressure) return 0

	return 1

mob/check_airflow_movable(n)
	if(n < vsc.airflow_heavy_pressure)
		return 0
	return 1

mob/living/silicon/check_airflow_movable()
	return 0


obj/check_airflow_movable(n)
	if(isnull(w_class))
		if(n < vsc.airflow_dense_pressure) return 0 //most non-item objs don't have a w_class yet
	else
		switch(w_class)
			if(1,2)
				if(n < vsc.airflow_lightest_pressure) return 0
			if(3)
				if(n < vsc.airflow_light_pressure) return 0
			if(4,5)
				if(n < vsc.airflow_medium_pressure) return 0
			if(6)
				if(n < vsc.airflow_heavy_pressure) return 0
			if(7 to INFINITY)
				if(n < vsc.airflow_dense_pressure) return 0
	return ..()


/atom/movable/var/turf/airflow_dest
/atom/movable/var/airflow_speed = 0
/atom/movable/var/airflow_time = 0
/atom/movable/var/last_airflow = 0
/atom/movable/var/airborne_acceleration = 0

/atom/movable/proc/AirflowCanMove(n)
	return 1

/mob/AirflowCanMove(n)
	if(status_flags & GODMODE)
		return 0
	if(buckled)
		return 0
	var/obj/item/shoes = get_equipped_item(slot_shoes)
	if(istype(shoes) && (shoes.item_flags & ITEM_FLAG_NOSLIP))
		return 0
	return 1

atom/movable/proc/airflow_hit(atom/A)
	airflow_speed = 0
	airflow_dest = null
	airborne_acceleration = 0

mob/airflow_hit(atom/A)
	for(var/mob/M in hearers(src))
		M.show_message("<span class='danger'>\The [src] slams into \a [A]!</span>",1,"<span class='danger'>You hear a loud slam!</span>",2)
	playsound(src.loc, "smash.ogg", 25, 1, -1)
	var/weak_amt = istype(A,/obj/item) ? A:w_class : rand(1,5) //Heheheh
	Weaken(weak_amt)
	. = ..()

obj/airflow_hit(atom/A)
	for(var/mob/M in hearers(src))
		M.show_message("<span class='danger'>\The [src] slams into \a [A]!</span>",1,"<span class='danger'>You hear a loud slam!</span>",2)
	playsound(src.loc, "smash.ogg", 25, 1, -1)
	. = ..()

obj/item/airflow_hit(atom/A)
	airflow_speed = 0
	airflow_dest = null

mob/living/carbon/human/airflow_hit(atom/A)
//	for(var/mob/M in hearers(src))
//		M.show_message("<span class='danger'>[src] slams into [A]!</span>",1,"<span class='danger'>You hear a loud slam!</span>",2)
	playsound(src.loc, "punch", 25, 1, -1)
	if (prob(33))
		loc:add_blood(src)
		bloody_body(src)
	var/b_loss = min(airflow_speed, (airborne_acceleration*2)) * vsc.airflow_damage

	var/blocked = run_armor_check(BP_HEAD,"melee")
	apply_damage(b_loss/3, BRUTE, BP_HEAD, blocked, 0, "Airflow")

	blocked = run_armor_check(BP_CHEST,"melee")
	apply_damage(b_loss/3, BRUTE, BP_CHEST, blocked, 0, "Airflow")

	blocked = run_armor_check(BP_GROIN,"melee")
	apply_damage(b_loss/3, BRUTE, BP_GROIN, blocked, 0, "Airflow")

	if(airflow_speed > 10)
		Paralyse(round(airflow_speed * vsc.airflow_stun))
		Stun(paralysis + 3)
	else
		Stun(round(airflow_speed * vsc.airflow_stun/2))
	. = ..()
