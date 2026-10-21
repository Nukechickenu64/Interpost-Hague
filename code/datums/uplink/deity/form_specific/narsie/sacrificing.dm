/datum/uplink_item/deity/boon/narsie_sacrificing
	category = /datum/uplink_category/deity_narsie_sacrifice
	required_feats = list(DEITY_TREE_SACRIFICE)

/datum/uplink_item/deity/boon/narsie_sacrificing/sac_dagger
	power_cost = 10
	name = "Sacrificial Dagger"
	desc = "A small dagger embued with your powers. Lets your followers give you power through sacrifices on an altar."
	path = /obj/item/weapon/material/knife/ritual/sacrifice

/datum/uplink_item/deity/boon/narsie_sacrificing/sac_spell
	power_cost = 10
	name = "Sacrifice Spell"
	desc = "This ability makes the user take INCREDIBLE amounts of damage to heal a target for a similar amount of damage."
	path = /spell/targeted/heal_target/sacrifice

/datum/uplink_item/deity/boon/narsie_sacrificing/execution_axe
	power_cost = 50
	name = "Greedy Axe"
	desc = "This axe can store the very souls of those it kills to be later transfered to you through an altar."
	path = /obj/item/weapon/material/twohanded/fireaxe/cult

/datum/uplink_item/deity/feat/blood_stone
	power_cost = 50
	name = "Bloodied Stone"
	desc = "Unlocks the blood stone building, which allows followers to increase your power through ritual and prayer."
	category = /datum/uplink_category/deity_narsie_sacrifice
	required_feats = list(DEITY_TREE_SACRIFICE)

/datum/uplink_item/deity/feat/blood_stone/buy(var/obj/item/device/uplink/U, var/mob/living/deity/user)
	. = ..()
	if(.)
		user.form.buildables |= /obj/structure/deity/blood_stone