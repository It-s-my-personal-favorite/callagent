# Installiert Node.js (LTS laut nodejs.org index) als ZIP ohne Admin nach:
#   %LOCALAPPDATA%\Programs\nodejs-portable\node-v*-win-x64
# und traegt den Ordner in den BENUTZER-PATH ein.
# Danach: PowerShell/Cursor neu starten ODER run-dev.ps1 verwenden (PATH wird ergaenzt).

$ErrorActionPreference = "Stop"

$index = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -TimeoutSec 60
$lts = $index | Where-Object { $_.lts -is [string] } | Select-Object -First 1
if (-not $lts) { throw "Keine LTS-Version in index.json gefunden." }

$ver = $lts.version.TrimStart("v")
$tag = $lts.version
$zipName = "node-$tag-win-x64.zip"
$zipUrl = "https://nodejs.org/dist/$tag/$zipName"

$base = Join-Path $env:LOCALAPPDATA "Programs"
$extractRoot = Join-Path $base "nodejs-portable"
$zipPath = Join-Path $env:TEMP $zipName

Write-Host "LTS: $tag ($($lts.lts))" -ForegroundColor Cyan
Write-Host "Download: $zipUrl"

New-Item -ItemType Directory -Force -Path $base | Out-Null
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

if (Test-Path $extractRoot) {
    Get-ChildItem $extractRoot -Directory | Where-Object { $_.Name -like "node-*-win-x64" } | Remove-Item -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

$nodeHome = Get-ChildItem $extractRoot -Directory | Where-Object { $_.Name -like "node-*-win-x64" } | Select-Object -First 1 -ExpandProperty FullName
if (-not (Test-Path (Join-Path $nodeHome "node.exe"))) { throw "node.exe nicht gefunden unter $nodeHome" }

Write-Host "Installiert: $nodeHome" -ForegroundColor Green

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$nodeHome*") {
    [Environment]::SetEnvironmentVariable("Path", "$nodeHome;$userPath", "User")
    Write-Host "Benutzer-PATH aktualisiert. Bitte Terminal neu starten, damit 'node' ueberall erkannt wird." -ForegroundColor Yellow
}

$env:Path = "$nodeHome;$env:Path"
Write-Host ""
& (Join-Path $nodeHome "node.exe") -v
& (Join-Path $nodeHome "npm.cmd") -v
