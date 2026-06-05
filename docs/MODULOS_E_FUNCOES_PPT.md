# SoloForte App — Módulos e Funções (roteiro estilo PPT)

> Objetivo: servir como base direta para um PowerPoint/Google Slides.
> Foco: módulos (`lib/modules/*`) + infraestrutura transversal (`lib/core`, `lib/app`, `lib/ui`) e principais “pontos de entrada” (funções/métodos públicos mais relevantes).

---

## Slide 1 — Visão geral do app

- Stack: Flutter + Riverpod + GoRouter + SQLite (sqflite) + Supabase.
- Estratégia de arquitetura (predominante): módulos por feature, com separação `data/`, `domain/`, `presentation/` e `infra/` quando aplicável.
- Rotas e navegação: `lib/core/router/*`.
- Sincronização: orquestrada por `lib/core/services/sync_orchestrator.dart` e módulos registrados em `lib/app/sync_registration.dart`.

---

## Slide 2 — Boot e composição do app

**Arquivo:** `lib/main.dart`

- Função principal: `Future<void> main()`
  - Inicialização dentro de `runZonedGuarded` (evita “zone mismatch”).
  - `WidgetsFlutterBinding.ensureInitialized()`
  - Splash “de boot” e fallback de erro (`_BootSplashApp`, `_BootErrorApp`).
  - Inicialização de configs, DB, preferências, Supabase, providers e overrides.
- Ponto importante de integração: `ProviderScope(overrides: [...])`
  - Conecta contratos (interfaces em `core/contracts`) às implementações concretas dos módulos.

---

## Slide 3 — Navegação e rotas

**Arquivos:** `lib/core/router/app_router.dart`, `lib/core/router/app_routes.dart`, `lib/core/router/router_notifier.dart`

- `GoRouter router(Ref ref)` define:
  - `initialLocation: AppRoutes.publicMap`
  - Regras de `redirect` (público vs autenticado, recovery, etc.)
  - `ShellRoute` e rotas de módulos.
- `AppRoutes`:
  - Rotas públicas: `/public-map`, `/login`, `/register`, `/recover-password`, `/reset-password`
  - Rotas privadas L0/L1/L2+: `/map`, `/settings`, `/agenda`, `/clima`, `/carteira`, `/feedback`, `/consultoria/*`, `/planos/*`
  - Funções de path: `reportDetail(id)`, `clientDetail(id)`, `farmDetail(...)`, `fieldDetail(...)`, `carteiraCliente(clienteId)`
  - Nível determinístico: `RouteLevel getLevel(String path)` e `bool canOpenSideMenu(String path)`
- `RouterNotifier`:
  - Ponte entre sessão (`SessionController`) e `GoRouter.refreshListenable`

---

## Slide 4 — Contratos (desacoplamento entre módulos)

**Pasta:** `lib/core/contracts/`

Ideia: módulos dependem de interfaces/contratos, e `main.dart` injeta implementações.

Exemplos (usados no boot via overrides):
- Cliente/Fazenda/Talhão lookup: `IClientLookup`, `IFarmLookup`, `IFieldLookup`, `IFieldLookupGeofence`
- Ponte com Agenda e sessões: `IAgendaSessionBridge`, `IAgendaObservable`
- Visitas: `IVisitSessionLookup`, `IVisitClientLookup`
- Ocorrências: `IOccurrenceRead`
- Relatórios: `IReportWriter`
- Localização do usuário: `IUserLocationLookup`
- Agenda AI: `IAgendaAiLauncher`

---

## Slide 5 — Sincronização (visão transversal)

**Arquivos:** `lib/core/services/sync_orchestrator.dart`, `lib/app/sync_registration.dart`

- Interface: `abstract class SyncModule { String get name; Future<void> sync(); }`
- Orquestrador: `class SyncOrchestrator extends ChangeNotifier`
  - Registro: `registerModule(SyncModule module)`
  - Execução: `Future<void> triggerSync(SyncPriority priority)`
  - Observadores:
    - Conectividade → `triggerSync(SyncPriority.normal)`
    - Timer periódico (15 min) → `triggerSync(SyncPriority.background)`
- Registro de módulos concretos em `sync_registration.dart` (exemplos):
  - Consultoria (agronomic), Drawing, Ocorrências, Visitas, Agenda

---

## Slide 6 — Sessão e autenticação (visão transversal)

**Pasta:** `lib/core/session/`

- `SessionController` (Riverpod) centraliza:
  - Estado de autenticação / recovery
  - Dados básicos do usuário e transições relevantes para o router

**Módulo Auth:** `lib/modules/auth/`

- Telas:
  - `RecoverPasswordPage`, `RegisterPage`, `ResetPasswordPage`
- Serviços:
  - `AuthService` (e `auth_service.g.dart`)
- Utilitários:
  - `auth_validators.dart`
  - `profile_avatar_picker.dart`

---

## Slide 7 — Módulo: Map (Mapa)

**Pasta:** `lib/modules/map/`

Papel: UI/estado do mapa e componentes de visita “ativa”.

Principais peças:
- `domain/field_map_adapter.dart`, `domain/field_map_entity.dart`
- Providers:
  - `map_location_mode_provider.dart`
  - `visit_completion_observer.dart` (observa conclusão de visita e dispara integrações)
- Widgets:
  - `visit_active_card.dart`
  - `visit_sheet.dart`

---

## Slide 8 — Módulo: Visitas

**Pasta:** `lib/modules/visitas/`

Papel: sessões de visita, estatísticas e sincronização.

Principais classes/funções (exemplos):
- `VisitRepository` (`data/repositories/visit_repository.dart`)
  - `getActiveSession()`
  - `getById(sessionId)`
  - `saveSession(session)`
  - `updateArea(sessionId, newAreaId)`
  - `endSession(sessionId, endTime)`
  - `getDashboardStats()`
  - `getVisitStats(start, end)`
  - `getHistory(start/end + filtros)`
- Sincronização:
  - `VisitSyncService` (`data/repositories/visit_sync_service.dart`)
- Controllers:
  - `geofence_controller.dart`
  - `visit_controller.dart`
  - `visit_stats_controller.dart`

---

## Slide 9 — Módulo: Agenda

**Pasta:** `lib/modules/agenda/`

Papel: calendário/eventos/sessões de visita vinculadas.

Domínio:
- Entidades: `Event`, `EventRecurrence`, `Visit`, `VisitSession`
- Enums: `AgendaView`, `EventStatus`, `EventType`, `RecurrencePattern`
- Regras: `event_rules.dart`
- Contrato: `IAgendaRepository` (`domain/repositories/i_agenda_repository.dart`)
  - Eventos: `saveEvent`, `updateEvent`, `getEventById`, `getEventBySessionId`, `getEventsByDateRange`, `getEventsByDay`, `getPendingSyncEvents`, `markEventAsSynced`, `deleteEvent`
  - Sessões: `saveSession`, `updateSession`, `getSessionById`, `getSessionsByEventId`, `getActiveSessions`

Data/Infra:
- Implementação: `AgendaRepository` (`data/repositories/agenda_repository.dart`)
- Serviços:
  - `AgendaSyncService` (`data/services/agenda_sync_service.dart`)
  - `AgendaNotificationService` (`data/services/agenda_notification_service.dart`)

Presentation:
- Providers e telas em `presentation/*` (ex.: `presentation/providers/agenda_provider.dart`)

---

## Slide 10 — Módulo: Agenda AI

**Pasta:** `lib/modules/agenda_ai/`

Papel: recomendações determinísticas para agenda/visitas (sem “LLM online”).

Principais peças:
- Entidades: `VisitRecommendation`, `VisitRecommendationContext`, `VisitRecommendationPolicy`
- Engine:
  - `IVisitRecommendationEngine`
  - `DeterministicVisitRecommendationEngine`
- Integração: `AgendaAiLauncherAdapter` (`infra/agenda_ai_launcher_adapter.dart`)
- UI: `AgendaAiSheet`

---

## Slide 11 — Módulo: Clima

**Pasta:** `lib/modules/clima/`

Papel: clima atual, previsões e alertas.

Domínio:
- Entidades: `ClimaAtual`, `PrevisaoHoraria`, `PrevisaoDiaria`, `AlertaMeteorologico`
- Contrato: `IClimaRepository`
  - `getClimaAtual(lat/lon)`
  - `getPrevisaoHoraria(lat/lon, horas=48)`
  - `getPrevisaoSemanal(lat/lon, dias=7)`
  - `getAlertas(lat/lon)`

Data:
- Datasources: `OpenWeatherRemoteDatasource`, `GoogleWeatherRemoteDatasource`, `ClimaLocalDatasource`
- Repositório: `ClimaRepositoryImpl`

Presentation:
- `ClimaScreen`
- `clima_providers.dart`
- Widgets: ex. `clima_charts.dart`

---

## Slide 12 — Módulo: Carteira

**Pasta:** `lib/modules/carteira/`

Papel: categorias/metas/safras/lançamentos e “oportunidades”.

Domínio:
- Entidades: `CategoriaGlobal`, `ClienteCategoria`, `CarteiraSafra`, `CarteiraMeta`, `CarteiraLancamento`
- Enums: `UnidadeCategoria`
- Contrato: `ICarteiraRepository`
  - Categorias: `getCategorias`, `saveCategoria`, `updateCategoria`, `desativarCategoria`
  - ClienteCategoria: `getCategoriasDoCliente`, `getTodosRegistros`, `upsertClienteCategoria`, `seedCategoriasIniciais`
  - Config: `getValorGrao`, `setValorGrao`
  - Safras: `getSafras`, `getSafraAtiva`, `saveSafra`, `ativarSafra`
  - Metas: `getMetasBySafra`, `saveMeta`, `updateMeta`
  - Lançamentos: `getLancamentos(...)`, `saveLancamento`, `deleteLancamento`
  - Cálculos: `getRealizadoBySafraCategoria`, `getRealizadoByClienteCategoriaSafra`

Presentation:
- `CarteiraScreen`, `CarteiraClienteScreen`, `OportunidadesDetalheScreen`
- Providers: `carteira_providers.dart`

---

## Slide 13 — Módulo: Consultoria (visão macro)

**Pasta:** `lib/modules/consultoria/`

Subdomínios principais:
- `clients/` (clientes, fazendas e talhões)
- `fields/` (talhões e integrações geofence/lookup)
- `occurrences/` (ocorrências técnicas)
- `relatorios/` (relatórios e PDFs)
- `publicacoes/` (conteúdo técnico/publicações)
- `relatorio_visita/` (rascunhos, imagens e persistência local)
- `quick_photo/` (captura/edição rápida de fotos e anotações)
- Serviços transversais: `services/agronomic_sync_service.dart`, `services/talhao_map_adapter.dart`

---

## Slide 14 — Consultoria: Clients / Farms / Fields

**Pasta:** `lib/modules/consultoria/clients/`

- Repositório (SQLite): `clients_repository.dart`
  - Exemplos de métodos: `getClients()`, `getClientById(id)`, `saveClient(...)`, `updateClient(...)`, `deleteClient(id)`, `getCulturas(clientId)`
- Domínio:
  - `client.dart`, `client_cultura.dart`, `agronomic_models.dart`
  - Enum `CulturaTipo`
- Infra/adapters:
  - `ClientLookupAdapter`, `FarmLookupAdapter`, `VisitClientLookupAdapter`
- Telas:
  - `ClientListScreen`, `ClientDetailScreen`, `ClientFormScreen`
  - `FarmDetailScreen`, `FieldDetailScreen`

**Pasta:** `lib/modules/consultoria/fields/`
- Repositório: `field_repository.dart`
- Integração geofence: `FieldLookupGeofenceAdapter`

---

## Slide 15 — Consultoria: Ocorrências

**Pasta:** `lib/modules/consultoria/occurrences/`

- Domínio: `Occurrence`
- Data:
  - `OccurrenceRepository`
  - `OccurrenceSyncService`
- Infra:
  - `OccurrenceReadAdapter`
- Presentation:
  - `OccurrenceController`
  - Sheets e widgets: criação, filtros, detalhes, seleção de cliente, etc.

---

## Slide 16 — Consultoria: Relatórios

**Pasta:** `lib/modules/consultoria/relatorios/`

Domínio:
- Entidade: `Relatorio`
- Modelos: `RelatorioStatus`, `RelatorioTecnico`, `VisitSessionSnapshot`
- Contratos:
  - `IReportRepository`
  - `IRelatorioRepository`

Infra/Data:
- Persistência: `relatorio_table.dart`, implementações `*_repository_impl.dart`
- Escrita: `ReportWriterAdapter` (injeta `IReportWriter` no app)
- PDF: `RelatorioPdfService`

Use cases:
- `GenerateRelatorioUseCase`
- `PublishRelatorioUseCase`

UI:
- Lista/detalhe/form: `RelatoriosListScreen`, `RelatorioDetailScreen`, `RelatorioFormScreen`, pages/providers associados

---

## Slide 17 — Consultoria: Publicações e Quick Photo

**Publicações (`publicacoes/`)**
- Repositório: `IPublicacaoRepository` + `PublicacaoRepositoryImpl`
- Use case: `CreatePublicacaoUseCase`
- UI: listagem, detalhe e formulário
- Providers: `publicacao_providers.dart`

**Quick Photo (`quick_photo/`)**
- Repositório: `QuickPhotoRepository`
- Fluxo: `quick_photo_flow.dart`
- Editor: `photo_editor_screen.dart`
- Widgets: `annotation_canvas.dart`, `annotation_toolbar.dart`

---

## Slide 18 — Módulo: Drawing (desenho/área/geometria)

**Pasta:** `lib/modules/drawing/`

Papel: desenho de áreas/feições, histórico e sincronização.

Domínio:
- Modelos/estado: `drawing_models.dart`, `drawing_state.dart`, `drawing_history.dart`
- Utils: `drawing_utils.dart`
- Contrato: `IDrawingRepository`
  - `saveFeature`, `deleteFeature`, `getAllFeatures`, `sync`, `markAllForSync`
- Serviços:
  - `async_geometry_service.dart`
  - `drawing_boolean_ops_service.dart`

Data:
- Stores: `drawing_local_store.dart`, `drawing_remote_store.dart`
- Sync: `drawing_sync_service.dart`
- Repo: `drawing_repository.dart`

Presentation:
- Providers: `drawing_provider.dart`
- Controllers: `drawing_controller.dart`, etc.

---

## Slide 19 — Módulo: Marketing

**Pasta:** `lib/modules/marketing/`

Papel: “cases” de marketing, avaliação/ROI, fotos e sync.

Domínio:
- Entidades: `MarketingCase`, `AvaliacaoBloco`, `AvaliacaoLado`, `RoiBloco`
- Enums: `AvaliacaoLayout`, `CaseTipo`, `MarketingCaseStatus`, `PlanoMarketing`, `ProdutividadeUnidade`

Data:
- Repositório: `MarketingCaseRepositoryImpl` (contrato `IMarketingCaseRepository`)
- Serviços: `MarketingPhotoService`, `MarketingSyncService`

Presentation:
- Providers: `marketing_providers.dart`
- UI: `NovoCaseSheet` + telas/widgets do módulo

---

## Slide 20 — Módulo: NDVI

**Pasta:** `lib/modules/ndvi/`

Papel: imagens NDVI (local/remoto) e visualização por talhão/data.

Data:
- Datasources: `ndvi_local_datasource.dart`, `ndvi_remote_datasource.dart`
- Model: `ndvi_image_model.dart`
- Repositório: `ndvi_repository_impl.dart` (contrato `i_ndvi_repository.dart`)

Domínio:
- Entidade: `NdviImage`

Presentation:
- Providers: `ndvi_providers.dart`, `ndvi_date_nav_provider.dart`
- Widget: `ndvi_talhao_sheet.dart`

---

## Slide 21 — Módulo: Feedback

**Pasta:** `lib/modules/feedback/`

Papel: coleta e exibição de feedback/estatísticas (Supabase).

Domínio:
- Entidades: `FeedbackStats`, `FeedbackType`
- Contrato: `IFeedbackRepository`

Data:
- `SupabaseFeedbackRepository`

Presentation:
- `FeedbackController` + `FeedbackState`
- `FeedbackScreen`
- Widgets: `feedback_stats_card.dart`

---

## Slide 22 — Módulo: Planos (assinatura/pagamento/referral)

**Pasta:** `lib/modules/planos/`

Domínio:
- Entidades: `UserPlan`, `Referral`, `ReferralCode`
- Enums: `PlanoOrigem`, `PlanoTipo`, `ReferralStatus`

Data/Serviços:
- Repositório: `PlanoRepositoryImpl` (contrato `IPlanoRepository`)
- Integrações: `MercadoPagoService`, `ReferralService`

UI:
- `MeusPlanos/MeuPlano`, `Pagamento`, `Confirmacao`, `Indicacoes` (screens)
- Providers: `plano_providers.dart`

---

## Slide 23 — Módulo: Settings (perfil/tema/config)

**Pasta:** `lib/modules/settings/`

Domínio:
- `UserProfile`
- Contrato: `IUserProfileRepository`
- `settings_models.dart`

Data:
- `UserProfileRepositoryImpl`
- `SettingsRepository`
- Auditoria: `user_profile_audit_entry.dart`

Presentation:
- Providers: `settings_providers.dart`, `user_profile_provider.dart`
- Telas: `SettingsScreen`, `EditProfileScreen`
- Tema: `presentation/theme/app_themes.dart`
- Widgets: `audit_trail_widget.dart`, `profile_field_tile.dart`

---

## Slide 24 — Módulo: Dashboard / Operação / Public

**Dashboard (`lib/modules/dashboard/`)**
- `LocationController`, `LocationService`, `LocationState`
- Adapter: `LocationLookupAdapter` (usado para `IUserLocationLookup` no boot)

**Operação (`lib/modules/operacao/`)**
- Entidade: `GeofenceState`
- Controller: `GeofenceController`
- Widget: `VisitSheet`

**Public (`lib/modules/public/`)**
- Providers: `map_style_provider.dart`, `public_location_provider.dart`, `public_publications_provider.dart`

---

## Slide 25 — Infra e utilitários transversais (core/)

**DB & Preferences**
- `DatabaseHelper` (`core/database/database_helper.dart`)
- `PreferencesService` (`core/infra/preferences_service.dart`)

**Permissões**
- Contrato/impl: `IService` + `PermissionServiceImpl`
- Gate: `LocationPermissionGate`

**Conectividade**
- `ConnectivityService` + `connectivity_provider.dart`

**Templates HTML (renderizadores)**
- `core/html_templates/*_html_renderer.dart`
- Uso típico: renderização de relatórios/ocorrências/marketing/visita em HTML/WebView

---

## Slide 26 — UI compartilhada (ui/)

**Pasta:** `lib/ui/`

Componentes e temas reutilizáveis:
- `ui/theme/*` (ex.: `premium/premium_app_theme.dart`)
- `ui/components/*` (widgets genéricos do app)
- Helpers e constants: `ui/helpers/*`, `ui/constants/*`

---

## Slide 27 — “Mapa de dependências” (como as peças se conectam)

- `main.dart` faz o “wiring”:
  - `core/contracts/*` → implementações em `modules/*/infra` ou `modules/*/data`
- `core/router/*` controla acesso por autenticação + níveis (L0/L1/L2+)
- `core/services/sync_orchestrator.dart` coordena `SyncModule`s dos features
- Features consumem DB/Supabase via repositórios e sincronizam via serviços

---

## Slide 28 — Próximos passos (para virar um PPT real)

- Definir público-alvo: time técnico vs produto vs onboarding.
- Escolher nível de detalhe:
  - “Executivo” (1 slide por módulo)
  - “Técnico” (1–3 slides por módulo: domínio, dados, UI)
- Se quiser, eu posso:
  - gerar um `.pptx` automaticamente a partir deste roteiro (com layout/tema),
  - ou criar um “inventário completo” (lista de todas as classes/enum/métodos públicos por arquivo).

