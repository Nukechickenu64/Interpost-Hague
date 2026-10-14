/*
	CYBERDECK RESEARCH SYSTEM
	-------------------------
	Three linked pieces:
	1. The cyberdeck headset - worn by a Cybertechnician on their head slot.
	2. The cyberdeck chair - the technician sits/buckles into it.
	3. The cyberdeck console - only operates when a linked operator
	   (headset + buckled chair) is present. The operator selects a
	   research LEVEL (1-4), then a TECHNOLOGY from that level. The
	   water chip is a level 1 technology. Immediately after selection
	   the operator's mind is transmitted into Cyberspace (the
	   Thunderfield) to collect a data node. When the node is recovered
	   the console uploads the research data, fabricates any reward and
	   returns the operator to their body.

	The cyberspace zone map is NOT compiled in - it is loaded at runtime
	by the console from disk (maps/cyberspace/cyberzone.dmm), the same
	way away-site ruins are loaded. If no cyberspace zone has been loaded
	yet, the console boots one up on demand on a fresh z-level.
*/

#define CYBERDECK_STATE_IDLE 0
#define CYBERDECK_STATE_RUNNING 1
#define CYBERDECK_LINK_RANGE 3
#define CYBERDECK_MAP_PATH "maps/cyberspace/cyberzone.dmm"

GLOBAL_VAR_INIT(cyberspace_loaded, FALSE)
GLOBAL_LIST_EMPTY(cyberdeck_techs)

// ----------------------------------------------------------------------------
// Research technology datums. Each entry belongs to a console LEVEL (1-4).
// ----------------------------------------------------------------------------

/datum/cyberdeck_tech
	var/uid = "tech"
	var/name = "untitled technology"
	var/desc = ""
	var/level = 1          // Console tier this technology lives in, 1-4.
	var/tech_id = null     // Origin tech ID that gets improved upon a successful dive.
	var/add_level = 1      // How many levels the origin tech gains.
	var/reward_path = null // Fabricated item after a successful dive, if any.
	var/reward_name = null // Display name of the reward.

/datum/cyberdeck_tech/proc/apply_research(var/datum/research/files)
	if(!files || !tech_id)
		return
	for(var/datum/tech/KT in files.known_tech)
		if(KT.id == tech_id)
			KT.level = min(KT.level + add_level, 20)
			return

// -- LEVEL 1: Basic data extraction -----------------------------------------

/datum/cyberdeck_tech/water_chip
	uid = "water_chip"
	name = "Water Filtration Chip Design"
	desc = "Blueprints for the station-wide water control chip. Restores water service when installed in its holder."
	level = 1
	tech_id = TECH_ENGINEERING
	add_level = 1
	reward_path = /obj/item/device/waterchip
	reward_name = "the water chip"

/datum/cyberdeck_tech/core_engineering
	uid = "core_eng"
	name = "Core Engineering Schematics"
	desc = "Foundational blueprints for heavy machinery and structural integrity systems."
	level = 1
	tech_id = TECH_ENGINEERING
	add_level = 1

/datum/cyberdeck_tech/material_theory
	uid = "mat_theory"
	name = "Structural Materials Theory"
	desc = "Early-generation composite and alloy research data."
	level = 1
	tech_id = TECH_MATERIAL
	add_level = 1

/datum/cyberdeck_tech/legacy_data
	uid = "legacy_data"
	name = "Legacy Code Archives"
	desc = "Ancient operational archives. Mostly backups, but some of it still runs."
	level = 1
	tech_id = TECH_DATA
	add_level = 1

// -- LEVEL 2: Intermediate archives -----------------------------------------

/datum/cyberdeck_tech/power_cells
	uid = "power_cells"
	name = "Portable Power Cell Fabrication"
	desc = "Schematics for improved chemical energy storage."
	level = 2
	tech_id = TECH_POWER
	add_level = 1

/datum/cyberdeck_tech/composite_matrix
	uid = "mat_comp"
	name = "Composite Matrix Synthesis"
	desc = "Layer-bonding techniques for high-stress structural materials."
	level = 2
	tech_id = TECH_MATERIAL
	add_level = 2

/datum/cyberdeck_tech/medical_recovery
	uid = "bio_recovery"
	name = "Medical Database Recovery"
	desc = "Salvaged biomedical libraries, cloning assists and implant drivers."
	level = 2
	tech_id = TECH_BIO
	add_level = 1

/datum/cyberdeck_tech/em_relay
	uid = "em_relay"
	name = "Electromagnetic Relay Theory"
	desc = "Coil geometry and spectrum maps for industrial electromagnetics."
	level = 2
	tech_id = TECH_MAGNET
	add_level = 1

// -- LEVEL 3: Restricted research databanks ----------------------------------

/datum/cyberdeck_tech/phoron_protocols
	uid = "phoron_proto"
	name = "Phoron Containment Protocols"
	desc = "Handling data for the useful but remarkably uncooperative substance."
	level = 3
	tech_id = TECH_PHORON
	add_level = 1

/datum/cyberdeck_tech/combat_schematics
	uid = "combat_sch"
	name = "Weapon Systems Schematics"
	desc = "Armory fabrication data for small-arms and personal defense systems."
	level = 3
	tech_id = TECH_COMBAT
	add_level = 1

/datum/cyberdeck_tech/bluespace_topology
	uid = "blue_topo"
	name = "Bluespace Topology"
	desc = "Sub-reality geometry. The math laughs at you, but it works."
	level = 3
	tech_id = TECH_BLUESPACE
	add_level = 1

/datum/cyberdeck_tech/biotech_advanced
	uid = "bio_adv"
	name = "Advanced Biotech Protocols"
	desc = "Cutting-edge tissue engineering and organ synthesis data."
	level = 3
	tech_id = TECH_BIO
	add_level = 2

// -- LEVEL 4: Black vault compilations ---------------------------------------

/datum/cyberdeck_tech/power_advanced
	uid = "power_adv"
	name = "High-Capacity Energy Storage"
	desc = "Vault-class cells and superconductor loop designs."
	level = 4
	tech_id = TECH_POWER
	add_level = 2

/datum/cyberdeck_tech/quantum_data
	uid = "quantum_data"
	name = "Quantum Data Theory"
	desc = "Coherent storage and processing architectures from the black vault."
	level = 4
	tech_id = TECH_DATA
	add_level = 2

/datum/cyberdeck_tech/exotic_engineering
	uid = "exotic_eng"
	name = "Exotic Engineering Systems"
	desc = "Reality-straining machinery designs. Handle with gloves."
	level = 4
	tech_id = TECH_ENGINEERING
	add_level = 2

/datum/cyberdeck_tech/battlefield_calibration
	uid = "combat_adv"
	name = "Battlefield Calibration Data"
	desc = "High-end military systems telemetry harvested from deep archives."
	level = 4
	tech_id = TECH_COMBAT
	add_level = 2

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

/proc/get_cyberdeck_techs()
	if(!GLOB.cyberdeck_techs.len)
		for(var/tech_type in typesof(/datum/cyberdeck_tech) - /datum/cyberdeck_tech)
			GLOB.cyberdeck_techs += new tech_type()
	return GLOB.cyberdeck_techs

// True if any cyberspace zone has been placed in the world.
/proc/cyberspace_is_loaded()
	for(var/turf/unsimulated/wall/cyber/W in world)
		return TRUE
	return FALSE

// Pick a safe turf to materialise a diving operator's VR body.
/proc/pick_cyberspace_spawn()
	if(GLOB.thunderfield_spawns_list.len)
		var/obj/effect/landmark/spawnpoint = pick(GLOB.thunderfield_spawns_list)
		var/turf/T = get_turf(spawnpoint)
		if(T)
			return T
	for(var/turf/simulated/floor/fixed/cyber/T in world)
		return T
	return null

// Pick a safe turf for the data node, some distance from the operator.
/proc/pick_cyberspace_node_turf(var/turf/from, var/min_d = 6, var/max_d = 20)
	var/list/turfs = list()
	for(var/turf/simulated/floor/fixed/cyber/T in world)
		var/d = get_dist(T, from)
		if(d >= min_d && d <= max_d)
			turfs += T
	if(!turfs.len)
		for(var/turf/simulated/floor/fixed/cyber/T in world)
			turfs += T
	if(!turfs.len)
		return null
	return pick(turfs)

// ----------------------------------------------------------------------------
// The data node recovered by the operator inside Cyberspace.
// ----------------------------------------------------------------------------

/obj/item/cyberdeck_data
	name = "encrypted data node"
	desc = "A shimmering knot of raw datastream. Your deck hungers for it."
	icon = 'icons/misc/cyberspace.dmi'
	icon_state = "beam1"
	light_range = 2
	light_color = "#66ccff"
	var/obj/machinery/computer/cyberdeck/master_console = null
	var/dive_id = 0

/obj/item/cyberdeck_data/equipped(mob/user)
	..()
	if(QDELETED(master_console))
		qdel(src)
		return
	var/mob/living/carbon/human/vrhuman/V = user
	if(!istype(V))
		return
	if(master_console.dive_id != dive_id || master_console.dive_body != V)
		to_chat(V, SPAN_WARNING("This datastream is foreign to your deck. It disperses."))
		qdel(src)
		return
	master_console.complete_dive(V)
	qdel(src)

// ----------------------------------------------------------------------------
// The cyberdeck headset. While worn by someone sitting in a cyberdeck chair,
// the deck console can launch that person into Cyberspace.
// ----------------------------------------------------------------------------

/obj/item/clothing/head/cyberdeck/headset
	name = "cyberdeck headset"
	desc = "A slim neural induction headset with a fold-down visor. While worn by an operator seated in a cyberdeck chair, the deck console can transmit their mind into Cyberspace."
	icon_state = "cyberdeck"
	item_state = "cyberdeck"
	tint = TINT_NONE

// ----------------------------------------------------------------------------
// The cyberdeck chair. A seated, headset-wearing operator is what the console
// looks for.
// ----------------------------------------------------------------------------

/obj/structure/bed/chair/cyberdeck
	name = "cyberdeck chair"
	desc = "A reclined operator's chair bristling with neural interface cabling. It links a seated operator wearing a cyberdeck headset to the deck console."
	base_icon = "officechair_dark"
	icon_state = "officechair_dark_preview"

/obj/structure/bed/chair/cyberdeck/post_buckle_mob()
	. = ..()
	if(buckled_mob)
		var/mob/living/carbon/human/H = buckled_mob
		if(istype(H) && istype(H.head, /obj/item/clothing/head/cyberdeck))
			to_chat(H, SPAN_NOTICE("The chair's dataport clamps lock around your headset jack with a soft hum."))
			playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)

// ----------------------------------------------------------------------------
// The cyberdeck console itself.
// ----------------------------------------------------------------------------

/obj/machinery/computer/cyberdeck
	name = "\improper cyberdeck research console"
	desc = "A hulking research deck wired into the ether. Only functions while a linked operator - someone wearing a cyberdeck headset and sitting in a cyberdeck chair - is nearby. Transmits the operator into Cyberspace to retrieve research data."
	icon_keyboard = "rd_key"
	icon_screen = "rdcomp"

	var/datum/research/files = null
	var/state = CYBERDECK_STATE_IDLE
	var/selected_level = 0
	var/datum/cyberdeck_tech/pending_tech = null
	var/mob/living/carbon/human/operator_body = null
	var/datum/mind/operator_mind = null
	var/mob/living/carbon/human/vrhuman/dive_body = null
	var/dive_id = 0
	var/active_timer = null

/obj/machinery/computer/cyberdeck/New()
	..()
	files = new /datum/research/techonly(src)

/obj/machinery/computer/cyberdeck/Destroy()
	if(active_timer)
		deltimer(active_timer)
		active_timer = null
	state = CYBERDECK_STATE_IDLE
	return ..()

/obj/machinery/computer/cyberdeck/power_change()
	. = ..()
	if(stat & NOPOWER)
		abort_dive("The console lost power. Your dive was terminated.")

/obj/machinery/computer/cyberdeck/attack_hand(mob/user)
	..()
	if(stat & (BROKEN|NOPOWER))
		return
	show_menu(user)

/obj/machinery/computer/cyberdeck/Topic(href, href_list, hsrc)
	if(..())
		return
	if(src.CanUseTopic(usr, GLOB.default_state, href_list) != STATUS_INTERACTIVE)
		return
	if(get_dist(src, usr) > 1)
		return
	switch(href_list["action"])
		if("select_level")
			var/lvl = text2num(href_list["level"])
			if(lvl >= 1 && lvl <= 4)
				selected_level = lvl
		if("back")
			selected_level = 0
		if("select_tech")
			var/datum/cyberdeck_tech/T = null
			for(var/datum/cyberdeck_tech/TT in get_cyberdeck_techs())
				if(TT.uid == href_list["tech"])
					T = TT
					break
			if(!T)
				to_chat(usr, SPAN_WARNING("Unknown research target."))
				return
			if(T.level != selected_level)
				return
			begin_dive(usr, T)
		if("abort")
			abort_dive("Emergency recall: your dive was aborted from the console.")
	show_menu(usr)

// Finds a valid operator: a conscious human buckled into a cyberdeck chair
// within range, wearing a cyberdeck headset on their head slot.
/obj/machinery/computer/cyberdeck/proc/locate_operator()
	for(var/obj/structure/bed/chair/cyberdeck/chair in range(CYBERDECK_LINK_RANGE, src))
		var/mob/living/carbon/human/H = chair.buckled_mob
		if(istype(H) && H.stat == CONSCIOUS && istype(H.head, /obj/item/clothing/head/cyberdeck))
			return H
	return null

/obj/machinery/computer/cyberdeck/proc/get_known_level(var/tech_id)
	for(var/datum/tech/KT in files.known_tech)
		if(KT.id == tech_id)
			return KT.level
	return 0

/obj/machinery/computer/cyberdeck/proc/level_blurb(var/level)
	switch(level)
		if(1)
			return "Basic data extraction. Station-critical schematics and essential systems."
		if(2)
			return "Intermediate archives. Refined materials, power and medical data."
		if(3)
			return "Restricted research databanks. Hazardous-substance and weapons data."
		if(4)
			return "Black vault compilations. Exotic and esoteric research trees."
	return "Unknown"

/obj/machinery/computer/cyberdeck/proc/show_menu(var/mob/user)
	var/menu = "<div class='firstdivmood'><div class='compbox'>"
	menu += "<span class='graytext'>CYBERDECK RESEARCH CONSOLE</span><hr>"

	if(state == CYBERDECK_STATE_RUNNING)
		var/opname = operator_body ? operator_body.real_name : "operator"
		menu += "<span class='graytext'>DIVE IN PROGRESS: [opname] is in Cyberspace retrieving data for: [pending_tech ? pending_tech.name : "unknown target"].</span><br>"
		menu += "<span class='feedback'><a href='?src=\ref[src];action=abort'>ABORT DIVE (emergency recall)</a></span><hr>"
	else
		var/mob/living/carbon/human/H = locate_operator()
		if(H)
			menu += "<span class='graytext'>OPERATOR LINK: [H.real_name] - chair connection nominal, headset synchronized.</span><br>"
		else
			menu += "<span class='graytext'>NO OPERATOR LINK - a technician must sit in a cyberdeck chair within [CYBERDECK_LINK_RANGE] tiles while wearing a cyberdeck headset.</span><br>"
		menu += "<hr>"
		if(selected_level)
			menu += "<span class='graytext'>Research level selected: [selected_level] - [level_blurb(selected_level)]</span><br>"
			menu += "<span class='feedback'><a href='?src=\ref[src];action=back'>BACK TO LEVELS</a></span><hr>"
			for(var/datum/cyberdeck_tech/T in get_cyberdeck_techs())
				if(T.level != selected_level)
					continue
				var/known = T.tech_id ? get_known_level(T.tech_id) : 0
				menu += "<b>[T.name]</b> - [T.desc]<br>"
				menu += "<span class='graytext'>Improves [T.tech_id ? CallTechName(T.tech_id) : "N/A"] by +[T.add_level] (station level: [known])."
				if(T.reward_name)
					menu += " Produces: [T.reward_name]."
				menu += "</span><br>"
				menu += "<span class='feedback'><a href='?src=\ref[src];action=select_tech;tech=[T.uid]'>RESEARCH THIS TECHNOLOGY</a></span><br><br>"
		else
			menu += "<span class='graytext'>Select a research level (1-4):</span><br><br>"
			for(var/lvl in 1 to 4)
				menu += "<span class='feedback'><a href='?src=\ref[src];action=select_level;level=[lvl]'>LEVEL [lvl]</a></span> - <span class='graytext'>[level_blurb(lvl)]</span><br><br>"

	menu += "<hr><span class='graytext'>RESEARCH DATABASE</span><br>"
	for(var/datum/tech/KT in files.known_tech)
		if(KT.level > 0)
			menu += "<span class='graytext'>[KT.name]: Level [KT.level]</span><br>"
	menu += "</div></div>"
	to_chat(user, menu)

// Makes sure a cyberspace zone exists somewhere; loads one if necessary.
/obj/machinery/computer/cyberdeck/proc/ensure_cyberspace()
	if(cyberspace_is_loaded())
		return TRUE
	if(GLOB.cyberspace_loaded)
		return cyberspace_is_loaded()
	var/datum/map_template/template = new(list(CYBERDECK_MAP_PATH), "Cyberspace")
	var/turf/center = template.load_new_z()
	if(!center)
		return FALSE
	GLOB.cyberspace_loaded = TRUE
	return TRUE

/obj/machinery/computer/cyberdeck/proc/begin_dive(var/mob/user, var/datum/cyberdeck_tech/T)
	if(!T)
		to_chat(user, SPAN_WARNING("Invalid research target."))
		return
	var/mob/living/carbon/human/H = locate_operator()
	if(!H)
		to_chat(user, SPAN_WARNING("NO OPERATOR LINK. A technician must be sitting in a cyberdeck chair within [CYBERDECK_LINK_RANGE] tiles while wearing a cyberdeck headset."))
		return
	if(!H.mind)
		to_chat(user, SPAN_WARNING("[H] has no active mind to transmit."))
		return
	if(H.mind.current != H)
		to_chat(user, SPAN_WARNING("[H] is already jacked into Cyberspace."))
		return
	if(state != CYBERDECK_STATE_IDLE)
		to_chat(user, SPAN_WARNING("The deck is already running a dive."))
		return
	if(!powered())
		to_chat(user, SPAN_WARNING("The console has no power."))
		return
	if(!ensure_cyberspace())
		to_chat(user, SPAN_WARNING("Cyberspace node unreachable. Contact maintenance."))
		return
	var/turf/spawn_turf = pick_cyberspace_spawn()
	if(!spawn_turf)
		to_chat(user, SPAN_WARNING("No safe cyberspace entry point found."))
		return
	var/turf/node_turf = pick_cyberspace_node_turf(spawn_turf)
	if(!node_turf)
		to_chat(user, SPAN_WARNING("No data node placement site found in cyberspace."))
		return

	state = CYBERDECK_STATE_RUNNING
	pending_tech = T
	operator_body = H
	operator_mind = H.mind
	dive_id++

	H.mind.thunderfield_owner = H
	var/mob/living/carbon/human/vrhuman/vrbody = new /mob/living/carbon/human/vrhuman(spawn_turf)
	vrbody.vr_mind = H.mind
	dive_body = vrbody
	H.mind.transfer_to(vrbody)
	vrbody.name = H.mind.name
	vrbody.real_name = H.mind.name

	var/obj/item/cyberdeck_data/node = new /obj/item/cyberdeck_data(node_turf)
	node.master_console = src
	node.dive_id = dive_id

	playsound(src, 'sound/machines/TERMINAL_DAT.ogg', 10, 1)
	to_chat(vrbody, SPAN_WARNING("You are transmitted into Cyberspace. Retrieve the data node for: [T.name]."))
	to_chat(user, SPAN_NOTICE("Dive initiated. [H.real_name] has been transmitted into Cyberspace to collect [T.name]."))

	active_timer = addtimer(CALLBACK(src, /obj/machinery/computer/cyberdeck/proc/check_dive), 2 SECONDS)

// Periodically makes sure the dive is still nominally healthy.
/obj/machinery/computer/cyberdeck/proc/check_dive()
	if(state != CYBERDECK_STATE_RUNNING)
		return
	if(!powered())
		abort_dive("The console lost power. Your dive was terminated.")
		return
	if(!dive_body || QDELETED(dive_body))
		fail_dive("The connection to your deck was severed. Dive failed.")
		return
	active_timer = addtimer(CALLBACK(src, /obj/machinery/computer/cyberdeck/proc/check_dive), 2 SECONDS)

// Called when the operator's VR body recovers the data node.
/obj/machinery/computer/cyberdeck/proc/complete_dive(var/mob/living/carbon/human/vrhuman/V)
	if(state != CYBERDECK_STATE_RUNNING)
		return
	if(QDELETED(V) || !V.vr_mind)
		return
	if(V.vr_mind != operator_mind)
		return

	state = CYBERDECK_STATE_IDLE
	var/datum/mind/M = V.vr_mind
	var/mob/living/carbon/human/owner = M.thunderfield_owner
	var/datum/cyberdeck_tech/T = pending_tech
	pending_tech = null
	dive_body = null

	to_chat(V, SPAN_NOTICE("Data node secured! Uploading [T ? T.name : "the payload"] through the deck..."))

	if(T)
		T.apply_research(files)
		files.RefreshResearch()
		push_research()
		if(T.reward_path)
			var/obj/item/reward = new T.reward_path(loc)
			if(reward)
				if(owner)
					to_chat(owner, SPAN_NOTICE("The console's fabricator whirs and dispenses \a [reward]."))
				else
					visible_message(SPAN_NOTICE("The console's fabricator whirs and dispenses \a [reward]."))
		if(owner)
			to_chat(owner, SPAN_NOTICE("<b>[T.name]</b> researched! Station databases updated."))

	if(M && owner && owner.stat != DEAD)
		M.transfer_to(owner)
	else if(M && owner)
		M.transfer_to(owner)

	if(!QDELETED(V))
		qdel(V)
	operator_body = null
	operator_mind = null

// Dive went wrong (operator died, quit, or link was broken).
/obj/machinery/computer/cyberdeck/proc/fail_dive(var/message)
	if(state != CYBERDECK_STATE_RUNNING)
		return
	state = CYBERDECK_STATE_IDLE
	pending_tech = null
	if(dive_body && !QDELETED(dive_body))
		var/mob/living/carbon/human/vrhuman/V = dive_body
		dive_body = null
		if(V.vr_mind)
			var/mob/owner = V.vr_mind.thunderfield_owner
			if(owner && owner != V)
				V.vr_mind.transfer_to(owner)
		qdel(V)
	if(operator_body && !QDELETED(operator_body))
		to_chat(operator_body, SPAN_WARNING("[message]"))
	operator_body = null
	operator_mind = null
	dive_body = null

// Manual abort from the console.
/obj/machinery/computer/cyberdeck/proc/abort_dive(var/message)
	if(state != CYBERDECK_STATE_RUNNING)
		return
	state = CYBERDECK_STATE_IDLE
	pending_tech = null
	var/mob/living/carbon/human/vrhuman/V = dive_body
	dive_body = null
	if(V && !QDELETED(V) && V.vr_mind)
		var/mob/owner = V.vr_mind.thunderfield_owner
		if(owner)
			V.vr_mind.transfer_to(owner)
			if(message)
				to_chat(owner, SPAN_WARNING("[message]"))
		else if(message)
			to_chat(V, SPAN_WARNING("[message]"))
	else if(V && !QDELETED(V) && message)
		to_chat(V, SPAN_WARNING("[message]"))
	if(V && !QDELETED(V))
		qdel(V)
	operator_body = null
	operator_mind = null

// Push the collected research up to the centcomm server so station R&D can sync it.
/obj/machinery/computer/cyberdeck/proc/push_research()
	for(var/obj/machinery/r_n_d/server/centcom/C in SSmachines.machinery)
		for(var/datum/tech/T in files.known_tech)
			C.files.AddTech2Known(T)
		C.files.RefreshResearch()