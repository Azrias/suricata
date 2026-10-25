#!/usr/bin/env bash
# Run from MSYS2: bash scripts/build-windows.sh [parallel jobs]
set -euo pipefail
export PATH="/ucrt64/bin:/usr/bin:$PATH"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p .build-tmp rust/gen windows-install/bin
export TMPDIR="$(cygpath -m "$PWD/.build-tmp")"
export TEMP="$TMPDIR" TMP="$TMPDIR"
trap 'echo "Build failed; see *-windows.log in the repository root." >&2' ERR

./autogen.sh > autogen-windows.log 2>&1
./configure --prefix="$PWD/windows-install" --disable-gccmarch-native \
    --enable-unittests > configure-windows.log 2>&1
make -j"${1:-8}" > build-windows.log 2>&1
python scripts/compile-commands-windows.py

# Package the real executable (src/suricata.exe is a libtool launcher).
cp src/.libs/suricata.exe windows-install/bin/
declare -A seen=()
pending=(windows-install/bin/suricata.exe)
while ((${#pending[@]})); do
    binary="${pending[0]}"
    pending=("${pending[@]:1}")
    imports=$(objdump -p "$binary")
    while read -r dll; do
        [[ -n "$dll" && -z "${seen[$dll]:-}" ]] || continue
        seen[$dll]=1
        if [[ -f "/ucrt64/bin/$dll" ]]; then
            cp "/ucrt64/bin/$dll" windows-install/bin/
            pending+=("windows-install/bin/$dll")
        fi
    done < <(awk '/DLL Name:/ {gsub(/\r/, ""); print $3}' <<< "$imports")
done
# The MinGW libtool launcher loses child exit codes; expose the real binary.
cp windows-install/bin/suricata.exe src/suricata.exe
echo "Built windows-install/bin/suricata.exe (unit tests enabled)."
