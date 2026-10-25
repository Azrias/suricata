#!/usr/bin/env bash
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
exp=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tree=$(cd "$exp/../.." && pwd)
base=$(cd "${1:?Pass the baseline source directory}" && pwd)
bin="$tree/.build-tmp/library-plugin-probes"
out="$bin/negative-runs/$(date -u +%Y%m%dT%H%M%S)"
mkdir -p "$out"
gcc -shared "-I$base/src" "$exp/bad-api-plugin.c" -o "$out/bad-api.dll"
gcc -shared "$exp/no-entry-plugin.c" -o "$out/no-entry.dll"
fixture="$base/suricata-verify/tests/alert-distance-within-1"
for test in bad-api no-entry missing; do
    mkdir -p "$out/$test"
    timeout 45 "$bin/suricata-plugin-host.exe" -c "$fixture/suricata.yaml" -S "$fixture/test.rules" \
        -k none -r "$fixture/input.pcap" -l "$out/$test" --plugin "$out/$test.dll" \
        --set "classification-file=$(cygpath -m "$base/etc/classification.config")" \
        --set "reference-config-file=$(cygpath -m "$base/etc/reference.config")" \
        --set "threshold-file=$(cygpath -m "$base/threshold.config")" > "$out/$test.log" 2>&1
done
grep -q 'Suricata and plugin versions differ' "$out/bad-api.log"
! grep -q 'BAD_API_PLUGIN_INITIALIZER_EXECUTED' "$out/bad-api.log"
grep -q 'Plugin does not export SCPluginRegister' "$out/no-entry.log"
grep -q 'Bad plugin path' "$out/missing.log"
echo 'PASS: wrong ABI rejected before Init; missing entry and missing DLL diagnosed'
echo 'NOTE: upstream loader behavior is non-fatal for these failures; all three engine runs exited 0'
echo "Logs: $out"
