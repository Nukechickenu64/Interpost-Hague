// Runs requests and messages independently for each active Old God religion.
SUBSYSTEM_DEF(old_gods)
	name = "Old Gods"
	wait = 600
	priority = 20

/datum/controller/subsystem/old_gods/New()
	NEW_SS_GLOBAL(SSold_gods)

/datum/controller/subsystem/old_gods/fire()
	for(var/G in GLOB.all_religions)
		var/datum/religion/selected_religion = GLOB.all_religions[G]
		if(selected_religion.name != LEGAL_RELIGION && selected_religion.followers.len)
			if(prob(5)) 
				if(selected_religion.request == null)
					selected_religion.request()
				else
					for(var/mob/living/carbon/human/player in GLOB.player_list)
						if(player.religion == G)
							selected_religion.punish(player)
					QDEL_NULL(selected_religion.request)
			if(prob(15))
				selected_religion.whisper_to_followers()

/datum/controller/subsystem/old_gods/Initialize(time = null)
	..()

/datum/controller/subsystem/old_gods/stat_entry(msg)
	..("Old God religions: [GLOB.all_religions.len]")

/datum/controller/subsystem/old_gods/Recover()
	log_debug("Old Gods subsystem is recovering!")