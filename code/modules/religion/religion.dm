//PUTTING RELIGIOUS RELATED STUFF IN IT'S ON MODULES FOLDER FROM NOW ON. - Matt
/* (Legacy commented example removed) */

/datum/religion
	var/name = "NONE"
	var/favor = 0
	var/obj/item/holy_item = null
	var/shrine = null
	var/list/followers = list()
	var/list/territories = list()
	var/datum/request/request = null
	var/selectable_requests = list()
	var/selectable_rewards = list()
	var/selectable_punishments = list()
	var/whisper_lines = list()
	var/offering_items = list(/obj/item/paper)
	var/cult_id = null
// Cult-specific religion aligned with Nar-Sie
/datum/religion/narsie
	name = NARSIE_RELIGION
	cult_id = MODE_CULTIST
	holy_item = /obj/item/book/tome
	shrine = /obj/old_god_shrine/narsie
	favor = 0
	whisper_lines = list(
		"The geometer must be completed.",
		"Blood is the ink of revelation.",
		"Carve the angles. Open the way.",
		"The veil thins with every stroke."
	)
	offering_items = list(/obj/item/book/tome, /obj/item/weapon/material/knife/ritual)

/datum/religion/narsie/fire
	name = KHARIN_RELIGION
	cult_id = MODE_CULTIST_FIRE
	holy_item = /obj/item/book/tome/fire
	shrine = /obj/old_god_shrine/kharin
	whisper_lines = list("Feed the flame.", "The veil will burn.", "Kha'Rin consumes all.")
	offering_items = list(/obj/item/book/tome/fire, /obj/item/weapon/flame/candle)

/datum/religion/narsie/death
	name = REAPER_RELIGION
	cult_id = MODE_CULTIST_DEATH
	holy_item = /obj/item/book/tome/death
	shrine = /obj/old_god_shrine/reaper
	whisper_lines = list("All will cross the river.", "The Reaper waits.", "The veil is a shroud.")
	offering_items = list(/obj/item/book/tome/death, /obj/item/stack/teeth)

/datum/religion/proc/can_use_magic(mob/living/user)
	if(!user || user.religion != name)
		return FALSE
	if(cult_id)
		return same_cult(user, get_cult_by_religion(name))
	return name != LEGAL_RELIGION

/datum/religion/heretic
	name = HERETIC_RELIGION
	whisper_lines = list("The Mansus lies beyond the veil.", "Every door has a key.", "Knowledge demands a price.")

/datum/religion/heretic/can_use_magic(mob/living/user)
	return FALSE

/datum/religion/proc/show_rituals(mob/living/user)
	if(!can_use_magic(user))
		to_chat(user, "<span class='warning'>The rituals of this faith are closed to you.</span>")
		return
	to_chat(user, "<span class='notice'>The shrine rituals of [name]:</span>")
	for(var/spell_name in GLOB.all_spells)
		var/datum/old_god_spell/ritual = GLOB.all_spells[spell_name]
		if(ritual.old_god != name)
			continue
		var/list/ingredients = list()
		for(var/direction in ritual.requirments)
			var/obj/component_type = ritual.requirments[direction]
			ingredients += "[lowertext(direction)]: [initial(component_type.name)]"
		to_chat(user, "<span class='notice'><b>[ritual.name]</b>: [english_list(ingredients)]. Say: [ritual.phrase]</span>")

/mob/living/proc/update_religion_magic()
	verbs -= /mob/living/proc/praise_god
	verbs -= /mob/living/proc/make_shrine
	verbs -= /mob/living/proc/getBrothers
	var/datum/religion/faith = GLOB.all_religions[religion]
	if(faith && faith.can_use_magic(src))
		verbs |= /mob/living/proc/praise_god
		verbs |= /mob/living/proc/make_shrine
		verbs |= /mob/living/proc/getBrothers

/datum/religion/New()
	selectable_requests =  subtypesof(/datum/request)
	selectable_rewards = subtypesof(/datum/reward)
	selectable_punishments = subtypesof(/datum/punishment/)

/datum/religion/machina
	name = "Atheism"
	holy_item = /obj/item/weapon/brander
	whisper_lines = list("Remember: science protects.", "The researcher provides.", "Trust the Internal Affairs agent.")
	offering_items = list(/obj/item/spacecash/bundle/c10)

/*
/datum/religion/narsie
	name = "Narsie"
	holy_item = /obj/item/book/tome
	favor = 0
*/

/* GENERAL RELIGION PROCS */

//Stupidly simplistic? Probably. But I'm too tired to write something more complex.
/mob/living/proc/religion_is_legal()
	return !is_cult_religion(religion) && religion != HERETIC_RELIGION

//Reveals self as a heretic
/mob/living/proc/reveal_self()
	var/msg = ""
	if (religion_is_legal())  //Non-heretics will still deny
		msg = "I'm not a cultist, I swear it!"
	else
		msg = "YES!! I SERVE [uppertext(religion)]!"
	agony_scream()
	say(NewStutter(msg))

/* LEGAL RELIIGON PROCS */
//PRAYER
var/accepted_prayer //The prayer that all those who are not heretics will have.

proc/generate_random_prayer()//This generates a new one.
	var/prayer = pick("Oh great AI. ", "Oh glorious science. ", "Research, our Lord and Saviour. ")
	prayer += pick("You bathe us in your glow. ", "You bathe our minds in you omniscient wisdom. ", "You bathe our [pick("station","corporation","planets")] in your knowledge. ")
	prayer += pick("Science be praised. ", "Science save us all. ", "Science guide us all. ")
	prayer += "Atheoi."
	return prayer

/mob/living/proc/recite_prayer()
	set category = "Religion"
	set name = "Recite the prayer"

	say(mind.prayer)

/mob/living/verb/recite_prayer_hotkey()
	set name = ".praiselord"

	recite_prayer()

//Try to reveal a random heretic
/mob/living/proc/interrogate()
	set category = "Religion"
	set name = "Interrogate"

	var/list/victims = list()
	for(var/mob/living/carbon/human/C in oview(1))
		victims += C
	var/mob/living/carbon/human/T = input(src, "Who will we interrogate?") as null|anything in victims
	if(!T) return
	if(!(T in view(1))) return
	say("[T], are you a cultist!?")
	if(prob((T.getHalLoss()/3) - T.stats[STAT_HT]))  //Higher con helps your resist torture
		T.reveal_self()
		return

//Reveals a random heretic
/mob/living/proc/reveal_heretics()
	var/msg = " is one of Nar-Sie's cultists!"
	var/name = ""
	if (religion_is_legal())  //Non-heretics will say nothing
		msg = "I don't know anything!"
		say(NewStutter(msg))
		return
	else
		var/datum/religion/R_narsie = GLOB.all_religions[religion]
		if(istype(R_narsie) && R_narsie.followers.len)
			name = pick(R_narsie.followers)
		if(name)
			say(NewStutter("[name] is one of them!"))
		else
			say("I'm the only one!")

/* ILLEGAL RELIGION PROCS */
/datum/religion/proc/claim_territory(area/territory,var/claiming_religion)
	var/datum/religion/R = GLOB.all_religions[claiming_religion]
	if(istype(R))
		R.territories |= territory
	return

/datum/religion/proc/lose_territory(area/territory,var/claiming_religion)
	var/datum/religion/R = GLOB.all_religions[claiming_religion]
	if(istype(R))
		R.territories -= territory
	return

/datum/religion/proc/territory_claimed(area/territory, mob/user)
	for (var/name in GLOB.all_religions)
		var/datum/religion/R = GLOB.all_religions[name]
		if(istype(R) && (territory in R.territories))
			return name
	return null

//This is general, and should be overloaded for ~flavor~
/datum/religion/proc/generate_random_phrase()
		var/phrase = pick("Oh great [name] ", "Oh our Lord [name]. ", "[name], our Lord and Saviour. ")
		phrase += pick("You bathe us in your glow. ", "You bathe our minds in you omniscient wisdom. ", "You bathe our [pick("station","corporation","planets")] in your knowledge. ")
		phrase += pick("[name] be praised. ", "[name] save us all. ", "[name] guide us all. ")
		phrase += "Amen."
		return phrase

/datum/religion/proc/whisper_to_followers()
	var/whisper_line = pick(whisper_lines)
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.religion == name)
			playsound(player, "sound/effects/badmood[pick(1,4)].ogg",50,1)
			to_chat(player, "<span class='danger'>[whisper_line]</span>")

//Makes a request, and tells all followers about it
/datum/religion/proc/request()
	request = pick(selectable_requests)
	//request = new request(name)
	request = new /datum/request/offering/(name)
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.religion == name)
			playsound(player, "sound/effects/badmood[pick(1,4)].ogg",50,1)
			to_chat(player, "<span class='danger'><font size=3>[request.message]</font></span>")

/datum/religion/proc/reward(var/mob/living/target)
	var/datum/reward/reward = pick(selectable_rewards)
	reward = new reward
	reward.do_reward(target)

/datum/religion/proc/punish(var/mob/living/target)
	var/datum/punishment/punishment = pick(selectable_punishments)
	punishment = new punishment
	punishment.do_punishment(target)

/datum/religion/proc/can_claim_for_gods(mob/user, atom/target)
	//Check the area for if there's another shrine already, or the arbiters have already claimed it with TODO:?????
	var/area/A = get_area(target)
	if(!A)
		to_chat(user, "<span class='warning'>[name] refuses your offering.</span>")
		return FALSE

	var/occupying_religion = territory_claimed(A, user)
	if(occupying_religion == name)
		to_chat(user,"<span class='danger'>There is already a shrine in this area!</span>")
		return FALSE

	if(occupying_religion)
		to_chat(user, "<span class='danger'>Something in the area is blocking your connection to [name]! Find and destroy it!</span>")
		return FALSE

	// If you pass the gaunlet of checks, you're good to proceed
	return TRUE

/datum/religion/proc/spawn_item(mob/living/user, var/divisor = 0.1)
	var/turf/T = get_turf(user)
	var/datum/religion/user_religion = GLOB.all_religions[user.religion]
	for(var/obj/old_god_shrine/shrine in view(user, 5))
		//If we can see an allied shrine nearby, we have more chance to spawn a reward.
		if(istype(user_religion) && shrine.shrine_religion == user_religion)
			divisor = 1
		if(istype(user_religion) && prob(user_religion.favor * divisor))
			var/S = pick(GLOB.all_spells)
			var/datum/old_god_spell/OGS = GLOB.all_spells[S]
			if(istype(OGS) && OGS.old_god == name && OGS.requirments.len)
				var/reward = pick(OGS.requirments)
				var/obj/reward_obj = OGS.requirments[reward]
				new reward_obj(T)

/mob/living/proc/praise_god()
	set category = "Old God Magic"
	set name = "PraiseyourGod"

	var/datum/religion/user_religion = GLOB.all_religions[religion]
	if(!user_religion || !user_religion.can_use_magic(src))
		to_chat(src, "<span class='warning'>Your faith does not grant this magic.</span>")
		return
	var/timer = 30
	var/praise_sound = "sound/effects/Cultistemessage[pick(1,10)].ogg"
	//You need your god's item to do this
	if(!istype(get_active_hand(), user_religion.holy_item) && !istype(get_inactive_hand(), user_religion.holy_item))
		if(isnull(religion_token))
			if(do_after(src, timer) && user_religion.can_use_magic(src))
				var/T =  get_turf(src)
				playsound(get_turf(src), praise_sound,30,0)
				to_chat(src, "<span class='danger'>A [user_religion.holy_item] appears at your feet!</span>")
				var/datum/religion/R = GLOB.all_religions[religion]
				var/holy_item_type
				if(istype(R) && R.holy_item)
					if(ispath(R.holy_item))
						holy_item_type = R.holy_item
					else if(istype(R.holy_item))
						var/obj/item/holy_item = R.holy_item
						holy_item_type = holy_item.type
				var/new_holy_item = new holy_item_type(T)
				religion_token = new_holy_item
		else
			to_chat(src, "<span class='warning'>You can't praise your god without your [user_religion.holy_item]!</span>")
		return 0
	if(!doing_something)
		var/self = "You raise your [initial(user_religion.holy_item.name)] and chant praise to your god."
		visible_message("<span class='warning'>\The [src] begins speaking praise for their god.</span>", "<span class='notice'>[self]</span>", "[src] praises their god! .")
		doing_something = 1
		if(do_after(src, timer) && user_religion.can_use_magic(src))
			//These variables used to just be functions that returned a hard coded value.  So don't blame me, this is actually faster.
			user_religion.favor += 10
			playsound(get_turf(src), praise_sound,30,0)
			doing_something = 0
			user_religion.spawn_item(src)
			if(user_religion.request)
				if(user_religion.request.check_complete(src))
					user_religion.reward(src)
					QDEL_NULL(user_religion.request)
			return 1
		else
			to_chat(src, "<span class='notice'>Your prayer is interrupted.</span>")
			doing_something = 0
			return 0
	else
		to_chat(src, "<span class='notice'>You are already doing something.</span>")
		return 0


/mob/living/proc/make_shrine()
	set category = "Old God Magic"
	set name = "CreateShrine"
	var/turf/T = get_turf(src)
	var/datum/religion/user_religion = GLOB.all_religions[religion]
	if(!user_religion || !user_religion.can_use_magic(src) || !ispath(user_religion.shrine))
		to_chat(src, "<span class='warning'>Your faith does not grant shrine creation.</span>")
		return
	//You need your god's item to do this
	if(!istype(get_active_hand(), user_religion.holy_item) && !istype(get_inactive_hand(), user_religion.holy_item))
		to_chat(src, "<span class='warning'>You can't draw a rune without your [user_religion.holy_item]!</span>")
		return
	//Need 30 favor to make a shrine
	if(user_religion.favor < 30)
		to_chat(src, "<span class='warning'>You don't feel devoted enough to your god.</span>")
		return
	var/self = "You deftly use your [user_religion.holy_item] to create the shrine."
	var/timer = 20
	if(user_religion.can_claim_for_gods(src,T) && !doing_something)
		visible_message("<span class='warning'>\The [src] quickly draws on the floor and begins to whisper quietly to themselves.</span>", "<span class='notice'>[self]</span>", "You hear scratching.")
		doing_something = 1
		if(do_after(src, timer) && user_religion.can_use_magic(src) && user_religion.favor >= 30 && user_religion.can_claim_for_gods(src, T))
			//These variables used to just be functions that returned a hard coded value.  So don't blame me, this is actually faster.
			new user_religion.shrine(T)
			doing_something = 0
			return 1
		doing_something = 0
	//If we somehow got here
	doing_something = 0
	return 0

/mob/living/proc/getBrothers()
	set name = "getBrothers"
	var/datum/religion/narsie_religion = GLOB.all_religions[religion]
	if(!narsie_religion || !narsie_religion.can_use_magic(src))
		to_chat(src, "<span class='warning'>You have no fellow worshippers to contact.</span>")
		return
	if(istype(narsie_religion) && narsie_religion.followers.len > 1)
		var/brothers_message = "<span class='info'>Your fellow cultists are:<br></span>"
		for(var/H in narsie_religion.followers)
			brothers_message += "<span class='danger'><b>[H], who follows [religion].</b></span>\n"
		to_chat(src, brothers_message)
	else
		to_chat(src, "<span class='info'>You appear to be serving [religion] alone.</span>")