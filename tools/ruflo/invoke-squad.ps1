param(
    [Parameter(Mandatory=$true)][string]$Task,
    [int]$MaxAgents = 8,
    [switch]$Spawn,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Router = Join-Path $PSScriptRoot 'route-task.mjs'

Set-Location $RepoRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js is required.'
}

$argsList = @($Router, '--task', $Task, '--max-agents', "$MaxAgents")
if ($Spawn) { $argsList += '--spawn' }
if ($Json) { $argsList += '--json' }

& node @argsList
if ($LASTEXITCODE -ne 0) {
    throw 'AxioGlobe task routing failed.'
}
