# MSI Packaging

Este documento fecha a fase de empacotamento do `md-explorer-preview` como produto instalavel no Windows.

## Estrategia adotada

O MSI foi implementado com:

- `WiX Toolset 5`
- projeto em [installer/MdExplorerPreview.Setup.wixproj](../installer/MdExplorerPreview.Setup.wixproj)
- custom actions em [installer/CustomActions/InstallerActions.cs](../installer/CustomActions/InstallerActions.cs)

Motivo da escolha:

- gera MSI real e padrao do ecossistema Windows;
- integra bem com `dotnet build`;
- permite upgrade major version sem reinventar o empacotamento;
- evita deixar a distribuicao dependente dos scripts de desenvolvimento.

## Escopo do MSI

O MSI instala:

- `MdExplorerPreview.dll`
- dependencias do preview handler
- `MdExplorerPreview.AutoUnblocker.exe`
- dependencias do auto-unblocker
- registro COM/Shell necessario para o Preview Pane
- entrada `HKLM\Software\Microsoft\Windows\CurrentVersion\Run` para iniciar o auto-unblocker na sessao do usuario

O MSI nao instala:

- `content/mind-os-template`
- `content/validation-suite`
- scripts de laboratorio ou fixtures

Motivo:

- esses arquivos pertencem a conteudo de teste e adocao, nao ao runtime do produto.

## Escopo de instalacao

O MSI e:

- `x64`
- `per-machine`

Motivo:

- o Preview Handler do Explorer depende de registro COM/Shell em escopo de maquina;
- tentar transformar isso num instalador puramente `per-user` deixaria o produto inconsistente.

## Configuracao e dados do usuario

O MSI preserva dados por usuario fora de `Program Files`.

Locais:

- settings: `%LOCALAPPDATA%\MdExplorerPreview\settings.json`
- logs: `%USERPROFILE%\AppData\LocalLow\MdExplorerPreview\auto-unblocker.log`

Comportamento:

- instalacao limpa: o auto-unblocker recria `settings.json` no primeiro boot se o arquivo nao existir
- upgrade: o MSI nao apaga configuracao existente
- uninstall: o MSI remove binarios e registro, mas preserva settings/log por design

Motivo:

- a configuracao e por usuario;
- um MSI `per-machine` nao deve sair limpando `%LOCALAPPDATA%` de todos os perfis da maquina.

## Migracao a partir da instalacao por script

Se a maquina ja usou:

- [Install.cmd](../Install.cmd)
- [scripts/Install-MarkdownPreview.ps1](../scripts/Install-MarkdownPreview.ps1)

o MSI agora faz migracao basica do usuario atual:

- encerra `MdExplorerPreview.AutoUnblocker.exe`
- remove o atalho antigo em `Startup`
- remove o deploy antigo do auto-unblocker em `%LOCALAPPDATA%\MdExplorerPreview\AutoUnblocker`

O que ele preserva:

- `settings.json`
- `auto-unblocker.log`

Isso evita duplicar launcher antigo com a entrada nova em `HKLM\Run`.

## Como gerar o MSI

Opcoes:

```powershell
.\scripts\Build-MarkdownPreviewMsi.ps1
```

ou:

```powershell
dotnet build .\installer\MdExplorerPreview.Setup.wixproj -c Release
```

Saida esperada:

- [installer/bin/x64/Release/MdExplorerPreview.Setup.msi](../installer/bin/x64/Release/MdExplorerPreview.Setup.msi)

Versao do MSI:

- controlada em [installer/InstallerVersion.props](../installer/InstallerVersion.props)

Para testar upgrade real:

1. aumente `MdExplorerPreviewInstallerVersion`
2. gere o MSI novo
3. instale o MSI novo por cima do antigo

## Como instalar

Opcao grafica:

1. clique duas vezes no MSI
2. aceite o UAC
3. conclua a instalacao

Opcao com log:

```powershell
msiexec /i ".\installer\bin\x64\Release\MdExplorerPreview.Setup.msi" /l*v "$env:TEMP\MdExplorerPreview-install.log"
```

Depois:

1. abra o Explorer
2. ative o Painel de visualizacao
3. teste [preview-fixture.md](../content/validation-suite/preview-fixture.md)

## Como atualizar

Upgrade recomendado:

1. aumente a versao em [installer/InstallerVersion.props](../installer/InstallerVersion.props)
2. gere o MSI novo
3. instale o MSI novo com:

```powershell
msiexec /i ".\installer\bin\x64\Release\MdExplorerPreview.Setup.msi" /l*v "$env:TEMP\MdExplorerPreview-upgrade.log"
```

O `MajorUpgrade` do WiX remove a versao anterior e coloca a nova.

O que deve permanecer:

- configuracao do usuario
- log do usuario

## Como desinstalar

Opcao grafica:

- `Apps e Recursos` do Windows

Opcao por linha de comando:

```powershell
msiexec /x ".\installer\bin\x64\Release\MdExplorerPreview.Setup.msi" /l*v "$env:TEMP\MdExplorerPreview-uninstall.log"
```

O uninstall remove:

- binarios em `Program Files\MdExplorerPreview`
- registro COM/Shell do preview handler
- entrada `HKLM\Run` do auto-unblocker

O uninstall preserva:

- `%LOCALAPPDATA%\MdExplorerPreview\settings.json`
- `%USERPROFILE%\AppData\LocalLow\MdExplorerPreview\auto-unblocker.log`

## Fluxo de validacao recomendado

Use o helper:

```powershell
.\scripts\Test-MarkdownPreviewMsi.ps1
```

Para executar mesmo:

```powershell
.\scripts\Test-MarkdownPreviewMsi.ps1 -Mode Install -Execute
.\scripts\Test-MarkdownPreviewMsi.ps1 -Mode Uninstall -Execute
```

Para upgrade real:

```powershell
.\scripts\Test-MarkdownPreviewMsi.ps1 -Mode Upgrade -PreviousMsiPath "C:\caminho\versao-antiga.msi" -Execute
```

O helper grava logs em:

- `artifacts\msi-validation`

Casos minimos:

1. instalacao limpa
2. preview de `preview-fixture.md`
3. auto-unblocker removendo `Zone.Identifier` de `.md` ou `.txt` em `Downloads`
4. upgrade para nova versao
5. uninstall
6. reinstalacao

## Troubleshooting

### O MSI instala, mas o preview nao aparece

Cheque:

- se o preview handler foi registrado
- se o Explorer foi reaberto
- se o arquivo ainda tem `Zone.Identifier`

### O auto-unblocker nao inicia no login

Cheque:

- `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
- existencia de `MdExplorerPreview.AutoUnblocker.exe` em `Program Files\MdExplorerPreview`
- `settings.json` em `%LOCALAPPDATA%\MdExplorerPreview`

### O upgrade preservou configuracao, mas nao adicionou novos defaults

Isso e deliberado por seguranca de configuracao:

- o MSI preserva a configuracao do usuario
- se o arquivo for apagado, ele sera recriado no proximo boot do auto-unblocker

### O primeiro MSI foi instalado sobre uma maquina que usava os scripts antigos

O instalador tenta limpar o launcher legado do usuario atual, mas nao faz limpeza agressiva em todos os perfis da maquina.

Se necessario, rode a remocao antiga antes da adocao do MSI:

- [Uninstall.cmd](../Uninstall.cmd)

## Trade-offs

### Por que WiX 5 e nao outro empacotador

- WiX 5 produz MSI real sem inventar um bootstrap proprietario nesta fase
- integra bem com o pipeline atual em `dotnet`

### Por que `HKLM\Run` e nao Windows Service

- o auto-unblocker e uma camada de UX por sessao do usuario
- ele trabalha em `Downloads`, `%LOCALAPPDATA%` e pastas pessoais
- um servico global seria mais pesado e traria mais atrito do que beneficio

### Por que o MSI nao carrega o conteudo de teste

- o instalador precisa empacotar runtime e distribuicao
- fixtures e `mind-os-template` pertencem a validacao e adocao, nao ao produto base
