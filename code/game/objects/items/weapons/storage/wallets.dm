/obj/item/storage/card_holder
	name = "card holder"
	desc = "It can hold a few small and personal things."
	icon = 'icons/obj/wallet.dmi'
	icon_state = "wallet-white"
	w_class = ITEM_SIZE_SMALL
	storage_slots_w = 6
	storage_slots_h = 4
	can_hold = list(
		/obj/item/card,
		/obj/item/clothing/mask/smokable,
		/obj/item/lipstick,
		/obj/item/weapon/haircomb,
		/obj/item/mirror,
		/obj/item/clothing/accessory/locket,
		/obj/item/clothing/head/hairflower,
		/obj/item/device/flashlight/pen,
		/obj/item/device/flashlight/slime,
		/obj/item/seeds,
		/obj/item/dice,
		/obj/item/disk,
		/obj/item/implant,
		/obj/item/implanter,
		/obj/item/weapon/flame,
		/obj/item/paper,
		/obj/item/paper_bundle,
		/obj/item/pen,
		/obj/item/photo,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/pill,
		/obj/item/reagent_containers/hypospray/autoinjector,
		/obj/item/reagent_containers/glass/beaker/vial,
		/obj/item/device/radio/headset,
		/obj/item/device/paicard,
		/obj/item/stamp)
	slot_flags = SLOT_ID

	var/obj/item/card/id/front_id = null

/obj/item/storage/card_holder/leather
	color = COLOR_SEDONA

/obj/item/storage/card_holder/Destroy()
	if(front_id)
		front_id.dropInto(loc)
		front_id = null
	. = ..()

/obj/item/storage/card_holder/remove_from_storage(obj/item/W as obj, atom/new_location)
	. = ..(W, new_location)
	if(.)
		if(W == front_id)
			front_id = null
			name = initial(name)
			update_icon()

/obj/item/storage/card_holder/handle_item_insertion(obj/item/W as obj, prevent_warning = 0)
	. = ..(W, prevent_warning)
	if(.)
		if(!front_id && istype(W, /obj/item/card/id))
			front_id = W
			name = "[name] ([front_id])"
			update_icon()

/obj/item/storage/card_holder/update_icon()
	overlays.Cut()
	if(front_id)
		var/tiny_state = "id-generic"
		var/icon_state_key = "id-" + front_id.icon_state
		if(icon_state_key in icon_states(icon))
			tiny_state = icon_state_key
		var/image/tiny_image = new/image(icon, icon_state = tiny_state)
		tiny_image.appearance_flags = RESET_COLOR
		overlays += tiny_image

/obj/item/storage/card_holder/GetIdCard()
	return front_id

/obj/item/storage/card_holder/GetAccess()
	var/obj/item/I = GetIdCard()
	if(I)
		return I.GetAccess()
	else
		return ..()

/obj/item/storage/card_holder/poly
	name = "polychromic card holder"
	desc = "You can recolor it! Fancy! The future is NOW!"

/obj/item/storage/card_holder/poly/New()
	..()
	color = get_random_colour()
	update_icon()

/obj/item/storage/card_holder/poly/verb/change_color()
	set name = "Change Card Holder Color"
	set category = "Object"
	set desc = "Change the color of the card holder."
	set src in usr

	if(usr.incapacitated())
		return

	var/new_color = input(usr, "Pick a new color", "Card Holder Color", color) as color|null
	if(!new_color || new_color == color || usr.incapacitated())
		return
	color = new_color

/obj/item/storage/card_holder/poly/emp_act()
	icon_state = "wallet-emp"
	update_icon()

	spawn(200)
		if(src)
			icon_state = initial(icon_state)
			update_icon()