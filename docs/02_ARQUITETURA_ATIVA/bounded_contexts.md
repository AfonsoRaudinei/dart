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

### `operacao`
**Natureza:** Execução de visitas  
**Responsabilidade:** Registro e condução de visitas técnicas em campo  
**Dependências permitidas:** `Agenda`  
**Regra:** Pode depender de `Agenda`, mas não o contrário  

---

### `visitas/`
**Natureza:** Execução de sessão de visita técnica em campo  
**Responsabilidade:** Ciclo check-in → check-out, geofencing, estatísticas, sync  
**Entidade central:** `VisitSession`  
**ADR:** ADR-023  
**Contratos em core/contracts/:** `IVisitSessionLookup`, `IVisitClientLookup`  
**Regra:** NÃO depende de `consultoria/` nem de `drawing/`  
**Ponto cego CI:** violações internas em `visit_controller` e `geofence_controller`
são dívida técnica registrada em ADR-023 seção 9 (DT-023-3, DT-023-4)  

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
**Regra:** NÃO depende de nenhum módulo de domínio (`consultoria`, `operacao`, `drawing`, `agenda`, `marketing`)  
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
| `operacao` | `consultoria` | ✅ PERMITIDO (dependência semântica válida) |
| `map` | `agenda` / `drawing` / `consultoria` / `operacao` | ✅ PERMITIDO |
| `consultoria` | `core/contracts` | ✅ PERMITIDO |
| `visitas` | `core/contracts` | ✅ PERMITIDO |
| `agenda/` | `visitas/` | ✅ PERMITIDO (StartEventUseCase) |
| `operacao/` | `visitas/` | ✅ PERMITIDO |
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
