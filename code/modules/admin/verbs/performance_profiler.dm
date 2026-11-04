/client/proc/performance_profiler()
	set category = "Debug"
	set name = "Performance Profiler"
	set desc = "Start, stop, or restart server proc profiling and view the most expensive procs."

	if(!check_rights(R_DEBUG, C = src))
		return

	var/action = input(src, "Profiling measures server proc execution and adds overhead. Start / refresh resumes collection without clearing it. Stop freezes the results for inspection. Results are shared by all admins.", "Performance Profiler") as null|anything in list("Start / refresh", "Stop and view results", "Clear and restart")
	// Input sleeps: privileges may have changed while the menu was open.
	if(!action || !check_rights(R_DEBUG, C = src))
		return

	var/list/profile
	switch(action)
		if("Start / refresh")
			profile = world.Profile(PROFILE_START)
		if("Stop and view results")
			profile = world.Profile(PROFILE_STOP)
		if("Clear and restart")
			if(alert(src, "Clear the shared profiling results and start a new capture?", "Performance Profiler", "Clear and restart", "Cancel") != "Clear and restart")
				return
			if(!check_rights(R_DEBUG, C = src))
				return
			world.Profile(PROFILE_RESTART)
			profile = world.Profile(PROFILE_REFRESH)
		else
			return

	log_admin("[key_name(src)] used the performance profiler: [action].")
	message_admins("[key_name_admin(src)] used the performance profiler: [action].")

	var/body = "<p><b>[html_encode(action)]</b>. [action == "Stop and view results" ? "Collection is stopped." : "Collection is running; use Stop and view results when finished."]</p>"
	body += "<p>CPU: [round(world.cpu, 0.1)]% | Tick usage: [round(world.tick_usage, 0.1)]% | Tick interval: [world.tick_lag * 100] ms</p>"
	body += performance_profiler_report(profile)
	body += "<p>Run Debug &gt; Performance Profiler again to refresh, stop, or clear the capture.</p>"
	var/datum/browser/popup = new(mob, "performance_profiler", "Performance Profiler", 1100, 650)
	popup.set_content(body)
	popup.open()

// world.Profile returns six column headings followed by flat, six-value proc rows.
/proc/performance_profiler_report(list/profile)
	if(!islist(profile) || length(profile) < 6)
		return "<p>No profiling data is available yet. Let the server run before refreshing.</p>"

	var/list/rows = list()
	for(var/i = 7, i + 5 <= length(profile), i += 6)
		rows += list(list("name" = profile[i], "self" = profile[i + 1], "total" = profile[i + 2], "real" = profile[i + 3], "over" = profile[i + 4], "calls" = profile[i + 5]))
	if(!length(rows))
		return "<p>No proc calls have been recorded yet. Let the server run before refreshing.</p>"
	sortTim(rows, /proc/cmp_performance_profile_self)

	var/list/html = list("<p>Showing [min(100, length(rows))] of [length(rows)] procs, sorted by self CPU time. Times are cumulative milliseconds. Self excludes child procs; total includes them. Real includes sleeping; overtime identifies work that exceeded the tick budget.</p>")
	html += "<table border='1' cellpadding='4' cellspacing='0'><tr><th>Proc</th><th>Self (ms)</th><th>Total (ms)</th><th>Real (ms)</th><th>Overtime (ms)</th><th>Calls</th><th>Self / call (ms)</th></tr>"
	for(var/i = 1, i <= min(100, length(rows)), i++)
		var/list/row = rows[i]
		var/calls = row["calls"]
		html += "<tr><td>[html_encode(row["name"])]</td><td>[round(row["self"] * 1000, 0.001)]</td><td>[round(row["total"] * 1000, 0.001)]</td><td>[round(row["real"] * 1000, 0.001)]</td><td>[round(row["over"] * 1000, 0.001)]</td><td>[calls]</td><td>[calls ? round(row["self"] * 1000 / calls, 0.001) : 0]</td></tr>"
	html += "</table>"
	return jointext(html, "")

/proc/cmp_performance_profile_self(list/a, list/b)
	return b["self"] - a["self"]
