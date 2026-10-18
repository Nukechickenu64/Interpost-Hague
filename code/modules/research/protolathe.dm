/obj/machinery/r_n_d/protolathe
	name = "\improper Replicator"
	desc = "A matter replication and reclamation platform. Each conversion releases a brilliant blue flash and a lethal burst of radiation nearby."
	icon = 'icons/os13/replicator/labyrinth.dmi'
	icon_state = "chair"
	layer = ABOVE_TILE_LAYER
	density = FALSE
	atom_flags = ATOM_FLAG_OPEN_CONTAINER

	idle_power_usage = 30
	active_power_usage = 5000

	var/list/datum/design/queue = list()
	var/mat_efficiency = 1
	var/converting = FALSE
	var/datum/radiation_source/replicator/radiation_field
	var/datum/design/producing_design
	var/turf/production_turf

/obj/machinery/r_n_d/protolathe/New()
	// All feedstock lives in the separate, shared storage compartments.
	materials = list()
	..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/protolathe(src)
	component_parts += new /obj/item/stock_parts/matter_bin(src)
	component_parts += new /obj/item/stock_parts/matter_bin(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/reagent_containers/glass/beaker(src)
	component_parts += new /obj/item/reagent_containers/glass/beaker(src)
	RefreshParts()

/obj/machinery/r_n_d/protolathe/Destroy()
	if(linked_console && linked_console.linked_lathe == src)
		linked_console.linked_lathe = null
	linked_console = null
	return ..()

/obj/machinery/r_n_d/protolathe/Process()
	..()
	if(converting || busy || panel_open || stat || !powered())
		return
	if(length(queue))
		var/datum/design/D = queue[1]
		if(build(D))
			removeFromQueue(1)

/obj/machinery/r_n_d/protolathe/RefreshParts()
	var/T = 0
	for(var/obj/item/reagent_containers/glass/G in component_parts)
		T += G.reagents.maximum_volume
	create_reagents(T)
	T = 0
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		T += M.rating
	mat_efficiency = 1 - (T - 2) / 8


/obj/machinery/r_n_d/protolathe/update_icon()
	icon_state = "chair"

/obj/machinery/r_n_d/protolathe/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(busy || converting)
		to_chat(user, "<span class='notice'>\The [src] is busy. Please wait for completion of previous operation.</span>")
		return 1

	if(istype(O, /obj/item/ore/os13))
		if(!user)
			return 1
		var/material_id
		if(istype(O, /obj/item/ore/os13/iron))
			material_id = DEFAULT_WALL_MATERIAL
		else if(istype(O, /obj/item/ore/os13/zbrite))
			material_id = "glass"
		else if(istype(O, /obj/item/ore/os13/elerium))
			material_id = "plasteel"
		if(!material_id)
			to_chat(user, "<span class='warning'>The replicator cannot make sense of this ore.</span>")
			return 1
		if(stat || !powered() || panel_open)
			to_chat(user, "<span class='warning'>The replicator is offline right now.</span>")
			return 1
		var/ore_label = O.name
		if(user.get_active_hand() == O)
			user.drop_item()
		O.forceMove(src)
		var/recovered = store_material(material_id, SHEET_MATERIAL_AMOUNT)
		if(recovered <= 0)
			O.forceMove(get_turf(user))
			to_chat(user, "<span class='warning'>The replicator cannot store any more [material_name(material_id)] right now.</span>")
			return 1
		use_power_oneoff(active_power_usage)
		conversion_pulse()
		qdel(O)
		to_chat(user, "<span class='notice'>You feed the [ore_label] into the replicator, recovering [recovered] units of [material_name(material_id)].</span>")
		Process()
		if(linked_console)
			linked_console.updateUsrDialog()
		return 1
	if(default_deconstruction_screwdriver(user, O))
		if(linked_console)
			linked_console.linked_lathe = null
			linked_console = null
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return
	if(!O.is_open_container())
		to_chat(user, "<span class='notice'>Place items or material sheets on \the [src]'s platform, then reclaim them from the replicator console.</span>")
	return 1

/obj/machinery/r_n_d/protolathe/proc/addToQueue(var/datum/design/D)
	queue += D
	Process()

/obj/machinery/r_n_d/protolathe/proc/removeFromQueue(var/index)
	queue.Cut(index, index + 1)
	return

/obj/machinery/r_n_d/protolathe/proc/canBuild(var/datum/design/D)
	for(var/M in D.materials)
		if(material_amount(M, TRUE) < D.materials[M] * mat_efficiency)
			return 0
	for(var/C in D.chemicals)
		if(!reagents.has_reagent(C, D.chemicals[C] * mat_efficiency))
			return 0
	return 1

/obj/machinery/r_n_d/protolathe/proc/build(var/datum/design/D)
	if(busy || converting || stat || !powered() || panel_open || !canBuild(D))
		return FALSE
	busy = TRUE
	producing_design = D
	production_turf = get_turf(src)
	var/power = active_power_usage
	for(var/M in D.materials)
		power += round(D.materials[M] / 5)
	power = max(active_power_usage, power)
	use_power_oneoff(power)
	conversion_pulse(3 SECONDS)
	addtimer(CALLBACK(src, /obj/machinery/r_n_d/protolathe/proc/finish_production), 3 SECONDS)
	if(linked_console)
		linked_console.updateUsrDialog()
	return TRUE

/obj/machinery/r_n_d/protolathe/proc/finish_production()
	var/datum/design/D = producing_design
	if(!D)
		return
	// Recheck locks and shared stock at completion so another replicator cannot
	// spend the same material, and locking a compartment stops it being consumed.
	if(!stat && powered() && !panel_open && get_turf(src) == production_turf && canBuild(D))
		for(var/M in D.materials)
			consume_material(M, D.materials[M] * mat_efficiency)
		for(var/C in D.chemicals)
			reagents.remove_reagent(C, D.chemicals[C] * mat_efficiency)
		if(D.build_path)
			var/obj/new_item = D.Fabricate(src, src)
			new_item.loc = loc
			if(mat_efficiency != 1 && length(new_item.matter))
				for(var/material in new_item.matter)
					new_item.matter[material] *= mat_efficiency
	else
		queue.Insert(1, D)
	producing_design = null
	production_turf = null
	busy = FALSE
	if(linked_console)
		linked_console.updateUsrDialog()
	Process()

/obj/machinery/r_n_d/protolathe/proc/can_reclaim(obj/item/item)
	// Only loose objects on the platform: never held, equipped, inserted or adjacent items.
	if(!item || QDELETED(item) || !isturf(loc) || item.loc != loc || item.anchored || (item in component_parts))
		return FALSE
	if(istype(item, /obj/item/stack/material))
		var/obj/item/stack/material/sheets = item
		return !sheets.uses_charge && sheets.get_amount() > 0 && (sheets.material.name in GLOB.replicator_material_names)
	if(istype(item, /obj/item/stack))
		return FALSE
	// Never destroy occupied containers or the contents of storage items.
	// Integrated circuits are the analyzer's existing exception: their design is recovered.
	if(length(item.contents) && !istype(item, /obj/item/device/electronic_assembly))
		return FALSE
	if(length(item.search_contents_for(/mob)))
		return FALSE
	if(istype(item, /obj/item/device/electronic_assembly))
		return length(item.contents) > 0
	for(var/material in item.matter)
		if((material in GLOB.replicator_material_names) && item.matter[material] > 0)
			return TRUE
	return FALSE

/obj/machinery/r_n_d/protolathe/proc/reclaim(obj/item/item)
	if(stat || !powered() || panel_open || busy || converting || !linked_console || !can_reclaim(item))
		return FALSE
	busy = TRUE
	converting = TRUE
	. = recover_item(item)
	if(.)
		use_power_oneoff(active_power_usage)
		conversion_pulse()
	converting = FALSE
	busy = FALSE
	// Newly recovered materials can immediately satisfy pending production requests.
	Process()
	if(linked_console)
		linked_console.updateUsrDialog()

/obj/machinery/r_n_d/protolathe/proc/recover_item(obj/item/item)
	if(!can_reclaim(item))
		return FALSE
	if(istype(item, /obj/item/stack/material))
		var/obj/item/stack/material/sheets = item
		var/material_name = sheets.material.name
		var/amount = min(sheets.get_amount(), round((material_capacity(material_name) - material_amount(material_name)) / sheets.perunit))
		var/recovered = amount * sheets.perunit
		if(amount <= 0 || !sheets.use(amount))
			return FALSE
		store_material(material_name, recovered)
		return TRUE
	var/recovered_any = FALSE
	if(istype(item, /obj/item/device/electronic_assembly))
		linked_console.add_ic_design(item)
		recovered_any = TRUE
	// Match a stock analyzer's recovery; upgrades improve it without creating matter.
	var/recovery = min(1, 0.3 / max(0.1, mat_efficiency))
	for(var/material in item.matter)
		if(store_material(material, max(0, item.matter[material] * recovery)) > 0)
			recovered_any = TRUE
	if(!recovered_any)
		return FALSE
	qdel(item)
	return TRUE

/obj/machinery/r_n_d/protolathe/proc/conversion_pulse(flash_duration = 4)
	var/turf/origin = get_turf(src)
	if(!origin)
		return
	new /obj/effect/replicator_flash(origin, flash_duration)
	if(QDELETED(radiation_field) || radiation_field.source_turf != origin)
		radiation_field = new(origin)
	else
		radiation_field.refresh()
	radiation_field.expose(TRUE)

/datum/radiation_source/replicator
	var/peak_power = 500 * 3 ** 2
	var/duration = 60 SECONDS
	var/started_at

/datum/radiation_source/replicator/New(turf/origin)
	..(origin)
	refresh()
	// Independent of the turf's ordinary source: do not replace ambient radiation.
	SSradiation.sources += src

/datum/radiation_source/replicator/proc/refresh()
	started_at = world.time
	update_rad_power(peak_power)

/datum/radiation_source/replicator/process_radiation()
	update_rad_power(peak_power * max(0, 1 - (world.time - started_at) / duration))
	if(!QDELETED(src))
		expose()

/datum/radiation_source/replicator/get_power_at_distance(distance)
	// A deadly three-tile core and a weaker inverse-square tail beyond it.
	return distance > 3 ? rad_power * (25 * 4 ** 2) / peak_power : rad_power

/datum/radiation_source/replicator/proc/expose(initial_burst = FALSE)
	for(var/mob/living/victim in GLOB.living_mob_list_)
		if(victim.stat == DEAD)
			continue
		var/dose = SSradiation.get_rads_at_turf(get_turf(victim), src)
		if(dose <= RAD_LEVEL_LOW)
			continue
		if(initial_burst)
			victim.rad_act(dose)
		// Normal radiation burden is capped and harms humans very slowly. This intense
		// field also causes acute poisoning, using the same shielding and radiation armor.
		var/damage = min(50, dose / 10)
		if(ishuman(victim))
			var/mob/living/carbon/human/H = victim
			damage *= H.species.radiation_mod
		victim.apply_damage(damage, TOX, blocked = victim.getarmor(null, "rad"))

/obj/effect/replicator_flash
	icon = 'icons/os13/replicator/effects.dmi'
	icon_state = ""
	anchored = TRUE
	density = FALSE
	mouse_opacity = 0
	simulated = FALSE
	pixel_x = -32
	pixel_y = -32
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_LIGHTING_LAYER
	light_range = 8
	light_power = 6
	light_color = COLOR_DEEP_SKY_BLUE

/obj/effect/replicator_flash/Initialize(mapload, duration = 4)
	. = ..(mapload)
	if(duration >= 3 SECONDS)
		// Stretch one complete seven-frame animation across the production cycle.
		show_frame(1)
		for(var/frame = 2, frame <= 7, frame++)
			addtimer(CALLBACK(src, /obj/effect/replicator_flash/proc/show_frame, frame), (frame - 1) * duration / 7)
	else
		flick("reclaimer", src)
	QDEL_IN(src, duration)

/obj/effect/replicator_flash/proc/show_frame(frame)
	var/static/list/frames
	if(!frames)
		frames = list()
		for(var/index = 1, index <= 7, index++)
			frames += icon('icons/os13/replicator/effects.dmi', "reclaimer", SOUTH, index)
	icon = frames[frame]
