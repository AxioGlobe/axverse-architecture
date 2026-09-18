param(
    [string]$RunPath,
    [string]$BuildCommand,
    [string]$TestCommand,
    [int]$TestsTotal = -1,
    [int]$TestsPassed = -1,
    [int]$TestsFailed = -1,
    [int]$AcceptanceTotal = -1,
    [int]$AcceptanceMet = -1,
    [int]$ReviewFindings = -1,
    [int]$ReviewResolved = -1
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$RunRoot = Join-Path $RepoRoot '.axioglobe-codex-runs'

Set-Location $RepoRoot

if ([string]::IsNullOrWhiteSpace($RunPath)) {
    $activeFile = Join-Path $RunRoot '.active'
    if (-not (Test-Path $activeFile)) {
        throw 'No active Codex run was found. Pass -RunPath or run start-task.ps1 first.'
    }
    $RunPath = (Get-Content $activeFile -Raw).Trim()
}

$startFile = Join-Path $RunPath 'start.json'
if (-not (Test-Path $startFile)) {
    throw "Run start record not found: $startFile"
}

$start = Get-Content $startFile -Raw | ConvertFrom-Json
$baseline = $start.baselineCommit

function Invoke-RecordedCommand {
    param(
        [string]$Name,
        [string]$Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $null
    }

    $started = Get-Date
    $output = (& powershell -NoProfile -Command $Command 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    $ended = Get-Date

    $output | Set-Content -Encoding UTF8 (Join-Path $RunPath "$Name.log")

    return [ordered]@{
        command = $Command
        exitCode = $exitCode
        success = ($exitCode -eq 0)
        durationSeconds = [math]::Round(($ended - $started).TotalSeconds, 3)
        log = "$Name.log"
    }
}

$build = Invoke-RecordedCommand -Name 'build' -Command $BuildCommand
$tests = Invoke-RecordedCommand -Name 'tests' -Command $TestCommand

$numstat = (git diff --numstat $baseline | Out-String).Trim()
$changedFiles = 0
$linesAdded = 0
$linesRemoved = 0

if (-not [string]::IsNullOrWhiteSpace($numstat)) {
    foreach ($line in ($numstat -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split "`t"
        if ($parts.Count -lt 3) { continue }

        $changedFiles++
        if ($parts[0] -match '^\d+$') { $linesAdded += [int]$parts[0] }
        if ($parts[1] -match '^\d+$') { $linesRemoved += [int]$parts[1] }
    }
}

$statusNow = (git status --porcelain=v1 | Out-String).Trim()
$untracked = @()
if (-not [string]::IsNullOrWhiteSpace($statusNow)) {
    $untracked = @($statusNow -split "`r?`n" | Where-Object { $_ -match '^\?\?' })
}

$endedAt = Get-Date
$startedAt = [DateTimeOffset]::Parse($start.startedAtUtc)
$elapsedSeconds = [math]::Round(($endedAt.ToUniversalTime() - $startedAt.UtcDateTime).TotalSeconds, 3)

$testPassRate = $null
if ($TestsTotal -ge 0 -and $TestsPassed -ge 0 -and $TestsTotal -gt 0) {
    $testPassRate = [math]::Round(($TestsPassed / $TestsTotal) * 100, 2)
}

$acceptanceRate = $null
if ($AcceptanceTotal -ge 0 -and $AcceptanceMet -ge 0 -and $AcceptanceTotal -gt 0) {
    $acceptanceRate = [math]::Round(($AcceptanceMet / $AcceptanceTotal) * 100, 2)
}

$reviewResolutionRate = $null
if ($ReviewFindings -ge 0 -and $ReviewResolved -ge 0 -and $ReviewFindings -gt 0) {
    $reviewResolutionRate = [math]::Round(($ReviewResolved / $ReviewFindings) * 100, 2)
}

$metrics = [ordered]@{
    schemaVersion = '1.0'
    runId = $start.runId
    task = $start.task
    startedAtUtc = $start.startedAtUtc
    finishedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    elapsedSeconds = $elapsedSeconds
    complexity = $start.route.complexity
    selectedSpecialists = $start.route.squadSize
    registryAgents = 100
    git = [ordered]@{
        baselineCommit = $baseline
        currentCommit = (git rev-parse HEAD).Trim()
        changedFiles = $changedFiles
        linesAdded = $linesAdded
        linesRemoved = $linesRemoved
        untrackedFiles = $untracked.Count
        workingTreeDirty = -not [string]::IsNullOrWhiteSpace($statusNow)
    }
    build = $build
    testCommand = $tests
    tests = [ordered]@{
        total = $(if ($TestsTotal -ge 0) { $TestsTotal } else { $null })
        passed = $(if ($TestsPassed -ge 0) { $TestsPassed } else { $null })
        failed = $(if ($TestsFailed -ge 0) { $TestsFailed } else { $null })
        passRatePercent = $testPassRate
    }
    acceptance = [ordered]@{
        total = $(if ($AcceptanceTotal -ge 0) { $AcceptanceTotal } else { $null })
        met = $(if ($AcceptanceMet -ge 0) { $AcceptanceMet } else { $null })
        ratePercent = $acceptanceRate
    }
    review = [ordered]@{
        findings = $(if ($ReviewFindings -ge 0) { $ReviewFindings } else { $null })
        resolved = $(if ($ReviewResolved -ge 0) { $ReviewResolved } else { $null })
        resolutionRatePercent = $reviewResolutionRate
    }
}

$metrics | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 (Join-Path $RunPath 'metrics.json')

$lines = @(
    '# AxioGlobe Codex Quantitative Report',
    '',
    "Task: $($start.task)",
    "Complexity: $($start.route.complexity)",
    "Specialists selected: $($start.route.squadSize) / 100",
    "Elapsed seconds: $elapsedSeconds",
    '',
    '## Git',
    "- Files changed: $changedFiles",
    "- Lines added: $linesAdded",
    "- Lines removed: $linesRemoved",
    "- Untracked files: $($untracked.Count)",
    '',
    '## Build',
    $(if ($null -eq $build) { '- Not recorded' } else { "- Success: $($build.success) (exit $($build.exitCode), $($build.durationSeconds)s)" }),
    '',
    '## Tests',
    $(if ($null -eq $tests) { '- Test command not recorded' } else { "- Command success: $($tests.success) (exit $($tests.exitCode), $($tests.durationSeconds)s)" }),
    $(if ($null -eq $testPassRate) { '- Pass rate: not supplied' } else { "- Pass rate: $testPassRate% ($TestsPassed/$TestsTotal)" }),
    '',
    '## Acceptance',
    $(if ($null -eq $acceptanceRate) { '- Not supplied' } else { "- Met: $AcceptanceMet/$AcceptanceTotal ($acceptanceRate%)" }),
    '',
    '## Review',
    $(if ($null -eq $reviewResolutionRate) { '- Not supplied' } else { "- Findings resolved: $ReviewResolved/$ReviewFindings ($reviewResolutionRate%)" })
)

$lines -join [Environment]::NewLine | Set-Content -Encoding UTF8 (Join-Path $RunPath 'REPORT.md')

Write-Host ''
Write-Host 'AxioGlobe Codex Run Finished' -ForegroundColor Green
Write-Host '============================' -ForegroundColor Green
Write-Host "Files changed: $changedFiles"
Write-Host "Lines added/removed: $linesAdded / $linesRemoved"
if ($null -ne $build) { Write-Host "Build success: $($build.success)" }
if ($null -ne $tests) { Write-Host "Test command success: $($tests.success)" }
if ($null -ne $testPassRate) { Write-Host "Test pass rate: $testPassRate%" }
Write-Host "Report: $(Join-Path $RunPath 'REPORT.md')" -ForegroundColor Cyan
Write-Host 'Only real repository/command metrics were recorded.' -ForegroundColor Yellow
