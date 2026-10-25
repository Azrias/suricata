#!/usr/bin/env bash
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the baseline source directory}" && pwd)
bin="$tree/.build-tmp/library-plugin-probes"
out="$bin/rust-runs/$(date -u +%Y%m%dT%H%M%S)"
mkdir -p "$out"
fixture="$base/suricata-verify/tests/alert-distance-within-1"
timeout 45 "$bin/suricata-plugin-host.exe" -c "$fixture/suricata.yaml" -S "$fixture/test.rules" \
    -k none -r "$fixture/input.pcap" -l "$out" --plugin "$bin/plugins/rust-example.dll" \
    --set "classification-file=$(cygpath -m "$base/etc/classification.config")" \
    --set "reference-config-file=$(cygpath -m "$base/etc/reference.config")" \
    --set "threshold-file=$(cygpath -m "$base/threshold.config")" > "$out/run.log" 2>&1
grep -q 'Initializing rust example plugin' "$out/run.log"
jq -e -s '[.[] | select(.event_type == "alert")] | length == 2' "$out/eve.json"
jq -e -s '[.[] | select(.event_type == "http")] | length == 1' "$out/eve.json"
jq -e -s 'all(.[]; .foobar.example == "eve-callback" and .rust_wrapped.example == "eve-callback")' "$out/eve.json"
grep -q 'rust example flow init callback' "$out/run.log"
grep -q 'rust example thread init callback' "$out/run.log"
echo "PASS: Rust DLL initialized; raw/wrapped EVE, flow and thread callbacks executed: $out"
