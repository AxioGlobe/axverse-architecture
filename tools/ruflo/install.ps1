$ErrorActionPreference = 'Stop'

$RufloVersion = '3.42.0'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

Write-Host ''
Write-Host 'AxioGlobe Ruflo Development Harness' -ForegroundColor Cyan
Write-Host '===================================' -ForegroundColor Cyan
Write-Host "Pinned Ruflo version: $RufloVersion"

function Get-NodeMajorVersion {
    try {
        $version = (& node --version 2>$null).Trim().TrimStart('v')
        if (-not $version) { return 0 }
        return [int]($version.Split('.')[0])
    } catch {
        return 0
    }
}

$nodeMajor = Get-NodeMajorVersion
if ($nodeMajor -lt 20) {
    Write-Host 'Node.js 20+ is required by Ruflo.' -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host 'Installing the current Node.js LTS release with winget...' -ForegroundColor Cyan
        winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
        Write-Host ''
        Write-Host 'Node.js was installed/updated. Close PowerShell, open a NEW PowerShell window, then run this installer again.' -ForegroundColor Yellow
        exit 0
    }

    Write-Host 'winget is unavailable. Install Node.js 20 or newer, then run this script again.' -ForegroundColor Red
    exit 1
}

Write-Host "Node.js detected: $(& node --version)" -ForegroundColor Green
Write-Host "npm detected: $(& npm --version)" -ForegroundColor Green

Set-Location $RepoRoot

Write-Host ''
Write-Host 'Initializing the full Ruflo agent harness...' -ForegroundColor Cyan
& npx --yes "ruflo@$RufloVersion" init --preset full --yes --skip-prompts --no-signup --no-codex-detect --force
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Ruflo initialization failed.' -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host 'Running Ruflo doctor and applying safe fixes...' -ForegroundColor Cyan
& npx --yes "ruflo@$RufloVersion" doctor --fix
$doctorExit = $LASTEXITCODE

Write-Host ''
Write-Host 'Discovering available Ruflo plugins...' -ForegroundColor Cyan
& npx --yes "ruflo@$RufloVersion" discover-plugins

Write-Host ''
Write-Host 'Ruflo development harness initialization is complete.' -ForegroundColor Green
Write-Host 'Project root:' $RepoRoot
Write-Host ''
Write-Host 'Useful commands:' -ForegroundColor Cyan
Write-Host "  npx ruflo@$RufloVersion doctor"
Write-Host "  npx ruflo@$RufloVersion agent list"
Write-Host "  npx ruflo@$RufloVersion swarm init --topology hierarchical"
Write-Host "  npx ruflo@$RufloVersion mcp list"
Write-Host "  npx ruflo@$RufloVersion discover-plugins"

if ($doctorExit -ne 0) {
    Write-Host ''
    Write-Host 'Ruflo was initialized, but doctor reported one or more environment/provider items that still need attention.' -ForegroundColor Yellow
    exit $doctorExit
}
