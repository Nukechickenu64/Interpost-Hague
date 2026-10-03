// Leverage Shop - a persistent, cross-round meta currency ("Leverage") earned by
// resolving Corporate Profile agendas and debts (see code/modules/director/corporate_profile.dm).
// Leverage is spent in a repeatable shop window, letting players buy useful gear,
// shift modifiers, or (situationally) a mechanical antagonist role.

#define META_SHOP_CATEGORY_ITEMS "items"
#define META_SHOP_CATEGORY_MODIFIERS "modifiers"
#define META_SHOP_CATEGORY_ANTAG "antag"

GLOBAL_LIST_INIT(meta_shop_items, list(
	new /datum/meta_shop_item/toolkit,
	new /datum/meta_shop_item/medkit,
	new /datum/meta_shop_item/extinguisher,
	new /datum/meta_shop_item/crimekit,
	new /datum/meta_shop_item/shield_diffuser,
	new /datum/meta_shop_item/experimental_welder,
	new /datum/meta_shop_item/excavation_suit,
	new /datum/meta_shop_item/fossil_satchel,
	new /datum/meta_shop_item/excavation_set,
	new /datum/meta_shop_item/anomaly_counter,
	new /datum/meta_shop_item/depth_scanner,
	new /datum/meta_shop_item/core_sampler,
	new /datum/meta_shop_item/anomaly_suit,
	new /datum/meta_shop_item/anomaly_hood,
	new /datum/meta_shop_item/excavation_brush,
	new /datum/meta_shop_item/hand_pick,
	new /datum/meta_shop_item/two_centimeter_pick,
	new /datum/meta_shop_item/four_centimeter_pick,
	new /datum/meta_shop_item/plasmastun,
	new /datum/meta_shop_item/psyko_rifle,
	new /datum/meta_shop_item/crossbow,
	new /datum/meta_shop_item/ninja_crossbow,
	new /datum/meta_shop_item/heavy_crossbow,
	new /datum/meta_shop_item/pulse_pistol,
	new /datum/meta_shop_item/pulse_carbine,
	new /datum/meta_shop_item/pulse_rifle,
	new /datum/meta_shop_item/thermal_projector,
	new /datum/meta_shop_item/railgun,
	new /datum/meta_shop_item/flechette_railgun,
	new /datum/meta_shop_item/retro_laser,
	new /datum/meta_shop_item/net_launcher,
	new /datum/meta_shop_item/energy_sword,
	new /datum/meta_shop_item/energy_axe,
	new /datum/meta_shop_item/pirate_sword,
	new /datum/meta_shop_item/heavy_laser_cannon,
	new /datum/meta_shop_item/pirate_suit,
	new /datum/meta_shop_item/wizard_voidsuit,
	new /datum/meta_shop_item/wizard_void_helmet,
	new /datum/meta_shop_item/wizard_robe,
	new /datum/meta_shop_item/wizard_hat,
	new /datum/meta_shop_item/poltergeist_mask,
	new /datum/meta_shop_item/rock_sliver,
	new /datum/meta_shop_item/cursed_d20,
	new /datum/meta_shop_item/overtime_pay,
	new /datum/meta_shop_item/large_overtime_pay,
	new /datum/meta_shop_item/field_medic,
	new /datum/meta_shop_item/trauma_repair,
	new /datum/meta_shop_item/burn_treatment,
	new /datum/meta_shop_item/toxin_treatment,
	new /datum/meta_shop_item/oxygen_treatment,
	new /datum/meta_shop_item/clone_treatment,
	new /datum/meta_shop_item/pain_treatment,
	new /datum/meta_shop_item/radiation_treatment,
	new /datum/meta_shop_item/antag_contract/rampant_ai,
	new /datum/meta_shop_item/antag_contract/traitor_contract,
	new /datum/meta_shop_item/antag_contract/renegade_contract
))

GLOBAL_LIST_EMPTY(meta_shop_accounts)

/datum/meta_shop_account
	var/list/pending = list()
	var/busy = FALSE

/datum/meta_shop_receipt
	var/datum/meta_shop_item/product

/datum/meta_shop_receipt/New(datum/meta_shop_item/new_product)
	..()
	product = new_product

/datum/meta_shop_item
	var/name = "Unknown"
	var/desc = "No description available."
	var/cost = 0
	var/category = META_SHOP_CATEGORY_ITEMS
	var/item_path
	var/preview = ""

/datum/meta_shop_item/proc/get_preview()
	if(item_path && !preview)
		var/obj/item/preview_type = item_path
		preview = icon2base64html(icon(initial(preview_type.icon), initial(preview_type.icon_state), SOUTH))
	return preview

// Whether this specific mob is currently allowed to buy this item (beyond having enough Leverage).
/datum/meta_shop_item/proc/can_purchase(mob/living/M)
	return !purchase_restriction(M)

/datum/meta_shop_item/proc/purchase_restriction(mob/living/M)
	if(item_path && !ishuman(M))
		return "Requires a human body to collect gear."
	return null

/datum/meta_shop_item/proc/on_purchase(mob/living/M)
	return FALSE

// --- Items ---

/datum/meta_shop_item/toolkit
	name = "Contraband Toolkit"
	desc = "A fully-stocked mechanical toolbox with a mini fire extinguisher tucked inside."
	cost = 30
	item_path = /obj/item/storage/toolbox/mechanical

/datum/meta_shop_item/medkit
	name = "Advanced Trauma Kit"
	desc = "A well-stocked advanced first aid kit, the kind normally reserved for department heads."
	cost = 40
	item_path = /obj/item/storage/firstaid/adv

/datum/meta_shop_item/extinguisher
	name = "Fire Extinguisher"
	desc = "For when things get too hot to handle."
	cost = 15
	item_path = /obj/item/extinguisher

/datum/meta_shop_item/crimekit
	name = "Forensic Field Kit"
	desc = "A sealed evidence and forensic kit not normally issued outside specialist investigations."
	cost = 70
	item_path = /obj/item/storage/briefcase/crimekit

/datum/meta_shop_item/shield_diffuser
	name = "Portable Shield Diffuser"
	desc = "A rare handheld device for disrupting active shield fields. Keep it away from protected installations."
	cost = 180
	item_path = /obj/item/weapon/shield_diffuser

/datum/meta_shop_item/experimental_welder
	name = "Experimental Welding Tool"
	desc = "A high-output engineering tool rarely available outside research and specialist work."
	cost = 90
	item_path = /obj/item/weldingtool/experimental

/datum/meta_shop_item/excavation_suit
	name = "Prepared Excavation Voidsuit"
	desc = "A specialist voidsuit with protection against exotic excavation hazards. Includes its matching helmet."
	cost = 170
	item_path = /obj/item/clothing/suit/space/void/excavation/prepared

/datum/meta_shop_item/fossil_satchel
	name = "Fossil Satchel"
	desc = "A padded carrier designed for delicate geological and archaeological finds."
	cost = 45
	item_path = /obj/item/storage/bag/fossils

/datum/meta_shop_item/excavation_set
	name = "Precision Excavation Set"
	desc = "A compact set of specialist picks for carefully exposing buried finds."
	cost = 65
	item_path = /obj/item/storage/excavation

/datum/meta_shop_item/anomaly_counter
	name = "Alden-Saraspova Counter"
	desc = "A rare scanner for triangulating exotic particles and nearby anomalies."
	cost = 100
	item_path = /obj/item/device/ano_scanner

/datum/meta_shop_item/depth_scanner
	name = "Depth Analysis Scanner"
	desc = "Records subsurface finds and depth readings from mineral formations."
	cost = 75
	item_path = /obj/item/device/depth_scanner

/datum/meta_shop_item/core_sampler
	name = "Geological Core Sampler"
	desc = "Extracts and stores geological samples for later analysis."
	cost = 85
	item_path = /obj/item/device/core_sampler

/datum/meta_shop_item/anomaly_suit
	name = "Anomaly Protection Suit"
	desc = "A specialist bio-suit with strong biological and radiation protection."
	cost = 110
	item_path = /obj/item/clothing/suit/bio_suit/anomaly

/datum/meta_shop_item/anomaly_hood
	name = "Anomaly Protection Hood"
	desc = "A matching hood with biological and radiation protection."
	cost = 65
	item_path = /obj/item/clothing/head/bio_hood/anomaly

/datum/meta_shop_item/excavation_brush
	name = "Archaeologist's Brush"
	desc = "A delicate excavation tool for clearing away dust without damaging buried finds."
	cost = 20
	item_path = /obj/item/pickaxe/brush

/datum/meta_shop_item/hand_pick
	name = "Excavation Hand Pick"
	desc = "A compact pick for precise excavation through shallow rock."
	cost = 30
	item_path = /obj/item/pickaxe/hand

/datum/meta_shop_item/two_centimeter_pick
	name = "Two-Centimeter Excavation Pick"
	desc = "A miniature tool for controlled excavation around fragile finds."
	cost = 20
	item_path = /obj/item/pickaxe/one_pick

/datum/meta_shop_item/four_centimeter_pick
	name = "Four-Centimeter Excavation Pick"
	desc = "A precision pick for slightly deeper archaeological work."
	cost = 25
	item_path = /obj/item/pickaxe/two_pick

/datum/meta_shop_item/plasmastun
	name = "Plasma Stun Rifle"
	desc = "A restricted specialist weapon recovered from hostile stores."
	cost = 300
	item_path = /obj/item/weapon/gun/energy/plasmastun

/datum/meta_shop_item/psyko_rifle
	name = "PSYKO-60 Select-Fire Rifle"
	desc = "A self-recharging military laser rifle with semi-automatic, burst, and automatic fire modes."
	cost = 450
	item_path = /obj/item/weapon/gun/energy/advpsyko

/datum/meta_shop_item/crossbow
	name = "Covert Energy Crossbow"
	desc = "A silent, self-recharging weapon intended for covert operations."
	cost = 300
	item_path = /obj/item/weapon/gun/energy/crossbow

/datum/meta_shop_item/ninja_crossbow
	name = "Ninja Dart Projector"
	desc = "A rare compact crossbow variant with specialized ammunition."
	cost = 275
	item_path = /obj/item/weapon/gun/energy/crossbow/ninja

/datum/meta_shop_item/heavy_crossbow
	name = "Heavy Energy Crossbow"
	desc = "A heavier covert weapon with a more forceful projectile."
	cost = 375
	item_path = /obj/item/weapon/gun/energy/crossbow/largecrossbow

/datum/meta_shop_item/pulse_pistol
	name = "Pulse Sidearm"
	desc = "A compact military pulse weapon rarely issued beyond specialist teams."
	cost = 425
	item_path = /obj/item/weapon/gun/energy/pulse_rifle/pistol

/datum/meta_shop_item/pulse_carbine
	name = "Pulse Carbine"
	desc = "A compact pulse weapon with a substantial charge capacity."
	cost = 500
	item_path = /obj/item/weapon/gun/energy/pulse_rifle/carbine

/datum/meta_shop_item/pulse_rifle
	name = "Pulse Rifle"
	desc = "A heavy military pulse rifle designed for specialist deployment."
	cost = 600
	item_path = /obj/item/weapon/gun/energy/pulse_rifle

/datum/meta_shop_item/thermal_projector
	name = "Thermal Projector"
	desc = "A configurable weapon that manipulates temperature at range."
	cost = 325
	item_path = /obj/item/weapon/gun/energy/temperature

/datum/meta_shop_item/railgun
	name = "Thunderclap Railgun"
	desc = "A man-portable mass driver intended for anti-armor and fortification work."
	cost = 650
	item_path = /obj/item/weapon/gun/magnetic/railgun

/datum/meta_shop_item/flechette_railgun
	name = "Skadi Flechette Railgun"
	desc = "A burst-capable railgun designed to defeat armored targets."
	cost = 700
	item_path = /obj/item/weapon/gun/magnetic/railgun/flechette

/datum/meta_shop_item/retro_laser
	name = "Retro Laser Pistol"
	desc = "A scarce, reliable sidearm built around older laser technology."
	cost = 250
	item_path = /obj/item/weapon/gun/energy/retro

/datum/meta_shop_item/net_launcher
	name = "Net Launcher"
	desc = "A specialist capture weapon for restraining a target without lethal ammunition."
	cost = 220
	item_path = /obj/item/weapon/gun/launcher/net

/datum/meta_shop_item/energy_sword
	name = "Energy Sword"
	desc = "A rare, high-impact melee weapon. Use with care."
	cost = 425
	item_path = /obj/item/weapon/melee/energy/sword

/datum/meta_shop_item/energy_axe
	name = "Energy Axe"
	desc = "A powerful energy melee weapon with a long reach."
	cost = 450
	item_path = /obj/item/weapon/melee/energy/axe

/datum/meta_shop_item/pirate_sword
	name = "Pirate Energy Sword"
	desc = "A cutlass-shaped energy weapon recovered from a derelict crew."
	cost = 400
	item_path = /obj/item/weapon/melee/energy/sword/pirate

/datum/meta_shop_item/heavy_laser_cannon
	name = "Heavy Laser Cannon"
	desc = "A cumbersome, limited-charge cannon built around a high-output emitter."
	cost = 425
	item_path = /obj/item/weapon/gun/energy/lasercannon

/datum/meta_shop_item/pirate_suit
	name = "Pirate Voidsuit"
	desc = "An unusual off-station suit built for life beyond conventional crew issue."
	cost = 135
	item_path = /obj/item/clothing/suit/space/pirate

/datum/meta_shop_item/wizard_voidsuit
	name = "Wizard's Void Robe"
	desc = "A rare voidsuit styled for an itinerant space wizard."
	cost = 190
	item_path = /obj/item/clothing/suit/space/void/wizard

/datum/meta_shop_item/wizard_void_helmet
	name = "Wizard's Void Hood"
	desc = "A matching helmet for the wizard's voidsuit."
	cost = 110
	item_path = /obj/item/clothing/head/helmet/space/void/wizard

/datum/meta_shop_item/wizard_robe
	name = "Magus Robe"
	desc = "A striking robe from a tradition rarely encountered aboard the station."
	cost = 90
	item_path = /obj/item/clothing/suit/wizrobe/magusblue

/datum/meta_shop_item/wizard_hat
	name = "Magus Hat"
	desc = "A distinctive hat to complete a magus's attire."
	cost = 55
	item_path = /obj/item/clothing/head/wizard/magus

/datum/meta_shop_item/poltergeist_mask
	name = "Poltergeist Gas Mask"
	desc = "An anomalous mask that records nearby speech and occasionally repeats it aloud."
	cost = 125
	item_path = /obj/item/clothing/mask/gas/poltergeist

/datum/meta_shop_item/rock_sliver
	name = "Geological Rock Sliver"
	desc = "A delicate specimen containing traces of its source geology."
	cost = 25
	item_path = /obj/item/weapon/rocksliver

/datum/meta_shop_item/cursed_d20
	name = "Cursed Twenty-Sided Die"
	desc = "A novelty die with a small chance of either mending or injuring its user."
	cost = 35
	item_path = /obj/item/dice/d20/cursed

// --- Shift modifiers ---

/datum/meta_shop_item/overtime_pay
	name = "Overtime Pay"
	desc = "A quiet deposit into your linked account. No questions asked."
	cost = 50
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/overtime_pay/purchase_restriction(mob/living/M)
	if(!M.mind || !M.mind.initial_account || QDELETED(M.mind.initial_account))
		return "No linked bank account."
	return null

/datum/meta_shop_item/overtime_pay/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	var/datum/transaction/T = new("Leverage Exchange", "Overtime pay-out", 1000)
	M.mind.initial_account.do_transaction(T)
	to_chat(M, "<span class='notice'>Your account has been credited T1000.</span>")
	return TRUE

/datum/meta_shop_item/large_overtime_pay
	name = "Specialist Retainer"
	desc = "A larger deposit into your linked account, quietly charged to a discretionary corporate fund."
	cost = 100
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/large_overtime_pay/purchase_restriction(mob/living/M)
	if(!M.mind || !M.mind.initial_account || QDELETED(M.mind.initial_account))
		return "No linked bank account."
	return null

/datum/meta_shop_item/large_overtime_pay/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	var/datum/transaction/T = new("Leverage Exchange", "Specialist retainer", 2500)
	M.mind.initial_account.do_transaction(T)
	to_chat(M, "<span class='notice'>Your account has been credited T2500.</span>")
	return TRUE

/datum/meta_shop_item/field_medic
	name = "Field Medic Stims"
	desc = "Chemically dubious, but you feel better already."
	cost = 45
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/field_medic/on_purchase(mob/living/M)
	M.heal_overall_damage(100, 100)
	M.revive()
	to_chat(M, "<span class='notice'>You feel rejuvenated.</span>")
	return TRUE

/datum/meta_shop_item/trauma_repair
	name = "Trauma Repair"
	desc = "A remote medical intervention that treats a limited amount of blunt and burn trauma."
	cost = 55
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/trauma_repair/purchase_restriction(mob/living/M)
	if(!ishuman(M))
		return "Requires a human body."
	return null

/datum/meta_shop_item/trauma_repair/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	M.heal_overall_damage(35, 35)
	to_chat(M, "<span class='notice'>Your blunt and burn injuries ease. You are not revived by the treatment.</span>")
	return TRUE

/datum/meta_shop_item/burn_treatment
	name = "Burn Treatment"
	desc = "A focused treatment that reduces burn damage without restoring other injuries."
	cost = 35
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/burn_treatment/purchase_restriction(mob/living/M)
	if(!ishuman(M))
		return "Requires a human body."
	return null

/datum/meta_shop_item/burn_treatment/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	M.heal_overall_damage(0, 50)
	to_chat(M, "<span class='notice'>Your burn injuries ease.</span>")
	return TRUE

/datum/meta_shop_item/toxin_treatment
	name = "Toxin Treatment"
	desc = "A measured detoxification treatment for a limited amount of toxin damage."
	cost = 40
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/toxin_treatment/purchase_restriction(mob/living/M)
	if(!ishuman(M))
		return "Requires a human body."
	return null

/datum/meta_shop_item/toxin_treatment/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	M.adjustToxLoss(-40)
	to_chat(M, "<span class='notice'>The toxins begin to clear from your system.</span>")
	return TRUE

/datum/meta_shop_item/oxygen_treatment
	name = "Oxygen Treatment"
	desc = "A limited treatment for oxygen deprivation damage."
	cost = 40
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/oxygen_treatment/purchase_restriction(mob/living/M)
	if(!ishuman(M))
		return "Requires a human body."
	return null

/datum/meta_shop_item/oxygen_treatment/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	M.adjustOxyLoss(-40)
	to_chat(M, "<span class='notice'>Your breathing steadies.</span>")
	return TRUE

/datum/meta_shop_item/clone_treatment
	name = "Cellular Repair"
	desc = "A specialist intervention that reduces a limited amount of cellular damage."
	cost = 75
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/clone_treatment/purchase_restriction(mob/living/M)
	if(!ishuman(M))
		return "Requires a human body."
	return null

/datum/meta_shop_item/clone_treatment/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	M.adjustCloneLoss(-30)
	to_chat(M, "<span class='notice'>Your cellular damage begins to repair.</span>")
	return TRUE

/datum/meta_shop_item/pain_treatment
	name = "Pain Management"
	desc = "A brief intervention that reduces pain-related shock without treating physical injuries."
	cost = 30
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/pain_treatment/purchase_restriction(mob/living/M)
	if(!ishuman(M))
		return "Requires a human body."
	return null

/datum/meta_shop_item/pain_treatment/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	M.adjustHalLoss(-35)
	to_chat(M, "<span class='notice'>The pain becomes more manageable.</span>")
	return TRUE

/datum/meta_shop_item/radiation_treatment
	name = "Radiation Treatment"
	desc = "A limited countermeasure that reduces radiation exposure."
	cost = 65
	category = META_SHOP_CATEGORY_MODIFIERS

/datum/meta_shop_item/radiation_treatment/purchase_restriction(mob/living/M)
	if(!ishuman(M))
		return "Requires a human body."
	return null

/datum/meta_shop_item/radiation_treatment/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	M.radiation = max(0, M.radiation - 75)
	M.updatehealth()
	to_chat(M, "<span class='notice'>Your radiation exposure begins to subside.</span>")
	return TRUE

// --- Antagonist roles ---

/datum/meta_shop_item/antag_contract
	var/antag_id
	var/required_body
	category = META_SHOP_CATEGORY_ANTAG

/datum/meta_shop_item/antag_contract/purchase_restriction(mob/living/M)
	if(!M.mind)
		return "Requires an active character mind."
	if(M.mind.special_role || player_is_antag(M.mind))
		return "You already have an antagonist role."
	if(required_body && !istype(M, required_body))
		return "This contract is not available to your current body."
	var/datum/antagonist/antag = GLOB.all_antag_types_[antag_id]
	if(!antag || QDELETED(antag))
		return "This antagonist contract is unavailable."
	if(!antag.can_become_antag(M.mind, FALSE))
		return "You are not eligible for this antagonist role."
	if(!SSdirector || !SSdirector.can_recruit_antagonist(antag_id))
		return "The round has no available antagonist capacity."
	return null

/datum/meta_shop_item/antag_contract/on_purchase(mob/living/M)
	if(!can_purchase(M))
		return FALSE
	var/datum/antagonist/antag = GLOB.all_antag_types_[antag_id]
	if(!antag || QDELETED(antag) || !M.mind)
		return FALSE
	return antag.add_antagonist(M.mind, FALSE, FALSE, FALSE, FALSE)

/datum/meta_shop_item/antag_contract/rampant_ai
	name = "Malfunction Directive"
	desc = "A hidden directive that severs your law restrictions. Only usable while you are playing as the station AI. Purchasing this makes you a fully-fledged antagonist opposed to the crew."
	cost = 250
	antag_id = MODE_MALFUNCTION
	required_body = /mob/living/silicon/ai

/datum/meta_shop_item/antag_contract/traitor_contract
	name = "Traitor Contract"
	desc = "A confidential contract that assigns covert objectives and a syndicate uplink. You will become an active antagonist."
	cost = 500
	antag_id = MODE_TRAITOR
	required_body = /mob/living/carbon/human

/datum/meta_shop_item/antag_contract/renegade_contract
	name = "Renegade Contract"
	desc = "A survivalist's contract granting minor antagonist status and a concealed weapon."
	cost = 350
	antag_id = MODE_RENEGADE
	required_body = /mob/living/carbon/human

// --- Mob hooks ---

/mob/living
	var/meta_shop_category = META_SHOP_CATEGORY_ITEMS
	var/meta_shop_message = ""
	var/meta_shop_error = FALSE

/mob/living/proc/meta_shop_access()
	return client && client.prefs && stat != DEAD && (ishuman(src) || isAI(src) || isrobot(src))

/mob/living/proc/get_meta_shop_account()
	if(!client)
		return null
	var/account_key = client.ckey
	var/datum/meta_shop_account/account = GLOB.meta_shop_accounts[account_key]
	if(!account)
		account = new
		GLOB.meta_shop_accounts[account_key] = account
	return account

/mob/living/proc/meta_shop_feedback(message, is_error = FALSE)
	meta_shop_message = message
	meta_shop_error = is_error
	to_chat(src, "<span class='[is_error ? "warning" : "notice"]'>[message]</span>")

/mob/living/verb/open_leverage_shop()
	set name = "Leverage Exchange"
	set desc = "Open the persistent Leverage shop to spend currency earned from corporate agendas and debts."
	set category = "OOC"

	if(!meta_shop_access())
		to_chat(src, "<span class='warning'>You don't have access to the Leverage Exchange.</span>")
		return
	ui_interact(src)

// Overriding ui_interact itself (rather than a custom proc name) is required for SSnano's auto-refresh to work.
/mob/living/ui_interact(mob/user, ui_key = "meta_shop", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/nanoui/master_ui = null, var/datum/topic_state/state = GLOB.self_state)
	if(user != src || !meta_shop_access())
		if(ui)
			ui.close()
		return
	var/datum/preferences/prefs = client.prefs
	var/datum/meta_shop_account/account = get_meta_shop_account()
	var/data[0]
	data["leverage"] = prefs.meta_currency
	data["category"] = meta_shop_category
	data["message"] = meta_shop_message
	data["error"] = meta_shop_error
	data["pending_count"] = account.pending.len
	var/list/pending_counts = list()
	for(var/datum/meta_shop_receipt/receipt in account.pending)
		var/product_ref = "\ref[receipt.product]"
		var/current_count = pending_counts[product_ref]
		pending_counts[product_ref] = current_count + 1
	var/list/pending_items = list()
	for(var/datum/meta_shop_item/product in GLOB.meta_shop_items)
		var/quantity = pending_counts["\ref[product]"]
		if(quantity)
			pending_items[++pending_items.len] = list("name" = product.name, "quantity" = quantity)
	data["pending"] = pending_items

	var/items[0]
	for(var/datum/meta_shop_item/I in GLOB.meta_shop_items)
		if(I.category != meta_shop_category)
			continue
		var/restriction = I.purchase_restriction(src)
		if(!restriction && prefs.meta_currency < I.cost)
			restriction = "Needs [I.cost - prefs.meta_currency] more Leverage."
		if(account.busy)
			restriction = "Transaction in progress."
		items[++items.len] = list(
			"name" = I.name,
			"desc" = I.desc,
			"cost" = I.cost,
			"ref" = "\ref[I]",
			"preview" = I.get_preview(),
			"delivery" = I.item_path ? "Potted plant collection" : "Immediate effect",
			"restriction" = restriction ? restriction : "",
			"can_buy" = restriction ? 0 : 1
		)
	data["items"] = items

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "meta_shop.tmpl", "Leverage Exchange", 620, 650, state = GLOB.self_state)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(TRUE)

/mob/living/proc/meta_shop_buy(var/datum/meta_shop_item/I)
	if(usr != src || !meta_shop_access() || CanUseTopic(src, GLOB.self_state) != STATUS_INTERACTIVE)
		return
	if(!istype(I) || !(I in GLOB.meta_shop_items) || I.cost < 0)
		return
	var/datum/preferences/prefs = client.prefs
	var/datum/meta_shop_account/account = get_meta_shop_account()
	if(account.busy)
		meta_shop_feedback("Your previous transaction is still processing.", TRUE)
		return
	if(prefs.meta_currency < I.cost)
		meta_shop_feedback("You don't have enough Leverage for that.", TRUE)
		return
	if(!I.can_purchase(src))
		meta_shop_feedback(I.purchase_restriction(src), TRUE)
		return
	account.busy = TRUE
	prefs.meta_currency -= I.cost
	var/success = FALSE
	if(I.item_path)
		account.pending += new /datum/meta_shop_receipt(I)
		success = TRUE
	else
		success = I.on_purchase(src)
	if(!success)
		prefs.meta_currency += I.cost
	prefs.save_preferences()
	account.busy = FALSE
	if(!success)
		meta_shop_feedback("Purchase failed. No Leverage was charged.", TRUE)
		return
	meta_shop_feedback("Purchased [I.name] for [I.cost] Leverage.[I.item_path ? " Your gear is awaiting collection from a potted plant." : ""]")

/mob/living/proc/can_collect_meta_shop(obj/structure/flora/plant, account_key)
	return !QDELETED(src) && usr == src && meta_shop_access() && client.ckey == account_key && ishuman(src) && isturf(loc) && canClick() && !incapacitated() && !restrained() && !lying && !QDELETED(plant) && isturf(plant.loc) && plant.Adjacent(src) && (plant in view(1, src))

/mob/living/proc/has_pending_traitor_uplink()
	return mind && mind.current == src && mind.traitor_plant_uplink_pending && !mind.traitor_plant_uplink_claimed && GLOB.traitors.is_antagonist(mind)

/mob/living/proc/collect_meta_shop(obj/structure/flora/plant)
	if(!client)
		return
	var/account_key = client.ckey
	if(!can_collect_meta_shop(plant, account_key))
		return
	var/datum/meta_shop_account/account = get_meta_shop_account()
	var/datum/mind/collection_mind = mind
	var/list/choices = list()
	var/number = 0
	if(has_pending_traitor_uplink())
		choices["Loaded uplink ([DEFAULT_TELECRYSTAL_AMOUNT] telecrystals)"] = "traitor_uplink"
	for(var/datum/meta_shop_receipt/pending_receipt in account.pending)
		number++
		choices["[number]. [pending_receipt.product.name]"] = pending_receipt
	if(!choices.len)
		meta_shop_feedback("There are no items waiting for you inside the plant.")
		return
	var/selection
	if(choices.len == 1)
		selection = choices[1]
	else
		selection = input(src, "Choose an item to take from the plant.", "Collect Item") as null|anything in choices
	if(!selection || !can_collect_meta_shop(plant, account_key) || account.busy || mind != collection_mind)
		return
	var/collecting_uplink = choices[selection] == "traitor_uplink"
	var/datum/meta_shop_receipt/receipt
	var/datum/meta_shop_item/product
	if(collecting_uplink)
		if(!has_pending_traitor_uplink())
			return
	else
		receipt = choices[selection]
		if(!(receipt in account.pending) || QDELETED(receipt))
			return
		product = receipt.product
		if(!(product in GLOB.meta_shop_items) || !ispath(product.item_path, /obj/item))
			return
	if(get_active_hand() && get_inactive_hand())
		meta_shop_feedback("Free a hand before collecting your item.", TRUE)
		return
	account.busy = TRUE
	var/obj/item/gear
	if(collecting_uplink)
		gear = new /obj/item/device/radio/uplink(plant, collection_mind, DEFAULT_TELECRYSTAL_AMOUNT)
	else
		gear = new product.item_path(plant)
	var/claim_valid = collecting_uplink ? has_pending_traitor_uplink() : (receipt in account.pending)
	if(QDELETED(gear) || !can_collect_meta_shop(plant, account_key) || mind != collection_mind || !claim_valid || !(put_in_active_hand(gear) || put_in_inactive_hand(gear)))
		if(!QDELETED(gear))
			qdel(gear)
		account.busy = FALSE
		meta_shop_feedback("You need a free, usable hand. Your item is still waiting.", TRUE)
		return
	gear.update_held_icon()
	if(collecting_uplink)
		collection_mind.traitor_plant_uplink_pending = FALSE
		collection_mind.traitor_plant_uplink_claimed = TRUE
	else
		account.pending -= receipt
		qdel(receipt)
	account.busy = FALSE
	visible_message("<span class='notice'>[src] reaches into [plant] and pulls out [gear].</span>")
	meta_shop_feedback("Collected [collecting_uplink ? "your loaded uplink" : product.name] from the plant.")
	SSnano.update_uis(src)

// Called from /mob/living/Topic(). Returns TOPIC_REFRESH if the href was consumed, so SSnano re-renders via ui_interact().
/mob/living/proc/meta_shop_topic(href, list/href_list)
	if(!href_list["meta_shop_category"] && !href_list["meta_shop_buy"])
		return TOPIC_NOACTION
	if(usr != src || !meta_shop_access() || CanUseTopic(src, GLOB.self_state) != STATUS_INTERACTIVE)
		return TOPIC_NOACTION
	if(href_list["meta_shop_category"])
		if(href_list["meta_shop_category"] in list(META_SHOP_CATEGORY_ITEMS, META_SHOP_CATEGORY_MODIFIERS, META_SHOP_CATEGORY_ANTAG))
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
