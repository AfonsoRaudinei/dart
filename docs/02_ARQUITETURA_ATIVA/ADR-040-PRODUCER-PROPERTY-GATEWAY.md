# ADR-040 — Gateway de propriedade do produtor

**Data:** 17/06/2026
**Status:** APROVADO

## Contexto

O módulo `produtor` precisa ler e editar a propriedade própria, mas clientes,
fazendas e talhões pertencem ao bounded context `consultoria`. O repositório do
produtor importava entidades e repositórios de `consultoria` diretamente.

## Decisão

Criar `IProducerPropertyGateway` em `core/contracts`, com DTOs mínimos de
propriedade, fazenda e talhão. A implementação concreta permanece em
`consultoria/clients/infra` e é registrada no bootstrap do aplicativo.

## Regras

- `produtor/` depende somente do contrato neutro.
- `consultoria/` permanece dona da persistência agronômica.
- O gateway preserva `user_id`, `sync_status` e exclusão lógica dos repositórios.
- Nenhuma entidade de domínio atravessa a fronteira.

## Consequências

- Remove o acoplamento lateral `produtor -> consultoria`.
- Permite testar o fluxo do produtor com gateway falso.
- Novos comandos exigem consumidor real e atualização deste contrato.
