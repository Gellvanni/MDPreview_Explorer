@echo off
setlocal
cd /d "%~dp0"

set "BOOTSTRAP_NAME=MdExplorerPreview Uninstall"
set "PS_SCRIPT=%~dp0scripts\Uninstall-MarkdownPreview.ps1"

echo.
echo [%BOOTSTRAP_NAME%]

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERRO] Script de remocao nao encontrado:
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
        echo [INFO] Tente clicar com o botao direito em Uninstall.cmd e escolha Executar como administrador.
        echo.
        pause
        exit /b 1
    )
    exit /b 0
)

:run
echo [INFO] Executando remocao do preview handler...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [ERRO] A remocao falhou.
    echo [INFO] Revise as mensagens acima e tente novamente.
    echo.
    pause
    exit /b %RC%
)

echo.
echo [OK] Remocao concluida.
echo [INFO] Se alguma janela do Explorer ainda mostrar preview antigo, feche e abra o Explorer novamente.
echo [INFO] O auto-unblocker tambem foi removido da inicializacao.
echo [INFO] Arquivos de configuracao e log podem permanecer em %%LOCALAPPDATA%%\MdExplorerPreview e %%USERPROFILE%%\AppData\LocalLow\MdExplorerPreview.
echo.
pause
exit /b 0
