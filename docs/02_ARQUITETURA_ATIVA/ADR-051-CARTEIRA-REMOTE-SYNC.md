# ADR-051 — Espelho remoto da Carteira (SQLite → Supabase)

**Data:** 22/08/2026  
**Status:** APROVADO  
**Módulos:** `carteira/`, `core/database/`, `app/sync_registration.dart`

## Contexto

O bounded context `carteira/` persistia só em SQLite (`carteira_tipos_produto`,
`carteira_categorias`, `carteira_config`, `carteira_safras`, `carteira_metas`,
`carteira_cliente_categorias`, `carteira_lancamentos`). Sem tabela no Supabase e
sem `SyncModule`, reinstalar o app apagava metas, safras, lançamentos, categorias
e tipos — mesmo com login na mesma conta.

Clientes da consultoria já voltam no pull agronômico (tier 0). O pipeline
comercial não. Hard delete de `carteira_lancamentos` impedia tombstone.

Colunas de domínio permanecem as do SQLite atual (`toMap` das entidades + DDL
v22–v39). Não se inventa campo de produto (`roi`, `quantidade_derivada`, etc.).

## Decisão

1. **SQLite v42** — ALTER idempotente nas 7 tabelas: `sync_status TEXT NOT NULL
   DEFAULT 'pending_sync'`, `deleted_at TEXT` nullable, e `updated_at` em
   `carteira_lancamentos` / `carteira_config` se ainda não existir.
2. **Supabase** — `CREATE TABLE IF NOT EXISTS` espelhando snake_case do SQLite.
   `user_id uuid NOT NULL REFERENCES auth.users(id)`. `cliente_id` text/uuid
   **sem** FK para `clients` (evita ordem de pull). RLS `authenticated` com
   `user_id = auth.uid()` em SELECT/INSERT/UPDATE. Sem policy anônima. Sem
   DELETE físico no remoto.
3. **`CarteiraSyncService.syncNow()`** — sem JWT: no-op. Com JWT: push (upsert
   das 7 tabelas, incluindo tombstones de lançamento) depois pull (LWW por
   `updated_at`; remoto com `deleted_at` não reaparece na UI). Ordem:
   tipos → categorias → config → safras → metas → cliente_categorias →
   lançamentos.
4. **`CarteiraSyncModule`** — `syncTier` 1, registrado depois do agronômico
   (tier 0) em `registerSyncModules`.
5. **`deleteLancamento`** — soft delete (`deleted_at` + `pending_sync`).
   Listagens ignoram `deleted_at IS NOT NULL`.

## Consequências

- Reinstalar e logar na mesma conta restaura o pipeline se já havia sido
  sincronizado.
- Lançamento excluído vira tombstone; o pull não o reintroduz como vivo.
- Writes locais marcam `pending_sync` para o próximo push.
- Migration SQL no repo (`supabase/migrations/20260822190000_carteira_remote_sync.sql`);
  aplicar no projeto live não faz parte deste ADR.
