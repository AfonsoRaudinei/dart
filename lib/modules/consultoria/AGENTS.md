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

## Relatorios — cautela (IPA 210)

`relatorios/` herda chrome de `showSoloForteSheet` — regressao visual pode ocorrer **sem commit em relatorios/**.

- Sheets: `relatorios_page.dart` usa `Colors.transparent` — conteudo interno deve usar `soloForteSheetIsIos(context)` para cores
- HTML: logo SoloForte obrigatorio (`.cursor/rules/soloforte-designer.mdc`)
- Export iPad: `resolveSharePositionOrigin()`
- Filtro produtor/`clientId` em listas e export
- Sem import direto `modules/marketing/` (ADR-050)
- Doc: `.agent/AUDITORIA_REGRESSAO_IPA210.md`

