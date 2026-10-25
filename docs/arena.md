# Arena

Select **Arena** in the game-mode vote or set the server mode to `arena`.
The normal server build loads `maps/arena.dmm` when Arena starts and makes its
z-level the main station/player level. The original compiled station remains
loaded for subsystem initialization, but Arena arrivals and respawns use only
the arena landmarks. Station events and the AI director are disabled.

The map layout and number of spawn points can be edited in Dream Maker using:

- `/obj/effect/landmark/arena_spawn`: player arrivals and respawns.
- `/obj/effect/landmark/arena_ai_spawn`: practice opponents.
- `/area/arena`: unlimited power and fresh room-temperature, standard-pressure
  oxygen/nitrogen air, including on tiles converted to space by breaches.

All fighters start with a sword, breastplate, helmet, grey uniform and boots.
Players start with sword skill 50/100 (rank 5, adept) on every arrival and
respawn. Practice opponents retain their lower skill.
There are no station jobs, captain requirements, death-based round endings,
respawn delays, respawn quotas or restrictions from the normal respawn toggle.
Use **Respawn** in the ghost menu after death or ghosting. An occupied spawn
landmark does not prevent a player from returning.

With exactly one living connected Arena player, a practice opponent appears
after 15 seconds. There is at most one living practice opponent; replacement
also has a 15-second grace period during normal processing. Zero or multiple
players suspend further AI spawning. An existing opponent stays in the arena.

Sparring partners and defenders share the player's equipment and have lower
attributes/skills and slower reactions than invaders. Defenders guard more
often. Both use the shared GURPS combat resolver for aimed, strong and quick
attacks, guard/defense, feints, offhand attacks, kicks, unarmed grabs, parries,
dodges and willpower effort. Readiness, movement, stamina, armor and injury
rules apply normally. They rest when tired, favor torso targets, and leave
unconscious or disconnected players alone.

## Admin controls

Admins with the Admin permission can use **Admin → Edit Own Skills** and
**Admin → Edit Own Stats** while controlling a human character, in any mode.
Choose an entry, enter its new value, and continue editing or cancel to close.
Skills use 0–100; stat entries show effective GURPS values, including derived
Perception and Immunity. Changes apply to the current body and are logged.
Temporary effects continue to expire normally.

## Validation

Compile `arena_regression.dme` and run its DMB with DreamDaemon. The focused
suite checks actual runtime map loading, landmark placement, shared equipment,
solo spawning/grace/cap/replacement, AI guarding and action cooldowns, power,
polluted simulated floors and breached-turf breathing. Check both the suite
result and runtime diagnostics. The existing `combat_parity_regression.dme`
also covers the shared GURPS rules used by players and these opponents.
Client transfer and repeated ghost-menu respawns still need a live client test.
