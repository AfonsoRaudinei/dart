# ADR-008 — Normalização Riverpod: Padrão Canônico para Novo Código

**Data**: 21 de fevereiro de 2026
**Branch**: `release/v1.1`
**Status**: APROVADO
**Autores**: Engenheiro Sênior Flutter

---

## Contexto

O projeto SoloForte usa Riverpod de forma mista — resultado natural de evolução
orgânica ao longo do tempo. Antes da FASE 5, o inventário real do projeto era:

| Padrão | Ocorrências | Contexto principal |
|---|---|---|
| `StateProvider` | 63 | Valores simples — bool, int, DateTime |
| `NotifierProvider` | 25 | Estado de domínio com lógica |
| `@riverpod` / `@Riverpod` | 15 | auth, public, feedback, router |
| `StateNotifier` | 6 | Agenda, Location, Theme |
| `ChangeNotifier` | 6 | Sync, Router, Drawing |

A pergunta desta fase não é "qual padrão é superior".
A pergunta é: **qual padrão elimina atrito para o próximo desenvolvedor**.

---

## Decisão

### 1. Não reescrever código existente para uniformizar

Reescrever `ChangeNotifier` → `Notifier` ou `StateNotifier` → `@riverpod`
em código funcional tem custo alto e risco real sem benefício imediato.

**Regra**: código existente e funcional **permanece como está** até ser
alterado por outra razão (bug, feature, refatoração de domínio).

---

### 2. Padrão canônico para código NOVO: `@riverpod` codegen

Todo novo provider criado a partir de agora usa `@riverpod` com geração de
código via `build_runner`.

```dart
// ✅ NOVO CÓDIGO — padrão canônico
@riverpod
Future<List<Client>> clientList(ClientListRef ref) async {
  return ref.watch(clientRepositoryProvider).getAll();
}

// ✅ NOVO CÓDIGO — notifier com estado
@riverpod
class FilterNotifier extends _$FilterNotifier {
  @override
  FilterState build() => const FilterState();

  void setStatus(EventStatus status) {
    state = state.copyWith(status: status);
  }
}
```

**Por quê codegen como padrão futuro**:
- Tipos inferidos automaticamente — sem `Provider<X>` escrito à mão
- `ref.watch` / `ref.read` tipados — erros detectados em compile-time
- Elimina parâmetro `ProviderRef` explícito
- `autoDispose` por padrão — sem vazamentos de memória acidentais

---

### 3. Padrões existentes: quando são corretos e quando não são

#### `ChangeNotifier` — 3 casos legítimos, não alterar

| Classe | Motivo para manter |
|---|---|
| `SyncOrchestrator` | Integração com `ChangeNotifierProvider` do Riverpod; `notifyListeners()` é o contrato correto para orquestração de infraestrutura com múltiplos ouvintes |
| `RouterNotifier` | GoRouter exige `Listenable` — `ChangeNotifier` é o contrato correto |
| `DrawingController` | Máquina de estados com ~800 linhas auditada; reescrita traz risco sem ganho |

**Regra**: `ChangeNotifier` é permitido quando o consumidor exige `Listenable`
(GoRouter, AnimationController) ou quando o custo de migração supera o benefício.

#### `StateNotifier` — legado estável, não alterar

`AgendaNotifier`, `LocationStateNotifier`, `ThemeNotifier`, `AgendaViewNotifier`
existem, funcionam e têm teste implícito pelo uso em produção.

**Regra**: `StateNotifier` não será criado em código novo. Código existente
permanece até ser reescrito por razão de domínio.

#### `StateProvider` — correto para primitivos

```dart
// ✅ CORRETO — primitivo sem lógica
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final agendaHasUnsavedChangesProvider = StateProvider<bool>((ref) => false);
```

`StateProvider` para `bool`, `int`, `DateTime`, `enum` é **correto e deve
continuar sendo usado** — inclusive em código novo — quando não há lógica
associada ao estado.

**Regra**: `StateProvider<T>` é permitido em código novo para `T` primitivo
sem lógica de negócio. Para estado com lógica, usar `@riverpod class`.

#### `Provider` simples — correto para fábricas

```dart
// ✅ CORRETO — fábrica sem estado
final agendaRepositoryProvider = Provider<IAgendaRepository>(
  (ref) => AgendaRepository(),
);
```

`Provider` simples permanece como padrão para expor instâncias sem estado
(repositórios, serviços, use cases). Pode ser substituído por `@riverpod`
em código novo, ambos são válidos.

---

### 4. Guia de decisão para novo código

```
Preciso de um novo provider. Qual padrão usar?

┌─ Tem estado mutável com lógica? ──────────────────── @riverpod class Notifier
│
├─ É uma instância sem estado (repo, service, use case)? ─── @riverpod (function) 
│                                                       ou Provider simples
│
├─ É um primitivo sem lógica (bool, int, enum, DateTime)?─── StateProvider<T>
│
├─ O consumidor exige Listenable (GoRouter, Animation)?───── ChangeNotifier
│
└─ É infraestrutura de sync com múltiplos ouvintes? ──────── ChangeNotifier
```

---

### 5. `autoDispose` por padrão em codegen

O `@riverpod` usa `autoDispose` por padrão. Para providers que devem viver
durante toda a sessão do app (agenda, auth), usar `@Riverpod(keepAlive: true)`:

```dart
// Provider de sessão longa — não descarta ao sair da tela
@Riverpod(keepAlive: true)
class AgendaFilterNotifier extends _$AgendaFilterNotifier { ... }

// Provider de tela — descarta ao sair (padrão @riverpod)
@riverpod
Future<EventDetails> eventDetails(EventDetailsRef ref, String id) async { ... }
```

---

## Consequências

### O que muda agora
- ✅ Todo novo provider usa `@riverpod` ou `StateProvider<T>` (primitivos)
- ✅ `ChangeNotifier` permitido apenas nos 3 casos documentados acima
- ✅ `StateNotifier` não será criado em código novo
- ✅ Nenhum arquivo existente é alterado apenas para uniformizar

### O que não muda
- `SyncOrchestrator extends ChangeNotifier` — permanece
- `RouterNotifier extends ChangeNotifier` — permanece
- `DrawingController extends ChangeNotifier` — permanece
- `AgendaNotifier extends StateNotifier` — permanece
- 63 `StateProvider` existentes — permanecem

### Trajetória de longo prazo
À medida que módulos forem reescritos por razões de domínio, `StateNotifier`
é substituído por `@riverpod class Notifier`. Não há prazo — a migração
acontece naturalmente junto com evolução de feature.

---

## Princípio

> Arquitetura não é dogma.
> O padrão correto é o que elimina atrito sem criar risco.
> Uniformidade por uniformidade é desperdício.

---

## Referências

- [ADR-007](DECISAO_ARQUITETURAL_MAP_FIRST.md) — Map-First (Publicacao canônica)
- [Riverpod docs — codegen](https://riverpod.dev/docs/concepts/about_code_generation)
- `lib/modules/auth/services/auth_service.dart` — exemplo de `@riverpod` em produção
- `lib/core/router/router_notifier.dart` — exemplo legítimo de `ChangeNotifier`
