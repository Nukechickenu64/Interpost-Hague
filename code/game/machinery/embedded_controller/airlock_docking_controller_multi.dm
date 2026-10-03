//a controller for a docking port with multiple independent airlocks
//this is the master controller, that things will try to dock with.
/obj/machinery/embedded_controller/radio/docking_port_multi
	name = "docking port controller"

	var/child_tags_txt
	var/child_names_txt
	var/list/child_names = list()

	var/datum/computer/file/embedded_program/docking/multi/docking_program

/obj/machinery/embedded_controller/radio/docking_port_multi/New()
	..()
	docking_program = new/datum/computer/file/embedded_program/docking/multi(src)
	program = docking_program

	var/list/names = splittext(child_names_txt, ";")
	var/list/tags = splittext(child_tags_txt, ";")

	if (names.len == tags.len)
		for (var/i = 1; i <= tags.len; i++)
			child_names[tags[i]] = names[i]


/obj/machinery/embedded_controller/radio/docking_port_multi/ui_interact()
	return

/obj/machinery/embedded_controller/radio/docking_port_multi/proc/get_child_controller(child_tag)
	if(!docking_program || !(child_tag in docking_program.children_tags))
		return null
	for(var/obj/machinery/embedded_controller/radio/airlock/docking_port_multi/child in SSmachines.machinery)
		if(!QDELETED(child) && child.id_tag == child_tag && child.master_tag == id_tag && child.frequency == frequency)
			return child
	return null

/obj/machinery/embedded_controller/radio/docking_port_multi/proc/can_select_chamber(mob/user)
	if(!user || !allowed(user))
		if(user)
			to_chat(user, "<span class='warning'>Access denied.</span>")
		return FALSE
	return on && operable() && !user.stat && !user.lying && user.IsAdvancedToolUser() && CanUseTopic(user, GLOB.default_state) == STATUS_INTERACTIVE

/obj/machinery/embedded_controller/radio/docking_port_multi/attack_hand(mob/user)
	if(!can_select_chamber(user) || !docking_program)
		return FALSE
	var/list/choices = list()
	for(var/child_tag in docking_program.children_tags)
		if(!get_child_controller(child_tag))
			continue
		var/child_name = child_names[child_tag] ? child_names[child_tag] : child_tag
		choices += "<span class='feedback'><a href='?src=\ref[src];action=cycle_chamber;child_tag=[url_encode(child_tag)]'>[rhtml_encode(child_name)]</a></span>"
	if(!choices.len)
		to_chat(user, "<span class='warning'>No linked airlock chambers are available.</span>")
		return FALSE
	to_chat(user, "\n<div class='firstdivmood'><div class='compbox'><span class='graytext'>Select an airlock chamber:</span>\n<hr>[jointext(choices, "\n")]</div></div>")
	return TRUE

/obj/machinery/embedded_controller/radio/docking_port_multi/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/embedded_controller/radio/docking_port_multi/Topic(href, href_list)
	if(..())
		return
	if(href_list["action"] != "cycle_chamber" || !can_select_chamber(usr))
		return STATUS_CLOSE
	var/obj/machinery/embedded_controller/radio/airlock/docking_port_multi/child = get_child_controller(href_list["child_tag"])
	if(!child)
		to_chat(usr, "<span class='warning'>That airlock chamber is no longer available.</span>")
		return STATUS_CLOSE
	child.cycle_on_click(usr)
	return TRUE



//a docking port based on an airlock
/obj/machinery/embedded_controller/radio/airlock/docking_port_multi
	name = "docking port controller"
	var/master_tag	//for mapping
	var/datum/computer/file/embedded_program/airlock/multi_docking/airlock_program
	tag_secure = 1

/obj/machinery/embedded_controller/radio/airlock/docking_port_multi/Initialize()
	. = ..()
	airlock_program = new/datum/computer/file/embedded_program/airlock/multi_docking(src)
	program = airlock_program

/obj/machinery/embedded_controller/radio/airlock/docking_port_multi/manual_cycle_enabled()
	return airlock_program && (!airlock_program.docking_enabled || airlock_program.override_enabled)

/*** DEBUG VERBS ***

/datum/computer/file/embedded_program/docking/multi/proc/print_state()
	log_debug("id_tag: [id_tag]")
	log_debug("dock_state: [dock_state]")
	log_debug("control_mode: [control_mode]")
	log_debug("tag_target: [tag_target]")
	log_debug("response_sent: [response_sent]")

/datum/computer/file/embedded_program/docking/multi/post_signal(datum/signal/signal, comm_line)
	log_debug("Program [id_tag] sent a message!")

	print_state()
	log_debug("[id_tag] sent command \"[signal.data["command"]]\" to \"[signal.data["recipient"]]\"")

	..(signal)

/obj/machinery/embedded_controller/radio/docking_port_multi/verb/view_state()
	set category = "Debug"
	set src in view(1)
	src.program:print_state()

/obj/machinery/embedded_controller/radio/docking_port_multi/verb/spoof_signal(var/command as text, var/sender as text)
	set category = "Debug"
	set src in view(1)
	var/datum/signal/signal = new
	signal.data["tag"] = sender
	signal.data["command"] = command
	signal.data["recipient"] = id_tag

	src.program:receive_signal(signal)

/obj/machinery/embedded_controller/radio/docking_port_multi/verb/debug_init_dock(var/target as text)
	set category = "Debug"
	set src in view(1)
	src.program:initiate_docking(target)

/obj/machinery/embedded_controller/radio/docking_port_multi/verb/debug_init_undock()
	set category = "Debug"
	set src in view(1)
	src.program:initiate_undocking()

*/
