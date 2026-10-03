#define INVADER_FACTION "syndicate"

GLOBAL_LIST_INIT(invader_allied_factions, list(INVADER_FACTION, "mercenary"))
GLOBAL_LIST_INIT(invader_allied_antag_ids, list(MODE_TRAITOR, MODE_MERCENARY, MODE_COMMANDO))

/proc/is_invader_ally(var/mob/living/M)
	if(!istype(M))
		return FALSE
	if(istype(M, /mob/living/carbon/human/invader) || (M.faction in GLOB.invader_allied_factions))
		return TRUE
	var/datum/mind/mind = M.mind
	if(!mind)
		return FALSE
	if(SSdirector && SSdirector.loyalty && SSdirector.loyalty.get_faction(mind) == LOYALTY_SYNDICATE)
		return TRUE
	for(var/id in GLOB.invader_allied_antag_ids)
		var/datum/antagonist/A = GLOB.all_antag_types_[id]
		if(A && A.is_antagonist(mind))
			return TRUE
	return FALSE

/mob/living/carbon/human/invader
	faction = INVADER_FACTION
	var/datum/invader_ai/brain
	var/datum/humanized_mover/mover

/mob/living/carbon/human/invader/Initialize()
	. = ..()
	gender = pick(MALE, FEMALE)
	randomize_skin_tone()
	randomize_hair_style()
	randomize_hair_color()
	randomize_eye_color()
	if(gender == MALE && prob(50))
		randomize_facial_hair_style()
		randomize_facial_hair_color()
	fully_replace_character_name(species.get_random_name(gender))
	newgeneratestats(12, 16, 12, 16, 8, 12, 12, 16)
	skills[SKILL_MELEE] = rand(55, 75)
	skills[SKILL_RANGE] = rand(55, 75)

	zone_sel = new /obj/screen/zone_sel(null)
	zone_sel.selecting = BP_CHEST
	a_intent = I_HURT
	// Default I_AIM adds attack cooldown; aggressive players fight in quick mode.
	c_intent = I_QUICK
	equip_invader_gear()

	mover = new(src)
	brain = new(src, mover)
	START_PROCESSING(SSinvaders, brain)

/mob/living/carbon/human/invader/Destroy()
	if(brain)
		STOP_PROCESSING(SSinvaders, brain)
		QDEL_NULL(brain)
	QDEL_NULL(mover)
	return ..()

/mob/living/carbon/human/invader/ssd_check()
	return FALSE

// Squadmates swap places like two players on help intent instead of body-blocking each other.
/mob/living/carbon/human/invader/can_swap_with(var/mob/living/tmob)
	if(!istype(tmob, /mob/living/carbon/human/invader))
		return ..()
	var/old_intent = a_intent
	var/old_other_intent = tmob.a_intent
	a_intent = I_HELP
	tmob.a_intent = I_HELP
	. = ..()
	a_intent = old_intent
	tmob.a_intent = old_other_intent

// ClickOn calls this and it dereferences usr.client, which client-less invaders don't have.
/mob/living/carbon/human/invader/switch_pointer()
	return

/mob/living/carbon/human/invader/hear_say(var/message, var/verb = "says", var/datum/language/language = null, var/alt_name = "", var/italics = 0, var/mob/speaker = null, var/sound/speech_sound, var/sound_vol)
	if(brain && speaker)
		brain.on_heard(speaker)
	return ..()

/mob/living/carbon/human/invader/bullet_act(var/obj/item/projectile/P, var/def_zone)
	if(brain && P)
		brain.on_attacked(P.firer)
	return ..()

/mob/living/carbon/human/invader/hit_with_weapon(obj/item/I, mob/living/user, var/effective_force, var/hit_zone)
	if(brain)
		brain.on_attacked(user)
	return ..()

/mob/living/carbon/human/invader/attack_hand(mob/living/carbon/M as mob)
	if(brain && M && M.a_intent == I_HURT)
		brain.on_attacked(M)
	return ..()

/mob/living/carbon/human/invader/proc/equip_invader_gear()
	equip_to_slot_or_del(new /obj/item/storage/backpack/satchel(src), slot_back)
	equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/under/syndicate/combat, /obj/item/clothing/under/merc, /obj/item/clothing/under/syndicate)), slot_w_uniform)
	equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/shoes/jackboots, /obj/item/clothing/shoes/dutyboots)), slot_shoes)
	equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/gloves/thick, /obj/item/clothing/gloves/combat/gloves)), slot_gloves)
	equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/breastplate)), slot_wear_suit)
	equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/head/helmet, /obj/item/clothing/head/helmet/swat, /obj/item/clothing/head/helmet/siege)), slot_head)
	if(prob(75))
		equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/mask/balaclava, /obj/item/clothing/mask/gas, /obj/item/clothing/mask/gas/newsecurity)), slot_wear_mask)
	equip_to_slot_or_del(new /obj/item/crowbar/red(src), slot_l_store)

	var/list/melee_pool = list(
		/obj/item/weapon/material/sword/siegesword,
		/obj/item/weapon/material/harpoon,
		/obj/item/weapon/melee/baton/loaded,
	)
	if(prob(35))
		equip_to_slot_or_del(new_invader_item(melee_pool), slot_r_hand)
		return

	var/obj/item/weapon/gun/G = new_invader_item(list(
		/obj/item/weapon/gun/projectile/colt,
		/obj/item/weapon/gun/projectile/automatic/c20r,
		/obj/item/weapon/gun/projectile/automatic/wt550,
		/obj/item/weapon/gun/projectile/shotgun/pump/combat,
		/obj/item/weapon/gun/energy/gun,
		/obj/item/weapon/gun/energy/laser,
	))
	G.safety = 0
	equip_to_slot_or_del(G, slot_r_hand)
	equip_to_slot_or_del(new_invader_item(melee_pool), slot_l_hand)
	var/obj/item/weapon/gun/projectile/P = G
	if(istype(P) && P.magazine_type)
		for(var/i in 1 to rand(2, 3))
			equip_to_storage_or_drop(new P.magazine_type(src))

/mob/living/carbon/human/invader/proc/new_invader_item(var/list/pool)
	var/path = pick(pool)
	return new path(src)
