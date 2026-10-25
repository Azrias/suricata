# Suricata plugins, including Windows

Research date: 2026-10-25. Source baseline: OISF Suricata main at
`e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4` (9.0.0-dev), compared with
`suricata-8.0.7`. Public GitHub and Redmine statuses were queried live on the
research date. This report distinguishes the existing plugin API from a usable
Windows plugin implementation; they are not the same thing.

## Conclusions

- Suricata has real, useful native plugins, not merely a proposal: bundled
  capture plugins, nDPI, application-layer examples, custom output examples,
  and Linux CI exercise them. Nevertheless, configure explicitly labels plugin
  support **experimental**, and the umbrella remains **In Progress / TBD**.
  [Source: configure][configure], [tracker #4101][4101], [CI][ci].
- Our current UCRT64 executable does **not** have plugin support. There are two
  confirmed configure blockers: absent `dlfcn.h`, and GCC rejecting `-rdynamic`.
  This is more than an untested example: the loader is compiled out.
  Local evidence: `configure-windows.log:254–255,447`,
  `config.log:8484–8488`, `src/autoconf.h:414–415`.
- A native Windows port is technically feasible, but requires loader,
  symbol-linkage, build-system and validation work. Installing a POSIX loader
  shim or renaming `.so` to `.dll` is not a complete solution.
  [Source: loader][loader], [configure][configure], [example makefile][example-make].
- **We proved native Windows plugins locally**, in an isolated research
  worktree: both the unmodified C EVE filetype example and the unmodified Rust
  omnibus example built as real PE DLLs, loaded into a modified native host,
  and executed callbacks on a known PCAP. This required an experimental loader
  patch and explicit host export/import linkage; it is not upstream/released
  Windows support. [Experiment details below](#local-native-windows-proof).
- I found no public Windows-specific plugin implementation PR or delivery
  target in the searched upstream sources. That is a search result, not proof
  that nobody has private plans. Existing roadmap items mostly improve APIs,
  Rust wrappers and packaging, not Windows loading. [Roadmap below](#public-roadmap).

## What “plugin” means here

A native plugin is a dynamic library loaded into the Suricata process. It
exports `SCPluginRegister`, returns an `SCPlugin` descriptor, and supplies an
initialization function. The descriptor includes API version, Suricata version
string, plugin name/version, author and license. The loader verifies the API
version and then calls initialization. Plugins are specified by YAML `plugins:`
paths or repeated `--plugin <path>` options. Capture plugins can additionally be
selected by `--capture-plugin <name>` and passed capture-specific arguments.
[Header][header], [loader][loader], [command processing][engine].

This is different from embedding libsuricata in your own application: in a
plugin, **Suricata remains the host executable**. It is also different from
Suricata's Lua facilities. The proposed future package manager discusses Lua
scripts as another kind of extension, but that does not make Lua a native
`SCPlugin` ABI. [#8094][8094].

| Extension | Existing source evidence | Important qualification |
|---|---|---|
| Packet capture | `SCCapturePlugin`, bundled PF_RING and Napatech; `ci-capture` example | Hardware SDK, OS and capture correctness must be evaluated separately from generic loader support. |
| Application protocol parsing | `SCAppLayerPlugin`, `examples/plugins/altemplate` | Registers parser, detection keywords and optional simple EVE transaction logger. |
| Detection keywords | Dynamic keyword registration and nDPI rules | This is not a universal replacement for all internal detection interfaces; the lite API has setup/free/app-layer match callbacks, no validation member. |
| EVE destinations | `SCEveFileType`; `c-json-filetype` example | Custom writer destination, with initialization, write and thread callbacks. |
| EVE enrichment | EVE callbacks; Rust example | Adds information to existing EVE records. |
| Low-level logging | `c-custom-loggers`: packet, flow and DNS transaction callbacks | Register at the logging-ready lifecycle point, not too early in plugin initialization. |
| Flow/thread integration | Flow lifecycle and thread callbacks; Rust storage wrappers | Registration and ownership rules still apply; plugin loading is not hot-reloading. |

Sources: [plugin examples][examples], [plugin ABI][header], [nDPI documentation][ndpi-doc],
[Rust example][rust-example], [C custom logger][custom-logger],
[flow lifecycle documentation][flow-doc], [Rust lite keyword bindings][sys].

## Suricata 8 versus 9 development

Suricata 8 already uses dynamic plugins for PF_RING and Napatech. These are not
features waiting for Suricata 9. The 8.0 upgrade notes document the conversion
and the required YAML plugin path. [PF_RING][pfring-doc], [Napatech][napatech-doc].

The plugin ABI constant in 8.0.7 is `0x0800`; our 9.0-dev header uses `0x0900`.
The loader compares this value for **exact equality**. An 8-series plugin is
therefore rejected by a 9-series host even if its dynamic library can be opened.
The Suricata version string is logged, not itself used as a second equality
check. A major/minor version gate is not a guarantee that arbitrary headers,
build options, Rust layouts or internal symbols are safe across builds. Use
matching headers and a controlled build pair. [8.0.7 header][header8],
[9.0-dev header][header], [version check][loader].

Current main has `suricata-sys` raw C bindings and `suricata-ffi` ergonomic
wrappers. Both example Rust plugins depend on those crates by source-tree path.
The omnibus Rust example demonstrates EVE callbacks, per-flow state, per-thread
state and lifecycle callbacks. `suricata_ffi::plugin::init()` initializes the
plugin logging level; `Plugin::into_raw()` constructs the C ABI descriptor.
This is evidence of active Rust support, **not** a guarantee of a fully stable,
standalone SDK for arbitrary plugin purposes or Windows. [Rust example][rust-example],
[plugin wrapper][rust-plugin], [Cargo manifests][examples].

Keep the FFI boundary C-compatible. In particular, do not share arbitrary Rust
struct layout between independently compiled modules: use opaque pointers and
the supported C/wrapper APIs for JSON and engine objects. Upstream explicitly
warns about non-`repr(C)` types in plugins. [Developer documentation][dev-doc].

## Documentation traps uncovered

1. **Transaction logger support is implemented.** The current developer output
   page still says transaction loggers cannot be registered from plugins.
   Upstream #7236 is **Closed**, fixed in **8.0.0-rc1**; Jason Ish explicitly
   identifies that warning as obsolete in #7840. The source example correctly
   calls `SCRegisterOnLoggingReady` and registers a DNS transaction logger from
   that callback. Do not quote the old warning as the current API limitation.
   [#7236][7236], [#7840][7840], [working example source][custom-logger].
2. The application-plugin documentation still describes
   `suricata::plugin::init()` and an older Rust context arrangement. Current main
   examples use `suricata_ffi::plugin::init()`; inspect the example and matching
   source version when implementing. [Older prose][dev-doc],
   [current Rust helper][rust-plugin].
3. Both Rust example Cargo configurations include
   `-Clink-args=-Wl,-undefined,dynamic_lookup`. This is a platform-sensitive
   linker convention, **not a ready-made Windows linking strategy**.
   [Example config][rust-config].

## Why Windows is not working today

### Confirmed in our checkout/build

`configure.ac` checks for `dlfcn.h`, adds `-rdynamic`, and tries to link a test
program that includes the header. Only success defines `HAVE_PLUGINS`. On our
UCRT64 toolchain, the header is absent and GCC rejects `-rdynamic`. The configure
summary consequently says `Plugin support (experimental): no`.
[Configure source][configure]; local log evidence listed above.

The active loader is entirely inside `#ifdef HAVE_PLUGINS` and uses POSIX
`dlopen(..., RTLD_NOW)`, `dlsym`, `dlerror` and `dlclose`. There is no Win32
`LoadLibrary`/`GetProcAddress` branch in this file. Directory discovery accepts
names containing `.so`, not `.dll`. An explicit file path bypasses the directory
name filter, but does **not** bypass disabled plugin support or solve linkage.
[Loader source][loader].

**Testing pitfall:** the command parser accepts `--plugin` regardless of
`HAVE_PLUGINS`, while the actual `SCPluginsLoad` invocation is conditional. A
successful Suricata exit code with `--plugin` is therefore insufficient evidence
that any plugin was loaded. Require an initialization log and a plugin-produced
behavior/output marker. [Engine command and initialization code][engine].

### What a Windows port would need (engineering inference)

1. A deliberate Windows configure branch and loader implementation, or a
   validated `dlfcn-win32` equivalent. Do not merely force the feature macro.
2. A strategy for plugin-to-host calls. Unix examples leave Suricata symbols
   unresolved in the shared object and resolve them from the running host.
   Windows PE linking normally needs deliberate exports/imports: for example,
   an exported Suricata DLL with an import library, or a carefully exported EXE
   and matching import library; alternatively an explicit versioned function
   table ABI. These are alternatives to investigate, not features upstream
   already supplies. [Loader][loader], [example build][example-make].
3. DLL discovery, dependency-search hardening, install rules and Rust target
   linker configuration. Keep GCC/UCRT64 and Rust GNU-target artifacts
   compatible; “Windows supported” would not imply MSVC support.
4. Explicit cross-module ownership rules, C ABI layout, calling conventions and
   matching runtime/build configuration; do not pass privately laid-out Rust
   objects or free allocations using an unrelated module allocator.
5. Windows CI covering registration, version mismatch, missing entry point,
   missing dependent DLLs, real callbacks, traffic processing and shutdown.

Historical developer context supports this distinction: Jason Ish's initial
2020 plugin draft explicitly said Linux-only and noted that Windows needed a
different linking arrangement/full Suricata source or a Suricata DLL. A 2021
bootstrap proposal still referred to Windows as a platform where plugin
support had not been figured out. These are **historical explanations**, not
evidence that Windows is permanently impossible. [PR #4873][4873],
[PR #5343][5343].

The inspected Windows jobs in upstream `builds.yml` build Suricata, run C unit
tests and suricata-verify, but do not build/load the native plugin examples.
Plugin example execution exists elsewhere in the large workflow, including
Linux coverage. Thus passing Windows CI is not evidence of Windows DLL plugin
support. [Workflow][ci].

## Lifecycle and security limitations

The loader initializes plugins during engine setup. Its successful-load handle
list is retained; the source comments describe it as a place to keep handles,
possibly usable for an unload destructor in future. `SCPlugin` itself currently
has **only `Init`, no global deinitialization callback**. Failure paths close a
library, but the generic interface does not implement hot unload/reload of
successful plugins. Individual APIs can still have thread/output cleanup
callbacks. Rule reload and plugin reload should not be conflated.
[Header][header], [loader][loader], [filetype example][filetype].

Plugins are native code in the engine process. API version checking is not a
security sandbox, code-signature check or memory isolation boundary. Treat the
plugin and all its dependency DLLs/shared libraries as trusted engine code.
This is an architectural conclusion from direct dynamic loading and callback
execution, not a claimed upstream security guarantee. [Loader][loader].

## Local native Windows proof

The parent investigation performed and this report inspected native UCRT64
experiments in `.build-tmp/library-plugins/worktree/`, on a separate research
branch/worktree. The packaged baseline executable and normal configure results
were not changed. Artifacts and logs below are local, generated evidence, not
upstream support promises.

### How the experimental host was built

The proof deliberately bypassed configure. It copied the already-built baseline
C archive and recompiled the only three C translation units conditional on
`HAVE_PLUGINS`: `suricata.c`, `runmodes.c` and `util-plugin.c`. Those replacement
objects were inserted into the copied archive; the executable linked that
archive and the baseline Rust archive. The host was linked with
`--export-all-symbols` and an explicit `--out-implib` PE import library.

The only loader source adaptation was a research Win32 branch in
`src/util-plugin.c`: `GetFullPathNameA`,
`LoadLibraryExA(..., LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR |
LOAD_LIBRARY_SEARCH_DEFAULT_DIRS)`, `GetProcAddress`, `FreeLibrary`, numeric
Windows loader errors, and `.dll` directory discovery. The Windows dependency
search deliberately did not add arbitrary working-directory/PATH lookup.

Consequently, **the baseline configure summary/build information still says
plugins are disabled**. This host is a bespoke proof, not a normal supported
configuration and not a production patch. Conversely, its successful callback
execution is stronger evidence than mere DLL loading or command acceptance.

### Observed results

| Probe | Actual observation |
|---|---|
| Stock C EVE filetype example | Compiled as `filetype.dll` against the host import library; loaded by explicit filename and by directory discovery. |
| C plugin functionality | Initialization and thread callbacks ran; write callbacks produced **2 alert records and 1 HTTP record** while processing the **12-packet** fixture. |
| Stock Rust build settings | Offline build reached the Windows linker but failed with unresolved Suricata C functions, including `SCJbGetMark` and `SCLogGetLogLevel`. Do not describe this observed failure merely as an unrecognized linker flag. |
| Rust example with host linkage | Setting `RUSTFLAGS='-C link-arg=<absolute host import-library path>'` replaced the example's default linker flags; the unmodified Rust plugin source built as a Windows DLL. |
| Rust plugin functionality | Raw and wrapped EVE enrichment appeared in actual JSON; thread initialization and flow init/update/finish callbacks ran. Flow accounting reached **12 packets**. |
| Plugin-enabled host C unit tests | **2,619 passed; 0 failed**. This is not a full suricata-verify or performance validation of the plugin port. |
| Wrong API version | An `0x0800` plugin was rejected by the `0x0900` host before its initialization callback. |
| Missing registration entry / missing DLL | Diagnostic logged. The engine nevertheless exited **0**, consistent with the generic upstream loader's non-fatal handling. Do not use engine exit status alone as a plugin-health check. |

Inspected evidence, relative to
`.build-tmp/library-plugins/worktree/.build-tmp/library-plugin-probes/`:

- `plugin-runs/20261025T120258/explicit-dll.log` and `directory.log`: C plugin
  registration, initialization, EVE writes and 12-packet replay.
- `rust-plugin-stock-build.log` and `rust-plugin-import-build.log`: failure
  without host linkage and successful explicit-import build.
- `rust-runs/20261025T120525/run.log` and `eve.json`: Rust callbacks and the
  `foobar` / `rust_wrapped` output fields, including flow accessors/state.
- `negative-runs/20261025T120801/`: ABI mismatch, missing file and missing
  registration entry diagnostics.
- `unit-tests.log`: final C unit-test totals.

Additional parent checks passed after the initial proof: ten selected
Suricata-Verify cases with Rust-plugin injection (zero failed or case-skipped),
and an offline Rust-plugin run from a copied DLL bundle with only Windows
system directories on PATH. This is not a full-suite or separately provisioned
machine test. See [combined research and evidence](WINDOWS-LIBRARY-PLUGINS-RESEARCH.md).

The build scripts were inspected read-only at
`experiments/windows-library-plugins/plugin-probes.sh` and
`rust-plugin-probe.sh` in that worktree. They use copied/generated metadata,
baseline libraries, explicit native linkage and separate output directories.
Their evidence is scoped to the tested source/build pair, not an independent
clean configure/install pipeline.

### What this proves, and what it does not

This proves the **technical feasibility of native C and Rust Suricata DLL
plugins on this Windows GNU/UCRT64 build**, with real traffic-processing
callbacks. It also demonstrates that existing Rust FFI calls need not be
replaced wholesale: the tested example resolved through an explicit host
import library.

It does not establish a stable Windows SDK or ABI, MSVC compatibility, Unicode
or long-path handling (the prototype uses `A` APIs), plugin hot reload, full
application-layer plugin support, capture SDK/plugin support, live IPS
correctness, broad regression coverage, performance, signed distribution, or
reproducible clean Windows installation. Exporting every linked symbol is a
research shortcut, not a reviewed minimal public ABI. Symbols discarded or not
pulled from archives may still be absent for different plugins. C and Rust
allocation/runtime compatibility, dependency DLL placement and matching
headers/toolchain remain explicit constraints.

Upstream production work should add a real Windows configure/build path,
reviewed exported API, installation/dependency rules, loader hardening and
positive/negative CI tests. Plugin failures should also be considered by any
operational health checks because upstream currently tolerates many load
failures without a nonzero exit.

## Public roadmap

Live status on 2026-10-25:

| Work | Status / target | Interpretation |
|---|---|---|
| [#4101: plugin umbrella][4101] | In Progress / TBD | Explicit objective: get plugins out of experimental state. |
| [#7499: first-class Rust plugins][7499] | New / TBD | Umbrella for missing Rust bindings and plugin helpers. Existing newer code is more advanced than the ticket's short description. |
| [#7500: Rust EVE filetype plugins][7500] | New / TBD | Not a Windows delivery commitment. |
| [#7501: Rust app-layer support][7501] | New / TBD | Existing app-layer example does not mean every first-class-support task is complete. |
| [#8094: package manager][8094] | Triaged / TBD | Proposal for source builds, enabling/disabling and eventual binary distribution; not an available package ecosystem. |
| [#4070: capture packet-completion notification][4070] | Triaged / TBD (local snapshot) | Relevant to external ownership / zero-copy capture integration. |
| [#7840: repair transaction logger docs][7840] | Assigned / 9.0.0-beta1 | Documentation correction, not waiting for implementation. |
| [PR #16454: opaque packet accessors][16454] | Open, not merged | Reduces dependence on packet internals; preparation for safer Rust wrappers, not a Windows loader. |
| [PR #16354: nDPI 4.12 / 5 / 6 compatibility][16354] | Open, not merged | Current plugin uses APIs removed in newer nDPI; do not assume latest nDPI works with our baseline. Proposed Linux CI expansion does not establish Windows support. |

Public GitHub searches covered `repo:OISF/suricata plugin windows`,
`repo:OISF/suricata dll plugin`, `repo:OISF/suricata dlfcn`, and open plugin PRs.
The Windows hits were historical/plugin-adjacent, not a current DLL-loader
implementation. The cached non-closed Redmine inventory was also inspected.
Search is necessarily incomplete, especially for unpublished discussions.

## Recommended evaluation sequence

Keep two questions separate: “Can I run my own packet-processing application
linked to libsuricata?” and “Can a stock Suricata EXE dynamically load my DLL?”
Solving the former does not automatically solve the latter.

For a Windows plugin proof of concept, start with a tiny C plugin that logs a
unique marker and then a simple EVE callback. Establish host exports and loader
behavior before attempting Rust or nDPI. After successful loading, exercise a
known PCAP and assert the callback's output; negative-test API mismatch and
missing dependencies. Only then attempt the Rust omnibus or application-layer
example. Do not start with capture SDKs or live interception: they introduce
unrelated drivers, privilege and hardware requirements.

The evaluation's initial native C and Rust callback proof is now completed, as
recorded above. Broader integration and production-hardening steps remain
future work; consult the parent library/Windows investigation alongside this
plugin-focused report.

[configure]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/configure.ac#L412-L435
[loader]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/util-plugin.c
[header]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/suricata-plugin.h
[header8]: https://github.com/OISF/suricata/blob/suricata-8.0.7/src/suricata-plugin.h
[engine]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/suricata.c
[ci]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/.github/workflows/builds.yml
[examples]: https://github.com/OISF/suricata/tree/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/plugins
[example-make]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/plugins/c-json-filetype/Makefile.in
[filetype]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/plugins/c-json-filetype/filetype.c
[custom-logger]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/plugins/c-custom-loggers/custom-logger.c
[rust-example]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/plugins/rust/src/mod.rs
[rust-plugin]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/ffi/src/plugin.rs
[rust-config]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/examples/plugins/rust/.cargo/config.toml
[sys]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/sys/src/sys.rs
[dev-doc]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/doc/userguide/devguide/libsuricata/index.rst
[flow-doc]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/doc/userguide/devguide/extending/flow-lifecycle-callbacks.rst
[ndpi-doc]: https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/doc/userguide/plugins/ndpi.rst
[pfring-doc]: https://docs.suricata.io/en/suricata-8.0.0/upgrade/8.0-pfring-plugin.html
[napatech-doc]: https://docs.suricata.io/en/suricata-8.0.0/upgrade/8.0-napatech-plugin.html
[4101]: https://redmine.openinfosecfoundation.org/issues/4101
[4070]: https://redmine.openinfosecfoundation.org/issues/4070
[7499]: https://redmine.openinfosecfoundation.org/issues/7499
[7500]: https://redmine.openinfosecfoundation.org/issues/7500
[7501]: https://redmine.openinfosecfoundation.org/issues/7501
[8094]: https://redmine.openinfosecfoundation.org/issues/8094
[7236]: https://redmine.openinfosecfoundation.org/issues/7236
[7840]: https://redmine.openinfosecfoundation.org/issues/7840
[16454]: https://github.com/OISF/suricata/pull/16454
[16354]: https://github.com/OISF/suricata/pull/16354
[4873]: https://github.com/OISF/suricata/pull/4873
[5343]: https://github.com/OISF/suricata/pull/5343
