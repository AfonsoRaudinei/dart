# Supabase Manual — SoloForte

> **Guia passo a passo** para configurar o banco de dados Supabase do SoloForte Dart
> diretamente pelo Dashboard, sem precisar abrir arquivos do repositório.
>
> **Especificação completa de tabelas, colunas e RLS:**
> [docs/SUPABASE_RELATORIO_COMPLETO.md](SUPABASE_RELATORIO_COMPLETO.md)

---

## 1. Informações do Projeto

| Campo | Valor |
|---|---|
| **Project URL** | `https://pyoejhhkjlrjijiviryq.supabase.co` |
| **Chave pública (app)** | **Project Settings → API Keys → Publishable key** → Copy |
| **Repositório SQL** | https://github.com/AfonsoRaudinei/dart (branch `main`) |

> **Qual chave usar no Flutter**
>
> | Prioridade | Onde no Dashboard | Valor em `SUPABASE_ANON_KEY` |
> |------------|-------------------|------------------------------|
> | **Recomendado** | **API Keys → Publishable key** | Cole a Publishable key |
> | Alternativa | API Keys *(Legacy)* → `anon` `public` | Ainda funciona; Supabase desaconselha para projetos novos |
>
> A chave é **pública** e segura no mobile (protegida pelo RLS).
> Use via `--dart-define` ou `dart_defines.json`. **Nunca use `service_role` no Flutter.**

---

## 2. Ordem de Execução

```
1. supabase_schema.sql              → 7 tabelas + RLS isolado por user_id
2. supabase/auth_delete_account.sql → RPC delete_own_account()
3. supabase/feedback_table.sql      → tabela feedback (category/message)
4. Queries de verificação
5. Auth Dashboard
6. flutter run
```

> ⚠️ Schema usa `user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
> em todas as tabelas. RLS: `user_id = auth.uid()`.
> **Não use schema antigo sem user_id** — incompatível com o app de release.

---

## 3. Script 1 — Schema (`supabase_schema.sql`)

### O que faz
7 tabelas com `user_id` + CASCADE + RLS isolado por usuário.

**Diferenças vs schema antigo sem user_id:**
- Todas as tabelas têm `user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
- RLS usa `user_id = auth.uid()` (não `USING (true)`)
- `visit_sessions` tem `producer_id`, `area_id`, `activity_type`, `start_time`

### Como executar
1. SQL Editor → New query
2. Cole o SQL → Run → confirme "Run query"

### SQL completo

```sql
-- SoloForte — Schema Supabase completo (Fase 1 + Fase 2)

CREATE TABLE IF NOT EXISTS public.clients (
  id           UUID PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome         TEXT NOT NULL,
  documento    TEXT,
  telefone     TEXT,
  email        TEXT,
  created_at   TIMESTAMPTZ NOT NULL,
  updated_at   TIMESTAMPTZ NOT NULL,
  deleted_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.farms (
  id           UUID PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cliente_id   UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  nome         TEXT NOT NULL,
  area_total   REAL,
  municipio    TEXT,
  uf           TEXT,
  created_at   TIMESTAMPTZ NOT NULL,
  updated_at   TIMESTAMPTZ NOT NULL,
  deleted_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.fields (
  id              UUID PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fazenda_id      UUID NOT NULL REFERENCES public.farms(id) ON DELETE CASCADE,
  codigo          TEXT,
  nome            TEXT NOT NULL,
  area_produtiva  REAL,
  bordadura_geo   JSONB,
  centro_geo      JSONB,
  created_at      TIMESTAMPTZ NOT NULL,
  updated_at      TIMESTAMPTZ NOT NULL,
  deleted_at      TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.visit_sessions (
  id             UUID PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  producer_id    UUID NOT NULL,
  area_id        UUID NOT NULL,
  activity_type  TEXT NOT NULL,
  start_time     TIMESTAMPTZ NOT NULL,
  end_time       TIMESTAMPTZ,
  initial_lat    DOUBLE PRECISION,
  initial_long   DOUBLE PRECISION,
  status         TEXT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL,
  updated_at     TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS public.occurrences (
  id               UUID PRIMARY KEY,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  visit_session_id UUID REFERENCES public.visit_sessions(id) ON DELETE SET NULL,
  type             TEXT NOT NULL,
  description      TEXT,
  photo_path       TEXT,
  lat              DOUBLE PRECISION,
  long             DOUBLE PRECISION,
  category         TEXT,
  status           TEXT DEFAULT 'draft',
  created_at       TIMESTAMPTZ NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS public.visit_reports (
  id               UUID PRIMARY KEY,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  visit_session_id UUID NOT NULL REFERENCES public.visit_sessions(id) ON DELETE CASCADE,
  content          TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL,
  UNIQUE (visit_session_id)
);

CREATE TABLE IF NOT EXISTS public.agenda_events (
  id               UUID PRIMARY KEY,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  producer_id      UUID NOT NULL,
  area_id          UUID NOT NULL,
  activity_type    TEXT NOT NULL,
  scheduled_date   TIMESTAMPTZ NOT NULL,
  description      TEXT,
  visit_session_id UUID REFERENCES public.visit_sessions(id) ON DELETE SET NULL,
  status           TEXT NOT NULL,
  realized_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL
);

ALTER TABLE public.clients        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farms          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fields         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.occurrences    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_reports  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_events  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.farms;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.fields;

DROP POLICY IF EXISTS "clients_select_own" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_own" ON public.clients;
DROP POLICY IF EXISTS "clients_update_own" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_own" ON public.clients;
CREATE POLICY "clients_select_own" ON public.clients FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "clients_insert_own" ON public.clients FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "clients_update_own" ON public.clients FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "clients_delete_own" ON public.clients FOR DELETE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "farms_select_own" ON public.farms;
DROP POLICY IF EXISTS "farms_insert_own" ON public.farms;
DROP POLICY IF EXISTS "farms_update_own" ON public.farms;
DROP POLICY IF EXISTS "farms_delete_own" ON public.farms;
CREATE POLICY "farms_select_own" ON public.farms FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "farms_insert_own" ON public.farms FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "farms_update_own" ON public.farms FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "farms_delete_own" ON public.farms FOR DELETE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "fields_select_own" ON public.fields;
DROP POLICY IF EXISTS "fields_insert_own" ON public.fields;
DROP POLICY IF EXISTS "fields_update_own" ON public.fields;
DROP POLICY IF EXISTS "fields_delete_own" ON public.fields;
CREATE POLICY "fields_select_own" ON public.fields FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "fields_insert_own" ON public.fields FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "fields_update_own" ON public.fields FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "fields_delete_own" ON public.fields FOR DELETE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "visit_sessions_all_own" ON public.visit_sessions;
CREATE POLICY "visit_sessions_all_own" ON public.visit_sessions FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "occurrences_all_own" ON public.occurrences;
CREATE POLICY "occurrences_all_own" ON public.occurrences FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "visit_reports_all_own" ON public.visit_reports;
CREATE POLICY "visit_reports_all_own" ON public.visit_reports FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "agenda_events_all_own" ON public.agenda_events;
CREATE POLICY "agenda_events_all_own" ON public.agenda_events FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
```

---

## 4. Script 2 — delete_own_account

```sql
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
```

---

## 5. Script 3 — feedback (category/message)

```sql
CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  message  TEXT NOT NULL,
  app_version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "feedback_insert_own" ON public.feedback;
DROP POLICY IF EXISTS "feedback_select_own" ON public.feedback;
CREATE POLICY "feedback_insert_own" ON public.feedback FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "feedback_select_own" ON public.feedback FOR SELECT TO authenticated USING (user_id = auth.uid());
```

---

## 6. Verificação

```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  AND tablename IN ('clients','farms','fields','visit_sessions','occurrences','visit_reports','agenda_events','feedback')
ORDER BY tablename;

SELECT proname FROM pg_proc WHERE proname = 'delete_own_account';

SELECT column_name FROM information_schema.columns
WHERE table_name = 'clients' AND column_name = 'user_id';
```

**Critério:** 8 tabelas + função + user_id presente.

---

## 7. Auth + chave pública (Publishable key)

1. **Authentication → Providers → Email** — desabilitar "Confirm email" (dev) ou confirmar usuários manualmente (prod)
2. **Project Settings → API Keys**
   - **Recomendado:** aba **API Keys** → **Publishable key** → **Copy**
   - *Alternativa:* aba **API Keys (Legacy)** → `anon` `public` (funciona, mas legacy)

Cole o valor em `SUPABASE_ANON_KEY` no app (nome da variável mantido por compatibilidade com o código Flutter).

---

## 8. Flutter Run

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=COLE_SUA_PUBLISHABLE_KEY
```

---

## 9. Troubleshooting

| Erro | Solução |
|---|---|
| "Supabase não configurado" | Faltam `--dart-define` |
| "Confirme seu e-mail" | Desabilitar confirmação em Auth (dev) |
| `RPC delete_own_account not found` | Executar Script 2 |
| `permission denied / RLS violation` | user_id errado ou schema antigo → re-executar Script 1 |
| `column "category" does not exist` | Feedback com schema antigo → DROP TABLE public.feedback CASCADE + Script 3 |
| `column "user_id" does not exist` | Schema antigo → DROP todas as tabelas + re-executar 3 scripts |

---

## 10. Fora do Supabase

| Ação | Onde |
|---|---|
| Android keystore / key.properties | `docs/BUILD_RELEASE.md` |
| Certificado iOS Distribution | `docs/BUILD_RELEASE.md` |
| Submissão lojas | `docs/store/GUIA_SUBMISSAO.md` |
