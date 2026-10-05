GLOBAL_DATUM_INIT(pony_invaders, /datum/antagonist/pony, new)

/datum/antagonist/pony
	id = "pony"
	role_text = "Pony Invader"
	role_text_plural = "Pony Invaders"
	feedback_tag = "pony_objective"
	faction = "pony"
	flags = ANTAG_OVERRIDE_JOB
	hard_cap = 3
	hard_cap_round = 3
	valid_species = list("Earth Pony", "Unicorn", "Pegasus", "Thestral")
	welcome_text = "You are a pony invader. Kill all humanoids. Other ponies are your allies, not targets. Use your natural abilities and Ponish telepathy to coordinate your attack."

/datum/antagonist/pony/update_antag_mob(var/datum/mind/player, var/preserve_appearance)
	. = ..()
	if(!ishuman(player.current))
		return
	var/mob/living/carbon/human/pony = player.current
	if(preserve_appearance && istype(pony.species, /datum/species/pony))
		pony.update_dna()
		player.name = pony.real_name
		return
	pony.set_species(pick(valid_species), TRUE)
	pony.real_name = pony.species.get_random_name(pony.gender)
	pony.SetName(pony.real_name)
	pony.dna.real_name = pony.real_name
	player.name = pony.real_name

/datum/antagonist/pony/create_objectives(var/datum/mind/player, var/override = FALSE)
	if(!..())
		return
	for(var/datum/objective/pony_extermination/existing in player.objectives)
		return
	var/datum/objective/pony_extermination/objective = new
	objective.owner = player
	player.objectives += objective

/datum/objective/pony_extermination
	explanation_text = "Kill all humanoids. Leave no living non-pony humanoids anywhere. Other ponies and monkeys are not targets."

/datum/objective/pony_extermination/check_completion()
	for(var/mob/living/carbon/human/humanoid in GLOB.human_mob_list)
		if(humanoid.stat != DEAD && !istype(humanoid.species, /datum/species/pony) && !istype(humanoid.species, /datum/species/monkey))
			return FALSE
	return TRUE

/mob
	var/datum/nano_module/appearance_changer/pony_creation/pony_creation

/datum/topic_state/pony_creation/can_use_topic(var/src_object, var/mob/user)
	var/datum/nano_module/appearance_changer/pony_creation/editor = src_object
	if(!istype(editor) || QDELETED(editor) || editor.finished || !editor.owner || !user || user != editor.ghost || !user.client || user.ckey != editor.candidate_ckey || (!editor.admin_requester && !isghost(user)))
		return STATUS_CLOSE
	return STATUS_INTERACTIVE

/datum/nanoui/pony_creation/close()
	var/datum/nano_module/appearance_changer/pony_creation/editor = src_object
	. = ..()
	if(istype(editor) && !QDELETED(editor) && !editor.finished)
		qdel(editor)

/datum/nano_module/appearance_changer/pony_creation
	name = "Customize Pony"
	ui_type = /datum/nanoui/pony_creation
	flags = APPEARANCE_RACE | APPEARANCE_GENDER | APPEARANCE_SKIN | APPEARANCE_HAIR | APPEARANCE_HAIR_COLOR | APPEARANCE_EYE_COLOR | APPEARANCE_UPDATE_DNA
	var/mob/ghost
	var/client/admin_requester
	var/turf/spawn_turf
	var/finished = FALSE
	var/datum/topic_state/pony_creation/creation_state
	var/preview_image
	var/candidate_ckey
	var/expires_at

/datum/nano_module/appearance_changer/pony_creation/New(var/mob/candidate, var/turf/destination, var/client/requester)
	var/mob/living/carbon/human/dummy/mannequin/preview = new(null)
	var/datum/antagonist/pony/antag = GLOB.all_antag_types_["pony"]
	preview.set_species("Earth Pony", TRUE)
	preview.real_name = preview.species.get_random_name(preview.gender)
	preview.SetName(preview.real_name)
	..(candidate, preview, FALSE, antag.valid_species.Copy())
	ghost = candidate
	candidate_ckey = candidate.ckey
	expires_at = world.time + 5 MINUTES
	admin_requester = requester
	spawn_turf = destination
	valid_species = antag.valid_species.Copy()
	creation_state = new
	candidate.pony_creation = src
	ui_interact(candidate, state = creation_state)
	spawn(5 MINUTES)
		if(!QDELETED(src))
			qdel(src)

/datum/nano_module/appearance_changer/pony_creation/nano_host()
	return src

/datum/nano_module/appearance_changer/pony_creation/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = TRUE, var/datum/topic_state/state = GLOB.default_state)
	if(CanUseTopic(user, creation_state) != STATUS_INTERACTIVE)
		qdel(src)
		return
	return ..(user, ui_key, ui, force_open, creation_state)

/datum/nano_module/appearance_changer/pony_creation/extra_appearance_data(var/mob/user)
	if(!preview_image)
		owner.update_icons()
		var/icon/preview = getFlatIcon(owner, SOUTH, always_use_defdir = TRUE)
		preview.Scale(preview.Width() * 3, preview.Height() * 3)
		preview_image = icon2base64(preview)
	return list("pony_creation" = TRUE, "pony_name" = html_encode(owner.real_name), "pony_preview" = preview_image, "pony_time_left" = max(0, round((expires_at - world.time) / 10)))

/datum/nano_module/appearance_changer/pony_creation/Topic(href, href_list, var/datum/topic_state/state = GLOB.default_state)
	if(CanUseTopic(usr, creation_state) != STATUS_INTERACTIVE)
		return TRUE
	if(href_list["pony_cancel"])
		qdel(src)
		return TRUE
	if(href_list["pony_name"])
		var/new_name = sanitize(input(ghost, "Choose your pony's name.", "Pony Name", owner.real_name) as null|text, MAX_NAME_LEN)
		if(new_name && !QDELETED(src) && can_still_topic(creation_state))
			owner.real_name = new_name
			owner.SetName(new_name)
			update_dna()
		return TRUE
	if(href_list["pony_spawn"])
		return spawn_pony()
	. = ..(href, href_list, creation_state)
	if(!QDELETED(src))
		preview_image = null

/datum/nano_module/appearance_changer/pony_creation/proc/spawn_pony()
	var/datum/antagonist/pony/antag = GLOB.all_antag_types_["pony"]
	var/admin_spawn = admin_requester && (admin_requester in GLOB.clients) && admin_requester.holder && (admin_requester.holder.rights & R_ADMIN)
	if((admin_requester && !admin_spawn) || !is_antagonist_enabled("pony") || jobban_isbanned(ghost, "pony") || (!admin_spawn && (!istype(SSticker.mode, /datum/game_mode/dynamic) || config.director_antag_policy == DIRECTOR_ANTAG_POLICY_DISABLED || !SSdirector.can_recruit_antagonist("pony") || !("pony" in ghost.client.prefs.be_special_role))))
		to_chat(ghost, "<span class='warning'>Pony recruitment is no longer available.</span>")
		qdel(src)
		return TRUE
	var/datum/gas_mixture/air = spawn_turf?.return_air()
	if(!spawn_turf || (!admin_spawn && (!is_station_turf(spawn_turf) || spawn_turf.density || spawn_turf.contains_dense_objects() || !air || air.return_pressure() < 80 || air.temperature < 270 || air.temperature > 320)))
		to_chat(ghost, "<span class='warning'>The insertion point is no longer safe.</span>")
		qdel(src)
		return TRUE
	var/mob/living/carbon/human/pony
	if(admin_spawn && ishuman(ghost))
		pony = ghost
		if(pony.stat == DEAD || !pony.mind || player_is_antag(pony.mind) || !antag.can_become_antag(pony.mind, TRUE))
			to_chat(ghost, "<span class='warning'>You are no longer eligible to become a pony antagonist.</span>")
			qdel(src)
			return TRUE
	finished = TRUE
	var/ghost_key = ghost.key
	owner.update_dna()
	var/created_body = !pony
	if(created_body)
		pony = new(null)
	pony.set_species(owner.species.name, TRUE)
	pony.dna = owner.dna.Clone()
	pony.real_name = owner.real_name
	pony.SetName(pony.real_name)
	pony.UpdateAppearance()
	if(created_body)
		pony.key = ghost_key
		pony.forceMove(spawn_turf)
	if(!pony.mind || !antag.add_antagonist(pony.mind, admin_spawn, FALSE, FALSE, FALSE, TRUE))
		if(created_body)
			ghost.key = ghost_key
			qdel(pony)
		qdel(src)
		return TRUE
	if(admin_spawn)
		log_admin("[key_name(admin_requester)] ponified [key_name(pony)] as [pony.species.name].")
		message_admins("[key_name_admin(admin_requester)] ponified [key_name_admin(pony)] as [pony.species.name].")
	SSdirector.loyalty.set_faction(pony.mind, LOYALTY_NEUTRAL)
	SSdirector.add_tension(10, "Pony invader deployed")
	command_announcement.Announce("Hostile equestrian life signs detected aboard the station. These intruders are targeting all humanoids. All hands, prepare for hostile contact.", "Emergency Alert")
	qdel(src)
	return TRUE

/datum/nano_module/appearance_changer/pony_creation/Destroy()
	finished = TRUE
	SSnano.close_uis(src)
	if(ghost?.pony_creation == src)
		ghost.pony_creation = null
	ghost = null
	admin_requester = null
	QDEL_NULL(owner)
	QDEL_NULL(creation_state)
	return ..()