# Thanati combat: video parity and GURPS rules audit

Analysis date: 23 October 2026. Repository snapshot: `357be8a2cae20a5528901f5cfc0ba15639f9ae65`.

**Decision:** target full GURPS Third Edition, including advanced tactical combat, with Lifeweb's visual presentation. The existing implementation has useful interface, anatomy, and equipment infrastructure, but its principal melee path is not a faithful GURPS rules implementation. Achieving the requested result requires replacing the shared combat resolution and action economy, then driving the existing presentation from those results.

The supplied *GURPS Space, Second Edition* is a supplement for **Basic Set, Third Edition**; its printed page 3 (PDF page 4) says so explicitly. In response to the preference for the more detailed option, this report selects the full advanced system compatible with that book. This is a scope choice, not a claim that an edition number alone measures complexity. Lite is used only to cross-check a small set of core principles. Exact advanced tables still require the full Basic Set text.

**Implementation follow-up:** [combat-parity-implementation.md](combat-parity-implementation.md) records the subsequent code changes, regression coverage and remaining limitations. The findings below describe the audit snapshot, not an assertion that every listed defect remains in the current checkout.

## 1. Evidence and limits

| Source | What was examined | What it establishes |
|---|---|---|
| [Original video](<C:/Users/nukec/Downloads/Lifeweb 3 minutes of pure thanati docker combat - nocco (1080p, h264).mp4>) | Entire 180-second span surveyed through one-second frames, overview sheets, enlarged chat crops, and closer four-frame-per-second sequences around the eye injury and late collapse | Visible actions, persistent conditions, interface, combat messages, movement and equipment changes |
| [Space PDF](<C:/Users/nukec/Videos/archive/os13wiki/Gurps - Space 2nd Edition.pdf>) | Cover, publication/contents/edition statement, selected weapons and armor pages | Edition compatibility and concrete examples of weapon, armor, and force-shield rules; not the complete core combat system |
| [Archived How to Fight](<C:/Users/nukec/Videos/archive/os13wiki/How to Fight - Lifeweb.htm>) | Combat styles, targeting, weapon modes, armor, shields, firearms, grappling | Documented Lifeweb design at archived revision 2988; its version relationship to the recording is unknown |
| [SJ Games' GURPS Lite Third Edition listing](https://warehouse23.com/products/gurps-lite-third-edition) and [SJ Games-authored Lite PDF, October 2001 mirror](https://files.spawningpool.net/docs/Vault2.0.-.TTRPG-Gamebooks/GURPS%20Classic/GURPS%20-%20GURPS%20Lite.pdf) | Basic combat and defense principles, primarily printed pp. 24–28 | Abridged baseline only; not authority for every advanced exception |
| Current repository | Input dispatch, melee, unarmed, ranged, defenses, armor, anatomy, fatigue, HUD and item modes | Static implementation and call-path evidence; not tested gameplay |

The video is 1920×1080, 25 fps, with a container duration of 180.087528 seconds. The source hash and inspection scope are in the [manifest](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/manifest.json). Timestamps below are approximate, generally within one second; persistent chat can show an event after it happened. They are not precise measurements of click intervals or server ticks.

OCR was used as an index and checked against images. Colored combat text was particularly error-prone. Audio was not classified. No game build, unit suite, live client session, latency measurement, or statistical balance trial was performed. No gameplay source was changed by this analysis.

**Evidence labels used here:** observed means visible in this recording; documented means present in the archived wiki; code-confirmed means directly supported by current source; proposed means a design or acceptance criterion. An observed outcome does not prove its hidden formula.

## 2. What the three minutes actually demonstrate

The distinguishing feature is a fight that changes what characters can do. It develops through weapon selection, anatomical targets, armor failure or protection, dropped equipment, impaired movement, grabs, falls and recovery. Its presentation makes those consequences legible through bodies, hands, floor objects and prose. A visually similar exchange of generic damage numbers would miss the important part.

The viewpoint character is strongly identified by the log as Zon Dobbs. Other combatants' messages are interleaved; nearby pistol fire or a grab must not automatically be attributed to the viewpoint player.

| Approximate time | Observed evidence | Parity implication and limit |
|---|---|---|
| 0:00–0:15 | Examination of Cerberus lists a bastard sword, armor, helmet, gorget, shield equipment and an embedded chest arrow. Pain flashes occur during repositioning. | Equipment and existing injuries persist across exchanges. The arrow and wounds predate the inspected action; their cause is unknown. |
| 0:15–0:30 | Movement through dark stone passages and stairs; nearby pushes, pistol firing and empty clicks. | Combat includes other actors and environmental navigation. A text line about firing is not evidence of a player input sequence. |
| About 0:30 | Careful-steps mode announces a defense and aiming benefit. | Movement mode has a tactical meaning beyond animation speed. The exact numeric benefit is not visible. |
| 0:36–0:40 | A chest grab and stick attack on a leg; armor stops damage. Zon attacks a head with a dagger and invokes Tzchernobog. | Localized armor outcomes and supernatural feedback are distinct systems. Prayer text does not establish a specific combat bonus. |
| 0:44–0:47 | Mortus receives dagger head attacks, is stunned/falls, then suffers a right-eye injury. | Head trauma changes the next exchange. Preserve stun, posture and sensory injury as distinct states. See [eye-injury frame](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/00-47-eye-injury.jpg). |
| About 0:48 | Rat's critical failure causes loss of balance during a grab attempt. | Critical mishaps exist in the reference. One event cannot establish the full critical table or its probability. |
| 0:50–0:54 | Prepared-defense message, failed fist attack, torso-grab attempts and repeated dagger torso hits; Pachka throws a kitchen knife. | Attack, defense, grappling and thrown weapons coexist in the same encounter. |
| 0:56–1:00 | Willpower effort menu; tooltip specifies one minute and one active effort. Internal-organ injury and blade withdrawal appear in nearby combat text. | Exact effort duration is directly visible. Weapon embedding/withdrawal and wound consequences need separate state transitions. See [effort frame](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/00-56-willpower.jpg). |
| 1:00–1:14 | Torso injury to Izaak; Cerberus parries with a bastard sword; dagger strikes on Cerberus's torso are stopped by armor. | A parry and an armor stop are different outcomes and must produce different feedback. |
| 1:12–1:19 | Zon dodges, pushes and handles a weapon; a throwing knife strikes Cerberus's torso with blunt-trauma feedback. | Throwing and armored impact belong to the same coherent injury model, even if their attack procedures differ. |
| 1:23–1:25 | Self-examination lists widespread burns, FREEZING arms/hands and no encumbrance; an attempted bite misses. | Ongoing condition information is available. This does not identify the cause of every red flash or establish frostbite. See [condition frame](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/01-24-condition.jpg). |
| 1:30–1:35 | Torso injury, bite attempts, and attacks that hit blood/world objects. | Targeting can select environmental atoms; body targeting and world interaction need clear separation. The misclicks are evidence of the interface, not a rule to imitate mechanically. |
| 1:40–1:49 | Olaus attacks with a shovel and pushes; the log includes misses and swings. | Improvised weapons and non-damaging attempts remain visible. Do not turn every swing into a successful hit. |
| 1:49–1:55 | Zon targets Olaus's right arm; tendon injury is reported; shovel drops; further arm attacks precede surrender. | This is the clearest sequence linking anatomical injury, loss of equipment and a changed tactical outcome. See [arm-injury frame](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/01-54-arm-injury.jpg). |
| About 2:02 | Zon raises a medium shield. | Shield readiness is presented as an action/state. The recording does not then prove a successful shield block. |
| 2:07–2:18 | Right-arm attacks on Cerberus, blunt-trauma feedback, crawling/retching; another pair struggle and bite. | Multiple injury and grapple states can overlap. Do not infer a one-to-one relationship between all symptoms and the last hit. |
| 2:24–2:26 | Izaak grabs Eschefalt's chest and throws him. | Grabs have follow-up actions and positional consequences. |
| 2:30–2:34 | Repeated stair transitions, reach failures and a dagger strike on stairs; Zon falls and drops the dagger amid severe right-arm pain. | Reach and posture restrictions matter; hand loss must affect actual inventory and future actions. |
| 2:36–2:43 | A throat bite, impairment messages, inability to reach a body part, further falling/crawling and eventual standing. | Incapacitation is not necessarily death or permanent stun. Recovery transitions are part of parity. See [collapse frame](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/02-39-collapse.jpg). |
| 2:45–2:50 | Tiredness, some pain relief and another character's seizure. | Persistent conditions evolve while combat continues; causes remain partly hidden. |
| 2:52–3:00 | Bronze mace attacks the face, facial destruction is reported, a target becomes Unknown, then stun/fall and skull-injury text appear. | Different weapon/target combinations have distinct consequences. Identity loss may follow facial injury, but the clip alone cannot prove that rule. No explicit death line supports a kill count. See [late mace frame](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/02-58-mace.jpg). |

**Do not derive** attack accuracy, damage dice, maximum health, poison identity, kill count, server speed, input bindings, or a general time-to-kill from this sample. A spoken accusation about poisoned knives is character dialogue, not diagnostic evidence. Repeated pain flashes occur without matching new attacks and cannot be counted as hits.

## 3. Visual and interaction contract

![The reference interface and willpower menu at approximately 0:56](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/thanati_combat_parity/00-56-willpower.jpg)

At this resolution, equipment and action controls occupy roughly the left 11% of the screen; the world occupies the central region; a narrow condition/targeting rail sits beside it; statistics and a large scrolling log occupy the right. These proportions are approximate observations, not fixed requirements for every display size.

| Surface | Preserve from the reference | Required connection to simulation |
|---|---|---|
| World rendering | Small directional pixel sprites, dim occluded interiors, persistent blood, floor items, stairs and tight passages | Visibility, position, collision and weapon reach must agree. Decorative darkness must not conceal an otherwise authoritative hit without a defined perception rule. |
| Equipment rail | Visible hands, equipment slots, active-hand selection and immediate dropped-item feedback | A hand icon must represent the item actually usable by that hand. Injury, grabbing and readiness must affect this state. |
| Combat controls | Compact combat toggle, target selector, style selector, defense preference and movement mode | Controls select legal actions/preferences. A decorative selection must not imply a benefit absent from resolution. |
| Body/condition rail | Anatomical selection and separate condition/posture feedback | Selected target, actual struck location and injured location are distinct data. A fall or crippled hand must alter both sprite and available actions. |
| Readiness indicators | Small persistent indicators near the world | Show authoritative action/hand recovery, including weapon swaps. They cannot be separate timers that attacks ignore. |
| Combat log | Colored narrative outcomes with actor, item, body part and consequence | Distinguish miss, defense, armor stop, penetrating injury, impaired limb, drop, fall and recovery. Names should reflect what the observer can identify. |
| Pain feedback | Red screen tint and short disruption, alongside local pain messages | An existing wound can generate pain feedback; new-hit feedback should come from a new-hit event. Do not infer extra mechanical stun from every flash. |
| Sound | Weapon, impact, defense, fall and item-drop event categories | Existing source has suitable sound hooks, but the reference audio has not been assessed. Audio parity remains unverified. |

The existing OS13 HUD already provides many of these surfaces. [HUD styles](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/_onclick/hud/screen_objects_alt.dm:278) include Aimed, Strong, Defense, Fury, Weak, Guard, Dual and Feint. Existing sword [attack modes](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/game/objects/items/weapons/material/swords.dm:31) cycle slash, stab and hilt bash. These are valuable foundations, not evidence that their mechanical meanings match the video or GURPS.

The architectural requirement is simple: **one resolved event must drive the prose, body condition, held item, posture and visual effect.** Otherwise the game can say “throat” while injuring another location, show a ready hand that cannot act, or play a defensive animation without an actual defense.

## 4. Rules target and edition boundary

The following compact baseline paraphrases the SJ Games-authored [Third Edition Lite text](https://files.spawningpool.net/docs/Vault2.0.-.TTRPG-Gamebooks/GURPS%20Classic/GURPS%20-%20GURPS%20Lite.pdf), printed pp. 24–28:

> Combat uses one-second turns and maneuver choices. Normal attacks resolve an effective-skill roll on 3d6, an eligible defense, then damage. Weapon readiness matters. Dodge derives from Move; Block normally uses half Shield skill; most weapon Parries use half skill, with exceptions. Passive Defense contributes separately from Damage Resistance. All-Out Attack sacrifices active defenses until the next turn. All-Out Defense has its own defense permissions. Injury, shock, stun, knockdown and unconsciousness are different effects. Advanced combat uses a hex map.

That is a baseline, not an exhaustive specification. The publisher labels Lite an [abridgment](https://warehouse23.com/products/gurps-lite-third-edition). Full advanced location penalties, critical tables, reach/facing details, contested maneuvers and special cases must be transcribed and checked from the intended Basic Set printing before claiming complete compliance.

The supplied Space book independently makes the armor problem concrete: printed pp. 61–63 distinguish PD, DR, coverage, damage-type exceptions and force-shield behavior. Printed p. 56 sends ordinary medieval melee equipment back to the Basic Set. It cannot fill the missing core tables by itself.

Use three explicitly named content layers:

1. **GURPS Third Edition core and advanced combat:** the authoritative resolver and rule tables, with a source/page for every nontrivial exception.
2. **Selected Third Edition supplements:** specific equipment or optional combat modules, enabled and documented individually. Complexity should come from supported interacting rules, not accumulating unrelated random penalties.
3. **Lifeweb setting and presentation:** prayer, the shown willpower-effort resource, supernatural traits, special shield behavior, social surrender and narrative injury descriptions. These can coexist with the rules, but must be identified as additions where no matching rule has been established.

Do not silently substitute later-edition formulas. Do not treat a wiki's named combat style as a tabletop maneuver just because their names sound similar. In particular, the wiki's aimed melee strike, Fury, maximum-damage Strong attack, approach-triggered Guard and spendable willpower pool need explicit mappings or extension status.

## 5. Current implementation: where parity breaks

The existing [Deathweb port document](C:/Users/nukec/Documents/GitHub/Interpost-Hague/docs/deathweb-port.md:1) already describes a partial integration retaining Hague's anatomy and several older combat actions. This audit confirms that boundary. Its historical compilation statement is not a new validation result; some behavioral claims also need revision in light of the call paths below.

### A. Main melee attacks bypass the shared 3d6 attack resolver — critical

There is a real [3d6 utility](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/stats_skills.dm:74), with margins and critical flags. However, ordinary human weapon attacks use [percentage-based location selection](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:264), calling [deathweb_hit_zone](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/deathweb.dm:248). A failed location roll either misses completely or selects another location. This is not simply a different implementation of the same probability model.

For example, with the torso's 7% base failure and no other modifiers, the helper produces a complete miss only half of that time: **3.5%**. Some of the remaining outcomes hit a different location. This is a helper-level calculation before defenses, not an estimate of the video's accuracy.

For comparison, enumerating all 216 equally likely 3d6 outcomes gives these raw roll-under probabilities:

| Target | 8 | 10 | 12 | 14 | 16 |
|---|---:|---:|---:|---:|---:|
| Roll ≤ target | 25.93% | 50.00% | 74.07% | 90.74% | 98.15% |

These are mathematical probabilities, before separate critical handling or defense. A skill-point modifier cannot be replaced with a fixed percentage-point modifier while preserving this curve. Feeding every ordinary attack through the same effective-skill resolver is a foundational requirement.

### B. Weapon specialization reduces parry chance — concrete defect

[deathweb_specialty_modifier](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/deathweb.dm:214) returns a negative value because it reduces an attack's miss chance. [Parry](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/deathweb.dm:257) adds that same value to its success chance. Better specialization therefore makes this defense worse.

Holding the other inputs fixed, a combat-ready defender with general melee rank 5, low stamina loss and a weapon block value of 20 has a computed chance of 53% at specialty rank 0 and 3% at specialty rank 5. This is a deterministic reading of the formula, not a measured runtime frequency. Repairing the sign would fix the inversion but would still leave the non-GURPS percentage defense model.

### C. Ordinary melee does not call the shield or prepared-block path — critical

The ordinary human resolver checks dodge or parry and then proceeds to the injury location. It does not call either [check_shields](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:251) or [try_guard_block](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:41). The projectile handler does call the shield path, and some special attacks use prepared blocking.

Consequently, merely holding or raising a shield does not establish normal melee Block behavior. This finding is specific to the examined path; it does not mean every shield in every situation is inert. Shield handlers also use their own percentage values rather than a unified defense model.

### D. Feint expires before the ordinary follow-up — concrete defect

A successful [feint](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:63) expires after 6 deciseconds but sets the default attack cooldown of 8. With ordinary click cooldown enforcement, it is already expired before the next normal attack. Separately, its penalty is consumed by dodge and prepared guard, but not by the main parry routine—the defense the archived wiki particularly associates with feinting.

[Right-click dispatch](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/_onclick/click.dm:52) also occurs before the normal `canClick` gate. Individual actions have inconsistent checks. This needs one action-validation policy; adjusting a duration alone would not repair the whole contract.

### E. Action timing is split between item, hand and click timers — critical

[Weapon attack](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/_onclick/item_attack.dm:55) checks an item-specific cooldown, sets a click cooldown, and later updates a hand-readiness timer. It does not use the hand timer as its attack eligibility check. Unarmed combat does consult hand readiness.

This creates a potential swap-to-another-item route around the intended recovery state, subject to the remaining click gate. The source does not justify claiming a tested exploit, but it does prove different authority for different attack paths. The HUD can therefore display a hand state that does not govern the next weapon attack.

Movement is separately calculated in [human_movement](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_movement.dm:18). Neither a weapon's delay nor a fast movement setting is a substitute for an explicit maneuver/action budget.

### F. Several named styles do not deliver their implied effects — high

In the ordinary weapon path:

| Style | Current source effect | Gap |
|---|---|---|
| Aimed | Adds 4 deciseconds to click cooldown | No corresponding accuracy or chosen-location bonus appears in this resolver. |
| Strong | Adds 7 stamina loss | No corresponding strong damage increase appears in this resolver. |
| Fury/Quick | Reduces click cooldown by 4 deciseconds | Item `weapon_speed_delay` remains unchanged, so the slower gate can still dominate. No matching defense penalty appears here. |
| Weak | Reduces [combat_strength](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/stats_skills.dm:162) by 1 | A small strength adjustment is not a guarantee of a safe sparring blow. |
| Dual | Calls the inactive-hand item's attack | No explicit offhand accuracy penalty in [this action](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:79). |
| Guard | Short prepared-block state and a parry-triggered riposte elsewhere | Does not match the wiki's approach-triggered attack as a complete action model. |

Other subsystems, such as mouth grabs, have additional style effects. The conclusions above concern ordinary weapon strikes, not every use of these constants in the repository. Each style needs a written rule contract before further tuning.

### G. Armor categories replace penetration, and cutting can take the wrong branch — critical

[Melee armor](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/deathweb.dm:355) selects a covering garment by armor category. A sharp weapon against positive, undamaged non-cloth protection generally returns a complete block. This can produce categorical immunity where the target needs a numeric damage-versus-protection calculation.

The code checks `sharp` before `edge`. Ordinary swords in slash mode have both flags, so they enter the sharp branch rather than the later edge-specific treatment. The existence of a cutting branch therefore does not prove cutting weapons reach it.

On a partial block, [human weapon effects](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:354) subtract armor from force and then pass the blocked percentage onward; [apply_damage](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_damage.dm:384) applies percentage mitigation too. That is two mitigation stages. It must not be mistaken for verified PD/DR and injury processing. Coverage, layered garments, damage type and armor wear need separate explicit fields.

### H. Damage and injury scale are incompatible with a faithful core — critical

[Weapon force](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/deathweb.dm:219) scales an item's existing force through an accumulating strength adjustment. [Unarmed damage](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/deathweb.dm:241) uses a custom strength-versus-target-health random formula. Neither uses an authoritative equipment damage expression and checked strength table.

Current wounds, arteries, tendons and organs are useful state containers. Their thresholds and chance rolls belong to the inherited medical system. Head hits also pass through a separate [concussion/knockout system](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_damage.dm:442). Replacing only the initial damage number would leave additional injury and incapacitation rules acting afterward.

Before conversion, define one owner for injury, consciousness and limb disability. The anatomy layer should store the resulting injury and support treatment; it must not silently apply a second independent combat model. Avoid converting tabletop injury to an arbitrary multiplier of legacy health while still describing that as exact parity.

### I. Dodge, facing and defense eligibility are inconsistent — high

[Dodge](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/combat.dm:44) really rolls 3d6, but against capped DX plus custom modifiers. Parry uses a percentage. Prepared guard has a facing check; ordinary parry does not visibly check facing, hand readiness or a turn-based defense budget.

The successful dodge calls a random cardinal `step` and returns success without checking whether that step occurred. Avoidance and actual displacement must be distinguishable: a wall-blocked animation cannot be reported as a completed movement. Any retreat/displacement option needs its own eligibility and position result.

### J. Grapples are structurally present but mechanically unverified — high

Grabs are not missing: [human unarmed input](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_attackhand.dm:133), grab objects, mouth holds and follow-up actions already exist. Their attack/escape resolution uses custom rules, including a percentage grab defense.

The video requires arm/chest/mouth holds, escape attempts, throws, bites and posture restrictions. A full conversion must account for occupied hands, maintained holds, reach, resisting opponents, interruption and release. Retaining the existing state machine can save work, but its transitions need to call the chosen rules rather than remain an independent contest system.

### K. Ranged combat is partially integrated, not absent — high

The [Deathweb ranged projectile path](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/projectiles/projectile.dm:212) already calls `gurps_skill_roll` and derives narrative attack quality from its margin. Its distance, wielding and handling adjustments are custom, and another legacy projectile path remains.

Thus “the game never uses 3d6” would be false. The actual problem is that changing weapon or attack type changes the mathematical system. Audit thrown weapons, firearm aim, ammunition, reloading and projectile defense separately before declaring ranged parity. The clip shows examples of these actions, not enough data to fit their parameters.

### L. Fatigue and stamina have conflicting owners — high

[Human life processing](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/life.dm:726) calls both `CheckStamina` and `handle_fatigue`. The latter adds fatigue for movement/combat, then unconditionally subtracts recovery. An upright idle combatant receives +1 and -2 from those portions of the function. At low fatigue it also reduces stamina loss, including in combat.

This conflicts with the broad description of no combat recovery in the port notes. It does not prove every fighting character has net regeneration—attacks and other systems add costs—but it proves recovery is not governed by the documented simple rule. One scheduler must own expenditure, recovery, exhaustion and display.

### M. Several presentation details already diverge — medium, with gameplay implications

* The recorded effort tooltip says one minute; [current effort code](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/GURPS/deathweb.dm:429) uses two minutes. The recorded menu also includes Resist Disgust; this implementation offers only attribute efforts. Treat this as a Lifeweb extension, not an established core GURPS resource.
* Ordinary melee clears attack-quality text rather than computing the descriptive margin used by the reference. Ranged already has a useful implementation pattern.
* [Throat wording](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:320) can be chosen from the requested aim location even when the actual location differs. Log text should use the resolved event.
* Main weapon and unarmed attack animation calls are commented out. Other effects remain; this is not proof that all attacks are visually static. It warrants a live visual check.
* Critical-result helpers exist in [human_defense](C:/Users/nukec/Documents/GitHub/Interpost-Hague/code/modules/mob/living/carbon/human/human_defense.dm:851), but the searched source contains definitions without calls to those helpers. A critical function's existence is not evidence that ordinary attacks use it.

## 6. Mapping the visible controls to detailed combat

The following is a proposed interface contract. Exact rule options must be checked against the chosen books; this is not a claim that every current style is an official maneuver.

| Reference control | Proposed handling |
|---|---|
| Body doll | Select an intended anatomical target. Show its difficulty and whether the held weapon/posture can reach it. Preserve that intent separately from the actual impact. |
| Normal weapon click | Submit a legal attack request using selected hand, weapon mode, target and current action state. Repeated clicks cannot create extra action budget. |
| Weapon self-use | Keep slash/stab/bash where the item supports them; use explicit damage type and reach data for each mode. |
| Aimed melee | Map only to a verified rule option or declare a setting extension. Do not borrow a firearm aim bonus automatically. |
| Strong/Fury | Offer clearly described offensive choices and their costs. Do not maintain a label that only adds stamina loss or shortens an unrelated timer. |
| Defense selector | Store the player's preferred eligible response. Actual defense must depend on the incoming attack and current state. Automatic preference selection is a computer adaptation and should be documented. |
| Guard | Store a trigger, target/area and committed action. A triggered attack must consume that commitment; no free extra riposte loop. |
| Feint | Store opponent-specific contest result and its valid follow-up window in the same action system. |
| Dual | Select the other hand subject to readiness, occupied hands, attack entitlement and checked modifiers. |
| Grab/bite/kick/push | Distinct action requests with their own range, posture, hand and target prerequisites; not generic weapon damage under different text. |
| Sprint/careful steps | Present movement choices while the simulator accounts for their combat costs and restrictions. |
| Willpower/prayer | Setting actions with explicit duration, resource and effect data. Their implementation should not change the definition of core attributes implicitly. |

Preserve compact controls in the normal screen. Detailed explanations can live in tooltips and inspection; the player should not need to read a debugging trace to choose an attack.

## 7. Real-time presentation without an inconsistent action economy

The main design tension is genuine: the reference looks continuously interactive, while the chosen rules organize combat into discrete decisions. Animation can be continuous; unrestricted actions cannot be called exact tabletop behavior merely because they eventually roll 3d6.

For the strict profile, use a server-authoritative combat scheduler with deterministic ordering and explicit action windows. Inputs select or queue the next eligible action. Movement and animation can interpolate between authoritative positions. Resolve ties, interrupted actions and defense commitments consistently. Record the adaptation in the rules profile.

Do not start by building a generic cooldown framework and hoping it reproduces the intended rules. The scheduler must represent what the rules authorize, including multi-part actions and equipment readiness. A separate real-time variant is possible, but its timing differences should be named rather than hidden.

The map also needs an explicit decision. The current world uses BYOND's tile geometry; advanced GURPS geometry cannot be assumed equivalent. A hidden tactical coordinate layer is one option. A documented square-grid conversion is another, but it is an adaptation and will need facing, diagonal distance, reach and obstacle fixtures. Merely drawing hex-shaped floor art does not solve this.

Stairs need special attention because the clip repeatedly crosses them. At action resolution, confirm current level, reachable path, facing and target position. A target seen before a stair transition should not remain attackable through stale adjacency. World-object targeting can remain available without silently turning a queued body attack into a strike at blood or stairs.

Suggested processing order:

```mermaid
flowchart LR
    A[Player intent] --> B[Validate action and equipment]
    B --> C[Commit action in scheduler]
    C --> D[Resolve attack and defense]
    D --> E[Resolve protection and injury]
    E --> F[Update authoritative state]
    F --> G[Log, sprite, hands, HUD and effects]
```

Each resolved event should carry actor and target identities, action/rules profile, intended and actual location, weapon/mode, roll inputs and outcomes, defense used, protection result, final injury, status changes, item drops and before/after positions. Keep detailed rolls available to tests or an optional inspection view; normal combat prose can remain concise and atmospheric.

## 8. Anatomy, persistence and equipment: the conversion boundary

The most reusable parts of Hague are the world objects, inventory, equipment art, body organs, medical interactions and existing HUD. The least safe parts to preserve unchanged are the numeric combat assumptions embedded inside them.

For each organ effect, decide whether it is a mechanically significant rule, a setting extension or purely descriptive presentation. A torn-tendon message cannot be decorative if it forces a weapon drop. Conversely, a severe-sounding message should not independently add disability beyond the injury already resolved.

Persistent conditions need identity and cause: for example, a wound can keep hurting while no new strike occurs. Store the injury, any lasting disability and any temporary impairment separately. This permits the reference's sequence of pain, dropping a dagger, crawling, standing and continuing with another weapon without implementing every symptom as a generic stun timer.

Equipment needs data for attack modes, reach, damage expression/type, required grip, readiness, permitted defenses, protection coverage and wear. Preserve visible sword mode switching. Add any alternative grip only with its actual consequences. A shield held in the wrong or injured hand cannot be represented solely by a flat bonus on the character.

For armor, convert from the existing mixed category/percentage representation once. Do not allow one garment to mean a percentage in one resolver and numeric resistance in another. Make covered locations and exposed gaps explicit. The Space book's varied armor profiles are useful examples of why a single “plate” flag is insufficient.

Medical compatibility must be tested deliberately. Healing an organ should clear only the statuses it can actually repair. Damage from fire, chemicals, falls and nonhuman attackers must enter a declared conversion boundary, not accidentally reuse the old scale and overwhelm the new one.

## 9. Acceptance scenarios

These are proposed tests and live-review scenarios, **not tests run during this audit**. Use deterministic rolls for rule tests; reserve probabilistic trials for checking distributions or balance. Several scenarios recreate the video's causal patterns without claiming to reproduce its unknown random seed.

| Scenario | Required evidence of success |
|---|---|
| Same attack through each input route | Normal click, alternate input and NPC dispatch reach the same legality/resolution path. |
| Skill increase | Improving relevant skill never lowers a defense through a sign error; recorded effective targets match the profile. |
| Attack distribution | Enumerated or seeded rolls match the configured success/critical boundaries. |
| Feint and follow-up | Benefit survives until the intended eligible follow-up, applies to the proper opponent/defense and expires correctly. |
| Shield vs normal melee | A legal block reaches the shield resolver; broken, occupied or unavailable shield state is respected. |
| Facing and multiple attackers | Defense eligibility changes correctly with relative position and prior commitments. |
| Weapon swap during recovery | Inventory changes do not manufacture an additional action or contradict the hand display. |
| Strong/Aimed/Fury selection | Every displayed benefit and cost is represented in the event record; no cost-only phantom style. |
| Cutting/stabbing/bash on one sword | Each mode selects the intended damage/protection treatment. |
| Layered armor and exposed locations | Coverage and damage-type differences are applied once, with explainable intermediate values. |
| Head hit, fall, subsequent eye attack | Separate target, injury, posture and sensory outcomes; no unexplained duplicate knockout from the old backend. |
| Arm injury and shovel drop | Injury affects the correct arm/hand; floor item, HUD and permitted actions agree. |
| Grip, throw, escape and bite | Holds occupy appropriate resources, follow-up legality is enforced, and leaving reach resolves the hold consistently. |
| Prone attacker reaches too high | Rejected before damage; log and action cost follow the chosen rule contract. |
| Dodge adjacent to a wall | Avoidance and attempted displacement are reported accurately; blocked movement does not fabricate a new position. |
| Stairs during a queued attack | No cross-level stale hit, duplicate action or unintended object substitution. |
| Pistol fire, empty chamber, reload | Ammunition and readiness change exactly once and every attack uses the selected ranged profile. |
| Thrown blade | Item leaves the hand, follows the actual path, resolves protection, then lands or embeds consistently. |
| Fatigue over repeated exchanges | One accounting system explains costs, recovery and exhaustion; switching combat mode cannot bypass it. |
| Willpower effort | If retained to match the clip, one active effort, one resource debit, one-minute duration and synchronized HUD expiration. |
| Facial injury and identity | Recognition behavior follows an explicit observer rule; a name change is not assumed from visual gore alone. |
| Repeated pain without a new hit | Persistent wound feedback does not create additional damage or repeat an old attack event. |
| Network delay and repeat clicks | Extra packets cannot add actions; server results and displayed readiness converge. |
| Existing medical/environmental systems | Treatment, species, burns and other damage sources remain on declared scales. |
| Visual replay | Compare hands, posture, body state, log and floor objects in the eye/arm/collapse/mace sequences; assess audio separately. |

A successful build establishes syntax and integration only. Deterministic rule checks establish the tested mechanics. A live client review establishes interaction and presentation. Those are separate milestones.

## 10. Recommended implementation order

1. **Freeze the rules profile and provenance.** Acquire/check the full Third Edition advanced tables, choose optional modules explicitly, define geometry and real-time adaptation, and list Lifeweb extensions. This is the remaining source requirement for exact rules certification.
2. **Create one combat action and resolution boundary.** Centralize legality, timing, readiness, skill results and defense eligibility. Route ordinary melee, unarmed and NPC attacks through it before expanding content.
3. **Convert defenses and protection.** Eliminate the parry inversion, connect shield defenses, replace the feint timing split and migrate armor to unambiguous fields. Address these as part of the shared model rather than unrelated tuning patches.
4. **Convert injury and persistent state.** Connect anatomical targets, incapacitation, drops and recovery to one authoritative result. Remove or explicitly classify duplicate inherited effects.
5. **Bring in ranged, grappling and equipment exceptions.** Preserve their existing assets and useful state containers while converting resolution. Validate mixed encounters, not only isolated duels.
6. **Finish the reference presentation.** Drive style feedback, descriptive combat text, hand indicators, posture, pain and sound from events. Recreate the five most informative sequences: head/eye injury, armored torso attacks, arm injury/disarm, collapse/recovery and the mace transition.

There is no defensible single percentage for “parity” from this evidence. Many surface features are present, but several central mechanics have different mathematical meanings and some named controls do not deliver their promised effects. The correct completion standard is a source-backed rules matrix, passing scenario checks and a live visual comparison—not a count of icons or similarly named procedures.

**Assessment:** preserve and finish the Lifeweb presentation; replace the inconsistent combat authority underneath it. The video/current-code analysis is complete to the stated inspection scope. Full advanced GURPS compliance remains unverified until the missing core rules are checked and the resulting implementation is tested.
