"""Build a small native BYOND viewer for the production startup masks/renderer.

Run walking_animation_regression.dme first to export standing character fixtures.
Then run this script, compile tmp/walking-animation/native.dme, host its DMB,
and connect Dream Seeker. The isolated viewer exits after five minutes.
"""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tmp/walking-animation"
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "icons/effects").mkdir(parents=True, exist_ok=True)
shutil.copyfile(ROOT / "icons/effects/effects.dmi", OUT / "icons/effects/effects.dmi")
source = (ROOT / "code/modules/mob/living/carbon/human/walking_animation.dm").read_text()
library = source[source.index("SUBSYSTEM_DEF(walking)"):source.index("/mob/living/carbon/human/set_dir")]
renderer = source[source.index("/mob/living/carbon/human/proc/walking_overlay"):]
renderer = renderer.replace("/mob/living/carbon/human/proc/walking_overlay", "/obj/sample/proc/walking_overlay")
(OUT / "production.dm").write_text(library + renderer)

resources = []
for gender in ("male", "female"):
    for facing in (2, 1, 4, 8):
        name = f"{gender}_0_{facing}.png"
        if not (OUT / name).exists():
            raise SystemExit("Run walking_animation_regression.dme first: missing " + name)
        resources.append(f'"{gender}|{facing}" = \'{name}\'')

harness = r'''
#define TRUE 1
#define FALSE 0
#define SS_INIT_ATOMS 4
#define SS_NO_FIRE 1
#define SUBSYSTEM_DEF(X) /datum/controller/subsystem/##X
#define CRASH(X) throw EXCEPTION(X)
/datum/controller/subsystem
	var/name
	var/init_order
	var/flags
	var/initialized = FALSE
/datum/controller/subsystem/proc/Initialize(timeofday)
	initialized = TRUE
var/datum/controller/subsystem/walking/SSwalking = new
#include "production.dm"
var/list/fixtures = list(RESOURCES)
/world
	name = "Walking Animation Native Preview"
	fps = 20
	view = "15x12"
	maxx = 15
	maxy = 12
	maxz = 1
/world/New()
	SSwalking.Initialize(world.timeofday)
	world.log << "Prepared [SSwalking.generated_masks] masks and [SSwalking.poses.len] poses before client entry."
	spawn(3000)
		del world
/obj/sample
	var/walking_phase
	var/list/walking_overlay_cache
/client
	var/body_gender = "male"
/client/New()
	. = ..()
	mob.loc = locate(8, 6, 1)
	mob.invisibility = 101
	show_samples()
/client/verb/SwitchBody()
	set name = "Switch Body"
	body_gender = body_gender == "male" ? "female" : "male"
	show_samples()
/client/proc/show_samples()
	for(var/obj/sample/O in world) del O
	var/column = 0
	for(var/facing in list(SOUTH, NORTH, EAST, WEST))
		var/row = 0
		for(var/phase in list(0, 1, -1))
			var/obj/sample/O = new(locate(3 + column * 3, 10 - row * 3, 1))
			O.dir = facing
			O.walking_phase = phase
			var/image/standing = image(fixtures["[body_gender]|[facing]"])
			O.overlays += phase ? O.walking_overlay(standing) : standing
			O.transform = matrix() * 2
			row++
		column++
	world.log << "Showing [body_gender]: top idle, middle left step, bottom right step. Columns south, north, east, west. Masks=[SSwalking.generated_masks]."
'''
(OUT / "native.dme").write_text(harness.replace("RESOURCES", ",\n".join(resources)))
print(OUT / "native.dme")
