# Water-chip video parity

Reference: the user-supplied **Lifeweb OS13 A nice little story with a nice little water chip – Fliche**, 1:42:29 (archived locally as `D:/os13archive/os131.mp4`). Surveyed the whole recording at 75-second intervals, then inspected full-resolution frames and chat around the logistics, hydroponics, kitchen and repair sequences. This is an audit of observable interactions, not a claim to have recovered Lifeweb's hidden implementation or exact balance.

A later full-coverage pass (one frame per 3 s, 2,050 frames, chat OCR into a
3,690-line deduplicated transcript, audio onset timeline) added the
"Additional gameplay observations" section at the end. Shared station systems
seen in all three recordings are documented centrally in
`os13_marshal_video_parity.md` and `os13_video_parity_gaps.md`.

| Recording evidence | Implemented behavior |
| --- | --- |
| 18:30–20:00; 1:03:45–1:06:15: precursor charges, a cycling ChargeMaster selector, finished charges and “Happy charging.” | Physical one-for-one precursor conversion, fixed output during a job, five-second powered processing, floor output, cancellation and destruction recovery. Completion now prints the recorded `[ChargeMaster] Happy charging.` line. Two machines and twelve precursors in Alpha cargo; more can be ordered. |
| 18:30–23:45; 41:00–42:00: coffee, soda, security, equipment, cigarette, bar and chemistry deliveries | Compatible vendor refills, cigarette and bar charges, basic chemistry and beverage dispenser refills. Universal equipment charges also restock medical equipment vendors; named vendor charges now require their matching vendor family. Full or incompatible machines preserve the charge. Returned items, premium stock and custom chemical mixtures remain intact. |
| 39:30–40:30: yeast and glig in water-filled vats | Existing exact culture recipe retained. Alpha has four connected vats, its dedicated Water Chip console, culture dispenser and press. Three missing vats restored after checking the actual map. |
| 45:30–46:30: hand stirring, red dots, “continue 5 time,” then green | Five mandatory growth/stir cycles; hand stirring added. Empty-skimmer stirring remains available. Repeated clicks cannot skip growing time. |
| 47:30–51:15: green harvest, skimmer, press, biomatter delivery for cloning | Existing bounded skimming, pressing and cloning feedstock path retained and regression-tested. |
| 42:00–42:30; 52:30–53:45: separately configured pizza/sandwich units; load biomatter, then activate | Three mapped OS13 Food Processing Units, explicit loading and activation, edible ersatz-pizza/sandwich/shawarma, original configurable food options retained for ordered units. |
| 56:15: separate Food Processor described as processing normal meat | A separate OS13 meat processor makes a raw meatball for existing cooking recipes, preserving the input's nutrition and contaminants. |
| 1:07:20–1:07:30: repair of the broken unit; examination identifies shawarma configuration | Shawarma unit begins jammed; an uninterrupted ten-second empty-hand repair restores it. Broken units reject ingredients. |

The wider recording's power failures, solar/shield operation, meteor warnings, cloning, inventory transfers, radio, food/drink consumption, combat and medical treatment use existing systems. Dialogue and character-specific events are not scripted into the round. The Foam Container is delivered but its operation is not demonstrated; the existing metal-foam equipment remains available. No unobserved foam-container control scheme or narrative outcome was inferred from that delivery.

## Water service consistency

Sinks now enforce chip availability for filling vessels, wetting mops and washing items, and recheck supply after timed washing. Running showers stop when the last chip leaves a holder or console; they can still be switched off without a chip. Multiple installed chips keep service active until the last is removed. Existing liquid can still be drained without a chip. Water-chip recycling material now matches its research fabrication cost.

## Water-chip sprite

At 34:12, immediately after Elena Meijer's water-chip handoff, the right-hand
inventory slot shows a grey module with red upper accents, a cyan indicator and
gold contacts. The matching supplied asset is the two-frame `module1` state in
`icons/os13/objects/objects/hitech_parts.dmi`. The water-chip item now uses this
animated state on the floor and in inventory, including after installation and
removal. The holder's separate sprites and water-service behavior are unchanged.

No dedicated `module1` hand-overlay state exists in the supplied OS13 sheets.
Both hands use their OS13 `electronic` state rather than an absent `chip` state;
an exact character-overlay match has not been established. Manual in-game checks
should cover both hands, dropping the chip and installing/removing it.

## Alpha locations

Coordinates are `(x, y, z)`:

- ChargeMasters: `(130,117,3)` and `(132,116,3)` on cargo counters; precursor crate `(132,115,3)`.
- Vats: `(108,97,3)`, `(108,95,3)`, `(108,93,3)` and `(102,88,3)`; existing console `(108,100,3)` and press `(100,88,3)` retained.
- Pizza `(120,95,2)`, sandwich `(120,93,2)`, repairable shawarma `(121,93,2)`; separate meat processor `(120,95,3)`.
- Cigarette vendor: `(110,107,2)` in the bar.

All art comes from the supplied OS13 DMI assets. Timings, three scoops per vat, eight nutrition units per ersatz meal, one raw meatball per slab and cargo prices are local balance choices. The recording does not establish their exact values. Hydroponics/snack refill outputs extend the current local supply chain; those selector entries were not clearly demonstrated in this recording.

## Validation

Compile `waterchip_video_regression.dme` and run its DMB with DreamDaemon. The ten focused suites cover the full biomass cycle, real machinery dispatch, food/cloning consumers, vending stock preservation, all charge outputs, beverage/chemical refill compatibility, chip removal, timed repair, outage recovery and meat reagent conservation. `tools/waterchip_video/check_map_assets.py` checks mapped equipment, access tiles and referenced sprites.

Compile, automated server tests and static sprite inspection are separate from an interactive Dream Seeker playthrough. Final results are recorded with the implementation handoff; a live client playthrough remains necessary to assess movement and visual timing in play.

The validation world also reports existing startup problems before the focused suites begin: a null random-spawner item at `(138,98,2)`, obsolete power-link helpers and unavailable local database connections. The unit-test runtime counter does not include every startup error; it must not be read as a clean-startup guarantee.

Final local results (2026-10-18):

- `Interpost-Hague.dme`: **0 errors, 0 warnings**.
- `waterchip_video_regression.dme`: **0 errors, 0 warnings**.
- DreamDaemon: **All Unit Tests Passed [10]**, **Caught 0 Runtimes** during the focused tests, with the startup caveat above.
- Map/assets: **14 fixture placements passed**, four vats present, kitchen ladder route clear, all required OS13 sprite states present.
- Static machine-state preview inspected; gameplay and map source hashes remained unchanged through the final test run. The final normal build also includes the revised hand-stirring hint in the console.

Local evidence: `tmp/waterchip-video-check/runtime-verified.log`, `machine-states.png`, and `validated_sources.json`.

## Additional gameplay observations (full-coverage pass)

Message/format observations from the transcript pass that the implementation
tables above do not cover. Quotes are short functional message strings
transcribed by OCR; treat spellings as approximate.

| Evidence | Observed behavior |
| --- | --- |
| 00:00 | Same round-start cryosleep hangover system line as the other recordings ("You feel terrible, like having a heavy hangover..."). |
| 12:39 | Same loyal-crew objective sheet banner. |
| 10:51 | Staged alert levels exist: an announcement raises the station "to 'elevated alert'" and explicitly extends IntenSecure (security) authority. |
| 18:15, 36:24 | ChargeMaster completion chat line uses a bracketed machine prefix: "[ChargeMaster] Happy charging." Charge items examine as "@-icon Chemistry Charge", "Coffee Charge", "Bar Charge", "Soda Machine Charge", "Precursor Charge"; these observed charge names are implemented in `vending_charges.dm` and `chargemaster.dm`. Machine restock prints "You insert the charge into the machine." |
| 23:24 | Charges obey the shared telegraphed-throw grammar ("is trying to throw the Precursor Charge!" then the throw line). |
| 34:09–34:12 | Pointing verb works with held items ("points the water chip at the floor."); hand-offs print the paired give/pass lines. |
| 39:39–40:03 | Vat work messages: "fills the food vat with yeast.", "throws Glig into the Food Vat.", "stirs the muck in the vat!" |
| 17:21 | Idle flavor/emote self-message: "You raise your head and look at the ceiling. Thousands of..." |
| 1:33:18–1:34:00 | Head-trauma amnesia: "You feel an intense pain in your head" followed by "Your head hurts- You can't remember anything that..." (memory loss effect after a head hit during the outage incident). |
| 1:38:45 | Nausea moodlet line: "You feel nauseous." |
| 1:38:12 (0:38:12 ann.) | Planetary psi-field announcements ("planet's natural psi field changed by 23%...") and psionic lore: a crew member cites "a Beta psi-potential" and a psionic implant; Mentats appear as a psi-relevant drug. |
| 1:01:51 | Cloning failure prose after the power outage: "The outage mulched this clone."; separate talk of replacement "cloned hands" for a maimed crew member. |
| 37:06, 37:21+ | Shared container/darkness restrictions: "You can't reach the contents of Backpack.", "It is pitch black. You are likely to stumble." |
| throughout | Deck elevator is the main inter-deck transport (characters wait for and call the elevator; the recording's z-change blackouts match the lift rides mapped in `os13_waterchip_manual_map.md`). |
