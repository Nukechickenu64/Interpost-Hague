// Morality selection: sins and virtues side panel for character preferences

// Data registry: simple lists and descriptions
var/global/list/MORAL_SINS = list(
	"Pride" = "An unshakable confidence in oneself, often at odds with humility.",
	"Greed" = "A hunger for more than one needs, be it wealth or power.",
	"Wrath" = "A tendency toward anger and vengeance.",
	"Envy" = "A restless longing for what others possess.",
	"Lust" = "Desire that can distract from duty or reason.",
	"Gluttony" = "Excess and indulgence beyond necessity.",
	"Sloth" = "A reluctance to act when action is needed."
)

var/global/list/MORAL_VIRTUES = list(
	"Humility" = "Grounded self-regard; the antidote to pride.",
	"Charity" = "Willingness to give freely for others' good.",
	"Chastity" = "Ordered desire; fidelity to commitments.",
	"Patience" = "Measured temper and forbearance.",
	"Kindness" = "Goodwill toward others without envy.",
	"Temperance" = "Restraint and measured action.",
	"Diligence" = "Steady effort and responsibility."
)

// Opposites map: a sin's contrary virtue
var/global/list/MORAL_OPPOSITES = list(
	"Pride" = "Humility",
	"Greed" = "Charity",
	"Wrath" = "Patience",
	"Envy" = "Kindness",
	"Lust" = "Chastity",
	"Gluttony" = "Temperance",
	"Sloth" = "Diligence"
)

/datum/category_item/player_setup_item/morality
	name = "Morality"
	sort_order = 4

/datum/category_item/player_setup_item/morality/load_character(var/savefile/S)
	from_file(S["selected_sin"], pref.selected_sin)
	from_file(S["selected_virtue"], pref.selected_virtue)

/datum/category_item/player_setup_item/morality/save_character(var/savefile/S)
	to_file(S["selected_sin"], pref.selected_sin)
	to_file(S["selected_virtue"], pref.selected_virtue)

/datum/category_item/player_setup_item/morality/sanitize_character()
	if(!(pref.selected_sin in MORAL_SINS)) pref.selected_sin = null
	if(!(pref.selected_virtue in MORAL_VIRTUES)) pref.selected_virtue = null

	// Build key lists for random defaults
	var/list/sin_keys = list()
	for(var/k in MORAL_SINS)
		sin_keys += k
	var/list/virtue_keys = list()
	for(var/vk in MORAL_VIRTUES)
		virtue_keys += vk

	// Default random sin if none
	if(!pref.selected_sin && sin_keys.len)
		pref.selected_sin = pick(sin_keys)

	// Default random virtue (not opposite of chosen sin) if none
	if(!pref.selected_virtue && virtue_keys.len)
		var/list/choices = virtue_keys.Copy()
		var/oppv = MORAL_OPPOSITES[pref.selected_sin]
		if(oppv)
			choices -= oppv
		if(choices.len)
			pref.selected_virtue = pick(choices)
		else
			pref.selected_virtue = pick(virtue_keys)

	// If an illegal opposite pair slipped in, re-roll a valid virtue
	if(pref.selected_sin && pref.selected_virtue)
		var/opp = MORAL_OPPOSITES[pref.selected_sin]
		if(opp && pref.selected_virtue == opp)
			var/list/valids = virtue_keys.Copy()
			valids -= opp
			if(valids.len)
				pref.selected_virtue = pick(valids)

/datum/category_item/player_setup_item/morality/content(var/mob/user)
	. = list()
	. += "<div style='display:flex;gap:12px;'>"
	// Left: selector list
	. += "<div style='flex:0 0 220px;border-right:1px solid #333;padding-right:10px;'>"
	. += "<b>Sin</b><br>"
	for(var/name in MORAL_SINS)
		var/selected = (name == pref.selected_sin)
		if(selected)
			. += "<span class='linkOn'>[name]</span><br>"
		else
			. += "<a href='?src=\ref[src];choose_sin=[name]'>[name]</a><br>"
	. += "<br><b>Virtue</b><br>"
	for(var/v in MORAL_VIRTUES)
		var/selectedv = (v == pref.selected_virtue)
		if(selectedv)
			. += "<span class='linkOn'>[v]</span><br>"
		else
			. += "<a href='?src=\ref[src];choose_virtue=[v]'>[v]</a><br>"
	. += "</div>"
	// Right: description
	. += "<div style='flex:1;padding-left:10px;'>"
	. += "<b>Description</b><br>"
	var/list/desc_parts = list()
	if(pref.selected_sin && (pref.selected_sin in MORAL_SINS))
		desc_parts += "<b>Sin: [pref.selected_sin]</b><br><span class='notice'>[MORAL_SINS[pref.selected_sin]]</span><br>"
	if(pref.selected_virtue && (pref.selected_virtue in MORAL_VIRTUES))
		desc_parts += "<b>Virtue: [pref.selected_virtue]</b><br><span class='notice'>[MORAL_VIRTUES[pref.selected_virtue]]</span><br>"
	if(!length(desc_parts))
		desc_parts += "<span class='notice'>Select a sin and a virtue to see their descriptions here.</span>"
	. += jointext(desc_parts, "<br>")
	. += "</div>"
	. += "</div>"
	. = jointext(., null)

/datum/category_item/player_setup_item/morality/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(href_list["choose_sin"]) {
		var/choice_sin = href_list["choose_sin"]
		if(!(choice_sin in MORAL_SINS))
			return TOPIC_HANDLED
		// Block picking a sin whose opposite equals the current virtue
		var/oppv = MORAL_OPPOSITES[choice_sin]
		if(oppv && pref.selected_virtue == oppv)
			to_chat(user, "<span class='warning'>That sin directly contradicts your chosen virtue.</span>")
			return TOPIC_HANDLED
		pref.selected_sin = choice_sin
		return TOPIC_REFRESH
	}
	if(href_list["choose_virtue"]) {
		var/choice_virtue = href_list["choose_virtue"]
		if(!(choice_virtue in MORAL_VIRTUES))
			return TOPIC_HANDLED
		// Block picking the contrary virtue to the current sin
		var/oppv = MORAL_OPPOSITES[pref.selected_sin]
		if(oppv && choice_virtue == oppv)
			to_chat(user, "<span class='warning'>That virtue directly contradicts your chosen sin.</span>")
			return TOPIC_HANDLED
		pref.selected_virtue = choice_virtue
		return TOPIC_REFRESH
	}
	return ..()
