# Deathweb Mechanics Port

## Status

This is an integrated partial port, not a complete faithful replacement of Hague
with Deathweb. The normal Hague project compiles with the port enabled. Runtime
behavior has not been verified in-game.

Existing sprites, sounds, jobs, species, item types, and the current organ backend
are retained. In particular, the existing local pain and concussion changes have
not been replaced. No Git history merge, asset import, or upstream content-pack
import was performed.

## Source

- Repository: https://github.com/Near-Web/Deathweb
- Revision: `d264167e57357ce9fc5aa43c631dc13bb0f0c1f3` (`master`).
- License: GNU Affero General Public License version 3, matching Hague's
  `LICENSE.txt`. Upstream attribution and license obligations still apply.
- Main source references: `code/modules/gurps/GURPS.dm`,
  `code/modules/mob/living/carbon/human/skills.dm`, `skills_stats.dm`,
  `stat_mods.dm`, `combat_procs.dm`, `combat_comicao.dm`,
  `human_attackhand.dm`, `human_defense_rework.dm`,
  `code/modules/mob/living/armor_new.dm`, and the projectile modules.

## Implemented

- Shared 3d6 roll-under resolution, critical thresholds, and success margins.
- Deathweb's 37 skill definitions and stat/specialization defaults, plus Hague's
  science skill. Untrained surgery has no default.
- Whole-number skill ranks, use-based learning up to rank 10, and teaching
  progression. Higher existing content values are not silently clamped.
- Restraint, combat readiness, hunger, thirst, and mood modifiers for skill rolls.
- Nine-or-ten baseline primary attributes for newly created humans, before
  existing character/job setup applies its changes.
- Perception derived from intelligence, immunity derived from health, and
  willpower and speed fields. Speed remains a reserved modifier field, as it is
  in the inspected upstream human code.
- Versioned, named temporary stat modifiers and two-minute willpower efforts.
  `Check Skills` displays effective attributes, ranks, and base roll targets.
- Weapon hit-location accuracy, melee training and weapon specialty modifiers,
  posture and readiness modifiers, and strength-based weapon force.
- Unarmed hit locations, strength-versus-health damage, reduced stamina cost,
  and active defenses without Hague's previous extra random block/miss stack.
- Active dodge and parry rules, defense stamina costs, bare-hand parry injuries,
  grip loss, and guard ripostes with recursion protection.
- Grab-defense chances based on melee training, dexterity, combat mode, and
  existing grabs. Existing grab objects still perform the resulting actions.
- Projectile-impact ranged rolls with distance, wielding, and heavy-gun
  penalties. Gun jamming is conditioned on a failed handling roll.
- Melee armor categories, armor wear, and weapon durability/sharpness wear.
  Full blocks no longer receive a second independent melee armor roll.
- No passive combat-mode stamina drain or recovery. Out-of-combat recovery,
  sprint cost, and a human exhaustion threshold of 120 use the ported rules.

## Integration And Fidelity Gaps

Hague's string identifiers and numeric backing lists remain public compatibility
interfaces. A stored Hague skill value of 70 is read as rank 7. Existing task
callers still pass old requirements: stat checks translate a requirement into
`stat + 10 - requirement`; skill checks apply `(50 - requirement) / 10` to the
native target. These adapters are not a migration of every task caller to
Deathweb's native API.

Existing job skill/stat assignments, explicit stat-generation ranges, traits,
species bonuses, and antagonist content have not been rebalanced against
Deathweb job profiles. New specialist skills are available and learnable, but
all crafting, movement, social, and other noncombat workflows have not been
rewritten to consume those specialist skills.

Existing weapons are mapped to the corresponding specializations where there
is a current equivalent. Items without a mapping use general melee training.
Armor defaults are cloth for clothing, leather for armor suits, and plate for
helmets and spacesuits, with plate overrides for breastplates. Those mappings
need content review; they are not upstream equipment balance data.

Melee armor outcomes are translated into Hague's percentage-blocking damage
interface. Projectile armor still uses Hague's existing armor resolver.
Hague's wound creation, internal damage, pain, concussion, medical treatments,
and advanced grapple state machine remain active. Deathweb's full anatomical
injury backend, immunity consumers, exhaustion-induced heart attacks, specialized
energy-weapon malfunctions, perks, and supernatural exceptions are not ported.

The existing strong, quick, aimed, dual, feint, and guard controls remain. Some
of their Hague-specific actions and cooldown rules are retained rather than
replaced with upstream equivalents. Willpower currently provides stat efforts;
the upstream disgust-resistance and perk-dependent efforts are not included.

## Validation

Validation uses only the normal project compiler and focused static inspection.
No unit tests, isolated harnesses, or Dream Maker IDE are used.

Compile from the Interpost-Hague workspace root:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' 'Interpost-Hague.dme'
```

Manual in-game review still required:

1. Create crew and NPC characters; confirm job/species values, skill lists,
   perception, and willpower in `Check Skills`.
2. Spend willpower, verify only one active effort, and confirm it expires after
   two minutes without interfering with another temporary stat effect.
3. Try unarmed and weapon attacks on standing, prone, buckled, and grabbed
   targets; check actual wound location against the combat message.
4. Exercise dodge, weapon and bare-hand parry, guard ripostes, dual attacks,
   feints, grabs, and grip loss. Check cooldowns and stamina costs.
5. Compare cloth, armor, and helmet hits with sharp and blunt weapons; inspect
   armor degradation and weapon breakage after repeated use.
6. Fire aimed and unaimed shots at close and long range, wield heavy guns,
   and clear jams. Confirm misses continue along the projectile path.
7. Check out-of-combat recovery, resting recovery, sprinting, and exhaustion.
8. Verify use-based learning and spoken teaching, then inspect existing
   surgery, engineering, crafting, and other skill-gated tasks for balance.
9. Confirm existing pain, concussion, medical treatment, and projectile armor
   behavior still works with the changed combat inputs.