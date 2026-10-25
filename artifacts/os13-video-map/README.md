# OS13 video map extraction

Status: extraction running; no completed or verified map yet.

Uses a preserved copy of the user-supplied Video to Tilemap Studio HTML.
Sources: the four Lifeweb OS13 MP4 recordings in D:/os13archive.
Output: all_z_layers.zip and stitch_diagnostics.json after processing completes.
Progress: progress.json, updated every ten seconds by run.cjs.
Settings: x=252, y=0, width=1080, height=1080; 0.2-second sampling; 8192-pixel mosaic; up to 100 provisional regions.
Crop inspected against the Engineer recording at 600 seconds. Other source crops still require visual verification.
Automatic final reconciliation disabled pending inspection of extracted regions.

The output is an image mosaic with provisional regions, not a playable BYOND DMM. Region numbers do not establish floors. Unseen areas cannot be recovered from these recordings. Tile slicing and cross-region verification remain required after capture.

Do not start a second run while the current process is active. To rerun after it exits:
node artifacts/os13-video-map/run.cjs

## Stitcher update
The studio now keeps several coarse motion hypotheses and explicitly tests zero movement, computes luminance once per frame pyramid, respects transparent masks, caps pixel voting history at eight observations so transient objects can be replaced, and includes a supplied-recordings viewport button. Exports record the reference viewport and observed-only status.

Validation: test.cjs / test-results.json, 13 checks passed. Synthetic translations and stationary samples from all four videos were tested. Full moving-video reconstruction and exact topology have not been validated. The already-running extraction loaded the earlier HTML and does not acquire these edits automatically. Its output must not be described as output of the updated algorithm.

## Export-based fixes (2026-10-24)
Inspected D:/Downloads/all_z_layers(2).zip: version 5, 78 regions, one source (water-chip). Contact sheet: tmp/video-map/export-survey.jpg. Large mosaics show overlapping geometry and UI trails. This export is not evidence that all four sources were processed.

Version 6 changes: inset OS13 crop to x=256..1324; require textured motion agreement across at least three cells spanning two rows and columns; reject stronger conflicts with mapped pixels; disable automatic joining/reconciliation by default; cap merged vote counts consistently at eight. Exports retain both automatic-merge settings.

20 focused checks passed, including consecutive frames at 1043.1/1043.25 seconds from all four sources. Water-chip forward/reverse motion was (0,47)/(0,-47); other sampled pairs were stationary. This is not a full-video quality validation. Stricter support may reject sparsely visible valid views. Existing corrupt merges cannot be reversed from flattened PNGs; rerun capture for those areas. The supplied ZIP was not modified.

Reload the HTML after preserving any unsaved browser work, click Use supplied OS13 viewport, and load all four recordings for a new extraction. A currently open page continues using the previous JavaScript until reloaded.
