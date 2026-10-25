#ifdef UNIT_TEST

/datum/unit_test/proc/combat_test_turf()
	var/turf/origin = locate(world.maxx - 30, world.maxy - 30, world.maxz)
	for(var/turf/T in range(6, origin))
		if(!istype(T, /turf/unsimulated/floor))
			T.ChangeTurf(/turf/unsimulated/floor)
	return locate(world.maxx - 30, world.maxy - 30, world.maxz)

/mob/living/carbon/human/combat_test
	var/list/test_rolls = list()
	var/list/test_targets = list()
	var/test_damage = 6

/mob/living/carbon/human/combat_test/gurps_roll(var/target)
	test_targets += target
	var/dice = length(test_rolls) ? test_rolls[1] : 10
	if(length(test_rolls))
		test_rolls.Cut(1, 2)
	return gurps_roll_result(target, dice)

/mob/living/carbon/human/combat_test/combat_roll_damage(obj/item/weapon, var/damage_type, var/maximize = FALSE, var/attack_kind = "strike")
	return test_damage

/mob/living/carbon/human/combat_test/proc/reset_actions()
	combat_action_until = next_move = left_hand_ready_until = right_hand_ready_until = special_action_ready_until = 0
	combat_defenseless_until = combat_defending_until = 0
	combat_shock_until = 0
	combat_motion_window = -1
	combat_steps = combat_action_steps = 0
	combat_last_step = -COMBAT_TURN
	stunned = weakened = paralysis = 0
	resting = FALSE
	update_canmove()
	setStaminaLoss(0)
	if(l_hand) l_hand.next_attack_time = 0
	if(r_hand) r_hand.next_attack_time = 0

/obj/item/combat_test_blade
	name = "test blade"
	force = 20
	sharp = TRUE
	edge = TRUE
	deathweb_weapon_skill = "swords"
	combat_swing_add = 1
	combat_thrust_add = 1

/obj/item/clothing/suit/combat_test_plate
	name = "test plate"
	body_parts_covered = UPPER_TORSO
	combat_dr = 6
	combat_pd = 0
	armor = list(melee = 60)

/datum/unit_test/proc/combat_fixture(turf/T)
	var/mob/living/carbon/human/combat_test/H = new(T)
	H.stats = list(st = 10, dx = 10, iq = 10, ht = 10, per = 10, wp = 5, im = 0, spd = 0)
	H.skills["melee"] = 40
	H.skills["swords"] = 40
	H.skills["unarmed"] = 40
	H.skills["shield"] = 60
	H.combat_mode = TRUE
	H.c_intent = I_DUAL
	H.a_intent = I_HURT
	H.hand = FALSE
	H.zone_sel = new /obj/screen/zone_sel(null)
	H.zone_sel.selecting = BP_CHEST
	H.reset_actions()
	return H

/datum/unit_test/combat_rolls
	name = "COMBAT PARITY - Dice distribution and strength table"

/datum/unit_test/combat_rolls/start_test()
	var/failure = ""
	var/successes = 0
	for(var/a = 1; a <= 6; a++)
		for(var/b = 1; b <= 6; b++)
			for(var/c = 1; c <= 6; c++)
				var/list/result = gurps_roll_result(10, a+b+c)
				successes += result["success"]
	if(successes != 108) failure += "3d6 skill 10 did not produce 108/216 successes. "
	var/list/critical = gurps_roll_result(-10, 3)
	if(!critical["critical_success"] || critical["critical_failure"]) failure += "Automatic success was overwritten by failure margin. "
	var/list/high_failure = gurps_roll_result(20, 17)
	if(high_failure["success"] || high_failure["critical_failure"]) failure += "High-skill 17 was not an ordinary failure. "
	var/list/thrust = combat_strength_dice(10)
	var/list/swing = combat_strength_dice(13, TRUE)
	if(thrust[1] != 1 || thrust[2] != -2 || swing[1] != 2 || swing[2] != -1) failure += "Verified strength rows changed. "
	if(failure) fail(failure)
	else pass("All 216 skill-10 outcomes, critical boundaries and strength rows verified.")
	return TRUE

/datum/unit_test/combat_action_gate
	name = "COMBAT PARITY - Weapon, hand and unarmed action authority"

/datum/unit_test/combat_action_gate/start_test()
	var/failure = ""
	var/turf/T = combat_test_turf()
	var/mob/living/carbon/human/combat_test/A = combat_fixture(T)
	var/mob/living/carbon/human/combat_test/B = combat_fixture(get_step(T, EAST))
	var/obj/item/combat_test_blade/W = new(T)
	var/obj/item/combat_test_blade/other = new(T)
	A.put_in_hands(W)
	A.put_in_hands(other)
	A.readycd = new /obj/screen()
	A.readycd.icon = 'icons/mob/screen/os13.dmi'
	A.test_rolls = list(18)
	if(!W.attack(B, A, BP_CHEST) || A.last_combat_event["outcome"] != "miss") failure += "Real weapon dispatch did not resolve a miss. "
	if(length(A.readycd.overlays) != 3) failure += "The HUD did not display the shared action commitment. "
	var/list/first_event = A.last_combat_event
	A.next_move = 0
	other.next_attack_time = 0
	if(other.attack(B, A, BP_CHEST)) failure += "Swapping weapons bypassed the action budget. "
	A.drop_from_inventory(W)
	B.attack_hand(A)
	if(A.last_combat_event != first_event) failure += "Unarmed input bypassed weapon recovery. "
	A.reset_actions()
	A.right_hand_ready_until = world.time + 20
	if(A.perform_combat_strike(B, null, BP_CHEST)) failure += "The hand HUD timer did not govern unarmed attacks. "
	A.reset_actions()
	A.hand = TRUE
	A.test_rolls = list(18)
	other.attack(B,A,BP_CHEST)
	var/list/left_roll = A.last_combat_event["roll"]
	if(left_roll["target"] != A.combat_attack_target(other,BP_CHEST) - 4) failure += "Selecting the weaker hand erased its attack penalty. "
	A.reset_actions()
	A.forceMove(get_step(get_step(B, EAST), EAST))
	if(other.attack(B, A, BP_CHEST)) failure += "Non-adjacent attack was accepted. "
	for(var/atom/O in list(A,B,W,other)) qdel(O)
	if(failure) fail(failure)
	else pass("Normal weapon and unarmed dispatch share recovery; swaps and out-of-range attacks cannot bypass it.")
	return TRUE

/datum/unit_test/combat_defenses
	name = "COMBAT PARITY - Shield, parry progression, facing and commitment"

/datum/unit_test/combat_defenses/start_test()
	var/failure = ""
	var/turf/T = combat_test_turf()
	var/mob/living/carbon/human/combat_test/A = combat_fixture(T)
	var/mob/living/carbon/human/combat_test/B = combat_fixture(get_step(T, EAST))
	var/obj/item/combat_test_blade/W = new(T)
	var/obj/item/weapon/shield/S = new(T)
	A.put_in_hands(W)
	B.put_in_hands(S)
	B.dir = WEST
	A.test_rolls = list(10)
	B.test_rolls = list(8)
	W.attack(B, A, BP_CHEST)
	if(A.last_combat_event["outcome"] != "block" || B.combat_blocks_used != 1 || B.getBruteLoss()) failure += "Ordinary melee bypassed the shield block. "
	B.skills["swords"] = 0
	var/low_parry = B.combat_parry_target(W)
	B.skills["swords"] = 50
	if(B.combat_parry_target(W) <= low_parry) failure += "Specialization did not improve parry. "
	B.dir = EAST
	B.test_rolls = list(3)
	if(B.combat_defend(A,W,BP_CHEST,"cut")) failure += "An attack from behind received an active defense or shield PD. "
	B.dir = WEST
	B.combat_defenseless_until = world.time + 10
	B.test_rolls = list(8)
	if(B.combat_defend(A,W,BP_CHEST,"cut")) failure += "All-out offense retained an active defense. "
	B.reset_actions()
	B.c_intent = I_DEFEND
	if(!B.prepare_guard() || B.combat_defending_until <= world.time || B.prepare_guard()) failure += "Defensive commitment was missing or could be spammed. "
	B.reset_actions()
	B.c_intent = I_DUAL
	B.drop_from_inventory(S)
	var/obj/item/combat_test_blade/left_blade = new(T)
	var/obj/item/combat_test_blade/right_blade = new(T)
	B.put_in_hands(left_blade)
	B.put_in_hands(right_blade)
	B.combat_defense_window = -1
	B.test_rolls = list(3,3,18)
	var/first_parry = B.combat_defend(A,W,BP_CHEST,"cut")
	var/second_parry = B.combat_defend(A,W,BP_CHEST,"cut")
	var/third_parry = B.combat_defend(A,W,BP_CHEST,"cut")
	if(first_parry != "parry" || second_parry != "parry" || third_parry || B.combat_left_parries != 1 || B.combat_right_parries != 1)
		failure += "Two held weapons did not supply independent, limited parries. "
	for(var/atom/O in list(A,B,W,S,left_blade,right_blade)) qdel(O)
	if(failure) fail(failure)
	else pass("A real melee strike can be blocked; skill progression, rear attacks and committed defense verified.")
	return TRUE

/datum/unit_test/combat_feint
	name = "COMBAT PARITY - Feint survives and affects the follow-up"

/datum/unit_test/combat_feint/start_test()
	var/failure = ""
	var/turf/T = combat_test_turf()
	var/mob/living/carbon/human/combat_test/A = combat_fixture(T)
	var/mob/living/carbon/human/combat_test/B = combat_fixture(get_step(T, EAST))
	A.c_intent = I_FEINT
	B.dir = WEST
	A.test_rolls = list(7)
	B.test_rolls = list(15)
	if(!A.perform_combat_feint(B) || A.feint_expires <= A.combat_action_until) failure += "Feint expired before the follow-up window. "
	if(A.perform_combat_feint(B)) failure += "Repeated feint bypassed commitment. "
	A.reset_actions()
	A.test_rolls = list(10)
	B.test_rolls = list(10)
	B.test_targets.Cut()
	if(!A.perform_combat_strike(B, null, BP_CHEST)) failure += "The next attack could not use the feint. "
	if(A.feint_target || A.feint_margin) failure += "Feint was not consumed once. "
	if(!length(B.test_targets) || B.test_targets[1] != 2) failure += "The feint did not reduce parry 8 by its margin of 6. "
	qdel(A)
	qdel(B)
	if(failure) fail(failure)
	else pass("Opponent-specific feint survives recovery, affects parry and is consumed once.")
	return TRUE

/datum/unit_test/combat_armor_injury
	name = "COMBAT PARITY - Damage type, single DR and anatomical consequences"

/datum/unit_test/combat_armor_injury/start_test()
	var/failure = ""
	var/turf/T = combat_test_turf()
	var/mob/living/carbon/human/combat_test/A = combat_fixture(T)
	var/mob/living/carbon/human/combat_test/B = combat_fixture(get_step(T,EAST))
	var/obj/item/combat_test_blade/W = new(T)
	var/obj/item/combat_test_blade/held = new(T)
	var/obj/item/clothing/suit/combat_test_plate/C = new(B)
	B.wear_suit = C
	B.combat_mode = FALSE
	A.put_in_hands(W)
	A.test_damage = 10
	A.test_rolls = list(10)
	B.test_rolls = list(3)
	W.attack(B,A,BP_CHEST)
	if(A.last_combat_event["dr"] != 6 || A.last_combat_event["injury"] != 6) failure += "Cutting did not apply (10-6)*1.5 exactly once. "
	if(abs(B.getBruteLoss() - 6 * B.maxHealth / 10) > 0.1) failure += "Medical conversion: got [B.getBruteLoss()] damage, maxHealth [B.maxHealth], species multiplier [B.species.brute_mod]. "
	if(!B.stunned || B.weakened) failure += "Passing the major-injury HT roll did not retain stun while avoiding knockdown. "
	A.reset_actions()
	A.test_rolls = list(3)
	A.test_damage = 6
	B.put_in_hands(held)
	W.edge = FALSE
	W.attack(B,A,BP_R_ARM)
	var/obj/item/organ/external/arm = B.get_organ(BP_R_ARM)
	if(A.last_combat_event["zone"] != BP_R_ARM || !(arm.status & ORGAN_TENDON_CUT) || held.loc == B || B.combat_hand_usable(FALSE)) failure += "Arm injury did not cripple the selected arm and drop its weapon. "
	A.reset_actions()
	A.test_rolls = list(3)
	W.attack(B,A,BP_EYES)
	var/obj/item/organ/internal/eyes/E = B.internal_organs_by_name[BP_EYES]
	if(!E || E.damage < E.max_damage || A.last_combat_event["zone"] != BP_EYES) failure += "Eye target did not produce an eye injury. "
	for(var/atom/O in list(A,B,W,held,C)) qdel(O)
	if(failure) fail(failure)
	else pass("Cutting penetrates numeric DR once; arm disability drops equipment; eye injury reaches the eye organ.")
	return TRUE

/datum/unit_test/combat_effort_fatigue
	name = "COMBAT PARITY - Effort lifetime and fatigue accounting"

/datum/unit_test/combat_effort_fatigue/start_test()
	var/failure = ""
	var/mob/living/carbon/human/combat_test/A = combat_fixture(combat_test_turf())
	if(!A.activate_willpower_effort(STAT_ST)) failure += "Effort activation failed. "
	var/list/effort = A.deathweb_stat_modifiers["willpower"]
	if(effort["expires"] != world.time + 1 MINUTE || A.stats[STAT_ST] != 11 || A.stats[STAT_WP] != 4) failure += "Effort did not last one minute with one resource debit. "
	if(A.activate_willpower_effort(STAT_DX) || A.stats[STAT_WP] != 4) failure += "An overlapping effort spent another resource. "
	A.deathweb_clear_stat_modifier("willpower", effort["serial"])
	if(A.stats[STAT_ST] != 10 || A.deathweb_stat_modifiers["willpower"]) failure += "Effort expiration did not restore stats. "
	A.setStaminaLoss(30)
	A.fatigue = 40
	A.handle_fatigue()
	if(A.fatigue != 40 || A.staminaloss != 30) failure += "Idle combat regenerated fatigue or stamina behind CheckStamina. "
	A.combat_mode = FALSE
	A.handle_fatigue()
	if(A.fatigue >= 40 || A.staminaloss != 30) failure += "Idle fatigue did not recover independently of stamina. "
	qdel(A)
	if(failure) fail(failure)
	else pass("One-minute nonstacking effort and single-owner stamina recovery verified.")
	return TRUE

/datum/unit_test/combat_motion_special
	name = "COMBAT PARITY - Movement, kick and grab integration"

/datum/unit_test/combat_motion_special/start_test()
	var/failure = ""
	var/turf/T = combat_test_turf()
	var/mob/living/carbon/human/combat_test/A = combat_fixture(T)
	var/mob/living/carbon/human/combat_test/B = combat_fixture(get_step(T,EAST))
	B.combat_mode = FALSE
	A.middle_click_intent = "kick"
	A.zone_sel.selecting = BP_CHEST
	A.test_rolls = list(18, 18)
	if(!B.kick_act(A) || A.last_combat_event["zone"] != BP_CHEST || !A.weakened || A.special_action_ready_until <= world.time)
		failure += "Actual kick dispatch lost its location, balance check or recovery. "
	A.reset_actions()
	A.test_rolls = list(3)
	A.a_intent = I_GRAB
	B.attack_hand(A)
	var/obj/item/grab/G = A.get_active_hand()
	if(!istype(G) || G.affecting != B || A.combat_action_until <= world.time)
		failure += "Actual grab input did not create a committed hold. "
	if(G) A.drop_from_inventory(G)
	A.reset_actions()
	A.test_rolls = list(18)
	if(A.combat_attempt_grab(B, BP_CHEST) || A.combat_action_until <= world.time)
		failure += "Missed grab failed to consume its action. "
	A.reset_actions()
	A.a_intent = I_HURT
	A.forceMove(T)
	B.forceMove(get_step(T,EAST))
	A.test_rolls = list(10)
	if(!A.perform_combat_strike(B, null, BP_CHEST)) failure += "Movement fixture attack was rejected (hand=[A.get_active_hand()], lying=[A.lying], ready=[A.combat_action_until], now=[world.time]). "
	var/first_step = A.Move(get_step(A, NORTH), NORTH)
	var/second_step = A.Move(get_step(A, NORTH), NORTH)
	if(!first_step || second_step)
		failure += "Attack steps were [first_step], [second_step]; expected one then zero. "
	A.reset_actions()
	A.forceMove(T)
	if(!A.Move(get_step(A,NORTH),NORTH) || !A.Move(get_step(A,NORTH),NORTH))
		failure += "Full movement could not spend two steps. "
	A.combat_mode = FALSE
	if(A.combat_can_act(A.hand)) failure += "Toggling combat mode bypassed movement commitment. "
	A.reset_actions()
	A.forceMove(T)
	A.lying = TRUE
	if(A.perform_combat_strike(B, null, BP_EYES)) failure += "Prone attacker reached a standing target's eyes. "
	A.lying = FALSE
	B.forceMove(locate(B.x, B.y, B.z - 1))
	if(A.perform_combat_strike(B, null, BP_CHEST)) failure += "Attack crossed z-levels. "
	qdel(A)
	qdel(B)
	if(failure) fail(failure)
	else pass("Kick and grab input, failed-action costs, step limits, posture and cross-level rejection verified.")
	return TRUE

/datum/unit_test/combat_profiles
	name = "COMBAT PARITY - Styles, readiness and equipment boundaries"

/datum/unit_test/combat_profiles/start_test()
	var/failure = ""
	var/turf/T = combat_test_turf()
	var/mob/living/carbon/human/A = new(T)
	var/mob/living/carbon/human/combat_test/B = combat_fixture(get_step(T,EAST))
	A.c_intent = I_DUAL
	A.stats[STAT_ST] = 10
	var/obj/item/combat_test_blade/W = new(T)
	var/base_target = A.combat_attack_target(W, BP_CHEST)
	var/base_damage = A.combat_roll_damage(W, "cut", TRUE)
	A.c_intent = I_STRONG
	if(A.combat_roll_damage(W, "cut", TRUE) != base_damage + 2) failure += "Strong style has no damage benefit. "
	A.c_intent = I_QUICK
	if(A.combat_attack_target(W, BP_CHEST) != base_target + 4 || A.combat_roll_damage(W, "cut", TRUE) != base_damage)
		failure += "Fury does not implement its stated accuracy benefit. "
	A.c_intent = I_AIM
	if(A.combat_attack_target(W, BP_CHEST) != base_target + 2 || A.combat_attack_duration(W) != 20) failure += "Aimed benefit/recovery mismatch. "
	var/obj/item/weapon/shield/energy/S = new(T)
	B.put_in_hands(S)
	B.combat_mode = FALSE
	B.dir = WEST
	B.test_rolls = list(3)
	if(B.combat_defend(A,W,BP_CHEST,"cut")) failure += "Retracted shield supplied passive defense. "
	S.active = TRUE
	B.test_rolls = list(3)
	if(B.combat_defend(A,W,BP_CHEST,"cut") != "passive protection") failure += "Expanded shield lost passive defense. "
	B.drop_from_inventory(S)
	B.put_in_hands(W)
	B.combat_mode = TRUE
	W.combat_unbalanced = TRUE
	W.next_attack_time = world.time + 10
	B.test_targets.Cut()
	B.test_rolls = list(18)
	B.combat_defend(A,W,BP_CHEST,"cut")
	if(length(B.test_targets) != 1 || B.test_targets[1] != B.combat_dodge_target()) failure += "Unready unbalanced weapon could parry. "
	B.drop_from_inventory(W)
	B.reset_actions()
	B.pulling_punches = TRUE
	B.test_rolls = list(3)
	B.perform_combat_strike(A,null,BP_R_ARM)
	var/obj/item/organ/external/O = A.get_organ(BP_R_ARM)
	if(A.getBruteLoss() || (O.status & ORGAN_TENDON_CUT)) failure += "A pulled punch caused physical injury. "
	B.reset_actions()
	B.put_in_hands(W)
	W.next_attack_time = 0
	W.combat_parry_modifier = 4
	B.test_rolls = list(3,3)
	B.combat_defense_window = -1
	B.test_damage = 6
	if(B.combat_defend(A,null,BP_CHEST,"cr") != "parry" || !A.getBruteLoss() || !(O.status & ORGAN_TENDON_CUT))
		failure += "An armed parry failed to injure the unarmed attacker's limb. "
	for(var/atom/item in list(A,B,W,S)) qdel(item)
	if(failure) fail(failure)
	else pass("Style benefits, inactive shields, unbalanced readiness and nonlethal sparring verified.")
	return TRUE

#endif
