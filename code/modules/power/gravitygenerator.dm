// It.. uses a lot of power.  Everything under power is engineering stuff, at least.

/obj/machinery/computer/gravity_control_computer
	name = "Gravity Generator Control"
	desc = "A computer to control a local gravity generator.  Qualified personnel only."
	icon = 'icons/obj/computer.dmi'
	icon_state = "airtunnel0e"
	anchored = 1
	density = 1
	var/obj/machinery/gravity_generator/gravity_generator

/obj/machinery/gravity_generator
	name = "Gravitational Generator"
	desc = "A device which produces a gravaton field when set up."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "TheSingGen"
	anchored = 1
	density = 1
	idle_power_usage = 200
	active_power_usage = 1000
	var/on = 1
	var/list/localareas = list()
	var/effectiverange = 25

	// Borrows code from cloning computer
/obj/machinery/computer/gravity_control_computer/Initialize()
	. = ..()
	updatemodules()

/obj/machinery/gravity_generator/Initialize()
	. = ..()
	locatelocalareas()

/obj/machinery/computer/gravity_control_computer/proc/updatemodules()
	for(dir in list(NORTH,EAST,SOUTH,WEST))
		gravity_generator = locate(/obj/machinery/gravity_generator/, get_step(src, dir))
		if (gravity_generator)
			return

/obj/machinery/gravity_generator/proc/locatelocalareas()
	for(var/area/A in range(src,effectiverange))
		if(istype(A,/area/space))
			continue // No (de)gravitizing space.
		localareas |= A

/obj/machinery/computer/gravity_control_computer/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/gravity_control_computer/attack_hand(mob/user as mob)
	user.set_machine(src)
	add_fingerprint(user)

	if(stat & (BROKEN|NOPOWER))
		return

	updatemodules()
	var/body = ""
	// Toolbar with a Close control
	body += "<div style='display:flex;align-items:center;justify-content:flex-end;margin-bottom:6px;'>"
	body += "<a href='?src=\ref[src];ui_close=1'>Close</a>"
	body += "</div>"

	body += "<h3>Generator Control System</h3>"
	if(gravity_generator)
		if(gravity_generator.on)
			body += "<div><tt><span style='color:#4caf50'>Gravity Status: ON</span></tt></div>"
		else
			body += "<div><tt><span style='color:#e57373'>Gravity Status: OFF</span></tt></div>"

		body += "<br><tt>Currently Supplying Gravitons To:</tt><br>"

		for(var/area/A in gravity_generator.localareas)
			if(A.has_gravity && gravity_generator.on)
				body += "<tt><span style='color:#4caf50'>[A]</span></tt><br>"
			else if (A.has_gravity)
				body += "<tt><span style='color:#ffca28'>[A]</span></tt><br>"
			else
				body += "<tt><span style='color:#e57373'>[A]</span></tt><br>"

		body += "<br><tt>Maintenance Functions:</tt><br>"
		body += "<a href='?src=\ref[src];gentoggle=1'>" + (gravity_generator.on ? "<span style='color:#e57373'>TURN GRAVITY GENERATOR OFF.</span>" : "<span style='color:#4caf50'>TURN GRAVITY GENERATOR ON.</span>") + "</a>"
	else
		body += "No local gravity generator detected!"

	ui_browse_styled(user, "Gravity Generator Control", body, "window=gravgen;size=400x500;can_close=0;can_resize=0;border=0;titlebar=0")
	// Keep legacy onclose in case other code relies on it, though window itself is borderless
	onclose(user, "gravgen")


/obj/machinery/computer/gravity_control_computer/Topic(href, href_list)
	set background = 1
	if((. = ..()))
		usr << browse(null, "window=air_alarm")
		return

	if(href_list["ui_close"]) {
		usr << browse(null, "window=gravgen")
		usr.unset_machine()
		return
	}

	if(href_list["gentoggle"])
		if(gravity_generator.on)
			gravity_generator.on = 0

			for(var/area/A in gravity_generator.localareas)
				var/obj/machinery/gravity_generator/G
				for(G in SSmachines.machinery)
					if((A in G.localareas) && (G.on))
						break
				if(!G)
					A.gravitychange(0)
		else
			for(var/area/A in gravity_generator.localareas)
				gravity_generator.on = 1
				A.gravitychange(1)

	src.updateUsrDialog()
