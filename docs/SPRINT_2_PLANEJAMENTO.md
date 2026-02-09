# 🚀 SPRINT 2 - PLANEJAMENTO: TALHÕES COMO ENTIDADES VISUAIS
**INÍCIO:** 09/02/2026  
**DURAÇÃO ESTIMADA:** 3 Checkpoints  
**OBJETIVO:** Transformar geometrias puras em "Talhões" com estados visuais ricos e interatividade.

---

## 🎯 OBJETIVOS TÉCNICOS

### 1. Sistema de Estilos Dinâmicos (Visual States)
Implementar uma renderização que reflita instantaneamente o estado do talhão:
- **Rascunho (Draft):** Linhas tracejadas, preenchimento leve.
- **Não Sincronizado (Local):** Ícone de nuvem cortada ou cor de alerta sutil.
- **Sincronizado (Synced):** Cor sólida, borda firme (Verde SoloForte).
- **Conflito (Error):** Vermelho ou alerta visual.
- **Selecionado:** Realce (Highlight) e alças de edição visíveis.

### 2. Menu Contextual de Talhão (Context Menu)
Ao clicar em um talhão, deve surgir um menu contextual (Bottom Sheet ou Floating Menu) com ações específicas:
- **Editar Geometria** (Leva ao modo `editing`).
- **Ver Detalhes** (Leva à tela de detalhes do talhão).
- **Excluir** (Com confirmação).
- **Operações** (União/Diferença se aplicável).

### 3. Integração com Módulo de Desenho
Garantir que a seleção de um talhão no mapa ative corretamente o `DrawingController` e permita a transição suave para o modo de edição.

---

## 📅 ROTEIRO DE EXECUÇÃO (CHECKPOINTS)

### ✅ Checkpoint 1: Definição de Estilos e Estados
- [ ] Criar `FieldVisualState` enum (Draft, Synced, Conflict, Selected).
- [ ] Criar `FieldStyle` class com as propriedades visuais (cor, borda, opacidade).
- [ ] Mapear `DrawingFeature` -> `FieldVisualStyle`.

### 🔄 Checkpoint 2: Renderização no Mapa
- [ ] Atualizar `TalhaoMapAdapter` para usar os novos estilos.
- [ ] Modificar `PolygonLayer` no `PrivateMapScreen` para renderizar estilos dinâmicos.
- [ ] Garantir performance (evitar recriação excessiva de objetos de estilo).

### 🔄 Checkpoint 3: Interatividade e Menu Contextual
- [ ] Implementar detecção de clique robusta (Hit Test).
- [ ] Criar Widget `FieldContextMenu`.
- [ ] Integrar ações do menu com `DrawingController` (ex: `startEditMode`).

---

## ⚠️ RISCOS E MITIGAÇÃO

- **Performance:** Renderizar muitos polígonos complexos com estilos diferentes pode ser pesado.
  - *Mitigação:* Usar cache de estilos e simplificação de geometria em zooms baixos.
- **Conflito de Gestos:** O clique no talhão pode conflitar com o clique no mapa para outras ações.
  - *Mitigação:* Priorizar a camada de talhões no `onTap` e usar `HitTestBehavior`.

---

**CRITÉRIOS DE ACEITE:**
1. O usuário consegue distinguir visualmente um talhão salvo de um rascunho.
2. Ao clicar em um talhão, ele é selecionado visualmente.
3. O menu de opções aparece ao selecionar um talhão.
4. É possível entrar no modo de edição através desse menu.
