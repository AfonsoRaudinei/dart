# PROMPT — NDVI Fase 2a: Bottom Sheet Reutilizável
**Agente:** Engenheiro Sênior Flutter/Dart — Top 0,1%  
**Arquivo de destino:** `lib/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart`  
**Pré-requisito obrigatório:** NDVI Fase 1 concluída e validada (arch_check Exit 0, testes verdes)

---

## 0️⃣ PASSO 0 — AUDITORIA OBRIGATÓRIA ANTES DE QUALQUER EDIÇÃO

Execute exatamente estes comandos e reporte antes de criar qualquer arquivo:

```bash
# 1. Confirmar que Fase 1 foi executada — módulo ndvi existe
find lib/modules/ndvi/ -name "*.dart" | sort

# 2. Confirmar que INdviRepository existe
find lib/modules/ndvi/ -name "i_ndvi_repository.dart"

# 3. Confirmar que ndvi_providers.dart existe
find lib/modules/ndvi/ -name "ndvi_providers.dart"

# 4. Confirmar que NdviImage entidade existe
find lib/modules/ndvi/ -name "ndvi_image.dart"

# 5. Confirmar que IFieldLookup existe em core/contracts/
find lib/core/contracts/ -name "i_field_lookup.dart"

# 6. Confirmar design system — cores e tema
find lib/ -name "design_soloforte*" -o -name "app_theme*" -o -name "app_colors*" | head -10

# 7. Confirmar kFabSafeArea e layout_constants
find lib/core/constants/ -name "layout_constants.dart"
grep -n "kFabSafeArea\|kFabHeight" lib/core/constants/layout_constants.dart
```

Se Fase 1 não estiver completa → **PARAR. Não executar esta fase.**

---

## 1️⃣ ESCOPO

**Módulo:** `ndvi/`  
**Arquivo principal:** `lib/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart`  
**Rota afetada:** nenhuma — é bottom sheet, não rota  

### PROIBIDO alterar:
- Qualquer arquivo fora de `lib/modules/ndvi/presentation/`
- Providers de outros módulos
- Rotas globais
- Tema ou design system
- Card de visita ativa (será feito na Fase 2b)
- Tela de detalhe do cliente (será feita na Fase 3)

---

## 2️⃣ OBJETIVO

Criar o widget `NdviTalhaoSheet` — um bottom sheet standalone e reutilizável que recebe um `fieldId`, carrega as imagens NDVI daquele talhão via provider, exibe a imagem mais recente com navegação por data (setas ← →), e pode ser aberto de qualquer ponto do app sem depender de contexto de visita.

---

## 3️⃣ REGRAS ABSOLUTAS

❌ Não criar rota — o sheet é aberto via `showModalBottomSheet`  
❌ Não depender de `VisitSession` — o sheet recebe apenas `fieldId` como parâmetro  
❌ Não importar módulos de `consultoria/`, `visitas/` ou `drawing/` diretamente  
❌ Não criar AppBar dentro do sheet  
❌ Não usar dados fictícios ou imagens placeholder hardcoded  
❌ Não chamar Edge Function diretamente do widget — apenas via provider/repositório  

✅ Widget deve ser stateless na assinatura (`ConsumerWidget`)  
✅ Estado de navegação entre datas via `StateProvider` local com `autoDispose`  
✅ Respeitar `kFabSafeArea` no padding inferior  
✅ Tratar estado de loading, erro e lista vazia explicitamente  

---

## 4️⃣ PLANEJAMENTO

### Arquivos a criar:

```
lib/modules/ndvi/presentation/widgets/
└── ndvi_talhao_sheet.dart    ← widget principal

lib/modules/ndvi/presentation/providers/
└── ndvi_date_nav_provider.dart  ← StateProvider para índice de data selecionada
```

### Arquivos a criar em test/:
```
test/modules/ndvi/
└── ndvi_talhao_sheet_test.dart  ← widget test com FakeNdviRepository
```

---

## 5️⃣ CONTRATO DE DADOS

### Assinatura pública do widget:

```dart
class NdviTalhaoSheet extends ConsumerWidget {
  final String fieldId;
  final String fieldName;   // para exibição no header do sheet
  final double? areaHa;     // opcional — exibido se disponível
  
  const NdviTalhaoSheet({
    super.key,
    required this.fieldId,
    required this.fieldName,
    this.areaHa,
  });
}
```

### Como abrir o sheet (padrão a seguir nos outros módulos):

```dart
// Exemplo de uso — NÃO implementar aqui, apenas documentar
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => NdviTalhaoSheet(
    fieldId: 'uuid-do-talhao',
    fieldName: 'Talhão A',
    areaHa: 45.2,
  ),
);
```

---

## 6️⃣ ESTADO

- **ndviImagesProvider(fieldId):** `FutureProvider.family.autoDispose` — lista de `NdviImage` ordenada por `imageDate DESC`  
- **ndviDateIndexProvider:** `StateProvider.autoDispose<int>` — índice da imagem exibida atualmente (começa em 0 = mais recente)  
- **Pode perder estado?** SIM — ao fechar o sheet, estado é descartado (autoDispose correto)  
- **Afeta fluxo Map-First?** NÃO  

---

## 7️⃣ LAYOUT DO SHEET

```
┌──────────────────────────────────────────┐
│  ── (drag handle)                        │
│                                          │
│  [Nome do talhão]          [45,2 ha]     │
│  [Fonte: Sentinel]  [Data: 15/03/2026]   │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │                                    │  │
│  │      Imagem NDVI colorida          │  │
│  │      (placeholder se sem URL)      │  │
│  │                                    │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ← anterior    [3 de 7]    próxima →     │
│                                          │
│  NDVI médio: 0.72  Min: 0.41  Max: 0.89  │
│                                          │
│         [SizedBox kFabSafeArea]          │
└──────────────────────────────────────────┘
```

**Estados visuais obrigatórios:**
- `loading` → `CircularProgressIndicator` centralizado  
- `error` → mensagem de erro + botão retry  
- `empty` → texto "Nenhuma imagem disponível para este talhão"  
- `data` → layout completo acima  

**Setas de navegação:**
- Seta esquerda desabilitada quando `index == images.length - 1` (imagem mais antiga)  
- Seta direita desabilitada quando `index == 0` (imagem mais recente)  

---

## 8️⃣ PERFORMANCE

- Imagem NDVI: usar `Image.network` com `loadingBuilder` se `imageUrl != null`  
- Se `imageUrl == null` e `localPath != null`: usar `Image.file`  
- Se ambos null: exibir container colorido com gradiente verde/amarelo/vermelho como placeholder visual (não dado inventado — é indicador de ausência)  
- Nenhum loop pesado em build  

---

## 9️⃣ TESTABILIDADE

**Cenário feliz:** sheet abre com `fieldId` válido, exibe imagem mais recente, navega entre datas  
**Cenário erro:** provider retorna erro → exibe mensagem de erro sem crash  
**Edge case:** apenas 1 imagem disponível → ambas as setas desabilitadas  

**Impacta testes existentes?** NÃO  
**Testes novos:** widget test com `FakeNdviRepository` injetado via `ProviderScope.overrides`  

---

## 🔟 RISCO

**Classificação:** Baixo  
**Motivo:** Widget standalone sem dependências cruzadas. Único risco é `Image.network` em ambiente de teste — usar `FakeNdviRepository` com `imageUrl: null` nos testes para evitar chamadas de rede.

---

## 1️⃣1️⃣ EXECUÇÃO

Ordem obrigatória:

1. Criar `ndvi_date_nav_provider.dart`
2. Criar `ndvi_talhao_sheet.dart`
3. Criar `ndvi_talhao_sheet_test.dart`

**Nada além disso.**

---

## 1️⃣2️⃣ VALIDAÇÃO FINAL

| Pergunta | Esperado |
|---|---|
| `flutter analyze lib/modules/ndvi/` | 0 erros |
| `flutter test test/modules/ndvi/` | todos verdes |
| `./tool/arch_check.sh` | Exit 0 |
| Widget importa `consultoria/`, `visitas/` ou `drawing/`? | NÃO |
| Foi criada alguma rota nova? | NÃO |
| Algum arquivo novo > 900 linhas? | NÃO |
| Card de visita ativa foi alterado? | NÃO |

Se qualquer resposta divergir → rollback e reportar.

---

## 1️⃣3️⃣ ENCERRAMENTO PADRÃO

O widget `NdviTalhaoSheet` foi criado como bottom sheet reutilizável.  
Recebe `fieldId` como parâmetro, carrega dados via provider, navega entre datas.  
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
