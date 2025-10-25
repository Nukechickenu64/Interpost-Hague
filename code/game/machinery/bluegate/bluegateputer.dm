/obj/machinery/computer/bluegate
	name = "testing computer"
	desc = "I fucking hate you."
	var/obj/machinery/bluegate/bluegate

/obj/machinery/computer/testing/Topic(href, href_list, hsrc)
	..()
	if(get_dist(src, usr) > 1)
		return

/obj/machinery/computer/testing/attack_hand(mob/user)
	..()
	if(stat & (BROKEN|NOPOWER))
		return
	to_chat(user, "\n<div class='firstdivmood'><div class='moodbox'><span class='graytext'>The computer's nearly burned out screen shows you the following commands:</span>\n<hr><span class='feedback'><a href='?src=\ref[src];action=printstatus;align='right'>PRINT LATEST COMMUNICATION LOGS</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=checkstationintegrity;align='right'>STATION STATUS</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=announce;align='right'>SEND AN ANNOUNCEMENT</a></span></div></div>")
