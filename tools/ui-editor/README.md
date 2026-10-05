# Human HUD Editor

A self-contained, offline website tool for visually editing the human player's
in-game HUD (the "os13" skin `screen_loc` defines used by
[`code/_onclick/hud/_defines_alt.dm`](../../code/_onclick/hud/_defines_alt.dm)
and consumed by
[`code/_onclick/hud/human_alt.dm`](../../code/_onclick/hud/human_alt.dm) /
[`code/modules/mob/living/carbon/human/species/species_hud.dm`](../../code/modules/mob/living/carbon/human/species/species_hud.dm)).

No build step or dependency install is required to use the tool itself — it's
a single `index.html`. An optional one-file Python server
([`serve.py`](./serve.py)) is included purely to make the **auto-load**
feature work in every browser without any prompts; there's also a built-in
Chrome/Edge-only fallback (folder access, no server needed) described below.

## How to use it

1. Open the tool in one of these ways:
   * **Directly:** open [`index.html`](./index.html) straight from disk.
     Whether auto-load works immediately depends on your browser — see
     step 2.
   * **Via local server (works everywhere, no prompts):** run
     `python tools/ui-editor/serve.py` from the repo root, then open the
     `http://localhost:8000/tools/ui-editor/index.html` link it prints.
     Browsers block `fetch()` from reading sibling files on `file://`
     pages (Firefox always; Chrome/Edge too, depending on version/flags),
     so serving over plain HTTP sidesteps that restriction entirely.
2. The tool automatically tries to load `_defines_alt.dm`, `os13.dmi`, and
   `backgrounds.dmi` straight from their repo-relative paths as soon as the
   page opens — no file pickers needed. Check the status line in the
   toolbar to confirm all 3 loaded.
   * If opened directly from disk and the browser blocks `fetch()`, a
     **📁 Grant folder access…** button appears (Chrome/Edge only, via the
     File System Access API). Click it once and pick the repo's root
     folder (the one containing `code/` and `icons/`) — the tool loads
     immediately and remembers that folder for next time, so future visits
     to the same `file://` page auto-load with no prompt at all.
   * Firefox and other browsers without that API will instead be told to
     use `serve.py`.
   * Click **🔄 Auto-load from repo** any time to retry the whole sequence
     (fetch, then the remembered folder, in that order).
3. If you still need to load files manually (auto-load failed, or you want
   to point the tool at a different copy of a file):
   * Click **Load _defines_alt.dm…** and pick
     `code/_onclick/hud/_defines_alt.dm` from the repo. This lets the tool
     reconstruct the exact file later instead of generating a fresh one.
   * Click **Load os13.dmi…** and pick `icons/mob/screen/os13.dmi`. The tool
     reads the DMI's embedded `icon_state` metadata and renders the real
     sprites on the board instead of placeholder boxes.
   * Click **Load backgrounds.dmi…** and pick
     `icons/mob/screen/backgrounds.dmi`. This renders the full-height HUD
     backdrop/panel bar behind the other icons, so you can see your layout
     against the real backdrop instead of floating in empty space.
4. Drag HUD elements around the board, or type exact anchor/tile/pixel values
   directly in the table on the right — both stay in sync. Use the group
   checkboxes to show/hide gear, hands, status icons, intent buttons,
   background, etc.
   * **Undo**: press **Ctrl+Z** (or click **↩ Undo**) to step back through
     your edits — drags, table edits, resets, and "+ Add to board" are all
     undoable, up to the last 100 changes.
   * **Snap to grid**: with the checkbox enabled, dragging snaps to the
     chosen tile fraction (1, ½, or ¼ tile) and, if a pixel snap size other
     than "Off" is selected, also snaps the leftover pixel nudge to that
     many pixels. Turn the checkbox off for fully free dragging.
   * The grid (both the faint lines drawn on the board and the snap points
     themselves) is always phased to line up with the edges of the **HUD
     Backdrop Bar**, not the raw view-tile origin. Since the backdrop isn't
     tile-aligned itself (it's nudged `WEST-3:12,SOUTH` — 12px off a clean
     tile boundary), everything you drag snaps to that same offset, so new
     elements land on the same invisible grid the hand-authored defines
     already use, and stay visually consistent with the backdrop no matter
     where it sits. If `backgrounds.dmi` hasn't been loaded yet, snapping
     falls back to the plain view-tile grid.
6. Click **Generate updated file**, review the diff in the text box
   (changed lines are flagged with a "changed" badge in the table), then
   **Copy to clipboard** or **Download _defines_alt.dm** and replace the file
   in the repo.
7. Recompile in BYOND Dream Maker as usual to see the result in-game.

## Notes

* Auto-loading relies on `fetch()` reading sibling files from the repo.
  When the page is opened directly as `file://`, Firefox always blocks
  this (and so does Chrome/Edge in some configurations). In Chrome/Edge,
  the tool falls back to the File System Access API — click **📁 Grant
  folder access…**, pick the repo root once, and it's remembered (via
  IndexedDB) for future visits, no server required. Firefox has no such
  API, so `python tools/ui-editor/serve.py` (open the printed
  `http://localhost` link) is the only way to get auto-load working there.
  The manual **Load…** buttons always work as a fallback regardless of how
  the page was opened or which browser you're using.
* Only single-point `screen_loc` values (`"X,Y"`) can be edited visually.
  Multi-part values like `"WEST,SOUTH to EAST,NORTH"` are left untouched.
* Any `ui_*` define found in the loaded file that isn't already on the board
  (e.g. a custom addition) shows up under **"Other ui_* defines found…"** with
  an **+ Add to board** button.
* The HUD backdrop bar isn't a `#define` — in
  [`human_alt.dm`](../../code/_onclick/hud/human_alt.dm) its `screen_loc` is
  set directly in code (`using.screen_loc = "WEST-3:12,SOUTH"`). You can still
  drag it on the board to preview layout changes, but since it isn't part of
  `_defines_alt.dm`, it's listed under **"Hardcoded positions…"** with a
  **Copy snippet** button instead of being included in the exported file —
  copy that line and paste it over the matching line in `human_alt.dm`
  manually.
* The board's grid approximates BYOND's `screen_loc` anchor system
  (`WEST`/`EAST`/`NORTH`/`SOUTH`/`CENTER` relative to `world.view`, default
  15 tiles) closely enough for layout purposes, but BYOND's exact on-screen
  rendering (borders, letterboxing) can differ slightly — always confirm
  final placement in-game.
* Exporting only ever rewrites the quoted value of matching
  `#define NAME "..."` lines; comments, ordering, and unrelated defines are
  preserved byte-for-byte.
