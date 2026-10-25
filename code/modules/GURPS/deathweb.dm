var/global/list/deathweb_skill_defaults = list(
	"melee" = list(STAT_DX, -4),
	"shield" = list(STAT_DX, -4),
	"ranged" = list(STAT_PER, -4),
	"throwing" = list(STAT_PER, -5),
	"gardening" = list(STAT_IQ, -5),
	"cooking" = list(STAT_IQ, -5),
	"engineering" = list(STAT_IQ, -6),
	"surgery" = list("medical", -4, TRUE, TRUE),
	"medical" = list(STAT_IQ, -5),
	"cleaning" = list(STAT_IQ, -4),
	"smithing" = list(STAT_IQ, -4),
	"climbing" = list(STAT_DX, -5),
	"masonry" = list(STAT_IQ, -4),
	"pickpocketing" = list(STAT_DX, -6),
	"swimming" = list(STAT_HT, -5),
	"party" = list(STAT_HT, -4),
	"mining" = list(STAT_ST, -5),
	"tanning" = list(STAT_DX, -4),
	"shroomcutting" = list(STAT_ST, -5),
	"alchemy" = list(null, 0),
	"survival" = list(STAT_PER, -5),
	"fishing" = list(STAT_PER, -4),
	"lockpicking" = list(STAT_IQ, -5),
	"sneaking" = list(STAT_DX, -5),
	"riding" = list(STAT_DX, -5),
	"music" = list(null, 0),
	"traps" = list(STAT_IQ, -5),
	"crafting" = list(STAT_IQ, -4),
	"boating" = list(STAT_DX, -5),
	"observation" = list(STAT_PER, -5),
	"swords" = list("melee", -5, TRUE, FALSE, TRUE),
	"staffs" = list("melee", -5, TRUE, FALSE, TRUE),
	"knives" = list("melee", -4, TRUE, FALSE, TRUE),
	"unarmed" = list("melee", -5, TRUE, FALSE, TRUE),
	"axes_clubs" = list("melee", -5, TRUE, FALSE, TRUE),
	"flails" = list("melee", -6, TRUE, FALSE, TRUE),
	"crossbows" = list("ranged", -4, TRUE, FALSE, TRUE),
	"bows" = list("ranged", -5, TRUE, FALSE, TRUE),
	"science" = list(STAT_IQ, -6)
)

/mob/proc/gurps_stat(var/stat_type)
	switch(stat_type)
		if(STAT_PER)
			return max(0, round(stats[STAT_IQ] + stats[STAT_PER] - 10))
		if(STAT_IM)
			return max(0, round(stats[STAT_HT] + stats[STAT_IM]))
	return max(0, round(stats[stat_type]))

/mob/proc/gurps_skill_rank(var/skill_type)
	return max(0, round(skills[skill_type] / 10))

/mob/proc/gurps_skill_target(var/skill_type, var/skill_value = null)
	var/list/definition = deathweb_skill_defaults[skill_type]
	if(!definition)
		return 0
	var/value = isnull(skill_value) ? gurps_skill_rank(skill_type) : max(0, round(skill_value / 10))
	if(length(definition) >= 4 && definition[4] && value <= 0)
		return 0
	var/base = definition[1]
	if(!base)
		return value
	if(length(definition) >= 3 && definition[3])
		value += gurps_skill_rank(base)
		if(length(definition) >= 5 && definition[5])
			var/list/parent_definition = deathweb_skill_defaults[base]
			value += gurps_stat(parent_definition[1])
	else
		value += gurps_stat(base)
	return value + definition[2]

/mob/proc/gurps_condition_modifier()
	if(!ishuman(src))
		return 0
	var/mob/living/carbon/human/human = src
	var/modifier = 0
	if(human.handcuffed)
		modifier -= rand(0, 2)
	if(human.legcuffed())
		modifier -= rand(0, 2)
	if(combat_mode)
		modifier += rand(1, 3)
	if(stunned)
		modifier -= rand(2, 4)
	switch(human.nutrition)
		if(400 to 550)
			modifier += pick(0, 1)
		if(150 to 275)
			modifier += pick(-1, 0)
		if(100 to 150)
			modifier += pick(-2, 0)
		if(1 to 100)
			modifier += pick(-3, -2)
		if(-INFINITY to 1)
			modifier += pick(-4, -3)
	if(human.thirst <= THIRST_LEVEL_DEHYDRATED)
		modifier += rand(-4, -2)
	else if(human.thirst <= 150)
		modifier += rand(-3, -1)
	else if(human.thirst <= THIRST_LEVEL_THIRSTY)
		modifier += rand(-2, 0)
	else if(human.thirst <= THIRST_LEVEL_MEDIUM)
		modifier += pick(-1, 0)
	switch(happiness)
		if(MOOD_LEVEL_HAPPY1 to INFINITY)
			modifier += pick(0, 1)
		if(MOOD_LEVEL_SAD2 to MOOD_LEVEL_SAD1)
			modifier += pick(-1, 0)
		if(MOOD_LEVEL_SAD3 to MOOD_LEVEL_SAD2)
			modifier += pick(-2, 1)
		if(MOOD_LEVEL_SAD4 to MOOD_LEVEL_SAD3)
			modifier += pick(-3, -2)
		if(-5000000 to MOOD_LEVEL_SAD4)
			modifier += pick(-4, -3)
	return modifier

/mob/proc/gurps_skill_roll(var/skill_type, var/modifier = 0, var/skill_value = null)
	var/list/result = gurps_roll(gurps_skill_target(skill_type, skill_value) + gurps_condition_modifier() + modifier)
	if(ishuman(src))
		var/mob/living/carbon/human/human = src
		human.deathweb_learn_skill(skill_type, -2)
	return result

/mob/proc/gurps_combat_skill(var/skill_type)
	return skill_type in list("melee", "ranged", "throwing", "swords", "staffs", "knives", "unarmed", "shield", "axes_clubs", "flails", "crossbows", "bows")

/mob/living/carbon/human/proc/deathweb_learn_skill(var/skill_type, var/modifier = 0)
	if(!mind || !(skill_type in deathweb_skill_defaults) || gurps_skill_rank(skill_type) >= 10)
		return
	var/list/result = gurps_roll(gurps_stat(STAT_IQ) + modifier)
	if(!result["success"])
		return
	var/skill_level = gurps_skill_rank(skill_type)
	var/progress = max(1, result["margin"] + modifier * 2 - skill_level)
	if(gurps_combat_skill(skill_type))
		progress = max(1, round(progress / 2))
	if(result["critical_success"])
		progress *= 2
	learning_collector[skill_type] += progress
	if(learning_collector[skill_type] >= 20 * max(1, skill_level))
		skills[skill_type] = min(100, skills[skill_type] + 10)
		learning_collector[skill_type] = 0
		to_chat(src, SPAN_NOTICE("You have learned more about [skill_type]!"))

/mob/living/carbon/human/proc/initialize_deathweb_skills()
	for(var/skill_type in deathweb_skill_defaults)
		if(!(skill_type in skills))
			skills[skill_type] = 0
	skills["party"] = rand(0, 2) * 10
	skills["survival"] = rand(0, 1) * 10
	skills["tanning"] = rand(1, 2) * 10
	if(!skills[SKILL_CRAFT])
		skills[SKILL_CRAFT] = rand(0, 1) * 10

/mob/proc/deathweb_melee_miss_modifier()
	var/static/list/modifiers = list(30, 29, 28, 25, 24, 23, 15, 12, 10, 6, 0, -6, -10, -15, -20, -25, -30, -35, -40, -45, -50)
	return modifiers[clamp(round(gurps_skill_rank(SKILL_MELEE)), 0, 20) + 1]

/obj/item
	var/deathweb_weapon_skill = null
	var/deathweb_accuracy = 0
	var/deathweb_stat_dependent = TRUE
	var/deathweb_ignore_armor = FALSE
	var/deathweb_weapon_durability = 100
	var/deathweb_weapon_sharpness = 100

/obj/item/weapon/material/sword
	deathweb_weapon_skill = "swords"

/obj/item/weapon/material/knife
	deathweb_weapon_skill = "knives"

/obj/item/weapon/material/kitchen/utensil/knife
	deathweb_weapon_skill = "knives"

/obj/item/weapon/material/hatchet
	deathweb_weapon_skill = "axes_clubs"

/obj/item/weapon/material/twohanded/fireaxe
	deathweb_weapon_skill = "axes_clubs"

/obj/item/weapon/material/twohanded/baseballbat
	deathweb_weapon_skill = "axes_clubs"

/obj/item/weapon/material/twohanded/steelmace
	deathweb_weapon_skill = "axes_clubs"

/obj/item/weapon/material/twohanded/spear
	deathweb_weapon_skill = "staffs"

/obj/item/weapon/staff
	deathweb_weapon_skill = "staffs"

/obj/item/weapon/material/sword/makeshiftspear
	deathweb_weapon_skill = "staffs"

/obj/item/weapon/material/sword/mace
	deathweb_weapon_skill = "axes_clubs"

/obj/item/weapon/material/sword/steelhammer
	deathweb_weapon_skill = "axes_clubs"

/obj/item/weapon/material/sword/club
	deathweb_weapon_skill = "axes_clubs"

/obj/item/weapon/material/sword/combat_knife
	deathweb_weapon_skill = "knives"

/obj/item/weapon/melee/energy/sword
	deathweb_weapon_skill = "swords"
	deathweb_stat_dependent = FALSE
	deathweb_ignore_armor = TRUE

/obj/item/proc/deathweb_specialty_modifier(mob/user)
	if(!deathweb_weapon_skill || !user)
		return 0
	return -10 * clamp(round(user.gurps_skill_rank(deathweb_weapon_skill)), 0, 5)

/obj/item/proc/deathweb_weapon_force(var/base_force, var/strength)
	if(!deathweb_stat_dependent)
		return base_force
	var/difference = round(strength - 10)
	var/adjustment = 0
	for(var/step = 0; step < abs(difference); step++)
		if(difference < 0)
			adjustment += base_force / 12
			base_force -= adjustment
		else
			adjustment += base_force / 10
			base_force += adjustment
	return max(0, base_force)

/obj/item/proc/deathweb_wear_weapon(var/hard_block = FALSE)
	deathweb_weapon_durability = max(0, deathweb_weapon_durability - (hard_block ? 5 : 1))
	if(sharp)
		deathweb_weapon_sharpness = max(1, deathweb_weapon_sharpness - (hard_block ? 3 : 1))
	if(deathweb_weapon_durability <= 0)
		visible_message(SPAN_DANGER("[src] breaks!"))
		qdel(src)

/proc/deathweb_unarmed_damage(var/strength, var/health)
	var/damage = 5
	var/difference = round(strength - health)
	for(var/step = 0; step < abs(difference); step++)
		damage += difference < 0 ? -rand(1, 3) : rand(4, 7)
	return damage <= 0 ? 3 : damage

/proc/deathweb_hit_zone(var/zone, var/modifier = 0)
	var/static/list/miss_chances = list(BP_HEAD = 15, BP_THROAT = 45, BP_FACE = 15, BP_L_LEG = 15, BP_R_LEG = 15, BP_L_ARM = 15, BP_R_ARM = 15, BP_L_HAND = 20, BP_R_HAND = 20, BP_L_FOOT = 20, BP_R_FOOT = 20, BP_GROIN = 14, BP_VITALS = 9, BP_CHEST = 7, BP_MOUTH = 20)
	var/miss_chance = (zone in miss_chances) ? miss_chances[zone] : 10
	if(prob(max(0, miss_chance + modifier)))
		if(prob(50))
			return null
		return pick(BP_HEAD, BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG, BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT, BP_GROIN, BP_THROAT, BP_FACE, BP_VITALS, BP_CHEST, BP_MOUTH)
	return zone

/mob/living/proc/deathweb_parry(mob/living/attacker, var/damage = 0)
	if(!ishuman(src) || attacker == src || defense_intent != I_PARRY || stat || incapacitated() || zoomed)
		return FALSE
	var/modifier = combat_mode ? 5 : -90
	if(lying)
		modifier -= 5
	if(c_intent == I_DEFEND)
		modifier += 20
	var/obj/item/weapon = get_active_hand()
	var/chance
	if(weapon)
		modifier += -weapon.deathweb_specialty_modifier(src) + weapon.block_chance
		chance = (staminaloss < 50 ? 3 : 1) + gurps_skill_rank(SKILL_MELEE) * (staminaloss < 50 ? 5 : 3) + modifier
	else
		chance = (staminaloss < 50 ? 10 : 1) + gurps_skill_rank(SKILL_MELEE) * (staminaloss < 50 ? 5 : 3) + modifier
	if(!prob(chance))
		return FALSE
	if(!weapon && damage > 0)
		var/mob/living/carbon/human/human = src
		var/obj/item/organ/external/hand_organ = human.get_organ(pick(BP_L_HAND, BP_R_HAND))
		if(hand_organ && !(human.gloves && human.gloves.armor["melee"] > 0))
			hand_organ.take_external_damage(damage / 3)
	adjustStaminaLoss(max(0, 10 - (gurps_stat(STAT_DX) - 9)) + (c_intent == I_DEFEND ? 2 : 0))
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, 1)
	visible_message(SPAN_NOTICE("[src] parries [attacker ? "[attacker]'s attack" : "the attack"] with [weapon ? "[weapon]" : "bare hands"]!"))
	if(weapon)
		weapon.deathweb_weapon_durability = max(0, weapon.deathweb_weapon_durability - rand(1, 8))
		if(!weapon.deathweb_weapon_durability)
			weapon.deathweb_wear_weapon()
			return TRUE
		if(attacker && attacker.gurps_skill_rank(SKILL_MELEE) > gurps_skill_rank(SKILL_MELEE) && prob(attacker.gurps_skill_rank(SKILL_MELEE) * 10))
			drop_from_inventory(weapon)
		if(c_intent == I_GUARD && !deathweb_riposting && attacker && !attacker.deathweb_riposting && Adjacent(attacker) && get_active_hand() == weapon && !istype(weapon, /obj/item/weapon/gun))
			deathweb_riposting = TRUE
			weapon.attack(attacker, src, zone_sel.selecting)
			deathweb_riposting = FALSE
			adjustStaminaLoss(5)
	return TRUE

/mob/living/carbon/human/proc/deathweb_grab_dodge(mob/living/carbon/human/attacker)
	if(!attacker || attacker == src || lying || resting || incapacitated() || !canmove)
		return FALSE
	var/chance = 45
	if(c_intent == I_DEFEND && combat_mode)
		chance += 15
	chance += combat_mode ? -20 : 20
	chance += attacker.combat_mode ? 20 : -20
	if(length(grabbed_by))
		chance -= 85
	var/difference = round(attacker.gurps_skill_rank(SKILL_MELEE) + attacker.gurps_stat(STAT_DX) - gurps_skill_rank(SKILL_MELEE) - gurps_stat(STAT_DX))
	for(var/step = 0; step < abs(difference); step++)
		chance += difference < 0 ? rand(5, 8) : -rand(5, 8)
	if(FAT in attacker.mutations)
		chance -= 15
	return prob(chance <= 0 ? 5 : chance)

/obj/item/clothing
	var/deathweb_armor_type = DEATHWEB_ARMOR_CLOTH
	var/deathweb_durability = 100
	var/list/deathweb_initial_armor = null

/obj/item/clothing/suit/armor
	deathweb_armor_type = DEATHWEB_ARMOR_LEATHER

/obj/item/clothing/suit/armor/breastplate
	deathweb_armor_type = DEATHWEB_ARMOR_PLATE

/obj/item/clothing/suit/armor/fullbreastplate
	deathweb_armor_type = DEATHWEB_ARMOR_PLATE

/obj/item/clothing/head/helmet
	deathweb_armor_type = DEATHWEB_ARMOR_PLATE

/obj/item/clothing/suit/space
	deathweb_armor_type = DEATHWEB_ARMOR_PLATE

/obj/item/clothing/proc/deathweb_wear_armor()
	if(!deathweb_initial_armor)
		deathweb_initial_armor = armor.Copy()
		armor = armor.Copy()
	deathweb_durability = max(0, deathweb_durability - rand(2, 3))
	var/multiplier = 1
	deathweb_armor_type = initial(deathweb_armor_type)
	if(deathweb_durability < 41)
		multiplier = 0.25
		deathweb_armor_type = DEATHWEB_ARMOR_DAMAGED
	else if(deathweb_durability < 51)
		multiplier = 0.55
		if(initial(deathweb_armor_type) == DEATHWEB_ARMOR_PLATE)
			deathweb_armor_type = DEATHWEB_ARMOR_LEATHER
	else if(deathweb_durability < 71)
		multiplier = 0.75
		if(initial(deathweb_armor_type) == DEATHWEB_ARMOR_PLATE)
			deathweb_armor_type = DEATHWEB_ARMOR_MAIL
	else if(deathweb_durability < 91)
		multiplier = 0.9
	armor["melee"] = deathweb_initial_armor["melee"] * multiplier

/mob/living/carbon/human/proc/deathweb_melee_armor(var/hit_zone, obj/item/weapon = null, var/unarmed = FALSE, var/gauntlet = FALSE)
	if(weapon && weapon.deathweb_ignore_armor)
		return 0
	var/obj/item/organ/external/organ = get_organ(hit_zone)
	if(!organ)
		return 0
	var/obj/item/clothing/protection
	for(var/obj/item/clothing/gear in list(head, wear_mask, wear_suit, w_uniform, gloves, shoes))
		if(!(gear.body_parts_covered & organ.body_part))
			continue
		if(!protection || gear.deathweb_armor_type > protection.deathweb_armor_type)
			protection = gear
	if(!protection)
		return 0
	var/armor_type = protection.deathweb_armor_type
	var/armor_value = getarmor(hit_zone, "melee") - (weapon ? weapon.armor_penetration : 0)
	var/blocked = 0
	if(unarmed)
		if(gauntlet)
			blocked = armor_type == DEATHWEB_ARMOR_CLOTH ? 0 : 50
		else
			blocked = armor_type == DEATHWEB_ARMOR_CLOTH ? 50 : 100
	else if(weapon && armor_value > 0)
		if(weapon.sharp)
			blocked = armor_type == DEATHWEB_ARMOR_DAMAGED ? 50 : (armor_type == DEATHWEB_ARMOR_CLOTH ? 0 : 100)
		else if(weapon.edge)
			switch(armor_type)
				if(DEATHWEB_ARMOR_PLATE)
					blocked = 100
				if(DEATHWEB_ARMOR_MAIL)
					blocked = prob(weapon.force - armor_value) ? 50 : 0
				if(DEATHWEB_ARMOR_LEATHER, DEATHWEB_ARMOR_DAMAGED)
					blocked = prob(max(weapon.force - armor_value, rand(10, 35))) ? 0 : 50
		else if(armor_type != DEATHWEB_ARMOR_CLOTH)
			blocked = 50
	if(blocked)
		protection.deathweb_wear_armor()
	return blocked

/mob
	var/list/deathweb_stat_modifiers = list()
	var/deathweb_stat_modifier_serial = 0
	var/deathweb_riposting = FALSE

/mob/proc/deathweb_add_stat_modifier(var/category, var/list/values, var/duration = 0)
	if(!category || !islist(values))
		return FALSE
	deathweb_clear_stat_modifier(category)
	var/list/applied_values = list()
	for(var/stat_type in values)
		if(!(stat_type in stats) || !isnum(values[stat_type]))
			continue
		applied_values[stat_type] = values[stat_type]
		stats[stat_type] += values[stat_type]
	deathweb_stat_modifier_serial++
	deathweb_stat_modifiers[category] = list("values" = applied_values, "serial" = deathweb_stat_modifier_serial, "expires" = duration > 0 ? world.time + duration : 0)
	if(duration > 0)
		addtimer(CALLBACK(src, /mob/proc/deathweb_clear_stat_modifier, category, deathweb_stat_modifier_serial), duration)
	return TRUE

/mob/proc/deathweb_clear_stat_modifier(var/category, var/serial = null)
	var/list/modifier = deathweb_stat_modifiers[category]
	if(!modifier || (!isnull(serial) && modifier["serial"] != serial))
		return FALSE
	var/list/values = modifier["values"]
	for(var/stat_type in values)
		stats[stat_type] -= values[stat_type]
	deathweb_stat_modifiers -= category
	if(category == "willpower")
		to_chat(src, SPAN_NOTICE("My effort has ended."))
	return TRUE

/mob/living/carbon/human/proc/gain_willpower(var/amount = 1)
	stats[STAT_WP] = max(0, stats[STAT_WP] + amount)
	return stats[STAT_WP]

/mob/living/carbon/human/verb/spend_willpower()
	set name = "Spend Willpower"
	set category = "IC"
	if(stat || incapacitated() || gurps_stat(STAT_WP) <= 0 || deathweb_stat_modifiers["willpower"])
		return
	var/list/efforts = list("Strength" = STAT_ST, "Dexterity" = STAT_DX, "Intelligence" = STAT_IQ, "Health" = STAT_HT, "Perception" = STAT_PER, "Immunity" = STAT_IM)
	var/effort = input(src, "Choose an effort.", "Willpower") as null|anything in efforts
	if(!effort || stat || incapacitated() || gurps_stat(STAT_WP) <= 0 || deathweb_stat_modifiers["willpower"])
		return
	var/stat_type = efforts[effort]
	if(activate_willpower_effort(stat_type))
		to_chat(src, SPAN_NOTICE("You focus your willpower on [lowertext(effort)]."))

/mob/living/carbon/human/proc/activate_willpower_effort(var/stat_type)
	if(!(stat_type in list(STAT_ST, STAT_DX, STAT_IQ, STAT_HT, STAT_PER, STAT_IM)) || stat || incapacitated() || gurps_stat(STAT_WP) <= 0 || deathweb_stat_modifiers["willpower"])
		return FALSE
	var/amount = stat_type == STAT_IM ? 4 : (stat_type == STAT_PER ? 2 : 1)
	deathweb_add_stat_modifier("willpower", list("[stat_type]" = amount), 1 MINUTE)
	gain_willpower(-1)
	return TRUE
