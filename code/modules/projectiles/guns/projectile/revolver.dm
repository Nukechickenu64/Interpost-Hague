/obj/item/weapon/gun/projectile/revolver
	name = "\improper Lumoco Arms HE-357 Service Revolver"
	desc = "The Lumoco Arms HE-357 is a double-action service revolver chambered for .357 ammunition."
	icon_state = "revolver"
	item_state = "revolver"
	caliber = "357"
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 3)
	handle_casings = CYCLE_CASINGS
	max_shells = 6
	fire_delay = 6.75 //Revolvers are naturally slower-firing
	ammo_type = /obj/item/ammo_casing/a357
	var/chamber_offset = 0 //how many empty chambers in the cylinder until you hit a round
	unload_sound 	= 'sound/weapons/guns/interact/rev_magout.ogg'
	reload_sound 	= 'sound/weapons/guns/interact/rev_magin.ogg'
	bulletinsert_sound 	= 'sound/weapons/guns/interact/rev_magin.ogg'

/obj/item/weapon/gun/projectile/revolver/MiddleClick()
	if(CanPhysicallyInteract(usr))
		spin_cylinder()

/obj/item/weapon/gun/projectile/revolver/verb/spin_cylinder()
	set name = "Spin cylinder"
	set desc = "Fun when you're bored out of your skull."
	set category = "Object"

	chamber_offset = 0
	visible_message("<span class='warning'>\The [usr] spins the cylinder of \the [src]!</span>", \
	"<span class='notice'>You hear something metallic spin and click.</span>")
	playsound(src.loc, 'sound/weapons/revolver_spin.ogg', 100, 1)
	loaded = shuffle(loaded)
	if(rand(1,max_shells) > loaded.len)
		chamber_offset = rand(0,max_shells - loaded.len)

/obj/item/weapon/gun/projectile/revolver/consume_next_projectile()
	if(chamber_offset)
		chamber_offset--
		return
	return ..()

/obj/item/weapon/gun/projectile/revolver/load_ammo(var/obj/item/A, mob/user)
	chamber_offset = 0
	return ..()

/obj/item/weapon/gun/projectile/revolver/mateba
	name = "\improper Tirena Arms M-50 Competition Revolver"
	desc = "A heavy-frame .50-caliber revolver designed for precision shooting and field use."
	icon_state = "mateba"
	caliber = ".50"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a50

/obj/item/weapon/gun/projectile/revolver/detective
	name = "\improper HelTek D-38 Detective Revolver"
	desc = "A low-cost .38-caliber double-action revolver commonly issued to investigators. Uses .38 Special rounds."
	icon_state = "detective"
	max_shells = 6
	caliber = "38"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/c38

/obj/item/weapon/gun/projectile/revolver/detective/verb/rename_gun()
	set name = "Name Gun"
	set category = "Object"
	set desc = "Click to rename your gun. If you're the detective."

	var/mob/M = usr
	if(!M.mind)	return 0
	if(!M.mind.assigned_role == "Detective")
		to_chat(M, "<span class='notice'>You don't feel cool enough to name this gun, chump.</span>")
		return 0

	var/input = sanitizeSafe(input("What do you want to name the gun?", ,""), MAX_NAME_LEN)

	if(src && input && !M.stat && in_range(M,src))
		SetName(input)
		to_chat(M, "You name the gun [input]. Say hello to your new friend.")
		return 1

/obj/item/weapon/gun/projectile/revolver/capgun
	name = "\improper Kestrel K-7 Toy Revolver"
	desc = "A brightly marked toy revolver that fires paper caps. For ages 8 and up."
	icon_state = "revolver-toy"
	item_state = "revolver"
	caliber = "caps"
	origin_tech = list(TECH_COMBAT = 1, TECH_MATERIAL = 1)
	handle_casings = CYCLE_CASINGS
	max_shells = 7
	ammo_type = /obj/item/ammo_casing/cap

/obj/item/weapon/gun/projectile/revolver/capgun/attackby(obj/item/wirecutters/W, mob/user)
	if(!istype(W) || icon_state == "revolver")
		return ..()
	to_chat(user, "<span class='notice'>You snip off the toy markings off the [src].</span>")
	name = "Kestrel K-7 Unmarked Toy Revolver"
	icon_state = "revolver"
	desc += " Someone snipped off the barrel's toy mark. How dastardly."
	return 1

/obj/item/weapon/gun/projectile/revolver/webley
	name = "\improper Hephaestus HI-44 Service Revolver"
	desc = "A rugged top-break revolver with modernized components, chambered for .44 Magnum ammunition."
	icon_state = "webley"
	item_state = "webley"
	max_shells = 6
	caliber = ".44"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/c44

/obj/item/weapon/gun/projectile/revolver/smithwesson32
	name = "\improper Lumoco Arms L-32 Pocket Revolver"
	desc = "A compact, six-shot .32-caliber revolver intended for concealed carry."
	icon_state = "smithwesson32"
	item_state = "pistol1"
	max_shells = 6
	caliber = "a32"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a32

/obj/item/weapon/gun/projectile/revolver/magnum44
	name = "\improper Mars Military Industries MI-50 Heavy Revolver"
	desc = "A heavy-frame revolver chambered for .50-caliber ammunition."
	icon_state = "magnum44"
	item_state = "pistol1"
	max_shells = 6
	caliber = ".50"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a50

/obj/item/weapon/gun/projectile/revolver/ct2
	name = "\improper Ward-Takahashi WT-50 Duty Revolver"
	desc = "A six-shot duty revolver chambered for .50-caliber ammunition."
	icon_state = "a44rev"
	item_state = "pistol1"
	max_shells = 6
	caliber = ".50"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a50

/obj/item/weapon/gun/projectile/revolver/colony/revolver
	name = "\improper Frontier Arms FR-9 Colony Revolver"
	desc = "A locally produced 9mm revolver designed for service on frontier colonies."
	icon_state = "colonyrevolver"
	item_state = "pistol1"
	max_shells = 6
	caliber = "a9mm"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a9mm

/obj/item/weapon/gun/projectile/revolver/colony/enfils
	name = "\improper Aussec Armoury A-32 Heritage Revolver"
	desc = "An obsolete service revolver retained in limited use; chambered for .32-caliber ammunition."
	icon_state = "colonyrevolver"
	item_state = "pistol1"
	max_shells = 6
	caliber = "a32"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a32

/obj/item/weapon/gun/projectile/revolver/colony/revolver
	name = "Malice revolver"
	desc = "A revolver produced on frontier colonies. Chambered in (9mm)."
	icon_state = "colonyrevolver"
	item_state = "pistol1"
	max_shells = 6
	caliber = "a9mm"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a9mm

/obj/item/weapon/gun/projectile/revolver/colony/deckard
	name = "\improper Lumoco Arms BC-24 Service Revolver"
	desc = "A once-modern 24th-century 9mm revolver, now considered a dated but recognizable service design."
	icon_state = "deckard-loaded"
	item_state = "pistol1"
	max_shells = 6
	caliber = "a9mm"
	origin_tech = list(TECH_COMBAT = 3, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a9mm
