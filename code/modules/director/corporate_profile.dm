// Corporate Profiles – Agendas and Debts
// Instead of hard antagonist flags at round start, everyone gets a corporate profile
// that creates baseline friction without immediate bloodshed.

/datum/corporate_profile
	var/type_name = PROFILE_CLEAN
	var/datum/mind/owner
	var/description = "You have a standard corporate profile with no special obligations."

	// Agenda vars
	var/agenda_text = ""          // What the crewmember is being paid extra to do
	var/agenda_reward = 0         // Payout in thalers/credits on completion
	var/agenda_completed = FALSE
	var/agenda_target_type = null // Optional: type path of target item/area
	var/agenda_target_amount = 0  // Optional: amount to hoard/collect
	var/agenda_progress = 0       // Progress toward agenda_target_amount, credited externally

	// Debt vars
	var/debt_amount = 0           // How much is owed
	var/debt_creditor = ""        // Who is owed (syndicate name)
	var/debt_paid = 0             // How much has been paid so far
	var/debt_contraband_delivered = 0
	var/debt_threshold = 0        // When debt_paid >= debt_amount, debt is cleared
	var/debt_failed = FALSE       // If round ends without paying, consequences
	var/debt_leverage_granted = FALSE // Guards against granting Leverage more than once

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
		agenda_reward = rand(800, 1500)
		tension_contribution = 5

	else if(findtext(role, "Scientist") || findtext(role, "Research"))
		agenda_text = "Bypass safety protocols on the engine and push experimental research beyond standard parameters."
		agenda_reward = rand(1000, 2000)
		tension_contribution = 8

	else if(findtext(role, "Engineer") || findtext(role, "Atmos"))
		agenda_text = "Divert power from a non-critical department to your preferred section and maintain it for 10 minutes."
		agenda_reward = rand(600, 1200)
		tension_contribution = 6

	else if(findtext(role, "Medical") || findtext(role, "Doctor") || findtext(role, "Chemist"))
		agenda_text = "Stockpile a personal reserve of advanced medicines and withhold distribution until a price is met."
		agenda_reward = rand(700, 1300)
		tension_contribution = 5

	else if(findtext(role, "Security") || findtext(role, "Officer") || findtext(role, "Detective"))
		agenda_text = "Maintain a quota of arrests. You receive a bonus for each successful processing."
		agenda_target_amount = rand(3, 6)
		agenda_reward = rand(500, 1000) * agenda_target_amount
		tension_contribution = 10

	else if(findtext(role, "Bartender") || findtext(role, "Chef") || findtext(role, "Botanist"))
		agenda_text = "Create and sell premium goods at inflated prices. Hoard the best ingredients."
		agenda_reward = rand(400, 800)
		tension_contribution = 3

	else if(findtext(role, "Captain") || findtext(role, "Head"))
		agenda_text = "Maximize department efficiency metrics. Cut corners on safety to boost output."
		agenda_reward = rand(1500, 3000)
		tension_contribution = 7

	else
		// Generic agenda for any other role
		var/list/generic_agendas = list(
			"Collect and hoard a specific type of item for a private buyer.",
			"Spread a rumor about a coworker to damage their reputation.",
			"Sabotage a rival department's equipment subtly.",
			"Secure a promotion by any means necessary.",
			"Accumulate more wealth than any other crewmember."
		)
		agenda_text = pick(generic_agendas)
		agenda_reward = rand(500, 1000)
		tension_contribution = 4

	description = "Corporate Agenda: [agenda_text] Complete this for a bonus of T[agenda_reward]."

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
		"an unaffiliated loan shark",
		"the Waffle Corporation"
	)
	debt_creditor = pick(creditors)
	debt_amount = rand(3000, 8000)
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

	agenda_text = "You owe [debt_creditor] T[debt_amount]. To pay off your debt, you must [task]."
	description = "Corporate Debt: You owe [debt_creditor] T[debt_amount]. You must [task] to pay it off. Failure will have consequences."
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
		// Quota-style agenda: progress credited externally (e.g. arrest processing)
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

/// Credit progress toward a quota-style agenda (called by external systems, e.g. security processing)
/datum/corporate_profile/proc/credit_agenda_progress(var/amount = 1)
	if(type_name != PROFILE_AGENDA || agenda_completed)
		return
	agenda_progress += amount
	check_completion()

/// Mark the agenda complete and pay out the reward
/datum/corporate_profile/proc/complete_agenda()
	if(agenda_completed)
		return
	agenda_completed = TRUE
	tension_contribution = max(0, tension_contribution - 5)
	if(owner && owner.initial_account)
		var/datum/transaction/T = new("Corporate Agenda", "Agenda bonus", agenda_reward)
		owner.initial_account.do_transaction(T)
	if(owner && owner.current)
		to_chat(owner.current, "<span class='notice'><b>Agenda Completed:</b> Your corporate bonus of T[agenda_reward] has been deposited.</span>")
	grant_leverage(round(agenda_reward / 25))

/// Mark debt as partially paid
/datum/corporate_profile/proc/pay_debt(var/amount)
	if(type_name != PROFILE_DEBT)
		return
	debt_paid += amount
	if(debt_paid >= debt_threshold)
		to_chat(owner.current, "<span class='notice'><b>Debt Cleared:</b> You have paid off your debt to [debt_creditor]. You are free.</span>")
		tension_contribution = max(0, tension_contribution - 10)
		if(!debt_leverage_granted)
			debt_leverage_granted = TRUE
			grant_leverage(round(debt_amount / 25))

/// Mark contraband delivered for debt
/datum/corporate_profile/proc/deliver_contraband()
	if(type_name != PROFILE_DEBT)
		return
	debt_contraband_delivered++
	debt_paid += rand(500, 1500)
	pay_debt(0) // Check threshold

/// Called at round end to evaluate consequences
/datum/corporate_profile/proc/round_end_evaluation()
	if(!owner || !owner.current)
		return
	if(type_name == PROFILE_DEBT && debt_paid < debt_threshold)
		debt_failed = TRUE
		to_chat(owner.current, "<span class='danger'><b>Debt Unpaid:</b> You failed to repay [debt_creditor]. They will remember this...</span>")
	else if(type_name == PROFILE_AGENDA && agenda_completed)
		to_chat(owner.current, "<span class='notice'><b>Agenda Completed:</b> Your corporate bonus of T[agenda_reward] has been deposited.</span>")

/// Grant persistent Leverage currency to the owner's account, spendable in the Leverage shop.
/datum/corporate_profile/proc/grant_leverage(var/amount)
	if(amount <= 0 || !owner || !owner.current || !owner.current.client)
		return
	var/datum/preferences/prefs = owner.current.client.prefs
	if(!prefs)
		return
	prefs.meta_currency += amount
	prefs.save_preferences()
	to_chat(owner.current, "<span class='notice'><b>Leverage Earned:</b> +[amount] Leverage (total: [prefs.meta_currency]). Spend it in the Leverage shop on your next join.</span>")

/// Get a summary for round-end display
/datum/corporate_profile/proc/get_summary()
	if(type_name == PROFILE_CLEAN)
		return null
	if(type_name == PROFILE_AGENDA)
		return "Agenda: [agenda_text] - [agenda_completed ? "<font color='green'>Completed</font>" : "<font color='red'>Incomplete</font>"]"
	if(type_name == PROFILE_DEBT)
		return "Debt to [debt_creditor]: T[debt_paid]/T[debt_amount] - [debt_paid >= debt_threshold ? "<font color='green'>Paid</font>" : "<font color='red'>Unpaid</font>"]"
	return null