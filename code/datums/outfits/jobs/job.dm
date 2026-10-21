/decl/hierarchy/outfit/job
	name = "Standard Gear"
	hierarchy_type = /decl/hierarchy/outfit/job

	uniform = /obj/item/clothing/under/rank/nanotrasen
	l_ear = /obj/item/device/radio/headset
	shoes = /obj/item/clothing/shoes/jackboots

	id_slot = slot_wear_amulet
	id_type = /obj/item/card/id/civilian
	pda_slot = slot_wear_id
	pda_type = /obj/item/device/pda

	flags = OUTFIT_HAS_BACKPACK

/decl/hierarchy/outfit/job/equip_id(mob/living/carbon/human/H)
	var/obj/item/card/id/C = ..()
	if(!C)
		return
	return C
