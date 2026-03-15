@echo off
setlocal
cd /d "%~dp0"

set "BOOTSTRAP_NAME=MdExplorerPreview Auto-Unblocker Settings"
set "PS_SCRIPT=%~dp0scripts\Open-MarkdownPreviewAutoUnblockerSettings.ps1"

echo.
echo [%BOOTSTRAP_NAME%]

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERRO] Script de configuracao nao encontrado:
    echo        %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [ERRO] Nao foi possivel abrir a configuracao.
    echo.
    pause
    exit /b %RC%
)

echo.
echo [OK] Configuracao aberta no Notepad.
echo [INFO] Salve o arquivo e reinicie o auto-unblocker com Start-AutoUnblocker.cmd para aplicar mudancas.
echo.
pause
exit /b 0
