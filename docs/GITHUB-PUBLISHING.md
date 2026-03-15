# GitHub e Distribuicao

## Recomendacao pratica

Para este projeto, a forma mais simples e profissional de publicar e:

1. deixar o repositorio publico no GitHub;
2. usar a licenca MIT;
3. versionar apenas o codigo-fonte, scripts e docs;
4. publicar o MSI em GitHub Releases, nao dentro do repositorio.

## Publico x open source

Repositorio publico:

- qualquer pessoa consegue ver o codigo;
- isso sozinho nao concede direito automatico de uso, modificacao e redistribuicao.

Open source de verdade:

- repositorio publico;
- licenca explicita;
- regras claras de distribuicao.

Sem `LICENSE`, o projeto fica visivel, mas juridicamente fechado.

## Por que MIT aqui

MIT e uma boa primeira licenca para este projeto porque:

- e simples de entender;
- reduz friccao para adocao;
- permite uso comercial e redistribuicao;
- nao obriga o usuario final a abrir o codigo derivado.

Se no futuro voce quiser forcar compartilhamento das modificacoes, ai faz sentido considerar GPL.

## O que deve entrar no repositorio

Deve entrar:

- `src/`
- `scripts/`
- `installer/`
- `content/`
- `docs/`
- `README.md`
- `IMPLEMENTACAO.md`
- `LICENSE`
- `.gitignore`

Nao deve entrar:

- `bin/`
- `obj/`
- `artifacts/`
- `.tmp-ads-test/`
- MSI gerado
- logs locais

## Fluxo recomendado de release

1. ajuste a versao em [InstallerVersion.props](../installer/InstallerVersion.props)
2. gere o MSI com [Build-MarkdownPreviewMsi.ps1](../scripts/Build-MarkdownPreviewMsi.ps1)
3. teste instalacao, upgrade e uninstall
4. crie uma tag Git como `v1.0.1`
5. crie uma GitHub Release
6. anexe o MSI gerado na Release
7. copie para a Release um resumo curto do que mudou

## Estrategia de distribuicao

Repositorio:

- fonte;
- scripts;
- documentacao;
- exemplos.

GitHub Releases:

- `MdExplorerPreview.Setup.msi`

Isso deixa o repositorio limpo e o download para usuario final bem mais simples.

## Checklist antes de subir

- confirmar que `.gitignore` esta ativo
- remover artefatos locais antigos
- revisar `README.md`
- revisar `LICENSE`
- validar se o MSI instala em maquina limpa
- validar se o auto-unblocker inicia apos logon
