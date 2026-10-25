#!/usr/bin/env python3
"""Generate a native Windows compile database from the configured GCC build."""

import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--msys2", type=Path, default=Path("C:/msys64"))
    parser.add_argument("--check", action="store_true", help="syntax-check representative C files")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    src = root / "src"
    compiler = args.msys2 / "ucrt64/bin/x86_64-w64-mingw32-gcc.exe"
    bash = args.msys2 / "usr/bin/bash.exe"
    if not compiler.is_file() or not (src / "Makefile").is_file():
        parser.error("MSYS2 UCRT64 GCC and an already configured build are required")

    env = os.environ.copy()
    env["PATH"] = os.pathsep.join(
        [str(args.msys2 / "ucrt64/bin"), str(args.msys2 / "usr/bin"), env["PATH"]]
    )
    # Avoid login-shell setup and Autotools regeneration. Force only C inputs;
    # -n prints the actual expanded compile recipes without rebuilding anything.
    command = ["make", "-n", "-C", "src", "-o", "Makefile", "-o", "autoconf.h"]
    for source in sorted(src.glob("*.c")):
        command.extend(["-W", source.name])
    result = subprocess.run(
        [str(bash), "-c", shlex.join(command)],
        cwd=root, env=env, text=True, capture_output=True, check=True,
    )
    entries = {}
    for line in result.stdout.splitlines():
        if not line.startswith("gcc "):
            continue
        tokens = shlex.split(line.split("&&", 1)[0].rstrip("\\"))
        if "-c" not in tokens:
            continue
        source = next((token for token in reversed(tokens) if token.endswith(".c")), None)
        if source is None:
            continue
        # Drop shell variables and dependency/output bookkeeping. Keep all
        # configured defines, warnings, language flags, and project includes.
        flags = []
        index = 1
        while index < len(tokens):
            token = tokens[index]
            if token in ("-MT", "-MQ", "-MF", "-o"):
                index += 2
                continue
            if token not in ("-MD", "-MMD", "-MP", "-c", source):
                flags.append(token)
            index += 1
        filename = (src / source).resolve()
        if not filename.is_file():
            raise RuntimeError(f"Missing source: {filename}")
        entries[str(filename)] = {
            "directory": src.as_posix(),
            "file": filename.as_posix(),
            "arguments": [compiler.as_posix(), *flags, "-c", filename.as_posix()],
        }
    if not entries:
        raise RuntimeError("No GCC compilation commands found")
    output = root / "compile_commands.json"
    output.write_text(json.dumps(list(entries.values()), indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(entries)} compilation commands to {output}")
    if args.check:
        for name in ("suricata.c", "decode-tcp.c", "app-layer-htp.c"):
            entry = entries[str((src / name).resolve())]
            arguments = [arg for arg in entry["arguments"] if arg != "-c"]
            subprocess.run(
                [*arguments, "-fsyntax-only"], cwd=src, env=env, check=True,
            )
            print(f"Syntax check passed: {name}")


if __name__ == "__main__":
    main()
