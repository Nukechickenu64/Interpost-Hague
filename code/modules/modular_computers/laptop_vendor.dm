// A vendor machine for modular computer portable devices - Laptops and Tablets

/obj/machinery/lapvend
	name = "computer vendor"
	desc = "A vending machine with a built-in microfabricator, capable of dispensing various NT-branded computers."
	icon = 'icons/obj/vending.dmi'
	icon_state = "robotics"
	layer = BELOW_OBJ_LAYER
	anchored = 1
	density = 1
	var/creation_charges = 10

	// The actual laptop/tablet
	var/obj/item/modular_computer/laptop/fabricated_laptop = null
	var/obj/item/modular_computer/tablet/fabricated_tablet = null

	// Utility vars
	var/state = 0
	var/devtype = 0 						// 0: None(unselected), 1: Laptop, 2: Tablet

	// Device loadout
	var/dev_cpu = 1							// 1: Default, 2: Upgraded
	var/dev_battery = 1						// 1: Default, 2: Upgraded, 3: Advanced
	var/dev_disk = 1						// 1: Default, 2: Upgraded, 3: Advanced
	var/dev_netcard = 0						// 0: None, 1: Basic, 2: Long-Range
	var/dev_tesla = 0						// 0: None, 1: Standard
	var/dev_nanoprint = 0					// 0: None, 1: Standard
	var/dev_card = 0						// 0: None, 1: Standard
	var/dev_aislot = 0						// 0: None, 1: Standard

// Removes all traces of old order and allows you to begin configuration from scratch.
/obj/machinery/lapvend/proc/reset_order()
	state = 0
	devtype = 0
	if(fabricated_laptop)
		qdel(fabricated_laptop)
		fabricated_laptop = null
	if(fabricated_tablet)
		qdel(fabricated_tablet)
		fabricated_tablet = null
	dev_cpu = 1
	dev_battery = 1
	dev_disk = 1
	dev_netcard = 0
	dev_tesla = 0
	dev_nanoprint = 0
	dev_card = 0
	dev_aislot = 0

/obj/machinery/lapvend/proc/fabricate_device(var/fabricate = 0)
	if(devtype == 1)
		if(fabricate)
			fabricated_laptop = new(src)
		switch(dev_cpu)
			if(1)
				if(fabricate)
					fabricated_laptop.processor_unit = new/obj/item/computer_hardware/processor_unit/small(fabricated_laptop)
			if(2)
				if(fabricate)
					fabricated_laptop.processor_unit = new/obj/item/computer_hardware/processor_unit(fabricated_laptop)
		switch(dev_battery)
			if(1) // Basic(750C)
				if(fabricate)
					fabricated_laptop.battery_module = new/obj/item/computer_hardware/battery_module(fabricated_laptop)
			if(2) // Upgraded(1100C)
				if(fabricate)
					fabricated_laptop.battery_module = new/obj/item/computer_hardware/battery_module/advanced(fabricated_laptop)
			if(3) // Advanced(1500C)
				if(fabricate)
					fabricated_laptop.battery_module = new/obj/item/computer_hardware/battery_module/super(fabricated_laptop)
		switch(dev_disk)
			if(1) // Basic(128GQ)
				if(fabricate)
					fabricated_laptop.hard_drive = new/obj/item/computer_hardware/hard_drive(fabricated_laptop)
			if(2) // Upgraded(256GQ)
				if(fabricate)
					fabricated_laptop.hard_drive = new/obj/item/computer_hardware/hard_drive/advanced(fabricated_laptop)
			if(3) // Advanced(512GQ)
				if(fabricate)
					fabricated_laptop.hard_drive = new/obj/item/computer_hardware/hard_drive/super(fabricated_laptop)
		switch(dev_netcard)
			if(1) // Basic(Short-Range)
				if(fabricate)
					fabricated_laptop.network_card = new/obj/item/computer_hardware/network_card(fabricated_laptop)
			if(2) // Advanced (Long Range)
				if(fabricate)
					fabricated_laptop.network_card = new/obj/item/computer_hardware/network_card/advanced(fabricated_laptop)
		if(dev_tesla)
			if(fabricate)
				fabricated_laptop.tesla_link = new/obj/item/computer_hardware/tesla_link(fabricated_laptop)
		if(dev_nanoprint)
			if(fabricate)
				fabricated_laptop.nano_printer = new/obj/item/computer_hardware/nano_printer(fabricated_laptop)
		if(dev_card)
			if(fabricate)
				fabricated_laptop.card_slot = new/obj/item/computer_hardware/card_slot(fabricated_laptop)
		if(dev_aislot)
			if(fabricate)
				fabricated_laptop.ai_slot = new/obj/item/computer_hardware/ai_slot(fabricated_laptop)

		return creation_cost()
	else if(devtype == 2)
		if(fabricate)
			fabricated_tablet = new(src)
			fabricated_tablet.processor_unit = new/obj/item/computer_hardware/processor_unit/small(fabricated_tablet)
		switch(dev_battery)
			if(1) // Basic(300C)
				if(fabricate)
					fabricated_tablet.battery_module = new/obj/item/computer_hardware/battery_module/nano(fabricated_tablet)
			if(2) // Upgraded(500C)
				if(fabricate)
					fabricated_tablet.battery_module = new/obj/item/computer_hardware/battery_module/micro(fabricated_tablet)
			if(3) // Advanced(750C)
				if(fabricate)
					fabricated_tablet.battery_module = new/obj/item/computer_hardware/battery_module(fabricated_tablet)
		switch(dev_disk)
			if(1) // Basic(32GQ)
				if(fabricate)
					fabricated_tablet.hard_drive = new/obj/item/computer_hardware/hard_drive/micro(fabricated_tablet)
			if(2) // Upgraded(64GQ)
				if(fabricate)
					fabricated_tablet.hard_drive = new/obj/item/computer_hardware/hard_drive/small(fabricated_tablet)
			if(3) // Advanced(128GQ)
				if(fabricate)
					fabricated_tablet.hard_drive = new/obj/item/computer_hardware/hard_drive(fabricated_tablet)
		switch(dev_netcard)
			if(1) // Basic(Short-Range)
				if(fabricate)
					fabricated_tablet.network_card = new/obj/item/computer_hardware/network_card(fabricated_tablet)
			if(2) // Advanced (Long Range)
				if(fabricate)
					fabricated_tablet.network_card = new/obj/item/computer_hardware/network_card/advanced(fabricated_tablet)
		if(dev_nanoprint)
			if(fabricate)
				fabricated_tablet.nano_printer = new/obj/item/computer_hardware/nano_printer(fabricated_tablet)
		if(dev_card)
			if(fabricate)
				fabricated_tablet.card_slot = new/obj/item/computer_hardware/card_slot(fabricated_tablet)
		if(dev_tesla)
			if(fabricate)
				fabricated_tablet.tesla_link = new/obj/item/computer_hardware/tesla_link(fabricated_tablet)
		if(dev_aislot)
			if(fabricate)
				fabricated_tablet.ai_slot = new/obj/item/computer_hardware/ai_slot(fabricated_tablet)
		return creation_cost()
	return 0





/obj/machinery/lapvend/Topic(href, href_list)
	if(..())
		return 1
	if(stat & (BROKEN|NOPOWER|MAINT))
		return

	if(href_list["pick_device"])
		if(state) // We've already picked a device type
			return 0
		var/choice = text2num(href_list["pick_device"])
		if(!(choice in list(1, 2)))
			return
		devtype = choice
		state = 1
		fabricate_device(0)
		return 1
	if(href_list["clean_order"])
		reset_order()
		return 1
	if(state != 1)
		return 0
	if(href_list["confirm_order"])
		if(!(devtype in list(1, 2)))
			return
		complete_order(usr)
		return 1
	if(href_list["hw_cpu"])
		dev_cpu = devtype == 2 ? 1 : clamp(round(text2num(href_list["hw_cpu"])), 1, 2)
		fabricate_device(0)
		return 1
	if(href_list["hw_battery"])
		dev_battery = clamp(round(text2num(href_list["hw_battery"])), 1, 3)
		fabricate_device(0)
		return 1
	if(href_list["hw_disk"])
		dev_disk = clamp(round(text2num(href_list["hw_disk"])), 1, 3)
		fabricate_device(0)
		return 1
	if(href_list["hw_netcard"])
		dev_netcard = clamp(round(text2num(href_list["hw_netcard"])), 0, 2)
		fabricate_device(0)
		return 1
	if(href_list["hw_tesla"])
		dev_tesla = clamp(round(text2num(href_list["hw_tesla"])), 0, 1)
		fabricate_device(0)
		return 1
	if(href_list["hw_nanoprint"])
		dev_nanoprint = clamp(round(text2num(href_list["hw_nanoprint"])), 0, 1)
		fabricate_device(0)
		return 1
	if(href_list["hw_card"])
		dev_card = clamp(round(text2num(href_list["hw_card"])), 0, 1)
		fabricate_device(0)
		return 1
	if(href_list["hw_aislot"])
		dev_aislot = clamp(round(text2num(href_list["hw_aislot"])), 0, 1)
		fabricate_device(0)
		return 1
	return 0

/obj/machinery/lapvend/attack_hand(var/mob/user)
	ui_interact(user)

/obj/machinery/lapvend/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	if(stat & (BROKEN | NOPOWER | MAINT))
		if(ui)
			ui.close()
		return 0

	var/list/data[0]
	data["state"] = state
	data["charges"] = creation_charges
	if(state == 1)
		data["devtype"] = devtype
		data["hw_battery"] = dev_battery
		data["hw_disk"] = dev_disk
		data["hw_netcard"] = dev_netcard
		data["hw_tesla"] = dev_tesla
		data["hw_nanoprint"] = dev_nanoprint
		data["hw_card"] = dev_card
		data["hw_cpu"] = dev_cpu
		data["hw_aislot"] = dev_aislot
	if(state == 1)
		data["chargecost"] = creation_cost()

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "computer_fabricator.tmpl", "Personal Computer Vendor", 500, 400)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)


/obj/machinery/lapvend/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/vending_charge))
		if(!user.Adjacent(src) || user.incapacitated() || W.loc != user || !user.unEquip(W, target = src))
			return
		creation_charges += 10
		qdel(W)
		to_chat(user, SPAN_NOTICE("The vendor now has [creation_charges] creation charges."))
		SSnano.update_uis(src)
		return
	return ..()

/obj/machinery/lapvend/proc/complete_order(mob/user)
	if(stat & (BROKEN|NOPOWER|MAINT))
		return
	if(state == 1)
		var/required_charges = creation_cost()
		if(creation_charges >= required_charges)
			creation_charges -= required_charges
			state = 3
			fabricate_device(1)
			if((devtype == 1) && fabricated_laptop)
				if(fabricated_laptop.battery_module)
					fabricated_laptop.battery_module.charge_to_full()
				fabricated_laptop.forceMove(src.loc)
				fabricated_laptop.screen_on = 0
				fabricated_laptop.anchored = 0
				fabricated_laptop.update_icon()
				fabricated_laptop.update_verbs()
				fabricated_laptop = null
			else if((devtype == 2) && fabricated_tablet)
				if(fabricated_tablet.battery_module)
					fabricated_tablet.battery_module.charge_to_full()
				fabricated_tablet.forceMove(src.loc)
				fabricated_tablet.update_verbs()
				fabricated_tablet = null
			ping("Enjoy your new product!")
			state = 3
			return 1
		to_chat(user, SPAN_WARNING("Insufficient creation charges."))
		return 0

/obj/machinery/lapvend/proc/creation_cost()
	return 3 + max(0, dev_cpu - 1) + max(0, dev_battery - 1) + max(0, dev_disk - 1) + dev_netcard + dev_tesla + dev_nanoprint + dev_card + dev_aislot

