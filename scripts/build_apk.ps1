param(
    [string]$ApiBaseUrl = "",
    [string]$DefinesFile = "dart_defines/production.json",
    [switch]$SkipAnalyze,
    [switch]$Obfuscate
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$flutter = $null
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutter = "flutter"
} elseif (Test-Path "$env:USERPROFILE\flutter_sdk\bin\flutter.bat") {
    $flutter = "$env:USERPROFILE\flutter_sdk\bin\flutter.bat"
} else {
    throw "Flutter not found. Install Flutter or add it to PATH."
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
  1. Copy dart_defines\production.json.example to dart_defines\production.json
     and set API_BASE_URL to your Render URL, then re-run this script.
  2. Pass -ApiBaseUrl 'https://YOUR-SERVICE.onrender.com'
"@
}

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

Write-Host "Building release APK with:"
$dartDefines | ForEach-Object { Write-Host "  --dart-define=$_" }

$buildArgs = @("build", "apk", "--release")
foreach ($define in $dartDefines) {
    $buildArgs += "--dart-define=$define"
}
if ($Obfuscate) {
    $symbolsDir = "build/app/outputs/symbols"
    New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null
    $buildArgs += "--obfuscate"
    $buildArgs += "--split-debug-info=$symbolsDir"
}

if (-not $SkipAnalyze) {
    Write-Host "Running flutter analyze (informational)..."
    & $flutter analyze
    # Do not fail the APK build on analyzer warnings/infos.
}

Write-Host "Running: $flutter $($buildArgs -join ' ')"
& $flutter @buildArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkPath = Join-Path $PWD "build/app/outputs/flutter-apk/app-release.apk"
$shareDir = Join-Path $PWD "dist"
New-Item -ItemType Directory -Force -Path $shareDir | Out-Null
$shareApk = Join-Path $shareDir "ShineGold-1.0.1.apk"
Copy-Item -Force $apkPath $shareApk

Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  $apkPath"
Write-Host "  $shareApk"
Write-Host ""
Write-Host "Share this file with testers (Drive, WhatsApp, etc.)."
Write-Host "API: check dart_defines/production.json"
