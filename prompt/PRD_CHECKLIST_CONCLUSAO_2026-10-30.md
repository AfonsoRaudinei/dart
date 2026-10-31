# PRD — Checklist de conclusão (30/10/2026)

**Referência:** entregas do PRD de ações pendentes (Prompt 10 → 6a → Prompt 11).  
**`origin/main`:** verificar com `git log -1 origin/main` após sync.

---

## Escopo código — PRD ações 1–6 + Prompt 11

| # | Entrega | PR | Merge |
|---|---------|-----|-------|
| 1 | Launcher limite central (#333) | #333 | ✅ |
| 2 | Prompt 10 — pin oculto leitura + reconcile | #334 | ✅ |
| 3 | Lote 8 MultiPolygon render | #335 | ✅ (#331 fechado) |
| 4 | Lote 9 hit/viewport/geofence | #337 | ✅ (#332 fechado, estratégia A) |
| 5 | Lote 7 furos drawing | #336 | ✅ |
| 6 | 6a — remover `SELF` | #338 | ✅ |
| 7 | Prompt 11 — «Oculto no mapa» relatório | #340 | ✅ |

**Validação padrão (cada PR):** analyze fatal-infos · testes · `arch_check.sh` Exit 0 · CI verde no merge.

---

## Escopo PRD — fora de código (não 100% automatizável)

| Item | Status | Responsável |
|------|--------|-------------|
| Teste em aparelho (MultiPolygon, furo, offline) | ⬜ Manual | Raudinei |
| Schema grátis 2 meses / expiração servidor | ⬜ Bloqueado — aprovação escrita | Raudinei |
| Play Billing / StoreKit | ⬜ Futuro | — |
| Auditoria 27/10 (B1, B3, C2–C4, D2–D3, E2–E5, pacotes) | ⬜ Não iniciado neste ciclo | PRD §10 |
| Proteção branch `main` GitHub | ⬜ Pendência #8 | Raudinei |
| Texto/ícone Prompt 11 | ✅ «Oculto no mapa», sem ícone | Decidido 30/10 |
| Preços prata/ouro · case com plano expirado · política MultiPolygon drawing | ⬜ Pendências produto | Raudinei |
| Leitura Supabase (contagens / policies) | ⬜ Autorização pendente #7 | Raudinei |

---

## Percentual honesto

| Bloco | Conclusão |
|-------|-----------|
| **PRD ações 1–6 + Prompt 11 (código mergeado)** | **100%** |
| **PRD completo incl. §7–§11 e pendências humanas** | **Parcial** — gates loja, schema, auditoria, GitHub |

---

## Pós-merge Mac

```bash
export DEVELOPER_DIR=/Library/Developer/CommandLineTools
cd /path/to/appdart
git checkout main && git pull --rebase origin main
flutter pub get
git log -1 --oneline
```

**Stash local:** `wip-pre-prompt11` (branch `cursor/sheets-blue-theme-reports-7467`) — recuperar com `git stash list` / `git stash pop` se necessário.

**PR paralelo (fora deste PRD):** #339 sheets tema azul — não mergeado neste ciclo.

---

## SHA de entrega

Atualizar após sync:

```bash
git rev-parse --short origin/main
```
