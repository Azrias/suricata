#!/usr/bin/env bash
# This is an experimental manual link, NOT the upstream install-library target.
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the baseline source directory}" && pwd)
out="$tree/.build-tmp/library-plugin-probes"
mkdir -p "$out"
read -r -a libs <<< "$(make -s --no-print-directory -C "$base/src" -f Makefile -f "$exp/link-flags.mk" research-libs)"
read -r -a rust_libs <<< "$(make -s --no-print-directory -C "$base/src" -f Makefile -f "$exp/link-flags.mk" research-rust-libs)"
gcc -shared -o "$out/libsuricata-research.dll" \
    "-Wl,--out-implib,$(cygpath -m "$out/libsuricata-research.dll.a")" \
    -Wl,--whole-archive "$base/src/libsuricata_c.a" "$base/rust/target/release/libsuricata_rust.a" \
    -Wl,--no-whole-archive "${rust_libs[@]}" "${libs[@]}" > "$out/dll-build.log" 2>&1
gcc -std=c11 -DOS_WIN32 -DHAVE_CONFIG_H '-D__SCFILENAME__="dll-host"' \
    "-I$base/src" "-I$base/rust/gen" "-I$base/rust/dist" \
    "$tree/examples/lib/simple/main.c" "$out/libsuricata-research.dll.a" \
    -o "$out/simple-dll.exe" > "$out/dll-host-build.log" 2>&1
"$out/simple-dll.exe" -V > "$out/dll-version.log" 2>&1
echo "Experimental DLL host startup succeeded: $out/simple-dll.exe"
