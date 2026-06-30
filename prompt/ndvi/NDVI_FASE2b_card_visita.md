# PROMPT — NDVI Fase 2b: Ponto de Entrada no Card de Visita Ativa
**Agente:** Engenheiro Sênior Flutter/Dart — Top 0,1%  
**Arquivo de destino:** card de visita ativa (path confirmado no PASSO 0)  
**Pré-requisito obrigatório:** Fases 1 e 2a concluídas e validadas

---

## 0️⃣ PASSO 0 — AUDITORIA OBRIGATÓRIA ANTES DE QUALQUER EDIÇÃO

Execute exatamente estes comandos e reporte o resultado completo:

```bash
# 1. Localizar o card de visita ativa — pode ter nome variado
find lib/ -name "*visit*card*" -o -name "*active*visit*" -o -name "*checkin*card*" \
  -o -name "*visit*overlay*" -o -name "*session*card*" | grep "\.dart$"

# 2. Confirmar que NdviTalhaoSheet existe (Fase 2a)
find lib/modules/ndvi/ -name "ndvi_talhao_sheet.dart"

# 3. Ver conteúdo atual do card de visita ativa (path do resultado acima)
# ATENÇÃO: substituir <PATH_REAL> pelo path encontrado no passo 1
cat <PATH_REAL>

# 4. Identificar o provider que gerencia o estado da visita ativa
grep -rn "visitControllerProvider\|activeVisit\|isCheckInActive\|VisitSession" \
  lib/modules/visitas/presentation/ --include="*.dart" | head -20

# 5. Verificar se VisitSession já tem campo areaId ou fieldId
grep -n "areaId\|fieldId\|talhao" \
  lib/modules/visitas/domain/models/visit_session.dart

# 6. Confirmar que IFieldLookup existe
find lib/core/contracts/ -name "i_field_lookup.dart"

# 7. Confirmar adapter existente para IFieldLookup (se houver)
find lib/ -name "*field_lookup_adapter*" -o -name "*field*adapter*" | grep "\.dart$"
```

**STOP CONDITION — parar e reportar se:**
- Card de visita ativa não encontrado → não criar novo arquivo, reportar path esperado
- `VisitSession.areaId` não existe → não inventar campo, reportar ausência
- `IFieldLookup` não tem adapter implementado → reportar antes de continuar

---

## 1️⃣ ESCOPO

**Módulo afetado:** `visitas/` (apenas o arquivo do card de visita ativa)  
**Módulo importado:** `ndvi/presentation/widgets/ndvi_talhao_sheet.dart`  

### PROIBIDO alterar:
- `VisitSession` model (não adicionar campos)
- `visit_controller.dart` ou qualquer provider de visitas
- Qualquer tela fora do card de visita ativa
- Rotas globais
- Tema ou design system
- `arch_check.sh`

---

## 2️⃣ OBJETIVO

Adicionar ao card de visita ativa um botão "NDVI" condicional: aparece apenas quando `VisitSession.areaId != null`. Ao tocar, abre `NdviTalhaoSheet` via `showModalBottomSheet`. Quando `areaId == null`, o botão não é renderizado — nenhum estado extra, nenhuma mensagem.

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não alterar o modelo `VisitSession` — apenas ler o `areaId` existente  
❌ Não adicionar ícone novo à coluna direita do mapa  
❌ Não criar rota nova  
❌ Não mostrar botão NDVI quando `areaId == null` — simplesmente não renderiza  
❌ Não buscar nome do talhão diretamente de `drawing/` — usar `IFieldLookup` via provider  
❌ Não chamar `showModalBottomSheet` com Navigator.of — usar `context` do widget  

✅ Botão NDVI deve ser visualmente coerente com o card existente (mesma família tipográfica e cores do design system)  
✅ Nome do talhão para o sheet: buscar via `IFieldLookup` se disponível, ou usar `areaId` como fallback  
✅ Se `IFieldLookup` não tiver adapter implementado ainda → usar `areaId` como `fieldName` temporariamente e documentar com `// TODO: substituir por IFieldLookup quando adapter estiver disponível`  

---

## 4️⃣ PLANEJAMENTO

### Arquivos a alterar:
```
<path do card de visita ativa>   ← adicionar botão NDVI condicional
```

### Arquivos a criar (se necessário):
```
# Apenas se IFieldLookup já tiver implementação disponível:
lib/modules/visitas/infra/field_lookup_adapter.dart  ← adapter opcional
```

### Nenhum outro arquivo é criado ou alterado.

---

## 5️⃣ CONTRATO DE DADOS

### Lógica condicional a implementar:

```dart
// Pseudocódigo — agente deve adaptar ao código real do card
final session = ref.watch(visitControllerProvider).activeSession;

if (session?.areaId != null) {
  // Exibir botão NDVI
  // Ao tocar:
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => NdviTalhaoSheet(
      fieldId: session!.areaId!,
      fieldName: fieldName ?? session.areaId!, // fallback se lookup indisponível
      areaHa: null, // opcional — buscar via IFieldLookup se disponível
    ),
  );
} 
// Se areaId == null → não renderizar nada. Zero widget. Zero mensagem.
```

**Impacto retrocompatível:** SIM — botão simplesmente não aparece em visitas sem talhão

---

## 6️⃣ ESTADO

- **Tipo:** Efêmero — nenhum estado novo criado no card  
- **AutoDispose:** já gerenciado pelo `NdviTalhaoSheet` (Fase 2a)  
- **Pode perder estado?** SIM — sheet fecha e descarta  
- **Afeta fluxo Map-First?** NÃO — card já estava no mapa, apenas ganha um botão  

---

## 7️⃣ PERFORMANCE

- Nenhum rebuild novo introduzido no card  
- `IFieldLookup.findById` é chamado apenas quando botão é tocado (dentro do `onTap`), não em build  
- Nenhum loop pesado  

---

## 8️⃣ TESTABILIDADE

**Cenário feliz:** sessão com `areaId != null` → botão NDVI visível e funcional  
**Cenário:** sessão com `areaId == null` → botão não renderizado, nenhum erro  
**Cenário:** sem sessão ativa → card não exibido (comportamento já existente)  

**Impacta testes existentes?** Verificar se há testes do card de visita — se sim, não quebrá-los  
**Testes novos:** opcional nesta fase se card não tiver harness de teste existente  

---

## 9️⃣ MAP-FIRST CHECK

- Move raiz funcional? **NÃO**  
- Altera nível de navegação? **NÃO**  
- Cria sub-rota? **NÃO**  
- Quebra regra L0 do `/map`? **NÃO** — card já está no mapa  

---

## 🔟 RISCO

**Classificação:** Médio  
**Motivo:** Alteração em arquivo existente do módulo `visitas/`. O campo `areaId` pode não existir em `VisitSession` — se não existir, **parar e reportar** sem inventar solução alternativa. A dependência entre `visitas/` e `ndvi/` é nova e deve ser verificada pelo `arch_check.sh`.

**Verificação adicional pós-implementação:**
```bash
grep -rn "import.*ndvi" lib/modules/visitas/ --include="*.dart"
```
Essa importação é **permitida** (visitas → ndvi é dependência válida). Confirmar que `arch_check.sh` não reporta erro.

---

## 1️⃣1️⃣ EXECUÇÃO

1. Confirmar `areaId` em `VisitSession` (PASSO 0)
2. Adicionar import de `NdviTalhaoSheet` no card
3. Adicionar bloco condicional `if (areaId != null)` com botão
4. Executar `./tool/arch_check.sh`

**Nada além disso.**

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

| Pergunta | Esperado |
|---|---|
| `flutter analyze lib/modules/visitas/` | 0 erros novos |
| `flutter analyze lib/modules/ndvi/` | 0 erros |
| `flutter test test/modules/visitas/` | todos verdes (sem regressão) |
| `./tool/arch_check.sh` | Exit 0 |
| `VisitSession` foi alterada? | NÃO |
| Foi criada alguma rota nova? | NÃO |
| Botão aparece quando `areaId == null`? | NÃO |

Se qualquer resposta divergir → rollback e reportar.

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

O card de visita ativa agora exibe botão "NDVI" condicionalmente quando `areaId != null`.  
Ao tocar, abre `NdviTalhaoSheet` com o `fieldId` da sessão ativa.  
Nenhum model, provider global, rota ou outro módulo foi alterado.
