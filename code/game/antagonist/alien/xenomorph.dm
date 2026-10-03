GLOBAL_DATUM_INIT(xenomorphs, /datum/antagonist/xenos, new)

/datum/antagonist/xenos
	id = MODE_XENOMORPH
	role_text = "Xenophage"
	role_text_plural = "Xenophages"
	mob_path = /mob/living/carbon/alien/larva
	flags = ANTAG_OVERRIDE_MOB | ANTAG_RANDSPAWN | ANTAG_OVERRIDE_JOB
	welcome_text = "Hiss! You are a larval alien. Hide and bide your time until you are ready to evolve."
	antaghud_indicator = "hudalien"
	antag_indicator = "hudalien"
	faction_role_text = "Xenophage Thrall"
	faction_descriptor = "Hive"
	faction_welcome = "Your will is ripped away as your humanity merges with the xenomorph overmind. You are now \
		a thrall to the queen and her brood. Obey their instructions without question. Serve the hive."
	faction = "xenophage"
	faction_indicator = "hudalien"
	porco_tab = "Xenophage"
	porco_actions = list(
		list("ventcrawl", "Crawl through Vent", /mob/living/proc/ventcrawl),
		list("regurgitate", "Regurgitate", /mob/living/carbon/human/proc/regurgitate),
		list("plant", "Plant Weeds (50)", /mob/living/carbon/human/proc/plant),
		list("transfer_plasma", "Transfer Plasma", /mob/living/carbon/human/proc/transfer_plasma),
		list("evolve", "Evolve (500)", /mob/living/carbon/human/proc/evolve),
		list("resin", "Secrete Resin (75)", /mob/living/carbon/human/proc/resin),
		list("corrosive_acid", "Corrosive Acid (200)", /mob/living/carbon/human/proc/corrosive_acid),
		list("pry_open", "Pry Open Airlock", /mob/living/carbon/human/proc/pry_open),
		list("tackle", "Tackle", /mob/living/carbon/human/proc/tackle),
		list("leap", "Leap", /mob/living/carbon/human/proc/leap),
		list("psychic_whisper", "Psychic Whisper", /mob/living/carbon/human/proc/psychic_whisper),
		list("neurotoxin", "Spit Neurotoxin (50)", /mob/living/carbon/human/proc/neurotoxin),
		list("xeno_infest", "Infest (500)", /mob/living/carbon/human/proc/xeno_infest),
		list("lay_egg", "Lay Egg (75)", /mob/living/carbon/human/proc/lay_egg)
		)

	hard_cap = 5
	hard_cap_round = 8
	initial_spawn_req = 4
	initial_spawn_target = 6

	spawn_announcement_title = "Lifesign Alert"
	spawn_announcement_delay = 5000

/datum/antagonist/xenos/get_porco_actions(var/mob/living/carbon/human/user)
	if(!user || !user.mind || !user.mind.has_active_antagonist(src))
		return
	var/list/available_actions = list()
	for(var/list/action in porco_actions)
		if(action[3] in user.verbs)
			available_actions += list(action)
	if(!available_actions.len)
		return
	return available_actions

/datum/antagonist/xenos/Initialize()
	spawn_announcement = replacetext(GLOB.using_map.unidentified_lifesigns_message, "%STATION_NAME%", station_name())
	spawn_announcement_sound = GLOB.using_map.xenomorph_spawn_sound
	..()

/datum/antagonist/xenos/attempt_random_spawn()
	if(config.aliens_allowed) ..()

/datum/antagonist/xenos/proc/get_vents()
	var/list/vents = list()
	for(var/obj/machinery/atmospherics/unary/vent_pump/temp_vent in SSmachines.machinery)
		if(!temp_vent.welded && temp_vent.network && (temp_vent.loc.z in GLOB.using_map.station_levels))
			if(temp_vent.network.normal_members.len > 50)
				vents += temp_vent
	return vents

/datum/antagonist/xenos/create_objectives(var/datum/mind/player)
	if(!..())
		return
	player.objectives += new /datum/objective/survive()
	player.objectives += new /datum/objective/escape()

/datum/antagonist/xenos/place_mob(var/mob/living/player)
	var/list/vents = get_vents()
	if(vents.len)
		player.forceMove(get_turf(pick(vents)))
