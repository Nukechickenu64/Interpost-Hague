GLOBAL_VAR_INIT(os13_salvage_authorized, TRUE)
GLOBAL_LIST_EMPTY(os13_bridge_reports)
GLOBAL_LIST_EMPTY(os13_approved_documents)

/proc/os13_salvage_allowed()
	return !istype(GLOB.using_map, /datum/map/alpha) || GLOB.os13_salvage_authorized

/obj/machinery/computer/bridge/proc/os13_general_report()
	if(istype(GLOB.using_map, /datum/map/os13classic))
		return {"<h2>Orbital Station 13 &mdash; General Report</h2>
			<p><b>MALFUNCTION DETECTED</b><br>
			AUTOMATIC METEOR PROTECTION SYSTEM: Unavailable<br>
			STEALTH SYSTEM: Unavailable</p>
			<p>ROCKET DEFENCE: Online<br>
			IFF: Online</p>
			<p>PLANNED NEW SHIFT DATE: 30 DEC 2437<br>
			(cancelled: reactivation confirmation not received)<br>
			<b>EMERGENCY REACTIVATION DATE: 23 AUG 3022</b><br>
			(caused by core systems malfunction)</p>
			<p>OUTER COMMUNICATIONS: Unavailable<br>
			<em>TNC Aurora</em> communication link: Unavailable</p>"}
	var/list/lines = list("<h2>Orbital Station 13: General Report</h2>")
	lines += "<h3>Recovered emergency record</h3><p><b>Emergency reactivation: 23 August 3022.</b> The record indicates approximately six centuries of hibernation. The onboard AI's self-destruction damaged station systems and triggered the emergency awakening. Contact with corporate command cannot be assumed.</p>"
	lines += "<p>The recovered account identifies locked research databases, failed clone backups, deteriorated solar equipment and an expired water chip. These are historical incident entries, not live fault measurements. Inspect each installation before declaring it repaired.</p>"
	lines += os13_awakening_account()
	lines += "<h3>Command briefing</h3><p>Assemble the crew, distribute departmental keycards, assign the Marshal to investigate the sabotage and agree research priorities with the Scientific Overseer. Research recovery, fabrication of a replacement water chip and station repairs require the appropriate crew and equipment.</p>"
	lines += "<h3>Current recovery procedure</h3><ol><li>Use WAKE STATION to restore bridge-controlled lighting and reset station air-alarm thermostats to 20&deg;C. Broken lights, missing power and damaged machinery still require repairs.</li><li>Install a working portable water control chip in its holder.</li><li>[GLOB.bridge_crew_objectives.power_grid_goal()].</li></ol>"
	var/wake_state = GLOB.station_wake_sequence.started ? (GLOB.station_wake_sequence.active ? "In progress" : (GLOB.station_wake_sequence.finished ? "Complete" : "Interrupted")) : "Not started"
	lines += "<h3>Live readings: [stationtime2text()]</h3><p>Wake sequence: [wake_state].<br>Water control chip: [GLOB.waterchip_installed ? "Installed" : "Not installed"].<br>Cryogenic startup alarm: [GLOB.cryo_startup_effect.active ? "Active" : "Inactive"].</p>"
	if(GLOB.station_wake_sequence.active)
		lines += "<p>Wake targets processed: [GLOB.station_wake_sequence.next_target - 1] / [length(GLOB.station_wake_sequence.targets)]. Lights started: [GLOB.station_wake_sequence.lights_started]. Thermostats reset: [GLOB.station_wake_sequence.thermostats_reset].</p>"
	lines += os13_startup_readiness()
	lines += GLOB.bridge_crew_objectives.get_status_report()
	if(SSdirector)
		lines += SSdirector.station_status_report()
	else
		lines += "<p><b>Station telemetry unavailable: AI Director is not initialized.</b></p>"
	return jointext(lines, "")

/obj/machinery/computer/bridge/proc/os13_classic_station_status()
	var/wake_state = GLOB.station_wake_sequence.started ? (GLOB.station_wake_sequence.active ? "In progress" : (GLOB.station_wake_sequence.finished ? "Complete" : "Interrupted")) : "Not started"
	var/report = "<p>Wake sequence: [wake_state].<br>Water control chip: [GLOB.waterchip_installed ? "Installed" : "Not installed"].<br>Cryogenic startup alarm: [GLOB.cryo_startup_effect.active ? "Active" : "Inactive"].</p>"
	report += os13_startup_readiness()
	report += GLOB.bridge_crew_objectives.get_status_report()
	report += "<p>Long-range distress receiver: [os13_outer_antenna() ? "online" : "offline"].</p>"
	var/sky_veteran = os13_sky_veteran_name()
	if(sky_veteran)
		report += "<p>Hall of Fame, Sky Veteran: [html_encode(sky_veteran)]</p>"
	if(SSdirector)
		report += SSdirector.station_status_report()
	return report

/obj/machinery/computer/bridge/proc/os13_startup_readiness()
	var/controllers_total = 0
	var/controllers_online = 0
	for(var/obj/machinery/power/area_smes/controller in SSmachines.machinery)
		if(!is_station_turf(get_turf(controller)))
			continue
		controllers_total++
		if(controller.is_supplying_power())
			controllers_online++
	var/research_consoles = 0
	var/research_online = 0
	var/list/installed_technologies = list()
	for(var/obj/machinery/computer/rdconsole/replicator in SSmachines.machinery)
		if(!is_station_turf(get_turf(replicator)))
			continue
		research_consoles++
		if(replicator.operable() && replicator.powered())
			research_online++
		if(replicator.files)
			for(var/datum/tech/os13/technology in replicator.files.known_tech)
				if(technology.level > 0)
					installed_technologies |= technology.type
	var/panels_total = 0
	var/panels_intact = 0
	var/panels_linked = 0
	for(var/obj/machinery/power/solar/panel in SSmachines.machinery)
		if(!is_station_turf(get_turf(panel)))
			continue
		panels_total++
		if(!(panel.stat & BROKEN))
			panels_intact++
			if(!QDELETED(panel.control) && panel.network_connected)
				panels_linked++
	var/bases_total = 0
	var/bases_faulty = 0
	var/bases_missing_panels = 0
	var/bases_output = 0
	for(var/obj/machinery/power/solar_base/base in GLOB.solar_bases)
		if(QDELETED(base) || !is_station_turf(get_turf(base)))
			continue
		bases_total++
		if(base.defective || (base.stat & BROKEN))
			bases_faulty++
		if(QDELETED(base.panel) || base.panel.loc != base || base.panel.broken)
			bases_missing_panels++
		bases_output += base.power_output()
	var/clone_consoles = 0
	var/clone_online = 0
	var/clone_records = 0
	for(var/obj/machinery/computer/cloning/cloner in SSmachines.machinery)
		if(!is_station_turf(get_turf(cloner)))
			continue
		clone_consoles++
		if(cloner.operable() && cloner.powered())
			clone_online++
		for(var/datum/dna2/record/record in cloner.records)
			if(!QDELETED(record))
				clone_records++
	var/list/lines = list("<h3>Startup readiness</h3><table border='1' cellpadding='5'><tr><th>System</th><th>Current local reading</th></tr>")
	if(istype(GLOB.using_map, /datum/map/os13classic))
		var/coverage = power_net.os13_generation_coverage()
		var/grid_reading = isnull(coverage) ? "Awaiting live grid sample" : "[round(power_net.generated / 1000, 0.01)] kW generated / [round(power_net.viewload / 1000, 0.01)] kW demand; [round(power_net.stored_energy / 1000, 0.01)] kWh reserve; [length(power_net.depowered_areas)] areas shed"
		lines += "<tr><td>Station power grid</td><td>[grid_reading]</td></tr>"
	else
		lines += "<tr><td>Area power supply</td><td>[controllers_total ? "[controllers_online] / [controllers_total] controllers supplying at least one channel" : "Unavailable: no station controllers detected"]</td></tr>"
	lines += "<tr><td>Replicator research</td><td>[research_consoles ? "[research_online] / [research_consoles] consoles operational; [length(installed_technologies)] distinct technologies stored" : "Unavailable: no station research consoles detected"]</td></tr>"
	lines += "<tr><td>Legacy solar arrays</td><td>[panels_total ? "[panels_intact] / [panels_total] panels intact; [panels_linked] intact panels linked to a controller and power network" : "No legacy station solar panels detected"]</td></tr>"
	lines += "<tr><td>OS13 solar mounts</td><td>[bases_total ? "[bases_total] mounts; [bases_faulty] defective bases; [bases_missing_panels] missing or shattered panels; [round(bases_output / 1000, 0.01)] kW configured output" : "Unavailable: no station OS13 solar mounts detected"]</td></tr>"
	lines += "<tr><td>Clone records</td><td>[clone_consoles ? "[clone_online] / [clone_consoles] consoles operational; [clone_records] stored record entries" : "Unavailable: no station cloning consoles detected"]</td></tr></table>"
	lines += "<p>These are current station-local inventories, including data stored in offline consoles. Legacy solar links do not guarantee sunlight or output. OS13 solar output uses each mount's current deployment, panel and connection checks; it is not accumulated energy. Stored clone entries may be incomplete, duplicated or unsuitable for cloning; verify them at Genetics. Technologies carried on unimported diskettes are not counted. Missing equipment is not reported as repaired.</p>"
	if(research_consoles && !length(installed_technologies))
		lines += "<p><b>Research recovery pending:</b> the station's Replicator consoles have no installed technologies. The Overseer and Cybertechnician must recover research data and import the diskettes at a Replicator console; merely carrying recovered media does not unlock fabrication.</p>"
	return jointext(lines, "")

/obj/machinery/computer/bridge/proc/os13_show_general_report(mob/user, obj/item/device/os13_remcom/remote = null)
	if(!os13_command_available(user, remote))
		return
	GLOB.bridge_crew_objectives.issue()
	var/datum/browser/popup = new(user, "os13_general_report", "General Report", 700, 600)
	popup.device_source = remote ? remote : src
	popup.set_content(os13_general_report())
	popup.open()

/obj/machinery/computer/bridge/proc/os13_command_authorized(mob/user)
	if(!user)
		return FALSE
	var/list/credentials = user.GetAccess()
	return check_mapper_access(credentials, (access_heads in credentials) || (access_captain in credentials))

/obj/machinery/computer/bridge/proc/os13_command_available(mob/user, obj/item/device/os13_remcom/remote = null)
	if(QDELETED(src) || QDELETED(user) || !istype(GLOB.using_map, /datum/map/alpha))
		return FALSE
	if(remote)
		return remote.can_connect(user, src)
	if(CanUseTopic(user, GLOB.default_state) != STATUS_INTERACTIVE || !user.Adjacent(src) || user.incapacitated() || !os13_command_authorized(user) || !operable() || !powered())
		to_chat(user, SPAN_WARNING("ACCESS DENIED: remain beside an operational bridge console with command authorization."))
		return FALSE
	return TRUE

/obj/machinery/computer/bridge/proc/os13_show_reports(mob/user, obj/item/device/os13_remcom/remote = null)
	if(!os13_command_available(user, remote))
		return
	var/list/lines = list("<h3>Today Reports</h3><p>Most recent 100 command and station-service broadcasts, oldest first.</p>")
	if(!length(GLOB.os13_bridge_reports))
		lines += "<p>No broadcasts have been recorded.</p>"
	else
		lines += GLOB.os13_bridge_reports
	var/datum/browser/popup = new(user, "os13_today_reports", "Today Reports", 650, 500)
	popup.device_source = remote ? remote : src
	popup.set_content(jointext(lines, "<hr>"))
	popup.open()

/obj/machinery/computer/bridge/proc/os13_show_documents(mob/user, obj/item/device/os13_remcom/remote = null)
	if(!os13_command_available(user, remote))
		return
	if(GAME_STATE != RUNLEVEL_GAME)
		to_chat(user, SPAN_WARNING("The document registry is available during the round."))
		return
	for(var/obj/structure/filingcabinet/cabinet in world)
		if(is_station_turf(get_turf(cabinet)))
			cabinet.os13_prepare_archive()
	var/list/lines = list("<h3>Approved Documents List</h3><p>Archive locations at registration, not a live tracking system.</p>")
	for(var/number in GLOB.os13_approved_documents)
		var/list/entry = GLOB.os13_approved_documents[number]
		lines += "<p>[html_encode(entry["name"])] &mdash; [html_encode(entry["location"])]</p>"
	if(!length(GLOB.os13_approved_documents))
		lines += "<p>No approved documents are registered.</p>"
	var/datum/browser/popup = new(user, "os13_approved_documents", "Approved Documents List", 650, 500)
	popup.device_source = remote ? remote : src
	popup.set_content(jointext(lines, ""))
	popup.open()

/obj/machinery/computer/bridge/proc/os13_erase_documents(mob/user, obj/item/device/os13_remcom/remote = null)
	if(!os13_command_available(user, remote))
		return
	if(GAME_STATE != RUNLEVEL_GAME)
		to_chat(user, SPAN_WARNING("The document registry is available during the round."))
		return
	if(alert(user, "Erase the station's approved-document registry? Physical files and their contents will remain intact.", "Approved Documents", "Cancel", "Erase") != "Erase")
		return
	if(!os13_command_available(user, remote) || GAME_STATE != RUNLEVEL_GAME)
		return
	// Materialize lazy cabinet archives before erasure so reopening the list cannot recreate them.
	for(var/obj/structure/filingcabinet/cabinet in world)
		if(is_station_turf(get_turf(cabinet)))
			cabinet.os13_prepare_archive()
	GLOB.os13_approved_documents.Cut()
	add_fingerprint(user)
	log_game("[key_name(user)] erased the approved-document registry at [get_area(src)].")
	to_chat(user, SPAN_NOTICE("Approved Documents List erased. Physical files have not been destroyed."))

/obj/machinery/computer/bridge/proc/os13_toggle_salvage(mob/user, obj/item/device/os13_remcom/remote = null)
	if(!os13_command_available(user, remote))
		return
	GLOB.os13_salvage_authorized = !GLOB.os13_salvage_authorized
	add_fingerprint(user)
	log_game("[key_name(user)] [GLOB.os13_salvage_authorized ? "authorized" : "prohibited"] Scout salvage coordinates at [get_area(src)].")
	to_chat(user, SPAN_NOTICE("Salvage coordinates [GLOB.os13_salvage_authorized ? "authorized" : "prohibited"]. Mining, satellite travel and return to station remain available."))

/obj/machinery/computer/bridge/proc/os13_control_shields(mob/user, action, obj/item/device/os13_remcom/remote = null)
	if(!os13_command_available(user, remote) || !check_mapper_access(user.GetAccess(), access_heads in user.GetAccess()))
		to_chat(user, SPAN_WARNING("ACCESS DENIED: a working bridge console and command keycard are required."))
		return
	var/list/generators = list()
	for(var/obj/machinery/power/shield_generator/G in SSmachines.machinery)
		if(is_station_turf(get_turf(G)))
			generators += G
	if(!generators.len)
		to_chat(user, SPAN_WARNING("No station shield generator is connected."))
		return
	var/obj/machinery/power/shield_generator/G = input(user, "Select a station shield generator.", "Shields") as null|anything in generators
	if(!G)
		return
	var/direction
	if(action == "os13_shield_direction")
		var/list/directions = list("360" = 0, "North" = NORTH, "South" = SOUTH, "East" = EAST, "West" = WEST)
		var/selection = input(user, "Select shield coverage. Full coverage consumes more power.", "Select Shields") as null|anything in directions
		if(!selection)
			return
		direction = directions[selection]
	if(QDELETED(G) || !is_station_turf(get_turf(G)) || !os13_command_available(user, remote) || !check_mapper_access(user.GetAccess(), access_heads in user.GetAccess()))
		to_chat(user, SPAN_WARNING("The shield control link is no longer available."))
		return
	if(G.stat & BROKEN || G.offline_for)
		to_chat(user, SPAN_WARNING("The shield generator is damaged or cooling down."))
		return
	if(action == "os13_shield_direction")
		if(G.mode_changes_locked)
			to_chat(user, SPAN_WARNING("The generator's control wire has locked its settings."))
			return
		G.OnTopic(user, list("direction" = "[direction]"))
		to_chat(user, SPAN_NOTICE("Shield coverage set to [direction ? dir2text(direction) : "360 degrees"]."))
	else if(G.running == SHIELD_RUNNING)
		G.OnTopic(user, list("begin_shutdown" = "1"))
		to_chat(user, SPAN_NOTICE("Shield discharge initiated. The field will fall as its stored energy dissipates."))
	else if(G.running == SHIELD_OFF)
		command_announcement.Announce("Shields are being enabled. All crawlspaces in maintenance areas will be electrified. Clear the maintenance tunnels.", "Bridge Operations")
		G.OnTopic(user, list("start_generator" = "1"))
		to_chat(user, SPAN_NOTICE("Shield startup initiated."))
	else
		to_chat(user, SPAN_WARNING("The generator is still discharging. Wait for shutdown to finish."))
	log_game("[key_name(user)] used [action] at the bridge for [G] at [get_area(G)].")
