// Ambient occlusion is disabled. Retained only for legacy subsystem references.
SUBSYSTEM_DEF(ao)
	name = "Ambient Occlusion"
	init_order = SS_PRIORITY_AO
	flags = SS_NO_INIT | SS_NO_FIRE
	var/list/queue = list()
