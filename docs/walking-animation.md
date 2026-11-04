# Procedural human walking

Pig menu **Options → Walking animation: On/Off** controls the player's own
human, visible to other players. It defaults on and uses the existing saved
client-preference system (`HUMAN_WALKING_ANIMATION`). It can also be changed
through **Toggle Preference → Animate my human's walking**.

The `Walking Poses` subsystem prepares all eight reusable alpha-mask sprites
and sixteen direction/foot/garment configurations before atom initialization.
It never fires during the round. Missing masks cannot be generated after it
has initialized. Late joins, clothing changes, colors and preference changes
reuse this same library: no walking icon rasterization happens during play.

The renderer copies appearances and applies the prepared masks, leaving source
icons, animations, tints, blood and nested accessories intact. Appearance
wrappers are cached per human, direction and pose until appearance changes.
The existing human appearance pipeline still assembles bodies and equipment
normally; this feature does not try to precompute every possible skin color
and outfit combination.

Feet alternate after successful player movement. North/south poses lift one
foot; profile poses reuse the lower silhouette for a short two-leg stride.
Pixels at y=11 and above stay fixed, preserving hand/glove/weapon alignment.
Suit hems and uniforms that hide shoes sway together. No new clothing or human
art is required. This is a restrained procedural gait, not a hand-drawn cycle.

The gait returns to standing between steps and is disabled while prone,
resting, buckled, hanging, thrown, floating, unconscious/dead, cloaked, in zero
gravity, or missing a leg/foot. Teleports and logout reset it. It currently
supports standard Humans; other species retain their existing rendering.

## Validation

Compile `walking_animation_regression.dme` and run its DMB with DreamDaemon.
The three suites cover startup-only mask generation, directional pixel masks,
stationary hands/torso, long hems, nested equipment appearance and cache
invalidation, preference registration, posture/teleport resets and the idle
timer. Require `All Unit Tests Passed [3]` and `Caught 0 Runtimes.`

The test exports software previews under `tmp/walking-animation`. Run
`python tools/walking_animation/preview.py` to build a small native viewer
using the actual production mask library and appearance compositor. Compile
the printed DME, host its DMB and connect Dream Seeker. Rows are standing,
left step and right step; columns are south, north, east and west. The
`Switch Body` verb changes male/female fixtures. It exits after five minutes.

Server tests and software previews do not validate live filter rendering or
pig-menu clicks. A native viewer launch was successful, but automated capture
timed out; full-game visual timing and the menu interaction remain live checks.
