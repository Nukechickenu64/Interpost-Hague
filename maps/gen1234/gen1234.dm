#if !defined(using_map_DATUM)
	#include "gen1234_areas.dm"
	#include "gen1234_unit_testing.dm"

	#include "gen1234.dmm"

	#include "../shared/job/jobs.dm"
	#include "../../code/modules/lobby_music/generic_songs.dm"

	#define using_map_DATUM /datum/map/gen1234

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Halcyon Platform

#endif
