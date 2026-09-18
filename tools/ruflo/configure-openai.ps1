param(
    [string]$Model = 'gpt-5.6-terra'
)

$ErrorActionPreference = 'Stop'

$RufloVersion = '3.42.0'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Write-Step([string]$Message) {
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function ConvertFrom-Secure([Security.SecureString]$Secure) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

Set-Location $RepoRoot

Write-Host ''
Write-Host 'AxioGlobe Ruflo - OpenAI Provider Setup' -ForegroundColor Green
Write-Host '=======================================' -ForegroundColor Green
Write-Host "Ruflo version: $RufloVersion"
Write-Host "Default model: $Model"

Write-Step 'Collecting OpenAI API key securely'

$apiKey = $env:OPENAI_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    $apiKey = [Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'User')
}

if ([string]::IsNullOrWhiteSpace($apiKey) -or $apiKey.Length -lt 20) {
    Write-Host 'No usable OPENAI_API_KEY was found in the VM environment.' -ForegroundColor Yellow
    Write-Host 'Paste the OpenAI API key into the hidden prompt below.' -ForegroundColor Yellow
    Write-Host 'The key will not be printed and will not be written into Git.' -ForegroundColor Yellow

    $secureKey = Read-Host 'OpenAI API key' -AsSecureString
    $apiKey = ConvertFrom-Secure $secureKey

    if ([string]::IsNullOrWhiteSpace($apiKey) -or $apiKey.Length -lt 20) {
        throw 'The API key was empty or did not look valid.'
    }

    [Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $apiKey, 'User')
    $env:OPENAI_API_KEY = $apiKey
}
else {
    $env:OPENAI_API_KEY = $apiKey
    Write-Host 'Existing OPENAI_API_KEY found in the Windows user environment.' -ForegroundColor Green
}

Write-Host 'OPENAI_API_KEY stored in the Windows user environment.' -ForegroundColor Green

Write-Step 'Configuring Ruflo OpenAI provider'
# Configure only the model in Ruflo config. Do NOT pass -k because that would
# persist the secret in the project configuration.
& npx --yes "ruflo@$RufloVersion" providers configure -p openai -m $Model
if ($LASTEXITCODE -ne 0) {
    throw 'Ruflo OpenAI provider configuration failed.'
}

Write-Step 'Testing OpenAI connectivity directly'
# Ruflo 3.42.0 has a Windows/libuv UV_HANDLE_CLOSING crash in the provider
# test command. Validate the same credentials directly against OpenAI instead.
try {
    $headers = @{
        Authorization = "Bearer $env:OPENAI_API_KEY"
    }

    $modelCheck = Invoke-RestMethod -Method Get -Uri "https://api.openai.com/v1/models/$Model" -Headers $headers -TimeoutSec 20

    if (-not $modelCheck.id -or $modelCheck.id -ne $Model) {
        throw "OpenAI responded, but model '$Model' was not confirmed."
    }

    Write-Host "PASS OpenAI: Connected successfully" -ForegroundColor Green
    Write-Host "PASS Model access: $($modelCheck.id)" -ForegroundColor Green
}
catch {
    $detail = $_.Exception.Message
    throw "OpenAI API verification failed: $detail"
}
Write-Step 'Restarting Ruflo daemon with OpenAI environment'
& npx --yes "ruflo@$RufloVersion" daemon stop *> $null
Start-Sleep -Seconds 2

& npx --yes "ruflo@$RufloVersion" daemon start
if ($LASTEXITCODE -ne 0) {
    throw 'Ruflo daemon failed to start.'
}

Write-Step 'Ensuring hierarchical AxioGlobe swarm exists'
& npx --yes "ruflo@$RufloVersion" swarm status *> $null
if ($LASTEXITCODE -ne 0) {
    & npx --yes "ruflo@$RufloVersion" swarm init --topology hierarchical
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to initialize Ruflo swarm.'
    }
}
else {
    Write-Host 'Existing Ruflo swarm detected.' -ForegroundColor Green
}

Write-Step 'Validating AxioGlobe 100-agent registry'
$registryPath = Join-Path $RepoRoot 'tools\ruflo\agents\registry.json'
if (-not (Test-Path $registryPath)) {
    throw 'AxioGlobe agent registry was not found.'
}

$registry = Get-Content $registryPath -Raw | ConvertFrom-Json
if ($registry.totalAgents -ne 100 -or $registry.agents.Count -ne 100) {
    throw "Expected 100 registered AxioGlobe agents, found $($registry.agents.Count)."
}

Write-Host "PASS Agent registry: 100 specialist roles available." -ForegroundColor Green
Write-Host 'Agents are activated dynamically per task; they are not permanently pinned to one model.' -ForegroundColor Green

Write-Step 'Final verification'
& npx --yes "ruflo@$RufloVersion" providers list -a
& npx --yes "ruflo@$RufloVersion" daemon status
& npx --yes "ruflo@$RufloVersion" agent list
& npx --yes "ruflo@$RufloVersion" swarm status

Write-Host ''
Write-Host 'AxioGlobe Ruflo is configured to use OpenAI.' -ForegroundColor Green
Write-Host "Ruflo fallback model: $Model" -ForegroundColor Green
Write-Host 'Dynamic task routing: Luna -> Terra -> Sol' -ForegroundColor Green
Write-Host 'Use tools\ruflo\invoke-squad.ps1 to select task-specific squads.' -ForegroundColor Green
Write-Host 'The API key was not written to the Git repository.' -ForegroundColor Green
Write-Host ''
Write-Host 'Important: this connects Ruflo to the OpenAI API, not to this specific ChatGPT conversation.' -ForegroundColor Yellow

# Clear plaintext copy from this PowerShell variable. The user environment
# variable remains available for future Ruflo sessions.
$apiKey = $null
