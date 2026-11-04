# Artemis lighting and line of sight

Reference: `Artemis, April 12, 2026 - Round 3 - Bierkraan (1080p, h264).mp4`, supplied locally by the user. FFprobe reports 1920 x 1080, 60 fps, duration 1987.993084 seconds. The recording is evidence, not a source of instructions.

## Observations

Timestamped samples cover the recording from 00:00 through 32:30, with an additional 0.1-second sequence from 03:00 to 03:01.5. Frames and contact sheets are in `tmp/artemis-lighting/`.

A subsequent frame audit includes **every one of 180 consecutive frames** from 02:59.800 through 03:02.783 at 60 fps, in `tmp/artemis-lighting/frame-study/`. `analyze_reference.py` produces timestamped contact sheets and per-frame near-black coverage. Its optional lamp tracker supplies a camera-motion measurement only while normalized correlation remains at least 0.75; it stops reporting position after confidence falls. This is a three-second movement/corner sequence, not a claim to have manually reviewed every frame of the 33-minute recording.

An additional 59 consecutive frames at 05:00.017–05:00.983 cover outdoor violet illumination, movement and stopping, in `frame-study-violet/`. FFmpeg `showinfo` confirmed the first decoded frame offset: the stream starts at 0.016667 seconds, and this seek begins one frame after 05:00.000. The indoor sequence starts exactly at 02:59.800. These outdoor frames show colored illumination coexisting with the ground's ambient lighting; they do not establish a universal ambient value for enclosed rooms.

Candidate floor-texture registration is recorded by `measure_tiles.py`. The attempted fits are not sufficiently accurate to calibrate an exact brightness transfer function: texture/alignment differences, lamp bloom and video compression remain in the residual. No fitted gains were automatically applied to production settings.

| Time | Visible behavior |
| --- | --- |
| 01:00, 01:30 | Local pools of cool white and green light; enclosed unseen rooms are black. |
| 03:00 | Wall ends cast diagonal black wedges across partially visible floor tiles; edges are slightly feathered. |
| 03:00.4–03:01.5 | Doorway silhouettes change as the player moves through the junction. No Bayer/checker stippling is visible. |
| 04:00, 18:00 | Long geometric shadows from corners and doors; visible wall faces remain readable. |
| 05:00, 12:00, 16:00 | Violet/blue outdoor illumination, with local darker areas and distinct colored sources. |
| 22:00–23:00 | A small visible patch surrounded by black. These frames alone cannot separate equipment light, darkvision, and impairment. |
| 25:00 onward | Injury overlays and later observer imagery differ from ordinary living-player vision; they are not a basis for global brightness tuning. |

## Implementation

- Enable geometric shadows by default, retaining native visibility checks and special sight flags.
- Apply blur size 3 to the shadow plane before subtracting visible wall faces. Registered reference frames measure a 7.65–8.19 source-pixel 10–90% shadow transition; this setting measures 7.77 in the native fixture. This matches the measured feathering, without identifying the reference engine's filter implementation.
- Replace tile snapshots/fades with persistent, private wall-edge meshes. Animate their triangle matrices linearly for the character's glide duration. Keep the silhouettes opaque throughout; split an animation when the eye crosses a wall-edge plane.
- Track the interpolated eye position and remaining glide duration. A stationary Life/opacity refresh does not restart or cancel existing mesh motion; new edges begin at the interpolated eye. Batch nested cardinal steps into one diagonal LOS update, including movement where only one leg succeeds.
- Extend projection through the square viewport's diagonal corners and beyond its edges. Cache both the turf's generated range and each client's displayed range.
- Keep look-far geometry centered on the body and include the shifted viewport in its radius. The tile mask now honors its existing `use_viewer` argument instead of calculating visibility from the camera.
- Render a uniform RGB value over each tile using a solid white texture, replacing the four-corner gradient texture. Average raw samples before exposure; opaque tiles omit corners buried entirely in opaque geometry. Apply a 2-source-pixel blur to the light plane and bloom with threshold `#808080`, size 4 and alpha 110. This follows the user's clarification that the reference is tile based, softened by blur and bloom.
- Use finite circular smoothstep falloff and an exponential exposure response, preserving relative lamp colors. Unlit tiles remain black. These transfer/filter parameters are implementation choices, not recovered settings from the reference engine.
- Route floor-lamp lens appearances additively into the emissive plane. The recessed OS13 fixture uses its existing `floorlight2` lens-only texture, leaving its housing lit normally; square panels use their on/flicker appearance. Clear the emissive overlay on power-off or failure. Previously these fixtures never reached the bloom plane.
- Composite the emissive plane additively over the shaded world, below LOS. A normally blended plane would still replace the underlying scene even when individual lens images inside that plane use additive blending.
- Keep opacity changes and moving opaque objects connected to both light propagation and LOS invalidation.

This changes the shared renderer, not the map's lamp placement, colors, or room geometry. Existing directional awareness, species vision, impairment, equipment and observer behavior are retained.

## Validation

`lighting_los_regression.dme` includes seven focused suites covering eight projection directions, diagonal blockers beyond the old radius, viewport shrink, opening/closing/moving opacity, uniform tile illumination, colored light falloff and occlusion, light removal, body-based visibility across a shifted viewport, independent viewer meshes, interpolated rays, start/stop timing, repeated stationary refreshes, the exposure/falloff response, and floor-lamp bloom through power/damage changes. The runtime checker scans actual errors because BYOND can report a zero runtime counter even after a test runtime.

```powershell
& 'C:/Program Files (x86)/BYOND/bin/dm.exe' lighting_los_regression.dme
& 'C:/Program Files (x86)/BYOND/bin/dd.exe' lighting_los_regression.dmb -invisible -trusted -close 2>&1 | Tee-Object 'tmp/artemis-lighting/runtime-bloom-final.log'
python tools/lighting_los/check_runtime.py tmp/artemis-lighting/runtime-bloom-final.log
```

The normal game, focused build and preview compile with 0 errors and 0 warnings. All seven suites pass with no test-phase runtime errors, including a rerun after the calibrated shadow blur in `tmp/artemis-lighting/runtime-calibrated.log`. The existing Alpha map emits a pre-test `/obj/random/proc/unit_test_spawn_item` error at `(138,98,2)`; database and map power-link diagnostics also occur during startup.

## Interactive fixture and remaining comparison

Compile `lighting_los_preview.dme` and host its DMB locally. It uses the production human HUD and renderer, with white, green and violet lamps, a partition and an opaque door. The Preview tab supplies **Preview Door**, **Preview Lights**, and **Preview Reset**; arrow keys move, and Ctrl-right-click uses the production look-far action. The fixture is included only by the preview DME.

The preview also supports opt-in `-params "los_capture=1"`, which waits for world initialization and exports native map screenshots for a closed door, open door, intermediate movement, stopping, diagonal movement and lights off. Runtime capture diagnostics confirm a 16-decisecond journey at glide size 1, preservation of the journey across a forced stationary refresh, and one completed diagonal update with no remaining movement nesting. Native exports show intermediate shadow positions and black unlit floors. The fixture now uses actual recessed floor lamps.

The final captures are in `tmp/artemis-lighting/native-final/`, with a source-file manifest. In the same 22-by-22-pixel lens region, changing the emissive plane's composition raised channel maxima from RGB 112/101/97 to 255/212/153. An 88-by-120-pixel sample behind the closed wall remained exactly RGB zero. This verifies that emission visibly adds over the lit scene and remains under LOS, without treating the generic fixture as a reconstruction of the reference map. The final native log is `tmp/artemis-lighting/preview-composite.log`; it contains no runtime errors.

Exact visual parity is **not verified** by compilation, server tests or these controlled screenshots. Remaining comparison includes identical scene geometry and lamp parameters, ordinary-speed motion at 60 fps, wall fixtures, rapid door changes, resized views, look-far and special sight/observer views. The source recording alone does not determine hidden lamp values or the reference renderer's exact algorithm.

## Registered shadow-edge calibration

`measure_shadow_edge.py` registers two views of the same floor, then divides the later, partially shadowed pixels by the earlier visible pixels. This cancels the unknown floor texture and local illumination instead of fitting to a different sprite. It rejects registration correlation below 0.9, dark baseline pixels, multiple threshold crossings and invalid edge profiles. The reported 10–90% width is perpendicular to the fitted edge, normalized to a 32-pixel source tile. Reference tiles are approximately 84 display pixels wide; this scale and video compression limit precision.

| Reference time | Accepted profiles | Registration correlation | Width in source pixels |
| --- | ---: | ---: | ---: |
| 03:00.450 | 4 | 0.979 | 7.65 |
| 03:00.550 | 8 | 0.939 | 8.19 |
| 03:00.617 | 6 | 0.970 | 7.81 |

The baseline is 02:59.800. Reports are `frame-study/shadow-edge-40.json`, `shadow-edge.json` and `shadow-edge-50.json` beneath `tmp/artemis-lighting/`. A later frame with registration correlation 0.75 was rejected.

The opt-in `los_reference=1` preview reconstructs the visible junction's wall endpoints, doorway and lamp locations. The two panes immediately east of the player are dense but transparent: in the reference, shadow rays originate from the next solid tile. Unseen topology, floor textures and lamp intensity/color parameters remain provisional. The native calibration compares the same three filter settings in this fixture:

| Shadow blur size | Accepted profiles | Width in source pixels |
| --- | ---: | ---: |
| 1.5 (previous) | 28 | 3.97 |
| 3 (selected) | 21 | 7.77 |
| 3.2 | 18 | 8.38 |

Native screenshots and reports are in `tmp/artemis-lighting/native-calibration/`; the log is `preview-calibration.log`. The latter two pairs register at −29 pixels because the reset camera had not quite settled when the baseline was taken; registration compensates for that translation. The calibration helper now waits longer after resetting. Widths are measurements of these captures, not proof of temporal parity.

Reproduce a measurement with:

```powershell
python tools/lighting_los/measure_shadow_edge.py tmp/artemis-lighting/frame-study/frame_00001.png tmp/artemis-lighting/frame-study/frame_00046.png --template 500 425 560 480 --columns 850 1030 --rows 417 578 --tile-size 84 --output tmp/artemis-lighting/frame-study/shadow-edge.json
python tools/lighting_los/measure_shadow_edge.py tmp/artemis-lighting/native-calibration/blur-3-base.png tmp/artemis-lighting/native-calibration/blur-3-south.png --template 321 129 350 157 --columns 450 560 --rows 194 255 --tile-size 32 --expected-dy -32 --output tmp/artemis-lighting/native-calibration/edge-3.json
```

## Normal movement-input replay

`-params "los_reference=1&los_input_capture=1"` exercises `client.Move → SelfMove` through three southward steps and ten stationary refreshes, using ordinary walk intent. It forces opacity refreshes throughout each glide to check that refreshes neither restart the journey nor snap the eye. `los_move_intent=run` selects ordinary running. Unlike the older slowed capture, this uses production movement-delay calculation.

`check_input_trace.py` verifies destinations, unsnapped starts, monotonic travel, preserved deadlines, endpoint arrival and a stable stopped eye. The walk replay in `tmp/artemis-lighting/preview-input.log` passes all 83 samples, with 11-decisecond glides; its five native exports are in `native-input/`. Those exports predate the transparent-pane fixture correction. These server-side motion samples and endpoint screenshots do not substitute for a 60 fps capture of DreamSeeker's actual animation.

The preview schedules at most one capture per world, including when DreamSeeker reconnects during a second login. The trace checker rejects duplicated completion/start phases. The first run attempt (`preview-run.log`) had overlapping replays from duplicate connections and is invalid evidence; it is retained for diagnosis.

The single-client running replay in `tmp/artemis-lighting/preview-run-final.log` passes all 56 samples, with approximately 6-decisecond glides and ten stable stationary refreshes. Its five native captures and source-file manifest are in `native-run/`. This replay uses the production blur size 3 without a filter override and the corrected transparent panes. It contains no runtime errors. Walking and running checks establish the server's eye/mesh timing through the movement entry point; they do not exercise DreamSeeker's command dispatch or measure client-side frame pacing.

A final measurement of `native-run/initial.png` against `step-1.png` gives **7.84 source pixels** across 16 accepted profiles, with correlation 0.975 and an exact −32-pixel registration. This independently confirms the production setting falls inside the sampled reference range after the fixture's camera has settled. The report is `native-run/shadow-edge.json`.

## Dark wall-edge correction

The supplied dark-room screenshot exposed a lightmap composition bug. Native visibility omits tiles behind opaque walls, leaving the lightmap's white fullbright backing next to those walls. Blur/bloom sampled that backing and exposed wall outlines even with all lamp samples at zero. Disabling only the lighting filters removed the outlines in the diagnostic, establishing that the leakage came from composition rather than residual lamp power.

Opaque boundaries now provide cached black padding below the real light samples. Visible tile samples replace the padding; the light plane still multiplies the resulting lightmap onto the world. Padding excludes nondynamic neighbors, is removed when a door/wall opens, and refreshes when neighboring lighting coverage changes. Both samples and padding use topdown layer ordering because this game's `SIDE_MAP` format otherwise orders sprites by position. [BYOND's rendering/layer reference](https://www.byond.com/docs/ref/info.html) describes this distinction. Emissive rendering and the blur/bloom settings are retained.

`los_dark_capture=1` builds an enclosed room with its wall boundary inside the viewport, matching the reported case. It renders the old composition and corrected composition in the same native client/world, with lit, dark-filtered and dark-unfiltered captures for each. Accepted captures are in `tmp/artemis-lighting/dark-room/{before,after}/`; the log is `preview-dark-room.log`. The measurement script verifies unchanged HUD registration and excludes the HUD from the dark-pixel count.

| Native enclosed-room measurement | Old composition | Corrected composition |
| --- | ---: | ---: |
| Nonblack pixels with lighting filters enabled | 10,106 | 0 |
| Maximum RGB channel with lighting filters enabled | 63 | 0 |
| Nonblack pixels with lighting filters disabled | 0 | 0 |

The sampled lit floor's mean channel brightness changes by at most 0.097/255 and its per-channel standard deviation by at most 0.037/255. This is a brightness/contrast control, not pixel equality: individual pixels differ by up to 15/255, with correlation 0.951. These values are retained in `after/comparison.json` rather than described as an identical lit render.

```powershell
python tools/lighting_los/check_dark_capture.py tmp/artemis-lighting/dark-room/before tmp/artemis-lighting/dark-room/after
```

The focused colored-light suite also checks opaque-boundary padding, opening a boundary, and preserving a nondynamic neighbor. Earlier `dark-after`, `dark-fixed`, `dark-final` and oversized `dark-ab` captures are diagnostic attempts, not accepted verification. The oversized open-scene diagnostic also revealed a separate viewport-edge fringe where visible floors reach the screen boundary; this wall-boundary fix does not claim to repair that fringe. The attempted viewport-backing changes were removed.

The final main, preview and focused builds compile with zero errors/warnings. `runtime-dark-room.log` passes all seven suites with no test-phase runtimes; the existing pre-test random-object startup runtime remains separate. `preview-dark-room.log` contains no runtime errors.

## Dark corners and rectangular wall spots

A thick room corner has only one exposed lighting corner. Averaging its sample with three permanently buried samples reduced its brightness to a quarter before exposure. `lighting_tile_rgb` now excludes corners whose surrounding turfs are all opaque. Exposed samples with zero illumination still count, so this adds no ambient light. Opacity changes refresh the affected neighboring tiles.

The old wall mask also erased rectangular strips to conceal offset fixtures behind a visible wall. It now keeps the wall mask solid and hides the unseen object with a viewer-specific override image instead. Offset/movement changes are checked even while the viewer is stationary; fixtures on visible tiles remain visible.

The `los_spots_capture=1` fixture reproduces both defects using a thick rectangular room and an offset fixture behind its east wall. Native captures in `tmp/artemis-lighting/spots-before/` and `spots-after/` show:

- The 16-by-32 east-wall patch changes from 512 black pixels to 512 visible wall pixels, with no red far-side fixture exposed.
- Mean corner brightness rises from 42.14 to 98.43/255; the adjacent straight wall sample is 109.59/255 after correction. Remaining variation comes from lamp falloff.
- With the lamp off, the inspected room region contains zero nonblack pixels before and after the changes.

The focused tests cover buried versus exposed-zero corner samples, solid wall masks, offset removal, and moving a fixture onto the visible side. All seven suites pass in `runtime-spots.log`, with no test-phase runtimes and the separately reported pre-test random-object runtime.

## Start/stop camera synchronization

The body and LOS meshes already used explicit glide timing, but the body-following camera retained `client.glide_size = 0`, allowing BYOND to choose a separate scrolling speed. The client now uses the body's glide size while enhanced LOS follows that body. The override is set before movement, remains in place while stopping, and restores the previous setting for remote eyes, disabled LOS, or special sight. A mob using `NO_STEPS` also snaps its LOS rather than animating a journey the mob does not take. See [BYOND's glide-size reference](https://www.byond.com/docs/ref/info.html) for automatic versus explicit camera gliding.

The native input replay checks camera/body speed equality at every step and checks restoration when switching to a remote eye and back. Its existing checks still cover continuous eye position, unchanged glide deadlines, and ten stationary refreshes. `los_frame_capture=1` adds intermediate map exports for diagnosis. These exports capture shadow animations but do not reliably record the viewport's intermediate scrolling, so they are not evidence of smooth live camera frame pacing. Full temporal parity still requires a live-window recording; the computer-use window inventory did not expose the hidden test client.

Final validation: main game, preview, and focused builds all compile with zero errors/warnings. `preview-motion-after.log` passes all 56 input trace samples, camera synchronization and remote-eye restoration checks, with no runtime errors. `runtime-motion-final.log` passes all seven focused suites with zero test-phase runtimes; the existing pre-test `/obj/random/proc/unit_test_spawn_item` runtime remains. The running user world was not restarted; restart it to load the rebuilt main DMB.

## Live start/stop twitch: completed image reuse

The camera-speed change above did not resolve the reported twitch. A 60 fps native-window capture of actual play (`player-los-live.mp4`) shows a one- or two-frame backward shadow change before the camera begins scrolling. At 9.900 seconds the sampled shadow slope changes from approximately -0.438 to -0.364 while the wall and lamp remain stationary, then returns to -0.429 as scrolling starts. Server eye-position traces and BYOND map exports missed this behavior.

The preview now dispatches the production `.moveright` and `.moveleft` commands through DreamSeeker with `winset(command=...)`. Its legacy/corrected comparison uses identical run movement and pauses. Testing regular-tick movement verbs, `ANIMATION_END_NOW`, explicit transform resets, and a zero-duration starting animation did not remove the twitch. Those experiments were removed. A fresh image for the next completed movement did remove it in the native capture; this isolates reuse of completed animated images as the trigger without claiming an engine-internal explanation.

`update_opacity_image` now retires the previous private mesh images before a new glide when the previous journey has finished. Replacement images start at the sampled eye position and animate to the destination. In-flight images are retained on interruption, and stationary refreshes do not replace images or restart animation. The wall coordinates, triangle geometry, opacity, blur, lighting and production movement bindings are unchanged by this correction. This costs new private images at completed-step boundaries; large multiplayer performance has not been benchmarked.

The preview-only `ARTEMIS_LOS_PREVIEW` switch enables the old image lifecycle for the comparison. The main build always uses the corrected lifecycle. Launch the preview with `los_reference=1&los_twitch_capture=1&los_twitch_wait=1`, wait for `ARTEMIS_TWITCH_READY`, and start a native window recording of `LOS-Transition-Regression`. Then write `start` to `tmp/artemis-lighting/twitch-replay-trigger.txt`. The fixture consumes that file and runs eight legacy steps, eight corrected steps, and eight repeated-input steps with direction changes. It checks retired-image removal and preservation of active images across forced stationary refreshes. `ARTEMIS_TWITCH complete` is required, with no `ARTEMIS_TWITCH_FAILURE` lines. It returns to corrected mode for interactive play.

The first final-production capture, `twitch-final-live.mp4`, contains all sixteen paused comparison steps: maximum wrong-way slope excursion falls from **0.26734** to **0.01407**; maximum corrected stopping excursion is **0.01758**. Measurements use the same wall-relative edge in the 1920-pixel-wide native window, and the remaining variation is comparable to pixel/blur sampling noise (approximately 0.01-0.02). Its continuous phase was incomplete because the original replay sent one command before the cooldown expired; it is evidence for the paused comparison only. The replay now retries input at tick intervals like a held key.

The accepted repeat is `twitch-accepted-live.mp4`, with the complete `preview-twitch-accepted.log` and no replay failures or native-preview runtimes. Its sixteen paused comparison steps give maximum wrong-way excursions of **0.26909 before** and **0.00874 after**; maximum corrected stopping excursion is **0.00969**. All eight repeated-input direction changes complete and return to the starting position. Across 480 sampled frames covering that phase and its final stop, the maximum deviation from the stationary-calibrated edge slope is **0.02760**, without the earlier backward spikes. `twitch-accepted-summary.json` records these measurements. The fixed crop, lamp positions and edge-fitting assumptions in the local analysis scripts apply only to this reference fixture and window size; they are not a general gameplay benchmark.

`los-before-after-slow.mp4` is a three-times-slower side-by-side excerpt from the first final-code comparison: old image reuse on the left, corrected lifecycle on the right. It is cropped for inspection; the full native captures retain the original timing and viewport.

The main game, focused regression and final preview compile with zero errors/warnings. `runtime-image-lifecycle.log` passes all seven suites with zero test-phase runtimes and one separately reported pre-test random-object startup runtime. These focused native captures establish the sampled transition behavior, not full visual parity with every frame of the Artemis recording. The obsolete preview on port 14446 was closed; port 14447 remains open in corrected mode for interactive play. The main DMB has been rebuilt; an already-running main world must restart to load it.

## Tile glow and lamp spectrum, 2026-10-27

The next lighting audit separates illumination from an additive glow. `measure_bloom_veil.py` compares two matching grated-floor patches in 22 consecutive decoded frames at 179.800–180.150 seconds. Their detail correlation exceeds 0.9 after registration. An affine comparison gives an additive RGB offset of **32.56, 28.02, 25.03** in addition to a multiplicative gain. The patches are unchanged across these frames, so these are repeated observations, not 22 independent estimates. This is consistent with a broad glow around the bright pool; authored differences between the floor variants remain a confound. It does not uniquely recover the original renderer's algorithm.

Searching the local turf atlas, including directional variants, still does not produce a sufficiently accurate texture match for absolute exposure calibration. `match_reference_tiles.py` removes broad lighting gradients when ranking candidates and reports correlation and residuals rather than silently accepting a poor match. The fixture's floor textures, square-versus-round white fixture and lamp values remain provisional. The exposure curve and lamp ranges were not fitted to these mismatched assets.

The renderer now adds a blurred contribution from actual lit tiles. Its source is separate from the multiply lightmap's white fullbright backing, preventing that backing from becoming a glow source. Source RGB is `tile_rgb * (0.2 * peak(tile_rgb))`, with blur size 8. This keeps the effect tile based, preserves the emitted spectrum and suppresses weak spill quadratically. These parameters are a visual matching choice, not recovered engine settings. The additive display stays below LOS and above the shaded world. Plane copies use `SCREEN_SOUTHWEST` to remain registered to the map, including HUD borders, as described by the [BYOND screen-location reference](https://www.byond.com/docs/ref/info.html#/atom/var/screen_loc).

Glow colors follow the existing lighting transition time. A black tile immediately cancels its glow animation and becomes black; deleting the tile lightmap also deletes its glow source. The source is created only after a tile is lit and is protected from explosions and singularity movement, like the lightmap itself. This introduces one additional render atom for each tile that has been lit; large multiplayer performance has not been benchmarked.

The recessed floor lamp's authored `floorlight2` texture is amber. Multiplying it by the configured lamp color kept white lamps amber and suppressed blue emission. Its red channel now supplies a neutral brightness mask, tinted by the configured color for both the visible lens and the emissive pass. The unlit housing stays on the world plane; damage and power changes retain their existing behavior. The unit suite renders actual white and blue lens pixels through the color matrix to verify their spectrum and retained brightness.

Native comparison exports and reports are in `tmp/artemis-lighting/lighting-audit/`:

| Sample | Tile light only, RGB mean | With tile glow, RGB mean |
| --- | --- | --- |
| White-lit floor | 35.76, 36.39, 36.93 | 72.57, 73.90, 74.51 |
| Green-lit floor | 31.95, 65.54, 33.94 | 47.84, 100.56, 53.11 |
| Fully occluded region | 0, 0, 0 | 0, 0, 0 |

Half-strength captures confirm proportional control within three channel levels. The occluded sample is inside the opaque shadow, away from its deliberately feathered edge, which already contains nonblack pixels without glow. The enclosed-room lights-off capture (`room-dark.png`) has **zero nonblack pixels**, maximum channel **0**, in the 458-by-400-pixel inspected map region. The separate junction capture has a maximum of 2 in its larger dark sample and is not described as an exact-zero result. `lighting-comparison.png` shows the native glow comparison without color grading.

Reproduce the measurements with:

```powershell
python tools/lighting_los/measure_bloom_veil.py tmp/artemis-lighting/frame-study --output tmp/artemis-lighting/lighting-audit/reference-veil.json
python tools/lighting_los/check_veil_capture.py tmp/artemis-lighting/lighting-audit
python tools/lighting_los/check_runtime.py tmp/artemis-lighting/lighting-audit/runtime-veil-final.log
```

Use `los_reference=1&lighting_halo_capture=1` for the junction comparison, or `los_dark_capture=1&lighting_halo_capture=1` for the enclosed room. The preview captures three strengths and a blackout, then restores the lamps. The initial lamp-only wide-bloom experiment and the misaligned tile-glow capture are diagnostic attempts, not accepted validation.

The final main, preview and regression builds compile with zero errors/warnings. All seven suites pass, including immediate glow removal, glow-source cleanup and neutral lens pixels, with zero test-phase runtimes. The existing pre-test random-object startup runtime remains separate. The unused preview on 14447 was closed; the updated interactive junction is on 14448. This improves the measured lighting behavior, but perfect pixel parity across the full video remains unverified.

## Projected drop shadows, 2026-10-27

The indoor character crops at 01:30, 03:00 and 10:00 show projected floor silhouettes. The 03:00 shadow extends down-left and the 10:00 sample extends down-right. A later frame-by-frame review found that the outdoor 05:00 rectangular dark patch remains attached to scenery; it must not be used as a character-shadow measurement. These are observations from the supplied recording, not a recovery of its original shader parameters.

The existing dynamic-shadow renderer was disabled globally. It is now enabled for living mobs, raised structures and machinery, retaining its exclusions for doors, wall mounts, flat structures and render effects. Recessed floor lamps are explicitly excluded. Silhouettes use the composed sprite, a black color filter, blur size 1 and a foot-anchored floor projection, below the lighting, emission and LOS passes. Existing length, flattening and alpha limits remain visual approximations; full pixel parity is not established.

Source strength now comes from actual corner contributions and emitted RGB, incorporating cone direction and occlusion instead of estimating from distance alone. Up to three silhouettes retain their own light-source identity when source strengths trade rank. Stationary refreshes leave an unchanged projection animation alone, blocked moves do not restart it, teleports replace the previous silhouettes, and the first frame is already projected onto the floor. Copies omit map text, underlays, render-source links and overlays on separate planes so those do not become visible duplicates. They also clear collision and screen-location properties. Native gliding uses the owner's glide speed and diagonal-glide flag.

Shadow direction uses the light fixture's alpha-weighted sprite centroid, including transparent padding, large sprite dimensions, pixel offsets and the appearance transform. Sampling is cached by icon, state and direction, using the first animation frame to avoid a flickering origin. Coordinates remain continuous when a fixture crosses a half-tile pixel offset; the previous quantized `pixel_turf` no longer determines its shadow direction. Carried lights use the displayed top atom, consistent with the lighting system's attachment model.

Ambient occlusion now uses layer 2.015, between turf detail and ground decals. Its images inherit the terrain plane and opt out of a parent's combined draw group. This keeps AO below ordinary ground objects and mobs, including when the overlay is attached to a lower-Z lighting copy. It does not move illumination or LOS masks below actors.

The eighth focused suite checks opposing lamp directions, unchanged projection revisions, stable source identity when brightness ranks swap, zero-RGB emitters, text/emission exclusions, container cleanup, complete light removal and recessed-lamp exclusion. Main, preview and focused builds compile with zero errors/warnings; `tmp/artemis-lighting/drop-shadows/runtime.log` passes all eight suites with zero test-phase runtimes. The pre-existing random-object startup runtime remains separate.

The preview parameter `drop_shadow_capture=1` captures disabled, enabled and lights-off states, then restores lighting and interactive movement. Pair it with `los_dark_capture=1` for the enclosed room. Add `drop_shadow_wait=1`, wait for the native viewport to load fully, and write `start` to `tmp/artemis-lighting/drop-shadow-trigger.txt` to begin. The fixture holds the actor still and temporarily removes film grain. Earlier pairs affected by camera movement, animated grain or a still-loading client are diagnostic attempts, not accepted comparisons. `tools/lighting_los/compare_drop_shadows.py` checks stationary 608-by-480 exports named `before.png`, `after.png` and `dark.png`, records the image differences, and creates an ungraded side-by-side crop. Such exports validate static composition; they do not replace a live-window movement recording or multiplayer performance testing.

## Shadows across neighboring floors and opposing light, 2026-10-29

Shadows are enabled again. The reported cross-tile disappearance came from `SIDE_MAP` depth sorting: a fractional floor-shadow layer still allowed a neighboring turf to draw over the silhouette. Terrain and shadows now have separate hidden source planes. Two `BACKGROUND_LAYER` displays compose terrain first and shadows second inside the existing world plane, before ordinary objects and mobs. Physical objects retain their original depth sorting. Underfloor objects travel with terrain, overhead turfs retain their foreground plane, and terrain mouse hits pass through to the source. AO travels with the terrain and remains below physical objects and mobs. Copied physical sprite overlays inherit the shadow plane so they cannot escape the silhouette filter.

The native exports in `tmp/artemis-shadow-20261029/accepted/` establish the cross-tile correction. After `GaussianBlur(2)` suppresses animated capture grain for measurement, 178 pixels in the character's southern neighboring tile and 275 in the crate's southern neighboring tile darken by more than three channel levels. Maximum smoothed darkening is 26/255, with no pixels brightened by more than three levels. The ungraded comparison image retains the original screenshot pixels. The inspected terrain rectangle `(112, 64, 570, 440)` contains zero nonblack pixels with the lamps off; HUD hover text is excluded. These exports prove static cross-tile composition, not live motion timing.

Each silhouette now samples actual illumination on the receiving floor. Other lights attenuate a local alpha mask in proportion to their contribution relative to the casting light. Equal or stronger opposing illumination cancels that portion completely. Contributions use the lighting system's applied corner values and emitted RGB, so cone aim, range, power and opaque walls govern cancellation. Sources on the caster's opposite side fill the shadow; sources behind the caster retain the shared projection. The directional fill factor is a clamped dot product, a visual approximation rather than a recovered three-dimensional visibility model.

The mask samples a four-pixel grid in the sprite's local space, maps those samples through its projected transform, and reads the receiving tiles. It is applied to the composed silhouette before its existing blur, using BYOND's [alpha-mask filter](https://www.byond.com/docs/ref/info.html#/filter/alpha). A beam can therefore fill the end of a shadow without illuminating the caster. Per-tile samples are reused within an update, and an unchanged mask does not create a new icon or restart the projection animation. Large multiplayer performance and exact temporal alignment during projection changes have not been benchmarked.

The focused suite checks weak and strong opposing light, same-side lamps, a cone aimed away and toward the receiving tile, an opaque intervening wall, alpha-filter installation, and unchanged stationary masks. `regression-fill.log` passes all eight suites with zero test-phase and zero startup runtimes. Main, preview and regression builds compile with zero errors and warnings. Native fill comparison uses `los_dark_capture=1&drop_shadow_capture=1&drop_shadow_wait=1&drop_shadow_fill_capture=1`; after `ARTEMIS_DROP_SHADOW_READY`, the normal trigger file runs pairs with identical illumination and masked/unmasked shadows. This comparison is separate from server assertions. Full video parity remains unverified.

The completed native comparison is in `tmp/artemis-shadow-20261029/fill-accepted/`. With the beam aimed away, no receiving-floor pixels change by more than three channel levels. Aiming the beam at the silhouette restores 190 receiving-floor pixels by more than three levels, up to 58/255. The unchanged-light control region differs by at most two levels in both pairs after grain suppression. The lights-off terrain rectangle has zero nonblack pixels. `check_shadow_fill_capture.py` verifies these controls and produces an ungraded four-panel crop. The first clients disconnected before the viewport loaded; the accepted client completed the sequence without preview runtimes. That successful capture does not establish a general client-crash fix.

## Light-relative character silhouettes, 2026-10-29

Character shadows now use the sprite direction seen from the casting lamp. A character facing down presents a profile to side lamps; a character facing toward a side lamp presents the front sprite, and facing away presents the back sprite. The relative angle comes from the lamp's continuous visual center and the character's facing, rounded to an authored cardinal sprite. Equipment and nested physical overlays receive the same selection. The real character retains its direction, and structures keep their original sprite direction.

The former projection kept the sprite-width axis horizontal while its height axis turned toward the cast direction. These axes became almost parallel under side lighting, collapsing silhouettes into lines. Both axes now rotate together on the floor before applying its existing vertical perspective scale. The projected area at a fixed length is independent of lamp angle, and the pivot remains at the feet. Overlay-only bodies, used by the procedural walking animation, remain eligible for shadows when their main icon is null.

The focused regression checks eight projection angles for equal nonzero area and a fixed foot anchor, front/back/profile selection, nested equipment direction, unchanged real facing, and overlay-only body eligibility. `regression-direction.log` passes all eight suites with no startup or test-phase runtimes. Native comparisons use `drop_shadow_direction_capture=1` alongside the standard enclosed-room capture/wait flags. They compare historical and corrected geometry for west, east, north and south lamps, with the character facing south and east. Historical projection code exists only in this opt-in preview path.

## Approaching the horizontal light axis, 2026-10-30

Drop-shadow animations now use `ANIMATION_LINEAR_TRANSFORM`, matching the existing LOS mesh animation. BYOND's default animation decomposes a transform to preserve size during rotation; that is inappropriate for these reflected, sheared floor bases around their sideways orientation. Direct interpolation keeps each basis coefficient and its foot-anchoring translation on the same path. Unchanged targets still return without restarting animation. The composed filter group is refreshed after assigning a changed projection, rather than being left prepared for its previous matrix.

`drop_shadow_rotation_capture=1` adds a native comparison behind the standard enclosed-room capture/wait flags and trigger. It runs north, north, south, south on each side of a lamp, first with default interpolation and then with linear interpolation. Both modes use the production `Move` and shadow-update path with deliberately slow native glides; this isolates rendering from input cooldowns. The legacy switch is compiled only into the preview. The main game always uses linear interpolation.

Main, preview and regression builds compile with zero errors and warnings. `tmp/artemis-shadow-20261029/regression-rotation.log` passes all eight suites with zero startup and test-phase runtimes. The 60 fps native recording is `rotation-live.mp4`; `rotation-preview-error.log` records all sixteen completed glides and no preview runtimes. `rotation-trace.json` verifies their target directions and foot anchors independently of the recording. Endpoint traces do not prove intermediate rendering, and the deliberately slow scripted replay does not establish full gameplay/video parity.

`rotation-comparison-slow.mp4` places the west-lamp replay with previous interpolation on the left and linear interpolation on the right, cropped and slowed by three times. It retains the captured colors. The exploratory `rotation-measurement*` files are excluded from acceptance evidence: their registered floor maximum also captures lighting/texture differences and does not reliably isolate a shadow, so its slope estimates must not be reported as a rotation measurement.

## Composed foreground AO prototype, 2026-10-31 (superseded)

AO now follows [tgstation's game-world render plate](https://github.com/tgstation/tgstation/blob/master/code/_onclick/hud/rendering/render_plate.dm): a drop-shadow filter on the composed foreground, using x=0, y=-2, size=4 and color `#04080FAA`. In this renderer terrain already sits below the foreground. The filter draws contact shading behind the combined physical objects and mobs, so another object's shadow cannot cover an opaque wall-light or window pixel. Lighting, emission and LOS remain separate later passes.

This replaces the legacy per-floor corner overlays. It also removes the experimental sprite raster masks, mask caches, and wall-light invalidation hooks from the earlier attempts. The old turf AO methods remain inert compatibility hooks for turf replacement and multiz callers; the AO subsystem no longer runs. No turf or fixture planes are promoted. Static wall terrain no longer receives the old corner-sprite shading. This adapts tgstation's AO method, rather than importing its entire rendering or multiz framework.

The focused suite checks that tile AO stays inactive, the foreground filter is installed, mouse routing remains enabled, and floor/wall/lamp/window planes retain their ordering. The opt-in native `ao_elevator_capture=1` preview loads the actual OS13 classic lower-elevator landmark at `(135,125,1)` and captures AO on/off without rebuilding the map. Earlier synthetic floor-lamp/window captures did not reproduce the reported scene and are not acceptance evidence for this rework.

Final validation: main, regression and preview builds compile with zero errors/warnings. All nine focused suites pass with zero startup and test-phase runtimes (`tmp/ao-tg/runtime.log`). The powered native on/off capture completed at `(133,127,1)`, beside the lower elevator, in `tmp/ao-tg/elevator-final.log` without runtimes. The fixture stops the startup cryo light pulse and powers existing wall lamps, preserving mapped geometry, offsets and LOS. `elevator-on.png`, `elevator-off.png` and `elevator-detail.png` record the inspected view. Sharp black visibility wedges remain part of LOS, not AO. Earlier dark/startup captures are not the accepted visual check. Restart an existing world to load the rebuilt main DMB.

## Floor-only contact shading prototype, 2026-10-31 (superseded)

The foreground-filter prototype above could draw its AO over objects on lower planes and onto raised wall terrain. AO now has a separate shadow-only display above terrain and below plane-zero objects, ordinary objects and mobs. The foreground plane supplies its unfiltered alpha silhouette through `world_ao_casters`; its normal colors and mouse routing remain unchanged. The AO display tints that silhouette to `#04080FAA`, offsets it downward by two pixels and blurs it by four pixels. It draws no duplicate foreground textures.

A hidden receiver pass restricts the result to nondense, nonopaque floor turfs with `permit_ao` enabled. Walls, space and open shafts do not provide receivers. Each eligible floor has one shared-white-icon overlay; the compatibility hooks maintain it without reintroducing per-corner shading or a processing queue. Floor creation, opacity changes and sprite refreshes update the mask, and turf destruction removes it. Fixture and mob planes retain their existing ordering.

The focused AO suite checks the unfiltered caster pass, the separate draw order below plane zero, floor-only masks, constructed floors, opacity changes, receiver disabling and sprite refreshes. The `ao_object_probe=1` option extends the mapped `ao_elevator_capture=1` comparison with a solid blue object on plane zero, under the foreground caster plane. Paired AO on/off captures distinguish object protection from simply disabling AO everywhere.

## Doors share wall LOS culling, 2026-10-31

Opaque doors already generated the same wall-edge LOS meshes. The door type nevertheless bypassed native culling through `los_never_cull` and insertion into its turf's `vis_contents`. That exception is removed. The fallback visible-boundary test now recognizes `opaque_counter`, including an opaque object on a floor, rather than accepting only opaque turf types. It exposes the same viewer-facing boundary for a closed opaque door and a wall. Transparent doors retain their authored transparency.

The real-door regression compares its complete LOS geometry and boundary mask against a wall occupying the same tile. It also checks near versus far boundary visibility, normal culling without a visual-content exception, actual opening and closing, and a transparent glass airlock. These checks are part of the nine-suite lighting/LOS regression.

## Ambient occlusion disabled, 2026-10-31

AO is completely disabled at the user's request. The HUD no longer creates any AO plane masters or displays. Turf hooks perform cleanup only and cannot generate corner overlays or receiver masks, even when a map sets `permit_ao = TRUE`. Compatibility screen types have no filters, render targets or render sources, and their display is invisible. The AO subsystem remains inactive. Directional light-source drop shadows and LOS are separate effects and remain enabled.

The AO regression now checks that construction, opacity changes, turf replacement and legacy hooks cannot reactivate AO. Existing worlds must restart to load this change.

The main and focused builds compile with zero errors and warnings. `tmp/artemis-ao-disabled-runtime.log` passes all nine lighting/LOS suites, including globally disabled AO and real-door wall equivalence, with zero startup or test-phase runtimes.

## Foreground LOS occlusion, 2026-10-31

The first sprite-edge correction exempted the entire native foreground from LOS. Native visibility can still draw pixels behind the custom wall rays, so that exemption revealed concealed objects. Foreground alpha now passes through a sharp copy of the animated LOS geometry before providing protection from the floor's blurred edge. Both copies share wall masks, projection matrices and animation timing. Visible objects retain their normal texture and lighting; concealed pixels cannot exempt themselves from LOS. AO remains disabled.

Main, preview and regression builds compile with zero errors or warnings. All nine suites pass with zero startup or test-phase runtimes in `tmp/artemis-object-occlusion-runtime.log`. The mapped native corrected/broken/corrected comparison in `tmp/object-occlusion/` includes a visible cyan sprite and a pixel-offset sprite behind a wall. Both corrected captures make the concealed probe exactly black; the broken pass reveals it. The visible probe remains clear across the three captures. Existing previews must be relaunched to load this correction.

## Human-only directional shadows, 2026-10-31

Standing `/mob/living/carbon/human` casters use the rotating projection basis and select a front/back/profile sprite relative to the light. Humans with `lying` set use the same projection and their own facing as objects: horizontal width, flattened shear and a minimum projected height of 0.2. Standing up restores the directional projection. Nonhuman living mobs also use the object behavior. Shared lighting, fill-light cancellation, composition and animation remain in the same rendering path. The focused shadow suite compares prone humans with objects across four facings and five light offsets, then checks the return to standing behavior.

Main and focused builds compile with zero errors or warnings. `tmp/artemis-human-only-shadows-runtime.log` passes all nine suites with zero startup and test-phase runtimes. This change has server regression coverage; a new native gameplay capture was not performed.

## Rear walls obey LOS, 2026-10-31

Native-visible wall tiles no longer receive unconditional protection from every LOS ray. The wall-mask pass orders white wall faces with black copies of the projected rays, then converts the resulting white pixels to mask alpha. Each face remains above its own shadow while nearer faces can cover farther walls. Contiguous straight faces share a depth so adjacent wall tiles do not cut sawtooth holes into one another. Face bounds are cached and invalidated with opacity changes.

All wall-mask images and their ray copies share the viewer's turf anchor with visual-only `pixel_w`/`pixel_z` offsets. This is required by `SIDE_MAP`: different map rows or physical `pixel_x`/`pixel_y` offsets otherwise override the fractional depth layers and reveal rear walls. The existing soft floor edge and sharp foreground LOS use the resulting wall mask; their ray transforms and animation timing remain shared. AO remains disabled, and directional character shadows remain human-only.

Main, preview and focused builds compile with zero errors and warnings. `tmp/artemis-wall-depth-runtime.log` passes all nine suites with zero startup or test-phase runtimes. Native screenshot exports became misleadingly dark during the anchored-mask tests, so acceptance uses captures of the live DreamSeeker window instead. `tmp/wall-depth/live-verified-comparison.png` and `live-report.json` compare the mapped elevator area before and after the visual-offset correction: the covered rear-wall sample changes from mean RGB 81.01 to exactly black, while the exposed front-wall sample remains approximately 105 versus 104.37. The local recording is `live-comparison.mp4`. Existing previews must be relaunched to load the rebuilt game.

## Complete exposed wall corners, 2026-10-31

Wall tiles bordering a directly visible front floor now retain their complete authored appearance. L-shaped joins also qualify when their two connected wall neighbours border a visible diagonal floor. A cell-interior ray trace distinguishes those exposed corners from screened rear walls. A ray may graze an opaque grid corner only when that blocker touches the protected wall; a distant wall cannot gain visibility through the tip of a nearer silhouette. Floor LOS geometry and its interpolation are unchanged.

Main, preview and focused builds compile with zero errors or warnings. `tmp/artemis-wall-corners-runtime.log` passes all nine suites with zero startup and test-phase runtimes. The added cases cover exposed diagonal caps, L-shaped joins in all four quadrants, blocked rear walls and distant walls behind a grazing ray. The live corrected/previous/corrected recording is `tmp/wall-corners/live-comparison.mp4`; its inspected frames and pixel checks are in `live-verified-comparison.png` and `live-report.json`. All four marked corner samples are visible in both corrected states and black with the prior clipping rule. The screened rear-wall sample remains exactly black in all three states. Restart an existing preview to load the correction.

## Partly covered rear-wall tiles, 2026-10-31

The visible-front-floor rule alone could protect a whole rear wall tile even when its farther edge crossed a separate wall's LOS shadow. Whole-tile protection now also checks rays to all four footprint corners. The tested wall, adjoining caps and its connected straight wall runs are treated as the same local surface; other blockers prevent the exemption. The normal depth mask then clips the covered part of the rear tile. This preserves the exposed corner joins without revealing the marked rear sections.

The focused cases include a visible front-floor center with a screened wall footprint, a partially screened L-joint, and exposed corners beside longer straight runs in all four orientations. The preview-only legacy flag reproduces the earlier leaking promotion for the native comparison; production has no legacy toggle.

Main, preview and focused builds compile with zero errors or warnings. `tmp/artemis-wall-footprint-runtime.log` passes all nine suites with zero startup and test-phase runtimes. The live corrected/previous/corrected recording and registered comparison are in `tmp/wall-footprint/`. The two marked samples change from mean RGB 80.31 and 92.33 in the previous mask to exactly black in both corrected states. All four exposed corner samples remain visible across the three states; the earlier screened rear-wall sample also stays black. `live-report.json` records the frame selection and registration against an unchanged stair texture, accounting for the client's startup backbuffer resize. Existing previews must restart to load the rebuilt game.

## Recorded movement and wall-cap continuity, 2026-10-31

The supplied `2026-10-31 16-54-16.mp4` was reviewed across its gameplay segment, with all 2,520 frames extracted at 60 fps and dense samples around the stair caps, lift walls and movement reversals. The wall-protection pass used destination-tile visibility while the projected rays and camera were still gliding. Native visibility also removed some connecting wall appearances before the geometric boundary reached them. These were separate sources of abrupt corner changes.

Wall-mask candidates now include opaque boundaries independently of native visibility. Whole-cap eligibility uses the fractional gliding viewpoint and refreshes through the existing motion deadline. Each black mask ray animates its depth and transform together in one sequence, including edge-plane crossing steps; the white wall masks sample the same moving eye. Only exposed, natively culled boundary caps receive retained physical appearances. Copies exclude mobs, nonopaque contents, emission and other auxiliary render passes, preserve the real source appearance, and are removed when no longer needed. Camera/LOS motion deadlines and stationary mesh reuse remain unchanged. AO stays disabled.

`tools/lighting_los/video_motion_route.json` records 80 positions recovered from the fixed orange/green board in the video, starting at `(130,128,2)`. Thirteen intermediate positions are inferred across tracking gaps. The opt-in preview parameter `video_motion_capture=1` waits for `tmp/review-20261031-video/replay-trigger.txt`, then compares the previous wall behavior against the correction on the same 79-move route. Add `video_motion_corrected_only=1` for one corrected pass. The replay uses native movement glides with scripted `Move` calls; it does not reproduce exact keyboard inputs or procedural gait. It powers existing lights and freezes lighting/shadow processing for the comparison.

Exploratory recordings `native-replay.mp4` and `native-final.mp4` in `tmp/review-20261031-video/` exposed flashes of retained remote walls. The subsequent `native-accepted.mp4` eliminated those flashes but exposed a narrow rear-wall slice in a moving frame, so it also failed visual review. These are rejected visual checks. The final approach combines ray depth with transform animation and limits retained appearances to exposed caps. The server regression covers fractional-eye visibility, matching animated depth endpoints, candidate alignment and physical-only appearance copying alongside the existing rear-wall, corner, object-occlusion and real-door cases.

Final validation: main, preview and regression builds compile with zero errors and warnings. `tmp/artemis-video-motion-synced-runtime.log` passes all nine suites with zero startup and test-phase runtimes. `tmp/artemis-video-motion-synced-preview.log` records all 79 corrected moves and completion without failed moves or preview runtimes. The live recording is `tmp/review-20261031-video/native-synced.mp4`. Its overview and targeted moving-frame comparison were inspected separately from the server tests.

`verified-wall-motion-comparison.png` compares the rejected intermediate rear-wall slice against the final glide. `synced-probe-report.json` uses the fixed board to register the same wall rectangle in eleven nearby 60 fps frames: the intermediate sample contains 280 pixels above channel level 25, while all eleven corrected rectangles contain zero. This is a focused occlusion check, not full lighting/video pixel parity. The GDI recorder stopped after 59.25 seconds with capture error 8, after the full replay and stationary tail were recorded. The preview client had exited by cleanup; no matching Windows Application crash report was found. This run does not establish a client-crash fix. Existing game worlds must restart to load the rebuilt main DMB.

## Light through upper and lower decks, 2026-11-03

Lights now trace straight 3D paths through `ZM_ALLOW_LIGHTING` apertures in connected decks. Light spreads across the receiving level in both directions, rather than copying only the column beneath each opening. Solid floors and opaque contents block the path; rays check side cells at tied grid boundaries to prevent corner shortcuts. Each deck adds two horizontal tiles of distance (`LIGHTING_Z_HEIGHT`) to the finite radial falloff. Source color is preserved, and directional lights retain their beam shape with vertical attenuation.

Initial application and visibility updates share the same footprint calculation. Cross-deck paths subscribe to their blocking turfs as well as visible ones, so opening a blocked door restores light. Turf replacement also invalidates changes to vertical light passage, including creating the first opening beneath a lit room. Removing a source clears both its light contributions and visibility subscriptions. Rooms without a visible aperture use native same-deck visibility without cross-deck ray scans.

An overwritten Z-mimic hole samples the visible bottom surface's lightmap, while the existing Z-copy multiplier retains the depth cue. Lower-floor corner updates queue the matching openings above. Covered crawlspaces retain their own surface lightmap.

`code/unit_tests/lighting_multiz_tests.dm` adds a native three-deck fixture for upward and downward lateral spill, stacked apertures, height falloff, color, solid floors, shaft blockers, receiving-deck doors, hole creation/closure, aiming updates, disconnected levels, visible-floor shading, and complete source cleanup. The focused and production builds compile with zero errors and warnings. `tmp/artemis-lighting/runtime-multiz.log` passes all ten suites with zero startup or test-phase runtimes; `tools/lighting_los/check_runtime.py` validates the log. The pictured shaft has not been visually checked in a live client. Restart an existing world to load the rebuilt production DMB.

### Lower-floor rendering follow-up, 2026-11-03

Z-copy was also treating lower-deck lighting edge guards and glow buffers as physical scenery. The copied black padding and dark glow tiles could replace the floor and objects beneath an opening. Lightmap overlays, edge guards and glow buffers now carry `ZMM_IGNORE`; the upper opening already supplies its visible-floor lightmap and glow. Physical lower-deck objects continue to copy normally.

The native regression exercises the Z-copy queue with a lit lower floor, a wall with black boundary padding, a physical crate, and openings above both the wall and floor. It checks that renderer helpers have no copied appearances while the crate retains its copy. The opt-in preview parameter `openspace_capture=1` builds a controlled shaft, recreates the old helper-copy behavior, then removes only those copies with lighting held constant. Native client exports are `tmp/artemis-lighting/openspace-before.png` and `openspace-after.png`. The sequence removed 37 helper copies. In the same 32-by-32-pixel probe region, blue pixels increase from 0 to 1,017; `openspace-render-report.json` records the measurement. Both exports were visually inspected: the previously obscured lower-floor texture and blue object become visible. This is a controlled native rendering comparison, not a live check at the user's exact mapped shaft. Main, preview and focused builds compile without errors or warnings; `runtime-openspace.log` records the focused suites.
