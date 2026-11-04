# Correctional Apparatus and Psychocorrectional Console

This continuation adds the two missing physical machines and a real spoken
trigger-conditioning loop. **It does not complete psychocorrection parity.**
Subpersonality installation/possession, psi-potential procedures, cognitive
optimization and Refragment personality remain unimplemented.

## Source evidence

Local source recordings in `D:\os13archive`:

- **Medical Officer, 00:15:50–00:16:00:** seated subject, Correctional
  Apparatus, locked/unlocked Psychocorrectional Console.
- **Medical Officer, 00:17:30:** the scrolled menu includes Trigger (SLEEP),
  Trigger (PANIC), Trigger (COMBAT), Refragment personality, specialist
  subpersonality integration and triggerword integration, in addition to the
  four earlier psi/cognitive actions.
- **Medical Officer, 00:18:40:** recording starts, operator exclaims “Light!”,
  a mnemonic audiosignal records, procedures succeed and a duplicate
  subpersonality is rejected. A separate failure requires an implanted
  trigger word before Demon installation. These are distinct state changes;
  they do not establish specialist skill values or possession lifecycle.
- **Genetics/working AI, 01:05:00:** the visible history shows failed
  procedures and an already-present subpersonality. After the subject leaves
  the apparatus, Nash says “Sleep.” and Victor falls over. The subject is
  seated again; the operator records “Apple!” and further success lines
  appear. This adds a concrete spoken Sleep response to the earlier audit.

Inspected full-resolution evidence is retained in
`tmp/os13-parity-20261102/medical/01120.0.jpg` and
`tmp/os13-psychocorrection/genetics/03900.0.jpg`, with neighboring extracted
samples in those directories. Chat is history and not a frame-accurate action
timer. The source's original menu selections and control bindings are not
fully recovered.

## Physical machinery and workflow

`/obj/machinery/os13_correctional_apparatus` is a real upright buckling surface.
`/obj/machinery/computer/os13_psychocorrection` is a separate powered,
keycard-locked medical console. Both are placeable and supplied together by
the separate Psychocorrection equipment cargo entry. Cargo units arrive
unanchored and use ordinary wrench floor-bolt installation. No unverified
station map coordinates or authored research node were introduced.

Swipe a held medical ID to unlock the console. A nearby apparatus is selected
within the same room/deck, up to four tiles away. A single candidate can be
selected automatically; multiple candidates require an explicit choice.
Each machine pair has exclusive links. An active procedure cannot be
redirected to another apparatus.

The operator selects SLEEP, PANIC or COMBAT, then speaks a short trigger word
beside the console. Only the initiating operator can supply the recording.
The console records the mnemonic and starts an interruptible procedure on
the seated organic subject's actual viable brain. The word is installed only
after completion and a successful medical skill roll. Failure preserves the
previous program. An existing mode can receive a replacement word; the same
word cannot activate different modes.

The **Clear conditioned triggers** operation removes these three learned
responses after a successful procedure. It also removes this system's panic
event. This is a local maintenance/reversal operation, not an implementation
of the source's broader Refragment personality action or a mind wipe.

## Spoken effects and persistence

Conditioning is stored on the brain organ, not a loose console, character name
or a copied genotype. It remains after leaving the apparatus and can be
activated through normal local speech. Ordinary hearing, speech
comprehension, deafness, consciousness, deck and vacuum/contact-hearing
restrictions apply. Radio messages, emotes and sign language do not activate
it. Matching is case-insensitive, accepts terminal punctuation, and requires
the whole utterance; “Oversleep” does not match “Sleep”.

- **SLEEP:** invokes actual sleeping/resting and ordinary held-item release.
  The recorded Sleep/fall sequence supports this direction of effect, not its
  exact duration or resistance.
- **PANIC:** applies a real temporary fear mood event and jitter. This is a
  local reconstruction of the named procedure; forced fleeing, resistance
  and exact original outcomes remain unverified.
- **COMBAT:** enables the real combat-mode flag and its indicator. Repeated
  activation does not toggle it off or force an attack. The mode's original
  duration and exact behavioral consequences remain unverified.

The brain is revalidated when receiving a word. Dead/synthetic subjects,
removed/unusable brains, deafness, sleep, unrelated speech and remote-deck
speakers cannot activate it. No player mind is transferred and no specialist
skill points or lethal implant conflicts are inferred from dialogue.

## Procedure ownership and interruption

A session captures its operator, console, apparatus, subject, brain, seat
turf and brain-program revision. The operation revalidates them after its
delay. Unbuckling, death, brain changes, machine movement/unanchoring, loss
of credentials, locking, power loss, timeout, cancellation or destruction
invalidates pending work. Machine processing also detects interruptions
while work is pending, including an outage that is later restored.

Cancellation releases the processing-power state and recording lock. A stale
sleeping procedure cannot write to a replacement subject or cancel a newer
session. Destroying the apparatus releases its buckled subject through the
existing buckling lifecycle. Mechanical hand release remains usable without
electric power, so the ordinary machinery interaction gate cannot trap the
subject during an outage. Successfully learned responses remain on the
brain when their programming machine is destroyed.

## Reconstruction values and artwork

These are **local integration choices**, not recovered OS13 constants:
medical access checks throughout operation; one word per mode; Latin-letter
single words up to 24 characters; four-tile same-room pairing; 30-second
recording timeout; five-second procedure; existing medical skill roll;
noninjurious failure; three-second retrigger cooldown; Sleep value 10;
Panic mood -10 for one minute plus jitter 10; apparatus idle/working power
50/2500 and inherited console power usage.

The apparatus uses supplied `surgery.dmi:torturechair`, and the console uses
supplied `computer.dmi:mtnc`, `mtnc0` and `mtncb` states. These are candidate
asset assignments inspected in the generated existing-asset atlas, not
pixel-certified source matches. The console stops illuminating when broken
or unpowered. Original sound, pose alignment, procedure animation and exact
hardware sprite assignments still need live comparison.

## Validation

The expanded native complete-Classic-map regression adds five groups for
real speech recording, organ-bound Sleep, Combat/Panic effects, failed and
interrupted procedures, and reversal/destruction cleanup. Only the success
roll is controlled in the fixture; speech, timing, machinery, organs and
buckling use production paths. The outage checks include actual mechanical
release without power.

Executed with BYOND 516.1688 on 2026-11-02:

- Production `Interpost-Hague.dme`: **0 errors, 0 warnings**.
- Focused `os13_object_regression.dme`: **0 errors, 0 warnings**.
- Native complete-map regression: **all 20 check groups completed; 0 failures,
  0 new runtimes, 0 startup runtimes**. The world exited itself. Results:
  `tmp/os13-object-regression.log`.
- Scoped source/report whitespace and log-integrity checks passed.

Reproduce:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' os13_object_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' os13_object_regression.dmb -invisible -trusted -close
```

The intervening Scout artwork update uses `rcomm`/`rcomm0`; its older
regression assertions were updated to those current states without reverting
the artwork. Two identifiers in the newer crew navigation code (`to` and
`walk_to`) were DM reserved names and prevented compilation. They and their
local references were renamed, with navigation logic preserved.

Existing unmapped Escape/Supply/Mercenary warnings and unavailable SQL
connections remain separate deployment limitations. The cargo catalogue
entry does not certify cargo delivery on Classic. No user world was restarted
to load the production DMB. Exact source mechanics, original hardware art and
Dream Seeker visual comparison remain open.
