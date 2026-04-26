@echo off
REM Delegiert an apps\admin-web (gleiche package_config wie direkt dort).
cd /d "%~dp0apps\admin-web"
flutter %*
