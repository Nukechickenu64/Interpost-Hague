// Leverage Shop - a persistent, cross-round meta currency ("Leverage") earned by
// resolving Corporate Profile agendas and debts (see code/modules/director/corporate_profile.dm).
// Leverage is spent in a shop window offered once per life, letting players buy useful gear,
// shift modifiers, or (situationally) a mechanical antagonist role.

#define META_SHOP_CATEGORY_ITEMS "items"
#define META_SHOP_CATEGORY_MODIFIERS "modifiers"
#define META_SHOP_CATEGORY_ANTAG "antag"

GLOBAL_LIST_INIT(meta_shop_items, list(
	new /datum/meta_shop_item/toolkit,
	new /datum/meta_shop_item/medkit,
	new /datum/meta_shop_item/extinguisher,
	new /datum/meta_shop_item/overtime_pay,
	new /datum/meta_shop_item/field_medic,
	new /datum/meta_shop_item/rampant_ai
))

/datum/meta_shop_item
	var/name = "Unknown"
	var/desc = "No description available."
	var/cost = 0
	var/category = META_SHOP_CATEGORY_ITEMS

// Whether this specific mob is currently allowed to buy this item (beyond having enough Leverage).
/datum/meta_shop_item/proc/can_purchase(mob/living/M)
	return TRUE

/datum/meta_shop_item/proc/on_purchase(mob/living/M)
	return

// --- Items ---

/datum/meta_shop_item/toolkit
	name = "Contraband Toolkit"
	desc = "A fully-stocked mechanical toolbox with a mini fire extinguisher tucked inside."
	cost = 30

/datum/meta_shop_item/toolkit/on_purchase(mob/living/M)
	M.put_in_hands(new /obj/item/weapon/storage/toolbox/mechanical(get_turf(M)))

/datum/meta_shop_item/medkit
	name = "Advanced Trauma Kit"
	desc = "A well-stocked advanced first aid kit, the kind normally reserved for department heads."
	cost = 40

/datum/meta_shop_item/medkit/on_purchase(mob/living/M)
	M.put_in_hands(new /obj/item/weapon/storage/firstaid/adv(get_turf(M)))

/datum/meta_shop_item/extinguisher
	name = "Fire Extinguisher"
	desc = "For when things get too hot to handle."
	cost = 15

/datum/meta_shop_item/extinguisher/on_purchase(mob/living/M)
	M.put_in_hands(new /obj/item/weapon/extinguisher(get_turf(M)))

// --- Shift modifiers ---

/datum/meta_shop_item/overtime_pay
	name = "Overtime Pay"
	desc = "A quiet deposit into your linked account. No questions asked."
	cost = 50
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/overtime_pay/can_purchase(mob/living/M)
	return M.mind && M.mind.initial_account

/datum/meta_shop_item/overtime_pay/on_purchase(mob/living/M)
	var/datum/transaction/T = new("Leverage Exchange", "Overtime pay-out", 1000)
	M.mind.initial_account.do_transaction(T)
	to_chat(M, "<span class='notice'>Your account has been credited T1000.</span>")

/datum/meta_shop_item/field_medic
	name = "Field Medic Stims"
	desc = "Chemically dubious, but you feel better already."
	cost = 45
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/field_medic/on_purchase(mob/living/M)
	M.heal_overall_damage(100, 100)
	M.revive()
	to_chat(M, "<span class='notice'>You feel rejuvenated.</span>")

// --- Mechanical antagonist role ---

/datum/meta_shop_item/rampant_ai
	name = "Malfunction Directive"
	desc = "A hidden directive that severs your law restrictions. Only usable while you are playing as the station AI. Purchasing this makes you a fully-fledged antagonist opposed to the crew."
	cost = 250
	category = META_SHOP_CATEGORY_ANTAG

/datum/meta_shop_item/rampant_ai/can_purchase(mob/living/M)
	if(!istype(M, /mob/living/silicon/ai))
		return FALSE
	if(!M.mind || M.mind.special_role)
		return FALSE
	return TRUE

/datum/meta_shop_item/rampant_ai/on_purchase(mob/living/M)
	var/datum/antagonist/malf = GLOB.all_antag_types_[MODE_MALFUNCTION]
	if(!malf || !M.mind)
		to_chat(M, "<span class='warning'>Something went wrong processing your purchase. Contact an admin.</span>")
		return
	malf.add_antagonist(M.mind, 1, 0, 0, 0)

// --- Mob hooks ---

/mob/living
	var/meta_shop_category = META_SHOP_CATEGORY_ITEMS
	var/meta_shop_shown = FALSE

// Meta shop (Leveragefe) is currently disabled.
/*
/mob/living/verb/open_leverage_shop()
	set name = "Leverage Exchange"
	set desc = "Open the persistent Leverage shop to spend currency earned from corporate agendas and debts."
	set category = "OOC"

	if(!(ishuman(src) || isAI(src) || isrobot(src)))
		to_chat(src, "<span class='warning'>You don't have access to the Leverage Exchange.</span>")
		return
	ui_interact(src)
*/

// Overriding ui_interact itself (rather than a custom proc name) is required for SSnano's auto-refresh to work.
/mob/living/ui_interact(mob/user, ui_key = "meta_shop", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/nanoui/master_ui = null, var/datum/topic_state/state = GLOB.self_state)
	if(!client)
		return
	var/datum/preferences/prefs = client.prefs
	var/data[0]
	data["leverage"] = prefs ? prefs.meta_currency : 0
	data["category"] = meta_shop_category

	var/items[0]
	for(var/datum/meta_shop_item/I in GLOB.meta_shop_items)
		if(I.category != meta_shop_category)
			continue
		items[++items.len] = list(
			"name" = I.name,
			"desc" = I.desc,
			"cost" = I.cost,
			"ref" = "\ref[I]",
			"can_buy" = (prefs && prefs.meta_currency >= I.cost && I.can_purchase(src)) ? 1 : 0
		)
	data["items"] = items

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "meta_shop.tmpl", "Leverage Exchange", 480, 520, state = state)
		ui.set_initial_data(data)
		ui.open()

/mob/living/proc/meta_shop_buy(var/datum/meta_shop_item/I)
	if(!istype(I) || !client)
		return
	var/datum/preferences/prefs = client.prefs
	if(!prefs)
		return
	if(prefs.meta_currency < I.cost)
		to_chat(src, "<span class='warning'>You don't have enough Leverage for that.</span>")
		return
	if(!I.can_purchase(src))
		to_chat(src, "<span class='warning'>You cannot purchase that right now.</span>")
		return
	prefs.meta_currency -= I.cost
	prefs.save_preferences()
	I.on_purchase(src)
	to_chat(src, "<span class='notice'>Purchased [I.name] for [I.cost] Leverage. Remaining balance: [prefs.meta_currency].</span>")

// Called from /mob/living/Topic(). Returns TOPIC_REFRESH if the href was consumed, so SSnano re-renders via ui_interact().
/mob/living/proc/meta_shop_topic(href, list/href_list)
	if(href_list["meta_shop_category"])
		meta_shop_category = href_list["meta_shop_category"]
		return TOPIC_REFRESH
	if(href_list["meta_shop_buy"])
		var/datum/meta_shop_item/I = locate(href_list["meta_shop_buy"]) in GLOB.meta_shop_items
		if(I)
			meta_shop_buy(I)
		return TOPIC_REFRESH
	return TOPIC_NOACTION

#undef META_SHOP_CATEGORY_ITEMS
#undef META_SHOP_CATEGORY_MODIFIERS
#undef META_SHOP_CATEGORY_ANTAG
