SUBSYSTEM_DEF(metrics)
	name = "Metrics"
	wait = 10 SECONDS
	priority = SS_PRIORITY_DEFAULT
	init_order = SS_INIT_MISC

	var/list/counters = list() // key -> integer
	var/log_interval = 60 SECONDS // aggregate and log every N seconds
	var/last_log = 0

/datum/controller/subsystem/metrics/proc/inc(var/key, var/amount = 1)
	if(!key)
		return
	if(!(key in counters))
		counters[key] = 0
	counters[key] += amount

/datum/controller/subsystem/metrics/proc/get(var/key)
	return counters[key]

/datum/controller/subsystem/metrics/fire(resumed)
	. = ..()
	if(!config || !config.log_debug)
		return
	if(world.time - last_log >= log_interval)
		last_log = world.time
		if(counters.len)
			var/list/out = list()
			for(var/k in counters)
				out += "[k]=[counters[k]]"
			log_debug("metrics: [english_list(out, ", ")]")
			// Reset counters after logging
			counters.Cut()

// Convenience proc
/proc/metrics_inc(var/key, var/amount = 1)
	SSmetrics?.inc(key, amount)
