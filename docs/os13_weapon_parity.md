# OS13 weapon and remote-device continuation

This continuation follows the requested priority of missing objects and their
gameplay. It adds four functional products, using the current production
systems and the local archive. **It is not perfect-parity certification.**

## Recorded evidence

| Source | Inspected position | Observation |
| --- | --- | --- |
| Another captain round | 00:00:20–00:00:40 | NT5, its description, opening/closing the cylinder, empty examination and failed fire/click. The shown specimen is damaged. |
| Second time pilot and alien return | 01:18:30–01:19:10 | TNC Laser Gun named in actual firing, point-blank firing and empty-click messages; head hits and incapacitation. RAX Shotgun is a separate dropped/used object. |
| Current archived Scientific Overseer catalogue | Tier 2; reveal edge | Advanced FixBoy provides remote atmospherics access; its research reveals RemCom Device, which provides remote Bridge access. |
| Productive Science / Captain audit | SCI 01:09:30; CAP 01:05:00 | Laser Gun technology retrieval/catalogue. RemCom appears in the Captain catalogue snapshot; that snapshot alone does not prove physical fabrication. |

The full-resolution archive frames for this continuation are retained under
`tmp/os13-new-objects/nt5`, `syrv`, and `encounter`. The atlas in that directory
was made from existing DMI states, without generating replacement artwork.
Source videos remain in `D:\os13archive`.

## NT5

`/obj/item/weapon/gun/projectile/revolver/os13_nt5` is a real revolver, not a
display prop. It starts empty. Activate it while held to open/close its
cylinder. Loading and unloading require an open cylinder; actual firing
requires it closed. Compatible speedloaders transfer their original casings
and remain in the other hand. Individual rounds also load through normal
inventory removal. A non-removable round, wrong calibre, distant/floor item,
full cylinder or active firing action cannot bypass those requirements.

Successful shots use the production firing/projectile path, spend a real
round and retain its spent case in the cylinder. Repeated empty shots do not
create ammunition. Existing hand-drag unloading works with the open-cylinder
guard. Inspection reports cylinder state and live rounds.

The supplied `revolver3` and `revolver3_open0/1/2` body states and matching
left/right hand states provide closed/empty/partial/full visual states.
This family is a reconstruction choice, not a pixel-certified NT5 match.
The source name and description are directly inspected.

**Unverified local compatibility values:** the existing revolver's six .357
chambers, ballistic projectile, firing delay, recoil/accuracy and damage.
The original calibre and capacity were not recovered from these frames.
Partial/full art represents the loaded fraction, not evidence that the source
has six chambers. The damaged specimen's exact malfunction/durability rule
was not invented. A separate security cargo entry supplies unloaded NT5s and
compatible ammunition; issuance, stock quantity and prices are local choices.
No unsourced NT5 research-tree node was added.

## TNC Laser Gun

`/obj/item/weapon/gun/energy/laser/os13_tnc` uses the production laser
projectile/firing path and an actual removable power cell. Each shot consumes
stored energy. Depletion prevents further shots and produces the existing
empty-fire feedback. The supplied `laser100/75/50/25/0` body states reflect
actual charge; `laser_empty` is reserved for a missing cell. OS13 `laser` hand
states are used for both hands.

**Eject Power Cell**, or dragging to a hand control, removes the actual cell.
Inserting a held cell is interruptible and rechecks the gun, cell, ownership,
free bracket and firing state. Inventory-removal refusal cannot install it.
The gun does not self-recharge. Examination without a cell also works; the
shared energy-weapon examination now treats a missing cell as zero shots.

The named **Laser Gun** technology unlocks its physical Replicator design.
Fabricated guns contain an uncharged cell, rather than creating free stored
energy. A separate security cargo entry also exists.

**Local compatibility choices:** the inherited laser projectile, damage,
fire rate, charge cost, initial weapon cell, acceptance of standard cell
subtypes, reload delay, fabrication recipe and cargo stock. Original laser
output, battery compatibility/capacity, recharge procedure, source handheld
alignment and every visual state still need direct comparison.

## Advanced FixBoy

`/obj/item/device/fixboy/advanced` is a separate physical, fabricatable device.
It retains existing FixBoy diagnostics and nearby console-glass repair.
Activation offers the existing station power report or remote atmospherics.

Remote control uses the **actual selected Modcon** and its existing native
dialogue/command path: individual/all vents, REFILL/STOP/FILTER, manual
lockdown and automatic lockdown. It does not create a substitute controller
or move the operator beside the target. A session belongs to its operator,
device and controller; another selection cannot redirect its command.

The user must hold the device aboard the station with the target's required
access. Controllers must be station masters, unlocked, built, powered,
unbroken, unshorted and remote-enabled. These are rechecked after selection
and immediately before commitment. Foreign/stale vent references retain the
existing area boundaries. Locking the controller while a mode dialog is open
prevents the pending command from committing. Ordinary local Modcon calls
still require their original proximity/console checks.

The named **Advanced FixBoy** technology unlocks the product. Its existing
reveal edge to RemCom is retained.

**Local choices:** access/lock/remote-enable requirements, station-level range,
native menu routing, recipe and `fixboy2` artwork with the existing multitool
hand mapping. The catalogue establishes the remote-access role, not these
exact original protocol, menu, power, inventory or artwork details.

## RemCom Device

`/obj/item/device/os13_remcom` is a separate physical, fabricatable command
device. It connects to an **actual operational station bridge computer** and
routes supported operations through the same bridge procedures:

- General Report, Today Reports and Approved Documents.
- Approved-document erasure, retaining the existing round-state guard and
  confirmation dialog.
- Scout salvage permission, using the actual station-wide policy.
- Shield coverage/startup/discharge, retaining generator readiness, wire and
  cooldown checks and revalidation after selection.

Every command requires the held device, station presence, the selected live
bridge, power and command credentials or the mapper's explicit access rule.
Dropping the device, losing the card or bridge power revokes pending commands.
Local bridge calls retain their proximity requirement. The default command
access now checks actual Bridge/Captain credentials: `GetAccess()` returns
an entire list and does not take a department-filter parameter. Treating that
list as a Boolean had allowed unrelated cards. The named Scout control helper
had the same mistake and now checks the real Pilot credential. Its touch-range
check now passes the operator as the adjacency neighbor, allowing the actual
pilot chair to be ignored as intended; seated and standing pilots can reach
the controls while their physical reach and credentials remain required.

The named **RemCom Device** technology unlocks the product. No new reveal
edges or free technology grants were added.

**Local reconstruction choices:** supported command subset, station-only
range, command-card policy, native selectors, recipe and the supplied `Pipboy`
item/multitool hand art. Original RemCom art, controls, power/network model
and complete command coverage are not established by the catalogue. Wake,
evacuation and other bridge commands are not silently advertised as remote.

## Integration and validation

The current OS13 Replicator admits only its named-technology catalogue.
Distress Beacon, TNC Laser Gun, Advanced FixBoy and RemCom designs are now
connected to their corresponding technologies. This also repairs the earlier
Distress Beacon design's exclusion from that catalogue. Blank research does
not unlock these products; installing the relevant technology does.

`os13_object_regression.dme` runs the complete Classic map plus native checks
for actual firing, ammunition conservation, cell exhaustion/replacement,
interrupted reloads, technology admission, uncharged fabrication, remote
vent/bridge commands, area boundaries, lost authorization, dropped devices,
power loss and stale dialogs. Existing Scout/rescue/helmet checks also run,
along with seated/standing pilot reach and actual pilot-keycard authorization.

Executed on 2026-11-02 with BYOND 516.1688:

- Production `Interpost-Hague.dme`: **0 errors, 0 warnings**.
- Focused `os13_object_regression.dme`: **0 errors, 0 warnings**.
- Native complete-map regression: **all 11 check groups completed, 0 failures,
  0 new runtimes, 0 startup runtimes**, followed by self-exit. Log:
  `tmp/os13-object-regression.log`.
- Static Classic geometry/baseline check passed: exactly 36 deployment cells
  changed; 79,964 other cells preserved.
- Scoped source whitespace checks passed, accepting CRLF line endings.

The native world reports the existing unmapped Escape/Supply/Mercenary
shuttles and unavailable local SQL connections. Successful cargo catalogue
integration does not certify delivery on Classic. Live Dream Seeker visual
comparison remains unperformed. No running user world was restarted to load
the rebuilt production DMB.

Psychocorrection, Genemod, Autonurse/Medchamber, unimplemented medicines,
source-specific combat balance and remaining ship/map contracts are still
open. A new whole-duration two-minute sampling of the psionic recording
adds reference coverage under `tmp/os13-psychocorrection/overview`; it is not
an every-frame or audio audit and does not establish hidden psychocorrection
effects. No unrelated local reference code was used as proof of OS13 behavior.
