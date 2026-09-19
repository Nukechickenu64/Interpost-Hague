#if !defined(using_map_DATUM)
	#include "example_areas.dm"
	#include "example_shuttles.dm"
	#include "example_unit_testing.dm"

	#include "example.dmm"

	#include "../shared/job/jobs.dm"
	#include "../../code/modules/lobby_music/absconditus.dm"

	#define using_map_DATUM /datum/map/example

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Example

#endif
