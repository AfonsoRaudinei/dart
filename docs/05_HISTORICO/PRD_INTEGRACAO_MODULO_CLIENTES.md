# PRD — Integração do Módulo Clientes com o Sistema SoloForte

> **Versão:** 1.1 (revisão de conformidade arquitetural)  
> **Data:** 02 de março de 2026  
> **Baseline:** v1.2 | DB Schema: v15  
> **Autor:** Engenheiro Sênior Flutter — Auditoria Sistêmica  
> **Status:** APROVADO PARA ESTUDO — Requer ADRs pré-requisitos antes de executar  
> **Revisão v1.1:** Corrigido cruzamento de bounded contexts (REGRA 2), rotas não declaradas, alterações de contrato sem ADR

---

## 1. Contexto e Motivação

O Módulo Clientes (`lib/modules/consultoria/clients/`) foi implementado com CRUD completo (Create, Read, Update, Delete), avatar via `image_picker`, sub-entidade `ClientCultura`, e integração Map-First com o módulo Drawing.

Porém, a **integração real com os demais módulos do sistema é inexistente ou contém bugs silenciosos**. Os módulos Agenda, Visitas, Relatórios, Ocorrências e Drawing possuem campos de FK para `cliente_id`, mas a UI não conecta esses módulos ao cadastro real de clientes.

Este PRD documenta **todos os gaps**, classifica por prioridade, e define workstreams com estimativas de esforço.

---

## 2. Mapa de Dependências Atual

```
                    ┌──────────────┐
                    │   clients    │
                    │  (CRUD OK)   │
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
    ┌─────▼─────┐   ┌─────▼─────┐   ┌──────▼──────┐
    │  farms     │   │  fields   │   │ client_     │
    │ (FK OK)    │   │ (FK OK)   │   │ culturas    │
    └─────┬──────┘   └───────────┘   │ (FK OK)     │
          │                          └─────────────┘
          │
    ┌─────▼──────────────────────────────────────────┐
    │           MÓDULOS DEPENDENTES                  │
    ├────────────────────────────────────────────────┤
    │ drawings      │ cliente_id existe no DB (V9)   │
    │               │ ⛔ NÃO persiste em _toRow()    │
    │               │ ⛔ NÃO lê em _fromRow()        │
    ├───────────────┼────────────────────────────────┤
    │ agenda_events │ cliente_id existe no DB (V10)   │
    │               │ ⛔ UI hardcoda 'cliente-demo'   │
    │               │ ⛔ UI hardcoda 'temp-client-id' │
    ├───────────────┼────────────────────────────────┤
    │ visit_sessions│ producer_id existe no DB (V3)   │
    │               │ 🟡 Nome legado, sem selector UI │
    ├───────────────┼────────────────────────────────┤
    │ relatórios    │ RelatorioTecnico.clientId OK     │
    │               │ 🟡 Sem filtro por cliente na UI  │
    ├───────────────┼────────────────────────────────┤
    │ occurrences   │ Ligada via visit_session_id     │
    │               │ 🟡 Sem FK direta para cliente   │
    └───────────────┴────────────────────────────────┘
```

---

## 3. Bugs Silenciosos Identificados

### BUG-1: DrawingLocalStore não persiste `cliente_id` / `fazenda_id` 🔴 CRÍTICO

**Arquivo:** `lib/modules/drawing/data/data_sources/drawing_local_store.dart`

**Problema:** O método `_toRow(DrawingFeature f)` monta o mapa para inserção no SQLite mas **omite** `cliente_id` e `fazenda_id`. O método `_fromRow(Map<String, dynamic> row)` também **não lê** esses campos. Há inclusive um comentário explícito no código:

```
// Missing fields in DB but present in model:
// operacaoId, fazendaId -> Add columns if necessary or assume null
```

As colunas existem na tabela `drawings` desde a migração V9. O `DrawingProperties` model possui os campos `clienteId` e `fazendaId`. Mas **o ciclo persist → reload perde a vinculação**.

**Impacto:** Qualquer desenho associado a um cliente via `DrawingController.setClienteAtivo()` perde a vinculação ao ser salvo e recarregado do banco.

---

### BUG-2: CreateEventDialog hardcoda `clienteId` 🔴 CRÍTICO

**Arquivo:** `lib/modules/agenda/presentation/widgets/create_event_dialog.dart`  
**Linha:** 187

```dart
clienteId: 'cliente-demo', // TODO: selecionar cliente real
```

**Impacto:** Todos os eventos criados ficam vinculados a um cliente fictício inexistente.

---

### BUG-3: VisitFormDialog hardcoda `clienteId` 🔴 CRÍTICO

**Arquivo:** `lib/modules/agenda/presentation/widgets/visit_form_dialog.dart`  
**Linha:** 155

```dart
clienteId: 'temp-client-id', // TODO: selecionar cliente
```

**Impacto:** Todas as visitas criadas via agenda ficam com FK inválida.

---

### BUG-4: DrawingController viola DIP 🟡 MÉDIO

**Arquivo:** `lib/modules/drawing/presentation/controllers/drawing_controller.dart`  
**Linhas:** 12-14

```dart
import '../../../consultoria/clients/data/clients_repository.dart';
import '../../../consultoria/clients/domain/client.dart';
import '../../../consultoria/clients/domain/agronomic_models.dart';
```

**Problema:** Import direto da implementação concreta `ClientsRepository` (camada `data/`), violando o Princípio de Inversão de Dependência. Deveria depender de uma interface/abstração.

---

### BUG-5: VisitSession usa nomenclatura legada `producerId` 🟡 MÉDIO

**Arquivo:** `lib/modules/operacao/visitas/domain/visit_session.dart`

**Problema:** O campo é `producerId` (mapeado como `producer_id` no SQLite), enquanto todos os outros módulos usam `clienteId` / `cliente_id`. Não há selector de cliente real na UI de início de visita.

---

### BUG-6: Relatorio (domain) não tem `clientId` 🟡 MÉDIO

**Arquivo:** `lib/modules/consultoria/relatorios/domain/entities/relatorio.dart`

**Problema:** A entidade de domínio `Relatorio` não tem campo `clientId`, mas o model `RelatorioTecnico` (em `models/relatorio_tecnico.dart`) possui. Inconsistência entre camadas domain/model. A UI de relatórios não filtra por cliente.

---

## 4. Schema do Banco de Dados (v15) — Referência

### Tabelas no `soloforte.db` (10 tabelas)

| Tabela | Migração | FK para Cliente |
|--------|----------|-----------------|
| `clients` | V1+V2+V15 | — (é a tabela raiz) |
| `client_culturas` | V15 | `client_id` → clients (CASCADE) |
| `farms` | V1+V2 | `cliente_id` → clients |
| `fields` | V1+V2 | `fazenda_id` → farms |
| `drawings` | V8+V9 | `cliente_id` (V9) — **não persistido** |
| `agenda_events` | V10 | `cliente_id` |
| `agenda_visit_sessions` | V10 | `evento_id` → agenda_events |
| `visit_sessions` | V3 | `producer_id` (legado) |
| `occurrences` | V4+V6+V7+V14 | — (via `visit_session_id`) |
| `visit_reports` | V4 | — (via `visit_session_id`) |

---

## 5. Rotas do Sistema — Referência Map-First

| Path | Tela | Módulo |
|------|------|--------|
| `/map` | `PrivateMapScreen` | map (raiz) |
| `/map/publicacao/edit?id=X` | `PublicacaoEditorScreen` | map |
| `/settings` | `SettingsScreen` | settings |
| `/agenda` | `AgendaMonthPage` | agenda |
| `/agenda/day?date=X` | `AgendaDayPage` | agenda |
| `/agenda/event/:id` | `AgendaEventDetailPage` | agenda |
| `/consultoria/relatorios` | `RelatoriosScreen` | consultoria |
| `/consultoria/relatorios/novo` | `ReportFormScreen` | consultoria |
| `/consultoria/relatorios/:id` | `ReportDetailScreen` | consultoria |
| `/consultoria/clientes` | `ClientListScreen` | consultoria |
| `/consultoria/clientes/novo` | `ClientFormScreen` | consultoria |
| `/consultoria/clientes/:id` | `ClientDetailScreen` | consultoria |
| `/consultoria/clientes/:id/fazendas/:farmId` | `FarmDetailScreen` | consultoria |
| `/consultoria/clientes/:id/fazendas/:farmId/talhoes/:fieldId` | `FieldDetailScreen` | consultoria |
| `/feedback` | `FeedbackScreen` | settings |
| `/planos` | `PlanosScreen` | settings |
| `/planos/meu-plano` | `MeuPlanoScreen` | settings |
| `/planos/pagamento` | `PagamentoScreen` | settings |
| `/planos/confirmacao` | `ConfirmacaoScreen` | settings |
| `/planos/indicacoes` | `IndicacoesScreen` | settings |

---

## 6. Workstreams

### WS-1: Fix DrawingLocalStore — Persistir `cliente_id` e `fazenda_id` 🔴

| Item | Detalhe |
|------|---------|
| **Prioridade** | P0 — Bug crítico |
| **Módulo** | `drawing` |
| **Bounded Context** | `drawing` |
| **Estimativa** | 2h |
| **Objetivo** | Corrigir `_toRow()` e `_fromRow()` para persistir e ler `cliente_id` e `fazenda_id` |

**Arquivos a alterar:**
- `lib/modules/drawing/data/data_sources/drawing_local_store.dart`

**Ações:**

1. No método `_toRow(DrawingFeature f)`, adicionar:
```dart
'cliente_id': f.properties.clienteId,
'fazenda_id': f.properties.fazendaId,
```

2. No método `_fromRow(Map<String, dynamic> row)`, ler:
```dart
clienteId: row['cliente_id'] as String?,
fazendaId: row['fazenda_id'] as String?,
```

3. Remover o comentário `// Missing fields in DB but present in model`

**Teste de validação:**
- Criar desenho com cliente associado via `setClienteAtivo()`
- Fechar e reabrir o app
- Verificar que o desenho mantém a vinculação ao recarregar

**Critério de aceite:**
- `_toRow()` escreve `cliente_id` e `fazenda_id`
- `_fromRow()` lê `cliente_id` e `fazenda_id`
- Ciclo persist → reload preserva a vinculação

---

### WS-2: Fix Agenda — Selector de Cliente Real 🔴

| Item | Detalhe |
|------|---------|
| **Prioridade** | P0 — Bug crítico |
| **Módulo** | `agenda` |
| **Bounded Context** | `agenda` |
| **Estimativa** | 4h |
| **Objetivo** | Substituir `clienteId` hardcoded por dropdown real de clientes |

**Arquivos a alterar:**
- `lib/modules/agenda/presentation/widgets/create_event_dialog.dart`
- `lib/modules/agenda/presentation/widgets/visit_form_dialog.dart`

**Arquivo a criar:**
- `lib/modules/agenda/presentation/widgets/client_selector_dropdown.dart`

**Ações:**

1. Criar widget `ClientSelectorDropdown` reutilizável:
```dart
class ClientSelectorDropdown extends ConsumerWidget {
  final String? selectedClientId;
  final ValueChanged<String> onChanged;
  // Usa clientsListProvider para listar clientes ativos
}
```

2. Em `CreateEventDialog` (linha 187):
   - Remover `clienteId: 'cliente-demo'`
   - Adicionar `ClientSelectorDropdown` no formulário
   - Passar o `clienteId` selecionado para o `Event`

3. Em `VisitFormDialog` (linha 155):
   - Remover `clienteId: 'temp-client-id'`
   - Adicionar `ClientSelectorDropdown` no formulário
   - Validar que um cliente foi selecionado antes de salvar

4. Opcional: pré-selecionar cliente se vier via query param

**Critério de aceite:**
- Zero strings hardcoded de `clienteId`
- Dropdown lista apenas clientes com `ativo = true`
- Validação: não permite salvar sem cliente selecionado
- Evento/Visita criados com `clienteId` real do banco

---

### WS-3: Conectar Visitas ↔ Cliente 🟡

| Item | Detalhe |
|------|---------|
| **Prioridade** | P1 |
| **Módulo** | `operacao/visitas` |
| **Bounded Context** | `operacao` |
| **Estimativa** | 5h |
| **Objetivo** | Substituir `producerId` por selector real + alinhar nomenclatura |

**Arquivos a alterar:**
- `lib/modules/operacao/visitas/domain/visit_session.dart`
- `lib/modules/operacao/visitas/data/visit_repository.dart`
- `lib/modules/operacao/visitas/presentation/` (telas de início de visita)

**Ações:**

1. **NÃO renomear** a coluna `producer_id` no banco (breaking change) — manter compatibilidade
2. No `VisitSession`, adicionar alias:
```dart
String get clienteId => producerId; // alias semântico
```
3. Na UI de início de visita, criar selector de cliente local usando `IClientLookup` de `core/contracts/` (mesma interface do WS-2, mas widget próprio em `operacao/` — **não importar** `ClientSelectorDropdown` de `agenda/`)
4. Ao iniciar visita pelo Hub do Cliente (WS-4), pré-preencher o `producerId` com o `clienteId`

**⚠️ Nota:** `operacao → consultoria` é ✅ PERMITIDO pelas enforcement-rules. Porém, para manter DIP, usar `IClientLookup` de `core/contracts/` é preferível.

**Critério de aceite:**
- Visita não inicia sem cliente selecionado
- `producer_id` no banco recebe UUID válido de cliente real
- Compatibilidade retroativa mantida (sem ALTER TABLE)
- Zero imports de `consultoria/` em `operacao/` (via interface)

---

### WS-4: Hub do Cliente — Tela de Detalhe Expandida 🟡

| Item | Detalhe |
|------|---------|
| **Prioridade** | P1 |
| **Módulo** | `consultoria/clients` |
| **Bounded Context** | `consultoria` |
| **Estimativa** | 6h |
| **Objetivo** | Transformar `ClientDetailScreen` em Hub com contadores dinâmicos e atalhos |

**Arquivos a alterar:**
- `lib/modules/consultoria/clients/presentation/screens/client_detail_screen.dart`

**Arquivos a criar:**
- `lib/modules/consultoria/clients/presentation/widgets/client_hub_section.dart`
- `lib/modules/consultoria/clients/data/client_stats_service.dart`

**Layout do Hub:**

```
┌──────────────────────────────────────┐
│  👤 Avatar + Nome + Status           │
├──────────────────────────────────────┤
│  📊 Contadores Dinâmicos            │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │  3   │ │  12  │ │  2   │        │
│  │Visitas│ │Ocorr.│ │Relat.│        │
│  └──────┘ └──────┘ └──────┘        │
│  ┌──────┐ ┌──────┐                  │
│  │  5   │ │  8   │                  │
│  │Desenhos│ │Eventos│               │
│  └──────┘ └──────┘                  │
├──────────────────────────────────────┤
│  🏠 Fazendas (existente)            │
├──────────────────────────────────────┤
│  🌾 Culturas (existente)            │
├──────────────────────────────────────┤
│  📅 Próximos Eventos (top 3)        │
│  ├─ Visita agendada — 05/03/2026    │
│  ├─ Monitoramento — 10/03/2026      │
│  └─ Ver todos →                     │
├──────────────────────────────────────┤
│  📋 Últimas Visitas (top 3)         │
│  ├─ Visita #42 — 28/02/2026 ✅      │
│  ├─ Visita #41 — 15/02/2026 ✅      │
│  └─ Ver todas →                     │
├──────────────────────────────────────┤
│  ⚡ Ações Rápidas                   │
│  [+ Evento] [+ Visita] [+ Desenho]  │
│  [📊 Relatório] [📍 Ver no Mapa]    │
└──────────────────────────────────────┘
```

**Queries SQL para contadores (`ClientStatsService`):**

```sql
-- Visitas do cliente
SELECT COUNT(*) FROM visit_sessions WHERE producer_id = ?;

-- Ocorrências (via visit_sessions)
SELECT COUNT(*) FROM occurrences o
  INNER JOIN visit_sessions v ON o.visit_session_id = v.id
  WHERE v.producer_id = ?;

-- Desenhos do cliente
SELECT COUNT(*) FROM drawings WHERE cliente_id = ? AND ativo = 1;

-- Eventos agendados
SELECT COUNT(*) FROM agenda_events WHERE cliente_id = ?;

-- Relatórios
-- (depende de ter clientId na tabela de relatórios — ver WS-5)
```

**Navegação dos atalhos (Map-First):**

```dart
// + Evento → Agenda com cliente pré-selecionado
context.go('/agenda?clienteId=$clienteId');

// + Visita → Iniciar visita com cliente
context.go('/map?modo=visita&clienteId=$clienteId');

// + Desenho → Modo desenho com cliente
context.go('/map?modo=desenho&clienteId=$clienteId');

// Ver no Mapa → Centralizar no cliente (fazenda principal)
context.go('/map?focusClienteId=$clienteId');

// Relatório → Lista filtrada
context.go('/consultoria/relatorios?clienteId=$clienteId');
```

**Critério de aceite:**
- Contadores exibem dados reais (não mocked)
- Atalhos navegam com `context.go()` (Map-First)
- Seções de "Próximos Eventos" e "Últimas Visitas" carregam de forma lazy
- Performance: queries com índice, < 100ms em 1000 registros

---

### WS-5: Conectar Relatórios ↔ Cliente 🟡

| Item | Detalhe |
|------|---------|
| **Prioridade** | P1 |
| **Módulo** | `consultoria/relatorios` |
| **Bounded Context** | `consultoria` |
| **Estimativa** | 4h (inclui ADR + migration) |
| **Objetivo** | Permitir filtrar relatórios por cliente e exibir no Hub |
| **⚠️ Pré-requisito** | **ADR-017** (alteração de contrato de domínio) + **ADR-016** (rota) |

**⚠️ ALTERAÇÃO DE CONTRATO DE DOMÍNIO:**

Adicionar `clientId` à entidade `Relatorio` é uma **alteração de contrato**. Pela REGRA OBRIGATÓRIA DE PROCESSO, isso exige:

```
[x] Módulo afetado: consultoria/relatorios
[x] Altera contrato de interface: SIM → ADR-017 obrigatório
[x] Altera fronteira entre módulos: NÃO
[x] Impacto retroativo: registros antigos terão clientId = NULL (nullable)
[x] Testes quebrando: verificar serialização/fromMap/toMap
[x] Baseline atualizada: SIM, após merge
```

**Arquivos a alterar:**
- `lib/modules/consultoria/relatorios/domain/entities/relatorio.dart` — adicionar campo `clientId`
- `lib/modules/consultoria/relatorios/` (repository/provider) — adicionar filtro por `clienteId`
- `lib/modules/consultoria/relatorios/presentation/screens/relatorios_screen.dart` — ler query param `clienteId`
- `lib/core/database/database_helper.dart` — migration V16: `ALTER TABLE` para adicionar coluna `client_id` em tabela de relatórios (se necessário)

**Ações:**

1. Criar **ADR-017** documentando:
   - Motivo da adição de `clientId`
   - Campo nullable (`String?`) — compatibilidade retroativa
   - Registros antigos mantêm `clientId = null`
   - `RelatorioTecnico` (model) já possui `clientId` — alinhamento domain ↔ model

2. Adicionar `clientId` à entidade `Relatorio` (domain):
```dart
final String? clientId; // nullable — retrocompatível
```

3. Atualizar `fromMap()` / `toMap()` / `copyWith()` para incluir `clientId`

4. Se necessário, migration V16:
```sql
ALTER TABLE relatorios ADD COLUMN client_id TEXT;
```

5. Na `RelatoriosScreen`, ler query param (requer ADR-016 para rota):
```dart
final clienteId = GoRouterState.of(context).uri.queryParameters['clienteId'];
```

6. Se `clienteId` presente, filtrar lista:
```sql
SELECT * FROM relatorios WHERE client_id = ? ORDER BY created_at DESC;
```

7. Exibir badge/chip com nome do cliente quando filtro ativo (usar `IClientLookup` de `core/contracts/`)

**Critério de aceite:**
- ADR-017 criado e aprovado antes de implementação
- Rota `/consultoria/relatorios?clienteId=X` filtra corretamente (declarada em ADR-016)
- Sem query param, exibe todos os relatórios (comportamento atual)
- Registros antigos sem `clientId` continuam funcionando
- `fromMap` / `toMap` / `copyWith` atualizados
- Nome do cliente aparece como filtro ativo na UI

---

### WS-6: Normalizar Relatório de Visita (DB separado) 🟢

| Item | Detalhe |
|------|---------|
| **Prioridade** | P2 |
| **Módulo** | `consultoria/relatorio_visita` |
| **Bounded Context** | `consultoria` |
| **Estimativa** | 2h |
| **Objetivo** | Adicionar FK `cliente_id` ao lado do campo texto `produtor` |

**Nota:** Este módulo usa banco separado (`visitas_tecnicas.db`). O campo `produtor` é texto livre. 

**Ações:**

1. Adicionar coluna `cliente_id TEXT` na tabela de visitas técnicas (migration)
2. Manter `produtor` como campo de texto (compatibilidade retroativa)
3. No form, se cliente selecionado, auto-preencher `produtor` com `client.name`
4. Na listagem, permitir filtrar por `cliente_id` quando vier do Hub

**Critério de aceite:**
- Campo `produtor` continua editável (texto livre)
- Se cliente selecionado via Hub, `cliente_id` é salvo + `produtor` auto-preenchido
- Compatibilidade retroativa: registros antigos sem `cliente_id` continuam funcionando

---

### WS-7: Refatorar DIP no DrawingController 🟢

| Item | Detalhe |
|------|---------|
| **Prioridade** | P2 |
| **Módulo** | `drawing` |
| **Bounded Context** | `drawing` |
| **Estimativa** | 2h |
| **Objetivo** | Substituir import direto de `ClientsRepository` por interface/adapter |
| **Nota** | Reutiliza `IClientLookup` de `core/contracts/` criada no WS-2 |

**⚠️ CORREÇÃO v1.1:** Na v1.0 do PRD, o adapter era colocado em `consultoria/clients/`. Isso faria `consultoria` conhecer `drawing` — direção proibida. O adapter correto vive em `drawing/infra/`, conforme já documentado no `bounded_contexts.md` (`ClientsRepositoryAdapter`).

**Arquivos a alterar:**
- `lib/modules/drawing/presentation/controllers/drawing_controller.dart`

**Arquivo a criar (ou atualizar se já existe):**
- `lib/modules/drawing/infra/client_lookup_adapter.dart` ← **em drawing/infra/, NÃO em consultoria/**

**Ações:**

1. **Reutilizar** `IClientLookup` de `core/contracts/i_client_lookup.dart` (criada no WS-2):
```dart
// NÃO criar interface duplicada em drawing/domain/interfaces/
// Usar a mesma de core/contracts/ — ponto único de verdade
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
```

2. Criar adapter em `drawing/infra/` (ponte autorizada — bounded_contexts.md):
```dart
// lib/modules/drawing/infra/client_lookup_adapter.dart
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';

/// Adapter que resolve a dependência drawing → clients
/// SEM import direto de consultoria/
/// A implementação concreta é injetada via provider no ponto de composição
class DrawingClientLookupAdapter implements IClientLookup {
  final IClientLookup _delegate;
  DrawingClientLookupAdapter(this._delegate);

  @override
  Future<List<ClientSummary>> listActive() => _delegate.listActive();

  @override
  Future<ClientSummary?> findById(String id) => _delegate.findById(id);
}
```

3. No `DrawingController`, substituir:
```dart
// ❌ Antes (3 imports cross-module)
import '../../../consultoria/clients/data/clients_repository.dart';
import '../../../consultoria/clients/domain/client.dart';
import '../../../consultoria/clients/domain/agronomic_models.dart';
final ClientsRepository? _clientsRepository;

// ✅ Depois (1 import de core/)
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
final IClientLookup? _clientLookup;
```

4. Injeção via provider no ponto de composição (app_router ou main):
```dart
// O adapter recebe a implementação concreta do ClientLookupAdapter
// de consultoria/ — resolvido na camada de composição, não no drawing/
```

**Fluxo de dependências (conformidade REGRA 2):**
```
drawing/ ──import──► core/contracts/i_client_lookup.dart  ✅ PERMITIDO
drawing/ ──✘──► consultoria/  ❌ NUNCA (bloqueado)
composição (app_router) ──inject──► ambos  ✅ PERMITIDO
```

**Critério de aceite:**
- Zero imports de `consultoria/` no módulo `drawing/`
- `DrawingController` depende apenas de `IClientLookup` (de `core/contracts/`)
- Adapter vive em `drawing/infra/` (não em `consultoria/`)
- Funcionalidade de `setClienteAtivo()` preservada
- `arch_check.sh` passa sem violações

---

### WS-8: ClientStatsService — Serviço de Contadores 🔴

| Item | Detalhe |
|------|---------|
| **Prioridade** | P0 (pré-requisito do WS-4) |
| **Módulo** | `core/services` |
| **Bounded Context** | `core` (infraestrutura de agregação) |
| **Estimativa** | 3h |
| **Objetivo** | Criar serviço de agregação para contadores do Hub |

**⚠️ CORREÇÃO v1.1:** Na v1.0, este serviço vivia em `consultoria/clients/data/`. Isso violava ownership de dados — `consultoria` não pode fazer queries em tabelas de `drawing`, `agenda` e `operacao`. Movido para `core/services/` como infraestrutura pura (queries SQL raw, zero imports de modules/).

**Arquivo a criar:**
- `lib/core/services/client_stats_service.dart`
- `lib/core/services/client_stats_providers.dart`

**Ações:**

1. Criar `ClientStatsService`:
```dart
class ClientStats {
  final int totalVisitas;
  final int totalOcorrencias;
  final int totalDesenhos;
  final int totalEventos;
  final int totalRelatorios;
  final List<Map<String, dynamic>> proximosEventos; // top 3
  final List<Map<String, dynamic>> ultimasVisitas;   // top 3
  
  const ClientStats({...});
}

class ClientStatsService {
  final Database _db;
  
  Future<ClientStats> getStats(String clienteId) async {
    // Queries agregadas em uma única transação
    return await _db.transaction((txn) async {
      final visitas = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM visit_sessions WHERE producer_id = ?',
          [clienteId],
        ),
      ) ?? 0;
      
      final ocorrencias = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM occurrences o '
          'INNER JOIN visit_sessions v ON o.visit_session_id = v.id '
          'WHERE v.producer_id = ?',
          [clienteId],
        ),
      ) ?? 0;
      
      final desenhos = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM drawings WHERE cliente_id = ? AND ativo = 1',
          [clienteId],
        ),
      ) ?? 0;
      
      final eventos = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM agenda_events WHERE cliente_id = ?',
          [clienteId],
        ),
      ) ?? 0;
      
      // ... proximosEventos, ultimasVisitas com LIMIT 3
      
      return ClientStats(
        totalVisitas: visitas,
        totalOcorrencias: ocorrencias,
        totalDesenhos: desenhos,
        totalEventos: eventos,
        totalRelatorios: 0, // populado após WS-5
        proximosEventos: [...],
        ultimasVisitas: [...],
      );
    });
  }
}
```

2. Criar provider Riverpod (ADR-008):
```dart
@riverpod
Future<ClientStats> clientStats(ClientStatsRef ref, String clienteId) async {
  final db = await ref.watch(databaseProvider.future);
  final service = ClientStatsService(db);
  return service.getStats(clienteId);
}
```

**Critério de aceite:**
- Todas as queries usam índices existentes
- Execução em transação única (performance)
- Provider com invalidação automática quando dados mudam
- Contadores retornam `0` quando não há dados (nunca null)

---

## 7. Ordem de Execução e Dependências

```
Fase 0 — ADRs Obrigatórios (pré-requisito) — 3h
├── ADR-015: IClientLookup em core/contracts   ← BLOQUEIA WS-2, WS-7
├── ADR-016: Query params oficiais do /map     ← BLOQUEIA WS-4
├── ADR-017: clientId em Relatorio (contrato)  ← BLOQUEIA WS-5
└── ADR-018: Schema v15 (retroativo)           ← documentação pendente

Fase 1 — Bugs Críticos (P0) — 11h
├── WS-1: Fix DrawingLocalStore (2h)     ← sem dependência
├── WS-2: Fix Agenda Selector (5h)       ← depende de ADR-015
└── WS-8: ClientStatsService (3h)        ← sem dependência (vive em core/)

Fase 2 — Integrações (P1) — 16h
├── WS-4: Hub do Cliente (7h)            ← depende de WS-8, ADR-016
├── WS-5: Relatórios ↔ Cliente (4h)      ← depende de ADR-017, ADR-016
└── WS-3: Visitas ↔ Cliente (5h)         ← usa IClientLookup do ADR-015

Fase 3 — Refinamentos (P2) — 4h
├── WS-6: Normalizar Rel. Visita (2h)    ← sem dependência
└── WS-7: Refatorar DIP Drawing (2h)     ← depende de ADR-015 (reutiliza IClientLookup)
```

**Total estimado: 34h (27h implementação + 3h ADRs + 4h revisão conformidade)**

**Grafo de dependências:**

```
ADR-015 ──────┬──────────────────────────────────────────┐
              │                                          │
              ▼                                          ▼
WS-1 ─────────────────────────────►  DONE              WS-7 ──►  DONE
WS-2 ──────────────────┬──────────►  DONE
                       │
WS-8 ──────┬──────────►│  DONE
           │           │
   ADR-016 │           │
       │   ▼           ▼
       └► WS-4       WS-3 ────────►  DONE
            │
   ADR-017  │
       │    ▼
       └► WS-5 ───────────────────►  DONE
          WS-6 ───────────────────►  DONE
```

---

## 8. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| WS-1 corrompe desenhos existentes | Média | Alto | Migração adiciona DEFAULT NULL; desenhos antigos mantêm `cliente_id = NULL` |
| WS-2 quebra fluxo de criação de eventos | Baixa | Alto | Dropdown permite "Sem cliente" como opção válida durante transição |
| WS-2 viola REGRA 2 (agenda → consultoria) | **Alta** | **Crítico** | **Mitigado v1.1:** `IClientLookup` em `core/contracts/` — zero import cross-module |
| WS-3 renomear `producer_id` no banco | — | — | **NÃO renomear** — usar alias no Dart, manter coluna legada |
| WS-4 queries cross-module em consultoria/ | **Alta** | **Crítico** | **Mitigado v1.1:** `ClientStatsService` movido para `core/services/` |
| WS-4 query params não declarados | **Alta** | **Crítico** | **Mitigado v1.1:** ADR-016 obrigatório antes de implementação |
| WS-4 performance dos contadores | Média | Médio | Queries com JOIN indexado; cache via Riverpod `keepAlive` |
| WS-5 altera contrato sem ADR | **Alta** | **Crítico** | **Mitigado v1.1:** ADR-017 obrigatório antes de implementação |
| WS-6 banco separado (`visitas_tecnicas.db`) | Baixa | Baixo | Migration isolada, sem afetar `soloforte.db` |
| WS-7 adapter em local proibido | **Alta** | **Crítico** | **Mitigado v1.1:** adapter em `drawing/infra/` (não `consultoria/`) |

---

## 9. Entidade Client — Campos Disponíveis (Referência)

| Campo | Tipo | Origem |
|-------|------|--------|
| `id` | `String` (UUID) | Original |
| `name` | `String` | Original |
| `phone` | `String` | Original |
| `city` | `String` | Original |
| `state` | `String` | Original |
| `email` | `String?` | Original |
| `observation` | `String?` | Original |
| `photoPath` | `String?` | Original |
| `active` | `bool` | Original |
| `createdAt` | `DateTime` | Original |
| `farms` | `List<Farm>` | Original |
| `dataNascimento` | `DateTime?` | V15 |
| `cpfCnpj` | `String?` | V15 |
| `areaTotal` | `double?` | V15 |
| `tipoPropriedade` | `String?` | V15 |
| `sistemaIrrigacao` | `String?` | V15 |
| `soloTipo` | `String?` | V15 |
| `regiaoAgricola` | `String?` | V15 |
| `safraAtual` | `String?` | V15 |
| `usaAssistenciaTecnica` | `bool?` | V15 |
| `tecnicoResponsavel` | `String?` | V15 |
| `updatedAt` | `DateTime?` | Controle |
| `deletedAt` | `DateTime?` | Soft delete |

---

## 10. Checklist de Validação por WS

Cada WS deve passar TODOS os itens antes de merge:

```
[ ] Apenas módulo declarado alterado
[ ] Bounded context respeitado (sem cross-module proibido)
[ ] Navegação Map-First (context.go() exclusivo)
[ ] Estado Riverpod segue ADR-008
[ ] Zero dados hardcoded / placeholders
[ ] Queries SQL com índices adequados
[ ] Soft delete respeitado (sync_status)
[ ] arch_check.sh passaria
[ ] Testes manuais no fluxo completo
```

---

## 11. ADRs Pré-Requisitos (Fase 0 — Obrigatórios)

Nenhum WS bloqueado pode ser executado antes do ADR correspondente ser criado e aprovado.

### ADR-015: Interface `IClientLookup` em `core/contracts/`

| Item | Detalhe |
|------|---------||
| **Bloqueia** | WS-2, WS-3, WS-7 |
| **Problema** | Módulos `agenda`, `operacao` e `drawing` precisam consultar lista de clientes, mas `agenda → consultoria` e `drawing → consultoria` são **PROIBIDOS** (REGRA 2) |
| **Decisão** | Criar interface `IClientLookup` + DTO `ClientSummary` em `core/contracts/` — zona neutra acessível por todos os bounded contexts |
| **Padrão** | Inversão de Dependência (DIP) via `core/` — mesmo padrão do `DatabaseHelper` |
| **Implementação** | `ClientLookupAdapter` em `consultoria/clients/infra/` implementa a interface. Provider registrado no ponto de composição. |
| **Impacto em arch_check.sh** | Nenhum — `core/contracts/` não importa `modules/` |

```
core/contracts/i_client_lookup.dart
├── ClientSummary (DTO leve)
└── IClientLookup (interface)

consultoria/clients/infra/client_lookup_adapter.dart
└── ClientLookupAdapter implements IClientLookup

agenda/ ──import──► core/contracts/  ✅
drawing/ ──import──► core/contracts/  ✅
agenda/ ──✘──► consultoria/  ❌ BLOQUEADO
```

---

### ADR-016: Query Params Oficiais para Navegação com Contexto de Cliente

| Item | Detalhe |
|------|---------||
| **Bloqueia** | WS-4, WS-5 |
| **Problema** | O Hub do Cliente precisa navegar para `/map`, `/agenda`, `/consultoria/relatorios` passando `clienteId` como query param. Esses params não estão na tabela de rotas oficial. |
| **Decisão** | Declarar oficialmente os seguintes query params |

**Tabela de Query Params — Adições:**

| Rota | Param | Tipo | Comportamento | Status |
|------|-------|------|---------------|--------|
| `/map` | `modo=desenho` | `String` | Ativa modo desenho ao carregar | ✅ Já existe |
| `/map` | `clienteId` | `String?` | Pré-seleciona cliente no modo ativo | ✅ Já existe |
| `/map` | `modo=visita` | `String` | Ativa modo visita ao carregar | **NOVO** |
| `/map` | `focusClienteId` | `String?` | Centraliza mapa na fazenda principal do cliente | **NOVO** |
| `/agenda` | `clienteId` | `String?` | Pré-filtra eventos por cliente | **NOVO** |
| `/consultoria/relatorios` | `clienteId` | `String?` | Filtra relatórios por cliente | **NOVO** |

**Regra:** Query params são **opcionais** — sem eles, a tela funciona normalmente (comportamento padrão preservado).

**Impacto:** Nenhuma rota nova é criada. Apenas extensão de comportamento via query params opcionais nas rotas existentes.

---

### ADR-017: Adição de `clientId` à Entidade `Relatorio` (Contrato de Domínio)

| Item | Detalhe |
|------|---------||
| **Bloqueia** | WS-5 |
| **Problema** | `Relatorio` (domain entity) não tem `clientId`, mas `RelatorioTecnico` (model) já tem. Inconsistência entre camadas. |
| **Decisão** | Adicionar `clientId` como campo **nullable** (`String?`) à entidade `Relatorio` |
| **Retrocompatibilidade** | Registros existentes terão `clientId = null` — sem breaking change |
| **Migration** | V16: `ALTER TABLE relatorios ADD COLUMN client_id TEXT;` |
| **Testes** | Atualizar `fromMap()`, `toMap()`, `copyWith()`, `Equatable props` |
| **Baseline** | Atualizar para v1.3 após merge |

---

### ADR-018: Registro Retroativo do Schema v15 (Dívida Documental)

| Item | Detalhe |
|------|---------||
| **Bloqueia** | Nenhum (documentação pendente) |
| **Problema** | O Schema v15 (tabela `client_culturas` + 15 colunas em `clients`) foi implementado sem ADR registrado nos documentos do projeto |
| **Decisão** | Criar ADR-018 retroativo documentando: |

```
- Tabela client_culturas (FK client_id → clients ON DELETE CASCADE)
- 15 colunas adicionadas em clients (V15)
- Migration idempotente com try/catch por coluna
- Sem breaking change (todas as colunas são nullable ou com DEFAULT)
```

---

## 12. Changelog v1.0 → v1.1

| Item | v1.0 (problema) | v1.1 (correção) |
|------|-----------------|------------------|
| WS-2 | `clientsListProvider` usado diretamente em `agenda/` → viola REGRA 2 | `IClientLookup` via `core/contracts/` + ADR-015 |
| WS-4 | `ClientStatsService` em `consultoria/clients/data/` → queries cross-module | Movido para `core/services/` — infraestrutura pura |
| WS-4 | Query params `modo=visita`, `focusClienteId` não declarados | ADR-016 obrigatório — tabela de params oficiais |
| WS-5 | Alteração de contrato de domínio sem ADR | ADR-017 obrigatório — checklist de processo |
| WS-7 | Adapter em `consultoria/clients/` → `consultoria` conhece `drawing` | Adapter em `drawing/infra/` — direção correta |
| WS-7 | Interface duplicada em `drawing/domain/interfaces/` | Reutiliza `IClientLookup` de `core/contracts/` |
| WS-8 | Vivia em `consultoria/clients/data/` | Movido para `core/services/` |
| Schema | v15 sem ADR registrado | ADR-018 retroativo criado |
| Estimativa | 27h | 34h (+ ADRs + revisão) |

---

*SoloForte Baseline v1.2 — DB Schema v15 — PRD Integração Módulo Clientes v1.1*