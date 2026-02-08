@echo off
REM Build then serve on :8085 (Windows equivalent of make dev).
set SCRIPT_DIR=%~dp0
call "%SCRIPT_DIR%build.cmd"
if errorlevel 1 exit /b 1
echo Serving at http://localhost:8085
cd /d "%SCRIPT_DIR%..\dist"
python -m http.server 8085
