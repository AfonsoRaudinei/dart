# PROMPT — NDVI Auditoria Final: Verificação das 4 Fases
**Agente:** Engenheiro Sênior Flutter/Dart — Auditor  
**Tipo:** Prompt de auditoria — apenas leitura e verificação, zero alterações  
**Pré-requisito:** Fases 1, 2a, 2b e 3 declaradas como concluídas

---

## REGRA FUNDAMENTAL DESTA AUDITORIA

> Este prompt **não executa código**.  
> Não cria arquivos. Não altera arquivos.  
> Apenas verifica, mede e reporta.  
> Se encontrar problema → **reportar** com path e linha exata. Nunca corrigir silenciosamente.

---

## 0️⃣ BLOCO A — Verificação de Existência (Fase 1)

Execute e reporte cada resultado:

```bash
echo "=== BLOCO A: ESTRUTURA DO MÓDULO NDVI ==="

# A1. Estrutura de pastas completa
find lib/modules/ndvi/ -name "*.dart" | sort
echo "Esperado: domain/entities, domain/repositories, data/models, data/repositories, presentation/providers, presentation/widgets"

# A2. ADR-022 criado
find docs/ -name "ADR-022*" -o -name "adr-022*" 2>/dev/null
find . -name "ADR-022*" | grep -v ".git"

# A3. IFieldLookup em core/contracts
find lib/core/contracts/ -name "i_field_lookup.dart"
cat lib/core/contracts/i_field_lookup.dart

# A4. INdviRepository interface
find lib/modules/ndvi/ -name "i_ndvi_repository.dart"
cat lib/modules/ndvi/domain/repositories/i_ndvi_repository.dart

# A5. NdviImage entidade — campos obrigatórios presentes
grep -n "fieldId\|imageDate\|ndviMin\|ndviMax\|ndviMean\|source\|syncStatus" \
  lib/modules/ndvi/domain/entities/ndvi_image.dart

# A6. SqliteNdviRepository — usa ndvi_cache, não inventa tabela
grep -n "ndvi_cache\|ndviCache" lib/modules/ndvi/data/repositories/sqlite_ndvi_repository.dart

# A7. Provider com autoDispose e family
grep -n "autoDispose\|family" lib/modules/ndvi/presentation/providers/ndvi_providers.dart
```

**Critério de aprovação Bloco A:**
- Todos os arquivos existem
- `ndvi_cache` referenciado no repositório (não tabela inventada)
- `autoDispose` presente nos providers
- ADR-022 criado

---

## 1️⃣ BLOCO B — Verificação do Bottom Sheet (Fase 2a)

```bash
echo "=== BLOCO B: NDVI TALHAO SHEET ==="

# B1. Widget existe
find lib/modules/ndvi/ -name "ndvi_talhao_sheet.dart"

# B2. Assinatura correta — fieldId e fieldName obrigatórios
grep -n "final String fieldId\|final String fieldName\|final double? areaHa" \
  lib/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart

# B3. Não importa consultoria, visitas ou drawing
grep -n "import.*consultoria\|import.*visitas\|import.*drawing" \
  lib/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart
echo "Esperado: nenhuma linha (zero importações proibidas)"

# B4. Trata estados loading, error, empty
grep -n "loading:\|error:\|data:\|CircularProgressIndicator\|SizedBox.shrink\|Nenhuma imagem" \
  lib/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart

# B5. Navegação entre datas — setas com índice
grep -n "dateIndex\|ndviDateIndex\|IconButton\|chevron\|arrow" \
  lib/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart

# B6. Usa kFabSafeArea no padding inferior
grep -n "kFabSafeArea" lib/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart

# B7. Testes existem
find test/modules/ndvi/ -name "*sheet*test*" -o -name "*talhao*test*"
```

**Critério de aprovação Bloco B:**
- Zero importações de `consultoria/`, `visitas/`, `drawing/`
- Três estados visuais presentes (loading, error, empty/data)
- Navegação por datas implementada
- `kFabSafeArea` usado
- Teste de widget existe

---

## 2️⃣ BLOCO C — Verificação do Card de Visita Ativa (Fase 2b)

```bash
echo "=== BLOCO C: BOTAO NDVI NO CARD DE VISITA ==="

# C1. Localizar o card alterado
find lib/ -name "*.dart" | xargs grep -l "NdviTalhaoSheet" 2>/dev/null | \
  grep -v "ndvi_talhao_sheet.dart"
echo "Esperado: exatamente 1 arquivo fora do módulo ndvi (o card de visita)"

# C2. Lógica condicional — só exibe quando areaId != null
grep -n "areaId\|NdviTalhaoSheet" \
  $(find lib/ -name "*.dart" | xargs grep -l "NdviTalhaoSheet" 2>/dev/null | \
    grep -v "ndvi_talhao_sheet.dart")

# C3. VisitSession NÃO foi alterada
git diff lib/modules/visitas/domain/models/visit_session.dart 2>/dev/null || \
  echo "git não disponível — verificar manualmente"

# C4. Nenhuma rota nova criada
grep -rn "GoRoute\|path:.*ndvi" lib/core/router/ --include="*.dart"
echo "Esperado: nenhuma rota com 'ndvi'"

# C5. showModalBottomSheet presente no card
grep -n "showModalBottomSheet" \
  $(find lib/ -name "*.dart" | xargs grep -l "NdviTalhaoSheet" 2>/dev/null | \
    grep -v "ndvi_talhao_sheet.dart")
```

**Critério de aprovação Bloco C:**
- `NdviTalhaoSheet` importado em exatamente 1 arquivo externo ao módulo ndvi
- Lógica condicional `areaId != null` presente
- Nenhuma rota ndvi criada
- `showModalBottomSheet` usado (não Navigator.push)

---

## 3️⃣ BLOCO D — Verificação da Tela de Detalhe do Talhão (Fase 3)

```bash
echo "=== BLOCO D: SECAO NDVI NA TELA DE DETALHE ==="

# D1. Arquivos que importam NdviTalhaoSheet ou ndviLatestProvider
find lib/ -name "*.dart" | xargs grep -l "NdviTalhaoSheet\|ndviLatestProvider" 2>/dev/null

# D2. ndviLatestProvider existe
find lib/modules/ndvi/ -name "ndvi_latest_provider.dart"
grep -n "LIMIT 1\|getLatestByFieldId\|autoDispose" \
  lib/modules/ndvi/presentation/providers/ndvi_latest_provider.dart

# D3. Preview card implementado com 3 estados
grep -n "loading:\|error:\|SizedBox.shrink\|não disponível\|Ver histórico" \
  $(find lib/ -name "*.dart" | xargs grep -l "ndviLatestProvider" 2>/dev/null | \
    grep -v "ndvi_latest_provider.dart")

# D4. arch_check — importação consultoria → ndvi não viola regras
./tool/arch_check.sh
echo "Esperado: Exit 0"
```

**Critério de aprovação Bloco D:**
- `ndviLatestProvider` criado com `autoDispose` e `LIMIT 1`
- 3 estados tratados na tela (loading, error, empty)
- `arch_check.sh` Exit 0 (importação `consultoria → ndvi` não proibida)

---

## 4️⃣ BLOCO E — Gate Checks Finais (obrigatório)

```bash
echo "=== BLOCO E: GATE CHECKS FINAIS ==="

# E1. flutter analyze — módulo ndvi
flutter analyze lib/modules/ndvi/

# E2. flutter analyze — módulos alterados
flutter analyze lib/modules/visitas/
flutter analyze lib/modules/consultoria/

# E3. Testes ndvi
flutter test test/modules/ndvi/ --reporter compact

# E4. Testes dos módulos alterados (verificar regressão)
flutter test test/modules/visitas/ --reporter compact
flutter test test/modules/consultoria/ --reporter compact

# E5. arch_check final
./tool/arch_check.sh
echo "Exit code: $?"

# E6. Nenhum arquivo novo > 900 linhas
find lib/modules/ndvi/ -name "*.dart" | while read f; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt 900 ]; then
    echo "VIOLAÇÃO REGRA 3: $f tem $lines linhas"
  fi
done
echo "Verificação de tamanho concluída"

# E7. Nenhuma rota ndvi foi criada
grep -rn "ndvi" lib/core/router/ --include="*.dart"
echo "Esperado: nenhum resultado"

# E8. MapContext.ndvi não vira rota
grep -rn "GoRoute.*ndvi\|path.*ndvi" lib/ --include="*.dart"
echo "Esperado: nenhum resultado"
```

---

## 5️⃣ RELATÓRIO FINAL OBRIGATÓRIO

Após executar todos os blocos, gerar tabela de resultado:

| Bloco | Item | Resultado | Status |
|---|---|---|---|
| A | Estrutura ndvi/ completa | — | ✅/❌ |
| A | ADR-022 criado | — | ✅/❌ |
| A | IFieldLookup em core/contracts/ | — | ✅/❌ |
| A | ndvi_cache referenciado (não inventado) | — | ✅/❌ |
| B | NdviTalhaoSheet existe | — | ✅/❌ |
| B | Zero importações proibidas no sheet | — | ✅/❌ |
| B | 3 estados visuais (loading/error/empty) | — | ✅/❌ |
| B | kFabSafeArea usado | — | ✅/❌ |
| B | Teste de widget existe | — | ✅/❌ |
| C | Botão NDVI em exatamente 1 ponto externo | — | ✅/❌ |
| C | Condicional areaId != null | — | ✅/❌ |
| C | Nenhuma rota ndvi criada | — | ✅/❌ |
| D | ndviLatestProvider com autoDispose | — | ✅/❌ |
| D | Preview card com 3 estados | — | ✅/❌ |
| E | flutter analyze lib/modules/ndvi/ = 0 erros | — | ✅/❌ |
| E | Testes ndvi todos verdes | — | ✅/❌ |
| E | Sem regressão em visitas/ e consultoria/ | — | ✅/❌ |
| E | arch_check.sh Exit 0 | — | ✅/❌ |
| E | Nenhum arquivo ndvi > 900 linhas | — | ✅/❌ |

---

## CRITÉRIO DE APROVAÇÃO TOTAL

**APROVADO:** todos os itens ✅  
**REPROVADO PARCIAL:** qualquer ❌ → listar itens com falha, path exato, linha, motivo  
**BLOQUEANTE:** qualquer falha em Bloco E (gate checks) → commit não autorizado  

---

## ENCERRAMENTO

Esta auditoria confirma (ou nega) que as 4 fases do módulo NDVI foram implementadas conforme especificado, sem regressão arquitetural, sem violação de fronteiras e sem dados inventados.  
Nenhuma alteração foi feita durante esta auditoria.
