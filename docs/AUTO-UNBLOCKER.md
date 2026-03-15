# Auto-Unblocker

Esta camada existe para reduzir a friccao do `Zone.Identifier` em pastas confiaveis sem desligar a protecao do Windows globalmente.

## O que ele faz

- observa pastas confiaveis configuradas;
- filtra por extensao permitida;
- espera o arquivo estabilizar;
- verifica se ha `Zone.Identifier`;
- remove o ADS quando a extensao e permitida;
- registra em log o que aconteceu.

Escopo exato:

- `.md` e variantes continuam usando o preview handler deste projeto;
- `.txt`, `.log`, `.json`, `.yaml`, `.yml`, `.ini`, `.csv` e `.xml` usam o preview que o Windows ou outro handler ja tiverem;
- o auto-unblocker nao renderiza nada por conta propria; ele so remove o bloqueio de origem quando permitido.

## Por que um app leve em background e nao um Windows Service

A escolha atual e intencional:

- as pastas observadas sao do proprio usuario, como `Downloads`;
- a configuracao fica em `%LOCALAPPDATA%`;
- o log fica em `%USERPROFILE%\\AppData\\LocalLow`;
- a execucao por atalho de inicializacao do usuario evita conta de servico, privilegios extras e depuracao mais hostil;
- a UX real e melhor: instala uma vez, entra no Windows, roda em segundo plano.

Um `Windows Service` global seria mais complexo e menos coerente com o problema:

- teria de lidar com contexto de usuario, perfis e permissao em pastas pessoais;
- aumentaria superficie de risco sem trazer beneficio real aqui;
- empurraria o projeto para uma topologia mais pesada antes da hora.

## Estrategia para arquivos novos, movidos e extraidos

O watcher escuta:

- `Created`
- `Changed`
- `Renamed`

Isso cobre os fluxos mais comuns:

- download direto em `Downloads`;
- arquivo extraido dentro da pasta confiavel;
- copia para pasta confiavel;
- movimentacao/renomeacao para dentro da pasta confiavel.

Para casos em que o arquivo chega antes de terminar de ser escrito, o app:

- aguarda um `settle delay`;
- tenta abrir o arquivo com exclusividade;
- reprograma a tentativa se o arquivo ainda estiver ocupado;
- limita as tentativas por `maxWaitMs`.

Para evitar ruido de eventos duplicados do `FileSystemWatcher`, o app:

- agrupa por caminho com `ConcurrentDictionary`;
- faz debounce por arquivo;
- reprograma o mesmo candidato em vez de processar tudo de novo.

## Estrategia para `.zip`

Existem tres caminhos conceituais:

- `A`: desbloquear o `.zip` assim que ele chega;
- `B`: ignorar o `.zip` e agir so nos arquivos extraidos permitidos;
- `C`: suportar os dois fluxos.

Recomendacao atual:

- padrao seguro: `B`
- opcao avancada: `C`

No produto atual isso aparece assim:

- `unblockZipOnArrival = false` por padrao
- se voce ativar `true`, o watcher tambem remove o `Zone.Identifier` do proprio `.zip`

Trade-off:

- vantagem de `B`: um `.zip` com executaveis ou scripts continua marcado; o app so toca nos tipos explicitamente aprovados quando eles aparecem extraidos;
- custo de `B`: o proprio `.zip` continua bloqueado;
- vantagem de `C`: fluxos de conteudo 100% confiavel ficam mais lisos;
- custo de `C`: desbloquear o `.zip` pode fazer com que arquivos perigosos extraidos depois percam a marca da internet.

Por isso o padrao permanece conservador.

## Configuracao

Arquivo padrao:

- `%LOCALAPPDATA%\\MdExplorerPreview\\settings.json`

Exemplo:

```json
{
  "autoUnblockEnabled": true,
  "dryRun": false,
  "logEnabled": true,
  "logPath": "%USERPROFILE%\\AppData\\LocalLow\\MdExplorerPreview\\auto-unblocker.log",
  "scanOnStartup": true,
  "unblockZipOnArrival": false,
  "settleDelayMs": 700,
  "retryDelayMs": 700,
  "maxWaitMs": 20000,
  "allowedExtensions": [
    ".md",
    ".markdown",
    ".mdown",
    ".mkdn",
    ".mdwn",
    ".txt",
    ".log",
    ".json",
    ".yaml",
    ".yml",
    ".ini",
    ".csv",
    ".xml",
    ".svg",
    ".png",
    ".jpg",
    ".jpeg",
    ".zip"
  ],
  "watchFolders": [
    {
      "name": "Downloads",
      "path": "%USERPROFILE%\\Downloads",
      "enabled": true,
      "recursive": true
    },
    {
      "name": "CustomTrustedFolder",
      "path": "%USERPROFILE%\\Documents\\TrustedMarkdown",
      "enabled": false,
      "recursive": true
    }
  ]
}
```

## Log e auditoria

Local padrao:

- `%USERPROFILE%\\AppData\\LocalLow\\MdExplorerPreview\\auto-unblocker.log`

O log registra:

- arquivo;
- extensao;
- pasta logica;
- se havia `Zone.Identifier`;
- se foi desbloqueado;
- se foi ignorado;
- se houve timeout ou erro.

## Operacao diaria

Comandos de usuario:

- [Start-AutoUnblocker.cmd](../Start-AutoUnblocker.cmd)
- [Stop-AutoUnblocker.cmd](../Stop-AutoUnblocker.cmd)
- [Open-AutoUnblockerSettings.cmd](../Open-AutoUnblockerSettings.cmd)

Fluxo esperado:

1. o arquivo permitido cai numa pasta confiavel;
2. o auto-unblocker processa em segundo plano;
3. voce clica no arquivo textual;
4. o Preview Pane abre sem ritual manual de desbloqueio.

## Seguranca e limites

O auto-unblocker e diferente de desligar a protecao do Windows:

- ele age so em pastas explicitamente confiaveis;
- ele age so nas extensoes da whitelist;
- ele nao toca em `.exe`, `.dll`, `.ps1`, `.bat`, `.cmd`, `.msi`, `.docm`, `.xlsm` por padrao;
- ele nao altera politica global do Windows.

Limites conhecidos:

- alguns fluxos de terceiros podem gerar eventos em ordem estranha; por isso existe debounce, retry e `scanOnStartup`;
- se um arquivo continuar bloqueado, revise a whitelist, a pasta monitorada e o log;
- o preview handler continua separado desta camada: se o watcher desbloqueou e o preview ainda falhar, o problema ja nao esta no `Zone.Identifier`.

## Validacao

Validacao automatizada:

```powershell
.\scripts\Test-MarkdownPreviewAutoUnblocker.ps1
```

Cenarios cobertos:

- `.md` criado localmente;
- `.md` baixado;
- `.txt` baixado;
- `.txt` ja existente na pasta monitorada no inicio do app;
- `.log` baixado;
- `.json` baixado;
- `.md` extraido em subpasta recursiva;
- `.svg` baixado;
- `.zip` com comportamento conservador;
- `.zip` com opt-in de desbloqueio;
- arquivo nao permitido como `.exe` e `.ps1`;
- pasta monitorada e nao monitorada;
- copia rapida para pasta confiavel.
