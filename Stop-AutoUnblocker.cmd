@echo off
setlocal
cd /d "%~dp0"

set "BOOTSTRAP_NAME=MdExplorerPreview Auto-Unblocker Stop"
set "PS_SCRIPT=%~dp0scripts\Stop-MarkdownPreviewAutoUnblocker.ps1"

echo.
echo [%BOOTSTRAP_NAME%]

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERRO] Script de parada nao encontrado:
    echo        %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [ERRO] Nao foi possivel parar o auto-unblocker.
    echo.
    pause
    exit /b %RC%
)

echo.
echo [OK] Auto-unblocker parado.
echo.
pause
exit /b 0
