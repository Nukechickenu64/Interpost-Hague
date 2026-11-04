// OS13 video-parity objects and machines.
// Every type below was named or shown in the archived OS13 recordings (see
// docs/os13_marshal_video_parity.md and the other parity documents) and was
// absent from this codebase. All art comes from the supplied OS13 DMI assets.
// Where a recording only shows a name, stats are conservative local tuning.

// ---------------------------------------------------------------------------
// Consoles and machines (marshal video)
// ---------------------------------------------------------------------------

// "Cerberus hits the Radar Console!" (marshal video 2:10:12, bridge)
/obj/machinery/computer/os13_radar
	name = "Radar Console"
	desc = "A bridge radar station sweeping nearby space for contacts."
	icon = 'icons/os13/objects/objects/computer.dmi'
	icon_state = "radar"
	icon_keyboard = null
	icon_screen = null
	density = 1

/obj/machinery/computer/os13_radar/update_icon()
	overlays.Cut()
	if(stat & NOPOWER)
		icon_state = "radar0"
		set_light(0)
	else
		icon_state = (stat & BROKEN) ? "radarb" : "radar"
		set_light(light_range_on, light_power_on)

/obj/machinery/computer/os13_radar/attack_hand(mob/user)
	if(..())
		return
	var/obj/effect/overmap/origin = map_sectors["[z]"]
	if(QDELETED(origin) || !GLOB.using_map.use_overmap || origin.z != GLOB.using_map.overmap_z)
		to_chat(user, SPAN_WARNING("Radar unavailable: no overmap link."))
		return
	var/obj/machinery/shipsensors/sensor
	var/list/connected_levels = GetConnectedZlevels(z)
	for(var/obj/machinery/shipsensors/candidate in SSmachines.machinery)
		if(!(candidate.z in connected_levels) || candidate.inoperable() || !candidate.use_power || !candidate.powered())
			continue
		if(candidate.health <= 0 || !candidate.in_vacuum() || candidate.range <= 0)
			continue
		if(!sensor || candidate.range > sensor.range)
			sensor = candidate
	if(!sensor)
		to_chat(user, SPAN_WARNING("Radar unavailable: no operational sensor suite."))
		return
	var/list/report = list("<b>RADAR CONTACTS</b>", "Sensor range: [sensor.range] overmap tiles.")
	var/contacts = 0
	for(var/obj/effect/overmap/contact in range(sensor.range, origin))
		if(contact == origin || QDELETED(contact) || contact.invisibility || !contact.alpha)
			continue
		var/contact_name = contact.known ? html_encode(contact.name) : "Unidentified contact"
		report += "[contact_name]: ([contact.x], [contact.y])"
		contacts++
	if(!contacts)
		report += "No contacts detected within sensor range."
	to_chat(user, jointext(report, "<br>"))

// "This is Scout Controls." (marshal video 1:04:30, scout cockpit)
/obj/machinery/computer/os13_scout_controls
	name = "Scout Controls"
	desc = "The scout vessel's flight controls, linked to its expedition navigation system."
	icon = 'icons/os13/objects/objects/computer.dmi'
	icon_state = "rcomm"
	icon_keyboard = null
	icon_screen = null
	density = 0
	var/os13_unlocked = FALSE

/obj/machinery/computer/os13_scout_controls/update_icon()
	overlays.Cut()
	if(stat & BROKEN)
		icon_state = "rcommb"
		set_light(0)
	else if(stat & NOPOWER)
		icon_state = "rcomm0"
		set_light(0)
	else
		icon_state = "rcomm"
		set_light(light_range_on, light_power_on)

/obj/machinery/computer/os13_scout_controls/attack_hand(mob/user)
	if(..())
		return
	var/datum/mining_expedition_controller/controller = os13_scout_controller(src)
	if(!os13_scout_can_use(src, user, controller, TRUE))
		return
	if(!os13_unlocked)
		os13_unlocked = TRUE
		visible_message(SPAN_NOTICE("[user] unlocks the Scout Controls!"))
	add_fingerprint(user)
	controller.show_local_menu(user, src)

// "Nash Ampert unlocks the Atmospherics Reports Console!" (marshal video 34:09)
/obj/machinery/computer/os13_atmos_reports
	name = "Atmospherics Reports Console"
	desc = "A read-only terminal collating pressure reports from the station's air alarms."
	icon = 'icons/os13/objects/objects/computer.dmi'
	icon_state = "tnc1"
	icon_keyboard = null
	icon_screen = null
	density = 1
	req_access = list(access_engine)
	var/os13_unlocked = FALSE

/obj/machinery/computer/os13_atmos_reports/update_icon()
	overlays.Cut()
	if(stat & NOPOWER)
		icon_state = "tnc10"
		set_light(0)
	else
		icon_state = (stat & BROKEN) ? "tnc1b" : "tnc1"
		set_light(light_range_on, light_power_on)
	add_os13_emissive()

/obj/machinery/computer/os13_atmos_reports/attack_hand(mob/user)
	if(..())
		return
	if(!os13_unlocked && !issilicon(user) && !isobserver(user))
		if(!allowed(user))
			to_chat(user, "<span class='warning'><b>Negative It's LOCKED.</b></span>")
			return
		os13_unlocked = TRUE
		visible_message("<span class='notice'>[user] unlocks the [initial(name)]!</span>")
	var/list/report = list("<b>ATMOSPHERICS REPORTS</b>")
	var/entries = 0
	var/list/seen_areas = list()
	for(var/obj/machinery/alarm/A in SSmachines.machinery)
		if(!isStationLevel(A.z) || A.inoperable())
			continue
		var/area/AR = get_area(A)
		if(!AR || (AR in seen_areas))
			continue
		var/turf/T = get_turf(A)
		var/datum/gas_mixture/env = T?.return_air()
		if(!env)
			continue
		if(entries >= 30)
			report += "..."
			break
		seen_areas += AR
		var/kpa = round(env.return_pressure(), 0.1)
		report += "[html_encode(AR.name)]: [kpa] kPa"
		entries++
	if(entries == 0)
		report += "No operational air alarm telemetry received."
	to_chat(user, jointext(report, "<br>"))

// ---------------------------------------------------------------------------
// Security equipment (marshal video finale)
// ---------------------------------------------------------------------------

// "IntenSecure Operative swings with IntenSecure Baton!" (2:10:06)
/obj/item/weapon/melee/baton/loaded/intensecure
	name = "IntenSecure Baton"
	desc = "A rubberized stun baton issued to IntenSecure operatives."
	icon = 'icons/os13/objects/objects/weapons/weapons.dmi'
	icon_state = "insecure_baton"
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_belt_str = 'icons/os13/mob/mob/clothing/secondary/belt.dmi'
	)

// The OS13 sheet has a single baton state; keep it through charge changes.
/obj/item/weapon/melee/baton/loaded/intensecure/update_icon()
	icon_state = "insecure_baton"
	if(status == 1)
		set_light(1.5, 2, "#ff6a00")
	else
		set_light(0)

/obj/item/weapon/melee/baton/loaded/intensecure/proc/os13_hit_message(mob/living/attacker, mob/living/target, hit_zone, aimed_zone)
	if(hit_zone != BP_R_HAND || aimed_zone != BP_R_HAND)
		return null
	return "[attacker] neatly beats [target]'s right hand with the IntenSecure Baton!"

// IntenSecure operative armor (worn by the boarding operatives)
/obj/item/clothing/suit/armor/intensecure
	name = "IntenSecure armor"
	desc = "Matte corporate body armor stamped with the IntenSecure logotype."
	icon = 'icons/os13/objects/objects/clothing/suits.dmi'
	icon_state = "insecure"
	item_state = "insecure"
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_wear_suit_str = 'icons/os13/mob/mob/clothing/suit.dmi',
		)

/obj/item/device/os13_pocketwatch
	name = "Pocketwatch"
	desc = "A small pocket timepiece."
	icon = 'icons/os13/objects/objects/weapons/personal.dmi'
	icon_state = "watch"
	item_state = "card"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	w_class = ITEM_SIZE_TINY

/obj/item/device/os13_pocketwatch/examine(mob/user)
	. = ..()
	if(isobserver(user) || get_dist(user, src) <= 5)
		to_chat(user, SPAN_NOTICE("Alas, it's [stationtime2text()]."))

/obj/item/device/os13_pocketwatch/attack_self(mob/user)
	if(user.incapacitated() || (user.get_active_hand() != src && user.get_inactive_hand() != src))
		to_chat(user, SPAN_WARNING("Hold the Pocketwatch to read it."))
		return
	user.visible_message(SPAN_NOTICE("[user] looks at their watch."), SPAN_NOTICE("Alas, it's [stationtime2text()]."))

/datum/design/item/os13_pocketwatch
	name = "Pocketwatch"
	id = "os13_pocketwatch"
	req_tech = list(TECH_MATERIAL = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/device/os13_pocketwatch
	sort_string = "VAACDC"

// Department keycards (marshal video 06:09, 18:12, 24:48, 2:14:12)
/obj/item/card/id/os13_keycard
	name = "keycard"
	desc = "A stamped OS13 department keycard."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "keycard"
	item_state = "card-id"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/card/id/os13_keycard/update_name()
	SetName(initial(name))

/obj/item/card/id/os13_keycard/bridge
	name = "Bridge Keycard"
	access = list(access_heads)

/obj/item/card/id/os13_keycard/captain
	name = "Captain Keycard"
	icon_state = "keycard2"
	access = list(access_captain, access_heads)

/obj/item/card/id/os13_keycard/science
	name = "Scientific Department Keycard"
	access = list(access_research)

/obj/item/card/id/os13_keycard/medbay
	name = "Medbay Keycard"
	access = list(access_medical)

/obj/item/card/id/os13_keycard/intensecure
	name = "IntenSecure Keycard"
	icon_state = "keycard2"
	access = list(access_security)

// "He has a Handheld Radio on his neck." (marshal video 42:00)
/obj/item/device/radio/os13_handheld
	name = "Handheld Radio"
	desc = "A rugged walkie-talkie tuned to the station bands."
	icon = 'icons/os13/objects/objects/device.dmi'
	icon_state = "walkietalkie"
	item_state = "radio"
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_wear_amulet_str = 'icons/os13/mob/mob/clothing/secondary/amulet.dmi'
	)
	slot_flags = SLOT_BELT|SLOT_AMULET

/obj/item/device/radio/os13_handheld/talk_into(mob/living/speaker, message, channel, verb = "speaks into the radio", datum/language/speaking = null)
	if(!speaker || !message)
		return 0
	if(loc != speaker || (speaker.get_active_hand() != src && speaker.get_inactive_hand() != src))
		to_chat(speaker, SPAN_WARNING("Setback. I need to be holding the radio in my hand."))
		return 0
	return ..()

/obj/item/device/radio/os13_handheld/hear_talk(mob/speaker, message, verb = "says", datum/language/speaking = null)
	if(!speaker || loc != speaker || (speaker.get_active_hand() != src && speaker.get_inactive_hand() != src))
		return
	return ..()

// "John Aburke is trying to throw the SCAN Diskette!" (marshal video 12:09)
/obj/item/disk/os13_scan
	parent_type = /obj/item/disk/tech_disk/os13
	name = "SCAN Diskette"
	desc = "A scuffed data diskette labeled S.C.A.N."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "datadisk0"
	w_class = ITEM_SIZE_TINY
	throwforce = 2
	throw_speed = 4
	throw_range = 10

/obj/item/disk/os13_scan/Initialize(mapload)
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		var/datum/tech/os13/scan_mk1/software = new
		set_research(software)

// OVR 00:09:20 shows ICE-PICK MK.I installed and its diskette containing ICE-Pick Mk.I.
/obj/item/disk/os13_icepick
	name = "ICE-PICK Diskette"
	desc = "A software diskette containing ICE-Pick Mk.I."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "datadisk0"
	w_class = ITEM_SIZE_TINY
	throwforce = 2
	throw_speed = 4
	throw_range = 10

// "Maheira X13" sidearm (marshal video 2:10:27)
/obj/item/weapon/gun/projectile/os13_maheira
	name = "\improper Maheira X13"
	desc = "A compact Maheira-pattern service pistol. Uses .45 rounds."
	icon = 'icons/os13/objects/objects/weapons/gun.dmi'
	icon_state = "pistol0"
	magazine_type = /obj/item/ammo_magazine/c45m
	allowed_magazines = /obj/item/ammo_magazine/c45m
	caliber = ".45"
	load_method = 4 // MAGAZINE; the define lives in ammunition.dm, included after this file
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)

/obj/item/weapon/gun/projectile/os13_maheira/update_icon()
	..()
	if(ammo_magazine && ammo_magazine.stored_ammo.len)
		icon_state = "pistol1"
	else
		icon_state = "pistol_empty"

// ---------------------------------------------------------------------------
// EVA equipment (marshal video 1:02:20-1:03:45)
// ---------------------------------------------------------------------------

// "This is a Tri-Net Space Helmet. Someone in the cargo department has made
// good money on you. This cheap knockoff uses cheap glass instead of sound
// polymer." (1:02:30)
/obj/item/clothing/head/helmet/space/trinet
	name = "Tri-Net Space Helmet"
	matter = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 1000)
	desc = "Someone in the cargo department has made good money on you. This cheap knockoff uses cheap glass instead of sound polymer."
	icon = 'icons/os13/objects/objects/clothing/hats.dmi'
	icon_state = "tspacehelmet"
	item_state = "tspacehelmet"
	light_overlay = null
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_head_str = 'icons/os13/mob/mob/clothing/secondary/head.dmi',
		)

/obj/item/clothing/head/helmet/space/trinet/get_icon_state(mob/user_mob, slot)
	if(slot == slot_head_str)
		return on ? "tspacehelmetL1" : "tspacehelmet"
	return ..()

/obj/item/clothing/head/helmet/space/trinet/update_icon(mob/user)
	icon_state = on ? "tspacehelmetL1" : "tspacehelmet"
	return ..()

// PIL 00:20:10: a distinct broken helmet, not an intact one with a new name.
/obj/item/clothing/head/helmet/space/trinet/broken
	name = "Broken Tri-Net Space Helmet"
	description_info = "The faceplate is broken. This helmet cannot seal against vacuum."
	icon_state = "broken_tspacehelmet"
	item_state = "broken_tspacehelmet"
	item_flags = ITEM_FLAG_THICKMATERIAL
	flags_inv = BLOCKHAIR
	body_parts_covered = HEAD
	cold_protection = 0
	heat_protection = 0
	flash_protection = FLASH_PROTECTION_NONE
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0)
	action_button_name = null
	brightness_on = 0
	item_icons = list(
		slot_l_hand_str = 'icons/os13/objects/objects/clothing/hats.dmi',
		slot_r_hand_str = 'icons/os13/objects/objects/clothing/hats.dmi',
		slot_head_str = 'icons/os13/mob/mob/clothing/secondary/head.dmi'
	)
	item_state_slots = list()

/obj/item/clothing/head/helmet/space/trinet/broken/get_icon_state(mob/user_mob, slot)
	return "broken_tspacehelmet"

/obj/item/clothing/head/helmet/space/trinet/broken/update_icon(mob/user)
	on = FALSE
	. = ..()
	icon_state = "broken_tspacehelmet"
	overlays.Cut()
	set_light(0)

/obj/item/clothing/suit/space/trinet
	name = "Tri-Net Space Suit"
	matter = list(DEFAULT_WALL_MATERIAL = 5000, "glass" = 1000)
	desc = "A mass-produced Tri-Net pressure suit. The stitching does not inspire confidence."
	icon = 'icons/os13/objects/objects/clothing/suits.dmi'
	icon_state = "tspacesuit"
	item_state = "tspacesuit"
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_wear_suit_str = 'icons/os13/mob/mob/clothing/suit.dmi',
		)

/datum/design/item/os13_trinet_helmet
	name = "Tri-Net Space Helmet"
	id = "os13_trinet_helmet"
	req_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000, "glass" = 1000)
	build_path = /obj/item/clothing/head/helmet/space/trinet
	sort_string = "VAACDK"

/datum/design/item/os13_trinet_suit
	name = "Tri-Net Space Suit"
	id = "os13_trinet_suit"
	req_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 5000, "glass" = 1000)
	build_path = /obj/item/clothing/suit/space/trinet
	sort_string = "VAACDL"

/obj/item/clothing/mask/breath/os13
	name = "Breath Mask"
	icon = 'icons/os13/objects/objects/clothing/masks.dmi'
	icon_state = "breath"
	item_state = "breath"
	item_state_slots = list(slot_l_hand_str = "m_mask", slot_r_hand_str = "m_mask")
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_wear_mask_str = 'icons/os13/mob/mob/clothing/secondary/mask.dmi'
	)

/datum/design/item/os13_breath_mask
	name = "Breath Mask"
	id = "os13_breath_mask"
	req_tech = list(TECH_MATERIAL = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500, "glass" = 250)
	build_path = /obj/item/clothing/mask/breath/os13
	sort_string = "VAACDD"

/obj/machinery/portable_atmospherics/canister/air/os13
	name = "Air Canister"
	desc = "A fixed station-air filling point. Insert a gas tank to refill it, then use an empty hand to retrieve it."
	icon = 'icons/os13/objects/objects/canister_new.dmi'
	icon_state = "air_canister"
	description_info = "This filling point draws from the station gas reserve. Use a held gas tank on it to begin filling automatically, then use an empty hand to retrieve the tank. The animated indicator shows the inserted tank's nominal gas fill, not oxygen purity. A gas analyzer can check the actual mixture."
	description_antag = "Damaging the filling point does not vent the entire connected station reserve."

/obj/machinery/portable_atmospherics/canister/air/os13/update_icon()
	overlays.Cut()
	if(destroyed || (stat & BROKEN))
		icon_state = "air_canister0"
		return
	if(QDELETED(holding) || holding.loc != src)
		icon_state = "air_canister"
		return
	var/fill = holding.remaining_gas_percent()
	var/fill_state = 0
	if(fill >= 100)
		fill_state = 100
	else if(fill >= 75)
		fill_state = 75
	else if(fill >= 50)
		fill_state = 50
	else if(fill >= 25)
		fill_state = 25
	icon_state = "air_canister[fill_state]"
	var/tank_state = "big"
	if(istype(holding, /obj/item/tank/jetpack))
		tank_state = "jetpack"
	else if(istype(holding, /obj/item/tank/emergency))
		tank_state = "emergency"
	else if(istype(holding, /obj/item/tank/oxygen/yellow) || istype(holding, /obj/item/tank/oxygen/os13) || istype(holding, /obj/item/tank/air/os13))
		tank_state = "oxygen"
	overlays += image(icon, tank_state)

/obj/machinery/portable_atmospherics/canister/air/os13/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/tank))
		if(!user || user.incapacitated() || !user.Adjacent(src) || W.loc != user)
			to_chat(user, SPAN_WARNING("Hold the tank beside the Air Canister to insert it."))
			return
		if(destroyed || (stat & BROKEN))
			to_chat(user, SPAN_WARNING("The Air Canister is damaged and cannot fill tanks."))
			return
		var/datum/gas_mixture/source = get_refill_source()
		if(!source || source.total_moles <= 0)
			to_chat(user, SPAN_WARNING("No station air is available. The tank cannot be filled until the supply is restored."))
	. = ..()

/obj/machinery/portable_atmospherics/canister/air/os13/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == holding)
		holding = null
		update_icon()

/obj/machinery/portable_atmospherics/canister/air/os13/return_air()
	if(destroyed || (stat & BROKEN))
		return air_contents
	return get_refill_source()

/obj/machinery/portable_atmospherics/canister/air/os13/examine(mob/user)
	. = ..()
	if(destroyed || (stat & BROKEN))
		to_chat(user, SPAN_WARNING("The Air Canister is damaged and cannot fill tanks."))
		return
	var/datum/gas_mixture/source = get_refill_source()
	if(!source || source.total_moles <= 0)
		to_chat(user, SPAN_WARNING("No station air is available."))
	else
		to_chat(user, SPAN_NOTICE("The station air reserve contains gas; filling also requires its output to be enabled."))
	if(!QDELETED(holding) && holding.loc == src)
		to_chat(user, SPAN_NOTICE("Inserted: [holding]. Gas remaining: [holding.remaining_gas_percent()]% of nominal fill. Use an empty hand to retrieve it."))

/obj/item/tank/oxygen/os13
	icon = 'icons/os13/objects/objects/tank.dmi'
	icon_state = "oxygen"
	item_state = "oxygen"
	gauge_icon = null
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_back_str = 'icons/os13/mob/mob/items/back.dmi'
	)

/obj/item/tank/oxygen/os13/empty
	desc = "An empty oxygen tank. Fill it with oxygen before use."
	starting_pressure = null

/datum/design/item/os13_oxygen_tank
	name = "Oxygen tank"
	desc = "An empty oxygen tank. Fill it from atmospheric equipment before use."
	id = "os13_oxygen_tank"
	req_tech = list(TECH_MATERIAL = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000)
	build_path = /obj/item/tank/oxygen/os13/empty
	sort_string = "VAACDI"

/obj/item/tank/air/os13
	name = "Gas Tank (Air Mix)"
	desc = "A portable tank for an oxygen and nitrogen air mixture."
	icon = 'icons/os13/objects/objects/tank.dmi'
	icon_state = "oxygen"
	item_state = "oxygen"
	gauge_icon = null
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_back_str = 'icons/os13/mob/mob/items/back.dmi'
	)

/obj/item/tank/air/os13/remaining_gas_message()
	return "Air mixture left: [remaining_gas_percent()]%"

/obj/item/tank/air/os13/empty
	starting_pressure = null

/datum/design/item/os13_air_mix_tank
	name = "Gas Tank (Air Mix)"
	desc = "An empty air-mixture tank. Fill it from atmospheric equipment before use."
	id = "os13_air_mix_tank"
	req_tech = list(TECH_MATERIAL = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000)
	build_path = /obj/item/tank/air/os13/empty
	sort_string = "VAACDE"

/obj/item/tank/emergency/oxygen/os13
	name = "emergency oxygentank"
	icon = 'icons/os13/objects/objects/tank.dmi'
	icon_state = "emergency"
	item_state = "emergency"
	gauge_icon = null
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_belt_str = 'icons/os13/mob/mob/clothing/secondary/belt.dmi'
	)

/obj/item/tank/emergency/oxygen/os13/empty
	desc = "A small emergency oxygen tank. Fill it with oxygen before use."
	starting_pressure = null

/datum/design/item/os13_emergency_oxygen_tank
	name = "Emergency Oxygentank"
	desc = "An empty emergency oxygen tank. Fill it before use."
	id = "os13_emergency_oxygen_tank"
	req_tech = list(TECH_MATERIAL = 1)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/tank/emergency/oxygen/os13/empty
	sort_string = "VAACDH"

/obj/item/tank/jetpack/oxygen/os13
	name = "Jetpack (Oxygen)"
	icon = 'icons/os13/objects/objects/tank.dmi'
	icon_state = "jetpack0"
	item_state = "jetpack"
	item_icons = list(
		slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi',
		slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi',
		slot_back_str = 'icons/os13/mob/mob/items/back.dmi'
	)

/obj/item/tank/jetpack/oxygen/os13/get_icon_state(mob/user_mob, slot)
	if(slot == slot_back_str)
		return on ? "jetpack1" : "jetpack0"
	return ..()

/obj/item/tank/jetpack/oxygen/os13/update_icon()
	icon_state = on ? "jetpack1" : "jetpack0"
	return ..()

/obj/item/tank/jetpack/oxygen/os13/toggle()
	. = ..()
	update_icon()

/obj/item/tank/jetpack/oxygen/os13/empty
	starting_pressure = null

/datum/design/item/os13_oxygen_jetpack
	name = "Jetpack (Oxygen)"
	desc = "An empty oxygen jetpack. Fill it before use."
	id = "os13_oxygen_jetpack"
	req_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 3000)
	build_path = /obj/item/tank/jetpack/oxygen/os13/empty
	sort_string = "VAACDF"

/obj/item/clothing/shoes/os13_space
	name = "Space Suit Boots"
	desc = "A pair of boots for use with a space suit."
	icon = 'icons/os13/objects/objects/clothing/shoes.dmi'
	icon_state = "spaceboots"
	item_state = "jackboots"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	cold_protection = FEET
	min_cold_protection_temperature = HELMET_MIN_COLD_PROTECTION_TEMPERATURE

/datum/design/item/os13_space_boots
	name = "Space Suit Boots"
	id = "os13_space_boots"
	req_tech = list(TECH_MATERIAL = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 1000)
	build_path = /obj/item/clothing/shoes/os13_space
	sort_string = "VAACDB"

/obj/item/clothing/shoes/magboots/os13
	name = "Magnetic Boots"
	icon = 'icons/os13/objects/objects/clothing/shoes.dmi'
	icon_state = "magboots"
	icon_base = null
	item_state = "jackboots"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')

/obj/item/clothing/shoes/magboots/os13/get_icon_state(mob/user_mob, slot)
	if(slot == slot_shoes_str)
		return magpulse ? "magboots1" : "magboots0"
	return ..()

/obj/item/clothing/shoes/magboots/os13/update_icon()
	icon_state = magpulse ? "magboots1" : "magboots"

/obj/item/clothing/shoes/magboots/os13/attack_self(mob/user)
	. = ..()
	update_icon()

/datum/design/item/os13_magnetic_boots
	name = "Magnetic Boots"
	id = "os13_magnetic_boots"
	req_tech = list(TECH_MATERIAL = 2, TECH_MAGNET = 2)
	build_type = PROTOLATHE
	materials = list(DEFAULT_WALL_MATERIAL = 2000)
	build_path = /obj/item/clothing/shoes/magboots/os13
	sort_string = "VAACDG"

// ---------------------------------------------------------------------------
// Medical supplies (marshal video 59:30-59:33)
// ---------------------------------------------------------------------------

/obj/item/stack/medical/bruise_pack/os13_hemostatic
	name = "Hemostatic Bandages"
	singular_name = "hemostatic bandage"
	desc = "Pressure bandages infused with a clotting agent."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "bandages2k"
	heal_brute = 3

/obj/item/stack/medical/bruise_pack/os13_bacteriophage
	name = "Bacteriophages Containing Bandages"
	singular_name = "bacteriophage bandage"
	desc = "Sterile wraps cultured with bacteriophages to suppress wound infection."
	icon = 'icons/os13/objects/objects/weapons/items.dmi'
	icon_state = "bandages2b"
	heal_brute = 2

/obj/item/stack/medical/bruise_pack/os13_bacteriophage/on_wound_bandaged(mob/user, mob/living/carbon/human/patient, obj/item/organ/external/affected, datum/wound/wound)
	patient.germ_level = max(0, patient.germ_level - 100)

// ---------------------------------------------------------------------------
// Drinks (marshal video 2:06:39; waterchip video 1:06:21, 1:09:54)
// ---------------------------------------------------------------------------

// "Symond Ravnos swallows a gulp of Diet Cola." (marshal 2:07:09)
/obj/item/reagent_containers/food/drinks/cans/dietcoo
	name = "\improper Diet Cola"
	desc = "The classic taste, allegedly. Zero sugar, zero calories, zero explanation."
	icon = 'icons/os13/objects/objects/food/food.dmi'
	icon_state = "cola"
	item_state = "cola"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	announce_drinking = TRUE
	center_of_mass = "x=16;y=10"

/obj/item/reagent_containers/food/drinks/cans/dietcoo/New()
	..()
	reagents.add_reagent(/datum/reagent/drink/space_cola, 30)

// "Magdalena fills the shot glass from Pepsi." — the type existed only as an
// examine stub; give it its OS13 can art and contents.
/obj/item/reagent_containers/food/drinks/cans/pepsi
	name = "\improper Pepsi"
	desc = "A can of space pepsi, by Robust Industries LLC."
	icon = 'icons/os13/objects/objects/food/food.dmi'
	icon_state = "pcola"
	item_state = "cola"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	announce_pouring = TRUE
	center_of_mass = "x=16;y=10"

/obj/item/reagent_containers/food/drinks/cans/pepsi/New()
	..()
	reagents.add_reagent(/datum/reagent/drink/space_cola, 30)

// ---------------------------------------------------------------------------
// Away-vessel wardrobe (marshal video 2:01:24 strip window, 1:19+)
// ---------------------------------------------------------------------------

// "Clothes: Heir's Dress" — no dedicated onmob state survives; the serving
// dress body sprite stands in when worn.
/obj/item/clothing/suit/os13_heir_dress
	name = "Heir's Dress"
	desc = "A tailored dress cut for the heir of a noble house."
	icon = 'icons/os13/objects/objects/clothing/suits.dmi'
	icon_state = "heirdress"
	item_state = "servdress"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS
	item_icons = list(
		slot_wear_suit_str = 'icons/os13/mob/mob/clothing/suit.dmi',
		)

// "Boots: Child's Jackboots"
/obj/item/clothing/shoes/jackboots/os13_child
	name = "Child's Jackboots"
	desc = "A small pair of polished jackboots."
	icon = 'icons/os13/objects/objects/clothing/shoes.dmi'
	icon_state = "jackboots"
	w_class = ITEM_SIZE_SMALL

// "Ring: Noble Ring"
/obj/item/clothing/ring/os13_noble
	name = "Noble Ring"
	desc = "A heavy signet ring carrying a noble house's crest."
	icon_state = "diamond"

// "He wears a Pumpkin on his head." (waterchip video 1:19:48)
/obj/item/clothing/head/os13_pumpkin
	name = "Pumpkin"
	desc = "A hollowed-out pumpkin. Festive, if limiting."
	icon = 'icons/os13/objects/objects/clothing/hats.dmi'
	icon_state = "pumpkin"
	item_state = "pumpkin"
	body_parts_covered = HEAD|FACE
	item_icons = list(
		slot_head_str = 'icons/os13/mob/mob/clothing/secondary/head.dmi',
		)
