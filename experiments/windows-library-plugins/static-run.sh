#!/usr/bin/env bash
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the baseline source directory}" && pwd)
bin="$tree/.build-tmp/library-plugin-probes"
out="$bin/runs/$(date -u +%Y%m%dT%H%M%S)"
mkdir -p "$out"
fixture="$base/suricata-verify/tests/alert-distance-within-1"
common=(-c "$fixture/suricata.yaml" -S "$fixture/test.rules" -k none
    --set "classification-file=$(cygpath -m "$base/etc/classification.config")"
    --set "reference-config-file=$(cygpath -m "$base/etc/reference.config")"
    --set "threshold-file=$(cygpath -m "$base/threshold.config")")
"$bin/simple.exe" -V > "$out/simple-version.log" 2>&1
mkdir -p "$out/simple-output" "$out/custom-output" "$out/baseline-output" "$out/plugin-disabled-output"
timeout 45 "$bin/simple.exe" "${common[@]}" -l "$out/simple-output" -r "$fixture/input.pcap" > "$out/simple-run.log" 2>&1
(cd "$out/custom-output" && timeout 45 "$bin/custom.exe" "${common[@]}" -- "$fixture/input.pcap") > "$out/custom-run.log" 2>&1
timeout 45 "$base/windows-install/bin/suricata.exe" "${common[@]}" -l "$out/baseline-output" -r "$fixture/input.pcap" > "$out/baseline-run.log" 2>&1
timeout 45 "$base/windows-install/bin/suricata.exe" "${common[@]}" -l "$out/plugin-disabled-output" --plugin "$out/does-not-exist.dll" -T > "$out/plugin-disabled.log" 2>&1
for name in baseline simple custom; do
    echo "$name: $(jq -s '[.[] | select(.event_type == "alert")] | length' "$out/$name-output/eve.json") alerts; $(jq -s '[.[] | select(.event_type == "http")] | length' "$out/$name-output/eve.json") HTTP events"
    jq -s -S '[.[] | select(.event_type == "alert") | {sid:.alert.signature_id,src_ip,dest_ip,src_port,dest_port,proto}] | sort_by(.sid,.src_ip,.dest_ip,.src_port,.dest_port)' "$out/$name-output/eve.json" > "$out/$name-alerts.json"
done
cmp "$out/baseline-alerts.json" "$out/simple-alerts.json"
cmp "$out/baseline-alerts.json" "$out/custom-alerts.json"
echo 'PASS: stock simple/custom embedding matches baseline alerts on this fixture'
echo 'NOTE: disabled plugin build accepted a nonexistent --plugin path; success alone is not proof of plugin loading'
echo "Logs: $out"
