# Suricata as a library: implementation, maturity, and Windows

Research date: 2026-10-25. Primary-source review of OISF upstream `main`, confirmed through the GitHub commits API to be `e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4`, the same upstream base as this checkout. This document separates source-supported conclusions from local experiments performed by the parent investigation on the isolated `research/windows-library-and-plugins` worktree.

## Executive conclusion

**Libsuricata is usable, its engine is mature, and its maintainer states an API/ABI stability policy within a major release as of 8.0. Developer experience and general-purpose embedding remain less mature.** On October 1, 2026, Jason Ish explained that Suricata itself is a library consumer, that patch releases should not break API/ABI unless completely unavoidable, and that major releases may break it. That contemporary statement is stronger than the older developer guide's “work in progress” wording. It is not a polished, independently packaged SDK or an opaque `engine_create → inspect_bytes → engine_destroy` interface. The intended model is to bring packets and threads to the engine while adapting to its lifecycle. [1–6,35]

**Windows static embedding is now locally demonstrated, but Windows DLL support is a separate gap.** The parent investigation compiled the stock simple/custom C host examples against the C and Rust engine archives and replayed an offline 12-packet fixture successfully. The shared-library build is still explicitly Linux-gated, generates an ELF `.so`, and provides no stock Windows DLL/export/import-library recipe. Neither this small experiment nor Windows application CI establishes production certification or a Windows plugin ABI. [5–7; local experiment summarized below]

## 1. What “library” actually means here

There are three related but different artifacts:

| Artifact | What it contains / does | What it does not establish |
|---|---|---|
| `src/libsuricata_c.a` | The C engine objects; also linked into the normal executable | A stand-alone engine: it needs the Rust archive and configured dependencies |
| `rust/.../libsuricata_rust.a` | Cargo-built Rust components, renamed from Cargo's `libsuricata.a` as necessary | A complete Rust-only Suricata engine |
| `libsuricata.so.<version>` | Optional Linux shared library collecting both archives with whole-archive linking | A portable Windows DLL or stable, narrow ABI |

`src/main.c` is now the small application bootstrap. It calls the same lifecycle routines used by embedding examples; most implementation lives in the archives. This is a genuine architectural change, not merely renaming the executable. [5–8]

The top-level `make install-library` installs both static archives, the optional shared library, and `libsuricata-config`. `make install-headers` installs the headers separately. This is opt-in; our Windows packaging script's executable/DLL output is not that library SDK. [5,6,9]

`libsuricata-config --cflags` prints the configured include flags; `--libs` prints link flags and dependencies. `--static` selects the C/Rust archives in repeated order because they have circular references. Even without `--static`, it falls back to static linking when the installed `libsuricata.so` is absent. It is a shell-based build helper, not a Windows runtime DLL. Its flags are tied to the installed configure result. [7]

### Rust names can be misleading

The root `suricata` Rust crate describes itself as “Suricata Rust components” and produces `staticlib` and `rlib` artifacts. Its `suricata-sys` workspace crate provides “Bindings to Suricata C interface”; `suricata-ffi` describes itself as “Nice wrappers around Suricata C interface.” The latter wraps configuration, detection, flows, logging, app-layer, thread, and plugin APIs. It does **not** expose a complete safe Rust engine lifecycle and arbitrary-byte inspection interface. These crates participate in a mixed C/Rust engine and should not be confused with an independent embedded IDS crate. [10–12]

## 2. What is already implemented

### Lifecycle and optional application behavior

The simple C and C++ examples show this sequence:

1. `SuricataPreInit(argv[0])` initializes engine-global state.
2. Optionally parse arguments (`SCParseCommandLine`) and load YAML (`SCLoadYamlConfig`); examples say configuration may instead be supplied through the configuration API.
3. Finalize runmode, optionally process internal command modes, optionally enable Suricata's signal handlers.
4. `SuricataInit()` then `SuricataPostInit()` start the engine.
5. `SuricataMainLoop()` runs/waits until stop is requested.
6. `SuricataShutdown()` then `GlobalsDestroy()` tear it down. [3,8]

This can largely reproduce the normal application with a replacement `main`. Signal handling became opt-in in the completed Suricata 8 issue [#6814](https://redmine.openinfosecfoundation.org/issues/6814). A host should make that choice deliberately; embedding a library should not unexpectedly replace the application's signal handlers. [13]

### Bring your own packets and threads

`examples/lib/custom` reads PCAP through libpcap only as an example source. In [#8082](https://redmine.openinfosecfoundation.org/issues/8082), Jason Ish explicitly says the packets “could be coming from anywhere,” but warns that the host must adapt to Suricata's threading model. `examples/lib/live` demonstrates live libpcap capture with host-created workers and up to 16 interfaces; that limit belongs to the example, not a documented engine limit. [4,14,15]

The current custom pipeline requires more integration than a single inspect call:

- Register a `RUNMODE_LIB` runmode and create `ThreadVars` during its setup callback, before thread sealing.
- Register a logical `LiveDevice` and initialize each host-owned worker using `SCRunModeLibSpawnWorker`.
- Allocate an engine packet, set source, time, datalink, device, and release callback, then supply packet data.
- Call `TmThreadsSlotProcessPkt(tv, tv->tm_slots, p)` to enter the normal decode/flow/detect pipeline.
- In the release callback, inspect actions such as `ACTION_DROP`, then return/free the engine packet. The host must implement actual forwarding/dropping/reinjection if it owns packet I/O. [4,15,16]

That path performs packet/flow/stream inspection, not just pattern matching. Do not assume arbitrary workers can process arbitrary packets without preserving the engine's flow/thread expectations. The VPP integration discussion documents blocking/crash problems when initialization and threading assumptions were not met; those reports illustrate integration difficulty rather than proving all VPP or library use fails. [14]

Shutdown is particularly important: examples explicitly say `SCTmThreadsSlotPacketLoopFinish` in the worker and `SuricataShutdown` in the main thread need to run concurrently. The live example joins its worker threads before `GlobalsDestroy`. The custom example does not explicitly join its worker, so the newer live example is the better lifecycle reference for a real integration. [4,15]

### Outputs and hooks

Available APIs include EVE file-type output registration (`SCRegisterEveFileType`), EVE augmentation callbacks (`SCEveRegisterCallback`), flow-update callbacks, and rate-filter action callbacks. EVE augmentation is **not** a universal “return all alerts from inspect()” operation: its documented role is adding fields immediately before an EVE object closes, and the header explicitly notes it does not cover stats records at this time. A custom EVE file type is a different facility for transporting serialized output. [17–19]

The packet release callback can expose the final packet action for host-owned enforcement. That is not equivalent to a stable per-packet structured verdict object containing every alert/event; integrations must select suitable hooks and account for flow/transaction events. [4,15,17]

## 3. What is unfinished or unsafe to assume

| Concern | Evidence / practical consequence |
|---|---|
| Independent engine instances | `src/suricata.c` still defines global `SCInstance suricata`; lifecycle functions take no engine handle. Removal of global state remains a future goal, with context work in #4684. Do not assume two isolated engines in one process. |
| Errors instead of process exits | The umbrella explicitly says a library should not fatal-exit under ordinary errors. Current engine code still contains `exit`/fatal paths; embedding does not automatically isolate host-process failure. |
| Header/config isolation | #6752 tracks installing/including generated `autoconf.h`; #6754 tracks header namespacing. Use matching generated headers/configuration, not an arbitrary installed release's headers. |
| Compatibility policy versus polished SDK | Jason explicitly states API/ABI stability within a major release as of 8.0, except unavoidable patch-release changes; major upgrades can break compatibility. This does not imply arbitrary Windows CRT/compiler interchangeability or that every internal header is a clean public contract. Examples expose `Packet`, `ThreadVars`, runmode and configuration details; use matching generated headers and validate supported combinations. The plugin version check is a separate mechanism. [35] |
| Already-reassembled or decrypted streams | #9150, opened October 2026, explicitly requests input without synthetic packets and is still New/TBD. Jason says it is not on the near-term roadmap. Existing integrations synthesize packets to reach app-layer parsing/detection. An arbitrary application-byte buffer is not interchangeable with packet ingress. [36] |
| Dedicated rule/tenant reload handles | #8095 remains Assigned, targeting 9.0-beta1. Existing internal reload functions are not the completed proposed embedding API. |

Sources: umbrella [2], source [8,20], stream/reload/context tickets [21–23], packaging/header tickets [24,25]. These are specific gaps; they do not mean no one can successfully embed Suricata today.

## 4. Suricata 8 versus 9 development

**Not a 9-only invention:** the `suricata-8.0.0` source tag already contains the simple/custom library examples and the developer guide labels the effort work-in-progress. Signal opt-in, rate-filter callbacks, and flow callbacks have completed 8.0 tracker targets. The live example was also delivered to 8.0.4: backport #8097 is Closed. Earlier PR #14284 is closed unmerged, but that does not mean the replacement effort failed; mainline work went through #14919 and #14953 into merged batch #14961. [13,18,19,26,37]

**Work continues for 9:** #2693 is In Progress, assigned to Jason Ish, targeting 9.0.0-beta1; its July 2025 journal explicitly says work continues toward 9. The dedicated #8098 release umbrella targets 9.0.0. Live library example work #8096 is Closed, targeting 9.0-beta1; the current source and Linux CI contain that example. Reload API #8095 remains Assigned rather than delivered. [2,22,27,28]

This means neither “libsuricata is entirely future work” nor “version 9 removes all embedding limitations” is supported by the evidence. The within-major compatibility policy already applies as of 8.0; usability and platform integration remain separate concerns. Target versions on open issues express planning, not delivery guarantees. [35]

## 5. Windows assessment

### Static embedding: demonstrated locally, with bounded coverage

The Windows build already links both static engine archives to produce the executable. The library example makefiles link those same archives and configured platform dependencies. Configure supplies Windows libraries such as `ws2_32`, `iphlpapi`, `Ole32`, `userenv`, `advapi32`, `bcrypt`, and others in `RUST_LDADD`. An MSYS2 UCRT64 host built against matching headers/archives is therefore a more realistic first target than an MSVC consumer or a drop-in DLL. [5,6,29]

The parent investigation's separate branch/worktree has now established:

- Stock `examples/lib/simple/main.c` and `examples/lib/custom/main.c` compile and statically link the engine into native Windows C hosts.
- Both replayed an offline 12-packet fixture successfully: each produced two alerts and one HTTP event, with normalized alert tuples equal to the unchanged baseline. This does not imply broader correctness coverage.
- The stock live example fails compilation because its `interface` identifier collides with a Windows COM interface macro. Renaming it to `interface_name` permits compilation; the patch is experimental, not an upstream fix.
- No live capture was performed. A compiling live example is not validation of Npcap capture, WinDivert enforcement, or live worker shutdown.

These are actual local results, not a claim of official Windows embedding support, broad ABI testing, or production qualification.

Static engine linking does not necessarily mean a fully static application: dependency DLLs may still be required. The successful small replay goes beyond `-V`, but does not establish reload safety, repeated initialization, sustained-load behavior, or correctness for all protocols and packet sources.

### Shared DLL: no stock implementation

`configure.ac` sets `can_build_shared_library=yes` only in the Linux branch. `BUILD_SHARED_LIBRARY` requires both `enable_shared=yes` and that platform flag. The implementation names the result `libsuricata.so.$(VERSION)` and uses ELF `-soname` / `--whole-archive` linking. It contains no counterpart producing `suricata.dll` plus an import library/export contract. Simply passing `--enable-shared` on Windows does not implement that missing platform support. [5,6]

Providing a Windows DLL would require deliberate PE/COFF export/import handling, consistent C/Rust/dependency linkage and CRT allocation ownership, plus a defined public API. A matched MinGW/UCRT64 executable using static engine archives avoids part of that DLL boundary problem, but not the engine's lifecycle/global-state limitations. These are engineering implications of the observed build design, not an upstream published DLL roadmap.

The parent also tried a manual whole-archive Windows DLL link. It failed:
`win32-service.o` references application `main`, ultimately producing unresolved
`WinMain` through the MinGW startup library. No engine DLL was produced. This
is a concrete service/host entrypoint coupling to address, not proof DLLs are
impossible. See [combined experiments](WINDOWS-LIBRARY-PLUGINS-RESEARCH.md).

### CI and support evidence

The upstream workflow explicitly exercises Linux library builds in-tree and out-of-tree, runs the custom PCAP example and asserts a packet count, and builds the live example. Windows CI jobs build/test Suricata as an application; no equivalent Windows library-example test was found in those jobs. Consequently, successful Windows application CI must not be described as Windows embedding parity. [30]

For this project: extend the initial same-toolchain offline proof with custom packets/verdict callbacks, error handling, and concurrency coverage. Only subsequently decide whether an application-owned service around the engine is sufficient or a reusable DLL API is actually needed. Live Npcap/WinDivert capture is a separate capability from embedding and does not gate an offline library test.

## 6. Upstream roadmap worth following

| Issue | State / target observed | Why it matters |
|---|---|---|
| [#2693](https://redmine.openinfosecfoundation.org/issues/2693) | In Progress / 9.0-beta1 | Main library umbrella, Jason Ish |
| [#8098](https://redmine.openinfosecfoundation.org/issues/8098) | Assigned / 9.0.0 | Release umbrella |
| [#8095](https://redmine.openinfosecfoundation.org/issues/8095) | Assigned / 9.0-beta1 | Callable rule and tenant reload API; desired 8.0 backport |
| [#9150](https://redmine.openinfosecfoundation.org/issues/9150) | New / TBD | Reassembled/decrypted stream ingestion without synthetic packets; explicitly not near-term [36] |
| [#4684](https://redmine.openinfosecfoundation.org/issues/4684) | Assigned / TBD | Instance/per-thread context types and global-state work |
| [#6752](https://redmine.openinfosecfoundation.org/issues/6752) | New / TBD | Generated configuration header leakage |
| [#6754](https://redmine.openinfosecfoundation.org/issues/6754) | New / TBD | Header namespacing / out-of-tree ergonomics |
| [#8109](https://redmine.openinfosecfoundation.org/issues/8109) | Triaged / 9.0-beta1 | Application naming and library logging ownership |
| [#9152](https://redmine.openinfosecfoundation.org/issues/9152) | Assigned / 9.0-beta1 | OpenBSD pledge opt-in: another example of application behavior needing separation |

The non-closed local issue snapshot was also searched. Example requests for an Apache/Nginx integration (#4430), libnids-like application (#4431), and Wireshark plugin (#4432) remain ideas/backlog rather than evidence of shipped integrations. No dedicated Windows DLL or finished Windows embedding roadmap was found in the reviewed material. This is a bounded search result, not proof no unpublished work exists. [31–33]

## 7. Licensing and distribution

Suricata's root license is GPL version 2 and the Rust workspace explicitly declares `GPL-2.0-only`. The example applications themselves carry GPLv2 notices. Embedding or making a DLL does not itself relicense the engine under a permissive license. Review the actual distribution model, source/license obligations, and dependency licenses before distributing a host product. Do not assume static versus dynamic linking, a plugin boundary, or Windows changes that automatically. This is source/license identification, not legal advice or a determination about a particular combined product. [3,10,34]

## Sources

Pinned source links below refer to the upstream commit reviewed; tracker statuses were checked against the local 2026-10-25 public mirror, with the principal umbrella, reload, global-context, stream-ingress and completed milestone issues also rechecked live through Redmine's public API.

1. [Official latest developer guide](https://docs.suricata.io/en/latest/devguide/libsuricata/index.html).
2. [#2693 library umbrella and development goals](https://redmine.openinfosecfoundation.org/issues/2693).
3. [Simple C example](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/lib/simple/main.c).
4. [Custom packet/thread example](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/lib/custom/main.c).
5. [Platform configure and shared-library condition](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/configure.ac).
6. [C archive, shared-library and header installation recipes](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/Makefile.am).
7. [libsuricata-config implementation](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/libsuricata-config.in).
8. [Application bootstrap](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/main.c).
9. [Top-level installation targets](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/Makefile.am) and [Rust archive installation](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/Makefile.am).
10. [Rust workspace / crate types / license](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/Cargo.toml.in).
11. [suricata-ffi manifest](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/ffi/Cargo.toml.in) and [module surface](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/ffi/src/lib.rs).
12. [suricata-sys manifest](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/sys/Cargo.toml.in).
13. [#6814 opt-in signals, completed for 8](https://redmine.openinfosecfoundation.org/issues/6814).
14. [#8082 VPP integration discussion and maintainer guidance](https://redmine.openinfosecfoundation.org/issues/8082).
15. [Live capture example](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/lib/live/main.c) and [README](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/lib/live/README.md).
16. [Library runmode helpers](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/runmode-lib.c).
17. [EVE API and limitations](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/output-eve.h).
18. [#7320 flow update callbacks, completed](https://redmine.openinfosecfoundation.org/issues/7320).
19. [#7673 rate-filter callback, completed](https://redmine.openinfosecfoundation.org/issues/7673).
20. [Engine globals and lifecycle implementation](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/suricata.c) and [public declarations](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/suricata.h).
21. [#9150 stream input](https://redmine.openinfosecfoundation.org/issues/9150).
22. [#8095 reload API](https://redmine.openinfosecfoundation.org/issues/8095).
23. [#4684 global/instance context work](https://redmine.openinfosecfoundation.org/issues/4684).
24. [#6752 generated configuration headers](https://redmine.openinfosecfoundation.org/issues/6752).
25. [#6754 namespaced headers](https://redmine.openinfosecfoundation.org/issues/6754).
26. [8.0.0 custom example](https://github.com/OISF/suricata/blob/suricata-8.0.0/examples/lib/custom/main.c) and [8.0.0 library guide](https://github.com/OISF/suricata/blob/suricata-8.0.0/doc/userguide/devguide/libsuricata/index.rst).
27. [#8098 Suricata 9 library umbrella](https://redmine.openinfosecfoundation.org/issues/8098).
28. [#8096 live library example, completed](https://redmine.openinfosecfoundation.org/issues/8096).
29. [Custom in-tree archive linking](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/lib/custom/Makefile.am).
30. [Upstream CI library checks and Windows application jobs](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/.github/workflows/builds.yml).
31. [#4430 Apache/Nginx example](https://redmine.openinfosecfoundation.org/issues/4430).
32. [#4431 libnids-like example](https://redmine.openinfosecfoundation.org/issues/4431).
33. [#4432 Wireshark example](https://redmine.openinfosecfoundation.org/issues/4432).
34. [Root GPLv2 license](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/LICENSE).
35. [Jason Ish, October 1, 2026: maturity and within-major API/ABI policy](https://forum.suricata.io/t/libsuricata-status/6476/3).
36. [Jason Ish: packetless input not near-term, packet-based integration remains first class](https://forum.suricata.io/t/packetless-application-layer-interface/6477/3) and [follow-up](https://forum.suricata.io/t/packetless-application-layer-interface/6477/5).
37. [#8097 live-example backport, Closed / 8.0.4](https://redmine.openinfosecfoundation.org/issues/8097), [replacement PR #14953](https://github.com/OISF/suricata/pull/14953), and [merged batch #14961](https://github.com/OISF/suricata/pull/14961).
