# ADR-015 — Interface `IClientLookup` em `core/contracts/`

**Data:** 02/03/2026  
**Status:** APROVADO — pré-requisito para implementação  
**Autor:** Engenheiro Sênior SoloForte  
**Referência PRD:** PRD_INTEGRACAO_MODULO_CLIENTES v1.1  
**Bloqueia:** WS-2, WS-3, WS-7  
**Baseline afetada:** ARCH_BASELINE_v1.2 → deve ser atualizada após aprovação

---

## 1. CONTEXTO

Os módulos `agenda`, `operacao` e `drawing` precisam consultar a lista de clientes para:

- `agenda`: substituir `clienteId: 'cliente-demo'` hardcoded em `CreateEventDialog` e `VisitFormDialog`
- `operacao`: substituir `producerId: 'temp-client-id'` hardcoded em `VisitSession` UI
- `drawing`: substituir import direto de `ClientsRepository` (implementação concreta de `consultoria/`)

Porém, as enforcement-rules (REGRA 2) proíbem explicitamente:

```
❌ agenda → consultoria    (BLOQUEADO no CI)
❌ drawing → consultoria   (BLOQUEADO no CI)
```

Sem uma solução arquitetural, qualquer implementação direta seria bloqueada pelo `arch_check.sh`.

---

## 2. PROBLEMA

```
agenda/   ──import──► consultoria/clients/  ❌ REGRA 2
drawing/  ──import──► consultoria/clients/  ❌ REGRA 2
operacao/ ──import──► consultoria/clients/  ⚠️ permitido, mas cria acoplamento forte
```

O `bounded_contexts.md` define `core/` como **zona neutra**, acessível por todos os bounded contexts — equivalente ao `DatabaseHelper` que já vive em `core/database/`.

---

## 3. DECISÃO

### 3.1 Criar `IClientLookup` em `core/contracts/`

**Arquivo:** `lib/core/contracts/i_client_lookup.dart`

```dart
/// DTO leve — apenas dados necessários para lookup (sem Farm, sem Cultura)
class ClientSummary {
  final String id;
  final String name;
  final String? photoPath;
  final bool active;

  const ClientSummary({
    required this.id,
    required this.name,
    this.photoPath,
    required this.active,
  });
}

/// Interface de lookup de clientes — zona neutra (core/contracts/)
/// Acessível por todos os bounded contexts sem violar REGRA 2
abstract interface class IClientLookup {
  /// Retorna todos os clientes ativos, ordenados por nome
  Future<List<ClientSummary>> listAtivos();

  /// Retorna um cliente por ID, ou null se não encontrado
  Future<ClientSummary?> findById(String id);
}
```

### 3.2 Implementação em `consultoria/clients/infra/`

**Arquivo:** `lib/modules/consultoria/clients/infra/client_lookup_adapter.dart`

```dart
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';

/// Implementação concreta que delega ao ClientsRepository
/// Vive em consultoria/ — dono dos dados de clientes
class ClientLookupAdapter implements IClientLookup {
  final ClientsRepository _repository;

  ClientLookupAdapter(this._repository);

  @override
  Future<List<ClientSummary>> listAtivos() async {
    final clients = await _repository.listAtivos();
    return clients.map((c) => ClientSummary(
      id: c.id,
      name: c.name,
      photoPath: c.photoPath,
      active: c.active,
    )).toList();
  }

  @override
  Future<ClientSummary?> findById(String id) async {
    final client = await _repository.findById(id);
    if (client == null) return null;
    return ClientSummary(
      id: client.id,
      name: client.name,
      photoPath: client.photoPath,
      active: client.active,
    );
  }
}
```

### 3.3 Provider no ponto de composição

**Arquivo:** `lib/core/contracts/i_client_lookup_provider.dart`

```dart
// Provider registrado em core/ — composição resolvida aqui
// A implementação concreta (ClientLookupAdapter) é injetada pelo app_router
// ou pelo ponto de entrada da aplicação

@riverpod
IClientLookup clientLookup(ClientLookupRef ref) {
  // Injeção da implementação concreta — resolvida no override de testes
  throw UnimplementedError('Registrar ClientLookupAdapter no ProviderScope');
}
```

---

## 4. FLUXO DE DEPENDÊNCIAS

```
core/contracts/i_client_lookup.dart   ← interface + DTO (zero imports de modules/)
        ▲                  ▲                  ▲
        │                  │                  │
   agenda/          operacao/            drawing/
   (usa interface)  (usa interface)  (usa interface)
        
consultoria/clients/infra/
└── ClientLookupAdapter implements IClientLookup  ← dono da impl concreta
```

**Conformidade REGRA 2:**
| Dependência | Status |
|-------------|--------|
| `agenda/ → core/contracts/` | ✅ PERMITIDO |
| `operacao/ → core/contracts/` | ✅ PERMITIDO |
| `drawing/ → core/contracts/` | ✅ PERMITIDO |
| `consultoria/ → core/contracts/` | ✅ PERMITIDO |
| `agenda/ → consultoria/` | ❌ BLOQUEADO — nunca ocorre |
| `drawing/ → consultoria/` | ❌ BLOQUEADO — nunca ocorre |
| `core/contracts/ → modules/` | ❌ BLOQUEADO — nunca ocorre |

---

## 5. IMPACTO NO `arch_check.sh`

- `core/contracts/i_client_lookup.dart` → não importa `modules/` → **REGRA 1 respeitada** ✅
- `agenda/` → importa apenas `core/contracts/` → **REGRA 2 respeitada** ✅
- `arch_check.sh passaria` → **SIM** ✅

---

## 6. ARQUIVOS AFETADOS

| Ação | Arquivo | Módulo |
|------|---------|--------|
| **CRIAR** | `lib/core/contracts/i_client_lookup.dart` | `core` |
| **CRIAR** | `lib/core/contracts/i_client_lookup_provider.dart` | `core` |
| **CRIAR** | `lib/modules/consultoria/clients/infra/client_lookup_adapter.dart` | `consultoria` |
| **ALTERAR** | `lib/modules/agenda/presentation/widgets/create_event_dialog.dart` | `agenda` (WS-2) |
| **ALTERAR** | `lib/modules/agenda/presentation/widgets/visit_form_dialog.dart` | `agenda` (WS-2) |
| **ALTERAR** | `lib/modules/drawing/presentation/controllers/drawing_controller.dart` | `drawing` (WS-7) |

---

## 7. CRITÉRIO DE ACEITE

```
[ ] IClientLookup e ClientSummary criados em core/contracts/
[ ] Zero imports de modules/ em core/contracts/i_client_lookup.dart
[ ] ClientLookupAdapter criado em consultoria/clients/infra/
[ ] arch_check.sh passaria (simular)
[ ] ClientSummary contém apenas id, name, photoPath, active
[ ] Testes unitários para ClientLookupAdapter (mock do repository)
```

---

## 8. ALTERNATIVAS REJEITADAS

| Alternativa | Motivo da rejeição |
|-------------|-------------------|
| Import direto `agenda → consultoria` | Viola REGRA 2 — bloqueado pelo CI |
| Interface em `agenda/domain/interfaces/` | Cada módulo teria sua própria cópia — sem ponto único de verdade |
| Interface em `consultoria/domain/interfaces/` | `agenda` ainda importaria `consultoria` — mesmo problema |
| Passar callback via construtor/provider | Funciona para um widget, não escala para 3 módulos |

---

*SoloForte Baseline v1.2 — ADR-015 — 02/03/2026*
