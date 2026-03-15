# MdExplorerPreview

Microproduto para visualizar arquivos Markdown no Preview Pane do Windows Explorer sem trocar o aplicativo padrao associado ao `.md`.

## Publicacao no GitHub

O caminho recomendado para publicar este projeto e:

- repositorio publico no GitHub;
- licenca MIT;
- codigo-fonte no repositorio;
- MSI distribuido por GitHub Releases.

Resumo importante:

- repositorio publico sem `LICENSE` nao e open source de verdade;
- com `LICENSE`, o projeto fica juridicamente redistribuivel;
- neste projeto, a recomendacao atual e MIT para reduzir friccao de adocao.

Guia curto em [GITHUB-PUBLISHING.md](docs/GITHUB-PUBLISHING.md).

## Para quem so quer instalar e usar

### Distribuicao recomendada

Para usuario final, a distribuicao recomendada agora e o MSI.

Fluxo:

1. gere o pacote com [Build-MarkdownPreviewMsi.ps1](scripts/Build-MarkdownPreviewMsi.ps1)
2. publique o MSI em GitHub Releases
3. compartilhe a Release com quem for instalar
4. valide o preview e o auto-unblocker

Mais detalhe em [MSI-PACKAGING.md](docs/MSI-PACKAGING.md) e [GITHUB-PUBLISHING.md](docs/GITHUB-PUBLISHING.md).

### Entrada recomendada

Use os arquivos de bootstrap na raiz do projeto:

- [Install.cmd](Install.cmd)
- [Uninstall.cmd](Uninstall.cmd)
- [Open-AutoUnblockerSettings.cmd](Open-AutoUnblockerSettings.cmd)
- [Start-AutoUnblocker.cmd](Start-AutoUnblocker.cmd)
- [Stop-AutoUnblocker.cmd](Stop-AutoUnblocker.cmd)
- [Unblock-MarkdownFolder.cmd](Unblock-MarkdownFolder.cmd)

Esses arquivos:

- pedem elevacao quando necessario;
- chamam os scripts PowerShell corretos;
- evitam que voce precise decorar comandos;
- mostram o proximo passo de teste.

Observacao:

- os `.cmd` continuam sendo a entrada pratica para desenvolvimento, manutencao e laboratorio;
- para distribuicao limpa do produto, prefira o MSI.

### Fluxo de 1 clique em pasta confiavel

Depois da instalacao, o projeto tambem instala um auto-unblocker leve em background.

Na pratica:

- ele observa pastas confiaveis configuradas;
- por padrao ja cobre `Downloads`;
- quando um arquivo permitido chega com `Zone.Identifier`, ele remove o ADS sozinho;
- o objetivo e voce clicar no arquivo textual e o Preview Pane abrir direto.

Escopo:

- `.md` e variantes usam o preview handler deste projeto;
- `.txt`, `.log`, `.json`, `.yaml`, `.yml`, `.ini`, `.csv` e `.xml` dependem do preview que o Windows ou outro handler ja tiverem;
- o auto-unblocker so remove o bloqueio de origem quando aplicavel.

Configuracao padrao:

- settings: `%LOCALAPPDATA%\\MdExplorerPreview\\settings.json`
- log: `%USERPROFILE%\\AppData\\LocalLow\\MdExplorerPreview\\auto-unblocker.log`

Para editar as pastas monitoradas, use [Open-AutoUnblockerSettings.cmd](Open-AutoUnblockerSettings.cmd).

### Aparencia visual padrao

O preview agora usa uma aparencia unica, adaptada ao tema de apps do Windows.

Na pratica:

- se o Windows estiver em dark mode, o preview acompanha;
- se o Windows estiver em light mode, o preview acompanha;
- nao ha seletor manual de tema no microproduto.

### Instalacao

Opcao recomendada para distribuicao:

1. rode [Build-MarkdownPreviewMsi.ps1](scripts/Build-MarkdownPreviewMsi.ps1)
2. instale [MdExplorerPreview.Setup.msi](installer/bin/x64/Release/MdExplorerPreview.Setup.msi)

Opcao para laboratorio via source checkout:

1. clique duas vezes em [Install.cmd](Install.cmd)
2. aceite o UAC se o Windows pedir
3. espere a validacao terminar
4. se quiser mudar a pasta customizada monitorada, abra [Open-AutoUnblockerSettings.cmd](Open-AutoUnblockerSettings.cmd)

### Remocao

Opcao recomendada para distribuicao:

- remova por `Apps e Recursos` ou pelo proprio MSI

Opcao para laboratorio via source checkout:

1. clique duas vezes em [Uninstall.cmd](Uninstall.cmd)
2. aceite o UAC se o Windows pedir
3. espere a validacao terminar

### Teste final rapido

Depois da instalacao:

1. abra o Explorer;
2. ative `Visualizar > Painel de visualizacao`;
3. selecione [preview-fixture.md](content/validation-suite/preview-fixture.md);
4. depois teste [01-simple.md](content/validation-suite/01-simple.md) e [05-local-image.md](content/validation-suite/05-local-image.md);
5. para leitura longa, compare tambem:
   - [manifesto-operacional.md](content/mind-os-template/00-constituicao/manifesto-operacional.md)
   - [auditoria.md](content/mind-os-template/01-modos/auditoria.md)
   - [prancheta-mestra.md](content/mind-os-template/02-projetos/template-projeto/prancheta-mestra.md)
   - [08-syntax-guide.md](content/validation-suite/08-syntax-guide.md)

Para uma bateria mais completa, veja [VALIDATION-MATRIX.md](docs/VALIDATION-MATRIX.md).

### Teste rapido do auto-unblocker

1. abra [Open-AutoUnblockerSettings.cmd](Open-AutoUnblockerSettings.cmd);
2. confirme que a pasta desejada esta em `watchFolders`;
3. salve o arquivo;
4. rode [Start-AutoUnblocker.cmd](Start-AutoUnblocker.cmd);
5. coloque um `.md` baixado na pasta monitorada;
6. espere alguns segundos;
7. abra o Explorer e clique no arquivo.

Se quiser testar texto simples do sistema, repita com `.txt` ou `.log`.

Para ver o detalhe do que aconteceu, abra o log em `%USERPROFILE%\\AppData\\LocalLow\\MdExplorerPreview\\auto-unblocker.log`.

### Ligar, desligar e reconfigurar o auto-unblocker

- iniciar ou reiniciar: [Start-AutoUnblocker.cmd](Start-AutoUnblocker.cmd)
- parar: [Stop-AutoUnblocker.cmd](Stop-AutoUnblocker.cmd)
- editar configuracao: [Open-AutoUnblockerSettings.cmd](Open-AutoUnblockerSettings.cmd)

Mais detalhe em [AUTO-UNBLOCKER.md](docs/AUTO-UNBLOCKER.md).

### Se o seu foco for o pacote mind-os

Gere um workspace local em vez de depender de `.zip` baixado repetidamente:

```powershell
.\scripts\New-MindOsWorkspace.ps1 -Destination C:\mind-os\meu-workspace
```

Isso reduz a friccao do `Zone.Identifier`.

### Se voce quiser montar um laboratorio de validacao

```powershell
.\scripts\Prepare-ValidationWorkspace.ps1 -Destination C:\temp\md-preview-validation -Force
```

### Se o painel mostrar aviso de seguranca

Isso normalmente e Windows bloqueando arquivo vindo da internet, nao defeito do handler.

Opcoes:

- desbloquear o `.zip` antes de extrair;
- rodar [Unblock-MarkdownFiles.ps1](scripts/Unblock-MarkdownFiles.ps1);
- rodar [Unblock-MarkdownFolder.cmd](Unblock-MarkdownFolder.cmd) para uma pasta inteira sem precisar de comando PowerShell;
- usar um workspace gerado localmente com [New-MindOsWorkspace.ps1](scripts/New-MindOsWorkspace.ps1).

Quando a pasta estiver configurada como confiavel no auto-unblocker, o fluxo normal passa a ser automatico para os tipos permitidos.

## Para quem quer entender arquitetura e manutencao

Leia:

- [IMPLEMENTACAO.md](IMPLEMENTACAO.md)
- [GITHUB-PUBLISHING.md](docs/GITHUB-PUBLISHING.md)
- [MSI-PACKAGING.md](docs/MSI-PACKAGING.md)
- [AUTO-UNBLOCKER.md](docs/AUTO-UNBLOCKER.md)
- [PACKAGE-BOUNDARIES.md](docs/PACKAGE-BOUNDARIES.md)
- [VALIDATION-MATRIX.md](docs/VALIDATION-MATRIX.md)
- [DISTRIBUTION-ROADMAP.md](docs/DISTRIBUTION-ROADMAP.md)

## Separacao entre motor e conteudo

### Motor do preview

- `src/`
- `src/MdExplorerPreview.AutoUnblocker/`
- `src/MdExplorerPreview/Resources/`
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

### Conteudo visualizado

- [content/README.md](content/README.md)
- [content/mind-os-template](content/mind-os-template)
- [content/validation-suite](content/validation-suite)

### Problema do Windows

- `Zone.Identifier`
- UAC
- politica de execucao

### Problema do Explorer

- `prevhost.exe`
- cache do shell
- carregamento do Preview Pane

### Problema do handler

- renderizacao Markdown
- registro COM/Shell
- compatibilidade do controle de preview
- camada visual adaptativa e acabamento tipografico

### Problema da camada auxiliar de UX

- monitoramento seletivo de pastas confiaveis
- debounce e retry do watcher
- configuracao e log do auto-unblocker
