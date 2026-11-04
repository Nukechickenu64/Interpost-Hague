# OS13 video parity gaps — cross-video checklist

Consolidated status of every gameplay system observed in the three archived
OS13 recordings against the Interpost-Hague working tree. Evidence citations
point at the per-video documents:

- M = `os13_marshal_video_parity.md` (Marshal adventures, 2:15:07)
- E = `os13_engineer_video_parity.md` (Chill Engineer, 2:07:39)
- W = `os13_waterchip_video_parity.md` (water-chip video / `os131.mp4`, 1:42:30)

Statuses: **Implemented** (system present; wording may differ), **Partial**
(core exists, OS13-specific behavior/format missing), **Missing** (no
counterpart found in `code/`). Message wording from OCR is approximate.

The later [archived-wiki implementation](os13_wiki_parity.md) replaces the OS13
job roster and adds Counselor abilities, neural ports, bridge shield controls
and medical/maintenance interactions. Its coverage table supersedes older job
and Counselor status notes here; it also lists systems that remain incomplete.

The [extended eight-recording audit](os13_extended_video_audit.md) adds
timestamped medical, research, genetics, flight, hostile-encounter and afterlife
evidence. It supersedes blanket missing-system claims where current production
code already provides real expedition travel, shared replicator storage,
reclamation, ChargeMaster conversion, Harvester or FixBoy behavior. It also
distinguishes named placeholders from source-faithful gameplay and records
sampling/OCR limitations rather than claiming every-frame completeness.

## Sectional station benches

`/obj/structure/sofa/bench/os13` adds real, upright seating using the supplied
`icons/obj/bench.dmi` sprites specified by the user. Their grey seats, brown
edging and metal supports match the pictured sectional bench.
Existing benches and map placements are unchanged.

Mapper pieces (all under `/obj/structure/sofa/bench/os13`):

- Base: horizontal straight; `/vertical`: vertical straight.
- `/end`: left end; `/end/right`, `/end/top`, `/end/bottom`: other ends.
- `/corner`: upper-right corner; `/corner/top_left`,
  `/corner/bottom_left`, `/corner/bottom_right`: other corners.
- `/single`: standalone seat.
- `/junction`: four-way join; `/junction/north`, `/junction/south`,
  `/junction/east`, `/junction/west`: T-junctions named for the branch off
  the straight section.

To assemble the pictured L, place a left end, horizontal straight sections,
an upper-right corner, vertical straight sections below it and a bottom end.
Sections do not automatically join or rotate; each mapper-selected variant
uses its own numbered, single-direction sprite state. Changing `dir` does not
rotate this artwork. `buckle_dir` can override occupant
facing independently of the sprite direction, including on corner pieces.
Drag a character onto each section to sit; click it to stand up.
Each section seats one character and inherits normal sofa anchoring and
passability. No invented map coordinates or new artwork are included.

Validation uses normal compilation of `Interpost-Hague.dme` and static sprite
inspection. Manual checks still need to confirm all four corners, end seams,
seating/unbuckling, occupant facing and layering in Dream Seeker.

## Round framework

| System | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Cryosleep wake-up hangover line ("You feel terrible, like having a heavy hangover…") | M, E, W | Implemented | Cryopod release message (`code/game/machinery/cryopod.dm`); OCR-truncated tail completed conservatively. |
| Loyal-crew objective sheet (banner, numbered objectives, "+N" point rewards) | M, E, W | Implemented | Sent to non-antagonist crew shortly after round start in traitor-tag modes (`code/modules/os13/os13_video_parity.dm`); reward wording approximate where OCR truncated. No point-scoring backend. |
| End-of-round traitor report (name + key, hidden-stash failure line, per-antagonist entries) | M | Partial | Existing antagonist summary prints name/key/objective failures (`code/game/antagonist/antagonist_print.dm`); OS13's exact layout and hidden-stash line are not replicated. |
| Staged alert levels ("elevated alert" authorizing IntenSecure) | W | Partial | Alert/announce infrastructure exists (`code/procs/announce.dm`); staged-level wording unverified. |
| Trait/moodlet sheet (character card + trait text + bullet goals) | M | Partial | Psychosis trait card implemented; the full character-card/moodlet sheet is not. |
| Posthibernational psychosis (white-out hallucination, chat spam, DISCHARGE/TREATMENT cures) | M | Implemented | Trait chance on cryopod wake; episodic white-out overlay, chat spam, onset announcement, drunk discharge and counselor treatment verb (`code/modules/os13/os13_video_parity.dm`). Probabilities/durations are local tuning. |
| Hunger/nausea moodlet ticks | M, W | Implemented | "*You feel hunger.*" tick added to the hungry band (`code/modules/organs/internal/stomach.dm`); nausea already present. |
| Head-trauma amnesia ("You can't remember anything that…") | W | Missing | |

## Security / Marshal

| System | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Marshal job title and IntenSecure equipment line (baton, operatives, keycards) | M | Partial | Marshal is now selectable on OS13; named IntenSecure objects exist. Complete loadout and map-placement parity remain unverified. See [wiki coverage](os13_wiki_parity.md). |
| File-investigation minigame ("begins to investigate the files!", "N PAGES LEFT!", "NO LEADS HERE.", evidence payoff, sit-to-read gating) | M | Partial | OS13 cabinets now expose portable File #N documents before reading, with specific-file selection, persistent progress/exhaustion and the verified junior-staff clue tied to actual traitor roles. Larger page counts supported; other categories/generation/memory effects remain unverified. Page ranges/speeds are local tuning; see the [browsing continuation](os13_extended_operations_audit.md#cabinet-browsing-continuation). |
| Handcuff application/removal ("swings with handcuffs!", timed cuffing, unhandcuffing) | M | Partial | Standard cuffs emit the recorded swing line; existing application still requires a firm grab and interruptible timed action/recheck. Strip-interface removal now emits the recorded unhandcuff message while preserving existing timed unequip guards. Exact struggle feedback and source timings/requirements remain unverified; see the [cuff interaction continuation](os13_extended_operations_audit.md#recorded-handcuff-application-and-removal-messages). |
| Strip/search window (all slots + Cuffed / Not legcuffed / Empty Pockets) | M | Implemented | `code/modules/mob/living/carbon/carbon.dm` strip code. |
| Takedown state ("pushes X down!", HUD TAKEDOWN button) | M | Partial | Push/grab exist via GURPS combat parity; takedown HUD state unverified. |
| IntenSecure Baton hit prose ("neatly beats X's right hand with…") | M | Partial | Exact wording now occurs only for a successfully targeted right-hand strike in both item and GURPS combat; all other source attack-quality tiers and nonlethal semantics remain unverified. |
| Grip struggle messages ("is trying to break loose from the grip!" / "struggles with X and wins!") | M | Partial | The explicit resist action and successful full escape now use the recorded wording. Existing contest odds, automatic struggle timing and intermediate grip-loosening messages remain local behavior. |

## Combat (supplements `combat-parity-implementation.md`)

| System | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Weapon readying line ("X grabs a weapon.") | M | Implemented | Printed when a weapon-grade item (force ≥ 6) is picked up from the floor (`code/game/objects/items.dm`). |
| Push attempts/success/knockdown three-way prose | M, E | Implemented | GURPS parity module. |
| Location-specific grab prose (chest/throat/face/arm/hand), hostage blade-to-throat variant | M | Implemented | Special grabs already named the location; a chest grab with a sharp off-hand item now reads "grabs X's chest, putting the blade to X's throat!" (`code/modules/mob/grab/special/grab_special.dm`). |
| Quality adverbs in strike prose ("clumsily", "neatly", "effortlessly") | M | Partial | GURPS successful weak/solid/powerful labels map to observed clumsily/neatly/effortlessly wording for weapons, punches, kicks and bites; missed kicks use observed target-part/foot prose. Margin thresholds and legacy-combat parity remain unverified. |
| Species bites ("…with his huge fangs!" vs "with his teeth") | M | Partial | Bite prose names the body part and species teeth/fangs; the GURPS top-margin bite now also uses observed "effortlessly bites" wording. Exact quality thresholds and legacy-combat quality remain unverified (`code/modules/mob/living/carbon/human/unarmed_attack.dm`). |
| Thrown body / deliberate environment strike prose | M | Partial | Dense-turf/window impacts preserve observed wall/window wording and existing impact effects; eligible dense structures use generic thrown-body feedback. Table harm-intent hand/item strikes now use the recorded “hits the Table” line. Pod identity/path and other intentional environment strikes remain unresolved. |
| Telegraphed throws ("is trying to throw the X!" then impact line) | M, W | Implemented | Pre-existing telegraph reworded to "is trying to throw the X!" / "throws the X!" (`code/modules/mob/living/carbon/carbon.dm`). |
| Carrying bodies on the back | M | Unimplemented | The marshal footage records “is trying to carry [person] on their back”; code provides dragging/pulling only, not a back-carry action. Source eligibility, timing, interruption, movement, and release behavior are not established, so no substitute action is inferred. |
| Injury-gated interactions ("YOUR CHEST HURTS! You hardly bend down to pick up…") | M | Implemented | Floor pickups with a broken/heavily bruised chest print the pain line (`code/game/objects/items.dm`). |

## Medical

| System | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Graded wound examine ("You see no wounds." / slightly / severely wounded, unconscious, relative strength) | M, E | Partial | `examine.dm` has graded states; exact OS13 strings unverified. |
| Pulse check verb and `???` unknown identities | M | Partial | Manual pulse-check and unconscious-patient pulse actions exist; the OS13 Medvisor displays pulse in local diagnosis and remote telemetry. Body Search currently displays repository names directly; the recorded unknown-identity masking/recognition rule is unresolved. |
| Pupil-state examine line (intoxication/psi tell) | M | Partial | Drug eye effects exist; examine line unverified. |
| Named items: Hemostatic / Bacteriophages Containing Bandages, medical bracelet | M, E | Partial | Bracelet implemented per engineer doc; named bandages now have replicator designs, per-wound consumption and success-only surface germ effects. Regional removal added; original disease/clotting rules remain unverified. See [supplies batch](os13_extended_medical_audit.md#implemented-medical-supplies-batch). |
| Cloning failure prose ("The outage mulched this clone."), replacement limb lore | W | Partial | Cloning exists; outage interaction/prose unverified. |

## Ship systems and environment

| System | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Scout shuttle: pilot-chair launch, "You launch the shuttle. ETA: Ns" | M | Partial | Named Scout Controls now connects to the actual onboard expedition/spacecraft controller. Exact routes, layout and ETA parity remain unresolved; see the [extended flight comparison](os13_extended_operations_audit.md). |
| Scout Console commands (Transmit Security Code / Search for Distress Signals / Send Message) | M | Partial | Named console now validates the actual craft link and searches/dispatches registered SOS/ruin landing sites. Original satellite code authentication and portable beacon rescue remain unresolved. |
| Airlock "Cycling in progress. Pressure: N kPa" status | M | Implemented | Cycling airlock controllers report chamber pressure every 4 s during pressurize/depressurize (`code/game/machinery/embedded_controller/airlock_program.dm`). |
| Magnetic boots toggle | M, E | Implemented | `magboots.dm`; wording unverified. |
| Spoken cabin passwords ("* YOU MAY ENTER *", cabin identification lines) | M, W | Implemented | `/obj/machinery/door/airlock/os13_cabin`: bolted cabin door with owner name and a five-digit password; speaking the password adjacent unbolts/opens with "* YOU MAY ENTER *" and the door re-secures after 10 s; denied touches identify the owner (`code/modules/os13/os13_video_parity.dm`). Mapper-placed. |
| Darkness stumble warning ("It is pitch black. You are likely to stumble.") | M, E, W | Implemented | Printed (30 s throttle) when a conscious human moves through an unlit turf (`code/modules/os13/os13_video_parity.dm`). |
| Vacuum suffocation line ("You cannot breathe anymore.") | M | Implemented | Printed (15 s throttle) on near-total inhale failure (`code/modules/organs/internal/lungs.dm`). |
| Meteor proximity countdown ("DANGER! Proximity alert! Ns until the collision!") | M | Implemented | Meteor-wave announce now includes a seconds-to-first-impact countdown (`code/modules/events/meteors.dm`); the lead time is the event's own, not the video's 258 s. |
| Intercom channel tags ([Alert]/[WARNING]/[Emergency]) with security systems online/offline broadcasts | M | Partial | |
| Solar array status broadcast ("The solar panel array is now SPREADED.") | E | Partial | Spread/Retract console implemented (engineer doc); broadcast wording differs. |
| Vent console text format (`*LOCKDOWN PRESSURE: 60 kPA`, `Vent-N`, `> Status: FILTER`, `FILTER[turbo]`) | E | Partial | NanoUI console implemented; raw text format differs, turbo mechanism unverified. |
| Standing-order announcements ("You are NOT to fill your air-tanks from the primary air supply") | E | Partial | Announce exists; content is round role-play. |
| Deck elevator transport | W, M | Partial | Turbolifts exist; OS13 lift behavior under map reconstruction (`os13_waterchip_manual_map.md`). |
| Planetary psi-field announcements, psi-potential grades, psionic implants, Mentats | W | Missing | No psi-field system found. |

## Social / chat / UI

| System | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Speech formats (says/asks, dash-shout, stutter rendering, whisper masking "whispers something...") | M, E, W | Partial | Say/whisper exist; dash-shout and stutter formats unverified. |
| Job-tagged radio with department icons | M, E, W | Partial | |
| OOC prefix format | M | Implemented | |
| Emote wheel panel (18 emotes Slap…Clear Throat) | M, E, W | Implemented | `code/porco/pig.dm`. |
| Free-form emotes (leans on wall, slaps own face, points at object, gazes into the distance…) | M, W | Partial | Emote system exists; several specific emotes unverified. |
| Recognition system ("Oh, this is X! I always knew him as a Y.", `???` until introduced) | M, W | Partial | Unknown-name rendering exists; recognition prose unverified. |
| Examine with inline item icons/colored links per slot | M, W | Implemented | Human examine. |
| Consumption messages (eats, swallows pill/gulp, lights cigarette) | M | Implemented | |
| Chair sit/rise messages | M, E | Implemented | `buckling.dm`. |
| Item hand-off paired messages (gives you / passed X to Y) | E, W | Partial | Successful Give actions now send the recipient a private "gives you" line and nearby observers the recorded public "passed ... to ..." line (`code/modules/mob/living/carbon/give.dm`). Other transfer paths and exact message punctuation remain unverified. |
| Container reach restriction ("You can't reach the contents of X.") + concealment verb | M, W | Partial | |
| Paper windows, book-writing prompt ("Do you want to write a book?") | M | Partial | Paper exists; book-writing prompt unverified. |
| Console personal lock/unlock ("Access denied." / "X unlocks the … Console!") | M, E | Implemented | `/obj/machinery/computer/crew/os13_locked`: access-gated, prints "Negative It's LOCKED." or a public unlock line on first authorized use (`code/modules/os13/os13_video_parity.dm`). Other consoles can adopt the same pattern. |
| Crew Monitoring pulse list (`N. ### Name (Area) PLS: n`, 0 = dead) | M, E | Implemented | Signal report now numbers entries in the observed `N. ### Name (Area) PLS: n` format (`code/modules/modular_computers/file_system/programs/medical/suit_sensors.dm`). |
| Target-selection list dialogs, native OS windows for paper/inventory | M | Implemented | BYOND input()/browse() conventions. |
| Hover context tooltip of blue examine text | M | Partial | |
| Idle flavor self-messages ("You raise your head and look at the ceiling…") | W | Missing | |

## Implementation status (video-parity pass)

Implemented in `code/modules/os13/os13_video_parity.dm` plus targeted edits
(compiled from `Interpost-Hague.dme` with 0 errors, 0 warnings):

1. Posthibernational psychosis: cryo-wake trait chance, trait card, episodic
   white-out overlay with chat spam and onset announcement, drunk DISCHARGE and
   counselor TREATMENT cures.
2. File-investigation minigame on filing cabinets with page countdown,
   sit-to-read speedup and mapper-set lead payoffs.
3. Loyal-crew objective sheet at round start in traitor-tag modes.
4. Spoken cabin passwords (`/obj/machinery/door/airlock/os13_cabin`).
5. Scout Console command set (`/obj/machinery/computer/os13_scout`).
6. Personally locked crew console (`/obj/machinery/computer/crew/os13_locked`)
   and the numbered `N. ### Name (Area) PLS: n` signal report.
7. Feedback lines: darkness stumble, injury-gated pickup, hunger tick,
   cryo-wake hangover, vacuum "You cannot breathe anymore.", airlock cycling
   pressure status, meteor proximity countdown.
8. Combat prose: weapon readying line, telegraphed throw wording, hostage
   blade-to-throat grab variant, species bite fang wording.

Where the recordings truncated a message or hid a number, the implementation
uses conservative completions and local tuning; these are marked in the tables
above. The new machinery/door types are mapper-placed and do not alter
existing maps.

## Video objects and machines (OS13 art pass)

`code/modules/os13/os13_video_objects.dm` adds every object or machine named
or shown in the recordings that had no counterpart type, using the supplied
OS13 DMI assets (icon-state existence verified against the sheets before use).
All are mapper/admin-placed; no existing maps were altered.

| Type | Evidence | Art |
| --- | --- | --- |
| `computer/os13_radar` — Radar Console | marshal 2:10:12 (bridge, struck in melee) | `computer.dmi: radar/radar0/radarb` |
| `computer/os13_scout_controls` — Scout Controls | marshal 1:04:30 cockpit examine | `computer.dmi: rcomm/rcomm0/rcommb` |
| `computer/os13_atmos_reports` — Atmospherics Reports Console (personal unlock + air-alarm kPa report) | marshal 33:57–34:09 | `computer.dmi: tnc1*` |
| `computer/os13_scout` — Scout Console (reskinned from generic console art) | marshal 1:04:48 | `computer.dmi: shuttlecomms*` |
| `melee/baton/loaded/intensecure` — IntenSecure Baton | marshal 2:10:06, full-resolution | `weapons.dmi: insecure_baton`; OS13 hand/belt `baton`, inherited cell/combat mechanics. Exact balance/alignment unresolved. |
| `suit/armor/intensecure` — IntenSecure armor | marshal finale operatives | `suits.dmi: insecure`; OS13 hand/suit `insecure`. Exact protection/alignment/issuance unresolved. |
| `card/id/os13_keycard` + bridge/captain/science/intensecure | marshal 06:09, 18:12, 24:48, 2:14:12 | `items.dmi: keycard/keycard2` |
| `device/radio/os13_handheld` — Handheld Radio | marshal 42:00 examine | `device.dmi: walkietalkie` |
| `disk/os13_scan` — SCAN Diskette | marshal 12:09 throw scene | `items.dmi: datadisk0` |
| `gun/projectile/os13_maheira` — Maheira X13 | marshal 2:10:27 | `gun.dmi: pistol0/1/_empty` (model association is local choice) |
| `head/helmet/space/trinet` + `suit/space/trinet` — Tri-Net EVA set | marshal 1:02:20–1:03:45, examine text verbatim | `hats.dmi: tspacehelmet`, `suits.dmi: tspacesuit` (+onmob) |
| `stack/medical/bruise_pack/os13_hemostatic` / `os13_bacteriophage` | marshal 59:30–59:33 | `items.dmi: bandages2k/bandages2b` |
| `drinks/cans/dietcoo` — Diet Cola (corrected OCR name); `cans/pepsi` | marshal 2:07:09; waterchip 1:09:54 | `food.dmi: cola/pcola`; OS13 cola hand states; selective public gulp/positive-transfer feedback. Exact formula/supply unresolved. |
| `suit/os13_heir_dress` — Heir's Dress | marshal 2:01:24 strip window | `suits.dmi: heirdress` (no dedicated onmob survives; serving-dress body sprite stands in) |
| `shoes/jackboots/os13_child` — Child's Jackboots | marshal 2:01:24 strip window | `shoes.dmi: jackboots` |
| `ring/os13_noble` — Noble Ring | marshal 2:01:24 strip window | `rings.dmi: diamond` (no OS13 ring sprite exists) |
| `head/os13_pumpkin` — Pumpkin | waterchip 1:19:48 examine | `hats.dmi: pumpkin` (+onmob) |

Already present from earlier passes and therefore not re-added: ChargeMaster,
FixBoy-2000, Harvester, solar mounts/panels/carts, station power console,
station gas console, OS13 vendors and refill charges, food processing units,
vats/culture equipment, medical bracelets, cabin doors, crew monitoring
console, marshalling wand, security backpack, captain's hat, jetpack (oxygen),
magnetic boots, intercoms and dice.

Validation: `Interpost-Hague.dme` compiles with 0 errors and 0 warnings
(BYOND 516.1688). Manual in-game checks worth running: wake from a cryopod
(hangover line, occasional psychosis trait), trigger an episode and cure it
both ways, investigate a filing cabinet seated and standing, speak a cabin
password at its door, cycle an external airlock, let a meteor event announce,
pick up a weapon and throw an item near observers, and bite with a fanged
species.

## Remaining follow-up backlog

1. Named Scout controls are now wired to the existing flight system; recover
   exact destination, source authentication, portable beacon rescue, transit
   and docking rules before claiming source parity.
2. OS13 end-of-round report layout (THE TRAITOR: name (key), hidden-stash
   failure line) and objective point scoring.
3. Head-trauma amnesia ("You can't remember anything that…").
4. Full trait/moodlet character sheet beyond the psychosis card.
5. Contested handcuffing prose ("swings with handcuffs!"), grip-struggle
   message wording, staged alert levels, planetary psi-field system, idle
   flavor self-messages and spoken-recognition prose polish.

Each remaining item should be verified against the recordings' timestamps in
the per-video documents before implementation; none of the hidden numbers
(timers, probabilities, point values beyond those printed on screen) are
established by the recordings.
