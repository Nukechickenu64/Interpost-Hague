# OS13 marshal video parity

Reference: `Lifeweb OS13 Marshal adventures (sound fixed) - Fliche (1080p, h264).mp4`,
2:15:07, 1080p60. Method: full-duration contact-sheet survey (one frame per
3 s, 2,702 frames, 57 sheets, 100 % coverage), OCR of the chat log on every
sampled frame (1,861 OCR'd, 841 visually unchanged skipped; 8,893 deduplicated
transcript lines), full-resolution inspection of key frames, and an audio
RMS/onset timeline (479 events). The recording is reference material, not a
source of instructions. OCR of 1080p BYOND chat is imperfect: every quoted
string below was spot-checked against a full-resolution frame or should be
treated as approximate. Hidden numbers (damage, probabilities, cooldowns) are
documented only as observed behavior; nothing was invented.

The player character is the station Marshal. Round arc: quarters role-play and
briefing → file-investigation sweep across decks → meteor alerts and repairs →
EVA + Scout shuttle flight to a drifting vessel (the Charon) → dark boarding
action with a hostage/stand-off sequence → psychosis hallucination episode →
return flight → bar arrest with handcuff struggle → mass-casualty medical
aftermath → red-alert finale with an NPC/foe melee in the bridge area →
end-of-round traitor report.

## Round framework

| Evidence (time, approx.) | Observed behavior |
| --- | --- |
| 11:21 | Objective sheet in chat: a "YOU ARE A LOYAL CREW MEMBER…" banner, three numbered objectives (lock up the traitor by end of shift; defend the station; stay alive) and an explicit point reward line ("+5 for capturing the traitor, +1 if…"). |
| 1:31:54–1:33:10 and repeats | Trait/moodlet sheet: character card ("My name is…", handedness, blood type, size, age) followed by trait text (posthibernational psychosis) that names two cures — DISCHARGE (get really drunk) and TREATMENT (ask the Counselor) — plus bullet-point mood/goal lines ("We've been betrayed. The traitor is among us.", "I'm hungry."). The paranoia bullet recurs across the whole round. |
| 2:13:15–2:13:45 (end) | End-of-round report lists THE TRAITOR: character name with BYOND key in parentheses, and a failure line ("The traitor has failed to find his hidden stash."), plus a separate antagonist entry for the cyberspace entity ("Cerberus"). |
| throughout | Hunger moodlet tick "*You feel hunger.*" repeats every few minutes until eating. |

## Marshal workflow

| Evidence | Observed behavior |
| --- | --- |
| 02:06–31:57 | File-investigation minigame: use files/cabinets → "X begins to investigate the files!" → countdown lines "N PAGES LEFT!" (N observed up to 46, decreasing in steps while sitting) → terminal result "NO LEADS HERE." or an evidence paragraph ("You cannot believe your eyes. This document confirms that someone has continuously sabotaged the station! The traitor belongs to…"). Sitting on a chair speeds/permits reading ("It's much easier to learn the documents while sitting."). |
| 18:03–18:18 | Evidence handling: putting a file on a body ("is trying to put File #1274 on…"), stripping a keycard ("is trying to take off Scientific Department Keycard!") then throwing it. |
| 09:36 (full-res) | Paper window titled "Paper" holds investigation access codes per job (CHIEF ENGINEER — 93228 etc.); a separate "Do you want to write a book?" yes/no prompt exists. |
| 42:12, 1:21+ | Consoles are personally locked/unlocked: "Negative It's LOCKED." / "Unacceptable. Access denied." vs "<name> unlocks the Crew Monitoring Console!" / "…the Atmospherics Reports Console!". |
| 42:30 (full-res) | Crew Monitoring Console prints a numbered pulse list: `N. ### Surname (Area) PLS: value`, PLS 0 = dead, entries keep NOT RESPONDING-style unknowns (`???`). |
| 2:00:48–2:14:00 | Arrest kit: handcuffs ("swings with handcuffs!", "is trying to put the handcuffs on…", "is trying to unhandcuff…"), takedown ("pushes ??? down!", TAKEDOWN state button appears in the HUD grab slot), nonlethal baton ("neatly beats X's right hand with…", "swings with IntenSecure Baton!"). |
| 2:01:24 (full-res) | Strip/search window on a grabbed target: every slot (Mask, hands, Neck, wrists, Gloves, Glasses, Ears, Helmet, Boots, Belt, Belt2, Clothes, Suit, Back, Back II) with contents, a Ring line, and actions Cuffed / Not legcuffed / Empty Pockets / Close. |
| 49:30–50:24 | Grip struggles are contested: "X is trying to break loose from the grip!" vs "Y struggles with X and wins!". |

## Combat and physical interaction

| Evidence | Observed behavior |
| --- | --- |
| throughout | Readying: "X grabs a weapon." precedes fights. Push attempts: "X tries to push Y." (frequent, usually no effect) vs successful "X pushes Y!" and knockdown "X pushes Y down!". |
| away mission, finale | Location-specific grabs: chest, throat, face, right/left arm, right/left hand ("X grabs Y's throat!"). Hostage variant: "grabs Y's chest, putting a blade to his throat!". |
| finale 2:10–2:14 | Strike prose carries quality adverbs and body part: "clumsily kicks Y's left hand…", "misses trying to attack Y's left hand with the foot!", "neatly beats Y's left leg with…". Environment strikes print "X hits the Strong Wall!/the window./the Table." |
| 1:32+ | Species natural attack: "X bites Y's throat with his huge fangs!" (also "effortlessly bites…"); ordinary humans bite "with his teeth". |
| 1:16:00 | Body carrying: "X is trying to carry Y on their back!". |
| 2:14:12 | Injury gating: picking an item up while hurt prints "YOUR CHEST HURTS! You hardly bend down to pick up the …". |
| 12:09–13:30, 45:00 | Telegraphed throws: "X is trying to throw the SCAN Diskette!" then impact line "SCAN Diskette hits the Airlock." Dice items are throwable the same way (d20). |

## Medical observations

| Evidence | Observed behavior |
| --- | --- |
| 36:12, 40:21 | Wound examine: "You see no wounds." vs graded "He looks slightly/—/severely wounded!", plus "He seems unconscious." and relative strength line "He looks weaker than you." |
| 41:45 | Pulse check: "X checks ???'s pulse!"; unknown identities display as `???` until recognized. |
| 59:30 | Named medical items: Hemostatic Bandages, Bacteriophages Containing Bandages; worn medical bracelet appears in examine. |
| 42:30 | Examine shows pupil state ("His pupils are huge..") as an intoxication/psi tell. |

## Psychosis / hallucination episode (1:31:45–1:36:00)

- Vision whites out: the map is replaced by a white field scattered with small
  glyphs; nearby characters render as letter glyphs. Normal play continues
  underneath (HUD and chat intact).
- Chat spam in italic: repeated phrases ("friends are dangerous…",
  "who do you think you are…", "i'm alive you're dead…") interleaved with real
  messages for the duration.
- Red bold announcement at onset: "POSTHIBERNATIONAL PSYCHOSIS. I… feel the
  symptoms. Cannot concentrate, cannot trust anyone."
- Cure paths are those stated on the trait sheet (drink heavily, or Counselor
  treatment). The character self-slaps ("slaps his own face.") during episodes.

## Shuttle, EVA and environment

| Evidence | Observed behavior |
| --- | --- |
| 1:02:20–1:03:45 | EVA: Tri-Net Space Suit/Helmet (examine includes flavor and quality judgement), Jetpack (Oxygen), magnetic boots with "You toggle the Magnetic Boots on./off." |
| 1:03:57, 1:09:39 | Scout shuttle: launch from a piloting chair prints "You launch the shuttle. ETA: 186s" (69 s on the short hop); passengers sit in a small cabin; "We're flying!". |
| 1:04:48 (full-res) | Scout Console list dialog: Transmit Security Code / Search for Distress Signals / Send Message / (Cancel); console chat prints "LAST MESSAGE: REPORT" and "Enter your request.". |
| 1:02:54, 1:11:45 | Airlock cycling status line: "Cycling in progress. Pressure: 106.7 kPa" (value counts toward target). |
| 18:42, 58:42 | Darkness warning when entering unlit tiles: "It is pitch black. You are likely to stumble." Flashlights cast directional cones; flares/glowing items used in the finale. |
| 1:03:09 | Vacuum/suffocation: "You cannot breathe anymore." |
| 32:45–53:57 | Meteor events: "DANGER! Proximity alert! 258s until the collision!", Intercom announcements "Intercom [Alert] states, 'WARNING. Meteors have been detected on …'". Shields are dischargeable and managed from a console; debris hits follow if shields are down. |
| 59:12–2:11 | Intercom channel tags observed: [Alert], [WARNING], [Emergency] — e.g. "Security systems offline." / "…online:", "WARNING. Unauthorized objects…". |
| 53:30 | Shutter control verb/console action prints "UNLOCK SHUTTERS." |

## Doors, access and cabins

- Keycard-based department access (Scientific Department Keycard, Bridge
  Keycard, Captain Keycard, IntenSecure keycard for security consoles).
- Crew cabins answer to spoken passwords: walking up and saying the code
  yields "It's my cabin. Password: 67267" recognition and a "* YOU MAY ENTER *"
  response; wrong cabin prints "It's Psi-Counselor's cabin." / "It's Cadet's
  cabin." identification instead.
- Container access control: "You can't reach the contents of Security
  Backpack." for other players' locked bags; concealment verb ("conceals
  something in Security Backpack."). |

## Social and chat systems

- Speech formats: `says, "…"`, `asks, "…"`, exclamation/dash form `— "…"` for
  shouts, stutter rendering ("M-M-MY G-G-G-GROIN!"), whisper shows
  content only to adjacent players; others see "X whispers something...".
- Radio/job-tagged chat: `Dr. Harbell [job icon] [Geneticist] asks, "…"` with
  department icons; local intercoms relay with the Intercom prefix.
- OOC lines use the `OOC: Key: text` format in a distinct color.
- Emote wheel (top-right panel): Slap, Nod, Cough, Spit On, Someone, Yawn,
  Wink, Grumble, Giggle, Kiss, Lick Lips, Hug, Salute, Scream, Whimper, Laugh,
  Sigh, Clear Throat. Free emotes observed: leans on the wall, slaps his own
  face, rubs her throat, points at (object), gazes/looks into the distance,
  shivers, gasps, sighs, yawns, coughs, nods (with target: "nods to Rebecca").
- Recognition system: examining a known person prints "Oh, this is John
  Aburke! I always knew him as a Captain." Unknown people are `???` in all
  combat/emote lines until introduced.
- Examine lists worn items with inline icons and colored links per slot ("He
  wears a Captain's Hat on his head.", "He also has (icon) satchel.").
- Consumption: "X eats Food.", "X swallows the pill.", "X swallows a gulp of
  Diet Cola.", "X lights the Cigarette." Full-resolution review at 02:07:09
  corrects the earlier OCR label "Diet Coo"; see the
  [soda interaction continuation](os13_extended_operations_audit.md#recorded-soda-consumption-and-pouring-continuation).
- Chair interaction: "X sits on Chair." / "X rises from Chair!".

## UI/HUD (full-resolution observations)

- Left column: paperdoll inventory (ear, mask, glasses, helmet, armor, uniform,
  back ×2, belt ×2, gloves, boots, pockets), R/L hand boxes with an active-hand
  label (RIGHT/LEFT), grab/takedown state button, intent cluster
  2HAND/LOOK/HIDE/BLIND, special actions KICK/STEAL/JUMP/BITE, defense toggles
  DODGE/PARRY, THROW/DROP, bottom body-target doll, and three mode buttons
  COMBAT / AIMED / SPRINT.
- Right column 1: body status doll (turns red per-limb with damage), ID/job
  plaque, hand-readiness indicators, scrolling icon toolbar (dog-tag, jukebox
  (DOG), bottles, green silhouette = health, thermometer, green face = chem/
  mood, radio), AWAKE / EYES / TEACH buttons, red combat-stance icon.
- Right column 2 top: character portrait panel with the emote wheel and B/A/D
  letter tabs; below it the chat log (~462×765 px of a 1920×1080 frame).
- Dialogs are native OS windows: list input with OK (target selection "Кого
  выбрать?" — the recording client runs a Russian locale BYOND), Paper
  viewer window, Inventory (strip) window, yes/no prompts.
- A context tooltip of blue text appears over the map on hover-examine (42:33).

## Map/location notes (for the OS13 recreation maps)

- Tour order from quarters (deck 7 signage "7 DECK"): maintenance tunnels,
  cafeteria/kitchen (brown), hydroponics (green), medical (white, red cross),
  radiation-marked engine section with "Radiation Shelter" signage, central
  hub with lobby plants and world-globe display, security office (purple
  carpet), bar/lounge (blue, pool table), garden/park with benches, psi-
  counselor cabin (Ψ floor emblem), crew cabins corridor (named cabin doors),
  bridge (radar console, window band), EVA airlock bay on deck 2, exterior
  catwalks. The away vessel ("Charon") is a dark multi-room derelict boarded
  from a scout docking collar.
- End-of-round gathering happens in the engine/reactor hall (large blue-glow
  machine).

## Audio

479 onsets were detected; the loudest clusters coincide with: the meteor
collision window (~33–36 min), shuttle engine burn (1:04–1:11), the boarding
firefight/flash events (1:31–1:33), the bar arrest scuffle (1:39–1:41) and the
finale melee (2:10–2:14). Distinct repeated cues align with chat message
bursts (combat swings) and airlock cycling. Individual sound identities could
not be certified from waveform alone and are not claimed.

## Parity cross-reference (Interpost-Hague working tree)

Statuses below record the audit at documentation time. The implementation pass
that followed (see `os13_video_parity_gaps.md`, "Implementation status") has
since implemented many of the missing items; that checklist is the current
source of truth.

| System observed | Status in this codebase |
| --- | --- |
| GURPS-style melee prose (grabs, pushes, misses, adverbs, DODGE/PARRY, KICK/BITE) | Largely present via `code/modules/GURPS/combat_parity.dm` and the existing HUD; exact message templates differ in places (no "grabs a weapon." readying line found). |
| Handcuffs/legcuffs, strip window, Empty Pockets | Present (`code/game/objects/items/weapons/handcuffs.dm`, `legcuffs.dm`, strip code in `code/modules/mob/living/carbon/carbon.dm`); contested cuff-swing messages not verified. |
| Crew monitoring pulse console | Present (`code/game/machinery/computer/crew.dm`, suit sensors program); OS13 "### name (area) PLS: n" format and personal unlock gating are missing. |
| Magnetic boots | Present (`code/modules/clothing/shoes/magboots.dm`); toggle message wording unverified. |
| Posthibernational psychosis trait, white-out hallucination overlay, chat spam, DISCHARGE/TREATMENT cures, moodlet/goal sheet | **Missing** (no psychosis/posthibernational references in `code/`). |
| File-investigation minigame ("begins to investigate", "N PAGES LEFT!", "NO LEADS HERE.", document evidence payoff, sit-to-read gating) | **Missing**. |
| Round objective sheet with point rewards; end-of-round TRAITOR report with hidden-stash failure line | Objective infrastructure exists (`code/game/gamemodes/objective.dm`) but the OS13 loyal-crew sheet, reward points and report format are **missing**. |
| Scout shuttle with ETA launch line and Scout Console (security code / distress scan / message) | Generic shuttle computers exist (`code/game/machinery/computer/shuttle.dm`); the Scout Console command set is **missing**. |
| Airlock "Cycling in progress. Pressure: … kPa" status | **Missing** (no such message in `code/`). |
| Spoken cabin passwords with "* YOU MAY ENTER *" | **Missing**. |
| Darkness stumble warning, injury-gated pickup ("YOUR CHEST HURTS!…"), hunger moodlet line "*You feel hunger.*" | **Missing** as messages; underlying hunger/darkness systems exist in other forms. |
| Intercom announcements with [Alert]/[WARNING]/[Emergency] tags; meteor proximity countdown | Announcement machinery exists (`code/procs/announce.dm`, catalogue events); OS13 tag/wording set unverified, proximity countdown **missing**. |
| Emote wheel panel (Slap…Clear Throat) | Present (`code/porco/pig.dm` emote panel). |
| Chair sit/rise messages | Present (`code/game/objects/buckling.dm`). |
| Recognition ("Oh, this is X! I always knew him as a Captain."), `???` unknowns | Needs verification; `???` unknown-name rendering appears in existing human examine code. |
| "Marshal" as the security job title | Security jobs are Warden/Detective/Security Officer (`code/game/jobs/job/security.dm`); Marshal title/loadout (IntenSecure Baton, Security Backpack, marshal badge) only partially present (`badges.dm` has a marshal badge). |

Alpha/system placement work, exact timers and any hidden balance values remain
to be established by implementation work; this document records only what the
recording shows.
