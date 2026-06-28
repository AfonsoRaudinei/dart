# ADR-039 — Contrato de criação de convite de produtor

## Status

Ativo — Jun/2026.

## Contexto

`consultoria/clients` precisa iniciar a criação de um convite cujo fluxo e
persistência pertencem ao módulo `produtor`. Importar o repositório do produtor
diretamente criaria acoplamento lateral entre bounded contexts.

## Decisão

Expor `IProducerInviteWriter` em `core/contracts`. O módulo `produtor` fornece
o adapter concreto e `main.dart` registra a implementação no `ProviderScope`.
O contrato retorna somente token e expiração, sem expor modelos do módulo.

## Consequências

- `consultoria` não importa classes de `produtor`.
- A composição concreta permanece no ponto de entrada do aplicativo.
- Mudanças internas no repositório de vínculos não afetam a tela de cliente.
