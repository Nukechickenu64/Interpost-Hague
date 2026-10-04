/client/proc/toggle_spoken_magic()
	set category = "Fun"
	set name = "Toggle Spoken Magic"
	set desc = "Lets your character's speech be parsed as spoken magic."

	if(!check_rights(R_FUN|R_DEBUG))
		return
	magic_casting = !magic_casting
	to_chat(src, "<span class='notice'>Spoken magic is now [magic_casting ? "enabled" : "disabled"] for you.</span>")
	log_and_message_admins("has [magic_casting ? "enabled" : "disabled"] spoken magic for themselves.")

/client/proc/magic_lexicon()
	set category = "Fun"
	set name = "Magic Lexicon"
	set desc = "Lists every spoken magic word and its fallbacks."

	if(!check_rights(R_FUN|R_DEBUG))
		return
	if(!magic_dictionary)
		build_magic_dictionary()

	var/list/lines = list("<b>Grammar:</b> \[modifier] target member \[operator] \[value...]<br>")
	lines += "Chain clauses with 'et' or 'atque'; a clause without its own target reuses the previous one.<br>"
	lines += "Aer, Creare and Explodere can act on bare floor; Locus takes a target word as its destination.<br><br>"
	lines += "<b>Latin words</b><br>"
	for(var/word in magic_dictionary)
		lines += "[word]: [magic_entry_text(magic_dictionary[word])]<br>"
	lines += "<br><b>Aliases</b> (a failed spell that starts with one of these is treated as normal speech)<br>"
	for(var/word in magic_aliases)
		lines += "[word]: [magic_entry_text(magic_aliases[word])]<br>"
	lines += "<br><b>Fallbacks</b><br>"
	lines += "Member: any variable on the target (same rights as View Variables), then any proc on the target (R_DEBUG).<br>"
	lines += "Operator: omitted means set.<br>"
	lines += "Value: numbers, true/false, null/none, #rrggbb or color names, otherwise the rest of the sentence as text.<br>"
	lines += "Create: any material name, or a type path written with dots instead of slashes (R_SPAWN), followed by an optional count.<br>"
	src << browse(jointext(lines, ""), "window=magic_lexicon;size=500x600")

/proc/magic_entry_text(list/entry)
	var/payload = entry[2]
	if(istype(payload, /decl/magic_word))
		var/decl/magic_word/D = payload
		payload = D.name
	return "[entry[1]] ([payload])"
