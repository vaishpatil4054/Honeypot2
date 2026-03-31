@echo off
setlocal
cd /d "%~dp0"
echo Folder: %CD%

set "PY="
if exist ".venv\Scripts\python.exe" set "PY=.venv\Scripts\python.exe"
if not defined PY if exist "venv\Scripts\python.exe" set "PY=venv\Scripts\python.exe"
if not defined PY (
  echo ERROR: Could not find a virtualenv Python at .venv\Scripts\python.exe ^(or venv\Scripts\python.exe^).
  echo        Create/activate a venv and install requirements, then try again.
  pause
  exit /b 1
)

echo Starting honeypot + dashboard...
echo Opening: http://127.0.0.1:5000/login
echo.

"%PY%" start_project.py
echo.
echo Done (or it exited with an error above).
pause
