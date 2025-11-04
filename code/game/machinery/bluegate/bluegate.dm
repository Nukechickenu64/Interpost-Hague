/obj/machinery/bluegate
	name = "Bluespace gateway chamber"
	desc = "Nobody on the station would know how exactly this works, better not break it."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "sleeper_0"
	density = 1
	anchored = 1
	clicksound = 'sound/machines/buttonbeep.ogg'
	clickvol = 30
	var/mob/living/carbon/human/occupant = null
	var/obj/item/weapon/reagent_containers/glass/beaker = null

	idle_power_usage = 15
	active_power_usage = 1000 //builtin health analyzer, dialysis machine, injectors.

/obj/machinery/bluegate/Initialize()
	. = ..()
	update_icon()

/obj/machinery/bluegate/Process()
	if(stat & (NOPOWER|BROKEN))
		return

/obj/machinery/bluegate/update_icon()
	icon_state = "sleeper_[occupant ? "1" : "0"]"

/obj/machinery/bluegate/attack_hand(var/mob/user)
	if(stat & (NOPOWER|BROKEN))
		return
	if(user == occupant)
		if(occupant.isblue)
			to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The interior computer's nearly burned out screen shows you the following commands:</span>\n<span class='feedback'><a href='?src=\ref[src];action=fuel;align='right'>CHECK FUEL</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=activate;align='right'>DEACTIVATE TRANSFORMATION</a></span></div></div>")
		else
			to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The interior computer's nearly burned out screen shows you the following commands:</span>\n<span class='feedback'><a href='?src=\ref[src];action=fuel;align='right'>CHECK FUEL</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=activate;align='right'>ACTIVATE TRANSFORMATION</a></span></div></div>")
	else
		to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>The computer's nearly burned out screen shows you the following commands:</span>\n<hr><span class='feedback'><a href='?src=\ref[src];action=eject;align='right'>EJECT SUBJECT</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=beaker;align='right'>EJECT BEAKER</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=fuel;align='right'>CHECK FUEL</a></span></div></div>")

/obj/machinery/bluegate/Topic(href, href_list, hsrc)
	if(get_dist(src, usr) > 1)
		return
	switch(href_list["action"])
		if("eject")
			go_out()

		if("beaker")
			remove_beaker()

		if("fuel")
			if(!beaker)
				to_chat(usr, "<span class='warning'>There is no beaker in the sleeper.</span>")
				return TOPIC_REFRESH
			else
				visible_message("there's [beaker.reagents.total_volume] units of fuel left.")

		if("activate")
			if(!occupant)
				to_chat(usr, "<span class='warning'>There is no occupant in the sleeper.</span>")

			if(stat & (NOPOWER|BROKEN))
				to_chat(usr, "<span class='warning'>The [src] is not powered.</span>")
			else

				if(!beaker || !beaker.reagents.get_reagent_amount(/datum/reagent/toxin/phoron) || beaker.reagents.get_reagent_amount(/datum/reagent/toxin/phoron) < 100)
					to_chat(usr, "<span class='warning'>There is not enough phoron fuel in the beaker.</span>")
					return TOPIC_REFRESH
				else
					for(var/obj/item/bad in occupant.contents)
						if(!istype(bad,/obj/item/organ))
							to_chat(occupant, "<span class='warning'>There must be no items on subject.</span>")
							return
					beaker.reagents.remove_reagent(/datum/reagent/toxin/phoron, 100)
					if(!occupant.isblue)
						occupant.phantomize_blue()
						use_power_oneoff(active_power_usage,POWER_CHAN, TRUE)
						visible_message("\The [occupant] slowly materializes out of the phantom state.")
					else
						occupant.phantomize_blue()
						use_power_oneoff(active_power_usage, POWER_CHAN, TRUE)
						visible_message("\The [occupant] slowly fades into a phantom state.")

/obj/item/weapon/reagent_containers/glass/beaker/phoron
	name = "phoron beaker"
	desc = "A beaker filled with highly concentrated phoron fuel."


/obj/item/weapon/reagent_containers/glass/beaker/phoron/New()
	reagents = new()
	reagents.add_reagent(/datum/reagent/toxin/phoron, 500)

/obj/machinery/bluegate/attack_ai(var/mob/user)
	return attack_hand(user)

/obj/machinery/bluegate/attackby(var/obj/item/I, var/mob/user)
	if(istype(I, /obj/item/weapon/reagent_containers/glass))
		add_fingerprint(user)
		if(!beaker)
			beaker = I
			user.drop_item()
			I.forceMove(src)
			user.visible_message("<span class='notice'>\The [user] adds \a [I] to \the [src].</span>", "<span class='notice'>You add \a [I] to \the [src].</span>")
		else
			to_chat(user, "<span class='warning'>\The [src] has a beaker already.</span>")
		return
	else
		..()

/obj/machinery/bluegate/MouseDrop_T(var/mob/target, var/mob/user)
	if(!CanMouseDrop(target, user))
		return
	if(!istype(target))
		return
	if(target.buckled)
		to_chat(user, "<span class='warning'>Unbuckle the subject before attempting to move them.</span>")
		return
	go_in(target, user)

/obj/machinery/bluegate/relaymove(var/mob/user)
	..()
	go_out()


/obj/machinery/bluegate/proc/go_in(var/mob/M, var/mob/user)
	if(!M)
		return
	if(stat & (BROKEN|NOPOWER))
		return
	if(occupant)
		to_chat(user, "<span class='warning'>\The [src] is already occupied.</span>")
		return

	if(M == user)
		visible_message("\The [user] starts climbing into \the [src].")
	else
		visible_message("\The [user] starts putting [M] into \the [src].")

	if(do_after(user, 20, src))
		if(occupant)
			to_chat(user, "<span class='warning'>\The [src] is already occupied.</span>")
			return
		M.stop_pulling()
		if(M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.forceMove(src)
		occupant = M
		update_icon()

/obj/machinery/bluegate/proc/go_out()
	if(!occupant)
		return
	if(occupant.client)
		occupant.client.eye = occupant.client.mob
		occupant.client.perspective = MOB_PERSPECTIVE
	occupant.dropInto(loc)
	occupant = null
	for(var/atom/movable/A in src) // In case an object was dropped inside or something
		if(A == beaker)
			continue
		A.dropInto(loc)
	update_use_power(POWER_USE_IDLE)
	update_icon()

/obj/machinery/bluegate/proc/remove_beaker()
	if(beaker)
		beaker.dropInto(loc)
		beaker = null

/mob/living/carbon/human
	var/isblue = FALSE

/mob/living/carbon/human/attack_hand(mob/living/carbon/M)
	. = ..()


/mob/living/carbon/human/equip_to_slot(obj/item/W, slot, redraw_mob)

/mob/living/carbon/human/proc/phantomize_blue()
	// Toggle phantom state on the target human
	if(isblue)
		// Return to normal
		isblue = FALSE
		density = 1
		alpha = 255
		plane = DEFAULT_PLANE
		invisibility = 0
		see_invisible = 0
		simulated = TRUE
		update_sight()
	else
		// Enter phantom state
		isblue = TRUE
		density = 0
		alpha = 127
		plane = OBSERVER_PLANE
		invisibility = INVISIBILITY_OBSERVER
		see_invisible = SEE_INVISIBLE_OBSERVER
		simulated = FALSE
		update_sight()

/obj/machinery/bluegate/Destroy()
	if(occupant)
		go_out()
	. = ..()

/obj/concept
		name = "thought wave"
		desc = "A wave of pure thought energy."
		invisibility = INVISIBILITY_OBSERVER
		icon = 'icons/effects/chemsmoke.dmi'

/obj/concept/grief
		name = "Grief"
		desc = "A wave of pure thought energy filled with sorrow and despair."

/obj/concept/fullfillment
	name = "Fulfillment"
	desc = "A wave of pure thought energy filled with joy and satisfaction."


/obj/item/weapon/bluescanner
	name = "bluespace scanner"
	desc = "A handheld device used to detect and store bluespace anomaly data within a disk. powered by bluespace itself, handy."

/obj/machinery/phaser
	name = "Bluespace phaser"
	desc = "Nobody on the station would know how exactly this works, better not break it."
	icon = 'icons/obj/modular_console.dmi'
	icon_state = "cs_db"
	density = 1
	anchored = 1
	clicksound = 'sound/machines/buttonbeep.ogg'
	clickvol = 30

	idle_power_usage = 15
	active_power_usage = 1000

// Machine that turns completed research papers into random research data disks
/obj/machinery/research_processor
	name = "Ideation Condenser"
	desc = "Condenses formalized concepts into useful research data disks. Feed it completed research papers."
	icon = 'icons/obj/modular_console.dmi'
	icon_state = "cs_db"
	density = 1
	anchored = 1
	clicksound = 'sound/machines/buttonbeep.ogg'
	clickvol = 30
	idle_power_usage = 10
	active_power_usage = 250

	var/obj/item/weapon/paper/research/loaded_paper = null
	var/obj/item/weapon/disk/design_disk/loaded_disk = null

/obj/machinery/research_processor/update_icon()
	return

/obj/machinery/research_processor/attack_hand(mob/user)
	if(stat & (NOPOWER|BROKEN))
		return
	var/list/lines = list()
	lines += "<span class='graytext'>Ideation Condenser</span>"
	lines += "<hr>"
	if(loaded_paper)
		lines += "<span class='notice'>Paper: [loaded_paper.name] ([loaded_paper.progress]% complete)</span>"
		lines += "<span class='feedback'><a href='?src=\ref[src];action=eject'>EJECT PAPER</a></span>"
	else
		lines += "<span class='info'>Insert a completed research paper.</span>"

	if(loaded_disk)
		if(loaded_disk.blueprint)
			lines += "<span class='warning'>Disk: [loaded_disk] already contains a design.</span>"
		else
			lines += "<span class='notice'>Disk: [loaded_disk] (empty)</span>"
		lines += "<span class='feedback'><a href='?src=\ref[src];action=eject_disk'>EJECT DISK</a></span>"
	else
		lines += "<span class='info'>Insert an empty design disk.</span>"

	if(loaded_paper && loaded_disk && !loaded_disk.blueprint)
		lines += "<hr>"
		lines += "<span class='feedback'><a href='?src=\ref[src];action=process'>PROCESS PAPER → WRITE DISK</a></span>"
	var/content = jointext(lines, "<br>")
	to_chat(user, "\n<div class='firstdivmood'><div class='moodbox'>[content]</div></div>")

/obj/machinery/research_processor/Topic(href, href_list)
	if(..())
		return 1
	usr.set_machine(src)
	switch(href_list["action"])
		if("eject")
			if(loaded_paper)
				loaded_paper.dropInto(loc)
				loaded_paper = null
				visible_message("\The [src] clunks and spits out the paper.")
		if("eject_disk")
			if(loaded_disk)
				loaded_disk.dropInto(loc)
				loaded_disk = null
				visible_message("\The [src] ejects the design disk.")
		if("process")
			if(!loaded_paper)
				to_chat(usr, "<span class='warning'>No paper loaded.</span>")
				return TOPIC_REFRESH
			if(loaded_paper.progress < 100)
				to_chat(usr, "<span class='warning'>The research paper is incomplete.</span>")
				return TOPIC_REFRESH
			if(!loaded_disk)
				to_chat(usr, "<span class='warning'>No design disk loaded.</span>")
				return TOPIC_REFRESH
			if(loaded_disk.blueprint)
				to_chat(usr, "<span class='warning'>The loaded design disk is not empty.</span>")
				return TOPIC_REFRESH
			// Consume power and produce a weighted random disk based on concept kind
			use_power_oneoff(active_power_usage)
			var/kind = (loaded_paper.concept_kind || "")
			// Require and write to the inserted empty design disk
			var/t_design = pick_weighted_design(kind)
			loaded_disk.blueprint = new t_design()
			visible_message("\The [src] condenses the ideas into a component design and writes it to [loaded_disk].")
			qdel(loaded_paper)
			loaded_paper = null
	attack_hand(usr)
	return 1

/obj/machinery/research_processor/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/paper/research))
		if(loaded_paper)
			to_chat(user, "<span class='warning'>There is already a paper loaded.</span>")
			return
		var/obj/item/weapon/paper/research/R = W
		user.drop_item()
		R.forceMove(src)
		loaded_paper = R
		visible_message("\The [user] feeds \a [R] into \the [src].")
		return
	else if(istype(W, /obj/item/weapon/disk/design_disk))
		if(loaded_disk)
			to_chat(user, "<span class='warning'>There is already a design disk loaded.</span>")
			return
		var/obj/item/weapon/disk/design_disk/D = W
		if(D.blueprint)
			to_chat(user, "<span class='warning'>That design disk is not empty.</span>")
			return
		user.drop_item()
		D.forceMove(src)
		loaded_disk = D
		visible_message("\The [user] inserts \a [D] into \the [src].")
		return
	return ..()

// Weighted pick helpers
/obj/machinery/research_processor/proc/weighted_pick(var/list/L)
	// L is a list keyed by type with numeric weights
	var/total = 0
	for(var/K in L)
		total += max(1, L[K])
	if(total <= 0)
		return null
	var/r = rand(1, total)
	var/acc = 0
	for(var/K in L)
		acc += max(1, L[K])
		if(r <= acc)
			return K
	return null

/obj/machinery/research_processor/proc/pick_weighted_tech(var/kind)
	var/list/choices = list()
	var/list/tech_types = typesof(/datum/tech) - /datum/tech
	for(var/T in tech_types)
		var/datum/tech/tmp = new T()
		var/w = 1
		if(kind == "grief")
			if(tmp.id == TECH_ARCANE)
				w = 5
			else if(tmp.id == TECH_DATA)
				w = 3
			else if(tmp.id == TECH_MAGNET)
				w = 2
		else if(kind == "fulfillment")
			if(tmp.id == TECH_DATA)
				w = 5
			else if(tmp.id == TECH_MAGNET)
				w = 3
			else if(tmp.id == TECH_ARCANE)
				w = 1
		qdel(tmp)
		choices[T] = w
	var/choice = weighted_pick(choices)
	if(!choice)
		return pick(tech_types)
	return choice

/obj/machinery/research_processor/proc/pick_weighted_design(var/kind)
	var/list/design_types = typesof(/datum/design) - /datum/design
	var/list/choices = list()
	for(var/Dt in design_types)
		var/w = 1
		if(kind == "fulfillment")
			if(ispath(Dt, /datum/design/item/medical))
				w = 5
			else if(ispath(Dt, /datum/design/item/hud))
				w = 3
			else if(ispath(Dt, /datum/design/item/optical))
				w = 3
		else if(kind == "grief")
			if(ispath(Dt, /datum/design/item/mining))
				w = 3
			else if(ispath(Dt, /datum/design/item/mecha/weapon))
				w = 3
			else if(ispath(Dt, /datum/design/item/robot_upgrade))
				w = 2
		choices[Dt] = w
	var/choice = weighted_pick(choices)
	if(!choice)
		return pick(design_types)
	return choice


/obj/machinery/phaser/attackby(obj/item/O, mob/user)
	// Toggle an item's visibility between normal and observer-only (ghost) for phantom users
	if(!istype(O, /obj/item))
		return ..()

	if(O.invisibility == INVISIBILITY_OBSERVER)
		// Make visible to everyone
		use_power_oneoff(active_power_usage)
		O.invisibility = 0
		visible_message("\the [O] reappears into ordinary existence!")
		if(istype(user))
			user.drop_item()
	else
		// Make visible only to observers/phantoms
		use_power_oneoff(active_power_usage)
		O.invisibility = INVISIBILITY_OBSERVER
		visible_message("\the [O] fades out of phase with reality.")
		if(istype(user))
			user.drop_item()

// Research paper produced from concepts
/obj/item/weapon/paper/research
	var/progress = 0           // 0..100 percent
	var/concept_name = ""
	var/concept_kind = ""      // "grief" or "fulfillment" (from the concept type)

/obj/item/weapon/paper/research/examine(mob/user)
	. = ..()
	to_chat(user, "<span class='notice'>Research progress: [progress]%</span>")

// Using paper+pen on concepts to extract research
/obj/concept
	// How much insight remains in this concept before it dissipates
	var/remaining_insight = 100

/obj/concept/proc/has_pen_and_paper(mob/user)
	if(!user)
		return FALSE
	var/obj/item/weapon/pen/pen_in_hands = null
	var/obj/item/weapon/paper/paper_in_hands = null
	if(istype(user.get_active_hand(), /obj/item/weapon/pen))
		pen_in_hands = user.get_active_hand()
	if(istype(user.get_inactive_hand(), /obj/item/weapon/pen))
		pen_in_hands = user.get_inactive_hand()
	if(istype(user.get_active_hand(), /obj/item/weapon/paper))
		paper_in_hands = user.get_active_hand()
	if(!paper_in_hands && istype(user.get_inactive_hand(), /obj/item/weapon/paper))
		paper_in_hands = user.get_inactive_hand()
	return (pen_in_hands && paper_in_hands)

/obj/concept/proc/get_paper(mob/user)
	var/obj/item/weapon/paper/P = null
	if(istype(user.get_active_hand(), /obj/item/weapon/paper))
		P = user.get_active_hand()
	else if(istype(user.get_inactive_hand(), /obj/item/weapon/paper))
		P = user.get_inactive_hand()
	return P

/obj/concept/proc/extract_step(mob/user)
	var/obj/item/weapon/paper/P = get_paper(user)
	if(!P)
		return FALSE
	var/obj/item/weapon/paper/research/R
	if(istype(P, /obj/item/weapon/paper/research))
		R = P
	else
		// Convert plain paper into a research paper tied to this concept
		var/loc_old = P.loc
		qdel(P)
		R = new /obj/item/weapon/paper/research(loc_old)
		R.name = "research paper: [src.name]"
		R.concept_name = src.name
		if(istype(src, /obj/concept/grief))
			R.concept_kind = "grief"
		else
			R.concept_kind = "fulfillment"
		if(ismob(loc_old))
			var/mob/M = loc_old
			// Put into the same hand if possible
			if(!M.put_in_active_hand(R))
				M.put_in_inactive_hand(R)

	// Balanced: smaller per-step progress to require more interactions
	var/prog_gain = rand(12, 20)
	prog_gain = min(prog_gain, remaining_insight)
	R.progress = clamp(R.progress + prog_gain, 0, 100)
	remaining_insight = max(remaining_insight - prog_gain, 0)
	to_chat(user, "<span class='notice'>You jot down insight from the [src.name] ([prog_gain]% gained, [R.progress]% total).</span>")

	if(R.progress >= 100 || remaining_insight <= 0)
		visible_message("\The [src] collapses into stray thought motes.")
		qdel(src)
	return TRUE

/obj/concept/attackby(obj/item/W, mob/user)
	if(!Adjacent(user))
		return ..()
	if(!has_pen_and_paper(user))
		to_chat(user, "<span class='warning'>You need both a pen and paper to formalize this concept.</span>")
		return
	// Using either item on the concept performs an extraction step
	extract_step(user)
	return