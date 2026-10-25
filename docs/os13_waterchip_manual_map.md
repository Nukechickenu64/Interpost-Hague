# Water-chip video map: manual reconstruction (in progress)

Working output: `maps/os13/waterchip-manual.dmm`. The original `os13.dmm` is
the template and remains untouched. The provisional z=9 bridge placements
were removed. The prior z=4 room and corridor edits have been restored from
their surviving hand-entered placement list. The map writer is disabled;
future edits must be entered as direct, frame-checked DMM changes.

The video opens on BYOND z=4. The three-window anchor is `(99..101,102,4)`.
The current 210 changed cells cover the opening rooms, locker area,
stair hall, and a housing-corridor section on z=6. The original 176 observations and a separate before/after
record for 29 earlier corrected cells and 25 new stair-hall cells are in `maps/os13/waterchip-manual.json`.
The round grated floor lights use
`/obj/machinery/floor_light/os13`; the scanner console now has a dedicated
type instead of borrowing cryopod machinery. Reference objects live in
`code/game/objects/structures/os13_reference.dm`.

Consecutive frame contact sheets have now been manually inspected for frames
0 through 8399 (00:00 through 02:19.983, 60 fps). Full-resolution stills were
used to identify the opening-room floor covers, vents, signs, and lockers.
The next frame is 8400. The full recording lasts 01:42:29.68; its remainder
has not been reviewed. The stair transition around frame 4478 matches the template stair pair at
(114..115,117,4). In this code, those stairs travel through GetAbove. Landing
transcription remains pending exact calibration. The lift room entered around
frame 4930 changes its surroundings around frame 5290 and then displays
4 DECK; its destination BYOND z is not yet verified.

This pass directly corrected 29 named DMM cells: floor covers, square vents,
station emblems, blue open lockers, the question-mark poster, green strips,
and the scanner. New reference turf/object types preserve the matched art.
Every other cell matches the preserved 141-cell baseline saved under
`tmp/waterchip-manual/preserved-141cells/`. No map generator was run for this
pass. The old map writer remains disabled.

Two north-corridor vents and the north-corridor station emblem were also
placed using full-resolution frame 3600. Their underlying template turfs
remain pending a separate tile-by-tile review.

Still unresolved: south locker hatch art, wall buttons, locker contents,
office poster, and functional small wall lamps. Camera motion must be tracked
against a common landmark before assigning coordinates or z levels.

`waterchip-manual-preview.png` and `waterchip-locker-review.png` are static,
unlit sprite previews of the current DMM. They are not live-client validation.
`os13_waterchip_manual.dme` compiled with 0 errors and 0 warnings after this
pass. The map has not been checked in a live BYOND client.

Latest continuation: full-resolution frame 4410 was used to manually correct
24 individual floor cells and place the yellow stair-hall deck sign. Every
other cell is identical to the snapshot in
`tmp/waterchip-manual/preserved-153cells/`. The latest DMM compiled with
0 errors and 0 warnings. `waterchip-stair-hall-review.png` shows these
changes as a static unlit crop; walls, doors, and other hall fixtures still
need transcription. No new z-level placements were made in this pass.

Housing continuation: the recording is now located at
`D:/os13archive/os131.mp4`. Its embedded title, duration, resolution, and frame
rate match the original recording. The route after the lift agrees with the
template's z=6 housing layout. The lift door `(116,123)`, psi door `(116,119)`,
paired gates `(119..120,127)`, and cabin threshold `(121,133)` track the camera
to frame 6000. In that frame `(120,142,6)` is at screen pixel `(787,541)` with
a 72-pixel tile pitch. This is manual reference-to-template correspondence;
the lift's live runtime destination has not been tested.

Eighteen individually inspected z=6 cells now contain 13 floor corrections,
four cabin doors, two square vents, and one round grated floor light. Some
cells contain both a corrected floor and a fixture. Every other cell matches
`tmp/waterchip-manual/preserved-177cells/waterchip-manual.dmm`. The exact edits
and frame evidence are in `housing_corrections` in the JSON ledger.
`waterchip-housing-review.png` is a static unlit crop. Remaining mixed floor
variants, wall art, buttons, corridor furnishings, and cabin interiors are
unfinished. The stair landing and the lift connection still need transcription.

Frame 7200 continuation: manually matched seven `os8` mixed gold/gray floor
tiles and six `os4` gray floor tiles, placed the east cabin door at
`(122,137,6)`, and placed round green wall lamps at `(117,143,6)` and
`(121,143,6)`. The new `/obj/machinery/light/small/os13_wall` subtype uses the
supplied `wall1`, `wall0`, broken, burned, and empty states with the existing
bulb/power implementation. This preserves the matched art through runtime
icon updates; live lighting remains untested. Older z=4 visual-only wall
lamps have not yet been converted.

Exactly 16 named cells differ from the snapshot in
`tmp/waterchip-manual/preserved-195cells/`; all other cells are identical.
Evidence is recorded under `housing_frame7200_corrections` in the JSON
ledger. The open cabin interior is too dark to identify its contents reliably
in these frames, so it remains untranscribed. The character returns south
through the housing corridor and re-enters the lift around 02:18.

The frame-7200 changes and new lamp type compiled through
`os13_waterchip_manual.dme` with 0 errors and 0 warnings.
