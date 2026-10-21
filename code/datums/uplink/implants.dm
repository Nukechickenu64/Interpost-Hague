/***********
* Implants *
***********/
/datum/uplink_item/item/implants
	category = /datum/uplink_category/implants

/datum/uplink_item/item/implants/imp_freedom
	name = "Freedom Implant"
	path = /obj/item/storage/box/syndie_kit/imp_freedom

/datum/uplink_item/item/implants/imp_compress
	name = "Compressed Matter Implant"
	path = /obj/item/storage/box/syndie_kit/imp_compress

/datum/uplink_item/item/implants/imp_explosive
	name = "Explosive Implant (DANGER!)"
	path = /obj/item/storage/box/syndie_kit/imp_explosive

/datum/uplink_item/item/implants/imp_uplink
	name = "Uplink Implant"
	path = /obj/item/storage/box/syndie_kit/imp_uplink

/datum/uplink_item/item/implants/imp_uplink/New()
	..()
	desc = "An empty implanted equipment fabricator. Refill it with universal creation tokens."

/datum/uplink_item/item/implants/imp_imprinting
	name = "Neural Imprinting Implant"
	desc = "Use on someone who is under influence of Mindbreaker to give them laws-like set of instructions. Kit comes with a dose of mindbreaker."
	path = /obj/item/storage/box/syndie_kit/imp_imprinting
