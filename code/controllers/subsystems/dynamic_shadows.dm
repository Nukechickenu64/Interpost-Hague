SUBSYSTEM_DEF(dynamic_shadows)
	name = "Dynamic Shadows"
	wait = 5
	priority = SS_PRIORITY_DYNAMIC_SHADOWS
	flags = SS_NO_INIT | SS_BACKGROUND
	/// Extra tiles scanned past the edge of each client's view
	var/scan_margin = 1
	var/list/failed_types = list()
	/// Casters that moved and need a direction refresh even if no scan picks them up
	var/list/queue = list()
	var/list/currentrun = list()

/datum/controller/subsystem/dynamic_shadows/stat_entry()
	..("Q:[queue.len] R:[currentrun.len]")

/datum/controller/subsystem/dynamic_shadows/fire(resumed = FALSE)
	if(!resumed)
		if(!dynamic_shadows_enabled)
			queue.Cut()
			return
		var/list/run = queue
		queue = list()
		for(var/client/C as anything in GLOB.clients)
			var/turf/T = get_turf(C.eye)
			if(!T)
				continue
			var/list/view_size = getviewsize(C.view)
			var/scan_range = round(max(view_size[1], view_size[2]) / 2) + scan_margin
			for(var/atom/movable/AM in range(scan_range, T))
				if(AM.casts_dynamic_shadow)
					run[AM] = TRUE
		currentrun = run

	var/list/run = currentrun
	while(run.len)
		var/atom/movable/AM = run[run.len]
		run.len--
		if(!QDELETED(AM))
			try
				AM.update_dynamic_shadow()
			catch(var/exception/E)
				if(!failed_types[AM.type])
					failed_types[AM.type] = TRUE
					log_error("dynamic shadow update failed for [AM.type]: [E] ([E.file]:[E.line])")
		if(MC_TICK_CHECK)
			return
