# REVISÃO SOLOFORTE — DIFF Marketing / Relatórios / Flash — 15/Ago/2026

**Agente base:** `soloforte-revisor` v1.2 (`.cursor/agents/soloforte-revisor.md`)  
**Camada anti-regressão:** Regression Shield (`test/regression/` + CI) + `AUDITORIA_REGRESSAO_IPA210.md`  
**Modo:** DIFF  
**Alvo:** `e1efa35..61e768a` + `868cbea`  
**Base:** `origin/main` @ `61e768a`  
**Profundidade:** PADRÃO

---

## 1. Sumário executivo

| Campo | Valor |
|---|---|
| Modo | DIFF |
| Arquivos no escopo (delta Marketing/Relatórios) | 14 (+756 / −115) |
| Arquivos flash (`868cbea`) | 7 (+25 / −19) |
| Achados novos do DIFF | 0 P0 · 0 P1 · 1 P2 · 0 P3 |
| Veredito | ✅ SAUDÁVEL |

**No findings** de regressão de produto no DIFF: labels Marketing, limite→rascunho, Salvar rascunho e flash mapa estão na `main` com testes verdes.

**P2 resolvido nesta execução:** BUG-007/008/009 promovidos para `test/regression/`; job CI renomeado para `BUG-001–009`; `IMarketingCaseReportsLookup` (ADR-050) incluído no `soloforte-revisor`.

---

## 2. Saúde estrutural (medida)

| Gate | Resultado |
|---|---|
| `./tool/arch_check.sh` | Exit **0** (APROVADO) |
| `flutter test test/regression/` + relatorios actions + launcher | **63 passed** |
| SHA `origin/main` | `61e768a` |
| Working tree | limpa em relação a `origin/main` no momento da medição |

### Commits no escopo

| SHA | Mensagem |
|---|---|
| `868cbea` | fix(map): eliminar flash ao tocar ícones e abrir sheets |
| `e1efa35` | feat(relatorios): aba Marketing com Gerado / Não gerado |
| `804a6c5` | test(relatorios): cobrir aba Marketing e cases não gerados |
| `493b34c` | fix(marketing): Marketing labels, rascunho além do limite e Salvar rascunho |
| `61e768a` | test(marketing): cobrir limite, filtros status e regressão flash mapa |

---

## 3. O que está bom (não mexer)

- Fronteira ADR-050: `consultoria/relatorios` consome só `core/contracts` (`marketingCaseReportsListProvider` / `IMarketingCaseReportsLookup`).
- Aba UI **Marketing**; status publicado = **Marketing**; rascunho = **Não gerado**; `showPackShare: false`.
- Limite de plano conta só **published**; no limite, mapa salva draft (`submitCaseFromMap`) em vez de travar.
- Botão **Salvar rascunho (Relatórios)** em `novo_case_sheet.dart`.
- `publishDraftCase` no limite: SnackBar + `DraftSavedSheet` (UX alinhada ao mapa).
- Flash: `const SmartButton()`, label só em long-press, `sameModalAlreadyOpen` em `private_map_screen.dart`.
- REGRA-MAP-CHROME-1 e REGRA-SHEET-BLAST-1 intactas no `arch_check`.

---

## 4. Achados por severidade

### [P2] Testes Marketing/launcher fora do job Regression Shield CI

**Arquivo:** `.github/workflows/architecture.yml:82-103`  
**Modo/Eixo:** DIFF · 12 — Enforcement / regressão de gate  
**Evidência:** job `Regression Shield (BUG-001–005)` executa apenas `flutter test test/regression/`. Invariantes de limite→draft e labels Marketing estavam em `test/modules/` e `test/ui/` (cobertos localmente, não no shield CI).  
**Impacto:** regressão poderia passar no job dedicado mesmo com testes verdes em outro path.  
**Correção proposta:** promover BUG-007/008/009 sob `test/regression/` e atualizar o nome do job.  
**Comportamento muda?** NÃO  
**Risco da correção:** BAIXO  
**Esforço:** ~30 min

**P0 / P1:** nenhum no DIFF.

---

## 5. Débito pré-existente tocado pelo escopo

- **soloforte-revisor §0** listava contratos cross-module **sem** `IMarketingCaseReportsLookup` (ADR-050) — documentação do agente desatualizada, não bug de runtime. Corrigir no agente.
- Enum interno `_RelatoriosSegment.gerados` permanece (só código); UI exibe **Marketing** — consciente, não mexer sem ADR de rename.
- “Gerado sob demanda” em Consolidados é copy de outro domínio — não confundir com badge de marketing case.

---

## 6. Plano de ação

| # | Achado | Sev | Esforço | Risco | Ação |
|---|---|---|---|---|---|
| 1 | Promover BUG-007 labels Marketing | P2 | 15 min | Baixo | `test/regression/relatorios/` |
| 2 | Promover BUG-008 limite→draft | P2 | 20 min | Baixo | `test/regression/marketing/` |
| 3 | Documentar flash como BUG-009 | P2 | 5 min | Baixo | grupo em `controls_overlay_regression_test` |
| 4 | Atualizar job CI + agente revisor ADR-050 | P2 | 10 min | Baixo | workflow + soloforte-revisor |

---

## 7. Prompts (execução nesta sessão)

- `PROMPT_SHIELD_BUG_007_009` — promover invariantes + CI  
- `PROMPT_REVISOR_ADR050` — incluir contrato no agente  

---

## 8. O que NÃO recomendo agora

- Fase 4 flash (ShellRoute/bootstrap) — custo > benefício sem sintoma novo.  
- Renomear enum `gerados` no código — só churn.  
- Reescrever Regression Shield v1 / AUDIT monorepo — fora do escopo.

---

## 9. Checklist device (QA residual ~2%)

No Mac após `git pull origin main` + hot restart:

1. Com 3 cases publicados, criar 4º via **Publicar** → Não gerado + snackbar + sheet planos.  
2. **Salvar rascunho (Relatórios)** → sempre salva.  
3. Relatórios → Marketing: chips **Marketing** / **Não gerados**.  
4. Draft no limite → **Publicar** no menu → sheet de limite (não publica).  
5. Tap rápido nos ícones da coluna direita → **sem flash** de label/FAB.

---

## 10. Mapa anti-regressão (após blindagem)

| ID | Invariante | Suite |
|---|---|---|
| BUG-001 | role / AsyncData | `test/regression/auth/` |
| BUG-002 / BUG-005 | coluna direita / sem publicações | `test/regression/map/controls_overlay_*` |
| BUG-003 | ocorrência sheet / sync | `test/regression/map/occurrence_sheet_*` |
| BUG-004 | Relatórios providers reais | `test/regression/relatorios/` |
| BUG-006 | fluxo ocorrência P0/P1 | `test/regression/map/occurrence_creation_*` |
| BUG-007 | labels Marketing (não Gerado/Gerados) | `test/regression/relatorios/marketing_labels_*` |
| BUG-008 | limite → saveAsDraft + snackbar | `test/regression/marketing/` |
| BUG-009 | flash mapa (868cbea) | `test/regression/map/controls_overlay_*` |

---

## Encerramento

> Revisão DIFF do alvo Marketing/Relatórios/Flash concluída com base no `soloforte-revisor`.  
> Veredito: ✅ SAUDÁVEL. Achados: 1 P2 (gap de shield CI).  
> Blindagem BUG-007/008/009 e ADR-050 no agente são a execução imediata desta revisão.
