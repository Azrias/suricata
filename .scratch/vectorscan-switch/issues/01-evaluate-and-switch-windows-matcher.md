# Switch the Windows Suricata matcher to Vectorscan after validation

Status: ready-for-agent
Type: task
Workflow: open
Created: 2026-10-25

## Goal

Build Vectorscan with the project's MSYS2 UCRT64 toolchain, integrate it through
Suricata's existing `hs` matcher backend, and switch the local Windows build
once correctness and packaging gates pass. Preserve a reproducible baseline
and fallback build without Vectorscan.

## Context and sources

- [Research and proposed evaluation](../../../VECTORSCAN-RESEARCH.md).
- Current baseline: Suricata `e16087fab`, packaged by
  `scripts/build-windows.sh`; `--build-info` reports `Hyperscan support: no`.
- [Vectorscan Windows port #414](https://github.com/VectorCamp/vectorscan/pull/414)
  merged as `c039c145649bd1f21d62b09974de506a5e5816c6`. Start with that pinned
  Windows-capable revision or document a newer reviewed revision and why.
  Release 5.4.13 predates this port.
- [Known Windows regression #417](https://github.com/VectorCamp/vectorscan/issues/417)
  reports two disabled regex tests with match-count discrepancies. The cause
  is unresolved in the research; do not assume either a harmless test issue
  or confirmed production missed detections.

## Implementation scope

1. Preserve the current runnable package and record its toolchain, configure
   options, rules, PCAP inputs, outputs, and test results for comparison.
2. Build the pinned library in an isolated directory/prefix with the same
   UCRT64 toolchain. Record build options, CPU requirements, and dependency
   versions; avoid mixing UCRT64 with MINGW64/MSVCRT or MSVC artifacts.
3. Add a concise reproducible dependency-build path and integrate `libhs`
   discovery into the Windows build script. Keep a documented no-`hs` fallback.
   Rebuild against matching headers/library rather than swapping an arbitrary
   DLL into the existing package.
4. Extend packaging as necessary for the isolated dependency prefix, recursive
   DLL dependencies, and BSD/third-party notices. Retain native Windows
   startup without the development MSYS2 PATH.
5. Verify `Hyperscan support: yes`, exercise `hs_valid_platform`, and confirm
   effective `mpm-algo=hs` / `spm-algo=hs` selection. Keep PCRE2 enabled;
   Vectorscan is not a wholesale replacement for Suricata's PCRE2 engine.
6. Complete the acceptance checks below and document results and limitations.
   Enable the new default only after correctness gates pass. If #417 remains
   reproducible or unexplained, retain an opt-in experimental build and record
   the blocker instead of silently accepting it as production-ready.

## Acceptance criteria

- [ ] Vectorscan revision, dependencies, build options, CPU ISA, and rebuild
  commands are recorded; fixed-ISA/fat-runtime choices match intended hosts.
- [ ] Library unit-test results include actual failures and skips. Explicitly
  reproduce or explain #417, including its normally disabled cases; disabled
  tests are not counted as passes.
- [ ] Suricata starts natively, reports `Hyperscan support: yes`, and actually
  uses `hs`; package dependencies are verified without the developer's PATH.
- [ ] All built-in C tests and applicable suricata-verify tests run, including
  `hs`-dependent coverage. Compare failures/skips with the preserved baseline;
  explain changes rather than assuming prior counts must remain identical.
- [ ] Baseline and new builds inspect identical rules and representative PCAPs;
  alert sets and relevant detection outputs agree, with nondeterministic
  timestamps/ordering normalized and every substantive difference investigated.
- [ ] Exercise cache regeneration, repeated startup, malformed/boundary input,
  and rule reload where supported. Do not reuse incompatible serialized caches.
- [ ] Measure repeated-run throughput, CPU, peak memory, and cold-start/rule
  compilation time. Record workload and hardware; do not promise a universal
  speedup or use throughput as a substitute for correctness.
- [ ] Document the default/fallback decision, remaining blockers, and exact
  commands in the Windows build guide and verification workflow.

## Out of scope

Npcap/WinDivert installation, fixing the unrelated Rust C-FFI link failure,
MSVC or Windows ARM64 ports, publishing an upstream issue/PR, and production
deployment. Keep all implementation changes on a feature branch; preserve
`main` as upstream.

## Comments

2026-10-25: Created at the user's request. Implementation has not started.
