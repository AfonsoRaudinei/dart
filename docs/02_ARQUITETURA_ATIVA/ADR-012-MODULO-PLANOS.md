# ADR-012 — Módulo `planos/` — Sistema de Planos, Pagamentos e Indicações

**Data:** 28/02/2026  
**Status:** APROVADO — base para implementação  
**Autor:** Engenheiro Sênior SoloForte  
**Referência PRD:** PRD-Planos-v2.0  
**Baseline afetada:** `ARCH_BASELINE_v1.1_SCORE_90.md` → deve ser atualizada após aprovação  

---

## 1. CONTEXTO

O SoloForte possui um módulo de marketing cases (`marketing/`) que exige um sistema de
autorização por plano pago. Atualmente não existe bounded context para planos, pagamentos
ou indicações. O PRD-Planos-v2.0 define as regras completas de negócio.

Este ADR formaliza a criação do bounded context `planos/` e seus acoplamentos autorizados.

---

## 2. DECISÃO

### 2.1 Criar bounded context `planos/`

Novo módulo em `lib/modules/planos/` com estrutura Clean Architecture:

```
lib/modules/planos/
├── domain/
│   ├── entities/
│   │   ├── user_plan.dart
│   │   └── referral.dart
│   └── enums/
│       ├── plano_tipo.dart        # bronze | prata | ouro
│       └── plano_origem.dart      # pagamento | indicacao
├── data/
│   ├── repositories/
│   │   ├── i_plano_repository.dart
│   │   └── plano_repository_impl.dart
│   └── services/
│       ├── mercadopago_service.dart
│       └── referral_service.dart
└── presentation/
    ├── providers/
    │   └── plano_providers.dart
    └── screens/
        ├── planos_screen.dart
        ├── pagamento_screen.dart
        ├── confirmacao_screen.dart
        ├── meu_plano_screen.dart
        └── indicacoes_screen.dart
```

### 2.2 Fronteiras de acoplamento

| De | Para | Status |
|---|---|---|
| `planos/` | qualquer outro módulo | ❌ PROIBIDO |
| `marketing/` | `planos/` | ✅ PERMITIDO — verificação de plano antes de publicar |
| `map/` (SideMenu) | `planos/` | ✅ PERMITIDO — exibição de badge no menu lateral |
| `planos/` | Supabase (remote) | ✅ PERMITIDO — fonte da verdade para planos |

`planos/` é folha na árvore de dependências. Não depende de nenhum outro módulo de domínio.

### 2.3 Rotas adicionadas ao `app_router.dart`

```
/planos                → PlanosScreen
/planos/pagamento      → PagamentoScreen
/planos/confirmacao    → ConfirmacaoScreen
/planos/meu-plano      → MeuPlanoScreen
/planos/indicacoes     → IndicacoesScreen
```

Todas as navegações usam `context.go()`. Nunca `context.pop()`.

### 2.4 Provider keepAlive

`planoAtivoProvider` declarado como `@Riverpod(keepAlive: true)` — o status do plano
deve sobreviver ao dispose de telas para que `marketing/` e `map/` possam consultá-lo
sem re-fetch.

---

## 3. CONTRATO DE DADOS

### Entidade `UserPlan`

```dart
class UserPlan {
  final String id;
  final String userId;
  final PlanoTipo plano;         // bronze | prata | ouro
  final PlanoOrigem origem;      // pagamento | indicacao
  final bool ativo;
  final DateTime iniciouEm;
  final DateTime expiraEm;
  final String? paymentId;       // null se origem == indicacao
  final DateTime criadoEm;
}
```

### Entidade `Referral`

```dart
class Referral {
  final String id;
  final String referrerId;
  final String referredId;
  final String code;
  final ReferralStatus status;   // pendente | validada | expirada
  final DateTime criadoEm;
  final DateTime? validadoEm;
  final DateTime expiraEm;       // criadoEm + 30 dias
}
```

### Enums

```dart
enum PlanoTipo { bronze, prata, ouro }
enum PlanoOrigem { pagamento, indicacao }
enum ReferralStatus { pendente, validada, expirada }
```

### Interface de repositório

```dart
abstract class IPlanoRepository {
  Future<UserPlan?> getPlanoAtivo(String userId);
  Future<UserPlan> ativarPlano(UserPlan plano);
  Future<List<Referral>> getReferrals(String referrerId);
  Stream<UserPlan?> watchPlanoAtivo(String userId);  // Supabase Realtime
}
```

**Fonte da verdade:** Supabase (remoto). Sem cache SQLite para planos — requer conectividade
para verificação de plano ativo. Esta é uma decisão explícita: publicar cases é fluxo
online-only.

---

## 4. SCHEMA SUPABASE

```sql
-- Planos ativos
CREATE TABLE user_plans (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id),
  plano         TEXT NOT NULL CHECK (plano IN ('bronze','prata','ouro')),
  origem        TEXT NOT NULL CHECK (origem IN ('pagamento','indicacao')),
  ativo         BOOLEAN NOT NULL DEFAULT true,
  iniciou_em    TIMESTAMPTZ NOT NULL DEFAULT now(),
  expira_em     TIMESTAMPTZ NOT NULL,
  payment_id    TEXT,
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user sees own plan" ON user_plans
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- Códigos de indicação
CREATE TABLE referral_codes (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
  code                  TEXT NOT NULL UNIQUE,
  indicacoes_validadas  INT NOT NULL DEFAULT 0,
  criado_em             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Registro de indicações
CREATE TABLE referrals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id     UUID NOT NULL REFERENCES auth.users(id),
  referred_id     UUID NOT NULL REFERENCES auth.users(id),
  code            TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'pendente'
                  CHECK (status IN ('pendente','validada','expirada')),
  criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
  validado_em     TIMESTAMPTZ,
  expira_em       TIMESTAMPTZ NOT NULL
);
```

---

## 5. GATEWAY DE PAGAMENTO

**Provedor:** Mercado Pago  
**Métodos:** PIX (aprovação instantânea) + Cartão crédito/débito  
**Integração:** SDK Mercado Pago Flutter + Edge Function webhook  

### Edge Function: `mercadopago-webhook`

```
POST /functions/v1/mercadopago-webhook
  → valida assinatura HMAC
  → se approved → ativa user_plans + verifica indicação + verifica upgrade
  → se rejected → push notificação de falha
```

### pg_cron — expiração diária

```sql
-- Roda 00:00 UTC diariamente
SELECT cron.schedule('expire-plans', '0 0 * * *', $$
  UPDATE user_plans SET ativo = false
  WHERE ativo = true AND expira_em < now();
$$);
```

---

## 6. LÓGICA DE UPGRADE POR INDICAÇÕES

```
Bronze (indicacoes_validadas >= 5):
  → plano = 'prata', expira_em = now() + interval '5 months'
  → indicacoes_validadas = 0
  → push: upgrade para Prata

Prata (indicacoes_validadas >= 10):
  → plano = 'ouro', expira_em = now() + interval '8 months'
  → indicacoes_validadas = 0
  → push: upgrade para Ouro
```

**Regras da cadeia:**
- Bronze pago = ponto de entrada obrigatório (sem Bronze, sem indicações)
- Bronze → Ouro direto por indicações: ❌ NÃO EXISTE
- Indicações do Bronze NÃO acumulam para Prata (reseta ao subir)
- Indicação válida = cadastro com código + pagamento de qualquer plano em até 30 dias

---

## 7. INTEGRAÇÃO COM `marketing/`

Ao tentar publicar um case, `marketing/` consulta `planoAtivoProvider`:

```dart
// Em marketing/ — verificação antes de abrir NovoCaseSheet
final plano = ref.watch(planoAtivoProvider);

if (plano == null) {
  // sem plano → bottom sheet de bloqueio → /planos
} else if (casesAtivos >= plano.limiteCases) {
  // limite atingido → bottom sheet de upgrade ou limite Ouro
} else {
  // abre NovoCaseSheet normalmente
}
```

Limites por plano:
- Bronze: 1 case ativo no mapa
- Prata: 2 cases ativos no mapa
- Ouro: 3 cases ativos no mapa

---

## 8. INTEGRAÇÃO COM `map/` (SideMenu)

O SideMenu adiciona dois itens condicionais:

```
🏅 Meu Plano    Bronze · 47 dias restantes   (sempre visível se autenticado)
👥 Indicações   3/5 para Prata               (visível só em Bronze ou Prata ativo)
```

Estados do item "Meu Plano":
- Sem plano: "Sem plano · Publicar cases" → `/planos`
- Ativo: "Bronze · 47 dias restantes"
- Expirando (≤7 dias): texto vermelho "⚠️ Expira em 3 dias"
- Expirado: "Plano expirado · Renovar" → `/planos`

---

## 9. NOTIFICAÇÕES PUSH

| Gatilho | Mensagem |
|---|---|
| 7 dias antes | "Seu plano expira em 7 dias" |
| 1 dia antes | "Seu plano expira amanhã" |
| No dia | "Seu plano expirou — seus cases saíram do mapa" |
| Upgrade Prata | "Parabéns! Você ganhou Prata por 5 indicações!" |
| Upgrade Ouro | "Parabéns! Você ganhou Ouro por 10 indicações!" |
| Pagamento rejeitado | "Pagamento não aprovado. Tente novamente." |

---

## 10. REGRAS DE VISIBILIDADE DE PINS

| Plano | Cases ativos no mapa | Visível sem login |
|---|---|---|
| Bronze | 1 | Não |
| Prata | 2 | Não |
| Ouro | 3 | Sim |

Ao expirar: pins somem do mapa imediatamente. Cases permanecem no banco.  
Ao reativar: pins voltam imediatamente após confirmação de pagamento.  
Períodos não acumulam — novo período começa do zero.

---

## 11. ESTADO RIVERPOD

```dart
// keepAlive — consultado por marketing/ e map/ sem re-fetch
@Riverpod(keepAlive: true)
Future<UserPlan?> planoAtivo(PlanoAtivoRef ref) async { ... }

// autoDispose — usado apenas nas telas de planos/
@riverpod
Future<List<Referral>> referrals(ReferralsRef ref) async { ... }

@riverpod
Future<ReferralCode?> meuCodigoIndicacao(MeuCodigoIndicacaoRef ref) async { ... }
```

---

## 12. ORDEM DE EXECUÇÃO

```
PASSO 1  → Supabase: tabelas user_plans + referral_codes + referrals + RLS + pg_cron
PASSO 2  → Edge Function: mercadopago-webhook
PASSO 3  → Domínio: entidades + enums + IPlanoRepository em planos/domain/
PASSO 4  → Data: PlanoRepositoryImpl + MercadoPagoService + ReferralService
PASSO 5  → Providers: planoAtivoProvider (keepAlive) + autoDispose providers
PASSO 6  → Telas: /planos, /pagamento, /confirmacao, /meu-plano, /indicacoes
PASSO 7  → app_router.dart: registrar 5 rotas novas
PASSO 8  → SideMenu (map/): adicionar "Meu Plano" e "Indicações"
PASSO 9  → Integração marketing/: bloquear publicação sem plano
PASSO 10 → Notificações push de expiração
```

---

## 13. CHECKLIST PRÉ-IMPLEMENTAÇÃO

```
[x] Lido: 00_INDEX_OFICIAL.md
[x] Lido: ARCH_BASELINE_v1.1_SCORE_90.md
[x] Lido: bounded_contexts.md
[x] Módulo afetado declarado: planos/ (NOVO)
[x] Altera contrato de interface? SIM → IPlanoRepository criada
[x] Altera fronteira entre módulos? SIM → marketing/ e map/ dependem de planos/
[x] ADR criado: ADR-012-MODULO-PLANOS.md ← este documento
[ ] Executar: tool/arch_check.sh → deve passar
[ ] Atualizar: ARCH_BASELINE_v1.1_SCORE_90.md (Seção 4 — Bounded Contexts)
[ ] Atualizar: bounded_contexts.md (adicionar planos/ + novos acoplamentos)
[ ] Atualizar: 00_INDEX_OFICIAL.md
```

---

## 14. VALIDAÇÃO FINAL (OBRIGATÓRIA APÓS CADA PASSO)

| Verificação | Esperado |
|---|---|
| Dashboard alterado? | NÃO |
| Módulos existentes alterados internamente? | NÃO (apenas imports em marketing/ e map/) |
| Navegação Map-First quebrada? | NÃO — apenas context.go() |
| Tema alterado? | NÃO |
| Contrato de módulos existentes alterado? | NÃO — apenas dependências adicionadas |
| Apenas planos/ + pontos de integração afetados? | SIM |

Se qualquer resposta divergir → rollback parcial do passo.

---

## 15. FORA DO ESCOPO DESTE ADR

- Painel admin para gerenciar planos manualmente
- Reembolso automático
- Plano corporativo (múltiplos usuários)
- Acúmulo de períodos ao renovar antes de expirar
- Upgrade Bronze → Ouro direto por indicações

---

## 16. CONSEQUÊNCIAS

**Positivas:**
- Monetização do app via marketing cases sem cobrar pelo core
- Sistema de indicações como crescimento orgânico
- Bounded context limpo — planos/ é folha, não polui outros módulos

**Negativas / Riscos:**
- `marketing/` passa a depender de `planos/` — acoplamento novo e explícito (mitigado pelo PRD)
- Publicar cases é online-only — usuários sem rede não podem publicar (decisão de negócio aceita)
- Webhook Mercado Pago requer endpoint público — configuração de segurança HMAC obrigatória

**Classificação de risco:** MÉDIO  
Motivo: Novo bounded context com acoplamentos em módulos existentes (`marketing/` e `map/`).
Não quebra contratos existentes — apenas adiciona dependências.

---

*Este ADR é o ponto de entrada obrigatório para qualquer agente implementando o módulo `planos/` no SoloForte App.*
