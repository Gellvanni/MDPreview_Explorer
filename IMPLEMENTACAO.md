# Implementacao e Manutencao

Este documento e para quem quer manter o projeto e entender as fronteiras entre runtime, conteudo e distribuicao.

## Estado atual

O preview handler ja chegou a um estado funcional inicial.

Nesta fase, o foco foi:

- bootstrap para usuario final;
- separacao entre motor e conteudo;
- matriz de validacao utilizavel;
- operacao repetivel.

O handler em si foi preservado.

Na fase visual atual, o foco passou a ser:

- aparencia unica, confortavel para leitura longa;
- aderencia ao tema de apps do Windows;
- separacao entre estrutura visual e paleta;
- validacao com arquivos reais do `mind-os`.

Na fase operacional atual, o foco passou a ser:

- experiencia de 1 clique em pastas confiaveis;
- remocao seletiva de `Zone.Identifier`;
- observacao automatica de `Downloads` e pasta customizada;
- logs e auditoria sem mexer no handler.

Na fase atual de empacotamento, o foco passou a ser:

- gerar MSI real para distribuicao;
- registrar e remover o preview handler sem depender dos scripts de dev;
- instalar o auto-unblocker em `Program Files`;
- iniciar o auto-unblocker por sessao via `HKLM\Run`;
- suportar upgrade major version preservando dados por usuario.

Na fase atual de publicacao, o foco passou a ser:

- deixar o repositorio limpo para GitHub;
- separar fonte de artefato gerado;
- distribuir o MSI por GitHub Releases;
- explicitar a licenca e a regra de redistribuicao.

## Arquitetura preservada

O runtime continua baseado em:

- `SharpShell` para COM/Preview Handler;
- `Markdig` para Markdown -> HTML;
- `WinForms WebBrowser` para a superficie de preview.

Trade-off:

- vantagem: sem depender de WebView2 nesta etapa;
- custo: renderer legado, a ser tratado numa fase futura.

Limites do renderer atual:

- nada de CSS variables modernas como base do sistema;
- nada de sintaxe avancada dependente de Chromium;
- tipografia limitada ao que o Windows e o motor IE oferecem;
- nao existe API simples do `WebBrowser` para herdar exatamente o brush interno do Explorer.

## Camadas do microproduto

### Runtime do handler

- [MarkdownPreviewHandler.cs](src/MdExplorerPreview/MarkdownPreviewHandler.cs)
- [MarkdownPreviewControl.cs](src/MdExplorerPreview/MarkdownPreviewControl.cs)
- [MarkdownPreviewDocumentBuilder.cs](src/MdExplorerPreview/MarkdownPreviewDocumentBuilder.cs)
- [PreviewThemeCatalog.cs](src/MdExplorerPreview/PreviewThemeCatalog.cs)
- [preview-base.css](src/MdExplorerPreview/Resources/preview-base.css)
- [preview-theme-dark.css](src/MdExplorerPreview/Resources/preview-theme-dark.css)
- [preview-theme-light.css](src/MdExplorerPreview/Resources/preview-theme-light.css)

Responsabilidade:

- receber o arquivo selecionado;
- converter Markdown;
- renderizar em modo read-only;
- cancelar navegacao externa.

Subcamadas:

- estrutura HTML/CSS base:
  layout, ritmo tipografico, espacamento, blocos e tabela;
- paleta adaptativa:
  cores, contraste e integracao com o modo de apps do Windows.

### Runtime do auto-unblocker

- [Program.cs](src/MdExplorerPreview.AutoUnblocker/Program.cs)
- [AutoUnblockerApplicationContext.cs](src/MdExplorerPreview.AutoUnblocker/AutoUnblockerApplicationContext.cs)
- [AutoUnblockerHost.cs](src/MdExplorerPreview.AutoUnblocker/AutoUnblockerHost.cs)
- [AutoUnblockerSettings.cs](src/MdExplorerPreview.AutoUnblocker/AutoUnblockerSettings.cs)
- [Infrastructure.cs](src/MdExplorerPreview.AutoUnblocker/Infrastructure.cs)
- [auto-unblocker.settings.json](config/auto-unblocker.settings.json)

Responsabilidade:

- rodar em background por sessao de usuario;
- observar pastas confiaveis;
- filtrar por extensao permitida;
- esperar o arquivo estabilizar;
- remover `Zone.Identifier` quando permitido;
- registrar log local para auditoria.

Importante:

- `.md` continua sendo responsabilidade do preview handler deste projeto;
- `.txt`, `.log`, `.json`, `.yaml`, `.yml`, `.ini`, `.csv` e `.xml` usam o preview que o sistema ja tiver;
- o auto-unblocker so resolve o bloqueio de origem.

Detalhes arquiteturais:

- `FileSystemWatcher` por pasta habilitada;
- `ConcurrentDictionary` para debounce por caminho;
- `Created`, `Changed` e `Renamed` para cobrir download, copia, extracao e movimentacao;
- retries com `settleDelay`, `retryDelay` e `maxWait`;
- remocao do ADS por chamada nativa do Windows, em vez de depender so de `File.Exists`.

### Registro Shell/COM

- [Register-MarkdownPreviewHandler.ps1](scripts/Register-MarkdownPreviewHandler.ps1)
- [Unregister-MarkdownPreviewHandler.ps1](scripts/Unregister-MarkdownPreviewHandler.ps1)

Responsabilidade:

- registrar/desregistrar a DLL;
- configurar `PreviewHandlers`, `ShellEx`, `AppID` e `FEATURE_BROWSER_EMULATION`;
- limpar `CLSID` e `ProgID` na remocao.

### Bootstrap e UX operacional

- [Install.cmd](Install.cmd)
- [Uninstall.cmd](Uninstall.cmd)
- [Start-AutoUnblocker.cmd](Start-AutoUnblocker.cmd)
- [Stop-AutoUnblocker.cmd](Stop-AutoUnblocker.cmd)
- [Open-AutoUnblockerSettings.cmd](Open-AutoUnblockerSettings.cmd)
- [Install-MarkdownPreview.ps1](scripts/Install-MarkdownPreview.ps1)
- [Uninstall-MarkdownPreview.ps1](scripts/Uninstall-MarkdownPreview.ps1)
- [Start-MarkdownPreviewAutoUnblocker.ps1](scripts/Start-MarkdownPreviewAutoUnblocker.ps1)
- [Stop-MarkdownPreviewAutoUnblocker.ps1](scripts/Stop-MarkdownPreviewAutoUnblocker.ps1)
- [Open-MarkdownPreviewAutoUnblockerSettings.ps1](scripts/Open-MarkdownPreviewAutoUnblockerSettings.ps1)
- [Test-MarkdownPreviewAutoUnblocker.ps1](scripts/Test-MarkdownPreviewAutoUnblocker.ps1)
- [Test-MarkdownPreviewRendering.ps1](scripts/Test-MarkdownPreviewRendering.ps1)
- [MarkdownPreview.Common.ps1](scripts/MarkdownPreview.Common.ps1)

Responsabilidade:

- elevar privilegios quando necessario;
- localizar ou compilar `Release x64`;
- desbloquear o pacote quando fizer sentido;
- reiniciar o Explorer;
- validar pos-instalacao e pos-remocao.
- instalar, iniciar e remover o auto-unblocker por sessao de usuario;
- abrir configuracao e expor caminhos de log/settings.

### Empacotamento MSI

- [InstallerVersion.props](installer/InstallerVersion.props)
- [MdExplorerPreview.Setup.wixproj](installer/MdExplorerPreview.Setup.wixproj)
- [Package.wxs](installer/Package.wxs)
- [InstallerActions.cs](installer/CustomActions/InstallerActions.cs)
- [Build-MarkdownPreviewMsi.ps1](scripts/Build-MarkdownPreviewMsi.ps1)
- [Test-MarkdownPreviewMsi.ps1](scripts/Test-MarkdownPreviewMsi.ps1)

Responsabilidade:

- construir um MSI `x64` `per-machine`;
- instalar handler e auto-unblocker em `Program Files\MdExplorerPreview`;
- registrar/desregistrar COM e Shell pelo proprio MSI;
- criar a entrada `HKLM\Run` do auto-unblocker;
- remover binarios e registro no uninstall;
- suportar major upgrade sem apagar `%LOCALAPPDATA%` do usuario.

Importante:

- o MSI nao empacota `content/`;
- fixtures e `mind-os-template` continuam sendo material de validacao, nao runtime do produto.

Responsabilidade visual:

- exportar HTML de revisao com a aparencia atual;
- validar com arquivos reais do `mind-os`.

### Conteudo e adocao

- [content/README.md](content/README.md)
- [mind-os-template](content/mind-os-template)
- [validation-suite](content/validation-suite)
- [New-MindOsWorkspace.ps1](scripts/New-MindOsWorkspace.ps1)
- [Prepare-ValidationWorkspace.ps1](scripts/Prepare-ValidationWorkspace.ps1)
- [Unblock-MarkdownFiles.ps1](scripts/Unblock-MarkdownFiles.ps1)

Responsabilidade:

- separar o pacote de conteudo do runtime;
- gerar workspaces locais;
- montar laboratorios de validacao;
- lidar com friccao de distribuicao de arquivo baixado.

## Fronteiras de responsabilidade

### Windows

- `Zone.Identifier`
- UAC
- politica de execucao do PowerShell
- infraestrutura COM
- ADS `Zone.Identifier`

### Explorer

- `prevhost.exe`
- cache do shell
- momento de carga do Preview Pane

### Conteudo

- `mind-os-template`
- arquivos baixados por `.zip`
- fixtures da validacao
- arquivos chegando em pastas confiaveis

### Handler

- renderer Markdown
- integracao COM/Shell
- comportamento read-only
- deteccao do modo visual do Windows e aplicacao do CSS embutido

### Auto-unblocker

- selecao de pastas confiaveis
- filtro por extensao segura
- tratamento de duplicidade e corrida do watcher
- estrategia conservadora para `.zip`

### Instalador MSI

- arquivos em `Program Files`
- custom actions de registro COM/Shell
- limpeza basica de artefatos legados do usuario atual
- entrada `HKLM\Run` para o auto-unblocker
- preservacao intencional de `settings.json` e log por usuario

## Trade-offs desta fase

### Por que adicionar `.cmd`

Porque o gargalo para adocao nao era mais o handler, e sim o custo de operacao para o usuario final. O `.cmd` serve como casca humana sobre o fluxo PowerShell.

### Por que escolher MSI per-machine com WiX 5

Porque esta fase nao pedia reinvencao do produto, e sim distribuicao profissional sobre o runtime atual.

Trade-off:

- vantagem: instalacao, upgrade e uninstall padrao Windows;
- vantagem: integra bem com `dotnet build`;
- custo: os dados por usuario continuam fora do MSI, por design.

Esse custo e correto, porque o preview handler e de maquina, mas a configuracao do auto-unblocker e de usuario.

### Por que o MSI preserva `settings.json`

Porque o arquivo vive em `%LOCALAPPDATA%` e representa decisao do usuario sobre:

- pastas confiaveis;
- whitelist efetiva;
- `dryRun`;
- log.

Apagar isso no uninstall quebraria a promessa de upgrade limpo e pisaria em configuracao pessoal.

### Por que mover conteudo para `content/`

Porque `mind-os-template` e fixtures de validacao nao pertencem ao motor do preview. Misturar tudo no antigo `samples/` escondia a fronteira entre produto e material consumido pelo produto.

### Por que criar uma matriz de validacao

Porque o preview precisava sair do modo "funciona no meu computador" e entrar no modo "casos conhecidos, passos repetiveis, causas separadas por dominio".

### Por que usar app de inicializacao em vez de Windows Service

Porque o problema e de experiencia do usuario em pastas pessoais, nao de infraestrutura global da maquina.

Trade-off:

- vantagem: menos privilegio, menos acoplamento com conta de servico, melhor aderencia a `%LOCALAPPDATA%` e `Downloads`;
- custo: o auto-unblocker depende da sessao do usuario estar ativa.

Para este produto, esse custo e aceitavel e a simplicidade e melhor.

### Como lidar com arquivos recem-chegados sem tocar em arquivo incompleto

O watcher nao desbloqueia imediatamente no primeiro evento.

Ele:

- agrupa eventos duplicados;
- espera um tempo de acomodacao;
- tenta abrir o arquivo com exclusividade;
- faz retry quando o arquivo ainda esta sendo escrito;
- so conclui que nao havia `Zone.Identifier` depois da janela de espera configurada.

Isso foi necessario porque o Windows e aplicativos terceiros podem publicar eventos antes do arquivo estar totalmente pronto.

### Por que o `.zip` fica opt-in

Desbloquear o `.zip` e poderoso demais para ser padrao.

Se um `.zip` trusted vier com executaveis, scripts ou macros, remover o `Zone.Identifier` do container pode fazer com que o conteudo extraido perca a marca da internet depois.

Por isso:

- padrao: observar o `.zip`, mas nao desbloquear;
- opt-in: permitir desbloqueio do `.zip` so quando o usuario realmente quiser esse fluxo.

### Por que separar `preview-base.css` da paleta

Porque a estabilidade do preview depende de um HTML simples e previsivel, mas o acabamento visual precisa evoluir sem refazer a camada de runtime. Separar estrutura de paleta permite mexer em contraste, tipografia e atmosfera sem reabrir COM, `Markdig` ou o ciclo do `WebBrowser`.

### Por que seguir o tema do Windows em vez de expor escolha manual

Porque o produto precisa ficar mais simples e mais coerente com o Explorer. O usuario nao precisa administrar tema dentro do preview; o preview acompanha o modo do sistema e reduz friccao operacional.

### Por que nao usar um sistema de tema mais moderno

Porque o renderer atual nao e Chromium. Como a base segue em `WebBrowser`, a camada visual precisa ficar dentro do subconjunto confiavel do IE11/`mshtml`.

## Validacao recomendada

1. execute [Install.cmd](Install.cmd)
2. valide o auto-unblocker com [Test-MarkdownPreviewAutoUnblocker.ps1](scripts/Test-MarkdownPreviewAutoUnblocker.ps1)
3. prepare um laboratorio com [Prepare-ValidationWorkspace.ps1](scripts/Prepare-ValidationWorkspace.ps1)
4. exporte HTMLs de revisao com [Test-MarkdownPreviewRendering.ps1](scripts/Test-MarkdownPreviewRendering.ps1)
5. valide os casos em [VALIDATION-MATRIX.md](docs/VALIDATION-MATRIX.md)
6. teste tambem um workspace gerado por [New-MindOsWorkspace.ps1](scripts/New-MindOsWorkspace.ps1)
7. execute [Uninstall.cmd](Uninstall.cmd) quando quiser validar remocao
