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

**Fonte da verdade:** ADR-051 (`docs/02_ARQUITETURA_ATIVA/ADR-051-RELATORIOS-VISIBILIDADE-CRONOLOGIA.md`).

- Aba **Gerados** (Publicacoes): lista apenas `MarketingCaseStatus.published`, ativo e nao deletado; ACL produtor via adapter ADR-050 (`marketingCaseReportsListImplProvider`). Consultoria consome via `core/contracts`.
- **Cronologia segura:** Consolidados, export de Ocorrencias, aba Visitas e aba Gerados (quando 2+ `clientId`) exigem `clientId` unico. Com multiplos produtores, selecao obrigatoria antes de listar ou exportar; nunca misturar dados de produtores distintos.
- **Defense-in-depth:** builders de export em `relatorios_generated_reports.dart` refiltram por `clientId` (ver ADR-051).
