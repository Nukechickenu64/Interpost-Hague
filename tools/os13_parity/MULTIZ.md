# Classic Z-level connections

Classic has occupied decks at Z1/Z2, a mapped hull roof at Z3, and reserved
empty space at Z4. Classic's `setup_map()` creates a `map_data/os13classic`
landmark on Z3 with `height = 3`, connecting the physical stack before turf
and ladder initialization. This lives in the map configuration so subsequent
DMM saves cannot remove the connection. Station-level lists alone do not
establish these connections.

Five exterior ladder routes connect Z1 and Z2: `(104,117)`, `(104,121)`,
`(104,123)`, `(104,127)`, and `(143,150)`. The lower ladders point up and the
upper ladders connect down. Both `/ladder` and `/ladder/updown` are valid
upper endpoints when they select the linked Z1 ladder. Each upper endpoint
has a catwalk over open space.
The floor sprites named `s_ladder` and `ss_ladder` are decorative steps;
they are not additional inter-deck ladder routes.

Run the geometry check and native production-map regression from the repository root:

```powershell
python tools/os13_parity/check_multiz.py
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' os13_multiz_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' os13_multiz_regression.dmb -invisible -trusted -close
Get-Content tmp/os13-multiz-regression.log -Tail 5
```

The native target checks destination selection and both-way ladder traversal,
the rendering stack, copied lower-deck artwork and depth on Z2 openings,
open-floor references to the actual turf below, and atmosphere connectivity
where the turf allows it. It exits without starting a round. Success is
`OS13_MULTIZ_RESULT: PASS failures=0 runtimes=0`.

Rebuild `Interpost-Hague.dme` and restart the running world to load map changes.
