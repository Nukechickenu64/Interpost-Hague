
/**
 *  A vending machine
 */
/obj/machinery/vending
	name = "Vendomat"
	desc = "A generic vending machine."
	icon = 'icons/obj/vending.dmi'
	icon_state = "generic"
	layer = BELOW_OBJ_LAYER
	anchored = 1
	density = 1
	obj_flags = OBJ_FLAG_ANCHORABLE
	clicksound = "button"
	clickvol = 40

	var/icon_vend //Icon_state when vending
	var/icon_deny //Icon_state when denying access
	var/diona_spawn_chance = 0.1

	// Power
	idle_power_usage = 10
	var/vend_power_usage = 150 //actuators and stuff

	// Vending-related
	var/active = 1 //No sales pitches if off!
	var/vend_ready = 1 //Are we ready to vend?? Is it time??
	var/vend_delay = 10 //How long does it take to vend?
	var/creation_charges = 10
	var/categories = CAT_NORMAL | CAT_SPECIAL
	var/status_message = ""
	var/status_error = 0 // Set to 1 if status_message is an error

	/*
		Variables used to initialize the product list
		These are used for initialization only, and so are optional if
		product_records is specified
	*/
	var/list/products	= list()
	var/list/contraband	= list()
	var/list/premium 	= list()

	// List of vending_product items available.
	var/list/product_records = list()


	// Variables used to initialize advertising
	var/product_slogans = "" //String of slogans spoken out loud, separated by semicolons
	var/product_ads = "" //String of small ad messages in the vending screen

	var/list/ads_list = list()

	// Stuff relating vocalizations
	var/list/slogan_list = list()
	var/shut_up = 1 //Stop spouting those godawful pitches!
	var/vend_reply //Thank you for shopping!
	var/last_reply = 0
	var/last_slogan = 0 //When did we last pitch?
	var/slogan_delay = 6000 //How long until we can pitch again?

	// Things that can go wrong
	emagged = 0 //Ignores if somebody doesn't have card access to that machine.
	var/seconds_electrified = 0 //Shock customers like an airlock.
	var/shoot_inventory = 0 //Fire items at customers! We're broken!

	var/scan_id = 1
	var/datum/wires/vending/wires = null

/obj/machinery/vending/Initialize()
	. = ..()
	wires = new(src)
	spawn(4)
		if(src.product_slogans)
			src.slogan_list += splittext(src.product_slogans, ";")

			// So not all machines speak at the exact same time.
			// The first time this machine says something will be at slogantime + this random value,
			// so if slogantime is 10 minutes, it will say it at somewhere between 10 and 20 minutes after the machine is crated.
			src.last_slogan = world.time + rand(0, slogan_delay)

		if(src.product_ads)
			src.ads_list += splittext(src.product_ads, ";")

		src.build_inventory()
		power_change()

		return

	return

/**
 *  Build src.produdct_records from the products lists
 *
 *  src.products, src.contraband, and src.premium allow specifying
 *  products that the vending machine is to carry without manually populating
 *  src.product_records.
 */
/obj/machinery/vending/proc/build_inventory()
	var/list/all_products = list(
		list(src.products, CAT_NORMAL),
		list(src.contraband, CAT_HIDDEN),
		list(src.premium, CAT_SPECIAL))

	for(var/current_list in all_products)
		var/category = current_list[2]

		for(var/entry in current_list[1])
			var/datum/stored_items/vending_products/product = new/datum/stored_items/vending_products(src, entry)

			product.charge_cost = creation_cost(entry)
			product.category = category

			src.product_records.Add(product)

/obj/machinery/vending/Destroy()
	qdel(wires)
	wires = null
	for(var/datum/stored_items/vending_products/R in product_records)
		qdel(R)
	product_records = null
	return ..()

/obj/machinery/vending/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return
		if(3.0)
			if (prob(25))
				spawn(0)
					src.malfunction()
					return
				return
		else
	return

/obj/machinery/vending/emag_act(var/remaining_charges, var/mob/user)
	if (!emagged)
		src.emagged = 1
		to_chat(user, "You short out the product lock on \the [src]")
		return 1

/obj/machinery/vending/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/vending_charge))
		refill_from_charge(W, user)
		return

	if (W.GetIdCard())
		attack_hand(user)
		return
	else if(istype(W, /obj/item/screwdriver))
		src.panel_open = !src.panel_open
		to_chat(user, "You [src.panel_open ? "open" : "close"] the maintenance panel.")
		src.overlays.Cut()
		if(src.panel_open)
			src.overlays += image(src.icon, "[initial(icon_state)]-panel")

		SSnano.update_uis(src)  // Speaker switch is on the main UI, not wires UI
		return
	else if(isMultitool(W) || isWirecutter(W))
		if(src.panel_open)
			attack_hand(user)
		return
	else if((obj_flags & OBJ_FLAG_ANCHORABLE) && isWrench(W))
		wrench_floor_bolts(user)
		power_change()
		return
	..()
	return

/obj/machinery/vending/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/vending/attack_hand(mob/user as mob)
	if(stat & (BROKEN|NOPOWER))
		return

	if(src.seconds_electrified != 0)
		if(src.shock(user, 100))
			return

	wires.Interact(user)
	ui_interact(user)

/**
 *  Display the NanoUI window for the vending machine.
 *
 *  See NanoUI documentation for details.
 */
/obj/machinery/vending/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	user.set_machine(src)

	var/list/data = list()
	data["charges"] = creation_charges
	data["ready"] = vend_ready
	data["message"] = status_message
	data["message_err"] = status_error
	var/list/listed_products = list()
	for(var/key = 1 to product_records.len)
		var/datum/stored_items/vending_products/product = product_records[key]
		if(!(product.category & categories))
			continue
		listed_products.Add(list(list(
			"key" = key,
			"name" = product.item_name,
			"cost" = product.charge_cost,
			"color" = product.display_color)))
	data["products"] = listed_products

	if(src.panel_open)
		data["panel"] = 1
		data["speaker"] = src.shut_up ? 0 : 1
	else
		data["panel"] = 0

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "vending_machine.tmpl", src.name, 440, 600)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/vending/Topic(href, href_list)
	if(stat & (BROKEN|NOPOWER))
		return
	if(..())
		return

	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))))
		if (href_list["vend"] && vend_ready)
			if((!allowed(usr)) && !emagged && scan_id)	//For SECURE VENDING MACHINES YEAH
				to_chat(usr, "<span class='warning'>Access denied.</span>")//Unless emagged of course
				flick(icon_deny,src)
				return

			var/key = text2num(href_list["vend"])
			if(!isnum(key) || key != round(key) || key < 1 || key > product_records.len)
				return
			var/datum/stored_items/vending_products/R = product_records[key]

			// This should not happen unless the request from NanoUI was bad
			if(!(R.category & src.categories))
				return

			vend(R, usr)

		else if ((href_list["togglevoice"]) && (src.panel_open))
			src.shut_up = !src.shut_up

		SSnano.update_uis(src)

/obj/machinery/vending/proc/creation_cost(product_path)
	return creation_charge_cost(product_path)

/proc/creation_charge_cost(product_path)
	if(ispath(product_path, /obj/item/weapon/handcuffs))
		return 1
	if(ispath(product_path, /obj/item/clothing/suit))
		return 5
	if(ispath(product_path, /obj/item/weapon/gun))
		return 4
	if(ispath(product_path, /obj/item/storage/box) || ispath(product_path, /obj/item/device/pda))
		return 3
	if(ispath(product_path, /obj/item/device) || ispath(product_path, /obj/item/weapon/grenade) || ispath(product_path, /obj/item/reagent_containers/hypospray))
		return 2
	return 1

/obj/machinery/vending/proc/vend(var/datum/stored_items/vending_products/R, mob/user)
	if(!vend_ready || (stat & (BROKEN|NOPOWER)) || !(R in product_records) || !(R.category & categories))
		return
	if(!allowed(user) && !emagged && scan_id)
		to_chat(user, "<span class='warning'>Access denied.</span>")
		flick(src.icon_deny,src)
		return
	if(creation_charges < R.charge_cost)
		status_message = "Insufficient creation charges."
		status_error = 1
		SSnano.update_uis(src)
		return
	creation_charges -= R.charge_cost
	src.vend_ready = 0 //One thing at a time!!
	src.status_message = "Vending..."
	src.status_error = 0
	SSnano.update_uis(src)

	if(((src.last_reply + (src.vend_delay + 200)) <= world.time) && src.vend_reply)
		spawn(0)
			src.speak(src.vend_reply)
			src.last_reply = world.time

	use_power_oneoff(vend_power_usage)	//actuators and stuff
	if (src.icon_vend) //Show the vending animation if needed
		flick(src.icon_vend,src)
	new R.item_path(get_turf(src))
	visible_message("\The [src] whirs as it creates \the [R.item_name].")
	spawn(vend_delay)
		if(QDELETED(src))
			return
		src.status_message = ""
		src.status_error = 0
		src.vend_ready = 1
		SSnano.update_uis(src)

/obj/machinery/vending/Process()
	if(stat & (BROKEN|NOPOWER))
		return

	if(!src.active)
		return

	if(src.seconds_electrified > 0)
		src.seconds_electrified--

	//Pitch to the people!  Really sell it!
	if(((src.last_slogan + src.slogan_delay) <= world.time) && (src.slogan_list.len > 0) && (!src.shut_up) && prob(5))
		var/slogan = pick(src.slogan_list)
		src.speak(slogan)
		src.last_slogan = world.time

	if(src.shoot_inventory && prob(2))
		src.throw_item()

	return

/obj/machinery/vending/proc/speak(var/message)
	if(stat & NOPOWER)
		return

	if (!message)
		return

	for(var/mob/O in hearers(src, null))
		O.show_message("<span class='game say'><span class='name'>\The [src]</span> beeps, \"[message]\"</span>",2)
	runechat_to_hearers(message)
	return

/obj/machinery/vending/powered()
	return anchored && ..()

/obj/machinery/vending/update_icon()
	if(stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
	else if( !(stat & NOPOWER) )
		icon_state = initial(icon_state)
	else
		spawn(rand(0, 15))
			src.icon_state = "[initial(icon_state)]-off"

//Oh no we're malfunctioning!  Dump out some product and break.
/obj/machinery/vending/proc/malfunction()
	for(var/datum/stored_items/vending_products/R in src.product_records)
		while(creation_charges >= R.charge_cost)
			creation_charges -= R.charge_cost
			new R.item_path(get_turf(src))
		break
	set_broken(TRUE)

//Somebody cut an important wire and now we're following a new definition of "pitch."
/obj/machinery/vending/proc/throw_item()
	var/obj/throw_item = null
	var/mob/living/target = locate() in view(7,src)
	if(!target)
		return 0

	for(var/datum/stored_items/vending_products/R in src.product_records)
		if(creation_charges < R.charge_cost)
			continue
		creation_charges -= R.charge_cost
		throw_item = new R.item_path(get_turf(src))
		if (throw_item)
			break
	if (!throw_item)
		return 0
	spawn(0)
		throw_item.throw_at(target, rand(1,2), 3, src)
	src.visible_message("<span class='warning'>\The [src] launches \a [throw_item] at \the [target]!</span>")
	return 1

/*
 * Vending machine types
 */

/*

/obj/machinery/vending/[vendors name here]   // --vending machine template   :)
	name = ""
	desc = ""
	icon = ''
	icon_state = ""
	vend_delay = 15
	products = list()
	contraband = list()
	premium = list()

*/

/obj/machinery/vending/boozeomat
	name = "Booze-O-Mat"
	desc = "A refrigerated vending unit for alcoholic beverages and alcoholic beverage accessories."
	icon_state = "boozeomat"
	icon_deny = "boozeomat-deny"
	products = list(/obj/item/reagent_containers/food/drinks/bottle/gin,
					/obj/item/reagent_containers/food/drinks/bottle/whiskey,
					/obj/item/reagent_containers/food/drinks/bottle/tequilla,
					/obj/item/reagent_containers/food/drinks/bottle/vodka,
					/obj/item/reagent_containers/food/drinks/bottle/vermouth,
					/obj/item/reagent_containers/food/drinks/bottle/rum,
					/obj/item/reagent_containers/food/drinks/bottle/wine,
					/obj/item/reagent_containers/food/drinks/bottle/cognac,
					/obj/item/reagent_containers/food/drinks/bottle/kahlua,
					/obj/item/reagent_containers/food/drinks/bottle/small/beer,
					/obj/item/reagent_containers/food/drinks/bottle/small/ale,
					/obj/item/reagent_containers/food/drinks/bottle/orangejuice,
					/obj/item/reagent_containers/food/drinks/bottle/tomatojuice,
					/obj/item/reagent_containers/food/drinks/bottle/limejuice,
					/obj/item/reagent_containers/food/drinks/bottle/cream,
					/obj/item/reagent_containers/food/drinks/cans/tonic,
					/obj/item/reagent_containers/food/drinks/bottle/cola,
					/obj/item/reagent_containers/food/drinks/bottle/space_up,
					/obj/item/reagent_containers/food/drinks/bottle/space_mountain_wind,
					/obj/item/reagent_containers/food/drinks/cans/sodawater,
					/obj/item/reagent_containers/food/drinks/flask/barflask,
					/obj/item/reagent_containers/food/drinks/flask/vacuumflask,
					/obj/item/reagent_containers/food/drinks/coffeecup/metal,
					/obj/item/reagent_containers/food/drinks/glass2/square,
					/obj/item/reagent_containers/food/drinks/glass2/rocks,
					/obj/item/reagent_containers/food/drinks/glass2/shake,
					/obj/item/reagent_containers/food/drinks/glass2/cocktail,
					/obj/item/reagent_containers/food/drinks/glass2/shot,
					/obj/item/reagent_containers/food/drinks/glass2/pint,
					/obj/item/reagent_containers/food/drinks/glass2/mug,
					/obj/item/reagent_containers/food/drinks/glass2/wine,
					/obj/item/reagent_containers/food/drinks/ice,
					/obj/item/reagent_containers/food/drinks/bottle/melonliquor,
					/obj/item/reagent_containers/food/drinks/bottle/bluecuracao,
					/obj/item/reagent_containers/food/drinks/bottle/absinthe,
					/obj/item/reagent_containers/food/drinks/bottle/grenadine,
					/obj/item/reagent_containers/food/drinks/bottle/specialwhiskey,
					/obj/item/reagent_containers/food/drinks/bottle/herbal,
					/obj/item/reagent_containers/food/drinks/tea,
					/obj/item/weapon/glass_extra/stick,
					/obj/item/weapon/glass_extra/straw)
	contraband = list(/obj/item/reagent_containers/food/drinks/bottle/premiumwine,
					/obj/item/reagent_containers/food/drinks/bottle/premiumvodka)
	vend_delay = 15
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.
	product_slogans = "I hope nobody asks me for a bloody cup o' tea...;Alcohol is humanity's friend. Would you abandon a friend?;Quite delighted to serve you!;Is nobody thirsty on this station?"
	product_ads = "Drink up!;Booze is good for you!;Alcohol is humanity's best friend.;Quite delighted to serve you!;Care for a nice, cold beer?;Nothing cures you like booze!;Have a sip!;Have a drink!;Have a beer!;Beer is good for you!;Only the finest alcohol!;Best quality booze since 2053!;Award-winning wine!;Maximum alcohol!;Man loves beer.;A toast for progress!"
	req_access = list(access_bar)

/obj/machinery/vending/assist
	products = list(	/obj/item/device/assembly/prox_sensor,/obj/item/device/assembly/igniter,/obj/item/device/assembly/signaler,
						/obj/item/wirecutters, /obj/item/cartridge/signal)
	contraband = list(/obj/item/device/flashlight,/obj/item/device/assembly/timer)
	product_ads = "Only the finest!;Have some tools.;The most robust equipment.;The finest gear in space!"

/obj/machinery/vending/assist/antag
	name = "AntagCorpVend"
	contraband = list()
	products = list(	/obj/item/device/assembly/prox_sensor, /obj/item/device/assembly/signaler,
						/obj/item/device/assembly/infra, /obj/item/device/assembly/prox_sensor,
						/obj/item/weapon/handcuffs, /obj/item/device/flash,
						/obj/item/cartridge/signal, /obj/item/clothing/glasses/sunglasses)

/obj/machinery/vending/coffee
	name = "Hot Drinks machine"
	desc = "A vending machine which dispenses hot drinks."
	product_ads = "Have a drink!;Drink up!;It's good for you!;Would you like a hot joe?;I'd kill for some coffee!;The best beans in the galaxy.;Only the finest brew for you.;Mmmm. Nothing like a coffee.;I like coffee, don't you?;Coffee helps you work!;Try some tea.;We hope you like the best!;Try our new chocolate!;Admin conspiracies"
	icon_state = "coffee"
	icon_vend = "coffee-vend"
	vend_delay = 34
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.
	vend_power_usage = 85000 //85 kJ to heat a 250 mL cup of coffee
	products = list(/obj/item/reagent_containers/food/drinks/coffee,/obj/item/reagent_containers/food/drinks/tea,/obj/item/reagent_containers/food/drinks/h_chocolate)
	contraband = list(/obj/item/reagent_containers/food/drinks/ice)




/obj/machinery/vending/snack
	name = "Getmore Chocolate Corp"
	desc = "A snack machine courtesy of the Getmore Chocolate Corporation, based out of Mars."
	product_slogans = "Try our new nougat bar!;Twice the calories for half the price!"
	product_ads = "The healthiest!;Award-winning chocolate bars!;Mmm! So good!;Oh my god it's so juicy!;Have a snack.;Snacks are good for you!;Have some more Getmore!;Best quality snacks straight from mars.;We love chocolate!;Try our new jerky!"
	icon_state = "snack"
	icon_vend = "snack-vend"
	vend_delay = 25
	products = list(/obj/item/reagent_containers/food/snacks/candy,/obj/item/reagent_containers/food/drinks/dry_ramen,/obj/item/reagent_containers/food/snacks/chips,
					/obj/item/reagent_containers/food/snacks/sosjerky,/obj/item/reagent_containers/food/snacks/no_raisin,/obj/item/reagent_containers/food/snacks/spacetwinkie,
					/obj/item/reagent_containers/food/snacks/cheesiehonkers, /obj/item/reagent_containers/food/snacks/tastybread)
	contraband = list(/obj/item/reagent_containers/food/snacks/syndicake)



/obj/machinery/vending/cola
	name = "Robust Softdrinks"
	desc = "A softdrink vendor provided by Robust Industries, LLC."
	icon_state = "Cola_Machine"
	icon_vend = "Cola_Machine-vend"
	vend_delay = 11
	product_slogans = "Robust Softdrinks: More robust than a toolbox to the head!"
	product_ads = "Refreshing!;Hope you're thirsty!;Over 1 million drinks sold!;Thirsty? Why not cola?;Please, have a drink!;Drink up!;The best drinks in space."
	products = list(/obj/item/reagent_containers/food/drinks/cans/cola,/obj/item/reagent_containers/food/drinks/cans/space_mountain_wind,
					/obj/item/reagent_containers/food/drinks/cans/dr_gibb,/obj/item/reagent_containers/food/drinks/cans/starkist,
					/obj/item/reagent_containers/food/drinks/cans/waterbottle,/obj/item/reagent_containers/food/drinks/cans/space_up,
					/obj/item/reagent_containers/food/drinks/cans/iced_tea, /obj/item/reagent_containers/food/drinks/cans/grape_juice)
	contraband = list(/obj/item/reagent_containers/food/drinks/cans/thirteenloko, /obj/item/reagent_containers/food/snacks/liquidfood)
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.

/obj/machinery/vending/fitness
	name = "SweatMAX"
	desc = "An exercise aid and nutrition supplement vendor that preys on your inadequacy."
	product_slogans = "SweatMAX, get robust!"
	product_ads = "Pain is just weakness leaving the body!;Run! Your fat is catching up to you;Never forget leg day!;Push out!;This is the only break you get today.;Don't cry, sweat!;Healthy is an outfit that looks good on everybody."
	icon_state = "fitness"
	icon_vend = "fitness-vend"
	vend_delay = 6
	products = list(/obj/item/reagent_containers/food/drinks/milk/smallcarton,
					/obj/item/reagent_containers/food/drinks/milk/smallcarton/chocolate,
					/obj/item/reagent_containers/food/drinks/glass2/fitnessflask/proteinshake,
					/obj/item/reagent_containers/food/drinks/glass2/fitnessflask,
					/obj/item/reagent_containers/food/snacks/candy/proteinbar,
					/obj/item/reagent_containers/food/snacks/liquidfood,
					/obj/item/reagent_containers/pill/diet,
					/obj/item/towel/random)


	contraband = list(/obj/item/reagent_containers/syringe/steroid)

//This one's from bay12
/obj/machinery/vending/cart
	name = "PTech"
	desc = "Cartridges for PDAs."
	product_slogans = "Carts to go!"
	icon_state = "cart"
	icon_deny = "cart-deny"
	icon_vend = "cart-vend"
	vend_delay = 23
	products = list(/obj/item/cartridge/medical,/obj/item/cartridge/engineering,/obj/item/cartridge/security,
					/obj/item/cartridge/janitor,/obj/item/cartridge/signal/science,/obj/item/device/pda/heads,
					/obj/item/cartridge/captain,/obj/item/cartridge/quartermaster)


/obj/machinery/vending/cigarette
	name = "Cigarette machine" //OCD had to be uppercase to look nice with the new formating
	desc = "A specialized vending machine designed to contribute to your slow and uncomfortable death."
	product_slogans = "There's no better time to start smokin'.;\
		Smoke now, and win the adoration of your peers.;\
		They beat cancer centuries ago, so smoke away.;\
		If you're not smoking, you must be joking."
	product_ads = "Probably not bad for you!;\
		Don't believe the scientists!;\
		It's good for you!;\
		Don't quit, buy more!;\
		Smoke!;\
		Nicotine heaven.;\
		Best cigarettes since 2150.;\
		Award-winning cigarettes, all the best brands.;\
		Feeling temperamental? Try a Temperamento!;\
		Carcinoma Angels - go fuck yerself!;\
		Don't be so hard on yourself, kid. Smoke a Lucky Star!;\
		We understand the depressed, alcoholic cowboy in you. That's why we also smoke Jericho.;\
		Professionals. Better cigarettes for better people. Yes, better people."
	vend_delay = 21
	icon_state = "cigs"
	icon_vend = "cigs-vend"
	products = list(/obj/item/storage/fancy/cigarettes,
					/obj/item/storage/fancy/cigarettes/luckystars,
					/obj/item/storage/fancy/cigarettes/jerichos,
					/obj/item/storage/fancy/cigarettes/menthols,
					/obj/item/storage/fancy/cigarettes/carcinomas,
					/obj/item/storage/fancy/cigarettes/professionals,
					/obj/item/storage/fancy/cigarettes/cigarello,
					/obj/item/storage/fancy/cigarettes/cigarello/mint,
					/obj/item/storage/fancy/cigarettes/cigarello/variety,
					/obj/item/storage/box/matches,
					/obj/item/weapon/flame/lighter/random,
					/obj/item/clothing/mask/smokable/ecig/simple,
					/obj/item/clothing/mask/smokable/ecig/util,
					/obj/item/clothing/mask/smokable/ecig/deluxe,
					/obj/item/reagent_containers/ecig_cartridge/med_nicotine,
					/obj/item/reagent_containers/ecig_cartridge/high_nicotine,
					/obj/item/reagent_containers/ecig_cartridge/orange,
					/obj/item/reagent_containers/ecig_cartridge/mint,
					/obj/item/reagent_containers/ecig_cartridge/watermelon,
					/obj/item/reagent_containers/ecig_cartridge/grape,
					/obj/item/reagent_containers/ecig_cartridge/lemonlime,
					/obj/item/reagent_containers/ecig_cartridge/coffee,
					/obj/item/reagent_containers/ecig_cartridge/blanknico)
	contraband = list(/obj/item/weapon/flame/lighter/zippo)
	premium = list(/obj/item/storage/fancy/cigar,/obj/item/storage/fancy/cigarettes/killthroat)



/obj/machinery/vending/medical
	name = "TetraMed Plus"
	desc = "Medical drug dispenser, with limited supply."
	icon_state = "med"
	icon_deny = "med-deny"
	icon_vend = "med-vend"
	vend_delay = 18
	product_ads = "Go save some lives!;The best stuff for your medbay.;Only the finest tools.;Natural chemicals!;This stuff saves lives.;Don't you want some?;Ping!"
	req_access = list(access_medical_equip)
	products = list(/obj/item/reagent_containers/glass/bottle/antitoxin,/obj/item/reagent_containers/glass/bottle/inaprovaline,
					/obj/item/reagent_containers/glass/bottle/stoxin,/obj/item/reagent_containers/glass/bottle/toxin,
					/obj/item/reagent_containers/syringe/antiviral,/obj/item/reagent_containers/syringe,
					/obj/item/device/healthanalyzer,/obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/dropper,
					/obj/item/stack/medical/advanced/bruise_pack, /obj/item/stack/medical/advanced/ointment, /obj/item/stack/medical/splint,
					/obj/item/reagent_containers/hypospray/autoinjector/pain)
	contraband = list(/obj/item/reagent_containers/pill/tox,/obj/item/reagent_containers/pill/stox,/obj/item/reagent_containers/pill/antitox,
					/obj/item/reagent_containers/hypospray/autoinjector/combatpain)
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.


//This one's from bay12
/obj/machinery/vending/phoronresearch
	name = "Toximate 3000"
	desc = "All the fine parts you need in one vending machine!"
	products = list(/obj/item/clothing/suit/bio_suit,/obj/item/clothing/head/bio_hood,
					/obj/item/device/transfer_valve,/obj/item/device/assembly/timer,/obj/item/device/assembly/signaler,
					/obj/item/device/assembly/prox_sensor,/obj/item/device/assembly/igniter)

/obj/machinery/vending/wallmed1
	name = "TetraMed Wall Edition"
	desc = "A wall-mounted version of the TetraMed."
	product_ads = "Go save some lives!;The best stuff for your medbay.;Only the finest tools.;Natural chemicals!;This stuff saves lives.;Don't you want some?"
	icon_state = "wallmed"
	icon_deny = "wallmed-deny"
	density = 0 //It is wall-mounted, and thus, not dense. --Superxpdude
	products = list(/obj/item/stack/medical/bruise_pack,/obj/item/stack/medical/ointment,/obj/item/reagent_containers/hypospray/autoinjector)
	contraband = list(/obj/item/reagent_containers/syringe/antitoxin,/obj/item/reagent_containers/syringe/antiviral,/obj/item/reagent_containers/pill/tox)

/obj/machinery/vending/wallmed2
	name = "TetraMed Mini"
	desc = "A wall-mounted version of the TetraMed, containing only vital first aid equipment."
	product_ads = "Go save some lives!;The best stuff for your medbay.;Only the finest tools.;Natural chemicals!;This stuff saves lives.;Don't you want some?"
	icon_state = "wallmed"
	icon_deny = "wallmed-deny"
	density = 0 //It is wall-mounted, and thus, not dense. --Superxpdude
	products = list(/obj/item/reagent_containers/hypospray/autoinjector,/obj/item/reagent_containers/syringe/antitoxin,/obj/item/stack/medical/bruise_pack,
					/obj/item/stack/medical/ointment)
	contraband = list(/obj/item/reagent_containers/pill/tox, /obj/item/reagent_containers/hypospray/autoinjector/pain)

/obj/machinery/vending/security
	name = "SecTech"
	desc = "A security equipment vendor."
	product_ads = "Crack capitalist skulls!;Beat some heads in!;Don't forget - harm is good!;Your weapons are right here.;Handcuffs!;Freeze, scumbag!;Don't tase me bro!;Tase them, bro.;Why not have a donut?"
	icon_state = "sec"
	icon_deny = "sec-deny"
	icon_vend = "sec-vend"
	vend_delay = 14
	req_access = list(access_security)
	products = list(/obj/item/weapon/handcuffs,/obj/item/weapon/grenade/flashbang,/obj/item/weapon/grenade/chem_grenade/teargas,/obj/item/device/flash,
					/obj/item/reagent_containers/food/snacks/donut/normal,/obj/item/storage/box/evidence)
	contraband = list(/obj/item/clothing/glasses/sunglasses,/obj/item/storage/box/donut)

/obj/machinery/vending/hydronutrients
	name = "NutriMax"
	desc = "A plant nutrients vendor."
	product_slogans = "Aren't you glad you don't have to fertilize the natural way?;Now with 50% less stink!;Plants are people too!"
	product_ads = "We like plants!;Don't you want some?;The greenest thumbs ever.;We like big plants.;Soft soil..."
	icon_state = "nutri"
	icon_deny = "nutri-deny"
	icon_vend = "nutri-vend"
	vend_delay = 26
	products = list(/obj/item/reagent_containers/glass/bottle/eznutrient,/obj/item/reagent_containers/glass/bottle/left4zed,/obj/item/reagent_containers/glass/bottle/robustharvest,/obj/item/plantspray/pests,
					/obj/item/reagent_containers/syringe,/obj/item/storage/plants)
	premium = list(/obj/item/reagent_containers/glass/bottle/ammonia,/obj/item/reagent_containers/glass/bottle/diethylamine)
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.

/obj/machinery/vending/hydroseeds
	name = "MegaSeed Servitor"
	desc = "When you need seeds fast!"
	product_slogans = "THIS'S WHERE TH' SEEDS LIVE! GIT YOU SOME!;Hands down the best seed selection this half of the galaxy!;Also certain mushroom varieties available, more for experts! Get certified today!"
	product_ads = "We like plants!;Grow some crops!;Grow, baby, growww!;Aw h'yeah son!"
	icon_state = "seeds"
	icon_vend = "seeds-vend"
	vend_delay = 13
	products = list(/obj/item/seeds/bananaseed,/obj/item/seeds/berryseed,/obj/item/seeds/carrotseed,/obj/item/seeds/chantermycelium,/obj/item/seeds/chiliseed,
					/obj/item/seeds/cornseed, /obj/item/seeds/eggplantseed, /obj/item/seeds/potatoseed, /obj/item/seeds/replicapod,/obj/item/seeds/soyaseed,
					/obj/item/seeds/sunflowerseed,/obj/item/seeds/tomatoseed,/obj/item/seeds/towermycelium,/obj/item/seeds/wheatseed,/obj/item/seeds/appleseed,
					/obj/item/seeds/poppyseed,/obj/item/seeds/sugarcaneseed,/obj/item/seeds/ambrosiavulgarisseed,/obj/item/seeds/peanutseed,/obj/item/seeds/whitebeetseed,/obj/item/seeds/watermelonseed,/obj/item/seeds/limeseed,
					/obj/item/seeds/lemonseed,/obj/item/seeds/orangeseed,/obj/item/seeds/grassseed,/obj/item/seeds/cocoapodseed,/obj/item/seeds/plumpmycelium,
					/obj/item/seeds/cabbageseed,/obj/item/seeds/grapeseed,/obj/item/seeds/pumpkinseed,/obj/item/seeds/cherryseed,/obj/item/seeds/plastiseed,/obj/item/seeds/riceseed,/obj/item/seeds/lavenderseed)
	contraband = list(/obj/item/seeds/amanitamycelium,/obj/item/seeds/glowshroom,/obj/item/seeds/libertymycelium,/obj/item/seeds/mtearseed,
					  /obj/item/seeds/nettleseed,/obj/item/seeds/reishimycelium,/obj/item/seeds/reishimycelium,/obj/item/seeds/shandseed,)

/**
 *  Populate hydroseeds product_records
 *
 *  This needs to be customized to fetch the actual names of the seeds, otherwise
 *  the machine would simply list "packet of seeds" times 20
 */
/obj/machinery/vending/hydroseeds/build_inventory()
	var/list/all_products = list(
		list(src.products, CAT_NORMAL),
		list(src.contraband, CAT_HIDDEN),
		list(src.premium, CAT_SPECIAL))

	for(var/current_list in all_products)
		var/category = current_list[2]

		for(var/entry in current_list[1])
			var/obj/item/seeds/S = new entry(src)
			var/name = S.seed_type
			var/datum/stored_items/vending_products/product = new/datum/stored_items/vending_products(src, entry, name)

			product.charge_cost = creation_cost(entry)
			product.category = category

			src.product_records.Add(product)
			qdel(S)

/obj/machinery/vending/magivend
	name = "MagiVend"
	desc = "A magic vending machine."
	icon_state = "MagiVend"
	product_slogans = "Sling spells the proper way with MagiVend!;Be your own Houdini! Use MagiVend!"
	vend_delay = 15
	vend_reply = "Have an enchanted evening!"
	product_ads = "FJKLFJSD;AJKFLBJAKL;1234 LOONIES LOL!;>MFW;Kill them fuckers!;GET DAT FUKKEN DISK;HONK!;EI NATH;Down with Central!;Admin conspiracies since forever!;Space-time bending hardware!"
	products = list(/obj/item/clothing/head/wizard,/obj/item/clothing/suit/wizrobe,/obj/item/clothing/head/wizard/red,/obj/item/clothing/suit/wizrobe/red,/obj/item/clothing/shoes/sandal,/obj/item/weapon/staff)

/obj/machinery/vending/dinnerware
	name = "Dinnerware"
	desc = "A kitchen and restaurant equipment vendor."
	product_ads = "Mm, food stuffs!;Food and food accessories.;Get your plates!;You like forks?;I like forks.;Woo, utensils.;You don't really need these..."
	icon_state = "dinnerware"
	icon_vend = "dinnerware-vend"
	products = list(
	/obj/item/weapon/tray,
	/obj/item/weapon/material/kitchen/utensil/fork,
	/obj/item/weapon/material/kitchen/utensil/knife,
	/obj/item/weapon/material/kitchen/utensil/spoon,
	/obj/item/weapon/material/knife,
	/obj/item/weapon/material/kitchen/rollingpin,
	/obj/item/serving_bowl,
	/obj/item/reagent_containers/food/drinks/pitcher,
	/obj/item/reagent_containers/food/drinks/coffeecup,
	/obj/item/reagent_containers/food/drinks/glass2/carafe,
	/obj/item/reagent_containers/food/drinks/glass2/square,
	/obj/item/clothing/suit/chef/classic)


	contraband = list(/obj/item/weapon/material/knife/butch)

/obj/machinery/vending/sovietsoda
	name = "BODA"
	desc = "An old soda vending machine. How could this have got here?"
	icon_state = "sovietsoda"
	icon_vend = "sovietsoda-vend"
	product_ads = "For Tsar and Country.;Have you fulfilled your nutrition quota today?;Very nice!;We are simple people, for this is all we eat.;If there is a person, there is a problem. If there is no person, then there is no problem."
	products = list(/obj/item/reagent_containers/food/drinks/bottle/space_up) // TODO Russian soda can
	contraband = list(/obj/item/reagent_containers/food/drinks/bottle/cola) // TODO Russian cola can
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.

/obj/machinery/vending/tool
	name = "YouTool"
	desc = "Tools for tools."
	icon_state = "tool"
	icon_deny = "tool-deny"
	icon_vend = "tool-vend"
	vend_delay = 11
	//req_access = list(access_maint_tunnels) //Maintenance access
	products = list(/obj/item/stack/cable_coil/random,/obj/item/crowbar,/obj/item/weldingtool,/obj/item/wirecutters,
					/obj/item/wrench,/obj/item/device/analyzer,/obj/item/device/t_scanner,/obj/item/screwdriver,
					/obj/item/device/flashlight/glowstick, /obj/item/device/flashlight/glowstick/red)
	contraband = list(/obj/item/weldingtool/hugetank)
	premium = list(/obj/item/clothing/gloves/insulated)

/obj/machinery/vending/engivend
	name = "Engi-Vend"
	desc = "Spare tool vending. What? Did you expect some witty description?"
	icon_state = "engivend"
	icon_deny = "engivend-deny"
	icon_vend = "engivend-vend"
	vend_delay = 21
	req_one_access = list(access_atmospherics,access_engine_equip)
	products = list(/obj/item/clothing/glasses/meson,/obj/item/device/multitool,/obj/item/device/geiger,/obj/item/airlock_electronics,/obj/item/weapon/module/power_control,/obj/item/airalarm_electronics,/obj/item/cell,/obj/item/clamp)
	contraband = list(/obj/item/cell/high)
	premium = list(/obj/item/storage/belt/utility)

//This one's from bay12
/obj/machinery/vending/engineering
	name = "Robco Tool Maker"
	desc = "Everything you need for do-it-yourself repair."
	icon_state = "engi"
	icon_deny = "engi-deny"
	req_one_access = list(access_atmospherics,access_engine_equip)
	products = list(/obj/item/storage/belt/utility,/obj/item/clothing/glasses/meson,/obj/item/clothing/gloves/insulated, /obj/item/screwdriver,
					/obj/item/crowbar,/obj/item/wirecutters,/obj/item/device/multitool,/obj/item/wrench,/obj/item/device/t_scanner,
					/obj/item/cell, /obj/item/weldingtool,/obj/item/clothing/head/welding,
					/obj/item/light/tube,/obj/item/stock_parts/scanning_module,/obj/item/stock_parts/micro_laser,
					/obj/item/stock_parts/matter_bin,/obj/item/stock_parts/manipulator,/obj/item/stock_parts/console_screen,
					/obj/item/stock_parts/capacitor)
	contraband = list(/obj/item/rcd, /obj/item/rcd_ammo)
	// There was an incorrect entry (cablecoil/power).  I improvised to cablecoil/heavyduty.
	// Another invalid entry, /obj/item/weapon/circuitry.  I don't even know what that would translate to, removed it.
	// The original products list wasn't finished.  The ones without given quantities became quantity 5.  -Sayu

//This one's from bay12
/obj/machinery/vending/robotics
	name = "Robotech Deluxe"
	desc = "All the tools you need to create your own robot army."
	icon_state = "robotics"
	icon_deny = "robotics-deny"
	req_access = list(access_robotics)
	products = list(/obj/item/stack/cable_coil,/obj/item/device/flash/synthetic,/obj/item/cell,/obj/item/device/healthanalyzer,
					/obj/item/weapon/surgery_tool/scalpel,/obj/item/weapon/surgery_tool/circular_saw,/obj/item/tank/anesthetic,/obj/item/clothing/mask/breath/medical,
					/obj/item/screwdriver,/obj/item/crowbar)
	contraband = list(/obj/item/device/flash)

//FOR ACTORS GUILD - mainly props that cannot be spawned otherwise
/obj/machinery/vending/props
	name = "prop dispenser"
	desc = "All the props an actor could need. Probably."
	icon_state = "Theater"
	products = list(/obj/structure/flora/pottedplant, /obj/item/device/flashlight/lamp, /obj/item/device/flashlight/lamp/green, /obj/item/reagent_containers/food/drinks/jar,
					/obj/item/nullrod, /obj/item/toy/cultsword, /obj/item/toy/katana)

//FOR ACTORS GUILD - Containers
/obj/machinery/vending/containers
	name = "container dispenser"
	desc = "A container that dispenses containers."
	icon_state = "robotics"
	products = list(/obj/structure/closet/crate/freezer, /obj/structure/closet, /obj/structure/closet/crate)

/obj/machinery/vending/fashionvend
	name = "Smashing Fashions"
	desc = "For all your cheap knockoff needs."
	product_slogans = "Look smashing for your darling!;Be rich! Dress rich!"
	icon_state = "Theater"
	vend_delay = 15
	vend_reply = "Absolutely smashing!"
	product_ads = "Impress the love of your life!;Don't look poor, look rich!;100% authentic designers!;All sales are final!;Lowest prices guaranteed!"
	products = list(/obj/item/mirror,
					/obj/item/weapon/haircomb,
					/obj/item/clothing/glasses/sunglasses,
					/obj/item/lipstick,
					/obj/item/lipstick/black,
					/obj/item/lipstick/purple,
					/obj/item/lipstick/jade,
					/obj/item/storage/card_holder/poly)
	contraband = list(/obj/item/clothing/glasses/eyepatch, /obj/item/clothing/accessory/horrible)
	premium = list(/obj/item/clothing/mask/smokable/pipe)
// eliza's attempt at a new vending machine
/obj/machinery/vending/games
	name = "Good Clean Fun"
	desc = "Vends things that the CO and SEA are probably not going to appreciate you fiddling with instead of your job..."
	vend_delay = 15
	product_slogans = "Escape to a fantasy world!;Fuel your gambling addiction!;Ruin your friendships!"
	product_ads = "Elves and dwarves!;Totally not satanic!;Fun times forever!"
	icon_state = "games"
	products = list(/obj/item/toy/blink, /obj/item/toy/spinningtoy, /obj/item/weapon/deck/cards, /obj/item/weapon/deck/tarot, /obj/item/weapon/pack/cardemon, /obj/item/weapon/pack/spaceball, /obj/item/storage/pill_bottle/dice_nerd, /obj/item/storage/pill_bottle/dice, /obj/item/storage/box/checkers, /obj/item/storage/box/checkers/chess/red, /obj/item/storage/box/checkers/chess)
	premium = list(/obj/item/weapon/gun/projectile/revolver/capgun, /obj/item/ammo_magazine/caps)
	contraband = list(/obj/item/reagent_containers/spray/waterflower, /obj/item/storage/box/snappops)
