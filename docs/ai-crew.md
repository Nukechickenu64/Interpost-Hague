# Experimental AI crew

## Enabling and controlling crew

Before the round begins, an administrator with Admin rights can enable **AI
crew** in the **Game Panel**. It defaults to off, applies to this round only,
and is locked when setup begins. Modes without station jobs do not spawn crew.
The option does not change a game mode's minimum human-player requirements.

Human players receive their jobs first. Each finite, vacant round-start crew
slot then receives an NPC; an unlimited job receives one NPC only if no human
has that job. Opposition, animal and silicon roles are excluded: this is a
human crew controller, not an AI/borg controller. A spawnable NPC Captain can
satisfy the round-start Captain requirement.

NPCs receive the job's normal outfit, access, skills, implants, medical bracelet
and crew record. They are not added to the player antagonist selection pool.
They do not consume human job slots, so latejoin remains available; latejoining
does not automatically delete an existing NPC.

Living human crew can use **IC > AI Crew Orders** to select an NPC and:

- Resume autonomous work.
- Follow the player, move to the player's current tile, or hold position.
- Collect a visible loose item and deliver it to the player's current tile.
- Set supported work priorities from 1 (highest) to 4, or 0 to disable.

Orders cannot interrupt an interaction already in progress. Deliveries and
unreachable destinations time out with a message to the ordering player.
NPCs yield control while possessed by a client.

## Implemented work

| Crew | Autonomous tasks |
|---|---|
| Medical department | Find authorized living crew and bandage accessible organic wounds using actual gauze. |
| Engineering department | Repair nearby damaged walls with a fueled welder and worn welding protection. Thermited walls are excluded. |
| Supply/service department | Harvest/remove dead plants in open trays; install a loose Water Chip, fill biomass vats, add yeast/glig, stir and skim, press biomass, load/activate food units, collect meals, and clear jammed food units. |
| All human jobs | Clean nearby decals using real soap, eat nearby/held food and drink water-containing drinks when needed, and execute movement/delivery orders. |

General tool collection uses the NPC's own inventory and nearby loose items.
Logistics workers also search loose station supplies across decks, travelling
to collect them. No tools, medicine, food, power or materials are conjured.
Leave needed supplies accessible. Failed work and supplies are temporarily
avoided and logged; the crew order menu displays each NPC's current status.
Workers reserve machines and supplies while collecting them so they do not
all attempt the same patient, machine or item. Tools are stored in carried
storage when possible instead of being abandoned whenever a hand is needed.

The **Logistics** priority controls the biomass/food chain independently of
**Gardening** (plant trays). Provide powered machines, a loose Water Chip,
yeast, glig and a skimmer. Workers use the vat's north service tile, unload
goo into an available press, and leave collected bricks and meals on the
floor for the next operation or nearby hungry crew. Food units retain their
configured meal shape. Jam clearing uses the normal timed repair interaction.
Workers do not process raw meat or fabricate new cultures, chips or tools;
the chain stops when its actual supplies run out or power is lost.

Movement reuses the human movement driver, with normal movement delays,
access checks and door interactions. Crew avoid space, open shafts, fire and
unsafe atmosphere. For another deck they call a turbolift, enter the actual
cabin, queue the destination and ride it. They do not teleport between decks
or force locked doors. Broken or unreachable routes time out.

## Current limits

This is an incremental implementation, **not complete singleplayer automation**.
Filling a job does not yet mean the NPC can perform every responsibility.
There is no autonomous surgery, cloning, genetics, cyberdeck exploration,
technology recovery, fabrication, piloting, combat/investigation, psionics,
general recipe-based cooking, power startup, hull reconstruction or
atmospherics repair. Unsupported specialists can still be given general
movement and delivery orders. NPCs do not currently patrol to discover distant
cleaning or wall-repair work, open containers for station supplies, or
automatically escape every hazard.

## Manual in-game checks

- With the setting off, confirm unchanged round setup and no AI crew.
- Enable it in the lobby; ready as a non-Captain and confirm a spawnable NPC
  Captain allows setup, while occupied jobs are not duplicated.
- Check every finite vacancy, an empty unlimited role, and an unlimited role
  already held by a human. Confirm job IDs, access, skills and records.
- Confirm non-admins cannot toggle the setting and nobody can toggle it after
  setup. Confirm latejoin slots remain available.
- Order a delivery across decks. Watch the NPC call, board, ride and leave the
  elevator. Try concurrent passengers, intermediate stops and a blocked door.
- Deny a door's access or break the route; confirm no forced entry,
  teleportation or indefinite delivery without an error message.
- Provide gauze and a wounded patient, a damaged wall plus welding equipment,
  soap plus dirt, a harvestable tray and a red biomass vat. Confirm normal
  interactions and supply usage; remove supplies and check the failure status.
- Start with empty powered vats, an unchipped hydroponics console, loose chip,
  yeast, glig, skimmer, press and food unit. Watch the full chain through to a
  meal left on the floor; verify cultures/bricks are consumed and skimmers
  switch between loaded and empty. Repeat with supplies on another deck.
- Use multiple logistics workers and only one skimmer: confirm they reserve
  distinct resources, process loaded skimmers before reusing them, and never
  duplicate products. Remove a reserved item or cut machine power mid-task.
- Jam a food unit and confirm timed repair before loading/activation.
  Disable Logistics priority and confirm biomass/food work stops being selected
  while Gardening still services plant trays.
- Change priorities, hold/follow orders, move/remove a delivery item, and try
  issuing orders while dead, incapacitated, or controlling an opposition role.

Validation for this pass is static inspection/editor diagnostics only.
Compilation and live gameplay have not been performed.
