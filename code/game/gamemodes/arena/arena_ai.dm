/mob/living/carbon/human/invader/arena
	faction = "arena"
	var/guard_chance = 15

/mob/living/carbon/human/invader/arena/defender
	guard_chance = 35

/mob/living/carbon/human/invader/arena/equip_invader_gear()
	equip_arena_fighter(src)

/mob/living/carbon/human/invader/arena/Initialize()
	. = ..()
	// Ordinary human attributes, modest skill, and slower reactions than invaders.
	newgeneratestats(10, 10, 10, 10, 10, 10, 10, 10)
	skills[SKILL_MELEE] = 35
	skills["swords"] = 35
	skills["unarmed"] = 35
	skills[SKILL_RANGE] = 0
	STOP_PROCESSING(SSinvaders, brain)
	qdel(brain)
	brain = new /datum/invader_ai/arena(src, mover)
	START_PROCESSING(SSinvaders, brain)
	c_intent = I_AIM
	fully_replace_character_name(istype(src, /mob/living/carbon/human/invader/arena/defender) ? "Arena defender" : "Arena sparring partner")

/datum/invader_ai/arena
	speed_multiplier = 2.5

/datum/invader_ai/arena/Process()
	. = ..()
	if(owner && owner.staminaloss >= 50)
		owner.combat_mode = FALSE

/datum/invader_ai/arena/is_valid_target(mob/living/carbon/human/H)
	// No executions of unconscious opponents, and no inherited syndicate immunity.
	return istype(H) && H.client && H.stat == CONSCIOUS && H.z == owner.z && !istype(H, /mob/living/carbon/human/invader/arena)

/datum/invader_ai/arena/pick_search_goal()
	var/list/tiles = list()
	for(var/turf/tile in range(7, owner))
		if(!tile.density && istype(get_area(tile), /area/arena))
			tiles += tile
	if(tiles.len)
		return pick(tiles)
	return null

/datum/invader_ai/arena/melee_attack()
	if(!is_valid_target(target) || !owner.combat_can_act(owner.hand))
		return
	var/mob/living/carbon/human/invader/arena/fighter = owner
	var/obj/item/weapon = get_melee_weapon(5)
	owner.defense_intent = weapon && prob(70) ? I_PARRY : I_DODGE
	owner.zone_sel.selecting = prob(80) ? BP_CHEST : pick(BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG)
	if(owner.staminaloss >= 50)
		mover.step_relative(target, TRUE)
		reaction_at = world.time + 2 SECONDS
		return
	if(prob(5))
		owner.activate_willpower_effort(pick(STAT_ST, STAT_DX, STAT_HT))
	// Every choice uses the same GURPS action budget, contests, defenses, armor,
	// injury and stamina code as player input. No direct damage or automatic hits.
	if(prob(fighter.guard_chance))
		owner.c_intent = pick(I_GUARD, I_DEFEND)
		owner.prepare_guard()
	else if(owner.feint_target != target && prob(15))
		owner.c_intent = I_FEINT
		owner.perform_combat_feint(target)
	else if(prob(10))
		owner.c_intent = I_DUAL
		owner.perform_dual_attack(target)
	else if(prob(8))
		owner.c_intent = I_AIM
		owner.perform_combat_strike(target, null, owner.zone_sel.selecting, "kick")
	else
		owner.c_intent = pick(I_AIM, I_AIM, I_GUARD, I_STRONG, I_QUICK)
		owner.a_intent = !weapon && prob(15) ? I_GRAB : I_HURT
		owner.ClickOn(target, "")
	// Visible breathing room even after a failed feint or a missed attack.
	reaction_at = max(world.time + 15, owner.combat_action_until + 5)
