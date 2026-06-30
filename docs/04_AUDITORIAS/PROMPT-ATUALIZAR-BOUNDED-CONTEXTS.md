# PROMPT — Atualizar `bounded_contexts.md` com módulo `planos/`

**Tipo:** Atualização documental — sem alteração de código  
**Arquivo alvo:** `docs/02_ARQUITETURA_ATIVA/bounded_contexts.md`  
**ADR de referência:** ADR-012-MODULO-PLANOS  
**Risco:** BAIXO — apenas documentação  

---

## OBJETIVO

Atualizar `bounded_contexts.md` para refletir o bounded context `planos/`
já implementado, seus acoplamentos autorizados com `marketing/` e `map/`,
e a regra de que `planos/` é folha na árvore de dependências.

---

## REGRAS

- Não alterar nenhum outro arquivo
- Não alterar fronteiras já existentes
- Não remover nenhuma entrada existente
- Apenas adicionar o que está faltando

---

## ALTERAÇÃO 1 — Adicionar `planos/` no mapa visual de bounded contexts

Localizar o bloco de diagrama ASCII no início do arquivo.
Adicionar `planos/` ao lado de `settings` e `auth` como módulo satélite:

```
┌──────────┐   ┌──────────┐   ┌──────────────┐
│ Settings │   │   Auth   │   │   Planos     │
└──────────┘   └──────────┘   └──────────────┘
```

---

## ALTERAÇÃO 2 — Adicionar definição do bounded context `planos/`

Após a seção `settings / auth`, adicionar nova seção:

```markdown
### `planos/`
**Natureza:** Módulo de monetização  
**Responsabilidade:** Gestão de planos pagos, pagamentos via Mercado Pago
e sistema de indicações com upgrade automático  
**Dependências permitidas:** Supabase (remoto) — sem dependências de outros módulos  
**Regra:** NÃO depende de nenhum módulo de domínio (`consultoria`, `operacao`,
`drawing`, `agenda`, `marketing`)  
**Regra:** `marketing/` pode depender de `planos/` para verificar plano ativo  
**Regra:** `map/` pode depender de `planos/` para exibir badge no SideMenu  
**Nota:** Publicação de cases é fluxo online-only — fonte da verdade é Supabase,
não SQLite  
```

---

## ALTERAÇÃO 3 — Atualizar tabela de acoplamentos autorizados

Localizar a tabela `| De | Para | Status |` e adicionar as três novas linhas:

```markdown
| `planos/`    | qualquer módulo de domínio                          | ❌ PROIBIDO                              |
| `marketing/` | `planos/`                                           | ✅ PERMITIDO — verificação de plano      |
| `map/`       | `planos/`                                           | ✅ PERMITIDO — badge SideMenu            |
```

---

## ALTERAÇÃO 4 — Adicionar em "Alterações Proibidas Sem ADR"

Ao final da seção, adicionar:

```markdown
- Permitir que `planos/` importe módulos de domínio (proibido sem ADR)
- Remover a dependência `marketing/ → planos/` sem ADR
```

---

## VALIDAÇÃO FINAL

- [ ] Nenhuma entrada existente foi removida ou alterada
- [ ] `planos/` aparece no diagrama visual
- [ ] Definição de `planos/` adicionada com fronteiras claras
- [ ] Tabela de acoplamentos tem as 3 novas linhas
- [ ] Nenhum arquivo de código foi tocado
