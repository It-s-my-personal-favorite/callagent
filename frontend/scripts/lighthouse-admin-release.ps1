# Release-Web-Build der Admin-App und statischer HTTP-Server (für Lighthouse / „Produktionsnah“).
# Voraussetzung: Python 3 im PATH (python).
$ErrorActionPreference = "Stop"
$frontendRoot = Split-Path -Parent $PSScriptRoot
$adminWeb = Join-Path $frontendRoot "apps\admin-web"
if (-not (Test-Path $adminWeb)) {
    Write-Error "Erwartet: $adminWeb"
}
Set-Location $adminWeb
Write-Host "==> flutter build web (release, CSP, O4, source maps, lokale Web-Ressourcen) ..." -ForegroundColor Cyan
flutter build web --release `
    --optimization-level=4 `
    --tree-shake-icons `
    --no-web-resources-cdn `
    --source-maps `
    --csp
$strip = Join-Path $PSScriptRoot "strip_flutter_service_worker.py"
if (Test-Path $strip) {
    python $strip $adminWeb
}
$webOut = Join-Path $adminWeb "build\web"
if (-not (Test-Path $webOut)) {
    Write-Error "Build-Ausgabe fehlt: $webOut"
}
$port = 8787
Set-Location $webOut
Write-Host ""
Write-Host "==> Server: http://127.0.0.1:$port/  (Strg+C beenden)" -ForegroundColor Green
Write-Host "    In Chrome: Lighthouse auf diese URL laufen lassen (nicht den flutter-run-Dev-Port)." -ForegroundColor Yellow
python -m http.server $port
