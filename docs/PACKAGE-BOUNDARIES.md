# Package Boundaries

Este documento deixa explicito o que pertence ao microproduto de preview e o que pertence ao conteudo consumido por ele.

## Pacote A: handler do Explorer

Pertence ao pacote do handler:

- `src/`
- `installer/`
- `src/MdExplorerPreview.AutoUnblocker/`
- `src/MdExplorerPreview/Resources/preview-base.css`
- `src/MdExplorerPreview/Resources/preview-theme-dark.css`
- `src/MdExplorerPreview/Resources/preview-theme-light.css`
- `config/auto-unblocker.settings.json`
- `scripts/Build-MarkdownPreviewMsi.ps1`
- `scripts/Test-MarkdownPreviewMsi.ps1`
- `scripts/Install-MarkdownPreview.ps1`
- `scripts/Uninstall-MarkdownPreview.ps1`
- `scripts/Start-MarkdownPreviewAutoUnblocker.ps1`
- `scripts/Stop-MarkdownPreviewAutoUnblocker.ps1`
- `scripts/Open-MarkdownPreviewAutoUnblockerSettings.ps1`
- `scripts/Test-MarkdownPreviewAutoUnblocker.ps1`
- `scripts/Test-MarkdownPreviewRendering.ps1`
- `scripts/Register-MarkdownPreviewHandler.ps1`
- `scripts/Unregister-MarkdownPreviewHandler.ps1`
- `Install.cmd`
- `Uninstall.cmd`
- `Start-AutoUnblocker.cmd`
- `Stop-AutoUnblocker.cmd`
- `Open-AutoUnblockerSettings.cmd`

Responsabilidade:

- build da DLL;
- build do MSI;
- registro COM/Shell;
- registro e remocao pelo proprio instalador;
- restart do Explorer;
- validacao operacional basica.
- deteccao do modo de apps do Windows e aplicacao da paleta visual.
- monitoramento seletivo de pastas confiaveis;
- remocao automatica e conservadora de `Zone.Identifier`.

## Pacote B: conteudo Markdown

Pertence ao pacote de conteudo:

- `content/mind-os-template/`
- `content/validation-suite/`
- `scripts/New-MindOsWorkspace.ps1`
- `scripts/Prepare-ValidationWorkspace.ps1`
- `scripts/Unblock-MarkdownFiles.ps1`

Responsabilidade:

- fornecer Markdown para consumo;
- gerar workspaces locais;
- montar laboratorio de validacao;
- tratar a friccao de `Zone.Identifier`.

## Problemas por dominio

### Problema do Windows

- `Zone.Identifier`
- UAC
- politica de execucao do PowerShell
- infraestrutura COM

### Problema do Explorer

- host `prevhost.exe`
- cache do shell
- comportamento do Preview Pane

### Problema de distribuicao do conteudo

- `.zip` baixado da internet
- arquivos herdando marca de internet
- forma como o `mind-os` chega ao disco
- escolha entre desbloquear o container `.zip` ou esperar os arquivos extraidos

### Problema do handler

- renderizacao Markdown
- registro incompleto do CLSID/ShellEx/PreviewHandlers
- falhas no controle de preview
- inconsistencias de tipografia, tabela, contraste ou adaptacao visual

### Problema da camada auxiliar de UX

- watcher em background por sessao de usuario
- configuracao das pastas confiaveis
- log e auditoria do auto-unblocker
- debounce, retry e estabilidade de arquivo
