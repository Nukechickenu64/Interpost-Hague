SUBSYSTEM_DEF(supply)
	name = "Supply"
	wait = 20 SECONDS
	priority = SS_PRIORITY_SUPPLY
	//Initializes at default time
	flags = SS_NO_TICK_CHECK

	var/orders_in_category = 2
	var/refresh_timer = 3000
	var/current_refresh_timer = 0
	//control
	var/ordernum
	var/list/shoppinglist = list()
	var/list/requestlist = list()
	var/list/donelist = list()
	var/list/master_supply_list = list()
	//sell_orders vars
	var/list/sell_order_list = list() //list of orders
	var/list/list_avalable_categories = list() //list of categories
	//shuttle movement
	var/movetime = 1200
	var/datum/shuttle/autodock/ferry/supply/shuttle

/datum/controller/subsystem/supply/Initialize()
	. = ..()
	ordernum = rand(1,9000)

	//Build master supply list
	for(var/decl/hierarchy/supply_pack/sp in cargo_supply_pack_root.children)
		if(sp.is_category())
			for(var/decl/hierarchy/supply_pack/spc in sp.children)
				master_supply_list += spc

	//Build sell_order list
	var/key = 1 //needed for building associative list
	var/datum/sell_order/root = new
	for(var/so_type in root.children_types()) //building categories list
		list_avalable_categories += list(text("category[]", key) = new so_type)
		key++
	key = 1 //needed for building associative list
	for(var/category_key in list_avalable_categories) //building order list
		var/datum/sell_order/category = list_avalable_categories[category_key]
		var/list/avalable_orders = category.children_types()
		for(var/k=1 to orders_in_category) //generating orders_in_category orders
			var/so_type = pick(avalable_orders) //picking one non-volumed order
			var/datum/sell_order/order = new so_type
			avalable_orders -= list(order.type) //deleting this order from avalable
			so_type = pick(order.children_types()) //getting volume for it
			var/datum/sell_order/order_v = new so_type
			sell_order_list += list(text("order[]", key) = order_v) //adding it to list
			key++

/datum/controller/subsystem/supply/proc/respawn(var/sell_order_type) //reroll order
	var/list/avalable_orders = list()
	var/found_key = null //key of given type of order in sell_order_list
	var/so_type = null

	var/datum/sell_order/so = new sell_order_type
	var/category_type = so.get_category_type() //making category
	var/datum/sell_order/order_category = new category_type
	avalable_orders = order_category.children_types() //getting avalable orders in it

	for(var/key in sell_order_list)
		if(istype(sell_order_list[key], sell_order_type)) //we found our order in list
			found_key = key //setting found key

		so = sell_order_list[key] //removing already existing from avalable to pick
		avalable_orders -= list(so.parent_type)

	so_type = pick(avalable_orders) //picking non-volumed order
	var/datum/sell_order/new_order_wo_v = new so_type
	so_type = pick(new_order_wo_v.children_types()) //picking volume
	var/datum/sell_order/new_order = new so_type

	sell_order_list[found_key] = new_order //changing old order to new

/datum/controller/subsystem/supply/fire()
	if(current_refresh_timer > 0) //decrease timer
		current_refresh_timer -= wait
		if(current_refresh_timer < 0)
			current_refresh_timer = 0

/datum/controller/subsystem/supply/stat_entry()
	..("Requests: [requestlist.len], Shipments: [shoppinglist.len]")

//Supply-related helper procs.

	//To stop things being sent to centcomm which should not be sent to centcomm. Recursively checks for these types.
/datum/controller/subsystem/supply/proc/forbidden_atoms_check(atom/A)
	if(istype(A,/mob/living))
		return 1
	if(istype(A,/obj/item/disk/nuclear))
		return 1
	if(istype(A,/obj/machinery/nuclearbomb))
		return 1
	if(istype(A,/obj/item/device/radio/beacon))
		return 1

	for(var/i=1, i<=A.contents.len, i++)
		var/atom/B = A.contents[i]
		if(.(B))
			return 1

/datum/controller/subsystem/supply/proc/sell_item(var/atom) //returns 1 if sold and 0 if not
	// Sell manifests
	var/atom/A = atom
	if(istype(A, /obj/item/contraband) && A.fingerprintslast)
		var/mob/deliverer = get_mob_by_key(A.fingerprintslast)
		if(deliverer && deliverer.mind && SSdirector)
			var/datum/corporate_profile/CP = SSdirector.profiles[deliverer.mind]
			if(CP)
				CP.deliver_contraband()
	if(istype(A,/obj/item/paper/manifest))
		var/obj/item/paper/manifest/slip = A
		if(!slip.is_copy && slip.stamped && slip.stamped.len) //Any stamp works.
			return 1
	// Sell Requests
	for(var/key in sell_order_list) //for every request
		var/datum/sell_order/so = sell_order_list[key]
		if(istype(so))
			if(so.add_item(A))
				return 1

	// Must sell ore detector disks
	if(istype(A, /obj/item/disk/survey))
		return 1
	return 0

/datum/controller/subsystem/supply/proc/sell()
	for(var/area/subarea in shuttle.shuttle_area)
		for(var/atom/movable/AM in subarea)
			if(istype(AM, /obj/structure/closet/crate)) //sell all shit what want CC
				var/obj/structure/closet/crate/CR = AM
				callHook("sell_crate", list(CR, subarea))
				for(var/atom in CR)
					sell_item(atom)
				qdel(AM)
				continue
			else
				if(sell_item(AM)) //just sell it
					qdel(AM)
					continue
			if(AM.anchored) //for not deleting shuttle
				continue
			qdel(AM)

//Buyin
/datum/controller/subsystem/supply/proc/buy()
	if(!shoppinglist.len)
		return
	var/list/clear_turfs = list()

	for(var/area/subarea in shuttle.shuttle_area)
		for(var/turf/T in subarea)
			if(T.density)
				continue
			var/occupied = 0
			for(var/atom/A in T.contents)
				if(!A.simulated)
					continue
				occupied = 1
				break
			if(!occupied)
				clear_turfs += T
	for(var/S in shoppinglist)
		if(!clear_turfs.len)
			break
		var/turf/pickedloc = pick_n_take(clear_turfs)
		shoppinglist -= S
		donelist += S

		var/datum/supply_order/SO = S
		var/decl/hierarchy/supply_pack/SP = SO.object

		var/obj/A = new SP.containertype(pickedloc)
		A.SetName("[SP.containername][SO.comment ? " ([SO.comment])":"" ]")
		//supply manifest generation begin

		var/obj/item/paper/manifest/slip
		if(!SP.contraband)
			var/info = list()
			info +="<h3>[command_name()] Shipping Manifest</h3><hr><br>"
			info +="Order #[SO.ordernum]<br>"
			info +="Destination: [GLOB.using_map.station_name]<br>"
			info +="[shoppinglist.len] PACKAGES IN THIS SHIPMENT<br>"
			info +="CONTENTS:<br><ul>"

			slip = new /obj/item/paper/manifest(A, JOINTEXT(info))
			slip.is_copy = 0

		//spawn the stuff, finish generating the manifest while you're at it
		if(SP.access)
			if(!islist(SP.access))
				A.req_access = list(SP.access)
			else if(islist(SP.access))
				var/list/L = SP.access // access var is a plain var, we need a list
				A.req_access = L.Copy()

		var/list/spawned = SP.spawn_contents(A)
		if(slip)
			for(var/atom/content in spawned)
				slip.info += "<li>[content.name]</li>" //add the item to the manifest
			slip.info += "</ul><br>CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"

/datum/supply_order
	var/ordernum
	var/decl/hierarchy/supply_pack/object = null
	var/orderedby = null
	var/comment = null
	var/reason = null
	var/orderedrank = null //used for supply console printing