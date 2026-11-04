# Mapper access: one field

Set **`map_access`** on an object instead of looking up numbers and editing
`req_access` / `req_one_access` lists. This works with existing door and
machine types, including OS13 variants; no special door subtype is needed.

| `map_access` value | Who passes the ID access check |
| --- | --- |
| `"medical"` | Medical access |
| `"medical | engineering"` | Medical **or** Engineering |
| `"medical, engineering"` | Same as `|` |
| `"medical & engineering"` | **Both** Medical and Engineering |
| `"security | command"` | Security Equipment **or** Bridge |
| `"public"` | No ID access restriction, including inherited requirements |
| `null` (default; leave unset) | Existing subtype / mapped numeric requirements, unchanged |

Names are case-insensitive. Spaces and hyphens can replace underscores.
Access datum names, their full display descriptions, and existing numeric
IDs written as text are accepted. An optional `access_` prefix is supported:
`"access_medical"` is the same as `"medical"`.

Do not mix `&` with `|` or commas. Parentheses and nested expressions are not
supported. For the uncommon existing rule "all of one list, plus any of
another", leave `map_access` unset and use the original two numeric lists.

`map_access` **replaces both inherited access lists**, rather than adding to
them. Empty strings, misspelled names, unknown IDs, mixed operators, and
non-text values produce a startup warning with the object's type/location
and install an impossible requirement. They do not silently make it public.
Use `"public"` deliberately; do not use an empty string.

## Placement examples

These are object entries for a DMM map, not new DM type definitions:

```dm
/obj/machinery/door/airlock{
    map_access = "medical"
}

/obj/structure/closet/secure_closet{
    map_access = "engineering | atmospherics"
}

/obj/machinery/computer/cloning{
    map_access = "genetics & command"
}
```

In a map editor, select the placed instance and edit only `map_access`.
There is no need to change its artwork, door subtype, or the two legacy lists.
This changes that object's existing restricted actions; it does not add a
lock to an action that never checks access.

## Common names

These name individual existing credentials, not entire departments' access
collections. For example, `"medical"` does not grant Chemistry or Surgery.
This configures **required** access, not access granted by an ID.

| Area / purpose | Accepted short names |
| --- | --- |
| General / service | `bar`, `kitchen`, `hydroponics`, `janitor`, `library`, `chapel_office` |
| Engineering | `engineering` / `engine`, `engine_equip`, `maintenance` / `maint_tunnels`, `atmospherics`, `external_airlocks`, `emergency_storage`, `tech_storage`, `construction` |
| Medical | `medical` / `medbay`, `medical_equip`, `morgue`, `genetics`, `chemistry`, `virology`, `surgery`, `psychiatrist` |
| Science | `science` / `research`, `tox`, `tox_storage`, `robotics`, `xenobiology`, `xenoarch`, `network` |
| Security | `security` (Security Equipment), `sec_doors` (Security entrance credential), `brig` / `holding`, `armory`, `forensics_lockers`, `detoffice` |
| Supply | `cargo` / `supply`, `cargo_bot`, `mailsorting`, `mining`, `mining_office`, `mining_station` |
| Command | `command` / `bridge` / `heads`, `captain`, `hop`, `hos`, `ce`, `cmo`, `rd`, `qm`, `heads_vault`, `change_ids` |
| Other station systems | `eva`, `ai_upload`, `teleporter`, `gateway`, `tcomsat`, `rc_announce`, `keycard_auth`, `all_personal_lockers` |
| Special | `cent_general`, `cent_thunder`, `cent_specops`, `cent_medical`, `cent_living`, `cent_storage`, `cent_teleporter`, `cent_creed`, `cent_captain`, `syndicate`, `synthetic` / `synth`, `crate_cash`, `merchant`, `manufacturing` |

The full source of names and display descriptions is
[access_datum.dm](../code/game/jobs/access_datum.dm). New access datums are
picked up automatically. Datum names win over conflicting display descriptions:
notably, use `sec_doors` for Security entrance access, not `security`.

## Specialized objects

- **Airlocks, windoors, lockers, crates, computers, vending machines, alarms,
  turrets, buttons, lockboxes, tape, and other shared ID-check objects:**
  use `map_access`. Installed airlock/windoor electronics inherit the resulting
  numeric requirements through the existing construction/deconstruction paths.
- **Airlock braces:** `map_access` also initializes the brace's electronics.
  Later in-game reprogramming continues to work normally.
- **Loose airlock electronics:** `map_access` controls who can configure the
  board. **`map_door_access`** uses the same syntax for the access that the
  board programs onto a constructed door. Leave either unset to keep its
  original behavior.
- **Mecha:** `map_access` controls operation. **`map_service_access`** separately
  controls the cell/service compartment, using exactly the same syntax.
  Existing operation-access UI entries still show/edit the real requirement
  list; an initial `&` expression keeps ALL mode, otherwise entries use ANY mode.
- **Bots, cyborgs, spiderbots:** `map_access` sets their existing control /
  panel / brain-removal credential checks, not their own ID's door privileges.
  Bots still respect their existing `RequiresAccessToToggle` setting.
- **RIG suits:** explicitly setting `map_access` enables the shared credential
  check; leaving it unset preserves their existing unrestricted override.
- **Barsigns, request-console announcement authorization, keycard authentication
  devices, AI-core authorization, holowarrants,
  holobadge imprinting, bridge controls and Scout/Prospector controls:** explicit
  `map_access` replaces their specialized credential check as well. Without
  it their original rules remain in force. Identity, multiple-card quorum,
  physical card swipes, power, proximity, seated-pilot and remote-control
  interlocks remain required where those devices already require them.

This is not a universal interaction bypass. Bolts, welded doors, personal
locker ownership, emag effects, physical locks, biological eligibility,
radio channel policies and individual software program permissions retain
their separate rules. In particular `"public"` does not unweld a door,
remove its bolts, power it, or replace a required physical ID swipe.

## Lifecycle and manual verification

The shorthand is resolved once during movable initialization, after map
preloading and before subtype initialization continues. Normal runtime access
checks use ordinary numeric lists; they do not parse strings on every bump.
Construction defaults that previously overwrote mapped access on portable
turrets and server alarms are now type defaults, so the mapper value wins
for both mapped and runtime-created instances.

In-game access edits, electronics programming and emag list changes are not
continually overwritten by the mapper string. Editing `map_access` on a live
instance alone does not reconfigure it; its `apply_map_access()` proc must
be called to explicitly reapply the configuration.

Validation for this change is static only; no compiler or live client was run.
Manual checks: place an unrestricted, single-access, OR, AND, public and
misspelled-name door; try no ID, unrelated IDs and each matching ID. Repeat
with a secure locker and machine. Verify mapped and constructed doors, loose
electronics, a brace, turret, server alarm, mecha operation/service, bots and
RIGs. Reprogram or emag an object and verify its changed access persists.
Confirm old maps with unset `map_access` retain their previous rules.
