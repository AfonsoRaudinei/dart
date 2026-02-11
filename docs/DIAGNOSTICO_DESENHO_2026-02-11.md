# 🔍 DIAGNÓSTICO: FUNCIONALIDADE DE DESENHO NÃO FUNCIONA

**Data:** 11 de fevereiro de 2026  
**Versão:** v1.1  
**Analista:** GitHub Copilot

---

## 📋 SUMÁRIO EXECUTIVO

A funcionalidade de desenho no mapa está **visualmente implementada** mas **não funciona** porque os botões da UI não estão conectados ao controller. O sistema possui toda a infraestrutura necessária, mas há uma **desconexão crítica** entre a interface e a lógica de negócio.

---

## 🎯 PONTOS DE ACESSO IDENTIFICADOS

### ✅ 1. Botão "Desenhar" no Mapa
**Localização:** [private_map_screen.dart](../lib/ui/screens/private_map_screen.dart#L713)

```dart
_MapActionButton(
  icon: Icons.edit,
  label: 'Desenhar',
  isActive: _activeSheetName == 'drawing',
  onTap: _openDrawingMode, // ✅ FUNCIONA
),
```

**Status:** ✅ **FUNCIONANDO**  
- Abre o DrawingSheet modal
- GPS é validado antes de abrir

---

### ❌ 2. Botões de Ferramentas no DrawingSheet
**Localização:** [drawing_sheet.dart](../lib/modules/drawing/presentation/widgets/drawing_sheet.dart#L38-L50)

**Ferramentas Disponíveis:**
- 🔷 Polígono
- ✏️ Livre
- ⭕ Pivô  
- 📁 Importar (KML)

**PROBLEMA CRÍTICO:**

```dart
// ❌ BUGADO - Linha 38-50
void _onToolSelected(String key) {
  if (key == 'import') {
    widget.controller.startImportMode(); // ✅ Import funciona
    setState(() {
      _selectedToolKey = null;
    });
    return;
  }

  // 🔴 BUG: Apenas muda visual, NÃO ATIVA A FERRAMENTA!
  setState(() {
    _selectedToolKey = (_selectedToolKey == key) ? null : key;
  });
  // ❌ FALTA: widget.controller.selectTool(key);
}
```

**Consequência:**
- O botão **acende** visualmente (feedback incorreto)
- O controller **nunca é notificado**
- O usuário toca no mapa mas **nada acontece**
- Estado da máquina de estados fica em `idle` ao invés de `armed`

---

## 🏗️ ARQUITETURA ATUAL

### Controller (DrawingController)
✅ **Implementado Corretamente:**
- `selectTool(String key)` - Linha 467 ✅
- Máquina de estados sincronizada ✅
- Ferramentas suportadas: polygon, freehand, pivot, rectangle, circle ✅

### Máquina de Estados (DrawingStateMachine)
✅ **Fluxo Esperado:**
```
idle → startDrawing(tool) → armed → appendDrawingPoint() → drawing
```

**Fluxo Real (BUGADO):**
```
idle → [botão clicado, nada acontece] → idle (fica travado)
```

---

## 🔗 INTEGRAÇÃO COM MÓDULO DE CLIENTES

### Status Atual: ⚠️ **PARCIALMENTE IMPLEMENTADO**

**Model (DrawingProperties):**
```dart
final String? operacaoId;  // ✅ Campo existe
final String? fazendaId;   // ✅ Campo existe
// ❌ FALTA: clienteId
```

**Banco de Dados:**
- `operacao_id` ✅
- `fazenda_id` ✅
- **FALTA** coluna `cliente_id`

**Formulário:**
- ❌ Não há seletor de cliente no DrawingSheet
- ❌ Não há integração com `clientsListProvider`

---

## 📊 ANÁLISE DO PLANO FAMS/CLIMATE

### ✅ Funcionalidades Já Implementadas:
1. ✅ Ferramentas de desenho (Polígono, Livre, Pivô)
2. ✅ Importação KML/KMZ
3. ✅ Métricas em tempo real (área, perímetro, segmentos)
4. ✅ Visualização de estado (DrawingStateIndicator)
5. ✅ Operações booleanas (União, Subtração, Interseção)
6. ✅ Edição de vértices
7. ✅ Máquina de estados robusta

### ❌ Funcionalidades Ausentes (do plano FAMS):
1. ❌ Transição automática de UI após 3º ponto
2. ❌ Cores personalizadas por grupo
3. ❌ Distâncias flutuantes nos segmentos (no mapa)
4. ❌ Hierarquia: Operação → Fazenda → Cliente → Talhão
5. ❌ Formulário de metadados completo
6. ❌ Grupos/Safras organizacionais
7. ❌ Histórico de operações agrícolas

---

## 🎯 ADAPTAÇÕES NECESSÁRIAS PARA iOS NATIVO

O plano FAMS/Climate é **web-first**. Ajustes para Flutter:

### 1. Navegação
❌ **Web:** Sidebar fixa + Mapa central  
✅ **Flutter:** BottomSheet modal + Floating Action Buttons

### 2. Interação
❌ **Web:** Mouse hover + Click  
✅ **Flutter:** Touch gestures + Long press

### 3. Transições
❌ **Web:** DOM updates instantâneos  
✅ **Flutter:** AnimatedContainer + Hero animations

### 4. Formulários
❌ **Web:** Formulários inline no sidebar  
✅ **Flutter:** BottomSheet com DraggableScrollableSheet

---

## 🐛 BUGS IDENTIFICADOS

### 🔴 **BUG #1: Botões de ferramenta não ativam drawing**
**Severidade:** CRÍTICA  
**Impacto:** Funcionalidade 100% inoperante  
**Localização:** `drawing_sheet.dart:38-50`  
**Solução:** Adicionar `widget.controller.selectTool(key)`

### 🟡 **BUG #2: Falta campo clienteId**
**Severidade:** MÉDIA  
**Impacto:** Desenhos não podem ser vinculados a clientes  
**Solução:** 
- Adicionar campo no modelo
- Migração de banco de dados
- Adicionar dropdown no formulário

### 🟡 **BUG #3: Tooltip fica travado**
**Severidade:** BAIXA  
**Impacto:** Poluição visual, mas não bloqueia funcionalidade  
**Localização:** `drawing_sheet.dart:26-28`

---

## 🎯 PLANO DE AÇÃO PRIORIZADO

### 🔥 **FASE 1: CORREÇÃO CRÍTICA (30 min)**
1. ✅ Conectar `_onToolSelected` ao `controller.selectTool()`
2. ✅ Testar fluxo: botão → armed → drawing → reviewing
3. ✅ Validar com GPS real

### 📦 **FASE 2: INTEGRAÇÃO COM CLIENTES (2h)**
4. ⬜ Adicionar campo `clienteId` ao modelo
5. ⬜ Migração de banco de dados
6. ⬜ Adicionar dropdown de cliente no formulário
7. ⬜ Conectar com `clientsListProvider`

### 🎨 **FASE 3: MELHORIAS UX (4h)**
8. ⬜ Transição automática após 3º ponto (estilo FAMS)
9. ⬜ Cores por grupo/safra
10. ⬜ Distâncias flutuantes no mapa
11. ⬜ Animações de feedback

### 🏗️ **FASE 4: ARQUITETURA HÍBRIDA (8h)**
12. ⬜ Hierarquia: Operação → Fazenda → Cliente → Talhão
13. ⬜ Sistema de grupos/safras
14. ⬜ Formulário de metadados completo
15. ⬜ Histórico de edições

---

## 📝 DECISÕES ARQUITETURAIS

### ✅ **MANTER:**
- DrawingController como fonte única de verdade
- Máquina de estados atual (robusta)
- Estrutura de DrawingFeature (GeoJSON compliant)
- BottomSheet modal (mobile-first)

### 🔄 **ADAPTAR:**
- Sidebar web → BottomSheet expansível
- Formulário inline → Sheet com abas
- Hierarquia fixa → Navegação drill-down

### ❌ **NÃO IMPLEMENTAR:**
- Sidebar esquerda fixa (não se aplica a mobile)
- Múltiplas janelas simultâneas
- Drag & drop (substituir por gestos)

---

## 🧪 CHECKLIST DE VALIDAÇÃO

### Após Correção do Bug #1:
- [ ] Tocar em "Polígono" → Botão acende
- [ ] Tocar no mapa → Primeiro ponto aparece
- [ ] Tocar novamente → Linha conecta os pontos
- [ ] 3+ pontos → Métricas aparecem
- [ ] Duplo toque → Polígono fecha e vai para review
- [ ] Botão "Confirmar" → Salva no banco

### Após Integração com Clientes:
- [ ] Dropdown de clientes carrega
- [ ] Selecionar cliente → Filtra fazendas
- [ ] Salvar desenho → `cliente_id` persiste
- [ ] Abrir desenho salvo → Cliente pré-selecionado

---

## 📚 REFERÊNCIAS

- [Contrato Módulo Drawing](./contratos/modulo-drawing.md)
- [Contrato Mapa ↔ Drawing](./contratos/mapa_drawing_contract.md)
- [Sprint 1 - Checkpoint 1](./SPRINT_1_CHECKPOINT_1.md)
- [Arquitetura de Namespaces](./arquitetura-namespaces-rotas.md)

---

**Próximos Passos:** Implementar correção do Bug #1 e testar em dispositivo real.
