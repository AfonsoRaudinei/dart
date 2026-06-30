# PROMPT — Atualizar `ARCH_BASELINE_v1.1_SCORE_90.md` com módulo `planos/`

**Tipo:** Atualização documental — sem alteração de código  
**Arquivo alvo:** `docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md`  
**ADR de referência:** ADR-012-MODULO-PLANOS  
**Risco:** BAIXO — apenas documentação  

---

## OBJETIVO

Atualizar o ARCH_BASELINE para registrar formalmente o bounded context
`planos/` como módulo estrutural do SoloForte, refletindo o estado real
do código já implementado.

---

## REGRAS

- Não alterar nenhuma garantia arquitetural existente
- Não alterar score (90 se mantém — planos/ não quebrou nenhuma garantia)
- Não remover nenhuma seção existente
- Apenas adicionar o que está faltando

---

## ALTERAÇÃO 1 — Seção de Bounded Contexts (Seção 4)

Localizar a lista/tabela de bounded contexts existentes.
Adicionar `planos/` após `settings / auth`:

```markdown
### `planos/`
**Natureza:** Módulo de monetização — folha na árvore de dependências  
**Responsabilidade:** Planos pagos (Bronze/Prata/Ouro), pagamentos via
Mercado Pago (PIX + Cartão), sistema de indicações com upgrade automático
e controle de visibilidade de marketing cases no mapa  
**Stack:** Supabase (fonte da verdade remota) + Edge Functions Deno/TS  
**Acoplamentos de entrada:** `marketing/` (verifica plano), `map/` (badge SideMenu)  
**Acoplamentos de saída:** nenhum — não depende de outros módulos  
**ADR:** ADR-012-MODULO-PLANOS  
**Status:** IMPLEMENTADO — v1.2  
```

---

## ALTERAÇÃO 2 — Seção de Métricas / Estado atual (Seção 2)

Localizar onde o baseline lista módulos implementados.
Adicionar linha para `planos/`:

```markdown
| `planos/`     | Implementado | ADR-012 | v1.2 | Supabase online-only |
```

---

## ALTERAÇÃO 3 — Seção de Garantias (Seção 5)

Localizar a tabela de garantias arquiteturais.
Adicionar nova linha:

```markdown
| `planos/` é folha — não depende de módulos de domínio | ✅ |
| Edge Functions Mercado Pago deployadas em supabase/functions/ | ✅ |
```

---

## ALTERAÇÃO 4 — Atualizar versão do baseline no cabeçalho

Localizar o cabeçalho do documento. Atualizar:

```markdown
**Versão:** v1.2  
**Última atualização:** 28/02/2026  
**Módulos registrados:** core, map, drawing, agenda, operacao, consultoria,
settings, auth, marketing, planos  
```

> ⚠️ Não alterar o Score (90). Não alterar o commit hash de referência.
> Não alterar o campo Branch. Apenas os campos acima.

---

## ALTERAÇÃO 5 — Registrar ADR-013 na lista de ADRs ativos

Localizar onde o baseline lista os ADRs vigentes.
Adicionar:

```markdown
| ADR-013 | RELATORIOS-DOMAIN | Submódulo relatorios/ em consultoria/ | ATIVO |
```

---

## VALIDAÇÃO FINAL

- [ ] Score continua 90
- [ ] Commit hash não foi alterado
- [ ] `planos/` aparece na seção de bounded contexts
- [ ] `planos/` aparece na tabela de métricas
- [ ] Garantias de `planos/` adicionadas
- [ ] ADR-013 registrado
- [ ] Versão atualizada para v1.2
- [ ] Nenhum arquivo de código foi tocado
