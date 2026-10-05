/decl/magic_word/magic_action/machine
	base_cost = 30
	var/machine_kind

/decl/magic_word/magic_action/machine/invoke(datum/magic_spell/S, atom/target, mob/caster)
	switch(machine_kind)
		if("open")
			if(istype(target, /obj/machinery/door))
				var/obj/machinery/door/D = target
				if(!D.density || !D.can_open(0))
					return S.fail("[D] does not open.")
				spawn(0)
					D.open()
			else if(istype(target, /obj/structure/closet))
				var/obj/structure/closet/C = target
				if(!C.open())
					return S.fail("[C] does not open.")
			else
				return S.fail("[target] has nothing to open.")
		if("close")
			if(istype(target, /obj/machinery/door))
				var/obj/machinery/door/D = target
				if(D.density || !D.can_close(0))
					return S.fail("[D] does not close.")
				spawn(0)
					D.close()
			else if(istype(target, /obj/structure/closet))
				var/obj/structure/closet/C = target
				if(!C.close())
					return S.fail("[C] does not close.")
			else
				return S.fail("[target] has nothing to close.")
		if("lock")
			if(istype(target, /obj/machinery/door/airlock))
				var/obj/machinery/door/airlock/A = target
				if(!A.lock(1))
					return S.fail("[A] will not bolt.")
			else if(istype(target, /obj/structure/closet))
				var/obj/structure/closet/C = target
				if(!(C.setup & CLOSET_HAS_LOCK) || C.locked || C.opened)
					return S.fail("[C] will not lock.")
				C.locked = TRUE
				C.update_icon()
			else
				return S.fail("[target] has no lock.")
		if("unlock")
			if(istype(target, /obj/machinery/door/airlock))
				var/obj/machinery/door/airlock/A = target
				if(!A.unlock(1))
					return S.fail("[A] is not bolted.")
			else if(istype(target, /obj/structure/closet))
				var/obj/structure/closet/C = target
				if(!C.locked)
					return S.fail("[C] is not locked.")
				C.locked = FALSE
				C.update_icon()
			else
				return S.fail("[target] has no lock.")
		if("break")
			if(istype(target, /obj/structure/window))
				var/obj/structure/window/W = target
				W.shatter()
			else if(istype(target, /obj/machinery/door/window))
				var/obj/machinery/door/window/W = target
				W.shatter()
			else if(istype(target, /obj/machinery/light))
				var/obj/machinery/light/L = target
				L.broken()
			else
				return S.fail("[target] does not break so easily.")
		if("charge", "drain")
			var/obj/item/cell/cell = target
			if(!istype(cell) && ("cell" in target.vars))
				cell = target.vars["cell"]
			if(!istype(cell))
				return S.fail("[target] holds no power.")
			cell.charge = machine_kind == "charge" ? cell.maxcharge : 0
			cell.update_icon()
	return "[name] [target]"

/decl/magic_word/magic_action/machine/aperire
	name = "to open"
	words = list("aperire")
	machine_kind = "open"
	base_cost = 20

/decl/magic_word/magic_action/machine/claudere
	name = "to close"
	words = list("claudere")
	machine_kind = "close"
	base_cost = 20

/decl/magic_word/magic_action/machine/obserare
	name = "to bolt"
	words = list("obserare")
	machine_kind = "lock"
	base_cost = 40

/decl/magic_word/magic_action/machine/reserare
	name = "to unbolt"
	words = list("reserare")
	machine_kind = "unlock"
	base_cost = 50

/decl/magic_word/magic_action/machine/frangere
	name = "to shatter"
	words = list("frangere")
	machine_kind = "break"
	base_cost = 35

/decl/magic_word/magic_action/machine/replere
	name = "to fill with power"
	words = list("replere")
	machine_kind = "charge"
	base_cost = 60

/decl/magic_word/magic_action/machine/exhaurire
	name = "to drain of power"
	words = list("exhaurire")
	machine_kind = "drain"
	base_cost = 40

/decl/magic_word/magic_action/terrain
	accepts_turf = TRUE
	base_cost = 30
	var/terrain_kind

/decl/magic_word/magic_action/terrain/invoke(datum/magic_spell/S, atom/target, mob/caster)
	var/turf/T = get_turf(target)
	if(!T)
		return S.fail("There is no ground there.")
	switch(terrain_kind)
		if("flicker")
			var/flickered = 0
			for(var/obj/machinery/light/L in range(spoken_amount(S, 4, 8), T))
				L.flicker()
				flickered++
			if(!flickered)
				return S.fail("There are no lights to trouble.")
		if("emp")
			var/range = spoken_amount(S, 3, 10)
			empulse(T, round(range / 2), range, 1)
		if("wall")
			if(!istype(T, /turf/simulated/floor))
				return S.fail("A wall cannot rise there.")
			for(var/atom/movable/AM in T)
				if(ismob(AM) || AM.density)
					return S.fail("Something stands in the way of the wall.")
			T.ChangeTurf(/turf/simulated/wall)
		if("dig")
			if(!istype(T, /turf/simulated/wall))
				return S.fail("There is no wall there to dig.")
			T.ChangeTurf(/turf/simulated/floor/plating)
		if("wet")
			var/wetted = 0
			for(var/turf/simulated/W in range(spoken_amount(S, 1, 3), T))
				W.wet_floor(2)
				wetted++
			if(!wetted)
				return S.fail("The ground will not take the water.")
		if("smoke")
			var/datum/effect/effect/system/smoke_spread/smoke = new
			smoke.set_up(spoken_amount(S, 5, 10), 0, T)
			smoke.start()
	return "[name] at [T.x],[T.y],[T.z]"

/decl/magic_word/magic_action/terrain/magic_cost(datum/magic_spell/S)
	return base_cost + spoken_amount(S, 0, 10) * cost_per_unit

/decl/magic_word/magic_action/terrain/coruscare
	name = "to make the lights flicker"
	words = list("coruscare")
	terrain_kind = "flicker"
	base_cost = 15
	cost_per_unit = 2

/decl/magic_word/magic_action/terrain/pulsare
	name = "to silence machines"
	words = list("pulsare")
	terrain_kind = "emp"
	base_cost = 80
	cost_per_unit = 10

/decl/magic_word/magic_action/terrain/aedificare
	name = "to raise a wall"
	words = list("aedificare")
	terrain_kind = "wall"
	base_cost = 100

/decl/magic_word/magic_action/terrain/fodere
	name = "to break down a wall"
	words = list("fodere")
	terrain_kind = "dig"
	base_cost = 120

/decl/magic_word/magic_action/terrain/lubricare
	name = "to make the ground slick"
	words = list("lubricare")
	terrain_kind = "wet"
	base_cost = 20
	cost_per_unit = 10

/decl/magic_word/magic_action/terrain/fumare
	name = "to raise smoke"
	words = list("fumare")
	terrain_kind = "smoke"
	base_cost = 25
	cost_per_unit = 3
