@echo off
setlocal
cd /d "%~dp0"

set "NODEHOME="

REM Portabel: neueste node-v*-win-x64 (Name absteigend = i.d.R. hoechste Version)
for /f "delims=" %%D in ('dir /b /ad /o-n "%LOCALAPPDATA%\Programs\nodejs-portable\node-v*-win-x64" 2^>nul') do (
  set "NODEHOME=%LOCALAPPDATA%\Programs\nodejs-portable\%%D"
  goto :have_node
)

if exist "%ProgramFiles%\nodejs\npm.cmd" (
  set "NODEHOME=%ProgramFiles%\nodejs"
  goto :have_node
)

echo Node/npm nicht gefunden.
echo Fuehre install-node-portable.ps1 aus oder installiere Node.js LTS.
exit /b 1

:have_node
set "PATH=%NODEHOME%;%PATH%"
echo Verwende: %NODEHOME%
call "%NODEHOME%\npm.cmd" install
if errorlevel 1 exit /b 1
call "%NODEHOME%\npm.cmd" run dev
