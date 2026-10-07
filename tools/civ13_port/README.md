# Civ13 Ground Vehicles

This compatibility port uses ground-vehicle data and sprites from
[Civ13](https://github.com/Civ13/Civ13), revision
`0d38999d5f9f987a944493f11c456537f39ac2f6`. Civ13 contributors are the
authors of the imported models, layouts, armor tables, movement configurations,
weapon descriptions, ammunition definitions, and DMI sprites. The upstream
repository distributes these under AGPL-3.0; Hague's existing `LICENSE.txt`
contains the same license. Preserve this provenance when redistributing the port
and make the modified source available as required by that license.

## Scope

- 54 upstream ground-vehicle layouts, plus a Hague-specific Yamasaki M125 layout
   using Civ13 motorcycle sprites and the bike chassis configuration.
- 513 frame definitions, 74 ground chassis definitions, legacy wheel/track
   variants, turret weapons, hull machine guns, and tank-shell definitions.
- Multi-tile modular construction, directional borders and armor, doors,
   engines/fuel, crew seats, gear/throttle controls, repairs, ammunition racks,
   and passenger/cargo movement. Existing Hague bikes and cargo trains are unchanged.
- Upstream boats, ships, aircraft, and trains are excluded. Hague-specific modular
   spacecraft are provided separately from the imported models. No maps or supply
   catalogues were modified to introduce vehicles automatically.

The runtime is a Hague compatibility implementation, not a verbatim copy of
Civ13's map-dependent machinery. Movement, browser controls, projectile behavior,
and component lifecycles use Hague APIs. Engines accept Hague's `fuel` reagent
and liquid phoron at the same fuel-unit rate;
fuel costs are derived from upstream efficiency/displacement. Magazine capacities,
accepted magazine types, available projectile damage/payload data, and turret
crew roles/offsets are imported from upstream. Shell explosions, component repair,
and construction costs still use Hague-specific behavior rather than Civ13 balancing.
Cars stop at obstacles; this port does not implement Civ13's terrain conversion,
faction/grace-wall checks, mines, or obstacle/run-over destruction. Armored frames
are directional movement/projectile borders, not sealed atmospheric compartments.
Door codes are retained as metadata but are not enforced as locks.
Eleven non-vehicle prop types are omitted, including faction radios/crates,
emergency lights, toolboxes, traffic cones, and boot tables. See
`import-report.json` for the exact list and source asset paths.

## Parity Audit

The 2026-10-05 audit compared the runtime against Civ13 master and confirmed that
master still points to the pinned revision above. Verified repair areas:

- Rectangular turning uses bounded footprint rotation rather than swinging around
   a chassis corner. Transport is snapshotted before movement, preserving crew,
   carried items, connected seats, and installed modules. Mounted guns retain
   their relative orientation and clear stale targets when the hull turns.
- Driver control requires a connected, occupied driver seat on the chassis.
   Cruise does not stop solely because of the periodic idle watchdog. Moving and
   turning require fuel. Detached or deleted driver frames cannot retain control.
- Interior layers, explicit directional wall sprites, model-specific frame art,
   uncolored panel flags, reversed tracks, and upstream corner-aware wheel/track
   offsets are handled. Exterior roofs and turret bodies are hidden for occupants.
- Rendering uses atlas-checked floor/wall/roof states and dimension-aware relative
   offsets for both 32x32 and 96x96 frame art. Where upstream declares missing
   legacy model art, visible generic pieces are used instead of blank states.
   Roofless sections remain roofless. Open doors without dedicated open sprites
   render a cutout rather than showing the closed door. Enclosed turrets include
   their separate roof layer; open technical mounts retain native gun sprites.
   Body overlays use upstream's opposite-facing convention. These fallbacks are
   not replacements for genuinely missing native model artwork.
- Diagonal movement cannot bypass frame borders. Built-wall health is retained
   for welding repairs. Preset assembly rolls back created atoms if installation
   fails instead of leaving a partially connected vehicle.
- Turrets create their imported crew roles and offsets, rather than always
   creating three seats. Manual-loading cannons require the loader when present;
   machine-gun belts do not. Gunner/commander-only autoloading crews remain usable.
- Canonical magazine capacities and accepted types replace blanket 50-round belts
   and caliber-only magazine matching. Autoloading cannons pull compatible rounds
   from connected racks after a reload delay. Rotation cooldowns, fixed mounts,
   ammunition movement checks, and damaged-weapon checks are enforced.
- Diagonal armor hits resolve against a facing border. Armor-piercing rounds can
   continue after spending penetration and damage on armor. A destroyed wall does
   not automatically destroy the track attached to that frame.
- Removing crew stations, mounted guns, frames, or chassis clears associated
   control links, exterior images, and aiming markers. Remounting a turret does
   not duplicate its weapons.

This is not a claim of complete runtime parity. The remaining limitations listed
under Scope still apply. Aiming uses Hague target selection and a simplified
rotation delay rather than Civ13's continuous azimuth/distance artillery controls.
Atmospheric sealing, original collision destruction, original idle-engine fuel
timing/power-to-weight handling, specialized chemical/nuclear shell effects, and
Civ13-specific game rules have not been ported. Compilation and static source/
asset checks passed; normal in-game driving, rendering, and combat checks remain
required before deployment.

## Spawning And Construction

Admins with spawn permission can use `Vehicle Menu` in the Admin tab to select
any spawnable preset, then choose North, South, East, West, or Mouse (the fifth
option). The cardinal options place the vehicle beside the admin, facing that
direction, and show a green footprint before confirmation. The outline, occupied
tiles, facing arrow, and direction/dimension label are visible only to that admin.

Mouse mode asks for the vehicle's facing, then follows the cursor with the same
green preview until a left-click places the vehicle. The hovered tile is the
southwest corner of the rotated footprint. Right-click or `Cancel Vehicle Placement`
cancels. Obstructed placement reports the blocking tile/object and leaves mouse
mode active so another position can be chosen. Cancellation, successful placement,
disconnect, and removal of admin verbs clear the preview. Abstract preset
categories are excluded; the complete footprint must be clear.

Use the normal admin object spawner or map these types on a clear floor footprint:

- `/obj/effect/civ13_vehicle/tank/t34`
- `/obj/effect/civ13_vehicle/tank/m1a1_abrams`
- `/obj/effect/civ13_vehicle/apc/bradley`
- `/obj/effect/civ13_vehicle/yamasaki/shinobu`
- `/obj/effect/civ13_vehicle/yamasaki/m125`
- `/obj/structure/vehicleparts/workbench`

The spawn helper is the southwest corner of the layout. It preflights the entire
footprint and refuses occupied tiles; ground vehicles also refuse space.
A failed helper remains available
for inspection; remove it or call `assemble()` after clearing its footprint.

Feed the workbench a held steel stack to construct components. Drag a chassis onto
a frame, then neighboring frames onto an attached frame. Drag wheels/tracks,
engine, fuel tank, and seats onto attached frames. Install at least four movement
parts, or two for a bike. Steel applied to a frame builds directional walls,
doors, windows, or armored walls. Wrenches remove mounted parts with the engine
off; welders repair damaged parts. Refill fuel tanks from a container holding
Hague `fuel`. All modular vehicle tanks also accept held phoron sheets: use a
sheet stack on the tank to consume one sheet and add 20 fuel units. Tanks need
room for all 20 units; full or nearly full tanks do not consume sheets. This
applies to cars, tanks, motorcycles and spacecraft, including empty built tanks.
Existing liquid refueling remains available using an open, held reagent container
containing `/datum/reagent/fuel` or liquid phoron (`/datum/reagent/toxin/phoron`).
Mixtures of both are accepted and the gauges show their combined usable amount.
Engines consume standard fuel first, then liquid phoron. Click the reservoir, connected engine, or an
adjacent connected hull part; hull/engine interactions forward to the reservoir.
Liquid transfers add up to 20 units per click. Closed/empty containers, full tanks,
and missing reservoirs now explain why refuelling failed.

Legacy Hague bikes also accept sheets directly on the bike or its engine.
Thermal engines gain 20 fuel units per sheet; electric engines and cell-powered
vehicles such as cargo tugs recharge their installed cell by 1,000 charge units
per sheet (or its full capacity for smaller cells). They require sufficient free
capacity and do not consume sheets when full. Install an engine/cell first;
unpowered trailers do not acquire a motor through refueling.

Click an empty vehicle seat to sit down. Click your driver's seat again to open
`Vehicle Controls`, which provides engine, gear, throttle, brake, and leave-seat
actions. The driver controls the installed engine even when it is several tiles
away. The individual `Toggle Vehicle Engine`, `Shift Vehicle Gear`, and
`Toggle Vehicle Throttle` verbs remain available. Directional movement drives
forward/reverse or rotates the chassis. Unbuckling stops movement. Click a frame
to operate its doors. Roofs, body covers, and turret exterior images hide for
onboard players and remain visible to observers outside.

Sit in a gunner station and click the seat again or click its interior weapon
mount to aim, select a mounted weapon, and fire. Use the loader station to load
a manually loaded cannon when the vehicle provides one. Autoloading cannons draw
compatible shells from connected racks. Load machine-gun belts manually using
an accepted magazine type. Ammunition racks dispense shells through normal hand
interaction. A target marker appears for the gunner; weapon controls show rounds,
reload state, and rotation readiness.

Some imported hull mounts do not have a separate gunner station. Their controls
appear as `Weapon Controls` in the connected driver's seat. If an uncrewed mount
has an otherwise unassigned gunner station, clicking that station opens its weapon
controls instead; this includes the Lancer patrol spacecraft's mass driver.

## Spacecraft

The Vehicle Menu also offers five spacecraft presets, using the same
cardinal and Mouse placement controls on clear space or floor footprints:

- `Kestrel scout spacecraft`: 2x3 tiles, two seats, efficient ion propulsion.
- `Wayfarer passenger shuttle`: 3x3 tiles, pilot plus four passenger seats.
- `Mule cargo spacecraft`: 3x5 tiles, four cargo lockers and a large fuel tank.
- `Lancer patrol spacecraft`: 3x4 tiles, weapons station, 75mm mass driver and
   ammunition rack. Load shells from the rack before firing.
- `Prospector mining shuttle`: 3x4 tiles, a pilot couch, two passenger couches
  and five cargo lockers. It is a real shuttle-system vehicle rather than a
  thruster-driven craft, so it needs neither local engines nor propellant.

Their helpers are `/obj/effect/civ13_vehicle/spacecraft/scout`, `/shuttle`,
`/freighter`, `/patrol`, and `/mining` under that same spacecraft path. All spacecraft parts
are available from the vehicle workbench: hulls, cockpit viewports, boarding
hatches, nacelles, chassis variants, engines, thrusters, tanks, seats, mass driver
and cargo lockers. Constructed tanks are empty; preset tanks start fueled.

Spacecraft require at least two undamaged thrusters instead of wheels or tracks.
Ground chassis reject thrusters; spacecraft chassis reject wheels and tracks.
Use the pilot couch's existing vehicle controls for engine, thrust setting
(gear), powered cruise, and braking. Spacecraft use controlled tile movement,
not orbital physics or the overmap ship engine. Tanks accept standard `fuel`
and liquid phoron.
Drag items into cargo lockers by using the held item on them; click to retrieve.

Hull sections are not airtight and do not create pressurized floors. Crew need
spacesuits and internals in vacuum, even behind closed boarding hatches. Ships
stay on their current Z level and cannot spawn, move or turn into space map-edge
transition zones, which would otherwise teleport individual vehicle pieces.

The Prospector pilot couch opens the mining shuttle controls for local mining
and salvage missions, satellite travel, returning home, revisiting the last
debris field, cancelling a pending mission, and allowing or forbidding remote
control. It requires mining access, exactly like the map mining shuttle console.
It travels as a registered shuttle: its initial position is its personal home
berth and its route uses the same warm-up, in-transit status, mission generation,
and arrival flow as the mining shuttle.

Each Prospector requires one clear, non-dense turf immediately outside its spawn
footprint for its paired communications console. The spawn announcement gives its
coordinates. Command-authorized
users can use that console for remote mining, salvage, satellite, and cancel
commands while the pilot has not forbidden remote control. Prospector missions
share the normal mining debris field and satellite; only one debris-field survey
can generate at a time.

## Reimporting

Requirements: Node.js, Git, and a Civ13 checkout at the pinned revision. The
checkout needs `code/modules/1713/machinery`, `code/modules/1713/siege`,
`code/modules/1713/weapons/guns/mg`, `code/modules/projectiles/projectile`, and
`code/modules/projectiles/ammunition.dm`, plus the concrete magazine definitions
`code/modules/1713/_mags1904.dm`, `_mags1939.dm`, and `_magsmodern.dm` in that same
directory. Magazine appearances select available count-dependent sprite states
when created and after firing. Git can retrieve referenced sprite blobs
from a sparse checkout.

From the Hague repository root:

```powershell
node tools/civ13_port/import_ground_vehicles.js C:\path\to\Civ13
node tools/civ13_port/import_ground_vehicles.js C:\path\to\Civ13 --check
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' 'Interpost-Hague.dme'
```

The importer writes `code/modules/vehicles/civ13/models.dm`, copies unmodified
sprite files into `icons/obj/civ13`, and records the import inventory. `--check`
performs read-only source-data and byte-for-byte sprite verification. Do not edit
the generated model file manually. Runtime adapters and the M125 layout are
separate from generated data. Build the normal Hague project; do not open the
Dream Maker IDE or use unit-test harnesses.

## Manual In-Game Checks

Compilation and import verification cannot validate gameplay. Check these in a
normal game before deployment:

1. Spawn a T-34, a car, an APC, and the M125 on clear floor footprints; confirm
   frames, tracks, turrets, and seats render in every cardinal orientation.
2. Drive forward/reverse, change gears, turn near walls/map edges, and stop the
   throttle; confirm frames, crew, and loose cargo remain aligned.
3. Verify another vehicle, closed airlock, or wall prevents the entire footprint
   from moving, without partial movement or passengers being displaced.
4. Exhaust fuel, leave the driver seat, break a track/engine, and remove the
   chassis; confirm movement stops and stale controls cannot operate it.
5. Compare roof visibility for an outside observer and onboard crew; leave the
   vehicle and delete frames/chassis to check image cleanup.
6. Operate every crew role, reload the main gun and coax/hull guns, reject wrong
   calibers, and fire AP/HE shells at front/side armor and ordinary Hague targets.
7. Build a vehicle from steel, attach/remove components, construct/open borders,
   and repair damaged parts. Confirm ordinary seat unbuckling still works.
8. Confirm preexisting Hague bikes/cargo trains retain their controls and movement.
9. Check all four cardinal placement previews against the spawned footprint and
   facing. Check Mouse mode on floors and over large sprites, with ordinary and
   widescreen views; confirm left-click, right-click cancellation, blocked-placement
   retry, and deadmin/disconnect cleanup.
10. Spawn all four spacecraft in clear space in each facing, wearing a spacesuit
   with internals. Board through a hatch, start the engine, drive, reverse, turn
   and brake. Verify crew, loose items and loaded cargo lockers move together.
11. Check spacecraft floor/space transitions, obstruction rejection and map-edge
   stopping. Confirm ordinary ground vehicles still cannot spawn or drive in space.
12. Break/remove thrusters and exhaust fuel to check movement stopping; repair and
   refuel to resume. Confirm removed thrusters no longer glow. Build a spacecraft
   from workbench parts and operate the patrol craft's weapon from its station.
13. Use phoron sheets on a partly empty car, tank, motorcycle and spacecraft fuel
   tank; confirm one sheet adds 20 units and movement resumes after refueling.
   Check full/nearly full tanks, empty sheet stacks and out-of-reach interactions
   do not consume sheets. Repeat on legacy thermal/electric bikes and cargo tugs,
   including missing/full cells; confirm liquid fuel and cell replacement still work.
