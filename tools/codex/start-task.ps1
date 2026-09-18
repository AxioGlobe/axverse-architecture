param(
    [Parameter(Mandatory=$true)][string]$Task,
    [int]$MaxAgents = 8
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$RunRoot = Join-Path $RepoRoot '.axioglobe-codex-runs'
$Router = Join-Path $RepoRoot 'tools\ruflo\route-task.mjs'

Set-Location $RepoRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is required.'
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js is required.'
}
if (-not (Test-Path $Router)) {
    throw 'AxioGlobe router was not found.'
}

New-Item -ItemType Directory -Force -Path $RunRoot | Out-Null

$runId = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ss-fffZ')
$runPath = Join-Path $RunRoot $runId
New-Item -ItemType Directory -Force -Path $runPath | Out-Null

$baselineCommit = (git rev-parse HEAD).Trim()
$branch = (git branch --show-current).Trim()
$statusBefore = (git status --porcelain=v1 | Out-String).Trim()

$routeJson = (& node $Router --task $Task --max-agents $MaxAgents --json | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw 'AxioGlobe task routing failed.'
}
$route = $routeJson | ConvertFrom-Json

$record = [ordered]@{
    schemaVersion = '1.0'
    runId = $runId
    task = $Task
    startedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    baselineCommit = $baselineCommit
    branch = $branch
    initialWorkingTreeDirty = -not [string]::IsNullOrWhiteSpace($statusBefore)
    initialStatus = $statusBefore
    route = $route
}

$record | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 (Join-Path $runPath 'start.json')
$route | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 (Join-Path $runPath 'route-plan.json')
Set-Content -Encoding UTF8 (Join-Path $RunRoot '.active') $runPath

Write-Host ''
Write-Host 'AxioGlobe Codex Run Started' -ForegroundColor Green
Write-Host '===========================' -ForegroundColor Green
Write-Host "Run: $runId"
Write-Host "Task: $Task"
Write-Host "Complexity: $($route.complexity)"
Write-Host "Base model guidance: $($route.baseModel)"
Write-Host "Reasoning guidance: $($route.reasoning)"
Write-Host "Selected specialists: $($route.squadSize) / 100"
Write-Host ''
foreach ($agent in $route.squad) {
    Write-Host ("- {0} [{1}] -> {2} / {3}" -f $agent.slug, $agent.rufloType, $agent.model, $agent.reasoning)
}
Write-Host ''
Write-Host "Run artifacts: $runPath" -ForegroundColor Cyan
Write-Host 'No OpenAI API calls were made by this script.' -ForegroundColor Yellow
