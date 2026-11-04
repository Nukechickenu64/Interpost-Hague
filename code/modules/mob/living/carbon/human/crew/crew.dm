/proc/crew_spawn_turf(var/datum/job/job)
	var/obj/start = job_master.get_roundstart_spawnpoint(job.title)
	if(start && isturf(start.loc))
		var/turf/candidate = crew_spawn_candidate(get_turf(start))
		if(candidate)
			return candidate
	var/datum/spawnpoint/point = get_job_restricted_spawnpoint(job.title)
	if(point && LAZYLEN(point.turfs))
		for(var/turf/T in point.turfs)
			var/turf/candidate = crew_spawn_candidate(T)
			if(candidate)
				return candidate
	for(var/spawn_name in GLOB.using_map.allowed_spawns)
		point = spawntypes()[spawn_name]
		if(point && point.check_job_spawning(job.title) && LAZYLEN(point.turfs))
			for(var/turf/T in point.turfs)
				var/turf/candidate = crew_spawn_candidate(T)
				if(candidate)
					return candidate
	return null

/proc/crew_spawn_candidate(var/turf/start)
	if(!start)
		return null
	var/list/candidates = list(start)
	candidates += orange(1, start)
	for(var/turf/T in candidates)
		if(crew_safe_turf(T) && !T.contains_dense_objects() && !(locate(/mob/living) in T))
			return T
	return null

/proc/crew_can_staff_captain()
	var/datum/job/job = job_master.GetJob("Captain")
	return job && !job.opposition && job.spawn_positions != 0 && crew_spawn_turf(job)

/datum/crew_roster
	var/list/members = list()
	var/list/claims = list()

/datum/crew_roster/proc/populate()
	for(var/datum/job/job in job_master.occupations)
		// Nonhuman and opposition jobs need their own controllers, not disguised human substitutes.
		if(job.opposition || (job.department_flag & MSC) || job.title in list("AI", "Cyborg", "Robot", "Greyhound"))
			continue
		var/vacancies = job.spawn_positions == -1 ? (job.current_positions ? 0 : 1) : max(0, job.spawn_positions - job.current_positions)
		for(var/i = 1 to vacancies)
			var/turf/start = crew_spawn_turf(job)
			if(!start)
				log_and_message_admins("AI crew could not fill [job.title]: no valid job spawnpoint.", null)
				break
			var/mob/living/carbon/human/crew/H = new(start)
			H.mind_initialize()
			// Clientless helpers must not enter the player antagonist selection pool.
			SSticker.minds -= H.mind
			H.mind.assigned_job = job
			H.mind.assigned_role = job.title
			H.job = job.title
			H.age = max(job.minimum_character_age, job.ideal_character_age)
			H.mind.religion_antagonist_rolled = TRUE
			job.initialize_character(H)
			H.job_character_initialized = TRUE
			if(!job.equip(H))
				log_and_message_admins("AI crew could not equip [job.title]; the NPC was not spawned.", null)
				qdel(H)
				break
			var/obj/item/card/id/card = H.GetIdCard()
			if(card)
				card.access = job.get_access()
			H.equip_medical_bracelet()
			job.apply_fingerprints(H)
			members += H
			H.brain = new(H, src, job)
			if(job.create_record)
				CreateModularRecord(H)
				file_crew_id(H)
			START_PROCESSING(SScrew, H.brain)
	to_world(SPAN_NOTICE("AI crew support: [members.len] crew members have joined. Use the AI Crew Orders verb to direct them. Advanced job automation is still experimental."))
	log_and_message_admins("Round-start AI crew populated [members.len] vacant crew positions.", null)

/datum/crew_roster/proc/has_captain()
	for(var/mob/living/carbon/human/crew/H in members)
		if(H.job == "Captain" && H.stat != DEAD)
			return TRUE
	return FALSE

/datum/crew_roster/proc/claim(var/atom/target, var/datum/crew_ai/worker)
	var/datum/crew_ai/other = claims[target]
	if(other && !QDELETED(other) && other != worker)
		return FALSE
	claims[target] = worker
	return TRUE

/datum/crew_roster/proc/release(var/datum/crew_ai/worker)
	for(var/atom/target in claims.Copy())
		if(claims[target] == worker || QDELETED(target))
			claims -= target

/mob/living/carbon/human/crew
	var/datum/crew_ai/brain

/mob/living/carbon/human/crew/Initialize()
	. = ..()
	gender = pick(MALE, FEMALE)
	randomize_skin_tone()
	randomize_hair_style()
	randomize_hair_color()
	randomize_eye_color()
	fully_replace_character_name(species.get_random_name(gender))
	if(!zone_sel)
		zone_sel = new /obj/screen/zone_sel(null)
	a_intent = I_HELP

/mob/living/carbon/human/crew/Destroy()
	if(brain)
		brain.roster.members -= src
		STOP_PROCESSING(SScrew, brain)
		QDEL_NULL(brain)
	return ..()

/mob/living/carbon/human/crew/ssd_check()
	return FALSE

/mob/living/carbon/human/crew/setMoveCooldown(var/timeout)
	if(brain && brain.mover)
		brain.mover.move_cooldown_until = max(brain.mover.move_cooldown_until, world.time + timeout)
	return ..()

/datum/crew_ai
	var/mob/living/carbon/human/crew/owner
	var/datum/crew_roster/roster
	var/datum/job/job
	var/datum/humanized_mover/crew/mover
	var/atom/work_target
	var/work_kind
	var/task_deadline = 0
	var/next_think = 0
	var/acting = FALSE
	var/status = "Looking for work"
	var/list/priorities = list("Medical" = 1, "Engineering" = 2, "Logistics" = 2, "Gardening" = 2, "Cleaning" = 3)
	var/list/avoided = list()
	var/obj/item/task_supply
	var/logistics_step
	var/order = "Work"
	var/atom/order_target
	var/mob/order_user
	var/turf/delivery
	var/obj/item/cargo
	var/datum/turbolift/ride
	var/datum/turbolift_floor/boarding_floor
	var/datum/turbolift_floor/exit_floor
	var/next_lift_call = 0
	var/boarding = FALSE

/datum/crew_ai/New(var/mob/living/carbon/human/crew/H, var/datum/crew_roster/R, var/datum/job/J)
	..()
	owner = H
	roster = R
	job = J
	mover = new(H)

/datum/crew_ai/Destroy()
	roster.release(src)
	owner = null
	roster = null
	job = null
	work_target = null
	order_target = null
	order_user = null
	cargo = null
	QDEL_NULL(mover)
	return ..()

/datum/crew_ai/Process()
	if(QDELETED(owner) || owner.stat == DEAD)
		roster.release(src)
		status = "Dead"
		return PROCESS_KILL
	if(GAME_STATE != RUNLEVEL_GAME)
		return
	if(owner.client)
		if(work_target || order != "Work" || cargo)
			cancel_order()
		status = "Player controlled"
		return
	if(acting)
		return
	if(order != "Work" && order != "Hold position" && world.time > task_deadline)
		fail_task("The order timed out.")
		return
	if(owner.stat != CONSCIOUS || (!mover.crawling && owner.incapacitated()) || owner.restrained() || owner.buckled)
		if(work_target)
			finish_task()
		status = "Unable to work"
		return
	if(owner.resting && !mover.crawling)
		owner.resting = FALSE
		owner.update_canmove()
	if(world.time >= next_think)
		next_think = world.time + 5 SECONDS
		for(var/atom/A in avoided.Copy())
			if(QDELETED(A) || avoided[A] <= world.time)
				avoided -= A
	if(order != "Work")
		process_order()
		return
	if(work_kind && (!work_target || QDELETED(work_target) || !work_needed(work_target, work_kind)))
		finish_task()
	if(work_target)
		if(world.time > task_deadline)
			fail_task("Could not reach or complete the task.")
			return
		perform_work()
		return
	if(world.time < task_deadline)
		return
	task_deadline = world.time + 5 SECONDS
	find_work()
	if(!work_target)
		status = "No supported work available"
		mover.idle_tick()

/datum/crew_ai/proc/finish_task()
	roster.release(src)
	work_target = null
	work_kind = null
	task_supply = null
	logistics_step = null
	reset_navigation()
	task_deadline = 0

/datum/crew_ai/proc/fail_task(var/reason)
	if(work_target && !QDELETED(work_target))
		avoided[work_target] = world.time + 1 MINUTE
	if(task_supply && !QDELETED(task_supply))
		avoided[task_supply] = world.time + 1 MINUTE
	status = reason
	if(order_user && order != "Work")
		to_chat(order_user, SPAN_WARNING("[owner]: [reason]"))
	log_debug("AI crew [owner] ([job.title]): [reason]")
	finish_task()
	task_deadline = world.time + 5 SECONDS
	order = "Work"
	order_target = null
	order_user = null
	delivery = null
	if(cargo && cargo.loc == owner)
		owner.drop_from_inventory(cargo)
	cargo = null
