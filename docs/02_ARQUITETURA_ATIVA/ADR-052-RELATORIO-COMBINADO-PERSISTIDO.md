# ADR-052 — Relatório combinado persistido

**Data:** 26/10/2026  
**Status:** APROVADO  
**Módulos:** `consultoria/relatorios/`, `core/database/`, `app/sync_registration.dart`

## Contexto

A aba Relatórios → Consolidados montava o relatório combinado só na hora,
num card “Gerado sob demanda”. Não havia linha para reabrir a mesma
composição, nem para tirar um capítulo sem apagar a visita, a ocorrência
ou o case de origem.

O HTML é regenerado pelos renderers já existentes. Congelar o documento
no banco duplicaria foto, branding e texto.

## Decisão

1. **SQLite v46** — `CREATE TABLE IF NOT EXISTS relatorios_combinados`:
   `id`, `user_id`, `client_id`, `title`, `chapters_json` (array de chaves
   `visita:<id>`, `ocorrencia:<id>`, `mkt:<id>`), `created_at`, `updated_at`,
   `sync_status` (`pending_sync` por omissão), `deleted_at`. Sem hard delete.
2. **Supabase** — `supabase/migrations/20261026223000_relatorios_combinados.sql`
   espelha a tabela. `user_id uuid NOT NULL REFERENCES auth.users(id)`.
   `chapters_json jsonb`. `client_id text` sem FK. RLS `authenticated` com
   `user_id = auth.uid()` em SELECT/INSERT/UPDATE. Sem policy anônima. Sem
   DELETE físico. O SQL fica no repo; aplicar no projeto live não faz parte
   deste ADR.
3. **`RelatorioCombinadoSyncService.syncNow()`** — sem JWT: no-op. Com JWT:
   push (upsert, inclusive tombstone `deleted_at`) depois pull LWW por
   `updated_at`. Remoto com `deleted_at` não volta para a lista. Colunas
   permitidas explícitas. `user_id` do JWT.
4. **`RelatorioCombinadoSyncModule`** — `syncTier` 1, nome `Relatórios combinados`,
   registrado depois de `RelatorioSyncModule`.
5. **Capítulos** — tirar uma chave atualiza `chapters_json`. Se não sobrar
   capítulo, soft delete (`deleted_at` + `pending_sync`). A fonte permanece.
   Fonte ausente é omitida na renderização; a chave só sai quando o usuário tira.

## Consequências

- Cada toque em Combinar grava uma combinação nova, por produtor.
- Abrir o card regenera o HTML com `_buildCombinedReportPayload` e inclui
  `combinadoId` no JSON do pack.
- Writes locais marcam `pending_sync`. Sem sessão JWT o aparelho continua
  lendo e gravando só no SQLite.
