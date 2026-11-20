# Campo: fluxo Teste (iniciar → foto → mapa)

**Status:** preparado — restauração marcada, código ainda não iniciado neste prompt.  
**Restore tag:** `restore/pre-campo-teste-fluxo-cb61` → `ca0cbd76` (`origin/main` em 19/nov/2026, horário de Araguaína).  
**Branch de trabalho (criar na Fase 1):** `cursor/campo-teste-fluxo-cb61`

## Restaurar se precisar voltar

```bash
git fetch origin
git checkout main
git pull origin main
git reset --hard restore/pre-campo-teste-fluxo-cb61
# ou só inspecionar:
git log -1 restore/pre-campo-teste-fluxo-cb61 --oneline
```

Alterações locais não commitadas (Podfile, linux ephemeral, etc.) não entram na tag — só o commit rastreado.

---

## Problema (campo)

Ordem real: **iniciar teste → tirar foto → gravar área no mapa**.  
Hoje: ferramenta **Teste** está na grade de desenho com talhão/pivô/KML; ficha pede cliente/nome (default “Talhão Novo”); **foto** só em Ocorrência / marketing.

## Objetivo (Fase 1 — mínimo entregável)

Um fluxo único no mapa, sem novo bounded context:

1. **Entrada direta** para modo Teste (menos cliques que a grade completa).
2. **Foto na mesma jornada** antes ou logo após nome do teste (georreferenciada ao ponto da sessão ou do centro do sketch).
3. **Polígono teste** como hoje (`DrawingType.teste`, azul Samsung, sem somar hectare do talhão).
4. **Nome default** “Teste” (ou vazio obrigando nome curto), nunca “Talhão Novo” quando `pendingDrawingType == teste`.
5. **Nota do agrônomo / relatório:** fora desta fase (etapas 1–4 do agente redator).

## Papéis (AGENTS / supervisor)

| Papel | Faz |
|-------|-----|
| Supervisor | Brief, tag de restore, PR, revisor, merge (path crítico pede ok) |
| Executor | Código na lista fechada abaixo |
| Revisor | DIFF read-only |

## Bounded context

- **Primário:** `drawing/` (tipo teste já existe).
- **Host mapa:** `ui/` (entrada, sheets, gestos).
- **Sem** novo módulo, **sem** ADR na Fase 1 se foto ficar em campo existente do drawing (path local + lat/lng) ou anexo reutilizando padrão de ocorrência/marketing **só via contrato existente** — se precisar tabela nova → parar e pedir ADR.

## Arquivos (teto inicial — executor confirma PASSO 0)

```
lib/modules/drawing/presentation/widgets/drawing_sheet.dart
lib/modules/drawing/presentation/widgets/drawing_sheet_builders_a.dart
lib/modules/drawing/presentation/widgets/drawing_sheet_builders_b.dart
lib/modules/drawing/presentation/widgets/components/drawing_tool_selector.dart
lib/modules/drawing/presentation/controllers/drawing_controller.dart
lib/ui/screens/private_map_screen.dart
lib/ui/components/map/widgets/map_action_fab_menu.dart
lib/ui/components/map/map_bottom_sheet.dart
test/modules/drawing/
test/ui/components/map/drawing_sheet_tool_arm_test.dart
```

Expandir lista só com devolução ao supervisor.

## Regras obrigatórias

- Map-First, `context.go`/`context.push`, nunca `pop()` de rota.
- Sheets: `showSoloForteSheet` + `SoloForteSheetVisuals.of(context)`.
- `kFabSafeArea`, `kMapActionColumnBottomInset` intactos.
- `./tool/arch_check.sh` Exit 0; testes do escopo verdes.
- Commits por arquivo; push só da branch; nunca `origin/main`.

## Fases pequenas (executor uma por PR ou uma PR com commits separados)

| Fase | Entrega | Pronto quando |
|------|---------|----------------|
| A | Atalho “Teste de campo” no mapa arma `teste` direto | Um toque até o modo desenhar teste |
| B | Nome default + revisão só campos do teste | Salvar grava `DrawingType.teste` com nome correto |
| C | Passo foto na ficha de revisão (câmera/galeria, offline) | Foto associada ao desenho salvo ou ao sketch em revisão |
| D | Testes widget/controller + regressão tool arm | CI verde |

Fase E (relatório/agente redator): **não** neste prompt.

## Gate merge

Paths críticos: `lib/modules/drawing/`, `lib/ui/screens/map/`, `lib/ui/components/map/`.  
Supervisor pede ok no chat antes de `gh pr merge --auto --rebase`.

## Referências

- `lib/modules/drawing/AGENTS.md`
- `lib/ui/AGENTS.md`
- `docs/03_ENFORCEMENT/supervisor-merge-gate.md`
- Conversa: fluxo campo 18–19/nov/2026 (canvas agente soja)