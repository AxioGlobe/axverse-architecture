$ErrorActionPreference = 'Stop'

$deployDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$composeFile = Join-Path $deployDir 'compose.yml'
$envFile = Join-Path $deployDir '.env'

function New-HexSecret([int]$bytes = 32) {
    $buffer = New-Object byte[] $bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($buffer)
    } finally {
        $rng.Dispose()
    }
    return ([System.BitConverter]::ToString($buffer)).Replace('-', '').ToLowerInvariant()
}

Write-Host ''
Write-Host 'AxioGlobe Prompt Registry' -ForegroundColor Cyan
Write-Host '=========================' -ForegroundColor Cyan

try {
    docker version | Out-Null
} catch {
    Write-Host 'Docker Desktop is not running or is not installed.' -ForegroundColor Red
    Write-Host 'Install/start Docker Desktop, then run this script again.'
    exit 1
}

if (-not (Test-Path $envFile)) {
    $postgresPassword = New-HexSecret 24
    $authSecret = New-HexSecret 32

    @"
PORT=4444
POSTGRES_PASSWORD=$postgresPassword
AUTH_SECRET=$authSecret
PCHAT_AUTH_PROVIDERS=credentials
PCHAT_ALLOW_REGISTRATION=true
PCHAT_FEATURE_AI_SEARCH=false
PCHAT_FEATURE_AI_GENERATION=false
OPENAI_API_KEY=
"@ | Set-Content -Path $envFile -Encoding UTF8

    Write-Host 'Created secure local .env configuration.' -ForegroundColor Green
}

Write-Host 'Pulling the Prompts.chat image...' -ForegroundColor Cyan
docker compose --env-file $envFile -f $composeFile pull

Write-Host 'Starting PostgreSQL and AxioGlobe Prompt Registry...' -ForegroundColor Cyan
docker compose --env-file $envFile -f $composeFile up -d

$url = 'http://localhost:4444'
$healthUrl = "$url/api/health"
$ready = $false

for ($i = 0; $i -lt 60; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
            $ready = $true
            break
        }
    } catch {
        Start-Sleep -Seconds 2
    }
}

if ($ready) {
    Write-Host ''
    Write-Host 'AxioGlobe Prompt Registry is running.' -ForegroundColor Green
    Write-Host "Open: $url" -ForegroundColor Green
    Start-Process $url
} else {
    Write-Host ''
    Write-Host 'Containers started, but the app health check is not ready yet.' -ForegroundColor Yellow
    Write-Host 'Run this command to inspect the application logs:'
    Write-Host "docker compose --env-file `"$envFile`" -f `"$composeFile`" logs -f app"
}
