// Corporate Profiles – Agendas and Debts
// Instead of hard antagonist flags at round start, everyone gets a corporate profile
// that creates baseline friction without immediate bloodshed.

/datum/corporate_profile
	var/type_name = PROFILE_CLEAN
	var/datum/mind/owner
	var/description = "You have a standard corporate profile with no special obligations."

	// Agenda vars
	var/agenda_text = ""
	var/agenda_completed = FALSE
	var/agenda_target_type = null // Optional: type path of target item/area
	var/agenda_target_amount = 0  // Optional: amount to hoard/collect
	var/agenda_progress = 0       // Progress toward agenda_target_amount, credited externally
	var/list/credited_arrest_records = list()

	// Debt vars
	var/debt_amount = 0           // How much is owed
	var/debt_creditor = ""        // Who is owed (syndicate name)
	var/debt_paid = 0             // How much has been paid so far
	var/debt_contraband_delivered = 0
	var/debt_threshold = 0        // When debt_paid >= debt_threshold, debt is cleared
	var/debt_failed = FALSE       // If round ends without paying, consequences

	// Tension contribution
	var/tension_contribution = 0  // How much this profile adds to the tension meter

/datum/corporate_profile/New(var/datum/mind/M)
	owner = M

/// Generate an agenda appropriate for the crewmember's job
/datum/corporate_profile/proc/generate_agenda()
	if(!owner || !owner.assigned_role)
		return

	type_name = PROFILE_AGENDA
	var/role = owner.assigned_role

	// Job-specific agendas
	if(findtext(role, "Quartermaster") || findtext(role, "Cargo"))
		agenda_target_type = pick(/obj/item/stack/material/gold, /obj/item/stack/material/silver, /obj/item/stack/material/platinum, /obj/item/stack/material/uranium, /obj/item/stack/material/diamond)
		var/obj/item/stack/dummy = agenda_target_type
		agenda_text = "Hoard and stockpile at least [rand(15,30)] units of [initial(dummy.name)] in the cargo bay."
		agenda_target_amount = rand(15, 30)
		tension_contribution = 5

	else if(findtext(role, "Scientist") || findtext(role, "Research"))
		agenda_text = "Bypass safety protocols on the engine and push experimental research beyond standard parameters."
		tension_contribution = 8

	else if(findtext(role, "Engineer") || findtext(role, "Atmos"))
		agenda_text = "Divert power from a non-critical department to your preferred section and maintain it for 10 minutes."
		tension_contribution = 6

	else if(findtext(role, "Medical") || findtext(role, "Doctor") || findtext(role, "Chemist"))
		agenda_text = "Stockpile a personal reserve of advanced medicines and withhold distribution from rival departments."
		tension_contribution = 5

	else if(findtext(role, "Security") || findtext(role, "Officer") || findtext(role, "Detective"))
		agenda_text = "Maintain a quota of arrests and successfully process each detainee."
		agenda_target_amount = rand(3, 6)
		tension_contribution = 10

	else if(findtext(role, "Bartender") || findtext(role, "Chef") || findtext(role, "Botanist"))
		agenda_text = "Create premium goods for your preferred department. Hoard the best ingredients."
		tension_contribution = 3

	else if(findtext(role, "Captain") || findtext(role, "Head"))
		agenda_text = "Maximize department efficiency metrics. Cut corners on safety to boost output."
		tension_contribution = 7

	else
		// Generic agenda for any other role
		var/list/generic_agendas = list(
			"Collect and hoard a specific type of item for a private contact.",
			"Spread a rumor about a coworker to damage their reputation.",
			"Sabotage a rival department's equipment subtly.",
			"Secure a promotion by any means necessary.",
			"Stockpile more useful equipment than any other crewmember."
		)
		agenda_text = pick(generic_agendas)
		tension_contribution = 4

	description = "Corporate Agenda: [agenda_text]"

/// Generate a debt for the crewmember
/datum/corporate_profile/proc/generate_debt()
	if(!owner)
		return

	type_name = PROFILE_DEBT
	var/list/creditors = list(
		"the Gorlex Marauders",
		"the Cybersun Syndicate",
		"the Donk Corporation",
		"a shadowy syndicate broker",
		"an unaffiliated smuggling contact",
		"the Waffle Corporation"
	)
	debt_creditor = pick(creditors)
	debt_amount = rand(3, 5)
	debt_threshold = debt_amount

	var/list/debt_tasks = list(
		"smuggle small contraband items past security checkpoints",
		"steal minor research data from the R&D servers",
		"plant a listening device in a department head's office",
		"divert a small shipment of materials to a dead drop",
		"copy the station's blueprints and deliver them to a contact",
		"acquire a head of staff's ID card briefly for duplication"
	)
	var/task = pick(debt_tasks)

	agenda_text = "You are obligated to [debt_creditor]. You must [task]."
	description = "Corporate Obligation: Complete [debt_amount] deliveries for [debt_creditor]. You must [task]. Failure will have consequences."
	tension_contribution = 12

/// Show the profile to the player
/datum/corporate_profile/proc/show_to_player()
	if(!owner || !owner.current)
		return
	var/mob/M = owner.current
	to_chat(M, "<span class='notice'><b>Corporate Profile:</b></span>")
	to_chat(M, "<span class='notice'>[description]</span>")
	if(type_name == PROFILE_DEBT)
		to_chat(M, "<span class='warning'>This is not a full antagonist role. You are not authorized to use lethal force. Be subtle.</span>")
	else if(type_name == PROFILE_AGENDA)
		to_chat(M, "<span class='notice'>This is a minor corporate objective. It creates friction but should not result in violence.</span>")

/// Check if agenda is completed (called periodically)
/datum/corporate_profile/proc/check_completion()
	if(agenda_completed)
		return TRUE
	if(type_name != PROFILE_AGENDA || agenda_target_amount <= 0)
		return FALSE

	if(agenda_target_type)
		// Hoarding-style agenda: count matching stacks in the cargo bay
		if(count_hoarded_stock() >= agenda_target_amount)
			complete_agenda()
			return TRUE
	else if(agenda_progress >= agenda_target_amount)
		// Quota-style progress is credited by gameplay systems.
		complete_agenda()
		return TRUE
	return FALSE

/// Tally units of agenda_target_type sitting in the cargo bay area
/datum/corporate_profile/proc/count_hoarded_stock()
	var/total = 0
	for(var/area/A in world)
		if(!isStationLevel(A.z) || !findtext(A.name, "Cargo"))
			continue
		for(var/obj/item/stack/S in A.contents)
			if(istype(S, agenda_target_type))
				total += S.get_amount()
	return total

/// Credit progress toward a quota-style agenda
/datum/corporate_profile/proc/credit_agenda_progress(var/amount = 1)
	if(type_name != PROFILE_AGENDA || agenda_completed)
		return
	agenda_progress += amount
	check_completion()

/datum/corporate_profile/proc/credit_arrest(var/record_uid)
	if(!record_uid || record_uid in credited_arrest_records)
		return FALSE
	credited_arrest_records |= record_uid
	credit_agenda_progress()
	return TRUE

/datum/corporate_profile/proc/complete_agenda()
	if(agenda_completed)
		return
	agenda_completed = TRUE
	tension_contribution = max(0, tension_contribution - 5)
	if(owner && owner.current)
		to_chat(owner.current, "<span class='notice'><b>Agenda Completed:</b> You have fulfilled your corporate assignment.</span>")

/// Mark debt as partially paid
/datum/corporate_profile/proc/pay_debt(var/amount)
	if(type_name != PROFILE_DEBT)
		return
	debt_paid += amount
	if(debt_paid >= debt_threshold)
		to_chat(owner.current, "<span class='notice'><b>Obligation Fulfilled:</b> You have completed your assignment for [debt_creditor].</span>")
		tension_contribution = max(0, tension_contribution - 10)

/// Mark contraband delivered for debt
/datum/corporate_profile/proc/deliver_contraband()
	if(type_name != PROFILE_DEBT)
		return
	debt_contraband_delivered++
	debt_paid++
	pay_debt(0) // Check threshold

/// Called at round end to evaluate consequences
/datum/corporate_profile/proc/round_end_evaluation()
	if(!owner || !owner.current)
		return
	if(type_name == PROFILE_DEBT && debt_paid < debt_threshold)
		debt_failed = TRUE
		to_chat(owner.current, "<span class='danger'><b>Obligation Unfulfilled:</b> You failed to complete your assignment for [debt_creditor].</span>")
	else if(type_name == PROFILE_AGENDA && agenda_completed)
		to_chat(owner.current, "<span class='notice'><b>Agenda Completed:</b> You have fulfilled your corporate assignment.</span>")

/datum/corporate_profile/proc/get_summary()
	if(type_name == PROFILE_CLEAN)
		return null
	if(type_name == PROFILE_AGENDA)
		return "Agenda: [agenda_text] - [agenda_completed ? "<font color='green'>Completed</font>" : "<font color='red'>Incomplete</font>"]"
	if(type_name == PROFILE_DEBT)
		return "Obligation to [debt_creditor]: [debt_paid]/[debt_amount] deliveries - [debt_paid >= debt_threshold ? "<font color='green'>Completed</font>" : "<font color='red'>Incomplete</font>"]"
	return null
