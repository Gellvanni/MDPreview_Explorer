# Distribution Roadmap

Este documento prepara o projeto para a proxima fase sem forcar mudancas prematuras no handler atual.

## Estado desta fase

Esta fase consolidou:

- bootstrap com `Install.cmd` e `Uninstall.cmd`;
- separacao entre motor e conteudo em `content/`;
- matriz de validacao repetivel;
- fluxo de adocao mais limpo.

## Direcao 1: MSI/EXE installer

### Objetivo

Reduzir ainda mais a friccao operacional para usuario final:

- elevar privilegios quando necessario;
- instalar ou localizar prerequisitos;
- registrar o handler;
- reiniciar o Explorer;
- oferecer desinstalacao limpa.

### O que ja esta pronto para isso

- bootstrap `.cmd` para usuario final;
- scripts unificados de instalacao e remocao;
- validacao pos-operacao;
- separacao clara entre registro Shell/COM, runtime do handler e pacote de conteudo.

### O que faltaria

- empacotar a DLL e scripts em um instalador;
- decidir se a build acontece antes do empacotamento ou no pipeline CI;
- opcionalmente assinar binarios e instalador.

## Direcao 2: WebView2 renderer

### Objetivo

Trocar a superficie `WebBrowser` por uma base mais moderna para HTML/CSS e assets locais.

### O que pode permanecer

- registro COM;
- associacoes ShellEx;
- scripts de instalacao/remocao;
- pipeline de conversao Markdown;
- estrategia de validacao.

### O que mudaria

- [MarkdownPreviewControl.cs](../src/MdExplorerPreview/MarkdownPreviewControl.cs)
- politica de runtime e distribuicao do WebView2;
- testes de compatibilidade do host `prevhost.exe`.

## Direcao 3: separacao entre handler e pacote Markdown

### Objetivo

Parar de tratar conteudo `mind-os` e handler como um bloco unico na experiencia do usuario.

### Estrutura sugerida

- pacote A: handler do Explorer
- pacote B: template/conteudo `mind-os`
- opcional: comando de bootstrap para gerar workspaces locais

### Beneficio

- o handler vira uma dependencia de sistema;
- o conteudo vira material de trabalho;
- `Zone.Identifier` passa a ser tratado no fluxo do conteudo, nao do handler.

## Decisao recomendada para a proxima iteracao

Se a prioridade for adocao por usuarios finais, a melhor sequencia e:

1. consolidar `Install.cmd` e `Uninstall.cmd` como entrada oficial;
2. empacotar em MSI/EXE;
3. depois considerar migracao para WebView2;
4. paralelamente, separar distribuicao do handler e do pacote `mind-os`.
