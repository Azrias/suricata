"""Run selected upstream checks on the prototype, with the Rust DLL loaded.

The upstream runner and assertions are unchanged. Only binary selection and
the added --plugin argument are overridden; outputs stay in this worktree.
"""
import importlib.util
import os
from pathlib import Path
import sys
from datetime import datetime, timezone

base = Path(sys.argv[1]).resolve()
tree = Path(__file__).resolve().parents[2]
bin_dir = tree / '.build-tmp' / 'library-plugin-probes'
runner = base / 'suricata-verify' / 'run.py'
sys.path.insert(0, str(runner.parent))
host = bin_dir / 'suricata-plugin-host.exe'
plugin = bin_dir / 'plugins' / 'rust-example.dll'
out = bin_dir / 'verify-runs' / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S')
assert out.is_relative_to(tree)
assert host.is_file() and plugin.is_file()
spec = importlib.util.spec_from_file_location('suricata_verify_research', runner)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
module.suricata_bin = str(host)
module.suricata_yaml = str(base / 'suricata.yaml')
original_default_args = module.TestRunner.default_args


def default_args(self):
    result = original_default_args(self)
    # The pinned runner recursively clears individual test output directories.
    # Keep every resolved target inside this explicit, fresh research root.
    assert Path(self.output).resolve().is_relative_to(out.resolve())
    return [result[0], '--plugin', str(plugin), *result[1:]]


module.TestRunner.default_args = default_args
os.chdir(base)
os.environ['SURICATASC'] = str(base / 'rust/target/release/suricatasc.exe')
sys.argv = [str(runner), '-q', '--debug-failed', '--outdir', str(out), '--exact',
            'alert-distance-within-1', 'max-flowbits-per-signature',
            'dns-udp-nxdomain-soa', 'dns-udp-junkrequest-first',
            'http2-basic', 'http2-frames', 'smb2-01', 'smb2-02',
            'tls-alpn-client-log-01', 'tls-alpn-log-detect-02']
status = module.main()
if status == 0:
    # Ensure real successful PCAP tests actually initialized the DLL.
    initialized = []
    for log in out.rglob('stderr'):
        if 'Initializing rust example plugin' in log.read_text(encoding='utf-8', errors='replace'):
            initialized.append(log)
    for log in out.rglob('stdout'):
        if 'Initializing rust example plugin' in log.read_text(encoding='utf-8', errors='replace'):
            initialized.append(log)
    assert initialized, 'No plugin initialization found in verification logs'
    print(f'Plugin initialization confirmed in {len(initialized)} test logs')
print(f'Research verification outputs: {out}')
sys.exit(status)
