# Ritual — Revisar Arquitetura

> Use quando for necessário reexaminar estrutura, coerência e consequências de uma decisão arquitetural.

---

## Prompt-base

Quero revisar a arquitetura desta parte do sistema sem cair nem em simplificação apressada nem em reescrita impulsiva.

Faça uma análise que considere simultaneamente:
- função técnica;
- razão de existência;
- relação com o restante do sistema;
- efeitos sobre a jornada do usuário;
- trade-offs arquiteturais;
- custo de manutenção;
- riscos de legado, duplicação ou acoplamento ruim.

Devolva em sete blocos:

### 1. O que esta estrutura é e faz
### 2. O que ela parece fazer, mas talvez não faça bem
### 3. Dependências e acoplamentos
### 4. Fragilidades, legados e riscos
### 5. Alternativas possíveis
### 6. Recomendação arquitetural
### 7. Próximo movimento mais inteligente

---

## Uso recomendado
Acione antes de mexer em:
- autenticação;
- onboarding;
- schema;
- integrações externas;
- módulos altamente acoplados;
- fluxos críticos.
