# AGENTS.md — feedback

## Bounded context

`feedback/` coleta feedback, suporte e sinais de qualidade do usuario.

## Contratos e dependencias

- Pode usar utilitarios e servicos neutros de `core/`.
- Nao deve depender de modulos de dominio.

## Proibido

- Enviar dados sensiveis sem sanitizacao.
- Acoplar feedback a telas internas especificas por import direto.
- Inventar usuario, device ou contexto quando nao houver fonte real.

## Qualidade obrigatoria

- Erros devem ser claros e nao vazar detalhe tecnico sensivel.
- Testes esperados: `test/modules/feedback/`.
- Rodar `flutter analyze lib/modules/feedback/` e `./tool/arch_check.sh`.

