# TGMC Gun Mechanics Adaptation

## Source

Adapted from TerraGov Marine Corps, revision
`ab9934355ae4c8dfda5b3bd8bbc7a86b054ac238`:

- https://github.com/tgstation/TerraGov-Marine-Corps/blob/ab9934355ae4c8dfda5b3bd8bbc7a86b054ac238/code/modules/projectiles/gun_system.dm
- https://github.com/tgstation/TerraGov-Marine-Corps/blob/ab9934355ae4c8dfda5b3bd8bbc7a86b054ac238/code/modules/projectiles/gun_helpers.dm

Upstream code is licensed under AGPL-3.0. This adaptation uses Hague's existing
gun and projectile types; no TGMC assets, weapon roster, or dependencies are imported.

## Adapted Mechanics

- Firing-state lock prevents overlapping bursts and fire-mode changes mid-burst.
- Every round checks shooter capability, gun location, held state, safety, jam,
  submersion, and target elevation. Embedded weapons remain supported.
- Automatic fire advances the existing accuracy and dispersion tables across
  repeated shots, resetting after a pause.
- Sustained fire builds bounded scatter, which recovers between shots.
- Recent movement and firing unwielded increase handling penalties.
- Unwielded weapons add their existing one-hand penalty to camera recoil.

Scatter values are adapted to Hague's scale, not copied from TGMC's angular units.
Defaults are 0.2 buildup per successful shot, 0.1 recovery per decisecond after
the first, a cap of 3, and a movement modifier of 1. Wielding halves the added
sustained-fire and movement penalties relative to unwielded use.

## Preserved Behavior

Human ranged hits still use `gurps_skill_roll(SKILL_RANGE, modifier)`. Weapon
accuracy, burst accuracy, and the existing aimed-target bonus now feed that
roll. Added handling penalties modify skill-based accuracy rather than adding
random trajectory scatter for humans. Existing trajectory dispersion remains.
GURPS range, heavy-weapon, wielding, jam, and hit-quality logic remains in place.

Existing controls, aiming and reflex entry points, weapon roster, ammunition,
damage values, point-blank multipliers, armor, wounds, and projectile travel
remain unchanged. This is a firing/handling adaptation, not the full TGMC
attachment, heat, ammunition-receiver, or projectile framework.

## Manual In-Game Checks

1. Compare low- and high-ranged-skill shooters using the same gun, range, and
   selected body zone; verify GURPS success margins still determine hits.
2. Aim before firing and compare with unaimed shots. Compare moving, stationary,
   wielded, and unwielded shots without changing ranged skill.
3. Hold automatic fire, pause, and resume. Confirm progressive handling penalties
   and recovery, unchanged release/drag controls, and unchanged ammunition use.
4. During a burst, drop or holster the gun, become incapacitated, or enable its
   safety. Confirm remaining rounds stop and mode changes cannot alter a burst.
5. Check energy, ballistic, embedded RIG, reflex, and point-blank firing. Confirm
   unchanged damage and armor/wound handling with equivalent successful hits.