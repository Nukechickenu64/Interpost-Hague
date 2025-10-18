PROCESSING_SUBSYSTEM_DEF(miscproc)
	name = "Miscproc"
	priority = SS_PRIORITY_MISC
	flags = SS_KEEP_TIMING|SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY|RUNLEVEL_GAME|RUNLEVEL_POSTGAME
	wait = 10

	process_proc = /datum/proc/Process

/datum/controller/subsystem/processing/miscproc/fire(resumed)
	. = ..()
	for(var/datum/M in processing)
		M.Process()
		message_admins("Miscproc processed [M]")