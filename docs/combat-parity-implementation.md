# Combat parity implementation

Target: full GURPS Third Edition advanced combat, presented through the existing Lifeweb-style HUD, sprites, equipment, wounds and combat prose. This patch is a working melee conversion toward that target. **It is not full advanced-rule or visual parity.** The original video audit remains in [thanati_combat_parity.md](thanati_combat_parity.md).

## Source boundary

The supplied *GURPS Space, Second Edition* identifies Basic Set Third Edition as its rules basis (printed page 3, PDF page 4). The available core cross-check is Steve Jackson Games' October 2001 *GURPS Lite*: [publisher listing](https://warehouse23.com/products/gurps-lite-third-edition), [publisher-authored PDF on a mirror](https://files.spawningpool.net/docs/Vault2.0.-.TTRPG-Gamebooks/GURPS%20Classic/GURPS%20-%20GURPS%20Lite.pdf). Relevant printed pages are 2 for success rolls, 18–20 for equipment/damage, and 24–28 for combat/injury. Lite supports the implemented roll sequence, basic defense formulas, strength rows, weapon expressions, damage-type treatment and two all-out attack choices. It does not establish the complete advanced rules.

The full Third Edition Basic Set was not present among the supplied files. Advanced location penalties, location multipliers, the complete crippling model, feint details and advanced exceptions remain **provisional**, even where their current values resemble other editions. No value has been inferred statistically from the video's animation or combat messages. This implementation does not reproduce rulebook prose.

## Running behavior

`code/modules/GURPS/combat_parity.dm` owns ordinary human-to-human physical melee resolution. The normal item attack entry point, harm-intent unarmed attacks, alternate-hand attacks and kicks call the shared strike procedure. Initial human grabs use the same action gate, attack roll and defense resolver before creating the existing hold object. Bites retain their specialized effects but now respect shared action recovery.

An attack checks current adjacency and z-level, functional anatomy, held item, posture, readiness and action commitment. Legal attempts spend recovery even when they miss. Switching hands, dropping a weapon, selecting another style or repeatedly submitting input cannot create another strike during recovery. The existing three readiness indicators also display the shared commitment.

After the attack roll, an eligible defender chooses the highest available defense; the player's dodge/parry preference breaks ties. Both held weapons have independent parry allowances; a shield supplies block rather than an extra weapon parry. Only a deployed energy shield supplies its shield protection. Facing, disabled hands, readiness, prior defense use and an all-out attack affect eligibility. Defense attempts have per-actor one-second counters. Merely selecting a defensive style does not grant the prepared-defense benefit: right-click commits the action. Weapon parries can injure an unarmed attacker's limb; bare-hand parries distinguish swings from thrusts.

Protection is evaluated for the struck location. Numeric resistance is subtracted once before the injury multiplier; it is not passed through the old percentage-armor path again. Item and clothing profiles live beside the resolver. Existing sword self-use continues to select slash, thrust or bash. Unprofiled items and most existing clothing use explicitly documented conversions below.

Feints store their opponent and result through recovery, then apply once to the follow-up defense. Attack quality comes from the resolved roll margin. Events retain the actual target, weapon, location, roll, outcome, recovery time and, when damage resolves, basic damage, resistance and injury. Combat animation, sounds, armor-stop messages and anatomical effects follow those results.

## Controls and presentation

The existing HUD artwork, body selector, inventory slots, posture sprites and world items remain the presentation surface. Selecting a style now explains its effect in chat.

| Control | Implemented behavior |
|---|---|
| Light | Reduced effective strength; setting extension. |
| Aimed | Higher melee accuracy with longer recovery; setting extension, not firearm Aim. |
| Strong | The damage-focused all-out attack choice. |
| Fury | The accuracy-focused all-out attack choice. |
| Defense | Right-click prepares additional defenses; attacks require another style. |
| Guard | Right-click uses the same prepared-defense action. This is not yet a tactical Wait/riposte. |
| Dual | Right-click attacks with the other hand, subject to off-hand difficulty and shared recovery. It does not grant simultaneous attacks. |
| Feint | Right-click contests the opponent's skill and reserves the result for a follow-up. |
| Kick | Uses selected location, special-action readiness and a balance check after a miss. |
| Grab | Resolves entry before creating the existing location-specific hold. |
| Willpower effort | One active attribute effort; one resource debit; one minute, matching the observed tooltip. |

Location-based injury can produce the reference's arm disability and dropped held item, eye injury, or a failed health check followed by stun/fall. A major injury still stuns when the health check prevents a fall. Existing anatomy and inventory code carries these outcomes into sprites and floor objects. Pulled punches retain nonlethal pain damage. Species natural attacks retain their presentation and a converted content bonus; their former independent random stun/disarm effects do not run on this path.

## Explicit adaptations and incomplete areas

These are implementation choices, not claims about the full advanced rules:

* **Timing and geometry:** authoritative recovery uses deciseconds and per-actor windows in the existing square-grid world. A strike allows one step during its commitment; moving farther consumes the movement window. Successful moves are counted, including outside combat mode, so toggling the mode cannot erase a movement commitment. Force moves and thrown/buckled motion are excluded. There is no initiative-ordered tactical scheduler, hex geometry, diagonal distance conversion, retreat choice, reach-2 weapon mode or queued-input interpolation yet.
* **Attributes and skill:** existing jobs/ranks are converted through the current skill definitions. This is not a replacement of character creation with Third Edition point costs/defaults. Shield skill is now available for learning; the current unarmed skill uses the Brawling damage/parry mapping. Physical handedness defaults to right-handed and remains independent of HUD hand selection. Relevant advantages, ambidexterity/handedness character preferences, visibility modifiers, eye-count modifiers, fencing exceptions and weapon-weight breakage are incomplete.
* **Equipment:** generic knife/sword families, dagger, mace, club, hatchet, staff and makeshift spear have explicit damage expressions. Family inheritance is a content migration, not proof that every named descendant is the corresponding tabletop weapon. The current sword mode supplies damage type; blunt-point exceptions and proper hilt-strike profiles remain to be authored. Unprofiled item force becomes `floor(force / 10)` basic damage. Strength rows outside the verified 5–20 interval are not certified; above 20 uses an explicitly provisional extrapolation.
* **Armor:** mapped breastplates have explicit numeric profiles. Other garments convert their existing melee percentage to resistance by division by ten, then derive passive defense. Resistance adds across layers; passive defense uses the best garment plus an eligible held shield. Mail's impaling treatment and existing wear are retained. This is not full equipment coverage, layered-armor certification, armor gaps, shield damage, force-field or projectile conversion.
* **Anatomy/medicine:** resolved injury converts once to the existing wound scale with `maxHealth / HT`. Legacy random tendon/artery severing, amputation, fracture, internal-damage selection and the separate head-concussion branch are suppressed while applying this melee injury. Explicit location consequences run afterward. Species multipliers, organ capacity, bleeding, pain processing, healing, death and later life processing still belong to the inherited medical system. Full GURPS health, knockdown, consciousness and death behavior is **not implemented** by this conversion.
* **Criticals:** the sourced basic success/critical boundaries are active. A roll of 3 maximizes basic damage; other critical hits bypass defense. Critical misses add recovery, rather than pretending the missing full critical table has been implemented. Missed kicks also check balance.
* **Grappling:** entry and bite recovery are integrated. Hold upgrades, escape, throws, disarm, bite damage, leech feeding and special grapple effects still use existing rules. Ordinary weapon attacks on a held target now use the common targeted strike instead of the old automatic throat/tendon-cut interception. A complete grappling migration must replace those special attacks explicitly.
* **Fatigue:** action costs feed existing fatigue; stamina recovery has one owner. Idle combat no longer receives background fatigue/stamina recovery from `handle_fatigue`. Movement is observed for both clients and NPCs. Existing stamina/fatigue scales and rapid mode toggling are not a full GURPS fatigue/recovery model.
* **Other attacks:** projectiles, thrown items, energy damage, holographic gloves, nonhuman attackers and special item overrides are not converted by the ordinary BRUTE melee entry point. They require mixed-encounter regression coverage before full parity can be claimed.

## Verification

The dedicated project is `combat_parity_regression.dme`. Tests are also included under `UNIT_TEST` in the main project. They create fixtures on an isolated platform, independent of engineering-test helpers.

The eight suites cover:

1. All 216 possible three-die outcomes at skill 10, critical boundaries and sampled strength rows.
2. Real item/unarmed dispatch, weapon swaps, physical off-hand penalties, readiness indicators and adjacency.
3. Shield blocks, improved parry with improved skill, both-weapon parry allowances, rear attacks and prepared-defense commitment.
4. Feint lifetime, opponent-specific defense penalty and one-time consumption.
5. Single resistance subtraction, damage type, medical conversion, arm drop/disability, eye injury and stun without knockdown on a successful major-injury check.
6. Willpower debit/expiration and fatigue/stamina ownership.
7. Actual kick and grab input, miss costs, step limits, posture and cross-level rejection.
8. Style benefits, inactive shields, unbalanced weapon readiness, nonlethal sparring and armed-parry injury to an unarmed attacker.

PowerShell commands from the repository root:

```powershell
& 'C:/Program Files (x86)/BYOND/bin/dm.exe' 'Interpost-Hague.dme'
& 'C:/Program Files (x86)/BYOND/bin/dm.exe' 'combat_parity_regression.dme'
& 'C:/Program Files (x86)/BYOND/bin/dd.exe' 'combat_parity_regression.dmb' -invisible -trusted -close 2>&1 | Tee-Object 'tmp/combat-parity/runtime.log'
python tools/combat_parity/check_runtime.py tmp/combat-parity/runtime.log
```

The log checker requires every named suite, the completed summary and a zero runtime counter, and independently scans the test phase for runtime/error text. It reports startup runtimes separately. The current test map emits a pre-test null object creation from `/obj/random/proc/unit_test_spawn_item`, missing power-link targets and unavailable local SQL warnings. Those startup issues are outside this combat patch and prevent a claim of a clean full-world startup.

Verified on 2026-10-23 with BYOND 516.1688:

* Normal game and focused project: **0 errors, 0 warnings**.
* Focused DreamDaemon run: **all eight suites passed**, runtime counter **0**.
* Independent log scan: **no runtime errors after the suites began**; one startup runtime reported separately.
* Whitespace check for changed tracked combat files: passed, treating the repository's CRLF line endings as valid.

Local execution logs: `tmp/combat-parity/main-compile-final.log`, `tmp/combat-parity/test-compile-final.log`, and `tmp/combat-parity/runtime-final.log`. These generated logs are not required source files.

No interactive BYOND client replay has been verified in this pass. The source and server tests do not establish matching animation cadence, HUD placement, pixel-level appearance, sound, or the video's complete encounter sequence. The remaining acceptance scenarios in the original audit remain open until explicitly tested.
