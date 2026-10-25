#!/usr/bin/env bash
# Build first. Optional --rust adds Rust tests; other arguments go to the runner.
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p .build-tmp
export TMPDIR="$(cygpath -m "$PWD/.build-tmp")"
export TEMP="$TMPDIR" TMP="$TMPDIR"
trap 'echo "Verification failed; see .build-tmp/*-tests.log." >&2' ERR
rust_tests=false
if [[ "${1:-}" == --rust ]]; then rust_tests=true; shift; fi

exe="$PWD/windows-install/bin/suricata.exe"
[[ -f "$exe" ]] || { echo "Run scripts/build-windows.sh first." >&2; exit 1; }
[[ -f suricata-verify/run.py ]] || {
    echo "Run git submodule update --init --recursive first." >&2; exit 1;
}
python -c 'import yaml' || {
    echo "Install mingw-w64-ucrt-x86_64-python-yaml with pacman." >&2; exit 1;
}
command -v jq >/dev/null || {
    echo "Install mingw-w64-ucrt-x86_64-jq with pacman." >&2; exit 1;
}
# Confirm the packaged DLLs suffice without MSYS2 on PATH.
system_path="$(cygpath -u "$SYSTEMROOT")/System32:$(cygpath -u "$SYSTEMROOT")"
PATH="$system_path" "$exe" -V
PATH="$system_path" "$exe" --build-info > .build-tmp/build-info-tests.log 2>&1
"$exe" -u -l "$TMPDIR" > .build-tmp/unit-tests.log 2>&1
tail -n 5 .build-tmp/unit-tests.log
# The upstream runner discovers src/suricata.exe; require the real packaged binary.
cmp src/suricata.exe "$exe"
: "${SURICATASC:=$(cygpath -m "$PWD/rust/target/release/suricatasc.exe")}"
export SURICATASC
PYTHONDONTWRITEBYTECODE=1 python -u suricata-verify/run.py -q --debug-failed "$@" \
    2>&1 | tee .build-tmp/integration-tests.log
if "$rust_tests"; then
    make -C rust check > .build-tmp/rust-tests.log 2>&1
    tail -n 12 .build-tmp/rust-tests.log
fi
python scripts/compile-commands-windows.py --check
echo "Windows build verification passed."
