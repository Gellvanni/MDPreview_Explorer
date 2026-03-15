# Zone Identifier Validation

Este arquivo deve ser usado para validar o comportamento quando o Windows marca o arquivo como vindo da internet.

## Resultado esperado

- com `Zone.Identifier`: o Explorer pode mostrar aviso de seguranca antes do handler;
- sem `Zone.Identifier`: o handler deve renderizar normalmente.
