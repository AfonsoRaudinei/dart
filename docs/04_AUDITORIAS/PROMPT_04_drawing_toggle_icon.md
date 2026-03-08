# PROMPT 04 — drawing_sheet: Toggle no ícone + fechar arrastando

**Agente:** Engenheiro Sênior Flutter/Dart  
**Especialização:** BottomSheet, StateProvider, Map-First  
**Risco:** 🟡 Médio (provider local novo + controle de sheet via controller)  
**Atualizado:** 08/03/2026 — caminho corrigido pós-auditoria

---

## ESCOPO

**Módulo:** `drawing/`  
**Arquivos-alvo confirmados pela auditoria:**

```
# Arquivo 1 — ícone de desenho no mapa
lib/modules/map/presentation/widgets/map_controls_overlay.dart
(ou equivalente — confirmar com grep no Passo 1)

# Arquivo 2 — sheet de ferramentas
lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

> ⚠️ `drawing_tools_sheet.dart` **NÃO EXISTE**. O componente real é `drawing_sheet.dart` (1217 linhas).  
> **Não criar arquivo novo.** Editar exclusivamente os arquivos acima.

🚫 **Proibido alterar:**
- Providers globais existentes
- Rotas, tema, Design System
- Qualquer outro módulo fora de `drawing/` e `map/`
- `SmartButton` / FAB global
- `DrawingController`

---

## OBJETIVO

O ícone de desenho no mapa deve funcionar como **toggle**: primeiro toque abre o sheet, segundo toque fecha. O sheet também fecha ao arrastar para baixo. Remover o botão X do header do sheet.

---

## COMPORTAMENTO ESPERADO

```
Usuário toca ícone de desenho
  → sheet está fechado → ABRE o sheet
  → ícone muda de cor (branco → verde/primário)

Usuário toca ícone de desenho novamente
  → sheet está aberto → FECHA o sheet
  → ícone volta ao estado normal

Usuário arrasta sheet para baixo
  → sheet fecha → ícone volta ao estado normal (não selecionado)
```

---

## PASSO A PASSO

### Passo 1 — Localizar arquivos reais

```bash
# Localizar ícone de desenho no mapa
grep -rn "drawing\|pencil\|edit.*map\|map.*edit\|DrawingSheet" \
  lib/modules/map/ lib/ui/ --include="*.dart" -l

# Confirmar arquivo do sheet
wc -l lib/modules/drawing/presentation/widgets/drawing_sheet.dart

# Localizar botão X atual no sheet (para remoção no Passo 6)
grep -n "Icons.close\|close.*onPressed\|IconButton.*close" \
  lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

### Passo 2 — Criar provider local de estado do sheet

Criar **dentro do arquivo do overlay do mapa** (ou em arquivo de providers de `map/` se já existir):

```dart
// Provider LOCAL — autoDispose — controla se o DrawingSheet está aberto
// NÃO é global. NÃO vai para core/. NÃO afeta nenhum outro módulo.
final drawingSheetOpenProvider = StateProvider.autoDispose<bool>((ref) => false);
```

> ⚠️ Se já existir algum provider que controla o estado ativo do ícone de desenho,  
> **reutilizá-lo** em vez de criar novo.

### Passo 3 — Verificar Navigator.pop existentes no DrawingSheet

```bash
# Identificar todos os Navigator.pop no arquivo (auditoria encontrou 4 ocorrências)
grep -n "Navigator\.pop\|context\.pop" \
  lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

Todos os `Navigator.pop(context)` encontrados devem ser substituídos por:
```dart
Navigator.of(context, rootNavigator: false).pop()
```
Fazer essa correção **antes** de implementar o toggle — evita tela preta.

### Passo 4 — Lógica de toggle no `onTap` do ícone

```dart
void _toggleDrawingSheet(BuildContext context, WidgetRef ref) {
  final isOpen = ref.read(drawingSheetOpenProvider);

  if (isOpen) {
    // Fechar programaticamente
    Navigator.of(context, rootNavigator: false).pop();
    ref.read(drawingSheetOpenProvider.notifier).state = false;
    return;
  }

  // Abrir sheet
  ref.read(drawingSheetOpenProvider.notifier).state = true;

  showModalBottomSheet(
    context: context,
    useRootNavigator: false,          // OBRIGATÓRIO
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
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
        // manter parâmetros existentes
      ),
    ),
  ).whenComplete(() {
    // Disparado quando sheet fecha POR QUALQUER MOTIVO
    // (arrastar, tocar fora, ou toggle no ícone)
    if (context.mounted) {
      ref.read(drawingSheetOpenProvider.notifier).state = false;
    }
  });
}
```

### Passo 5 — Atualizar visual do ícone de desenho

```dart
Consumer(
  builder: (context, ref, _) {
    final isOpen = ref.watch(drawingSheetOpenProvider);
    return GestureDetector(
      onTap: () => _toggleDrawingSheet(context, ref),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOpen
              ? Theme.of(context).colorScheme.primary  // verde quando aberto
              : Colors.white,                           // branco quando fechado
          boxShadow: [ /* sombra existente — não alterar */ ],
        ),
        child: Icon(
          Icons.edit_outlined,   // manter ícone existente
          color: isOpen ? Colors.white : Colors.black87,
        ),
      ),
    );
  },
),
```

> **Atenção:** Se o ícone já usa widget próprio (ex: `MapControlButton`),  
> adaptar dentro desse widget sem quebrar o padrão existente.

### Passo 6 — Remover botão X do `DrawingSheet`

No `DrawingSheet` (`drawing_sheet.dart`), remover o `IconButton(Icons.close, ...)` do header.

```bash
# Confirmar localização do botão X antes de remover
grep -n "Icons.close" \
  lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

Header final deve ficar apenas:
```dart
// handle + título — SEM botão X
Center(
  child: Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    width: 36, height: 4,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(2),
    ),
  ),
),
Padding(
  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
  child: const Text(
    'Ferramentas de Desenho',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  ),
),
const Divider(height: 1),
```

---

## CONTRATO DE DADOS

| Item | Status |
|---|---|
| Entidade nova | ❌ Nenhuma |
| Provider novo | `drawingSheetOpenProvider` — `StateProvider.autoDispose<bool>` — local |
| Alteração de contrato | ❌ NÃO |
| Retrocompatível | ✅ SIM |

---

## ESTADO

| Propriedade | Valor |
|---|---|
| Tipo | Local / Efêmero |
| AutoDispose | ✅ Sim |
| Pode perder estado | ✅ Sim — intencional |
| Afeta Map-First | ❌ Não — `/map` permanece ativo |
| Provider global alterado | ❌ Não |

---

## RISCO

**Classificação:** 🟡 Médio  
**Motivo:** O `.whenComplete()` do `showModalBottomSheet` deve funcionar em todos os casos de fechamento (arrastar, tocar fora, toggle). Se contexto desmontado antes do callback, o guard `context.mounted` evita crash.

**Ponto de atenção:** Se o widget que chama `_toggleDrawingSheet` for `StatelessWidget`, converter para `ConsumerStatefulWidget`.

---

## MAP-FIRST CHECK

- Move raiz funcional? ❌ Não
- Altera nível de navegação? ❌ Não
- Cria sub-rota? ❌ Não
- Quebra regra L0 do `/map`? ❌ Não
- Usa `Navigator.of(context, rootNavigator: false).pop()`? ✅ Sim — correto

---

## VALIDAÇÃO FINAL

| Verificação | Esperado |
|---|---|
| Toque no ícone abre sheet? | SIM |
| Toque novamente no ícone fecha sheet? | SIM |
| Arrastar para baixo fecha sheet? | SIM |
| Ícone fica verde com sheet aberto? | SIM |
| Ícone volta ao branco após fechar? | SIM |
| Tela preta ao fechar? | NÃO |
| Botão X removido do header? | SIM |
| 4 `Navigator.pop()` substituídos por `rootNavigator: false`? | SIM |
| Outros módulos alterados? | NÃO |
| `arch_check.sh` Exit 0? | SIM |

Se tela preta persistir → confirmar `useRootNavigator: false` na chamada do sheet.  
Se provider não reseta → confirmar `.whenComplete()` está anexado ao `showModalBottomSheet`.

---

## ENCERRAMENTO

O ícone de desenho no mapa agora funciona como toggle (abre/fecha).  
O sheet fecha por arrastar ou por toque fora — sem botão X.  
Os 4 `Navigator.pop()` soltos foram substituídos pela chamada segura com `rootNavigator: false`.  
Nenhum outro módulo, rota, estado global ou contrato do SoloForte foi alterado.
