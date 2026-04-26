@echo off
REM Flutter vom Repository-Root (pubspec.yaml + web/ am Root).
cd /d "%~dp0"
flutter %*
