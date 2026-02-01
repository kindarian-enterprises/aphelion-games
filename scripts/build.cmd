@echo off
REM Thin wrapper: delegates to cross-platform build.py (reused by Makefile and build.sh).
set SCRIPT_DIR=%~dp0
python "%SCRIPT_DIR%build.py" %*
