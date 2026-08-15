# Prompts do agente — regras gerais + Coluna direita do mapa

## REGRA-ENTREGA-1 — Toda correção precisa chegar na `main` (no app)

> Vale para **qualquer** prompt executado neste repositório (bug fix, feature, doc, ajuste
> de layout), não só para o tema abaixo. Fonte da verdade: `AGENTS.md` (raiz) e
> `.agent/AGENT_REGRAS.md`.

**Nunca** considerar uma tarefa concluída com o código parado numa branch de feature
(`cursor/...`). Commit + push numa branch é só o meio do caminho — a correção **só está
no aplicativo** depois do merge na `main` remota.

Checklist obrigatório antes de encerrar QUALQUER resposta que tenha alterado código:

```bash
# 1) validar
./tool/arch_check.sh && flutter analyze lib/ && flutter test

# 2) commit por arquivo + push da branch
git push -u origin <branch>

# 3) merge obrigatório na main (nunca pular)
git checkout main && git pull origin main
git merge <branch> && git push origin main

# 4) provar que a correção está na main
git fetch origin --quiet
git branch --contains <sha-do-fix> -a   # deve listar "main" / "remotes/origin/main"
```

Se o passo 4 não listar `main`, a tarefa **não está pronta** — o agente deve mergear
antes de responder "correção feita".

---

# Prompt — Coluna direita do mapa (REGRA-MAP-CHROME-1)

## Status IPA

| IPA | Travamento inset | Posição canônica (imagem) |
|---|---|---|
| **208** | ❌ | ❌ `mapSheetChromeInsetProvider` |
| **209** | ✅ | ❌ spacing uniforme 12px — coluna ~26px abaixo do layout correto |
| **210+** | ✅ | ✅ gaps 26dp (camadas↔+) e 16dp (+↔check-in) |

## Verdade visual (referência imagem Porto Nacional)

Coluna fixa na direita, de cima para baixo:

1. Camadas (layers)
2. + (ações)
3. Check-in
4. SmartButton ☰ (AppShell — não mover)

```
bottom coluna = kMapActionColumnBottomInset + safeBottom  (= kFabSafeArea + safeBottom)
gap + ↔ check-in = kMapActionColumnSpacingAboveCheckIn (16)
gap camadas ↔ + = kMapActionColumnSpacingAboveActions (26)
offset camadas.bottom − check-in.bottom = 130dp
```

**Proibido:** `mapSheetChromeInsetProvider` em `map_controls_overlay.dart`.

## Validação

```bash
flutter test test/regression/map/controls_overlay_regression_test.dart
./tool/arch_check.sh
```

## MacBook

`git pull origin main` → hot restart ou IPA **210+**.
