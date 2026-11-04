# Extended OS13 object, sprite and effect inventory

See the [audit scope, source IDs and limitations](os13_extended_video_audit.md).
This is an evidence-backed inventory of identified objects and selected
visible families, **not a census of every prop in every frame**.
Technology retrieval is not proof that a physical item was fabricated.
Entity names are not proof of autonomous NPC behavior.

Evidence references resolve to the [medical ledger](os13_extended_medical_audit.md),
[operations ledger](os13_extended_operations_audit.md) and
[science ledger](os13_extended_science_audit.md).
**F** = functional foundation present; **P** = partial identity/contract;
**U** = exact implementation or evidence unverified; **M** = particular
observed contract absent from examined production surfaces.

## Visual effects

| Effect | Evidence | Status and required comparison |
| --- | --- | --- |
| OS13 space parallax | Supplied `space2` artwork request and OS13 HUD star sheets | F/P: Alpha-family maps use native animated `fullscreen4.dmi` `space2` and three stable, independently moving authored star layers, tiled to the current viewport. Legacy map/universe backgrounds remain available. Motion speeds/density are local reconstruction choices; live rendering and exact source parity remain unverified. See the [parallax integration](os13_extended_operations_audit.md#os13-animated-space-and-parallax). |

## Objects and machines

| Object/family | Evidence | Status and required comparison |
| --- | --- | --- |
| Handcuffs | Marshal arrest sequence, 02:00:48–02:14:00 | F/P: standard cuff attack emits recorded swing line; strip-interface removal emits unhandcuff message through the existing timed success-only unequip path. Exact struggle messages and source timings/requirements remain unresolved. |
| IntenSecure Baton / armor | Marshal 02:10:06, V; earlier marshal finale audit | F/P: OS13 baton hand/belt and armor hand/suit art connected; documented aimed right-hand baton wording added to both combat paths. Exact source protection, stun/combat coefficients, other quality tiers, alignment and issuance remain unresolved. |
| Diet Cola / Pepsi | Marshal 02:07:09; Water-chip 01:09:54, V | F/P: corrected Diet Cola name, OS13 hand art and observed public drinking/pouring feedback use existing real reagent actions; exact formula, doses, source supply and Pepsi hand-overlay match unresolved. |
| Environment impacts and strikes | GEN/AI 00:57:30; marshal finale, V | F/P: dense wall/window feedback uses observed wording and preserves impact effects; eligible dense structures report thrown-body collisions. Harm-intent bare-hand/table-item strikes print “hits [table]” without damage-path changes. Pod identity/path and other deliberate environment strikes remain unresolved. |
| Body carry on back | Marshal 1:16:00, V | U: footage records “is trying to carry [person] on their back”; current code supports pulling/dragging, not carrying on the back. Eligibility, timing, interruption, movement, and release rules need further source evidence. |
| Scout Controls | FLT-03, FLT-11; RUIN 00:12:00, V | P: bound to real onboard expedition controller; standing or seated authorized operation, actual transit examination/ETA and shared salvage permission. Source route/layout/ETA formula unresolved. |
| Scout Console | FLT-08 | P: now uses real craft status and registered SOS/ruin landing-site search/dispatch. Exact security exchange and portable beacon rescue unresolved. |
| Scout spacecraft | FLT-03, FLT-08; PIL 00:05:40, V | F/P: Classic's existing 35-tile craft now has a correct shuttle area, home/transit navigation, distinct consoles, pilot chair and four OS13 passenger seats. Its existing Space waypoint and exterior berth are retained. Exact source hull/layout, routes, authentication, ETA and client visuals remain unverified. See [missing-object continuation](os13_missing_objects.md). |
| Four Scout chairs | FLT-03, FLT-08 | F/U: ordinary seating exists; pilot/passenger authority and exact art/layout need matching. |
| Radar Console | Earlier recordings; cross-system matrix | P: real overmap/sensor-backed read-only scan where infrastructure exists, explicit unavailable status otherwise; OS13 map lacks a mapped suite. Exact source detection/UI/beacon integration unresolved; not newly proven in this set's selected action frames. |
| Atmospherics Reports Console | CAP-08; CAP 00:29:50, V | F/P: inherited use guards, temperature/volume-correct pressure from operational station alarms, distinct-area accounting and powered OS13 illumination connected; exact source report layout/access/history unverified. |
| Main/Bridge Computer | Captain wiki; CAP 00:09:30, V | F/P: repeatable General Report separates historical story from live power/research/solar/clone-record readiness; actual-supply recovery checks and cancellable wake lifecycle supplement Today Reports, registry/erasure, salvage permission and shields. A physical RemCom now routes selected real bridge operations remotely with credential/power revalidation. Classic's power/solar deployment, exact original reporting/approval, Cargo Airlock and complete source RemCom contract remain unresolved. See [remote-device continuation](os13_weapon_parity.md). |
| Crew Monitoring Console | CAP-01, CAP-09 | F/P: monitoring and initial access handling; source classification/diagnostic integration differs. |
| Primary Computer / Security Console | SCI 00:03:10, O | F/U: general station consoles exist; exact menus/authority not recovered from these labels. |
| Captain Keycard | CAP-08 | F/P: named access item now retains its label on initialization and uses OS13 held art; exact permissions, worn art and issuance unresolved. |
| Bridge Keycard | SCI 00:09:50, V | F/P: named item now retains its label and uses OS13 held art; exact department/rank behavior unresolved. |
| Scientific Department Keycard | SCI 00:09:50, V | F/P: retained label/OS13 held art; inherited physical throwing/access. Card throws hit characters in footage; exact impact strength unresolved. |
| Medbay Keycard | SCI 00:09:50, V | P: physical OS13 product now exists with retained label, OS13 held art and local medical access; source permission matrix, issuance and worn art unresolved. |
| Numbered File | CAP-05; CAP-12; FLT-05 | P: File #N media now supports pre-reading cabinet retrieval, specific-file reading, OS13 hand art and larger page counts, retaining progress/exhaustion and verified junior-role evidence. Source ID scheme, generation, cross-file references and other categories remain unresolved. |
| Technology Diskette | SCI-02, SCI-08 | P: OS13 media product, real stored-research examination and replicator design now exist. Single-datum storage remains; multi-technology source contents/software installation unresolved. |
| Filing cabinet | CAP-03, CAP-07 | F/P: OS13 cabinets now investigate physical files, retaining progress through transfers; exact source generation/counts/reading rules unverified. |
| Pocketwatch | CAP-02, V | P: OS13 watch item art, real station-time examination/self-use and fabrication now exist; held mapping, source clock origin/format and issuance remain unresolved. |
| Captain hat | CAP-01 | U: role outfit foundation; exact held/worn states not certified. |
| Handheld Radio | MED-22; MED 00:58:00, V; ALIEN 00:04:50, O | F/P: OS13 world, hand and neck art, neck storage, held-only transmission and explicit refusal implemented; inherited reception, source channels/range, belt art and body alignment not certified. |
| Distress Beacon | FLT-01, FLT-15; ALIEN 00:02:40, V | F/P: distinct physical neck-wearable beacon, live/off/deleted signal handling, fabrication/cargo supply and real Scout rescue approach now exist. Original activation/range/rescue rules, recipes, ETA and alignment remain unverified. See [missing-object continuation](os13_missing_objects.md). |
| Tri-Net Space Helmet | FLT-02, FLT-07 | F/P: replicator product, OS13 world/worn/held sheets and integrated lamp-on state connected; source recipe, damage/breakage, protection/lamp rules and alignment unverified. |
| Broken Tri-Net Space Helmet | PIL 00:20:10, V; FLT-08 | F/P: distinct wearable subtype now uses the supplied broken item/head art with no pressure seal or lamp. Source damage/repair chain, protection coefficients and held pose remain unverified. See [missing-object continuation](os13_missing_objects.md). |
| Tri-Net Space Suit | FLT-07; EXP-01 | F/P: replicator product and OS13 world/worn/held sheets connected; source recipe, sealing/wear/armor/sleep restrictions need matching. |
| Space Suit Boots | FLT-07 | P: separate wearable/replicator product, OS13 spaceboots item art and OS13 jackboots held mapping now exist; generic worn art, source protection, exact recipe and issuance unresolved. |
| Magnetic Boots | PIL 00:04:20, V | P: distinct OS13 item/held product and fabrication reuse actual mag-pulse grip/undershoe mechanics; paired worn art uses generic fallback, source slowdown/activation/protection unresolved. |
| Breath Mask | FLT-07 | P: named OS13 item/worn product and replicator design now reuse real breath-mask internals mechanics; held mapping, source coefficients and alignment remain unverified. |
| Gas Tank (Air Mix) | FLT-07, ALIEN 00:43:10, V | P: OS13 item/hand/back art, observed real remaining-gas wording, inherited mixed-air mechanics and empty fabrication now connected; source capacity/refill/damage/art alignment unresolved. |
| Emergency oxygen tank | FLT-15, ALIEN 00:45:40, V | P: observed emergency oxygentank identity, OS13 item/hand/belt art and empty fabrication now reuse real emergency-oxygen mechanics; source capacity/readout/alignment/issuance unverified. |
| Jetpack (Oxygen) | FLT-03; EXP-01, EXP-03 | P: OS13 item/hand/back on/off art and empty fabrication now reuse real gas-consuming propulsion/stabilization; exact source percentage wording, damage, repair and thrust effects unresolved. |
| Air Canister | RUIN 01:00:00, O; ALIEN 00:30:30, 00:51:10, V; supplied canister_new sheet | P: separate OS13-art station filling point and supply order now compose all five fill animations with emergency/large/jetpack/yellow-tank insertion overlays. Actual inserted-tank nominal fill drives the display; shared-reserve refill and retrieval retained. Original thresholds/rates and live alignment remain unverified. |
| OS13 oxygen tank | Supplied oxygen-tank artwork and existing oxygen-tank mechanics | P: separate pure-oxygen subtype now uses OS13 world/hand/back art, with empty replicator output and filled supply order alongside emergency tanks. Air Mix remains a distinct actual gas mixture; source capacity, pressure, recipe and original pure-oxygen product identity are not certified. |
| Dosimeter | PIL 00:22:50, V; ALIEN 00:54:30, V | P: OS13 device art, portable event-driven exposure record, Gy readout and replicator design now exist. Zero Gy observed; nonzero calibration, container propagation, reset/alarm rules remain unverified. |
| TNC Gravcutter | FLT-13, V for tool | F/P: observed name and same-tool replicator design now use existing OS13 art/instant excavation; source charge, damage/repair and combat modes unresolved. |
| Harvester | SCI-15 | F/P: actual powered collection/unload snapshots contents, tracks committed transfers and reports partial-release failure; physical-use guards and a cargo acquisition/replacement crate exist. Source issuance, collected set/capacity/input unresolved. |
| Scrap | EXP-02, SCI-16 | F/U: physical salvage exists; source resource content and conversion yields unresolved. |
| Elerium | FLT-13; SCI-04, SCI-16 | F/P: internally plasteel; full-nugget recovery is now consistent between hand-feeding and platform reclamation, without scrap-rate loss or partial-capacity consumption. Source identity/units remain unresolved. |
| Zrbite / zbrite ore | FLT-13, SCI-04 | F/P: internally glass; shared full-nugget recovery with no loss on insufficient storage. Naming/spelling/art and original output units remain unresolved. |
| Gold ore | ALIEN 00:22:30, O | U: physical examine lead; not proof of mineable three-resource parity. |
| Gem Ore | ALIEN 00:31:20, O | U: physical examine lead; source uses/generation not established. |
| FixBoy-2000 | FLT-04, V | F/P: real diagnostics now have replicator supply, OS13 held mapping and actual-hand use guards; exact source targets/UI/costs and belt artwork unresolved. |
| Advanced FixBoy | Archived Scientific Overseer catalogue, Tier 2 | F/P: distinct technology-gated product retains FixBoy functions and operates actual remote station Modcons through their native menus. Access, device ownership, power, area boundaries and stale-dialog checks apply. Exact source controls, range and art remain unverified. See [remote-device continuation](os13_weapon_parity.md). |
| RemCom Device | SCI-14; CAP-10; archived Scientific Overseer catalogue | F/P: distinct technology-gated handheld operates actual bridge reports, approved documents, salvage permission and shields. Command credentials and held-device/live-bridge checks apply. Exact source art, network/power model and full command coverage remain unresolved. See [remote-device continuation](os13_weapon_parity.md). |
| Light Switch | FLT-04 | F/U: explicit off state; exact local light grouping/power behavior not certified. |
| Cargo conveyor | EXP-02 | F/U: cargo automation exists; belt directions/routing and map placement unverified. |
| Ancient crate | RUIN 00:03:50; ALIEN 00:44:00, O | F/U: container foundation; random contents, provenance and reluctance text not exact. |
| Vault | EXP-01 | U: no opening method visible; do not invent an unlock puzzle. |
| Cryosleep Chamber | EXP-01; EXP-03 | F/P: cryopod foundation; authored derelict occupant/wake conditions differ/unverified. |
| Lattice, grilles and exterior walkways | EXP-03 | F/U: actual structures; tile layout and directions not mapped by this audit. |
| Ladder, hatch and maintenance hole | OVR 00:09:40, V; ALIEN 00:55:40/01:02:50, O | F/U: traversal foundation; exact destinations and movement/access timing unresolved. |
| ChargeMaster | MED-28 | F: precursor conversion exists; source product list, timing and failure/power presentation unverified. |
| Precursor charge | GEN 00:13:10, V; SCI-17 | F/P: generic refill input exists; observed scarcity is not an exact economy specification. |
| Soda Machine Charge | MED-28 | F/P: refill family exists; exact item/charge sprite and consumption need comparison. |
| Chemistry charge | MED-23; SCI-17 | F/P: supplies the separate water-fed Chemfabricator's finite feedstock; generic cartridge refill support remains. Exact original yield is unverified. |
| Replicator / Reclaimer platform | SCI-15, SCI-16 | F: queue, real material consumption/output/reclaim and pulse. Exact separate source device identities need verification. |
| Replicator storage controller | SCI-04 | F/P: real shared compartments; exact geometry and stock units unresolved. |
| Steel storage | SCI-04 | F/P: independently locked supply; source display/capacity not measured. |
| Elerium storage | SCI-04 | F/P: independently locked plasteel-backed supply. |
| Zrbite storage | SCI-04 | F/P: independently locked glass-backed supply. |
| Diskette | SCI-02 | F/P: generic physical media; exact payload cardinality and display differ/unverified. |
| Core Diskette | SCI-04 | P: distinct OS13 technology-disk subtype now uses the existing cyberdeck/R&D disk contract and art. Source provisioning, initial payload and console relationship remain unresolved; it is not automatically stocked or given invented data. |
| SCAN Diskette | SCI-03 | P: named flavor item locally, not an installed Scan-software implementation. |
| ICE-PICK Diskette | SCI-03 | P: distinct physical OS13-art diskette now carries the observed ICE-Pick Mk.I identity. The source's software installation mechanism, provisioning, and interaction remain unverified; it is not treated as a research-data disk. |
| Cyberspace Core Console | SCI-06 | F/P: real generic cyberdeck research console; source name/UI/software/archive behavior differs. |
| Cyberspace Deck / neural seat | SCI-11, SCI-18 | F/P: existing chair/helmet link; source art, body positioning and helmet controls need comparison. |
| Schriebmann Port | MED-06; GEN-05 | F/P: real OS13 internal organ/design; source spelling/art/timing not certified. |
| Advanced Schriebmann's Port | SCI-11 | P: distinct OS13-art product/design now uses existing neural-port surgery and connection checks; advanced effects, original recipe, discovery/media installation and live operation remain unverified. |
| Genetics Console | GEN-01 | P: mapped counter console links the scanner and two lettered pods without releasing ownership on refresh; scanner discovery preserves orientation and explicit cross-area multitool links survive. Snapshot scanning and full GENECODE import/export work through real records; original UI/art and data format remain unverified. |
| Genetics Chamber | GEN-01, GEN-06 | F/P: generic scanner foundation; exact scanning, genotype operation and injury behavior unresolved. |
| Genemod Console | GEN-06, GEN-07 | M: authored sequence menu/risk/GENECODE contract not found in examined production genetics. |
| GENECODE item | GEN-10 | P: OS13-art named physical genotype disk, independently copied full/partial records, write protection and blank-media cargo supply. Source serialization, authored sequences and initial provisioning remain unverified. |
| Clonepod A / B | GEN-01, GEN-02 | P: two mapped pods now use the OS13 cloning sheet, real-readiness indicators, stable lettered links, guarded feedstock commitment and external-occupant cleanup. Exact source indicator thresholds, growth rates and resource quantities remain unverified. |
| Clone / named clone | GEN-04, GEN-12 | F/P: actual fresh claimable body exists; source phenotype/naming/control not fully mapped. |
| Biomatter / biomass | GEN-02, GEN-12 | F/P: real growth resource exists; source units, products and costs unresolved. |
| Genetics biomass grinder | Supplied cloning-sheet sprites | P: separate mapped Genetics machine uses OS13 bases/paddle/glass overlays; meat, organic organs and stripped dead organic bodies become clone-compatible biomass bricks. Power pauses, input ownership and output commitment are guarded. Recipes, yields and cycle times are local integration, not source-certified. |
| Wall bar | Supplied `nbar` sprite | P: placeable anchored, nonblocking wall fixture at `/obj/structure/os13_wall_bar`, using `orbital_decor.dmi`. No dispensing, storage or map placement inferred from the image. |
| Shuttle console art | Supplied `rcomm` sprites | Shuttle-control consoles and the legacy shuttle authorization console use OS13 `computer.dmi`: `rcomm` powered, `rcomm0` unpowered, `rcommb` broken. Full sprites replace legacy screen/keyboard overlays; broken/off states emit no light. Mining lift platform display and shuttle controls remain unchanged. |
| Computer emissive screens | Supplied `computer_overlay.dmi` | Matching OS13 console families now render screen-only overlays above lighting while powered/intact. Shared mapping follows the existing computer import families; modular desktop consoles, custom scout controls/atmos reports/scanner terminals, power monitors and solar controls are included. Off/broken updates clear old glow. No mismatched overlay is forced onto shuttle, radar, multi-tile bridge or laptop artwork without a matching supplied screen mask. |
| OS13 door catalogue | All 50 recursive sheets in `icons/os13/objects/objects/doors/` | 62 placeable door types cover every sheet, including alternate cave/office/gate leaves and both window-door sides. Shared rendering resolves each sheet's actual closed/open/animation names, keeps all lower/foreground frame pieces separate from the leaf, follows direction changes, and renders authored light states above lighting only while operational. Shutters share animation cleanup; the alternate office includes its coloured indicators. Existing OS13-skinned doors inherit the same handling. Airlock, shutter, firedoor and window-door mechanics are retained. See [door rendering coverage](os13_extended_operations_audit.md#os13-door-catalogue-and-layered-rendering). |
| OS13 closet family | Supplied `closet.dmi` sheet | P: placeable `/obj/structure/closet/os13` family covers standard, NT, blue/dark/damaged equipment, black, suit, biohazard, red, emergency/transparent/compact, medical, refrigerator halves/double-door, wardrobes, mining, fire, security, cabinets, green, Cerberus, sarcophagus, coffins, mailbox, organic and bloodstained variants. Existing storage/open/close/welding behavior is reused; black/suit opening animations and paired open sprites are wired. No stock, access restrictions, magical effects, refrigeration or map placement inferred from artwork. |
| OS13 couches and armchairs | Previously unused `couch.dmi` sheet | 14 placeable `/obj/structure/sofa/os13` types cover every supplied furniture state. Twelve seat-bearing sprites retain existing buckling, occupancy and direction-dependent draw order; the two partial sectional extensions cannot buckle occupants. No original comfort/stat effects or room placement inferred. |
| OS13 cargo containers and chests | Previously unused container families in `storage.dmi` | 12 placeable `/obj/structure/closet/crate/os13` types cover equipment cases, ancient/wooden/technical/ornate chests, red cases and cargo containers; existing storage, capacity and crate interaction paths are retained. Equipment-case animations and cargo foreground lip are wired. No generated treasure or source inventories inferred. |
| OS13 electronic safes | Previously unused `newsafe.dmi` | Two functional `/obj/structure/safe/os13` types use new/old casing, opening/closing/denial animations and matching emissive status masks. Inherit the local combination-dial lock, not a recovered original electronic/keypad protocol. Input ownership, nearby interaction and capacity recalculation are guarded in these subtypes. |
| OS13 bookcase | Previously unused `bookcase.dmi` | `/obj/structure/bookcase/os13` stores/retrieves real books and uses empty art plus 15 authored fill tiers. It retains local naming, dismantling and library interaction rules, with held-book insertion and delayed retrieval revalidation. No source titles, categories, initial stock or placement invented. |
| Implanter | GEN-06 | F/U: generic implantation tools exist; exact source brain/sequence/port device not identified. |
| PsiBoost Implant | Counselor wiki; SCI-12 | P: research-gated surgical OS13-art organ now grants remote vision and thought transmission. Random active powers, advanced product, permanent stat costs and exact communication tuning remain unimplemented/unverified. |
| Freezer | GEN 00:18:40, V | F/P: `/obj/structure/closet/crate/freezer/os13` adds supplied closed/open OS13 art to the existing freezer-container cooling foundation. Source stock, temperature, cooling rate and placement remain unverified. |
| Correctional Apparatus | MED-10, MED-12; GEN-11 | F/P: distinct powered, upright-buckling apparatus now pairs with an actual Psychocorrectional Console, captures its seated organic brain and cancels work on subject/power/link changes. Exact source art/animation/placement remain unverified. See [psychocorrection continuation](os13_psychocorrection_parity.md). |
| Psychocorrectional Console | MED-11, MED-12; GEN 01:05:00, V | F/P: separate locked medical console now records actual spoken mnemonics and commits real SLEEP/PANIC/COMBAT conditioning, with failure/cancellation and local reversal. Brain-bound Sleep works after leaving the chair, consistent with the inspected GEN speech/fall sequence. Subpersonality/psi/cognitive/Refragment procedures and exact source balance remain absent/unverified. See [psychocorrection continuation](os13_psychocorrection_parity.md). |
| Implanted cosmetic visor | MED-02 | U: eye-concealment interaction; do not equate with diagnostic device without evidence. |
| Medical diagnostic/body-search device | MED-03, MED-14, MED-20 | P: Medvisor now provides implant diagnosis, visible-body classification and sensor-aware telemetry; exact source input/filter/tuning unresolved. |
| Medical Bracelet | MED-03, MED-20 | F/P: wrist sensor foundation; source authorization/search/rad/PLS integration differs. |
| Medi-Kit | MED-27 | P: functional independent charged modes and clothing/interruption checks now exist. Source dose/timing/refill rules remain unverified. |
| Hemostatic Bandages | MED-09, MED-19 | P: named art, replicator supply, commit-time consumption and regional removal exist; exact clotting/visual states unresolved. |
| Bacteriophages Containing Bandages | MED-09 | P: replicator supply and success-only surface germ reduction exist; source wound infection semantics unresolved. |
| Blood Substitute Injector | MED-07 | P: five-dose cartridge, OS13 ready/spent art and interruptible logged nanoblood injection now exist. Five uses observed; source dose/effects/timing unresolved. |
| theosin injector | MED-07, MED-08 | P: exact source pharmacology and item state unresolved. |
| hyperstim injector | MED-24 | P: used product observed; stat stacking/duration/survival effect not measured. |
| Hyperstim injector | MED 00:54:20; 01:04:40, V | F/P: distinct physical product and formulation, real Chemfab cost-three production, attempted/completed injection and spent-object discard, temporary nonstacking GURPS combat-stat effects. Source dose/duration/risks and exact stat deltas remain unverified; see [medicine continuation](os13_medicine_parity.md). |
| Mnemosine / Oxivior / Monogreline / Polythesine injectors | MED help panel 00:54:20 and recorded Chemfab catalogue, V | F/P: four distinct physical products and formulations now affect cognitive checks, circulating oxygenation, sedation/sleep and hallucinations respectively. Actual Chemfab/injection/metabolism paths are used. Numeric pharmacology remains a local reconstruction; see [medicine continuation](os13_medicine_parity.md). |
| Jetamite / Torporine / Drenex | Medical help-panel transcription in medical report | U/P: named categories only; exact formulation, dose, effects and source product contracts remain unresolved. |
| Chemfabricator / Chemfab | Medical Officer wiki; MED 00:53:10, 00:53:30, 00:54:20, 00:54:30, V | P: mapped/orderable keycard-locked water/charge-fed machine with composed tower/tank artwork, powered/broken states and emissive screen. The 17 inspected drug entries have recorded costs; Dylovene/Hyperzine produce real sealed OS13 injectors at cost 2. Other formulations are explicitly unavailable. Five-point refills preserve existing stock; prior raw-reagent dispensing remains labeled compatibility behavior. [Implementation and limits](os13_extended_medical_audit.md#implemented-chemfabricator-and-reagent-supply-loop): doses, water use, maximum storage, remaining pharmacology and original plumbing remain uncertified. |
| Autonurse / Medchamber | Prior wiki/recording evidence discussed in medical report | U/P: not a newly verified full operating sequence in these selected frames. Do not equate later RUIN Nurse with station automation. |
| Artificial Liver | MED-06 | P: OS13 cyber-organ liver art, real robotic liver/transplant behavior and replicator product now exist. Source recipe, coefficients, lifetime and failure rules unresolved. |
| Surgical scalpel | MED-16 | P: OS13 item/hand art, replicator product and existing scalpel surgery now connected; exact source sequence/art not certified. |
| Surgical laser | MED-15, MED-16 | P: Alpha priority now closes the surgical incision after skull repair, with ordinary wound suturing retained; exact source sequence/timing/art remains unverified. |
| Bone-gel | MED-16 | P: OS13 item art, local held-tube mapping and replicator product use existing bone-gel surgery; source timing/effect not measured. |
| Retractor / forceps / drill / surgical saw / bone setter / surgical needle | MED-16 sampled surgical flow; How to Save Lives wiki | P: six OS13-art behavior-preserving tool subtypes and a separate stocked supply kit now exist. Saw has matched OS13 held art; the other five use their own world states in the held layer, with original alignment unverified. |
| Neural-port surgical route | MED 00:26:20-00:27:40; wiki head implantation | P: Alpha incision/drill/direct port removal or insertion/gel-setter-gel/laser-closure path uses real installed organs. Original implant identity, coefficients and other implant procedures remain unverified; shared interruption and stale-selection safeguards added. |
| Stationary Neuroinhibitor | MED 00:28:40, 00:29:30, 00:29:50; SCI 00:30:50 | P: placeable/orderable OS13 `inhib0` machine with switchable animated `inhib1` glow overlay and power-loss handling. Biological suppression/anesthesia is not implemented or implied; examination warns explicitly. |
| Operating / surgery tables | Medical/science surgery-room samples; supplied surgery sheet | P: Classic's existing operating table now uses OS13 idle, active, pulseless and unpowered art, plus a placeable unmonitored `table3` subtype. Existing patient/console/surgery behavior retained; exact source state conditions and runtime alignment remain unverified. |
| Shears Saniturgy | MED-05 | U: name-only lead, not a verified function or sprite. |
| Stretcher | MED-26; CAP-11 | F/U: assisted transport foundation; buckling, movement, posture and layers need source comparison. |
| Station AI core | GEN/AI discussion; FLT-05 | F/P: generic AI construction exists; exact source stationary identity/reboot unresolved. |
| Lance / HOMUNKULUS-5 | FLT-05, FLT-06 | P: embodied source unit; not simply a renamed stationary AI. Player/NPC ownership unresolved. |
| DFG700 / other synthetic units | GEN-12 | U/P: source unit identity/equipment; exact chassis/personality/control unresolved. |
| Alien | EXP-06, EXP-07 | P: generic aliens exist; recorded species attacks/skin/art need comparison. |
| Nurse / Parasite | EXP-05 | U: directly visible later RUIN entities; not proven equivalent to medical bot/xenomorph types. |
| Ghost / spectral character | EXP-09 | P/M: generic ghost exists; recorded afterlife resources/actions missing. |
| NT5 | CAP-01, MED-25; CAP 00:00:20–00:00:40, V | F/P: distinct unloaded revolver with held cylinder toggle, guarded loading/unloading, real firing and retained spent cases. Supplied closed/open artwork connected. Calibre, capacity, damage and damaged-specimen behavior remain local assumptions or unresolved. See [weapon continuation](os13_weapon_parity.md). |
| SyrV-40M | MED-01 | P: generic injection weapon foundation, exact model/charge/effects unresolved. |
| TNC Laser Gun | EXP-06; ALIEN 01:18:30–01:19:10, V | F/P: distinct cell-powered laser uses real firing/depletion, guarded physical cell replacement and supplied charge/empty sprites. Named Laser Gun technology unlocks fabrication with an uncharged cell. Source balance, battery compatibility, reload protocol and exact art alignment remain unverified. See [weapon continuation](os13_weapon_parity.md). |
| Heavy Gravpulser | Archived named technology catalogue; ALIEN 01:19:40–01:19:50 gravsphere vocabulary | F/P: distinct research-gated physical weapon now implements the catalogue's five-shot battery and armor-bypass contract, actual gravsphere collision/damage, standard station recharge and uncharged fabrication. The filmed shooter identity, original damage, servicing and exact art remain unverified. See [Gravpulser continuation](os13_gravpulser_parity.md). |
| RAX Shotgun | EXP-07; ALIEN 01:18:40–01:19:20, V | F/P: distinct physical pump-action weapon now fires real pellet ammunition, requires chamber cycling, retains/ejects original cases and guards loading, ownership and jam clearing. Security cargo supplies unloaded guns and separate shells. Calibre, capacity, balance and exact source art remain local assumptions or unresolved. See [RAX continuation](os13_rax_parity.md). |
| Stun Mine | Archived named technology catalogue | F/P: distinct carryable, single-use research product now implements physical deployment, contact stunning, electrical protection and interruptible arming/disarming. Original interaction sequence, timing, detection, strength and exact artwork remain unverified. See [Stun Mine continuation](os13_stun_mine_parity.md). |
| Maheira X13 | CAP-11 | F/P: named local .45 pistol exists; calibre/stats are local assumptions, not confirmed by this set. |
| Crossbow / iron bolt | EXP-05 | F/P: generic launcher exists; source draw/reload, aim bonuses and projectile states need comparison. |
| Spear | EXP-05 | F/U: generic melee foundation; source specific data/art unverified. |
| Streamer 23 / Talon M12A3 / Big Stabby | EXP-05; GEN-12 | U/P: source labels/weapon interactions; exact products not mapped by this audit. |
| Welder | EXP-07 | F/U: generic tool exists; source combat/repair distinction and charge states unverified. |

## Named research catalogue versus physical products

The following identities are additionally evidenced by retrieval/discovery
notices or installed-data menus. These do **not** prove physical fabrication,
placement, working effects, recipe costs or individual sprite assignments.

| Identities | Evidence | Gap to resolve |
| --- | --- | --- |
| ICE-Pick Mk.I, ICE-Pick Mk2; Scan Mk.I, Scan Mk.II; Hack Mk.II; ICE-Safety | SCI-03, SCI-09, SCI-12; CAP-10 | Authored generations, installation, active effects and dependencies; current SCAN flavor disk/relay puzzle is insufficient. |
| Battery, Energy Cell, Elerium Power Cell | SCI-05; CAP-10 | Actual recipe, charge capacities, compatibility and media identity. Generic cells do not certify this catalogue. |
| Solar Panel, Improved Solar Panel | SCI retrieval timeline; CAP-10 | Ordinary solar servicing exists; distinct improvement/unlock/recipe/output remains unverified. |
| Artificial Organ, Artificial Eyeball | SCI-05; CAP-10 | Artificial Liver and Artificial Eyeball now have OS13 physical products with existing robotic transplant mechanics and replicator designs. Authored Artificial Organ discovery dependencies, original recipes, individual-eye model and source effects remain unresolved. |
| EMP Grenade | SCI-05 | Discovery notice, not a verified fabricated/used instance. |
| Water Chip | SCI-10; CAP-10 | Existing water-chip implementation documented [separately](os13_waterchip_video_parity.md); research retrieval is not physical installation. |
| PsiBoost Implant, PsiBoost+ Implant | SCI-12, SCI-13; SCI retrieval timeline | Design installation is not surgical implantation or verified power/cost. |
| Outer Comms, RemCom Device | SCI-14; CAP-10 | RemCom now has a separate named-technology-gated physical bridge controller; source authority, range, artwork and complete command coverage remain unresolved. Outer Comms physical behavior remains unresolved. See [remote-device continuation](os13_weapon_parity.md). |
| Advanced Schriebmann's Port | SCI-11; CAP-10 | Distinct product/design now exists, sharing the ordinary neural connection. Advanced link effects and authored discovery/installation remain unresolved. |
| Laser Gun, Energy Gun, Energy Sword, Hand Tele | SCI retrieval timeline | Laser Gun now unlocks the physical TNC product; source numeric balance and recipe remain uncertified. Other named products' actual source use/art/recipes are not all demonstrated. See [weapon continuation](os13_weapon_parity.md). |
| Stunner, Flamethrower, Stun Rifle | CAP-10 | Installed catalogue snapshot only; exact distinct weapon contracts unresolved. |
| IntenSecure Light Armor, Assault Vest | SCI-19, SCI-20 | Distinct designs/appearance/armor; ordinary named armor is not an exact match certificate. |

## Asset candidates: metadata verified, matches not certified

The following DMI states were found by reading existing PNG DMI metadata.
They are starting points for visual comparison, **not permissions to assign
every similarly named item to them**.

| Existing asset | Relevant states |
| --- | --- |
| [OS13 items](../icons/os13/objects/objects/weapons/items.dmi) | `report`, `emptyreport`, `report1`-`report5`, `reportframe`; `bandage1`-`bandage4` and bloody/small-bandage variants; `bandages2`, `bandages2k`, `bandages2b`, `bandages2p`, `bandages`, `bandages_low`; `datadisk0`, `datadiskp`, `datadisko`, `datadiskgen0`-`datadiskgen2`; `medbelt`, `psiport`, `cyberport`, `godport`, `meireport`. |
| [OS13 devices](../icons/os13/objects/objects/device.dmi) | `medkit`, `medkit0`, `defib`, `defib2`, `scanner`, `scanner1`. |
| [Orbital decor](../icons/os13/objects/objects/orbital_decor.dmi) | `cyberdeck`, `scanner`, `scannerb`, `scanner0`, `torpedo_control`, `torpedo_control_button`, `torpedo_control_button1`, `epodm1`, `epodm0`, `epodm1o`. |
| [Orbital decor 2](../icons/os13/objects/objects/orbital_decor2.dmi) | `chemfabo`, `chemfab0`, `chemfab1`, `chemfab2`, `injector`, `chemfabb`. |
| [OS13 computers](../icons/os13/objects/objects/computer.dmi) | `shuttlecomms`, `shuttlecommsb`, `shuttlecommsm`, `radar`, `radar0`, `radarb`, `scanner2`, `scanner2b`, `scanner20`. |
| [OS13 guns](../icons/os13/objects/objects/weapons/gun.dmi) | `syren0`, `syren1`, `syringegun`, `syringegun_empty`. |
| [Current cyberspace sheet](../icons/misc/newcyber.dmi) | `black_ice`, `ice`, `red_ice`; an [imported OS13 sheet](../icons/os13/objects/objects/newcyber.dmi) also exists. Byte/visual equivalence is not certified here. |
| [Replicator effects](../icons/os13/replicator/effects.dmi) | `reclaimer`, used by current conversion animation. |
| [ChargeMaster](../icons/os13/objects/objects/chargemaster.dmi) | Current machine uses `cmaster` / `cmaster_process`; conversion already wired. |
| [Specified bench sheet](../icons/obj/bench.dmi) | Earlier bench work uses all 16 numbered single-direction pieces; see [bench documentation](os13_video_parity_gaps.md#sectional-station-benches). |

For every confirmed match also inspect dimensions, directions, frame count,
delay, looping, transparent padding, pixel offsets, broken/off/open/used
states, overlay composition and held/worn sheets. A static object icon is not
proof of exact hand, clothing, posture or movement parity.

## Effects and presentation

| Effect/surface | Evidence | What must match / remains unresolved |
| --- | --- | --- |
| Blue/white medical world filter | MED-20 | Terrain tint, target markers, telemetry list, input toggle, duration and range; not measured from one sample. |
| Body-search classification | MED-03, MED-20 | Blue alive authorized crew versus three red classes, PLS/RAD/room text, missing identity/bracelet. |
| Regional deep-analysis warnings | MED-14 | HEALTHY coexistence with bleeding/brain warning, numbering, region selection and precision. |
| Charged treatment mode feedback | MED-27 | Mode names/counts, clothes refusal, successful/failed/empty state and item dropping. |
| Trigger recording | MED-12; GEN-11 | Prompt -> spoken word -> saved signal -> eligible procedure; duplicates/failure, not just matching text. |
| Injection attempt/completion | MED-08, MED-24 | Separate action states, used injector/drop, exact timing and successful commit. |
| Stimulant self-card changes | MED-24 | Stat/card changes, duration and interactions; causal dose/stacking unmeasured. |
| Bullet penetration / rib crush | MED-25 | Region, through-shot, blood/decal, fracture state and post-hit behavior. |
| Dizziness blur/tint | MED-26 | Viewport-only/full-client scope, onset/offset, camera/lighting interaction; timing unmeasured. |
| Crawl, fall, stretcher posture | MED-26; EXP-06 | Body rotation, seat/bed overlays, movement and handling. |
| FESTERING / FRACTURE / BLEEDING self-card | MED-25, EXP-08 | Independent per-part states; not one whole-body injury flag. |
| Space Doze saliva/examine hint | CAP-11, GEN-06 | Conditional diagnosis prose/visual state; disease cause/progression unresolved. |
| White/grey viewport distortion | FLT-10 | HUD/chat remain available; exact symptom/cause and grey silhouette dynamics unresolved. |
| Cyber blue grid / dark blocks / red nodes / static patches | SCI-18 | Art, visibility, movement, software scan and hazard behavior; cannot infer type from color alone. |
| Firewall / DATA LEFT / all-data feedback | SCI-09, SCI-18 | Collection count and activation/finish state; DATA LEFT is not assumed seconds. |
| Spore termination / section lock notice | SCI-17 | Failure cause, affected archive, displayed 24 hours and actual enforcement; onset/lifetime not measured. |
| Named retrieval / hidden-data notices | SCI-05, SCI-09, SCI-16 | Authored technology identity and real persisted payload/unlocks, not arbitrary success text. |
| Blue/white replicator pulse | SCI-15 | Existing seven-frame effect and light; source duration/plane/radius/radiation values unverified. |
| Storage lock/material failure feedback | SCI-04, SCI-15 | Per-compartment availability and actual queue/resource behavior. |
| Genemod risk / interpretation hints | GEN-07, GEN-08 | Skill-dependent uncertainty, sequence marker and risk; complete mapping unresolved. |
| Launch ETA / travel / arrival | FLT-03, FLT-11, FLT-12 | Real transport and route-specific ETA; travel overlays/timing not fully reviewed. |
| Extreme heat / damaged air equipment | EXP-01, EXP-03 | Independent thermal, air, item wear, HUD and refusal states. |
| Laser head hit / stun / alien crawl | EXP-06 | Region and species mitigation, red/pink effect, incapacitation and recovery. |
| Tail shove/stab / dodge / empty click | EXP-07 | Different combat results and depleted resources; exact animation/sound/timing unresolved. |
| Spectral grey vignette / ghost | EXP-09 | Observed afterlife viewport and interface rather than ordinary full-color observer. |
| Angst / sacraments / memories / Shroud | EXP-09 | Real progression/resource changes, action costs and targeting; labels alone insufficient. |
| Experience reflection / memory menu | EXP-02; GEN-07 | Source-specific character progression/friend/memory surface; arbitrary roleplay notes not equivalent. |
| Console locking / off/broken state | MED-10; SCI-06; FLT-03 | Physical state and authority, distinct icons, failure and relocking behavior. |
| Game sound and spatial audio | Entire corpus | **Not semantically reviewed.** Exact gun, machine, UI, alarm, voice and ambient cues remain open. |
| Recording artifacts | SCI-09; initial GEN/SCI/MED | Windows language selector, recording software and external notifications are not game mechanics. Some viewport cards/scene changes need continuity verification before classification. |

## Acceptance record needed for each asset/effect

Record source ID/time window, input, actor state, target, prior machine/item
state, resulting state and failure/interruption branch. For visuals record
sprite file/state/direction/frame, held/worn overlays, offsets, layer/plane,
light, viewport/camera change and measured onset/end. For sounds record local
cue identity, start/duration, volume/falloff and whether it belongs to gameplay.

Compare the original and actual project at equivalent state, orientation,
zoom and lighting. A similarity thumbnail, correctly named DMI state or
matching chat line is not adequate evidence of perfect parity.
