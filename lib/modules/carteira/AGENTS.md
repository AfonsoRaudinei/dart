# AGENTS.md — carteira

## Bounded context

`carteira/` gerencia clientes comerciais, oportunidades e pipeline de relacionamento.

## Contratos e dependencias

- Expoe/implementa lookup de cliente e oportunidade quando aplicavel.
- Deve usar `core/contracts/IClientLookup` e `IOpportunityLookup` para fronteiras.

## Proibido

- Importar outros `modules/*` diretamente.
- Duplicar entidades de consultoria para contornar contrato.
- Persistir oportunidade sem `user_id` e `sync_status` quando sincronizavel.

## Qualidade obrigatoria

- Regras comerciais ficam em domain/data, nao na tela.
- Estados de filtros simples podem usar `StateProvider<T>`.
- Testes esperados: `test/modules/carteira/`.
- Rodar `flutter analyze lib/modules/carteira/` e `./tool/arch_check.sh`.

