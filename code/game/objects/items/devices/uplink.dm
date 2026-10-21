// HIDDEN UPLINK - Can be stored in anything but the host item has to have a trigger for it.
/* How to create an uplink in 3 easy steps!

 1. All obj/item 's have a hidden_uplink var. By default it's null. Give the item one with "new(src)", it must be in it's contents. Feel free to add "uses".

 2. Code in the triggers. Use check_trigger for this, I recommend closing the item's menu with "usr << browse(null, "window=windowname") if it returns true.
 The var/value is the value that will be compared with the var/target. If they are equal it will activate the menu.

 3. If you want the menu to stay until the users locks his uplink, add an active_uplink_check(mob/user as mob) in your interact/attack_hand proc.
 Then check if it's true, if true return. This will stop the normal menu appearing and will instead show the uplink menu.
*/

/obj/item/device/uplink
	name = "hidden uplink"
	desc = "There is something wrong if you're examining this."
	var/active = 0
	var/datum/uplink_category/category 	= 0		// The current category we are in
	var/exploit_id								// Id of the current exploit record we are viewing

	var/welcome = "Welcome, Operative"	// Welcoming menu message
	var/uses = 10
	var/list/ItemsCategory				// List of categories with lists of items
	var/list/ItemsReference				// List of references with an associated item
	var/list/nanoui_items				// List of items for NanoUI use
	var/nanoui_menu = 0					// The current menu we are in
	var/list/nanoui_data = new 			// Additional data for NanoUI use

	var/datum/mind/uplink_owner = null
	var/creation_charges_spent = 0

/obj/item/device/uplink/nano_host()
	return loc

/obj/item/device/uplink/New(var/atom/location, var/datum/mind/owner, var/initial_charges = DEFAULT_CREATION_CHARGES)
	if(!istype(location, /atom))
		CRASH("Invalid spawn location. Expected /atom, was [location ? location.type : "NULL"]")

	..()
	nanoui_data = list()
	update_nano_data()

	src.uplink_owner = owner
	uses = istype(location, /mob/living/deity) ? initial_charges : 10
	world_uplinks += src

/obj/item/device/uplink/Destroy()
	uplink_owner = null
	world_uplinks -= src
	return ..()

// Toggles the uplink on and off. Normally this will bypass the item's normal functions and go to the uplink menu, if activated.
/obj/item/device/uplink/proc/toggle()
	active = !active

// Directly trigger the uplink. Turn on if it isn't already.
/obj/item/device/uplink/proc/trigger(mob/user as mob)
	if(!active)
		toggle()
	interact(user)

// Checks to see if the value meets the target. Like a frequency being a traitor_frequency, in order to unlock a headset.
// If true, it accesses trigger() and returns 1. If it fails, it returns false. Use this to see if you need to close the
// current item's menu.
/obj/item/device/uplink/proc/check_trigger(mob/user as mob, var/value, var/target)
	if(value == target)
		trigger(user)
		return 1
	return 0

/*
	NANO UI FOR UPLINK WOOP WOOP
*/
/obj/item/device/uplink/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/uistate = GLOB.inventory_state)
	var/title = "Remote Uplink"
	var/data[0]

	data["welcome"] = welcome
	data["charges"] = uses
	data["resource_label"] = istype(loc, /mob/living/deity) ? "Power" : "Creation charges"
	data["menu"] = nanoui_menu

	data += nanoui_data

	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)	// No auto-refresh
		ui = new(user, src, ui_key, "uplink.tmpl", title, 450, 600, state = uistate)
		ui.set_initial_data(data)
		ui.open()


// Interaction code. Gathers a list of items purchasable from the paren't uplink and displays it. It also adds a lock button.
/obj/item/device/uplink/interact(mob/user)
	ui_interact(user)

/obj/item/device/uplink/CanUseTopic()
	if(!active)
		return STATUS_CLOSE
	return ..()

// The purchasing code.
/obj/item/device/uplink/OnTopic(user, href_list)
	if(href_list["refill"] && !istype(loc, /mob/living/deity))
		var/mob/operator = user
		var/obj/item/vending_charge/token = operator.get_active_hand()
		if(!istype(token))
			token = operator.get_inactive_hand()
		if(!istype(token) || token.loc != operator || operator.incapacitated() || !operator.unEquip(token, target = src))
			return TOPIC_HANDLED
		uses += 10
		qdel(token)
		. = TOPIC_REFRESH
	else if(href_list["buy_item"])
		var/datum/uplink_item/UI = (locate(href_list["buy_item"]) in uplink.items)
		if(UI)
			UI.buy(src, user)
		. = TOPIC_REFRESH
	else if(href_list["lock"])
		toggle()
		SSnano.close_user_uis(user, src, "main")
		. = TOPIC_HANDLED
	else if(href_list["return"])
		nanoui_menu = round(nanoui_menu/10)
		. = TOPIC_REFRESH
	else if(href_list["menu"])
		nanoui_menu = text2num(href_list["menu"])
		if(href_list["id"])
			exploit_id = text2num(href_list["id"])
		if(href_list["category"])
			category = locate(href_list["category"]) in uplink.categories
		. = TOPIC_REFRESH

	if(. == TOPIC_REFRESH)
		update_nano_data()

/obj/item/device/uplink/proc/update_nano_data()
	if(nanoui_menu == 0)
		var/categories[0]
		for(var/datum/uplink_category/category in uplink.categories)
			if(category.can_view(src))
				categories[++categories.len] = list("name" = category.name, "ref" = "\ref[category]")
		nanoui_data["categories"] = categories
	else if(nanoui_menu == 1 && category)
		var/items[0]
		for(var/datum/uplink_item/item in category.items)
			if(item.can_view(src))
				var/cost = item.cost(uses, src)
				if(!cost) cost = "???"
				items[++items.len] = list("name" = item.name(), "description" = replacetext(item.description(), "\n", "<br>"), "can_buy" = item.can_buy(src), "cost" = cost, "ref" = "\ref[item]")
		nanoui_data["items"] = items
	else if(nanoui_menu == 2)
		var/permanentData[0]
		for(var/datum/computer_file/crew_record/L in GLOB.all_crew_records)
			permanentData[++permanentData.len] = list(Name = L.get_name(),"id" = L.uid, "exploit" = length(L.get_antagRecord()))
		nanoui_data["exploit_records"] = permanentData
	else if(nanoui_menu == 21)
		nanoui_data["exploit_exists"] = 0

		for(var/datum/computer_file/crew_record/L in GLOB.all_crew_records)
			if(L.uid == exploit_id)
				nanoui_data["exploit"] = list()  // Setting this to equal L.fields passes it's variables that are lists as reference instead of value.
								 // We trade off being able to automatically add shit for more control over what gets passed to json
								 // and if it's sanitized for html.
				var/list/fields = list(
					REC_FIELD(name),
					REC_FIELD(sex),
					REC_FIELD(age),
					REC_FIELD(species),
					REC_FIELD(rank),
					REC_FIELD(homeSystem),
					REC_FIELD(citizenship),
					REC_FIELD(faction),
					REC_FIELD(religion),
					REC_FIELD(fingerprint),
					REC_FIELD(antagRecord))
				var/list/rec_fields = list()
				for(var/field in fields)
					var/record_field/F = locate(field) in L.fields
					if(!F)
						continue
					rec_fields.Add(list(list(
						"name" = html_encode(F.name),
						"val" = F.get_display_value()
					)))
				nanoui_data["exploit"]["fields"] =  rec_fields

				nanoui_data["exploit_exists"] = 1
				break

// I placed this here because of how relevant it is.
// You place this in your uplinkable item to check if an uplink is active or not.
// If it is, it will display the uplink menu and return 1, else it'll return false.
// If it returns true, I recommend closing the item's normal menu with "user << browse(null, "window=name")"
/obj/item/proc/active_uplink_check(mob/user as mob)
	// Activates the uplink if it's active
	if(src.hidden_uplink)
		if(src.hidden_uplink.active)
			src.hidden_uplink.trigger(user)
			return 1
	return 0

// PRESET UPLINKS
// A collection of preset uplinks.
//
// Includes normal radio uplink, multitool uplink,
// implant uplink (not the implant tool) and a preset headset uplink.

/obj/item/device/radio/uplink/New(var/loc, var/owner, var/amount)
	..()
	hidden_uplink = new(src, owner, amount)
	icon_state = "radio"

/obj/item/device/radio/uplink/attack_self(mob/user as mob)
	if(hidden_uplink)
		hidden_uplink.trigger(user)

/obj/item/device/multitool/uplink/New(var/loc, var/owner)
	..()
	hidden_uplink = new(src, owner)

/obj/item/device/multitool/uplink/attack_self(mob/user as mob)
	if(hidden_uplink)
		hidden_uplink.trigger(user)

/obj/item/device/radio/headset/uplink
	traitor_frequency = 1445

/obj/item/device/radio/headset/uplink/New()
	..()
	hidden_uplink = new(src)

/obj/item/device/uplink/contained/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/uistate = GLOB.contained_state)
	return ..()
