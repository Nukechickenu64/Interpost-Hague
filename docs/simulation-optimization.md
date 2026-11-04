# Atmospherics and lighting optimization

This pass removes repeated work without changing atmosphere tick intervals,
transfer formulas, pressure limits, light ranges, shadow count, mask resolution,
falloff, blur, bloom, ambient occlusion, or line-of-sight rules.

## Changes

- Station reserves iterate a lifecycle-managed vent registry instead of every
  machine. Registration follows machinery initialization order, so allocation
  order and the low-supply round-robin cursor keep their existing behavior.
- Full two-way gas equalization skips the redundant comparison of the identical
  mixtures it just produced. Partial and one-way sharing retain the old check.
- Airflow stops expanding its search after processing the final affected ring.
  It still processes every original tile, movable, stun, and movement route.
- Overlapping client views scan each tile's shadow casters once per subsystem
  pass. The scan radius and update interval are unchanged.
- Shadow selection keeps only the strongest three candidates during ranking,
  preserving encounter order for equal weights and each shadow's light identity.
- Each shadow caches the exact mapping from mask samples to receiving turfs.
  Position, pixel offsets, projection matrix, z-level, and sprite dimensions
  invalidate that mapping. Every refresh still samples current lighting on every
  distinct receiving turf; stationary shadows respond to changing lamps, cones,
  colors, and occlusion. Cached data is owned by the shadow and released with it.
- Zero RGB deltas do not queue corner work. Tile lighting still updates geometry
  and visibility, but unchanged RGB values do not rebuild color matrices or
  restart lightmap/bloom animations. The initial black sample is always applied.
- Director structural telemetry discovers walls and simulated/space boundaries
  once. Turf construction and destruction queue the changed coordinates and
  cardinal neighbors for reclassification. Samples still read current wall
  damage, station levels and neighboring area names. Discovery and large update
  batches yield to the controller's tick budget.
- Atmosphere telemetry checks shared zone mixtures once per area, retaining
  direct reads of unzoned turf air. Lockdown pressure scans use the existing live
  vent registry and preserve area membership, including moved/contained vents.
- Shadow masks reuse their geometry until position, pixel offsets, dimensions,
  matrix components or world bounds change. Receiving coordinates are resolved
  again each refresh, so turf replacement cannot leave stale references. Fill
  light facing is calculated once per light per mask refresh. Appearance-only
  changes reuse an unchanged alpha-mask icon.

## Verification

`simulation_optimization_regression.dme` runs 19 focused suites, including all
nine Artemis lighting/LOS suites and seven atmosphere/control suites. Its isolated
atmosphere fixtures avoid dependence on test landmarks in the selected map.

The additional equivalence tests compare 60 gas-sharing scenarios and 64 shadow
projection/live-light scenarios against frozen original implementations. They
also cover vent lifecycle/order, overlapping views, receiving-turf replacement,
larger sprites, and out-of-map shadow samples. Native microbenchmarks report
stationary mask and full-equalization time. These are operation-level timings,
not a claim about total server frame rate or client GPU performance.

The profile-driven telemetry suite also compares full-map readings and live
wall damage, shared breach boundaries, area renames, changed station levels,
`ChangeTurf` and direct turf construction against the original sampler. It
reports initial discovery separately from steady-state samples and records
BYOND self/total CPU and overtime, since elapsed time includes tick-budget yields.

Compile and run from the repository root with the installed BYOND tools:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' simulation_optimization_regression.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' simulation_optimization_regression.dmb -invisible -trusted -close -logself
python tools/simulation_optimization/check_runtime.py simulation_optimization_regression.log
```

The validator checks the actual runtime text as well as suite results; the
engine's runtime counter alone is insufficient. Build and runtime logs from this
pass are saved under `tmp/simulation-optimization/`.

## November 1 profile-driven validation

The production and 19-suite regression targets compile with zero errors and
warnings. On the current OS13 Classic map, initial structural discovery took
256 ms and retained 1,458 walls and 928 boundary candidates. The subsequent
sample used 9 ms total CPU (8 ms self), compared with the original sampler's
789 ms total (683 ms self). Recorded overtime fell from 672 ms to 2 ms. Elapsed
sample time includes controller yields and is not the CPU measurement.

The last native mask benchmark ran 1,000 stationary refreshes in 481 ms versus
825 ms for the original sampler (about 1.7 times faster). Timings vary with
other world activity; these measurements do not establish whole-server CPU or
client frame-rate gains.

All three optimization equivalence suites and both engineering atmosphere/control
suites pass, with no runtime errors in the full run. The broader run has 14
passing suites and five failing suites: four legacy atmosphere suites (shared
supply, modcon refill, fixed-station refill, cold startup) and the nested shadow
appearance assertion. An isolated comparison restoring the original shadow
ranking, appearance, mask and area-lockdown procedures reproduces the same 11
assertion failures in those five suites. The strict full-run validator therefore
still fails; these unrelated failures have not been suppressed or changed.

The final logs are `tmp/simulation-optimization/profile-final-full.log`,
`profile-baseline-root.log`, `profile-build.log` and `profile-main-build.log`.
Restart a running world to load the rebuilt production DMB. Live-client visual
and whole-server profiling after restart remain to be checked.
