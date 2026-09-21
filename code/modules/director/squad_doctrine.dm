// Squad Doctrines & Tactical Asymmetry
// When major antagonist factions spawn, they are organized into squads
// with distinct doctrines and specialized loadouts.

/datum/squad_doctrine
	var/name = "Default Squad"
	var/faction = LOYALTY_SYNDICATE
	var/list/role_assignments = list()  // mind ref -> role string
	var/list/loadout_types = list()     // role string -> outfit type path
	var/squad_size = 5
	var/doctrine_description = "A balanced fireteam with mixed capabilities."

/datum/squad_doctrine/syndicate_strike
	name = "Syndicate Strike Team"
	faction = LOYALTY_SYNDICATE
	squad_size = 5
	doctrine_description = "A coordinated Syndicate fireteam designed for tactical insertion and assault."

	loadout_types = list(
		SQUAD_ROLE_LEADER   = /decl/hierarchy/outfit/syndicate_strike/leader,
		SQUAD_ROLE_EW       = /decl/hierarchy/outfit/syndicate_strike/ew,
		SQUAD_ROLE_HEAVY    = /decl/hierarchy/outfit/syndicate_strike/heavy,
		SQUAD_ROLE_BREACHER = /decl/hierarchy/outfit/syndicate_strike/breacher,
		SQUAD_ROLE_MEDIC    = /decl/hierarchy/outfit/syndicate_strike/medic,
	)

/datum/squad_doctrine/mercenary
	name = "Mercenary Squad"
	faction = LOYALTY_SYNDICATE
	squad_size = 4
	doctrine_description = "A flexible mercenary team with emphasis on adaptability and firepower."

	loadout_types = list(
		SQUAD_ROLE_LEADER   = /decl/hierarchy/outfit/mercenary_squad/leader,
		SQUAD_ROLE_HEAVY    = /decl/hierarchy/outfit/mercenary_squad/heavy,
		SQUAD_ROLE_BREACHER = /decl/hierarchy/outfit/mercenary_squad/breacher,
		SQUAD_ROLE_MEDIC    = /decl/hierarchy/outfit/mercenary_squad/medic,
	)

/// Assign roles to a list of minds based on squad size and doctrine
/datum/squad_doctrine/proc/assign_roles(var/list/datum/mind/members)
	if(!members || !members.len)
		return

	role_assignments.Cut()

	// Shuffle members for random role assignment
	var/list/shuffled = members.Copy()
	shuffle(shuffled)

	var/list/roles_to_assign = list()
	// Always have a leader
	roles_to_assign += SQUAD_ROLE_LEADER

	// Fill remaining slots with specialized roles
	var/list/specialist_roles = list(SQUAD_ROLE_EW, SQUAD_ROLE_HEAVY, SQUAD_ROLE_BREACHER, SQUAD_ROLE_MEDIC)
	while(roles_to_assign.len < min(shuffled.len, squad_size) && specialist_roles.len)
		roles_to_assign += pick_n_take(specialist_roles)

	// Assign
	for(var/i = 1 to min(shuffled.len, roles_to_assign.len))
		role_assignments[shuffled[i]] = roles_to_assign[i]

/// Get the role assigned to a mind
/datum/squad_doctrine/proc/get_role(var/datum/mind/M)
	return role_assignments[M]

/// Get the outfit type for a role
/datum/squad_doctrine/proc/get_outfit_for_role(var/role)
	return loadout_types[role]

/// Equip a member with their role's loadout
/datum/squad_doctrine/proc/equip_member(var/datum/mind/M)
	if(!M || !M.current)
		return FALSE
	var/role = get_role(M)
	if(!role)
		return FALSE
	var/outfit_type = get_outfit_for_role(role)
	if(!outfit_type)
		return FALSE
	var/mob/living/carbon/human/H = M.current
	if(!istype(H))
		return FALSE
	// Create and apply the outfit
	var/decl/hierarchy/outfit/O = new outfit_type
	O.equip(H)
	qdel(O)
	to_chat(H, "<span class='notice'><b>Squad Role:</b> You are the [role] for the [name]. [get_role_description(role)]</span>")
	return TRUE

/// Get a description of what each role does
/datum/squad_doctrine/proc/get_role_description(var/role)
	switch(role)
		if(SQUAD_ROLE_LEADER)
			return "You coordinate the squad, call targets, and make tactical decisions."
		if(SQUAD_ROLE_EW)
			return "You handle electronic warfare: hacking PDAs, disabling cameras, and jamming communications."
		if(SQUAD_ROLE_HEAVY)
			return "You carry heavy weapons and provide suppressive fire. You are the spearhead."
		if(SQUAD_ROLE_BREACHER)
			return "You specialize in breaching doors, walls, and fortified positions. You carry C4 and breaching tools."
		if(SQUAD_ROLE_MEDIC)
			return "You keep the squad alive. Prioritize healing and reviving fallen teammates."
		else
			return "Follow your leader's orders."

/// Announce the squad composition to all members
/datum/squad_doctrine/proc/announce_squad()
	for(var/datum/mind/M in role_assignments)
		if(!M.current)
			continue
		var/role = role_assignments[M]
		to_chat(M.current, "<span class='danger'><b>[name] Assembled</b></span>")
		to_chat(M.current, "<span class='danger'>[doctrine_description]</span>")
		to_chat(M.current, "<span class='danger'>Your role: <b>[role]</b></span>")
		// List squadmates
		var/squad_list = ""
		for(var/datum/mind/teammate in role_assignments)
			if(teammate == M)
				continue
			if(teammate.current)
				squad_list += "[teammate.current.name] ([role_assignments[teammate]]), "
		if(squad_list)
			to_chat(M.current, "<span class='danger'>Squadmates: [squad_list]</span>")

// === Outfit definitions for squad roles ===

/decl/hierarchy/outfit/syndicate_strike

/decl/hierarchy/outfit/syndicate_strike/leader
	name = "Syndicate Strike Leader"
	// Base syndicate gear + command extras
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/gun/energy/crossbow
	l_pocket = /obj/item/weapon/melee/energy/sword
	r_pocket = /obj/item/device/radio

/decl/hierarchy/outfit/syndicate_strike/ew
	name = "Syndicate EW Specialist"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/device/multitool/hacktool
	l_pocket = /obj/item/device/encryptionkey/syndicate
	r_pocket = /obj/item/device/radio

/decl/hierarchy/outfit/syndicate_strike/heavy
	name = "Syndicate Heavy Weapons"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/heavy
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/gun/projectile/automatic
	l_pocket = /obj/item/ammo_magazine/a10mm
	r_pocket = /obj/item/weapon/grenade/empgrenade

/decl/hierarchy/outfit/syndicate_strike/breacher
	name = "Syndicate Breacher"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/grenade/empgrenade
	l_pocket = /obj/item/weapon/melee/energy/sword
	r_pocket = /obj/item/weapon/card/emag

/decl/hierarchy/outfit/syndicate_strike/medic
	name = "Syndicate Medic"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/storage/firstaid/adv
	l_pocket = /obj/item/weapon/storage/firstaid/surgery
	r_pocket = /obj/item/device/radio

/decl/hierarchy/outfit/mercenary_squad

/decl/hierarchy/outfit/mercenary_squad/leader
	name = "Mercenary Leader"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/gun/energy/crossbow
	l_pocket = /obj/item/weapon/melee/energy/sword
	r_pocket = /obj/item/device/radio

/decl/hierarchy/outfit/mercenary_squad/heavy
	name = "Mercenary Heavy"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/heavy
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/gun/projectile/automatic
	l_pocket = /obj/item/ammo_magazine/a10mm

/decl/hierarchy/outfit/mercenary_squad/breacher
	name = "Mercenary Breacher"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/grenade/empgrenade
	l_pocket = /obj/item/weapon/card/emag

/decl/hierarchy/outfit/mercenary_squad/medic
	name = "Mercenary Medic"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/swat
	gloves = /obj/item/clothing/gloves/thick/swat
	head = /obj/item/clothing/head/helmet/swat
	back = /obj/item/weapon/storage/backpack/satchel_norm
	belt = /obj/item/weapon/storage/firstaid/adv
	l_pocket = /obj/item/weapon/storage/firstaid/surgery