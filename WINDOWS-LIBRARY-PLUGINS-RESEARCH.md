# Suricata embedding and plugins on Windows: research and experiments

Research and test date: 2026-10-25. Upstream baseline:
`e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4`, Suricata 9.0.0-dev.
Three research agents independently examined library APIs, plugins, and the
public roadmap; the main investigation built and ran the Windows probes below.

## Direct answers

| Question | Current upstream status | What actually worked here |
| --- | --- | --- |
| Suricata as a library? | Real, usable packet/thread embedding, already in 8.0. The maintainer calls engine stability mature, while developer experience remains unfinished. | Stock simple and custom C hosts linked the engine and inspected a PCAP. |
| Library on Windows? | Static engine archives exist. The standalone shared-library recipe is Linux-gated; no stock Windows DLL/SDK build was found. | Native GNU/UCRT64 static hosts worked. The naive engine-DLL link failed on a Windows service dependency on application `main`. |
| Plugins? | Real capture, protocol, detection and output extension points, but officially experimental. | Existing examples exercise useful APIs; this is not just proposed functionality. |
| Plugins on Windows? | Disabled by stock configure and missing a native loader/export recipe; no targeted public delivery plan found. | An isolated prototype loaded unmodified C and Rust examples as real Windows DLLs and executed their callbacks. |

The Windows result is stronger than "probably portable," but weaker than
"Windows plugins are now supported upstream." The experiment deliberately
bypasses configure and is not a finished distribution or supported SDK.

## 1. Library maturity: more developed than the old documentation suggests

In his [October 1 maintainer answer](https://forum.suricata.io/t/libsuricata-status/6476/3),
Jason Ish separates engine stability from API ergonomics: the executable is
itself a library consumer; the engine is mature; the developer experience needs
more work. As of 8.0, the stated policy is to preserve API/ABI within a major
release, except unavoidable patch-release changes. Major releases may break it.
That is a maintainer policy, not proof that every Windows compiler/CRT/header
combination is interoperable.

The existing components are:

- `libsuricata_c.a`: C engine objects.
- `libsuricata_rust.a`: Rust engine components; both archives and dependencies
  are needed, not just the Rust crate.
- Optional Linux `libsuricata.so`: combined shared library.
- `libsuricata-config`, `make install-library`, and `make install-headers`:
  build/install helpers rather than an independently polished Windows SDK.
- `suricata-sys` and `suricata-ffi`: raw C bindings and Rust wrappers, **not** a
  complete safe Rust API for creating an engine and inspecting arbitrary bytes.

Sources: [build recipes](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/Makefile.am),
[link helper](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/libsuricata-config.in),
[Rust wrappers](https://github.com/OISF/suricata/tree/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/ffi).

### The intended input model is packets, not an arbitrary L7 byte buffer

An embedding host initializes the engine, supplies packets through engine
workers, follows flow/thread ownership rules, consumes events, and coordinates
shutdown. The [custom example](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/lib/custom/main.c)
uses PCAP only as a convenient input source; the source can be replaced with
host-owned packets. A release callback can inspect packet actions, while actual
drop/reinjection remains the host's responsibility. EVE output transport and EVE
enrichment are separate hooks, not a single synchronous "return all alerts" API.

Direct input of already-reassembled or decrypted streams is requested in
[#9150](https://redmine.openinfosecfoundation.org/issues/9150), but Jason explicitly
says it is **not on the near-term roadmap**. Current adapters may reconstruct
packets. That pattern is intended to remain first-class; a particular external
prototype is not thereby certified production-ready.
[Maintainer discussion](https://forum.suricata.io/t/packetless-application-layer-interface/6477/3)

Other boundaries remain important: global engine state, fatal-exit paths,
generated/private headers, initialization ordering, and concurrent worker/main
shutdown. Do not assume multiple isolated engine instances or ordinary-error
recovery merely because the engine is linked as a library.
[Library umbrella](https://redmine.openinfosecfoundation.org/issues/2693),
[global context work](https://redmine.openinfosecfoundation.org/issues/4684)

## 2. Plugins: real extensions, not a stable universal SDK

A native plugin runs inside the Suricata process, exports `SCPluginRegister`,
returns an `SCPlugin` descriptor, and registers initialization/callbacks. Existing
extension points cover packet sources, application parsers and keywords, EVE
destinations/enrichment, low-level logging, flows, and thread state. PF_RING and
Napatech already use plugins in Suricata 8; nDPI is another bundled example.

The header's API marker changes from `0x0800` in 8.x to `0x0900` in our 9.x
source. The loader checks exact equality; the descriptive version string is
logged rather than used as an additional ABI validator. Use controlled build
pairs and C-compatible/opaque FFI boundaries, not arbitrary Rust-native layouts.
There is no general plugin hot-reload/unload API or official mature package
ecosystem. Native extensions are trusted code, not a sandbox.

Sources: [plugin header](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/suricata-plugin.h),
[loader](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/util-plugin.c),
[examples](https://github.com/OISF/suricata/tree/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/plugins),
[plugin umbrella](https://redmine.openinfosecfoundation.org/issues/4101).

Two documentation traps emerged: transaction loggers can now be registered from
plugins despite an obsolete warning, and newer Rust examples use `suricata-ffi`
rather than the older context arrangement described in some prose.
[#7236 implementation](https://redmine.openinfosecfoundation.org/issues/7236),
[#7840 documentation correction](https://redmine.openinfosecfoundation.org/issues/7840)

## 3. Windows stock support versus the prototype

Stock configure requires `dlfcn.h` and a successful `-rdynamic` link test to
enable plugins. Our UCRT64 environment lacks the header and GCC rejects that
flag. The loader uses POSIX `dlopen`/`dlsym` and discovers `.so` files, not DLLs.
The engine's shared-library target also sets its platform capability only on
Linux and uses ELF `.so`/soname conventions.
[Configure](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/configure.ac),
[loader](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/util-plugin.c)

The research branch adds a native loader using `LoadLibraryExA`,
`GetProcAddress`, safe dependency-search flags, and `.dll` discovery. It
recompiles only the three `HAVE_PLUGINS`-conditional C translation units into a
**copy** of the baseline archive. A PE-exported host executable and matching
import library provide calls from DLL plugins back into the engine. This avoids
installing a POSIX shim or changing the original build.

Both the C plugin and the Rust plugin source are unmodified upstream examples.
The Rust example's stock build leaves host functions unresolved. Overriding
its platform-sensitive linker settings with the host import library resolves
the tested example. This is not proof that every plugin has all symbols it needs.

The import library names `suricata-plugin-host.exe`. Plugins built against it
are tied to that host name/export arrangement; renaming the executable or
using them in another host requires appropriate relinking. A production design
needs a deliberate public export contract, not this broad export-all shortcut.

**Generated configure/build-info data still describes the baseline as having
plugins disabled.** Runtime initialization and callback output prove the
prototype works; its generated feature summary is not an integrated port.

### Shared engine DLL: a distinct unsuccessful experiment

A manual whole-archive engine DLL link failed. The Windows service object
references application `main`, and MinGW ultimately reported unresolved
`WinMain`. Symbol inspection traced it to `win32-service.o`; it was not a
missing Npcap dependency. The standalone DLL was not produced. An incomplete
import-library artifact from a failed link is not a usable engine DLL.

This is an additional Windows library/host-entrypoint boundary to design, not
proof a DLL is impossible. The successful plugin proof exports a working EXE;
it does not depend on a successfully built engine DLL.

## 4. Actual Windows tests

Toolchain: MSYS2 UCRT64 GCC 15.1.0, Rust 1.87.0; native x86-64 Windows binaries.
Only offline PCAP inputs were used. No driver was installed and no traffic was
captured or intercepted.

| Test | Result | Scope |
| --- | --- | --- |
| Stock simple static host | Pass | Startup and 12-packet PCAP inspection. |
| Stock custom packet/thread host | Pass | Host-owned worker feeds engine packets and completes shutdown. |
| Alert equivalence | Pass | Both hosts and baseline each produce 2 alerts + 1 HTTP record; normalized SID/address/port/protocol tuples match. |
| Stock live example | Compile failure | Windows COM macro expands the field name `interface`. |
| Live example with `interface_name` rename | Compiles | Compile-only: no live capture or Npcap validation. |
| Stock plugin configure/link approach | Unavailable | Missing `dlfcn.h`, unsupported `-rdynamic`; existing loader compiled out. |
| C EVE DLL, explicit path | Pass | Real registration, initialization, 2 alert writes and 1 HTTP write. |
| C EVE DLL, directory discovery | Pass | `.dll` discovery and callback execution. |
| Stock Rust plugin linkage | Fails | Unresolved host functions such as `SCJbGetMark` and `SCLogGetLogLevel`. |
| Rust DLL with host import library | Pass | Raw/wrapped EVE enrichment, flow state, and thread lifecycle callbacks. |
| Prototype host built-in C suite | 2,619 passed, 0 failed | No claim of new plugin-specific unit coverage. |
| Selected Suricata-Verify cases with Rust plugin injected | 10 passed, 0 failed, 0 case skips | HTTP, HTTP/2, DNS, SMB, TLS, and a rule-limit negative case; not the full suite. Plugin initialization confirmed in 9 logs; one negative case exits before initialization. |
| Wrong API marker | Rejected before Init | An 8.x-marker test DLL cannot initialize in the 9.x host. |
| Missing DLL / registration function | Diagnosed | Engine still exits 0; load failures are non-fatal in upstream-style handling. |
| Copied runtime, Windows-only PATH | Pass | Static-host startup and Rust-plugin PCAP inspection without MSYS2 directories on PATH; not an independent clean-machine test. |
| Combined native engine DLL | Link failure | Service-to-application entrypoint dependency described above. |

The verification adapter uses the pinned upstream runner and unchanged test
assertions; it overrides only binary selection and adds `--plugin`. Outputs go
into fresh research directories. The unit suite runs before normal engine
plugin initialization, so it is regression coverage for the prototype host,
not 2,619 tests of the plugin loader.

Plugin load health cannot be inferred from exit status alone. The stock build
also accepts a nonexistent `--plugin` argument without loading it, because the
CLI parser exists even when plugin initialization is compiled out. Positive
tests therefore assert actual initialization, callbacks and JSON fields.

## 5. What developers plan next

| Work | Public status on research date |
| --- | --- |
| [Library umbrella #2693](https://redmine.openinfosecfoundation.org/issues/2693) | In Progress, Jason Ish, 9.0-beta1; basic embedding is already usable. |
| [Library release tracking #8098](https://redmine.openinfosecfoundation.org/issues/8098) | Assigned, Victor Julien, 9.0.0. |
| [Callable reload API #8095](https://redmine.openinfosecfoundation.org/issues/8095) | Assigned, Jason Ish, 9.0-beta1; desired ruleset/tenant control API, not a completed replacement for the Unix socket. |
| [Transport-independent command API #4704](https://redmine.openinfosecfoundation.org/issues/4704) | New, 9.0-beta1; relevant to library users and future Windows control transports. |
| [Remove global SCInstance #8106](https://redmine.openinfosecfoundation.org/issues/8106) | In Progress, 9.0-beta1. |
| [Packetless stream ingestion #9150](https://redmine.openinfosecfoundation.org/issues/9150) | New/TBD, explicitly not near-term. |
| [Rust plugin support #7499](https://redmine.openinfosecfoundation.org/issues/7499) | New/TBD; existing examples already work in some environments. |
| [Plugin package manager #8094](https://redmine.openinfosecfoundation.org/issues/8094) | Triaged/TBD, proposal rather than a shipped ecosystem. |

I found no targeted public Windows DLL-library/plugin port, owner, or delivery
release. That is a bounded public-source search, not proof of no private work.
The successful local prototype does not change the upstream roadmap.

## 6. Practical recommendation

For a custom native Windows application today, **matched-toolchain static
embedding is the closest to a demonstrated usable path**. Start from the
packet/thread examples; keep lifecycle and error handling explicit. It does
not require Npcap when the host supplies packets or uses offline data.

For modular extensions to a Windows Suricata executable, **DLL plugins are
technically viable**, as demonstrated for both C and Rust. A proper port still
needs configure/build/install integration, a reviewed export contract, runtime
ownership rules, Unicode/long-path support, and Windows CI. App-layer, nDPI and
capture plugins need their own validation. Throughput, sustained concurrency,
repeat init/shutdown, multiple engines and live IPS were not tested.

For a reusable Windows engine DLL/foreign-language SDK, do not treat either
proof as completion: that is a separate product/API and packaging effort.
Suricata remains GPL-2.0; embedding or changing to DLL loading does not itself
relicense it. Review distribution and dependency obligations for a host product.
This identifies source licensing, not legal advice.

## Files, branch and evidence

Experiments live in the separate worktree on branch
`research/windows-library-and-plugins`:

`.build-tmp/library-plugins/worktree/experiments/windows-library-plugins/README.md`

That README lists the reproducible commands and prototype limitations. Source
changes are confined to that worktree's `src/util-plugin.c` and
`examples/lib/live/main.c`, plus the experiment harness. The original feature
branch, executable, and existing build remain separate; `main` is untouched.
The research and [implementation plan](WINDOWS-LIBRARY-PLUGINS-PLAN.md) are
tracked separately from the uncommitted experimental code and local evidence.
Committing these documents does not publish or integrate the prototype.

Evidence root: `.build-tmp/library-plugins/worktree/.build-tmp/library-plugin-probes/`.
Key completed run directories:

- `runs/20261025T115854/`: fresh static-host/baseline comparison.
- `plugin-runs/20261025T120258/`: native C DLL registration and output.
- `rust-runs/20261025T120525/`: native Rust DLL callbacks and enriched JSON.
- `negative-runs/20261025T120801/`: version/entrypoint/path negative checks.
- `verify-runs/20261025T121348/`: ten selected integration cases.
- `native-runtime/20261025T121352882Z/`: copied bundle and restricted-PATH run.
- `unit-tests.log`, `live-stock-build.log`, `dll-build.log`, and Rust build logs.

Detailed primary-source appendices:

- [Library implementation and Windows](LIBSURICATA-RESEARCH.md).
- [Plugin APIs, examples and Windows proof](SURICATA-PLUGINS-RESEARCH.md).
- [Developer statements, delivered work and roadmap](LIBRARY-PLUGINS-ROADMAP.md).
