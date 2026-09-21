// Fluid Loyalties & Dynamic Defection System
// Faction alignment is fluid and trackable in real-time.
// Players can be bribed, defect, or be converted through gameplay actions.

/datum/loyalty_tracker
	var/list/faction_members = list()  // faction_name -> list of datum/mind
	var/list/mind_factions = list()    // mind ref -> faction_name

/datum/loyalty_tracker/New()
	for(var/faction in list(LOYALTY_NANOTRASEN, LOYALTY_SYNDICATE, LOYALTY_REVOLUTIONARY, LOYALTY_CULT, LOYALTY_NEUTRAL))
		faction_members[faction] = list()

/// Get the faction a mind belongs to
/datum/loyalty_tracker/proc/get_faction(var/datum/mind/M)
	if(!M)
		return LOYALTY_NEUTRAL
	return mind_factions[M] || LOYALTY_NANOTRASEN

/// Set a mind's faction
/datum/loyalty_tracker/proc/set_faction(var/datum/mind/M, var/faction)
	if(!M || !faction)
		return
	// Compare against the raw entry, not get_faction()'s NT fallback, so first-time
	// registration to the default faction still actually gets recorded.
	var/old_faction = mind_factions[M]
	if(old_faction == faction)
		return
	// Remove from old faction
	if(old_faction && faction_members[old_faction])
		faction_members[old_faction] -= M
	// Add to new faction
	if(!faction_members[faction])
		faction_members[faction] = list()
	faction_members[faction] |= M
	mind_factions[M] = faction
	log_debug("[key_name(M)] loyalty shifted from [old_faction || "unassigned"] to [faction].")

/// Get all members of a faction
/datum/loyalty_tracker/proc/get_members(var/faction)
	return faction_members[faction] || list()

/// Get faction member count
/datum/loyalty_tracker/proc/get_count(var/faction)
	var/list/members = faction_members[faction]
	return members ? members.len : 0

/// Offer a bribe to a player to switch sides (Syndicate -> NT or vice versa)
/datum/loyalty_tracker/proc/offer_bribe(var/datum/mind/offerer, var/datum/mind/target, var/amount, var/target_faction)
	if(!offerer || !target || !target.current || !target.current.client)
		return FALSE
	if(get_faction(target) == target_faction)
		to_chat(offerer.current, "<span class='warning'>[target.current] is already loyal to [target_faction].</span>")
		return FALSE

	var/offer_text = "A Syndicate operative has offered you T[amount] to switch your loyalty to [target_faction]. Do you accept?"
	if(target_faction == LOYALTY_NANOTRASEN)
		offer_text = "Nanotrasen has offered you T[amount] to switch your loyalty. Do you accept?"

	var/choice = alert(target.current, offer_text, "Loyalty Offer", "Accept", "Refuse")
	if(choice == "Accept")
		set_faction(target, target_faction)
		to_chat(target.current, "<span class='notice'>You have accepted the bribe. Your loyalty now lies with [target_faction].</span>")
		to_chat(offerer.current, "<span class='notice'>[target.current] has accepted your offer and now serves [target_faction].</span>")
		log_admin("[key_name(target)] accepted a bribe of T[amount] from [key_name(offerer)] to join [target_faction].")
		message_admins("[key_name(target)] accepted a bribe of T[amount] from [key_name(offerer)] to join [target_faction].")
		return TRUE
	else
		to_chat(target.current, "<span class='warning'>You refuse the bribe. Your loyalty remains unchanged.</span>")
		to_chat(offerer.current, "<span class='warning'>[target.current] has refused your offer.</span>")
		return FALSE

/// Authorize a plea deal - captured antag gets NT loyalty implant in exchange for cooperation
/datum/loyalty_tracker/proc/authorize_plea_deal(var/datum/mind/captured, var/datum/mind/authorizer, var/temporary = TRUE)
	if(!captured || !captured.current || !authorizer)
		return FALSE

	var/choice = alert(captured.current, \
		"[authorizer.current] is offering you a plea deal. You will receive a temporary Nanotrasen loyalty implant and must hunt your former allies. Do you accept?", \
		"Plea Deal", "Accept", "Refuse")

	if(choice == "Accept")
		set_faction(captured, LOYALTY_NANOTRASEN)
		// Apply loyalty implant
		var/mob/living/carbon/human/H = captured.current
		if(istype(H))
			var/obj/item/weapon/implant/loyalty/L = new /obj/item/weapon/implant/loyalty(H)
			L.imp_in = H
			L.implanted = 1
			L.part = H.get_organ(BP_HEAD)
			if(L.part)
				L.part.implants += L
			L.Initialize()
		to_chat(captured.current, "<span class='notice'>You have accepted the plea deal. A loyalty implant has been installed. You must now cooperate with Nanotrasen.</span>")
		to_chat(authorizer.current, "<span class='notice'>[captured.current] has accepted the plea deal and been implanted.</span>")
		log_admin("[key_name(captured)] accepted a plea deal from [key_name(authorizer)].")
		message_admins("[key_name(captured)] accepted a plea deal from [key_name(authorizer)].")
		return TRUE
	else
		to_chat(captured.current, "<span class='warning'>You refuse the plea deal. You remain loyal to your cause.</span>")
		to_chat(authorizer.current, "<span class='warning'>[captured.current] has refused the plea deal.</span>")
		return FALSE

/// Get a summary of faction distribution for admin display
/datum/loyalty_tracker/proc/get_faction_summary()
	var/list/summary = list()
	for(var/faction in faction_members)
		summary[faction] = faction_members[faction].len
	return summary

/// Reset all loyalties (round end)
/datum/loyalty_tracker/proc/reset()
	for(var/faction in faction_members)
		faction_members[faction].Cut()
	mind_factions.Cut()