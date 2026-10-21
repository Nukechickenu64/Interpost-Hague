/datum/uplink_item/deity/boon/ability_dark
	category = /datum/uplink_category/deity_ability_dark
	required_feats = list(DEITY_FORM_DARK_ART)

/datum/uplink_item/deity/boon/ability_dark/shatter_mind
	power_cost = 40
	name = "Eternal Darkness"
	desc = "Allows a follower to cause insanity in a target."
	path = /spell/targeted/shatter

/datum/uplink_item/deity/boon/ability_dark/torment
	power_cost = 30
	name = "Torment"
	desc = "Gives a follower the ability to cause mass hysteria and pain."
	path = /spell/targeted/torment

/datum/uplink_item/deity/boon/ability_dark/blood_shard
	power_cost = 40
	name = "Bloodshard"
	desc = "Lets a follower cause a target's blood to literally explode out of their skin into dangerous projectiles."
	path = /spell/hand/charges/blood_shard

/datum/uplink_item/deity/boon/ability_dark/drain_blood
	power_cost = 60
	name = "Drain Blood"
	desc = "Lets a follower drain blood from all those around them."
	path = /spell/aoe_turf/drain_blood

/datum/uplink_item/deity/feat/phenomena/exhude_blood
	power_cost = 30
	name = "Phenomena: Exhude Blood"
	desc = "You extract the raw blood used in your faith and give it to one of your flock"
	path = /datum/phenomena/exhude_blood
	category = /datum/uplink_category/deity_ability_dark
	required_feats = list(DEITY_FORM_DARK_ART)