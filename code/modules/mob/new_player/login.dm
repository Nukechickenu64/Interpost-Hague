/var/obj/effect/lobby_image = new/obj/effect/lobby_image()

/obj/effect/lobby_image
	name = "Marrow" // renamed project
	desc = "This shouldn't be read."
	screen_loc = "WEST,SOUTH"
	mouse_opacity = 0

/obj/effect/lobby_image/Initialize()
	icon = 'icons/misc/fullscreen_lobby.dmi'
	icon_state = "orbital"

	. = ..()

/mob/new_player/Login()
	..()
	update_Login_details()	//handles setting lastKnownIP and computer_id for use by the ban systems as well as checking for multikeying
	to_chat(src, "<h1 class='alert'>Story ID:</h1>")

	to_chat(src, "<div class='danger'>[game_id]</div>")

	if(GAME_STATE <= RUNLEVEL_LOBBY)
		to_world("<div class='playerjoinbox'><span class='notice'>LOBBY: [usr.key] comes.</span></div>")

	if(!mind)
		mind = new /datum/mind(key)
		mind.active = 1
		mind.current = src

	loc = null
	var/obj/effect/lobby_image/lobby = new
	var/view_w = update_client_view()
	if(view_w > 15)
		// Uniform "cover" scaling: keeps the aspect ratio, fills the widened view, and crops the overflow top and bottom.
		var/matrix/M = matrix()
		M.Scale(view_w / 15, view_w / 15)
		M.Translate((view_w - 15) * 16, 0)
		lobby.transform = M
	client.screen += lobby
	my_client = client
	set_sight(sight|SEE_TURFS|SEE_OBJS)
	GLOB.player_list |= src
	//to_chat(src, "\n<div class='firstdivmood'><div class='moodbox'><span class='graytext'>This is a proof of concept.</span>\n<span class='feedback'><a href='?src=\ref[src];action=agreeconcept'>This sucks ass.</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=refuseconcept'>No, it doesn't.</a></span></div></div>")

	client.playtitlemusic()

/*
/client/Topic(href, href_list, hsrc)
	..()
	switch(href_list["action"])
		if("agreeconcept")
			to_chat(src, "Eurika!")
*/