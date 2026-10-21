// OS13 Mining Rework
// Only iron, zrbite and elerium are mineable. Ore nuggets look like any other
// rock and can be fed straight into the Replicator platform. Adds the grav
// cutter instant mining tool and the Harvester, a drag-able mining crate that
// collects loose ore and salvage it drives over while powered on.

/****************************** Ores ******************************/

/obj/item/ore/os13
	name = "ore"
	desc = "A lump of ore that looks like any other rock."
	icon = 'icons/os13/objects/objects/mining.dmi'
	icon_state = "ore"
	randpixel = 8
	w_class = ITEM_SIZE_SMALL

/obj/item/ore/os13/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/device/core_sampler))
		var/obj/item/device/core_sampler/C = W
		C.sample_item(src, user)
	else
		return ..()

// Keep the generic rock sprite; only sync names/tech from the ore datum so the
// processing unit can account for smelting.
/obj/item/ore/os13/update_ore()
	if(!ore)
		return
	SetName(ore.display_name)
	origin_tech = ore.origin_tech.Copy()

/obj/item/ore/os13/iron
	name = "iron ore"
	ore = /ore/hematite
	matter = list("steel" = 2000)

/obj/item/ore/os13/zbrite
	name = "zbrite"
	ore = /ore/zbrite
	matter = list("glass" = 2000)

/obj/item/ore/os13/elerium
	name = "elerium"
	ore = /ore/elerium
	matter = list("plasteel" = 2000)

/********************** Grav Cutter **********************/

/obj/item/pickaxe/gravcutter
	name = "grav cutter"
	desc = "A portable graviton shear that cleanly slices mineral deposits apart in a single pass."
	icon = 'icons/os13/objects/objects/weapons/gun.dmi'
	icon_state = "gravcutter"
	item_state = "gravcutter"
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi'
		)
	digspeed = 0
	excavation_amount = 200
	drill_verb = "cutting"
	drill_sound = 'sound/weapons/marauder.ogg'
	w_class = ITEM_SIZE_NORMAL
	matter = list(DEFAULT_WALL_MATERIAL = 2500, "plasteel" = 1000)
	origin_tech = list(TECH_MATERIAL = 4, TECH_PHORON = 3, TECH_ENGINEERING = 3)

// Instantly mines through the standard pickaxe path in turf/simulated/mineral/attackby().
/obj/item/pickaxe/gravcutter/get_digspeed(var/mob/user)
	return 0

/********************** Harvester **********************/

/obj/structure/harvester
	name = "harvester"
	desc = "A heavy collection crate on treads. While powered on, it collects loose ore, shards and scrap. Click it to power it, and use Release Contents in its right-click menu to empty it."
	icon = 'icons/os13/objects/objects/mining.dmi'
	icon_state = "harvester0"
	density = 1
	var/on = FALSE
	var/list/scooped = list()

/obj/structure/harvester/update_icon()
	icon_state = on ? "harvester1" : "harvester0"

/obj/structure/harvester/attack_hand(mob/user)
	add_fingerprint(user)
	on = !on
	if(on)
		scoop_turf()
		to_chat(user, "<span class='notice'>You power on \the [src]. It will collect loose ore, shards and scrap.</span>")
	else
		to_chat(user, "<span class='notice'>You power off \the [src].</span>")
	update_icon()

/obj/structure/harvester/Move()
	. = ..()
	if(. && on)
		scoop_turf()
	return .

// Called on a successful Move(): collect eligible loose salvage on the destination turf.
/obj/structure/harvester/proc/scoop_turf()
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/obj/item/O in T.contents)
		if(O.anchored || !can_collect(O))
			continue
		O.forceMove(src)
		scooped |= O
	if(scooped.len)
		flick("harvester1", src)

/obj/structure/harvester/examine(mob/user)
	. = ..()
	if(!Adjacent(user))
		return
	scooped &= contents
	if(!scooped.len)
		to_chat(user, "It is empty.")
		return
	to_chat(user, "It holds [scooped.len] collected item\s.")

/obj/structure/harvester/proc/can_collect(obj/item/O)
	return istype(O, /obj/item/ore) || istype(O, /obj/item/weapon/material/shard) || istype(O, /obj/item/solar_panel)

/obj/structure/harvester/Destroy()
	// Salvage must not disappear with a destroyed collection crate.
	release_contents()
	return ..()

/obj/structure/harvester/Exited(atom/movable/O, atom/newloc)
	. = ..()
	scooped -= O

/obj/structure/harvester/proc/release_contents()
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	for(var/obj/item/O in contents)
		O.forceMove(T)
	scooped.Cut()
	return TRUE

/obj/structure/harvester/verb/release_ores()
	set name = "Release Contents"
	set category = "Object"
	set src in view(1)

	if(!istype(usr, /mob/living/carbon/human))
		to_chat(usr, "<span class='warning'>You are physically incapable of emptying the harvester.</span>")
		return
	if(usr.stat || usr.restrained())
		return
	if(!Adjacent(usr))
		to_chat(usr, "You cannot reach the harvester.")
		return

	add_fingerprint(usr)
	scooped &= contents

	if(!scooped.len)
		to_chat(usr, "<span class='warning'>The harvester is empty.</span>")
		return

	release_contents()
	to_chat(usr, "<span class='notice'>You release everything the harvester has collected.</span>")
