# PROMPT 03 — drawing_sheet: Adicionar item "Gravar Rota"

**Agente:** Engenheiro Sênior Flutter/Dart  
**Especialização:** UI de lista, stub pattern, Map-First  
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

🚫 **Proibido:**
- Criar controller, provider, rota ou qualquer lógica de gravação
- Alterar itens existentes (Polígono, Livre, Pivô, KML, GPS Caminhar)
- Alterar qualquer outro arquivo

---

## OBJETIVO

Adicionar o item **"Gravar Rota"** como **último item** da lista no `DrawingSheet`, sem nenhuma funcionalidade — apenas visual com `onTap` vazio e TODO documentado.

---

## REFERÊNCIA VISUAL

Inspiração: app Wikiloc — botão REC com ícone de gravação em vermelho.  
O item deve parecer uma opção especial comparado aos demais.

---

## PASSO A PASSO

**Passo 1 — Confirmar o arquivo e localizar o último item atual**

```bash
# Confirmar existência
wc -l lib/modules/drawing/presentation/widgets/drawing_sheet.dart

# Localizar o último item da lista (GPS caminhar)
grep -n "GPS\|caminhar\|gps_walk\|GpsWalk" \
  lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

**Passo 2 — Confirmar que NÃO há item "Gravar Rota" já inserido**

```bash
grep -n "Gravar Rota\|gravar_rota\|GravarRota\|fiber_manual_record" \
  lib/modules/drawing/presentation/widgets/drawing_sheet.dart
```

Se já existir → **parar, não duplicar**.

**Passo 3 — Adicionar o item "Gravar Rota" após o item GPS Caminhar**

```dart
// APÓS o item "GPS (caminhar)", adicionar:
ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  leading: Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(
      Icons.fiber_manual_record,   // ícone REC — círculo de gravação
      color: Colors.red,
      size: 20,
    ),
  ),
  title: const Text('Gravar Rota'),
  onTap: () {
    // TODO(drawing): implementar GravarRotaController em prompt futuro
    Navigator.of(context, rootNavigator: false).pop();
  },
),
```

> **Notas de design:**
> - `red.shade50` diferencia o item dos demais sem poluir o layout
> - `fiber_manual_record` remete ao botão REC de gravadores (referência Wikiloc)
> - Manter o mesmo `contentPadding` dos outros itens para consistência

**Passo 4 — NÃO fazer:**
- ❌ Criar `GravarRotaController`
- ❌ Criar `gravarRotaProvider`
- ❌ Criar nova rota
- ❌ Alterar `DrawingController`
- ❌ Adicionar import de novos packages

---

## CONTRATO DE DADOS

Nenhuma entidade nova. Nenhuma alteração de contrato.

---

## ESTADO

- Efêmero — o `onTap` fecha o sheet e não grava nada
- AutoDispose: sim (modal)
- Impacto Map-First: zero

---

## VALIDAÇÃO

- [ ] Item "Gravar Rota" aparece como último na lista?
- [ ] Ícone vermelho visualmente distinto dos outros itens?
- [ ] Tap fecha o sheet sem tela preta?
- [ ] Itens existentes (Polígono, Livre, Pivô, KML, GPS) inalterados?
- [ ] `flutter analyze` sem novos erros?
- [ ] `arch_check.sh` Exit 0?

---

## ENCERRAMENTO

Apenas um item foi adicionado ao final da lista do `DrawingSheet`.  
Nenhum módulo, rota, estado, controller ou provider do SoloForte foi alterado.
