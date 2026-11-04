//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/var/list/req_access = list()
/obj/var/list/req_one_access = list()

/atom/movable/var/map_access = null // Mapper shorthand; null preserves the subtype's access requirements.

/proc/mapper_access_key(value)
	return replacetext(replacetext(lowertext(trim(value)), " ", "_"), "-", "_")

/proc/get_mapper_access_names()
	var/static/list/names
	if(!names)
		names = list()
		var/list/access_datums = get_all_access_datums()
		for(var/datum/access/A in access_datums)
			if(A.id > 0 && length(A.desc))
				names[mapper_access_key(A.desc)] = A.id
		// Subtype names take precedence over descriptions (notably "security").
		for(var/datum/access/A in access_datums)
			if(A.id > 0)
				var/list/path_parts = splittext("[A.type]", "/")
				names[mapper_access_key(path_parts[path_parts.len])] = A.id
		names["command"] = access_heads
		names["medbay"] = access_medical
		names["supply"] = access_cargo
		names["brig"] = access_brig
		names["synth"] = access_synth
	return names

// Returns the existing all/any requirement lists, or a fail-closed requirement.
/proc/parse_mapper_access(expression, atom/owner, field = "map_access")
	var/list/all_access = list()
	var/list/any_access = list()
	var/error
	if(!istext(expression))
		error = "expected access names as text"
	else
		expression = trim(expression)
		if(lowertext(expression) == "public")
			return list("all" = all_access, "any" = any_access)
		var/require_all = findtext(expression, "&")
		if(!length(expression))
			error = "empty expression; use public to remove restrictions"
		else if(require_all && (findtext(expression, "|") || findtext(expression, ",")))
			error = "cannot mix & with | or commas"
		else
			var/list/names = get_mapper_access_names()
			var/list/tokens = splittext(replacetext(expression, ",", "|"), require_all ? "&" : "|")
			for(var/token in tokens)
				var/key = mapper_access_key(token)
				if(findtext(key, "access_") == 1)
					key = copytext(key, 8)
				var/id = names[key]
				if(!id)
					var/numeric_id = text2num(key)
					if(numeric_id > 0 && "[numeric_id]" == key && get_access_by_id(numeric_id))
						id = numeric_id
				if(!id)
					error = "unknown access '[token]'"
					break
				if(require_all)
					all_access |= id
				else
					any_access |= id
			if(!error && !all_access.len && !any_access.len)
				error = "no access names; use public to remove restrictions"
	if(error)
		log_warning("Mapper access: [owner.type] at ([owner.x],[owner.y],[owner.z]), [field]: [error]. Access denied until corrected.")
		return list("all" = list(-1), "any" = list())
	return list("all" = all_access, "any" = any_access)

/atom/movable/proc/apply_map_access()
	if(!isnull(map_access))
		log_warning("Mapper access: [type] at ([x],[y],[z]) does not support map_access.")

/obj/apply_map_access()
	if(isnull(map_access))
		return
	var/list/requirements = parse_mapper_access(map_access, src)
	req_access = requirements["all"]
	req_one_access = requirements["any"]

// Preserve specialized authorization rules unless a mapper explicitly overrides them.
/obj/proc/check_mapper_access(list/accesses, default_allowed)
	return isnull(map_access) ? default_allowed : check_access_list(accesses)

//returns 1 if this mob has sufficient access to use this object
/obj/proc/allowed(mob/M)
	//check if it doesn't require any access at all
	if(src.check_access(null))
		return 1
	if(!istype(M))
		return 0
	return check_access_list(M.GetAccess())

/atom/movable/proc/GetAccess()
	var/obj/item/card/id/id = GetIdCard()
	return id ? id.GetAccess() : list()

/atom/movable/proc/GetIdCard()
	return null

/obj/proc/check_access(obj/item/I)
	return check_access_list(I ? I.GetAccess() : list())

/obj/proc/check_access_list(var/list/L)
	if(!req_access)		req_access = list()
	if(!req_one_access)	req_one_access = list()
	if(!istype(L, /list))	return 0
	return has_access(req_access, req_one_access, L)

/proc/has_access(var/list/req_access, var/list/req_one_access, var/list/accesses)
	for(var/req in req_access)
		if(!(req in accesses)) //doesn't have this access
			return 0
	if(req_one_access.len)
		for(var/req in req_one_access)
			if(req in accesses) //has an access from the single access list
				return 1
		return 0
	return 1

/proc/get_centcom_access(job)
	switch(job)
		if("VIP Guest")
			return list(access_cent_general)
		if("Custodian")
			return list(access_cent_general, access_cent_living, access_cent_storage)
		if("Thunderdome Overseer")
			return list(access_cent_general, access_cent_thunder)
		if("Intel Officer")
			return list(access_cent_general, access_cent_living)
		if("Medical Officer")
			return list(access_cent_general, access_cent_living, access_cent_medical)
		if("Death Commando")
			return list(access_cent_general, access_cent_specops, access_cent_living, access_cent_storage)
		if("Research Officer")
			return list(access_cent_general, access_cent_specops, access_cent_medical, access_cent_teleporter, access_cent_storage)
		if("BlackOps Commander")
			return list(access_cent_general, access_cent_thunder, access_cent_specops, access_cent_living, access_cent_storage, access_cent_creed)
		if("Supreme Commander")
			return get_all_centcom_access()

/var/list/datum/access/priv_all_access_datums
/proc/get_all_access_datums()
	if(!priv_all_access_datums)
		priv_all_access_datums = init_subtypes(/datum/access)
		priv_all_access_datums = dd_sortedObjectList(priv_all_access_datums)

	return priv_all_access_datums.Copy()

/var/list/datum/access/priv_all_access_datums_id
/proc/get_all_access_datums_by_id()
	if(!priv_all_access_datums_id)
		priv_all_access_datums_id = list()
		for(var/datum/access/A in get_all_access_datums())
			priv_all_access_datums_id["[A.id]"] = A

	return priv_all_access_datums_id.Copy()

/var/list/datum/access/priv_all_access_datums_region
/proc/get_all_access_datums_by_region()
	if(!priv_all_access_datums_region)
		priv_all_access_datums_region = list()
		for(var/datum/access/A in get_all_access_datums())
			if(!priv_all_access_datums_region[A.region])
				priv_all_access_datums_region[A.region] = list()
			priv_all_access_datums_region[A.region] += A

	return priv_all_access_datums_region.Copy()

/proc/get_access_ids(var/access_types = ACCESS_TYPE_ALL)
	var/list/L = new()
	for(var/datum/access/A in get_all_access_datums())
		if(A.access_type & access_types)
			L += A.id
	return L

/var/list/priv_all_access
/proc/get_all_accesses()
	if(!priv_all_access)
		priv_all_access = get_access_ids()

	return priv_all_access.Copy()

/var/list/priv_station_access
/proc/get_all_station_access()
	if(!priv_station_access)
		priv_station_access = get_access_ids(ACCESS_TYPE_STATION)

	return priv_station_access.Copy()

/var/list/priv_centcom_access
/proc/get_all_centcom_access()
	if(!priv_centcom_access)
		priv_centcom_access = get_access_ids(ACCESS_TYPE_CENTCOM)

	return priv_centcom_access.Copy()

/var/list/priv_syndicate_access
/proc/get_all_syndicate_access()
	if(!priv_syndicate_access)
		priv_syndicate_access = get_access_ids(ACCESS_TYPE_SYNDICATE)

	return priv_syndicate_access.Copy()

/var/list/priv_region_access
/proc/get_region_accesses(var/code)
	if(code == ACCESS_REGION_ALL)
		return get_all_station_access()

	if(!priv_region_access)
		priv_region_access = list()
		for(var/datum/access/A in get_all_access_datums())
			if(!priv_region_access["[A.region]"])
				priv_region_access["[A.region]"] = list()
			priv_region_access["[A.region]"] += A.id

	var/list/region = priv_region_access["[code]"]
	return region.Copy()

/proc/get_region_accesses_name(var/code)
	switch(code)
		if(ACCESS_REGION_ALL)
			return "All"
		if(ACCESS_REGION_SECURITY) //security
			return "Security"
		if(ACCESS_REGION_MEDBAY) //medbay
			return "Medbay"
		if(ACCESS_REGION_RESEARCH) //research
			return "Research"
		if(ACCESS_REGION_ENGINEERING) //engineering and maintenance
			return "Engineering"
		if(ACCESS_REGION_COMMAND) //command
			return "Command"
		if(ACCESS_REGION_GENERAL) //station general
			return "General"
		if(ACCESS_REGION_SUPPLY) //supply
			return "Supply"

/proc/get_access_desc(id)
	var/list/AS = priv_all_access_datums_id || get_all_access_datums_by_id()
	var/datum/access/A = AS["[id]"]

	return A ? A.desc : ""

/proc/get_centcom_access_desc(A)
	return get_access_desc(A)

/proc/get_access_by_id(id)
	var/list/AS = priv_all_access_datums_id || get_all_access_datums_by_id()
	return AS[num2text(id)]

/proc/get_all_jobs()
	var/list/all_jobs = list()
	var/list/all_datums = typesof(/datum/job)
	all_datums -= exclude_jobs
	var/datum/job/jobdatum
	for(var/jobtype in all_datums)
		jobdatum = new jobtype
		all_jobs.Add(jobdatum.title)
	return all_jobs

/proc/get_all_centcom_jobs()
	return list("VIP Guest",
		"Custodian",
		"Thunderdome Overseer",
		"Intel Officer",
		"Medical Officer",
		"Death Commando",
		"Research Officer",
		"BlackOps Commander",
		"Supreme Commander",
		"Emergency Response Team",
		"Emergency Response Team Leader")

/mob/observer/ghost
	var/static/obj/item/card/id/all_access/ghost_all_access

/mob/observer/ghost/GetIdCard()
	if(!is_admin(src))
		return

	if(!ghost_all_access)
		ghost_all_access = new()
	return ghost_all_access

/mob/living/bot/GetIdCard()
	return botcard

#define HUMAN_ID_CARDS list(get_active_hand(), wear_id, wear_amulet, get_inactive_hand())
/mob/living/carbon/human/GetIdCard()
	for(var/item_slot in HUMAN_ID_CARDS)
		var/obj/item/I = item_slot
		var/obj/item/card/id = I ? I.GetIdCard() : null
		if(id)
			return id

/mob/living/carbon/human/GetAccess()
	. = list()
	for(var/item_slot in HUMAN_ID_CARDS)
		var/obj/item/I = item_slot
		if(I)
			. |= I.GetAccess()
	if(mind?.has_epicurean_trophy("command_brain"))
		. |= access_security
#undef HUMAN_ID_CARDS

/mob/living/silicon/GetIdCard()
	if(stat || (ckey && !client))
		return // Unconscious, dead or once possessed but now client-less silicons are not considered to have id access.
	return idcard

/proc/FindNameFromID(var/mob/M, var/missing_id_name = "Unknown")
	var/obj/item/card/id/C = M.GetIdCard()
	if(C)
		return C.registered_name
	return missing_id_name

/proc/get_all_job_icons() //For all existing HUD icons
	return joblist + list("Prisoner")

/obj/proc/GetJobName() //Used in secHUD icon generation
	var/obj/item/card/id/I = GetIdCard()

	if(I)
		var/job_icons = get_all_job_icons()
		if(I.assignment	in job_icons) //Check if the job has a hud icon
			return I.assignment
		if(I.rank in job_icons)
			return I.rank

		var/centcom = get_all_centcom_jobs()
		if(I.assignment	in centcom) //Return with the NT logo if it is a Centcom job
			return "Centcom"
		if(I.rank in centcom)
			return "Centcom"
	else
		return

	return "Unknown" //Return unknown if none of the above apply
