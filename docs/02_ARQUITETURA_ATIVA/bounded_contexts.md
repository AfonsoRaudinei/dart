# SoloForte — Bounded Contexts Oficiais

**Versão:** v1.1  
**Referência:** `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` — Seção 4  
**Status:** ATIVO — CONTRATO VIGENTE  

---

## Mapa de Bounded Contexts

```
┌─────────────────────────────────────────────────────────────────┐
│                          lib/                                    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  core/  (infraestrutura pura)                            │   │
│  │  database/ · network/ · logger/ · router/¹               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                            │ (apenas ↓)                         │
│  ┌──────────┐  ┌────────┐  ┌───────────┐  ┌─────────────────┐  │
│  │  Agenda  │  │  Map   │  │  Drawing  │  │  Consultoria    │  │
│  └──────────┘  └────────┘  └───────────┘  └─────────────────┘  │
│                   │ ↘ ↙ ↙ ↙                                     │
│           ┌──────────────┐   ┌──────────┐   ┌──────────────┐   ┌──────────────┐  │
│           │   Operacao   │   │ Settings │   │    Auth      │   │   Planos     │  │
│           └──────────────┘   └──────────┘   └──────────────┘   └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘

¹ app_router.dart — única exceção autorizada (ADR implícito, seção 3)
```

---

## Definição de Cada Bounded Context

### `core/`
**Natureza:** Infraestrutura horizontal pura  
**Responsabilidade:** Serviços agnósticos de domínio (database, network, logger, router)  
**Regra:** NÃO conhece nenhum módulo de domínio  
**Exceção autorizada:** `app_router.dart` — ponto de composição de rotas (único arquivo de `core/` autorizado a importar `modules/`)  

### `core/contracts/`
**Natureza:** Zona neutra de contratos inter-módulos  
**Responsabilidade:** DTOs e interfaces de fronteira para evitar import cross-module em presentation  
**Regra:** NÃO importa `modules/`  
**Contratos ativos:** `IClientLookup` (ADR-015), `IVisitSessionLookup` (ADR-020), `IVisitClientLookup` (ADR-020)  

---

### `map`
**Natureza:** Projeção agregadora  
**Responsabilidade:** Orquestração visual do mapa e integração de domínios no contexto espacial  
**Dependências permitidas:** `Agenda`, `Operacao`, `Drawing`, `Consultoria`, `Visitas` (via contratos), `Planos`  
**ADR:** ADR-025  
**Enforcement:** REGRA-MAP-1 em `arch_check.sh`  
**Regra:** Pode depender de outros módulos, mas **ninguém depende de `map/`**  
**Exceções temporárias (DT-025-4 — Fase 3 pending):** `app_router.dart`, `main.dart`, `ui/components/map/`, `ui/screens/`  
**Dívidas ativas:** DT-025-2, DT-025-3, DT-025-4, DT-025-5, DT-025-6, DT-025-7, DT-025-8 — ver ADR-025  

---

### `drawing`
**Natureza:** Domínio geométrico isolado  
**Responsabilidade:** Criação, edição e persistência de geometrias (polígonos, pontos, linhas)  
**I/O abstraído via:** `IFilePicker`, `FilePickerAdapter`  
**DIP aplicado:** `IDrawingRepository`, `IClientsRepository`  
**Regra:** NÃO depende de `consultoria`  
**Ponte autorizada:** `ClientsRepositoryAdapter` em `drawing/infra/` — única ponte para dados de clientes  

---

### `agenda`
**Natureza:** Domínio de planejamento  
**Responsabilidade:** Ciclo de vida de eventos agronômicos (agendado → em andamento → concluído)  
**Use cases formais:** `CreateEventUseCase`, `StartEventUseCase`, `FinalizeEventUseCase`, `CompleteEventUseCase`, `CancelEventUseCase`, `UpdateEventUseCase`  
**DIP aplicado:** `IAgendaNotificationService`  
**Regra:** NÃO depende de `consultoria`  

---

### `visitas/`
**Natureza:** Execução de sessão de visita técnica em campo  
**Responsabilidade:** Ciclo check-in → check-out, geofencing, estatísticas, sync  
**Entidade central:** `VisitSession`  
**ADR:** ADR-023  
**Contratos em core/contracts/:** `IVisitSessionLookup`, `IVisitClientLookup`  
**Regra:** NÃO depende de `consultoria/` nem de `drawing/`  
**Geofence:** execução foreground enquanto o mapa privado está aberto

---

### `consultoria`
**Natureza:** Conteúdo técnico e ocorrências  
**Responsabilidade:** Registro e gestão de ocorrências agronômicas  
**Regra:** NÃO depende de `drawing`  

---

### `settings` / `auth`
**Natureza:** Módulos satélite  
**Responsabilidade:** Configurações de usuário e autenticação  
**Regra:** Sem dependências cruzadas com módulos de domínio  

---

### `planos/`
**Natureza:** Módulo de monetização  
**Responsabilidade:** Gestão de planos pagos, pagamentos via Mercado Pago e sistema de indicações com upgrade automático  
**Dependências permitidas:** Supabase (remoto) — sem dependências de outros módulos  
**Regra:** NÃO depende de nenhum módulo de domínio (`consultoria`, `drawing`, `agenda`, `marketing`)
**Regra:** `marketing/` pode depender de `planos/` para verificar plano ativo  
**Regra:** `map/` pode depender de `planos/` para exibir badge no SideMenu  
**Nota:** Publicação de cases é fluxo online-only — fonte da verdade é Supabase, não SQLite  

---

## Tabela de Acoplamentos Autorizados

| De | Para | Status |
|---|---|---|
| `core/` | `modules/*` | ❌ PROIBIDO (exceto `app_router.dart`) |
| `drawing` | `consultoria` | ❌ PROIBIDO |
| `agenda` | `consultoria` | ❌ PROIBIDO |
| `consultoria` | `drawing` | ❌ PROIBIDO |
| `consultoria` | `visitas` (presentation) | ❌ PROIBIDO |
| `visitas` | `consultoria` (presentation) | ❌ PROIBIDO |
| `map` | `agenda` / `drawing` / `consultoria` | ✅ PERMITIDO |
| `consultoria` | `core/contracts` | ✅ PERMITIDO |
| `visitas` | `core/contracts` | ✅ PERMITIDO |
| `agenda/` | `visitas/` | ✅ PERMITIDO (StartEventUseCase) |
| `map/` | `visitas/` via contratos | ✅ PERMITIDO |
| `map/` | `visitas/` direto | ⚠️ A MIGRAR — DT-025-3 (ex-DT-023-5) |
| módulos externos | `map/` | ❌ PROIBIDO — REGRA-MAP-1 (ADR-025) |
| `consultoria/` | `visitas/` via contratos | ✅ PERMITIDO |
| `visitas/` | `consultoria/` | ❌ PROIBIDO — DT-023-3, DT-023-4 ativas |
| `visitas/` | `drawing/` | ❌ PROIBIDO |
| `planos/`    | qualquer módulo de domínio                          | ❌ PROIBIDO                              |
| `marketing/` | `planos/`                                           | ✅ PERMITIDO — verificação de plano      |
| `map/`       | `planos/`                                           | ✅ PERMITIDO — badge SideMenu            |

---

## Alterações Proibidas Sem ADR

- Adicionar novo bounded context
- Alterar fronteiras de acoplamento desta tabela
- Remover interface de domínio existente
- Criar dependência circular entre módulos
- Permitir que `planos/` importe módulos de domínio (proibido sem ADR)
- Remover a dependência `marketing/ → planos/` sem ADR

Qualquer alteração exige: atualização desta tabela + ADR em `02_ARQUITETURA_ATIVA/` + atualização da baseline.

---

*Referência: `01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` — Seções 3 e 4*

---

## Contextos Complementares v1.1 (Auditoria Parte 2)

## agenda

**Responsabilidade**: Planejamento e ciclo de vida de eventos agronômicos.

## auth

**Responsabilidade**: Autenticação e controle de sessão.

## consultoria

**Responsabilidade**: Gestão de ocorrências e conteúdo técnico.

## drawing

**Responsabilidade**: Geometrias e desenho técnico em mapa.

## map

**Responsabilidade**: Projeção agregadora espacial e orquestração visual.

## planos

**Responsabilidade**: Monetização, assinatura e pagamentos.

## settings

**Responsabilidade**: Configurações de usuário e preferências do app.

## visitas

**Responsabilidade**: Sessões de visita técnica (check-in/check-out e sync).

## agenda_ai

**Responsabilidade**: Sugestões inteligentes de agendamento usando IA

**Camada de Apresentação**:
- `agenda_ai_sheet.dart` e widgets de sugestão

**Camada de Domínio**:
- Entidades: `AgendaSuggestion`
- Providers: `agendaAiSuggestionsProvider`

**Dependências Permitidas**:
- ✅ `core/contracts/IAgendaSessionBridge` para consulta de slots
- ✅ `core/contracts/IClientLookup` para dados de clientes
- ❌ Import direto de `modules/agenda` e `modules/carteira`

**Contratos Expostos**:
- Nenhum (consumidor interno)

**Dívidas Técnicas Conhecidas**:
- Acoplamento lateral `agenda_ai -> agenda/carteira` detectado pela `REGRA-CROSS-MODULE-2`

## carteira

**Responsabilidade**: Gestão de carteira de clientes e oportunidades comerciais

**Documentação detalhada**: [`MODULO_CARTEIRA.md`](MODULO_CARTEIRA.md)

**Camada de Apresentação**:
- `carteira_screen.dart`, `carteira_cliente_screen.dart`, `oportunidades_detalhe_screen.dart`
- Providers: `carteira_providers.dart`

**Camada de Domínio**:
- Entidades: `CategoriaGlobal`, `CarteiraSafra`, `CarteiraMeta`, `CarteiraLancamento`, `ClienteCategoria` (legado)
- Repositório: `ICarteiraRepository` / `CarteiraRepositoryImpl`
- Lookup ADR-029: `OpportunityLookupImpl` → `IOpportunityLookup`

**Dependências Permitidas**:
- ✅ `core/contracts/IClientLookup`
- ✅ `core/contracts/IOpportunityLookup`
- ❌ Imports diretos de outros `modules/`

**Contratos Expostos**:
- `IClientLookup`
- `IOpportunityLookup`

**Dívidas Técnicas Conhecidas**:
- Nenhuma específica registrada nesta auditoria

## clima

**Responsabilidade**: Dados climaticos, overlay de radar RainViewer e apoio operacional no mapa (ADR-043)

**Camada de Apresentação**:
- `clima_screen.dart`, widgets de previsao
- `ClimaRadarLayerWidget` (overlay no FlutterMap)

**Camada de Domínio/Dados**:
- `radar_providers.dart`, `rainviewer_radar_datasource.dart`
- `IRadarOverlayController` via adapter em `infra/`

**Dependências Permitidas**:
- ✅ `core/contracts/IUserLocationLookup` quando necessário
- ✅ `core/state/map_state.dart` somente no adapter de radar (camada satelite)
- ❌ Imports diretos de outros `modules/`

**Contratos Expostos**:
- `IRadarOverlayController` (implementado em `clima/infra`)

**Dívidas Técnicas Conhecidas**:
- Nenhuma — DT-028 encerrado (radar em `clima/`, nao `ArmedMode.clima`)

## dashboard

**Responsabilidade**: Consolidação de métricas e KPIs do usuário

**Camada de Apresentação**:
- `dashboard_screen.dart` e widgets de KPI

**Camada de Domínio**:
- Entidades de métricas agregadas
- Providers de resumo

**Dependências Permitidas**:
- ✅ `core/contracts/IVisitSessionLookup`
- ✅ `core/contracts/IClientLookup`

**Contratos Expostos**:
- Nenhum

**Dívidas Técnicas Conhecidas**:
- Nenhuma específica registrada nesta auditoria

## feedback

**Responsabilidade**: Coleta de feedback de usuário e suporte

**Camada de Apresentação**:
- `feedback_screen.dart`

**Camada de Domínio**:
- Entidades de submissão
- Repositório de feedback

**Dependências Permitidas**:
- ✅ `core/utils/`
- ❌ Imports diretos de outros `modules/`

**Contratos Expostos**:
- Nenhum

**Dívidas Técnicas Conhecidas**:
- Nenhuma específica registrada nesta auditoria

## marketing

**Responsabilidade**: Cases de marketing, plano de usuário e regras de visibilidade por plano

**Camada de Apresentação**:
- telas/widgets de cases e seleção de plano

**Camada de Domínio**:
- Entidades: `MarketingCase`, `PlanoMarketing`, `UserPlan`
- Providers de cases e plano

**Dependências Permitidas**:
- ✅ `core/contracts/IClientLookup`
- ✅ `core/contracts/IFarmLookup`
- ✅ Dependência explícita `marketing -> planos` já documentada

**Contratos Expostos**:
- Pendente: `IPlanLimitsLookup` (planejado em ADR futuro)

**Dívidas Técnicas Conhecidas**:
- DT-035: `ui/components/map/widgets/isolated_marker_layers.dart` importa `PlanoMarketing` direto (ADR-035)

## ndvi

**Responsabilidade**: Análise NDVI e consumo de dados de vegetação

**Camada de Apresentação**:
- `ndvi_talhao_sheet.dart`

**Camada de Domínio**:
- Entidades e providers de NDVI
- Repositório com integração Supabase

**Dependências Permitidas**:
- ✅ `core/contracts/IFieldLookup` (ADR-022)
- ✅ `core/contracts/IFarmLookup`
- ❌ Import direto de `modules/drawing`

**Contratos Expostos**:
- Nenhum

**Dívidas Técnicas Conhecidas**:
- Acoplamento lateral `ndvi -> drawing` detectado pela `REGRA-CROSS-MODULE-2`

## public

**Responsabilidade**: Fluxos públicos e onboarding sem autenticação

**Camada de Apresentação**:
- telas públicas (onboarding, termos e afins)

**Camada de Domínio**:
- Sem domínio transacional relevante; foco em apresentação

**Dependências Permitidas**:
- ✅ `core/utils/`
- ❌ Import direto de outros `modules/`

**Contratos Expostos**:
- Nenhum

**Dívidas Técnicas Conhecidas**:
- Nenhuma específica registrada nesta auditoria

---

## Matriz de Dependências Entre Contextos

| Contexto | Depende de (via Contratos) | Expõe Contratos |
|----------|-----------------------------|-----------------|
| agenda | `IClientLookup`, `IAgendaSessionBridge` | `IAgendaObservable` |
| agenda_ai | `IAgendaSessionBridge`, `IClientLookup` | - |
| auth | - | - |
| carteira | - | `IClientLookup`, `IOpportunityLookup` |
| clima | `IUserLocationLookup` | - |
| consultoria | `IClientLookup`, `IFarmLookup`, `IFieldLookup`, `IVisitSessionLookup` | `IReportWriter` |
| dashboard | `IVisitSessionLookup`, `IClientLookup` | - |
| drawing | `IFarmLookup` | - |
| feedback | - | - |
| map | múltiplos contratos e composição | - |
| marketing | `IClientLookup`, `IFarmLookup` | *`IPlanLimitsLookup` (pendente)* |
| ndvi | `IFieldLookup`, `IFarmLookup` | - |
| planos | - | - |
| public | - | - |
| settings | - | - |
| visitas | `IClientLookup` | `IVisitSessionLookup`, `IVisitClientLookup` |

**Legenda**:
- ✅ Dependência via contrato (permitida)
- ❌ Dependência direta (violação)
- *Itálico* = contrato pendente de criação
