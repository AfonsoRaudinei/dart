# Supabase Manual — SoloForte

> **Guia passo a passo** para configurar o banco de dados Supabase do SoloForte Dart
> diretamente pelo Dashboard, sem precisar abrir arquivos do repositório.

---

## 1. Informações do Projeto

| Campo | Valor |
|---|---|
| **Project URL** | `https://pyoejhhkjlrjijiviryq.supabase.co` |
| **Anon Key** | Obter em **Project Settings → API → Project API keys → anon public** |
| **Repositório SQL** | https://github.com/AfonsoRaudinei/dart (branch `main`) |

> ⚠️ **Importante:** A **anon key** é uma chave pública segura para uso no app mobile
> (protegida pelo RLS no backend). Use-a via `--dart-define` no Flutter.
> **Nunca use a `service_role` key no código do app Flutter** — ela bypassa o RLS.

---

## 2. Ordem de Execução no SQL Editor

Execute os scripts **nesta ordem exata** — dependências de tabelas e funções exigem sequência:

```
1. supabase_schema.sql              → cria 7 tabelas + RLS
2. supabase/auth_delete_account.sql → cria RPC delete_own_account()
3. supabase/feedback_table.sql      → cria tabela feedback
4. Queries de verificação
5. Configurar Auth no Dashboard
6. (Opcional) Criar conta demo
7. flutter run local
```

**Por que esta ordem:**

- **Script 1** cria as 7 tabelas base (`clients`, `farms`, `fields`, `visit_sessions`, `occurrences`, `visit_reports`, `agenda_events`) com RLS habilitado. Os scripts 2 e 3 dependem deste schema.
- **Script 2** cria a função RPC `delete_own_account()` chamada por `lib/core/auth/auth_service.dart`. Sem ela, o botão "Excluir conta" em Configurações lança erro `RPC not found`.
- **Script 3** cria a tabela `feedback` usada pela tela de feedback do app. Deve rodar após o schema base para herdar as políticas de usuário autenticado.

---

## 3. Script 1 — Schema Principal (`supabase_schema.sql`)

### O que faz

Cria 7 tabelas relacionais com soft delete, habilita RLS em todas e cria políticas de acesso para usuários autenticados.

**Tabelas criadas:** `clients`, `farms`, `fields`, `visit_sessions`, `occurrences`, `visit_reports`, `agenda_events`

### Como executar

1. Acesse **SQL Editor** no menu lateral esquerdo
2. Clique em **New query** (botão `+` ou ícone de nova query)
3. Cole o SQL abaixo
4. Clique em **Run** (ou `Cmd+Enter` / `Ctrl+Enter`)

### SQL completo

```sql
-- ============================================================
-- SoloForte — Schema Principal
-- Executar PRIMEIRO no SQL Editor do Supabase
-- Seguro para re-executar (usa IF NOT EXISTS e DROP IF EXISTS)
-- ============================================================

-- 1. Tabelas

CREATE TABLE IF NOT EXISTS public.clients (
  id           UUID PRIMARY KEY,
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
  cliente_id   UUID NOT NULL REFERENCES public.clients(id),
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
  fazenda_id      UUID NOT NULL REFERENCES public.farms(id),
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
  id           UUID PRIMARY KEY,
  cliente_id   UUID REFERENCES public.clients(id),
  fazenda_id   UUID REFERENCES public.farms(id),
  field_id     UUID REFERENCES public.fields(id),
  data_visita  DATE,
  status       TEXT,
  notas        TEXT,
  created_at   TIMESTAMPTZ NOT NULL,
  updated_at   TIMESTAMPTZ NOT NULL,
  deleted_at   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.occurrences (
  id               UUID PRIMARY KEY,
  visit_session_id UUID REFERENCES public.visit_sessions(id),
  tipo             TEXT,
  descricao        TEXT,
  severidade       TEXT,
  geo              JSONB,
  fotos            JSONB,
  created_at       TIMESTAMPTZ NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL,
  deleted_at       TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.visit_reports (
  id               UUID PRIMARY KEY,
  visit_session_id UUID REFERENCES public.visit_sessions(id),
  resumo           TEXT,
  recomendacoes    TEXT,
  assinatura_url   TEXT,
  created_at       TIMESTAMPTZ NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL,
  deleted_at       TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.agenda_events (
  id           UUID PRIMARY KEY,
  titulo       TEXT NOT NULL,
  descricao    TEXT,
  data_inicio  TIMESTAMPTZ NOT NULL,
  data_fim     TIMESTAMPTZ,
  cliente_id   UUID REFERENCES public.clients(id),
  fazenda_id   UUID REFERENCES public.farms(id),
  created_at   TIMESTAMPTZ NOT NULL,
  updated_at   TIMESTAMPTZ NOT NULL,
  deleted_at   TIMESTAMPTZ
);

-- 2. Habilitar RLS

ALTER TABLE public.clients        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farms          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fields         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.occurrences    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_reports  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_events  ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de acesso (DROP IF EXISTS garante re-execução segura)

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.clients;
CREATE POLICY "Enable all for authenticated users" ON public.clients
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.farms;
CREATE POLICY "Enable all for authenticated users" ON public.farms
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.fields;
CREATE POLICY "Enable all for authenticated users" ON public.fields
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.visit_sessions;
CREATE POLICY "Enable all for authenticated users" ON public.visit_sessions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.occurrences;
CREATE POLICY "Enable all for authenticated users" ON public.occurrences
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.visit_reports;
CREATE POLICY "Enable all for authenticated users" ON public.visit_reports
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.agenda_events;
CREATE POLICY "Enable all for authenticated users" ON public.agenda_events
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
```

### Resultado esperado

```
Success. No rows returned.
```

### Erros comuns

| Erro | Causa | Solução |
|---|---|---|
| `relation "clients" already exists` | Tabela já criada | `IF NOT EXISTS` ignora — continue |
| `policy already exists` | Política duplicada | Os `DROP POLICY IF EXISTS` resolvem — re-execute |
| `permission denied` | Role incorreta | Execute como `postgres` (padrão no SQL Editor) |

---

## 4. Script 2 — Exclusão de Conta (`supabase/auth_delete_account.sql`)

### O que faz

Cria a função RPC `delete_own_account()` no schema `public` com `SECURITY DEFINER`.
Essa função é chamada pelo app em **Configurações → Excluir conta**.

**Chamado em:** `lib/core/auth/auth_service.dart`

### Como executar

1. No **SQL Editor**, clique em **New query**
2. Cole o SQL abaixo
3. Clique em **Run**

### SQL completo

```sql
-- ============================================================
-- SoloForte — RPC: delete_own_account
-- Executar SEGUNDO no SQL Editor do Supabase
-- Permite que o usuário exclua a própria conta pelo app
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _uid UUID := auth.uid();
BEGIN
  -- Remove dados nas tabelas públicas (ordem: filhos antes dos pais)
  DELETE FROM public.occurrences
    WHERE visit_session_id IN (
      SELECT id FROM public.visit_sessions WHERE cliente_id = _uid
    );

  DELETE FROM public.visit_reports
    WHERE visit_session_id IN (
      SELECT id FROM public.visit_sessions WHERE cliente_id = _uid
    );

  DELETE FROM public.visit_sessions WHERE cliente_id = _uid;

  DELETE FROM public.fields
    WHERE fazenda_id IN (
      SELECT id FROM public.farms WHERE cliente_id = _uid
    );

  DELETE FROM public.farms        WHERE cliente_id = _uid;
  DELETE FROM public.agenda_events WHERE cliente_id = _uid;
  DELETE FROM public.clients      WHERE id = _uid;
  DELETE FROM public.feedback     WHERE user_id = _uid;

  -- Remove a conta do Auth (requer SECURITY DEFINER)
  DELETE FROM auth.users WHERE id = _uid;
END;
$$;

-- Conceder execução apenas para usuários autenticados
REVOKE EXECUTE ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
```

### Resultado esperado

```
Success. No rows returned.
```

### Erros comuns

| Erro | Causa | Solução |
|---|---|---|
| `RPC delete_own_account not found` no app | Script não executado | Execute este script |
| `permission denied for table users` | SECURITY DEFINER faltando | Confirme que copiou o script completo |
| `table "feedback" does not exist` | Script 3 não executado | Execute o Script 3 e re-execute este |

---

## 5. Script 3 — Tabela Feedback (`supabase/feedback_table.sql`)

### O que faz

Cria a tabela `feedback` com RLS. Cada usuário autenticado só vê e insere o próprio feedback.

**Usado em:** `lib/modules/feedback/presentation/screens/feedback_screen.dart`

### Como executar

1. No **SQL Editor**, clique em **New query**
2. Cole o SQL abaixo
3. Clique em **Run**

### SQL completo

```sql
-- ============================================================
-- SoloForte — Tabela: feedback
-- Executar TERCEIRO no SQL Editor do Supabase
-- ============================================================

CREATE TABLE IF NOT EXISTS public.feedback (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo        TEXT        NOT NULL,  -- 'bug' | 'sugestao' | 'elogio' | 'outro'
  mensagem    TEXT        NOT NULL,
  plataforma  TEXT,                  -- 'ios' | 'android'
  app_version TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

-- Política: cada usuário gerencia apenas o próprio feedback
DROP POLICY IF EXISTS "Users manage own feedback" ON public.feedback;
CREATE POLICY "Users manage own feedback" ON public.feedback
  FOR ALL TO authenticated
  USING    (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_feedback_user_id    ON public.feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON public.feedback(created_at DESC);
```

### Resultado esperado

```
Success. No rows returned.
```

### Erros comuns

| Erro | Causa | Solução |
|---|---|---|
| `relation "feedback" already exists` | Tabela já existe | `IF NOT EXISTS` ignora — continue |
| `Feedback insert failed` no app | Script não executado | Execute este script |
| `new row violates row-level security` | `user_id` nulo ou errado | Confirme que o app envia `auth.uid()` |

---

## 6. Queries de Verificação

Execute após os 3 scripts para confirmar instalação correta.

### No SQL Editor — New query

```sql
-- ============================================================
-- Verificação: 8 tabelas, 1 função, RLS ativo
-- Critério de sucesso:
--   • 8 linhas em pg_tables
--   • 1 linha em pg_proc (delete_own_account)
--   • relrowsecurity = true nas amostras
-- ============================================================

-- 1. Tabelas esperadas (deve retornar 8 linhas)
SELECT tablename
FROM   pg_tables
WHERE  schemaname = 'public'
  AND  tablename IN (
         'clients','farms','fields','visit_sessions',
         'occurrences','visit_reports','agenda_events','feedback'
       )
ORDER BY tablename;

-- 2. Função de exclusão de conta (deve retornar 1 linha)
SELECT proname
FROM   pg_proc
WHERE  proname = 'delete_own_account';

-- 3. RLS ativo em amostra de tabelas (relrowsecurity deve ser true)
SELECT relname, relrowsecurity
FROM   pg_class
WHERE  relname IN ('clients','occurrences','feedback');
```

### Critério de sucesso

- **Query 1:** 8 linhas (uma por tabela)
- **Query 2:** 1 linha com `delete_own_account`
- **Query 3:** 3 linhas, todas com `relrowsecurity = true`

Se alguma tabela faltar → re-execute o Script 1.
Se a função faltar → re-execute o Script 2.
Se `feedback` faltar → re-execute o Script 3.

---

## 7. Configuração do Auth no Dashboard

### 7.1 — Email Provider

1. Menu lateral → **Authentication → Providers**
2. Clique em **Email**
3. Configure conforme o ambiente:

| Configuração | Desenvolvimento | Produção / Review |
|---|---|---|
| **Confirm email** | **Desabilitado** → login imediato | **Habilitado** → confirmar por e-mail |
| **Secure email change** | Opcional | Recomendado |

> Em **desenvolvimento**, desabilitar "Confirm email" permite testar login imediatamente
> após o signup sem precisar verificar a caixa de entrada.

### 7.2 — Confirmar usuário manualmente (quando confirmação ativa)

1. **Authentication → Users**
2. Encontre o usuário pelo e-mail
3. Clique em **...** → **Send confirmation email** ou **Confirm email manually**

### 7.3 — Criar conta demo para revisores da loja

1. **Authentication → Users → Add user → Create new user**
2. Preencha:
   - **Email:** `review@soloforte.app`
   - **Password:** (ver `docs/store/CONTA_DEMO_REVIEW.md`)
3. Marque **Auto confirm user**
4. Clique em **Create user**

### 7.4 — Copiar a Anon Key

1. **Project Settings → API**
2. Em **Project API keys**, copie **anon public**
3. Use no comando Flutter (próxima seção)

---

## 8. Comando Flutter (variáveis de ambiente)

Substitua apenas `COLE_SUA_ANON_KEY_AQUI` pela chave copiada no passo 7.4:

```bash
# Instalar dependências
flutter pub get

# Executar com Supabase configurado
flutter run \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=COLE_SUA_ANON_KEY_AQUI
```

### Variáveis opcionais (definidas em `lib/core/config/app_config.dart`)

| Variável `--dart-define` | Default (fallback) | Uso no app |
|---|---|---|
| `PRIVACY_POLICY_URL` | URL GitHub raw | Tela Política de Privacidade |
| `TERMS_URL` | URL GitHub raw | Tela Termos de Uso |
| `LGPD_CONTACT_EMAIL` | e-mail padrão | Botão "Falar com DPO" |

```bash
# Exemplo completo com todas as variáveis
flutter run \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY \
  --dart-define=PRIVACY_POLICY_URL=https://seudominio.com/privacidade \
  --dart-define=TERMS_URL=https://seudominio.com/termos \
  --dart-define=LGPD_CONTACT_EMAIL=dpo@seudominio.com
```

### Comportamento sem `--dart-define`

O app inicia normalmente com funcionalidades limitadas (`AppConfig.hasSupabaseConfig == false`):

| Funcionalidade | Sem `--dart-define` | Com `--dart-define` |
|---|---|---|
| Login / Cadastro | Desabilitado | Habilitado |
| Sync de dados | Desabilitado | Habilitado |
| Feedback Supabase | Desabilitado | Habilitado |
| Feedback offline (mailto) | Funciona | Funciona |

---

## 9. Testes Funcionais após Configurar

| Ação no app | Depende de | Resultado esperado |
|---|---|---|
| Login / Cadastro | URL + Anon Key + Auth habilitado | Entra no app com sucesso |
| Sync de clientes/visitas | Script 1 + usuário logado | Dados salvos no Supabase |
| Excluir conta (Configurações) | Script 2 | Conta removida completamente |
| Enviar feedback | Script 3 + login | Feedback inserido na tabela |
| Feedback offline (e-mail) | `LGPD_CONTACT_EMAIL` | Abre app de e-mail |
| Política de Privacidade | `PRIVACY_POLICY_URL` | Abre URL configurada |

---

## 10. Fora do Supabase — Referência Rápida

| Ação | Onde fazer | Documentação |
|---|---|---|
| Android keystore / `key.properties` | Local — máquina do dev | `docs/BUILD_RELEASE.md` |
| Certificado iOS Distribution | Xcode local | `docs/BUILD_RELEASE.md` |
| URLs legais em HTTPS próprio | Seu hosting/domínio | `docs/legal/` |
| Smoke test completo | Dispositivo físico / emulador | `docs/SMOKE_TEST_CHECKLIST.md` |
| Submissão às lojas | App Store Connect / Google Play | `docs/store/GUIA_SUBMISSAO.md` |

---

## 11. Troubleshooting

### "Supabase não configurado" no app

**Causa:** Faltam as variáveis `--dart-define` no comando `flutter run`.
**Solução:** Execute com `--dart-define=SUPABASE_URL=...` e `--dart-define=SUPABASE_ANON_KEY=...`.

---

### "Conta criada. Confirme seu e-mail."

**Causa:** Confirmação de e-mail está **habilitada** no Auth.
**Solução (dev):** Desabilite em **Authentication → Providers → Email → Confirm email**.
**Solução (prod):** Confirme manualmente em **Authentication → Users → ... → Confirm email**.

---

### `RPC delete_own_account not found`

**Causa:** Script 2 não foi executado.
**Solução:** Execute o Script 2 no SQL Editor.

---

### `permission denied` / `RLS violation`

**Causa:** Schema não executado, ou `user_id` do registro não bate com `auth.uid()`.
**Solução:**
1. Re-execute o Script 1 completo
2. Confirme que o usuário está logado no app
3. Verifique as políticas em **Authentication → Policies**

---

### `Feedback insert failed`

**Causa:** Script 3 não executado, ou `user_id` nulo.
**Solução:** Execute o Script 3 e confirme que o app envia `auth.uid()` no campo `user_id`.

---

### `relation "X" does not exist`

**Causa:** Scripts executados em ordem errada ou incompletos.
**Solução:** Execute na ordem Script 1 → Script 2 → Script 3. Todos usam `IF NOT EXISTS` / `CREATE OR REPLACE` — re-executar é seguro.

---

## Referências

- [Supabase Dashboard — SoloForte](https://supabase.com/dashboard/project/pyoejhhkjlrjijiviryq)
- [Repositório GitHub](https://github.com/AfonsoRaudinei/dart)
- [Documentação Supabase](https://supabase.com/docs)
- [`docs/BUILD_RELEASE.md`](BUILD_RELEASE.md) — Build Android e iOS release
- [`docs/store/CONTA_DEMO_REVIEW.md`](store/CONTA_DEMO_REVIEW.md) — Conta demo para revisores
