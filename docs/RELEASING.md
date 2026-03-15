# Releasing

## Fluxo recomendado

1. ajuste a versao em [InstallerVersion.props](../installer/InstallerVersion.props)
2. gere o MSI com [Build-MarkdownPreviewMsi.ps1](../scripts/Build-MarkdownPreviewMsi.ps1)
3. valide instalacao, preview e auto-unblocker
4. crie uma tag Git como `v1.0.1`
5. publique uma GitHub Release com a mesma tag
6. anexe o arquivo `MdExplorerPreview.Setup.msi`

## O que publicar no GitHub Release

- titulo da release
- notas curtas do que o produto faz
- limites conhecidos
- asset binario:
  `MdExplorerPreview.Setup.msi`

## O que nao subir no repositorio

- `bin/`
- `obj/`
- `artifacts/`
- logs locais
- MSI gerado

## Checklist antes de publicar

- `README.md` revisado
- `LICENSE` presente
- repositiorio limpo
- MSI gerado com sucesso
- teste de instalacao concluido
- teste de preview `.md` concluido
- teste do auto-unblocker em `Downloads` concluido

## Sugestao de About no GitHub

`Markdown Preview Handler + trusted-folder auto-unblocker for Windows Explorer Preview Pane.`

## Sugestao de topics

- `windows`
- `explorer`
- `preview-handler`
- `markdown`
- `wix`
- `dotnet-framework`
- `shell`
