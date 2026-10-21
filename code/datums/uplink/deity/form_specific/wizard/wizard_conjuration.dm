/datum/uplink_item/deity/leveled/conjuration
	power_cost = 100
	name = DEITY_LEVELED_CONJURATION
	desc = "Conjuration is the school of creation and teleportation, summoning fireballs or teleporting long distances, this school is extremely powerful."
	category = /datum/uplink_category/deity_wizard_conjuration
	required_feats = list(DEITY_TREE_CONJURATION)
	max_level = 3

/datum/uplink_item/deity/boon/single_charge/conjuration
	category = /datum/uplink_category/deity_wizard_conjuration
	required_feats = list(DEITY_LEVELED_CONJURATION = 1)

/datum/uplink_item/deity/feat/phenomena/conjuration
	category = /datum/uplink_category/deity_wizard_conjuration
	required_feats = list(DEITY_LEVELED_CONJURATION = 1)

//Level 1
/datum/uplink_item/deity/boon/single_charge/conjuration/create_air
	power_cost = 10
	name = "Create Air"
	desc = "Allows your follower to generate a livable atmosphere in the area they are in."
	path = /spell/create_air
	category = /datum/uplink_category/deity_wizard_conjuration
	required_feats = list(DEITY_LEVELED_CONJURATION = 1)

/datum/uplink_item/deity/boon/single_charge/conjuration/acid_spray
	power_cost = 50
	name = "Acid Spray"
	desc = "The simplest form of aggressive conjuration: acid spray is quite effective in melting both man and object."
	path = /spell/acid_spray

/datum/uplink_item/deity/boon/single_charge/conjuration/force_wall
	power_cost = 10
	name = "Force Wall"
	desc = "A temporary invincible wall for followers to summon."
	path = /spell/aoe_turf/conjure/forcewall

/datum/uplink_item/deity/feat/phenomena/conjuration/dimensional_locker
	power_cost = 50
	name = "Phenomena: Dimensional Locker"
	desc = "Gain the ability to move a magical locker around. While it cannot move living things, you can move it around as you please, even disappearing it into the nether."
	path = /datum/phenomena/dimensional_locker

//Level 2
/datum/uplink_item/deity/boon/single_charge/conjuration/faithful_hound
	power_cost = 20
	name = "Faithful Hound"
	desc = "This spell allows a follower to summon a singular spectral dog that guards the nearby area. Anyone without the password is barked at or bitten."
	path = /spell/aoe_turf/conjure/faithful_hound
	required_feats = list(DEITY_LEVELED_CONJURATION = 2)

/datum/uplink_item/deity/feat/wizard_armaments
	power_cost = 25
	name = DEITY_UNLOCK_ARMS
	desc = "Unlock spells related to the summoning of weapons and armor. These spells only last a short duration, but are extremely effective."
	category = /datum/uplink_category/deity_wizard_conjuration
	required_feats = list(DEITY_LEVELED_CONJURATION = 2)

/datum/uplink_item/deity/boon/single_charge/wizard_armaments
	category = /datum/uplink_category/deity_wizard_conjuration
	required_feats = list(DEITY_UNLOCK_ARMS)

/datum/uplink_item/deity/boon/single_charge/wizard_armaments/sword
	power_cost = 25
	name = "Summon Sword"
	desc = "This spell allows your followers to summon a golden firey sword for a short duration."
	path = /spell/targeted/equip_item/dyrnwyn

/datum/uplink_item/deity/boon/single_charge/wizard_armaments/shield
	power_cost = 10
	name = "Summon Shield"
	desc = "This spell allows your followers to summon a magical shield for a short duration."
	path = /spell/targeted/equip_item/shield

/datum/uplink_item/deity/feat/phenomena/conjuration/portals
	power_cost = 75
	name = "Phenomena: Portals"
	desc = "Gain the ability to create portals for your followers to enter through. You will need to create two for it work. Any created past that will delete the oldest portal."
	required_feats = list(DEITY_LEVELED_CONJURATION = 2)
	path = /datum/phenomena/portals

//Level 3
/datum/uplink_item/deity/boon/single_charge/conjuration/fireball
	power_cost = 30
	name = "Fireball"
	desc = "Embue your follower with the power of exploding fire."
	path = /spell/targeted/projectile/dumbfire/fireball
	required_feats = list(DEITY_LEVELED_CONJURATION = 3)

/datum/uplink_item/deity/boon/single_charge/conjuration/force_portal
	power_cost = 15
	name = "Force Portal"
	desc = "This spell allows a follower to summon a force portal. Anything that hits the portal gets sucked inside and is then thrown out when the portal explodes."
	path = /spell/aoe_turf/conjure/force_portal
	required_feats = list(DEITY_LEVELED_CONJURATION = 3)

/datum/uplink_item/deity/feat/phenomena/conjuration/banishing_smite
	power_cost = 75
	name = "Phenomena: Banishing Smite"
	desc = "Gain the ability to smite an individual, dealing damage to them. If they are weakened enough, this can cause them to temporarily be transported."
	required_feats = list(DEITY_LEVELED_CONJURATION = 3)
	path = /datum/phenomena/banishing_smite