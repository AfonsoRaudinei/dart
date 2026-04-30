# PROMPT 06 — AUDITORIA FINAL: Validação Pós-Execução dos Prompts 01–05

**Especialização do agente:** Engenheiro Sênior Flutter/Dart — Auditor de Arquitetura e Qualidade  
**Tipo:** READ-ONLY AUDIT (zero modificações)  
**Escopo:** Validação completa do estado pós-execução de todos os prompts desta sprint

---

## ⚠️ REGRA ABSOLUTA

Este prompt é **somente leitura e execução de comandos de validação**.  
- ✅ `find`, `grep`, `wc -l`, `flutter analyze`, `arch_check.sh`  
- ✅ Leitura de arquivos  
- ❌ Nenhuma escrita, nenhum edit, nenhum `git add`  

Se encontrar algo que precisa ser corrigido → **registrar no relatório final, não corrigir aqui**.

---

## PASSO 0 — ESTADO DO REPOSITÓRIO

```bash
git status
git log --oneline -10
```

Confirmar:
- Não há arquivos staged não commitados
- Os commits dos prompts 01–05 aparecem no log

---

## BLOCO A — AUDITORIA DO PROMPT 01 (ADR-033 — NovoCaseSheet)

### A.1 Tamanho do arquivo principal
```bash
wc -l lib/modules/marketing/presentation/screens/novo_case_sheet.dart
```
✅ Esperado: ≤ 500 linhas  
❌ Falha se: > 500 linhas

### A.2 Arquivos extraídos existem
```bash
find lib/modules/marketing/presentation/widgets/ -name "novo_case_*" | sort
```
✅ Esperado: ao menos 3 arquivos de seção extraídos  
❌ Falha se: nenhum arquivo extraído (decomposição não executada)

### A.3 Contrato externo preservado
```bash
grep -n "required double lat\|required double lng\|required VoidCallback onClose\|required void Function(MarketingCase) onPublicar" lib/modules/marketing/presentation/screens/novo_case_sheet.dart
```
✅ Esperado: 4 linhas encontradas (contrato intacto)  
❌ Falha se: qualquer parâmetro ausente ou alterado

### A.4 NovoCaseModalLauncher não foi alterado
```bash
git diff HEAD~5 -- lib/ui/screens/map/handlers/novo_case_modal_launcher.dart 2>/dev/null | head -5
```
✅ Esperado: sem diff ou arquivo não encontrado no diff  
❌ Falha se: diff não vazio

---

## BLOCO B — AUDITORIA DO PROMPT 02 (DT-028 — Radar)

### B.1 showRadarProvider eliminado
```bash
grep -rn "showRadarProvider" lib/
```
✅ Esperado: zero ocorrências  
❌ Falha se: qualquer ocorrência encontrada

### B.2 MapContext.clima existe
```bash
grep -rn "MapContext.clima\|clima" lib/modules/map/ lib/ui/ | grep -i "mapcontext\|MapContext" | sort
```
✅ Esperado: ao menos 1 ocorrência de `MapContext.clima`  
❌ Falha se: zero ocorrências (migração não executada)

### B.3 RadarLayerWidget usa novo provider
```bash
grep -n "watch\|read" $(find lib/ -name "radar_layer*.dart") 2>/dev/null
```
✅ Esperado: referência a `MapContext.clima` ou provider equivalente — não a `showRadarProvider`

---

## BLOCO C — AUDITORIA DO PROMPT 03 (VFX-01 a 06)

### C.1 Design tokens aplicados nos sheets
```bash
grep -rln "0xFF1C1C1E" lib/ | grep "sheet\|Sheet" | sort
grep -rln "0xFF2C2C2E" lib/ | grep "sheet\|Sheet" | sort
```
Contar: quantos sheets têm o token de background vs quantos existem no total.

### C.2 Handle padronizado
```bash
grep -rln "width: 36\|width: 40" lib/ | grep "sheet\|Sheet" | sort
```
✅ Esperado: ao menos os sheets que eram pendentes agora têm o handle

### C.3 Botão primário padronizado
```bash
grep -rn "0xFFF59E0B" lib/ | grep "sheet\|Sheet" | sort
```
✅ Esperado: ocorrências nos sheets que tinham VFX-06 pendente

---

## BLOCO D — AUDITORIA DO PROMPT 04 (DrawingRemoteStore)

### D.1 Stub eliminado
```bash
grep -rn "UnimplementedError\|throw Unimplemented\|// TODO" lib/modules/drawing/data/ | sort
```
✅ Esperado: zero `UnimplementedError` relacionado ao RemoteStore  
❌ Falha se: `UnimplementedError` ainda presente

### D.2 Implementação existe
```bash
find lib/ -name "*drawing*remote*" | sort
wc -l $(find lib/ -name "*drawing*remote*") 2>/dev/null
```
✅ Esperado: arquivo existe com conteúdo real (> 30 linhas)

### D.3 Sem acoplamento proibido
```bash
grep -n "import.*consultoria\|import.*operacao" $(find lib/modules/drawing/ -name "*.dart") | sort
```
✅ Esperado: zero imports proibidos

---

## BLOCO E — AUDITORIA DO PROMPT 05 (Migration marketing_cases_cache)

### E.1 user_id presente na tabela
```bash
grep -A 50 "marketing_cases_cache" $(find lib/ -name "*.dart" | xargs grep -l "marketing_cases_cache" 2>/dev/null) | grep "user_id"
```
✅ Esperado: `user_id` presente no CREATE TABLE

### E.2 Padrão DROP + CREATE respeitado
```bash
grep -B2 -A2 "marketing_cases_cache" $(find lib/ -name "*.dart" | xargs grep -l "DROP.*marketing\|marketing.*DROP" 2>/dev/null) 2>/dev/null | head -20
```
✅ Esperado: `DROP TABLE IF EXISTS marketing_cases_cache` antes do `CREATE TABLE`

### E.3 Versão do banco
```bash
grep -rn "_dbVersion\|schemaVersion\|version:" lib/ | grep -v ".g.dart" | sort
```
✅ Esperado: versão correta (30 se sem divergência, 31 se migration foi necessária)

---

## BLOCO F — VALIDAÇÃO GLOBAL

### F.1 flutter analyze
```bash
flutter analyze lib/ 2>&1 | tail -5
```
✅ Esperado: `No issues found` ou apenas warnings pré-existentes  
❌ Falha crítica se: qualquer erro novo

### F.2 arch_check.sh
```bash
bash tool/arch_check.sh
echo "Exit code: $?"
```
✅ Esperado: Exit 0 com as 3 violações preexistentes  
❌ Falha se: Exit ≠ 0 ou nova violação apareceu

### F.3 Contagem de linhas — arquivos críticos
```bash
wc -l \
  lib/modules/marketing/presentation/screens/novo_case_sheet.dart \
  lib/ui/screens/private_map_screen.dart \
  2>/dev/null | sort -n
```
✅ Esperado: `novo_case_sheet.dart` ≤ 500L, `private_map_screen.dart` ≤ 700L

### F.4 Zero imports proibidos novos
```bash
grep -rn "import.*modules/drawing.*modules/consultoria\|import.*modules/consultoria.*modules/drawing" lib/ | sort
grep -rn "import.*modules/agenda.*modules/consultoria" lib/ | sort
```
✅ Esperado: zero ocorrências

---

## RELATÓRIO FINAL (preencher obrigatoriamente)

```
SPRINT POST-AUDIT — Abr/2026
═══════════════════════════════════════════════════════

PROMPT 01 — ADR-033 (NovoCaseSheet)
├── novo_case_sheet.dart: XXX linhas → PASS/FAIL (limite: ≤500)
├── Arquivos extraídos: N arquivos
├── Contrato externo: PRESERVADO / ALTERADO
└── Status: ✅ CONCLUÍDO / ❌ PENDENTE / ⚠️ PARCIAL

PROMPT 02 — DT-028 (Radar)
├── showRadarProvider: ELIMINADO / AINDA EXISTE
├── MapContext.clima: EXISTE / NÃO EXISTE
└── Status: ✅ CONCLUÍDO / ❌ PENDENTE / ⚠️ PARCIAL

PROMPT 03 — ADR-027 VFX
├── VFX-01 (handle): N sheets corrigidos
├── VFX-02 (background): N sheets corrigidos
├── VFX-03 (inputs): N sheets corrigidos
├── VFX-05 (tipografia): N sheets corrigidos
├── VFX-06 (botão): N sheets corrigidos
└── Status: ✅ CONCLUÍDO / ❌ PENDENTE / ⚠️ PARCIAL

PROMPT 04 — DrawingRemoteStore
├── UnimplementedError: ELIMINADO / AINDA EXISTE
├── Implementação: COMPLETA / PARCIAL / AUSENTE
└── Status: ✅ CONCLUÍDO / ❌ PENDENTE / ⚠️ PARCIAL

PROMPT 05 — Migration marketing_cases_cache
├── user_id: PRESENTE / AUSENTE
├── DROP+CREATE: SIM / NÃO
├── Schema version: vXX
└── Status: ✅ CONCLUÍDO / ❌ PENDENTE / ⚠️ PARCIAL

VALIDAÇÃO GLOBAL
├── flutter analyze: ✅ 0 erros / ❌ N erros novos
├── arch_check.sh: ✅ Exit 0 / ❌ Exit 1 (nova violação: DESCREVER)
└── Regressões detectadas: NENHUMA / LISTA

AÇÕES PENDENTES PARA PRÓXIMA SPRINT:
- [ ] item 1
- [ ] item 2
```

---

## ENCERRAMENTO

Auditoria pós-sprint concluída.  
Relatório acima é a fonte da verdade para o próximo planning.  
Nenhum arquivo foi modificado nesta auditoria.
