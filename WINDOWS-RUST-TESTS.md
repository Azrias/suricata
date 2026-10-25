# Windows Rust test linking: upstream findings

Researched 2026-10-24 against Suricata developers' documentation, issue tracker,
and source. Local revision: `e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4`
(9.0.0-dev), MSYS2 UCRT64, Rust 1.87, GCC 15.1.

## What upstream confirms

Suricata's developer guide instructs developers to run `cargo test` from `rust/`
and supports filtering tests by module. Rust tests are an intended development
workflow; Windows is not inherently unable to run them.
[Official Rust unit-test guide](https://docs.suricata.io/en/latest/devguide/codebase/unittests-rust.html).

In [issue #6793, comment 1](https://redmine.openinfosecfoundation.org/issues/6793#note-1),
Jason Ish explains that Rust unit tests can reference Suricata C functions without
linking the C implementation. He says Linux, Windows, macOS and FreeBSD normally
tolerate those references when the tests never execute the corresponding paths.
In [comment 3](https://redmine.openinfosecfoundation.org/issues/6793#note-3), he
clarifies that `cargo test` builds no C and suggests investigating Rust/LLVM's
handling of unused references. That issue concerns Solaris, not this Windows
build; it establishes the mechanism, not an identical diagnosed regression.

There is a concrete historical upstream fix: Jason Ish's 2023 commit
[`68d0d6c`, "rust: fix unit test link error on Rust 1.70"](https://github.com/OISF/suricata/commit/68d0d6ca24780ac7c5d8b9d3d9d465371cafc179).
It replaced an `if cfg!(test)` approach with separate compile-time test and
application implementations, because references to C-only functions still
reached the linker. This is precedent for fixing the Rust test boundary, not a
patch to apply again to the current checkout.

The older [OISF Rust Notes wiki, "Allow cargo test To Work"](https://redmine.openinfosecfoundation.org/projects/suricata/wiki/Rust_Notes#Allow-cargo-test-To-Work)
also describes the C callback problem and suggests registering function pointers.
This page was available through the search index during this research; directly
opening it redirected to login. Treat it as historical context rather than a
current Windows installation recipe.

## What Windows CI actually tests

At this checkout's revision, OISF's Windows MSYS2 UCRT64/libpcap workflow builds
with unit tests enabled, runs `./src/suricata --build-info` and
`./src/suricata -u -l .`, and runs the separate `suricata-verify` integration
suite. It does not invoke `cargo test` or `make check` in that job. An Npcap job
also uses executable unit tests and `suricata-verify`, without Cargo tests.
[UCRT64 job](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/.github/workflows/builds.yml#L3666-L3722),
[Npcap job](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/.github/workflows/builds.yml#L3557-L3617).

The upstream `rust/Makefile.am` check target invokes
`cargo test --workspace`, adding `--release` for a non-debug configuration and
passing configured features. This is a separate test suite from the executable's
`-u` tests.
[Upstream Rust Makefile](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/rust/Makefile.am).

## Applying this evidence locally

The existing [Rust test log](.build-tmp/rust-tests.log) ends with undefined
references including `SCLogGetLogLevel`, `SCDetectSignatureAddTransform`, and
`SCAppLayerParserRegisterGetTxSubStateFuncs`, then fails to compile the
`suricata` library test. Those are Suricata engine APIs, rather than Npcap APIs.
This is a link-time failure before those tests execute.

The evidence supports investigating unused C references and Rust test stubs or
linker behavior. It does not yet establish which recent source change or toolchain
behavior causes this particular failure. No authoritative issue or published fix
specifically matching this revision, Windows toolchain, and symbol list was found.
It would be inaccurate to call this a confirmed upstream Windows bug or say that
Rust tests cannot run on Windows generally.

Installing Npcap does not provide these Suricata engine symbols. Nothing in the
sources above identifies Npcap as a prerequisite for the Cargo unit tests. OISF
also has a separate Windows libpcap CI configuration.
[Local failure log](.build-tmp/rust-tests.log),
[OISF Windows jobs](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/.github/workflows/builds.yml#L3619-L3722).

## Supported next steps versus possible fixes

For build verification, mirror the upstream Windows job: executable unit tests
plus the `suricata-verify` integration suite. Passing executable unit tests alone
does not verify the separate Cargo suite.
[OISF UCRT64 job](https://github.com/OISF/suricata/blob/e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4/.github/workflows/builds.yml#L3708-L3720).

To diagnose Cargo tests, compare plain debug `cargo test` with the configured
release workspace command, then isolate packages and inspect which C references
survive into the test executable. The debug command is documented upstream;
the comparison is a proposed diagnostic, not an upstream-proven fix.
[Developer guide](https://docs.suricata.io/en/latest/devguide/codebase/unittests-rust.html).

Possible implementation approaches include compile-time test stubs or correcting
test-specific compilation boundaries, following the historical upstream fix.
Linking the full C archive and its dependencies was reported as a Solaris
workaround in [issue #6793, comment 8](https://redmine.openinfosecfoundation.org/issues/6793#note-8),
but it is not an established Windows solution and should not be copied blindly.
No source, build script, or test configuration was changed during this research.
