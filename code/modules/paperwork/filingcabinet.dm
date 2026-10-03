/* Filing cabinets!
 * Contains:
 *		Filing Cabinets
 *		Security Record Cabinets
 *		Medical Record Cabinets
 */


/*
 * Filing Cabinets
 */
/obj/structure/filingcabinet
	name = "filing cabinet"
	desc = "A large cabinet with drawers."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "filingcabinet"
	density = 1
	anchored = 1
	atom_flags = ATOM_FLAG_CLIMBABLE
	obj_flags = OBJ_FLAG_ANCHORABLE
	var/list/can_hold = list(
		/obj/item/paper,
		/obj/item/folder,
		/obj/item/photo,
		/obj/item/paper_bundle,
		/obj/item/sample,
		/obj/item/card/id,
		/obj/item/disk/nuclear)


/obj/structure/filingcabinet/chestdrawer
	name = "chest drawer"
	icon_state = "chestdrawer"

/obj/structure/filingcabinet/wallcabinet
	name = "wall-mounted filing cabinet"
	desc = "A filing cabinet installed into a cavity in the wall to save space. Wow!"
	icon_state = "wallcabinet"
	density = 0
	obj_flags = 0


/obj/structure/filingcabinet/filingcabinet	//not changing the path to avoid unecessary map issues, but please don't name stuff like this in the future -Pete
	icon_state = "tallcabinet"


/obj/structure/filingcabinet/id_records
	name = "identification records cabinet"
	desc = "A tall cabinet where spare crew identification cards are filed away."
	icon_state = "tallcabinet"
	can_hold = list(/obj/item/card/id)

/obj/structure/filingcabinet/id_records/Initialize()
	. = ..()
	GLOB.id_record_cabinets += src

/obj/structure/filingcabinet/id_records/Destroy()
	GLOB.id_record_cabinets -= src
	return ..()

// Files a spare job ID for H, usually in the HoP's office but occasionally somewhere else on the map.
/proc/file_crew_id(mob/living/carbon/human/H)
	if(!istype(H) || !H.mind || !length(GLOB.id_record_cabinets))
		return
	var/datum/job/job = job_master.GetJob(H.mind.assigned_role)
	if(!job)
		return
	var/alt_title = H.mind.role_alt_title
	var/decl/hierarchy/outfit/outfit = job.get_outfit(H, alt_title, H.char_branch, H.char_rank)
	if(!outfit || !outfit.id_type)
		return

	var/list/hop_cabinets = list()
	var/list/captain_cabinets = list()
	for(var/obj/structure/filingcabinet/id_records/C in GLOB.id_record_cabinets)
		var/area/A = get_area(C)
		if(istype(A, /area/crew_quarters/heads/hop))
			hop_cabinets += C
		else if(istype(A, /area/crew_quarters/captain))
			captain_cabinets += C
	var/obj/structure/filingcabinet/id_records/cabinet
	if(istype(job, /datum/job/captain) && captain_cabinets.len)
		cabinet = pick(captain_cabinets)
	else
		cabinet = pick((hop_cabinets.len && prob(98)) ? hop_cabinets : GLOB.id_record_cabinets)

	var/obj/item/card/id/W = new outfit.id_type(cabinet)
	if(outfit.id_desc)
		W.desc = outfit.id_desc
	W.rank = job.title
	W.assignment = alt_title || job.title
	H.set_id_info(W)
	// Unnamed so the owner has to prove it's theirs via photo, prints and DNA.
	W.registered_name = null
	W.update_name()
	return W


/obj/structure/filingcabinet/Initialize()
	for(var/obj/item/I in loc)
		if(istype(I, /obj/item/paper) || istype(I, /obj/item/folder) || istype(I, /obj/item/photo) || istype(I, /obj/item/paper_bundle))
			I.loc = src
	. = ..()

/obj/structure/filingcabinet/attackby(obj/item/P as obj, mob/user as mob)
	if(is_type_in_list(P, can_hold))
		add_fingerprint(user)
		to_chat(user, "<span class='notice'>You put [P] in [src].</span>")
		user.drop_item()
		P.loc = src
		icon_state = "[initial(icon_state)]-open"
		sleep(5)
		icon_state = initial(icon_state)
		updateUsrDialog()
	else
		..()
	return


/obj/structure/filingcabinet/attack_hand(mob/user as mob)
	if(contents.len <= 0)
		to_chat(user, "<span class='notice'>\The [src] is empty.</span>")
		return

	user.set_machine(src)
	var/dat = "<center><table>"
	for(var/obj/item/P in src)
		dat += "<tr><td><a href='?src=\ref[src];retrieve=\ref[P]'>[P.name]</a></td></tr>"
	dat += "</table></center>"
	var/page = ui_build_styled_html(name, dat)
	user << browse(page, "window=filingcabinet;size=350x300")

	return

/obj/structure/filingcabinet/attack_tk(mob/user)
	if(anchored)
		attack_self_tk(user)
	else
		..()

/obj/structure/filingcabinet/attack_self_tk(mob/user)
	if(contents.len)
		if(prob(40 + contents.len * 5))
			var/obj/item/I = pick(contents)
			I.loc = loc
			if(prob(25))
				step_rand(I)
			to_chat(user, "<span class='notice'>You pull \a [I] out of [src] at random.</span>")
			return
	to_chat(user, "<span class='notice'>You find nothing in [src].</span>")

/obj/structure/filingcabinet/Topic(href, href_list)
	if(href_list["retrieve"])
		usr << browse("", "window=filingcabinet") // Close the menu

		//var/retrieveindex = text2num(href_list["retrieve"])
		var/obj/item/P = locate(href_list["retrieve"])//contents[retrieveindex]
		if(istype(P) && (P.loc == src) && src.Adjacent(usr))
			usr.put_in_hands(P)
			updateUsrDialog()
			icon_state = "[initial(icon_state)]-open"
			spawn(0)
				sleep(5)
				icon_state = initial(icon_state)