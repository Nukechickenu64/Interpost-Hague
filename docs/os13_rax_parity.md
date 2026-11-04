# RAX Shotgun continuation

This continuation adds the missing RAX Shotgun and a physical buckshot
cartridge that launches a real OS13-named pellet projectile. **It does not
certify perfect weapon parity or original numerical balance.**

## Inspected evidence

Source: `Second time pilot and alien return` in `D:\os13archive`.
The inspected full-resolution frames are retained under
`tmp/os13-rax-continuation/alien`.

- **01:18:40–01:19:00:** RAX point-blank firing, repeated pellet-hit messages
  and the target's thick-skin mitigation coexist with TNC laser use by a
  separate person. They are separate weapons.
- **01:19:00:** the visible history includes multiple pellet impacts,
  a failed click, `Lance pumps the RAX Shotgun!`, melee use and the weapon
  falling to the floor. This supports manual action between shots.
- **01:19:20:** further empty clicks and a pump occur before another drop.
  Pumping alone does not replenish ammunition.

These frames establish the identity, pump feedback, pellet ammunition family,
empty-fire behavior and physical transfer/drop. They do not recover calibre,
capacity, exact pellet count, spread, damage, armor coefficients, shell
loading input, malfunction rules or the original weapon sprite assignment.

## Implemented gameplay

`/obj/item/weapon/gun/projectile/shotgun/pump/os13_rax` starts empty. Loading
moves the actual held compatible shell into the tube only if inventory
removal succeeds. Wrong ammunition, remote/floor items, a full tube and
ongoing firing/jam-clearing actions cannot consume a shell or bypass the
ownership check. Stack and magazine conversions are not used by this subtype.

Self-use pumps the action. A tube round cannot be fired until pumped into
the chamber. Each real shot spends the chamber's actual projectile and keeps
its spent case. The next shot requires another pump, which ejects that case
onto the floor and chambers an actual tube round. Cycling a live shell
recovers its original unspent projectile; it does not destroy or duplicate it.
Repeated empty shots/pumps produce no ammunition.

Tube unloading returns one real shell to a free hand or the floor. A chambered
shell is ejected by pumping. Inspection distinguishes tube contents from a
live, spent or empty chamber. The gun's ammunition query counts live
projectiles rather than spent cases, including before the action is cycled.

Existing jam clearing is retained with timed ownership/action revalidation.
Dropping the gun interrupts the attempt, preserves ammunition and releases
the action lock. Successful clearing does not also cycle a shell. Firing,
loading and unloading cannot race the pending clearing action.

The new `/obj/item/ammo_casing/shotgun/pellet/os13` contains an actual
`/obj/item/projectile/bullet/pellet/shotgun/os13`, named **pellet**. It retains
the existing physical projectile/pellet/armor framework; it is not a cosmetic
chat message or an armor-bypassing imitation. Generic shotgun ammunition and
other guns retain their original code paths.

## Availability, art and reconstruction choices

A separate security-locked **RAX Shotguns and buckshot** cargo entry supplies
two unloaded guns and twelve buckshot cartridges. No unsupported RAX research
node or free ammunition fabrication was introduced. The cargo quantities,
stock route and inherited price are local choices. Classic's unmapped Supply
shuttle remains a deployment limitation; a catalogue entry alone does not
certify delivery. Mapper/admin creation of the actual item type also works.

The gun uses supplied `gun.dmi:shotgun` world art and the matching `shotgun`
left/right-hand states. It does not request the generic missing `wshotgun`
held state. These are inspected asset candidates, not a pixel-certified RAX
match. Back-slot/wield alignment and original shell artwork remain unverified.

Inherited compatibility values are explicitly **not recovered source values**:
12-gauge family, four-shell tube plus one chambered shell, acceptance of other
local compatible shotgun shells, six-pellet payload, base damage 25, existing
distance/spread/armor behavior, weapon size/force/accuracy/recoil/fire delay,
one-second pump throttle, four-second jam clearing and existing sounds.
No new source-specific breakage, random malfunction or repair rule is inferred.

## Validation

`tools/os13_parity/rax_regression.dm` adds three native groups to the complete
Classic-map suite:

1. Empty start, actual single-shell loading/unloading and rejected
   wrong/full/unreleasable/dropped ownership cases.
2. Real projectile delivery to a physical target, mandatory manual cycling,
   retained/ejected original spent cases and live-ammunition accounting.
3. Recovery of a live shell, interrupted/completed jam clearing and
   firing/action exclusion without ammunition loss or duplication.

The target records actual incoming projectile types and structure damage;
it does not replace the weapon or projectile simulation. These checks do not
certify original organic target damage or Alien skin protection.

Executed with BYOND 516.1688 on 2026-11-02:

- Production `Interpost-Hague.dme`: **0 errors, 0 warnings**.
- Focused `os13_object_regression.dme`: **0 errors, 0 warnings**.
- Complete-map native regression: **all 23 groups completed, 0 failures,
  0 new runtimes, 0 startup runtimes**. The world exited itself. Log:
  `tmp/os13-object-regression.log`.
- Scoped source/report whitespace and final log-integrity checks passed.
- Supplied shotgun world/left/right-hand state metadata was inspected;
  an existing-asset candidate atlas is retained at
  `tmp/os13-rax-continuation/shotgun-candidates.png`.

Reproduce:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' os13_object_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' os13_object_regression.dmb -invisible -trusted -close
```

The native world retains the existing unmapped Escape/Supply/Mercenary
warnings and unavailable SQL connections. No user world was restarted to
load the production DMB. Dream Seeker comparison and original balance remain
open; this pass does not complete all remaining OS13 systems.
