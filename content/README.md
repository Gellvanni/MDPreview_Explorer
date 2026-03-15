# Content Package

Este diretorio contem apenas conteudo Markdown e fixtures de validacao.

## O que mora aqui

- `mind-os-template/`
  Conteudo de exemplo do pacote `mind-os`.
- `validation-suite/`
  Arquivos de teste para validar o comportamento do Preview Pane.

## O que nao mora aqui

- DLL do preview handler
- registro COM
- scripts de instalacao e remocao do handler
- logica do renderer

## Fronteira conceitual

O conteudo e separado do runtime por um motivo:

- o handler e um microproduto de sistema;
- o conteudo e material visualizado por esse microproduto;
- `Zone.Identifier` e distribuicao de `.zip` pertencem ao fluxo do conteudo, nao ao runtime do handler.
