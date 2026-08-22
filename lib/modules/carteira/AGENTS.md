# AGENTS.md — carteira

## Bounded context

`carteira/` gerencia clientes comerciais, oportunidades e pipeline de relacionamento.

Documentação completa: `docs/02_ARQUITETURA_ATIVA/MODULO_CARTEIRA.md`

## Contratos e dependencias

- Expoe/implementa lookup de cliente e oportunidade quando aplicavel.
- Deve usar `core/contracts/IClientLookup` e `IOpportunityLookup` para fronteiras.

## Proibido

- Importar outros `modules/*` diretamente.
- Duplicar entidades de consultoria para contornar contrato.
- Persistir oportunidade sem `user_id` e `sync_status` quando sincronizavel.
- Hard delete de lançamento (`carteira_lancamentos`) — usar soft delete (`deleted_at` + `pending_sync`). ADR-051.

## Sync remoto (ADR-051)

- As 7 tabelas SQLite têm espelho no Supabase. `CarteiraSyncModule` (tier 1) hidrata no login.
- `sync_status` obrigatório. Sem JWT o `syncNow()` é no-op.
- Depois de reinstalar, metas/safras/lançamentos/categorias/tipos voltam se já tinham sido sincronizados.

## Qualidade obrigatoria

- Regras comerciais ficam em domain/data, nao na tela.
- Estados de filtros simples podem usar `StateProvider<T>`.
- Testes esperados: `test/modules/carteira/`.
- Rodar `flutter analyze lib/modules/carteira/` e `./tool/arch_check.sh`.

