@echo off
setlocal
cd /d "%~dp0"

set "BOOTSTRAP_NAME=MdExplorerPreview Unblock Folder"
set "PS_SCRIPT=%~dp0scripts\Unblock-MarkdownFiles.ps1"
set "TARGET_PATH=%~1"

echo.
echo [%BOOTSTRAP_NAME%]

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERRO] Script de desbloqueio nao encontrado:
    echo        %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

if "%TARGET_PATH%"=="" (
    set /p TARGET_PATH=Digite o caminho da pasta que contem os arquivos Markdown: 
)

if "%TARGET_PATH%"=="" (
    echo.
    echo [ERRO] Nenhuma pasta informada.
    echo.
    pause
    exit /b 1
)

if not exist "%TARGET_PATH%" (
    echo.
    echo [ERRO] A pasta informada nao existe:
    echo        %TARGET_PATH%
    echo.
    pause
    exit /b 1
)

echo [INFO] Removendo Zone.Identifier de arquivos Markdown e assets locais em:
echo        %TARGET_PATH%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Path "%TARGET_PATH%" -Recurse
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [ERRO] O desbloqueio falhou.
    echo [INFO] Revise as mensagens acima e tente novamente.
    echo.
    pause
    exit /b %RC%
)

echo.
echo [OK] Desbloqueio concluido.
echo [INFO] Abra o Explorer nessa pasta e teste novamente o Preview Pane.
echo.
pause
exit /b 0
