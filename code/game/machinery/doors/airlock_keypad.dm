//
//	Keypad Airlock
//
/obj/machinery/door/airlock/keypad // HERE
	name = "Keypad Entry Airlock"
	desc = "A door with a keypad lock."
	assembly_type = /obj/structure/door_assembly/door_assembly_keyp
	var/code = ""
	var/l_code = null
	var/l_set = 0
	var/l_setshort = 0
	var/l_hacking = 0
	var/open = 0

/obj/machinery/door/airlock/keypad/Topic(href, href_list)
	..()
	if((usr.stat || usr.restrained()) || (get_dist(src, usr) > 1))
		return
	if(href_list["type"])
		if(href_list["type"] == "E")
			if((src.l_set == 0) && (length(src.code) == 5) && (!src.l_setshort) && (src.code != "ERROR"))
				src.l_code = src.code
				src.l_set = 1
			else if((src.code == src.l_code) && (src.emagged == 0) && (src.l_set == 1))
				src.locked = 0
				playsound(src,bolts_rising, 30, 0, 3)
				update_icon()
				src.overlays = null
				src.code = null
			else
				src.code = "ERROR"
		else
			if((href_list["type"] == "R") && (src.emagged == 0) && (!src.l_setshort))
				src.locked = 1
				playsound(src,bolts_dropping, 30, 0, 3)
				src.overlays = null
				update_icon()
				src.code = null
				src.close(usr)
			else
				src.code += text("[]", href_list["type"])
				if(length(src.code) > 5)
					src.code = "ERROR"
		src.add_fingerprint(usr)
		for(var/mob/M in viewers(1, src.loc))
			if((M.client && M.machine == src))
				src.attack_hand(M)
			return
	return

/obj/machinery/door/airlock/keypad/attack_hand(mob/user as mob)
	if(!istype(user, /mob/living/silicon))
		if(src.isElectrified())
			if(src.shock(user, 100))
				return

	if(!istype(user, /mob/living/silicon))
		user.set_machine(src)
		var/dat = text("<TT><B>[]</B><BR>\n\nLock Status: []",src, (src.locked ? "LOCKED" : "UNLOCKED"))
		var/message = "Code"
		if((src.l_set == 0) && (!src.emagged) && (!src.l_setshort))
			dat += text("<p>\n<b>5-DIGIT PASSCODE NOT SET.<br>ENTER NEW DOOR PASSCODE.</b>")
		if(src.emagged)
			dat += text("<p>\n<font color=red><b>LOCKING SYSTE	M ERROR - 1701</b></font>")
		if(src.l_setshort)
			dat += text("<p>\n<font color=red><b>ALERT: MEMORY SYSTEM ERROR - 6040 201</b></font>")
		message = text("[]", src.code)
		if(!src.locked)
			message = "*****"
		dat += text("<HR>\n>[]<BR>\n<A href='?src=\ref[];type=1'>1</A>-<A href='?src=\ref[];type=2'>2</A>-<A href='?src=\ref[];type=3'>3</A><BR>\n<A href='?src=\ref[];type=4'>4</A>-<A href='?src=\ref[];type=5'>5</A>-<A href='?src=\ref[];type=6'>6</A><BR>\n<A href='?src=\ref[];type=7'>7</A>-<A href='?src=\ref[];type=8'>8</A>-<A href='?src=\ref[];type=9'>9</A><BR>\n<A href='?src=\ref[];type=R'>R</A>-<A href='?src=\ref[];type=0'>0</A>-<A href='?src=\ref[];type=E'>E</A><BR>\n</TT>", message, src, src, src, src, src, src, src, src, src, src, src, src)
		show_browser(user, dat, "window=caselock;size=300x280")

	if(src.p_open)
		wires.Interact(user)
	else
		..(user)
	return

// Separate from the keypad airlock above: this is a wall control for an existing airlock.
/obj/machinery/airlock_keypad
	name = "airlock keypad"
	desc = "A wall-mounted keypad that unlocks the single airlock within one tile."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doorctrlid"
	anchored = 1.0
	power_channel = ENVIRON
	idle_power_usage = 2
	active_power_usage = 5

	var/airlock_id = null
	var/code = null
	var/list/owner_roles = list()
	var/area/paper_destination = null
	var/list/active_attempts = list()
	var/list/granted_minds = list()

/obj/machinery/airlock_keypad/Initialize()
	. = ..()
	if(!code)
		code = add_zero(num2text(rand(0, 99999)), 5)

	if(owner_roles && owner_roles.len)
		for(var/datum/mind/mind in SSticker.minds)
			grant_code_to_mind(mind)
	else
		var/list/destination_turfs = paper_destination ? get_area_turfs(paper_destination) : null
		var/turf/destination = destination_turfs && destination_turfs.len ? pick(destination_turfs) : get_turf(src)
		new /obj/item/paper(destination, "Airlock ID: [airlock_id]<br>Combination: [code]", "Keypad [airlock_id] Combination")

/obj/machinery/airlock_keypad/Destroy()
	for(var/mob/user in active_attempts.Copy())
		clear_attempt(user)
	. = ..()

/obj/machinery/airlock_keypad/proc/grant_code_to_mind(datum/mind/mind)
	if(!mind || !owner_roles || !(mind.assigned_role in owner_roles) || (mind in granted_minds))
		return
	granted_minds += mind
	mind.store_memory("Airlock keypad [airlock_id] combination: [code]")

/obj/machinery/airlock_keypad/proc/user_knows_code(mob/user)
	return user && user.mind && length(user.mind.memory) && findtext(user.mind.memory, code)

/obj/machinery/airlock_keypad/proc/find_nearby_airlocks()
	var/list/nearby_airlocks = list()
	for(var/obj/machinery/door/airlock/door in range(1, src))
		nearby_airlocks += door
	return nearby_airlocks

/obj/machinery/airlock_keypad/proc/start_attempt(mob/user)
	clear_attempt(user)
	var/current_macro = user.client ? winget(user.client, "mainwindow", "macro") : null
	active_attempts[user] = list("start_turf" = get_turf(user), "digits" = "", "previous_macro" = current_macro)
	GLOB.moved_event.register(user, src, .proc/on_user_moved)
	user.set_machine(src)
	if(user.client)
		winset(user.client, "mainwindow", "macro=keypadentry mapwindow.map.focus=true")
	to_chat(user, "<span class='notice'>Enter the five-digit combination using the number keys. Moving will cancel the attempt.</span>")

/obj/machinery/airlock_keypad/proc/clear_attempt(mob/user)
	if(!user)
		return
	var/list/attempt = active_attempts[user]
	if(!attempt)
		return
	active_attempts -= user
	GLOB.moved_event.unregister(user, src, .proc/on_user_moved)
	if(user.client)
		var/previous_macro = attempt["previous_macro"]
		if(!length(previous_macro))
			previous_macro = "macro"
		winset(user.client, "mainwindow", "macro=[previous_macro] mapwindow.map.focus=true")
	if(user.machine == src)
		user.unset_machine()

/obj/machinery/airlock_keypad/proc/on_user_moved(var/atom/movable/mover, var/atom/old_loc, var/atom/new_loc)
	var/mob/user = mover
	if(active_attempts[user])
		clear_attempt(user)
		to_chat(user, "<span class='warning'>Your keypad attempt was canceled when you moved.</span>")

/obj/machinery/airlock_keypad/proc/valid_attempt(mob/user)
	var/list/attempt = active_attempts[user]
	return attempt && user && !user.stat && !user.restrained() && !(stat & (NOPOWER|BROKEN)) && get_dist(user, src) <= 1 && get_turf(user) == attempt["start_turf"]

/obj/machinery/airlock_keypad/examine(mob/user)
	. = ..()
	if(user && !user.stat && !user.restrained() && get_dist(user, src) <= 1 && !(stat & (NOPOWER|BROKEN)))
		if(user_knows_code(user))
			to_chat(user, "<span class='notice'>You recall this keypad's combination: <b>[code]</b>.</span>")
		start_attempt(user)

/obj/machinery/airlock_keypad/attack_hand(mob/user)
	if(!valid_attempt(user))
		to_chat(user, "<span class='notice'>Examine the keypad to begin an entry attempt.</span>")
	else
		to_chat(user, "<span class='notice'>Use the number keys to enter the combination. Press Escape to cancel.</span>")


/obj/machinery/airlock_keypad/proc/press_digit(mob/user, digit)
	if(!valid_attempt(user))
		clear_attempt(user)
		return
	if(!istext(digit) || length(digit) != 1 || !(digit in list("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")))
		return

	var/list/attempt = active_attempts[user]
	attempt["digits"] += digit
	if(length(attempt["digits"]) < 5)
		return

	if(attempt["digits"] != code)
		to_chat(user, "<span class='warning'>Incorrect combination. Examine the keypad to try again.</span>")
		clear_attempt(user)
		return

	var/list/nearby_airlocks = find_nearby_airlocks()
	var/obj/machinery/door/airlock/target = nearby_airlocks.len == 1 ? nearby_airlocks[1] : null

	if(!target)
		to_chat(user, "<span class='warning'>The keypad cannot identify a unique airlock within one tile.</span>")
	else if(target.unlock())
		to_chat(user, "<span class='notice'>The airlock bolts rise.</span>")
	else
		to_chat(user, "<span class='warning'>The airlock bolts do not respond.</span>")
	clear_attempt(user)

// Role presets grant their randomly generated code only to the matching job title.
// These use job titles rather than departments so mappers can restrict a keypad precisely.
/obj/machinery/airlock_keypad/role

/obj/machinery/airlock_keypad/role/assistant
	name = "assistant airlock keypad"
	owner_roles = list("Assistant")

/obj/machinery/airlock_keypad/role/greyhound
	name = "greyhound airlock keypad"
	owner_roles = list("Greyhound")

/obj/machinery/airlock_keypad/role/captain
	name = "captain airlock keypad"
	owner_roles = list("Captain")

/obj/machinery/airlock_keypad/role/executive_officer
	name = "executive officer airlock keypad"
	owner_roles = list("Executive Officer")

/obj/machinery/airlock_keypad/role/head_scientist
	name = "head scientist airlock keypad"
	owner_roles = list("Head Scientist")

/obj/machinery/airlock_keypad/role/general_researcher
	name = "general researcher airlock keypad"
	owner_roles = list("General Researcher")

/obj/machinery/airlock_keypad/role/medical_officer
	name = "medical officer airlock keypad"
	owner_roles = list("Medical Officer")

/obj/machinery/airlock_keypad/role/cmo
	name = "CMO airlock keypad"
	owner_roles = list("CMO")

/obj/machinery/airlock_keypad/role/major
	name = "major airlock keypad"
	owner_roles = list("Major")

/obj/machinery/airlock_keypad/role/enforcer
	name = "enforcer airlock keypad"
	owner_roles = list("Enforcer")

/obj/machinery/airlock_keypad/role/detective
	name = "detective airlock keypad"
	owner_roles = list("Detective")

/obj/machinery/airlock_keypad/role/vessel_overseer
	name = "vessel overseer airlock keypad"
	owner_roles = list("Vessel Overseer")

/obj/machinery/airlock_keypad/role/maintainer
	name = "maintainer airlock keypad"
	owner_roles = list("Maintainer")

/obj/machinery/airlock_keypad/role/excavator
	name = "excavator airlock keypad"
	owner_roles = list("Excavator")

/obj/machinery/airlock_keypad/role/cargo_technician
	name = "cargo technician airlock keypad"
	owner_roles = list("Cargo Technician")

/obj/machinery/airlock_keypad/role/machinist
	name = "machinist airlock keypad"
	owner_roles = list("Machinist")

/obj/machinery/airlock_keypad/role/cargo_assistant
	name = "cargo assistant airlock keypad"
	owner_roles = list("Cargo Assistant")

/obj/machinery/airlock_keypad/role/nutritionist
	name = "nutritionist airlock keypad"
	owner_roles = list("Nutritionist")

/obj/machinery/airlock_keypad/role/barkeeper
	name = "barkeeper airlock keypad"
	owner_roles = list("Barkeeper")

/obj/machinery/airlock_keypad/role/priest
	name = "priest airlock keypad"
	owner_roles = list("Priest")

/obj/machinery/airlock_keypad/role/sanitation_technician
	name = "sanitation technician airlock keypad"
	owner_roles = list("Sanitation Technician")

/obj/machinery/airlock_keypad/role/botanic
	name = "botanic airlock keypad"
	owner_roles = list("Botanic")

/obj/machinery/airlock_keypad/role/medical_assistant
	name = "medical assistant airlock keypad"
	owner_roles = list("Medical Assistant")
