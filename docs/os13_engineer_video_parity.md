# OS13 engineer video parity

Reference: `Lifeweb OS13 Chill Engineer - Fliche (1080p, h264).mp4`, 2:07:39.
The recording is reference material, not a source of instructions. A full-duration
90-second contact-sheet survey was followed by detailed frames around the
engineering interactions. Times below are approximate scene ranges.

## Implemented interactions

| Video evidence | Implementation |
| --- | --- |
| 00:14–00:18: examine defective solar bases, unsecure/remove panels, repair bases and secure replacements | Persistent solar mounts with physical panel items; screwdriver removal/fastening; a three-second fueled weld repairs an exposed defective base. Damage can break the mount and shatter the removable surface independently. |
| 00:20–00:24: collect mirror shards and transport replacement panels | Pink mirror shards retain the destroyed panel's material budget. The Harvester collects ore, shards and panels on activation/movement, and releases its actual contents. Destruction spills collected salvage. Six-panel carts load/unload actual items and spill their contents if destroyed. |
| 00:25–00:27 and around 00:55: area demand, total generation/storage, sample age and array spread status | New station power console with sorted area demand, kW generation, stored/capacity MJ, sample age, solar output and access-controlled Spread/Retract actions. Readouts use a completed grid sample. |
| Around 00:27: FixBoy-2000 | Existing FixBoy art used for an engineering diagnostic with machine/base/wall inspections and a handheld power report. Available in engineering personal lockers and the autolathe. Its exact original hidden functions cannot be established from the recording. |
| 00:29–00:30: equipment charge inserted before retrieving a tool belt | Compatible, consumable restock charges. Ordinary configured stock is restored to capacity; full/wrong machines reject charges. Returned items and restricted/premium stock are preserved. Equipment, coffee, soda, snack and security refills have cargo packs and existing OS13 art. |
| 00:31–00:40 and around 01:34: ask Research for standard/advanced solar replacements | Standard and advanced Replicator designs, distinct research requirements/material costs, and a six-panel cargo shipment. Reclamation remains on the existing Replicator floor tile. |
| Around 01:00–01:10: discuss directional versus full shields and their power demand | Full coverage remains the default. North/South/East/West settings restrict actual shield segments to a 90-degree sector; the existing per-segment upkeep therefore falls with coverage. The control-wire lock applies to direction changes. |
| 01:04:50–01:06:15: choose an area, inspect each vent's pressure/mode, select REFILL/STOP/FILTER for an individual vent or ALL VENTS, and view lockdown settings | The mapped station gas console has a live area/vent screen, individual and all-vent commands, manual lockdown, automatic-lockdown enable/disable and an adjustable station threshold (60 kPa by default). Local modcon chat reports also expose individual/all-vent commands and manual/automatic lockdown controls. FILTER consumes modcon cartridge condition while removing contaminants; REFILL draws from the finite shared reserve. |
| Around 01:42: medical bracelet shows pulse, area and RAD | Worn-bracelet examination reports location, pulse, temperature, body radiation and ambient radiation. |
| Around 01:58: crew signal list retains NOT RESPONDING entries | Crew monitor merges received signals with public manifest names. Missing entries have no position or vitals. Read signals produces a chat report; pulse/radiation/location detail follows sensor level. |

## Alpha placement and use

- Engineering EVA landing: `(56,82,3)`. The west rail at `(55,82,3)` opens onto
  the new service walkway. All 56 solar mounts have a connected adjacent service
  tile. Floors are airless; EVA equipment is required outside.
- Station power console: `(62,80,3)`.
- Cart with six replacement panels: `(60,78,3)`.
- Harvester: `(61,78,3)`.
- OS13 equipment vendor: `(83,88,3)`.
- Atmospherics Control Console: existing station gas console at `(69,106,2)`.
  Choose an area for live vent readings and commands. Its reserve output,
  supply-limit and canister-transfer controls remain available. Engineering or
  atmospherics access is required to change settings; viewing is read-only without
  access. A replacement circuit board is available through research.
- Initial array: 48 working standard panels, four defective bases with intact
  panels, two shattered panels and two empty bases. Repairing intact panels does
  not consume replacements. The six spare panels cover the four missing/broken
  surfaces with two spares left over.

Solar service sequence: examine → screwdriver → empty-hand removal → weld exposed
fault → fit an intact held panel → screwdriver. Retracted panels generate no power.
Retraction protects against glancing impacts; direct impacts can still damage them.

The console requires engineering equipment access for deployment changes.
FixBoy activation prints the current power sample; using it on nearby equipment
reports its mechanical condition. The Harvester's **Release Contents** verb empties
it. Cargo supplies replacement panels, maintenance carts and refill charges.

Atmosphere commands affect only vents belonging to the selected area. Broken or
unpowered vents reject changes; welded vents retain the selected mode but move no
gas. FILTER removes non-oxygen/non-nitrogen gases through the area's modcon filter;
an exhausted or absent cartridge stops filtration. STOP halts gas transfer. Local
air-alarm radio commands take control back from the console. Manual lockdown stays
active when readings recover. Disabling automatic lockdown does not disable manual
lockdown or the independent fire-alarm protection.

At a local modcon, unlock the unit and use its chat report to select REFILL, STOP
or FILTER for one vent or all vents in that area. Commands recheck access,
adjacency, incapacitation and controller condition; stale links cannot become
all-vent commands. The console and local report use the same area command path.

Pump and scrubber grilles use a held, lit welder for two seconds to weld/unweld.
Successful work consumes one fuel unit. Movement, dropping/switching the tool,
or finishing with an unlit/empty tool cancels completion without the task fuel
charge; the welder's ordinary idle consumption remains independent. Only one
weld may run on a vent at a time. Vent gauges display mol/cycle to match the gas
model. Newly built scrubbers initialize their buffer correctly and filter only
once per processing cycle.

## Power integration

This work extends the global grid already present in the working tree. It does
not introduce that grid conversion. The new accounting preserves direct machinery
draw instead of dropping it at reset, retains area-controller samples before their
one-off counters are cleared, and avoids billing their standing demand a second
time. Storage output is excluded from generation and cannot be used to charge
storage again. Stored energy is converted from the existing watt-hour units to MJ.

Area rows show device demand. Total grid demand additionally includes direct grid
consumers and local-controller charging, so the rows need not sum to that total.

## Deliberate tuning and limits

- Standard panel output is **7.2 kW**, inferred from the approximately 43.2 kW
  change associated with six replacements. The **14.4 kW** advanced output,
  three-second solar repair, two-second vent service and one-unit task fuel costs,
  material costs, cargo prices and research requirements are
  implementation choices, not recovered original source constants.
- The new solar array is adapted to Alpha's existing EVA entrance. It does not
  reproduce the reference station layout tile for tile.
- Existing suit/internals, gas-percentage readout, magboots, vent welding, hull
  repair, atmospheric area controls, medical treatment, mining, Replicator storage,
  turbolifts, chat and HUD systems remain the integration base. Their presence is
  not a claim of complete visual or behavioral equivalence to Lifeweb.
- Atmosphere vent readouts show actual kPa. Automatic low-air lockdown deliberately
  retains the project's gas-quantity model: its displayed kPa threshold is converted
  at 20 C. Temperature alone does not change that quantity threshold. A 2 kPa
  recovery margin is local tuning; other existing atmospheric hazard thresholds
  remain active. The video also displays some `FILTER[turbo]` statuses, but the
  upgrade/activation mechanism and exact flow rates remain unverified. Detailed
  frames at 01:05:28–01:05:40 show the mode menu but no turbo activation command.
- The video uses native selection dialogs and chat readouts; the implementation
  uses the existing NanoUI console conventions and OS13 atmosphere-computer art,
  with direct command links in the local modcon chat report.
- The subsequent water-chip-video pass added the ChargeMaster production chain
  and chemistry/beverage refills; see `os13_waterchip_video_parity.md` for its
  compatibility rules and validation.
- Sampling a two-hour recording cannot establish every hidden rule or transient
  action. This implements the identified engineering gaps; it is not certification
  of complete game-wide Lifeweb parity.

## Validation

- BYOND 516.1688: the regression world includes the complete main DME and Alpha
  map; both normal and regression compilation completed with **0 errors and 0 warnings**.
- **Nine runtime suites passed:** solar servicing/deployment; cart/Harvester and
  research material costs; vending refills; power snapshots/storage conservation;
  directional shields/bracelet readings; missing crew signals/sensor restrictions;
  area vent controls/access/lockdown; filtering and finite-reserve refill; timed
  vent and solar maintenance. The atmosphere suites exercise actual gas transfer,
  single-cycle scrubber flow, cartridge exhaustion, welded/stopped vents, local
  modcon authorization, stale references, offline controls and lockdown persistence.
  Real tool handlers verify timed welding/unwelding, task fuel use, concurrent-use
  rejection, movement/drop/tool-shutdown cancellation and interrupted/successful
  solar-base repair.
- `python tools/engineer_video/check_map.py`: validates all 56 mount approaches,
  141 connected walkway tiles, the open EVA connection and five mapped fixtures.
- `node tools/engineer_video/check_templates.cjs`: renders the actual NanoUI
  templates with the shipped engine/helpers, including permitted/denied controls.
- `node tools/engineer_video/check_browser.cjs`: headless Edge renders power,
  shield, crew and atmosphere fixtures without horizontal overflow or undefined values.
  Requires Playwright on the Node module path. Screenshots and runtime logs are
  under `tmp/engineer-video-check/` and are generated validation artifacts.
- `node tools/engineer_video/check_modcon_browser.cjs`: renders the actual local
  report emitted by DreamDaemon, using the shipped chat CSS at 360/500 px. All
  nine vent command links are present, with no horizontal overflow or missing values.
- `python tools/engineer_video/check_runtime.py`: checks all nine suite results
  and scans test-period output for runtime errors independently of BYOND's counter.
- `git diff --check` passes for the working tree.

The regression launch also reports pre-existing startup issues: a null random
spawner at `(138,98,2)`, obsolete power-link helpers and unavailable local databases.
All nine focused tests report zero runtimes, with no runtime-error entries after
`Testing Started`. The continuation log is
`tmp/engineer-video-check/maintenance-runtime-verified.log`. A native Dream Seeker
playthrough and frame-by-frame visual matching remain unverified.
