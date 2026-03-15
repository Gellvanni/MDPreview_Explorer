# Validation Matrix

Esta matriz valida duas camadas diferentes:

- preview handler no Explorer;
- auto-unblocker em pastas confiaveis.

Escopo de preview:

- `.md` e variantes dependem do preview handler deste projeto;
- `.txt`, `.log`, `.json`, `.yaml`, `.yml`, `.ini`, `.csv` e `.xml` dependem do preview que ja existir no Windows ou em outro handler instalado.

## Como preparar o laboratorio

Opcao rapida para o preview:

```powershell
.\scripts\Prepare-ValidationWorkspace.ps1 -Destination C:\temp\md-preview-validation -Force
```

Isso gera:

- uma copia da suite de validacao;
- um arquivo com `Zone.Identifier`;
- um arquivo explicitamente desbloqueado;
- um arquivo vindo por copia local.

Opcao automatizada para o auto-unblocker:

```powershell
.\scripts\Test-MarkdownPreviewAutoUnblocker.ps1
```

Esse script cria um laboratorio isolado em `%TEMP%` e valida o watcher sem depender do seu `Downloads` real.

## Casos de validacao

| Caso | Arquivo | Como obter | Resultado esperado |
| --- | --- | --- | --- |
| Markdown simples | `01-simple.md` | suite base | renderizacao basica |
| Markdown longo | `02-long.md` | suite base | rolagem estavel |
| Tabela | `03-table.md` | suite base | tabela visivel |
| Bloco de codigo | `04-code-block.md` | suite base | `pre/code` legivel |
| Imagem local | `05-local-image.md` | suite base | SVG local carregado |
| Arquivo com `Zone.Identifier` | `06-zone-identifier.md` | `Prepare-ValidationWorkspace.ps1` | Windows pode bloquear antes do handler |
| Arquivo desbloqueado | `07-unblocked.md` | suite base ou apos `Unblock-MarkdownFiles.ps1` | preview renderizado sem aviso |
| Arquivo vindo por copia local | `local-copy\01-simple-local-copy.md` | `Prepare-ValidationWorkspace.ps1` | preview renderizado como arquivo local |
| Guia sintatico completo | `08-syntax-guide.md` | suite base | headings, listas, blockquotes, links, tabela e codigo com acabamento coerente |

## Casos de validacao do auto-unblocker

| Caso | Como validar | Resultado esperado |
| --- | --- | --- |
| `.md` criado localmente | criar arquivo na pasta monitorada | continua sem `Zone.Identifier`; sem alteracao indevida |
| `.txt` ja existente na pasta monitorada no startup | deixar `.txt` bloqueado antes de iniciar o app | ADS removido durante `scanOnStartup` |
| `.md` baixado | gravar `.md` permitido com `Zone.Identifier` em pasta monitorada | ADS removido automaticamente |
| `.txt` baixado | gravar `.txt` permitido com `Zone.Identifier` em pasta monitorada | ADS removido automaticamente |
| `.log` baixado | gravar `.log` permitido com `Zone.Identifier` em pasta monitorada | ADS removido automaticamente |
| `.json` baixado | gravar `.json` permitido com `Zone.Identifier` em pasta monitorada | ADS removido automaticamente |
| `.md` extraido de zip | gravar `.md` permitido em subpasta monitorada recursivamente | ADS removido automaticamente |
| `.svg` baixado | gravar `.svg` permitido com `Zone.Identifier` | ADS removido automaticamente |
| `.zip` baixado com modo conservador | gravar `.zip` permitido com `unblockZipOnArrival=false` | `.zip` permanece bloqueado |
| `.zip` baixado com opt-in | gravar `.zip` permitido com `unblockZipOnArrival=true` | ADS removido automaticamente |
| arquivo nao permitido `.exe` | gravar `.exe` com `Zone.Identifier` | arquivo permanece bloqueado |
| arquivo nao permitido `.ps1` | gravar `.ps1` com `Zone.Identifier` | arquivo permanece bloqueado |
| pasta nao monitorada | gravar `.md` bloqueado fora de `watchFolders` | arquivo permanece bloqueado |
| subpasta recursiva | gravar `.md` bloqueado em subpasta de watcher recursivo | ADS removido automaticamente |
| copia rapida e clique em seguida | copiar `.md` bloqueado permitido para pasta monitorada | ADS removido sem ritual manual |

## Casos de validacao visual com arquivos reais do mind-os

| Arquivo real | O que observar |
| --- | --- |
| `content/mind-os-template/00-constituicao/manifesto-operacional.md` | conforto de leitura longa, densidade editorial, headings fortes |
| `content/mind-os-template/01-modos/auditoria.md` | listas, estrutura de secoes e leitura operacional |
| `content/mind-os-template/02-projetos/template-projeto/prancheta-mestra.md` | neutralidade, ritmo e clareza estrutural |

Arquivos de apoio visual:

- `content/validation-suite/03-table.md`
- `content/validation-suite/04-code-block.md`
- `content/validation-suite/05-local-image.md`
- `content/validation-suite/08-syntax-guide.md`

## Procedimento sugerido

1. Para distribuicao MSI, gere o pacote com [Build-MarkdownPreviewMsi.ps1](../scripts/Build-MarkdownPreviewMsi.ps1) e valide com [Test-MarkdownPreviewMsi.ps1](../scripts/Test-MarkdownPreviewMsi.ps1).
2. Para laboratorio por scripts, rode [Install.cmd](../Install.cmd) ou [Install-MarkdownPreview.ps1](../scripts/Install-MarkdownPreview.ps1).
3. Abra o Explorer.
4. Ative o Painel de visualizacao.
5. Valide o watcher com [Test-MarkdownPreviewAutoUnblocker.ps1](../scripts/Test-MarkdownPreviewAutoUnblocker.ps1).
6. Teste os arquivos da matriz um a um.
7. Se quiser revisar fora do Explorer, gere artefatos HTML com [Test-MarkdownPreviewRendering.ps1](../scripts/Test-MarkdownPreviewRendering.ps1).
8. Registre:
   - se o preview abriu;
   - se o auto-unblocker removeu o ADS sozinho;
   - se houve aviso de seguranca;
   - se houve travamento;
   - se a renderizacao bate com o esperado;
   - se tipografia, contraste e ritmo continuam confortaveis em documentos densos;
   - se a paleta acompanha o modo de apps do Windows.

## Casos de validacao do MSI

| Caso | Como validar | Resultado esperado |
| --- | --- | --- |
| Instalacao limpa | `Test-MarkdownPreviewMsi.ps1 -Mode Install -Execute` | arquivos em `Program Files`, registro COM/Shell e entrada `HKLM\Run` criados |
| Upgrade sobre versao anterior | `Test-MarkdownPreviewMsi.ps1 -Mode Upgrade -PreviousMsiPath <msi-antigo> -Execute` | major upgrade concluido, preview continua funcional, config do usuario preservada |
| Uninstall | `Test-MarkdownPreviewMsi.ps1 -Mode Uninstall -Execute` | binarios e registro removidos, config/log preservados |
| Reinstalacao | `Test-MarkdownPreviewMsi.ps1 -Mode Reinstall -Execute` | produto volta a funcionar sem depender dos scripts antigos |
| Recriacao de config | apagar `%LOCALAPPDATA%\MdExplorerPreview\settings.json` e iniciar sessao | auto-unblocker recria settings no primeiro boot |
| Preview via MSI | instalar MSI e abrir `preview-fixture.md` | preview abre como no fluxo por script |
| Auto-unblocker via MSI | instalar MSI e derrubar `.md` ou `.txt` bloqueado em `Downloads` | log mostra `unblocked` e o preview abre sem ritual manual |

Para detalhes do fluxo de empacotamento, veja [MSI-PACKAGING.md](MSI-PACKAGING.md).

## Diagnostico por classe de falha

### Painel mostra aviso de seguranca

Provavel causa:

- Windows bloqueando arquivo vindo da internet via `Zone.Identifier`

Nao e defeito do handler.

Cheque tambem:

- se a pasta esta em `watchFolders`;
- se a extensao esta na whitelist;
- se o auto-unblocker esta rodando;
- se o log registrou `ignored-extension`, `ignored-zip` ou `unblocked`.

### Painel vazio ou sem renderizacao

Provavel causa:

- registro Shell/COM incompleto;
- Explorer ainda com cache antigo;
- arquivo maior ou diferente do caso validado.

### `prevhost.exe` nao aparece

Provavel causa:

- o Explorer nao encontrou ou nao carregou o preview handler;
- o problema esta antes da renderizacao.

### Auto-unblocker nao age

Provavel causa:

- settings nao incluem a pasta;
- extensao nao esta liberada;
- processo em background nao iniciou;
- o log esta desabilitado ou aponta para outro caminho;
- o arquivo ainda estava sendo escrito e excedeu `maxWaitMs`.
