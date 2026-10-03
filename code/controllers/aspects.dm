/datum/controller/subsystem/ticker/proc/pick_round_event()
	var/event_type = pick(typesof(/datum/round_event) - /datum/round_event)
	if (event_type)
		var/event = new event_type
		return event
	else
		log_debug("No valid /datum/round_events found.")

/datum/round_event
	var/id = "default"
	var/event_message = "You shouldn't have seen this. Yell at a coder."

/datum/round_event/captainless
	id = "captainless"
	event_message = "The captain abandoned the crew in their sleep. There will be no law or order on this shift, and the security officers have become roughnecks."

/datum/round_event/captainless/apply_event()
	for(var/mob/living/carbon/human/H in GLOB.human_mob_list)
		if(!H.mind || !H.mind.assigned_job || !(H.mind.assigned_job.department_flag & SEC))
			continue
		if(H.mind.assigned_role == "Security Officer")
			H.job = "Security Roughneck"

		var/obj/item/card/id/id_card = H.wear_id
		if(istype(H.wear_id, /obj/item/device/pda))
			var/obj/item/device/pda/pda = H.wear_id
			id_card = pda.id
		if(id_card)
			id_card.access = get_all_accesses()

/datum/round_event/proc/announce_event()
	to_world("<h1 class='alert'>Round Aspect:</h1>")
	to_world("<br><b>[event_message]</b><br>")
	return

/datum/round_event/proc/apply_event()
	return

/datum/round_event/without_light
	id = "withoutlight"
	event_message = "The station did not receive the heroes of this shift very favourably: a complete darkness accompanied them to their workplaces."

/datum/round_event/without_light/apply_event()
	lightsout(0, 0)
	for(var/obj/item/device/flashlight/F)
		F.on = 0
		F.update_icon()

/datum/round_event/lack_of_energy
	id = "lackofenergy"
	event_message = "The absence of such a precious element as a supermatter crystal at the station on the outskirts is not such a big surprise. The corporation has raised another challenge to the engineers, who in turn tighten the wires with a heavy breath..."

/datum/round_event/lack_of_energy/apply_event()
	for(var/obj/machinery/power/supermatter/SM in world)
		qdel(SM)
	for(var/obj/machinery/the_singularitygen/LORDSINGULO in world)
		qdel(LORDSINGULO)

/*
/datum/round_event/old_times
	id = "oldtimes"
	event_message = "The ghosts of the past drag the staff down, showing them what was unheard of. The station's waste in the person of the \"olds\" has decided to open the curtain of darkness to those who still have to find out and understand everything.."

/datum/round_event/old_times/apply_event()
	for(var/atom/movable/lighting_overlay/LO in world)
		LO.icon = 'icons/effects/lighting_overlay.dmi'
		LO.update_overlay()
		CHECK_TICK
*/

/*
/datum/round_event/assjesters
	id = "assclowns"
	event_message = "On this wild shift, the members of the grey brotherhood decided to fold their clothes to raise the banner of absurdity and demonstrate the real meaning of \"Space Station\" to the plebians!"
*/

/*
/datum/round_event/ghetto_medbay
	id = "ghettomedbay"
	event_message = "Nanotrasen back on the line! Nothing will stop brave doctors from showing their competence again and proving that they are the best of their kind!.. Even despite the low budget."

/datum/round_event/ghetto_medbay/apply_event()
	for(var/area/medical/M in world)
		for(var/obj/item/storage/firstaid/o2/FO in M)
			var/obj/item/reagent_containers/syringe/inaprovaline/SI = new(FO.loc)
			SI.desc = "Who needs a oxygen deprivation first-aid kit?"
			qdel(FO)
		for(var/obj/item/reagent_containers/spray/sterilizine/SS in M)
			var/obj/item/reagent_containers/food/drinks/bottle/vodka/BV = new(SS.loc)
			BV.name = "Sterilizine"
			qdel(SS)
		for(var/obj/structure/morgue/SM in M)
			var/obj/structure/closet/coffin/CC = new(SM.loc)
			CC.name = "Morgue"
			CC.desc = "Why does it look like a coffin?"
			qdel(SM)
		for(var/obj/structure/closet/secure_closet/medical1/M1 in M)
			var/obj/structure/closet/wardrobe/medic_white/MW = new(M1.loc)
			MW.name = "Improvised Medical Closet"
			qdel(M1)
		for(var/obj/structure/closet/secure_closet/chemical/C in M)
			var/obj/structure/closet/wardrobe/medic_white/MW = new(C.loc)
			MW.name = "Improvised Chemical Closet"
			qdel(C)
		for(var/obj/item/clothing/glasses/hud/health/HH in M)
			var/obj/item/clothing/glasses/regular/GR = new(HH.loc)
			GR.desc = "Why are they without HUD?"
			qdel(HH)
		for(var/obj/structure/closet/secure_closet/medical_wall/SCMW in M)
			qdel(SCMW)
		for(var/obj/item/stack/material/phoron/MP in M)
			qdel(MP)
		for(var/obj/machinery/vending/medical/VM in M)
			qdel(VM)
		for(var/obj/item/storage/firstaid/regular/FAR in M)
			var/obj/item/device/healthanalyzer/HA = new(FAR.loc)
			HA.desc = "Where's my first aid kit?"
			qdel(FAR)
		for(var/obj/item/defibrillator/compact/loaded/DCL in M)
			qdel(DCL)
		for(var/obj/item/rig/medical/RM in M)
			qdel(RM)
		for(var/obj/structure/closet/radiation/CR in M)
			qdel(CR)
		for(var/obj/item/storage/firstaid/surgery/FAS in M)
			var/obj/item/storage/toolbox/mechanical/TM = new(FAS.loc)
			TM.name = "Surgery Kit"
			qdel(FAS)
		for(var/obj/machinery/bodyscanner/BS in M)
			qdel(BS)
		for(var/obj/machinery/body_scanconsole/BSC in M)
			qdel(BSC)
		for(var/obj/machinery/chemical_dispenser/CD in M)
			var/obj/machinery/chemical_dispenser/lower_budget/CDLB = new(CD.loc)
			CDLB.desc = "For some reason, without most chemicals."
			qdel(CD)
		for(var/obj/machinery/organ_printer/flesh/mapped/OP in M)
			qdel(OP)
		for(var/obj/machinery/sleeper/S in M)
			qdel(S)
		for(var/obj/item/bodybag/cryobag/CB in M)
			var/obj/item/bodybag/B = new(CB.loc)
			B.name = "Cryobag Replacement"
			B.desc = "You wouldn't have saved him anyway."
			qdel(CB)
		for(var/obj/item/weapon/scalpel/SC in M)
			var/obj/item/weapon/material/knife/K = new(SC.loc)
			K.name = "Improvised scalpel"
			qdel(SC)
		for(var/obj/machinery/resleever/RE in M)
			qdel(RE)
		for(var/obj/item/storage/firstaid/fire/FAF in M)
			var/obj/item/stack/medical/ointment/MO = new(FAF.loc)
			MO.desc = "Who needs a fire first-aid kit?"
			qdel(FAF)
		for(var/obj/item/storage/firstaid/toxin/FAT in M)
			var/obj/item/reagent_containers/syringe/antitoxin/SAT = new(FAT.loc)
			SAT.desc = "Who needs a toxin first-aid kit?"
			qdel(FAT)
		for(var/obj/item/reagent_containers/spray/cleaner/SC in M)
			var/obj/item/soap/deluxe/SD = new(SC.loc)
			SD.name = "Space Cleaner Soap Deluxe"
			SD.desc = "In 2563 someone need space cleaners?"
			qdel(SC)
	for(var/area/crew_quarters/medbreak/M in world)
		for(var/obj/item/reagent_containers/spray/cleaner/SC in M)
			var/obj/item/soap/deluxe/SD = new(SC.loc)
			SD.name = "Space Cleaner Soap Deluxe"
			SD.desc = "In 2563 someone need space cleaners?"
			qdel(SC)
*/

/*
/datum/round_event/clumpsy_dumbasses
	id = "clumpsydumbasses"
	event_message = "By a really wild coincidence, most of the staff makes a lot of effort to concentrate the flow of their thoughts, and even the targeting of those spend a huge amount of effort. As long as their heels are safe!"

/datum/round_event/clumpsy_dumbasses/apply_event()
	for(var/mob/living/carbon/human/H in GLOB.human_mob_list)
		if(prob(69))
			H.mutations.Add(CLUMSY)
*/

/datum/round_event/can_you_hear_me_major_tom
	id = "CANYOUHEARMEMAJTOM"
	event_message = "Absence of a specialized headset will never prevent anyone in the station from working. As long as they have walkie-talkies, that is."

/datum/round_event/can_you_hear_me_major_tom/apply_event()
	for(var/obj/item/device/radio/headset/RH in world)
		qdel(RH)

/datum/round_event/partyhard
	id = "partyhard"
	event_message = "The future is long overdue. Unfortunately, the desire to burn the \"city\" with neon candles appeared only recently, as well as the opportunity for this."

/datum/round_event/partyhard/apply_event()
	for(var/obj/machinery/light/L in world)
		L.lightbulb.brightness_color = pick(COLOR_DEEP_SKY_BLUE, COLOR_PINK, COLOR_RED_LIGHT, COLOR_LIME, COLOR_RED, COLOR_PAKISTAN_GREEN, COLOR_VIOLET, COLOR_BLUE, COLOR_PALE_GREEN_GRAY, COLOR_LUMINOL, COLOR_GUNMETAL, COLOR_LIGHT_CYAN)
		L.on = L.powered()
		L.update_icon()

/*
/datum/round_event/pussy_riot
	id = "pussyriot"
	event_message = "Today the Security Department is acting especially gently. This tenderness is expressed by the general attitude of the department...  As well as its equipment."

/datum/round_event/pussy_riot/apply_event()
	for(var/obj/item/weapon/melee/classic_baton/B in world)
		B.color = COLOR_LIGHT_PINK
	for(var/obj/item/weapon/handcuffs/H in world)
		H.icon = 'icons/obj/pinkcuffs.dmi'
		H.icon_state = "pinkcuffs"
		H.update_icon()
	for(var/area/security/S in world)
		for(var/obj/machinery/light/L in S)
			L.lightbulb.brightness_color = COLOR_PINK
			L.on = L.powered()
			L.update_icon()
		for(var/obj/structure/table/T in S)
			T.color = COLOR_LIGHT_PINK
		for(var/obj/structure/bed/chair/C in S)
			C.color = COLOR_LIGHT_PINK
		for(var/obj/structure/window/W in S)
			W.color = COLOR_LIGHT_PINK
		for(var/obj/machinery/door/window/W in S)
			W.color = COLOR_LIGHT_PINK
		for(var/obj/machinery/door/airlock/A in S)
			A.color = COLOR_LIGHT_PINK
*/

/datum/round_event/wherecams
	id = "wherecams"
	event_message = "It seems like the station's cameras suddenly packed their things and disappeared. Huh."

/datum/round_event/wherecams/apply_event()
	for(var/obj/machinery/camera/C in world)
		qdel(C)

/datum/round_event/whereaccess
	id = "whereaccess"
	event_message = "As you arrive, you notice that the whole station has all access. Oh Science."

/datum/round_event/whereaccess/apply_event()
	for(var/obj/machinery/door/airlock/A in world)
		A.req_access = list()
		A.req_one_access = list()
	for(var/obj/machinery/door/window/W in world)
		W.req_access = list()
		W.req_one_access = list()

/datum/round_event/guns_n_roses
	id = "guns_n_roses"
	event_message = "After a renowned 21st century band song started playing on the jukebox before you arrived, you suddenly notice that all melee weapons are now gone."

/datum/round_event/guns_n_roses/apply_event()
	for(var/obj/item/weapon/material/sword/B in world)
		qdel(B)

/datum/round_event/no_pdas
	id = "no_pdas"
	event_message = "The station's personal data assistants were recalled for a firmware audit. Paperwork is back in fashion."

/datum/round_event/no_pdas/apply_event()
	for(var/obj/item/device/pda/P in world)
		qdel(P)
		CHECK_TICK

/datum/round_event/no_id_cards
	id = "no_id_cards"
	event_message = "The identification office lost the entire badge shipment. Everyone will have to explain themselves the old-fashioned way."

/datum/round_event/no_id_cards/apply_event()
	for(var/obj/item/card/id/I in world)
		qdel(I)
		CHECK_TICK

/datum/round_event/no_flashlights
	id = "no_flashlights"
	event_message = "The emergency-lighting contractor delivered an empty crate. Personal flashlights are nowhere to be found."

/datum/round_event/no_flashlights/apply_event()
	for(var/obj/item/device/flashlight/F in world)
		qdel(F)
		CHECK_TICK

/datum/round_event/empty_vending
	id = "empty_vending"
	event_message = "The vending consortium is observing a labor action. Machines hum, but their shelves are empty."

/datum/round_event/empty_vending/apply_event()
	for(var/obj/machinery/vending/V in world)
		V.slogan_list = list()
		V.products = list()
		V.premium = list()
		V.contraband = list()
		CHECK_TICK

/datum/round_event/maintenance_shift
	id = "maintenance_shift"
	event_message = "A scheduling error assigned the entire station to maintenance duty. Departmental boundaries are mostly advisory today."

/datum/round_event/maintenance_shift/apply_event()
	for(var/obj/machinery/door/airlock/A in world)
		A.req_access = list()
		A.req_one_access = list()
		CHECK_TICK

/datum/round_event/department_blackout
	id = "department_blackout"
	event_message = "The station's departmental power routing failed. Only the public corridors remembered to stay lit."

/datum/round_event/department_blackout/apply_event()
	for(var/obj/machinery/light/L in world)
		if(istype(get_area(L), /area/security) || istype(get_area(L), /area/medical) || istype(get_area(L), /area/rnd))
			L.on = 0
			L.update_icon()
		CHECK_TICK

/datum/round_event/security_shortage
	id = "security_shortage"
	event_message = "Security's equipment order was cut to the bone. The department will have to improvise."

/datum/round_event/security_shortage/apply_event()
	for(var/obj/item/weapon/melee/classic_baton/B in world)
		qdel(B)
		CHECK_TICK
	for(var/obj/item/weapon/handcuffs/C in world)
		qdel(C)
		CHECK_TICK

/datum/round_event/medical_shortage
	id = "medical_shortage"
	event_message = "Medical supplies arrived in miniature quantities. Every treatment will need to count."

/datum/round_event/medical_shortage/apply_event()
	for(var/obj/item/storage/firstaid/F in world)
		qdel(F)
		CHECK_TICK
	for(var/obj/item/defibrillator/D in world)
		qdel(D)
		CHECK_TICK

/datum/round_event/research_shortage
	id = "research_shortage"
	event_message = "Research received a shipment of empty containers. Science will have to work with what it has."

/datum/round_event/research_shortage/apply_event()
	for(var/obj/item/stack/material/phoron/P in world)
		qdel(P)
		CHECK_TICK
	for(var/obj/item/stack/material/uranium/U in world)
		qdel(U)
		CHECK_TICK

/datum/round_event/communications_blackout
	id = "communications_blackout"
	event_message = "Long-range communications are down. The station is on its own until someone restores the antenna network."

/datum/round_event/communications_blackout/apply_event()
	for(var/obj/item/device/radio/headset/R in world)
		qdel(R)
		CHECK_TICK
	for(var/obj/item/device/radio/intercom/I in world)
		qdel(I)
		CHECK_TICK

/datum/round_event/airlock_census
	id = "airlock_census"
	event_message = "Every airlock received the same access audit result: insufficient data. Doors will not recognize department credentials."

/datum/round_event/airlock_census/apply_event()
	for(var/obj/machinery/door/airlock/A in world)
		A.req_access = list()
		A.req_one_access = list()
		CHECK_TICK
	for(var/obj/machinery/door/window/W in world)
		W.req_access = list()
		W.req_one_access = list()
		CHECK_TICK

/datum/round_event/party_lights
	id = "party_lights"
	event_message = "The station lighting controller entered celebration mode before anyone could find the off switch."

/datum/round_event/party_lights/apply_event()
	for(var/obj/machinery/light/L in world)
		L.lightbulb.brightness_color = pick(COLOR_PINK, COLOR_RED, COLOR_LIME, COLOR_VIOLET, COLOR_BLUE, COLOR_LIGHT_CYAN)
		L.on = L.powered()
		L.update_icon()
		CHECK_TICK

/datum/round_event/window_inspection
	id = "window_inspection"
	event_message = "The station's windows failed inspection and were removed pending a replacement order. Try not to lean on the walls."

/datum/round_event/window_inspection/apply_event()
	for(var/obj/structure/window/W in world)
		qdel(W)
		CHECK_TICK
	for(var/obj/machinery/door/window/D in world)
		qdel(D)
		CHECK_TICK

/datum/round_event/empty_toolboxes
	id = "empty_toolboxes"
	event_message = "The tool supplier sent beautifully organized boxes containing absolutely nothing useful."

/datum/round_event/empty_toolboxes/apply_event()
	for(var/obj/item/storage/toolbox/T in world)
		for(var/obj/item/I in T.contents)
			qdel(I)
		CHECK_TICK

/datum/round_event/no_cameras
	id = "no_cameras"
	event_message = "The station's surveillance office suffered a catastrophic filing error. There is no camera footage of anything."

/datum/round_event/no_cameras/apply_event()
	for(var/obj/machinery/camera/C in world)
		qdel(C)
		CHECK_TICK

/datum/round_event/random_names
	id = "randomnames"
	event_message = "The personnel database suffered a bizarre sorting error. Nobody's name matches the roster anymore."

/datum/round_event/random_names/apply_event()
	for(var/mob/living/carbon/human/H in GLOB.human_mob_list)
		if(!H.mind)
			continue
		H.real_name = random_name(H.gender)
		H.f_style = random_facial_hair_style(H.gender)
		H.h_style = random_hair_style(H.gender)
		H.name = H.real_name
		CHECK_TICK

/datum/round_event/clumsy_shift
	id = "clumpsydumbasses"
	event_message = "A statistical anomaly has made the crew unusually talented at dropping important things. Mind your feet."

/datum/round_event/clumsy_shift/apply_event()
	for(var/mob/living/carbon/human/H in GLOB.human_mob_list)
		if(prob(69))
			H.mutations.Add(CLUMSY)
		CHECK_TICK

/datum/round_event/assjesters
	id = "assjesters"
	event_message = "The station's role labels were shuffled overnight. Some members of the crew may discover a new calling at their first paycheck."

/datum/round_event/director_pressure
	id = "director_pressure"
	event_message = "The station's risk office began the shift with a red marker and a very long list of concerns."

/datum/round_event/director_pressure/apply_event()
	if(SSdirector && SSdirector.enabled)
		SSdirector.tension = max(SSdirector.tension, 35)
		SSdirector.tension_last_change_reason = "Round aspect: director pressure"

/datum/round_event/corporate_austerity
	id = "corporate_austerity"
	event_message = "Corporate has tightened the purse strings. Personal agendas are plentiful, but assistance will be scarce."

/datum/round_event/corporate_austerity/apply_event()
	if(SSdirector && SSdirector.enabled)
		SSdirector.debt_probability = max(SSdirector.debt_probability, 55)
		SSdirector.agenda_probability = min(SSdirector.agenda_probability, 25)

/datum/round_event/calm_before_the_storm
	id = "calm_before_the_storm"
	event_message = "The station's first reports are unusually calm. Everyone has a little too much time to notice the silence."

/datum/round_event/calm_before_the_storm/apply_event()
	if(SSdirector && SSdirector.enabled)
		SSdirector.tension = min(SSdirector.tension, 5)
		SSdirector.tension_last_change_reason = "Round aspect: calm before the storm"