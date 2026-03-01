-- ============================================================
-- SOLOFORTE — SETUP COMPLETO DO BANCO DE DADOS
-- Execute no Supabase → SQL Editor → New Query → Run
-- ============================================================
-- PASSO 1: LIMPAR TABELAS DO APP ANTIGO
-- ============================================================

drop table if exists public.conversas cascade;
drop table if exists public.blocos_de_documento cascade;
drop table if exists public.documentos cascade;
drop table if exists public.mensagens cascade;
drop table if exists public.alfinetes cascade;
drop table if exists public.produtores cascade;
drop table if exists public.registros_de_seguranca cascade;
drop table if exists public."registros de segurança" cascade;
drop table if exists public."preferências do usuário" cascade;
drop table if exists public.preferencias_do_usuario cascade;
drop table if exists public.webhook_configuracoes cascade;
drop table if exists public.webhook_configurações cascade;
drop table if exists public.webhook_logs cascade;
drop table if exists public.configuracoes_do_aplicativo cascade;
drop table if exists public."avaliações de marketing" cascade;
drop table if exists public.casos_de_marketing cascade;
drop table if exists public.perfis cascade;

-- ============================================================
-- PASSO 2: CRIAR TABELAS DO SOLOFORTE
-- ============================================================

-- ------------------------------------------------------------
-- PERFIS (auth)
-- ------------------------------------------------------------
create table public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  role text not null,
  photo_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- AGENDA EVENTS
-- ------------------------------------------------------------
create table public.agenda_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tipo text not null,
  cliente_id text,
  fazenda_id text,
  talhao_id text,
  titulo text not null,
  data_inicio_planejada timestamptz not null,
  data_fim_planejada timestamptz not null,
  status text not null default 'agendado',
  visit_session_id uuid,
  serie_id uuid,
  sync_status text not null default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- AGENDA VISIT SESSIONS
-- ------------------------------------------------------------
create table public.agenda_visit_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  evento_id uuid references public.agenda_events(id) on delete set null,
  start_at_real timestamptz not null,
  end_at_real timestamptz,
  duracao_min integer,
  notas_finais text,
  checklist_snapshot jsonb,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- ------------------------------------------------------------
-- VISIT SESSIONS (módulo visitas)
-- ------------------------------------------------------------
create table public.visit_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  producer_id text,
  area_id text,
  activity_type text,
  started_at timestamptz not null,
  ended_at timestamptz,
  sync_status text not null default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- CLIENTS (consultoria)
-- ------------------------------------------------------------
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  email text,
  phone text,
  document text,
  sync_status text not null default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- FARMS (consultoria)
-- ------------------------------------------------------------
create table public.farms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid references public.clients(id) on delete cascade,
  name text not null,
  city text,
  state text,
  area_ha numeric,
  sync_status text not null default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- FIELDS / TALHÕES (consultoria)
-- ------------------------------------------------------------
create table public.fields (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  farm_id uuid references public.farms(id) on delete cascade,
  name text not null,
  area_ha numeric,
  geometry jsonb,
  sync_status text not null default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- OCCURRENCES (consultoria)
-- ------------------------------------------------------------
create table public.occurrences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  field_id uuid references public.fields(id) on delete set null,
  visit_session_id uuid,
  type text not null,
  severity text,
  latitude numeric,
  longitude numeric,
  geometry jsonb,
  notes text,
  photo_url text,
  sync_status text not null default 'pending',
  deleted_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- MARKETING CASES
-- ------------------------------------------------------------
create table public.marketing_cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  product text,
  culture text,
  latitude numeric,
  longitude numeric,
  photo_url text,
  visibility text not null default 'bronze',
  status text not null default 'draft',
  roi_data jsonb,
  avaliacoes jsonb,
  sync_status text not null default 'pending',
  deleted_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- MARKETING AVALIACOES
-- ------------------------------------------------------------
create table public.marketing_avaliacoes (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.marketing_cases(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  lado_a jsonb,
  lado_b jsonb,
  colapsado boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- FEEDBACK
-- ------------------------------------------------------------
create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  type text,
  message text not null,
  rating integer,
  created_at timestamptz default now()
);

-- ============================================================
-- PASSO 3: ROW LEVEL SECURITY (RLS)
-- ============================================================

alter table public.perfis enable row level security;
alter table public.agenda_events enable row level security;
alter table public.agenda_visit_sessions enable row level security;
alter table public.visit_sessions enable row level security;
alter table public.clients enable row level security;
alter table public.farms enable row level security;
alter table public.fields enable row level security;
alter table public.occurrences enable row level security;
alter table public.marketing_cases enable row level security;
alter table public.marketing_avaliacoes enable row level security;
alter table public.feedback enable row level security;

-- Perfis
create policy "perfis_own" on public.perfis for all using (auth.uid() = id);

-- Agenda events
create policy "agenda_events_own" on public.agenda_events for all using (auth.uid() = user_id);

-- Agenda visit sessions
create policy "agenda_sessions_own" on public.agenda_visit_sessions for all using (auth.uid() = user_id);

-- Visit sessions
create policy "visit_sessions_own" on public.visit_sessions for all using (auth.uid() = user_id);

-- Clients
create policy "clients_own" on public.clients for all using (auth.uid() = user_id);

-- Farms
create policy "farms_own" on public.farms for all using (auth.uid() = user_id);

-- Fields
create policy "fields_own" on public.fields for all using (auth.uid() = user_id);

-- Occurrences
create policy "occurrences_own" on public.occurrences for all using (auth.uid() = user_id);

-- Marketing cases
create policy "marketing_cases_own" on public.marketing_cases for all using (auth.uid() = user_id);

-- Marketing avaliacoes
create policy "marketing_avaliacoes_own" on public.marketing_avaliacoes for all using (auth.uid() = user_id);

-- Feedback
create policy "feedback_insert" on public.feedback for insert with check (auth.uid() = user_id);
create policy "feedback_own_select" on public.feedback for select using (auth.uid() = user_id);

-- ============================================================
-- MÓDULO PLANOS — ADR-012 (28/02/2026)
-- ============================================================

-- ------------------------------------------------------------
-- USER_PLANS (planos ativos)
-- ------------------------------------------------------------
create table if not exists public.user_plans (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  plano         text not null check (plano in ('bronze','prata','ouro')),
  origem        text not null check (origem in ('pagamento','indicacao')),
  ativo         boolean not null default true,
  iniciou_em    timestamptz not null default now(),
  expira_em     timestamptz not null,
  payment_id    text,
  criado_em     timestamptz not null default now()
);

alter table public.user_plans enable row level security;

create policy "user_plans_own_select" on public.user_plans
  for select to authenticated using (user_id = auth.uid());

create policy "user_plans_own_insert" on public.user_plans
  for insert to authenticated with check (user_id = auth.uid());

create policy "user_plans_own_update" on public.user_plans
  for update to authenticated using (user_id = auth.uid());

-- ------------------------------------------------------------
-- REFERRAL_CODES (código único por usuário)
-- ------------------------------------------------------------
create table if not exists public.referral_codes (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users(id) on delete cascade unique,
  code                  text not null unique,
  indicacoes_validadas  int not null default 0,
  criado_em             timestamptz not null default now()
);

alter table public.referral_codes enable row level security;

create policy "referral_codes_own_select" on public.referral_codes
  for select to authenticated using (user_id = auth.uid());

create policy "referral_codes_own_insert" on public.referral_codes
  for insert to authenticated with check (user_id = auth.uid());

-- ------------------------------------------------------------
-- REFERRALS (registro de indicações)
-- ------------------------------------------------------------
create table if not exists public.referrals (
  id              uuid primary key default gen_random_uuid(),
  referrer_id     uuid not null references auth.users(id) on delete cascade,
  referred_id     uuid not null references auth.users(id) on delete cascade,
  code            text not null,
  status          text not null default 'pendente'
                  check (status in ('pendente','validada','expirada')),
  criado_em       timestamptz not null default now(),
  validado_em     timestamptz,
  expira_em       timestamptz not null
);

alter table public.referrals enable row level security;

create policy "referrals_own_select" on public.referrals
  for select to authenticated using (referrer_id = auth.uid());

create policy "referrals_own_insert" on public.referrals
  for insert to authenticated with check (referrer_id = auth.uid());

-- ------------------------------------------------------------
-- PG_CRON — expiração diária de planos (00:00 UTC)
-- Requer extensão pg_cron ativa no Supabase Dashboard
-- ------------------------------------------------------------
-- select cron.schedule('expire-plans', '0 0 * * *', $$
--   update public.user_plans set ativo = false
--   where ativo = true and expira_em < now();
-- $$);

-- ============================================================
-- FIM — SoloForte DB Setup completo (v13 — ADR-012)
-- ============================================================
