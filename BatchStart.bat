@echo off
chcp 65001 >nul
echo Running BatchStart.ps1...

set "SCRIPT_DIR=%~dp0"

where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo Using pwsh.exe
    pwsh.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%BatchStart\BatchStart.ps1"
) else (
    echo Using powershell.exe
    powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%BatchStart\BatchStart.ps1"
)

echo Done.
