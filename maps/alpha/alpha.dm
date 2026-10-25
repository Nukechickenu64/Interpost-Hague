#if !defined(using_map_DATUM)

	#include "alpha_announcements.dm"
	#include "alpha_areas.dm"


	//CONTENT
	#include "alpha_gamemodes.dm"
	#include "alpha_presets.dm"
	#include "alpha_shuttles.dm"

	#ifdef OS13_MANUAL_REFERENCE
		#include "../os13/waterchip-manual.dmm"
	#else
	#ifdef OS13_RECREATION
		#include "../os13/recreation.dm"
	#else
		#include "alpha.dmm"
	#endif
	#endif
	#include "../../maps/away/mining/mining.dm"

	//#include "job/jobs.dm"
	#include "../shared/job/jobs.dm"

	#include "../../code/modules/lobby_music/generic_songs.dm"

	#ifdef OS13_RECREATION
		#define using_map_DATUM /datum/map/os13
	#else
		#define using_map_DATUM /datum/map/alpha
	#endif

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Alpha
#endif
