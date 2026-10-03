/obj/item/weapon/gun/energy/pulse_rifle
	name = "\improper Hephaestus Industries HPR-40 Pulse Rifle"
	desc = "A high-output pulse rifle with a 36-shot cell capacity. Its cost and maintenance requirements limit issue to specialist units."
	icon_state = "pulse"
	item_state = "pulse"
	slot_flags = SLOT_BACK
	force = 12
	projectile_type = /obj/item/projectile/beam/pulse/heavy
	max_shots = 36
	w_class = ITEM_SIZE_HUGE
	one_hand_penalty= 6
	multi_aim = 1
	burst_delay = 3
	burst = 3
	move_delay = 4
	accuracy = -1
	wielded_item_state = "gun_wielded"

/obj/item/weapon/gun/energy/pulse_rifle/carbine
	name = "\improper Hephaestus Industries HPC-24 Pulse Carbine"
	desc = "A compact military pulse weapon with a 24-shot cell capacity, designed for use where the full-length HPR-40 is impractical."
	icon_state = "pulse_carbine"
	slot_flags = SLOT_BACK|SLOT_BELT
	force = 8
	projectile_type = /obj/item/projectile/beam/pulse/mid
	max_shots = 24
	w_class = ITEM_SIZE_LARGE
	one_hand_penalty= 3
	burst_delay = 2
	move_delay = 2

/obj/item/weapon/gun/energy/pulse_rifle/pistol
	name = "\improper Hephaestus Industries HPP-21 Pulse Pistol"
	desc = "A sidearm-sized pulse weapon with a 21-shot cell capacity."
	icon_state = "pulse_pistol"
	slot_flags = SLOT_BELT|SLOT_HOLSTER
	force = 6
	projectile_type = /obj/item/projectile/beam/pulse
	max_shots = 21
	w_class = ITEM_SIZE_NORMAL
	one_hand_penalty=1 //a bit heavy
	burst_delay = 1
	move_delay = 1
	wielded_item_state = null

/obj/item/weapon/gun/energy/pulse_rifle/mounted
	name = "\improper Hephaestus Industries HPR-40M Mounted Pulse Cannon"
	desc = "An HPR-40 pulse system configured for powered mounting and external cell supply."
	self_recharge = 1
	use_external_power = 1

/obj/item/weapon/gun/energy/pulse_rifle/destroyer
	name = "\improper Hephaestus Industries HPD-80 Pulse Destroyer"
	desc = "A heavy pulse weapon with a high-output cell and a long firing cycle, restricted to specialist deployment."
	power_supply = /obj/item/cell/super
	fire_delay = 25
	projectile_type=/obj/item/projectile/beam/pulse/destroy
	charge_cost= 40

/obj/item/weapon/gun/energy/pulse_rifle/destroyer/attack_self(mob/living/user as mob)
	to_chat(user, "<span class='warning'>[src.name] has three settings, and they are all DESTROY.</span>")

/obj/item/weapon/gun/energy/pulse_rifle/bogani
	name = "Uncatalogued Bogani Pulsar Cannon"
	desc = "An unfamiliar Bogani weapon that emits concentrated pulse energy. Its construction and operating principles are not recognized by human manufacturers."
	icon_state = "bog_rifle"
	item_state = "bog_rifle"
	wielded_item_state = "bog_rifle-wielded"
	projectile_type = /obj/item/projectile/beam/pulse/bogani
	max_shots = 100 //Don't want it to run out
	icon_rounder = 20