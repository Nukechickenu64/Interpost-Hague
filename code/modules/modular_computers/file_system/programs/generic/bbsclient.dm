/datum/computer_file/program/bbsclient
	filename = "bbsclient"
	filedesc = "Telnet BBS"
	extended_desc = "Allows connection to external Telnet / BBS servers via embedded fTelnet." // Ensure policies permit outbound usage.
	program_icon_state = "netterm"
	program_key_state = "net_key"
	size = 6
	requires_ntnet = 0
	available_on_ntnet = 1
	nanomodule_path = /datum/nano_module/program/computer_bbsclient/

	var/bbs_host = ""
	var/bbs_port = 23
	var/is_connected = 0
	var/error
	var/last_connect_attempt = 0

/datum/computer_file/program/bbsclient/proc/build_ftelnet_embed()
	if(!bbs_host || !bbs_port)
		return "<b>No host configured.</b>"
	// Basic fTelnet embed; in production you might want to whitelist and sanitize host.
	var/html = "<iframe src='https://www.ftelnet.ca/Embed.html?HOST=[html_encode(bbs_host)]&PORT=[bbs_port]&PROTOCOL=telnet' width='640' height='480' style='border:1px solid #333;background:#000;color:#0f0;'>Your browser does not support iframes.</iframe>"
	return html

/datum/computer_file/program/bbsclient/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["PRG_sethost"])
		var/newhost = sanitize(input(usr, "Enter BBS hostname or IP:", "BBS Host", bbs_host) as text|null)
		if(newhost)
			bbs_host = newhost
			is_connected = 0
			return 1

	if(href_list["PRG_setport"])
		var/newport = input(usr, "Enter BBS port:", "BBS Port", bbs_port) as num|null
		if(isnum(newport) && newport > 0 && newport < 65536)
			bbs_port = newport
			is_connected = 0
			return 1

	if(href_list["PRG_connect"])
		. = 1
		if(!bbs_host)
			error = "No host set."
			return 1
		if(world.time - last_connect_attempt < 50)
			error = "Please wait before reconnecting."
			return 1
		last_connect_attempt = world.time
		is_connected = 1
		show_browser(usr, "<html><head><title>BBS: [bbs_host]:[bbs_port]</title></head><body>[build_ftelnet_embed()]</body></html>", "window=bbsclient_\ref[src]")
		return 1

	if(href_list["PRG_disconnect"])
		is_connected = 0
		return 1

	if(href_list["PRG_close"])
		return 1

/datum/nano_module/program/computer_bbsclient
	name = "BBS Client"

/datum/nano_module/program/computer_bbsclient/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = GLOB.default_state)
	var/list/data = host.initial_data()
	var/datum/computer_file/program/bbsclient/PRG = program
	if(PRG.error)
		data["error"] = PRG.error
	data["host"] = PRG.bbs_host
	data["port"] = PRG.bbs_port
	data["connected"] = PRG.is_connected
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "bbs_client.tmpl", "BBS Client", 400, 220, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()
