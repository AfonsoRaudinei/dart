# Prompt — Claude Code: conferir tabelas do Supabase (SoloForte)

> Cole este arquivo inteiro no Claude Code, aberto na pasta `~/dev/appdart`.
> Modo: **somente leitura** até o Raudinei aprovar a proposta da Etapa 4.

---

## Contexto

- Projeto Supabase: **SoloForte Dart** — ref `pyoejhhkjlrjijiviryq` (São Paulo).
- O app é offline-first: grava no SQLite e envia ao Supabase por upsert (PostgREST).
  Coluna que falta no servidor faz **todo** o envio daquela tabela falhar
  (`PGRST204` / `42703`) — os dados ficam presos como `pending_sync` no aparelho.
- Migrations do repo: `supabase/migrations/*.sql` (40 arquivos).
- O histórico remoto (`supabase_migrations.schema_migrations`) está **desalinhado**:
  ~20 migrations locais aparecem como não aplicadas e 9 versões remotas não têm
  arquivo local (aplicadas pelo painel/MCP com outro número). Exemplos remotos
  órfãos: `20260822223918`, `20260825021012`, `20260825023941`, `20260825024829`,
  `20260825025131`, `20260825025706`, `20260831191135`, `20260912013400`,
  `20261105152913`.
- Já alinhadas em 10/nov/2026: `20261109230000` e `20261109240000`
  (colunas `data_fim_plantio`, `ciclo_dias`, `cultura`, `safra` em `occurrences`).
- CLI: `supabase` v2.75 instalada e logada (sem Docker → `db dump` não funciona).
  `npx --yes supabase@3.1.0 db query --remote --read-only "<sql>"` roda SQL só leitura,
  mas pede `SUPABASE_ACCESS_TOKEN` (ou `npx supabase@3.1.0 login`).
- Chave pública do app: `.env.local.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
  **Nunca** imprimir, copiar para arquivo versionado ou colar chaves/tokens no chat.

## Proibido

- `supabase db push` (aplicaria de novo migrations já existentes com outro número).
- `supabase db reset`, `drop`, `delete`, `truncate`, `alter ... drop`.
- Qualquer escrita no banco antes da aprovação explícita da Etapa 4.
- Editar `lib/`, `test/`, `tool/`, `ios/`, `android/`.
- `git push origin main`.

## Etapa 1 — Inventário do que o app usa

1. Liste as tabelas e buckets remotos usados pelo app:
   ```bash
   rg -o "\.from\('([a-z_]+)'\)" -r '$1' lib/ --no-filename | sort -u
   rg -n "storage\s*\.from\(" lib/
   rg -n "tableName|_table\s*=|kTable" lib/ | rg -i "supabase|remote|sync"
   ```
2. Para cada tabela, ache o serviço de sync/remote store e liste **todas** as chaves
   enviadas no payload do upsert (`toRemoteRow`, `toRemoteMap`, `_toRemote`…).
   Descarte chaves só locais (`sync_status`, `synced`, `cached_by_user_id`, GeoJSON
   interno como `coordinates`).

## Etapa 2 — Conferir o banco de produção (só leitura)

Opção A (sem token, só colunas): para cada `tabela` × `coluna`:
```bash
URL=$(python3 -c "import json;print(json.load(open('.env.local.json'))['SUPABASE_URL'])")
KEY=$(python3 -c "import json;print(json.load(open('.env.local.json'))['SUPABASE_ANON_KEY'])")
curl -s "$URL/rest/v1/<tabela>?select=<coluna>&limit=0" -H "apikey: $KEY" -H "Authorization: Bearer $KEY"
```
`[]` = existe · `42703` = coluna falta · `42P01`/`PGRST205` = tabela falta.

Opção B (com token, completo) — sempre `--read-only`:
```sql
select table_name, column_name, data_type, is_nullable
from information_schema.columns where table_schema = 'public' order by 1, 2;

select tablename, policyname, cmd, roles from pg_policies where schemaname = 'public';

select c.relname, c.relrowsecurity from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r';

select id, public from storage.buckets;

select version, name, array_to_string(statements, E'\n;\n') as sql
from supabase_migrations.schema_migrations order by version;
```

## Etapa 3 — Cruzar migrations locais × banco

Para **cada** migration local que não aparece no remoto
(`supabase migration list --linked`), leia o `.sql` e verifique se cada efeito
(tabela, coluna, índice, policy, bucket, função, view, trigger) já existe em produção.
Para **cada** versão remota órfã, leia o SQL salvo e diga a qual arquivo local
ela corresponde (ou se não corresponde a nenhum).

## Etapa 4 — Entregar a proposta (parar aqui e pedir ok)

Responda em português, com uma tabela:

| Versão | Origem (local/remota) | Efeito existe no banco? | Ação proposta |
|---|---|---|---|

Ações possíveis:
- `supabase migration repair --status applied <versão>` — local com efeito já presente.
- `supabase migration repair --status reverted <versão>` — remota órfã que duplica um arquivo local já marcado como aplicado.
- **Aplicar SQL** — local cujo efeito **não** existe (mostrar o SQL exato; idempotente com `if not exists`).
- **Investigar** — divergência que não dá para decidir com segurança.

Liste também: colunas que o app envia e não existem (bloqueiam sync hoje),
tabelas sem RLS e buckets públicos inesperados.

**Só depois do ok do Raudinei:** aplicar o SQL aprovado pelo SQL Editor
(`https://supabase.com/dashboard/project/pyoejhhkjlrjijiviryq/sql/new`) ou
`db query --remote` sem `--read-only`, rodar os `migration repair` e confirmar com:
```bash
supabase migration list --linked     # local e remoto iguais
supabase db push --dry-run --linked  # "Remote database is up to date"
```
