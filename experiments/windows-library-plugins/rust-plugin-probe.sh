#!/usr/bin/env bash
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the baseline source directory}" && pwd)
out="$tree/.build-tmp/library-plugin-probes"
mkdir -p "$out/rust-target" "$out/rust-target-stock"
# Reuse only generated workspace metadata; keep all build output in this worktree.
cp "$base/rust/Cargo.toml" "$tree/rust/Cargo.toml"
for member in derive suricatactl suricatasc sys ffi htp; do
    cp "$base/rust/$member/Cargo.toml" "$tree/rust/$member/Cargo.toml"
done
cp "$base/rust/sys/src/sys.rs" "$tree/rust/sys/src/sys.rs"
export CARGO_TARGET_DIR="$(cygpath -m "$out/rust-target-stock")"
export TMPDIR="$(cygpath -m "$out")" TEMP="$(cygpath -m "$out")" TMP="$(cygpath -m "$out")"
cd "$tree/examples/plugins/rust"
echo 'Trying the stock Rust plugin linker settings (offline)'
set +e
cargo build --offline --release > "$out/rust-plugin-stock-build.log" 2>&1
stock_status=$?
set -e
echo "Stock Rust plugin build exit: $stock_status"
echo 'Trying explicit linkage to the research host import library'
export CARGO_TARGET_DIR="$(cygpath -m "$out/rust-target")"
export RUSTFLAGS="-C link-arg=$(cygpath -m "$out/libsuricata_host.dll.a")"
cargo build --offline --release > "$out/rust-plugin-import-build.log" 2>&1
cp "$out/rust-target/release/suricata_rust_plugin.dll" "$out/plugins/rust-example.dll"
echo "Research Rust plugin built: $out/plugins/rust-example.dll"
