# Porco UI checks

The replacement menu retains the `InputMsg`, `addel`, `changel`, `change`, and
`doneRsc` interface used by `code/porco/pig.dm`. It loads the shared device bezel
CSS with static markup: this embedded panel has no window drag, close, or resize
handlers. Its layout fills the existing 541 × 315 browser control.

Run `python tools/porco_ui/check.py [preview directory]` to generate an isolated
native test and a browser preview. Compile `tmp/porco-ui-check/check.dme`, start
the resulting DMB with DreamDaemon, and connect a test Dream Seeker. The world
shuts down after the checks, or after a 30-second timeout.

The native test extracts the production asset registration, panel opener, output
callbacks, and verb-link generator. It verifies resource delivery, stats and
scrolling, the compact layout, role and OOC tabs, lobby countdown updates, ghost
controls, actual action/WHO command dispatch, and removal of the native browser
border. Only the isolated test page includes the assertion script.

Open `porco-preview.html` from the generated preview folder to inspect the menu
at its native dimensions. Preview mode uses sample data and suppresses commands;
the normal in-game page uses live server data and the existing command links.
