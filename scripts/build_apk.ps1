param(
    [string]$ApiBaseUrl = "",
    [string]$DefinesFile = "dart_defines/production.json",
    [switch]$SkipAnalyze
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter not found on PATH. Install Flutter and add it to PATH."
}

$dartDefines = @()

if ($ApiBaseUrl) {
    $dartDefines += "API_BASE_URL=$ApiBaseUrl"
    $dartDefines += "PRODUCTION=true"
} elseif (Test-Path $DefinesFile) {
    Write-Host "Using dart defines from $DefinesFile"
    $json = Get-Content $DefinesFile -Raw | ConvertFrom-Json
    foreach ($prop in $json.PSObject.Properties) {
        $dartDefines += "$($prop.Name)=$($prop.Value)"
    }
} else {
    throw @"
Missing production API URL.

Either:
  1. Copy dart_defines/production.json.example to dart_defines/production.json
     and set API_BASE_URL to your Render URL, then re-run this script.
  2. Pass -ApiBaseUrl 'https://YOUR-SERVICE.onrender.com'
"@
}

if ($dartDefines -notcontains "API_BASE_URL=*") {
    $hasUrl = $false
    foreach ($define in $dartDefines) {
        if ($define -match '^API_BASE_URL=.+') {
            $hasUrl = $true
            break
        }
    }
    if (-not $hasUrl) {
        throw "API_BASE_URL is required for production APK builds."
    }
}

Write-Host "Building release APK with:"
$dartDefines | ForEach-Object { Write-Host "  --dart-define=$_ " }

$buildArgs = @("build", "apk", "--release")
foreach ($define in $dartDefines) {
    $buildArgs += "--dart-define=$define"
}

if (-not $SkipAnalyze) {
    Write-Host "Running flutter analyze..."
    flutter analyze
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

flutter @buildArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkPath = Join-Path $PWD "build/app/outputs/flutter-apk/app-release.apk"
Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  $apkPath"
Write-Host ""
Write-Host "Share this file with testers (Drive, WhatsApp, etc.)."
