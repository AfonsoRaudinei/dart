# Regras do Agente — SoloForte

> Espelho operacional em `.agent/` · fonte duplicada em `prompt/AGENT_REGRAS.md` quando aplicável.

## Terminal — SEMPRE executar daqui

O agente **DEVE executar** comandos no Cursor — nunca só listar para o usuário copiar.

---

## Sync remoto (obrigatório ao encerrar)

```bash
git fetch origin && git checkout main && git pull origin main
# após feature:
git push -u origin <branch> && git merge <branch> && git push origin main
git status && git log -1 --oneline
```

**MacBook (Fase 2 local):** `git pull origin main` no Cursor Desktop.

---

## Memória persistente

Ler: `.agent/AGENT_MEMORIA.md` · `prompt/AGENT_MEMORIA.md`

---

## Bottom sheets — SheetSkin iOS (tema Azul)

**Doc canônico:** `design/sheets.md` · **Skill:** `.cursor/skills/soloforte-sheets/SKILL.md`

| Regra | Ação |
|---|---|
| Wrapper | `showSoloForteSheet` em `lib/core/ui/sheets/soloforte_sheet.dart` |
| Detecção | `SoloForteThemeExtension.themeId == 'blue'` — **nunca** hex |
| Tokens iOS | `SoloForteSheetSkinIos` em `sheet_tokens.dart` |
| Registro tema | `premium_app_theme.dart` — extension nos 3 temas |
| Chamadores | 12 arquivos — **não alterar** sem prompt cirúrgico |
| Escopo Fase 1 | Chrome-only (fundo, handle, borda, radius, `SoloForteSheetSkinScope`) |
| Limitação QA | `transparent` / `MapBottomSheet` = limitação conhecida, não FALHA |
| Validação | `./tool/arch_check.sh` Exit 0 após mudança em `core/ui/sheets/` |

**Main:** cherry-pick `6230591` → `e04e690` · tag `feat/sheet-skin-ios`

---

## Ocorrências no mapa (REGRA-OCC)

Ver `.agent/PLANO_BLINDAGEM_OCORRENCIAS_MAPA.md` · REGRA-OCC-8..11 em `arch_check.sh`

---

## Coluna direita do mapa — blindagem anti-regressão (REGRA-MAP-CHROME-1)

Ao tocar `map_controls_overlay.dart` ou constantes de layout do mapa:

| Regra | Ação |
|---|---|
| Posição travada | Usar `kMapActionColumnBottomInset` + `safeBottom` — **nunca** `mapSheetChromeInsetProvider` |
| Constantes | Tamanho/espaçamento em `layout_constants.dart` (`kMapActionColumn*`) |
| SmartButton | Coluna ancorada ao FAB global (`kFabSafeArea` = 76dp acima da safe-area) |
| Modo desenho | Compensar com `kMapActionColumnDrawModeCompensation` para manter camadas fixas |
| IPA | **208 NÃO inclui** este fix — mínimo **209+** |
| Validação | `flutter test test/regression/map/controls_overlay_regression_test.dart` + `arch_check.sh` REGRA-MAP-CHROME-1 |

---

## Relatórios HTML

Obedecer `.cursor/rules/soloforte-designer.mdc` — logo SoloForte, zero ícones genéricos.
