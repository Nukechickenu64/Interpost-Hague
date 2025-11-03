// Simple global signal bus for pub/sub style events

// Usage:
//   signal_subscribe("event:name", some_datum, "OnEventProc")
//   signal_emit("event:name", arg1, arg2, ...)

var/global/datum/signal_bus/SIGNAL_BUS = new

/datum/signal_bus
	var/list/subscribers = list() // event -> list of list(d=datum, p=proc_name)

	proc/subscribe(var/event, var/datum/d, var/proc_name)
		if(!event || !d || !istext(proc_name))
			return FALSE
		if(!(event in subscribers))
			subscribers[event] = list()
		subscribers[event] += list(list(d = d, p = proc_name))
		return TRUE

	proc/unsubscribe(var/event, var/datum/d, var/proc_name)
		if(!(event in subscribers))
			return FALSE
		var/list/L = subscribers[event]
		for(var/i = L.len, i >= 1, i--)
			var/entry = L[i]
			if(entry && entry["d"] == d && entry["p"] == proc_name)
				L.Cut(i, i+1)
				return TRUE
		return FALSE

	proc/emit(var/event, list/args = list())
		if(!(event in subscribers))
			return 0
		var/count = 0
		var/list/L = subscribers[event].Copy() // prevent modification during iteration
		for(var/entry in L)
			var/datum/d = entry["d"]
			var/proc_name = entry["p"]
			if(!d || !istext(proc_name))
				continue
			try
				call(d, proc_name)(arglist(args))
				count++
			catch(var/exception/e)
				if(config && config.log_debug)
					log_debug("signal_emit error: [event] -> [log_info_line(d)]: [e]")
		return count

// Convenience wrappers
/proc/signal_subscribe(var/event, var/datum/d, var/proc_name)
	return SIGNAL_BUS?.subscribe(event, d, proc_name)

/proc/signal_unsubscribe(var/event, var/datum/d, var/proc_name)
	return SIGNAL_BUS?.unsubscribe(event, d, proc_name)

/proc/signal_emit(var/event, ...)
	var/list/L = args.Copy()
	L.Cut(1, 2) // remove event name from args list
	return SIGNAL_BUS?.emit(event, L)
