# SoloForte — cadeado de merge (supervisor)

**Status:** ATIVO — Ago/2026  
**Ruleset:** [SoloForte main gate](https://github.com/AfonsoRaudinei/dart/rules/21199633) (`id` 21199633)  
**O que isto NÃO é:** mais um `.mdc` pedindo bom comportamento.

Prompt define papéis. Mecanismo garante o cadeado.

---

## O que é mecanismo vs o que é prompt

| Camada | O quê | Tipo |
|---|---|---|
| Ruleset `main` | PR obrigatório; bypass vazio (`current_user_can_bypass: never`); só rebase; check obrigatório | Mecânico |
| Settings do repo | Auto-merge ligado; squash e merge commit **desligados** | Mecânico |
| `tool/hooks/pre-push` | Recusa push para `main` e `release/*` | Mecânico (local) |
| `arch_check.sh` + job no PR | Fronteiras | Mecânico |
| Revisor LLM (DIFF) | P0/P1 / No findings | Prompt |
| Path crítico pede ok no chat | drawing, agenda, DB, sheets, map chrome | Prompt (leve) |

Não existe `.review-ok` nem trailer de aprovação: quem escreveria o marcador é quem o gate deveria barrar.

---

## Ruleset — verificado na API (não copiado de memória)

GET `repos/AfonsoRaudinei/dart/rulesets/21199633` em 24/Ago/2026 (reconfirmado; criado 22/Ago):

- `enforcement`: `active`
- `bypass_actors`: `[]`
- `current_user_can_bypass`: **`never`** (a conta admin que aplicou **não** fura)
- Check obrigatório (nome da Checks API, confirmado em PRs 61/63): `Verificação de Fronteiras Arquiteturais`
- `allowed_merge_methods`: `["rebase"]`
- **Up to date:** o parâmetro `strict_required_status_checks_policy` **existe** neste ruleset e está **`true`**. Decisão: **ligar**. PRs concorrentes precisam rebase + re-CI antes do merge. Consistente com “CI é o único gate determinístico”.

`on.pull_request` em `.github/workflows/architecture.yml` e `flutter_ci.yml` é load-bearing. Não remover.

---

## Check `analyze-and-test` — fora do ruleset de propósito

Nome na Checks API (PRs 61/63 e commit `08b6786` na `main`): **`analyze-and-test`**.

Não está no ruleset hoje: o job está **vermelho na `main`** (`flutter analyze --fatal-infos`, 24 issues pré-existentes). Exigi-lo agora congelaria todos os merges. Quando o job estiver verde na `main`, adicionar este context ao ruleset. Até lá o gate determinístico de merge é o `arch_check` (`Verificação de Fronteiras Arquiteturais`).

Não exigir os outros jobs do `architecture.yml` (NDVI, coverage, radar, shield).

---

## Papéis

1. **Supervisor** (chat padrão) — não escreve `lib/`; lança executor e revisor; arma `gh pr merge --auto --rebase`; não polla CI.
2. **Executor** (`.cursor/agents/soloforte-executor.md`) — escreve no escopo fechado; push só da branch.
3. **Revisor** (`.cursor/agents/soloforte-revisor.md`) — DIFF read-only.

## Merge por risco

- **Baixo risco** + `No findings` → `--auto --rebase` sem perguntar.
- **Crítico** (pede ok): `lib/modules/drawing/`, `lib/modules/agenda/`, `lib/core/database/`, `lib/core/ui/sheets/`, `lib/ui/screens/map/`, `lib/ui/components/map/`.
- P2/P3 → pede ok. P0/P1 → não mergeia.

## Encerramento (REGRA-ENTREGA-1)

```bash
gh pr view <n> --json state,mergedAt,mergeStateStatus,autoMergeRequest,url
```

- `mergedAt` → entregue (SHA em `origin/main`).
- `autoMergeRequest` vivo → **não entregue:** `auto-merge armado, pendente de CI — ainda não está na main`.
- nulo e não merged → GitHub desarmou. Bloqueio explícito.

Proibido: `git push origin main` · `gh pr merge --admin` · `--squash`.

---

## Hook local (uma vez, humano)

Agentes **não** rodam `git config`. No clone:

```bash
git config core.hooksPath tool/hooks
```

O hook recusa `refs/heads/main` e `refs/heads/release/*`. Não consulta marcador de revisão.

---

## Prova do cadeado

`current_user_can_bypass: never` no GET. Push direto na `main` com a conta admin deve ser rejeitado. Se passar, o ruleset é teatro — corrigir antes de declarar o gate ativo.

**Prova 24/Ago/2026** (conta admin, `git push origin HEAD:main` com commit vazio, depois `reset` local):

```
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Changes must be made through a pull request.
remote: - Required status check "Verificação de Fronteiras Arquiteturais" is expected.
```

Push recusado (`PUSH_EXIT:1`). Settings do repo no mesmo dia: `allow_auto_merge=true`, `allow_rebase_merge=true`, `allow_squash_merge=false`, `allow_merge_commit=false`.
