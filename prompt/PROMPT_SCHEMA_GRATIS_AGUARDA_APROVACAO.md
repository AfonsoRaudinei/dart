# PRD Item 8 — Schema / servidor grátis (PARAR — aguarda aprovação escrita)

**Não executar código nem migration Supabase até o Raudinei responder «APROVO SCHEMA GRÁTIS» neste chat.**

---

## Objetivo (decisão já tomada no PRD)

- Grátis bronze: **2 meses**, **5 cases**
- Expiração e limite com **data do servidor**, não do relógio do aparelho
- Novo grátis só **12 meses após o fim** do grátis anterior
- App **não** insere em `user_plans` hoje (policy) — linha nasce no **cadastro no servidor**

---

## Entregáveis (após aprovação)

1. ADR + migration Supabase (`user_plans`, cron, função signup)
2. App: ler plano só de fonte confiável (sem `UserPlan.free` 9999 como produção)
3. Testes contrato + regressão Prompt 10/11
4. PR separado · **sem** Billing (item 11 futuro)

---

## Perguntas a fechar antes do prompt executor

1. Case novo com plano expirado: **bloquear** publicar? (sugestão PRD: sim, «sem plano»)
2. Texto final de bloqueio na UI
3. Autorização leitura Supabase (#7) para baseline de dados

---

## Status

⬜ **Bloqueado** — próximo passo automático após aprovação escrita + respostas acima.
