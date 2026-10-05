# Marrow

[This project is NOT dead.]
---
![Coverage](https://img.shields.io/badge/coverage---9999999%25-red.svg)
[![forthebadge](https://forthebadge.com/images/badges/built-with-resentment.svg)](https://forthebadge.com) [![forthebadge](https://forthebadge.com/images/badges/contains-technical-debt.svg)](https://forthebadge.com) [![forinfinityandbyond](https://user-images.githubusercontent.com/5211576/29499758-4efff304-85e6-11e7-8267-62919c3688a9.gif)](https://www.reddit.com/r/SS13/comments/5oplxp/what_is_the_main_problem_with_byond_as_an_engine/dclbu1a)

### LICENSE
The code for Baystation12 is licensed under the [GNU Affero General Public License v3](http://www.gnu.org/licenses/agpl.html), which can be found in full in LICENSE.

Code with a git authorship date prior to `1420675200 +0000` (2015/01/08 00:00) is licensed under the GNU General Public License version 3, which can be found in full in LICENSE-GPL3.txt.

All code where the authorship dates are not prior to `1420675200 +0000` is assumed to be licensed under AGPL v3, if you wish to license under GPL v3 please make this clear in the commit message and any added files.

If you wish to develop and host this codebase in a closed source manner you may use all commits prior to `1420675200 +0000`, which are licensed under GPL v3.  The major change here is that if you host a server using any code licensed under AGPLv3 you are required to provide full source code for your servers users as well including addons and modifications you have made.

See [here](https://www.gnu.org/licenses/why-affero-gpl.html) for more information.

tgui clientside is licensed as a subproject under the MIT license.
Font Awesome font files, used by tgui, are licensed under the SIL Open Font License v1.1
tgui assets are licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

See tgui/LICENSE.md for the MIT license.
See tgui/assets/fonts/SIL-OFL-1.1-LICENSE.md for the SIL Open Font License.

All assets including icons and sound are under a [Creative Commons 3.0 BY-SA license](http://creativecommons.org/licenses/by-sa/3.0/) unless otherwise indicated.

## Floor liquids

Core floor-liquid behavior is adapted from
[Monkestation2.0](https://github.com/Monkestation/Monkestation2.0/tree/70c2e7a08319737901bc8759a518fcc63c0b2b4f/monkestation/code/modules/liquids),
revision `70c2e7a08319737901bc8759a518fcc63c0b2b4f`, modified on 2026-10-05.
The source is AGPLv3. The unmodified `liquid.dmi` and `liquid_overlays.dmi`
sprites from that revision are included as `icons/effects/monke_liquid.dmi`
and `icons/effects/monke_liquid_overlays.dmi`, credited to Monkestation2.0
contributors under CC BY-SA 3.0.

Spilled reagents persist, mix, and spread between passable neighboring floors.
Pools use the upstream depth thresholds, with finite skin-contact doses,
shallow-water evaporation, fuel fires, and depth-dependent movement slowdown.
Storage uses local per-tile reagent holders rather than upstream liquid groups.
Existing mapped floods and oceans retain their original simulation. Upstream
oceans, pumps, drains, floor heights, and plumbing are not included.

Manual in-game checks: spill water and mixed chemicals; confirm color, depth,
and that closed doors and directional windows stop spreading. Scoop samples
with an open beaker on help intent and compare mixture proportions. Mop shallow
pools and wring the saturated mop into a bucket on harm intent. Compare shoes, bare feet,
lying down, and deep-pool exposure. Ignite fuel with a lighter or igniter,
then dilute it with water; confirm fuel is consumed and the fire extinguishes.

## Teaching skills

Human characters can use **Teach** in the IC verbs to choose a skill and
explain it aloud. Less-skilled humans within three visible tiles who hear
and understand the lesson can accept it with **Nod** (or `say *nod`) within
five seconds. Each offer can be accepted only once; expired offers and
teachers who leave range cannot grant progress.

This adapts the teaching and nod-based acceptance mechanics from
[Deathweb](https://github.com/Near-Web/Deathweb), revision
`d264167e57357ce9fc5aa43c631dc13bb0f0c1f3`, specifically
[skills_stats.dm](https://github.com/Near-Web/Deathweb/blob/d264167e57357ce9fc5aa43c631dc13bb0f0c1f3/code/modules/mob/living/carbon/human/skills_stats.dm)
and its human emote handler, under AGPLv3. No upstream assets are included.

Learning uses an IQ-based 3d6 roll, lesson length, and the teacher's skill
advantage. Critical success doubles progress; melee and ranged lessons
grant half progress. Accumulated progress grants up to ten local skill
points, never beyond the teacher's skill or the existing training cap of
70. Local skills and stats remain in place, and automatic learning from
ordinary skill checks remains disabled. Upstream teaching perks, dummy
training, and failure-induced attacks are not imported.

Manual in-game checks:

- Teach a lower-skilled human a nearby lesson, then nod within five seconds.
  Verify successful rolls accumulate progress and eventually improve the skill.
- Nod twice for one lesson, nod after five seconds, or move out of range
  before accepting. Verify no repeated or expired progress is awarded.
- Repeat with deaf, sleeping, unconscious, and language-incompatible
  students; speech blocked by a muzzle or an IC mute must not offer lessons.
- Teach an equal-skilled student and a student at skill 70. Verify neither
  receives progress; a successful increase cannot exceed the teacher's skill.
- Compare combat and noncombat lessons and cancel either input dialog.
  Verify combat progresses more slowly and cancellation does nothing.

## Leech vampire disciplines

The existing Leech antagonist incorporates vampire mechanics adapted from
[Deathweb](https://github.com/Near-Web/Deathweb), revision
`d264167e57357ce9fc5aa43c631dc13bb0f0c1f3`, specifically its
[vampire module](https://github.com/Near-Web/Deathweb/blob/d264167e57357ce9fc5aa43c631dc13bb0f0c1f3/code/modules/mob/living/carbon/human/vampire.dm).
Feeding is adapted from its
[combat rework](https://github.com/Near-Web/Deathweb/blob/d264167e57357ce9fc5aa43c631dc13bb0f0c1f3/code/modules/mob/living/carbon/human/human_defense_rework.dm)
and mood events.
The source is AGPLv3. No upstream sounds or sprites are included in this port.

Leeches retain their objectives, fang feeding, mesmerizing gaze, coffin refuge,
light vulnerability, and Director awakening. They gain +5 IQ while afflicted,
ignore stamina/fatigue, and no longer passively lose blood. Their OS13 stamina bar becomes a red blood
meter with the current percentage in its hover name; ordinary humans retain
the stamina display.

Leeches bypass the happiness system: their mood is always happy, with the
OS13 `pressure-1` icon, no mood-event modifiers, and no mood-driven stress or
sanity crises. Existing stress effects clear on conversion. They hunger and
thirst only for blood, using OS13 `hunger2` when hungry or starving and `hunger0`
when satisfied. Food and water do not satisfy this blood hunger.
Feeding and blood expenditure immediately refresh these HUD states; removing
the role restores ordinary mood and nutrition handling.

Hunger is separate from stored blood. A leech becomes hungry fifteen minutes
after its last completed meal and starving after thirty minutes. A meal is
200 blood consumed across feeding actions. Completing it resets the hunger
clock; blood spent on disciplines does not advance that clock. Resting or
lying in a coffin pauses hunger before starvation, not the starvation deadline.
Blood lost to injury or powers is still real blood loss, and an empty vessel
is still fatal.

Starvation gives the body to a feeding AI. The player's mind remains in the
body while their input is moved to a temporary, immobile spectator with its
camera, sight limits, and hearing tied to that body. The player cannot move,
bite, or use the body's powers during takeover. The AI uses the existing
human NPC mover, pursues nearby non-leech humans or corpses containing blood,
and uses ordinary bite holds. Armor, restraints, missing teeth, inaccessible
targets, and other physical feeding restrictions still apply.

The AI has one minute to consume 200 blood after takeover; partial meals from
before starvation do not count. Success immediately returns the player to
the body, ends hunger, and restores the previous combat intents and fang state.
Failure kills the leech, even if its blood vessel is full. Reconnection cannot
bypass takeover. Death, body deletion, or antagonist removal cleans up the
AI and spectator; deleted bodies release their players as ghosts.

| Discipline | Blood Cost | Effect |
| --- | --- | --- |
| Blood Strength | 50 | +5 ST for 120 seconds, capped at 30 ST |
| Fortitude | 50 | +4 HT for 120 seconds, capped at 30 HT |
| Celerity | 250 | +6 DX and one-third movement delay for 90 seconds |
| Heal | 150 | Rejuvenate a living body without replenishing blood |
| Dead Eyes | None | Toggle eight-tile dark vision and spirit visibility |

Powers require a conscious, capable leech with more blood than their cost.
Strength and Fortitude refresh rather than stack; Celerity cannot be recast
while active. Stat bonuses expire or are removed on de-antagging. The local
skill and personality systems are retained instead of Deathweb's random
unarmed-skill increase and vice reset.

Feeding uses a two-stage mouth hold. The first successful bite with extended
fangs makes a sharp puncture, adding 5 damage to the ordinary bite. Later bite
clicks or the feed control drink up to 40 units immediately, without another
puncture or automatic artery severing. Standing victims and corpses can be
fed upon; fully blocking armor prevents insertion and feeding. Living victims
receive 200 intoxication, a 10-unit stun, and a +15 mood event for fifteen
minutes, unless they are themselves leeches and immune to mood events.
The local mood event does not overwrite their sin event.
Retracting fangs or losing the hold stops feeding. Each drink is limited by
available victim blood, preserves blood data in the amount stored, and
does not siphon other vessel reagents. Unlike the upstream per-victim bitten
flag, fang insertion is tracked on the current hold and must be repeated
after release. No blood is created when the victim has less than 40 left.
Feeding can satisfy hunger with a full vessel: blood that does not fit is
consumed as food rather than stored, without overfilling the vessel.

Bare-handed contact with silver materials or silver coins damages the hand
and forces the item to be dropped; gloves protect against contact. Nearby
atmospheric fire or being on fire causes periodic trembling and dizziness.
These use local material and fire types rather than Deathweb's medieval
fireplace objects. Drained victims still follow the existing delayed leech
conversion path, with revival checked through body and mind state.

Manual in-game checks:

- Convert a human to a leech and back. Verify +5 IQ, ability availability,
  removal of active bonuses, and immediate blood/stamina HUD switching.
- Convert an unhappy human during a sanity crisis. Verify stress/crisis effects
  stop, mood remains `pressure-1` through positive and negative events, and
  ordinary mood handling returns on removal. Recreate the HUD while afflicted.
- Wait fifteen minutes after a completed meal. Verify `hunger2` appears while
  stored blood remains unchanged. Consume 200 blood and verify `hunger0`
  returns, including with a full vessel; ordinary food and water cannot help.
- At thirty minutes, verify control is lost while the camera follows the
  body's eyes. Check movement, powers, inventory input, blindness, darkness,
  hearing, and reconnecting; none should grant player control or ghost vision.
- Leave accessible blood sources nearby. Verify the AI pursues, bites, and
  consumes 200 blood, then restores control and the normal HUD immediately.
  Repeat with an empty source and a source behind a locked door.
- Prevent feeding with confinement or restraints and wait one minute. Verify
  death even with a full vessel or a partial meal. Kill, delete, or de-antag
  the body during takeover and verify the player is not stranded.
- Feed and spend blood with each power. Verify the meter changes immediately,
  no fatigue overlay remains, and insufficient blood prevents activation.
- Bite a standing victim, then drink using both halves of the bite control.
  Verify only the first bite wounds, each drink transfers up to 40 blood,
  and intoxication, stun, and the positive mood event affect a living victim.
  Retract fangs, release the hold, and try fully blocking armor.
- Initiate biting through both the normal bite command and the context menu.
  Repeat on the same victim to feed through the existing hold; repeat on a
  corpse as a leech. Click both the equipped bite icon and its slot background,
  with empty and occupied hands. Verify top/bottom routing uses the 32-pixel
  sprite, the feed icon persists after insertion, and right-click releases
  the hold even in guard intent rather than unequipping or attacking it.
- Feed from a corpse and from a nearly empty victim. Repeat while almost full
  and with non-blood reagents in the victim's vessel; verify blood conservation,
  capacity limits, preserved blood data, and no transfer of other reagents.
- Refresh Strength/Fortitude, wait for expiry, and activate Celerity. Verify
  bonuses do not stack, speed returns to normal, and an old expiry cannot
  cancel a refreshed power or a later antagonist conversion.
- Heal with damaged organs and less than full blood. Verify rejuvenation
  leaves the blood volume at its pre-heal amount minus 150 units.
- Toggle Dead Eyes in darkness near a ghost, including after a life tick and
  while wearing vision equipment; verify ordinary sight returns on removal.
- Handle a silver weapon, sheet, and coin with and without gloves; remove
  gloves while holding silver. Check nearby fire and existing light damage.
- Drain a victim completely and wait one minute; verify the same mind and
  body revive as a leech. Rest in a coffin and check the hunger clock pauses
  before starvation, while an already active starvation deadline cannot pause.

## Equestrian species (admin-only)

Earth Pony, Unicorn, Pegasus, and Thestral are adapted from
[Ponystation13](https://github.com/tiiktaaaliik/Ponystation13), revision
`cbebc7b1488d22983678d5de5c5c6f489c72348b`. They are registered for admin
species changes, but restricted from character creation, saved-character
selection, and full-body prosthetic creation. No jobs or maps spawn them.
Use `set_species("Earth Pony", TRUE)` (or the other species names) on a human
through admin tooling; the second argument applies the default white coat.

Racial modifiers are applied once on top of existing GURPS stats and reapplied
after stat generation, without accumulating on species changes:

| Species | ST | DX | IQ | HT | PER | Signature abilities |
| --- | --- | --- | --- | --- | --- | --- |
| Earth Pony | +2 | 0 | 0 | +2 | 0 | Hind-leg kick; food-assisted recovery |
| Unicorn | 0 | 0 | +2 | -1 | 0 | Ranged telekinesis; floating carried items |
| Pegasus | 0 | +2 | 0 | -1 | 0 | Brief flight; atmospheric zero-gravity maneuvering |
| Thestral | 0 | +1 | 0 | -1 | +2 | Bat-wing flight; fangs; night vision and light sensitivity |

All four speak Ponish as well as Galactic Common, use the upstream Equestrian
name list, and have quadrupedal bodies, manes, tails, hooves, and short-range
telepathic communication. Gloves cannot be equipped. Empty forehooves confer
a movement advantage; carrying items or broken, dislocated, severed, or otherwise
unusable forelegs removes it. Stance checks account for all four legs, with
half-weighted leg/hoof injuries compared with bipedal stance. Unicorns
can float carried items to avoid that penalty. Psychic and flight abilities
use existing GURPS checks and stamina/fatigue, and require healthy organs.
Unicorn horns are temporarily disrupted by EMPs. Non-Earth archetypes have
increased infection susceptibility and share human pathogen compatibility
without being added to the playable-species pool. Animal protein is toxic to all four.

Flight lasts three seconds, costs stamina, and requires at least 84% of a
standard tile's gas amount, independently of its temperature.
It uses the existing table-pass, gravity, falling, and space-movement hooks:
it does not phase through walls or permit vacuum flight. Pegasus flight has
a seven-second cooldown; Thestral flight has a fifteen-second cooldown.
Unicorn telekinesis uses the existing remote grab/interaction system with a
seven-tile line-of-sight range, IQ checks, and stamina costs, without granting
the general telekinesis mutation or unrestricted spoken magic.
Unicorn grips continuously check the held object's visibility, range, anchoring,
and weight; stronger unicorns can lift larger objects. Both moving/throwing a
gripped object and activating it in-hand require focus checks. Maintaining a
grip also costs stamina. Damaged brains/heads, exhaustion, and horn disruption
disable innate psychic abilities. Existing telekinesis mutations retain their
normal range and rules.

Bay's separate surgical hand/foot slots are retained as forehoof/hind-hoof
organs; their pixels are split from the bottom three rows of the source leg
sprites at render time. Severed hooves therefore disappear from the body and
hoof injuries have visible medical HUD silhouettes. Damage remains tracked by
the existing organ, armor, medical HUD, and surgery systems. The separate
hindquarters slot still shares the main body art rather than having a dedicated
sprite or HUD silhouette. Humanoid damage
masks are not drawn on pony bodies. Headgear uses directional pony offsets;
general humanoid clothing has not been comprehensively resprited for quadrupeds.
Robotic and skeletal limbs use existing matching fallback sprites rather than
missing pony-only icon states; these fallbacks are humanoid, not bespoke pony
prosthetic art. Pony-to-pony changes preserve the selected mane, and leaving
the pony species restores the original hair/facial-hair styles. Pony head and
body overlays are rebuilt rather than accumulated on repeated icon updates.
Six Equestrian mane styles are available through appearance/admin tooling.
Sprite and source attribution is in
[ATTRIBUTION.txt](icons/mob/human_races/pony/ATTRIBUTION.txt).

Manual in-game checks:

- Confirm none of the four species appears in character creation.
- Admin-change a human through each archetype and back; verify racial stats,
  anatomy, coat/eye/mane colors, and removal of old abilities. Repeat after
  job/NPC stat generation and organ regeneration.
- Check hoof movement with empty/full hands, broken forelegs, and floating
  unicorn items; verify gloves remain unequippable. Remove a forehoof/hind hoof
  and check the body and medical HUD; compare standing with foreleg and hind-leg
  injuries. Check robotic replacements and skeletal mutations for invisible limbs.
- Use telekinesis and telepathy at and beyond seven tiles and behind walls.
  Damage/remove the relevant organ or EMP a horn; verify powers stop.
  Move a held object behind a wall, beyond range, into a container, or anchor it;
  verify the grip releases. Check in-hand activation, heavy objects, and fatigue.
- Fly over tables/open space and change z-levels in atmosphere; verify landing
  on expiry, exhaustion, wing damage, death, or species change. Try vacuum.
  Try takeoff/kicking while buckled or pinned, and takeoff near the stamina limit.
  Cancel flight, change species, and fly again; old timers must not end new flights.
- Check Earth kicks against armored/blocking targets, food recovery, animal
  protein toxicity, and Thestral vision with and without protective glasses.
  Verify sparring kicks inflict pain instead of brute damage, and customized manes
  survive pony archetype changes without replacing the original non-pony hairstyle.

## Tile atmospheres

Tile atmospheres simulate gas amounts and temperature only. Gas still spreads
between connected rooms and escapes through breaches. Fastmos-style ZAS edges
equalize connected zones in one atmos tick, weighted by their sizes; breaches
equalize with outside gas. Pre-transfer mole-density differences drive wind,
calibrated at 20 C, within seven passable tiles of openings. Loose items and
unprotected mobs can be pulled through breaches, knocked down, and injured by
collisions. Anchoring, buckles, no-slip footwear, and existing weight thresholds
protect against movement. This uses the DM zone engine, not a native DLL.
Too little or too much gas still causes
human pressure damage and HUD warnings, using gas amount at the nominal 20 C
calibration and species-specific tolerances. An intact pressure-proof suit and
helmet protect against this damage; suit breaches progressively reduce that
protection, with 10 breach damage removing it entirely. Internals supply a
breath, not protection from external pressure damage. Breathing too little
gas in a low-gas environment, including vacuum, can still damage and rupture
lungs; an adequate breath from internals prevents this injury.
Breathing, contamination, fire, sound propagation, and atmospheric devices use
gas amounts; temperature remains responsible for heating and cooling effects.
Room monitors and vent controls show mol/tile. A standard tile holds about
104 mol. Legacy map/radio pressure settings are converted to fixed gas targets
at the nominal 20 C calibration, so heating a room does not make vents remove
gas or cooling it make them overfill it.

Pipes and tanks retain internal pressure, pump limits, and rupture mechanics.

Manual in-game checks: breach a full room and verify it drains in one atmos tick
and pulls nearby loose items and unprotected mobs toward the opening, including
around corridor bends. Check knockdowns and impacts against a wall or airlock;
anchored objects, buckled mobs, and no-slip footwear should resist movement.
Open unequal-size rooms to each other and confirm total gas is conserved and
wind goes from more mol/tile to less; equal mol/tile should cause no wind even
at different temperatures. Repeat with a one-tile room and a resealed breach.
Compare vent targets in warm and cold rooms; verify
low oxygen still causes suffocation, heat/cold and fire still hurt, and tank
gauges and pressure limits still work.
Check vacuum and overfilled rooms with and without a sealed suit and helmet,
then repeat with a breached suit (10 breach damage for full exposure) while
using oxygen internals. Confirm pressure damage and HUD warnings occur even
at comfortable body/air temperatures, clear in normal atmosphere, and are
prevented by an intact sealed suit. Heating or cooling the same gas amount
should not change pressure damage; godmode should prevent pressure injury.

## Occupied inventory slots

Occupied equipment, hand, and pocket slot backgrounds rapidly pulse dark, with a
0.1-second cycle. Emptying a slot stops the pulse and restores its original HUD
color. Item sprites and inventory interactions are unchanged.

## Custom cursor

The custom map cursor is the client default. Gun safety, holstering, dropping a
gun, and leaving a combat mech restore it instead of the system cursor.
Gun targeting, attack feedback, and combat mech cursors retain their existing
behavior.

Manual in-game checks: toggle gun safety, holster and drop guns, and enter/exit
a combat mech. Verify the custom cursor returns whenever a special cursor ends,
including after reconnecting or changing bodies.

## Crate collision

Crates remain solid when opened, so walking into an open crate is blocked just
as it is for a closed crate. Ordinary closets and lockers are unchanged.

## Crawlspace appearances

Crawlspace turfs use [newmaintenance.dmi](icons/turf/flooring/newmaintenance.dmi).
The base `/turf/simulated/open/crawlspace` uses `hh`. Available subtypes are:

- `/maintenance`: wiring that automatically connects to cardinally adjacent wired
  crawlspaces, choosing straight runs, corners, T-junctions, or hubs. Connections
  refresh when tiles are placed or replaced. Isolated tiles use the hub sprite;
  single-neighbor tiles use a straight run because the sheet has no end caps.
- `/hatch`: the vent hatch (the empty icon state).
- `/panel`: the divided panel (`hhh`).
- `/panel/plain`: the plain panel (`h2`).
- `/panel/directional`: the directional hatch/panel variants (`h`); set `dir` in
  the map to select the desired variant.

All retain the existing crawl-only entry and open-space behavior. Their own
sprites remain visible instead of being overwritten by the level below.

## Closed-eye tile awareness

The eye button in the awake HUD closes or opens your eyes. While awake with eyes
closed, nearby map interactions and bumping into obstacles briefly reveal a blue,
glowing symbol from [blind.dmi](icons/mob/screen/blind.dmi) on the touched tile, visible only
to you. Each tile has at most one symbol; recognized objects take priority over
unknown objects, and all objects take priority over turf. Symbols disappear after
three seconds, refresh on another interaction, and clear when you reopen your
eyes, become incapacitated, or log out. Inventory clicks and ranged interactions
do not reveal tiles.

## Cryopods

Cryogenic freezers use the layered sprites in [os13.dmi](icons/obj/machines/os13.dmi):
the bed (`cryochamber0`), the occupant, the front rim (`cryochamber0c`), and the
lid. The occupant is shown lying at 45 degrees inside the pod, clipped to the
pod's outline, and stays visible through the glass windows. When someone enters, the lid
plays its closing animation and settles on `cryochamber1`. When they leave or are
despawned, it opens again (`cryopod_opening` / `cryopod_open`) while the lower
glass lid slides down toward the feet, and the occupant is only let out once the
animation finishes. Latejoiners
spawn in an already-closed pod. SOUTH/WEST pods have the headrest at the upper
left, and NORTH/EAST pods are mirrored. Robotic storage and life pods keep their
old sprites.

Cryopods dispense a temporary ID access card when a joining crewmember leaves
their pod. The card displays their role (including alternate titles) and grants
their job's configured access. It is equipped in an empty ID slot, otherwise
placed in a free hand or dropped beside the pod; existing IDs are not replaced.
The card is dissolving in the air and disappears three minutes after dispensing,
even if stored or handed to someone else. Returning to cryosleep does not issue
another card.

## Admin testing: Mid-round job spawn

Admins can test how any job spawns mid-round using the new verb:

- Admin > Test Job Latejoin

What it does:
- Prompts you to pick a job and then runs the standard latejoin flow (same as a normal player joining mid-round), including spawnpoint selection, job equipment, custom items, records, and mode hooks.

Usage tips:
- Best used while you are a ghost or in the lobby. If you are in a normal body, the verb will prompt to ghost you first.
- This does not bypass normal blockers (e.g., round ended, administrative join lock). If a job is unavailable, the spawn will fail and you will be restored to your previous mob.

## Competing cults: religion foundation

The Paradise cult port is being adapted in stages. Its three theme identities
come from [Paradise](https://github.com/ParadiseSS13/Paradise), reference revision
`44060b61f407ed10043502cbb39cc6518e0a20b6`.

Blood (Nar-Sie), fire (Kha'Rin), and death (Mortality/The Reaper) now have
independent antagonist controllers, factions, religions, progression, sacrifices,
objectives, and teleport networks. Their admin antagonist IDs are `cultist`,
`cultist_fire`, and `cultist_death`. Selecting one of these religions retains the
existing independent 1-in-20 spawn-time role roll; an unsuccessful roll restores
Atheism. Existing cult members do not roll again.

Legacy runes, soulstones, construct shells, artificer summons, and summoned gods
carry their creating cult's ownership. Rival cultists cannot invoke one another's
runes, contribute to rituals, receive communion, repair constructs, or count
toward another cult's objectives. Deconversion restores the prior faith, and
body transfers retain membership without increasing cult progression.

Jes, Judas, and Hasard remain available with their existing Old God recipes.
Each faith has separate favor, requests, and shrine territory. Examine an allied
shrine to learn its ingredients and generated invocation phrases; cult tomes
also display their deity's shrine rituals. A paper north of a cult shrine can
be exchanged for that cult's tome using the displayed scriptures invocation.

The rune-scribing menu's Imbue option creates an EMP talisman rune: drop a blank
sheet of paper on the rune's tile, then invoke the rune with an empty hand.
The talisman belongs to the rune's cult. Old incomplete Imbue runes must be
erased and redrawn. Rune scribing starts its ten-second recharge only after a
rune is successfully created; cancelling the menu, missing materials, or an
interrupted carving does not consume the cooldown.

This is **not yet the complete Paradise gameplay port**. It currently uses the
local rune/progression system and legacy sprites (tinted tomes, blades, shrines,
and gods for fire/death). Paradise blood-magic preparation, the distinct acolyte
role, modern rune/objective progression, full crafting/gear, additional construct
abilities, and upstream themed assets remain to be ported.

Validation uses normal command-line compilation of `Interpost-Hague.dme`, not
unit tests or the Dream Maker IDE. Manual in-game checks for this stage:

- Admin-add one member of each cult; inspect their religion, faction, tome, and
  objectives. Confirm a mind cannot join two competing cults simultaneously.
- Draw two teleport runes per cult. Verify destinations and communion are
  isolated; deconvert a member inside a teleport rune and confirm they can exit.
- Mix cults around sacrifice and summoning runes: only the owning cult counts.
  Check sacrifice credit, soulstone ownership, and summoned deity objectives.
- Use an artificer to summon stones, shells, floors, and pylons. Verify the
  creator's ownership, construct recruitment, rival repair rejection, and
  progression credit when floors or walls are removed.
- Transfer a cult member to another body, then deconvert them. Check old-body
  powers, restored faith/faction, spell cleanup, and unchanged transfer ratings.
- Praise each faith, build/destroy its shrine, and invoke its displayed recipes.
  Confirm rival shrines cannot refund favor and paper-targeted Old God spells
  read their ingredients before those ingredients are consumed.
- Scribe an Imbue rune, place blank paper on it, and invoke it; verify an owned
  EMP talisman replaces the paper. Try without paper and with written paper.
- Cancel rune selection, attempt without a blade/tome, and interrupt carving;
  verify immediate retry is possible. Complete a rune and verify recharge
  begins only then. Attempt a second activation while the first menu is open.
