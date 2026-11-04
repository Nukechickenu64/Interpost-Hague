/area/os13_psychocorrection_regression
	name = "Psychocorrection regression room"
	requires_power = FALSE
	dynamic_lighting = FALSE

// Control only the success roll. Timing, speech, organs, machinery and
// transaction/cancellation behavior are the actual production paths.
/obj/machinery/computer/os13_psychocorrection/regression
	var/succeed = TRUE

/obj/machinery/computer/os13_psychocorrection/regression/procedure_succeeds(mob/user)
	return succeed

/datum/os13_object_regression/proc/await_correction(obj/machinery/computer/os13_psychocorrection/console)
	for(var/i = 1, i <= 100 && console.session, i++)
		sleep(1)
	return expect(!console.session, "Psychocorrection did not release its procedure lock.")

/datum/os13_object_regression/proc/check_psychocorrection_objects()
	var/area/room = new /area/os13_psychocorrection_regression
	for(var/x = 40, x <= 49, x++)
		for(var/y = 30, y <= 38, y++)
			var/turf/tile = locate(x,y,1)
			if(x == 40 || x == 49 || y == 30 || y == 38)
				tile = tile.ChangeTurf(/turf/simulated/wall)
			else
				tile = tile.ChangeTurf(/turf/simulated/floor)
				var/datum/gas_mixture/air = tile.return_air()
				air.adjust_gas(GAS_OXYGEN, MOLES_CELLSTANDARD * 0.21)
				air.adjust_gas(GAS_NITROGEN, MOLES_CELLSTANDARD * 0.79)
				air.temperature = T20C
			room.contents.Add(tile)
	var/mob/living/carbon/human/user = new(locate(44,33,1))
	var/mob/living/carbon/human/subject = new(locate(44,35,1))
	var/mob/living/carbon/human/other = new(locate(45,33,1))
	var/obj/machinery/os13_correctional_apparatus/chair = new(locate(44,35,1))
	var/obj/machinery/computer/os13_psychocorrection/regression/console = new(locate(44,32,1))
	chair.stat = console.stat = 0
	var/obj/item/organ/internal/brain/brain = subject.os13_conditioning_brain()
	if(!expect(brain && console.link_apparatus(chair), "Psychocorrection could not link its real apparatus and organic subject."))
		return
	var/obj/item/card/id/card = new(get_turf(user))
	user.put_in_hands(card)
	card.access = list(access_engine)
	console.attackby(card, user)
	expect(console.locked && !console.begin_procedure(user, "SLEEP"), "An unrelated keycard unlocked psychocorrection.")
	card.access = list(access_medical)
	console.attackby(card, user)
	expect(!console.locked && !console.begin_procedure(user, "SLEEP"), "An empty apparatus started a procedure, or a medical keycard could not unlock it.")
	expect(chair.buckle_mob(subject) && console.begin_procedure(user, "SLEEP"), "A seated organic subject could not start actual trigger recording.")
	other.say("Sleep!")
	sleep(2)
	expect(console.session && !console.session.word && !console.session.working, "A bystander replaced the operator's mnemonic recording.")
	user.say("Sleep now!")
	sleep(2)
	expect(console.session && !console.session.word, "A phrase was accepted as a single mnemonic word.")
	user.say("Sleep!")
	sleep(2)
	expect(console.session?.word == "sleep" && console.session.working && !brain.os13_conditioned_triggers, "Actual spoken recording failed or installed conditioning before the procedure finished.")
	await_correction(console)
	expect(brain.os13_conditioned_triggers?["SLEEP"] == "sleep", "Completed Sleep procedure did not condition the actual brain.")
	world.log << "OS13_OBJECT_CHECK: physical psychocorrection apparatus, keycards, seating and actual spoken mnemonic recording"

	chair.unbuckle_mob()
	subject.forceMove(locate(45,33,1))
	var/obj/item/screwdriver/held = new(get_turf(subject))
	subject.put_in_hands(held)
	user.say("Oversleep!")
	sleep(2)
	expect(!subject.sleeping && held.loc == subject, "A substring accidentally activated Sleep conditioning.")
	user.say("Sleep!")
	sleep(2)
	expect(subject.sleeping && subject.resting && isturf(held.loc) && subject.os13_conditioning_brain() == brain, "Spoken Sleep after leaving the apparatus did not cause real sleep and inventory release.")
	subject.sleeping = 0
	subject.resting = FALSE
	subject.set_stat(CONSCIOUS)
	brain.os13_next_conditioned_trigger = 0
	subject.sdisabilities |= DEAF
	expect(!subject.os13_receive_mnemonic("Sleep!", user, user.get_default_language()) && !subject.sleeping, "A deaf subject responded to an unheard mnemonic.")
	subject.sdisabilities &= ~DEAF
	user.forceMove(locate(47,36,2))
	expect(!subject.os13_receive_mnemonic("Sleep!", user, user.get_default_language()), "A trigger crossed station decks.")
	user.forceMove(locate(44,33,1))
	world.log << "OS13_OBJECT_CHECK: persistent brain-bound Sleep, actual local speech, whole-word matching and hearing/deck isolation"

	for(var/mode in list("COMBAT", "PANIC"))
		subject.sleeping = 0
		subject.resting = FALSE
		subject.set_stat(CONSCIOUS)
		subject.forceMove(get_turf(chair))
		chair.buckle_mob(subject)
		expect(console.begin_procedure(user, mode), "[mode] recording could not start.")
		var/word = mode == "COMBAT" ? "Fight" : "Fear"
		user.say("[word]!")
		await_correction(console)
		expect(brain.os13_conditioned_triggers[mode] == lowertext(word), "[mode] procedure did not persist its own mnemonic.")
		chair.unbuckle_mob()
		subject.forceMove(locate(45,33,1))
		brain.os13_next_conditioned_trigger = 0
		user.say("[word]!")
		sleep(2)
		if(mode == "COMBAT")
			expect(subject.combat_mode, "Combat mnemonic did not enable actual combat mode.")
			expect(!subject.os13_receive_mnemonic("Fight!", user, user.get_default_language()) && subject.combat_mode, "Trigger cooldown failed or repeated combat activation toggled combat off.")
		else
			expect(istype(subject.events["os13_conditioned_panic"], /datum/happiness_event/os13_conditioned_panic), "Panic mnemonic did not apply its actual fear event.")
	world.log << "OS13_OBJECT_CHECK: separate Combat/Panic conditioning, actual combat/fear effects and bounded retriggering"

	subject.forceMove(get_turf(chair))
	chair.buckle_mob(subject)
	var/previous_revision = brain.os13_conditioning_revision
	console.succeed = FALSE
	console.begin_procedure(user, "SLEEP")
	user.say("Different!")
	await_correction(console)
	expect(brain.os13_conditioned_triggers["SLEEP"] == "sleep" && brain.os13_conditioning_revision == previous_revision, "Failed psychocorrection overwrote a working mnemonic.")
	console.succeed = TRUE
	console.begin_procedure(user, "SLEEP")
	user.say("Fight!")
	sleep(2)
	expect(console.session && !console.session.word, "Conflicting trigger words were installed for different responses.")
	console.cancel_procedure("Test cancellation.")
	console.begin_procedure(user, "PANIC")
	user.say("Abandon!")
	sleep(2)
	chair.unbuckle_mob()
	expect(!console.session && brain.os13_conditioned_triggers["PANIC"] == "fear", "Unbuckling failed to cancel pending neural work.")
	subject.forceMove(get_turf(chair))
	chair.buckle_mob(subject)
	console.begin_procedure(user, "SLEEP")
	user.say("Power!")
	sleep(2)
	chair.stat = NOPOWER
	console.Process()
	expect(!console.session && brain.os13_conditioned_triggers["SLEEP"] == "sleep", "A transient apparatus outage did not cancel pending work.")
	user.forceMove(locate(44,34,1))
	chair.attack_hand(user)
	expect(!subject.buckled && !chair.buckled_mob, "An unpowered apparatus trapped its subject behind the machinery interaction check.")
	user.forceMove(locate(44,33,1))
	chair.stat = 0
	chair.buckle_mob(subject)
	console.begin_procedure(user, "SLEEP")
	card.access = list()
	console.Process()
	expect(!console.session, "Losing operator credentials retained the recording session.")
	card.access = list(access_medical)
	console.begin_procedure(user, "SLEEP")
	console.attackby(card, user)
	expect(console.locked && !console.session, "Keycard locking retained a pending procedure.")
	console.attackby(card, user)
	world.log << "OS13_OBJECT_CHECK: failed/conflicting procedures preserve state; unbuckling, outages, credentials and locks cancel work"

	// Old sleeping jobs must not overwrite a later successful clear.
	expect(console.begin_procedure(user, "CLEAR"), "Conditioning clear could not start.")
	await_correction(console)
	expect(!brain.os13_conditioned_triggers && !subject.events["os13_conditioned_panic"], "Completed clear did not remove exactly this conditioning and fear event.")
	console.begin_procedure(user, "COMBAT")
	user.say("Deleted!")
	sleep(2)
	qdel(console)
	expect(!chair.console && !brain.os13_conditioned_triggers, "Destroying the console retained a pending write or apparatus link.")
	qdel(chair)
	expect(!subject.buckled, "Destroyed apparatus left its subject buckled to a deleted machine.")
	qdel(held)
	qdel(user)
	qdel(subject)
	qdel(other)
	world.log << "OS13_OBJECT_CHECK: conditioning reversal, stale-job isolation and console/apparatus destruction cleanup"
