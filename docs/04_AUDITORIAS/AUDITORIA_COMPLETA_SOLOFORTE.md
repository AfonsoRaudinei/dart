# AUDITORIA_COMPLETA_SOLOFORTE

**Data da auditoria:** 08/03/2026  
**Escopo auditado:** árvore de trabalho atual (incluindo alterações locais)  
**Premissa:** sem alteração de código-fonte durante a auditoria

## 1. Visão geral da arquitetura

O sistema mantém a base modular (Flutter + Riverpod + SQLite + sync posterior) e preserva regras críticas do enforcement automatizado:

- `core -> modules` fora do router: sem violação detectada.
- acoplamentos laterais bloqueados no `arch_check.sh`: sem violação detectada.
- novos arquivos acima de 900 linhas: sem novos violadores bloqueantes.

Evidências de execução:

- `./tool/arch_check.sh`: **APROVADO**.
- `flutter analyze`: **101 issues** (inclui warnings estruturais).
- `flutter test`: **598 success / 8 error**.

Conclusão geral da visão arquitetural: a base segue protegida pelo enforcement atual, mas há deriva relevante entre contrato documental e implementação corrente, além de falhas de qualidade que impedem considerar o estado atual como baseline estável.

## 2. Qualidade estrutural

### Pontos fortes

- Fronteira `core` preservada conforme contrato ([app_router.dart:92](/Users/raudineisilvapereira/dev/appdart/lib/core/router/app_router.dart:92)).
- Regras principais do script de arquitetura continuam ativas ([arch_check.sh](/Users/raudineisilvapereira/dev/appdart/tool/arch_check.sh)).

### Pontos de atenção

- Baseline oficial registra 10 módulos ([ARCH_BASELINE_v1.1_SCORE_90.md:15](/Users/raudineisilvapereira/dev/appdart/docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md:15)), porém `lib/modules` hoje contém adicionais (`dashboard`, `feedback`, `ndvi`, `public`, `visitas`) sem atualização explícita de contrato.
- Há acoplamento cíclico e por camada entre `consultoria` e `visitas`:
  - [occurrence_controller.dart:5](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart:5)
  - [visit_controller.dart:7](/Users/raudineisilvapereira/dev/appdart/lib/modules/visitas/presentation/controllers/visit_controller.dart:7)
- Regressão de tamanho em arquivos críticos:
  - [drawing_controller.dart](/Users/raudineisilvapereira/dev/appdart/lib/modules/drawing/presentation/controllers/drawing_controller.dart)
  - [drawing_sheet.dart](/Users/raudineisilvapereira/dev/appdart/lib/modules/drawing/presentation/widgets/drawing_sheet.dart)
  - [map_occurrence_sheet.dart](/Users/raudineisilvapereira/dev/appdart/lib/ui/components/map/map_occurrence_sheet.dart)
  - [drawing_utils.dart](/Users/raudineisilvapereira/dev/appdart/lib/modules/drawing/domain/drawing_utils.dart)
- DIP em agenda parcialmente adotado:
  - contrato existe ([i_agenda_repository.dart:9](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/domain/repositories/i_agenda_repository.dart:9))
  - implementação concreta sem `implements` ([agenda_repository.dart:9](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/data/repositories/agenda_repository.dart:9))
  - warning de `@override` inválido ([agenda_repository.dart:56](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/data/repositories/agenda_repository.dart:56))
  - provider expõe concreto ([agenda_provider.dart:377](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/presentation/providers/agenda_provider.dart:377))

## 3. Análise de estado (Riverpod)

### Situação atual

- Código usa mistura de estilos (`@riverpod`, `StateNotifierProvider`, `ChangeNotifierProvider`, `StateProvider`) com convivência de padrões novos e legados.
- Há duplicidade semântica de estado de localização:
  - provider legado: [location_controller.dart:7](/Users/raudineisilvapereira/dev/appdart/lib/modules/dashboard/controllers/location_controller.dart:7)
  - provider novo: [location_providers.dart:34](/Users/raudineisilvapereira/dev/appdart/lib/modules/dashboard/providers/location_providers.dart:34)
  - consumo legado no overlay: [map_controls_overlay.dart:8](/Users/raudineisilvapereira/dev/appdart/lib/ui/components/map/widgets/map_controls_overlay.dart:8)
- `geofenceControllerProvider` cria timers periódicos sem amarração explícita de descarte via `ref.onDispose`:
  - [geofence_controller.dart:37](/Users/raudineisilvapereira/dev/appdart/lib/modules/visitas/presentation/controllers/geofence_controller.dart:37)
  - [geofence_controller.dart:209](/Users/raudineisilvapereira/dev/appdart/lib/modules/visitas/presentation/controllers/geofence_controller.dart:209)

### Risco de estado

- Probabilidade média/alta de estado divergente entre fluxos de GPS (legado x novo) e risco de timers vivos fora da tela de mapa.

## 4. Análise de navegação

### Contrato vs implementação

- Contrato ativo proíbe sub-rotas do mapa e define URL canônica `/map`:
  - [arquitetura-navegacao.md:77](/Users/raudineisilvapereira/dev/appdart/docs/02_ARQUITETURA_ATIVA/arquitetura-navegacao.md:77)
- Implementação atual mantém sub-rota de edição sob `/map/publicacao/edit`:
  - [app_router.dart:99](/Users/raudineisilvapereira/dev/appdart/lib/core/router/app_router.dart:99)
  - [publicacao_pin_preview.dart:340](/Users/raudineisilvapereira/dev/appdart/lib/ui/components/map/publicacao_pin_preview.dart:340)
- Classificação de rota trata `/map/*` como L0:
  - [app_routes.dart:93](/Users/raudineisilvapereira/dev/appdart/lib/core/router/app_routes.dart:93)

### Outras violações de contrato de navegação

- Regra "Sem AppBar":
  - [agenda_month_page.dart:43](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/presentation/pages/agenda_month_page.dart:43)
  - [agenda_day_page.dart:26](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/presentation/pages/agenda_day_page.dart:26)
  - [publicacao_editor_screen.dart:67](/Users/raudineisilvapereira/dev/appdart/lib/ui/screens/publicacao_editor_screen.dart:67)
  - contrato: [arquitetura-navegacao.md:35](/Users/raudineisilvapereira/dev/appdart/docs/02_ARQUITETURA_ATIVA/arquitetura-navegacao.md:35)
- Regra "One FAB":
  - [map_controls_overlay.dart:184](/Users/raudineisilvapereira/dev/appdart/lib/ui/components/map/widgets/map_controls_overlay.dart:184)
  - [occurrence_creation_sheet.dart:653](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart:653)
  - contrato: [arquitetura-navegacao.md:40](/Users/raudineisilvapereira/dev/appdart/docs/02_ARQUITETURA_ATIVA/arquitetura-navegacao.md:40)

## 5. Persistência offline

### Pontos positivos

- Camada principal mantém SQLite (`DatabaseHelper`) e uso extensivo de `sync_status`.
- Várias rotinas adotam soft delete em tabelas principais (ex.: `drawings`, `agenda_events`).

### Achados relevantes

- Bancos locais paralelos fora do `DatabaseHelper`:
  - [visita_database_service.dart:24](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/relatorio_visita/data/visita_database_service.dart:24)
  - [marketing_case_repository_impl.dart:20](/Users/raudineisilvapereira/dev/appdart/lib/modules/marketing/data/repositories/marketing_case_repository_impl.dart:20)
- Hard delete em fluxo legado:
  - [visita_database_service.dart:118](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/relatorio_visita/data/visita_database_service.dart:118)
- Dependência de backend ainda incompleta em fluxos de publicações:
  - [map_repository.dart:49](/Users/raudineisilvapereira/dev/appdart/lib/core/data/map_repository.dart:49)
  - [map_repository.dart:283](/Users/raudineisilvapereira/dev/appdart/lib/core/data/map_repository.dart:283)
  - [public_publications_provider.dart:13](/Users/raudineisilvapereira/dev/appdart/lib/modules/public/providers/public_publications_provider.dart:13)
- Instanciação direta de serviço de upload na UI:
  - [foto_picker_widget.dart:51](/Users/raudineisilvapereira/dev/appdart/lib/modules/marketing/presentation/widgets/foto_picker_widget.dart:51)

## 6. Performance

### Riscos de performance observados

- Concentração de lógica/UI em arquivos grandes (>900 linhas) em áreas sensíveis de mapa e desenho.
- Multiplicidade de widgets interativos no overlay do mapa (incluindo múltiplos FABs).
- Polling por timers em geofence (`45s` e `15min`) sem gestão de ciclo de vida robusta.
- `flutter analyze` acusa pontos de manutenção que tendem a degradar performance no médio prazo (deprecated APIs, uso inconsistente de estado).

### Sinal prático

- Regressões em testes de fluxo de desenho indicam comportamento de sheet/estado que pode implicar custo de rebuild e inconsistência de UI:
  - [drawing_flow_widget_test.dart:168](/Users/raudineisilvapereira/dev/appdart/test/modules/drawing/drawing_flow_widget_test.dart:168)
  - [drawing_flow_widget_test.dart:335](/Users/raudineisilvapereira/dev/appdart/test/modules/drawing/drawing_flow_widget_test.dart:335)
  - [drawing_flow_widget_test.dart:473](/Users/raudineisilvapereira/dev/appdart/test/modules/drawing/drawing_flow_widget_test.dart:473)

## 7. Segurança estrutural

### Controles que permanecem

- Enforcement arquitetural ativo e executável localmente ([arch_check.sh](/Users/raudineisilvapereira/dev/appdart/tool/arch_check.sh)).
- Isolamento de `core` preservado nas regras principais.

### Exposição estrutural

- Fronteiras de bounded context com deriva não documentada (módulos adicionais fora da baseline).
- Dependências cruzadas por camada de apresentação entre módulos de domínio.
- Contratos conflitantes entre documentação ativa e comportamento testado em navegação (`/map/*`).

## 8. Riscos técnicos

| Severidade | Localização | Explicação técnica | Impacto | Probabilidade | Recomendação |
|---|---|---|---|---|---|
| CRÍTICO | [app_router.dart:99](/Users/raudineisilvapereira/dev/appdart/lib/core/router/app_router.dart:99), [arquitetura-navegacao.md:77](/Users/raudineisilvapereira/dev/appdart/docs/02_ARQUITETURA_ATIVA/arquitetura-navegacao.md:77) | Sub-rota `/map/publicacao/edit` contradiz contrato de mapa canônico sem sub-rotas. | Divergência de arquitetura e decisões inconsistentes em PR/CI. | Alta | Consolidar ADR/documento ativo único para navegação e atualizar enforcement. |
| CRÍTICO | [occurrence_controller.dart:5](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart:5), [visit_controller.dart:7](/Users/raudineisilvapereira/dev/appdart/lib/modules/visitas/presentation/controllers/visit_controller.dart:7) | Dependência cruzada por camada entre `consultoria` e `visitas` gera ciclo de módulo. | Alto risco de regressão e baixo isolamento de domínio. | Alta | Extrair contrato em `core/contracts` e remover imports de presentation entre módulos. |
| CRÍTICO | [geofence_controller.dart:37](/Users/raudineisilvapereira/dev/appdart/lib/modules/visitas/presentation/controllers/geofence_controller.dart:37), [geofence_controller.dart:209](/Users/raudineisilvapereira/dev/appdart/lib/modules/visitas/presentation/controllers/geofence_controller.dart:209) | Timers periódicos sem descarte via lifecycle de provider. | Vazamento de recursos, bateria e estado inválido. | Alta | `autoDispose` + `ref.onDispose` chamando `dispose()`. |
| ALTO | [register_golden_test.dart:8](/Users/raudineisilvapereira/dev/appdart/test/auth/register_golden_test.dart:8) | Teste depende de tema removido (`soloforte_theme.dart`). | Pipeline de qualidade quebrado. | Alta | Atualizar teste para tema vigente e estabilizar golden suite. |
| ALTO | [register_widget_test.dart:54](/Users/raudineisilvapereira/dev/appdart/test/auth/register_widget_test.dart:54), [register_flow_test.dart:154](/Users/raudineisilvapereira/dev/appdart/test/auth/register_flow_test.dart:154) | Expectativas de UI/erro não batem com comportamento atual. | Regressão funcional em cadastro. | Média/Alta | Revalidar contrato da tela de registro e ajustar testes e UX de erro. |
| ALTO | [drawing_flow_widget_test.dart:168](/Users/raudineisilvapereira/dev/appdart/test/modules/drawing/drawing_flow_widget_test.dart:168), [drawing_flow_widget_test.dart:335](/Users/raudineisilvapereira/dev/appdart/test/modules/drawing/drawing_flow_widget_test.dart:335), [drawing_flow_widget_test.dart:473](/Users/raudineisilvapereira/dev/appdart/test/modules/drawing/drawing_flow_widget_test.dart:473) | Fluxo de fechamento/reabertura de sheet de desenho regressivo. | Instabilidade de operação crítica do módulo Drawing. | Alta | Corrigir estado do sheet e reestabelecer invariantes de fluxo. |
| ALTO | [map_controls_overlay.dart:184](/Users/raudineisilvapereira/dev/appdart/lib/ui/components/map/widgets/map_controls_overlay.dart:184), [occurrence_creation_sheet.dart:653](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart:653) | Múltiplos FABs contrariando contrato "One FAB". | Navegação imprevisível e fragmentação de UX. | Alta | Unificar ações no SmartButton/overlays sem FABs adicionais. |
| ALTO | [drawing_controller.dart](/Users/raudineisilvapereira/dev/appdart/lib/modules/drawing/presentation/controllers/drawing_controller.dart), [drawing_sheet.dart](/Users/raudineisilvapereira/dev/appdart/lib/modules/drawing/presentation/widgets/drawing_sheet.dart) | Regressão de tamanho/complexidade em componentes centrais. | Queda de manutenibilidade e maior risco de bugs. | Alta | Retomar decomposição por serviços/notifiers focados. |
| MÉDIO | [location_controller.dart:7](/Users/raudineisilvapereira/dev/appdart/lib/modules/dashboard/controllers/location_controller.dart:7), [location_providers.dart:34](/Users/raudineisilvapereira/dev/appdart/lib/modules/dashboard/providers/location_providers.dart:34) | Dupla fonte de verdade para estado de localização. | Comportamento incoerente no mapa. | Média | Consolidar em um único fluxo de localização e remover legado. |
| MÉDIO | [agenda_repository.dart:56](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/data/repositories/agenda_repository.dart:56), [agenda_provider.dart:377](/Users/raudineisilvapereira/dev/appdart/lib/modules/agenda/presentation/providers/agenda_provider.dart:377) | Contrato de repositório não aplicado de ponta a ponta. | Menor testabilidade e desacoplamento. | Média | Provider tipado por interface + implementação explícita. |
| MÉDIO | [visita_database_service.dart:24](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/relatorio_visita/data/visita_database_service.dart:24), [visita_database_service.dart:118](/Users/raudineisilvapereira/dev/appdart/lib/modules/consultoria/relatorio_visita/data/visita_database_service.dart:118) | Persistência paralela com hard delete em módulo legado. | Inconsistência de dados offline e sync. | Média | Migrar para DB central e política unificada de soft delete. |
| MÉDIO | [map_repository.dart:283](/Users/raudineisilvapereira/dev/appdart/lib/core/data/map_repository.dart:283), [public_publications_provider.dart:13](/Users/raudineisilvapereira/dev/appdart/lib/modules/public/providers/public_publications_provider.dart:13) | Fluxo de publicações ainda placeholder (`return []`). | Funcionalidade incompleta em produção. | Média | Concluir integração backend + cache/sync canônico. |

## 9. Recomendações estratégicas

1. Congelar um contrato único de navegação (`/map` + exceções reais), reconciliando documento ativo, router e testes.
2. Eliminar acoplamentos cruzados `consultoria <-> visitas` por meio de interfaces de domínio e adapters.
3. Fechar o ciclo de vida de providers com timers/streams (especialmente geofence).
4. Reestabelecer gate de qualidade: corrigir 8 testes com erro e warnings estruturais de `flutter analyze`.
5. Rebaixar complexidade de `drawing_controller` e `drawing_sheet` com decomposição incremental.
6. Consolidar localização em uma única implementação Riverpod.
7. Unificar persistência local: evitar bancos paralelos fora de `DatabaseHelper` para fluxos de domínio principal.
8. Atualizar baseline e bounded contexts para refletir os módulos realmente ativos ou remover módulos não-canônicos.
9. Remover placeholder de publicações (`return []`) e concluir integração remota com fallback offline consistente.
10. Reduzir dívida técnica rastreável (TODOs) com backlog priorizado por risco operacional.

## 10. Score final de engenharia

### Score atual (árvore de trabalho auditada)

**72 / 100**

### Justificativa do score

- **+** enforcement estrutural principal ainda passa.
- **+** base modular e offline-first seguem presentes.
- **-** 8 erros de teste ativos (qualidade de release comprometida).
- **-** conflitos de contrato em navegação e bounded contexts.
- **-** regressão de complexidade em arquivos críticos.
- **-** riscos de lifecycle e estado (timers/providers e duplicidade de localização).

### Classificação final

**Nível:** aceitável para desenvolvimento interno, **não ideal para baseline congelada** sem plano de correção curto.

