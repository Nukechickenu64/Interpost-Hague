# Extended OS13 audit: research, fabrication, genetics and AI

See the [extended audit manifest](os13_extended_video_audit.md).
**OVR**, **SCI** and **GEN** denote the Overseer, Productive Science and
Genetics/AI recordings. **V** = inspected full-resolution sample;
**O** = OCR lead, not fully verified interaction.

Current physical-product integration for Laser Gun, Advanced FixBoy and
RemCom is recorded in the [weapon and remote-device continuation](os13_weapon_parity.md).
That implementation retains the distinction between observed catalogue roles
and original numeric balance, artwork and detailed interaction contracts.

The [Heavy Gravpulser continuation](os13_gravpulser_parity.md) adds that
named technology's physical five-shot, armor-bypassing product and uncharged
Replicator output. It preserves the existing reveal relationships and does
not unlock the product merely by discovering Gravcutter. Original damage,
battery servicing and exact graphics remain reconstruction boundaries.

The [Stun Mine continuation](os13_stun_mine_parity.md) connects its existing
named technology to a carryable single-use physical product, with real contact
stunning, deployment and disarming. The catalogue establishes its role;
source timing, strength, detection, servicing and exact sprites remain unknown.

## Cloning art, linking and lifecycle continuation

The supplied [OS13 cloning sheet](../icons/os13/objects/objects/cloning.dmi)
contains the actual chamber art. Full-resolution GEN `00:13:10` shows idle
chambers and the selection of **Clonepod A**. GEN `00:18:40` shows a green,
occupied chamber, **Clonepod B selected**, and **Not enough biomatter!**.
These observations support chamber art, independent pod selection and a real
resource prerequisite, not exact growth costs or timing.

### Implemented

- All [clone pods](../code/game/machinery/cloning.dm) now use that
  sheet's animated `pod_1`, idle `pod_0`, failed `pod_g` and broken `podb`
  states. `ind0` through `ind6` follow the existing bounded readiness value;
  `ready` requires full readiness and expiration of the initial eject delay.
  The indicator thresholds are local UI integration, not recovered source
  thresholds. The base definition uses this sheet too, so editor previews,
  newly constructed pods and non-Alpha maps no longer fall back to legacy art.
- GENECODE disks use the same OS13 cloning sheet's existing `datadisk0`
  through `datadisk2` animations; generic data disks are unchanged.
- The [Genetics Console](../code/game/machinery/computer/cloning.dm) keeps
  existing pod ownership across browser refreshes and actions. Discovery
  only adds unclaimed, anchored pods on the console's level in its area.
  Explicit multitool connections still work across areas, survive refresh
  and cannot steal a currently occupied/starting pod from another console.
  Removed/deleted links are pruned and remaining letter names refreshed.
- Scanner discovery no longer rotates the console as a side effect. Browser
  actions require usable access and operating power; displayed record names
  are HTML-encoded. Anchoring is rechecked after the pod-selection dialog and
  in the pod itself before any biomass is committed.
- Wrenching an unlinked pod no longer dereferences a missing console;
  disconnecting a linked pod uses the console's existing release helper.
  Both meat and biomass feedstock require an adjacent, capable user and
  a successfully removed held item before granting their existing 50 units.
- External occupant movement clears locks, readiness delay and cycle state,
  invalidating old delayed callbacks. Normal ejection captures its body
  before clearing state, and never teleports an already-extracted body back
  to the pod. Destruction, dead-clone rejection and power loss continue to
  use the same ejection path. Interrupted growth is not refunded.

### Validation and remaining limits

Focused source, include and whitespace inspection and direct DMI metadata/
frame inspection were performed. All referenced states exist and the pod/
indicator compositions were inspected. No compiler, Dream Maker, unit tests
or live game were run. The sprite states are verified assets, not proof of
identical original animation timing or indicator thresholds.

Manual in-game acceptance remains:

1. Compare both mapped pods while idle, growing, failed and broken; remove
   power mid-growth and verify ejection and removal of the running indicator.
2. Refresh two consoles repeatedly; verify a growing pod remains owned by
   its console. Verify explicit cross-area links survive refresh and an
   occupied pod cannot be reassigned to the other console.
3. Unanchor an unused linked and unlinked pod, then reanchor it. Verify link
   removal, letter names and rediscovery without a runtime.
4. Feed held meat/biomass, then try nonremovable/unheld items. Only successfully
   consumed items should increase stock, once, without dropping another item.
5. Extract/delete a growing body, start another cycle and wait past the old
   delay. The new body's lock and maturation delay must remain its own.
6. Round-trip a GENECODE disk and repeat the snapshot, partial-data and
   shock-gated observer checks below.

Authored Genemod effects, risk/skill formulas, original costs, physiology and
growth timing remain unresolved. The genetics biomass grinder below is a
separate machine; the hydroponics vats and kitchen gibber are unchanged.

## Genetics biomass grinder

The [genetics biomass grinder](../code/game/machinery/cloning.dm) is now
placed in [Classic Genetics](../maps/os13classic/os13classic.dmm) at
`(115,111,2)`, immediately south of the original clone pod, with a clear
approach from the east. It uses the supplied
[OS13 cloning sprites](../icons/os13/objects/objects/cloning.dmi), not the
kitchen grinder art.

- Insert held meat or an organic organ, or drag a stripped dead organic
  carbon/simple-animal body onto it. A grab can also load a corpse.
  Loading a corpse takes three seconds and rechecks the body, operator,
  machine and occupancy afterward. Living bodies, robotic organs,
  synthetic bodies and bodies carrying equipment are rejected.
- Click with an empty hand to start a five-second powered cycle. Power loss
  pauses processing without completing or consuming the material. Broken
  machinery cannot process. Alt-click unloads unprocessed material;
  processing locks normal unloading. A revived, capable occupant can exit.
- One meat item or organic organ yields one biomass brick; a corpse yields
  three. Click again to collect the bricks onto the floor. Each brick feeds
  the existing clone-pod interface for 50 units. These recipes and timings
  are explicit **local integration values**, not recovered original balance.
  Recycled corpses are deleted, with existing mob deletion preserving their
  player's observer; recycling is recorded in the existing attack log.
- Only the exact loaded material is consumed. Removing/deleting it cancels
  processing without output. Revival/equipment changes make a corpse
  unsuitable and stop the cycle. Machine destruction releases its input.
- `grinder00` is empty, `grinder0` holds material/product, and `grinderb` is
  broken. Existing `grindglass0/1/2` and `grindpaddle0/1` supply loaded,
  finished and powered-running overlays. Ambiguous duplicate `grinder1`
  and `grinder2` names are deliberately unused.

Static inspection covers the unique map placement, existing biomass/pod
integration, lifecycle guards, DMI state metadata/composition and whitespace.
No compiler, Dream Maker, unit tests or live gameplay were run.

Manual checks: process meat and an organic organ; load a stripped corpse and
reject a living/equipped/synthetic body; pause/resume power mid-cycle; extract
or delete input and verify no free output; destroy a loaded machine; collect
bricks and feed both clone pods; inspect empty/loaded/running/ready/broken
art. Original input catalogue, yields, automation, plumbing and animation
timings remain unverified.

## Genetics media and clone recruitment continuation

The GEN observations establish separate identity/donor data, biomass-backed
growth, lettered pods and physical GENECODE media. This continuation repairs
those workflows without inventing the authored Genemod sequence effects.

### Implemented workflow

- [OS13 Classic](../maps/os13classic/os13classic.dmm) previously placed a DNA
  modifier console and one clone pod, **but no cloning control console**.
  A **Genetics Console** now occupies the existing glass counter at
  `(117,111,2)`. A second pod occupies `(121,111,2)`, with an open approach
  from the south. The original pod at `(115,110,2)` remains.
  The console locates the existing scanner at `(120,111,2)` through the
  existing same-area linkage. The separate DNA modifier console at
  `(119,111,2)` is retained, not relabeled as the unimplemented Genemod system.
- [Cloning control](../code/game/machinery/computer/cloning.dm) labels its
  linked OS13 pods with letters. Other maps retain numbered names.
  The two placement choices are local integration, not source room coordinates.
  Scanner and console art is retained. The identified OS13 pod art is now
  wired as described in the cloning-art continuation above.
- Scanning now stores independent DNA, markings, language-list and flavor
  snapshots. Changing the living subject later does not rewrite the archived
  genotype. A delayed scan verifies the original scanner, original subject and
  operating power, rather than scanning a replacement occupant.
- **Save GENECODE** records UI, UE and SE together. Existing partial-save
  controls remain, but cannot export data missing from the selected record.
  Disk write protection and physical insertion are respected. Saving no longer
  changes the source record's flags or shares mutable DNA with it.
- **Import genetic record** is available without a pre-existing active record.
  It adds an independent record to the console database, where it can be
  selected as identity or donor. Partial UI/UE/SE records remain usable as
  partial data, but cannot initialize a clone without a complete genotype.
  Complete cloning records require identity, all three data flags and arrays
  of the expected lengths.
- [GENECODE diskettes](../code/game/machinery/cloning.dm) retain their OS13
  sprite and acquire the recorded person's `GENECODE` label on saving.
  [Medical cargo](../code/datums/supplypacks/medical.dm) offers five blank
  diskettes per order. Blank media does not contain a valid person's genotype.
- The [DNA modifier](../code/game/dna/dna_modifier.dm) also copies disk buffers
  on import/export, preserves the GENECODE label and clears references when
  disks leave. Buffer-generated injectors receive their own snapshot.
  Injector fabrication respects its cooldown and permits only one block
  selection at a time; cancellation produces no injector. Block injectors
  contain only the selected structural or identity data, not both categories
  from a full GENECODE. Stale label dialogs cannot restore a cleared buffer.
  UI-only capture now carries the UI flag. Full-record previews agree with
  their advertised data type. Transfers capture their original buffer,
  scanner and subject before the delay, reject interrupted operations and
  copy structural DNA rather than aliasing a saved buffer.
- Clone initialization rechecks the chosen pod, console link, selected records,
  operator access, power, occupancy, configuration and biomass after the
  selection dialog. Pod-level guards enforce the same growth prerequisites,
  including for callers other than the console.
- Biomass is committed **once at growth start**, not when a body happens to
  leave the pod. This prevents interrupted/deleted bodies from avoiding the
  cost. A previous cycle's readiness timer cannot mature a later clone.
  Destruction ejects the current occupant; a delayed malfunction targets the
  failed body it captured, not a future occupant.
- Importing a second copy of the same identity does not evade the existing
  same-origin mutation rule. That rule, randomized appearance/stats, current
  biomass quantities and ordinary growth medicine are inherited local
  mechanics, **not recovered OS13 balance**.
- On OS13, a fresh body cannot be claimed while still in a pod or before a
  neural-shock recruitment offer. A qualifying shock marks the ejected body
  available and notifies eligible observers; volunteering still uses the
  existing respawn and occupation checks. Other maps retain their original
  recruitment gate. Counselor training remains a separate skill transfer,
  never a genetic transfer of the donor's mind or expertise.

### Evidence limits

This is not a recovered Genemod implementation. The observed IF4, IUTA3,
LW10, LW18, PID9, QT3, RAC11, RAC16 and RAC2 identifiers, `(+)` marker,
skill-dependent hints, changing 3%/1% defect-risk display and their exact
effects still need a verified mapping. They are not aliases to random
structural-DNA blocks. Original disk format, provisioning, growth timings,
biomass costs, injuries and genotype-to-phenotype/stat rules remain unresolved.

Reinspection of full-resolution GEN `00:29:00` and `00:29:30` adds a narrower
lead: the player's **Memories of Nash Ampert** window records `IF4 muscle`
and then `LW10 HEALING`. These are player-written notes, not measured effect
values. The accompanying chat also mentions resistance to decompression,
aquatic respiration, telomere lengthening and resistance to pathogens.
The notes corroborate two likely sequence roles but do not establish their
strength, stacking, inheritance, failure outcomes or the other ID mappings.
No numerical effects or mutation aliases are inferred from those labels.

### Additional focused Genemod capture, 2026-11-02

New full-resolution samples at GEN **00:28:00–00:30:30** are retained under
`tmp/os13-genemod-continuation`. GEN **00:28:50** shows the native console
actions **Open the Chamber** and **Gene Sequences (Patient)**. The samples
at **00:29:00**, **00:29:20**, **00:29:40** and **00:29:50** add:

- Player-written `IF4 muscle`, `LW10 HEALING` and `RAC16 speed/dex?` notes.
  The question mark is retained as the player's uncertainty.
- Distinct system hints for myofibrils, rapid coagulation, rapid tissue
  healing, decompression resistance, aquatic respiration, telomere
  lengthening, pathogen resistance, accelerated muscle response and improved
  toxin processing. These are nine role leads, not measured effect values.
- The menu progresses from three `(+)` entries to eight during the sequence
  of inspections; RAC2 remains unmarked in the **00:29:40** selection frame.
  This does not establish that `(+)` means installed, active or merely
  inspected. Treating those states as interchangeable would invent behavior.
- Defect-risk messages of both 3% and 1%. The source does not isolate skill,
  selected sequence, patient condition or another cause as their formula.
- A later refusal: **Cannot scan DNA data: the organism is damaged by
  extreme amounts of radiation.** Its numerical threshold and owning scan
  action remain unmeasured.

The sequence selection and hint order provide hypotheses for further dense
inspection; they do not justify assigning all nine effects, mutating a
patient on mere inspection, or silently replacing the generic DNA modifier.
No Genemod mechanics were implemented from these uncertain associations.

### Static validation and manual acceptance

No compiler, Dream Maker, unit tests or live gameplay were run for this
continuation. Focused source/reference and whitespace checks cover the
changed files. Older compilation claims below are historical, not validation
of these changes.

Static map inspection resolves exactly one cloning console and two pods at
the coordinates above, all in the scanner's genetics area. The new console
has open east/west approaches; the new pod has an open south approach.
The project's direct includes resolve each changed genetics/counseling
module once, and the implant's `neuroimplant` sprite state exists.
The PsiBoost design is explicitly whitelisted and requires its named
technology on Alpha; generic non-Alpha research requirements remain separate.

In-game verification is still required:

1. Locate the new console, scanner and both pods. Confirm each pod is
   independently selectable by letter, is reachable and reports its own stock.
2. Scan two subjects, change one subject afterward, and confirm the stored
   record stays unchanged. Replace/eject a subject during scanning: no
   replacement record should be created.
3. Save a full GENECODE, write-protect/eject it, import it at another console,
   delete the original record and confirm the disk/imported copy survives.
   Compare identity, appearance and structural data independently.
4. Import UI-only, UI+UE and SE-only data. They must not be usable as complete
   clone genotypes or be upgraded to full records through the save links.
5. Hold a pod-selection dialog open while changing its link, records,
   occupancy, stock or power. A stale selection must not start growth or
   consume biomass.
6. Grow a clone, interrupt/eject it and grow another. Charge each cycle once;
   verify the previous readiness/malfunction callbacks cannot affect the new
   body. Repeat with pod destruction and power loss.
7. Attempt observer entry before release, after release but before a shock,
   and after a recruitment shock. Only the last should permit OS13
   recruitment. Confirm no mind/skills were copied from the DNA donor.
8. Create whole-buffer and single-block injectors from full and partial
   media. Cancel a block selection, repeat during cooldown, and remove power
   or walk away while choosing. No cancelled or stale operation should
   produce an injector. Change a buffer afterward: existing injectors must
   remain unchanged. Clear a buffer while a label dialog is open: submitting
   the old label must not restore the record.
8. Teach the volunteer a needed skill; interrupt the selection by moving or
   incapacitating either participant. Check borrowed knowledge expiry and
   independent knowledge gained afterward.

## Research evidence ledger

### Wiki-only technology requirement

The requested replacement catalogue is grounded in the local archived
Scientific Overseer and Cybertechnician pages. Generic Materials, Engineering,
Combat Systems, Bluespace and the other inherited research disciplines are
not entries in that catalogue. Restricting only visible links is insufficient:
archive admission, rewards, disk imports/backups, research reset and design
admission must agree on the same named catalogue.

The Scientific Overseer tables list:

| Tier | Initially available for extraction | Revealed/researchable |
| --- | --- | --- |
| 1 | ICE-Pick MK2; Distress Beacon; Gravcutter; Space Suit; Scan Mk.I; Battery; Artificial Organ; Solar Panel; Intensecure Light Armor; Portative Healthanalyzer; Water Chip; Stunner; Turbo Atmospherics | Anti-Personnel Mine; Scan Mk.II; Energy Cell; M41A Rifle Ammo; Machine Gun Ammo |
| 2 | Laser Gun; Stun Mine; Advanced FixBoy; ICE-Safety; Hand Tele | M41A Rifle; Machine Gun; Space Suit Mk2; Frag Grenade; Artificial Eyeball; Stun Rifle; Energy Gun; RemCom Device; Improved Solar Panel; Assault Vest |
| 3 | Advanced Schriebmann's Port; Satellite Coordinates; Advanced Cyberdeck | Captain's Keycard; PsiBoost Implant; Mag-Pulse Gun; Outer Comms |
| 4 | Flamethrower | PsiBoost Implant+; Heavy Gravpulser; Heavy Armor |

Energy Sword is explicitly named in Energy Gun's reveal column at tier 4,
although it has no separate table row. The Cybertechnician page additionally
documents base ICE-Pick, Scan and Emergency Exit software; these are not
permission to expose unrelated generic research.

The reveal relationships are:

- Distress Beacon -> Hand Tele; Gravcutter -> Heavy Gravpulser.
- Space Suit -> Space Suit Mk2; Battery -> Energy Cell.
- Artificial Organ -> Artificial Eyeball; Solar Panel -> Improved Solar Panel.
- Intensecure Light Armor -> Assault Vest; Stunner -> Stun Rifle.
- Laser Gun -> Energy Gun; Stun Mine -> Frag Grenade.
- Advanced FixBoy -> RemCom Device; Hand Tele -> Outer Comms.
- Advanced Schriebmann's Port -> PsiBoost Implant and Scan Mk.II.
- M41A Rifle -> M41A Rifle Ammo and Machine Gun.
- Machine Gun -> Machine Gun Ammo; Frag Grenade -> Anti-Personnel Mine.
- Stun Rifle -> M41A Rifle; Energy Gun -> Energy Sword.
- RemCom Device -> Captain's Keycard; PsiBoost Implant -> PsiBoost Implant+.
- Heavy Gravpulser -> Mag-Pulse Gun.
- Heavy Armor requires both Space Suit Mk2 and Assault Vest.

The wiki is internally inconsistent about some tiers: Hand Tele appears
initially at tier 2 but in Distress Beacon's reveal column at tier 4;
Assault Vest is a tier-2 table row but a tier-1 reveal, and Frag Grenade and
Anti-Personnel Mine also have conflicting reveal/table tiers. Preserve these
as source conflicts rather than silently presenting inferred values as fact.
Battery and Solar Panel are explicitly examples of Core Diskette contents;
the complete starting disk payload is not enumerated.

### Implemented wiki-only catalogue

#### Recorded payload and software panel continuation

The renderer became writable again. Recorded disk tier/level wording now
comes from the saved technology subtype, independently of map or active
archive mode. Generic research inserted on Alpha is labeled level; named
OS13 research is labeled tier. The numerical value still uses the payload's
existing display method, matching examination and Replicator disk operations.
The new snapshot field is populated before the active-session return, so
booting and running dives still show the old saved recording accurately.

The existing installed Scan/ICE-Pick summary now occupies a separate Alpha
software panel rather than being appended to every status message. It uses
the same station research lookups and generation precedence, but leaves
failure/overwrite messages uncluttered. It explicitly distinguishes a saved
disk from imported software. Both payload and software text are HTML-escaped.
The panel is present in all phases on Alpha only; generic archive interfaces
do not gain software controls. No research, media or gameplay gates changed.
This is local UI presentation, not exact source styling.

Static inspection covered every new snapshot key and renderer consumer,
phase ordering, unchanged ability lookups and escaping; scoped whitespace
checks passed. No compiler or live UI verification was performed. Manual
checks: inspect named/generic recordings on both map families; on Alpha compare
idle, boot and running views, abort and successful overwrite. Carry a software
recording, then import it and refresh to confirm only installed state changes
the panel. Destroy required data and verify the failure banner remains clear.

#### Replicator chemical-control identity continuation

Chemical purge controls now bind both the displayed Replicator and its
chemical holder. Switching machine links or replacing the holder invalidates
old single/all-purge links with a review-and-retry warning rather than letting
them discard another machine's chemicals. Single purge also warns when its
displayed reagent datum no longer exists in that holder. The all-purge link
is rendered once outside the reagent loop, only when chemicals are present.

Existing purge semantics remain: a valid single purge removes all of that
reagent type, while all-purge removes the holder's current contents, including
additions since display. This does not reserve quantities, alter access rules,
change recipes or affect compartment feedstock. It is a local interaction
integrity fix, not a source-certified chemical-storage behavior.

Static inspection covered link generation and both handler branches,
machine/holder identity and missing-reagent feedback; scoped whitespace checks
passed. No compiler or live checks were run. Manual checks: open chemical
storage, change the machine link and activate old controls; repeat after
holder replacement or consumption of the selected reagent. Confirm rejection
leaves the new machine's chemicals intact, valid controls still purge, and
multiple reagents produce only one all-purge link.

The renderer was write-locked (Windows error 1224) during this pass. The later
recorded-payload/software-panel continuation above completes those UI changes.

#### Technology import payload consistency continuation

Alpha technology imports now require the exact recorded installed-state value
1, matching successful cyberdeck output and console backups. Previously any
positive value was accepted and silently normalized to 1, despite archive
difficulty being a separate tier. The central research admission path and
console preflight now agree: zero, negative, fractional, textual and values
above 1 do not constitute a valid named recording. This does not restrict
the four archive tiers or change ordinary-map numeric progression.

The delayed console import also snapshots the technology ID and recorded
level. Besides the existing disk/datum/database identity and power checks,
it now rejects in-place changes to those values during processing with an
explicit review-and-retry warning. No technology/design/reveal update happens
on that branch, and the disk is not erased. Deleted recordings are rejected
before preflight accesses their fields. Normal duplicate imports remain
idempotent and valid level-1 backups can still restore a reset console.

Static inspection covered named reward/backup levels, central admission,
delayed ordering before research mutation and generic-map preservation.
Scoped whitespace checks passed. No compiler or live checks were run.
Manual checks: import a normal tier-4 recording and verify installed state 1
with tier 4 retained; restore it after reset. In a controlled debugging
session, change the payload ID/level during processing and verify rejection
without unlocks. Try malformed named levels and confirm explicit refusal,
then verify ordinary-map level upgrades and duplicate imports still work.

#### Active archive ownership continuation

The shared dive validity check now requires reciprocal avatar-console
ownership and a live, busy archive owned by that console, with generation
finished and cancellation unset. A matching z-level alone is insufficient.
Collection, software, ICE interactions, movement bonuses and disk completion
already use this check; they now reject released or foreign archive state.
The existing monitor recalls an invalid session without recording data.

Cleanup also refuses to release an archive explicitly owned by another
console, logging the mismatch instead. Ownerless slots are still released
for failed boot cleanup, where acquisition precedes generation ownership.
The stale console reference is cleared in either case. Normal release,
physical return, disk preservation and other-map gameplay remain unchanged.
These are local session-isolation safeguards, not newly inferred source rules.

Static inspection covered acquire/generate/release ownership transitions,
normal running state and cleanup-before-reuse; scoped whitespace checks
passed. No compiler or live checks were run. Manual checks: ordinary boot,
collect/recall, aborted generation and consecutive dives. In a controlled
debug session, invalidate archive ownership, busy/cancelled state or avatar
back-reference; confirm interactions stop, no disk write occurs, and recall
does not release an archive owned by another active console.

#### Functional SCAN Diskette continuation

The existing SCAN Diskette previously inherited ordinary disk behavior and
was rejected as an unsupported format by the Replicator console and cyberdeck.
It now explicitly inherits the existing OS13 technology-disk implementation
while retaining its old type path, name, OS13 sprite, tiny size and throwing
properties. On Alpha initialization it records an independent Scan Mk.I
technology datum, matching the Scientific Overseer entry's explicit
"Available on a diskette" description. On other maps it initializes blank;
normal generic-map catalogue rules still reject named OS13 research.

Examination, normal delayed console import, erasure, backup, ejection and
confirmed cyberdeck overwrite now work through existing media paths. Import
enables the current station-network Scan ability; merely holding/inserting
the disk does not. Payload creation occurs only on initialization, not on
erasure, ejection or reinsertion. No new technology, fabrication recipe,
roundstart provisioning or map placement was added. Existing searches found
no map placements of this named disk, so this repairs the item's behavior
without claiming it is now supplied to players at round start.

The ordinary ICE-PICK Diskette remains separate and unconnected: the observed
Mk.I software requires a distinct installation/provisioning design rather
than mislabeling it as the wiki's MK2 research upgrade. This pass does not
silently convert it to MK2 or add a non-wiki technology.

Static inspection covered inheritance, the included type definitions,
Alpha-only payload creation, normal media admission and existing one-time
installed-state import. Scoped whitespace checks passed. No compiler or live
checks were run. Manual checks: spawn a SCAN Diskette on Alpha, examine it,
import it and confirm Scan becomes available. Erase/eject/reinsert and confirm
it stays blank; back up another installed technology or perform a confirmed
successful cyberdeck overwrite and verify the actual payload changes. Abort
an overwrite and confirm Scan Mk.I remains intact. On other maps confirm it
initializes blank and generic research progression is unchanged.

#### Installed software summary continuation

Alpha initially exposed a read-only station software summary in the status
banner in idle, booting and running views. The later panel continuation above
moves it to its own section. Scan distinguishes unavailable,
installed Mk.I and installed Mk.II; ICE-Pick distinguishes its base ability
from installed MK2. Upgraded generations take precedence and show the
implemented 10x recharge effect. The summary uses the same network lookup as
the avatar abilities, explicitly distinguishing saved recordings from imported
research. It makes no claim that ICE-Safety or other unimplemented effects
work. Generic maps do not gain the summary.

The original summary was appended only to the read-only UI snapshot, not the underlying
status message, so refreshing does not accumulate duplicate text or erase a
download-failure message. The existing renderer escapes the combined text.
Presentation is local UX, not exact source layout. A proposed separate panel
and payload-derived tier/level label correction could not be applied because
the renderer was write-locked (Windows error 1224); no unused snapshot fields
were left behind. The later recorded-payload continuation above completes
both changes; the media label now follows the saved technology subtype.

Static inspection covered shared ability lookups, snapshot ordering before
the active return, no persistent mutation and existing banner rendering;
scoped whitespace checks passed. No compiler or live UI verification was
performed. Manual checks: compare states before/after imports, duplicate
imports, reset and installation at another console, refreshing in each phase.
A carried/loaded disk alone must not enable Scan or MK2. Resetting the last
installed copy must remove the corresponding summary state and ability
permission, without removing base ICE-Pick. Refresh repeatedly after required
data destruction and confirm its failure message remains without duplicated
software summaries.

#### Cyberdeck session display continuation

The renderer became writable again. Its running Alpha session objective now
replaces the normal collection instruction when required data has been
destroyed, rather than contradicting the failure banner. The neural-link
panel distinguishes an actually implanted, usable advanced port from a
standard port and describes the existing interior Blue ICE traversal.
The session shows remaining protection-grace seconds or an awake warning,
plus Blue ICE, Scan and ICE-Pick instructions and the destructive-data warning.

These are read-only snapshot fields, not new software/recall controls or
changed gameplay. Protection readings explicitly require Refresh status;
they are not a live countdown. Generation continues displaying its existing
boot message rather than claiming that protection is already awake. New
details are collection-mode gated; generic relay interfaces are unchanged.
Wording/layout remain local presentation, not exact recovered source UI.

Static inspection covered each snapshot key and renderer consumer, destroyed
data taking precedence over the collection instruction, boot/running gating,
and inherited map behavior. Scoped whitespace checks passed. No compiler or
live UI verification was performed. Manual checks: open/refresh the operator
console during boot, grace, after grace and after data destruction; compare
standard/advanced/disabled ports; verify non-Alpha sessions retain relay text.

#### Scan field-of-view coverage continuation

Scan now uses the invoking client's actual view size rather than the world's
default view. This follows the existing client-view interaction pattern and
supports both numeric and rectangular BYOND view settings. The pulse also
includes visible archive grid floors and cyber avatars, alongside nodes and
Blue ICE, closing the previously documented omission from the wiki's
"everything in the field of view" rule for the currently implemented archive
contents. It still uses visibility-limited `view`, not through-wall `range`,
and continues excluding transparent/collected targets and entities above the
avatar's see-invisible threshold. Boot and activation guidance match coverage.

Static inspection covered the client-view call, target types and inherited
visibility filters; scoped whitespace checks were performed. No compiler or
live checks were run. Manual checks: Scan with a view smaller and larger than
the world default and a rectangular view; confirm only visible in-viewport
targets are initially highlighted, including grid/avatar. Confirm obstructed,
invisible and collected targets remain excluded, and recall clears all images.
Exact visual styling and unimplemented hidden-entity detection remain gaps.

#### Destructive data-loss feedback continuation

ICE-Pick destruction of useful data now records a separate per-dive loss
count. It does not award collection credit or reduce the original objective.
The existing console status banner immediately reports the count, that the
download is unavailable, that prior disk contents are unchanged, and that
EJECT/restarting is required. Later pickups repeat the warning rather than
only reporting an apparently achievable DATA LEFT total. Completion explicitly
refuses writing if required data was destroyed. Layout construction and
instance release both reset loss tracking for the next dive.

This preserves the wiki's destructive-data consequence, with locally chosen
failure wording and restart guidance. The renderer was initially write-locked
(Windows error 1224); the later session display continuation above updates
the objective paragraph as well as the existing status banner. DATA LEFT includes
missing/destroyed data, not just surviving pickups. Cancellation, rejected
ICE-Pick, Red ICE removal and wall deactivation do not mark research lost.
The ICE-Safety source description was checked: it concerns brain protection
and fatigue, not accidental data removal, and no unrelated effect was added.

Static inspection covered loss accounting, no-credit behavior, completion
ordering, reset and the existing status-banner rendering; scoped whitespace
checks were performed. No compiler or live checks were run. Manual checks:
destroy one and then multiple research nodes, inspect the console banner,
collect surviving data and confirm warnings/no download, then EJECT/reboot
and confirm a fresh objective with no carried-over loss. Cancel destruction
and remove Red ICE instead to confirm neither marks the download unavailable.

#### ICE-Pick software continuation

The Cybertechnician wiki says ICE-Pick removes information in cyberspace and
warns against targeting useful data or the exit. The Scientific Overseer wiki
says MK2 recharges 10x faster. Alpha avatars now have a base ICE-Pick ability
that selects a nearby visible archive node or Blue ICE barrier. Installing
ICE-Pick MK2 through research reduces subsequent recharge from the locally
chosen thirty seconds to three seconds. The absolute timing, adjacent range,
selection dialog and confirmation are local choices, not source-certified UX.
Other maps do not gain this ability.

Interior Blue ICE removal reuses tracked-floor deactivation so archive
release restores the wall. The sealed boundary still refuses removal.
Nodes are removed from the instance ownership list and deleted. Removing
Red ICE prevents its later collisions. Removing uncollected data does not
award collection credit or reduce the objective: completion becomes impossible
for that dive, as the confirmation warns. Removing the portal leaves the
independent EJECT ability available. Both destructive targets require
confirmation; cancellation changes neither data nor recharge. This does not
implement floor destruction, future hidden entities or ICE-Safety.

After selection and confirmation yields, the operation checks session
identity, valid mind/link, current cooldown, visibility, adjacency, instance
ownership and node generation. Stale selections cannot act on a recycled
archive. Failed operations warn without spending cooldown. Successful removal
clears the current Scan pulse to prevent stale highlights of deleted targets.
The Status panel exposes the separate ICE-Pick recharge. Direct Blue ICE
left-click deactivation remains a separate action without this cooldown.

Static inspection covered source rules, the 10x ratio, destructive-target
confirmation, ownership/generation checks and no-credit removal; scoped
whitespace checks were performed. No compiler or live checks were run.
Manual checks: remove interior ICE and Red ICE; cancel a data/exit confirmation;
confirm data removal and verify no credit/download; remove the portal and
EJECT safely. Keep a selection open across recall/reboot, simultaneously open
two selections, or move out of reach and confirm rejection. Compare base/MK2
recharge, boundary rejection and wall restoration on release.

#### Scan target invalidation continuation

Scan overlays copy target appearances. Collecting a highlighted research node
previously hid the actual node but left the copied data visible until the pulse
expired; opening a highlighted Blue ICE wall had the same stale-image problem.
Both successful collection and successful barrier deactivation now clear the
avatar's current pulse before changing the target. Rejected interactions do
not clear it, and the original Scan recharge is preserved. Clearing the whole
pulse instead of tracking per-target images is an explicit local presentation
choice. The user can Scan again when its normal recharge finishes.

Static inspection verified ordering before alpha/turf changes, timer
cancellation and unchanged collection counts, boundary rejection and recharge;
scoped whitespace checks were performed. No compiler or live checks were run.
Manual checks: Scan and collect a non-final data point, then verify no ghost
highlight remains and recharge is unchanged; repeat with an interior barrier,
and verify clicking a sealed boundary does not prematurely clear the pulse.

ICE-Pick was initially blocked by Windows error 1224 on the avatar source.
The subsequent ICE-Pick continuation above implements the action after the
lock cleared.

#### Scan software continuation

The archived Cybertechnician software section says Scan highlights everything
in the field of view. The Scientific Overseer table makes Scan Mk.I available
on diskette and says Scan Mk.II speeds recharge by 10x. Alpha avatars now have
a Scan ability gated by installation of either named Scan technology in the
station research network. Revealing an archive or merely carrying its disk
does not enable the software; successful console import does. Installed Mk.II
uses exactly one tenth of the base recharge. Other maps do not gain Scan.

The implemented pulse highlights visible archive nodes (data, hazards and
exit), Blue ICE, grid floors and avatars using client-only cyan image overlays.
Already-collected
invisible data is excluded; nothing outside ordinary view is initially
revealed. It does not collect, remove or alter its targets. This is a snapshot,
not continuous tracking of newly visible targets or changes to appearances.
Successful data collection or barrier deactivation clears the current pulse
to avoid stale copied images, without resetting its recharge.
Grid/avatar coverage was added in the subsequent field-of-view continuation.
Unimplemented hidden entities and exact source styling remain unresolved.

Highlight duration is locally chosen as three seconds, base recharge as
thirty seconds and Mk.II recharge as three seconds; these absolute values and
the color are not certified source settings. Mk.II supplies Scan without a
separate Mk.I install. The installed software is checked each time; an upgrade
does not retroactively shorten an already-started recharge. Repeated requests
while recharging warn with remaining time; Status exposes the countdown.

The owning client and images are tracked explicitly. The timer and overlays
are cleared before mind return on every console cleanup, on avatar logout,
and defensively on deletion. No client images should survive physical return
or be passed to another dive.

Static inspection covered software gates, exact recharge ratio, visibility
filtering and lifecycle cleanup; scoped whitespace checks were performed.
No compiler or live gameplay checks were run. Manual checks: try Scan before
installation, then install Mk.I and confirm data/ICE/exit highlights,
recharge refusal and expiration; install Mk.II and compare recharge times.
Recall, disconnect, die or destroy the console during the pulse and verify
no highlights remain after returning. Confirm already-collected data and
out-of-view nodes are not initially highlighted.

#### Advanced port speed and download integrity continuation

The avatar source became writable again. Advanced port movement now uses the
normal movement-intent delay hook: a valid Alpha dive with an actually
implanted, usable advanced port halves that component, with a 0.5-tick lower
bound. The check is live on every request. Standard ports, loose implants,
invalid sessions and non-Alpha maps retain the inherited delay. Terrain,
pulling and other movement penalties remain in the separate inherited
movement-delay calculation. This is not a claim of twice the observed speed:
server tick resolution and those penalties still affect actual cadence.
The wiki specifies faster movement but not its multiplier, so the half-delay
and lower bound are local tuning. Boot guidance now mentions both effects.

Completion now rejects missing/deleted, out-of-catalogue or invalid-level
pending research before any disk write or success notice. Alpha recordings
must carry installed-state level 1, distinct from archive tier. A rejected
download logs its reason and recalls with an explicit failure message,
preserving the old disk payload and label rather than erasing it or failing
while constructing the completion message.

Static inspection covered inherited movement scheduling, live implant
validation, completion-before-write ordering and cleanup; scoped whitespace
checks passed. No compiler or live checks were run. Manual checks: compare
walk/run cadence with standard versus advanced ports, with and without
terrain/pulling penalties; disable or replace the advanced port during a
dive and verify the bonus stops. In a controlled debugging session, invalidate
pending research before completion and confirm recall, no success notice and
unchanged prior disk contents. Confirm ordinary downloads still import.

#### Advanced port ICE traversal continuation

The Scientific Overseer wiki describes Advanced Schriebmann's Port as a
replacement implant that speeds cyberspace movement and permits passage
through ICE. The existing advanced-port recipe and surgical organ previously
provided only the standard connection requirement. Its ICE traversal effect
is now connected to the active Alpha dive.

An avatar with a usable advanced port owned by its physical operator may
walk through interior Blue ICE without removing or changing the turf.
The check uses the actual implanted subtype, not research installation alone
or an advanced implant held in inventory. Removing, disabling or replacing
the port removes this permission on the next attempted crossing. A standard
port does not gain traversal. Active session, instance ownership, avatar
identity, neural link, correct z-level and interior coordinates are all
checked before allowing passage. Archive boundaries remain sealed as a local
containment rule; no cross-instance or general noclip is granted.

Traversal leaves data, exits, Red ICE and ordinary collision processing
untouched. Other maps retain their original wall behavior. The subsequent
speed continuation above adds the movement effect with explicitly local
tuning; exact source cadence remains unverified.

Static inspection covered the normal turf Enter/CanPass path, standard-port
fallback, live implant ownership/usability and instance bounds. Scoped
whitespace checks were performed. No compiler or live checks were run.
Manual checks: fabricate/install the advanced port through existing surgery,
boot and walk into interior ICE; confirm the wall is unchanged and the outer
boundary blocks movement. Repeat with a standard port, an advanced port held
but not implanted, a disabled implant, and another instance's avatar. Confirm
Red ICE and research data still trigger their existing collision behavior.

#### Initial protection grace continuation

The archived Cybertechnician Inside section states that active protection
sleeps for the first 10-30 seconds, allowing orientation before detection.
Alpha dives now choose a whole-second grace interval in that range when the
avatar starts running, rather than spending the interval during generation.
Red ICE collisions during this interval give an asleep notice and do not
apply the existing integrity damage. At the exact deadline protection is
active again. Boot chat reports the chosen interval; cleanup clears it.
Other maps retain their previous immediately active Red ICE behavior.

Uniform random selection within the source range and the chat wording are
local choices. This gates only the currently implemented collision hazard;
it does not implement dormant guardians/scanners, Red ICE security escalation
or source brain damage. After grace, Red ICE still uses the local 20-integrity
damage behavior pending that larger hazard reconstruction.

Static inspection covered start/cleanup ordering and the map-gated collision
branch; scoped whitespace checks were performed. No compiler or live checks
were run. Manual checks: collide with Red ICE before and at/after the reported
deadline, verify no early damage and normal post-grace damage, recall/reboot
and confirm a fresh interval, and verify generic-map collisions are unchanged.

Scan was initially blocked by Windows error 1224 on the avatar source.
The later Scan continuation above implements the ability after that lock
cleared; its remaining limits and local timing choices are documented there.

#### Whole-nugget ore admission continuation

Direct ore feeding now requires enough connected storage capacity for the
entire existing one-sheet yield. Previously any positive free capacity
allowed a nugget to be consumed while only that remaining fraction was saved.
The machine now warns before unequipping it when there is insufficient room,
and rechecks after unequipping before transferring material. If storage
changed, the unprocessed ore returns to the user's turf. Rejected feeding
does not consume power or trigger conversion radiation.

Capacity is still pooled across connected matching compartments, including
locked ones: locks restrict production withdrawal, not deposits. A yield
can span multiple reservoirs. Existing ore yield, sprites and successful
conversion behavior remain unchanged. Rejecting a partial-capacity deposit
is a local material-preservation safeguard, not a source-certified capacity
rule. Sheet reclamation already admits only complete sheets; partial salvage
of ordinary reclaimed items is unchanged.

Static inspection verified the capacity check, post-unequip recheck and
non-yielding storage-transfer loop; scoped whitespace checks passed.
No compiler or live gameplay checks were run. Manual checks: leave less than
one nugget's yield free, attempt feeding each supported ore and confirm it
remains intact with no flash; free exactly one yield and confirm full recovery;
split that capacity across connected reservoirs and confirm the same full
recovery; confirm locked compartments still accept deposits but cannot supply
queued production until unlocked.

#### Recorded disk label consistency continuation

Technology disk recording and erasure now share one metadata update path.
Previously a standard disk written by cyberspace could retain its old
technology name/description after erasure, and a console backup could leave
that obsolete label on a different payload. Both standard disks and OS13
diskettes now refresh their visible labels on successful recording and restore
their subtype's initial name/description on erasure. Named OS13 research uses
archive tier; ordinary research uses level. OS13 Diskette/Core Diskette names
remain intact. This is data-presentation consistency, not source-certified
wording or additional Core Diskette contents.

Cyberdeck completion, Replicator-console backup/erase, BBS downloads,
datajack erasure and infernal disk creation use the shared path. Infernal
creation still applies its existing provenance-specific label afterward.
This changes no payload ownership, import requirements, fabrication gates,
or cyberdeck overwrite timing: failed/aborted dives still leave recorded data
and its label untouched.

Static inspection covered production recording/erase call sites and scoped
whitespace validation. No compiler or live gameplay checks were run. Manual
checks: download onto each disk subtype, erase at a console, then back up a
different technology and inspect the name/description/examine output at each
step; repeat erasure through a datajack. Confirm failed/aborted overwrite
dives preserve both the prior recording and label.

#### Archive discovery feedback continuation

Successful Alpha technology imports now report newly revealed cyberspace
archives separately from newly available Replicator designs. The notice
explicitly states that revealed data must still be extracted and installed.
It is a local presentation choice, not a claim about exact source UI wording.

The console compares station-wide archive availability immediately before
and after a successful import. Cyberdeck visibility and admission use the
same shared availability helper, preserving the existing console/server
research lookup and all-parent prerequisite rule. Duplicate imports, archives
already revealed by another console, and initially available entries do not
produce new-discovery notices. The imported archive itself is also excluded:
restoring a hidden technology from backup must not tell the user to extract
the technology they just installed. Heavy Armor is reported only when both of its
parents are installed somewhere on the station. Interrupted or rejected
imports produce no discovery notices and retain the existing failure message.

Static inspection covered the shared lookup, import ordering, duplicate
suppression, multi-parent reveal and unchanged generic-map behavior.
Compilation and live gameplay verification were not performed. Manual checks:
install Battery and confirm Energy Cell is named; repeat at another console
and confirm no duplicate discovery; install Space Suit Mk2 and Assault Vest
in either order/across separate consoles and confirm Heavy Armor appears only
after the second parent. Confirm revealing an archive does not unlock its
fabrication designs until its own data is installed.

The file lock cleared during the catalogue implementation. OS13/Alpha now
uses **45 named technologies**: all 44 table entries (including Outer Comms,
whose HTML row has only two cells) plus Energy Sword from the reveal column.
Generic Materials, Engineering, Bluespace and other inherited disciplines
are excluded from OS13 research initialization, reset and cyberdeck admission.
Other maps exclude the new named types and retain their generic progression.

- New OS13 databases start with no extracted technologies installed. The 22
  initially available entries are extractable; the other 23 become available
  through the listed reveal edges. Heavy Armor requires both parent entries.
  Installed entries remain visible but cannot be extracted as level 2, 3,
  etc.; acquisition is a one-time installed/not-installed state.
- Main table rows determine archive tier 1-4 where reveal text conflicts.
  Hand Tele remains initially available at tier 2. Reveal edges do not add
  extra tier variants or duplicate technology identities.
- Cyberspace generation, hazards and the existing local deadline use the
  named archive tier, not the installed-state value. These retain local
  geometry, hazard-count and timing choices, not certified source tuning.
- Final collection records the named technology on an independent physical
  disk. Its name/tier is shown by examination, disk operations, backup,
  reports and the cyberdeck. Normal console import installs it and the
  cyberdeck's existing console-aware research scan reveals successor entries.
- Generic technology imports are explicitly refused on OS13. Technology
  backup lists omit uninstalled entries and stale/direct copy requests
  cannot manufacture their recordings. Analyzer level gains cannot bypass
  named extraction.
- OS13 research/design admission and Replicator queue/build/completion
  checks use an exact blueprint-type whitelist. Unlisted design disks cannot
  import or fabricate generic equipment; IC reclamation cannot introduce
  arbitrary prefab designs. Legacy imprinter admission/build is also gated.
  Resetting the linked console pauses a valid waiting/active recipe until
  its named technology is installed again rather than spending feedstock.
- The whitelist now admits 16 product designs for Battery,
  Energy Cell, Solar Panel, Improved Solar Panel, Space Suit, Space Suit Mk2
  (magnetic boots), Stunner, Stun Rifle, Water Chip and Advanced Schriebmann's
  Port, Gravcutter, Artificial Organ (the existing Artificial Liver product)
  and Artificial Eyeball, plus the partial PsiBoost communications implant
  described in the [counselor continuation](os13_extended_medical_audit.md#psiboost-communications-and-counselor-continuation).
  Existing recipes/costs are retained; the new implant recipe is local tuning.
  These are not source-certified
  prices or complete source equipment sets. In particular, the inherited
  Stun Rifle recipe still requires silver, which the three-material OS13
  reservoirs do not provide; its source-compatible recipe remains unresolved.
- Blank OS13 technology diskettes and blank design disks remain producible
  infrastructure without an extracted technology. They do not add generic
  research disciplines. No unrelated stock parts, weapons, boards or
  equipment are granted as substitutes for missing catalogue products.

The same pass completed the previously blocked Boot-link safeguard: links
identify their physical disk, recording/blank state, dive ID and selected
archive tier/level. The handler validates these before boot, rejects unknown
or unrevealed technologies, and rechecks archive availability and level after
overwrite confirmation. The old file-lock notes below describe earlier
passes, not the current Boot implementation.

**Remaining parity gaps:** named research does not by itself implement each
entry's software, global upgrade, equipment set or implant effect. Technologies
without a mapped product can still be extracted, installed, revealed and
backed up, but do not grant an invented replacement product. The Core Diskette
is still not provisioned with the source's multi-technology initial payload.
Rifle/ammunition production requirements need integration when their products
are implemented; they are not made cyclic archive prerequisites. Base
Source Emergency Exit penalties remain software/action work; ICE-Pick and
Scan now have the partial implementations described above. These are not new
generic research fields. Progress ownership remains the existing local
console plus station-wide archive-discovery scan, not recovered source rules.

Manual acceptance (not performed):

1. On a fresh OS13 round, inspect empty console research and the 22 initial
   archive choices. No generic discipline or hidden successor should be
   extractable, including with a direct URL.
2. Extract Battery: its disk should identify Battery, tier 1. Install it,
   fabricate the existing basic cell, and verify Energy Cell becomes
   available while Battery is marked installed. Back up/import Battery at
   another console and verify the snapshot survives reset of the first.
3. Extract/install Stunner, then Stun Rifle, then M41A Rifle. Verify the
   respective reveal chain and named tiers without adding generic weapon
   designs. Heavy Armor must remain hidden until both parents are installed.
4. Insert generic technology or an unrelated design disk. Imports must
   refuse without altering the media or unlocking unlisted products. Repeat
   direct/stale production and imprinter requests; no feedstock is spent.
5. Reset a console while its Replicator is producing a mapped item. The
   valid recipe should wait for its technology to be installed again.
   The queue must explain the technology requirement.
6. Replace/rewrite media or complete/recall a session before using an old
   Boot link. It must not start a dive. Change research during overwrite
   confirmation and confirm outdated/completed archives are refused.
7. On a non-Alpha map, verify generic research levels, technology import,
   relay/core extraction and ordinary blueprint fabrication remain intact.

Validation uses focused source inspection and read-only reconciliation of
the HTML tables, named datums, reveal graph and included design paths.
The reconciliation found 45 distinct names/IDs, no missing or unlisted names,
no main-table tier mismatches, 22 initial choices and all 45 entries reachable
through the reveal graph. The earlier batch's 17 whitelisted design paths resolve in the
project's included source. Scoped code and documentation whitespace checks
passed.
No Dream Maker/compiler, unit tests or live in-game verification were run.

#### Existing OS13 product integration continuation

The wiki-only whitelist now maps the existing TNC Gravcutter design to
Gravcutter, Artificial Liver to Artificial Organ, and Artificial Eyeball to
Artificial Eyeball. These are exact existing design types, not broad category
exceptions: unrelated mining tools or medical equipment remain excluded.
Artificial Organ currently produces only the existing liver, not an invented
complete organ set.

All three recipes use the supported steel/glass/plasteel storage keys
(displayed as steel/zbrite/elerium) and retain their existing costs. Their
existing object paths, supplied OS13 sprites, fabrication and normal use or
organ surgery paths are unchanged. Importing Artificial Organ still reveals
the Artificial Eyeball archive; revealing it is not sufficient for producing
eyes until that separate technology is extracted and installed.

Manual checks (not performed):

- Before installation, reject copies/imports/production requests for these
  blueprints. Install Gravcutter, unlock and load steel/elerium, then produce
  the TNC Gravcutter. Verify the existing instant mining behavior.
- Install Artificial Organ and fabricate its existing liver. Verify its
  cybernetic state and ordinary liver surgery path. Confirm Artificial
  Eyeball becomes extractable but cannot yet be produced.
- Extract/install Artificial Eyeball, then fabricate and implant it through
  ordinary eye surgery. Compare its existing OS13 appearance and sight
  restoration with the pre-existing item behavior.
- Reset the linked console: these products must disappear from its menu;
  queued jobs wait for the corresponding technology to be installed again.
- On other maps, confirm their original generic prerequisites remain in use.

Focused source inspection and read-only design/recipe/include reconciliation
were performed, plus scoped whitespace checks. No compiler, unit tests or
live in-game checks were run.

| ID | Source / visible time | Observation | Established behavior / limit |
| --- | --- | --- | --- |
| SCI-01 | OVR 00:06:00, O | Research Expert with other specialist disciplines novice. | Role skill distribution; not evidence that all novice actions are forbidden. |
| SCI-02 | OVR 00:08:00; SCI 00:09:50, V for SCI | Diskette examination with Technologies heading; empty example. | Physical technology media with inspectable contents. |
| SCI-03 | OVR 00:09:20, V | SCAN MK.I and ICE-PICK MK.I installed; ICE-PICK Diskette contains ICE-Pick Mk.I. | Software identities and physical disk payload. A distinct OS13-art ICE-PICK Diskette now represents the observed software payload; installation, provisioning and software behavior remain unverified. |
| SCI-04 | OVR 00:09:40, V; SCI 00:10:00-00:10:10, O | Core Diskette and separate Steel, Elerium, Zrbite storage unlocks. | A distinct Core Diskette now uses existing OS13 technology media and R&D/cyberdeck handling; its source provisioning, initial data and relation to separate locked supplies remain unverified. |
| SCI-05 | SCI 00:10:30, V | Hidden data discovered for Energy Cell, EMP Grenade, Improved Solar Panel, Artificial Eyeball. Artificial Organ installation precedes the Artificial Eyeball notice in visible scrollback. | Named discovery/unlock feedback. This scene alone does not prove an exclusive prerequisite edge or physical organ implantation. |
| SCI-06 | OVR 00:12:00; SCI 00:12:20, O | Cyberspace Core Console unlock and seated technician arrangement. | Separate physical operator/console role. |
| SCI-07 | SCI 00:12:30, O | No-diskette warning says progress may not save. | Missing-media branch. Does not alone prove a media-less dive is allowed. |
| SCI-08 | OVR 00:12:20; SCI 00:15:30; SCI 00:24:00, V for SCI 24 | Warning that recorded disk data may be overwritten. | Previously differed from unconditional refusal; OS13 now has confirmed reuse with local success-only commitment. Exact source overwrite semantics remain open. |
| SCI-09 | SCI 00:15:00, V | DATA LEFT counts down; firewall active; all data collected; ICE-SAFETY retrieved. | Collection objective, firewall transition and named technology completion. DATA LEFT is not necessarily seconds. |
| SCI-10 | SCI 00:21:10, O | WATER CHIP retrieved. | Named research completion, separate from installing a physical water chip. |
| SCI-11 | SCI 00:24:00, V | ADVANCED SCHRIEBMANN'S PORT retrieved; four deck stations visible. | Advanced named technology and multi-seat room; not proof all four can dive concurrently. |
| SCI-12 | OVR 00:27:10, O | Hidden data: PsiBoost Implant, Scan Mk.II, Hack Mk.II. | Software generations and implant discovery. Do not infer all costs/prerequisites. |
| SCI-13 | OVR 00:46:10, O | PSIBOOST IMPLANT installed. | Research/design installation notice; not necessarily surgical implantation in a person. |
| SCI-14 | OVR 00:50:40, O | Hidden data: Outer Comms. | Authored technology/communications catalogue extends beyond generic science levels. |
| SCI-15 | OVR 00:52:00, V | Bright circular blue/white replicator pulse, Harvester nearby, insufficient elerium and empty-content refusals. | Conversion visual and real resource failure branches. Exact animation duration and radiation effect not measured. |
| SCI-16 | SCI 01:10:40, V | Named installation notices, hidden Hand Tele/Energy Gun data, steel 2 / zrbite 46 / elerium 40 display, thrown scrap. | Research progression, storage accounting and physical reclamation overlap. Units must be recovered, not assumed sheets. |
| SCI-17 | SCI 01:22:20, V | Mysterious spore terminates process; hacking detected; database section says locked for 24 hours; later successful Energy Sword retrieval also visible. | Guardian/failure and per-section lockout branch. Scrollback cannot establish that the immediately failed attempt subsequently succeeded. |
| SCI-18 | SCI 01:34:00, V | Blue grid, dark blocks, red squares, white static-like regions, avatar, Scanner and EJECT controls, DATA LEFT and firewall warning. | Exact visual/action surface differs from a generic relay puzzle. Static regions' type/behavior is not proven by nearby advice. |
| SCI-19 | SCI 01:36:20, O | INTENSECURE LIGHT ARMOR retrieved. | Later named catalogue completion. |
| SCI-20 | SCI 01:38:30, O | Hidden data: Assault Vest. | Late progression lead; no exact prerequisite or fabrication outcome established. |

### Named retrieval timeline

These are visibility timestamps from the Productive Science transcript; only
entries marked V above were additionally inspected at full resolution.
Repeated rendering/OCR variants are not separate discoveries.

| Visible time | Named technology |
| --- | --- |
| 00:15:00 | ICE-Safety |
| 00:21:10 | Water Chip |
| 00:24:00 | Advanced Schriebmann's Port |
| 00:41:30 | Improved Solar Panel |
| 00:59:10 | Distress Beacon |
| 01:09:30 | Laser Gun |
| 01:13:40 | Hand Tele |
| 01:15:40 | Energy Gun |
| 01:22:20 | Energy Sword |
| 01:24:20 | PsiBoost+ Implant |
| 01:36:20 | IntenSecure Light Armor |

CAP 01:05:00 additionally directly displays ICE-Pick Mk.I, Battery, Solar
Panel, Elerium Power Cell, Artificial Organ, Scan Mk.I, ICE-Safety, Water Chip,
Improved Solar Panel, ICE-Pick Mk2, Laser Gun, RemCom Device, Advanced
Schriebmann's Port, Stunner, Flamethrower and Stun Rifle.
This is a catalogue snapshot, not proof of that Captain researching or
fabricating every item.

## Advanced Schriebmann's Port product integration

**SCI 00:24:00, V** explicitly shows the Advanced Schriebmann's Port retrieval
notice and nearby dialogue distinguishing the advanced implant from an
advanced cyberdeck. This establishes a separate identity, not a measured
speed, protection, archive-level limit or implantation outcome.

The [OS13 neural-port module](../code/modules/os13/os13_wiki_counseling.dm)
now includes a distinct Advanced Schriebmann's Port internal-organ subtype
and replicator design. It inherits the ordinary port's robotic status, Head
parent, relative size, damage rules and `os13_neural_port` organ tag.
Ordinary and advanced ports therefore occupy the same slot: replacement uses
existing removal, transplantation and attachment rather than stacking ports.

The existing [cyberdeck checks](../code/modules/cyberresearch/cyberdeck.dm)
already accept neural-port subtypes through the authoritative installed-organ
lookup, ownership and usability checks. A held or unattached advanced port
does not provide access. Removal or an unusable port invalidates the active
connection through the existing recall path. Normal port recipes, starting
loadouts, non-OS13 behavior and cyberdeck gameplay are unchanged.

The item reuses the supplied OS13 `neuroimplant` art and OS13 `implantcase`
held art; a distinct advanced sprite has not been established. Data 3,
Biology 3, 2000 steel and 1000 glass are **local fabrication mappings**, not
recovered original costs or the source dialogue's "level 3" rule.
The product currently grants the ordinary working neural connection only.
Advanced effects, source prerequisites and named research-disk retrieval/
installation remain unresolved; a distinct product does not certify them.

Validation: normal command-line Interpost-Hague compilation passed with
**0 errors, 0 warnings**. Item/held DMI states, design discovery, shared organ
tag, duplicate rejection, ownership/usability and active-link recall were
statically inspected. Focused whitespace and report-anchor checks passed.
No unit tests or live Dream Seeker validation were performed.

**Manual checks (not performed):** fabricate both port designs; confirm
advanced item/held art; transplant and attach the advanced port in a portless
Head and boot a seated helmet-wearing operator; reject duplicate installation
when an ordinary port occupies the slot; confirm a held/unattached port
cannot boot; damage or remove the installed port during a dive and verify
recall. Exact source surgery timing and advanced bonuses require more evidence.

## Artificial Eyeball product integration

[Artificial Eyeball](../code/modules/os13/os13_medical.dm) now provides a
fabricatable robotic eye-organ product using the supplied OS13 surgery
`eyeball` item state. This addresses a physical product integration gap,
**not** the still-unimplemented authored discovery tree.

- Full-resolution **SCI 00:10:30** confirms the Artificial Eyeball discovery
  label. It does not demonstrate its physical use, recipe or sight bonuses.
- Uses the existing [eye-organ ancestry](../code/modules/organs/internal/eyes.dm)
  and normal robotization after construction. Damage-induced blur/blindness,
  robotic damage/EMP handling and ordinary surgery remain in the production
  systems. No invented night vision, scanner, immunity or extra flash guard.
- Keeps `BP_EYES`, Head parent, surface accessibility and the existing
  [organ transplant/attachment](../code/modules/surgery/organs_internal.dm)
  path. The current organ system models both eyes as one slot; this product
  therefore replaces that slot, **not** independently selected left/right
  eyeballs. The singular name matches the source technology identity only.
- Robotization restores the OS13 name/icon instead of the generic optical
  sensor/camera asset. No separate broken-eyeball sprite was established;
  organ death retains item art and normal dead/damaged state rather than
  selecting `camera_broken` from a sheet that lacks it.
- The existing eye-colour transfer behavior is inherited. OS13 `implantcase`
  held art, slot model, research levels and material costs are local mappings.
  Ordinary natural eyes, optical sensors and species starting eyes are unchanged.

The source's **Artificial Organ -> Artificial Eyeball** scrollback sequence is
retained as evidence, not encoded as an exclusive dependency without further
review. Fabrication still uses ordinary numeric research requirements. Exact
discovery, media installation, source surgery, eye-colour behavior, individual
eye damage, recipes and vision effects remain unresolved.

Validation: normal command-line Interpost-Hague compilation passed with
**0 errors, 0 warnings**. Sprite metadata, robotization and existing organ/eye
lookup and attachment paths were statically inspected. No unit tests or Dream
Maker IDE. No live Dream Seeker validation has been performed.

Manual checks:

1. Fabricate the design; verify name, OS13 item/hand art and robotic status.
2. Use ordinary Head organ surgery to remove eyes, insert and attach the
   product. Verify duplicate-eye and damaged-product rejections; a merely
   inserted/unattached product must not become the active eye organ.
3. Compare eye-colour transfer, damage blur/blindness and EMP failure with
   existing robotic eyes. Confirm no unimplemented sight/flash bonus appears.
4. Remove/reinstall, kill and re-robotize the product. Art must stay valid;
   natural eyes and other optical sensors retain their normal sprites.

## Current research implementation and actual gaps

### Inspectable technology diskettes

[Technology media](../code/modules/research/research.dm) now exposes a
**Technologies:** examination heading and the actual stored research name and
level. Empty media shows the heading without invented contents, matching the
visually checked **SCI 00:09:50** empty Diskette examination.

A distinct **Diskette** product uses the supplied OS13 `datadisk0` item and
`card-id` hand states, and has a [replicator design](../code/modules/research/designs.dm).
It inherits the existing technology-disk type, so insertion, recording,
confirmed overwrite, R&D import, backup and erasure all use real research
payloads rather than a flavor-only disk. Generic technology disks also gain
the truthful examination readout; their sprites and fabrication remain unchanged.
Cyberdeck completion preserves each OS13 technology diskette's identity label
(including the distinct Core Diskette label) and records its stored technology
and level in the description; generic non-OS13 technology disks retain their
existing research-specific names. R&D erasure restores the OS13 product's
original name/description as well as clearing its payload, so erased media
does not claim to hold an old archive. The R&D console also rejects a copy
request when a disk already contains research; clear the disk explicitly before
replacing its contents. Successful OS13 disk backups keep their identity label
and show the backed-up research and level in the description.

The cyberdeck media panel now shows **Technologies:** with the actual saved
research name and level from the inserted disk. This readout is populated
before the boot/running snapshot branch, so it remains visible during a dive
and stays separate from the pending archive displayed in the session panel.
Blank media shows only the heading; missing media has no contents heading.
Research names are HTML-encoded. This reuses the inspectable-media contract,
not a recovered source console layout.

The Replicator console now shows the actual physical disk name on its main,
contents and backup pages, preserving Diskette/Core Diskette identity rather
than replacing it with a generic media label. On OS13 its technology contents
page also uses the **Technologies:** heading. Stored research name,
description and physical disk labels are HTML-encoded; the backup selection
shows each technology's current local level before copying it.
This is a consistent local readout, not a reconstruction of the source
console's exact layout or named technology catalogue.

Technology and design contents/backup pages return to the main menu if their
required disk has been removed, deleted or moved outside the console.
This avoids dereferencing an empty drive when another operator ejects media
or an old Disk Operations link is reused. Existing handlers still validate
the identity of disks targeted by Import, Copy, Clear and Eject.

Manual console-display checks (not performed): insert blank and recorded
Diskette/Core Diskette media, compare the label and stored research with
physical examination and the cyberdeck media panel, then verify the backup
list level matches the exported recording. Open each technology/design disk
page in two windows, eject media in one and refresh or reuse navigation in
the other: it must return to the main menu without an empty-drive runtime.
Repeat with no disk and with the other disk format inserted. Fresh import,
backup, clear and eject operations should remain functional.
Validation is limited to static inspection and focused whitespace checking;
no compiler, automated tests or in-game checks were run.

Manual checks: compare blank and recorded media against physical examination;
start a recorded-media dive and verify the media panel still shows the old
recording, not the pending reward. EJECT must preserve that recording.
Successful download must show the newly committed technology after refresh;
ejection must remove the contents readout. Import the completed disk at the
Replicator console to confirm normal research transfer remains unchanged.
These checks remain unperformed. Static inspection covered snapshot ordering,
rendering and success/abort writes; no compiler or automated tests were run.

Cyberdeck media-control continuation: Eject Disk links now identify the
displayed physical disk and dive ID. The idle-state handler verifies those
values and that the disk is still inside the console before moving it.
Stale links report a changed disk/session and refresh instead of ejecting
replacement media or media from a later dive. Active dives still prohibit
disk ejection. Inventory-removal failures during insertion now produce an
explicit warning; a disk that cannot be unequipped does not occupy the drive.
These are local integrity rules, not recovered source media-control semantics.

Manual checks: keep an eject link for disk A, replace it with disk B, then use
the old link; B must remain inserted. Repeat after completing a dive with
the same disk; only its fresh eject link should work. Normal fresh ejection
must preserve research for Replicator-console import, and ejection requests
during boot/running must not release reserved media. Try inserting a disk
that cannot be unequipped; verify the warning, unchanged inventory and empty
drive. Static inspection only; no compiler or automated tests were run.

The engine currently stores one research datum per disk. This does **not**
implement the source's multi-technology catalogue, SCAN/ICE-Pick software
installation or arbitrary named-technology payloads. Existing SCAN flavor
disks are not silently relabeled as working research/software media.
The sprite mapping, recipe and numbered level display are local choices.

Validation: normal Interpost-Hague command-line compilation passed with
**0 errors, 0 warnings**. Static inspection covers technology-disk inheritance,
stored-data examination, R&D import/clear and cyberdeck output. No unit tests
or Dream Maker IDE; live comparisons remain unperformed.

Manual checks:

1. Fabricate a Diskette; inspect empty Technologies heading and both hand art.
2. Record a successful cyberdeck archive, examine its actual research/level
   and import it at R&D. Examine it again after erasure: no stale entry.
3. Overwrite recorded media on OS13; examination must reflect only the newly
   committed datum. Failed/aborted dives must retain the previous entry.
4. Compare generic technology disks and component-design disks. Generic tech
   behavior remains; component disks must not be accepted as technology media.

### Recorded-media overwrite integration

[Cyberdeck](../code/modules/cyberresearch/cyberdeck.dm) now accepts a recorded
technology disk **on Alpha/OS13 only**, with the observed warning that its data
may be overwritten. Boot requests explicit Continue/Cancel confirmation.
[The UI](../code/modules/cyberresearch/cyberdeck_ui.dm) enables the recorded-media
boot path and explains the confirmation requirement. Non-OS13 consoles retain
their blank-only policy; missing media still blocks boot everywhere.

Full-resolution **SCI 00:24:00** shows the recorded-disk warning and later
Advanced Schriebmann's Port retrieval in scrollback. It supports moving beyond
unconditional recorded-media refusal, but does not recover exact overwrite
commit timing, original confirmation UI, or every cancellation outcome.

**Local safety semantics:** old disk data, name and description remain until
successful data-core completion replaces them. Cancelling confirmation,
aborting, boot failure, power/link loss and failed dives do not erase the prior
recording. Each dive reserves the exact disk and research-datum identity; a
replacement or externally changed recording invalidates the session. After
confirmation, the console rechecks session identity, power, proximity, physical
interaction, media and archive availability before reserving resources.
Confirmation is per boot, never a reusable authorization for another disk.
The old research datum is not deleted: existing R&D recording conventions do
not establish exclusive ownership of imported media data.

This does not implement multi-technology diskettes, source catalogue edges,
DATA LEFT collection, guardians or an assumed media-less dive rule.

Validation: normal Interpost-Hague command-line compilation passed with
**0 errors, 0 warnings**. Static inspection checks UI/boot/active-link/completion
and cleanup paths. No unit tests or Dream Maker IDE; live verification remains
unperformed.

Manual checks:

1. On OS13 insert recorded media, verify warning and boot availability with an
   eligible technician. Cancel confirmation, eject and import: old data/name
   must remain. On another map, recorded insertion/boot remains refused.
2. Confirm and complete the data core: only then should the disk contain the
   new archive. Import it through ordinary R&D; blank-disk dives stay unchanged.
3. Abort, lose power, break the chair/helmet/port or fail avatar integrity.
   Ejected recorded media must still contain the original research.
4. During confirmation swap/eject the disk, alter its recording, walk away,
   incapacitate the user or have another operator begin and end a dive.
   The stale confirmation must not authorize a new session or overwrite.
5. Replace/modify reserved media during an active dive: it must recall rather
   than write to the new recording. Missing media must still block boot.

### Session-bound emergency recall

On OS13 the console's session button is now labeled **EJECT**, matching the
visible control in SCI 01:34:00 and the avatar action. Other maps retain
**Emergency recall**. Both labels use the same session-bound abort handler.
The media panel explicitly explains the existing success-only write policy:
unfinished dives leave previous research intact. This is local explanatory
text, not recovered source wording or a new overwrite rule. The detailed
saved-research readout is described under inspectable technology diskettes.

The [cyberdeck screen snapshot](../code/modules/cyberresearch/cyberdeck.dm)
now includes the current dive ID. The
[Emergency Recall link](../code/modules/cyberresearch/cyberdeck_ui.dm)
carries that ID, and the console checks it against the active boot/running
session before recalling. Idle, missing-ID and ended-session requests report
the stale control and refresh the screen instead of terminating a later dive.
Boot and cleanup already advance this ID, so a link from an earlier dive
cannot recall its successor.

The avatar's EJECT/Recall action and the existing cleanup/disk-commit rules
are unchanged. This is a local session-integrity correction, not a new
source gameplay rule or authorization mechanism.

Manual checks:

1. Recall a running dive using its current console button: body control,
   chair availability and archive availability must be restored, with no
   pending research written to the disk.
2. Keep a recall link from dive A, finish or abort A, then begin dive B.
   Reuse A's link: B must remain active and the console must show a notice.
3. Use the current recall link during archive generation. Boot must cancel
   through existing cleanup, release its archive slot and preserve the disk.
4. Reuse an old recall link while idle, or omit its session ID. No cleanup
   should run and disk data must remain unchanged.

Validation: static inspection confirms IDs are assigned before the boot
screen is displayed, advanced on cleanup, carried in the rendered link and
checked before recall. Focused `git diff --check` passed. No compiler or
automated tests were run; manual in-game checks remain unperformed.

[Cyberdeck](../code/modules/cyberresearch/cyberdeck.dm) already requires a
conscious seated character, helmet, available mind, eligible chair within
three tiles and, on Alpha, a working surgically installed OS13 port. It has
boot/running/idle state, recall on equipment/link failure, actual avatar
transfer and physical technology-disk output.

[Cyberspace](../code/modules/cyberresearch/cyberspace.dm) now uses OS13-only
open collection fields with ICE islands, ten distributed data points,
DATA LEFT feedback and automatic completion on the last collection.
The [Specialist Stevens audit](os13_specialist_stevens_video_parity.md)
records the supporting footage and explicit local geometry/count choices.
Other maps retain the maze, hexadecimal relays, core download and optional
dead-end red ICE. Red ICE still damages avatar integrity by 20; wrong
non-OS13 relay keys damage it by 10. Those values are local code rules.

| Contract | Current behavior | Gap against recorded evidence |
| --- | --- | --- |
| Research identity | OS13 uses 45 wiki-named, one-time technology unlocks with four archive tiers and reveal dependencies. Other maps retain generic disciplines and level 20 ceiling. | Catalogue effects/products, Core Diskette provisioning and source menu layout are incomplete. Tier conflicts use main wiki table rows. |
| Installed software | Scan requires Mk.I or Mk.II installed through console research; Mk.II recharges 10x faster. The existing [SCAN Diskette](../code/modules/os13/os13_video_objects.dm) now carries importable Scan Mk.I on Alpha. Base ICE-Pick removes nearby nodes/interior ICE, with installed MK2 recharging 10x faster. | Source-local software installation/ownership, roundstart media supply, base ICE-Pick disk provisioning and exact timing/control layout remain incomplete. |
| Scanner control | Alpha Scan highlights visible grid, avatars, archive nodes and Blue ICE within the client's view in a timed client-only snapshot; non-OS13 maps retain relay decryption. | Recorded control layout, detectable/hidden entities, exact styling and absolute timings need recovery. |
| Collection | OS13 collects distributed data, shows DATA LEFT and records the selected named technology on final pickup; other maps retain relays/core. | Exact pickup input/count, trapped data and partial-progress ownership remain unresolved. |
| Firewall | Solid ICE barriers and overall dive deadline `(10 + level)` minutes. | Recorded firewall activation transition and guardian detection/section lockout differ. No source-correct grace period measured. |
| ICE | OS13 uses grid floors, adjacent-click deactivation of interior Blue ICE and distributed red-damage nodes; other maps retain old terrain/dead-end hazards. Removed walls are restored on archive release; outer boundaries stay sealed. | Software installation/cooldowns, red-ICE security escalation, black/unstable ICE and guardians remain incomplete. See the Stevens audit for local reconstruction choices. |
| Missing media | Boot cannot proceed without a tech disk; non-OS13 also requires it blank. | Source displays a warning; whether it permits continuation still unresolved. Preserve uncertainty rather than assume a permissive source rule. |
| Recorded media | OS13 now accepts recorded disks with warning, per-boot confirmation and success-only overwrite; other maps remain blank-only. | Original confirmation/commit/cancellation and multi-technology media semantics still need explicit review. |
| Failure | Recall/avatar damage; blank media stays blank and OS13 recorded media retains its old data until successful completion. | Spore termination and database section's 24-hour lock notice exist in source; actual lock lifetime/brain penalties need recovery. |
| Cooperation | One active dive per console. | Four physical stations and external operator visible; multi-dive limits, monitor/recall authority and seat routing unresolved. |
| Persistence | Local research files but cyberdeck level discovery examines consoles/servers. | Recover exactly what is personal, media-bound, console-local or station-wide before migrating research ownership. |

Do not replace the existing robust transfer/recall infrastructure with fake
chat announcements. Reuse it while changing the authored archive/software
contracts after evidence is sufficient.

### Research import discovery feedback

The shared research refresh now enforces its existing level range of 0–20
on the stored technology's `level` field before evaluating design
prerequisites. Previously it assigned the bounded number to the loop
variable, leaving the actual research unchanged, and evaluated designs
first. Out-of-range corrections are logged. This keeps imported console
research, Replicator requirements and the cyberdeck's existing level ceiling
consistent on non-OS13 maps. The later wiki-only catalogue instead bounds
OS13's installed state to 0/1 and uses a separate archive tier. The original
disk payload is not modified by import:
the correction applies to the console's local technology datum.

Manual checks: import research above level 20 and confirm the local research
viewer and subsequent disk export show level 20; confirm ordinary in-range
imports still unlock the same designs and level-zero secret disciplines
remain undiscovered. Static inspection only; no compiler or automated tests
were run for this correction.

Reinspection of **SCI 00:10:30** confirms named installation and
**Hidden data found on:** notices, including Energy Cell, EMP Grenade,
Improved Solar Panel and Artificial Eyeball.

On OS13, successful [technology imports](../code/modules/research/rdconsole.dm)
now announce each newly available Replicator design by its actual name.
The console compares its known designs immediately before and after the
import and prerequisite refresh. Only newly unlocked designs with a
Replicator fabrication path are reported. Reimporting unchanged or lower
research does not replay discovery notices. If no additional Replicator
design becomes available, the requester receives explicit completion
feedback instead.

The local message is **New replicator design available:**, not the source's
**Hidden data found on:** wording: the current implementation unlocks
fabricatable designs, whereas the source distinguishes named technology
discovery and installation. This does not invent the source's dependency
edges, software payloads or multi-technology disk contents. Non-OS13 import
feedback remains unchanged.

Static inspection covers the successful-import branch, prerequisite refresh,
design-list delta and production-menu filter. No compiler or automated tests
were run. Manual checks remain:

1. Import research that satisfies a new Replicator design's requirements.
   Verify the notice names a design now available in the production menu.
2. Reimport the same or lower research: no repeated unlock notices.
3. Import research unlocking only non-Replicator designs: no false
   Replicator discovery notice.
4. Interrupt import through media removal, power failure or database reset:
   no discovery notices and no newly committed designs.

### OS13 cyberspace grid and EJECT continuation

Reinspection of **SCI 01:34:00 and 01:34:10** confirms blue-grid pathways,
dark block obstacles, pulsing red squares, white static-like regions and
the visible **Scanner** / **EJECT** controls.

On Alpha/OS13, [archive pathways](../code/modules/cyberresearch/cyberspace.dm)
now use the supplied OS13 `mob/mob/HUD/grid.dmi` state `1`, rather than the
legacy black-ICE sprite. Archive nodes use the supplied OS13
`objects/objects/newcyber.dmi` sheet while retaining their existing states
and interaction rules. The blue grid and sprite identities were inspected;
this is not a reconstruction of the source's full terrain behavior.

Alpha archive walls now use the same OS13 sheet's animated `ice` state.
Reinspection of **SCI 01:34:10** and a labelled sprite contact sheet confirms
the purple-bordered dark-block artwork. The previous `beam0` state is a thin
black line, not that block sprite. The `nwall` state is a purple particle
effect and is not used as a substitute. OS13 examination calls these walls
**ICE barrier**, keeping the existing solid obstruction behavior without
claiming to implement the recording's active-firewall transition.

This is an artwork/name substitution only: maze topology, density, opacity,
generation, release and node interactions are unchanged. The turf initializer
applies both at world startup and when reused archives change turf types.
Non-Alpha maps retain the previous wall name, description and `beam0` art.
The six-frame ICE state is reused directly; no custom animation timing or
new sprite has been invented. This does not add destructible ICE or ICE-Pick.

The [avatar](../code/modules/cyberresearch/avatar.dm) exposes **EJECT**
on OS13 using the existing recall path. It returns control to the physical
body, releases the archive and does not commit pending research.
Recall remains a compatibility alias for existing instructions. Other maps
retain their existing verbs and archive artwork.

The later [Specialist Stevens collection reconstruction](os13_specialist_stevens_video_parity.md)
adds OS13 DATA LEFT collection and open ICE-island fields, replacing its
relay/core objective. The later Scan continuation adds partial visible-target
highlighting. Hidden-entity detection, exact source layouts, active-firewall
transitions and guardians remain unimplemented.
Damage values and the success-only disk commit policy remain local choices.
The Abilities-menu action is not the source's custom menu layout.

Validation: sprite-sheet metadata and sampled artwork were inspected against
the recorded grid and EJECT label; code paths were statically reviewed.
No compiler or automated tests were run. Manual in-game checks remain:

1. Boot an OS13 dive: pathways should show the blue grid, with nodes drawn
   from the OS13 sheet. Confirm the collection objective and solid barriers.
2. EJECT before completion: verify body control is restored, the chair and
   archive slot are released, and recorded disk contents are unchanged.
3. Begin another dive after EJECT, complete it, and import the physical
   research disk normally at the Replicator console.
4. On another map, verify the existing artwork and Recall action remain,
   without an added EJECT action.
5. On OS13, inspect archive obstacles for the animated purple-bordered ICE
   blocks and the ICE barrier name. Confirm they still block movement and
   that a second dive after archive release restores the same art. Verify
   non-Alpha archives still use their original wall appearance and name.

## Fabrication, storage and reclamation

These systems are **already substantial implementations**, not wholly missing:

- [Replicator console](../code/modules/research/rdconsole.dm): local research
  holder, nearby device linkage, disk import/export/erase, reset and designs.
  Technology import takes five local seconds and rechecks disk identity,
  location and power before committing. Technology and design imports are
  bound to the local research database that began the operation: resetting
  the database cancels pending imports rather than restoring data into the
  replacement database. Interrupted imports report failure to the requester.
  Insertion uses the inventory unequip contract, like the cyberdeck drive;
  a disk that cannot be removed stays in the inventory and does not occupy
  the console's drive.
- [Shared storage](../code/modules/research/replicator_storage.dm): central
  controller creates west steel, east elerium and south zbrite compartments;
  initially locked, two-second science-authorized toggle, capacity 15 sheets,
  material acceptance and shared consumption. Broken or disconnected
  compartments are unavailable to sheet loading, lock controls, stock totals
  and production. Whole-sheet deposits round down remaining capacity so
  fractional salvage cannot overfill a compartment. Elerium is internally
  plasteel; zbrite is glass. No withdrawal is implemented.
- [Replicator](../code/modules/research/protolathe.dm): queued designs, actual
  materials, stock/lock recheck at completion, physical output, reclamation,
  conversion pulse and radiation.
  Queue admission and build checks reject designs without a fabrication path
  or the Replicator build flag, matching the production menu's filter.
  The console lists the active conversion separately from waiting jobs;
  every waiting job remains removable during production. Invalid queue
  positions are rejected without changing the queue.
  Direct ore intake now uses the guarded inventory unequip contract rather
  than dropping the active hand and forcibly moving the ore. Refused removal
  reports a warning without crediting stock, consuming power or emitting a
  conversion pulse. Full or unavailable matching storage is checked before
  removing ore from the inventory. Existing material mappings, partial
  recovery into remaining capacity, lock behavior and successful conversion
  effects are unchanged.
- [Harvester](../code/modules/mining/os13_mining.dm): powered pickup of eligible
  loose ore/shards/panels and physical unloading.
- [ChargeMaster](../code/game/machinery/chargemaster.dm): precursor conversion
  and refill servicing, including Chemistry family.

**Known differences/unverified choices:** exact original stock units/capacity,
left/right/lower geometry on every mapped installation, sharing/link radius,
Core Diskette provisioning, authored design catalogue, reclaimable item set,
recovery percentage, queue interruption and destruct/reset persistence.
Current single-tech/single-design disk snapshots are not automatically the
source's full technology-media model.

Ore-intake validation is limited to static inspection and focused whitespace
checking; no compiler or automated tests were run. These inventory safeguards
are local correctness rules, not recovered source ore-handling semantics.
Reinspection of **SCI 01:10:40** confirms physical thrown scrap and the
steel/zrbite/elerium readout, but does not establish exact ore yields.

Manual ore-intake checks (not performed):

1. Feed iron, zbrite and elerium ore with matching storage space. Each should
   credit only its existing mapped material, consume the ore, emit the
   conversion pulse and allow waiting production to resume.
2. Try ore that cannot be unequipped. It must remain in the inventory;
   stock, power use and conversion effects must remain unchanged.
3. Fill or disconnect the matching reservoirs and try again. The refusal
   must leave ore held, without consuming it or emitting a pulse.
4. Repeat with an offline, busy or open-panel Replicator. Preserve existing
   refusal behavior. Locked but connected reservoirs should still accept
   ore while withholding their supply from production.

Focused manual checks for queue handling:

### Unavailable blueprints and complete recipe readouts

The Replicator now discards invalid/deleted waiting blueprints with a visible
warning and debug log, advancing the queue revision through the existing
removal helper. Valid jobs still wait for resources in their original order.
If an active blueprint disappears or becomes incompatible during conversion,
completion reports cancellation and clears the active job, production turf
and busy state without consuming feedstock. It does not requeue an invalid
recipe. Existing power, position, panel, lock and stock interruptions still
requeue valid jobs normally; already spent startup power/radiation is not
reversed.

The queue screen labels unavailable entries without dereferencing their
recipe and preserves their real numeric positions for manual removal.
Design-disk contents now show all applicable Replicator/imprinter flags,
OS13 steel/elerium/zbrite material labels and chemical names/quantities.
Amounts are explicitly base recipe units before machine efficiency, not
sheets or the adjusted production price. Legacy `$` display prefixes remain
stripped. Design names are encoded in disk contents and backup listings.

Manual checks (not performed):

1. Invalidate the first waiting blueprint; confirm one rejection notice/log,
   revision change, correct removal-link positions and continuation to the
   next valid job. A valid but understocked job must not be discarded.
2. Invalidate an active blueprint during its three-second conversion.
   Completion must clear busy/active state, consume no feedstock and allow
   another valid job to start. Existing startup effects remain observable.
3. Interrupt a valid job with power loss, a locked supply or insufficient
   stock. It must still return to the queue and resume when conditions allow.
4. Inspect a design disk with a multi-machine design, material and chemical
   requirements. Compare its base costs to the efficiency-adjusted production
   menu; verify elerium/zbrite labels and reagent display names.

These are local reliability and recipe-display corrections, not recovered
source queue rules or exact source units. Focused static inspection and
whitespace validation were performed; no compiler, automated tests or live
in-game checks were run.

The queue now reports why its first waiting job has not started: offline
equipment, an open maintenance panel, a busy machine or insufficient
resources. Resource shortages use the existing material checker, including
material efficiency and only unlocked, connected storage. A Refresh Queue
link updates the readout without changing the queue. These are current
resource amounts, not reservations for later jobs. This supplies truthful
insufficient-material feedback consistent with SCI-15, not the source's
exact wording or stock units.

Chemical shortages now report the missing quantity in reagent units and the
reagent's display name, instead of exposing a reagent type path. The quantity
subtracts actual stored reagent volume from the efficiency-adjusted recipe.
Manual check: partially fill a required reagent, verify the remaining deficit,
then fill the remainder and confirm the shortage disappears. Also verify the
OS13 EJECT console button preserves recorded media when aborting a dive and
other maps retain Emergency recall. These changes were statically inspected;
no compiler or automated tests were run and runtime checks remain outstanding.

1. Queue three compatible designs with adequate unlocked stock. While the
   first converts, remove the first waiting job; the active conversion must
   finish normally and the remaining waiting job must retain its order.
2. Queue a design without sufficient stock. It must remain waiting and
   removable, without claiming to be the active conversion. Verify the
   displayed shortage against unlocked stock, then unlock or load the
   appropriate compartment and confirm production resumes. Check offline
   and open-panel feedback separately; neither may consume materials.
3. Use a zero, fractional or out-of-range queue position. No removal or
   runtime error should occur; the console should report an unavailable entry.
4. Submit a known design intended only for another fabrication machine using
   a direct production link. It must be refused without consuming stock,
   starting a conversion pulse, or entering the queue.
5. Leave a queue window open while production advances, another user changes
   the queue, or the console links to another Replicator. Clicking an old
   Remove link must refresh the queue with a notice and remove nothing.
   Repeat with identical designs queued more than once.

Remove links are bound to the displayed machine and queue revision.
Enqueuing, removing a waiting job, starting a job and requeuing interrupted
production invalidate older links. This prevents a shifted numeric position
from removing a different job, including repeated copies of one design.

These are local implementation consistency checks, not recovered source
queue-interruption semantics. This queue update has only been statically
inspected; no compiler or automated tests were run.

Focused manual checks for disk transfer:

### Displayed production and backup targets

Produce links now identify the displayed Replicator, local research database
and exact design datum. A device relink, database reset or replaced design
invalidates the old request instead of enqueueing it against the new target.
Reclaim links also identify their displayed Replicator; moving the item to
a newly linked platform does not make an old reclaim link valid.

Technology and design backup links now identify the source database and
source datum as well as the destination disk. Technology backups additionally
verify the displayed level, so a newer import cannot silently change what an
old Copy link records. Refresh the backup list to copy the new level.
Normal independent technology snapshots, blank-media requirements, queue
ordering, resource checks, recovery amounts and conversion effects remain
unchanged. These are local action-targeting safeguards, not newly recovered
OS13 rules.

Manual checks (not performed):

1. Leave a production page open, relink to another Replicator, then activate
   old Produce and Reclaim links. Neither machine may start a conversion,
   reclaim an item or gain a waiting job.
2. Reset the database and retry an old Produce or Copy link, including a
   design/technology also available in the reset database. No job should
   be queued and the destination disk should remain blank.
3. Keep a technology backup link open while importing a higher level of that
   technology. The old link should refuse; a refreshed link should create
   an independent snapshot of the newly displayed level.
4. Refresh each interface. Current links should still support production,
   reclamation and technology/design backup and import normally.

Focused static link/handler inspection and whitespace checks passed.
No compiler, automated tests or in-game checks were run.

**Historical file-lock follow-up, now completed:** earlier passes could not
change the Boot handler because of Windows mapped-file error 1224. The
wiki-only catalogue pass above subsequently wired disk/recording, dive-session
and selected-level checks through the Boot link and handler, including
revalidation after overwrite confirmation.

### Disk transfer acceptance

#### Reset confirmation and delayed reports

Reset confirmation now identifies the original local research database and
rechecks power and science access after the prompt. If another reset replaces
that database while confirmation is open, the old confirmation refuses to
erase the replacement. The prompt is explicitly addressed to the requesting
user and has its message/title in the proper order.

Delayed report printing verifies that the console still exists, is powered
and still owns the database that began printing. A reset or power failure
cancels the report with a notice instead of printing replacement data; a
destroyed console emits no paper and never reads its disposed database.
Reports still reflect the current contents of that same database at print
completion, not a frozen request-time snapshot.

Reset/print completion refreshes existing viewers instead of reopening the
interface for the original requester. Delayed navigation changes only apply
while the matching processing screen remains selected. This preserves a
player's navigation away from the operation.

Manual checks (not performed):

- Open reset confirmation in two clients. Complete one reset, then accept the
  other prompt. The replacement database must remain intact and the second
  requester must receive a cancellation notice.
- While confirmation is open, remove console power or lose research access.
  Acceptance must not erase the database. Repeat an ordinary authorized reset.
- Request each report type, then reset or depower the console before paper
  appears. No report may print; the requester must receive a cancellation.
- Destroy the console during either print delay. No callback may dereference
  the deleted console or reopen its UI. Existing printed paper remains paper.
- Print normally with stable data/power. Check detailed and technology reports,
  then repeat while closing the UI or navigating elsewhere; completion must
  not reopen it or force a different page.

These are local asynchronous-data safeguards, not measured OS13 print/reset
timings. Static callback/ownership inspection and focused whitespace checking
were performed; no compiler, automated tests or in-game checks were run.

The Replicator console now releases physically loaded technology and design
disks before parent destruction deletes contained objects. This matches the
cyberdeck's existing physical-media cleanup: console-local research is lost,
but an inserted backup is not deleted simply because its drive is removed.
The local database is explicitly disposed of during cleanup. Disk payloads
are not erased, and a stale drive reference to media already moved elsewhere
cannot relocate it. Blank and recorded media use the same release path.

This is a local lifecycle consistency correction, not evidence of the source
game's explosion or media-survival rules. Parent movable cleanup deletes
remaining contents, so releasing media must happen before that cleanup.
Delayed imports already check console deletion before changing research.

Manual destruction checks (not performed):

- Remove a console containing a recorded technology disk; the disk should
  land at the console's location with its original research/level and remain
  importable at another console. Repeat with blank technology media and
  blank/recorded design media.
- Start an import and remove the console before its delay finishes. The
  disk should survive unchanged; no delayed import may restore the deleted
  database. Existing queued fabrication must not acquire a different recipe.
- Move loaded media out of the console without clearing its drive reference,
  then remove the console. That media must stay at its actual location.
- On deletion of a container or turf as well as the console, ordinary parent
  deletion rules still apply; this is not an indestructibility guarantee.

Focused static inspection covered the disk ownership guards, parent content
deletion, shared drop helper, database reset/cleanup and delayed-import paths.
Whitespace validation passed; no compiler, automated tests or in-game checks
were run. The subsequent wiki-only catalogue pass completed the Boot follow-up.

The cyberdeck's empty-drive UI now describes its existing map-specific media
policy accurately: OS13 permits recorded technology disks with overwrite
confirmation and success-only replacement; other maps still require blank
media. This changes guidance only, not disk admission or download behavior.
Manual check (not performed): open the empty-drive interface on each map
mode, then insert recorded media and verify its existing accept/refuse and
confirmation behavior agrees with that guidance.

1. Begin importing recorded technology, then reset the console before its
   five-second import finishes. The reset database must remain reset, and
   the disk must retain its recording. Repeat with a design disk.
2. Eject or clear the source disk, or remove equipment power during import.
   The console must report interruption without learning the research.
3. Attempt insertion with a disk that cannot be unequipped. It must remain
   in the inventory and the drive must remain available for other media.
4. Import normally after a reset: technology must unlock eligible designs;
   design imports must remain available through their normal build paths.

The disk-transfer update was statically inspected only; no compiler or
automated tests were run, and the in-game checks remain unperformed.

Disk-control consistency continuation:

- Technology ejection and design clear/eject/copy now report missing media
  instead of dereferencing an empty drive after a stale control is clicked.
- Design copying rejects populated media, matching the existing blank-only
  copy menu and technology-copy guard. Clear the blueprint explicitly first.
- A blueprint removed by a research reset is reported as unavailable instead
  of silently presenting an unsuccessful copy as completed.
- Design ejection refreshes the console immediately, as technology ejection
  already does.
- Clear links identify both the displayed physical disk and its recording.
  The handler verifies both identities and that the disk is still inside
  the console before erasure. A stale link cannot erase a replacement disk
  or a different recording on the same disk; it reports the change instead.
  This applies to technology and design media.
- Import, Copy and Eject links now also identify their displayed disk.
  Their handlers reject changed or physically absent media before reading,
  writing or moving it. Import additionally identifies the displayed
  recording, so a link for an earlier payload cannot start importing a
  different recording on the same disk. The existing delayed-import checks
  still protect the interval after a valid import starts.
- An empty technology import and an unavailable technology-copy selection
  now report explicit feedback, matching the corresponding design actions.

Manual identity checks (not performed): for both technology and design
media, retain Import, Copy and Eject links for disk A, replace it with disk B,
and activate each old link. B must remain inserted and unchanged; local
research must not be imported from B by A's old link. Clear and record a new
payload on A, then try its old Import link: the new recording must not be
imported. Fresh controls must still support cyberdeck download, console
import, newly unlocked Replicator production and blank-media backup.
Check empty-drive controls and unavailable copy IDs for explicit notices.
These are local media-targeting safeguards, not recovered source workflow
semantics. Static handler/link inspection and focused whitespace checking
were performed; no compiler, automated tests or in-game checks were run.

Manual checks: eject media and reuse an old eject/clear/copy link; no runtime
error should occur. Copy onto recorded design media; its original blueprint
must remain. Clear it and copy again; normal backup/import must still work.
Reset research before using an old blueprint-copy link; unavailable designs
must be reported without writing media. These are local data-integrity fixes,
not evidence for the source's full technology-media model.

Additional manual erasure checks: open a recorded disk's menu, swap in
another recorded disk, then use the old Clear link. The replacement's data
must remain. Repeat by clearing and recording different research on the same
disk before reusing its old link. Fresh Clear links must still erase the
displayed recording, restore OS13 technology labels and invalidate any
pending import of the erased payload. These checks remain unperformed;
validation of this change is limited to focused static inspection.

The current conversion pulse has a seven-frame animation, blue illumination
and above-lighting rendering. Its radiation field lasts 60 local seconds,
with a high-power three-tile core and weaker tail. The recording confirms a
pulse and nearby radiation concerns, **not these exact dose/radius/duration
values**. Do not tune lethal exposure from a visual similarity alone.

## Genetics evidence and reconstruction

| ID | Source / visible time | Observation | Contract / remaining gap |
| --- | --- | --- | --- |
| GEN-01 | GEN 00:13:10, V | Genetics Console unlock, Clonepod A selected, person in chamber, specialized genetics skill card. | Physical scan/console/pod relationship and lettered selection. |
| GEN-02 | GEN 00:18:40, V | Data combined successfully; Clonepod B selected; insufficient biomatter. | Data mixing is separate from material-backed body growth. |
| GEN-03 | GEN 00:18:50, O | OCR reads Clonepod 3. | Do not create a numeric third pod from an ambiguous OCR label; letter C/other value needs visual verification. |
| GEN-04 | GEN 00:23:00; 00:24:40, O | Clone NOT ready, then ready. | Growth/readiness gates; exact duration and premature release unresolved. |
| GEN-05 | GEN 00:23:30, O | Neural implant procedure on another character. | Genetics and research link through real organs, not only a job label. |
| GEN-06 | GEN 00:28:10, V | Genemod Console, Genetics Chamber, Implanter; severely damaged clone and suspected Space Doze. | Distinct machinery and injuries; does not prove Genemod caused these injuries or disease. |
| GEN-07 | GEN 00:29:00, V | Gene Sequence menu: IF4, IUTA3, LW10, LW18, PID9, QT3, RAC11, RAC16, RAC2; first three prefixed (+). | Authored sequence IDs and installed/selected marker need representation. (+)'s exact meaning is unresolved. |
| GEN-08 | GEN 00:29:00, V | Defect risk 3%; tool-generated hints reference myofibrils, rapid coagulation and rapid tissue healing. | Skill-mediated interpretation/risk feedback; does not establish a complete sequence-to-effect map. |
| GEN-09 | GEN 00:29:30, O | Defect risk 1%. | Risk can vary, but cause/formula not recovered. |
| GEN-10 | MED 00:34:20, V | Named person's GENECODE item. | Genotype media. The character surname Coat is **not a clothing recipe**. |
| GEN-11 | GEN 01:05:00, V | Correctional Apparatus procedure failures, existing subpersonality and new trigger recording. | Genetic clones and psychocorrection have distinct state machines; see [medical audit](os13_extended_medical_audit.md). |
| GEN-12 | GEN 01:12:00, V | Named Clone examined, no pulse, insufficient biomatter; synthetic units operating nearby. | Clone identity, medical vitality and biomass resource must remain separate. |

[Cloning console](../code/game/machinery/computer/cloning.dm) already manages
scanner linkage, records, donor selection and disks.
[Clone pods](../code/game/machinery/cloning.dm) already mix recipient/donor
DNA and grow fresh claimable bodies without automatically transferring the
original mind. Current cycle costs 150 biomass, starts with 450, and accepts
50 per biomass brick. Same-record crosses can randomize mutations; current
appearance and stats include randomized local rules. Power loss ejects the
occupant. These are not recovered original tuning.

[DNA modifier](../code/game/dna/dna_modifier.dm) provides generic buffers and
scanner manipulation. Exact recorded Genemod names, sequence IDs, GENECODE
media and defect-risk feedback were not found in inspected production
genetics sources. **Generic DNA editing is not the recorded Genemod system.**

Required reconstruction:

1. Recover scan output, disk writing/reading, identity/donor combination and
   which data drives appearance versus genotype.
2. Model authored sequences separately from opaque generic structural DNA.
3. Preserve unknown/skill-dependent hints; do not give novice users perfect
   expert identification unless footage supports it.
4. Recover sequence editing, installed markers, defect risk, failure and
   recovery. Do not assign all nine effects from three visible hints.
5. Bind correct lettered pods, readiness and biomass stock to actual bodies.
6. Recover sterile clone naming, mind availability/claiming, training and
   subpersonality separately; duplicate minds must not be inferred from title.

## AI: what is and is not established

PIL 00:12:10 directly shows physical AI and an embodied Lance exchanging items.
PIL 00:13:40 reports HOMUNKULUS-5. GEN's later frames show Lance and DFG700
operating and responding; GEN 01:12:00 shows interactions during a medical/
combat situation. Conversation about core disconnection/reboot and requests
to station AI are **not a visually verified assembly or restoration sequence**.
The Genetics/AI video's title cannot establish the missing construction steps.

[AI core construction](../code/game/machinery/computer/ai_core.dm) already
supports MMI/posibrain insertion, law modules, live AI and latejoinable empty
core. [Station AI](../code/modules/mob/living/silicon/ai/ai.dm) already has
cameras, laws, announcements and normal silicon systems.

Source-specific gaps/unresolved contracts:

- Stationary AI versus embodied homunculus identity and mind ownership.
- Lance/HOMUNKULUS-5 and other units' exact chassis, sprites, equipment and
  operating states; player responses must not become hard-coded NPC dialogue.
- Satellite recovery, physical power/brain/core servicing, reboot and
  connection to station command.
- Command authorization and remote device control, law/loyalty/personality
  model, rank permissions and refusal behavior.
- Synthetic damage, repair, organic diagnostic mismatch, item transfer and
  empty-weapon behavior.

## Manual acceptance and evidence still needed

Compare normal gameplay in Dream Seeker:

- Blank/recorded/missing disks, physical payload, installation, export/reset
  and destruction; verify actual committed data rather than a success string.
- Named research catalogue and dependencies; Scanner/ICE-Pick actions;
  collection, firewall and guardian failure; section lockout and recall.
- Shared locked/unlocked storage, inadequate material, competing queues,
  power interruption, reclamation and conversion/radiation visuals.
- Two distinct parent records, same-parent combination, genotype editing,
  risk feedback, lettered pods, inadequate biomass and incomplete clone.
- Ordinary/advanced neural links, port damage/removal and safe recall.
- Station AI versus homunculus recovery/repair and actual control authority.

Still needed: frame-dense action capture, full popup-menu transcription,
authored technology and genome dependency mapping, exact failure/brain damage,
software generations, effect/audio timings and AI restoration continuity.
No every-frame, all-effects or complete gameplay-parity certification follows
from this ledger.
