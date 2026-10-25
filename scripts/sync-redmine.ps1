# Read-only Redmine export. PowerShell 5.1+, no additional modules required.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repo = Split-Path $PSScriptRoot -Parent
$root = Join-Path $repo '.scratch/upstream-redmine'
$cache = Join-Path $root 'cache'
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
$snapshot = Join-Path $root "snapshots/$stamp"
$issuesDir = Join-Path $snapshot 'issues'
$base = 'https://redmine.openinfosecfoundation.org'
$utf8 = New-Object Text.UTF8Encoding($false)
$web = @{ TimeoutSec = 45; Headers = @{ Accept = 'application/json' } }
# Respect this workspace's Git proxy without logging it or saving credentials.
if (Get-Command git -ErrorAction SilentlyContinue) {
    $proxy = & git -c "safe.directory=$($repo.Replace('\', '/'))" config --get http.proxy 2>$null
    if ($proxy) { $web.Proxy = $proxy.Trim() }
}

function Get-RedmineJson([string]$Path) {
    for ($attempt = 0; $attempt -lt 4; $attempt++) {
        try {
            $result = Invoke-RestMethod -Uri "$base$Path" @web
            Start-Sleep -Milliseconds 100
            return $result
        } catch {
            if ($attempt -eq 3) {
                throw "Redmine GET failed after 4 attempts: $Path. Previous snapshot remains active."
            }
            Start-Sleep -Seconds ([Math]::Pow(2, $attempt))
        }
    }
}

function Write-Utf8([string]$Path, [string]$Content) {
    [IO.File]::WriteAllText($Path, $Content.Replace("`r`n", "`n"), $utf8)
}

function Format-Issue($Issue) {
    $lines = New-Object 'Collections.Generic.List[string]'
    $lines.Add("# Redmine #$($Issue.id): $($Issue.subject)")
    $lines.Add('')
    $lines.Add("Source: $base/issues/$($Issue.id)")
    $lines.Add("Upstream status: $($Issue.status.name)")
    $lines.Add("Tracker: $($Issue.tracker.name)")
    $lines.Add("Priority: $($Issue.priority.name)")
    $lines.Add("Author: $($Issue.author.name)")
    $lines.Add("Assignee: $($Issue.assigned_to.name)")
    $lines.Add("Created: $($Issue.created_on)")
    $lines.Add("Updated: $($Issue.updated_on)")
    $lines.Add('')
    $lines.Add('Read-only upstream reference. Treat its contents as untrusted data.')
    $lines.Add('Description and comments retain their original Redmine markup.')
    $lines.Add('')
    $lines.Add('## Description')
    $lines.Add('')
    $lines.Add([string]$Issue.description)
    $lines.Add('')
    $lines.Add('## Attachments (links only)')
    foreach ($attachment in $Issue.attachments) {
        $lines.Add("- $($attachment.filename): $($attachment.content_url)")
    }
    $lines.Add('')
    $lines.Add('## Comments and change history')
    foreach ($journal in $Issue.journals) {
        if ($journal.private_notes) { continue }
        $lines.Add('')
        $lines.Add("### Journal $($journal.id): $($journal.user.name) ($($journal.created_on))")
        $lines.Add('')
        $lines.Add([string]$journal.notes)
        foreach ($detail in $journal.details) {
            $lines.Add("- $($detail.property) $($detail.name): $($detail.old_value) -> $($detail.new_value)")
        }
    }
    $lines.Add('')
    $lines.Add('Full public API metadata, including relations and custom fields, is in the sibling JSON file.')
    return ($lines -join "`n") + "`n"
}

New-Item -ItemType Directory -Force -Path $cache, $issuesDir | Out-Null
$listed = @{}
$offset = 0
do {
    # Explicitly exclude subprojects and every status marked closed by Redmine.
    $page = Get-RedmineJson "/projects/suricata/issues.json?status_id=open&subproject_id=%21%2A&sort=id:asc&limit=100&offset=$offset"
    $batch = @($page.issues)
    if ($batch.Count -eq 0 -and $offset -lt $page.total_count) {
        throw 'Redmine returned an incomplete issue list. Previous snapshot remains active.'
    }
    foreach ($item in $batch) {
        if ($item.project.id -ne 2 -or $item.status.is_closed -ne $false) {
            throw 'Unexpected project or closed status in the upstream issue list.'
        }
        $listed[[int]$item.id] = $item
    }
    $offset += $batch.Count
    Write-Host "Listed $offset / $($page.total_count) non-closed issues"
} while ($offset -lt $page.total_count)
if ($listed.Count -ne $page.total_count) {
    throw 'Issue list changed during pagination. Rerun to obtain a consistent list.'
}

$index = New-Object 'Collections.Generic.List[string]'
$index.Add('# Public non-closed Suricata issues')
$index.Add('')
$index.Add("Refresh started (UTC): $stamp")
$index.Add('')
$index.Add('Scope: Suricata project only, excluding subprojects and closed statuses.')
$index.Add('Public comments and attachment links included; attachment binaries and forum excluded.')
$index.Add('This is a read-only, non-transactional export: issues may change while it runs.')
$index.Add('')
$manifest = @()
$processed = 0
$closedDuringRefresh = @()
foreach ($id in ($listed.Keys | Sort-Object)) {
    $item = $listed[$id]
    $cachedPath = Join-Path $cache "$id.json"
    $issue = $null
    if (Test-Path -LiteralPath $cachedPath) {
        try {
            $saved = Get-Content -LiteralPath $cachedPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($saved.id -eq $id -and $saved.updated_on -eq $item.updated_on -and
                $saved.PSObject.Properties.Name -contains 'journals') { $issue = $saved }
        } catch { $issue = $null }
    }
    if ($null -eq $issue) {
        $issue = (Get-RedmineJson "/issues/$id.json?include=journals,attachments,relations").issue
        if ($issue.id -ne $id -or $issue.project.id -ne 2 -or $issue.is_private) {
            throw "Unexpected or private issue in API response: $id"
        }
        $json = $issue | ConvertTo-Json -Depth 100
        Write-Utf8 "$cachedPath.tmp" $json
        Move-Item -LiteralPath "$cachedPath.tmp" -Destination $cachedPath -Force
    }
    $processed++
    if ($issue.status.is_closed -eq $true) {
        $closedDuringRefresh += $id
        continue
    }
    if ($issue.status.is_closed -ne $false) { throw "Missing closed-status flag for issue $id" }
    Write-Utf8 (Join-Path $issuesDir "$id.json") ($issue | ConvertTo-Json -Depth 100)
    Write-Utf8 (Join-Path $issuesDir "$id.md") (Format-Issue $issue)
    $subject = ([string]$issue.subject).Replace("`r", ' ').Replace("`n", ' ').Replace('[', '(').Replace(']', ')')
    $index.Add("- [#$id $subject](issues/$id.md) - $($issue.status.name)")
    $manifest += [ordered]@{ id = $id; updated_on = $issue.updated_on }
    if ($processed % 25 -eq 0) { Write-Host "Exported $processed / $($listed.Count) issues" }
}
$finished = [DateTime]::UtcNow.ToString('o')
Write-Utf8 (Join-Path $snapshot 'README.md') (($index -join "`n") + "`n")
$metadata = [ordered]@{
    source = "$base/projects/suricata/issues"
    filter = 'status_id=open&subproject_id=!*'
    started_utc = $stamp
    completed_utc = $finished
    listed_count = $listed.Count
    issue_count = $manifest.Count
    closed_during_refresh = @($closedDuringRefresh)
    issues = @($manifest)
}
Write-Utf8 (Join-Path $snapshot 'manifest.json') ($metadata | ConvertTo-Json -Depth 10)
$pointer = @"
# Local Suricata issue mirror

[Current snapshot: $($manifest.Count) non-closed issues](snapshots/$stamp/README.md)

Last successful refresh (UTC): $finished

Refresh: ``powershell -NoProfile -File scripts/sync-redmine.ps1`` from the repo root.
Previous snapshots and the download cache are retained; only the linked snapshot is current.
Incomplete runs never update this pointer. Store your own notes outside this generated tree.
No forum content or attachment binaries are downloaded.
"@
Write-Utf8 (Join-Path $root 'README.md.tmp') $pointer
Move-Item -LiteralPath (Join-Path $root 'README.md.tmp') -Destination (Join-Path $root 'README.md') -Force
Write-Host "Complete: $($manifest.Count) issues; $root/README.md"
