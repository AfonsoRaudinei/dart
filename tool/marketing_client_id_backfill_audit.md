# Marketing Cases — auditoria de `client_id`

O backfill idempotente roda automaticamente no carregamento de
`marketingCasesProvider` (após leitura do cache local).

## Cobertura em runtime

Procure no log:

```
tag: MarketingBackfill
MarketingCase client_id backfill: antes: X/Y com client_id → depois: ...
```

## Auditoria offline (testes)

```bash
flutter test test/modules/marketing/domain/marketing_case_client_id_resolver_test.dart
flutter test test/modules/marketing/data/marketing_case_client_id_backfill_service_test.dart
```

Função utilitária: `auditMarketingCaseClientIdCoverage(cases)` em
`marketing_case_client_id_backfill_service.dart`.

## Regras de inferência

1. `client_id` existente → mantido
2. Match único `produtor_fazenda` ↔ nome de cliente (`IClientLookup`)
3. Padrão `Cliente - Fazenda` com fazenda do mesmo cliente (`IFarmLookup`)
4. Match único por nome de fazenda
5. Sem match único → `null` (não inventar)
