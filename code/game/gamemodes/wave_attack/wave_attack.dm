#define WAVE_FIRST_WARNING   (10 MINUTES)
#define WAVE_WARNING_TIME    (2 MINUTES)
#define WAVE_MAX_DURATION    (10 MINUTES)
#define WAVE_MAX_SQUAD       12

/datum/game_mode/wave_attack
	name = "Wave Attack"
	config_tag = "wave_attack"
	round_description = "Hostile boarders will assault the station in escalating waves."
	extended_round_description = "Boarding parties will strike the station again and again, each wave better armed than the last. The bridge will report every incoming wave two minutes before it boards at the arrivals shuttle hallway. Hold the line."
	required_players = 0
	votable = 1
	round_autoantag = FALSE
	addantag_allowed = ADDANTAG_ADMIN
	var/wave = 0
	var/next_warning_at = 0
	var/spawn_at = 0
	var/list/wave_mobs = list()
	var/list/arrivals_area_types = list(/area/hallway/secondary/entry)

/datum/game_mode/wave_attack/announce()
	to_world("<B>The current game mode is - Wave Attack!</B>")
	to_world("<B>Hostile boarding parties will attack the station in escalating waves. The bridge will warn the crew before each one arrives.</B>")

/datum/game_mode/wave_attack/post_setup()
	. = ..()
	next_warning_at = world.time + WAVE_FIRST_WARNING

/datum/game_mode/wave_attack/process()
	..()
	if(SSevac.evacuation_controller && (SSevac.evacuation_controller.is_evacuating() || SSevac.evacuation_controller.has_evacuated()))
		return
	if(spawn_at)
		if(world.time >= spawn_at)
			spawn_wave()
		return
	if(next_warning_at && (world.time >= next_warning_at || (wave && wave_cleared())))
		announce_wave()

/datum/game_mode/wave_attack/proc/wave_cleared()
	for(var/mob/living/carbon/human/invader/I in wave_mobs)
		if(!QDELETED(I) && I.stat != DEAD)
			return FALSE
	return TRUE

/datum/game_mode/wave_attack/proc/announce_wave()
	next_warning_at = 0
	spawn_at = world.time + WAVE_WARNING_TIME
	command_announcement.Announce("Bridge sensors have picked up a hostile boarding craft closing on the station. Boarding wave [wave + 1] will arrive in approximately two minutes. All hands, prepare to repel boarders.", "Bridge Sensor Report")

/datum/game_mode/wave_attack/proc/is_active_crew(var/mob/living/carbon/human/H)
	return istype(H) && !istype(H, /mob/living/carbon/human/invader) && H.client && H.stat != DEAD

/datum/game_mode/wave_attack/proc/get_spawn_turfs(var/list/areas, var/needed)
	var/list/turfs = list()
	for(var/area/A in areas)
		for(var/turf/simulated/floor/F in A)
			if(!F.contains_dense_objects() && !(locate(/mob/living) in F))
				turfs += F
	return turfs.len >= needed ? turfs : null

/// Arrivals hallway unless crew are standing in it; then a random crew-free area; arrivals again if every area is occupied.
/datum/game_mode/wave_attack/proc/pick_spawn_turfs(var/needed)
	var/list/station_areas = SSinvaders.get_station_areas()
	var/list/occupied = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(is_active_crew(H))
			occupied |= get_area(H)

	var/list/arrivals = list()
	for(var/area/A in station_areas)
		if(is_type_in_list(A, arrivals_area_types))
			arrivals += A
	var/list/arrival_turfs = get_spawn_turfs(arrivals, needed)

	var/arrivals_occupied = length(arrivals & occupied)
	if(arrival_turfs && !arrivals_occupied)
		return arrival_turfs

	var/list/candidates = shuffle(station_areas - occupied - arrivals)
	for(var/area/A in candidates)
		var/list/turfs = get_spawn_turfs(list(A), needed)
		if(turfs)
			return turfs
	return arrival_turfs

/datum/game_mode/wave_attack/proc/get_squad_size()
	var/crew = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(is_active_crew(H))
			crew++
	return clamp(2 + round(wave / 2) + round(crew / 8), 2, WAVE_MAX_SQUAD)

/datum/game_mode/wave_attack/proc/spawn_wave()
	spawn_at = 0
	wave++
	next_warning_at = world.time + WAVE_MAX_DURATION
	var/size = get_squad_size()
	var/list/turfs = pick_spawn_turfs(size)
	if(!length(turfs))
		log_and_message_admins("Wave Attack: no valid spawn turfs for wave [wave].")
		return
	wave_mobs = list()
	var/list/spawn_pool = turfs.Copy()
	for(var/i in 1 to size)
		var/turf/spawn_turf = pick_n_take(spawn_pool)
		if(!spawn_turf)
			spawn_pool = turfs.Copy()
			spawn_turf = pick_n_take(spawn_pool)
			if(!spawn_turf)
				break
		var/mob/living/carbon/human/invader/wave/I = new(spawn_turf)
		I.equip_wave_gear(wave)
		wave_mobs += I
	if(length(wave_mobs))
		log_and_message_admins("Wave Attack: wave [wave] ([length(wave_mobs)] invaders) boarded at [get_area(wave_mobs[1])].")
	else
		log_and_message_admins("Wave Attack: wave [wave] failed to spawn any invaders.")

/datum/game_mode/wave_attack/declare_completion()
	..()
	to_world("<B>The station faced [wave] boarding wave\s.</B>")

/mob/living/carbon/human/invader/wave/equip_invader_gear()
	return // Equipped by the game mode once the wave tier is known.

/mob/living/carbon/human/invader/wave/proc/equip_wave_gear(var/wave)
	var/skill = min(40 + wave * 5, 75)
	skills[SKILL_MELEE] = rand(skill - 5, skill + 5)
	skills[SKILL_RANGE] = rand(skill - 5, skill + 5)

	equip_to_slot_or_del(new /obj/item/storage/backpack/satchel(src), slot_back)
	equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/under/syndicate/combat, /obj/item/clothing/under/merc, /obj/item/clothing/under/syndicate)), slot_w_uniform)
	equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/shoes/jackboots, /obj/item/clothing/shoes/dutyboots)), slot_shoes)
	if(wave >= 2 || prob(30))
		equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/gloves/thick, /obj/item/clothing/gloves/combat/gloves)), slot_gloves)
	if(prob(clamp((wave - 1) * 25, 0, 100)))
		equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/breastplate)), slot_wear_suit)
	if(prob(clamp((wave - 2) * 25, 0, 100)))
		equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/head/helmet, /obj/item/clothing/head/helmet/swat, /obj/item/clothing/head/helmet/siege)), slot_head)
	if(prob(50))
		equip_to_slot_or_del(new_invader_item(list(/obj/item/clothing/mask/balaclava, /obj/item/clothing/mask/gas, /obj/item/clothing/mask/gas/newsecurity)), slot_wear_mask)
	equip_to_slot_or_del(new /obj/item/crowbar/red(src), slot_l_store)

	var/list/melee_pool = list(
		/obj/item/weapon/material/knife,
		/obj/item/weapon/material/hatchet,
		/obj/item/weapon/melee/classic_baton,
	)
	if(wave >= 2)
		melee_pool += list(/obj/item/weapon/material/harpoon, /obj/item/weapon/melee/baton/loaded)
	if(wave >= 4)
		melee_pool += /obj/item/weapon/material/sword/siegesword

	// The first two waves are melee only.
	var/gun_chance = wave < 3 ? 0 : min(85, 25 + (wave - 3) * 15)
	if(!prob(gun_chance))
		equip_to_slot_or_del(new_invader_item(melee_pool), slot_r_hand)
		return

	var/list/gun_pool = list(/obj/item/weapon/gun/projectile/colt)
	if(wave >= 4)
		gun_pool += list(/obj/item/weapon/gun/projectile/automatic/wt550, /obj/item/weapon/gun/projectile/shotgun/pump/combat)
	if(wave >= 5)
		gun_pool += list(/obj/item/weapon/gun/projectile/automatic/c20r, /obj/item/weapon/gun/energy/gun, /obj/item/weapon/gun/energy/laser)
	var/obj/item/weapon/gun/G = new_invader_item(gun_pool)
	G.safety = 0
	equip_to_slot_or_del(G, slot_r_hand)
	equip_to_slot_or_del(new_invader_item(melee_pool), slot_l_hand)
	equip_spare_ammo(G, min(1 + round(wave / 3), 3))

#undef WAVE_FIRST_WARNING
#undef WAVE_WARNING_TIME
#undef WAVE_MAX_DURATION
#undef WAVE_MAX_SQUAD
