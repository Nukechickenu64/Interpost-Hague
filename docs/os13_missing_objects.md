# OS13 missing-object implementation, 2026-11-02

User priority: **objects absent from the code and their actual gameplay**.
This continuation uses the local archive and existing audit; it does not
certify perfect OS13 parity. Original mechanics not established by a recording
remain distinct from explicit local integration choices.

The [weapon and remote-device continuation](os13_weapon_parity.md) additionally
implements NT5, TNC Laser Gun, Advanced FixBoy and RemCom. It also connects
the earlier Distress Beacon design to the current named research catalogue.
The five-group validation below records this first pass; the linked report
records the expanded eleven-group regression and its remaining limitations.

The subsequent [medicine-product continuation](os13_medicine_parity.md) adds
five more missing physical injectors/formulations: Hyperstim, Mnemosine,
Oxivior, Monogreline and Polythesine, with real Chemfab and physiology paths.

The [RAX continuation](os13_rax_parity.md) adds a distinct physical pump
shotgun and buckshot, with observed pump/empty-fire behavior, real projectile
delivery and conservation of the original shells/cases.

The [Heavy Gravpulser continuation](os13_gravpulser_parity.md) adds the
catalogue's missing five-shot, armor-ignoring weapon as a real research-gated
product, with actual projectile impacts, station recharge and uncharged
fabrication. Its original balance and exact visuals remain unverified.

The [Stun Mine continuation](os13_stun_mine_parity.md) adds the missing
carryable single-use research product, with physical deployment, contact
stun, electrical protection and interruptible arming/disarming. Its detailed
interaction sequence and balance remain documented local choices.

## Distress Beacon

**Source:** `Second time pilot and alien return`, **00:02:40**, in
`D:\os13archive`. The full-resolution frame confirms the name, purple/green
ring icon and rescue description. FLT-01/15 also identify neck wear.

New `/obj/item/device/os13_distress_beacon` uses `device.dmi:beacon` and can
be worn on the neck, held, transferred or dropped. Its transmitter can be
switched on/off while held. It is available through a separate four-beacon
cargo order and a Replicator design.

Scout Console **Search for Distress Signals** now discovers these actual
items, alongside the existing registered ruin/SOS signals. Selection rechecks
the operator, console, controller, beacon and navigation state after the
native input dialog. A live beacon supplies its current coordinates; no crew
identity is disclosed by the numbered signal label.

The real Scout can fly to a clear approach near the signal and return home.
The approach requires the complete ship footprint to fit in empty space,
without people, dense objects, loose items or terrain under it. Its landmark
overrides the generic navigation path that can clear/reassign terrain.
Blocked approaches are refused. Plotted coordinates remain fixed through
transit if the beacon moves, is switched off or is destroyed. Temporary
navigation persists while occupied and during the owning flight, including
its emergency return route, then unregisters after departure completes.

**Local choices, not recovered source constants:** initially active
transmitter, explicit held toggle, belt compatibility, unlimited signal
detection range, a twelve-tile approach search, the existing shuttle's travel
time, supply quantity/cost ancestry, fabrication recipe and using the world
sprite in held/neck overlays. Exact source activation, range, ETA, rescue
procedure, wear alignment and electrical requirements remain unverified.
It does not create a vessel or teleport the stranded person aboard.

## Broken Tri-Net Space Helmet

**Source:** `Second time piloting`, **00:20:10**. Full-resolution examination
confirms the distinct **Broken Tri-Net Space Helmet** name and original
Tri-Net description. The supplied item and head sheets contain
`broken_tspacehelmet` artwork.

New `/obj/item/clothing/head/helmet/space/trinet/broken` can be worn and
handled, uses the broken item/head art, has no pressure seal, face coverage,
lamp or radiation/bio protection, and makes an otherwise intact pressure suit
fail the existing complete-kit pressure check. Examination explains the broken
seal. It is mapper/admin-placeable; no unobserved fabrication recipe, initial
stock, damage threshold or repair procedure was introduced.

The loss of protection and lamp is a local broken-equipment integration, not
a measured source coefficient. The source damage/repair chain and exact held
pose remain unresolved. Intact helmets retain their existing behavior.

## Scout deployment required by rescue gameplay

The current Classic DMM has **two** decks. Its stale map configuration listed
the separate eight-deck recreation's levels and excluded deck 1 from station
systems. Classic now lists its actual levels 1 and 2; the reconstruction's
own configuration is separate.

The existing mapped 5 x 7 craft at `(152..156,140..146,1)` is retained.
Thirty-five craft cells now use the station shuttle area expected by the
controller. A stationary home waypoint and an empty-space transit waypoint,
together with the map's existing Space waypoint, complete its native navigation.
The berth uses its existing exterior
catwalk/side doors, without binding Alpha's absent docking-port controller.
The two generic terminals become distinct Scout Controls and Scout Console.

**PIL 00:05:40** confirms four inward-facing passenger seats in addition to the
pilot chair. Four new `/obj/structure/sofa/os13_scout` seats use the supplied
`weapons/objects.dmi:shuttle` art and a separate occupied restraint overlay.
The existing pilot chair remains. An overlapping light is moved to the next
interior row. Exactly **36** cells changed; the other **79,964** cells were
compared with the pre-continuation working map and preserved.

Flight controls now retain their `econtrol2` casing and compose the
`econtrol2_active` indicator separately; the latter is a small animated light,
not a complete console sprite. Power restoration restores console lighting;
broken/unpowered controls do not glow. Authorized first use prints the
recorded unlock line. Local dispatched flights report the real configured
travel ETA. Original ship hull/layout, routes, authentication and ETA formula
are still not source-certified.

## Additional recovered evidence and remaining missing objects

Closer inspection of **MED 00:17:30** supersedes the old four-entry-only menu
description. The visible scrolled Psychocorrectional Console menu includes:

- Trigger (SLEEP), Trigger (PANIC), Trigger (COMBAT).
- Refragment personality.
- Subpersonality Integration (ENGINEER), (MEDIC), (SOLDIER), (PILOT).
- triggerword integration.

The four earlier actions remain visible at **00:16:00**. At **00:18:40**, the
recorded trigger, installation prerequisite, success and duplicate rejection
remain distinct evidence. The [psychocorrection continuation](os13_psychocorrection_parity.md)
now adds the paired physical apparatus/console, real spoken-word recording
and brain-bound SLEEP/PANIC/COMBAT responses, with guarded commitment and
cleanup. A new GEN 01:05:00 inspection shows spoken Sleep followed by the
subject falling over after leaving the apparatus. Subpersonality installation,
control transfer, psi/cognitive procedures and Refragment personality remain
open; no arbitrary specialist skills or lethal implant conflict were added.

Other important absent contracts remain Genemod's authored sequences and
risk/hint rules, Autonurse/Medchamber automation, remaining named medicine
formulations and complete source-specific remote-control contracts. See the
extended inventory and medical/science ledgers. These are remaining work,
not completed features.

## Reproduction and validation

Reference frames are retained under `tmp/os13-parity-20261102/` and can be
re-extracted with `tools/waterchip_video/extract_reference.py` from the local
recordings at the timestamps above. No footage was downloaded.

Static map check:

```powershell
python tools/os13_parity/check_map.py
```

Native regression uses the complete production Classic map and real shuttle
movement, not an alternate transport implementation:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' os13_object_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dreamdaemon.exe' os13_object_regression.dmb -invisible -trusted -close
```

The self-closing world writes `tmp/os13-object-regression.log`. It checks
deployment, console art/power state, passenger/seat transport through transit
and return, inactive/live/deleted signals, people/items/terrain obstruction,
real rescue travel, waypoint lifetime, and intact-versus-broken helmet seals.
Executed results:

- Normal `Interpost-Hague.dme` build: **0 errors, 0 warnings**.
- Focused regression build: **0 errors, 0 warnings**.
- Native full-map regression: **0 failures, 0 new runtimes, 0 startup runtimes**.
  All five check groups completed and the world exited itself.
- Geometry/baseline comparison: passed; exactly 36 cells changed and 79,964
  other cells preserved. Supplied sprite-state metadata checks passed.
- Scoped whitespace checks passed with CRLF accepted as line endings;
  untracked new production/check/report files were inspected separately.

The native log also reports existing unmapped Escape/Supply/Mercenary shuttle
warnings and unavailable local SQL connections. Those are separate deployment
limitations; the cargo catalogue entry does not certify cargo delivery on
Classic. The Replicator design supplies a separate production route.
Dream Seeker visual comparison and original hidden balance remain unverified.
