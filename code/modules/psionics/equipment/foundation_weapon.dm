/obj/item/weapon/gun/projectile/revolver/foundation
	name = "\improper Cuchulain Foundation CF-1 Troubleshooter Revolver"
	icon = 'icons/obj/foundation.dmi'
	icon_state = "foundation"
	desc = "The Cuchulain Foundation CF-1 Troubleshooter is a compact composite revolver designed for concealed carry by field agents. It smells faintly of copper."
	ammo_type = /obj/item/ammo_casing/pistol/magnum/nullglass

/obj/item/weapon/gun/projectile/revolver/foundation/disrupts_psionics()
	return FALSE

/obj/item/storage/briefcase/foundation
	name = "\improper Foundation briefcase"
	desc = "A handsome black leather briefcase embossed with a stylized radio telescope."
	icon_state = "fbriefcase"
	item_state = "fbriefcase"

/obj/item/storage/briefcase/foundation/disrupts_psionics()
	return FALSE

/obj/item/storage/briefcase/foundation/New()
	..()
	new /obj/item/ammo_magazine/speedloader/magnum/nullglass(src)
	new /obj/item/weapon/gun/projectile/revolver/foundation(src)
	make_exact_fit()
