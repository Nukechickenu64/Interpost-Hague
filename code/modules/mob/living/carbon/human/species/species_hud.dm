/datum/hud_data
	var/icon              // If set, overrides ui_style.
	var/has_a_intent = 1  // Set to draw intent box.
	var/has_c_intent = 1  // Set to draw combat box.
	var/has_skills_family = 1  // Set to draw skills_family box.
	var/has_m_intent = 1  // Set to draw move intent box.
	var/has_warnings = 1  // Set to draw environment warnings.
	var/has_pressure = 1  // Draw the pressure indicator.
	var/has_nutrition = 1 // Draw the nutrition indicator.
	var/has_bodytemp = 1  // Draw the bodytemp indicator.
	var/hovertext = 1
	var/has_hands = 1     // Set to draw hands.
	var/has_drop = 1      // Set to draw drop button.
	var/has_throw = 1     // Set to draw throw button.
	var/has_resist = 1    // Set to draw resist button.
	var/has_internals = 1 // Set to draw the internals toggle button.
	var/list/equip_slots = list() // Checked by mob_can_equip().

	// Contains information on the position and tag for all inventory slots
	// to be drawn for the mob. This is fairly delicate, try to avoid messing with it
	// unless you know exactly what it does.
	var/list/gear = list(
		"i_clothing" =   list("loc" = ui_os13_iclothing, "name" = "Uniform",      "slot" = slot_w_uniform, "state" = "center", "toggle" = 1),
		"o_clothing" =   list("loc" = ui_os13_oclothing, "name" = "Suit",         "slot" = slot_wear_suit, "state" = "o_clothing", "toggle" = 1),
		"mask" =         list("loc" = ui_os13_mask,      "name" = "Mask",         "slot" = slot_wear_mask, "state" = "mask",   "toggle" = 1),
		"gloves" =       list("loc" = ui_os13_gloves,    "name" = "Gloves",       "slot" = slot_gloves,    "state" = "gloves", "toggle" = 1),
		"wrist_l" =      list("loc" = ui_os13_wrist_l,  "name" = "Left Wrist",   "slot" = slot_wrist_l,   "state" = "wrist_l", "toggle" = 1),
		"wrist_r" =      list("loc" = ui_os13_wrist_r,  "name" = "Right Wrist",  "slot" = slot_wrist_r,   "state" = "wrist_r", "toggle" = 1),
		"eyes" =         list("loc" = ui_os13_glasses,   "name" = "Glasses",      "slot" = slot_glasses,  "state" = "glasses","toggle" = 1),
		"l_ear" =        list("loc" = ui_os13_l_ear,     "name" = "Left Ear",     "slot" = slot_l_ear,    "state" = "ears",   "toggle" = 1),
		"r_ear" =        list("loc" = ui_os13_r_ear,     "name" = "Right Ear",    "slot" = slot_r_ear,    "state" = "ears",   "toggle" = 1),
		"head" =         list("loc" = ui_os13_head,      "name" = "Hat",          "slot" = slot_head,      "state" = "hair",   "toggle" = 1),
		"shoes" =        list("loc" = ui_os13_shoes,     "name" = "Shoes",        "slot" = slot_shoes,      "state" = "shoes",  "toggle" = 1),
		"suit storage" = list("loc" = ui_os13_sstore,    "name" = "Suit Storage", "slot" = slot_s_store,   "state" = "back2"),
		"back" =         list("loc" = ui_os13_back,      "name" = "Back",         "slot" = slot_back,      "state" = "back"),
		"id" =           list("loc" = ui_os13_id,        "name" = "ID",           "slot" = slot_wear_id,    "state" = "card"),
		"amulet" =       list("loc" = ui_os13_amulet,    "name" = "Amulet",       "slot" = slot_wear_amulet, "state" = "amulet"),
		"storage1" =     list("loc" = ui_os13_storage1,  "name" = "Left Pocket",  "slot" = slot_l_store,   "state" = "pocket"),
		"storage2" =     list("loc" = ui_os13_storage2,  "name" = "Right Pocket", "slot" = slot_r_store,   "state" = "pocket"),
		"belt" =         list("loc" = ui_os13_belt,      "name" = "Belt",         "slot" = slot_belt,      "state" = "belt")
		)

/datum/hud_data/New()
	..()
	for(var/slot in gear)
		equip_slots |= gear[slot]["slot"]

	if(has_hands)
		equip_slots |= slot_l_hand
		equip_slots |= slot_r_hand
		equip_slots |= slot_handcuffed

	if(slot_back in equip_slots)
		equip_slots |= slot_in_backpack

	if(slot_w_uniform in equip_slots)
		equip_slots |= slot_tie

	equip_slots |= slot_legcuffed

/datum/hud_data/monkey
	gear = list(
		"i_clothing" =   list("loc" = ui_iclothing, "name" = "Uniform",      "slot" = slot_w_uniform, "state" = "center", "toggle" = 1),
		"storage1" =     list("loc" = ui_storage1,  "name" = "Left Pocket",  "slot" = slot_l_store,   "state" = "pocket"),
		"storage2" =     list("loc" = ui_storage2,  "name" = "Right Pocket", "slot" = slot_r_store,   "state" = "pocket"),
		"head" =         list("loc" = ui_head,      "name" = "Hat",          "slot" = slot_head,      "state" = "hair",   "toggle" = 1),
		"mask" =         list("loc" = ui_shoes,     "name" = "Mask", "slot" = slot_wear_mask, "state" = "mask",  "toggle" = 1),
		"back" =         list("loc" = ui_sstore1,   "name" = "Back", "slot" = slot_back,      "state" = "back"),
		)
