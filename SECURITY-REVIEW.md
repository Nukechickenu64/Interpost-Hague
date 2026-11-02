# Security Review — 2026-11-02

Static review of the Interpost-Hague codebase (no compile, no runtime verification).
Focus areas: `Topic()` href handling, `world/Topic` authentication, file/shell access,
admin privilege checks, HTML/SQL injection, NanoUI/PICO-8 JS layer, committed secrets.

Severity key: CRITICAL / HIGH / MEDIUM / LOW. Confidence is 1–10.

## Summary

| # | Severity | File | Lines | Vulnerability | Confidence |
|---|----------|------|-------|---------------|------------|
| 1 | HIGH | `code/modules/integrated_electronics/machine_printer.dm` | 73-96 | Arbitrary type spawn via unchecked `text2path(href_list["build"])` | 9/10 |
| 2 | HIGH | `code/modules/modular_computers/file_system/programs/generic/library.dm` | 42, 160, 174-180 | SQL injection in library program (`id`, `sortby`) | 9/10 |
| 3 | HIGH | `code/game/world.dm` | 201, 250, 317, 366, 380, 433 | `world/Topic` privileged branches accept empty comms password; `adminmsg` HTML injection | 8/10 |
| 4 | HIGH | `code/game/objects/topic.dm` (+ ~70 legacy `Topic` overrides) | 1-7, 48 | `/obj/Topic` returns null on access failure, so legacy `if(..()) return 1` handlers have no distance/access check | 8/10 |
| 5 | HIGH | `code/_onclick/context_menu.dm`, `code/modules/mob/mob.dm`, `code/modules/client/client_procs.dm` | 427-487, 499-510, 100-101 | Tile context-menu href allows remote item pickup/use on any atom and puppeteering of other mobs | 9/10 |
| 6 | MEDIUM | `code/modules/client/client_procs.dm`, `code/modules/admin/verbs/adminpm.dm` | 68-75, 163-188 | `irc_msg` href missing `return`; non-admins can inject unsanitized HTML into chat | 7/10 |
| 7 | MEDIUM | `code/modules/clothing/spacesuits/rig/rig.dm` | 574-631 | `check_suit_access()` passes for any human when rig is sealed; remote unseal/lock/module control | 8/10 |
| 8 | LOW | `config/dbconfig.txt`, `sql/Dockerfile`, `start-database.bat` | 14-21, 5, 56 | Live DB credentials (`gamelord`/`gamelord`) committed to git | 9/10 |
| 9 | LOW | `code/modules/mob/mob.dm` | 434-440 | `update_flavor_text()` lacks `return` after `usr != src` check; anyone can overwrite another mob's flavor text | 9/10 |

## Findings

### 1. Arbitrary type spawn in integrated circuit printer — HIGH (9/10)

**File:** `code/modules/integrated_electronics/machine_printer.dm:73-96`

`/obj/machinery/integrated_circuit_printer/Topic()` does
`var/build_type = text2path(href_list["build"])` → `ispath()` → `new build_type(get_turf(loc))`.
The `recipe_list` whitelist built in `interact()` is never consulted in the Topic handler, so any
type path is accepted. Cost defaults to 1 metal unless the path is an electronic assembly.
A player can send `?src=\ref[printer];build=/obj/singularity` (or any weapon, the nuke, a mob,
an admin-only item) and have it spawned. Combined with finding 4, the player does not need to be
near the printer. The printer is mapped on the active map and its circuit board is buildable.

**Fix:** Reject unless `(build_type in recipe_list["Circuits"]) || (build_type in recipe_list["Assemblies"])`;
convert the handler to `OnTopic()` so `CanUseTopic` distance/state checks are enforced.

### 2. SQL injection in Library program — HIGH (9/10)

**File:** `code/modules/modular_computers/file_system/programs/generic/library.dm:42, 160, 174-180`

Two injections reachable by any player using the Library program on a modular computer (or by
direct href to the nano_module ref):

- `view_book(href_list["viewbook"])` → `"SELECT * FROM library WHERE id=[sqlid]"`.
  `sanitizeSQL()` only escapes quotes and the `id` is interpolated **unquoted**, so
  `viewbook=0 UNION SELECT 1,ckey,ip,computerid,lastadminrank FROM erro_player` needs no quotes
  and is displayed back as author/title/content. `dbcon_old` uses the FEEDBACK_* credentials which
  point at the same database as `erro_player`/`erro_admin`/`erro_ban` (`config/dbconfig.txt`), so
  player IPs/CIDs, the admin table, bans and notes are exfiltrable.
- `href_list["sortby"]` is stored raw into `sort_by` and concatenated into
  `"... ORDER BY " + sanitizeSQL(sort_by)` — arbitrary expressions/subqueries (blind injection).

`SQL_ENABLED` is on in `config/config.txt`. `/datum/nano_module/Topic` performs no distance check.

**Fix:** `text2num()` the id and reject non-numbers; whitelist `sort_by` against
`list("id","author","title","category")`.

### 3. `world/Topic` accepts empty comms password; `adminmsg` HTML injection — HIGH (8/10)

**File:** `code/game/world.dm:201, 250, 317, 366, 380, 433`; `code/controllers/configuration.dm:165`

`config.comms_password` defaults to `""` and `COMMS_PASSWORD` is commented out in the live
`config/config.txt`. Every privileged `world/Topic` branch (`laws`, `info`, `adminmsg`, `notes`,
`age`, `prometheus_metrics`) only checks `if(input["key"] != config.comms_password)`. An
unauthenticated remote sender that includes an empty `key=` parameter passes the check. Only
`placepermaban` has the `if(!config.ban_comms_password) return "Not enabled"` guard.

Impact: `info` discloses any player's location, antag status and role; `notes` dumps admin notes;
`adminmsg` lets anyone deliver a spoofed "Admin PM" to any connected player, with
`input["sender"]`/`input["msg"]` inserted **unsanitized** into `to_chat()` for the victim and all
admins — HTML/JS injection into the BYOND chat browser (`browserOutput.js` sets `innerHTML`),
which can issue `byond://?...` hrefs as the viewing admin.

**Fix:** Early-return `"Not enabled"` when `config.comms_password` is empty for every key-protected
branch; `sanitize()` `sender`/`msg` before use.

### 4. `/obj/Topic` fall-through disables access checks for legacy handlers — HIGH (8/10)

**File:** `code/game/objects/topic.dm:1-7, 48`

Legacy overrides affected include (≈70 total): `code/game/machinery/doors/airlock.dm:970`,
`code/game/machinery/nuclear_bomb.dm:226`, `code/game/machinery/portable_turret.dm:249`,
`code/game/machinery/turret_control.dm:148`, `code/game/machinery/syndicatebeacon.dm:41`,
`code/game/machinery/computer/message.dm:290`, `code/modules/power/smes.dm:292`,
`code/modules/power/solar.dm:483`, `code/modules/reagents/Chemistry-Machinery.dm:72`.

`/obj/Topic` returns **null** both when `CanUseTopic()` fails (`CouldNotUseTopic()` has an empty
body) and when `OnTopic()` returns `TOPIC_NOACTION` (which is `0`). There is no `/datum/Topic` or
`/atom/Topic` definition. Consequently every legacy `/obj/.../Topic(href, href_list)` override
that relies on `if(..()) return 1` has **no** distance, state or access check when hit by a direct
`?src=\ref[obj];...` href. Concrete consequences for any player, from anywhere on the map:

- `airlock.dm:970-1030`: `command=open|bolts|electrify_permanently|main_power` on any airlock.
- `nuclear_bomb.dm:226-299`: enter code / set `timer` to arm or disarm once a disk is inserted.
- `portable_turret.dm` / `turret_control.dm`: set `lethal=1` / `enable=0` on any turret.
- `syndicatebeacon.dm:41-70`: `betraitor;traitormob=<ref>` turns an arbitrary mob into a traitor.
- `message.dm`: authenticate / spam-filter / read message server logs remotely.

**Fix:** Make `/obj/Topic` return `TOPIC_HANDLED` after `CouldNotUseTopic()` (and when `OnTopic`
returns `TOPIC_NOACTION`), or convert the legacy handlers to `OnTopic()`.

### 5. Tile context-menu href: remote use/pickup and mob puppeteering — HIGH (9/10)

**Files:** `code/_onclick/context_menu.dm:427-487`, `code/modules/mob/mob.dm:499-510`,
`code/modules/client/client_procs.dm:100-101`

`handle_tilectx_topic()` handles `tilectx_invoke=<ref>;proc=use|use_right|examine|pull|<verbname>`
with no `Adjacent()`, `incapacitated()` or `view()` check except for the `pickup` branch.
`proc=use` calls `target.attack_hand(src)` on **any atom in the world**; `/obj/item/attack_hand`
has no range check and ends in `user.put_in_active_hand(src)`, so any item anywhere (nuke disk,
weapons, ID cards) is teleported into the caller's hand; any machine can be remotely "used". The
fallback branch `call(target, procname)()` runs any `Object`-category verb while bypassing
`set src in oview(1)`.

Worse, `/mob/Topic` calls `handle_tilectx_topic` with `src` = the mob named in
`?src=\ref[othermob]`, so an attacker can make **another player's mob** pick up or use objects.

**Fix:** In `handle_tilectx_topic`, require `usr == src`, `!incapacitated()`, and
`target.Adjacent(src)` (or `target in view(1, src)`) for every branch.

### 6. `irc_msg` href reachable by non-admins; chat HTML injection — MEDIUM (7/10)

**Files:** `code/modules/client/client_procs.dm:68-75`, `code/modules/admin/verbs/adminpm.dm:163-188`

The `irc_msg` href branch is missing a `return` after the "no longer able to use this" message, so
any non-admin can invoke it, and `sender`/`msg` reach `to_chat()` unsanitized. Compare with the
adjacent `mute_irc` branch, which does `return`.

**Fix:** Add `return` after the time-limit message; `sanitize()` both `sender` and `msg`.

### 7. Rig suit access bypass when sealed — MEDIUM (8/10)

**File:** `code/modules/clothing/spacesuits/rig/rig.dm:574-631`

`check_suit_access()` returns 1 for any human when `!canremove` — and `canremove` is set to 0
whenever the rig is sealed (line 329). For any sealed, worn rig, any player with its ref can send
`?src=\ref[rig];toggle_seals=1` (unseal someone in vacuum), `toggle_suit_lock=1`,
`toggle_ai_control=1`, or `interact_module=N;module_mode=activate/engage` from anywhere. The
file's own comment (line 596) acknowledges the hole. There is no `..()`/`CanUseTopic`/distance
check in `/obj/item/rig/Topic`.

**Fix:** Require `user.back == src` (or AI with `ai_override_enabled`) before the `canremove`
shortcut, and add an `Adjacent`/wearer check.

### 8. Database credentials committed to git — LOW (9/10)

**Files:** `config/dbconfig.txt:14-21`, `sql/Dockerfile:5`, `start-database.bat:56`

The live (non-example) `config/dbconfig.txt` is tracked and contains
`LOGIN gamelord / PASSWORD gamelord` (also for FEEDBACK_*), matching the MySQL user created in
`sql/Dockerfile`. `SQL_ENABLED` is on. Mitigating: docker-compose binds the DB to
`127.0.0.1:3307`, so exposure requires local access or a changed port mapping.

**Fix:** Remove `config/dbconfig.txt` from version control (keep only `config/example/`); use a
strong generated password supplied via environment/secret.

### 9. Flavor text overwrite of other mobs — LOW (9/10)

**File:** `code/modules/mob/mob.dm:434-440` (reached via `flavor_change` in `/mob/Topic`)

`update_flavor_text()` does `if(usr != src) to_chat(usr, "No.")` but never returns, so
`?src=\ref[victim];flavor_change=1` lets any player overwrite any other mob's flavor text
(sanitized, so no XSS — impersonation/grief only).

**Fix:** `return` after the "No." message.

## Reviewed and not flagged

- `code/game/machinery/alarm.dm`: `Topic` → `can_use_modcon()` enforces adjacency/`allowed()`/
  `locked`; `OnTopic` runs under `/obj/Topic` + `CanUseTopic`. Only weakness is
  `TLV[href_list["env"]]` with an arbitrary `env` string causing a runtime error (not security-relevant).
- Admin panel (`/datum/admins/Topic`, `view_var_Topic`, `debug_variables`, SDQL) all gate on
  `check_rights`/`holder`.
- `shell()` is not used; all `file()`/`fdel()`/`file2text()` paths are constant or whitelisted
  (PDA/T-box PICO-8 carts are checked against `pico8_cart_library`).
- PICO-8 Lua VM (`nano/js/pico8.js`): `luaL_openlibs` exposes `package`/`io` (XHR-backed) to
  carts, but carts are server-shipped and whitelisted; T-box savestate re-broadcast is filtered
  for `<`/`>` and must be valid JSON. Becomes a finding if user-authored carts are ever accepted.
- `tools/tts/server.js` uses `spawn()` without a shell, whitelists voices, and does a
  constant-time token compare.
- No DM `DBQuery` other than the library program interpolates attacker-controlled strings
  unescaped (poll ids are `text2num`'d, ckeys pass `ckey()`).
- Awareness only: `code/modules/interpost/flag.dm` sends each player's IP to `http://ip-api.com`
  over plain HTTP (PII disclosure to a third party).

## Limitations

- Static review only; the project was not compiled and nothing was verified at runtime.
- DoS vectors (unbounded `input()` sizes etc.) were not exhaustively surveyed.
- Href exploitability assumes attackers can obtain object `\ref`s. BYOND refs are sequential for
  mapped atoms and routinely exposed in UI hrefs, which is standard for SS13 href exploits.
