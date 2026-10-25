param([Parameter(Mandatory=$true)][string]$Baseline)
$ErrorActionPreference = 'Stop'
$tree = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$bin = Join-Path $tree '.build-tmp/library-plugin-probes'
$out = Join-Path $bin ('native-runtime/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
New-Item -ItemType Directory -Path $out -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $bin 'suricata-plugin-host.exe') -Destination $out
Copy-Item -LiteralPath (Join-Path $bin 'simple.exe') -Destination $out
Copy-Item -LiteralPath (Join-Path $bin 'custom.exe') -Destination $out
Copy-Item -LiteralPath (Join-Path $bin 'plugins/rust-example.dll') -Destination $out
Get-ChildItem -LiteralPath (Join-Path $Baseline 'windows-install/bin') -Filter '*.dll' |
    ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $out }
$fixture = Join-Path $Baseline 'suricata-verify/tests/alert-distance-within-1'
$arguments = @('-c', (Join-Path $fixture 'suricata.yaml'), '-S', (Join-Path $fixture 'test.rules'),
    '-r', (Join-Path $fixture 'input.pcap'), '-k', 'none', '-l', $out,
    '--plugin', (Join-Path $out 'rust-example.dll'),
    '--set', ('classification-file=' + (Join-Path $Baseline 'etc/classification.config')),
    '--set', ('reference-config-file=' + (Join-Path $Baseline 'etc/reference.config')),
    '--set', ('threshold-file=' + (Join-Path $Baseline 'threshold.config')))
$savedPath = $env:PATH
try {
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
    & (Join-Path $out 'simple.exe') -V *> (Join-Path $out 'static-version.log')
    if ($LASTEXITCODE -ne 0) { throw 'Static host failed with restricted PATH' }
    & (Join-Path $out 'suricata-plugin-host.exe') @arguments *> (Join-Path $out 'plugin-run.log')
    if ($LASTEXITCODE -ne 0) { throw 'Plugin host failed with restricted PATH' }
} finally {
    $env:PATH = $savedPath
}
$events = @(Get-Content (Join-Path $out 'eve.json') -Encoding UTF8 | ForEach-Object { $_ | ConvertFrom-Json })
if (@($events | Where-Object { $_.event_type -eq 'alert' }).Count -ne 2) { throw 'Alert count mismatch' }
if (@($events | Where-Object { $_.event_type -eq 'http' }).Count -ne 1) { throw 'HTTP count mismatch' }
if (@($events | Where-Object { $_.rust_wrapped.example -ne 'eve-callback' }).Count) { throw 'Rust callbacks missing' }
'PASS: static host startup and Rust plugin PCAP inspection with Windows-only PATH'
"Runtime package: $out"
