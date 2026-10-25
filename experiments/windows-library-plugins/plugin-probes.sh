#!/usr/bin/env bash
# Research prototype: bypasses configure; rebuilds the three HAVE_PLUGINS units.
# It does NOT make upstream Windows plugins supported or change the baseline.
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the baseline source directory}" && pwd)
out="$tree/.build-tmp/library-plugin-probes"
mkdir -p "$out/plugin-objects" "$out/plugins"
export TMPDIR="$(cygpath -m "$out")" TEMP="$(cygpath -m "$out")" TMP="$(cygpath -m "$out")"
read -r -a libs <<< "$(make -s --no-print-directory -C "$base/src" -f Makefile -f "$exp/link-flags.mk" research-libs)"
read -r -a rust_libs <<< "$(make -s --no-print-directory -C "$base/src" -f Makefile -f "$exp/link-flags.mk" research-rust-libs)"
cflags=(-std=c11 -g -O2 -DOS_WIN32 -DHAVE_CONFIG_H -DHAVE_PLUGINS
    '-D__SCFILENAME__="plugin-research"' "-I$base/src" "-I$base/rust/gen" "-I$base/rust/dist")
cp "$base/src/libsuricata_c.a" "$out/libsuricata_plugins.a"
for unit in suricata runmodes util-plugin; do
    echo "Recompiling plugin-enabled unit: $unit"
    gcc "${cflags[@]}" -c "$tree/src/$unit.c" -o "$out/plugin-objects/$unit.o" > "$out/plugin-$unit-build.log" 2>&1
    ar r "$out/libsuricata_plugins.a" "$out/plugin-objects/$unit.o"
done
echo 'Linking native Windows host with an explicit PE export/import library'
gcc "${cflags[@]}" "$tree/src/main.c" -o "$out/suricata-plugin-host.exe" \
    -Wl,--export-all-symbols "-Wl,--out-implib,$(cygpath -m "$out/libsuricata_host.dll.a")" \
    -Wl,--start-group "$out/libsuricata_plugins.a" "$base/rust/target/release/libsuricata_rust.a" \
    -Wl,--end-group "${rust_libs[@]}" "${libs[@]}" > "$out/plugin-host-build.log" 2>&1
echo 'Building the unmodified C EVE filetype plugin as a real PE DLL'
gcc "${cflags[@]}" -shared "$tree/examples/plugins/c-json-filetype/filetype.c" \
    "$out/libsuricata_host.dll.a" -lpthread -ljansson -o "$out/plugins/filetype.dll" > "$out/plugin-dll-build.log" 2>&1
echo "Prototype host and plugin built: $out"
