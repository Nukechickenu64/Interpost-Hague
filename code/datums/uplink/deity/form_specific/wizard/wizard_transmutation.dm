/datum/uplink_item/deity/leveled/transmutation
	power_cost = 100
	name = DEITY_LEVELED_TRANSMUTATION
	desc = "Transmutation is the school of change. It cannot be used to create things, only modify them or even destroy them."
	category = /datum/uplink_category/deity_wizard_transmutation
	required_feats = list(DEITY_TREE_TRANSMUTATION)
	max_level = 3

/datum/uplink_item/deity/boon/single_charge/transmutation
	category = /datum/uplink_category/deity_wizard_transmutation
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 1)

/datum/uplink_item/deity/feat/phenomena/transmutation
	category = /datum/uplink_category/deity_wizard_transmutation
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 1)

//Level 1
/datum/uplink_item/deity/boon/single_charge/transmutation/slippery_surface
	power_cost = 10
	name = "Slippery Surface"
	desc = "Allows a follower to slicken a small patch of floor. Anyone without sure-footing will find it hard to stay upright."
	path = /spell/hand/slippery_surface

/datum/uplink_item/deity/boon/single_charge/transmutation/smoke
	power_cost = 10
	name = "Smoke"
	desc = "Allows a follower to distill the nearby air into smoke."
	path = /spell/aoe_turf/smoke

/datum/uplink_item/deity/feat/phenomena/transmutation/animation
	power_cost = 75
	name = "Phenomena: Animation"
	desc = "Gain the ability to transform objects into mimics."
	path = /datum/phenomena/animate

//Level 2
/datum/uplink_item/deity/boon/single_charge/transmutation/knock
	power_cost = 25
	name = "Knock"
	desc = "Allows a follower to open nearby doors without the keys."
	path = /spell/aoe_turf/knock
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 2)

/datum/uplink_item/deity/boon/single_charge/transmutation/burning_grip
	power_cost = 15
	name = "Burning Grip"
	desc = "Allows a follower cause an object to heat up intensly in someone's hand, making them drop it and whatever skin is attached."
	path = /spell/hand/burning_grip
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 2)

/datum/uplink_item/deity/feat/phenomena/transmutation/warp_body
	power_cost = 75
	name = "Phenomena: Warp Body"
	desc = "Gain the ability to warp the very structure of a target's body, wracking pain and weakness."
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 2)
	path = /datum/phenomena/warp

//Level 3
/datum/uplink_item/deity/boon/single_charge/transmutation/jaunt
	power_cost = 25
	name = "Ethereal Jaunt"
	desc = "Allows a follower to liquify for a short duration, letting them pass through all dense objects."
	path = /spell/targeted/ethereal_jaunt
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 3)

/datum/uplink_item/deity/feat/healing_spells
	power_cost = 50
	name = DEITY_UNLOCK_HEAL
	desc = "Of transmutation, healing is perhaps the most immediately effective and useful. This unlocks the healing spells for your followers."
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 3)
	category = /datum/uplink_category/deity_wizard_transmutation

/datum/uplink_item/deity/boon/single_charge/heal
	power_cost = 15
	name = "Minor Heal"
	desc = "Allows your follower to heal themselves, or others, for a slight amount."
	required_feats = list(DEITY_UNLOCK_HEAL)
	category = /datum/uplink_category/deity_wizard_transmutation
	path = /spell/targeted/heal_target

/datum/uplink_item/deity/boon/single_charge/heal/major
	power_cost = 25
	name = "Major Heal"
	desc = "Allows your follower to heal others for a great amount."
	path = /spell/targeted/heal_target/major

/datum/uplink_item/deity/boon/single_charge/heal/area
	power_cost = 20
	name = "Area Heal"
	desc = "Allows your follower to heal everyone in an area for minor damage."
	path = /spell/targeted/heal_target/area

/datum/uplink_item/deity/feat/phenomena/transmutation/rock_form
	power_cost = 75
	name = "Phenomena: Rock Form"
	desc = "Gain the ability to transform your followers into beings of rock and stone."
	required_feats = list(DEITY_LEVELED_TRANSMUTATION = 3)
	path = /datum/phenomena/rock_form