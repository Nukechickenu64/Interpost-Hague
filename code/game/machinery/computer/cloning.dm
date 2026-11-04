/obj/machinery/computer/cloning
	name = "cloning control console"
	icon = 'icons/obj/computer.dmi'
	icon_keyboard = "med_key"
	icon_screen = "dna"
	light_color = "#315ab4"
	circuit = /obj/item/circuitboard/cloning
	req_access = list(access_heads) //Only used for record deletion right now.
	var/obj/machinery/dna_scannernew/scanner = null //Linked scanner. For scanning.
	var/list/pods = list() //Linked cloning pods.
	var/temp = ""
	var/scantemp = "Scanner unoccupied"
	var/menu = 1 //Which menu screen to display
	var/list/records = list()
	var/datum/dna2/record/active_record = null
	var/datum/dna2/record/identity_record = null
	var/datum/dna2/record/donor_record = null
	var/obj/item/disk/data/diskette = null //Mostly so the geneticist can steal everything.
	var/loading = 0 // Nice loading text

/obj/machinery/computer/cloning/Initialize()
	. = ..()
	if(istype(GLOB.using_map, /datum/map/alpha))
		SetName("Genetics Console")
	set_extension(src, /datum/extension/interactive/multitool, /datum/extension/interactive/multitool/cryo, list(/proc/is_operable))
	updatemodules()

/obj/machinery/computer/cloning/Destroy()
	if(diskette)
		diskette.dropInto(get_turf(src))
	releasecloner()
	return ..()

/obj/machinery/computer/cloning/proc/updatemodules()
	src.scanner = findscanner()
	for(var/obj/machinery/clonepod/P in pods.Copy())
		if(QDELETED(P))
			pods -= P
		else if(P.connected != src)
			pods -= P
		else if(!P.anchored)
			release_pod(P)
	findcloner()

/obj/machinery/computer/cloning/proc/findscanner()
	var/obj/machinery/dna_scannernew/scannerf = null

	//Try to find scanner on adjacent tiles first
	for(var/direction in GLOB.cardinal)
		scannerf = locate(/obj/machinery/dna_scannernew, get_step(src, direction))
		if (scannerf)
			return scannerf

	//Then look for a free one in the area
	if(!scannerf)
		var/area/A = get_area(src)
		if(!A)
			return
		for(var/obj/machinery/dna_scannernew/S in A.get_contents())
			if(S.z == z)
				return S

	return

/obj/machinery/computer/cloning/proc/releasecloner()
	for(var/obj/machinery/clonepod/P in pods)
		if(!QDELETED(P) && P.connected == src)
			P.connected = null
			P.name = initial(P.name)
	pods.Cut()

/obj/machinery/computer/cloning/proc/connect_pod(var/obj/machinery/clonepod/P)
	if(QDELETED(P) || !P.anchored)
		return 0
	if(P in pods)
		return 0

	if(P.connected)
		if(P.occupant || P.attempting)
			return 0
		P.connected.release_pod(P)
	P.connected = src
	pods += P
	rename_pods()

	return 1

/obj/machinery/computer/cloning/proc/release_pod(var/obj/machinery/clonepod/P)
	if(!(P in pods))
		return

	if(!QDELETED(P) && P.connected == src)
		P.connected = null
		P.name = initial(P.name)
	pods -= P
	rename_pods()
	return 1

/obj/machinery/computer/cloning/proc/rename_pods()
	for(var/i = pods.len; i >= 1; i--)
		var/obj/machinery/clonepod/P = pods[i]
		if(QDELETED(P) || P.connected != src)
			pods.Cut(i, i + 1)
	for(var/i = 1 to pods.len)
		var/atom/P = pods[i]
		P.name = istype(GLOB.using_map, /datum/map/alpha) ? "Clonepod [ascii2text(64 + i)]" : "[initial(P.name)] #[i]"

/obj/machinery/computer/cloning/proc/findcloner()
	var/area/A = get_area(src)
	if(!A)
		return
	for(var/obj/machinery/clonepod/P in A.get_contents())
		if(!QDELETED(P) && P.anchored && P.z == z && !P.connected)
			pods += P
			P.connected = src
	rename_pods()

/obj/machinery/computer/cloning/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/disk/data)) //INSERT SOME DISKETTES
		if (!src.diskette)
			if(!user || user.incapacitated() || !user.Adjacent(src) || W.loc != user || !user.unEquip(W, target = src))
				return
			src.diskette = W
			to_chat(user, "You insert \the [W].")
			src.updateUsrDialog()
			return
	else
		..()
	return

/obj/machinery/computer/cloning/Exited(atom/movable/O, atom/newloc)
	. = ..()
	if(O == diskette)
		diskette = null
		updateUsrDialog()

/obj/machinery/computer/cloning/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/cloning/attack_hand(mob/user as mob)
	if(!user || CanUseTopic(user) != STATUS_INTERACTIVE || !operable() || !powered())
		return
	user.set_machine(src)
	add_fingerprint(user)

	if(stat & (BROKEN|NOPOWER))
		return

	updatemodules()
	var/dat = ""
	dat += "<h3>Cloning System Control</h3>"
	dat += "<font size=-1><a href='byond://?src=\ref[src];refresh=1'>Refresh</a></font>"

	dat += "<br><tt>[temp]</tt><br>"

	switch(src.menu)
		if(1)
			// Modules
			dat += "<h4>Modules</h4>"
			//dat += "<a href='byond://?src=\ref[src];relmodules=1'>Reload Modules</a>"
			if (isnull(src.scanner))
				dat += " <font color=red>DNA scanner not found.</font><br>"
			else
				dat += " <font color=green>DNA scanner found.</font><br>"
			if (pods.len)
				dat += " <font color=green>[pods.len] cloning vat\s found.</font><br>"
			else
				dat += " <font color=red>No cloning vats found.</font><br>"

			// Scanner
			dat += "<h4>Scanner Functions</h4>"

			if(loading)
				dat += "<b>Scanning...</b><br>"
			else
				dat += "<b>[scantemp]</b><br>"

			if (isnull(src.scanner))
				dat += "No scanner connected!<br>"
			else
				if (src.scanner.occupant)
					if(scantemp == "Scanner unoccupied") scantemp = "" // Stupid check to remove the text

					dat += "<a href='byond://?src=\ref[src];scan=1'>Scan - [src.scanner.occupant]</a><br>"
				else
					scantemp = "Scanner unoccupied"

				dat += "Lock status: <a href='byond://?src=\ref[src];lock=1'>[src.scanner.locked ? "Locked" : "Unlocked"]</a><br>"

			if (pods.len)
				for (var/obj/machinery/clonepod/pod in pods)
					dat += "[pod] biomass: <i>[pod.biomass]</i><br>"

			// Database
			dat += "<h4>Database Functions</h4>"
			dat += "<a href='byond://?src=\ref[src];menu=2'>View Records</a><br>"
			if (src.diskette)
				dat += "<a href='byond://?src=\ref[src];disk=eject'>Eject Disk</a>"
				dat += " | <a href='byond://?src=\ref[src];disk=load'>Import genetic record</a>"


		if(2)
			dat += "<h4>Current records</h4>"
			dat += "<a href='byond://?src=\ref[src];menu=1'>Back</a><br><br>"
			for(var/datum/dna2/record/R in src.records)
				if(!QDELETED(R) && R.dna)
					dat += "<li><a href='byond://?src=\ref[src];view_rec=\ref[R]'>[html_encode(R.dna.real_name)]</a></li>"

		if(3)
			dat += "<h4>Selected Record</h4>"
			dat += "<a href='byond://?src=\ref[src];menu=2'>Back</a><br>"

			if (!src.active_record)
				dat += "<font color=red>ERROR: Record not found.</font>"
			else
				dat += {"<br><font size=1><a href='byond://?src=\ref[src];del_rec=1'>Delete Record</a></font><br>
					<b>Name:</b> [html_encode(src.active_record.dna.real_name)]<br>"}
				var/obj/item/implant/health/H = null
				if(src.active_record.implant)
					H=locate(src.active_record.implant)

				if ((H) && (istype(H)))
					dat += "<b>Health:</b> [H.sensehealth()] | OXY-BURN-TOX-BRUTE<br>"
				else
					dat += "<font color=red>Unable to locate implant.</font><br>"

				if (!isnull(src.diskette))
					dat += "<a href='byond://?src=\ref[src];disk=load'>Load from disk.</a>"

					dat += " | Save: <a href='byond://?src=\ref[src];save_disk=ue'>UI + UE</a>"
					dat += " | Save: <a href='byond://?src=\ref[src];save_disk=ui'>UI</a>"
					dat += " | Save: <a href='byond://?src=\ref[src];save_disk=se'>SE</a>"
					dat += " | <a href='byond://?src=\ref[src];save_disk=full'>Save GENECODE</a>"
					dat += "<br>"
				else
					dat += "<br>" //Keeping a line empty for appearances I guess.

				dat += "<b>Identity DNA:</b> [identity_record ? html_encode(identity_record.dna.real_name) : "Not selected"] "
				dat += "<a href='byond://?src=\ref[src];select_dna=identity;select_dna_record=\ref[src.active_record]'>Select this</a><br>"
				dat += "<b>Second DNA:</b> [donor_record ? html_encode(donor_record.dna.real_name) : "Not selected"] "
				dat += "<a href='byond://?src=\ref[src];select_dna=donor;select_dna_record=\ref[src.active_record]'>Select this</a><br>"
				if(identity_record && donor_record && (identity_record == donor_record || identity_record.dna.unique_enzymes == donor_record.dna.unique_enzymes))
					dat += "<font color=red><b>Warning:</b> Using one DNA profile twice will create a severely mutated clone.</font><br>"
				else
					dat += "Two DNA profiles will be combined to create the clone.<br>"

				dat += {"<b>UI:</b> [src.active_record.dna.uni_identity]<br>
				<b>SE:</b> [src.active_record.dna.struc_enzymes]<br><br>"}

				if(pods.len && identity_record && donor_record)
					dat += {"<a href='byond://?src=\ref[src];clone=1'>Grow clone</a><br>"}

		if(4)
			if (!src.active_record)
				src.menu = 2
			dat = "[src.temp]<br>"
			dat += "<h4>Confirm Record Deletion</h4>"

			dat += "<b><a href='byond://?src=\ref[src];del_rec=1'>Scan card to confirm.</a></b><br>"
			dat += "<b><a href='byond://?src=\ref[src];menu=3'>No</a></b>"

	// Add styled header with in-UI Close and open as a borderless window
	var/body = ""
	body += "<div style='display:flex;align-items:center;justify-content:flex-end;margin-bottom:6px;'>"
	body += "<a href='?src=\ref[src];ui_close=1'>Close</a>"
	body += "</div>"
	body += dat
	ui_browse_styled(user, "Cloning System Control", body, "window=cloning;size=500x600;can_close=0;can_resize=0;border=0;titlebar=0", src)
	// Keep legacy onclose hook
	onclose(user, "cloning")
	return

/obj/machinery/computer/cloning/Topic(href, href_list)
	if(..())
		return 1

	// Handle in-UI Close
	if(href_list["ui_close"])
		usr << browse(null, "window=cloning")
		usr.unset_machine()
		return

	if(loading)
		return
	if(CanUseTopic(usr) != STATUS_INTERACTIVE || !operable() || !powered())
		return
	updatemodules()

	if ((href_list["scan"]) && (!isnull(src.scanner)))
		scantemp = ""

		loading = 1
		var/obj/machinery/dna_scannernew/scan_source = scanner
		var/mob/living/carbon/human/subject = scan_source.occupant
		src.updateUsrDialog()

		spawn(20)
			if(QDELETED(src))
				return
			if(!operable() || !powered() || QDELETED(scan_source) || scan_source != scanner || !scan_source.operable() || !scan_source.powered() || scan_source.occupant != subject || QDELETED(subject))
				scantemp = "Scan interrupted: scanner, subject or power changed."
			else
				scan_mob(subject)

			loading = 0
			src.updateUsrDialog()


		//No locking an open scanner.
	else if ((href_list["lock"]) && (!isnull(src.scanner)))
		if ((!src.scanner.locked) && (src.scanner.occupant))
			src.scanner.locked = 1
		else
			src.scanner.locked = 0

	else if (href_list["view_rec"])
		var/datum/dna2/record/selected = locate(href_list["view_rec"])
		if(istype(selected) && (selected in records) && selected.dna)
			active_record = selected
			menu = 3
		else
			src.active_record = null
			src.temp = "Record missing."

	else if(href_list["select_dna"])
		var/datum/dna2/record/selected = locate(href_list["select_dna_record"])
		if(!selected && (src.active_record in src.records))
			selected = src.active_record
		if(!(selected in src.records))
			temp = "Error: DNA record is no longer available."
		else if(!selected.is_complete_genotype())
			temp = "Error: Cloning requires a complete GENECODE record (UI, UE and SE)."
		else if(href_list["select_dna"] == "identity")
			identity_record = selected
			temp = "Identity DNA selected."
		else if(href_list["select_dna"] == "donor")
			donor_record = selected
			temp = "Second DNA selected."

	else if (href_list["del_rec"])
		if ((!src.active_record) || (src.menu < 3))
			return
		if (src.menu == 3) //If we are viewing a record, confirm deletion
			src.temp = "Delete record?"
			src.menu = 4

		else if (src.menu == 4)
			var/obj/item/card/id/C = usr.get_active_hand()
			if (istype(C)||istype(C, /obj/item/device/pda))
				if(src.check_access(C))
					if(identity_record == src.active_record)
						identity_record = null
					if(donor_record == src.active_record)
						donor_record = null
					src.records.Remove(src.active_record)
					qdel(src.active_record)
					src.temp = "Record deleted."
					src.menu = 2
				else
					src.temp = "Access Denied."

	else if (href_list["disk"]) //Load or eject.
		switch(href_list["disk"])
			if("load")
				if (!diskette || diskette.loc != src || !diskette.buf || !diskette.buf.dna || !diskette.buf.types)
					src.temp = "Load error."
					src.updateUsrDialog()
					return
				active_record = diskette.buf.clone_record()
				records += active_record
				menu = 3
				src.temp = "Load successful."
			if("eject")
				if (!isnull(src.diskette))
					src.diskette.dropInto(loc)
					src.diskette = null

	else if (href_list["save_disk"]) //Save to disk!
		if (!diskette || diskette.loc != src || diskette.read_only || !(active_record in records) || !active_record.dna)
			src.temp = "Save error."
			src.updateUsrDialog()
			return

		var/save_types
		switch(href_list["save_disk"]) //Save as Ui/Ui+Ue/Se
			if("ui")
				save_types = DNA2_BUF_UI
			if("ue")
				save_types = DNA2_BUF_UI|DNA2_BUF_UE
			if("se")
				save_types = DNA2_BUF_SE
			if("full")
				save_types = DNA2_BUF_UI|DNA2_BUF_UE|DNA2_BUF_SE
		if(!save_types || (active_record.types & save_types) != save_types)
			temp = "Save error: the record does not contain all requested genetic data."
		else
			diskette.buf = active_record.clone_record()
			diskette.buf.types = save_types
			diskette.update_genetic_label()
			temp = "Save \[[href_list["save_disk"]]\] successful."

	else if (href_list["refresh"])
		src.updateUsrDialog()

	else if (href_list["clone"])
		var/datum/dna2/record/C = identity_record
		var/datum/dna2/record/D = donor_record
		//Look for that player! They better be dead!
		if(istype(C) && istype(D) && (C in records) && (D in records) && C.is_complete_genotype() && D.is_complete_genotype())
			//Can't clone without someone to clone.  Or a pod.  Or if the pod is busy. Or full of gibs.
			if(!pods.len)
				temp = "Error: No clone pods detected."
			else
				var/obj/machinery/clonepod/pod = pods[1]
				var/list/choices = pods.Copy()
				var/mob/operator = usr
				if (pods.len > 1)
					pod = input(operator,"Select a cloning pod to use", "Pod selection") as null|anything in choices
				if(!pod)
					return
				if(QDELETED(src) || QDELETED(operator))
					return
				if(CanUseTopic(operator) != STATUS_INTERACTIVE || !operable() || !powered())
					to_chat(operator, SPAN_WARNING("Cloning interrupted: the operator or Genetics Console is unavailable."))
					return
				if(QDELETED(pod) || !pod.anchored || !(pod in pods) || pod.connected != src || !(C in records) || !(D in records) || C != identity_record || D != donor_record)
					temp = "Error: Selected pod or genetic records changed. Select again."
				else if(!pod.operable() || !pod.powered())
					temp = "Error: Clonepod is not operational."
				else if(pod.occupant || pod.attempting)
					temp = "Error: Clonepod is currently occupied."
				else if(pod.biomass < CLONE_BIOMASS)
					temp = "Error: Not enough biomass."
				else if(pod.mess)
					temp = "Error: Clonepod malfunction."
				else if(!config.revival_cloning)
					temp = "Error: Unable to initiate cloning cycle."

				else if(pod.growclone(C, D))
					temp = "Initiating cloning cycle..."
					menu = 1
				else
					temp = "Error: Clone initialization failed."


		else
			temp = "Error: Select two valid DNA records first."

	else if (href_list["menu"])
		src.menu = text2num(href_list["menu"])

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return

/obj/machinery/computer/cloning/proc/scan_mob(mob/living/carbon/human/subject as mob)
	if ((isnull(subject)) || (!(ishuman(subject))) || (!subject.dna))
		scantemp = "Error: Unable to locate valid genetic data."
		return
	if(!config.use_cortical_stacks)
		if (!subject.has_brain())
			if(ishuman(subject))
				var/mob/living/carbon/human/H = subject
				if(H.should_have_organ(BP_BRAIN))
					scantemp = "Error: No signs of intelligence detected."
			else
				scantemp = "Error: No signs of intelligence detected."
			return
		if ((!subject.ckey) || (!subject.client))
			scantemp = "Error: Mental interface failure."
			return
		if(subject.isSynthetic())
			scantemp = "Error: Subject is not organic."
			return
	if (NOCLONE in subject.mutations)
		scantemp = "Error: Major genetic degradation."
		return
	if (subject.species.species_flags & SPECIES_FLAG_NO_SCAN)
		scantemp = "Error: Incompatible species."
		return
	if (subject.ckey && !isnull(find_record(subject.ckey)))
		scantemp = "Subject already in database."
		return

	subject.dna.check_integrity()

	var/datum/dna2/record/R = new /datum/dna2/record()
	R.dna = subject.dna.Clone()
	R.dna.body_markings = list()
	for(var/marking in subject.dna.body_markings)
		var/list/data = subject.dna.body_markings[marking]
		R.dna.body_markings[marking] = data.Copy()
	R.ckey = subject.ckey ? subject.ckey : "no ckey"
	R.id= copytext(md5(subject.real_name), 2, 6)
	R.name=R.dna.real_name
	R.types=DNA2_BUF_UI|DNA2_BUF_UE|DNA2_BUF_SE
	R.languages = subject.languages.Copy()
	R.flavor=subject.flavor_texts.Copy()

	//Add an implant if needed
	var/obj/item/implant/health/imp = locate(/obj/item/implant/health, subject)
	if (isnull(imp))
		imp = new /obj/item/implant/health(subject)
		imp.implanted = subject
		R.implant = "\ref[imp]"
	//Update it if needed
	else
		R.implant = "\ref[imp]"

	if (!isnull(subject.mind)) //Save that mind so traitors can continue traitoring after cloning.
		R.mind = "\ref[subject.mind]"

	src.records += R
	scantemp = "Subject successfully scanned."

//Find a specific record by key.
/obj/machinery/computer/cloning/proc/find_record(var/find_key)
	var/selected_record = null
	for(var/datum/dna2/record/R in src.records)
		if (R.ckey == find_key)
			selected_record = R
			break
	return selected_record