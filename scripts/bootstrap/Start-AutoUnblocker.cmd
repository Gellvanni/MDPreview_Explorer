@echo off
setlocal
set "REPO_ROOT=%~dp0..\..\"
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

set "BOOTSTRAP_NAME=MdExplorerPreview Auto-Unblocker Start"
set "PS_SCRIPT=%REPO_ROOT%scripts\Start-MarkdownPreviewAutoUnblocker.ps1"

echo.
echo [%BOOTSTRAP_NAME%]

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERRO] Script de inicio nao encontrado:
    echo        %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Restart
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [ERRO] Nao foi possivel iniciar o auto-unblocker.
    echo.
    pause
    exit /b %RC%
)

echo.
echo [OK] Auto-unblocker iniciado.
echo.
pause
exit /b 0
