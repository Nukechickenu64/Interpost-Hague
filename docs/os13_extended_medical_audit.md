# Extended OS13 audit: medicine and psychocorrection

Part of the [extended video audit](os13_extended_video_audit.md). Source **MED**
is the Medical Officer recording. Times are positions in that file, not round
time. **V** means a full-resolution sample was visually inspected; **O** means
an OCR lead requiring further visual/action verification. A chat line can
remain visible after its action occurred.

This is a gameplay specification, not real-world medical guidance. Numeric
examples below describe displayed game values, not physiological standards.

The [medicine-product continuation](os13_medicine_parity.md) supersedes the
earlier unavailable-product status for Hyperstim, Mnemosine, Oxivior,
Monogreline and Polythesine. It adds distinct formulations and physical
injectors with functional effects, guarded injection and Chemfab supply.
Original effect strengths, doses, risks and duration remain unverified.

## Implemented Chemfabricator and reagent supply loop

The archived **Medical Officer** article identifies a Chemfabricator supplied
with a chemical charge and water. **How to Save Lives** identifies particular
medicines and qualitative effects, but supplies no dosing, metabolism rates
or overdose thresholds. The focused Chemfab recording inspection below now
establishes named menu entries and their displayed charge costs, not their
full pharmacology.

[Chemfabricator implementation](../code/modules/reagents/dispenser/dispenser2.dm)
now provides a separate `/obj/machinery/chemical_dispenser/os13`:

- Both existing chemistry-room dispenser placements in
  [OS13 Classic](../maps/os13classic/os13classic.dmm), at `(116,113,2)` and
  `(120,113,2)`, now use this machine.
  An empty, unanchored replacement is available through the separate
  [Chemfabricator supply order](../code/modules/reagents/dispenser/supply.dm).
  Other maps' existing dispensers, their supply order and cartridge refills
  are not converted.
- It uses supplied OS13 `chemfab0` (unpowered), `chemfab1` (powered) and
  `chemfabb` (broken) states from `orbital_decor2.dmi`, rather than the generic
  dispenser/beaker overlay. The `chemfabo` screen is emissive only while
  powered and intact. `chemfab2` NORTH supplies the upper tower at `(0,+32)`
  pixels; EAST supplies the upper-right pipework at `(+32,+32)`, as clarified
  by the supplied directional sprite reference; SOUTH supplies the tank at
  `(+32,0)`. This completes the silhouette visible in **MED 00:54:20**.
  Both upper pieces render above occupants. These are visual overhangs,
  not additional collision tiles.
- A **Chemistry Charge**, already produced by the ChargeMaster, supplies
  chemical feedstock only. Other charges and reagent cartridges are rejected.
  Each charge adds five points; existing stock is preserved. A refill that
  cannot fit in full is refused without consuming the item. Charges may be
  serviced while controls are locked, matching **MED 00:53:10**.
- The machine is named **Chemfab** and starts keycard-locked. A held medical
  or chemistry ID (including one in a PDA) toggles the lock. Locked, distant,
  incapacitated and unpowered control requests cannot fabricate, load water,
  change amounts or eject the vessel. Locking refreshes already open UIs.
  The observed lock is source-backed; the access-bit mapping and swipe
  interaction use local infrastructure.
- Water is loaded separately: fill an open beaker at an existing water source,
  insert it, then select **Load Water**. Transfer is limited by the actual
  water quantity and remaining reservoir capacity. Mixed or non-water contents
  are rejected without consumption; no automatic purification occurs.
  Existing sinks still require water-chip service. Stored water remains usable
  after a service outage; there is no invented direct pipe connection.
- The UI displays water and charge separately. Fabrication consumes both,
  requires power and an open, physically inserted output vessel, and refuses
  batches that exceed either supply or available vessel space. It does not
  silently deliver a partial medication dose. Existing reagent reactions and
  metabolism still apply to the actual product.
- The recorded drug-selection catalogue is presented separately from
  **Compatibility beaker dispensing**. Dylovene and Hyperzine each produce a
  sealed injector for two charge points. A loaded beaker is not required for
  injector output once water is stored. Products use real existing reagents,
  OS13 `chemical.dmi` full/spent injector art and OS13 held-item art; no
  duplicate inaprovaline dose is inherited. The injector checks held ownership,
  adjacency, user capability, an accessible organic injection site and full-dose
  recipient capacity before invoking existing injection/logging mechanics.
  The [medicine continuation](os13_medicine_parity.md) adds five more distinct
  products: Hyperstim, Mnemosine, Oxivior, Monogreline and Polythesine.
  Unsupported source formulations are displayed as unavailable and server-side
  requests for them are refused without consuming supplies.
- Dylovene and Oxycodone use their existing reagent types. Existing ethanol
  remains available, and existing Spaceacillin supplies a local antibiotic
  option, not a newly inferred OS13 drug. The original dispenser's standard
  raw-reagent catalogue is retained for compatibility with local chemistry;
  that catalogue is not claimed to be the original OS13 recipe list.
- Shared insertion now respects failed inventory unequips. Delayed cartridge
  removal revalidates the operator, tool and selected cartridge identity.
  A vessel or cartridge leaving the machine clears its UI reference.

**Local balance and interaction choices:** initially empty reservoirs,
500-unit water capacity and maximum charge storage, additive top-up,
five-unit single-dose injectors requiring five water units, compatibility
beaker output consuming one water and one charge point per reagent unit,
whole-batch output, clean-water-only admission, manual beaker loading,
adjacent NanoUI controls, existing medicine effects and the replacement
supply order. The compatibility amount defaults to five units.
These are explicit integration choices, not recovered source constants.
The five-point refill is grounded in the displayed post-load charge count
and subsequent cost-three output, not proof of every source refill variant.
Generic dispensers retain their existing catalogue, controls and
partial-transfer behavior.

### Focused Chemfab recording reconciliation

Full-resolution **MED 00:53:10** shows "You load the charge into the machine",
the keycard-locked refusal and the public Chemfab unlock message.
**MED 00:53:30** shows **Charge: 5** and the bottom of the drug catalogue.
**MED 00:54:20** shows **Charge: 2**, the upper catalogue and the chat report
that a Hyperstim injector was put into a medical belt. **MED 00:54:30** shows
the middle catalogue. The visible cost-three Hyperstim and 5-to-2 count
support discrete product costs, rather than one point per arbitrary
milliliter as the earlier local-only dispenser implementation assumed.
They do not establish injector dose, water consumption, synthesis duration,
maximum charge storage or the exact original selection-dialog implementation.

| Visible menu cost | Recorded drug names | Implemented output |
| --- | --- | --- |
| 1 | Technetium, Theosin | Unavailable: no exact implemented formulation. |
| 2 | Alzhesine, Cordrazine, Dentrine, Dylovene, Gelabine, Hyperzine, Jetamet, LAD-5, Mnemosine, Oxivior | Dylovene/Hyperzine use existing reagents; Mnemosine/Oxivior now have distinct functional reconstructions. Other entries unavailable. |
| 3 | Drenex, Hyperstim, Immirit, Monogreline, Polythesine | Hyperstim/Monogreline/Polythesine now have distinct functional reconstructions. Drenex and Immirit unavailable. |

These are 17 inspected entries, not a claim that every OS13 release has
exactly this catalogue. Hyperstim is not substituted with Hyperzine,
Cordrazine with Tricordrazine, or Technetium with Dylovene. The Hyperstim
synthesis/injection loop is now functional, with explicitly local balance
values and source risk/duration gaps described in the linked continuation.
The remaining unsupported entries are unavailable. Existing generic medicine
metabolism was not changed.

### Named medicine reconciliation

This table separates available names from unsupported effects. Similar names
or an available sprite do not justify substituting a generic medicine.

| Source medicine | Source role | Current boundary |
| --- | --- | --- |
| Dylovene | Poison treatment. | Existing Dylovene is fabricatable; its present metabolism is retained, not source-certified. |
| Oxycodone | One of several pain medicines. | Existing Oxycodone is fabricatable; the wiki's full opiate side-effect contract is not reproduced by this batch. |
| Technetium | Treatment for psychedelic poisoning. | No exact drug implementation or recipe; no silent substitution with Dylovene. |
| Morphite | Bleeding control with weakness/drowsiness. | Not replaced with generic hemostatic treatment or a renamed opiate. |
| Selenium | Seizure/contraction suppression with weakness/drowsiness. | No exact reagent, dose or effect coefficients established. |
| Dentrine; Morphine; Heroin; Metadone | Pain treatment with differing side effects. | Exact medicines and opiate respiratory/cardiac risks are not established by existing Oxycodone. |
| Molybdenum | Panic treatment with sedation and mild toxicity. | No exact reagent or thresholds established. |
| Lutetium | Treatment for loss of interest. | No exact mental-state interaction established. |
| Barium | Opiate-overdose treatment with sleep/coordination side effects. | No exact antagonist implementation or dose established. |
| Hassium | Stomach-parasite treatment with vomiting/toxicity. | Parasite targeting, cure and adverse-effect rules remain unresolved. |
| Mentats | Brain-injury treatment with overdose harm and an exception for its own damage. | No exact repair/provenance/overdose contract established. |
| Krovnik | Recovery support alongside clean water when transfusion is unavailable. | No preparation recipe or recovery coefficients; not an alias for nanoblood. |
| Kalocin | Imported disease treatment; raw use can create dependence. | The wiki explicitly excludes synthesis from available chemicals. It is not added to the Chemfabricator; import, processing and dependence remain unimplemented. |
| Theosin; Hyperstim and the other video help-panel medicines | Recorded products/categories, summarized below. | Hyperstim, Mnemosine, Oxivior, Monogreline and Polythesine now have distinct functional formulations/products; exact pharmacology remains unverified. Theosin and other unsupported drugs remain unavailable. See [medicine continuation](os13_medicine_parity.md). |

The wiki also distinguishes radiation injury from removable poison and says
Cave Plague is not antibiotic-treatable. This batch does not add a universal
radiation-removal or disease-cure product and does not change global radiation,
infection or wound rules.
Availability of existing ethanol also does not implement the wiki's targeted
early-wound infection treatment; that interaction remains unresolved.

### Validation and manual acceptance

This continuation uses focused static inspection and scoped whitespace checks.
The updated UI template compiles with the repository's existing NanoUI doT
parser. Sprite states/directions, both held-item sprites, include paths, map
references, actual reagent definitions and UI bindings were inspected
separately from runtime behavior. The composed machine silhouette was also
compared with the inspected recording. No BYOND compiler, Dream Maker,
unit tests, automated gameplay harness or live client was run; compilation
results in older sections do not validate this continuation.

Manual in-game acceptance remains necessary:

1. On OS13 Classic, examine both chemistry-room Chemfabricators. Order a
   replacement and confirm all start keycard-locked without water or feedstock.
   Swipe authorized and unauthorized IDs/PDAs; verify public lock messages.
   Open the UI, lock it again, and confirm stale control requests are refused.
2. Produce a Chemistry Charge at the ChargeMaster. Reject a wrong-family
   charge, add five points per valid charge (including while locked), retain
   existing stock, and reject a refill within four points of maximum storage
   without consuming it. An unreleasable held charge must remain held.
3. Fill a beaker using water-chip-dependent water service. Load water, eject
   the beaker, and verify exact quantities at the reservoir limit. Mixtures,
   empty/closed vessels and a full reservoir must not consume contents.
4. With enough supplies, fabricate 5 units into an empty vessel. Water and
   charge must each fall by 5 and the actual reagent volume must rise by 5.
   Reload supplies and fabricate each supported injector without a beaker:
   charge must fall by 2, water by 5, and exactly one five-unit injector
   must appear in an available hand or beside the machine.
   Unsupported catalogue entries must not create output or spend supplies.
   Confirm loaded/spent art, blocked injection through thick clothing,
   missing/robotic-site refusals, empty-injector refusal and existing logs.
   For a 10-unit compatibility batch, water and
   feedstock must each fall by 10 and the actual reagent volume must rise by
   10. Verify real existing drug metabolism rather than a renamed placeholder.
5. Try a batch with insufficient water, insufficient feedstock, insufficient
   output space, a closed/missing vessel, or lost power. Every refusal must
   leave both supplies and the vessel unchanged.
6. Interrupt water service after filling the reservoir. Stored water should
   still work; replenishing from an affected sink should not.
7. Remove/destroy the loaded vessel and repeat UI actions. Check ordinary
   cartridge dispensers as well: refused unequips cannot insert items, stale
   screwdriver selections cannot remove a replacement cartridge, and their
   usual partial transfers/refill behavior remains available.
8. Inspect the complete tower/tank silhouette, including occupants behind the
   upper tower and beside the tank. Toggle power and break the machine:
   only the powered intact screen should glow in darkness. Inserting a beaker
   must no longer switch the entire machine between powered/unpowered art.

## PsiBoost communications and counselor continuation

The archived **Psionic-Counselor** page explicitly gates remote vision and
thought transmission behind an implanted Psi-Boost, after its research is
unlocked. [Counseling equipment](../code/modules/os13/os13_wiki_counseling.dm)
now adds a distinct surgical **PsiBoost Implant** using supplied OS13
`neuroimplant` art. Its [Replicator design](../code/modules/research/research.dm)
is gated by the named PsiBoost Implant technology, not granted by carrying a
research disk or an unimplanted organ.

**Implemented:** a usable installed implant grants **Remote Vision** and
**Thought Transmission** to an organic, conscious operator with a brain.
These controls do not require the Counselor role. Targets are connected,
conscious organic humans on the same deck. Both controls revalidate the
implant, operator client, target and location after input dialogs.

- Remote Vision observes the selected target's location without moving the
  operator's body or transferring either mind. It does not grant X-ray vision,
  possession or the target's skills. Normal human vision handling recognizes
  this view only while its implant session is valid.
- Reusing the control returns sight to the body. Expiry, unconsciousness,
  death, blindness, target disconnection/deletion/deck changes, implant
  removal/failure/destruction and switching to another viewing interface end
  the session. Cleanup restores only its own client/eye, not another machine's
  or a transferred player's camera.
- Thought Transmission sanitizes a bounded message, delivers it privately
  to the selected recipient and records a normal speech log. It does not
  broadcast to nearby crew, spoof spoken chat or read unsent player input.
- Basic training now revalidates a visible, adjacent, conscious organic
  partner with a brain. Emotion reading and combat-mode psychometry require
  actual local visibility, rather than a distance check that could admit a
  person on another deck.
- Clone volunteering now requires the existing shock offer and an ejected
  body on OS13; see the [genetics continuation](os13_extended_science_audit.md#genetics-media-and-clone-recruitment-continuation).

**Local choices:** 30-second viewing sessions, two-second transmission
throttle, same-deck connected-human targeting, body vision restrictions,
sender identification, a separate internal-organ slot and a recipe of
1,000 wall-material units plus 500 glass. Target range, presentation,
duration, resistance and any cost of these two communication functions are
not established by the source. No Intelligence/Willpower cost was invented
for them.

**This is a partial PsiBoost product, not complete PsiBoost parity.** The
random three-power base set, advanced implant and permanent Intelligence /
Willpower expenditure are not implemented by these communications controls.
No advanced product that merely duplicates the base communications implant
was fabricated. The wiki says "all nine" but lists ten distinct powers;
that discrepancy is not resolved by silently dropping one.

The following are source-defined cost/effect leads, not implemented powers:

| Power | Listed INT cost | Evidence boundary |
| --- | --- | --- |
| Psi-Armor | 2 | Broad damage protection; exact armor coverage, duration and stacking unknown. |
| Pain Radiation | 2 | Visible-area agony with mood-dependent duration; magnitude and resistance unknown. |
| Fear Radiation | 1 | Visible-area panic; forced movement, duration and recovery unknown. |
| Telepathic Control | 5 | Temporary victim control; identity, displacement, interruption and return rules unresolved. |
| Psychogenic Agility | 1 | Permanent agility enhancement; exact gain/cap and expenditure interaction unknown. |
| Psychogenic Strength | 1 | Permanent strength enhancement; exact gain/cap and expenditure interaction unknown. |
| Hypnogenesis | 1 | Slow movement and prevent crawling/jumping; duration and resistance unknown. |
| Meta-Barrier | 1 | Wall passage compares psionic talent; shape, placement, lifetime and talent scale unknown. |
| Cryptokinetic Attack | 2 | Target freezing; exact temperature, damage and thawing unknown. |
| Pyrokinetic Attack | 5 | Immediate ignition; fire intensity, duration and protection interaction unknown. |

Psionic skill scaling, fallback Willpower accounting and permanent brain-cost
semantics require their own reconstruction. These powers are not substituted
with similarly named generic faculties.

### Validation and manual acceptance

This continuation received focused static and whitespace inspection only.
No compiler, Dream Maker, unit tests or live-client verification was run.

Manual checks:

1. Before installing PsiBoost research, its design must remain unavailable.
   Install the named technology, fabricate the organ, then implant it using
   ordinary surgery. A loose implant or research alone must grant no controls.
2. Use both communications controls as Counselor and non-Counselor. Reject
   dead/synthetic/disconnected/off-deck targets. Remove or disable the implant,
   move decks or switch clients while an input dialog is open: no operation
   should commit using the stale link.
3. Observe a remote person, then wait for expiry, become unconscious/blind,
   remove the implant, disconnect either player and switch camera interfaces.
   Verify body location/mind ownership never changes and no unrelated view is
   reset. No remote-view effect should survive a destroyed implant.
4. Send punctuation/HTML-like text and a long message. It must remain bounded,
   display as text to the two participants, produce a speech log and not
   appear as a locally spoken sentence.
5. Train an awakened clone and compare taught versus untaught skills.
   Attempt training through walls, across decks, while unconscious, and while
   the partner moves away during selection. Invalid links transfer nothing.

## Implemented medical batch

[Medical implementation](../code/modules/os13/os13_medical.dm) now adds:

- A surgically implantable **Medvisor**, with Medical Diagnosis and Body Search
  controls. [OS13 Medical Officers](../maps/alpha/job/os13_jobs.dm) initialize
  with it; replacement clones do not automatically inherit the implant.
- Compact diagnosis and selected-region numbered findings from real organs,
  blood and pulse. HEALTHY is an organic vital-status label, not a guarantee
  of no injuries. Functioning synthetics report no organic vitals/DEAD without
  changing their actual life or AI state. Brain warnings use the existing
  brain-damage threshold, not a newly inferred source coefficient.
- Client-local blue/red body overlays for visible humans. Blue requires a
  living, non-fake-dead body, a worn medical bracelet and an ID bearing station
  department access; dead, unauthorized or braceletless bodies are red.
  The telemetry window uses the existing crew repository and its sensor/jamming
  rules: location requires tracking mode; pulse/RAD require vital mode.
  Missing/disabled remote transmissions are not fabricated.
- A **Medi-Kit** with independent Artery sewer, Antibiotic, Painkillers and
  Hemostatic charges. Self-use cycles modes. HELP-use on an uncovered selected
  region starts interruptible treatment; concurrent regional surgery is
  rejected. Clothing, limb identity, holding, adjacency and stock are checked
  again before commitment. Cancelled/invalid treatment consumes no charge.
  Artery sewer repairs the selected ruptured artery; Hemostatic clamps
  bleeding wounds, without healing fractures or repairing an artery.
  Antibiotic/Painkillers administer existing spaceacillin/tramadol and log
  the injection through the standard administration logger.
- A **surgical laser** using OS13 surgery and hand sprites. It is a cautery
  subtype accepted by existing incision closure and
  [individual wound suturing](../code/modules/surgery/suture_wound.dm).
  Existing surgery durations, skill checks, failure, pain and healing rules
  remain unchanged; a laser scalpel is not silently repurposed.
- Replicator designs for the Medvisor, Medi-Kit and surgical laser. No new
  machine/map coordinates or invented medication names were added.

**Local choices, not verified original rules:** three initial charges per mode
(the recorded Painkillers 2 is a mid-round observation), three-second Medi-Kit
treatment, ten-unit doses, existing drug effects, department-ID authorization,
adjacent diagnosis, one-second visible-overlay refresh with the repository's
five-second telemetry cache, verb bindings, semi-transparent overlays and
fabrication requirements/costs. `neuroimplant`, `medkit`/`medkit0`,
`medicalpack` and `laser2`/`laser` states exist in the supplied OS13 assets;
their exact appearance/animation equivalence remains unverified.
Medical Officer implant provisioning is also a local integration choice; the
recordings do not establish the original initialization code.

No blue/white terrain filter was invented. No unsupported refill chemistry,
psychocorrection outcomes, Demon possession, lethal implant conflict, new
disease formula or pharmaceutical stat bonus was implemented. Those contracts
remain open below. The inventory and code comparisons in the original audit
describe the pre-batch state where explicitly superseded here.

### Validation and manual comparisons

Normal command-line project compilation from Interpost-Hague passed with
**0 errors, 0 warnings**. Static inspection checks sprite states, charge
commitment, target revalidation, browser closure, client-image cleanup and
implant removal/destruction/death handling. No unit tests or Dream Maker IDE.

Manual Dream Seeker verification is still required:

1. Initialize a Medical Officer; diagnose self and an adjacent injured patient
   at each region. Verify HEALTHY plus bleeding/brain findings, missing limbs,
   blood precision and synthetic DEAD without disabling the synthetic.
2. Compare living authorized crew with unauthorized/braceletless/dead people.
   Toggle bracelet modes and test jamming, closed rooms, scanner/container
   occupancy and a different deck. Hidden people must not acquire remote
   markers; withheld fields must not become live readings.
3. Close/toggle search, disconnect/reconnect, become incapacitated, remove,
   break, destroy or transplant the implant. No stale client overlays or
   reopened closed window should remain.
4. Cycle all four Medi-Kit modes, exhaust each independently, interrupt/drop
   the tool, dress the patient during treatment, remove the limb and attempt
   simultaneous surgery. Only committed treatments consume a charge.
5. Verify artery repair does not repair a fracture, clotting leaves artery
   bleeding separate, and medicines enter the existing reagent/metabolism
   system with normal logs rather than immediately curing every wound.
6. Fabricate all three designs; implant the spare visor by ordinary surgery.
   Use the surgical laser for wound and incision closure; compare ordinary
   suture/cable behavior to confirm it is unchanged.

## Implemented medical supplies batch

[Medical implementation](../code/modules/os13/os13_medical.dm) also adds:

- **Remove Dressing**, granted/revoked with the Medvisor controls. Select an
  adjacent patient and body region; an interruptible action removes only that
  region's existing wound dressings. Clothing and concurrent regional surgery
  block removal. The limb, implant, patient and exposure are rechecked before
  commitment. Real wound bandaging, body overlays and bleeding are updated;
  this does not erase wounds, clamps, ointment, fractures or arterial damage.
  The original control binding and requirement for a Medvisor are unverified.
- **Surgical scalpel** and **Bone-gel** using supplied OS13 item art and existing
  scalpel/bone-gel surgery ancestry. No global reskin or replacement surgery
  formula is involved. The scalpel uses OS13 held art; bone gel uses the
  available `c_tube` hand state as a local mapping, not a certified source pose.
- A sealed **Blood Substitute Injector** with five available doses and an
  examination line showing `Cartridge life: 5 uses.` Successful injections
  consume one dose through the ordinary autoinjector/reagent/admin-log path.
  Attempts are interruptible and recheck the held tool, selected limb, patient,
  exposure and reagent capacity. Cancellation does not consume a dose. Spent
  art is separate; no cartridge-refill mechanism was invented.
- Replicator designs for these three products and both existing named bandage
  variants. Recipes/technology levels are local availability choices.

[Bandaging](../code/game/objects/items/stacks/medical.dm) now consumes one
length immediately for each committed wound application, rather than reserving
an unspent stack during successive waits. Post-wait checks reject a vanished
limb, moved/dropped tool, intervening space-suit coverage or an already treated
wound. Skill healing bonuses are calculated per application, not permanently
accumulated in the stack's `heal_brute`. Existing splint handling is preserved.
[Bacteriophage bandages](../code/modules/os13/os13_video_objects.dm) reduce
surface germs by 100 only at the successful wound-application hook. They no
longer infer success from an ambiguous parent attack return. This retains the
existing local surface effect; it does not claim a source wound-infection cure.

### Newly checked source evidence and local choices

Full-resolution **MED 00:11:00** visibly names the Blood Substitute Injector
and reports **five uses**. **MED 00:41:50** shows attempted/completed chest
unbandaging and old-dressing rejection. **MED 00:26:50** includes bone-gel
application messages, not proof of a specific healing coefficient.
These strengthen MED-07/16/19; scrollback still does not prove exact timing.

Five injector uses are observed, but five-unit dose size, existing nanoblood
pharmacology, three-second injection/removal, default five-dose spawn capacity,
the Medvisor removal binding and fabrication costs are local integration
choices. Nanoblood already restores blood through existing metabolism and has
toxicity/immunity effects; repeated dosing is not guaranteed safe.
`scalpel`, `bonegel`, `nanoblood`, `dnanoblood`, `dnainjector` and `c_tube`
exist in the referenced OS13 assets. Ready/spent injector state mapping and
precise visual parity still need in-game comparison. Theosin, hyperstim,
automated nurse treatment and psychocorrection remain open. Artificial Liver
is addressed by the following batch; its original performance remains unverified.

### Supplies validation and manual comparisons

Normal compilation command, run from Interpost-Hague:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' 'C:\Users\nukec\Documents\GitHub\Interpost-Hague\Interpost-Hague.dme'
```

Result: **0 errors, 0 warnings**. Sprite metadata and action/consumption paths
were inspected. No unit tests, isolated harnesses or Dream Maker IDE were used.
No live Dream Seeker verification has been performed.

Manual checks:

1. Fabricate the five new supply designs. Check both hands, inventory icons
   and incision/bone-repair tool acceptance against the recordings.
2. Examine a fresh injector, then administer five completed doses; remaining
   uses must be 4, 3, 2, 1, 0 and spent art must appear only after the fifth.
   Interrupt, drop it, change region, replace the limb or cover the injection
   site during a sixth separate fresh-injector attempt: no invalid dose or log.
   Confirm real blood regeneration, toxicity and ordinary administration logs.
3. Bandage multiple wounds with both variants; count one length per committed
   wound. Interrupt midway or have a second medic bandage the same wound.
   Surface germs must not decrease on an untreated/already-bandaged patient.
   Repeated applications must not permanently increase the stack's healing.
4. Remove dressings from a selected chest while the head remains bandaged.
   Confirm wound damage is unchanged and existing bleeding can resume.
   Interrupt, clothe the region, remove the limb/Medvisor and attempt concurrent
   regional surgery. Previously applied dressings must remain on failed removal.
   Clamped/salved wound overlays can legitimately remain after unbandaging.

## Implemented Artificial Liver batch

[Artificial Liver](../code/modules/os13/os13_medical.dm) is now a distinct
fabricatable cybernetic organ, not an inert prop or a global liver reskin.
The full-resolution **MED 00:09:50** examination visibly names **Artificial
Liver** and describes it as a cybernetic replacement of an ordinary organ.
This confirms identity and intended organ role, not numerical performance.

- Uses the supplied [OS13 cyber-organ sheet](../icons/os13/mob/mob/flesh/cyber_organs.dmi)
  `liver` state. OS13 `implantcase` hand art is a local held-item mapping; the
  exact recorded hand pose is not established.
- Inherits [liver mechanics](../code/modules/organs/internal/liver.dm) and calls
  the normal `robotize()` chain after organ construction, so fabricated and
  directly instantiated products have actual robotic damage/filter behavior.
  Re-robotization retains OS13 liver art rather than requesting the generic
  `liver-prosthetic` state absent from this sheet.
- Keeps `BP_LIVER`, the existing Groin parent region, organ size and ordinary
  [transplant/attachment sequence](../code/modules/surgery/organs_internal.dm).
  Existing duplicate-organ, damaged-product and cavity-capacity checks apply.
  It becomes functional only after attachment registers it in the patient's
  internal organ lookup. Removal uses existing organ lifecycle behavior.
- Reuses filtering, blood regeneration, thirst, nutrition, damage, robotic
  EMP response and species adaptation. It does not fabricate source immunity
  to alcohol, thirst, radiation or organ failure.
- Adds a replicator design. Technology thresholds, material costs, hand-state
  mapping, the inherited parent region and all inherited coefficients are
  **local integration choices**, not recovered OS13 rules. Existing natural
  livers, bioprinter output and species starting organs are unchanged.

Validation: normal Interpost-Hague command-line compilation passed with
**0 errors, 0 warnings**. Static inspection verified constructor/robotization,
sprite metadata and existing transplant/attachment lookup paths. No unit
tests or Dream Maker IDE were used. Live Dream Seeker verification remains
unperformed; no exact source lifetime or failure contract is claimed.

Manual checks:

1. Fabricate the design; inspect its OS13 item/hand art. It must already be
   robotic without an admin conversion. Compare the recorded examination.
2. Open the existing liver region, remove the old liver, insert the Artificial
   Liver and attach it using ordinary surgery. Duplicate, damaged and
   undersized-cavity attempts must still follow standard surgery rejection.
3. Confirm the attached organ is the patient's liver and resumes the existing
   blood/filter/thirst mechanics. An inserted but unattached organ must not
   silently replace the active liver.
4. Remove/reinstall it, apply robotic damage/EMP and rejuvenate/re-robotize.
   OS13 art should remain valid; ordinary natural livers and other prosthetic
   organs must retain their existing behavior and sprites.

The subsequent [Artificial Eyeball product integration](os13_extended_science_audit.md#artificial-eyeball-product-integration)
adds a robotic eye-slot replacement with OS13 item art and ordinary organ
surgery. It inherits the current combined-eye model, damage/blur/blindness
and eye-colour behavior; original single-eye surgery and sight bonuses remain
unverified.

## Evidence ledger

| ID | Source / visible time | Evidence | What this establishes / does not establish |
| --- | --- | --- | --- |
| MED-01 | MED 00:00:10, O | SyrV-40M examination and damaged-weapon warning. | Named medical weapon; not its dose, ammunition, damage or repair procedure. |
| MED-02 | MED 00:00:10, O | Implanted visor caress conceals the eyes. | Cosmetic implant interaction. Do not assume it is the diagnostic implant merely because both are visors. |
| MED-03 | MED 00:01:20; 00:03:00, V | Body-search help: blue denotes alive crew; red denotes corpses, unauthorized people and crew without medical bracelets. | Three red categories, not a simple alive/dead filter. |
| MED-04 | MED 00:02:20, O; 00:24:00, V | Diagnosis has overall status, blood type, blood percentage/volume and pulse. | Compact output differs from current analyzer formatting. |
| MED-05 | MED 00:05:40, O | Visor and Shears Saniturgy labels. | Item names; the latter's exact functionality remains unidentified. |
| MED-06 | MED 00:09:50, V; 00:10:00, O | Artificial Liver visibly described as a cybernetic replacement of an ordinary organ; Schriebmann's Port lead. | Physical organ/implant objects. No transplant outcome or numerical filtering/failure rule is proven by these examinations. |
| MED-07 | MED 00:11:00, V; 00:11:20, O | Blood Substitute Injector examination: Cartridge life: 5 uses; theosin injector lead. | Physical five-use blood injector, not just a generic beaker and syringe; dose/pharmacology unmeasured. |
| MED-08 | MED 00:13:20, O | Attempt followed by successful injection of another character. | Separate attempted/completed actions. Exact duration and interruption conditions are unresolved. |
| MED-09 | MED 00:13:50; 00:14:40, O | Bacteriophages Containing Bandages; Hemostatic Bandages. | Existing locally named supplies must be compared behaviorally, not counted as absent. |
| MED-10 | MED 00:15:50; 00:16:00, V | Subject seated in Correctional Apparatus; Psychocorrectional Console initially locked, then unlocked. | A physical seated-target machine/console pair and access state. |
| MED-11 | MED 00:16:00, V | Four actions: Uncover Psi-potential, Suppress Psi-potential, Optimize cognitive abilities, Optimize signal processing. | Exact observed action surface; does not prove the numerical changes for every action. |
| MED-12 | MED 00:18:40, V | Recording begins, a trigger word is spoken, mnemonic audiosignal records successfully; later success and existing-subpersonality rejection. | A recording/state prerequisite and duplicate rejection, not merely counselor roleplay. |
| MED-13 | MED 00:18:40, V | An attempted operation says a trigger word must be implanted first so the subject can give control to its Demon. | Trigger-before-installation ordering. The full selection menu and control-transfer outcome were not observed here. |
| MED-14 | MED 00:24:00, V | Head deep analysis lists numbered bleeding and significant brain damage while overall status remains HEALTHY. | Overall HEALTHY must not suppress detailed injury findings. |
| MED-15 | MED 00:24:10, O | Head sutured with surgical laser; nearby blood-volume reports change. | Tool/action label. Do not derive healing rate from adjacent changing blood readings. |
| MED-16 | MED 00:26:20-00:27:40, O; 00:26:20, 00:26:50, 00:27:30, V | Head incision/skull drilling and brain-implant removal, later implantation, bone-gel application and laser suturing; selected full-resolution chat samples checked. | Alpha neural-port route and OS13 tool kit now implemented; original implant identity and exact timings still need dense review. |
| MED-17 | MED 00:28:10; 00:30:40, O | Head grab and chest laser suture on another patient. | Region-specific treatment and handling, not a single whole-body heal. |
| MED-18 | MED 00:34:20, V | Logi Officer Coat GENECODE is a separate examined object beside Genetics Chamber and Genemod Console. | A genotype media item associated with a person. **Coat is the character surname**, not proof of garment fabrication. A named OS13-art GENECODE Diskette now reuses DNA-record storage, but the original payload, Genemod integration and provisioning remain unverified. |
| MED-19 | MED 00:40:30-00:41:50, O; 00:41:30, 00:41:50, V | Diagnosis, head/other-region bandaging; chest unbandaging and old-dressing rejection visually checked. | Reversible region-specific bandage state, separate attempted/completed removal. Exact control binding unverified. |
| MED-20 | MED 00:46:00, V | Blue/white world filter; body-search list includes crew names, deck/room, PLS and a RAD flag. | Medical-search presentation and telemetry. Exact toggle, range, update interval and through-wall behavior remain unmeasured. |
| MED-21 | MED 00:46:00, V | Lance speaks while diagnosis reports DEAD; attempted pushing is rejected as uncontrolled. | Organic diagnosis semantics can misclassify a functioning synthetic. Do not use a HEALTHY/DEAD string as authoritative AI state. |
| MED-22 | MED 00:58:00, V | Radio use rejected because radio is not held in hand. | Worn neck-slot radio is not necessarily sufficient to transmit. |
| MED-23 | MED 01:02:00, V | Weapon aiming preparations, gripping/squeezing, and demand for a chemical charge. | Combat and consumable logistics overlap treatment; exact charge servicing remains unverified. |
| MED-24 | MED 01:04:40, V | Self-injection of hyperstim precedes temporary higher displayed stats, successful grip escape and a point-blank NT5 shot. | A stimulant/action sequence. Do not attribute all stat changes or survival solely to the drug. |
| MED-25 | MED 01:04:40, V | Upper-torso bullet passes through, ribs crushed; chest card shows FESTERING, FRACTURE, BLEEDING; attacker thrown into Genetics Chamber. | Penetration, region injury, fracture, grapple throw and environmental collision coexist. No exact damage coefficients recovered. |
| MED-26 | MED 01:04:50-01:05:00, V | Dizziness with blur/tint, crawling, blood cough, helper places patient on stretcher. | Debility and assisted transport following trauma; death itself is not established by the recording title. |
| MED-27 | ALIEN 01:20:00, V | Medi-Kit cycles Artery sewer (Charge: 3), Antibiotic (3), Painkillers (2), Hemostatic (3); clothing prevents use. | A multi-mode charged treatment tool, not merely a storage box. Exact healing, refill, targeting and consumption per mode remain unresolved. |
| MED-28 | ALIEN 01:18:00, V | ChargeMaster completion, Soda Machine Charge examination. | Existing precursor conversion is relevant medical logistics infrastructure, though a soda product is not a medicine charge. |
| MED-29 | GEN 01:05:00, V | Psychocorrection failure, existing-subpersonality rejection, another trigger recording and later success lines. | Failure is a real branch. Nearby complaints about blurry eyes do not establish the failure's precise medical penalty. |

## Diagnostic and body-search contract

### Observed output shape

The inspected injured-patient example at MED 00:24:00 displays:

- Overall status HEALTHY.
- Blood type A+.
- Blood level normal, 89.6429%, 502.661 cl.
- Pulse 63.
- Deep analysis of Head, including a numbered bleeding finding.
- Significant brain damage warning.

The earlier ordinary scan reports 100%, 560 cl and pulse 69. Preserve display
units and rounding deliberately; these examples are not an exhaustive formula.
Do not silently correct recorded units or infer that 560 cl is an authentic
physiological quantity. Head trauma and bleeding are compatible with the
displayed overall status.

The search legend distinguishes membership/authorization/bracelet state from
life state. At MED 00:46:00, the search list reports rooms/decks, PLS values and
RAD. A world tint is visible at the same sample. Their causal connection,
whether terrain itself is recolored by body-search mode, and the precise input
binding are still open evidence questions.

**Current implementation:** the [OS13 Medvisor](../code/modules/os13/os13_medical.dm)
provides an implant-gated Medical Diagnosis action with the observed overall
status, blood type, blood percentage/volume, pulse and selected-region deep
analysis. Its Body Search action also provides the blue/red body overlay and a
remote bracelet telemetry list with deck/room, PLS and RAD columns. The
pre-existing [health analyzer](../code/game/objects/items/devices/scanners.dm)
and [medical bracelets](../code/game/objects/items/devices/geiger.dm) remain
separate tools.

The current body-search implementation is a partial evidence-based integration,
not proof of full parity: the telemetry list currently uses repository names
directly; the source's `???` identity masking rule is not implemented. Missing
bracelet behavior, visibility and sensor-range rules, refresh cadence, and
whether remote search can identify hidden targets also remain unresolved.

**Required parity work:**

1. Recover the source identity-masking/recognition rule and apply it to remote
   telemetry without breaking local diagnosis or sensor privacy.
2. Verify missing-bracelet behavior, visibility/range rules, refresh cadence,
   and whether remote search can identify hidden targets.
3. Keep authorization/bracelet classification separate from organic vitality
   and synthetic activity.
4. Match displayed precision only after verifying additional values.

## Psychocorrection and subpersonality contract

The [psychocorrection continuation](os13_psychocorrection_parity.md) now adds
the missing apparatus and console, actual spoken recording, guarded procedures
and persistent SLEEP/PANIC/COMBAT conditioning. A new GEN 01:05:00 inspection
shows Nash saying “Sleep.” followed by Victor falling over after leaving the
apparatus. This supports a concrete Sleep response; exact timing and the
other trigger outcomes remain reconstruction choices. The subpersonality,
psi/cognitive and personality-refragmentation contracts below remain open.

The console description refers to hypnosis, synapse nanosurgery and brain
chemistry, but this description is not proof of individual gameplay effects.
The four observed actions above need separately verified prerequisites,
duration, costs, stat effects and reversal rules.

The directly visible state sequence at MED 00:18:40 is stronger evidence:

1. Subject occupies the apparatus; operator uses the associated console.
2. Recording starts and requests a spoken trigger word.
3. A short word is spoken and the mnemonic audiosignal is recorded.
4. Installation requires the recorded/implanted trigger prerequisite.
5. A procedure succeeds.
6. Another attempt explicitly rejects an already present subpersonality.
7. Subject is unbuckled from the apparatus.

Some nearby dialogue predicts possession, extra expertise and an implant
conflict causing head damage. **Those predictions are not verified outcomes.**
Do not implement lethal implant conflicts or arbitrary specialist skills based
on dialogue alone. Likewise, a success line by itself does not establish which
of several recently attempted operations succeeded.

**Current implementation:** [OS13 counseling](../code/modules/os13/os13_wiki_counseling.dm)
has adjacent skill transfer, temporary borrowed knowledge, psychometry and
clone offers. [Psychosis counseling](../code/modules/os13/os13_video_parity.dm)
has an interruptible treatment session. Generic psionic implants exist in
[psionic equipment](../code/modules/psionics/equipment/implant.dm).
The new apparatus/console continuation is separate from these earlier
counseling foundations and adds the trigger-word recorder and actual
conditioned responses. The subpersonality state machine and control transfer
are still absent; procedure success does not certify them.

An implementation must preserve the recorded dependency order, reject missing
subject/trigger/duplicate installation explicitly, keep control transfer
distinct from ordinary skill copying, and define cleanup on unbuckling,
power failure, subject death and console destruction. Those cleanup choices
remain specification questions until footage establishes them.

## Implemented targeted surgery integration

The full-resolution **MED 00:26:20** sample shows an incision, drilling a hole
in Gan Jones's skull and removing an implant from the brain. Subsequent
samples show implantation, bone-gel use, setting the head bone and laser
suturing; **00:27:30** includes the bone-gel attempt/completion messages.
These are sampled chat/action observations, not frame-accurate operation
durations. The archived **How to Save Lives** article instead describes a
surgical saw opening the skull, and separately describes expander/GRAB organ
access, scalpel detachment, forceps extraction, insertion and needle attachment.
These sources do not prove that every brain implant uses an identical recipe.

[OS13 surgery steps](../code/modules/surgery/os13.dm) now supply a shortened
**Alpha-map, organic-head neural-port route**:

1. Select the head and make a surgical incision with a scalpel.
2. Use a surgical drill. A completed step expands the incision to the local
   skull-access threshold and opens the skull using the existing fracture
   model. Unbreakable skulls and configurations disabling fractures explicitly
   refuse this route.
3. Use forceps/hemostat to remove an installed Schriebmann Port directly, or
   apply a replacement port to install it. Both ordinary and advanced ports
   use the existing single neural-port slot. Removal uses actual organ
   detachment; insertion registers the real working organ, not a decorative
   cavity item. The cyberdeck therefore sees the installed/removed state
   through its existing connection checks.
4. Repair the skull with **bone gel, bone setter, then bone gel**. The final
   Alpha head-repair step preserves the incision instead of healing it away
   before the separate closure action.
5. Use the surgical laser to close the actual surgical incision. This takes
   precedence over ordinary partial wound suturing, refuses an unrepaired
   skull and retains cavity-wall closure before outer incision closure.
   Ordinary wound suturing remains available when no surgical incision exists.

The port must be unowned, viable and small enough for the remaining cranial
space. Installed or loose duplicate ports are refused. Inventory release must
succeed before insertion. No separate cavity-drilling or needle-attachment
step is required for this particular direct port route. Other implants,
general transplants and non-Alpha maps retain their existing procedures.
The recording does not establish that the implant pictured was specifically
a Schriebmann Port: mapping this route to the repository's existing neural
interface is an explicit integration boundary.

The [OS13 medical items](../code/modules/os13/os13_medical.dm) now include
retractor, forceps, drill, surgical saw, bone setter and surgical needle
subtypes, in addition to the existing scalpel, bone gel and laser. A distinct
nine-instrument surgery kit is available through the
[medical supply catalogue](../code/datums/supplypacks/medical.dm).
Existing tool ancestry, surgery eligibility, storage filtering and kit
sterilization are reused; no map placements or research recipes are invented.
Every instrument uses supplied OS13 world art. The saw uses the matching
OS13 left/right-hand states. The five tools without matching dedicated hand
states render their own OS13 world state in the held layer, not a nonexistent
generic state or an unrelated tool. Their exact original hand alignment remains
unverified. The kit container retains its existing local artwork.

[Shared surgery dispatch](../code/modules/surgery/surgery.dm) now reserves the
region before organ-selection dialogs and rechecks operator capability,
adjacency, tool possession, selected region, limb identity, incision identity
and selected organ location/ownership after selection and delayed work.
Interrupted work does not run its success or malpractice callback, and
releases the region lock. Initial pain, germ exposure and bloody-hand effects
remain possible when an operation begins. Selections are captured per action
so simultaneous operations on different regions cannot redirect one another
through the patient's shared current-organ field.

[Internal-organ procedures](../code/modules/surgery/organs_internal.dm)
revalidate menu choices and respect failed inventory release on transplant;
MMI extraction runs its transfer/deletion only once.
[Robotic organ selection](../code/modules/surgery/robotics.dm) likewise checks
current menu membership and captures the actual organ for attachment rather
than searching again by tag after delayed work.
[Cavity procedures](../code/modules/surgery/implant.dm) now create/seal space
only on committed completion and respect failed item unequips.
These transactional safeguards intentionally apply to the shared framework,
not only Alpha.

**Local choices, not recovered source constants:** inherited skill/success,
pain/infection and operating-surface rules; drill duration 50-70 ticks;
port insertion/removal 60-80 ticks; five sharp damage on failed neural work;
the existing wound/fracture representation and bone-gel repair stages;
inherited closure duration and failure effects; supply-kit contents and price.
No exact source rates, sounds, hand alignment or skill thresholds are claimed.
The wiki's empty-hand GRAB organ interface, original disinfection sequence,
single-eye procedures, tourniquets and complete implant-specific rules are
still unresolved rather than replaced with invented equivalents.

### Surgery validation and manual acceptance

Static inspection covers production includes, subtype discovery and priority
routing, instrument/storage/supply ancestry, actual asset-state existence and
the incision/access/port/repair/closure state path. Whitespace checks cover
the touched tracked and untracked sources. No compiler, game session or unit
tests were run; this is not runtime or perfect-parity certification.

Manual in-game verification remains necessary:

- On Alpha, operate on a lying organic patient using the supplied kit: create
  an incision, drill, remove an existing port, insert another, repair the skull
  and laser-close the incision. Confirm cyberdeck eligibility changes only
  with the real installed usable port.
- Repeat with an advanced port; refuse duplicate, damaged, dead, oversized,
  occupied-space and non-releasable implants without moving the held item.
- Interrupt selection and timed work by moving, switching tools or regions,
  incapacitation, incision changes, limb replacement and organ removal.
  Confirm no completion effect and that the region is available afterward.
- Operate concurrently on different regions and attempt simultaneous work on
  the same region; confirm independent selections and same-region exclusion.
- Check ordinary organ removal/attachment, MMI removal, cavity work, ordinary
  laser wound suturing and non-Alpha surgery for preserved behavior.
- Order the kit, inspect all nine instruments, hold each in both hands and
  compare appearance/position against the source rather than treating asset
  existence as visual parity.

## Neuroinhibitor and operating-table artwork

The **Stationary Neuroinhibitor** is now a placeable machine using `inhib0`
from the supplied OS13 `orbital_decor.dmi`. The five-frame `inhib1` state is
an indicator-only overlay, not a replacement machine body. It is composed
above lighting while switched on and operational, and disappears on power
loss or breakage. Adjacent, capable users can toggle the machine, producing
the on/off wording visible in **MED 00:28:40, 00:29:30, 00:29:50** and
**SCI 00:30:50**. The inspected science frame also shows its blue indicator.
A separate medical supply order delivers an unanchored unit; the standard
wrench-floor-bolts interaction allows placement and securing.

This addition implements the object and powered artwork only. It does **not**
establish or implement anesthesia, paralysis, pain blocking or psi suppression.
Examination explicitly warns that the indicator alone supplies no anesthesia.
No range, dosage, biological effect, source power cost or initial switch
position is inferred from the machine's name. The local switch defaults off
and power draw is one idle/five active units; it resumes its indicator after
power restoration if left switched on.

The existing Classic medbay operating-table placement now uses
`/obj/machinery/optable/os13`, retaining ordinary patient placement, surgical
surface recognition and linked patient-monitoring-console behavior. Its
supplied OS13 `surgery.dmi` states are connected as follows:

| State | Local display condition |
| --- | --- |
| `table1` | Monitor unavailable because the table is unpowered or broken |
| `table2-idle` | Powered table with no lying human patient |
| `table2-active` | Lying human patient with a detected pulse; native four-frame animation |
| `table2-active-dead` | Lying human patient without a detected pulse, not necessarily confirmed death |
| `table3` | Separate unmonitored operating-table subtype |

These are complete single-tile sprites, not pieces to stack or rearrange.
Other maps' generic operating tables are unchanged. The separate unmonitored
subtype has no local power draw; it is placeable but no invented map location
is assigned. Sprite-state existence, animation frame counts, includes, map
type wiring, supply path and power/patient update hooks were statically
checked. No build, unit tests or live game were run. Manual checks should
compare both table styles and lying/standing/pulseless patients, switch the
inhibitor on/off, interrupt power, restore power, break it, and verify that
the base body remains visible beneath its animated indicator.

## Supplies, surgery and fabrication boundaries

| Surface | Existing counterpart | Gap / evidence limit |
| --- | --- | --- |
| Hemostatic bandages | [OS13 supply types](../code/modules/os13/os13_video_objects.dm): gauze-derived, heal_brute 3. | Identity/art present; exact clotting strength, used-state sprite and treatment duration are not source-verified. |
| Bacteriophage bandages | Same file: heal_brute 2 and surface germ reduction by 100 at the committed wound hook; replicator supply design now exists. | Does not establish treatment of a particular wound infection; local germ coefficient remains unverified. |
| Ordinary bandaging | [Medical stacks](../code/game/objects/items/stacks/medical.dm) now revalidate and consume per committed wound; Medvisor control removes region-specific dressings. | Exact source unbandaging input, overlay art and timings remain unverified; clamps/ointment are separate. |
| Head cavity implant surgery | [Alpha neural-port route](../code/modules/surgery/os13.dm) adds direct skull drilling, installed-port removal and working-port insertion; shared cavity work commits only on completion. | Other implants retain local generic procedures; exact source implant identity, coefficients and every implant-specific recipe remain unverified. |
| Bone gel and repair | OS13-art gel/setter and stocked kit reuse gel/setter/gel stages; Alpha skull repair now preserves the incision for separate closure. | Exact source region prerequisites, timings and general fracture/disinfection sequence remain unverified. |
| Surgical laser suturing | [Alpha incision-closure priority](../code/modules/surgery/os13.dm) closes the surgical incision after skull repair; [ordinary wound suturing](../code/modules/surgery/suture_wound.dm) remains available. | Exact timing, effectiveness, source sound and held alignment are not certified; ordinary suture/cable and laser-scalpel cutting remain unchanged. |
| Artificial liver | Distinct OS13 cyber-organ product now robotizes through existing liver ancestry, with ordinary transplant/attachment and replicator design. | Exact source recipe, parent region, filtering coefficients, lifetime and failure behavior remain unverified. |
| Schriebmann Port | [OS13 neural organ and designs](../code/modules/os13/os13_wiki_counseling.dm), linked to [cyberdeck](../code/modules/cyberresearch/cyberdeck.dm), now use the shortened Alpha surgical route. | Ordinary/advanced products share the same installed-organ connection and slot. Advanced effects and exact source implant identity/sequence remain unverified. |
| Blood Substitute Injector | Five-dose OS13 product now uses existing nanoblood metabolism and logged injections, with attempt/commit checks and ready/spent art. | Five uses observed; dose, pharmacology, action timing, original capacity/refill and state mapping remain unverified. |
| theosin / hyperstim injectors | Hyperstim now has a separate physical subtype, formulation, actual combat-stat effects and attempted/completed injection with spent-object discard. See [medicine continuation](os13_medicine_parity.md). | Theosin remains unavailable; original dose, duration, individual stat deltas and drug side effects remain unverified. |
| Chemfabricator / chemical charge | Mapped/orderable water-and-charge-fed Chemfab with keycard lock, composed OS13 art/emissive screen, 17 inspected menu entries/costs and seven working injector formulations; see [supply loop](#implemented-chemfabricator-and-reagent-supply-loop) and [medicine continuation](os13_medicine_parity.md). | Ten remaining formulations, original doses, water requirements, maximum storage, contamination and automatic plumbing remain unverified. |
| Precursor-to-charge servicing | [ChargeMaster](../code/game/machinery/chargemaster.dm) converts one precursor into one selected refill, with five-second local cycle, cancellation and power pause. Chemistry output supplies five Chemfab charge points per item, grounded in the inspected post-load count; generic cartridge refill behavior is preserved separately. | No claim that every source charge variant has the same yield or that the local ChargeMaster conversion cycle is source-exact. |
| Multi-mode Medi-Kit | New OS13 medical tool provides four named independently charged modes, exposed-region checks and interruptible treatment. | Original timing/doses/charges/refilling and precise effect contracts remain unresolved; see local choices above. |
| Autonurse / Medchamber | Generic cryo, medical bots and transport infrastructure. | Exact source apparatus, automation, power/water/charge costs and interruption behavior remain unverified. A Nurse encountered in RUIN is not proof of station Autonurse equivalence. |

The help panel also names Hyperstim, Jetamite, Mnemosine, Oxivior, Torporine,
Monogreline, Drenex and Polythesine with stimulant/oxygen/paralytic/sedative/
psi-blocking/neuroleptic categories. These labels support a product inventory,
**not numerical pharmacology**. The medicine continuation now supplies local
reconstruction values for five products; their doses, duration,
contraindications, stacking and withdrawal still require source comparison.

## Visual/effect acceptance and remaining capture work

Manual in-game comparisons should include:

- Normal and injured regional diagnosis, with HEALTHY plus visible wounds.
- Authorized alive crew, dead crew, unauthorized target and missing bracelet.
- Radiation-flagged target and synthetic target.
- Full apparatus occupancy/lock/trigger/duplicate-installation flow.
- Successful, interrupted and cancelled injections; empty/used injector state.
- Clean/bloody bandage art, wound dressing, removal and supply depletion.
- Neural-port surgery and active dive interruption on port failure.
- Point-blank shot, bleed/fracture self-card, dizziness tint/blur, crawling and
  stretcher transfer as separate effects rather than one generic stun.

Still needed: dense review of surgery and console menus; exact input bindings;
effect onset/end frames; audible cues; medical production costs; automatic
nurse behavior; and actual subpersonality control. Ten-second samples cannot
measure a muzzle flash, injection animation, abrupt blur onset or action timer.
No such timing or complete sound parity is claimed here.
## OS13 body-scanner sprites

The existing body scanner and diagnostic console now use
`icons/os13/objects/objects/Cryogenic2.dmi`. The scanner retains its one-tile
footprint; the sheet supplies two mirrored complete chambers, not two halves.
The default `/obj/machinery/bodyscanner` uses `body_scanner_0/1`;
`/obj/machinery/bodyscanner/mirrored` uses `body_scanner1_0/1`.
Existing mapped scanners inherit the default art without map edits.

Occupied, powered, operational chambers animate and display their matching
`bodyscan0` or `bodyscan1` overlay above lighting, with a small cyan light.
Empty, unpowered and broken scanners have no glow. The light radius/color
are local visual integration, not source-certified values. Ambiguous duplicate
`*_10` states are not used. The console uses the matching animated OS13 art.
Diagnostic contents and printable reports are unchanged.

All entry/exit paths refresh the visual state; external occupant removal
clears the camera, lock, power mode and glow. Delayed loading rechecks the
subject and occupancy before committing. Console power loss no longer queues
a stale delayed icon change.

Static sprite/reference and whitespace checks were performed; no compiler,
Dream Maker, unit tests or live game were run. In-game checks remain: enter
and eject from both variants, load by grab/drag, remove the occupant externally,
interrupt delayed loading, toggle power and compare the glow in darkness,
then read and print a diagnostic report.
