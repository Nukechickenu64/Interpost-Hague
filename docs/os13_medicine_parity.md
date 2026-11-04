# OS13 missing medicine products, 2026-11-02

This continuation implements five previously unavailable Chemfab products:
Hyperstim, Mnemosine, Oxivior, Monogreline and Polythesine. It follows the
requested priority of absent objects and gameplay systems. **Original
pharmacology and perfect parity remain unverified.**

## Inspected recording evidence

Source: `Lifeweb OS13 A medical officer who end in a shot - Fliche (1080p,
h264).mp4` in `D:\os13archive`.

- **00:54:20:** the help panel identifies Hyperstim as a combat stimulator,
  Mnemosine as a cognitive stimulator, Oxivior as a chemical oxygenic liquid,
  Monogreline as a sedative and Polythesine as a neuroleptic. Chat records a
  Hyperstim injector being put into a medical belt.
- **00:54:20–00:54:50:** the catalogue and previously inspected samples
  establish costs of 2 for Mnemosine/Oxivior and 3 for
  Hyperstim/Monogreline/Polythesine. The previously inspected charge count
  falls from 5 to 2 around the Hyperstim product.
- **01:02:00:** before the later edited action, the HUD reads ST 10, HT 11
  with a separate (-1), IN 12, DX 10, PR 13 and IM 11.
- **01:04:40:** a full HUD/chat frame shows attempted self-injection,
  successful injection, the Hyperstim injector falling to the floor and
  `... I'M FEELING SO GOOD! ...`. The HUD then reads ST 15, HT 13, IN 11,
  DX 12, PR 14 and IM 11. Grip escape and an NT5 shot follow.

The intervening video uses crops, fades and cuts. These observations **do not
isolate every stat delta, duration or survival outcome as a drug effect**.
Source frames are retained under `tmp/os13-medical-continuation/baseline`
and `hyperstim`. Extraction uses the existing local-video tool and no
generated replacement art.

## Functional products and reconstruction values

All five have distinct reagent and physical injector subtypes in
`code/modules/os13/os13_medicines.dm`. The physical products are children of
`/obj/item/reagent_containers/hypospray/autoinjector/os13_chemfab`, named
`hyperstim`, `mnemosine`, `oxivior`, `monogreline` and `polythesine`.
They can be placed by a mapper and are produced by the actual Chemfab.
Each contains exactly its own formulation, with no inherited Inaprovaline.

| Product | Implemented gameplay | Values that remain local choices |
| --- | --- | --- |
| Hyperstim | Temporary effective GURPS strength, dexterity and health; recorded onset line. Actual combat checks use these values. | +5 ST, +2 DX, +2 HT. No source-certified damage immunity, wound healing or guaranteed grip escape. |
| Mnemosine | Temporary effective intelligence, including intelligence-derived perception and intellectual skill checks. | +2 IQ; no permanent training grant. |
| Oxivior | Existing circulating-blood oxygenation system receives oxygen support. | Support magnitude 1, equivalent to the existing system's 50% oxygen-deficit mitigation; requires actual circulation. |
| Monogreline | Drowsiness accumulates and continued exposure produces actual sleeping state. | +4 drowsiness per effective metabolism cycle, capped at 60; sleep of 5 after cumulative exposure reaches 1. |
| Polythesine | Existing neuroleptic chemical effect reduces hallucination strength/duration through the real hallucination handler. | Mind-stabilizing magnitude 2; does not implement a universal psychiatric cure. |

All five currently use a five-unit injector and metabolism of 0.1 units per
normal chemistry cycle, subject to existing species/size metabolism. Those
are reconstruction values, **not recovered original dose/duration constants**.
Original overdose thresholds, dependence, withdrawal, contraindications and
drug-specific side effects remain unimplemented. No new universal cure,
antagonist recipe or claimed original risk model is supplied.

## Effective stats and cleanup

Drug contributions live in the normal per-cycle chemical effects list.
Repeated exposure refreshes a bounded contribution rather than stacking a
permanent stat bonus. `effective_stat()` leaves stored stats intact;
`gurps_stat()` uses effective primary stats and the existing derived
perception/immunity formulas. The Porco primary-stat display uses those same
effective values, including live updates.

The next normal chemistry pass clears effects after removal or depletion.
Death and synthetic physiology reject the stat contribution. Permanent
learning and edits made during exposure survive its end. Existing drugs and
non-carbon mobs receive zero new stat contribution by default. Legacy code
that directly reads raw `stats[]` outside the shared GURPS checks still sees
permanent stats; this continuation does not certify every legacy action.

## Chemfab and injection loop

The existing water/feedstock loop and recorded discrete catalogue costs
remain in use. Fabrication validates the operator, machine, supplies and
requested formulation. It produces the physical subtype, verifies exact
five-unit single-reagent contents, then commits water and feedstock.
Malformed products are deleted without spending resources. The catalogue
now supports seven of its seventeen recorded entries, including existing
Dylovene and Hyperzine. Ten unsupported formulations remain unavailable.

OS13 Chemfab injectors now have an attempted/completed injection sequence.
A one-second interruptible action captures patient, region, organ and full
dose. Completion rechecks capability, held ownership, reach, clothing,
organic limb identity, contents and recipient capacity. A second action on
the same injector cannot run concurrently. Rejected/interrupted work retains
medicine; success transfers real reagents and uses the existing administration
logger. Empty injectors use supplied `chemical.dmi:injector1` art and drop
through ordinary inventory rules, matching the observed floor-discard
sequence when removal is permitted.

The delay, exact interruption rules and whole-dose delivery are local
integration choices. OS13 Dylovene/Hyperzine injectors share this path;
generic hyposprays and the separate five-use blood-substitute injector retain
their own paths. World/held art reuse the prior OS13 injector mapping; live
source alignment remains unverified.

## Validation

`os13_object_regression.dme` includes the complete production Classic map and
the new `tools/os13_parity/medicine_regression.dm`. New native groups check:

1. Actual charge/water servicing, exact Hyperstim cost and contents, injection,
   spent-object discard, real combat stats, repeated exposure, removal and
   natural metabolism/depletion.
2. Mnemosine's cognitive skill/derived-stat effects while preserving permanent
   intelligence gained during exposure.
3. Fabricated/injected Oxivior, Monogreline and Polythesine and downstream
   oxygenation, sleep and hallucination effects.
4. Locked/unpowered/unsupported fabrication, interrupted injections, a full
   recipient and a selected site covered during the action, with conservation.

The headless operator overrides only the NanoUI client-presence check; native
machine authorization, distance, power, lock, contents and resources remain
in use. The regression explicitly enables DEBUG for runtime accounting.

Executed with BYOND 516.1688 on 2026-11-02:

- Production build: **0 errors, 0 warnings**.
- Expanded focused build: **0 errors, 0 warnings**.
- Native complete-map regression: **all 15 check groups completed, 0 failures,
  0 new runtimes, 0 startup runtimes**. The world exited itself. Results:
  `tmp/os13-object-regression.log`.
- Scoped whitespace and native-log integrity checks passed.

Reproduce with:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' os13_object_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' os13_object_regression.dmb -invisible -trusted -close
```

The test world retains existing unmapped Escape/Supply/Mercenary warnings
and unavailable SQL connections. Those are separate from these checks.
No running user world was restarted to load the production DMB. Live Dream
Seeker comparison, original effect values and remaining medical apparatus
are open. Psychocorrection, Genemod, Autonurse/Medchamber, the ten unsupported
Chemfab entries and the remaining medical contracts are still incomplete.
