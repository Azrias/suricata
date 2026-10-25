# Vectorscan research: Hyperscan history and the Windows UCRT64 opportunity

Research date: 2026-10-25. Scope: primary-source research and inspection of this
Suricata checkout, not a Vectorscan installation, build, or performance test.

## Bottom line

**Yes: native Windows MSYS2 UCRT64 support is now merged into Vectorscan.**
This is no longer just the September OISF announcement's forecast:
[PR #414](https://github.com/VectorCamp/vectorscan/pull/414) merged on
2026-10-08 as commit
[`c039c145649bd1f21d62b09974de506a5e5816c6`](https://github.com/VectorCamp/vectorscan/commit/c039c145649bd1f21d62b09974de506a5e5816c6).
That commit was `develop` HEAD when checked. It specifically targets the same
GCC/UCRT64 environment used by this project's Windows build.

**But it is an early, unreleased port with a known correctness-test discrepancy.**
The latest published release is
[5.4.13, August 23, 2026](https://github.com/VectorCamp/vectorscan/releases/tag/vectorscan/5.4.13),
before the Windows merge. Open
[issue #417](https://github.com/VectorCamp/vectorscan/issues/417), milestone
5.4.14, records two regex regression tests producing four fewer matches each
on UCRT64. Those tests are disabled on MinGW in the merged code. This deserves
investigation before production IDS deployment, not an assumption of either
complete correctness or a confirmed security vulnerability.

Your recollection is broadly right, with two important refinements:

- Vectorscan began as a portability/ARM-driven fork **in 2020**, before Intel's
  proprietary 5.5-and-later direction; it did not originate only after that
  change. It retains and develops x86 matching too.
- Intel did not retroactively close the BSD-licensed Hyperscan 5.4 code. That
  code remains available; the proprietary development line starts at 5.5.
  [Vectorscan's rationale](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md),
  [Intel 5.4.2 license](https://github.com/intel/hyperscan/blob/v5.4.2/LICENSE),
  [OISF history and collaboration announcement](https://suricata.io/2026/09/29/why-vectorscan-matters-to-suricata-and-why-were-supporting-it/).

## 1. What Vectorscan actually does

Vectorscan is a SIMD-accelerated, multi-pattern/multi-regex matching library
derived from Hyperscan. Its hybrid automata can match many expressions in one
scan, rather than executing each expression independently. It exposes the
familiar `hs_*` C API and supplies `libhs` (compiler plus runtime) and
`libhs_runtime` (runtime only). This makes it relevant to deep packet inspection
and Suricata's hot matching paths.
[Project overview](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md),
[library and serialization documentation](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/doc/dev-reference/serialization.rst).

It is **not a complete PCRE/PCRE2 replacement**, and installing it does not make
every Suricata `pcre` rule execute in Vectorscan. Suricata's integration is its
`hs` multi-pattern and single-pattern matcher backends; its separate PCRE2
matching remains in the detection engine.
[Suricata Hyperscan guide](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/doc/userguide/performance/hyperscan.rst),
[MPM backend](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/util-mpm-hs.c),
[SPM backend](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/util-spm-hs.c),
[PCRE implementation](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/src/detect-pcre.c).

## 2. History and licensing: the precise version

| Period | What the primary sources establish |
|---|---|
| Before Vectorscan | Original Hyperscan already had Windows work. Its changelog calls MSVC support experimental in 4.3.2 (2016), adds Windows tools in 5.0 (2018), and DLL support in 5.2 (2019). New UCRT64 support is not the first Windows code in this family. [Intel changelog](https://github.com/intel/hyperscan/blob/v5.4.2/CHANGELOG.md) |
| 2020 | Vectorscan starts as a portable fork. Its maintainers say ARM changes were originally offered upstream, but were not accepted for the foreseeable future. [Project rationale](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md), [OISF history](https://suricata.io/2026/09/29/why-vectorscan-matters-to-suricata-and-why-were-supporting-it/) |
| Hyperscan 5.4.x | Remains BSD licensed. Intel's public 5.4.2 release was published April 19, 2023. [License](https://github.com/intel/hyperscan/blob/v5.4.2/LICENSE), [release](https://github.com/intel/hyperscan/releases/tag/v5.4.2) |
| Hyperscan 5.5 onward | Intel's first-party paper states that newer releases are delivered under Intel Proprietary License (IPL) for interested customers. This does not revoke the old BSD release. [Intel paper, section 2.2](https://networkbuilders.intel.com/docs/networkbuilders/accelerate-snort-performance-with-hyperscan-and-intel-xeon-processors-on-public-clouds-1680176363.pdf); the passage is also [quoted by Vectorscan](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md#hyperscan-license-change-after-54). |
| Vectorscan now | Continues under a BSD license, with the Intel, VectorCamp, Arm and third-party notices retained. The maintainers explicitly commit to keeping it open source. [License](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/LICENSE), [statement](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md#license) |

Thus, "we used Hyperscan before the new line went proprietary" is a useful
description. "Hyperscan disappeared" or "all Hyperscan versions became closed"
would be inaccurate. The long-term attraction of Vectorscan is continued public
development and portability, not recovery of a revoked license.

## 3. ARM-focused origins, not an ARM-only engine

The project describes ARM NEON/ASIMD and Power VSX as fully functional and
continues SVE/SVE2 work. Its x86 code still includes SSE4.2, AVX2, AVX-512 and
AVX-512 VBMI implementations/build options. Release 5.4.13 includes x86
AVX-512 fixes as well as ARM and generic fixes. These are substantive x86
maintenance signals, not just inherited marketing text.
[README and build options](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md),
[x86 CMake configuration](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/cmake/cflags-x86.cmake),
[5.4.13 release notes](https://github.com/VectorCamp/vectorscan/releases/tag/vectorscan/5.4.13).

Since 5.4.12, a SIMDe backend can emulate SIMD or map it to another architecture.
That extends build portability; it is not evidence that scalar/emulated builds
will match native SIMD performance, or that every OS/architecture combination
is maintained and tested. The release notes explicitly distinguish supported
platforms from ports that merely might compile. In 5.4.13, macOS x86 and
FreeBSD were removed from CI unless backed by a support contract.
[5.4.12 notes](https://github.com/VectorCamp/vectorscan/releases/tag/vectorscan/5.4.12),
[5.4.13 support policy](https://github.com/VectorCamp/vectorscan/releases/tag/vectorscan/5.4.13).

## 4. Windows UCRT64: what is real, and what remains qualified

### Merged implementation, not only a roadmap item

OISF's September 29 announcement describes a summer pilot engagement with
VectorCamp and forecasts UCRT64 support by month end. The concrete merge
followed on October 8. Treat the announcement as intent/support and the merge
as evidence of implementation; the original forecast was not a release.
[OISF announcement](https://suricata.io/2026/09/29/why-vectorscan-matters-to-suricata-and-why-were-supporting-it/),
[merged PR #414](https://github.com/VectorCamp/vectorscan/pull/414).

The merge includes a documented UCRT64 dependency recipe, Windows OS detection,
page-size handling through `GetSystemInfo`, MinGW-specific build wrapping and
symbol/PE-section handling. These are actual platform changes, not just a
README promise.
[Merge diff](https://github.com/VectorCamp/vectorscan/commit/c039c145649bd1f21d62b09974de506a5e5816c6),
[Windows page-size helper](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/src/util/pagesize.h),
[MinGW wrapper](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/cmake/build_wrapper_mingw.sh).

UCRT64 means **x86-64 GCC + Microsoft's Universal C Runtime**, using MSYS2's
native Windows toolchain. It is distinct from legacy MINGW64/MSVCRT,
CLANG64, MSVC, and Windows ARM64. PR #414 explicitly defers MINGW64 and CLANG64
to separate PRs. A February 2026 maintainer response says Visual C++ support
will not be added without a support arrangement. Do not extrapolate this merge
to all Windows toolchains.
[MSYS2 environment definitions](https://www.msys2.org/docs/environments/),
[PR scope](https://github.com/VectorCamp/vectorscan/pull/414),
[MSVC response](https://github.com/VectorCamp/vectorscan/issues/334#issuecomment-3891089394).

### CI exists, but "all tests pass" would be misleading

Issue #417 links the real Buildbot builder `release-ucrt64-x86-gcc`.
Its referenced [build 27](https://buildbot-ci.vectorcamp.gr/#/builders/546/builds/27)
is complete and failed at `bin\unit-hyperscan.exe`, independently confirmed
through the [Buildbot build API](https://buildbot-ci.vectorcamp.gr/api/v2/builders/546/builds/27).
This is evidence of actual Windows test execution, not a successful complete
suite claim.

The reported discrepancies are:

| Test | Expected matches | Observed matches |
|---|---:|---:|
| `rebar.lh3lh3_reb_uri_or_email_grep` | 888,987 | 888,983 |
| `rebar.lh3lh3_reb_email_grep` | 232,354 | 232,350 |

The maintainer calls this non-fatal and says the other unit tests pass, but
the root cause is not established in the public issue. Both cases are
conditionally excluded on MinGW in the merged
[`unit/hyperscan/regressions.cpp`](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/unit/hyperscan/regressions.cpp).
Some `mmap`-dependent tests and PCAP examples are also excluded/guarded on
Windows. **A green reduced suite is not proof of complete Linux-equivalent
test coverage.**
[Issue #417](https://github.com/VectorCamp/vectorscan/issues/417),
[PR limitations](https://github.com/VectorCamp/vectorscan/pull/414),
[example guards](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/examples/CMakeLists.txt),
[guard-page test changes](https://github.com/VectorCamp/vectorscan/commit/c039c145649bd1f21d62b09974de506a5e5816c6).

Do not infer production missed alerts directly from these two counts: test
input handling, platform differences, or matching logic could be involved.
Conversely, matching correctness is central to an IDS, so this is a validation
gate rather than a discrepancy to silently disregard.

### Unreleased status and a documentation conflict

The latest release 5.4.13 predates the UCRT64 merge and has no uploaded binary
assets. A Windows experiment should therefore pin the post-release source
commit, not assume that `5.4.13` contains the port or that a Windows DLL is
provided. No matching UCRT64 package was found at the checked official MSYS2
package names `mingw-w64-ucrt-x86_64-vectorscan` and
`mingw-w64-ucrt-x86_64-hyperscan`; that is a point-in-time check, not a claim
about every possible package/distributor.
[Release metadata](https://api.github.com/repos/VectorCamp/vectorscan/releases/latest),
[Vectorscan package lookup](https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-vectorscan),
[Hyperscan package lookup](https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-hyperscan).

The README still describes `FAT_RUNTIME` as Linux-only. However, the October
merge adds a Windows-specific fat-runtime wrapper and `libucrtbase.a` symbol
handling, while OS detection no longer imposes a Linux-only gate. The source
is ahead of that README sentence. **Do not conclude Windows has no fat runtime
from the README, or claim every dispatch variant is proven locally.** Verify
the intended build configurations and CPU matrix in an actual experiment.
[README](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md),
[fat-runtime wrapper setup](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/cmake/build_wrapper.cmake),
[OS/build checks](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/cmake/osdetection.cmake).

## 5. Compatibility: easy integration does not mean unlimited interchangeability

Vectorscan's README targets Hyperscan 5.4 API/ABI compatibility and explicitly
does not chase proprietary 5.5/5.6 extensions. But its 5.4.12 release notes
call that release the **last 100% API/ABI-compatible release**, with later work
expected to be mostly backwards compatible. Since Windows support is later,
do not advertise its new build as an unqualified binary drop-in for every
application/library combination. Rebuild and validate against the exact
headers/library/toolchain.
[Compatibility policy](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/README.md#compatibility-with-hyperscan),
[5.4.12 compatibility caveat](https://github.com/VectorCamp/vectorscan/releases/tag/vectorscan/5.4.12).

Serialized compiled pattern databases are a separate compatibility boundary.
The documentation requires the same Vectorscan version and compatible platform
features when deserializing. Do not carry a Linux/ARM/Hyperscan compiled cache
into Windows/x86 or across upgrades and assume it works; regenerate caches
and keep source patterns/rules as the portable input.
[Serialization rules](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/doc/dev-reference/serialization.rst),
[database error definitions](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/src/hs_common.h).

## 6. Why this matters to this Windows Suricata project

Local read-only checks found `Hyperscan support: no` and `PCRE jit: yes` in
`windows-install/bin/suricata.exe --build-info`; `pkg-config --exists libhs`
also failed. Thus the current binary is **not already benefiting from
Vectorscan/Hyperscan**, even though it has PCRE JIT. These are local observations,
not statements about every upstream Windows package.

Suricata's configure logic already probes `libhs`, `hs.h`, `hs_compile`, and
`hs_valid_platform`; its backend retains the name `hs`. There is no distinct
`--enable-vectorscan` switch in this checkout. This offers a plausible existing
integration seam rather than requiring a new detection engine. It does not,
by itself, prove the newly ported library builds and links correctly here.
[Pinned configure logic](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/configure.ac#L655),
[existing integration guidance](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/doc/userguide/performance/hyperscan.rst).

The local host reports an AMD Ryzen 7 5800X (64-bit, 8 cores/16 logical
processors). The relevant target is therefore its x86 SIMD backend, not ARM.
Intel ancestry does not mean the engine requires an Intel-branded CPU: the
source selects instruction-set features. Actual `hs_valid_platform` execution
and performance on this host still require a library build.
[x86 feature/build checks](https://github.com/VectorCamp/vectorscan/blob/c039c145649bd1f21d62b09974de506a5e5816c6/cmake/cflags-x86.cmake).

The potential win is faster matching using native x86 SIMD in the toolchain
we already use, plus a maintained open-source dependency path. That can reduce
CPU demand or increase sustainable inspection throughput **when matching is
the bottleneck**. It does not accelerate capture, parsing, logging and all
other engine stages automatically, and no speedup factor is established for
our rules, PCAPs or machine. OISF specifically identifies multi-pattern matching
as an important hot path and plans to examine Suricata-specific optimizations.
[OISF performance rationale and future direction](https://suricata.io/2026/09/29/why-vectorscan-matters-to-suricata-and-why-were-supporting-it/).

## 7. Recommended evaluation, not changes already performed

1. Pin the Windows-capable commit above (or a later reviewed fix/release), build
   it separately with the same UCRT64 toolchain, and record compiler, build
   options, CPU ISA and dependency versions. Keep the current binary as baseline.
2. Run Vectorscan's own tests. Explicitly record/reproduce #417 and account for
   excluded `mmap` tests; do not count disabled tests as passed. Check both the
   intended fixed-ISA and fat-runtime configurations if both will be distributed.
3. Rebuild Suricata against the resulting `libhs`; check `--build-info` and
   effective matcher configuration, not merely successful linking. Exercise
   the existing `hs` C tests and all applicable suricata-verify cases.
4. Replay identical representative PCAPs and rules through baseline and new
   builds. Compare alert sets and relevant detection outputs, not timestamps or
   throughput alone. Include rule reload, cache rebuild and malformed/boundary
   input cases. Investigate differences before performance conclusions.
5. Measure cold start/rule compilation, warm replay throughput, CPU and peak
   memory under controlled settings. Report hardware, ruleset, packet mix and
   repeated-run variability. A library microbenchmark is not an end-to-end IDS
   performance guarantee.
6. Verify distribution on a clean Windows machine: executable/DLL dependency
   closure, runtime loading, CPU compatibility, BSD/third-party notices and
   startup/tests without the developer's MSYS2 PATH.

These are proposed acceptance gates based on the source limitations above,
not a claim that this work has already been done. No dependency, build script,
configuration, executable, or upstream code was changed for this research.

## Assessment

**Worth evaluating now; not yet justified as a production default.** The
October merge turns UCRT64 from a prospect into a concrete integration
opportunity, and this project's disabled `hs` backend gives the experiment a
clear purpose. The highest-value next step is a separate pinned build plus
correctness comparison, with #417 visible. The evidence supports enthusiasm
about the port, not a promise of a released, completely tested Windows package
or a measured performance win.
