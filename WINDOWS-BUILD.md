# Windows build

For official support, bug reports, and Windows-related upstream discussions,
see [Upstream community and issue tracking](UPSTREAM-RESOURCES.md).

Built from https://github.com/OISF/suricata at commit
`e16087fab` (version `9.0.0-dev`) using MSYS2 UCRT64, GCC 15.1.0,
and Rust 1.87.0.

The runnable package is `windows-install/bin/`. Keep its DLLs beside
`suricata.exe`. It runs from PowerShell without MSYS2 on PATH:

```powershell
.\windows-install\bin\suricata.exe -V
.\windows-install\bin\suricata.exe --build-info
```

Both commands were verified with exit code 0 and PATH restricted to Windows
system directories. Version output:

```text
This is Suricata version 9.0.0-dev (e16087fab 2026-10-23)
```

Upstream does not implement `--version`: that command was tested and returned
`unknown option -- version` with exit code 1. Use `-V` instead.

## Rebuilding

See `doc/userguide/install/windows.rst` for MSYS2 dependencies. In an MSYS2
UCRT64 shell, from this repository:

```bash
git submodule update --init --recursive
pacman -S --needed mingw-w64-ucrt-x86_64-python-yaml mingw-w64-ucrt-x86_64-jq
bash scripts/build-windows.sh
bash scripts/verify-windows.sh
```

Build logs are `autogen-windows.log`, `configure-windows.log`, and
`build-windows.log`. The actual executable is `src/.libs/suricata.exe`;
the generated `src/suricata.exe` libtool launcher is replaced by a copy of the
actual executable because the MinGW launcher loses child exit codes. The
packaged executable is also a copy of the actual executable, with its recursive
non-system DLL dependencies copied from `C:/msys64/ucrt64/bin`.

The build script enables C unit tests, packages the executable and its DLLs,
and regenerates the compile database. Its optional first argument sets the
parallel build jobs (default: 8).

The verification script checks startup without MSYS2 on PATH, runs all built-in
C unit tests and the pinned OISF `suricata-verify` integration-test submodule,
and syntax-checks three C files using the compile database.
Any failing check exits nonzero; test logs are saved under `.build-tmp/`.
Integration-test results are in `.build-tmp/integration-tests.log`, with each
test's artifacts in its `suricata-verify/tests/.../output/` directory. Upstream
requirements determine skips for unavailable features or unsupported Windows
tests. The script requires `src/suricata.exe` to be identical to the packaged binary,
so the tests see Suricata's real exit status rather than a libtool launcher's.
Pass runner arguments to select tests, for example:
`bash scripts/verify-windows.sh --exact alert-distance-within-1 max-flowbits-per-signature`.
Without arguments the complete integration suite runs.

For a fresh clone, use `git clone --recurse-submodules` or initialize the
submodule as above. Updates are explicit: `git submodule update --remote
suricata-verify`, then review and commit the changed submodule pointer.

Use `bash scripts/verify-windows.sh --rust` to additionally run the upstream
Rust workspace test target (`make -C rust check`). At this commit that target
fails to link on Windows due to unresolved C FFI symbols; its failure is
reported, not suppressed. The default checks passed all 2,619 built-in C tests.

This build uses MSYS2 libpcap for offline PCAP processing. Npcap live capture
and WinDivert IPS support are not configured. Configuration files and rules
are not installed.

## Editor / LSP setup

The root `compile_commands.json` contains the configured Windows C compiler
commands. Zed discovers this database automatically. Project settings in
`.zed/settings.json` allow clangd to query the UCRT64 GCC driver for Windows
system headers and enable background indexing. Restart the C language server
in Zed after changing these settings.

Optional VS Code settings in `.vscode/settings.json` point C/C++ IntelliSense
at the same database and configure Rust Analyzer for the generated
`rust/Cargo.toml` workspace and GNU Windows target.

Regenerate the database after reconfiguring the build, from PowerShell:

```powershell
& C:\msys64\ucrt64\bin\python.exe scripts/compile-commands-windows.py
```

The generator reads Make's expanded dry-run commands; it does not rebuild.
The database and VS Code settings are ignored by upstream Git rules.
Upstream also provides `make compile-commands` in `Makefile.am`, but that
target requires a build configured with Clang and performs a C rebuild.
