////////////////////////////////////////////////////////////////////////////////
/// HYPOSPRAY
////////////////////////////////////////////////////////////////////////////////

/obj/item/reagent_containers/hypospray //obsolete, use hypospray/vial for the actual hypospray item
	name = "hypospray"
	desc = "The DeForest Medical Corporation hypospray is a sterile, air-needle autoinjector for rapid administration of drugs to patients."
	icon = 'icons/obj/syringe.dmi'
	item_state = "hypo"
	icon_state = "hypo"
	origin_tech = list(TECH_MATERIAL = 4, TECH_BIO = 5)
	amount_per_transfer_from_this = 5
	unacidable = 1
	volume = 30
	possible_transfer_amounts = null
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	slot_flags = SLOT_BELT
	var/inject_sound = 'sound/items/hypoinject.ogg'

///obj/item/reagent_containers/hypospray/New() //comment this to make hypos start off empty
//	..()
//	reagents.add_reagent(/datum/reagent/tricordrazine, 30)
//	return

/obj/item/reagent_containers/hypospray/do_surgery(mob/living/carbon/M, mob/living/user)
	if(user.a_intent != I_HELP) //in case it is ever used as a surgery tool
		return ..()
	attack(M, user)
	return 1

/obj/item/reagent_containers/hypospray/attack(mob/living/M as mob, mob/user as mob)
	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] is empty.</span>")
		return
	if (!istype(M))
		return

	var/mob/living/carbon/human/H = M
	if(istype(H))
		var/obj/item/organ/external/affected = H.get_organ(user.zone_sel.selecting)
		if(!affected)
			to_chat(user, "<span class='danger'>\The [H] is missing that limb!</span>")
			return
		else if(affected.robotic >= ORGAN_ROBOT)
			to_chat(user, "<span class='danger'>You cannot inject a robotic limb.</span>")
			return

	user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	user.do_attack_animation(M)
	to_chat(user, "<span class='notice'>You inject [M] with [src].</span>")
	to_chat(M, "<span class='notice'>You feel a tiny prick!</span>")
	user.visible_message("<span class='warning'>[user] injects [M] with [src].</span>")

	if(M.reagents)
		var/contained = reagentlist()
		var/trans = reagents.trans_to_mob(M, amount_per_transfer_from_this, CHEM_BLOOD)
		admin_inject_log(user, M, src, contained, trans)
		to_chat(user, "<span class='notice'>[trans] units injected. [reagents.total_volume] units remaining in \the [src].</span>")

	playsound(M, inject_sound, 100)
	return

/obj/item/reagent_containers/hypospray/vial
	name = "hypospray"
	item_state = "autoinjector"
	desc = "The DeForest Medical Corporation hypospray is a sterile, air-needle autoinjector for rapid administration of drugs to patients. Uses a replacable 30u vial."
	var/obj/item/reagent_containers/glass/beaker/vial/loaded_vial
	volume = 0

/obj/item/reagent_containers/hypospray/vial/New()
	..()
	loaded_vial = new /obj/item/reagent_containers/glass/beaker/vial(src)
	volume = loaded_vial.volume
	reagents.maximum_volume = loaded_vial.reagents.maximum_volume

/obj/item/reagent_containers/hypospray/vial/attack_hand(mob/user as mob)
	if(user.get_inactive_hand() == src)
		if(loaded_vial)
			reagents.trans_to_holder(loaded_vial.reagents,volume)
			reagents.maximum_volume = 0
			loaded_vial.update_icon()
			user.put_in_hands(loaded_vial)
			loaded_vial = null
			to_chat(user, "You remove the vial from the [src].")
			update_icon()
			playsound(src.loc, 'sound/weapons/flipblade.ogg', 50, 1)
			return
		..()
	else
		return ..()

/obj/item/reagent_containers/hypospray/vial/attackby(obj/item/weapon/W, mob/user as mob)
	if(istype(W, /obj/item/reagent_containers/glass/beaker/vial))
		if(!loaded_vial)
			if(!do_after(user,10) || loaded_vial || !(W in user))
				return 0
			if(W.is_open_container())
				W.atom_flags ^= ATOM_FLAG_OPEN_CONTAINER
				W.update_icon()
			user.drop_item()
			W.forceMove(src)
			loaded_vial = W
			reagents.maximum_volume = loaded_vial.reagents.maximum_volume
			loaded_vial.reagents.trans_to_holder(reagents,volume)
			user.visible_message("<span class='notice'>[user] has loaded [W] into \the [src].</span>","<span class='notice'>You load \the [W] into \the [src].</span>")
			update_icon()
			playsound(src.loc, 'sound/weapons/empty.ogg', 50, 1)
		else
			to_chat(user,"<span class='notice'>\The [src] already has a vial.</span>")
	else
		..()

/obj/item/reagent_containers/hypospray/autoinjector
	name = "autoinjector"
	desc = "A rapid and safe way to administer small amounts of drugs by untrained or trained personnel."
	icon_state = "blue"
	item_state = "autoinjector"
	amount_per_transfer_from_this = 5
	volume = 5
	origin_tech = list(TECH_MATERIAL = 2, TECH_BIO = 2)
	var/list/starts_with = list(/datum/reagent/inaprovaline = 5)

/obj/item/reagent_containers/hypospray/autoinjector/New()
	..()
	for(var/T in starts_with)
		reagents.add_reagent(T, starts_with[T])
	update_icon()
	return

/obj/item/reagent_containers/hypospray/autoinjector/attack(mob/M as mob, mob/user as mob)
	..()
	if(reagents.total_volume <= 0) //Prevents autoinjectors to be refilled.
		atom_flags &= ~ATOM_FLAG_OPEN_CONTAINER
	update_icon()
	return

/obj/item/reagent_containers/hypospray/autoinjector/update_icon()
	if(reagents.total_volume > 0)
		icon_state = "[initial(icon_state)]1"
	else
		icon_state = "[initial(icon_state)]0"

/obj/item/reagent_containers/hypospray/autoinjector/examine(mob/user)
	. = ..(user)
	if(reagents && reagents.reagent_list.len)
		to_chat(user, "<span class='notice'>It is currently loaded.</span>")
	else
		to_chat(user, "<span class='notice'>It is spent.</span>")

/obj/item/reagent_containers/hypospray/autoinjector/detox
	name = "autoinjector (antitox)"
	icon_state = "green"
	starts_with = list(/datum/reagent/dylovene = 5)

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab
	name = "chemical injector"
	desc = "A sealed single-dose injector produced by a Chemfab."
	icon = 'icons/os13/objects/objects/chemical.dmi'
	icon_state = "injector"
	item_state = "dnainjector"
	item_icons = list(slot_l_hand_str = 'icons/os13/mob/mob/items/items_lefthand.dmi', slot_r_hand_str = 'icons/os13/mob/mob/items/items_righthand.dmi')
	atom_flags = 0
	starts_with = list()
	var/injecting = FALSE

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/update_icon()
	icon_state = (reagents && reagents.total_volume) ? "injector" : "injector1"

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/on_reagent_change()
	. = ..()
	update_icon()

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/proc/can_administer(mob/user, mob/living/carbon/human/patient, zone, obj/item/organ/external/site)
	return !QDELETED(src) && user && !user.incapacitated() && loc == user && (user.get_active_hand() == src || user.get_inactive_hand() == src) && !QDELETED(patient) && patient.Adjacent(user) && !patient.isSynthetic() && patient.can_inject(user, zone) && !QDELETED(site) && patient.get_organ(zone) == site && !site.is_stump() && site.robotic < ORGAN_ROBOT && reagents && reagents.total_volume > 0 && patient.reagents && patient.reagents.get_free_space() >= reagents.total_volume

/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab/attack(mob/living/target, mob/user)
	if(injecting || !user?.zone_sel || !ishuman(target))
		return FALSE
	var/mob/living/carbon/human/patient = target
	var/zone = user.zone_sel.selecting
	var/obj/item/organ/external/site = patient.get_organ(zone)
	if(!can_administer(user, patient, zone, site))
		to_chat(user, SPAN_WARNING("Hold a loaded injector beside an accessible organic injection site with room for the full dose."))
		return FALSE
	var/datum/reagents/dose_holder = reagents
	var/dose = reagents.total_volume
	var/contained = reagentlist()
	injecting = TRUE
	user.visible_message(SPAN_NOTICE("[user] is trying to inject [patient]!"))
	var/completed = do_after(user, 1 SECOND, patient)
	if(QDELETED(src))
		return FALSE
	injecting = FALSE
	// Capture the region and contents before waiting. Changing targets, limbs,
	// clothes, ownership or contents cannot redirect or partially spend a dose.
	if(!completed || !can_administer(user, patient, zone, site) || reagents != dose_holder || reagents.total_volume != dose || reagentlist() != contained)
		return FALSE
	var/transferred = reagents.trans_to_mob(patient, dose, CHEM_BLOOD)
	if(!transferred)
		return FALSE
	user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	user.do_attack_animation(patient)
	user.visible_message(SPAN_NOTICE("[user] injects [patient]!"))
	to_chat(patient, SPAN_NOTICE("You feel a tiny prick!"))
	admin_inject_log(user, patient, src, contained, transferred)
	playsound(patient, inject_sound, 100)
	update_icon()
	if(!reagents.total_volume)
		user.drop_from_inventory(src)
	return TRUE

/obj/item/reagent_containers/hypospray/autoinjector/pain
	name = "autoinjector (painkiller)"
	icon_state = "purple"
	starts_with = list(/datum/reagent/tramadol = 5)
	inject_sound = 'sound/items/inject.ogg'

/obj/item/reagent_containers/hypospray/autoinjector/combatpain
	name = "autoinjector (oxycodone)"
	icon_state = "black"
	starts_with = list(/datum/reagent/tramadol/oxycodone = 5)

/obj/item/reagent_containers/hypospray/autoinjector/mindbreaker
	name = "autoinjector"
	icon_state = "black"
	starts_with = list(/datum/reagent/mindbreaker = 5)
