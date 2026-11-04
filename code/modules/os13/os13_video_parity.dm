// OS13 video-parity systems.
// Implements behaviors documented from the three archived OS13 recordings in
// docs/os13_marshal_video_parity.md, docs/os13_engineer_video_parity.md,
// docs/os13_waterchip_video_parity.md and docs/os13_video_parity_gaps.md.
// Message strings follow the recordings; OCR-truncated tails are completed
// conservatively and flagged in the documentation.
// Opening reconstruction and scenario limits: docs/os13_extended_operations_audit.md.

GLOBAL_VAR_INIT(os13_opening_announced, FALSE)

/datum/mind
	var/os13_awakening_received = FALSE
	var/os13_loyal_sheet_received = FALSE

/datum/game_mode
	var/os13_loyal_sheets_ready = FALSE

/proc/os13_awakening_account()
	return "<p>You remember entering cryosleep aboard Orbital Station 13. An emergency has interrupted hibernation.</p><p>Lakamaka Belan's recorded account admits sabotage but claims an implant forced him to act. He mentions taking the Charon to Base-7 and warns that another saboteur remains aboard. This is his account, not proof of anyone's guilt.</p>"

/proc/os13_send_awakening(mob/living/carbon/human/H, datum/job/os13/job, joined_late)
	if(!istype(GLOB.using_map, /datum/map/alpha) || !H || !H.mind || !istype(job) || H.mind.os13_awakening_received)
		return
	var/list/lines = list("<h3>Awakening aboard Orbital Station 13</h3>", os13_awakening_account())
	lines += "<p>I am the <b>[html_encode(job.title)]</b>. [html_encode(job.job_desc)]</p>"
	if(job.supervisors)
		lines += "<p>I answer to [html_encode(job.supervisors)].</p>"
	if(istype(job, /datum/job/os13/captain))
		lines += "<p>I need to reach the bridge, read GENERAL REPORT at the main computer and gather the crew for a briefing. The report separates the recovered incident record from current station readings. WAKE STATION restores lighting and resets air-alarm thermostats; it does not repair damaged equipment. Coordinate the Marshal's investigation and the Overseer's research priorities.</p>"
	else
		lines += "<p>[joined_late ? "Other crew may already be at work. " : ""]Report to the bridge for the Captain's briefing. Recover your department's keycard and equipment; do not mistake an accusation for evidence.</p>"
	var/briefing = jointext(lines, "")
	H.mind.os13_awakening_received = TRUE
	H.mind.store_memory(briefing)
	to_chat(H, briefing)

/datum/map/alpha/send_welcome()
	if(GLOB.os13_opening_announced)
		return
	GLOB.os13_opening_announced = TRUE
	command_announcement.Announce("Emergency awakening. Available crew should report to the bridge for the Captain's briefing. Command personnel: consult GENERAL REPORT at the bridge computer and coordinate station recovery.", "Cryogenic Emergency", do_newscast = FALSE)

// ---------------------------------------------------------------------------
// Darkness stumble warning (all three recordings: "It is pitch black...")
// ---------------------------------------------------------------------------

/mob/living/carbon/human
	var/last_dark_warning = 0

/mob/living/carbon/human/Move(NewLoc, direct)
	. = ..()
	if(!. || stat != CONSCIOUS || !client || !isturf(loc))
		return
	if(world.time < last_dark_warning + 30 SECONDS)
		return
	var/turf/T = loc
	if(T.get_lumcount() <= LIGHTING_SOFT_THRESHOLD && !(see_in_dark > 2 && see_invisible))
		last_dark_warning = world.time
		to_chat(src, "<span class='warning'><i>It is pitch black. You are likely to stumble.</i></span>")

// ---------------------------------------------------------------------------
// Loyal-crew objective sheet (marshal video 11:21, engineer 12:12, waterchip 12:39)
// ---------------------------------------------------------------------------

/proc/os13_send_loyal_crew_sheet(var/mob/living/carbon/human/H)
	if(!istype(GLOB.using_map, /datum/map/alpha) || !H || !H.mind || !H.client || H.mind.os13_loyal_sheet_received)
		return
	var/datum/job/crew_job = job_master.GetJob(H.mind.assigned_role)
	if(!istype(crew_job, /datum/job/os13) || player_is_antag(H.mind)) // antagonists get their own objectives
		return
	var/list/sheet = list()
	sheet += "<span class='danger'><b>YOU ARE A LOYAL CREW MEMBER OF ORBITAL STATION 13.</b></span>"
	sheet += "<span class='warning'>We've been betrayed. The traitor is among us.</span>"
	sheet += "<b>Objective #1</b>: At the end of the shift, the traitor shall be locked in the brig as a scapegoat."
	sheet += "<b>Objective #2</b>: Defend the station from any outside threat."
	sheet += "<b>Objective #3</b>: Stay alive."
	sheet += "<span class='notice'>Reward: +5 for capturing the traitor, +1 if another crewmember was kept alive.</span>"
	var/briefing = jointext(sheet, "<br>")
	H.mind.os13_loyal_sheet_received = TRUE
	H.mind.store_memory(briefing)
	to_chat(H, briefing)

/datum/game_mode/proc/os13_distribute_loyal_crew_sheets()
	if(GAME_STATE != RUNLEVEL_GAME || !istype(GLOB.using_map, /datum/map/alpha) || !(MODE_TRAITOR in antag_tags))
		return
	os13_loyal_sheets_ready = TRUE
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		os13_send_loyal_crew_sheet(H)

// ---------------------------------------------------------------------------
// Posthibernational psychosis (marshal video 1:31:45-1:36:00)
// ---------------------------------------------------------------------------

/obj/screen/fullscreen/os13_psychosis
	icon = 'icons/mob/screen1.dmi'
	screen_loc = ui_entire_screen
	icon_state = "flash"
	alpha = 210
	layer = BLIND_LAYER

/mob/living/carbon/human
	var/posthib_psychosis = FALSE
	var/psychosis_episode_until = 0
	var/psychosis_next_spam = 0

/mob/living/carbon/human/proc/acquire_posthib_psychosis()
	if(posthib_psychosis || !client)
		return
	posthib_psychosis = TRUE
	var/list/card = list()
	card += "<span class='danger'><b>Posthibernational psychosis.</b></span>"
	card += "<span class='notice'>A frequent occurrence among those who spent too much time in cryosleep... The anxiety inside me grows, pushing me to the edge.</span>"
	card += "<span class='notice'>There are two solutions:</span>"
	card += "<span class='notice'>- DISCHARGE: Get really drunk.</span>"
	card += "<span class='notice'>2. TREATMENT: Ask the Counselor for help.</span>"
	to_chat(src, jointext(card, "<br>"))

/mob/living/carbon/human/proc/cure_posthib_psychosis(var/treatment)
	if(!posthib_psychosis)
		return
	posthib_psychosis = FALSE
	end_psychosis_episode()
	if(treatment)
		to_chat(src, "<span class='notice'>The counseling quiets the anxiety. You can concentrate again.</span>")
	else
		to_chat(src, "<span class='notice'>The drink drowns the anxiety. You can concentrate again.</span>")

/mob/living/carbon/human/proc/end_psychosis_episode()
	if(!psychosis_episode_until)
		return
	psychosis_episode_until = 0
	clear_fullscreen("os13_psychosis")

/mob/living/carbon/human/proc/handle_posthib_psychosis()
	if(!posthib_psychosis)
		return
	if(stat == DEAD)
		end_psychosis_episode()
		return
	// DISCHARGE: heavy drinking suppresses episodes and can lift the trait.
	if(chem_effects[CE_ALCOHOL] >= 2)
		if(psychosis_episode_until)
			end_psychosis_episode()
		if(prob(4))
			cure_posthib_psychosis(treatment = FALSE)
		return
	if(psychosis_episode_until)
		if(world.time >= psychosis_episode_until)
			end_psychosis_episode()
			return
		if(stat == CONSCIOUS && world.time >= psychosis_next_spam)
			psychosis_next_spam = world.time + rand(4 SECONDS, 8 SECONDS)
			var/static/list/psychosis_lines = list(
				"friends are dangerous friends are dangerous friends are dangerous friends are dangerous",
				"who do you think you are who do you think you are who do you think you are who do you think you are",
				"i'm alive you're dead i'm alive you're dead i'm alive you're dead i'm alive you're dead",
				"cannot trust anyone cannot trust anyone cannot trust anyone cannot trust anyone")
			to_chat(src, "<span class='cult'><i>[pick(psychosis_lines)]</i></span>")
		return
	// Latent trait: a conscious tick can start an episode.
	if(stat == CONSCIOUS && client && prob(0.4))
		psychosis_episode_until = world.time + rand(25 SECONDS, 40 SECONDS)
		psychosis_next_spam = 0
		overlay_fullscreen("os13_psychosis", /obj/screen/fullscreen/os13_psychosis)
		to_chat(src, "<span class='danger'><b>POSTHIBERNATIONAL PSYCHOSIS. I... feel the symptoms. Cannot concentrate, cannot trust anyone.</b></span>")
		visible_message("<span class='warning'>[src] slaps \his own face.</span>")

// TREATMENT: a counselor-type crew member talks the sufferer down.
/mob/living/carbon/human/verb/treat_psychosis()
	set name = "Treat Psychosis"
	set category = "IC"
	set src in view(1)

	var/mob/living/carbon/human/healer = usr
	if(!istype(healer) || healer == src || healer.incapacitated() || !healer.Adjacent(src))
		return
	if(!healer.mind || !(healer.mind.assigned_role in list("Psionic-Counselor", "Medical Officer", "Psychiatrist", "Chaplain", "Chief Medical Officer")))
		to_chat(healer, "<span class='warning'>You lack the counseling training to treat psychosis.</span>")
		return
	if(!posthib_psychosis)
		to_chat(healer, "<span class='notice'>[src] shows no symptoms of posthibernational psychosis.</span>")
		return
	healer.visible_message("<span class='notice'>[healer] begins a counseling session with [src].</span>")
	if(!do_after(healer, 10 SECONDS, src))
		return
	if(!posthib_psychosis)
		return
	cure_posthib_psychosis(treatment = TRUE)
	healer.visible_message("<span class='notice'>[healer] finishes the counseling session with [src].</span>")

// ---------------------------------------------------------------------------
// File-investigation minigame (marshal video 02:06-31:57)
// ---------------------------------------------------------------------------

/obj/structure/filingcabinet
	var/investigation_pages = -1        // -1: roll on first use; 0: exhausted
	var/investigation_lead_text         // mapper/admin-set evidence payoff
	var/investigation_busy = FALSE
	var/os13_archive_created = FALSE

/obj/structure/filingcabinet/verb/investigate_files()
	set name = "Investigate Files"
	set category = "Object"
	set src in oview(1)

	var/mob/living/carbon/human/user = usr
	if(!istype(user) || user.incapacitated() || !user.Adjacent(src))
		return
	if(istype(GLOB.using_map, /datum/map/alpha))
		os13_investigate_archive(user)
		return
	if(investigation_busy)
		to_chat(user, "<span class='warning'>Someone is already going through these files.</span>")
		return
	if(investigation_pages < 0)
		investigation_pages = rand(8, 48)
	if(!investigation_pages)
		to_chat(user, "<span class='notice'><b>NO LEADS HERE.</b></span>")
		return
	var/seated = istype(user.buckled, /obj/structure/bed/chair)
	if(!seated)
		to_chat(user, "<span class='notice'>It's much easier to learn the documents while sitting.</span>")
	user.visible_message("<span class='notice'>[user] begins to investigate the files!</span>")
	investigation_busy = TRUE
	var/per_step = seated ? 3 SECONDS : 6 SECONDS
	while(investigation_pages > 0)
		if(!do_after(user, per_step, src))
			investigation_busy = FALSE
			return
		investigation_pages = max(0, investigation_pages - rand(4, 9))
		if(investigation_pages > 0)
			to_chat(user, "<span class='notice'><b>[investigation_pages] PAGES LEFT!</b></span>")
	investigation_busy = FALSE
	to_chat(user, "<span class='notice'><b>0 PAGES LEFT!</b></span>")
	if(investigation_lead_text)
		to_chat(user, "<span class='danger'>You cannot believe your eyes. [investigation_lead_text]</span>")
		investigation_lead_text = null
	else
		to_chat(user, "<span class='notice'><b>NO LEADS HERE.</b></span>")

// ---------------------------------------------------------------------------
// Spoken cabin passwords (marshal video 09:36+; waterchip 01:36)
// ---------------------------------------------------------------------------

/obj/machinery/door/airlock/os13_cabin
	name = "cabin door"
	icon = 'icons/os13/objects/objects/doors/b_room.dmi'
	var/cabin_owner = "Crew"
	var/cabin_password            // five digits; randomized when unset
	var/last_cabin_hint = 0

/obj/machinery/door/airlock/os13_cabin/Initialize()
	. = ..()
	if(!cabin_password)
		cabin_password = "[rand(10000, 99999)]"
	lock()

/obj/machinery/door/airlock/os13_cabin/examine(mob/user)
	. = ..()
	to_chat(user, "<span class='notice'>It's [cabin_owner]'s cabin.</span>")

/obj/machinery/door/airlock/os13_cabin/attack_hand(mob/user)
	if(locked && world.time >= last_cabin_hint + 3 SECONDS)
		last_cabin_hint = world.time
		to_chat(user, "<span class='notice'>It's [cabin_owner]'s cabin.</span>")
	return ..()

/obj/machinery/door/airlock/os13_cabin/hear_talk(mob/M, text, verb, datum/language/speaking)
	..()
	if(!locked || !cabin_password || !M || get_dist(M, src) > 1)
		return
	if(findtext(text, cabin_password))
		audible_message("<span class='notice'><b>* YOU MAY ENTER *</b></span>", hearing_distance = 3)
		unlock()
		open()
		addtimer(CALLBACK(src, /obj/machinery/door/airlock/os13_cabin/proc/os13_cabin_secure), 10 SECONDS)

/obj/machinery/door/airlock/os13_cabin/proc/os13_cabin_secure()
	if(QDELETED(src) || locked)
		return
	close()
	lock()

// ---------------------------------------------------------------------------
// Scout Console (marshal video 1:04:48)
// ---------------------------------------------------------------------------

/obj/machinery/computer/os13_scout
	name = "Scout Console"
	desc = "The command console of a scout vessel. It accepts security codes, distress-signal sweeps and messages."
	icon = 'icons/os13/objects/objects/computer.dmi'
	icon_state = "shuttlecomms"
	icon_keyboard = null
	icon_screen = null
	density = 1
	var/last_message = "REPORT"

/obj/machinery/computer/os13_scout/update_icon()
	overlays.Cut()
	if(stat & NOPOWER)
		icon_state = "shuttlecommsm"
		set_light(0)
	else
		icon_state = (stat & BROKEN) ? "shuttlecommsb" : "shuttlecomms"
		set_light((stat & BROKEN) ? 0 : light_range_on, light_power_on)

/obj/machinery/computer/os13_scout/attack_hand(mob/user)
	if(..())
		return
	var/datum/mining_expedition_controller/controller = os13_scout_controller(src)
	if(!os13_scout_can_use(src, user, controller))
		return
	to_chat(user, "<span class='notice'>LAST MESSAGE: [html_encode(last_message)]<br>[html_encode(controller.status_text())]</span>")
	to_chat(user, "<span class='notice'>Enter your request.</span>")
	var/command = input(user, "ENTER YOUR COMMAND", "Scout Console") as null|anything in list(
		"Transmit Security Code", "Search for Distress Signals", "Send Message", "(Cancel)")
	if(!command || command == "(Cancel)")
		return
	if(!os13_scout_can_use(src, user, controller))
		return
	switch(command)
		if("Transmit Security Code")
			// Original code exchange is unresolved; acknowledge the actual authorized link.
			audible_message("<span class='notice'>[src] pings: authorized uplink acknowledged.</span>", hearing_distance = 3)
			last_message = "AUTHORIZED UPLINK: [controller.status_text()]"
			to_chat(user, SPAN_NOTICE("[html_encode(last_message)]"))
		if("Search for Distress Signals")
			search_distress(user, controller)
		if("Send Message")
			var/text = sanitize(input(user, "Enter your message:", "Scout Console") as null|text)
			if(!text)
				return
			if(!os13_scout_can_use(src, user, controller))
				return
			last_message = uppertext(text)
			minor_announcement.Announce(text, "Scout Vessel Message")
			log_say("[key_name(user)] sent a scout-console message: [text]")

// ---------------------------------------------------------------------------
// Personally locked crew monitoring console (marshal video 27:54, 42:12)
// ---------------------------------------------------------------------------

/obj/machinery/computer/crew/os13_locked
	name = "Crew Monitoring Console"
	req_access = list(access_medical)
	var/os13_unlocked = FALSE

/obj/machinery/computer/crew/os13_locked/attack_hand(mob/user)
	if(!os13_unlocked && !issilicon(user) && !isobserver(user))
		if(!allowed(user))
			to_chat(user, "<span class='warning'><b>Negative It's LOCKED.</b></span>")
			return
		os13_unlocked = TRUE
		visible_message("<span class='notice'>[user] unlocks the [initial(name)]!</span>")
	return ..()
