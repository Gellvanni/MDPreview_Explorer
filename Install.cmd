@echo off
setlocal
cd /d "%~dp0"

set "BOOTSTRAP_NAME=MdExplorerPreview Install"
set "PS_SCRIPT=%~dp0scripts\Install-MarkdownPreview.ps1"
set "VALIDATION_FILE=%~dp0content\validation-suite\preview-fixture.md"

echo.
echo [%BOOTSTRAP_NAME%]

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERRO] Script de instalacao nao encontrado:
    echo        %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

if /i "%~1"=="__elevated" goto run
if defined MDEP_SKIP_UAC goto run

powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo [INFO] Privilegios administrativos sao necessarios.
    echo [INFO] Se o UAC aparecer, confirme a elevacao.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '__elevated' -Verb RunAs"
    if errorlevel 1 (
        echo [ERRO] Nao foi possivel solicitar elevacao.
        echo [INFO] Tente clicar com o botao direito em Install.cmd e escolha Executar como administrador.
        echo.
        pause
        exit /b 1
    )
    exit /b 0
)

:run
echo [INFO] Executando instalacao do preview handler...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [ERRO] A instalacao falhou.
    echo [INFO] Revise as mensagens acima e tente novamente.
    echo.
    pause
    exit /b %RC%
)

echo.
echo [OK] Instalacao concluida.
echo [INFO] Teste final sugerido:
echo        1. Abra o Explorer.
echo        2. Ative o Painel de visualizacao.
echo        3. Selecione:
echo           %VALIDATION_FILE%
echo.
echo [INFO] Auto-unblocker instalado:
echo        - configurações: %%LOCALAPPDATA%%\MdExplorerPreview\settings.json
echo        - log: %%USERPROFILE%%\AppData\LocalLow\MdExplorerPreview\auto-unblocker.log
echo        - edite com Open-AutoUnblockerSettings.cmd
echo.
echo [INFO] O visual do preview agora segue automaticamente o tema de apps do Windows.
echo.
pause
exit /b 0
