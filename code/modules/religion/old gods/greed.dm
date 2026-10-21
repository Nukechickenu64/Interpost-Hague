/datum/religion/greed
	name = GREED
	holy_item = /obj/item/stack/material/gold
	shrine = /obj/old_god_shrine/greed_shrine
	var/bloodgold = FALSE
	whisper_lines = list("Protect your treasures.", "Gold endures.", "Nothing lasts forever.")
	offering_items = list(/obj/item/stack/material/gold/ten, /obj/item/stack/material/silver/ten)

/datum/religion/greed/generate_random_phrase()
		var/phrase = pick("Oh great [name] ", "Oh [name]. ", "[name], our Benefactor. ")
		phrase += pick("You enrich our lives ", "You will shower us with gold ", "You bathe our [pick("outpost","kingdom","cities")] in your opulence. ")
		phrase += pick("In your golden light ", "[name] enrish us all. ", "[name] fill our pockets. ")
		phrase += "Amen"
		return phrase

/obj/old_god_shrine/greed_shrine
	name = "gold-plated shrine"
	shrine_religion = GREED
	icon_state = "greed"
	var/spell_to_blood = FALSE

/obj/old_god_shrine/greed_shrine/New()
	..()
	shrine_religion = GLOB.all_religions[GREED]


/*
Debt contract
*/
/obj/item/paper/contract
	throw_range = 3
	throw_speed = 3
	var/signed = FALSE
	var/datum/mind/target
	info = "test"
	item_flags = ITEM_FLAG_NO_BLUDGEON

/obj/item/paper/contract/proc/update_text()
	return
