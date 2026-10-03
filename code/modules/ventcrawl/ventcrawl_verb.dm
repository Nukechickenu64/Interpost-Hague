/mob/living/proc/ventcrawl()
	set name = "Crawl through Vent"
	set desc = "Enter or travel through the station vents."
	set category = "Abilities"
	if(is_ventcrawling)
		choose_station_vent()
		return
	var/pipe = start_ventcrawl()
	if(pipe)
		handle_ventcrawl()
