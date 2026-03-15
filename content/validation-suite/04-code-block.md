# Code Block Validation

```powershell
Get-ChildItem .\content\validation-suite -Filter *.md
```

```json
{
  "handler": "MdExplorerPreview",
  "mode": "read-only",
  "target": "Explorer Preview Pane"
}
```

## Resultado esperado

- bloco de codigo com fundo diferenciado
- quebra de linha preservada
- fonte monoespacada
