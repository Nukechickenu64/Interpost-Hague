#define BBS_OFFLINE    0
#define BBS_DIALING    1
#define BBS_MENU       2
#define BBS_BOARD      3
#define BBS_THREAD     4
#define BBS_COMPLETE   5
#define BBS_NO_CARRIER 6

#define BBS_HEX_DIGITS "0123456789ABCDEF"
#define BBS_READ_COST  2
#define BBS_GUESS_COST 2
#define BBS_PAGE_COST  3
#define BBS_DIAL_TIME  29 SECONDS

/obj/machinery/computer/bbs_terminal
	name = "BBS research terminal"
	desc = "A dial-up terminal for trawling scientific bulletin boards. Feed it a fabricator data disk to pull research files off the line."
	icon_keyboard = "rd_key"
	icon_screen = "rdcomp"
	light_color = "#a97faa"
	circuit = /obj/item/circuitboard/bbs_terminal
	var/obj/item/disk/tech_disk/disk
	var/state = BBS_OFFLINE
	var/board_id
	var/board_type
	var/target_level
	var/code
	var/list/claims
	var/list/threads
	var/thread_index
	var/line_time
	var/list/guess_log
	var/status_msg
	var/max_level = 8
	var/board_cooldown = 3 MINUTES
	var/list/board_cooldowns = list()
	// Session flavor, rolled on each successful dial-in.
	var/list/online_handles
	var/list/troll_handles
	var/caller_number
	var/motd
	var/paged_sysop
	var/carrier_reason
	var/dial_attempt = 0

/obj/machinery/computer/bbs_terminal/Destroy()
	if(disk)
		disk.dropInto(loc)
		disk = null
	return ..()

/obj/machinery/computer/bbs_terminal/emag_act(var/remaining_charges, var/mob/user)
	if(emagged)
		return
	emagged = 1
	to_chat(user, "<span class='notice'>You splice a pirate dialer into \the [src]'s modem.</span>")
	return 1

/obj/machinery/computer/bbs_terminal/attackby(var/obj/item/I, var/mob/user)
	if(!istype(I, /obj/item/disk))
		return ..()
	if(!istype(I, /obj/item/disk/tech_disk))
		to_chat(user, "<span class='notice'>\The [src] cannot read disks in that format.</span>")
		return
	if(disk)
		to_chat(user, "<span class='notice'>A disk is already loaded into \the [src].</span>")
		return
	if(!user.unEquip(I, src))
		return
	disk = I
	to_chat(user, "<span class='notice'>You slot \the [I] into \the [src].</span>")
	if(disk.stored)
		to_chat(user, "<span class='warning'>The disk already holds data. A new download will overwrite it.</span>")
	updateUsrDialog()

/obj/machinery/computer/bbs_terminal/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/computer/bbs_terminal/attack_hand(mob/user)
	if(..())
		return
	user.set_machine(src)
	var/dat = "<div style='background:#020a02;color:#4cff6a;font-family:Courier New,monospace;padding:8px;border:1px solid #1d5c26;'>"
	dat += render_screen()
	dat += "</div><br>"
	if(disk)
		dat += "Media: [disk.name][disk.stored ? " (holds [disk.stored.name] L[disk.stored.level])" : " (blank)"] - <a href='byond://?src=\ref[src];eject=1'>Eject disk</a>"
	else
		dat += "<span class='note'>No media inserted.</span>"
	dat += " | <a href='byond://?src=\ref[src];close=1'>Close</a>"
	user << browse(ui_build_styled_html("BBS Terminal", dat), "window=bbs_terminal;size=520x560")
	onclose(user, "bbs_terminal")

/obj/machinery/computer/bbs_terminal/proc/bbs_link(var/text, var/href)
	return "<a style='color:#b8ffc4' href='byond://?src=\ref[src];[href]'>[text]</a>"

/obj/machinery/computer/bbs_terminal/proc/render_screen()
	var/dat = ""
	if(status_msg)
		dat += "<b>[status_msg]</b><br><br>"
	switch(state)
		if(BBS_OFFLINE)
			dat += "TERMCOM v2.1 READY<br>MODEM: 2400 BAUD<br><br>"
			dat += disk ? bbs_link("ATDT 555-0199 (dial in)", "dial=1") : "INSERT MEDIA TO ENABLE DOWNLOADS."
		if(BBS_DIALING)
			dat += "ATDT 555-0199<br>RINGING...<br>CONNECT 2400<br>NEGOTIATING..."
		if(BBS_NO_CARRIER)
			dat += "[carrier_reason ? carrier_reason : "NO CARRIER"]<br><br>[bbs_link("Redial", "dial=1")] | [bbs_link("Return to prompt", "hangup=1")]"
		if(BBS_MENU)
			dat += {"<pre style='margin:0'>
 .-=-=-=-=-=-=-=-=-=-=-=-=-.
 |  T H E   A R C H I V E  |
 |   est. 2384 * node 3/4  |
 '-=-=-=-=-=-=-=-=-=-=-=-='</pre>"}
			dat += "SysOp: d1gital_monk | You are caller #[caller_number]<br>"
			dat += "<i>MOTD: [motd]</i><br>"
			dat += "Users online: [english_list(online_handles)]<br><br>FILE AREAS:<br>"
			for(var/T in subtypesof(/datum/tech))
				var/datum/tech/tech_type = T
				var/id = initial(tech_type.id)
				if(id == TECH_ARCANE || (id == TECH_ILLEGAL && !emagged))
					continue
				var/area_name = id == TECH_ILLEGAL ? "Warez Underground" : initial(tech_type.name)
				var/wait = board_cooldowns[id] ? board_cooldowns[id] - world.time : 0
				if(wait > 0)
					dat += "&nbsp;- [area_name] <i>(SYSOP: area busy, [round(wait / 10)]s)</i><br>"
				else
					dat += "&nbsp;- [bbs_link(area_name, "board=[id]")]<br>"
			dat += "<br>[bbs_link("Log off", "hangup=1")]"
		if(BBS_BOARD)
			dat += "=== [uppertext(CallTechName(board_id))] FILES ===<br>"
			dat += "Target file: research archive, revision [target_level]<br>"
			dat += "Line time remaining: [line_time]<br><br>THREADS:<br>"
			for(var/i in 1 to threads.len)
				var/list/thread = threads[i]
				var/flags = ""
				if(thread["read"])
					flags = thread["garbled"] ? " <i>(garbled)</i>" : " (read)"
				dat += "&nbsp;[i]. [bbs_link(thread["title"], "thread=[i]")] -- [thread["author"]][flags]<br>"
			dat += "<br>TRANSFER KEY: [render_key()]<br>"
			for(var/entry in guess_log)
				dat += "&nbsp;&nbsp;[entry]<br>"
			dat += "<br>[bbs_link("Request download", "guess=1")] | "
			if(!paged_sysop)
				dat += "[bbs_link("Page the SysOp", "page=1")] | "
			dat += "[bbs_link("Back to areas", "menu=1")]"
		if(BBS_THREAD)
			var/list/thread = threads[thread_index]
			dat += "=== [thread["title"]] ===<br>posted by: [thread["author"]]<br><br>"
			if(thread["garbled"])
				dat += "[garble_text(thread["body"])]<br><br><i>±%$# LINE NOISE #$%± -- [bbs_link("re-request page (free)", "thread=[thread_index]")]</i><br><br>"
			else
				dat += "[thread["body"]]<br><br>"
			dat += "Line time remaining: [line_time]<br>[bbs_link("Back to threads", "board_back=1")]"
		if(BBS_COMPLETE)
			dat += "TRANSFER COMPLETE.<br>[CallTechName(board_id)] archive revision [target_level] written to media.<br><br>"
			dat += "EJECT MEDIA AND UPLOAD AT AN R&D CONSOLE.<br><br>[bbs_link("Back to areas", "menu=1")] | [bbs_link("Log off", "hangup=1")]"
	return dat

/obj/machinery/computer/bbs_terminal/proc/render_key()
	var/out = ""
	for(var/i in 1 to length(code))
		var/list/c = claims[i]
		if(!c || !c.len)
			out += "_"
		else if(c.len == 1)
			out += c[1]
		else
			out += "\[[jointext(c, "/")]?\]"
		out += " "
	return out

/obj/machinery/computer/bbs_terminal/CanUseTopic(var/mob/user, var/datum/topic_state/state, var/href_list)
	if(src.state == BBS_DIALING && href_list && !href_list["close"] && !href_list["eject"])
		return min(..(), STATUS_UPDATE)
	return ..()

/obj/machinery/computer/bbs_terminal/OnTopic(var/mob/user, var/list/href_list)
	status_msg = null
	if(href_list["close"])
		close_browser(user, "window=bbs_terminal")
		user.unset_machine()
		return TOPIC_HANDLED

	if(href_list["eject"])
		if(disk)
			disk.dropInto(loc)
			disk = null
			if(state == BBS_COMPLETE || state == BBS_NO_CARRIER)
				state = BBS_OFFLINE
			else if(state != BBS_OFFLINE)
				disconnect()
		. = TOPIC_REFRESH

	else if(href_list["dial"] && (state == BBS_OFFLINE || state == BBS_NO_CARRIER))
		if(!disk)
			status_msg = "ERROR: NO MEDIA."
		else
			state = BBS_DIALING
			dial_attempt++
			playsound(loc, 'sound/machines/bbs_dialup.ogg', 35, FALSE)
			addtimer(CALLBACK(src, .proc/finish_dial, user, dial_attempt), BBS_DIAL_TIME)
		. = TOPIC_REFRESH

	else if(href_list["hangup"])
		state = BBS_OFFLINE
		. = TOPIC_REFRESH

	else if(href_list["menu"] && (state == BBS_BOARD || state == BBS_COMPLETE))
		state = BBS_MENU
		. = TOPIC_REFRESH

	else if(href_list["board"] && state == BBS_MENU)
		open_board(href_list["board"])
		. = TOPIC_REFRESH

	else if(href_list["thread"] && state == BBS_BOARD)
		var/index = text2num(href_list["thread"])
		if(index && index >= 1 && index <= threads.len)
			read_thread(index)
		. = TOPIC_REFRESH

	else if(href_list["board_back"] && state == BBS_THREAD)
		state = BBS_BOARD
		. = TOPIC_REFRESH

	else if(href_list["guess"] && state == BBS_BOARD)
		var/entry = input(user, "Enter the [length(code)]-digit hex transfer key.", "Transfer key") as text|null
		if(entry && state == BBS_BOARD && CanUseTopic(user) == STATUS_INTERACTIVE)
			try_guess(uppertext(entry))
		. = TOPIC_REFRESH

	else if(href_list["page"] && state == BBS_BOARD && !paged_sysop)
		page_sysop()
		. = TOPIC_REFRESH

	if(. == TOPIC_REFRESH)
		attack_hand(user)

/obj/machinery/computer/bbs_terminal/proc/finish_dial(var/mob/user, var/attempt)
	if(state != BBS_DIALING || attempt != dial_attempt)
		return
	if(!disk)
		state = BBS_OFFLINE
		refresh_dial_viewers(user)
		return
	var/list/handles = shuffle(handle_pool())
	troll_handles = list(handles[1], handles[2])
	online_handles = handles.Copy(3, 3 + rand(2, 4))
	caller_number = rand(10000, 42000)
	motd = pick(motd_pool())
	state = BBS_MENU
	refresh_dial_viewers(user)

/obj/machinery/computer/bbs_terminal/proc/refresh_dial_viewers(var/mob/user)
	updateUsrDialog()
	if(user && user.client && user.machine == src && !(user in viewers(1, src)) && CanUseTopic(user) >= STATUS_UPDATE)
		attack_hand(user)

/obj/machinery/computer/bbs_terminal/proc/disconnect(var/reason)
	state = BBS_NO_CARRIER
	carrier_reason = reason || pick("NO CARRIER", "CARRIER LOST", "+++ ATH0<br>NO CARRIER", "SYSOP HAS DROPPED YOUR LINE")
	code = null
	threads = null
	claims = null
	guess_log = null

/obj/machinery/computer/bbs_terminal/proc/open_board(var/id)
	if(id == TECH_ARCANE || (id == TECH_ILLEGAL && !emagged))
		return
	if(board_cooldowns[id] && board_cooldowns[id] > world.time)
		status_msg = "SYSOP: AREA BUSY. TRY AGAIN LATER."
		return
	board_type = null
	for(var/T in subtypesof(/datum/tech))
		var/datum/tech/tech_type = T
		if(initial(tech_type.id) == id)
			board_type = T
			break
	if(!board_type)
		return
	var/level = get_network_level(board_type)
	if(level >= max_level)
		status_msg = "NO NEWER FILES IN THIS AREA."
		return
	board_id = id
	target_level = level + 1

	var/code_length = 3 + round(target_level / 3)
	code = ""
	for(var/i in 1 to code_length)
		code += pick_hex()
	claims = new /list(code_length)
	guess_log = list()
	line_time = 26 - target_level
	paged_sysop = FALSE

	var/list/clue_positions = list()
	for(var/i in 1 to code_length)
		clue_positions += i
	clue_positions = shuffle(clue_positions)
	clue_positions.Cut(max(1, code_length - 2) + 1)

	var/list/clean_handles = shuffle(handle_pool()) - troll_handles

	// Pinned bulletin: names one troll and carries the key checksum.
	var/crc = 0
	for(var/i in 1 to code_length)
		crc = (crc + hex_val(copytext(code, i, i + 1))) % 16
	var/pinned_body = "Welcome to the [uppertext(CallTechName(board_id))] area. House rules apply.<br><br>\
		1. We have had FAKE transfer keys posted lately. Confirmed troll: <b>[pick(troll_handles)]</b>. There may be others. Verify before you trust.<br>\
		2. Archive integrity header for the current file: all key digits sum to <b>[hex_char(crc)]</b> (hex, mod 16). Use it to check your key.<br>\
		3. No leeching. The SysOp sees everything."
	threads = list(list("title" = "SYSOP BULLETIN - READ FIRST", "author" = "d1gital_monk", "body" = pinned_body, "clue" = 0, "read" = FALSE, "pinned" = TRUE))

	var/list/body_threads = list()
	// True clues, each in a random encoding.
	for(var/pos in clue_positions)
		var/digit = copytext(code, pos, pos + 1)
		body_threads += list(list("author" = pick(clean_handles), "body" = "[pick(clue_openers())] [encode_clue(pos, digit)]. [pick(clue_closers())]", "clue" = pos, "read" = FALSE))
	// Red herrings: trolls post convincing but wrong digits.
	for(var/i in 1 to rand(1, 2))
		var/pos = rand(1, code_length)
		var/real = copytext(code, pos, pos + 1)
		var/fake = real
		while(fake == real)
			fake = pick_hex()
		body_threads += list(list("author" = pick(troll_handles), "body" = "[pick(clue_openers())] [encode_clue(pos, fake)]. [pick(clue_closers())]", "clue" = pos, "fake_digit" = fake, "read" = FALSE))
	// One truthful global hint.
	var/letters = 0
	for(var/i in 1 to code_length)
		if(hex_val(copytext(code, i, i + 1)) > 9)
			letters++
	body_threads += list(list("author" = pick(clean_handles), "body" = "Ran the archive header through my parser: the key has exactly [letters] letter digit\s (A-F). Make of that what you will.", "clue" = 0, "read" = FALSE))
	// Decoy chatter.
	while(body_threads.len < 7)
		body_threads += list(list("author" = pick(clean_handles), "body" = pick(decoy_bodies()), "clue" = 0, "read" = FALSE))

	body_threads = shuffle(body_threads)
	var/list/titles = shuffle(thread_titles())
	for(var/i in 1 to body_threads.len)
		var/list/thread = body_threads[i]
		thread["title"] = titles[i]
		threads += list(thread)
	state = BBS_BOARD

/obj/machinery/computer/bbs_terminal/proc/read_thread(var/index)
	var/list/thread = threads[index]
	if(!thread["read"])
		line_time -= BBS_READ_COST
		thread["read"] = TRUE
		if(!thread["pinned"] && prob(20))
			thread["garbled"] = TRUE
		else
			apply_clue(thread)
	else if(thread["garbled"])
		thread["garbled"] = FALSE
		apply_clue(thread)
	if(line_time <= 0)
		disconnect()
		return
	thread_index = index
	state = BBS_THREAD

/obj/machinery/computer/bbs_terminal/proc/apply_clue(var/list/thread)
	var/pos = thread["clue"]
	if(!pos)
		return
	var/digit = thread["fake_digit"] || copytext(code, pos, pos + 1)
	if(!claims[pos])
		claims[pos] = list()
	var/list/c = claims[pos]
	c |= digit

/obj/machinery/computer/bbs_terminal/proc/page_sysop()
	paged_sysop = TRUE
	line_time -= BBS_PAGE_COST
	if(line_time <= 0)
		disconnect("SYSOP HAS DROPPED YOUR LINE")
		return
	if(prob(40))
		var/list/unknown = list()
		for(var/i in 1 to length(code))
			var/list/c = claims[i]
			if(!c || c.len != 1 || c[1] != copytext(code, i, i + 1))
				unknown += i
		if(unknown.len)
			var/pos = pick(unknown)
			var/digit = copytext(code, pos, pos + 1)
			claims[pos] = list(digit)
			status_msg = "SYSOP: fine. slot [pos] is '[digit]'. you did NOT hear it from me."
		else
			status_msg = "SYSOP: you already have the whole key. stop paging me."
	else
		status_msg = pick("SYSOP: busy. figure it out yourself.",
			"SYSOP: paging me costs line time, you know.",
			"SYSOP: read the bulletin. it's pinned for a reason.",
			"SYSOP: half the keys posted this week were fake. trust no one.")

/obj/machinery/computer/bbs_terminal/proc/try_guess(var/guess)
	var/code_length = length(code)
	if(length(guess) != code_length)
		status_msg = "KEY MUST BE [code_length] HEX DIGITS."
		return
	for(var/i in 1 to code_length)
		if(!findtext(BBS_HEX_DIGITS, copytext(guess, i, i + 1)))
			status_msg = "KEY MUST BE [code_length] HEX DIGITS."
			return

	if(guess == code)
		complete_download()
		return

	var/exact = 0
	var/list/code_left = list()
	var/list/guess_left = list()
	for(var/i in 1 to code_length)
		var/c = copytext(code, i, i + 1)
		var/g = copytext(guess, i, i + 1)
		if(c == g)
			exact++
		else
			code_left[c] = code_left[c] + 1
			guess_left[g] = guess_left[g] + 1
	var/misplaced = 0
	for(var/g in guess_left)
		misplaced += min(guess_left[g], code_left[g] || 0)
	guess_log += "[guess]: [exact] in place, [misplaced] misplaced"

	line_time -= BBS_GUESS_COST
	if(line_time <= 0)
		disconnect()
		return
	status_msg = "KEY REJECTED."

/obj/machinery/computer/bbs_terminal/proc/complete_download()
	if(!disk)
		disconnect()
		return
	var/datum/tech/T = new board_type()
	T.level = target_level
	disk.stored = T
	board_cooldowns[board_id] = world.time + board_cooldown
	state = BBS_COMPLETE
	code = null
	threads = null
	claims = null
	guess_log = null
	playsound(loc, 'sound/machines/ping.ogg', 30, 1)

// Highest level the station's research network already has, so downloads are always an upgrade.
/obj/machinery/computer/bbs_terminal/proc/get_network_level(var/tech_type)
	var/datum/tech/base = tech_type
	. = initial(base.level)
	var/id = initial(base.id)
	for(var/obj/machinery/r_n_d/server/S in SSmachines.machinery)
		if(istype(S, /obj/machinery/r_n_d/server/centcom) || !S.files)
			continue
		for(var/datum/tech/known in S.files.known_tech)
			if(known.id == id)
				. = max(., known.level)

/obj/machinery/computer/bbs_terminal/proc/pick_hex()
	var/index = rand(1, length(BBS_HEX_DIGITS))
	return copytext(BBS_HEX_DIGITS, index, index + 1)

/obj/machinery/computer/bbs_terminal/proc/hex_val(var/c)
	return findtext(BBS_HEX_DIGITS, c) - 1

/obj/machinery/computer/bbs_terminal/proc/hex_char(var/v)
	return copytext(BBS_HEX_DIGITS, v + 1, v + 2)

// A digit clue in one of several encodings the player must decode.
/obj/machinery/computer/bbs_terminal/proc/encode_clue(var/pos, var/digit)
	var/v = hex_val(digit)
	switch(rand(1, 3))
		if(1)
			return "slot [pos] of the transfer key is '[digit]'"
		if(2)
			var/bits = ""
			for(var/i = 3, i >= 0, i--)
				bits += ((v >> i) & 1) ? "1" : "0"
			return "slot [pos] of the transfer key is [bits] in binary"
		if(3)
			var/a = rand(0, 15)
			var/b = (v - a + 16) % 16
			return "slot [pos] of the transfer key is [hex_char(a)] plus [hex_char(b)] (hex, wraps past F)"

/obj/machinery/computer/bbs_terminal/proc/garble_text(var/text)
	var/out = ""
	for(var/i in 1 to length(text))
		var/c = copytext(text, i, i + 1)
		out += (prob(30) && c != "<" && c != ">") ? pick("#", "%", "&", "$", "@", "~") : c
	return out

/obj/machinery/computer/bbs_terminal/proc/handle_pool()
	return list("xXphoronXx", "modemqueen", "TAB_damage", "null_carrier", "ROMhacker", "glassjaw",
		"2400baudrate", "capt_crunch", "wirehead", "deckard_b26", "sys_remorse", "hexpriest",
		"lady_lovelace", "warez_wolf", "packetgoblin", "the_janitor", "bluebox_kid", "crt_burn")

/obj/machinery/computer/bbs_terminal/proc/motd_pool()
	return list("Node 2 is down AGAIN. Stop asking.",
		"New files in all areas. Ratio enforced as always.",
		"The Archive turns 42 this cycle. Drinks on the SysOp (not really).",
		"Reminder: keys rotate every maintenance window.",
		"If your transfer drops at 99%, that's the phone company's fault, not mine.",
		"Welcome new callers. Read the bulletins before posting.",
		"Someone keeps wardialing our voice line. Cut it out.")

/obj/machinery/computer/bbs_terminal/proc/thread_titles()
	return list("RE: RE: anyone got the new revision?", "FS: lab notes, cheap", "a friend told me something",
		"leech alert!!! ratio enforced", "Uploaded new stuff, check it", "Q: transfer keeps failing",
		"Grant committee rejected my paper again", "lost my notes, help", "Keys rotated tonight",
		"Who keeps tying up line 2?", "Off-topic: best synth-coffee", "[rand(1, 99)]% done, mirror up soon",
		"don't trust everything you read here", "found this in the header dump", "my parser output (long)",
		"RE: RE: RE: RE: key thread", "petition to upgrade the modem pool", "is the sysop ok?",
		"HOT TIP inside", "reposting before it gets deleted")

/obj/machinery/computer/bbs_terminal/proc/decoy_bodies()
	return list("Stop asking for keys in public threads. Ask the SysOp.",
		"Mirror is down until the next maintenance window. Sorry.",
		"Has anyone else noticed the modem pool is slow tonight?",
		"My download got to 99% and then NO CARRIER. Great.",
		"Leechers will be banned. Upload something first.",
		"This thread is a duplicate. Locked.",
		"I had the whole key written on a sticky note and the janitor threw it out.",
		"The coffee machine on deck 3 takes exact change only. You're welcome.",
		"Selling: one slightly haunted oscilloscope. No refunds.",
		"If you're reading this at work, get back to work.",
		"Whoever keeps posting in all caps: the SysOp is watching.",
		"I swear the key was different yesterday. Am I losing it?",
		"lol")

/obj/machinery/computer/bbs_terminal/proc/clue_openers()
	return list("Psst, a friend on the SysOp's staff told me", "Not supposed to post this, but",
		"For the people asking: after the rotation,", "Mod note:", "Decoded the header myself:",
		"Overheard on the voice line:", "Before this gets deleted:")

/obj/machinery/computer/bbs_terminal/proc/clue_closers()
	return list("Don't spread it around.", "You didn't hear it from me.", "Delete after reading.",
		"-- d1gital_monk", "Trust me.", "100% verified, I used it myself.", "The SysOp will kill this thread soon.")

#undef BBS_OFFLINE
#undef BBS_DIALING
#undef BBS_MENU
#undef BBS_BOARD
#undef BBS_THREAD
#undef BBS_COMPLETE
#undef BBS_NO_CARRIER
#undef BBS_HEX_DIGITS
#undef BBS_READ_COST
#undef BBS_GUESS_COST
#undef BBS_PAGE_COST
#undef BBS_DIAL_TIME
