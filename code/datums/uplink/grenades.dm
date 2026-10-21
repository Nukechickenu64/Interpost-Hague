/***********
* Grenades *
************/
/datum/uplink_item/item/grenades
	category = /datum/uplink_category/grenades

/datum/uplink_item/item/grenades/anti_photon
	name = "1xPhoton Disruption Grenade"
	path = /obj/item/weapon/grenade/anti_photon

/datum/uplink_item/item/grenades/anti_photons
	name = "5xPhoton Disruption Grenades"
	path = /obj/item/storage/box/anti_photons

/datum/uplink_item/item/grenades/smoke
	name = "1xSmoke Grenade"
	path = /obj/item/weapon/grenade/smokebomb

/datum/uplink_item/item/grenades/smokes
	name = "5xSmoke Grenades"
	path = /obj/item/storage/box/smokes

/datum/uplink_item/item/grenades/emp
	name = "1xEMP Grenade"
	path = /obj/item/weapon/grenade/empgrenade

/datum/uplink_item/item/grenades/emps
	name = "5xEMP Grenades"
	path = /obj/item/storage/box/emps

/datum/uplink_item/item/grenades/frag_high_yield
	name = "Fragmentation Bomb"
	antag_roles = list(MODE_MERCENARY) // yeah maybe regular traitors shouldn't be able to get these
	path = /obj/item/weapon/grenade/frag/high_yield

/datum/uplink_item/item/grenades/fragshell
	name = "1xFragmentation Shell"
	desc = "Weaker than standard fragmentation grenades, these devices can be fired from a grenade launcher."
	antag_roles = list(MODE_MERCENARY)
	path = /obj/item/weapon/grenade/frag/shell

/datum/uplink_item/item/grenades/fragshells
	name = "5xFragmentation Shells"
	desc = "Weaker than standard fragmentation grenades, these devices can be fired from a grenade launcher."
	antag_roles = list(MODE_MERCENARY)
	path = /obj/item/storage/box/fragshells

/datum/uplink_item/item/grenades/frag
	name = "1xFragmentation Grenade"
	antag_roles = list(MODE_MERCENARY)
	path = /obj/item/weapon/grenade/frag

/datum/uplink_item/item/grenades/frags
	name = "5xFragmentation Grenades"
	antag_roles = list(MODE_MERCENARY)
	path = /obj/item/storage/box/frags

/datum/uplink_item/item/grenades/supermatter
	name = "1xSupermatter Grenade"
	desc = "This grenade contains a small supermatter shard which will delaminate upon activation and pull in nearby objects, irradiate lifeforms, and eventually explode."
	antag_roles = list(MODE_MERCENARY = 15)
	path = /obj/item/weapon/grenade/supermatter

/datum/uplink_item/item/grenades/supermatters
	name = "5xSupermatter Grenades"
	desc = "These grenades contains a small supermatter shard which will delaminate upon activation and pull in nearby objects, irradiate lifeforms, and eventually explode."
	antag_roles = list(MODE_MERCENARY)
	path = /obj/item/storage/box/supermatters