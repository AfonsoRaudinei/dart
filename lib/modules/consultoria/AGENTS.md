# AGENTS.md — consultoria

## Bounded context

`consultoria/` e o dominio tecnico de clientes, fazendas, talhoes, ocorrencias, publicacoes e relatorios de visita.

## Contratos e dependencias

- Pode implementar/consumir contratos neutros em `core/contracts`: `IClientLookup`, `IFarmLookup`, `IFieldLookup`, `IVisitSessionLookup`, `IReportWriter`.
- Deve manter comunicacao com agenda, drawing e visitas por contratos.

## Proibido

- Importar `modules/drawing`.
- Recriar `lib/modules/consultoria/agenda/`; este modulo foi deletado.
- Referenciar `lib/modules/reports/`; usar `relatorios/`.
- Fazer hard delete de dados sincronizaveis.

## Qualidade obrigatoria

- Entidades persistidas exigem `user_id` e `sync_status`.
- Ocorrencias e relatorios devem preservar trilha de sync e exclusao logica.
- Testes esperados: `test/modules/consultoria/`.
- Rodar `flutter analyze lib/modules/consultoria/` e `./tool/arch_check.sh`.

## Relatorios — regras de visibilidade e cronologia

- Aba **Gerados** (Publicacoes): lista apenas `MarketingCaseStatus.published`, ativo e nao deletado. Filtro no adapter ADR-050 (`marketingCaseReportsListImplProvider`); consultoria consome via `core/contracts`.
- Aba **Consolidados** e export de **Ocorrencias**: obrigatorio `clientId` unico por exportacao. Com multiplos produtores, exigir selecao antes de consolidar ou exportar; nunca misturar dados de produtores distintos.
