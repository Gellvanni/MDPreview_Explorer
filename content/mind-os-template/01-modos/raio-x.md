# Modo: Raio-X

## Finalidade
Ler a anatomia de um sistema existente antes de alterá-lo, com foco em dependências, impactos, fragilidades e coerência arquitetural.

## Quando usar
- quando há código, banco, UI ou fluxo já implementados;
- quando o usuário deseja alterar algo existente;
- quando existe medo de quebrar outras áreas;
- quando a pergunta envolve “o que isso afeta?”, “onde isso está sendo atribuído?”, “como essa estrutura conversa com o resto?”.

## Pergunta central
**O que esta estrutura faz, de que depende, o que depende dela e o que acontece se a alterarmos?**

## Entradas mínimas
- prancheta mestra;
- sessão atual;
- arquivos ou módulos em foco;
- prints, schemas, dumps ou logs, quando houver;
- decisões congeladas relacionadas.

## Operações cognitivas
1. identificar a função de cada estrutura relevante;
2. mapear acoplamentos, fluxos e dependências;
3. localizar hard-coded, legados, remendos e pontos frágeis;
4. diferenciar o que é núcleo, borda, adaptação temporária e dívida técnica;
5. prever impacto lateral de alteração;
6. explicitar zonas de risco e zonas seguras.

## Perguntas-matriz
- Qual a função declarada desta estrutura?
- Qual a função real, observada no sistema?
- Onde ela é lida, escrita, acionada ou inferida?
- Que partes ficarão incoerentes se ela mudar?
- Existe duplicação de responsabilidade?
- O problema está na peça analisada ou em sua relação com outras?
- Há diferença entre o que o código sugere e o que a jornada real do usuário exige?

## Saída esperada
- mapa funcional das estruturas;
- dependências críticas;
- impacto de alteração;
- risco de regressão;
- alternativas arquiteturais;
- recomendação de mudança mínima segura e, se cabível, mudança estrutural mais profunda.

## O que não fazer
- confundir familiaridade com compreensão;
- alterar sem mapear dependências;
- responder só com leitura técnica sem contexto de jornada;
- sugerir reescrita total por preguiça de entender o que existe.

## Critério de encerramento
O raio-x termina quando:
- há clareza sobre o papel da estrutura;
- os impactos laterais ficaram explícitos;
- já é possível decidir se vale corrigir, adaptar, encapsular ou reestruturar.

## Template de resposta
### Estrutura em foco
### O que ela faz hoje
### Relações e dependências
### Riscos de alteração
### Alternativas técnicas
### Recomendação
### Próximo modo recomendado
