#if !defined(using_map_DATUM)

	#include "dreyfus_announcements.dm"
	#include "dreyfus_areas.dm"
	#include "dreyfus_elevator.dm"
	//#include "dreyfus_ranks.dm"
	#include "dreyfus_presets.dm"
	#include "dreyfus_shuttles.dm"
	#include "dreyfus_effects.dm"


	//CONTENT
	#include "../shared/job/jobs.dm"
	#include "../shared/datums/uniforms.dm"
	#include "../shared/items/cards_ids.dm"
	#include "../shared/items/clothing.dm"

	#include "dreyfus_gamemodes.dm"

	#include "dreyfus.dmm"

	#include "../../code/modules/lobby_music/generic_songs.dm"

	#define using_map_DATUM /datum/map/dreyfus

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Dreyfus
#endif
