// TGstation's modern blood-cult identity is adapted here as a second-stage
// antagonist. The ascendant intentionally remains in the legacy cult datum so
// it keeps that cult's objectives, rune network, constructs, and allies.

GLOBAL_DATUM_INIT(cult_ascendant, /datum/antagonist/cultist/ascendant, new)

/proc/is_hell_turf(turf/T)
	if(!T)
		return FALSE
	// The Hell map uses several floor types, so resolve the level from the
	// Hell Delver landmark instead of accepting only its exposed dirt/slate.
	for(var/obj/effect/landmark/L in landmarks_list)
		if(L.name == "Hell Spawn" && L.z == T.z)
			return TRUE
	return istype(T, /turf/simulated/floor/helldirt) || istype(T, /turf/simulated/floor/hellslate)

/proc/get_cult_ascendant(datum/mind/player)
	if(!player || !GLOB.cult_ascendant || !(player in GLOB.cult_ascendant.current_antagonists))
		return null
	return GLOB.cult_ascendant

/proc/is_cult_ascendant(mob/player)
	return player && player.mind && get_cult_ascendant(player.mind)

/datum/antagonist/cultist/ascendant
	id = MODE_CULTIST_ASCENDED
	role_type = MODE_CULTIST
	role_text = "Nar'Sien Ascendant"
	role_text_plural = "Nar'Sien Ascendants"
	welcome_text = "The blood of Hell has remade you. You remain a servant of Nar-Sie, but can now prepare the blood magic used by the cults of other realities."
	flags = ANTAG_RANDOM_EXCEPTED
	// The legacy cult datum already supplies this player's cult HUD indicator.
	antag_indicator = null
	antaghud_indicator = "hudcultist"
	porco_tab = "Thanati"
	porco_actions = list(list("Prepare Blood Magic", "Prepare Blood Magic", /mob/living/proc/prepare_ascendant_blood_magic))

/datum/antagonist/cultist/ascendant/can_become_antag(datum/mind/player, ignore_role)
	return player && player.current && GLOB.cult && (player in GLOB.cult.current_antagonists) && !(player in current_antagonists)

/datum/antagonist/cultist/ascendant/add_antagonist(datum/mind/player, ignore_role, do_not_equip, move_to_spawn, do_not_announce, preserve_appearance)
	if(!can_become_antag(player, TRUE))
		return FALSE
	current_antagonists |= player
	player.add_active_antagonist(src)
	player.special_role = role_text
	apply_ascendant_magic(player.current)
	if(!do_not_equip)
		equip(player.current)
	to_chat(player.current, "<span class='danger'><font size=3>You are a [role_text]!</font></span>")
	to_chat(player.current, "<span class='cult'>The blood of the slain Hell Delver floods the rune and Nar-Sie remakes you. Your old rites remain, and you may now prepare blood magic in your own flesh.</span>")
	log_and_message_admins("ascended a Blood Cultist into a [role_text]", player.current)
	player.current.updatePig()
	return TRUE

// The first-stage cult owns the shared sacrifice and Nar-Sie objectives.
/datum/antagonist/cultist/ascendant/create_objectives(datum/mind/player, override)
	return FALSE

/datum/antagonist/cultist/ascendant/equip(mob/living/player)
	if(!player)
		return FALSE
	var/obj/item/weapon/melee/cultblade/ritual_dagger/dagger = new(get_turf(player), GLOB.cult)
	if(!player.put_in_hands(dagger))
		to_chat(player, "<span class='notice'>A ritual dagger forms at your feet.</span>")
	return TRUE

/datum/antagonist/cultist/ascendant/proc/apply_ascendant_magic(mob/living/body)
	if(!body)
		return
	body.verbs |= /mob/living/proc/prepare_ascendant_blood_magic

/datum/antagonist/cultist/ascendant/proc/remove_ascendant_magic(mob/living/body)
	if(body)
		body.verbs -= /mob/living/proc/prepare_ascendant_blood_magic

// Do not use the parent cultist cleanup: this player is still a member of the
// original blood cult and must retain its faith, runes, and objectives.
/datum/antagonist/cultist/ascendant/remove_antagonist(datum/mind/player, show_message, implanted)
	if(!player || !(player in current_antagonists))
		return FALSE
	remove_ascendant_magic(player.current)
	current_antagonists -= player
	player.remove_active_antagonist(src)
	player.special_role = (GLOB.cult && (player in GLOB.cult.current_antagonists)) ? GLOB.cult.role_text : null
	if(player.current)
		player.current.updatePig()
	return TRUE

/obj/item/weapon/melee/cultblade/ritual_dagger
	name = "ritual dagger"
	desc = "A compact blade that carries a sliver of Nar-Sie's geometry. It is used to carve blood magic into the wielder's flesh."
	w_class = ITEM_SIZE_SMALL
	force = 15

/obj/item/weapon/melee/cult_blood_magic
	name = "blood magic"
	desc = "A temporary knot of bloody light, waiting to be spent."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "cultblade"
	item_state = "cultblade"
	w_class = ITEM_SIZE_SMALL
	force = 0
	var/charges = 1
	var/datum/mind/owner_mind

/obj/item/weapon/melee/cult_blood_magic/New(loc, datum/mind/new_owner)
	owner_mind = new_owner
	..()

/obj/item/weapon/melee/cult_blood_magic/proc/valid_user(mob/living/user)
	return user && user.mind == owner_mind && is_cult_ascendant(user) && (src in user.contents)

/obj/item/weapon/melee/cult_blood_magic/proc/spend_charge()
	charges--
	if(charges <= 0)
		qdel(src)

/obj/item/weapon/melee/cult_blood_magic/attack(mob/living/target, mob/living/user, target_zone)
	if(!valid_user(user))
		return
	cast_on_living(target, user)

/obj/item/weapon/melee/cult_blood_magic/afterattack(atom/target, mob/living/user, proximity)
	if(!proximity || ismob(target) || !valid_user(user))
		return
	cast_on_atom(target, user)

/obj/item/weapon/melee/cult_blood_magic/proc/cast_on_living(mob/living/target, mob/living/user)
	return

/obj/item/weapon/melee/cult_blood_magic/proc/cast_on_atom(atom/target, mob/living/user)
	to_chat(user, "<span class='warning'>The blood magic finds no purchase there.</span>")

/obj/item/weapon/melee/cult_blood_magic/stun
	name = "stunning aura"
	desc = "A single-use blood spell that stuns and silences a non-cultist on touch."

/obj/item/weapon/melee/cult_blood_magic/stun/cast_on_living(mob/living/target, mob/living/user)
	if(same_cult(target, GLOB.cult))
		to_chat(user, "<span class='warning'>Your blood will not turn against a fellow cultist.</span>")
		return
	user.visible_message("<span class='warning'>[user]'s hand flashes crimson around [target]!</span>", "<span class='cult'>The prepared blood magic breaks across [target]'s mind.</span>")
	target.Weaken(8)
	target.Stun(8)
	target.silent = max(target.silent, 8)
	spend_charge()

/obj/item/weapon/melee/cult_blood_magic/teleport
	name = "teleporting aura"
	desc = "A single-use blood spell that sends a fellow cultist to one of your cult's teleport runes."

/obj/item/weapon/melee/cult_blood_magic/teleport/cast_on_living(mob/living/target, mob/living/user)
	if(!same_cult(target, GLOB.cult))
		to_chat(user, "<span class='warning'>Only a fellow Blood Cultist can follow this path.</span>")
		return
	var/list/destinations = list()
	for(var/obj/effect/rune/teleport/R in GLOB.cult.teleport_runes)
		if(!QDELETED(R))
			destinations |= R
	if(!destinations.len)
		to_chat(user, "<span class='warning'>No teleport runes answer your call.</span>")
		return
	var/obj/effect/rune/teleport/destination = input(user, "Choose a teleport rune.", "Blood Transposition") as null|anything in destinations
	if(!destination || !valid_user(user) || !same_cult(target, GLOB.cult))
		return
	var/turf/arrival = get_turf(destination)
	if(!arrival)
		return
	target.visible_message("<span class='warning'>[target] vanishes in a rush of bloody air!</span>", "<span class='cult'>Blood geometry drags you to a distant rune.</span>")
	target.forceMove(arrival)
	arrival.visible_message("<span class='warning'>[target] appears over a blood rune in a sharp red flash!</span>")
	spend_charge()

/obj/item/weapon/melee/cult_blood_magic/shackles
	name = "shackling aura"
	desc = "A two-use blood spell that binds and silences a non-cultist on touch."
	charges = 2

/obj/item/weapon/melee/cult_blood_magic/shackles/cast_on_living(mob/living/target, mob/living/user)
	if(same_cult(target, GLOB.cult))
		to_chat(user, "<span class='warning'>Your shadows refuse to bind a fellow cultist.</span>")
		return
	user.visible_message("<span class='warning'>Shadows coil around [target]'s limbs!</span>", "<span class='cult'>You shape the blood into dark restraints.</span>")
	target.Weaken(12)
	target.silent = max(target.silent, 12)
	spend_charge()

/obj/item/weapon/melee/cult_blood_magic/construction
	name = "twisting aura"
	desc = "A single-use blood spell that folds ten steel sheets into a cult construct shell."

/obj/item/weapon/melee/cult_blood_magic/construction/cast_on_atom(atom/target, mob/living/user)
	if(!istype(target, /obj/item/stack/material/steel))
		to_chat(user, "<span class='warning'>Twisted construction requires a stack of steel.</span>")
		return
	var/obj/item/stack/material/steel/steel = target
	if(steel.get_amount() < 10)
		to_chat(user, "<span class='warning'>You need ten sheets of steel to form a construct shell.</span>")
		return
	if(!steel.use(10))
		return
	var/obj/structure/constructshell/cult/shell = new(get_turf(steel))
	shell.cult = GLOB.cult
	user.visible_message("<span class='warning'>Blood-dark smoke twists the steel into an empty construct shell!</span>", "<span class='cult'>The steel obeys Nar-Sie's geometry.</span>")
	spend_charge()

/obj/item/weapon/melee/cult_blood_magic/equipment
	name = "arming aura"
	desc = "A single-use blood spell that gives a fellow cultist a complete robe set and cult blade."

/obj/item/weapon/melee/cult_blood_magic/equipment/cast_on_living(mob/living/target, mob/living/user)
	if(!ishuman(target) || !same_cult(target, GLOB.cult))
		to_chat(user, "<span class='warning'>Only a human Blood Cultist can bear this equipment.</span>")
		return
	var/mob/living/carbon/human/H = target
	if(!istype(H.get_equipped_item(slot_head), /obj/item/clothing/head/culthood))
		H.equip_to_slot_or_del(new /obj/item/clothing/head/culthood/alt(H), slot_head)
	if(!istype(H.get_equipped_item(slot_wear_suit), /obj/item/clothing/suit/cultrobes))
		H.equip_to_slot_or_del(new /obj/item/clothing/suit/cultrobes/alt(H), slot_wear_suit)
	if(!istype(H.get_equipped_item(slot_shoes), /obj/item/clothing/shoes/cult))
		H.equip_to_slot_or_del(new /obj/item/clothing/shoes/cult(H), slot_shoes)
	var/obj/item/weapon/melee/cultblade/blade = new(get_turf(H), GLOB.cult)
	H.put_in_hands(blade)
	H.update_icons()
	H.visible_message("<span class='warning'>Otherworldly cult equipment forms around [H]!</span>", "<span class='cult'>The Ascendant arms you for the red harvest.</span>")
	spend_charge()

/obj/item/weapon/melee/cult_blood_magic/rite
	name = "blood rite aura"
	desc = "A three-use blood rite. It heals cultists and drains a living human enemy to restore its wielder."
	charges = 3

/obj/item/weapon/melee/cult_blood_magic/rite/cast_on_living(mob/living/target, mob/living/user)
	if(same_cult(target, GLOB.cult))
		target.heal_organ_damage(10, 10)
		target.adjustToxLoss(-5)
		user.visible_message("<span class='warning'>Blood-red light closes [target]'s wounds!</span>", "<span class='cult'>You return stolen vitality to [target].</span>")
		spend_charge()
		return
	if(!ishuman(target))
		to_chat(user, "<span class='warning'>This rite needs the blood of a living human.</span>")
		return
	var/mob/living/carbon/human/victim = target
	if(victim.stat == DEAD || !victim.vessel || !victim.vessel.has_reagent(/datum/reagent/blood, 20))
		to_chat(user, "<span class='warning'>That body has no blood left to offer.</span>")
		return
	victim.vessel.remove_reagent(/datum/reagent/blood, 20)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.vessel.add_reagent(/datum/reagent/blood, 20)
		H.heal_organ_damage(8, 8)
	user.visible_message("<span class='warning'>Blood streams from [victim] into [user]!</span>", "<span class='cult'>The rite takes [victim]'s vitality for your own.</span>")
	spend_charge()

/obj/item/weapon/melee/cult_blood_magic/dagger
	name = "dagger invocation"
	desc = "A single-use invocation that restores a ritual dagger."

/obj/item/weapon/melee/cult_blood_magic/dagger/attack_self(mob/living/user)
	if(!valid_user(user))
		return
	var/obj/item/weapon/melee/cultblade/ritual_dagger/dagger = new(get_turf(user), GLOB.cult)
	if(!user.put_in_hands(dagger))
		to_chat(user, "<span class='notice'>A ritual dagger forms at your feet.</span>")
	else
		to_chat(user, "<span class='cult'>A ritual dagger materializes in your hand.</span>")
	spend_charge()

/mob/living/proc/prepare_ascendant_blood_magic()
	set category = "Cult Magic"
	set name = "Prepare Blood Magic"
	var/datum/antagonist/cultist/ascendant/ascended = get_cult_ascendant(mind)
	if(!ascended || stat || incapacitated())
		return
	var/list/rites = list(
		"Stunning Aura" = /obj/item/weapon/melee/cult_blood_magic/stun,
		"Teleporting Aura" = /obj/item/weapon/melee/cult_blood_magic/teleport,
		"Shadow Shackles" = /obj/item/weapon/melee/cult_blood_magic/shackles,
		"Twisted Construction" = /obj/item/weapon/melee/cult_blood_magic/construction,
		"Summon Combat Equipment" = /obj/item/weapon/melee/cult_blood_magic/equipment,
		"Blood Rite" = /obj/item/weapon/melee/cult_blood_magic/rite,
		"Summon Ritual Dagger" = /obj/item/weapon/melee/cult_blood_magic/dagger
	)
	var/choice = input(src, "Choose a blood spell to carve into your flesh.", "Prepare Blood Magic") as null|anything in rites
	if(!choice || !get_cult_ascendant(mind) || incapacitated())
		return
	visible_message("<span class='warning'>[src] cuts occult symbols into their own flesh.</span>", "<span class='cult'>You carve the [choice] into your flesh. Remain still.</span>")
	if(!do_after(src, 40) || !get_cult_ascendant(mind) || incapacitated())
		to_chat(src, "<span class='warning'>Your blood magic unravels before it can take shape.</span>")
		return
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		H.apply_damage(3, BRUTE, pick(BP_L_ARM, BP_R_ARM), 0, DAM_SHARP, "Blood Magic")
	var/path = rites[choice]
	var/obj/item/weapon/melee/cult_blood_magic/spell = new path(get_turf(src), mind)
	if(!put_in_hands(spell))
		to_chat(src, "<span class='notice'>The prepared blood magic falls at your feet.</span>")
	else
		to_chat(src, "<span class='cult'>The symbols glow: your [choice] is ready in your hand.</span>")

/obj/effect/rune/ascension
	cultname = "Hell ascension"
	strokes = 9

/obj/effect/rune/ascension/cast(mob/living/user)
	var/turf/T = get_turf(src)
	if(cult != GLOB.cult)
		to_chat(user, "<span class='warning'>Only Nar-Sie's Blood Cult knows this Hell rite.</span>")
		return fizzle(user)
	if(!is_hell_turf(T))
		to_chat(user, "<span class='warning'>The rune's geometry cannot survive outside Hell.</span>")
		return fizzle(user)
	if(user.loc != T || !ishuman(user) || !(user.mind in GLOB.cult.current_antagonists))
		to_chat(user, "<span class='warning'>An original, living Blood Cultist must stand on this rune.</span>")
		return fizzle(user)
	if(get_cult_ascendant(user.mind))
		to_chat(user, "<span class='warning'>Your blood has already crossed this threshold.</span>")
		return fizzle(user)
	var/mob/living/carbon/human/delver = null
	for(var/mob/living/carbon/human/candidate in T)
		if(candidate.stat == DEAD && candidate.mind && GLOB.delver && (candidate.mind in GLOB.delver.current_antagonists))
			delver = candidate
			break
	if(!delver)
		to_chat(user, "<span class='warning'>Place the corpse of a slain Hell Delver on this rune.</span>")
		return fizzle(user)
	speak_incantation(user, "N'ath reth hellan, Nar-Sie remakes me!")
	user.visible_message("<span class='warning'>The rune drinks the Hell Delver's blood and climbs [user]'s body in impossible angles!</span>", "<span class='cult'>You offer the Hell Delver's death and your own blood to Nar-Sie. Remain on the rune.</span>")
	if(!do_after(user, 100, T))
		to_chat(user, "<span class='warning'>The ascension is interrupted.</span>")
		return
	if(QDELETED(src) || user.loc != T || user.stat == DEAD || get_cult_ascendant(user.mind) || delver.loc != T || delver.stat != DEAD || !(delver.mind in GLOB.delver.current_antagonists))
		to_chat(user, "<span class='warning'>The necessary sacrifice is no longer bound to the rune.</span>")
		return
	if(!GLOB.cult_ascendant.add_antagonist(user.mind, TRUE, FALSE))
		to_chat(user, "<span class='warning'>The blood rite fails to take hold.</span>")
		return
	delver.dust()
	for(var/datum/mind/cultist_mind in GLOB.cult.current_antagonists)
		if(cultist_mind.current)
			to_chat(cultist_mind.current, "<span class='cult'>The blood of Hell has made [user] a Nar'Sien Ascendant.</span>")
	qdel(src)
