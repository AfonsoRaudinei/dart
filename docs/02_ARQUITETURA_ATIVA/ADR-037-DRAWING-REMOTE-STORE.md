# ADR-037 — DrawingRemoteStore e Sincronização Remota de Drawing

**Data:** Mai/2026
**Status:** APROVADO
**Origem:** PRD Auditoria v1.0 — Fase 2/Fase 3
**Módulo:** `lib/modules/drawing/`

---

## Contexto

`drawing/` é um bounded context fechado para geometria, edição de talhões e
operações espaciais. A persistência local usa SQLite via `DrawingLocalStore`.
A auditoria registrou risco no sync remoto porque `DrawingRemoteStore` precisava
ter comportamento explícito para Supabase, autenticação e payload inválido.

---

## Decisão

`DrawingRemoteStore` é o adaptador remoto oficial de `drawing/` para Supabase.

Contrato operacional:

- `push(DrawingFeature)` faz `upsert` idempotente na tabela `drawings`
- `fetchUpdates(DateTime? lastSync)` lê registros do usuário autenticado
- `SupabaseClient` deve ser injetável pelo construtor
- `sync_status` não é enviado ao remoto; é controle local
- falha de autenticação deve lançar erro explícito
- payload remoto inválido deve lançar erro explícito

---

## Fronteira

`DrawingRemoteStore` não pode importar `consultoria/`, `agenda/`, `visitas/` ou
outro bounded context. Qualquer lookup externo necessário ao módulo deve passar
por contratos neutros ou adapters já autorizados em `drawing/infra/`.

---

## Tabela Remota

Tabela esperada: `drawings`

Campos usados:

| Campo | Uso |
|---|---|
| `id` | chave lógica e conflito do upsert |
| `user_id` | isolamento por usuário autenticado |
| `geometry` | GeoJSON do desenho |
| `properties` | metadados do desenho |
| `deleted_at` | soft delete remoto |
| `created_at` | criação original |
| `updated_at` | ordenação e pull incremental |

---

## Consequências

- Sync não deve falhar silenciosamente quando não há usuário autenticado.
- Linhas remotas corrompidas bloqueiam o sync com `FormatException`.
- O tratamento de retry/conflito permanece em `DrawingSyncService`.
- O repositório público de drawing não muda de interface.

---

## Gate

- `flutter analyze lib/modules/drawing/data/data_sources/drawing_remote_store.dart`
  deve passar.
- `flutter test test/modules/drawing/ --reporter compact` deve passar.
- `./tool/arch_check.sh` deve passar.
