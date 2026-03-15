# MdExplorerPreview v1.0.1

Primeira release publica do `MdExplorerPreview`.

## O que entrega

- preview de arquivos Markdown no Preview Pane do Windows Explorer
- instalacao por MSI
- registro do preview handler sem trocar o app padrao do `.md`
- auto-unblocker leve para pastas confiaveis
- suporte automatico a `Downloads` por padrao
- desbloqueio seletivo para arquivos textuais seguros, como:
  `.md`, `.txt`, `.log`, `.json`, `.yaml`, `.yml`, `.ini`, `.csv`, `.xml`

## O que nao faz

- nao desliga a protecao global do Windows
- nao desbloqueia executaveis e scripts por padrao
- nao tenta substituir o preview nativo de outros tipos fora do escopo

## Notas importantes

- o preview de `.md` usa o handler deste projeto
- arquivos textuais como `.txt` e `.log` dependem do preview que o Windows ja tiver
- o auto-unblocker apenas remove `Zone.Identifier` em pastas confiaveis configuradas

## Instalacao

1. baixe `MdExplorerPreview.Setup.msi`
2. execute o instalador como administrador
3. abra o Explorer
4. ative o Preview Pane
5. teste um arquivo `.md`

## Limitacoes conhecidas

- o renderer atual ainda usa `WinForms WebBrowser`
- alguns estados do Explorer podem exigir reinicio do `prevhost` ou do Explorer
- arquivos fora de pastas confiaveis continuam sujeitos ao comportamento normal do Windows
