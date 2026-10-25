# Offline tests; no Redmine requests and no external modules.
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'sync-redmine.ps1'
$errors = $null
$tokens = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
# Load only pure rendering/output functions, not the downloader's entry point.
foreach ($definition in $ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -in @('Format-Issue', 'Write-Utf8')
}, $false)) {
    Invoke-Expression $definition.Extent.Text
}
$base = 'https://redmine.openinfosecfoundation.org'
$utf8 = New-Object Text.UTF8Encoding($false)
$issue = [pscustomobject]@{
    id = 123
    subject = 'A sample issue'
    status = @{ name = 'New' }
    tracker = @{ name = 'Bug' }
    priority = @{ name = 'Normal' }
    author = @{ name = 'Reporter' }
    assigned_to = $null
    created_on = '2026-01-01T00:00:00Z'
    updated_on = '2026-01-02T00:00:00Z'
    description = "Description with Unicode $([char]0x03bb) and original <pre>markup</pre>"
    attachments = @(@{ filename = 'test.pcap'; content_url = "$base/attachments/download/5/test.pcap" })
    journals = @(
        @{ id = 1; user = @{ name = 'Developer' }; created_on = '2026-01-02'; notes = 'Public comment'; details = @(
            @{ property = 'attr'; name = 'status_id'; old_value = '1'; new_value = '2' }
        ) },
        @{ id = 2; private_notes = $true; user = @{ name = 'Other' }; notes = 'PRIVATE NOTE' }
    )
}
$rendered = Format-Issue $issue
$checks = @(
    @('issue identity', $rendered.Contains('# Redmine #123: A sample issue')),
    @('source link', $rendered.Contains("Source: $base/issues/123")),
    @('original description', $rendered.Contains($issue.description)),
    @('public comments', $rendered.Contains('Public comment')),
    @('change history', $rendered.Contains('attr status_id: 1 -> 2')),
    @('attachment link', $rendered.Contains($issue.attachments[0].content_url)),
    @('private notes excluded', -not $rendered.Contains('PRIVATE NOTE')),
    @('reference warning', $rendered.Contains('untrusted data'))
)
foreach ($check in $checks) {
    if (-not $check[1]) { throw "FAILED: $($check[0])" }
}
$tempFile = [IO.Path]::GetTempFileName()
try {
    Write-Utf8 $tempFile "test`r`n$([char]0x03bb)`r`n"
    $bytes = [IO.File]::ReadAllBytes($tempFile)
    if ($bytes[0] -eq 0xEF -or $bytes -contains 13) { throw 'Output must be UTF-8 without BOM and use LF.' }
    if ([IO.File]::ReadAllText($tempFile, $utf8) -ne "test`n$([char]0x03bb)`n") { throw 'UTF-8 roundtrip failed.' }
} finally {
    Remove-Item -LiteralPath $tempFile
}
Write-Host "PASS: syntax, $($checks.Count) rendering checks, UTF-8/LF output"
