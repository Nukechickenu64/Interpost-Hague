/***************
* Telecrystals *
***************/
/datum/uplink_item/item/telecrystal
	category = /datum/uplink_category/telecrystals
	desc = "Create crystals for short-range teleportation."
	var/crystal_amount = 1

/datum/uplink_item/item/telecrystal/cost(var/charges, obj/item/device/uplink/U)
	return max(1, ceil(crystal_amount / 10))

/datum/uplink_item/item/telecrystal/get_goods(var/obj/item/device/uplink/U, var/loc)
	return new /obj/item/stack/telecrystal(loc, crystal_amount)

/datum/uplink_item/item/telecrystal/one
	name = "Telecrystal - 01"

/datum/uplink_item/item/telecrystal/five
	name = "Telecrystals - 05"
	crystal_amount = 5

/datum/uplink_item/item/telecrystal/ten
	name = "Telecrystals - 10"
	crystal_amount = 10

/datum/uplink_item/item/telecrystal/twentyfive
	name = "Telecrystals - 25"
	crystal_amount = 25

/datum/uplink_item/item/telecrystal/fifty
	name = "Telecrystals - 50"
	crystal_amount = 50

/datum/uplink_item/item/telecrystal/all
	name = "Teleportation crystal bundle"
	crystal_amount = 10
