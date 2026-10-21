/datum/uplink_item/deity/boon/soul_arts
	category = /datum/uplink_category/deity_narsie_minions
	required_feats = list(DEITY_TREE_SOUL)

/datum/uplink_item/deity/boon/soul_arts/soul_shard
	power_cost = 10
	name = "Soul Stone Shard"
	desc = "Give your follower a sliver of soulstone to capture a life in."
	path = /obj/item/device/soulstone

/datum/uplink_item/deity/boon/soul_arts/blood_zombie
	power_cost = 200 //End game shit.
	name = "Blood Plague"
	desc = "Give a vessel to a follower filled with infection so vile, it turns all sapient creatures into mindless husks."
	path = /obj/item/reagent_containers/food/drinks/zombiedrink

/datum/uplink_item/deity/boon/soul_arts/tear_veil
	power_cost = 50
	name = "Tear Veil"
	desc = "Grant your follower the ability to literally rip a hole in this reality, allowing things to pass through."
	path = /spell/tear_veil

/datum/uplink_item/deity/feat/phenomena/hellscape
	power_cost = 50
	name = "Phenomena: Reveal Hellscape"
	desc = "You show a non-believer what their future will be like."
	path = /datum/phenomena/hellscape
	category = /datum/uplink_category/deity_narsie_minions
	required_feats = list(DEITY_TREE_SOUL)