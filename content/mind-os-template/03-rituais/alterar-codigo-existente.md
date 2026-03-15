# Ritual — Alterar Código Existente

> Use antes de modificar código já em funcionamento.

---

## Prompt-base

Não quero mexer neste código como se fosse uma ilha.

Quero que você:
- leia a função real dessa estrutura;
- identifique dependências diretas e indiretas;
- localize acoplamentos, comportamentos implícitos e riscos de regressão;
- diferencie correção pontual de reestruturação necessária;
- proponha o menor caminho seguro e, se cabível, o caminho estruturalmente mais saudável.

Devolva em sete blocos:

### 1. O que esta parte faz hoje
### 2. Onde ela conversa com o resto
### 3. O que pode quebrar
### 4. O que está remendado ou legado
### 5. Alteração mínima segura
### 6. Alteração estrutural recomendada
### 7. Decisão mais sensata agora

---

## Uso recomendado
Acione sempre que houver medo de “consertar uma coisa e bagunçar outras cinco”.
