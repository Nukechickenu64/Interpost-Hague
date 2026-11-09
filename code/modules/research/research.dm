/*
General Explination:
The research datum is the "folder" where all the research information is stored in a R&D console. It's also a holder for all the
various procs used to manipulate it. It has four variables and seven procs:

Variables:
- possible_tech is a list of all the /datum/tech that can potentially be researched by the player. The RefreshResearch() proc
(explained later) only goes through those when refreshing what you know. Generally, possible_tech contains ALL of the existing tech
but it is possible to add tech to the game that DON'T start in it (example: Xeno tech). Generally speaking, you don't want to mess
with these since they should be the default version of the datums. They're actually stored in a list rather then using typesof to
refer to them since it makes it a bit easier to search through them for specific information.
- know_tech is the companion list to possible_tech. It's the tech you can actually research and improve. Until it's added to this
list, it can't be improved. All the tech in this list are visible to the player.
- possible_designs is functionally identical to possbile_tech except it's for /datum/design.
- known_designs is functionally identical to known_tech except it's for /datum/design

Procs:
- TechHasReqs: Used by other procs (specifically RefreshResearch) to see whether all of a tech's requirements are currently in
known_tech and at a high enough level.
- DesignHasReqs: Same as TechHasReqs but for /datum/design and known_design.
- AddTech2Known: Adds a /datum/tech to known_tech. It checks to see whether it already has that tech (if so, it just replaces it). If
it doesn't have it, it adds it. Note: It does NOT check possible_tech at all. So if you want to add something strange to it (like
a player made tech?) you can.
- AddDesign2Known: Same as AddTech2Known except for /datum/design and known_designs.
- RefreshResearch: This is the workhorse of the R&D system. It updates the /datum/research holder and adds any unlocked tech paths
and designs you have reached the requirements for. It only checks through possible_tech and possible_designs, however, so it won't
accidentally add "secret" tech to it.
- UpdateTech is used as part of the actual researching process. It takes an ID and finds techs with that same ID in known_tech. When
it finds it, it checks to see whether it can improve it at all. If the known_tech's level is less then or equal to
the inputted level, it increases the known tech's level to the inputted level -1 or know tech's level +1 (whichever is higher).

The tech datums are the actual "tech trees" that you improve through researching. Each one has five variables:
- Name:		Pretty obvious. This is often viewable to the players.
- Desc:		Pretty obvious. Also player viewable.
- ID:		This is the unique ID of the tech that is used by the various procs to find and/or maniuplate it.
- Level:	This is the current level of the tech. All techs start at 1 and have a max of 20. Devices and some techs require a certain
level in specific techs before you can produce them.
- Req_tech:	This is a list of the techs required to unlock this tech path. If left blank, it'll automatically be loaded into the
research holder datum.

*/
/***************************************************************
**						Master Types						  **
**	Includes all the helper procs and basic tech processing.  **
***************************************************************/

/datum/research								//Holder for all the existing, archived, and known tech. Individual to console.
	var/list/known_tech = list()			//List of locally known tech. Datum/tech go here.
	var/list/possible_designs = list()		//List of all designs.
	var/list/known_designs = list()			//List of available designs.

/datum/research/New()		//Insert techs into possible_tech here. Known_tech automatically updated.
	initialize_technologies()
	for(var/D in typesof(/datum/design) - /datum/design)
		if(!istype(GLOB.using_map, /datum/map/alpha) || (D in os13_research_designs()))
			possible_designs += new D(src)
	RefreshResearch()

/datum/research/techonly

/datum/research/techonly/New()
	initialize_technologies()
	RefreshResearch()

/datum/research/proc/initialize_technologies()
	for(var/tech_type in research_technology_types())
		var/datum/tech/T = new tech_type(src)
		if(istype(GLOB.using_map, /datum/map/alpha))
			T.level = 0
		known_tech += T

//Checks to see if design has all the required pre-reqs.
//Input: datum/design; Output: 0/1 (false/true)
/datum/research/proc/DesignHasReqs(var/datum/design/D)
	if(istype(GLOB.using_map, /datum/map/alpha))
		var/list/catalogue = os13_research_designs()
		if(QDELETED(D) || !(D.type in catalogue))
			return FALSE
		var/tech_type = catalogue[D.type]
		if(!tech_type)
			return TRUE // Blank media is infrastructure, not an extracted technology.
		for(var/datum/tech/T in known_tech)
			if(T.type == tech_type && T.level > 0)
				return TRUE
		return FALSE
	if(D.req_tech.len == 0)
		return 1

	var/list/k_tech = list()

	for(var/datum/tech/known in known_tech)
		k_tech[known.id] = known.level

	for(var/req in D.req_tech)
		if(isnull(k_tech[req]) || k_tech[req] < D.req_tech[req])
			return 0

	return 1

//Adds a tech to known_tech list. Checks to make sure there aren't duplicates and updates existing tech's levels if needed.
//Input: datum/tech; Output: Null
/datum/research/proc/AddTech2Known(var/datum/tech/T)
	return import_technologies(list(T))

/datum/research/proc/import_technologies(list/recordings)
	var/os13 = istype(GLOB.using_map, /datum/map/alpha)
	var/list/targets = list()
	for(var/datum/tech/T as anything in recordings)
		if(QDELETED(T) || (os13 && (!istype(T, /datum/tech/os13) || T.type == /datum/tech/os13 || T.level != 1)))
			log_debug("Research rejected an unavailable technology import.")
			return FALSE
		var/datum/tech/target = find_import_target(T, os13)
		if(!target)
			return FALSE
		targets[T] = target
	for(var/datum/tech/recording as anything in targets)
		var/datum/tech/target = targets[recording]
		target.level = max(target.level, recording.level)
	return length(targets) > 0

/datum/research/proc/find_import_target(datum/tech/T, os13)
	for(var/datum/tech/known in known_tech)
		if(T.id == known.id && (!os13 || T.type == known.type))
			return known

/datum/research/proc/AddDesign2Known(var/datum/design/D)
	if(istype(GLOB.using_map, /datum/map/alpha) && !DesignHasReqs(D))
		log_debug("Research rejected a blueprint outside the installed OS13 wiki catalogue.")
		return FALSE
	if(!known_designs.len) // Special case
		known_designs.Add(D)
		return
	for(var/i = 1 to known_designs.len)
		var/datum/design/A = known_designs[i]
		if(A.id == D.id) // We are guaranteed to reach this if the ids are the same, because sort_string will also be the same
			return
		if(A.sort_string > D.sort_string)
			known_designs.Insert(i, D)
			return
	known_designs.Add(D)
	return

//Refreshes known_tech and known_designs list
//Input/Output: n/a
/datum/research/proc/RefreshResearch()
	if(istype(GLOB.using_map, /datum/map/alpha))
		for(var/datum/design/D in known_designs.Copy())
			if(!DesignHasReqs(D))
				known_designs -= D
	for(var/datum/tech/T in known_tech)
		var/bounded_level = between(0, T.level, istype(GLOB.using_map, /datum/map/alpha) ? 1 : 20)
		if(T.level != bounded_level)
			log_debug("Research refresh bounded [T.id] from level [T.level] to [bounded_level].")
			T.level = bounded_level
	for(var/datum/design/PD in possible_designs)
		if(DesignHasReqs(PD))
			AddDesign2Known(PD)
	return

//Refreshes the levels of a given tech.
//Input: Tech's ID and Level; Output: null
/datum/research/proc/UpdateTech(var/ID, var/level)
	if(istype(GLOB.using_map, /datum/map/alpha))
		return // Named OS13 research is installed from media, never analyzer levels.
	for(var/datum/tech/KT in known_tech)
		if(KT.id == ID && KT.level <= level)
			KT.level = max(KT.level + 1, level - 1)
	return

// A simple helper proc to find the name of a tech with a given ID.
/proc/CallTechName(var/ID) 
	for(var/T in subtypesof(/datum/tech))
		var/datum/tech/check_tech = T
		if(initial(check_tech.id) == ID)
			return  initial(check_tech.name)
	
/***************************************************************
**						Technology Datums					  **
**	Includes all the various technoliges and what they make.  **
***************************************************************/

/datum/tech //Datum of individual technologies.
	var/name = "name"					//Name of the technology.
	var/desc = "description"			//General description of what it does and what it makes.
	var/id = "id"						//An easily referenced ID. Must be alphanumeric, lower-case, and no symbols.
	var/level = 1						//A simple number scale of the research level. Level 0 = Secret tech.

/datum/tech/materials
	name = "Materials"
	desc = "Development of new and improved materials."
	id = TECH_MATERIAL

/datum/tech/engineering
	name = "Engineering"
	desc = "Development of new and improved engineering parts."
	id = TECH_ENGINEERING

/datum/tech/phorontech
	name = "Phoron Technology"
	desc = "Manipulation of the mysterious substance colloqually known as 'phoron'."
	id = TECH_PHORON

/datum/tech/powerstorage
	name = "Power Manipulation Technology"
	desc = "The various technologies behind the storage and generation of electicity."
	id = TECH_POWER

/datum/tech/bluespace
	name = "'Blue-space' Technology"
	desc = "Devices that utilize the sub-reality known as 'blue-space'"
	id = TECH_BLUESPACE

/datum/tech/biotech
	name = "Biological Technology"
	desc = "Deeper mysteries of life and organic substances."
	id = TECH_BIO

/datum/tech/combat
	name = "Combat Systems"
	desc = "Offensive and defensive systems."
	id = TECH_COMBAT

/datum/tech/magnets
	name = "Electromagnetic Spectrum Technology"
	desc = "Electromagnetic spectrum and magnetic devices. No clue how they actually work, though."
	id = TECH_MAGNET

/datum/tech/programming
	name = "Data Theory"
	desc = "Computer and artificial intelligence and data storage systems."
	id = TECH_DATA

/datum/tech/syndicate
	name = "ILLEGAL"
	desc = "WARNING: Controlled technology detected. Fabrication of items using this technology is a direct violation of Federal Law 352-C part II and is a serious crime."
	id = TECH_ILLEGAL
	level = 0

/datum/tech/arcane
	name = "Arcane"
	desc = "Techniques not explained by the mainstream science, commonly regarded as 'occult'."
	id = TECH_ARCANE
	level = 0

/obj/item/disk/tech_disk
	name = "fabricator data disk"
	desc = "A disk for storing fabricator learning data for backup."
	icon = 'icons/obj/cloning.dmi'
	icon_state = "datadisk2"
	item_state = "card-id"
	w_class = ITEM_SIZE_SMALL
	matter = list(DEFAULT_WALL_MATERIAL = 30, "glass" = 10)
	var/datum/tech/stored

/obj/item/disk/tech_disk/proc/set_research(datum/tech/technology)
	stored = technology
	if(!stored)
		name = initial(name)
		desc = initial(desc)
		return
	var/level_label = istype(stored, /datum/tech/os13) ? "tier" : "level"
	var/recording = "[stored.name] ([level_label] [stored.display_level()])"
	if(istype(src, /obj/item/disk/tech_disk/os13))
		name = initial(name)
		desc = "Technologies: [recording]. Import this disk at an R&D console to unlock this research."
	else
		name = "[stored.name] technology disk ([level_label] [stored.display_level()])"
		desc = "Recorded research. Import this disk at an R&D console to unlock [recording]."

/obj/item/disk/tech_disk/examine(mob/user)
	. = ..()
	to_chat(user, SPAN_NOTICE("<b>Technologies:</b>"))
	for(var/datum/tech/recording in research_recordings())
		to_chat(user, SPAN_NOTICE("[html_encode(recording.name)] ([istype(recording, /datum/tech/os13) ? "tier" : "level"] [recording.display_level()])"))

/obj/item/disk/tech_disk/proc/research_recordings()
	return stored ? list(stored) : list()

/obj/item/disk/tech_disk/os13
	name = "Diskette"
	desc = "A portable technology diskette. Record research with a cyberdeck or import its data at a replicator console."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "datadisk0"
	item_state = "card-id"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/disk/tech_disk/os13/core
	name = "Core Diskette"
	desc = "A core technology diskette for the Replicator console."
	var/list/core_recordings

/obj/item/disk/tech_disk/os13/core/Initialize(mapload)
	. = ..()
	stored = new /datum/tech/os13/battery
	core_recordings = list(stored, new /datum/tech/os13/solar_panel, new /datum/tech/os13/icepick_mk1)

/obj/item/disk/tech_disk/os13/core/research_recordings()
	return core_recordings ? core_recordings.Copy() : ..()

/obj/item/disk/tech_disk/os13/core/set_research(datum/tech/technology)
	if(core_recordings)
		for(var/datum/tech/recording in core_recordings)
			if(recording != technology)
				qdel(recording)
		core_recordings = null
	return ..()

/obj/item/disk/tech_disk/os13/core/Destroy()
	set_research(null)
	return ..()

/obj/item/disk/design_disk
	name = "component design disk"
	desc = "A disk for storing device design data for construction in lathes."
	icon = 'icons/obj/cloning.dmi'
	icon_state = "datadisk2"
	item_state = "card-id"
	w_class = ITEM_SIZE_SMALL
	matter = list(DEFAULT_WALL_MATERIAL = 30, "glass" = 10)
	var/datum/design/blueprint

// Named entries and reveal edges from the archived Scientific Overseer wiki.
/proc/research_technology_types()
	. = list()
	var/os13 = istype(GLOB.using_map, /datum/map/alpha)
	for(var/tech_type in subtypesof(/datum/tech))
		if(tech_type == /datum/tech/os13)
			continue
		if(ispath(tech_type, /datum/tech/os13) == os13)
			. += tech_type

/proc/research_network_level(tech_type)
	var/datum/tech/base = tech_type
	. = ispath(tech_type, /datum/tech/os13) ? 0 : initial(base.level)
	for(var/obj/machinery/computer/rdconsole/C in SSmachines.machinery)
		if(C.files)
			for(var/datum/tech/T in C.files.known_tech)
				if(T.id == initial(base.id) && (!ispath(tech_type, /datum/tech/os13) || T.type == tech_type))
					. = max(., T.level)
	for(var/obj/machinery/r_n_d/server/S in SSmachines.machinery)
		if(istype(S, /obj/machinery/r_n_d/server/centcom) || !S.files)
			continue
		for(var/datum/tech/T in S.files.known_tech)
			if(T.id == initial(base.id) && (!ispath(tech_type, /datum/tech/os13) || T.type == tech_type))
				. = max(., T.level)

/proc/research_archive_available(tech_type)
	if(!(tech_type in research_technology_types()))
		return FALSE
	if(!ispath(tech_type, /datum/tech/os13) || research_network_level(tech_type) > 0)
		return TRUE
	var/datum/tech/os13/T = new tech_type
	. = T.initially_available
	if(!. && length(T.requires_technologies))
		. = TRUE
		for(var/required_type in T.requires_technologies)
			if(research_network_level(required_type) <= 0)
				. = FALSE
				break
	qdel(T)

/proc/os13_research_designs()
	var/static/list/catalogue = list(
		/datum/design/item/disk/tech/os13 = null,
		/datum/design/item/disk/design = null,
		/datum/design/item/powercell/basic = /datum/tech/os13/battery,
		/datum/design/item/powercell/high = /datum/tech/os13/energy_cell,
		/datum/design/item/solar_panel = /datum/tech/os13/solar_panel,
		/datum/design/item/solar_panel/advanced = /datum/tech/os13/improved_solar_panel,
		/datum/design/item/os13_trinet_helmet = /datum/tech/os13/space_suit,
		/datum/design/item/os13_trinet_suit = /datum/tech/os13/space_suit,
		/datum/design/item/os13_space_boots = /datum/tech/os13/space_suit,
		/datum/design/item/os13_magnetic_boots = /datum/tech/os13/space_suit_mk2,
		/datum/design/item/os13_distress_beacon = /datum/tech/os13/distress_beacon,
		/datum/design/item/os13_tnc_laser = /datum/tech/os13/laser_gun,
		/datum/design/item/os13_heavy_gravpulser = /datum/tech/os13/heavy_gravpulser,
		/datum/design/item/os13_stun_mine = /datum/tech/os13/stun_mine,
		/datum/design/item/os13_energy_gun = /datum/tech/os13/energy_gun,
		/datum/design/item/os13_energy_sword = /datum/tech/os13/energy_sword,
		/datum/design/item/os13_advanced_fixboy = /datum/tech/os13/advanced_fixboy,
		/datum/design/item/os13_remcom = /datum/tech/os13/remcom,
		/datum/design/item/weapon/stunrevolver = /datum/tech/os13/stunner,
		/datum/design/item/weapon/stunrifle = /datum/tech/os13/stun_rifle,
		/datum/design/item/waterchip = /datum/tech/os13/water_chip,
		/datum/design/item/os13_gravcutter = /datum/tech/os13/gravcutter,
		/datum/design/item/os13_artificial_liver = /datum/tech/os13/artificial_organ,
		/datum/design/item/os13_artificial_eyeball = /datum/tech/os13/artificial_eyeball,
		/datum/design/item/os13_advanced_neural_port = /datum/tech/os13/advanced_port,
		/datum/design/item/os13_psiboost = /datum/tech/os13/psiboost
	)
	if(!istype(GLOB.using_map, /datum/map/os13classic))
		return catalogue
	var/static/list/classic_catalogue
	if(!classic_catalogue)
		classic_catalogue = catalogue.Copy()
		classic_catalogue[/datum/design/item/os13_psiboost/advanced] = /datum/tech/os13/psiboost_plus
	return classic_catalogue

/datum/tech/os13
	level = 1
	var/archive_tier = 1
	var/initially_available = TRUE
	var/list/requires_technologies = list()

/datum/tech/proc/display_level()
	return level

/datum/tech/os13/display_level()
	return archive_tier

/datum/tech/os13/icepick_mk2
	name = "ICE-Pick MK2"
	id = "os13_icepick_mk2"
	desc = "Speeds up ICE-Pick recharge by ten times."

/datum/tech/os13/icepick_mk1
	name = "ICE-Pick Mk.I"
	id = "os13_icepick_mk1"
	desc = "Software for removing information in cyberspace."
	initially_available = FALSE

/datum/tech/os13/distress_beacon
	name = "Distress Beacon"
	id = "os13_distress_beacon"
	desc = "A radio beacon for people lost in space."

/datum/tech/os13/gravcutter
	name = "Gravcutter"
	id = "os13_gravcutter"
	desc = "Allows production of Gravcutters."

/datum/tech/os13/space_suit
	name = "Space Suit"
	id = "os13_space_suit"
	desc = "A space suit with a durable glass helmet."

/datum/tech/os13/scan_mk1
	name = "Scan Mk.I"
	id = "os13_scan_mk1"
	desc = "Cyberspace scanning software."

/datum/tech/os13/battery
	name = "Battery"
	id = "os13_battery"
	desc = "A basic power cell."

/datum/tech/os13/artificial_organ
	name = "Artificial Organ"
	id = "os13_artificial_organ"
	desc = "A replacement for a natural organ."

/datum/tech/os13/solar_panel
	name = "Solar Panel"
	id = "os13_solar_panel"
	desc = "Allows production of solar panels."

/datum/tech/os13/light_armor
	name = "Intensecure Light Armor"
	id = "os13_light_armor"
	desc = "A light armor set: helmet, gloves, greaves and vest."

/datum/tech/os13/healthanalyzer
	name = "Portative Healthanalyzer"
	id = "os13_healthanalyzer"
	desc = "A portable health analyzer."

/datum/tech/os13/water_chip
	name = "Water Chip"
	id = "os13_water_chip"
	desc = "Restores the station's water supply."

/datum/tech/os13/stunner
	name = "Stunner"
	id = "os13_stunner"
	desc = "An electroshock weapon."

/datum/tech/os13/turbo_atmospherics
	name = "Turbo Atmospherics"
	id = "os13_turbo_atmospherics"
	desc = "Turbo ventilation for atmospherics machinery."

/datum/tech/os13/laser_gun
	name = "Laser Gun"
	id = "os13_laser_gun"
	desc = "A standard lethal energy weapon."
	archive_tier = 2

/datum/tech/os13/stun_mine
	name = "Stun Mine"
	id = "os13_stun_mine"
	desc = "A single-use stunning mine."
	archive_tier = 2

/datum/tech/os13/advanced_fixboy
	name = "Advanced FixBoy"
	id = "os13_advanced_fixboy"
	desc = "Remote access to atmospherics machinery."
	archive_tier = 2

/datum/tech/os13/ice_safety
	name = "ICE-Safety"
	id = "os13_ice_safety"
	desc = "Brain-damage protection and fatigue reduction for a cybertechnician."
	archive_tier = 2

/datum/tech/os13/hand_tele
	name = "Hand Tele"
	id = "os13_hand_tele"
	desc = "A personal teleportation device."
	archive_tier = 2

/datum/tech/os13/advanced_port
	name = "Advanced Schriebmann's Port"
	id = "os13_advanced_port"
	desc = "An upgraded neural implant."
	archive_tier = 3

/datum/tech/os13/satellite_coordinates
	name = "Satellite Coordinates"
	id = "os13_satellite_coordinates"
	desc = "Coordinates of the observation satellite."
	archive_tier = 3

/datum/tech/os13/advanced_cyberdeck
	name = "Advanced Cyberdeck"
	id = "os13_advanced_cyberdeck"
	desc = "A personal cyberdeck for independent research."
	archive_tier = 3

/datum/tech/os13/flamethrower
	name = "Flamethrower"
	id = "os13_flamethrower"
	desc = "A flame-projecting weapon."
	archive_tier = 4

/datum/tech/os13/antipersonnel_mine
	name = "Anti-Personnel Mine"
	id = "os13_antipersonnel_mine"
	desc = "A mine for denying enemy movement."
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/frag_grenade)

/datum/tech/os13/scan_mk2
	name = "Scan Mk.II"
	id = "os13_scan_mk2"
	desc = "Speeds up Scan recharge by ten times."
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/advanced_port)

/datum/tech/os13/energy_cell
	name = "Energy Cell"
	id = "os13_energy_cell"
	desc = "A heavy energy cell."
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/battery)

/datum/tech/os13/m41a_ammo
	name = "M41A Rifle Ammo"
	id = "os13_m41a_ammo"
	desc = "Pulse rifle ammunition."
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/m41a_rifle)

/datum/tech/os13/machine_gun_ammo
	name = "Machine Gun Ammo"
	id = "os13_machine_gun_ammo"
	desc = "Machine gun ammunition."
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/machine_gun)

/datum/tech/os13/m41a_rifle
	name = "M41A Rifle"
	id = "os13_m41a_rifle"
	desc = "A rapid-fire pulse rifle."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/stun_rifle)

/datum/tech/os13/machine_gun
	name = "Machine Gun"
	id = "os13_machine_gun"
	desc = "A machine gun."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/m41a_rifle)

/datum/tech/os13/space_suit_mk2
	name = "Space Suit Mk2"
	id = "os13_space_suit_mk2"
	desc = "An improved space suit with helmet light and magnetic boots."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/space_suit)

/datum/tech/os13/frag_grenade
	name = "Frag Grenade"
	id = "os13_frag_grenade"
	desc = "A fragmentation grenade."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/stun_mine)

/datum/tech/os13/artificial_eyeball
	name = "Artificial Eyeball"
	id = "os13_artificial_eyeball"
	desc = "A visual prosthesis."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/artificial_organ)

/datum/tech/os13/stun_rifle
	name = "Stun Rifle"
	id = "os13_stun_rifle"
	desc = "An automatic stun rifle."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/stunner)

/datum/tech/os13/energy_gun
	name = "Energy Gun"
	id = "os13_energy_gun"
	desc = "An efficient energy weapon with a stun mode."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/laser_gun)

/datum/tech/os13/remcom
	name = "RemCom Device"
	id = "os13_remcom"
	desc = "Remote access to the Bridge."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/advanced_fixboy)

/datum/tech/os13/improved_solar_panel
	name = "Improved Solar Panel"
	id = "os13_improved_solar_panel"
	desc = "A solar panel with twice the basic output."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/solar_panel)

/datum/tech/os13/assault_vest
	name = "Assault Vest"
	id = "os13_assault_vest"
	desc = "Durable armor for the arms and torso."
	archive_tier = 2
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/light_armor)

/datum/tech/os13/captains_keycard
	name = "Captain's Keycard"
	id = "os13_captains_keycard"
	desc = "A spare Captain's access card."
	archive_tier = 3
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/remcom)

/datum/tech/os13/psiboost
	name = "PsiBoost Implant"
	id = "os13_psiboost"
	desc = "Unlocks three psionic abilities after implantation."
	archive_tier = 3
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/advanced_port)

/datum/tech/os13/magpulse
	name = "Mag-Pulse Gun"
	id = "os13_magpulse"
	desc = "A weapon dangerous to station walls as well as enemies."
	archive_tier = 3
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/heavy_gravpulser)

/datum/tech/os13/outer_comms
	name = "Outer Comms"
	id = "os13_outer_comms"
	desc = "Unlocks outer communications."
	archive_tier = 3
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/hand_tele)

/datum/tech/os13/psiboost_plus
	name = "PsiBoost Implant+"
	id = "os13_psiboost_plus"
	desc = "Unlocks nine psionic abilities after implantation."
	archive_tier = 4
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/psiboost)

/datum/tech/os13/heavy_gravpulser
	name = "Heavy Gravpulser"
	id = "os13_heavy_gravpulser"
	desc = "An armor-ignoring weapon with a five-shot battery."
	archive_tier = 4
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/gravcutter)

/datum/tech/os13/heavy_armor
	name = "Heavy Armor"
	id = "os13_heavy_armor"
	desc = "A TNC combat suit."
	archive_tier = 4
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/space_suit_mk2, /datum/tech/os13/assault_vest)

/datum/tech/os13/energy_sword
	name = "Energy Sword"
	id = "os13_energy_sword"
	desc = "An energy blade."
	archive_tier = 4
	initially_available = FALSE
	requires_technologies = list(/datum/tech/os13/energy_gun)
