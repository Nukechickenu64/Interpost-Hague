/hook/startup/proc/os13_traitor_regression_log()
	fdel("tmp/os13-traitor-regression.log")
	world.log = file("tmp/os13-traitor-regression.log")
	return TRUE

SUBSYSTEM_DEF(os13_traitor_regression)
	name = "OS13 Traitor regression"
	flags = SS_NO_FIRE
	init_order = -INFINITY

/datum/controller/subsystem/os13_traitor_regression/Initialize(timeofday)
	. = ..()
	spawn(0)
		world.sleep_offline = FALSE
		var/datum/os13_traitor_regression/test = new
		test.run_checks()

/datum/os13_traitor_regression
	var/failures = 0

/datum/os13_traitor_regression/proc/expect(condition, message)
	if(!condition)
		failures++
		world.log << "TRAITOR_FAIL: [message]"

/datum/os13_traitor_regression/proc/run_checks()
	var/baseline_runtimes = GLOB.total_runtimes
	Master.SetRunLevel(RUNLEVEL_GAME)
	SSticker.can_fire = FALSE
	var/turf/genetics_access = locate(119, 110, 2)
	var/mob/living/carbon/human/traitor = new(genetics_access)
	// Isolate item and mode checks from the unrepaired station's atmosphere.
	traitor.status_flags |= GODMODE
	traitor.mind_initialize()
	traitor.mind.assigned_job = job_master.GetJob("Pilot")
	traitor.mind.assigned_role = "Pilot"
	var/mob/living/carbon/human/crew = new(genetics_access)
	crew.status_flags |= GODMODE
	crew.mind_initialize()
	crew.mind.assigned_job = job_master.GetJob("Marshal")
	crew.mind.assigned_role = "Marshal"
	SSticker.minds = list(traitor.mind, crew.mind)

	SSticker.mode = new /datum/game_mode/dynamic
	expect(!os13_fixed_traitor_mode(), "Dynamic was treated as the 3022 scenario.")
	var/datum/game_mode/traitor/mode = new
	SSticker.mode = mode
	mode.pre_setup()
	GLOB.traitors.update_current_antag_max(mode)
	expect(os13_fixed_traitor_mode() == mode && !mode.round_autoantag && !length(mode.latejoin_antag_tags) && GLOB.traitors.cur_max == 1, "Fixed mode did not constrain its lottery to one round-start traitor.")
	var/datum/os13_traitor_orders/orders = new(traitor.mind)
	mode.os13_orders = orders
	if(!orders.setup())
		expect(FALSE, "The production map could not supply a cache and lifeboat berth.")
		return finish(baseline_runtimes)
	expect(istype(get_area(orders.lifeboat), /area/outpost/mining_main/eva), "The lifeboat spawned outside the EVA compartment.")
	expect(!orders.lifeboat.check_occupant_allowed(traitor), "The traitor lifeboat accepted a passenger before a launch request.")
	expect(!GLOB.traitors.is_antagonist(traitor.mind) && !orders.open_cache(traitor) && !length(GLOB.traitors.get_porco_actions(traitor)), "The selected mind had antagonist state or powers before memory restoration.")
	check_case_files(orders, crew)

	var/turf/cell = locate(140, 137, 2)
	var/obj/machinery/door/blast/os13/remote/door/general/door = locate() in locate(140, 138, 2)
	expect(door?.id == "Brig" && istype(get_area(cell), /area/security/brig/os13_classic), "The Classic brig is not mapped to the real cell and remote door.")
	crew.forceMove(cell)
	expect(orders.crew_score() == 1 && findtext(orders.debrief(), "locked up a scapegoat"), "A living loyal scapegoat behind the closed door did not earn one point.")
	traitor.forceMove(cell)
	expect(orders.crew_score() == 5 && findtext(orders.debrief(), "failed to find his hidden stash"), "Actual capture did not outrank a scapegoat independently of stash failure.")
	var/turf/panel_tile = locate(141, 139, 2)
	var/obj/machinery/button/remote/id/panel = locate() in panel_tile
	if(!panel || panel.id != "Brig")
		expect(FALSE, "The physical Brig door had no outside control.")
		return finish(baseline_runtimes)
	crew.forceMove(panel_tile)
	var/obj/item/card/id/keycard = new(panel_tile)
	crew.put_in_active_hand(keycard)
	keycard.resolve_attackby(panel, crew)
	sleep(1 SECOND)
	expect(door.density, "An unauthorized keycard opened the Brig.")
	keycard.access = list(access_brig)
	keycard.resolve_attackby(panel, crew)
	sleep(3 SECONDS)
	expect(!door.density && !orders.crew_score(), "The Marshal could not release a prisoner using the panel or an open Brig awarded points.")
	keycard.resolve_attackby(panel, crew)
	sleep(3 SECONDS)
	expect(door.density && orders.crew_score() == 5, "The Marshal could not lock the Brig and secure the prisoner.")
	crew.unEquip(keycard, target = panel_tile)
	crew.forceMove(genetics_access)
	traitor.forceMove(genetics_access)
	world.log << "TRAITOR_CHECK: fixed mode, secret assignment, live investigation and physical custody"

	if(!orders.restore_memory())
		expect(FALSE, "Memory restoration failed to register the real antagonist.")
		return finish(baseline_runtimes)
	expect(GLOB.traitors.is_antagonist(traitor.mind) && length(GLOB.traitors.get_porco_actions(traitor)) == 2 && !traitor.mind.traitor_plant_uplink_pending, "The revealed traitor did not receive their two actions or still received the plant uplink.")
	expect(!orders.open_cache(traitor), "The cache could be opened away from the marked tunnel.")
	crew.forceMove(orders.cache_site)
	expect(!orders.open_cache(crew), "Another crew member could open the cache.")
	traitor.forceMove(orders.cache_site)
	traitor.resting = TRUE
	traitor.update_canmove()
	expect(traitor.lying && length(GLOB.traitors.get_porco_actions(traitor)) == 2, "Crawling hid the adult traitor's cache action.")
	if(!orders.open_cache(traitor) || QDELETED(orders.virus) || QDELETED(orders.bomb))
		expect(FALSE, "The cache could not be opened on the correct tile.")
		return finish(baseline_runtimes)
	expect(!orders.open_cache(traitor) && (locate(/obj/item/card/emag) in orders.virus.loc), "The cache could be reopened or did not contain its sequencer.")
	expect(findtext(orders.debrief(), "has not executed his 600-years old orders"), "An opened stash with incomplete orders had the wrong outcome.")
	world.log << "TRAITOR_CHECK: reveal, Porco actions, one cache, unfinished orders"

	var/obj/machinery/computer/scan_consolenew/genetics = locate() in locate(119, 111, 2)
	var/obj/machinery/computer/bridge/bridge = locate() in locate(125, 146, 2)
	var/turf/bridge_access = locate(125, 145, 2)
	var/obj/item/os13_virus_disk/disk = orders.virus
	var/obj/item/os13_sabotage_bomb/charge = orders.bomb
	disk.attack_hand(traitor)
	traitor.resting = FALSE
	traitor.update_canmove()
	if(!expect_upload_ready(orders, disk, genetics, traitor, genetics_access))
		return finish(baseline_runtimes)
	disk.resolve_attackby(genetics, traitor)
	expect(orders.genetics_uploaded && genetics.os13_infected, "Applying the held disk at Genetics did not upload the mission virus.")
	traitor.unEquip(disk, target = genetics_access)
	traitor.forceMove(orders.cache_site)
	charge.attack_hand(traitor)
	expect(traitor.get_active_hand() == charge, "The charge could not be picked up from its stash.")
	traitor.forceMove(genetics_access)
	charge.attack_self(traitor)
	expect(!orders.charge_ready(), "The charge armed in Genetics, outside its three compartments.")
	traitor.forceMove(bridge_access)
	charge.attack_self(traitor)
	expect(orders.charge_ready(), "The charge did not arm on the Bridge through its normal interaction. Site: [orders.bomb_site(bridge_access)]. Held: [traitor.get_active_hand() == charge]. Can act: [orders.can_act(traitor)]. Position: [traitor.loc == bridge_access].")
	charge.attack_hand(crew)
	expect(charge.loc == bridge_access, "The crew could pick up the mounted bomb without disarming it.")
	var/obj/item/wirecutters/cutters = new(bridge_access)
	crew.forceMove(bridge_access)
	crew.put_in_active_hand(cutters)
	charge.attackby(cutters, crew)
	expect(!orders.charge_ready() && !charge.anchored, "The crew could not disarm a planted charge with wirecutters.")
	charge.attack_hand(traitor)
	charge.attack_self(traitor)
	expect(orders.charge_ready(), "The recovered charge could not be replanted.")

	disk.forceMove(bridge_access)
	disk.attack_hand(traitor)
	// Exercise the upload after power restoration, independent of Classic's damaged starting grid.
	var/area/bridge_area = get_area(bridge)
	bridge_area.requires_power = FALSE
	bridge.power_change()
	if(!expect_upload_ready(orders, disk, bridge, traitor, bridge_access))
		return finish(baseline_runtimes)
	disk.resolve_attackby(bridge, traitor)
	expect(orders.lifeboat.check_occupant_allowed(traitor), "An active sabotage launch did not unlock the traitor lifeboat.")
	expect(orders.launch_timer && orders.cancel_launch(), "The first Bridge upload did not request a cancellable launch.")
	disk.resolve_attackby(bridge, traitor)
	disk.resolve_attackby(bridge, traitor)
	expect(orders.launch_timer && orders.bridge_infected && !orders.cancel_launch(), "The second Bridge upload did not lock recall.")
	deltimer(orders.launch_timer)
	expect(!orders.depart() && !orders.lifeboat.launched && !orders.escaped, "An empty lifeboat left or completed the escape.")
	world.log << "TRAITOR_CHECK: normal disk and bomb actions, launch, recall lock and empty-boat abort"

	disk.resolve_attackby(bridge, traitor)
	if(!orders.launch_timer)
		expect(FALSE, "An aborted launch could not be retried.")
		return finish(baseline_runtimes)
	orders.lifeboat.set_occupant(traitor, TRUE)
	deltimer(orders.launch_timer)
	expect(orders.depart() && orders.escaped && !orders.bomb_detonated, "Departure failed to move the passenger off-station and prime the charge.")
	sleep(6 SECONDS)
	var/datum/objective/os13_traitor/objective = locate() in traitor.mind.objectives
	expect(orders.bomb_detonated && QDELETED(charge) && objective?.check_completion() && mode.check_finished(), "Successful escape did not detonate the charge, complete the objective and resolve the mode.")
	expect(!istype(locate(125, 145, 2), /turf/simulated/floor), "The charge completed the objective without breaching the planted tile.")
	expect(findtext(orders.debrief(), "has executed his 600-years old orders") && findtext(orders.debrief(), "(+0)"), "Completed orders and crew failure did not report independently.")
	world.log << "TRAITOR_CHECK: real off-station launch, timed detonation, objective and debrief"
	finish(baseline_runtimes)

/datum/os13_traitor_regression/proc/check_case_files(datum/os13_traitor_orders/orders, mob/living/carbon/human/reader)
	var/list/categories = os13_case_categories()
	expect(length(categories) == 13, "The archive did not have Junior Staff plus twelve additional categories.")
	for(var/category in categories)
		var/list/roles = categories[category]
		expect(length(roles) > 1, "Category [category] exposes a single role.")
		for(var/role in roles)
			expect(istype(job_master.GetJob(role), /datum/job/os13), "Category [category] references an unavailable role [role].")
	var/list/archives = list()
	var/obj/item/os13_investigation_file/intake
	for(var/obj/structure/filingcabinet/cabinet in world)
		for(var/obj/item/os13_investigation_file/file in cabinet)
			archives["[file.file_number]"] = file
			if(file.followup_file_number && !file.lead_text)
				intake = file
	if(!intake)
		expect(FALSE, "The Marshal had no starting file reference.")
		return
	var/obj/item/os13_investigation_file/report = archives["[intake.followup_file_number]"]
	var/obj/item/os13_investigation_file/evidence = report ? archives["[report.followup_file_number]"] : null
	if(!report || !evidence || !evidence.lead_text)
		expect(FALSE, "A case reference did not resolve to a real evidence file.")
		return
	expect(intake.loc != report.loc && report.loc != evidence.loc && intake.loc != evidence.loc, "Case files shared a cabinet.")
	expect(findtext(report.lead_text, "JUNIOR STAFF") && !findtext(evidence.lead_text, "JUNIOR STAFF"), "The dormant Pilot did not drive both distinct clues.")
	expect(("Pilot" in orders.evidence_roles) && length(orders.evidence_roles) < 4, "The corroborating clue did not narrow Junior Staff to a truthful shortlist.")
	expect(orders.evidence == evidence, "The traitor's destruction target was unrelated to the case.")
	expect(GLOB.os13_approved_documents["[intake.file_number]"] && !GLOB.os13_approved_documents["[report.file_number]"] && !GLOB.os13_approved_documents["[evidence.file_number]"], "The bridge registry revealed a linked file location or lost the starting file.")
	var/obj/item/os13_investigation_file/unrelated = new(get_turf(reader))
	unrelated.bind_evidence()
	expect(!unrelated.lead_text, "An unrelated file duplicated a fixed case clue.")
	qdel(unrelated)
	var/turf/previous = get_turf(reader)
	reader.forceMove(get_turf(intake))
	intake.pages_left = 1
	intake.investigate(reader, intake.loc)
	expect(!intake.pages_left && !intake.followup_file_number && findtext(reader.mind.memory, "I have to check File #[report.file_number] for a clue."), "Reading the intake did not retain the number-only reference in memory.")
	reader.forceMove(previous)
	var/datum/os13_traitor_orders/other_case = new(reader.mind)
	other_case.file_case()
	expect(("Marshal" in other_case.evidence_roles) && !findtext(other_case.evidence?.lead_text, "JUNIOR STAFF"), "A non-Junior Marshal did not receive matching evidence categories.")
	qdel(other_case)

/datum/os13_traitor_regression/proc/expect_upload_ready(datum/os13_traitor_orders/orders, obj/item/os13_virus_disk/disk, obj/machinery/computer/console, mob/living/carbon/human/user, turf/position)
	user.forceMove(position)
	var/ready = disk.can_upload(orders, console, user)
	if(!ready)
		expect(FALSE, "Upload at [console] could not start. Held: [user.get_active_hand() == disk]. Can act: [orders.can_act(user)]. Adjacent: [console?.Adjacent(user)]. Power: [console?.powered()]. Operable: [console?.operable()]. Status: [user.stat], stunned [user.stunned], sleeping [user.sleeping], paralyzed [user.paralysis], resting [user.resting].")
	return ready

/datum/os13_traitor_regression/proc/finish(baseline_runtimes)
	expect(GLOB.total_runtimes == baseline_runtimes, "Native runtime during scenario regression.")
	world.log << "OS13_TRAITOR_RESULT: [failures ? "FAIL" : "PASS"] failures=[failures] new_runtimes=[GLOB.total_runtimes - baseline_runtimes] startup_runtimes=[baseline_runtimes]"
	del(world)
