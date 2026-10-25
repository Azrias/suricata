#!/usr/bin/env bash
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the baseline source directory}" && pwd)
bin="$tree/.build-tmp/library-plugin-probes"
out="$bin/plugin-runs/$(date -u +%Y%m%dT%H%M%S)"
mkdir -p "$out"
fixture="$base/suricata-verify/tests/alert-distance-within-1"
common=(-c "$exp/plugin-output.yaml" -S "$fixture/test.rules" -k none -r "$fixture/input.pcap" -l "$out"
    --set "classification-file=$(cygpath -m "$base/etc/classification.config")"
    --set "reference-config-file=$(cygpath -m "$base/etc/reference.config")"
    --set "threshold-file=$(cygpath -m "$base/threshold.config")")
timeout 45 "$bin/suricata-plugin-host.exe" "${common[@]}" --plugin "$bin/plugins/filetype.dll" > "$out/explicit-dll.log" 2>&1
grep -q 'Initializing plugin json-filetype-plugin' "$out/explicit-dll.log"
grep -q 'Received write with thread_data' "$out/explicit-dll.log"
alerts=$(grep -c 'Received write with thread_data.*"event_type":"alert"' "$out/explicit-dll.log")
http=$(grep -c 'Received write with thread_data.*"event_type":"http"' "$out/explicit-dll.log")
test "$alerts" -eq 2 && test "$http" -eq 1
echo "PASS: native DLL initialized and received $alerts alert records and $http HTTP record"
timeout 45 "$bin/suricata-plugin-host.exe" "${common[@]}" --plugin "$bin/plugins" > "$out/directory.log" 2>&1
grep -q 'Initializing plugin json-filetype-plugin' "$out/directory.log"
grep -q 'Received write with thread_data' "$out/directory.log"
echo 'PASS: .dll directory discovery also initialized the plugin and invoked callbacks'
echo "Logs: $out"
