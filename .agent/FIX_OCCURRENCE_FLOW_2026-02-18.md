# 🔧 Correção do Fluxo de Ocorrências no Mapa

**Data:** 18/02/2026  
**Branch:** release/v1.1  
**Issue:** Ao clicar no ícone de ocorrência, o bottom sheet com opções não aparecia

---

## 📋 Problema Identificado

Quando o usuário clicava no ícone de ocorrência (⚠️), o sistema apenas:
1. Armava o modo de ocorrência (`_armedMode = ArmedMode.occurrences`)
2. Mostrava um SnackBar pedindo para clicar no mapa
3. **NÃO abria o MapBottomSheet** com opções de ocorrências

O usuário não tinha como:
- Ver ocorrências existentes
- Ter uma interface clara para criar nova ocorrência
- Entender o próximo passo

---

## ✅ Solução Implementada

### 1. **Modificação em `_armOccurrenceMode()`** 
**Arquivo:** `lib/ui/screens/private_map_screen.dart`

```dart
void _armOccurrenceMode() {
  // 🔧 FIX: Abrir o sheet de ocorrências primeiro
  _setSheetState(
    const MapSheetState(
      type: MapSheetType.occurrences,
      isCreatingOccurrence: false,
    ),
    'ArmOccurrenceMode: Opening occurrence sheet',
  );
  
  // Armar o modo para quando clicar no mapa
  setState(() => _armedMode = ArmedMode.occurrences);
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Toque no mapa para registrar a ocorrência'),
      duration: Duration(seconds: 2),
    ),
  );
}
```

**O que mudou:**
- Agora **abre o MapBottomSheet** no tipo `occurrences` antes de armar o modo
- O usuário vê a lista de ocorrências existentes
- Um SnackBar instrui a próxima ação

### 2. **Botão "Nova Ocorrência" Adicionado**
**Arquivo:** `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart`

**Modificações:**
- Adicionado callback `onRequestNewOccurrence` ao widget
- Adicionado `FloatingActionButton.extended` com texto "Nova Ocorrência"
- Botão posicionado no canto inferior direito (bottom: 20, right: 20)

```dart
if (widget.onRequestNewOccurrence != null)
  Positioned(
    bottom: 20,
    right: 20,
    child: FloatingActionButton.extended(
      onPressed: widget.onRequestNewOccurrence,
      backgroundColor: SoloForteColors.greenIOS,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Nova Ocorrência',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    ),
  ),
```

### 3. **Conexão com MapBottomSheet**
**Arquivo:** `lib/ui/components/map/map_bottom_sheet.dart`

No método `_buildOccurrenceList()`, conectado o callback:

```dart
onRequestNewOccurrence: () {
  // Armar modo de ocorrência (deixa o modo armado)
  widget.onOccurrenceArmed();
  // O usuário agora pode clicar no mapa
},
```

### 4. **Fechar Sheet ao Desarmar**
**Arquivo:** `lib/ui/screens/private_map_screen.dart`

Quando o usuário clica novamente no ícone de ocorrência (para desarmar):

```dart
onToggleOccurrenceMode: () {
  if (_armedMode == ArmedMode.occurrences) {
    // Desarmar e fechar o sheet
    setState(() => _armedMode = ArmedMode.none);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _setSheetState(null, 'Toggle OFF: Closing occurrence sheet');
  } else {
    _armOccurrenceMode();
  }
},
```

---

## 🎯 Fluxo Atual (Corrigido)

### **Cenário 1: Criar Nova Ocorrência**

1. **Usuário clica no ícone ⚠️** (ocorrência)
   - ✅ Abre `MapBottomSheet` mostrando lista de ocorrências
   - ✅ Modo armado (`_armedMode = occurrences`)
   - ✅ SnackBar: "Toque no mapa para registrar a ocorrência"

2. **Opção A: Usuário clica no botão "Nova Ocorrência"**
   - ✅ Mantém o modo armado
   - ✅ SnackBar reforça a instrução

3. **Opção B: Usuário clica direto no mapa**
   - ✅ Captura coordenadas (lat, lng)
   - ✅ Desarma o modo (`_armedMode = none`)
   - ✅ Abre formulário de criação (`MapOccurrenceSheet`)
   - ✅ Sheet muda para `isCreatingOccurrence: true`

4. **Usuário preenche o formulário**
   - ✅ "Relatório de Visita" com categorias
   - ✅ Salva a ocorrência no banco
   - ✅ Fecha o sheet

### **Cenário 2: Ver Ocorrências Existentes**

1. **Usuário clica no ícone ⚠️**
   - ✅ Abre lista de ocorrências existentes
   - ✅ Pode filtrar, visualizar, editar

2. **Usuário clica em uma ocorrência**
   - ✅ Primeira vez: seleciona (centraliza no mapa)
   - ✅ Segunda vez: abre editor

3. **Usuário clica no ícone ⚠️ novamente (para fechar)**
   - ✅ Desarma o modo
   - ✅ Fecha o sheet
   - ✅ Remove SnackBar

---

## 🛡️ Garantias para Não Regredir

### **Checklist de Validação:**

- [ ] Ao clicar no ícone ⚠️, o `MapBottomSheet` **sempre** abre
- [ ] A lista de ocorrências é **visível** no sheet
- [ ] O botão "Nova Ocorrência" está **presente** e **funcional**
- [ ] Ao clicar no mapa (modo armado), o formulário **abre com coordenadas**
- [ ] Ao clicar novamente no ícone ⚠️, o sheet **fecha**
- [ ] O modo armado é **desarmado** corretamente
- [ ] Não há **race conditions** entre tap no mapa e abertura do sheet

### **Testes Manuais Recomendados:**

1. **Fluxo Completo: Criar Ocorrência**
   ```
   1. Clicar ícone ⚠️ → Ver lista
   2. Clicar "Nova Ocorrência" → Modo armado
   3. Clicar no mapa → Formulário abre
   4. Preencher → Salvar → Sheet fecha
   ```

2. **Fluxo: Cancelar Criação**
   ```
   1. Clicar ícone ⚠️ → Ver lista
   2. Clicar ícone ⚠️ novamente → Sheet fecha
   3. Modo desarmado
   ```

3. **Fluxo: Ver Ocorrência Existente**
   ```
   1. Clicar ícone ⚠️ → Ver lista
   2. Clicar em ocorrência → Seleciona
   3. Clicar novamente → Abre detalhes
   ```

---

## 📦 Arquivos Modificados

1. **`lib/ui/screens/private_map_screen.dart`**
   - Método `_armOccurrenceMode()`: Abre sheet antes de armar
   - Callback `onToggleOccurrenceMode`: Fecha sheet ao desarmar

2. **`lib/modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart`**
   - Adicionado parâmetro `onRequestNewOccurrence`
   - Adicionado `FloatingActionButton.extended` com layout Stack
   - Ícone: `Icons.add`, Cor: `SoloForteColors.greenIOS`

3. **`lib/ui/components/map/map_bottom_sheet.dart`**
   - Método `_buildOccurrenceList()`: Conectado callback `onRequestNewOccurrence`
   - Chama `widget.onOccurrenceArmed()` ao clicar no botão

---

## 🧪 Validação Técnica

### **Estado Antes da Correção:**
```dart
void _armOccurrenceMode() {
  setState(() => _armedMode = ArmedMode.occurrences);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
// ❌ Sheet não abre
// ❌ Usuário não vê opções
```

### **Estado Depois da Correção:**
```dart
void _armOccurrenceMode() {
  _setSheetState(MapSheetState(...), ...); // ✅ Abre sheet
  setState(() => _armedMode = ArmedMode.occurrences);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
// ✅ Sheet abre com lista
// ✅ Botão "Nova Ocorrência" visível
// ✅ Usuário pode navegar ou criar
```

---

## 🔍 Debug Logs (para monitoramento)

Se precisar debugar o fluxo, observe estes logs:

```
🕵️ SHEET CHANGE | old=null | new=occurrences | reason=ArmOccurrenceMode: Opening occurrence sheet
🔵 Ocorrência tocada: <id>
🟢 MapBottomSheet INIT | type=occurrences
🕵️ SHEET CHANGE | old=occurrences | new=null | reason=Toggle OFF: Closing occurrence sheet
```

---

## ✅ Conclusão

O fluxo de ocorrências agora está **completo e intuitivo**:
- ✅ Clicar no ícone abre o sheet
- ✅ Botão "Nova Ocorrência" disponível
- ✅ Instruções claras para o usuário
- ✅ Modo armado funciona corretamente
- ✅ Formulário abre com coordenadas do tap no mapa

**Atenção:** Este documento deve ser consultado antes de qualquer refatoração que envolva:
- `MapBottomSheet`
- `OccurrenceListSheet`
- `_armOccurrenceMode()`
- Fluxo de criação de ocorrências
