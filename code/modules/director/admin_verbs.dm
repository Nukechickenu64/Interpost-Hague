// Admin verbs for the AI Director Engine

/client/proc/director_status_panel()
	set name = "AI Director Status"
	set category = "Admin"
	if(!holder)
		return
	if(!SSdirector)
		to_chat(src, "<span class='warning'>AI Director subsystem not initialized.</span>")
		return
	var/html = SSdirector.status_report()
	var/datum/browser/popup = new(usr, "director_status", "AI Director Status", 600, 500)
	popup.set_content(html)
	popup.open()

/client/proc/director_set_tension()
	set name = "Set Director Tension"
	set category = "Admin"
	if(!holder)
		return
	if(!SSdirector)
		return
	var/amount = input("Enter tension value (0-100)", "Set Tension", SSdirector.tension) as num|null
	if(isnull(amount))
		return
	SSdirector.admin_set_tension(amount)

/client/proc/director_force_catalyst()
	set name = "Force Catalyst Event"
	set category = "Admin"
	if(!holder)
		return
	if(!SSdirector)
		return
	var/list/catalyst_options = list(
		"Tactical Strike" = CATALYST_TACTICAL_STRIKE,
		"Dimensional Anomaly" = CATALYST_ANOMALY,
		"Mutiny" = CATALYST_MUTINY,
		"Infiltration" = CATALYST_INFILTRATION
	)
	var/choice = input("Select a catalyst event to force.", "Force Catalyst") as null|anything in catalyst_options
	if(!choice)
		return
	SSdirector.admin_force_catalyst(catalyst_options[choice])

/client/proc/director_force_boiling_point()
	set name = "Force Boiling Point"
	set category = "Admin"
	if(!holder)
		return
	if(!SSdirector)
		return
	if(alert("Force the Boiling Point endgame? This will trigger a station-wide critical event.", "Force Boiling Point", "Yes", "No") != "Yes")
		return
	SSdirector.admin_force_boiling_point()

/client/proc/director_toggle()
	set name = "Toggle AI Director"
	set category = "Admin"
	if(!holder)
		return
	if(!SSdirector)
		return
	SSdirector.enabled = !SSdirector.enabled
	to_chat(src, "<span class='notice'>AI Director is now [SSdirector.enabled ? "enabled" : "disabled"].</span>")
	log_and_message_admins("toggled the AI Director [SSdirector.enabled ? "ON" : "OFF"].")