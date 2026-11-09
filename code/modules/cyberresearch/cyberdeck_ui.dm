/datum/asset/simple/cyberdeck_ui
	assets = list("cyberdeck.css" = 'html/cyberdeck.css')

// Keep the renderer independent of the live dive so previews use the same HTML.
/proc/cyberdeck_ui_html(list/data, base_href)
	var/phase = data["phase"]
	var/active = phase != CYBERDECK_IDLE
	var/collection_mode = data["collection_mode"]
	var/phase_label = phase == CYBERDECK_BOOTING ? "Building archive" : active ? "Dive active" : data["can_boot"] ? "Ready to dive" : "Standby"
	var/href = html_encode(base_href)
	var/html = "<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'><meta charset='utf-8'><title>Cyberdeck research</title><link rel='stylesheet' href='cyberdeck.css'></head><body><div class='cyberdeck'>"
	html += "<header class='cyber-header'><div><div class='cyber-eyebrow'>Neural research interface</div><h1>CYBERDECK</h1></div><span class='cyber-badge'>[phase_label]</span></header>"
	html += "<div class='cyber-status' role='status'>[html_encode(data["message"])]</div>"
	if(data["debug_tools"])
		html += "<p><a class='cyber-button' href='[href];action=debug_solo'>Enter safe debug cyberspace</a> <a class='cyber-button' href='[href];action=debug'>Debug tools</a></p>"
	if(data["safe_debug_dive"])
		html += "<section class='cyber-panel'><h2>Safe debug simulation</h2><p>The player's body is paused and protected. No chair, helmet, neural port or disk is required. Data collection cannot write research. Use Exit Debug Cyberspace, EJECT or Recall in Abilities to return immediately.</p></section></div></body></html>"
		return html
	html += "<div class='cyber-connections'><section class='cyber-panel'><h2>01 / Media drive</h2><div class='cyber-value'>[html_encode(data["disk_name"])]</div>"
	if(data["media"] != "missing")
		html += "<p class='cyber-muted'><b>Technologies:</b>"
		if(length(data["recordings"]))
			for(var/recording in data["recordings"])
				html += "<br>[html_encode(recording)]"
		else if(data["media"] == "recorded")
			html += "<br>[html_encode(data["stored_research"])] ([html_encode(data["stored_level_label"])] [data["stored_level"]])"
		html += "</p>"
	if(active)
		html += "<p class='cyber-muted'>Drive locked until recall or download.</p>"
		html += "<p class='cyber-muted'>Disk contents change only after a successful download. An unfinished dive leaves existing research intact.</p>"
	else if(data["media"] == "missing")
		if(data["allow_overwrite"])
			html += "<p class='cyber-muted'>Insert a technology disk. Recorded media requires confirmation before boot; only a successful download replaces its saved research.</p>"
		else
			html += "<p class='cyber-muted'>Insert a blank technology disk into the console.</p>"
	else
		var/media_status = data["media"] == "blank" ? "Blank / ready to write" : data["allow_overwrite"] ? "Research stored / confirmation required to overwrite" : "Research stored / import at R&amp;D"
		html += "<div class='cyber-panel-footer'><span class='cyber-muted'>[media_status]</span><a class='cyber-button' href='[href];action=eject;disk=[html_encode(data["disk_ref"])];dive_id=[data["dive_id"]]'>Eject disk</a></div>"
	html += "</section><section class='cyber-panel'><h2>02 / Neural link</h2>"
	if(active)
		html += "<div class='cyber-value'>[html_encode(data["operator"])]</div><p class='cyber-muted'>Chair and helmet connection reserved.</p>"
		if(collection_mode)
			html += "<p class='cyber-muted'>[data["advanced_port"] ? "Advanced port: interior Blue ICE traversal enabled." : "Standard port: deactivate interior Blue ICE before crossing."]</p>"
	else
		var/list/chairs = data["chairs"]
		if(!chairs.len)
			html += "<div class='cyber-value'>No eligible operator</div>"
		for(var/list/chair in chairs)
			html += "<a class='cyber-chair[chair["selected"] ? " selected" : ""]' href='[href];action=chair;chair=[html_encode(chair["ref"])]'><span>[html_encode(chair["name"])]</span><span class='cyber-link-label'>[chair["selected"] ? "Selected" : "Connect"]</span></a>"
		html += "<p class='cyber-muted'>[html_encode(data["link_hint"])]</p>"
	html += "</section></div>"
	if(data["allow_overwrite"])
		html += "<section class='cyber-panel'><h2>Software / Station research</h2><p><b>Scan:</b> [html_encode(data["scan_status"])]<br><b>ICE-Pick:</b> [html_encode(data["icepick_status"])]</p><p class='cyber-muted'>Saved disk contents are not installed software. Import research at a Replicator console, then refresh this display. Use software from the avatar's Abilities panel during a dive.</p></section>"
	if(active)
		var/required = data["required"]
		var/decrypted = data["decrypted"]
		var/progress = required ? clamp(round(100 * decrypted / required), 0, 100) : 0
		var/seconds = data["seconds"]
		var/remaining_seconds = seconds % 60
		var/time_left = "[round(seconds / 60)]:[remaining_seconds < 10 ? "0" : ""][remaining_seconds]"
		html += "<section class='cyber-panel cyber-session'><div class='cyber-section-heading'><h2>03 / Archive session</h2><a class='cyber-button' href='[href];action=refresh'>Refresh status</a></div><h3>[html_encode(data["research"])] <span class='cyber-muted'>/ [collection_mode ? "Tier" : "Level"] [data["level"]]</span></h3>"
		if(phase == CYBERDECK_BOOTING)
			html += "<p>Generating the archive and preparing your avatar. Keep the chair and helmet connected.</p><div class='cyber-loading' aria-label='Building archive'></div>"
		else
			var/objective_label = collection_mode ? "Data collected" : "Relays decrypted"
			var/objective_status = collection_mode ? "Collect every data point. The final collection writes the disk and returns you to your body." : required && decrypted >= required ? "All relays decrypted. Click the data core to download the archive." : "Decrypt the relays, then click the data core to download onto the disk."
			if(collection_mode && data["destroyed_data"] > 0)
				objective_status = "Download unavailable: [data["destroyed_data"]] required data point(s) destroyed. EJECT and start a fresh dive. Existing disk contents are unchanged."
			html += "<div class='cyber-metrics'><div><span class='cyber-eyebrow'>Archive dimensions</span><strong>[data["size"]] &times; [data["size"]]</strong></div><div><span class='cyber-eyebrow'>[collection_mode ? "DATA LEFT" : objective_label]</span><strong>[collection_mode ? "[max(0, required - decrypted)]" : "[decrypted] / [required]"]</strong></div><div><span class='cyber-eyebrow'>Time remaining</span><strong>[time_left]</strong></div></div>"
			html += "<div class='cyber-progress' role='progressbar' aria-label='[objective_label]' aria-valuenow='[decrypted]' aria-valuemin='0' aria-valuemax='[required]'><span style='width:[progress]%'></span></div>"
			html += "<p class='cyber-muted'>[objective_status]</p>"
			if(collection_mode)
				var/protection_seconds = data["protection_seconds"]
				html += "<p class='cyber-muted'>[protection_seconds > 0 ? "Active protection asleep: [protection_seconds] seconds remaining." : "Active protection is awake. Avoid Red ICE."] Refresh status to update this reading.</p>"
				html += "<p class='cyber-muted'>Left-click nearby Blue ICE to deactivate it. The outer boundary remains sealed. Use Scan and ICE-Pick in the avatar's Abilities panel; Scan requires installed software. ICE-Pick can destroy useful data or the exit.</p>"
		var/recall_label = data["allow_overwrite"] ? "EJECT" : "Emergency recall"
		html += "<div class='cyber-recall'><span class='cyber-muted'>Recall cancels an unfinished download.</span><a class='cyber-button danger' href='[href];action=abort;dive_id=[data["dive_id"]]'>[recall_label]</a></div></section>"
	else
		html += "<section class='cyber-panel cyber-archives'><div class='cyber-section-heading'><h2>03 / Research archives</h2><a class='cyber-button' href='[href];action=refresh'>Refresh links</a></div>"
		html += "<p class='cyber-muted'>[collection_mode ? "Select a technology to extract. Install its completed disk at the Replicator console to unlock its designs and reveal further technologies." : "Retrieve the next research level. Import the completed disk at R&amp;D to advance."]</p>"
		if(!data["can_boot"])
			html += "<p class='cyber-prerequisite'>Boot requires [data["allow_overwrite"] ? "a technology disk" : "a blank disk"] and an eligible chair connection.</p>"
		html += "<table class='cyber-archive-table'><thead><tr><th scope='col'>[collection_mode ? "Technology" : "Discipline"]</th><th scope='col'>[collection_mode ? "Status" : "Known"]</th><th scope='col'>Archive</th><th scope='col'>Dive</th></tr></thead><tbody>"
		for(var/list/archive in data["archives"])
			var/known_label = collection_mode ? (archive["known"] > 0 ? "Installed" : "Not installed") : "LV [archive["known"]]"
			html += "<tr><td>[html_encode(archive["name"])]</td><td>[known_label]</td><td>[archive["complete"] ? "Complete" : "[archive["size"]] &times; [archive["size"]]"]</td><td>"
			if(archive["complete"])
				html += "<span class='cyber-muted'>Fully researched</span>"
			else if(data["can_boot"])
				html += "<a class='cyber-button' href='[href];action=boot;tech=[url_encode(archive["id"])];level=[archive["level"]];disk=[html_encode(data["disk_ref"])];recording=[html_encode(data["recording_ref"])];dive_id=[data["dive_id"]]'>[collection_mode ? "Extract tier" : "Boot level"] [archive["level"]]</a>"
			else
				html += "<span class='cyber-button cyber-disabled' aria-disabled='true'>[collection_mode ? "Extract tier" : "Boot level"] [archive["level"]]</span>"
			html += "</td></tr>"
		html += "</tbody></table></section>"
	html += "<footer class='cyber-footer'>[collection_mode ? "Collect research data &nbsp;/&nbsp; Complete the download" : "Decrypt relay keys &nbsp;/&nbsp; Download the data core"] &nbsp;/&nbsp; Import at R&amp;D</footer></div></body></html>"
	return html
