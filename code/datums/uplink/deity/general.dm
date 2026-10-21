/datum/uplink_item/deity/boon/ability_general
	category = /datum/uplink_category/deity_ability_general

/datum/uplink_item/deity/feat/ability_general
	category = /datum/uplink_category/deity_ability_general

/datum/uplink_item/deity/boon/ability_general/god_vision
	power_cost = 20
	name = "Godsvision"
	desc = "Grants the ability for a servant to see the world like you do."
	path = /spell/camera_connection/god_vision

/datum/uplink_item/deity/feat/ability_general/innate_minimum
	power_cost = 30
	name = "Increase Potential"
	desc = "Increase the amount of natural power you regenerate."
	can_buy_multiples = 1

/datum/uplink_item/deity/feat/ability_general/innate_minimum/buy(var/obj/item/device/uplink/U, var/mob/living/deity/user)
	. = ..()
	if(.)
		user.power_min += 5

/datum/uplink_item/deity/feat/ability_general/power_regeneration
	power_cost = 10
	name = DEITY_POWER_BONUS
	desc = "Decreases the time it takes to charge your power."
	can_buy_multiples = 1

/datum/uplink_item/deity/feat/ability_general/power_regeneration/buy(var/obj/item/device/uplink/U, var/mob/living/deity/user)
	. = ..()
	if(.)
		if(!user.feats[DEITY_POWER_BONUS])
			user.feats[DEITY_POWER_BONUS] = 0
		user.feats[DEITY_POWER_BONUS] += 1