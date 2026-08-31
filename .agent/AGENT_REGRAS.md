# Regras do Agente — SoloForte

> **Canônico neste path.** Cópias em `prompt/AGENT_REGRAS.md` são apenas redirecionamento.
> Em conflito: este arquivo + `AGENTS.md` (raiz) vencem.

## Terminal — SEMPRE executar daqui

O agente **DEVE executar** comandos no Cursor — nunca só listar para o usuário copiar.

---

## Sync remoto (obrigatório ao encerrar)

Push da **branch**. A `main` só recebe PR com auto-merge rebase. Nunca `git push origin main`.

```bash
git fetch origin && git checkout main && git pull origin main
# após feature (executor):
git push -u origin <branch>
# supervisor: gh pr create → revisor → gh pr merge --auto --rebase
gh pr view <n> --json state,mergedAt,mergeStateStatus,autoMergeRequest,url
```

**MacBook (Fase 2 local):** `git pull origin main` no Cursor Desktop.

---

## REGRA-ENTREGA-1 — Correção só vale se estiver na `main` (no app)

> Todo prompt que resultar em código alterado só está concluído quando o commit
> está em `origin/main`. Auto-merge armado **não** é entrega.

- ❌ Nunca `git push origin main` nem `gh pr merge --admin`
- ❌ Nunca encerrar com "correção feita" na branch `cursor/...` ou só com auto-merge armado
- ✅ `gh pr merge --auto --rebase` após o gate; depois `gh pr view` (mergedAt / pendente / desarmado)
- ✅ Reportar o SHA da `main` ou o texto obrigatório de pendente + URL do PR
- Referência: `AGENTS.md` · `docs/03_ENFORCEMENT/supervisor-merge-gate.md`

---

## Restore pós-reinstall (mesmo login)

Checklist: `.agent/CHECKLIST_RESTORE_REINSTALL.md` · PRD: `docs/PRD_RESTORE_REINSTALL_IPA.md`.  
Código + SQL live + IPA 224 **não** são 100% da trilha. 100% exige live counts > 0 (F2) e wipe (F3). Tela Sincronizando ok + nuvem 0 = SQLite deste install vazio ou push sem gravar — **não** desinstalar para “provar restore”.

---

## Memória persistente

Ler: `.agent/AGENT_MEMORIA.md` (**canônico**). `prompt/AGENT_MEMORIA.md` só redireciona.

---

## Bottom sheets — SheetSkin iOS (tema Azul)

**Doc canônico:** `design/sheets.md` · **Auditoria IPA 210:** `.agent/AUDITORIA_REGRESSAO_IPA210.md`

| Regra | Ação |
|---|---|
| Wrapper | `showSoloForteSheet` em `lib/core/ui/sheets/soloforte_sheet.dart` |
| Detecção | `SoloForteThemeExtension.themeId == 'blue'` — **nunca** hex |
| Tokens iOS | `SoloForteSheetSkinIos` em `sheet_tokens.dart` |
| Registro tema | `premium_app_theme.dart` — extension nos 3 temas |
| Blast radius | **20+ callers** com `Colors.transparent` — **não** confiar na lista de 12 do prompt Fase 1 |
| Escopo Fase 1 | Chrome-only (fundo, handle, borda, radius, `SoloForteSheetSkinScope`) |
| Escopo Fase 2 | Conteúdo interno + `transparent` + `MapBottomSheet` chrome (Ago/2026) |
| Helper | `soloForteSheetIsIos(context)` — scope ou `themeId == 'blue'` |
| Validação | `flutter test test/regression/sheets/soloforte_sheet_contract_test.dart` + `./tool/arch_check.sh` |

**Main:** cherry-pick `6230591` → `e04e690` · tag `feat/sheet-skin-ios`

---

## REGRA-SHEET-BLAST-1 — sheets compartilhados (IPA 210)

Ao tocar `lib/core/ui/sheets/` ou widgets de sheet compartilhados:

| Regra | Ação |
|---|---|
| Inventário | `rg showSoloForteSheet` + `rg 'backgroundColor: Colors.transparent'` |
| Contrato | **Proibido** inverter `transparent` / `preserveMaterialDefaults` sem atualizar callers + teste |
| Conteúdo escuro | `SoloForteSheetTokens.titleColor` (branco) não assume fundo escuro no tema Azul — usar `soloForteSheetIsIos` |
| Transversal | Afeta consultoria, marketing, agenda, carteira, map, drawing, planos |
| Release | **Proibido** reutilizar mesmo `+N` após código na `main` — próximo archive = próximo build |
| Doc | `.agent/AUDITORIA_REGRESSAO_IPA210.md` |

---

## REGRA-AUTODISPOSE-1 — `autoDispose` sem `watch` mata o estado no pior momento

> Incidente Ago/2026: **dois** recursos quebrados pela mesma causa. O pin do long press
> (`pendingOccurrenceLocationProvider`) e o rascunho por pin (`occurrenceDraftProvider`).

Um `StateProvider.autoDispose` só sobrevive enquanto **alguém observa** (`watch`). Escrever
com `read` e ler depois com `read` **não** mantém o valor vivo: ele é descartado no fim do
frame, justamente quando o sheet ainda não montou ou acabou de fechar.

| Situação | Ação |
|---|---|
| Provider escrito antes do consumidor existir | `watch` no host **antes** de qualquer early-return |
| Provider só lido com `read` em todo o `lib/` | **Remover `autoDispose`** + limpeza explícita |
| Auditar antes de usar autoDispose | `rg "<provider>" lib/ \| rg -v "\.notifier"` — se não houver `watch`, o autoDispose é armadilha |

**Proibido** gravar provider dentro de `build`, `initState`, `dispose`, `deactivate` ou
`didChangeDependencies`. Em `dispose`/`deactivate` o `ref` do Riverpod lança `StateError`
**incondicional** (não é assert de debug — quebra em release). Usar `addPostFrameCallback`
ou mover a gravação para o callback que originou a mudança.

**Validação:** `flutter test test/regression/map/occurrence_creation_flow_regression_test.dart`
(shields QA-1..QA-5 + ordem do `watch` do pin).

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
| SmartButton | Coluna ancorada ao FAB: `kMapActionColumnBottomInset` = `kFabSafeArea` 76 + `kMapActionColumnSpacingAboveFab` 16; clearance FAB↔check-in = 4+16 = **20dp** |
| Coluna atual | layers → check-in → SmartButton (sem botão `+` no overlay) |
| Modo desenho | Compensar com `kMapActionColumnDrawModeCompensation` (**60dp** = 16 + 44) |
| Espaçamento canônico | **16dp** (camadas↔check-in) — `kMapActionColumnSpacingAboveCheckIn` |
| Validação | `flutter test test/regression/map/controls_overlay_regression_test.dart` + `arch_check.sh` REGRA-MAP-CHROME-1 |

---

## Restore agronômico — push PT-only (REGRA-RESTORE-1)

Push de cliente/fazenda/talhão para o live **só no contrato PT**. Aliases EN (`name`/`phone`/`city`/`state`/`document`/`area_ha`) geram PGRST204 e o upsert inteiro cai — wipe deixa `public.clients=0`.

| Regra | Ação |
|---|---|
| Push cliente | Só `nome`/`telefone`/`cidade`/`uf` — nunca aliases EN |
| Push fazenda | Só `cliente_id`/`nome`/`area_total` |
| Push talhão | Só `fazenda_id`/`nome`/`area_produtiva` — nunca `geometry` |
| Validação | `flutter test test/regression/consultoria/agronomic_restore_push_regression_test.dart` + `arch_check.sh` REGRA-RESTORE-1 |

---

## Relatórios HTML

Obedecer `.cursor/rules/soloforte-designer.mdc` — logo SoloForte, zero ícones genéricos.
