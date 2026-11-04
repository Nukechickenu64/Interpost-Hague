/*
Research and Development (R&D) Console

This is the main work horse of the R&D system. It contains the menus/controls for the Destructive Analyzer, Replicator, and Circuit
imprinter. It also contains the /datum/research holder with all the known/possible technology paths and device designs.

Basic use: It links to the closest available replicator anywhere on the map, and to other fabrication devices within 4 squares.
Devices must have their maintenance panels closed and cannot already belong to another console. The settings menu lets a player
re-sync devices or disconnect a specific device. Re-syncing also switches to a closer available replicator if one exists.

The imprinting and construction menus do NOT require toxins access to access but all the other menus do. However, if you leave it
on a menu, nothing is to stop the person from using the options on that menu (although they won't be able to change to a different
one). You can also lock the console on the settings menu if you're feeling paranoid and you don't want anyone messing with it who
doesn't have toxins access.

Each console stores its technology levels and designs locally. It neither syncs with research servers nor automatically backs up
to the Central R&D Database. Fabrication uses the linked console's local data, without requiring a server.

Resetting, destroying, or disassembling a console loses its research. Back up or transfer data using Technology Disks and Design
Disks, each of which holds one technology or design. Technology exports are snapshots: later console upgrades do not change a disk.
*/

/obj/machinery/computer/rdconsole
	name = "replicator console"
	desc = "Console controlling the various fabrication devices. Stores technology and blueprints in its own learning matrix without a research server. Back up research using technology and design disks."
	icon_keyboard = "rd_key"
	icon_screen = "rdcomp"
	light_color = "#a97faa"
	circuit = /obj/item/circuitboard/rdconsole
	var/datum/research/files							//Stores all the collected research data.
	var/obj/item/disk/tech_disk/t_disk = null	//Stores the technology disk.
	var/obj/item/disk/design_disk/d_disk = null	//Stores the design disk.

	var/obj/machinery/r_n_d/destructive_analyzer/linked_destroy = null	//Linked Destructive Analyzer
	var/obj/machinery/r_n_d/protolathe/linked_lathe = null				//Linked Replicator
	var/obj/machinery/r_n_d/circuit_imprinter/linked_imprinter = null	//Linked Circuit Imprinter

	var/screen = 1.0	//Which screen is currently showing.
	var/id = 0			//Legacy ID retained for map compatibility.
	var/sync = 0		//Legacy server-controller field; local consoles never connect.

	req_access = list(access_research)	//Data and setting manipulation requires scientist access.

/obj/machinery/computer/rdconsole/proc/CallMaterialName(var/ID)
	var/return_name = ID
	switch(return_name)
		if("metal")
			return_name = "Metal"
		if("glass")
			return_name = "Glass"
		if("gold")
			return_name = "Gold"
		if("silver")
			return_name = "Silver"
		if("phoron")
			return_name = "Solid Phoron"
		if("uranium")
			return_name = "Uranium"
		if("diamond")
			return_name = "Diamond"
	return return_name

/obj/machinery/computer/rdconsole/proc/CallReagentName(var/reagent_type)
	var/datum/reagent/R = reagent_type
	return ispath(reagent_type, /datum/reagent) ? initial(R.name) : "Unknown"

/obj/machinery/computer/rdconsole/proc/SyncRDevices() //Makes sure it is properly sync'ed up with the devices attached to it (if any).
	var/turf/console_turf = get_turf(src)
	if(!console_turf)
		return
	var/obj/machinery/r_n_d/protolathe/closest_replicator
	var/closest_distance = INFINITY
	for(var/obj/machinery/r_n_d/protolathe/R in SSmachines.machinery)
		if(QDELETED(R) || R.panel_open || (R.linked_console && R.linked_console != src))
			continue
		var/turf/replicator_turf = get_turf(R)
		if(!replicator_turf)
			continue
		// Tile distance across all map levels; get_dist() returns -1 between different z levels.
		var/distance = max(abs(console_turf.x - replicator_turf.x), abs(console_turf.y - replicator_turf.y), abs(console_turf.z - replicator_turf.z))
		if(distance < closest_distance || (distance == closest_distance && R == linked_lathe))
			closest_distance = distance
			closest_replicator = R
	if(linked_lathe != closest_replicator)
		if(linked_lathe && linked_lathe.linked_console == src)
			linked_lathe.linked_console = null
		linked_lathe = closest_replicator
	if(linked_lathe)
		linked_lathe.linked_console = src

	for(var/obj/machinery/r_n_d/D in range(4, src))
		if(D.linked_console != null || D.panel_open)
			continue
		if(istype(D, /obj/machinery/r_n_d/destructive_analyzer))
			if(linked_destroy == null)
				linked_destroy = D
				D.linked_console = src
		else if(istype(D, /obj/machinery/r_n_d/circuit_imprinter))
			if(linked_imprinter == null)
				linked_imprinter = D
				D.linked_console = src
	return

/obj/machinery/computer/rdconsole/proc/add_ic_design(var/obj/item/device/electronic_assembly/assembly)
	files.AddDesign2Known(new /datum/design/prefab(files,create_prefab_from_assembly(assembly)))

/obj/machinery/computer/rdconsole/New()
	..()
	files = new /datum/research(src) //Setup the research data holder.

/obj/machinery/computer/rdconsole/Initialize()
	. = ..()
	sync = FALSE
	// All map machines must be registered before choosing the nearest replicator.
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/rdconsole/LateInitialize()
	SyncRDevices()

/obj/machinery/computer/rdconsole/Destroy()
	if(!QDELETED(t_disk) && t_disk.loc == src)
		t_disk.dropInto(loc)
	t_disk = null
	if(!QDELETED(d_disk) && d_disk.loc == src)
		d_disk.dropInto(loc)
	d_disk = null
	QDEL_NULL(files)
	for(var/obj/machinery/r_n_d/D in list(linked_destroy, linked_lathe, linked_imprinter))
		if(D.linked_console == src)
			D.linked_console = null
	linked_destroy = null
	linked_lathe = null
	linked_imprinter = null
	return ..()

/obj/machinery/computer/rdconsole/attackby(var/obj/item/weapon/D as obj, var/mob/user as mob)
	//Loading a disk into it.
	if(istype(D, /obj/item/disk))
		if(t_disk || d_disk)
			to_chat(user, "A disk is already loaded into the machine.")
			return

		if(!istype(D, /obj/item/disk/tech_disk) && !istype(D, /obj/item/disk/design_disk))
			to_chat(user, "<span class='notice'>Machine cannot accept disks in that format.</span>")
			return
		if(!user.unEquip(D, FALSE, src))
			to_chat(user, "<span class='warning'>You cannot insert \the [D] while it cannot be removed from your inventory.</span>")
			return
		if(istype(D, /obj/item/disk/tech_disk))
			t_disk = D
		else
			d_disk = D
		to_chat(user, "<span class='notice'>You add \the [D] to the machine.</span>")
	else
		//The construction/deconstruction of the console code.
		..()

	src.updateUsrDialog()
	return

/obj/machinery/computer/rdconsole/emp_act(var/remaining_charges, var/mob/user)
	if(!emagged)
		playsound(src.loc, 'sound/effects/sparks4.ogg', 75, 1)
		emagged = 1
		to_chat(user, "<span class='notice'>You you disable the security protocols.</span>")
		return 1

/obj/machinery/computer/rdconsole/CanUseTopic(var/mob/user, var/datum/topic_state/state, var/href_list)
	if(topic_requires_research_access(href_list) && !allowed(user) && !emagged)
		to_chat(user, "Unauthorized Access.")
		return STATUS_CLOSE
	if(href_list["menu"])
		var/temp_screen = text2num(href_list["menu"])
		if(!(topic_menu_is_public(temp_screen) || allowed(user) || emagged))
			to_chat(user, "Unauthorized Access.")
			return STATUS_CLOSE
	return ..()

/obj/machinery/computer/rdconsole/proc/topic_menu_is_public(var/menu)
	return menu <= 1.1 || (3 <= menu && menu <= 5.0)


/obj/machinery/computer/rdconsole/proc/topic_requires_research_access(var/list/href_list)
	var/list/restricted_actions = list(
		"updt_tech", "clear_tech", "eject_tech", "copy_tech",
		"updt_design", "clear_design", "eject_design", "copy_design",
		"eject_item", "deconstruct", "reclaim", "lock", "sync", "togglesync",
		"find_device", "disconnect", "reset"
	)
	for(var/action in restricted_actions)
		if(href_list[action])
			return TRUE
	return FALSE

/obj/machinery/computer/rdconsole/OnTopic(mob/user, href_list)
	if(href_list["ui_close"] || href_list["close"]) {
		usr << browse(null, "window=rdconsole")
		usr.unset_machine()
		return TOPIC_HANDLED
	}
	if(href_list["menu"]) //Switches menu screens. Converts a sent text string into a number. Saves a LOT of code.
		screen = text2num(href_list["menu"])
		. = TOPIC_REFRESH

	else if(href_list["updt_tech"]) //Update the research holder with information from the technology disk.
		if(!t_disk || !t_disk.stored)
			to_chat(user, "<span class='notice'>Insert a technology disk containing research.</span>")
			return TOPIC_REFRESH
		if(QDELETED(t_disk) || t_disk.loc != src || href_list["disk"] != "\ref[t_disk]" || href_list["recording"] != "\ref[t_disk.stored]")
			to_chat(user, "<span class='warning'>The disk or its recording changed. Review the current contents before importing it.</span>")
			return TOPIC_REFRESH
		var/obj/item/disk/tech_disk/upload_disk = t_disk
		var/datum/tech/upload_tech = t_disk.stored
		if(QDELETED(upload_tech))
			to_chat(user, "<span class='warning'>The research recording is no longer available.</span>")
			return TOPIC_REFRESH
		if(istype(GLOB.using_map, /datum/map/alpha) && (!(upload_tech.type in research_technology_types()) || upload_tech.level != 1))
			to_chat(user, "<span class='warning'>This recording is not an extracted technology from the OS13 wiki catalogue.</span>")
			return TOPIC_REFRESH
		var/datum/research/upload_files = files
		var/upload_id = upload_tech.id
		var/upload_level = upload_tech.level
		screen = 0.0
		. = TOPIC_REFRESH
		spawn(50)
			if(QDELETED(src))
				return
			if(files != upload_files || QDELETED(upload_files))
				to_chat(user, "<span class='warning'>Technology import cancelled: the console's research database changed.</span>")
				return
			if(QDELETED(upload_disk) || QDELETED(upload_tech) || t_disk != upload_disk || upload_disk.loc != src || upload_disk.stored != upload_tech || (stat & (BROKEN|NOPOWER)) || !powered())
				screen = 1.0
				to_chat(user, "<span class='warning'>Technology import interrupted: check the disk and console power.</span>")
				updateUsrDialog()
				return
			if(upload_tech.id != upload_id || upload_tech.level != upload_level)
				screen = 1.2
				to_chat(user, "<span class='warning'>Technology import cancelled: the recording's technology or level changed during processing. Review its current contents before importing again.</span>")
				updateUsrDialog()
				return
			screen = 1.2
			var/list/previous_designs = files.known_designs.Copy()
			var/list/previous_archives = list()
			if(istype(GLOB.using_map, /datum/map/alpha))
				for(var/tech_type in research_technology_types())
					if(research_archive_available(tech_type))
						previous_archives += tech_type
			if(!files.AddTech2Known(upload_tech))
				to_chat(user, "<span class='warning'>Technology import refused: the recording is outside this research catalogue.</span>")
				updateUsrDialog()
				return
			files.RefreshResearch() // Newly uploaded technology may unlock additional fabrication designs.
			if(istype(GLOB.using_map, /datum/map/alpha))
				to_chat(user, "<span class='notice'>[html_encode(upload_tech.name)] technology installed.</span>")
				for(var/tech_type in research_technology_types())
					if(tech_type == upload_tech.type || (tech_type in previous_archives) || !research_archive_available(tech_type))
						continue
					var/datum/tech/os13/revealed = tech_type
					to_chat(user, "<span class='notice'>New cyberspace archive available: [html_encode(initial(revealed.name))]. Extract and install its data to unlock its technology.</span>")
				var/unlocked_designs = 0
				for(var/datum/design/D in files.known_designs)
					if((D in previous_designs) || !D.build_path || !(D.build_type & PROTOLATHE))
						continue
					unlocked_designs++
					to_chat(user, "<span class='notice'>New replicator design available: [html_encode(D.name)].</span>")
				if(!unlocked_designs)
					to_chat(user, "<span class='notice'>Technology disk processed. No additional replicator designs unlocked.</span>")
			updateUsrDialog()

	else if(href_list["clear_tech"]) //Erase data on the technology disk.
		if(!t_disk)
			to_chat(user, "<span class='notice'>No technology disk is loaded.</span>")
			return TOPIC_REFRESH
		if(t_disk.loc != src || href_list["disk"] != "\ref[t_disk]" || !t_disk.stored || href_list["recording"] != "\ref[t_disk.stored]")
			to_chat(user, "<span class='warning'>The disk or its recording changed. Review the current contents before clearing it.</span>")
			return TOPIC_REFRESH
		t_disk.set_research(null)
		. = TOPIC_REFRESH

	else if(href_list["eject_tech"]) //Eject the technology disk.
		if(!t_disk)
			to_chat(user, "<span class='notice'>No technology disk is loaded.</span>")
			return TOPIC_REFRESH
		if(QDELETED(t_disk) || t_disk.loc != src || href_list["disk"] != "\ref[t_disk]")
			to_chat(user, "<span class='warning'>The disk changed. Review the current media before ejecting it.</span>")
			return TOPIC_REFRESH
		t_disk.dropInto(loc)
		t_disk = null
		screen = 1.0
		. = TOPIC_REFRESH

	else if(href_list["copy_tech"]) //Copys some technology data from the research holder to the disk.
		if(!t_disk)
			to_chat(user, "<span class='notice'>Insert a technology disk to back up research.</span>")
			return TOPIC_REFRESH
		if(QDELETED(t_disk) || t_disk.loc != src || href_list["disk"] != "\ref[t_disk]")
			to_chat(user, "<span class='warning'>The disk changed. Review the current media before copying research.</span>")
			return TOPIC_REFRESH
		if(t_disk.stored)
			to_chat(user, "<span class='warning'>The technology disk already contains data. Clear it before copying new research.</span>")
			return TOPIC_REFRESH
		if(!files || QDELETED(files) || href_list["database"] != "\ref[files]")
			to_chat(user, "<span class='warning'>The research database changed. Review the current technology before copying it.</span>")
			return TOPIC_REFRESH
		var/copied = FALSE
		for(var/datum/tech/T in files.known_tech)
			if(href_list["copy_tech_ID"] == T.id && href_list["technology"] == "\ref[T]" && href_list["level"] && text2num(href_list["level"]) == T.level)
				if(istype(GLOB.using_map, /datum/map/alpha) && T.level <= 0)
					to_chat(user, "<span class='warning'>Extract and install this technology before backing it up.</span>")
					return TOPIC_REFRESH
				var/datum/tech/backup = new T.type()
				backup.level = T.level
				t_disk.set_research(backup)
				copied = TRUE
				break
		if(!copied)
			to_chat(user, "<span class='warning'>That technology or its level changed. Review the current research before copying it.</span>")
		screen = 1.2
		. = TOPIC_REFRESH

	else if(href_list["updt_design"]) //Updates the research holder with design data from the design disk.
		if(!d_disk || !d_disk.blueprint)
			to_chat(user, "<span class='notice'>Insert a design disk containing a blueprint.</span>")
			return TOPIC_REFRESH
		if(QDELETED(d_disk) || d_disk.loc != src || href_list["disk"] != "\ref[d_disk]" || href_list["recording"] != "\ref[d_disk.blueprint]")
			to_chat(user, "<span class='warning'>The disk or its recording changed. Review the current contents before importing it.</span>")
			return TOPIC_REFRESH
		var/obj/item/disk/design_disk/upload_disk = d_disk
		var/datum/design/upload_design = d_disk.blueprint
		if(istype(GLOB.using_map, /datum/map/alpha) && !files.DesignHasReqs(upload_design))
			to_chat(user, "<span class='warning'>This blueprint is outside the installed OS13 wiki technologies. Install the matching technology first.</span>")
			return TOPIC_REFRESH
		var/datum/research/upload_files = files
		screen = 0.0
		. = TOPIC_REFRESH
		spawn(50)
			if(QDELETED(src))
				return
			if(files != upload_files || QDELETED(upload_files))
				to_chat(user, "<span class='warning'>Design import cancelled: the console's research database changed.</span>")
				return
			if(QDELETED(upload_disk) || QDELETED(upload_design) || d_disk != upload_disk || upload_disk.loc != src || upload_disk.blueprint != upload_design || (stat & (BROKEN|NOPOWER)) || !powered())
				screen = 1.0
				to_chat(user, "<span class='warning'>Design import interrupted: check the disk and console power.</span>")
				updateUsrDialog()
				return
			screen = 1.4
			if(istype(GLOB.using_map, /datum/map/alpha) && !files.DesignHasReqs(upload_design))
				to_chat(user, "<span class='warning'>Design import refused: its OS13 technology is no longer installed.</span>")
				updateUsrDialog()
				return
			files.AddDesign2Known(upload_design)
			updateUsrDialog()

	else if(href_list["clear_design"]) //Erases data on the design disk.
		if(!d_disk)
			to_chat(user, "<span class='notice'>No design disk is loaded.</span>")
			return TOPIC_REFRESH
		if(d_disk.loc != src || href_list["disk"] != "\ref[d_disk]" || !d_disk.blueprint || href_list["recording"] != "\ref[d_disk.blueprint]")
			to_chat(user, "<span class='warning'>The disk or its recording changed. Review the current contents before clearing it.</span>")
			return TOPIC_REFRESH
		d_disk.blueprint = null
		. = TOPIC_REFRESH

	else if(href_list["eject_design"]) //Eject the design disk.
		if(!d_disk)
			to_chat(user, "<span class='notice'>No design disk is loaded.</span>")
			return TOPIC_REFRESH
		if(QDELETED(d_disk) || d_disk.loc != src || href_list["disk"] != "\ref[d_disk]")
			to_chat(user, "<span class='warning'>The disk changed. Review the current media before ejecting it.</span>")
			return TOPIC_REFRESH
		d_disk.dropInto(loc)
		d_disk = null
		screen = 1.0
		. = TOPIC_REFRESH

	else if(href_list["copy_design"]) //Copy design data from the research holder to the design disk.
		if(!d_disk)
			to_chat(user, "<span class='notice'>Insert a design disk to back up a blueprint.</span>")
			return TOPIC_REFRESH
		if(QDELETED(d_disk) || d_disk.loc != src || href_list["disk"] != "\ref[d_disk]")
			to_chat(user, "<span class='warning'>The disk changed. Review the current media before copying a blueprint.</span>")
			return TOPIC_REFRESH
		if(d_disk.blueprint)
			to_chat(user, "<span class='warning'>The design disk already contains data. Clear it before copying a new blueprint.</span>")
			return TOPIC_REFRESH
		if(!files || QDELETED(files) || href_list["database"] != "\ref[files]")
			to_chat(user, "<span class='warning'>The research database changed. Review the current designs before copying a blueprint.</span>")
			return TOPIC_REFRESH
		var/copied = FALSE
		for(var/datum/design/D in files.known_designs)
			if(href_list["copy_design_ID"] == D.id && href_list["design"] == "\ref[D]")
				d_disk.blueprint = D
				copied = TRUE
				break
		if(!copied)
			to_chat(user, "<span class='warning'>That blueprint is no longer available in the console's research database.</span>")
		screen = 1.4
		. = TOPIC_REFRESH

	else if(href_list["eject_item"]) //Eject the item inside the destructive analyzer.
		if(linked_destroy)
			if(linked_destroy.busy)
				to_chat(usr, "<span class='notice'>The destructive analyzer is busy at the moment.</span>")

			else if(linked_destroy.loaded_item)
				linked_destroy.loaded_item.dropInto(linked_destroy.loc)
				linked_destroy.loaded_item = null
				linked_destroy.icon_state = "d_analyzer"
				screen = 2.1
		. = TOPIC_REFRESH

	else if(href_list["deconstruct"]) //Deconstruct the item in the destructive analyzer and update the research holder.
		if(linked_destroy)
			if(linked_destroy.busy)
				to_chat(usr, "<span class='notice'>The destructive analyzer is busy at the moment.</span>")
			else
				if(alert("Proceeding will destroy loaded item. Continue?", "Destructive analyzer confirmation", "Yes", "No") == "No" || !linked_destroy)
					return
				linked_destroy.busy = 1
				screen = 0.1
				. = TOPIC_REFRESH
				flick("d_analyzer_process", linked_destroy)
				spawn(24)
					if(linked_destroy)
						linked_destroy.busy = 0
						if(!linked_destroy.loaded_item)
							to_chat(usr, "<span class='notice'>The destructive analyzer appears to be empty.</span>")
							screen = 1.0
							return
						if(istype(linked_destroy.loaded_item, /obj/item/device/electronic_assembly))
							add_ic_design(linked_destroy.loaded_item)
						// Technology levels now come from imported research disks.
						// The analyzer still recovers materials and integrated circuit designs.
						if(linked_lathe && linked_destroy.loaded_item.matter) // Also sends salvaged materials to a linked protolathe, if any.
							for(var/t in linked_destroy.loaded_item.matter)
								linked_lathe.store_material(t, linked_destroy.loaded_item.matter[t] * linked_destroy.decon_mod)

						linked_destroy.loaded_item = null
						for(var/obj/I in linked_destroy.contents)
							for(var/mob/M in I.contents)
								M.death()
							if(istype(I,/obj/item/stack/material))//Only deconsturcts one sheet at a time instead of the entire stack
								var/obj/item/stack/material/S = I
								if(S.get_amount() > 1)
									S.use(1)
									linked_destroy.loaded_item = S
								else
									qdel(S)
									linked_destroy.icon_state = "d_analyzer"
							else
								if(!(I in linked_destroy.component_parts))
									qdel(I)
									linked_destroy.icon_state = "d_analyzer"

						use_power_oneoff(linked_destroy.active_power_usage)
						screen = 1.0
						attack_hand(user)
		. = TOPIC_REFRESH

	else if(href_list["lock"]) //Lock the console from use by anyone without tox access.
		if(allowed(usr))
			screen = text2num(href_list["lock"])
		else
			to_chat(usr, "Unauthorized Access.")
		. = TOPIC_REFRESH

	else if(href_list["sync"] || href_list["togglesync"])
		to_chat(user, "<span class='notice'>Research is stored locally. Use technology and design disks to transfer or back up data.</span>")
		screen = 1.6
		. = TOPIC_REFRESH

	else if(href_list["reclaim"])
		if(!linked_lathe || QDELETED(linked_lathe) || href_list["replicator"] != "\ref[linked_lathe]")
			to_chat(user, "<span class='warning'>The linked replicator changed. Review the current platform before reclaiming an item.</span>")
		else
			var/obj/item/target = locate(href_list["reclaim"]) in get_turf(linked_lathe)
			if(!linked_lathe.reclaim(target))
				to_chat(user, "<span class='notice'>The replicator cannot reclaim that item right now. Check that it is on the platform, the machine has power, and a matching storage compartment has room.</span>")
		. = TOPIC_REFRESH

	else if(href_list["build"]) //Causes the Replicator to build something.
		if(!linked_lathe || QDELETED(linked_lathe) || href_list["replicator"] != "\ref[linked_lathe]" || !files || QDELETED(files) || href_list["database"] != "\ref[files]")
			to_chat(user, "<span class='warning'>The linked replicator or research database changed. Review the current designs before requesting production.</span>")
		else
			var/datum/design/being_built = null
			for(var/datum/design/D in files.known_designs)
				if(D.id == href_list["build"] && href_list["design"] == "\ref[D]")
					being_built = D
					break
			if(!being_built || !linked_lathe.addToQueue(being_built))
				to_chat(user, "<span class='warning'>That design is not available for production on the replicator.</span>")

		screen = 3.1
		. = TOPIC_REFRESH

	else if(href_list["imprint"]) //Causes the Circuit Imprinter to build something.
		if(linked_imprinter)
			var/datum/design/being_built = null
			for(var/datum/design/D in files.known_designs)
				if(D.id == href_list["imprint"])
					being_built = D
					break
			if(being_built)
				if(!linked_imprinter.addToQueue(being_built))
					to_chat(user, "<span class='warning'>That blueprint is not available for production on the circuit imprinter.</span>")
		screen = 4.1
		. = TOPIC_REFRESH

	else if(href_list["disposeI"] && linked_imprinter)  //Causes the circuit imprinter to dispose of a single reagent (all of it)
		var/datum/reagent/R = locate(href_list["disposeI"]) in linked_imprinter.reagents.reagent_list
		if(R)
			linked_imprinter.reagents.del_reagent(href_list["dispose"])
		. = TOPIC_REFRESH

	else if(href_list["disposeallI"] && linked_imprinter) //Causes the circuit imprinter to dispose of all it's reagents.
		linked_imprinter.reagents.clear_reagents()
		. = TOPIC_REFRESH

	else if(href_list["removeI"] && linked_lathe)
		linked_imprinter.removeFromQueue(text2num(href_list["removeI"]))
		. = TOPIC_REFRESH

	else if(href_list["disposeP"] || href_list["disposeallP"])
		if(QDELETED(linked_lathe) || !linked_lathe.reagents || QDELETED(linked_lathe.reagents) || href_list["replicator"] != "\ref[linked_lathe]" || href_list["chemical_holder"] != "\ref[linked_lathe.reagents]")
			to_chat(user, "<span class='warning'>The replicator or its chemical storage changed. Review the current storage before purging chemicals.</span>")
		else if(href_list["disposeP"])
			var/datum/reagent/R = locate(href_list["disposeP"]) in linked_lathe.reagents.reagent_list
			if(QDELETED(R))
				to_chat(user, "<span class='warning'>That chemical is no longer stored. Review the current contents before purging.</span>")
			else
				linked_lathe.reagents.del_reagent(R.type)
		else
			linked_lathe.reagents.clear_reagents()
		. = TOPIC_REFRESH

	else if(href_list["removeP"] && linked_lathe)
		if(href_list["queue_machine"] != "\ref[linked_lathe]" || !href_list["queue_revision"] || text2num(href_list["queue_revision"]) != linked_lathe.queue_revision)
			to_chat(user, "<span class='notice'>The replicator queue changed. Review the refreshed queue before removing a job.</span>")
		else if(!linked_lathe.removeFromQueue(text2num(href_list["removeP"])))
			to_chat(user, "<span class='notice'>That queue entry is no longer available. Refresh the queue before removing another job.</span>")
		. = TOPIC_REFRESH

	else if(href_list["lathe_ejectsheet"] && linked_lathe) //Causes the protolathe to eject a sheet of material
		linked_lathe.eject(href_list["lathe_ejectsheet"], text2num(href_list["amount"]))
		. = TOPIC_REFRESH

	else if(href_list["imprinter_ejectsheet"] && linked_imprinter) //Causes the protolathe to eject a sheet of material
		linked_imprinter.eject(href_list["imprinter_ejectsheet"], text2num(href_list["amount"]))
		. = TOPIC_REFRESH

	else if(href_list["find_device"]) //Refresh device links, including the closest available replicator.
		screen = 0.0
		. = TOPIC_HANDLED
		spawn(10)
			SyncRDevices()
			screen = 1.7
			attack_hand(user)

	else if(href_list["disconnect"]) //The R&D console disconnects with a specific device.
		switch(href_list["disconnect"])
			if("destroy")
				linked_destroy.linked_console = null
				linked_destroy = null
			if("lathe")
				linked_lathe.linked_console = null
				linked_lathe = null
			if("imprinter")
				linked_imprinter.linked_console = null
				linked_imprinter = null
		. = TOPIC_REFRESH

	else if(href_list["reset"]) //Reset the R&D console's database.
		var/datum/research/reset_files = files
		var/choice = alert(user, "Reset this console's local research? There is no server backup. Export technology and designs to disks first.", "R&D Console Database Reset", "Continue", "Cancel")
		. = TOPIC_HANDLED
		if(choice == "Continue")
			if(QDELETED(src) || QDELETED(user))
				return TOPIC_NOACTION
			if(files != reset_files || QDELETED(reset_files))
				to_chat(user, "<span class='warning'>Reset cancelled: the research database changed during confirmation. Review the current data before resetting it.</span>")
				return TOPIC_REFRESH
			if((stat & (BROKEN|NOPOWER)) || !powered() || (!allowed(user) && !emagged))
				to_chat(user, "<span class='warning'>Reset cancelled: check console power and research access.</span>")
				return TOPIC_REFRESH
			screen = 0.0
			qdel(files)
			files = new /datum/research(src)
			spawn(20)
				if(!QDELETED(src) && screen == 0.0)
					screen = 1.6
					updateUsrDialog()

	else if (href_list["print"]) //Print research information
		var/datum/research/print_files = files
		var/is_detailed = (text2num(href_list["print"]) == 2)
		screen = 0.5
		. = TOPIC_HANDLED
		spawn(20)
			if(QDELETED(src))
				return
			if(files != print_files || QDELETED(print_files) || (stat & (BROKEN|NOPOWER)) || !powered())
				to_chat(user, "<span class='warning'>Research report cancelled: the database changed or the console lost power.</span>")
				if(screen == 0.5)
					screen = (is_detailed ? 5.0 : 1.1)
				updateUsrDialog()
				return
			var/obj/item/paper/PR = new/obj/item/paper
			PR.name = "fabricator report"
			PR.info = "<center><b>[station_name()] Fabricator Laboratory</b>"
			var/title_str = is_detailed ? "Detailed" : ""
			PR.info += "<h2>[title_str] Fabricator Status Report</h2>"
			PR.info += "<i>report prepared at [stationtime2text()] local time</i></center><br>"
			if(is_detailed)
				PR.info += GetResearchListInfo()
			else
				PR.info += GetResearchLevelsInfo()
			PR.info_links = PR.info
			PR.icon_state = "paper_words"
			PR.dropInto(loc)
			spawn(10)
				if(!QDELETED(src) && screen == 0.5)
					screen = (is_detailed ? 5.0 : 1.1)
					updateUsrDialog()

	if(. == TOPIC_REFRESH)
		attack_hand(user)

/obj/machinery/computer/rdconsole/proc/GetResearchLevelsInfo()
	var/dat
	dat += "<UL>"
	for(var/datum/tech/T in files.known_tech)
		if(T.level < 1)
			continue
		dat += "<LI>"
		dat += "[T.name]"
		dat += "<UL>"
		dat +=  "<LI>[istype(T, /datum/tech/os13) ? "Tier" : "Level"]: [T.display_level()]"
		dat +=  "<LI>Summary: [T.desc]"
		dat += "</UL>"
	return dat

/obj/machinery/computer/rdconsole/proc/GetResearchListInfo()
	var/dat
	dat += "<UL>"
	for(var/datum/design/D in files.known_designs)
		if(D.build_path)
			dat += "<LI><B>[D.name]</B>: [D.desc]"
	dat += "</UL>"
	return dat

/obj/machinery/computer/rdconsole/attack_hand(mob/user as mob)
	if(stat & (BROKEN|NOPOWER))
		return

	user.set_machine(src)
	var/dat = ""
	files.RefreshResearch()
	switch(screen) //A quick check to make sure you get the right screen when a device is disconnected.
		if(1.2, 1.3)
			if(!t_disk || QDELETED(t_disk) || t_disk.loc != src)
				screen = 1.0
		if(1.4, 1.5)
			if(!d_disk || QDELETED(d_disk) || d_disk.loc != src)
				screen = 1.0
		if(2 to 2.9)
			if(linked_destroy == null)
				screen = 2.0
			else if(linked_destroy.loaded_item == null)
				screen = 2.1
			else
				screen = 2.2
		if(3 to 3.9)
			if(linked_lathe == null)
				screen = 3.0
		if(4 to 4.9)
			if(linked_imprinter == null)
				screen = 4.0

	switch(screen)

		//////////////////////R&D CONSOLE SCREENS//////////////////
		if(0.0)
			dat += "Updating Database..."

		if(0.1)
			dat += "Processing and Updating Database..."

		if(0.2)
			dat += "SYSTEM LOCKED<BR><BR>"
			dat += "<A href='?src=\ref[src];lock=1.6'>Unlock</A>"

		if(0.3)
			dat += "Constructing Prototype. Please Wait..."

		if(0.4)
			dat += "Imprinting Circuit. Please Wait..."

		if(0.5)
			dat += "Printing. Please Wait..."

		if(1.0) //Main Menu
			dat += "Main Menu:<BR><BR>"
			dat += "Loaded disk: "
			dat += (t_disk || d_disk) ? html_encode(t_disk ? t_disk.name : d_disk.name) : "none"
			dat += "<HR><UL>"
			dat += "<LI><A href='?src=\ref[src];menu=1.1'>Current Fabricator Learning Matrix Status</A>"
			dat += "<LI><A href='?src=\ref[src];menu=5.0'>View Available Designs</A>"
			if(t_disk)
				dat += "<LI><A href='?src=\ref[src];menu=1.2'>Disk Operations</A>"
			else if(d_disk)
				dat += "<LI><A href='?src=\ref[src];menu=1.4'>Disk Operations</A>"
			else
				dat += "<LI>Disk Operations"
			if(linked_destroy)
				dat += "<LI><A href='?src=\ref[src];menu=2.2'>Destructive Analyzer Menu</A>"
			dat += "<LI><A href='?src=\ref[src];menu=3.1'>Produce</A>"
			if(linked_imprinter)
				dat += "<LI><A href='?src=\ref[src];menu=4.1'>Circuit Construction Menu</A>"
			dat += "<LI><A href='?src=\ref[src];menu=1.6'>Settings</A>"
			dat += "</UL>"

		if(1.1) //Research viewer
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];print=1'>Print This Page</A><HR>"
			dat += "Fabricator Learning Matrix Proficiency Levels:<BR><BR>"
			dat += GetResearchLevelsInfo()
			dat += "</UL>"

		if(1.2) //Technology Disk Menu

			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "Disk Contents: (Technology Data Disk)<BR><BR>"
			dat += "Disk: [html_encode(t_disk.name)]<BR>"
			if(istype(GLOB.using_map, /datum/map/alpha))
				dat += "<B>Technologies:</B><BR>"
			if(t_disk.stored == null)
				dat += "The disk has no data stored on it.<HR>"
				dat += "Operations: "
				dat += "<A href='?src=\ref[src];menu=1.3'>Load Tech to Disk</A> || "
			else
				dat += "Name: [html_encode(t_disk.stored.name)]<BR>"
				dat += "[istype(t_disk.stored, /datum/tech/os13) ? "Tier" : "Level"]: [t_disk.stored.display_level()]<BR>"
				dat += "Description: [html_encode(t_disk.stored.desc)]<HR>"
				dat += "Operations: "
				dat += "<A href='?src=\ref[src];updt_tech=1;disk=\ref[t_disk];recording=\ref[t_disk.stored]'>Upload to Database</A> || "
				dat += "<A href='?src=\ref[src];clear_tech=1;disk=\ref[t_disk];recording=\ref[t_disk.stored]'>Clear Disk</A> || "
			dat += "<A href='?src=\ref[src];eject_tech=1;disk=\ref[t_disk]'>Eject Disk</A>"

		if(1.3) //Technology Disk submenu
			dat += "<BR><A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=1.2'>Return to Disk Operations</A><HR>"
			dat += "Load Technology to Disk:<BR><BR>"
			dat += "Disk: [html_encode(t_disk.name)]<BR>"
			dat += "<UL>"
			for(var/datum/tech/T in files.known_tech)
				if(istype(GLOB.using_map, /datum/map/alpha) && T.level <= 0)
					continue
				dat += "<LI>[html_encode(T.name)] ([istype(T, /datum/tech/os13) ? "tier" : "level"] [T.display_level()]) "
				dat += "\[<A href='?src=\ref[src];copy_tech=1;copy_tech_ID=[T.id];disk=\ref[t_disk];database=\ref[files];technology=\ref[T];level=[T.level]'>copy to disk</A>\]"
			dat += "</UL>"

		if(1.4) //Design Disk menu.
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "Disk: [html_encode(d_disk.name)]<BR>"
			if(d_disk.blueprint == null)
				dat += "The disk has no data stored on it.<HR>"
				dat += "Operations: "
				dat += "<A href='?src=\ref[src];menu=1.5'>Load Design to Disk</A> || "
			else
				dat += "Name: [html_encode(d_disk.blueprint.name)]<BR>"
				if(d_disk.blueprint.build_type & PROTOLATHE)
					dat += "Fabricator Type: Replicator<BR>"
				if(d_disk.blueprint.build_type & IMPRINTER)
					dat += "Fabricator Type: Circuit Imprinter<BR>"
				dat += "Base Required Materials (before machine efficiency):<BR>"
				for(var/M in d_disk.blueprint.materials)
					var/material_id = copytext(M, 1, 2) == "$" ? copytext(M, 2) : M
					var/material_label = GLOB.replicator_material_names[material_id]
					if(!material_label)
						material_label = CallMaterialName(material_id)
					dat += "* [html_encode(material_label)] x [d_disk.blueprint.materials[M]] material units<BR>"
				if(length(d_disk.blueprint.chemicals))
					dat += "Base Required Chemicals (before machine efficiency):<BR>"
					for(var/chemical in d_disk.blueprint.chemicals)
						dat += "* [html_encode(CallReagentName(chemical))] x [d_disk.blueprint.chemicals[chemical]] reagent units<BR>"
				dat += "<HR>Operations: "
				dat += "<A href='?src=\ref[src];updt_design=1;disk=\ref[d_disk];recording=\ref[d_disk.blueprint]'>Upload to Database</A> || "
				dat += "<A href='?src=\ref[src];clear_design=1;disk=\ref[d_disk];recording=\ref[d_disk.blueprint]'>Clear Disk</A> || "
			dat += "<A href='?src=\ref[src];eject_design=1;disk=\ref[d_disk]'>Eject Disk</A>"

		if(1.5) //Technology disk submenu
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=1.4'>Return to Disk Operations</A><HR>"
			dat += "Load Design to Disk:<BR><BR>"
			dat += "Disk: [html_encode(d_disk.name)]<BR>"
			dat += "<UL>"
			for(var/datum/design/D in files.known_designs)
				if(D.build_path)
					dat += "<LI>[html_encode(D.name)] "
					dat += "<A href='?src=\ref[src];copy_design=1;copy_design_ID=[D.id];disk=\ref[d_disk];database=\ref[files];design=\ref[D]'>\[copy to disk\]</A>"
			dat += "</UL>"

		if(1.6) //R&D console settings
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "R&D Console Setting:<HR>"
			dat += "Technology and designs are stored locally on this console. No research server is required.<BR>"
			dat += "Back up or transfer research using technology and design disks. Resetting or dismantling this console loses its local data.<HR>"
			dat += "<UL>"
			dat += "<LI><A href='?src=\ref[src];menu=1.7'>Device Linkage Menu</A><BR>"
			dat += "<LI><A href='?src=\ref[src];lock=0.2'>Lock Console</A><BR>"
			dat += "<LI><A href='?src=\ref[src];reset=1'>Reset R&D Database</A><BR>"
			dat += "<UL>"

		if(1.7) //R&D device linkage
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=1.6'>Settings Menu</A><HR>"
			dat += "R&D Console Device Linkage Menu:<BR><BR>"
			dat += "<A href='?src=\ref[src];find_device=1'>Re-sync Devices</A><HR>"
			dat += "Linked Devices:"
			dat += "<UL>"
			if(linked_destroy)
				dat += "<LI>Destructive Analyzer <A href='?src=\ref[src];disconnect=destroy'>(Disconnect)</A>"
			else
				dat += "<LI>(No Destructive Analyzer Linked)"
			if(linked_lathe)
				dat += "<LI>Replicator <A href='?src=\ref[src];disconnect=lathe'>(Disconnect)</A>"
			else
				dat += "<LI>(No Replicator Linked)"
			if(linked_imprinter)
				dat += "<LI>Circuit Imprinter <A href='?src=\ref[src];disconnect=imprinter'>(Disconnect)</A>"
			else
				dat += "<LI>(No Circuit Imprinter Linked)"
			dat += "</UL>"

		////////////////////DESTRUCTIVE ANALYZER SCREENS////////////////////////////
		if(2.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "NO DESTRUCTIVE ANALYZER LINKED TO CONSOLE<BR><BR>"

		if(2.1)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "No Item Loaded. Standing-by...<BR><HR>"

		if(2.2)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "Deconstruction Menu<HR>"
			dat += "Name: [linked_destroy.loaded_item.name]<BR>"
			if(istype(linked_destroy.loaded_item, /obj/item/device/electronic_assembly))
				dat += "Assembly Detected. Prepared for blueprint download."
				dat += "Warning: Assemblies manafactured this way will not have removable circuits."
			else
				dat += "Salvage only. New technology levels must be imported from research disks.<BR>Item composition:"
				dat += "<UL>"
				for(var/T in linked_destroy.loaded_item.origin_tech)
					dat += "<LI>[CallTechName(T)] [linked_destroy.loaded_item.origin_tech[T]]"
					for(var/datum/tech/F in files.known_tech)
						if(F.name == CallTechName(T))
							dat += " (Current: [F.level])"
							break
				dat += "</UL>"
			dat += "<HR><A href='?src=\ref[src];deconstruct=1'>Deconstruct Item</A> || "
			dat += "<A href='?src=\ref[src];eject_item=1'>Eject Item</A> || "

		/////////////////////PROTOLATHE SCREENS/////////////////////////
		if(3.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "NO REPLICATOR LINKED TO CONSOLE<BR><BR>"

		if(3.1)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.4'>View Queue</A> || "
			dat += "<A href='?src=\ref[src];menu=3.2'>Material Storage</A> || "
			dat += "<A href='?src=\ref[src];menu=3.3'>Chemical Storage</A><HR>"
			dat += "Produce:<BR><BR>"
			if(linked_lathe.producing_design)
				dat += "<B>Producing [html_encode(linked_lathe.producing_design.name)]...</B><BR>"
			dat += "Production takes three seconds. The flash and radiation begin immediately.<BR>"
			dat += "<B>Radiation hazard:</B> Every conversion leaves a lethal radiation field within three tiles, with weaker radiation beyond. It fades over one minute. Use shielding and remote controls.<BR>"
			dat += "<B>Reclamation:</B> Place an item or material sheets on the platform, then select it below. <A href='?src=\ref[src];menu=3.1'>Refresh</A><BR>"
			for(var/obj/item/item in get_turf(linked_lathe))
				if(linked_lathe.can_reclaim(item))
					dat += "<A href='?src=\ref[src];reclaim=\ref[item];replicator=\ref[linked_lathe]'>Reclaim [html_encode(item.name)] (destroys item)</A><BR>"
			dat += "<B>Shared storage:</B> [round(linked_lathe.TotalMaterials() / SHEET_MATERIAL_AMOUNT, 0.01)] sheets. Only unlocked compartments can supply production.<BR>"
			for(var/material_id in GLOB.replicator_material_names)
				dat += "[capitalize(linked_lathe.material_name(material_id))]: [round(linked_lathe.material_amount(material_id, TRUE) / SHEET_MATERIAL_AMOUNT, 0.01)] sheets available<BR>"
			dat += "<B>Chemical Volume:</B> [linked_lathe.reagents.total_volume] (MAX: [linked_lathe.reagents.maximum_volume])<HR>"
			dat += "<UL>"
			for(var/datum/design/D in files.known_designs)
				if(!D.build_path || !(D.build_type & PROTOLATHE))
					continue
				var/temp_dat
				for(var/M in D.materials)
					temp_dat += ", [D.materials[M] * linked_lathe.mat_efficiency] [capitalize(linked_lathe.material_name(M))]"
				for(var/T in D.chemicals)
					temp_dat += ", [D.chemicals[T]*linked_lathe.mat_efficiency] [CallReagentName(T)]"
				if(temp_dat)
					temp_dat = " \[[copytext(temp_dat, 3)]\]"
				if(linked_lathe.canBuild(D))
					dat += "<LI><B><A href='?src=\ref[src];build=[D.id];replicator=\ref[linked_lathe];database=\ref[files];design=\ref[D]'>[D.name]</A></B>[temp_dat]"
				else
					dat += "<LI><B>[D.name]</B>[temp_dat]"
			dat += "</UL>"

		if(3.2) //Replicator Material Storage Sub-menu
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.1'>Produce</A><HR>"
			dat += "Material Storage<BR><HR>"
			dat += "Materials cannot be withdrawn. Science access is required to lock or unlock each compartment at its controls.<BR>"
			if(!length(GLOB.replicator_storages))
				dat += "No replicator storage structures found.<BR>"
			var/storage_number = 0
			for(var/obj/machinery/replicator_storage/storage in GLOB.replicator_storages)
				storage_number++
				var/area/storage_area = get_area(storage)
				dat += "<B>Storage [storage_number] ([html_encode(storage_area ? storage_area.name : "Unknown location")])</B><UL>"
				for(var/material_id in GLOB.replicator_material_names)
					var/obj/machinery/replicator_storage_compartment/C = storage.compartments[material_id]
					if(QDELETED(C) || !C.connected())
						dat += "<LI>[capitalize(linked_lathe.material_name(material_id))]: unavailable"
					else
						dat += "<LI>[capitalize(C.material_label)]: [round(C.stored_material / SHEET_MATERIAL_AMOUNT, 0.01)] / [C.capacity / SHEET_MATERIAL_AMOUNT] sheets — [C.locked ? "Locked" : "Unlocked"]"
				dat += "</UL>"

		if(3.3) //Replicator Chemical Storage Submenu
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.1'>Produce</A><HR>"
			dat += "Chemical Storage<BR><HR>"
			for(var/datum/reagent/R in linked_lathe.reagents.reagent_list)
				dat += "Name: [R.name] | Units: [R.volume] "
				dat += "<A href='?src=\ref[src];disposeP=\ref[R];replicator=\ref[linked_lathe];chemical_holder=\ref[linked_lathe.reagents]'>(Purge)</A><BR>"
			if(length(linked_lathe.reagents.reagent_list))
				dat += "<A href='?src=\ref[src];disposeallP=1;replicator=\ref[linked_lathe];chemical_holder=\ref[linked_lathe.reagents]'><U>Dispose All Chemicals in Storage</U></A><BR>"

		if(3.4) // Replicator queue
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=3.1'>Produce</A><HR>"
			dat += "Queue<BR><HR>"
			dat += "<A href='?src=\ref[src];menu=3.4'>Refresh queue</A><BR>"
			if(linked_lathe.producing_design)
				dat += "<B>Producing: [html_encode(linked_lathe.producing_design.name)]</B><BR>"
			else if(length(linked_lathe.queue))
				if(linked_lathe.stat || !linked_lathe.powered())
					dat += "<B>Production paused: Replicator offline.</B><BR>"
				else if(linked_lathe.panel_open)
					dat += "<B>Production paused: close the Replicator's maintenance panel.</B><BR>"
				else if(linked_lathe.busy || linked_lathe.converting)
					dat += "<B>Production paused: Replicator busy.</B><BR>"
				else
					var/datum/design/next_design = linked_lathe.queue[1]
					if(!linked_lathe.supports_design(next_design))
						dat += "<B>Unavailable blueprint: this job will be discarded on the next production cycle.</B><BR>"
					else if(istype(GLOB.using_map, /datum/map/alpha) && !files.DesignHasReqs(next_design))
						dat += "<B>Production paused: install the matching OS13 technology on this linked console.</B><BR>"
					else
						var/missing_materials = linked_lathe.getLackingMaterials(next_design)
						if(missing_materials)
							dat += "<B>Insufficient resources for [html_encode(next_design.name)]: [html_encode(missing_materials)].</B><BR>"
							dat += "Only unlocked, connected storage supplies production.<BR>"
						else
							dat += "Next job is awaiting the production cycle.<BR>"
			if(!linked_lathe.queue.len)
				dat += "No waiting jobs."
			else
				for(var/index = 1, index <= length(linked_lathe.queue), index++)
					var/datum/design/D = linked_lathe.queue[index]
					var/design_label = linked_lathe.supports_design(D) ? html_encode(D.name) : "Unavailable blueprint"
					dat += "[index]: [design_label] <A href='?src=\ref[src];removeP=[index];queue_machine=\ref[linked_lathe];queue_revision=[linked_lathe.queue_revision]'>(Remove)</A><BR>"

		///////////////////CIRCUIT IMPRINTER SCREENS////////////////////
		if(4.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A><HR>"
			dat += "NO CIRCUIT IMPRINTER LINKED TO CONSOLE<BR><BR>"

		if(4.1)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.4'>View Queue</A> || "
			dat += "<A href='?src=\ref[src];menu=4.3'>Material Storage</A> || "
			dat += "<A href='?src=\ref[src];menu=4.2'>Chemical Storage</A><HR>"
			dat += "Circuit Imprinter Menu:<BR><BR>"
			dat += "Material Amount: [linked_imprinter.TotalMaterials()] cm<sup>3</sup><BR>"
			dat += "Chemical Volume: [linked_imprinter.reagents.total_volume]<HR>"
			dat += "<UL>"
			for(var/datum/design/D in files.known_designs)
				if(!D.build_path || !(D.build_type & IMPRINTER))
					continue
				var/temp_dat
				for(var/M in D.materials)
					temp_dat += ", [D.materials[M]*linked_imprinter.mat_efficiency] [CallMaterialName(M)]"
				for(var/T in D.chemicals)
					temp_dat += ", [D.chemicals[T]*linked_imprinter.mat_efficiency] [CallReagentName(T)]"
				if(temp_dat)
					temp_dat = " \[[copytext(temp_dat,3)]\]"
				if(linked_imprinter.canBuild(D))
					dat += "<LI><B><A href='?src=\ref[src];imprint=[D.id]'>[D.name]</A></B>[temp_dat]"
				else
					dat += "<LI><B>[D.name]</B>[temp_dat]"
			dat += "</UL>"

		if(4.2)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.1'>Imprinter Menu</A><HR>"
			dat += "Chemical Storage<BR><HR>"
			for(var/datum/reagent/R in linked_imprinter.reagents.reagent_list)
				dat += "Name: [R.name] | Units: [R.volume] "
				dat += "<A href='?src=\ref[src];disposeI=\ref[R]'>(Purge)</A><BR>"
				dat += "<A href='?src=\ref[src];disposeallI=1'><U>Disposal All Chemicals in Storage</U></A><BR>"

		if(4.3)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.1'>Circuit Imprinter Menu</A><HR>"
			dat += "Material Storage<BR><HR>"
			dat += "<UL>"
			for(var/M in linked_imprinter.materials)
				var/amount = linked_imprinter.materials[M]
				dat += "<LI><B>[capitalize(M)]</B>: [amount] cm<sup>3</sup>"
				if(amount >= SHEET_MATERIAL_AMOUNT)
					dat += " || Eject: "
					for (var/C in list(1, 3, 5, 10, 15, 20, 25, 30, 40))
						if(amount < C * SHEET_MATERIAL_AMOUNT)
							break
						dat += "[C > 1 ? ", " : ""]<A href='?src=\ref[src];imprinter_ejectsheet=[M];amount=[C]'>[C]</A> "

					dat += " or <A href='?src=\ref[src];imprinter_ejectsheet=[M];amount=50'>max</A> sheets"
				dat += ""
			dat += "</UL>"

		if(4.4)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];menu=4.1'>Circuit Imprinter Menu</A><HR>"
			dat += "Queue<BR><HR>"
			if(linked_imprinter.queue.len == 0)
				dat += "Empty"
			else
				var/tmp = 1
				for(var/datum/design/D in linked_imprinter.queue)
					if(tmp == 1)
						dat += "<B>1: [D.name]</B><BR>"
					else
						dat += "[tmp]: [D.name] <A href='?src=\ref[src];removeI=[tmp]'>(Remove)</A><BR>"
					++tmp

		///////////////////Research Information Browser////////////////////
		if(5.0)
			dat += "<A href='?src=\ref[src];menu=1.0'>Main Menu</A> || "
			dat += "<A href='?src=\ref[src];print=2'>Print This Page</A><HR>"
			dat += "List of Available Designs:"
			dat += GetResearchListInfo()

	ui_browse_styled(user, "Replicator Console", dat, "window=rdconsole;size=850x620;can_close=0;can_resize=0;border=0;titlebar=0", src)
	onclose(user, "rdconsole")

/obj/machinery/computer/rdconsole/robotics
	name = "robotics fabrication console"
	id = 2
	req_access = list(access_robotics)

/obj/machinery/computer/rdconsole/core
	id = 1
