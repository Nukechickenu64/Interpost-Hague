// Simplified cult rune scribing spell that creates rune types directly
/spell/rune_write
	name = "Scribe a Rune"
	desc = "Lets you inscribe a cult rune at your feet."

	school = "evocation"
	charge_max = 100
	charge_type = Sp_RECHARGE
	invocation_type = SpI_NONE

	spell_flags = CONSTRUCT_CHECK

	hud_state = "const_rune"

	smoke_amt = 1

/spell/rune_write/choose_targets(mob/user = usr)
	return list(user)

/spell/rune_write/cast(null, mob/user = usr)
	if(!user)
		return
	if(!iscultist(user))
		to_chat(user, "<span class='warning'>The forbidden knowledge eludes you.</span>")
		return
	// Need a sharp implement in either hand
	var/obj/item/weapon/tool_or_weapon = null
	for(var/obj/item/I in list(user.l_hand, user.r_hand))
		if(I && (I.sharp || I.edge))
			tool_or_weapon = I
			break
	if(!tool_or_weapon)
		to_chat(user, "<span class='warning'>You need something sharp to carve the rune (a knife, shard, or other edged implement).</span>")
		return
	if(!istype(user.loc, /turf))
		to_chat(user, "<span class='warning'>You need a solid surface to inscribe a rune.</span>")
		return
	if(locate(/obj/effect/rune) in user.loc)
		to_chat(user, "<span class='warning'>There is already a rune in this location.</span>")
		return

	var/list/choices = list(
		"Teleport" = /obj/effect/rune/teleport,
		"Summon Tome" = /obj/effect/rune/tome,
		"Convert" = /obj/effect/rune/convert,
		"Wall" = /obj/effect/rune/wall,
		"EMP" = /obj/effect/rune/emp,
		"Drain" = /obj/effect/rune/drain,
		"Confuse" = /obj/effect/rune/confuse,
		"Revive" = /obj/effect/rune/revive,
		"Blood Boil" = /obj/effect/rune/blood_boil,
		"Tear Reality" = /obj/effect/rune/tearreality,
		"Weapon" = /obj/effect/rune/weapon,
		"Shell" = /obj/effect/rune/shell,
		"Imbue" = /obj/effect/rune/imbue
	)

	var/choice = input(user, "Choose a rune to scribe (requires cult tome in inventory unless summoning one)", "Rune Scribing") as null|anything in choices
	if(!choice)
		return

	var/path = choices[choice]
	if(!path)
		return

	// All rune types except Summon Tome require carrying a cult tome
	if(choice != "Summon Tome")
		var/has_tome = 0
		for(var/obj/item/weapon/book/tome/T in user.contents)
			has_tome = 1; break
		if(!has_tome)
			to_chat(user, "<span class='warning'>You need your cult tome on you to recall the words for that rune.</span>")
			return

	var/turf/T = get_turf(user)
	if(!T)
		return

	// Writing takes time; longer for larger or more complex runes
	var/delay = 30
	if(choice == "Tear Reality")
		delay = 80
	else if(choice == "Teleport" || choice == "Revive")
		delay = 50
	else if(choice == "Wall" || choice == "Weapon" || choice == "Shell")
		delay = 45
	else if(choice == "Blood Boil")
		delay = 60
	else if(choice == "Imbue")
		delay = 55

	// Massive speed increase when using a converted knife or ritual knife
	var/converted_knife = 0
	if(istype(tool_or_weapon, /obj/item/weapon/material/knife/ritual))
		converted_knife = 1
	else
		// Some blades may be later flagged as cult-converted
		if(tool_or_weapon.cult_converted)
			converted_knife = 1

	if(converted_knife)
		// Apply a large speed-up; keep a sane floor so do_after still matters
		delay = max(5, round(delay / 4))
		// Add a flavorful tell to the knife description once
		if(!tool_or_weapon.cult_marked)
			tool_or_weapon.desc += "\nIts edge drinks in the light, a thin sheen of dried blood tracing eldritch angles."
			tool_or_weapon.cult_marked = 1

	user.visible_message("<span class='notice'>[user] kneels and begins carving a bloody rune with [tool_or_weapon].</span>", "<span class='cult'>You begin carving the rune... stay focused.</span>")
	if(!do_after(user, delay, T))
		to_chat(user, "<span class='warning'>Your concentration breaks and the carving fails.</span>")
		return

	// Determine blood cost per rune, then pay it as the carving completes.
	// Costs aligned roughly with make_rune() defaults.
	var/blood_cost = 5
	if(choice == "Summon Tome")
		blood_cost = 15
	else if(choice == "Drain")
		blood_cost = 10
	else if(choice == "Weapon" || choice == "Shell")
		blood_cost = 10
	else if(choice == "Blood Boil")
		blood_cost = 20
	else if(choice == "Revive")
		blood_cost = 25
	else if(choice == "Tear Reality")
		blood_cost = 50
	else if(choice == "Imbue")
		blood_cost = 3

	// Pay the blood cost using existing ritual helpers.
	user.pay_for_rune(blood_cost)

	var/obj/effect/rune/R = new path(T)
	if(R)
		var/area/A = get_area(T)
		log_and_message_admins("inscribed a [choice] rune at [A?.name] - [T.x]-[T.y]-[T.z] (blood cost [blood_cost]).", user)
		to_chat(user, "<span class='cult'>The blood takes shape as the rune forms.</span>")
	return
