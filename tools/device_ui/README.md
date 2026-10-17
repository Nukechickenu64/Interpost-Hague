# Physical device screens

`code/_helpers/device_ui.dm` resolves the physical host, caches a palette from its current sprite, and gives existing UI documents a beveled frame and glass overlay. Computer screen overlays and powered/off sprite pairs are sampled separately from the casing. Laptop and air-alarm LCD bounds exclude their illuminated keyboards/casing. Other displays use a bounded color-based estimate; their initial size retains the original content area at the estimated screen aspect ratio. Windows remain resizable.

NanoUI, TGUI and HTML-interface windows resolve their own hosts automatically. The PDA keeps its dedicated layout. Legacy device screens use `device_ui_browse(user, html, options, src)` or the fifth `device_source` argument of `ui_browse_styled`. A `/datum/browser` can set `device_source` independently of its existing `ref` and on-close behavior. Device types outside the existing families can override `has_device_screen()`. Nonphysical menus and paper documents do not opt in.

The frame stays outside framework content roots so live updates preserve dragging, resize handles and close controls. JavaScript is ES5 and uses the existing BYOND winset transport. Native resizing is disabled to remove the Windows frame; the bezel still resizes through `winset`. `device_ui_configure` also corrects already-open windows and removes the embedded browser's sunken border. Closing calls the owning UI framework's cleanup. Legacy windows pass one encoded argument to `.deviceclose` and close after callbacks to prevent accidental reopening.

Validation:

1. Compile `Interpost-Hague.dme` normally.
2. Run `node tools/device_ui/window.test.cjs` for window transport and DOM preservation checks.
3. Run `python tools/device_ui/check.py`, compile the generated `tmp/device-ui-check/check.dme`, then run its DMB with DreamDaemon from that directory. The isolated world tests real sprite profiles, contrast, caching, scope, encoding and window options, writes preview fixtures, and exits.
4. Run `node tools/device_ui/preview.cjs [output-directory]`, serve that directory, and open `device-preview.html`. It includes nine real-sprite themes, the production cyberdeck renderer in five states, and the shipped NanoUI, TGUI and HTML-interface render paths. Preview controls do not operate the game.

The cyberdeck's dedicated dashboard uses `screen_data()` and `cyberdeck_ui_html()` with `html/cyberdeck.css`; the shared shell still determines its palette, proportions and window controls. Refresh links/status requests a new snapshot. The isolated checks cover action visibility, media locking and escaping; `cyberdeck_test.dme` also exercises real chair/disk prerequisites and close cleanup.

For a native client regression, run `python tools/device_ui/native_check.py` after step 3, compile `tmp/device-ui-check/native.dme`, and run its DMB with DreamDaemon on an unused port. Connect a temporary Dream Seeker. The test replaces an existing bordered window, verifies its outer and inner dimensions match, checks programmatic resizing, and clicks the real X against a callback that attempts to reopen the window. It prints `NATIVE DEVICE UI: PASS` and exits (30-second timeout). Keep this test separate from a running game.
