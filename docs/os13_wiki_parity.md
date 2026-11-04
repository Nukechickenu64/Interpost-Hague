# Archived OS13 wiki parity

Source: the locally saved HTML articles in the user-provided `os13wiki` archive.
The directory contains wiki pages and their saved resources, not a new gameplay
recording. This implementation uses the OS13 crew roster shared by the
`Orbital Station 13` and `Orbital Station 13 3022` articles, including the Chief
Engineer identified in the Captain's keycard table.

This is not a claim of complete Lifeweb parity. Existing implementations and
unresolved differences are distinguished below.

The [extended eight-recording audit](os13_extended_video_audit.md) adds
timestamped gameplay evidence and production comparisons. It identifies real
generic flight and other existing foundations without treating them as exact
Scout, software, genotype, medical or afterlife parity. Its
[object/effect inventory](os13_extended_inventory.md) also records sprite
candidates and unresolved presentation contracts.

## Selectable jobs

The Alpha-based OS13 maps now use only these crew jobs:

| Job | Default slots | Department |
| --- | ---: | --- |
| Captain | 1 | Command |
| Chief Engineer | 1 | Engineering |
| Engineer | 2 | Engineering |
| Marshal | 1 | IntenSecure |
| Pilot | 1 | IntenSecure |
| Geneticist | 1 | Medical |
| Medical Officer | 1 | Medical |
| Scientific Overseer | 1 | Science |
| Cybertechnician | 1 | Science |
| Psionic-Counselor | 1 | Medical |
| Logistics Officer | 1 | Supply |
| Cadet | 1 | Civilian |

The thirteen-slot allocation is a local default consistent with the thirteen
crew members mentioned in the older station article; the archive does not
specify every individual job limit. Both job configuration files match these
defaults. Other maps retain their own selectable job lists.

[Job definitions](../maps/alpha/job/os13_jobs.dm) replace the legacy selectable
Major, Enforcer, General Researcher, Head Scientist, Greyhound and separate
service/cargo roles on OS13. Each job has appropriate department access, a
description, existing outfit support and GURPS training. Logistics combines
cleaning, cooking, hydroponics and cargo access. Medical staff can use chemistry
and surgery; science personnel can use research and cyberdeck facilities.
The Captain has full station access. Cadets are mechanically small and have
maintenance access, not automatic bridge access.

Preferences, previews, roundstart selection, latejoining, manifests and temporary
cryo cards use the actual job datums. The fallback preference names Cadet rather
than Assistant and returns players to the lobby when that slot is full.
Existing cryosleep/no-starting-equipment behavior is preserved; this does not
place new uniforms or role equipment throughout the map.

## Round-start and opening story

Alpha crew now receive persistent, once-per-mind role/awakening notes rather
than generic Nanotrasen wake-up monologues, including on latejoin. An
idempotent emergency broadcast gathers the crew on the bridge. The Captain's
repeatable **General Report** presents the recovered 23 August 3022 incident
record separately from current station readings; its single printable copy
uses the same content. The date revelation remains in the report rather than
being announced to everyone at spawn. Existing recovery objectives now
progress independently of the Director being enabled.

The [startup-readiness continuation](os13_extended_operations_audit.md#startup-readiness-and-wake-lifecycle-continuation)
adds actual power-supply checks shared by the bridge and Director, live
Replicator/solar/clone-record inventories, explicit interrupted wake state,
round-end timer/alarm cleanup and missed loyal-sheet delivery on reconnect.
The Classic map's missing direct power-controller/solar placements remain a
deployment gap, not something narrative text or a nominal telemetry score repairs.

See the [round-start continuation](os13_extended_operations_audit.md#round-start-story-and-bridge-continuation)
for inspected video timestamps, scenario-version boundaries, integration,
announcement safeguards and manual acceptance. This reconstructs an opening
briefing, not the complete original malfunctioning-AI/traitor mission chain.
Narrative damage entries do not generate or guarantee current physical faults.

## Newly implemented mechanics

| Archived evidence | Implementation |
| --- | --- |
| Counselor: instantly learns and teaches skills; knowledge lasts a few hours | `Telepathic Training` links an adjacent living human and transfers a selected higher skill in either direction. Borrowed knowledge expires after three hours; refreshing a loan does not stack bonuses. Later ordinary learning is retained when the borrowed contribution expires. |
| Counselor: senses emotions and remembers recent phrases on examination | Examining a person displays their broad emotional state and, when available, an echo of recent spoken words. It does not inspect unsent client input or fabricate future speech. |
| Counselor: examine an object in combat mode to identify its recent handler | Adjacent combat-mode examination reports the last recorded character touch, including gloved touches. Only the in-character name is displayed, not player keys or administrative forensic logs. Objects without recorded touches report no impression. |
| Counselor: use a taser on a clone to offer it to wraiths | A stun/agony shock to an available fresh clone notifies eligible observers and explains the existing double-click possession interaction. OS13 clones must be ejected and offered before observer recruitment. Recruitment is throttled, never forces a volunteer and leaves existing occupation checks intact. |
| Counselor: implanted Psi-Boost enables remote vision and thought transmission | A research-gated surgical PsiBoost product grants both communications controls to organic operators. Same-deck targeting, lifecycle cleanup and delayed-input checks are wired. This is a partial product, not the random/advanced active-power system; see the [counselor continuation](os13_extended_medical_audit.md#psiboost-communications-and-counselor-continuation). |
| Counselor: Healing Headphones treat insanity | Fabricatable OS13 headphones cure existing posthibernational psychosis after one minute of uninterrupted wearing. Removing them resets treatment. Counselors and Medical Officers can also use the existing counseling interaction. |
| Scientific Overseer: replacement technicians require a Schriebmann Port | Cybertechnicians begin with a surgical neural port. On OS13, cyberdeck boot and the active connection require a working installed port. Spare ports can be fabricated and implanted through existing organ surgery; removal/failure terminates the link through the existing recall path. |
| Captain: toggle shields and select cardinal/360-degree coverage | Bridge controls operate real station shield generators, respect damage/cooldown and locked direction settings, and require command access. Startup broadcasts the maintenance-tunnel warning. Existing generator discharge and per-tile power costs are retained. |
| Captain: Today Reports, approved documents/erasure and Salvage Coordinates | Alpha bridge controls provide shared bounded broadcast history, registered numbered-file locations and confirmation-gated registry erasure. Station-wide salvage authorization gates ordinary/legacy navigation, named Scout controls, Prospector couches/uplinks, revisit and ruin-signal dispatch. Source defaults/formatting and exact approval rules remain unverified; see the [operations continuation](os13_extended_operations_audit.md#bridge-authority-flight-state-and-raw-material-continuation). |
| Maintenance: wrench repairs an exposed solar base | Wrench repair is added after panel removal, with interrupted-action checks. Existing welder repair remains available. |
| Save Lives: mouth rescue breaths and chest compressions | HELP intent distinguishes mouth breaths from chest compressions. Mouth coverings do not block compressions. Existing revival probability is retained; CPR cooldown and actor handling are corrected. |
| Save Lives: relocate dislocated joints | The WRENCH grab action relocates eligible dislocations using existing painful joint treatment, checking parent joints and interruption. |
| Save Lives: gauze and a wooden stick stabilize fractures | Gauze with an offhand stick applies a removable splint and consumes one gauze. |

The three-hour skill loan, ten-minute speech-echo window, one-minute headphone
treatment and one-minute clone-offer throttle are local choices, not recovered
Lifeweb timing. Base ability access is tied to the Counselor's character training;
it is not automatically inherited by a new clone.

Implementation:
[Counseling and neural equipment](../code/modules/os13/os13_wiki_counseling.dm),
[bridge shield control](../code/modules/os13/os13_wiki_bridge.dm),
[cyberdeck link checks](../code/modules/cyberresearch/cyberdeck.dm),
[solar maintenance](../code/modules/power/os13_solar.dm).

Medical additions:
[resuscitation](../code/modules/mob/living/carbon/human/human_attackhand.dm),
[joint relocation](../code/modules/mob/grab/special/grab_special.dm),
[improvised splints](../code/game/objects/items/stacks/medical.dm).

## Existing coverage and remaining gaps

| Article or system | Current coverage | Still missing or not established |
| --- | --- | --- |
| Captain / station AI | Persistent awakening/role notes, once-only bridge assembly broadcast, repeatable General Report with historical/live readiness sections and a stamped printable snapshot, actual-supply recovery checks, mode-independent progress, round-end wake/alarm cleanup, station telemetry, validated announcements, evacuation controller, real shield controls, bounded Today Reports, approved-file registration/erasure and station-wide salvage authorization exist. Physical RemCom now provides selected real remote bridge operations; see [continuation](os13_weapon_parity.md). | Classic's direct power-controller/solar deployment, original initial damage/transmission progression, exact report classification, registry approval/location rules, original RemCom controls/art/full coverage, cargo-lock command, mission-dependent evacuation and emergency self-destruction rules. |
| Pilot | Generic expedition/spacecraft backends, mining, oxygen/jetpacks, EVA gear and movable cryopods exist. Configured named Scout controls use their onboard controller without a buckling gate, and report actual transit/ETA. Compatible registered SOS/ruin dispatch and salvage permission reach legacy/couch/uplink routes. Hand-fed and platform-reclaimed raw ore share full-nugget accounting. Classic now initializes a 35-tile Scout with passenger seating, home/transit/space destinations and real portable-beacon rescue; see [missing objects](os13_missing_objects.md). | Original hull/layout, complete destination menus/ETA formula, beacon activation/range/rescue rules, authentication, Charon, landing module, Evergreen, satellite/Lance, derelict population and original mineral yield/distributions remain unresolved. See the [flight comparison](os13_extended_operations_audit.md). |
| Scientific Overseer / Cybertechnician | A physical chair/helmet/port link, generated cyberspace, relay puzzles, research diskettes, failure recall and fabrication exist. | The wiki's exact four-level individual-technology dependency tree, automatic initial Core Diskette, military-chip installation, brain damage on failed dives, named ICE-Pick/Scan software, blue/red/black/unstable ICE rules, scanner/spore/carp guardians, detection grace period, advanced limb-amputating cyberdeck and advanced port are not reproduced by the current generic research maze. |
| Logistics Officer | ChargeMaster refills, water-chip supply, culture vats, skimming, biomass pressing, food processing and cloning feedstock already exist. | Exact refill-dispenser inventories, prices and every recorded room placement remain unverified. See [water-chip coverage](os13_waterchip_video_parity.md). |
| Medical Officer | Existing medical scanning, chemical dispensing, wound treatment, defibrillation, cloning, suturing and bone surgery are retained; manual CPR, relocation and splint gaps above are addressed. The [medical implementation batch](os13_extended_medical_audit.md#implemented-medical-batch) adds Medvisor diagnosis/search, a charged four-mode Medi-Kit and surgical-laser closure/suturing. The [supplies batch](os13_extended_medical_audit.md#implemented-medical-supplies-batch) adds regional dressing removal, reliable bandage commitment, OS13 scalpel/bone-gel products and a five-dose blood-substitute injector with fabrication designs. A [fabricatable Artificial Liver](os13_extended_medical_audit.md#implemented-artificial-liver-batch) now uses OS13 art and real robotic-organ transplant mechanics. The [Chemfabricator batch](os13_extended_medical_audit.md#implemented-chemfabricator-and-reagent-supply-loop) adds the mapped water/chemical-charge machine, replacement supply order, keycard lock, composed OS13 artwork/emissive screen, 17 recorded menu entries/costs and functional Dylovene/Hyperzine injectors. The [medicine-product continuation](os13_medicine_parity.md) adds distinct Hyperstim, Mnemosine, Oxivior, Monogreline and Polythesine products with real fabrication, injection and physiological effects. The [psychocorrection continuation](os13_psychocorrection_parity.md) adds paired physical machinery, actual spoken recording and guarded brain-bound trigger responses. | Exact Medvisor input/filter, original medication/removal timing/doses/refills, remaining named medicines and original pharmacology, including exact Hyperstim balance/risks, original Chemfabricator doses/capacities/contamination/plumbing, artificial-organ coefficients/lifetime, automatic nurse/medchamber parity, full psychocorrection and subpersonality installation/control, tourniquets, direct cardiac massage, heated-weapon emergency cauterization and exact disease/radiation progression. |
| Geneticist | [Genetics continuation](os13_extended_science_audit.md#genetics-media-and-clone-recruitment-continuation): mapped Genetics Console and two lettered pods, independent genotype snapshots, full GENECODE import/export, blank media supply, atomic biomass commitment and shock-gated clone recruitment. [Cloning-art continuation](os13_extended_science_audit.md#cloning-art-linking-and-lifecycle-continuation) adds verified OS13 pod/disk assets, readiness indicators, stable links and guarded feedstock/occupant lifecycle. A separate [genetics biomass grinder](os13_extended_science_audit.md#genetics-biomass-grinder) now recycles organic material into clone-compatible bricks using OS13 sprites. Existing DNA modifier remains separate. | Authored Genemod sequence effects/markers, skill hints and defect-risk formula, exact source phenotype/stat inheritance, indicator thresholds, grinder recipes/yields/timing, costs, growth and injury behavior. |
| Psionic-Counselor | Skill transfer, psychometry, emotion/phrase reading, shock-gated clone recruitment, psychosis counseling and headphones are wired. A partial research-gated PsiBoost organ adds lifecycle-safe remote vision and private thought transmission. | Random/advanced PsiBoost powers and Intelligence/Willpower expenditure. The article says nine advanced powers but lists ten; no arbitrary missing-power selection was inferred. Communication tuning, padded-cell placement and identical effects are unverified. |
| Station Maintenance | Solar servicing, power distribution, atmospherics and shields exist; wrench repair is added. | Exact Modcon/FixBoy/foam-container interaction chain, antenna repairs, glass-shard console repair and every radiator workflow. |
| How to Fight | Existing GURPS combat modes, hit locations, shock, gun safety and individual shield defenses are present. | Exact numerical balance, half-swording/armor-joint targeting, adjacent shield-wall bonuses and grab-triggered hostage retaliation. Presence of a similarly named feature is not proof of parity. |
| Marshal / Cadet | Both are selectable; small-body access and physical numbered-file investigation exist. The verified junior-staff clue depends on actual eligible traitor roles, with shared file progress/exhaustion. [Cabinet browsing](os13_extended_operations_audit.md#cabinet-browsing-continuation) now enables unread-file retrieval, specific-file investigation and larger page counts. | Other evidence categories, cross-file references, source generation/probability/cadence and memory effects remain unverified. Cadet age/body appearance and original technical-tunnel movement need runtime/reference verification. |
| Station 3022 traitor scenario | Reconstructed sabotage/hibernation opening and incident report, generic traitor gameplay, and once-per-mind informational loyal-crew sheets for starting/latejoining traitor-tag crew exist. Dynamic retains its own delayed traitor/leech/logomancer selection. | Original fixed-traitor delayed memory restoration, closed-tunnel cache, scenario bomb placement, genetics/bridge viruses, lifeboat escape conditions, scored crew rewards and Hall of Fame persistence. |

The saved Game Modes page predominantly describes Ravenheart fortress scenarios,
not additional OS13 crew jobs. The Prologue page is setting history rather than
an OS13 interaction specification. The saved Russian change-log article contains
obfuscated text and cannot reliably define gameplay. The accompanying GURPS
book is not treated as an instruction to replace every local rule or copy book
content. These sources were not used to invent unrelated fortress systems.

## Validation

Historical validation of the earlier wiki implementation used normal compilation
from the Interpost-Hague repository root:

```powershell
& "C:\Program Files (x86)\BYOND\bin\dm.exe" "C:\Users\nukec\Documents\GitHub\Interpost-Hague\Interpost-Hague.dme"
```

That earlier result was **0 errors, 0 warnings**; it does not validate subsequent
continuations. The round-start continuation uses focused static/include and
whitespace inspection only, with no compiler or live-client verification.
Earlier focused static inspection verified the exact
twelve job titles, thirteen default slots, both configuration files and the
referenced OS13 sprite states. No unit tests or Dream Maker IDE were used.
Compilation is not a substitute for a live gameplay session.

Manual checks still needed:

- Start a new round and inspect job preferences and latejoin lists; confirm old
  job titles are absent and a full Cadet slot returns a fallback player to lobby.
- Wake each role, inspect access cards, skills and role-specific initialization.
- Learn and teach with the Counselor, train a clone, refresh a loan, and verify
  expiry does not remove subsequently learned skill.
- Examine an object before and after another character handles it, with gloves,
  out of range and with combat mode switched off.
- Wear/remove the Healing Headphones during a psychosis episode.
- Shock an empty clone and occupy it with an eligible observer.
- Boot a Cybertechnician, implant a spare port in a volunteer, and remove or
  damage the active technician's port to confirm safe recall.
- Control shields with/without command access, while cooling down and with the
  control wire cut; compare cardinal coverage and full-coverage power demand.
- Interrupt solar wrench repair; perform rescue breaths, compressions, joint
  relocation and improvised splinting on the appropriate injuries.
