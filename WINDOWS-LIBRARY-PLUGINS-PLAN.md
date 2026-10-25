# Windows library and plugin implementation plan

Date: 2026-10-25. Baseline: Suricata 9.0-dev, upstream
`e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4`.

This is a proposed implementation sequence, not an upstream commitment.
See [research and experimental evidence](WINDOWS-LIBRARY-PLUGINS-RESEARCH.md)
for source citations, results, limitations, and the separate prototype worktree.

## Summary

There are three separate deliverables: static embedding, loadable extension
DLLs, and a reusable engine DLL. Static embedding and C/Rust extension DLLs
worked in local GNU/UCRT64 probes. A reusable engine DLL did not link.
First establish tested static embedding and harden EXE-hosted plugins; build
the reusable engine DLL afterward. None of the prototypes establishes supported
Windows SDK compatibility or production readiness.

## 1. Establish supported static embedding

- Fix Windows portability in embedding examples. The live example's
  `interface` field conflicts with a Windows COM macro; rename it consistently
  (the prototype used `interface_name`).
- Package matching C and Rust static archives, public/generated headers,
  dependency information, and concise build/install instructions.
- Start with a pinned GNU/UCRT64 toolchain and matching runtime dependencies.
  Treat MSVC compatibility as a separate milestone.
- Add Windows CI that builds and runs the simple/custom embedding hosts on
  offline packets. Compare normalized alerts and protocol events with the
  normal Suricata executable.
- Test host-owned packet input, final packet action/verdict callbacks, error
  paths, coordinated shutdown, and sustained concurrent workers.

Acceptance: a separate host can build from the installed artifacts and process
a known capture with equivalent expected results. Offline/host-supplied packets
must not require Npcap. Live capture remains a separate, driver-dependent test.

This remains a packet/thread/lifecycle API, not `inspect_bytes()`. Hosts must
respect flow ownership and shutdown ordering. Do not promise isolated multiple
engines per process or repeated initialization without dedicated validation.

## 2. Make Windows extension DLLs a supported build path

- Replace the Unix-only `dlfcn.h`/`-rdynamic` configure gate with platform-aware
  loader and linker capability checks. Preserve the Unix path.
- Integrate native DLL loading, symbol lookup, release, explicit paths, and
  directory discovery. The prototype used `LoadLibraryExA`, `GetProcAddress`,
  and `FreeLibrary`; production code needs Unicode/long-path handling and a
  reviewed, restricted dependency-search policy.
- Define the exported host API deliberately. Prototype export-all is not a
  stable or minimal contract. Specify version checks, calling conventions,
  allocation/free ownership, callback lifetimes, and unload/shutdown behavior.
- Generate the host import library and provide reproducible C and Rust plugin
  build examples with matching toolchain/runtime requirements.
- Make build-info reflect actual plugin capability. Report load failures
  clearly and document whether explicitly requested plugin failures are fatal.
- Add Windows CI for real initialization and output/flow/thread callbacks,
  directory discovery, incompatible API versions, missing entrypoints,
  missing dependencies, non-ASCII paths, and orderly shutdown.

Acceptance: C and Rust DLLs built against the installed interface execute their
callbacks; negative tests prove that failures are diagnosed. Exit status alone
is not proof of loading: stock Windows builds can accept a plugin option while
plugin support is compiled out, and upstream loader failures can be nonfatal.
Capture and application-layer parser plugins need separate validation.

### Choose the host linkage contract before packaging

| Option | Benefit | Work or constraint |
| --- | --- | --- |
| Import from the executable | Closest to the working prototype | Imports bind to the host executable basename; renaming requires relinking. |
| Import from an engine DLL | Stable shared dependency for hosts and plugins | Requires the engine-DLL work below first. |
| Pass a versioned host function table | Explicit, narrowly scoped boundary | Requires API design and adaptation of current plugin interfaces. |

EXE imports are the shortest path to a hardened first implementation. Review
that tradeoff before calling the result a reusable SDK; the prototype does not
settle the long-term API design.

## 3. Produce a reusable engine DLL

- Add Windows PE DLL, import-library, and installation targets rather than
  reusing the Linux `.so` recipe.
- Separate Windows service startup from application `main()`. The current
  `win32-service.o` references `main`; whole-archive DLL linking pulled in this
  dependency and failed through startup code with unresolved `WinMain`.
- Define the public exported API and its compatibility policy; do not export
  every internal symbol by default.
- Specify cross-module allocation, object ownership, callback lifetime, error
  propagation, and engine/thread shutdown contracts.
- Validate a separately linked host, dependency discovery, startup/shutdown,
  expected packet results, and supported compiler/runtime combinations.

Acceptance: an independently built Windows application links through the
installed import library and runs with the packaged DLL/dependencies, without
depending on a Suricata executable entrypoint. Validate on a clean Windows
environment, not only the developer machine with its PATH restricted.

## Verification and scope

Previous probes recorded working static hosts, C and Rust DLL callbacks,
2,619 passing C unit tests, and 10 passing selected suricata-verify cases.
The unit tests are engine regression coverage, not 2,619 loader tests.
No reusable engine DLL, MSVC compatibility, live IPS, sustained-load safety,
or general multi-engine/reinitialization support was demonstrated.

Keep each deliverable in a focused feature branch and require its acceptance
checks before presenting it as supported. Review GPL-2.0 and dependency
distribution obligations for the intended host product; DLL loading does not
itself change licensing.
