#!/usr/bin/env bash
# Build stock embedding examples against a previously configured Windows build.
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the existing configured Suricata source directory}" && pwd)
out="$tree/.build-tmp/library-plugin-probes"
mkdir -p "$out"
export TMPDIR="$(cygpath -m "$out")" TEMP="$(cygpath -m "$out")" TMP="$(cygpath -m "$out")"
read -r -a libs <<< "$(make -s --no-print-directory -C "$base/src" -f Makefile -f "$exp/link-flags.mk" research-libs)"
read -r -a rust_libs <<< "$(make -s --no-print-directory -C "$base/src" -f Makefile -f "$exp/link-flags.mk" research-rust-libs)"
cflags=(-std=c11 -DOS_WIN32 -DHAVE_CONFIG_H '-D__SCFILENAME__="embedding-probe"'
    "-I$base/src" "-I$base/rust/gen" "-I$base/rust/dist")
archives=(-Wl,--start-group "$base/src/libsuricata_c.a"
    "$base/rust/target/release/libsuricata_rust.a" -Wl,--end-group)
for example in simple custom live; do
    echo "Building stock library example: $example"
    gcc "${cflags[@]}" -o "$out/$example.exe" "$tree/examples/lib/$example/main.c" \
        "${archives[@]}" "${rust_libs[@]}" "${libs[@]}" > "$out/$example-build.log" 2>&1
done
echo 'Probing the stock plugin linker flag (failure is recorded, not hidden)'
set +e
gcc -rdynamic "$exp/rdynamic-probe.c" -o "$out/rdynamic-probe.exe" > "$out/rdynamic.log" 2>&1
rdynamic_status=$?
set -e
echo "rdynamic probe exit: $rdynamic_status"
test "$rdynamic_status" -ne 0
echo "Static example executables: $out"
