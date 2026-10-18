GLOBAL_LIST_EMPTY(replicator_storages)
GLOBAL_LIST_INIT(replicator_material_names, list("steel" = "steel", "plasteel" = "elerium", "glass" = "zbrite"))

// Place the central machine on the map; it creates the three separate reservoirs.
/obj/machinery/replicator_storage
	name = "replicator storage"
	desc = "A shared material reservoir for replicators. Steel is stored on the left, elerium on the right, and zbrite below."
	icon = 'icons/os13/objects/objects/WIP/replicator.dmi'
	icon_state = "repup"
	pixel_x = -32
	anchored = TRUE
	density = TRUE
	use_power = POWER_USE_OFF
	var/list/compartments = list()

/obj/machinery/replicator_storage/Initialize(mapload)
	. = ..()
	if(!isturf(loc) || !get_step(src, WEST) || !get_step(src, EAST) || !get_step(src, SOUTH))
		return INITIALIZE_HINT_QDEL
	compartments["steel"] = new /obj/machinery/replicator_storage_compartment/steel(get_step(src, WEST), src)
	compartments["plasteel"] = new /obj/machinery/replicator_storage_compartment/elerium(get_step(src, EAST), src)
	compartments["glass"] = new /obj/machinery/replicator_storage_compartment/zbrite(get_step(src, SOUTH), src)
	GLOB.replicator_storages += src

/obj/machinery/replicator_storage/Destroy()
	GLOB.replicator_storages -= src
	for(var/material_id in compartments)
		qdel(compartments[material_id])
	compartments.Cut()
	return ..()

/obj/machinery/replicator_storage/attack_hand(mob/user)
	if(..())
		return
	to_chat(user, SPAN_NOTICE("Load sheets into the matching compartment. Scientists can hold a compartment's control for two seconds to lock or unlock its supply to replicators. Stored material cannot be withdrawn."))

/obj/machinery/replicator_storage_compartment
	name = "replicator material compartment"
	desc = "A sealed material reservoir. Its supply to replicators starts locked."
	icon = 'icons/os13/objects/objects/WIP/labyrinth.dmi'
	anchored = TRUE
	density = TRUE
	use_power = POWER_USE_OFF
	req_access = list(access_research)
	var/obj/machinery/replicator_storage/controller
	var/material_id
	var/material_label
	var/position
	var/stored_material = 0
	var/capacity = 15 * SHEET_MATERIAL_AMOUNT
	var/locked = TRUE
	var/changing_lock = FALSE

/obj/machinery/replicator_storage_compartment/steel
	name = "steel compartment"
	icon_state = "repE"
	material_id = "steel"
	material_label = "steel"
	position = WEST
	pixel_y = -8

/obj/machinery/replicator_storage_compartment/elerium
	name = "elerium compartment"
	icon_state = "repZ"
	material_id = "plasteel"
	material_label = "elerium"
	position = EAST
	pixel_y = -8

/obj/machinery/replicator_storage_compartment/zbrite
	name = "zbrite compartment"
	icon_state = "repS"
	material_id = "glass"
	material_label = "zbrite"
	position = SOUTH

/obj/machinery/replicator_storage_compartment/Initialize(mapload, obj/machinery/replicator_storage/storage)
	. = ..(mapload)
	controller = storage

/obj/machinery/replicator_storage_compartment/Destroy()
	if(controller && controller.compartments[material_id] == src)
		controller.compartments[material_id] = null
	controller = null
	return ..()

/obj/machinery/replicator_storage_compartment/proc/connected()
	return !QDELETED(controller) && !(stat & BROKEN) && !(controller.stat & BROKEN) && isturf(controller.loc) && loc == get_step(controller, position)

/obj/machinery/replicator_storage_compartment/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("Contains [round(stored_material / SHEET_MATERIAL_AMOUNT, 0.01)] / [capacity / SHEET_MATERIAL_AMOUNT] sheets of [material_label]. Production supply is [locked ? "locked" : "unlocked"]."))
	if(material_id != material_label)
		to_chat(user, SPAN_NOTICE("Accepts [material_id] sheets as [material_label]."))
	to_chat(user, SPAN_NOTICE("Scientists can left-click and wait two seconds to change the lock. Materials cannot be withdrawn."))

/obj/machinery/replicator_storage_compartment/attack_hand(mob/user)
	if(..())
		return
	toggle_lock(user)

/obj/machinery/replicator_storage_compartment/proc/toggle_lock(mob/user)
	if(!user || !connected() || changing_lock || !user.Adjacent(src))
		return FALSE
	if(!allowed(user))
		to_chat(user, SPAN_WARNING("Science access is required to change this compartment's lock."))
		return FALSE
	changing_lock = TRUE
	to_chat(user, SPAN_NOTICE("You begin [locked ? "unlocking" : "locking"] the [material_label] supply."))
	var/completed = do_after(user, 2 SECONDS, src)
	if(QDELETED(src))
		return FALSE
	changing_lock = FALSE
	if(!completed || !connected() || !allowed(user) || !user.Adjacent(src))
		return FALSE
	locked = !locked
	add_fingerprint(user)
	to_chat(user, SPAN_NOTICE("The [material_label] supply is now [locked ? "locked" : "unlocked"]."))
	notify_replicators()
	return TRUE

/obj/machinery/replicator_storage_compartment/attackby(obj/item/item, mob/user)
	if(!istype(item, /obj/item/stack/material))
		return ..()
	var/obj/item/stack/material/sheets = item
	if(!connected() || sheets.uses_charge || sheets.material.name != material_id)
		to_chat(user, SPAN_WARNING("This [material_label] compartment only accepts [material_id] sheets."))
		return
	var/amount = min(sheets.get_amount(), round((capacity - stored_material) / sheets.perunit))
	if(amount < 1)
		to_chat(user, SPAN_WARNING("There is no room for another sheet."))
		return
	var/volume = amount * sheets.perunit
	if(!sheets.use(amount))
		return
	stored_material += volume
	add_fingerprint(user)
	to_chat(user, SPAN_NOTICE("You load [amount] [material_id] sheet\s into the compartment."))
	notify_replicators()

/obj/machinery/replicator_storage_compartment/proc/notify_replicators()
	for(var/obj/machinery/r_n_d/protolathe/R in SSmachines.machinery)
		R.Process()
		if(R.linked_console)
			R.linked_console.updateUsrDialog()

/obj/machinery/r_n_d/protolathe/proc/storage_compartments(material_id, unlocked_only = FALSE)
	. = list()
	for(var/obj/machinery/replicator_storage/storage in GLOB.replicator_storages)
		var/obj/machinery/replicator_storage_compartment/C = storage.compartments[material_id]
		if(!QDELETED(C) && C.connected() && (!unlocked_only || !C.locked))
			. += C

/obj/machinery/r_n_d/protolathe/proc/material_name(material_id)
	var/label = GLOB.replicator_material_names[material_id]
	return label ? label : material_id

/obj/machinery/r_n_d/protolathe/proc/material_amount(material_id, unlocked_only = FALSE)
	. = 0
	for(var/obj/machinery/replicator_storage_compartment/C in storage_compartments(material_id, unlocked_only))
		. += C.stored_material

/obj/machinery/r_n_d/protolathe/proc/material_capacity(material_id)
	. = 0
	for(var/obj/machinery/replicator_storage_compartment/C in storage_compartments(material_id))
		. += C.capacity

/obj/machinery/r_n_d/protolathe/proc/store_material(material_id, amount)
	. = 0
	for(var/obj/machinery/replicator_storage_compartment/C in storage_compartments(material_id))
		var/transferred = min(max(0, amount - .), C.capacity - C.stored_material)
		C.stored_material += transferred
		. += transferred

/obj/machinery/r_n_d/protolathe/proc/consume_material(material_id, amount)
	if(amount < 0 || material_amount(material_id, TRUE) < amount)
		return FALSE
	for(var/obj/machinery/replicator_storage_compartment/C in storage_compartments(material_id, TRUE))
		var/transferred = min(amount, C.stored_material)
		C.stored_material -= transferred
		amount -= transferred
	return TRUE

/obj/machinery/r_n_d/protolathe/TotalMaterials()
	. = 0
	for(var/material_id in GLOB.replicator_material_names)
		. += material_amount(material_id)

/obj/machinery/r_n_d/protolathe/eject(material, amount)
	// The reservoirs have no manual withdrawal path, including legacy console hrefs.
	return FALSE

/obj/machinery/r_n_d/protolathe/getLackingMaterials(datum/design/D)
	var/list/missing = list()
	for(var/material_id in D.materials)
		var/required = D.materials[material_id] * mat_efficiency - material_amount(material_id, TRUE)
		if(required > 0)
			missing += "[required] [material_name(material_id)]"
	for(var/chemical in D.chemicals)
		if(!reagents.has_reagent(chemical, D.chemicals[chemical] * mat_efficiency))
			missing += chemical
	return english_list(missing)
