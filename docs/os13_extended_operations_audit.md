# Extended OS13 audit: Captain, flight, ruins and hostile encounters

The [missing-object continuation](os13_missing_objects.md) supersedes this
audit's stock Scout deployment blocker and portable-beacon absence: a physical
beacon and native rescue approach, plus Classic deployment, now exist. Source
range/authentication/ETA and exact layouts remain unresolved.

See the [source manifest and coverage limits](os13_extended_video_audit.md).
**CAP**, **PIL**, **ALIEN** and **RUIN** identify separate canonical recordings.
Times are sampled visibility times, not necessarily action onsets.
**V** denotes inspected full-resolution evidence; **O** denotes an OCR lead.

## OS13 animated space and parallax

The supplied artwork request identifies `space2` in
[fullscreen4.dmi](../icons/turf/fullscreen4.dmi). Alpha and its OS13 Classic
and recreation map subtypes now use that **native 480 x 480 animated state**
instead of the legacy skybox's `space` state. Its six frames, authored delays
(`250,0.5,0.5,0.5,0.5,0.5`) and rewind are retained; the image is neither
flattened nor rescaled.

The [skybox subsystem](../code/controllers/subsystems/skybox.dm) also composes
three independently moving layers from the complete numbered states in
[stars1.dmi](../icons/os13/mob/mob/HUD/stars1.dmi),
[stars2.dmi](../icons/os13/mob/mob/HUD/stars2.dmi) and
[stars3.dmi](../icons/os13/mob/mob/HUD/stars3.dmi). Their native animations
remain intact. Each depth contains one instance of each of its 11, 15 or
20 states per repeating 480-pixel field. MD5-derived positions keyed by
z-level, depth and state keep the field stable across movement, camera changes
and reconnects, and consistent between clients viewing the same z-level.
All 32-pixel stars fit inside their field, rather than being clipped at seams.

The [client renderer](../code/_onclick/hud/skybox.dm) moves the nebula and
three star depths by **1, 2, 4 and 8 pixels per world tile**, respectively.
These speeds, density and deterministic placement are local reconstruction
choices, **not recovered OS13 source constants**. The supplied sprite identity
does not establish the original camera algorithm or certify frame-perfect
visual parity.

Each layer tiles beyond both axes of the current viewport, wraps its offset
at 480 pixels, and accounts for the actual client eye and client pixel-view
offsets. Background screen objects stay anchored at `CENTER,CENTER`, retain
`TILE_BOUND`, and apply camera offsets through a translation transform.
Oversized parallax fields therefore do not create HUD borders, change the
client's automatic map scaling, or shift the origin of world render targets.
The wrapped shift is centred to at most 240 pixels, so each layer's
`TILE_BOUND` anchor stays near the screen centre instead of being translated
off-screen and culled, which exposed field edges. Every OS13 layer composes on
`SKYBOX_PLANE`: the nebula draws normally, stars add over it, and a
client-owned plane master multiplies the finished plane onto white space
turfs. Stars can no longer bleed across the screen wherever the world pass is
transparent, and blur effects reuse that master instead of replacing the mask.
The legacy background uses the same bounds-independent positioning.
Immediate login/mob movement hooks remain; a background update every
decisecond catches remote-eye movement, viewport changes and screen resets.
Z changes rebuild the appropriate field. With no world eye the backgrounds
are removed, and disconnect deletes the client-owned depth objects.

The nebula retains the existing multiply composition and `SKYBOX_PLANE`;
stars use additive composition on `STAR_PLANE`, ordered from far to near.
Both remain below world geometry and the blackness plane and are non-clickable.
Alpha's [space appearance](../code/game/turfs/space/space.dm) retains the white
space mask but omits the old randomized dust, avoiding a second unrelated
star/dust layer. Other maps retain their original space/dust appearances and
skybox. Nondefault universe backgrounds still select the legacy renderer;
the star-enable switch is respected in both paths. Subsystem recovery retains
the current scene settings and shared field cache.

Validation used focused source inspection, DMI state/frame metadata and
viewport/wrap geometry calculations. No compiler, Dream Maker IDE or live
client was launched. In-game verification is still required: walk in all four
directions beside a station window, cross wrap boundaries and teleport between
z-levels, move a remote camera, resize to wide/tall viewports, reconnect, and
check an alternate universe background. Confirm that depth layers move at
different rates without rerandomizing, no gaps appear, the native flashes and
star animations play, and floors/walls/unseen areas continue to mask space.

## Startup readiness and wake lifecycle continuation

Reinspected full-resolution **CAP 00:09:30** shows the bridge briefing
discussing failed clone backups, broken solar equipment and the expired water
chip. **GEN 00:00:10** shows the crew discussing the emergency alarm and bridge
assembly. These support the recovery subjects, not a particular diagnostic
table, damage distribution, alarm duration or power threshold.

### Actual supply rather than a breaker setting

The earlier bridge recovery check and Director sample counted a controller
as online whenever its `operating` switch was set. Empty cells, short circuits,
EMP failures, broken/maintenance controllers and controllers with no powered
served areas could therefore look healthy and satisfy the recovery contract.

The shared [power-supply predicate](../code/modules/power/area_smes.dm) now
requires an intact, enabled controller without a short or failure timer, a
nonempty installed cell, and at least one enabled channel actually supplied
to a power-requiring area owned by that controller. The
[bridge objective](../code/game/machinery/computer/testing.dm),
[Director sample](../code/modules/director/telemetry.dm) and
[General Report](../code/modules/os13/os13_wiki_bridge.dm) all use it.
No controllers means unavailable supply data, not a nominal 100% sample.
The [Director's report](../code/controllers/subsystems/director.dm) labels
that absence explicitly and explains the revised metric.

The existing local rule remains **at least 90% for 30 seconds**:
`powered * 100 >= total * 90`, with zero controllers rejected. Losing the
threshold resets the stability window. One supplying channel does not certify
every channel, room, cable or generator; the report says so. This correction
also affects Director power telemetry outside Alpha; it does not change
controller output, repair equipment, or alter the Director's antagonist policy.

### First-briefing readiness

General Report now supplements the historical incident record with current,
station-local inventory:

- Controllers actually supplying power.
- Operational Replicator consoles and distinct installed OS13 technologies,
  read from their real research files. Offline console storage still counts;
  carrying an unimported diskette does not. An empty installed catalogue
  directs science staff to recover and import research rather than implying
  that successful extraction alone unlocked fabrication.
- Intact/linked legacy solar panels, separately from OS13 serviceable mounts.
  OS13 mounts report defective bases, missing/shattered panels and configured
  output using their existing deployment/panel/network checks. Legacy links
  do not prove sunlight/output; configured OS13 output is not stored energy.
- Operational cloning consoles and stored record-entry counts, without
  exposing identities or asserting every entry is complete or cloneable.
- In-progress wake targets, lights started and thermostats reset.

Counts are fresh when the browser is reopened or the existing paper snapshot
is printed. They do not spawn machines, reset data, manufacture repairs or
certify a room as safe. Missing installations are identified explicitly.
This diagnostic layout is a local integration, not recovered source UI.

### Lifecycle and disconnected crew

- Wake-up has a cancellable device timer and an explicit finished state.
  [Round-end handling](../code/controllers/subsystems/ticker.dm) cancels
  unfinished wake work, stops the cryogenic alarm/pulsing, and stops objective
  tracking without deleting completed objective history. Callback guards also
  prevent further wake work outside gameplay. Cancellation releases pending
  fixture startup gates using existing power-change handling; it does not
  change room switch settings or count as successful wake completion.
  The report distinguishes **Interrupted** from **Complete**.
- [Cryogenic startup](../code/game/machinery/cryopod.dm) only uses
  station-located pods to choose pulsing rooms, and only pulses station
  fixtures. It also stops on a non-gameplay callback. Existing five-minute
  alarm and half-second wake-device timings are unchanged local tuning.
- A loyal crew member disconnected during the one-time objective-sheet
  distribution can now receive the missed sheet on
  [human login](../code/modules/mob/living/carbon/human/login.dm).
  The game mode marks delivery ready only when its scheduled distribution
  actually runs during gameplay. Reconnecting before that cannot bypass
  antagonist setup; existing per-mind and antagonist/job/map guards prevent
  duplicate delivery and keep Dynamic's separate policy unchanged.

### Deployment findings and verification limits

Focused DMM inspection used **ordinal, case-sensitive keys**. DMM keys such
as `bV` and `bv` are distinct; a default PowerShell hashtable would conflate
them and produce incorrect placement counts. Classic has a direct station
Replicator console and cloning console, but no direct area-power-controller,
legacy solar-panel or OS13 solar-base placements on its declared station
levels 2-9. These are static placement findings, not a simulated runtime
initialization or proof about an alternate map. The report therefore cannot
honestly promise that Classic's power/solar recovery loop is fully deployed.
No arbitrary replacement power system or machine placement was invented.

The Captain article also describes Cargo Airlock and research-gated RemCom
controls. Their exact target/authority/deployment contracts remain unresolved;
this continuation does not lock every cargo-looking door or treat a named
research datum as a working remote-control device.

Validation uses focused source inspection of channel/area ownership,
callback cancellation, login readiness, project includes, exact proc-header
uniqueness and changed-file whitespace. No unit tests, Dream Maker, compiler
or live BYOND session were used. Manual acceptance still required:

1. Compare General Report before/after importing research and scanning a
   clone record. Duplicate technologies on multiple consoles count once;
   duplicate clone entries remain labeled entries. Offstation equipment and
   unimported diskettes must not inflate station counts.
2. With real configured controllers, verify 9/10 supplying for 30 seconds can
   complete recovery while 8/10 cannot. Interrupt supply during the window.
   Repeat with empty/missing cells, all channels off, short/failure flags,
   broken/maintenance state, and no served power-requiring areas. No-controller
   configurations must show unavailable data and never complete power recovery.
3. Inspect both solar families, including absent, shattered, defective,
   unsecured, retracted and disconnected OS13 mounts. Compare the report with
   the mount's existing output display, not with guessed solar generation.
4. End a round during wake-up. Confirm the alarm stops, pending device callbacks
   do not reset more thermostats, startup gates clear, and interrupted work
   never earns a wake-completion notification.
5. In a traitor-tag Alpha round, disconnect before the scheduled loyal sheet
   and reconnect after it; receive one sheet and stored note. Reconnect again
   and check antagonist/offstation/non-Alpha exclusions. An early reconnect
   must wait for the ordinary scheduled distribution.

## Round-start, story and bridge continuation

### Evidence and scenario boundaries

- **CAP 00:00:00**, reinspected at full resolution, shows the remembered
  Lakamaka transmission: an implant, sabotage, protected databases, Charon,
  Base-7 and a warning that another enemy remains aboard. **GEN 00:00:10**
  OCR/chat context corroborates an emergency alarm and instructions to gather
  on the bridge. These do not identify the current round's antagonist.
- **CAP 00:09:00**, reinspected at full resolution, shows a crewmember reading
  the emergency reactivation date as **23 August 3022**. The surrounding
  briefing discusses six centuries of sleep, inaccessible research, failed
  clone backups, solar deterioration and an expired water chip.
- The archived **Captain** article specifies a reusable **General Report**
  containing station condition information and a player-led bridge briefing.
  The **Orbital Station 13 3022** article supplies the six-century sleep and
  AI self-destruction background. The older **Orbital Station 13** article's
  impending corporate investigation is a different premise; it is not added
  as a second simultaneous opening assignment. The archived **Game Modes**
  page predominantly concerns fortress scenarios, not another OS13 opening.

The new narrative is a concise reconstruction, not a verbatim transcript or
an assertion that the complete original scenario has been recovered.

### Implemented opening flow

- [Job assignment](../code/game/jobs/job_controller.dm) gives Alpha OS13 crew
  a once-per-mind awakening account, their actual role description and
  supervisors, and instructions to attend the bridge briefing. The Captain
  instead receives command-specific General Report, wake-up, investigation
  and research-priority guidance. Both roundstart and latejoin use this path.
  The material is saved in existing character notes as well as chat; duplicate
  equipment/assignment calls do not duplicate it. Generic Nanotrasen
  cryosleep monologues are suppressed only for these Alpha OS13 jobs.
  No starting equipment, spawn locations, implants or role access are changed.
- [Ticker startup](../code/controllers/subsystems/ticker.dm) invokes the
  Alpha welcome after crew creation/equipment and cryogenic startup.
  [The Alpha welcome](../code/modules/os13/os13_video_parity.dm) broadcasts
  the emergency bridge assembly once; later scheduled welcome calls do not
  repeat it. The redundant welcome scheduled by
  [Dynamic](../code/game/gamemodes/dynamic/dynamic.dm) is removed; its parent
  still schedules ordinary map welcomes. Dynamic's hidden antagonist
  selection, delayed awakening and player eligibility remain unchanged.
- The date and six-century revelation are **not** pushed into every player's
  initial memory or the public assembly call. They are recovered through
  [General Report](../code/modules/os13/os13_wiki_bridge.dm), leaving the
  Captain's briefing player-led. Lakamaka's allegation is explicitly an
  account to investigate, not proof against any selected player.
- Alpha's [main console](../code/game/machinery/computer/testing.dm) has a
  repeatable, command-authorized **GENERAL REPORT** browser. Its single
  printable report uses the same content and retains the existing Top Secret
  stamp. Exhausting or losing the paper no longer hides the report.
  The browser refreshes on reopening; a printed sheet remains a snapshot.
  Non-Alpha maps retain the earlier relay-report text and printer behavior.
- The report separates the recovered incident narrative from live wake,
  water-chip, cryogenic-alarm, objective and Director readings. Unavailable
  Director telemetry is stated explicitly. Historical date/incident entries
  do not change the engine's world date, wipe real clone records, damage
  equipment or assert that all historical faults are still present.
- Opening or printing the report issues the existing local recovery goals.
  A single cancellable timer checks progress each second independently of
  whether the Director is enabled. Reopening does not restart the power
  stability window or create another timer; reset cancels it, and processing
  stops after completion or outside gameplay. The 90%/30-second power
  criterion, wake timing, alarm duration and recovery goals are local rules,
  not recovered original mission contracts. No point-scoring backend is added.
- The existing traitor-tag loyal-crew sheet is now restricted to actual Alpha
  OS13 crew, stored once per mind in notes, and also delivered by the
  [latejoin hook](../code/game/gamemodes/game_mode_latespawn.dm).
  Antagonists/offstation roles are excluded. Dynamic has no traitor tag and
  is deliberately not relabeled as the original fixed-traitor scenario.
- Delayed bridge announcements revalidate the original operator's body,
  client, access, proximity, ability and powered console after input. They
  also recheck cooldown, sanitize before committing, and derive the sender
  from the current card only when broadcasting. Empty/oversized submissions
  cannot consume cooldown or send an empty success-shaped announcement;
  concurrent writers cannot overwrite each other's attribution.

### Validation and remaining work

Focused source/include and tracked/untracked whitespace inspection is the
validation for this continuation. No unit tests, Dream Maker, compiler or
live BYOND client were run. Full frame-by-frame coverage and perfect parity
are not claimed.

Manual in-game acceptance remains necessary:

1. Start Alpha with Captain and ordinary crew, then latejoin another role.
   Verify actual-role notes, no generic Nanotrasen wake script, a single
   emergency assembly announcement and unchanged spawn/equipment behavior.
2. Read General Report with and without command authorization. Compare the
   historical date with live fields, print the stamped snapshot, and reopen
   the browser after the printer is exhausted and after repairing services.
3. Disable the Director, issue recovery goals and perform the wake/water/power
   workflow. Reopen repeatedly while the power window runs; confirm one
   completion notification per goal and no updates after round end.
4. In a traitor-tag round, check starting/latejoining loyal crew notes and
   antagonist exclusion. Dynamic must retain its own delayed-antagonist flow.
5. Leave two announcement dialogs open. Broadcast one, then submit the other;
   verify cooldown rejection. Repeat while losing access, moving away,
   changing bodies, disconnecting, losing power, or entering empty/oversized
   text. Rejected submissions must not broadcast or consume cooldown.

Still unresolved: the original scenario's exact initial damage distribution,
full malfunctioning-AI narrative, authored transmissions and timed mission
progression, traitor caches/viruses/bomb objectives, Charon/Base-7/Evergreen
content, mission-dependent lifeboat conditions and scoring/Hall of Fame.
The existing stock-map Scout deployment blocker also remains. The opening
does not create fictitious destinations, an assistant NPC or guaranteed
offstation rescue to disguise these gaps.

## Bridge authority, flight state and raw-material continuation

The archived **Captain** article specifies Today Reports, an approved-document
list with erasure, and command permission for Scout salvage coordinates.
The **Pilot** article distinguishes mining/salvage, satellite, base and distress
destinations. It describes unlocking the controls with a card, not a requirement
to remain strapped into a pilot seat.

Reinspected full-resolution **PIL 00:05:40** shows Scout unlocking and an
89-second launch. **RUIN 00:12:00** shows `We're flying!` on examining Scout
Controls, followed by several launch/sit/rise messages: launch precedes sitting
in the visible chat. These observations support actual flight-state feedback
and removal of the earlier unsupported seat gate on the named controls.
They do not establish an ETA formula or certify every action onset.

### Implemented bridge controls

- [Bridge commands](../code/modules/os13/os13_wiki_bridge.dm) add **Today
  Reports**, **Approved Documents List**, **Erase Approved Documents List**
  and **Salvage Coordinates** to the existing
  [bridge menu](../code/game/machinery/computer/testing.dm), on Alpha only.
  Mutation and report requests require command access, proximity, an
  operational powered console and an able operator. Erasure revalidates
  those conditions after confirmation and is logged.
- [Announcement history](../code/procs/announce.dm) retains the most recent
  100 command/minor-service broadcasts with station timestamps. Reopening
  Today Reports displays stored messages; it does not rebroadcast them,
  synthesize old messages, consume the recovery-report printer, or expose
  administrative logs. This local history includes manually initiated
  service announcements that use those same broadcast datums; it is not
  certified as the source's exact automatic-report classification.
- [Numbered files](../code/modules/os13/os13_investigation.dm) register their
  number and area when initialized on the station. The list materializes
  existing lazy cabinet archives, so it can identify files before they are
  read. It does not expose their evidence or select new traitors.
  Locations are registration snapshots, **not live tracking** of a file or
  its carrier. Erasure removes only the registry, not physical files,
  investigation progress or evidence. Preparing existing cabinets before
  erasure prevents an unopened drawer from immediately recreating the list.
  Newly created files can subsequently register normally.
- Salvage authorization is station-wide and initially allowed to preserve
  existing availability. The starting state and exact original message
  presentation are local choices, not recovered source rules.

### Navigation enforcement and feedback

[Expedition control](../code/modules/shuttles/mining_expedition.dm) checks
salvage permission at mission start, after asynchronous survey preparation
and when dispatching to salvage destinations. It protects revisit and
registered ruin-signal routes as well as the ordinary SALVAGE MISSION link.
The shared generation job retains its actual configured mission type only
after a successful job start; a refused request cannot relabel a previous
salvage field as ordinary mining.

The [mapped shuttle](../maps/alpha/alpha_shuttles.dm) also filters its older
destination catalogue and rechecks authorization at departure. The
[Prospector](../code/modules/vehicles/civ13/mining_shuttle.dm) uses the same
departure policy, closing the pilot-couch and paired-uplink alternatives.
Revocation before departure cancels the queued launch using the existing
redocking path. It does not teleport or reroute a craft already underway.
Mining, satellite and home destinations remain permitted. A new survey
requires the home berth; it cannot regenerate terrain beneath an away craft.

[Scout signal search](../code/modules/os13/os13_scout.dm) omits prohibited
ruin signals and still rechecks dispatch. SOS is a separate registered
destination, not an automatically generated portable-beacon rescue system.
Named local Scout controls continue to require pilot access, proximity and
installation aboard their linked craft, **but no longer require buckling**.
Actual Prospector pilot couches retain their seat-specific controls.

Examining onboard Scout Controls prints `We're flying!` only during actual
transit, followed by current controller status. Satellite, return, revisit and
signal flights now show their real remaining transit ETA, not only generated
mining/salvage trips. Departure, transit and docking have separate status text.
Dispatch reports success only after the backend accepts a launch.
Existing random travel time and craft footprints remain local mechanics.

### Mining and material accounting

The existing Gravcutter -> ore -> Harvester -> Replicator loop remains intact.
[Cargo](../code/datums/supplypacks/supply.dm) now offers a Harvester delivery
crate, providing a normal acquisition/replacement path without an admin spawn
or an invented research technology. Current OS13 Classic has no directly
mapped Harvester or named Scout controls. Its ordinary expedition-console
object is subject to the same salvage policy when linked, but static map
inspection found a more fundamental stock-map deployment gap, detailed below.
Cargo availability/packaging is local integration, not source issuance.
[OS13 ores](../code/modules/mining/os13_mining.dm) now declare one shared
feedstock identity per type: iron supplies steel, zbrite supplies glass and
elerium supplies plasteel. These are existing local aliases, not newly
recovered OS13 material definitions.

[Replicator recovery](../code/modules/research/protolathe.dm) uses the same
full-nugget conversion for hand-fed ore and loose ore reclaimed on the
platform. Previously, platform reclamation applied the ordinary 30% scrap
factor to the same ore that hand-feeding converted in full. Both paths now
yield one `SHEET_MATERIAL_AMOUNT`, require room for the entire nugget, and
preserve the ore on refusal. Upgraded scrap recovery does not multiply raw
ore. Hand-feeding additionally requires a held, removable ore and an able
adjacent operator. Filled/anchored ores cannot be destroyed through this path.
Ordinary manufactured scrap retains its existing recovery factor.

The exact source nugget yield, conversion ratios, deposit distributions,
Gold/Gem Ore roles, Harvester capacity/power and mining radiation are still
unverified. They are not inferred from the three local feedstock aliases.

### Validation and manual acceptance

This continuation uses focused static source/reference, project-include,
mapped-object and whitespace inspection only. No compiler, Dream Maker,
unit tests or live game were run. Compilation claims in older sections are
historical and do not validate this continuation.

Static inspection resolves the bridge at `(125,147,2)`, Replicator at
`(143,101,2)` and reservoir at `(136,107,2)`. The ordinary expedition console
at `(155,141,1)` sits in `/area/space` inside a small staging craft, **not**
`/area/shuttle/mining/station`. The Classic map contains no Mining shuttle
area, home landmark or transit landmark. The existing controller requires
those surfaces to initialize; the console's presence alone does not provide
a usable stock-map Scout. Neither ordinary flight nor the new named controls
are claimed as verified stock-map gameplay. Restoring that deployment needs
a deliberate station berth, craft-area/landmark integration and live movement/
docking checks; no hidden teleport, guessed transport layout or forced
spacecraft spawn was substituted for it in this continuation.

Manual in-game checks remain necessary:

1. Use each new bridge command with/without command access, away from the
   console, while incapacitated and with power lost. Lose access or walk away
   while confirming erasure: no registry mutation should occur.
2. Trigger actual command/service broadcasts and reopen Today Reports from
   two consoles. Verify timestamp order, identical history, the 100-entry
   rolling limit, and no repeated broadcast or printer consumption.
3. Open the document list before opening cabinets. Move/read a file, erase
   the registry, reopen it and inspect the physical file: its contents and
   progress must survive and old entries must not regenerate.
4. Prohibit salvage and try named controls, ordinary expedition menus, the
   old waypoint picker, Prospector couches/uplinks, revisit and ruin signals.
   Withdraw permission during survey and queued departure. No denied launch
   should start. Return home and satellite/mining travel must remain usable;
   an already underway craft must not be stranded.
5. Launch using authorized named Scout controls while standing and seated.
   Examine during preparation, departure, transit and docking; verify truthful
   feedback and a decreasing ETA on satellite and return legs as well.
6. Reclaim one nugget of each type by hand and from the platform, with the
   same starting stock. Compare exact increases, including upgraded machines.
   Try full storage and less than one nugget of free space: nothing is lost.
   Verify compartment locks still prevent fabrication spending but not loading,
   ordinary scrap retains its prior recovery, and collected ores survive
   Harvester unloading before reclamation.
7. Order the Harvester crate, unload and activate the actual collector, move
   it over loose ore and unload it. Confirm the delivery produces the real
   OS13-art machine, not an item or a descriptive proxy.

**Remaining source/runtime blockers:** Cargo Airlock's exact controlled-door
set and lock behavior, research-gated RemCom bridge controls, portable distress
beacons, satellite code authentication, Evergreen/landing module/Charon,
original mission population, stock-map Scout area/berth/transit deployment,
scored objectives and source material balance.
No guessed Cargo door group, fake security exchange, new transport map,
or placeholder RemCom product was added.

## Radar backend integrity continuation

The earlier marshal audit identifies a Radar Console in the bridge melee
sequence around **02:10:12**. This identifies a physical console, not its scan
menu, detection rules or contact classification. The newly inspected frame at
that timestamp shows combat but does not independently establish radar use.

The [local Radar Console](../code/modules/os13/os13_video_objects.dm)
previously always said there were no unidentified contacts, even with no
sensor backend. It now honors inherited machinery-use refusals and reads
the existing [overmap registry](../code/modules/overmap/sectors.dm) and
[ship sensor suites](../code/modules/overmap/ships/computers/sensors.dm).
No link or no operational suite yields an explicit unavailable report.

An available scan uses the longest-range operational suite on connected
z-levels. Suites must be enabled, powered, operable, have positive health/range
and meet their existing vacuum requirement. Contacts are real overmap objects
within that suite's range; the origin, invisible objects (including temporary
deep-space bookkeeping sectors) and transparent objects are excluded. Known
objects use HTML-encoded names; unknown objects are anonymous contacts, not
leaked entity names. Coordinates are live overmap coordinates, not station
floor coordinates or invented destinations. Empty space is reported only
after a valid scan. These display/classification choices are local integration,
not recovered OS13 detection rules.

The OS13 map has a Radar Console but no mapped ship sensor suite and inherits
the disabled-overmap default; this change
does not add an unobserved scanner or enable an overmap by fiat. Such a deployment
therefore honestly reports an unavailable backend rather than claiming that
space is safe. Portable beacons, Scout rescue integration, source range,
authentication and exact UI remain unresolved. Existing OS13 radar/off/broken
art is retained; powered light settings now restore illumination after outages.

Manual checks (not performed): use radar with no overmap link, then with a link
but no operational suite. On an overmap-enabled deployment with existing suites,
place known and unknown contacts inside/outside range, plus an invisible temporary
sector; verify only valid contacts appear and unknown names remain hidden. Disable,
unpower, damage or expose a suite to atmosphere; verify fallback to another
operational suite or explicit unavailability, never a false clear scan. Verify
inherited use refusals and console power-state/light restoration.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Static inspection confirmed null/deleted origin handling, active
sensor eligibility and fallback, actual range scanning, anonymous unknown
contacts, invisible temporary-sector exclusion and the unavailable-versus-empty
report distinction. Radar animation/off/broken DMI states were verified.
Focused whitespace checks passed. No unit tests or live gameplay checks ran;
the overmap-enabled scan branch still needs manual runtime verification.

## Thrown-body wall and window collision prose continuation

The [marshal combat observations](os13_marshal_video_parity.md) include
"hits the Strong Wall!" and "hits the window." The full-resolution
**GEN/AI 00:57:30** frame and event transcript show multiple simultaneous
environment impacts after the meteor warning; collision prose is present
alongside impact injuries. This supports thrown-body collision feedback, not
freeform attacks on walls or all structure types.

The existing [living turf-collision handler](../code/modules/mob/living/living_defense.dm)
now says "hits" and labels simulated walls "the Strong Wall"; dense windows use
their actual name ("the window"). The handler's existing sound, jolt and impact
injury remain intact. The shared structure impact handler now gives thrown
living mobs the same observed "hits [object]" feedback on dense structures
whose throw handling permits a collision; existing structure hit handling
remains intact. Tables have `throwpass` behavior and are not claimed as thrown
body collisions. The marshal finale separately records environment strike
prose for a table; harm-intent hand strikes and item strikes on tables now use
the observed "hits [table]" wording without changing table damage or break
behavior. The pod's identity and collision path remain unresolved. No
additional environmental damage or movement-on-bump behavior is added.

Manual checks (not performed): throw a living mob into a simulated wall,
window, and dense structure; verify the observed labels and unchanged
sound/jolt/injury where applicable. Confirm harm-intent hand and item attacks
on tables print the observed line without changing table damage; ordinary item
impacts still use their own hit handlers, tables retain their throwpass
behavior, and unrelated objects do not receive invented prose from this code
path. Verify low-speed/non-dense collisions continue to be filtered by their
existing callers.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Static inspection confirmed both callers pass a wall/window
atom, the wall subtype gets the observed label, and existing impact effects
remain in place. Focused whitespace checks passed. No unit tests or live
gameplay checks were performed.

## Recorded handcuff application and removal messages

The [marshal arrest sequence](os13_marshal_video_parity.md) records
"swings with handcuffs!", "is trying to put the handcuffs on…", and an
IntenSecure operative "is trying to unhandcuff" another crewmember.
The existing cuff application already requires an aggressive grab, announces
the timed attempt, waits interruptibly on the target, and rechecks the grab
before equipping restraints.

The standard handcuff item's attack now emits the recorded public swing line
before the existing firm-grip check and application sequence. This is limited
to standard handcuffs applied to another uncuffed carbon. Self-cuffing,
clumsiness, cable/tape restraint variants, already-restrained targets,
firm-grip requirements, interrupted timed application, and the post-wait
grab check retain their prior behavior. The line itself does not apply cuffs,
grant a grab, prevent escape or change restraint timing.

The inventory strip interface already exposes an equipped handcuff slot and
removes it through the standard interruptible `do_mob` strip action. That path
now uses the recorded "is trying to unhandcuff [person]!" wording instead of
generic "trying to remove handcuffs". It retains the existing strip delay,
incapacitation/range checks, `mob_can_unequip` veto, success-only unequip,
inventory handoff and audit logging. This is distinct from resisted
self-escape, and does not add a new way to release someone. Cuff-application
struggle feedback and the exact source unhandcuff duration/requirements remain
unverified.

Manual checks (not performed): target an uncuffed carbon while holding standard
cuffs with and without a firm grab; verify the swing line precedes the existing
attempt/refusal, only a valid grab begins application, and losing it during the
timed attempt prevents cuff application. Check self-cuffing, cable/tape cuffs,
clumsy users and already-cuffed targets for unchanged messages/behavior.
In the strip interface, select a handcuffed target's cuff slot with empty
hands; verify the new unhandcuff line, interruption/range failures, and
success-only removal/handoff. Also verify unrelated slots retain their generic
strip message.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Static inspection confirmed the new line is before the existing
grab/application branches and the strip line reuses existing timed unequip
guards without changing restraint state transitions. Focused whitespace checks
passed. No unit tests or live gameplay checks were performed.

## IntenSecure right-hand strike prose continuation

The [marshal combat observations](os13_marshal_video_parity.md) record the
IntenSecure Baton message "neatly beats X's right hand with…". A generic hit
verb loses the observed right-hand action. The video does not establish that
every baton strike or every hit-quality tier should use this wording.

The baton now owns one narrowly scoped formatter for this message. The legacy
item-hit path and GURPS combat path use it only when the IntenSecure Baton
successfully hits the specifically targeted right hand. Other hit locations,
misses, defended/armor-stopped blows, other weapons and other attack styles
retain their existing messages. The formatter changes prose only: attack roll,
damage, armor, wound, stamina, stun, cell, sound, and timing mechanics remain
in their existing combat paths. No unobserved adverb tiers, hand-breaking
chance or arrest effect was invented.

Manual checks (not performed): successfully strike the aimed right hand with
the IntenSecure Baton through both normal item combat and GURPS melee; compare
the log to the recorded phrase and ensure normal injury resolves. Target another
body part, attack with another baton/weapon, miss, defend, or absorb the strike
with armor; confirm original messages and combat outcomes remain unchanged.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Static inspection confirmed both legacy and GURPS paths call the
shared formatter only after successful hits; the legacy branch preserves
redirected-hit wording, and both paths keep their normal armor/damage handling.
Focused whitespace checks passed. No unit tests or live gameplay checks were
performed.

## Back-carry parity gap review

The marshal video at **1:16:00** records the line "X is trying to carry Y on
their back!" The existing mob interaction found in
[`start_pulling`](../code/modules/mob/mob.dm) sets the normal pulling target and
continues to move it behind the puller. The grab system's ladder-carry flag
only controls movement through ladders while a grab is held; neither path
places a person on the carrier's back.

No action was added: the recording establishes an attempt announcement, but
does not establish the needed eligibility checks, timing/interruption rules,
movement arrangement, or release behavior. Treating ordinary dragging as a
back carry would claim parity without reproducing the observed interaction.

## IntenSecure held equipment artwork continuation

Full-resolution **Marshal 02:10:06** confirms the "IntenSecure Operative
swings with IntenSecure Baton!" action. The visible operative equipment
family was already identified in the earlier marshal audit; this frame does
not recover exact combat coefficients or every equipment slot.

The [existing IntenSecure baton and armor](../code/modules/os13/os13_video_objects.dm)
now explicitly use the supplied OS13 hand sheets. The baton retains its
inherited `baton` held state and uses the OS13 four-direction `baton` belt
state for its existing belt slot. Visual inspection distinguishes this from
the gold `classic_baton` hand state; `insecure` in the hand sheets depicts
the armor, not a baton. The armor uses that `insecure` state in both hands,
retaining the already-connected four-direction OS13 suit state.

The baton retains its single `insecure_baton` world/item state through power,
cell removal and cell insertion. Existing cell charge, activation, light,
stun/agony effects, hit cost, force, parrying and target-zone handling are
unchanged. The armor retains existing coverage, thermal/electrical behavior,
suit-storage permissions and protection values. No source armor coefficients,
new operative AI, fabrication recipe or role/map issuance is invented.

Manual checks (not performed): hold the baton and armor in each hand and turn
in all four directions. Equip the baton on the belt and armor in the suit slot,
then remove them and verify overlays update. Toggle the baton, remove/reinsert
its cell and exhaust its charge, confirming world/held/belt artwork remains
valid while inherited power behavior still applies. Compare generic equipment
to confirm it retains its own artwork. Exact body alignment, source combat
balance and complete operative loadout remain unverified.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. DMI metadata and sprite previews confirmed the selected states
and four-direction hand/belt/suit coverage; static inspection confirmed inherited
state resolution, suit rendering and unchanged cell/combat paths. Focused
whitespace checks passed. No unit tests or live Dream Seeker checks were run.

## Recorded soda consumption and pouring continuation

Full-resolution **Marshal 02:07:09** shows repeated "Symond Ravnos swallows
a gulp of Diet Cola." Earlier documentation and the local item called it
"Diet Coo"; that was an OCR/transcription error. **Water-chip 01:09:54**
also shows Diet Cola drinking and "Magdalena fills the shot glass from Pepsi."
These are other characters' actions visible to the recording player, not just
private messages to the consumer.

The [Diet Cola product](../code/modules/os13/os13_video_objects.dm) now uses
the verified name while retaining its existing `dietcoo` type path for reference
compatibility. Diet Cola and Pepsi use the supplied four-direction `cola` hand
states in both OS13 hand sheets. Pepsi retains its distinct `pcola` world/item
state; the hand sheets do not supply a separate `pcola` state, so shared cola
hand art is a local mapping, not a certified exact Pepsi overlay.

[Drinking](../code/modules/reagents/reagent_containers/food/drinks.dm) now
selectively emits the observed public gulp message for Diet Cola, retaining
the existing private feedback and achievement handling. The closed-can,
empty-container and mouth/coverage refusals remain before consumption feedback.
Actual reagent ingestion, cooldown, thirst and drinking sound are unchanged.
Other drink types retain their existing private messages.

[Pouring](../code/modules/reagents/reagent_containers.dm) selectively emits
the observed public filling message for Pepsi only after a positive actual
transfer. The pouring player still sees the measured transferred quantity;
closed cans/targets, empty cans and full glasses do not emit success prose.
Existing transfer amount selection, reagent conservation, mixtures and sounds
are unchanged. Other containers retain their existing private transfer feedback.

Both products still use the existing 30-unit cola fill and 40-unit can capacity.
The name "Diet Cola" is not evidence for zero calories or a different formula:
exact ingredients, dose, nutrition, source timing, vendor supply and body/art
alignment remain unresolved. No vendor catalogue or map placement is invented.

Manual checks (not performed): open Diet Cola and drink with an observer nearby;
verify one public action and one private message per permitted gulp, real contents
decreasing, mouth-cover refusal and empty/closed-can refusal. Pour Pepsi into an
open shot glass and compare measured loss/gain; retry with a full or closed glass
and an empty or closed can. Confirm refused transfers produce no filling message.
Inspect both held sprites and compare generic drinks/containers for unchanged
private feedback.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Static inspection confirmed both four-direction hand states,
actual transfer-result gating, existing can/mouth/empty/capacity refusals,
unchanged ingestion and achievement handling, and default-off announcement
flags for other products. Focused whitespace checks passed. No unit tests or
live Dream Seeker verification were performed.

## Atmospherics Reports telemetry continuation

**CAP 00:29:50, V** confirms "Nash Ampert unlocks the Atmospherics Reports
Console!" in the full-resolution frame. The preceding lock refusals are also
visible, but their individual targets are not established by this frame.
It does not establish the report's exact format or department permission matrix.

The [existing console](../code/modules/os13/os13_video_objects.dm) now honors
inherited machinery interaction refusals before unlocking or producing reports.
Its local engineering access requirement, persistent unlocked state and observed
unlock announcement remain unchanged. No personal ownership or relocking rule
is invented.

Pressure now uses the [actual gas-mixture pressure](../code/modules/xgm/xgm_gas_mixture.dm),
including temperature and volume, instead of converting gas quantity to pressure
at a fixed nominal temperature. Reports use operational station air alarms only;
broken or unpowered sensors cannot supply apparently live telemetry. Another
working alarm in the same area can still provide the sample. Deduplication uses
area identity, so distinct areas sharing a name are not silently merged. Names
are HTML-encoded, the existing 30-area limit is retained, and the omission marker
appears only when another valid area sample exists. No operational samples
produce an explicit unavailable-telemetry message, not a fabricated safe reading.

The original OS13 on/off/broken console states remain. Powered illumination now
uses the inherited computer light settings and returns after a power outage.
The report remains a local read-only snapshot, not recovered source history,
an area-wide average, or a reproduction of the original menu.

Manual checks (not performed): try authorized/unauthorized use while locked,
then attempt use while lying down, incapacitated, under maintenance, broken
or unpowered. Change room temperature without changing gas quantity and compare
the report with a pressure gauge. Disable one alarm, then all alarms in an area;
verify a working fallback and absence of offline readings. Check distinct
same-named areas and exactly 30 versus more than 30 valid samples. Cycle console
power and verify the OS13 state and illumination recover.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Focused static inspection confirmed inherited refusal handling,
gas-mixture pressure use, operational-sensor filtering, fallback/deduplication
ordering, the 30-entry boundary and light restoration. Focused whitespace checks
passed. No unit tests or live Dream Seeker checks were performed.

## Tri-Net EVA fabrication continuation

The [Tri-Net suit and helmet](../code/modules/os13/os13_video_objects.dm)
now have separate replicator designs producing the existing functional
equipment rather than renamed generic replacements. This connects the
recorded EVA equipment family to the local fabrication loop; the footage
establishes physical gear, not these recipes.

Both designs require Material 2 and Engineering 2. Helmet cost is 2000 steel
and 1000 glass; suit cost is 5000 steel and 1000 glass. These are **local
fabrication choices**, not recovered OS13 costs or research dependencies.
Each item's material content matches its recipe, so existing production
efficiency adjustment and reclamation use consistent quantities.

The existing replicator checks power, compartment locks and available stock
at completion, consumes actual resources and creates the exact Tri-Net type.
Existing item/head/suit/hand artwork, integrated helmet light, protection,
slowdown and equipment restrictions remain unchanged. No guessed map
placement, role loadout or broken-helmet repair rule is introduced.

Manual checks (not performed): unlock the designs, fabricate each with enough
stock and verify material deduction and exact item identity; try inadequate
stock or lock a compartment during production and verify no free output.
Equip the products, inspect all facing directions and toggle the helmet lamp.
Reclaim a loose product and compare material returns with the machine's
existing efficiency rules. Source recipes and live gameplay remain unverified.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Static inspection confirmed automatic research-design discovery,
unique design IDs, exact output types and matching recipe/item material content.
Focused whitespace checks passed; no unit tests or live gameplay checks ran.

## Tri-Net helmet light artwork continuation

The [Tri-Net helmet](../code/modules/os13/os13_video_objects.dm) already
inherits a working helmet light. Its lit appearance previously used generic
helmet-light overlays over OS13 artwork. The supplied OS13 item and head
sheets have an integrated `tspacehelmetL1` lamp-on state; visual inspection
of the item states confirms a lit lamp. That state now follows the existing
`on` flag for world and worn appearances.

The existing unlit `tspacehelmet` state is preserved, as are inherited
`s_helmet` hand states, actual emitted light, toggle messages, brightness,
equipment checks and action buttons. The alternate `tspacehelmetL0` lamp
housing is not substituted for the observed default helmet. Exact source
lamp attachment, activation and brightness rules remain unverified.

[Headwear rendering](../code/modules/clothing/clothing.dm) now respects a
null light-overlay setting: integrated-art helmets can opt out of generic
light overlays without disabling their actual light. Other headwear keeps
its existing non-null overlay and rendering behavior. No global light cache
is cleared and no duplicate OS13 lamp overlay is added.

Manual checks (not performed): wear a Tri-Net helmet and toggle its light;
verify real illumination and integrated OS13 lamp artwork; turn it off and
confirm original art returns. Check both held states and helmet/mask clipping,
then compare ordinary space helmets and hard hats to ensure their existing
light overlays remain.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Lit/unlit item and four-direction worn states, existing light
emission/toggle paths and the null-overlay opt-out were statically inspected.
Only Tri-Net currently opts out. Focused whitespace checks passed. No unit
tests or live Dream Seeker verification were performed.

## Harvester collection and unloading continuation

**OVR 00:52:00, V** names the Harvester beside the replicator and shows
discussion of its contents and recycling. This confirms the physical
collection/reclamation workflow, not exact capacity or collection categories.

The existing [Harvester](../code/modules/mining/os13_mining.dm) now retains
the observed capitalized name and handles collection/unloading using snapshots
of actual item contents. Movement callbacks can remove or relocate items:
only live items still on the destination turf are scooped, and only items
actually inside the Harvester are added to its collected list afterward.
Unloading reconciles that list with real remaining contents rather than
unconditionally clearing it. A failed/partial release reports failure rather
than claiming everything was released.

Power toggling requires an adjacent, capable, unrestrained user. Unloading
also rejects incapacitated users explicitly, extending its existing human,
restraint and adjacency checks. These are local physical-interaction safety
rules, not recovered source skill/access restrictions.

The existing powered-movement collection set (ore, material shards and solar
panels), power states, OS13 artwork, destruction cleanup and actual ground
release remain. No guessed scrap class, automatic replicator transfer,
capacity limit, wider item collection or new resource conversion is added.
Exact source unloading input, categories, capacity and recycling rates remain
unresolved.

Manual checks (not performed): power on over eligible items and pull across
several piles; confirm all actual collected items are counted; remove an item
and re-examine; release the rest and check each item on the floor and an empty
readout. Check anchored/ineligible items remain, power-off movement does not
collect, and incapacitated/unreachable operation refuses. Destroy a loaded
Harvester and confirm salvage survives.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Movement callbacks, collection commit checks, unloading and
physical-use guards were statically inspected. No unit tests or live Dream
Seeker verification were performed.

## TNC Gravcutter identity and fabrication

**ALIEN 00:11:30, V** directly shows the TNC Gravcutter examination label,
its item icon and a damaged-weapon repair notice. The existing
[OS13 mining tool](../code/modules/mining/os13_mining.dm) now uses that
observed name and has a replicator design producing the same functional
item already supplied by miner lockers.

The existing OS13 `gravcutter` world and four-direction left/right hand art
remain unchanged. The design uses the tool's existing origin-tech thresholds
(Material 4, Phoron 3, Engineering 3) and material content (2500 steel,
1000 plasteel). These are **local mappings**, not recovered source costs
or proof that source elerium equals plasteel.

Existing instant standard-path mining, excavation amount, tool sound,
wall interaction and ore production remain unchanged. This does not
implement source charge, weapon wear, repair or combat modes: a visible
damage notice is not enough to recover damage thresholds, repair tools,
costs or durability effects.

Manual checks (not performed): fabricate and compare against the miner
locker tool; confirm TNC name and both held states; cut an eligible mineral
tile and compare output/instant excavation; verify other pickaxes and the
existing wall-cut path remain unchanged. Source repair/charge and mining
coefficients remain unresolved.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Source frame, item/both-hand DMI states, same-tool locker
supply, recipe mappings and standard instant-mining branch were inspected.
Focused whitespace checks passed. No unit tests or live Dream Seeker checks.

## FixBoy supply and held-art continuation

**PIL 00:09:30, V** directly shows the FixBoy-2000 examination label and
its red diagnostic-device icon. This confirms identity, not a source
repair action or numerical diagnostic rules.

The existing [FixBoy tool](../code/modules/power/engineering_monitor.dm)
now has a replicator design in addition to its existing engineering-locker
and autolathe supply. The design produces the same functional tool, not a
second diagnostic implementation. Engineering 1 and Data 1 are local
requirements; 500 steel/500 glass matches the existing tool's material content.

OS13 `multitool` left/right hand states are a documented local mapping;
the supplied hand sheets do not contain a named FixBoy state. Existing OS13
world art and belt compatibility are retained; exact belt/held visual parity
remains unverified.

Power-report self-use now requires a capable user holding the actual tool.
Target diagnostics also require an actual hand before beeping/reporting.
This closes the unheld-report path without altering the completed grid sample,
wall damage checks, solar-base examination, machinery power/fault checks or
unsupported-target feedback. The tool does not repair equipment or claim
source-specific functions that were not recovered.

Manual checks (not performed): fabricate; compare with locker/autolathe tools;
read the report from each hand and compare with station power control; inspect
a wall, solar base and powered/unpowered machinery. Attempt unheld and
incapacitated self-use and confirm refusal without a report. Check both held
states. Exact source UI, permissions, hidden functions and recipe remain open.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Source frame, OS13 held states, existing report/diagnostic
branches, supply paths and pre-report hand/capacity checks were inspected.
Focused whitespace checks passed. No unit tests or live Dream Seeker checks.

## Emergency oxygen tank product integration

**ALIEN 00:45:40, V** shows examination of "emergency oxygentank" with a
small blue cylinder icon. This confirms a physical emergency item distinct
from the full Air Mix tank and oxygen jetpack. It does not reveal the
original gas capacity, regulator pressure or a remaining-gas message.

The [OS13 emergency tank](../code/modules/os13/os13_video_objects.dm) now
inherits the real emergency oxygen tank, retaining its small size, belt slot,
oxygen fill, tank selection, airtight-mask/helmet checks, gas consumption,
refilling and pressure/temperature handling. The source's examination spelling
is retained for the physical item. OS13 `emergency` item, both hand and belt
states are connected. No absent generic gauge state is requested from the
OS13 tank sheet; actual gas remains inspectable through ordinary examination.

Volume 2 and three-atmosphere filled oxygen are inherited local values,
not recovered source calibration. The existing remaining-gas percentage and
regulator are unchanged. An empty replicator product costs 500 steel at
Material 1 (local mappings) and explicitly says it needs filling; fabrication
does not generate free oxygen. No guessed issuance, map placement, special
synthetic handoff or automatic rescue behavior is added.

Manual checks (not performed): fabricate, verify empty contents, name and
OS13 item/hand/belt art; fill with oxygen using existing atmospheric equipment;
select it as internals with a Breath Mask and verify depletion/refill. Move
between hands and belt, pass it to another player, and check overlay removal.
Compare generic emergency tanks to confirm unchanged capacity and behavior.
Source capacity, belt alignment and exact readout remain unverified.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. All four OS13 item/hand/belt states, emergency-tank inheritance,
empty initialization and selected-tank seal/consumption paths were statically
inspected. Report-anchor and whitespace checks passed. No unit tests or live
Dream Seeker verification were performed.

## Magnetic Boots product integration

**PIL 00:04:20, V** visibly identifies Magnetic Boots separately from Space
Suit Boots. This establishes the item identity, not its source activation,
slowdown, grip strength or protection coefficients.

The [OS13 product](../code/modules/os13/os13_video_objects.dm) now derives
from the existing [magboots](../code/modules/clothing/shoes/magboots.dm).
Activation changes the real mag-pulse flag and NOSLIP flag, updates movement/
floating state and uses the existing shoe-grip check. Ordinary undershoes
are retained inside the boots and restored on removal through the parent
equipment path. No parallel movement or shoe-storage implementation is added.

OS13 `magboots`/`magboots1` item states follow disabled/enabled traction.
The parent uses a `magboots0` item suffix absent from the supplied OS13 item
sheet; this subtype disables that naming rule and sets the correct state.
Both OS13 hands use `jackboots` as a local mapping. Worn art retains the
generic paired `magboots0`/`magboots1` states, including the slim-body sheet:
the supplied split-foot OS13 sheets are not incorrectly used as a full pair.

Existing slowdown (+3 when active), force (3/5), knife storage, overshoe
behavior and clamp sound are inherited local rules, not source-certified.
Material 2, Magnets 2 and 2000 steel are local fabrication mappings. No
guessed placement or loadout changes are made. These magnetic boots remain
distinct from the nonmagnetic Space Suit Boots.

Manual checks (not performed): fabricate; toggle in each hand and worn,
checking item/paired worn states and feedback; equip over ordinary boots and
remove, checking undershoe restoration; compare zero-gravity grip on/off and
walking slowdown; confirm generic magboots retain original art and behavior.
Exact source worn art, activation conditions and grip coefficients remain open.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. OS13 item states, both held mappings, normal/slim paired worn
states, activation/slowdown, shoe-grip and undershoe restoration paths were
statically inspected. Focused whitespace checks passed. No unit tests or live
Dream Seeker verification were performed.

## Oxygen jetpack product integration

The recorded Jetpack (Oxygen) family (FLT-03; EXP-01/03) now has an
[OS13 product](../code/modules/os13/os13_video_objects.dm) derived from the
existing oxygen jetpack. It inherits real gas storage, internals, thruster
toggle, stabilization, ion trails and gas-consuming movement. The existing
human movement path requires it on the back; holding it does not grant thrust.

OS13 `jetpack0`/`jetpack1` world and back states follow the actual on/off
flag. Both hands use the supplied OS13 `jetpack` state. The generic parent
toggle uses an `-on` suffix, absent from this sheet; a subtype update restores
the correct OS13 state, while back-state selection reads the flag directly.
Repeated toggles and normal tank processing cannot leave an invalid sprite.
Generic jetpacks and rig propulsion remain unchanged.

The replicator produces an empty unit requiring real filling. Material 2,
Engineering 2 and 3000 steel are local fabrication mappings. Inherited
70-volume/six-atmosphere oxygen fill, gas use, stabilization and trail effects
are not certified source coefficients. Examination retains actual remaining
gas and low-gas warning; no recovered source readout wording is asserted.
Source damage/repair, exact thrust/trail art and issuance remain unresolved.

Manual checks (not performed): fabricate, confirm empty and no thrust; fill
with oxygen, equip on back, toggle thrusters and stabilization, move in zero
gravity and check falling gas. Inspect item/back art during repeated toggles
and processing, both hands, low-gas behavior and removal. Compare generic
oxygen and rig jetpacks to confirm unchanged behavior.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. All six item/hand/back sprite states, inherited toggle/trail
handling, back-slot propulsion checks and real gas removal were statically
inspected. Focused whitespace checks passed. No unit tests or live Dream
Seeker verification were performed.

## OS13 Air Canister and oxygen-tank sprite integration

The supplied `icons/os13/objects/objects/canister_new.dmi` contains ten states:
the complete idle `air_canister`, five complete animated canister bodies
(`air_canister0`, `25`, `50`, `75`, `100` suffixes), and four small inserted-tank
overlays (`emergency`, `big`, `jetpack`, `oxygen`). The latter occupy the
canister's tank socket; they are not full-size handheld tank artwork.
**ALIEN 00:30:30 and 00:51:10**, inspected at full resolution, show the named
Air Canisters in EVA. These samples establish identity and silhouette, not
the exact original fill thresholds or interaction timing.

[OS13 objects](../code/modules/os13/os13_video_objects.dm) now include
`/obj/machinery/portable_atmospherics/canister/air/os13`. It preserves the
existing fixed station-air filling-point behavior: a held tank is inserted,
the processing loop transfers real gas from the shared station reserve, and
empty-hand use retrieves the tank. The machine is available through a
separate [OS13 Air Canister supply order](../code/datums/supplypacks/atmospherics.dm).
The existing generic air-canister order and other maps' types are unchanged;
no map location is invented.

The display uses the inserted tank's existing nominal-fill percentage:

| Inserted-tank percentage | Complete canister body |
| --- | --- |
| 0 through below 25 | `air_canister0`, two frames |
| 25 through below 50 | `air_canister25`, three frames |
| 50 through below 75 | `air_canister50`, four frames |
| 75 through below 100 | `air_canister75`, five frames |
| 100 (including clamped overfill) | `air_canister100`, two frames |

With no inserted tank it uses `air_canister`. Destroyed/broken units use the
lowest indicator state without an inserted-tank overlay; the sheet has no
dedicated broken state. These meter animations are not proof gas is currently
flowing: source loss, a disabled reserve or the inherited pressure cap can
stop refilling independently of the tank's existing charge. Examination
reports missing reserve gas and the actual inserted tank/readout.
Gas analysis on the new filling point reads the same reserve mixture used
for refilling rather than the unused local canister vessel. With no reserve,
the existing analyzer reports that it cannot analyze the source.

The overlay is `jetpack` for jetpacks, `emergency` for emergency tanks,
`oxygen` for yellow oxygen tanks and the yellow OS13 oxygen/Air Mix products,
and `big` for remaining tank types. Each is drawn at its authored socket
coordinates over the complete body, with no repositioning, generic canister
overlays, or whole-body emissive glow. Native animation delays are retained.
Handheld and worn equipment keep their existing full-size sheets. A tank
leaving the socket through another path clears the reference and overlay,
preventing remote refilling or deletion through a stale held-tank reference.

A separate `/obj/item/tank/oxygen/os13` now connects existing full-size
OS13 `tank.dmi` oxygen art and matching left/right/back art to **pure oxygen**
tank initialization and its oxygen regulator. It is not an alias of
`/obj/item/tank/air/os13`, which retains its actual oxygen/nitrogen mixture.
The new replicator design creates an **empty** tank; the separate oxygen-tank
supply crate contains three filled ordinary OS13 oxygen tanks and three
existing OS13 emergency oxygen tanks. Existing emergency-tank and jetpack
products keep their actual capacities, equipment slots, gas consumption,
on/off back art and designs.

**Local behavior, not recovered source constants:** inherited volume and
starting pressures, a nominal-mole-based percentage with the existing
rounding/clamping, quarter-fill display thresholds, supply contents,
Material 1/2000 steel empty-tank recipe, shared station-reserve lookup,
automatic refill rate and the existing ten-atmosphere refill cutoff.
The Air Canister supplies the reserve's actual mixture, not pure oxygen and
not automatic purification. Filling a pure-oxygen tank there can therefore
mix its contents; use a genuine oxygen source when pure oxygen is required.
Tank leakage, regulator, reactions and pressure/temperature failures remain
the existing mechanics. No new damage or repair behavior is inferred.

Static validation covers every sheet state/frame count, all four composed
socket overlays, nominal-fill threshold boundaries, type/include/design/
supply wiring, gas-transfer inheritance, removal cleanup and whitespace.
No compiler, unit tests or live game were run for this change. Perfect visual
and gameplay parity remains unverified.

Manual in-game acceptance, not yet performed:

- Order/unpack the filling point; insert empty, partial and full tanks of each
  supported family. Compare socket alignment and all fill animations against
  the supplied sheet. Confirm retrieval restores full-size hand/worn art.
- Watch real gas enter a tank while the station reserve loses gas. Disable or
  drain the reserve and confirm filling stops without manufacturing gas;
  restore supply and confirm it resumes. Check nominal 0/25/50/75/100 display
  boundaries separately from the inherited refill pressure cutoff.
- Move an inserted tank out by another game mechanism and confirm the socket
  clears and it receives no remote refill. Destroy the machine and confirm
  its inserted tank is ejected according to inherited canister handling.
- Fabricate the new oxygen product and confirm it is empty; check the filled
  supply product contains oxygen, while Air Mix contains oxygen/nitrogen.
  Exercise ordinary breathing, emergency belt use and jetpack thrust to
  confirm the artwork does not change the actual gas or equipment behavior.
- Confirm ordinary non-OS13 canister/tank types and their supply orders retain
  their prior sprites and behavior.

## Gas Tank Air Mix integration

**ALIEN 00:43:10, V** explicitly shows Gas Tank (Air Mix) examination with
"Air mixture left: 89%". **PIL 00:20:00, V** lists the same item separately
from the suit, boots and mask. These establish physical media and a remaining
gas readout, not the original volume, pressure or gas ratio.

The [OS13 tank product](../code/modules/os13/os13_video_objects.dm) now
inherits the actual mixed-air tank: oxygen/nitrogen initialization, selected
internals, regulator, gas consumption, atmospheric refilling, leakage and
pressure/temperature failures remain in the existing tank system.
[Tank examination](../code/game/objects/items/weapons/tanks/tanks.dm) uses
a small overridable message helper so this subtype reports the observed
"Air mixture left" wording without a second, conflicting percentage.
Other tank types retain their existing wording and percentage calculation.

OS13 `oxygen` item, both hand and back states are connected. The source
sheet has no generic tank indicator states, so this product does not request
those nonexistent gauge overlays; examination still shows its real contents.
Capacity 70, starting pressure six atmospheres and the inherited standard
oxygen/nitrogen ratio are local tank rules, not source measurements.
The percentage is total remaining gas moles relative to nominal fill, not
oxygen purity; existing 0-100 clamping and minimum nonempty 1% are preserved.

A replicator design produces an **empty** tank for real atmospheric filling,
not free breathable gas. Material 1 and 2000 steel are local recipe mappings.
The filled subtype remains available for authored placement, but no guessed
map or loadout changes are made. Exact damage wording, worn alignment,
source filling economy and assembly-overlay artwork remain unverified.

Manual checks (not performed): fabricate and confirm 0%; fill with air using
existing atmospheric equipment; examine and consume through a selected
internal tank with a Breath Mask; check falling percentage and empty-tank
behavior. Move through both hands/back and compare art; verify ordinary
oxygen/air tanks retain their original readout and regulator behavior.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. OS13 item/hand/back states, empty initialization and nominal
fill fallback, mole-based readout, real removal/refill and pressure-failure
paths were statically inspected. Focused whitespace checks passed.
No unit tests or live Dream Seeker verification were performed.

## Breath Mask product integration

**PIL 00:20:00, V** lists Breath Mask separately from the suit, boots and
air-mix tank. The [OS13 EVA objects](../code/modules/os13/os13_video_objects.dm)
now include this named physical product and a replicator design.

It inherits ordinary breath-mask mechanics: airtight/flexible flags, face
coverage, the mask slot, gas transfer 0.10 and permeability 0.50. The existing
[breathing path](../code/modules/mob/living/carbon/breathe.dm) supplies air
only from an accessible selected internal tank with an airtight seal.
The mask does not generate oxygen, add a filter, or enable internals simply
by being held. Those coefficients are inherited local values, not source
measurements. Generic breathing masks and other maps' equipment are unchanged.

OS13 `breath` item/worn states are connected to the supplied mask sheets.
Both OS13 hands use `m_mask` as a local held-mask mapping, not certified
Breath Mask hand art. Existing helmet clipping recognizes the subtype through
its breath-mask ancestry; no second worn-overlay or internals path is added.
Material 1, 500 steel and 250 glass are local fabrication choices. No guessed
starting loadout, map placement, pull-down action or source refill rule is added.

Manual checks (not performed): fabricate and equip the mask; inspect both
hands and worn art in all directions; select an air tank and enable internals;
verify tank consumption and removal/disconnection behavior without an
airtight helmet. With a Tri-Net helmet, check clipping and removal: that
helmet may legitimately retain a seal after removing the mask. Exact source
art alignment, tank compatibility and numerical protection remain unresolved.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Item, both hand and four-direction worn states, slot-state
precedence, tank/seal checks and helmet-clipping ancestry were statically
inspected. Whitespace and report-anchor checks passed. No unit tests or live
Dream Seeker verification were performed.

## Tri-Net EVA held-art continuation

The [Tri-Net suit and helmet](../code/modules/os13/os13_video_objects.dm)
now use the supplied OS13 left/right hand sheets as well as their existing
OS13 world and worn sheets. Both sheets contain the inherited `s_helmet`
and `s_suit` slot states. Keeping those inherited slot overrides is important:
the worn `tspacehelmet`/`tspacesuit` names are not handheld state names.
No generic or nonexistent held state is substituted.

This is an asset-wiring correction, not a recovered grip or equipment rule.
Pressure/temperature protection, suit slowdown, camera/light behavior,
equipment slots and existing worn art are unchanged. Manual checks (not
performed): move each item through both hands, equip, unequip and drop it;
inspect all four facing directions and confirm no stale overlays remain.

**PIL 00:20:10, V** additionally confirms the Broken Tri-Net Space Helmet
name and examination art. The archive contains matching broken item/head
states, but the reviewed scene does not establish the break trigger, lost
protection, repair process or light behavior. Those mechanics remain
unimplemented rather than assigning speculative damage/repair rules.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. All four inherited hand-state/OS13-sheet combinations have
four directions. Slot-state precedence, whitespace and report anchors were
checked statically. No unit tests or live Dream Seeker verification.

## Pocketwatch continuation

**CAP 00:02:10, V** shows Pocketwatch examination, "Alas, it's 3:07." and
the character looking at their watch. The supplied OS13
`personal.dmi:watch` gold timepiece matches the visible inventory art.

The [Pocketwatch product](../code/modules/os13/os13_video_objects.dm) now
reads the real station clock on examination and held self-use, with a visible
looking-at-watch message on self-use. Examination respects the parent's
five-tile range rule (observers remain exempt); self-use requires an actual
hand and a capable user.
It does not display the recorded 3:07 as a fixed value or use wall-clock time.
The existing clock's zero-padded hours/minutes format is retained.

The item is tiny and fabricatable at Material 1 for 500 steel, a local supply
mapping. OS13 `card` held states are a local small-object fallback, not
certified watch-in-hand art. No alarm, wrist slot, independent clock drift,
setting controls or guessed starting-loadout placement is invented.
Manual checks (not performed): fabricate, examine and self-use in both hands;
compare with PDA station time; let the minute advance and check again; verify
incapacitated/unheld self-use rejection and out-of-range examination behavior.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Source frame, OS13 watch art, clock helper and examination/
hand-use paths were inspected. No unit tests or live gameplay verification
were performed.

## Space Suit Boots product integration


**PIL 00:20:00, V** lists Space Suit Boots separately from Tri-Net Space Suit,
Gas Tank (Air Mix) and Breath Mask in a physical pickup menu.
The [OS13 object module](../code/modules/os13/os13_video_objects.dm) now
provides this distinct footwear item and a replicator design.

It uses the supplied OS13 `spaceboots` world/inventory state and the OS13
left/right `jackboots` held states as a **local mapping**. The worn overlay
currently uses existing generic jackboots art: the supplied OS13 foot sheets
are split left/right and have no verified `spaceboots` state. No single-foot
sheet is incorrectly assigned as a complete pair.

The ordinary footwear ancestry supplies the feet slot, body coverage,
transfer, removal and blood overlays. Foot cold protection uses the existing
jackboot temperature threshold as a local choice; source protection values
are unknown. No magnetic toggle, NOSLIP, armor bonus, pressure-seal bonus,
knife pocket or overshoe behavior is invented. Material level 2 and 1000 steel
are local recipe mappings, not recovered source costs. No guessed map
placement or starting-loadout changes are made.

Validation: normal command-line Interpost-Hague compilation passed with
**0 errors, 0 warnings**. Footwear inheritance and OS13 item/held sprite
metadata were inspected. Focused whitespace checks passed. No unit tests or
live Dream Seeker checks were performed.

**Manual checks (not performed):** fabricate the boots; verify the name,
OS13 item and both held states; equip/remove them in the feet slot and
confirm worn/blood overlays update. Wear with a Tri-Net suit and helmet,
compare thermal behavior with ordinary footwear, and verify no magnetic
action or grip bonus appears. Exact worn art, source thermal/pressure rules,
recipe and original issuance remain unresolved.

## Department keycard integration

**SCI 00:09:50, V** shows Medbay Keycard, Scientific Department Keycard and
Bridge Keycard being thrown; the scientific card also hits a character's
upper torso. This confirms physical card identities and impact, not their
complete permission matrix, issuance or damage values.

The [OS13 keycard family](../code/modules/os13/os13_video_objects.dm) now
includes the missing Medbay Keycard with `access_medical`. This is a local
department mapping, not recovered original access data; no command, surgery,
chemistry, genetics or all-access permissions were added.

The inherited ID-card constructor calls `update_name`, which previously
replaced these unassigned department names with "ID card". A family-scoped
override now preserves each subtype's original department label on creation
and subsequent ID-name updates. Generic/personal ID cards retain their normal
name behavior. The family uses the supplied OS13 `keycard`/`keycard2` item
states and `card-id` left/right hand states.

Existing ID and neck/amulet equipment slots, real access lookup from either
hand or worn slot, card transfer, throwing and impact remain inherited.
No department item is made freely fabricatable, spawned at guessed map
coordinates or substituted for personal crew IDs. Source issuance,
department-specific worn artwork and exact thrown damage remain unresolved.

Validation: normal command-line Interpost-Hague compilation passed with
**0 errors, 0 warnings**. Constructor/name dispatch, both-hand and worn-slot
access lookup, item/held DMI states and existing equipment behavior were
statically inspected. Focused whitespace and audit-anchor checks passed.
No unit tests or live Dream Seeker verification were performed.

**Manual checks (not performed):** create each named OS13 keycard and confirm
its label and OS13 held art; carry the Medbay card in either hand, then ID or
neck slot, and verify ordinary medical access but no command access; throw
and retrieve it and confirm the name persists. Check ordinary personal ID
naming still follows assignment/rank. Programmed access remains governed by
the existing ID-console rules; the department item's label stays fixed.

## Handheld Radio transmission integration

**MED 00:58:00, V:** chat explicitly reports "Setback. I need to be holding the
radio in my hand." Local speech and successful radio speech are visible in
the same retained chat. The earlier neck-worn radio observation establishes
the item placement, not original frequency or reception-range coefficients.

The [OS13 Handheld Radio](../code/modules/os13/os13_video_objects.dm) now fits
the existing neck/amulet slot as well as the belt. Intentional transmission
requires the actual active or inactive hand and direct ownership. A worn,
stored or dropped radio refuses transmission with the observed message.
Automatic microphone forwarding silently ignores unheld speech, avoiding a
warning for every nearby conversation. Existing listening, power, wires,
frequency, range and telecom behavior remain inherited.

The radio now explicitly uses the supplied OS13 left/right hand sheets and
neck/amulet sheet, each with its four-direction `radio` state. Previously
only its world item used OS13 art; carried/worn overlays fell back to generic
assets. The existing slot renderer handles movement, direction and removal;
no custom overlay, sprite offset, animation or second equipment path is added.
Belt artwork and exact body-type alignment remain unverified.

[Human speech routing](../code/modules/mob/living/carbon/human/say.dm) uses a
held OS13 radio, then the neck-worn OS13 radio, for the common radio prefix
when neither ear contains a radio. Existing ear-radio priority is preserved.
Failed OS13 transmissions do not mark the radio as used: the utterance still
reaches the normal local-speech path without a false talks-into notification.
Left/right-hand radio prefixes retain their original generic-radio behavior.

**Manual checks (not performed):** equip the radio on the neck and receive a
second player's transmission; attempt the common radio prefix while worn and
confirm the refusal and local speech but no outgoing transmission; move it to
each hand and confirm successful transmission; enable its microphone while
worn and verify nearby speech causes neither transmission nor warning spam.
Check powered-off/cut-transmit-wire refusal and ordinary headset/intercom use.
Inspect both hands and neck while facing north, south, east and west; transfer
between slots and drop the radio to check stale-overlay removal. Compare male
and female body alignment against the source before certifying visual parity.

Normal project compilation passed with zero errors and warnings. Exact source
channel selection, body alignment, belt art, propagation range and live Dream Seeker
behavior remain unverified; this is not complete radio parity certification.

## Implemented Scout integration batch

[Scout integration](../code/modules/os13/os13_scout.dm) now replaces the named
Scout Controls' readiness-only response with the existing expedition menu and
actual mission dispatch. The [named console
definitions](../code/modules/os13/os13_video_objects.dm) keep their OS13 art.
[Scout communications](../code/modules/os13/os13_video_parity.dm) keeps the
three recorded command labels but now checks a real shuttle link.

- Terminals aboard an assembled Prospector resolve to that craft's controller.
  Otherwise they use the existing mapped Mining expedition. Local controls
  refuse operation outside the linked craft's shuttle area.
- Local flight controls require pilot/mining access. The later
  [flight-state continuation](#bridge-authority-flight-state-and-raw-material-continuation)
  removes this batch's unsupported seated-operator requirement.
  Onboard communication requires pilot/mining access. Offboard communications
  requires command access and respects the craft's remote-control prohibition.
  These are existing/local permission choices, not recovered source rules.
- Mining, salvage, satellite, revisit, return, cancellation and the remote
  lock reuse existing controller operations. Original generic consoles and
  pilot couches remain unchanged. No second flight state machine was added.
- Distress search lists **currently registered** `nav_mining_sos` and
  `nav_mining_ruin_...` landing signals compatible with the linked shuttle.
  Selection rechecks the live registration, controller, access, power,
  adjacency, busy state and landing validity before actual dispatch.
  Missing signals produce the legitimate empty-result message.
- This search does not allocate new worlds, invent contacts, invoke the
  unused timed beacon-template factory, or claim to find portable worn
  beacons. Ruin landing signals are explicitly identified as such.
- LAST MESSAGE includes real controller status. Transmit Security Code now
  acknowledges the access-validated actual uplink; it does **not** fabricate
  satellite authentication or a successful original code exchange.
- Inputs and navigation hyperlinks revalidate permission, operational power,
  proximity and current craft binding; moving a terminal during input cannot
  silently redirect a request to a different craft.

**Remaining parity gaps:** exact Scout footprint/chairs/map placement,
destination catalogue, source ETA formula, security-code challenge/response,
portable-beacon ownership/activation/rescue, radar contacts, mission population
and homunculus recovery. No new named consoles were placed at guessed map
coordinates. Install Scout Controls within an existing shuttle area and put
the Scout Console onboard for local use or offboard for command use.

### Scout validation and manual comparisons

Normal compilation from Interpost-Hague:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' 'C:\Users\nukec\Documents\GitHub\Interpost-Hague\Interpost-Hague.dme'
```

Result: **0 errors, 0 warnings**. Static inspection covers controller selection,
stale landing signals, access/power revalidation and existing dispatch reuse.
No unit tests or Dream Maker IDE were used. Live behavior remains unverified.

Manual checks in Dream Seeker:

1. Put named controls in the Mining shuttle and in each of two Prospectors.
   Each must control its own craft; standalone controls must refuse operation.
2. Try seated/unseated, permitted/unpermitted users, broken/unpowered consoles,
   and movement away while an input or chat hyperlink is open.
   Both seating states are allowed at named Scout controls by the later
   continuation; actual pilot-couch controls remain seat-bound.
3. Run outward/return/revisit/satellite trips with passengers and cargo; compare
   existing generic controls to ensure their behavior remains unchanged.
4. Search with no registered signal, an existing compatible SOS/ruin site,
   a destroyed/replaced signal and another craft's restricted landing site.
   Selection must launch the real craft, not merely print a success string.
5. Test offboard command use with remote control allowed/forbidden, including
   permission/lock changes while a menu is open.
6. Send a message and inspect real LAST MESSAGE/status; verify that the security
   command does not claim a satellite was authenticated or alter docking codes.

## Captain evidence ledger

| ID | Source / visible time | Evidence | Parity implication |
| --- | --- | --- | --- |
| CAP-01 | CAP 00:00:10-00:01:10, O | Captain hat, NT5, cylinder opened/closed, attempted shot at crew monitor. | Loadout, weapon manipulation and empty/failed firing need distinct behavior. |
| CAP-02 | CAP 00:02:10, V | Pocketwatch examination says "Alas, it's 3:07."; character looks at their watch. | Physical timepiece and time readout; exact clock origin, formatting and alarm behavior not recovered. |
| CAP-03 | CAP 00:11:30, O | Investigation begins; sitting advice. | Seating changes reading usability. |
| CAP-04 | CAP 00:12:20, O | Loyal objectives: capture traitor, defend station, stay alive; rewards distinguish own capture from another person's capture. | Announcement parity is not objective evaluation or point scoring. |
| CAP-05 | CAP 00:15:40; 00:16:30; 00:17:30, V | File #1867 has 53 pages remaining; File #1253 has 135 then 129. Five individually numbered files are put in a box at 17:30. | Portable identified documents with different page counts, not just a cabinet interaction. The observed counts are not proven initial capacities. |
| CAP-06 | CAP 00:17:30; 00:18:30, O | Recalling suspicions and being overwhelmed by data. | Leads for memory/cognitive reading state; exact effects remain unverified. |
| CAP-07 | CAP 00:22:50, V | Page countdown followed by a JUNIOR STAFF traitor-category clue: Pilot, Engineer, Cadet, Logistics Officer. | Evidence is tied to a class of potential suspects. Mapper-authored arbitrary payoff text is insufficient. |
| CAP-08 | CAP 00:29:20, O; 00:29:50, V | Captain Keycard examination and Atmospherics Reports Console unlock. | Department access/card identity and telemetry surface; exact permissions and report layout are not established. |
| CAP-09 | CAP 00:32:50, O | Crew Monitoring Console unlock. | Initial access state; exact relocking/key ownership remains unresolved. |
| CAP-10 | CAP 01:05:00, V | Sixteen named installed technologies, including RemCom Device, advanced port, ICE-Pick Mk2 and several weapons. | Command gameplay shares the authored research catalogue. It does not prove RemCom control usage. |
| CAP-11 | CAP 02:10:00, V | Counselor shows suspected Space Doze, implanted head device, bandaged hand, grave injury; assisted stretcher transport and electrical shocks visible in chat. | Disease hint, implant examination, bandage state, power hazard and transport overlap. Source-specific disease progression is not established. |
| CAP-12 | CAP 00:15:40, V | "I have to check File #1440 for a clue" appears twice before investigation of File #1867. | A numbered-file reference exists. This alone does not establish its originating mechanic, delivery, target selection or resolution. |

### Implemented numbered-file investigation batch

[Numbered files](../code/modules/os13/os13_investigation.dm) now provide real
physical media using existing OS13 `report` / `emptyreport` states.
The [cabinet interaction](../code/modules/os13/os13_video_parity.dm) uses this
path on Alpha/OS13 maps; other maps retain the existing cabinet minigame.

- Each file has a unique round-local number, remaining pages, busy state and
  an evidence snapshot bound at first investigation.
- On OS13, a cabinet's first valid browse or investigation creates one file using its existing
  configured page count and explicit mapper lead, if present. Subsequent
  reading uses the same item. Removing/destroying it does not silently create
  a replacement. An inserted unread file can be investigated instead.
- Ordinary [filing cabinets](../code/modules/paperwork/filingcabinet.dm) accept
  these files and collect mapped loose files during initialization. Existing
  retrieval and physical transfer behavior are reused. ID-record cabinets
  continue to accept only ID cards and do not generate investigation files.
- The verified CAP-07 category is generated only if a member of the actual
  traitor registry has assigned role Pilot, Engineer, Cadet or Logistics
  Officer. It implicates **at least one** junior-staff member, not every member
  or necessarily the sole traitor. No player key, individual antagonist name,
  admin reference or complete antagonist roster is disclosed.
- Unverified other role categories produce no generated lead. Explicit mapper
  evidence is preserved, not relabeled as authentic source deduction.
- Investigation requires a conscious, sighted human during the active round.
  Dropping/removing the file, moving away, incapacitation or changing seats
  during a step interrupts without consuming that step's pages. Partial
  progress remains with the file when transferred between readers.
- Any actual buckle seat, including the sectional bench, provides the seated
  speed. Two readers cannot consume the same file simultaneously.
- Completion sets the exhausted art and consumes the lead. Reinvestigation
  reports exhaustion; no automatic memory/skill gain was invented.

**Local choices:** one initially generated file per cabinet, serialized file
numbers, first-read evidence snapshot, reusable physical progress, shared
exhaustion, no repeated lead, all buckle seats qualifying and no automatic
character memory. Random **8-160 pages** now accommodates the visually checked
53/135-page observations; the previous local ceiling of 48 could not.
The range, 4-9 pages per step and three/six-second reading times remain local tuning. These do not establish original
file generation, evidence probability or exact reading cadence.

Validation: normal Interpost-Hague command-line compilation passed with
**0 errors, 0 warnings**; static inspection checks registry/role filtering,
file ownership, one-reader commitment and interrupted/exhausted states.
No unit tests or Dream Maker IDE were used.

Manual Dream Seeker checks:

1. Investigate with a junior-role traitor, only non-junior traitors and no
   traitors. Only the supported real category may produce a generated clue.
2. Check configured mapper evidence, preset page counts and exhausted cabinets.
3. Retrieve/refile a partially read file; another reader must resume its actual
   remaining pages. Destroy/remove the original: no replacement should appear.
4. Interrupt by standing, changing seats, dropping/retrieving the file,
   walking away, blindness/incapacitation or deleting the cabinet.
5. Verify chair and sectional bench reading, concurrent readers, exhausted
   art, unique file numbers and unchanged non-OS13 investigation rules.

### Cabinet browsing continuation

[Physical archive browsing](../code/modules/paperwork/filingcabinet.dm) now
exposes the generated OS13 file **before** it has been read. Click the cabinet,
retrieve its named file, carry it to a chair elsewhere, and investigate it in
hand. The earlier implementation could only create the file by starting the
cabinet investigation, so this recorded portable workflow was inaccessible
until reading had already begun.

- Rows show `File #N`, Unread / remaining pages / Exhausted and an Investigate
  link for that exact document. Multiple inserted files can be investigated
  separately rather than always choosing the first unread file. The cabinet
  verb also offers a selection when more than one unread file is present.
- Browsing and reading share one preparation path. Any existing physical file,
  including an exhausted one, suppresses fresh generation. Insertion, ordinary
  retrieval and telekinetic extraction mark the archive as already populated.
  No new lead is generated just because an exhausted file is removed.
- Held-file reading requires an actual active/inactive hand; worn or stowed
  files must be taken out first. Supplied OS13 `paper` hand states are used.
- Filing checks adjacency, physical interaction, the actual held item and
  `unEquip` success. It cannot move a non-removable file while dropping another
  active-hand item. Cabinet links recheck physical access and item location;
  obsolete links cannot read/retrieve a document transferred elsewhere.
- Normal retrieval preserves the repository's full-hands behavior: the item is
  placed at the user's feet, with an explicit notice. Ordinary paper/ID storage
  and the non-OS13 investigation minigame remain; the transfer/interaction
  guards also apply to ordinary cabinet documents.

The browser layout, one-file generation, sequential numbering and 8-160 random
page range are **local choices**, not recovered source UI/generation rules.
The source visibly has multiple portable files and much larger page counts,
but this batch does not invent a five-file spawn bundle, distributions,
cross-file clue graph, recollection formula or exact reading-text sequence.
CAP-12's numbered reference and CAP-06's memory state remain unresolved.

Validation: normal command-line Interpost-Hague compilation passed with
**0 errors, 0 warnings**. Static inspection checks preparation idempotence,
specific-file links, transfer success, post-input revalidation and OS13 hand
sprite metadata. No live Dream Seeker session or unit tests were performed.

Additional manual checks:

1. Open an untouched OS13 cabinet during the round. Retrieve its unread file
   without reading; opening the cabinet again must not create another.
   Before the round, and in ID-record cabinets, no archive should be generated.
2. Insert two partially read files and choose the second via both the cabinet
   link and verb. Only that item's pages/lead may change. Move it during the
   selection prompt or reading; the old request must not affect another file.
3. Insert an exhausted file into an unused cabinet; browse, extract it normally
   or with telekinesis, and reopen. No replacement or new lead should appear.
4. Try inactive-hand filing, non-removable items, full/disabled hands, restraint,
   incapacitation and walking away from an open menu. Compare ordinary paper
   and ID filing; failed filing must not drop an unrelated held item.
5. Carry a file to another room, read seated/standing, stow/drop it mid-step,
   and refile it. Number, remaining pages and exhausted art must travel with
   the item. Preset a 135-page file for comparison; the observed source page
   counts are supported without implying exact source timing/distribution.

### Original audit comparison

[The original file investigation](../code/modules/os13/os13_video_parity.dm)
rolled 8-48 cabinet pages on first use, consumed 4-9 per step, took three seconds
seated or six standing, permits cancellation, and returns a mapper-set lead
once or NO LEADS HERE. These numbers are **local tuning**, not measurements.
Its original seated check was for chair ancestry. The OS13 numbered-file
path above now recognizes buckle seating, including sectional benches.

Remaining source evidence requirements for the new document model:

- Give each file an identity, subject/content and exhaustion state.
- Relate evidence to the round's actual antagonist assignment, without leaking
  player keys or arbitrary admin information.
- Recover whether evidence narrows job group, individual, location or prior
  actions; only the junior-staff example is directly verified in this set.
- Recover whether reading stores suspicion in character memory, whether
  rereading differs, and whether different readers share exhaustion.
- Compare interruption, moving away, standing up, occupied seat, duplicate
  investigation and destroyed-file behavior.
- Recover the actual page counts and reading cadence before replacing local
  random values.

Do not classify this system as fully implemented solely because PAGE-style
messages exist. Do not hard-code a junior-staff accusation when the real
antagonist is outside that group.

### Bridge and objective boundaries

[Bridge recovery and command controls](../code/game/machinery/computer/testing.dm)
already have real station wake, status, communication-log printing, shields,
announcements and evacuation handling. Wake operates one device every
0.5 seconds, activating lights before setting thermostats to 20 C. Recovery
conditions include water, wake and a sustained controller-online threshold.
Those values describe current code, not recovered original configuration.

The same source's `complete_objective` accepts but does not apply its reward
argument. [Loyal-objective presentation](../code/modules/os13/os13_video_parity.dm)
likewise is not a source-faithful scoring backend. Current escape/announcement
cooldowns and generated mission briefings must not be attributed to the
recording without direct UI evidence.

[Atmospherics Reports](../code/modules/os13/os13_video_objects.dm) collates
pressure from station air alarms and limits the output. It is functional,
not a placeholder. [Bridge shields](../code/modules/os13/os13_wiki_bridge.dm)
also have actual behavior. The [command continuation](#bridge-authority-flight-state-and-raw-material-continuation)
adds bounded Today Reports, registration-location document listing/erasure
and salvage authorization. Their exact original formats/classification remain
unverified. Remote RemCom commands, cargo locking and source-specific
evacuation/self-destruction remain **unverified source contracts**, not
established by people asking for them in chat.

## Flight and EVA evidence ledger

### Dosimeter integration

[Dosimeter](../code/modules/os13/os13_medical.dm) now exists as a portable
passive radiation-exposure recorder with the supplied OS13
[device sheet](../icons/os13/objects/objects/device.dmi) `dosimeter` state.
Full-resolution **PIL 00:22:50** and **ALIEN 00:54:30** show the named device
examined with **0 Gy**; a separate LAST MESSAGE displays 15 / 6 rad/s.
These are distinct readouts. The footage does not establish a nonzero dose,
reset control, exact calibration or that the Dosimeter provides LAST MESSAGE.

- Examination/self-use displays retained exposure in Gy, initially zero.
  Real radiation events delivered to the carried device increment its
  accumulator; transferring it does not discard earlier exposure.
- Reuses the existing [radiation propagation](../code/modules/radiation/radiation.dm):
  living carriers forward radiation events to directly carried items when
  the engine threshold is exceeded. It does not replace the ambient Geiger
  counter, medical bracelet or character's current radiation burden.
- No invented audible alarm, automatic reset, shielding benefit, source
  rad/s terminal message or dose-dependent medical cure.
- OS13 `multitool` hand art, belt storage, replicator requirements/costs and
  **100 received engine radiation units per displayed Gy** are local mappings,
  not source-certified calibration. The accumulator sums received engine
  events; it is not a physiological dose model or real-world instrument.
  The engine's existing below-threshold and container propagation limits
  remain: stowed nested containers and unattended floor devices do not
  automatically receive carried-item events. No environmental polling was
  added that could double-count exposure.

Validation: normal Interpost-Hague compilation passed with **0 errors,
0 warnings**. Radiation delivery and sprite metadata inspected statically;
no unit tests or Dream Maker IDE. Live comparison remains unperformed.

Manual checks:

1. Fabricate and examine a fresh Dosimeter: 0 Gy and valid OS13 item/hand art.
2. Carry it directly in an irradiated area; confirm its reading grows only
   from delivered radiation events. Transfer it and revisit a safe room:
   the accumulated reading must persist without following body detoxification.
3. Compare the existing ambient Geiger readout with the retained-dose reading.
   Test spacecraft shielding, nested storage and a floor-dropped Dosimeter;
   do not interpret those propagation limits as verified original behavior.

### Flight evidence

| ID | Source / visible time | Evidence | Parity implication |
| --- | --- | --- | --- |
| FLT-01 | ALIEN 00:02:40, O | Distress Beacon worn on neck; rescue-chance description. | Portable item and slot contract; not proof of an activated routing result. |
| FLT-02 | PIL 00:04:00, O | Tri-Net Space Helmet examination. | Imported named gear exists locally; exact deterioration remains to compare. |
| FLT-03 | PIL 00:05:40, V | Four-chair Scout cabin, pilot controls unlock, launch ETA 89 s; jetpack air 98.7%. | Real travel/action and finite air, not a decorative console. |
| FLT-04 | PIL 00:09:30, V | FixBoy-2000 examination and an off light switch. | Physical diagnostic-tool identity and local lighting state; no repair sequence established. |
| FLT-05 | PIL 00:12:10, V | Physical AI on satellite; Lance holds a flare and a numbered file, wears satchel, responds to interactions. | Embodied homunculus is distinct from a stationary AI core. |
| FLT-06 | PIL 00:13:10; 00:13:40, O | Return launch ETA 26 s; HOMUNKULUS-5 reporting. | Satellite recovery loop and named synthetic unit. Authentication details still need direct review. |
| FLT-07 | PIL 00:20:00, V | Pickup list includes suit, suit boots, air-mix gas tank and breath mask; worn spares and loose cabin gear. | Grouped pickup UX, spare equipment and actual slot transitions. |
| FLT-08 | PIL 00:22:00, V | Scout Console: Transmit Security Code, Search for Distress Signals, Send Message, Cancel; last message displays 15 rad/s. | Distinct communications terminal and potentially live telemetry, not the same device as flight controls. |
| FLT-09 | PIL 00:34:40, O | NO DISTRESS SIGNALS FOUND. | Legitimate empty-result branch; not justification for always returning empty. |
| FLT-10 | PIL 00:50:00, V | Strong white/grey viewport distortion; HUD/chat still usable; mood changes and altered prose. | Isolated viewport effect, not complete client blindness. Exact cause/onset still unverified. |
| FLT-11 | RUIN 00:08:10; 00:10:20; 00:11:00; 00:20:00, O | Launch ETAs 21, 22, 29 and 50 s. | Route/leg times vary; do not replace them with one universal ETA. |
| FLT-12 | ALIEN 00:21:30; 00:23:20; 00:34:20; 00:51:50, O | Launch ETAs 23, 30, 43 and 78 s. | Additional independent flight legs. Titles alone do not reveal destination names. |
| FLT-13 | ALIEN 00:11:30, V; 00:22:30; 00:25:30; 00:31:20, O | TNC Gravcutter with damage/repair notice, Gold ore, zrbite ore, Gem Ore. | Physical tool identity and wear feedback; mining catalogue is wider than only the three currently enabled resources. Exact repair mechanics not established. |
| FLT-14 | RUIN 00:31:20; 00:45:00; 01:00:40; 01:01:10, O | Further launches; repeated returns and resource/air preparation. | Revisit and transport loops, not one-way cutscene travel. |
| FLT-15 | ALIEN 01:01:40, O | Lance passes an emergency oxygen tank to pilot. | Embodied synthetic can transfer normal items. Not proof of autonomous rescue AI. |

### Do not overlook existing actual flight

There are **three different local surfaces**:

1. [Mining expedition controller](../code/modules/shuttles/mining_expedition.dm):
   real mining/salvage launch, preparation, return, revisit, satellite travel
   and local/remote control permission.
2. [Prospector spacecraft integration](../code/modules/vehicles/civ13/mining_shuttle.dm):
   attaches an actual autodock shuttle/controller and exposes seated pilot and
   paired remote communications actions.
3. Earlier [named OS13 objects](../code/modules/os13/os13_video_objects.dm) and
   [Scout Console](../code/modules/os13/os13_video_parity.dm):
   the audit originally found readiness-only Scout Controls, always-empty
   search and announcement-only code transmission. The integration batch above
   replaces those Scout placeholders with real controller/landing-signal
   behavior, while source authentication remains unresolved. Radar still
   reports no unidentified contacts.

Therefore **generic flight and named Scout integration exist, exact Scout
parity remains incomplete**. Reuse the real controller; do not build another
disconnected fake flight menu.
The generic [ruins/distress framework](../code/modules/maps/ruins.dm) is also
present. Its examined registry contains generic derelict/outpost signals,
not verified exact OS13 destinations, mission populations or rescue rules.

### Flight reconstruction requirements

- Bind Scout Controls and Scout Console to the same physical craft/controller.
- Recover exact destination menu, approach/launch/arrival states, landing gear
  prerequisite, return availability and revisit persistence from popup windows.
- Record each observed origin/destination with ETA; current evidence only
  establishes variable displayed values, not a distance formula.
- Treat satellite codes as an actual authorization exchange once verified;
  an announcement is not authorization.
- Search live registered beacons and return actionable results. Preserve the
  legitimate no-signal branch and avoid fabricated contacts.
- Keep local pilot permission separate from command remote permission.
- Recover whether pilot seating is mandatory and what happens to passengers,
  cargo, loose objects and external occupants at departure.
- Match cabin footprint, four chairs, control positions, exits, lamps, signs
  and onboard spare air/suits; the screenshot does not supply map coordinates.
- Verify powerless/broken/locked devices, cancelled input, blocked docking,
  missing landing gear, occupied destination and deleted beacon behavior.

Charon, Evergreen, Base-7 and other names in previous wiki notes remain
unresolved here unless a particular frame/menu establishes them. Dialogue
about a satellite code does not identify a complete route graph.

## Ruins, aliens and afterlife

| ID | Source / visible time | Evidence | Gap / limit |
| --- | --- | --- | --- |
| EXP-01 | RUIN 00:27:10, V | Small derelict interior, cryopod-like structures, survivor, Vault with no visible opening method, extreme heat, air 80.8%. | Authored rescue scene and inaccessible-object branch. No vault-unlock mechanic established. |
| EXP-02 | RUIN 00:43:20, V | Scrap delivered beside cargo conveyor; heat warnings and experience-reflection desire. | Cargo handoff, environment burden and progression UI; exact automation remains to compare. |
| EXP-03 | RUIN 00:49:50, V | Exterior lattice/walkways, damaged oxygen jetpack, air 72.8%; extreme heat persists. | Equipment wear and atmospheric/thermal hazards are independent states. |
| EXP-04 | RUIN 01:06:00, V | SPACE HERO viewport card, air 9.3%, inability to breathe, no willpower and armor preventing sleep nearby. | Transition/card and multiple refusal branches. Exact cause and whether card is game-generated or edited require continuity review. |
| EXP-05 | RUIN 01:07:00, V | Different character/interface, crossbow aiming bonuses, Nurse cleaning, Parasite combat, spear and Streamer 23. | Later scene includes additional entities/weapons. A character change is not proof of resurrection or possession. |
| EXP-06 | ALIEN 01:18:30, V | Alien jumps, claws synthetic hand, laser hits head, stun/crawl; pink/red injury effects. | Region-resolved species combat, movement and incapacitation states. |
| EXP-07 | ALIEN 01:18:40-01:19:40, O | Thick skin dampens laser/pellet; empty clicks, tail shove/stab, targeted hands/feet, dodge, vitals grab and gravsphere hit. | Attack families, armor and resource exhaustion; numerical armor not recovered. |
| EXP-08 | ALIEN 01:20:00, V | After fight, festering/bleeding self-card and multi-mode Medi-Kit refusal through clothing. | Persistent injuries outlive the fight; see [medical audit](os13_extended_medical_audit.md). |
| EXP-09 | PIL 01:06:00, V | Grey spectral viewport, ghost figure, Ascension (300), Oblivion (10), Remember Echo, Visit Friend (10), Shroud Thickness, Remove Magical Defence (20), Perish (60), Laugh (2); Angst and sacrament messages. | Afterlife is an actual interactive surface, not merely ordinary observer ghosting. Effects/cost currency and targeting still need direct action review. |

[Generic aliens](../code/modules/mob/living/simple_animal/hostile/alien.dm)
and [xenomorph abilities](../code/modules/mob/living/carbon/human/species/xenomorphs/alien_powers.dm)
already exist. They do not establish the recorded species' thick-skin formula,
body-part targeting, tail attacks or exact sprites. Claw/tail prose may also
come from the shared GURPS resolver, so compare actual attack data before adding
special duplicate combat logic.

[Generic observer ghosts](../code/modules/mob/observer/ghost/ghost.dm) exist.
The inspected mob sources did not contain Angst/Shroud/sacrament or the named
afterlife powers. A source-faithful implementation needs its own verified
resource, memory/echo, friend visitation, visibility and return/termination
contracts; copying labels onto generic ghost verbs is insufficient.

[Grav cutter and Harvester](../code/modules/mining/os13_mining.dm) are already
functional: immediate standard-path excavation, powered movement collection
of eligible loose ore/shards/panels, contents release and destruction cleanup.
Current resource identity maps zbrite to glass and elerium to plasteel.
Gold/Gem examinations do not prove they are mineable through the same source
tool; their source use and local generation need separate verification.
[FixBoy](../code/modules/power/engineering_monitor.dm) is also already a real
tool, not a missing name.

## Manual acceptance comparisons

Compare in Dream Seeker, without an isolated test daemon:

1. Numbered file investigation with real eligible/ineligible antagonist groups,
   seated/standing speed, interruption and exhausted evidence.
2. Station wake, telemetry, pressure reports and reward accounting separately.
3. Satellite outward/return trip; ordinary mining and salvage/revisit legs;
   local/remote lock; real beacon and no-beacon searches.
4. Passenger and cargo persistence, onboard spares, pickup grouping, suit/air
   slots, damaged helmet, finite oxygen and heat independently.
5. Harvested cargo delivery and actual replicator consumption.
6. Named alien attack data, head laser stun, tail shove, thick-skin mitigation,
   empty weapon clicks, injuries and post-fight treatment.
7. Ghost viewport/menu, displayed resource costs and memory/sacrament changes.

Still required: dense menu/action and transition review, exact map templates,
NPC versus player control identification, animation/effect timings, authentic
sound cues, destination authentication and afterlife action outcomes.
## OS13 door catalogue and layered rendering

[OS13 door definitions](../code/game/machinery/doors/os13_doors.dm) cover all
50 DMI sheets recursively found in
[the supplied doors folder](../icons/os13/objects/objects/doors/).
There are 62 placeable types, including the base families, alternate cave
leaves, the alternate office door, six alternate industrial/tech gate leaves,
and both window-door sides. No additional subfolders were present at
inspection. No arbitrary map placements or department access restrictions
were added.

### Placeable families

| Root | Variants / supplied sheets |
|---|---|
| `/obj/machinery/door/os13` | Base `1`; `panel` (`door2`), `office` (`door3`), `office/alternate` (`doora` leaf and `doorao` frame), `general`, `interior`, `chapel_left`, `chapel_right`, `throne_left`, `throne_right`, `leviathan`, `prison`, `solitary`. |
| `/obj/machinery/door/os13/cave` | Base and `two`, `three`, `four`; `alternate` leaves for base, two and four use the supplied `xdoor` states. |
| `/obj/machinery/door/os13/gate` | Base, `two`, `three`; `industrial` / `industrial/two` / `industrial/three`; `tech` / `tech/two` / `tech/three`. Each industrial/tech type also has an `alternate` subtype selecting its authored `door2` closed leaf. Covers `gates1-3`, `sgates/2/3` and `tgates1-3`. |
| `/obj/machinery/door/airlock/os13` | Maintenance base; `room`, `electrical_hatch`, `maintenance_hatch`, `hatch`, `maintenance`, `engineering_glass`, `medical_glass` / `medical_glass/alternate`, `security_glass`, `tnc_engineering` / `tnc_engineering/alternate`, `tnc_medical` / `tnc_medical/alternate`, `inquisitor` / `inquisitor/alternate`, `water_glass`. |
| `/obj/machinery/door/blast/os13` | Rapid-shutter base; `alternate`, `automatic`, `brothel`, `elevator`, `warehouse`, `tnc`. Uses existing remotely controlled blast-door behavior, not invented original automation. |
| `/obj/machinery/door/firedoor/os13` | `door_fire2` art with existing fire/pressure alarm and shutter behavior. A closed firedoor in pressure/temperature lockdown shows the supplied sealed `doorl` leaf. Missing alarm/hatch symbols retain the standard safety overlays; welding uses the supplied `door_welded`. |
| `/obj/machinery/door/window/os13` | Supplied `windoor` left side; `right` selects the matching right-side movement states and retains directional border collision. A closed south-facing pane draws above mobs on its tile. |
| `/obj/machinery/door/os13/solitary` | Alt-click while closed toggles the supplied `door1o` viewing slot. The door stays opaque and keeps its normal access. |
| `/obj/machinery/door/os13/shuttle`, `/obj/machinery/door/os13/replicator` | OS13 door art kept outside the doors folder (`turf/shuttle.dmi`, `replicator/labyrinth.dmi`), opted in to the layered renderer with `os13_door_sheet`. |
| `/obj/machinery/door/blast/os13/portcullis` (`/open`) | Remote-controlled see-through grate from `weapons/objects.dmi`; the raised teeth (`portcullis0`) draw above mobs and the `portculliso` floor sockets below them. |
| `/obj/machinery/door/blast/os13/remote/...` | Blast-door (button/wifi `id` only) version of every OS13 door, mirroring the normal paths: `remote/airlock/*`, `remote/door/*` (including cave, gate, industrial/tech gate alternates, shuttle and replicator), and `remote/firedoor`. They use the same layered, over-mob and emissive rendering. Glass sheets stay see-through when closed. The windoor has no blast version because it is a directional border door. The existing pdoor-sheet shutters were already blast doors. |
| Legacy `.../os13` subtypes | `airlock/door3`, `maintenance`, `research`, `hatch`, `command`, `keypad`, `external`, `cone`, `doorgeneral2`, `security`, `blast/iddoor` and `blast/shutters` each have an `os13` subtype that keeps the legacy behaviour but uses an OS13 sheet. Every legacy door on `os13classic` now uses these subtypes, and its edge firedoor uses `firedoor/os13`. The cabin door uses `b_room`. |

### Rendering and behavior

- The [normal door](../code/game/machinery/doors/door.dm),
  [airlock](../code/game/machinery/doors/airlock.dm) and
  [shutter](../code/game/machinery/doors/blast_door.dm) render paths recognize
  only the OS13 doors resource prefix. Non-OS13 artwork keeps its existing
  rendering. Existing mapped OS13 office/corridor/maintenance types are
  covered without replacing their type or access configuration.
- Closed/open and movement states are selected from the actual `door_*`,
  `door1/0/c0/c1`, `mdoor*`, `pdoor*` or selected `xdoor*` families.
  Denial, panel-open movement, lock, welding and damaged art are used where
  provided. Missing optional states are not flicked as blank icons.
  Airlock braces still render through the existing brace update.
- `door_lower`, `pdoor_u`, `OO` and gate lower-frame pieces render below
  occupants. `door_overlay`, `door_overlay2`, `door_closedo`, `pdoor_o`
  and gate `door_up` pieces render at `ABOVE_HUMAN_LAYER`, above normal
  people/items but still subject to scene lighting. Every part explicitly
  follows the door's direction; changing direction rebuilds the parts.
  `KEEP_APART` prevents the frame/light pieces from being flattened into
  the leaf's layer. Both `door_down` and `door_down2` are retained when
  supplied together, rather than losing the threshold strip. The TNC
  shutter uses its split `pdoor_o`/`pdoor_u` frame instead of also drawing
  the redundant combined `OO` frame.
- Authored `light_opening`, `light_closing` and `light` states render on
  `ABOVE_LIGHTING_PLANE`. They require intact operational power; airlocks
  also require an available main/backup power system. Structural pieces
  are not made emissive just because they are named overlays.
  Movement-light lifetime follows the inherited movement cycle; serial-
  guarded cleanup cannot end a newer animation. Power/state changes rebuild
  the parts rather than accumulating overlays. Shutters now enter the same
  animation lifecycle, with their existing 15-decisecond movement cycle;
  ordinary doors retain their 10-decisecond cycle. Initially open shutters
  refresh their complete appearance after density changes.
- The alternate office door uses its authored blue `doorao0` indicator
  while open and red `doorao1` while closed, only with operational power.
  This open/closed mapping is a local integration choice, not a recovered
  OS13 rule. Light parts ignore the parent colour tint and remain below
  LOS shadows. Animated gate leaves remain ordinary lit scenery; an
  animated or coloured leaf is not itself an emissive mask.
- Open airlocks retain an authored `panel_open` or `welded_open` part where
  available, while closed doors retain their matching panel/weld art.
- Stencil states `mask`/`mask2` are not drawn as opaque scenery or
  emissive screens. Gate frame geometry uses the supplied `door_up` and
  `door_down` pieces. Duplicate state names are left untouched in the assets;
  original special-purpose mask/alternate-state semantics remain unverified.
- Opening/closing, authorization, air blocking, glass transparency, safety
  checks, wire controls, welding and existing sound/timing policies use the
  inherited door implementations. This is asset and rendering integration,
  not certification of original OS13 door strength, timing or access rules.

### Validation

Static inspection verifies recursive sheet coverage, referenced resources,
complete closed/open/opening/closing state families for all 50 sheets,
inherited preview/alternate states for all 62 types, alternate office light
states, production project inclusion and whitespace. Editor diagnostics
reported no errors in the changed door code. Foreground/lower/light frames
were inspected visually. No compiler, Dream Maker, unit tests or live game
were run for this door follow-up.

Manual in-game acceptance remains: place every family, open/close in each
supported direction, pass a human and loose item through open door frames,
compare foreground versus floor pieces, toggle power during medical light
animations and on the TNC shutter and alternate office indicators, then
rotate a door and verify its parts follow. Exercise denied access, bolts,
panel/welding, airlock braces, blocked closure, fire/pressure alarms and
left/right window-door collision. Verify ordinary non-OS13 doors retain
their previous appearance and behavior.
## Missing-object furniture and storage continuation

The supplied art contained complete seating, chest and safe families with
no corresponding OS13 production definitions. This continuation adds
**30 placeable objects** without changing existing generic furniture art or
inventing contents, room placements or undocumented gameplay.

- [Seating](../code/game/objects/structures/stool_bed_chair_nest/sofas.dm):
  `/obj/structure/sofa/os13` and its `section_a`, `section_b`, `section_d`,
  `section_e`, `padded_left`, `padded_right`, `fancy`, `armchair`, `royal`,
  `old`, `old/alternate`, `rounded`, `rounded/alternate` variants cover all
  14 states in `couch.dmi`. The base uses `couch2c`. Twelve seat-bearing
  variants use existing buckling and north-facing draw-order behavior,
  not arbitrary skill effects. The partial `couch2d`/`couch2e` sectional
  extensions remain placeable but cannot buckle occupants.
- [Storage](../code/game/objects/structures/crates_lockers/os13_storage.dm):
  `/obj/structure/closet/crate/os13` and `ancient`, `wood`, `wood/small`,
  `wood/banded`, `wood/large`, `equipment`, `red`, `technical`,
  `technical/alternate`, `ornate`, `cargo` provide 12 real containers with
  matched open/closed art. The base equipment chest also flicks its supplied
  opening/closing animations. The cargo lip renders above ordinary occupants.
  Existing item-only crate storage, capacity and interactions are inherited;
  names such as `gold` are sprite IDs, not evidence that a chest contains gold.
- `/obj/structure/closet/crate/freezer/os13` uses the real freezer parent,
  including its local cooling behavior, with the supplied freezer art.
  It is not a relabeled ordinary cabinet.
- [Safes](../code/game/objects/structures/safe.dm):
  `/obj/structure/safe/os13` and `/old` use their corresponding safe casing,
  movement/denied animations and `*1` emissive indicators. Animation cleanup
  is serial-guarded. They inherit the existing combination-dial system;
  neither original keypad access nor original safe-cracking balance is
  claimed. These variants require a capable adjacent user, only accept a
  successfully released held item, and recalculate capacity when items leave.
  Status indicators are self-contained visual indicators, not evidence of
  an original station-power connection.
  The shared safe constructor now calls its parent so dynamically created
  safes initialize, and random tumbler values use the reachable 0-71 range.
  Safe initialization also retains its parent initialization result when
  its initial contents fill the container. Generic lock rules are unchanged.
- [Bookcase](../code/modules/library/lib_items.dm):
  `/obj/structure/bookcase/os13` stores actual books using the existing
  library system. Its empty state and 15 `a*` fill tiers reflect the stored
  book count (art saturates at 15; storage retains the existing unlimited
  local behavior). Contents entering or leaving refresh its art. It retains
  local naming, dismantling and library interactions; book insertion must
  release a held book. Shared retrieval now rechecks that a selected book
  still belongs to this shelf after the selection dialog, preventing a
  stale choice from taking a book another user already removed. Alternate
  palette/label states do not imply invented source categories or stock.

Static inspection covers all 30 type definitions, sprite states, inherited
interaction paths, direct project includes and whitespace. No compiler,
Dream Maker, unit tests or live game were run. Manual acceptance remains:
place each couch and buckle/unbuckle in supported directions; fill/open/close
each chest; inspect the cargo lip over an occupant; exercise freezer storage;
operate both safe locks, inspect indicators in darkness, open/close rapidly,
fill/retrieve/refill and attempt remote or unremovable-item interaction.
Fill/empty the bookcase, check external book moves and have two users select
the same book before either confirms the selection.

This closes identified unused-asset object gaps only. Correctional Apparatus,
Psychocorrectional Console, original wall-bar behavior, authored Genemod
effects and other source-contract gaps in the inventory remain unresolved.
They have not been replaced by decorative lookalikes or guessed mechanics.
