/obj/item/weapon/gun/energy/taser
	name = "\improper NanoTrasen Mk30 NL Conducted-Energy Pistol"
	desc = "A low-capacity conducted-energy sidearm based on a Ward-Takahashi design and licensed for NanoTrasen production. It has low- and high-intensity settings."
	icon_state = "taser"
	item_state = null	//so the human update icon uses the icon_state instead.
	max_shots = 1
	projectile_type = /obj/item/projectile/beam/stun
	combustion = 0

	firemodes = list(
		list(mode_name="stun", projectile_type=/obj/item/projectile/beam/stun),
		list(mode_name="shock", projectile_type=/obj/item/projectile/beam/stun/shock),
		)

/obj/item/weapon/gun/energy/taser/carbine
	name = "\improper NanoTrasen Mk44 NL Conducted-Energy Carbine"
	desc = "A high-capacity conducted-energy carbine with low- and high-intensity settings for non-lethal takedowns."
	icon_state = "tasercarbine"
	w_class = ITEM_SIZE_LARGE
	slot_flags = SLOT_BELT|SLOT_BACK
	one_hand_penalty = 3
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 3, TECH_POWER = 3)
	force = 8
	max_shots = 12
	accuracy = 1
	projectile_type = /obj/item/projectile/beam/stun/heavy
	wielded_item_state = "tasercarbine-wielded"

	firemodes = list(
		list(mode_name="stun", projectile_type=/obj/item/projectile/beam/stun/heavy),
		list(mode_name="shock", projectile_type=/obj/item/projectile/beam/stun/shock/heavy),
		)

/obj/item/weapon/gun/energy/taser/mounted
	name = "\improper NanoTrasen Mk30-M Mounted Conducted-Energy System"
	desc = "A Mk30 conducted-energy system configured for powered mounting and external cell supply."
	self_recharge = 1
	use_external_power = 1

/obj/item/weapon/gun/energy/taser/mounted/cyborg
	name = "\improper NanoTrasen Mk30-C Cyborg Conducted-Energy System"
	desc = "A compact Mk30 conducted-energy system integrated into a cyborg chassis."
	max_shots = 6
	recharge_time = 10 //Time it takes for shots to recharge (in ticks)


/obj/item/weapon/gun/energy/stunrevolver
	name = "\improper Lawson Arms LAEP20 Zeus Electroshock Revolver"
	desc = "The Lawson Arms LAEP20 Zeus is an electroshock revolver produced under the FTU. Several TSCs have sought its blueprints for years."
	icon_state = "stunrevolver"
	item_state = "stunrevolver"
	origin_tech = list(TECH_COMBAT = 3, TECH_MATERIAL = 3, TECH_POWER = 2)
	projectile_type = /obj/item/projectile/energy/electrode
	max_shots = 6
	combustion = 0

/obj/item/weapon/gun/energy/stunrevolver/rifle
	name = "\improper Lawson Arms LAEP38 Thor Electroshock Rifle"
	desc = "A LAEP38 Thor, a vastly oversized variant of the LAEP20 Zeus. Fires overcharged electrodes to take down hostile armored targets without harming them too much."
	icon_state = "stunrifle"
	item_state = "stunrifle"
	w_class = ITEM_SIZE_HUGE
	slot_flags = SLOT_BACK
	one_hand_penalty = 6
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 3, TECH_POWER = 3)
	force = 10
	max_shots = 10
	accuracy = 1
	projectile_type = /obj/item/projectile/energy/electrode/stunshot
	wielded_item_state = "stunrifle-wielded"

/obj/item/weapon/gun/energy/crossbow
	name = "\improper Xenonomix XE-4 Compact Energy Crossbow"
	desc = "A compact, silenced energy-bolt launcher designed for covert operations."
	icon_state = "crossbow"
	w_class = ITEM_SIZE_NORMAL
	item_state = "crossbow"
	origin_tech = list(TECH_COMBAT = 2, TECH_MAGNET = 2, TECH_ILLEGAL = 5)
	matter = list(DEFAULT_WALL_MATERIAL = 2000)
	slot_flags = SLOT_BELT
	silenced = 1
	fire_sound = 'sound/weapons/Genhit.ogg'
	projectile_type = /obj/item/projectile/energy/bolt
	max_shots = 8
	self_recharge = 1
	charge_meter = 0
	combustion = 0

/obj/item/weapon/gun/energy/crossbow/ninja
	name = "\improper Xenonomix XD-5 Energy Dart Projector"
	desc = "A compact energy projector configured to fire low-profile darts."
	projectile_type = /obj/item/projectile/energy/dart
	max_shots = 5

/obj/item/weapon/gun/energy/crossbow/largecrossbow
	name = "\improper Xenonomix XE-7 Heavy Energy Crossbow"
	desc = "A full-size energy-bolt launcher used by infiltration teams requiring increased projectile output."
	w_class = ITEM_SIZE_LARGE
	force = 10
	one_hand_penalty = 1
	matter = list(DEFAULT_WALL_MATERIAL = 200000)
	projectile_type = /obj/item/projectile/energy/bolt/large

/obj/item/weapon/gun/energy/plasmastun
	name = "\improper Mars Military Industries MA21 Selkie Plasma Pulse Projector"
	desc = "The Mars Military Industries MA21 Selkie ionizes the surrounding atmosphere with a laser pulse, producing an expanding plasma burst and disorienting shockwave."
	icon_state = "plasma_stun"
	item_state = "plasma_stun"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_POWER = 3)
	fire_delay = 20
	max_shots = 4
	projectile_type = /obj/item/projectile/energy/plasmastun
	combustion = 0
