# PROMPT 01 — drawing_sheet: Fix sheet não expande ao abrir

**Agente:** Engenheiro Sênior Flutter/Dart  
**Especialização:** BottomSheet, DraggableScrollableSheet, Map-First  
**Risco:** 🟢 Baixo  
**Atualizado:** 08/03/2026 — caminho corrigido pós-auditoria

---

## ESCOPO

**Módulo:** `drawing/`  
**Arquivo-alvo confirmado pela auditoria:**
```
lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

> ⚠️ `drawing_tools_sheet.dart` **NÃO EXISTE**. O componente real é `drawing_sheet.dart` (1217 linhas).  
> **Não criar arquivo novo.** Editar exclusivamente o arquivo acima.

🚫 **Proibido alterar:** qualquer coisa fora da chamada `showModalBottomSheet` e do `mainAxisSize` da Column raiz do sheet

---

## OBJETIVO

O sheet abre colado na parte inferior sem expandir. Deve expandir automaticamente ao abrir, mostrando todos os itens visíveis sem precisar arrastar.

---

## PASSO A PASSO

**Passo 1 — Confirmar o arquivo antes de qualquer edição**

```bash
# Confirmar existência e tamanho (esperado: ~1217 linhas)
wc -l lib/modules/drawing/presentation/widgets/drawing_sheet.dart

# Localizar onde showModalBottomSheet chama o DrawingSheet
grep -rn "DrawingSheet\|showModalBottomSheet" \
  lib/modules/drawing/presentation/ --include="*.dart" | grep -v ".g.dart"
```

**Passo 2 — Verificar a chamada atual de `showModalBottomSheet`**

Provável estado atual (incompleto):
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => DrawingSheet(...),
);
```

**Passo 3 — Substituir pela versão correta**

```dart
showModalBottomSheet(
  context: context,
  useRootNavigator: false,        // OBRIGATÓRIO — isola do GoRouter root
  isScrollControlled: true,       // OBRIGATÓRIO — permite controle total de altura
  backgroundColor: Colors.transparent,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.52,
    minChildSize: 0.40,
    maxChildSize: 0.75,
    expand: false,
    snap: true,
    snapSizes: const [0.52, 0.75],
    builder: (_, scrollController) => DrawingSheet(
      scrollController: scrollController,
      // manter TODOS os parâmetros existentes sem alteração
    ),
  ),
);
```

> Se `DrawingSheet` não aceita `scrollController`, adicionar o parâmetro opcional  
> `ScrollController? scrollController` ao construtor — não usá-lo internamente  
> se o conteúdo for Column simples (não scrollável).

**Passo 4 — Garantir `mainAxisSize: MainAxisSize.min` na Column raiz do DrawingSheet**

```bash
# Verificar Column raiz atual
grep -n "Column\|mainAxisSize" \
  lib/modules/drawing/presentation/widgets/drawing_sheet.dart | head -20
```

```dart
// A Column raiz do DrawingSheet deve ter:
Column(
  mainAxisSize: MainAxisSize.min,  // ← CRÍTICO
  children: [ ... ],
)
```

---

## VALIDAÇÃO

- [ ] Sheet abre expandido mostrando todos os itens sem precisar arrastar?
- [ ] Sheet ainda fecha ao arrastar para baixo?
- [ ] Mapa permanece visível atrás do sheet?
- [ ] `flutter analyze` sem novos erros?
- [ ] `arch_check.sh` Exit 0?

---

## ENCERRAMENTO

Apenas a chamada `showModalBottomSheet` e o `mainAxisSize` da Column raiz do `DrawingSheet` foram alterados.  
Nenhum outro módulo, rota, provider ou contrato do SoloForte foi tocado.
