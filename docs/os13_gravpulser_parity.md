# Heavy Gravpulser physical product

This continuation adds a previously missing physical Heavy Gravpulser,
its gravsphere projectile and its named-technology Replicator design.
**Exact original weapon behavior and visual parity remain unverified.**

## Evidence boundary

The archived Scientific Overseer catalogue, transcribed in the
[science audit](os13_extended_science_audit.md#research-evidence-ledger),
names **Heavy Gravpulser**, revealed from **Gravcutter**, and its later
**Mag-Pulse Gun** reveal. The existing named technology description in
`code/modules/research/research.dm` specifies an armor-ignoring weapon with
a five-shot battery. This product implements that recorded local catalogue
contract; no additional reveal edge or free technology grant was introduced.

The inspected ALIEN **01:19:40–01:19:50** scrollback contains actual
**gravsphere** hits. Frames are retained in `tmp/os13-rax-continuation/alien`.
They support the projectile vocabulary, **not proof that the shooter used a
Heavy Gravpulser**, the exact ammunition source, damage, recoil, impact effect
or a five-shot depletion sequence. The five-shot/armor-bypass specification
comes from the current catalogue contract, not an invented reading of those
frames.

## Functional implementation

`/obj/item/weapon/gun/energy/os13_heavy_gravpulser` is a real energy weapon.
Each successful shot consumes one fifth of its actual battery and launches
`/obj/item/projectile/energy/os13_gravsphere`. A full battery permits exactly
five shots; a sixth produces the ordinary empty-fire response. Insufficient
charge is not partially consumed. The weapon does not self-recharge and
requires held ownership/capability through the standard firing checks.

The moving projectile uses the existing collision and damage framework.
Its conventional armor bypass uses the standard 100 armor-penetration
boundary and no conventional armor category for internal-hit calculations.
Real human body damage therefore is not reduced by ordinary protective
clothing. Shields, terrain and other existing interception paths remain in
use. Armor bypass does not make the projectile pass through dense walls.
No new ignition, forced throw, dismemberment or area blast was inferred.

The fixed internal battery can be restored at the ordinary powered station
weapon recharger. An unpowered charger provides no charge. Recharging and
retrieval use the actual weapon and cell, not a replacement object. Standard
loose cells are not interchangeable with this reconstruction's fixed battery;
the original replacement/compatibility protocol remains unknown.

The named **Heavy Gravpulser** technology unlocks its physical design.
Learning Gravcutter alone reveals the technology without granting the new
gun. Fabrication creates an **uncharged** five-shot battery, so the Replicator
does not create stored electrical energy. No cargo route bypassing this
named research gate was added.

## Local reconstruction choices

These values and assets are not certified original OS13 constants:

- 25 BRUTE damage, inherited internal-injury behavior, no new stun/throw
  effect, existing non-hitscan movement and ordinary wall/shield collision.
- 500 internal charge units, 100 per shot, fixed-battery handling, standard
  station-recharger servicing and inherited recharge rate.
- Weapon size/back storage, force 10, one-hand penalty 3, inherited accuracy,
  firing delay/recoil and the existing `pulse3.ogg` firing sound.
- Fabrication recipe of 3,000 wall-material and 1,000 glass units.
- Supplied `gun.dmi:gravrifle` / `gravrifle_empty` world states and matching
  `gravrifle` left/right-hand states. Ready art requires enough charge for an
  actual shot. A missing battery also renders empty.
- Supplied `projectiles.dmi:pulse` projectile artwork. This is a candidate
  gravsphere representation, not a frame-verified projectile sprite match.

The original remaining-charge presentation, battery servicing, target
resistance, sound, damage and artwork alignment still need direct comparison.
This item does not turn the separate Gravcutter or Mag-Pulse Gun into aliases.

## Validation

Four groups in `tools/os13_parity/gravpulser_regression.dm` exercise:

1. Actual five-shot firing, projectile delivery, depletion, insufficient
   charge and absence of self-recharge.
2. Standard recharger insertion/power/retrieval, refused inventory release,
   incompatible cells and missing-battery handling.
3. Actual armored/unarmored human impacts, an ordinary bullet blocked by the
   comparison armor, and a dense wall stopping a fired gravsphere.
4. The named research gate and physically uncharged Replicator output.

Only the physical target records incoming projectiles; gun firing, energy,
charger servicing, body damage and armor checks use production code.

Executed with BYOND 516.1688 on 2026-11-02:

- Production `Interpost-Hague.dme`: **0 errors, 0 warnings**.
- Focused `os13_object_regression.dme`: **0 errors, 0 warnings**.
- Native complete-map regression: **all 27 groups completed, 0 failures,
  0 new runtimes, 0 startup runtimes**. The world exited itself. Log:
  `tmp/os13-object-regression.log`.
- Scoped source/report whitespace and final log-integrity checks passed.

Reproduce:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' os13_object_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' os13_object_regression.dmb -invisible -trusted -close
```

Existing unmapped Escape/Supply/Mercenary warnings and unavailable SQL
connections remain separate deployment limitations. No running user world
was restarted to load the production DMB. Live Dream Seeker and original
source-specific balance verification remain open. This pass does not finish
Genemod, subpersonality possession, automated medicine or all other OS13 gaps.
