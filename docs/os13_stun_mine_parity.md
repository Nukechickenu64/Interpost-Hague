# Stun Mine physical product

This continuation adds the missing carryable, research-gated **Stun Mine**.
It does not certify exact original OS13 mine mechanics or visual parity.

## Evidence boundary

The archived named catalogue, transcribed in the existing
[science audit](os13_extended_science_audit.md), lists Stun Mine at tier 2
and its Frag Grenade reveal. The existing named technology description calls
it a **single-use stunning mine**. These establish a named product and role;
they do not establish an observed deployment, trigger or disarming sequence.
No inspected recording establishes its original strength, timing, detection
range, power supply, artwork assignment or spent-casing behavior.

The previous `/obj/effect/mine/stun` is an inherited fixed map hazard using
generic art. It is not the new physical catalogue product and remains separate.

## Gameplay

`/obj/item/device/os13_stun_mine` is a real inventory item. Held self-use
releases the original item onto the operator's floor and starts arming.
Refused inventory release leaves it held and inactive. The floor object also
provides **Arm Stun Mine**. The operator must be capable, adjacent and have
a usable empty hand. Arming requires three uninterrupted seconds on a valid
floor and refuses another living occupant already standing on the tile.
Interrupted arming leaves the same mine inactive and recoverable.

An armed mine is anchored and nonblocking. A living, grounded mover entering
its actual tile discharges it once through the normal stun/pain framework.
The target receives three stun/weakness units and 40 agony units before the
existing physiological and electrical-protection calculations. No blast,
brute damage, toxin payload or owner immunity was introduced. Dead bodies,
loose items, zero-gravity crossings, floating, buckled and thrown movers do
not trigger this reconstruction's pressure-contact detector.

An empty-hand interaction with an armed mine starts a three-second disarm.
Interrupted disarming preserves the armed state. Successful disarming makes
the unused original item recoverable and deployable again. Contact still
works while disarming: a discharge invalidates the pending operation, so its
timer cannot restore the spent mine. A spent casing cannot be rearmed.
Forced relocation cancels arming and disables an armed mine, including when
put inside a container. It does not provide portable or through-container
contact detection. Trigger logging retains the arming operator identity.

The named **Stun Mine** technology unlocks the physical Replicator design.
Fabrication produces an inactive, unused mine. No technology grant, altered
reveal relationship or cargo route bypassing research was added.

## Local reconstruction choices

The interaction sequence, three-second timers, one-tile pressure detection,
gravity and mover filters, resistance behavior, strength, spent casing and
relocation safety are local integration choices. The source does not certify
them. The small item size, empty-hand operation, 1,000 wall-material / 500
glass fabrication recipe and ordinary `Taser.ogg` sound are also local.
The single-discharge assembly has no battery replacement or recharging path;
the original energy or chemical servicing contract remains unknown.

Supplied `grenade.dmi:mine` and `mine1` are candidate inactive/active world
states. Both hand slots explicitly use the same supplied `mine` icon, because
the supplied left/right hand sheets have no mine-specific state. This keeps
the item visible in hand; it is not a verified original held-art assignment
or body alignment. Spent and inactive artwork currently share `mine`.

## Validation

Four native groups in `tools/os13_parity/stun_mine_regression.dm` cover:

1. Named research gating and the actual inactive Replicator product.
2. Physical deployment, refused release, interrupted arming, loose-item,
   zero-gravity and dead-body filters, actual movement onto the mine,
   native stun/weakness and a second victim receiving no second discharge.
3. Interrupted and completed disarming, physical recovery/redeployment,
   forced movement, concurrent-action refusal and contact during disarming.
4. Relocation during arming, storage containment, space-floor refusal and
   actual insulating footwear suppressing electrical effects while spending
   the mine.

The native full-map run also exposed a missing Scout pilot chair at
`(154,144,1)`, causing the existing seated-control check to runtime. The chair
was restored facing its controls. A cell comparison against
`tmp/os13-stun-mine/map-before-chair.dmm` verified exactly that one cell changed;
all other current map cells were preserved. `check_map.py` passes the two-deck,
35-tile craft, five-seat and clear destination-footprint checks.

Executed with BYOND 516.1688 on 2026-11-02:

- Production `Interpost-Hague.dme`: **0 errors, 0 warnings**.
- Focused `os13_object_regression.dme`: **0 errors, 0 warnings**.
- Full-map native regression: **all 31 groups completed, 0 failures,
  0 new runtimes and 0 startup runtimes**. The world exited itself.
- Final log-integrity, scoped whitespace and one-cell map preservation
  checks passed. Native log: `tmp/os13-object-regression.log`.

The existing unmapped Escape/Supply/Mercenary warnings and unavailable SQL
connections remain separate deployment limitations.

Reproduce:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' os13_object_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' os13_object_regression.dmb -invisible -trusted -close
```

The native world exits itself. The production DMB still needs a normal world
restart to be loaded. Live Dream Seeker interaction and direct original-video
mine behavior remain unverified.
