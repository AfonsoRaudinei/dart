# UPDATE BASELINE — PÓS-AUDITORIA MARÇO/2026
## Atualizar SOLOFORTE_BASELINE_REAL.md e ARCH_BASELINE

**Agente:** Engenheiro Sênior Flutter/Dart  
**Destino:** `prompt/UPDATE_BASELINE_POS_AUDITORIA.md`  
**Execução imediata:** NÃO — PASSO 0 obrigatório antes de qualquer edição.  
**Tipo:** Atualização de documentação — ZERO alteração em `.dart`

---

## CONTEXTO

Após auditoria completa (23/03/2026) e 3 sessões de correção, o estado
real do código diverge do baseline documentado em vários pontos.
Este prompt atualiza os dois documentos de referência para refletir
a realidade atual do código.

**Documentos a atualizar:**
```
docs/SOLOFORTE_BASELINE_REAL.md
docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md
```

---

## PASSO 0 — COLETA DE DADOS REAIS (executar antes de editar)

```bash
# 0.1 — Contagem real de arquivos Dart
find lib/ -name "*.dart" | wc -l

# 0.2 — Schema DB: versão atual
grep -n "_migrateToV\|version\s*=" lib/core/database/database_helper.dart \
  | grep -i "Future\|version\s*=" | tail -10

# 0.3 — ADRs referenciados no código
grep -rn "ADR-0[0-9][0-9]" lib/ --include="*.dart" \
  | grep -oP "ADR-0[0-9][0-9]" | sort -u

# 0.4 — Testes: contagem total
flutter test --reporter compact 2>&1 | tail -3

# 0.5 — flutter analyze: contagem de issues
flutter analyze lib/ 2>&1 | tail -3

# 0.6 — arch_check status
./tool/arch_check.sh 2>&1 | tail -5

# 0.7 — Módulos existentes em lib/modules/
find lib/modules/ -maxdepth 1 -type d | sort

# 0.8 — Arquivos >900 linhas (legados monitorados)
find lib/ -name "*.dart" -exec wc -l {} + | sort -rn | awk '$1 > 900' | head -10

# 0.9 — Providers keepAlive ativos
grep -rn "keepAlive:\s*true\|keepAlive: true\|@Riverpod(keepAlive\|ref\.keepAlive()" \
  lib/ --include="*.dart" | grep -v "_test\|\.g\.dart" | wc -l

# 0.10 — Interfaces formais DIP
find lib/ -name "i_*.dart" | grep -v test | wc -l

# 0.11 — Confirmar features implementadas (pós-auditoria)
find lib/ -name "*ndvi*panel*" | grep -v test | head -3
find lib/ -name "*gps_walk*" | grep -v test | head -3
grep -rn "NovoCaseSheet\|marketing_case_marker" \
  lib/ui/screens/private_map_screen.dart 2>/dev/null | head -3

# 0.12 — Confirmar repairOrphanUserIds implementado
grep -n "repairOrphanUserIds" lib/core/database/database_helper.dart

# 0.13 — Confirmar logout seguro implementado
grep -n "clearLocalUserData\|invalidate\|signOut" \
  lib/core/session/session_controller.dart | head -10

# 0.14 — Confirmar .baseline_marker existe
ls -la .baseline_marker

# 0.15 — Confirmar enum real do mapa (ArmedMode vs MapContext)
grep -rn "enum ArmedMode\|enum MapContext" lib/ --include="*.dart" | head -5

# 0.16 — Confirmar versões reais dos 3 bancos
grep -rn "marketing_cases\|visitas_tecnicas\|soloforte" \
  lib/core/database/database_helper.dart | grep "version\|openDatabase" | head -10

# 0.17 — Confirmar sub-rota proibida /map/publicacao ainda existe
grep -n "map/publicacao\|/map/pub" lib/core/router/app_router.dart | head -5

# 0.18 — Confirmar visit_controller usa IAgendaRepository ou concreto
grep -n "IAgendaRepository\|AgendaRepository" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart | head -5

# 0.19 — Confirmar occurrence_list_sheet ainda importa visitas/
grep -n "import.*visitas\|visit_controller" \
  $(find lib/ -name "occurrence_list_sheet.dart" | head -1) 2>/dev/null

# 0.20 — TODOs em produção (contagem atual)
grep -rn "TODO\|FIXME\|HACK" lib/ --include="*.dart" | grep -v "_test" | wc -l
```

---

## MUDANÇAS CONFIRMADAS A APLICAR

O agente usa os resultados do PASSO 0 para confirmar cada item antes
de editar. Se um resultado divergir do esperado, reportar antes de prosseguir.

### Em `SOLOFORTE_BASELINE_REAL.md`

**1. Cabeçalho e data**
```
Última verificação: Março/2026 (pós-auditoria)
Schema DB atual: v26 (soloforte.db) — confirmar com PASSO 0.2
```

**2. Seção Schema DB — adicionar versões confirmadas:**
```
v21 | user_id adicionado em todas as tabelas locais (V21 migration) | ✅ Aplicado
v22 | [confirmar com PASSO 0.2 o que v22+ contém]
...
v26 | [estado atual — confirmar]
```

**3. Seção ADRs — atualizar para ADR-008 a ADR-022:**

Adicionar ADRs confirmados no código (PASSO 0.3):
```
ADR-018 | Agenda duplicada eliminada — consultoria/agenda/ deletado | ✅ Ativo
ADR-019 | IVisitClientLookup — contrato visitas/consultoria | ✅ Ativo  
ADR-020 | Acoplamento consultoria↔visitas removido | ✅ Ativo
ADR-021 | IFarmLookup — drawing via DIP | ✅ Ativo
ADR-022 | [confirmar se existe no código com PASSO 0.3]
```

**4. Seção Features — atualizar status de pendentes para implementadas:**
```
GPS Walk / Gravar Rota: IMPLEMENTADO (confirmado auditoria 23/03/2026)
  Arquivos: gps_walk_session.dart, gps_walk_controller.dart,
            gps_walk_providers.dart, gps_walk_metrics_bar.dart,
            gps_walk_bottom_bar.dart, gps_walk_controls_overlay.dart

NDVI Panel: IMPLEMENTADO (confirmado auditoria 23/03/2026)
  Arquivo: lib/modules/ndvi/presentation/widgets/ndvi_panel_widget.dart
  444 linhas, consome provider real, 0 TODOs internos

Marketing PASSO 6 (long press → NovoCaseSheet): IMPLEMENTADO
  Localização: private_map_screen.dart + private_map_sheets.dart

Marketing PASSO 7 (pins no mapa): IMPLEMENTADO
  Localização: isolated_marker_layers.dart via marketingCasesProvider
```

**5. Seção Estado de Saúde — atualizar:**
```
flutter analyze: 0 erros, 65 issues (infos/warnings pré-existentes)
arch_check.sh: EXIT 0 (5 exceções legadas monitoradas)
Testes: confirmar contagem real com PASSO 0.4
Schema DB: v26 (soloforte.db), confirmar marketing_cases.db e visitas_tecnicas.db
ADRs formais: ADR-008 a ADR-022 (confirmar com PASSO 0.3)
.baseline_marker: ✅ Criado (enforcement REGRA 3 agora funciona)
repairOrphanUserIds: ✅ Implementado em database_helper.dart
Logout seguro: ✅ clear → invalidate → signOut em session_controller.dart
```

**6. Seção Dívidas Técnicas — atualizar:**

Remover itens resolvidos:
- ~~Logout sem clear/invalidate~~ → RESOLVIDO (Sessão 2)
- ~~SELECTs sem user_id em 6 repositórios~~ → RESOLVIDO (Sessão 3)
- ~~repairOrphanUserIds ausente~~ → RESOLVIDO (Sessão 3)
- ~~.baseline_marker ausente~~ → RESOLVIDO (Sessão 2)

Manter/adicionar itens pendentes:
```
| Sub-rota /map/publicacao/edit | Alto — viola contrato Map-First | app_router.dart | Remover rota, converter para overlay |
| visit_controller usa AgendaRepository concreto | Médio — ADR-018 regrediu | visitas/controllers/visit_controller.dart | Migrar para IAgendaRepository |
| occurrence_list_sheet importa visitas/ diretamente | Médio — violação bounded context | occurrence_list_sheet.dart | Usar contrato em core/contracts/ |
| relatorios sem coluna user_id (usa agronomist_id) | Médio — isolamento parcial | relatorio_table.dart | ADR futuro + migração schema |
| marketing_cases.db versão real vs baseline | Baixo — divergência documental | database_helper.dart | Confirmar versão real e atualizar |
| ArmedMode no código vs MapContext no contrato | Baixo — divergência nomenclatura | map_state.dart | Alinhar nome ou atualizar contrato |
| 3 FABs no overlay de desenho | Médio — viola FAB único | map_controls_overlay.dart | Refatorar para SmartButton único |
```

**7. Seção Enum do Mapa — CORRIGIR:**
```
⚠️ DIVERGÊNCIA CONFIRMADA:
Contrato documenta: enum MapContext { tecnico, clima, ocorrencias, publicacoes, ndvi }
Código real usa: enum ArmedMode (nome diferente)
Status: divergência de nomenclatura — código funciona, documentação desatualizada
Ação: atualizar documentação para refletir ArmedMode, ou criar ADR para renomear
```

---

### Em `ARCH_BASELINE_v1.1_SCORE_90.md`

**1. Seção Identificação — atualizar:**
```
Versão arquitetural: v1.2 (pós-auditoria Mar/2026)
Data de última revisão: 24/03/2026
Branch de referência: release/v1.1
Commit de referência: 51c5c99 (último commit da Sessão 3)
```

**2. Seção Métricas — atualizar com valores do PASSO 0:**
```
Arquivos Dart em lib/: [PASSO 0.1]
Providers keepAlive: [PASSO 0.9]
TODOs em produção: [PASSO 0.20]
Interfaces formais (DIP): [PASSO 0.10]
Testes verdes: [PASSO 0.4]
Erros flutter analyze: 0
Arquivos >900 linhas: 5 legados (WARN controlado) ← era 4, agora inclui database_helper
```

**3. Seção Garantias — adicionar:**
```
| repairOrphanUserIds implementado | ✅ |
| Logout seguro (clear→invalidate→signOut) | ✅ |
| .baseline_marker criado | ✅ |
| Isolamento user_id em 6 repositórios | ✅ |
| GPS Walk implementado | ✅ |
| NDVI Panel implementado | ✅ |
| Marketing PASSO 6+7 implementados | ✅ |
```

**4. Seção Bounded Contexts — adicionar módulos confirmados:**
```
ndvi/ — módulo NDVI (NdviPanelWidget — 444 linhas, funcional)
  Sem ADR formal ainda
  
drawing/gps_walk — GPS Walk dentro do módulo drawing
  Sem ADR formal ainda
  Controller: gps_walk_controller.dart (184 linhas)
```

**5. Seção Issues Conhecidos (nova seção):**
```
## Issues Conhecidos (Pós-Auditoria Mar/2026)

### P1 — Alta Prioridade
- Sub-rota /map/publicacao/edit: GoRoute real em app_router.dart — viola Map-First
- visit_controller.dart: usa AgendaRepository concreto (ADR-018 regrediu)
- occurrence_list_sheet.dart: importa visitas/ diretamente (bounded context)

### P2 — Média Prioridade  
- relatorios/: sem coluna user_id — usa agronomist_id como isolamento
- ArmedMode vs MapContext: divergência entre código e contrato documentado
- marketing_cases.db / visitas_tecnicas.db: versões divergem do baseline
- 3 FABs no map_controls_overlay (viola contrato FAB único)

### P3 — Baixa Prioridade / Backlog
- DrawingRemoteStore: ainda stub (sync remoto de desenhos não funcional)
- Duplicatas: field_map_entity.dart e geofence_state.dart (2 cópias cada)
- 65 issues flutter analyze (todos infos/warnings pré-existentes)
```

---

## SEQUÊNCIA DE EXECUÇÃO

```
1. PASSO 0 completo → reportar todos os outputs
2. Apresentar diff de cada seção que será alterada
3. Aguardar aprovação
4. Editar SOLOFORTE_BASELINE_REAL.md
5. Editar ARCH_BASELINE_v1.1_SCORE_90.md
6. Gate check: revisar se há inconsistências entre os dois documentos
7. Commit
```

---

## GATE CHECK FINAL

```bash
# Verificar que os documentos existem e foram editados
ls -la docs/SOLOFORTE_BASELINE_REAL.md
ls -la docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md

# Confirmar que nenhum .dart foi alterado
GIT_PAGER=cat git diff --stat | grep "\.dart" | head -5

# Verificar status
GIT_PAGER=cat git diff --name-only
```

---

## COMMIT

```bash
git add docs/SOLOFORTE_BASELINE_REAL.md
git add docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md
git commit -m "docs: atualiza baseline pós-auditoria Mar/2026 — features, métricas, dívidas técnicas"
```

---

## PROIBIÇÕES ABSOLUTAS

- Nunca editar arquivos `.dart`
- Nunca alterar `arch_check.sh` ou `bounded_contexts.md` aqui
- Nunca inventar métricas — usar apenas dados do PASSO 0
- Nunca marcar como resolvido item não confirmado pelo PASSO 0
- Nunca usar `git add .` ou `git add -A`

---

## ENCERRAMENTO PADRÃO

```
Resultado final:
SOLOFORTE_BASELINE_REAL.md atualizado com estado real pós-auditoria.
ARCH_BASELINE atualizado com métricas reais e issues conhecidos.
Nenhum arquivo .dart foi alterado.
Baseline agora reflete o estado real da branch release/v1.1 em 24/03/2026.
```

---

*Prompt gerado para: SoloForte App — Atualização de Baseline Pós-Auditoria*  
*Referência: Relatório de Auditoria 21/03/2026 + Sessões 1, 2, 3 de correção*  
*Último commit de referência: 51c5c99*
