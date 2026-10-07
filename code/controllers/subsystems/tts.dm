SUBSYSTEM_DEF(tts)
	name = "Text To Speech"
	wait = 1
	flags = SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY|RUNLEVEL_SETUP|RUNLEVEL_GAME|RUNLEVEL_POSTGAME
	var/list/available_voices = list()
	var/pitch_available = FALSE
	var/speech_profiles_available = FALSE
	var/datum/tts_http_job/voice_request
	var/datum/tts_http_job/pitch_request
	var/datum/tts_http_job/profile_request
	var/next_connection_attempt = 0
	var/list/pending = list()
	var/list/active = list()
	var/list/speaker_queues = list()
	var/list/speaker_busy_until = list()
	var/list/duplicates = list()
	var/duplicate_tick = -1
	var/sequence = 0
	var/queued_count = 0
	var/stopping = FALSE
	var/was_enabled = FALSE

/datum/controller/subsystem/tts/stat_entry()
	..("Voices:[available_voices.len]|Pending:[pending.len]|Active:[active.len]")

/datum/controller/subsystem/tts/proc/request_headers()
	var/token = world.GetConfig("env", "TTS_HTTP_TOKEN")
	if(!token)
		token = config.tts_http_token
	return list("Content-Type" = "application/json", "Authorization" = token ? token : "")

/datum/controller/subsystem/tts/proc/backend_url()
	var/url = world.GetConfig("env", "TTS_HTTP_URL")
	if(!url)
		url = config.tts_http_url
	if(!url)
		return null
	while(copytext(url, -1) == "/")
		url = copytext(url, 1, -1)
	return url

/datum/controller/subsystem/tts/proc/connect()
	next_connection_attempt = world.time + 600
	voice_request = new
	voice_request.begin("[backend_url()]/tts-voices", "", request_headers())

/datum/controller/subsystem/tts/proc/poll_connection()
	if(voice_request && voice_request.poll())
		if(voice_request.success)
			var/list/voices
			try
				voices = json_decode(voice_request.response["body"])
			catch(var/exception/error)
				log_misc("TTS voice discovery returned invalid JSON: [error.name]")
			if(islist(voices))
				available_voices = list()
				for(var/voice in voices)
					if(istext(voice) && !(voice in config.tts_voice_blacklist))
						available_voices += voice
				var/datum/client_preference/voice_preference = get_client_preference(/datum/client_preference/tts_voice)
				voice_preference.options = list("Automatic") + available_voices
				if(available_voices.len)
					pitch_request = new
					pitch_request.begin("[backend_url()]/pitch-available", "", request_headers())
					profile_request = new
					profile_request.begin("[backend_url()]/speech-profile-available", "", request_headers())
		else
			log_misc("TTS backend unavailable; text chat is unaffected.")
		voice_request = null
	if(pitch_request && pitch_request.poll())
		pitch_available = pitch_request.success
		pitch_request = null
	if(profile_request && profile_request.poll())
		speech_profiles_available = profile_request.success
		profile_request = null

/datum/controller/subsystem/tts/fire(resumed = FALSE)
	if(stopping || !config)
		return
	if(!GLOB.tts_enabled && was_enabled)
		clear_queue()
	was_enabled = GLOB.tts_enabled
	poll_connection()
	if(GLOB.tts_enabled && backend_url() && !available_voices.len && !voice_request && world.time >= next_connection_attempt)
		connect()
	for(var/datum/tts_packet/packet in active.Copy())
		if(!packet.poll())
			continue
		active -= packet
		if(packet.discarded)
			packet.cleanup()
	if(GLOB.tts_enabled)
		while(pending.len && active.len < config.tts_max_concurrent_requests)
			var/datum/tts_packet/packet = pending[1]
			pending.Cut(1, 2)
			if(world.time > packet.created_at + 70 || QDELETED(packet.speaker))
				packet.failed = TRUE
				continue
			packet.begin(backend_url(), request_headers())
			active += packet
	for(var/mob/speaker in speaker_queues.Copy())
		var/list/queue = speaker_queues[speaker]
		if(QDELETED(speaker))
			queued_count -= queue.len
			for(var/datum/tts_packet/packet in queue)
				packet.discarded = TRUE
				pending -= packet
				if(!(packet in active))
					packet.cleanup()
			speaker_queues -= speaker
			speaker_busy_until -= speaker
			continue
		var/datum/tts_packet/packet = queue[1]
		if(packet.failed || (!packet.ready && world.time > packet.created_at + 70))
			packet.discarded = TRUE
			pending -= packet
			queue.Cut(1, 2)
			queued_count--
			if(!(packet in active))
				packet.cleanup()
		else if(packet.ready && world.time >= speaker_busy_until[speaker])
			packet.play()
			speaker_busy_until[speaker] = world.time + packet.duration
			queue.Cut(1, 2)
			queued_count--
			packet.cleanup()
		if(!queue.len)
			speaker_queues -= speaker
		if(MC_TICK_CHECK)
			return
	for(var/mob/speaker in speaker_busy_until.Copy())
		if(QDELETED(speaker) || world.time >= speaker_busy_until[speaker])
			speaker_busy_until -= speaker

/datum/controller/subsystem/tts/proc/clear_queue()
	for(var/mob/speaker in speaker_queues)
		var/list/queue = speaker_queues[speaker]
		for(var/datum/tts_packet/packet in queue)
			packet.discarded = TRUE
			packet.listeners.Cut()
			if(!(packet in active))
				packet.cleanup()
	pending.Cut()
	speaker_queues.Cut()
	speaker_busy_until.Cut()
	duplicates.Cut()
	queued_count = 0

/datum/controller/subsystem/tts/Shutdown()
	stopping = TRUE
	clear_queue()
	while(active.len || voice_request || pitch_request || profile_request)
		poll_connection()
		for(var/datum/tts_packet/packet in active.Copy())
			if(packet.poll())
				active -= packet
				packet.cleanup()
		if(active.len || voice_request || pitch_request || profile_request)
			sleep(1)
	fdel("tmp/tts/")

/datum/controller/subsystem/tts/proc/queue_speech(mob/speaker, mob/listener, message, datum/language/language, quiet = FALSE)
	if(stopping || !GLOB.tts_enabled || !available_voices.len || !speaker || !listener.client || !isliving(speaker) || speaker.stat == DEAD)
		return
	if(listener.get_preference_value(/datum/client_preference/tts_mode) == "Disabled" || text2num(listener.get_preference_value(/datum/client_preference/tts_volume)) <= 0)
		return
	if(language && (language.flags & (NONVERBAL|SIGNLANG|INNATE)))
		return
	if(!listener.say_understands(speaker, language))
		return
	var/turf/source = get_turf(speaker)
	if(!source)
		return
	var/static/regex/markup = regex("<\[^>]*>", "g")
	var/static/regex/unsafe_characters = regex("\[^a-zA-Z0-9 ,?.!'&-]", "g")
	var/static/regex/alphanumeric = regex("\[a-zA-Z0-9]")
	message = html_decode(markup.Replace(message, ""))
	message = trim(copytext(unsafe_characters.Replace(message, " "), 1, 300))
	if(!alphanumeric.Find(message))
		return
	var/voice = speaker.client ? speaker.get_preference_value(/datum/client_preference/tts_voice) : null
	if(!(voice in available_voices))
		var/identity = speaker.name
		if(ishuman(speaker))
			var/mob/living/carbon/human/human_speaker = speaker
			identity = human_speaker.GetVoice()
		voice = available_voices[(text2num(copytext(md5(identity), 1, 7), 16) % available_voices.len) + 1]
	var/pitch = pitch_available && speaker.client ? clamp(text2num(speaker.get_preference_value(/datum/client_preference/tts_pitch)), -4, 4) : 0
	var/speech_gender = null
	var/speech_age = 30
	if(speech_profiles_available)
		speech_gender = speaker.gender in list(MALE, FEMALE, NEUTER, PLURAL) ? speaker.gender : NEUTER
		if(ishuman(speaker))
			var/mob/living/carbon/human/human_speaker = speaker
			speech_age = isnum(human_speaker.age) ? clamp(human_speaker.age, 0, 120) : 30
	var/filter = issilicon(speaker) ? "silicon" : ""
	if(duplicate_tick != world.time)
		duplicates.Cut()
		duplicate_tick = world.time
	var/key = md5("\ref[speaker]|[message]|[voice]|[pitch]|[speech_gender]|[speech_age]|[filter]|[quiet]")
	var/datum/tts_packet/packet = duplicates[key]
	if(!packet)
		var/list/queue = speaker_queues[speaker]
		if(queued_count >= 64 || (queue && queue.len >= 8))
			return
		packet = new
		packet.speaker = speaker
		packet.source = source
		packet.message = message
		packet.voice = voice
		packet.pitch = pitch
		packet.speech_gender = speech_gender
		packet.speech_age = speech_age
		packet.filter = filter
		packet.quiet = quiet
		packet.created_at = world.time
		packet.identifier = "[md5("[world.realtime]|[key]")]-[++sequence]"
		if(!queue)
			queue = list()
			speaker_queues[speaker] = queue
		queue += packet
		queued_count++
		pending += packet
		duplicates[key] = packet
	packet.listeners[listener] = listener.client
	packet.listener_distances[listener] = get_dist(listener, source)

/datum/tts_http_job
	var/job_id
	var/list/response
	var/success = FALSE
	var/complete = FALSE

/datum/tts_http_job/proc/begin(url, body, list/headers, output_filename)
	var/list/options = list("timeout_seconds" = 10)
	if(output_filename)
		options["output_filename"] = output_filename
	job_id = rustg_http_request_async(RUSTG_HTTP_METHOD_GET, url, body, json_encode(headers), json_encode(options))

/datum/tts_http_job/proc/poll()
	if(complete)
		return TRUE
	var/result = rustg_http_check_request(job_id)
	if(result == RUSTG_JOB_NO_RESULTS_YET)
		return FALSE
	complete = TRUE
	try
		response = json_decode(result)
	catch(var/exception/error)
		response = list("error" = error.name)
		return TRUE
	if(islist(response))
		success = response["status_code"] == 200
	return TRUE

/datum/tts_packet
	var/mob/speaker
	var/turf/source
	var/message
	var/voice
	var/pitch
	var/speech_gender
	var/speech_age = 30
	var/filter
	var/quiet = FALSE
	var/identifier
	var/created_at
	var/duration = 10
	var/list/listeners = list()
	var/list/listener_distances = list()
	var/datum/tts_http_job/speech_request
	var/datum/tts_http_job/blips_request
	var/ready = FALSE
	var/failed = FALSE
	var/discarded = FALSE

/datum/tts_packet/proc/begin(base_url, list/headers)
	if(!fexists("tmp/tts/init.txt"))
		rustg_file_write("TTS audio cache", "tmp/tts/init.txt")
	var/query = "voice=[url_encode(voice)]&identifier=[url_encode(identifier)]&filter=[url_encode(filter)]&pitch=[pitch]&special_filters="
	var/list/payload = list("text" = message)
	if(speech_gender)
		payload["gender"] = speech_gender
		payload["age"] = speech_age
	var/body = json_encode(payload)
	speech_request = new
	blips_request = new
	speech_request.begin("[base_url]/tts?[query]", body, headers, "tmp/tts/[identifier].ogg")
	blips_request.begin("[base_url]/tts-blips?[query]", body, headers, "tmp/tts/[identifier]_blips.ogg")

/datum/tts_packet/proc/poll()
	var/speech_complete = speech_request.poll()
	var/blips_complete = blips_request.poll()
	if(!speech_complete || !blips_complete)
		return FALSE
	failed = !speech_request.success || !blips_request.success || !fexists("tmp/tts/[identifier].ogg") || !fexists("tmp/tts/[identifier]_blips.ogg")
	if(!failed)
		var/list/headers = speech_request.response["headers"]
		if(islist(headers))
			var/audio_duration = text2num(headers["audio-length"])
			if(audio_duration > 0)
				duration = clamp(audio_duration * 10, 1, 300)
			else
				duration = clamp(length(message), 10, 300)
		ready = TRUE
	return TRUE

/datum/tts_packet/proc/play()
	if(discarded || !GLOB.tts_enabled || QDELETED(speaker) || QDELETED(source))
		return
	for(var/mob/listener in listeners)
		if(QDELETED(listener) || !listener.client || listener.client != listeners[listener] || listener.is_deaf() || listener.sleeping || listener.stat == UNCONSCIOUS)
			continue
		var/mode = listener.get_preference_value(/datum/client_preference/tts_mode)
		var/volume = clamp(text2num(listener.get_preference_value(/datum/client_preference/tts_volume)), 0, 100)
		if(mode == "Disabled" || !volume)
			continue
		var/remote_ghost = isghost(listener) && listener.get_preference_value(/datum/client_preference/ghost_ears) == GLOB.PREF_ALL_SPEECH
		if(!remote_ghost && (listener.z != source.z || get_dist(listener, source) > listener_distances[listener] + 1))
			continue
		var/audio_file = mode == "Blips Only" ? "tmp/tts/[identifier]_blips.ogg" : "tmp/tts/[identifier].ogg"
		var/sound/audio = sound(fcopy_rsc(audio_file), volume = volume * (quiet ? 0.4 : 0.85))
		if(remote_ghost)
			sound_to(listener, audio)
		else
			listener.playsound_local(source, audio, audio.volume, use_pressure = !isghost(listener))

/datum/tts_packet/proc/cleanup()
	fdel("tmp/tts/[identifier].ogg")
	fdel("tmp/tts/[identifier]_blips.ogg")
	listeners.Cut()
	listener_distances.Cut()
	speech_request = null
	blips_request = null

/client/verb/choose_tts_voice()
	set name = "Choose Text To Speech Voice"
	set category = "OOC"
	if(!SStts.available_voices.len)
		to_chat(src, "<span class='notice'>TTS voices are not available. An administrator must enable TTS and configure its backend first.</span>")
		return
	var/list/choices = list("Automatic") + SStts.available_voices
	var/choice = input(src, "Choose your speaking voice.", "Text To Speech", get_preference_value(/datum/client_preference/tts_voice)) as null|anything in choices
	if(choice && set_preference(/datum/client_preference/tts_voice, choice))
		SScharacter_setup.queue_preferences_save(prefs)