# Startup optimization

Startup retains the complete map, away-site generation, atmosphere settling,
lighting and four isolated cyberdeck archives. The lobby countdown is unchanged.

- Opacity notifications compare whether a tile blocks sight. An unset counter
  becoming zero no longer sends a visibility change through neighboring tiles.
- Initial lighting samples and edge padding are calculated after geometry and
  light sources are ready. Each overlay is queued once; live opacity changes
  still update neighboring samples immediately. Dark samples share a black
  color matrix instead of allocating duplicate light and glow matrices.
- Startup starlight walks outward from simulated terrain. It visits each space
  boundary tile once instead of searching eight neighbors on every empty tile.
  Space created during play still uses the normal local update.
- Six per-turf viewing caches are allocated when first populated. Unvisited
  terrain no longer allocates empty caches, including on reserved archive levels.
- Subsystem initialization starts immediately after the startup hooks, removing
  the fixed one-second delay.

## Full-map benchmark

Build and run from the repository root with BYOND 516:

```powershell
& 'C:\Program Files (x86)\BYOND\bin\dm.exe' startup_benchmark.dme
& 'C:\Program Files (x86)\BYOND\bin\dd.exe' startup_benchmark.dmb -invisible -trusted -close
python tools/startup/check.py
```

If launching through the Dream Daemon GUI executable, wait for
`STARTUP_BENCHMARK_READY` in `tmp/startup-benchmark.log` before reading results.
The benchmark uses the production map and configuration and exits automatically.
It checks every dynamic lighting tile before a regular lighting tick can repair
an initial sample, and independently checks space against the original starlight
neighbor rule. It also requires all three lighting queues to be drained.
It writes subsystem timings to `tmp/startup-timings.json`.

For a proc profile, add `-params 'profile=1'` to Dream Daemon, then run:

```powershell
python tools/startup/check.py --profile tmp/startup-profile.json
```

Compare elapsed times with profiling disabled and no other builds or test worlds
running. The measurement covers subsystem initialization, as in the admin log;
it excludes executable/resource loading, global construction and compilation.
Map generation and machine load introduce variation. Use repeated captures for
precise comparisons. The profiler is opt-in and is only part of the benchmark.

The existing `lighting_los_regression.dme` checks runtime lighting, doors,
visibility and shadow geometry separately from the startup checks.

## Local measurements (2026-11-01)

Unprofiled captures using the same production map/configuration:

| Subsystem | Before | After |
| --- | ---: | ---: |
| Mapping | 3.88 s | 2.84 s |
| Atoms | 17.38 s | 9.77 s |
| Atmosphere | 4.38 s | 4.13 s |
| Lighting | 8.29 s | 6.49 s |
| Total initialization | 34.61 s | 23.86 s |

The final capture reduced elapsed initialization by about 31%. These are local
captures, not a guarantee for every machine or procedural map. The final
benchmark checked 67,212 initial light samples and every starlight boundary with
zero failures and zero runtimes. The production and regression builds compiled
with zero errors and zero warnings.

Eight of the nine lighting/visibility suites passed, with zero startup or test
runtimes. The remaining assertion, "Light-view selection did not reach nested
equipment or changed the real character's facing," also failed in an isolated
source copy with all seven changed code files restored to their pre-change
behavior, run from the same production directory with the same configuration
and native libraries. That existing shadow-facing failure is separate from the
startup changes.
