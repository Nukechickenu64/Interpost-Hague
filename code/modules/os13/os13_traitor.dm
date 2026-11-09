// The fixed 3022 scenario on OS13 Classic. Dynamic uses the shared traitor template independently.
/proc/os13_fixed_traitor_mode()
	if(istype(GLOB.using_map, /datum/map/os13classic) && istype(SSticker?.mode, /datum/game_mode/traitor))
		return SSticker.mode

/proc/os13_sky_veteran_name()
	var/path = "data/os13_traitor_hall_of_fame.sav"
	if(!fexists(path))
		return
	var/savefile/hall = new(path)
	var/winner
	hall["name"] >> winner
	return winner

/obj/effect/landmark/os13_traitor_cache
	name = "closed maintenance cache"

/obj/effect/landmark/os13_lifeboat_berth
	name = "lifeboat berth"

/area/security/brig/os13_classic
	name = "Brig"

/datum/os13_traitor_orders
	var/datum/mind/owner
	var/turf/simulated/open/crawlspace/cache_site
	var/obj/machinery/cryopod/lifepod/os13_lifeboat/lifeboat
	var/obj/item/os13_sabotage_bomb/bomb
	var/obj/item/os13_virus_disk/virus
	var/obj/item/os13_investigation_file/evidence
	var/evidence_location
	var/list/evidence_roles
	var/revealed = FALSE
	var/cache_opened = FALSE
	var/genetics_uploaded = FALSE
	var/launch_timer
	var/launch_time
	var/bridge_infected = FALSE
	var/escaped = FALSE
	var/bomb_detonated = FALSE
	var/victory_recorded = FALSE

/datum/os13_traitor_orders/New(datum/mind/selected)
	owner = selected
	return ..()

/datum/os13_traitor_orders/proc/setup()
	var/list/sites = list()
	for(var/obj/effect/landmark/os13_traitor_cache/marker in landmarks_list)
		var/turf/T = get_turf(marker)
		if(istype(T, /turf/simulated/open/crawlspace/maintenance) && is_station_turf(T))
			sites += T
	if(!length(sites))
		return FALSE
	var/obj/effect/landmark/os13_lifeboat_berth/berth = locate() in landmarks_list
	var/turf/dock = get_turf(berth)
	if(!is_station_turf(dock) || dock.density)
		return FALSE
	cache_site = pick(sites)
	lifeboat = new(dock)
	file_case()
	return TRUE

/datum/os13_traitor_orders/proc/restore_memory()
	var/datum/game_mode/traitor/mode = os13_fixed_traitor_mode()
	var/mob/living/carbon/human/H = owner.current
	if(mode?.os13_orders != src || GAME_STATE != RUNLEVEL_GAME || revealed || !istype(H) || H.stat == DEAD)
		return FALSE
	if(istype(H.loc, /obj/machinery/cryopod))
		addtimer(CALLBACK(src, .proc/restore_memory), 10 SECONDS)
		return FALSE
	if(!GLOB.traitors.add_antagonist(owner, do_not_equip = TRUE, do_not_announce = TRUE, preserve_appearance = TRUE, keep_living_body = TRUE))
		message_admins("The selected OS13 Traitor could not regain their memories.")
		return FALSE
	revealed = TRUE
	H.updatePig()
	return TRUE

/datum/os13_traitor_orders/proc/brief(mob/living/carbon/human/user)
	if(owner.os13_loyal_sheet_memory)
		owner.memory = replacetextEx(owner.memory, "[owner.os13_loyal_sheet_memory]<BR>", "")
		owner.os13_loyal_sheet_memory = null
	var/text = "<b>Your memories return. You are the traitor.</b><br>The Corporation may be gone, or this awakening may be an Intensecure trap. Your six-century-old orders still stand.<br>Find your stash in a closed maintenance branch on deck [cache_site.z]. Use <b>Open Cache</b> from the Traitor tab while standing on its tile.<br>Upload the mission disk at the Genetics console and plant your bomb in EVA, the Bridge or the Brig. Use the disk at the main bridge console to request the lifeboat, then upload its second payload there to block a recall. Board in the EVA compartment on deck 1 before it departs."
	if(length(evidence_roles))
		var/list/other_suspects = list()
		for(var/datum/mind/crew in SSticker.minds)
			if(crew != owner && (crew.assigned_role in evidence_roles))
				other_suspects += html_encode(crew.name)
		if(length(other_suspects))
			text += "<br>The files could also implicate [english_list(other_suspects)]."
	owner.store_memory(text)
	to_chat(user, SPAN_DANGER(text))

/datum/os13_traitor_orders/proc/can_act(mob/living/carbon/human/user)
	// Adults must be able to open the cache while voluntarily crawling.
	var/blocked = INCAPACITATION_DEFAULT & ~INCAPACITATION_FORCELYING
	return revealed && GAME_STATE == RUNLEVEL_GAME && ishuman(user) && user.mind == owner && owner.current == user && !length(user.pinned) && !user.incapacitated(blocked) && GLOB.traitors.is_antagonist(owner)

/datum/os13_traitor_orders/proc/open_cache(mob/living/carbon/human/user)
	if(!can_act(user))
		return FALSE
	if(cache_opened || user.loc != cache_site || !istype(cache_site, /turf/simulated/open/crawlspace/maintenance))
		to_chat(user, SPAN_NOTICE(cache_opened ? "I already emptied my stash." : "My stash isn't here. I need to search the closed maintenance branches."))
		return FALSE
	cache_opened = TRUE
	var/obj/item/storage/box/kit = new(cache_site)
	kit.SetName("sabotage kit")
	new /obj/item/card/emag(kit)
	bomb = new(kit)
	virus = new(kit)
	to_chat(user, SPAN_NOTICE("You extract a cryptographic sequencer, a bomb and your mission disk from the cache."))
	return TRUE

/datum/os13_traitor_orders/proc/thoughts(mob/living/carbon/human/user)
	if(!can_act(user))
		return
	if(!genetics_uploaded)
		to_chat(user, SPAN_NOTICE("I still need to upload the virus into the Genetics console."))
		return
	if(QDELETED(evidence))
		to_chat(user, SPAN_NOTICE("There is no surviving evidence file to recover."))
		return
	to_chat(user, SPAN_NOTICE("I remember the evidence I meant to destroy: [evidence.name], originally filed in [evidence_location]."))

/datum/os13_traitor_orders/proc/file_case()
	var/list/categories = os13_case_categories()
	var/list/matching = list()
	for(var/category in categories)
		if(owner.assigned_role in categories[category])
			matching += category
	if(!length(matching))
		return
	var/primary = ("JUNIOR STAFF" in matching) ? "JUNIOR STAFF" : pick(matching)
	var/list/primary_roles = categories[primary]
	matching -= primary
	var/list/narrowing = list()
	var/list/shortlists = list()
	for(var/category in matching)
		var/list/overlap = primary_roles & categories[category]
		if(length(overlap) < length(primary_roles))
			narrowing += category
			if(length(overlap) > 1)
				shortlists += category
	var/list/secondary_choices = length(shortlists) ? shortlists : (length(narrowing) ? narrowing : matching)
	var/secondary = length(secondary_choices) ? pick(secondary_choices) : null
	var/list/available = list()
	var/list/bridge_files = list()
	for(var/obj/structure/filingcabinet/cabinet in world)
		if(istype(cabinet, /obj/structure/filingcabinet/id_records) || !is_station_turf(get_turf(cabinet)))
			continue
		cabinet.os13_prepare_archive()
		for(var/obj/item/os13_investigation_file/file in cabinet)
			if(file.pages_left == 0 || file.lead_text || file.evidence_bound || file.investigating || file.followup_file_number)
				continue
			available += file
			if(istype(get_area(cabinet), /area/bridge))
				bridge_files += file
			break
	if(!length(available))
		return
	var/obj/item/os13_investigation_file/intake = pick(length(bridge_files) ? bridge_files : available)
	available -= intake
	var/obj/item/os13_investigation_file/report = intake
	if(length(available))
		report = pick_case_file(available, list(get_area(intake)))
		intake.reference_case_file(report)
		available -= report
	report.lead_text = case_clue(primary, primary_roles)
	evidence = report
	evidence_roles = primary_roles.Copy()
	if(secondary && length(available))
		var/obj/item/os13_investigation_file/corroboration = pick_case_file(available, list(get_area(intake), get_area(report)))
		var/list/secondary_roles = categories[secondary]
		report.reference_case_file(corroboration)
		corroboration.lead_text = case_clue(secondary, secondary_roles)
		evidence = corroboration
		evidence_roles &= secondary_roles
	var/area/location = get_area(evidence)
	evidence_location = location.name

/datum/os13_traitor_orders/proc/pick_case_file(list/available, list/previous_areas)
	var/list/elsewhere = list()
	for(var/obj/item/os13_investigation_file/file in available)
		if(!(get_area(file) in previous_areas))
			elsewhere += file
	return pick(length(elsewhere) ? elsewhere : available)

/datum/os13_traitor_orders/proc/case_clue(category, list/roles)
	return "The sabotage evidence implicates at least one member of [category] ([english_list(roles)])."

/datum/os13_traitor_orders/proc/bomb_site(turf/T)
	if(!isturf(T) || !is_station_turf(T) || T.density)
		return FALSE
	var/area/site = get_area(T)
	return istype(site, /area/outpost/mining_main/eva) || istype(site, /area/bridge) || istype(site, /area/security/brig/os13_classic)

/datum/os13_traitor_orders/proc/charge_ready()
	return !QDELETED(bomb) && bomb.armed && bomb.anchored && isturf(bomb.loc) && bomb_site(bomb.loc)

/datum/os13_traitor_orders/proc/request_launch()
	if(launch_timer || !lifeboat?.shuttle?.can_depart())
		return FALSE
	launch_time = world.time + 90 SECONDS
	launch_timer = addtimer(CALLBACK(src, .proc/depart), 90 SECONDS, TIMER_STOPPABLE)
	command_announcement.Announce("The lifeboat is preparing to depart. Board in EVA on deck 1.", "Lifeboat Control", do_newscast = FALSE)
	return TRUE

/datum/os13_traitor_orders/proc/cancel_launch()
	if(!launch_timer || bridge_infected)
		return FALSE
	deltimer(launch_timer)
	launch_timer = null
	command_announcement.Announce("The lifeboat launch was cancelled from the bridge.", "Lifeboat Control", do_newscast = FALSE)
	return TRUE

/datum/os13_traitor_orders/proc/depart()
	launch_timer = null
	bridge_infected = FALSE
	if(GAME_STATE != RUNLEVEL_GAME || !lifeboat?.shuttle?.can_depart())
		return FALSE
	var/mob/living/passenger = lifeboat.shuttle.secured_passenger()
	if(!passenger)
		lifeboat.audible_message(SPAN_WARNING("Lifeboat launch aborted: no living passenger secured."))
		return FALSE
	if(!lifeboat.launch())
		lifeboat.audible_message(SPAN_WARNING("Lifeboat launch aborted: no clear escape route."))
		return FALSE
	escaped = passenger == owner.current && passenger.mind == owner && !is_station_turf(get_turf(lifeboat))
	if(escaped && genetics_uploaded && charge_ready())
		bomb.activate(src)
	return TRUE

/datum/os13_traitor_orders/proc/in_custody(datum/mind/prisoner)
	var/mob/living/carbon/human/H = prisoner.current
	var/turf/T = get_turf(H)
	if(!istype(H) || H.stat == DEAD || !is_station_turf(T) || !istype(get_area(T), /area/security/brig/os13_classic))
		return FALSE
	for(var/obj/machinery/door/blast/os13/remote/door/general/door in range(5, T))
		if(door.id == "Brig" && door.density)
			return TRUE
	return FALSE

/datum/os13_traitor_orders/proc/crew_score()
	if(in_custody(owner))
		return 5
	for(var/datum/mind/crew in SSticker.minds)
		if(crew != owner && istype(crew.assigned_job, /datum/job/os13) && !player_is_antag(crew) && in_custody(crew))
			return 1
	return 0

/datum/os13_traitor_orders/proc/debrief()
	var/list/lines = list("<br><center><b>TRAITOR</b></center>", "<br><b>THE TRAITOR:</b> [html_encode(owner.name)] ([html_encode(owner.key)])")
	if(!cache_opened)
		lines += "<br><b>Failure.</b> The traitor has failed to find his hidden stash."
	else if(!bomb_detonated)
		lines += "<br><b>Failure?</b> The traitor has not executed his 600-years old orders."
	else
		lines += "<br><b>Success!</b> The traitor has executed his 600-years old orders."
		if(!victory_recorded && owner.key)
			victory_recorded = TRUE
			var/savefile/hall = new("data/os13_traitor_hall_of_fame.sav")
			hall["name"] << owner.name
			hall["key"] << owner.key
			owner.current?.unlock_achievement(new /datum/achievement/os13_sky_veteran)
	var/score = crew_score()
	lines += "<br><b>TRI-NET ORBITAL STATION 13:</b>"
	for(var/datum/mind/crew in SSticker.minds)
		if(istype(crew.assigned_job, /datum/job/os13))
			lines += "<br>[html_encode(crew.name)] &mdash; [html_encode(crew.assigned_role)]"
	switch(score)
		if(5)
			lines += "<br><b>Space success!</b> The orbital station crew has managed to capture the traitor. (+5)"
		if(1)
			lines += "<br>The orbital station crew locked up a scapegoat. (+1)"
		else
			lines += "<br>The Crew has not managed to catch the traitor. (+0)"
	return jointext(lines, "")

/datum/achievement/os13_sky_veteran
	name = "Sky Veteran Medal"
	description = "I executed my six-century-old orders aboard Orbital Station 13."
	difficulty = DIFF_HARD

/datum/objective/os13_traitor
	explanation_text = "Open the closed-tunnel cache, infect the Genetics console, and escape on the lifeboat with the station bomb set to detonate."
	var/datum/os13_traitor_orders/orders

/datum/objective/os13_traitor/check_completion()
	return orders?.bomb_detonated

/obj/machinery/cryopod/lifepod/os13_lifeboat
	parent_type = /obj/machinery/cryopod/lifepod/lifeboat
	name = "EVA lifeboat"
	desc = "A single-passenger lifeboat launched from the main bridge console."
	use_power = POWER_USE_OFF

/obj/machinery/cryopod/lifepod/os13_lifeboat/powered(chan, area/check_area)
	return TRUE

/obj/machinery/cryopod/lifepod/os13_lifeboat/check_occupant_allowed(mob/passenger)
	var/datum/os13_traitor_orders/orders = os13_fixed_traitor_mode()?.os13_orders
	return ..() && (type != /obj/machinery/cryopod/lifepod/os13_lifeboat || (orders?.lifeboat == src && orders.launch_timer))

/obj/machinery/cryopod/lifepod/os13_lifeboat/Process()
	if(occupant)
		refresh_occupant_visual()

/obj/item/os13_sabotage_bomb
	name = "sabotage bomb"
	desc = "A compact charge with a lifeboat-linked receiver. Wirecutters can sever its arming circuit."
	icon = 'icons/obj/syndieweapons.dmi'
	icon_state = "c-4small_0"
	w_class = ITEM_SIZE_NORMAL
	var/armed = FALSE

/obj/item/os13_sabotage_bomb/attack_hand(mob/user)
	if(armed)
		to_chat(user, SPAN_WARNING("The charge is fastened in place. Cut its arming wire first."))
		return
	return ..()

/obj/item/os13_sabotage_bomb/attack_self(mob/user)
	var/datum/os13_traitor_orders/orders = os13_fixed_traitor_mode()?.os13_orders
	if(!orders?.can_act(user) || orders.bomb != src || orders.escaped || armed || user.get_active_hand() != src)
		return
	var/turf/T = user.loc
	if(!orders.bomb_site(T))
		to_chat(user, SPAN_WARNING("The bomb must be planted in EVA, the Bridge or the Brig."))
		return
	user.visible_message(SPAN_WARNING("[user] begins installing [src]."))
	if(!do_after(user, 5 SECONDS, T) || QDELETED(src) || !orders.can_act(user) || orders.escaped || user.loc != T || user.get_active_hand() != src || !orders.bomb_site(T))
		return
	if(!user.unEquip(src, target = T))
		return
	anchored = TRUE
	armed = TRUE
	to_chat(user, SPAN_NOTICE("Charge armed. The receiver is waiting for the lifeboat to depart."))

/obj/item/os13_sabotage_bomb/attackby(obj/item/tool, mob/user)
	if(!armed || !istype(tool, /obj/item/wirecutters))
		return ..()
	if(!do_after(user, 3 SECONDS, src) || QDELETED(src) || QDELETED(tool) || !armed || !Adjacent(user) || tool.loc != user)
		return
	armed = FALSE
	anchored = FALSE
	icon_state = "c-4small_0"
	user.visible_message(SPAN_NOTICE("[user] cuts the arming wire on [src]."))

/obj/item/os13_sabotage_bomb/proc/activate(datum/os13_traitor_orders/orders)
	icon_state = "c-4small_1"
	visible_message(SPAN_DANGER("[src] begins flashing!"))
	addtimer(CALLBACK(src, .proc/detonate, orders), 5 SECONDS)

/obj/item/os13_sabotage_bomb/proc/detonate(datum/os13_traitor_orders/orders)
	if(GAME_STATE != RUNLEVEL_GAME || !orders.charge_ready())
		return
	orders.bomb_detonated = TRUE
	explosion(get_turf(src), 1, 2, 3, 4, 4)
	qdel(src)

/obj/item/os13_virus_disk
	name = "mission disk"
	desc = "A data disk carrying two pieces of old Tri-Net malware."
	icon = 'icons/obj/cloning.dmi'
	icon_state = "datadisk0"
	w_class = ITEM_SIZE_TINY

/obj/item/os13_virus_disk/resolve_attackby(atom/target, mob/user)
	if(!istype(target, /obj/machinery/computer/scan_consolenew) && !istype(target, /obj/machinery/computer/bridge))
		return ..()
	var/datum/os13_traitor_orders/orders = os13_fixed_traitor_mode()?.os13_orders
	if(can_upload(orders, target, user) && do_after(user, 5 SECONDS, target) && can_upload(orders, target, user))
		upload(orders, target, user)
	return TRUE

/obj/item/os13_virus_disk/proc/can_upload(datum/os13_traitor_orders/orders, obj/machinery/computer/target, mob/user)
	return !QDELETED(src) && !QDELETED(target) && orders?.virus == src && orders.can_act(user) && user.get_active_hand() == src && isturf(user.loc) && target.Adjacent(user) && target.operable() && target.powered() && is_station_turf(get_turf(target))

/obj/item/os13_virus_disk/proc/upload(datum/os13_traitor_orders/orders, obj/machinery/computer/target, mob/user)
	if(istype(target, /obj/machinery/computer/scan_consolenew) && istype(get_area(target), /area/medical/genetics))
		var/obj/machinery/computer/scan_consolenew/genetics = target
		genetics.os13_infected = TRUE
		if(!orders.genetics_uploaded)
			orders.genetics_uploaded = TRUE
		to_chat(user, SPAN_NOTICE("Genetics payload uploaded. I remember the evidence I was supposed to destroy."))
	else if(istype(target, /obj/machinery/computer/bridge) && istype(get_area(target), /area/bridge))
		if(!orders.genetics_uploaded || !orders.charge_ready())
			to_chat(user, SPAN_WARNING("Finish the Genetics upload and plant the charge before requesting the lifeboat."))
		else if(!orders.launch_timer)
			if(orders.request_launch())
				to_chat(user, SPAN_NOTICE("Launch requested. Use the disk here again to block cancellation."))
			else
				to_chat(user, SPAN_WARNING("The lifeboat is unavailable."))
		else
			orders.bridge_infected = TRUE
			to_chat(user, SPAN_NOTICE("Bridge payload uploaded. The crew can no longer cancel this launch."))
