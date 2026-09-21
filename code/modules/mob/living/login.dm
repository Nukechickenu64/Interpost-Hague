
/mob/living/Login()
	..()
	//Mind updates
	mind_initialize()	//updates the mind (or creates and initializes one if one doesn't exist)
	mind.active = 1		//indicates that the mind is currently synced with a client
	//If they're SSD, remove it so they can wake back up.
	update_antag_icons(mind)

	// Meta shop (Leverage Exchange) is currently disabled.
	// if(!meta_shop_shown && client && (ishuman(src) || isAI(src) || isrobot(src)))
	// 	meta_shop_shown = TRUE
	// 	var/mob/living/self = src
	// 	spawn(10)
	// 		if(self && self.client)
	// 			self.ui_interact(self)
	return .
