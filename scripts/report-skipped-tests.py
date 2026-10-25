#!/usr/bin/env python3
"""Audit skip decisions using the pinned runner, without replaying PCAPs."""

from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
import copy
import importlib.util
import json
import os
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
SUITE = ROOT / "suricata-verify"
os.chdir(ROOT)
sys.path.insert(0, str(SUITE))
spec = importlib.util.spec_from_file_location("verify_runner", SUITE / "run.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
runner.suricata_bin = str(ROOT / "windows-install/bin/suricata.exe")
# Reproduce the original full run, before the helper's .exe path was supplied.
runner.HAS_SURICATA_SC = False
base = runner.SuricataConfig(runner.get_suricata_version())
base.valgrind = False
original_requires = runner.check_requires


def historical_requires(requires, config, directory=None):
    """Do not execute prerequisite shell scripts while preparing a report."""
    before_script = {}
    for key, value in requires.items():
        if key == "script":
            original_requires(before_script, config, directory)
            raise runner.UnsatisfiedRequirementError(
                "historical prerequisite script failure (reconstructed)"
            )
        before_script[key] = value
    original_requires(requires, config, directory)


runner.check_requires = historical_requires


def audit(directory):
    config = copy.copy(base)
    test = runner.TestRunner(
        str(ROOT), str(directory), str(directory / "output"), config, quiet=True,
    )
    name = directory.relative_to(SUITE / "tests").as_posix()
    try:
        test.check_requires()
        test.check_skip()
        test.check_unix_socket()
        if runner.WIN32 and "setup" in test.config:
            raise runner.UnsatisfiedRequirementError('test "setup" not supported on Windows')
        if runner.WIN32 and "command" in test.config:
            raise runner.UnsatisfiedRequirementError('"command" tests are not supported on Windows')
    except runner.UnsatisfiedRequirementError as error:
        return {"test": name, "status": "skipped", "stage": "prerequisite",
                "reasons": [str(error)], "skipped_checks": []}

    skipped = []
    executed = 0
    for index, check in enumerate(test.config.get("checks", []), 1):
        for kind, options in check.items():
            try:
                if kind in ("shell", "filter"):
                    requirements = options.get("requires", {})
                    if kind == "filter":
                        runner.check_filter_test_version_compat(requirements, test.version)
                    runner.check_requires(requirements, config, str(directory))
                if runner.WIN32 and kind in ("shell", "file-compare"):
                    raise runner.UnsatisfiedRequirementError(
                        f"{kind} check not supported on Windows"
                    )
            except runner.UnsatisfiedRequirementError as error:
                skipped.append({"check": index, "type": kind, "reason": str(error)})
            else:
                executed += 1
    # Upstream counts a test as skipped only if it has no successful checks.
    status = "skipped" if skipped and not executed else "passed"
    return {"test": name, "status": status, "stage": "checks",
            "reasons": sorted({item["reason"] for item in skipped}),
            "skipped_checks": skipped}


def group(reason):
    if reason == "requires feature DISABLED":
        return "Intentionally disabled unit-test wrappers: DISABLED feature marker"
    if reason.startswith("requires feature "):
        return "Missing build feature: " + reason.removeprefix("requires feature ")
    if reason.startswith("not for feature "):
        return "Feature-selection exclusions: JA3/JA4 are enabled"
    if "not supported on Windows" in reason:
        return "Windows limitation: " + reason
    if reason.startswith(("requires script returned false", "historical prerequisite")):
        return "Unix-style prerequisite scripts fail under Windows cmd.exe"
    if reason == "missing suricatasc":
        return "Unix-socket helper not discovered in the original run"
    if reason.startswith(("for version", "only for version", "requires at least version")):
        return "Version requirements"
    if reason.startswith("requires command "):
        return "Missing external command"
    if reason in ("linux", "darwin", "freebsd") or "sys.platform" in reason:
        return "Operating-system requirement"
    if reason == "skipped by default":
        return "Explicitly disabled upstream"
    return "Other declared requirement"


def test_link(name):
    return f"[{name}](suricata-verify/tests/{name}/test.yaml)"


def main():
    tests = []
    for directory, subdirectories, filenames in os.walk(SUITE / "tests"):
        if "test.yaml" in filenames:
            subdirectories[:] = []
            tests.append(Path(directory))
    output = ROOT / ".build-tmp/skipped-tests.json"
    if "--reuse-audit" in sys.argv:
        results = json.loads(output.read_text(encoding="utf-8"))
    else:
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(audit, sorted(tests)))
    # The original log has five path-error warnings and these five prerequisite
    # tests have no execution artifacts. Preserve that historical decision;
    # some probes now succeed, so a current rerun is not an original-run log.
    historical = []
    for item in results:
        directory = SUITE / "tests" / item["test"]
        config = runner.yaml.safe_load((directory / "test.yaml").read_bytes()) or {}
        if "script" in config.get("requires", {}):
            if (directory / "output/cmdline").exists():
                raise RuntimeError(f"Historical evidence changed for {item['test']}")
            historical.append(item["test"])
            item.update(status="skipped", stage="prerequisite",
                        reasons=["historical prerequisite script failure (reconstructed)"],
                        skipped_checks=[])
    skipped = [item for item in results if item["status"] == "skipped"]
    partial = [item for item in results
               if item["status"] == "passed" and item["skipped_checks"]]
    output.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8", newline="\n")
    raw_log = (ROOT / ".build-tmp/full-suite-run.log").read_bytes()
    original = raw_log.decode("utf-16" if raw_log.startswith(b"\xff\xfe") else "utf-8-sig")
    expected = int(re.findall(r"^SKIPPED:\s+(\d+)", original, re.MULTILINE)[-1])
    warnings = original.count("The system cannot find the path specified.")
    if len(historical) != 5 or warnings != 5:
        raise RuntimeError("Historical prerequisite evidence no longer matches the original run")
    if len(skipped) != expected:
        raise RuntimeError(f"Audit found {len(skipped)} skips; full run recorded {expected}")
    groups = defaultdict(list)
    for item in skipped:
        groups[group(item["reasons"][0])].append(item)
    lines = ["# Skipped-test report", "",
             "Windows UCRT64 build: Suricata `e16087fab`; suricata-verify `06ccb56d`.", "",
             f"Of {len(results):,} integration tests, **{len(skipped)} were skipped**, "
             f"{len(results) - len(skipped):,} passed, and none failed in the full run. "
             "All 2,619 C unit tests ran and passed. Rust workspace tests were blocked "
             "at linking; they are not included in the skipped-test count.", "",
             "## Groups", "", "| Primary skip reason | Tests |", "|---|---:|"]
    ordered = sorted(groups.items(), key=lambda item: (-len(item[1]), item[0]))
    lines += [f"| {name} | {len(items)} |" for name, items in ordered]
    lines += [f"| **Total** | **{len(skipped)}** |", "", "## Interpretation", "",
              "Each test is counted once, under the first prerequisite that stopped it, "
              "or its first skipped-check reason when all its checks were skipped. "
              "Other unmet requirements may exist behind that first reason.", "",
              "`DISABLED` intentionally excludes the `ut-complete` and `ut-leakcheck` "
              "wrappers; it is not an optional Suricata library to install. "
              "The regular C unit suite was already run separately. The JA3/JA4 'requires-off' "
              "cases are intentionally excluded because those features are enabled.", "",
              "A Windows shell-check skip can occur after Suricata processed the PCAP; "
              "it means the assertion did not run, not necessarily that the engine did not run. "
              "The runner reports the whole test as skipped when none of its checks succeed.", "",
              "The original run did not discover `suricatasc` because its default path "
              "omitted `.exe`. The verification script now supplies the correct path. "
              "This build still lacks UNIX_SOCKET support, so those cases remain ineligible.", "",
              "Unix-style prerequisite scripts use `/dev/null` and can fail under Windows "
              "cmd.exe. These prerequisite failures do not demonstrate a Suricata feature failure.", "",
              "**Historical reconstruction:** the original quiet log has five command-path "
              "warnings, and the five tests with prerequisite scripts have no execution "
              "artifacts. Those five are attributed to prerequisite failures by inference. "
              "A current audit reproduced 289 skips; three metadata prerequisite probes "
              "now succeed. Their original names/reasons were not individually logged, "
              "so this report does not present that attribution as directly recorded evidence.", "",
              "## Every skipped test", ""]
    for name, items in ordered:
        lines += [f"### {name} ({len(items)})", ""]
        reasons = {tuple(item["reasons"]) for item in items}
        for item in items:
            suffix = "; ".join(item["reasons"])
            if len(reasons) == 1 and len(item["reasons"]) == 1:
                suffix = ""
            lines.append(f"- {test_link(item['test'])}" + (f" — {suffix}" if suffix else ""))
        lines.append("")
    lines += ["## Passed tests with skipped assertions", "",
              f"Another **{len(partial)} passed tests** contain "
              f"**{sum(len(item['skipped_checks']) for item in partial)} skipped checks**. "
              "They are excluded from the 292 whole-test skips because other checks passed.", ""]
    for item in partial:
        detail = "; ".join(f"#{check['check']} {check['type']}: {check['reason']}"
                           for check in item["skipped_checks"])
        lines.append(f"- {test_link(item['test'])} — {detail}")
    lines += ["", "## Method and evidence", "",
              "The earlier quiet run retained aggregate totals, not individual skip reasons. "
              "This report reconstructs decisions using the pinned runner's requirement "
              "and skip functions, the same native executable and installed tools, "
              "and original helper-discovery behavior. It reads current test configurations "
              "and performs read-only config dumps; prerequisite shell probes are not executed. It does not "
              "replay PCAPs or modify test artifacts. Check eligibility is audited without "
              "rerunning assertions; pass/fail results come from the full-run summary.", "",
              f"The reconstructed whole-test total matches the recorded **{expected} skips**, "
              "with the historical inference above explicitly retained.", "",
              "- [Original full-run output](.build-tmp/full-suite-run.log)",
              "- [Machine-readable audit](.build-tmp/skipped-tests.json)",
              "- [Pinned runner](suricata-verify/run.py)",
              "- [Shared requirement and check implementations](suricata-verify/lib/common.py)", ""]
    report = ROOT / "SKIPPED-TESTS.md"
    report.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {report}: {len(skipped)} skipped tests, {len(partial)} partial tests")
    print(json.dumps({name: len(items) for name, items in ordered}, indent=2))


if __name__ == "__main__":
    main()
