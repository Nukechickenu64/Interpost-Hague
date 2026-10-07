#define CULTINESS_PER_CULTIST 40
#define CULTINESS_PER_SACRIFICE 40
#define CULTINESS_PER_TURF 1

#define CULT_RUNES_1 200
#define CULT_RUNES_2 400
#define CULT_RUNES_3 1000

#define CULT_GHOSTS_1 400
#define CULT_GHOSTS_2 800
#define CULT_GHOSTS_3 1200

#define CULT_MAX_CULTINESS 1200 // When this value is reached, the game stops checking for updates so we don't recheck every time a tile is converted in endgame

GLOBAL_DATUM_INIT(cult, /datum/antagonist/cultist, new)
GLOBAL_DATUM_INIT(cult_fire, /datum/antagonist/cultist/fire, new)
GLOBAL_DATUM_INIT(cult_death, /datum/antagonist/cultist/death, new)

/proc/get_cult_by_religion(religion_name)
	switch(religion_name)
		if(NARSIE_RELIGION)
			return GLOB.cult
		if(KHARIN_RELIGION)
			return GLOB.cult_fire
		if(REAPER_RELIGION)
			return GLOB.cult_death
	return null

/proc/is_cult_religion(religion_name)
	return religion_name in list(NARSIE_RELIGION, KHARIN_RELIGION, REAPER_RELIGION)

/proc/get_cults()
	return list(GLOB.cult, GLOB.cult_fire, GLOB.cult_death)

/proc/get_cult(mob/player)
	if(!player || !player.mind)
		return null
	for(var/datum/antagonist/cultist/cult in player.mind.active_antagonists)
		if(player.mind in cult.current_antagonists)
			return cult
	return null

/proc/iscultist(var/mob/player)
	return !isnull(get_cult(player))

/proc/same_cult(mob/player, datum/antagonist/cultist/cult)
	return cult && get_cult(player) == cult

/proc/bind_cult_summon(atom/summoned, datum/antagonist/cultist/cult)
	if(!cult)
		return
	if(istype(summoned, /obj/item/device/soulstone))
		var/obj/item/device/soulstone/stone = summoned
		stone.cult = cult
	else if(istype(summoned, /obj/structure/constructshell))
		var/obj/structure/constructshell/shell = summoned
		shell.cult = cult
	else if(istype(summoned, /obj/structure/cult))
		var/obj/structure/cult/structure = summoned
		structure.cult = cult
	else if(istype(summoned, /turf/simulated/wall/cult) || istype(summoned, /turf/simulated/floor/cult))
		var/turf/T = summoned
		if(T.cult_owner != cult)
			if(T.cult_owner)
				T.cult_owner.remove_cultiness(CULTINESS_PER_TURF)
			T.cult_owner = cult
			cult.add_cultiness(CULTINESS_PER_TURF)

/datum/antagonist/cultist
	id = MODE_CULTIST
	role_text = "Cultist"
	role_text_plural = "Cultists"
	restricted_jobs = list(/datum/job/lawyer, /datum/job/captain, /datum/job/hos)
	protected_jobs = list(/datum/job/officer, /datum/job/warden, /datum/job/detective)
	blacklisted_jobs = list(/datum/job/ai, /datum/job/chaplain, /datum/job/psychiatrist)
	feedback_tag = "cult_objective"
	antag_indicator = "hudcultist"
	welcome_text = "Keep your faith hidden while you find your fellow cultists. Use Communicate to whisper to your allies. Your tome contains your cult's rituals; hold it while drawing runes. Sacrifice both named targets on Offering runes, then summon your deity with a Tear Reality rune. The final ritual needs nine conscious members of your own cult, including constructs, within one tile of the rune for 45 seconds."
	victory_text = "The cult wins! It has succeeded in serving its dark masters!"
	loss_text = "The staff managed to stop the cult!"
	victory_feedback_tag = "win - cult win"
	loss_feedback_tag = "loss - staff stopped the cult"
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE
	hard_cap = 5
	hard_cap_round = 6
	initial_spawn_req = 4
	initial_spawn_target = 6
	antaghud_indicator = "hudcultist"
	porco_tab = "Thanati"
	porco_actions = list(list("CreateRune", "Create Rune"))

	var/allow_narsie = 1
	var/religion_name = NARSIE_RELIGION
	var/entity_name = "Nar-Sie"
	var/entity_title = "The Geometer of Blood"
	var/theme = "blood"
	var/theme_color = "#c80000"
	var/obj/item/book/tome/tome_type = /obj/item/book/tome
	var/obj/singularity/narsie/large/deity_type = /obj/singularity/narsie/large
	var/powerless = 0
	var/list/sacrifice_targets = list()
	var/list/obj/effect/rune/teleport/teleport_runes = list()
	var/list/rune_strokes = list()
	var/list/sacrificed = list()
	var/cult_rating = 0
	var/list/cult_rating_bounds = list(CULT_RUNES_1, CULT_RUNES_2, CULT_RUNES_3, CULT_GHOSTS_1, CULT_GHOSTS_2, CULT_GHOSTS_3)
	var/max_cult_rating = 0
	var/conversion_blurb = "You catch a glimpse of the Realm of Nar-Sie, the Geometer of Blood. You now see how flimsy the world is, you see that it should be open to the knowledge of That Which Waits. Assist your new compatriots in their dark dealings. Their goals are yours, and yours are theirs. You serve the Dark One above all else. Bring It back."

	faction = "cult"

/datum/antagonist/cultist/fire
	id = MODE_CULTIST_FIRE
	role_type = MODE_CULTIST
	role_text = "Fire Cultist"
	role_text_plural = "Fire Cultists"
	porco_tab = "Kha'Rin"
	religion_name = KHARIN_RELIGION
	entity_name = "Kha'Rin"
	entity_title = "The Harbinger of Fire"
	theme = "fire"
	theme_color = "#ff6600"
	tome_type = /obj/item/book/tome/fire
	deity_type = /obj/singularity/narsie/large/fire
	faction = "cult_fire"
	conversion_blurb = "You glimpse the realm of Kha'Rin, the Harbinger of Fire. Serve the Burning One with your fellow disciples. Rival cults do not share your cause."

/datum/antagonist/cultist/death
	id = MODE_CULTIST_DEATH
	role_type = MODE_CULTIST
	role_text = "Death Cultist"
	role_text_plural = "Death Cultists"
	porco_tab = "Mortality"
	religion_name = REAPER_RELIGION
	entity_name = "The Reaper"
	entity_title = "The Ferryman of Oblivion"
	theme = "death"
	theme_color = "#800020"
	tome_type = /obj/item/book/tome/death
	deity_type = /obj/singularity/narsie/large/death
	faction = "cult_death"
	conversion_blurb = "You glimpse the realm of the Reaper, the Ferryman of Oblivion. Serve the Silent One with your fellow disciples. Rival cults do not share your cause."

/datum/antagonist/cultist/can_become_antag(datum/mind/player, ignore_role)
	if(!player || !player.current)
		return FALSE
	var/datum/antagonist/cultist/existing_cult = get_cult(player.current)
	if(existing_cult && existing_cult != src)
		return FALSE
	// All themes share the existing Cultist ban.
	if(jobban_isbanned(player.current, MODE_CULTIST))
		return FALSE
	return ..()

/datum/antagonist/cultist/create_global_objectives()

	if(!..())
		return

	global_objectives = list()
	sacrificed = list()
	sacrifice_targets = list()
	global_objectives |= new /datum/objective/cult/eldergod(null, src)
	for(var/i = 1, i <= 2, i++)
		var/datum/objective/cult/sacrifice/sacrifice = new(null, src)
		sacrifice.find_target()
		if(sacrifice.target)
			sacrifice_targets |= sacrifice.target
		global_objectives |= sacrifice

/datum/antagonist/cultist/proc/sacrifice_objectives_complete()
	if(!sacrifice_targets.len)
		return FALSE
	for(var/datum/mind/target in sacrifice_targets)
		if(!(target in sacrificed))
			return FALSE
	return TRUE

/datum/antagonist/cultist/equip(var/mob/living/carbon/human/player)

	if(!..())
		return 0

	var/obj/item/book/tome/T = new tome_type(get_turf(player))
	var/list/slots = list (
		"backpack" = slot_in_backpack,
		"left pocket" = slot_l_store,
		"right pocket" = slot_r_store,
		"left hand" = slot_l_hand,
		"right hand" = slot_r_hand,
	)
	for(var/slot in slots)
		player.equip_to_slot(T, slot)
		if(T.loc == player)
			break
	var/obj/item/storage/S = locate() in player.contents
	if(istype(S))
		T.forceMove(S)

	// Membership is established before equipping, including the saved prior faith.
	if(istype(player, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = player
		H.religion = religion_name
		if(H.mind)
			H.mind.religion = religion_name
		to_chat(H, "<span class='cult'>Your faith binds to [religion_name].</span>")

/datum/antagonist/cultist/add_antagonist(var/datum/mind/player, var/ignore_role, var/do_not_equip, var/move_to_spawn, var/do_not_announce, var/preserve_appearance)
	if(!player || !player.current || get_cult(player.current))
		return FALSE
	if(player && !player.religion_before_cult)
		var/mob/living/current_living = isliving(player.current) ? player.current : null
		if(current_living && !is_cult_religion(current_living.religion))
			player.religion_before_cult = current_living.religion
		else if(player.religion && !is_cult_religion(player.religion))
			player.religion_before_cult = player.religion
	if(isliving(player.current))
		player.faction_before_cult = player.current.faction
		if(player.faction_before_cult in list("cult", "cult_fire", "cult_death"))
			player.faction_before_cult = "neutral"
	. = ..()
	if(.)
		// Ghost recruitment recursively adds the new body's mind in create_default().
		if(!(player in current_antagonists))
			player.religion_before_cult = null
			player.faction_before_cult = null
			return .
		var/datum/religion/previous_faith = GLOB.all_religions[player.religion_before_cult]
		if(previous_faith)
			previous_faith.followers -= player.name
		to_chat(player, "<span class='cult'>[conversion_blurb]</span>")
		if(player.current && !istype(player.current, /mob/living/simple_animal/construct))
			player.current.add_language(LANGUAGE_CULT)
		player.religion = religion_name
		if(player.current && isliving(player.current))
			var/mob/living/L = player.current
			L.religion = religion_name
			L.update_religion_magic()
			to_chat(L, "<span class='cult'>You embrace [entity_name], [entity_title].</span>")
		var/datum/religion/religion_datum = GLOB.all_religions[religion_name]
		if(istype(religion_datum))
			religion_datum.followers |= player.name
	else if(player)
		player.religion_before_cult = null
		player.faction_before_cult = null

/datum/antagonist/cultist/remove_antagonist(var/datum/mind/player, var/show_message, var/implanted)
	// An ascendant is still a member of this original cult. Remove its added
	// TG-style powers before the normal deconversion restores their old faith.
	var/datum/antagonist/cultist/ascendant/ascended = get_cult_ascendant(player)
	if(ascended)
		ascended.remove_antagonist(player, 0, implanted)
	. = ..()
	if(!.)
		return 0
	if(player.current)
		if(!istype(player.current, /mob/living/simple_animal/construct))
			player.current.remove_language(LANGUAGE_CULT)
		to_chat(player.current, "<span class='danger'>An unfamiliar white light flashes through your mind, cleansing the taint of the dark-one and the memories of your time as his servant.</span>")
	player.memory = ""
	if(show_message && player.current)
		player.current.visible_message("<span class='notice'>[player.current] looks like they just reverted to their old faith!</span>")
	var/datum/religion/religion_datum = GLOB.all_religions[religion_name]
	if(istype(religion_datum))
		religion_datum.followers -= player.name
	var/restored_religion = player.religion_before_cult
	if(!restored_religion || is_cult_religion(restored_religion))
		restored_religion = LEGAL_RELIGION
	player.religion = restored_religion
	var/datum/religion/restored_faith = GLOB.all_religions[restored_religion]
	if(restored_faith)
		restored_faith.followers |= player.name
	player.religion_before_cult = null
	if(player.current && isliving(player.current))
		var/mob/living/L = player.current
		L.religion = restored_religion
		L.faction = player.faction_before_cult ? player.faction_before_cult : initial(L.faction)
		L.update_religion_magic()
		to_chat(L, "<span class='notice'>Your faith returns to [L.religion].</span>")
	player.faction_before_cult = null
	player.objectives -= global_objectives
	remove_cult_magic(player.current)
	remove_cultiness(CULTINESS_PER_CULTIST)
	return 1

/datum/antagonist/cultist/update_antag_mob(var/datum/mind/player)
	. = ..()
	add_cultiness(CULTINESS_PER_CULTIST)
	add_cult_magic(player.current)
	// Make sure the cult rune scribing spell is present on the mob
	if(player.current && !istype(player.current, /mob/living/simple_animal/construct))
		var/has_rune_spell = 0
		if(player.current.mind && player.current.mind.learned_spells)
			for(var/spell/rune_write/S in player.current.mind.learned_spells)
				has_rune_spell = 1
				break
		if(!has_rune_spell)
			player.current.add_spell(new /spell/rune_write)

/datum/antagonist/cultist/proc/transfer_cult_body(mob/living/old_body, mob/living/new_body)
	if(old_body)
		old_body.verbs -= Tier1Runes
		old_body.verbs -= Tier2Runes
		old_body.verbs -= Tier3Runes
		old_body.verbs -= Tier4Runes
		old_body.verbs -= /mob/living/proc/praise_god
		old_body.verbs -= /mob/living/proc/make_shrine
		old_body.verbs -= /mob/living/proc/getBrothers
		old_body.remove_language(LANGUAGE_CULT)
		old_body.faction = new_body.mind.faction_before_cult ? new_body.mind.faction_before_cult : initial(old_body.faction)
		old_body.religion = new_body.mind.religion_before_cult ? new_body.mind.religion_before_cult : LEGAL_RELIGION
	new_body.religion = religion_name
	new_body.mind.faction_before_cult = initial(new_body.faction) == "cult" ? "neutral" : initial(new_body.faction)
	new_body.faction = faction
	new_body.add_language(LANGUAGE_CULT)
	add_cult_magic(new_body)
	new_body.update_religion_magic()
	var/datum/antagonist/cultist/ascendant/ascended = get_cult_ascendant(new_body.mind)
	if(ascended)
		ascended.apply_ascendant_magic(new_body)
	update_icons_added(new_body.mind)

/datum/antagonist/cultist/proc/add_cultiness(var/amount)
	cult_rating += amount
	var/old_rating = max_cult_rating
	max_cult_rating = max(max_cult_rating, cult_rating)
	if(old_rating >= CULT_MAX_CULTINESS)
		return
	var/list/to_update = list()
	for(var/i in cult_rating_bounds)
		if((old_rating < i) && (max_cult_rating >= i))
			to_update += i

	if(to_update.len)
		update_cult_magic(to_update)

/datum/antagonist/cultist/proc/update_cult_magic(var/list/to_update)
	if(CULT_RUNES_1 in to_update)
		for(var/datum/mind/H in current_antagonists)
			if(H.current)
				to_chat(H.current, "<span class='cult'>The veil between this world and beyond grows thin, and your power grows.</span>")
				add_cult_magic(H.current)
	if(CULT_RUNES_2 in to_update)
		for(var/datum/mind/H in current_antagonists)
			if(H.current)
				to_chat(H.current, "<span class='cult'>You feel that the fabric of reality is tearing.</span>")
				add_cult_magic(H.current)
	if(CULT_RUNES_3 in to_update)
		for(var/datum/mind/H in current_antagonists)
			if(H.current)
				to_chat(H.current, "<span class='cult'>The world is at end. The veil is as thin as ever.</span>")
				add_cult_magic(H.current)

	if((CULT_GHOSTS_1 in to_update) || (CULT_GHOSTS_2 in to_update) || (CULT_GHOSTS_3 in to_update))
		for(var/mob/observer/ghost/D in SSmobs.mob_list)
			add_ghost_magic(D)

/datum/antagonist/cultist/proc/offer_uncult(var/mob/M)
	if(!same_cult(M, src) || !M.mind)
		return

	to_chat(M, "<span class='cult'>Do you want to abandon [religion_name]? <a href='?src=\ref[src];confirmleave=1'>ACCEPT</a></span>")

/datum/antagonist/cultist/Topic(href, href_list)
	if(href_list["confirmleave"] && same_cult(usr, src))
		remove_antagonist(usr.mind, 1)

/datum/antagonist/cultist/proc/remove_cultiness(var/amount)
	cult_rating = max(0, cult_rating - amount)

/datum/antagonist/cultist/proc/add_cult_magic(var/mob/M)
	if(!M)
		return
	M.verbs += Tier1Runes
	if(isliving(M))
		M.verbs |= /mob/living/proc/praise_god
		M.verbs |= /mob/living/proc/make_shrine
		M.verbs |= /mob/living/proc/getBrothers

	if(max_cult_rating >= CULT_RUNES_1)
		M.verbs += Tier2Runes

		if(max_cult_rating >= CULT_RUNES_2)
			M.verbs += Tier3Runes

			if(max_cult_rating >= CULT_RUNES_3)
				M.verbs += Tier4Runes

/datum/antagonist/cultist/proc/remove_cult_magic(var/mob/M)
	if(!M)
		return
	M.verbs -= Tier1Runes
	M.verbs -= Tier2Runes
	M.verbs -= Tier3Runes
	M.verbs -= Tier4Runes
	// Remove the rune scribing spell if they had it
	if(M && M.mind && M.mind.learned_spells)
		for(var/spell/rune_write/S in M.mind.learned_spells)
			M.remove_spell(S)
