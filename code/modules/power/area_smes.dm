// Area SMES: replaces the APC. Stores power in an internal cell, charges from its linked CCID bus,
// and powers every area that holds an /obj/effect/area_power_marker with a matching area_id.
// It does not need to be inside the areas it powers.

#define POWERCHAN_OFF		0	// Power channel is off
#define POWERCHAN_OFF_TEMP	1	// Power channel is off until there is power
#define POWERCHAN_OFF_AUTO	2	// Power channel is off until power passes a threshold
#define POWERCHAN_ON		3	// Power channel is on until there is no power
#define POWERCHAN_ON_AUTO	4	// Power channel is on until power drops below a threshold

#define AUTO_THRESHOLD_LIGHTING  50
#define AUTO_THRESHOLD_EQUIPMENT 25

#define CRITICAL_APC_EMP_PROTECTION 10	// EMP effect duration is divided by this number if the unit has "critical" flag

#define UPDATE_CELL_IN 1
#define UPDATE_OPENED1 2
#define UPDATE_OPENED2 4
#define UPDATE_MAINT 8
#define UPDATE_BROKE 16
#define UPDATE_BLUESCREEN 32
#define UPDATE_WIREEXP 64
#define UPDATE_ALLGOOD 128

#define APC_UPOVERLAY_CHARGEING0 1
#define APC_UPOVERLAY_CHARGEING1 2
#define APC_UPOVERLAY_CHARGEING2 4
#define APC_UPOVERLAY_LOCKED 8
#define APC_UPOVERLAY_OPERATING 16

GLOBAL_LIST_EMPTY(area_smes_by_id)

/area
	var/obj/machinery/power/area_smes/area_smes = null

/area/proc/get_area_smes()
	return area_smes

// Variants
/obj/machinery/power/area_smes/critical
	is_critical = 1

/obj/machinery/power/area_smes/high
	cell_type = /obj/item/cell/high

/obj/machinery/power/area_smes/high/inactive
	lighting = 0
	equipment = 0
	environ = 0
	locked = 0
	coverlocked = 0

/obj/machinery/power/area_smes/super
	cell_type = /obj/item/cell/super

/obj/machinery/power/area_smes/super/critical
	is_critical = 1

/obj/machinery/power/area_smes/hyper
	cell_type = /obj/item/cell/hyper

/obj/machinery/power/area_smes/derelict
	cell_type = /obj/item/cell/crap/empty
	lighting = 0
	equipment = 0
	environ = 0
	locked = 0
	coverlocked = 0

/obj/machinery/power/area_smes
	name = "power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit that feeds configured areas."

	icon_state = "smes"
	density = 1
	anchored = 1
	use_power = POWER_USE_OFF
	req_access = list(access_engine_equip)
	clicksound = "switch"
	var/area_id = null						// markers with the same area_id are powered by this unit
	var/list/area/served_areas = list()
	var/area/area							// first served area, used for naming and alarms
	var/obj/item/cell/cell
	var/chargelevel = 0.0005  // Cap for how fast cells charge, as a percentage-per-tick
	var/cell_type = /obj/item/cell/apc
	var/opened = 0 //0=closed, 1=opened, 2=cover removed
	var/shorted = 0
	var/lighting = POWERCHAN_ON_AUTO
	var/equipment = POWERCHAN_ON_AUTO
	var/environ = POWERCHAN_ON_AUTO
	var/operating = 1
	var/charging = 0
	var/chargemode = 1
	var/chargecount = 0
	var/locked = 1
	var/coverlocked = 1
	var/aidisabled = 0
	var/lastused_light = 0
	var/lastused_equip = 0
	var/lastused_environ = 0
	var/lastused_charging = 0
	var/lastused_total = 0
	var/main_status = 0
	var/mob/living/silicon/ai/hacker = null // Malfunction var. If set AI hacked the unit and has full control.
	var/wiresexposed = 0
	var/debug= 0
	var/autoflag= 0		// 0 = off, 1= eqp and lights off, 2 = eqp off, 3 = all on.
	var/beenhit = 0
	var/longtermpower = 10
	var/datum/wires/apc/wires = null
	var/update_state = -1
	var/update_overlay = -1
	var/list/update_overlay_chan
	var/is_critical = 0
	var/failure_timer = 0
	var/force_update = 0
	var/emp_hardened = 0
	var/needs_powerdown_sound
	var/ambience_last_played

/obj/machinery/power/area_smes/updateDialog()
	if (stat & (BROKEN|MAINT))
		return
	..()

/obj/machinery/power/area_smes/drain_power(var/drain_check, var/surge, var/amount = 0)
	if(drain_check)
		return 1

	charging = 0

	if(locked)
		amount /= 4

	var/drained_energy = 0

	if(powernet)
		powernet.trigger_warning()
		drained_energy += powernet.draw_power(amount)

	if((drained_energy < amount) && cell)
		drained_energy += cell.use((amount - drained_energy) * CELLRATE)

	return drained_energy

/obj/machinery/power/area_smes/Initialize(mapload, var/ndir)
	wires = new(src)

	if(ndir)
		set_dir(ndir)

	pixel_x = 0
	pixel_y = 0

	if(cell_type)
		cell = new cell_type(src)

	if(area_id)
		if(GLOB.area_smes_by_id[area_id])
			log_error("Duplicate area SMES id '[area_id]' at [x],[y],[z].")
		else
			GLOB.area_smes_by_id[area_id] = src
	else
		add_served_area(get_area(src))

	. = ..(mapload)

	update_name()
	update_icon()
	if(operating)
		update()

/obj/machinery/power/area_smes/Destroy()
	for(var/area/A in served_areas.Copy())
		remove_served_area(A)
	if(area_id && GLOB.area_smes_by_id[area_id] == src)
		GLOB.area_smes_by_id -= area_id
	qdel(wires)
	wires = null
	if(cell)
		cell.forceMove(loc)
		cell = null

	if((hacker) && (hacker.hacked_apcs) && (src in hacker.hacked_apcs))
		hacker.hacked_apcs -= src

	return ..()

/obj/machinery/power/area_smes/proc/update_name()
	if(area)
		SetName("\improper [area.name] power storage unit")
	else if(area_id)
		SetName("\improper [area_id] power storage unit")

/obj/machinery/power/area_smes/proc/add_served_area(area/A)
	if(!A || (A in served_areas))
		return
	if(A.area_smes && A.area_smes != src)
		log_error("Area [A] ([A.type]) is claimed by both [A.area_smes.area_id] and [area_id]; keeping the first.")
		return
	served_areas += A
	A.area_smes = src
	if(!area)
		area = A
		update_name()
	update()

/obj/machinery/power/area_smes/proc/remove_served_area(area/A)
	if(!(A in served_areas))
		return
	served_areas -= A
	if(A.area_smes == src)
		A.area_smes = null
		A.power_light = 0
		A.power_equip = 0
		A.power_environ = 0
		A.power_change()
	if(area == A)
		area = served_areas.len ? served_areas[1] : null

/obj/machinery/power/area_smes/get_implicit_power_outputs()
	. = list()
	for(var/area/A in served_areas)
		. += "Area: [A.name]"

/obj/machinery/power/area_smes/proc/energy_fail(var/duration)
	if(emp_hardened)
		return
	failure_timer = max(failure_timer, round(duration))
	update()
	queue_icon_update()
	force_update = 1

/obj/machinery/power/area_smes/examine(mob/user)
	if(..(user, 1))
		if(stat & BROKEN)
			to_chat(user, "Looks broken.")
			return
		if(opened)
			to_chat(user, "The cover is [opened==2?"removed":"open"] and the storage cell is [ cell ? "installed" : "missing"].")
		else
			if (stat & MAINT)
				to_chat(user, "The cover is closed. Something wrong with it: it doesn't work.")
			else if (hacker && !hacker.hacked_apcs_hidden)
				to_chat(user, "The cover is locked.")
			else
				to_chat(user, "The cover is closed.")
		var/list/names = list()
		for(var/area/A in served_areas)
			names += A.name
		to_chat(user, "It powers: [names.len ? english_list(names) : "nothing"].")

/obj/machinery/power/area_smes/update_icon()
	var/update = check_updates()
	if(!update)
		return

	overlays.Cut()
	icon_state = "smes"
	if(stat & (BROKEN|MAINT) || opened || !cell)
		set_light(0)
		return

	var/outputting = (operating && !shorted && !failure_timer && served_areas.len) ? 1 : 0
	var/charge_display = round(5.5 * cell.charge / (cell.maxcharge ? cell.maxcharge : 5e6))
	var/charge_state = charging

	overlays += overlay_image(icon, "smes-op[outputting]")
	if(charge_state == 2)
		overlays += overlay_image(icon, "smes-oc2", ABOVE_LIGHTING_PLANE, ABOVE_LIGHTING_LAYER)
	else if(charge_state == 1)
		overlays += overlay_image(icon, "smes-oc1", ABOVE_LIGHTING_PLANE, ABOVE_LIGHTING_LAYER)
	else if(chargemode)
		overlays += overlay_image(icon, "smes-oc0", ABOVE_LIGHTING_PLANE, ABOVE_LIGHTING_LAYER)

	if(charge_display)
		overlays += overlay_image(icon, "smes-og[charge_display]", ABOVE_LIGHTING_PLANE, ABOVE_LIGHTING_LAYER)

	overlays += overlay_image(icon, "smes-op[outputting]", ABOVE_LIGHTING_PLANE, ABOVE_LIGHTING_LAYER)
	set_light(l_range = 1, l_power = 0.5, l_color = charging == 2 ? "#82ff4c" : charging ? "#a8b0f8" : "#f86060")

/obj/machinery/power/area_smes/proc/check_updates()
	if(!update_overlay_chan)
		update_overlay_chan = new/list()
	var/last_update_state = update_state
	var/last_update_overlay = update_overlay
	var/list/last_update_overlay_chan = update_overlay_chan.Copy()
	update_state = 0
	update_overlay = 0
	if(cell)
		update_state |= UPDATE_CELL_IN
	if(stat & BROKEN)
		update_state |= UPDATE_BROKE
	if(stat & MAINT)
		update_state |= UPDATE_MAINT
	if(opened)
		if(opened==1)
			update_state |= UPDATE_OPENED1
		if(opened==2)
			update_state |= UPDATE_OPENED2
	else if(emagged || (hacker && !hacker.hacked_apcs_hidden) || failure_timer)
		update_state |= UPDATE_BLUESCREEN
	else if(wiresexposed)
		update_state |= UPDATE_WIREEXP
	if(update_state <= 1)
		update_state |= UPDATE_ALLGOOD

	if(operating)
		update_overlay |= APC_UPOVERLAY_OPERATING

	if(update_state & UPDATE_ALLGOOD)
		if(locked)
			update_overlay |= APC_UPOVERLAY_LOCKED

		if(!charging)
			update_overlay |= APC_UPOVERLAY_CHARGEING0
		else if(charging == 1)
			update_overlay |= APC_UPOVERLAY_CHARGEING1
		else if(charging == 2)
			update_overlay |= APC_UPOVERLAY_CHARGEING2

		update_overlay_chan["Equipment"] = equipment
		update_overlay_chan["Lighting"] = lighting
		update_overlay_chan["Enviroment"] = environ
		update_overlay_chan["Cell"] = cell ? round(5.5 * cell.charge / (cell.maxcharge ? cell.maxcharge : 5e6)) : 0
		update_overlay_chan["Output"] = (operating && !shorted && !failure_timer && served_areas.len) ? 1 : 0

	var/results = 0
	if(last_update_state == update_state && last_update_overlay == update_overlay && last_update_overlay_chan == update_overlay_chan)
		return 0
	if(last_update_state != update_state)
		results += 1
	if(last_update_overlay != update_overlay || last_update_overlay_chan != update_overlay_chan)
		results += 2
	return results

/obj/machinery/power/area_smes/attackby(obj/item/W, mob/user)
	if (istype(user, /mob/living/silicon) && get_dist(src,user)>1)
		return src.attack_hand(user)
	src.add_fingerprint(user)
	if(isCrowbar(W) && opened)
		if (opened!=2)
			opened = 0
			update_icon()
	else if(isCrowbar(W) && !((stat & BROKEN) || (hacker && !hacker.hacked_apcs_hidden)) )
		if(coverlocked && !(stat & MAINT))
			to_chat(user, "<span class='warning'>The cover is locked and cannot be opened.</span>")
			return
		else
			opened = 1
			update_icon()
	else if	(istype(W, /obj/item/cell) && opened)
		if(cell)
			to_chat(user, "There is a storage cell already installed.")
			return
		if (stat & MAINT)
			to_chat(user, "<span class='warning'>There is no connector for your cell.</span>")
			return
		if(W.w_class != ITEM_SIZE_NORMAL)
			to_chat(user, "\The [W] is too [W.w_class < ITEM_SIZE_NORMAL? "small" : "large"] to fit here.")
			return

		user.drop_item()
		W.forceMove(src)
		cell = W
		user.visible_message(\
			"<span class='warning'>[user.name] has inserted the cell to [src.name]!</span>",\
			"<span class='notice'>You insert the cell.</span>")
		chargecount = 0
		update_icon()
	else if(isScrewdriver(W))
		if(opened)
			if (cell)
				to_chat(user, "<span class='warning'>Remove the cell first.</span>")
				return
			if(stat & MAINT)
				stat &= ~MAINT
				to_chat(user, "You secure the control electronics.")
			else
				stat |= MAINT
				to_chat(user, "You unfasten the control electronics.")
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			update_icon()
		else
			wiresexposed = !wiresexposed
			to_chat(user, "The wires have been [wiresexposed ? "exposed" : "unexposed"]")
			update_icon()

	else if (istype(W, /obj/item/card/id)||istype(W, /obj/item/device/pda))
		if(emagged)
			to_chat(user, "The interface is broken.")
		else if(opened)
			to_chat(user, "You must close the cover to swipe an ID card.")
		else if(wiresexposed)
			to_chat(user, "You must close the panel")
		else if(stat & (BROKEN|MAINT))
			to_chat(user, "Nothing happens.")
		else if(hacker && !hacker.hacked_apcs_hidden)
			to_chat(user, "<span class='warning'>Access denied.</span>")
		else
			if(src.allowed(usr) && !isWireCut(APC_WIRE_IDSCAN))
				locked = !locked
				to_chat(user, "You [ locked ? "lock" : "unlock"] the interface.")
				update_icon()
			else
				to_chat(user, "<span class='warning'>Access denied.</span>")
	else if(isWelder(W) && opened && ((stat & BROKEN) || emagged || opened == 2))
		var/obj/item/weldingtool/WT = W
		if (WT.get_fuel() < 3)
			to_chat(user, "<span class='warning'>You need more welding fuel to complete this task.</span>")
			return
		user.visible_message("<span class='warning'>[user.name] starts repairing [src].</span>", \
							"You start repairing the frame...", \
							"You hear welding.")
		playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
		if(do_after(user, 50, src))
			if(!src || !WT.remove_fuel(3, user)) return
			emagged = 0
			set_broken(FALSE)
			if(hacker && hacker.hacked_apcs && (src in hacker.hacked_apcs))
				hacker.hacked_apcs -= src
				hacker = null
			if (opened==2)
				opened = 1
			to_chat(user, "<span class='notice'>You repair \the [src].</span>")
			queue_icon_update()
	else
		if (((stat & BROKEN) || (hacker && !hacker.hacked_apcs_hidden)) \
				&& !opened \
				&& W.force >= 5 \
				&& W.w_class >= 3.0 \
				&& prob(20) )
			opened = 2
			user.visible_message("<span class='danger'>The [src.name] cover was knocked down with the [W.name] by [user.name]!</span>", \
				"<span class='danger'>You knock down the cover with your [W.name]!</span>", \
				"You hear a bang")
			update_icon()
		else
			if (istype(user, /mob/living/silicon))
				return src.attack_hand(user)
			if (!opened && wiresexposed && isMultitool(W) || isWirecutter(W) || istype(W, /obj/item/device/assembly/signaler))
				return src.attack_hand(user)
			user.visible_message("<span class='danger'>The [src.name] has been hit with the [W.name] by [user.name]!</span>", \
				"<span class='danger'>You hit the [src.name] with your [W.name]!</span>", \
				"You hear a bang")
			if(W.force >= 5 && W.w_class >= ITEM_SIZE_NORMAL && prob(W.force))
				var/roulette = rand(1,100)
				switch(roulette)
					if(1 to 10)
						locked = FALSE
						to_chat(user, "<span class='notice'>You manage to disable the lock on \the [src]!</span>")
					if(50 to 70)
						to_chat(user, "<span class='notice'>You manage to bash the lid open!</span>")
						opened = 1
					if(90 to 100)
						to_chat(user, "<span class='warning'>There's a nasty sound and \the [src] goes cold...</span>")
						set_broken(TRUE)
				queue_icon_update()
		playsound(get_turf(src), 'sound/weapons/smash.ogg', 75, 1)

/obj/machinery/power/area_smes/emag_act(var/remaining_charges, var/mob/user)
	if (!(emagged || (hacker && !hacker.hacked_apcs_hidden)))
		if(opened)
			to_chat(user, "You must close the cover to swipe an ID card.")
		else if(wiresexposed)
			to_chat(user, "You must close the panel first")
		else if(stat & (BROKEN|MAINT))
			to_chat(user, "Nothing happens.")
		else
			flick("apc-spark", src)
			if (do_after(user,6,src))
				if(prob(50))
					emagged = 1
					locked = 0
					to_chat(user, "<span class='notice'>You emag the interface.</span>")
					update_icon()
				else
					to_chat(user, "<span class='warning'>You fail to [ locked ? "unlock" : "lock"] the interface.</span>")
				return 1

/obj/machinery/power/area_smes/attack_hand(mob/user)
	if(!user)
		return
	src.add_fingerprint(user)

	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user

		if(H.species.can_shred(H))
			user.visible_message("<span class='warning'>\The [user] slashes at \the [src]!</span>", "<span class='notice'>You slash at \the [src]!</span>")
			playsound(src.loc, 'sound/weapons/slash.ogg', 100, 1)

			var/allcut = wires.IsAllCut()

			if(beenhit >= pick(3, 4) && wiresexposed != 1)
				wiresexposed = 1
				src.update_icon()
				src.visible_message("<span class='warning'>\The [src]'s cover flies open, exposing the wires!</span>")

			else if(wiresexposed == 1 && allcut == 0)
				wires.CutAll()
				src.update_icon()
				src.visible_message("<span class='warning'>\The [src]'s wires are shredded!</span>")
			else
				beenhit += 1
			return

	if(usr == user && opened && (!issilicon(user)))
		if(cell)
			user.put_in_hands(cell)
			cell.add_fingerprint(user)
			cell.update_icon()

			src.cell = null
			user.visible_message("<span class='warning'>[user.name] removes the cell from [src.name]!</span>",\
								 "<span class='notice'>You remove the cell.</span>")
			charging = 0
			src.update_icon()
		return
	if(stat & (BROKEN|MAINT))
		return
	src.interact(user)

/obj/machinery/power/area_smes/interact(mob/user)
	if(!user)
		return

	if(wiresexposed && !istype(user, /mob/living/silicon/ai))
		wires.Interact(user)

	return ui_interact(user)

/obj/machinery/power/area_smes/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	if(!user)
		return

	var/list/data = list(
		"pChan_Off" = POWERCHAN_OFF,
		"pChan_Off_T" = POWERCHAN_OFF_TEMP,
		"pChan_Off_A" = POWERCHAN_OFF_AUTO,
		"pChan_On" = POWERCHAN_ON,
		"pChan_On_A" = POWERCHAN_ON_AUTO,
		"locked" = (locked && !emagged) ? 1 : 0,
		"isOperating" = operating,
		"externalPower" = main_status,
		"powerCellStatus" = cell ? cell.percent() : null,
		"chargeMode" = chargemode,
		"chargingStatus" = charging,
		"totalLoad" = round(lastused_total),
		"totalCharging" = round(lastused_charging),
		"coverLocked" = coverlocked,
		"failTime" = failure_timer * 2,
		"siliconUser" = istype(user, /mob/living/silicon),
		"powerChannels" = list(
			list(
				"title" = "Equipment",
				"powerLoad" = lastused_equip,
				"status" = equipment,
				"topicParams" = list(
					"auto" = list("eqp" = 2),
					"on"   = list("eqp" = 1),
					"off"  = list("eqp" = 0)
				)
			),
			list(
				"title" = "Lighting",
				"powerLoad" = round(lastused_light),
				"status" = lighting,
				"topicParams" = list(
					"auto" = list("lgt" = 2),
					"on"   = list("lgt" = 1),
					"off"  = list("lgt" = 0)
				)
			),
			list(
				"title" = "Environment",
				"powerLoad" = round(lastused_environ),
				"status" = environ,
				"topicParams" = list(
					"auto" = list("env" = 2),
					"on"   = list("env" = 1),
					"off"  = list("env" = 0)
				)
			)
		)
	)

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "apc.tmpl", "[name]", 520, data["siliconUser"] ? 465 : 440)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/power/area_smes/proc/report()
	return "[area_id || (area && area.name)] : [equipment]/[lighting]/[environ] ([lastused_equip+lastused_light+lastused_environ]) : [cell? cell.percent() : "N/C"] ([charging])"

/obj/machinery/power/area_smes/proc/update()
	for(var/area/A in served_areas)
		if(operating && !shorted && !failure_timer)
			var/new_power_light = (lighting >= POWERCHAN_ON)
			if(A.power_light != new_power_light)
				A.power_light = new_power_light
				A.set_emergency_lighting(lighting == POWERCHAN_OFF_AUTO)

			A.power_equip = (equipment >= POWERCHAN_ON)
			A.power_environ = (environ >= POWERCHAN_ON)
		else
			A.power_light = 0
			A.power_equip = 0
			A.power_environ = 0

		A.power_change()

	if(!cell || cell.charge <= 0)
		if(needs_powerdown_sound == TRUE)
			playsound(src, 'sound/machines/apc_nopower.ogg', 75, 0)
			needs_powerdown_sound = FALSE
		else
			needs_powerdown_sound = TRUE

/obj/machinery/power/area_smes/proc/isWireCut(var/wireIndex)
	return wires.IsIndexCut(wireIndex)

/obj/machinery/power/area_smes/proc/can_use(mob/user as mob, var/loud = 0)
	if (user.stat)
		to_chat(user, "<span class='warning'>You must be conscious to use [src]!</span>")
		return 0
	if(!user.client)
		return 0
	if(inoperable())
		return 0
	if(!user.IsAdvancedToolUser())
		return 0
	if(user.restrained())
		to_chat(user, "<span class='warning'>You must have free hands to use [src].</span>")
		return 0
	if(user.lying)
		to_chat(user, "<span class='warning'>You must stand to use [src]!</span>")
		return 0
	autoflag = 5
	if (istype(user, /mob/living/silicon))
		var/permit = 0
		var/mob/living/silicon/ai/AI = user
		var/mob/living/silicon/robot/robot = user
		if(hacker && !hacker.hacked_apcs_hidden)
			if(hacker == AI)
				permit = 1
			else if(istype(robot) && robot.connected_ai && robot.connected_ai == hacker)
				permit = 1

		if(aidisabled && !permit)
			if(!loud)
				to_chat(user, "<span class='danger'>\The [src] have AI control disabled!</span>")
			return 0
	else
		if (!in_range(src, user) || !istype(src.loc, /turf))
			return 0
	var/mob/living/carbon/human/H = user
	if (istype(H) && prob(H.getBrainLoss()))
		to_chat(user, "<span class='danger'>You momentarily forget how to use [src].</span>")
		return 0
	return 1

/obj/machinery/power/area_smes/Topic(href, href_list)
	if(..())
		return 1

	if(!can_use(usr, 1))
		return 1

	if(!istype(usr, /mob/living/silicon) && (locked && !emagged))
		to_chat(usr, "You must unlock the panel to use this!")
		return 1

	if (href_list["lock"])
		coverlocked = !coverlocked

	else if( href_list["reboot"] )
		failure_timer = 0
		update_icon()
		update()

	else if (href_list["breaker"])
		toggle_breaker()

	else if (href_list["cmode"])
		chargemode = !chargemode
		if(!chargemode)
			charging = 0
			update_icon()

	else if (href_list["eqp"])
		var/val = text2num(href_list["eqp"])
		equipment = setsubsystem(val)
		update_icon()
		update()

	else if (href_list["lgt"])
		var/val = text2num(href_list["lgt"])
		lighting = setsubsystem(val)
		update_icon()
		update()

	else if (href_list["env"])
		var/val = text2num(href_list["env"])
		environ = setsubsystem(val)
		update_icon()
		update()

	else if (href_list["overload"])
		if(istype(usr, /mob/living/silicon))
			src.overload_lighting()

	else if (href_list["toggleaccess"])
		if(istype(usr, /mob/living/silicon))
			if(emagged || (stat & (BROKEN|MAINT)))
				to_chat(usr, "\The [src] does not respond to the command.")
			else
				locked = !locked
				update_icon()

	return 0

/obj/machinery/power/area_smes/proc/toggle_breaker()
	operating = !operating
	src.update()
	update_icon()

/obj/machinery/power/area_smes/proc/last_surplus()
	if(powernet)
		return powernet.last_surplus()
	return 0

/obj/machinery/power/area_smes/proc/attempt_charging()
	return (chargemode && charging == 1 && operating)

/obj/machinery/power/area_smes/proc/total_area_usage(chan)
	. = 0
	for(var/area/A in served_areas)
		if(A.requires_power)
			. += A.usage(chan)

/obj/machinery/power/area_smes/Process()
	if(stat & (BROKEN|MAINT))
		return
	if(!served_areas.len)
		return
	if(failure_timer)
		if (!--failure_timer)
			update()
			queue_icon_update()
			force_update = 1
		return

	lastused_light = total_area_usage(LIGHT)
	lastused_equip = total_area_usage(EQUIP)
	lastused_environ = total_area_usage(ENVIRON)
	for(var/area/A in served_areas)
		A.clear_usage()

	lastused_total = lastused_light + lastused_equip + lastused_environ

	var/last_lt = lighting
	var/last_eq = equipment
	var/last_en = environ
	var/last_ch = charging

	var/excess = surplus()

	if(!src.avail())
		main_status = 0
	else if(excess < 0)
		main_status = 1
	else
		main_status = 2

	if(debug)
		log_debug("Status: [main_status] - Excess: [excess] - Last Equip: [lastused_equip] - Last Light: [lastused_light] - Longterm: [longtermpower]")

	if(cell && !shorted)
		var/cellused = min(cell.charge, CELLRATE * lastused_total)
		cell.use(cellused)

		if(excess > lastused_total)
			var/draw = draw_power(cellused/CELLRATE)
			cell.give(draw * CELLRATE)
		else
			if( (cell.charge/CELLRATE + excess) >= lastused_total)
				var/draw = draw_power(excess)
				cell.charge = min(cell.maxcharge, cell.charge + CELLRATE * draw)
				charging = 0
			else
				charging = 0
				chargecount = 0
				equipment = autoset(equipment, 0)
				lighting = autoset(lighting, 0)
				environ = autoset(environ, 0)
				autoflag = 0

		update_channels()

		lastused_charging = 0
		if(src.attempt_charging())
			if(excess > 0)
				var/ch = min(excess*CELLRATE, cell.maxcharge*chargelevel)

				ch = draw_power(ch/CELLRATE)
				cell.give(ch*CELLRATE)
				lastused_charging = ch
				lastused_total += ch // Sensors need this to stop reporting charging as "Other" load
			else
				charging = 0
				chargecount = 0

		if(cell.charge >= cell.maxcharge)
			cell.charge = cell.maxcharge
			charging = 2

		if(chargemode)
			if(!charging)
				if(excess > cell.maxcharge*chargelevel)
					chargecount++
				else
					chargecount = 0

				if(chargecount >= 10)
					chargecount = 0
					charging = 1

		else
			charging = 0
			chargecount = 0

	else
		charging = 0
		chargecount = 0
		equipment = autoset(equipment, 0)
		lighting = autoset(lighting, 0)
		environ = autoset(environ, 0)
		power_alarm.triggerAlarm(loc, src)
		autoflag = 0

	if(last_lt != lighting || last_eq != equipment || last_en != environ || force_update)
		force_update = 0
		queue_icon_update()
		update()
	else if (last_ch != charging)
		queue_icon_update()

	var/static/list/electricsounds = list('sound/machines/electr1.ogg','sound/machines/electr2.ogg','sound/machines/electr3.ogg')
	if(operating && world.time > ambience_last_played + 60 SECONDS && prob(5) && charging)
		ambience_last_played = world.time
		playsound(src.loc, pick(electricsounds),15,1,10, is_ambiance = 1)

/obj/machinery/power/area_smes/proc/update_channels()
	if(charging && longtermpower < 10)
		longtermpower += 1
	else if(longtermpower > -10)
		longtermpower -= 2

	if((cell.percent() > AUTO_THRESHOLD_LIGHTING) || longtermpower > 0)
		if(autoflag != 3)
			equipment = autoset(equipment, 1)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
			autoflag = 3
			power_alarm.clearAlarm(loc, src)
	else if((cell.percent() <= AUTO_THRESHOLD_LIGHTING) && (cell.percent() > AUTO_THRESHOLD_EQUIPMENT) && longtermpower < 0)
		if(autoflag != 2)
			equipment = autoset(equipment, 1)
			lighting = autoset(lighting, 2)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src)
			autoflag = 2
	else if(cell.percent() <= AUTO_THRESHOLD_EQUIPMENT)
		if((autoflag > 1 && longtermpower < 0) || (autoflag > 1 && longtermpower >= 0))
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 2)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src)
			autoflag = 1
	else
		if(autoflag != 0)
			equipment = autoset(equipment, 0)
			lighting = autoset(lighting, 0)
			environ = autoset(environ, 0)
			power_alarm.triggerAlarm(loc, src)
			autoflag = 0

// on 0=off, 1=on, 2=autooff
/obj/machinery/power/area_smes/proc/autoset(var/cur_state, var/on)
	switch(cur_state)
		if(POWERCHAN_OFF_TEMP)
			if(on == 1 || on == 2)
				return POWERCHAN_ON
		if(POWERCHAN_OFF_AUTO)
			if(on == 1)
				return POWERCHAN_ON_AUTO
		if(POWERCHAN_ON)
			if(on == 0)
				return POWERCHAN_OFF_TEMP
		if(POWERCHAN_ON_AUTO)
			if(on == 0 || on == 2)
				return POWERCHAN_OFF_AUTO

	return cur_state

/obj/machinery/power/area_smes/emp_act(severity)
	if(emp_hardened)
		return
	if(is_critical)
		energy_fail(rand(240, 360) / severity / CRITICAL_APC_EMP_PROTECTION)
		if(cell)
			cell.emp_act(severity+2)
	else
		energy_fail(rand(240, 360) / severity)
		if(cell)
			cell.emp_act(severity+1)

	update_icon()
	..()

/obj/machinery/power/area_smes/ex_act(severity)
	switch(severity)
		if(1.0)
			if (cell)
				cell.ex_act(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				set_broken(TRUE)
				if (cell && prob(50))
					cell.ex_act(2.0)
		if(3.0)
			if (prob(25))
				set_broken(TRUE)
				if (cell && prob(25))
					cell.ex_act(3.0)
	return

/obj/machinery/power/area_smes/set_broken(new_state)
	if(!new_state || (stat & BROKEN))
		return ..()
	visible_message("<span class='notice'>[src]'s screen flickers with warnings briefly!</span>")
	power_alarm.triggerAlarm(loc, src)
	spawn(rand(2,5))
		..()
		visible_message("<span class='notice'>[src]'s screen suddenly explodes in rain of sparks and small debris!</span>")
		operating = 0
		update()
	return TRUE

/obj/machinery/power/area_smes/proc/reboot()
	charging = initial(charging)
	chargecount = initial(chargecount)
	autoflag = initial(autoflag)
	longtermpower = initial(longtermpower)
	failure_timer = initial(failure_timer)

	operating = 0
	chargemode = initial(chargemode)
	power_alarm.clearAlarm(loc, src)

	lighting = POWERCHAN_ON_AUTO
	equipment = POWERCHAN_ON_AUTO
	environ = POWERCHAN_ON_AUTO

	update_icon()
	update()

/obj/machinery/power/area_smes/proc/overload_lighting(var/chance = 100)
	if(!operating || shorted)
		return
	if( cell && cell.charge>=20)
		cell.use(20);
		spawn(0)
			for(var/area/A in served_areas)
				for(var/obj/machinery/light/L in A)
					if(prob(chance))
						L.on = 1
						L.flicker()
						L.broken()
					sleep(1)

/obj/machinery/power/area_smes/proc/setsubsystem(val)
	if(cell && cell.charge > 0)
		switch(val)
			if(2) return POWERCHAN_ON_AUTO
			if(1) return POWERCHAN_ON
			else return POWERCHAN_OFF
	else
		switch(val)
			if(2) return POWERCHAN_OFF_AUTO
			if(1) return POWERCHAN_OFF_TEMP
			else return POWERCHAN_OFF

// Malfunction: Transfers the unit under AI's control
/obj/machinery/power/area_smes/proc/ai_hack(var/mob/living/silicon/ai/A = null)
	if(!A || !A.hacked_apcs || hacker || aidisabled || A.stat == DEAD)
		return 0
	src.hacker = A
	A.hacked_apcs += src
	locked = 1
	update_icon()
	return 1

/obj/machinery/power/area_smes/malf_upgrade(var/mob/living/silicon/ai/user)
	..()
	malf_upgraded = 1
	emp_hardened = 1
	to_chat(user, "\The [src] has been upgraded. It is now protected against EM pulses.")
	return 1

/obj/item/weapon/module/power_control
	name = "power control module"
	desc = "Heavy-duty switching circuits for power control."
	icon = 'icons/obj/module.dmi'
	icon_state = "power_mod"
	item_state = "electronic"
	matter = list(DEFAULT_WALL_MATERIAL = 50, "glass" = 50)
	w_class = ITEM_SIZE_SMALL
	obj_flags = OBJ_FLAG_CONDUCTIBLE

/////////////////////////////////////////////
// Marker: ties the area it sits in to an area SMES with the same area_id.
/////////////////////////////////////////////

GLOBAL_LIST_EMPTY(area_power_markers)

/obj/effect/area_power_marker
	name = "area power marker"
	desc = "Mapping marker: powers this area from the area SMES with the same area_id."
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x2"
	anchored = 1
	simulated = 0
	invisibility = 101
	var/area_id

/obj/effect/area_power_marker/Initialize()
	. = ..()
	GLOB.area_power_markers += src
	return INITIALIZE_HINT_LATELOAD

/obj/effect/area_power_marker/LateInitialize()
	var/obj/machinery/power/area_smes/S = GLOB.area_smes_by_id[area_id]
	if(S)
		S.add_served_area(get_area(src))
	else
		log_error("Area power marker at [x],[y],[z] has no area SMES with area_id '[area_id]'.")

/obj/effect/area_power_marker/Destroy()
	GLOB.area_power_markers -= src
	var/obj/machinery/power/area_smes/S = GLOB.area_smes_by_id[area_id]
	var/area/A = get_area(src)
	if(S && A)
		var/still_marked = FALSE
		for(var/obj/effect/area_power_marker/M in GLOB.area_power_markers)
			if(M.area_id == area_id && get_area(M) == A)
				still_marked = TRUE
				break
		if(!still_marked)
			S.remove_served_area(A)
	return ..()

#undef UPDATE_CELL_IN
#undef UPDATE_OPENED1
#undef UPDATE_OPENED2
#undef UPDATE_MAINT
#undef UPDATE_BROKE
#undef UPDATE_BLUESCREEN
#undef UPDATE_WIREEXP
#undef UPDATE_ALLGOOD
#undef APC_UPOVERLAY_CHARGEING0
#undef APC_UPOVERLAY_CHARGEING1
#undef APC_UPOVERLAY_CHARGEING2
#undef APC_UPOVERLAY_LOCKED
#undef APC_UPOVERLAY_OPERATING
