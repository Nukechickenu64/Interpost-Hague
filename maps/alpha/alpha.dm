#if !defined(using_map_DATUM)

	#include "alpha_announcements.dm"
	#include "alpha_areas.dm"


	//CONTENT
	#include "alpha_gamemodes.dm"
	#include "alpha_presets.dm"
	#include "alpha_shuttles.dm"

	#include "alpha.dmm"
	#include "ruinsalpha.dmm"
	#include "../../maps/away/mining/mining.dm"

	//#include "job/jobs.dm"
	#include "../shared/job/jobs.dm"

	#include "../../code/modules/lobby_music/generic_songs.dm"

	#define using_map_DATUM /datum/map/alpha

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Alpha
#endif
