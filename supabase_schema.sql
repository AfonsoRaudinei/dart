-- SoloForte — Schema Supabase completo (Fase 1 + Fase 2)
-- Executar no SQL Editor do Supabase

-- ============================================================
-- FASE 1 — Cadastro agronômico
-- ============================================================

CREATE TABLE IF NOT EXISTS public.clients (
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome        TEXT NOT NULL,
  documento   TEXT,
  telefone    TEXT,
  email       TEXT,
  created_at  TIMESTAMPTZ NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL,
  deleted_at  TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.farms (
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cliente_id  UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  nome        TEXT NOT NULL,
  area_total  REAL,
  municipio   TEXT,
  uf          TEXT,
  created_at  TIMESTAMPTZ NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL,
  deleted_at  TIMESTAMPTZ
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

-- ============================================================
-- FASE 2 — Campo (visitas, ocorrências, relatórios, agenda)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.visit_sessions (
  id            UUID PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  producer_id   UUID NOT NULL,
  area_id       UUID NOT NULL,
  activity_type TEXT NOT NULL,
  start_time    TIMESTAMPTZ NOT NULL,
  end_time      TIMESTAMPTZ,
  initial_lat   DOUBLE PRECISION,
  initial_long  DOUBLE PRECISION,
  status        TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL,
  updated_at    TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS public.occurrences (
  id                UUID PRIMARY KEY,
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  visit_session_id  UUID REFERENCES public.visit_sessions(id) ON DELETE SET NULL,
  type              TEXT NOT NULL,
  description       TEXT,
  photo_path        TEXT,
  lat               DOUBLE PRECISION,
  long              DOUBLE PRECISION,
  category          TEXT,
  status            TEXT DEFAULT 'draft',
  created_at        TIMESTAMPTZ NOT NULL,
  updated_at        TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS public.visit_reports (
  id                UUID PRIMARY KEY,
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  visit_session_id  UUID NOT NULL REFERENCES public.visit_sessions(id) ON DELETE CASCADE,
  content           TEXT NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL,
  updated_at        TIMESTAMPTZ NOT NULL,
  UNIQUE (visit_session_id)
);

CREATE TABLE IF NOT EXISTS public.agenda_events (
  id                UUID PRIMARY KEY,
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  producer_id       UUID NOT NULL,
  area_id           UUID NOT NULL,
  activity_type     TEXT NOT NULL,
  scheduled_date    TIMESTAMPTZ NOT NULL,
  description       TEXT,
  visit_session_id  UUID REFERENCES public.visit_sessions(id) ON DELETE SET NULL,
  status            TEXT NOT NULL,
  realized_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL,
  updated_at        TIMESTAMPTZ NOT NULL
);

-- ============================================================
-- RLS — isolamento por usuário (user_id = auth.uid())
-- ============================================================

ALTER TABLE public.clients       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farms         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fields        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.occurrences   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_reports  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_events  ENABLE ROW LEVEL SECURITY;

-- Remove políticas permissivas antigas (se existirem)
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.farms;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.fields;

-- Clients
DROP POLICY IF EXISTS "clients_select_own" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_own" ON public.clients;
DROP POLICY IF EXISTS "clients_update_own" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_own" ON public.clients;
CREATE POLICY "clients_select_own" ON public.clients FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "clients_insert_own" ON public.clients FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "clients_update_own" ON public.clients FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "clients_delete_own" ON public.clients FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Farms
DROP POLICY IF EXISTS "farms_select_own" ON public.farms;
DROP POLICY IF EXISTS "farms_insert_own" ON public.farms;
DROP POLICY IF EXISTS "farms_update_own" ON public.farms;
DROP POLICY IF EXISTS "farms_delete_own" ON public.farms;
CREATE POLICY "farms_select_own" ON public.farms FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "farms_insert_own" ON public.farms FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "farms_update_own" ON public.farms FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "farms_delete_own" ON public.farms FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Fields
DROP POLICY IF EXISTS "fields_select_own" ON public.fields;
DROP POLICY IF EXISTS "fields_insert_own" ON public.fields;
DROP POLICY IF EXISTS "fields_update_own" ON public.fields;
DROP POLICY IF EXISTS "fields_delete_own" ON public.fields;
CREATE POLICY "fields_select_own" ON public.fields FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "fields_insert_own" ON public.fields FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "fields_update_own" ON public.fields FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "fields_delete_own" ON public.fields FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Visit sessions
DROP POLICY IF EXISTS "visit_sessions_all_own" ON public.visit_sessions;
CREATE POLICY "visit_sessions_all_own" ON public.visit_sessions FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Occurrences
DROP POLICY IF EXISTS "occurrences_all_own" ON public.occurrences;
CREATE POLICY "occurrences_all_own" ON public.occurrences FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Visit reports
DROP POLICY IF EXISTS "visit_reports_all_own" ON public.visit_reports;
CREATE POLICY "visit_reports_all_own" ON public.visit_reports FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Agenda events
DROP POLICY IF EXISTS "agenda_events_all_own" ON public.agenda_events;
CREATE POLICY "agenda_events_all_own" ON public.agenda_events FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
