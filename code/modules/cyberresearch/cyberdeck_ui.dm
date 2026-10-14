/datum/asset/simple/cyberdeck_ui
	assets = list("cyberdeck.css" = 'html/cyberdeck.css')

// Keep the renderer independent of the live dive so previews use the same HTML.
/proc/cyberdeck_ui_html(list/data, base_href)
	var/phase = data["phase"]
	var/active = phase != CYBERDECK_IDLE
	var/phase_label = phase == CYBERDECK_BOOTING ? "Building archive" : active ? "Dive active" : data["can_boot"] ? "Ready to dive" : "Standby"
	var/href = html_encode(base_href)
	var/html = "<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'><meta charset='utf-8'><title>Cyberdeck research</title><link rel='stylesheet' href='cyberdeck.css'></head><body><div class='cyberdeck'>"
	html += "<header class='cyber-header'><div><div class='cyber-eyebrow'>Neural research interface</div><h1>CYBERDECK</h1></div><span class='cyber-badge'>[phase_label]</span></header>"
	html += "<div class='cyber-status' role='status'>[html_encode(data["message"])]</div>"
	html += "<div class='cyber-connections'><section class='cyber-panel'><h2>01 / Media drive</h2><div class='cyber-value'>[html_encode(data["disk_name"])]</div>"
	if(active)
		html += "<p class='cyber-muted'>Drive locked until recall or download.</p>"
	else if(data["media"] == "missing")
		html += "<p class='cyber-muted'>Insert a blank technology disk into the console.</p>"
	else
		html += "<div class='cyber-panel-footer'><span class='cyber-muted'>[data["media"] == "blank" ? "Blank / ready to write" : "Research stored / import at R&amp;D"]</span><a class='cyber-button' href='[href];action=eject'>Eject disk</a></div>"
	html += "</section><section class='cyber-panel'><h2>02 / Neural link</h2>"
	if(active)
		html += "<div class='cyber-value'>[html_encode(data["operator"])]</div><p class='cyber-muted'>Chair and helmet connection reserved.</p>"
	else
		var/list/chairs = data["chairs"]
		if(!chairs.len)
			html += "<div class='cyber-value'>No eligible operator</div>"
		for(var/list/chair in chairs)
			html += "<a class='cyber-chair[chair["selected"] ? " selected" : ""]' href='[href];action=chair;chair=[html_encode(chair["ref"])]'><span>[html_encode(chair["name"])]</span><span class='cyber-link-label'>[chair["selected"] ? "Selected" : "Connect"]</span></a>"
		html += "<p class='cyber-muted'>[html_encode(data["link_hint"])]</p>"
	html += "</section></div>"
	if(active)
		var/required = data["required"]
		var/decrypted = data["decrypted"]
		var/progress = required ? clamp(round(100 * decrypted / required), 0, 100) : 0
		var/seconds = data["seconds"]
		var/remaining_seconds = seconds % 60
		var/time_left = "[round(seconds / 60)]:[remaining_seconds < 10 ? "0" : ""][remaining_seconds]"
		html += "<section class='cyber-panel cyber-session'><div class='cyber-section-heading'><h2>03 / Archive session</h2><a class='cyber-button' href='[href];action=refresh'>Refresh status</a></div><h3>[html_encode(data["research"])] <span class='cyber-muted'>/ Level [data["level"]]</span></h3>"
		if(phase == CYBERDECK_BOOTING)
			html += "<p>Generating the archive and preparing your avatar. Keep the chair and helmet connected.</p><div class='cyber-loading' aria-label='Building archive'></div>"
		else
			html += "<div class='cyber-metrics'><div><span class='cyber-eyebrow'>Archive dimensions</span><strong>[data["size"]] &times; [data["size"]]</strong></div><div><span class='cyber-eyebrow'>Relays decrypted</span><strong>[decrypted] / [required]</strong></div><div><span class='cyber-eyebrow'>Time remaining</span><strong>[time_left]</strong></div></div>"
			html += "<div class='cyber-progress' role='progressbar' aria-label='Relays decrypted' aria-valuenow='[decrypted]' aria-valuemin='0' aria-valuemax='[required]'><span style='width:[progress]%'></span></div>"
			html += "<p class='cyber-muted'>[required && decrypted >= required ? "All relays decrypted. Click the data core to download the archive." : "Decrypt the relays, then click the data core to download onto the disk."]</p>"
		html += "<div class='cyber-recall'><span class='cyber-muted'>Recall cancels an unfinished download.</span><a class='cyber-button danger' href='[href];action=abort'>Emergency recall</a></div></section>"
	else
		html += "<section class='cyber-panel cyber-archives'><div class='cyber-section-heading'><h2>03 / Research archives</h2><a class='cyber-button' href='[href];action=refresh'>Refresh links</a></div>"
		html += "<p class='cyber-muted'>Retrieve the next research level. Import the completed disk at R&amp;D to advance.</p>"
		if(!data["can_boot"])
			html += "<p class='cyber-prerequisite'>Boot requires a blank disk and an eligible chair connection.</p>"
		html += "<table class='cyber-archive-table'><thead><tr><th scope='col'>Discipline</th><th scope='col'>Known</th><th scope='col'>Archive</th><th scope='col'>Dive</th></tr></thead><tbody>"
		for(var/list/archive in data["archives"])
			html += "<tr><td>[html_encode(archive["name"])]</td><td>LV [archive["known"]]</td><td>[archive["complete"] ? "Complete" : "[archive["size"]] &times; [archive["size"]]"]</td><td>"
			if(archive["complete"])
				html += "<span class='cyber-muted'>Fully researched</span>"
			else if(data["can_boot"])
				html += "<a class='cyber-button' href='[href];action=boot;tech=[url_encode(archive["id"])]'>Boot level [archive["level"]]</a>"
			else
				html += "<span class='cyber-button cyber-disabled' aria-disabled='true'>Boot level [archive["level"]]</span>"
			html += "</td></tr>"
		html += "</tbody></table></section>"
	html += "<footer class='cyber-footer'>Decrypt relay keys &nbsp;/&nbsp; Download the data core &nbsp;/&nbsp; Import at R&amp;D</footer></div></body></html>"
	return html
