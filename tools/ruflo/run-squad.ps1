param(
    [Parameter(Mandatory=$true)][string]$Task,
    [int]$MaxAgents = 8,
    [int]$Concurrency = 3,
    [switch]$NoSynthesis
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Runner = Join-Path $PSScriptRoot 'run-squad.mjs'

Set-Location $RepoRoot

if (-not $env:OPENAI_API_KEY) {
    $env:OPENAI_API_KEY = [Environment]::GetEnvironmentVariable('OPENAI_API_KEY','User')
}
if (-not $env:OPENAI_API_KEY) {
    throw 'OPENAI_API_KEY is missing from the Windows user environment.'
}

$argsList = @($Runner, '--task', $Task, '--max-agents', "$MaxAgents", '--concurrency', "$Concurrency")
if ($NoSynthesis) { $argsList += '--no-synthesis' }

& node @argsList
if ($LASTEXITCODE -ne 0) {
    throw 'AxioGlobe squad execution failed.'
}
