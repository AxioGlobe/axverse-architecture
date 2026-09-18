param(
    [string]$Model = 'gpt-5.6-sol'
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

function Ensure-Agent {
    param(
        [string]$Type,
        [string]$Name,
        [string]$ModelName
    )

    $listOutput = (& npx --yes "ruflo@$RufloVersion" agent list 2>&1 | Out-String)
    if ($listOutput -match [regex]::Escape($Name)) {
        Write-Host "Agent already present: $Name" -ForegroundColor Green
        return
    }

    Write-Host "Spawning agent: $Name ($Type)" -ForegroundColor Cyan
    & npx --yes "ruflo@$RufloVersion" agent spawn -t $Type --name $Name --model $ModelName
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to spawn agent '$Name'."
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

Write-Step 'Testing OpenAI connectivity'
# Ruflo 3.42.0 can hit a Windows/libuv UV_HANDLE_CLOSING assertion after
# successfully completing the provider test. Capture output and trust the
# explicit PASS marker instead of LASTEXITCODE alone.
$providerTestOutput = (& npx --yes "ruflo@$RufloVersion" providers test -p openai 2>&1 | Out-String)
Write-Host $providerTestOutput

$providerPassed = (
    $providerTestOutput -match 'PASS\s+OpenAI:\s+Connected successfully' -or
    $providerTestOutput -match '1/1\s+provider\(s\)\s+passed'
)

if (-not $providerPassed) {
    throw 'OpenAI provider connectivity test failed. Check the API key, project access, billing, or network connection.'
}

Write-Host 'OpenAI provider test passed.' -ForegroundColor Green

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

Write-Step 'Starting AxioGlobe core AI team'
Ensure-Agent -Type 'hierarchical-coordinator' -Name 'axioglobe-coordinator' -ModelName $Model
Ensure-Agent -Type 'architect' -Name 'axioglobe-architect' -ModelName $Model
Ensure-Agent -Type 'coder' -Name 'axioglobe-coder' -ModelName $Model
Ensure-Agent -Type 'tester' -Name 'axioglobe-tester' -ModelName $Model
Ensure-Agent -Type 'reviewer' -Name 'axioglobe-reviewer' -ModelName $Model

Write-Step 'Final verification'
& npx --yes "ruflo@$RufloVersion" providers list -a
& npx --yes "ruflo@$RufloVersion" daemon status
& npx --yes "ruflo@$RufloVersion" agent list
& npx --yes "ruflo@$RufloVersion" swarm status

Write-Host ''
Write-Host 'AxioGlobe Ruflo is configured to use OpenAI.' -ForegroundColor Green
Write-Host "Default model: $Model" -ForegroundColor Green
Write-Host 'The API key was not written to the Git repository.' -ForegroundColor Green
Write-Host ''
Write-Host 'Important: this connects Ruflo to the OpenAI API, not to this specific ChatGPT conversation.' -ForegroundColor Yellow

# Clear plaintext copy from this PowerShell variable. The user environment
# variable remains available for future Ruflo sessions.
$apiKey = $null
