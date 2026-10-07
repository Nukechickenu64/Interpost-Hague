var/datum/admin_secrets/admin_secrets = new()

/datum/admin_secrets
	var/list/datum/admin_secret_category/categories
	var/list/datum/admin_secret_item/items
	var/list/datum/event_meta/random_event_templates = list()

/datum/admin_secrets/New()
	..()
	categories = init_subtypes(/datum/admin_secret_category)
	items = list()
	var/list/category_assoc = list()
	for(var/datum/admin_secret_category/category in categories)
		category_assoc[category.type] = category

	for(var/item_type in (typesof(/datum/admin_secret_item) - /datum/admin_secret_item))
		var/datum/admin_secret_item/secret_item = item_type
		if(!initial(secret_item.name))
			continue

		var/datum/admin_secret_item/item = new item_type()
		var/datum/admin_secret_category/category = category_assoc[item.category]
		dd_insertObjectList(category.items, item)
		items += item

/datum/admin_secrets/proc/populate_random_events()
	if(!SSevent || !SSevent.event_containers)
		return

	var/datum/admin_secret_category/random_event_category
	for(var/datum/admin_secret_category/category in categories)
		if(category.type == /datum/admin_secret_category/random_events)
			random_event_category = category
			break
	if(!random_event_category)
		return

	for(var/severity = EVENT_LEVEL_MUNDANE to EVENT_LEVEL_MAJOR)
		var/list/datum/event_container/event_containers = SSevent.event_containers[severity]
		for(var/datum/event_container/event_container in event_containers)
			for(var/datum/event_meta/event_template in event_container.available_events)
				if(event_template in random_event_templates)
					continue
				random_event_templates += event_template
				var/datum/admin_secret_item/random_event/scheduled_event/item = new(event_template)
				dd_insertObjectList(random_event_category.items, item)
				items += item

//
// Secret Item Category - Each subtype is a category for organizing secret commands.
//
/datum/admin_secret_category
	var/name = ""
	var/desc = ""
	var/list/datum/admin_secret_item/items

/datum/admin_secret_category
	items = list()

/datum/admin_secret_category/proc/can_view(var/mob/user)
	for(var/datum/admin_secret_item/item in items)
		if(item.can_view(user))
			return 1
	return 0

//
// Secret Item Datum - Each subtype is a command on the secrets panel.
// 	Override execute() with the implementation of the command.
//
/datum/admin_secret_item
	var/name = ""
	var/category = null
	var/log = 1
	var/feedback = 1
	var/permissions = R_HOST
	var/warn_before_use = 0

/datum/admin_secret_item/dd_SortValue()
	return "[name]"

/datum/admin_secret_item/proc/name()
	return name

/datum/admin_secret_item/proc/can_view(var/mob/user)
	return check_rights(permissions, 0, user)

/datum/admin_secret_item/proc/can_execute(var/mob/user)
	if(can_view(user))
		if(!warn_before_use || alert("Execute the command '[name]'?", name, "No","Yes") == "Yes")
			return 1
	return 0

/datum/admin_secret_item/proc/execute(var/mob/user)
	if(!can_execute(user))
		return 0

	if(log)
		log_and_message_admins("used secret '[name]'", user)
	if(feedback)
		SSstatistics.add_field("admin_secrets_used",1)
		SSstatistics.add_field_details("admin_secrets_used","[name]")
	. = TRUE
	do_execute(user)

/datum/admin_secret_item/proc/do_execute(var/mob/user)
	return

/datum/admin_secret_item/Topic()
	. = ..()
	return !. && !can_execute(usr)

/*************************
* Pre-defined categories *
*************************/
/datum/admin_secret_category/admin_secrets
	name = "Admin Secrets"

/datum/admin_secret_category/investigation
	name = "Investigation"

/datum/admin_secret_category/random_events
	name = "'Random' Events"

/datum/admin_secret_category/fun_secrets
	name = "Fun Secrets"

/datum/admin_secret_category/final_solutions
	name = "Final Solutions"
	desc = "(Warning, these will end the round!)"

/*************************
* Pre-defined base items *
*************************/
/datum/admin_secret_item/admin_secret
	category = /datum/admin_secret_category/admin_secrets
	log = 0
	permissions = R_ADMIN

/datum/admin_secret_item/investigation
	category = /datum/admin_secret_category/investigation
	log = 0
	permissions = R_INVESTIGATE

/datum/admin_secret_item/random_event
	category = /datum/admin_secret_category/random_events
	permissions = R_FUN
	warn_before_use = 1

/datum/admin_secret_item/random_event/scheduled_event
	var/datum/event_meta/event_template

/datum/admin_secret_item/random_event/scheduled_event/New(var/datum/event_meta/template)
	..()
	event_template = template
	name = "[severity_to_string[template.severity]]: [template.name]"

/datum/admin_secret_item/random_event/scheduled_event/do_execute(var/mob/user)
	if(!event_template || !event_template.event_type)
		return

	var/datum/event_meta/event_instance = new /datum/event_meta(event_template.severity, event_template.name, event_template.event_type, event_template.weight, event_template.role_weights, event_template.one_shot, event_template.min_weight, event_template.max_weight, FALSE)
	new event_template.event_type(event_instance)

/datum/admin_secret_item/fun_secret
	category = /datum/admin_secret_category/fun_secrets
	permissions = R_FUN
	warn_before_use = 1

/datum/admin_secret_item/final_solution
	category = /datum/admin_secret_category/final_solutions
	permissions = R_FUN|R_SERVER|R_ADMIN
