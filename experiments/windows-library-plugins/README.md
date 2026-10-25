# Native Windows library and plugin experiments

Research only, 2026-10-25. Branch: `research/windows-library-and-plugins`.
Upstream engine: `e16087fab426e1edbc1a3ea8a75ce7e0ee76a4e4`.

This is not a production Windows port or a clean configure/install pipeline.
It reuses the matching configured headers, C archive, Rust archive and dependency
DLLs from the original Windows build, without modifying them. Outputs are under
this worktree's `.build-tmp/library-plugin-probes/`.

## Reproduce

First build the baseline using its normal Windows build script. From that
repository's PowerShell prompt, set the experiment and baseline paths explicitly:

```powershell
$experiment = 'C:\Users\Azrias\repos\suricata\.build-tmp\library-plugins\worktree\experiments\windows-library-plugins'
$baseline = '/c/Users/Azrias/repos/suricata'
& C:\msys64\usr\bin\bash.exe "$experiment/static-probes.sh" $baseline
& C:\msys64\usr\bin\bash.exe "$experiment/static-run.sh" $baseline
& C:\msys64\usr\bin\bash.exe "$experiment/plugin-probes.sh" $baseline
& C:\msys64\usr\bin\bash.exe "$experiment/plugin-run.sh" $baseline
& C:\msys64\usr\bin\bash.exe "$experiment/rust-plugin-probe.sh" $baseline
& C:\msys64\usr\bin\bash.exe "$experiment/rust-plugin-run.sh" $baseline
& C:\msys64\usr\bin\bash.exe "$experiment/negative-plugin-run.sh" $baseline
```

The Python verification adapter additionally needs `/ucrt64/bin` and `/usr/bin`
on PATH for the pinned runner's test tools. It imports that runner and changes
only its binary selection and added `--plugin` argument, not its assertions:

```powershell
$env:PATH = 'C:\msys64\ucrt64\bin;C:\msys64\usr\bin;' + $env:PATH
$env:PYTHONDONTWRITEBYTECODE = '1'
& C:\msys64\ucrt64\bin\python.exe "$experiment/run-verify.py" C:\Users\Azrias\repos\suricata
powershell -NoProfile -File "$experiment/clean-runtime.ps1" -Baseline C:\Users\Azrias\repos\suricata
```

`dll-probe.sh` is a separate, deliberately retained negative experiment. A naive
combined engine DLL link fails: `win32-service.o` references the application
`main`, producing an unresolved `WinMain` through MinGW startup code. No working
engine DLL was produced. A generated partial import library is not success.

## Observed results

- Stock simple/custom static C hosts compiled and each inspected 12 packets:
  two alerts and one HTTP event, with normalized alert tuples equal to baseline.
- The stock live example failed on Windows' COM `interface` macro. This branch
  renames that field to `interface_name`; it then compiles. No live capture ran.
- Stock `-rdynamic` probe fails; stock plugin support remains disabled upstream.
- The prototype recompiles only `suricata.c`, `runmodes.c` and `util-plugin.c`
  with `HAVE_PLUGINS`, using a copied archive. A native Win32 loader replaces
  POSIX loading, and PE export/import flags provide plugin-to-host calls.
- The unmodified C EVE plugin builds as a PE DLL and receives real records,
  both through explicit-file loading and `.dll` directory discovery.
- Stock Rust plugin linking fails on unresolved host functions. Explicitly
  linking the host import library builds the DLL; EVE, flow and thread callbacks
  execute, including raw and wrapped JSON enrichment.
- 2,619 C unit tests pass; ten selected Suricata-Verify cases pass (no case skips).
- Wrong API version is rejected before Init. Missing DLL / missing entry point
  are diagnosed, but upstream-style plugin load failures are non-fatal.
- A copied bundle works with only Windows system directories on PATH. This is
  not validation on a separately provisioned clean machine.

## Boundaries

The prototype bypasses configure. Generated feature/build-info strings still
describe the stock baseline; initialization logs and callback output establish
the experimental loader's behavior. Do not distribute this as a supported build.
Exporting every linked symbol is a research shortcut; another plugin may need
symbols that were discarded or never linked. Headers, API version, compiler and
runtime must match. This is GNU/UCRT64, not MSVC or Windows ARM64 validation.
The plugin import library names `suricata-plugin-host.exe`; changing the host
name or export arrangement requires relinking the plugins appropriately.

The loader uses ANSI Win32 paths and lacks a reviewed long-path/Unicode story.
No app-layer parser DLL, nDPI, capture plugin, hot reload, repeated engine init,
multiple engine instances, stress/performance or live IPS tests were performed.
Native plugins are trusted code inside the host process, not sandboxed scripts.

No Npcap/WinDivert driver was installed, no live traffic was captured or
intercepted, and no upstream report or PR was submitted.
