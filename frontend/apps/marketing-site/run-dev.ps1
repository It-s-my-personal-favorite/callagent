# CallAgent Marketing-Site (apps/marketing-site) lokal starten — npm muss verfügbar sein.
# Falls npm weiterhin fehlt: Node.js LTS installieren → https://nodejs.org/de → Terminal neu starten.

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
Set-Location $here

$candidates = @(
    "${env:ProgramFiles}\nodejs",
    "${env:ProgramFiles(x86)}\nodejs",
    "$env:LOCALAPPDATA\Programs\node",
    "$env:LOCALAPPDATA\fnm_multishells\1",
    "$env:USERPROFILE\.fnm\aliases\default"
)

foreach ($dir in $candidates) {
    if (Test-Path (Join-Path $dir "npm.cmd")) {
        if ($env:Path -notlike "*$dir*") {
            $env:Path = "$dir;$env:Path"
        }
        break
    }
}

$npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
if (-not $npm) {
    Write-Host ""
    Write-Host "npm wurde nicht gefunden." -ForegroundColor Red
    Write-Host ""
    Write-Host "So behebst du das:" -ForegroundColor Yellow
    Write-Host "  1) Node.js LTS installieren: https://nodejs.org/de/"
    Write-Host "  2) Installer-Option 'Add to PATH' aktiv lassen"
    Write-Host "  3) Cursor / PowerShell komplett schließen und neu öffnen"
    Write-Host "  4) Pruefen:  node -v   und   npm -v"
    Write-Host ""
    exit 1
}

Write-Host "Nutze: $($npm.Source)" -ForegroundColor DarkGray
& npm.cmd install
& npm.cmd run dev
