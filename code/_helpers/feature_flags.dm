// Lightweight feature flag loader with config-driven toggles.

// Global registry of feature flags (string => boolean)
var/global/list/FEATURE_FLAGS = null

// Returns TRUE if a feature is enabled.
/proc/feature_enabled(var/feature_name)
	if(!FEATURE_FLAGS)
		load_feature_flags()
	return !!FEATURE_FLAGS?[lowertext("[feature_name]")]

// Load feature flags from config/features.txt (simple one-flag-per-line, '#' for comments).
/proc/load_feature_flags()
	FEATURE_FLAGS = list()
	var/path = "config/features.txt"
	var/text = file2text(path)
	if(!istext(text))
		return // no features file, defaults remain empty/disabled
	var/list/lines = splittext(text, "\n")
	for(var/line in lines)
		line = trim(line)
		if(!length(line))
			continue
		if(copytext(line, 1, 2) == "#")
			continue
		var/enabled = TRUE
		if(findtext(line, "NO_FEATURE_") == 1)
			enabled = FALSE
			line = copytext(line, 12) // strip NO_FEATURE_
		else if(findtext(line, "FEATURE_") == 1)
			line = copytext(line, 9) // strip FEATURE_
		FEATURE_FLAGS[lowertext(line)] = enabled

// Admin/debug convenience to reload flags at runtime
/proc/reload_feature_flags()
	FEATURE_FLAGS = null
	load_feature_flags()
	if(config && config.log_debug)
		log_debug("Feature flags reloaded: [FEATURE_FLAGS.len] flags")
