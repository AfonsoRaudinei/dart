# PROMPT — NDVI Fase 3: Ponto de Entrada no Detalhe do Talhão
**Agente:** Engenheiro Sênior Flutter/Dart — Top 0,1%  
**Arquivo de destino:** tela de detalhe do talhão (path confirmado no PASSO 0)  
**Pré-requisito obrigatório:** Fases 1, 2a e 2b concluídas e validadas

---

## 0️⃣ PASSO 0 — AUDITORIA OBRIGATÓRIA ANTES DE QUALQUER EDIÇÃO

Execute exatamente estes comandos e reporte o resultado completo:

```bash
# 1. Localizar tela de detalhe do talhão/field
find lib/ -name "*field*detail*" -o -name "*talhao*detail*" \
  -o -name "*field*screen*" | grep "\.dart$"

# 2. Localizar tela de detalhe do cliente — pode conter lista de talhões
find lib/ -name "client_detail_screen.dart" -o -name "*client*detail*" | grep "\.dart$"

# 3. Ver estrutura atual da tela encontrada
# ATENÇÃO: substituir <PATH_REAL> pelo path encontrado acima
cat <PATH_REAL>

# 4. Confirmar NdviTalhaoSheet existe (Fase 2a)
find lib/modules/ndvi/ -name "ndvi_talhao_sheet.dart"

# 5. Confirmar que IFieldLookup existe e tem implementação
find lib/core/contracts/ -name "i_field_lookup.dart"
find lib/ -name "*field_lookup*" | grep "\.dart$"

# 6. Verificar se a tela de detalhe já tem campo fieldId acessível
grep -n "fieldId\|areaId\|field\.id\|talhao\.id" <PATH_REAL> | head -20

# 7. Verificar fronteira arquitetural — a tela pertence a qual módulo
echo "Módulo da tela:"
echo <PATH_REAL> | sed 's|lib/modules/||' | cut -d'/' -f1
```

**STOP CONDITION — parar e reportar se:**
- Tela de detalhe do talhão não existe → reportar e aguardar instrução (não criar tela nova)
- `fieldId` não está disponível no contexto da tela → reportar antes de continuar
- A tela pertence a módulo com fronteira proibida para `ndvi/` → reportar antes de continuar

---

## 1️⃣ ESCOPO

**Módulo afetado:** `consultoria/clients/` (apenas o arquivo da tela de detalhe do talhão)  
**Módulo importado:** `ndvi/presentation/widgets/ndvi_talhao_sheet.dart`  

### PROIBIDO alterar:
- Qualquer outra tela de `consultoria/`
- Providers de `consultoria/`
- Models de `consultoria/`
- Rotas globais
- Tema ou design system
- `arch_check.sh`

---

## 2️⃣ OBJETIVO

Adicionar uma seção "NDVI" na tela de detalhe do talhão: exibe a imagem mais recente disponível (via `ndviLatestProvider(fieldId)`) com um botão "Ver histórico" que abre `NdviTalhaoSheet`. Se não houver dados NDVI, exibe estado vazio discreto sem poluir a tela.

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não alterar estrutura de navegação da tela  
❌ Não alterar AppBar ou layout raiz da tela — apenas inserir seção  
❌ Não criar rota nova  
❌ Não chamar Edge Function diretamente  
❌ Não exibir dados inventados se NDVI ainda não foi buscado  
❌ Não quebrar o back button existente da tela  

✅ Seção NDVI deve ser visualmente distinta mas coerente com o restante da tela  
✅ Se sem dados: mostrar apenas texto discreto "NDVI não disponível" — sem blocar a tela  
✅ Botão "Ver histórico" abre `NdviTalhaoSheet` via `showModalBottomSheet`  

---

## 4️⃣ PLANEJAMENTO

### Arquivo a alterar:
```
<path da tela de detalhe do talhão>  ← inserir seção NDVI
```

### Provider adicional a criar em ndvi/:
```
lib/modules/ndvi/presentation/providers/ndvi_latest_provider.dart
```
```dart
// Provider que retorna apenas a imagem mais recente de um talhão
// Usado para preview na tela de detalhe sem carregar lista completa
final ndviLatestProvider = FutureProvider.family.autoDispose<NdviImage?, String>(
  (ref, fieldId) async {
    final repo = ref.watch(ndviRepositoryProvider);
    return repo.getLatestByFieldId(fieldId);
  },
);
```

---

## 5️⃣ CONTRATO DE DADOS

### Seção NDVI a inserir na tela (pseudocódigo):

```dart
// Seção inserida na tela de detalhe do talhão
// fieldId vem do context/state existente da tela
Widget _buildNdviSection(BuildContext context, WidgetRef ref, String fieldId) {
  final latestAsync = ref.watch(ndviLatestProvider(fieldId));
  
  return latestAsync.when(
    loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
    error: (_, __) => const SizedBox.shrink(), // erro silencioso — não polui tela
    data: (image) {
      if (image == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('NDVI não disponível', style: TextStyle(color: Colors.grey)),
        );
      }
      return _NdviPreviewCard(
        image: image,
        fieldId: fieldId,
        fieldName: '<nome do talhão da tela>',
      );
    },
  );
}
```

**Layout do preview card:**
```
┌─────────────────────────────────────┐
│  🛰 NDVI                            │
│  Última imagem: 15/03/2026          │
│  Médio: 0.72  ████████░░  Bom       │
│                    [Ver histórico →] │
└─────────────────────────────────────┘
```

**Impacto retrocompatível:** SIM — seção nova, não altera dados existentes

---

## 6️⃣ ESTADO

- **Tipo:** Efêmero — `ndviLatestProvider(fieldId)` com `autoDispose`  
- **Pode perder estado?** SIM — recarrega ao retornar à tela  
- **Afeta fluxo Map-First?** NÃO — tela de detalhe existe fora do mapa  

---

## 7️⃣ PERFORMANCE

- `ndviLatestProvider` usa `LIMIT 1` no SQLite — query leve  
- Erro silencioso (`SizedBox.shrink`) — não bloca renderização da tela  
- Loading discreto — não bloca scroll da tela  

---

## 8️⃣ TESTABILIDADE

**Cenário feliz:** talhão com imagem NDVI → preview card visível, botão funcional  
**Cenário:** talhão sem dados NDVI → texto "não disponível" discreto  
**Cenário erro:** repositório retorna erro → `SizedBox.shrink` silencioso  

**Impacta testes existentes?** Verificar testes da tela — não quebrar  
**Testes novos:** opcional se tela não tiver harness existente  

---

## 9️⃣ MAP-FIRST CHECK

- Move raiz funcional? **NÃO**  
- Altera nível de navegação? **NÃO**  
- Cria sub-rota? **NÃO**  
- Quebra regra L0 do `/map`? **NÃO** — tela de detalhe é rota secundária existente  

---

## 🔟 RISCO

**Classificação:** Médio  
**Motivo:** Alteração em tela existente de `consultoria/`. A importação `consultoria → ndvi` é nova e precisa ser verificada no `arch_check.sh`. Segundo `bounded_contexts.md`, `consultoria` pode depender de módulos não listados explicitamente como proibidos — verificar se `ndvi` como dependência de `consultoria` é válido ou cria acoplamento não declarado.

**Verificação arquitetural obrigatória:**
```bash
# Após implementação:
grep -rn "import.*ndvi" lib/modules/consultoria/ --include="*.dart"
./tool/arch_check.sh
```

Se `arch_check.sh` reportar violação → **parar, não forçar**, reportar para decisão de ADR.

---

## 1️⃣1️⃣ EXECUÇÃO

1. Confirmar path da tela e disponibilidade de `fieldId` (PASSO 0)
2. Criar `ndvi_latest_provider.dart`
3. Inserir seção NDVI na tela de detalhe
4. Executar `./tool/arch_check.sh`

**Nada além disso.**

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

| Pergunta | Esperado |
|---|---|
| `flutter analyze lib/modules/consultoria/` | 0 erros novos |
| `flutter analyze lib/modules/ndvi/` | 0 erros |
| `flutter test test/modules/consultoria/` | todos verdes (sem regressão) |
| `./tool/arch_check.sh` | Exit 0 |
| Outras telas de consultoria foram alteradas? | NÃO |
| Foi criada alguma rota nova? | NÃO |
| Tela exibe dados inventados quando NDVI ausente? | NÃO |

Se qualquer resposta divergir → rollback e reportar.

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

A tela de detalhe do talhão exibe preview NDVI com botão "Ver histórico".  
Quando não há dados, exibe estado vazio discreto.  
Nenhuma outra tela, rota, provider global ou contrato do SoloForte foi alterado.
